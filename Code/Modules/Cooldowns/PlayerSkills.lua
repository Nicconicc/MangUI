local _,M=...
local S={};M.PlayerSkillMonitor=S
local samples={{type="cooldown",value="116"},{type="debuff",value="172"},{type="cooldown",value="133"}}
local auraTypes={
    buff={unit="player",filter="HELPFUL"},
    debuff={unit="target",filter="HARMFUL|PLAYER"},
    targetBuff={unit="target",filter="HELPFUL"},
    playerDebuff={unit="player",filter="HARMFUL"},
}
local auraKinds={"buff","debuff","targetBuff","playerDebuff"}
local skillNumeric={skillIconScale={.5,2,1},skillIconSpacing={0,10,4}}
local skillChecks={"skillCooldownSwipe","skillShowGCD","skillShowShortcut"}
local extraEntryFields={triggerGlow=true,maxStackGlow=true,maxStacks=true,slot=true,blizzardCategory=true}
local validBlizzardCategories={Essential=true,Utility=true,TrackedBuff=true}
local effectTypes={buffCooldown="buff",debuffCooldown="debuff"}
local function IsCombined(entry)return entry.type=="blizzard" or effectTypes[entry.type]~=nil end
local function Readable(v)return not issecretvalue or not issecretvalue(v)end
local function Number(v)return Readable(v) and type(v)=="number" and v or nil end
local function Safe(fn,...)
    if not fn then return end
    local ok,a,b,c,d,e=pcall(fn,...);if ok then return a,b,c,d,e end
end
function S.FormatCountdown(seconds)
    seconds=Number(seconds)
    return seconds and M.CooldownMonitor.RemainingText(seconds) or ""
