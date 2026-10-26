local _,M=...
local C,B,R=M.Compat,M.MainBarLayout,M.Renderer
local unpack=unpack or table.unpack
local private=M.RendererInternals
local Readable=private.Readable
local Cache=private.Cache

local function State(view,unit)
    unit=unit or "player"
    if unit=="shared" and view.preview then unit=view.scene=="noTarget" and "player" or "target" end
    if not view.cache[unit] then
        local state
        if unit=="playerThirdResource"then state=M.ThirdResource.State(view,view.stateBuffers[unit])
        else
            state=(view.stateProvider or C.State)(unit,view.preview,view.scene,view.stateBuffers[unit],view.stateFields[unit])
            if M.PartyFrames then M.PartyFrames.ExtendState(view,state) end
        end
        view.stateBuffers[unit]=state;view.cache[unit]=state
    end
    return view.cache[unit]
end
local function Rule(view,r)
    local s=State(view,r.unit);local v=false
    if r.test=="exists" then v=s.exists
    elseif r.test=="casting" then v=s.cast.active
    elseif r.test=="targetOrCasting" then v=State(view,"target").exists or State(view,"player").cast.active
    elseif r.test=="classification" then for _,c in ipairs(r.values or {}) do if s.classification==c then v=true end end
    elseif r.test=="hearth" then v=false
        if s.cast.active and C.Readable(s.cast.name) then v=s.cast.name=="炉石" or s.cast.name=="Hearthstone" end
    elseif r.test=="raid" then v=type(s.raid)~="nil"
    else v=s[r.test] end
    if r.invert then return not v end
    return not not v
end
local white={1,1,1,1}
local tappedColor={.777,.777,.777,1}
local healthGreen={0,1,.42745101451874,1}
local function Appearance(view,n,s,o)
    local hidePlayerPower=n.id=="wa8ee62b16d6"and(s.powerType==1 or s.powerType==2 or s.powerType==3 or s.powerType==6
        or C.retail and(s.powerType==8 or s.powerType==11 or s.powerType==13 or s.powerType==17))
    if o.fixedAppearance then return n.color or white,hidePlayerPower and 0 or n.alpha or 1 end
    local col=n.color or white;local alpha=n.alpha or 1
    local tint=o.appearanceColor or {};o.appearanceColor=tint
    tint[1],tint[2],tint[3],tint[4]=col[1],col[2],col[3],col[4] or 1
    if n.powerColor and s.powerColor then tint[1],tint[2],tint[3]=s.powerColor[1],s.powerColor[2],s.powerColor[3] end
    if n.nameColor and s.nameColor then tint[1],tint[2],tint[3]=s.nameColor[1],s.nameColor[2],s.nameColor[3] end
    if n.targetNameColor then
        if s.isPlayer and s.nameColor then tint[1],tint[2],tint[3]=s.nameColor[1],s.nameColor[2],s.nameColor[3]
        elseif s.reaction==4 then tint[1],tint[2],tint[3]=1,.82,0
        elseif (s.reaction and s.reaction>=5) or (not s.reaction and s.friendly) then tint[1],tint[2],tint[3]=0,1,.32
        else tint[1],tint[2],tint[3]=1,0,0 end
    end
    if o.targetLevelColor then
        local r,g,b=C.LevelDifficultyColor(s.unit,s.level,view.preview)
        if r then tint[1],tint[2],tint[3]=r,g,b end
    end
    col=tint
    for _,c in ipairs(n.conditions or {}) do
        local st=State(view,c.unit);local value
        if c.field=="percenthealth" then value=st.healthRatio and st.healthRatio*100
        elseif c.field=="powertype" then value=st.powerType
        elseif c.field=="partyDispel" then value=st.partyDispel
        elseif c.field=="partyOutOfRange" then value=st.partyOutOfRange and 1 or 0
        elseif c.field=="hastarget" then value=State(view,"target").exists and 1 or 0 end
        local expected=c.field=="partyDispel" and c.value or tonumber(c.value);local match=false
        if value~=nil and expected then
            match=(c.op=="<" and value<expected) or (c.op==">" and value>expected) or (c.op=="==" and value==expected)
                or (c.op=="<=" and value<=expected) or (c.op==">=" and value>=expected)
        end
        if match then for _,change in ipairs(c.changes) do
            if change.field=="color" then
                if not (o.targetHealthThreshold and c.field=="percenthealth" and c.op=="<") then col=change.value end
            else alpha=change.value end
        end end
    end
    -- Keep a single resource value for rage, focus, energy, runic power and
    -- retail Astral Power/Maelstrom/Insanity/Fury. Apply to saved layouts and previews.
    if hidePlayerPower then alpha=0 end
    if n.tapColor and s.tapped then col=tappedColor end
    if o.customHealthStyle then
        local start=n.healthColor or n.color or healthGreen
        tint[1],tint[2],tint[3],tint[4]=start[1],start[2],start[3],start[4] or 1;col=tint
    end
    o.healthThresholdActive=o.targetHealthThreshold and n.healthThresholdEnabled==true and not o.classHealthColor
        and s.healthRatio~=nil and s.healthRatio<(n.healthThreshold or 25)/100 or false
    if o.healthThresholdActive then
        local warning=n.healthThresholdColor or {1,0,0,1}
        tint[1],tint[2],tint[3],tint[4]=warning[1],warning[2],warning[3],warning[4] or 1;col=tint
    end
    if o.classHealthColor then
        local class=s.isPlayer and s.classColor
        if class then tint[1],tint[2],tint[3]=class.r,class.g,class.b
        elseif s.isPlayer then tint[1],tint[2],tint[3]=1,1,1
        else tint[1],tint[2],tint[3]=healthGreen[1],healthGreen[2],healthGreen[3] end
        tint[4]=col[4] or 1;col=tint
    end
    -- Creature ownership takes priority over configured health colors. Forever
    -- may use the mainline project id, but must follow the Classic tap rule.
    o.tapColorActive=not view.preview and (not C.retail or C.interface==16001)
        and n.tapColor==true and s.tapped==true
    if o.tapColorActive then
        tint[1],tint[2],tint[3],tint[4]=tappedColor[1],tappedColor[2],tappedColor[3],col[4] or 1
        col=tint;o.healthThresholdActive=false
    end
    return col,alpha
