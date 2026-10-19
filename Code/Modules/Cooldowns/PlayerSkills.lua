local _,M=...
local S={};M.PlayerSkillMonitor=S
local samples={{type="cooldown",value="116"},{type="debuff",value="172"},{type="cooldown",value="133"}}
local function Readable(v)return not issecretvalue or not issecretvalue(v)end
local function Number(v)return Readable(v) and type(v)=="number" and v or nil end
local function Safe(fn,...)
    if not fn then return end
    local ok,a,b,c,d,e=pcall(fn,...);if ok then return a,b,c,d,e end
end
function S.Input(value)
    if type(value)~="string" then return "" end
    return value:gsub("[%c]",""):match("^%s*(.-)%s*$")
end
function S.NewEntry()
    return {type="cooldown",value="",showShortcut=true,shortcut="",shortcutColor={1,1,1,1}}
end
S.directionChoices={{name="从左向右",path="RIGHT"},{name="从中间向两边",path="CENTER"},{name="从右向左",path="LEFT"}}
function S.Direction(group)
    local direction=group and group.growthDirection
    return (direction=="LEFT"or direction=="CENTER")and direction or "RIGHT"
end
function S.RowOffset(group,count)
    local extent=math.max(0,count-1)*22;local direction=S.Direction(group)
    return direction=="LEFT"and -extent or (direction=="CENTER"and 0 or extent)
end
function S.IconOffset(group,index,count)
    local direction=S.Direction(group)
    if direction=="LEFT"then return -(index-1)*44 end
    return (direction=="CENTER"and -(count-1)*22 or 0)+(index-1)*44
