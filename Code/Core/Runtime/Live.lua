local _,M=...
local R,C=M.Renderer,M.Compat
local bossHealthInterval=.2

local function RaidInstance()
    if not IsInInstance then return false end
    local inside,kind=IsInInstance()
    return C.Bool(inside) and C.Readable(kind) and kind=="raid"
end

local function EnemyBossTarget()
    if not C.Bool(UnitExists("target")) then return false end
    local attackable=UnitCanAttack and UnitCanAttack("player","target")
    if not C.Readable(attackable) or attackable==nil then
        local friendly=UnitIsFriend and UnitIsFriend("player","target")
        attackable=C.Readable(friendly) and friendly==false
    end
    if not attackable then return false end
    local classification=UnitClassification and UnitClassification("target")
    if C.Readable(classification) and classification=="worldboss" then return true end
    if UnitIsUnit then
        for i=1,5 do
            if C.Bool(UnitIsUnit("target","boss"..i)) then return true end
        end
    end
    return false
end
-- Cold login can report font assignment success before glyph assets settle.
-- Finite refreshes rebuild glyphs after loading; never retry healthy fonts forever.
local fontSettleDelays={.5,2,5,10,20,40,60,90}
local independentEvents={ITEM_DATA_LOAD_RESULT=true,SPELL_UPDATE_COOLDOWN=true,SPELL_UPDATE_CHARGES=true,BAG_UPDATE_COOLDOWN=true,
    SPELL_UPDATE_USABLE=true,ACTIONBAR_UPDATE_USABLE=true,ACTIONBAR_SLOT_CHANGED=true,
    UPDATE_SHAPESHIFT_FORM=true,UPDATE_SHAPESHIFT_FORMS=true,
    SPELL_ACTIVATION_OVERLAY_GLOW_SHOW=true,SPELL_ACTIVATION_OVERLAY_GLOW_HIDE=true,
    PLAYER_STARTED_TURNING=true,PLAYER_STOPPED_TURNING=true,PLAYER_STARTED_LOOKING=true,PLAYER_STOPPED_LOOKING=true}
local cooldownEvents={UNIT_SPELLCAST_SUCCEEDED=true,SPELL_UPDATE_COOLDOWN=true,SPELL_UPDATE_CHARGES=true,
    PLAYER_REGEN_DISABLED=true,PLAYER_REGEN_ENABLED=true,
    SPELLS_CHANGED=true,LEARNED_SPELL_IN_TAB=true,PLAYER_ENTERING_WORLD=true,BAG_UPDATE_COOLDOWN=true,
    BAG_UPDATE_DELAYED=true,PLAYER_EQUIPMENT_CHANGED=true,GET_ITEM_INFO_RECEIVED=true}
local chatEvents={PLAYER_ENTERING_WORLD=true,GROUP_ROSTER_UPDATE=true,PARTY_LEADER_CHANGED=true,
    PLAYER_GUILD_UPDATE=true,GUILD_ROSTER_UPDATE=true,ZONE_CHANGED_NEW_AREA=true,ZONE_CHANGED=true,UPDATE_BATTLEFIELD_STATUS=true}
local xpEvents={QUEST_LOG_UPDATE=true,UNIT_QUEST_LOG_CHANGED=true,PLAYER_ENTERING_WORLD=true,
    PLAYER_XP_UPDATE=true,PLAYER_LEVEL_UP=true,TIME_PLAYED_MSG=true,UPDATE_EXHAUSTION=true,UPDATE_EXPANSION_LEVEL=true}
local castEvents={UNIT_SPELLCAST_START=true,UNIT_SPELLCAST_STOP=true,UNIT_SPELLCAST_FAILED=true,
    UNIT_SPELLCAST_INTERRUPTED=true,UNIT_SPELLCAST_DELAYED=true,UNIT_SPELLCAST_CHANNEL_START=true,
    UNIT_SPELLCAST_CHANNEL_STOP=true,UNIT_SPELLCAST_CHANNEL_UPDATE=true,UNIT_SPELLCAST_SUCCEEDED=true,
    UNIT_SPELLCAST_EMPOWER_START=true,UNIT_SPELLCAST_EMPOWER_UPDATE=true,UNIT_SPELLCAST_EMPOWER_STOP=true}
