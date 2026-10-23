local _,M=...
local G={};M.ModuleGuides=G
local I=M.RaidBuffMonitor
G.definitions={
    playerSkillMonitor={label="职业技能监控",anchor="playerSkillMonitorIcons",mode="icons"},
    playerOtherMonitor={label="装备触发与其他监控",anchor="playerOtherMonitorIcons",mode="icons"},
    cooldownMonitor={label="冷却监控",anchor="cooldownMonitorIcons",mode="cooldowns"},
    commonItems={label="常用物品监控",anchor="commonItemsIcons",mode="icons",secureItems=true},
    petComposite={label="宠物框体",mode="unit"},
    totComposite={label="目标的目标框体",mode="unit"},
    focusComposite={label="焦点框体",mode="unit"},
    partyFrames={label="队伍框体",mode="unit"},
    receivedBuffs={label="获取队友Buff监控",anchor="receivedBuffsIcons",mode="icons"},
    raidVulnerability={label="团队易伤监控",anchor="raidVulnerabilityIcons",mode="icons"},
    raidBuffs={label="团队Buff缺失监控",mode="raid"},
    targetThreat={label="仇恨监控",anchor="targetThreatDisplay",mode="threat"},
    targetDistance={label="距离监控",anchor="targetDistanceNumber",mode="distance"},
    mouseCircle={label="鼠标光圈提示",anchor="mouseCircleRings",mode="mouse"},
}
function G.Supports(group)return group and G.definitions[group.id]~=nil end
function G.DefaultText(group)
    local definition=group and G.definitions[group.id]or G.definitions.raidBuffs
    local english=M.localeTables and M.localeTables.enUS
    local text=english and english[definition.label]or definition.label
    return (text:gsub("[Tt][Rr][Aa][Cc][Kk][Ii][Nn][Gg]",""):gsub("%s+"," "):match("^%s*(.-)%s*$"))
end
function G.Ensure(design)
    for _,group in ipairs(design and design.nodes or {})do
        if G.Supports(group)then
            group.showGuideLines=I.GuideLinesShown(group);group.hideGuideLines=nil
            if type(group.showGuideText)~="boolean"then group.showGuideText=true end
            group.guideLineLength=I.GuideLength(group)
            group.guideHorizontalLength=I.GuideHorizontalLength(group)
            group.guideOpacity=I.GuideOpacity(group)
            group.guideFontSize=I.GuideFontSize(group)
            group.guideFontPath=I.GuideFontPath(group)
            if type(group.guideText)~="string"or #group.guideText>384 then group.guideText=G.DefaultText(group)end
        end
    end
end
G.Ensure(M.defaults);G.Ensure(M.recordedDefaults)

