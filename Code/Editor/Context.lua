local _,M=...
local W,R=M.Widgets,M.Renderer
local unpack=unpack or table.unpack
local topLevelFrames={"mainComposite","wa8d650f8d3a","petComposite","totComposite","focusComposite","partyFrames","bossFrames","cooldownMonitor","targetDistance","targetThreat","chatButtons","systemMenu","experienceBar","mouseCircle","combatNotices"}
local unlockExcluded={mouseCircle=true,targetDistance=true,systemMenu=true}
local function ModuleAvailable(id)
    local interface=M.Compat.interface or 0
    local classicEra=interface>=10000 and interface<20000 and interface~=16001
    return not (classicEra and id=="focusComposite")
end
local moduleGroupBreaks={bossFrames=true,targetThreat=true,experienceBar=true}
local moduleGroupColors={{.35,.95,1,1},{1,.82,.3,1},{.8,.65,1,1},{.55,1,.55,1}}
local moduleColorPalette={moduleGroupColors[1],moduleGroupColors[2],moduleGroupColors[3],moduleGroupColors[4],
    {1,.35,.35,1},{1,.6,.3,1},{.4,.65,1,1},{1,.5,.8,1}}
local disabledModuleColor={.6,.6,.6,1}
local unitChoices={{"player","玩家"},{"target","目标"},{"pet","宠物"},{"targettarget","目标的目标"},{"focus","焦点"},{"shared","共享头像单位"}}
local bindingChoices={{"static","固定内容"},{"health","生命进度"},{"power","资源进度"},{"healthText","生命数值"},{"powerText","资源数值"},{"healthPercent","生命百分比"},{"powerPercent","资源百分比"},{"name","单位名称"},{"level","等级"},{"cast","施法进度"},{"castName","施法名称"},{"castTime","施法剩余时间"},{"castIcon","施法图标"},{"auraStacks","光环层数"},{"auraTime","光环剩余时间"}}
local pointXY={CENTER={0,0},LEFT={-1,0},RIGHT={1,0},TOP={0,1},BOTTOM={0,-1},TOPLEFT={-1,1},TOPRIGHT={1,1},BOTTOMLEFT={-1,-1},BOTTOMRIGHT={1,-1}}
local compositeParts={
    focusComposite={avatar="focusAvatar",hp="focusHP",mp="focusMP"},
    petComposite={avatar="petAvatar",hp="petHP",mp="petMP"},
    totComposite={avatar="totAvatar",hp="totHP"},
}
local mainBarParts=M.MainBarLayout.parts
local mainAuraIcons={wa028b62b494=true,wadde9035c6a=true}
local function MainBarPart(group)
    return group and mainBarParts[group.id]
end
local function IsUnitComposite(group)
    return group and compositeParts[group.compound]~=nil
end
local function HasDedicatedPreview(group)
    return group and (group.compound=="playerCast" or group.compound=="cooldownMonitor" or group.compound=="chatButtons" or group.compound=="combatNotices" or group.compound=="systemMenu" or group.compound=="mouseCircle" or group.compound=="experienceBar" or group.compound=="targetThreat" or group.compound=="targetDistance" or M:ModuleID(group)=="bossFrames" or M:ModuleID(group)=="partyFrames")
end
local function IsCastGroup(group)
    return group and (group.compound=="playerCast" or group.compound=="targetCast")
end
local function RoundOffset(value)
    if value>=0 then return math.floor(value+.5) end
    return math.ceil(value-.5)
end
local function SetActualFontControl(control,value,minimum,maximum)
    value=math.floor(value*100+.5)/100
    control.updating=true
    control:SetMinMaxValues(math.min(minimum,value),math.max(maximum,value))
    control:SetValue(value);control.updating=false
end
local targetCastParts={
    wa8fa968f2a9="targetCastIcon",waba76314011sub3="targetCastName",
    waba76314011sub2=nil,
}
local function CastPart(group,id)
    if not IsCastGroup(group) or not M.byID then return nil end
    local partID=id
    if group.compound=="targetCast" then partID=targetCastParts[id] end
    return partID and M.byID[partID] or nil
