local _,M=...
local C=M.Compat
local B=M.MainBarLayout
local R={};M.Renderer=R
local unpack=unpack or table.unpack
local raidMarkFiles={}
for index,name in ipairs({"Star","Circle","Diamond","Triangle","Moon","Square","Cross","Skull"}) do
    raidMarkFiles[index]="Interface\\AddOns\\MangUI\\Assets\\RaidMarks\\"..name.."-v3.tga"
end
local function Readable(value) return not (issecretvalue and issecretvalue(value)) end
local function Cache(o)
    if not o.renderCache then o.renderCache={} end
    return o.renderCache
end
-- Cache only readable native values; restricted values always reach the API.
local function CachedValue(o,key,target,method,value)
    local cache=Cache(o);local last=cache[key]
    if not Readable(value) then cache[key]=nil;target[method](target,value);return true end
    if last and last[1]==value then return false end
    target[method](target,value)
    last=last or {};last[1]=value;cache[key]=last;return true
end
local function CachedPair(o,key,target,method,a,b)
    local cache=Cache(o);local last=cache[key]
    if not Readable(a) or not Readable(b) then cache[key]=nil;target[method](target,a,b);return end
    if last and last[1]==a and last[2]==b then return end
    target[method](target,a,b)
    last=last or {};last[1],last[2]=a,b;cache[key]=last
end
local function CachedColor(o,key,target,method,col)
    local a,b,c,d=col[1],col[2],col[3],col[4] or 1
    local cache=Cache(o);local last=cache[key]
    if not Readable(a) or not Readable(b) or not Readable(c) or not Readable(d) then
        cache[key]=nil;target[method](target,a,b,c,d);return true
    end
    if last and last[1]==a and last[2]==b and last[3]==c and last[4]==d then return end
    target[method](target,a,b,c,d)
    last=last or {};last[1],last[2],last[3],last[4]=a,b,c,d;cache[key]=last
    return true
end
local function HealthTint(o,key,target,col,force)
    if not target then return end
    if not (o.customHealthStyle or o.classHealthColor or o.targetHealthThreshold) then
        CachedColor(o,key,target,"SetVertexColor",col);return
    end
    local n=o.spec
    local finish=not o.classHealthColor and not o.healthThresholdActive and not o.tapColorActive
        and n.healthGradient==true and (n.healthGradientEnd or col) or nil
    local a=col[4] or 1;local ea=finish and (finish[4] or a)
    local cache=o.healthTintCache or {};o.healthTintCache=cache
    local last=cache[key]
    if not force and last and last.texture==target and last[1]==col[1] and last[2]==col[2]
        and last[3]==col[3] and last[4]==a and last[5]==(finish and finish[1])
        and last[6]==(finish and finish[2]) and last[7]==(finish and finish[3]) and last[8]==ea then return end
    if finish and (target.SetGradientAlpha or (target.SetGradient and CreateColor)) then
        target:SetVertexColor(1,1,1,1)
        if target.SetGradientAlpha then
            target:SetGradientAlpha("HORIZONTAL",col[1],col[2],col[3],a,finish[1],finish[2],finish[3],ea)
        else
            target:SetGradient("HORIZONTAL",CreateColor(col[1],col[2],col[3],a),CreateColor(finish[1],finish[2],finish[3],ea))
        end
    else target:SetVertexColor(col[1],col[2],col[3],a) end
    last=last or {};cache[key]=last;last.texture=target
    last[1],last[2],last[3],last[4]=col[1],col[2],col[3],a
    last[5],last[6],last[7],last[8]=finish and finish[1],finish and finish[2],finish and finish[3],ea
end
local function CachedPoint(o,key,target,point,parent,anchor,x,y)
    local cache=Cache(o);local last=cache[key]
    if last and last[1]==point and last[2]==parent and last[3]==anchor and last[4]==x and last[5]==y then return end
    target:ClearAllPoints();target:SetPoint(point,parent,anchor,x,y)
    last=last or {};last[1],last[2],last[3],last[4],last[5]=point,parent,anchor,x,y;cache[key]=last
