local _,M=...
local C=M.Compat
local A={};M.AttackProgress=A
local GROUP="wa8d650f8d3a"
local FILL="waba76314011"
local definitions={{"playerRangedProgress","ranged","远程攻击进度","rangedProgressColor"},{"playerMeleeProgress","melee","近战攻击进度","meleeProgressColor"}}
local geometry={"parent","x","y","width","height","scale","point","anchor","alpha","layer","file","blend","color","cropX","cropY","mirror","mirrorY","rotation"}
function M:EnsureAttackProgress(design)
    if not design or not design.nodes then return end
    local index={};for _,n in ipairs(design.nodes) do index[n.id]=n end
    local group,fill=index[GROUP],index[FILL]
    if not group or not fill then return end
    if group.showRangedProgress==nil then group.showRangedProgress=false end
    if group.showMeleeProgress==nil then group.showMeleeProgress=false end
    for _,entry in ipairs(definitions) do
        if group[entry[4]]==nil then group[entry[4]]=self.Copy(fill.color or {1,1,1,1}) end
        local n=index[entry[1]]
        if not n then n={id=entry[1]};design.nodes[#design.nodes+1]=n end
        for _,key in ipairs(geometry) do n[key]=self.Copy(fill[key]) end
        n.kind="texture";n.binding="static";n.attackKind=entry[2];n.label=entry[3]
        n.parent=GROUP;n.unit="player";n.scope="player";n.internal=true;n.locked=true
        n.enabled=entry[2]=="ranged" and group.showRangedProgress==true or entry[2]=="melee" and group.showMeleeProgress==true
        n.color=self.Copy(group[entry[4]])
        n.rules={};n.conditions={}
        local original=index.wa1537213e27
        if original then
            local id=entry[1].."Frame"
            local border=index[id]
            if not border then border={id=id};design.nodes[#design.nodes+1]=border end
            for _,key in ipairs(geometry) do border[key]=self.Copy(original[key]) end
            border.kind="texture";border.binding="static";border.attackKind=entry[2];border.attackFrame=true
            border.label=entry[3].."框体";border.parent=GROUP;border.unit="player";border.scope="player"
            border.internal=true;border.locked=true;border.enabled=n.enabled;border.rules={};border.conditions={}
        end
    end
end
M:EnsureAttackProgress(M.defaults)
M:EnsureAttackProgress(M.recordedDefaults)

local state={melee={},ranged={}}
A.state=state
local function MeleeAttacking()
    if IsCurrentSpell then
        local attacking=IsCurrentSpell(6603)
        if C.Readable(attacking) then return C.Bool(attacking) end
    end
    return state.meleeAttacking==true
end
local function Reset(kind)
    local s=state[kind];s.start=nil;s.finish=nil;s.paused=nil;s.active=false
end
local function Speed(kind)
    local value
    if kind=="melee" and UnitAttackSpeed then value=UnitAttackSpeed("player")
    elseif kind=="ranged" then
        if UnitAttackSpeed then value=select(3,UnitAttackSpeed("player")) end
        if C.Number(value)==nil and UnitRangedDamage then value=UnitRangedDamage("player") end
    end
    value=C.Number(value)
    return value and value>0 and value or state[kind].speed
end
local function Start(kind,speed)
    if not A.enabled or not A[kind.."Enabled"] then return end
    speed=C.Number(speed) or Speed(kind)
    if not speed or speed<=0 then return end
    local s=state[kind];local now=GetTime()
    -- Spell success and combat-log damage can describe the same melee attack.
    if s.start and now-s.start<.05 and s.speed==speed then return end
    s.speed=speed;s.start=now;s.finish=now+speed;s.active=true;s.paused=nil
    state.latest=kind
end
local function Rescale(kind)
    local s=state[kind];local speed=Speed(kind);local now=GetTime()
    if speed and s.speed and s.finish and s.finish>now and not s.paused then
        s.finish=now+(s.finish-now)*speed/s.speed;s.start=s.finish-speed
    end
    s.speed=speed
end
local queuedIDs={[78]=true,[845]=true,[6807]=true,[2973]=true,[56815]=true}
local queuedNames,noResetNames={},{}
local function SpellName(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    if GetSpellInfo then return GetSpellInfo(id) end
end
local slamName
local function Names()
    for id in pairs(queuedIDs) do local name=SpellName(id);if name then queuedNames[name]=true end end
    for _,id in ipairs({75,5019,56641,19434,2643}) do local name=SpellName(id);if name then noResetNames[name]=true end end
    slamName=SpellName(1464)
end
local function Resume()
    local s=state.melee
    if s.paused and s.finish then
        local elapsed=GetTime()-s.paused;s.start=s.start+elapsed;s.finish=s.finish+elapsed
    end
    s.paused=nil
end
local function Parry()
    local s=state.melee;local now=GetTime()
    if not s.active or not s.finish or not s.speed or s.paused then return end
    local remaining=s.finish-now;local floor=.2*s.speed
    if remaining>floor then
        remaining=math.max(floor,remaining-.4*s.speed)
        s.finish=now+remaining;s.start=s.finish-s.speed
    end
end
local function CombatLog(_,event,_,source,_,_,_,dest,_,_,_,...)
    if not C.Readable(event) or not C.Readable(source) or not C.Readable(dest) then return end
    local player=UnitGUID and UnitGUID("player")
    if not player or not C.Readable(player) then return end
    if event=="SWING_MISSED" and dest==player then
        local miss=...;if C.Readable(miss) and miss=="PARRY" then Parry() end
    end
    if source~=player then return end
    if event=="SWING_DAMAGE" or event=="SWING_MISSED" then
        local offhand
        if event=="SWING_DAMAGE" then offhand=select(10,...) else offhand=select(2,...) end
        if C.Readable(offhand) and not offhand and not state.nativeMelee then Start("melee") end
    elseif event=="RANGE_DAMAGE" or event=="RANGE_MISSED" then
        -- A projectile arriving later must not move the firing-time anchor.
        if not state.rangedSpellAnchor and not state.nativeRanged then Start("ranged") end
    elseif event=="SPELL_DAMAGE" or event=="SPELL_MISSED" then
        local id,name=...
        if C.Readable(id) and C.Readable(name) and (queuedIDs[id] or queuedNames[name]) and not state.nativeMelee then Start("melee") end
    end
end
function A.Event(event,unit,castGUID,spellID)
    if not A.enabled then return end
    if event=="COMBAT_LOG_EVENT_UNFILTERED" then
        if C.CombatLogAvailable() then CombatLog(CombatLogGetCurrentEventInfo()) end
    elseif event=="PLAYER_SWING" then
        local duration,kind=C.Number(unit),C.Number(castGUID)
        if duration and duration>0 then
            if kind==0 and MeleeAttacking() then state.nativeMelee=true;Start("melee",duration)
            elseif kind==2 then state.nativeRanged=true;Start("ranged",duration) end
        end
    elseif event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_DEAD" or event=="PLAYER_REGEN_ENABLED" then
        Reset("melee");Reset("ranged");state.pendingSpell=nil;state.pendingReset=nil
        state.meleeAttacking=nil
        state.nativeMelee=nil;state.nativeRanged=nil;state.rangedSpellAnchor=nil
        state.melee.speed=Speed("melee");state.ranged.speed=Speed("ranged");Names()
    elseif event=="PLAYER_ENTER_COMBAT" then state.meleeAttacking=true;state.melee.active=true
    elseif event=="PLAYER_LEAVE_COMBAT" then
        state.meleeAttacking=nil;state.nativeMelee=nil;Reset("melee")
    elseif event=="START_AUTOREPEAT_SPELL" then state.ranged.active=true
    elseif event=="STOP_AUTOREPEAT_SPELL" then Reset("ranged")
    elseif event=="PLAYER_EQUIPMENT_CHANGED" then
        if unit==16 or unit==17 or unit==18 then Reset("melee");Reset("ranged");Rescale("melee");Rescale("ranged") end
    elseif event=="UNIT_ATTACK_SPEED" or event=="UNIT_RANGEDDAMAGE" then
        if unit=="player" then Rescale("melee");Rescale("ranged") end
    elseif unit=="player" and event:find("^UNIT_SPELLCAST_") then
        local id=C.Number(spellID);local name=id and SpellName(id)
        if event=="UNIT_SPELLCAST_START" then
            state.pendingSpell=id;state.pendingReset=id and not noResetNames[name]
            if name and name==slamName then state.pendingReset=false;state.melee.paused=GetTime() end
        elseif event=="UNIT_SPELLCAST_SUCCEEDED" then
            if id==75 or id==5019 then
                state.rangedSpellAnchor=true;if not state.nativeRanged then Start("ranged") end
            elseif id and (queuedIDs[id] or queuedNames[name]) and not state.nativeMelee then Start("melee")
            elseif id and state.pendingSpell==id and state.pendingReset and state.melee.active
                and state.melee.start and MeleeAttacking() then Start("melee") end
            if state.pendingSpell==id then Resume();state.pendingSpell=nil;state.pendingReset=nil end
            if id==5384 then Reset("melee");Reset("ranged") end
        elseif event=="UNIT_SPELLCAST_FAILED" or event=="UNIT_SPELLCAST_FAILED_QUIET" or event=="UNIT_SPELLCAST_INTERRUPTED" then
            Resume();state.pendingSpell=nil;state.pendingReset=nil
        elseif event=="UNIT_SPELLCAST_STOP" then Resume() end
    end
end
local events={"COMBAT_LOG_EVENT_UNFILTERED","PLAYER_SWING","PLAYER_ENTERING_WORLD","PLAYER_DEAD","PLAYER_REGEN_ENABLED",
    "PLAYER_ENTER_COMBAT","PLAYER_LEAVE_COMBAT","START_AUTOREPEAT_SPELL","STOP_AUTOREPEAT_SPELL",
    "UNIT_ATTACK_SPEED","UNIT_RANGEDDAMAGE","PLAYER_EQUIPMENT_CHANGED","UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_SUCCEEDED","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_FAILED_QUIET","UNIT_SPELLCAST_INTERRUPTED"}
function A.Configure(view)
    if view.preview then return end
    local group=view.byID[GROUP]
    A.meleeEnabled=group and group.showMeleeProgress==true or false
    A.rangedEnabled=group and group.showRangedProgress==true or false
    local enabled=group and group.enabled~=false and (A.meleeEnabled or A.rangedEnabled) or false
    if not A.meleeEnabled then Reset("melee") end
    if not A.rangedEnabled then Reset("ranged") end
    if enabled==A.enabled then return end
    A.enabled=enabled
    if enabled then
        if not A.frame then
            A.frame=CreateFrame("Frame")
            A.frame:SetScript("OnEvent",function(_,event,...)M:Safe("攻击进度",A.Event,event,...)end)
        end
        for _,event in ipairs(events) do
            if event~="COMBAT_LOG_EVENT_UNFILTERED" or C.CombatLogAvailable() then
                pcall(A.frame.RegisterEvent,A.frame,event)
            end
        end
        A.Event("PLAYER_ENTERING_WORLD")
    else
        if A.frame then A.frame:UnregisterAllEvents() end
        Reset("melee");Reset("ranged")
    end
end
local function Active(kind)
    local s=state[kind]
    return A[kind.."Enabled"] and s.active and s.start and s.finish and s.speed and s.speed>0
        and (kind~="melee" or MeleeAttacking())
end
function A.Paint(view,o,player)
    local n=o.spec;local group=view.byID[GROUP];local kind=n.attackKind
    local enabled=group and (kind=="ranged" and group.showRangedProgress or kind=="melee" and group.showMeleeProgress)
    local chosen=state.latest
    if not chosen or not Active(chosen) then chosen=Active("ranged") and "ranged" or "melee" end
    local visible=enabled and n.enabled~=false and not player.cast.active and not player.dead
        and not (view.hidden and view.hidden[n.id]) and (view.preview or Active(kind) and chosen==kind) or false
    if view.preview and group and group.showRangedProgress and group.showMeleeProgress then visible=visible and kind=="ranged" end
    if o.frame:IsShown()~=visible then o.frame:SetShown(visible) end
    if not visible or n.attackFrame then return end
    local s=state[kind];local now=GetTime()
    local ratio=view.preview and .65 or M.Clamp(((s.paused or now)-s.start)/s.speed,0,1)
    if o.attackRatio==ratio then return end
    o.attackRatio=ratio
    o.texture:ClearAllPoints();o.texture:SetPoint("LEFT",o.frame,"LEFT",0,0)
    o.texture:SetSize(math.max(.001,(n.width or 512)*ratio),n.height or 128)
    o.texture:SetTexCoord(0,ratio,0,1);o.texture:SetShown(ratio>0)
    if o.castInterior then
        o.castInterior:ClearAllPoints();o.castInterior:SetPoint("LEFT",o.frame,"LEFT",24,0)
        o.castInterior:SetSize(math.max(.001,((n.width or 512)-48)*ratio),7);o.castInterior:SetShown(ratio>0)
    end
end