end
local function FontPreviewPath(n)
    if n.fontPath and n.fontPath~="" then return n.fontPath end
    if n.font=="Myriad" and n.binding~="name" and n.binding~="static" and n.binding~="castName" and n.binding~="petStatus" then
        return M.MYRIAD
    end
    return M:DefaultFontPath()
end
local function FontChoiceName(n)
    return n.fontName or (FontPreviewPath(n)==M.MYRIAD and "Myriad" or "默认")
end

function M:Geometry(index,ids)
    index=index or self.byID
    local out={}
    local function Calc(n,depth)
        if out[n.id] then return out[n.id] end
        if depth>100 then return {x=0,y=0,s=1,w=2,h=2} end
        local p=n.parent and index[n.parent];local g=p and Calc(p,depth+1) or {x=0,y=0,s=1,w=2,h=2}
        if pointXY[n.screenAnchor] then g={x=0,y=0,s=1,w=UIParent:GetWidth(),h=UIParent:GetHeight()} end
        local s=g.s*self:NodeScale(n);local a=pointXY[n.anchor] or pointXY.CENTER;local q=pointXY[n.point] or pointXY.CENTER
        if n.screenAnchor then a=pointXY[n.screenAnchor] or pointXY.CENTER end
        local w,h=n.width or 2,n.height or 2
        -- Resolve rebased positions through this calculation's ancestor results.
        -- Starting a new Geometry call for each label repeats the same tree walk.
        local x,y=self:NodePosition(n,index,function(id)
            local node=index[id];return node and Calc(node,depth+1)
        end)
        local result={x=g.x+a[1]*g.w*g.s/2+x*s-q[1]*w*s/2,y=g.y+a[2]*g.h*g.s/2+y*s-q[2]*h*s/2,s=s,w=w,h=h}
        local moveX,moveY=M:MainModuleOffset(n,index)
        result.x=result.x+moveX;result.y=result.y+moveY
        out[n.id]=result;return result
    end
    if ids then
        for _,id in pairs(ids) do if index[id] then Calc(index[id],0) end end
    else
        for _,n in pairs(index) do Calc(n,0) end
    end
    return out
end
function M:MainCanvasRange(n,axis,index)
    local e=self.editor
    if not e or not e.mainPreview or not e.window:IsShown() or not e.canvas:IsShown() or not e.fit then return end
    local geo=self:Geometry(index);local g=geo[n.id];if not g then return end
    local parent=geo[n.parent];local unit=g.s
    if n.id=="centerFire" or n.id=="waf24f8d43e3" or n.id=="centerClassification" or n.valueTextOriginRevision==1 or n.resourceOriginRevision==1 or n.auraOriginRevision==1 or n.castOriginRevision==1 then unit=parent and parent.s or 1 end
    if unit<=0 then return end
    if n.id=="playerResources" then
        -- The editable group is only 2x2. Limit its visible resource row,
        -- whose LEFT anchor and downward offset extend beyond that origin.
        local object=e.view and e.view.nodes.playerResourcesVisual
        local frame=object and object.frame
        if frame and frame:GetLeft() and e.canvas:GetLeft() then
            local scale=frame:GetEffectiveScale()/e.canvas:GetEffectiveScale()
            local low=axis=="x" and frame:GetLeft()*scale or frame:GetBottom()*scale
            local high=axis=="x" and frame:GetRight()*scale or frame:GetTop()*scale
            local canvasLow=axis=="x" and e.canvas:GetLeft() or e.canvas:GetBottom()
            local canvasHigh=axis=="x" and e.canvas:GetRight() or e.canvas:GetTop()
            local minimum=(n[axis] or 0)+(canvasLow-low)/(unit*e.fit)
            local maximum=(n[axis] or 0)+(canvasHigh-high)/(unit*e.fit)
            minimum=math.ceil(minimum-1e-7);maximum=math.floor(maximum+1e-7)
            if minimum>maximum then local center=RoundOffset((minimum+maximum)/2);return center,center end
            return minimum,maximum
        end
    end
    local center=(axis=="x" and e.centerX or e.centerY) or 0
    local pan=(axis=="x" and e.panX or e.panY) or 0
    local size=axis=="x" and e.canvas:GetWidth() or e.canvas:GetHeight()
    local half=size/(2*e.fit);center=center-pan/e.fit
    local minimum=(n[axis] or 0)+(center-half-g[axis])/unit
    local maximum=(n[axis] or 0)+(center+half-g[axis])/unit
    -- Offset controls use whole-number steps, so keep their bounds on that grid.
    return math.floor(minimum+1e-7),math.ceil(maximum-1e-7)
