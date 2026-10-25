local _,M=...
local C,R=M.Compat,M.Renderer
local I=M.RendererInternals
local P={};M.MistsResources=P
local art=M.ART.."PlayerResources\\Mists\\"
local unpack=unpack or table.unpack
local definitions={
    MAGE={[62]="arcane"},PRIEST={[258]="shadow"},
    WARLOCK={[265]="shards",[267]="embers"},DRUID={[102]="balance"},
    PALADIN={[65]="holy",[66]="holy",[70]="holy"},
    MONK={[268]="chi",[269]="chi",[270]="chi"},SHAMAN={[263]="maelstrom"},
}
local powers={shadow={"ShadowOrbs",28},embers={"BurningEmbers",14},shards={"SoulShards",7},
    holy={"HolyPower",9},chi={"Chi",12},balance={"Balance",26}}
local function Query(fn,...)
    if type(fn)~="function"then return end
    local ok,value=pcall(fn,...)
    if ok and C.Readable(value)then return value end
end
local function PowerType(key)
    local p=powers[key]
    return Enum and Enum.PowerType and Enum.PowerType[p[1]] or p[2]
end
local function Specialization()
    local api=C_SpecializationInfo
    local index=Query(GetSpecialization or api and api.GetSpecialization)
    return index and Query(GetSpecializationInfo or api and api.GetSpecializationInfo,index)
end
local auraBuffer={}
local function Aura(id,filter)
    for i=1,255 do
        local a=C.Aura("player",i,filter or "HELPFUL",auraBuffer)
        if not a then break end
        if C.Number(a.spellId)==id then
            return C.Number(a.applications,0),C.Number(a.expirationTime,0)
        end
    end
end
local function State(key,preview)
    if key=="arcane"then
        if preview then return 4,4,GetTime()+12 end
        local count,expiration=Aura(36032,"HARMFUL")
        return count or 0,4,expiration
    elseif key=="maelstrom"then
        return preview and 5 or (Aura(53817)or 0),5
    end
    local powerType=PowerType(key)
    local amount=C.Number(Query(UnitPower,"player",powerType),0)
    local maximum=C.Number(Query(UnitPowerMax,"player",powerType),0)
    if key=="embers"or key=="shards"then
        local modifier=C.Number(Query(UnitPowerDisplayMod,powerType),key=="embers"and 10 or 1)
        if modifier<=0 then modifier=1 end
        local raw=C.Number(Query(UnitPower,"player",powerType,true))
        local rawMax=C.Number(Query(UnitPowerMax,"player",powerType,true))
        if raw then amount=raw/modifier end
        if rawMax then maximum=rawMax/modifier end
    end
    if key=="balance"then
        local solar=Aura(48517)~=nil
        local lunar=Aura(48518)~=nil
        local both=Aura(112071)~=nil
        return preview and 50 or M.Clamp(amount,-100,100),100,nil,solar,lunar,both
    end
    local count=M.MistsResourceData[key].count
    if preview then return count,count end
    return math.max(0,amount),math.min(count,math.max(0,maximum))
end
local function Frame(parent,w,h,level)
    local f=CreateFrame("Frame",nil,parent);f:SetSize(w,h);f:EnableMouse(false)
    f:SetFrameLevel(parent:GetFrameLevel()+(level or 1));return f
end
local function Texture(parent,file,w,h,x,y,layer)
    local t=parent:CreateTexture(nil,layer or "ARTWORK")
    t:SetSize(w,h);t:SetPoint("CENTER",parent,"CENTER",x or 0,y or 0)
    t:SetTexture(art..file);return t
end
local function Text(parent,spec)
    local t=parent:CreateFontString(nil,"OVERLAY")
    t:SetPoint(spec.selfPoint,parent,"CENTER",spec.xOffset,spec.yOffset)
    M:ApplyRegionFont(t,M:EffectiveFontPath(M.MYRIAD),spec.fontSize,spec.outline)
    t:SetTextColor(unpack(spec.color));t:SetJustifyH(spec.justify)
    t:SetShadowColor(unpack(spec.shadowColor));t:SetShadowOffset(spec.shadowXOffset,spec.shadowYOffset)
    return t
