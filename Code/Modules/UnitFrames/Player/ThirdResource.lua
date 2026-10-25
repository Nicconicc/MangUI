local _,M=...
local C=M.Compat
local P={providers={}};M.ThirdResource=P
local ART=M.ART.."Player\\ThirdResource\\"
local width,height=512/math.sqrt(2),128/math.sqrt(2)
-- A third bar is independent of the unit's primary power and discrete points.
-- Future client/spec implementations register their own power source here.
function P.Register(id,provider)
    provider.id=id;P.providers[id]=provider
end
P.Register("mistsDemonicFury",{class="WARLOCK",spec=266,minimum=50000,maximum=59999,
    powerToken="DemonicFury",powerType=15,previewPower=650,previewMax=1000})
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
            and interface>=provider.minimum and interface<=provider.maximum then return provider end
    end
end
function P.State(view,out)
    local s=out or {};local provider=P.Provider()
    -- An unsupported character can still select and arrange this reusable bar.
    local selected=view.selected and view.byID[view.selected]
    if not provider and view.preview and selected and (selected.id=="playerThirdResource"or selected.thirdResource)then
        provider=P.providers.mistsDemonicFury
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
    s.unit="player";s.exists=true;s.cast=s.cast or {active=false}
    s.power,s.maxPower,s.powerType=value,maximum,powerType
    s.resourceAvailable=provider~=nil and (readableMax==nil or readableMax>0)
    s.powerRatio=readableValue and readableMax and readableMax>0 and M.Clamp(readableValue/readableMax,0,1)or nil
    s.provider=provider and provider.id or nil
    return s
end
local function Node(id,kind,layer)
    return {id=id,label="第三资源条",kind=kind,parent="playerThirdResource",scope="player",unit="player",
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
    local group=Node("playerThirdResource","group",30)
    group.parent=hp.parent;group.treeParent="mainComposite";group.internal=nil
    group.compound="thirdResource";group.thirdResource=nil;group.mirror=nil
    group.width,group.height=2,2
    group.scale=hp.scale or .6;group.scaleReference=hp.scaleReference or group.scale
    group.mainScaleFactor=hp.mainScaleFactor
    -- Rebase the export's (50,-250) leaf origin into the editable group center.
    group.x=(hp.x or -765)+85;group.y=(hp.y or -239)-161
    templates[#templates+1]=group
    local function Add(id,file,layer,color,alpha,blend)
        local n=Node(id,"texture",layer);n.file=ART..file
        n.color=color or n.color;n.alpha=alpha or 1;n.blend=blend or "BLEND"
        templates[#templates+1]=n;return n
    end
    Add("playerThirdResourceShadow","TargetHPShadow",31,nil,.5)
    Add("playerThirdResourceBackground","TargetHPBG",32)
    local bar=Node("playerThirdResourceFill","bar",33)
    bar.file=ART.."TargetHPColor";bar.binding="power";bar.reverse=true
    bar.color={.6196078658103943,.3333333432674408,1,1}
    bar.smooth=true;bar.smoothDuration=.35;bar.alphaFill=true
    bar.fillExtent=1;bar.fillInset=0;bar.materialName="默认"
    templates[#templates+1]=bar
    Add("playerThirdResourceRamp","TargetHPRamp",34,{1,1,1,0})
    Add("playerThirdResourceGlass","TargetHPGlass",35,{1,1,1,.5117184817791},1,"ADD")
    local spark=Node("playerThirdResourceSpark","spark",36)
    spark.file="Interface\\CastingBar\\UI-CastingBar-Spark"
    spark.owner=bar.id;spark.binding="power";spark.followDisplay=true;spark.edgeOnly=true
    spark.width,spark.height=30,40;spark.y=-3;spark.blend="ADD";spark.desaturate=true
    spark.color={.98823535442352,1,1,1};templates[#templates+1]=spark
    Add("playerThirdResourceFrame","TargetHPKuang",37)
    for _,template in ipairs(templates)do
        local existing=index[template.id]
        if not existing then
            design.nodes[#design.nodes+1]=template
        elseif template.thirdResource then
            -- Old imports must not drop the class/spec resource binding.
            existing.thirdResource=true
        end
    end
end
