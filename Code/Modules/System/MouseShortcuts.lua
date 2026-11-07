local _,M=...
local C=M.Compat
local id="mouseShortcuts"
local stableUnits={"target","focus","player","pet"}
local clicks={}
local lastLeft
local popup
local dropdown
local generation=0

function M:EnsureMouseShortcutsModule(design)
    for _,node in ipairs(design.nodes) do
        if node.id==id then return end
    end
    design.nodes[#design.nodes+1]={id=id,label="鼠标快捷功能",kind="group",compound=id,
        scope="player",unit="player",width=2,height=2,layer=600,enabled=false,locked=true,
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

local function Popup()
    if popup then return popup end
    popup=M.Widgets.Panel(UIParent)
    popup:SetFrameStrata("DIALOG");popup:SetClampedToScreen(true);popup:EnableMouse(true)
    popup:Hide()
    popup.title=M.Widgets.Label(popup,"",12)
    popup.title:SetPoint("TOPLEFT",10,-9);popup.title:SetPoint("TOPRIGHT",-10,-9)
    popup.title:SetJustifyH("LEFT");popup.title:SetWordWrap(false)
    return popup
end

local function Place(panel,x,y,width,height)
    local scale=UIParent:GetEffectiveScale()
    panel:SetSize(width,height);panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x/scale+8,y/scale-6)
    panel:Show()
end

local function Name(unit)
    local name,realm=UnitName(unit)
    if not C.Readable(name) or type(name)~="string" then return end
    if C.Readable(realm) and type(realm)=="string" and realm~="" then return name.."-"..realm end
    return name
end

local function MarkMenu(guid,unit,x,y)
    if not SetRaidTarget then return end
    local panel=Popup()
    panel.title:SetText(Name(unit) or M:T("选择标记"))
    panel.guid=guid
    if not panel.marks then
        panel.marks={}
        for i=1,9 do
            local index=i<=8 and i or 0
            local button=CreateFrame("Button",nil,panel)
            button:SetSize(26,26);button:SetPoint("TOPLEFT",8+(i-1)*28,-30)
            button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
            if index>0 then
                local icon=button:CreateTexture(nil,"ARTWORK")
                icon:SetAllPoints();icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
                if SetRaidTargetIconTexture then
                    SetRaidTargetIconTexture(icon,index)
                else
                    local left,top=(index-1)%4/4,math.floor((index-1)/4)/4
                    icon:SetTexCoord(left,left+.25,top,top+.25)
                end
            else
                button:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
            end
            button:SetScript("OnClick",function()
                local target=panel.guid and StableUnit(panel.guid)
                panel:Hide()
                if target and Setting("mouseUnitMarks") then pcall(SetRaidTarget,target,index) end
            end)
            panel.marks[i]=button
        end
    end
    for _,button in ipairs(panel.marks) do button:Show() end
    for _,button in ipairs(panel.actions or {}) do button:Hide() end
    Place(panel,x,y,268,64)
end

local function MenuType(unit)
    if C.Bool(UnitIsUnit(unit,"player")) then return "SELF" end
    if not C.Bool(UnitIsPlayer(unit)) then return "TARGET" end
    if unit:match("^raid%d+$") or UnitInRaid and C.Number(UnitInRaid(unit)) then return "RAID_PLAYER" end
    if unit:match("^party%d+$") or UnitInParty and C.Bool(UnitInParty(unit)) then return "PARTY" end
    return "PLAYER"
end

local function OpenNativeMenu(unit)
    local which=MenuType(unit)
    if UnitPopup_OpenMenu then
        local ok=pcall(UnitPopup_OpenMenu,which,{unit=unit,name=Name(unit),fromTargetFrame=true})
        if ok then return true end
    end
    if UnitPopup_ShowMenu and UIDropDownMenu_Initialize and ToggleDropDownMenu then
        if not dropdown then dropdown=CreateFrame("Frame","MangUIUFWorldUnitDropdown",UIParent,"UIDropDownMenuTemplate") end
        UIDropDownMenu_Initialize(dropdown,function(frame) UnitPopup_ShowMenu(frame,which,unit) end,"MENU")
        ToggleDropDownMenu(1,nil,dropdown,"cursor",0,0)
        return true
    end
end

local function PlayerMenu(name,x,y)
    local panel=Popup()
    panel.title:SetText(name);panel.nameText=name
    for _,button in ipairs(panel.marks or {}) do button:Hide() end
    if not panel.actions then
        local whisper=M.Widgets.Button(panel,WHISPER or "密语",146,function()
            panel:Hide()
            if Setting("mouseUnitMenu") and ChatFrame_SendTell then ChatFrame_SendTell(panel.nameText) end
        end)
        local invite=M.Widgets.Button(panel,INVITE or "邀请",146,function()
            panel:Hide()
            local send=C_PartyInfo and C_PartyInfo.InviteUnit or InviteUnit
            if Setting("mouseUnitMenu") and send then pcall(send,panel.nameText) end
        end)
        whisper:SetPoint("TOPLEFT",7,-28);invite:SetPoint("TOPLEFT",7,-57)
        panel.actions={whisper,invite}
    end
    for _,button in ipairs(panel.actions) do button:Show() end
    Place(panel,x,y,160,88)
end

local function OnMouse(_,event,button)
    if event=="PLAYER_REGEN_DISABLED" or event=="PLAYER_TARGET_CHANGED" then
        if popup then popup:Hide() end
        if event=="PLAYER_REGEN_DISABLED" then generation=generation+1;lastLeft=nil end
        return
    end
    if event=="GLOBAL_MOUSE_DOWN" then
        generation=generation+1
        if popup and popup:IsShown() and not popup:IsMouseOver() then popup:Hide() end
    end
    local key=button=="RightButton" and "mouseUnitMenu" or button=="LeftButton" and "mouseUnitMarks"
    if not key then return end
    local previous=clicks[button];clicks[button]=nil
    local guid
    if Setting(key) and WorldHasMouse() and not (button=="RightButton" and InCombatLockdown()) then
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
        if serial~=generation or not Setting(key) then return end
        local unit=StableUnit(guid)
        if button=="LeftButton" then
            if unit then MarkMenu(guid,unit,x,y) end
        elseif not InCombatLockdown() then
            if unit and CanOpenUnitMenu(unit) then
                if not OpenNativeMenu(unit) and C.Bool(UnitIsPlayer(unit)) then
                    local name=Name(unit)
                    if name then PlayerMenu(name,x,y) end
                end
            elseif not unit and GUID("mouseover")==guid and CanOpenUnitMenu("mouseover")
                and C.Bool(UnitIsPlayer("mouseover")) then
                local name=Name("mouseover")
                if name then PlayerMenu(name,x,y) end
            end
        end
    end)
end

local listener=CreateFrame("Frame")
listener:RegisterEvent("GLOBAL_MOUSE_DOWN")
listener:RegisterEvent("GLOBAL_MOUSE_UP")
listener:RegisterEvent("PLAYER_REGEN_DISABLED")
listener:RegisterEvent("PLAYER_TARGET_CHANGED")
listener:SetScript("OnEvent",OnMouse)
