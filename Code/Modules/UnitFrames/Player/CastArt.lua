local _,M=...
local A={};M.PlayerCastArt=A
local artwork=setmetatable({},{__mode="k"})
local cuts={0,48,232,280,464,512}
function A.Hide(texture)
    for _,part in ipairs(artwork[texture] or {}) do
        M.RendererInternals.CachedValue(part,"shown",part.texture,"SetShown",false)
    end
end
function A.IsPart(n)
    return n.id=="waba76314011" or n.id=="wa1537213e27"
        or (n.attackKind~=nil and n.parent=="wa8d650f8d3a")
end
function A.Resize(group,value)
    local fill=M.byID.waba76314011
    if not fill or group.compound~="playerCast" then return end
    local previous=group.castHorizontalScale or 1
    local width=(fill.width or 512)*value/previous
    local delta=(width-(fill.width or 512))*M:NodeScale(fill)/2
    fill.width=width
    local border=M.byID.wa1537213e27
    if border then border.width=(border.width or 512)*value/previous end
    local icon=M.byID.wa8fa968f2a9
    if icon then icon.x=(icon.x or -280)-delta end
    local timer=M.byID.waba76314011sub2
    if timer then timer.x=(timer.x or 300)+delta end
    group.castHorizontalScale=value
end
-- Preserve both arrowheads and the central ornament. Only the two straight
-- sections stretch. Public cast ratios crop each section at the same fill edge;
-- restricted native timers clip the complete artwork in the engine instead.
function A.Draw(texture,anchor,n,ratio,color)
    if not A.IsPart(n) then return end
    local width,height=n.width or 512,n.height or 128
    local state=artwork[texture]
    if math.abs(width-512)<.001 then
        if state then
            A.Hide(texture)
            texture:SetTexture(n.file)
        end
        return
    end
    if not state then
        state={}
        local layer,level=texture:GetDrawLayer()
        for i=1,5 do
            state[i]={texture=texture:GetParent():CreateTexture(nil,layer,nil,level)}
        end
        artwork[texture]=state
    end
    texture:SetTexture(nil)
    local P=M.RendererInternals
    local straight=math.max(.001,(width-144)/2)
    local offset=0
    for i,part in ipairs(state) do
        local size=(i==2 or i==4) and straight or 48
        local visible=math.max(0,math.min(size,width*(ratio or 1)-offset))
        local t=part.texture
        P.CachedValue(part,"shown",t,"SetShown",visible>0)
        if visible>0 then
            P.CachedValue(part,"file",t,"SetTexture",n.file)
            P.CachedValue(part,"blend",t,"SetBlendMode",n.blend or "BLEND")
            P.CachedColor(part,"color",t,"SetVertexColor",color or n.color or {1,1,1,1})
            P.CachedPoint(part,"point",t,"LEFT",anchor,"LEFT",offset,0)
            P.CachedPair(part,"size",t,"SetSize",visible,height)
            local coords=part.coords or {};part.coords=coords
            coords[1],coords[2],coords[3],coords[4]=cuts[i]/512,(cuts[i]+(cuts[i+1]-cuts[i])*visible/size)/512,0,1
            P.CachedColor(part,"coords",t,"SetTexCoord",coords)
        end
        offset=offset+size
    end
end
