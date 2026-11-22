local _,M=...
local C=M.Compat
local V={}
M.AttackVoice=V
local MODULE="attackVoice"
V.channelChoices={
    {"Master","主音量"},{"SFX","音效"},{"Music","音乐"},{"Ambience","环境音"},{"Dialog","对白"},
}
local validChannels={}
for _,choice in ipairs(V.channelChoices) do validChannels[choice[1]]=true end

function V.Channel(node,stage)
    local channel=node and node["attackVoiceChannel"..stage]
    return validChannels[channel] and channel or (stage=="Attack" and "SFX" or "Dialog")
end

local clientLocale=GetLocale()
local defaultDialogueLanguage=(clientLocale=="zhCN" or clientLocale=="zhTW") and "zhCN" or "enUS"

function V.DialogueLanguage(node)
    local locale=node and node.attackVoiceLanguage
    if locale=="zhCN" or locale=="enUS" then return locale end
    return defaultDialogueLanguage
end

local dialogueStages={"Target","Combat","Cast","After","Death"}
local dialogueDefaults={Target=.2,Combat=.3,Cast=.3,After=.2,Death=1}
local dialogueRaceAliases={
    KulTiran="Human", DarkIronDwarf="Dwarf", EarthenDwarf="Dwarf", Earthen="Dwarf",
    Nightborne="NightElf", Haranir="NightElf", VoidElf="BloodElf", Mechagnome="Gnome",
    LightforgedDraenei="Draenei", MagharOrc="Orc", HighmountainTauren="Tauren", ZandalariTroll="Troll",
}

-- Unit spellcast events report successful abilities even where the combat log is restricted.
-- Keep the list explicit so heals, ranged attacks and spells cast at point-blank range stay silent.
local meleeSpells={
    53,284,6572,6760,7384,1464,1680,23881,23922,20243,
    12294,34428,167105,163201,184367,85288,385059,46968,5308,
    1752,2098,1833,8676,185438,32645,1329,703,1943,16511,51723,152150,193315,185763,200758,315496,
    1822,5221,22568,33876,33917,1079,106830,213764,106785,202028,274837,155625,202021,80313,
    35395,53385,53595,85256,184575,255937,343527,427453,
    17364,60103,187874,115356,342240,384352,
    49998,45462,45902,55090,49020,49143,130735,194913,207230,207311,206930,
    100780,100784,107428,113656,101546,121253,205523,261947,152175,322109,322729,392983,
    162243,162794,188499,210152,201427,258920,225919,228477,263642,232893,
    186270,259387,259391,187708,400456,
}
-- Classic replaces the next weapon swing with these abilities.
local queuedSpells={78,845,6807,2973,56815}
local meleeByID,queuedByID,meleeByName,queuedByName={},{},{},{}
local function IndexSpells(ids,byID,byName)
    for _,id in ipairs(ids) do
        byID[id]=true
        local name
        if C_Spell and C_Spell.GetSpellName then name=C_Spell.GetSpellName(id)
        elseif GetSpellInfo then name=GetSpellInfo(id) end
        if C.Readable(name) and type(name)=="string" then byName[name]=true end
    end
end
local function HasSpell(byID,byName,id,name)
    return C.Number(id) and byID[id] or C.Readable(name) and type(name)=="string" and byName[name]
end
local function IsMeleeSkill(id)
    local classicQueue=(C.interface or 0)<40000
    if classicQueue and queuedByID[id] then return false end
    if meleeByID[id] then return true end
    if not classicQueue then return false end
    local name
    if C_Spell and C_Spell.GetSpellName then name=C_Spell.GetSpellName(id)
    elseif GetSpellInfo then name=GetSpellInfo(id) end
    return not HasSpell(queuedByID,queuedByName,id,name) and HasSpell(meleeByID,meleeByName,id,name)
end

local function IsInstantSpell(id)
    -- Auto attacks and Classic queued swings already use the weapon event.
    if id==6603 or id==75 or id==5019 then return false end
    local passive=C_Spell and C_Spell.IsSpellPassive or IsPassiveSpell
    if passive and C.Bool(passive(id)) then return false end
    local name,castTime
    if C_Spell and C_Spell.GetSpellInfo then
        local info=C_Spell.GetSpellInfo(id)
        if not C.Readable(info) or type(info)~="table"
            or (canaccesstable and not canaccesstable(info)) then return false end
        name,castTime=info.name,info.castTime
    elseif GetSpellInfo then
        local spellName,_,_,duration=GetSpellInfo(id)
        name,castTime=spellName,duration
    end
    if (C.interface or 0)<40000 and HasSpell(queuedByID,queuedByName,id,name) then return false end
    return C.Number(castTime)==0
