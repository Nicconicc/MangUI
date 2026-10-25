local _,M=...
local W,R=M.Widgets,M.Renderer
local unpack=unpack or table.unpack
local private=M.EditorInternals
local compositeParts=private.compositeParts
local MainBarPart=private.MainBarPart
local IsUnitComposite=private.IsUnitComposite
local IsCastGroup=private.IsCastGroup
local SetActualFontControl=private.SetActualFontControl
local CastPart=private.CastPart
local FontPreviewPath=private.FontPreviewPath
local FontChoiceName=private.FontChoiceName
local Selected=private.Selected
local OrganizePropertyRows=private.OrganizePropertyRows
local PropertyDivider=private.PropertyDivider
local SetGradientEndState=private.SetGradientEndState
local PositionPropertyControl=private.PositionPropertyControl
local CompositePart=private.CompositePart
local CompositeAvatar=private.CompositeAvatar
local CompositeBar=private.CompositeBar
local HealthStyleBar=private.HealthStyleBar
local CompositeName=private.CompositeName
local AvatarXRange=private.AvatarXRange
local PreviewModuleID=private.PreviewModuleID
local MainTextElement=private.MainTextElement

local function ResetDividers(e)
    e.propertyDividerCount=0
    for _,line in ipairs(e.propertyDividers) do line:Hide() end
end

