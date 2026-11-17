local _,M=...
local C,B,R=M.Compat,M.MainBarLayout,M.Renderer
local unpack=unpack or table.unpack
local private=M.RendererInternals
local Readable=private.Readable
local CachedValue=private.CachedValue
local CachedPair=private.CachedPair
local CachedColor=private.CachedColor
local CachedPoint=private.CachedPoint
local State=private.State
local Appearance=private.Appearance

local function FillStart(view,n,barFrame)
    if B.bars[n.id] then
        local token=view.nodes[B.tokenID]
        if not token then return 0 end
        local edge=token.frame
        local barScale,edgeScale=barFrame:GetEffectiveScale(),edge:GetEffectiveScale()
        local barEdge=n.reverse and barFrame:GetRight() or barFrame:GetLeft()
        local _,tokenY=edge:GetCenter();local _,barY=barFrame:GetCenter()
        local leftUV,rightUV=B.ContactAtHeight(token.spec,n,tokenY*edgeScale,edge:GetHeight()*edgeScale,
            barY*barScale,barFrame:GetHeight()*barScale)
        local tokenEdge=edge:GetLeft()
        if tokenEdge then tokenEdge=tokenEdge+(n.reverse and leftUV or rightUV)*edge:GetWidth() end
        if not barEdge or not tokenEdge or not barScale or barScale<=0 then return 0 end
        local covered=(barEdge*barScale-tokenEdge*edgeScale)/barScale
        if not n.reverse then covered=-covered end
        return M.Clamp(covered-(n.fillInset or 0),0,(n.width or 1)*(n.fillExtent or 1))
    end
    if not n.startAt then return 0 end
    local edge=view.nodes[n.startAt]
    edge=edge and edge.frame
    if not edge then return 0 end
    local right,left=edge:GetRight(),barFrame:GetLeft()
    local edgeScale,barScale=edge:GetEffectiveScale(),barFrame:GetEffectiveScale()
    if not right or not left or not barScale or barScale==0 then return 0 end
    return M.Clamp((right*edgeScale-left*barScale)/barScale-(n.startOverlap or 24),0,(n.width or 1)*(n.fillExtent or 1))
end
local DAMAGE_HOLD,DAMAGE_RETRACT,HEAL_FLASH=.15,.35,.22
local function ClearHealthChange(o)
    o.healthChangeRatio=nil
    o.healthChangeMaximum=nil
    o.healthChangeActive=nil
    local native=o.nativeHealthChange
    if native and native.ready then
        native.ready=nil;native.pending=nil;native.pendingHealth=nil
        native.layer:Hide()
    end
    local fx=o.healthChange
    if not fx then return end
    fx.tail,fx.damageAt,fx.damageStep,fx.healFrom,fx.healAt=nil,nil,nil,nil,nil
    fx.damage:Hide()
    fx.heal:Hide()
end

local SHAKE_THRESHOLD,SHAKE_INTERVAL,SHAKE_DURATION=.004,.22,.21
local RESTRICTED_SHAKE_INTERVAL,RESTRICTED_SHAKE_AMPLITUDE=.32,2.4
local PORTRAIT_SHAKE_DELAY,PORTRAIT_SHAKE_DURATION=.025,.26
local PORTRAIT_SHAKE_STRENGTH,PORTRAIT_SHAKE_DECAY=.85,1.2

local function StopMainHealthShake(view)
    local state=view.mainHealthShake
    if not state then return end
    state.started,state.amplitude=nil,nil
    state.ratio,state.maximum,state.nextAt,state.epoch,state.maxEpoch=nil,nil,nil,nil,nil
    R.ResetMainHealthShakeOffset(view)
end

local function MainShakeEnabled(view)
    local group=view.byID and view.byID.mainComposite
    return not group or group.shakeEnabled~=false
end

local function ShakeWave(age,duration,amplitude,decay)
    if age<=0 or age>=duration then return 0,0 end
    local progress=age/duration
    local strength=amplitude*(1-progress)^decay
    local swing=progress*math.pi*4
    return math.sin(swing)*strength,math.sin(swing*1.25)*strength*.24
end