local bodies={bar=true,texture=true,portrait=true,border=true}
local function BodyLists(view)
    if view.guideBodies and view.guideBodiesGeneration==view.applyGeneration then return end
    view.guideBodiesGeneration=view.applyGeneration;view.guideBodies={}
    for _,o in ipairs(view.ordered or {})do
        local spec=o.spec
        if bodies[spec.kind]and spec.enabled~=false and not spec.particleFlow and not spec.spinPeriod then
            local ancestor=spec
            for _=1,100 do
                local definition=G.definitions[ancestor.id]
                if definition then
                    if definition.mode=="unit"then
                        local list=view.guideBodies[ancestor.id]or {};view.guideBodies[ancestor.id]=list;list[#list+1]=o
                    end
                    break
                end
                ancestor=ancestor.parent and view.byID[ancestor.parent]
                if not ancestor then break end
            end
        end
    end
end
local function VisibleBounds(view,id,frame)
    local ax,ay=frame:GetCenter();if not ax or not ay then return end
    local scale=frame:GetEffectiveScale();local left,right,bottom,top
    for _,body in ipairs(view.guideBodies[id]or {})do
        local f=body.frame
        -- These are addon-owned artwork frames, never unit hitboxes or native
        -- aura/provider frames. Their full layout sizes do not expose unit data.
        if not body.removed and not body.focusPortraitOnlyHidden and not(view.hidden and view.hidden[body.spec.id])and f:IsVisible()then
            local x,y=f:GetCenter()
            if x and y then
                local ratio=f:GetEffectiveScale()/scale
                local w,h=f:GetWidth()*ratio,f:GetHeight()*ratio;x,y=x*ratio-ax,y*ratio-ay
                left=left and math.min(left,x-w/2)or x-w/2;right=right and math.max(right,x+w/2)or x+w/2
                bottom=bottom and math.min(bottom,y-h/2)or y-h/2;top=top and math.max(top,y+h/2)or y+h/2
            end
        end
    end
    if left then return {x=(left+right)/2,y=(bottom+top)/2,width=math.max(1,right-left),height=math.max(1,top-bottom)}end
end
function G.Refresh(view,force)
    BodyLists(view);view.moduleGuides=view.moduleGuides or {}
    local now=GetTime()
    for id,definition in pairs(G.definitions)do
        if definition.mode~="raid"then
            local group=view.byID[id];local owner=view.nodes[definition.anchor or id]
            local state=view.moduleGuides[id]
            if group and owner and not owner.removed then
                if not state or state.o.frame~=owner.frame then
                    state={o={frame=owner.frame,spec={parent=id}}};view.moduleGuides[id]=state
                end
                local o=state.o;o.guideGroup=group
                local itemsHidden=definition.secureItems and not view.preview and
                    (M.moveMode or (group.hideWithoutTarget and not M.Compat.Bool(I.Safe(UnitExists,"target"))))
                if (not view.preview and group.enabled==false)or owner.spec.enabled==false or itemsHidden
                    or (view.hidden and (view.hidden[id]or view.hidden[owner.spec.id]))or not owner.frame:IsVisible()then
                    if o.decoration then o.decoration:Hide()end
                elseif definition.mode=="icons"then
                    o.guideBounds=nil;I.LayoutGuideDecoration(o,group,owner.rowCount or 0);I.UpdateGuideConnector(view,o)
                elseif definition.mode=="cooldowns"then
                    local count=#(owner.cooldownEntries or {})
                    o.guideBounds={x=0,y=0,width=math.max(1,count*44-4),height=40}
                    I.LayoutGuideDecoration(o,group,count);I.UpdateGuideConnector(view,o)
                else
                    if definition.mode=="mouse"or force or state.generation~=view.applyGeneration or now>=(state.nextBounds or 0)then
                        state.generation=view.applyGeneration;state.nextBounds=now+.1
                        if definition.mode=="unit"then o.guideBounds=VisibleBounds(view,id,owner.frame)
                        elseif definition.mode=="threat"or definition.mode=="distance"then
                            local text=definition.mode=="distance"and owner.distanceNumber or owner.threatText
                            local width=text:GetStringWidth()
                            local x=definition.mode=="distance"and 0 or (width-owner.frame:GetWidth())/2
                            local height=owner.frame:GetHeight();local y=0
                            if definition.mode=="distance"then
                                height=math.max(.1,group.fontSize or 20)+4
                                -- Compare visible text spacing in screen units: the
                                -- two modules may have different effective scales.
                                local threat=view.nodes.targetThreatDisplay
                                local threatGroup=view.byID.targetThreat or {}
                                local threatSize=math.max(.1,threatGroup.fontSize or 28)
                                local threatHeight=threat and threat.frame:GetHeight()or threatSize+4
                                local threatTextHeight=threat and threat.threatText:GetStringHeight()or 0
                                if threatTextHeight<=0 then threatTextHeight=threatSize end
                                local textHeight=text:GetStringHeight()
                                if textHeight<=0 then textHeight=math.max(.1,group.fontSize or 20)end
                                local ratio=threat and threat.frame:GetEffectiveScale()/math.max(.001,owner.frame:GetEffectiveScale())or 1
                                local gap=(threatHeight/2+16-threatTextHeight/2)*ratio
                                y=height/2+16-textHeight/2-gap
                            end
                            o.guideBounds=width>0 and {x=x,y=y,width=width,height=height}or nil
                        else
                            local size=owner.outerSize or 50;o.guideBounds={x=0,y=0,width=size,height=size}
                        end
                    end
                    if o.guideBounds then I.LayoutGuideDecoration(o,group,1);I.UpdateGuideConnector(view,o)
                    elseif o.decoration then o.decoration:Hide()end
                end
            elseif state and state.o.decoration then state.o.decoration:Hide()end
        end
    end
end
function G.PreviewBounds(view,id,geometry)
    local definition=G.definitions[id];if not definition then return end
    local anchorID=definition.mode=="raid"and "raidBuffsIcons"or definition.anchor or id
    local state=view.moduleGuides and view.moduleGuides[id]
    local o=definition.mode=="raid"and view.nodes.raidBuffsIcons or state and state.o
    local frame=o and o.decoration;local g=geometry[anchorID]
    if not frame or not g or not frame:IsVisible()or not frame.title:IsShown()then return end
    if definition.mode=="distance"and view.preview and not view.unlockMode then
        local x,y=M.TargetDistance.NumberPreviewPosition(geometry)
        g={x=x,y=y,s=g.s}
    end
    local x=g.x+frame.layoutCenter*g.s
    local y=g.y+(frame.layoutCenterY-frame:GetHeight()+frame.layoutPixel/2)*g.s
    local w,h=frame.title:GetWidth()*g.s,frame.title:GetHeight()*g.s
    return x-w/2,y-h/2,x+w/2,y+h/2
end

function G.BuildControls(e,parent,flush,key)
    local W=M.Widgets;local guide,propertyRow
    local function Current()local group=M.byID[M.selection];return G.Supports(group)and group end
    local function Flush()
        if flush then flush()elseif guide and guide.text then guide.text:ClearFocus()end
    end
    guide=CreateFrame("Frame",nil,parent);guide:SetSize(470,240);if key=="raidBuffsGuideSettings"then e.raidBuffsGuidePanel=guide else e.moduleGuidePanel=guide end
    guide.title=W.Label(guide,"辅助线",12);guide.title:SetPoint("CENTER",guide,"TOP",0,12);guide.title:SetTextColor(1,.82,0)
    M:SetLocaleLineHeight(guide.title,18);guide.title:SetJustifyH("CENTER")
    guide.left=guide:CreateTexture(nil,"ARTWORK");guide.left:SetHeight(1);guide.left:SetColorTexture(.5,.5,.5,.45)
    guide.left:SetPoint("LEFT",guide,"TOPLEFT",0,12);guide.left:SetPoint("RIGHT",guide.title,"LEFT",-8,0)
    guide.right=guide:CreateTexture(nil,"ARTWORK");guide.right:SetHeight(1);guide.right:SetColorTexture(.5,.5,.5,.45)
    guide.right:SetPoint("LEFT",guide.title,"RIGHT",8,0);guide.right:SetPoint("RIGHT",guide,"TOPRIGHT",0,12)
    guide.rows={}
    for index=1,6 do
        local row=CreateFrame("Frame",nil,guide);row:SetSize(470,index==6 and 48 or 24)
        row:SetPoint("TOPLEFT",guide,"TOPLEFT",0,-(index-1)*36);guide.rows[index]=row
    end
    local function ChangeGuide(field,value)
        local owner=guide.owner
        if not owner or Current()~=owner or M.byID[owner.id]~=owner or not M:CanEdit()then M:RefreshProperties();return end
        Flush()
        if owner[field]~=value then owner[field]=value;M:Commit()end
    end
    guide.showLines=W.Check(guide.rows[1],"显示辅助线",function(value)ChangeGuide("showGuideLines",value==true)end)
    guide.showLines:SetPoint("LEFT",guide.rows[1],"LEFT",-4,0)
    guide.lengthLabel=W.Label(guide.rows[2],"辅助斜线长度",12);guide.lengthLabel:SetPoint("LEFT",guide.rows[2],"LEFT",0,0)
    guide.length=W.SpinBox(guide.rows[2],225,0,1,.01);guide.length:SetIsPercent(true)
    guide.length:SetPoint("RIGHT",guide.rows[2],"RIGHT",-2,0)
    guide.length:SetScript("OnValueChanged",function(self,value)
        if not self.updating then ChangeGuide("guideLineLength",M.Clamp(value,0,1))end
    end)
    guide.opacityLabel=W.Label(guide.rows[3],"辅助线透明度",12);guide.opacityLabel:SetPoint("LEFT",guide.rows[3],"LEFT",0,0)
    guide.opacity=W.SpinBox(guide.rows[3],225,0,1,.01);guide.opacity:SetIsPercent(true)
    guide.opacity:SetPoint("RIGHT",guide.rows[3],"RIGHT",-2,0)
    guide.opacity:SetScript("OnValueChanged",function(self,value)
        if not self.updating then ChangeGuide("guideOpacity",M.Clamp(value,0,1))end
    end)
    guide.flatLengthLabel=W.Label(guide.rows[4],"辅助平线长度",12);guide.flatLengthLabel:SetPoint("LEFT",guide.rows[4],"LEFT",0,0)
    guide.flatLength=W.SpinBox(guide.rows[4],225,0,1,.01);guide.flatLength:SetIsPercent(true)
    guide.flatLength:SetPoint("RIGHT",guide.rows[4],"RIGHT",-2,0)
    guide.flatLength:SetScript("OnValueChanged",function(self,value)
        if not self.updating then ChangeGuide("guideHorizontalLength",M.Clamp(value,0,1))end
    end)
    guide.showText=W.Check(guide.rows[5],"显示文字",function(value)ChangeGuide("showGuideText",value==true)end)
    guide.showText:SetPoint("LEFT",guide.rows[5],"LEFT",-4,0)
    guide.text=W.Edit(guide.rows[5],225);guide.text:SetMaxLetters(128);guide.text:SetTextInsets(6,6,0,0)
    guide.text:SetPoint("RIGHT",guide.rows[5],"RIGHT",-2,0)
    guide.text:SetScript("OnEditFocusLost",function(self)
        if not self.updating then ChangeGuide("guideText",W.InputValue(self))end
    end)
    guide.text:SetScript("OnEnterPressed",function(self)
        ChangeGuide("guideText",W.InputValue(self));self:ClearFocus()
    end)
    guide.text:SetScript("OnEscapePressed",function(self)
        W.SetInputValue(self,guide.owner and I.GuideText(guide.owner)or "");self:ClearFocus()
    end)
    local fontChoices=M:BundledFontChoices()
    guide.font=W.MediaSelect(guide.rows[6],"字体",225,"font",function()
        local drop=guide.font
        if drop.menu then drop.menu:Hide();return end
        W.MediaMenu(drop,fontChoices,"font",drop.value,function(choice)
            ChangeGuide("guideFontPath",choice.path)
        end)
    end)
    guide.font:SetPoint("TOPLEFT",guide.rows[6],"TOPLEFT",0,0)
    function guide.font:SetValue(value)
        self.value=value
        for _,choice in ipairs(fontChoices)do
            if choice.path==value then self:SetMedia(choice.name,choice.path);return end
        end
        self:SetMedia(value or "",value)
    end
    guide.fontSizeLabel=W.Label(guide.rows[6],"大小",12)
    guide.fontSizeLabel:SetPoint("TOPLEFT",guide.rows[6],"TOPLEFT",245,0)
    guide.fontSize=W.SpinBox(guide.rows[6],225,4,150,1)
    guide.fontSize:SetPoint("TOPLEFT",guide.rows[6],"TOPLEFT",245,-24)
    guide.fontSize:SetScript("OnValueChanged",function(self,value)
        if not self.updating then ChangeGuide("guideFontSize",M.Clamp(math.floor(value+.5),4,150))end
    end)
    function guide:Refresh(owner)
        if self.owner~=owner and self.font.menu then self.font.menu:Hide();self.font.menu=nil end
        self.owner=owner;self:SetWidth(e.props:GetWidth())
        local mouse=owner.id=="mouseCircle"
        local offset=0
        local function Place(row,visible)
            row:SetShown(visible)
            if visible then
                row:ClearAllPoints();row:SetPoint("TOPLEFT",self,"TOPLEFT",0,-offset)
                offset=offset+(row==self.rows[6]and 60 or 36)
            end
        end
        Place(self.rows[1],true);Place(self.rows[2],true);Place(self.rows[3],true)
        Place(self.rows[4],not mouse);Place(self.rows[5],true);Place(self.rows[6],true)
        local height=offset
        self:SetHeight(height)
        if propertyRow.height~=height then propertyRow.height=height;e.propertyLayoutSignature=nil end
        local width=(self:GetWidth()-20)/2
        for _,row in ipairs(self.rows)do row:SetWidth(self:GetWidth())end
        self.length:SetWidth(width);self.opacity:SetWidth(width);self.flatLength:SetWidth(width);self.text:SetWidth(width)
        local fontWidth=(self:GetWidth()-20)/2
        self.font:SetWidth(fontWidth);self.fontSizeLabel:ClearAllPoints();self.fontSizeLabel:SetPoint("TOPLEFT",self.rows[6],"TOPLEFT",fontWidth+20,0)
        self.fontSize:ClearAllPoints();self.fontSize:SetPoint("TOPLEFT",self.rows[6],"TOPLEFT",fontWidth+20,-24)
        self.fontSize:SetWidth(width)
        self.showLines:SetChecked(I.GuideLinesShown(owner));self.showText:SetChecked(owner.showGuideText~=false)
        self.length.updating=true;self.length:SetValue(I.GuideLength(owner));self.length.updating=false
        self.flatLength.updating=true;self.flatLength:SetValue(I.GuideHorizontalLength(owner));self.flatLength.updating=false
        self.opacity.updating=true;self.opacity:SetValue(I.GuideOpacity(owner));self.opacity.updating=false
        self.font:SetValue(I.GuideFontPath(owner))
        self.fontSize.updating=true;self.fontSize:SetValue(I.GuideFontSize(owner));self.fontSize.updating=false
        if not self.text:HasFocus()then W.SetInputValue(self.text,I.GuideText(owner))end
    end
    propertyRow={height=240,controls={{guide,0,0}},kinds={},key=key or "moduleGuideSettings"};e.propRows[#e.propRows+1]=propertyRow
    return guide
end
