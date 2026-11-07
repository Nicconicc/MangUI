local _,M=...
local C=M.Compat
local id="mouseShortcuts"
local stableUnits={"target","focus","player","pet"}
local clicks={}
local lastLeft
local popup
local generation=0

function M:EnsureMouseShortcutsModule(design)
    for _,node in ipairs(design.nodes) do
        if node.id==id then return end
    end
    design.nodes[#design.nodes+1]={id=id,label="鼠标快捷功能",kind="group",compound=id,
        scope="player",unit="player",width=2,height=2,layer=600,enabled=true,locked=true,
        mouseUnitMenu=true,mouseUnitMarks=true,rules={},conditions={}}
end
M.moduleIDs[id]=true
M:EnsureMouseShortcutsModule(M.defaults)
if M.recordedDefaults then M:EnsureMouseShortcutsModule(M.recordedDefaults) end

local function Setting(key)
    local node=M.byID and M.byID[id]
    return node and node.enabled~=false and node[key]~=false
end

local function WorldHasMouse()
    if GetMouseFoci then
        for _,frame in ipairs(GetMouseFoci() or {}) do
            if frame~=WorldFrame and frame~=UIParent then return false end
        end
        return true
    end
    local frame=GetMouseFocus and GetMouseFocus()
    return not frame or frame==WorldFrame or frame==UIParent
end

local function GUID(unit)
    local ok,guid=pcall(UnitGUID,unit)
    if ok and C.Readable(guid) and type(guid)=="string" then return guid end
end

local function StableUnit(guid)
    for _,unit in ipairs(stableUnits) do
        if GUID(unit)==guid then return unit end
    end
    local prefix,count="party",GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
    if IsInRaid and IsInRaid() then prefix,count="raid",GetNumGroupMembers() end
    for i=1,count do
        local unit=prefix..i
        if GUID(unit)==guid then return unit end
    end
end

local function CanOpenUnitMenu(unit)
    local attackable=UnitCanAttack("player",unit)
    return C.Readable(attackable) and not attackable and C.Bool(UnitExists(unit))
end

local backdrop={
    bgFile="Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true,tileSize=32,edgeSize=16,insets={left=4,right=4,top=4,bottom=4},
}
local width,rowHeight=184,20
local function MenuFrame(parent,secure)
    local template=secure and "BackdropTemplate,SecureHandlerStateTemplate" or "BackdropTemplate"
    local frame=CreateFrame("Frame",nil,parent,template)
    local atlas="common-dropdown-bg"
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
        local background=frame:CreateTexture(nil,"BACKGROUND")
        background:SetAtlas(atlas)
        background:SetPoint("TOPLEFT",-10,3);background:SetPoint("BOTTOMRIGHT",10,-3)
        background:SetAlpha(.925)
    else
        frame:SetBackdrop(backdrop);frame:SetBackdropColor(0,0,0,.9)
        frame:SetBackdropBorderColor(.8,.67,.43,1)
    end
    frame:SetFrameStrata("DIALOG");frame:SetClampedToScreen(true);frame:EnableMouse(true)
    frame:Hide()
    return frame
end

local function Name(unit)
    local name,realm=UnitName(unit)
    if not C.Readable(name) or type(name)~="string" then return end
    if C.Readable(realm) and type(realm)=="string" and realm~="" then return name.."-"..realm end
    return name
end

local function MenuRow(parent,text,secure)
    local button=CreateFrame("Button",nil,parent,secure and "SecureActionButtonTemplate" or nil)
    button:SetSize(width-16,rowHeight)
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
    button.label=M.Widgets.Label(button,text,12)
    button.label:SetPoint("LEFT",5,0);button.label:SetJustifyH("LEFT")
    return button
end

local function SecureRow(panel,parent,text,kind)
    local button=MenuRow(parent,text,true)
    button:RegisterForClicks("LeftButtonUp")
    button:SetAttribute("useOnKeyDown",false)
    button:SetScript("PreClick",function(self)
        if InCombatLockdown() then return end
        local unit=panel.unit
        local valid=panel:IsShown() and unit and GUID(unit)==panel.guid and Setting(panel.key)
            and (panel.key~="mouseUnitMenu" or CanOpenUnitMenu(unit))
        self:SetAttribute("type",valid and kind or nil)
        self:SetAttribute("unit",valid and unit or nil)
    end)
    button:SetScript("PostClick",function()
        if not InCombatLockdown() then panel:Hide() end
    end)
    return button