end
local countdownFormatter
function S.CountdownFormatter()
    if countdownFormatter then return countdownFormatter end
    if not C_StringUtil or not C_StringUtil.CreateNumericRuleFormatter
        or not Enum or not Enum.NumericRuleFormatRounding then return end
    local formatter=Safe(C_StringUtil.CreateNumericRuleFormatter)
    if not formatter then return end
    local rounding=Enum.NumericRuleFormatRounding
    -- The engine selects a rule from the raw time, then rounds its display.
    -- Keep exact seconds at the upper edge of each band, as in RemainingText.
    local edge=.000001
    local ok=pcall(formatter.SetBreakpoints,formatter,{
        {threshold=0,format="|cffff0000%d|r",rounding=rounding.Up,step=1},
        {threshold=4+edge,format="|cffffa500%d|r",rounding=rounding.Down,step=1},
        {threshold=10+edge,format="%d",rounding=rounding.Down,step=1},
        {threshold=60+edge,format="%d"..M.CooldownMonitor.MinuteSuffix(),
            components={{div=60,step=1,rounding=rounding.Down}}},
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
function S.IconSize(group)
    return group and group.id=="playerSkillMonitor" and 40*(group.skillIconScale or 1) or 40
end
function S.IconPitch(group)
    return S.IconSize(group)+(group and group.id=="playerSkillMonitor" and (group.skillIconSpacing or 4) or 4)
end
function S.RowOffset(group,count)
    local extent=math.max(0,count-1)*S.IconPitch(group)/2;local direction=S.Direction(group)
    return direction=="LEFT"and -extent or (direction=="CENTER"and 0 or extent)
end
function S.IconOffset(group,index,count)
    local direction=S.Direction(group)
    local pitch=S.IconPitch(group)
    if direction=="LEFT"then return -(index-1)*pitch end
    return (direction=="CENTER"and -(count-1)*pitch/2 or 0)+(index-1)*pitch
end
function S.ValidEntries(entries)
    if type(entries)~="table" then return false end
    for key,entry in pairs(entries) do
        if type(key)~="number" or key%1~=0 or key<1 or key>#entries or type(entry)~="table" then return false end
        if entry.type~="cooldown" and entry.type~="usable" and entry.type~="stance" and entry.type~="equipment" and not auraTypes[entry.type] and entry.type~="custom" and not IsCombined(entry)then return false end
        if not M.CustomMonitor.Valid(entry)then return false end
        if type(entry.value)~="string" or #entry.value>384 then return false end
        if entry.effect~=nil and (type(entry.effect)~="string" or #entry.effect>384)then return false end
        if entry.blizzardCategory~=nil and not validBlizzardCategories[entry.blizzardCategory]then return false end
        local cooldownID=entry.blizzardCooldownID
        if cooldownID~=nil and (type(cooldownID)~="number" or cooldownID<=0 or cooldownID>2147483647 or cooldownID%1~=0)then return false end
        if entry.showShortcut~=nil and type(entry.showShortcut)~="boolean" then return false end
        if entry.reverseDisplay~=nil and type(entry.reverseDisplay)~="boolean" then return false end
        if entry.shortcut~=nil and (type(entry.shortcut)~="string" or #entry.shortcut>128) then return false end
        if entry.shortcutColor~=nil then
            if type(entry.shortcutColor)~="table" then return false end
            for i=1,4 do
                local v=entry.shortcutColor[i]
                if type(v)~="number" or v~=v or v<0 or v>1 then return false end
            end
            for k in pairs(entry.shortcutColor)do if type(k)~="number" or k%1~=0 or k<1 or k>4 then return false end end
        end
        for _,key in ipairs({"triggerGlow","maxStackGlow"})do
            if entry[key]~=nil and type(entry[key])~="boolean" then return false end
        end
        if entry.maxStacks~=nil and (type(entry.maxStacks)~="number" or entry.maxStacks%1~=0 or entry.maxStacks<0 or entry.maxStacks>999)then return false end
        if entry.slot~=nil and (type(entry.slot)~="number" or entry.slot%1~=0 or entry.slot<1 or entry.slot>19)then return false end
        for field in pairs(entry)do
            if field~="type" and field~="value" and field~="showShortcut" and field~="shortcut" and field~="shortcutColor"
                and field~="reverseDisplay" and field~="effect" and field~="blizzardCooldownID" and not extraEntryFields[field] and not M.CustomMonitor.fields[field]then return false end
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
        if spec and spec>0 then
            -- The active config is the working spec tree, not the saved loadout.
            local saved=interface>=100000 and Number(Safe(C_ClassTalents and C_ClassTalents.GetLastSelectedSavedConfigID,spec))
            if saved and saved>0 and saved<=1000000000 and saved%1==0 then
                return "spec:"..spec..":loadout:"..saved,active,count,saved
            end
            return "spec:"..spec,active,count
        end
    end
    return "talent:"..active,active,count
end
function S.CurrentProfile()
    local character=S.CurrentCharacter();if not character then return end
    local suffix=S.TalentContext();local key=character.."#"..suffix
    return S.ValidCharacter(key)and key
end
function S.RefreshMonitorTitle(title)
    local _,active,count,loadout=S.TalentContext();local text=M:T("监控设置")
    if loadout then
        local info=Safe(C_Traits and C_Traits.GetConfigInfo,loadout)
        if type(info)=="table"and type(info.name)=="string"and info.name~=""then text=text.." · "..info.name end
    elseif count==2 then text=text.." "..(active==1 and "|cffff80c0"..M:T("主天赋")or "|cff40ff80"..M:T("副天赋")).."|r"end
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
    local spec,loadout=key:match("^spec:(%d+):loadout:(%d+)$")
    if spec then return tonumber(spec)>0 and tonumber(spec)<=1000000000 and tonumber(loadout)>0 and tonumber(loadout)<=1000000000 end
    local value=key:match("^talent:(%d+)$")or key:match("^spec:(%d+)$")
    return value~=nil and tonumber(value)>0 and tonumber(value)<=1000000000
end
local function SameCharacter(owner,character,name,class)
    if not S.ValidCharacter(owner.character)then return false end
    if owner.class and class and owner.class~=class then return false end
    if owner.character==character then return true end
    -- A GUID may be unavailable during early login. Only use the name alias
    -- when at least one identity is a fallback; two different GUIDs never match.
    return (owner.character:sub(1,5)=="char:"or character:sub(1,5)=="char:")
        and name~=nil and owner.name==name
end
local function GuardCharacterStore(root)
    local character=S.CurrentCharacter();if not character then return end
    local name,class=CharacterNameKey(),CurrentClass()
    local owner=root.owner
    local same=type(owner)=="table"and SameCharacter(owner,character,name,class)
    if type(owner)=="table"and not same then
        -- Preserve the foreign lists in the character file, but never bind or
        -- save the visible account layout over them on this character.
        if type(root.quarantinedMonitors)~="table"then root.quarantinedMonitors={}end
        root.quarantinedMonitors[#root.quarantinedMonitors+1]={owner=M.Copy(owner),monitors=M.Copy(root.monitors),designModes=M.Copy(root.designModes)}
        root.monitors={}
        root.attackVoiceID=nil;root.designModes=nil;root.designModesSeeded=nil
        for _,id in ipairs(characterModules)do
            root.monitors[id]={migrated=true,profiles={},template={}}
        end
        S.profileBindings={}
        if M.Print then M:Print("监控存档所属角色或职业不匹配，原列表已隔离保留。请为当前角色重新配置或使用配置导入。")end
    end
    -- Untagged legacy files are claimed without guessing their spell class or
    -- replacing existing lists. Explicit imports remain the portable path.
    if same and character:sub(1,5)=="char:"and owner.character:sub(1,5)~="char:"then
        owner.name=name or owner.name;owner.class=class or owner.class
    else
        root.owner={character=character,name=name or(same and owner.name or nil),class=class or(same and owner.class or nil)}
    end
end
function S.InitCharacterStore()
    local loaded=type(MangUICharacterDB)=="table"
    if type(MangUICharacterDB)~="table"then MangUICharacterDB={}end
    local root=MangUICharacterDB
    if type(root.schema)=="number"and root.schema>3 then error("角色配置由更新版本创建，请更新 MangUI；现有配置未修改。")end
    root.schema=3
    if M.characterDB~=root then M.characterDB=root;S.profileBindings={};S.characterStorageLoaded=loaded end
    GuardCharacterStore(root)
    M.DisplayModes.CharacterProfile(root)
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
local function CharacterStore(id,mode)
    local root=M.DisplayModes.CharacterProfile(S.InitCharacterStore(),mode)
    local d=CharacterDefinition(id);local store=root.monitors[id]
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
    if not store.template then
        local candidate=type(legacy)=="table"and legacy[class]
        local owned=identities[owner]or (type(owner)=="string"and identities[owner:match("^(.-)#")])
        if not candidate and group and config[d.profiles]==nil and config[d.legacy]==nil
            and (portable or owned or (owner==nil and config[d.class]==class and class~=nil))then candidate=group[d.list]end
        -- Account-wide module reset presets have no character ownership.
        -- Never seed a new character from another character's reset list.
        store.template=M.Copy(d.api.ValidEntries(candidate)and candidate or {d.api.NewEntry()})
    end
    return consumed
end
local function IsStarterList(entries)
    if not entries or #entries==0 then return true end
    local entry=entries and #entries==1 and entries[1]
    if not entry or entry.type~="cooldown" or entry.value~="" or (entry.shortcut or "")~=""
        or entry.reverseDisplay or entry.showShortcut==false or entry.effect or entry.blizzardCooldownID then return false end
    local color=entry.shortcutColor
    return not color or (color[1]==1 and color[2]==1 and color[3]==1 and color[4]==1)
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
    -- Keep the previous spec-wide list frozen as the seed for every loadout.
    local specProfile=profile:match("^(spec:%d+):loadout:%d+$")
    group[d.list]=M.Copy(store.profiles[profile]or (specProfile and store.profiles[specProfile])or store.template or {d.api.NewEntry()})
    M[d.ensure](M,db.design);store.profiles[profile]=M.Copy(group[d.list])
    S.profileBindings[id]={root=MangUICharacterDB,character=character,profile=profile}
end
function S.BlizzardSyncEnabled(key)
    local store=M.characterDB and M.DisplayModes.CharacterProfile(M.characterDB).monitors.playerSkillMonitor
    if not key then
        for _,category in ipairs(S.BlizzardCategories or {})do
            if S.BlizzardSyncEnabled(category.key)then return true end
        end
        return false
    end
    local value=store and type(store.blizzardSyncCategories)=="table" and store.blizzardSyncCategories[key]
    if type(value)=="boolean" then return value end
    return key=="Essential" and (not store or store.useBlizzardCooldownManager~=false)
end
local observed,requestedSync={},{}
function S.SetBlizzardSyncEnabled(enabled,key)
    if M.Compat.interface~=16001 or not S.IsProfileBound("playerSkillMonitor") or not M:CanEdit() then return end
    key=key or "Essential"
    if not validBlizzardCategories[key]then return end
    local store=CharacterStore("playerSkillMonitor")
    if type(store.blizzardSyncCategories)~="table"then store.blizzardSyncCategories={} end
    store.blizzardSyncCategories[key]=enabled==true
    observed[key]=nil
    local mode=M.DisplayModes.Minimal() and "minimal:" or "standard:"
    local profile=S.CurrentProfile()
    requestedSync[key]=enabled and profile and mode..profile or nil
    if enabled then S.QueueBlizzardSync()end
end

local function NeedsBlizzardStarter(store,group)
    if store.blizzardStarterImported or not IsStarterList(group.monitors)
        or not IsStarterList(store.template) then return false end
    for _,entries in pairs(store.profiles) do
        if not IsStarterList(entries) then return false end
    end
    return true
end

local observingBlizzard,blizzardSyncTimer,blizzardSyncAfterCombat
local BLIZZARD_SYNC_FAST_RETRIES=4
local BLIZZARD_STARTER_RETRIES=12
local function ObserveBlizzardCooldowns()
    if not M.db or not S.IsProfileBound("playerSkillMonitor")then return false,false end
    local profile=S.CurrentProfile()
    if profile then profile=(M.DisplayModes.Minimal() and "minimal:" or "standard:")..profile end
    local group=CharacterGroup("playerSkillMonitor",M.db.design)
    if not group or not profile then return false,false end
    local store=CharacterStore("playerSkillMonitor")
    local ready,waitingForStarter=true,false
    for _,category in ipairs(S.BlizzardCategories or {})do
        local key=category.key
        if S.BlizzardSyncEnabled(key)then
            local starter=key=="Essential" and NeedsBlizzardStarter(store,group)
            local desired=Safe(S.ReadBlizzardCooldowns,key)
            if not desired or (starter and #desired==0)then
                ready=false;waitingForStarter=waitingForStarter or starter
            else
                local signature={}
                for i,entry in ipairs(desired)do signature[i]=entry.blizzardCooldownID..":"..entry.value end
                signature=table.concat(signature,",")
                local last=observed[key]
                local changed=last and (profile~=last.profile or signature~=last.signature)
                if changed or starter or requestedSync[key]==profile or (not last and key~="Essential") then
                    local synced,imported=Safe(S.SyncBlizzardCooldowns,group,desired,key)
                    if not synced or (starter and not imported)then return false,starter end
                    if starter then
                        store.blizzardStarterImported=true
                        store.blizzardStarterPending=nil
                    end
                end
                requestedSync[key]=nil
                observed[key]={profile=profile,signature=signature}
            end
        end
    end
    return ready,waitingForStarter
end

function S.QueueBlizzardSync(attempt)
    if not observingBlizzard or not S.BlizzardSyncEnabled() or blizzardSyncTimer then return end
    if InCombatLockdown() then blizzardSyncAfterCombat=true;return end
    if not C_Timer or not C_Timer.After then return end
    attempt=attempt or 0
    local delay=attempt==0 and .25 or (attempt<=BLIZZARD_SYNC_FAST_RETRIES and .4 or 2)
    blizzardSyncTimer=true
    C_Timer.After(delay,function()
        blizzardSyncTimer=nil
        if not S.BlizzardSyncEnabled() then return end
        if InCombatLockdown() then blizzardSyncAfterCombat=true;return end
        local ready,waitingForStarter=ObserveBlizzardCooldowns()
        local retryLimit=waitingForStarter and BLIZZARD_STARTER_RETRIES or BLIZZARD_SYNC_FAST_RETRIES
        if not ready and attempt<retryLimit then S.QueueBlizzardSync(attempt+1) end
    end)
end

local function WatchBlizzardLayoutChanges()
    local elapsed,wasOpen=0,false
    local watcher=CreateFrame("Frame")
    watcher:SetScript("OnUpdate",function(_,delta)
        elapsed=elapsed+delta
        if elapsed<.5 then return end
        elapsed=0
        if not S.BlizzardSyncEnabled()then wasOpen=false;return end
        local settings=CooldownViewerSettings
        local open=settings and M.Compat.Bool(Safe(settings.IsShown,settings))
        -- Observe from our own frame, never from a Blizzard layout callback.
        if open or wasOpen then S.QueueBlizzardSync()end
        wasOpen=open
    end)
end

local function ObserveBlizzardEvent(event,unit)
    if M.Compat.interface~=16001 then return end
    if event=="PLAYER_ENTERING_WORLD" and not observingBlizzard then
        observingBlizzard=true
        WatchBlizzardLayoutChanges()
        S.QueueBlizzardSync()
    elseif event=="PLAYER_REGEN_ENABLED" then
        if blizzardSyncAfterCombat then blizzardSyncAfterCombat=nil;S.QueueBlizzardSync()end
    elseif event=="SPELLS_CHANGED" or event=="LEARNED_SPELL_IN_TAB" or event=="ACTIVE_TALENT_GROUP_CHANGED"
        or event=="PLAYER_TALENT_UPDATE" or (event=="PLAYER_SPECIALIZATION_CHANGED" and (not unit or unit=="player"))
        or event=="TRAIT_CONFIG_UPDATED" or event=="ACTIVE_COMBAT_CONFIG_CHANGED" or event=="ACTIVE_PLAYER_SPECIALIZATION_CHANGED"
        or event=="COOLDOWN_VIEWER_DATA_LOADED" or event=="COOLDOWN_VIEWER_TABLE_HOTFIXED" or event=="COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED" then
        S.QueueBlizzardSync()
    end
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
        if raw.useBlizzardCooldownManager~=nil then
            if id~="playerSkillMonitor" or type(raw.useBlizzardCooldownManager)~="boolean" then return end
            store.useBlizzardCooldownManager=raw.useBlizzardCooldownManager
        end
        if raw.blizzardSyncCategories~=nil then
            if id~="playerSkillMonitor" or type(raw.blizzardSyncCategories)~="table"then return end
            for key,enabled in pairs(raw.blizzardSyncCategories)do
                if not validBlizzardCategories[key] or type(enabled)~="boolean" then return end
            end
            store.blizzardSyncCategories=M.Copy(raw.blizzardSyncCategories)
        end
        for key in pairs(raw)do
            if key~="profiles" and key~="template" and key~="useBlizzardCooldownManager" and key~="blizzardSyncCategories" then return end
        end
        result[id]=store
    end
    return result
end
function S.ExportCharacterSettings(mode)
    local result={}
    for _,id in ipairs(characterModules)do
        if not mode then S.SaveCharacter(id) end
        local store=CharacterStore(id,mode)
        result[id]={profiles=M.Copy(store.profiles),template=store.template and M.Copy(store.template),
            useBlizzardCooldownManager=store.useBlizzardCooldownManager,blizzardSyncCategories=store.blizzardSyncCategories}
    end
    return S.CleanCharacterSettings(result)
end
function S.FillInactiveCharacterLists(design,mode)
    for _,id in ipairs(characterModules) do
        local store,d=CharacterStore(id,mode)
        local group=CharacterGroup(id,design)
        if group then
            local profile=S.TalentContext()
            local spec=profile:match("^(spec:%d+):loadout:%d+$")
            group[d.list]=M.Copy(store.profiles[profile] or (spec and store.profiles[spec]) or store.template or group[d.list])
        end
    end
end
function S.ImportCharacter(id,config,mode)
    local root=M.DisplayModes.CharacterProfile(S.InitCharacterStore(),mode)
    local d=CharacterDefinition(id);local group=CharacterGroup(id,mode and config.design or M.db.design);if not group then return end
    local store
    if config.characterMonitors and config.characterMonitors[id]then
        store=M.Copy(config.characterMonitors[id])
        local profile=S.TalentContext()
        -- Saved loadout IDs differ between characters. Apply the exported visible
        -- list to an unknown receiving loadout and retain the other saved lists.
        if profile:find(":loadout:",1,true)and not store.profiles[profile]and d.api.ValidEntries(group[d.list])then
            store.profiles[profile]=M.Copy(group[d.list])
        end
    else
        local existing=CharacterStore(id,mode);store={profiles=M.Copy(existing.profiles)}
        LegacyCharacterProfiles(id,config,store,true)
        -- Old exports carry one visible list; bind that list to the receiving talent.
        store.profiles[S.TalentContext()]=M.Copy(group[d.list])
    end
    store.migrated=true;root.monitors[id]=store
    if not mode then S.profileBindings[id]=nil;S.BindCharacter(id) end
end
function S.ImportInactiveCharacterSettings(config,mode)
    for _,id in ipairs(characterModules) do S.ImportCharacter(id,config,mode) end
end
function S.AccountSnapshot(db)
    local result=M.Copy(db)
    for _,id in ipairs(characterModules)do
        local d=CharacterDefinition(id);local group=CharacterGroup(id,result.design)
        if group then group[d.list]={}end
        if result.inactiveDesign then
            local inactive=CharacterGroup(id,result.inactiveDesign.design)
            if inactive then inactive[d.list]={} end
            result.inactiveDesign[d.owner]=nil;result.inactiveDesign[d.revision]=nil
        end
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
    local entries=config.format==2 and config.entries or config.profiles[config.class or CurrentClass()]
    if not entries then return false,"旧版配置中没有当前职业的监控列表，未导入。"end
    S.SaveCharacter(id)
    group[d.list]=M.Copy(entries);S.SaveCharacter(id)
    M[d.ensure](M,db.design);return true
end
function S.RefreshProfileBindings()
    local key=S.CurrentProfile();local db=M.db
    if not key or not db or (S.IsProfileBound("playerSkillMonitor")and S.IsProfileBound("playerOtherMonitor"))then return false end
    local panel=M.editor and M.editor.skillMonitorPanel
    if panel and panel.edit then panel.edit:ClearFocus() end
    if M.editor then M.editor.skillEntry=nil end
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
    for key,v in pairs(skillNumeric)do group[key]=M.Clamp(tonumber(group[key]) or v[3],v[1],v[2])end
    for _,key in ipairs(skillChecks)do group[key]=group[key]~=false end
    for _,entry in ipairs(group.monitors)do
        entry.value=S.Input(entry.value);entry.shortcut=S.Input(entry.shortcut)
        if entry.type=="custom"then M.CustomMonitor.Defaults(entry)end
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
function S.Entries(group,draft)
    local result={}
    for _,entry in ipairs(group.monitors or {})do
        if entry==draft or entry.type=="custom" or entry.type=="equipment" or entry.value~="" then result[#result+1]=entry end
    end
    return result
end
function S.MoveBounds(group)
    local count=#S.Entries(group)
    if count==0 then count=#samples end -- Movement mode shows the sample row.
    return S.RowOffset(group,count),20,math.max(180,count*S.IconPitch(group)+20),math.max(112,S.IconSize(group)+72)
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
local desaturationCurves,fadeCurves={},{}
local shortcutCurve
local function DisplayCurve(curves,reversed,inactive,active)
    if not curves[reversed] and C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType then
        local curve=C_CurveUtil.CreateCurve()
        curve:SetType(Enum.LuaCurveType.Step)
        curve:AddPoint(0,reversed and active or inactive)
        curve:AddPoint(.001,reversed and inactive or active)
        curves[reversed]=curve
    end
    return curves[reversed]
end
local function ShortcutCurve()
    if not shortcutCurve and C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType then
        shortcutCurve=C_CurveUtil.CreateCurve();shortcutCurve:SetType(Enum.LuaCurveType.Step)
        shortcutCurve:AddPoint(0,1);shortcutCurve:AddPoint(.001,0)
    end
    return shortcutCurve
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
    if not Readable(value)then label.monitorTextValid=nil;label:SetFormattedText("%d",value);return end
    local count=Number(value)
    M.CustomMonitor.SetText(label,count and count>=(hideZero and 1 or 0)and (showSingle or count>1)and tostring(count)or "")
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
-- Keep the visual the same size. The aura group's right edge is one unit
-- from its origin while empty and moves off screen on a match. Only the
-- inactive artwork follows that edge; no clip or secret geometry read.
S.auraBackdropLayoutWidth=16384
function S.CreateAuraBackdrop(parent,container)
    if not C_XMLUtil.GetTemplateInfo("DisableUntrustedLayoutScriptsTemplate")then return end
    local backdrop=CreateFrame("Frame",nil,parent,"DisableUntrustedLayoutScriptsTemplate")
    backdrop:SetSize(40,40);backdrop:EnableMouse(false)
    local ok=pcall(backdrop.SetPoint,backdrop,"TOPLEFT",container,"TOPRIGHT",-1,0)
    if ok then return backdrop end
    backdrop:Hide()
end
local function StyleNativeAura(slot,frame,reversed)
    frame:SetSize(40,40);frame:EnableMouse(false);frame:EnableMouseMotion(true)
    frame:SetTooltipAnchorPoint("ANCHOR_RIGHT");frame:SetHideTooltipInCombat(false)
    local forever=slot.nativeHost~=nil
    if forever then frame:SetFrameLevel(slot.baseIconFrame:GetFrameLevel()+2)end
    frame.monitorIcon=frame:CreateTexture(nil,"ARTWORK");frame.monitorIcon:SetAllPoints();frame.monitorIcon:SetDesaturated(not reversed)
    if not reversed and forever and not slot.nativeBackdrop then
        -- The provider owns visibility. An opaque, dimmed icon covers the
        -- colored base even when the client forbids reading aura visibility.
        frame.monitorIcon:SetVertexColor(.5,.5,.5,1)
    elseif not reversed then
        frame.monitorIcon:SetAlpha(.5)
    end
    frame.monitorTime=frame:CreateFontString(nil,"OVERLAY");Font(frame.monitorTime)
    frame.monitorTime:SetPoint("BOTTOM",frame,"TOP",0,7)
    M.MasqueIcons.Attach(frame.monitorIcon,"playerSkillMonitor",40,40)
    frame:SetIcon(frame.monitorIcon);frame:SetDurationText(frame.monitorTime,S.DurationTextOptions())
    frame.monitorCount=frame:CreateFontString(nil,"OVERLAY");CountFont(frame.monitorCount)
    frame.monitorCount:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-1,1);frame:SetApplicationCount(frame.monitorCount,{})
    if forever then return end
    -- The provider denies direct access to its AuraButtons once auras become
    -- secret. Our own child exposes inherited visibility as a secret boolean;
    -- pass it straight to the alpha setter without querying the AuraButton.
    frame.monitorPresence=CreateFrame("Frame",nil,frame);frame.monitorPresence:SetAllPoints();frame.monitorPresence:EnableMouse(false)
    -- Each native aura frame gates the annotation through engine alpha. This
    -- also handles private visibility without testing secret booleans in Lua.
    frame.shortcutGate=CreateFrame("Frame",nil,slot.shortcutGate or slot.shortcutFrame)
    frame.shortcutGate:SetAllPoints();frame.shortcutGate:EnableMouse(false)
    slot.shortcutGate=frame.shortcutGate
    -- Remove the colored backing while a native aura icon is present, so its
    -- half opacity is not composited over another fully opaque icon.
    frame.baseIconGate=CreateFrame("Frame",nil,slot.baseIconGate or slot.baseIconFrame)
    frame.baseIconGate:SetAllPoints();frame.baseIconGate:EnableMouse(false)
    slot.baseIconGate=frame.baseIconGate;M.MasqueIcons.Reparent(slot.texture,frame.baseIconGate)
    slot.nativeFrames[#slot.nativeFrames+1]=frame
end
local function NativeAura(slot,aura,reversed)
    local parent=slot
    if M.Compat.interface==16001 then
        slot.nativeHost=CreateFrame("Frame",nil,slot)
        slot.nativeHost:SetAllPoints()
        parent=slot.nativeHost
    end
    local container=CreateFrame("AuraContainer",nil,parent,"CustomAuraContainerTemplate")
    container:SetEnabled(false);container:SetUnit(aura.unit);container:SetPoint("TOPLEFT",slot,"TOPLEFT",0,0)
    slot.nativeFrames={};slot.nativeAuras=container
    if slot.nativeHost then
        local backdrop=S.CreateAuraBackdrop(slot.nativeHost,container)
        if backdrop then
            slot.nativeBackdrop=backdrop:CreateTexture(nil,"ARTWORK");slot.nativeBackdrop:SetAllPoints()
            slot.nativeBackdrop:SetTexture(M:TextureFile(slot.customFallbackIcon))
            slot.nativeBackdrop:SetDesaturated(reversed);slot.nativeBackdrop:SetAlpha(reversed and .5 or 1)
            M.MasqueIcons.Attach(slot.nativeBackdrop,"playerSkillMonitor",40,40)
        end
    end
    local width=slot.nativeBackdrop and S.auraBackdropLayoutWidth or 40
    container:AddAuraGroup("monitor",aura.filter,{maxFrameCount=0,initializeFrame=function(frame)StyleNativeAura(slot,frame,reversed)end})
    container:SetFlowLayoutAnchorPoint("TOPLEFT")
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right,AnchorUtil.FlowDirection.Down)
    container:SetFlowLayoutMaximumLineSize(width+.001)
    container:SetAuraGroupLayout("monitor",{elementSpacing=0,lineSpacing=0,elementWidth=width,elementHeight=40})
end
-- Native AuraButtons can become inaccessible after initialization. Keep one
-- initialized container per style and switch containers without restyling them.
local nativeVariantFields={"nativeAuras","nativeHost","nativeBackdrop","nativeFrames","nativeAuraType","shortcutGate","baseIconGate"}
local function SelectNativeAura(slot,aura)
    local reversed=slot.entry.reverseDisplay==true
    if slot.nativeAuras and slot.nativeReversed==reversed then return end
    slot.nativeVariants=slot.nativeVariants or {}
    if slot.nativeAuras then
        slot.nativeAuras:SetEnabled(false)
        if slot.nativeHost then slot.nativeHost:Hide() end
        local saved={}
        for _,key in ipairs(nativeVariantFields)do saved[key]=slot[key] end
        slot.nativeVariants[slot.nativeReversed]=saved
    end
    local saved=slot.nativeVariants[reversed]
    for _,key in ipairs(nativeVariantFields)do slot[key]=saved and saved[key] or nil end
    slot.nativeReversed=reversed
    M.MasqueIcons.Reparent(slot.texture,slot.baseIconGate or slot.baseIconFrame)
    if not slot.nativeAuras then
        NativeAura(slot,aura,reversed)
        slot.nativeAuraType=slot.entry.type
    end
    if slot.nativeHost then slot.nativeHost:Show() end
    if slot.nativeBackdrop then slot.nativeBackdrop:SetTexture(M:TextureFile(slot.customFallbackIcon))end
end
local function Icon(view,o,i)
    local slot=o.skillIcons[i];if slot then return slot end
    slot=CreateFrame("Frame",nil,o.frame);slot:SetSize(40,40);slot:EnableMouse(true)
    slot.baseIconFrame=CreateFrame("Frame",nil,slot);slot.baseIconFrame:SetAllPoints();slot.baseIconFrame:EnableMouse(false)
    slot.texture=slot.baseIconFrame:CreateTexture(nil,"ARTWORK");slot.texture:SetAllPoints()
    slot.timerGate=CreateFrame("Frame",nil,slot);slot.timerGate:SetAllPoints()
    slot.text=slot.timerGate:CreateFontString(nil,"OVERLAY");Font(slot.text);slot.text:SetPoint("BOTTOM",slot,"TOP",0,7)
    slot.countGate=CreateFrame("Frame",nil,slot);slot.countGate:SetAllPoints()
    slot.count=slot.countGate:CreateFontString(nil,"OVERLAY");CountFont(slot.count);slot.count:SetPoint("BOTTOMRIGHT",slot,"BOTTOMRIGHT",-1,1)
    slot.cooldown=CreateFrame("Cooldown",nil,slot.timerGate,"CooldownFrameTemplate");slot.cooldown:SetAllPoints();slot.cooldown:EnableMouse(false)
    slot.gcd=CreateFrame("Cooldown",nil,slot,"CooldownFrameTemplate")
    slot.gcd:SetAllPoints();slot.gcd:EnableMouse(false)
    slot.gcd:SetDrawEdge(false);slot.gcd:SetDrawBling(false);slot.gcd:SetDrawSwipe(true)
    M.CustomMonitor.SetVisual(slot.gcd,"SetHideCountdownNumbers",true);slot.gcd.noCooldownCount=true
    if slot.gcd.SetSwipeColor then slot.gcd:SetSwipeColor(0,0,0,.45)end
    slot.cooldown:SetDrawEdge(false);slot.cooldown:SetDrawBling(false);slot.cooldown:SetDrawSwipe(false)
    M.CustomMonitor.SetVisual(slot.cooldown,"SetHideCountdownNumbers",true);slot.cooldown.noCooldownCount=true
    local formatter=S.CountdownFormatter()
    if formatter and slot.cooldown.SetCountdownFormatter then slot.cooldown:SetCountdownFormatter(formatter)
    elseif slot.cooldown.SetCountdownAbbrevThreshold then slot.cooldown:SetCountdownAbbrevThreshold(60)end
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
    if not view.preview then M.MasqueIcons.Attach(slot.texture,"playerSkillMonitor",40,40) end
    o.skillIcons[i]=slot;return slot
end
local Shortcut
local learnedSpells
function S.LearnedSpell(name)
    if not name then return end
    if not learnedSpells then
        learnedSpells={}
        local function Add(id)
            id=Number(id)
            if not id or id<=0 then return end
            local spell,_,icon=M.PetBuffs.SpellInfo(id)
            if spell then learnedSpells[spell]={id,icon} end
        end
        local book=C_SpellBook
        local bank=Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
        if bank and book and book.GetSpellBookSkillLineInfo and book.GetSpellBookItemType then
            for tab=1,Number(Safe(book.GetNumSpellBookSkillLines)) or 0 do
                local line=Safe(book.GetSpellBookSkillLineInfo,tab)
                if line and (not line.offSpecID or line.offSpecID==0) then
                    for index=line.itemIndexOffset+1,line.itemIndexOffset+line.numSpellBookItems do
                        local kind,action,id=Safe(book.GetSpellBookItemType,index,bank)
                        if Enum.SpellBookItemType and kind==Enum.SpellBookItemType.Spell then Add(id or action) end
                    end
                end
            end
        elseif GetSpellBookItemInfo then
            for tab=1,Number(Safe(GetNumSpellTabs)) or 0 do
                local _,_,offset,count,_,offSpec=Safe(GetSpellTabInfo,tab)
                if offset and count and (not offSpec or offSpec==0)then
                    for index=offset+1,offset+count do
                        local kind,id=Safe(GetSpellBookItemInfo,index,BOOKTYPE_SPELL or "spell")
                        if kind=="SPELL" then Add(id) end
                    end
                end
            end
        end
    end
    local spell=learnedSpells[name]
    if spell then return spell[1],spell[2] end
    local _,id,icon=M.PetBuffs.SpellInfo(name)
    return id,icon
end
local function Resolve(slot,entry)
    local name,id,icon=M.PetBuffs.SpellInfo(entry.value)
    if entry.type=="equipment" and M.PlayerOtherMonitor then
        local _,itemName,itemIcon=M.PlayerOtherMonitor.Item(entry.slot or 13)
        name,icon=itemName,itemIcon
    end
    id=tonumber(entry.value) or id or Safe(C_Spell and C_Spell.GetSpellIDForSpellIdentifier,entry.value)
    if not Readable(id) then id=nil end
    if name and (entry.type=="cooldown" or entry.type=="usable" or effectTypes[entry.type]~=nil or auraTypes[entry.type])then
        local current,currentIcon=S.LearnedSpell(name)
        id,icon=current or id,currentIcon or icon
    end
    if slot.auraInput~=entry.value or slot.auraEntryType~=entry.type then slot.observedAuraIDs=nil end
    slot.auraInput,slot.auraEntryType=entry.value,entry.type
    slot.entry=entry;slot.spellID=id;slot.spellName=name or entry.value
    slot.auraMatchName=name or (not tonumber(entry.value) and entry.value)
    M.CustomMonitor.SetVisual(slot.texture,"SetTexture",M:TextureFile(icon or 134400));slot.customFallbackIcon=icon or 134400
    if slot.nativeBackdrop then slot.nativeBackdrop:SetTexture(M:TextureFile(slot.customFallbackIcon))end
    slot.needsInfo=entry.type~="custom"and(not id or not icon);slot.nextInfo=GetTime()+1
end
local function BindAura(slot,enabled)
    local aura=auraTypes[slot.entry.type]
    if enabled==false or not aura or not slot.spellID then
        slot.nativeSpellID=nil
        if slot.nativeAuras then slot.nativeAuras:SetEnabled(false)end
        return
    end
    SelectNativeAura(slot,aura)
    slot.nativeAuras:SetEnabled(false)
    if slot.nativeAuraType~=slot.entry.type then
        slot.nativeAuras:SetUnit(aura.unit)
        slot.nativeAuras:SetAuraGroupFilterString("monitor",aura.filter)
        slot.nativeAuraType=slot.entry.type
    end
    local ids={[slot.spellID]=true}
    local raid=M.RaidBuffMonitor
    if raid and raid.ExpandBuffRanks then
        local spell={name=slot.auraMatchName,value=slot.entry.value,id=slot.spellID}
        raid.ExpandBuffRanks(spell)
        for id in pairs(spell.ids or {})do ids[id]=true end
    end
    for id in pairs(slot.observedAuraIDs or {})do ids[id]=true end
    slot.boundAuraIDs,slot.nativeAuraDirty=ids,nil
    slot.nativeAuras:SetAuraGroupCandidateFilters("monitor",{includeSpellIDs=ids})
    slot.nativeAuras:SetAuraGroupMaxFrameCount("monitor",1)
    slot.nativeSpellID=slot.spellID
    slot.nativeAuras:SetEnabled(true);slot.nativeAuras:UpdateAllAuras()
end
local function BindEffect(slot)
    if InCombatLockdown() then return end
    local native=slot.effectNative
    local effect=slot.effect
    if native then native:SetEnabled(false)end
    if not effect or not next(effect.ids) or not NativeAurasAvailable() then return end
    if not native then
        native=CreateFrame("AuraContainer",nil,slot,"CustomAuraContainerTemplate")
        slot.effectNative=native
        native:SetEnabled(false);native:SetPoint("TOPLEFT",slot,"TOPLEFT",0,0)
        native:AddAuraGroup("effect",effect.filter,{maxFrameCount=1,initializeFrame=function(frame)
            frame:SetSize(40,40);frame:EnableMouse(false)
            frame:SetFrameLevel(slot.baseIconFrame:GetFrameLevel()+2)
            local icon=frame:CreateTexture(nil,"ARTWORK");icon:SetAllPoints()
            M.MasqueIcons.Attach(icon,"playerSkillMonitor",40,40)
            frame:SetIcon(icon)
            local timer=frame:CreateFontString(nil,"OVERLAY");Font(timer)
            timer:SetPoint("BOTTOM",frame,"TOP",0,7)
            frame:SetDurationText(timer,S.DurationTextOptions())
            local count=frame:CreateFontString(nil,"OVERLAY");CountFont(count)
            count:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-1,1);frame:SetApplicationCount(count,{})
            local presence=CreateFrame("Frame",nil,frame);presence:SetAllPoints();presence:EnableMouse(false)
            slot.effectPresence=presence
        end})
        native:SetFlowLayoutAnchorPoint("TOPLEFT")
        native:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right,AnchorUtil.FlowDirection.Down)
        native:SetFlowLayoutMaximumLineSize(40.001)
        native:SetAuraGroupLayout("effect",{elementSpacing=0,lineSpacing=0,elementWidth=40,elementHeight=40})
    end
    native:SetUnit(effect.unit)
    native:SetAuraGroupFilterString("effect",effect.filter)
    native:SetAuraGroupCandidateFilters("effect",{includeSpellIDs=effect.ids})
    native:SetEnabled(true);native:UpdateAllAuras()
end

local function ResolveEffect(slot,preview)
    local entry,id=slot.entry,slot.spellID
    slot.effect,slot.effectAura,slot.effectSpell,slot.effectGlow,slot.effectRevenge=nil,nil,nil,nil,nil
    slot.blizzardID,slot.blizzardTimer,slot.blizzardDesaturated=nil,nil,nil
    slot.effectKnown=true
    if not preview and IsCombined(entry) then
        local kind=effectTypes[entry.type]
        local ids,name={},nil
        if entry.type=="blizzard" and M.Compat.interface==16001 then
            local info=Safe(S.GetBlizzardCooldownInfo,entry,id)
            slot.effectKnown=info and Readable(info.isKnown) and info.isKnown==true or false
            if info then
                slot.effectSpell=Number(info.overrideSpellID) or Number(info.spellID)
                slot.blizzardID=Number(info.cooldownID) or entry.blizzardCooldownID
                local revengeName=M.PetBuffs.SpellInfo(6572)
                slot.effectRevenge=revengeName~=nil and slot.spellName==revengeName
                local hidden=FlagsUtil and Enum and Enum.CooldownSetSpellFlags and info.flags
                    and Safe(FlagsUtil.IsSet,info.flags,Enum.CooldownSetSpellFlags.HideAura)
                local mapped=Number(Safe(C_UnitAuras and C_UnitAuras.GetCooldownAuraBySpellID,slot.effectSpell or id))
                local lastStand=id==12975 or info.spellID==12975
                local linked=info.linkedSpellIDs or {}
                local tracked=entry.blizzardCategory=="TrackedBuff"
                if not hidden and (tracked or lastStand or info.hasAura or #linked>0 or (mapped and mapped>0))then
                    kind=(tracked or lastStand or info.selfAura) and "buff" or "debuff"
                    for _,linkedID in ipairs(linked)do if Number(linkedID)then ids[linkedID]=true end end
                    if mapped and mapped>0 then ids[mapped]=true end
                    local tooltipID=Number(info.overrideTooltipSpellID)
                    if tooltipID and tooltipID>0 then ids[tooltipID]=true end
                    if id then ids[id]=true end
                    if slot.effectSpell then ids[slot.effectSpell]=true end
                    if lastStand then ids[12976]=true end
                end
            end
        elseif kind and entry.effect and entry.effect~="" then
            local effectName,resolved=M.PetBuffs.SpellInfo(entry.effect)
            local numeric=tonumber(entry.effect)
            local effectID=numeric or Number(resolved)
            if effectID and effectID>0 then ids[effectID]=true end
            name=effectName or (not numeric and entry.effect)
            if name then
                local known=S.LearnedSpell(name)
                if known then ids[known]=true end
                local raid=M.RaidBuffMonitor
                if raid and raid.ExpandBuffRanks then
                    local spell={value=entry.effect,name=name,id=effectID}
                    raid.ExpandBuffRanks(spell)
                    for rank in pairs(spell.ids or {})do ids[rank]=true end
                end
            end
        end
        if kind and (next(ids) or name)then
            local aura=auraTypes[kind]
            slot.effect={unit=aura.unit,filter=aura.filter,ids=ids,name=name}
            if entry.type=="blizzard" then
                local other=auraTypes[kind=="buff" and "debuff" or "buff"]
                slot.effect.alternate={unit=other.unit,filter=other.filter,ids=ids}
            end
        end
    end
    slot.effectDirty=false
    slot.effectNeedsBind=slot.effect~=nil or slot.effectNative~=nil
end
-- All callers use the same deadlines, including full renderer refreshes.
-- Events only mark data dirty. An event burst can consume one refresh per lane.
function S.ResetMonitorRefresh(o)
    o.monitorDirty, o.monitorEarliest, o.monitorFallback = {}, {}, {}
end
function S.InvalidateMonitor(o, key, urgent)
    o.monitorDirty[key] = true
    if urgent then o.monitorEarliest[key] = nil end
end
function S.MonitorRefreshDue(o, key, now, fallback)
    if now < (o.monitorEarliest[key] or 0) then return false end
    if not o.monitorDirty[key] and now < (o.monitorFallback[key] or 0) then return false end
    o.monitorDirty[key] = nil
    o.monitorEarliest[key] = now + .05
    o.monitorFallback[key] = now + fallback
    return true
end
function S.TargetAuraFilter(native)
    return native and "HARMFUL" or "HARMFUL|PLAYER"
end
function S.Configure(view,o)
    o.skillIcons=o.skillIcons or {};o.nativeTargetGeneration=nil
    S.ResetMonitorRefresh(o)
    o.skillKinds={}
    o.skillDirection=nil
    local group=view.byID[o.spec.parent]
    o.skillEditorPreview=view.preview and view.previewScope=="playerSkillMonitor"
    local draft=o.skillEditorPreview and M.editor and M.editor.skillEntry
    o.entries=S.Entries(group,draft);o.usesNativeAuras=not view.preview and NativeAurasAvailable()
    for i,entry in ipairs(o.entries)do
        o.skillKinds[entry.type]=true
        local slot=Icon(view,o,i);Resolve(slot,entry);slot.duration=nil;slot.expires=nil;slot.active=false;slot.stacks=nil
        slot.texture:SetVertexColor(1,1,1)
        slot:SetScale(S.IconSize(group)/40)
        slot.rowX=nil;slot.sweepStart=nil;slot.maxCharges=nil;slot.auraDuration=nil;slot.item=nil
        slot.cooldown:SetDrawSwipe(group.skillCooldownSwipe~=false)
        ClearCooldown(slot.gcd)
        slot.gcdStart=nil;slot.gcd.monitorStart=nil;slot.cooldown.monitorStart=nil
        ResolveEffect(slot,view.preview)
        if not view.preview and (slot.effect or slot.effectNative) and not InCombatLockdown()then
            BindEffect(slot);slot.effectNeedsBind=false
        end
        slot.timerGate:SetAlpha(1);slot.cooldown:SetAlpha(1)
        if slot.effectNative then slot.effectNative:SetAlpha(0)end
        slot.spellCount=nil;slot.countGate:SetAlpha(1)
        CountFont(slot.count);M.CustomMonitor.SetText(slot.count,"")
        M.CustomMonitor.SetText(slot.text,"");ClearCooldown(slot.cooldown);M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",false)
        Font(slot.text)
        Shortcut(slot,group)
        if slot.nativeTime then Font(slot.nativeTime)end
        for _,frame in ipairs(slot.nativeFrames or {})do Font(frame.monitorTime);CountFont(frame.monitorCount)end
        if o.usesNativeAuras then BindAura(slot,view.byID[o.spec.parent].enabled~=false)end
    end
    for i=#o.entries+1,#o.skillIcons do
        local slot=o.skillIcons[i];slot:Hide();slot.entry=nil
        if slot.nativeAuras then slot.nativeAuras:SetEnabled(false)end
        if slot.effectNative and not InCombatLockdown()then slot.effectNative:SetEnabled(false)end
    end
    M.CustomMonitor.Sync(view,o,o.skillIcons,S.Paint)
end
local function Remaining(slot,seconds)
    M.CustomMonitor.SetText(slot.text,S.FormatCountdown(seconds))
end
local function SpellCharges(key)
    if C_Spell and C_Spell.GetSpellCharges then
        local info=Safe(C_Spell.GetSpellCharges,key)
        if info then return info.currentCharges,info.maxCharges,info.cooldownStartTime,info.cooldownDuration,info.chargeModRate end
    else return Safe(GetSpellCharges,key)end
end
local function SpellCount(slot,key,charges,maximum)
    local summons=S.SummonCount(slot)
    if not Readable(summons) or (Number(summons) and summons>0) then return summons end
    if summons~=nil then return end
    if Number(maximum) and maximum>1 then return charges end

    -- Prefer the client's display-ready value when charge data is restricted.
    if not Number(maximum) then
        local display=Safe(C_Spell and C_Spell.GetSpellDisplayCount,key)
        if not Readable(display) then return display end
        if type(display)=="string" and display~="" and display~="0" then return display end
        if not Readable(charges) or Number(charges) then return charges end
    end
    local castCount=C_Spell and C_Spell.GetSpellCastCount
    local count
    if castCount then count=Safe(castCount,key)
    else count=Safe(GetSpellCount,slot.spellName or key) end
    if Number(count) and count>0 then return count end
end
local function SetCount(slot,value)
    if type(value)=="number" then CountText(slot.count,value,true)
    elseif type(value)=="string" then M.CustomMonitor.SetText(slot.count,value)
    else M.CustomMonitor.SetText(slot.count,"") end
end
local function SpellCooldown(key)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info=Safe(C_Spell.GetSpellCooldown,key)
        if info then return info.startTime,info.duration,info.isEnabled,info.modRate,info.isOnGCD end
    else return Safe(GetSpellCooldown,key)end
end
local function CachedSpellCooldown(cache,key)
    local values=cache[key]
    if not values then values={SpellCooldown(key)};cache[key]=values end
    return values[1],values[2],values[3],values[4],values[5]
end
local function GlobalCooldown(start,duration,cache)
    local gs,gd=CachedSpellCooldown(cache,M.Compat.interface==16001 and 29515 or 61304)
    return Number(gs) and Number(gd) and math.abs(gs-start)<.001 and math.abs(gd-duration)<.001
end
local function Cooldown(entry,slot,cache)
    local key=slot.effectSpell or slot.spellID or entry.value
    if not slot.effectSpell and slot.spellID then
        local override=Number(Safe(C_Spell and C_Spell.GetOverrideSpell or FindSpellOverrideByID,slot.spellID))
        if override and override>0 then key=override end
    end
    local charges,maximum,chargeStart,chargeDuration,chargeRate=SpellCharges(key)
    slot.spellCount=SpellCount(slot,key,charges,maximum)
    slot.maxCharges=Number(maximum)
    if C_Spell and C_Spell.GetSpellCooldownDuration then
        local duration=Safe(C_Spell.GetSpellChargeDuration,key) or Safe(C_Spell.GetSpellCooldownDuration,key,true)
        if duration and slot.cooldown.SetCooldownFromDurationObject then
            slot.duration=duration;slot.expires=nil;M.CustomMonitor.SetText(slot.text,"")
            slot.cooldown:SetCooldownFromDurationObject(duration,true);return
        end
    end
    if slot.duration then ClearCooldown(slot.cooldown);slot.cooldown.monitorStart=nil end
    slot.duration=nil;slot.sweepStart=nil
    local start,duration,enabled,rate,onGCD=CachedSpellCooldown(cache,key)
    if Readable(onGCD) and onGCD==true then slot.active=false;slot.expires=nil;return end
    if Number(charges) and Number(maximum) and charges<maximum and Number(chargeStart) and Number(chargeDuration) then
        start,duration,rate=chargeStart,chargeDuration,chargeRate
    end
    start,duration,rate=Number(start),Number(duration),Number(rate) or 1
    local disabled=Readable(enabled) and (enabled==false or enabled==0)
    if start and duration and rate>0 and not disabled then
        slot.expires=duration>0 and not GlobalCooldown(start,duration,cache) and start+duration/rate or nil
    else slot.expires=nil end
    slot.active=slot.expires~=nil and slot.expires>GetTime()
    if slot.active then slot.sweepStart,slot.sweepDuration,slot.sweepRate=start,duration,rate end
end
local activationEvents={}
local function HasSpellActivation(id)
    local query=C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed or IsSpellOverlayed
    local active=Safe(query,id)
    if Readable(active) and type(active)=="boolean" then return active end
    return activationEvents[id]==true
end
local legacyActionSlots
local function SpellActionSlots(id)
    local find=C_ActionBar and C_ActionBar.FindSpellActionButtons
    if find then
        local slots=Safe(find,id)
        if Readable(slots) and type(slots)=="table" and (not canaccesstable or canaccesstable(slots)) then return slots end
        return
    end
    if not legacyActionSlots then
        legacyActionSlots={}
        for slot=1,180 do
            local kind,spellID=Safe(GetActionInfo,slot)
            if Readable(kind) and kind=="spell" and Number(spellID) then
                local slots=legacyActionSlots[spellID] or {}
                slots[#slots+1]=slot;legacyActionSlots[spellID]=slots
            end
        end
    end
    return legacyActionSlots[id]
end
local bindingsBySlot,bindingRevision
local actionBars={
    {"ActionButton","ACTIONBUTTON",12},
    {"MultiBarBottomLeftButton","MULTIACTIONBAR1BUTTON",12},
    {"MultiBarBottomRightButton","MULTIACTIONBAR2BUTTON",12},
    {"MultiBarRightButton","MULTIACTIONBAR3BUTTON",12},
    {"MultiBarLeftButton","MULTIACTIONBAR4BUTTON",12},
    {"MultiBar5Button","MULTIACTIONBAR5BUTTON",12},
    {"MultiBar6Button","MULTIACTIONBAR6BUTTON",12},
    {"MultiBar7Button","MULTIACTIONBAR7BUTTON",12},
    {"BT4Button","CLICK BT4Button",180},
}
local function ActionBindings()
    if bindingsBySlot and bindingRevision==S.bindingRevision then return bindingsBySlot end
    bindingsBySlot={};bindingRevision=S.bindingRevision
    for _,bar in ipairs(actionBars)do
        for i=1,bar[3]do
            local button=_G[bar[1]..i]
            if button then
                local slot=Number(button.action)
                    or Number(Safe(button.GetAttribute,button,"action"))
                    or Number(Safe(ActionButton_GetPagedID,button))
                local command=bar[2]..i
                if bar[1]=="BT4Button" then command=command..":LeftButton" end
                local key=Safe(GetBindingKey,command)
                if Readable(key) and type(key)=="string" and slot then
                    local visible=M.Compat.Bool(Safe(button.IsVisible,button))
                    local existing=bindingsBySlot[slot]
                    if not existing or (visible and not existing.visible) then
                        local label=Safe(GetBindingText,key,"KEY_",true)
                        bindingsBySlot[slot]={key=Readable(label) and type(label)=="string" and label~="" and label or key,visible=visible}
                    end
                end
            end
        end
    end
    return bindingsBySlot
end
Shortcut=function(slot,group)
    slot.bindingRevision=S.bindingRevision
    local binding
    if group.skillShowShortcut~=false and slot.spellID then
        local keys=ActionBindings()
        local function Find(id)
            for _,index in ipairs(SpellActionSlots(id) or {})do
                local candidate=Number(index) and keys[index]
                if candidate and (not binding or (candidate.visible and not binding.visible)) then binding=candidate end
            end
        end
        Find(slot.spellID)
        local override=Number(Safe(C_Spell and C_Spell.GetOverrideSpell or FindSpellOverrideByID,slot.spellID))
        if override and override>0 and override~=slot.spellID then Find(override)end
    end
    slot.shortcut:SetFont(M:EffectiveFontPath(M.MYRIAD),20,"OUTLINE")
    slot.shortcut:SetTextColor(1,1,1,1)
    slot.shortcut:SetText(binding and binding.key:gsub("|","||") or "")
    slot.shortcut:SetShown(binding~=nil)
end

local function IsSpellActionUsable(id)
    local slots=SpellActionSlots(id)
    local query=C_ActionBar and C_ActionBar.IsUsableAction or IsUsableAction
    for _,slot in ipairs(slots or {})do
        if Number(slot) then
            local usable=Safe(query,slot)
            if Readable(usable) and usable==true then return true end
        end
    end
    return false
end
local function Usable(slot,now,cache)
    slot.usableReady=false;slot.usableCooldown=nil;slot.spellCount=nil;slot.maxCharges=nil
    local id=slot.spellID
    if not id then return end
    local override=Number(Safe(C_Spell and C_Spell.GetOverrideSpell or FindSpellOverrideByID,id))
    local key=override and override>0 and override or id
    local charges,maximum=SpellCharges(key)
    slot.maxCharges=Number(maximum)
    slot.spellCount=SpellCount(slot,key,charges,maximum)
    if M.Compat.interface==16001 then
        local base=Number(Safe(C_Spell and C_Spell.GetBaseSpell,id)) or id
        if base<=0 then base=id end
        if not IsSpellActionUsable(base) and (key==base or not IsSpellActionUsable(key)) then return end
    else
        if not HasSpellActivation(key) and (key==id or not HasSpellActivation(id)) then return end
        local usable=Safe(C_Spell and C_Spell.IsSpellUsable or IsUsableSpell,key)
        if not Readable(usable) or usable~=true then return end
    end
    if Number(maximum) and maximum>0 and Number(charges) then
        slot.usableReady=charges>0
        return
    end
    local start,duration,enabled,rate=CachedSpellCooldown(cache,key)
    if Readable(enabled) and (enabled==false or enabled==0) then return end
    start,duration,rate=Number(start),Number(duration),Number(rate) or 1
    if start and duration and rate>0 then
        slot.usableReady=duration<=0 or start+duration/rate<=now or GlobalCooldown(start,duration,cache)==true
    else
        -- The cooldown object can drive the icon without reading a secret
        -- timer or confusing recharge time with the spell's actual cooldown.
        slot.usableCooldown=Safe(C_Spell and C_Spell.GetSpellCooldownDuration,key,true)
    end
end
local function SetSwipe(timer,start,duration,rate)
    if timer.monitorStart==start and timer.monitorDuration==duration and timer.monitorRate==rate then return end
    timer.monitorStart,timer.monitorDuration,timer.monitorRate=start,duration,rate
    if start and duration and duration>0 then timer:SetCooldown(start,duration,rate or 1)
    else ClearCooldown(timer)end
end

function S.UpdateSkillSwipe(slot,group,now,effectVisible)
    local entry=slot.entry
    if not slot.duration then
        local start,duration,rate=slot.sweepStart,slot.sweepDuration,slot.sweepRate
        if slot.expires and slot.expires>now and slot.auraDuration and slot.auraDuration>0 then
            duration,rate=slot.auraDuration,1
            start=slot.expires-duration
        end
        if group.skillCooldownSwipe==false or entry.type=="custom" then start,duration,rate=nil,nil,nil end
        SetSwipe(slot.cooldown,start,duration,rate)
    end
    if group.skillShowGCD~=false and slot.gcdStart and not effectVisible then
        SetSwipe(slot.gcd,slot.gcdStart,slot.gcdDuration,slot.gcdRate)
    else SetSwipe(slot.gcd)end
end

local function ReadGCD(slot,cache)
    slot.gcdStart,slot.gcdDuration,slot.gcdRate=nil,nil,nil
    local key=slot.spellID
    if not key or slot.entry.type=="equipment" or slot.entry.type=="custom" then return end
    local start,duration,_,rate,onGCD=CachedSpellCooldown(cache,key)
    start,duration,rate=Number(start),Number(duration),Number(rate)
    if Readable(onGCD) and onGCD==true then
        local gs,gd,_,gr=CachedSpellCooldown(cache,M.Compat.interface==16001 and 29515 or 61304)
        if Number(gs) and Number(gd) then start,duration,rate=gs,gd,Number(gr)end
    elseif not (start and duration and GlobalCooldown(start,duration,cache))then return end
    if start and start>0 and duration and duration>0 then
        slot.gcdStart,slot.gcdDuration,slot.gcdRate=start,duration,rate
    end
end

local function NeedsAuraScan(o,slot)
    if slot.auraMatchName then return true end
    if not o.usesNativeAuras or not slot.nativeSpellID then return true end
    return M.Compat.interface==16001 and not slot.nativeBackdrop
end
local emptyAuraSlots={}
local function ScanAuras(o,kind)
    local auraType=auraTypes[kind]
    local debuff=kind=="debuff"
    local byID, byName = {}, {}
    for _,slot in ipairs(o.skillIcons)do
        local entry=slot.entry
        if entry and entry.type==kind then
            slot.active=false;slot.expires=nil;slot.stacks=nil;slot.auraDuration=nil
            if NeedsAuraScan(o,slot) then
                local index,key=byName,slot.auraMatchName
                if not key then index,key=byID,slot.spellID or tonumber(entry.value) end
                if key then
                    local slots=index[key]
                    if not slots then slots={};index[key]=slots end
                    slots[#slots+1]=slot
                end
            end
        end
    end
    if not next(byID) and not next(byName) then return end
    if o.usesNativeAuras and C_Secrets and M.Compat.Bool(Safe(C_Secrets.ShouldAurasBeSecret,auraType.unit)) then return end
    local filter=debuff and S.TargetAuraFilter(o.usesNativeAuras) or auraType.filter
    for _,aura in ipairs(M.Compat.AuraSnapshot(auraType.unit,filter))do
        local id=Number(aura.spellId) or Number(aura.spellID)
        local named=Readable(aura.name) and byName[aura.name]
        local numbered=id and byID[id]
        if named or numbered then
            local source=aura.sourceUnit
            local accepted=not debuff or (Readable(source) and (source=="player" or
                (source~=nil and UnitIsUnit and M.Compat.Bool(Safe(UnitIsUnit,source,"player")))))
            if accepted then
                local stacks,expires=Number(aura.applications),Number(aura.expirationTime)
                for i=1,2 do
                    local slots
                    if i==1 then slots=named else slots=numbered end
                    for _,slot in ipairs(slots or emptyAuraSlots) do
                        slot.active=true
                        if id and o.usesNativeAuras and not (slot.boundAuraIDs and slot.boundAuraIDs[id]) then
                            slot.observedAuraIDs=slot.observedAuraIDs or {}
                            slot.observedAuraIDs[id]=true;slot.nativeAuraDirty=true
                        end
                        if stacks and (not slot.stacks or stacks>slot.stacks)then slot.stacks=stacks end
                        if expires and expires>0 and (not slot.expires or expires>slot.expires)then
                            slot.expires=expires;slot.auraDuration=Number(aura.duration)
                        end
                        if Readable(aura.icon) and aura.icon~=nil then M.CustomMonitor.SetVisual(slot.texture,"SetTexture",M:TextureFile(aura.icon))end
                    end
                end
            end
        end
    end
end
local function FindEffectAura(effect,now)
    if effect.unit=="player" and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        for id in pairs(effect.ids)do
            local aura=Safe(C_UnitAuras.GetPlayerAuraBySpellID,id)
            if Readable(aura) and type(aura)=="table" and (not canaccesstable or canaccesstable(aura))then
                local expires=Number(aura.expirationTime)
                if expires and (expires==0 or expires>now) then return aura end
            end
        end
    end
    local restricted=Safe(C_Secrets and C_Secrets.ShouldAurasBeSecret,effect.unit)
    if not Readable(restricted) or restricted then return end
    local best,latest=nil,0
    for _,aura in ipairs(M.Compat.AuraSnapshot(effect.unit,effect.filter))do
        local id=Number(aura.spellId) or Number(aura.spellID)
        local sameName=effect.name and Readable(aura.name) and effect.name==aura.name
        if (id and effect.ids[id]) or sameName then
            local source=aura.sourceUnit
            local own=effect.unit~="target" or (Readable(source) and (source=="player"
                or (source and M.Compat.Bool(Safe(UnitIsUnit,source,"player")))))
            local expires=Number(aura.expirationTime)
            if own and expires and ((expires==0 and not best) or (expires>now and expires>latest)) then
                best,latest=aura,expires
            end
        end
    end
    return best
end

local function BlizzardHUDIcons()
    local byID,bySpell={},{}
    for _,name in ipairs({"EssentialCooldownViewer","UtilityCooldownViewer","BuffIconCooldownViewer"})do
        local viewer=_G[name]
        if viewer and M.Compat.Bool(Safe(viewer.IsVisible,viewer))then
            for _,frame in ipairs({viewer:GetChildren()})do
                if Readable(frame) and not M.Compat.Bool(Safe(frame.IsForbidden,frame))then
                    local id=Number(Safe(frame.GetCooldownID,frame))
                    local spell=Number(Safe(frame.GetBaseSpellID,frame))
                    if id then byID[id]=frame end
                    if spell and not bySpell[spell]then bySpell[spell]=frame end
                end
            end
        end
    end
    return byID,bySpell
end

function S.BlizzardSpellInRange(spell,base)
    local _,frames=BlizzardHUDIcons()
    local frame=frames and (frames[spell] or frames[base])
    if not frame then return end
    local check=Number(frame.rangeCheckSpellID)
    if not check or (check~=spell and check~=base) then return end
    local within=Safe(C_Spell and C_Spell.IsSpellInRange,check)
    if Readable(within) and type(within)=="boolean" then return within end
    local outside=frame.spellOutOfRange
    if Readable(outside) and outside==true then return false end
end

local function ReadBlizzardPresentation(slot,frame)
    slot.blizzardTimer,slot.blizzardDesaturated=nil,nil
    local texture=frame and Safe(frame.GetIconTexture,frame)
    local r,g,b
    if Readable(texture) and texture then
        r,g,b=Safe(texture.GetVertexColor,texture)
        local desaturated=Safe(texture.IsDesaturated,texture)
        if Readable(desaturated) and type(desaturated)=="boolean" then slot.blizzardDesaturated=desaturated end
    end
    if not Number(r) or not Number(g) or not Number(b)then
        local spell=slot.effectSpell or slot.spellID
        local usable,noPower=Safe(C_Spell and C_Spell.IsSpellUsable,spell)
        local inRange=Safe(C_Spell and C_Spell.IsSpellInRange,spell,"target")
        r,g,b=1,1,1
        if Readable(inRange) and (inRange==false or inRange==0)then r,g,b=.64,.15,.15
        elseif Readable(usable) and (usable==false or usable==0)then
            if Readable(noPower) and (noPower==true or noPower==1)then r,g,b=.5,.5,1
            elseif Readable(noPower) then r,g,b=.4,.4,.4 end
        end
    end
    slot.texture:SetVertexColor(r,g,b)

    local timer=frame and Safe(frame.GetCooldownFrame,frame)
    if not Readable(timer) or not timer then return end
    local label=Safe(timer.GetCountdownFontString,timer)
    if Readable(label) and label and M.Compat.Bool(Safe(label.IsVisible,label))then
        local text=Safe(label.GetText,label)
        if Readable(text) and type(text)=="string" and text~="" then
            local plain=text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
            local minutes,seconds=plain:match("^(%d+):(%d%d)$")
            local minuteValue=plain:match("^(%d+%.?%d*)%s*[mM]$")
            local remaining=minutes and (tonumber(minutes)*60+tonumber(seconds))
                or (minuteValue and tonumber(minuteValue)*60) or tonumber(plain)
            if minuteValue and remaining==60 then
                slot.blizzardTimer="1"..M.CooldownMonitor.MinuteSuffix()
                return
            end
            slot.blizzardTimer=remaining and S.FormatCountdown(remaining) or text
        end
    end
end

local function PaintEffect(slot,now)
    local effect,aura=slot.effect,slot.effectAura
    local expires=aura and Number(aura.expirationTime)
    local timed=expires and expires>now
    local active=expires and (expires==0 or timed)
    local stacks=active and aura.applications
    local amount=Number(stacks)
    local display=amount and amount>1 and amount or nil
    if active and not Readable(stacks) then
        local id=Number(aura.auraInstanceID)
        if id then display=Safe(C_UnitAuras and C_UnitAuras.GetAuraApplicationDisplayCount,effect.unit,id,2) end
    end
    if Readable(display) and (display==nil or display=="") then display=slot.spellCount end
    SetCount(slot,display)

    local native=slot.effectNative
    local useNative=effect and native and not active and not slot.effectNeedsBind
    if native then native:SetAlpha(useNative and 1 or 0)end
    slot.countGate:SetAlpha(1)
    slot.timerGate:SetAlpha(1)
    if slot.blizzardTimer then
        slot.cooldown:SetAlpha(0)
        M.CustomMonitor.SetText(slot.text,slot.blizzardTimer)
    else
        slot.cooldown:SetAlpha(timed and 0 or 1)
    end
    if timed and not slot.blizzardTimer then
        Remaining(slot,expires-now)
        M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",false)
        return true,true
    end
    if useNative and slot.effectPresence then
        local present=Safe(slot.effectPresence.IsVisible,slot.effectPresence)
        if type(present)=="boolean" then
            if slot.timerGate.SetAlphaFromBoolean then
                slot.timerGate:SetAlphaFromBoolean(present,0,1)
                slot.countGate:SetAlphaFromBoolean(present,0,1)
            elseif Readable(present) then
                local alpha=present and 0 or 1
                slot.timerGate:SetAlpha(alpha);slot.countGate:SetAlpha(alpha)
            end
        end
    end
    if slot.blizzardTimer then return false,true end
end

function S.Paint(view,o,animateOnly)
    local group=view.byID[o.spec.parent]
    local shown=o.spec.enabled~=false and (view.preview or group.enabled~=false) and not(view.hidden and view.hidden[o.spec.id])
    if shown and not view.preview and group.hideWithoutTarget==true then shown=M.Compat.Bool(Safe(UnitExists,"target"))end
    if o.frame:IsShown()~=shown then o.frame:SetShown(shown)end
    if not shown then return end
    local now=GetTime();local entries=o.entries or {}
    if view.preview and not o.skillEditorPreview and #entries==0 then entries=samples end
    if not view.preview then
        local kinds=o.skillKinds
        local combined=kinds.blizzard or kinds.buffCooldown or kinds.debuffCooldown
        local cooldown=(kinds.cooldown or combined) and S.MonitorRefreshDue(o,"cooldown",now,.2)
        local usable=kinds.usable and S.MonitorRefreshDue(o,"usable",now,.2)
        local info=S.MonitorRefreshDue(o,"info",now,1)
        local gcd=group.skillShowGCD~=false and S.MonitorRefreshDue(o,"gcd",now,.15)
        if cooldown or usable or info or gcd then
            local cooldowns={}
            local blizzardByID,blizzardBySpell
            if cooldown and kinds.blizzard and M.Compat.interface==16001 then
                blizzardByID,blizzardBySpell=Safe(BlizzardHUDIcons)
            end
            for i,entry in ipairs(entries)do
                local slot=o.skillIcons[i]
                if info and slot.needsInfo and now>=(slot.nextInfo or 0) then
                    Resolve(slot,entry);Shortcut(slot,group)
                    if IsCombined(entry) then slot.effectDirty=true end
                    if o.usesNativeAuras and not InCombatLockdown() then BindAura(slot,group.enabled~=false)end
                end
                if IsCombined(entry) then
                    if slot.effectDirty then
                        local known=slot.effectKnown
                        ResolveEffect(slot,false)
                        if known~=slot.effectKnown then o.skillDirection=nil end
                    end
                    if slot.effectNeedsBind and not InCombatLockdown()then
                        BindEffect(slot);slot.effectNeedsBind=false
                    end
                    if cooldown and slot.effect then
                        local effect=slot.effect
                        -- Blizzard prefers active player auras before checking the current target.
                        local first,second=effect,effect.alternate
                        if second and second.unit=="player" then first,second=second,first end
                        slot.effectAura=FindEffectAura(first,now) or (second and FindEffectAura(second,now))
                    end
                    if cooldown and entry.type=="blizzard" then
                        local id=slot.effectSpell or slot.spellID
                        local native=blizzardByID and (blizzardByID[slot.blizzardID] or blizzardBySpell[slot.spellID])
                        if M.Compat.interface==16001 then Safe(ReadBlizzardPresentation,slot,native)end
                        slot.effectGlow=slot.effectKnown and id and (HasSpellActivation(id)
                            or (id~=slot.spellID and slot.spellID and HasSpellActivation(slot.spellID))
                            or (slot.effectRevenge and IsSpellActionUsable(id)))
                    end
                end
                if cooldown and (entry.type=="cooldown" or IsCombined(entry))then Cooldown(entry,slot,cooldowns)end
                if usable and entry.type=="usable" then Usable(slot,now,cooldowns)end
                if gcd then ReadGCD(slot,cooldowns)end
            end
        end
        for _,kind in ipairs(auraKinds)do
            if kinds[kind] and S.MonitorRefreshDue(o,kind,now,1) then ScanAuras(o,kind)end
        end
        if (kinds.stance or kinds.equipment) and S.MonitorRefreshDue(o,"special",now,.25) then
            M.PlayerOtherMonitor.RefreshSkillEntries(o,now)
        end
        if o.usesNativeAuras and not InCombatLockdown()then
            for _,slot in ipairs(o.skillIcons)do
                if slot.entry and slot.nativeAuraDirty then BindAura(slot,group.enabled~=false)end
            end
        end
        local version=view.targetRefreshGeneration or 0
        if o.usesNativeAuras and o.nativeTargetGeneration~=version then
            for _,slot in ipairs(o.skillIcons)do
                if slot.nativeAuras and slot.entry and auraTypes[slot.entry.type] and auraTypes[slot.entry.type].unit=="target" then slot.nativeAuras:UpdateAllAuras()end
            end
            o.nativeTargetGeneration=version
        end
    elseif not o.skillEditorPreview and #o.entries==0 then
        for i,entry in ipairs(entries)do
            local slot=Icon(view,o,i)
            if slot.entry~=entry then Resolve(slot,entry);Shortcut(slot,group)end
            slot:SetScale(S.IconSize(group)/40)
        end
    end
    local direction=S.Direction(group)
    if view.preview or o.skillKinds.usable or o.skillDirection~=direction then
        o.skillDirection=direction
        local visibleCount=0
        for i=1,#entries do
            local slot=o.skillIcons[i]
            local alpha=1
            if not view.preview and slot.entry.type=="blizzard" and not slot.effectKnown then alpha=0 end
            if slot.entry.type=="usable" and not view.preview then
                local timer=slot.usableCooldown
                local remaining=timer and Number(Safe(timer.GetRemainingDuration,timer))
                if remaining then alpha=remaining<=0 and 1 or 0
                elseif timer and timer.EvaluateRemainingDuration and ShortcutCurve() then
                    -- A restricted timer can drive visibility through native alpha.
                    -- Keep its position when Lua cannot read the evaluated value.
                    alpha=timer:EvaluateRemainingDuration(ShortcutCurve(),0)
                else alpha=slot.usableReady and 1 or 0 end
            end
            local readable=Readable(alpha)
            slot.rowVisible=not readable or alpha==1
            if slot.rowVisible then visibleCount=visibleCount+1 end
            if slot:IsShown()~=slot.rowVisible then slot:SetShown(slot.rowVisible) end
            M.CustomMonitor.SetVisual(slot,"SetAlpha",alpha)
            M.CustomMonitor.SetVisual(slot,"EnableMouse",not view.preview and readable and slot.rowVisible)
        end
        o.rowCount=visibleCount
        local width=math.max(1,S.IconSize(group)+math.max(0,visibleCount-1)*S.IconPitch(group))
        if o.rowWidth~=width then o.frame:SetSize(width,66);o.rowWidth=width end
        local visibleIndex=0
        for i=1,#entries do
            local slot=o.skillIcons[i]
            if slot.rowVisible then
                visibleIndex=visibleIndex+1
                local x=S.IconOffset(group,visibleIndex,visibleCount)
                if slot.rowX~=x then slot:ClearAllPoints();slot:SetPoint("CENTER",o.frame,"CENTER",x/slot:GetScale(),-7/slot:GetScale());slot.rowX=x end
            end
        end
    end
    for i=1,#entries do
        local slot=o.skillIcons[i]
        local textureAlpha=1
        local useCooldownNumbers=false
        local reversed=slot.entry.reverseDisplay==true
        -- On Forever, a readable match can draw the complete faded icon even
        -- when the native button's inherited visibility is inaccessible.
        local isAura=auraTypes[slot.entry.type]~=nil
        local readableAura=not view.preview and slot.nativeHost and isAura
            and slot.active and (not slot.expires or slot.expires>now)
        local useNative=not view.preview and o.usesNativeAuras and isAura and slot.spellID~=nil
            and slot.nativeSpellID==slot.spellID and not readableAura
        if slot.nativeHost then
            M.CustomMonitor.SetVisual(slot.nativeHost,"SetAlpha",useNative and 1 or 0)
            M.CustomMonitor.SetVisual(slot.baseIconFrame,"SetAlpha",useNative and slot.nativeBackdrop and 0 or 1)
        end
        if slot.entry.type~="custom"and slot.entry.type~="blizzard" and slot.customGlow then slot.customGlow:Hide()end
        for _,frame in ipairs(slot.nativeFrames or {})do
            if useNative then
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
        if slot.entry.type=="custom"then
            ClearCooldown(slot.cooldown);slot.duration=nil
            local result=M.CustomMonitor.Apply(o,slot,view.preview)
            M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",false);textureAlpha=1
            M.CustomMonitor.SetText(slot.text,result.text or S.FormatCountdown(result.expirationTime and result.expirationTime-now))
            M.CustomMonitor.SetText(slot.count,result.count and tostring(result.count)or "")
            M.CustomMonitor.Glow(slot,result.show and result.glow)
        elseif slot.entry.type=="usable" then
            M.CustomMonitor.SetText(slot.text,"")
            if view.preview then SetCount(slot,nil) else SetCount(slot,slot.spellCount) end
            M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",false)
        elseif view.preview then
            local faded=(i%2==1)~=reversed
            ClearCooldown(slot.cooldown);M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",faded);textureAlpha=faded and .5 or 1
            M.CustomMonitor.SetText(slot.text,S.FormatCountdown(30-i))
            M.CustomMonitor.SetText(slot.count,isAura and "3"or "2")
        elseif slot.duration then
            SetCount(slot,slot.spellCount)
            useCooldownNumbers=true
            M.CustomMonitor.SetText(slot.text,"")
            local desat=DisplayCurve(desaturationCurves,reversed,0,1)
            if desat and slot.duration.EvaluateRemainingDuration and slot.texture.SetDesaturation then
                -- The engine consumes this potentially secret number directly.
                M.CustomMonitor.SetVisual(slot.texture,"SetDesaturation",slot.duration:EvaluateRemainingDuration(desat,0))
                textureAlpha=slot.duration:EvaluateRemainingDuration(DisplayCurve(fadeCurves,reversed,1,.5),reversed and .5 or 1)

            else
                local remaining=Number(Safe(slot.duration.GetRemainingDuration,slot.duration))
                if remaining then
                    useCooldownNumbers=false
                    local faded=(remaining>0)~=reversed
                    M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",faded);Remaining(slot,remaining)
                    textureAlpha=faded and .5 or 1

                end
            end
        elseif useNative then
            M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",reversed);M.CustomMonitor.SetText(slot.text,"");M.CustomMonitor.SetText(slot.count,"")
            textureAlpha=reversed and .5 or 1
        else
            local active=slot.active and (not slot.expires or slot.expires>now)
            local faded=(active==true)~=reversed
            M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",faded);Remaining(slot,active and slot.expires and slot.expires-now or nil)
            textureAlpha=faded and .5 or 1

            if isAura then CountText(slot.count,active and slot.stacks or nil,false)end
            if not isAura then SetCount(slot,slot.spellCount)end
        end
        local effectVisible
        if not view.preview and IsCombined(slot.entry) then
            local hasTextTimer
            effectVisible,hasTextTimer=PaintEffect(slot,now)
            if hasTextTimer then useCooldownNumbers=false end
            if effectVisible then textureAlpha=1
            elseif slot.blizzardDesaturated~=nil then
                M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",slot.blizzardDesaturated)
                textureAlpha=1
            end
        end
        if slot.entry.type~="custom" then
            local entry=slot.entry
            local count=Number(slot.stacks) or Number(slot.spellCount)
            local max=entry.maxStacks and entry.maxStacks>0 and entry.maxStacks or slot.maxCharges
            local proc=entry.triggerGlow==true and not view.preview and
                (slot.effectGlow==true or (slot.spellID and HasSpellActivation(slot.spellID))
                    or ((isAura or entry.type=="stance" or entry.type=="equipment") and slot.active))
            local full=entry.maxStackGlow==true and count and max and max>1 and count>=max
                and (not isAura or slot.active)
            if proc or full or slot.customGlow then M.CustomMonitor.Glow(slot,proc or full or false)end
        end
        if not view.preview then
            S.UpdateSkillSwipe(slot,group,now,effectVisible)
            if slot.bindingRevision~=S.bindingRevision then Shortcut(slot,group)end
        end
        M.CustomMonitor.SetVisual(slot.cooldown,"SetHideCountdownNumbers",not useCooldownNumbers)
        M.CustomMonitor.SetVisual(slot.texture,"SetAlpha",textureAlpha)
        M.CustomMonitor.SetVisual(slot.shortcutFrame,"SetAlpha",1)
    end
end
local events={PLAYER_TARGET_CHANGED=true,UNIT_AURA=true,SPELL_UPDATE_COOLDOWN=true,SPELL_UPDATE_CHARGES=true,SPELL_UPDATE_USES=true,
    SPELL_UPDATE_USABLE=true,ACTIONBAR_UPDATE_USABLE=true,ACTIONBAR_SLOT_CHANGED=true,
    UPDATE_BINDINGS=true,ACTIONBAR_PAGE_CHANGED=true,UPDATE_BONUS_ACTIONBAR=true,
    PLAYER_EQUIPMENT_CHANGED=true,UPDATE_SHAPESHIFT_FORM=true,UPDATE_SHAPESHIFT_FORMS=true,
    SPELL_ACTIVATION_OVERLAY_GLOW_SHOW=true,SPELL_ACTIVATION_OVERLAY_GLOW_HIDE=true,
    SPELLS_CHANGED=true,LEARNED_SPELL_IN_TAB=true,PLAYER_ENTERING_WORLD=true,PLAYER_REGEN_ENABLED=true,UNIT_SPELLCAST_SUCCEEDED=true,
    ACTIVE_TALENT_GROUP_CHANGED=true,PLAYER_TALENT_UPDATE=true,PLAYER_SPECIALIZATION_CHANGED=true,TRAIT_CONFIG_UPDATED=true,
    ACTIVE_COMBAT_CONFIG_CHANGED=true,ACTIVE_PLAYER_SPECIALIZATION_CHANGED=true,
    COOLDOWN_VIEWER_DATA_LOADED=true,COOLDOWN_VIEWER_TABLE_HOTFIXED=true,COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED=true}
function S.Event(view,event,unit)
    if not events[event] or (event=="UNIT_AURA" and unit~="target"and unit~="player") or (event=="UNIT_SPELLCAST_SUCCEEDED" and unit~="player")then return end
    ObserveBlizzardEvent(event,unit)
    local activation=event=="SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or event=="SPELL_ACTIVATION_OVERLAY_GLOW_HIDE"
    if activation and Number(unit) then
        activationEvents[unit]=event=="SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or nil
    elseif event=="PLAYER_ENTERING_WORLD" then activationEvents={} end
    if event=="ACTIONBAR_SLOT_CHANGED" or event=="PLAYER_ENTERING_WORLD" then legacyActionSlots=nil end
    if event=="UPDATE_BINDINGS" or event=="ACTIONBAR_SLOT_CHANGED" or event=="ACTIONBAR_PAGE_CHANGED"
        or event=="UPDATE_BONUS_ACTIONBAR" or event=="UPDATE_SHAPESHIFT_FORM" or event=="PLAYER_ENTERING_WORLD" then
        S.bindingRevision=(S.bindingRevision or 0)+1
    end
    if event=="SPELLS_CHANGED" or event=="LEARNED_SPELL_IN_TAB" or event=="PLAYER_ENTERING_WORLD" then learnedSpells=nil end
    local o=view.nodes.playerSkillMonitorIcons
    if not o or not o.monitorDirty then return end
    if event=="UNIT_AURA" then
        for _,kind in ipairs(auraKinds)do
            if auraTypes[kind].unit==unit then S.InvalidateMonitor(o,kind)end
        end
        if unit=="player" then S.InvalidateMonitor(o,"special")end
        S.InvalidateMonitor(o,"cooldown")
        if unit=="player" and o.skillKinds.usable then S.InvalidateMonitor(o,"usable")end
    elseif event=="PLAYER_EQUIPMENT_CHANGED" or event=="UPDATE_SHAPESHIFT_FORM" or event=="UPDATE_SHAPESHIFT_FORMS" then
        S.InvalidateMonitor(o,"special",true)
    elseif event=="PLAYER_TARGET_CHANGED" then
        o.nativeTargetGeneration=nil
        S.InvalidateMonitor(o,"debuff",true);S.InvalidateMonitor(o,"targetBuff",true)
        S.InvalidateMonitor(o,"usable",true)
        if o.skillKinds.blizzard or o.skillKinds.debuffCooldown then
            for _,slot in ipairs(o.skillIcons)do
                if slot.effect and (slot.effect.unit=="target" or slot.effect.alternate)then slot.effectAura=nil end
            end
            S.InvalidateMonitor(o,"cooldown",true)
        end
    elseif activation or event=="SPELL_UPDATE_USABLE" or event=="ACTIONBAR_UPDATE_USABLE" or event=="ACTIONBAR_SLOT_CHANGED" then
        S.InvalidateMonitor(o,"usable")
        if o.skillKinds.blizzard then S.InvalidateMonitor(o,"cooldown",activation)end
    elseif event=="SPELL_UPDATE_COOLDOWN" or event=="SPELL_UPDATE_CHARGES" or event=="SPELL_UPDATE_USES" or event=="UNIT_SPELLCAST_SUCCEEDED" then
        S.InvalidateMonitor(o,"gcd")
        S.InvalidateMonitor(o,"cooldown")
        S.InvalidateMonitor(o,"usable")
    else
        learnedSpells=nil
        for _,slot in ipairs(o.skillIcons or {})do slot.needsInfo=true;slot.nextInfo=0;slot.effectDirty=true end
        S.ResetMonitorRefresh(o)
    end
end

function S.BuildControls(e,parent,Row)
    local W=M.Widgets
    local choices={
        {name="跟随暴雪CDM",path="blizzard"},{name="法术冷却",path="cooldown"},
        {name="Buff/Debuff",path="aura"},{name="可用触发法术",path="usable"},
        {name="姿态/形态/光环",path="stance"},{name="装备触发",path="equipment"},
        {name="自定义代码",path="custom"},
    }
    local function Current()
        return M.selection=="playerSkillMonitor" and M.byID.playerSkillMonitor
    end
    local function Editable(owner,entry)
        return owner and owner==Current() and S.EntryIndex(owner,entry) and M:CanEdit()
    end
    local function Panel(height,key)
        local frame=CreateFrame("Frame",nil,parent);frame:SetSize(470,height)
        Row(height,{{frame,0,0}}, {},key)
        return frame,e.propRows[#e.propRows]
    end
    local imports=Panel(162,"skillMonitorImport")
    local appearance=Panel(24,"skillMonitorAppearance")
    W.SettingsSectionTitle(appearance,"外观与显示",-8)
    local share=Panel(56,"skillMonitorSharing")
    local panel=Panel(205,"skillMonitorEntry");e.skillMonitorPanel=panel
    local function Flush() if panel.edit and panel.edit:HasFocus() then panel.edit:ClearFocus() end end
    imports.available=S.AddBlizzardCooldownButton and S.AddBlizzardCooldownButton(imports,Current,Flush)
    e.skillMonitorImport=imports
    W.SettingsSectionTitle(share,"配置分享",10)
    local export=W.Button(share,"导出配置",150,function()Flush();M:ShowConfigStringDialog("export","skillsAll")end)
    local import=W.Button(share,"导入配置",150,function()Flush();M:ShowConfigStringDialog("import","skills")end)
    export:SetPoint("TOPLEFT",0,-24);import:SetPoint("LEFT",export,"RIGHT",8,0)
    local globals={}
    for _,option in ipairs({
        {"图标缩放","skillIconScale",.05},{"图标间距","skillIconSpacing",1},
        {"显示冷却刷","skillCooldownSwipe"},{"显示GCD","skillShowGCD"},{"显示快捷键","skillShowShortcut"},
    })do
        local label,key,step=option[1],option[2],option[3]
        if step then
            local limits=skillNumeric[key]
            local caption=W.Label(parent,label)
            local slider=W.SpinBox(parent,205,limits[1],limits[2],step)
            slider:SetScript("OnValueChanged",function(self,value)
                local owner=Current()
                if not self.updating and owner and M:CanEdit()then owner[key]=value;M:Commit()end
            end)
            Row(53,{{caption,0,0},{slider,12,-22}}, {},key)
            globals[key]=slider
        else
            local check=W.Check(parent,label,function(value)
                local owner=Current()
                if owner and M:CanEdit()then owner[key]=not not value;M:Commit()
                elseif owner then globals[key]:SetChecked(owner[key]~=false)end
            end)
            Row(30,{{check,-4,0}}, {},key)
            globals[key]=check
        end
    end

    local function Update(change)
        local owner,entry=panel.owner,panel.entry
        Flush()
        if Editable(owner,entry)then change(entry);M:Commit()end
    end
    local function Choice(label,options,width,change)
        local button
        button=W.MediaSelect(panel,label,width,"choice",function()
            if button.menu then button.menu:Hide();return end
            local owner,entry=panel.owner,panel.entry
            W.MediaMenu(button,options,"choice",button.value,function(choice)
                if panel.owner==owner and panel.entry==entry then Update(function(item)change(item,choice.path)end)end
            end)
        end)
        function button:SetValue(value)
            self.value=value
            for _,choice in ipairs(options)do
                if choice.path==value then self:SetMedia(choice.name,value);return end
            end
        end
        return button
    end
    local function AuraKind(unit,harmful)
        if unit=="target"then return harmful and "debuff" or "targetBuff"end
        return harmful and "playerDebuff" or "buff"
    end
    local function Harmful(entry)
        return entry.type=="debuff" or entry.type=="playerDebuff"
    end
    local kind=Choice("监控类型",choices,150,function(entry,value)
        if value=="aura" then
            if not auraTypes[entry.type] then entry.type="buff" end
        else
            entry.type=value
            if value=="custom" then M.CustomMonitor.Defaults(entry) end
        end
    end)
    kind:SetPoint("TOPLEFT",0,0)
    local unit=Choice("单位",{{name="玩家",path="player"},{name="目标",path="target"}},115,function(entry,value)
        entry.type=AuraKind(value,Harmful(entry))
    end)
    unit:SetPoint("TOPLEFT",160,0)
    local filter=Choice("类型",{{name="Buff",path="buff"},{name="Debuff",path="debuff"}},115,function(entry,value)
        if auraTypes[entry.type] then entry.type=AuraKind(auraTypes[entry.type].unit,value=="debuff")end
    end)
    filter:SetPoint("TOPLEFT",285,0)
    local equipmentSlots={}
    for slot=1,19 do
        local name=({"HEADSLOT","NECKSLOT","SHOULDERSLOT","SHIRTSLOT","CHESTSLOT","WAISTSLOT","LEGSSLOT","FEETSLOT",
            "WRISTSLOT","HANDSSLOT","FINGER0SLOT","FINGER1SLOT","TRINKET0SLOT","TRINKET1SLOT","BACKSLOT","MAINHANDSLOT",
            "SECONDARYHANDSLOT","RANGEDSLOT","TABARDSLOT"})[slot]
        equipmentSlots[slot]={name=_G[name] or tostring(slot),path=tostring(slot)}
    end
    local equipment=Choice("装备位置",equipmentSlots,190,function(entry,value)entry.slot=tonumber(value)end)
    equipment:SetPoint("TOPLEFT",160,0)

    local icon=CreateFrame("Button",nil,panel);icon:SetSize(26,26);icon:SetPoint("TOPLEFT",0,-58)
    icon.texture=icon:CreateTexture(nil,"ARTWORK");icon.texture:SetAllPoints()
    local edit=W.Edit(panel,220);panel.edit=edit
    edit:SetMaxLetters(128);edit:SetTextInsets(6,6,0,0);edit:SetPoint("LEFT",icon,"RIGHT",8,0)
    W.NamedInput(edit,"spell")
    local placeholder=W.Label(edit,"输入监控技能名或ID",11);placeholder:SetPoint("LEFT",6,0);placeholder:SetTextColor(.5,.5,.5)
    local function RefreshIcon()
        local entry=panel.entry
        local value=S.Input(W.InputValue(edit))
        local name,id,texture
        if entry and entry.type=="equipment" then
            id,name,texture=M.PlayerOtherMonitor.Item(entry.slot or 13)
        else name,id,texture=M.PetBuffs.SpellInfo(value);id=tonumber(value) or id end
        icon.texture:SetTexture(M:TextureFile(texture or 134400))
        W.SetIconTooltip(icon,name and {name=name,id=id,icon=texture,slot=entry and entry.slot} or nil,
            entry and entry.type=="equipment" and "item" or "spell")
        placeholder:SetShown(edit:GetText()=="")
    end
    edit:HookScript("OnTextChanged",RefreshIcon)
    edit:SetScript("OnEditFocusGained",function(self)self.owner,self.entry=panel.owner,panel.entry end)
    edit:SetScript("OnEditFocusLost",function(self)
        local owner,entry=self.owner,self.entry;self.owner,self.entry=nil,nil
        if Editable(owner,entry)then
            local value=S.Input(W.InputValue(self))
            if value~=entry.value then entry.value=value;entry.blizzardCooldownID=nil;M:Commit()end
        end
    end)
    edit:SetScript("OnEnterPressed",function(self)self:ClearFocus()end)
    edit:SetScript("OnEscapePressed",function(self)
        if self.entry then W.SetInputValue(self,self.entry.value)end
        self:ClearFocus()
    end)
    edit:HookScript("OnHide",function(self)self:ClearFocus()end)
    local code=W.Button(panel,"编辑代码",100,function()
        Flush()
        if Editable(panel.owner,panel.entry)then M.CustomMonitor.OpenEditor(panel.owner,panel.entry)end
    end)
    code:SetPoint("LEFT",edit,"RIGHT",10,0)

    local function EntryCheck(label,key,y)
        local check=W.Check(panel,label,function(value)Update(function(entry)entry[key]=not not value end)end)
        check:SetPoint("TOPLEFT",-4,y)
        return check
    end
    local glow=EntryCheck("触发发光","triggerGlow",-96)
    local maxGlow=EntryCheck("最大层数发光","maxStackGlow",-129)
    local reverse=EntryCheck("反转褪色效果","reverseDisplay",-162)
    local maxLabel=W.Label(panel,"层数上限（0 = 自动）")
    maxLabel:SetPoint("LEFT",maxGlow.label,"RIGHT",18,0)
    local maxStacks=W.SpinBox(panel,76,0,999,1)
    maxStacks:SetPoint("LEFT",maxLabel,"RIGHT",8,0)
    maxStacks:SetScript("OnValueChanged",function(self,value)
        if not self.updating then Update(function(entry)entry.maxStacks=value end)end
    end)
    panel:SetScript("OnHide",function()
        Flush()
        for _,button in ipairs({kind,unit,filter,equipment})do if button.menu then button.menu:Hide()end end
    end)
    function panel:Refresh(owner)
        local entry=e.skillEntry
        if entry and not S.EntryIndex(owner,entry)then e.skillEntry=nil;entry=nil end
        local width=e.props:GetWidth()
        share:SetWidth(width);export:SetWidth((width-8)/2);import:SetWidth((width-8)/2)
        imports:SetWidth(width);appearance:SetWidth(width)
        for key,check in pairs(imports.blizzardSyncChecks or {})do check:SetChecked(S.BlizzardSyncEnabled(key))end
        for key,control in pairs(globals)do
            control.updating=true
            if skillNumeric[key]then control:SetValue(owner[key] or skillNumeric[key][3])
            else control:SetChecked(owner[key]~=false)end
            control.updating=false
        end
        if self.entry~=entry or self.owner~=owner then
            Flush()
            for _,button in ipairs({kind,unit,filter,equipment})do if button.menu then button.menu:Hide()end end
        end
        self.owner,self.entry=owner,entry
        if not entry then return end
        local aura=auraTypes[entry.type]
        local combined=effectTypes[entry.type]
        local isEquipment=entry.type=="equipment"
        kind:SetValue((aura or combined) and "aura" or entry.type)
        unit:SetShown(aura~=nil or combined~=nil);filter:SetShown(aura~=nil or combined~=nil)
        if aura or combined then
            local category=aura or auraTypes[combined]
            unit:SetValue(category.unit)
            filter:SetValue((Harmful(entry) or combined=="debuff") and "debuff" or "buff")
        end
        equipment:SetShown(isEquipment);equipment:SetValue(tostring(entry.slot or 13))
        code:SetShown(entry.type=="custom")
        if isEquipment then
            local _,name=M.PlayerOtherMonitor.Item(entry.slot or 13)
            W.SetInputValue(edit,name or M:T("未装备"));edit:Disable()
        else
            edit:Enable()
            if not edit:HasFocus()then W.SetInputValue(edit,entry.value)end
        end
        RefreshIcon()
        glow:SetChecked(entry.triggerGlow==true);maxGlow:SetChecked(entry.maxStackGlow==true)
        reverse:SetChecked(entry.reverseDisplay==true)
        maxStacks.updating=true;maxStacks:SetValue(entry.maxStacks or 0);maxStacks.updating=false
        maxStacks:SetShown(entry.maxStackGlow==true);maxLabel:SetShown(entry.maxStackGlow==true)
    end
end
