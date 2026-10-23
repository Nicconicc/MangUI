local _,M=...
local D={};M.TargetDistance=D
-- Class tokens keep the saved thresholds independent of the UI language.
D.classes={
    {"WARRIOR","战士",5},{"PALADIN","圣骑士",5},{"HUNTER","猎人",35},
    {"ROGUE","潜行者",5},{"PRIEST","牧师",40},{"DEATHKNIGHT","死亡骑士",5},
    {"SHAMAN","萨满祭司",40},{"MAGE","法师",40},{"WARLOCK","术士",40},{"DRUID","德鲁伊",5},
    {"MONK","武僧",5},{"DEMONHUNTER","恶魔猎手",5},{"EVOKER","唤魔师",25},
}
local classIcons={WARRIOR="Warrior",PALADIN="Paladin",HUNTER="Hunter",ROGUE="Rogue",PRIEST="Priest",
    DEATHKNIGHT="DKnight",SHAMAN="Shaman",MAGE="Mage",WARLOCK="Warlock",DRUID="Druid",
    MONK="Monk",DEMONHUNTER="DHunter",EVOKER="Evoker"}
function D.ClassIcon(token)
    return "Interface\\AddOns\\MangUI\\Assets\\Library\\PartyFrames\\Class\\"..classIcons[token].." icon.blp"
