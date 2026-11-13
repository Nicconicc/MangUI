local _,M=...
local C=M.Compat
local stableUnits={"target","focus","player","pet"}
local nameplateUnits={}
local clicks={}
local lastLeft
local popup
local markerWheel
local combatPicker
local generation=0
local targetRevision=0
local hookedMenus={}
local nativeRequests=setmetatable({}, {__mode="k"})
local focusBinding
local focusBound=false
local combatFocusBinding

local function Setting(key)
    local node=M.byID and M.byID.mouseCircle
    return node and node[key]~=false
end

local function Nameplate(unit)
    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return end
    local ok,plate=pcall(C_NamePlate.GetNamePlateForUnit,unit)
    if ok and C.Readable(plate) then return plate end
end

local function IsWorldFocus(frame,plate)
    if not frame or frame==WorldFrame or frame==UIParent then return true end
    if not plate then return false end
    while frame do
        if frame==plate then return true end
        if frame.IsForbidden and frame:IsForbidden() then return false end
        frame=frame:GetParent()
    end
    return false
end

local function WorldHasMouse(plate)
    if GetMouseFoci then
        for _,frame in ipairs(GetMouseFoci() or {}) do
            if not IsWorldFocus(frame,plate) then return false end
        end
        return true
    end
    local frame=GetMouseFocus and GetMouseFocus()
    return IsWorldFocus(frame,plate)
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

local function MarkerUnit(guid)
    -- Restricted creature GUIDs fall back to the player's confirmed target.
    -- A target change invalidates that selection even if the old target returns.
    if type(guid)=="number" then
        if guid==targetRevision and C.Bool(UnitExists("target")) then return "target" end
        return
    end
    local unit=StableUnit(guid)
    if unit then return unit end
    if UnitTokenFromGUID then
        local ok,token=pcall(UnitTokenFromGUID,guid)
        if ok and C.Readable(token) and type(token)=="string" and token~="mouseover" and GUID(token)==guid then
            return token
        end
    end
    for token in pairs(nameplateUnits) do
        if GUID(token)==guid then return token end
    end
    if GUID("mouseover")==guid then return "mouseover" end
end

local function HoveredTarget(plate)
    local ok,same=pcall(UnitIsUnit,"mouseover","target")
    if ok and C.Readable(same) and type(same)=="boolean" then return same end
    return plate~=nil and plate==Nameplate("target")
end

local function CanOpenUnitMenu(unit)
    if not C.Bool(UnitIsPlayer(unit)) or not C.Bool(UnitIsFriend("player",unit)) then return false end
    local attackable=UnitCanAttack("player",unit)
    return C.Readable(attackable) and not attackable
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

local function LeftModifier()
    if IsControlKeyDown and IsControlKeyDown() then return "other" end
    local alt=IsAltKeyDown and IsAltKeyDown()
    local shift=IsShiftKeyDown and IsShiftKeyDown()
    if alt and shift then return "other" end
    if alt then return "alt" end
    if shift then return "shift" end
end

local clearFocusMacro="/clearfocus [@mouseover,noexists,nocombat,mod:shift,nomod:alt,nomod:ctrl]"

local function WorldFocusAction()
    if not FocusUnit or not Setting("mouseShiftFocus") or LeftModifier()~="shift" then return end
    if C.Bool(UnitExists("mouseover")) then
        if WorldHasMouse(Nameplate("mouseover")) then return "focus" end
    elseif C.Bool(UnitExists("focus")) and WorldHasMouse() then
        return "macro"
    end
end

