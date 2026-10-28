local _,M=...
local C,P=M.Compat,M.ThirdResource
local N={};P.Native=N
local unpack=unpack or table.unpack
local layerOrder={playerThirdResourceShadow={"BACKGROUND",-2},playerThirdResourceBackground={"BACKGROUND",-1},
    playerThirdResourceRamp={"OVERLAY",0},playerThirdResourceGlass={"OVERLAY",1},playerThirdResourceFrame={"OVERLAY",2}}
local function Query(fn,...)
    if type(fn)~="function"then return end
    local ok,value=pcall(fn,...);if ok then return value end
end
local function Support(load)
    if not C.retail or C.interface<120000 or not(C_XMLUtil and C_XMLUtil.GetTemplateInfo)then return false end
    if not C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")and load and C_AddOns and C_AddOns.LoadAddOn and not InCombatLockdown()then
        pcall(C_AddOns.LoadAddOn,"Blizzard_AuraContainer")
    end
    return C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")~=nil
end
local function Selected()
    local _,class=UnitClass("player")
    local api=C_SpecializationInfo
    local index=C.Number(Query(GetSpecialization or api and api.GetSpecialization))
    local spec=index and C.Number(Query(GetSpecializationInfo or api and api.GetSpecializationInfo,index))
    local d=M.SpecialBarData
    if class=="EVOKER"and spec==d.ebon.spec then return "ebon",d.ebon.aura,nil,d.ebon.color end
    if class=="MONK"and spec==d.windwalker.spec then return "flurry",d.windwalker.chargeAura,d.windwalker.chargeMaximum,d.windwalker.color end
end
local function Frame(parent,level,anchor)
    local f=CreateFrame("Frame",nil,parent,"DisableUntrustedLayoutScriptsTemplate")
    f:EnableMouse(false);f:SetFrameLevel(level);f:SetAllPoints(anchor);return f
end
local function LayoutFill(q,item)
    local fill=q.view.nodes.playerThirdResourceFill;local n=fill.spec
    local start=M.RendererInternals.FillStart(q.view,n,fill.frame)
    local inset,extent=n.fillInset or 0,n.fillExtent or 1
    local width=math.max(.001,n.width*extent-start)
    if item.start~=start or item.width~=width or item.height~=n.height then
        local anchor=n.reverse and "RIGHT"or"LEFT"
        item.bar:ClearAllPoints();item.bar:SetPoint(anchor,fill.frame,anchor,n.reverse and -inset-start or inset+start,0)
        item.bar:SetSize(width,n.height);item.start,item.width,item.height=start,width,n.height
        local left=n.reverse and(n.width-inset-n.width*extent)/n.width or(inset+start)/n.width
        local right=n.reverse and(n.width-inset-start)/n.width or(inset+n.width*extent)/n.width
        local cx,cy=1+(n.cropX or 0),1+(n.cropY or 0)
        left,right=.5+(left-.5)/cx,.5+(right-.5)/cx
        local top,bottom=.5-.5/cy,.5+.5/cy
        if n.mirror then left,right=right,left end
        if n.mirrorY then top,bottom=bottom,top end
        item.fillTexture:SetTexCoord(left,right,top,bottom)
    end
