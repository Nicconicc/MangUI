local _,M=...
local C=M.Compat
local P={providers={}};M.ThirdResource=P
local ART=M.ART.."Target\\Health\\"
local width,height=512/math.sqrt(2),128/math.sqrt(2)
local furyColor={.6196078658103943,.3333333432674408,1,1}
-- Share the actual target health layers, not an independent copy of the art.
-- Their canvas-side origin remains consistent after target texture revisions.
local targetLayers={
    TargetHPShadow={"wa1882259c81","Target_HP_shadow_TargetHPShadow"},
    TargetHPBG={"wa385c615b2abg","Target_HP_bar_TargetHPBG"},
    TargetHPColor={"wa385c615b2a","Target_HP_bar_TargetHPColor"},
    TargetHPRamp={"wa8ba303231f","Target_HP_ramp_TargetHPRamp"},
    TargetHPGlass={"wa6d7e5b3bf4","Target_HP_glass_TargetHPGlass"},
    TargetHPKuang={"waae10175c53","Target_HP_frame_TargetHPKuang"},
}
local function TargetArt(index,node,name)
    local route=targetLayers[name];local source=index[route[1]]
    node.file=source and M:TexturePath(source,source.file)or ART..route[2]
    node.cropX=source and source.cropX or 0;node.cropY=source and source.cropY or 0
    node.mirror=not(source and source.mirror==true);node.mirrorY=source and source.mirrorY==true or false
    return source
end
-- A third bar is independent of the unit's primary power and discrete points.
-- Future client/spec implementations register their own power source here.
function P.Register(id,provider)
    provider.id=id;P.providers[id]=provider
end
P.Register("mistsDemonicFury",{class="WARLOCK",spec=266,minimum=50000,maximum=59999,
    powerToken="DemonicFury",powerType=15,previewPower=650,previewMax=1000,color=furyColor})
local function Query(fn,fallback,...)
    if type(fn)~="function"then return fallback end
    local ok,value=pcall(fn,...)
    if not ok or C.Readable(value)and type(value)~="number"then return fallback end
    return value
end
function P.Provider()
    local _,class=UnitClass("player")
    local api=C_SpecializationInfo
    local index=Query(GetSpecialization or api and api.GetSpecialization,nil)
    local spec=index and Query(GetSpecializationInfo or api and api.GetSpecializationInfo,nil,index)
    local interface=C.interface or 0
    for _,provider in pairs(P.providers)do
        if class==provider.class and spec==provider.spec
            and interface>=provider.minimum and interface<=provider.maximum
            and(not provider.retail or C.retail)
            and(not provider.available or provider.available())then return provider end
    end
end
function P.State(view,out)
    local s=out or {};local provider=P.Provider()
    s.thirdTimer=nil;s.thirdExpires=nil;s.thirdTotal=nil;s.thirdValueKind=nil;s.thirdCustom=nil;s.thirdTimeAt=nil
    s.showThirdValue=false;s.provider=provider and provider.id or nil
    s.unit="player";s.exists=true;s.cast=s.cast or {active=false}
    s.powerColor=provider and provider.color or furyColor
    if provider and provider.state then
        s.power,s.maxPower,s.powerType,s.powerRatio=0,1,0,nil;s.resourceAvailable=true
        s.thirdCustom=true;provider.state(view,s)
        P.Refresh(s,view.preview)
        return s
    end
    local value,maximum,powerType=0,0,15
    if provider then
        powerType=Enum and Enum.PowerType and Enum.PowerType[provider.powerToken]or provider.powerType
        if view.preview then value,maximum=provider.previewPower,provider.previewMax
        else
            value=Query(UnitPower,0,"player",powerType)
            maximum=Query(UnitPowerMax,0,"player",powerType)
        end
    end
    local readableValue,readableMax=C.Number(value),C.Number(maximum)
    s.power,s.maxPower,s.powerType=value,maximum,powerType
    s.powerColor=provider and provider.color or furyColor
    s.resourceAvailable=provider~=nil and (readableMax==nil or readableMax>0)
    s.powerRatio=readableValue and readableMax and readableMax>0 and M.Clamp(readableValue/readableMax,0,1)or nil
    s.provider=provider and provider.id or nil
    return s
end
local function Node(id,kind,layer)
    return {id=id,label="玩家第三资源条",kind=kind,parent="playerThirdResource",scope="player",unit="player",
        enabled=true,internal=true,thirdResource=true,x=0,y=0,width=width,height=height,
        point="CENTER",anchor="CENTER",scale=1,scaleReference=1,modelScaleReference=1,
        alpha=1,binding="static",blend="BLEND",color={1,1,1,1},mirror=true,
        layer=layer,rules={},conditions={}}
