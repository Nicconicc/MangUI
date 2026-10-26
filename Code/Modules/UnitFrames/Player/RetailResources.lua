local _,M=...
local C,R,I=M.Compat,M.Renderer,M.RendererInternals
local P={};M.RetailResources=P
local art=M.ART.."PlayerResources\\Retail\\"
local unpack=unpack or table.unpack
local modes={
    ROGUE={[259]="combo",[260]="combo",[261]="combo"},
    DRUID={[102]="combo",[103]="combo",[104]="combo",[105]="combo"},
    MAGE={[62]="arcane",[64]="icicles"},PALADIN={[65]="holy",[66]="holy",[70]="holy"},
    SHAMAN={[262]="maelstrom",[263]="maelstrom",[264]="maelstrom"},
    DEATHKNIGHT={[250]="blood",[251]="frost",[252]="unholy"},MONK={[269]="chi"},
    WARLOCK={[265]="shards",[266]="shards",[267]="shards"},
    EVOKER={[1467]="essence",[1468]="essence",[1473]="essence"},
}
local powers={combo=4,arcane=16,holy=9,chi=12,shards=7,essence=19}
local function Query(fn,...)
    if type(fn)~="function"then return end
    local ok,value=pcall(fn,...)
    if ok then return value end
end
local function Specialization()
    local api=C_SpecializationInfo
    local index=Query(GetSpecialization or api and api.GetSpecialization)
    if C.Number(index)then return C.Number(Query(GetSpecializationInfo or api and api.GetSpecializationInfo,index))end
end
local function AuraStacks(id)
    local api=C_UnitAuras
    local aura=Query(api and api.GetPlayerAuraBySpellID,id)
    if C.Readable(aura)and aura==nil and AuraUtil and AuraUtil.FindAuraBySpellID then
        -- Older retail clients expose this helper rather than the direct query.
        local _,_,count=AuraUtil.FindAuraBySpellID(id,"player","HELPFUL")
        if not C.Readable(count)then return count end
        return C.Number(count,0)
    end
    if not C.Readable(aura)or type(aura)~="table"or(canaccesstable and not canaccesstable(aura))then return 0 end
    local count=aura.applications
    if not C.Readable(count)then return count end
    return C.Number(count,0)
end
local function Amount(key,preview,limit)
    if preview then return key=="maelstrom"and 10 or limit end
    if key=="icicles"then return AuraStacks(205473)end
    if key=="maelstrom"then return AuraStacks(344179)end
    if key=="blood"or key=="frost"or key=="unholy"then
        local count=0
        if GetRuneCooldown then
            for i=1,6 do
                local ok,start,_,ready=pcall(GetRuneCooldown,i)
                if not ok or not C.Readable(start)or not C.Readable(ready)then
                    return Query(UnitPower,"player",5)
                end
                if ready==true or(ready==nil and start==0)then count=count+1 end
            end
            return count
        end
        return Query(UnitPower,"player",5)
    end
    return Query(UnitPower,"player",powers[key])
end
local function Pass(value,op,threshold)
    if op=="=="then return value==threshold end
    return value>=threshold
end
local function Appearance(d,value,spec)
    local alpha,file,y=d.alpha,d.file,0
    for _,condition in ipairs(d.conditions)do
        local v=condition.variable=="specId"and spec or value
        if v and Pass(v,condition.op,condition.value)then
            for _,change in ipairs(condition.changes)do
                if change.property=="alpha"then alpha=change.value
                elseif change.property=="texture"then file=change.value
                elseif change.property=="yOffsetRelative"then y=change.value end
            end
        end
    end
    return alpha,file,y
