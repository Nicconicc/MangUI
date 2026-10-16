local _,M=...
function M:NormalizeCenterPortraitOcclusion(design)
    if type(design)~="table" or type(design.nodes)~="table" then return end
    for _,node in ipairs(design.nodes) do
        if node.parent=="wabc757f81ee" and node.portraitOcclusionRevision~=1 then
            if node.id=="wa92712c7b3d" then
                node.layer=207;node.portraitOcclusionRevision=1
            elseif node.id=="wa88b1376baa" or node.id=="wa0b0b0540c7" then
                node.layer=206
                node.width=(node.width or 90)*0.95
                node.height=(node.height or 90)*0.95
                node.portraitOcclusionRevision=1
            end
        end
    end
end
function M:UpgradeCenterPortrait(design)
    local groupID="wabc757f81ee"
    local old={}
    for _,n in ipairs(design.nodes) do old[n.id]=n end
    if not old[groupID] then return end
    local fallback={}
    for _,n in ipairs(self.defaults.nodes) do fallback[n.id]=n end
    local specs={
        {"wa92712c7b3d","TokenFrame\\TokenFrame_01_BattleMaster",216,"BLEND"},
        {"wafd920b2a61","CenterBlack",219,"BLEND"},
        {"wa291016c8c1","CenterGlass",210,"ADD"},
        {"wa080cd4c4fb","CenterLight",209,"BLEND"},
    }
    local obsolete={waf207da072b=true,wab80c423318=true,wa3b534aad3d=true}
    local replacement={}
    for _,spec in ipairs(specs) do
        local id,file,layer,blend=spec[1],spec[2],spec[3],spec[4]
        local n=self.Copy(old[id] or fallback[id])
        if n then
            n.parent=groupID;n.scope="shared";n.kind="texture"
            n.x=0;n.y=0;n.width=256;n.height=256;n.scale=1
            n.point="CENTER";n.anchor="CENTER";n.alpha=1;n.enabled=true
            n.unit="player";n.binding="static";n.visibleUnit="player"
            n.color={1,1,1,1};n.file="Interface\\AddOns\\MangUI\\Assets\\"..file
            n.blend=blend;n.rotation=0;n.mirror=false;n.mirrorY=false
            n.cropX=0;n.cropY=0;n.rules={};n.conditions={}
            n.layer=layer;n.internal=true
            replacement[#replacement+1]=n
        end
        obsolete[id]=true
    end
    for _,spec in ipairs({{"wa88b1376baa","player",207},{"wa0b0b0540c7","target",207}}) do
        local id,unit,layer=spec[1],spec[2],spec[3]
        local n=self.Copy(old[id] or fallback[id])
        if n then
            n.parent=groupID;n.scope="shared";n.kind="portrait"
            n.x=0;n.y=0;n.width=90;n.height=90;n.scale=1
            n.point="CENTER";n.anchor="CENTER";n.alpha=1;n.enabled=true
            n.unit=unit;n.binding="static";n.visibleUnit=unit
            n.color={1,1,1,1};n.rules=unit=="player"
                and {{test="exists",unit="target",invert=true}} or {}
            n.conditions={};n.layer=layer;n.internal=true
            replacement[#replacement+1]=n
        end
        obsolete[id]=true
    end
    local nodes={}
    for _,n in ipairs(design.nodes) do
        if n.id==groupID then
            nodes[#nodes+1]=n
            for _,part in ipairs(replacement) do nodes[#nodes+1]=part end
        elseif not obsolete[n.id] then nodes[#nodes+1]=n end
    end
    design.nodes=nodes
end
function M:UpgradeTargetName(design)
    local groupID="wabc757f81ee"
    local removed={wa5f8db1fcbf=true,waaec9daac0a=true,wa97f1441c1b=true}
    local group,source,existing
    for _,n in ipairs(design.nodes) do
        if n.id==groupID then group=n
        elseif n.id=="wa5f8db1fcbf" then source=n
        elseif n.id=="targetUnifiedName" then existing=n end
    end
    if not group then return end
    -- This is a list hierarchy only. The render parent stays unchanged so the
    -- shared portrait keeps its position and player fallback without a target.
    group.treeParent="wa53d013cb9c"
    group.scope="target"
    local name=self.Copy(existing or source or {
        x=0,y=-110,width=200,height=33,scale=1,point="CENTER",anchor="CENTER",
        alpha=1,enabled=true,color={1,1,1,1},fontSize=22,font="Myriad",
        outline="OUTLINE",justify="CENTER",shadowX=3,shadowY=-3,layer=211,
    })
    name.id="targetUnifiedName";name.label="目标姓名"
    name.parent=groupID;name.scope="target";name.kind="text"
    name.unit="target";name.visibleUnit="target";name.binding="name"
    name.rules={};name.conditions={};name.nameColor=nil;name.targetNameColor=true
    name.autoWidth=true;name.text="%n";name.color={1,1,1,1}
    local nodes={}
    for _,n in ipairs(design.nodes) do
        if n.id==groupID then nodes[#nodes+1]=n;nodes[#nodes+1]=name
        elseif not removed[n.id] and n.id~="targetUnifiedName" then nodes[#nodes+1]=n end
    end
    design.nodes=nodes
end
function M:UpgradeCenterLevel(design)
    local parentID="wabc757f81ee"
    local groupID="centerLevel"
    local parts={wa585478f967=true,wa0b35e5bbc2=true,wa38ad2639d2=true}
    local parent,existing,first
    for _,n in ipairs(design.nodes) do
        if n.id==parentID then parent=n
        elseif n.id==groupID then existing=n
        elseif parts[n.id] and not first then first=n end
    end
    if not parent or not first then return end
    local group=existing or {
        id=groupID,label="等级 Player / Target level",parent=parentID,
        scope="target",kind="group",x=0,y=0,width=2,height=2,scale=1,
        point="CENTER",anchor="CENTER",alpha=1,enabled=true,
        unit="player",binding="static",color={1,1,1,1},
        blend="BLEND",rules={},conditions={},layer=234,
    }
    local nodes={}
    for _,n in ipairs(design.nodes) do
        if n==first and not existing then nodes[#nodes+1]=group end
        if n.id==groupID then nodes[#nodes+1]=group
        else
            if parts[n.id] then n.parent=groupID;n.internal=true end
            nodes[#nodes+1]=n
        end
    end
    design.nodes=nodes
end
function M:UpgradeCenterClassification(design)
    local parentID="wabc757f81ee"
    local groupID="centerClassification"
    local parts={wad38d9b944e=true,wad25ba7d231=true}
    local parent,existing,first
    for _,n in ipairs(design.nodes) do
        if n.id==parentID then parent=n
        elseif n.id==groupID then existing=n
        elseif parts[n.id] and not first then first=n end
    end
    if not parent or not first then return end
    local group=existing or {
        id=groupID,label="稀有精英图标",parent=parentID,
        scope="target",kind="group",x=0,y=0,width=2,height=2,scale=1,
        point="CENTER",anchor="CENTER",alpha=1,enabled=true,
        unit="target",binding="static",color={1,1,1,1},
        blend="BLEND",rules={},conditions={},layer=240,
    }
    local nodes={}
    for _,n in ipairs(design.nodes) do
        if n==first and not existing then nodes[#nodes+1]=group end
        if n.id==groupID then nodes[#nodes+1]=group
        else
            if parts[n.id] then n.parent=groupID;n.internal=true end
            nodes[#nodes+1]=n
        end
    end
    design.nodes=nodes
    self:EnsureCenterClassification(design)
end
function M:UpgradeCenterFire(design)
    local parentID="wabc757f81ee"
    local groupID="centerFire"
    local parts={waa3b4cd2bd6=true,wa278b65b0bb=true,wa6974d3f684=true}
    local removed={wa3f53f75d4e=true,waded06e146a=true}
    local parent,existing,first
    for _,n in ipairs(design.nodes) do
        if n.id==parentID then parent=n
        elseif n.id==groupID then existing=n
        elseif parts[n.id] and not first then first=n end
    end
    if not parent then return end
    local group=existing or (first and {
        id=groupID,label="装饰贴图与火焰动画",parent=parentID,
        scope="target",kind="group",x=0,y=0,width=2,height=2,scale=1,
        point="CENTER",anchor="CENTER",alpha=1,enabled=true,
        unit="player",binding="static",color={1,1,1,1},
        blend="BLEND",rules={},conditions={},layer=244,
    })
    local nodes={}
    for _,n in ipairs(design.nodes) do
        if n==first and not existing then nodes[#nodes+1]=group end
        if n.id==groupID then nodes[#nodes+1]=group
        elseif not removed[n.id] then
            if parts[n.id] then n.parent=groupID;n.internal=true end
            nodes[#nodes+1]=n
        end
    end
    design.nodes=nodes
end
function M:UpgradeMainComposite(design)
    local id="mainComposite"
    local members={
        wa70b7aa5607=true,waf0a666c0b7=true,wadb51e41246=true,
        wa8ee62b16d6=true,wa6edbcf125a=true,
        waf465575a72=true,wae608adf3d8=true,wa8492858a6d=true,
        wa712a8bee10=true,wa074335b474=true,
        wabc757f81ee=true,targetUnifiedName=true,waf24f8d43e3=true,
        centerLevel=true,centerClassification=true,centerFire=true,
    }
    local existing
    for _,n in ipairs(design.nodes) do if n.id==id then existing=n;break end end
    local group=existing or {
        id=id,label="玩家与目标主框体",parent="root",scope="all",kind="group",
        x=0,y=0,width=2,height=2,scale=1,point="CENTER",anchor="CENTER",
        alpha=1,enabled=true,unit="player",binding="static",
        color={1,1,1,1},blend="BLEND",rules={},conditions={},layer=4,
    }
    local nodes={}
    for _,n in ipairs(design.nodes) do
        nodes[#nodes+1]=n
        if members[n.id] then n.treeParent=id end
        if n.id=="root" and not existing then nodes[#nodes+1]=group end
    end
    design.nodes=nodes
end
function M:UpgradeBarMenus(design)
    local byID={}
    for _,n in ipairs(design.nodes) do byID[n.id]=n end
    for _,pair in ipairs({
        {"wab9dab4b3b1","wa70b7aa5607"},
        {"wa24502fe64f","waf465575a72"},
    }) do
        local menu,bar=byID[pair[1]],byID[pair[2]]
        if menu and bar then
            if menu.parent~=bar.id then
                local menuScale=menu.scale or 1
                local barScale=bar.scale or 1
                -- Both frames use CENTER anchors. Preserve the menu's current
                -- position and size while moving it under the HP bar frame.
                menu.x=(menu.x or 0)-(bar.x or 0)*barScale/menuScale
                menu.y=(menu.y or 0)-(bar.y or 0)*barScale/menuScale
                menu.scale=menuScale/barScale
                menu.parent=bar.id
            end
            menu.treeParent=bar.id
            menu.internal=true
        end
    end
end
function M:UpgradeTargetPortraitScale(design)
    for _,n in ipairs(design.nodes) do
        if n.id=="wa0b0b0540c7" then n.scale=1.2;return end
    end
end
function M:UpgradeCenterFallbackPortraitScale(design)
    for _,n in ipairs(design.nodes) do
        if n.id=="wa88b1376baa" then n.scale=1.2;return end
    end
end
function M:UpgradeCenterGlass(design)
    for _,n in ipairs(design.nodes) do
        if n.id=="wa291016c8c1" then
            n.file="Interface\\AddOns\\MangUI\\Assets\\Library\\CenterGlass_Original"
            n.width=200;n.height=200
            n.blend="ADD";n.alpha=1;n.color={1,1,1,1}
            return
        end
    end
end
function M:UpgradeCenterGlassLayer(design)
    for _,n in ipairs(design.nodes) do
        if n.id=="wa291016c8c1" then n.layer=210;return end
    end
end
function M:UpgradeMainRamps(design)
    local ramps={
        wae12272bfbd=.5,
        wa39c778505b=.5,
        wa8ba303231f=false,
        wab8d9a2846e=.6,
    }
    for _,n in ipairs(design.nodes) do
        local alpha=ramps[n.id]
        if alpha~=nil then
            n.color={0,0,0,1}
            if alpha then n.alpha=alpha end
        end
    end
end
function M:UpgradeMainLayerAlpha(design)
    local ids={
        wa35859adb29=true, -- PlayerHPGlass
        wa56eafb62c2=true, -- PlayerPowerGlass
        wa6d7e5b3bf4=true, -- TargetHPGlass
        waf16bf4d17d=true, -- TargetPowerGlass
        waf216fe2b9f=true, -- PlayerHPShadow
        wabc74ecc599=true, -- PlayerPowerShadow
        wa1882259c81=true, -- TargetHPShadow
        wa3e18cba51a=true, -- TargetPowerShadow
    }
    for _,n in ipairs(design.nodes) do
        if ids[n.id] then n.alpha=.5 end
    end
end
function M:UpgradeCenterLightRotation(design)
    for _,n in ipairs(design.nodes) do
        if n.id=="wa080cd4c4fb" then
            n.spinPeriod=20
            n.castSpinPeriod=.5
            return
        end
    end
end
function M:UpgradeCenterLogo(design)
    local parentIndex
    for index,n in ipairs(design.nodes) do
        if n.id=="centerLogo" then return end
        if n.id=="wabc757f81ee" then parentIndex=index end
    end
    if not parentIndex then return end
    table.insert(design.nodes,parentIndex+1,{
        id="centerLogo",label="CenterLogo",parent="wabc757f81ee",scope="shared",kind="texture",
        x=0,y=-4,width=160,height=160,scale=1,point="CENTER",anchor="CENTER",
        alpha=1,enabled=true,unit="player",binding="static",visibleUnit="player",
        color={1,1,1,1},file="Interface\\AddOns\\MangUI\\Assets\\Library\\CenterLogo",
        blend="BLEND",rotation=0,rules={},conditions={},layer=231,internal=true,
        centerLogo=true,logoStartScale=1.5,logoInDuration=.35,logoOutDuration=.35,
    })
end
function M:UpgradeCenterLogoScale(design)
    for _,n in ipairs(design.nodes) do
        if n.id=="centerLogo" then n.scale=1.5;return end
    end
end
function M:UpgradeMainBarParticles(design)
    local specs={
        wa4f9903a71c={id="playerHPParticles",label="玩家血量粒子",reverse=true,layer=600},
        wa58141a60dd={id="playerMPParticles",label="玩家能量粒子",reverse=true,layer=601},
        wa385c615b2a={id="targetHPParticles",label="目标血量粒子",reverse=false,layer=602},
        wadb47b70c3f={id="targetMPParticles",label="目标能量粒子",reverse=false,layer=603},
    }
    local existing={}
    for _,n in ipairs(design.nodes) do existing[n.id]=n end
    local nodes={}
    for _,bar in ipairs(design.nodes) do
        nodes[#nodes+1]=bar
        local spec=specs[bar.id]
        if spec then
            local fillWidth=math.max(1,(bar.width or 512)*(bar.fillExtent or 1))
            local x=(spec.reverse and 1 or -1)*((bar.width or 512)-fillWidth)/2
                +(spec.reverse and -50 or 50)
            if existing[spec.id] then
                local particle=existing[spec.id]
                particle.parent=bar.id;particle.x=x;particle.y=0
                particle.width=480;particle.height=120
                particle.blend="ADD"
                particle.particleCastFPS=90
                particle.layer=spec.layer
            else
                nodes[#nodes+1]={
                    id=spec.id,label=spec.label,parent=bar.id,scope=bar.scope,kind="sprite",
                    x=x,y=0,width=480,height=120,scale=1,
                    point="CENTER",anchor="CENTER",alpha=1,enabled=true,
                    unit=bar.unit,binding="static",visibleUnit=bar.visibleUnit,
                    color={1,1,1,1},file="Interface\\AddOns\\MangUI\\Assets\\Library\\TargetHPParticular",
                    blend="ADD",rows=64,columns=1,frames=64,fps=25,play="loop",
                    particleFlow=true,particleNormalReverse=spec.reverse,
                    particleCastFPS=90,
                    particleSlideX=spec.reverse and -10 or 10,particleSlideDuration=.4,
                    rules={},conditions={},layer=spec.layer,internal=true,
                }
            end
        end
    end
    design.nodes=nodes
end
