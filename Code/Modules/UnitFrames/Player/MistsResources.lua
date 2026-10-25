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
local function Text(parent,size,y)
    local t=parent:CreateFontString(nil,"OVERLAY")
    t:SetPoint("CENTER",parent,"CENTER",0,y or 0)
    M:ApplyRegionFont(t,M:EffectiveFontPath(M.MYRIAD),size,"THICKOUTLINE")
    t:SetTextColor(1,1,1,1);return t
end
local function Rotate(t,degrees)
    -- Same UV convention used by the existing imported combo-point art.
    local angle=math.rad(degrees);local c,s=math.cos(angle),math.sin(angle)
    local function corner(x,y)return .5+(x*c-y*s)*math.sqrt(2),.5+(x*s+y*c)*math.sqrt(2)end
    if degrees==0 then t:SetTexCoord(0,1,0,1);return end
    local a,b=corner(-.5,-.5);local d,e=corner(-.5,.5)
    local g,h=corner(.5,-.5);local j,k=corner(.5,.5)
    t:SetTexCoord(a,b,d,e,g,h,j,k)
end
local function BuildRow(o,key)
    local data=M.MistsResourceData[key]
    local row={frame=Frame(o.frame,data.width,60),leaves={},data=data}
    row.frame:SetPoint("CENTER")
    for i,d in ipairs(data.leaves)do
        local f=Frame(row.frame,d.w,d.h,i+1);f:Hide()
        local v=Frame(f,d.w,d.h);v:SetPoint("CENTER")
        local leaf={frame=f,visual=v,data=d};row.leaves[i]=leaf
        if d.kind=="model"then
            local model=CreateFrame("PlayerModel",nil,v);model:SetSize(d.w,d.h);model:SetPoint("CENTER")
            model:EnableMouse(false);model:SetFrameLevel(v:GetFrameLevel()+1)
            model.resourceFile=d.file;model.resourcePosition=d.position;model.resourceSequence=d.sequence or 0
            if model.SetKeepModelOnHide then model:SetKeepModelOnHide(false)end
            model:SetScript("OnModelLoaded",I.ResourceModelLoaded)
            model:SetScript("OnShow",I.ResourceModelRestart);model:Hide();leaf.model=model
        else
            local t=Texture(v,d.file,d.w,d.h,0,0)
            t:SetBlendMode(d.blend);t:SetVertexColor(unpack(d.color))
            leaf.texture=t
        end
    end
    if key=="arcane"then row.timer=Text(row.frame,20,-65)end
    if key=="embers"then
        row.fills={}
        for i=1,4 do
            local f=Frame(row.frame,20,35,1);f:Hide()
            local t=Texture(f,"EmberFill.tga",20,35)
            t:ClearAllPoints();t:SetPoint("BOTTOM",f,"BOTTOM",0,0)
            row.fills[i]={frame=f,texture=t}
        end
    end
    return row
end
local function BuildBalance(o)
    local row={frame=Frame(o.frame,340,60)};row.frame:SetPoint("CENTER")
    local f=row.frame
    row.background=Texture(f,"Wglass.tga",240,15,0,1,"BACKGROUND")
    row.background:SetVertexColor(.08,.08,.08,.8)
    row.lunar=Texture(f,"Wglass.tga",240,15,0,1)
    row.solar=Texture(f,"Wglass.tga",240,15,0,1)
    if row.solar.SetGradient and CreateColor then
        row.solar:SetGradient("HORIZONTAL",CreateColor(1,.09,.11,1),CreateColor(1,.6,.157,1))
        row.lunar:SetGradient("HORIZONTAL",CreateColor(0,0,.427,1),CreateColor(1,0,.396,1))
    elseif row.solar.SetGradientAlpha then
        row.solar:SetGradientAlpha("HORIZONTAL",1,.09,.11,1,1,.6,.157,1)
        row.lunar:SetGradientAlpha("HORIZONTAL",0,0,.427,1,1,0,.396,1)
    else
        row.solar:SetVertexColor(1,.35,.1,1);row.lunar:SetVertexColor(.35,.1,1,1)
    end
    row.border=Texture(f,"EclipseBar",512,200,7,5,"OVERLAY")
    row.sunBase=Texture(f,"Sun",42,42,150,1);row.sunBase:SetVertexColor(0,0,0,1)
    row.moonBase=Texture(f,"Moon",42,42,-150,1);row.moonBase:SetVertexColor(0,0,0,1)
    row.sun=Texture(f,"Sun",38,38,150,1,"OVERLAY")
    row.moon=Texture(f,"Moon",38,38,-150,1,"OVERLAY")
    row.marker=f:CreateTexture(nil,"OVERLAY");row.marker:SetSize(30,30)
    row.marker:SetAtlas("Gamepad_Shp_Circle_64")
    row.left=f:CreateTexture(nil,"OVERLAY");row.left:SetSize(40,33)
    row.left:SetAtlas("charactercreate-icon-requiredarrow");row.left:SetRotation(math.pi/2)
    row.right=f:CreateTexture(nil,"OVERLAY");row.right:SetSize(32,32)
    row.right:SetAtlas("charactercreate-icon-requiredarrow");row.right:SetRotation(math.pi*1.5)
    row.text=Text(f,18,35)
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
    row.power=power
    row.sun:SetShown(solar or both or power>=100)
    row.moon:SetShown(lunar or both or power<=-100)
    row.solar:SetShown(both or power>=100 or solar and power>0)
    row.lunar:SetShown(both or power<=-100 or lunar and power<0)
    -- A signed -100..100 axis; neither side depends on a selected target.
    row.marker:ClearAllPoints();row.marker:SetPoint("CENTER",row.frame,"CENTER",power*1.2,1)
    local fraction=both and 1 or math.abs(power)/100
    row.solar:SetWidth(math.max(.001,240*fraction));row.solar:SetTexCoord(1-fraction,1,0,1)
    row.solar:ClearAllPoints();row.solar:SetPoint("RIGHT",row.frame,"CENTER",120,1)
    row.lunar:SetWidth(math.max(.001,240*fraction));row.lunar:SetTexCoord(0,fraction,0,1)
    row.lunar:ClearAllPoints();row.lunar:SetPoint("LEFT",row.frame,"CENTER",-120,1)
    row.text:SetText(tostring(math.floor(math.abs(power)+.5)))
    local direction=Query(GetEclipseDirection)
    row.left:SetShown(both or direction=="moon")
    row.right:SetShown(both or direction=="sun")