local function RefreshFocusBinding()
    if InCombatLockdown() or not SetOverrideBindingClick or not ClearOverrideBindings then return end
    local active=WorldFocusAction()~=nil
    if active==focusBound then return end
    if not active then
        ClearOverrideBindings(focusBinding)
        focusBound=false
        return
    end
    if not focusBinding then
        focusBinding=CreateFrame("Frame",nil,UIParent,"SecureHandlerStateTemplate")
        local button=CreateFrame("Button","MangUIUFWorldMouseFocus",UIParent,"SecureActionButtonTemplate")
        button:SetSize(1,1);button:SetPoint("CENTER");button:SetAlpha(0)
        button:EnableMouse(false)
        if C.interface==16001 then
            -- Configure the macro before the client's world click is dispatched.
            button:RegisterForClicks("AnyDown","AnyUp")
            button:SetAttribute("type1","macro")
            button:SetAttribute("macrotext1","/focus [@mouseover,exists,nocombat,mod:shift,nomod:alt,nomod:ctrl]\n"..clearFocusMacro)
            focusBinding:SetAttribute("_onstate-combat",[[if newstate=="combat" then self:ClearBindings() end]])
        else
            button:RegisterForClicks("LeftButtonDown","LeftButtonUp")
            button:SetAttribute("unit","mouseover")
            button:SetAttribute("useOnKeyDown",false)
            button:SetAttribute("macrotext",clearFocusMacro)
            button:SetScript("PreClick",function(self)
                if not InCombatLockdown() then
                    self:SetAttribute("type",WorldFocusAction())
                end
            end)
            focusBinding:SetFrameRef("button",button)
            focusBinding:SetAttribute("_onstate-combat",[[ if newstate=="combat" then
                self:ClearBindings()
                self:GetFrameRef("button"):SetAttribute("type",nil)
            end ]])
        end
        RegisterStateDriver(focusBinding,"combat","[combat] combat; safe")
    end
    SetOverrideBindingClick(focusBinding,true,"SHIFT-BUTTON1","MangUIUFWorldMouseFocus","LeftButton")
    focusBound=true
end

local function PollFocusBinding(listener)
    RefreshFocusBinding()
    if LeftModifier()~="shift" then listener:SetScript("OnUpdate",nil) end
end

local function ConfigureCombatFocus(enabled)
    if not combatFocusBinding then
        if not enabled or not SecureHandlerWrapScript then return end
        local owner=CreateFrame("Frame",nil,UIParent,"SecureHandlerStateTemplate")
        local button=CreateFrame("Button","MangUIUFCombatMouseFocus",UIParent,"SecureActionButtonTemplate")
        button:SetSize(1,1);button:SetPoint("CENTER");button:SetAlpha(0)
        button:EnableMouse(false)
        button:RegisterForClicks("AnyDown","AnyUp")
        button:SetAttribute("useOnKeyDown",false)
        button:SetAttribute("unit","mouseover")
        if C.interface==16001 then
            button:SetAttribute("macrotext1","/focus [@mouseover,exists,mod:shift,nomod:alt,nomod:ctrl]")
        end
        owner:SetAttribute("focus-action",C.interface==16001 and "macro" or "focus")
        SecureHandlerWrapScript(button,"OnClick",owner,[[
            local valid=control:GetAttribute("focus-enabled")
                and SecureCmdOptionParse("[combat,@mouseover,exists,mod:shift,nomod:alt,nomod:ctrl] yes")
            self:SetAttribute("type1",valid and control:GetAttribute("focus-action") or nil)
        ]])
        owner:SetAttribute("_onstate-worldfocus",[[
            self:ClearBindings()
            if newstate=="active" and self:GetAttribute("focus-enabled") then
                self:SetBindingClick(true,"SHIFT-BUTTON1","MangUIUFCombatMouseFocus","LeftButton")
            end
        ]])
        owner:SetAttribute("focus-enabled",true)
        RegisterStateDriver(owner,"worldfocus","[combat,@mouseover,exists] active; inactive")
        combatFocusBinding=owner
    end
    combatFocusBinding:SetAttribute("focus-enabled",not not enabled)
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
        if panel.key=="mouseUnitMarks" and (type(panel.guid)=="number" or not unit or GUID(unit)~=panel.guid) then
            unit=MarkerUnit(panel.guid)
        elseif not unit or GUID(unit)~=panel.guid then
            unit=nil
        end
        local valid=panel:IsShown() and unit and Setting(panel.key)
            and (panel.key~="mouseUnitMenu" or CanOpenUnitMenu(unit))
        self:SetAttribute("type",valid and (kind or panel.confirmation and panel.confirmation.kind) or nil)
        self:SetAttribute("unit",valid and unit or nil)
    end)
    button:SetScript("PostClick",function()
        if not InCombatLockdown() then panel:Hide() end
    end)
    return button
