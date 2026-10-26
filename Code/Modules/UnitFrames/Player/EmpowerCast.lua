local _,M=...
local C,D=M.Compat,M.SpecialBarData.empower
local E={};M.EmpowerCast=E
local function Query(fn,...)
    if type(fn)~="function"then return end
    local ok,value=pcall(fn,...);if ok then return value end
end
function E.Decorate(c,unit,count)
    c.empowered=true;c.channel=false
    count=C.Number(count)
    if not count or count<1 or count>5 then return end
    local stages,total={},0
    for i=1,count do
        local ms=C.Number(Query(GetUnitEmpowerStageDuration,unit,i-1))
        if not ms or ms<=0 then return end
        stages[i]={start=total,finish=total+ms/1000};total=stages[i].finish
    end
    local hold=C.Number(Query(GetUnitEmpowerHoldAtMaxTime,unit))
    if not hold or hold<0 then return end
    c.empowerStages,c.empowerHold,c.empowerTotal=stages,hold,total+hold/1000
    if c.start then c.finish=c.start+c.empowerTotal end
    -- Native duration objects can carry a restricted start time without Lua
    -- inspecting or doing arithmetic on it. Stage lengths must be public.
    if C_DurationUtil and C_DurationUtil.CreateDuration then
        local start=c.start
        if not start and c.duration then start=Query(c.duration.GetStartTime,c.duration)end
        if not C.Readable(start)or type(start)=="number"then
            local full=C_DurationUtil.CreateDuration()
            if full and full.SetTimeFromStart then
                full:SetTimeFromStart(start,c.empowerTotal);c.duration=full;c.empowerNative=true
            end
        end
    end
end
function E.Preview(c)
    if not C.retail or not c.active then return end
    local _,class=UnitClass("player");if class~="EVOKER"then return end
    c.empowered=true;c.channel=false;c.empowerHold=1;c.empowerTotal=4
    c.empowerStages={{start=0,finish=1},{start=1,finish=2},{start=2,finish=3}}
    c.start=GetTime()-1.5;c.finish=c.start+4
end
local function Frame(parent,level)
    local f=CreateFrame("Frame",nil,parent,"DisableUntrustedLayoutScriptsTemplate")
    f:EnableMouse(false);f:SetFrameLevel(level);return f
end
local function Art(parent,owner,n,color)
    local f=Frame(parent,parent:GetFrameLevel()+1);f:SetAllPoints(owner)
    local t=f:CreateTexture(nil,"ARTWORK");t:SetAllPoints();t:SetTexture(n.file)
    t:SetBlendMode(n.blend or "BLEND");t:SetVertexColor(unpack(color))
    local line=f:CreateTexture(nil,"ARTWORK");line:SetColorTexture(1,1,1,1);line:SetVertexColor(unpack(color))
    line:SetPoint("LEFT",f,"LEFT",24,0);line:SetSize(math.max(.001,(n.width or 512)-48),7)
    f.art,f.line=t,line;return f