end
local function CastRatio(s)
    local c=s.cast
    if not c.active or not c.start or not c.finish or c.finish<=c.start then return nil end
    local p=M.Clamp((GetTime()-c.start)/(c.finish-c.start),0,1)
    return c.channel and 1-p or p
end
local function DisplayRatio(view,o,n,target,animateOnly)
    if not n.smooth or view.preview or target==nil then
        o.displayRatio=target;o.smoothTarget=target;o.smoothStart=nil
        return target
    end
    local now=GetTime()
    if o.displayRatio==nil then
        o.displayRatio=target;o.smoothTarget=target;o.smoothStart=nil
    elseif not animateOnly and target~=o.smoothTarget then
        o.smoothFrom=o.displayRatio;o.smoothTarget=target;o.smoothStart=now
    end
    if o.smoothStart then
        local progress=M.Clamp((now-o.smoothStart)/(n.smoothDuration or .35),0,1)
        local eased=1-(1-progress)^3
        o.displayRatio=o.smoothFrom+(o.smoothTarget-o.smoothFrom)*eased
        if progress>=1 then o.displayRatio=o.smoothTarget;o.smoothStart=nil end
    end
    return o.displayRatio
end
local function RestrictedHealthColor(o,s)
    if not (C_CurveUtil and C_CurveUtil.CreateColorCurve and CreateColor and UnitHealthPercent and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step) then return end
    local n=o.spec
    if not o.healthCurve then
        local stops={0,1}
        for _,c in ipairs(n.conditions or {}) do
            if c.field=="percenthealth" and c.op=="<" and tonumber(c.value) then stops[#stops+1]=tonumber(c.value)/100 end
        end
        table.sort(stops)
        local curve=C_CurveUtil.CreateColorCurve();curve:SetType(Enum.LuaCurveType.Step)
        local previous
        for _,p in ipairs(stops) do
            if p~=previous then
                local col=n.color or {1,1,1,1}
                for _,condition in ipairs(n.conditions or {}) do
                    if condition.field=="percenthealth" and condition.op=="<" and p*100<tonumber(condition.value) then
                        for _,change in ipairs(condition.changes) do if change.field=="color" then col=change.value end end
                    end
                end
                curve:AddPoint(p,CreateColor(unpack(col)));previous=p
            end
        end
        o.healthCurve=curve
    end
    local color=UnitHealthPercent(s.unit,true,o.healthCurve)
    if color and color.GetRGBA then
        if o.nativeArt then o.nativeArt:SetVertexColor(color:GetRGBA())
        else o.bar:SetStatusBarColor(color:GetRGBA()) end
        Cache(o).barColor=nil
    end
end
local function RestrictedHealthThreshold(o,s,col)
    local n=o.spec
    if not (o.targetHealthThreshold and n.healthThresholdEnabled==true and not o.classHealthColor and not o.tapColorActive
        and C_CurveUtil and C_CurveUtil.CreateColorCurve and CreateColor and UnitHealthPercent
        and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step) then return end
    -- Gradient APIs cannot receive secret curve colors. Preserve the configured
    -- gradient underneath and use a secret-safe alpha for the warning overlay.
    local overlay=o.healthWarning
    if not overlay then return end
    local point=(n.healthThreshold or 25)/100
    local curve=o.healthWarningCurve
    if not curve or o.healthWarningPoint~=point then
        curve=C_CurveUtil.CreateColorCurve();curve:SetType(Enum.LuaCurveType.Step)
        if point>0 then curve:AddPoint(0,CreateColor(1,1,1,1)) end
        curve:AddPoint(point,CreateColor(1,1,1,0))
        if point<1 then curve:AddPoint(1,CreateColor(1,1,1,0)) end
        o.healthWarningCurve=curve;o.healthWarningPoint=point
    end
    local color=UnitHealthPercent(s.unit,true,curve)
    if not (color and color.GetRGBA) then return end
    local _,_,_,alpha=color:GetRGBA()
    overlay:SetVertexColor(unpack(n.healthThresholdColor or {1,0,0,1}))
    overlay:SetAlpha(alpha);overlay:Show()
end
local function Text(n,s)
    local b=n.binding
    if n.partyName then return M.PartyFrames.Name(s.name or "") end
    if b=="name" then return s.name or "" end
    if b=="healthText" then return not s.connected and M:T("离线") or (s.dead and M:T("死亡") or s.health or "") end
    if b=="powerText" then return s.power or "" end
    if b=="healthPercent" then return s.healthRatio and string.format("%.0f%%",s.healthRatio*100) or "" end
    if b=="powerPercent" then
        if n.manaPercentOtherwiseValue and s.powerType~=0 then return s.power or "" end
        return s.powerRatio and string.format("%.0f%%",s.powerRatio*100) or ""
    end
    if b=="level" then return C.Number(s.level,0)<0 and "??" or s.level or "" end
    if b=="castName" then return s.cast.name or "" end
    if b=="castTime" then
        if s.cast.finish then return string.format("%.1f",math.max(0,s.cast.finish-GetTime())) end
        local duration=s.cast.duration
        if duration and duration.FormatRemainingDuration and C_StringUtil and C_StringUtil.CreateNumericRuleFormatter then
            if not M.castSecondsFormatter then
                M.castSecondsFormatter=C_StringUtil.CreateNumericRuleFormatter()
                M.castSecondsFormatter:SetBreakpoints({{threshold=0,step=.1,format="%.1f"}})
            end
            return duration:FormatRemainingDuration(M.castSecondsFormatter)
        end
        return ""
    end
    if b=="petStatus" then return M:T(s.petStatus or "") end
    if b=="auraStacks" then return "3" end
    if b=="auraTime" then return "12" end
    return n.text or ""
end

M.RendererInternals.State=State
M.RendererInternals.Rule=Rule
M.RendererInternals.white=white
M.RendererInternals.tappedColor=tappedColor
M.RendererInternals.healthGreen=healthGreen
M.RendererInternals.Appearance=Appearance
M.RendererInternals.CastRatio=CastRatio
M.RendererInternals.DisplayRatio=DisplayRatio
M.RendererInternals.RestrictedHealthColor=RestrictedHealthColor
M.RendererInternals.RestrictedHealthThreshold=RestrictedHealthThreshold
M.RendererInternals.Text=Text