end

local markerLabels={"星形","圆形","菱形","三角形","月亮","方块","十字","骷髅"}
-- These Classic interfaces allow direct marking outside combat. Forever and
-- modern Retail require the secure click even when the player is out of combat.
local hoverMarkerClients={[11509]=true,[20506]=true,[50504]=true}
local function ApplyHoveredMarker(panel,marker)
    if not hoverMarkerClients[C.interface] or not SetRaidTarget or InCombatLockdown()
        or not panel:IsShown() or not Setting("mouseUnitMarks") then return end
    local unit=MarkerUnit(panel.guid)
    if not unit then return end
    local ok=pcall(SetRaidTarget,unit,marker)
    if ok then panel:Hide() end
end
local function WheelDisk(parent,layer,size,r,g,b,a)
    local disk=parent:CreateTexture(nil,layer)
    disk:SetSize(size,size);disk:SetPoint("CENTER")
    disk:SetColorTexture(r,g,b,a)
    local mask=parent:CreateMaskTexture()
    mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(disk);disk:AddMaskTexture(mask)
    return disk
end
local function AddMarkerButtons(panel,parent,radial,combat)
    for i=1,9 do
        local clear=i==9
        local marker=clear and 0 or i
        local label=clear and (REMOVE_RAID_TARGET_ICON or "清除标记")
            or _G["RAID_TARGET_"..i] or markerLabels[i]
        local button
        if combat then
            button=MenuRow(parent,label,true)
            button:RegisterForClicks("LeftButtonUp")
            button:SetAttribute("useOnKeyDown",false)
            button:SetAttribute("type","raidtarget")
            button:SetAttribute("unit","target")
            SecureHandlerWrapScript(button,"PostClick",panel,[[control:Hide()]])
        else
            button=SecureRow(panel,parent,label,"raidtarget")
        end
        if radial then
            local angle=math.pi/2-(i-1)*2*math.pi/9
            button:SetSize(44,44)
            button:SetPoint("CENTER",math.cos(angle)*74,math.sin(angle)*74)
            button.label:Hide()
            button:GetHighlightTexture():SetAlpha(0)
            local highlight=WheelDisk(button,"BACKGROUND",44,.95,.72,.23,.48)
            highlight:Hide()
            button:SetScript("OnEnter",function()
                highlight:Show()
                panel.markerSelection:SetText(M:T(label))
                if not combat then ApplyHoveredMarker(panel,marker) end
            end)
            button:SetScript("OnLeave",function()
                highlight:Hide()
                panel.markerSelection:SetText("")
            end)
            button:HookScript("OnHide",function() highlight:Hide() end)
        else
            button:SetPoint("TOPLEFT",8,-8-(i-1)*rowHeight)
        end
        button:SetAttribute("marker",marker)
        button:SetAttribute("action",clear and "clear" or "set")
        if radial or not clear then
            local icon=button:CreateTexture(nil,"ARTWORK")
            if radial then
                icon:SetSize(32,32);icon:SetPoint("CENTER")
            else
                icon:SetSize(14,14);icon:SetPoint("LEFT",5,0)
                button.label:ClearAllPoints();button.label:SetPoint("LEFT",24,0)
            end
            if clear then
                icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
            else
                icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
                if SetRaidTargetIconTexture then
                    SetRaidTargetIconTexture(icon,i)
                else
                    local left,top=(i-1)%4/4,math.floor((i-1)/4)/4
                    icon:SetTexCoord(left,left+.25,top,top+.25)
                end
            end
        end
    end
end

local function MenuTitle(panel,text)
    local title=M.Widgets.Label(panel,text,12)
    title:SetPoint("TOPLEFT",13,-10);title:SetPoint("TOPRIGHT",-13,-10)
    title:SetJustifyH("LEFT");title:SetWordWrap(false);title:SetTextColor(1,.82,0)
    return title
end

