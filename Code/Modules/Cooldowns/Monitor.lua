local _,M=...
local D={};M.CooldownMonitor=D
D.defaultBlacklist="炉石\n猛虎之怒\n精灵之火（野性）\n十字军打击\n神圣风暴\n奉献\n驱邪术\n愤怒之锤\n神圣震击\n正义之锤\n正义盾击\n神圣之盾\n烈焰震击\n熔岩爆裂\n闪电链\n火焰新星\n雷霆风暴\n风暴打击\n熔岩猛击\n大地震击\n暗影灼烧\n混乱之箭\n鬼影缠身\n裂伤（熊）\n裂伤（豹）\n野性成长\n迅捷治愈\n激流\n脚踢\n嫁祸诀窍\n冲击波\n龙息术\n心灵震爆\n暗言术：灭\n苦修\n愈合祷言\n陷阱发射器：爆炸陷阱\n爆炸射击\n多重射击\n杀戮射击\n火焰冲击"
local function Templates()
    return {
        {id="cooldownMonitor",label="玩家技能冷却监控",kind="group",compound="cooldownMonitor",scope="player",unit="player",
            x=0,y=-375,width=2,height=2,scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=350,
            blacklist=D.defaultBlacklist,minCooldown=1.5,maxCooldown=86400,rules={},conditions={}},
        {id="cooldownMonitorIcons",label="玩家技能冷却监控",kind="cooldowns",parent="cooldownMonitor",internal=true,locked=true,
            scope="player",unit="player",x=0,y=0,width=216,height=60,autoWidth=true,scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=351},
    }
