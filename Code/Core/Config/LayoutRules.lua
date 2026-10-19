local _,M=...
function M:NormalizeScaleReferences(design)
    -- Rebase editor values once without changing physical rendering parameters.
    -- Persist the reference so reloads and sharing retain later user adjustments.
    for _,n in ipairs(design and design.nodes or {})do
        if not n.scaleReference then n.scaleReference=n.scale or 1 end
        if not n.modelScaleReference then n.modelScaleReference=n.modelScale or 1 end
    end
end
function M:ScaleDisplayValue(node,field)
    if not node then return 1 end
    field=field or "scale"
    return (node[field] or 1)/(node[field.."Reference"] or 1)
end
function M:ScaleInputValue(node,value,field)
    field=field or "scale"
    return value*(node[field.."Reference"] or 1)
end
function M:NodeScale(node)
    -- Keep the child's editable scale independent of the logical main module.
    return (node.scale or 1)*(node.mainScaleFactor or 1)
end
function M:SyncCenterLevelFonts(design)
    local player,target
    for _,n in ipairs(design.nodes or {}) do
        if n.id=="wa0b35e5bbc2" then player=n
        elseif n.id=="wa38ad2639d2" then target=n end
    end
    -- Both labels occupy the same portrait badge. Preserve its current target
    -- size when the badge falls back to the player's level without a target.
    if player and target and player.parent==target.parent then
        player.fontSize=(target.fontSize or 20)*self:NodeScale(target)/math.max(.001,self:NodeScale(player))
    end