local function CreateMarkerWheel(combat)
    local wheel=CreateFrame("Frame",nil,UIParent,"SecureHandlerStateTemplate")
    wheel:SetSize(200,200)
    wheel:SetFrameStrata("DIALOG")
    wheel:SetClampedToScreen(true)
    wheel:EnableMouse(true)
    wheel:Hide()
    WheelDisk(wheel,"BACKGROUND",200,0,0,0,.75)
    local rim=wheel:CreateTexture(nil,"BORDER")
    rim:SetAllPoints(wheel)
    rim:SetTexture(M.ART.."UI\\MarkerWheelRim.tga")
    rim:SetVertexColor(.78,.59,.24,.94)
    wheel.title=M.Widgets.Label(wheel,"",12)
    wheel.title:SetPoint("CENTER",0,10);wheel.title:SetWidth(105);wheel.title:SetJustifyH("CENTER");wheel.title:SetWordWrap(false)
    wheel.title:SetTextColor(1,.82,0)
    wheel.markerSelection=M.Widgets.Label(wheel,"",11)
    wheel.markerSelection:SetPoint("CENTER",0,-13);wheel.markerSelection:SetWidth(105);wheel.markerSelection:SetJustifyH("CENTER")
    wheel.markerSelection:SetWordWrap(false)
    AddMarkerButtons(wheel,wheel,true,combat)
    return wheel
end

local function OpenMarkerWheel(guid,unit,x,y)
    if not markerWheel then
        markerWheel=CreateMarkerWheel(false)
        markerWheel:SetAttribute("_onstate-combat",[[if newstate=="combat" then self:Hide() end]])
        RegisterStateDriver(markerWheel,"combat","[combat] combat; safe")
    end
    local wheel=markerWheel
    wheel.key,wheel.guid,wheel.unit="mouseUnitMarks",guid,unit
    wheel.title:SetText(Name(unit) or M:T("选择标记"))
    wheel.markerSelection:SetText("")
    local scale=UIParent:GetEffectiveScale()
    wheel:ClearAllPoints()
    wheel:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x/scale,y/scale)
    wheel:Show()
end

function M:NormalizeCombatMarkerKey(value)
    if type(value)~="string" then return nil end
    local key=value:upper():gsub("%s+",""):gsub("%+","-")
    if key=="" then return "" end
    local modifiers={}
    while true do
        local modifier,rest=key:match("^(%a+)%-(.+)$")
        if not modifier then break end
        if modifiers[modifier] or (modifier~="ALT" and modifier~="CTRL" and modifier~="SHIFT") then return nil end
        modifiers[modifier]=true
        key=rest
    end
    if not (key:match("^[A-Z0-9]$") or key:match("^F[1-9]$") or key:match("^F1[0-2]$")) then return nil end
    return (modifiers.ALT and "ALT-" or "")..(modifiers.CTRL and "CTRL-" or "")
        ..(modifiers.SHIFT and "SHIFT-" or "")..key
end

local function UpdateCombatMarkerTitle(panel)
    panel.title:SetText(Name("target") or M:T("选择标记"))
end

local function CombatPicker(key)
    if combatPicker then return combatPicker end
    local panel=CreateMarkerWheel(true)
    panel:HookScript("OnShow",function(self)
        UpdateCombatMarkerTitle(self)
        self.markerSelection:SetText("")
    end)

    local opener=CreateFrame("Button","MangUIUFCombatMarkerMenu",UIParent,"SecureHandlerClickTemplate")
    opener:SetSize(1,1);opener:SetPoint("CENTER");opener:SetAlpha(0);opener:EnableMouse(false)
    opener:RegisterForClicks("AnyUp")
    opener:SetFrameRef("panel",panel)
    opener:SetAttribute("_onclick",[[
        if button~="LeftButton" or down or not SecureCmdOptionParse("[combat,@target,exists] yes") then return end
        local menu=self:GetFrameRef("panel")
        if not menu:GetAttribute("marker-key") then return end
        if menu:IsShown() then menu:Hide();return end
        menu:ClearAllPoints()
        menu:SetPoint("CENTER","$cursor","BOTTOMLEFT",0,0)
        menu:Show()
        menu:RegisterAutoHide(1.2)
    ]])
    panel:SetAttribute("marker-key",key)
    panel:SetAttribute("_onstate-combat",[[
        self:Hide()
        self:ClearBindings()
        local key=self:GetAttribute("marker-key")
        if newstate=="active" and key then
            self:SetBindingClick(true,key,"MangUIUFCombatMarkerMenu","LeftButton")
        end
    ]])
    RegisterStateDriver(panel,"combat","[combat,@target,exists] active; inactive")
    combatPicker=panel
    return panel