end
local function Rotate(t,degrees,canRotate,mirror)
    local angle=math.rad(135-degrees)
    local divisor=canRotate and 1 or math.sqrt(2)
    local x,y=math.cos(angle)/divisor,math.sin(angle)/divisor
    local a,b,c,d,e,f,g,h=.5+x,.5-y,.5-y,.5-x,.5+y,.5+x,.5-x,.5+y
    if mirror then t:SetTexCoord(e,f,g,h,a,b,c,d)else t:SetTexCoord(a,b,c,d,e,f,g,h)end
end
local function BuildRow(o,key)
    local data=M.MistsResourceData[key]
    local row={frame=Frame(o.frame,data.width,60),leaves={},groups={},data=data}
    row.frame:SetPoint("CENTER")
    for i,d in ipairs(data.groups)do
        local parent=d.parent==0 and row.frame or row.groups[d.parent].frame
        local f=Frame(parent,1,1);f:SetScale(d.scale)
        row.groups[i]={frame=f,data=d}
    end
    for i,d in ipairs(data.leaves)do
        local parent=d.parent==0 and row.frame or row.groups[d.parent].frame
        local f=Frame(parent,d.w,d.h);f:SetFrameLevel(row.frame:GetFrameLevel()+d.layer)
        f:SetScale(d.scale);f:SetPoint("CENTER",parent,"CENTER",d.x,d.y);f:Hide()
        local v=Frame(f,d.w,d.h);v:SetPoint("CENTER")
        local leaf={frame=f,visual=v,data=d};row.leaves[i]=leaf
        if d.kind=="model"then
            local model=CreateFrame("PlayerModel",nil,v);model:SetSize(d.w,d.h);model:SetPoint("CENTER")
            model:EnableMouse(false);model:SetFrameLevel(v:GetFrameLevel()+1)
            model.resourceFile=d.file;model.resourcePosition=d.position;model.resourceSequence=d.sequence or 0
            model.resourceFacing=math.rad(d.rotation)
            if model.SetKeepModelOnHide then model:SetKeepModelOnHide(false)end
            model:SetScript("OnModelLoaded",I.ResourceModelLoaded)
            model:SetScript("OnShow",I.ResourceModelRestart);model:Hide();leaf.model=model
        else
            local t=Texture(v,d.file,d.w,d.h,0,0)
            t:SetBlendMode(d.blend);t:SetVertexColor(unpack(d.color))
            t:SetDesaturated(d.desaturate)
            leaf.texture=t
        end
    end
    if data.timer then row.timer=Text(row.frame,data.timer)end
    if data.fill then
        row.fills={}
        local d=data.fill
        for i=1,4 do
            local f=Frame(row.frame,d.width,d.height);f:SetFrameLevel(row.frame:GetFrameLevel()+d.layer);f:Hide()
            local t=Texture(f,"EmberFill.tga",d.width,d.height)
            t:ClearAllPoints();t:SetPoint("BOTTOM",f,"BOTTOM",0,0)
            local spark=f:CreateTexture(nil,"OVERLAY");spark:SetTexture(d.sparkTexture)
            spark:SetSize(d.sparkWidth,d.sparkHeight);spark:SetBlendMode(d.sparkBlendMode)
            spark:SetVertexColor(unpack(d.sparkColor));spark:SetTexCoord(0,1,1,1,0,0,1,0)
            row.fills[i]={frame=f,texture=t,spark=spark}
        end
    end
    return row