end
local points={CENTER=true,LEFT=true,RIGHT=true,TOP=true,BOTTOM=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
local function ResourceModelPose(model)
    if model.movementSuppressed then return end
    local position=model.resourcePosition
    if not position then return end
    -- SetModel, viewport changes and asynchronous loading can reset the camera.
    -- Apply the old model API in WA's order, after the viewport is sized.
    if model.SetPortraitZoom then model:SetPortraitZoom(0) end
    if model.ClearTransform then model:ClearTransform() end
    model:SetModelScale(1)
    model:SetPosition(position[1],position[2],position[3])
    model:SetFacing(model.resourceFacing or 0)
end
local function ResourceModelLoaded(model)
    if model.movementSuppressed then model:Hide();model:ClearModel();return end
    if not model.resourcePosition then return end
    ResourceModelPose(model)
    model:SetAnimation(model.resourceSequence or 0)
end
local function ResourceModelRestart(model)
    if model.movementSuppressed then model:Hide();return true end
    if not model.resourceFile or not model.resourcePosition or model.resourceReloading then return end
    model.resourceReloading=true
    -- WA releases hidden models and configures them again on PreShow. Reusing
    -- a retained particle simulation also retains particles from the old scale.
    model:ClearModel()
    local ok=pcall(model.SetModel,model,model.resourceFile)
    if ok then ResourceModelLoaded(model) end
    model.resourceReloading=nil
    return ok
end
local noTargetModules={mainComposite=true,petComposite=true,focusComposite=true}
local function FocusPortraitOnlyHidden(n,index)
    local group=index.focusComposite
    if not group or group.portraitNameOnly~=true or n.id==group.id or n.kind=="hitbox" then return false end
    local branch=n;local guard=0
    while branch and guard<100 do
        if branch.parent==group.id then return branch.id~="focusAvatar" and branch.binding~="name" end
        branch=branch.parent and index[branch.parent];guard=guard+1
    end
    return false
end
local entrySpecs={
    wa70b7aa5607={duration=.3,x=-10},waf0a666c0b7={duration=.4,x=-10},
    waf465575a72={duration=.3,x=10},wae608adf3d8={duration=.4,x=10},
    wabc757f81ee={duration=.3,scale=1.1},
}
function R.EntryCurve(spec,progress)
    -- WA start animations reverse progress before applying easeIn (strength 3).
    local eased=(1-M.Clamp(progress,0,1))^3
    local shift=(spec.x or 0)*math.sin(eased*math.pi)
    local scale=1+((spec.scale or 1)-1)*(1-math.cos(eased*2*math.pi))/2
    return shift,scale
end
local function EntryTransform(entry,shift,scale,force)
    if not force and entry.shift==shift and entry.scale==scale then entry.transformPending=nil;return end
    local f=entry.frame
    if InCombatLockdown() and f.IsProtected then
        local ok,value=pcall(f.IsProtected,f)
        if not ok or not C.Readable(value) or value then entry.transformPending=true;return end
    end
    entry.transformPending=nil
    f:SetScale(scale);f:ClearAllPoints();f:SetPoint("CENTER",entry.parent,"CENTER",shift/scale,0)
    entry.shift,entry.scale=shift,scale
end
local function EntryParent(view,id,parent,spec)
    view.entries=view.entries or {}
    local entry=view.entries[id]
    if not entry then
        -- Animate an unprotected visual layer. Secure unit buttons remain on
        -- their original parents, so combat never moves or scales click areas.
        local frame=CreateFrame("Frame",nil,parent);frame:EnableMouse(false)
        entry={frame=frame,parent=parent,spec=entrySpecs[id],members={}}
        view.entries[id]=entry
        frame:SetScript("OnHide",function()
            if view.applying then return end
            entry.visible=false;entry.started=nil;entry.visibilityDirty=nil;EntryTransform(entry,0,1)
        end)
        frame:SetScript("OnShow",function()
            if not view.applying then entry.visibilityDirty=true end
        end)
    end
    entry.parent=parent;entry.frame:SetParent(parent)
    entry.frame:SetSize(spec.width or 2,spec.height or 2)
    EntryTransform(entry,entry.shift or 0,entry.scale or 1,true)
    return entry.frame
end
function R.UpdateEntryAnimations(view,animateOnly)
    if view.applying then return end
    if R.SyncMainPortraitAnchor then R.SyncMainPortraitAnchor(view) end
    local now=GetTime()
    for _,entry in pairs(view.entries or {}) do
        -- Settled entry animations wake through normal updates or native show.
        if not animateOnly or entry.started or entry.visibilityDirty or entry.transformPending then
            entry.visibilityDirty=nil
            local visible=false
            for _,o in ipairs(entry.members) do
                if not o.removed and o.frame:IsVisible() then visible=true;break end
            end
            if visible and not entry.visible then entry.started=now end
            entry.visible=visible
            local shift,scale=0,1
            if visible and entry.started then
                local progress=M.Clamp((now-entry.started)/entry.spec.duration,0,1)
                if progress<1 then shift,scale=R.EntryCurve(entry.spec,progress)
                else entry.started=nil end
            elseif not visible then entry.started=nil end
            EntryTransform(entry,shift,scale)
        end
    end
end
-- Gate every physical root of these modules. Some main-frame elements use
-- treeParent for module membership while retaining different geometry parents.
-- Secure visibility also hides unit buttons safely when targets change in combat.
function R.TargetVisibilityParent(view,moduleID,parent)
    if view.preview or not noTargetModules[moduleID] then return parent end
    view.targetGates=view.targetGates or {}
    local gates=view.targetGates[moduleID]
    if not gates then gates={};view.targetGates[moduleID]=gates end
    local gate=gates[parent]
    if not gate then
        gate=CreateFrame("Frame",nil,parent,"SecureHandlerStateTemplate")
        gate:SetAllPoints(parent);gate:EnableMouse(false)
        gate:SetScript("OnShow",function()
            if not view.applying then M:Safe("目标刷新",R.RefreshTarget,view,moduleID) end
        end)
        gates[parent]=gate
    end
    local enabled=M.db.hideWithoutTarget==true
    if gate.targetVisibilityEnabled~=enabled then
        if enabled then RegisterStateDriver(gate,"visibility","[@target,exists] show; hide")
        else UnregisterStateDriver(gate,"visibility");gate:Show() end
        gate.targetVisibilityEnabled=enabled
    end
    return gate
end
local function Font(n)
    if M.db and M.db.useGlobalFont then return M:EffectiveFontPath() end
    if type(n.fontPath)=="string" and n.fontPath~="" then return M:ResolveFontPath(n.fontPath) end
    -- The bundled Latin face is used for numeric labels; CJK names use the client font.
    if n.font=="Myriad" and n.binding~="name" and n.binding~="static" and n.binding~="castName" and n.binding~="petStatus" then return M.MYRIAD end
    return M:DefaultFontPath()
end
local function TextureCoords(t,n)
    local x,y=1+(n.cropX or 0),1+(n.cropY or 0)
    local l,r=.5-.5/x,.5+.5/x;local top,bottom=.5-.5/y,.5+.5/y
    if n.mirror then l,r=r,l end
    if n.mirrorY then top,bottom=bottom,top end
    t:SetTexCoord(l,r,top,bottom)
end
local independentKinds={raidbuffs=true,commonitems=true,othermonitor=true,skillmonitor=true,cooldowns=true,chatbuttons=true,systemmenu=true,mousecircle=true,
    experiencebar=true,combatnotice=true,targetthreat=true,targetdistance=true}
local function Animated(n)
    return n.kind=="sprite" or n.kind=="combatnotice" or n.kind=="systemmenu" or n.kind=="mousecircle"
        or n.kind=="experiencebar" or n.kind=="targetthreat" or n.kind=="targetdistance" or n.kind=="glow"
        or n.kind=="spark" or n.kind=="resources" or n.kind=="skillmonitor" or n.kind=="othermonitor" or n.kind=="raidbuffs" or n.kind=="commonitems" or n.kind=="cooldowns" or n.centerLogo or n.spinPeriod
        or n.smooth or n.binding=="cast" or n.binding=="castTime" or n.attackKind
end
local function ResetParticle(o)
    o.particlePhase=nil;o.particleTime=nil;o.particleMode=nil;o.particleSlideAt=nil;o.particleSettled=nil
end
local function PrepareVisual(o)
    local n=o.spec
    o.classHealthColor=M.db and M.db.healthClassColor==true and n.kind=="bar" and n.binding=="health"
    o.customHealthStyle=n.kind=="bar" and n.binding=="health" and (n.healthColor~=nil or n.healthGradient==true)
    o.targetHealthThreshold=n.id=="wa385c615b2a"
    o.targetLevelColor=n.id=="wa38ad2639d2"
    o.healthThresholdActive=false
    o.fixedAppearance=not (o.targetLevelColor or o.classHealthColor or o.customHealthStyle or o.targetHealthThreshold or n.powerColor or n.nameColor or n.targetNameColor or n.tapColor) and #(n.conditions or {})==0
    local simple=n.kind=="texture" or n.kind=="sprite" or n.kind=="glow" or n.kind=="border"
        or (n.kind=="text" and (not n.binding or n.binding=="static" or n.binding=="auraStacks" or n.binding=="auraTime"))
    o.needsState=not (simple and not (n.powerColor or n.nameColor or n.targetNameColor or n.tapColor or n.castFill or n.binding=="castIcon" or n.binding=="raid" or n.binding=="partyClass" or n.binding=="partyRole"))
    o.fastVisual=(n.kind=="glow" or (o.texture and (n.kind=="sprite" or n.kind=="texture")))
        and not (n.centerLogo or n.castFill or n.binding=="castIcon" or n.binding=="raid")
    o.fastReady=nil
    if n.kind=="sprite" then
        local rows,columns=math.max(1,n.rows or 1),math.max(1,n.columns or 1)
        o.spriteGrid={rows=rows,columns=columns,frames=math.max(1,n.effectOnce and math.min(n.frames or 1,rows*columns) or n.frames or 1)}
    else o.spriteGrid=nil end
end
local function AddUnit(deps,unit)
    unit=unit or "player"
    if unit=="shared" then deps.player=true;deps.target=true
    elseif unit=="vehicle" then deps.player=true
    else deps[unit]=true end
end
local function TriggerUnits(deps,n)
    if n.id=="wa38ad2639d2" then AddUnit(deps,"player") end
    if n.triggerAny=="targetOrPlayerCast" then AddUnit(deps,"player");AddUnit(deps,"target") end
    if n.triggerAny=="bossTarget" or n.triggerAny=="bossCast" then AddUnit(deps,"target") end
    for _,rule in ipairs(n.rules or {}) do
        AddUnit(deps,rule.unit)
        if rule.test=="targetOrCasting" then AddUnit(deps,"player");AddUnit(deps,"target") end
    end
    for _,condition in ipairs(n.conditions or {}) do
        AddUnit(deps,condition.unit)
        if condition.field=="hastarget" then AddUnit(deps,"target") end
    end
end
local healthFields={health=true,maxHealth=true,healthRatio=true,dead=true,partyDead=true}
local powerFields={power=true,maxPower=true,powerRatio=true,powerType=true,powerColor=true}
local function FieldDependencies(o)
    local n=o.spec;local fields={health={},power={}};o.fieldDeps=fields
    local binding=n.binding
    if n.kind=="portrait" and n.unit=="pet" then AddUnit(fields.health,"pet") end
    if binding=="health" or binding=="healthText" or binding=="healthPercent" or (n.kind=="bar" and not binding) then AddUnit(fields.health,n.unit) end
    if binding=="power" or binding=="powerText" or binding=="powerPercent" or n.powerColor then AddUnit(fields.power,n.unit) end
    if n.kind=="resources" then AddUnit(fields.power,"player") end
    for _,rule in ipairs(n.rules or {}) do
        if healthFields[rule.test] then AddUnit(fields.health,rule.unit) end
        if powerFields[rule.test] then AddUnit(fields.power,rule.unit) end
    end
    for _,condition in ipairs(n.conditions or {}) do
        if condition.field=="percenthealth" then AddUnit(fields.health,condition.unit)
        elseif condition.field=="powertype" then AddUnit(fields.power,condition.unit) end
    end
end
local function IndexUpdates(view)
    view.unitBuckets={};view.moduleBuckets={};view.moduleUnits={};view.animated={};view.targetRefreshNodes={};view.updateQueue={}
    view.fieldBuckets={health={},power={}}
    for index,o in ipairs(view.ordered) do
        local n=o.spec;local deps={};o.unitDeps=deps;o.updateOrder=index
        FieldDependencies(o)
        o.auraClock=false
        for _,template in ipairs(view.auraTemplates[n.id] or {}) do
            if template.enabled~=false and template.binding=="auraTime" then o.auraClock=true;break end
        end
        o.animatedEdge=false
        local edge=n.startAt and view.byID[n.startAt];local edgeGuard=0
        while edge and edgeGuard<100 do
            if entrySpecs[edge.id] or edge.particleFlow or edge.kind=="spark" then o.animatedEdge=true;break end
            edge=edge.parent and view.byID[edge.parent];edgeGuard=edgeGuard+1
        end
        if not independentKinds[n.kind] and n.kind~="group" and n.kind~="hitbox" then
            AddUnit(deps,n.unit);if n.visibleUnit then AddUnit(deps,n.visibleUnit) end
            TriggerUnits(deps,n)
            if n.particleFlow or n.spinPeriod or n.centerLogo or n.kind=="resources" then AddUnit(deps,"player") end
            if n.kind=="resources" then AddUnit(deps,"target") end
            if n.effectOnce then
                if n.effectTrigger~="cast" then AddUnit(deps,"target") end
                if n.effectTrigger~="target" then AddUnit(deps,"player") end
            end
        elseif n.kind=="group" then TriggerUnits(deps,n)
        elseif n.kind=="targetthreat" or n.kind=="targetdistance" then AddUnit(deps,"target") end
        local ancestor=n.parent and view.byID[n.parent];local guard=0
        while ancestor and guard<100 do
            if ancestor.triggerAny then TriggerUnits(deps,ancestor) end
            ancestor=ancestor.parent and view.byID[ancestor.parent];guard=guard+1
        end
        if (Animated(n) or o.auraClock) and (view.preview or (n.enabled~=false and (not o.module or o.module.enabled~=false))) then
            view.animated[#view.animated+1]=o
        end
        if n.unit=="target" or n.unit=="targettarget" or n.unit=="shared" then view.targetRefreshNodes[#view.targetRefreshNodes+1]=o end
    end
    -- Sparks and portrait-edge fills must follow their owner's data dependencies.
    local changed=true
    while changed do
        changed=false
        for _,o in ipairs(view.ordered) do
            local n=o.spec
            for _,id in pairs({n.owner,n.startAt}) do
                local owner=view.nodes[id]
                if owner and not owner.removed then
                    for unit in pairs(owner.unitDeps) do
                        if not o.unitDeps[unit] then o.unitDeps[unit]=true;changed=true end
                    end
                    for field,units in pairs(owner.fieldDeps) do
                        for unit in pairs(units) do
                            if not o.fieldDeps[field][unit] then o.fieldDeps[field][unit]=true;changed=true end
                        end
                    end
                end
            end
        end
    end
    for _,o in ipairs(view.ordered) do
        for field,units in pairs(o.fieldDeps) do
            for unit in pairs(units) do
                local bucket=view.fieldBuckets[field][unit] or {};view.fieldBuckets[field][unit]=bucket;bucket[#bucket+1]=o
            end
        end
        for unit in pairs(o.unitDeps) do
            local bucket=view.unitBuckets[unit] or {};view.unitBuckets[unit]=bucket;bucket[#bucket+1]=o
        end
        local id=o.module and o.module.id
        if id then
            local bucket=view.moduleBuckets[id] or {};view.moduleBuckets[id]=bucket;bucket[#bucket+1]=o
            local units=view.moduleUnits[id] or {};view.moduleUnits[id]=units
            for unit in pairs(o.unitDeps) do units[unit]=true end
        end
    end
end

M.RendererInternals={}
M.RendererInternals.raidMarkFiles=raidMarkFiles
M.RendererInternals.Readable=Readable
M.RendererInternals.Cache=Cache
M.RendererInternals.CachedValue=CachedValue
M.RendererInternals.CachedPair=CachedPair
M.RendererInternals.CachedColor=CachedColor
M.RendererInternals.HealthTint=HealthTint
M.RendererInternals.CachedPoint=CachedPoint
M.RendererInternals.points=points
M.RendererInternals.ResourceModelPose=ResourceModelPose
M.RendererInternals.ResourceModelLoaded=ResourceModelLoaded
M.RendererInternals.ResourceModelRestart=ResourceModelRestart
M.RendererInternals.noTargetModules=noTargetModules
M.RendererInternals.FocusPortraitOnlyHidden=FocusPortraitOnlyHidden
M.RendererInternals.entrySpecs=entrySpecs
M.RendererInternals.EntryTransform=EntryTransform
M.RendererInternals.EntryParent=EntryParent
M.RendererInternals.Font=Font
M.RendererInternals.TextureCoords=TextureCoords
M.RendererInternals.independentKinds=independentKinds
M.RendererInternals.Animated=Animated
M.RendererInternals.ResetParticle=ResetParticle
M.RendererInternals.PrepareVisual=PrepareVisual
M.RendererInternals.AddUnit=AddUnit
M.RendererInternals.TriggerUnits=TriggerUnits
M.RendererInternals.healthFields=healthFields
M.RendererInternals.powerFields=powerFields
M.RendererInternals.FieldDependencies=FieldDependencies
M.RendererInternals.IndexUpdates=IndexUpdates
