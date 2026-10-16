local _,M=...
local R=M.Renderer
-- Cold login can report font assignment success before glyph assets settle.
-- Finite refreshes rebuild glyphs after loading; never retry healthy fonts forever.
local fontSettleDelays={.5,2,5,10,20,40}
local independentEvents={SPELL_UPDATE_COOLDOWN=true,SPELL_UPDATE_CHARGES=true,BAG_UPDATE_COOLDOWN=true,
    PLAYER_STARTED_TURNING=true,PLAYER_STOPPED_TURNING=true,PLAYER_STARTED_LOOKING=true,PLAYER_STOPPED_LOOKING=true}
local cooldownEvents={UNIT_SPELLCAST_SUCCEEDED=true,SPELL_UPDATE_COOLDOWN=true,SPELL_UPDATE_CHARGES=true,
    SPELLS_CHANGED=true,LEARNED_SPELL_IN_TAB=true,PLAYER_ENTERING_WORLD=true,BAG_UPDATE_COOLDOWN=true,
    BAG_UPDATE_DELAYED=true,PLAYER_EQUIPMENT_CHANGED=true,GET_ITEM_INFO_RECEIVED=true}
local chatEvents={PLAYER_ENTERING_WORLD=true,GROUP_ROSTER_UPDATE=true,PARTY_LEADER_CHANGED=true,
    PLAYER_GUILD_UPDATE=true,GUILD_ROSTER_UPDATE=true,ZONE_CHANGED_NEW_AREA=true,ZONE_CHANGED=true,UPDATE_BATTLEFIELD_STATUS=true}
local xpEvents={QUEST_LOG_UPDATE=true,UNIT_QUEST_LOG_CHANGED=true,PLAYER_ENTERING_WORLD=true,
    PLAYER_XP_UPDATE=true,PLAYER_LEVEL_UP=true,TIME_PLAYED_MSG=true,UPDATE_EXHAUSTION=true,UPDATE_EXPANSION_LEVEL=true}
local castEvents={UNIT_SPELLCAST_START=true,UNIT_SPELLCAST_STOP=true,UNIT_SPELLCAST_FAILED=true,
    UNIT_SPELLCAST_INTERRUPTED=true,UNIT_SPELLCAST_DELAYED=true,UNIT_SPELLCAST_CHANNEL_START=true,
    UNIT_SPELLCAST_CHANNEL_STOP=true,UNIT_SPELLCAST_CHANNEL_UPDATE=true,UNIT_SPELLCAST_SUCCEEDED=true}
local distanceEvents={PLAYER_TARGET_CHANGED=true,NAME_PLATE_UNIT_ADDED=true,NAME_PLATE_UNIT_REMOVED=true}
local portraitEvents={UNIT_PORTRAIT_UPDATE=true,UNIT_MODEL_CHANGED=true,PORTRAITS_UPDATED=true,
    PLAYER_ENTERING_WORLD=true,PLAYER_REGEN_DISABLED=true,PLAYER_REGEN_ENABLED=true,
    UNIT_TARGETABLE_CHANGED=true,UNIT_PHASE=true,UNIT_CONNECTION=true,UNIT_FLAGS=true,UNIT_NAME_UPDATE=true,
    ENCOUNTER_START=true,ENCOUNTER_END=true,INSTANCE_ENCOUNTER_ENGAGE_UNIT=true}
local trackedUnits={player=true,vehicle=true,target=true,targettarget=true,focus=true,pet=true,
    party1=true,party2=true,party3=true,party4=true}
local function Clear(t) for key in pairs(t) do t[key]=nil end end
local function Dispatch(id,fn,...)
    local profile=M.ModuleProfiler
    if profile and profile.active then profile.Measure(id,fn,...) else fn(...) end
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
    R.Apply(self.live,self.db.design);self:BlizzardVisibility()
