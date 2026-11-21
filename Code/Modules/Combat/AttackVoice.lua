local _,M=...
local C=M.Compat
local V={}
M.AttackVoice=V
local MODULE="attackVoice"
local dialogueStages={"Target","Combat","Cast","After","Death"}
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
            for _,stage in ipairs(dialogueStages) do
                local key="attackVoiceDialogue"..stage
                if node[key]==nil then node[key]=0 end
            end
            return
        end
    end
    design.nodes[#design.nodes+1]={
        id=MODULE,label="音效增强",kind="group",compound=MODULE,scope="player",unit="player",
        x=0,y=0,width=2,height=2,scale=1,point="CENTER",anchor="CENTER",alpha=0,
        enabled=true,attackVoiceEnabled=false,attackVoiceChance=.5,
        attackVoiceDialogueTarget=0,attackVoiceDialogueCombat=0,attackVoiceDialogueAfter=0,
        attackVoiceDialogueDeath=0,attackVoiceDialogueCast=0,
        layer=500,rules={},conditions={},
    }
end
M.moduleIDs[MODULE]=true
M:EnsureAttackVoiceModule(M.defaults)
if M.recordedDefaults then M:EnsureAttackVoiceModule(M.recordedDefaults) end

local function UpdatePlayer()
    V.dialogueRace,V.dialogueSex=nil,nil
    local name,race=UnitRace("player")
    local sex=C.Number(UnitSex("player"))
    V.guid=UnitGUID("player")
    if not C.Readable(race) or not C.Readable(name) then V.sounds=nil;return end
    if C.interface==16001 then
        local token=type(race)=="string" and race:lower():gsub("[^a-z]","") or ""
        if token:find("skyborne",1,true) or token:find("sendorei",1,true) or token=="tianyi"
            or type(name)=="string" and (name:find("天裔",1,true) or name:find("天弈",1,true)) then
            race="Nightborne"
        end
    end
    local pool=race and M.AttackVoiceSounds[race]
    V.sounds=pool and (sex==2 and pool[1] or sex==3 and pool[2] or nil)
    V.dialogueRace,V.dialogueSex=dialogueRaceAliases[race] or race,sex
    V.failedSounds={}
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

local function PlayDialogue(stage)
    local chance=V.dialogueChance[stage]
    if not V.dialogueRace or not chance or chance<=0 then return end
    local playing=DialoguePlaying()
    local priority=stage=="After" or stage=="Death"
    if playing and (not priority or not V.dialogueHandle or not StopSound) then return end
    local language=M:EffectiveLanguage()
    local locale=(language=="zhCN" or language=="zhTW") and "zhCN" or "enUS"
    local languagePools=M.AttackVoiceDialogue[locale]
    local racePools=languagePools and languagePools[V.dialogueRace]
    local pools=racePools and racePools[V.dialogueSex]
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
    local path=M.ART..("Sounds\\AttackDialogue\\%s\\%s\\%s.ogg"):format(locale,pools.folder,clip[1])
    local played,handle=PlaySoundFile(path,"Dialog")
    if played then
        if playing then StopSound(V.dialogueHandle) end
        V.dialogueEnds=now+clip[2]
        V.dialogueHandle=handle
    end
end

local function PlayAttack()
    if V.inCombat then PlayDialogue("Combat") end
    if DialoguePlaying() then return end
    local pool=V.sounds
    if not pool or V.chance<=0 or V.chance<1 and math.random()>=V.chance then return end
    local first=math.random(#pool)
    for offset=0,#pool-1 do
        local id=pool[(first+offset-1)%#pool+1]
        if not V.failedSounds[id] then
            local path=M.ART.."Sounds\\AttackVoice\\"..id..".ogg"
            if PlaySoundFile(path,"SFX") then return end
            V.failedSounds[id]=true
        end
    end
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
    V.chance=module and M.Clamp(tonumber(module.attackVoiceChance) or .5,0,1) or 0
    V.dialogueChance=V.dialogueChance or {}
    local hasChance=V.chance>0
    for _,stage in ipairs(dialogueStages) do
        local chance=module and M.Clamp(tonumber(module["attackVoiceDialogue"..stage]) or 0,0,1) or 0
        V.dialogueChance[stage]=chance
        hasChance=hasChance or chance>0
    end
    local enabled=module and module.enabled~=false and module.attackVoiceEnabled==true
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