end
local function Ensure(o)
    if o.empower then return o.empower end
    local f,n=o.frame,o.spec
    local a={};o.empower=a
    a.root=Frame(f,f:GetFrameLevel()+1);a.root:SetAllPoints(f)
    a.backgrounds={};a.dimmed={};a.colors={};a.boundaries={}
    for i=1,6 do
        -- Both layers use the same stage color and crop of the full artwork.
        -- A whole segment becomes bright only when its finish time is reached.
        local clip=Frame(a.root,a.root:GetFrameLevel()+1);clip:SetClipsChildren(true)
        local color=D.colors[math.min(i,#D.colors)]
        a.dimmed[i]=Art(clip,f,n,{color[1]*.24,color[2]*.24,color[3]*.24,1})
        local bright=Art(clip,f,n,color);bright:SetFrameLevel(clip:GetFrameLevel()+2)
        bright:SetAlpha(0);a.backgrounds[i]=clip;a.colors[i]=bright
    end
    a.driver=CreateFrame("StatusBar",nil,a.root);a.driver:SetAllPoints(f);a.driver:EnableMouse(false)
    a.driver:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    a.driver:SetStatusBarColor(1,1,1,0);a.driver:GetStatusBarTexture():SetAlpha(0)
    a.foreground=Frame(a.root,a.root:GetFrameLevel()+8);a.foreground:SetAllPoints(f)
    a.halo=a.foreground:CreateTexture(nil,"OVERLAY")
    a.halo:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");a.halo:SetBlendMode("ADD")
    a.halo:SetVertexColor(unpack(D.sparkColor));a.halo:SetSize(84,48);a.halo:SetAlpha(.6)
    a.spark=a.foreground:CreateTexture(nil,"OVERLAY")
    a.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");a.spark:SetBlendMode("ADD")
    a.spark:SetVertexColor(1,1,.9,1);a.spark:SetSize(52,36)
    a.sparkCore=a.foreground:CreateTexture(nil,"OVERLAY")
    a.sparkCore:SetColorTexture(1,1,.9,1);a.sparkCore:SetBlendMode("ADD");a.sparkCore:SetSize(2,12)
    for i=1,5 do
        local boundary=Frame(a.root,a.root:GetFrameLevel()+6)
        boundary:SetSize(1,12)
        local marker=boundary:CreateTexture(nil,"ARTWORK");marker:SetAllPoints();marker:SetColorTexture(1,1,1,.25)
        local flash=Frame(boundary,boundary:GetFrameLevel()+1);flash:SetAllPoints(boundary)
        local color=D.colors[i]
        local glow=flash:CreateTexture(nil,"OVERLAY");glow:SetPoint("CENTER");glow:SetSize(62,38)
        glow:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");glow:SetBlendMode("ADD");glow:SetVertexColor(unpack(color))
        local core=flash:CreateTexture(nil,"OVERLAY");core:SetPoint("CENTER");core:SetSize(24,46)
        core:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");core:SetBlendMode("ADD");core:SetVertexColor(1,1,.9,1)
        flash:SetAlpha(0);boundary.flash=flash;a.boundaries[i]=boundary
    end
    a.label=a.foreground:CreateFontString(nil,"OVERLAY")
    a.label:SetFont(M.MYRIAD,D.stageFontSize,"OUTLINE")
    a.label:SetTextColor(1,1,1,1);a.label:SetShadowColor(0,0,0,1);a.label:SetShadowOffset(2,-2)
    a.label:SetPoint("CENTER",f,"CENTER",0,30)
    return a
end
local function Step(points)
    if not(C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType)then return end
    local curve=C_CurveUtil.CreateCurve();curve:SetType(Enum.LuaCurveType.Step)
    for _,p in ipairs(points)do curve:AddPoint(p[1],p[2])end
    return curve
end
local function Layout(a,o,c)
    local width,height=o.spec.width or 512,o.spec.height or 128
    local signature=width..":"..height..":"..c.empowerTotal
    for _,stage in ipairs(c.empowerStages)do signature=signature..":"..stage.finish end
    if a.signature==signature then return end
    a.signature=signature;a.stageCurves={};a.flashCurves={};local points={{0,0}}
    for i,stage in ipairs(c.empowerStages)do points[#points+1]={stage.finish,i}end
    a.stageCurve=Step(points)
    local count=#c.empowerStages
    -- The hold interval belongs to the last real stage, regardless of whether
    -- this spell has three, four or five stages.
    local last=D.colors[count]
    for _,texture in ipairs({a.colors[6].art,a.colors[6].line})do texture:SetVertexColor(unpack(last))end
    for _,texture in ipairs({a.dimmed[6].art,a.dimmed[6].line})do texture:SetVertexColor(last[1]*.24,last[2]*.24,last[3]*.24,1)end
    for i,clip in ipairs(a.backgrounds)do
        local stage=c.empowerStages[i]
        local lo,hi
        if stage then lo,hi=stage.start,stage.finish
        elseif i==6 then lo,hi=c.empowerStages[count].finish,c.empowerTotal end
        if lo and hi>lo then
            clip:ClearAllPoints();clip:SetPoint("LEFT",o.frame,"LEFT",width*lo/c.empowerTotal,0)
            clip:SetSize(width*(hi-lo)/c.empowerTotal,height);clip:Show()
            -- The hold area shares the final stage's bright state; it never
            -- creates another completed-stage count.
            local finish=stage and stage.finish or c.empowerStages[count].finish
            a.stageCurves[i]=Step({{0,0},{finish,1}})
        else clip:Hide()end
    end
    for i,boundary in ipairs(a.boundaries)do
        local stage=c.empowerStages[i]
        if stage then
            boundary:ClearAllPoints();boundary:SetPoint("CENTER",o.frame,"LEFT",width*stage.finish/c.empowerTotal,0);boundary:Show()
            a.flashCurves[i]=Step({{0,0},{stage.finish,1},{stage.finish+.08,.65},{stage.finish+.18,.25},{stage.finish+.32,0}})
        else boundary:Hide();boundary.flash:SetAlpha(0)end
    end
end
local function Evaluate(c,elapsed,curve,fallback)
    if not curve then return fallback end
    local value
    if elapsed then value=Query(curve.Evaluate,curve,elapsed)
    elseif c.duration then value=Query(c.duration.EvaluateElapsedDuration,c.duration,curve)end
    if C.Readable(value)and value==nil then return fallback end
    return value
end
function E.Paint(view,o,s,animateOnly)
    local c=s.cast
    if not c.active or not c.empowered or not c.empowerStages then
        if o.empower then o.empower.root:Hide();o.empower.bound=nil end
        return false
    end
    local a=Ensure(o);Layout(a,o,c);a.root:Show()
    local P=M.RendererInternals
    P.CachedValue(o,"castShown",o.texture,"SetShown",false)
    P.CachedValue(o,"castInteriorShown",o.castInterior,"SetShown",false)
    if o.nativeCast then o.nativeCast.timer:Hide();o.nativeCast.interior:Hide();o.nativeCast.bound=nil end
    local elapsed=c.start and math.max(0,GetTime()-c.start)
    local native=not view.preview and c.empowerNative and c.duration and a.driver.SetTimerDuration and Enum and Enum.StatusBarTimerDirection
    a.spark:ClearAllPoints()
    if native then
        a.driver:Show()
        if not animateOnly or not a.bound then a.driver:SetTimerDuration(c.duration,nil,Enum.StatusBarTimerDirection.ElapsedTime)end
        a.bound=true;a.spark:SetPoint("CENTER",a.driver:GetStatusBarTexture(),"RIGHT",0,0)
    elseif elapsed then
        a.driver:Hide();a.bound=nil
        local width=(o.spec.width or 512)*M.Clamp(elapsed/c.empowerTotal,0,1)
        a.spark:SetPoint("CENTER",o.frame,"LEFT",width,0)
    else a.root:Hide();return false end
    a.halo:ClearAllPoints();a.halo:SetPoint("CENTER",a.spark,"CENTER",0,0)
    a.sparkCore:ClearAllPoints();a.sparkCore:SetPoint("CENTER",a.spark,"CENTER",0,0)
    for i,f in ipairs(a.colors)do
        local stage=c.empowerStages[i]or i==6 and c.empowerStages[#c.empowerStages]
        local complete=elapsed and stage and elapsed>=stage.finish and 1 or 0
        f:SetAlpha(Evaluate(c,elapsed,a.stageCurves[i],complete))
    end
    for i,boundary in ipairs(a.boundaries)do
        local stage=c.empowerStages[i];local alpha=0
        if elapsed and stage then
            local age=elapsed-stage.finish
            alpha=age>=0 and(age<.08 and 1 or age<.18 and .65 or age<.32 and .25 or 0)or 0
        end
        boundary.flash:SetAlpha(Evaluate(c,elapsed,a.flashCurves[i],alpha))
    end
    local stage=0
    if elapsed then for i,v in ipairs(c.empowerStages)do if elapsed>=v.finish then stage=i end end end
    a.label:SetText(Evaluate(c,elapsed,a.stageCurve,stage))
    local name=M.byID and M.byID.waba76314011sub3
    a.label:SetShown(not name or name.enabled~=false)
    return true
end
