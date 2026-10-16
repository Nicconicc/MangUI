local _,M=...
local C,B,R=M.Compat,M.MainBarLayout,M.Renderer
local unpack=unpack or table.unpack
local private=M.RendererInternals
local FocusPortraitOnlyHidden=private.FocusPortraitOnlyHidden
local independentKinds=private.independentKinds
local ResetParticle=private.ResetParticle
local Paint=private.Paint

local focusPoints={CENTER={0,0},LEFT={-1,0},RIGHT={1,0},TOP={0,1},BOTTOM={0,-1},TOPLEFT={-1,1},TOPRIGHT={1,1},BOTTOMLEFT={-1,-1},BOTTOMRIGHT={1,-1}}
local menuBodies={bar=true,portrait=true,texture=true,sprite=true,border=true}
function R.UpdateUnitMenuBounds(view)
    if view.preview or InCombatLockdown() or view.menuBoundsGeneration==view.applyGeneration then return end
    local byID=view.byID;local regions,owners={},{}
    local function Add(button,anchorID,roots)
        if not button or not byID[anchorID] then return end
        local region={button=button,anchorID=anchorID};regions[#regions+1]=region
        for _,id in ipairs(roots) do owners[id]=region end
    end
    local function Button(id)return view.nodes[id] and view.nodes[id].frame end
    Add(Button("wab9dab4b3b1"),"mainComposite",{"wa70b7aa5607","waf0a666c0b7"})
    Add(Button("wa24502fe64f"),"mainComposite",{"waf465575a72","wae608adf3d8"})
    Add(Button("petHitbox"),"petComposite",{"petComposite"})
    Add(Button("totHitbox"),"totComposite",{"totComposite"})
    Add(view.focusMenu,"focusComposite",{"focusComposite"})
    for i=0,4 do local id="party"..i;Add(Button(id.."Hitbox"),id.."Frame",{id.."Frame"}) end
    local geometry=M:Geometry(byID)
    for _,o in ipairs(view.ordered or {}) do
        local n=o.spec
        if menuBodies[n.kind] and n.enabled~=false and not o.focusPortraitOnlyHidden
            and n.binding~="cast" and n.binding~="castIcon" and not n.castFill then
            local current=n;local region;local enabled=true
            for _=1,100 do
                if not current then break end
                if current.enabled==false then enabled=false;break end
                region=region or owners[current.id]
                current=byID[current.parent]
            end
            local g=enabled and region and geometry[n.id]
            if g then
                -- Full layout dimensions, never the depleted or animated fill.
                local left,right=g.x-g.w*g.s/2,g.x+g.w*g.s/2
                local bottom,top=g.y-g.h*g.s/2,g.y+g.h*g.s/2
                region.left=region.left and math.min(region.left,left) or left
                region.right=region.right and math.max(region.right,right) or right
                region.bottom=region.bottom and math.min(region.bottom,bottom) or bottom
                region.top=region.top and math.max(region.top,top) or top
            end
        end
    end
    for _,region in ipairs(regions) do
        local anchor=view.nodes[region.anchorID];local g=geometry[region.anchorID]
        if region.left and anchor and g then
            local button=region.button;local scale=math.max(.001,g.s)
            local x=((region.left+region.right)/2-g.x)/scale
            local y=((region.bottom+region.top)/2-g.y)/scale
            local width=(region.right-region.left)/scale+8
            local height=(region.top-region.bottom)/scale+8
            if button:GetParent()~=anchor.frame then button:SetParent(anchor.frame) end
            button:SetScale(1);button:ClearAllPoints();button:SetPoint("CENTER",anchor.frame,"CENTER",x,y)
            button:SetSize(math.max(1,width),math.max(1,height))
        end
    end
    view.menuBoundsGeneration=view.applyGeneration
end
local function UpdateFocusMenuBounds(view)R.UpdateUnitMenuBounds(view)end
local targetUnits={target=true,targettarget=true}
local gateModules={mainComposite={mainComposite=true},petComposite={petComposite=true},focusComposite={focusComposite=true}}
function R.InvalidateAuras(view,unit)
    view.auraVersions=view.auraVersions or {}
    local versions=view.auraVersions
    if unit then versions[unit]=(versions[unit] or 0)+1
    else
        for _,name in ipairs({"player","target","targettarget","focus","pet"}) do versions[name]=(versions[name] or 0)+1 end
    end
end
function R.RefreshTarget(view,moduleID)
    if view.applying or view.targetRefreshing then return end
    view.nextDecorationRange=nil
    view.targetRefreshing=true
    view.targetRefreshGeneration=(view.targetRefreshGeneration or 0)+1
    R.InvalidateAuras(view,"target");R.InvalidateAuras(view,"targettarget")
    for _,o in ipairs(view.targetRefreshNodes or view.ordered or {}) do
        local n=o.spec
        if n.unit=="target" or n.unit=="targettarget" or n.unit=="shared" then
            o.displayRatio=nil;o.smoothTarget=nil;o.smoothStart=nil;o.smoothFrom=nil;o.nativeReady=nil
            if n.kind=="portrait" then o.portraitRefresh=true end
        end
    end
    local ok,err=pcall(R.Update,view,targetUnits,gateModules[moduleID])
    view.targetRefreshing=nil
    if not ok then error(err) end
end
local healthState={health=true};local powerState={power=true};local healthPowerState={health=true,power=true}
local function InvalidateState(view,unit,fields)
    view.cache[unit]=nil
    local previous=view.stateFields[unit]
    if previous==false or not fields then view.stateFields[unit]=false
    elseif previous and previous~=fields then view.stateFields[unit]=healthPowerState
    else view.stateFields[unit]=fields end
end
local function Invalidate(view,unit,fields)
    InvalidateState(view,unit,fields)
    if unit=="player" or unit=="vehicle" or unit=="shared" then
        InvalidateState(view,"player",fields);InvalidateState(view,"vehicle",fields);InvalidateState(view,"shared",fields)
    end
    if unit=="target" or unit=="shared" then
        InvalidateState(view,"target",fields);InvalidateState(view,"shared",fields)
    end
end
local function UpdateOrder(a,b) return a.updateOrder<b.updateOrder end
local function ProfilePaint(view,o,animateOnly,visibleHint)
    local started=debugprofilestop()
    Paint(view,o,animateOnly,visibleHint)
    M.ModuleProfiler.Record(o.module and o.module.id,o.spec.kind,debugprofilestop()-started,animateOnly and "animate" or "update")
end
local emptyUpdates={}
local function QueueBucket(list,bucket,generation)
    if not bucket then return 0 end
    for _,o in ipairs(bucket) do
        if o.updateGeneration~=generation then o.updateGeneration=generation;list[#list+1]=o end
    end
    return 1
end
function R.Update(view,units,modules,fields,objects)
    if not view.ordered then return end
    R.UpdateDecorationRange(view)
    for unit in pairs(view.stateFields) do view.stateFields[unit]=nil end
    local list=view.ordered;local focus=not units and not modules and not objects
    if objects then
        list=objects
        for _,o in ipairs(objects) do for unit in pairs(o.unitDeps or emptyUpdates) do Invalidate(view,unit) end end
    elseif units or modules then
        list=view.updateQueue
        for i=#list,1,-1 do list[i]=nil end
        view.updateGeneration=(view.updateGeneration or 0)+1
        local generation=view.updateGeneration;local buckets=0
        for unit in pairs(units or emptyUpdates) do
            local key=unit=="vehicle" and "player" or unit
            local mask
            if fields and not fields.all[key] then
                if fields.health[key] and fields.power[key] then mask=healthPowerState
                elseif fields.health[key] then mask=healthState
                elseif fields.power[key] then mask=powerState end
            end
            Invalidate(view,key,mask)
            if not fields or fields.all[key] or not (fields.health[key] or fields.power[key]) then
                buckets=buckets+QueueBucket(list,view.unitBuckets[key],generation)
            else
                if fields.health[key] then buckets=buckets+QueueBucket(list,view.fieldBuckets.health[key],generation) end
                if fields.power[key] then buckets=buckets+QueueBucket(list,view.fieldBuckets.power[key],generation) end
            end
        end
        for id in pairs(modules or emptyUpdates) do
            for unit in pairs(view.moduleUnits[id] or emptyUpdates) do Invalidate(view,unit) end
            buckets=buckets+QueueBucket(list,view.moduleBuckets[id],generation)
        end
        if buckets>1 then table.sort(list,UpdateOrder) end
    else for unit in pairs(view.cache) do view.cache[unit]=nil end end
    view.lastUpdateCount=#list
    local paint=not view.preview and M.ModuleProfiler and M.ModuleProfiler.active and ProfilePaint or Paint
    for _,o in ipairs(list) do
        paint(view,o,false)
        if o.module and o.module.id=="focusComposite" then focus=true end
    end
    if not view.preview and focus then UpdateFocusMenuBounds(view) end
    R.UpdateEntryAnimations(view)
    if M.BossFrames then M.BossFrames.Animate(view) end
    if M.PartyFrames then M.PartyFrames.RefreshHighlight(view) end
end
local function NeedsAnimation(view,o)
    if view.preview then return true end
    local n=o.spec
    if n.centerLogo then return o.logoAnimating~=false end
    if o.bar and (n.binding=="health" or n.binding=="power") then return o.smoothStart~=nil or o.animatedEdge or o.fillEdgeMoving or B.Moving(view,n) end
    if n.kind=="spark" and n.followDisplay then
        local owner=view.nodes[n.owner]
        if owner then return owner.spec.binding=="cast" or owner.animatedEdge or owner.fillEdgeMoving or B.Moving(view,owner.spec) or owner.displayRatio~=o.sparkRatio or owner.fillStart~=o.sparkStart end
    end
    if n.kind=="resources" and o.resourceAnimating==false then return false end
    return true
end
function R.Animate(view)
    if not view.root:IsVisible() then return end
    R.UpdateDecorationRange(view)
    if not view.preview then view.animationNow=GetTime();view.animationCasting=nil end
    local paint=not view.preview and M.ModuleProfiler and M.ModuleProfiler.active and ProfilePaint or Paint
    for _,o in ipairs(view.animated) do
        -- Custom modules may wake themselves while hidden (range, cooldowns,
        -- combat notices). Ordinary visuals wake through Update or gate OnShow.
        local n=o.spec
        if NeedsAnimation(view,o) then
            if independentKinds[n.kind] or n.attackKind or n.centerLogo or (n.kind=="spark" and n.edgeOnly) then
                paint(view,o,true)
            elseif o.frame:IsVisible() then
                paint(view,o,true,true)
            elseif n.particleFlow then
                ResetParticle(o)
            end
        end
    end
    R.UpdateEntryAnimations(view,true)
    if M.BossFrames and view.bossAnimating then M.BossFrames.Animate(view) end
    if M.MainSweep then
        local profile=not view.preview and M.ModuleProfiler
        local started=profile and profile.active and debugprofilestop()
        M.MainSweep.Animate(view)
        if started then profile.Record("mainComposite","shine",debugprofilestop()-started,"animate") end
    end
end

M.RendererInternals.focusPoints=focusPoints
M.RendererInternals.UpdateFocusMenuBounds=UpdateFocusMenuBounds
M.RendererInternals.targetUnits=targetUnits
M.RendererInternals.gateModules=gateModules
M.RendererInternals.healthState=healthState
M.RendererInternals.InvalidateState=InvalidateState
M.RendererInternals.Invalidate=Invalidate
M.RendererInternals.UpdateOrder=UpdateOrder
M.RendererInternals.ProfilePaint=ProfilePaint
M.RendererInternals.emptyUpdates=emptyUpdates
M.RendererInternals.QueueBucket=QueueBucket
M.RendererInternals.NeedsAnimation=NeedsAnimation
