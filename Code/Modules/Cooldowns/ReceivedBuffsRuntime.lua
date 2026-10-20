local _,M=...
local I,S=M.ReceivedBuffs,M.PlayerSkillMonitor
local Safe,Number,Readable=I.Safe,I.Number,I.Readable
local function Font(text)
    text:SetFont(M:EffectiveFontPath(M.MYRIAD),16,"OUTLINE");text:SetTextColor(1,1,1,1);text:SetJustifyH("CENTER")
    text:SetShadowColor(0,0,0,0);text:SetShadowOffset(0,0)
end
local function NativeAvailable()
    local interface=M.Compat.interface or 0
    if interface~=16001 and interface<120000 then return false end
    if not C_XMLUtil or not C_XMLUtil.GetTemplateInfo then return false end
    if not C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")and not InCombatLockdown()and C_AddOns then Safe(C_AddOns.LoadAddOn,"Blizzard_AuraContainer")end
    return C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")~=nil
end
local function OtherPlayer(source)
    if not Readable(source)or type(source)~="string"then return false end
    for _,own in ipairs({"player","pet","vehicle"})do
        if source==own or M.Compat.Bool(Safe(UnitIsUnit,source,own))then return false end
    end
    local player=Safe(UnitIsPlayer,source);local controlled=Safe(UnitPlayerControlled,source)
    if M.Compat.Bool(player)or M.Compat.Bool(controlled)then return true end
    -- Old clients may not expose UnitPlayerControlled for pet unit tokens.
    return type(player)=="nil"and type(controlled)=="nil"and (source:match("^party%d+$")~=nil or source:match("^raid%d+$")~=nil)
end
local function Resolve(slot,entry)
    local spell=M.RaidBuffMonitor.ResolveValue(entry.value)
    if not spell.id then M.RaidBuffMonitor.RequestBuffName(entry.value)end
    local key=entry.value..":"..tostring(spell.id)..":"..tostring(spell.revision)
    local changed=slot.lookupKey~=key;slot.lookupKey=key;slot.spell=spell
    slot.texture:SetTexture(spell.icon or 134400)
    return changed
end
local function Bind(slot)
    slot.pending=nil;slot.bound=false
    if slot.container then slot.container:SetEnabled(false)end
    if not slot.spell.id then return end
    if not slot.container then
        local container=CreateFrame("AuraContainer",nil,slot,"CustomAuraContainerTemplate")
        container:SetEnabled(false);container:SetPoint("TOPLEFT",slot,"TOPLEFT",0,0);slot.container=container
        container:AddAuraGroup("received","HELPFUL|!PLAYER",{maxFrameCount=0,initializeFrame=function(frame)
            frame:SetSize(40,40);frame:EnableMouse(false);frame:EnableMouseMotion(true)
            frame:SetTooltipAnchorPoint("ANCHOR_RIGHT");frame:SetHideTooltipInCombat(false)
            frame.icon=frame:CreateTexture(nil,"ARTWORK");frame.icon:SetAllPoints();frame:SetIcon(frame.icon)
            frame.time=frame:CreateFontString(nil,"OVERLAY");Font(frame.time);frame.time:SetPoint("BOTTOM",frame,"TOP",0,7)
            frame.count=frame:CreateFontString(nil,"OVERLAY");Font(frame.count);frame.count:SetPoint("BOTTOM",frame,"TOP",0,29)
            frame:SetDurationText(frame.time,S.DurationTextOptions());frame:SetApplicationCount(frame.count,{})
        end})
        container:SetFlowLayoutAnchorPoint("TOPLEFT");container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right,AnchorUtil.FlowDirection.Down)
        container:SetFlowLayoutMaximumLineSize(40.001)
        container:SetAuraGroupLayout("received",{elementSpacing=0,lineSpacing=0,elementWidth=40,elementHeight=40})
    end
    slot.container:SetUnit("player")
    slot.container:SetAuraGroupCandidateFilters("received",{includeSpellIDs=slot.spell.ids or {[slot.spell.id]=true},isFromPlayerOrPlayerPet=true})
    slot.container:SetAuraGroupMaxFrameCount("received",1);slot.container:SetEnabled(true);slot.container:UpdateAllAuras();slot.bound=true
end
local function Icon(o,index)
    local slot=o.buffIcons[index];if slot then return slot end
    slot=CreateFrame("Frame",nil,o.frame);slot:SetSize(40,40);slot:EnableMouse(false);slot:EnableMouseMotion(true)
    slot.base=CreateFrame("Frame",nil,slot);slot.base:SetAllPoints();slot.base:EnableMouse(false)
    slot.texture=slot.base:CreateTexture(nil,"ARTWORK");slot.texture:SetAllPoints()
    slot.time=slot.base:CreateFontString(nil,"OVERLAY");Font(slot.time);slot.time:SetPoint("BOTTOM",slot,"TOP",0,7)
    slot.count=slot.base:CreateFontString(nil,"OVERLAY");Font(slot.count);slot.count:SetPoint("BOTTOM",slot,"TOP",0,29)
    slot:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        if self.auraIndex and GameTooltip.SetUnitAura then GameTooltip:SetUnitAura("player",self.auraIndex,"HELPFUL")
        elseif self.spell.id and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(self.spell.id)
        else GameTooltip:SetText(self.spell.name or "",1,1,1,1,true)end
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave",function()GameTooltip:Hide()end)
    o.buffIcons[index]=slot;return slot
