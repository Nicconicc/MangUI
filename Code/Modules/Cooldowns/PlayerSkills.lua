local _,M=...
local S={};M.PlayerSkillMonitor=S
local samples={{type="cooldown",value="116"},{type="debuff",value="172"},{type="cooldown",value="133"}}
local function Readable(v)return not issecretvalue or not issecretvalue(v)end
local function Number(v)return Readable(v) and type(v)=="number" and v or nil end
local function Safe(fn,...)
    if not fn then return end
    local ok,a,b,c,d,e=pcall(fn,...);if ok then return a,b,c,d,e end
end
function S.FormatCountdown(seconds)
    seconds=Number(seconds)
    if not seconds or seconds<=0 then return "" end
    local whole=math.ceil(seconds)
    if seconds>=60 then return string.format("%d:%02d",math.floor(whole/60),whole%60)end
    return tostring(whole)
end
local countdownFormatter
function S.CountdownFormatter()
    if countdownFormatter then return countdownFormatter end
    if not C_StringUtil or not C_StringUtil.CreateNumericRuleFormatter
        or not Enum or not Enum.NumericRuleFormatRounding then return end
    local formatter=Safe(C_StringUtil.CreateNumericRuleFormatter)
    if not formatter then return end
    local up=Enum.NumericRuleFormatRounding.Up
    local ok=pcall(formatter.SetBreakpoints,formatter,{
        {threshold=0,format="%d",rounding=up,step=1},
        {threshold=60,format="%d:%02d",rounding=up,step=1,
            components={{div=60},{mod=60}}},
    })
    if ok then countdownFormatter=formatter;return formatter end
end
function S.DurationTextOptions()
    return {textFormatter=S.CountdownFormatter()}
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
    return (direction=="LEFT"or direction=="RIGHT")and direction or "CENTER"
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
function S.ValidCharacter(key)
    return type(key)=="string"and #key>0 and #key<=128 and not key:find("[%c]")
end
local function CharacterNameKey()
    local name,realm=Safe(UnitFullName or UnitName,"player")
    realm=realm and realm~=""and realm or Safe(GetNormalizedRealmName or GetRealmName)
    if type(name)=="string"and name~=""and type(realm)=="string"and realm~=""then return "char:"..name.."-"..realm end
end
function S.CurrentCharacter()
    local guid=Safe(UnitGUID,"player")
    if S.ValidCharacter(guid)then return guid end
    local key=CharacterNameKey();return S.ValidCharacter(key)and key
end
function S.TalentContext()
    local count=Number(Safe(GetNumTalentGroups,false,false))or Number(Safe(GetNumSpecGroups,false,false))or 1
    local active=Number(Safe(GetActiveTalentGroup,false,false))or Number(Safe(GetActiveSpecGroup,false,false))
        or Number(Safe(C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup,false,false))or 1
    active=math.max(1,math.floor(active));count=math.max(active,math.floor(count))
    local interface=M.Compat.interface or 0
    if interface>=70000 then
        local index=Number(Safe(GetSpecialization or (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization)))
        local spec=index and Number(Safe(GetSpecializationInfo or (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo),index))
        if spec and spec>0 then return "spec:"..spec,active,count end
    end
    return "talent:"..active,active,count
end
function S.CurrentProfile()
    local character=S.CurrentCharacter();if not character then return end
    local suffix=S.TalentContext();local key=character.."#"..suffix
    return S.ValidCharacter(key)and key
end
function S.RefreshMonitorTitle(title)
    local _,active,count=S.TalentContext();local text=M:T("监控设置")
    if count==2 then text=text.." "..(active==1 and "|cffff80c0"..M:T("主天赋")or "|cff40ff80"..M:T("副天赋")).."|r"end
    title:SetText(text);title:SetJustifyH("CENTER");title:SetWordWrap(false)
end
local function CharacterDefinition(id)
    if id=="playerSkillMonitor"then
        return {api=S,list="monitors",profiles="playerSkillMonitorsByCharacter",owner="playerSkillMonitorCharacter",legacy="playerSkillMonitorsByClass",class="playerSkillMonitorClass",revision="playerSkillMonitorCharacterRevision",ensure="EnsurePlayerSkillMonitor"}
    elseif id=="playerOtherMonitor"then
        return {api=M.PlayerOtherMonitor,list="otherMonitors",profiles="playerOtherMonitorsByCharacter",owner="playerOtherMonitorCharacter",legacy="playerOtherMonitorsByClass",class="playerOtherMonitorClass",revision="playerOtherMonitorCharacterRevision",ensure="EnsurePlayerOtherMonitor"}
    end
