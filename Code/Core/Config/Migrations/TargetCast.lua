local _,M=...
function M:UpgradeTargetCastComposite(design)
    local oldID="wa89a259b16a"
    local byID={}
    for _,n in ipairs(design.nodes or {}) do byID[n.id]=n end
    if byID.targetCast then return end
    local old=byID[oldID]
    local obsolete={}
    for _,n in ipairs(design.nodes or {}) do
        local id=n.id;local seen={}
        while id and not seen[id] do
            if id==oldID then obsolete[n.id]=true;break end
            seen[id]=true
            id=byID[id] and byID[id].parent
        end
    end
    for i=#design.nodes,1,-1 do
        if obsolete[design.nodes[i].id] then table.remove(design.nodes,i) end
    end
    local sourceIDs={
        group="wa8d650f8d3a",fill="waba76314011",frame="wa1537213e27",
        icon="wa8fa968f2a9",name="waba76314011sub3",
    }
    local targetIDs={
        group="targetCast",fill="targetCastFill",frame="targetCastFrame",
        icon="targetCastIcon",name="targetCastName",
    }
    local defaultNodes={}
    for _,n in ipairs(self.defaults and self.defaults.nodes or {}) do defaultNodes[n.id]=n end
    local sources={}
    for key,id in pairs(sourceIDs) do sources[key]=byID[id] or defaultNodes[id] end
    if not sources.group then return end
    local scale=self.Clamp(tonumber(sources.group.scale) or 1.2,.5,1.5)
    local group=self.Copy(sources.group)
    group.id=targetIDs.group;group.label="目标施法条 Target cast bar"
    group.parent=old and old.parent or "wa53d013cb9c"
    group.treeParent="mainComposite";group.compound="targetCast"
    group.scope="target";group.unit="target";group.enabled=true
    group.internal=false;group.locked=false;group.scale=scale
    group.x=old and (old.x or 30)*(old.scale or 1)/scale or 25
    group.y=old and (old.y or -460)*(old.scale or 1)/scale or -460/scale
    group.layer=163
    design.nodes[#design.nodes+1]=group
    local layer={frame=185,fill=186,icon=187,name=189}
    local labels={frame="目标施法条框体",fill="目标施法进度",icon="目标施法图标",name="目标施法名称"}
    for _,key in ipairs({"frame","fill","icon","name"}) do
        local source=sources[key]
        if source then
            local n=self.Copy(source)
            n.id=targetIDs[key];n.parent=targetIDs.group;n.owner=nil
            n.label=labels[key];n.scope="target";n.unit="target"
            n.visibleUnit="target";n.rules={{test="casting",unit="target"}}
            n.conditions={};n.enabled=true;n.internal=true;n.locked=false
            n.treeParent=nil;n.layer=layer[key]
            design.nodes[#design.nodes+1]=n
        end
    end
end