end
function M:StartLive()
    if not self.live then
        self.live=R.New(UIParent,false);self.live.root:SetFrameStrata("LOW")
        self.live.root:ClearAllPoints();self.live.root:SetPoint("CENTER",UIParent,"CENTER")
    end
    self:ApplyLive()
    if self.liveEvents then return end
    local f=CreateFrame("Frame");self.liveEvents=f
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","UI_SCALE_CHANGED","PLAYER_STARTED_TURNING","PLAYER_STOPPED_TURNING","PLAYER_STARTED_LOOKING","PLAYER_STOPPED_LOOKING","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","UNIT_PET","UNIT_TARGET",
        "UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_POWER_UPDATE","UNIT_MAXPOWER","UNIT_DISPLAYPOWER","UNIT_NAME_UPDATE","UNIT_LEVEL",
        "RUNE_POWER_UPDATE","RUNE_TYPE_UPDATE","UNIT_THREAT_SITUATION_UPDATE","UNIT_THREAT_LIST_UPDATE",
        "NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED",
        "PLAYER_XP_UPDATE","PLAYER_LEVEL_UP","UPDATE_EXHAUSTION","UPDATE_EXPANSION_LEVEL","QUEST_LOG_UPDATE","UNIT_QUEST_LOG_CHANGED","TIME_PLAYED_MSG",
        "UNIT_SPELLCAST_SUCCEEDED","SPELL_UPDATE_COOLDOWN","SPELL_UPDATE_CHARGES","SPELLS_CHANGED","LEARNED_SPELL_IN_TAB",
        "BAG_UPDATE_COOLDOWN","BAG_UPDATE_DELAYED","PLAYER_EQUIPMENT_CHANGED","GET_ITEM_INFO_RECEIVED",
        "UNIT_PORTRAIT_UPDATE","UNIT_MODEL_CHANGED","PORTRAITS_UPDATED","UNIT_FLAGS","UNIT_CONNECTION","UNIT_FACTION","UNIT_CLASSIFICATION_CHANGED","UNIT_AURA","RAID_TARGET_UPDATE","GROUP_ROSTER_UPDATE",
        "UNIT_TARGETABLE_CHANGED","UNIT_PHASE","ENCOUNTER_START","ENCOUNTER_END","INSTANCE_ENCOUNTER_ENGAGE_UNIT",
        "PARTY_LEADER_CHANGED","PLAYER_GUILD_UPDATE","GUILD_ROSTER_UPDATE","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED","ZONE_CHANGED_INDOORS","UPDATE_BATTLEFIELD_STATUS",
        "UNIT_SPELLCAST_START","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_INTERRUPTED","UNIT_SPELLCAST_DELAYED",
        "UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_STOP","UNIT_SPELLCAST_CHANNEL_UPDATE","UNIT_ENTERED_VEHICLE","UNIT_EXITED_VEHICLE"}) do
        pcall(f.RegisterEvent,f,event)
    end
    local dirty=true;local pending=false;local polled=0
    local dirtyUnits,dirtyModules={},{}
    local dirtyFields={health={},power={},all={}}
    local function ResetDirty()
        Clear(dirtyUnits);Clear(dirtyModules)
        Clear(dirtyFields.health);Clear(dirtyFields.power);Clear(dirtyFields.all)
    end
    local function Unit(unit,field)
        if trackedUnits[unit] then
            local key=unit=="vehicle" and "player" or unit
            dirtyUnits[key]=true;dirtyFields[field or "all"][key]=true;pending=true
        end
    end
    local function Module(id) dirtyModules[id]=true;pending=true end
    f:SetScript("OnEvent",function(_,event,unit,...)
        if event=="UI_SCALE_CHANGED" then M:QueueUIScale();return end
        if event=="PLAYER_ENTERING_WORLD" then M:QueueUIScale()
        elseif event=="PLAYER_REGEN_ENABLED" and M.pendingUIScale then M:ApplyUIScale() end
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
                if trackedUnits[unit] then R.InvalidateAuras(M.live,unit=="vehicle" and "player" or unit) end
            elseif event=="PLAYER_ENTERING_WORLD" or event=="GROUP_ROSTER_UPDATE" then R.InvalidateAuras(M.live)
            elseif event=="PLAYER_FOCUS_CHANGED" then R.InvalidateAuras(M.live,"focus")
            elseif event=="UNIT_PET" and unit=="player" then R.InvalidateAuras(M.live,"pet")
            elseif event=="UNIT_TARGET" then
                if unit=="target" then R.InvalidateAuras(M.live,"targettarget")
                elseif unit=="player" then R.InvalidateAuras(M.live,"target");R.InvalidateAuras(M.live,"targettarget") end
            elseif (event=="UNIT_ENTERED_VEHICLE" or event=="UNIT_EXITED_VEHICLE") and (unit=="player" or unit=="vehicle") then R.InvalidateAuras(M.live,"player") end
        end
        if M.CooldownMonitor and cooldownEvents[event] and (event~="UNIT_SPELLCAST_SUCCEEDED" or unit=="player") then Dispatch("cooldownMonitor",M.CooldownMonitor.Event,M.CooldownMonitor,event,unit,...) end
        if M.ChatButtons and chatEvents[event] then Dispatch("chatButtons",M.ChatButtons.Event,M.live,event) end
        local combatEvent=event=="PLAYER_REGEN_DISABLED" or event=="PLAYER_REGEN_ENABLED"
        if M.CombatNotices and combatEvent then Dispatch("combatNotices",M.CombatNotices.Event,M.live,event) end
        if M.MouseCircle and (independentEvents[event] or castEvents[event] or event=="PLAYER_ENTERING_WORLD") then Dispatch("mouseCircle",M.MouseCircle.Event,M.live,event,unit) end
        if M.ExperienceBar and xpEvents[event] then Dispatch("experienceBar",M.ExperienceBar.Event,M.live,event,unit,...) end
        if M.TargetDistance and distanceEvents[event] then Dispatch("targetDistance",M.TargetDistance.Event,M.live,event) end
        if event=="PLAYER_TARGET_CHANGED" then
            M.live.resourceTargetChanged=true
            M.live.effectTargetPulse=(M.live.effectTargetPulse or 0)+1
            -- Refresh during the event, before the next rendered frame. The secure
            -- visibility gate also refreshes on show, regardless of event order.
            M:Safe("目标刷新",R.RefreshTarget,M.live)
        elseif (event=="UNIT_SPELLCAST_START" or event=="UNIT_SPELLCAST_CHANNEL_START") and (unit=="player" or unit=="vehicle") then
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
        elseif distanceEvents[event] or independentEvents[event] then
            -- Independently updated modules already consumed these events.
        elseif event=="UNIT_FACTION" and unit=="player" then
            for name in pairs(trackedUnits) do Unit(name) end
        elseif event=="UNIT_HEALTH" or event=="UNIT_MAXHEALTH" then Unit(unit,"health")
        elseif event=="UNIT_POWER_UPDATE" or event=="UNIT_MAXPOWER" or event=="UNIT_DISPLAYPOWER" then Unit(unit,"power")
        elseif event:find("^UNIT_") then Unit(unit)
        else dirty=true end
        if started then profile.Total("event",debugprofilestop()-started) end
    end)
    -- Reuse the protected callback instead of allocating a closure every frame.
    local function Refresh()
        local view=M.live
        local step=view.fontSettleStep
        local settling=step and GetTime()>=(view.fontSettleStarted+fontSettleDelays[step])
        if view.fontRefreshPending or settling or (view.fontsPending and (view.fontRetryCount or 0)<10 and GetTime()>=(view.fontRetryAt or 0)) then
            view.fontRefreshPending=nil
            R.RefreshTextFonts(view)
            if settling then
                repeat step=step+1 until not fontSettleDelays[step] or GetTime()<view.fontSettleStarted+fontSettleDelays[step]
                view.fontSettleStep=fontSettleDelays[step] and step or nil
                if not view.fontSettleStep then view.fontSettleStarted=nil end
            end
            view.fontRetryCount=(view.fontRetryCount or 0)+1;view.fontRetryAt=GetTime()+.5
            dirty=true
        end
        if dirty or polled>=.2 then
            R.Update(M.live);dirty=false;pending=false;polled=0;ResetDirty()
        elseif pending then
            R.Update(M.live,dirtyUnits,dirtyModules,dirtyFields);pending=false;ResetDirty()
        end
        R.Animate(M.live)
    end
    f:SetScript("OnUpdate",function(self,dt)
        polled=polled+dt
        local profile=M.ModuleProfiler
        local started=profile and profile.active and debugprofilestop()
        local ok,err=pcall(Refresh)
        if started then profile.Total("frame",debugprofilestop()-started) end
        if not ok then self:SetScript("OnUpdate",nil);M:Report("框体刷新已暂停",err) end
    end)
end