end
local function CharacterGroup(id,design)
    for _,node in ipairs(design and design.nodes or {})do if node.id==id then return node end end
end
function S.ValidCharacterProfiles(profiles,valid)
    if type(profiles)~="table"then return false end
    local count=0
    for key,entries in pairs(profiles)do
        count=count+1;if count>512 or not S.ValidCharacter(key)or not valid(entries)then return false end
    end
    return true
end
local characterModules={"playerSkillMonitor","playerOtherMonitor"}
function S.ValidTalentKey(key)
    if type(key)~="string"or #key>48 then return false end
    local value=key:match("^talent:(%d+)$")or key:match("^spec:(%d+)$")
    return value~=nil and tonumber(value)>0 and tonumber(value)<=1000000000
end
function S.InitCharacterStore()
    local loaded=type(MangUICharacterDB)=="table"
    if type(MangUICharacterDB)~="table"then MangUICharacterDB={}end
    local root=MangUICharacterDB
    if type(root.schema)=="number"and root.schema>1 then error("角色配置由更新版本创建，请更新 MangUI；现有配置未修改。")end
    root.schema=1;if type(root.monitors)~="table"then root.monitors={}end
    if M.characterDB~=root then M.characterDB=root;S.profileBindings={};S.characterStorageLoaded=loaded end
    if not M.characterSaveEvents then
        local frame=CreateFrame("Frame");M.characterSaveEvents=frame;frame:RegisterEvent("PLAYER_LOGOUT")
        frame:SetScript("OnEvent",function()
            if not M.db then return end
            M:SavePlayerSkillMonitorClass();M:SavePlayerOtherMonitorClass()
            MangUIUFDB=S.AccountSnapshot(M.db)
        end)
    end
    return root
end
local function CharacterStore(id)
    local root=S.InitCharacterStore();local d=CharacterDefinition(id);local store=root.monitors[id]
    if type(store)~="table"then store={};root.monitors[id]=store end
    if type(store.profiles)~="table"then store.profiles={}end
    for key,entries in pairs(store.profiles)do if not S.ValidTalentKey(key)or not d.api.ValidEntries(entries)then store.profiles[key]=nil end end
    if store.template~=nil and not d.api.ValidEntries(store.template)then store.template=nil end
    return store,d
end
function S.IsProfileBound(id)
    local binding=S.profileBindings and S.profileBindings[id]
    return binding and binding.root==MangUICharacterDB and binding.character==S.CurrentCharacter()and binding.profile==S.TalentContext()
end
function S.SaveCharacter(id)
    local store,d=CharacterStore(id);local group=M.db and CharacterGroup(id,M.db.design)
    if not group or not S.IsProfileBound(id)or not d.api.ValidEntries(group[d.list])then return end
    local profile=S.TalentContext();store.profiles[profile]=M.Copy(group[d.list])
    -- Retain a migration copy until a later login confirms the new character
    -- variable was loaded from disk, including clients still using an old TOC.
    if not S.characterStorageLoaded then
        local key=S.CurrentProfile()
        local db=M.db;db[d.profiles]=type(db[d.profiles])=="table"and db[d.profiles]or {}
        db[d.profiles][key]=M.Copy(group[d.list])
    end