local distanceEvents={PLAYER_TARGET_CHANGED=true,NAME_PLATE_UNIT_ADDED=true,NAME_PLATE_UNIT_REMOVED=true}
local portraitEvents={UNIT_PORTRAIT_UPDATE=true,UNIT_MODEL_CHANGED=true,PORTRAITS_UPDATED=true,
    PLAYER_ENTERING_WORLD=true,PLAYER_REGEN_DISABLED=true,PLAYER_REGEN_ENABLED=true,
    UNIT_TARGETABLE_CHANGED=true,UNIT_PHASE=true,UNIT_CONNECTION=true,UNIT_FLAGS=true,UNIT_NAME_UPDATE=true,
    ENCOUNTER_START=true,ENCOUNTER_END=true,INSTANCE_ENCOUNTER_ENGAGE_UNIT=true}
local trackedUnits={player=true,vehicle=true,target=true,targettarget=true,focus=true,pet=true,
    party1=true,party2=true,party3=true,party4=true}
local partyUnits={party1=true,party2=true,party3=true,party4=true}
local function Clear(t) for key in pairs(t) do t[key]=nil end end
local dispatchKeys={}
local function Dispatch(id,fn,...)
    local key=dispatchKeys[id];if not key then key="event:"..id;dispatchKeys[id]=key end
    local group=M.byID and M.byID[id];local label=group and group.label or id
    local profile=M.ModuleProfiler
    local sample=profile and profile.targetSampling
    if sample and sample.macro then
        sample.eventDispatches=(sample.eventDispatches or 0)+1
    end
    if profile and profile.active then M:RuntimeCall(M.live,key,label,profile.Measure,id,fn,...)
    else M:RuntimeCall(M.live,key,label,fn,...)end
end
-- Match the supplied WA exactly; do not change the game's saved scale CVars.
local waUIScale=768/1440
local function SameScale(a,b)return b and math.abs(a-b)<.0000001 end
function M:ApplyUIScale()
    if not self.db or self.applyingUIScale then return end
    local enabled=self.db.adapt4KUIScale==true
    local state=self.uiScaleOverride
    if not enabled and not state then return end
    if InCombatLockdown() then self.pendingUIScale=true;return end
    self.pendingUIScale=nil
    local current=UIParent:GetScale()
    if enabled then
        if not state then state={original=current};self.uiScaleOverride=state
        elseif not SameScale(current,state.applied) then state.original=current end
        state.applied=waUIScale
        if not SameScale(current,waUIScale) then
            self.applyingUIScale=true;UIParent:SetScale(waUIScale);self.applyingUIScale=nil
        end
    else
        -- A newer native/other-addon scale takes precedence over our old snapshot.
        self.uiScaleOverride=nil
        if SameScale(current,state.applied) then
            self.applyingUIScale=true;UIParent:SetScale(state.original);self.applyingUIScale=nil
        end
    end
end
function M:QueueUIScale()
    if self.applyingUIScale or self.uiScaleQueued or not self.db
        or (not self.db.adapt4KUIScale and not self.uiScaleOverride) then return end
    if C_Timer and C_Timer.After then
        self.uiScaleQueued=true
        C_Timer.After(0,function()M.uiScaleQueued=nil;M:ApplyUIScale()end)
    else self:ApplyUIScale() end
end
function M:ApplyLive()
    if InCombatLockdown() then self.pending=true;return end
    self:ApplyUIScale()
    if not self.live then return end
    R.Apply(self.live,self.db.design);self:RefreshTargetMouseShortcuts();self:BlizzardVisibility()
