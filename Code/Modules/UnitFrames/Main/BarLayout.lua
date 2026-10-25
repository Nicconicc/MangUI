local _,M=...
local B={};M.MainBarLayout=B
B.tokenID="wa92712c7b3d"
B.avatarID="wabc757f81ee"
function B.SyncNodes(design)
    local index={};for _,n in ipairs(design.nodes) do index[n.id]=n end
    local token=index[B.tokenID];if not token then return end
    -- The rim covers the square native portrait's corners. Preserve this order
    -- during rendering as well as initialization, reset and imported layouts.
    token.layer=207
    for _,id in ipairs({"wa88b1376baa","wa0b0b0540c7"}) do
        local portrait=index[id]
        if portrait and portrait.parent==B.avatarID then portrait.layer=206 end
    end
end
B.parts={
    wa70b7aa5607={bar="wa4f9903a71c",original="PlayerHPColor",side="LEFT"},
    waf0a666c0b7={bar="wa58141a60dd",original="PlayerPowerColor",side="LEFT"},
    waf465575a72={bar="wa385c615b2a",original="TargetHPColor",side="RIGHT"},
    wae608adf3d8={bar="wadb47b70c3f",original="TargetPowerColor",side="RIGHT"},
    playerThirdResource={bar="playerThirdResourceFill",original="TargetHPColor",side="LEFT"},
}
B.bars={}
for id,part in pairs(B.parts) do part.group=id;B.bars[part.bar]=part end
-- Nontransparent horizontal bounds measured from the installed 512px art.
-- The transparent canvas margin must not become a gap at the outer X limit.
local tokenEdges={
    tokenframe_01_battlemaster={25,482},tokenframe_02_champion={42,480},
    tokenframe_03_eldritchknight={21,485},tokenframe_04_psiwarrior={24,482},
    tokenframe_05_banneret={16,481},tokenframe_06_arcanearcher={30,487},
    tokenframe_07_cavalier={25,493},tokenframe_08_echoknight={1,495},
    tokenframe_08b_echoknightalt={29,482},tokenframe_09_runeknight={40,483},
    tokenframe_10_samurai={23,480},tokenframe_11_frostiron={14,500},
}
local edgeCache=setmetatable({},{__mode="k"})
function B.EdgeUV(spec)
    local cached=edgeCache[spec]
    if cached and cached.file==spec.file and cached.mirror==spec.mirror and cached.crop==spec.cropX then
        return cached.left,cached.right
    end
    local source=M:TextureSourcePath(spec.file)
    local name=type(source)=="string" and source:lower():match("([^\\]+)$") or ""
    name=name:gsub("%.[^.]+$","")
    local bounds=tokenEdges[name]
    local left,right=0,1
    if bounds then left,right=bounds[1]/512,bounds[2]/512 end
    if spec.mirror then left,right=1-right,1-left end
    local crop=1+(spec.cropX or 0)
    left,right=M.Clamp(.5+(left-.5)*crop,0,1),M.Clamp(.5+(right-.5)*crop,0,1)
    edgeCache[spec]={file=spec.file,mirror=spec.mirror,crop=spec.cropX,left=left,right=right}
    return left,right
end
function B.ContactUV(spec)
    local left,right=B.EdgeUV(spec)
    -- The circular rim bends inward at the strip heights. Let the fill tuck
    -- under the rim by 20 units at a 256-unit TokenFrame width, scaling with it.
    local inset=math.min(20/256,(right-left)/4)
    return left+inset,right-inset
end
local points={CENTER={0,0},LEFT={-1,0},RIGHT={1,0},TOP={0,1},BOTTOM={0,-1},
    TOPLEFT={-1,1},TOPRIGHT={1,1},BOTTOMLEFT={-1,-1},BOTTOMRIGHT={1,-1}}
local function Geometry(index,id,cache,depth)
    if cache[id] then return cache[id] end
    local n=index[id]
    if not n or depth>100 then return {x=0,s=1,w=2} end
    local p=n.parent and Geometry(index,n.parent,cache,depth+1) or {x=0,s=1,w=2}
    if points[n.screenAnchor] then p={x=0,s=1,w=UIParent:GetWidth()} end
    local scale=p.s*M.Clamp(M:NodeScale(n),.05,10)
    local anchor=points[n.screenAnchor or n.anchor] or points.CENTER
    local point=points[n.point] or points.CENTER
    local width=n.width or 2
    local g={x=p.x+anchor[1]*p.w*p.s/2+(n.x or 0)*scale-point[1]*width*scale/2,s=scale,w=width}
    local moveX=M:MainModuleOffset(n,index);g.x=g.x+moveX
    cache[id]=g;return g
end
function B.XRange(group,index,cache)
    local part=group and B.parts[group.id]
    index=index or M.byID
    if not part or not index or not index[part.bar] or not index[B.tokenID] then return end
    cache=cache or {}
    local token=Geometry(index,B.tokenID,cache,0)
    local bar=Geometry(index,part.bar,cache,0)
    local g=Geometry(index,group.id,cache,0)
    if g.s<=0 then return end
    local leftUV,rightUV=B.ContactUV(index[B.tokenID])
    local tokenLeft=token.x+(leftUV-.5)*token.w*token.s
    local tokenRight=token.x+(rightUV-.5)*token.w*token.s
    local middle=(tokenLeft+tokenRight)/2
    local inner=bar.x+(part.side=="LEFT" and 1 or -1)*bar.w*bar.s/2
    -- The inward-facing strip edge moves from the inset contact edge to the
    -- visible span's midpoint; maximum insertion stays at 50% of visible width.
    local left=part.side=="LEFT" and tokenLeft or middle
    local right=part.side=="LEFT" and middle or tokenRight
    return (group.x or 0)+(left-inner)/g.s,(group.x or 0)+(right-inner)/g.s
end
function B.ClampX(group,value,index)
    local minimum,maximum=B.XRange(group,index)
    if not minimum then return value end
    return M.Clamp(value,minimum,maximum)
end
function B.ClampAll(index)
    local cache={}
    for id in pairs(B.parts) do
        local group=index[id]
        local minimum,maximum=B.XRange(group,index,cache)
        if minimum then group.x=M.Clamp(group.x or 0,minimum,maximum) end
    end
end
function B.Moving(view,spec)
    local part=B.bars[spec.id]
    local entries=view.entries
    if not part or not entries then return false end
    local bar,avatar=entries[part.group],entries[B.avatarID]
    return (bar and bar.started~=nil) or (avatar and avatar.started~=nil) or false
end