end

function M:EnsureAttackVoiceModule(design)
    for _,node in ipairs(design.nodes) do
        if node.id==MODULE then
            node.label="人声增强"
            if node.attackVoiceEnabled~=nil then
                node.enabled=node.enabled~=false and node.attackVoiceEnabled==true
                node.attackVoiceEnabled=nil
            end
            if node.attackVoiceChance==nil then node.attackVoiceChance=.5 end
            node.attackVoiceLanguage=V.DialogueLanguage(node)
            node.attackVoiceChannelAttack=V.Channel(node,"Attack")
            for _,stage in ipairs(dialogueStages) do
                local key="attackVoiceDialogue"..stage
                if node[key]==nil then node[key]=dialogueDefaults[stage] end
                node["attackVoiceChannel"..stage]=V.Channel(node,stage)
            end
            return
        end
    end
    local node={
        id=MODULE,label="人声增强",kind="group",compound=MODULE,scope="player",unit="player",
        x=0,y=0,width=2,height=2,scale=1,point="CENTER",anchor="CENTER",alpha=0,
        enabled=false,attackVoiceChance=.5,attackVoiceChannelAttack="SFX",attackVoiceLanguage=defaultDialogueLanguage,
        layer=500,rules={},conditions={},
    }
    for _,stage in ipairs(dialogueStages) do
        node["attackVoiceDialogue"..stage]=dialogueDefaults[stage]
        node["attackVoiceChannel"..stage]=V.Channel(node,stage)
    end
    design.nodes[#design.nodes+1]=node
end
M.moduleIDs[MODULE]=true
M:EnsureAttackVoiceModule(M.defaults)
if M.recordedDefaults then M:EnsureAttackVoiceModule(M.recordedDefaults) end

local raceVoices={
    {"Human","人类"},
    {"Dwarf","矮人"},
    {"NightElf","暗夜精灵"},
    {"BloodElf","血精灵"},
    {"Gnome","侏儒"},
    {"Draenei","德莱尼"},
    {"Orc","兽人"},
    {"Tauren","牛头人"},
    {"Troll","巨魔"},
    {"Goblin","地精"},
    {"Vulpera","狐人"},
    {"Pandaren","熊猫人"},
    {"Worgen","狼人"},
    {"Dracthyr","龙希尔"},
    {"Scourge","亡灵"},
}
local voiceOptions={{path="default"}}
local voicesByID={}
for _,race in ipairs(raceVoices) do
    for sex=2,3 do
        local option={path=race[1]..":"..sex,race=race[1],label=race[2],sex=sex}
        voiceOptions[#voiceOptions+1]=option
        voicesByID[option.path]=option
    end
end

function V.SelectedVoice()
    local saved=type(MangUICharacterDB)=="table" and MangUICharacterDB.attackVoiceID
    return voicesByID[saved] and saved or "default"
end

local function VoiceLabel(option)
    if not option.race then return M:T("默认") end
    return M:T(option.sex==2 and "%s男" or "%s女"):format(M:T(option.label))
end

function V.VoiceChoices()
    local items={}
    for _,option in ipairs(voiceOptions) do
        items[#items+1]={path=option.path,name=VoiceLabel(option)}
    end
    return items
end

function V.SelectedVoiceLabel()
    return VoiceLabel(voicesByID[V.SelectedVoice()] or voiceOptions[1])
end

local function PlayerVoice()
    local name,race=UnitRace("player")
    local sex=C.Number(UnitSex("player"))
    if not C.Readable(race) or not C.Readable(name) or type(race)~="string" then return end
    if C.interface==16001 then
        local token=race:lower():gsub("[^a-z]","")
        if token:find("skyborne",1,true) or token:find("sendorei",1,true) or token=="tianyi"
            or type(name)=="string" and (name:find("天裔",1,true) or name:find("天弈",1,true)) then
            race="Nightborne"
        end
    end
    return race,sex
end

local function DialogueVoice(race,sex)
    local option=voicesByID[V.SelectedVoice()]
    if option then return option.race,option.sex end
    return dialogueRaceAliases[race] or race,sex
end

local function VoiceSounds(race,sex)
    local pool=race and M.AttackVoiceSounds[race]
    return pool and (sex==2 and pool[1] or sex==3 and pool[2] or nil)
end

local function UpdatePlayer()
    V.attackRace,V.attackSex=PlayerVoice()
    V.sounds=VoiceSounds(V.attackRace,V.attackSex)
    V.dialogueRace,V.dialogueSex=DialogueVoice(V.attackRace,V.attackSex)
    V.guid=UnitGUID("player")
end

function V.SetVoice(value)
    if value~="default" and not voicesByID[value] then return end
    if type(MangUICharacterDB)~="table" then MangUICharacterDB={} end
    MangUICharacterDB.attackVoiceID=voicesByID[value] and value or nil
    if V.previewHandle and StopSound then StopSound(V.previewHandle);V.previewHandle=nil end
    if V.enabled then UpdatePlayer() end
    M:RefreshProperties()
end

local function DialoguePlaying()
    return V.dialogueEnds and GetTime()<V.dialogueEnds
end

local function PlayerHealthPercent()
    local health=C.Number(UnitHealth("player"))
    local maximum=C.Number(UnitHealthMax("player"))
    if health and maximum and maximum>0 then return health/maximum*100 end
    if UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then
        local ok,value=pcall(UnitHealthPercent,"player",true,CurveConstants.ScaleTo100)
        if ok then return C.Number(value) end
    end
end

local function DialogueGroup(stage)
    if stage~="After" then return end
    local percent=PlayerHealthPercent()
    if not percent then return end
    if percent<50 then return "AfterLow" end
    return percent>=80 and "AfterHigh" or "AfterNormal"
end

local function DialoguePath(locale,pool,clip)
    return M.ART..("Sounds\\AttackDialogue\\%s\\%s\\%s.ogg"):format(locale,pool.folder,clip[1])
end

local function AttackPath(id)
    return M.ART.."Sounds\\AttackVoice\\"..id..".ogg"
end

local function DialoguePool(locale,race,sex)
    local language=M.AttackVoiceDialogue[locale]
    local bodies=language and race and language[race]
    return bodies and bodies[sex]
end

local function RandomAttackPath(race,sex,locale,sounds)
    if sounds and #sounds>0 then return AttackPath(sounds[math.random(#sounds)]) end
    -- Races without bundled strike effects can still use their own voice.
    local pool=DialoguePool(locale,race,sex)
    local combat=pool and pool.Combat
    if combat and #combat>0 then
        return DialoguePath(locale,pool,combat[math.random(#combat)])
    end
end

function V.Preview(node,stage)
    if type(PlaySoundFile)~="function" then return end
    local playerRace,playerSex=PlayerVoice()
    local locale=V.DialogueLanguage(node)
    local path
    if stage=="Attack" then
        path=RandomAttackPath(playerRace,playerSex,locale,VoiceSounds(playerRace,playerSex))
    else
        local race,sex=DialogueVoice(playerRace,playerSex)
        local pool=DialoguePool(locale,race,sex)
        if not pool then return end
        local groups=stage=="After" and {"After","AfterLow","AfterNormal","AfterHigh"} or {stage}
        local candidates={}
        for _,group in ipairs(groups) do
            for _,clip in ipairs(pool[group] or {}) do
                candidates[#candidates+1]=clip
            end
        end
        if #candidates>0 then path=DialoguePath(locale,pool,candidates[math.random(#candidates)]) end
    end
    if not path then return end
    if V.previewHandle and StopSound then StopSound(V.previewHandle) end
    local played,handle=PlaySoundFile(path,V.Channel(node,stage))
    V.previewHandle=played and handle or nil
end

local function PlayDialogue(stage)
    local chance=V.dialogueChance[stage]
    if not V.dialogueRace or not chance or chance<=0 then return end
    local playing=DialoguePlaying()
    local priority=stage=="After" or stage=="Death"
    if playing and (not priority or not V.dialogueHandle or not StopSound) then return end
    local locale=V.locale
    local pools=DialoguePool(locale,V.dialogueRace,V.dialogueSex)
    local clips=pools and pools[stage]
    if not clips or #clips==0 then return end
    local now=GetTime()
    if stage=="Combat" then
        if now<(V.nextCombatDialogue or 0) then return end
        V.nextCombatDialogue=now+4
    end
    if chance<1 and math.random()>=chance then return end
    local group=DialogueGroup(stage)
    local extra=group and pools[group]
    local index=math.random(#clips+(extra and #extra or 0))
    if index>#clips then
        index=index-#clips
        stage,clips=group,extra
    end
    local clip=clips[index]
    local played,handle=PlaySoundFile(DialoguePath(locale,pools,clip),V.channels[stage])
    if played then
        if playing then StopSound(V.dialogueHandle) end
        V.dialogueEnds=now+clip[2]
        V.dialogueHandle=handle
    end
end

local function PlayAttack()
    if V.inCombat then PlayDialogue("Combat") end
    if DialoguePlaying() then return end
    if V.chance<=0 or V.chance<1 and math.random()>=V.chance then return end
    local path=RandomAttackPath(V.attackRace,V.attackSex,V.locale,V.sounds)
    if path then PlaySoundFile(path,V.channels.Attack) end
end

local function CombatLog(_,event,_,source,_,_,_,_,_,_,_,spellID,spellName)
    if not C.Readable(event) or not C.Readable(source) or not C.Readable(V.guid) or not V.guid or source~=V.guid then return end
    if event=="SWING_DAMAGE" or event=="SWING_MISSED"
        or ((C.interface or 0)<40000 and (event=="SPELL_DAMAGE" or event=="SPELL_MISSED")
            and HasSpell(queuedByID,queuedByName,spellID,spellName)) then
        PlayAttack()
    end
end

local function OnEvent(_,event,arg1,arg2,arg3)
    if event=="PLAYER_ENTERING_WORLD" then
        UpdatePlayer()
        V.inCombat=C.Bool(UnitAffectingCombat("player"))
        IndexSpells(meleeSpells,meleeByID,meleeByName)
        IndexSpells(queuedSpells,queuedByID,queuedByName)
    elseif event=="PLAYER_TARGET_CHANGED" then
        if C.Bool(UnitCanAttack("player","target")) and not C.Bool(UnitIsDeadOrGhost("target")) then
            PlayDialogue("Target")
        end
    elseif event=="PLAYER_REGEN_DISABLED" then
        V.inCombat=true
        V.nextCombatDialogue=nil
    elseif event=="PLAYER_DEAD" then
        V.inCombat=false
        PlayDialogue("Death")
    elseif event=="PLAYER_REGEN_ENABLED" then
        if V.inCombat and not C.Bool(UnitIsDeadOrGhost("player")) then PlayDialogue("After") end
        V.inCombat=false
    elseif event=="COMBAT_LOG_EVENT_UNFILTERED" then
        if C.CombatLogAvailable() then CombatLog(CombatLogGetCurrentEventInfo()) end
    elseif event=="PLAYER_SWING" then
        local kind=C.Number(arg2)
        local duration=C.Number(arg1,0)
        local swing=Enum and Enum.PlayerSwingType
        if duration>0 and (kind==(swing and swing.MainHand or 0) or kind==(swing and swing.OffHand or 1)) then
            PlayAttack()
        end
    elseif arg1=="player" then
        if event=="UNIT_SPELLCAST_START" then
            V.castGUID=C.Readable(arg2) and arg2 or nil
            PlayDialogue("Cast")
        elseif event=="UNIT_SPELLCAST_SUCCEEDED" then
            local wasCast=V.castGUID and C.Readable(arg2) and arg2==V.castGUID
            if wasCast then
                V.castGUID=nil
                return
            end
            local spellID=C.Number(arg3)
            if spellID and (IsMeleeSkill(spellID) or IsInstantSpell(spellID)) then PlayAttack() end
        end
    end
end

function V.Configure(view)
    if view.preview then return end
    local module=view.byID[MODULE]
    V.locale=V.DialogueLanguage(module)
    V.chance=module and M.Clamp(tonumber(module.attackVoiceChance) or .5,0,1) or 0
    V.dialogueChance=V.dialogueChance or {}
    V.channels=V.channels or {}
    V.channels.Attack=V.Channel(module,"Attack")
    local hasChance=V.chance>0
    for _,stage in ipairs(dialogueStages) do
        local chance=module and M.Clamp(tonumber(module["attackVoiceDialogue"..stage]) or dialogueDefaults[stage],0,1) or 0
        V.dialogueChance[stage]=chance
        V.channels[stage]=V.Channel(module,stage)
        hasChance=hasChance or chance>0
    end
    local enabled=module and module.enabled~=false
        and hasChance and type(PlaySoundFile)=="function" or false
    if enabled==V.enabled then return end
    V.enabled=enabled
    if not enabled then
        if V.frame then V.frame:UnregisterAllEvents() end
        return
    end
    if not V.frame then
        V.frame=CreateFrame("Frame")
        V.frame:SetScript("OnEvent",OnEvent)
    end
    V.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    V.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    V.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    V.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    V.frame:RegisterEvent("PLAYER_DEAD")
    V.frame:RegisterUnitEvent("UNIT_SPELLCAST_START","player")
    V.frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED","player")
    if C.CombatLogAvailable() then
        V.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        pcall(V.frame.RegisterEvent,V.frame,"PLAYER_SWING")
    end
    OnEvent(V.frame,"PLAYER_ENTERING_WORLD")
end
