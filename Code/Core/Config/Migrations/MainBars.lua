local _,M=...
function M:UpgradePlayerHP(design)
    local groupID="wa70b7aa5607"
    local parts={
        {"waf216fe2b9f","PlayerHPShadow","Player HP shadow","texture",11},
        {"wa4f9903a71cbg","PlayerHPBG","Player HP bar · 背景","texture",13},
        {"wa4f9903a71c","PlayerHPColor","Player HP bar","bar",15},
        {"wae12272bfbd","PlayerHPRamp","Player HP ramp","texture",17},
        {"wa35859adb29","PlayerHPGlass","Player HP glass","texture",19},
        {"waed2b7d662a","PlayerHPKuang","Player HP frame","texture",21},
    }
    local obsolete={wa561ce245af=true,wa42af8eec9f=true,
        waee32bec44abg=true,waee32bec44a=true,waee32bec44aspark=true,
        wa50009a654e=true,playerHPSpark=true}
    local old={}
    for _,n in ipairs(design.nodes) do old[n.id]=n end
    if not old[groupID] then return end
    local fallback={}
    for _,n in ipairs(self.defaults.nodes) do fallback[n.id]=n end
    local replacement={}
    for _,spec in ipairs(parts) do
        local id,file,label,kind,layer=spec[1],spec[2],spec[3],spec[4],spec[5]
        local n=self.Copy(old[id] or fallback[id])
        if n then
            n.label=label;n.parent=groupID;n.scope="player";n.kind=kind
            n.x=50;n.y=-250;n.width=512;n.height=128;n.scale=1
            n.point="CENTER";n.anchor="CENTER";n.alpha=1;n.enabled=true
            n.unit="player";n.binding=kind=="bar" and "health" or "static"
            n.visibleUnit="player";n.file="Interface\\AddOns\\MangUI\\Assets\\"..file
            n.blend=file=="PlayerHPGlass" and "ADD" or "BLEND"
            n.cropX=0;n.cropY=0;n.rotation=0;n.mirror=false;n.mirrorY=false
            n.rules={};n.layer=layer;n.internal=true
            if kind=="bar" then
                n.reverse=true;n.vertical=false;n.alphaFill=true
                n.fillExtent=366/512;n.fillInset=0
                n.smooth=true;n.smoothDuration=.35
                n.startAt=nil;n.materialName=nil;n.materialPath=nil
            else n.color={1,1,1,1};n.conditions={} end
            replacement[#replacement+1]=n
        end
        obsolete[id]=true
    end
    local spark=self.Copy(old.waee32bec44aspark or old.playerHPSpark or fallback.playerHPSpark)
    if spark then
        spark.id="playerHPSpark";spark.label="玩家血量边缘 Spark"
        spark.parent="wa4f9903a71c";spark.owner="wa4f9903a71c"
        spark.scope="player";spark.kind="spark";spark.unit="player"
        spark.binding="health";spark.visibleUnit="player"
        spark.x=0;spark.y=0;spark.width=30;spark.height=40;spark.scale=1
        spark.point="CENTER";spark.anchor="LEFT";spark.alpha=1;spark.enabled=true
        spark.color={.98823535442352,1,1,1};spark.blend="ADD"
        spark.file="Interface\\CastingBar\\UI-CastingBar-Spark"
        spark.edgeOnly=true;spark.followDisplay=true;spark.layer=16;spark.internal=true
        replacement[#replacement+1]=spark
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
function M:UpgradePlayerMP(design)
    local groupID="waf0a666c0b7"
    local parts={
        {"wabc74ecc599","PlayerPowerShadow","Player MP shadow","texture",37},
        {"wa58141a60ddbg","PlayerPowerBG","Player MP bar · 背景","texture",39},
        {"wa58141a60dd","PlayerPowerColor","Player MP bar","bar",41},
        {"wa39c778505b","PlayerPowerRamp","Player MP ramp","texture",43},
        {"wa56eafb62c2","PlayerPowerGlass","Player MP glass","texture",45},
        {"wa4889e74a55","PlayerPowerKuang","Player MP frame","texture",47},
    }
    local obsolete={wa5dba6775e7=true,wad65f98bcd3=true,
        waf3ffa83d49bg=true,waf3ffa83d49=true,waf3ffa83d49spark=true,
        waaf380a9dea=true,playerMPSpark=true}
    local old={}
    for _,n in ipairs(design.nodes) do old[n.id]=n end
    if not old[groupID] then return end
    local fallback={}
    for _,n in ipairs(self.defaults.nodes) do fallback[n.id]=n end
    local replacement={}
    for _,spec in ipairs(parts) do
        local id,file,label,kind,layer=spec[1],spec[2],spec[3],spec[4],spec[5]
        local n=self.Copy(old[id] or fallback[id])
        if n then
            n.label=label;n.parent=groupID;n.scope="player";n.kind=kind
            n.x=50;n.y=-295;n.width=512;n.height=128;n.scale=1
            n.point="CENTER";n.anchor="CENTER";n.alpha=1;n.enabled=true
            n.unit="player";n.binding=kind=="bar" and "power" or "static"
            n.visibleUnit="player";n.file="Interface\\AddOns\\MangUI\\Assets\\"..file
            n.blend=file=="PlayerPowerGlass" and "ADD" or "BLEND"
            n.cropX=0;n.cropY=0;n.rotation=0;n.mirror=false;n.mirrorY=false
            n.rules={};n.layer=layer;n.internal=true
            if kind=="bar" then
                n.reverse=true;n.vertical=false;n.alphaFill=true
                n.fillExtent=320/512;n.fillInset=0
                n.smooth=true;n.smoothDuration=.35;n.powerColor=true
                n.startAt=nil;n.materialName=nil;n.materialPath=nil
            else n.color={1,1,1,1};n.conditions={} end
            replacement[#replacement+1]=n
        end
        obsolete[id]=true
    end
    local spark=self.Copy(old.waf3ffa83d49spark or old.playerMPSpark or fallback.playerMPSpark)
    if spark then
        spark.id="playerMPSpark";spark.label="玩家能量边缘 Spark"
        spark.parent="wa58141a60dd";spark.owner="wa58141a60dd"
        spark.scope="player";spark.kind="spark";spark.unit="player"
        spark.binding="power";spark.visibleUnit="player"
        spark.x=0;spark.y=0;spark.width=30;spark.height=40;spark.scale=1
        spark.point="CENTER";spark.anchor="LEFT";spark.alpha=1;spark.enabled=true
        spark.color={.98823535442352,1,1,1};spark.blend="ADD"
        spark.file="Interface\\CastingBar\\UI-CastingBar-Spark"
        spark.edgeOnly=true;spark.followDisplay=true;spark.layer=42;spark.internal=true
        replacement[#replacement+1]=spark
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
function M:UpgradeTargetHP(design)
    local groupID="waf465575a72"
    local parts={
        {"wa1882259c81","TargetHPShadow","Target HP shadow","texture",107},
        {"wa385c615b2abg","TargetHPBG","Target HP bar · 背景","texture",109},
        {"wa385c615b2a","TargetHPColor","Target HP bar","bar",111},
        {"wa8ba303231f","TargetHPRamp","Target HP ramp","texture",113},
        {"wa6d7e5b3bf4","TargetHPGlass","Target HP glass","texture",115},
        {"waae10175c53","TargetHPKuang","Target HP frame","texture",117},
    }
    local obsolete={wa9b9830d1e5=true,waf0fc42203b=true,
        wac6e2431f6dbg=true,wac6e2431f6d=true,wac6e2431f6dspark=true,
        wa94f7171757=true,targetHPSpark=true}
    local old={}
    for _,n in ipairs(design.nodes) do old[n.id]=n end
    if not old[groupID] then return end
    local fallback={}
    for _,n in ipairs(self.defaults.nodes) do fallback[n.id]=n end
    local replacement={}
    for _,spec in ipairs(parts) do
        local id,file,label,kind,layer=spec[1],spec[2],spec[3],spec[4],spec[5]
        local n=self.Copy(old[id] or fallback[id])
        if n then
            n.label=label;n.parent=groupID;n.scope="target";n.kind=kind
            n.x=50;n.y=-250;n.width=512;n.height=128;n.scale=1
            n.point="CENTER";n.anchor="CENTER";n.alpha=1;n.enabled=true
            n.unit="target";n.binding=kind=="bar" and "health" or "static"
            n.visibleUnit="target";n.file="Interface\\AddOns\\MangUI\\Assets\\"..file
            n.blend=file=="TargetHPGlass" and "ADD" or "BLEND"
            n.cropX=0;n.cropY=0;n.rotation=0;n.mirror=false;n.mirrorY=false
            n.rules={};n.layer=layer;n.internal=true
            if kind=="bar" then
                n.reverse=false;n.vertical=false;n.alphaFill=true
                n.fillExtent=483/512;n.fillInset=0
                n.smooth=true;n.smoothDuration=.35
                n.startAt=nil;n.materialName=nil;n.materialPath=nil
            else n.color={1,1,1,1};n.conditions={} end
            replacement[#replacement+1]=n
        end
        obsolete[id]=true
    end
    local spark=self.Copy(old.wac6e2431f6dspark or old.targetHPSpark or fallback.targetHPSpark)
    if spark then
        spark.id="targetHPSpark";spark.label="目标血量边缘 Spark"
        spark.parent="wa385c615b2a";spark.owner="wa385c615b2a"
        spark.scope="target";spark.kind="spark";spark.unit="target"
        spark.binding="health";spark.visibleUnit="target"
        spark.x=0;spark.y=0;spark.width=30;spark.height=40;spark.scale=1
        spark.point="CENTER";spark.anchor="LEFT";spark.alpha=1;spark.enabled=true
        spark.color={.98823535442352,1,1,1};spark.blend="ADD"
        spark.file="Interface\\CastingBar\\UI-CastingBar-Spark"
        spark.edgeOnly=true;spark.followDisplay=true;spark.layer=112;spark.internal=true
        replacement[#replacement+1]=spark
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
function M:UpgradeTargetMP(design)
    local groupID="wae608adf3d8"
    local parts={
        {"wa3e18cba51a","TargetPowerShadow","Target MP shadow","texture",133},
        {"wadb47b70c3fbg","TargetPowerBG","Target MP bar · 背景","texture",135},
        {"wadb47b70c3f","TargetPowerColor","Target MP bar","bar",137},
        {"wab8d9a2846e","TargetPowerRamp","Target MP ramp","texture",139},
        {"waf16bf4d17d","TargetPowerGlass","Target MP glass","texture",141},
        {"wa8660d78045","TargetPowerKuang","Target MP frame","texture",143},
    }
    local obsolete={wa5e3853826c=true,wa667b5ff41f=true,
        wa6fe2ca4dd1bg=true,wa6fe2ca4dd1=true,wa6fe2ca4dd1spark=true,
        wa1853affaa3=true,targetMPSpark=true}
    local old={}
    for _,n in ipairs(design.nodes) do old[n.id]=n end
    if not old[groupID] then return end
    local fallback={}
    for _,n in ipairs(self.defaults.nodes) do fallback[n.id]=n end
    local replacement={}
    for _,spec in ipairs(parts) do
        local id,file,label,kind,layer=spec[1],spec[2],spec[3],spec[4],spec[5]
        local n=self.Copy(old[id] or fallback[id])
        if n then
            n.label=label;n.parent=groupID;n.scope="target";n.kind=kind
            n.x=50;n.y=-295;n.width=512;n.height=128;n.scale=1
            n.point="CENTER";n.anchor="CENTER";n.alpha=1;n.enabled=true
            n.unit="target";n.binding=kind=="bar" and "power" or "static"
            n.visibleUnit="target";n.file="Interface\\AddOns\\MangUI\\Assets\\"..file
            n.blend=file=="TargetPowerGlass" and "ADD" or "BLEND"
            n.cropX=0;n.cropY=0;n.rotation=0;n.mirror=false;n.mirrorY=false
            n.rules={};n.layer=layer;n.internal=true
            if kind=="bar" then
                n.reverse=false;n.vertical=false;n.alphaFill=true
                n.fillExtent=492/512;n.fillInset=0
                n.smooth=true;n.smoothDuration=.35;n.powerColor=true
                n.startAt=nil;n.materialName=nil;n.materialPath=nil
            else n.color={1,1,1,1};n.conditions={} end
            replacement[#replacement+1]=n
        end
        obsolete[id]=true
    end
    local spark=self.Copy(old.wa6fe2ca4dd1spark or old.targetMPSpark or fallback.targetMPSpark)
    if spark then
        spark.id="targetMPSpark";spark.label="目标能量边缘 Spark"
        spark.parent="wadb47b70c3f";spark.owner="wadb47b70c3f"
        spark.scope="target";spark.kind="spark";spark.unit="target"
        spark.binding="power";spark.visibleUnit="target"
        spark.x=0;spark.y=0;spark.width=30;spark.height=40;spark.scale=1
        spark.point="CENTER";spark.anchor="LEFT";spark.alpha=1;spark.enabled=true
        spark.color={.98823535442352,1,1,1};spark.blend="ADD"
        spark.file="Interface\\CastingBar\\UI-CastingBar-Spark"
        spark.edgeOnly=true;spark.followDisplay=true;spark.layer=138;spark.internal=true
        replacement[#replacement+1]=spark
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
