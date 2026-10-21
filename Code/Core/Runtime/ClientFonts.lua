local _,M=...
local fonts={}
local pending=false

-- SetFont may report success while the native glyph run still uses the login
-- fallback. A recovery pass must detach that face before selecting it again.
function M:ApplyRegionFont(region,path,size,flags,force)
    local fallback=self:DefaultFontPath()
    flags=flags or ""
    if force and path~=fallback then pcall(region.SetFont,region,fallback,size,flags) end
    local ok,loaded=pcall(region.SetFont,region,path,size,flags)
    if ok and loaded~=false and region.GetFont then
        local read,actual,height=pcall(region.GetFont,region)
        local function Key(value)return type(value)=="string"and value:gsub("/","\\"):lower()end
        ok=read and Key(actual)==Key(path)and type(height)=="number"and math.abs(height-size)<.01
    end
    if not ok or loaded==false then
        pcall(region.SetFont,region,fallback,size,flags);return false
    end
    return true
end

function M:NormalizeClientFontScale(value)
    if type(value)~="number" or value~=value or value==math.huge or value==-math.huge then return 1 end
    return math.floor(math.max(.5,math.min(1.5,value))*20+.5)/20
end

local function ReadFont(object)
    if not object or type(object.GetFont)~="function" or type(object.SetFont)~="function" then return end
    local ok,path,size,flags=pcall(object.GetFont,object)
    if ok and type(path)=="string" and type(size)=="number" and size>0 then return path,size,flags end
end

function M:ClientInterfaceFontSize(nominal)
    -- GameFontNormal is already resized by ApplyClientFontScale. Add the
    -- interface label's original difference from 13 AFTER that scaling.
    local _,size=ReadFont(GameFontNormal)
    if not size then size=13*self:NormalizeClientFontScale(self.db and self.db.clientFontScale) end
    return math.max(1,size+(nominal or 13)-13)
end

local function Capture(object,visiting,allowed)
    if fonts[object] then return fonts[object] end
    local _,size=ReadFont(object)
    if not size or visiting[object] then return end
    visiting[object]=true
    local inherited
    if type(object.GetFontObject)=="function" then
        local ok,parent=pcall(object.GetFontObject,object)
        if ok and type(parent)=="string" then parent=_G[parent] end
        -- A font created by a later Blizzard addon can inherit a font that we
        -- have already resized. Recover that parent's unscaled height first.
        if ok and parent and parent~=object and allowed[parent] then
            local _,parentSize=ReadFont(parent)
            if parentSize and math.abs(size-parentSize)<.001 then
                inherited=Capture(parent,visiting,allowed)
            end
        end
    end
    local record={size=inherited and inherited.size or size}
    fonts[object]=record
    visiting[object]=nil
    return record
end

function M:ApplyClientFontScale()
    if not self.db then return end
    if InCombatLockdown and InCombatLockdown() then pending=true;return end
    pending=false
    local scale=self:NormalizeClientFontScale(self.db.clientFontScale)
    self.db.clientFontScale=scale
    -- Capture every original height before changing any shared parent font.
    -- This catalog contains Blizzard font objects only, not addon font names.
    local allowed={}
    for _,name in ipairs(self.clientFontNames) do
        local object=_G[name]
        if object then allowed[object]=true end
    end
    for object in pairs(allowed) do Capture(object,{},allowed) end
    for object,record in pairs(fonts) do
        if scale~=1 or record.applied then
            local path,_,flags=ReadFont(object)
            if path then
                local ok,result=pcall(object.SetFont,object,path,record.size*scale,flags or "")
                if ok and result~=false then record.applied=true end
            end
        end
    end
    if self.RefreshClientInterfaceFonts then self:RefreshClientInterfaceFonts() end
end

function M:SetClientFontScale(value)
    if not self:CanEdit() then return end
    self.db.clientFontScale=self:NormalizeClientFontScale(value)
    self:ApplyClientFontScale()
end

local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent",function(_,event,addon)
    if event=="PLAYER_LOGIN" or (event=="PLAYER_REGEN_ENABLED" and pending)
        or (event=="ADDON_LOADED" and type(addon)=="string" and addon:match("^Blizzard_")) then
        M:ApplyClientFontScale()
    end
end)