end
local function Hide(o)
    for _,row in pairs(o.mistsResources or {})do
        row.frame:Hide()
        for _,leaf in ipairs(row.leaves or {})do
            leaf.active=nil;leaf.phase=nil;leaf.frame:Hide()
            if leaf.model then leaf.model:Hide();leaf.model:ClearModel()end
        end
    end
end
local function UpdateBalance(o,row,view)
    local power,_,_,solar,lunar,both=State("balance",view.preview)
    if both then power=100 end
    M.MistsBalance.Update(o,row,view,power,solar,lunar,both)
end
local function UpdateRow(o,row,key,view,gap)
    local amount,maximum,expiration=State(key,view.preview)
    row.amount,row.maximum,row.expiration=amount,maximum,expiration
    for _,group in ipairs(row.groups)do
        local d=group.data
        local offset=(d.slot-(row.data.count+1)/2)*gap/d.scale
        I.CachedPoint(group,"point",group.frame,"CENTER",group.frame:GetParent(),"CENTER",d.x+offset,d.y)
    end
    for _,leaf in ipairs(row.leaves)do
        local d=leaf.data
        local passes=d.op=="=="and math.abs(amount-d.threshold)<1e-7 or d.op==">="and amount+1e-7>=d.threshold
        local active=d.slot<=maximum and passes
        if active~=leaf.active then
            local previous=leaf.active;leaf.active=active;leaf.at=GetTime()
            leaf.phase=active and d.enter and "enter"or(previous and d.exit and "exit"or nil)
            leaf.frame:SetShown(active or leaf.phase~=nil)
            if leaf.model then
                R.SuppressMovementModel(view,leaf.model)
                leaf.model:SetShown(not view.movementModelsHidden and (active or leaf.phase~=nil))
            end
        end
        if leaf.model then
            R.SuppressMovementModel(view,leaf.model)
            leaf.model:SetShown(not view.movementModelsHidden and (active or leaf.phase~=nil))
        end
    end
    if row.fills then
        local brimstone=Aura(108683)~=nil
        local d=row.data.fill
        for i,fill in ipairs(row.fills)do
            local fraction=M.Clamp(amount-i+1,0,1)
            I.CachedPoint(fill,"point",fill.frame,"CENTER",row.frame,"CENTER",d.x+(i-1)*d.step+(i-2.5)*gap,d.y)
            fill.frame:SetShown(i<=maximum and fraction>0)
            fill.texture:SetHeight(math.max(.001,d.height*fraction))
            -- WA rotates a vertical bar's horizontal status texture by 90 degrees.
            fill.texture:SetTexCoord(1-fraction,1,1,1,1-fraction,0,1,0)
            I.CachedPoint(fill,"sparkPoint",fill.spark,"CENTER",fill.frame,"CENTER",0,-d.height/2+d.height*fraction)
            fill.spark:SetShown(fraction>0 and fraction<1)
            if brimstone then fill.texture:SetVertexColor(1,1,1,1)
            else fill.texture:SetVertexColor(.945098,1,.968628,1)end
        end
    end