local function RefreshProperties(self)
    local layoutEditor=self.editor
    layoutEditor.propertyDividers=layoutEditor.propertyDividers or {}
    local e=self.editor;local n=Selected()
    local selectedID=n and n.id or nil
    if e.propertySelection~=selectedID then
        e.propertyLayoutSignature=nil
        e.propertySelection=selectedID
        e.propScroll:SetVerticalScroll(0)
        if e.propScroll.ScrollBar then e.propScroll.ScrollBar:SetValue(0) end
    end
    local mainRoot=self.byID.mainComposite
    local moduleID=PreviewModuleID(n);local module=moduleID and self.byID[moduleID]
    local decoration=n and n.id=="centerFire"
    local showModuleEnabled=module~=nil and not decoration
        and (moduleID~="mainComposite" or selectedID=="mainComposite")
    local headerOffset=showModuleEnabled and 44 or 0
    e.moduleEnabled:SetShown(showModuleEnabled)
    e.moduleDivider:SetShown(showModuleEnabled)
    if module then e.moduleEnabled:SetChecked(module.enabled~=false) end
    local showMainScale=e.mainPreview and n~=nil and n.id=="mainComposite" and mainRoot~=nil
    if e.propTitle then
        e.propTitle:ClearAllPoints()
        e.propTitle:SetPoint("TOPLEFT",e.right,"TOPLEFT",13,-15-headerOffset)
        e.propTitle:SetTextColor(1,1,1)
    end
    if e.mainScaleHeader then
        if showMainScale then
            e.mainScaleHeader:ClearAllPoints()
            e.mainScaleHeader:SetPoint("TOPLEFT",e.right,"TOPLEFT",12,-15-headerOffset)
            e.mainScaleHeader:SetPoint("TOPRIGHT",e.right,"TOPRIGHT",-30,-15-headerOffset)
        end
        e.mainScaleHeader:SetShown(showMainScale)
        if mainRoot then
            e.mainScaleLabel:SetText("缩放")
            e.mainScaleSlider.updating=true;e.mainScaleSlider:SetValue(M.Clamp(M:ScaleDisplayValue(mainRoot),.1,1.5));e.mainScaleSlider.updating=false
        end
    end
    if n and n.noProperties then
        ResetDividers(e);e.propertyLayoutSignature=nil
        e.props:Hide();e.propTitle:Hide();e.empty:SetText("");e.empty:Show()
        return
    end
    if n and n.id=="mainComposite" then
        ResetDividers(e);e.propertyLayoutSignature=nil
        e.props:Show();e.propTitle:Hide();e.empty:Hide()
        e.propScroll:ClearAllPoints()
        e.propScroll:SetPoint("TOPLEFT",e.right,"TOPLEFT",12,-96-headerOffset)
        e.propScroll:SetPoint("BOTTOMRIGHT",e.right,"BOTTOMRIGHT",-30,12)
        e.propScroll:Hide();e.props:SetHeight(2)
        return
    end
    if n and n.id=="wabc757f81ee" then
        ResetDividers(e);e.propertyLayoutSignature=nil
        e.props:Show();e.propTitle:Show();e.empty:Hide()
        e.propTitle:SetText(n.label)
        e.propScroll:ClearAllPoints()
        e.propScroll:SetPoint("TOPLEFT",e.right,"TOPLEFT",12,-42-headerOffset)
        e.propScroll:SetPoint("BOTTOMRIGHT",e.right,"BOTTOMRIGHT",-30,12)
        e.propScroll:Show()
        e.overallScaleLabel:SetText("缩放")
        e.overallScaleSlider.updating=true;e.overallScaleSlider:SetValue(M.Clamp(M:ScaleDisplayValue(n),.5,1.5));e.overallScaleSlider.updating=false
        local frame=self.byID.wa92712c7b3d
        local light=self.byID.wa080cd4c4fb
        local glass=self.byID.wa291016c8c1
        e.portraitLightEnabled:SetChecked(light and light.enabled~=false or false)
        e.portraitLightColor:SetColor(light and light.color or {1,1,1,1})
        e.portraitLightScaleSlider.updating=true
        e.portraitLightScaleSlider:SetValue(M.Clamp(M:ScaleDisplayValue(light),.5,3))
        e.portraitLightScaleSlider.updating=false
        e.portraitGlassEnabled:SetChecked(glass and glass.enabled~=false or false)
        e.portraitGlassScaleSlider.updating=true
        e.portraitGlassScaleSlider:SetValue(M.Clamp(M:ScaleDisplayValue(glass),.5,3))
        e.portraitGlassScaleSlider.updating=false
        e.portraitGlassAlphaSlider.updating=true
        e.portraitGlassAlphaSlider:SetValue(M.Clamp(glass and glass.alpha or 1,0,1))
        e.portraitGlassAlphaSlider.updating=false
        local avatar=self.byID.wa0b0b0540c7 or self.byID.wa88b1376baa
        e.portraitAvatarScaleSlider.updating=true
        e.portraitAvatarScaleSlider:SetValue(M.Clamp(M:ScaleDisplayValue(avatar),.5,3))
        e.portraitAvatarScaleSlider.updating=false
        e.portraitOuterScaleSlider.updating=true
        e.portraitOuterScaleSlider:SetValue(M.Clamp(M:ScaleDisplayValue(frame),.5,1.5))
        e.portraitOuterScaleSlider.updating=false
        e.portraitFrameTexture:SetValue(frame and frame.file or "Interface\\AddOns\\MangUI\\Assets\\Library\\TokenFrame\\TokenFrame_01_BattleMaster")
        local y=0;local portraitRows={};local previousSection
        for _,row in ipairs(e.propRows) do
            local visible=row.key=="overallScale" or row.key=="portraitLightEnabled" or row.key=="portraitLightScale"
                or row.key=="portraitGlassEnabled" or row.key=="portraitGlassScale" or row.key=="portraitGlassAlpha"
                or row.key=="portraitAvatarScale" or row.key=="portraitOuterScale" or row.key=="portraitFrameTexture"
            portraitRows[#portraitRows+1]={row=row,visible=visible}
        end
        for _,entry in ipairs(OrganizePropertyRows(n,portraitRows))do
            local row,visible=entry.row,entry.visible
            if visible and previousSection and previousSection~=entry.section then y=-PropertyDivider(e,-y)end
            for _,control in ipairs(row.controls) do
                control[1]:SetShown(visible)
                if visible then
                    PositionPropertyControl(control,e.props,y)
                end
            end
            if visible then y=y-row.height;previousSection=entry.section end
        end
        e.props:SetHeight(-y+10)
        return
    end
    e.empty:SetText("从左侧列表或画布选择元素")
    e.props:SetShown(n~=nil);e.empty:SetShown(n==nil)
    e.propTitle:SetShown(n~=nil and not IsUnitComposite(n) and n.id~="wa8d650f8d3a" and n.compound~="partyFrames" and n.compound~="bossFrames" and n.compound~="playerSkillMonitor" and n.compound~="playerOtherMonitor" and n.compound~="cooldownMonitor" and n.compound~="raidBuffs" and n.compound~="receivedBuffs" and n.compound~="raidVulnerability" and n.compound~="commonItems" and n.compound~="chatButtons" and n.compound~="combatNotices" and n.compound~="systemMenu" and n.compound~="mouseCircle" and n.compound~="experienceBar" and n.compound~="targetThreat" and n.compound~="targetDistance")
    if not n then ResetDividers(e);e.propertyLayoutSignature=nil;return end
    e.propScroll:ClearAllPoints()
    e.propScroll:SetPoint("TOPLEFT",e.right,"TOPLEFT",12,((IsUnitComposite(n) or n.id=="wa8d650f8d3a" or n.compound=="partyFrames" or n.compound=="bossFrames" or n.compound=="playerSkillMonitor" or n.compound=="playerOtherMonitor" or n.compound=="cooldownMonitor" or n.compound=="raidBuffs"or n.compound=="receivedBuffs"or n.compound=="raidVulnerability"or n.compound=="commonItems" or n.compound=="chatButtons" or n.compound=="combatNotices" or n.compound=="systemMenu" or n.compound=="mouseCircle" or n.compound=="experienceBar" or n.compound=="targetThreat" or n.compound=="targetDistance") and -12 or -42)-headerOffset)
    e.propScroll:SetPoint("BOTTOMRIGHT",e.right,"BOTTOMRIGHT",-30,12)
    e.propScroll:Show()
    local valueTextTitle=n.id=="wadb51e41246" or n.id=="wa8ee62b16d6" or n.id=="wa6edbcf125a"
        or n.id=="wa8492858a6d" or n.id=="wa074335b474" or n.id=="wa712a8bee10" or n.id=="playerHealthPercent"
    e.propTitle:SetText(decoration and "头像框体装饰" or n.id=="targetUnifiedName" and "目标名字" or n.id=="playerResources" and "玩家资源" or n.id=="centerClassification" and "稀有精英图标" or n.id=="waf24f8d43e3" and "团队标记" or ((n.compound or valueTextTitle) and n.label or ((self.kindLabels[n.kind] or n.kind).." · "..n.label)))
    e.propTitle:SetTextColor(1,1,1)
    if n.id=="wa026b04c50e" then e.propTitle:SetText("目标Debuff")
    elseif n.id=="wa88e7259b1c" then e.propTitle:SetText("目标Buff") end
    e.coordXLabel:SetText("X偏移")
    e.coordYLabel:SetText("Y偏移")
    e.decorationHidden:SetChecked(n.enabled==false)
    for field,edit in pairs(e.fields) do
        if not edit:HasFocus() then
            local minimum,maximum=M.SettingRanges.Range(n,field)
            if minimum or field=="x" or field=="y" then
                edit.updating=true
                edit:SetMinMaxValues(minimum or -10000,maximum or 10000)
                edit.updating=false
            elseif field=="scale" then
                edit.updating=true
                if n.compound=="partyFrames" or n.compound=="bossFrames" or n.compound=="playerSkillMonitor" or n.compound=="playerOtherMonitor" or n.compound=="cooldownMonitor" or n.compound=="raidBuffs"or n.compound=="receivedBuffs"or n.compound=="raidVulnerability"or n.compound=="commonItems" or n.compound=="chatButtons" or n.compound=="combatNotices" or n.compound=="systemMenu" or n.compound=="mouseCircle" or n.compound=="experienceBar" then edit:SetMinMaxValues(.1,2)
                else edit:SetMinMaxValues(.05,10) end
                edit.updating=false
            end
            local value=n[field]
            if field=="scale" or field=="modelScale" then value=M:ScaleDisplayValue(n,field)end
            if field=="fontSize" and (n.kind=="text" or n.compound=="chatButtons" or n.compound=="targetThreat" or n.compound=="targetDistance") then
                value=math.floor(M:FontDisplaySize(n)*100+.5)/100
                edit.updating=true;edit:SetMinMaxValues(math.min(4,value),math.max(150,value));edit.updating=false
            end
            if value==nil and (field=="scale" or field=="modelScale" or field=="alpha") then value=1 end
            if edit.inputNameKind then W.SetInputValue(edit,value)else edit:SetText(tostring(value or ""))end
        end
    end
    if n.compound=="cooldownMonitor" then e.cooldownBlacklist:SetBlacklist(n.blacklist or "") end
    if n.compound=="chatButtons" then e.chatTextLabels:SetChecked(n.textLabels==true) end
    if n.compound=="targetThreat" then e.threatInstanceOnly:SetChecked(n.instanceOnly~=false) end
    if n.compound=="combatNotices" or n.compound=="bossFrames" then e.combatSound:SetChecked(n.soundEnabled~=false) end
    if n.compound=="partyFrames" then
        e.partyHideInRaid:SetChecked(n.hidePartyInRaid==true)
        e.partyHideNumbers:SetChecked(n.hidePartyNumbers==true)
        e.partyHidePlayer:SetChecked(n.hidePartyPlayer==true)
        e.partyGradient:SetChecked(n.partyHealthGradient==true)
        e.partyMaterialButton:SetMedia(n.partyMaterialName,n.partyMaterialPath~="" and n.partyMaterialPath or nil)
        e.partyHPColor:SetColor(n.partyHealthColor);e.partyHPEndColor:SetColor(n.partyHealthEndColor)
        SetGradientEndState(e.partyHPEndColor,e.partyHPEndLabel,n.partyHealthGradient==true)
        e.partyFontButton:SetMedia(n.partyFontName,n.partyFontPath)
        for key,edit in pairs(e.partyFields)do
            if not edit:HasFocus()then
                edit.updating=true
                local lo,hi=M.SettingRanges.Range(n,key)
                if lo then edit:SetMinMaxValues(lo,hi) end
                if key=="partyNameSize" then SetActualFontControl(edit,(n[key] or 14)*M:FontDisplayScale(M.byID.party1Name),4,48)
                else edit:SetValue(n[key]);edit.updating=false end
            end
        end
    end
    if n.compound=="bossFrames" then
        local hp,percent,cast=M.byID.bossHPFill,M.byID.bossHPPercent,M.byID.bossCast
        e.bossHideAvatar:SetChecked(n.hideAvatar==true)
        e.bossMaterialButton:SetMedia(hp.materialName or "MangUI",hp.materialPath)
        e.bossHPColor:SetColor(hp.color)
        e.bossCastColor:SetColor(M.byID.bossCastFill.color)
        e.bossFontButton:SetMedia(FontChoiceName(percent),FontPreviewPath(percent))
        local values={bossPercentX=percent.x,bossPercentY=percent.y,bossPercentSize=M:FontDisplaySize(percent),bossCastY=cast.y}
        for key,value in pairs(values) do
            local edit=e.bossFields[key]
            if not edit:HasFocus() then
                if key=="bossPercentSize" then SetActualFontControl(edit,value,4,150)
                else edit.updating=true;edit:SetValue(value);edit.updating=false end
            end
        end
    end
    if n.compound=="mouseCircle" then for key,swatch in pairs(e.mouseColors) do swatch:SetColor(n[key]) end end
    if n.compound=="targetDistance" then
        e.distanceRingCheck:SetChecked(n.showOnRing~=false)
        e.distanceNameplateCheck:SetChecked(n.showOnNameplate~=false)
        e.distanceNumberCheck:SetChecked(n.showDistanceNumber~=false)
        e.distanceFriendlyCheck:SetChecked(n.hideFriendlyDistanceNumber==true)
        e.distanceNumberColor:SetColor(n.distanceNumberColor or {1,1,1,1})
        for _,class in ipairs(e.rangeClasses) do
            local token=class[1];local manual=n["rangeManual"..token]==true
            local input=e.fields["rangeSpell"..token]
            e.rangeManualChecks["rangeManual"..token]:SetChecked(manual)
            if manual then input:ClearFocus();input:Disable() else input:Enable() end
            input:SetTextColor(1,1,1)
            input:EnableMouse(not manual);input:SetAlpha(manual and .45 or 1)
            input.rangeSkillIcon:SetAlpha(manual and .45 or 1)
            input:UpdateRangeSpellIcon()
            e.fields["range"..token]:SetEnabled(manual)
        end
    end
    if IsUnitComposite(n) then
        local avatar=CompositeAvatar(n)
        local overallScale=M:ScaleDisplayValue(n)
        e.overallScaleLabel:SetText("缩放")
        local unitLabel=({focusComposite="焦点",petComposite="宠物",totComposite="目标的目标"})[n.compound]
        e.avatarXLabel:SetText(unitLabel.."头像X偏移")
        e.avatarScaleLabel:SetText("头像缩放")
        e.overallScaleSlider.updating=true;e.overallScaleSlider:SetValue(M.Clamp(overallScale,.5,1.5));e.overallScaleSlider.updating=false
        e.avatarScaleSlider.updating=true;e.avatarScaleSlider:SetValue(M.Clamp(M:ScaleDisplayValue(avatar),.5,1.5));e.avatarScaleSlider.updating=false
        local minimum,maximum=AvatarXRange(n)
        e.avatarXSlider.updating=true
        e.avatarXSlider:SetMinMaxValues(minimum,maximum)
        e.avatarXSlider:SetValue(M.Clamp(avatar and (avatar.x or minimum) or minimum,minimum,maximum))
        e.avatarXSlider.updating=false
        if n.compound=="totComposite" then
            local hp=CompositePart(n,"totHP")
            if hp then
                e.totHPYSlider.updating=true
                e.totHPYSlider:SetValue(M.Clamp(hp.y or 250,200,250))
                e.totHPYSlider.updating=false
                e.totHPYLabel:SetText("生命条Y偏移")
            end
        end
        local name=CompositeName(n)
        if n.compound=="petComposite" then
            for i,edit in ipairs(e.petBuffInputs) do
                if not edit:HasFocus() then W.SetInputValue(edit,n["petBuff"..i] or "") end
            end
            e.petNameEnabled:SetChecked(name and name.enabled==false or false)
            local power=CompositePart(n,"petMP")
            e.petPowerHidden:SetChecked(power and power.enabled==false or false)
        end
        if name then
            for _,entry in ipairs({{e.nameXSlider,name.x or 200,100,400},{e.nameYSlider,name.y or 0,-100,100}}) do
                entry[1].updating=true;entry[1]:SetValue(M.Clamp(entry[2],entry[3],entry[4]));entry[1].updating=false
            end
            SetActualFontControl(e.nameSizeSlider,M:FontDisplaySize(name),4,150)
            local unitLabel=({focusComposite="焦点",petComposite="宠物",totComposite="目标的目标"})[n.compound]
            e.nameXLabel:SetText(unitLabel.."名称X偏移")
            e.nameYLabel:SetText(unitLabel.."名称Y偏移")
            e.nameSizeLabel:SetText("字体大小")
            e.nameFontButton:SetMedia(FontChoiceName(name),FontPreviewPath(name))
        end
        local cast=CompositePart(n,"focusCast")
        local castBar=CompositeBar(n,"focusCast","cast")
        if cast and castBar then
            local ranges=M.SettingRanges.FocusCast()
            for _,entry in ipairs({{e.castXSlider,cast.x or 371,unpack(ranges.x)},
                {e.castYSlider,cast.y or -98,unpack(ranges.y)},{e.castWidthSlider,castBar.width or 173,unpack(ranges.width)},
                {e.castHeightSlider,castBar.height or 12,4,40}}) do
                entry[1].updating=true;entry[1]:SetMinMaxValues(entry[3],entry[4])
                entry[1]:SetValue(M.Clamp(entry[2],entry[3],entry[4]));entry[1].updating=false
            end
            e.castXLabel:SetText("施法条X偏移")
            e.castYLabel:SetText("施法条Y偏移")
            e.castWidthLabel:SetText("施法条宽度")
            e.castHeightLabel:SetText("施法条高度")
        end
    end
    if IsCastGroup(n) then
        if n.compound=="targetCast" then e.hideCastName:SetChecked(self.byID.targetCastName and self.byID.targetCastName.enabled==false)end
        if n.compound=="playerCast" then
            local name=CastPart(n,"waba76314011sub3")
            e.hidePlayerCastText:SetChecked(name and name.enabled==false)
            e.castColor:SetColor(M.byID.waba76314011.color or {1,1,1,1})
            e.rangedProgressColor:SetColor(n.rangedProgressColor or {1,1,1,1})
            e.meleeProgressColor:SetColor(n.meleeProgressColor or {1,1,1,1})
        end
        e.showRangedProgress:SetChecked(n.showRangedProgress==true)
        e.showMeleeProgress:SetChecked(n.showMeleeProgress==true)
        local icon=CastPart(n,"wa8fa968f2a9")
        local name=CastPart(n,"waba76314011sub3")
        e.overallScaleLabel:SetText("缩放")
        e.overallScaleSlider.updating=true
        e.overallScaleSlider:SetValue(M.Clamp(M:ScaleDisplayValue(n),.5,1.5))
        e.overallScaleSlider.updating=false
        if icon then
            e.castIconSizeLabel:SetText("施法图标大小")
            e.castIconSizeSlider.updating=true
            e.castIconSizeSlider:SetValue(M.Clamp(icon.width or 45,16,128))
            e.castIconSizeSlider.updating=false
        end
        if name then
            e.castFontSizeLabel:SetText("字体大小")
            SetActualFontControl(e.castFontSizeSlider,M:FontDisplaySize(name),4,150)
            e.nameFontButton:SetMedia(FontChoiceName(name),FontPreviewPath(name))
        end
    end
    e.enabled:SetChecked(n.enabled~=false);e.locked:SetChecked(n.locked or false)
    local healthBar=HealthStyleBar(n)
    if healthBar then
        local start=healthBar.healthColor or healthBar.color or {0,1,.42745101451874,1}
        e.healthGradient:SetChecked(healthBar.healthGradient==true)
        e.healthStartColor:SetColor(start)
        e.healthEndColor:SetColor(healthBar.healthGradientEnd or start)
        SetGradientEndState(e.healthEndColor,e.healthEndLabel,healthBar.healthGradient==true)
        if healthBar.id=="wa385c615b2a" then
            e.healthThresholdEnabled:SetChecked(healthBar.healthThresholdEnabled==true)
            e.healthThreshold.updating=true;e.healthThreshold:SetValue((healthBar.healthThreshold or 25)/100);e.healthThreshold.updating=false
            e.healthThresholdColor:SetColor(healthBar.healthThresholdColor or {1,0,0,1})
        end
    end
    if e.materialButton then
        local mainBar=MainBarPart(n)
        local bar=self.byID[mainBar and mainBar.bar or (n.compound=="focusMP" and "waeddad93083" or "wa916b193e98")]
        if n.id=="playerThirdResource"then
            bar=self.byID.playerThirdResourceFill
            e.materialButton:SetMedia(bar and bar.materialName or "默认",bar and bar.materialPath)
        elseif mainBar then
            e.materialButton:SetMedia(bar and bar.materialName or "Solid",bar and (bar.materialPath or "Interface\\Buttons\\WHITE8X8"))
        elseif IsUnitComposite(n) then
            local parts=compositeParts[n.compound]
            local hp=CompositeBar(n,parts.hp,"health")
            local mp=parts.mp and CompositeBar(n,parts.mp,"power")
            if hp and mp and not M:SameTexture(hp.materialPath,mp.materialPath) then
                e.materialButton:SetMedia("血量／能量材质不同",nil)
            else
                local source=hp or mp
                e.materialButton:SetMedia(source and source.materialName or "Solid",source and (source.materialPath or "Interface\\Buttons\\WHITE8X8"))
            end
        else
            local source=n.compound=="focusMP" and "TargetPowerColor" or "TargetHPColor"
            e.materialButton:SetMedia(bar and bar.materialName or "Solid",bar and (bar.materialPath or "Interface\\Buttons\\WHITE8X8"))
        end
    end
    if MainTextElement(n) or n.compound=="chatButtons" or n.compound=="experienceBar" or n.compound=="targetThreat" or n.compound=="targetDistance" then
        e.nameFontButton:SetMedia(FontChoiceName(n),FontPreviewPath(n))
    end
    e.unit:SetValue(n.unit or "player");e.binding:SetValue(n.binding or "static")
    e.blend:SetValue(n.blend or "BLEND");e.play:SetValue(n.play or "loop")
    e.auraFilter:SetValue(n.filter or "HELPFUL")
    e.focusPortraitOnly:SetChecked(n.portraitNameOnly==true)
    e.hideUntimedBuffs:SetChecked(n.hideUntimedBuffs==true)
    e.onlyPlayerDebuffs:SetChecked(n.onlyPlayerDebuffs==true)
    e.debuffHidden:SetChecked(n.enabled==false)
    e.playerHealthPercentHidden:SetChecked(n.enabled==false)
    e.reverse:SetChecked(n.reverse or false)
    local c=n.color or {1,1,1,1}
    for i,edit in ipairs(e.colors) do if not edit:HasFocus() then edit:SetText(string.format("%.2f",c[i] or 1)) end end
    local rules={}
    for _,rule in ipairs(n.rules or {}) do rules[#rules+1]=(rule.invert and "非 " or "")..(rule.unit or "player").." · "..({casting="施法中",exists="单位存在",classification="分类",isPlayer="玩家",friendly="友方",leader="队长",afk="暂离",dead="死亡",hearth="炉石",raid="团队标记"})[rule.test] end
    e.ruleText:SetText(#rules>0 and table.concat(rules,"\n") or "跟随所属单位显示")
    M.MonitorSharing.RefreshControls(e,n)
    if M.ModuleGuides.Supports(n)and n.id~="raidBuffs"then e.moduleGuidePanel:Refresh(n)end
    if n.compound=="raidBuffs"then
        e.skillMonitorHideWithoutTarget:SetChecked(n.hideWithoutTarget==true)
        e.raidBuffsOnlyRaid:SetChecked(n.raidOnly~=false)
        e.skillMonitorDirection:SetValue(M.PlayerSkillMonitor.Direction(n))
        e.raidBuffsSharedPanel:Refresh(n)
        e.raidBuffsGuidePanel:Refresh(n)
    end
    if n.compound=="receivedBuffs"then
        e.skillMonitorHideWithoutTarget:SetChecked(n.hideWithoutTarget==true)
        e.skillMonitorDirection:SetValue(M.PlayerSkillMonitor.Direction(n))
        e.receivedBuffPanel:Refresh(n)
    end
    if n.compound=="raidVulnerability"then
        e.skillMonitorHideWithoutTarget:SetChecked(n.hideWithoutTarget==true)
        e.raidBuffsOnlyRaid:SetChecked(n.raidOnly~=false)
        e.skillMonitorDirection:SetValue(M.PlayerSkillMonitor.Direction(n))
        e.raidVulnerabilitySharedPanel:Refresh(n)
    end
    if n.compound=="commonItems"then
        e.skillMonitorHideWithoutTarget:SetChecked(n.hideWithoutTarget==true)
        e.skillMonitorDirection:SetValue(M.PlayerSkillMonitor.Direction(n))
        e.commonItemsSharedPanel:Refresh(n)
    end
    if n.compound=="playerOtherMonitor" then
        e.skillMonitorHideWithoutTarget:SetChecked(n.hideWithoutTarget==true)
        e.skillMonitorDirection:SetValue(M.PlayerSkillMonitor.Direction(n))
        e.otherMonitorPanel:Refresh(n)
    end
    if n.compound=="playerSkillMonitor" then
        e.skillMonitorHideWithoutTarget:SetChecked(n.hideWithoutTarget==true)
        e.skillMonitorDirection:SetValue(M.PlayerSkillMonitor.Direction(n))
        e.skillMonitorPanel:Refresh(n)
    end
    local rows={}
    local propertyRows=e.propRows or {}
    for _,row in ipairs(propertyRows) do
        local visible=not row.kinds or row.kinds[n.kind]
        if n.compound then
            if IsUnitComposite(n) then
                visible=row.key=="overallScale" or row.key=="avatarScale" or row.key=="avatarX" or row.key=="hpMaterial"
                    or row.key=="nameX" or row.key=="nameY" or row.key=="nameFont" or row.key=="nameSize"
                    or (n.compound=="petComposite" and (row.key=="petNameEnabled" or row.key=="petPowerHidden"
                        or row.key=="petBuffTitle" or (row.key and row.key:match("^petBuff%d$"))))
                    or (n.compound=="totComposite" and row.key=="totHPY")
                    or (n.compound=="focusComposite" and (row.key=="castX" or row.key=="castY"
                        or row.key=="castWidth" or row.key=="castHeight" or row.key=="focusPortraitOnly"))
            elseif IsCastGroup(n) then
                visible=row.key=="overallScale" or row.key=="castIconSize"
                    or row.key=="castFontSize" or row.key=="nameFont"
                    or (n.compound=="targetCast" and (row.key=="x" or row.key=="y" or row.key=="hideCastName"))
                    or (n.compound=="playerCast" and (row.key=="hidePlayerCastText" or row.key=="castColor" or row.key=="showRangedProgress" or row.key=="showMeleeProgress"))
            elseif n.compound=="playerOtherMonitor" then
                visible=row.key=="scale"or row.key=="skillMonitorHideWithoutTarget"or row.key=="skillMonitorDirection"or row.key=="otherMonitorSharing"or row.key=="otherMonitorItems"or row.key=="otherMonitorEquipment"
            elseif n.compound=="playerSkillMonitor" then
                visible=row.key=="scale" or row.key=="skillMonitorHideWithoutTarget"or row.key=="skillMonitorDirection"or row.key=="skillMonitorSharing"or row.key=="skillMonitorItems"
            elseif n.compound=="raidBuffs"then
                visible=row.key=="scale"or row.key=="skillMonitorHideWithoutTarget"or row.key=="raidBuffsOnlyRaid"or row.key=="skillMonitorDirection"or row.key=="raidBuffsSharing"or row.key=="raidBuffsSharedRows"or row.key=="raidBuffsGuideSettings"
            elseif n.compound=="receivedBuffs"then
                visible=row.key=="scale"or row.key=="skillMonitorHideWithoutTarget"or row.key=="skillMonitorDirection"or row.key=="receivedBuffSharing"or row.key=="receivedBuffItems"
            elseif n.compound=="raidVulnerability"then
                visible=row.key=="scale"or row.key=="skillMonitorHideWithoutTarget"or row.key=="raidBuffsOnlyRaid"or row.key=="skillMonitorDirection"or row.key=="raidVulnerabilitySharing"or row.key=="raidVulnerabilitySharedRows"
            elseif n.compound=="commonItems"then
                visible=row.key=="scale"or row.key=="skillMonitorHideWithoutTarget"or row.key=="skillMonitorDirection"or row.key=="commonItemsSharing"or row.key=="commonItemsSharedRows"
            elseif n.compound=="cooldownMonitor" then
                visible=row.key=="scale" or row.key=="minCooldown" or row.key=="maxCooldown" or row.key=="blacklist"
            elseif n.compound=="chatButtons" then
                visible=row.key=="iconSize" or row.key=="nameFont" or row.key=="fontSize" or row.key=="fontYOffset" or row.key=="buttonSpacing"
                    or row.key=="pullSeconds" or row.key=="customChannelName" or row.key=="chatTextLabels"
            elseif n.compound=="bossFrames" then
                visible=row.key=="scale" or row.key=="combatSound" or (row.key and row.key:find("^boss")~=nil)
            elseif n.compound=="partyFrames" then
                visible=row.key=="scale" or (row.key and row.key:find("^party")~=nil)
            elseif n.compound=="combatNotices" then
                visible=row.key=="scale" or row.key=="combatSound"
            elseif n.compound=="targetThreat" then
                visible=row.key=="nameFont" or row.key=="fontSize" or row.key=="threatInstanceOnly"
            elseif n.compound=="targetDistance" then
                visible=row.key=="showOnRing" or row.key=="showOnNameplate"
                    or row.key=="showDistanceNumber" or row.key=="hideFriendlyDistanceNumber" or row.key=="nameFont" or row.key=="fontSize" or row.key=="distanceNumberColor"
                    or row.key=="distanceIconSize" or row.key=="distanceX" or row.key=="distanceY"
                    or row.key=="distanceTitle" or row.key=="distanceHint" or (row.key and row.key:find("^range")~=nil)
            elseif n.compound=="experienceBar" then
                visible=row.key=="scale" or row.key=="nameFont" or row.key=="experienceHeight"
            elseif n.compound=="systemMenu" then
                visible=row.key=="scale"
            elseif n.compound=="mouseCircle" then
                visible=row.key=="scale" or row.key=="mouseColors"
            else
                visible=row.key=="x" or row.key=="y" or row.key=="scale" or row.key=="flags"
                if (n.compound=="focusHP" or n.compound=="focusMP") and row.key=="hpMaterial" then visible=true end
            end
        end
        if MainBarPart(n) then visible=row.key=="x" or row.key=="hpMaterial" end
        if row.key=="healthGradient" or row.key=="healthColors" then visible=healthBar~=nil end
        if row.key=="healthThresholdEnabled" or row.key=="healthThreshold" then visible=n.id=="waf465575a72" end
        if MainTextElement(n) then
            visible=row.key=="x" or row.key=="y" or row.key=="fontSize" or row.key=="nameFont"
                or (n.id=="playerHealthPercent" and row.key=="playerHealthPercentHidden")
        end
        if n.id=="wa026b04c50e" then
            visible=row.key=="x" or row.key=="y" or row.key=="scale"
                or row.key=="debuffCount" or row.key=="debuffPerRow"
                or row.key=="onlyPlayerDebuffs" or row.key=="debuffHidden"
        end
        if n.id=="wa88e7259b1c" then
            visible=row.key=="x" or row.key=="y" or row.key=="scale"
                or row.key=="buffCount" or row.key=="buffPerRow"
                or row.key=="hideUntimedBuffs"
        end
        if n.id=="waf24f8d43e3" then
            visible=row.key=="x" or row.key=="y" or row.key=="scale"
        end
        if n.id=="wad38d9b944e" or n.id=="wad25ba7d231" then
            visible=row.key=="x" or row.key=="y" or row.key=="scale"
        end
        if n.id=="centerClassification" then
            visible=row.key=="x" or row.key=="y" or row.key=="scale"
        end
        if n.id=="playerThirdResource"then
            visible=row.key=="x"or row.key=="hpMaterial"
        end
        if n.id=="playerResources" then
            visible=row.key=="x" or row.key=="y" or row.key=="scale"
                or row.key=="resourceSpacing"
        end
        if decoration then
            visible=row.key=="decorationHidden" or row.key=="x" or row.key=="y" or row.key=="scale"
        end
        if e.mainPreview and row.key=="overallScale" and n.compound~="targetCast" then visible=false end
        if row.key=="moduleGuideSettings"then visible=M.ModuleGuides.Supports(n)and n.id~="raidBuffs"end
        rows[#rows+1]={row=row,visible=visible}
    end
    OrganizePropertyRows(n,rows)
    local layoutKey={selectedID,tostring(n.compound),tostring(e.props:GetWidth()),tostring(e.propertyRatio),
        tostring(headerOffset),M:EffectiveLanguage()}
    for _,entry in ipairs(rows) do
        layoutKey[#layoutKey+1]=tostring(entry.row.key)..":"..tostring(entry.visible)..":"..tostring(entry.section)
    end
    local signature=table.concat(layoutKey,"|")
    if e.propertyLayoutSignature==signature then return end
    e.propertyLayoutSignature=signature
    ResetDividers(e)
    -- Pair visible font and size controls on one row; party keeps its own column layout.
    local fontPairs={};local byKey={}
    for _,entry in ipairs(rows)do if entry.row.key then byKey[entry.row.key]=entry end end
    for _,fontKey in ipairs({"nameFont","bossFont"})do
        local fontEntry=byKey[fontKey]
        if fontEntry then
            local font=fontEntry.row.controls[1][1]
            font:SetWidth((font.propertyLayoutWidth or 470)*(e.propertyRatio or 1))
            if n.compound~="partyFrames" and fontEntry.visible then
                local sizeKeys=fontKey=="bossFont" and {"bossPercentSize"}or {"nameSize","castFontSize","fontSize"}
                for _,key in ipairs(sizeKeys)do
                    local sizeEntry=byKey[key]
                    if sizeEntry and sizeEntry.visible then
                        sizeEntry.fontPairHidden=true
                        fontPairs[#fontPairs+1]={fontEntry=fontEntry,sizeEntry=sizeEntry,font=font}
                        break
                    end
                end
            end
        end
    end
    local offsetPairs={}
    if n.compound~="partyFrames"then
        for _,keys in ipairs({{"skillMonitorHideWithoutTarget","raidBuffsOnlyRaid"},{"x","y"},{"nameX","nameY"},{"bossPercentX","bossPercentY"},
            {"castX","castY"},{"castWidth","castHeight"},{"distanceX","distanceY"}})do
            local left,right=byKey[keys[1]],byKey[keys[2]]
            if left and right and left.visible and right.visible then
                right.inlineHidden=true;offsetPairs[#offsetPairs+1]={left.row.controls,right.row.controls}
            end
        end
    end
    local height=0;local previousSection
    for _,entry in ipairs(rows) do
        local row,visible=entry.row,entry.visible and not entry.fontPairHidden and not entry.inlineHidden
        if visible and previousSection and previousSection~=entry.section then
            height=PropertyDivider(e,height)
            if row.key=="moduleGuideSettings"or (n.compound=="raidBuffs"and (row.key=="raidBuffsSharing"or row.key=="raidBuffsSharedRows"or row.key=="raidBuffsGuideSettings"))
                or (n.compound=="receivedBuffs"and (row.key=="receivedBuffSharing"or row.key=="receivedBuffItems"))
                or (n.compound=="raidVulnerability"and (row.key=="raidVulnerabilitySharing"or row.key=="raidVulnerabilitySharedRows"))
                or (n.compound=="commonItems"and (row.key=="commonItemsSharing"or row.key=="commonItemsSharedRows"))
                or (n.compound=="playerSkillMonitor"and (row.key=="skillMonitorSharing"or row.key=="skillMonitorItems"))
                or (n.compound=="playerOtherMonitor"and (row.key=="otherMonitorSharing"or row.key=="otherMonitorItems"or row.key=="otherMonitorEquipment"))then
                e.propertyDividers[e.propertyDividerCount]:Hide()
            end
        end
        entry.layoutY=-height
        for i,control in ipairs(row.controls) do
            -- Inline controls still remain visible while skipping their own row.
            -- Hiding them on each value refresh cancels spin-box drag and focus.
            local show=entry.visible and not (n.compound and row.key=="flags" and i>1)
            control[1]:SetShown(show)
            if show and visible then PositionPropertyControl(control,e.props,-height) end
        end
        if visible then
            height=height+((n.compound and row.key=="flags") and 32 or row.height)
            previousSection=entry.section
        end
    end
    for _,pair in ipairs(fontPairs)do
        local font=pair.font;local controls=pair.sizeEntry.row.controls
        local caption,slider=controls[1][1],controls[2][1]
        local width=e.props:GetWidth();local half=(width-20)/2;local y=pair.fontEntry.layoutY
        font:SetWidth(half)
        caption:SetText("大小");M:SetLocaleLineHeight(caption,18)
        caption:ClearAllPoints();caption:SetPoint("TOPLEFT",font,"TOPRIGHT",20,0);caption:Show()
        slider:SetWidth(half);slider:ClearAllPoints()
        slider:SetPoint("CENTER",font,"BOTTOMRIGHT",20+half/2,12);slider:Show()
    end
    for _,pair in ipairs(offsetPairs)do
        local half=(e.props:GetWidth()-20)/2
        local left,right=pair[1],pair[2]
        if left[2]and right[2]then left[2][1]:SetWidth(half);right[2][1]:SetWidth(half)end
        if left[2]and right[2]then
            M:FitLocaleText(left[1][1],half,9)
            M:FitLocaleText(right[1][1],half,9)
        end
        for i=1,#right do
            local control=right[i][1]
            control:ClearAllPoints();control:SetPoint("TOPLEFT",left[i][1],"TOPLEFT",half+20,0);control:Show()
        end
    end
    e.props:SetHeight(math.max(2,height+10))
end

local function InPanel(object,panel)
    while object do
        if object==panel then return true end
        object=object.GetParent and object:GetParent()
    end
    return false
end
local function RestoreModuleSettings(e)
    for texture,desaturated in pairs(e.moduleLockedTextures or {})do texture:SetDesaturated(desaturated)end
    for input,enabled in pairs(e.moduleLockedInputs or {})do
        if enabled then input:Enable()else input:Disable()end
    end
    e.moduleLockedTextures=nil;e.moduleLockedInputs=nil
end
local function LockModuleSettings(e)
    local selected=Selected();local id=PreviewModuleID(selected)
    local module=id and M.byID[id];local locked=module and module.enabled==false or false
    e.right:SetAlpha(locked and .4 or 1)
    if not e.moduleLockShield then
        e.moduleLockShield=CreateFrame("Frame",nil,e.right)
        e.moduleLockShield:SetAllPoints();e.moduleLockShield:EnableMouse(true)
    end
    e.moduleLockShield:SetFrameLevel(e.right:GetFrameLevel()+10000)
    e.moduleLockShield:SetShown(locked)
    e.moduleEnabled:SetFrameLevel(e.moduleLockShield:GetFrameLevel()+1)
    e.moduleEnabled:SetIgnoreParentAlpha(true);e.moduleEnabled:SetAlpha(1)
    if not locked then return end
    e.moduleLockedInputs={};e.moduleLockedTextures={}
    -- End any active color edit owned by this panel before blocking its controls.
    local colorSource=M.EditorUndo and M.EditorUndo.colorSource
    if colorSource and InPanel(colorSource,e.right)and ColorPickerFrame then ColorPickerFrame:Hide()end
    for input in pairs(M.localizedInputs)do
        if InPanel(input,e.right)then
            e.moduleLockedInputs[input]=not input.IsEnabled or input:IsEnabled()
            input:ClearFocus();input:Disable()
        end
    end
    local function Desaturate(frame)
        if frame==e.moduleLockShield or frame==e.moduleEnabled then return end
        if frame.menu then frame.menu:Hide()end
        if frame.GetRegions then for _,region in ipairs({frame:GetRegions()})do
            if region.GetObjectType and region:GetObjectType()=="Texture"and region.IsDesaturated then
                e.moduleLockedTextures[region]=region:IsDesaturated();region:SetDesaturated(true)
            end
        end end
        if frame.GetChildren then for _,child in ipairs({frame:GetChildren()})do Desaturate(child)end end
    end
    Desaturate(e.right)
end
function M:RefreshProperties()
    local e=self.editor
    RestoreModuleSettings(e)
    RefreshProperties(self)
    LockModuleSettings(e)
end

