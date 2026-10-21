local _,M=...
local I,S,W=M.RaidBuffMonitor,M.PlayerSkillMonitor,M.WeaponEnhancements
local Safe,Number,Readable=I.Safe,I.Number,I.Readable
local expiryCurve
local function HideConnector(connector)
    connector.row:Hide();connector.link:Hide()
    if connector.joint then connector.joint:Hide()end
end
local function ExpiryCurve()
    if not expiryCurve and C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType then
        expiryCurve=C_CurveUtil.CreateCurve();expiryCurve:SetType(Enum.LuaCurveType.Step)
        expiryCurve:AddPoint(0,0);expiryCurve:AddPoint(.001,1);expiryCurve:AddPoint(180,0)
    end
    return expiryCurve
end
local function NativeAvailable()
    local interface=M.Compat.interface or 0
    if interface~=16001 and interface<120000 then return false end
    if not C_XMLUtil or not C_XMLUtil.GetTemplateInfo then return false end
    if not C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")and not InCombatLockdown()and C_AddOns then Safe(C_AddOns.LoadAddOn,"Blizzard_AuraContainer")end
    return C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")~=nil
end
local function ResolveSlot(slot,entry)
    local ids,keys={},{}
    slot.spells=I.Options(entry);slot.spell=I.Resolve(entry)
    slot.weapon=I.Kind(entry)~="buff"and entry.type~="weaponAura"
    for _,spell in ipairs(slot.spells)do
        if I.Kind(entry)=="buff"then I.ExpandBuffRanks(spell)end
        if spell.id then ids[spell.id]=true end
        if spell.ids then for id in pairs(spell.ids)do ids[id]=true end
        elseif spell.id then ids[spell.id]=true end
        keys[#keys+1]=spell.value..":"..tostring(spell.id)..":"..tostring(spell.revision)
        if not spell.id then I.RequestBuffName(spell.value)end
    end
    local key=table.concat(keys,"|")..I.Kind(entry)..":"..entry.value;local changed=key~=slot.lookupKey
    slot.ids,slot.lookupKey=ids,key;slot.texture:SetTexture(slot.spell.icon or 134400)
    return changed
end
local function Bind(slot)
    slot.pending=nil
    if slot.container then slot.container:SetEnabled(false)end
    slot.bound=false
    for _,frame in ipairs(slot.nativeFrames or {})do frame.gate:SetAlpha(1)end
    if not next(slot.ids)then return end
    if not slot.container then
        local container=CreateFrame("AuraContainer",nil,slot,"CustomAuraContainerTemplate")
        container:SetEnabled(false);container:SetPoint("TOPLEFT",slot,"TOPLEFT",0,0);slot.container=container;slot.nativeFrames={}
        container:AddAuraGroup("missing","HELPFUL",{maxFrameCount=0,initializeFrame=function(frame)
            frame:SetSize(40,40);frame:EnableMouse(false)
            -- Chain native gates so either healthy alternative suppresses the
            -- reminder without comparing protected presence or duration values.
            frame.gate=CreateFrame("Frame",nil,slot.lastGate or slot.base);frame.gate:SetAllPoints();frame.gate:EnableMouse(false)
            slot.lastGate=frame.gate;slot.texture:SetParent(frame.gate)
            slot.timerGate:SetParent(frame.gate)
            if #slot.nativeFrames==0 and frame.SetDurationText then
                frame.nativeTime=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
                frame.nativeTime:SetAlpha(0);frame:SetDurationText(frame.nativeTime,S.DurationTextOptions())
            end
            slot.nativeFrames[#slot.nativeFrames+1]=frame
        end})
        container:SetFlowLayoutAnchorPoint("TOPLEFT");container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right,AnchorUtil.FlowDirection.Down)
        container:SetFlowLayoutMaximumLineSize(40.001)
        container:SetAuraGroupLayout("missing",{elementSpacing=0,lineSpacing=0,elementWidth=40,elementHeight=40})
    end
    slot.container:SetUnit("player")
    slot.container:SetAuraGroupCandidateFilters("missing",{includeSpellIDs=slot.ids})
    local count=0;for _ in pairs(slot.ids)do count=count+1 end
    slot.container:SetAuraGroupMaxFrameCount("missing",count)
    if slot.container.SetAuraGroupSortMethod and AuraContainerSortMethod and AuraContainerSortDirection then
        slot.container:SetAuraGroupSortMethod("missing",AuraContainerSortMethod.ExpirationOnly,AuraContainerSortDirection.Reverse)
    end
    slot.container:SetEnabled(true);slot.container:UpdateAllAuras();slot.bound=true
    slot.texture:SetParent(slot.lastGate or slot.base)
    slot.timerGate:SetParent(slot.lastGate or slot.base)
end
local function Icon(o,index)
    local slot=o.buffIcons[index];if slot then return slot end
    slot=CreateFrame("Frame",nil,o.frame);slot:SetSize(40,40);slot:EnableMouse(false);slot:EnableMouseMotion(true)
    slot.base=CreateFrame("Frame",nil,slot);slot.base:SetAllPoints();slot.base:EnableMouse(false)
    slot.texture=slot.base:CreateTexture(nil,"ARTWORK");slot.texture:SetAllPoints()
    slot.timerGate=CreateFrame("Frame",nil,slot.base);slot.timerGate:SetAllPoints();slot.timerGate:EnableMouse(false)
    -- Numeric/native countdowns must not use the interface-label font wrapper.
    slot.time=slot.timerGate:CreateFontString(nil,"OVERLAY")
    slot.time:SetFont(M:EffectiveFontPath(M.MYRIAD),16,"OUTLINE");slot.time:SetPoint("BOTTOM",slot,"TOP",0,7);slot.time:SetTextColor(1,1,1)
    slot.time:SetJustifyH("CENTER");slot.time:SetShadowColor(0,0,0,1);slot.time:SetShadowOffset(1,-1)
    slot.hand=slot.base:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");M:BindText(slot.hand)
    slot.hand:SetPoint("BOTTOM",slot.base,"BOTTOM",0,1);slot.hand:SetTextColor(1,1,1);slot.hand:SetWidth(40);slot.hand:SetWordWrap(false)
    slot:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        W.Tooltip(self.spell)
        if self.weapon then GameTooltip:AddLine(M:T(self.remaining and self.remaining>0 and "武器强化即将到期："or "缺少武器强化：")..W.SlotName(self.entry),1,.82,0,true)end
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave",function()GameTooltip:Hide()end)
    o.buffIcons[index]=slot;return slot
end
local function Decoration(o)
    if o.decoration then return o.decoration end
    local frame=CreateFrame("Frame",nil,o.frame);frame:EnableMouse(false)
    frame:SetFrameLevel(o.frame:GetFrameLevel())
    if frame.CreateLine then
        -- Keep the connector behind every addon panel while the caption stays
        -- on the guide frame's regular layer.
        local canvas=CreateFrame("Frame",nil,frame);canvas:SetAllPoints(frame);canvas:EnableMouse(false)
        canvas:SetFrameStrata("BACKGROUND")
        frame.connector={canvas=canvas}
        for _,name in ipairs({"row","link"})do
            local line=canvas:CreateLine(nil,"OVERLAY")
            if name=="link"then
                line:SetTexture(M.ART.."UI\\RaidBuffSoftLine.tga","CLAMP","CLAMP","LINEAR")
                line:SetVertexColor(1,1,1,.6);line:SetBlendMode("BLEND")
                if line.SetSnapToPixelGrid then line:SetSnapToPixelGrid(false)end
                if line.SetTexelSnappingBias then line:SetTexelSnappingBias(0)end
            else line:SetColorTexture(1,1,1,.6)end
            line:Hide();frame.connector[name]=line
        end
        if frame.CreateMaskTexture then
            local dot=canvas:CreateTexture(nil,"OVERLAY");dot:SetTexture("Interface\\Buttons\\WHITE8X8")
            dot:SetVertexColor(1,1,1,.6)
            local mask=canvas:CreateMaskTexture(nil,"OVERLAY")
            mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
            dot:AddMaskTexture(mask);frame.connector.joint=dot;frame.connector.jointMask=mask
        end
    end
    local title=frame:CreateFontString(nil,"OVERLAY");frame.title=title
    title:SetFont(M:EffectiveFontPath(M:DefaultFontPath()),19.2,"")
    title:SetHeight(24)
    title:SetText(I.DefaultGuideText());title:SetTextColor(1,1,1,1);title:SetJustifyH("CENTER");title:SetWordWrap(false)
    title:SetShadowColor(0,0,0,.8);title:SetShadowOffset(2,-2)
    frame:Hide();o.decoration=frame;return frame
end
local function LayoutDecoration(o,group,count)
    local frame=Decoration(o)
    if count==0 then frame:Hide();return end
    local text=I.GuideText(group)
    if frame.title:GetText()~=text then frame.title:SetText(text)end
    frame.title:SetShown(group.showGuideText~=false)
    local bounds=o.guideBounds
    local rowWidth=bounds and bounds.width or count*44-4
    local scale=math.max(.001,frame:GetEffectiveScale())
    local _,screenHeight=Safe(GetPhysicalScreenSize)
    local pixel=(PixelUtil and PixelUtil.GetPixelToUIUnitFactor and PixelUtil.GetPixelToUIUnitFactor()
        or 768/math.max(1,Number(screenHeight)or 768))/scale
    local uiScale=math.max(.001,UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()or 1)
    local effectiveScale=frame.title.GetEffectiveScale and frame.title:GetEffectiveScale()or frame:GetEffectiveScale()
    local fontScale=math.max(.001,effectiveScale/uiScale)
    local fontSize=I.GuideFontSize(group)/fontScale
    local fontPath=M:EffectiveFontPath(I.GuideFontPath(group))
    if not frame.layoutFontSize or math.abs(frame.layoutFontSize-fontSize)>.01 or frame.layoutFontPath~=fontPath then
        frame.title:SetFont(fontPath,fontSize,"")
        frame.title:SetHeight(math.max(24,fontSize*1.5))
        frame.title:SetShadowOffset(2/fontScale,-2/fontScale)
        frame.layoutFontSize,frame.layoutFontPath=fontSize,fontPath
    end
    local textWidth=(frame.title.GetUnboundedStringWidth and frame.title:GetUnboundedStringWidth()or frame.title:GetStringWidth())+2
    local width=math.ceil(math.max(rowWidth+144,textWidth+40)/pixel)*pixel
    local center=bounds and bounds.x or S.RowOffset(group,count)
    local centerY=bounds and bounds.y or -7
    local bodyHeight=bounds and bounds.height or 40
    if frame.layoutWidth~=width or frame.layoutRowWidth~=rowWidth or frame.layoutCenter~=center
        or frame.layoutPixel~=pixel or frame.layoutTextWidth~=textWidth
        or frame.layoutCenterY~=centerY or frame.layoutBodyHeight~=bodyHeight then
        local thickness,height=pixel,math.ceil((bodyHeight/2+16)/pixel)*pixel
        frame:ClearAllPoints();frame:SetPoint("TOP",o.frame,"CENTER",center,centerY);frame:SetSize(width,height)
        frame.title:ClearAllPoints();frame.title:SetPoint("CENTER",frame,"BOTTOM",0,thickness/2)
        frame.title:SetWidth(textWidth)
        frame.layoutWidth,frame.layoutRowWidth,frame.layoutCenter=width,rowWidth,center
        frame.layoutPixel,frame.layoutTextWidth=pixel,textWidth
        frame.layoutCenterY,frame.layoutBodyHeight=centerY,bodyHeight
    end
    frame:Show()
end
local function UpdateConnector(view,o)
    local frame=o.decoration;local connector=frame and frame.connector
    if not connector then return end
    local group=o.guideGroup or view.byID[o.spec.parent]
    local target=view.nodes[M.MainBarLayout.tokenID]
    if group.hideGuideLines or not frame:IsVisible()or not target or target.spec.enabled==false or not target.frame:IsVisible()then
        HideConnector(connector);return
    end
    -- Read only our own artwork frames. The external secure portrait anchor and
    -- Blizzard aura frames must never become layout dependencies of these lines.
    local cx,cy=frame:GetCenter();local tx,ty=target.frame:GetCenter()
    if not cx or not cy or not tx or not ty then HideConnector(connector);return end
    local ratio=target.frame:GetEffectiveScale()/frame:GetEffectiveScale()
    tx,ty=tx*ratio-cx,ty*ratio-cy
    local rx,ry=target.frame:GetWidth()*ratio/2,target.frame:GetHeight()*ratio/2
    local width,height,pixel,rowWidth=frame:GetWidth(),frame:GetHeight(),frame.layoutPixel,frame.layoutRowWidth
    local length=I.GuideLength(group)
    local opacity=I.GuideOpacity(group)
    if connector.opacity~=opacity then
        connector.row:SetColorTexture(1,1,1,opacity)
        connector.link:SetVertexColor(1,1,1,opacity)
        if connector.joint then connector.joint:SetVertexColor(1,1,1,opacity)end
        connector.opacity=opacity
    end
    local mouse=group.id=="mouseCircle"
    local horizontalLength=mouse and 0 or I.GuideHorizontalLength(group)
    if rx<=0 or ry<=0 or not pixel then HideConnector(connector);return end
    if connector.tx~=tx or connector.ty~=ty or connector.rx~=rx or connector.ry~=ry
        or connector.width~=width or connector.height~=height or connector.pixel~=pixel
        or connector.rowWidth~=rowWidth or connector.length~=length or connector.horizontalLength~=horizontalLength or connector.mouse~=mouse then
        local side=tx<0 and -1 or 1
        local innerX,y=side*width/2,height/2
        local iconEdge=side*(rowWidth/2+8)
        innerX=iconEdge+(innerX-iconEdge)*horizontalLength
        local vx,vy=innerX-tx,y-ty
        local distance=math.sqrt(vx*vx/(rx*rx)+vy*vy/(ry*ry))
        local edgeX,edgeY
        if mouse then
            -- Both endpoints follow the ray between the artwork centers. The
            -- mouse endpoint lies on the pulsing halo, with no horizontal arm.
            local mx,my=0,height/2
            vx,vy=mx-tx,my-ty
            local targetDistance=math.sqrt(vx*vx/(rx*rx)+vy*vy/(ry*ry))
            local haloRX,haloRY=rowWidth/2,frame.layoutBodyHeight/2
            local haloDistance=math.sqrt(vx*vx/(haloRX*haloRX)+vy*vy/(haloRY*haloRY))
            connector.outside=targetDistance>0 and haloDistance>0 and 1/targetDistance+1/haloDistance<1
            if connector.outside then
                innerX,y=mx-vx/haloDistance,my-vy/haloDistance
                edgeX,edgeY=tx+vx/targetDistance,ty+vy/targetDistance
            end
        else
            connector.outside=distance>1
            if connector.outside then edgeX,edgeY=tx+vx/distance,ty+vy/distance end
        end
        if connector.outside then
            -- The texture's 4px footprint has a 2px solid core and a 1px alpha
            -- shoulder on each side, so the quad boundary stays transparent.
            connector.row:SetThickness(2*pixel);connector.link:SetThickness(4*pixel)
            if horizontalLength>0 then
                connector.row:SetStartPoint("CENTER",connector.canvas,innerX,y)
                connector.row:SetEndPoint("CENTER",connector.canvas,iconEdge,y)
            end
            local startX,startY=innerX+(edgeX-innerX)*length,y+(edgeY-y)*length
            if length>0 then
                connector.link:SetStartPoint("CENTER",connector.canvas,startX,startY)
                connector.link:SetEndPoint("CENTER",connector.canvas,innerX,y)
            end
            if connector.joint then
                connector.joint:SetSize(8*pixel,8*pixel)
                connector.joint:ClearAllPoints();connector.joint:SetPoint("CENTER",connector.canvas,startX,startY)
                connector.jointMask:SetAllPoints(connector.joint)
            end
        end
        connector.tx,connector.ty,connector.rx,connector.ry=tx,ty,rx,ry
        connector.width,connector.height,connector.pixel,connector.rowWidth=width,height,pixel,rowWidth
        connector.length=length
        connector.horizontalLength=horizontalLength;connector.mouse=mouse
    end
    connector.row:SetShown(connector.outside and horizontalLength>0);connector.link:SetShown(connector.outside and length>0)
    if connector.joint then connector.joint:SetShown(connector.outside)end
end
I.CreateGuideDecoration=Decoration
I.LayoutGuideDecoration=LayoutDecoration
I.UpdateGuideConnector=UpdateConnector
function I.Configure(view,o)
    o.buffIcons=o.buffIcons or {};o.entries=I.Entries(view.byID[o.spec.parent]);o.native=not view.preview and NativeAvailable()
    local decoration=Decoration(o)
    decoration.title:SetFont(M:EffectiveFontPath(M:DefaultFontPath()),12,"");decoration.layoutFontSize=nil
    decoration.layoutWidth=nil
    for index,entry in ipairs(o.entries)do
        local slot=Icon(o,index);slot.entry=entry;ResolveSlot(slot,entry)
        slot.time:SetFont(M:EffectiveFontPath(M.MYRIAD),16,"OUTLINE")
        slot.time:SetText("");slot.timerGate:SetAlpha(1)
        slot.hand:SetText(slot.weapon and W.SlotLabel(entry)or "")
        if not view.preview then
            if InCombatLockdown()then slot.pending=true
            elseif o.native and not slot.weapon then Bind(slot)
            elseif slot.container then slot.container:SetEnabled(false);slot.bound=false end
        end
        if slot.weapon then
            slot.texture:SetParent(slot.base)
            slot.timerGate:SetParent(slot.base)
            for _,frame in ipairs(slot.nativeFrames or {})do frame.gate:SetAlpha(1)end
        end
    end
    for index=#o.entries+1,#o.buffIcons do
        local slot=o.buffIcons[index];slot:Hide();slot.entry=nil
        if slot.container then slot.container:SetEnabled(false)end
    end
    o.nextScan=0;o.nextInfo=0
end
local function Auras()
    if C_Secrets and C_Secrets.ShouldAurasBeSecret then
        local secret=Safe(C_Secrets.ShouldAurasBeSecret,"player")
        if not Readable(secret)or secret==true then return end
    end
    local byID,byName={},{}
    for index=1,255 do
        local aura=M.Compat.Aura("player",index,"HELPFUL");if not aura then break end
        I.RememberBuffAura(aura)
        local id=aura.spellId;if type(id)=="nil"then id=aura.spellID end
        if Readable(id)and type(id)=="number"then byID[id]=aura end
        if Readable(aura.name)and type(aura.name)=="string"then
            local matches=byName[aura.name]or {};byName[aura.name]=matches;matches[#matches+1]=aura
        end
    end
    return byID,byName
end
local function BuffRemaining(slot,byID,byName,now)
    if not byID then return false end
    local active,longest,permanent=false,nil,false
    local function Include(aura)
        if not aura then return end
        local expires=Number(aura.expirationTime)
        if not expires or expires==0 then permanent=true
        elseif expires>now then active=true;longest=math.max(longest or 0,expires-now)end
    end
    for _,spell in ipairs(slot.spells)do
        local name=spell.matchName or (not tonumber(spell.value)and spell.value)
        if name then
            for _,aura in ipairs(byName[name]or {})do Include(aura)end
        else
            Include(spell.id and byID[spell.id])
            for id in pairs(spell.ids or {})do Include(byID[id])end
        end
        if permanent then return true end
    end
    return active,longest
end
function I.Paint(view,o,animateOnly)
    local group=view.byID[o.spec.parent]
    local raid=M.Compat.Bool(Safe(IsInRaid))or (Number(Safe(GetNumRaidMembers))or 0)>0
    local shown=not(view.hidden and view.hidden[o.spec.id])and (view.preview or
        (group.enabled~=false and o.spec.enabled~=false and (not group.raidOnly or raid)
        and (not group.hideWithoutTarget or M.Compat.Bool(Safe(UnitExists,"target")))))
    o.frame:SetShown(shown);if not shown then return end
    local now=GetTime()
    if animateOnly and now<(o.nextScan or 0)then UpdateConnector(view,o);return end
    o.nextScan=now+.1
    local byID,byName;if not view.preview then byID,byName=Auras()end
    local displayed={};local snapshot,lines=W.Snapshot(),{}
    for _,slot in ipairs(o.buffIcons or {})do
        if slot.entry then
            if now>=(o.nextInfo or 0)then
                local changed=ResolveSlot(slot,slot.entry)
                if o.native and not slot.weapon and (changed or not slot.bound)then slot.pending=true end
            end
            if slot.pending and o.native and not slot.weapon and not InCombatLockdown()then Bind(slot)end
            local active,remaining=BuffRemaining(slot,byID,byName,now)
            local visible
            if slot.weapon then
                visible,remaining=W.Missing(slot.entry,slot.spell,snapshot,lines);visible=view.preview or visible
            else
                visible=view.preview or (o.native and slot.bound)or not active or (remaining and remaining<180)
                if slot.entry.type=="weaponAura"and not view.preview then
                    local d=slot.spell.definition
                    visible=visible and d and (W.Applicable(16,d)==true or W.Applicable(17,d)==true)
                end
            end
            slot:SetShown(visible)
            slot.remaining=remaining;slot.timerGate:SetAlpha(1)
            slot.time:SetText(S.FormatCountdown(view.preview and 80 or visible and remaining or nil))
            if visible then displayed[#displayed+1]=slot end
            slot.texture:SetDesaturated(false);slot.texture:SetAlpha(1)
            if o.native and slot.bound then
                for _,frame in ipairs(slot.nativeFrames or {})do
                    local present=frame:IsShown()
                    local alpha=0;local curve=ExpiryCurve()
                    local duration=curve and frame.GetAuraDuration and Safe(frame.GetAuraDuration,frame)
                    if duration and duration.EvaluateRemainingDuration then alpha=duration:EvaluateRemainingDuration(curve,0)end
                    if frame.gate.SetAlphaFromBoolean then frame.gate:SetAlphaFromBoolean(present,alpha,1)
                    elseif Readable(present)then frame.gate:SetAlpha(present and 0 or 1)end
                end
                local first=slot.nativeFrames and slot.nativeFrames[1]
                if first and first.nativeTime then
                    first.nativeTime:SetAlpha(0)
                    slot.time:SetText(first.nativeTime:GetText())
                    local present=first:IsShown()
                    if slot.timerGate.SetAlphaFromBoolean then slot.timerGate:SetAlphaFromBoolean(present,1,0)
                    elseif Readable(present)then slot.timerGate:SetAlpha(present and 1 or 0)end
                end
            end
        end
    end
    if now>=(o.nextInfo or 0)then o.nextInfo=now+1 end
    o.rowCount=#displayed;local width=math.max(1,#displayed*44-4)
    if o.rowWidth~=width then o.rowWidth=width;o.frame:SetSize(width,66)end
    for index,slot in ipairs(displayed)do
        local x=S.IconOffset(group,index,#displayed)
        if slot.rowX~=x then slot.rowX=x;slot:ClearAllPoints();slot:SetPoint("CENTER",o.frame,"CENTER",x,-7)end
    end
    LayoutDecoration(o,group,#displayed)
    UpdateConnector(view,o)
end
function I.Event(view,event,unit)
    if (event=="UNIT_AURA"or event=="UNIT_INVENTORY_CHANGED")and unit~="player"then return end
    if event~="UNIT_AURA"and event~="GROUP_ROSTER_UPDATE"and event~="PLAYER_ENTERING_WORLD"and event~="PLAYER_TARGET_CHANGED"
        and event~="PLAYER_REGEN_ENABLED"and event~="SPELLS_CHANGED"and event~="UNIT_INVENTORY_CHANGED"
        and event~="PLAYER_EQUIPMENT_CHANGED"and event~="GET_ITEM_INFO_RECEIVED"and event~="BAG_UPDATE_DELAYED"then return end
    local o=view.nodes.raidBuffsIcons;if not o then return end
    if event=="SPELLS_CHANGED"or event=="PLAYER_REGEN_ENABLED"or event=="PLAYER_ENTERING_WORLD"then I.Configure(view,o)end
    o.nextScan=0;if event~="UNIT_AURA"then o.nextInfo=0 end
    I.Paint(view,o,false)
end
function I.Remove(view,o)
    for _,slot in ipairs(o.buffIcons or {})do if slot.container then slot.container:SetEnabled(false)end end
end