end
function S.ValidEntries(entries)
    if type(entries)~="table" then return false end
    for key,entry in pairs(entries) do
        if type(key)~="number" or key%1~=0 or key<1 or key>#entries or type(entry)~="table" then return false end
        if entry.type~="cooldown" and entry.type~="debuff" then return false end
        if type(entry.value)~="string" or #entry.value>384 then return false end
        if entry.showShortcut~=nil and type(entry.showShortcut)~="boolean" then return false end
        if entry.shortcut~=nil and (type(entry.shortcut)~="string" or #entry.shortcut>128) then return false end
        if entry.shortcutColor~=nil then
            if type(entry.shortcutColor)~="table" then return false end
            for i=1,4 do
                local v=entry.shortcutColor[i]
                if type(v)~="number" or v~=v or v<0 or v>1 then return false end
            end
            for k in pairs(entry.shortcutColor)do if type(k)~="number" or k%1~=0 or k<1 or k>4 then return false end end
        end
        for field in pairs(entry)do
            if field~="type" and field~="value" and field~="showShortcut" and field~="shortcut" and field~="shortcutColor" then return false end
        end
    end
    for i=1,#entries do if type(entries[i])~="table" then return false end end
    return true
end
local classes={WARRIOR=true,PALADIN=true,HUNTER=true,ROGUE=true,PRIEST=true,DEATHKNIGHT=true,
    SHAMAN=true,MAGE=true,WARLOCK=true,MONK=true,DRUID=true,DEMONHUNTER=true,EVOKER=true}
function S.ValidClassProfiles(profiles)
    if type(profiles)~="table"then return false end
    for class,entries in pairs(profiles)do if not classes[class]or not S.ValidEntries(entries)then return false end end
    return true
end
function S.ValidClass(class)return type(class)=="string"and classes[class]==true end
local function CurrentClass()
    local _,class=Safe(UnitClass,"player")
    return S.ValidClass(class)and class or nil
end
local function MonitorGroup(design)
    for _,node in ipairs(design and design.nodes or {})do if node.id=="playerSkillMonitor"then return node end end
end
function M:SavePlayerSkillMonitorClass()
    local db=self.db;local class=CurrentClass();local group=db and MonitorGroup(db.design)
    if not class or not group or db.playerSkillMonitorClass~=class or not S.ValidEntries(group.monitors)then return end
    if type(db.playerSkillMonitorsByClass)~="table"then db.playerSkillMonitorsByClass={}end
    db.playerSkillMonitorsByClass[class]=self.Copy(group.monitors)
end
function M:BindPlayerSkillMonitorClass()
    local db=self.db;local class=CurrentClass();local group=db and MonitorGroup(db.design)
    if not class or not group then return end
    if type(db.playerSkillMonitorsByClass)~="table"then db.playerSkillMonitorsByClass={}end
    local profiles=db.playerSkillMonitorsByClass
    for key,entries in pairs(profiles)do if not S.ValidClass(key)or not S.ValidEntries(entries)then profiles[key]=nil end end
    local previous=db.playerSkillMonitorClass
    if S.ValidClass(previous)and S.ValidEntries(group.monitors)then
        profiles[previous]=self.Copy(group.monitors)
    elseif profiles[class]==nil then
        -- Adopt the pre-upgrade list once, for the first class that loads it.
        profiles[class]=self.Copy(group.monitors)
    end
    group.monitors=self.Copy(profiles[class]or {S.NewEntry()})
    self:EnsurePlayerSkillMonitor(db.design)
    db.playerSkillMonitorClass=class;profiles[class]=self.Copy(group.monitors)
end
function M:ImportPlayerSkillMonitorClasses(config)
    if config.playerSkillMonitorsByClass then
        if type(self.db.playerSkillMonitorsByClass)~="table"then self.db.playerSkillMonitorsByClass={}end
        for class,entries in pairs(config.playerSkillMonitorsByClass)do self.db.playerSkillMonitorsByClass[class]=self.Copy(entries)end
        self.db.playerSkillMonitorClass=config.playerSkillMonitorClass
        self:BindPlayerSkillMonitorClass()
    else
        -- Older exports contain one list; import it into the current class.
        self.db.playerSkillMonitorClass=CurrentClass();self:SavePlayerSkillMonitorClass()
    end
end
function M:EnsurePlayerSkillMonitor(design)
    if not design or not design.nodes then return end
    local seen={};for _,n in ipairs(design.nodes)do seen[n.id]=n end
    local group=seen.playerSkillMonitor
    if not group then
        local cd=seen.cooldownMonitor
        group={id="playerSkillMonitor",label="玩家技能监控",kind="group",compound="playerSkillMonitor",scope="player",unit="player",
            x=0,y=-295,width=2,height=2,scale=cd and cd.scale or 1,scaleReference=cd and (cd.scaleReference or cd.scale) or 1,
            point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=340,monitors={S.NewEntry()},rules={},conditions={}}
        design.nodes[#design.nodes+1]=group
    end
    if not S.ValidEntries(group.monitors) then group.monitors={S.NewEntry()} end
    if group.hideWithoutTarget==nil then group.hideWithoutTarget=false end
    group.growthDirection=S.Direction(group)
    for _,entry in ipairs(group.monitors)do
        entry.value=S.Input(entry.value);entry.shortcut=S.Input(entry.shortcut)
        if entry.showShortcut==nil then entry.showShortcut=true end
        if entry.shortcutColor==nil then entry.shortcutColor={1,1,1,1} end
    end
    if not seen.playerSkillMonitorIcons then
        design.nodes[#design.nodes+1]={id="playerSkillMonitorIcons",label="玩家技能监控",kind="skillmonitor",parent=group.id,
            internal=true,locked=true,scope="player",unit="player",x=0,y=0,width=216,height=66,autoWidth=true,
            scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=341}
    end
end
M.moduleIDs.playerSkillMonitor=true
M:EnsurePlayerSkillMonitor(M.defaults);M:EnsurePlayerSkillMonitor(M.recordedDefaults)
function S.Entries(group)
    local result={}
    for _,entry in ipairs(group.monitors or {})do
        if entry.value~="" then result[#result+1]=entry end
    end
    return result
end
function S.MoveBounds(group)
    local count=#S.Entries(group)
    if count==0 then count=#samples end -- Movement mode shows the sample row.
    return S.RowOffset(group,count),20,math.max(180,count*44+20),112
end
function S.EntryIndex(group,entry)
    for i,current in ipairs(group.monitors or {})do if current==entry then return i end end
end
local curve,shortcutCurve,fadeCurve
local function DesaturationCurve()
    if not curve and C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType then
        curve=C_CurveUtil.CreateCurve();curve:SetType(Enum.LuaCurveType.Step);curve:AddPoint(0,0);curve:AddPoint(.001,1)
    end
    return curve
end
local function ShortcutCurve()
    if not shortcutCurve and C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType then
        shortcutCurve=C_CurveUtil.CreateCurve();shortcutCurve:SetType(Enum.LuaCurveType.Step)
        shortcutCurve:AddPoint(0,1);shortcutCurve:AddPoint(.001,0)
    end
    return shortcutCurve
end
local function FadeCurve()
    if not fadeCurve and C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType then
        fadeCurve=C_CurveUtil.CreateCurve();fadeCurve:SetType(Enum.LuaCurveType.Step)
        fadeCurve:AddPoint(0,1);fadeCurve:AddPoint(.001,.5)
    end
    return fadeCurve
end
local function NativeAurasAvailable()
    local interface=M.Compat.interface or 0
    if interface~=16001 and interface<120000 then return false end
    if not C_XMLUtil or not C_XMLUtil.GetTemplateInfo then return false end
    if not C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate") and not InCombatLockdown() and C_AddOns and C_AddOns.LoadAddOn then
        Safe(C_AddOns.LoadAddOn,"Blizzard_AuraContainer")
    end
    return C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")~=nil
end
local function ClearCooldown(cooldown)
    if cooldown.Clear then cooldown:Clear() else cooldown:SetCooldown(0,0) end
end
local countdownFontSize=16 -- Shared by countdowns and count labels.
local function Font(label)
    label:SetFont(M:EffectiveFontPath(M.MYRIAD),countdownFontSize,"OUTLINE");label:SetTextColor(1,1,1,1)
    label:SetJustifyH("CENTER");label:SetShadowColor(0,0,0,1);label:SetShadowOffset(1,-1)
end
local function CountFont(label)
    Font(label);label:SetShadowColor(0,0,0,0);label:SetShadowOffset(0,0)
end
local function CountText(label,value,showSingle,hideZero)
    if not Readable(value)then label:SetFormattedText("%d",value);return end
    local count=Number(value)
    label:SetText(count and count>=(hideZero and 1 or 0)and (showSingle or count>1)and tostring(count)or "")
end
-- Summon abilities use their live guardian count in the same place as spell
-- charges. Register only verified client mechanics; other spells keep charges.
-- Hawk Shot's player aura is the server-maintained guardian census, including
-- staggered expiry, replacement and reloads. Never infer it from the spell CD
-- or refresh both guardians' lifetimes when another hawk is summoned.
S.summonCountRules={
    {interfaces={[38001]=true,[38002]=true},spellIDs={[1284199]=true},
        referenceSpell=1284199,unit="player",auraIDs={[1284379]=true}},
}
function S.SummonCount(slot)
    local interface=M.Compat.interface or 0
    for _,rule in ipairs(S.summonCountRules)do
        if rule.interfaces[interface]then
            local matches=slot.spellID and rule.spellIDs[slot.spellID]
            if not matches then
                local name=M.PetBuffs.SpellInfo(tostring(rule.referenceSpell))
                matches=name and slot.spellName==name
            end
            if matches then
                for index=1,255 do
                    local aura=M.Compat.Aura(rule.unit,index,"HELPFUL");if not aura then break end
                    local id=aura.spellId;if type(id)=="nil"then id=aura.spellID end
                    if Readable(id)and rule.auraIDs[id]then
                        local source=aura.sourceUnit
                        local own=Readable(source)and (source==nil or source=="player"or
                            (UnitIsUnit and M.Compat.Bool(Safe(UnitIsUnit,source,"player"))))
                        if own then
                            local expires=Number(aura.expirationTime)
                            if not expires or expires==0 or expires>GetTime()then
                                local count=aura.applications
                                if not Readable(count)then return count end
                                return math.max(1,Number(count)or 1)
                            end
                        end
                    end
                end
                return 0
            end
        end
    end
end
local function StyleNativeAura(slot,frame)
    frame:SetSize(40,40);frame:EnableMouse(false);frame:EnableMouseMotion(true)
    frame:SetTooltipAnchorPoint("ANCHOR_RIGHT");frame:SetHideTooltipInCombat(false)
    frame.monitorIcon=frame:CreateTexture(nil,"ARTWORK");frame.monitorIcon:SetAllPoints();frame.monitorIcon:SetDesaturated(true)
    frame.monitorIcon:SetAlpha(.5)
    frame.monitorTime=frame:CreateFontString(nil,"OVERLAY");Font(frame.monitorTime)
    frame.monitorTime:SetPoint("BOTTOM",frame,"TOP",0,7)
    frame:SetIcon(frame.monitorIcon);frame:SetDurationText(frame.monitorTime,{})
    frame.monitorCount=frame:CreateFontString(nil,"OVERLAY");CountFont(frame.monitorCount)
    frame.monitorCount:SetPoint("BOTTOM",frame,"TOP",0,29);frame:SetApplicationCount(frame.monitorCount,{})
    -- Each native aura frame gates the annotation through engine alpha. This
    -- also handles private visibility without testing secret booleans in Lua.
    frame.shortcutGate=CreateFrame("Frame",nil,slot.shortcutGate or slot.shortcutFrame)
    frame.shortcutGate:SetAllPoints();frame.shortcutGate:EnableMouse(false)
    slot.shortcutGate=frame.shortcutGate;slot.shortcut:SetParent(frame.shortcutGate)
    -- Remove the colored backing while a native gray icon is present, so its
    -- half opacity is not composited over another fully opaque icon.
    frame.baseIconGate=CreateFrame("Frame",nil,slot.baseIconGate or slot.baseIconFrame)
    frame.baseIconGate:SetAllPoints();frame.baseIconGate:EnableMouse(false)
    slot.baseIconGate=frame.baseIconGate;slot.texture:SetParent(frame.baseIconGate)
    slot.nativeFrames[#slot.nativeFrames+1]=frame
end
local function NativeAura(slot)
    local container=CreateFrame("AuraContainer",nil,slot,"CustomAuraContainerTemplate")
    container:SetEnabled(false);container:SetUnit("target");container:SetPoint("TOPLEFT",slot,"TOPLEFT",0,0)
    slot.nativeFrames={};slot.nativeAuras=container
    container:AddAuraGroup("monitor","HARMFUL|PLAYER",{maxFrameCount=0,initializeFrame=function(frame)StyleNativeAura(slot,frame)end})
    container:SetFlowLayoutAnchorPoint("TOPLEFT")
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right,AnchorUtil.FlowDirection.Down)
    container:SetFlowLayoutMaximumLineSize(40.001)
    container:SetAuraGroupLayout("monitor",{elementSpacing=0,lineSpacing=0,elementWidth=40,elementHeight=40})
end
local function Icon(o,i)
    local slot=o.skillIcons[i];if slot then return slot end
    slot=CreateFrame("Frame",nil,o.frame);slot:SetSize(40,40);slot:EnableMouse(true)
    slot.baseIconFrame=CreateFrame("Frame",nil,slot);slot.baseIconFrame:SetAllPoints();slot.baseIconFrame:EnableMouse(false)
    slot.texture=slot.baseIconFrame:CreateTexture(nil,"ARTWORK");slot.texture:SetAllPoints()
    slot.text=slot:CreateFontString(nil,"OVERLAY");Font(slot.text);slot.text:SetPoint("BOTTOM",slot,"TOP",0,7)
    slot.count=slot:CreateFontString(nil,"OVERLAY");CountFont(slot.count);slot.count:SetPoint("BOTTOM",slot,"TOP",0,29)
    slot.cooldown=CreateFrame("Cooldown",nil,slot,"CooldownFrameTemplate");slot.cooldown:SetAllPoints();slot.cooldown:EnableMouse(false)
    slot.cooldown:SetDrawEdge(false);slot.cooldown:SetDrawBling(false);slot.cooldown:SetDrawSwipe(false)
    slot.cooldown:SetHideCountdownNumbers(false);slot.cooldown.noCooldownCount=true
    if slot.cooldown.GetCountdownFontString then
        slot.nativeTime=slot.cooldown:GetCountdownFontString()
        if slot.nativeTime then Font(slot.nativeTime);slot.nativeTime:ClearAllPoints();slot.nativeTime:SetPoint("BOTTOM",slot,"TOP",0,7)end
    end
    -- Keep the annotation above the native aura overlay and cooldown children.
    slot.shortcutFrame=CreateFrame("Frame",nil,slot);slot.shortcutFrame:SetAllPoints();slot.shortcutFrame:EnableMouse(false)
    slot.shortcutFrame:SetFrameLevel(slot:GetFrameLevel()+30)
    slot.shortcut=slot.shortcutFrame:CreateFontString(nil,"OVERLAY");slot.shortcut:SetPoint("CENTER",slot,"BOTTOM",2,2)
    slot:SetScript("OnEnter",function(self)
        if not self.entry then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        if self.spellID and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(self.spellID)
        else GameTooltip:AddLine(self.entry.value,1,1,1)end
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave",function()GameTooltip:Hide()end)
    o.skillIcons[i]=slot;return slot
end
local function Shortcut(slot,entry)
    Font(slot.shortcut);slot.shortcut:SetFont(M:EffectiveFontPath(M.MYRIAD),20,"OUTLINE")
    slot.shortcut:SetTextColor(unpack(entry.shortcutColor or {1,1,1,1}))
    slot.shortcut:SetText((entry.shortcut or ""):gsub("|","||"))
    slot.shortcut:SetShown(entry.showShortcut~=false and entry.shortcut~=nil and entry.shortcut~="")
end
local function Resolve(slot,entry)
    local name,id,icon=M.PetBuffs.SpellInfo(entry.value)
    id=tonumber(entry.value) or id or Safe(C_Spell and C_Spell.GetSpellIDForSpellIdentifier,entry.value)
    if not Readable(id) then id=nil end
    slot.entry=entry;slot.spellID=id;slot.spellName=name or entry.value
    slot.texture:SetTexture(icon or 134400);slot.needsInfo=not id or not icon;slot.nextInfo=GetTime()+1
end
local function BindAura(slot,enabled)
    if enabled==false or slot.entry.type~="debuff" or not slot.spellID then
        if slot.nativeAuras then slot.nativeAuras:SetEnabled(false)end
        return
    end
    if not slot.nativeAuras then NativeAura(slot)end
    slot.nativeAuras:SetEnabled(false)
    slot.nativeAuras:SetAuraGroupCandidateFilters("monitor",{includeSpellIDs={[slot.spellID]=true}})
    slot.nativeAuras:SetAuraGroupMaxFrameCount("monitor",1)
    slot.nativeAuras:SetEnabled(true);slot.nativeAuras:UpdateAllAuras()
end
function S.Configure(view,o)
    o.skillIcons=o.skillIcons or {};o.nextScan=0;o.nativeTargetGeneration=nil
    o.entries=S.Entries(view.byID[o.spec.parent]);o.usesNativeAuras=not view.preview and NativeAurasAvailable()
    for i,entry in ipairs(o.entries)do
        local slot=Icon(o,i);Resolve(slot,entry);slot.duration=nil;slot.expires=nil;slot.active=false;slot.stacks=nil
        CountFont(slot.count);slot.count:SetText("")
        slot.text:SetText("");ClearCooldown(slot.cooldown);slot.texture:SetDesaturated(false)
        Font(slot.text)
        Shortcut(slot,entry)
        if slot.nativeTime then Font(slot.nativeTime)end
        for _,frame in ipairs(slot.nativeFrames or {})do Font(frame.monitorTime);CountFont(frame.monitorCount)end
        if o.usesNativeAuras then BindAura(slot,view.byID[o.spec.parent].enabled~=false)end
    end
    for i=#o.entries+1,#o.skillIcons do
        local slot=o.skillIcons[i];slot:Hide();slot.entry=nil
        if slot.nativeAuras then slot.nativeAuras:SetEnabled(false)end
    end
end
local function Remaining(slot,seconds)
    slot.text:SetText(seconds and seconds>0 and (seconds>=60 and math.ceil(seconds/60).."m" or tostring(math.ceil(seconds))) or "")
end
local function Cooldown(entry,slot)
    local key=slot.spellID or entry.value
    local charges,maximum,chargeStart,chargeDuration,chargeRate
    if C_Spell and C_Spell.GetSpellCharges then
        local info=Safe(C_Spell.GetSpellCharges,key)
        if info then charges,maximum,chargeStart,chargeDuration,chargeRate=info.currentCharges,info.maxCharges,info.cooldownStartTime,info.cooldownDuration,info.chargeModRate end
    else charges,maximum,chargeStart,chargeDuration,chargeRate=Safe(GetSpellCharges,key)end
    local summons=S.SummonCount(slot)
    if summons~=nil then CountText(slot.count,summons,true,true)
    elseif Number(maximum)and maximum<=1 then slot.count:SetText("")else CountText(slot.count,charges,true)end
    if C_Spell and C_Spell.GetSpellCooldownDuration then
        local duration=Safe(C_Spell.GetSpellChargeDuration,key) or Safe(C_Spell.GetSpellCooldownDuration,key,true)
        if duration and slot.cooldown.SetCooldownFromDurationObject then
            slot.duration=duration;slot.expires=nil;slot.text:SetText("")
            slot.cooldown:SetCooldownFromDurationObject(duration,true);return
        end
    end
    slot.duration=nil;ClearCooldown(slot.cooldown)
    local start,duration,enabled,rate
    if C_Spell and C_Spell.GetSpellCooldown then
        local info=Safe(C_Spell.GetSpellCooldown,key)
        if info then
            if Readable(info.isOnGCD) and info.isOnGCD==true then slot.active=false;slot.expires=nil;return end
            start,duration,enabled,rate=info.startTime,info.duration,info.isEnabled,info.modRate
        end
    else start,duration,enabled,rate=Safe(GetSpellCooldown,key)end
    if Number(charges) and Number(maximum) and charges<maximum and Number(chargeStart) and Number(chargeDuration) then
        start,duration,rate=chargeStart,chargeDuration,chargeRate
    end
    start,duration,rate=Number(start),Number(duration),Number(rate) or 1
    local disabled=Readable(enabled) and (enabled==false or enabled==0)
    if start and duration and rate>0 and not disabled then
        local gcdID=M.Compat.interface==16001 and 29515 or 61304
        local gs,gd=Safe(GetSpellCooldown,gcdID)
        local gcd=Number(gs) and Number(gd) and math.abs(gs-start)<.001 and math.abs(gd-duration)<.001
        slot.expires=not gcd and duration>0 and start+duration/rate or nil
    else slot.expires=nil end
    slot.active=slot.expires~=nil and slot.expires>GetTime()
end
local function TargetAuras(o)
    local needed=false
    for _,slot in ipairs(o.skillIcons)do
        if slot.entry and slot.entry.type=="debuff" then slot.active=false;slot.expires=nil;slot.stacks=nil;needed=true end
    end
    if not needed or o.usesNativeAuras then return end
    for index=1,255 do
        local aura=M.Compat.Aura("target",index,"HARMFUL");if not aura then break end
        local id=aura.spellId;if type(id)=="nil" then id=aura.spellID end
        for _,slot in ipairs(o.skillIcons)do
            local entry=slot.entry
            if entry and entry.type=="debuff" then
                local requested=tonumber(entry.value)
                local match=requested and Readable(id) and id==requested or (not requested and Readable(aura.name) and aura.name==entry.value)
                local source=aura.sourceUnit
                local own=Readable(source) and (source=="player" or
                    (source~=nil and UnitIsUnit and M.Compat.Bool(Safe(UnitIsUnit,source,"player"))))
                if match and own then
                    slot.active=true
                    local stacks=Number(aura.applications)
                    if stacks and (not slot.stacks or stacks>slot.stacks)then slot.stacks=stacks end
                    local expires=Number(aura.expirationTime)
                    if expires and expires>0 and (not slot.expires or expires>slot.expires)then slot.expires=expires end
                    if Readable(aura.icon) and aura.icon~=nil then slot.texture:SetTexture(aura.icon)end
                end
            end
        end
    end
end
function S.Paint(view,o,animateOnly)
    local group=view.byID[o.spec.parent]
    local shown=o.spec.enabled~=false and (view.preview or group.enabled~=false) and not(view.hidden and view.hidden[o.spec.id])
    if shown and not view.preview and group.hideWithoutTarget==true then shown=M.Compat.Bool(Safe(UnitExists,"target"))end
    if o.frame:IsShown()~=shown then o.frame:SetShown(shown)end
    if not shown then return end
    local now=GetTime();local entries=o.entries or {}
    if view.preview and #entries==0 then entries=samples end
    o.rowCount=#entries
    local width=math.max(1,#entries*44-4)
    if o.rowWidth~=width then o.frame:SetSize(width,66);o.rowWidth=width end
    if not animateOnly or now>=(o.nextScan or 0) then
        o.nextScan=now+.2
        for i,entry in ipairs(entries)do
            local slot=Icon(o,i)
            if slot.entry~=entry then Resolve(slot,entry)end
            if view.preview and o.entries and #o.entries==0 then Shortcut(slot,entry)end
            if not view.preview and slot.needsInfo and now>=(slot.nextInfo or 0) then
                Resolve(slot,entry)
                if o.usesNativeAuras and not InCombatLockdown() then BindAura(slot,group.enabled~=false)end
            end
            local x=S.IconOffset(group,i,#entries)
            if slot.rowX~=x then slot:ClearAllPoints();slot:SetPoint("CENTER",o.frame,"CENTER",x,-7);slot.rowX=x end
            if not slot:IsShown() then slot:Show()end
            if not view.preview and entry.type=="cooldown" then Cooldown(entry,slot)end
        end
        if not view.preview then TargetAuras(o)end
        local version=view.targetRefreshGeneration or 0
        if not view.preview and o.nativeTargetGeneration~=version then
            for _,slot in ipairs(o.skillIcons)do if slot.nativeAuras and slot.entry and slot.entry.type=="debuff" then slot.nativeAuras:UpdateAllAuras()end end
            o.nativeTargetGeneration=version
        end
    end
    for i=1,#entries do
        local slot=o.skillIcons[i]
        slot.shortcutFrame:SetAlpha(1)
        slot.texture:SetAlpha(1)
        for _,frame in ipairs(slot.nativeFrames or {})do
            if not view.preview and o.usesNativeAuras and slot.entry.type=="debuff" then
                local present=frame:IsShown()
                if frame.shortcutGate.SetAlphaFromBoolean then
                    frame.shortcutGate:SetAlphaFromBoolean(present,0,1);frame.baseIconGate:SetAlphaFromBoolean(present,0,1)
                elseif Readable(present)then
                    frame.shortcutGate:SetAlpha(present and 0 or 1);frame.baseIconGate:SetAlpha(present and 0 or 1)
                end
            else frame.shortcutGate:SetAlpha(1);frame.baseIconGate:SetAlpha(1)end
        end
        if view.preview then
            ClearCooldown(slot.cooldown);slot.texture:SetDesaturated(i%2==1);slot.texture:SetAlpha(i%2==1 and .5 or 1);slot.text:SetText(tostring(30-i))
            slot.count:SetText(slot.entry.type=="debuff"and "3"or "2")
        elseif slot.duration then
            local desat=DesaturationCurve()
            if desat and slot.duration.EvaluateRemainingDuration and slot.texture.SetDesaturation then
                -- The engine consumes this potentially secret number directly.
                slot.texture:SetDesaturation(slot.duration:EvaluateRemainingDuration(desat,0))
                slot.texture:SetAlpha(slot.duration:EvaluateRemainingDuration(FadeCurve(),1))
                slot.shortcutFrame:SetAlpha(slot.duration:EvaluateRemainingDuration(ShortcutCurve(),1))
            else
                local remaining=Number(Safe(slot.duration.GetRemainingDuration,slot.duration))
                if remaining then
                    slot.texture:SetDesaturated(remaining>0);Remaining(slot,remaining)
                    slot.texture:SetAlpha(remaining>0 and .5 or 1)
                    slot.shortcutFrame:SetAlpha(remaining>0 and 0 or 1)
                end
            end
        elseif slot.entry.type=="debuff" and o.usesNativeAuras then
            slot.texture:SetDesaturated(false);slot.text:SetText("");slot.count:SetText("")
            -- Native aura frames draw a gray overlay and countdown only while
            -- present. The colored base icon remains visible when absent.
        else
            local active=slot.active and (not slot.expires or slot.expires>now)
            slot.texture:SetDesaturated(active==true);Remaining(slot,active and slot.expires and slot.expires-now or nil)
            slot.texture:SetAlpha(active and .5 or 1)
            slot.shortcutFrame:SetAlpha(active and 0 or 1)
            if slot.entry.type=="debuff"then CountText(slot.count,active and slot.stacks or nil,false)end
        end
    end
end
local events={PLAYER_TARGET_CHANGED=true,UNIT_AURA=true,SPELL_UPDATE_COOLDOWN=true,SPELL_UPDATE_CHARGES=true,
    SPELLS_CHANGED=true,LEARNED_SPELL_IN_TAB=true,PLAYER_ENTERING_WORLD=true,PLAYER_REGEN_ENABLED=true,UNIT_SPELLCAST_SUCCEEDED=true}
function S.Event(view,event,unit)
    if not events[event] or (event=="UNIT_AURA" and unit~="target"and unit~="player") or (event=="UNIT_SPELLCAST_SUCCEEDED" and unit~="player")then return end
    local o=view.nodes.playerSkillMonitorIcons
    if o then
        o.nextScan=0
        if event=="PLAYER_TARGET_CHANGED" then o.nativeTargetGeneration=nil end
        if event=="SPELLS_CHANGED" or event=="LEARNED_SPELL_IN_TAB" or event=="PLAYER_REGEN_ENABLED" then
            for _,slot in ipairs(o.skillIcons or {})do slot.needsInfo=true;slot.nextInfo=0 end
        end
        S.Paint(view,o,false)
    end
end

function S.BuildControls(e,parent,Row)
    local W=M.Widgets
    local choices={{name="玩家技能冷却",path="cooldown"},{name="目标Debuff",path="debuff"}}
    local panel=CreateFrame("Frame",nil,parent);panel:SetSize(470,30);e.skillMonitorPanel=panel
    local sharing=CreateFrame("Frame",nil,parent);sharing:SetSize(470,56);e.skillMonitorSharing=sharing
    local function SectionTitle(frame,text)
        local title=W.Label(frame,text,12);title:SetPoint("CENTER",frame,"TOP",0,12)
        title:SetTextColor(1,.82,0);title:SetJustifyH("CENTER");M:SetLocaleLineHeight(title,18)
        local left=frame:CreateTexture(nil,"ARTWORK");left:SetHeight(1);left:SetColorTexture(.5,.5,.5,.45)
        left:SetPoint("LEFT",frame,"TOPLEFT",0,12);left:SetPoint("RIGHT",title,"LEFT",-8,0)
        local right=frame:CreateTexture(nil,"ARTWORK");right:SetHeight(1);right:SetColorTexture(.5,.5,.5,.45)
        right:SetPoint("LEFT",title,"RIGHT",8,0);right:SetPoint("RIGHT",frame,"TOPRIGHT",0,12)
        return title
    end
    sharing.title=SectionTitle(sharing,"配置分享");panel.title=SectionTitle(panel,"监控设置")
    e.propRows[#e.propRows+1]={height=56,controls={{sharing,0,0}},kinds={},key="skillMonitorSharing"}
    local property={height=30,controls={{panel,0,0}},kinds={},key="skillMonitorItems"}
    e.propRows[#e.propRows+1]=property;panel.propertyRow=property;panel.rows={}
    local function Current()local n=M.byID[M.selection];return n and n.compound=="playerSkillMonitor" and n end
    local function Editable(group,entry)
        return group and M.byID[group.id]==group and S.EntryIndex(group,entry) and M:CanEdit()
    end
    local function Flush()
        for _,row in ipairs(panel.rows)do row.edit:ClearFocus();row.shortcutEdit:ClearFocus()end
    end
    sharing.exportAll=W.Button(sharing,"导出全职业配置",150,function()Flush();M:ShowConfigStringDialog("export","skillsAll")end)
    sharing.exportClass=W.Button(sharing,"导出当前职业配置",150,function()Flush();M:ShowConfigStringDialog("export","skillsClass")end)
    sharing.import=W.Button(sharing,"导入配置",150,function()Flush();M:ShowConfigStringDialog("import","skills")end)
    for _,button in ipairs({sharing.exportAll,sharing.exportClass,sharing.import})do button:SetHoverTextColor(1,.82,0)end
    local function SkillIcon(row)
        local value=S.Input(row.edit:GetText())
        local name,_,icon
        if value~="" then name,_,icon=M.PetBuffs.SpellInfo(value)end
        row.skillIcon.texture:SetTexture(name and icon or 134400)
    end
    panel.insertMarker=CreateFrame("Frame",nil,panel);panel.insertMarker:SetSize(470,2)
    panel.insertMarker:SetFrameLevel(panel:GetFrameLevel()+40);panel.insertMarker:Hide()
    local line=panel.insertMarker:CreateTexture(nil,"OVERLAY");line:SetAllPoints();line:SetColorTexture(1,.82,0,1)
    panel.dragGhost=W.Panel(e.window);panel.dragGhost:SetSize(220,32);panel.dragGhost:SetFrameStrata("TOOLTIP")
    panel.dragGhost:SetFrameLevel(9200);panel.dragGhost:Hide()
    panel.dragText=panel.dragGhost:CreateFontString(nil,"OVERLAY");panel.dragText:SetFont(M:DefaultFontPath(),12,"")
    panel.dragText:SetPoint("LEFT",10,0);panel.dragText:SetWidth(200);panel.dragText:SetWordWrap(false)
    function panel:FinishDrag(apply)
        self:EnableKeyboard(false);self:SetPropagateKeyboardInput(true)
        local drag=self.drag;if not drag then return end
        self.drag=nil;self.insertMarker:Hide();self.dragGhost:Hide()
        for _,row in ipairs(self.rows)do row.dragTint:Hide()end
        if not apply or not drag.valid or Current()~=drag.group or drag.entries~=drag.group.monitors or not Editable(drag.group,drag.entry)then return end
        local from=S.EntryIndex(drag.group,drag.entry)
        if from~=drag.target then
            table.remove(drag.entries,from);table.insert(drag.entries,drag.target,drag.entry);M:Commit()
        end
    end
    function panel:UpdateDrag(elapsed)
        local drag=self.drag;if not drag then return end
        if not self:IsVisible()or Current()~=drag.group or drag.entries~=drag.group.monitors or #drag.entries~=drag.count or not Editable(drag.group,drag.entry)then
            self:FinishDrag(false);return
        end
        local cursorX,cursorY=GetCursorPosition();local scale=self:GetEffectiveScale()
        local x,y=cursorX/scale,cursorY/scale;local scroll=e.propScroll
        local top,bottom,left,right=scroll:GetTop(),scroll:GetBottom(),scroll:GetLeft(),scroll:GetRight()
        if not top or not bottom or not left or not right or not self:GetTop()then self:FinishDrag(false);return end
        drag.valid=x>=left and x<=right and y>=bottom and y<=top
        if drag.valid then
            local direction=y>top-22 and -1 or (y<bottom+22 and 1 or 0)
            if direction~=0 then
                local limit=math.max(0,e.props:GetHeight()-scroll:GetHeight())
                scroll:SetVerticalScroll(M.Clamp(scroll:GetVerticalScroll()+direction*(elapsed or 0)*260,0,limit))
            end
            local insertion=M.Clamp(math.floor((self:GetTop()-y)/88+.5)+1,1,drag.count+1)
            local from=S.EntryIndex(drag.group,drag.entry)
            drag.target=M.Clamp(insertion-(insertion>from and 1 or 0),1,drag.count)
            self.insertMarker:ClearAllPoints();self.insertMarker:SetPoint("TOPLEFT",self,"TOPLEFT",0,-(insertion-1)*88+3)
            self.insertMarker:SetWidth(self:GetWidth());self.insertMarker:Show()
        else self.insertMarker:Hide()end
        local ghostScale=self.dragGhost:GetEffectiveScale()
        self.dragGhost:ClearAllPoints();self.dragGhost:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",cursorX/ghostScale+14,cursorY/ghostScale+12)
    end
    function panel:BeginDrag(row)
        if self.drag or not Editable(row.group,row.entry)or #row.group.monitors<2 then return end
        Flush()
        for _,current in ipairs(self.rows)do if current.drop.menu then current.drop.menu:Hide()end end
        local group,entry=row.group,row.entry;local index=S.EntryIndex(group,entry)
        self.drag={group=group,entry=entry,entries=group.monitors,count=#group.monitors,target=index,valid=false}
        row.dragTint:Show();self.dragText:SetText((entry.value~="" and entry.value or M:T("拖拽排序")):gsub("|","||"))
        self.dragGhost:Show();self:EnableKeyboard(true);self:SetPropagateKeyboardInput(true);self:UpdateDrag(0)
    end
    local function DragSurface(surface,row)
        surface:EnableMouse(true);surface:RegisterForDrag("LeftButton")
        surface:SetScript("OnDragStart",function()panel:BeginDrag(row)end)
        surface:SetScript("OnDragStop",function()panel:UpdateDrag(0);panel:FinishDrag(true)end)
        surface:SetScript("OnMouseUp",function(_,button)if button=="RightButton"then panel:FinishDrag(false)end end)
    end
    panel:SetScript("OnUpdate",function(self,elapsed)
        if not self.drag then return end
        self:UpdateDrag(elapsed)
        if IsMouseButtonDown("RightButton")then self:FinishDrag(false)
        elseif not IsMouseButtonDown("LeftButton")then self:FinishDrag(true)end
    end)
    panel:SetScript("OnKeyDown",function(self,key)
        if not self.drag then self:SetPropagateKeyboardInput(true);return end
        self:SetPropagateKeyboardInput(key~="ESCAPE")
        if key=="ESCAPE"then self:FinishDrag(false);self:SetPropagateKeyboardInput(false)end
    end)
    panel:EnableKeyboard(false);panel:SetPropagateKeyboardInput(true)
    panel:SetScript("OnShow",function(self)if not self.drag then self:EnableKeyboard(false);self:SetPropagateKeyboardInput(true)end end)
    panel:SetScript("OnHide",function(self)
        self:FinishDrag(false)
        if M.configDialog and M.configDialog.scope then M.configDialog:Hide()end
    end)
    local function BindInput(row,edit,field)
        local function Save(self,owner,item)
            owner=owner or self.monitorOwner or row.group;item=item or self.monitorEntry or row.entry
            if not Editable(owner,item)then return end
            local value=S.Input(self:GetText())
            if item[field]~=value then item[field]=value;M:Commit()end
        end
        edit:SetScript("OnEditFocusGained",function(self)self.monitorOwner=row.group;self.monitorEntry=row.entry end)
        edit:SetScript("OnEditFocusLost",function(self)
            local owner,item=self.monitorOwner,self.monitorEntry;self.monitorOwner=nil;self.monitorEntry=nil;Save(self,owner,item)
        end)
        edit:SetScript("OnEnterPressed",function(self)Save(self);self:ClearFocus()end)
        edit:SetScript("OnEscapePressed",function(self)self:SetText((self.monitorEntry or row.entry)[field] or "");self:ClearFocus()end)
        edit:HookScript("OnHide",function(self)self:ClearFocus()end)
    end
    panel.add=W.Button(panel,"添加监控",130,function()
        local group=Current();if not group or not M:CanEdit()then return end
        Flush();group.monitors[#group.monitors+1]=S.NewEntry();M:Commit()
    end)
    function panel:Refresh(group)
        if self.drag and (self.drag.group~=group or self.drag.entries~=group.monitors or self.drag.count~=#group.monitors)then self:FinishDrag(false)end
        local monitors=group and group.monitors or {};local width=e.props:GetWidth()
        sharing:SetWidth(width)
        for i,button in ipairs({sharing.exportAll,sharing.exportClass,sharing.import})do
            local buttonWidth=(width-16)/3;button:SetWidth(buttonWidth)
            button:ClearAllPoints();button:SetPoint("TOPLEFT",sharing,"TOPLEFT",(i-1)*(buttonWidth+8),-24)
        end
        if self.owner~=group or self.count~=#monitors or self.width~=width then e.propertyLayoutSignature=nil end
        self.owner,self.count,self.width=group,#monitors,width
        self:SetSize(width,#monitors*88+32);property.height=self:GetHeight()
        for i,entry in ipairs(monitors)do
            local row=self.rows[i]
            if not row then
                row=CreateFrame("Frame",nil,self);row:SetHeight(84);self.rows[i]=row
                row.separator=row:CreateTexture(nil,"ARTWORK");row.separator:SetHeight(1)
                row.separator:SetPoint("TOPLEFT",0,6);row.separator:SetPoint("TOPRIGHT",0,6)
                row.separator:SetColorTexture(.45,.45,.45,.22)
                row.dragTint=row:CreateTexture(nil,"BACKGROUND");row.dragTint:SetAllPoints();row.dragTint:SetColorTexture(.2,.6,.9,.2);row.dragTint:Hide()
                DragSurface(row,row)
                row.dragHandle=CreateFrame("Button",nil,row);row.dragHandle:SetSize(100,18)
                row.dragLabel=W.Label(row.dragHandle,"拖拽排序",12);row.dragLabel:SetPoint("CENTER");row.dragLabel:SetJustifyH("CENTER")
                row.dragLabel:SetTextColor(.65,.65,.65)
                M:SetLocaleLineHeight(row.dragLabel,18);row.dragLabel:SetWordWrap(false)
                DragSurface(row.dragHandle,row)
                -- Reuse the font selector's skin, arrow, menu rows and single check mark.
                row.drop=W.MediaSelect(row,"监控类型",160,"choice",function()
                    if row.drop.menu then row.drop.menu:Hide();return end
                    local owner,item=row.group,row.entry
                    W.MediaMenu(row.drop,choices,"choice",item.type,function(choice)
                        Flush()
                        if Editable(owner,item)then item.type=choice.path;M:Commit()end
                    end)
                end)
                row.drop:SetPoint("TOPLEFT",0,0);row.caption=row.drop.caption
                function row.drop:SetValue(value)
                    self.value=value
                    self:SetMedia(value=="debuff" and "目标Debuff" or "玩家技能冷却",value)
                end
                row.showShortcut=W.Check(row,"显示快捷键",function(enabled)
                    local owner,item=row.group,row.entry;Flush()
                    if Editable(owner,item)then item.showShortcut=enabled==true;M:Commit()end
                end)
                row.showShortcut.label:SetWordWrap(false)
                row.shortcutEdit=W.Edit(row,100);row.shortcutEdit:SetMaxLetters(32);row.shortcutEdit:SetTextInsets(6,6,0,0)
                row.shortcutPlaceholder=W.Label(row.shortcutEdit,"快捷键",11)
                row.shortcutPlaceholder:SetPoint("LEFT",6,0);row.shortcutPlaceholder:SetPoint("RIGHT",-6,0)
                row.shortcutPlaceholder:SetTextColor(.5,.5,.5);row.shortcutPlaceholder:SetWordWrap(false)
                row.shortcutEdit:HookScript("OnTextChanged",function(self)row.shortcutPlaceholder:SetShown(self:GetText()=="")end)
                BindInput(row,row.shortcutEdit,"shortcut")
                row.shortcutColor=W.ColorSwatch(row,function(color)
                    local owner,item=row.colorOwner,row.colorEntry
                    if Editable(owner,item)then item.shortcutColor=M.Copy(color);M:Commit()end
                end)
                local openColor=row.shortcutColor:GetScript("OnClick")
                row.shortcutColor:SetScript("OnClick",function(button)
                    Flush();row.colorOwner,row.colorEntry=row.group,row.entry;openColor(button)
                end)
                row.skillIcon=CreateFrame("Button",nil,row);row.skillIcon:SetSize(26,26);row.skillIcon:SetPoint("TOPLEFT",0,-51)
                row.skillIcon.texture=row.skillIcon:CreateTexture(nil,"ARTWORK");row.skillIcon.texture:SetAllPoints()
                DragSurface(row.skillIcon,row)
                row.edit=W.Edit(row,width/2);row.edit:SetMaxLetters(128);row.edit:SetTextInsets(6,6,0,0)
                row.edit:SetPoint("LEFT",row.skillIcon,"RIGHT",8,0)
                row.placeholder=W.Label(row.edit,"输入监控技能名或ID",11)
                row.placeholder:SetPoint("LEFT",row.edit,"LEFT",6,0);row.placeholder:SetPoint("RIGHT",row.edit,"RIGHT",-6,0)
                row.placeholder:SetTextColor(.5,.5,.5);row.placeholder:SetWordWrap(false)
                row.edit:HookScript("OnTextChanged",function(self)row.placeholder:SetShown(self:GetText()=="");SkillIcon(row)end)
                BindInput(row,row.edit,"value")
                row.remove=W.Button(row,"删除",72,function()
                    local owner,item=row.group,row.entry;Flush()
                    local index=owner and S.EntryIndex(owner,item)
                    if index and Editable(owner,item)then table.remove(owner.monitors,index);M:Commit()end
                end)
                row.remove:SetPoint("TOPRIGHT",row,"TOPRIGHT",0,-53)
                row.dragHandle:SetPoint("TOP",row.remove,"TOP",0,53)
            end
            row.group,row.entry=group,entry;row:SetWidth(width);row:SetPoint("TOPLEFT",self,"TOPLEFT",0,-(i-1)*88)
            row.dragHandle:SetWidth(math.max(100,row.dragLabel:GetStringWidth()+4))
            local dropWidth=math.max(140,width*.34)
            row.drop:SetWidth(dropWidth);row.drop:SetValue(entry.type)
            row.showShortcut:ClearAllPoints();row.showShortcut:SetPoint("TOPLEFT",row,"TOPLEFT",dropWidth+10,-20)
            local keyX=dropWidth+10+24+math.max(72,row.showShortcut.label:GetStringWidth())+8
            row.shortcutEdit:ClearAllPoints();row.shortcutEdit:SetPoint("TOPLEFT",row,"TOPLEFT",keyX,-21)
            row.shortcutEdit:SetWidth(70)
            row.shortcutColor:ClearAllPoints();row.shortcutColor:SetPoint("LEFT",row.shortcutEdit,"RIGHT",12,0)
            row.edit:SetWidth(width/3);row.separator:SetShown(i>1)
            if not row.edit:HasFocus()then row.edit:SetText(entry.value)end
            if not row.shortcutEdit:HasFocus()then row.shortcutEdit:SetText(entry.shortcut or "")end
            row.showShortcut:SetChecked(entry.showShortcut~=false);row.shortcutColor:SetColor(entry.shortcutColor or {1,1,1,1})
            local shortcutEnabled=entry.showShortcut~=false
            if shortcutEnabled then row.shortcutEdit:Enable()else row.shortcutEdit:ClearFocus();row.shortcutEdit:Disable()end
            row.shortcutEdit:EnableMouse(shortcutEnabled);row.shortcutEdit:SetAlpha(shortcutEnabled and 1 or .55)
            row.shortcutEdit:SetTextColor(shortcutEnabled and 1 or .45,shortcutEnabled and 1 or .45,shortcutEnabled and 1 or .45)
            row.shortcutPlaceholder:SetShown(row.shortcutEdit:GetText()=="");SkillIcon(row)
            row.placeholder:SetShown(row.edit:GetText()=="");row:Show()
        end
        for i=#monitors+1,#self.rows do self.rows[i]:Hide()end
        self.add:ClearAllPoints();self.add:SetPoint("TOPLEFT",self,"TOPLEFT",0,-#monitors*88)
    end
end