end

local markerLabels={"星形","圆形","菱形","三角形","月亮","方块","十字","骷髅"}
local function MarkerMenu(panel)
    local submenu=MenuFrame(panel)
    submenu:SetSize(width,9*rowHeight+16)
    submenu:SetFrameLevel(panel:GetFrameLevel()+5)
    for i=1,9 do
        local clear=i==9
        local label=clear and (REMOVE_RAID_TARGET_ICON or "清除标记")
            or _G["RAID_TARGET_"..i] or markerLabels[i]
        local button=SecureRow(panel,submenu,label,"raidtarget")
        button:SetPoint("TOPLEFT",8,-8-(i-1)*rowHeight)
        button:SetAttribute("marker",clear and 0 or i)
        button:SetAttribute("action",clear and "clear" or "set")
        if not clear then
            local icon=button:CreateTexture(nil,"ARTWORK")
            icon:SetSize(14,14);icon:SetPoint("LEFT",5,0)
            icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
            if SetRaidTargetIconTexture then
                SetRaidTargetIconTexture(icon,i)
            else
                local left,top=(i-1)%4/4,math.floor((i-1)/4)/4
                icon:SetTexCoord(left,left+.25,top,top+.25)
            end
            button.label:ClearAllPoints();button.label:SetPoint("LEFT",24,0)
        end
    end
    return submenu
end

local function Popup()
    if popup then return popup end
    local panel=MenuFrame(UIParent,true)
    popup=panel
    panel:SetAttribute("_onstate-combat",[[ if newstate=="combat" then self:Hide() end ]])
    RegisterStateDriver(panel,"combat","[combat] combat; safe")
    panel.title=M.Widgets.Label(panel,"",12)
    panel.title:SetPoint("TOPLEFT",13,-10);panel.title:SetPoint("TOPRIGHT",-13,-10)
    panel.title:SetJustifyH("LEFT");panel.title:SetWordWrap(false);panel.title:SetTextColor(1,.82,0)
    panel.markers=MarkerMenu(panel)
    panel.markRow=MenuRow(panel,RAID_TARGET_ICON or "目标标记图标")
    local arrow=panel.markRow:CreateTexture(nil,"ARTWORK")
    arrow:SetSize(16,16);arrow:SetPoint("RIGHT",-3,0)
    arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    local function ShowMarkers()
        if InCombatLockdown() or not panel.unit then return end
        local submenu=panel.markers
        submenu:ClearAllPoints()
        if (panel:GetRight() or 0)+width>UIParent:GetWidth() then
            submenu:SetPoint("TOPRIGHT",panel.markRow,"TOPLEFT",-4,5)
        else
            submenu:SetPoint("TOPLEFT",panel.markRow,"TOPRIGHT",4,5)
        end
        submenu:Show()
    end
    panel.markRow:SetScript("OnEnter",ShowMarkers)
    panel.markRow:SetScript("OnClick",ShowMarkers)
    panel.focusRow=SecureRow(panel,panel,SET_FOCUS or "设置焦点","focus")
    panel.whisperRow=MenuRow(panel,WHISPER or "密语")
    panel.inviteRow=MenuRow(panel,INVITE or "邀请")
    panel.whisperRow:SetScript("OnClick",function()
        if InCombatLockdown() then return end
        panel:Hide()
        if Setting("mouseUnitMenu") and ChatFrame_SendTell then ChatFrame_SendTell(panel.nameText) end
    end)
    panel.inviteRow:SetScript("OnClick",function()
        if InCombatLockdown() then return end
        panel:Hide()
        local invite=C_PartyInfo and C_PartyInfo.InviteUnit or InviteUnit
        if Setting("mouseUnitMenu") and invite then pcall(invite,panel.nameText) end
    end)
    for _,row in ipairs({panel.focusRow,panel.whisperRow,panel.inviteRow}) do
        row:SetScript("OnEnter",function()
            if not InCombatLockdown() then panel.markers:Hide() end
        end)
    end
    return panel
end