end
local function UpdateRow(o,row,key,view,gap)
    local amount,maximum,expiration=State(key,view.preview)
    row.amount,row.maximum,row.expiration=amount,maximum,expiration
    for _,leaf in ipairs(row.leaves)do
        local d=leaf.data
        I.CachedPoint(leaf,"point",leaf.frame,"CENTER",row.frame,"CENTER",d.x+(d.slot-(row.data.count+1)/2)*gap,d.y)
        local active=d.slot<=maximum and amount+1e-7>=d.threshold
        if active~=leaf.active then
            local previous=leaf.active;leaf.active=active;leaf.at=GetTime()
            leaf.phase=active and d.animate and "enter"or(previous and d.exit and "exit"or nil)
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
        for i,fill in ipairs(row.fills)do
            local fraction=M.Clamp(amount-i+1,0,1)
            I.CachedPoint(fill,"point",fill.frame,"CENTER",row.frame,"CENTER",(i-2.5)*(60+gap),0)
            fill.frame:SetShown(i<=maximum and fraction>0)
            fill.texture:SetHeight(math.max(.001,35*fraction))
            fill.texture:SetTexCoord(0,1,1-fraction,1)
            if brimstone then fill.texture:SetVertexColor(1,1,1,1)
            else fill.texture:SetVertexColor(.945098,1,.968628,1)end
        end
    end
end
function P.Animate(o)
    local key=o.mistsResourceMode;local row=o.mistsResources and o.mistsResources[key]
    if not row or not row.frame:IsShown()then return end
    local now=GetTime()
    if key=="balance"then
        local x=100-200*((now%3)/3)
        I.CachedPoint(row,"left",row.left,"CENTER",row.frame,"CENTER",x,2)
        I.CachedPoint(row,"right",row.right,"CENTER",row.frame,"CENTER",-x,2)
        return
    end
    local animating=false
    for _,leaf in ipairs(row.leaves)do
        local d=leaf.data
        if leaf.frame:IsShown()then
            local scale,alpha,angle=1,d.alpha,0
            if leaf.phase then
                local progress=M.Clamp((now-leaf.at)/(leaf.phase=="enter"and .1 or .25),0,1)
                scale=leaf.phase=="enter"and progress or 1-progress
                alpha=alpha*(leaf.phase=="enter"and 1 or 1-progress)
                angle=leaf.phase=="enter"and 90*(1-progress)or 0
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
                elseif leaf.angle~=angle then Rotate(leaf.texture,d.rotation+angle);leaf.angle=angle end
            elseif leaf.model then
                leaf.model.resourceFacing=math.rad(angle)
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
        row=key=="balance"and BuildBalance(o)or BuildRow(o,key);o.mistsResources[key]=row
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
        if row.font~=path and M:ApplyRegionFont(label,path,key=="arcane"and 20 or 18,"THICKOUTLINE")then row.font=path end
    end
    if key=="balance"then UpdateBalance(o,row,view)
    else UpdateRow(o,row,key,view,gap)end
    o.resourceAnimating=true;P.Animate(o)
    return true
end
