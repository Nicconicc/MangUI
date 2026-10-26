local _,M=...
local C,P=M.Compat,M.ThirdResource
-- Match Blizzard's DemonHunterSoulFragmentsBar: these are collected souls,
-- not Fury, world fragments or the Annihilator's three Voidfall points.
local D={spec=1480,meta=1217607,souls=1225789,star=1227702,glutton=1247534,
    color={.55,.25,.85,1}}
P.Devourer=D
local function Query(fn,...)
    if type(fn)~="function"then return end
    local ok,value=pcall(fn,...);if ok then return value end
end
local function Aura(id)
    local fn=C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
    if not fn then return nil,false end
    local ok,a=pcall(fn,id)
    if not ok or not C.Readable(a)then return nil,false end
    if a==nil then return nil,true end
    if type(a)~="table"or(canaccesstable and not canaccesstable(a))then return nil,false end
    local source=a.sourceUnit
    if not C.Readable(source)then return nil,false end
    if source~=nil and source~="player"then return nil,true end
    return a,true
end
local function FallbackMaximum()
    for _,fn in ipairs({IsPlayerSpell or false,IsSpellKnownOrOverridesKnown or false,IsSpellKnown or false})do
        local known=Query(fn,D.glutton)
        if C.Readable(known)and known==true then return 35 end
    end
    return 50
end
function D.Maximum(meta)
    local maximum
    if meta then maximum=Query(GetCollapsingStarCost)
    else maximum=Query(C_Spell and C_Spell.GetSpellMaxCumulativeAuraApplications,D.souls)end
    -- Preserve an opaque maximum for the native bar. Never infer a restricted
    -- value or replace a valid game result with a hard-coded threshold.
    if not C.Readable(maximum)then return maximum end
    if type(maximum)=="number"and maximum>0 then return maximum end
    return meta and 30 or FallbackMaximum()
end
P.Register("retailDevourerSouls",{class="DEMONHUNTER",spec=D.spec,minimum=120000,maximum=999999,retail=true,color=D.color,
    state=function(view,s)
        s.showThirdValue=true;s.thirdValueKind="stacks"
        if view.preview then
            local maximum=C.Number(D.Maximum(false),FallbackMaximum())
            s.maxPower=maximum;s.power=math.floor(maximum*.7);s.powerRatio=s.power/maximum
            return
        end
        -- The official resource widget uses these same permitted self-aura
        -- queries. Unreadable identities fail safely rather than guessing a phase.
        local meta,known=Aura(D.meta)
        if not known then s.resourceAvailable=false;return end
        s.maxPower=D.Maximum(meta~=nil)
        local aura,available=Aura(meta and D.star or D.souls)
        if not available then s.resourceAvailable=false;return end
        s.power=aura and aura.applications or 0
        if C.Readable(s.power)and type(s.power)~="number"then s.power=0 end
    end})