local function OpenMenu(key,guid,unit,playerName,x,y)
    local panel=Popup()
    panel.key,panel.guid,panel.unit,panel.nameText=key,guid,unit,playerName
    panel.title:SetText(unit and Name(unit) or playerName or M:T("选择标记"))
    panel.markers:Hide()
    local offset=28
    local function PlaceRow(row,visible)
        row:SetShown(visible)
        if not visible then return end
        row:ClearAllPoints();row:SetPoint("TOPLEFT",8,-offset)
        offset=offset+rowHeight
    end
    PlaceRow(panel.markRow,unit~=nil)
    PlaceRow(panel.focusRow,unit~=nil and type(FocusUnit)=="function")
    PlaceRow(panel.whisperRow,playerName~=nil)
    PlaceRow(panel.inviteRow,playerName~=nil)
    local scale=UIParent:GetEffectiveScale()
    panel:SetSize(width,offset+7);panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x/scale+8,y/scale-6)
    panel:Show()
end

local function OnMouse(_,event,button)
    if event=="PLAYER_REGEN_DISABLED" then
        generation=generation+1;lastLeft=nil
        for key in pairs(clicks) do clicks[key]=nil end
        -- The combat state driver hides the protected menu.
        return
    end
    if InCombatLockdown() then return end
    if event=="PLAYER_TARGET_CHANGED" then
        if popup then popup:Hide() end
        return
    end
    if event=="GLOBAL_MOUSE_DOWN" then
        generation=generation+1
        if popup and popup:IsShown() and not popup:IsMouseOver()
            and not (popup.markers:IsShown() and popup.markers:IsMouseOver()) then
            popup:Hide()
        end
    end
    local key=button=="RightButton" and "mouseUnitMenu" or button=="LeftButton" and "mouseUnitMarks"
    if not key then return end
    local previous=clicks[button];clicks[button]=nil
    local guid
    if Setting(key) and WorldHasMouse() then
        guid=GUID("mouseover")
        if button=="RightButton" then
            if guid and not CanOpenUnitMenu("mouseover") then
                return
            elseif not guid and event=="GLOBAL_MOUSE_UP" and previous then
                -- Releasing the camera button can restore mouseover on the next frame.
                guid=previous.guid
            end
        end
    end
    if not guid then
        if button=="LeftButton" then lastLeft=nil end
        return
    end
    local x,y=GetCursorPosition()
    local now=GetTime()
    if event=="GLOBAL_MOUSE_DOWN" then
        clicks[button]={guid=guid,x=x,y=y,time=now}
        return
    end
    if not previous or guid~=previous.guid or now-previous.time>.5
        or math.abs(x-previous.x)>8 or math.abs(y-previous.y)>8 then
        if button=="LeftButton" then lastLeft=nil end
        return
    end
    if button=="LeftButton" then
        local first=lastLeft
        lastLeft={guid=guid,time=now,x=x,y=y}
        if not first or first.guid~=guid or now-first.time>.35
            or math.abs(x-first.x)>12 or math.abs(y-first.y)>12 then return end
        lastLeft=nil
    end
    local serial=generation
    C_Timer.After(0,function()
        if serial~=generation or not Setting(key) or InCombatLockdown() then return end
        local unit=StableUnit(guid)
        if button=="LeftButton" then
            if unit then OpenMenu(key,guid,unit,nil,x,y) end
        elseif unit and CanOpenUnitMenu(unit) then
            local name=C.Bool(UnitIsPlayer(unit)) and unit~="player" and Name(unit) or nil
            OpenMenu(key,guid,unit,name,x,y)
        elseif not unit and GUID("mouseover")==guid and CanOpenUnitMenu("mouseover")
            and C.Bool(UnitIsPlayer("mouseover")) then
            local name=Name("mouseover")
            if name then OpenMenu(key,guid,nil,name,x,y) end
        end
    end)
end

local listener=CreateFrame("Frame")
listener:RegisterEvent("GLOBAL_MOUSE_DOWN")
listener:RegisterEvent("GLOBAL_MOUSE_UP")
listener:RegisterEvent("PLAYER_REGEN_DISABLED")
listener:RegisterEvent("PLAYER_TARGET_CHANGED")
listener:SetScript("OnEvent",OnMouse)