end

function M:RefreshTargetMouseShortcuts()
    if InCombatLockdown() then return end
    local focusEnabled=FocusUnit and Setting("mouseShiftFocus")
    ConfigureCombatFocus(focusEnabled)
    local node=self.byID and self.byID.mouseCircle
    local key=node and self:NormalizeCombatMarkerKey(node.mouseCombatMarkerKey)
    if key=="" then key=nil end
    local panel=key and SecureHandlerWrapScript and CombatPicker(key) or combatPicker
    if panel then
        panel:SetAttribute("marker-key",key or nil)
        if not key then panel:Hide() end
    end
    for _,object in ipairs(self.live.ordered) do
        local spec,button=object.spec,object.frame
        if spec.kind=="hitbox" and spec.unit=="target" then
            local action=button:GetAttribute("shift-type1")
            if focusEnabled and not action then
                button:SetAttribute("shift-type1","focus")
                button.manguiShiftFocus=true
            elseif not focusEnabled and button.manguiShiftFocus then
                if action=="focus" then button:SetAttribute("shift-type1",nil) end
                button.manguiShiftFocus=nil
            end
        end
    end
end

local function MarkerMenu(panel)
    local submenu=MenuFrame(panel)
    submenu:SetSize(width,9*rowHeight+16)
    submenu:SetFrameLevel(panel:GetFrameLevel()+5)
    AddMarkerButtons(panel,submenu,false)
    return submenu
end

local function Popup()
    if popup then return popup end
    local panel=MenuFrame(UIParent,true)
    popup=panel
    panel:SetAttribute("_onstate-combat",[[ if newstate=="combat" then self:Hide() end ]])
    RegisterStateDriver(panel,"combat","[combat] combat; safe")
    panel.title=MenuTitle(panel,"")
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
    panel.confirmRow=SecureRow(panel,panel,"")
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

local function OpenMenu(key,guid,unit,playerName,x,y,confirmation)
    local panel=Popup()
    panel.key,panel.guid,panel.unit,panel.nameText=key,guid,unit,playerName
    panel.confirmation=confirmation
    panel.title:SetText(unit and Name(unit) or playerName or M:T("选择标记"))
    panel.markers:Hide()
    local offset=28
    local function PlaceRow(row,visible)
        row:SetShown(visible)
        if not visible then return end
        row:ClearAllPoints();row:SetPoint("TOPLEFT",8,-offset)
        offset=offset+rowHeight
    end
    PlaceRow(panel.markRow,unit~=nil and not confirmation)
    PlaceRow(panel.focusRow,unit~=nil and not confirmation and type(FocusUnit)=="function")
    if confirmation then
        panel.confirmRow.label:SetText(confirmation.label)
        panel.confirmRow:SetAttribute("marker",confirmation.marker)
        panel.confirmRow:SetAttribute("action",confirmation.marker and (confirmation.marker==0 and "clear" or "set") or nil)
    end
    PlaceRow(panel.confirmRow,confirmation~=nil)
    PlaceRow(panel.whisperRow,playerName~=nil)
    PlaceRow(panel.inviteRow,playerName~=nil)
    local scale=UIParent:GetEffectiveScale()
    panel:SetSize(width,offset+7);panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x/scale+8,y/scale-6)
    panel:Show()
end

local function NativeMenuType(unit)
    if not unit then return "PLAYER" end
    if C.Bool(UnitIsUnit(unit,"player")) then return "SELF" end
    if unit:match("^raid%d+$") or UnitInRaid and C.Number(UnitInRaid(unit)) then return "RAID_PLAYER" end
    if unit:match("^party%d+$") or UnitInParty and C.Bool(UnitInParty(unit)) then return "PARTY" end
    return "PLAYER"
end

