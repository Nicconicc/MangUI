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
local function SkillChecked(group,key)
    if key=="skillRangeRed" then return group[key]==true end
    return group[key]~=false
end
local extraEntryFields={triggerGlow=true,maxStackGlow=true,triggerGlowColor=true,maxStackGlowColor=true,maxStacks=true,slot=true,blizzardCategory=true,onlyWhenTriggered=true}
local soundFields={soundEnabled=true,soundWhen=true,sound=true,soundPath=true,soundID=true}
local whiteGlow={1,1,1,1}
local validBlizzardCategories={Essential=true,Utility=true,TrackedBuff=true}
local effectTypes={buffCooldown="buff",debuffCooldown="debuff"}
local function IsCombined(entry)return entry.type=="blizzard" or effectTypes[entry.type]~=nil end
local function AuraFilter(aura,onlyMine)
    local filter=aura.filter:gsub("|PLAYER","")
    return onlyMine and filter.."|PLAYER" or filter
end
local function IsSpellIcon(entry)
    return IsCombined(entry) or entry.type=="cooldown" or entry.type=="usable"
end
local function TriggerGlowEnabled(entry)
    return entry.triggerGlow==true or (entry.type=="usable" and entry.triggerGlow==nil)
end
local function StackGlowThreshold(entry,automatic)
    if entry.maxStackGlow~=true then return end
    if entry.maxStacks and entry.maxStacks>0 then return entry.maxStacks end
    if automatic and automatic>1 then return automatic end
end
local function Readable(v)return not issecretvalue or not issecretvalue(v)end
local function Number(v)return Readable(v) and type(v)=="number" and v or nil end
local function Safe(fn,...)
    if not fn then return end
    local ok,a,b,c,d,e=pcall(fn,...);if ok then return a,b,c,d,e end
