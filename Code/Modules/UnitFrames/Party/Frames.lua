local _,M=...
local P={};M.PartyFrames=P
local ART="Interface\\AddOns\\MangUI\\Assets\\"
local MEDIA=ART.."PartyFrames\\"
local classes={DEATHKNIGHT="DKnight",DEMONHUNTER="DHunter",DRUID="Druid",EVOKER="Evoker",
    HUNTER="Hunter",MAGE="Mage",MONK="Monk",PALADIN="Paladin",PRIEST="Priest",ROGUE="Rogue",
    SHAMAN="Shaman",WARLOCK="Warlock",WARRIOR="Warrior"}
local roles={TANK="UI-LFG-RoleIcon-Tank",HEALER="UI-LFG-RoleIcon-Healer",DAMAGER="UI-LFG-RoleIcon-DPS"}
local previewClasses={"DRUID","WARRIOR","PRIEST","MAGE","ROGUE"}
local previewRoles={"DAMAGER","TANK","HEALER","DAMAGER","DAMAGER"}
local previewNames={"Aldric","Thorne","Elowen","Kael","Sylas"}
local previewPowers={{0,"MANA",0,0,1},{1,"RAGE",1,0,0},{0,"MANA",0,0,1},
    {0,"MANA",0,0,1},{3,"ENERGY",1,1,0}}
local numberColors={Curse={.61960786581,0,1,1},Disease={.90196084976,1,.30588236451,1},
    Magic={.30196079611,.67058825493,1,1},Poison={0,1,.14509804547,1}}
local portraitColors={Curse={.49019610882,0,1,1},Disease={.76470595598,1,0,1},
    Magic={0,.70588237047,1,1},Poison={0,1,.10980392992,1}}
-- WA TextureBase samples a sqrt(2)-wide UV square when full rotation is
-- enabled, including at zero degrees. Keep the screenshot's region dimensions.
local rotationCrop=1/math.sqrt(2)-1
function P.ConfigurePortraits(view)
    for i=0,4 do
        local portrait=view.nodes["party"..i.."Portrait"]
        local metal=view.nodes["party"..i.."Metal"]
        if portrait and portrait.portrait3D and metal then
            -- Native models have square viewports. Draw the whole portrait
            -- surface underneath the metal rim rather than over its corners.
            local level=math.max(1,metal.frame:GetFrameLevel()-1)
            portrait.frame:SetFrameLevel(level)
            portrait.portraitModel:SetFrameLevel(level)
        end
    end
end
local party1Geometry={
    Number={-90,5,1,48},Name={20,-22,1,22},Background={0,0,300,150},
    Power={14,0,84,6},Health={18,10,98,10},Metal={0,0,300,150},Glass={0,0,300,150},
    Portrait={-58,-2,40,40},Dead={-58,-2,60,60},AvatarBlack={-58,-9,105,105},
    AvatarGlass={-58,-9,105,105},Offline={-56,-3,40,40},AFK={-52,-5,45,45},
    LevelBackground={-40,-30,60,60},Level={-38,-28,1,18},Leader={-40,30,50,50},
    Class={-78,-15,30,30},Role={-120,0,32,32},Hitbox={0,0,150,50}}
local fullRotation={Background=true,Metal=true,Glass=true,Dead=true,AvatarBlack=true,
    AvatarGlass=true,LevelBackground=true,Leader=true}
local function EnsureParty1Auras(design)
    local index={};for _,n in ipairs(design.nodes or {})do index[n.id]=n end
    local member=index.party1Frame
    if not member or member.partyAuraRevision==1 then return end
    local auras=index.party1Debuffs
    if auras then auras.hideCooldownNumbers=true;auras.cooldownReverse=true end
    local label=index.party1DebuffLabel1
    if label then label.enabled=false end
    member.partyAuraRevision=1
