local _,M=...
function M:UpgradeFocusAvatar(design)
    for _,n in ipairs(design.nodes) do if n.id=="focusAvatar" then return end end
    local originals={waf8bf4ab582=true,wa80ccb35d69=true,wae766ba2633=true,wa0d7b685339=true}
    local oldPortrait,at
    for index,n in ipairs(design.nodes) do
        if n.id=="waf8bf4ab582" then oldPortrait=n end
        if originals[n.id] and not at then at=index end
    end
    local replacement={}
    for _,n in ipairs(self.defaults.nodes) do
        if n.id=="focusAvatar" or n.parent=="focusAvatar" then replacement[#replacement+1]=self.Copy(n) end
    end
    local group=replacement[1]
    if oldPortrait then
        group.x=oldPortrait.x or 0;group.y=oldPortrait.y or 0
        group.scale=oldPortrait.scale or 1;group.enabled=oldPortrait.enabled~=false
    end
    local result={};local inserted=false
    for index,n in ipairs(design.nodes) do
        if index==at then
            for _,new in ipairs(replacement) do result[#result+1]=new end
            inserted=true
        end
        if not originals[n.id] then result[#result+1]=n end
    end
    if not inserted then for _,new in ipairs(replacement) do result[#result+1]=new end end
    design.nodes=result
end
function M:UpgradeFocusPortraitSize(design)
    for _,n in ipairs(design.nodes) do
        if n.id=="waf8bf4ab582" and n.parent=="focusAvatar" then
            n.width=150;n.height=150
            return
        end
    end
end
function M:UpgradeFocusBackgroundSize(design)
    for _,n in ipairs(design.nodes) do
        if n.id=="wa80ccb35d69" and n.parent=="focusAvatar" then
            n.width=200;n.height=200
            return
        end
    end
end
function M:UpgradeFocusAvatar256(design)
    local sizes={
        wa0d7b685339=256,wae766ba2633=256,
        focusAvatarBlack=256,wa80ccb35d69=256,
        waf8bf4ab582=192,
    }
    for _,n in ipairs(design.nodes) do
        local size=sizes[n.id]
        if size and n.parent=="focusAvatar" then n.width=size;n.height=size end
    end
end
function M:UpgradeFocusHP(design)
    local groupID="wa438f32582f"
    local obsolete={wa05c979b9bdbg=true,wa05c979b9bd=true,wa05c979b9bdspark=true}
    local replacement,replaceIDs,oldByID={},{},{}
    for _,n in ipairs(self.defaults.nodes) do
        if n.id==groupID or n.parent==groupID then
            replacement[#replacement+1]=self.Copy(n)
            replaceIDs[n.id]=true
        end
    end
    local at
    for i,n in ipairs(design.nodes) do
        oldByID[n.id]=n
        if n.id==groupID then at=i end
    end
    for _,n in ipairs(replacement) do
        local old=oldByID[n.id]
        if old and n.id==groupID then
            n.x=old.x or n.x;n.y=old.y or n.y
            n.scale=old.scale or n.scale;n.enabled=old.enabled~=false
        elseif old and n.id=="wa916b193e98" then
            if type(old.color)=="table" then n.color=self.Copy(old.color) end
            if type(old.conditions)=="table" then n.conditions=self.Copy(old.conditions) end
        end
    end
    local result,inserted={},false
    for i,n in ipairs(design.nodes) do
        if i==at then
            for _,new in ipairs(replacement) do result[#result+1]=new end
            inserted=true
        end
        if not replaceIDs[n.id] and not obsolete[n.id] then result[#result+1]=n end
    end
    if not inserted then for _,new in ipairs(replacement) do result[#result+1]=new end end
    design.nodes=result
end
function M:UpgradeFocusHPAnimation(design)
    local color,hasSpark,at
    for i,n in ipairs(design.nodes) do
        if n.id=="wa916b193e98" and n.parent=="wa438f32582f" then color=n;at=i end
        if n.id=="focusHPSpark" then hasSpark=true end
    end
    if not color then return end
    color.smooth=true;color.smoothDuration=.35
    if hasSpark then return end
    for _,n in ipairs(self.defaults.nodes) do
        if n.id=="focusHPSpark" then
            table.insert(design.nodes,at+1,self.Copy(n))
            return
        end
    end
end
function M:UpgradeFocusMP(design)
    local groupID="wa49c31df401"
    local replacement,replaceIDs,oldByID={},{},{}
    for _,n in ipairs(self.defaults.nodes) do
        if n.id==groupID or n.parent==groupID or n.id=="focusMPSpark" then
            replacement[#replacement+1]=self.Copy(n)
            replaceIDs[n.id]=true
        end
    end
    local at
    for i,n in ipairs(design.nodes) do
        oldByID[n.id]=n
        if n.id==groupID then at=i end
    end
    for _,n in ipairs(replacement) do
        local old=oldByID[n.id]
        if old and n.id==groupID then
            n.x=old.x or n.x;n.y=old.y or n.y
            n.scale=old.scale or n.scale;n.enabled=old.enabled~=false
        elseif old and n.id=="waeddad93083" then
            if type(old.color)=="table" then n.color=self.Copy(old.color) end
            if type(old.conditions)=="table" then n.conditions=self.Copy(old.conditions) end
            n.materialName=old.materialName;n.materialPath=old.materialPath
        end
    end
    local result,inserted={},false
    for i,n in ipairs(design.nodes) do
        if i==at then
            for _,new in ipairs(replacement) do result[#result+1]=new end
            inserted=true
        end
        if not replaceIDs[n.id] then result[#result+1]=n end
    end
    if not inserted then for _,new in ipairs(replacement) do result[#result+1]=new end end
    design.nodes=result
end
function M:UpgradeFocusBarShadows(design)
    local shadowIDs={wa536ddaeffb=true,wa59428060f1=true}
    for _,n in ipairs(design.nodes) do
        if shadowIDs[n.id] then n.enabled=false;n.alpha=0 end
    end
end
function M:UpgradeFocusComposite(design)
    local groupID="focusComposite"
    local children={
        wa438f32582f={x=200,y=275,scale=1},
        wa49c31df401={x=200,y=240,scale=.9},
        focusAvatar={x=-100,y=0,scale=1},
    }
    local group,at
    for i,n in ipairs(design.nodes) do
        if n.id==groupID then group=n end
        if children[n.id] then
            at=at or i
            local values=children[n.id]
            n.parent=groupID;n.x=values.x;n.y=values.y;n.scale=values.scale;n.internal=true
        end
    end
    if not group then
        for _,n in ipairs(self.defaults.nodes) do
            if n.id==groupID then
                table.insert(design.nodes,at or #design.nodes+1,self.Copy(n))
                break
            end
        end
    end
end
function M:UpgradeFocusFillStart(design)
    for _,n in ipairs(design.nodes) do
        if n.id=="wa916b193e98" or n.id=="waeddad93083" then n.startAt="wa0d7b685339" end
    end
end
function M:UpgradeFocusScaleControls(design)
    for _,n in ipairs(design.nodes) do
        if n.id=="focusAvatar" then
            if math.abs((n.scale or 1)-.8)<.0001 then n.scale=1 end
            n.scale=self.Clamp(n.scale or 1,.5,1.5)
        elseif n.id=="focusComposite" then n.scale=self.Clamp(n.scale or 1,.5,1.5) end
    end
end
function M:UpgradeFocusName(design)
    local nodes={}
    for _,n in ipairs(design.nodes) do
        if n.id~="wa9f0beed4ab" then
            if n.id=="wab32587f90e" then n.parent="focusComposite";n.internal=true end
            nodes[#nodes+1]=n
        end
    end
    design.nodes=nodes
end
function M:UpgradeFocusNameControls(design)
    for _,n in ipairs(design.nodes) do
        if n.id=="wab32587f90e" then
            n.x=self.Clamp(n.x or 200,100,400)
            n.y=self.Clamp(n.y or 79,-100,100)
            n.autoWidth=true
        end
    end
end
function M:UpgradeFocusMenu(design)
    local nodes={}
    for _,n in ipairs(design.nodes) do
        if n.id~="wa3d7718c775" then nodes[#nodes+1]=n end
    end
    design.nodes=nodes
end
function M:UpgradeFocusCast(design)
    local castIDs={wa81bc085edc=true,wab2e0282c42bg=true,
        wab2e0282c42=true,wab2e0282c42sub3=true,wab2e0282c42sub4=true,focusCastIcon=true}
    local byID,nodes={},{}
    for _,n in ipairs(design.nodes) do
        if n.id~="wa866f85e638" then nodes[#nodes+1]=n;byID[n.id]=n end
    end
    design.nodes=nodes
    if design~=self.defaults then
        for _,template in ipairs(self.defaults.nodes) do
            if castIDs[template.id] and not byID[template.id] then
                local n=self.Copy(template);design.nodes[#design.nodes+1]=n;byID[n.id]=n
            end
        end
    end
    local group=byID.wa81bc085edc
    if group then
        group.parent="focusComposite";group.internal=true;group.compound="focusCast"
        group.x=270;group.y=-65;group.scale=1;group.unit="focus"
    end
    for _,id in ipairs({"wab2e0282c42bg","wab2e0282c42"}) do
        local n=byID[id]
        if n then
            n.x=-165;n.y=4;n.width=380;n.height=8;n.scale=1
            n.point="LEFT";n.anchor="CENTER";n.internal=true
        end
    end
    for _,id in ipairs({"wab2e0282c42sub3","wab2e0282c42sub4"}) do
        if byID[id] then byID[id].internal=true end
    end
    if not byID.focusCastIcon then
        design.nodes[#design.nodes+1]={id="focusCastIcon",label="焦点施法图标",parent="wa81bc085edc",
            scope="focus",kind="icon",internal=true,x=-205,y=4,width=40,height=40,scale=1,
            point="CENTER",anchor="CENTER",alpha=1,enabled=true,unit="focus",binding="castIcon",
            color={1,1,1,1},file=136048,blend="BLEND",layer=399,visibleUnit="focus",
            rules={{test="casting",unit="focus"}},conditions={}}
    end
end
function M:UpgradeFocusCastScale(design)
    local byID={}
    for _,n in ipairs(design.nodes) do byID[n.id]=n end
    local icon=byID.focusCastIcon
    local bar=byID.wab2e0282c42
    local background=byID.wab2e0282c42bg
    if not icon or not bar or not background then return end
    local left=(icon.x or -205)-(icon.width or 40)/2
    local iconWidth=(icon.width or 40)*1.5
    icon.x=left+iconWidth/2;icon.width=iconWidth;icon.height=(icon.height or 40)*1.5
    for _,n in ipairs({bar,background}) do
        local oldLeft=n.x or -165
        n.x=left+(oldLeft-left)*1.5
        n.width=(n.width or 380)*1.5;n.height=(n.height or 8)*1.5
    end
end
function M:UpgradeFocusCastAlignIcon(design)
    local byID={}
    for _,n in ipairs(design.nodes) do byID[n.id]=n end
    local icon=byID.focusCastIcon
    local left=icon and ((icon.x or 0)+(icon.width or 0)/2)
    if not left then return end
    for _,id in ipairs({"wab2e0282c42bg","wab2e0282c42"}) do
        local n=byID[id]
        if n then n.x=left;n.point="LEFT";n.anchor="CENTER" end
    end
end
function M:UpgradeFocusWrapper(design)
    local wrapper,composite
    for _,n in ipairs(design.nodes) do
        if n.id=="wac925c30a8f" then wrapper=n
        elseif n.id=="focusComposite" then composite=n end
    end
    if not composite then return end
    composite.label="焦点框体"
    if wrapper then
        if composite.parent==wrapper.id then
            local overallScale=composite.scale or 1
            composite.parent=wrapper.parent
            composite.point=wrapper.point
            composite.anchor=wrapper.anchor
            composite.x=(wrapper.x or 0)+(composite.x or 0)*(wrapper.scale or 1)
            composite.y=(wrapper.y or 0)+(composite.y or 0)*(wrapper.scale or 1)
            composite.baseScale=wrapper.scale or 1
            composite.scale=composite.baseScale*overallScale
            composite.alpha=(wrapper.alpha or 1)*(composite.alpha or 1)
            composite.enabled=wrapper.enabled~=false and composite.enabled~=false
            composite.locked=wrapper.locked or composite.locked
        end
        for _,n in ipairs(design.nodes) do
            if n.parent==wrapper.id then n.parent=composite.id end
        end
        local nodes={}
        for _,n in ipairs(design.nodes) do
            if n~=wrapper then nodes[#nodes+1]=n end
        end
        design.nodes=nodes
    end
end