local function SecureNativeEntries(description,request)
    for _,entry in description:EnumerateElementDescriptions() do
        entry:AddInitializer(function(frame,element)
            local label=frame.fontString and frame.fontString:GetText()
            if not C.Readable(label) or type(label)~="string" then return end
            local kind,marker
            if label==SET_FOCUS then
                kind="focus"
            elseif element.IsRadio and element:IsRadio() then
                if label==RAID_TARGET_NONE then marker=0 end
                for index=1,8 do
                    if label==_G["RAID_TARGET_"..index] then marker=index;break end
                end
                if marker~=nil then kind="raidtarget" end
            end
            if not kind then return end
            -- A native responder cannot run a protected action from addon Lua.
            -- Route it to an actual secure button for the hardware click.
            element:SetResponder(function()
                local x,y=GetCursorPosition()
                local serial=generation
                C_Timer.After(0,function()
                    if serial~=generation or InCombatLockdown() or not Setting("mouseUnitMenu")
                        or GUID(request.unit)~=request.guid or not CanOpenUnitMenu(request.unit) then return end
                    OpenMenu("mouseUnitMenu",request.guid,request.unit,nil,x,y,{kind=kind,marker=marker,label=label})
                end)
                return MenuResponse and MenuResponse.Close
            end)
        end)
        SecureNativeEntries(entry,request)
    end
end

local function OpenNativeMenu(guid,unit,playerName)
    if not UnitPopup_OpenMenu then return false end
    local which=NativeMenuType(unit)
    local context={unit=unit,name=playerName,fromTargetFrame=unit=="target"}
    if InCombatLockdown() then return pcall(UnitPopup_OpenMenu,which,context) end
    if not (Menu and Menu.ModifyMenu) then return false end
    if not hookedMenus[which] then
        Menu.ModifyMenu("MENU_UNIT_"..which,function(_,description,context)
            local request=context and nativeRequests[context]
            if request then SecureNativeEntries(description,request) end
        end)
        hookedMenus[which]=true
    end
    if unit then nativeRequests[context]={unit=unit,guid=guid} end
    return pcall(UnitPopup_OpenMenu,which,context)
end