function R.MainHealthShakeOffset(view,now)
    local state=view.mainHealthShake
    if view.preview or view.encounterActive or not state or not state.started then return 0,0,0,0 end
    if not MainShakeEnabled(view) then
        StopMainHealthShake(view)
        return 0,0,0,0
    end
    local age=now-state.started
    if age>=PORTRAIT_SHAKE_DELAY+PORTRAIT_SHAKE_DURATION then
        state.started=nil
        return 0,0,0,0
    end
    local x,y=ShakeWave(age,SHAKE_DURATION,state.amplitude,2)
    -- The delayed wave gives the portrait a clear follow-through as the
    -- underlying frame settles.
    local lagX,lagY=ShakeWave(age-PORTRAIT_SHAKE_DELAY,PORTRAIT_SHAKE_DURATION,
        state.amplitude*PORTRAIT_SHAKE_STRENGTH,PORTRAIT_SHAKE_DECAY)
    return x,y,x*.72+lagX,y*.72+lagY
end

local function SampleMainHealthShake(view,s)
    if view.preview or view.encounterActive then return end
    if not MainShakeEnabled(view) then
        if view.mainHealthShake then StopMainHealthShake(view);view.mainHealthShake=nil end
        return
    end
    local state=view.mainHealthShake
    if not state then state={};view.mainHealthShake=state end
    local epoch=view.healthChangeUpdates and view.healthChangeUpdates.target
    local maxEpoch=view.healthChangeMaxUpdates and view.healthChangeMaxUpdates.target
    if state.epoch==epoch and state.maxEpoch==maxEpoch then return end
    local firstSample=state.epoch==nil
    local maxChanged=state.maxEpoch~=maxEpoch
    state.epoch,state.maxEpoch=epoch,maxEpoch
    if not s.exists then return end

    local health=s.healthRatio
    local maximum=C.Number(s.maxHealth)
    if health==nil and UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then
        local ok,value=pcall(UnitHealthPercent,"target",true,CurveConstants.ScaleTo100)
        if ok then
            local percent=C.Number(value)
            if percent then health=M.Clamp(percent*.01,0,1) end
        end
    end

    local previous,previousMaximum=state.ratio,state.maximum
    if firstSample or maxChanged or maximum~=previousMaximum or (health~=nil and previous==nil) then
        state.ratio,state.maximum=health,maximum
        return
    end
    local amplitude,interval
    if health~=nil then
        local delta=math.abs(health-previous)
        if delta<SHAKE_THRESHOLD then return end
        amplitude=M.Clamp(delta*44,1.25,6)
        interval=SHAKE_INTERVAL
    else
        -- Restricted health still delivers UNIT_HEALTH. Use a short visual
        -- pulse without trying to calculate a delta from protected values.
        state.ratio=nil
        amplitude,interval=RESTRICTED_SHAKE_AMPLITUDE,RESTRICTED_SHAKE_INTERVAL
    end
    local now=GetTime()
    if state.nextAt and now<state.nextAt then return end
    state.ratio=health
    state.started,state.amplitude,state.nextAt=now,amplitude,now+interval
end
private.SampleMainHealthShake=SampleMainHealthShake

function R.ClearTargetHealthChange(view)
    StopMainHealthShake(view)
    local o=view.nodes.wa385c615b2a
    if o then ClearHealthChange(o) end
end

local function HealthChangeAllowed(view,o)
    return o.healthChangeEnabled and not view.preview
        and not (o.spec.unit=="target" and view.encounterActive)
end

local function DrawHealthSegment(o,texture,first,last,opacity,inset,start,full)
    if opacity<=0 or last<=first or full<=start then
        if texture:IsShown() then texture:Hide() end
        return
    end
    local n=o.spec
    local span=full-start
    local inner,outer=inset+start+span*first,inset+start+span*last
    local left,right=inner,outer
    if n.reverse then left,right=n.width-outer,n.width-inner end
    local cropX,cropY=1+(n.cropX or 0),1+(n.cropY or 0)
    local l,r=.5+(left/n.width-.5)/cropX,.5+(right/n.width-.5)/cropX
    local top,bottom=.5-.5/cropY,.5+.5/cropY
    if n.mirror then l,r=r,l end
    if n.mirrorY then top,bottom=bottom,top end
    texture:ClearAllPoints()
    texture:SetPoint("LEFT",o.frame,"LEFT",left,0)
    texture:SetSize(right-left,n.height)
    texture:SetTexCoord(l,r,top,bottom)
    texture:SetAlpha(opacity)
    if not texture:IsShown() then texture:Show() end
end

local function HealthChangeLayers(o)
    if o.healthChange then return o.healthChange end
    local layer=CreateFrame("Frame",nil,o.frame)
    layer:SetFrameLevel(o.clip:GetFrameLevel()+2)
    local damage=layer:CreateTexture(nil,"OVERLAY")
    damage:SetVertexColor(1,.30,.13)
    local heal=layer:CreateTexture(nil,"OVERLAY",nil,1)
    heal:SetVertexColor(1,.90,.60)
    heal:SetBlendMode("ADD")
    damage:Hide();heal:Hide()
    o.healthChange={damage=damage,heal=heal}
    return o.healthChange