end
local function AuraSourceIsPlayer(aura)
    local source=aura.sourceUnit
    return Readable(source) and (source=="player"
        or (source~=nil and M.Compat.Bool(Safe(UnitIsUnit,source,"player"))))
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
        if entry.soundEnabled~=nil and type(entry.soundEnabled)~="boolean"then return false end
        if entry.soundWhen~=nil and entry.soundWhen~="start" and entry.soundWhen~="finish" then return false end
        for _,key in ipairs({"sound","soundPath","soundID"})do
            if entry[key]~=nil and (type(entry[key])~="string" or #entry[key]>512)then return false end
        end
        for _,key in ipairs({"triggerGlowColor","maxStackGlowColor"})do
            local color=entry[key]
            if color~=nil then
                if type(color)~="table" or #color~=4 then return false end
                for index=1,4 do
                    local value=color[index]
                    if type(value)~="number" or value~=value or value<0 or value>1 then return false end
                end
            end
        end
        if type(entry.value)~="string" or #entry.value>384 then return false end
        if entry.effect~=nil and (type(entry.effect)~="string" or #entry.effect>384)then return false end
        if entry.blizzardCategory~=nil and not validBlizzardCategories[entry.blizzardCategory]then return false end
        local cooldownID=entry.blizzardCooldownID
        if cooldownID~=nil and (type(cooldownID)~="number" or cooldownID<=0 or cooldownID>2147483647 or cooldownID%1~=0)then return false end
        if entry.showShortcut~=nil and type(entry.showShortcut)~="boolean" then return false end
        if entry.reverseDisplay~=nil and type(entry.reverseDisplay)~="boolean" then return false end
        if entry.onlyMine~=nil and type(entry.onlyMine)~="boolean" then return false end
        if entry.shortcut~=nil and (type(entry.shortcut)~="string" or #entry.shortcut>128) then return false end
        if entry.shortcutColor~=nil then
            if type(entry.shortcutColor)~="table" then return false end
            for i=1,4 do
                local v=entry.shortcutColor[i]
                if type(v)~="number" or v~=v or v<0 or v>1 then return false end
            end
            for k in pairs(entry.shortcutColor)do if type(k)~="number" or k%1~=0 or k<1 or k>4 then return false end end
        end
        for _,key in ipairs({"triggerGlow","maxStackGlow","onlyWhenTriggered"})do
            if entry[key]~=nil and type(entry[key])~="boolean" then return false end
        end
        if entry.maxStacks~=nil and (type(entry.maxStacks)~="number" or entry.maxStacks%1~=0 or entry.maxStacks<0 or entry.maxStacks>999)then return false end
        if entry.slot~=nil and (type(entry.slot)~="number" or entry.slot%1~=0 or entry.slot<1 or entry.slot>19)then return false end
        for field in pairs(entry)do
            if field~="type" and field~="value" and field~="showShortcut" and field~="shortcut" and field~="shortcutColor"
                and field~="reverseDisplay" and field~="onlyMine" and field~="effect" and field~="blizzardCooldownID"
                and not extraEntryFields[field] and not soundFields[field] and not M.CustomMonitor.fields[field]then return false end
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
    group.skillRangeRed=group.skillRangeRed==true
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
local desaturationCurves,reversedOpacityCurves={},{}
local reversedOpacity=.6
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
local function ConfigureSwipe(timer)
    if timer.SetReverse then timer:SetReverse(true)end
    if timer.SetSwipeColor then timer:SetSwipeColor(0,0,0,.7)end
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
local function AuraVisibilityMarker(parent)
    local marker=CreateFrame("Frame",nil,parent)
    marker:SetAllPoints();marker:EnableMouse(false)
    return marker
end
local function ListenForCountdownEnd(slot,timer)
    timer:HookScript("OnCooldownDone",function()
        local state,entry=slot.skillSound,slot.entry
        if not slot.resettingSoundTimer and state and state.entry==entry and (entry.soundEnabled or entry.onlyWhenTriggered)
            and state.nativeTimer==timer and state.active then
            if timer==slot.soundTimer then state.soundTimerArmed=nil end
            state.completedTimer=timer
        end
    end)
end
local function ObserveNativeAuraSound(slot,frame,timer)
    frame:HookScript("OnShow",function()
        if not slot.resettingSoundTimer and slot.entry and (slot.entry.soundEnabled or slot.entry.onlyWhenTriggered) then
            slot.auraSoundTimer=timer
        end
    end)
    frame:HookScript("OnHide",function()
        if slot.auraSoundTimer==timer then slot.auraSoundTimer=nil end
    end)
end
local function ApplySkillGlowBorder(glow,border)
    if glow.skinBorder==border then return end
    glow.skinBorder=border
    if border then
        glow.edge:SetTexture(border.texture)
        glow.edge:SetTexCoord(0,1,0,1);glow.edge:SetSize(border.width+4,border.height+4)
        glow.edge:SetDesaturated(true)
        glow.inner:SetTexture(border.texture)
        glow.inner:ClearAllPoints();glow.inner:SetPoint("CENTER")
        glow.inner:SetSize(border.width,border.height)
        glow.inner:SetDesaturated(true);glow.inner:Show()
    else
        glow.edge:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        glow.edge:SetTexCoord(0,1,0,1);glow.edge:SetSize(72,72)
        glow.edge:SetDesaturated(false)
        glow.inner:SetTexture(M:TextureFile("Interface\\AddOns\\MangUI\\Assets\\UI\\MonitorInnerGlow.tga"))
        glow.inner:ClearAllPoints()
        glow.inner:SetPoint("TOPLEFT",-2,2);glow.inner:SetPoint("BOTTOMRIGHT",2,-2)
        glow.inner:SetDesaturated(false);glow.inner:Show()
    end
end
local function PaintSkillGlow(slot,glow,enabled,color,now)
    M.CustomMonitor.PaintGlow(glow,enabled,color or whiteGlow,now)
    if enabled then ApplySkillGlowBorder(glow,M.MasqueIcons.GlowBorder(slot.texture))end
end
local function CreateNativeGlowDisplay(slot,marker)
    -- The marker observes the aura, but the glow belongs to MangUI's slot.
    local glow=M.CustomMonitor.CreateGlow(slot)
    glow:SetFrameLevel(slot:GetFrameLevel()+25)
    return {glow=glow,marker=marker}
end
local function PaintNativeGlow(slot,display,enabled,now,color)
    if not display or not display.glow then return end
    local glow,marker=display.glow,display.marker
    local visible=enabled and marker and Safe(marker.IsVisible,marker)
    if type(visible)=="boolean" then
        if not Readable(visible) then
            if glow.SetAlphaFromBoolean then
                glow:SetAlphaFromBoolean(visible,1,0)
                PaintSkillGlow(slot,glow,true,color,now)
                return
            end
        elseif visible then
            glow:SetAlpha(1)
            PaintSkillGlow(slot,glow,true,color,now)
            return
        end
    end
    glow:Hide()
end
local function BindNativeStackGlow(slot,display)
    local threshold=StackGlowThreshold(slot.entry)
    if display.threshold==threshold then return end
    local frame=display.frame
    if threshold and frame.SetApplicationBar then
        if not display.bar then
            local bar=CreateFrame("StatusBar",nil,frame);bar:SetAllPoints();bar:EnableMouse(false)
            display.bar=bar
            local owned=CreateNativeGlowDisplay(slot,AuraVisibilityMarker(bar))
            display.glow,display.marker=owned.glow,owned.marker
        end
        -- The engine owns bar visibility and applies the threshold even to
        -- aura applications that are unavailable to addon Lua in combat.
        if not pcall(frame.SetApplicationBar,frame,display.bar,{minApplications=threshold,maxApplications=threshold+1}) then return end
    elseif display.bar then
        display.glow:Hide()
        Safe(frame.ClearApplicationBar,frame)
    end
    display.threshold=threshold
end
local function StyleNativeAura(slot,frame,reversed,nativeGlows,nativeStacks)
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
    local presence=AuraVisibilityMarker(frame)
    nativeGlows[#nativeGlows+1]=CreateNativeGlowDisplay(slot,presence)
    local tracker=nativeGlows[#nativeGlows]
    if frame.SetDurationCooldown then
        local timer=CreateFrame("Cooldown",nil,frame,"CooldownFrameTemplate")
        timer:SetAllPoints();timer:EnableMouse(false)
        timer:SetDrawEdge(false);timer:SetDrawBling(false);timer:SetDrawSwipe(false)
        M.CustomMonitor.SetVisual(timer,"SetHideCountdownNumbers",true);timer.noCooldownCount=true
        ListenForCountdownEnd(slot,timer)
        ObserveNativeAuraSound(slot,frame,timer)
        tracker.timer=timer;frame:SetDurationCooldown(timer)
    end
    local display={frame=frame}
    nativeStacks[#nativeStacks+1]=display
    BindNativeStackGlow(slot,display)
    if forever then return end
    -- The provider denies direct access to its AuraButtons once auras become
    -- secret. Our own child exposes inherited visibility as a secret boolean;
    -- pass it straight to the alpha setter without querying the AuraButton.
    frame.monitorPresence=presence
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
    slot.nativeFrames={};slot.nativeGlows={};slot.nativeStacks={};slot.nativeAuras=container
    if slot.nativeHost then
        local backdrop=S.CreateAuraBackdrop(slot.nativeHost,container)
        if backdrop then
            slot.nativeBackdrop=backdrop:CreateTexture(nil,"ARTWORK");slot.nativeBackdrop:SetAllPoints()
            slot.nativeBackdrop:SetTexture(M:TextureFile(slot.customFallbackIcon))
            slot.nativeBackdrop:SetDesaturated(reversed);slot.nativeBackdrop:SetAlpha(reversed and reversedOpacity or 1)
            M.MasqueIcons.Attach(slot.nativeBackdrop,"playerSkillMonitor",40,40)
        end
    end
    local width=slot.nativeBackdrop and S.auraBackdropLayoutWidth or 40
    local nativeGlows,nativeStacks=slot.nativeGlows,slot.nativeStacks
    slot.nativeAuraFilter=AuraFilter(aura,slot.entry.onlyMine~=false)
    container:AddAuraGroup("monitor",slot.nativeAuraFilter,{maxFrameCount=0,
        initializeFrame=function(frame)StyleNativeAura(slot,frame,reversed,nativeGlows,nativeStacks)end})
    container:SetFlowLayoutAnchorPoint("TOPLEFT")
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right,AnchorUtil.FlowDirection.Down)
    container:SetFlowLayoutMaximumLineSize(width+.001)
    container:SetAuraGroupLayout("monitor",{elementSpacing=0,lineSpacing=0,elementWidth=width,elementHeight=40})
end
-- Native AuraButtons can become inaccessible after initialization. Keep one
-- initialized container per style and switch containers without restyling them.
local nativeVariantFields={"nativeAuras","nativeHost","nativeBackdrop","nativeFrames","nativeGlows","nativeStacks","nativeAuraType","nativeAuraFilter","shortcutGate","baseIconGate"}
local function SelectNativeAura(slot,aura)
    local reversed=slot.entry.reverseDisplay==true
    if slot.nativeAuras and slot.nativeReversed==reversed then return end
    slot.nativeVariants=slot.nativeVariants or {}
    if slot.nativeAuras then
        for _,display in ipairs(slot.nativeGlows or {})do display.glow:Hide()end
        for _,display in ipairs(slot.nativeStacks or {})do if display.glow then display.glow:Hide()end end
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
    ListenForCountdownEnd(slot,slot.cooldown)
    slot.gcd=CreateFrame("Cooldown",nil,slot,"CooldownFrameTemplate")
    slot.gcd:SetAllPoints();slot.gcd:EnableMouse(false)
    slot.gcd:SetDrawEdge(false);slot.gcd:SetDrawBling(false);slot.gcd:SetDrawSwipe(true)
    M.CustomMonitor.SetVisual(slot.gcd,"SetHideCountdownNumbers",true);slot.gcd.noCooldownCount=true
    if slot.gcd.SetSwipeColor then slot.gcd:SetSwipeColor(0,0,0,.45)end
    slot.cooldown:SetDrawEdge(false);slot.cooldown:SetDrawBling(false);slot.cooldown:SetDrawSwipe(false)
    ConfigureSwipe(slot.cooldown)
    M.CustomMonitor.SetVisual(slot.cooldown,"SetHideCountdownNumbers",true);slot.cooldown.noCooldownCount=true
    slot.effectSwipe=CreateFrame("Cooldown",nil,slot,"CooldownFrameTemplate")
    slot.effectSwipe:SetAllPoints();slot.effectSwipe:EnableMouse(false)
    slot.effectSwipe:SetDrawEdge(false);slot.effectSwipe:SetDrawBling(false)
    M.CustomMonitor.SetVisual(slot.effectSwipe,"SetHideCountdownNumbers",true)
    slot.effectSwipe.noCooldownCount=true;ConfigureSwipe(slot.effectSwipe)
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
        slot.nativeAuraType=slot.entry.type
    end
    local filter=AuraFilter(aura,slot.entry.onlyMine~=false)
    if slot.nativeAuraFilter~=filter then
        slot.nativeAuras:SetAuraGroupFilterString("monitor",filter)
        slot.nativeAuraFilter=filter
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
    for _,display in ipairs(slot.nativeStacks or {})do BindNativeStackGlow(slot,display)end
    slot.nativeAuras:SetAuraGroupMaxFrameCount("monitor",1)
    slot.nativeSpellID=slot.spellID
    slot.nativeAuras:SetEnabled(true);slot.nativeAuras:UpdateAllAuras()
end
local function BindEffect(slot)
    if InCombatLockdown() then return end
    local native=slot.effectNative
    local effect=slot.effect
    slot.resettingSoundTimer=true
    if native then native:SetEnabled(false)end
    slot.boundEffect=nil
    if not effect or not next(effect.ids) or not NativeAurasAvailable() then slot.resettingSoundTimer=nil;return end
    if not native then
        native=CreateFrame("AuraContainer",nil,slot,"CustomAuraContainerTemplate")
        slot.effectNative=native
        native:SetEnabled(false);native:SetPoint("TOPLEFT",slot,"TOPLEFT",0,0)
        native:AddAuraGroup("effect",effect.filter,{maxFrameCount=1,initializeFrame=function(frame)
            frame:SetSize(40,40);frame:EnableMouse(false)
            frame:SetFrameLevel(slot.baseIconFrame:GetFrameLevel()+2)
            local icon=frame:CreateTexture(nil,"ARTWORK");icon:SetAllPoints()
            slot.effectNativeIcon=icon
            local reversed=slot.entry.reverseDisplay==true
            icon:SetDesaturated(reversed);icon:SetAlpha(reversed and reversedOpacity or 1)
            M.MasqueIcons.Attach(icon,"playerSkillMonitor",40,40)
            frame:SetIcon(icon)
            local presence=AuraVisibilityMarker(frame)
            slot.effectPresence=presence
            slot.effectNativeGlow=CreateNativeGlowDisplay(slot,presence)
            slot.effectNativeStack={frame=frame}
            BindNativeStackGlow(slot,slot.effectNativeStack)
            local timer=frame:CreateFontString(nil,"OVERLAY");Font(timer)
            timer:SetPoint("BOTTOM",frame,"TOP",0,7)
            frame:SetDurationText(timer,S.DurationTextOptions())
            if frame.SetDurationCooldown then
                local swipe=CreateFrame("Cooldown",nil,frame,"CooldownFrameTemplate")
                swipe:SetAllPoints();swipe:EnableMouse(false)
                swipe:SetDrawEdge(false);swipe:SetDrawBling(false)
                M.CustomMonitor.SetVisual(swipe,"SetHideCountdownNumbers",true)
                swipe.noCooldownCount=true;ConfigureSwipe(swipe)
                swipe:SetDrawSwipe(slot.showCooldownSwipe)
                slot.effectNativeSwipe=swipe
                ListenForCountdownEnd(slot,swipe)
                ObserveNativeAuraSound(slot,frame,swipe)
                frame:SetDurationCooldown(swipe)
            end
            local count=frame:CreateFontString(nil,"OVERLAY");CountFont(count)
            count:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-1,1);frame:SetApplicationCount(count,{})
        end})
        native:SetFlowLayoutAnchorPoint("TOPLEFT")
        native:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right,AnchorUtil.FlowDirection.Down)
        native:SetFlowLayoutMaximumLineSize(40.001)
        native:SetAuraGroupLayout("effect",{elementSpacing=0,lineSpacing=0,elementWidth=40,elementHeight=40})
    end
    native:SetUnit(effect.unit)
    native:SetAuraGroupFilterString("effect",effect.filter)
    native:SetAuraGroupCandidateFilters("effect",{includeSpellIDs=effect.ids})
    if slot.effectNativeStack then BindNativeStackGlow(slot,slot.effectNativeStack)end
    if slot.effectNativeIcon then
        local reversed=slot.entry.reverseDisplay==true
        Safe(M.CustomMonitor.SetVisual,slot.effectNativeIcon,"SetDesaturated",reversed)
        Safe(M.CustomMonitor.SetVisual,slot.effectNativeIcon,"SetAlpha",reversed and reversedOpacity or 1)
    end
    native:SetEnabled(true);native:UpdateAllAuras()
    slot.boundEffect=effect
    slot.resettingSoundTimer=nil
end

local function SameEffectBinding(first,second)
    if first==second then return true end
    if not first or not second or first.unit~=second.unit or first.filter~=second.filter then return false end
    for id in pairs(first.ids)do if not second.ids[id]then return false end end
    for id in pairs(second.ids)do if not first.ids[id]then return false end end
    return true
end
local function ResolveEffect(slot,preview)
    local entry,id=slot.entry,slot.spellID
    local blizzardInfo
    if not preview and entry.type=="blizzard" and M.Compat.interface==16001 then
        blizzardInfo=Safe(S.GetBlizzardCooldownInfo,entry,id)
        if not Readable(blizzardInfo) or type(blizzardInfo)~="table"
            or (canaccesstable and not canaccesstable(blizzardInfo))then blizzardInfo=nil end
        local known=blizzardInfo and blizzardInfo.isKnown
        if (not blizzardInfo or not Readable(known)) and InCombatLockdown()
            and slot.resolvedBlizzardEntry==entry and slot.resolvedBlizzardSpell==id then
            -- Combat can temporarily restrict the CDM metadata. Keep the
            -- engine-owned aura timer for the already resolved spell.
            slot.effectDirty=false
            return
        end
    end
    slot.resolvedBlizzardEntry,slot.resolvedBlizzardSpell=nil,nil
    slot.effect,slot.effectAura,slot.effectSpell,slot.effectGlow,slot.effectRevenge=nil,nil,nil,nil,nil
    slot.blizzardID,slot.blizzardTimer,slot.blizzardDesaturated,slot.blizzardAuraActive=nil,nil,nil,nil
    slot.blizzardEnd=nil
    slot.effectKnown=true
    if not preview and IsCombined(entry) then
        local kind=effectTypes[entry.type]
        local ids,name={},nil
        if entry.type=="blizzard" and M.Compat.interface==16001 then
            local info=blizzardInfo
            slot.effectKnown=info and Readable(info.isKnown) and info.isKnown==true or false
            if info then
                slot.resolvedBlizzardEntry,slot.resolvedBlizzardSpell=entry,id
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
                if entry.blizzardCategory=="TrackedBuff" then
                    local onlyMine=entry.onlyMine~=false
                    slot.effect.onlyMine=onlyMine
                    slot.effect.filter=AuraFilter(aura,onlyMine)
                    slot.effect.alternate.onlyMine=onlyMine
                    slot.effect.alternate.filter=AuraFilter(other,onlyMine)
                end
            else
                slot.effect.onlyMine=entry.onlyMine~=false
                slot.effect.filter=AuraFilter(aura,slot.effect.onlyMine)
            end
        end
    end
    if not preview and id and (entry.type=="cooldown" or entry.type=="usable") then
        local override=Number(Safe(C_Spell and C_Spell.GetOverrideSpell or FindSpellOverrideByID,id))
        local lookup=C_UnitAuras and C_UnitAuras.GetCooldownAuraBySpellID
        local mapped=Number(Safe(lookup,override and override>0 and override or id))
        if (not mapped or mapped<=0) and override and override~=id then mapped=Number(Safe(lookup,id))end
        if mapped and mapped>0 then
            local ids={[mapped]=true}
            slot.effect={unit="player",filter="HELPFUL",ids=ids,
                alternate={unit="target",filter="HARMFUL|PLAYER",ids=ids}}
        end
    end
    slot.effectDirty=false
    slot.effectNeedsBind=not SameEffectBinding(slot.boundEffect,slot.effect)
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
function S.Configure(view,o)
    o.skillIcons=o.skillIcons or {};o.nativeTargetGeneration=nil
    S.ResetMonitorRefresh(o)
    o.skillKinds={}
    local group=view.byID[o.spec.parent]
    o.skillEditorPreview=view.preview and view.previewScope=="playerSkillMonitor"
    local draft=o.skillEditorPreview and M.editor and M.editor.skillEntry
    o.entries=S.Entries(group,draft);o.usesNativeAuras=not view.preview and NativeAurasAvailable()
    for i,entry in ipairs(o.entries)do
        o.skillKinds[entry.type]=true
        local slot=Icon(view,o,i);Resolve(slot,entry);slot.duration=nil;slot.expires=nil;slot.active=false;slot.stacks=nil
        slot.baseIconFrame:SetAlpha(1)
        slot.texture:SetVertexColor(1,1,1)
        slot.appliedSpellR,slot.appliedSpellG,slot.appliedSpellB=1,1,1
        slot:SetScale(S.IconSize(group)/40)
        slot.rowX=nil;slot.rowVisible=nil;slot.sweepStart=nil;slot.maxCharges=nil;slot.auraDuration=nil;slot.item=nil
        slot.showCooldownSwipe=group.skillCooldownSwipe~=false
        slot.cooldown:SetDrawSwipe(slot.showCooldownSwipe)
        slot.effectSwipe:SetDrawSwipe(slot.showCooldownSwipe);ClearCooldown(slot.effectSwipe);slot.effectSwipe.monitorStart=nil
        if slot.effectNativeSwipe then Safe(slot.effectNativeSwipe.SetDrawSwipe,slot.effectNativeSwipe,slot.showCooldownSwipe)end
        slot.cooldownDesaturates=nil;slot.spellR,slot.spellG,slot.spellB=1,1,1
        ClearCooldown(slot.gcd)
        slot.gcdStart=nil;slot.gcd.monitorStart=nil;slot.cooldown.monitorStart=nil
        ResolveEffect(slot,view.preview)
        if not view.preview and (slot.effect or slot.effectNative) and not InCombatLockdown()then
            BindEffect(slot);slot.effectNeedsBind=false
        end
        slot.timerGate:SetAlpha(1);M.CustomMonitor.SetVisual(slot.cooldown,"SetAlpha",1)
        if slot.effectNative then slot.effectNative:SetAlpha(0)end
        slot.spellCount=nil;slot.chargeCount=nil;slot.countGate:SetAlpha(1)
        CountFont(slot.count);M.CustomMonitor.SetText(slot.count,"")
        slot.resettingSoundTimer=true
        M.CustomMonitor.SetText(slot.text,"");ClearCooldown(slot.cooldown);M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",false)
        slot.resettingSoundTimer=nil
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
local function SpellIconID(slot)
    local id=slot.spellID
    if slot.effectSpell then return slot.effectSpell end
    if not id then return end
    local override=Number(Safe(C_Spell and C_Spell.GetOverrideSpell or FindSpellOverrideByID,id))
    return override and override>0 and override or id
end
local function Cooldown(entry,slot,cache)
    local key=SpellIconID(slot) or entry.value
    local charges,maximum,chargeStart,chargeDuration,chargeRate=SpellCharges(key)
    slot.spellCount=SpellCount(slot,key,charges,maximum)
    slot.chargeCount=charges
    slot.maxCharges=Number(maximum)
    slot.cooldownDesaturates=not (slot.maxCharges and slot.maxCharges>1 and Number(charges) and charges>0)
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
    local recharging=Number(charges) and Number(maximum) and charges<maximum and Number(chargeStart) and Number(chargeDuration)
    if recharging then
        start,duration,rate=chargeStart,chargeDuration,chargeRate
    elseif Readable(onGCD) and onGCD==true then
        slot.active=false;slot.expires=nil;return
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
    local expires=effectVisible and slot.effectExpires
    local duration=expires and Number(slot.effectAura.duration)
    if group.skillCooldownSwipe~=false and duration and duration>0 then
        SetSwipe(slot.effectSwipe,expires-duration,duration,1)
    else SetSwipe(slot.effectSwipe)end
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
    local filter=AuraFilter(auraType,false)
    for _,aura in ipairs(M.Compat.AuraSnapshot(auraType.unit,filter))do
        local id=Number(aura.spellId) or Number(aura.spellID)
        local named=Readable(aura.name) and byName[aura.name]
        local numbered=id and byID[id]
        if named or numbered then
            local own=AuraSourceIsPlayer(aura)
            local stacks,expires=Number(aura.applications),Number(aura.expirationTime)
            for i=1,2 do
                local slots
                if i==1 then slots=named else slots=numbered end
                for _,slot in ipairs(slots or emptyAuraSlots) do
                    if slot.entry.onlyMine==false or own then
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
                if expires and (expires==0 or expires>now)
                    and (effect.onlyMine~=true or AuraSourceIsPlayer(aura)) then return aura end
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
            local requireMine=effect.onlyMine==true or (effect.onlyMine==nil and effect.unit=="target")
            local own=not requireMine or AuraSourceIsPlayer(aura)
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

local function CountdownEnd(timer)
    if not timer then return end
    local start,duration=Safe(timer.GetCooldownTimes,timer)
    start,duration=Number(start),Number(duration)
    if start and duration then return duration>0 and (start+duration)/1000 or 0 end
end

local function ReadBlizzardPresentation(slot,frame)
    slot.blizzardTimer,slot.blizzardDesaturated,slot.blizzardAuraActive=nil,nil,nil
    slot.blizzardEnd=nil
    local usesAura=frame and frame.cooldownUseAuraDisplayTime
    local ownTracked=slot.entry.blizzardCategory=="TrackedBuff" and slot.entry.onlyMine~=false
    -- The unfiltered CDM label cannot verify the caster. Use our filtered
    -- native aura container for these timers, including during combat.
    if ownTracked and (not Readable(usesAura) or usesAura~=false) then return end
    slot.blizzardAuraActive=Readable(usesAura) and usesAura==true
    local texture=frame and Safe(frame.GetIconTexture,frame)
    if Readable(texture) and texture then
        local desaturated=Safe(texture.IsDesaturated,texture)
        if Readable(desaturated) and type(desaturated)=="boolean" then slot.blizzardDesaturated=desaturated end
    end
    local timer=frame and Safe(frame.GetCooldownFrame,frame)
    if not Readable(timer) or not timer then return end
    if slot.entry.soundEnabled or slot.entry.onlyWhenTriggered then
        local actual=Safe(function()return frame.isOnActualCooldown end)
        if slot.blizzardAuraActive or (Readable(actual) and actual==true) then
            slot.blizzardEnd=CountdownEnd(timer)
        end
    end
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

local function UpdateSpellColor(slot,group)
    local spell=SpellIconID(slot)
    local usable,noPower=Safe(C_Spell and C_Spell.IsSpellUsable or IsUsableSpell,spell)
    local r,g,b=1,1,1
    local outOfRange=false
    if spell and group.skillRangeRed==true and M.Compat.Bool(Safe(UnitExists,"target")) then
        local base=Number(Safe(C_Spell and C_Spell.GetBaseSpell,slot.spellID))
        local rangeSpell=base and base>0 and base or slot.spellID or spell
        local checks=C_Spell and C_Spell.SpellHasRange
        local hasRange=not checks or Safe(checks,rangeSpell)
        if Readable(hasRange) and (hasRange==true or hasRange==1) then
            local within=Safe(C_Spell and C_Spell.IsSpellInRange or IsSpellInRange,rangeSpell,"target")
            outOfRange=Readable(within) and (within==false or within==0)
        end
    end
    if outOfRange then r,g,b=.64,.15,.15
    elseif Readable(usable) and (usable==false or usable==0)then
        if Readable(noPower) and (noPower==true or noPower==1)then r,g,b=.5,.5,1
        elseif Readable(noPower) then r,g,b=.4,.4,.4 end
    end
    slot.spellR,slot.spellG,slot.spellB=r,g,b
end
local function PaintSpellColor(slot,reversed,faded)
    local r,g,b=slot.spellR,slot.spellG,slot.spellB
    if reversed and slot.entry.type=="blizzard" and (faded==true or (faded==nil and b>r)) then
        -- Vertex tint is applied after desaturation. Use neutral RGB so the
        -- reversed CDM icon stays gray even when the spell lacks resources.
        r,g,b=1,1,1
    end
    if slot.appliedSpellR~=r or slot.appliedSpellG~=g or slot.appliedSpellB~=b then
        slot.texture:SetVertexColor(r,g,b)
        slot.appliedSpellR,slot.appliedSpellG,slot.appliedSpellB=r,g,b
    end
end

local function PaintEffect(slot,now,reversed)
    local effect,aura=slot.effect,slot.effectAura
    local expires=aura and Number(aura.expirationTime)
    local timed=expires and expires>now
    local active=expires and (expires==0 or timed)
    slot.effectExpires=timed and expires or nil
    local stacks=active and aura.applications
    local amount=Number(stacks)
    slot.effectStackCount=nil
    if active then
        if amount then slot.effectStackCount=math.max(1,amount)
        else slot.effectStackCount=stacks end
    end
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
    if native then slot.baseIconFrame:SetAlpha(1)end
    slot.countGate:SetAlpha(1)
    slot.timerGate:SetAlpha(1)
    M.CustomMonitor.SetVisual(slot.cooldown,"SetAlpha",timed and 0 or 1)
    if timed then
        Remaining(slot,expires-now)
    elseif slot.blizzardTimer then
        M.CustomMonitor.SetText(slot.text,slot.blizzardTimer)
    end
    if active then
        M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",reversed)
        return true,timed or slot.blizzardTimer~=nil
    end
    if useNative and slot.effectPresence then
        local present=Safe(slot.effectPresence.IsVisible,slot.effectPresence)
        if type(present)=="boolean" then
            if slot.timerGate.SetAlphaFromBoolean then
                slot.timerGate:SetAlphaFromBoolean(present,0,1)
                slot.countGate:SetAlphaFromBoolean(present,0,1)
                if reversed then slot.baseIconFrame:SetAlphaFromBoolean(present,0,1)end
            elseif Readable(present) then
                local alpha=present and 0 or 1
                slot.timerGate:SetAlpha(alpha);slot.countGate:SetAlpha(alpha)
                if reversed then slot.baseIconFrame:SetAlpha(alpha)end
            end
        end
    end
    if slot.blizzardTimer then return false,true end
end

local stackCurves={}
local function PaintRestrictedStackGlow(slot,count,threshold,now)
    local alpha
    if threshold and not Readable(count) and type(count)=="number" and C_CurveUtil and C_CurveUtil.CreateCurve
        and Enum and Enum.LuaCurveType then
        local curve=stackCurves[threshold]
        if not curve then
            curve=C_CurveUtil.CreateCurve();curve:SetType(Enum.LuaCurveType.Step)
            curve:AddPoint(0,0);curve:AddPoint(threshold,1);stackCurves[threshold]=curve
        end
        alpha=Safe(curve.Evaluate,curve,count)
    end
    local shown=type(alpha)=="number"
    if shown and not slot.restrictedStackGlow then
        slot.restrictedStackGlow=M.CustomMonitor.CreateGlow(slot)
        slot.restrictedStackGlow:SetFrameLevel(slot:GetFrameLevel()+25)
    end
    if slot.restrictedStackGlow then
        if shown then M.CustomMonitor.SetVisual(slot.restrictedStackGlow,"SetAlpha",alpha)end
        PaintSkillGlow(slot,slot.restrictedStackGlow,shown,slot.entry.maxStackGlowColor,now)
    end
end

local function PaintTriggerGlow(slot,shouldGlow,watchCooldown,now,color)
    local alpha=shouldGlow and 1 or 0
    if watchCooldown and not shouldGlow then
        if slot.duration then
            local remaining=Number(Safe(slot.duration.GetRemainingDuration,slot.duration))
            if remaining then
                shouldGlow=remaining>0;alpha=shouldGlow and 1 or 0
            else
                local curve=DisplayCurve(desaturationCurves,false,0,1)
                if curve and slot.duration.EvaluateRemainingDuration then
                    shouldGlow=true;alpha=slot.duration:EvaluateRemainingDuration(curve,0)
                end
            end
        elseif slot.active and slot.expires and slot.expires>now then
            shouldGlow=true;alpha=1
        end
    end
    if shouldGlow and not slot.customGlow then slot.customGlow=M.CustomMonitor.CreateGlow(slot)end
    if slot.customGlow then
        local level=slot:GetFrameLevel()+25
        if slot.customGlow:GetFrameLevel()~=level then slot.customGlow:SetFrameLevel(level)end
        M.CustomMonitor.SetVisual(slot.customGlow,"SetAlpha",alpha)
        PaintSkillGlow(slot,slot.customGlow,shouldGlow,color,now)
    end
end

local function UpdateSkillSound(slot,now,active,expires,nativeTimer)
    local entry=slot.entry
    if not entry.soundEnabled and not entry.onlyWhenTriggered then slot.skillSound=nil;return end
    local state=slot.skillSound
    if not state or state.entry~=entry then
        state={entry=entry,active=active==true}
        slot.skillSound=state
    end
    local completed=state.completedTimer
    state.completedTimer=nil
    local oldEnd=state.expires
    if not state.ended and (completed or (oldEnd and oldEnd<=now)) then
        state.ended=true
        if entry.soundEnabled and entry.soundWhen=="finish" then M.PlayerOtherMonitor.Play(entry)end
    end
    if active==nil then return end
    if active and not state.active then
        state.ended=nil
        if entry.soundEnabled and entry.soundWhen~="finish" then M.PlayerOtherMonitor.Play(entry)end
    end
    if expires and expires>now and (not oldEnd or expires>oldEnd+.25) then state.ended=nil end
    if active then
        -- A live aura may temporarily supply only visibility instead of its
        -- deadline. Keep its clock until it ends or is explicitly replaced.
        if expires then state.expires=expires
        elseif nativeTimer~=state.nativeTimer then state.expires=nil end
        state.nativeTimer=nativeTimer
    elseif not state.castUntil or now>=state.castUntil then
        state.expires,state.nativeTimer,state.ended=nil,nil,nil
    else return end
    state.active=active
end

local function NativeSoundTimer(slot,marker,timer,now)
    local expires=CountdownEnd(timer)
    if expires and expires>now then return true,expires,timer end
    if marker then
        local visible=Safe(marker.IsVisible,marker)
        if Readable(visible) and type(visible)=="boolean" then
            if visible then return true,nil,timer end
            return false
        end
    end
    if timer and slot.auraSoundTimer==timer then return true,nil,timer end
    if expires then return false end
end

local function SpellSoundTimer(slot,now)
    if slot.duration then
        local remaining=Number(Safe(slot.duration.GetRemainingDuration,slot.duration))
        if remaining then return remaining>0,remaining>0 and now+remaining or nil,slot.cooldown end
        local expires=CountdownEnd(slot.cooldown)
        if expires then return expires>now,expires>now and expires or nil,slot.cooldown end
        local running=Safe(slot.duration.IsActive,slot.duration)
        if Readable(running) and type(running)=="boolean" then return running,nil,slot.cooldown end
        return nil,nil,slot.cooldown
    end
    return slot.active==true and slot.expires~=nil and slot.expires>now,slot.expires
end

local function ArmOpaqueSpellSound(slot,now,active,nativeTimer)
    local state=slot.skillSound
    if not state or state.entry~=slot.entry or (slot.entry.soundWhen~="finish" and not slot.entry.onlyWhenTriggered) or not slot.duration
        or nativeTimer~=slot.cooldown then return active,nativeTimer end
    local castIsPending=state.castUntil and now<state.castUntil
    if active==false or (active==nil and not castIsPending and not state.soundTimerArmed)then
        return active,nativeTimer
    end
    if state.soundTimerArmed then return true,slot.soundTimer end
    if state.completedTimer or (state.ended and state.armedCast==state.castUntil)then return active,nativeTimer end
    if not slot.soundTimer then
        local timer=CreateFrame("Cooldown",nil,slot,"CooldownFrameTemplate")
        timer:SetSize(1,1);timer:SetPoint("CENTER");timer:EnableMouse(false)
        timer:SetDrawSwipe(false);timer:SetDrawEdge(false);timer:SetDrawBling(false)
        M.CustomMonitor.SetVisual(timer,"SetHideCountdownNumbers",true);timer.noCooldownCount=true
        ListenForCountdownEnd(slot,timer)
        slot.soundTimer=timer
    end
    local timer=slot.soundTimer
    if not timer.SetCooldownFromDurationObject then return active,nativeTimer end
    if pcall(timer.SetCooldownFromDurationObject,timer,slot.duration,true) then
        state.soundTimerArmed,state.armedCast=true,state.castUntil
        return true,timer
    end
    return active,nativeTimer
end

local function LayoutSkillRow(view,o,entries,group)
    local direction=S.Direction(group)
    local changed=o.rowDirection~=direction
    local count=0
    for i=1,#entries do
        local slot=o.skillIcons[i]
        local entry=slot.entry
        local visible=view.preview or ((entry.type~="blizzard" or slot.effectKnown)
            and (entry.onlyWhenTriggered~=true or slot.triggerVisible==true))
        if visible then count=count+1 end
        if slot.rowVisible~=visible then
            changed=true
            slot.rowVisible=visible
            -- Keep the slot itself shown so native aura children can still
            -- report activation while the icon is excluded from the row.
            if not slot:IsShown() then slot:Show()end
            M.CustomMonitor.SetVisual(slot,"SetAlpha",visible and 1 or 0)
            M.CustomMonitor.SetVisual(slot,"EnableMouse",not view.preview and visible)
        end
    end
    if not changed and o.rowCount==count then return end
    o.rowDirection=direction
    o.rowCount=count
    local width=count>0 and S.IconSize(group)+(count-1)*S.IconPitch(group) or 1
    if o.rowWidth~=width then o.frame:SetSize(width,66);o.rowWidth=width end
    local visibleIndex=0
    for i=1,#entries do
        local slot=o.skillIcons[i]
        if slot.rowVisible then
            visibleIndex=visibleIndex+1
            local x=S.IconOffset(group,visibleIndex,count)
            if slot.rowX~=x then
                slot:ClearAllPoints()
                slot:SetPoint("CENTER",o.frame,"CENTER",x/slot:GetScale(),-7/slot:GetScale())
                slot.rowX=x
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
    if view.preview and not o.skillEditorPreview and #entries==0 then entries=samples end
    if not view.preview then
        local kinds=o.skillKinds
        local spells=kinds.cooldown or kinds.usable or kinds.blizzard or kinds.buffCooldown or kinds.debuffCooldown
        local cooldown=spells and S.MonitorRefreshDue(o,"cooldown",now,.2)
        local info=S.MonitorRefreshDue(o,"info",now,1)
        local gcd=group.skillShowGCD~=false and S.MonitorRefreshDue(o,"gcd",now,.15)
        if cooldown or info or gcd then
            local cooldowns={}
            local blizzardByID,blizzardBySpell
            if cooldown and kinds.blizzard and M.Compat.interface==16001 then
                blizzardByID,blizzardBySpell=Safe(BlizzardHUDIcons)
            end
            for i,entry in ipairs(entries)do
                local slot=o.skillIcons[i]
                if info and slot.needsInfo and now>=(slot.nextInfo or 0) then
                    Resolve(slot,entry);Shortcut(slot,group)
                    if IsSpellIcon(entry) then slot.effectDirty=true end
                    if o.usesNativeAuras and not InCombatLockdown() then BindAura(slot,group.enabled~=false)end
                end
                if IsSpellIcon(entry) then
                    if slot.effectDirty then ResolveEffect(slot,false)end
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
                    if cooldown then
                        if entry.type=="blizzard" and M.Compat.interface==16001 then
                            local native=blizzardByID and (blizzardByID[slot.blizzardID] or blizzardBySpell[slot.spellID])
                            Safe(ReadBlizzardPresentation,slot,native)
                        end
                        local id=SpellIconID(slot)
                        slot.effectGlow=slot.effectKnown and id and (HasSpellActivation(id)
                            or (id~=slot.spellID and slot.spellID and HasSpellActivation(slot.spellID))
                            or (slot.effectRevenge and IsSpellActionUsable(id)))
                        Cooldown(entry,slot,cooldowns)
                        UpdateSpellColor(slot,group)
                        local auraIcon=slot.effectAura and slot.effectAura.icon
                        local spellIcon=Safe(C_Spell and C_Spell.GetSpellTexture,id)
                        local icon=(Readable(auraIcon) and auraIcon) or (Readable(spellIcon) and spellIcon) or slot.customFallbackIcon
                        M.CustomMonitor.SetVisual(slot.texture,"SetTexture",M:TextureFile(icon))
                    end
                end
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
    for i=1,#entries do
        local slot=o.skillIcons[i]
        local textureAlpha=1
        local useCooldownNumbers=false
        local spellFaded
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
            if slot.restrictedStackGlow then slot.restrictedStackGlow:Hide()end
            for _,display in ipairs(slot.nativeGlows or {})do PaintNativeGlow(slot,display,false,now)end
            for _,display in ipairs(slot.nativeStacks or {})do PaintNativeGlow(slot,display,false,now)end
            PaintNativeGlow(slot,slot.effectNativeGlow,false,now)
            PaintNativeGlow(slot,slot.effectNativeStack,false,now)
            if slot.customGlow then ApplySkillGlowBorder(slot.customGlow,nil)end
            ClearCooldown(slot.cooldown);slot.duration=nil
            local result=M.CustomMonitor.Apply(o,slot,view.preview)
            if not view.preview then
                local expires=Number(result.expirationTime)
                slot.triggerVisible=result.show and (not expires or expires>now)
                UpdateSkillSound(slot,now,slot.triggerVisible,expires)
            end
            M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",false);textureAlpha=1
            M.CustomMonitor.SetText(slot.text,result.text or S.FormatCountdown(result.expirationTime and result.expirationTime-now))
            M.CustomMonitor.SetText(slot.count,result.count and tostring(result.count)or "")
            M.CustomMonitor.Glow(slot,result.show and result.glow)
            M.CustomMonitor.SetVisual(slot.customGlow,"SetAlpha",1)
        elseif view.preview then
            local faded=(not o.skillEditorPreview and i%2==1)~=reversed
            ClearCooldown(slot.cooldown);M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",faded)
            textureAlpha=faded and (reversed and reversedOpacity or .5) or 1
            M.CustomMonitor.SetText(slot.text,S.FormatCountdown(30-i))
            M.CustomMonitor.SetText(slot.count,isAura and "3"or "2")
        elseif slot.duration then
            SetCount(slot,slot.spellCount)
            useCooldownNumbers=true
            M.CustomMonitor.SetText(slot.text,"")
            local desat=DisplayCurve(desaturationCurves,reversed,0,1)
            if not slot.cooldownDesaturates then
                spellFaded=reversed
                M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",reversed)
            elseif desat and slot.duration.EvaluateRemainingDuration and slot.texture.SetDesaturation then
                -- The engine consumes this potentially secret number directly.
                M.CustomMonitor.SetVisual(slot.texture,"SetDesaturation",slot.duration:EvaluateRemainingDuration(desat,0))

            else
                local remaining=Number(Safe(slot.duration.GetRemainingDuration,slot.duration))
                if remaining then
                    useCooldownNumbers=false
                    local faded=(remaining>0)~=reversed
                    spellFaded=faded
                    M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",faded);Remaining(slot,remaining)

                end
            end
        elseif useNative then
            M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",reversed);M.CustomMonitor.SetText(slot.text,"");M.CustomMonitor.SetText(slot.count,"")
            textureAlpha=reversed and reversedOpacity or 1
        else
            local active=slot.active and (not slot.expires or slot.expires>now)
            local faded=(active==true)~=reversed
            if IsSpellIcon(slot.entry) and not slot.cooldownDesaturates then faded=reversed end
            spellFaded=faded
            M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",faded);Remaining(slot,active and slot.expires and slot.expires-now or nil)
            if not IsSpellIcon(slot.entry) then textureAlpha=faded and (reversed and reversedOpacity or .5) or 1 end

            if isAura then CountText(slot.count,active and slot.stacks or nil,false)end
            if not isAura then SetCount(slot,slot.spellCount)end
        end
        local effectVisible
        if not view.preview and IsSpellIcon(slot.entry) then
            local hasTextTimer
            effectVisible,hasTextTimer=PaintEffect(slot,now,reversed)
            if hasTextTimer then useCooldownNumbers=false end
            if effectVisible then textureAlpha=1;spellFaded=reversed
            elseif slot.blizzardDesaturated~=nil then
                spellFaded=slot.blizzardDesaturated~=reversed
                M.CustomMonitor.SetVisual(slot.texture,"SetDesaturated",spellFaded)
                textureAlpha=1
            end
            PaintSpellColor(slot,reversed,spellFaded)
            if reversed then
                if spellFaded~=nil then
                    textureAlpha=spellFaded and reversedOpacity or 1
                elseif slot.duration and slot.duration.EvaluateRemainingDuration then
                    local curve=DisplayCurve(reversedOpacityCurves,true,1,reversedOpacity)
                    if curve then textureAlpha=slot.duration:EvaluateRemainingDuration(curve,1)end
                end
            end
        end
        if slot.entry.type~="custom" then
            local entry=slot.entry
            local trigger=not view.preview and TriggerGlowEnabled(entry)
            local active=slot.active and (not slot.expires or slot.expires>now)
            local threshold=not view.preview and StackGlowThreshold(entry,slot.maxCharges)
            local count
            if isAura or entry.type=="equipment" or entry.type=="stance" then
                if active then
                    if type(slot.stacks)=="nil" then count=1 else count=slot.stacks end
                end
            else
                count=slot.spellCount
                if type(count)=="nil" then count=slot.chargeCount end
                if effectVisible and (type(count)=="nil" or not Readable(slot.effectStackCount)
                    or (Number(slot.effectStackCount) or 0)>1) then
                    count=slot.effectStackCount
                end
            end
            local numeric=Number(count)
            if Readable(count) and type(count)=="string" then numeric=tonumber(count)end
            local proc=trigger and (effectVisible==true or slot.effectGlow==true or slot.blizzardAuraActive==true
                or ((isAura or entry.type=="stance" or entry.type=="equipment") and active))
            local full=threshold and numeric and numeric>=threshold
            local color=full and (entry.maxStackGlowColor or whiteGlow) or entry.triggerGlowColor
            PaintTriggerGlow(slot,proc or full or false,trigger and IsSpellIcon(entry),now,color)
            PaintRestrictedStackGlow(slot,count,threshold,now)
            for _,display in ipairs(slot.nativeGlows or {})do
                PaintNativeGlow(slot,display,trigger and not full and useNative,now,entry.triggerGlowColor)
            end
            local useNativeEffect=IsSpellIcon(entry) and slot.effect and not slot.effectNeedsBind and not effectVisible
            PaintNativeGlow(slot,slot.effectNativeGlow,trigger and not proc and not full and useNativeEffect,now,entry.triggerGlowColor)
            for _,display in ipairs(slot.nativeStacks or {})do
                PaintNativeGlow(slot,display,threshold and useNative and display.threshold==threshold,now,entry.maxStackGlowColor)
            end
            local display=slot.effectNativeStack
            if display and display.glow then
                PaintNativeGlow(slot,display,threshold and useNativeEffect and display.threshold==threshold,now,entry.maxStackGlowColor)
            end
            if not view.preview and (entry.soundEnabled or entry.onlyWhenTriggered) then
                local soundActive,expires,nativeTimer=active,active and slot.expires or nil
                local auraUnknown
                if effectVisible then
                    soundActive,expires=true,slot.effectExpires
                elseif useNativeEffect then
                    local nativeActive,finish,timer=NativeSoundTimer(slot,slot.effectPresence,slot.effectNativeSwipe,now)
                    if nativeActive then soundActive,expires,nativeTimer=true,finish,timer
                    else auraUnknown=nativeActive==nil and slot.effectPresence~=nil end
                elseif useNative and not active then
                    for _,watch in ipairs(slot.nativeGlows or {})do
                        local nativeActive,finish,timer=NativeSoundTimer(slot,watch.marker,watch.timer,now)
                        if nativeActive then soundActive,expires,nativeTimer=true,finish,timer;break end
                        if nativeActive==nil then auraUnknown=true end
                    end
                end
                if slot.blizzardEnd and slot.blizzardEnd>now and not expires then
                    soundActive,expires=true,slot.blizzardEnd
                elseif IsSpellIcon(entry) and not expires and not nativeTimer then
                    local running,finish,timer=SpellSoundTimer(slot,now)
                    if not finish then running,timer=ArmOpaqueSpellSound(slot,now,running,timer)end
                    if not soundActive or running then soundActive,expires,nativeTimer=running,finish,timer end
                end
                if not soundActive and auraUnknown then soundActive=nil end
                if slot.effectGlow==true or slot.blizzardAuraActive==true then soundActive=true end
                UpdateSkillSound(slot,now,soundActive,expires,nativeTimer)
                local tracking=slot.skillSound
                slot.triggerVisible=soundActive==true or (soundActive==nil and tracking and tracking.active and not tracking.ended)
            elseif not view.preview then slot.skillSound=nil end
        end
        if not view.preview then
            S.UpdateSkillSwipe(slot,group,now,effectVisible)
            if slot.bindingRevision~=S.bindingRevision then Shortcut(slot,group)end
        end
        M.CustomMonitor.SetVisual(slot.cooldown,"SetHideCountdownNumbers",not useCooldownNumbers)
        M.CustomMonitor.SetVisual(slot.texture,"SetAlpha",textureAlpha)
        M.CustomMonitor.SetVisual(slot.shortcutFrame,"SetAlpha",1)
    end
    LayoutSkillRow(view,o,entries,group)
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
function S.Event(view,event,unit,castGUID,spellID)
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
    if event=="UNIT_SPELLCAST_SUCCEEDED" and Number(spellID) and o.frame:IsShown() then
        local now=GetTime()
        local base=Number(Safe(C_Spell and C_Spell.GetBaseSpell,spellID))
        for _,slot in ipairs(o.skillIcons)do
            local entry=slot.entry
            if entry and (entry.type=="cooldown" or (entry.type=="blizzard" and entry.blizzardCategory~="TrackedBuff")
                or (entry.type=="usable" and entry.onlyWhenTriggered))
                and (entry.onlyWhenTriggered or (entry.soundEnabled and (entry.type=="cooldown" or entry.soundWhen=="finish")))
                and (slot.spellID==spellID or (base and slot.spellID==base) or SpellIconID(slot)==spellID) then
                local state=slot.skillSound
                if not state or state.entry~=entry then state={entry=entry};slot.skillSound=state end
                if not Readable(castGUID) or castGUID==nil or state.castGUID~=castGUID then
                    state.castGUID=Readable(castGUID) and castGUID or nil
                    state.castUntil=now+.75
                    if entry.soundEnabled and entry.type=="cooldown" then state.active=true end
                    state.soundTimerArmed=nil
                    if entry.soundEnabled and entry.type=="cooldown" and entry.soundWhen~="finish" then
                        M.PlayerOtherMonitor.Play(entry)
                    end
                    if slot.duration or (Number(Safe(GetSpellBaseCooldown or (C_Spell and C_Spell.GetSpellBaseCooldown),spellID)) or 0)>0
                        or (slot.maxCharges or 0)>1 then
                        state.nativeTimer=slot.cooldown
                        state.ended=nil
                    elseif not entry.soundEnabled then
                        state.castUntil=nil
                    end
                end
            end
        end
    end
    if event=="ACTIONBAR_PAGE_CHANGED" or event=="UPDATE_BONUS_ACTIONBAR" or event=="UPDATE_BINDINGS" then
        -- Shortcut labels update via bindingRevision. Paging may change
        -- action usability, but it must not tear down a live aura timer.
        S.InvalidateMonitor(o,"cooldown",true)
    elseif event=="UNIT_AURA" then
        for _,kind in ipairs(auraKinds)do
            if auraTypes[kind].unit==unit then S.InvalidateMonitor(o,kind)end
        end
        if unit=="player" then S.InvalidateMonitor(o,"special")end
        S.InvalidateMonitor(o,"cooldown")
    elseif event=="PLAYER_EQUIPMENT_CHANGED" or event=="UPDATE_SHAPESHIFT_FORM" or event=="UPDATE_SHAPESHIFT_FORMS" then
        S.InvalidateMonitor(o,"special",true)
    elseif event=="PLAYER_TARGET_CHANGED" then
        o.nativeTargetGeneration=nil
        S.InvalidateMonitor(o,"debuff",true);S.InvalidateMonitor(o,"targetBuff",true)
        for _,slot in ipairs(o.skillIcons)do
            if slot.effect and (slot.effect.unit=="target" or slot.effect.alternate)then slot.effectAura=nil end
            local aura=slot.entry and auraTypes[slot.entry.type]
            if (aura and aura.unit=="target") or (slot.effect and slot.effect.unit=="target")then slot.skillSound=nil end
        end
        S.InvalidateMonitor(o,"cooldown",true)
    elseif activation or event=="SPELL_UPDATE_USABLE" or event=="ACTIONBAR_UPDATE_USABLE" or event=="ACTIONBAR_SLOT_CHANGED" then
        S.InvalidateMonitor(o,"cooldown",activation)
    elseif event=="SPELL_UPDATE_COOLDOWN" or event=="SPELL_UPDATE_CHARGES" or event=="SPELL_UPDATE_USES" or event=="UNIT_SPELLCAST_SUCCEEDED" then
        S.InvalidateMonitor(o,"gcd")
        S.InvalidateMonitor(o,"cooldown")
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
        {name="Buff/Debuff",path="aura"},{name="触发法术",path="usable"},
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
    local panel,panelRow=Panel(271,"skillMonitorEntry");e.skillMonitorPanel=panel
    local function Flush()
        if panel.edit and panel.edit:HasFocus() then panel.edit:ClearFocus() end
        if panel.soundInput and panel.soundInput:HasFocus() then panel.soundInput:ClearFocus() end
    end
    local back=W.Button(panel,"返回",96,function()
        Flush()
        e.skillEntry=nil;e.propScroll:SetVerticalScroll(0)
        M:RefreshEditor(true)
    end)
    back:SetPoint("TOPLEFT",0,0)
    local backIcon=back:CreateTexture(nil,"OVERLAY");backIcon:SetSize(16,16)
    backIcon:SetPoint("LEFT",6,0)
    backIcon:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
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
        {"超出法术距离变红","skillRangeRed"},
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
                elseif owner then globals[key]:SetChecked(SkillChecked(owner,key))end
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
        local function Choices()return type(options)=="function" and options() or options end
        local button
        button=W.MediaSelect(panel,label,width,"choice",function()
            if button.menu then button.menu:Hide();return end
            local owner,entry=panel.owner,panel.entry
            W.MediaMenu(button,Choices(),"choice",button.value,function(choice)
                if panel.owner==owner and panel.entry==entry then Update(function(item)change(item,choice.path)end)end
            end)
        end)
        function button:SetValue(value)
            self.value=value
            for _,choice in ipairs(Choices())do
                if choice.path==value then self:SetMedia(choice.name,value);return end
            end
            self:SetMedia(value,value)
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
    kind:SetPoint("TOPLEFT",0,-34)
    local unit=Choice("单位",{{name="玩家",path="player"},{name="目标",path="target"}},115,function(entry,value)
        entry.type=AuraKind(value,Harmful(entry))
    end)
    unit:SetPoint("TOPLEFT",160,-34)
    local filter=Choice("类型",{{name="Buff",path="buff"},{name="Debuff",path="debuff"}},115,function(entry,value)
        if auraTypes[entry.type] then entry.type=AuraKind(auraTypes[entry.type].unit,value=="debuff")end
    end)
    filter:SetPoint("TOPLEFT",285,-34)
    local equipmentSlots={}
    for slot=1,19 do
        local name=({"HEADSLOT","NECKSLOT","SHOULDERSLOT","SHIRTSLOT","CHESTSLOT","WAISTSLOT","LEGSSLOT","FEETSLOT",
            "WRISTSLOT","HANDSSLOT","FINGER0SLOT","FINGER1SLOT","TRINKET0SLOT","TRINKET1SLOT","BACKSLOT","MAINHANDSLOT",
            "SECONDARYHANDSLOT","RANGEDSLOT","TABARDSLOT"})[slot]
        equipmentSlots[slot]={name=_G[name] or tostring(slot),path=tostring(slot)}
    end
    local equipment=Choice("装备位置",equipmentSlots,190,function(entry,value)entry.slot=tonumber(value)end)
    equipment:SetPoint("TOPLEFT",160,-34)

    local icon=CreateFrame("Button",nil,panel);icon:SetSize(26,26);icon:SetPoint("TOPLEFT",0,-92)
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
        check:SetPoint("TOPLEFT",-4,y-34)
        return check
    end
    local onlyWhenTriggered=EntryCheck("仅触发时显示","onlyWhenTriggered",-96)
    local glow=EntryCheck("触发发光","triggerGlow",-129)
    local maxGlow=EntryCheck("最大层数发光","maxStackGlow",-162)
    local reverse=EntryCheck("反转褪色效果","reverseDisplay",-195)
    local onlyMine=EntryCheck("只来源于自己","onlyMine",-228)
    local function GlowColor(check,key)
        local owner,entry
        local swatch=W.ColorSwatch(panel,function(color)
            if Editable(owner,entry)then entry[key]=M.Copy(color);M:Commit()end
        end)
        swatch:SetPoint("LEFT",check.label,"RIGHT",12,0)
        local open=swatch:GetScript("OnClick")
        swatch:SetScript("OnClick",function(button)
            Flush()
            owner,entry=panel.owner,panel.entry
            if Editable(owner,entry)then open(button)end
        end)
        return swatch
    end
    local triggerColor=GlowColor(glow,"triggerGlowColor")
    local stackColor=GlowColor(maxGlow,"maxStackGlowColor")
    local playSound=EntryCheck("播放声音","soundEnabled",-261)
    local when=Choice("播放时机",{{name="触发开始时播放",path="start"},{name="触发结束时播放",path="finish"}},208,
        function(entry,value)entry.soundWhen=value end)
    when:SetPoint("TOPLEFT",0,-325)
    local sound=Choice("音效",M.PlayerOtherMonitor.Sounds,270,function(entry,value)entry.sound=value end)
    sound:SetPoint("TOPLEFT",0,-379)
    local hear=W.Button(panel,"试听",72,function()
        Flush()
        if Editable(panel.owner,panel.entry)then M.PlayerOtherMonitor.Play(panel.entry)end
    end)
    hear:SetPoint("LEFT",sound,"RIGHT",12,-11)
    local soundLabel=W.Label(panel,"声音文件路径",11);soundLabel:SetPoint("TOPLEFT",0,-430)
    local soundInput=W.Edit(panel,340);panel.soundInput=soundInput
    soundInput:SetPoint("TOPLEFT",0,-447);soundInput:SetMaxLetters(512);soundInput:SetTextInsets(6,6,0,0)
    soundInput:SetScript("OnEditFocusGained",function(self)
        self.owner,self.entry=panel.owner,panel.entry
        self.field=self.entry and (self.entry.sound=="id" and "soundID" or "soundPath")
    end)
    soundInput:SetScript("OnEditFocusLost",function(self)
        local owner,entry,key=self.owner,self.entry,self.field
        self.owner,self.entry,self.field=nil,nil,nil
        if key and Editable(owner,entry)then
            local value=S.Input(self:GetText())
            if (entry[key] or "")~=value then entry[key]=value;M:Commit()end
        end
    end)
    soundInput:SetScript("OnEnterPressed",function(self)self:ClearFocus()end)
    soundInput:SetScript("OnEscapePressed",function(self)
        if self.entry then self:SetText(self.entry[self.field] or "")end
        self:ClearFocus()
    end)
    panel:SetScript("OnHide",function()
        Flush()
        for _,button in ipairs({kind,unit,filter,equipment,when,sound})do if button.menu then button.menu:Hide()end end
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
            else control:SetChecked(SkillChecked(owner,key))end
            control.updating=false
        end
        if self.entry~=entry or self.owner~=owner then
            Flush()
            for _,button in ipairs({kind,unit,filter,equipment,when,sound})do if button.menu then button.menu:Hide()end end
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
        onlyWhenTriggered:SetChecked(entry.onlyWhenTriggered==true)
        glow:SetChecked(TriggerGlowEnabled(entry))
        maxGlow:SetChecked(entry.maxStackGlow==true)
        triggerColor:SetColor(entry.triggerGlowColor or whiteGlow)
        stackColor:SetColor(entry.maxStackGlowColor or whiteGlow)
        reverse:SetChecked(entry.reverseDisplay==true)
        onlyMine:SetShown(aura~=nil or combined~=nil or (entry.type=="blizzard" and entry.blizzardCategory=="TrackedBuff"))
        onlyMine:SetChecked(entry.onlyMine~=false)
        local soundEnabled=entry.soundEnabled==true
        local selectedSound=entry.sound or "kit:8960"
        local extended=soundEnabled and (selectedSound=="id" or selectedSound=="custom")
        playSound:SetChecked(soundEnabled)
        -- Pull the sound row up for entries without the aura-source checkbox.
        local offset=(aura or combined or (entry.type=="blizzard" and entry.blizzardCategory=="TrackedBuff")) and 0 or 33
        playSound:SetPoint("TOPLEFT",-4,-295+offset)
        when:SetPoint("TOPLEFT",0,-325+offset);sound:SetPoint("TOPLEFT",0,-379+offset)
        soundLabel:SetPoint("TOPLEFT",0,-430+offset);soundInput:SetPoint("TOPLEFT",0,-447+offset)
        when:SetShown(soundEnabled);sound:SetShown(soundEnabled);hear:SetShown(soundEnabled)
        soundLabel:SetShown(extended);soundInput:SetShown(extended)
        panelRow.height=(extended and 482 or (soundEnabled and 430 or 333))-offset
        panel:SetHeight(panelRow.height)
        if soundEnabled then when:SetValue(entry.soundWhen or "start");sound:SetValue(selectedSound)end
        if extended then
            soundLabel:SetText(selectedSound=="id" and "音效ID" or "声音文件路径")
            if not soundInput:HasFocus()then
                soundInput:SetText(entry[selectedSound=="id" and "soundID" or "soundPath"] or "")
            end
        end
    end
end