end
local function LegacyCharacterProfiles(id,config,store,portable)
    local d=CharacterDefinition(id);local profiles=config[d.profiles]or {};local character=S.CurrentCharacter();local fallback=CharacterNameKey()
    local identities={}
    if character then identities[character]=true end;if fallback then identities[fallback]=true end
    if portable and S.ValidCharacter(config[d.owner])then identities[config[d.owner]:match("^(.-)#")or config[d.owner]]=true end
    local consumed={}
    for key,entries in pairs(type(profiles)=="table"and profiles or {})do
        local identity,profile
        if type(key)=="string"then identity,profile=key:match("^(.-)#(.+)$")end
        if identities[key]and d.api.ValidEntries(entries)then store.template=M.Copy(entries);consumed[#consumed+1]=key
        elseif identity and identities[identity]and S.ValidTalentKey(profile)and d.api.ValidEntries(entries)then
            store.profiles[profile]=M.Copy(entries);consumed[#consumed+1]=key
        end
    end
    local owner=config[d.owner];local group=CharacterGroup(id,config.design)
    if group and d.api.ValidEntries(group[d.list])and S.ValidCharacter(owner)then
        local identity,profile=owner:match("^(.-)#(.+)$")
        if identities[owner]then store.template=M.Copy(group[d.list])
        elseif identities[identity]and S.ValidTalentKey(profile)then store.profiles[profile]=M.Copy(group[d.list])end
    end
    local class=CurrentClass();local legacy=config[d.legacy]
    local preset=CharacterGroup(id,config.moduleDefaults)
    if not store.template then
        local candidate=type(legacy)=="table"and legacy[class]
        if not candidate and group and config[d.profiles]==nil and config[d.legacy]==nil then candidate=group[d.list]end
        if not candidate and preset then candidate=preset[d.list]end
        store.template=M.Copy(d.api.ValidEntries(candidate)and candidate or {d.api.NewEntry()})
    end
    return consumed
end
function S.BindCharacter(id)
    local store,d=CharacterStore(id);local db=M.db;local group=db and CharacterGroup(id,db.design)
    local character=S.CurrentCharacter();local profile=S.TalentContext();if not group or not character then return end
    local prior=S.profileBindings[id]
    if prior and prior.root==MangUICharacterDB and prior.character==character and d.api.ValidEntries(group[d.list])then
        store.profiles[prior.profile]=M.Copy(group[d.list])
    end
    if not store.migrated then
        LegacyCharacterProfiles(id,db,store,false)
        store.migrated=true
    end
    if S.characterStorageLoaded then
        local consumed=LegacyCharacterProfiles(id,db,{profiles={}},false)
        for _,key in ipairs(consumed)do db[d.profiles][key]=nil end
    end
    group[d.list]=M.Copy(store.profiles[profile]or store.template or {d.api.NewEntry()})
    M[d.ensure](M,db.design);store.profiles[profile]=M.Copy(group[d.list])
    S.profileBindings[id]={root=MangUICharacterDB,character=character,profile=profile}
end
function S.CleanCharacterSettings(settings)
    if type(settings)~="table"then return end
    local result={}
    for id,raw in pairs(settings)do
        local d=CharacterDefinition(id);if not d or type(raw)~="table"or type(raw.profiles)~="table"then return end
        local count=0;local store={profiles={}}
        for profile,entries in pairs(raw.profiles)do
            count=count+1;if count>64 or not S.ValidTalentKey(profile)or not d.api.ValidEntries(entries)then return end
            store.profiles[profile]=M.Copy(entries)
        end
        if raw.template~=nil then if not d.api.ValidEntries(raw.template)then return end;store.template=M.Copy(raw.template)end
        for key in pairs(raw)do if key~="profiles"and key~="template"then return end end
        result[id]=store
    end
    return result
end
function S.ExportCharacterSettings()
    local result={}
    for _,id in ipairs(characterModules)do
        S.SaveCharacter(id);local store=CharacterStore(id)
        result[id]={profiles=M.Copy(store.profiles),template=store.template and M.Copy(store.template)}
    end
    return S.CleanCharacterSettings(result)
end
function S.ImportCharacter(id,config)
    local root=S.InitCharacterStore();local d=CharacterDefinition(id);local group=CharacterGroup(id,M.db.design);if not group then return end
    local store
    if config.characterMonitors and config.characterMonitors[id]then
        store=M.Copy(config.characterMonitors[id])
    else
        local existing=CharacterStore(id);store={profiles=M.Copy(existing.profiles)}
        LegacyCharacterProfiles(id,config,store,true)
        -- Old exports carry one visible list; bind that list to the receiving talent.
        store.profiles[S.TalentContext()]=M.Copy(group[d.list])
    end
    store.migrated=true;root.monitors[id]=store;S.profileBindings[id]=nil;S.BindCharacter(id)
end
function S.AccountSnapshot(db)
    local result=M.Copy(db)
    for _,id in ipairs(characterModules)do
        local d=CharacterDefinition(id);local group=CharacterGroup(id,result.design)
        if group then group[d.list]={}end
        result[d.owner]=nil;result[d.revision]=nil
    end
    return result
end
function S.CleanCharacterSharing(config,id)
    local d=CharacterDefinition(id)
    if type(config)~="table"or config.module~=id then return end
    if config.format==2 then
        if not d.api.ValidEntries(config.entries)then return end
        return {format=2,module=id,entries=M.Copy(config.entries)}
    end
    if config.format~=1 or type(config.profiles)~="table"then return end
    for token,entries in pairs(config.profiles)do if not S.ValidClass(token)or not d.api.ValidEntries(entries)then return end end
    if next(config.profiles)==nil then return end
    if config.scope=="class"then
        if not S.ValidClass(config.class)or not config.profiles[config.class]then return end
        for token in pairs(config.profiles)do if token~=config.class then return end end
    elseif config.scope~="all"or config.class~=nil then return end
    return {format=1,module=id,scope=config.scope,class=config.class,profiles=M.Copy(config.profiles)}
end
function S.ExportCharacterSharing(id)
    local d=CharacterDefinition(id);S.SaveCharacter(id);local group=M.db and CharacterGroup(id,M.db.design)
    return group and S.CleanCharacterSharing({format=2,module=id,entries=group[d.list]},id)
end
function S.ApplyCharacterSharing(id,config)
    local d=CharacterDefinition(id);local db=M.db;local group=CharacterGroup(id,db.design)
    if not S.CurrentCharacter()or not group then return false end
    S.SaveCharacter(id)
    local entries=config.format==2 and config.entries or config.profiles[config.class or CurrentClass()]
    if entries then group[d.list]=M.Copy(entries);S.SaveCharacter(id)end
    M[d.ensure](M,db.design);return true
end
function S.RefreshProfileBindings()
    local key=S.CurrentProfile();local db=M.db
    if not key or not db or (S.IsProfileBound("playerSkillMonitor")and S.IsProfileBound("playerOtherMonitor"))then return false end
    local panel=M.editor and M.editor.skillMonitorPanel
    if panel then
        panel:FinishDrag(false)
        for _,row in ipairs(panel.rows)do row.edit:ClearFocus();row.shortcutEdit:ClearFocus()end
    end
    if M.PlayerOtherMonitor.FlushEditor then M.PlayerOtherMonitor.FlushEditor()end
    M:BindPlayerSkillMonitorClass();M:BindPlayerOtherMonitorClass();M:Commit();return true
end
function M:SavePlayerSkillMonitorClass()S.SaveCharacter("playerSkillMonitor")end
function M:BindPlayerSkillMonitorClass()S.BindCharacter("playerSkillMonitor")end
function M:ImportPlayerSkillMonitorClasses(config)S.ImportCharacter("playerSkillMonitor",config)end
function M:EnsurePlayerSkillMonitor(design)
    if not design or not design.nodes then return end
    local seen={};for _,n in ipairs(design.nodes)do seen[n.id]=n end
    local group=seen.playerSkillMonitor
    local created=not group
    if not group then
        local cd=seen.cooldownMonitor
        group={id="playerSkillMonitor",label="玩家技能监控",kind="group",compound="playerSkillMonitor",scope="player",unit="player",
            x=0,y=-120,width=2,height=2,scale=cd and cd.scale or 1,scaleReference=cd and (cd.scaleReference or cd.scale) or 1,
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
    if created then S.RestorePosition(group)end
end
function M:UpgradePlayerSkillMonitorDefaults(db)
    if db.playerSkillMonitorDefaultsRevision==2 then return end
    local group=MonitorGroup(db.moduleDefaults)
    if group then
        if not (self.recordedDefaults and MonitorGroup(self.recordedDefaults))then
            group.growthDirection="CENTER";S.RestorePosition(group)
        end
        -- Repair the exact 1.0.527 default, which ignored scale and mover pivot.
        local active=MonitorGroup(db.design)
        if active and active.x==0 and active.y==-120 and S.Direction(active)=="CENTER"then S.RestorePosition(active)end
        db.playerSkillMonitorDefaultsRevision=2
    end
end
M.moduleIDs.playerSkillMonitor=true
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
function S.RestorePosition(group,reference)
    local x,y=0,-120
    if reference then
        local cx,cy=S.MoveBounds(reference);local scale=M:NodeScale(reference)
        x,y=((reference.x or 0)+cx)*scale,((reference.y or 0)+cy)*scale
    end
    local cx,cy=S.MoveBounds(group);local scale=math.max(.001,M:NodeScale(group))
    group.x,group.y=x/scale-cx,y/scale-cy
end
M:EnsurePlayerSkillMonitor(M.defaults);M:EnsurePlayerSkillMonitor(M.recordedDefaults)
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
    frame.monitorIcon=frame:CreateTexture(nil,"ARTWORK");frame.monitorIcon:SetAllPoints();frame.monitorIcon:SetDesaturated(M.Compat.interface~=16001)
    frame.monitorIcon:SetAlpha(.5)
    frame.monitorTime=frame:CreateFontString(nil,"OVERLAY");Font(frame.monitorTime)
    frame.monitorTime:SetPoint("BOTTOM",frame,"TOP",0,7)
    frame:SetIcon(frame.monitorIcon);frame:SetDurationText(frame.monitorTime,S.DurationTextOptions())
    frame.monitorCount=frame:CreateFontString(nil,"OVERLAY");CountFont(frame.monitorCount)
    frame.monitorCount:SetPoint("BOTTOM",frame,"TOP",0,29);frame:SetApplicationCount(frame.monitorCount,{})
    -- The provider denies direct access to its AuraButtons once auras become
    -- secret. Our own child exposes inherited visibility as a secret boolean;
    -- pass it straight to the alpha setter without querying the AuraButton.
    frame.monitorPresence=CreateFrame("Frame",nil,frame);frame.monitorPresence:SetAllPoints();frame.monitorPresence:EnableMouse(false)
    -- Each native aura frame gates the annotation through engine alpha. This
    -- also handles private visibility without testing secret booleans in Lua.
    frame.shortcutGate=CreateFrame("Frame",nil,slot.shortcutGate or slot.shortcutFrame)
    frame.shortcutGate:SetAllPoints();frame.shortcutGate:EnableMouse(false)
    slot.shortcutGate=frame.shortcutGate;slot.shortcut:SetParent(frame.shortcutGate)
    -- Remove the colored backing while a native aura icon is present, so its
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
    local formatter=S.CountdownFormatter()
    if formatter and slot.cooldown.SetCountdownFormatter then slot.cooldown:SetCountdownFormatter(formatter)
    elseif slot.cooldown.SetCountdownAbbrevThreshold then slot.cooldown:SetCountdownAbbrevThreshold(3600)end
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
    slot.text:SetText(S.FormatCountdown(seconds))
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
                local present=Safe(frame.monitorPresence.IsVisible,frame.monitorPresence)
                if type(present)=="nil"then
                    frame.shortcutGate:SetAlpha(1);frame.baseIconGate:SetAlpha(1)
                elseif frame.shortcutGate.SetAlphaFromBoolean then
                    frame.shortcutGate:SetAlphaFromBoolean(present,0,1);frame.baseIconGate:SetAlphaFromBoolean(present,0,1)
                elseif Readable(present)then
                    frame.shortcutGate:SetAlpha(present and 0 or 1);frame.baseIconGate:SetAlpha(present and 0 or 1)
                end
            else frame.shortcutGate:SetAlpha(1);frame.baseIconGate:SetAlpha(1)end
        end
        if view.preview then
            ClearCooldown(slot.cooldown);slot.texture:SetDesaturated(i%2==1 and not(slot.entry.type=="debuff"and M.Compat.interface==16001));slot.texture:SetAlpha(i%2==1 and .5 or 1);slot.text:SetText(tostring(30-i))
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
            -- Native aura frames draw a half-opacity icon and countdown while
            -- present. The colored base icon remains visible when absent.
        else
            local active=slot.active and (not slot.expires or slot.expires>now)
            slot.texture:SetDesaturated(active==true and not(slot.entry.type=="debuff"and M.Compat.interface==16001));Remaining(slot,active and slot.expires and slot.expires-now or nil)
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
        frame.sectionRightLine=right
        return title
    end
    sharing.title=SectionTitle(sharing,"配置分享");panel.title=SectionTitle(panel,"监控设置");W.DragListHeader(panel)
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
    sharing.exportAll=W.Button(sharing,"导出配置",150,function()Flush();M:ShowConfigStringDialog("export","skillsAll")end)
    sharing.import=W.Button(sharing,"导入配置",150,function()Flush();M:ShowConfigStringDialog("import","skills")end)
    for _,button in ipairs({sharing.exportAll,sharing.import})do button:SetHoverTextColor(1,.82,0)end
    local function SkillIcon(row)
        local value=S.Input(W.InputValue(row.edit))
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
            local value=S.Input(W.InputValue(self))
            if item[field]~=value then item[field]=value;M:Commit()end
        end
        edit:SetScript("OnEditFocusGained",function(self)self.monitorOwner=row.group;self.monitorEntry=row.entry end)
        edit:SetScript("OnEditFocusLost",function(self)
            local owner,item=self.monitorOwner,self.monitorEntry;self.monitorOwner=nil;self.monitorEntry=nil;Save(self,owner,item)
        end)
        edit:SetScript("OnEnterPressed",function(self)Save(self);self:ClearFocus()end)
        edit:SetScript("OnEscapePressed",function(self)W.SetInputValue(self,(self.monitorEntry or row.entry)[field] or "");self:ClearFocus()end)
        W.NamedInput(edit,field=="value"and "spell"or nil)
        edit:HookScript("OnHide",function(self)self:ClearFocus()end)
    end
    panel.add=W.Button(panel,"添加监控",130,function()
        local group=Current();if not group or not M:CanEdit()then return end
        Flush();group.monitors[#group.monitors+1]=S.NewEntry();M:Commit()
    end)
    function panel:Refresh(group)
        S.RefreshMonitorTitle(self.title)
        if self.drag and (self.drag.group~=group or self.drag.entries~=group.monitors or self.drag.count~=#group.monitors)then self:FinishDrag(false)end
        local monitors=group and group.monitors or {};local width=e.props:GetWidth()
        sharing:SetWidth(width)
        for i,button in ipairs({sharing.exportAll,sharing.import})do
            local buttonWidth=(width-8)/2;button:SetWidth(buttonWidth)
            button:ClearAllPoints();button:SetPoint("TOPLEFT",sharing,"TOPLEFT",(i-1)*(buttonWidth+8),-24)
        end
        if self.owner~=group or self.count~=#monitors or self.width~=width then e.propertyLayoutSignature=nil end
        self.owner,self.count,self.width=group,#monitors,width
        self:SetSize(width,#monitors*88+32);property.height=self:GetHeight()
        for i,entry in ipairs(monitors)do
            local row=self.rows[i]
            if not row then
                row=CreateFrame("Frame",nil,self);row:SetHeight(84);self.rows[i]=row
                row.dragTint=row:CreateTexture(nil,"BACKGROUND");row.dragTint:SetAllPoints();row.dragTint:SetColorTexture(.2,.6,.9,.2);row.dragTint:Hide()
                DragSurface(row,row)
                row.dragHandle=CreateFrame("Button",nil,row);row.dragHandle:SetSize(100,18)
                row.dragLabel=W.Label(row.dragHandle,"",12);row.dragLabel:SetPoint("CENTER");row.dragLabel:SetJustifyH("CENTER")
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
            row.edit:SetWidth(width/3);
            if not row.edit:HasFocus()then W.SetInputValue(row.edit,entry.value)end
            if not row.shortcutEdit:HasFocus()then row.shortcutEdit:SetText(entry.shortcut or "")end
            row.showShortcut:SetChecked(entry.showShortcut~=false);row.shortcutColor:SetColor(entry.shortcutColor or {1,1,1,1})
            local shortcutEnabled=entry.showShortcut~=false
            if shortcutEnabled then row.shortcutEdit:Enable()else row.shortcutEdit:ClearFocus();row.shortcutEdit:Disable()end
            row.shortcutEdit:EnableMouse(shortcutEnabled);row.shortcutEdit:SetAlpha(shortcutEnabled and 1 or .55)
            row.shortcutEdit:SetTextColor(shortcutEnabled and 1 or .45,shortcutEnabled and 1 or .45,shortcutEnabled and 1 or .45)
            row.shortcutPlaceholder:SetShown(row.shortcutEdit:GetText()=="");SkillIcon(row)
            row.placeholder:SetShown(row.edit:GetText()=="");W.ShadeDragRow(row,i);row:Show()
        end
        for i=#monitors+1,#self.rows do self.rows[i]:Hide()end
        self.add:ClearAllPoints();self.add:SetPoint("TOPLEFT",self,"TOPLEFT",0,-#monitors*88)
    end
end