end
function D.AvailableClasses()
    local interface=M.Compat.interface or 0
    -- Forever's modern client exposes only the original Classic classes.
    local expansion=interface==16001 and 1 or math.floor(interface/10000)
    local introduced={DEATHKNIGHT=3,MONK=5,DEMONHUNTER=7,EVOKER=10}
    local _,playerClass=UnitClass("player")
    local result={}
    for _,class in ipairs(D.classes) do
        if not introduced[class[1]] or expansion>=introduced[class[1]] or (interface~=16001 and class[1]==playerClass) then
            result[#result+1]=class
        end
    end
    return result
end
local classColors={
    WARRIOR={.78,.61,.43},PALADIN={.96,.55,.73},HUNTER={.67,.83,.45},ROGUE={1,.96,.41},PRIEST={1,1,1},
    DEATHKNIGHT={.77,.12,.23},SHAMAN={0,.44,.87},MAGE={.25,.78,.92},WARLOCK={.53,.53,.93},DRUID={1,.49,.04},
    MONK={0,1,.6},DEMONHUNTER={.64,.19,.79},EVOKER={.2,.58,.5},
}
function D.ClassColor(token)
    local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if color and color.r and color.g and color.b then return color.r,color.g,color.b end
    local fallback=classColors[token] or {1,1,1};return fallback[1],fallback[2],fallback[3]
end
local function Number(value)
    if type(value)~="number" or (issecretvalue and issecretvalue(value)) then return end
    if value~=value or value==math.huge or value==-math.huge then return end
    return value
end
local function Call(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b,c,d=pcall(fn,...);if ok then return a,b,c,d end
end
function D.SpellInput(value)
    if type(value)~="string" then return "" end
    return (value:gsub("^%s+",""):gsub("%s+$",""))
end
local function FillRanges(group)
    if group.showDistanceNumber==nil then group.showDistanceNumber=true end
    if group.hideFriendlyDistanceNumber==nil then group.hideFriendlyDistanceNumber=false end
    group.fontSize=M.Clamp(Number(group.fontSize) or 20,.1,10000)
    if type(group.distanceNumberColor)~="table" then group.distanceNumberColor={1,1,1,1} end
    if group.showOnRing==nil then group.showOnRing=true end
    if group.showOnNameplate==nil then group.showOnNameplate=true end
    group.distanceIconSize=M.Clamp(Number(group.distanceIconSize) or 20,1,256)
    group.distanceX=M.Clamp(Number(group.distanceX) or -5,-150,150)
    group.distanceY=M.Clamp(Number(group.distanceY) or 20,-40,40)
    for _,class in ipairs(D.classes) do
        local token=class[1];local key="range"..token
        group[key]=M.Clamp(Number(group[key]) or class[3],1,100)
        if group["rangeSpell"..token]==nil then group["rangeSpell"..token]="" end
        if group["rangeManual"..token]==nil then group["rangeManual"..token]=false end
    end
end
function D.SyncNodes(design)
    local group,display,number
    for _,n in ipairs(design.nodes) do
        if n.id=="targetDistance" then group=n elseif n.id=="targetDistanceDisplay" then display=n elseif n.id=="targetDistanceNumber" then number=n end
    end
    if not group then return end
    FillRanges(group)
    group.width=math.max(240,math.abs(group.distanceX)*2+group.distanceIconSize)
    group.height=math.max(70,math.abs(group.distanceY)*2+group.distanceIconSize)
    if display then display.width=group.width;display.height=group.height end
    if number then number.width=math.max(80,group.fontSize*3);number.height=math.max(32,group.fontSize*1.5) end
end
local function Templates()
    local group={id="targetDistance",label="目标距离监控",kind="group",compound="targetDistance",scope="player",unit="player",
        x=0,y=0,width=240,height=70,scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,locked=true,
        layer=950,rules={},conditions={}}
    FillRanges(group)
    return {group,
        {id="targetDistanceNumber",label="目标距离数字",kind="targetdistancenumber",parent="targetDistance",internal=true,locked=true,
            scope="player",unit="player",x=0,y=-55,width=80,height=32,scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=952},
        {id="targetDistanceDisplay",label="目标距离监控",kind="targetdistance",parent="targetDistance",internal=true,locked=true,
            scope="player",unit="player",x=0,y=0,width=240,height=70,scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=951},
    }
end
function M:EnsureTargetDistanceModule(design)
    local seen,group,main={}
    for _,n in ipairs(design.nodes) do
        seen[n.id]=true
        if n.id=="targetDistance" then group=n elseif n.id=="mainComposite" then main=n end
        if n.id=="targetDistance" or n.id=="targetDistanceDisplay" then n.label="目标距离监控" end
    end
    if group then
        if group.showOnRing==nil then group.showOnRing=not main or main.targetDistanceHint~=false end
        FillRanges(group)
    end
    for _,n in ipairs(Templates()) do
        if not seen[n.id] then
            if n.id=="targetDistance" and main then n.showOnRing=main.targetDistanceHint~=false end
            design.nodes[#design.nodes+1]=n
        end
    end
    if main then main.targetDistanceHint=nil end
end
M.moduleIDs.targetDistance=true
M:EnsureTargetDistanceModule(M.defaults)
if M.recordedDefaults then M:EnsureTargetDistanceModule(M.recordedDefaults) end
function D.Threshold(group,token)
    if not token then local _,playerClass=Call(UnitClass,"player");token=playerClass end
    for _,class in ipairs(D.classes) do
        if token==class[1] then return M.Clamp(Number(group["range"..token]) or class[3],1,100) end
    end
end
local function RangeBoolean(value)
    if issecretvalue and issecretvalue(value) then return end
    if value==true or value==1 then return true end
    if value==false or value==0 then return false end
end
function D.SpellInRange(value)
    local text=D.SpellInput(value);if text=="" then return end
    local identifier=text:match("^%d+$") and tonumber(text) or text
    local result=RangeBoolean(Call(C_Spell and C_Spell.IsSpellInRange,identifier,"target"))
    if result~=nil then return result end
    -- The legacy numeric overload is a spellbook slot, not a spell ID.
    -- Resolve IDs to localized names before using that client API.
    local name=type(identifier)=="string" and identifier or Call(C_Spell and C_Spell.GetSpellName,identifier)
    if not name then name=Call(GetSpellInfo,identifier) end
    if not name then
        local info=Call(C_Spell and C_Spell.GetSpellInfo,identifier)
        name=type(info)=="table" and info.name or nil
    end
    if type(name)=="string" and name~="" then return RangeBoolean(Call(IsSpellInRange,name,"target")) end
end
function D.OutOfRange(group)
    if not Call(UnitExists,"target") or not Call(UnitCanAttack,"player","target") then return false end
    local reaction=Number(Call(UnitReaction,"target","player"))
    if reaction and reaction>=5 then return false end
    local _,token=Call(UnitClass,"player");if type(token)~="string" then return false end
    if group["rangeManual"..token]~=true then
        -- Unknown spells/invalid targets are not evidence of being out of range.
        -- Cooldowns, resources and line of sight do not participate in this check.
        return D.SpellInRange(group["rangeSpell"..token])==false
    end
    local threshold=D.Threshold(group,token);if not threshold then return false end
    local lib=LibStub and LibStub("LibRangeCheck-3.0",true)
    if not lib then return false end
    -- The lower bound is exclusive: a failed 35-yard check means distance >35.
    -- Never guess from the upper bound or reuse a cached result after a target change.
    local minimum=Number(Call(lib.GetRange,lib,"target",true,false,0))
    return minimum~=nil and minimum>=threshold
end
function D.State(group)
    if group.enabled==false or group.showOnNameplate==false then return end
    if Call(UnitIsPlayer,"target") then return end
    local plate=Call(C_NamePlate and C_NamePlate.GetNamePlateForUnit,"target")
    if plate and D.OutOfRange(group) then return plate end
end
function D.DecorationState(view,force)
    local main=view.byID and view.byID.mainComposite
    local decoration=view.byID and view.byID.wa080cd4c4fb
    local group=view.byID and view.byID.targetDistance
    if view.preview or not main or main.enabled==false or not group or group.enabled==false or group.showOnRing==false
        or not decoration or decoration.enabled==false then return false end
    local now=GetTime()
    if not force and view.nextDecorationRange and now<view.nextDecorationRange then return view.decorationOutOfRange end
    view.nextDecorationRange=now+.1
    view.decorationOutOfRange=D.OutOfRange(group)
    return view.decorationOutOfRange
end
function D.Build(view,o)
    o.distanceIcon=o.frame:CreateTexture(nil,"OVERLAY")
    o.distanceIcon:SetSize(20,20);o.distanceIcon:SetBlendMode("BLEND")
    o.distanceIcon:SetVertexColor(.984313786,1,.964705944,1)
    local atlasLoaded=o.distanceIcon.SetAtlas and pcall(o.distanceIcon.SetAtlas,o.distanceIcon,"common-icon-redx",false)
    if not atlasLoaded then o.distanceIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady") end
    if view.preview then
        o.previewNameplate=CreateFrame("Frame",nil,o.frame)
        o.previewNameplate:SetSize(240,70)
        o.previewNameplate:SetPoint("CENTER",o.frame,"CENTER",-105,0)
        o.previewNameplate:EnableMouse(false)
        -- Classic client layout: a 128x16 border, with a 103.75x10 channel.
        -- Scale both axes together; the level box is part of the same texture.
        local plateScale=1.4
        o.previewPlate=CreateFrame("StatusBar",nil,o.previewNameplate);o.previewPlate:SetSize(103.75*plateScale,10*plateScale)
        o.previewPlate:SetPoint("CENTER",o.previewNameplate,"CENTER",-8.625*plateScale,.5*plateScale)
        o.previewPlate:SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
        o.previewPlate:SetMinMaxValues(0,1);o.previewPlate:SetValue(1);o.previewPlate:SetStatusBarColor(0,.12,1)
        o.previewPlate:EnableMouse(false)
        o.previewBorder=o.previewPlate:CreateTexture(nil,"OVERLAY",nil,0)
        o.previewBorder:SetTexture("Interface\\Tooltips\\Nameplate-Border")
        o.previewBorder:SetTexCoord(0,1,.5,1)
        o.previewBorder:SetSize(128*plateScale,16*plateScale)
        o.previewBorder:SetPoint("CENTER",o.previewNameplate,"CENTER")
        o.previewBorder:SetDesaturated(true);o.previewBorder:SetVertexColor(1,.82,0,1)
        o.previewLevel=o.previewPlate:CreateFontString(nil,"OVERLAY")
        o.previewLevel:SetFont(M:DefaultFontPath(),12,"OUTLINE")
        o.previewLevel:SetPoint("CENTER",o.previewBorder,"RIGHT",-11*plateScale,0)
        o.previewLevel:SetTextColor(1,.82,0,1);o.previewLevel:SetText("80")
        o.previewName=o.previewPlate:CreateFontString(nil,"OVERLAY");o.previewName:SetFont(M:DefaultFontPath(),12,"OUTLINE")
        o.previewName:SetPoint("BOTTOM",o.previewBorder,"TOP",0,4*plateScale)
        o.previewName:SetJustifyH("CENTER")
        o.previewName:SetTextColor(1,1,1,1)
        o.previewRing=o.frame:CreateTexture(nil,"ARTWORK")
        o.previewRingRed=o.frame:CreateTexture(nil,"OVERLAY")
        for _,ring in ipairs({o.previewRing,o.previewRingRed}) do
            ring:SetSize(100,100);ring:SetPoint("CENTER",o.frame,"CENTER",110,0)
        end
        o.previewRingRed:SetDesaturated(true);o.previewRingRed:SetVertexColor(1,0,0,1)
    end
end
function D.Configure(view,o)
    if o.previewName then
        local font=M:EffectiveFontPath(M:DefaultFontPath())
        for _,label in ipairs({o.previewName,o.previewLevel})do label:SetFont(font,12,"OUTLINE")end
    end
    o.nextDistanceUpdate=nil;o.anchoredPlate=nil
    local group=o.module or {}
    local size=M.Clamp(Number(group.distanceIconSize) or 20,1,256)
    o.distanceX=M.Clamp(Number(group.distanceX) or -5,-150,150)
    o.distanceY=M.Clamp(Number(group.distanceY) or 20,-40,40)
    o.distanceIcon:SetSize(size,size)
    if view.preview then
        o.previewNameplate:SetShown(not view.unlockMode)
        o.previewRing:SetShown(not view.unlockMode);o.previewRingRed:SetShown(not view.unlockMode)
        o.distanceIcon:SetParent(view.unlockMode and o.frame or o.previewNameplate)
        o.distanceIcon:ClearAllPoints()
        if view.unlockMode then o.distanceIcon:SetPoint("CENTER",o.frame,"CENTER")
        else o.distanceIcon:SetPoint("CENTER",o.previewNameplate,"CENTER",o.distanceX,o.distanceY)end
        local ring=view.byID and view.byID.wa080cd4c4fb or {}
        local file=ring.file or "Interface\\AddOns\\MangUI\\Assets\\Library\\CenterLight"
        o.previewRing:SetTexture(M:TexturePath(o.spec,file,"previewRing"));o.previewRingRed:SetTexture(M:TexturePath(o.spec,file,"previewRingRed"))
        o.previewRing:SetBlendMode(ring.blend or "BLEND");o.previewRingRed:SetBlendMode(ring.blend or "BLEND")
        o.previewRing:SetDesaturated(ring.desaturate or false)
        o.previewRing:SetVertexColor(unpack(ring.color or {1,1,1,1}))
        o.previewRingSpin={texture=o.previewRing,spec={rotation=ring.rotation or 0,
            spinPeriod=(ring.spinPeriod or 20)/.3,castSpinPeriod=(ring.castSpinPeriod or .5)/.3}}
        o.previewRingStarted=GetTime()
        o.previewRing:SetAlpha(1);o.previewRingRed:SetAlpha(0)
    else
        o.frame:SetSize(size,size);o.frame:SetFrameStrata("HIGH")
        o.distanceIcon:ClearAllPoints()
        o.distanceIcon:SetPoint("CENTER",o.frame,"CENTER")
        o.frame:Hide()
    end
end
function D.Paint(view,o,animateOnly)
    if o.spec.enabled==false or (view.hidden and view.hidden[o.spec.id]) or (not view.preview and o.module and o.module.enabled==false) then
        o.anchoredPlate=nil;o.frame:Hide();return
    end
    if view.preview then
        if view.unlockMode then o.distanceIcon:Hide();o.frame:Hide();return end
        local name=M:T("目标名称（姓名板）")
        o.distanceIcon:SetShown(not o.module or o.module.showOnNameplate~=false)
        o.previewName:SetText(name)
        if not M.db.useGlobalFont then M:ApplyLocaleFont(o.previewName,name)end
        local now=GetTime()
        M.Renderer.SpinTexture(view,o.previewRingSpin,now)
        o.previewRingRed:SetRotation(o.previewRingSpin.spinAngle)
        local red=(1-math.cos((now-o.previewRingStarted)*2*math.pi/6))/2
        if o.module and o.module.showOnRing==false then red=0 end
        o.previewRing:SetAlpha(1-red);o.previewRingRed:SetAlpha(red)
        o.frame:Show();return
    end
    if animateOnly and o.nextDistanceUpdate and GetTime()<o.nextDistanceUpdate then return end
    o.nextDistanceUpdate=GetTime()+.1
    local plate=D.State(o.module or {})
    if not plate then o.anchoredPlate=nil;o.frame:Hide();return end
    if o.anchoredPlate~=plate then
        o.frame:ClearAllPoints();o.frame:SetPoint("CENTER",plate,"CENTER",o.distanceX,o.distanceY)
        o.anchoredPlate=plate
    end
    o.frame:Show()
end
function D.Event(view,event)
    if event=="PLAYER_TARGET_CHANGED" or event=="NAME_PLATE_UNIT_ADDED" or event=="NAME_PLATE_UNIT_REMOVED" then
        if view then view.nextDecorationRange=nil end
        if M.Renderer and M.Renderer.UpdateDecorationRange then M.Renderer.UpdateDecorationRange(view,true) end
        local o=view and view.nodes and view.nodes.targetDistanceDisplay
        if o then D.Paint(view,o,false) end
        local number=view and view.nodes and view.nodes.targetDistanceNumber
        if number then
            if event=="PLAYER_TARGET_CHANGED"then D.ResetNumber(number)end
            number.nextNumberUpdate=nil;D.PaintNumber(view,number,false)
        end
    end
end

-- A readable coordinate distance is preferred. Spell/item range probes only
-- provide bounds: their upper bound is an estimate, never an exact yard count.
local function FormatDistance(distance)
    if distance>40 then return "＞40" end
    return tostring(math.floor(math.max(0,distance)+.5))
end
-- Coordinates are usable only when both units have readable positions in
-- the same world map. Never substitute map percentages or a nearest NPC.
local function Position(unit)
    local x,y,z,map=Call(UnitPosition,unit)
    x,y,z,map=Number(x),Number(y),Number(z),Number(map)
    if not x or not y or not z or not map or map<0 then return end
    -- Some clients return a zero vector when the position is unavailable.
    if x==0 and y==0 and z==0 then return end
    return x,y,z,map
end
function D.ExactDistance()
    local squared,valid=Call(UnitDistanceSquared,"target")
    squared=Number(squared)
    if squared and squared>=0 and RangeBoolean(valid)==true then return math.sqrt(squared) end
    local px,py,pz,pm=Position("player")
    local tx,ty,tz,tm=Position("target")
    if not px or not tx or pm~=tm then return end
    return Number(math.sqrt((tx-px)^2+(ty-py)^2+(tz-pz)^2))
end
function D.NumberState(group)
    if group.enabled==false or group.showDistanceNumber==false then return end
    if RangeBoolean(Call(UnitExists,"target"))~=true then return end
    if RangeBoolean(Call(UnitIsUnit,"player","target"))==true then return end
    if group.hideFriendlyDistanceNumber==true then
        local reaction=Number(Call(UnitReaction,"target","player"))
        if RangeBoolean(Call(UnitIsFriend,"player","target"))==true or (reaction and reaction>=5)then return end
    end
    local exact=D.ExactDistance()
    if exact then return FormatDistance(exact) end
    local lib=LibStub and LibStub("LibRangeCheck-3.0",true)
    if not lib then return end
    local minimum,maximum=Call(lib.GetRange,lib,"target",true,false,0)
    minimum,maximum=Number(minimum),Number(maximum)
    if not minimum or minimum<0 then return end
    -- The lower bound is exclusive. Only a proven >40 result gets this label.
    if minimum>=40 then return "＞40" end
    if maximum and maximum>=minimum and maximum<=40 then return FormatDistance(maximum),true end
    -- Unknown or a bound spanning 40 yards must not be reported as >40.
end
-- The settings preview uses a fixed comparison row. Live and unlocked
-- placement continue to use the saved numeric node/module coordinates.
function D.NumberPreviewPosition(geometry)
    local group=geometry.targetDistance
    return group.x+230*group.s,group.y
end
function D.PreviewBounds(geometry)
    local group=geometry.targetDistance;local number=geometry.targetDistanceNumber
    return group.x-225*group.s,group.y-math.max(55,number.h/2)*group.s,
        group.x+(230+number.w/2)*group.s,group.y+math.max(70,number.h/2)*group.s
end
function D.BuildNumber(view,o)
    o.distanceNumber=o.frame:CreateFontString(nil,"OVERLAY")
    o.distanceNumber:SetPoint("CENTER");o.distanceNumber:SetJustifyH("CENTER");o.distanceNumber:SetWordWrap(false)
    o.distanceNumber:SetShadowColor(0,0,0,1);o.distanceNumber:SetShadowOffset(1,-1)
end
function D.ResetNumber(o)
    o.nextNumberUpdate=nil;o.numberText=nil
end
function D.ConfigureNumber(view,o)
    local group=o.module or {};local font=group.fontPath
    if not font or font=="" then font=group.font=="Myriad" and M.MYRIAD or M:DefaultFontPath() end
    font=M:EffectiveFontPath(font)
    local size=math.max(.1,group.fontSize or 20)
    local ok,loaded=pcall(o.distanceNumber.SetFont,o.distanceNumber,font,size,"OUTLINE")
    if not ok or loaded==false then o.distanceNumber:SetFont(M:DefaultFontPath(),size,"OUTLINE") end
    o.distanceNumber:SetTextColor(unpack(group.distanceNumberColor or {1,1,1,1}))
    if view.preview and not view.unlockMode then
        o.frame:ClearAllPoints();o.frame:SetPoint("CENTER",view.nodes.targetDistance.frame,"CENTER",230,0)
    end
    D.ResetNumber(o)
end
function D.PaintNumber(view,o,animateOnly)
    local group=o.module or {}
    if o.spec.enabled==false or group.enabled==false or group.showDistanceNumber==false
        or (view.hidden and view.hidden[o.spec.id]) then
        D.ResetNumber(o);o.distanceNumber:SetText("");o.frame:Hide();return
    end
    local now=GetTime()
    if view.preview then
        o.numberText="25"
    elseif not animateOnly or not o.nextNumberUpdate or now>=o.nextNumberUpdate then
        -- Display each measurement immediately, with no interpolated yards.
        o.nextNumberUpdate=now+.1
        local text,estimated=D.NumberState(group)
        o.numberText=text and ((estimated and "≈" or "")..text) or nil
    end
    local text=o.numberText
    if o.distanceNumber:GetText()~=(text or "")then o.distanceNumber:SetText(text or "")end
    o.frame:SetShown(text~=nil)
end
