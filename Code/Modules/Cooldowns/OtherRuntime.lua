local _,M=...
local O,S=M.PlayerOtherMonitor,M.PlayerSkillMonitor
local Safe,Number,Readable=O.Safe,O.Number,O.Readable
local samples={{type="buffFound",value="139",glow=true,glowColor={1,.82,0,1}},
    {type="buffMissing",value="21562"},{type="debuffFound",value="172"}}
local function Font(text,count)
    text:SetFont(M:EffectiveFontPath(M.MYRIAD),16,"OUTLINE");text:SetTextColor(1,1,1,1);text:SetJustifyH("CENTER")
    text:SetShadowColor(0,0,0,count and 0 or 1);text:SetShadowOffset(count and 0 or 1,count and 0 or -1)
end
local function Glow(parent)
    return M.CustomMonitor.CreateGlow(parent)
end
local function SetGlow(frame,enabled,color,now)
    M.CustomMonitor.PaintGlow(frame,enabled,color,now)
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
local repeatedAuraIDs={player={},target={}}
local function Auras(unit,filter)
    if not CanRead(unit)then return nil end
    local result={byID={},byName={},instancesByID={}}
    for index=1,255 do
        local raw=M.Compat.Aura(unit,index,filter);if not raw then break end
        -- Own the record: compatibility APIs may reuse a temporary result table.
        local aura={name=raw.name,spellId=raw.spellId,spellID=raw.spellID,sourceUnit=raw.sourceUnit,
            expirationTime=raw.expirationTime,duration=raw.duration,applications=raw.applications,
            icon=raw.icon,auraInstanceID=raw.auraInstanceID}
        local id=aura.spellId;if type(id)=="nil"then id=aura.spellID end
        if Readable(aura.name)and Readable(id)then
            if unit~="target"or (Readable(aura.sourceUnit)and (aura.sourceUnit=="player"or
                (aura.sourceUnit and M.Compat.Bool(Safe(UnitIsUnit,aura.sourceUnit,"player")))))then
                local key=Number(id)
                aura.monitorIndex=index
                if key then
                    result.byID[key]=aura
                    local instances=result.instancesByID[key]or {};result.instancesByID[key]=instances
                    instances[#instances+1]=aura
                end
                if type(aura.name)=="string"then result.byName[aura.name]=aura end
            end
        end
    end
    for _,instances in pairs(result.instancesByID)do
        local ids,ordinals={},{}
        for _,aura in ipairs(instances)do local id=Number(aura.auraInstanceID);if id and id>0 then ids[id]=(ids[id]or 0)+1 end end
        local rejected=repeatedAuraIDs[unit]or {}
        for id,count in pairs(ids)do if count>1 then rejected[id]=true end end
        for _,aura in ipairs(instances)do
            local id=Number(aura.auraInstanceID);local unique=id and id>0 and ids[id]==1 and not rejected[id]
            local identity="time:"..tostring(Number(aura.expirationTime))..":"..tostring(Number(aura.duration))
            ordinals[identity]=(ordinals[identity]or 0)+1
            aura.monitorTimeKey=identity..":"..ordinals[identity]
            aura.monitorKey=unique and "id:"..id or aura.monitorTimeKey;aura.monitorLegacy=not unique
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
    text:SetText(S.FormatCountdown(remaining))
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
        frame:SetDurationText(frame.time,S.DurationTextOptions());frame:SetApplicationCount(frame.count,{})
    end
end
local function BindNative(slot)
    slot.nativeDirty=nil
    local ids={};local entry=slot.entry
    if entry.type=="custom"then if slot.container then slot.container:SetEnabled(false)end;slot.nativeBound=false;return end
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
            frame:SetDurationText(frame.time,S.DurationTextOptions());frame:SetApplicationCount(frame.count,{})
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
    slot.customFallbackIcon=icon or 134400
    slot.needsInfo=entry.type~="custom"and entry.type~="equipment"and (not icon or not slot.spellID)
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
        if self.sharedWeapon then GameTooltip:AddLine(M:T("相同效果按Buff实例显示，不代表实际主副手。"),1,.82,0,true)end
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
local function WeaponAuras(o,auras)
    local groups={}
    for _,slot in ipairs(o.otherIcons)do
        slot.sharedWeapon=false
        if slot.entry and slot.item and (slot.entry.slot==16 or slot.entry.slot==17)then
            for spell in pairs(slot.item.effects)do
                local group=groups[spell]or {};groups[spell]=group
                group[slot.entry.slot]=slot.fingerprint
            end
        end
    end
    o.weaponAuraBindings=o.weaponAuraBindings or {}
    local assignments={};local retained={}
    for spell,hands in pairs(groups)do
        if hands[16]and hands[17]then
            for _,slot in ipairs(o.otherIcons)do
                if slot.entry and slot.item and hands[slot.entry.slot]and slot.item.effects[spell]then slot.sharedWeapon=true end
            end
            if auras then
                local prior=o.weaponAuraBindings[spell]or {hands={},bindings={}}
                local current=auras.instancesByID[spell]or {};local available,times={},{};local used={};local selected={}
                for _,aura in ipairs(current)do available[aura.monitorKey]=aura;times[aura.monitorTimeKey]=aura end
                -- Match existing instance IDs before assigning newly seen ones.
                -- Never move the remaining buff into the other empty position.
                for _,hand in ipairs({16,17})do
                    local key=prior.hands[hand]==hands[hand]and prior.bindings[hand]
                    local match=key and available[key]
                    if not match and prior.hands[hand]==hands[hand]and prior.times then match=times[prior.times[hand]]end
                    if match and not used[match.monitorKey]then selected[hand]=match;used[match.monitorKey]=true end
                end
                for _,aura in ipairs(current)do
                    if not used[aura.monitorKey]then
                        if aura.monitorLegacy then
                            for _,hand in ipairs({16,17})do
                                if not selected[hand]and prior.bindings[hand]and prior.hands[hand]==hands[hand]then
                                    selected[hand]=aura;used[aura.monitorKey]=true;break
                                end
                            end
                        end
                    end
                    if not used[aura.monitorKey]then
                        for _,hand in ipairs({16,17})do
                            if not selected[hand]then selected[hand]=aura;used[aura.monitorKey]=true;break end
                        end
                    end
                end
                local bindings,previousTimes={},{}
                for hand,aura in pairs(selected)do bindings[hand]=aura.monitorKey;previousTimes[hand]=aura.monitorTimeKey end
                retained[spell]={hands=hands,bindings=bindings,times=previousTimes};assignments[spell]=selected
            else retained[spell]=o.weaponAuraBindings[spell]end
        end
    end
    o.weaponAuraBindings=retained
    return assignments
end
local TrackEquipment
function O.Configure(view,o)
    if not view.preview then TrackEquipment(false)end
    o.otherIcons=o.otherIcons or {};o.entries=O.Entries(view.byID[o.spec.parent]);o.native=not view.preview and NativeAvailable()
    o.nextScan=0;o.nextEquipment=0;o.nextDiscovery=GetTime()+1
    for i,entry in ipairs(o.entries)do
        local slot=Icon(o,i)
        if slot.entry~=entry then slot.wasCondition=nil end
        ResetNative(slot);Resolve(slot,entry);slot.time:SetText("");slot.count:SetText("");Font(slot.time);Font(slot.count,true)
        if slot.item then slot.fingerprint=ItemFingerprint(slot.item)end
        if o.native then if not InCombatLockdown()then BindNative(slot)else slot.nativeDirty=true end end
    end
    for i=#o.entries+1,#o.otherIcons do local slot=o.otherIcons[i];slot:Hide();slot.entry=nil;ResetNative(slot)end
    M.CustomMonitor.Sync(view,o,o.otherIcons,O.Paint)
end
O.timers={}
local function SaveTimer(key,record,now)
    local clock=Number(Safe(time))
    if clock then
        M.db.otherMonitorEquipmentTimers=M.db.otherMonitorEquipmentTimers or {}
        M.db.otherMonitorEquipmentTimers[key]=clock+math.max(0,record.expires-now)
    end
end
local function TimerRecord(item,spell,cooldown,now)
    local guid=Safe(UnitGUID,"player");if not Readable(guid)or not guid then return end
    -- Trinkets keep their ICD when moved between the two slots or into a bag.
    local trinket=item.slot==13 or item.slot==14
    local key=guid..":"..(trinket and "trinket"or tostring(item.slot))..":"..tostring(item.id)..":"..tostring(item.enchant)..":"..spell
    local record=O.timers[key]
    if not record then
        local saved=M.db.otherMonitorEquipmentTimers or {};local stamp=Number(saved[key]);local clock=Number(Safe(time))
        if trinket then
            for _,position in ipairs({13,14})do
                local legacy=guid..":"..position..":"..tostring(item.id)..":"..tostring(item.enchant)..":"..spell
                local old=O.timers[legacy];local prior=Number(saved[legacy])
                if old and old.expires>now and clock then prior=math.max(prior or 0,clock+old.expires-now)end
                if prior then stamp=math.max(stamp or 0,prior)end
                saved[legacy]=nil;O.timers[legacy]=nil
            end
        end
        record={expires=stamp and clock and stamp>clock and now+math.min(cooldown,stamp-clock)or 0};O.timers[key]=record
        if record.expires>now then SaveTimer(key,record,now)end
    end
    return record,key
end
local function Timer(slot,spell,cooldown,aura,now)
    if not cooldown or cooldown<=0 then return end
    local record,key=TimerRecord(slot.item,spell,cooldown,now);if not record then return end
    if aura then
        local expires,duration=Number(aura.expirationTime),Number(aura.duration)
        if expires and duration and expires>0 and duration>0 then
            local start=expires-duration
            if not record.start and record.expires>now then
                -- A reload or aura refresh must preserve an already saved ICD.
                record.start=start
            elseif not record.start or (start>record.start+.1 and record.expires<=now)then
                record.start=start;record.expires=start+cooldown
                SaveTimer(key,record,now)
            end
        end
    end
    return record.expires
end
local function PublicCooldown(item,now)
    local finish
    local function Include(start,duration)
        start,duration=Number(start),Number(duration)
        if start and duration and start>0 and duration>1.5 and start+duration>now then
            finish=math.max(finish or 0,start+duration)
        end
    end
    local enabled
    if Number(Safe(GetInventoryItemID,"player",item.slot))==item.id then
        local start,duration;start,duration,enabled=Safe(GetInventoryItemCooldown,"player",item.slot)
        Include(start,duration)
    end
    if item.id then
        Include(Safe(GetItemCooldown,item.id))
        if C_Item and C_Item.GetItemCooldown~=GetItemCooldown then Include(Safe(C_Item.GetItemCooldown,item.id))end
    end
    return finish,Number(enabled)
end
local function EquipCooldown(item,now)
    if not item or not item.id then return end
    local public,enabled=PublicCooldown(item,now)
    if next(item.effects)==nil then return end
    local cooldown
    for _,effect in pairs(item.effects)do
        if effect.cooldown and effect.cooldown>0 then cooldown=math.max(cooldown or 0,effect.cooldown)end
    end
    local _,useSpell=Safe(C_Item and C_Item.GetItemSpell or GetItemSpell,item.id)
    if enabled==nil then enabled=item.cooldownEnabled end
    local usable=enabled~=0 and ((Number(useSpell)and useSpell>0)or
        ((item.slot==13 or item.slot==14)and enabled==1))
    -- Known passive effects restart their own ICD; active equipment uses the
    -- equip lock instead of its full use cooldown. Prefer a public timer.
    -- Keep this separate from proc timers so a later buff can start its ICD.
    if usable then cooldown=30 end
    if not cooldown and not public then return end
    local record,key=TimerRecord(item,"equip",604800,now)
    if record then
        record.expires=math.max(record.expires,public or now+cooldown)
        SaveTimer(key,record,now)
    end
end
TrackEquipment=function(changed)
    local current={}
    for position=1,19 do
        local item=O.Effects(position);current[position]=item
        local _,enabled=PublicCooldown(item,GetTime());item.cooldownEnabled=enabled
    end
    if not O.equipped then O.equipped=current;return end
    if not changed then return end
    local now=GetTime();local pending={}
    for position=1,19 do
        local before,after=O.equipped[position],current[position]
        -- Effect metadata may arrive later; it does not mean a new equip.
        if before.id~=after.id or before.enchant~=after.enchant or before.gem~=after.gem then
            if before.id then pending[position..":old"]=before end
            if after.id then pending[position..":new"]=after end
        end
    end
    O.equipped=current
    for _,item in pairs(pending)do
        -- Prefer the new slot when the same item moved: its public API now
        -- describes the correct item. Unequipped items retain their own ICD.
        if item.slot==13 or item.slot==14 then
            for _,position in ipairs({13,14})do if current[position].id==item.id then item=current[position];break end end
        end
        EquipCooldown(item,now)
    end
end
local function Equipment(slot,auras,now,weaponAuras)
    local active,expires,stacks,cdExpires,hasFixed=false,nil,nil,nil,false
    cdExpires=PublicCooldown(slot.item,now)
    local swap=TimerRecord(slot.item,"equip",604800,now)
    if swap and swap.expires>now then cdExpires=math.max(cdExpires or 0,swap.expires)end
    if cdExpires then hasFixed=true end
    for spell,effect in pairs(slot.item.effects)do
        local aura=auras and auras.byID[spell]
        if (slot.entry.slot==16 or slot.entry.slot==17)and weaponAuras[spell]then aura=weaponAuras[spell][slot.entry.slot]end
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
    slot.faded=not active and hasFixed and cdExpires~=nil and cdExpires>now or false
    slot.fixedCooldown=hasFixed;slot.condition=active;slot.show=true;slot.rawKnown=auras~=nil
end
local function Refresh(view,o,now)
    local player=Auras("player","HELPFUL")
    local targetExists=M.Compat.Bool(Safe(UnitExists,"target"));local target=targetExists and Auras("target","HARMFUL|PLAYER")or nil
    local equipmentDue=now>=(o.nextEquipment or 0)
    if equipmentDue then TrackEquipment(true)end
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
            end
        end
    end
    local weaponAuras=WeaponAuras(o,player)
    for _,slot in ipairs(o.otherIcons)do
        local entry=slot.entry
        if entry then
            if entry.type=="custom"then M.CustomMonitor.Apply(o,slot,false)
            elseif entry.type=="equipment"then Equipment(slot,player,now,weaponAuras)
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
            if known and entry.type~="custom"then
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
    local now=GetTime()
    if now>=(o.nextDiscovery or 0)then
        local current=O.Entries(group);local changed=#current~=#(o.entries or {})
        if not changed then for i,entry in ipairs(current)do if entry~=o.entries[i]then changed=true;break end end end
        if changed then O.Configure(view,o)end
        o.nextDiscovery=now+1
    end
    local entries=o.entries or {}
    if view.preview and #entries==0 then
        local equipment=false
        for _,entry in ipairs(group.otherMonitors or {})do if entry.type=="equipment"then equipment=true;break end end
        if not equipment then entries=samples end
    end
    local displayed={}
    if not view.preview and #entries>0 and (not animateOnly or now>=(o.nextScan or 0))then Refresh(view,o,now);o.nextScan=now+.2 end
    for i,entry in ipairs(entries)do
        local slot=Icon(o,i);if slot.entry~=entry then Resolve(slot,entry)end
        local custom=entry.type=="custom"and M.CustomMonitor.Apply(o,slot,view.preview)
        local rawWeapon=slot.sharedWeapon and slot.rawKnown
        local native=not view.preview and o.native and slot.nativeBound and not rawWeapon
        if slot.container then
            slot.container:SetAlpha(rawWeapon and 0 or 1)
            if rawWeapon then
                for _,frame in ipairs(slot.nativeFrames or {})do frame.baseGate:SetAlpha(1);frame.timeGate:SetAlpha(1)end
            end
        end
        local eligible=not IsTarget(entry)or M.Compat.Bool(Safe(UnitExists,"target"))
        local visible=view.preview or (native and eligible)or slot.show==true
        slot:SetShown(visible);slot.base:SetAlpha(1);slot.annotations:SetAlpha(1)
        if visible then displayed[#displayed+1]=slot end
        if view.preview then
            slot.texture:SetDesaturated(false);slot.texture:SetAlpha(1)
            slot.time:SetText(custom and (custom.text or "")or(IsMissing(entry)and ""or tostring(30-i)));slot.count:SetText(custom and tostring(custom.count or "")or(IsMissing(entry)and ""or "2"))
            SetGlow(slot.glow,custom and custom.glow or entry.glow,entry.glowColor,now)
        else
            slot.texture:SetDesaturated(slot.faded==true);slot.texture:SetAlpha(slot.faded and .5 or 1)
            if custom and custom.text then slot.time:SetText(custom.text)else Time(slot.time,slot.expires,now)end
            if custom then slot.count:SetText(tostring(custom.count or ""))else Count(slot.count,slot.stacks)end
            local glow=entry.glow;if custom and custom.glow~=nil then glow=custom.glow end
            SetGlow(slot.glow,glow and slot.condition,entry.glowColor,now)
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
                    -- Native aura frames only render while the effect is active.
                    -- Keep them colored even when the underlying item has a CD.
                    frame.icon:SetDesaturated(false);frame.icon:SetAlpha(1)
                    if entry.type=="equipment"then frame.icon:SetTexture(slot.item.icon or 134400)end
                    SetGlow(frame.glow,not IsMissing(entry)and entry.glow,entry.glowColor,now)
                    if IsMissing(entry)then SetGlow(slot.glow,entry.glow,entry.glowColor,now)end
                end
            end
        end
    end
    -- Keep configured slots/buff bindings stable; only visible icons occupy
    -- positions in the live row. Preview still includes every configured icon.
    o.rowCount=#displayed;local width=math.max(1,#displayed*44-4)
    if width~=o.rowWidth then o.frame:SetSize(width,66);o.rowWidth=width end
    for index,slot in ipairs(displayed)do
        local x=S.IconOffset(group,index,#displayed)
        if slot.rowX~=x then slot:ClearAllPoints();slot:SetPoint("CENTER",o.frame,"CENTER",x,-7);slot.rowX=x end
    end
end
local events={UNIT_AURA=true,PLAYER_TARGET_CHANGED=true,PLAYER_ENTERING_WORLD=true,PLAYER_EQUIPMENT_CHANGED=true,
    UNIT_INVENTORY_CHANGED=true,BAG_UPDATE_COOLDOWN=true,BAG_UPDATE_DELAYED=true,SPELL_UPDATE_COOLDOWN=true,
    GET_ITEM_INFO_RECEIVED=true,PLAYER_REGEN_ENABLED=true,SPELLS_CHANGED=true}
function O.Event(view,event,unit)
    if not events[event]or (event=="UNIT_AURA"and unit~="player"and unit~="target")then return end
    if event=="UNIT_INVENTORY_CHANGED"and unit~="player"then return end
    if event=="PLAYER_EQUIPMENT_CHANGED"or event=="UNIT_INVENTORY_CHANGED"or event=="BAG_UPDATE_DELAYED"then TrackEquipment(true)end
    local o=view.nodes.playerOtherMonitorIcons;if not o then return end
    o.nextScan=0
    if event=="PLAYER_EQUIPMENT_CHANGED"or event=="UNIT_INVENTORY_CHANGED"or event=="GET_ITEM_INFO_RECEIVED"then o.nextEquipment=0 end
    if event=="PLAYER_EQUIPMENT_CHANGED"or event=="UNIT_INVENTORY_CHANGED"or event=="GET_ITEM_INFO_RECEIVED"then o.nextDiscovery=0 end
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