end
local function ConfigureArt(q,item)
    local view,button=q.view,item.button
    local fill=view.nodes.playerThirdResourceFill;local n=fill.spec
    local I=M.RendererInternals
    if not item.bar then
        button:EnableMouse(false);button:EnableMouseMotion(false);button:SetSize(2,2)
        local bar=CreateFrame("StatusBar",nil,button);item.bar=bar;bar:EnableMouse(false)
        bar:SetFrameLevel(fill.frame:GetFrameLevel());bar:SetClipsChildren(false)
        if bar.SetRenderMode and Enum.StatusBarRenderMode then bar:SetRenderMode(Enum.StatusBarRenderMode.Linear)end
        if bar.SetFillStyle and Enum.StatusBarFillStyle then bar:SetFillStyle(Enum.StatusBarFillStyle.Standard)end
        bar:SetStatusBarTexture(n.file)
        -- All opaque backgrounds and the fill share one frame. Explicit draw
        -- layers prevent a separate background frame from covering the fill.
        item.layers={}
        for _,o in ipairs(view.ordered)do
            local spec=o.spec
            if spec.thirdResource and spec.kind=="texture"then
                local order=layerOrder[spec.id]or{"OVERLAY",0}
                local texture=bar:CreateTexture(nil,order[1],nil,order[2]);texture:SetAllPoints(o.frame)
                item.layers[spec.id]={texture=texture}
            end
        end
        -- Cache the display texture before handing this bar to the native aura
        -- button. Do not query bound objects or draw through a transparent driver.
        item.fillTexture=bar:GetStatusBarTexture()
        item.fillTexture:SetDrawLayer("ARTWORK",0)
        local value=view.nodes.playerThirdResourceValue
        item.textFrame=Frame(button,value.frame:GetFrameLevel(),value.frame)
        item.text=item.textFrame:CreateFontString(nil,"OVERLAY");item.text:SetAllPoints()
        local spark=view.nodes.playerThirdResourceSpark
        item.sparkFrame=CreateFrame("Frame",nil,button,"DisableUntrustedLayoutScriptsTemplate")
        item.sparkFrame:EnableMouse(false);item.sparkFrame:SetFrameLevel(spark.frame:GetFrameLevel())
        item.spark=item.sparkFrame:CreateTexture(nil,"OVERLAY");item.spark:SetAllPoints()
    end
    for id,layer in pairs(item.layers)do
        local o=view.nodes[id];local s=o.spec
        layer.texture:SetAllPoints(o.frame);layer.texture:SetAlpha(s.alpha or 1)
        layer.texture:SetTexture(s.file);layer.texture:SetBlendMode(s.blend or "BLEND")
        layer.texture:SetVertexColor(unpack(s.color or {1,1,1,1}));I.TextureCoords(layer.texture,s)
    end
    -- The engine owns the value; the public geometry still uses the same
    -- TokenFrame contact point and full-canvas crop as every main strip.
    local material=n.materialPath and n.materialPath~=n.file and n.materialPath~="Interface\\Buttons\\WHITE8X8"and n.materialPath
    item.fillTexture:SetTexture(material or n.file);item.fillTexture:SetBlendMode(n.blend or "BLEND")
    item.fillTexture:SetAlpha(1);item.bar:SetStatusBarColor(unpack(q.color))
    -- The default artwork already carries its own irregular alpha. Do not mask
    -- it a second time. Only rectangular custom materials need a shape mask.
    if material then
        if not item.mask then
            item.mask=item.bar:CreateMaskTexture();item.mask:SetAllPoints(fill.frame)
            item.fillTexture:AddMaskTexture(item.mask)
        end
        item.mask:SetAllPoints(fill.frame);item.mask:SetTexture(n.file,"CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
        I.TextureCoords(item.mask,n);item.mask:Show()
    elseif item.mask then
        item.fillTexture:RemoveMaskTexture(item.mask);item.mask=nil
    end
    item.start=nil;LayoutFill(q,item);item.bar:SetReverseFill(n.reverse==true)
    local v=view.nodes.playerThirdResourceValue.spec
    item.text:SetFont(I.Font(v),v.fontSize or 40,v.outline=="None"and""or(v.outline or "OUTLINE"))
    item.text:SetTextColor(unpack(v.color or {1,1,1,1}));item.text:SetJustifyH(v.justify or "RIGHT")
    item.text:SetShadowColor(0,0,0,1);item.text:SetShadowOffset(v.shadowX or 3,v.shadowY or -3)
    local s=view.nodes.playerThirdResourceSpark.spec
    item.sparkFrame:SetSize(s.width,s.height);item.sparkFrame:ClearAllPoints()
    item.sparkFrame:SetPoint("CENTER",item.fillTexture,n.reverse and "LEFT"or"RIGHT",s.x or 0,s.y or 0)
    item.sparkFrame:SetAlpha(s.alpha or 1)
    item.spark:SetTexture(s.file);item.spark:SetBlendMode(s.blend or "ADD");item.spark:SetVertexColor(unpack(s.color))
    button:ClearApplicationBar();button:ClearApplicationCount();button:ClearDurationBar();button:ClearDurationText()
    if q.kind=="flurry"then
        if not N.countFormatter and C_StringUtil and C_StringUtil.CreateNumericRuleFormatter then
            N.countFormatter=C_StringUtil.CreateNumericRuleFormatter()
            N.countFormatter:SetBreakpoints({{threshold=0,step=1,format="%.0f"}})
        end
        button:SetApplicationBar(item.bar,{minApplications=0,maxApplications=q.maximum})
        button:SetApplicationCount(item.text,N.countFormatter and {formatter=N.countFormatter}or{})
    else
        button:SetDurationBar(item.bar,{direction=Enum.StatusBarTimerDirection.RemainingTime})
        if not N.formatter and C_StringUtil and C_StringUtil.CreateNumericRuleFormatter then
            N.formatter=C_StringUtil.CreateNumericRuleFormatter()
            N.formatter:SetBreakpoints({{threshold=0,step=.1,format="%.1f"}})
        end
        button:SetDurationText(item.text,N.formatter and {textFormatter=N.formatter}or{})
    end
end
function N.Configure(view)
    if not view or view.preview or InCombatLockdown()then return end
    local kind,id,maximum,color=Selected()
    view.nativeThirdSelection={kind=kind,time=GetTime(),generation=view.nativeThirdSelectionGeneration}
    local q=view.nativeThird
    if not kind or not Support(true)then
        if q then q.enabled=false;q.kind=kind;q.container:SetEnabled(false)end
        return
    end
    local group=view.nodes.playerThirdResource
    if not group then return end
    if not q then
        q={view=view,items={}};view.nativeThird=q
        q.container=CreateFrame("AuraContainer",nil,group.frame,"CustomAuraContainerTemplate")
        q.container:SetUnit("player");q.container:SetEnabled(false)
        q.container:SetPoint("CENTER",group.frame,"CENTER",0,0)
        q.container:SetFlowLayoutAnchorPoint("TOPLEFT")
        q.container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right,AnchorUtil.FlowDirection.Down)
        q.container:SetFlowLayoutMaximumLineSize(2)
        q.kind,q.spellID,q.maximum,q.color=kind,id,maximum,color
        q.container:AddAuraGroup("resource","HELPFUL|PLAYER",{maxFrameCount=0,initializeFrame=function(button)
            local item={button=button};q.items[#q.items+1]=item;ConfigureArt(q,item)
        end})
        q.container:SetAuraGroupLayout("resource",{elementSpacing=0,lineSpacing=0,elementWidth=2,elementHeight=2})
    end
    q.container:SetEnabled(false)
    q.kind,q.spellID,q.maximum,q.color=kind,id,maximum,color
    q.container:SetAuraGroupCandidateFilters("resource",{includeSpellIDs={[id]=true},isFromPlayerOrPlayerPet=true})
    q.container:SetAuraGroupMaxFrameCount("resource",1)
    for _,item in ipairs(q.items)do ConfigureArt(q,item)end
    q.enabled=group.spec.enabled~=false and(not group.module or group.module.enabled~=false)
    q.container:SetEnabled(q.enabled);q.sparkAt=nil
end
function N.Paint(view,o)
    if view.preview then return false end
    local now=GetTime();local selection=view.nativeThirdSelection
    if not selection or selection.time~=now or selection.generation~=view.nativeThirdSelectionGeneration then
        selection={kind=Selected(),time=now,generation=view.nativeThirdSelectionGeneration};view.nativeThirdSelection=selection
    end
    local kind=selection.kind;local q=view.nativeThird
    if not InCombatLockdown()and((q and q.kind~=kind)or(not q and kind and Support(false)))then N.Configure(view);q=view.nativeThird end
    if not(q and q.enabled and q.kind==kind)then return false end
    -- Do not query an aura, inspect native visibility, read duration/count text,
    -- or infer a restricted value. The native group owns presence and bindings.
    if o.frame:IsShown()then o.frame:Hide()end
    return true
end
function N.Animate(view)
    local q=view.nativeThird
    if view.preview or not(q and q.enabled)then return end
    -- Entry animations move the public TokenFrame after ordinary node paints.
    -- Recompute its contact band afterwards, without inspecting aura geometry.
    for _,item in ipairs(q.items)do
        LayoutFill(q,item)
    end
end