end
local function Curve(evaluate)
    if not(C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType)then return end
    local curve=C_CurveUtil.CreateCurve();curve:SetType(Enum.LuaCurveType.Step)
    -- All resources in the source use integer points/stacks. Add an upper
    -- breakpoint for equality predicates without comparing opaque values in Lua.
    local boundaries={[-1]=true,[0]=true,[16]=true}
    for value=1,12 do boundaries[value]=true;boundaries[value+.000001]=true end
    local points={};for value in pairs(boundaries)do points[#points+1]=value end;table.sort(points)
    for _,value in ipairs(points)do local alpha=evaluate(value);curve:AddPoint(value,alpha)end
    return curve
end
local function Evaluate(curve,value)
    if not curve then return 0 end
    local ok,alpha=pcall(curve.Evaluate,curve,value)
    if ok then return alpha end
    return 0
end
local function Frame(parent,w,h,level)
    local f=CreateFrame("Frame",nil,parent);f:SetSize(w,h);f:EnableMouse(false)
    f:SetFrameLevel(level or parent:GetFrameLevel()+1);return f
end
local function Rotate(texture,degrees,rotate,mirror)
    local angle=math.rad(135-degrees);local divisor=rotate and 1 or math.sqrt(2)
    local x,y=math.cos(angle)/divisor,math.sin(angle)/divisor
    local a,b,c,d,e,f,g,h=.5+x,.5-y,.5-y,.5-x,.5+y,.5+x,.5-x,.5+y
    if mirror then texture:SetTexCoord(e,f,g,h,a,b,c,d)else texture:SetTexCoord(a,b,c,d,e,f,g,h)end
end
local function ReferenceScale(data,key)
    -- Match the existing resource row using the shared white diamond, whose
    -- texture/UVs are identical in both renderers. Keep the WA's proportions.
    local largest=0
    for _,d in ipairs(data.leaves)do
        if d.file=="Frame_Bar.blp"then largest=math.max(largest,d.w*d.scale*data.scale)end
    end
    local reference=50
    if key=="blood"or key=="frost"or key=="unholy"then reference=reference/.9 end
    return largest>0 and reference/largest or 1
end
local function Build(o,key)
    local data=M.RetailResourceData[key]
    local factor=ReferenceScale(data,key)
    local row={frame=Frame(o.frame,data.width/data.scale,data.height/data.scale),leaves={},data=data,
        sizeFactor=factor,scale=data.scale*factor}
    row.frame:SetPoint("CENTER");row.frame:SetScale(row.scale)
    for _,d in ipairs(data.leaves)do
        local f=Frame(row.frame,d.w,d.h,row.frame:GetFrameLevel()+d.layer)
        f:SetScale(d.scale);f:Hide()
        local v=Frame(f,d.w,d.h);v:SetPoint("CENTER")
        local leaf={frame=f,visual=v,data=d};row.leaves[#row.leaves+1]=leaf
        leaf.alphaCurve=Curve(function(amount)
            if not Pass(amount,d.op,d.threshold)then return 0 end
            return Appearance(d,amount)
        end)
        if d.kind=="model"then
            local model=CreateFrame("PlayerModel",nil,v);model:SetSize(d.w,d.h);model:SetPoint("CENTER")
            model:SetFrameLevel(v:GetFrameLevel()+1);model:EnableMouse(false)
            model.resourceFile=d.file;model.resourcePosition=d.position;model.resourceSequence=d.sequence
            model.resourceFacing=math.rad(d.rotation)
            if model.SetKeepModelOnHide then model:SetKeepModelOnHide(false)end
            model:SetScript("OnModelLoaded",I.ResourceModelLoaded)
            model:SetScript("OnShow",I.ResourceModelRestart);model:Hide();leaf.model=model
        elseif d.kind=="text"then
            local text=v:CreateFontString(nil,"OVERLAY")
            text:SetPoint(d.selfPoint,v,"CENTER",0,0)
            text:SetTextColor(unpack(d.color));text:SetJustifyH(d.justify)
            text:SetShadowColor(unpack(d.shadowColor));text:SetShadowOffset(d.shadowXOffset,d.shadowYOffset)
            leaf.text=text
        else
            local variants={[d.file]=true};leaf.textures={}
            for _,c in ipairs(d.conditions)do
                for _,change in ipairs(c.changes)do if change.property=="texture"then variants[change.value]=true end end
            end
            for file in pairs(variants)do
                local t=v:CreateTexture(nil,"ARTWORK");t:SetSize(d.w,d.h);t:SetPoint("CENTER")
                t:SetTexture(art..file);t:SetBlendMode(d.blend);t:SetVertexColor(unpack(d.color));t:SetDesaturated(d.desaturate)
                Rotate(t,d.rotation,d.rotate,d.mirror)
                leaf.textures[file]={texture=t,curve=Curve(function(amount)
                    if not Pass(amount,d.op,d.threshold)then return 0 end
                    local alpha,current=Appearance(d,amount)
                    return current==file and alpha or 0
                end)}
            end
        end
    end
    return row
end
local function Hide(o)
    if not o.retailResources then return end
    for _,row in pairs(o.retailResources)do
        row.frame:Hide()
        for _,leaf in ipairs(row.leaves)do
            leaf.active=nil;leaf.phase=nil;leaf.nativeMode=nil;leaf.frame:Hide()
            if leaf.model then leaf.model:Hide();leaf.model:ClearModel()end
        end
    end
end
local function Layout(row,limit)
    if limit==row.data.count then return row.data end
    row.layouts=row.layouts or {}
    if row.layouts[limit]then return row.layouts[limit]end
    local data=row.data;local points={};local half=0
    for _,d in ipairs(data.leaves)do
        if d.file=="Frame_Bar.blp"and d.threshold<=limit then points[#points+1]=d end
        if d.kind=="texture"and d.threshold<=limit then half=math.max(half,math.abs(d.x)+d.w*d.scale/2)end
    end
    table.sort(points,function(a,b)return a.x<b.x end)
    local layout={count=#points,width=2*half*data.scale,slots={}}
    for rank,d in ipairs(points)do layout.slots[d.slot]=rank end
    row.layouts[limit]=layout;return layout
end
function P.Animate(o)
    local row=o.retailResources and o.retailResources[o.retailResourceMode]
    if not row or not row.frame:IsShown()then return end
    local now=GetTime();local animating=false
    for _,leaf in ipairs(row.leaves)do
        if not leaf.nativeMode then
            local scale,alpha=1,leaf.currentAlpha or leaf.data.alpha
            if leaf.phase then
                local p=M.Clamp((now-leaf.at)/.25,0,1)
                local factor=leaf.phase=="enter"and p or 1-p
                scale=math.max(.001,factor);alpha=alpha*factor
                if p==1 then
                    leaf.phase=nil
                    if not leaf.active then leaf.frame:Hide();if leaf.model then leaf.model:Hide()end end
                end
            end
            local resized=I.CachedValue(leaf,"scale",leaf.visual,"SetScale",scale)
            I.CachedValue(leaf,"alpha",leaf.visual,"SetAlpha",alpha)
            if resized and scale==1 and leaf.model and leaf.active and not leaf.model.movementSuppressed then I.ResourceModelRestart(leaf.model)end
            animating=animating or leaf.phase~=nil
        end
    end
    o.resourceAnimating=animating
end
function P.Paint(view,o)
    if not C.retail then Hide(o);o.retailResourcesActive=nil;o.retailResourceMode=nil;return false end
    o.retailResourcesActive=true
    for _,slot in ipairs(o.resourceSlots)do slot:Hide()end
    local _,class=UnitClass("player");local spec=Specialization()
    local key=modes[class]and modes[class][spec]
    if o.retailResourceMode~=key then Hide(o)end
    o.retailResourceMode=key
    if not key then o.frame:Hide();o.resourceAnimating=false;return true end
    o.retailResources=o.retailResources or {}
    local row=o.retailResources[key]
    if not row then row=Build(o,key);o.retailResources[key]=row end
    local n,f=o.spec,o.frame;local data=row.data
    local limit=class=="ROGUE"and spec==260 and 5 or data.count
    local layout=Layout(row,limit);row.pointLimit=limit
    local parent=view.nodes[n.parent]and view.nodes[n.parent].spec
    local gap=M.Clamp(parent and parent.resourceSpacing or 0,-20,20)
    I.CachedPair(o,"resourceSize",f,"SetSize",layout.width*row.sizeFactor+(layout.count-1)*gap,data.height*row.sizeFactor)
    I.CachedValue(o,"resourceScale",f,"SetScale",M:NodeScale(n))
    if parent and parent.resourceOriginRevision==1 then I.CachedPoint(o,"resourcePoint",f,"CENTER",f:GetParent(),"CENTER",0,0)
    else I.CachedPoint(o,"resourcePoint",f,"LEFT",f:GetParent(),"CENTER",n.x or 122.22,n.y or -68.89)end
    row.frame:Show()
    local amount=Amount(key,view.preview,limit);local native=not C.Readable(amount)
    if not native then amount=C.Number(amount,0)end
    row.amount=amount;row.nativeMode=native
    for _,leaf in ipairs(row.leaves)do
        local d=leaf.data
        local alpha,file,y=Appearance(d,native and 0 or amount,spec)
        local slot=d.slot and(layout.slots and layout.slots[d.slot]or d.slot)
        local x=d.x+(slot and(slot-(layout.count+1)/2)*gap/row.scale or -(layout.count-1)*gap/row.scale/2)
        I.CachedPoint(leaf,"point",leaf.frame,"CENTER",row.frame,"CENTER",x,d.y+y)
        if leaf.text then
            local font=M:EffectiveFontPath(M.MYRIAD)
            if leaf.font~=font then M:ApplyRegionFont(leaf.text,font,d.fontSize,d.outline);leaf.font=font end
            I.CachedValue(leaf,"text",leaf.text,"SetText",amount)
        end
        if d.threshold>limit then
            -- A specialization change must immediately remove unavailable
            -- points, including opaque-value leaves and any exit animation.
            leaf.phase=nil;leaf.active=false;leaf.nativeMode=nil;leaf.frame:Hide()
            if leaf.model then leaf.model:Hide()end
        elseif native then
            -- Native curves receive opaque values directly. Lua never compares,
            -- counts, rounds or reconstructs restricted combat information.
            leaf.phase=nil;leaf.active=nil;leaf.nativeMode=true;leaf.frame:Show()
            I.CachedValue(leaf,"scale",leaf.visual,"SetScale",1)
            I.CachedValue(leaf,"alpha",leaf.visual,"SetAlpha",1)
            local opacity=Evaluate(leaf.alphaCurve,amount)
            if leaf.text then leaf.text:SetAlpha(opacity)end
            for _,variant in pairs(leaf.textures or {})do variant.texture:SetAlpha(Evaluate(variant.curve,amount))end
            if leaf.model then
                R.SuppressMovementModel(view,leaf.model)
                if not leaf.model.movementSuppressed then leaf.model:SetAlpha(opacity);leaf.model:Show()end
            end
        else
            local active=Pass(amount,d.op,d.threshold)
            if leaf.nativeMode then leaf.active=nil;leaf.nativeMode=nil end
            if active~=leaf.active then
                local previous=leaf.active;leaf.active=active;leaf.at=GetTime()
                leaf.phase=active and"enter"or(previous and"exit"or nil)
            end
            leaf.currentAlpha=alpha
            leaf.frame:SetShown(active or leaf.phase~=nil)
            if leaf.text then leaf.text:SetAlpha(1)end
            for name,variant in pairs(leaf.textures or {})do variant.texture:SetAlpha(name==file and 1 or 0)end
            if leaf.model then
                R.SuppressMovementModel(view,leaf.model)
                if not leaf.model.movementSuppressed then leaf.model:SetAlpha(1);leaf.model:SetShown(active or leaf.phase~=nil)end
            end
        end
    end
    P.Animate(o)
    return true
end