end
local function Selected()return M.selection and M.byID[M.selection]end
-- Each inner list is one user-facing settings category. Only visible rows take space.
local propertyCategories={
    unit={{"overallScale","avatarScale","avatarX"},{"hpMaterial","healthColors","totHPY"},
        {"nameX","nameY","nameFont","nameSize"},{"castX","castY","castWidth","castHeight"},
        {"focusPortraitOnly","petPowerHidden","petNameEnabled"}},
    bossFrames={{"scale"},{"bossHPMaterial","bossHPColor"},
        {"bossPercentX","bossPercentY","bossFont","bossPercentSize"},{"bossCastY","bossCastColor"},{"bossHideAvatar","combatSound"}},
    partyFrames={{"scale","partySpacing","partyPlayerX"},{"partyMaterial","partyHealthColor","partyHealthEndColor"},
        {"partyFont","partyNameSize"},{"partyHideInRaid","partyHideNumbers","partyHidePlayer"}},
    cast={{"overallScale","castIconSize","castColor"},{"nameFont","castFontSize"},{"showRangedProgress","showMeleeProgress"}},
    cooldownMonitor={{"scale"},{"minCooldown","maxCooldown"},{"blacklist"}},
    chatButtons={{"iconSize","buttonSpacing"},{"nameFont","fontSize","fontYOffset","chatTextLabels"},{"customChannelName","pullSeconds"}},
    targetThreat={{"nameFont","fontSize"},{"threatInstanceOnly"}},
    experienceBar={{"scale","experienceHeight"},{"nameFont"}},
    systemMenu={{"scale"}},mouseCircle={{"scale"},{"mouseColors"}},combatNotices={{"scale"},{"combatSound"}},
    portrait={{"overallScale"},{"portraitAvatarScale","portraitOuterScale","portraitFrameTexture"},
        {"portraitLightEnabled","portraitLightScale"},{"portraitGlassEnabled","portraitGlassScale","portraitGlassAlpha"}},
    generic={{"scale","overallScale","x","y","width","height","alpha","layer","resourceSpacing"},
        {"unit","binding"},{"hpMaterial","healthColors","healthThresholdEnabled","healthThreshold"},
        {"nameFont","fontSize","text"},{"auraFilter","debuffCount","debuffPerRow","buffCount","buffPerRow","count","spacing"},
        {"file","media","rotation","blend","colorTitle","color1","color2","color3","color4"},
        {"progressTitle","reverse","cropX","cropY","rows","columns","frames","fps","play"},
        {"model","modelScale","modelX","modelY","modelZ"},
        {"hideUntimedBuffs","decorationHidden","playerHealthPercentHidden","flags","rulesTitle","rules"}},
}
local function OrganizePropertyRows(n,rows)
    local profile=propertyCategories[n.compound] or propertyCategories.generic
    if n.id=="wabc757f81ee"then profile=propertyCategories.portrait
    elseif n.id=="wa026b04c50e"then profile={{"scale","x","y"},{"debuffCount","debuffPerRow"},{"onlyPlayerDebuffs","debuffHidden"}}
    elseif n.compound=="petComposite"or n.compound=="totComposite"or n.compound=="focusComposite"then profile=propertyCategories.unit
    elseif n.compound=="targetCast"then profile={{"overallScale","x","y","castIconSize"},{"nameFont","castFontSize"},{"hideCastName"}}
    elseif n.compound=="playerCast"then profile=propertyCategories.cast
    elseif n.compound=="targetDistance"then
        profile={{"showOnRing","showOnNameplate"},{"distanceIconSize","distanceX","distanceY"},{"distanceTitle","distanceHint"}}
        for _,class in ipairs(M.TargetDistance.classes)do profile[#profile+1]={"rangeSpell"..class[1],"rangeManual"..class[1]}end
    end
    local order,section={},{}
    for group,keys in ipairs(profile)do for i,key in ipairs(keys)do order[key]=group*100+i;section[key]=group end end
    for index,entry in ipairs(rows)do
        local key=entry.row.key
        entry.originalIndex=index;entry.section=section[key]or 99;entry.rank=order[key]or 9900+index
    end
    table.sort(rows,function(a,b)return a.rank==b.rank and a.originalIndex<b.originalIndex or a.rank<b.rank end)
    return rows
end
local function PropertyDivider(e,height)
    e.propertyDividerCount=(e.propertyDividerCount or 0)+1
    local i=e.propertyDividerCount;local line=e.propertyDividers[i]
    if not line then line=e.props:CreateTexture(nil,"ARTWORK");line:SetColorTexture(.5,.5,.5,.45);line:SetHeight(1);e.propertyDividers[i]=line end
    line:ClearAllPoints();line:SetPoint("TOPLEFT",e.props,"TOPLEFT",0,-height-8)
    line:SetWidth(e.props:GetWidth());line:Show()
    return height+20
end
local function SetGradientEndState(swatch,label,enabled)
    swatch:SetEnabled(enabled)
    local shade=enabled and 1 or .5
    label:SetTextColor(shade,shade,shade)
    if enabled then swatch.swatch:SetColorTexture(unpack(swatch.color))
    else swatch.swatch:SetColorTexture(.35,.35,.35,1)end
end
local function PositionPropertyControl(entry,parent,y)
    local control=entry[1];control:ClearAllPoints()
    if entry[5] then control:SetPoint(entry[5],entry[4],entry[6] or "RIGHT",entry[2],entry[3])
    elseif entry[4] then control:SetPoint("LEFT",entry[4],"RIGHT",6,0)
    else control:SetPoint("TOPLEFT",parent,"TOPLEFT",entry[2]*(M.editor.propertyRatio or 1),y+entry[3]) end
end
local function CompositePart(group,compound)
    if not IsUnitComposite(group) then return end
    for _,node in ipairs(M.db.design.nodes) do
        if node.compound==compound and M:IsChild(node.id,group.id) then return node end
    end
end
local function CompositeAvatar(group)
    local parts=group and compositeParts[group.compound]
    return parts and CompositePart(group,parts.avatar)
end
local function CompositeBar(group,compound,binding)
    local part=CompositePart(group,compound)
    if not part then return end
    for _,node in ipairs(M.db.design.nodes) do
        if node.parent==part.id and node.kind=="bar" and node.binding==binding then return node end
    end
end
local function HealthStyleBar(group)
    local main=MainBarPart(group)
    local bar=main and M.byID[main.bar]
    if bar and bar.binding=="health" then return bar end
    if IsUnitComposite(group) then return CompositeBar(group,compositeParts[group.compound].hp,"health") end
end
local function ChangeHealthStyle(bar,key,value)
    if not bar or M.byID[bar.id]~=bar or not M:CanEdit() then return false end
    bar.healthColor=bar.healthColor or M.Copy(bar.color or {0,1,.42745101451874,1})
    bar[key]=type(value)=="table" and M.Copy(value) or value
    M:Commit();return true
end
local function ChangeHealthThreshold(bar,key,value)
    if not bar or bar.id~="wa385c615b2a" or M.byID[bar.id]~=bar or not M:CanEdit() then return false end
    bar[key]=type(value)=="table" and M.Copy(value) or value
    M:Commit();return true
end
local function CompositeName(group)
    if not IsUnitComposite(group) then return end
    for _,node in ipairs(M.db.design.nodes) do
        if node.parent==group.id and node.kind=="text" and node.binding=="name" then return node end
    end
end
local function AvatarXRange(group)
    local avatar=CompositeAvatar(group)
    local hp=CompositePart(group,compositeParts[group.compound].hp)
    if not avatar or not hp then return -100,-100 end
    local portraitFrame,healthBar
    for _,node in ipairs(M.db.design.nodes) do
        if node.parent==avatar.id and node.file and node.file:find("CharacterFrame",1,true) then portraitFrame=node end
        if node.parent==hp.id and node.kind=="bar" and node.binding=="health" then healthBar=node end
    end
    if not portraitFrame or not healthBar then return -100,-100 end
    local barLeft=(hp.x or 0)+(hp.scale or 1)*((healthBar.x or 0)-(healthBar.width or 0)/2)
    local avatarLeft=(avatar.scale or 1)*(portraitFrame.scale or 1)*((portraitFrame.x or 0)-(portraitFrame.width or 0)/2)
    return -100,math.max(-100,math.floor(barLeft-avatarLeft+1e-7))
end
local function Change(field,value)
    local n=Selected();if not n or not M:CanEdit() then return end
    if type(value)=="number" then value=M.SettingRanges.Clamp(n,field,value) end
    if (n.compound=="systemMenu" or n.compound=="mouseCircle") and field=="scale" then n.scale=M:ScaleInputValue(n,M.Clamp(value,.1,2))
    elseif (n.compound=="partyFrames" or n.compound=="bossFrames" or n.compound=="cooldownMonitor" or n.compound=="chatButtons" or n.compound=="combatNotices" or n.compound=="experienceBar") and field=="scale" then M:SetCompositeScaleFromCenter(n,value,M:ScaleInputValue(n,M.Clamp(value,.1,2)))
    elseif n.compound=="experienceBar" and field=="experienceHeight" then
        n.experienceHeight=M.Clamp(math.floor(value+.5),1,100);n.height=n.experienceHeight
        if M.byID.experienceBarDisplay then M.byID.experienceBarDisplay.height=n.height end
    elseif n.compound=="cooldownMonitor" and (field=="minCooldown" or field=="maxCooldown") then
        n[field]=M.Clamp(value,0,86400)
        if field=="minCooldown" and n.minCooldown>n.maxCooldown then n.maxCooldown=n.minCooldown end
        if field=="maxCooldown" and n.maxCooldown<n.minCooldown then n.minCooldown=n.maxCooldown end
    elseif field=="fontSize" then M:SetFontDisplaySize(n,value)
    elseif field=="partyNameSize" and n.compound=="partyFrames" then
        n.partyNameSize=value/M:FontDisplayScale(M.byID.party1Name)
    elseif field=="scale" or field=="modelScale" then n[field]=M:ScaleInputValue(n,value,field)
    else n[field]=value end
    M:Commit()
end
local function InPreviewScope(n,scope)
    return scope=="all" or n.scope==scope or
        (scope=="target" and M:IsChild(n.id,"wabc757f81ee"))
end
local function InMainPreview(n)
    local seen={}
    while n and not seen[n.id] do
        if n.id=="mainComposite" or n.treeParent=="mainComposite" then return true end
        seen[n.id]=true;n=M.byID[n.parent]
    end
    return false
end
local function PreviewModuleID(n)
    return M:ModuleID(n)
end
local function MainCompositeRoots()
    local roots={}
    for _,n in ipairs(M.db.design.nodes) do
        if n.treeParent=="mainComposite" then
            local parent=M.byID[n.parent]
            local nested=false
            while parent do
                if parent.treeParent=="mainComposite" then nested=true;break end
                parent=M.byID[parent.parent]
            end
            if not nested then roots[#roots+1]=n end
        end
    end
    return roots
end
local function MainTextElement(n)
    return n and n.kind=="text" and InMainPreview(n)
end
local function MainPreviewSelection(n)
    return n and InMainPreview(n)
end
local function SetSelection(id)
    if M.commitRefreshToken then M:FlushCommit() end
    M.selection=id;M.multi={[id]=true}
    M:RefreshEditor(true)
end

local function UpdatePreviewGrid(e,width,height)
    width,height=math.max(1,width or e.canvas:GetWidth()),math.max(1,height or e.canvas:GetHeight())
    local index=0
    local function Line(vertical,step)
        index=index+1
        local line=e.gridLines[index]
        if not line then
            line=e.gridFrame:CreateTexture(nil,"ARTWORK")
            e.gridLines[index]=line
        end
        line:ClearAllPoints()
        if vertical then line:SetSize(1,height);line:SetPoint("CENTER",e.gridFrame,"CENTER",step*10,0)
        else line:SetSize(width,1);line:SetPoint("CENTER",e.gridFrame,"CENTER",0,step*10) end
        if step==0 then line:SetColorTexture(1,1,1,.1375)
        elseif step%5==0 then line:SetColorTexture(1,1,.5,.1125)
        else line:SetColorTexture(.5,.5,.5,.0875) end
        line:Show()
    end
    for step=-math.ceil(width/20),math.ceil(width/20) do Line(true,step) end
    for step=-math.ceil(height/20),math.ceil(height/20) do Line(false,step) end
    for i=index+1,#e.gridLines do e.gridLines[i]:Hide() end
    e.gridCount=index
end


M.EditorInternals={}
M.EditorInternals.topLevelFrames=topLevelFrames
M.EditorInternals.ModuleAvailable=ModuleAvailable
M.EditorInternals.unlockExcluded=unlockExcluded
M.EditorInternals.moduleGroupBreaks=moduleGroupBreaks
M.EditorInternals.moduleGroupColors=moduleGroupColors
M.EditorInternals.moduleColorPalette=moduleColorPalette
M.EditorInternals.disabledModuleColor=disabledModuleColor
M.EditorInternals.unitChoices=unitChoices
M.EditorInternals.bindingChoices=bindingChoices
M.EditorInternals.pointXY=pointXY
M.EditorInternals.compositeParts=compositeParts
M.EditorInternals.mainBarParts=mainBarParts
M.EditorInternals.mainAuraIcons=mainAuraIcons
M.EditorInternals.MainBarPart=MainBarPart
M.EditorInternals.IsUnitComposite=IsUnitComposite
M.EditorInternals.HasDedicatedPreview=HasDedicatedPreview
M.EditorInternals.IsCastGroup=IsCastGroup
M.EditorInternals.RoundOffset=RoundOffset
M.EditorInternals.SetActualFontControl=SetActualFontControl
M.EditorInternals.targetCastParts=targetCastParts
M.EditorInternals.CastPart=CastPart
M.EditorInternals.FontPreviewPath=FontPreviewPath
M.EditorInternals.FontChoiceName=FontChoiceName
M.EditorInternals.Selected=Selected
M.EditorInternals.propertyCategories=propertyCategories
M.EditorInternals.OrganizePropertyRows=OrganizePropertyRows
M.EditorInternals.PropertyDivider=PropertyDivider
M.EditorInternals.SetGradientEndState=SetGradientEndState
M.EditorInternals.PositionPropertyControl=PositionPropertyControl
M.EditorInternals.CompositePart=CompositePart
M.EditorInternals.CompositeAvatar=CompositeAvatar
M.EditorInternals.CompositeBar=CompositeBar
M.EditorInternals.HealthStyleBar=HealthStyleBar
M.EditorInternals.ChangeHealthStyle=ChangeHealthStyle
M.EditorInternals.ChangeHealthThreshold=ChangeHealthThreshold
M.EditorInternals.CompositeName=CompositeName
M.EditorInternals.AvatarXRange=AvatarXRange
M.EditorInternals.Change=Change
M.EditorInternals.InPreviewScope=InPreviewScope
M.EditorInternals.InMainPreview=InMainPreview
M.EditorInternals.PreviewModuleID=PreviewModuleID
M.EditorInternals.MainCompositeRoots=MainCompositeRoots
M.EditorInternals.MainTextElement=MainTextElement
M.EditorInternals.MainPreviewSelection=MainPreviewSelection
M.EditorInternals.SetSelection=SetSelection
M.EditorInternals.UpdatePreviewGrid=UpdatePreviewGrid
