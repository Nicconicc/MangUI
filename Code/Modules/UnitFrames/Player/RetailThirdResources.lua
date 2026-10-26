local _,M=...
local C,P=M.Compat,M.ThirdResource
local D=M.SpecialBarData
local function Query(fn,...)
    if type(fn)~="function"then return end
    local ok,value=pcall(fn,...);if ok then return value end
end
local function Aura(id)
    local a=Query(C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID,id)
    if not C.Readable(a)or type(a)~="table"or(canaccesstable and not canaccesstable(a))then return end
    local source=a.sourceUnit
    if C.Readable(source)and source~=nil and source~="player"then return end
    return a
end
local function Known(id)
    for _,fn in ipairs({IsPlayerSpell or false,IsSpellKnownOrOverridesKnown or false,IsSpellKnown or false,
        C_SpellBook and C_SpellBook.IsSpellKnown or false})do
        if type(fn)=="function"then
            local value=Query(fn,id)
            if C.Readable(value)and type(value)=="boolean"then return value end
        end
    end
    return false
end
function P.Refresh(s,preview)
    if preview or not s.thirdCustom or s.thirdTimeAt==GetTime()then return end
    s.thirdTimeAt=GetTime()
    local timer=s.thirdTimer
    if timer then
        s.power=Query(timer.GetRemainingDuration,timer)
        s.maxPower=Query(timer.GetTotalDuration,timer)
        s.powerRatio=C.Number(Query(timer.GetRemainingPercent,timer))
        local remaining=C.Number(s.power)
        if remaining and remaining<=0 then s.resourceAvailable=false end
    elseif s.thirdExpires then
        s.power=math.max(0,s.thirdExpires-GetTime());s.maxPower=s.thirdTotal
        s.powerRatio=s.maxPower>0 and M.Clamp(s.power/s.maxPower,0,1)or 0
        if s.power<=0 then s.resourceAvailable=false end
    end
    local value,maximum=C.Number(s.power),C.Number(s.maxPower)
    if not timer and not s.thirdExpires then s.powerRatio=value and maximum and maximum>0 and M.Clamp(value/maximum,0,1)or nil end
end
function P.Value(s)
    if not s.showThirdValue then return ""end
    if s.thirdValueKind=="time"then
        local value=C.Number(s.power)
        if value then return string.format("%.1f",math.max(0,value))end
        if s.thirdTimer and s.thirdTimer.FormatRemainingDuration and C_StringUtil and C_StringUtil.CreateNumericRuleFormatter then
            if not P.secondsFormatter then
                P.secondsFormatter=C_StringUtil.CreateNumericRuleFormatter()
                P.secondsFormatter:SetBreakpoints({{threshold=0,step=.1,format="%.1f"}})
            end
            return s.thirdTimer:FormatRemainingDuration(P.secondsFormatter)
        end
        return ""
    end
    if not C.Readable(s.power)then return s.power end
    return C.Number(s.power,0)
end
local sparkCurves={}
function P.SparkAlpha(s,alpha)
    if not(C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType)then return 0 end
    local maximum=s.thirdTimer and 1 or C.Number(s.maxPower)
    if not maximum or maximum<=0 then return 0 end
    local key=tostring(maximum)..":"..tostring(alpha)
    local curve=sparkCurves[key]
    if not curve then
        curve=C_CurveUtil.CreateCurve();curve:SetType(Enum.LuaCurveType.Step)
        curve:AddPoint(0,0);curve:AddPoint(.0000001,alpha);curve:AddPoint(maximum,0)
        sparkCurves[key]=curve
    end
    if s.thirdTimer then return Query(s.thirdTimer.EvaluateRemainingPercent,s.thirdTimer,curve)end
    return Query(curve.Evaluate,curve,s.power)
end
P.Register("retailEbonMight",{class="EVOKER",spec=D.ebon.spec,minimum=100000,maximum=999999,retail=true,color=D.ebon.color,
    state=function(view,s)
        s.showThirdValue=true;s.thirdValueKind="time"
        if view.preview then s.power,s.maxPower,s.powerRatio=10,20,.5;return end
        local a=Aura(D.ebon.aura)
        if not a then s.resourceAvailable=false;return end
        if C.Number(a.auraInstanceID)then s.thirdTimer=Query(C_UnitAuras.GetAuraDuration,"player",a.auraInstanceID)end
        s.thirdExpires,s.thirdTotal=C.Number(a.expirationTime),C.Number(a.duration)
        if not s.thirdTimer and(not s.thirdExpires or not s.thirdTotal or s.thirdTotal<=0)then s.resourceAvailable=false end
    end})
P.Register("retailStagger",{class="MONK",spec=D.stagger.spec,minimum=100000,maximum=999999,retail=true,color=D.stagger.color,
    state=function(view,s)
        s.showThirdValue=true;s.thirdValueKind="stagger"
        if view.preview then s.power,s.maxPower,s.powerRatio=35000,100000,.35;return end
        s.power=Query(UnitStagger,"player");s.maxPower=Query(UnitHealthMax,"player")
        if C.Readable(s.power)and C.Number(s.power)==nil then s.power=0 end
        local maximum=C.Number(s.maxPower)
        if maximum and maximum<=0 then s.resourceAvailable=false end
    end})
P.Register("retailFlurryStrikes",{class="MONK",spec=D.windwalker.spec,minimum=110000,maximum=999999,retail=true,color=D.windwalker.color,
    available=function()return Known(D.windwalker.knownSpell)end,
    state=function(view,s)
        s.showThirdValue=true;s.thirdValueKind="stacks";s.maxPower=D.windwalker.maximum
        if view.preview then s.power=160;s.powerRatio=160/D.windwalker.maximum;return end
        local a=Aura(D.windwalker.aura)
        if a then s.power=a.applications else s.power=0 end
        if C.Readable(s.power)and s.power==nil then s.power=0 end
        -- Keep the user-approved mint color at every stack count, including >185.
    end})
