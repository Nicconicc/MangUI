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
    local line=f:CreateTexture(nil,"ARTWORK");line:SetColorTexture(unpack(color))
    line:SetPoint("LEFT",f,"LEFT",24,0);line:SetSize(math.max(.001,(n.width or 512)-48),7)
    return f
end
local function Ensure(o)
    if o.empower then return o.empower end
    local f,n=o.frame,o.spec
    local a={};o.empower=a
    a.root=Frame(f,f:GetFrameLevel()+1);a.root:SetAllPoints(f)
    a.backgrounds={};a.colors={}
    for i=1,6 do
        -- Keep each stage tint above the moving fill so completed segments
        -- retain their individual colors. The spark and stage number sit above both.
        local clip=Frame(a.root,a.root:GetFrameLevel()+5);clip:SetClipsChildren(true)
        Art(clip,f,n,D.overlays[i]);a.backgrounds[i]=clip
    end
    a.driver=CreateFrame("StatusBar",nil,a.root);a.driver:SetAllPoints(f);a.driver:EnableMouse(false)
    a.driver:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    a.driver:SetStatusBarColor(1,1,1,0);a.driver:GetStatusBarTexture():SetAlpha(0)
    a.clip=Frame(a.root,a.root:GetFrameLevel()+3);a.clip:SetClipsChildren(true)
    for i,color in ipairs(D.colors)do a.colors[i]=Art(a.clip,f,n,color)end
    a.foreground=Frame(a.root,a.root:GetFrameLevel()+8);a.foreground:SetAllPoints(f)
    a.spark=a.foreground:CreateTexture(nil,"OVERLAY")
    a.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");a.spark:SetBlendMode("ADD")
    a.spark:SetVertexColor(unpack(D.sparkColor));a.spark:SetSize(D.sparkWidth,D.sparkHeight)
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
    a.signature=signature;a.stageCurves={};local points={{0,0}}
    for i,stage in ipairs(c.empowerStages)do points[#points+1]={stage.finish,i}end
    a.stageCurve=Step(points)
    local count=#c.empowerStages
    for i,clip in ipairs(a.backgrounds)do
        local stage=c.empowerStages[i]
        local lo,hi
        if stage then lo,hi=stage.start,stage.finish
        elseif i==6 then lo,hi=c.empowerStages[count].finish,c.empowerTotal end
        if lo and hi>lo then
            clip:ClearAllPoints();clip:SetPoint("LEFT",o.frame,"LEFT",width*lo/c.empowerTotal,0)
            clip:SetSize(width*(hi-lo)/c.empowerTotal,height);clip:Show()
        else clip:Hide()end
    end
    -- The WA changes the color of the entire current fill at each completed
    -- stage. Native step curves retain that behavior for restricted timings.
    for i=1,#D.colors do
        local lo=i==1 and 0 or c.empowerStages[i-1]and c.empowerStages[i-1].finish
        local hi=c.empowerStages[i]and c.empowerStages[i].finish
        if i==#D.colors then hi=nil end
        local p={{0,i==1 and 1 or 0}}
        if lo and lo>0 then p[#p+1]={lo,1}end
        if hi then p[#p+1]={hi,0}end
        a.stageCurves[i]=lo and Step(p)or nil
    end
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
    a.clip:ClearAllPoints();a.spark:ClearAllPoints()
    if native then
        a.driver:Show();a.clip:SetAllPoints(a.driver:GetStatusBarTexture())
        if not animateOnly or not a.bound then a.driver:SetTimerDuration(c.duration,nil,Enum.StatusBarTimerDirection.ElapsedTime)end
        a.bound=true;a.spark:SetPoint("CENTER",a.driver:GetStatusBarTexture(),"RIGHT",0,0)
    elseif elapsed then
        a.driver:Hide();a.bound=nil
        local width=(o.spec.width or 512)*M.Clamp(elapsed/c.empowerTotal,0,1)
        a.clip:SetPoint("LEFT",o.frame,"LEFT",0,0);a.clip:SetSize(math.max(.001,width),o.spec.height or 128)
        a.spark:SetPoint("CENTER",o.frame,"LEFT",width,0)
    else a.root:Hide();return false end
    local stage=0
    if elapsed then for i,v in ipairs(c.empowerStages)do if elapsed>=v.finish then stage=i end end end
    for i,f in ipairs(a.colors)do
        local alpha=elapsed and(i==math.min(stage+1,#D.colors)and 1 or 0)or 0
        if not elapsed and c.duration and a.stageCurves[i]then alpha=Query(c.duration.EvaluateElapsedDuration,c.duration,a.stageCurves[i])end
        if C.Readable(alpha)and alpha==nil then alpha=0 end
        f:SetAlpha(alpha)
    end
    local text=stage
    if not elapsed and c.duration and a.stageCurve then text=Query(c.duration.EvaluateElapsedDuration,c.duration,a.stageCurve)end
    if C.Readable(text)and text==nil then text=""end
    a.label:SetText(text)
    local name=M.byID and M.byID.waba76314011sub3
    a.label:SetShown(not name or name.enabled~=false)
    return true
end
