local _,M=...
local O,S=M.PlayerOtherMonitor,M.PlayerSkillMonitor
local Safe,Number,Readable=O.Safe,O.Number,O.Readable
local samples={{type="buffFound",value="139",glow=true,glowColor={1,.82,0,1}},
    {type="buffMissing",value="21562"},{type="equipment",slot=13,value=""}}
local function Font(text,count)
    text:SetFont(M:EffectiveFontPath(M.MYRIAD),16,"OUTLINE");text:SetTextColor(1,1,1,1);text:SetJustifyH("CENTER")
    text:SetShadowColor(0,0,0,count and 0 or 1);text:SetShadowOffset(count and 0 or 1,count and 0 or -1)
end
local function Glow(parent)
    local frame=CreateFrame("Frame",nil,parent);frame:SetAllPoints();frame:EnableMouse(false)
    local edge=frame:CreateTexture(nil,"OVERLAY");edge:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    edge:SetBlendMode("ADD");edge:SetSize(72,72);edge:SetPoint("CENTER")
    frame.edge=edge;frame:Hide();return frame
end
local function SetGlow(frame,enabled,color,now)
    frame:SetShown(enabled==true)
    if enabled then local c=color or {1,.82,0,1};frame.edge:SetVertexColor(c[1],c[2],c[3],c[4]);frame.edge:SetAlpha(.7+.25*math.sin(now*6))end
end
local function NativeAvailable()
    local interface=M.Compat.interface or 0
    if interface~=16001 and interface<120000 then return false end
    if not C_XMLUtil or not C_XMLUtil.GetTemplateInfo then return false end
    if not C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")and not InCombatLockdown()and C_AddOns then Safe(C_AddOns.LoadAddOn,"Blizzard_AuraContainer")end
    return C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")~=nil
end
local function CanRead(unit)
    if C_Secrets and C_Secrets.ShouldAurasBeSecret then
        local restricted=Safe(C_Secrets.ShouldAurasBeSecret,unit)
        if not Readable(restricted)or restricted==true then return false end
    end
    return true
end
local function Auras(unit,filter)
    if not CanRead(unit)then return nil end
    local result={byID={},byName={}}
    for index=1,255 do
        local aura=M.Compat.Aura(unit,index,filter);if not aura then break end
        local id=aura.spellId;if type(id)=="nil"then id=aura.spellID end
        if Readable(aura.name)and Readable(id)then
            if unit~="target"or (Readable(aura.sourceUnit)and (aura.sourceUnit=="player"or
                (aura.sourceUnit and M.Compat.Bool(Safe(UnitIsUnit,aura.sourceUnit,"player")))))then
                local key=Number(id)
                aura.monitorIndex=index
                if key then result.byID[key]=aura end
                if type(aura.name)=="string"then result.byName[aura.name]=aura end
            end
        end
    end
    return result
end
local function Find(auras,entry,spellID)
    if not auras then return end
    local id=tonumber(entry.value)or spellID
    return id and auras.byID[id]or auras.byName[entry.value]
end
local function Time(text,expires,now)
    local remaining=expires and expires-now
    text:SetText(remaining and remaining>0 and (remaining>=60 and math.ceil(remaining/60).."m"or tostring(math.ceil(remaining)))or "")
end
local function Count(text,value)
    local count=Number(value);text:SetText(count and count>1 and tostring(count)or "")