end
function M:EnsureThirdResource(design)
    if type(design)~="table"or type(design.nodes)~="table"then return end
    local index={};for _,n in ipairs(design.nodes)do index[n.id]=n end
    local hp=index.wa70b7aa5607
    if not hp then return end
    local templates={}
    -- Keep the entire strip, including the fill's child frames, below the
    -- first player health layer. Glass/ramp/spark share a level in draw order.
    local hpBack=math.huge
    for _,n in ipairs(design.nodes)do
        if n.parent==hp.id and n.kind~="hitbox"then hpBack=math.min(hpBack,n.layer or 11)end
    end
    local top=hpBack<math.huge and hpBack-1 or 10
    local group=Node("playerThirdResource","group",top-4)
    group.parent=hp.parent;group.treeParent="mainComposite";group.internal=nil
    group.compound="thirdResource";group.thirdResource=nil;group.mirror=nil
    group.width,group.height=2,2
    group.scale=hp.scale or .6;group.scaleReference=hp.scaleReference or group.scale
    group.mainScaleFactor=hp.mainScaleFactor
    group.x=-620;group.y=-430;group.thirdResourceLayoutRevision=1
    templates[#templates+1]=group
    local function Add(id,file,layer,color,alpha,blend)
        local n=Node(id,"texture",layer);TargetArt(index,n,file)
        n.color=color or n.color;n.alpha=alpha or 1;n.blend=blend or "BLEND"
        templates[#templates+1]=n;return n
    end
    Add("playerThirdResourceShadow","TargetHPShadow",top-3,nil,.5)
    Add("playerThirdResourceBackground","TargetHPBG",top-3)
    local bar=Node("playerThirdResourceFill","bar",top-2)
    local targetBar=TargetArt(index,bar,"TargetHPColor");bar.binding="power";bar.reverse=true
    bar.color=M.Copy(furyColor);bar.powerColor=true
    bar.smooth=true;bar.smoothDuration=.35;bar.alphaFill=true
    bar.fillExtent=targetBar and targetBar.fillExtent or 483/512
    bar.fillInset=targetBar and (targetBar.fillInset or 0)*width/(targetBar.width or 512)or 0
    bar.materialName="默认"
    templates[#templates+1]=bar
    Add("playerThirdResourceRamp","TargetHPRamp",top-1,{1,1,1,0})
    Add("playerThirdResourceGlass","TargetHPGlass",top-1,{1,1,1,.5117184817791},1,"ADD")
    local spark=Node("playerThirdResourceSpark","spark",top-1)
    spark.file="Interface\\CastingBar\\UI-CastingBar-Spark"
    spark.owner=bar.id;spark.binding="power";spark.followDisplay=true;spark.edgeOnly=true
    spark.width,spark.height=30,40;spark.y=-3;spark.blend="ADD";spark.desaturate=true
    spark.color={.98823535442352,1,1,1};templates[#templates+1]=spark
    Add("playerThirdResourceFrame","TargetHPKuang",top)
    local value=Node("playerThirdResourceValue","text",top)
    value.parent=bar.id;value.thirdResourceValue=true;value.binding="thirdResourceValue"
    value.width,value.height=200,60;value.x,value.y=-8,0
    value.point,value.anchor="RIGHT","LEFT";value.font,value.fontSize="Myriad",40
    value.outline,value.justify="OUTLINE","RIGHT";value.shadowX,value.shadowY=3,-3
    value.mirror=nil;templates[#templates+1]=value
    for _,template in ipairs(templates)do
        local existing=index[template.id]
        if not existing then
            design.nodes[#design.nodes+1]=template
        else
            existing.layer=template.layer;existing.enabled=true
            if existing.id==group.id then existing.label=group.label end
            if template.thirdResource then existing.thirdResource=true end
            if template.thirdResourceValue then existing.thirdResourceValue=true;existing.binding=template.binding end
            if template.kind=="texture"or template.kind=="bar"then
                existing.file=template.file
                existing.cropX,existing.cropY=template.cropX,template.cropY
                existing.mirror,existing.mirrorY=template.mirror,template.mirrorY
            end
            if existing.id==group.id and existing.thirdResourceLayoutRevision~=1 then
                -- Replace the shipped old position; retain a customized X.
                local oldX=(hp.x or -765)+85
                if not existing.x or math.abs(existing.x-oldX)<.001 then existing.x=group.x end
                existing.y=group.y;existing.thirdResourceLayoutRevision=1
            elseif existing.id==bar.id then
                existing.color=M.Copy(furyColor);existing.powerColor=true
                existing.fillExtent,existing.fillInset=bar.fillExtent,bar.fillInset
            end
        end
    end
end