end
local function EnsureParty1Range(design)
    local index={};for _,n in ipairs(design.nodes or {})do index[n.id]=n end
    local member=index.party1Frame
    if not member or member.partyRangeRevision==1 then return end
    local changes={Number={field="color",value={.27843138576,.27843138576,.27843138576,.49706971645}},
        Metal={field="color",value={.19607844949,.19607844949,.19607844949,1}},
        Power={field="alpha",value=.3},Health={field="alpha",value=.3}}
    for suffix,change in pairs(changes)do
        local n=index["party1"..suffix]
        if n then
            n.conditions=n.conditions or {}
            local condition={field="partyOutOfRange",unit="party1",op="==",value=1,changes={change}}
            -- Original WA lets the dispel color override the gray member number.
            if suffix=="Number"then table.insert(n.conditions,1,condition)
            else n.conditions[#n.conditions+1]=condition end
        end
    end
    member.partyRangeRevision=1
end
local function CorrectParty1(design)
    local index={};for _,n in ipairs(design.nodes or {}) do index[n.id]=n end
    local member=index.party1Frame
    if not member or member.partyLayoutRevision==1 then return end
    for suffix,geometry in pairs(party1Geometry) do
        local n=index["party1"..suffix]
        if n then
            n.x,n.y,n.width,n.height=unpack(geometry)
            n.point="CENTER";n.anchor="CENTER";n.scale=1
            n.rotation=0;n.mirror=false;n.mirrorY=false
            n.cropX=fullRotation[suffix] and rotationCrop or 0;n.cropY=n.cropX
            if n.kind=="texture" then
                n.textureWrapMode=(suffix=="Dead" or suffix=="Leader" or suffix=="Class" or suffix=="Role")
                    and "CLAMPTOBLACKADDITIVE" or "CLAMP"
            end
            if n.kind=="text" then n.fontPath=M.MYRIAD;n.autoWidth=true end
        end
    end
    member.partyLayoutRevision=1
end
local function DispelConditions(unit,colors)
    local result={}
    for _,kind in ipairs({"Curse","Disease","Magic","Poison"}) do
        result[#result+1]={field="partyDispel",unit=unit,op="==",value=kind,
            changes={{field="color",value=M.Copy(colors[kind])}}}
    end
    return result
end
local function Templates()
    local nodes={}
    local function Node(id,label,kind,parent,x,y,w,h,layer,unit,extra)
        local n={id=id,label=label,kind=kind,parent=parent,scope="party",unit=unit or "player",
            x=x,y=y,width=w,height=h,scale=1,point="CENTER",anchor="CENTER",alpha=1,
            enabled=true,color={1,1,1,1},binding="static",layer=layer,rules={},conditions={}}
        for key,value in pairs(extra or {}) do n[key]=value end
        nodes[#nodes+1]=n;return n
    end
    -- Rebase the five WA centers around their combined bounding box. The player
    -- remains 60 units left of the other rows, with a 90-unit vertical spacing.
    Node("partyFrames","队伍框体","group",nil,284.11764705882,-462.35294117647,360,510,1200,"player",
        {compound="partyFrames",screenAnchor="TOPLEFT",scale=.85})
    for i=0,4 do
        local unit=i==0 and "player" or "party"..i
        local id="party"..i;local layer=1210+i*40
        Node(id.."Frame",i==0 and "玩家框体" or "队友"..i.."框体","group","partyFrames",
            i==0 and -30 or 30,180-i*90,300,150,layer,unit,{compound="partyMember",partyRow=true,partyIndex=i})
        local function Part(suffix,label,kind,x,y,w,h,order,extra)
            extra=extra or {};extra.internal=true;extra.partyIndex=i;extra.visibleUnit=unit
            return Node(id..suffix,label,kind,id.."Frame",x,y,w,h,layer+order,unit,extra)
        end
        Part("Number","成员编号","text",-90,5,40,48,2,
            {text=i==0 and "P" or tostring(i),font="Myriad",fontSize=40,justify="LEFT",outline="OUTLINE",
                shadowX=5,shadowY=-5,conditions=DispelConditions(unit,numberColors)})
        Part("Name","成员姓名","text",20,-22,1,22,3,
            {binding="name",partyName=true,nameColor=true,font="Myriad",fontSize=14,justify="LEFT",
                outline="OUTLINE",shadowX=3,shadowY=-3,autoWidth=true})
        Part("Background","框体背景","texture",0,0,300,150,4,{file=ART.."PartyFrameBG",desaturate=true})
        Part("Power","资源进度","bar",14,0,84,6,5,
            {binding="power",file=MEDIA.."Wglass.tga",powerColor=true,smooth=true,
                color={1,.94901960784,.00392156863,1},background={0,0,0,.43939334154},
                conditions={{field="powertype",unit=unit,op="==",value=0,changes={{field="color",value={0,.5647059083,1,1}}}},
                    {field="powertype",unit=unit,op="==",value=1,changes={{field="color",value={1,.00392156886,0,1}}}},
                    {field="powertype",unit=unit,op="==",value=2,changes={{field="color",value={1,.501960814,.011764707,1}}}},
                    {field="powertype",unit=unit,op="==",value=3,changes={{field="color",value={1,.835294187,.298039228,1}}}},
                    {field="powertype",unit=unit,op="==",value=6,changes={{field="color",value={.396078467,1,.94901967,1}}}}}})
        Part("Health","生命进度","bar",18,10,98,10,6,
            {binding="health",file=MEDIA.."MangUI_GlassB.tga",color={0,1,.42745098039,1},background={0,0,0,0}})
        Part("Metal","框体金属","texture",0,0,300,150,7,{file=ART.."PartyFrame",desaturate=true})
        Part("Glass","框体玻璃","texture",0,0,300,150,8,{file=ART.."PartyFrameGlass",desaturate=true,blend="ADD",alpha=.6})
        Part("Portrait","成员头像","portrait",-58,-2,40,40,9,
            {rules={{test="partyDead",unit=unit,invert=true}},conditions=DispelConditions(unit,portraitColors)})
        Part("Dead","死亡提示","texture",-58,-2,60,60,10,{file=ART.."PartyDead",rules={{test="partyDead",unit=unit}}})
        Part("AvatarBlack","头像黑色渐变","texture",-58,-9,105,105,11,
            {file=ART.."PartyAvatarBlack",color={0,0,0,1},alpha=.5})
        Part("AvatarGlass","头像玻璃","texture",-58,-9,105,105,12,{file=ART.."PartyAvatarGlass",blend="ADD",alpha=.5})
        Part("Offline","离线提示","texture",-56,-3,40,40,13,
            {file=ART.."PartyOffline",rules={{test="connected",unit=unit,invert=true}}})
        Part("AFK","暂离提示","texture",-52,-5,45,45,14,
            {file=ART.."PartyAFK",color={.98823535442,1,1,1},rules={{test="partyAFK",unit=unit}}})
        Part("LevelBackground","等级背景","texture",-40,-30,60,60,15,{file=ART.."PartyLevel"})
        Part("Level","成员等级","text",-38,-28,30,18,16,
            {binding="level",font="Myriad",fontSize=12,outline="OUTLINE",justify="CENTER",shadowX=3,shadowY=-3})
        Part("Leader","队长标识","texture",-40,30,50,50,17,{file=ART.."PartyLeader",rules={{test="leader",unit=unit}}})
        Part("Class","职业图标","texture",-78,-15,30,30,18,{binding="partyClass",file=MEDIA.."Class\\Druid icon.blp"})
        Part("Role","职责图标","texture",-120,0,32,32,19,{binding="partyRole",rules={{test="partyRole",unit=unit}}})
        local auras=Part("Debuffs","减益效果","auras",100,5,20,20,20,
            {filter="HARMFUL",count=40,perRow=10,spacing=2,point="LEFT",anchor="CENTER"})
        Part("Hitbox","成员点击区域","hitbox",0,0,150,50,25)
        Node(id.."PowerBorder","资源描边","border",id.."Power",0,0,86,8,layer+5,unit,
            {internal=true,partyIndex=i,visibleUnit=unit,color={0,0,0,1}})
        -- The WA disables both debuff duration and stack labels initially.
        for j,binding in ipairs({"auraTime","auraStacks"}) do
            Node(id.."DebuffLabel"..j,"减益文字","text",auras.id,2,j==1 and 2 or -2,64,20,layer+21,unit,
                {internal=true,partyIndex=i,binding=binding,enabled=false,font="Myriad",fontSize=j==1 and 14 or 12,
                    point=j==1 and "BOTTOMRIGHT" or "CENTER",anchor=j==1 and "BOTTOMRIGHT" or "CENTER"})
        end
    end
    return nodes
end
local function ApplyParty1Standard(design)
    local index,sources={},{}
    for _,n in ipairs(design.nodes or {})do
        index[n.id]=n
        if n.partyIndex==1 then sources[#sources+1]=n end
    end
    local root,standard=index.partyFrames,index.party1Frame
    if not root or not standard or root.partyStyleRevision==1 then return end
    for _,i in ipairs({0,2,3,4})do
        local prefix="party"..i;local unit=i==0 and "player" or prefix
        local row=index[prefix.."Frame"]
        if row then
            local ids={party1=unit}
            for _,source in ipairs(sources)do ids[source.id]=prefix..source.id:sub(7) end
            local function Remap(value)
                if type(value)=="string"then return ids[value]or value end
                if type(value)~="table"then return value end
                local result={};for key,child in pairs(value)do result[key]=Remap(child)end
                return result
            end
            local layerOffset=row.layer-standard.layer
            for _,source in ipairs(sources)do
                local target=index[ids[source.id]]
                if target then
                    local copy=Remap(source)
                    copy.partyIndex=i;copy.layer=source.layer+layerOffset;copy.label=target.label
                    if source==standard then
                        -- Preserve each member's placement while copying its appearance.
                        copy.x,copy.y=target.x,target.y
                        copy.point,copy.anchor,copy.screenAnchor=target.point,target.anchor,target.screenAnchor
                    elseif source.id=="party1Number"then copy.text=i==0 and "P" or tostring(i) end
                    for key in pairs(target)do target[key]=nil end
                    for key,value in pairs(copy)do target[key]=value end
                end
            end
        end
    end
    root.partyStyleRevision=1
end
local function InitializeSettings(design)
    local index={};for _,n in ipairs(design.nodes)do index[n.id]=n end
    local root,player,first=index.partyFrames,index.party0Frame,index.party1Frame
    if not root or root.partySettingsRevision==1 then return end
    local sx,sy=(player.x or 0)*(player.scale or 1),(player.y or 0)*(player.scale or 1)
    root.x=(root.x or 0)+sx;root.y=(root.y or 0)+sy
    for i=0,4 do
        local row=index["party"..i.."Frame"]
        row.x=((row.x or 0)*(row.scale or 1)-sx)/(row.scale or 1)
        row.y=((row.y or 0)*(row.scale or 1)-sy)/(row.scale or 1)
    end
    root.partySpacing=math.abs(first.y or -90);root.partyMemberX=first.x or 60
    root.partyPlayerX=0;root.hidePartyNumbers=false;root.hidePartyPlayer=false
    local hp,name=index.party1Health,index.party1Name
    root.partyMaterialPath="";root.partyMaterialName="默认"
    root.partyHealthColor=M.Copy(hp.healthColor or hp.color)
    root.partyHealthEndColor=M.Copy(hp.healthGradientEnd or root.partyHealthColor)
    root.partyFontPath=name.fontPath or M.MYRIAD;root.partyFontName=name.fontName or "Myriad"
    root.partyNameSize=name.fontSize or 14;root.partySettingsRevision=1
end
function P.SyncNodes(design)
    local index={};for _,n in ipairs(design.nodes)do index[n.id]=n end
    local root=index.partyFrames;if not root or root.partySettingsRevision~=1 then return end
    if root.hidePartyInRaid==nil then root.hidePartyInRaid=false end
    if root.partyHealthGradient==nil then root.partyHealthGradient=false end
    root.partyPlayerX=M.Clamp(root.partyPlayerX or 0,-150,150)
    root.partySpacing=M.Clamp(root.partySpacing or 90,45,150)
    for i=0,4 do
        local id="party"..i;local row=index[id.."Frame"]
        if row then
            row.x=i==0 and root.partyPlayerX or (root.partyMemberX or 60)
            row.y=-i*root.partySpacing
            row.enabled=i~=0 or root.hidePartyPlayer~=true
            index[id.."Number"].enabled=root.hidePartyNumbers~=true
            for _,suffix in ipairs({"Health","Power"})do
                local bar=index[id..suffix]
                bar.partyOriginalFile=bar.partyOriginalFile or bar.file
                bar.file=root.partyMaterialPath~="" and root.partyMaterialPath or bar.partyOriginalFile
            end
            local hp=index[id.."Health"]
            hp.healthColor=M.Copy(root.partyHealthColor);hp.healthGradientEnd=M.Copy(root.partyHealthEndColor)
            hp.healthGradient=root.partyHealthGradient==true
            for _,suffix in ipairs({"Name","Level"})do
                local text=index[id..suffix]
                text.fontPath=root.partyFontPath;text.fontName=root.partyFontName
                if suffix=="Name"then text.fontSize=math.max(.1,root.partyNameSize or 14)end
            end
        end
    end
end
function M:EnsurePartyFramesModule(design)
    local seen={};for _,n in ipairs(design.nodes or {}) do seen[n.id]=true end
    for _,n in ipairs(Templates()) do if not seen[n.id] then design.nodes[#design.nodes+1]=n end end
    CorrectParty1(design)
    EnsureParty1Range(design)
    EnsureParty1Auras(design)
    ApplyParty1Standard(design)
    for _,n in ipairs(design.nodes)do if n.id=="partyFrames"then n.label="队伍框体";break end end
    InitializeSettings(design)
    P.SyncNodes(design)
end
M.moduleIDs.partyFrames=true
M:EnsurePartyFramesModule(M.defaults)
if M.recordedDefaults then M:EnsurePartyFramesModule(M.recordedDefaults) end
local function Call(fn,...)
    if type(fn)~="function"then return end
    local ok,a,b,c,d=pcall(fn,...);if ok then return a,b,c,d end
end
local function Number(value)
    if not M.Compat.Readable(value)or type(value)~="number"or value~=value
        or value==math.huge or value==-math.huge then return end
    return value
end
local previewDebuffs={
    {589,"Spell_Shadow_ShadowWordPain"},{172,"Spell_Shadow_AbominationExplosion"},
    {980,"Spell_Shadow_CurseOfSargeras"},{702,"Spell_Shadow_CurseOfMannoroth"},
    {1490,"Spell_Shadow_ChillTouch"},{1714,"Spell_Shadow_CurseOfTounges"},
    {710,"Spell_Shadow_Cripple"},{5782,"Spell_Shadow_Possession"},
    {339,"Spell_Nature_StrangleVines"},{122,"Spell_Frost_FrostNova"},
    {118,"Spell_Nature_Polymorph"},{853,"Spell_Holy_SealOfMight"},
    {408,"Ability_Rogue_KidneyShot"},{1833,"Ability_CheapShot"},
    {703,"Ability_Rogue_Garrote"},{1943,"Ability_Rogue_Rupture"},
    {772,"Ability_Gouge"},{7386,"Ability_Warrior_Sunder"},
    {6343,"Spell_Nature_ThunderClap"},{770,"Spell_Nature_FaerieFire"}}
function P.PreviewDebuff(member,slot)
    local item=previewDebuffs[(member*4+slot-1)%#previewDebuffs+1]
    local icon=Call(C_Spell and C_Spell.GetSpellTexture or GetSpellTexture,item[1])
    return M.Compat.Readable(icon)and icon or "Interface\\Icons\\"..item[2]
end
function P.SameArea(unit)
    local map=C_Map
    if not map then return false end
    local playerMap=Number(Call(map.GetBestMapForUnit,"player"))
    local memberMap=Number(Call(map.GetBestMapForUnit,unit))
    -- Use the best individual map, including its floor/submap. A shared parent
    -- or map group is not enough, and missing map data is not a positive match.
    if not playerMap or playerMap<=0 or playerMap~=memberMap then return false end
    local phase=Call(UnitInPhase,unit)
    if M.Compat.Readable(phase)and phase==false then return false end
    return true
end
function P.OutOfRange(view,unit)
    if view.preview or not (unit and unit:match("^party[1-4]$"))or not M.Compat.Bool(Call(UnitExists,unit))
        or not M.Compat.Bool(Call(UnitIsConnected,unit))or not P.SameArea(unit)then return false end
    local px,py,pz,pi=Call(UnitPosition,"player")
    local ux,uy,uz,ui=Call(UnitPosition,unit)
    px,py,pz,pi=Number(px),Number(py),Number(pz),Number(pi)
    ux,uy,uz,ui=Number(ux),Number(uy),Number(uz),Number(ui)
    if pi and ui and pi~=ui then return false end
    if px and py and pz and ux and uy and uz and pi and ui then
        local dx,dy,dz=ux-px,uy-py,uz-pz
        return dx*dx+dy*dy+dz*dz>1600
    end
    local lib=LibStub and LibStub("LibRangeCheck-3.0",true)
    if not lib then return false end
    local minimum=Number(Call(lib.GetRange,lib,unit,true,false,0))
    -- A lower bound of 40 comes from a failed 40-yard check: distance >40.
    -- An upper bound above 40 or an unknown range does not prove that.
    return minimum~=nil and minimum>=40
end
function P.ConfigureTexture(o)
    local n=o.spec
    if n.partyIndex==nil or not n.textureWrapMode or n.binding=="partyRole" then return end
    o.texture:SetTexture(n.file,n.textureWrapMode,n.textureWrapMode)
    if o.texture.SetSnapToPixelGrid then o.texture:SetSnapToPixelGrid(false) end
    if o.texture.SetTexelSnappingBias then o.texture:SetTexelSnappingBias(0) end
    -- Apply after native SetRotation, which must not replace the WA UV range.
    local x,y=1+(n.cropX or 0),1+(n.cropY or 0)
    local l,r=.5-.5/x,.5+.5/x;local top,bottom=.5-.5/y,.5+.5/y
    if n.mirror then l,r=r,l end
    if n.mirrorY then top,bottom=bottom,top end
    o.texture:SetTexCoord(l,r,top,bottom)
end
function P.ConfigureText(o)
    local n=o.spec
    if n.partyIndex==nil then return end
    -- WA Auto text has no width constraint; its region is the natural string
    -- size, centered at the saved anchor even with LEFT justification.
    o.text:ClearAllPoints();o.text:SetPoint(n.justify or "CENTER",o.frame,n.justify or "CENTER")
    o.text:SetWidth(0);o.text:SetHeight(0)
    o.text:SetShadowColor(0,0,0,1);o.text:SetShadowOffset(n.shadowX or 0,n.shadowY or 0)
    o.shadow:Hide()
end
function P.LayoutText(o)
    if o.spec.partyIndex==nil then return false end
    if o.textWidthDirty then
        local w,h=o.text:GetStringWidth(),o.text:GetStringHeight()
        if M.Compat.Readable(w) and M.Compat.Readable(h) and type(w)=="number" and type(h)=="number" then
            o.frame:SetSize(math.max(1,w),math.max(1,h))
        end
        o.textWidthDirty=nil
    end
    return true
end
local function RefreshMemberHighlight(view,i)
    local id="party"..i
    local metal=view.nodes[id.."Metal"];local hit=view.nodes[id.."Hitbox"]
    if not metal or not metal.partyHighlight then return end
    local visible=not view.preview and hit and hit.frame:IsVisible()
        and M.Compat.Bool(UnitExists(hit.spec.unit))
    if not visible and hit then hit.partyHovered=false end
    local selected=visible and UnitIsUnit and M.Compat.Bool(UnitIsUnit(hit.spec.unit,"target"))
    local highlighted=not not (visible and (hit.partyHovered or selected))
    local state=view.cache and hit and view.cache[hit.spec.unit]
    local alpha=highlighted and .35*(state and state.partyOutOfRange and .19607844949 or 1)or 0
    if metal.partyHighlightAlpha~=alpha then
        metal.partyHighlight:SetAlpha(alpha)
        metal.partyHighlightAlpha=alpha
        metal.partyHighlighted=highlighted
    end
end
function P.RefreshHighlight(view)
    for i=0,4 do RefreshMemberHighlight(view,i)end
end
local function ConfigureMemberHighlight(view,i)
    local id="party"..i
    local metal=view.nodes[id.."Metal"];local hit=view.nodes[id.."Hitbox"]
    if not metal or not hit or metal.removed or hit.removed then return end
    if not metal.partyHighlight then
        local texture=metal.frame:CreateTexture(nil,"OVERLAY")
        texture:SetAllPoints(metal.frame);texture:SetBlendMode("ADD")
        texture:SetDesaturated(true);texture:SetVertexColor(1,1,1,1)
        metal.partyHighlight=texture
    end
    local n=metal.spec;local texture=metal.partyHighlight
    texture:SetTexture(n.file,n.textureWrapMode,n.textureWrapMode)
    local x,y=1+(n.cropX or 0),1+(n.cropY or 0)
    local l,r=.5-.5/x,.5+.5/x;local top,bottom=.5-.5/y,.5+.5/y
    if n.mirror then l,r=r,l end
    if n.mirrorY then top,bottom=bottom,top end
    texture:SetTexCoord(l,r,top,bottom)
    if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(false) end
    if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
    metal.partyHighlighted=nil
    metal.partyHighlightAlpha=nil
    if not view.preview then
        -- Cover the visible metal rim and level badge, rather than only the
        -- original 150x50 click rectangle. Layout changes occur during Apply.
        local ratio=(n.scale or 1)/(hit.spec.scale or 1)
        hit.frame:SetSize(math.max(hit.spec.width or 150,(n.width or 300)*x*.9*ratio),
            math.max(hit.spec.height or 50,(n.height or 150)*y*.86*ratio))
        if not hit.partyHighlightHooks then
            hit.frame:HookScript("OnEnter",function()hit.partyHovered=true;RefreshMemberHighlight(view,i)end)
            hit.frame:HookScript("OnLeave",function()hit.partyHovered=false;RefreshMemberHighlight(view,i)end)
            hit.frame:HookScript("OnHide",function()hit.partyHovered=false;RefreshMemberHighlight(view,i)end)
            hit.partyHighlightHooks=true
        end
    end
    RefreshMemberHighlight(view,i)
end
function P.ConfigureHighlight(view)
    for i=0,4 do ConfigureMemberHighlight(view,i)end
end
function P.ConfigureGroupVisibility(view)
    local gate=view.partyGroupGate
    if not gate or view.preview or InCombatLockdown() then return end
    local root=view.byID.partyFrames
    local _,instanceType=IsInInstance()
    local driver=(root and root.hidePartyInRaid and "[group:raid] hide; " or "")
        .."[group] show; "..(instanceType=="pvp" and "show" or "hide")
    if gate.partyDriver~=driver then
        RegisterStateDriver(gate,"visibility",driver);gate.partyDriver=driver
    end
end
function P.VisibilityParent(view,n,parent)
    if view.preview then return parent end
    if n.id=="partyFrames" then
        local gate=view.partyGroupGate
        if not gate then
            gate=CreateFrame("Frame",nil,parent,"SecureHandlerStateTemplate")
            gate:SetAllPoints(parent);gate:EnableMouse(false);view.partyGroupGate=gate
            for _,event in ipairs({"PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA",
                "UPDATE_BATTLEFIELD_STATUS","PLAYER_REGEN_ENABLED"})do gate:RegisterEvent(event)end
            gate:SetScript("OnEvent",function()P.ConfigureGroupVisibility(view)end)
            gate:SetScript("OnShow",function()
                if not view.applying then M:Safe("队伍刷新",M.Renderer.Update,view)end
            end)
        end
        P.ConfigureGroupVisibility(view)
        return gate
    end
    if not n.partyRow then return parent end
    view.partyGates=view.partyGates or {}
    local gate=view.partyGates[n.id]
    if not gate then
        gate=CreateFrame("Frame",nil,parent,"SecureHandlerStateTemplate")
        gate:SetAllPoints(parent);gate:EnableMouse(false);view.partyGates[n.id]=gate
        RegisterStateDriver(gate,"visibility","[@"..n.unit..",exists] show; hide")
        gate:SetScript("OnShow",function()
            if not view.applying then M:Safe("小队刷新",M.Renderer.Update,view,{[n.unit]=true}) end
        end)
    end
    return gate
end
function P.ExtendState(view,s)
    if not view.byID.partyFrames or not s.exists then return end
    if view.preview and view.hidden and view.hidden.party0Portrait then return end
    local unit=s.unit;local index=(unit=="player" or unit=="vehicle") and 0 or tonumber(unit and unit:match("^party([1-4])$"))
    if index==nil then return end
    local C=M.Compat
    if view.preview then
        s.partyClass=previewClasses[index+1];s.partyRole=previewRoles[index+1]
        s.leader=index==1
        s.name=previewNames[index+1]
        s.isPlayer=true
        local power=previewPowers[index+1]
        local powerColor=PowerBarColor and (PowerBarColor[power[2]] or PowerBarColor[power[1]])
        s.powerType=power[1];s.powerColor=s.powerColor or {}
        s.powerColor[1]=powerColor and powerColor.r or power[3]
        s.powerColor[2]=powerColor and powerColor.g or power[4]
        s.powerColor[3]=powerColor and powerColor.b or power[5]
        local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[s.partyClass]
        if color then s.nameColor={color.r,color.g,color.b};s.classColor=color end
        s.partyDispel=nil
    else
        local member=unit=="vehicle" and "player" or unit
        local _,class=UnitClass(member)
        s.partyClass=C.Readable(class) and class or nil
        local role=UnitGroupRolesAssigned and UnitGroupRolesAssigned(member)
        s.partyRole=C.Readable(role) and roles[role] and role or nil
        view.partyDispelCache=view.partyDispelCache or {}
        local cache=view.partyDispelCache[unit] or {};view.partyDispelCache[unit]=cache
        local version=view.auraVersions and view.auraVersions[unit] or 0
        if cache.version~=version or GetTime()>=(cache.nextScan or 0) then
            cache.auras=C.Auras(unit,"HARMFUL",40,cache.auras)
            cache.kind=nil
            for _,a in ipairs(cache.auras) do
                local kind=a.dispelName
                if C.Readable(kind) and numberColors[kind] then cache.kind=kind;break end
            end
            cache.version=version;cache.nextScan=GetTime()+.2
        end
        s.partyDispel=cache.kind
    end
    s.partyDead=s.connected and (s.dead or s.healthRatio and s.healthRatio<=.01) or false
    s.partyAFK=s.connected and not s.partyDead and s.afk or false
    s.partyOutOfRange=index>0 and P.OutOfRange(view,unit)or false
end
function P.Texture(o,s)
    if o.spec.binding=="partyClass" then
        local class=classes[s.partyClass]
        if class and o.partyClass~=class then o.texture:SetTexture(M:TexturePath(o.spec,MEDIA.."Class\\"..class.." icon.blp"));o.partyClass=class end
    elseif o.spec.binding=="partyRole" then
        local atlas=roles[s.partyRole]
        if atlas and o.partyRole~=atlas then o.texture:SetAtlas(atlas,false);o.partyRole=atlas end
    end
end
function P.Name(name)
    -- Preserve whole UTF-8 characters; the original WA could cut a Chinese name
    -- in the middle of a byte sequence when applying its 20-byte name limit.
    if not M.Compat.Readable(name) then return name end
    if type(name)~="string" then return "" end
    local count,last=0,0
    for pos,char in name:gmatch("()([%z\1-\127\194-\244][\128-\191]*)") do
        count=count+1;if count>20 then return name:sub(1,last).."." end
        last=pos+#char-1
    end
    return name
end
function P.StartMovePreview()
    local R=M.Renderer
    local view=P.moveView
    if not view then view=R.New(UIParent,true);P.moveView=view;view.root:SetFrameStrata("HIGH") end
    local nodes={}
    for _,n in ipairs(M.db.design.nodes) do if M:ModuleID(n)=="partyFrames" then nodes[#nodes+1]=n end end
    view.root:Show();R.Apply(view,{nodes=nodes})
    view.root:SetScript("OnUpdate",function()R.Animate(view)end)
    return view
end
function P.StopMovePreview()
    if P.moveView then P.moveView.root:Hide();P.moveView.root:SetScript("OnUpdate",nil) end
end
