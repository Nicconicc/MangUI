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