end
local function IsMissing(entry)return entry.type=="buffMissing"or entry.type=="debuffMissing"end
local function IsTarget(entry)return entry.type=="debuffFound"or entry.type=="debuffMissing"end
local function NativeFrame(slot,frame)
    frame:SetSize(40,40);frame:EnableMouse(false);frame:EnableMouseMotion(true)
    frame:SetTooltipAnchorPoint("ANCHOR_RIGHT");frame:SetHideTooltipInCombat(false)
    frame.icon=frame:CreateTexture(nil,"ARTWORK");frame.icon:SetAllPoints()
    frame.time=frame:CreateFontString(nil,"OVERLAY");Font(frame.time);frame.time:SetPoint("BOTTOM",frame,"TOP",0,7)
    frame.count=frame:CreateFontString(nil,"OVERLAY");Font(frame.count,true);frame.count:SetPoint("BOTTOM",frame,"TOP",0,29)
    frame.glow=Glow(frame)
    frame.baseGate=CreateFrame("Frame",nil,slot.lastGate or slot.base);frame.baseGate:SetAllPoints();frame.baseGate:EnableMouse(false)
    slot.lastGate=frame.baseGate;slot.texture:SetParent(frame.baseGate);slot.glow:SetParent(frame.baseGate)
    frame.timeGate=CreateFrame("Frame",nil,slot.lastTimeGate or slot.annotations);frame.timeGate:SetAllPoints();frame.timeGate:EnableMouse(false)
    slot.lastTimeGate=frame.timeGate;slot.time:SetParent(frame.timeGate);slot.count:SetParent(frame.timeGate)
    slot.nativeFrames[#slot.nativeFrames+1]=frame
    local entry=slot.entry
    frame.icon:SetShown(not IsMissing(entry));frame.time:SetShown(not IsMissing(entry));frame.count:SetShown(not IsMissing(entry))
    if not IsMissing(entry)then
        if entry.type=="equipment"then frame.icon:SetTexture(slot.item.icon or 134400)else frame:SetIcon(frame.icon)end
        frame:SetDurationText(frame.time,{});frame:SetApplicationCount(frame.count,{})
    end
end
local function BindNative(slot)
    slot.nativeDirty=nil
    local ids={};local entry=slot.entry
    if entry.type=="equipment"then for id in pairs(slot.item.effects)do ids[id]=true end
    elseif slot.spellID then ids[slot.spellID]=true end
    if not next(ids)then if slot.container then slot.container:SetEnabled(false)end;slot.nativeBound=false;return end
    if slot.container and slot.boundType~=entry.type then
        slot.container:SetEnabled(false);slot.container:Hide();slot.container=nil
        slot.texture:SetParent(slot.base);slot.glow:SetParent(slot.base);slot.time:SetParent(slot.annotations);slot.count:SetParent(slot.annotations)
        slot.lastGate,slot.lastTimeGate=nil,nil
    end
    if not slot.container then
        local container=CreateFrame("AuraContainer",nil,slot,"CustomAuraContainerTemplate")
        container:SetEnabled(false);container:SetPoint("TOPLEFT",slot,"TOPLEFT",0,0);slot.container=container;slot.nativeFrames={}
        container:AddAuraGroup("monitor",IsTarget(entry)and "HARMFUL|PLAYER"or "HELPFUL",{maxFrameCount=0,initializeFrame=function(frame)NativeFrame(slot,frame)end})
        container:SetFlowLayoutAnchorPoint("TOPLEFT");container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right,AnchorUtil.FlowDirection.Down)
        container:SetFlowLayoutMaximumLineSize(40.001)
        container:SetAuraGroupLayout("monitor",{elementSpacing=0,lineSpacing=0,elementWidth=40,elementHeight=40})
    end
    slot.container:SetEnabled(false);slot.container:SetUnit(IsTarget(entry)and "target"or "player")
    slot.boundType=entry.type
    slot.container:SetAuraGroupCandidateFilters("monitor",{includeSpellIDs=ids})
    slot.container:SetAuraGroupMaxFrameCount("monitor",1)
    slot.container:SetEnabled(true);slot.container:UpdateAllAuras();slot.nativeBound=true
    for _,frame in ipairs(slot.nativeFrames)do
        frame.icon:SetShown(not IsMissing(entry));frame.time:SetShown(not IsMissing(entry));frame.count:SetShown(not IsMissing(entry))
        if not IsMissing(entry)then
            if entry.type=="equipment"then frame.icon:SetTexture(slot.item.icon or 134400)
            else frame:SetIcon(frame.icon)end
            frame:SetDurationText(frame.time,{});frame:SetApplicationCount(frame.count,{})
        end
    end
end
local function ResetNative(slot)
    if slot.container then slot.container:SetEnabled(false)end
    slot.nativeBound=false
    for _,frame in ipairs(slot.nativeFrames or {})do frame.baseGate:SetAlpha(1);frame.timeGate:SetAlpha(1);frame.glow:Hide()end
end
local function Resolve(slot,entry)
    local name,id,icon=M.PetBuffs.SpellInfo(entry.value)
    slot.entry=entry;slot.spellID=tonumber(entry.value)or id;slot.spellName=name or entry.value
    slot.item=entry.type=="equipment"and O.Effects(entry.slot or 13)or nil
    slot.texture:SetTexture(slot.item and slot.item.icon or icon or 134400)
    slot.needsInfo=entry.type~="equipment"and (not icon or not slot.spellID)
    slot.nextInfo=GetTime()+1