end
function M:StartLive()
    if not self.live then
        self.live=R.New(UIParent,false);self.live.root:SetFrameStrata("LOW")
        self.live.root:ClearAllPoints();self.live.root:SetPoint("CENTER",UIParent,"CENTER")
    end
    self:ApplyLive()
    if self.liveEvents then return end
    -- Also arm recovery when loaded after PLAYER_ENTERING_WORLD already fired.
    self.live.fontSettleStarted=GetTime();self.live.fontSettleStep=1
    local f=CreateFrame("Frame");self.liveEvents=f
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","UI_SCALE_CHANGED","PLAYER_STARTED_TURNING","PLAYER_STOPPED_TURNING","PLAYER_STARTED_LOOKING","PLAYER_STOPPED_LOOKING","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","UNIT_PET","UNIT_TARGET",
        "UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_POWER_UPDATE","UNIT_POWER_FREQUENT","UNIT_MAXPOWER","UNIT_DISPLAYPOWER","UNIT_NAME_UPDATE","UNIT_LEVEL",
        "RUNE_POWER_UPDATE","RUNE_TYPE_UPDATE","ECLIPSE_DIRECTION_CHANGE","UNIT_THREAT_SITUATION_UPDATE","UNIT_THREAT_LIST_UPDATE",
        "NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED",
        "PLAYER_XP_UPDATE","PLAYER_LEVEL_UP","UPDATE_EXHAUSTION","UPDATE_EXPANSION_LEVEL","QUEST_LOG_UPDATE","UNIT_QUEST_LOG_CHANGED","TIME_PLAYED_MSG",
        "UNIT_SPELLCAST_SUCCEEDED","SPELL_UPDATE_COOLDOWN","SPELL_UPDATE_CHARGES","SPELL_UPDATE_USABLE","ACTIONBAR_UPDATE_USABLE","ACTIONBAR_SLOT_CHANGED",
        "UPDATE_SHAPESHIFT_FORM","UPDATE_SHAPESHIFT_FORMS",
        "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW","SPELL_ACTIVATION_OVERLAY_GLOW_HIDE",
        "SPELLS_CHANGED","LEARNED_SPELL_IN_TAB",
        "ACTIVE_TALENT_GROUP_CHANGED","PLAYER_TALENT_UPDATE","PLAYER_SPECIALIZATION_CHANGED","TRAIT_CONFIG_UPDATED","TRAIT_CONFIG_LIST_UPDATED",
        "SELECTED_LOADOUT_CHANGED","ACTIVE_COMBAT_CONFIG_CHANGED","ACTIVE_PLAYER_SPECIALIZATION_CHANGED",
        "BAG_UPDATE_COOLDOWN","BAG_UPDATE_DELAYED","PLAYER_EQUIPMENT_CHANGED","GET_ITEM_INFO_RECEIVED","ITEM_DATA_LOAD_RESULT","UNIT_INVENTORY_CHANGED",
        "UNIT_PORTRAIT_UPDATE","UNIT_MODEL_CHANGED","PORTRAITS_UPDATED","UNIT_FLAGS","UNIT_CONNECTION","UNIT_FACTION","UNIT_CLASSIFICATION_CHANGED","UNIT_AURA","RAID_TARGET_UPDATE","GROUP_ROSTER_UPDATE",
        "UNIT_TARGETABLE_CHANGED","UNIT_PHASE","ENCOUNTER_START","ENCOUNTER_END","INSTANCE_ENCOUNTER_ENGAGE_UNIT",
        "PARTY_LEADER_CHANGED","PLAYER_GUILD_UPDATE","GUILD_ROSTER_UPDATE","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED","ZONE_CHANGED_INDOORS","UPDATE_BATTLEFIELD_STATUS",
        "UNIT_SPELLCAST_START","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_INTERRUPTED","UNIT_SPELLCAST_DELAYED",
        "UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_STOP","UNIT_SPELLCAST_CHANNEL_UPDATE",
        "UNIT_SPELLCAST_EMPOWER_START","UNIT_SPELLCAST_EMPOWER_UPDATE","UNIT_SPELLCAST_EMPOWER_STOP","UNIT_ABSORB_AMOUNT_CHANGED",
        "UNIT_ENTERED_VEHICLE","UNIT_EXITED_VEHICLE"}) do
        pcall(f.RegisterEvent,f,event)
    end
    if M.Compat.PetHappinessSupported() then
        pcall(f.RegisterEvent,f,"UNIT_HAPPINESS")
        pcall(f.RegisterEvent,f,"PET_UI_UPDATE")
    end
    local dirty=true;local refreshCause="初始化";local pending=false;local polled=0
    local dirtyUnits,dirtyModules={},{}
    local dirtyFields={health={},power={},aura={},portrait={},all={}}
    local function ResetDirty()
        Clear(dirtyUnits);Clear(dirtyModules)
        for _,fields in pairs(dirtyFields) do Clear(fields) end
    end
    local function Unit(unit,field)
        if trackedUnits[unit] then
            local key=unit=="vehicle" and "player" or unit
            dirtyUnits[key]=true;dirtyFields[field or "all"][key]=true;pending=true
        end
    end
    local function Module(id) dirtyModules[id]=true;pending=true end
    local raidInstance=RaidInstance()
    local encounterActive=C.Bool(IsEncounterInProgress and IsEncounterInProgress())
    local bossTarget,bossDead,bossHealthDue,bossHealthPending=false,false,0,false
    local function RefreshBossMode(resetTarget)
        local view=M.live
        local encounter=raidInstance and encounterActive
        if (view.raidEncounter==true)~=encounter then
            view.raidEncounter=encounter or nil
            if encounter and M.MainSweep then M.MainSweep.Suspend(view) end
            dirty=true;refreshCause="首领战状态"
        end
        local eligible=encounter and EnemyBossTarget()
        if resetTarget or eligible~=bossTarget then
            bossTarget=eligible;bossDead=false;bossHealthPending=false
            view.raidBossHealth=nil
            if eligible then
                bossDead=C.Bool(UnitIsDeadOrGhost("target"))
                if not bossDead then
                    view.raidBossHealth=C.CaptureBossHealth()
                    bossHealthDue=GetTime()+bossHealthInterval
                end
            end
            Unit("target","health")
        end
    end
    RefreshBossMode(true)

    local function UpdateBossHealth(view)
        if not bossTarget then return end
        local now=GetTime()
        if not bossHealthPending and (bossDead or now<bossHealthDue) then return end
        if not C.Bool(UnitExists("target")) then RefreshBossMode(true);return end
        local dead=C.Bool(UnitIsDeadOrGhost("target"))
        if dead~=bossDead then
            bossDead=dead;view.raidBossHealth=nil;bossHealthPending=false
            bossHealthDue=now
            if dead then Unit("target");return end
        end
        if dead then bossHealthPending=false;return end
        if now<bossHealthDue then bossHealthPending=false;return end
        bossHealthDue=now+bossHealthInterval;bossHealthPending=false
        local previous=view.raidBossHealth
        local sample=C.CaptureBossHealth()
        if previous and C.Readable(sample.health) and C.Readable(sample.maximum)
            and C.Readable(previous.health) and C.Readable(previous.maximum)
            and previous.health==sample.health and previous.maximum==sample.maximum then return end
        view.raidBossHealth=sample
        Unit("target","health")
    end
    local function OnEvent(_,event,unit,...)
        local view=M.live
        if type(unit)=="string" and C.Readable(unit) and partyUnits[unit]
            and view.partyGroupGate and not view.partyGroupGate:IsVisible() then return end
        if event=="UNIT_AURA" then
            if not trackedUnits[unit] then return end
            local update=...
            if type(update)=="table" and C.Readable(update) and C.Readable(update.isFullUpdate)
                and update.isFullUpdate==false and type(update.updatedAuraInstanceIDs)=="nil"
                and type(update.removedAuraInstanceIDs)=="nil" then
                local added=update.addedAuras
                if type(added)=="nil" then return end
                if view.raidEncounter and partyUnits[unit] and C.Readable(added) and type(added)=="table" then
                    local helpfulOnly=true
                    for _,aura in ipairs(added) do
                        if not C.Readable(aura) or type(aura)~="table"
                            or not C.Readable(aura.isHelpful) or aura.isHelpful~=true then
                            helpfulOnly=false;break
                        end
                    end
                    if helpfulOnly then return end
                end
            end
            if unit~="player" and unit~="target" then
                R.InvalidateAuras(view,unit=="vehicle" and "player" or unit)
                Unit(unit,"aura")
                return
            end
        end
        if event=="UNIT_HAPPINESS" then
            local pet=view.byID.petComposite
            if not pet or pet.enabled==false then return end
            local happiness=C.PetHappiness(false)
            local state=view.stateBuffers.pet
            if state and state.exists and state.petHappiness==happiness then return end
        end
        -- These events have no module dispatch consumers. Custom monitor events
        -- are registered separately, and keep their original delivery.
        local healthEvent=event=="UNIT_HEALTH" or event=="UNIT_MAXHEALTH"
        local powerEvent=event=="UNIT_POWER_UPDATE" or event=="UNIT_POWER_FREQUENT" or event=="UNIT_MAXPOWER"
        if healthEvent or powerEvent then
            local profile=M.ModuleProfiler
            local started=profile and profile.active and debugprofilestop()
            if healthEvent and unit=="target" and bossTarget then
                bossHealthPending=true
            elseif trackedUnits[unit] then
                Unit(unit,healthEvent and "health" or "power")
            end
            if started then profile.Total("event",debugprofilestop()-started) end
            return
        end
        if event=="PLAYER_ENTERING_WORLD" then
            raidInstance=RaidInstance()
            encounterActive=C.Bool(IsEncounterInProgress and IsEncounterInProgress())
            RefreshBossMode(true)
        elseif event=="ENCOUNTER_START" or event=="ENCOUNTER_END" then
            raidInstance=RaidInstance()
            encounterActive=event=="ENCOUNTER_START"
            RefreshBossMode(true)
        elseif event=="PLAYER_TARGET_CHANGED" or event=="INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
            RefreshBossMode(event=="PLAYER_TARGET_CHANGED")
        elseif raidInstance and encounterActive and unit=="target"
            and (event=="UNIT_FLAGS" or event=="UNIT_CLASSIFICATION_CHANGED" or event=="UNIT_TARGETABLE_CHANGED") then
            RefreshBossMode(false)
            if bossTarget then
                bossHealthPending=true
                UpdateBossHealth(M.live)
            end
        end
        M.live.nativeThirdSelectionGeneration=(M.live.nativeThirdSelectionGeneration or 0)+1
        if event=="UI_SCALE_CHANGED" then M:QueueUIScale();return end
        if event=="PLAYER_ENTERING_WORLD" then M:QueueUIScale()
        elseif event=="PLAYER_REGEN_ENABLED" and M.pendingUIScale then M:ApplyUIScale() end
        if (event=="PLAYER_ENTERING_WORLD"or event=="PLAYER_REGEN_ENABLED"or event=="ACTIVE_TALENT_GROUP_CHANGED"or event=="PLAYER_TALENT_UPDATE"
            or event=="PLAYER_SPECIALIZATION_CHANGED"or event=="TRAIT_CONFIG_UPDATED"or event=="TRAIT_CONFIG_LIST_UPDATED"
            or event=="SELECTED_LOADOUT_CHANGED"or event=="ACTIVE_COMBAT_CONFIG_CHANGED"or event=="ACTIVE_PLAYER_SPECIALIZATION_CHANGED")and not InCombatLockdown()
            and (event~="PLAYER_SPECIALIZATION_CHANGED"or not unit or unit=="player")then
            local changed=M.PlayerSkillMonitor.RefreshProfileBindings()
            if not changed and M.editor and M.editor.window:IsShown()and (M.selection=="playerSkillMonitor"or M.selection=="playerOtherMonitor")then
                M:RefreshProperties()
            end
            local preview=M.editor and M.editor.view
            if preview and M.editor.window:IsShown()then
                M:Safe("玩家资源专精预览刷新",R.Update,preview,{player=true})
            end
        end
        local profile=M.ModuleProfiler
        local started=profile and profile.active and debugprofilestop()
        if portraitEvents[event] then
            local portraitUnit=event:find("^UNIT_") and unit or nil
            M.Portraits.Invalidate(M.live,portraitUnit,event)
            local preview=M.editor and M.editor.view
            if preview then
                M.Portraits.Invalidate(preview,portraitUnit)
                if M.editor.window:IsShown() then M:Safe("头像预览刷新",R.Update,preview) end
            end
        end
        if R.InvalidateAuras then
            if event=="UNIT_AURA" then
                if trackedUnits[unit] then R.InvalidateAuras(M.live,unit=="vehicle" and "player" or unit,...) end
            elseif event=="PLAYER_ENTERING_WORLD" or event=="GROUP_ROSTER_UPDATE" then R.InvalidateAuras(M.live)
            elseif event=="PLAYER_FOCUS_CHANGED" then R.InvalidateAuras(M.live,"focus")
            elseif event=="UNIT_PET" and unit=="player" then R.InvalidateAuras(M.live,"pet")
            elseif event=="UNIT_TARGET" then
                if unit=="target" then R.InvalidateAuras(M.live,"targettarget")
                elseif unit=="player" then R.InvalidateAuras(M.live,"target");R.InvalidateAuras(M.live,"targettarget") end
            elseif (event=="UNIT_ENTERED_VEHICLE" or event=="UNIT_EXITED_VEHICLE") and (unit=="player" or unit=="vehicle") then R.InvalidateAuras(M.live,"player") end
        end
        if M.CooldownMonitor and cooldownEvents[event] and (event~="UNIT_SPELLCAST_SUCCEEDED" or unit=="player") then Dispatch("cooldownMonitor",M.CooldownMonitor.Event,M.CooldownMonitor,event,unit,...) end
        if M.PlayerSkillMonitor then
            if event=="SPELL_UPDATE_COOLDOWN" or event=="SPELL_UPDATE_CHARGES" then
                local skills=view.byID.playerSkillMonitor
                if skills and skills.enabled~=false then Module("playerSkillMonitor") end
            else Dispatch("playerSkillMonitor",M.PlayerSkillMonitor.Event,M.live,event,unit) end
        end
        if M.PlayerOtherMonitor then Dispatch("playerOtherMonitor",M.PlayerOtherMonitor.Event,M.live,event,unit) end
        if M.CommonItems then
            if event=="SPELL_UPDATE_COOLDOWN" or event=="BAG_UPDATE_COOLDOWN" then
                local items=view.byID.commonItems
                if items and items.enabled~=false then Module("commonItems") end
            else Dispatch("commonItems",M.CommonItems.Event,M.live,event,unit) end
        end
        -- Each team aura monitor consumes the dirty scan once in the frame refresh.
        if M.RaidVulnerability then Dispatch("raidVulnerability",M.RaidVulnerability.Event,M.live,event,unit,true)end
        if M.ReceivedBuffs then Dispatch("receivedBuffs",M.ReceivedBuffs.Event,M.live,event,unit,true)end
        if M.RaidBuffMonitor then Dispatch("raidBuffs",M.RaidBuffMonitor.Event,M.live,event,unit,true)end
        if M.ChatButtons and chatEvents[event] then Dispatch("chatButtons",M.ChatButtons.Event,M.live,event) end
        local combatEvent=event=="PLAYER_REGEN_DISABLED" or event=="PLAYER_REGEN_ENABLED"
        if M.CombatNotices and combatEvent then Dispatch("combatNotices",M.CombatNotices.Event,M.live,event) end
        if M.MouseCircle and (independentEvents[event] or castEvents[event] or event=="PLAYER_ENTERING_WORLD") then Dispatch("mouseCircle",M.MouseCircle.Event,M.live,event,unit) end
        if castEvents[event] or event=="PLAYER_ENTERING_WORLD" then
            Dispatch("wa8d650f8d3a",M.EmpowerCast.InterruptEvent,M.live,event,unit,...)
        end
        if M.ExperienceBar and xpEvents[event] then Dispatch("experienceBar",M.ExperienceBar.Event,M.live,event,unit,...) end
        if M.TargetDistance and distanceEvents[event] then Dispatch("targetDistance",M.TargetDistance.Event,M.live,event) end
        if event=="PLAYER_TARGET_CHANGED" then
            M.live.resourceTargetChanged=true
            M.live.effectTargetPulse=(M.live.effectTargetPulse or 0)+1
            -- Refresh during the event, before the next rendered frame. The secure
            -- visibility gate also refreshes on show, regardless of event order.
            M:Safe("目标刷新",R.RefreshTarget,M.live)
        elseif (event=="UNIT_SPELLCAST_START" or event=="UNIT_SPELLCAST_CHANNEL_START"or event=="UNIT_SPELLCAST_EMPOWER_START") and (unit=="player" or unit=="vehicle") then
            M.live.effectCastPulse=(M.live.effectCastPulse or 0)+1
        end
        if event=="PLAYER_ENTERING_WORLD" then
            -- Restore selected faces after startup; avoid protected layout changes.
            M.live.fontRefreshPending=true;M.live.fontRetryCount=0;dirty=true
            if unit==true then M.live.fontSettleStarted=GetTime();M.live.fontSettleStep=1 end
        elseif event=="ZONE_CHANGED"or event=="ZONE_CHANGED_NEW_AREA"or event=="ZONE_CHANGED_INDOORS"then
            for i=1,4 do Unit("party"..i)end
            Module("chatButtons")
        elseif event=="PLAYER_TARGET_CHANGED" then
            -- RefreshTarget already painted every target dependency synchronously.
            dirtyUnits.target=nil;dirtyUnits.targettarget=nil
        elseif event=="PLAYER_FOCUS_CHANGED" then Unit("focus")
        elseif event=="UNIT_PET" then if unit=="player" then Unit("pet") end
        elseif event=="UNIT_HAPPINESS" or event=="PET_UI_UPDATE" then Unit("pet")
        elseif event=="UNIT_PORTRAIT_UPDATE" or event=="UNIT_MODEL_CHANGED" then Unit(unit,"portrait")
        elseif event=="PORTRAITS_UPDATED" then
            for name in pairs(trackedUnits) do Unit(name,"portrait") end
        elseif event=="UNIT_AURA" then Unit(unit,"aura")
        elseif event=="UNIT_TARGET" then
            if unit=="target" then Unit("targettarget")
            elseif unit=="player" then Unit("target");Unit("targettarget") end
        elseif event=="RUNE_POWER_UPDATE" or event=="RUNE_TYPE_UPDATE" then Unit("player")
        elseif event=="UNIT_THREAT_SITUATION_UPDATE" or event=="UNIT_THREAT_LIST_UPDATE" then
            if unit==nil or unit=="player" or unit=="target" then Module("targetThreat") end
        elseif xpEvents[event] then
            if event~="UNIT_QUEST_LOG_CHANGED" or unit=="player" then Module("experienceBar") end
            if event=="PLAYER_LEVEL_UP" then Unit("player") end
        elseif event=="SPELLS_CHANGED" or event=="LEARNED_SPELL_IN_TAB" or event=="BAG_UPDATE_DELAYED"
            or event=="PLAYER_EQUIPMENT_CHANGED" or event=="GET_ITEM_INFO_RECEIVED" then
            Module("cooldownMonitor");Module("targetDistance")
        elseif combatEvent then Module("combatNotices");Module("targetThreat")
        elseif chatEvents[event] then
            Module("chatButtons")
            if event=="GROUP_ROSTER_UPDATE" or event=="PARTY_LEADER_CHANGED" then
                for name in pairs(trackedUnits) do Unit(name) end
            end
        elseif event=="UPDATE_SHAPESHIFT_FORM" or event=="UPDATE_SHAPESHIFT_FORMS" then
            Unit("player","power")
        elseif distanceEvents[event] or independentEvents[event] then
            -- Independently updated modules already consumed these events.
        elseif event=="UNIT_FACTION" and unit=="player" then
            for name in pairs(trackedUnits) do Unit(name) end
        elseif event=="UNIT_DISPLAYPOWER" then Unit(unit,"power")
        elseif event:find("^UNIT_") then Unit(unit)
        else dirty=true;refreshCause=event end
        if started then profile.Total("event",debugprofilestop()-started) end
    end
    f:SetScript("OnEvent",function(self,event,unit,...)
        local profile=M.ModuleProfiler
        local sample=profile and profile.targetSampling
        local started=sample and sample.macro and debugprofilestop()
        local ok,err=M.Compat.RunWithAuraSnapshots(OnEvent,self,event,unit,...)
        if started and profile.targetSampling==sample then
            profile.RecordMacroEvent(event,unit,debugprofilestop()-started)
        end
        if not ok then error(err)end
    end)
    -- Reuse the protected callback instead of allocating a closure every frame.
    local function Refresh()
        local view=M.live
        UpdateBossHealth(view)
        if view.shownTargetModules then
            for id in pairs(view.shownTargetModules) do Module(id) end
            view.shownTargetModules=nil
        end
        local step=view.fontSettleStep
        local settling=step and GetTime()>=(view.fontSettleStarted+fontSettleDelays[step])
        if view.fontRefreshPending or settling or (view.fontsPending and (view.fontRetryCount or 0)<10 and GetTime()>=(view.fontRetryAt or 0)) then
            view.fontRefreshPending=nil
            M:RuntimeCall(view,"fonts","字体刷新",R.RefreshTextFonts,view)
            if settling then
                repeat step=step+1 until not fontSettleDelays[step] or GetTime()<view.fontSettleStarted+fontSettleDelays[step]
                view.fontSettleStep=fontSettleDelays[step] and step or nil
                if not view.fontSettleStep then view.fontSettleStarted=nil end
            end
            view.fontRetryCount=(view.fontRetryCount or 0)+1;view.fontRetryAt=GetTime()+.5
            dirty=true;refreshCause="字体刷新"
        end
        local full=dirty or polled>=.2
        local profile=M.ModuleProfiler
        local sample=profile and profile.targetSampling
        local measure=(full or pending) and sample and sample.macro
        local cause=measure and (full and (dirty and (refreshCause or "状态变化") or "定时兜底") or "局部刷新")
        local started=measure and debugprofilestop()
        if full then
            M:RuntimeCall(view,"update","状态刷新",R.Update,M.live);dirty=false;pending=false;polled=0;ResetDirty()
        elseif pending then
            M:RuntimeCall(view,"update","状态刷新",R.Update,M.live,dirtyUnits,dirtyModules,dirtyFields);pending=false;ResetDirty()
        end
        if started then
            local elapsed=debugprofilestop()-started
            sample.refreshCauses=sample.refreshCauses or {}
            local row=sample.refreshCauses[cause] or {calls=0,ms=0}
            row.calls=row.calls+1;row.ms=row.ms+elapsed;sample.refreshCauses[cause]=row
        end
        if M.RaidBuffMonitor then
            M.RaidBuffMonitor.FlushAuraNames(view)
        end
        M:RuntimeCall(view,"animate","动画刷新",R.Animate,M.live)
    end
    f:SetScript("OnUpdate",function(self,dt)
        polled=polled+dt
        local profile=M.ModuleProfiler
        local sample=profile and profile.targetSampling
        local started=profile and (profile.active or (sample and sample.macro)) and debugprofilestop()
        local ok,err=M.Compat.RunWithAuraSnapshots(Refresh)
        if started then
            local elapsed=debugprofilestop()-started
            if sample then
                if profile.targetSampling==sample then profile.RecordTarget(6,elapsed) end
            else profile.Total("frame",elapsed) end
        end
        if not ok then
            dirty=true;pending=false;polled=0;ResetDirty()
            local message=tostring(err)
            if M.live.lastRefreshError~=message then
                M.live.lastRefreshError=message;M:Report("刷新异常（继续重试）",message)
            end
        end
    end)
end