end

local function PaintHealthChange(view,o,s,animateOnly,inset,start,full)
    local current=s.healthRatio
    if current==nil or not HealthChangeAllowed(view,o) or not s.exists then
        if o.healthChangeRatio~=nil or o.healthChangeActive then ClearHealthChange(o) end
        return
    end
    local previous=o.healthChangeRatio
    local maximum=s.maxHealth
    local fx=o.healthChange
    local now
    if not animateOnly then
        if previous==nil or maximum~=o.healthChangeMaximum then
            ClearHealthChange(o)
            o.healthChangeRatio=current;o.healthChangeMaximum=maximum
            return
        end
        o.healthChangeRatio=current
        if previous~=current then
            now=GetTime()
            fx=HealthChangeLayers(o)
            if fx.file~=o.spec.file then
                fx.file=o.spec.file
                fx.damage:SetTexture(fx.file);fx.heal:SetTexture(fx.file)
            end
            if current<previous then
                if not fx.damageAt then
                    fx.tail=previous;fx.damageAt=now+DAMAGE_HOLD
                    fx.damageStep=fx.damageAt
                end
                fx.healFrom,fx.healAt=nil,nil
            else
                if not fx.healAt or now-fx.healAt>=HEAL_FLASH then
                    fx.healFrom,fx.healAt=previous,now
                end
            end
        end
    end
    if not fx or (not fx.damageAt and not fx.healAt) then return end
    now=now or (animateOnly and view.animationNow) or GetTime()
    if fx.damageAt then
        local finish=fx.damageAt+DAMAGE_RETRACT
        if now>=finish or current>=fx.tail then
            fx.tail,fx.damageAt,fx.damageStep=nil,nil,nil
        elseif now>fx.damageAt then
            -- Consecutive hits retarget this same tail without restarting its hold.
            local step=M.Clamp((now-fx.damageStep)/(finish-fx.damageStep),0,1)
            fx.tail=fx.tail+(current-fx.tail)*step
            fx.damageStep=now
        end
    end
    if fx.damageAt then DrawHealthSegment(o,fx.damage,current,fx.tail,.68,inset,start,full)
    elseif fx.damage:IsShown() then fx.damage:Hide() end
    if fx.healAt then
        local progress=M.Clamp((now-fx.healAt)/HEAL_FLASH,0,1)
        if progress>=1 then fx.healFrom,fx.healAt=nil,nil
        else
            local head=fx.healFrom+(current-fx.healFrom)*math.min(1,.22+progress*3)
            DrawHealthSegment(o,fx.heal,fx.healFrom,head,.78*(1-progress),inset,start,full)
        end
    end
    if not fx.healAt and fx.heal:IsShown() then fx.heal:Hide() end
    o.healthChangeActive=fx.damageAt~=nil or fx.healAt~=nil
end

-- Intersect one native fill with the other bar's empty area. The client
-- computes both edges without exposing protected health to addon Lua.
local function NativeHealthSegment(layer,bar,filled,emptyEdge,reverse)
    local fillClip=CreateFrame("Frame",nil,layer)
    fillClip:SetAllPoints(filled)
    fillClip:SetClipsChildren(true)
    local remainder=CreateFrame("Frame",nil,fillClip)
    if reverse then
        remainder:SetPoint("TOPLEFT",bar,"TOPLEFT")
        remainder:SetPoint("BOTTOMRIGHT",emptyEdge,"BOTTOMLEFT")
    else
        remainder:SetPoint("TOPLEFT",emptyEdge,"TOPRIGHT")
        remainder:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT")
    end
    remainder:SetClipsChildren(true)
    local art=remainder:CreateTexture(nil,"OVERLAY")
    art:SetAllPoints(layer)
    return art
end

local function NativeHealthChangeLayers(o)
    local bar=o.bar
    local layer=CreateFrame("Frame",nil,o.frame)
    layer:SetAllPoints(o.frame)
    layer:Hide()
    local trailing=CreateFrame("StatusBar",nil,layer)
    trailing:SetAllPoints(bar)
    trailing:SetStatusBarTexture([[Interface\Buttons\WHITE8X8]])
    local delayed=trailing:GetStatusBarTexture()
    delayed:SetAlpha(0)
    local current=bar:GetStatusBarTexture()
    local damage=NativeHealthSegment(layer,bar,delayed,current,o.spec.reverse)
    damage:SetVertexColor(1,.28,.10,.80)
    local heal=NativeHealthSegment(layer,bar,current,delayed,o.spec.reverse)
    heal:SetVertexColor(1,.92,.68,.9)
    heal:SetBlendMode("ADD")
    local fx={layer=layer,trailing=trailing,damage=damage,heal=heal}
    o.nativeHealthChange=fx
    return fx
