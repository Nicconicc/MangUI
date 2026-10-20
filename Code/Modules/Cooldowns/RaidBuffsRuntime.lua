local _,M=...
local I,S=M.RaidBuffMonitor,M.PlayerSkillMonitor
local Safe,Number,Readable=I.Safe,I.Number,I.Readable
local function NativeAvailable()
    local interface=M.Compat.interface or 0
    if interface~=16001 and interface<120000 then return false end
    if not C_XMLUtil or not C_XMLUtil.GetTemplateInfo then return false end
    if not C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")and not InCombatLockdown()and C_AddOns then Safe(C_AddOns.LoadAddOn,"Blizzard_AuraContainer")end
    return C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")~=nil
end
local function ResolveSlot(slot,entry)
    local ids,keys={},{}
    slot.spells=I.Options(entry);slot.spell=I.Resolve(entry)
    for _,spell in ipairs(slot.spells)do
        if spell.ids then for id in pairs(spell.ids)do ids[id]=true end
        elseif spell.id then ids[spell.id]=true end
        keys[#keys+1]=spell.value..":"..tostring(spell.id)..":"..tostring(spell.revision)
        if not spell.id then I.RequestBuffName(spell.value)end
    end
    local key=table.concat(keys,"|");local changed=key~=slot.lookupKey
    slot.ids,slot.lookupKey=ids,key;slot.texture:SetTexture(slot.spell.icon or 134400)
    return changed
end
local function Bind(slot)
    slot.pending=nil
    if slot.container then slot.container:SetEnabled(false)end
    slot.bound=false
    for _,frame in ipairs(slot.nativeFrames or {})do frame.gate:SetAlpha(1)end
    if not next(slot.ids)then return end
    if not slot.container then
        local container=CreateFrame("AuraContainer",nil,slot,"CustomAuraContainerTemplate")
        container:SetEnabled(false);container:SetPoint("TOPLEFT",slot,"TOPLEFT",0,0);slot.container=container;slot.nativeFrames={}
        container:AddAuraGroup("missing","HELPFUL",{maxFrameCount=0,initializeFrame=function(frame)
            frame:SetSize(40,40);frame:EnableMouse(false)
            -- The native engine gates the missing-Buff icon without Lua
            -- comparing a protected aura-presence value during combat.
            frame.gate=CreateFrame("Frame",nil,slot.lastGate or slot.base);frame.gate:SetAllPoints();frame.gate:EnableMouse(false)
            slot.lastGate=frame.gate;slot.texture:SetParent(frame.gate)
            slot.nativeFrames[#slot.nativeFrames+1]=frame
        end})
        container:SetFlowLayoutAnchorPoint("TOPLEFT");container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right,AnchorUtil.FlowDirection.Down)
        container:SetFlowLayoutMaximumLineSize(40.001)
        container:SetAuraGroupLayout("missing",{elementSpacing=0,lineSpacing=0,elementWidth=40,elementHeight=40})
    end
    slot.container:SetUnit("player")
    slot.container:SetAuraGroupCandidateFilters("missing",{includeSpellIDs=slot.ids})
    slot.container:SetAuraGroupMaxFrameCount("missing",1)
    slot.container:SetEnabled(true);slot.container:UpdateAllAuras();slot.bound=true
end
local function Icon(o,index)
    local slot=o.buffIcons[index];if slot then return slot end
    slot=CreateFrame("Frame",nil,o.frame);slot:SetSize(40,40);slot:EnableMouse(false);slot:EnableMouseMotion(true)
    slot.base=CreateFrame("Frame",nil,slot);slot.base:SetAllPoints();slot.base:EnableMouse(false)
    slot.texture=slot.base:CreateTexture(nil,"ARTWORK");slot.texture:SetAllPoints()
    slot:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        if self.spell.id and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(self.spell.id)
        else GameTooltip:SetText(self.spell.name or "",1,1,1,1,true)end
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave",function()GameTooltip:Hide()end)
    o.buffIcons[index]=slot;return slot
end
function I.Configure(view,o)
    o.buffIcons=o.buffIcons or {};o.entries=I.Entries(view.byID[o.spec.parent]);o.native=not view.preview and NativeAvailable()
    for index,entry in ipairs(o.entries)do
        local slot=Icon(o,index);slot.entry=entry;ResolveSlot(slot,entry)
        if not view.preview then
            if InCombatLockdown()then slot.pending=true
            elseif o.native then Bind(slot)
            elseif slot.container then slot.container:SetEnabled(false);slot.bound=false end
        end
    end
    for index=#o.entries+1,#o.buffIcons do
        local slot=o.buffIcons[index];slot:Hide();slot.entry=nil
        if slot.container then slot.container:SetEnabled(false)end
    end
    o.nextScan=0;o.nextInfo=0
end
local function Auras()
    if C_Secrets and C_Secrets.ShouldAurasBeSecret then
        local secret=Safe(C_Secrets.ShouldAurasBeSecret,"player")
        if not Readable(secret)or secret==true then return end
    end
    local byID,byName={},{}
    for index=1,255 do
        local aura=M.Compat.Aura("player",index,"HELPFUL");if not aura then break end
        I.RememberBuffAura(aura)
        local id=aura.spellId;if type(id)=="nil"then id=aura.spellID end
        if Readable(id)and type(id)=="number"then byID[id]=aura end
        if Readable(aura.name)and type(aura.name)=="string"then byName[aura.name]=aura end
    end
    return byID,byName
end
function I.Paint(view,o,animateOnly)
    local group=view.byID[o.spec.parent]
    local raid=M.Compat.Bool(Safe(IsInRaid))or (Number(Safe(GetNumRaidMembers))or 0)>0
    local shown=not(view.hidden and view.hidden[o.spec.id])and (view.preview or
        (group.enabled~=false and o.spec.enabled~=false and (not group.raidOnly or raid)
        and (not group.hideWithoutTarget or M.Compat.Bool(Safe(UnitExists,"target")))))
    o.frame:SetShown(shown);if not shown then return end
    local now=GetTime();if animateOnly and now<(o.nextScan or 0)then return end;o.nextScan=now+.1
    local byID,byName;if not view.preview then byID,byName=Auras()end
    local displayed={}
    for _,slot in ipairs(o.buffIcons or {})do
        if slot.entry then
            if now>=(o.nextInfo or 0)then
                local changed=ResolveSlot(slot,slot.entry)
                if o.native and (changed or not slot.bound)then slot.pending=true end
            end
            if slot.pending and o.native and not InCombatLockdown()then Bind(slot)end
            local active
            if byID then
                for _,spell in ipairs(slot.spells)do
                    if (spell.id and byID[spell.id])or (not tonumber(spell.value)and byName[spell.value])then active=true;break end
                end
            end
            local visible=view.preview or (o.native and slot.bound)or not active
            slot:SetShown(visible)
            if visible then displayed[#displayed+1]=slot end
            slot.texture:SetDesaturated(false);slot.texture:SetAlpha(1)
            if o.native and slot.bound then
                for _,frame in ipairs(slot.nativeFrames or {})do
                    local present=frame:IsShown()
                    if frame.gate.SetAlphaFromBoolean then frame.gate:SetAlphaFromBoolean(present,0,1)
                    elseif Readable(present)then frame.gate:SetAlpha(present and 0 or 1)end
                end
            end
        end
    end
    if now>=(o.nextInfo or 0)then o.nextInfo=now+1 end
    o.rowCount=#displayed;local width=math.max(1,#displayed*44-4)
    if o.rowWidth~=width then o.rowWidth=width;o.frame:SetSize(width,66)end
    for index,slot in ipairs(displayed)do
        local x=S.IconOffset(group,index,#displayed)
        if slot.rowX~=x then slot.rowX=x;slot:ClearAllPoints();slot:SetPoint("CENTER",o.frame,"CENTER",x,-7)end
    end
end
function I.Event(view,event,unit)
    if event=="UNIT_AURA"and unit~="player"then return end
    if event~="UNIT_AURA"and event~="GROUP_ROSTER_UPDATE"and event~="PLAYER_ENTERING_WORLD"and event~="PLAYER_TARGET_CHANGED"
        and event~="PLAYER_REGEN_ENABLED"and event~="SPELLS_CHANGED"then return end
    local o=view.nodes.raidBuffsIcons;if not o then return end
    o.nextScan=0;if event~="UNIT_AURA"then o.nextInfo=0 end
    I.Paint(view,o,false)
end
function I.Remove(view,o)
    for _,slot in ipairs(o.buffIcons or {})do if slot.container then slot.container:SetEnabled(false)end end
end