end
function M:EnsureCooldownModule(design)
    local seen={};for _,n in ipairs(design.nodes) do seen[n.id]=n end
    for _,n in ipairs(Templates()) do if not seen[n.id] then design.nodes[#design.nodes+1]=n end end
    for _,node in ipairs(design.nodes) do
        if node.id=="cooldownMonitor" or node.id=="cooldownMonitorIcons" then node.label="玩家技能冷却监控" end
    end
    local group=seen.cooldownMonitor
    if group and type(group.blacklist)~="string" then group.blacklist=D.defaultBlacklist end
    if group then
        group.minCooldown=M.Clamp(type(group.minCooldown)=="number" and group.minCooldown or 1.5,0,86400)
        group.maxCooldown=M.Clamp(type(group.maxCooldown)=="number" and group.maxCooldown or 86400,group.minCooldown,86400)
    end
end
M.moduleIDs.cooldownMonitor=true
M:EnsureCooldownModule(M.defaults)
if M.recordedDefaults then M:EnsureCooldownModule(M.recordedDefaults) end
local function Number(value,default)
    if (not issecretvalue or not issecretvalue(value)) and type(value)=="number" then return value end
    return default
end
local function Readable(value)
    return not issecretvalue or not issecretvalue(value)
end
local function Safe(fn,...)
    if not fn then return end
    local ok,a,b,c,d,e,f,g,h,i,j=pcall(fn,...)
    if ok then return a,b,c,d,e,f,g,h,i,j end
end
local function SpellInfo(id)
    if C_Spell and C_Spell.GetSpellInfo then
        local info=Safe(C_Spell.GetSpellInfo,id)
        if info and Readable(info.name) and Readable(info.iconID) then return info.name,info.iconID end
    end
    local name,_,icon=Safe(GetSpellInfo,id)
    if Readable(name) and Readable(icon) then return name,icon end
end
local function Clear(t)
    for key in pairs(t) do t[key]=nil end
    return t
end
function D:SpellInfo(id)
    local info=self.spellInfo[id]
    if not info then
        local name,icon=SpellInfo(id)
        -- Retry incomplete native data; spellbook changes invalidate complete data.
        if not name or not icon then return name,icon end
        info={name=name,icon=icon,key="spell:"..name};self.spellInfo[id]=info
    end
    return info.name,info.icon,info.key
end
local function BaseCooldown(id)
    return Number(Safe(GetSpellBaseCooldown or (C_Spell and C_Spell.GetSpellBaseCooldown),id))
end
local function Charges(id)
    local charges,maxCharges,start,duration,rate,active
    if C_Spell and C_Spell.GetSpellCharges then
        local info=Safe(C_Spell.GetSpellCharges,id)
        if info then charges,maxCharges,start,duration,rate,active=info.currentCharges,info.maxCharges,info.cooldownStartTime,info.cooldownDuration,info.chargeModRate,info.isActive end
    else charges,maxCharges,start,duration,rate=Safe(GetSpellCharges,id) end
    return Number(charges),Number(maxCharges),Number(start),Number(duration),Number(rate,1),Readable(active) and active or nil
end
local function Watchable(id)
    if (BaseCooldown(id) or 0)>0 then return true end
    local _,maximum=Charges(id);return (maximum and maximum>0) or (C_Spell and C_Spell.GetSpellCooldownDuration~=nil)
end
local function SpellCooldown(id)
    local charges,maximum,chargeStart,chargeDuration,chargeRate,chargeActive=Charges(id)
    if charges and maximum and charges<maximum and chargeStart and chargeDuration then return chargeStart,chargeDuration,chargeRate,true end
    if chargeActive==true and C_Spell and C_Spell.GetSpellChargeDuration then
        local native=Safe(C_Spell.GetSpellChargeDuration,id)
        if native then return nil,nil,1,true,native end
    end
    local start,duration,enabled,rate
    if C_Spell and C_Spell.GetSpellCooldown then
        local info=Safe(C_Spell.GetSpellCooldown,id)
        if info then
            start,duration,enabled,rate=info.startTime,info.duration,info.isEnabled,info.modRate
            if Readable(info.isActive) and info.isActive==false then return 0,0,1,false end
            if Readable(info.isOnGCD) and info.isOnGCD==true then return 0,0,1,false end
        end
    else start,duration,enabled,rate=Safe(GetSpellCooldown,id) end
    if Readable(enabled) and (enabled==0 or enabled==false) then return 0,0,1,false end
    if not Number(start) or not Number(duration) then
        local native=C_Spell and Safe(C_Spell.GetSpellCooldownDuration,id,true)
        return nil,nil,1,false,native
    end
    return Number(start),Number(duration),Number(rate,1),false
end
function D.BlacklistEntries(text)
    local entries,seen={},{}
    text=(text or ""):gsub("，","\n"):gsub("；","\n")
    for value in text:gmatch("[^\r\n,;]+") do
        value=value:match("^%s*(.-)%s*$")
        local key=value:lower()
        if key~="" and not seen[key] then entries[#entries+1]=value;seen[key]=true end
    end
    return entries
end
function D.ParseBlacklist(text)
    local blocked={}
    for _,value in ipairs(D.BlacklistEntries(text)) do blocked[value:lower()]=true end
    return blocked
end
local function Blocked(blocked,kind,id,name,spellID)
    return blocked[tostring(id)] or blocked[kind..":"..id] or blocked[(name or ""):lower()]
        or (spellID and (blocked[tostring(spellID)] or blocked["spell:"..spellID]))
end
local events={UNIT_SPELLCAST_SUCCEEDED=true,SPELL_UPDATE_COOLDOWN=true,SPELL_UPDATE_CHARGES=true,
    PLAYER_REGEN_DISABLED=true,PLAYER_REGEN_ENABLED=true,
    SPELLS_CHANGED=true,LEARNED_SPELL_IN_TAB=true,PLAYER_ENTERING_WORLD=true,
    BAG_UPDATE_COOLDOWN=true,BAG_UPDATE_DELAYED=true,PLAYER_EQUIPMENT_CHANGED=true,GET_ITEM_INFO_RECEIVED=true}
function D:Init()
    if self.spells then return end
    self.spells={};self.spellUses={};self.items={};self.itemInfo={};self.equipped={};self.active={};self.spellItems={}
    self.spellInfo={};self.records={};self.suppressed={};self.seen={};self.candidates={};self.nextActive={}
    self.pollSpells={};self.lastFullScan=nil;self.spellDurations={}
    self.activeRevision=0
    self.rescan=true;self.dirty=true
end
function D:DiscoverSpells()
    Clear(self.spellInfo)
    -- Shared lockouts are reported for unused skills too. As in the source WA,
    -- only successful player casts enter the watch list; spellbook changes just
    -- invalidate their metadata, preserving any cooldown already being tracked.
end
function D:RememberItem(id)
    if not id then return end
    local get=C_Item and C_Item.GetItemInfo or GetItemInfo
    local name,_,_,_,_,_,_,_,_,icon=Safe(get,id)
    local _,spellID=Safe(GetItemSpell or (C_Item and C_Item.GetItemSpell),id)
    local info=self.itemInfo[id] or {};self.itemInfo[id]=info
    info.name=name or info.name
    info.icon=icon or info.icon or Safe(C_Item and C_Item.GetItemIconByID or GetItemIcon,id)
    info.spellID=Number(spellID,info.spellID)
    if info.spellID then
        self.spellItems[info.spellID]=self.spellItems[info.spellID] or {}
        self.spellItems[info.spellID][id]=true
    end
end
function D:DiscoverItems()
    self.equipped={};self.sources={}
    for slot=1,19 do
        local id=Number(Safe(GetInventoryItemID,"player",slot))
        if id then self:RememberItem(id);self.equipped[id]=slot;self.sources[id]={slot=slot} end
    end
    local container=C_Container or {}
    for bag=0,(NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
        local slots=Number(Safe(container.GetContainerNumSlots or GetContainerNumSlots,bag),0)
        for slot=1,slots do
            local id=Number(Safe(container.GetContainerItemID or GetContainerItemID,bag,slot))
            if id then self:RememberItem(id);self.sources[id]={bag=bag,slot=slot} end
        end
    end
end
function D:Event(event,unit,...)
    if not events[event] then return end
    self:Init();self.dirty=true
    if event=="UNIT_SPELLCAST_SUCCEEDED" and unit=="player" then
        local _,id=...;id=Number(id)
        if id then
            if self.rescan or self.rescanItems then self:DiscoverItems();self.rescanItems=false end
            if Watchable(id) then
                self.spells[id]=true
                local use=self.spellUses[id] or {};self.spellUses[id]=use
                use.castAt=GetTime();use.pending=true;use.start=nil;use.observed=nil
            end
            for itemID in pairs(self.spellItems[id] or {}) do self.items[itemID]=true end
        end
    elseif event=="PLAYER_ENTERING_WORLD" or event=="SPELLS_CHANGED" or event=="LEARNED_SPELL_IN_TAB" then self.rescan=true
    elseif event=="BAG_UPDATE_DELAYED" or event=="PLAYER_EQUIPMENT_CHANGED" or event=="GET_ITEM_INFO_RECEIVED" then self.rescanItems=true end
end
function D:ItemCooldown(id)
    local source=self.sources[id];local start,duration,enabled
    if source then
        if source.bag then
            start,duration,enabled=Safe(C_Container and C_Container.GetContainerItemCooldown or GetContainerItemCooldown,source.bag,source.slot)
        else start,duration,enabled=Safe(GetInventoryItemCooldown,"player",source.slot) end
    end
    if start==nil then start,duration,enabled=Safe(GetItemCooldown or (C_Item and C_Item.GetItemCooldown),id) end
    if Readable(enabled) and (enabled==0 or enabled==false) then return end
    return Number(start),Number(duration)
end
function D:Update()
    self:Init();local now=GetTime()
    -- Cast/item/cooldown events still refresh immediately. An empty list only
    -- needs a slow fallback for a missed event; active entries retain 10 Hz.
    -- Full discovery polling is independent of whether an entry is active.
    local interval=#self.active>0 and .1 or 1
    local full=self.dirty or self.rescan or self.rescanItems or not self.lastFullScan or now-self.lastFullScan>=1
    if not full and now-(self.lastUpdate or 0)<interval then return end
    self.dirty=false;self.lastUpdate=now
    if full then self.lastFullScan=now end
    if self.rescan then self:DiscoverSpells();self:DiscoverItems();self.rescan=false;self.rescanItems=false
    elseif self.rescanItems then self:DiscoverItems();self.rescanItems=false end
    local active=Clear(self.nextActive)
    local suppressed,seen=Clear(self.suppressed),Clear(self.seen)
    local changed=false
    local function Add(kind,id,name,icon,start,duration,rate,spellID,native)
        if not name or not icon then return end
        if not native and (not start or not duration or duration<=0) then return end
        rate=rate and rate>0 and rate or 1
        local key=kind=="spell" and (self.spellInfo[id] and self.spellInfo[id].key or kind..":"..name) or (kind..":"..id)
        if seen[key] then return end
        local record=self.records[key]
        local expires=native and (record and record.expires or math.huge) or start+duration/rate
        if not native and expires<=now then return end
        if not record then record={};self.records[key]=record;changed=true end
        local total
        if native then
            total=Number(Safe(native.GetTotalDuration,native)) or record.duration or self.spellDurations[id]
            -- A first cast made under restrictions has no readable modified
            -- duration. Its public base duration is only a range-filter fallback;
            -- the displayed remaining time always comes from the native handle.
            if not total then local base=BaseCooldown(id);if base and base>0 then total=base/1000 end end
        else total=duration/rate end
        if total and total<=0 then return end
        if kind=="spell" and not native then self.spellDurations[id]=total end
        if record.id~=id or record.name~=name or record.icon~=icon or record.expires~=expires
            or record.duration~=total or record.spellID~=spellID or record.nativeDuration~=native then changed=true end
        record.key,record.kind,record.id,record.name,record.icon=key,kind,id,name,icon
        record.expires,record.duration,record.spellID=expires,total,spellID
        record.nativeDuration=native
        seen[key]=true;active[#active+1]=record
    end
    local candidates=Clear(self.candidates);local spells=self.spells
    if full then
        for id in pairs(self.equipped)do candidates[id]=true end
        for id in pairs(self.items)do candidates[id]=true end
    else
        spells=Clear(self.pollSpells)
        for _,state in ipairs(self.active) do
            if state.kind=="item" then candidates[state.id]=true else spells[state.id]=true end
        end
    end
    for id in pairs(candidates) do
        local info=self.itemInfo[id] or {};local start,duration=self:ItemCooldown(id)
        if start and duration and duration>0 and start+duration>now then
            -- Do not show a second, unused trinket's short shared lockout.
            local base=info.spellID and BaseCooldown(info.spellID)
            if not self.equipped[id] or self.items[id] or not base or base==0 or duration>=base/1000-.1 then
                Add("item",id,info.name,info.icon,start,duration,1,info.spellID)
                if info.spellID then suppressed[info.spellID]=true end
            end
        end
    end
    local gcdStart,gcdDuration=SpellCooldown(61304)
    for id in pairs(spells) do
        if not suppressed[id] then
            local use=self.spellUses[id]
            local name,icon,key=self:SpellInfo(id);local start,duration,rate,recharging,native=SpellCooldown(id)
            local gcd=start and duration and gcdStart and gcdDuration and math.abs(start-gcdStart)<.01 and math.abs(duration-gcdDuration)<.01
            rate=rate and rate>0 and rate or 1
            local cooling=start and duration and duration>0 and start+duration/rate>now and not gcd
            if use and not start then
                -- Restricted/failed reads are not a completed cooldown. Keep the
                -- cast until readable data confirms completion, including after combat.
                if native then
                    Add("spell",id,name,icon,nil,nil,1,nil,native)
                    use.observed=true
                else
                    local previous=key and self.records[key]
                    if previous and previous.duration and previous.expires<math.huge and previous.expires>now then
                        Add("spell",id,name,icon,previous.expires-previous.duration,previous.duration,1)
                    end
                end
            elseif use and cooling and (recharging or (use.start and math.abs(start-use.start)<.01)
                or (use.observed and not use.start)
                or (not use.start and math.abs(start-use.castAt)<=3)) then
                use.start=start;use.pending=nil
                Add("spell",id,name,icon,start,duration,rate)
            elseif not use or not use.pending or now-use.castAt>3 then
                -- Remove completed/reset casts, so an old trap use cannot claim
                -- a new shared cooldown created by a different trap.
                self.spells[id]=nil;self.spellUses[id]=nil
            end
        end
    end
    for key in pairs(self.records) do
        if not seen[key] then self.records[key]=nil;changed=true end
    end
    if changed or #active~=#self.active then
        table.sort(active,function(a,b)if a.expires~=b.expires then return a.expires<b.expires end;return a.key<b.key end)
        self.nextActive,self.active=self.active,active
        self.activeRevision=self.activeRevision+1
    end
end
function D.RemainingText(seconds)
    if seconds<=0 then return "" end
    if seconds>60 then
        local _,class=UnitClass("player");local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        return string.format("%.1f",seconds/60).."|c"..(color and color.colorStr or "ffffffff").."m|r"
    elseif seconds<=3 then return "|cffff0000"..math.ceil(seconds).."|r"
    elseif seconds<=4 then return "|cffff0000"..string.format("%.1f",seconds).."|r"
    elseif seconds<=10 then return "|cffffa500"..math.floor(seconds).."|r" end
    return tostring(math.floor(seconds))
end
function D.InCooldownRange(group,duration)
    local minimum=group and group.minCooldown or 1.5
    local maximum=group and group.maxCooldown or 86400
    return duration>=minimum and duration<=maximum
end
local function Icon(o,index)
    local slot=o.cooldownIcons[index]
    if slot then return slot end
    slot=CreateFrame("Frame",nil,o.frame);slot:SetSize(40,40);slot:EnableMouse(true)
    slot.texture=slot:CreateTexture(nil,"ARTWORK");slot.texture:SetAllPoints()
    slot.shadow=slot:CreateFontString(nil,"ARTWORK");slot.text=slot:CreateFontString(nil,"OVERLAY")
    for _,text in ipairs({slot.shadow,slot.text}) do text:SetFont(M:EffectiveFontPath(M.MYRIAD),16,"OUTLINE");text:SetJustifyH("CENTER") end
    slot.text:SetPoint("BOTTOM",slot,"TOP",2,7);slot.shadow:SetPoint("BOTTOM",slot,"TOP",4,5)
    slot.shadow:SetTextColor(0,0,0,1);slot.text:SetTextColor(1,1,1,1)
    slot:SetScript("OnEnter",function(self)
        local state=self.state;if not state then return end
        GameTooltip:SetOwner(self,"ANCHOR_BOTTOMRIGHT")
        if state.kind=="item" and GameTooltip.SetItemByID then GameTooltip:SetItemByID(state.id)
        elseif state.kind=="spell" and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(state.id)
        else GameTooltip:AddLine(state.name,1,1,1) end
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave",function()GameTooltip:Hide()end)
    o.cooldownIcons[index]=slot;return slot
end
local previewIcons={136048,135953,136085,134414,134795}
local previewRemaining={3.2,8,22,45,95}
local function SetText(slot,text,shadow)
    if slot.lastText~=text then slot.text:SetText(text);slot.lastText=text end
    if slot.lastShadow~=shadow then slot.shadow:SetText(shadow);slot.lastShadow=shadow end
end
local function SetAlpha(slot,alpha)
    if slot.lastAlpha~=alpha then slot:SetAlpha(alpha);slot.lastAlpha=alpha end
end
function D.Paint(view,o)
    local group=o.module or (view.nodes[o.spec.parent] and view.nodes[o.spec.parent].spec)
    local text=group and group.blacklist or ""
    local changed=o.blacklistSource~=text
    if changed then o.blacklistSource=text;o.blocked=D.ParseBlacklist(text) end
    local now=GetTime()
    local entries=o.cooldownEntries or {};o.cooldownEntries=entries
    if view.preview then
        for i,icon in ipairs(previewIcons) do
            local state=entries[i]
            if not state then state={key="preview"..i,kind=i>3 and "item" or "spell",id=i,icon=icon};entries[i]=state end
            state.name=M:T("冷却预览");state.expires=now+previewRemaining[i]
        end
    else
        D:Update()
        local minimum,maximum=group and group.minCooldown or 1.5,group and group.maxCooldown or 86400
        if changed or o.activeSource~=D.active or o.activeRevision~=D.activeRevision
            or o.minimum~=minimum or o.maximum~=maximum or (o.nextExpiry and now>=o.nextExpiry) then
            Clear(entries);o.nextExpiry=nil
            for _,state in ipairs(D.active) do
                if (state.nativeDuration or state.expires>now) and (not state.duration or D.InCooldownRange(group,state.duration))
                    and not Blocked(o.blocked,state.kind,state.id,state.name,state.spellID) then
                    entries[#entries+1]=state
                    if not state.nativeDuration then o.nextExpiry=o.nextExpiry and math.min(o.nextExpiry,state.expires) or state.expires end
                end
            end
            o.activeSource,o.activeRevision,o.minimum,o.maximum=D.active,D.activeRevision,minimum,maximum
        end
    end
    local width=math.max(1,#entries*44-4)
    if o.cooldownWidth~=width then o.frame:SetSize(width,60);o.cooldownWidth=width end
    o.cooldownByKey=o.cooldownByKey or {}
    local seen=o.cooldownSeen or {};o.cooldownSeen=Clear(seen)
    for i,state in ipairs(entries) do
        local slot=o.cooldownByKey[state.key]
        if not slot then
            for _,candidate in ipairs(o.cooldownIcons) do if not candidate.key then slot=candidate;break end end
            slot=slot or Icon(o,#o.cooldownIcons+1);slot.added=now
            slot.position=nil;slot.desired=nil;slot.from=nil;slot.moved=nil
        elseif slot.exiting then slot.added=now end
        slot.exiting=nil;o.cooldownByKey[state.key]=slot;seen[state.key]=true
        local font=M:EffectiveFontPath(M.MYRIAD)
        if slot.fontPath~=font then
            for _,label in ipairs({slot.shadow,slot.text})do label:SetFont(font,16,"OUTLINE")end
            slot.fontPath=font
        end
        slot.key=state.key;slot.state=state
        if slot.lastIcon~=state.icon then slot.texture:SetTexture(state.icon);slot.lastIcon=state.icon end
        local progress=M.Clamp((now-(slot.added or now))/.25,0,1)
        local desired=-(#entries-1)*22+(i-1)*44
        if slot.desired~=desired then slot.from=slot.position or desired;slot.desired=desired;slot.moved=now end
        local move=M.Clamp((now-(slot.moved or now))/.2,0,1)
        slot.position=slot.from+(desired-slot.from)*(1-(1-move)^3)
        local x=slot.position-50*(1-progress)
        if slot.lastX~=x then slot:ClearAllPoints();slot:SetPoint("CENTER",o.frame,"CENTER",x,0);slot.lastX=x end
        SetAlpha(slot,progress);if not slot:IsShown() then slot:Show() end
        if state.nativeDuration then
            -- Pass secret remaining time straight to native font formatting;
            -- never compare, sort or do arithmetic with a restricted number.
            local remaining=Safe(state.nativeDuration.GetRemainingDuration,state.nativeDuration)
            if remaining~=nil and slot.text.SetFormattedText then
                slot.text:SetFormattedText("%.0f",remaining);slot.shadow:SetFormattedText("%.0f",remaining)
            else slot.text:SetText("");slot.shadow:SetText("") end
            slot.lastText=nil;slot.lastShadow=nil
        else
            local value=D.RemainingText(state.expires-now)
            if slot.lastText~=value then SetText(slot,value,value:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")) end
        end
    end
    for _,slot in ipairs(o.cooldownIcons) do
        if slot.key and not seen[slot.key] then
            slot.exiting=slot.exiting or now
            local progress=M.Clamp((now-slot.exiting)/.25,0,1)
            SetText(slot,"","");SetAlpha(slot,1-progress)
            if progress==1 then o.cooldownByKey[slot.key]=nil;slot.key=nil;slot.exiting=nil;slot:Hide() end
        end
    end
end
function D.Reset(o)
    o.cooldownByKey=o.cooldownByKey or {};Clear(o.cooldownByKey)
    o.activeSource=nil;o.activeRevision=nil;o.cooldownWidth=nil
    for _,slot in ipairs(o.cooldownIcons) do slot.key=nil;slot.exiting=nil;slot:Hide() end
end
