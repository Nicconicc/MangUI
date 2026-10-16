local _,M=...
function M:UpgradePlayerCastComposite(design)
    local ids={
        wa8d650f8d3a=true,waba76314011=true,waba76314011sub2=true,
        waba76314011sub3=true,wa1537213e27=true,wa8fa968f2a9=true,
    }
    local obsolete={
        wa2ee415a49e=true,waba76314011bg=true,wa505ddbc726bg=true,
        wa505ddbc726=true,wa505ddbc726spark=true,wa505ddbc726sub3=true,
        wa505ddbc726sub4=true,wa505ddbc726sub5=true,
        wa8fa968f2a9sub2=true,wa8fa968f2a9sub3=true,
    }
    local byID={}
    for _,n in ipairs(design.nodes or {}) do byID[n.id]=n end
    if design~=self.defaults and self.defaults and self.defaults.nodes then
        for _,source in ipairs(self.defaults.nodes) do
            if ids[source.id] and not byID[source.id] then
                local copy=self.Copy(source)
                design.nodes[#design.nodes+1]=copy;byID[copy.id]=copy
            end
        end
    end
    local group=byID.wa8d650f8d3a
    if group then
        group.label="玩家施法条"
        group.compound="playerCast"
        group.internal=false;group.locked=false
    end
    local castRule={{test="casting",unit="player"}}
    local function Part(id,kind,x,y,width,height,layer)
        local n=byID[id]
        if not n then return end
        n.parent="wa8d650f8d3a";n.owner=nil;n.kind=kind
        n.x=x;n.y=y;n.width=width;n.height=height;n.scale=1
        n.point="CENTER";n.anchor="CENTER";n.alpha=1
        n.enabled=true;n.unit="player";n.visibleUnit="player"
        n.rules=self.Copy(castRule);n.conditions={}
        n.internal=true;n.locked=true;n.layer=layer
        return n
    end
    local bar=Part("waba76314011","bar",0,0,512,128,71)
    if bar then
        bar.label="玩家施法进度"
        bar.binding="cast";bar.file="Interface\\AddOns\\MangUI\\Assets\\Library\\CenterBlackCastbarBar"
        bar.materialPath=nil;bar.maskOnly=nil
        bar.alphaFill=true;bar.fillExtent=1;bar.fillInset=0
        bar.cropX=0;bar.cropY=0;bar.reverse=false;bar.vertical=false
        bar.color={0,1,.93333339691162,1}
    end
    local frame=Part("wa1537213e27","texture",0,0,512,128,91)
    if frame then
        frame.label="玩家施法条框体"
        frame.binding="cast";frame.file="Interface\\AddOns\\MangUI\\Assets\\Library\\CenterBlackCastbarKuang"
        frame.color={1,1,1,1};frame.blend="BLEND"
    end
    local icon=Part("wa8fa968f2a9","icon",-280,0,45,45,93)
    if icon then icon.label="玩家施法图标";icon.binding="castIcon";icon.color={1,1,1,1} end
    local name=Part("waba76314011sub3","text",0,-34,400,30,95)
    if name then
        name.label="玩家施法名称";name.binding="castName";name.fontSize=18
        name.font="游戏默认";name.justify="CENTER";name.color={1,1,1,1}
    end
    local timer=Part("waba76314011sub2","text",300,0,80,30,97)
    if timer then
        timer.label="玩家施法倒计时";timer.binding="castTime";timer.fontSize=18
        timer.font="游戏默认";timer.justify="LEFT";timer.color={1,1,1,1}
    end
    for i=#design.nodes,1,-1 do
        if obsolete[design.nodes[i].id] then table.remove(design.nodes,i) end
    end
end
function M:UpgradePlayerCastFill(design)
    for _,n in ipairs(design.nodes or {}) do
        if n.id=="waba76314011" and n.parent=="wa8d650f8d3a" then
            -- Display the BLP directly: its alpha channel shapes the visible fill.
            n.file="Interface\\AddOns\\MangUI\\Assets\\Library\\CenterBlackCastbarBar"
            n.materialPath=nil;n.maskOnly=nil;n.alphaFill=true
            n.fillExtent=1;n.fillInset=0
            return
        end
    end
end
function M:UpgradePlayerCastDirectFill(design)
    for _,n in ipairs(design.nodes or {}) do
        if n.id=="waba76314011" and n.parent=="wa8d650f8d3a" then
            n.kind="texture";n.castFill=true;n.binding="cast"
            n.file="Interface\\AddOns\\MangUI\\Assets\\Library\\CenterBlackCastbarBar"
            n.color={0,1,.93333339691162,1}
            n.alphaFill=nil;n.maskOnly=nil;n.materialPath=nil
            n.width=512;n.height=128;n.x=0;n.y=0
            n.cropX=0;n.cropY=0;n.blend="BLEND"
            return
        end
    end
end
function M:UpgradePlayerCastLayer(design)
    for _,n in ipairs(design.nodes or {}) do
        if n.id=="waba76314011" and n.parent=="wa8d650f8d3a" then
            -- CenterBlackCastbarKuang has an opaque black center, so the fill
            -- must render above its frame level (91) and below the icon (93).
            n.layer=92
            return
        end
    end
end
function M:UpgradePlayerPowerDisplay(design)
    for _,n in ipairs(design.nodes or {}) do
        if n.id=="wa6edbcf125a" then
            n.binding="powerPercent"
            n.manaPercentOtherwiseValue=true
            return
        end
    end
end