end

local function PaintNativeHealthChange(view,o,s,enabled,interpolation)
    local fx=o.nativeHealthChange
    if not enabled or not s.exists then
        if fx and fx.ready then
            fx.ready=nil;fx.pending=nil;fx.pendingHealth=nil;fx.layer:Hide()
        end
        return
    end
    fx=fx or NativeHealthChangeLayers(o)
    local spec=o.spec
    local unit=spec.unit
    local epoch=view.healthChangeUpdates and view.healthChangeUpdates[unit]
    local maxEpoch=view.healthChangeMaxUpdates and view.healthChangeMaxUpdates[unit]
    local refresh=not fx.ready or fx.spec~=spec or fx.maxEpoch~=maxEpoch
    if not refresh and fx.epoch==epoch then return end
    fx.epoch,fx.maxEpoch=epoch,maxEpoch
    local health,maximum=s.health,s.maxHealth
    if type(health)=="nil" or type(maximum)=="nil" then
        fx.ready=nil;fx.pending=nil;fx.pendingHealth=nil;fx.layer:Hide()
        return
    end
    if refresh then
        fx.pending=nil;fx.pendingHealth=nil
        fx.spec=spec
        fx.trailing:SetReverseFill(spec.reverse==true)
        fx.trailing:SetMinMaxValues(0,maximum)
        fx.trailing:SetValue(health)
        fx.damage:SetTexture(spec.file);private.TextureCoords(fx.damage,spec)
        fx.heal:SetTexture(spec.file);private.TextureCoords(fx.heal,spec)
        fx.layer:SetFrameLevel(o.clip:GetFrameLevel()+2)
        fx.ready=true;fx.layer:Show()
    elseif C_Timer and C_Timer.After then
        fx.pendingHealth=health
        -- One pending sample per bar. Frequent hits update the value without
        -- restarting the hold. Clients without interpolation still show a step.
        if fx.pending then return end
        local token={}
        fx.pending=token
        C_Timer.After(DAMAGE_HOLD,function()
            if fx.pending~=token or not fx.ready then return end
            local value=fx.pendingHealth
            fx.pending=nil;fx.pendingHealth=nil
            if interpolation then fx.trailing:SetValue(value,interpolation)
            else fx.trailing:SetValue(value) end
        end)
    else
        fx.trailing:SetValue(health,interpolation)
    end
end

private.PaintNativeHealthChange=PaintNativeHealthChange
private.ClearHealthChange=ClearHealthChange
private.HealthChangeAllowed=HealthChangeAllowed
private.PaintHealthChange=PaintHealthChange

local function CenterLogo(view,o)
    local n,f=o.spec,o.frame
    local player=State(view,"player")
    local cast=player.cast or {}
    local name=cast.name
    local hearth=cast.active and C.Readable(name) and (name=="炉石" or name=="Hearthstone")
    local active=n.enabled~=false and player.exists and (player.afk or hearth)
    if view.hidden and view.hidden[n.id] then active=false end
    if view.preview and view.selected==n.id then active=true end
    local now=GetTime()
    if o.logoActive~=active then
        o.logoActive=active;o.logoChanged=now
        if not active then o.logoFadeFrom=o.logoOpacity or 0 end
    end
    local elapsed=now-(o.logoChanged or now)
    local opacity,size=1,1
    if active then
        local progress=M.Clamp(elapsed/(n.logoInDuration or .35),0,1)
        size=1+((n.logoStartScale or 1.5)-1)*(1-progress)
    else
        local progress=M.Clamp(elapsed/(n.logoOutDuration or .35),0,1)
        opacity=(o.logoFadeFrom or 0)*(1-progress)
        if opacity<=0 then o.logoOpacity=0;o.logoAnimating=false;if f:IsShown() then f:Hide() end;return end
    end
    o.logoOpacity=opacity
    o.logoAnimating=active and size~=1 or not active
    local col,alpha=Appearance(view,n,player,o)
    if not f:IsShown() then f:Show() end
    CachedValue(o,"frameAlpha",f,"SetAlpha",alpha*opacity)
    CachedColor(o,"textureColor",o.texture,"SetVertexColor",col)
    CachedPoint(o,"logoPoint",o.texture,"CENTER",f,"CENTER",0,0)
    CachedPair(o,"logoSize",o.texture,"SetSize",(n.width or 160)*size,(n.height or 160)*size)
