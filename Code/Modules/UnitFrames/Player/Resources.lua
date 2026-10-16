local _,M=...
local C,B,R=M.Compat,M.MainBarLayout,M.Renderer
local unpack=unpack or table.unpack
local private=M.RendererInternals
local Cache=private.Cache
local CachedValue=private.CachedValue
local CachedPair=private.CachedPair
local CachedColor=private.CachedColor
local CachedPoint=private.CachedPoint
local ResourceModelPose=private.ResourceModelPose
local ResourceModelRestart=private.ResourceModelRestart

local resourceRuneIndices={5,6,3,4,1,2}
local deathRuneColor={.86274516582489,0,1,1}
local normalRuneColor={1,1,1,1}
local resourceStyles={
    ROGUE={count=5,file="Rogue_bar4",models={308401,253465},sizes={65,40},color={1,.82,.22},slotScales={1,.85,1,.85,1}},
    DEATHKNIGHT={count=6,file="DK_bar_Blue",models={166892,166374},sizes={100,100},color={.3,.7,1},slotScales={.85,1,.85,1,.85,1}},
    SHAMAN={count=5,file="Shaman_bar",models={253465},sizes={100},color={.35,.7,1},slotScales={1,.85,1,.85,1}},
}
resourceStyles.DRUID=resourceStyles.ROGUE
local runeStyles={
    {file="DK_bar_Blue",color={.3,.7,1},models={166892,166374},sizes={100,100}},
    {file="DK_bar_Green",color={.3,1,.45},models={240935},sizes={75}},
    {file="DK_bar_Red",color={1,.2,.25},models={165728},sizes={150}},
}
local zeroPosition={0,0,0}
local resourceModelPositions={
    [308401]={-10,.5,-1.5},[240935]={-20,0,1},
}
local resourceSequences={
    ROGUE={{1,0},{10,0},{20,0},{30,0},{40,0}},
    DEATHKNIGHT={{0,0},{0,10},{40},{40},{1},{1}},
}
resourceSequences.DRUID=resourceSequences.ROGUE
-- WA applies the same animation to every leaf of a resource point. Keep the
-- point's art and model effects together while preserving its fixed layout.
local function ResourceCoords(texture,degrees)
    if degrees==0 then texture:SetTexCoord(0,1,0,1);return end
    local angle=math.rad(degrees)
    local c,s=math.cos(angle),math.sin(angle)
    local function corner(x,y)
        return .5+(x*c-y*s)*math.sqrt(2),.5+(x*s+y*c)*math.sqrt(2)
    end
    local ulx,uly=corner(-.5,-.5)
    local llx,lly=corner(-.5,.5)
    local urx,ury=corner(.5,-.5)
    local lrx,lry=corner(.5,.5)
    texture:SetTexCoord(ulx,uly,llx,lly,urx,ury,lrx,lry)
end
local function ResourceAnimate(o)
    if o.resourceAnimating==false then return end
    local now=GetTime()
    local animating=false
    for _,slot in ipairs(o.resourceSlots) do
        local phase=slot.resourcePhase
        local elapsed=phase and math.max(0,now-(slot.resourcePhaseAt or now)) or 0
        local scale,alpha,angle=1,1,0
        if phase=="enter" then
            local progress=M.Clamp(elapsed/.1,0,1)
            scale=math.max(.001,progress)
            angle=90*(1-progress)
            if progress==1 then slot.resourcePhase=nil end
        elseif phase=="exit" then
            local progress=M.Clamp(elapsed/.25,0,1)
            scale=math.max(.001,1-progress)
            alpha=1-progress
            if progress==1 then
                slot.resourcePhase=nil
                if not slot.resourceKeepSlot then slot:Hide() end
                slot.visual:Hide()
            end
        end
        if slot.resourcePhase~="exit" or alpha>0 then
            local scaleChanged=CachedValue(slot,"visualScale",slot.visual,"SetScale",scale)
            CachedValue(slot,"visualAlpha",slot.visual,"SetAlpha",alpha)
            if slot.resourceAngle~=angle then
                ResourceCoords(slot.base,45+angle);ResourceCoords(slot.art,angle)
                slot.resourceAngle=angle
            end
            for j,model in ipairs(slot.models) do
                model.resourceFacing=math.rad(angle)
                CachedValue(slot,"modelFacing"..j,model,"SetFacing",model.resourceFacing)
                if scaleChanged and scale==1 and slot.visual:IsShown() then ResourceModelRestart(model) end
            end
        end
        animating=animating or slot.resourcePhase~=nil
    end
    o.resourceAnimating=animating