end
local function Icon(o,index)
    local slot=o.otherIcons[index];if slot then return slot end
    slot=CreateFrame("Frame",nil,o.frame);slot:SetSize(40,40);slot:EnableMouse(true)
    slot.base=CreateFrame("Frame",nil,slot);slot.base:SetAllPoints();slot.base:EnableMouse(false)
    slot.texture=slot.base:CreateTexture(nil,"ARTWORK");slot.texture:SetAllPoints();slot.glow=Glow(slot.base)
    slot.annotations=CreateFrame("Frame",nil,slot);slot.annotations:SetAllPoints();slot.annotations:EnableMouse(false)
    slot.annotations:SetFrameLevel(slot:GetFrameLevel()+20)
    slot.time=slot.annotations:CreateFontString(nil,"OVERLAY");Font(slot.time);slot.time:SetPoint("BOTTOM",slot,"TOP",0,7)
    slot.count=slot.annotations:CreateFontString(nil,"OVERLAY");Font(slot.count,true);slot.count:SetPoint("BOTTOM",slot,"TOP",0,29)
    slot:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        if self.item and self.item.id and GameTooltip.SetInventoryItem then GameTooltip:SetInventoryItem("player",self.entry.slot)
        elseif self.auraIndex and GameTooltip.SetUnitAura then GameTooltip:SetUnitAura(IsTarget(self.entry)and "target"or "player",self.auraIndex,IsTarget(self.entry)and "HARMFUL|PLAYER"or "HELPFUL")
        elseif self.spellID and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(self.spellID)else GameTooltip:AddLine(self.spellName or "",1,1,1)end
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave",function()GameTooltip:Hide()end)
    o.otherIcons[index]=slot;return slot
