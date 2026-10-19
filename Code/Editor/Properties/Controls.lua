local _,M=...
local W,R=M.Widgets,M.Renderer
local unpack=unpack or table.unpack
local private=M.EditorInternals
local unitChoices=private.unitChoices
local bindingChoices=private.bindingChoices
local IsUnitComposite=private.IsUnitComposite
local IsCastGroup=private.IsCastGroup
local RoundOffset=private.RoundOffset
local CastPart=private.CastPart
local Selected=private.Selected
local CompositePart=private.CompositePart
local CompositeAvatar=private.CompositeAvatar
local CompositeBar=private.CompositeBar
local HealthStyleBar=private.HealthStyleBar
local ChangeHealthStyle=private.ChangeHealthStyle
local ChangeHealthThreshold=private.ChangeHealthThreshold
local CompositeName=private.CompositeName
local AvatarXRange=private.AvatarXRange
local Change=private.Change
local PreviewModuleID=private.PreviewModuleID

local function BuildProperties(e)
    local propertyWidth=470
    local scroll,content=W.Scroll(e.right);scroll:SetPoint("TOPLEFT",12,-42);scroll:SetPoint("BOTTOMRIGHT",-30,12);content:SetWidth(propertyWidth)
    e.propScroll=scroll;e.props=content;e.fields={};e.colors={};e.propRows={}
    e.moduleEnabled=W.Check(e.right,"启动模块",function(enabled)
        local moduleID=PreviewModuleID(Selected())
        if not M:SetModuleEnabled(moduleID,enabled) then M:RefreshProperties() end
    end)
    e.moduleEnabled:SetPoint("TOPLEFT",8,-10);e.moduleEnabled.label:SetTextColor(1,.82,0)
    e.moduleDivider=e.right:CreateTexture(nil,"ARTWORK")
    e.moduleDivider:SetColorTexture(.5,.5,.5,.45);e.moduleDivider:SetHeight(1)
    e.moduleDivider:SetPoint("TOPLEFT",12,-38);e.moduleDivider:SetPoint("TOPRIGHT",-42,-38)
    e.empty=W.Label(e.right,"从左侧列表或画布选择元素",12);e.empty:SetPoint("TOPLEFT",15,-53)
    e.propTitle=W.Label(e.right,"属性",13);e.propTitle:SetPoint("TOPLEFT",13,-15);e.propTitle:SetWidth(propertyWidth);e.propTitle:SetWordWrap(false)
    local y=0
    local textKinds={text=true};local mediaKinds={texture=true,bar=true,spark=true,sprite=true,icon=true}
    local spriteKinds={sprite=true};local modelKinds={model=true};local barKinds={bar=true}
    local colors={texture=true,bar=true,spark=true,sprite=true,text=true,glow=true,border=true,portrait=true,icon=true}
    local masks={text=textKinds,fontSize=textKinds,rotation=mediaKinds,file=mediaKinds,cropX=mediaKinds,cropY=mediaKinds,
        rows=spriteKinds,columns=spriteKinds,frames=spriteKinds,fps=spriteKinds,model=modelKinds,modelScale=modelKinds,modelX=modelKinds,modelY=modelKinds,modelZ=modelKinds,count={auras=true},spacing={auras=true},resourceSpacing={},debuffCount={},debuffPerRow={},buffCount={},buffPerRow={},minCooldown={},maxCooldown={},iconSize={},buttonSpacing={},fontYOffset={}}
    local function Row(height,controls,kinds,key)
        for _,entry in ipairs(controls) do
            local control=entry[1]
            if control:GetObjectType()=="FontString" then control:SetTextColor(1,1,1)
            elseif control.caption then control.caption:SetTextColor(1,1,1)
            elseif control.label then control.label:SetTextColor(1,1,1) end
            if control.colorSwatchInset then
                entry[2]=entry[2]+control.colorSwatchInset;entry[3]=entry[3]-control.colorSwatchInset
            end
        end
        e.propRows[#e.propRows+1]={height=height,controls=controls,kinds=kinds,key=key}
    end
    local function Field(label,key,numeric,min,max,step)
        local t=W.Label(content,label);t:SetPoint("TOPLEFT",0,y-3)
        local edit
        if numeric then
            local fieldStep=step or 1
            edit=W.SpinBox(content,(propertyWidth-4)/2,min or -10000,max or 10000,fieldStep)
            if key=="alpha" then edit:SetIsPercent(true) end
            edit:SetScript("OnValueChanged",function(self,value)
                if self.updating then return end
                if key=="debuffCount" or key=="debuffPerRow" or key=="buffCount" or key=="buffPerRow" then value=math.floor(value+.5) end
                Change(key,value)
            end)
        else
            edit=W.Edit(content,propertyWidth-4)
            edit:SetScript("OnEnterPressed",function(self)
                local value=self:GetText();self:ClearFocus();Change(key,value)
            end)
        end
        edit:SetPoint("TOPLEFT",2,y-22);e.fields[key]=edit
        Row(53,{{t,0,-3},{edit,2,-22}},masks[key],key);y=y-53
        return t,edit
    end
    e.decorationHidden=W.Check(content,"隐藏",function(hidden)
        local n=Selected();if not n or n.id~="centerFire" then return end
        if not M:CanEdit() then M:RefreshProperties();return end
        Change("enabled",not hidden)
    end)
    Row(32,{{e.decorationHidden,-4,0}},{},"decorationHidden");y=y-32
    Field("名称","label")
    e.coordXLabel=Field("X偏移","x",true);e.coordYLabel=Field("Y偏移","y",true)
    Field("宽度","width",true,1,4000);Field("高度","height",true,1,4000)
    Field("缩放","scale",true,.05,10,.05)
    e.partyFields={}
    e.partyHideInRaid=W.Check(content,"在团队时隐藏",function(hidden)
        if Selected() and Selected().compound=="partyFrames"then Change("hidePartyInRaid",hidden)end
    end)
    Row(32,{{e.partyHideInRaid,-4,0}},{},"partyHideInRaid");y=y-32
    local function PartyField(label,key,minimum,maximum,step)
        local caption=W.Label(content,label)
        local edit=W.SpinBox(content,propertyWidth-4,minimum,maximum,step)
        edit:SetScript("OnValueChanged",function(self,value)
            if not self.updating and Selected() and Selected().compound=="partyFrames"then
                if key=="partyNameSize" then Change(key,M.Clamp(value,self:GetMinMaxValues()))
                else Change(key,M.Clamp(value,minimum,maximum))end
            end
        end)
        e.partyFields[key]=edit
        Row(53,{{caption,0,-3},{edit,2,-22}},{},key);y=y-53
    end
    PartyField("队员纵向间距","partySpacing",45,150,1)
    e.partyHideNumbers=W.Check(content,"隐藏队伍编号",function(hidden)
        if Selected() and Selected().compound=="partyFrames"then Change("hidePartyNumbers",hidden)end
    end)
    Row(32,{{e.partyHideNumbers,-4,0}},{},"partyHideNumbers");y=y-32
    e.partyHidePlayer=W.Check(content,"隐藏玩家自己",function(hidden)
        if Selected() and Selected().compound=="partyFrames"then Change("hidePartyPlayer",hidden)end
    end)
    Row(32,{{e.partyHidePlayer,-4,0}},{},"partyHidePlayer");y=y-32
    PartyField("玩家框体X偏移","partyPlayerX",-150,150,1)
    e.partyMaterialButton=W.MediaSelect(content,"生命与能量条材质",propertyWidth,"statusbar",function()M:OpenBarMaterialPicker()end)
    Row(53,{{e.partyMaterialButton,0,0}},{},"partyMaterial");y=y-53
    local function PartyColor(label,field)
        local caption=W.Label(content,label)
        local swatch=W.ColorSwatch(content,function(color)
            if Selected() and Selected().compound=="partyFrames"then Change(field,M.Copy(color))end
        end)
        if field=="partyHealthEndColor"then
            e.partyHPEndLabel=caption
            e.partyGradient=W.Check(content,"启用渐变",function(enabled)
                if Selected() and Selected().compound=="partyFrames"then Change("partyHealthGradient",enabled)end
            end)
            Row(32,{{e.partyGradient,-4,0},{caption,0,-32,e.partyHPColorLabel,"RIGHT"},{swatch,0,0,caption}},{},field)
        else
            e.partyHPColorLabel=caption
            Row(32,{{caption,0,-3},{swatch,0,0,caption}},{},field)
        end
        y=y-32
        return swatch
    end
    e.partyHPColor=PartyColor("生命进度条颜色/渐变开始颜色","partyHealthColor")
    e.partyHPEndColor=PartyColor("渐变结束颜色","partyHealthEndColor")
    e.partyFontButton=W.MediaSelect(content,"字体",propertyWidth,"font",function()M:OpenFocusFontPicker()end)
    Row(53,{{e.partyFontButton,0,0}},{},"partyFont");y=y-53
    PartyField("名称字体大小","partyNameSize",4,48,1)
    e.bossHideAvatar=W.Check(content,"隐藏头像",function(hidden)
        local n=Selected();if n and n.compound=="bossFrames" then Change("hideAvatar",hidden) end
    end)
    Row(32,{{e.bossHideAvatar,-4,0}},{},"bossHideAvatar");y=y-32
    e.bossMaterialButton=W.MediaSelect(content,"生命进度条材质",propertyWidth,"statusbar",function()M:OpenBarMaterialPicker()end)
    Row(53,{{e.bossMaterialButton,0,0}},{},"bossHPMaterial");y=y-53
    local function BossColor(label,id,key)
        local caption=W.Label(content,label)
        local swatch=W.ColorSwatch(content,function(color)
            local n=Selected();local target=M.byID[id]
            if n and n.compound=="bossFrames" and target and M:CanEdit() then target.color=M.Copy(color);M:Commit() end
        end)
        Row(32,{{caption,0,-3},{swatch,0,0,caption}},{},key);y=y-32
        return swatch
    end
    local function BossField(label,key,id,field,minimum,maximum,step)
        local caption=W.Label(content,label)
        local edit=W.SpinBox(content,(propertyWidth-4)/2,minimum,maximum,step)
        edit:SetScript("OnValueChanged",function(self,value)
            if self.updating then return end
            local n=Selected();local target=M.byID[id]
            if n and n.compound=="bossFrames" and target and M:CanEdit() then
                if field=="fontSize" then M:SetFontDisplaySize(target,M.Clamp(value,self:GetMinMaxValues()))
                else target[field]=M.Clamp(value,minimum,maximum)end
                M:Commit()
            end
        end)
        e.bossFields[key]=edit
        Row(53,{{caption,0,-3},{edit,2,-22}},{},key);y=y-53
    end
    e.bossFields={}
    e.bossHPColor=BossColor("生命进度条颜色","bossHPFill","bossHPColor")
    BossField("生命百分比X偏移","bossPercentX","bossHPPercent","x",-300,300,1)
    BossField("生命百分比Y偏移","bossPercentY","bossHPPercent","y",-60,60,1)
    e.bossFontButton=W.MediaSelect(content,"字体",propertyWidth,"font",function()M:OpenFocusFontPicker()end)
    Row(53,{{e.bossFontButton,0,0}},{},"bossFont");y=y-53
    BossField("字体大小","bossPercentSize","bossHPPercent","fontSize",4,150,1)
    BossField("施法条Y偏移","bossCastY","bossCast","y",-160,40,1)
    e.bossCastColor=BossColor("施法条颜色","bossCastFill","bossCastColor")
    masks.experienceHeight={};Field("经验条高度","experienceHeight",true,1,100,1)
    e.distanceRingCheck=W.Check(content,"在旋转内环上显示",function(enabled)
        local n=Selected();if n and n.compound=="targetDistance" then Change("showOnRing",enabled) end
    end)
    Row(32,{{e.distanceRingCheck,-4,0}},{},"showOnRing");y=y-32
    e.distanceNameplateCheck=W.Check(content,"在姓名板上显示",function(enabled)
        local n=Selected();if n and n.compound=="targetDistance" then Change("showOnNameplate",enabled) end
    end)
    Row(32,{{e.distanceNameplateCheck,-4,0}},{},"showOnNameplate");y=y-32
    masks.distanceIconSize={};Field("姓名板标记大小","distanceIconSize",true,1,256,1)
    masks.distanceX={};Field("姓名板标记X偏移","distanceX",true,-150,150,1)
    masks.distanceY={};Field("姓名板标记Y偏移","distanceY",true,-40,40,1)
    local distanceTitle=W.Label(content,"判定距离设置",13)
    Row(30,{{distanceTitle,0,-3}},{},"distanceTitle");y=y-30
    e.rangeManualChecks={}
    e.rangeClasses=M.TargetDistance.AvailableClasses()
    for _,class in ipairs(e.rangeClasses) do
        local token=class[1];local key="range"..token
        local spellKey="rangeSpell"..token;local manualKey="rangeManual"..token
        local caption=W.Label(content,class[2]);caption:SetWidth(80);caption:SetWordWrap(false)
        local icon=content:CreateTexture(nil,"ARTWORK");icon:SetSize(22,22);icon:SetTexture(M.TargetDistance.ClassIcon(token))
        local edit=W.Edit(content,(propertyWidth-166)/2);edit:SetMaxLetters(128);edit:SetTextInsets(4,4,0,0)
        local placeholder=W.Label(edit,"技能名称/技能ID",11)
        placeholder:SetPoint("LEFT",edit,"LEFT",4,0);placeholder:SetPoint("RIGHT",edit,"RIGHT",-4,0)
        placeholder:SetTextColor(.5,.5,.5);placeholder:SetWordWrap(false)
        edit.rangePlaceholder=placeholder
        local function UpdatePlaceholder(self)placeholder:SetShown(self:GetText()=="")end
        edit:HookScript("OnTextChanged",UpdatePlaceholder);UpdatePlaceholder(edit)
        e.fields[spellKey]=edit
        local function SaveSpell(self)
            local selected=Selected()
            local n=self.rangeOwner or (selected and selected.compound=="targetDistance" and selected)
            if not n or M.byID[n.id]~=n or n[manualKey]==true or not M:CanEdit() then return end
            local value=M.TargetDistance.SpellInput(self:GetText())
            if n[spellKey]~=value then n[spellKey]=value;M:Commit() end
        end
        edit:SetScript("OnEditFocusGained",function(self)
            local n=Selected();self.rangeOwner=n and n.compound=="targetDistance" and n or nil
        end)
        edit:SetScript("OnEditFocusLost",function(self)SaveSpell(self);self.rangeOwner=nil end)
        edit:SetScript("OnEnterPressed",function(self)SaveSpell(self);self:ClearFocus()end)
        edit:SetScript("OnEscapePressed",function(self)
            if self.rangeOwner then self:SetText(self.rangeOwner[spellKey] or "") end
            self:ClearFocus()
        end)
        edit:HookScript("OnHide",function(self)self:ClearFocus()end)
        Row(32,{{icon,-6,0,caption,"RIGHT","LEFT"},{caption,28,-4},{edit,122,0}},{},spellKey);y=y-32
        caption:SetTextColor(M.TargetDistance.ClassColor(token))
        local check=W.Check(content,"手动距离（码）",function(enabled)
            local n=Selected();if not n or n.compound~="targetDistance" then return end
            if not M:CanEdit() then M:RefreshProperties();return end
            if enabled then edit:ClearFocus() end
            Change(manualKey,enabled)
        end)
        e.rangeManualChecks[manualKey]=check
        local slider=W.SpinBox(content,(propertyWidth-4)/2,1,100,1)
        slider:SetScript("OnValueChanged",function(self,value)
            local n=Selected()
            if not self.updating and self:IsEnabled() and n and n.compound=="targetDistance" and n[manualKey]==true then Change(key,value) end
        end)
        e.fields[key]=slider
        Row(42,{{check,-4,0},{slider,170,-3}},{},manualKey);y=y-42
    end
    local distanceHint=W.Label(content,"按职业填写技能名称或ID，以技能射程判断距离；勾选手动距离后使用设定码数。无法判定时不提示。",11)
    distanceHint:SetWidth(propertyWidth-4);distanceHint:SetWordWrap(true)
    Row(70,{{distanceHint,0,-3}},{},"distanceHint");y=y-70
    e.mouseColors={}
    local mouseColorControls={}
    for i,entry in ipairs({{"outerColor","外圈颜色"},{"innerColor","内圈颜色"},{"gcdColor","GCD圈颜色"}}) do
        local key=entry[1];local caption=W.Label(content,entry[2]);caption.whitePropertyLabel=true
        local swatch=W.ColorSwatch(content,function(color)
            local n=Selected();if not n or n.compound~="mouseCircle" or not M:CanEdit() then return end
            n[key]=M.Copy(color);M:Commit()
        end)
        e.mouseColors[key]=swatch
        caption:SetWidth(124);caption:SetWordWrap(false)
        mouseColorControls[#mouseColorControls+1]={swatch,(i-1)*156,-2}
        mouseColorControls[#mouseColorControls+1]={caption,0,0,swatch}
    end
    Row(32,mouseColorControls,{},"mouseColors");y=y-32
    e.combatSound=W.Check(content,"播放音效",function(enabled)Change("soundEnabled",enabled)end)
    Row(32,{{e.combatSound,-4,0}},{},"combatSound");y=y-32
    Field("图标大小","iconSize",true,1,256)
    Field("按钮间距","buttonSpacing",true,-32,32)
    Field("文字Y偏移","fontYOffset",true,-40,32)
    e.chatTextLabels=W.Check(content,"文本显示",function(enabled)Change("textLabels",enabled)end)
    Row(32,{{e.chatTextLabels,-4,0}},{},"chatTextLabels");y=y-32
    e.threatInstanceOnly=W.Check(content,"仅在副本中显示",function(enabled)Change("instanceOnly",enabled)end)
    Row(32,{{e.threatInstanceOnly,-4,0}},{},"threatInstanceOnly");y=y-32
    masks.pullSeconds={};Field("倒计时时间（秒）","pullSeconds",true,10,60,1)
    local channelLabel=W.Label(content,"自定义频道名")
    local channelInput=W.Edit(content,propertyWidth-4);channelInput:SetMaxLetters(128);channelInput:SetTextInsets(4,4,0,0)
    e.fields.customChannelName=channelInput
    e.chatChannelPlaceholder=W.Label(channelInput,"寻求组队",11)
    e.chatChannelPlaceholder:SetPoint("LEFT",channelInput,"LEFT",4,0)
    e.chatChannelPlaceholder:SetPoint("RIGHT",channelInput,"RIGHT",-4,0)
    e.chatChannelPlaceholder:SetTextColor(.5,.5,.5);e.chatChannelPlaceholder:SetWordWrap(false)
    channelInput:HookScript("OnTextChanged",function(self)
        e.chatChannelPlaceholder:SetShown(M.ChatButtons.ChannelInput(self:GetText())=="")
    end)
    local function SaveChannel(self)
        local n=self.chatOwner or Selected()
        if not n or n.compound~="chatButtons" or M.byID[n.id]~=n or not M:CanEdit() then return end
        local value=M.ChatButtons.ChannelInput(self:GetText())
        if n.customChannelName~=value then n.customChannelName=value;M:Commit() end
    end
    channelInput:SetScript("OnEditFocusGained",function(self)
        local n=Selected();self.chatOwner=n and n.compound=="chatButtons" and n or nil
    end)
    channelInput:SetScript("OnEditFocusLost",function(self)SaveChannel(self);self.chatOwner=nil end)
    channelInput:SetScript("OnEnterPressed",function(self)SaveChannel(self);self:ClearFocus()end)
    channelInput:SetScript("OnEscapePressed",function(self)
        local n=self.chatOwner or Selected();if n and n.compound=="chatButtons" then self:SetText(n.customChannelName or "") end
        self:ClearFocus()
    end)
    channelInput:HookScript("OnHide",function(self)self:ClearFocus()end)
    Row(53,{{channelLabel,0,-3},{channelInput,2,-22}},{},"customChannelName");y=y-53
    Field("最短冷却时间监控（秒）","minCooldown",true,0,86400,.5)
    Field("最长冷却时间监控（秒）","maxCooldown",true,0,86400,.5)
    local blacklistLabel=W.Label(content,"不监控的技能／物品")
    e.cooldownBlacklist=W.BlacklistEditor(content,propertyWidth-4,function(text)
        local n=Selected()
        if not n or n.compound~="cooldownMonitor" or not M:CanEdit() then return false end
        n.blacklist=text;M:Commit();return true
    end)
    local blacklistHint=W.Label(content,"输入技能／物品名称或 ID，点击＋添加。",11)
    blacklistHint:SetWidth(propertyWidth-4);blacklistHint:SetWordWrap(true)
    Row(285,{{blacklistLabel,0,-3},{e.cooldownBlacklist,2,-22},{blacklistHint,2,-264}},{},"blacklist");y=y-285
    Field("元素间距","resourceSpacing",true,-20,20)
    local function BareSlider(width,minimum,maximum,step,parent)
        return W.SpinBox(parent or content,width/2,minimum,maximum,step)
    end
    local function ScaleSlider(label,key,apply)
        local caption=W.Label(content,label);caption:SetPoint("TOPLEFT",0,y-3)
        local slider=BareSlider(propertyWidth-10,.5,1.5,.05);slider:SetPoint("TOPLEFT",4,y-20)
        slider:SetScript("OnValueChanged",function(self,value)
            if self.updating then return end
            local group=Selected()
            if not group or not M:CanEdit() then return end
            local main=group.id=="mainComposite" or group.id=="wabc757f81ee"
            local cast=IsCastGroup(group) and key=="overallScale"
            if not IsUnitComposite(group) and not (main and key=="overallScale") and not cast then return end
            local scale=M.Clamp(math.floor(value*20+.5)/20,.5,1.5)
            local current=key=="avatarScale" and CompositeAvatar(group) or group
            local currentScale=M:ScaleDisplayValue(current)
            if not current or math.abs(currentScale-scale)<.0001 then return end
            apply(group,scale);M:Commit()
        end)
        Row(49,{{caption,0,-3},{slider,4,-20}},nil,key);y=y-49
        return slider,caption
    end
    e.mainScaleHeader=CreateFrame("Frame",nil,e.right)
    e.mainScaleHeader:SetPoint("TOPLEFT",e.right,"TOPLEFT",12,-38)
    e.mainScaleHeader:SetPoint("TOPRIGHT",e.right,"TOPRIGHT",-30,-38)
    e.mainScaleHeader:SetHeight(51)
    e.mainScaleHeader:Hide()
    e.mainScaleLabel=W.Label(e.mainScaleHeader,"缩放",12)
    e.mainScaleLabel:SetTextColor(1,1,1)
    e.mainScaleLabel:SetPoint("TOPLEFT",2,-2)
    e.mainScaleSlider=BareSlider(propertyWidth-10,.1,1.5,.05,e.mainScaleHeader)
    e.mainScaleSlider:SetPoint("TOPLEFT",6,-24)
    e.mainScaleSlider:SetScript("OnValueChanged",function(self,value)
        if self.updating then return end
        local group=M.byID.mainComposite
        if not group or not M:CanEdit() then return end
        local scale=M.Clamp(math.floor(value*20+.5)/20,.1,1.5)
        scale=M:ScaleInputValue(group,scale)
        if math.abs((group.scale or 1)-scale)<.0001 then return end
        M:SetMainCompositeScaleFromCenter(group,scale);M:Commit()
    end)
    e.overallScaleSlider,e.overallScaleLabel=ScaleSlider("缩放","overallScale",function(group,scale)
        if group.id=="mainComposite" then M:SetMainCompositeScaleFromCenter(group,M:ScaleInputValue(group,scale))
        elseif group.id=="wabc757f81ee" then M:SetTargetProfileScaleFromCenter(group,M:ScaleInputValue(group,scale))
        else M:SetCompositeScaleFromCenter(group,scale,M:ScaleInputValue(group,scale)) end
    end)
    local function PlayerCastColorSwatch(key)
        local target
        local swatch=W.ColorSwatch(content,function(color)
            if not target or M.byID[target.id]~=target or not M:CanEdit() then return end
            target[key]=M.Copy(color);M:Commit()
        end)
        local click=swatch:GetScript("OnClick")
        swatch:SetScript("OnClick",function(self)
            local group=Selected()
            if not group or group.compound~="playerCast" or not M:CanEdit() then return end
            target=key=="color" and M.byID.waba76314011 or group
            if target then click(self) end
        end)
        return swatch
    end
    e.castColor=PlayerCastColorSwatch("color")
    local castColorLabel=W.Label(content,"施法条颜色")
    castColorLabel.whitePropertyLabel=true;M:SetLocaleLineHeight(castColorLabel,16.8)
    Row(30,{{castColorLabel,0,-3.6},{e.castColor,0,0,castColorLabel}},{},"castColor");y=y-30
    local function SetPortraitTextureEnabled(id,enabled)
        local group=Selected();local part=M.byID[id]
        if not group or group.id~="wabc757f81ee" or not part or part.parent~=group.id or not M:CanEdit() then
            M:RefreshProperties();return
        end
        if (part.enabled~=false)==enabled then return end
        part.enabled=enabled;M:Commit()
    end
    e.portraitLightEnabled=W.Check(content,"旋转内环",function(enabled)
        SetPortraitTextureEnabled("wa080cd4c4fb",enabled)
    end)
    e.portraitLightEnabled:SetPoint("TOPLEFT",-4,y)
    local portraitLightColorLabel=W.Label(content,"旋转内环颜色")
    portraitLightColorLabel.whitePropertyLabel=true
    e.portraitLightColor=W.ColorSwatch(content,function(color)
        local group=Selected();local light=M.byID.wa080cd4c4fb
        if not group or group.id~="wabc757f81ee" or not light or light.parent~=group.id or not M:CanEdit() then return end
        light.color=M.Copy(color);M:Commit()
    end)
    Row(30,{{e.portraitLightEnabled,-4,0},{e.portraitLightColor,160,-1},{portraitLightColorLabel,0,0,e.portraitLightColor}},{},"portraitLightEnabled");y=y-30
    local portraitLightScaleLabel=W.Label(content,"旋转内环缩放")
    e.portraitLightScaleSlider=BareSlider(propertyWidth-10,.5,3,.05)
    e.portraitLightScaleSlider:SetScript("OnValueChanged",function(self,value)
        if self.updating then return end
        local group=Selected();local light=M.byID.wa080cd4c4fb
        if not group or group.id~="wabc757f81ee" or not light or light.parent~=group.id or not M:CanEdit() then return end
        local scale=M.Clamp(math.floor(value*20+.5)/20,.5,3)
        scale=M:ScaleInputValue(light,scale)
        if math.abs((light.scale or 1)-scale)<.0001 then return end
        light.scale=scale;M:Commit()
    end)
    Row(49,{{portraitLightScaleLabel,0,-3},{e.portraitLightScaleSlider,4,-20}},{},"portraitLightScale");y=y-49
    e.portraitGlassEnabled=W.Check(content,"玻璃材质",function(enabled)
        SetPortraitTextureEnabled("wa291016c8c1",enabled)
    end)
    e.portraitGlassEnabled:SetPoint("TOPLEFT",-4,y)
    Row(30,{{e.portraitGlassEnabled,-4,0}},{},"portraitGlassEnabled");y=y-30
    local portraitGlassScaleLabel=W.Label(content,"玻璃缩放")
    e.portraitGlassScaleSlider=BareSlider(propertyWidth-10,.5,3,.05)
    e.portraitGlassScaleSlider:SetScript("OnValueChanged",function(self,value)
        if self.updating then return end
        local group=Selected();local glass=M.byID.wa291016c8c1
        if not group or group.id~="wabc757f81ee" or not glass or glass.parent~=group.id or not M:CanEdit() then return end
        local scale=M.Clamp(math.floor(value*20+.5)/20,.5,3)
        scale=M:ScaleInputValue(glass,scale)
        if math.abs((glass.scale or 1)-scale)<.0001 then return end
        glass.scale=scale;M:Commit()
    end)
    Row(49,{{portraitGlassScaleLabel,0,-3},{e.portraitGlassScaleSlider,4,-20}},{},"portraitGlassScale");y=y-49
    local portraitGlassAlphaLabel=W.Label(content,"玻璃透明度")
    portraitGlassAlphaLabel:SetPoint("TOPLEFT",0,y-3)
    e.portraitGlassAlphaSlider=BareSlider(propertyWidth-10,0,1,.01)
    e.portraitGlassAlphaSlider:SetPoint("TOPLEFT",4,y-20)
    e.portraitGlassAlphaSlider:SetIsPercent(true)
    e.portraitGlassAlphaSlider:SetScript("OnValueChanged",function(self,value)
        if self.updating then return end
        local group=Selected();local glass=M.byID.wa291016c8c1
        if not group or group.id~="wabc757f81ee" or not glass or glass.parent~=group.id or not M:CanEdit() then return end
        local alpha=M.Clamp(math.floor(value*100+.5)/100,0,1)
        if math.abs((glass.alpha or 1)-alpha)<.0001 then return end
        glass.alpha=alpha;M:Commit()
    end)
    Row(49,{{portraitGlassAlphaLabel,0,-3},{e.portraitGlassAlphaSlider,4,-20}},{},"portraitGlassAlpha");y=y-49
    local portraitAvatarScaleLabel=W.Label(content,"头像缩放")
    e.portraitAvatarScaleSlider=BareSlider(propertyWidth-10,.5,3,.05)
    e.portraitAvatarScaleSlider:SetScript("OnValueChanged",function(self,value)
        if self.updating then return end
        local group=Selected()
        if not group or group.id~="wabc757f81ee" or not M:CanEdit() then return end
        local scale=M.Clamp(math.floor(value*20+.5)/20,.5,3)
        local changed=false
        for _,id in ipairs({"wa88b1376baa","wa0b0b0540c7"}) do
            local avatar=M.byID[id]
            local actualScale=avatar and M:ScaleInputValue(avatar,scale)
            if avatar and avatar.parent==group.id and math.abs((avatar.scale or 1)-actualScale)>=.0001 then
                avatar.scale=actualScale;changed=true
            end
        end
        if changed then M:Commit() end
    end)
    Row(49,{{portraitAvatarScaleLabel,0,-3},{e.portraitAvatarScaleSlider,4,-20}},{},"portraitAvatarScale");y=y-49
    local portraitOuterScaleLabel=W.Label(content,"外圈缩放")
    e.portraitOuterScaleSlider=BareSlider(propertyWidth-10,.5,1.5,.05)
    e.portraitOuterScaleSlider:SetScript("OnValueChanged",function(self,value)
        if self.updating then return end
        local group=Selected();local frame=M.byID.wa92712c7b3d
        if not group or group.id~="wabc757f81ee" or not frame or frame.parent~=group.id or not M:CanEdit() then return end
        local scale=M.Clamp(math.floor(value*20+.5)/20,.5,1.5)
        scale=M:ScaleInputValue(frame,scale)
        if math.abs((frame.scale or 1)-scale)<.0001 then return end
        frame.scale=scale;M:Commit()
    end)
    Row(49,{{portraitOuterScaleLabel,0,-3},{e.portraitOuterScaleSlider,4,-20}},{},"portraitOuterScale");y=y-49
    local portraitTextureLabel=W.Label(content,"头像框体贴图")
    local portraitTextureChoices={}
    local portraitTextureNames={
        "01_BattleMaster","02_Champion","03_EldritchKnight","04_PsiWarrior",
        "05_Banneret","06_ArcaneArcher","07_Cavalier","08_EchoKnight",
        "08B_EchoKnightAlt","09_RuneKnight","10_Samurai","11_Frostiron",
    }
    for _,name in ipairs(portraitTextureNames) do
        local label=name:gsub("_"," ")
        portraitTextureChoices[#portraitTextureChoices+1]={
            M:ResolveAssetPath("Interface\\AddOns\\MangUI\\Assets\\TokenFrame\\TokenFrame_"..name),
            label,
        }
    end
    e.portraitFrameTexture=W.TextureGrid(content,propertyWidth,portraitTextureChoices,function(file)
        local group=Selected();local frame=M.byID.wa92712c7b3d
        if not group or group.id~="wabc757f81ee" or not frame or frame.parent~=group.id or not M:CanEdit() then
            M:RefreshProperties();return
        end
        frame.file=file;M:Commit()
    end)
    local portraitTextureHeight=e.portraitFrameTexture:GetHeight()+30
    Row(portraitTextureHeight,{{portraitTextureLabel,0,-3},{e.portraitFrameTexture,0,-22}},{},"portraitFrameTexture");y=y-portraitTextureHeight
    e.avatarScaleSlider,e.avatarScaleLabel=ScaleSlider("头像缩放","avatarScale",function(group,scale)
        local avatar=CompositeAvatar(group);if not avatar then return end
        avatar.scale=M:ScaleInputValue(avatar,scale)
        local minimum,maximum=AvatarXRange(group)
        avatar.x=M.Clamp(avatar.x or minimum,minimum,maximum)
    end)
    local xLabel=W.Label(content,"头像X偏移");xLabel:SetPoint("TOPLEFT",0,y-3)
    e.avatarXLabel=xLabel
    e.avatarXSlider=BareSlider(propertyWidth-10,-100,100,1);e.avatarXSlider:SetPoint("TOPLEFT",4,y-20)
    e.avatarXSlider:SetScript("OnValueChanged",function(self,value)
        if self.updating then return end
        local group=Selected();local avatar=CompositeAvatar(group)
        if not avatar or not M:CanEdit() then return end
        local minimum,maximum=AvatarXRange(group)
        local x=M.Clamp(RoundOffset(value),minimum,maximum)
        if avatar.x==x then return end
        avatar.x=x;M:Commit()
    end)
    Row(49,{{xLabel,0,-3},{e.avatarXSlider,4,-20}},nil,"avatarX");y=y-49
    local hpYLabel=W.Label(content,"生命条Y偏移");hpYLabel:SetPoint("TOPLEFT",0,y-3)
    e.totHPYSlider=BareSlider(propertyWidth-10,200,250,1);e.totHPYSlider:SetPoint("TOPLEFT",4,y-20)
    e.totHPYSlider:SetScript("OnValueChanged",function(self,value)
        if self.updating then return end
        local group=Selected()
        if not group or group.compound~="totComposite" or not M:CanEdit() then return end
        local hp=CompositePart(group,"totHP")
        if not hp then return end
        local position=M.Clamp(math.floor(value+.5),200,250)
        if hp.y==position then return end
        hp.y=position;M:Commit()
    end)
    Row(49,{{hpYLabel,0,-3},{e.totHPYSlider,4,-20}},nil,"totHPY");y=y-49
    e.totHPYLabel=hpYLabel
    Field("透明度","alpha",true,0,1,.01);Field("图层","layer",true,1,2000)
    e.enabled=W.Check(content,"显示元素",function(v)Change("enabled",v)end);e.enabled:SetPoint("TOPLEFT",-4,y)
    e.locked=W.Check(content,"锁定位置",function(v)Change("locked",v)end);e.locked:SetPoint("TOPLEFT",-4,y-30);y=y-64
    Row(64,{{e.enabled,-4,0},{e.locked,-4,-30}},nil,"flags")
    e.focusPortraitOnly=W.Check(content,"仅显示头像和名称",function(enabled)
        local group=Selected();if not group or group.id~="focusComposite" then return end
        if not M:CanEdit() then M:RefreshProperties();return end
        Change("portraitNameOnly",enabled)
    end)
    Row(32,{{e.focusPortraitOnly,-4,0}},{},"focusPortraitOnly");y=y-32
    e.materialButton=W.MediaSelect(content,"进度条材质",propertyWidth,"statusbar",function()M:OpenBarMaterialPicker()end)
    e.materialButton:SetPoint("TOPLEFT",0,y)
    Row(53,{{e.materialButton,0,0}},nil,"hpMaterial");y=y-53
    e.healthGradient=W.Check(content,"启用渐变",function(enabled)
        if not ChangeHealthStyle(HealthStyleBar(Selected()),"healthGradient",enabled) then M:RefreshProperties() end
    end)
    e.healthGradient.whitePropertyLabel=true
    e.healthGradient:SetPoint("TOPLEFT",-4,y)
    local function HealthColorSwatch(key)
        local target
        local swatch=W.ColorSwatch(content,function(color)ChangeHealthStyle(target,key,color)end)
        local click=swatch:GetScript("OnClick")
        swatch:SetScript("OnClick",function(self)
            target=HealthStyleBar(Selected())
            if target then click(self) end
        end)
        return swatch
    end
    e.healthStartColor=HealthColorSwatch("healthColor")
    e.healthEndColor=HealthColorSwatch("healthGradientEnd")
    local startLabel=W.Label(content,"进度条颜色/渐变开始颜色",11)
    local endLabel=W.Label(content,"渐变结束颜色",11)
    e.healthStartLabel=startLabel
    e.healthEndLabel=endLabel
    startLabel.whitePropertyLabel=true;endLabel.whitePropertyLabel=true
    startLabel:SetSize(166,24);startLabel:SetJustifyV("MIDDLE");startLabel:SetWordWrap(false)
    endLabel:SetSize(118,24);endLabel:SetJustifyV("MIDDLE");endLabel:SetWordWrap(false)
    e.healthGradient.label:SetSize(84,28);e.healthGradient.label:SetWordWrap(true);e.healthGradient.label:SetJustifyV("MIDDLE")
    M:FitLocaleText(e.healthGradient.label,84,9)
    M:FitLocaleText(startLabel,166,8)
    M:FitLocaleText(endLabel,118,8)
    Row(32,{{e.healthGradient,-4,0},{e.healthStartColor,112,2},{startLabel,0,0,e.healthStartColor},{e.healthEndColor,312,2},{endLabel,0,0,e.healthEndColor}},{},"healthColors");y=y-32
    e.healthThresholdEnabled=W.Check(content,"低生命值变色",function(enabled)
        if not ChangeHealthThreshold(HealthStyleBar(Selected()),"healthThresholdEnabled",enabled) then M:RefreshProperties() end
    end)
    e.healthThresholdEnabled.whitePropertyLabel=true
    Row(30,{{e.healthThresholdEnabled,-4,0}},{},"healthThresholdEnabled");y=y-30
    local thresholdLabel=W.Label(content,"生命值阈值",11)
    e.healthThreshold=W.SpinBox(content,propertyWidth/2,.01,1,.01);e.healthThreshold.isPercent=true
    e.healthThreshold:SetScript("OnValueChanged",function(self,value)
        if self.updating then return end
        local bar=HealthStyleBar(Selected());local percent=M.Clamp(math.floor(value*100+.5),1,100)
        if bar and bar.healthThreshold~=percent then ChangeHealthThreshold(bar,"healthThreshold",percent) end
    end)
    local thresholdTarget
    e.healthThresholdColor=W.ColorSwatch(content,function(color)ChangeHealthThreshold(thresholdTarget,"healthThresholdColor",color)end)
    local thresholdClick=e.healthThresholdColor:GetScript("OnClick")
    e.healthThresholdColor:SetScript("OnClick",function(self)
        thresholdTarget=HealthStyleBar(Selected())
        if thresholdTarget and thresholdTarget.id=="wa385c615b2a" then thresholdClick(self) end
    end)
    local thresholdColorLabel=W.Label(content,"低生命颜色",11);thresholdColorLabel.whitePropertyLabel=true
    Row(53,{{thresholdLabel,0,-3},{e.healthThreshold,0,-22},{e.healthThresholdColor,280,-17},{thresholdColorLabel,0,0,e.healthThresholdColor}},{},"healthThreshold");y=y-53
    local function NameSlider(label,key,field,minimum,maximum,step)
        local caption=W.Label(content,label);caption:SetPoint("TOPLEFT",0,y-3)
        local slider=BareSlider(propertyWidth-10,minimum,maximum,step);slider:SetPoint("TOPLEFT",4,y-20)
        slider:SetScript("OnValueChanged",function(self,value)
            if self.updating then return end
            local name=CompositeName(Selected())
            if not name or not M:CanEdit() then return end
            local lo,hi=minimum,maximum
            if field=="fontSize" then lo,hi=self:GetMinMaxValues()end
            local rounded=M.Clamp(math.floor(value/step+.5)*step,lo,hi)
            if field=="fontSize" then M:SetFontDisplaySize(name,rounded)
            else
                if name[field]==rounded then return end
                name[field]=rounded
            end
            M:Commit()
        end)
        Row(49,{{caption,0,-3},{slider,4,-20}},nil,key);y=y-49
        return slider,caption
    end
    e.petPowerHidden=W.Check(content,"隐藏宠物能量条",function(hidden)
        local group=Selected()
        if not group or group.compound~="petComposite" then return end
        if not M:CanEdit() then M:RefreshProperties();return end
        local power=CompositePart(group,"petMP")
        if not power or (power.enabled==false)==hidden then return end
        power.enabled=not hidden;M:Commit()
    end)
    Row(30,{{e.petPowerHidden,-4,0}},{},"petPowerHidden");y=y-30
    e.petNameEnabled=W.Check(content,"隐藏宠物名称",function(hidden)
        local group=Selected()
        if not group or group.compound~="petComposite" then return end
        if not M:CanEdit() then M:RefreshProperties();return end
        local name=CompositeName(group)
        if not name or (name.enabled==false)==hidden then return end
        name.enabled=not hidden;M:Commit()
    end)
    e.petNameEnabled:SetPoint("TOPLEFT",-4,y);e.petNameEnabled.label:SetTextColor(1,1,1)
    Row(30,{{e.petNameEnabled,-4,0}},{},"petNameEnabled");y=y-30
    e.nameXSlider,e.nameXLabel=NameSlider("焦点名称X偏移","nameX","x",100,400,1)
    e.nameYSlider,e.nameYLabel=NameSlider("焦点名称Y偏移","nameY","y",-100,100,1)
    e.nameFontButton=W.MediaSelect(content,"字体",propertyWidth,"font",function()M:OpenFocusFontPicker()end)
    e.nameFontButton:SetPoint("TOPLEFT",0,y)
    Row(53,{{e.nameFontButton,0,0}},nil,"nameFont");y=y-53
    e.nameSizeSlider,e.nameSizeLabel=NameSlider("字体大小","nameSize","fontSize",4,150,1)
    local function PlayerCastSlider(label,key,minimum,maximum)
        local caption=W.Label(content,label);caption:SetPoint("TOPLEFT",0,y-3)
        local slider=BareSlider(propertyWidth-10,minimum,maximum,1);slider:SetPoint("TOPLEFT",4,y-20)
        slider:SetScript("OnValueChanged",function(self,value)
            if self.updating then return end
            local group=Selected()
            if not IsCastGroup(group) or not M:CanEdit() then return end
            local lo,hi=minimum,maximum
            if key=="castFontSize" then lo,hi=self:GetMinMaxValues()end
            local size=M.Clamp(math.floor(value+.5),lo,hi)
            if key=="castIconSize" then
                local icon=CastPart(group,"wa8fa968f2a9")
                if not icon or (icon.width==size and icon.height==size) then return end
                icon.width=size;icon.height=size
            else
                local name=CastPart(group,"waba76314011sub3")
                local timer=CastPart(group,"waba76314011sub2")
                if not name then return end
                M:SetFontDisplaySize(name,size)
                if timer then M:SetFontDisplaySize(timer,size) end
            end
            M:Commit()
        end)
        Row(49,{{caption,0,-3},{slider,4,-20}},nil,key);y=y-49
        return slider,caption
    end
    e.castIconSizeSlider,e.castIconSizeLabel=PlayerCastSlider("施法图标大小","castIconSize",16,128)
    e.castFontSizeSlider,e.castFontSizeLabel=PlayerCastSlider("字体大小","castFontSize",4,150)
    e.hideCastName=W.Check(content,"隐藏施法名称",function(hidden)
        local group=Selected();local name=M.byID.targetCastName
        if not group or group.compound~="targetCast" or not name or not M:CanEdit() then return end
        name.enabled=not hidden;M:Commit()
    end)
    Row(32,{{e.hideCastName,-4,0}},nil,"hideCastName");y=y-32
    for _,entry in ipairs({{"showRangedProgress","显示远程攻击进度","rangedProgressColor"},{"showMeleeProgress","显示近战攻击进度","meleeProgressColor"}}) do
        local key=entry[1]
        local check=W.Check(content,entry[2],function(enabled)
            local group=Selected();if not group or group.compound~="playerCast" then return end
            if not M:CanEdit() then M:RefreshProperties();return end
            Change(key,enabled)
        end)
        local swatch=PlayerCastColorSwatch(entry[3]);e[entry[3]]=swatch
        e[key]=check;Row(30,{{check,-4,0},{swatch,0,0,check.label}},{},key);y=y-30
    end
    local function CastSlider(label,key,field,minimum,maximum)
        local caption=W.Label(content,label);caption:SetPoint("TOPLEFT",0,y-3)
        local slider=BareSlider(propertyWidth-10,minimum,maximum,1);slider:SetPoint("TOPLEFT",4,y-20)
        slider:SetScript("OnValueChanged",function(self,value)
            if self.updating then return end
            local group=Selected()
            local cast=CompositePart(group,"focusCast")
            local bar=CompositeBar(group,"focusCast","cast")
            if not cast or not bar or not M:CanEdit() then return end
            local target=(field=="width" or field=="height") and bar or cast
            local lo,hi=M.SettingRanges.Range(target,field)
            local rounded=M.Clamp(math.floor(value+.5),lo or minimum,hi or maximum)
            local sizeField=field=="width" or field=="height"
            if target[field]==rounded then return end
            target[field]=rounded
            if sizeField then
                local background=M.byID.wab2e0282c42bg
                if background and background.parent==cast.id then background[field]=rounded end
            end
            M:Commit()
        end)
        Row(49,{{caption,0,-3},{slider,4,-20}},nil,key);y=y-49
        return slider,caption
    end
    e.castXSlider,e.castXLabel=CastSlider("施法条X偏移","castX","x",159,498)
    e.castYSlider,e.castYLabel=CastSlider("施法条Y偏移","castY","y",-125,75)
    e.castWidthSlider,e.castWidthLabel=CastSlider("施法条宽度","castWidth","width",64,512)
    e.castHeightSlider,e.castHeightLabel=CastSlider("施法条高度","castHeight","height",4,40)
    local function Drop(label,choices,fn,key)
        local t=W.Label(content,label);t:SetPoint("TOPLEFT",0,y-3)
        local drop=W.Drop(content,propertyWidth,choices,fn);drop:SetPoint("TOPLEFT",0,y-22)
        local kinds
        if label=="混合" then kinds=mediaKinds elseif label=="播放方式" then kinds=spriteKinds
        elseif label=="光环类型" then kinds={auras=true}
        elseif label=="内容" then kinds={text=true,bar=true,icon=true}
        elseif label=="数据单位" then kinds={text=true,bar=true,portrait=true,icon=true,auras=true,hitbox=true} end
        Row(53,{{t,0,-3},{drop,0,-22}},kinds,key);y=y-53;return drop
    end
    e.unit=Drop("数据单位",unitChoices,function(v)Change("unit",v)end,"unit")
    e.binding=Drop("内容",bindingChoices,function(v)Change("binding",v)end,"binding")
    e.auraFilter=Drop("光环类型",{{"HELPFUL","增益"},{"HARMFUL","减益"}},function(v)Change("filter",v)end,"auraFilter")
    Field("图标上限","count",true,1,40);Field("图标间距","spacing",true,0,80)
    local function AuraGroupField(label,key)
        Field(label,key,true,1,40)
    end
    AuraGroupField("减益图标数量上限","debuffCount")
    AuraGroupField("每行减益图标数量","debuffPerRow")
    AuraGroupField("增益图标数量上限","buffCount")
    AuraGroupField("每行增益图标数量","buffPerRow")
    e.hideUntimedBuffs=W.Check(content,"隐藏无持续时间的增益",function(enabled)
        local group=Selected();if not group or group.id~="wa88e7259b1c" then return end
        if not M:CanEdit() then M:RefreshProperties();return end
        Change("hideUntimedBuffs",enabled)
    end)
    Row(32,{{e.hideUntimedBuffs,-4,0}},{},"hideUntimedBuffs");y=y-32
    e.onlyPlayerDebuffs=W.Check(content,"仅显示来源于自己的",function(enabled)
        local group=Selected();if not group or group.id~="wa026b04c50e" or not M:CanEdit() then return end
        Change("onlyPlayerDebuffs",enabled)
    end)
    Row(32,{{e.onlyPlayerDebuffs,-4,0}},{},"onlyPlayerDebuffs");y=y-32
    e.debuffHidden=W.Check(content,"隐藏",function(hidden)
        local group=Selected();if not group or group.id~="wa026b04c50e" or not M:CanEdit() then return end
        Change("enabled",not hidden)
    end)
    Row(32,{{e.debuffHidden,-4,0}},{},"debuffHidden");y=y-32
    e.playerHealthPercentHidden=W.Check(content,"隐藏",function(hidden)
        local node=Selected()
        if not node or node.id~="playerHealthPercent" or not M:CanEdit() then return end
        Change("enabled",not hidden)
    end)
    Row(32,{{e.playerHealthPercentHidden,-4,0}},{},"playerHealthPercentHidden");y=y-32
    Field("固定文字","text");Field("字体大小","fontSize",true,4,150);Field("贴图旋转","rotation",true,-360,360)
    Field("素材路径","file")
    local media=W.Button(content,"从素材库替换…",propertyWidth,function()M:OpenMedia()end);media:SetPoint("TOPLEFT",1,y);y=y-34
    Row(34,{{media,1,0}},mediaKinds,"media")
    e.blend=Drop("混合",{{"BLEND","正常"},{"ADD","叠加发光"},{"MOD","正片叠底"}},function(v)Change("blend",v)end,"blend")
    local t=W.Label(content,"颜色（0～1）");t:SetPoint("TOPLEFT",0,y);y=y-23
    Row(23,{{t,0,0}},colors,"colorTitle")
    local colorNames={"红色 R","绿色 G","蓝色 B","透明度 A"}
    for i=1,4 do
        local caption=W.Label(content,colorNames[i]);caption:SetPoint("TOPLEFT",0,y-3)
        local edit=W.SpinBox(content,(propertyWidth-4)/2,0,1,.01);edit:SetPoint("TOPLEFT",2,y-22);e.colors[i]=edit
        edit:SetScript("OnValueChanged",function(self,value)
            if self.updating then return end
            local n=Selected()
            if not n or not M:CanEdit() then M:RefreshProperties();return end
            n.color=n.color or {1,1,1,1};n.color[i]=M.Clamp(value,0,1);M:Commit()
        end)
        Row(53,{{caption,0,-3},{edit,2,-22}},colors,"color"..i);y=y-53
    end
    local title=W.Label(content,"进度与序列帧",13);title:SetPoint("TOPLEFT",0,y);y=y-25
    Row(25,{{title,0,0}},{bar=true,sprite=true},"progressTitle")
    e.reverse=W.Check(content,"反向填充",function(v)Change("reverse",v)end);e.reverse:SetPoint("TOPLEFT",-4,y);y=y-30
    Row(30,{{e.reverse,-4,0}},barKinds,"reverse")
    Field("横向裁切","cropX",true,0,4,.01);Field("纵向裁切","cropY",true,0,4,.01)
    Field("图集行数","rows",true,1,256);Field("图集列数","columns",true,1,256);Field("有效帧数","frames",true,1,4096);Field("播放帧率","fps",true,1,120)
    e.play=Drop("播放方式",{{"loop","循环"},{"bounce","往返"},{"once","单次"}},function(v)Change("play",v)end,"play")
    Field("模型 ID","model",true,1,99999999);Field("模型缩放","modelScale",true,.01,100,.01)
    Field("模型X偏移","modelX",true);Field("模型Y偏移","modelY",true);Field("模型Z偏移","modelZ",true)
    local rules=W.Label(content,"原始显示条件",13);rules:SetPoint("TOPLEFT",0,y);y=y-24
    Row(24,{{rules,0,0}},nil,"rulesTitle")
    e.ruleText=W.Label(content,"",11);e.ruleText:SetTextColor(1,1,1);e.ruleText:SetPoint("TOPLEFT",0,y);e.ruleText:SetWidth(propertyWidth);e.ruleText:SetWordWrap(true)
    Row(92,{{e.ruleText,0,0}},nil,"rules")
    y=y-92
    content:SetHeight(-y)
end


M.EditorInternals.BuildProperties=BuildProperties