end
local resourceAura={}
local function ResourceAuraStacks()
    for i=1,40 do
        local aura=C.Aura("player",i,"HELPFUL",resourceAura)
        if not aura then break end
        local spellID=C.Number(aura.spellId)
        if spellID==1283511 or spellID==53817 then return C.Number(aura.applications,0) end
    end
    return 0
end
local function ResourcePaint(view,o)
    o.resourceAnimating=nil
    local n=o.spec;local f=o.frame
    local _,playerClass=UnitClass("player")
    local fallbackRunes=view.preview and not resourceStyles[playerClass]
    local class=fallbackRunes and "DEATHKNIGHT" or playerClass
    local style=resourceStyles[class]
    if not style then f:Hide();return end
    local parent=view.nodes[n.parent] and view.nodes[n.parent].spec
    local gap=M.Clamp(parent and parent.resourceSpacing or 0,-20,20)
    local step=50+gap
    CachedPair(o,"resourceSize",f,"SetSize",50+(style.count-1)*step,60)
    CachedValue(o,"resourceScale",f,"SetScale",M:NodeScale(n)*(class=="DEATHKNIGHT" and 1/.9 or 1))
    if parent and parent.resourceOriginRevision==1 then
        CachedPoint(o,"resourcePoint",f,"CENTER",f:GetParent(),"CENTER",0,0)
    else
        CachedPoint(o,"resourcePoint",f,"LEFT",f:GetParent(),"CENTER",(n.x or 122.22)+(class=="DEATHKNIGHT" and -42.22 or 0),n.y or -68.89)
    end
    local amount=0
    local targetChanged=not view.preview and view.resourceTargetChanged
    if targetChanged then view.resourceTargetChanged=nil end
    local targetExists=UnitExists("target")
    if view.preview then amount=style.count
    elseif class=="ROGUE" or class=="DRUID" then
        if targetExists and not targetChanged and GetComboPoints then
            amount=C.Number(GetComboPoints("player","target"),0)
        elseif targetExists and not targetChanged then
            amount=C.Number(UnitPower("player",4),0)
        end
    elseif class=="SHAMAN" then amount=ResourceAuraStacks() end
    for i,slot in ipairs(o.resourceSlots) do
        local exists=i<=style.count
        local active=exists and i<=amount
        local progress=0
        local deathRune=false
        if exists and class=="DEATHKNIGHT" then
            if fallbackRunes then
                active=true
            else
                local rune=resourceRuneIndices[i]
                local start,duration,ready
                if GetRuneCooldown then start,duration,ready=GetRuneCooldown(rune) end
                deathRune=GetRuneType and GetRuneType(rune)==4 or false
                active=view.preview or C.Bool(ready)
                if not active and C.Number(duration,0)>0 then
                    progress=M.Clamp((GetTime()-C.Number(start,GetTime()))/duration,0,1)
                end
            end
        end
        if not exists then slot.resourcePhase=nil;slot.resourceActive=false
        elseif (class=="ROGUE" or class=="DRUID") and not view.preview and (targetChanged or not targetExists) then
            slot.resourcePhase=nil;slot.resourceActive=false
        elseif slot.resourceActive~=active then
            local previous=slot.resourceActive
            slot.resourceActive=active
            slot.resourcePhase=active and "enter" or (previous==true and "exit" or nil)
            slot.resourcePhaseAt=GetTime()
        end
        slot.resourceKeepSlot=class=="DEATHKNIGHT"
        local finishing=slot.resourcePhase=="exit"
        local shown=exists and (active or finishing or slot.resourceKeepSlot)
        if slot:IsShown()~=shown then slot:SetShown(shown) end
        if exists then
            if slot.visual:IsShown()~=(active or finishing) then slot.visual:SetShown(active or finishing) end
            CachedPoint(slot,"slotPoint",slot,"CENTER",f,"LEFT",25+(i-1)*step,0)
            local level=f:GetFrameLevel()
            if slot.layerClass~=class or slot.layerLevel~=level then
                local visualLevel=level+2
                local artAboveModels=class=="DEATHKNIGHT" or class=="SHAMAN"
                slot:SetFrameLevel(level+1)
                slot.visual:SetFrameLevel(visualLevel)
                slot.artFrame:SetFrameLevel(visualLevel+(artAboveModels and 3 or 1))
                for j,model in ipairs(slot.models) do
                    model:SetFrameLevel(visualLevel+j+(artAboveModels and 0 or 1))
                end
                slot.layerClass,slot.layerLevel=class,level
            end
            local itemScale=style.slotScales[i] or 1
            CachedPair(slot,"baseSize",slot.base,"SetSize",50*itemScale,50*itemScale)
            CachedPoint(slot,"basePoint",slot.base,"CENTER",slot.visual,"CENTER",0,-5*itemScale)
            CachedPair(slot,"artFrameSize",slot.artFrame,"SetSize",40*itemScale,40*itemScale)
            CachedPair(slot,"artSize",slot.art,"SetSize",40*itemScale,40*itemScale)
            local file=style.file;local modelIDs=style.models;local modelSizes=style.sizes
            local tint=style.color
            if class=="DEATHKNIGHT" then
                local runeStyle=runeStyles[math.ceil(i/2)]
                file,tint,modelIDs,modelSizes=runeStyle.file,runeStyle.color,runeStyle.models,runeStyle.sizes
            end
            local path=M:TexturePath(n,M.ART..file,"resourceArt"..i)
            if slot.artFile~=path then slot.art:SetTexture(path);slot.artFile=path end
            local runeColor=deathRune and deathRuneColor or normalRuneColor
            CachedColor(slot,"baseColor",slot.base,"SetVertexColor",runeColor)
            CachedColor(slot,"artColor",slot.art,"SetVertexColor",runeColor)
            CachedValue(slot,"baseAlpha",slot.base,"SetAlpha",(active or finishing) and .8 or .25)
            CachedValue(slot,"artAlpha",slot.art,"SetAlpha",(active or finishing) and 1 or .25)
            local cooling=class=="DEATHKNIGHT" and not active
            if slot.cooldown:IsShown()~=cooling then slot.cooldown:SetShown(cooling) end
            CachedColor(slot,"cooldownColor",slot.cooldown,"SetStatusBarColor",tint)
            CachedValue(slot,"cooldownValue",slot.cooldown,"SetValue",progress)
            for j,model in ipairs(slot.models) do
                R.SuppressMovementModel(view,model)
                local id=not fallbackRunes and modelIDs[j]
                if id then
                    local changed=not slot.modelIDs or slot.modelIDs[j]~=id
                    local size=modelSizes[j] or 65
                    local viewport=Cache(slot)["modelSize"..j]
                    local resized=not viewport or viewport[1]~=size*itemScale or viewport[2]~=size*itemScale
                    CachedPair(slot,"modelSize"..j,model,"SetSize",size*itemScale,size*itemScale)
                    model.resourcePosition=resourceModelPositions[id] or zeroPosition
                    model.resourceFile=id
                    local sequences=resourceSequences[class]
                    local sequence=sequences and sequences[i] and sequences[i][j] or 0
                    local sequenceChanged=model.resourceSequence~=sequence
                    model.resourceSequence=sequence
                    if changed then
                        model.resourceFacing=math.rad(slot.resourceAngle or 0)
                        slot.modelReady[j]=ResourceModelRestart(model)
                        Cache(slot)["modelFacing"..j]=nil
                    end
                    if changed or resized then ResourceModelPose(model) end
                    if not model.movementSuppressed and (changed or sequenceChanged) then model:SetAnimation(sequence) end
                    local modelShown=not view.movementModelsHidden and (active or finishing) and slot.modelReady[j]~=false
                    if model:IsShown()~=modelShown then model:SetShown(modelShown) end
                else
                    model.resourcePosition=nil
                    model.resourceFile=nil
                    if model:IsShown() then model:Hide() end
                end
            end
            slot.modelIDs=not fallbackRunes and modelIDs or nil
        end
    end
    ResourceAnimate(o)
end

M.RendererInternals.resourceRuneIndices=resourceRuneIndices
M.RendererInternals.deathRuneColor=deathRuneColor
M.RendererInternals.normalRuneColor=normalRuneColor
M.RendererInternals.resourceStyles=resourceStyles
M.RendererInternals.runeStyles=runeStyles
M.RendererInternals.zeroPosition=zeroPosition
M.RendererInternals.resourceModelPositions=resourceModelPositions
M.RendererInternals.resourceSequences=resourceSequences
M.RendererInternals.ResourceCoords=ResourceCoords
M.RendererInternals.ResourceAnimate=ResourceAnimate
M.RendererInternals.ResourceAuraStacks=ResourceAuraStacks
M.RendererInternals.ResourcePaint=ResourcePaint
