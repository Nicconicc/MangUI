local _,M=...
function M:UpgradeMainHPLayersY(design,previousSchema)
    local yByID={
        waf216fe2b9f=-245,wa4f9903a71cbg=-245,wa4f9903a71c=-245,
        wae12272bfbd=-245,wa35859adb29=-245,waed2b7d662a=-245,
        wa1882259c81=-245,wa385c615b2abg=-245,wa385c615b2a=-245,
        wa8ba303231f=-245,wa6d7e5b3bf4=-245,waae10175c53=-245,
    }
    local menuIDs={wab9dab4b3b1=true,wa24502fe64f=true}
    for _,n in ipairs(design.nodes or {}) do
        local y=yByID[n.id]
        if y then n.y=y end
        if menuIDs[n.id] then n.y=(n.y or 0)+(previousSchema==61 and -5 or 5) end
    end
end
function M:UpgradeTargetDebuffComposite(design)
    local group,icons
    for _,n in ipairs(design.nodes or {}) do
        if n.id=="wa026b04c50e" then group=n
        elseif n.id=="wadde9035c6a" then icons=n end
    end
    if not group or not icons then return end
    group.treeParent="mainComposite"
    group.locked=false
    group.debuffCount=self.Clamp(tonumber(group.debuffCount or icons.count) or 8,1,40)
    group.debuffPerRow=self.Clamp(tonumber(group.debuffPerRow or icons.perRow) or group.debuffCount,1,40)
    icons.internal=true
    icons.hideCooldownNumbers=true
    for _,n in ipairs(design.nodes) do
        if n.id=="wadde9035c6asub3" then n.internal=true end
    end
    local nodes={}
    for _,n in ipairs(design.nodes) do
        if n.id~="wadde9035c6asub2" then nodes[#nodes+1]=n end
    end
    design.nodes=nodes
end
function M:UpgradeTargetBuffComposite(design)
    local group,icons
    for _,n in ipairs(design.nodes or {}) do
        if n.id=="wa88e7259b1c" then group=n
        elseif n.id=="wa028b62b494" then icons=n end
    end
    if not group or not icons then return end
    group.treeParent="mainComposite"
    group.locked=false
    group.buffCount=self.Clamp(tonumber(group.buffCount or icons.count) or 8,1,40)
    group.buffPerRow=self.Clamp(tonumber(group.buffPerRow or icons.perRow) or group.buffCount,1,40)
    icons.internal=true;icons.hideCooldownNumbers=true
    for _,n in ipairs(design.nodes) do
        if n.id=="wa028b62b494sub2" then n.internal=true end
    end
end
function M:UpgradeTargetRaidMark(design)
    for _,n in ipairs(design.nodes or {}) do
        if n.id=="waf24f8d43e3" then
            n.treeParent="mainComposite"
            n.locked=false
            n.binding="raid"
            n.file="Interface\\AddOns\\MangUI\\Assets\\Library\\RaidMarks\\Skull-v3.tga"
            return
        end
    end
end
function M:UpgradeCenterClassificationIcons(design)
    for _,n in ipairs(design.nodes or {}) do
        if n.id=="wad38d9b944e" or n.id=="wad25ba7d231" then
            n.treeParent="mainComposite"
            n.internal=n.parent=="centerClassification"
            n.locked=false
        end
    end
end
function M:UpgradePlayerResources(design)
    local group,visual
    for _,n in ipairs(design.nodes or {}) do
        if n.id=="playerResources" then group=n
        elseif n.id=="playerResourcesVisual" then visual=n end
    end
    if not group then
        group={id="playerResources",label="玩家资源 Player resources",parent="wabd08933377",
            treeParent="mainComposite",scope="player",kind="group",x=0,y=0,width=2,height=2,
            scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,unit="player",
            binding="static",color={1,1,1,1},blend="BLEND",rules={},conditions={},layer=97}
        design.nodes[#design.nodes+1]=group
    end
    group.treeParent="mainComposite"
    group.locked=false
    group.resourceSpacing=self.Clamp(tonumber(group.resourceSpacing) or 0,-20,20)
    group.hideWithoutTarget=group.hideWithoutTarget==true
    if not visual then
        visual={id="playerResourcesVisual",label="玩家资源图标",parent="playerResources",
            scope="player",kind="resources",x=122.22,y=-68.89,width=250,height=60,
            scale=.9,point="LEFT",anchor="CENTER",alpha=1,enabled=true,unit="player",
            binding="static",color={1,1,1,1},blend="BLEND",rules={},conditions={},
            internal=true,layer=98}
        design.nodes[#design.nodes+1]=visual
    end
    visual.internal=true
end
function M:UpgradeAnimationEffectsTrigger(design)
    for _,n in ipairs(design.nodes or {}) do
        if n.id=="wa65978f0ae2" then
            n.triggerAny="targetOrPlayerCast"
            n.visibleUnit=nil
        elseif n.id=="wa14ba01f1dc" then
            n.visibleUnit="player"
            n.rules={{test="casting",unit="player"}}
        elseif n.id=="wa96a1cd0f19" then
            n.visibleUnit="player"
            n.rules={{test="targetOrCasting"}}
        end
    end
end
function M:UpgradeAnimationEffectsOnce(design)
    local triggers={
        wac340c7383f="target",wacba6d051a4="target",wa83f139b6eb="target",
        wa77d77920ab="target",wa14ba01f1dc="cast",wa96a1cd0f19="targetOrCast",
    }
    for _,n in ipairs(design.nodes or {}) do
        local trigger=triggers[n.id]
        if trigger then
            n.effectOnce=true
            n.effectTrigger=trigger
            n.play="once"
        end
    end
end
function M:UpgradeMainAnimationEffects(design)
    for _,n in ipairs(design.nodes or {}) do
        if n.id=="wa0873e74c77" then
            n.internal=true;n.locked=true;n.noProperties=true;n.scope="all"
        elseif n.id=="wa65978f0ae2" then
            n.treeParent="mainComposite"
            n.internal=true;n.locked=true;n.noProperties=true;n.scope="all"
        elseif n.parent=="wa65978f0ae2" then
            n.internal=true;n.locked=true;n.noProperties=true;n.scope="all"
        end
    end
end
