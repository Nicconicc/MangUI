local _,M=...
local C,B,R=M.Compat,M.MainBarLayout,M.Renderer
local unpack=unpack or table.unpack
local private=M.RendererInternals
local points=private.points
local ResourceModelLoaded=private.ResourceModelLoaded
local ResourceModelRestart=private.ResourceModelRestart
local FocusPortraitOnlyHidden=private.FocusPortraitOnlyHidden
local entrySpecs=private.entrySpecs
local EntryParent=private.EntryParent
local Font=private.Font
local TextureCoords=private.TextureCoords
local ResetParticle=private.ResetParticle
local PrepareVisual=private.PrepareVisual
local IndexUpdates=private.IndexUpdates

local portraitAnchorNames={
    wa0b0b0540c7="MangUIMainPortraitAnchor",
    pet_waf8bf4ab582="MangUIPetPortraitAnchor",
    tot_pet_waf8bf4ab582="MangUITargetTargetPortraitAnchor",
    waf8bf4ab582="MangUIFocusPortraitAnchor",
    bossPortrait="MangUIBossPortraitAnchor",
}
for i=0,4 do portraitAnchorNames["party"..i.."Portrait"]="MangUIParty"..i.."PortraitAnchor" end
local function ConfigurePortraitAnchor(view,o)
    local name=not view.preview and portraitAnchorNames[o.spec.id]
    if not name then return end
    local isolated=name=="MangUIMainPortraitAnchor"
    if isolated and InCombatLockdown() then view.mainAnchorPending=true;return end
    local anchor=o.portraitAnchor or _G[name]
    if not anchor then
        anchor=CreateFrame("Frame",name,isolated and UIParent or o.frame:GetParent(),isolated and "SecureHandlerStateTemplate" or nil)
        anchor:EnableMouse(false)
    end
    o.portraitAnchor=anchor
    if isolated then
        -- WA may put secure buttons below this public anchor. Do not parent or
        -- anchor it to our portrait/entry frames: protection follows those links.
        local g=M:Geometry(view.byID,{o.spec.id})[o.spec.id]
        if not g then return end
        local x,y=view.root:GetCenter()
        if not C.Readable(x) or not C.Readable(y) or x==nil or y==nil then return end
        local scale=g.s*view.root:GetEffectiveScale()/UIParent:GetEffectiveScale()
        if anchor:GetParent()~=UIParent then anchor:SetParent(UIParent) end
        anchor:SetScale(scale);anchor:SetSize(g.w,g.h)
        anchor:ClearAllPoints();anchor:SetPoint("CENTER",UIParent,"BOTTOMLEFT",(x+g.x)/g.s,(y+g.y)/g.s)
        local enabled=true;local node=view.byID[o.spec.parent]
        for _=1,100 do
            if not node then break end
            if node.enabled==false then enabled=false;break end
            node=view.byID[node.parent]
        end
        local condition=not enabled and "hide" or (M.db.hideWithoutTarget and "[@target,exists] show; hide" or "show")
        if anchor.manguiVisibility~=condition then
            RegisterStateDriver(anchor,"visibility",condition);anchor.manguiVisibility=condition
        end
        view.mainAnchorPending=nil
        return
    end
    -- A sibling keeps the anchor available when player/target, death or Logo
    -- replaces the portrait. Its bounds and scale still follow the portrait.
    if anchor:GetParent()~=o.frame:GetParent() then anchor:SetParent(o.frame:GetParent()) end
    anchor:ClearAllPoints();anchor:SetAllPoints(o.frame);anchor:Show()
end
function R.SyncMainPortraitAnchor(view)
    if view.mainAnchorPending and not InCombatLockdown() then
        local o=view.nodes.wa0b0b0540c7
        if o and not o.removed then ConfigurePortraitAnchor(view,o) else view.mainAnchorPending=nil end
    end
end

-- Preview parents may be raised or assigned inherited levels as their window
-- first appears. Restore layers after that show cycle as well as after edits.
local function PreviewFrameMatches(frame,level,strata)
    return frame:GetFrameLevel()==level and (not strata or not frame.GetFrameStrata or frame:GetFrameStrata()==strata)
end
function R.SyncPreviewLayers(view,force)
    if not view.preview or not view.design or (view.applying and not force) then return end
    local base=view.root:GetFrameLevel()
    local strata=view.root.GetFrameStrata and view.root:GetFrameStrata()
    local now=GetTime()
    if not force and not view.previewLayersPending and view.previewLayerBase==base
        and view.previewLayerStrata==strata then
        if now<(view.nextPreviewLayerCheck or 0) then return end
        view.nextPreviewLayerCheck=now+.25
        local changed=false
        for _,o in ipairs(view.ordered) do
            if o.frame:IsVisible() then
                local level=base+math.max(1,math.floor(o.spec.layer or 1))
                if not PreviewFrameMatches(o.frame,level,strata) or (o.bar and not PreviewFrameMatches(o.bar,level+1,strata))
                    or (o.clip and not PreviewFrameMatches(o.clip,level+1,strata))
                    or (o.portraitViewport and not PreviewFrameMatches(o.portraitViewport,level,strata))
                    or (o.portraitModel and not PreviewFrameMatches(o.portraitModel,level,strata)) then changed=true;break end
            end
        end
        if not changed then return end
    end
    local order,depths={},{}
    local function Depth(frame)
        if not frame or frame==view.root then return 0 end
        if depths[frame] then return depths[frame] end
        local depth=1;local parent=frame:GetParent()
        while parent and parent~=view.root and depth<100 do
            depth=depth+1;parent=parent:GetParent()
        end
        depths[frame]=depth;return depth
    end
    for i,o in ipairs(view.ordered) do order[i]={node=o,depth=Depth(o.frame),index=i} end
    table.sort(order,function(a,b)
        if a.depth==b.depth then return a.index<b.index end
        return a.depth<b.depth
    end)
    -- Saved node order need not follow the physical hierarchy. Finish every
    -- parent before its descendants, including entry-animation containers.
    for _,item in ipairs(order) do
        local o=item.node;local f=o.frame
        local level=base+math.max(1,math.floor(o.spec.layer or 1))
        if strata and f:GetFrameStrata()~=strata then f:SetFrameStrata(strata) end
        if f:GetFrameLevel()~=level then f:SetFrameLevel(level) end
        -- Bar fills live on child frames, outside the saved node list. Their
        -- levels must follow the owning bar rather than a startup inheritance.
        for _,child in ipairs({o.bar,o.clip}) do
            if strata and child.GetFrameStrata and child:GetFrameStrata()~=strata then child:SetFrameStrata(strata) end
            if child:GetFrameLevel()~=level+1 then child:SetFrameLevel(level+1) end
        end
        if o.portraitViewport and o.portraitViewport:GetFrameLevel()~=level then
            o.portraitViewport:SetFrameLevel(level)
        end
        if o.portraitModel then
            if strata and o.portraitModel:GetFrameStrata()~=strata then o.portraitModel:SetFrameStrata(strata) end
            if o.portraitModel:GetFrameLevel()~=level then o.portraitModel:SetFrameLevel(level) end
        end
    end
    view.previewLayerBase=base;view.previewLayerStrata=strata;view.previewLayersPending=nil
    view.nextPreviewLayerCheck=now+.25