local function OnMouse(listener,event,button,keyDown)
    if event=="NAME_PLATE_UNIT_ADDED" then
        nameplateUnits[button]=true
        return
    elseif event=="NAME_PLATE_UNIT_REMOVED" then
        nameplateUnits[button]=nil
        return
    elseif event=="UPDATE_MOUSEOVER_UNIT" then
        RefreshFocusBinding()
        return
    end
    if event=="MODIFIER_STATE_CHANGED" or event=="PLAYER_REGEN_ENABLED" then
        local shiftPressed=keyDown==1 and (button=="LSHIFT" or button=="RSHIFT")
        listener:SetScript("OnUpdate",(shiftPressed or LeftModifier()=="shift") and PollFocusBinding or nil)
        RefreshFocusBinding()
        return
    end
    if event=="PLAYER_REGEN_DISABLED" then
        generation=generation+1;lastLeft=nil
        focusBound=false
        listener:SetScript("OnUpdate",nil)
        for key in pairs(clicks) do clicks[key]=nil end
        -- The combat state driver hides the protected menu.
        return
    end
    if event=="PLAYER_TARGET_CHANGED" then
        targetRevision=targetRevision+1
        if popup and not InCombatLockdown() then popup:Hide() end
        if markerWheel and not InCombatLockdown() then markerWheel:Hide() end
        if combatPicker and combatPicker:IsShown() then UpdateCombatMarkerTitle(combatPicker) end
        return
    end
    local combat=InCombatLockdown()
    if event=="GLOBAL_MOUSE_DOWN" then
        generation=generation+1
        if not combat and markerWheel and markerWheel:IsShown() and not markerWheel:IsMouseOver() then
            markerWheel:Hide()
        end
        if not combat and popup and popup:IsShown() and not popup:IsMouseOver()
            and not (popup.markers:IsShown() and popup.markers:IsMouseOver()) then
            popup:Hide()
        end
    end
    local previous=clicks[button];clicks[button]=nil
    local key
    if button=="RightButton" then
        key="mouseUnitMenu"
    elseif button=="LeftButton" then
        local modifier=LeftModifier()
        if modifier then lastLeft=nil end
        if modifier=="alt" then key="mouseAltInvite"
        elseif not modifier and not combat then key="mouseUnitMarks" end
    end
    if not key then return end
    local guid,targetFallback
    local enabled=Setting(key)
    local plate=enabled and key=="mouseUnitMarks" and Nameplate("mouseover") or nil
    if enabled and WorldHasMouse(plate) then
        guid=GUID("mouseover")
        if button=="RightButton" then
            if guid and not CanOpenUnitMenu("mouseover") then
                return
            elseif not guid and event=="GLOBAL_MOUSE_UP" and previous then
                -- Releasing the camera button can restore mouseover on the next frame.
                guid=previous.guid
            end
        elseif key=="mouseUnitMarks" and not guid and event=="GLOBAL_MOUSE_UP" and previous
            and previous.guid and GUID("target")==previous.guid then
            guid=previous.guid
        elseif key=="mouseUnitMarks" and not guid and C.Bool(UnitExists("mouseover")) then
            targetFallback=true
            if event=="GLOBAL_MOUSE_UP" and previous and previous.targetFallback and HoveredTarget(plate) then
                guid=targetRevision
            end
        end
    end
    if not guid and not (event=="GLOBAL_MOUSE_DOWN" and targetFallback) then
        if button=="LeftButton" then lastLeft=nil end
        return
    end
    local x,y=GetCursorPosition()
    local now=GetTime()
    if event=="GLOBAL_MOUSE_DOWN" then
        clicks[button]={guid=guid,targetFallback=targetFallback,x=x,y=y,time=now,key=key}
        return
    end
    if not previous or key~=previous.key or (guid~=previous.guid and not (targetFallback and previous.targetFallback)) or now-previous.time>.5
        or math.abs(x-previous.x)>8 or math.abs(y-previous.y)>8 then
        if button=="LeftButton" then lastLeft=nil end
        return
    end
    if key=="mouseAltInvite" then
        if C.Bool(UnitIsPlayer("mouseover")) and not C.Bool(UnitIsUnit("mouseover","player")) then
            local name=Name("mouseover")
            local invite=C_PartyInfo and C_PartyInfo.InviteUnit or InviteUnit
            if invite and name then pcall(invite,name) end
        end
        return
    end
    if key=="mouseUnitMarks" then
        local first=lastLeft
        lastLeft={guid=guid,time=now,x=x,y=y}
        if not first or first.guid~=guid or now-first.time>.35
            or math.abs(x-first.x)>12 or math.abs(y-first.y)>12 then return end
        lastLeft=nil
    end
    local serial=generation
    C_Timer.After(0,function()
        if serial~=generation or not Setting(key) or combat~=InCombatLockdown() then return end
        if key=="mouseUnitMarks" then
            local unit=MarkerUnit(guid)
            if unit then OpenMarkerWheel(guid,unit,x,y) end
            return
        end
        local unit=StableUnit(guid)
        if unit and CanOpenUnitMenu(unit) then
            local name=unit~="player" and Name(unit) or nil
            if not OpenNativeMenu(guid,unit,name) and not combat then OpenMenu(key,guid,unit,name,x,y) end
        elseif not unit and GUID("mouseover")==guid and CanOpenUnitMenu("mouseover") then
            local name=Name("mouseover")
            if name and not OpenNativeMenu(guid,nil,name) and not combat then OpenMenu(key,guid,nil,name,x,y) end
        end
    end)
end

local listener=CreateFrame("Frame")
listener:RegisterEvent("GLOBAL_MOUSE_DOWN")
listener:RegisterEvent("GLOBAL_MOUSE_UP")
listener:RegisterEvent("PLAYER_REGEN_DISABLED")
listener:RegisterEvent("PLAYER_REGEN_ENABLED")
listener:RegisterEvent("MODIFIER_STATE_CHANGED")
listener:RegisterEvent("PLAYER_TARGET_CHANGED")
listener:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
listener:RegisterEvent("NAME_PLATE_UNIT_ADDED")
listener:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
listener:SetScript("OnEvent",OnMouse)