end
local function ItemFingerprint(item)
    local ids={};for id in pairs(item.effects)do ids[#ids+1]=id end;table.sort(ids)
    local text={tostring(item.id),tostring(item.icon),tostring(item.enchant),tostring(item.gem)}
    for _,id in ipairs(ids)do text[#text+1]=tostring(id)..":"..tostring(item.effects[id].cooldown)end
    return table.concat(text,":")
end
function O.Configure(view,o)
    o.otherIcons=o.otherIcons or {};o.entries=O.Entries(view.byID[o.spec.parent]);o.native=not view.preview and NativeAvailable()
    o.nextScan=0;o.nextEquipment=0
    for i,entry in ipairs(o.entries)do
        local slot=Icon(o,i)
        if slot.entry~=entry then slot.wasCondition=nil end
        ResetNative(slot);Resolve(slot,entry);slot.time:SetText("");slot.count:SetText("");Font(slot.time);Font(slot.count,true)
        if slot.item then slot.fingerprint=ItemFingerprint(slot.item)end
        if o.native then if not InCombatLockdown()then BindNative(slot)else slot.nativeDirty=true end end
    end
    for i=#o.entries+1,#o.otherIcons do local slot=o.otherIcons[i];slot:Hide();slot.entry=nil;ResetNative(slot)end
end
O.timers={}
local function Timer(slot,spell,cooldown,aura,now)
    if not cooldown or cooldown<=0 then return end
    local guid=Safe(UnitGUID,"player");if not Readable(guid)or not guid then return end
    local key=guid..":"..tostring(slot.item.slot)..":"..tostring(slot.item.id)..":"..tostring(slot.item.enchant)..":"..spell
    local record=O.timers[key]
    if not record then
        local saved=M.db.otherMonitorEquipmentTimers or {};local stamp=Number(saved[key]);local clock=Safe(time)
        record={expires=stamp and clock and stamp>clock and now+math.min(cooldown,stamp-clock)or 0};O.timers[key]=record
    end
    if aura then
        local expires,duration=Number(aura.expirationTime),Number(aura.duration)
        if expires and duration and expires>0 and duration>0 then
            local start=expires-duration
            if not record.start and record.expires>now then
                -- A reload or aura refresh must preserve an already saved ICD.
                record.start=start
            elseif not record.start or (start>record.start+.1 and record.expires<=now)then
                record.start=start;record.expires=start+cooldown
                local clock=Safe(time)
                if clock then
                    M.db.otherMonitorEquipmentTimers=M.db.otherMonitorEquipmentTimers or {}
                    M.db.otherMonitorEquipmentTimers[key]=clock+math.max(0,record.expires-now)
                end
            end
        end
    end
    return record.expires
end
local function Equipment(slot,auras,now)
    local active,expires,stacks,cdExpires,hasFixed=false,nil,nil,nil,false
    local start,duration=Safe(GetInventoryItemCooldown,"player",slot.entry.slot)
    start,duration=Number(start),Number(duration)
    if start and duration and duration>1.5 then cdExpires=start+duration;hasFixed=true end
    for spell,effect in pairs(slot.item.effects)do
        local aura=auras and auras.byID[spell]
        if aura then
            local finish=Number(aura.expirationTime)
            if not expires or (finish and finish>expires)then expires=finish;stacks=aura.applications end
            active=true
        end
        if effect.cooldown and effect.cooldown>0 then hasFixed=true end
        local finish=Timer(slot,spell,effect.cooldown,aura,now)
        if finish and (not cdExpires or finish>cdExpires)then cdExpires=finish end
    end
    slot.active=active;slot.expires=active and expires or cdExpires;slot.stacks=active and stacks or nil
    slot.faded=hasFixed and (active or (cdExpires~=nil and cdExpires>now))or false
    slot.fixedCooldown=hasFixed;slot.condition=active;slot.show=true
end
local function Refresh(view,o,now)
    local player=Auras("player","HELPFUL")
    local targetExists=M.Compat.Bool(Safe(UnitExists,"target"));local target=targetExists and Auras("target","HARMFUL|PLAYER")or nil
    local equipmentDue=now>=(o.nextEquipment or 0)
    for _,slot in ipairs(o.otherIcons)do
        local entry=slot.entry
        if entry then
            if slot.needsInfo and now>=(slot.nextInfo or 0)then
                local old=slot.spellID;Resolve(slot,entry)
                if o.native and old~=slot.spellID then
                    if not InCombatLockdown()then BindNative(slot)else slot.nativeDirty=true end
                end
            end
            if entry.type=="equipment"then
                if equipmentDue then
                    local item=O.Effects(entry.slot or 13);local fingerprint=ItemFingerprint(item)
                    if slot.fingerprint~=fingerprint then
                        slot.item=item;slot.fingerprint=fingerprint;slot.texture:SetTexture(item.icon or 134400);slot.wasCondition=false
                        if o.native then if not InCombatLockdown()then BindNative(slot)else slot.nativeDirty=true end end
                    else slot.item=item end
                end
                Equipment(slot,player,now)
            else
                local auras=player;if IsTarget(entry)then auras=target end
                local aura=Find(auras,entry,slot.spellID);local present=aura~=nil
                slot.active=present;slot.condition=IsMissing(entry)and not present or (not IsMissing(entry)and present)
                if IsTarget(entry)and not targetExists then slot.condition=false end
                slot.show=slot.condition and auras~=nil;slot.faded=false;slot.expires=not IsMissing(entry)and aura and Number(aura.expirationTime)or nil
                slot.stacks=not IsMissing(entry)and aura and aura.applications or nil;slot.auraIndex=aura and aura.monitorIndex
                slot.rawKnown=auras~=nil
            end
            if slot.nativeDirty and not InCombatLockdown()then BindNative(slot)end
            -- Protected aura existence never drives Lua sounds or hidden timers.
            local known=entry.type=="equipment"and player~=nil or (entry.type~="equipment"and slot.rawKnown)
            if known then
                if slot.condition and not slot.wasCondition and o.frame:IsVisible()and not(view.preview or(M.editor and M.editor.window:IsShown()))then O.Play(entry)end
                slot.wasCondition=slot.condition
            end
        end
    end
    if equipmentDue then o.nextEquipment=now+1 end
end
function O.Paint(view,o,animateOnly)
    local group=view.byID[o.spec.parent];local enabled=group.enabled~=false and o.spec.enabled~=false
    local shown=(view.preview or enabled)and not(view.hidden and view.hidden[o.spec.id])
    if not view.preview and group.hideWithoutTarget and not M.Compat.Bool(Safe(UnitExists,"target"))then shown=false end
    if o.frame:IsShown()~=shown then o.frame:SetShown(shown)end
    if not enabled and not view.preview then return end
    local entries=o.entries or {};if view.preview and #entries==0 then entries=samples end
    local now=GetTime();o.rowCount=#entries;local width=math.max(1,#entries*44-4)
    if width~=o.rowWidth then o.frame:SetSize(width,66);o.rowWidth=width end
    if not view.preview and #entries>0 and (not animateOnly or now>=(o.nextScan or 0))then Refresh(view,o,now);o.nextScan=now+.2 end
    for i,entry in ipairs(entries)do
        local slot=Icon(o,i);if slot.entry~=entry then Resolve(slot,entry)end
        local x=S.IconOffset(group,i,#entries)
        if slot.rowX~=x then slot:ClearAllPoints();slot:SetPoint("CENTER",o.frame,"CENTER",x,-7);slot.rowX=x end
        local native=not view.preview and o.native and slot.nativeBound
        local eligible=not IsTarget(entry)or M.Compat.Bool(Safe(UnitExists,"target"))
        local visible=view.preview or (native and eligible)or slot.show==true
        slot:SetShown(visible);slot.base:SetAlpha(1);slot.annotations:SetAlpha(1)
        if view.preview then
            slot.texture:SetDesaturated(entry.type=="equipment");slot.texture:SetAlpha(entry.type=="equipment"and .5 or 1)
            slot.time:SetText(IsMissing(entry)and ""or tostring(30-i));slot.count:SetText(IsMissing(entry)and ""or "2")
            SetGlow(slot.glow,entry.glow,entry.glowColor,now)
        else
            slot.texture:SetDesaturated(slot.faded==true);slot.texture:SetAlpha(slot.faded and .5 or 1)
            Time(slot.time,slot.expires,now);Count(slot.count,slot.stacks)
            SetGlow(slot.glow,entry.glow and slot.condition,entry.glowColor,now)
            if native then
                local found=not IsMissing(entry)and entry.type~="equipment"
                if found then slot.base:SetAlpha(0);slot.annotations:SetAlpha(0)end
                for _,frame in ipairs(slot.nativeFrames or {})do
                    if frame.baseGate.SetAlphaFromBoolean then
                        frame.baseGate:SetAlphaFromBoolean(frame:IsShown(),0,1);frame.timeGate:SetAlphaFromBoolean(frame:IsShown(),0,1)
                    else
                        local present=frame:IsShown()
                        if Readable(present)then frame.baseGate:SetAlpha(present and 0 or 1);frame.timeGate:SetAlpha(present and 0 or 1)end
                    end
                    local fade=entry.type=="equipment"and slot.fixedCooldown
                    frame.icon:SetDesaturated(fade==true);frame.icon:SetAlpha(fade and .5 or 1)
                    if entry.type=="equipment"then frame.icon:SetTexture(slot.item.icon or 134400)end
                    SetGlow(frame.glow,not IsMissing(entry)and entry.glow,entry.glowColor,now)
                    if IsMissing(entry)then SetGlow(slot.glow,entry.glow,entry.glowColor,now)end
                end
            end
        end
    end
end
local events={UNIT_AURA=true,PLAYER_TARGET_CHANGED=true,PLAYER_ENTERING_WORLD=true,PLAYER_EQUIPMENT_CHANGED=true,
    UNIT_INVENTORY_CHANGED=true,BAG_UPDATE_COOLDOWN=true,GET_ITEM_INFO_RECEIVED=true,PLAYER_REGEN_ENABLED=true,SPELLS_CHANGED=true}
function O.Event(view,event,unit)
    if not events[event]or (event=="UNIT_AURA"and unit~="player"and unit~="target")then return end
    local o=view.nodes.playerOtherMonitorIcons;if not o then return end
    o.nextScan=0
    if event=="PLAYER_EQUIPMENT_CHANGED"or event=="UNIT_INVENTORY_CHANGED"or event=="GET_ITEM_INFO_RECEIVED"then o.nextEquipment=0 end
    if event=="PLAYER_TARGET_CHANGED"then for _,slot in ipairs(o.otherIcons or {})do if slot.entry and slot.container and IsTarget(slot.entry)then slot.container:UpdateAllAuras()end end end
    if event=="SPELLS_CHANGED"or event=="PLAYER_REGEN_ENABLED"or event=="PLAYER_ENTERING_WORLD"then
        for _,slot in ipairs(o.otherIcons or {})do
            if slot.entry and slot.entry.type~="equipment"then
                local old=slot.spellID;Resolve(slot,slot.entry)
                if o.native and (old~=slot.spellID or slot.nativeDirty)then
                    if not InCombatLockdown()then BindNative(slot)else slot.nativeDirty=true end
                end
            end
        end
    end
    O.Paint(view,o,false)
    if (event=="PLAYER_EQUIPMENT_CHANGED"or event=="UNIT_INVENTORY_CHANGED"or event=="GET_ITEM_INFO_RECEIVED")
        and M.editor and M.editor.window:IsShown()and M.selection=="playerOtherMonitor"then M:RefreshProperties()end
end