end

function R.New(parent,preview)
    local root=CreateFrame("Frame",nil,parent);root:SetSize(2,2);root:SetPoint("CENTER")
    root:SetFrameLevel(parent:GetFrameLevel()+2)
    local view={root=root,preview=preview,nodes={},ordered={},scene="normal",cache={},stateBuffers={}}
    if preview then
        root:HookScript("OnShow",function()view.previewLayersPending=true end)
        root:HookScript("OnUpdate",function()
            if view.previewSetupPending and view.design and not view.applying then
                view.previewSetupPending=nil
                -- The first Apply allocates and reparents the entire tree. Do
                -- one complete configuration with the final hierarchy and the
                -- editor's fitted viewport, as an ordinary property edit does.
                for _,o in ipairs(view.ordered) do o.specRevision=nil end
                R.Apply(view,view.design,true)
            end
            R.SyncPreviewLayers(view)
        end)
    end
    return view
end
local function NativeModelPose(o)
    local n=o.spec
    if n.modelAPI and o.model.SetTransform and CreateVector3D then
        o.model:SetTransform(CreateVector3D(n.modelX or 0,n.modelY or 0,n.modelZ or 0),CreateVector3D(math.rad(n.pitch or 0),math.rad(n.roll or 0),math.rad(n.facing or 0)),-(n.modelScale or .1))
    else
        o.model:SetModelScale(n.modelScale or 1);o.model:SetPosition(n.oldModelX or 0,n.oldModelY or 0,n.oldModelZ or 0);o.model:SetFacing(math.rad(n.facing or 0))
    end
end
function R.SuppressMovementModel(view,model)
    local hidden=view.movementModelsHidden==true
    if hidden and not model.movementSuppressed then
        model.movementAlpha=model:GetAlpha();model.movementWasShown=model:IsShown()
        model.movementSuppressed=true
        model:SetAlpha(0);model:Hide();model:ClearModel()
    elseif not hidden and model.movementSuppressed then
        model.movementSuppressed=nil
        model:SetAlpha(model.movementAlpha or 1);model.movementAlpha=nil
    end
end
function R.SetMovementModelsHidden(view,hidden)
    if not view or view.preview or view.movementModelsHidden==(hidden==true) then return end
    -- Native model rendering does not reliably follow an ancestor's fade.
    -- Unload live models while movement previews supply their replacements.
    view.movementModelsHidden=hidden==true
    for _,o in pairs(view.nodes) do
        if o.portraitModel then
            R.SuppressMovementModel(view,o.portraitModel)
            if not hidden then o.portraitModel.portraitDirty=true end
        end
        if o.model then
            R.SuppressMovementModel(view,o.model)
            o.loadedModel=nil
            if not hidden then
                o.model:SetModel(tonumber(o.spec.model) or 165577)
                o.loadedModel=tonumber(o.spec.model) or 165577
                NativeModelPose(o);o.model:SetAlpha(o.spec.modelAlpha or 1)
                o.model:SetShown(o.model.movementWasShown~=false)
            end
        end
        for _,slot in ipairs(o.resourceSlots or {}) do
            for j,model in ipairs(slot.models) do
                R.SuppressMovementModel(view,model)
                if not hidden and model.resourceFile then slot.modelReady[j]=ResourceModelRestart(model) end
            end
        end
    end
    if not hidden then R.Update(view) end
end
function R.Position(view,f,n,parent)
    local point=points[n.point] and n.point or "CENTER"
    local x,y=M:NodePosition(n,view.byID)
    local moveX,moveY=M:MainModuleOffset(n,view.byID)
    if moveX~=0 or moveY~=0 then
        local scale=f:GetEffectiveScale()/math.max(.001,view.root:GetEffectiveScale())
        x=x+moveX/scale;y=y+moveY/scale
    end
    f:ClearAllPoints()
    if points[n.screenAnchor] then
        if view.preview then
            local vectors={CENTER={0,0},BOTTOMLEFT={-1,-1},BOTTOMRIGHT={1,-1},TOPLEFT={-1,1},TOPRIGHT={1,1},LEFT={-1,0},RIGHT={1,0},TOP={0,1},BOTTOM={0,-1}}
            local a=vectors[n.screenAnchor];local scale=M.Clamp(M:NodeScale(n),.05,10)
            f:SetPoint(point,parent,"CENTER",x+a[1]*UIParent:GetWidth()/2/scale,y+a[2]*UIParent:GetHeight()/2/scale)
        else f:SetPoint(point,UIParent,n.screenAnchor,x,y) end
    else f:SetPoint(point,parent,points[n.anchor] and n.anchor or "CENTER",x,y) end