end
local function Sprite(view,o,alpha,now,casting)
    local n,f=o.spec,o.frame;local grid=o.spriteGrid
    local rows,columns,frames=grid.rows,grid.columns,grid.frames
    local index
    if n.particleFlow then
        if casting==nil then casting=State(view,"player").cast.active end
        local direction=(n.particleNormalReverse and -1 or 1)*(casting and -1 or 1)
        if o.particlePhase==nil then o.particlePhase=direction<0 and frames-1 or 0 end
        if o.particleTime then
            local fps=casting and (n.particleCastFPS or 90) or (n.fps or 25)
            o.particlePhase=(o.particlePhase+(now-o.particleTime)*fps*direction)%frames
        end
        o.particleTime=now
        if o.particleMode==nil or o.particleMode~=casting then
            o.particleMode=casting;o.particleSlideAt=now;o.particleSettled=nil
        end
        index=math.floor(o.particlePhase)%frames
        if not o.particleSettled or view.preview then
            local progress=M.Clamp((now-o.particleSlideAt)/(n.particleSlideDuration or .4),0,1)
            local shift=(n.particleSlideX or 0)*(casting and -1 or 1)*math.sin(math.pi*progress)
            CachedPoint(o,"particlePoint",f,"CENTER",o.geometryParent,"CENTER",(n.x or 0)+shift,n.y or 0)
            CachedValue(o,"frameAlpha",f,"SetAlpha",alpha*progress^3)
            o.particleSettled=progress==1
        else CachedValue(o,"frameAlpha",f,"SetAlpha",alpha) end
    else
        if not o.started then o.started=now end
        local tick=math.floor((now-o.started)*(n.fps or 30))
        if n.play=="bounce" and frames>1 then local v=tick%(frames*2-2);index=v<frames and v or frames*2-2-v
        elseif n.play=="once" then index=math.min(tick,frames-1) else index=tick%frames end
    end
    if o.spriteIndex~=index or o.spriteColumns~=columns or o.spriteRows~=rows then
        local x=index%columns;local y=math.floor(index/columns)%rows
        o.texture:SetTexCoord(x/columns,(x+1)/columns,y/rows,(y+1)/rows)
        o.spriteIndex,o.spriteColumns,o.spriteRows=index,columns,rows
    end
end
local function Spin(view,o,now,casting)
    local n=o.spec
    if not o.spinAt then o.spinAt=now;o.spinAngle=math.rad(n.rotation or 0) end
    if view.raidEncounter and not view.preview then o.spinPaused=true;return end
    if o.spinPaused then o.spinAt=now;o.spinPaused=nil end
    if casting==nil then casting=State(view,"player").cast.active end
    local period=casting and (n.castSpinPeriod or .5) or n.spinPeriod
    o.spinAngle=(o.spinAngle+math.max(0,now-o.spinAt)*2*math.pi/period)%(2*math.pi)
    o.spinAt=now;o.texture:SetRotation(o.spinAngle)
end
R.SpinTexture=Spin
local emptyState={}
local function DecorationTint(view,o,col)
    local outside=view.decorationOutOfRange==true
    local tint=col
    if outside then
        tint=o.rangeTint or {};o.rangeTint=tint
        tint[1],tint[2],tint[3],tint[4]=1,0,0,col[4] or 1
    end
    CachedColor(o,"textureColor",o.texture,"SetVertexColor",tint)
    CachedValue(o,"rangeDesaturated",o.texture,"SetDesaturated",outside or o.spec.desaturate or false)
    CachedValue(o,"rangeTextureShown",o.texture,"SetShown",true)
end
function R.UpdateDecorationRange(view,force)
    if not view or not view.rangeDecorations or #view.rangeDecorations==0 then return end
    if not view.root:IsVisible() then return end
    local outside=M.TargetDistance and M.TargetDistance.DecorationState(view,force) or false
    if view.decorationTintState==outside and not force then return end
    view.decorationTintState=outside;view.decorationOutOfRange=outside
    for _,o in ipairs(view.rangeDecorations) do
        DecorationTint(view,o,o.animationColor or o.spec.color or {1,1,1,1})
    end
end

M.RendererInternals.FillStart=FillStart
M.RendererInternals.CenterLogo=CenterLogo
M.RendererInternals.Sprite=Sprite
M.RendererInternals.Spin=Spin
M.RendererInternals.emptyState=emptyState
M.RendererInternals.DecorationTint=DecorationTint