end
function P.Animate(o)
    local key=o.mistsResourceMode;local row=o.mistsResources and o.mistsResources[key]
    if not row or not row.frame:IsShown()then return end
    if key=="balance"then M.MistsBalance.Animate(o,row);return end
    local now=GetTime()
    local animating=false
    for _,leaf in ipairs(row.leaves)do
        local d=leaf.data
        if leaf.frame:IsShown()then
            local scale,alpha,angle=1,d.alpha,0
            if leaf.phase then
                local animation=leaf.phase=="enter"and d.enter or d.exit
                local progress=M.Clamp((now-leaf.at)/animation.duration,0,1)
                local factor=leaf.phase=="enter"and progress or 1-progress
                if animation.scale then scale=factor end
                if animation.alpha then alpha=alpha*factor end
                angle=animation.angle*(leaf.phase=="enter"and 1-progress or progress)
                if progress>=1 then
                    leaf.phase=nil
                    if not leaf.active then leaf.frame:Hide();if leaf.model then leaf.model:Hide()end end
                end
            end
            local resized=I.CachedValue(leaf,"scale",leaf.visual,"SetScale",math.max(.001,scale))
            I.CachedValue(leaf,"alpha",leaf.visual,"SetAlpha",alpha)
            if leaf.texture then
                if d.kind=="stopmotion"then
                    local frame=math.floor((now-(leaf.at or now))*d.fps)%d.frames
                    local x,y=frame%d.columns,math.floor(frame/d.columns)
                    leaf.texture:SetTexCoord(x/d.columns,(x+1)/d.columns,y/d.rows,(y+1)/d.rows)
                    animating=true
                elseif leaf.angle~=angle then Rotate(leaf.texture,d.rotation+angle,d.rotate,d.mirror);leaf.angle=angle end
            elseif leaf.model then
                leaf.model.resourceFacing=math.rad(d.rotation+angle)
                if not leaf.model.movementSuppressed then
                    I.CachedValue(leaf,"facing",leaf.model,"SetFacing",leaf.model.resourceFacing)
                    if resized and scale==1 then I.ResourceModelRestart(leaf.model)end
                end
            end
        end
        animating=animating or leaf.phase~=nil
    end
    if row.timer then
        local remaining=math.max(0,(row.expiration or 0)-now)
        row.timer:SetShown(row.amount>0 and remaining>0)
        I.CachedValue(row,"timer",row.timer,"SetText",tostring(math.ceil(remaining)))
        animating=animating or remaining>0
    end
    o.resourceAnimating=animating
end
function P.Paint(view,o)
    local _,_,_,interface=GetBuildInfo()
    local _,class=UnitClass("player")
    local spec=Specialization()
    -- Preserve the original combo-point and rune implementations verbatim.
    local supported=type(interface)=="number"and interface>=50000 and interface<60000 and definitions[class]
    if not supported or class=="DRUID"and spec~=102 then
        Hide(o);o.mistsResourceMode=nil;return false
    end
    local key=definitions[class][spec]
    for _,slot in ipairs(o.resourceSlots)do slot:Hide()end
    o.mistsResources=o.mistsResources or {}
    if o.mistsResourceMode~=key then Hide(o)end
    o.mistsResourceMode=key
    if not key then o.resourceAnimating=false;o.frame:Hide();return true end
    local row=o.mistsResources[key]
    if not row then
        row=key=="balance"and M.MistsBalance.Build(o)or BuildRow(o,key);o.mistsResources[key]=row
    end
    local n,f=o.spec,o.frame
    local parent=view.nodes[n.parent]and view.nodes[n.parent].spec
    local gap=M.Clamp(parent and parent.resourceSpacing or 0,-20,20)
    local width=key=="balance"and 340 or row.data.width+(row.data.count-1)*gap
    I.CachedPair(o,"resourceSize",f,"SetSize",width,60)
    I.CachedValue(o,"resourceScale",f,"SetScale",M:NodeScale(n))
    if parent and parent.resourceOriginRevision==1 then
        I.CachedPoint(o,"resourcePoint",f,"CENTER",f:GetParent(),"CENTER",0,0)
    else
        I.CachedPoint(o,"resourcePoint",f,"LEFT",f:GetParent(),"CENTER",n.x or 122.22,n.y or -68.89)
    end
    row.frame:Show()
    local label=row.timer or row.text
    if label then
        local path=M:EffectiveFontPath(M.MYRIAD)
        local font=row.data and row.data.timer
        if row.font~=path and M:ApplyRegionFont(label,path,font and font.fontSize or 18,font and font.outline or "MONOCHROME,THICKOUTLINE")then row.font=path end
    end
    if key=="balance"then UpdateBalance(o,row,view)
    else UpdateRow(o,row,key,view,gap)end
    o.resourceAnimating=true;P.Animate(o)
    return true
end