end
local fontScreenPoints={CENTER=true,LEFT=true,RIGHT=true,TOP=true,BOTTOM=true,
    TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
function M:FontDisplayScale(node)
    local id=node.compound=="chatButtons" and "chatButtonsRow" or node.compound=="targetThreat" and "targetThreatDisplay" or node.id
    local current=self.byID[id];local scale,guard=1,0
    -- Font size depends only on the ancestor scales, never on the positions
    -- of the other 300+ elements. Screen-anchored nodes restart at UIParent.
    while current and guard<100 do
        scale=scale*self:NodeScale(current);guard=guard+1
        if fontScreenPoints[current.screenAnchor] then break end
        current=self.byID[current.parent]
    end
    return math.max(.001,scale)
end
function M:FontDisplaySize(node)
    return (node.fontSize or 20)*self:FontDisplayScale(node)
end
function M:SetFontDisplaySize(node,size)
    node.fontSize=size/self:FontDisplayScale(node)
end
function M:NormalizeResourceOrigin(design)
    if not design or not self.Geometry then return end
    local index={}
    for _,n in ipairs(design.nodes or {})do index[n.id]=n end
    local group,visual=index.playerResources,index.playerResourcesVisual
    if not group or not visual or group.resourceOriginRevision==1 then return end
    local geo=self:Geometry(index)
    local g,parent,portrait=geo[group.id],geo[group.parent],geo.wabc757f81ee
    if not g or not parent or not portrait then return end
    local _,class=UnitClass("player")
    local dk=class~="ROGUE" and class~="DRUID" and class~="SHAMAN"
    local count=dk and 6 or 5
    local width=50+(count-1)*(50+(group.resourceSpacing or 0))
    local scale=g.s*self:NodeScale(visual)*(dk and 1/.9 or 1)
    local x=g.x+((visual.x or 122.22)+(dk and -42.22 or 0)+width/2)*scale
    local y=g.y+(visual.y or -68.89)*scale
    group.x=(x-portrait.x)/parent.s;group.y=(y-portrait.y)/parent.s
    group.resourceOriginRevision=1
    visual.x=0;visual.y=0;visual.point="CENTER";visual.anchor="CENTER"
end
function M:NormalizeTargetAuraOrigins(design)
    if not design or not self.Geometry then return end
    local index={}
    for _,n in ipairs(design.nodes or {})do index[n.id]=n end
    for _,entry in ipairs({{"wa026b04c50e","wadde9035c6a","debuff"},{"wa88e7259b1c","wa028b62b494","buff"}})do
        local group,icons=index[entry[1]],index[entry[2]]
        if group and icons and group.auraOriginRevision~=1 then
            local geo=self:Geometry(index)
            local old,parent,portrait=geo[icons.id],geo[group.parent],geo.wabc757f81ee
            if old and parent and portrait then
                local count=math.max(1,group[entry[3].."Count"] or icons.count or 8)
                local perRow=math.max(1,group[entry[3].."PerRow"] or icons.perRow or count)
                local x=old.x+(math.min(count,perRow)-1)*((icons.width or 20)+(icons.spacing or 4))*old.s/2
                local y=old.y-(math.ceil(count/perRow)-1)*((icons.height or 20)+(icons.spacing or 4))*old.s/2
                group.x=(x-portrait.x)/parent.s;group.y=(y-portrait.y)/parent.s
                group.auraOriginRevision=1
                icons.x=0;icons.y=0;icons.point="CENTER";icons.anchor="CENTER"
            end
        end
    end
end
function M:NormalizeTargetCastOrigin(design)
    if not design or not self.Geometry then return end
    local index={}
    for _,n in ipairs(design.nodes or {})do index[n.id]=n end
    local group=index.targetCast
    if not group or group.castOriginRevision==1 then return end
    local geo=self:Geometry(index)
    local origin,parent,portrait=geo[group.id],geo[group.parent],geo.wabc757f81ee
    if not origin or not parent or not portrait then return end
    local left,right,bottom,top
    for _,n in pairs(index)do
        if n.parent==group.id and n.kind~="group" and n.kind~="hitbox" then
            local g=geo[n.id]
            local l,r,b,t=g.x-g.w*g.s/2,g.x+g.w*g.s/2,g.y-g.h*g.s/2,g.y+g.h*g.s/2
            left=left and math.min(left,l)or l;right=right and math.max(right,r)or r
            bottom=bottom and math.min(bottom,b)or b;top=top and math.max(top,t)or t
        end
    end
    if not left then return end
    local x,y=(left+right)/2,(bottom+top)/2
    for _,n in pairs(index)do
        if n.parent==group.id then
            local unit=origin.s*self:NodeScale(n)
            n.x=(n.x or 0)-(x-origin.x)/unit;n.y=(n.y or 0)-(y-origin.y)/unit
        end
    end
    group.x=(x-portrait.x)/parent.s;group.y=(y-portrait.y)/parent.s
    group.castOriginRevision=1
end
function M:NormalizeValueTextAnchors(design)
    local sides={wadb51e41246="RIGHT",wa8ee62b16d6="RIGHT",wa6edbcf125a="RIGHT",
        wa8492858a6d="LEFT",wa074335b474="LEFT",wa712a8bee10="CENTER"}
    local horizontal={LEFT=-1,TOPLEFT=-1,BOTTOMLEFT=-1,RIGHT=1,TOPRIGHT=1,BOTTOMRIGHT=1}
    for _,n in ipairs(design and design.nodes or {}) do
        local side=sides[n.id]
        if side then
            if n.valueTextAnchorRevision~=1 then
                -- Preserve the text box bounds when changing its anchor edge.
                n.x=(n.x or 0)+((horizontal[side] or 0)-(horizontal[n.point] or 0))*(n.width or 2)/2
                n.valueTextAnchorRevision=1
            end
            n.point=side;n.justify=side;n.autoWidth=true;n.autoHeight=true
        end
    end
    if not self.Geometry then return end
    local index={};for _,n in ipairs(design and design.nodes or {}) do index[n.id]=n end
    local geometry=self:Geometry(index);local portrait=geometry.wabc757f81ee
    if not portrait then return end
    for _,n in ipairs(design.nodes) do
        if sides[n.id] and n.valueTextOriginRevision~=1 then
            local g=geometry[n.id]
            if g then
                local edge=horizontal[n.point] or 0
                local parent=geometry[n.parent];local unit=parent and parent.s or 1
                n.x=(g.x+edge*g.w*g.s/2-portrait.x)/unit
                n.y=(g.y-portrait.y)/unit
                n.valueTextOriginRevision=1
                n.valueTextScaleFixRevision=1
            end
        end
    end
end
function M:EnsurePlayerHealthPercent(design)
    if not design or not design.nodes then return end
    local index={}
    for _,n in ipairs(design.nodes) do
        if n.id=="playerHealthPercent" then return end
        index[n.id]=n
    end
    local target=index.wa712a8bee10
    local player=index.wadb51e41246
    if not target or not player or not index[player.parent] then return end
    local label=self.Copy(target)
    label.id="playerHealthPercent";label.label="玩家生命值百分比"
    label.parent=player.parent;label.treeParent="mainComposite"
    label.unit="player";label.scope="player";label.visibleUnit="player"
    label.binding="healthPercent";label.text="%c%"
    label.enabled=true;label.alpha=1;label.rules={};label.conditions={}
    label.point="CENTER";label.anchor="CENTER";label.justify="CENTER"
    label.autoWidth=true;label.autoHeight=true
    label.valueTextOriginRevision=1;label.valueTextAnchorRevision=1;label.valueTextScaleFixRevision=1
    label.valueTextScalePreviousX=nil;label.valueTextScalePreviousY=nil
    label.x=-150
    if self.Geometry then
        local geo=self:Geometry(index,{target.id,target.parent,player.parent,"wabc757f81ee"})
        local source,parent,portrait=geo[target.id],geo[player.parent],geo.wabc757f81ee
        local sourceParent=geo[target.parent]
        if source and parent and portrait and parent.s>0 then
            label.y=(source.y-portrait.y)/parent.s
            -- Copy the target label's physical font size even if its ancestor
            -- group has a different saved scale from the player's group.
            local ratio=(sourceParent and sourceParent.s or parent.s)/parent.s
            label.scale=(label.scale or 1)*ratio
            label.scaleReference=(label.scaleReference or target.scale or 1)*ratio
        end
    end
    for i,n in ipairs(design.nodes) do
        if n.id==player.id then table.insert(design.nodes,i+1,label);return end
    end
end

function M:RepairValueTextScale()
    local design,reference=self.db.design,self.db.moduleDefaults
    if not reference or not reference.nodes then return end
    local index,refIndex={},{}
    local needsRepair=false
    for _,n in ipairs(design.nodes) do
        index[n.id]=n
        if n.valueTextOriginRevision==1 and not n.valueTextScaleFixRevision then needsRepair=true end
    end
    if not needsRepair then return end
    for _,n in ipairs(reference.nodes) do refIndex[n.id]=n end
    local geo,refGeo=self:Geometry(index),self:Geometry(refIndex)
    local portrait=geo.wabc757f81ee
    if not portrait then return end
    local ratio=(index.mainComposite and index.mainComposite.scale or 1)/
        (refIndex.mainComposite and refIndex.mainComposite.scale or 1)
    local pending={};local currentScore,legacyScore,spread,closer=0,0,0,0
    for _,n in ipairs(design.nodes) do
        local ref=refIndex[n.id];local parent=geo[n.parent];local rp=ref and refGeo[ref.parent]
        if n.valueTextOriginRevision==1 and not n.valueTextScaleFixRevision and ref and parent and rp then
            local expectedX,expectedY=(ref.x or 0)*rp.s*ratio,(ref.y or 0)*rp.s*ratio
            local moveX,moveY=self:MainModuleOffset(n,index)
            local legacyX=parent.x+(n.x or 0)*geo[n.id].s+moveX-portrait.x
            local legacyY=parent.y+(n.y or 0)*geo[n.id].s+moveY-portrait.y
            local currentX,currentY=(n.x or 0)*parent.s,(n.y or 0)*parent.s
            local a=(currentX-expectedX)^2+(currentY-expectedY)^2
            local b=(legacyX-expectedX)^2+(legacyY-expectedY)^2
            currentScore=currentScore+a;legacyScore=legacyScore+b
            spread=spread+expectedX^2+expectedY^2
            if b<a then closer=closer+1 end
            pending[#pending+1]={node=n,unit=parent.s,x=legacyX,y=legacyY,expectedX=expectedX,expectedY=expectedY}
        end
    end
    -- Version 1.0.397 wrote legacy offsets during whole-module scaling. Only
    -- repair that six-text pattern; preserve ordinary customized positions.
    local repair=#pending==6 and closer>=4 and currentScore>math.max(10000,spread*.25)
        and legacyScore<currentScore*.6
    for _,entry in ipairs(pending) do
        local n=entry.node
        if repair then
            n.valueTextScalePreviousX=n.x;n.valueTextScalePreviousY=n.y
            local recover=legacyScore<math.max(10000,spread*.25)
            n.x=(recover and entry.x or entry.expectedX)/entry.unit
            n.y=(recover and entry.y or entry.expectedY)/entry.unit
        end
        n.valueTextScaleFixRevision=1
    end
end
function M:NodePosition(node,index,resolveGeometry)
    local x,y=node.x or 0,node.y or 0
    if (node.valueTextOriginRevision==1 or node.resourceOriginRevision==1 or node.auraOriginRevision==1 or node.castOriginRevision==1) and self.Geometry then
        index=index or self.byID or {}
        -- Resolve only the anchor ancestors, keeping the original text parents
        -- and their scale/visibility behavior independent of portrait scaling.
        local geo
        if not resolveGeometry then
            geo=self:Geometry(index,{node.parent,"wabc757f81ee","mainComposite"})
            resolveGeometry=function(id)return geo[id]end
        end
        local portrait=resolveGeometry("wabc757f81ee")
        if portrait then
            local parent=resolveGeometry(node.parent) or {x=0,y=0,s=1,w=2,h=2}
            local vectors={CENTER={0,0},LEFT={-1,0},RIGHT={1,0},TOP={0,1},BOTTOM={0,-1},
                TOPLEFT={-1,1},TOPRIGHT={1,1},BOTTOMLEFT={-1,-1},BOTTOMRIGHT={1,-1}}
            local anchor=vectors[node.anchor] or vectors.CENTER
            local scale=math.max(.001,self:NodeScale(node))
            local moveX,moveY=self:MainModuleOffset(node,index)
            return (portrait.x-parent.x-anchor[1]*parent.w*parent.s/2-moveX)/(parent.s*scale)+x/scale,
                (portrait.y-parent.y-anchor[2]*parent.h*parent.s/2-moveY)/(parent.s*scale)+y/scale
        end
    end
    if (node.id=="centerFire" and node.decorationPivotRevision==2)
        or (node.id=="waf24f8d43e3" and node.raidMarkPivotRevision==1)
        or (node.id=="centerClassification" and node.classificationPivotRevision==2) then
        local scale=math.max(.001,self:NodeScale(node))
        x=x/scale
        y=y/scale
    end
    return x,y
end
function M:NormalizeRaidMarkPivot(design)
    for _,n in ipairs(design and design.nodes or {}) do
        if n.id=="waf24f8d43e3" then
            n.label="团队标记"
            if n.raidMarkPivotRevision~=1 then
                local scale=n.scale or 1
                n.x=(n.x or 0)*scale;n.y=(n.y or 0)*scale
                n.raidMarkPivotRevision=1
            end
        end
    end
end
function M:NormalizeCenterDecoration(design)
    if not design or not design.nodes then return end
    local group,gem
    for _,n in ipairs(design.nodes) do
        if n.id=="centerFire" then group=n elseif n.id=="waa3b4cd2bd6" then gem=n end
    end
    if not group or not gem or group.decorationPivotRevision==2 then return end
    if group.decorationPivotRevision==1 then
        group.decorationBaseX=0;group.decorationBaseY=0
        group.decorationPivotRevision=2
        return
    end
    local px,py=(gem.x or 0)*(gem.scale or 1),(gem.y or 0)*(gem.scale or 1)
    local scale=group.scale or 1
    -- Rebase children around the gem's center. Decoration offsets are measured
    -- from the portrait center, so zero offsets place both centers together.
    group.decorationBaseX=0;group.decorationBaseY=0
    group.x=((group.x or 0)+px)*scale
    group.y=((group.y or 0)+py)*scale+85
    for _,n in ipairs(design.nodes) do
        if n.parent==group.id then
            local childScale=math.max(.001,n.scale or 1)
            n.x=(n.x or 0)-px/childScale;n.y=(n.y or 0)-py/childScale
        end
    end
    group.decorationPivotRevision=2
end
function M:EnsureCenterClassification(design)
    if not design or not design.nodes then return end
    local group,portrait,elite,rare,first
    for _,n in ipairs(design.nodes) do
        if n.id=="centerClassification" then group=n end
        if n.id=="wabc757f81ee" then portrait=n end
        if n.id=="wad38d9b944e" then elite=n;first=first or n end
        if n.id=="wad25ba7d231" then rare=n;first=first or n end
    end
    if not portrait or (not elite and not rare) then return end
    if not group then
        group={id="centerClassification",parent=portrait.id,kind="group",x=0,y=0,
            width=2,height=2,scale=1,point="CENTER",anchor="CENTER",alpha=1,
            enabled=true,unit="target",binding="static",color={1,1,1,1},
            blend="BLEND",rules={},conditions={},layer=240,scope="target",
            treeParent="mainComposite"}
        for i,n in ipairs(design.nodes) do
            if n==first then table.insert(design.nodes,i,group);break end
        end
    end
    group.label="稀有精英图标"
    group.parent=portrait.id;group.treeParent="mainComposite"
    if group.classificationPivotRevision~=1 and group.classificationPivotRevision~=2 then
        -- The two mutually exclusive icons become a single centered visual.
        -- Preserve their art, rules, layer, scale and dimensions.
        group.x=0;group.y=0
        if elite then elite.x=0;elite.y=0 end
        if rare then rare.x=0;rare.y=0 end
        group.classificationPivotRevision=1
    end
    if group.classificationPivotRevision==1 then
        -- Keep the saved visual position while making offsets independent of scale.
        local scale=group.scale or 1
        group.x=(group.x or 0)*scale;group.y=(group.y or 0)*scale
        group.classificationPivotRevision=2
    end
    for _,id in ipairs({"wad38d9b944e","wad25ba7d231"}) do
        local n=id=="wad38d9b944e" and elite or rare
        if n then
            n.parent=group.id;n.treeParent="mainComposite"
            n.internal=true;n.locked=false
        end
    end
end
-- The main module is a logical collection whose roots have different authored
-- parents/scales. Keep whole-module movement separate from editable local offsets.
function M:MainModuleOffset(node,index)
    index=index or self.byID
    if not node or node.treeParent~="mainComposite"then return 0,0 end
    local parent=index[node.parent];local guard=0
    while parent and guard<100 do
        if parent.treeParent=="mainComposite"or parent.id=="mainComposite"then return 0,0 end
        parent=index[parent.parent];guard=guard+1
    end
    local main=index.mainComposite
    return main and main.moveX or 0,main and main.moveY or 0
end
function M:SyncCenterPortraitBlack(index)
    local groupID="wabc757f81ee"
    local player=index.wa88b1376baa
    local target=index.wa0b0b0540c7
    local black=index.wafd920b2a61
    if not black or black.parent~=groupID then return end
    if player and player.parent==groupID then player.layer=206 else player=nil end
    if target and target.parent==groupID then target.layer=206 else target=nil end
    local avatar=target or player
    if not avatar then return end
    -- The unchanged black texture matches the portrait at avatar scale 1.4.
    black.scale=(avatar.scale or 1)/1.4
    black.layer=208
    local light=index.wa080cd4c4fb
    if light and light.parent==groupID then light.layer=black.layer+1 end
    local glass=index.wa291016c8c1
    if glass and glass.parent==groupID then glass.layer=black.layer+2 end
end