end
local function Build(view,n)
    local f
    if n.kind=="hitbox" and not view.preview then
        f=CreateFrame("Button",nil,view.root,"SecureUnitButtonTemplate")
        C.Menu(f,n.unit)
        if n.unit=="player" and n.partyIndex==nil then M.playerButton=f end
    else f=CreateFrame("Frame",nil,view.root); f:EnableMouse(false) end
    local o={frame=f,spec=n}; view.nodes[n.id]=o
    if n.kind=="text" then
        o.shadow=f:CreateFontString(nil,"ARTWORK")
        o.shadow:SetPoint("TOPLEFT",f,"TOPLEFT",6,-6)
        o.shadow:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",6,-6)
        o.text=f:CreateFontString(nil,"OVERLAY");o.text:SetAllPoints()
        if not view.preview then
            f:HookScript("OnShow",function()
                if not o.removed then o.fontNeedsSettle=true;view.fontRefreshPending=true end
            end)
        end
    elseif n.kind=="bar" then
        o.bar=CreateFrame("StatusBar",nil,f);o.bar:SetAllPoints();o.bar:EnableMouse(false)
        o.clip=CreateFrame("Frame",nil,f);o.clip:SetClipsChildren(true);o.clip:EnableMouse(false)
        o.fill=o.clip:CreateTexture(nil,"ARTWORK")
    elseif n.kind=="model" then
        o.model=CreateFrame("PlayerModel",nil,f);o.model:SetAllPoints();o.model:EnableMouse(false)
    elseif n.kind=="auras" then o.icons={}
    elseif n.kind=="chatbuttons" then M.ChatButtons.Build(view,o)
    elseif n.kind=="systemmenu" then M.SystemMenu.Build(view,o)
    elseif n.kind=="mousecircle" then M.MouseCircle.Build(view,o)
    elseif n.kind=="experiencebar" then M.ExperienceBar.Build(view,o)
    elseif n.kind=="targetthreat" then M.TargetThreat.Build(view,o)
    elseif n.kind=="targetdistance" then M.TargetDistance.Build(view,o)
    elseif n.kind=="targetdistancenumber" then M.TargetDistance.BuildNumber(view,o)
    elseif n.kind=="raidbuffs"then o.buffIcons={}
    elseif n.kind=="receivedbuffs"then o.buffIcons={}
    elseif n.kind=="raidvulnerability"then o.buffIcons={}
    elseif n.kind=="commonitems"then o.itemIcons={}
    elseif n.kind=="othermonitor" then o.otherIcons={}
    elseif n.kind=="skillmonitor" then o.skillIcons={}
    elseif n.kind=="cooldowns" then
        o.cooldownIcons={}
        f:SetScript("OnHide",function()M.CooldownMonitor.Reset(o)end)
    elseif n.kind=="resources" then
        o.resourceSlots={}
        for i=1,6 do
            local slot=CreateFrame("Frame",nil,f);slot:SetSize(50,50);slot:EnableMouse(false)
            slot.visual=CreateFrame("Frame",nil,slot);slot.visual:SetSize(50,50);slot.visual:SetPoint("CENTER")
            slot.visual:EnableMouse(false)
            slot.base=slot.visual:CreateTexture(nil,"ARTWORK");slot.base:SetSize(50,50)
            slot.base:SetPoint("CENTER",0,-5)
            slot.base:SetTexture(M:TexturePath(n,M.ART.."Frame_Bar","resourceBase"..i),"CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
            -- Match WA's 45-degree texture rotation, which uses UV coordinates.
            slot.base:SetTexCoord(.5,-.5,-.5,.5,1.5,.5,.5,1.5)
            slot.base:SetAlpha(.8)
            slot.models={};slot.modelReady={}
            for j=1,2 do
                local model=CreateFrame("PlayerModel",nil,slot.visual);model:SetPoint("CENTER")
                model:EnableMouse(false)
                if model.SetPortraitZoom then model:SetPortraitZoom(0) end
                if model.SetKeepModelOnHide then model:SetKeepModelOnHide(false) end
                model:SetScript("OnModelLoaded",ResourceModelLoaded)
                model:SetScript("OnShow",ResourceModelRestart)
                model:Hide();slot.models[j]=model
            end
            slot.artFrame=CreateFrame("Frame",nil,slot.visual)
            slot.artFrame:SetSize(40,40);slot.artFrame:SetPoint("CENTER")
            slot.artFrame:EnableMouse(false)
            slot.art=slot.artFrame:CreateTexture(nil,"ARTWORK");slot.art:SetSize(40,40)
            slot.art:SetPoint("CENTER")
            slot.cooldown=CreateFrame("StatusBar",nil,slot)
            slot.cooldown:SetSize(44,4);slot.cooldown:SetPoint("BOTTOM",0,-8)
            slot.cooldown:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
            slot.cooldown:SetMinMaxValues(0,1);slot.cooldown:Hide()
            o.resourceSlots[i]=slot
        end
    elseif n.kind=="border" or n.kind=="glow" then
        o.edges={}
        for i=1,4 do o.edges[i]=f:CreateTexture(nil,"OVERLAY");o.edges[i]:SetColorTexture(1,1,1) end
    elseif n.kind~="group" and n.kind~="hitbox" then
        if n.castFill or (n.attackKind and not n.attackFrame) then
            o.castInterior=f:CreateTexture(nil,"BACKGROUND")
            o.castInterior:SetTexture("Interface\\Buttons\\WHITE8X8")
            o.castInterior:SetHeight(7)
        end
        o.texture=f:CreateTexture(nil,"ARTWORK");o.texture:SetAllPoints()
    end
    return o
end
local function Border(o,n)
    local e=o.edges;local w=n.kind=="glow" and 3 or 1
    for _,t in ipairs(e) do t:ClearAllPoints();t:SetVertexColor(unpack(n.color or {1,1,1,1})) end
    e[1]:SetPoint("TOPLEFT");e[1]:SetPoint("TOPRIGHT");e[1]:SetHeight(w)
    e[2]:SetPoint("BOTTOMLEFT");e[2]:SetPoint("BOTTOMRIGHT");e[2]:SetHeight(w)
    e[3]:SetPoint("TOPLEFT");e[3]:SetPoint("BOTTOMLEFT");e[3]:SetWidth(w)
    e[4]:SetPoint("TOPRIGHT");e[4]:SetPoint("BOTTOMRIGHT");e[4]:SetWidth(w)
end
local function EnsureFocusMenu(view,active)
    if view.preview then return end
    local group=active.focusComposite and view.nodes.focusComposite
    if not group or group.spec.enabled==false then
        if view.focusMenu and view.focusMenuRegistered then
            UnregisterUnitWatch(view.focusMenu);view.focusMenuRegistered=false;view.focusMenu:Hide()
        end
        return
    end
    if not view.focusMenu then
        local button=CreateFrame("Button",nil,group.frame,"SecureUnitButtonTemplate")
        button:SetFrameLevel(view.root:GetFrameLevel()+400)
        C.Menu(button,"focus")
        view.focusMenu=button
    elseif view.focusMenu:GetParent()~=group.frame then view.focusMenu:SetParent(group.frame) end
    if not view.focusMenuRegistered then RegisterUnitWatch(view.focusMenu);view.focusMenuRegistered=true end
end
-- Rebuild glyph runs when reapplying a face, even if the text did not change.
-- A failed startup load keeps the chosen face and can recover after login.
local function ApplyTextFont(view,o,force)
    local n=o.spec
    local outline=n.outline or "OUTLINE";if outline=="None" then outline="" end
    local size=math.max(.1,n.fontSize or 20)
    local font=Font(n)
    local applied=o.appliedFont
    if not force and applied and not o.fontFailed and applied.path==font
        and applied.size==size and applied.outline==outline and applied.justify==(n.justify or "CENTER") then return end
    local failed=false
    for _,label in ipairs({o.shadow,o.text}) do
        if not M:ApplyRegionFont(label,font,size,outline,force)then failed=true end
        label:SetText("")
        label:SetJustifyH(n.justify or "CENTER")
        label:SetShadowColor(0,0,0,0);label:SetWordWrap(false)
    end
    o.textWidthDirty=true
    if o.renderCache then o.renderCache.text=nil;o.renderCache.shadowText=nil;o.renderCache.textWidth=nil end
    if failed then view.fontsPending=true end
    o.appliedFont={path=font,size=size,outline=outline,justify=n.justify or "CENTER"}
    o.fontFailed=failed;o.fontNeedsSettle=not force
end
local function RefreshObjectFont(view,o)
    if o.text then ApplyTextFont(view,o,true)
    elseif o.chatButtons then M.ChatButtons.RefreshFonts(view,o,true)
    elseif o.nativeAuras then M.NativeDisplays.RefreshAuraFonts(view,o,true)
    else M.ExperienceBar.RefreshFonts(view,o,true) end
end
function R.RefreshTextFonts(view,onlyPending)
    if not view then return end
    view.fontsPending=nil
    local refreshed={}
    for _,o in ipairs(view.ordered or {}) do
        if (o.text or o.spec.kind=="experiencebar" or o.chatButtons or o.nativeAuras)and not o.removed and (not onlyPending or o.fontNeedsSettle or o.fontFailed)
            and (not onlyPending or not view.preview or o.frame:IsVisible())then
            o.fontRuntimeKey=o.fontRuntimeKey or "font:"..o.spec.id
            local group=o.module or o.spec
            if M:RuntimeCall(view,o.fontRuntimeKey,group.label or group.id,RefreshObjectFont,view,o)then refreshed[#refreshed+1]=o
            else o.fontFailed=true;view.fontsPending=true end
        end
    end
    return refreshed
end

local function QueuePreviewFontRefresh(view)
    if not view.preview or view.previewFontRefreshQueued or not C_Timer or not C_Timer.After then return end
    for _,o in ipairs(view.ordered or {}) do
        if (o.text or o.spec.kind=="experiencebar" or o.chatButtons) and not o.removed and o.frame:IsVisible() and (o.fontNeedsSettle or o.fontFailed) then
            view.previewFontRefreshQueued=true
            C_Timer.After(0,function()
                view.previewFontRefreshQueued=nil
                -- Use the current selection: a tab/edit can change before this
                -- callback runs. Hidden names must stay pending until shown.
                local refreshed=R.RefreshTextFonts(view,true)
                if #refreshed>0 then R.Update(view,nil,nil,nil,refreshed) end
            end)
            return
        end
    end
end

local function SameSpec(a,b)
    if a==b then return true end
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return false end
    for key,value in pairs(a) do
        local other=b[key]
        if value~=other and (type(value)~="table" or not SameSpec(value,other)) then return false end
    end
    for key in pairs(b) do if a[key]==nil then return false end end
    return true
end

-- These fields affect appearance/geometry, not the event and animation index.
-- Unknown fields take the full indexing path so new modules remain correct.
local visualFields={x=true,y=true,width=true,height=true,scale=true,scaleReference=true,
    point=true,anchor=true,screenAnchor=true,layer=true,alpha=true,color=true,
    font=true,fontPath=true,fontName=true,fontSize=true,outline=true,justify=true,
    shadowX=true,shadowY=true,autoWidth=true,autoHeight=true,
    file=true,materialPath=true,materialName=true,blend=true,desaturate=true,
    rotation=true,mirror=true,mirrorY=true,cropX=true,cropY=true,
    healthColor=true,healthGradient=true,healthGradientEnd=true,
    healthThresholdEnabled=true,healthThreshold=true,healthThresholdColor=true}
local function SameDependencies(a,b)
    if not a then return false end
    for key,value in pairs(a) do
        if not visualFields[key] and value~=b[key] and not SameSpec(value,b[key]) then return false end
    end
    for key in pairs(b) do if not visualFields[key] and a[key]==nil then return false end end
    return true
end

local preparedDesigns=setmetatable({},{__mode="k"})
function R.PrepareDesign(design,unchanged)
    local prepared=preparedDesigns[design]
    local batch=M.renderBatch
    if prepared and (unchanged or (batch and prepared.batch==batch)) then return prepared end
    M:NormalizeCenterDecoration(design)
    M:SyncCenterLevelFonts(design)
    if M.EnsureAttackProgress then M:EnsureAttackProgress(design) end
    if M.MainBarLayout then M.MainBarLayout.SyncNodes(design) end
    if M.ChatButtons then M.ChatButtons.SyncNodes(design) end
    if M.ExperienceBar then M.ExperienceBar.SyncNodes(design) end
    if M.TargetThreat then M.TargetThreat.SyncNodes(design) end
    if M.TargetDistance then M.TargetDistance.SyncNodes(design) end
    if M.BossFrames then M.BossFrames.SyncNodes(design) end
    if M.PartyFrames then M.PartyFrames.SyncNodes(design) end
    M:NormalizeNodeTextures(design)
    prepared=prepared or {specs={},versions={},objects={},order={},revision=0,indexRevision=0}
    local byID={}
    for _,n in ipairs(design.nodes) do byID[n.id]=n end
    M.SettingRanges.ClampAll(byID)
    local reindex=#prepared.order~=#design.nodes
    prepared.revision=prepared.revision+1
    local order={}
    for i,n in ipairs(design.nodes) do
        local old=prepared.specs[n.id]
        if prepared.order[i]~=n.id or prepared.objects[n.id]~=n then reindex=true end
        if not SameSpec(old,n) then
            if not SameDependencies(old,n) then reindex=true end
            prepared.specs[n.id]=M.Copy(n);prepared.versions[n.id]=prepared.revision
        end
        prepared.objects[n.id]=n;order[i]=n.id
    end
    if reindex then prepared.indexRevision=prepared.indexRevision+1 end
    prepared.order=order;prepared.byID=byID;prepared.batch=batch
    preparedDesigns[design]=prepared
    return prepared
end

function R.Apply(view,design,unchanged)
    view.runtimeFailures=nil
    local prepared=R.PrepareDesign(design,unchanged)
    local selectionChanged=view.renderSelection~=view.selected or view.renderScene~=view.scene
        or view.renderScope~=view.previewScope
    view.renderSelection=view.selected;view.renderScene=view.scene;view.renderScope=view.previewScope
    local settings=table.concat({tostring(M.db and M.db.portrait3D),tostring(M.db and M.db.healthClassColor),
        tostring(M.db and M.db.hideWithoutTarget),tostring(M.db and M.db.useGlobalFont),
        tostring(M.db and M.db.globalFontPath),tostring(M.db and M.db.language),
        tostring(UIParent:GetWidth()),tostring(UIParent:GetHeight()),tostring(UIParent:GetEffectiveScale())},"|")
    local settingsChanged=view.renderSettings~=settings;view.renderSettings=settings
    view.applying=true
    local fullPaint=settingsChanged or selectionChanged or view.design~=design
    local reindex=settingsChanged or view.design~=design or view.indexRevision~=prepared.indexRevision
    local byID=prepared.byID
    local active=byID
    -- Allocate first, then parent: duplicates may follow their original descendants.
    for _,n in ipairs(design.nodes) do
        if not view.nodes[n.id] then
            Build(view,n)
            if view.preview then view.previewSetupPending=true end
        end
    end
    view.byID=byID
    local changed,anyChanged={},false
    for _,n in ipairs(design.nodes) do
        local o=view.nodes[n.id]
        if settingsChanged or o.removed or o.spec~=n or o.specRevision~=prepared.versions[n.id] then
            changed[n.id]=true;anyChanged=true
            if not o.module then reindex=true end
        end
    end
    view.lastConfiguredCount=0
    view.lastReindexed=reindex
    if not anyChanged and not reindex then
        view.applying=false
        if view.preview and selectionChanged then R.SyncPreviewLayers(view,true) end
        R.Update(view);QueuePreviewFontRefresh(view);return
    end
    view.fontsPending=nil;view.fontRetryCount=0;view.fontRetryAt=GetTime()+.5
    view.applyGeneration=(view.applyGeneration or 0)+1
    for _,entry in pairs(view.entries or {}) do entry.members={} end
    view.design=design;view.ordered={};view.rangeDecorations={}
    view.cache=view.cache or {};view.stateFields=view.stateFields or {};view.focusGeometry=view.focusGeometry or {}
    view.auraVersions=view.auraVersions or {}
    if reindex then
        view.auraTemplates={};view.nextDecorationRange=nil;view.decorationTintState=nil
        view.partyDispelCache=nil
        for _,n in ipairs(design.nodes) do
            if n.binding=="auraStacks" or n.binding=="auraTime" then
                view.auraTemplates[n.parent]=view.auraTemplates[n.parent] or {}
                table.insert(view.auraTemplates[n.parent],n)
            end
        end
    end
    local affectedModules={}
    local repaint,paintSet={},{}
    local sweepChanged=settingsChanged
    local levelsChanged=settingsChanged or reindex
    for id,o in pairs(view.nodes) do
        if not active[id] then
            if not o.removed then fullPaint=true end
            if not o.removed then sweepChanged=true end
            if o.spec.kind=="hitbox" and not view.preview then UnregisterUnitWatch(o.frame) end
            o.frame:Hide();o.frame:SetScript("OnUpdate",nil);o.removed=true
            if o.spec.kind=="receivedbuffs"then M.ReceivedBuffs.Remove(view,o)end
            if o.spec.kind=="raidvulnerability"then M.RaidVulnerability.Remove(view,o)end
            if o.spec.kind=="commonitems"then M.CommonItems.Remove(view,o)end
            if o.spec.kind=="skillmonitor"or o.spec.kind=="othermonitor"then M.CustomMonitor.Remove(o)end
            if o.spec.kind=="raidbuffs"then M.RaidBuffMonitor.Remove(view,o)end
            if o.portraitAnchor then
                local anchor=o.portraitAnchor
                if anchor.manguiVisibility then
                    RegisterStateDriver(anchor,"visibility","hide");anchor.manguiVisibility="hide"
                else anchor:Hide() end
            end
        end
    end
    for _,n in ipairs(design.nodes) do
        local o=view.nodes[n.id];local f=o.frame;o.spec=n
        local configure=changed[n.id]
        local ancestor=n.parent and byID[n.parent];local guard=0
        while not configure and ancestor and guard<100 do
            configure=changed[ancestor.id];ancestor=ancestor.parent and byID[ancestor.parent];guard=guard+1
        end
        local moduleID
        if reindex then
            moduleID=M:ModuleID(n,byID)
            o.module=moduleID and byID[moduleID] or nil
            o.focusPortraitOnlyHidden=FocusPortraitOnlyHidden(n,byID)
        else moduleID=o.module and o.module.id end
        -- Logical module roots can own visuals through treeParent rather than
        -- the physical frame parent (notably the central player/target module).
        configure=configure or (moduleID and changed[moduleID])
        o.removed=false
        if configure then
            paintSet[n.id]=true
            if moduleID then affectedModules[moduleID]=true end
            view.lastConfiguredCount=view.lastConfiguredCount+1
            if moduleID=="mainComposite" and n.kind~="text" and n.kind~="hitbox" then sweepChanged=true end
            o.healthCurve=nil;o.healthThresholdCurves=nil
            PrepareVisual(o)
            o.rangeDecoration=false
            if o.texture and n.id=="wa080cd4c4fb" then
                o.rangeDecoration=true
            end
            o.renderCache={};o.healthTintCache=nil;o.cooldownWidth=nil;o.activeSource=nil
            o.spriteIndex=nil;o.raidMark=nil
            o.partyClass=nil;o.partyRole=nil
            o.noticeFrame=nil;o.noticeAlpha=nil
            o.animationColor=nil;o.animationAlpha=nil;o.fillStart=nil;o.fillEdgeMoving=nil;o.sparkRatio=nil;o.sparkStart=nil
            o.auraData=nil;o.nextAuraScan=nil;o.resourceAnimating=nil
            o.attackRatio=nil
            for _,icon in ipairs(o.icons or {}) do
                icon.renderCache={};icon.auraGeneration=nil
                for _,label in pairs(icon.labels or {}) do label.renderCache={} end
                for _,shadow in pairs(icon.shadows or {}) do shadow.renderCache={} end
            end
            for _,slot in ipairs(o.resourceSlots or {}) do slot.renderCache={};slot.resourceAngle=nil end
            o.displayRatio=nil;o.smoothTarget=nil;o.smoothStart=nil;o.nativeReady=nil
            ResetParticle(o)
            local p=n.parent and view.nodes[n.parent] and view.nodes[n.parent].frame or view.root
            local parentModule=n.parent and byID[n.parent] and M:ModuleID(byID[n.parent],byID)
            if moduleID~=parentModule then p=R.TargetVisibilityParent(view,moduleID,p) end
            if M.PartyFrames then p=M.PartyFrames.VisibilityParent(view,n,p) end
            if n.kind~="hitbox" and entrySpecs[n.parent] then p=EntryParent(view,n.parent,p,byID[n.parent]) end
            o.entryID=nil
            if n.kind~="group" and n.kind~="hitbox" then
                local ancestor=n.parent and byID[n.parent];local guard=0
                while ancestor and guard<100 do
                    if entrySpecs[ancestor.id] then
                        if not view.entries or not view.entries[ancestor.id] then EntryParent(view,ancestor.id,view.nodes[ancestor.id].frame,ancestor) end
                        o.entryID=ancestor.id
                        table.insert(view.entries[ancestor.id].members,o);break
                    end
                    ancestor=ancestor.parent and byID[ancestor.parent];guard=guard+1
                end
            end
            if f:GetParent()~=p then f:SetParent(p);levelsChanged=true end
            o.geometryParent=p;f:SetSize(math.max(1,n.width or 2),math.max(1,n.height or 2));f:SetScale(M.Clamp(M:NodeScale(n),.05,10))
            R.Position(view,f,n,p)
            local level=view.root:GetFrameLevel()+math.max(1,math.floor(n.layer or 1))
            if f:GetFrameLevel()~=level then f:SetFrameLevel(level);levelsChanged=true end
            f:SetAlpha(n.alpha or 1)
            if o.chatButtons then M.ChatButtons.Configure(view,o)
            elseif n.kind=="raidbuffs"then M.RaidBuffMonitor.Configure(view,o)
            elseif n.kind=="receivedbuffs"then M.ReceivedBuffs.Configure(view,o)
            elseif n.kind=="raidvulnerability"then M.RaidVulnerability.Configure(view,o)
            elseif n.kind=="commonitems"then M.CommonItems.Configure(view,o)
            elseif n.kind=="othermonitor" then M.PlayerOtherMonitor.Configure(view,o)
            elseif n.kind=="skillmonitor" then M.PlayerSkillMonitor.Configure(view,o)
            elseif o.menuButtons then M.SystemMenu.Configure(view,o)
            elseif n.kind=="mousecircle" then M.MouseCircle.Configure(view,o)
            elseif n.kind=="experiencebar" then M.ExperienceBar.Configure(view,o)
            elseif n.kind=="targetthreat" then M.TargetThreat.Configure(view,o)
            elseif n.kind=="targetdistance" then M.TargetDistance.Configure(view,o)
            elseif n.kind=="targetdistancenumber" then M.TargetDistance.ConfigureNumber(view,o)
            elseif o.text then
                o.shadow:ClearAllPoints()
                o.shadow:SetPoint("TOPLEFT",f,"TOPLEFT",n.shadowX or 6,n.shadowY or -6)
                o.shadow:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",n.shadowX or 6,n.shadowY or -6)
                local size=math.max(.1,n.fontSize or 20)
                if n.autoHeight then f:SetHeight(math.max(n.height or 2,math.ceil(size*1.5+16))) end
                ApplyTextFont(view,o)
                o.shadow:SetTextColor(0,0,0,1)
                if M.PartyFrames then M.PartyFrames.ConfigureText(o) end
            elseif o.texture then
                o.texture:SetTexture(n.file or "Interface\\Buttons\\WHITE8X8");o.texture:SetBlendMode(n.blend or "BLEND")
                o.texture:SetDesaturated(n.desaturate or false);TextureCoords(o.texture,n)
                if o.texture.SetRotation then o.texture:SetRotation(math.rad(n.rotation or 0)) end
                if M.PartyFrames then M.PartyFrames.ConfigureTexture(o) end
                if n.attackKind then o.texture:SetVertexColor(unpack(n.color or {1,1,1,1})) end
                if o.castInterior then o.castInterior:SetVertexColor(unpack(n.color or {1,1,1,1})) end
            elseif o.bar then
                local material=n.alphaFill and n.materialPath or nil
                o.bar:SetStatusBarTexture(material or n.file or "Interface\\Buttons\\WHITE8X8")
                o.bar:SetOrientation(n.vertical and "VERTICAL" or "HORIZONTAL");o.bar:SetReverseFill(n.reverse or false)
                o.bar:SetMinMaxValues(0,1);o.bar:SetValue(.72)
                local t=o.bar:GetStatusBarTexture();if t then TextureCoords(t,n);t:SetBlendMode(n.blend or "BLEND") end
                o.fill:SetTexture(n.file or "Interface\\Buttons\\WHITE8X8");o.fill:SetBlendMode(n.blend or "BLEND");TextureCoords(o.fill,n)
                o.fill:SetAlpha(1)
                local fillInset=n.alphaFill and (n.fillInset or 0) or 0
                o.fill:SetSize(n.width,n.height);o.fill:ClearAllPoints();o.fill:SetPoint(n.reverse and "RIGHT" or "LEFT",o.clip,n.reverse and "RIGHT" or "LEFT",n.reverse and fillInset or -fillInset,0)
                if n.alphaFill then
                    if not o.material then
                        o.material=o.clip:CreateTexture(nil,"ARTWORK",nil,1)
                        o.materialMask=o.clip:CreateMaskTexture()
                        o.material:AddMaskTexture(o.materialMask)
                        o.nativeMask=o.bar:CreateMaskTexture()
                    end
                    -- Let the engine's filled region size a clipping frame. Place
                    -- full-size artwork on its child so clipping never stretches it.
                    if not o.nativeArt then
                        o.nativeClip=CreateFrame("Frame",nil,o.bar)
                        o.nativeClip:EnableMouse(false);o.nativeClip:SetClipsChildren(true)
                        o.nativeArtFrame=CreateFrame("Frame",nil,o.nativeClip)
                        o.nativeArtFrame:EnableMouse(false)
                        o.nativeArt=o.nativeArtFrame:CreateTexture(nil,"ARTWORK")
                        o.nativeArt:AddMaskTexture(o.nativeMask)
                    end
                    local nativeMaterial=material~="Interface\\Buttons\\WHITE8X8" and material or nil
                    o.nativeArt:SetTexture(nativeMaterial or n.file)
                    o.nativeClip:SetAllPoints(t)
                    o.nativeArtFrame:SetAllPoints(o.frame)
                    o.nativeArt:SetAllPoints(o.nativeArtFrame);TextureCoords(o.nativeArt,n)
                    o.nativeArt:SetBlendMode(n.blend or "BLEND")
                    o.bar:SetStatusBarColor(1,1,1,0)
                    if t then t:SetAlpha(0) end
                    o.material:SetSize(n.width,n.height);o.material:ClearAllPoints()
                    o.material:SetPoint(n.reverse and "RIGHT" or "LEFT",o.clip,n.reverse and "RIGHT" or "LEFT",n.reverse and fillInset or -fillInset,0)
                    o.material:SetTexture(material or "Interface\\Buttons\\WHITE8X8")
                    o.material:SetBlendMode("BLEND");TextureCoords(o.material,n)
                    o.material:SetShown(material~=nil)
                    o.materialMask:SetTexture(n.file);o.materialMask:SetAllPoints(o.material);TextureCoords(o.materialMask,n)
                    o.nativeMask:SetTexture(nativeMaterial and n.file or "Interface\\Buttons\\WHITE8X8","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
                    o.nativeMask:SetAllPoints(o.nativeArt);TextureCoords(o.nativeMask,n)
                end
                if o.targetHealthThreshold then
                    local target=o.nativeArt or t
                    if not o.healthWarning then o.healthWarning=(o.nativeArtFrame or o.bar):CreateTexture(nil,"OVERLAY") end
                    local warningMaterial=material~="Interface\\Buttons\\WHITE8X8" and material or nil
                    o.healthWarning:SetTexture(warningMaterial or n.file)
                    o.healthWarning:SetAllPoints(target);TextureCoords(o.healthWarning,n)
                    o.healthWarning:SetBlendMode(n.blend or "BLEND")
                    if o.nativeMask and not o.warningMasked then
                        o.healthWarning:AddMaskTexture(o.nativeMask);o.warningMasked=true
                    end
                    o.healthWarning:Hide()
                end
                if M.BossFrames then M.BossFrames.ConfigureHealthFill(o) end
            elseif o.model then
                R.SuppressMovementModel(view,o.model)
                local id=tonumber(n.model) or 165577
                if not view.movementModelsHidden and o.loadedModel~=id then o.model:SetModel(id);o.loadedModel=id end
                if not view.movementModelsHidden then NativeModelPose(o) end
                o.model:SetAlpha(view.movementModelsHidden and 0 or (n.modelAlpha or 1))
                o.model:SetShown(not view.movementModelsHidden)
            elseif o.edges then Border(o,n) end
            if M.NativeDisplays then
                if n.kind=="auras" then M.NativeDisplays.ConfigureAuras(view,o)
                elseif n.castFill then M.NativeDisplays.ConfigureCast(view,o) end
            end
            if n.kind=="portrait" then
                M.Portraits.Configure(view,o)
                if M.BossFrames then M.BossFrames.ConfigurePortrait(o) end
                ConfigurePortraitAnchor(view,o)
            end
            local enabled=n.enabled~=false and (view.preview or not o.module or o.module.enabled~=false)
            if o.focusPortraitOnlyHidden then enabled=false end
            if view.preview and M.moduleIDs[n.id] then enabled=true end
            if n.kind=="hitbox" and not view.preview then
                C.Menu(f,n.unit)
                if enabled then RegisterUnitWatch(f) else UnregisterUnitWatch(f);f:Hide() end
            else f:SetShown(enabled) end
            o.appliedSpec=prepared.specs[n.id];o.specRevision=prepared.versions[n.id]
        else
            local entry=o.entryID and view.entries and view.entries[o.entryID]
            if entry then entry.members[#entry.members+1]=o end
        end
        if o.rangeDecoration then view.rangeDecorations[#view.rangeDecorations+1]=o end
        if o.fontFailed then view.fontsPending=true end
        view.ordered[#view.ordered+1]=o
    end
    EnsureFocusMenu(view,active)
    if M.AttackProgress then M.AttackProgress.Configure(view) end
    -- Parenting/entry-animation frames can shift descendants' native levels.
    -- Restore every requested level after all parents have been configured,
    -- then place native models on their portrait's final layer and strata.
    if view.preview then
        -- Apply once now, then confirm after native show/parent updates settle.
        R.SyncPreviewLayers(view,true)
        view.previewLayersPending=true
    elseif levelsChanged then
    for pass=1,2 do
        for _,o in ipairs(view.ordered) do
            local level=view.root:GetFrameLevel()+math.max(1,math.floor(o.spec.layer or 1))
            if o.frame:GetFrameLevel()~=level then o.frame:SetFrameLevel(level) end
            if o.frame.GetFrameStrata and view.root.GetFrameStrata then
                local strata=view.root:GetFrameStrata()
                if o.frame:GetFrameStrata()~=strata then o.frame:SetFrameStrata(strata) end
            end
        end
    end
    for _,o in ipairs(view.ordered) do
        if o.portraitModel then
            if o.frame.GetFrameStrata then
                local strata=o.frame:GetFrameStrata()
                if o.portraitModel:GetFrameStrata()~=strata then o.portraitModel:SetFrameStrata(strata) end
            end
            local level=o.frame:GetFrameLevel()
            if o.portraitModel:GetFrameLevel()~=level then o.portraitModel:SetFrameLevel(level) end
        end
    end
    end
    if M.PartyFrames and (levelsChanged or affectedModules.partyFrames) then M.PartyFrames.ConfigurePortraits(view) end
    if M.PartyFrames and (reindex or affectedModules.partyFrames) then M.PartyFrames.ConfigureHighlight(view) end
    if reindex then IndexUpdates(view) end
    view.indexRevision=prepared.indexRevision
    if not fullPaint then
        -- Labels rendered inside aura icons and following sparks depend on the
        -- edited node even when their own saved properties did not change.
        for id in pairs(paintSet) do
            local n=byID[id]
            if n and (n.binding=="auraTime" or n.binding=="auraStacks") and n.parent then paintSet[n.parent]=true end
        end
        local added=true
        while added do
            added=false
            for _,o in ipairs(view.ordered) do
                local n=o.spec
                if not paintSet[n.id] and ((n.owner and paintSet[n.owner]) or (n.startAt and paintSet[n.startAt])) then
                    paintSet[n.id]=true;added=true
                end
            end
        end
        for _,o in ipairs(view.ordered) do if paintSet[o.spec.id] then repaint[#repaint+1]=o end end
    else repaint=nil end
    view.applying=false
    if not view.preview then view.mainAnchorPending=true;R.SyncMainPortraitAnchor(view) end
    R.UpdateUnitMenuBounds(view)
    R.Update(view,nil,nil,nil,repaint)
    QueuePreviewFontRefresh(view)
    if M.MainSweep then
        if sweepChanged or not view.mainSweep then M.MainSweep.Configure(view) end
        M.MainSweep.Animate(view)
    end
end

M.RendererInternals.NativeModelPose=NativeModelPose
M.RendererInternals.Build=Build
M.RendererInternals.Border=Border
M.RendererInternals.EnsureFocusMenu=EnsureFocusMenu