end
function I.Configure(view,o)
    o.buffIcons=o.buffIcons or {};o.entries=I.Entries(view.byID[o.spec.parent]);o.native=not view.preview and NativeAvailable()
    if view.preview and #o.entries==0 then o.entries={{value="10060"},{value="29166"},{value="33206"}}end
    for index,entry in ipairs(o.entries)do
        local slot=Icon(o,index)
        if slot.value~=entry.value then slot.seen=nil;slot.initialized=false;slot.value=entry.value end
        slot.entry=entry;Resolve(slot,entry);Font(slot.time);Font(slot.count)
        if not view.preview then
            if InCombatLockdown()then slot.pending=true
            elseif o.native then Bind(slot)
            elseif slot.container then slot.container:SetEnabled(false);slot.bound=false end
        end
    end
    for index=#o.entries+1,#o.buffIcons do local slot=o.buffIcons[index];slot:Hide();slot.entry=nil;if slot.container then slot.container:SetEnabled(false)end end
    o.nextScan=0;o.nextInfo=0
end
local function Auras()
    if C_Secrets and C_Secrets.ShouldAurasBeSecret then
        local secret=Safe(C_Secrets.ShouldAurasBeSecret,"player")
        if not Readable(secret)or secret==true then return end
    end
    local result={}
    for index=1,255 do
        local raw=M.Compat.Aura("player",index,"HELPFUL");if not raw then break end
        if OtherPlayer(raw.sourceUnit)then
            local id=raw.spellId;if type(id)=="nil"then id=raw.spellID end
            -- Own each record because some compatibility implementations reuse it.
            result[#result+1]={name=raw.name,spellId=id,icon=raw.icon,source=raw.sourceUnit,
                expires=raw.expirationTime,count=raw.applications,instance=raw.auraInstanceID,index=index}
            M.RaidBuffMonitor.RememberBuffAura(raw)
        end
    end
    return result
end
local function Scan(slot,auras,play)
    if not auras then return end
    local matched,seen,new=nil,{},false
    for _,aura in ipairs(auras)do
        local id=Number(aura.spellId)
        local match=tonumber(slot.entry.value)and id==tonumber(slot.entry.value)or
            (not tonumber(slot.entry.value)and Readable(aura.name)and aura.name==slot.entry.value)
        if match then
            local instance=Number(aura.instance)
            local key=instance and "instance:"..instance or tostring(id)..":"..aura.source
            seen[key]=true
            if slot.initialized and not(slot.seen and slot.seen[key])then new=true end
            if not matched or (Number(aura.expires)or 0)>(Number(matched.expires)or 0)then matched=aura end
        end
    end
    if new and play then I.Play(slot.entry)end
    slot.seen,slot.initialized,slot.aura=seen,true,matched
    slot.auraIndex=matched and matched.index
end
function I.Paint(view,o,animateOnly)
    local group=view.byID[o.spec.parent]
    local shown=not(view.hidden and view.hidden[o.spec.id])and (view.preview or
        (group.enabled~=false and o.spec.enabled~=false and (not group.hideWithoutTarget or M.Compat.Bool(Safe(UnitExists,"target")))))
    o.frame:SetShown(shown)
    local now=GetTime();if animateOnly and now<(o.nextScan or 0)then return end;o.nextScan=now+.1
    local auras=not view.preview and Auras()or nil
    local play=shown and o.frame:IsVisible()and not view.preview and not(M.editor and M.editor.window:IsShown())
    local displayed={}
    for index,slot in ipairs(o.buffIcons or {})do
        if slot.entry then
            if now>=(o.nextInfo or 0)then
                local changed=Resolve(slot,slot.entry);if o.native and (changed or not slot.bound)then slot.pending=true end
            end
            if slot.pending and o.native and not InCombatLockdown()then Bind(slot)end
            if not view.preview then Scan(slot,auras,play)end
            local native=not view.preview and o.native and slot.bound
            local visible=view.preview or native or (auras~=nil and slot.aura~=nil)
            slot:SetShown(visible);slot.base:SetAlpha(native and 0 or 1)
            if visible then displayed[#displayed+1]=slot end
            if view.preview then slot.time:SetText(tostring(30-index));slot.count:SetText("")
            else
                local aura=slot.aura;local expires=aura and Number(aura.expires)
                slot.time:SetText(S.FormatCountdown(expires and expires>0 and expires-now or nil))
                local count=aura and Number(aura.count);slot.count:SetText(count and count>=2 and tostring(count)or "")
                if aura and Readable(aura.icon)and aura.icon then slot.texture:SetTexture(aura.icon)end
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
    if event~="UNIT_AURA"and event~="PLAYER_ENTERING_WORLD"and event~="PLAYER_TARGET_CHANGED"and event~="PLAYER_REGEN_ENABLED"and event~="SPELLS_CHANGED"and event~="GROUP_ROSTER_UPDATE"then return end
    local o=view.nodes.receivedBuffsIcons;if not o then return end
    o.nextScan=0;if event~="UNIT_AURA"then o.nextInfo=0 end;I.Paint(view,o,false)
end
function I.Remove(view,o)
    for _,slot in ipairs(o.buffIcons or {})do if slot.container then slot.container:SetEnabled(false)end end
end
