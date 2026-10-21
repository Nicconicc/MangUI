local _,M=...
local W=M.Widgets
local backdrop={bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true,tileSize=16,edgeSize=16,insets={left=3,right=3,top=5,bottom=3}}
local function Label(parent,text,template)
    local label=parent:CreateFontString(nil,"OVERLAY",template or "GameFontHighlight")
    M:BindText(label);label:SetText(text);return label
end
local function Button(parent,text,width,height,callback)
    local button=W.Button(parent,text,width,callback);button:SetHeight(height)
    button:SetHoverTextColor(1,.82,0);return button
end
local function Section(parent,text,y,height)
    local area=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    area:SetPoint("TOPLEFT",4,y-18);area:SetPoint("TOPRIGHT",-4,y-18);area:SetHeight(height)
    area:SetFrameLevel(math.max(0,parent:GetFrameLevel()-1));area:SetBackdrop(backdrop)
    area:SetBackdropColor(.12,.12,.13,.6);area:SetBackdropBorderColor(.34,.34,.36,.9)
    local title=Label(parent,text);title:SetTextColor(1,.82,0);title:SetPoint("BOTTOMLEFT",area,"TOPLEFT",3,2)
    return area
end
function M:RefreshOtherSettings()
    local panel=self.general
    if not panel then return end
    local selected=self:EffectiveLanguage()
    local caption=selected=="zhCN" and "中文 (zhCN)" or "English (enUS)"
    UIDropDownMenu_SetSelectedValue(panel.language,selected)
    UIDropDownMenu_SetText(panel.language,caption)
    local dropdownText=panel.language.Text or _G[panel.language:GetName().."Text"]
    if dropdownText then self:SetLocaleLineHeight(dropdownText,18);self:ApplyLocaleFont(dropdownText,caption,true) end
    panel.minimapCheck:SetChecked(not self.db.minimap.hide)
    panel.targetVisibilityCheck:SetChecked(self.db.hideWithoutTarget==true)
    panel.portrait3DCheck:SetChecked(self.db.portrait3D==true)
    panel.healthClassColorCheck:SetChecked(self.db.healthClassColor==true)
    panel.uiScaleCheck:SetChecked(self.db.adapt4KUIScale==true)
    panel.globalFontCheck:SetChecked(self.db.useGlobalFont==true)
    panel.globalFontSelect:SetMedia(self.db.globalFontName,self.db.globalFontPath)
    panel.exportButton:SetText("导出配置");panel.importButton:SetText("导入配置")
end
function M:OpenGlobalFontPicker()
    if not self:CanEdit() then return end
    local anchor=self.general.globalFontSelect
    if anchor.menu then anchor.menu:Hide();anchor.menu=nil;return end
    local items=self:BundledFontChoices()
    local menu=W.MediaMenu(anchor,items,"font",self:ResolveFontPath(self.db.globalFontPath),function(item)
        M:SetGlobalFont(nil,item.path,item.name)
    end,self.db.globalFontName)
    anchor.menu=menu
    menu:HookScript("OnHide",function()if anchor.menu==menu then anchor.menu=nil end end)
end
function M:OpenGeneral()
    M.EditorUndo.Clear()
    local editor=self.editor
    if not self.general then
        local panel=W.Panel(editor.window);self.general=panel;panel.controlPanelTextSize=12
        panel:SetPoint("TOPLEFT",14,-61);panel:SetPoint("BOTTOMRIGHT",-14,49)
        panel:SetFrameStrata("DIALOG");panel:SetFrameLevel(7000);panel:EnableMouse(true)
        local content=CreateFrame("Frame",nil,panel)
        content:SetPoint("TOPLEFT",35,-28);content:SetPoint("BOTTOMRIGHT",-35,20)
        content:SetFrameLevel(panel:GetFrameLevel()+2)
        Section(content,"系统",0,104)
        local row=CreateFrame("Frame",nil,content);row:SetSize(560,62);row:SetPoint("TOPLEFT",16,-30)
        local caption=Label(row,"语言版本");caption:SetTextColor(1,.82,0);caption:SetPoint("TOPLEFT",0,0)
        local dropdown=CreateFrame("Frame","MangUIUFLanguageDropdown",row,"UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT",-15,-24);dropdown:SetSize(390,32)
        UIDropDownMenu_SetWidth(dropdown,360);UIDropDownMenu_JustifyText(dropdown,"RIGHT")
        UIDropDownMenu_Initialize(dropdown,function()
            for _,option in ipairs(M.languageOptions) do
                local code=option.code
                local info=UIDropDownMenu_CreateInfo();info.text=option.label
                info.value=code;info.checked=M.db.language==code
                info.func=function()M:SetLanguage(code);CloseDropDownMenus()end
                UIDropDownMenu_AddButton(info)
            end
        end)
        panel.language=dropdown
        local check=CreateFrame("CheckButton",nil,content,"UICheckButtonTemplate")
        check:SetSize(28,28);check:SetPoint("TOPLEFT",12,-92)
        local text=Label(check,"显示小地图图标");text:SetPoint("LEFT",check,"RIGHT",5,0);text:SetTextColor(1,1,1)
        check:SetScript("OnClick",function(self)M.db.minimap.hide=not self:GetChecked();M:CreateMinimap()end)
        panel.minimapCheck=check
        Section(content,"显示",-145,252)
        local visibility=CreateFrame("CheckButton",nil,content,"UICheckButtonTemplate")
        visibility:SetSize(28,28);visibility:SetPoint("TOPLEFT",12,-175)
        local visibilityText=Label(visibility,"无目标时隐藏框体")
        visibilityText:SetPoint("LEFT",visibility,"RIGHT",5,0);visibilityText:SetTextColor(1,1,1)
        visibility:SetScript("OnClick",function(self)
            M:SetHideWithoutTarget(self:GetChecked());M:RefreshOtherSettings()
        end)
        panel.targetVisibilityCheck=visibility
        local portrait=CreateFrame("CheckButton",nil,content,"UICheckButtonTemplate")
        portrait:SetSize(28,28);portrait:SetPoint("TOPLEFT",12,-209)
        local portraitText=Label(portrait,"3D头像")
        portraitText:SetPoint("LEFT",portrait,"RIGHT",5,0);portraitText:SetTextColor(1,1,1)
        portrait:SetScript("OnClick",function(self)
            M:SetPortrait3D(self:GetChecked());M:RefreshOtherSettings()
        end)
        panel.portrait3DCheck=portrait
        local healthColor=CreateFrame("CheckButton",nil,content,"UICheckButtonTemplate")
        healthColor:SetSize(28,28);healthColor:SetPoint("TOPLEFT",12,-243)
        local healthColorText=Label(healthColor,"按职业显示生命条颜色")
        healthColorText:SetPoint("LEFT",healthColor,"RIGHT",5,0);healthColorText:SetTextColor(1,1,1)
        healthColor:SetScript("OnClick",function(self)
            M:SetHealthClassColor(self:GetChecked());M:RefreshOtherSettings()
        end)
        panel.healthClassColorCheck=healthColor
        local uiScale=CreateFrame("CheckButton",nil,content,"UICheckButtonTemplate")
        uiScale:SetSize(28,28);uiScale:SetPoint("TOPLEFT",12,-277)
        local uiScaleText=Label(uiScale,"适配4K分辨率的UI缩放")
        uiScaleText:SetPoint("LEFT",uiScale,"RIGHT",5,0);uiScaleText:SetTextColor(1,1,1)
        uiScale:SetScript("OnClick",function(self)
            M:SetAdapt4KUIScale(self:GetChecked());M:RefreshOtherSettings()
        end)
        panel.uiScaleCheck=uiScale
        local globalFont=CreateFrame("CheckButton",nil,content,"UICheckButtonTemplate")
        globalFont:SetSize(28,28);globalFont:SetPoint("TOPLEFT",12,-311)
        local globalFontText=Label(globalFont,"使用全局字体")
        globalFontText:SetPoint("LEFT",globalFont,"RIGHT",5,0);globalFontText:SetTextColor(1,1,1)
        globalFont:SetScript("OnClick",function(self)
            M:SetGlobalFont(self:GetChecked());M:RefreshOtherSettings()
        end)
        panel.globalFontCheck=globalFont
        panel.globalFontSelect=W.MediaSelect(content,"字体",200,"font",function()M:OpenGlobalFontPicker()end)
        panel.globalFontSelect:SetPoint("TOPLEFT",16,-345)
        panel.globalFontSelect.caption:SetTextColor(1,1,1)
        Section(content,"配置分享",-432,59)
        local export=Button(content,"导出配置",190,32,function()M:ShowConfigStringDialog("export")end)
        panel.exportButton=export
        export:SetPoint("TOPLEFT",16,-462)
        local import=Button(content,"导入配置",190,32,function()M:ShowConfigStringDialog("import")end)
        panel.importButton=import
        import:SetPoint("TOPLEFT",216,-462)
        panel:SetScript("OnHide",function()
            if panel.globalFontSelect.menu then panel.globalFontSelect.menu:Hide()end
            if M.configDialog then M.configDialog:Hide() end
            editor.designTab:SetActive(true);editor.generalTab:SetActive(false)
            editor.canvas:Show();editor.left:Show();editor.right:Show();editor.status:Show()
            M:RefreshEditor()
        end)
    end
    if editor.overlap then editor.overlap:Hide() end
    for _,key in ipairs({"mediaWindow","materialWindow","fontWindow"}) do if self[key] then self[key]:Hide() end end
    editor.designTab:SetActive(false);editor.generalTab:SetActive(true)
    editor.canvas:Hide();editor.left:Hide();editor.right:Hide();editor.status:Show()
    self.general:Show();self:RefreshOtherSettings()
end
local function WrapString(value,edit,measure)
    local rows={};local width=math.max(100,edit:GetWidth()-16)
    local font,size,flags=measure:GetFont()
    local signature=tostring(font)..":"..tostring(size)..":"..tostring(flags)
    if measure.exportFontSignature~=signature then
        measure.exportFontSignature=signature;measure.exportGlyphs={};measure.exportGlyphWidth=0
    end
    -- An encoded configuration has a small ASCII alphabet. Measure each glyph
    -- once, rather than forcing native text layout repeatedly for every line.
    for char in value:gmatch(".") do
        if not measure.exportGlyphs[char] then
            measure:SetText(char)
            measure.exportGlyphWidth=math.max(measure.exportGlyphWidth,measure:GetStringWidth())
            measure.exportGlyphs[char]=true
        end
    end
    local count=math.max(1,math.min(150,math.floor(width/math.max(1,measure.exportGlyphWidth+1))))
    for first=1,#value,count do
        rows[#rows+1]=value:sub(first,first+count-1)
    end
    return table.concat(rows,"\n")
end
function M:ShowConfigStringDialog(mode,scope)
    local dialog=self.configDialog
    if not dialog then
        dialog=CreateFrame("Frame","MangUIUFConfigStringDialog",self.editor.window,"BackdropTemplate");self.configDialog=dialog;dialog.controlPanelTextSize=12
        dialog:SetSize(720,430);dialog:SetPoint("CENTER",self.editor.window,"CENTER");dialog:SetFrameStrata("FULLSCREEN_DIALOG")
        dialog:SetAlpha(1)
        dialog:SetBackdrop(backdrop);dialog:SetBackdropColor(.08,.08,.09,1);dialog:SetBackdropBorderColor(.34,.34,.36,1)
        dialog:EnableMouse(true)
        dialog.title=Label(dialog,"","GameFontNormalLarge");dialog.title:SetPoint("TOP",0,-18)
        dialog.hint=Label(dialog,"");dialog.hint:SetPoint("TOP",0,-48);dialog.hint:SetWidth(670);dialog.hint:SetJustifyH("CENTER")
        local scroll=CreateFrame("ScrollFrame",nil,dialog,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",28,-78);scroll:SetPoint("BOTTOMRIGHT",-44,70)
        local edit=CreateFrame("EditBox",nil,scroll,"BackdropTemplate")
        edit:SetPoint("TOPLEFT",4,-4);edit:SetSize(620,560);edit:SetMultiLine(true);edit:SetAutoFocus(false)
        edit:SetMaxLetters(400000);edit:SetFontObject(GameFontHighlightSmall);edit:SetTextInsets(6,6,6,6)
        edit:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
            tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
        edit:SetBackdropColor(.03,.03,.04,1);edit:SetBackdropBorderColor(.34,.34,.36,1)
        scroll:SetScrollChild(edit);dialog.edit=edit;dialog.scroll=scroll
        scroll:SetScript("OnSizeChanged",function(self,width)edit:SetWidth(math.max(100,width-20))end)
        edit:SetScript("OnEscapePressed",function()dialog:Hide()end)
        edit:SetScript("OnTextChanged",function(self)
            local rows=0;local charsPerLine=math.max(1,math.floor((self:GetWidth()-12)/7))
            for line in (self:GetText().."\n"):gmatch("(.-)\n") do rows=rows+math.max(1,math.ceil(#line/charsPerLine)) end
            self:SetHeight(math.max(560,rows*16+12));scroll:UpdateScrollChildRect()
            if dialog.status then dialog.status:SetText("") end
        end)
        dialog.measure=dialog:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");dialog.measure:Hide()
        dialog.status=Label(dialog,"");dialog.status:SetPoint("TOP",scroll,"BOTTOM",0,-4)
        dialog.status:SetWidth(670);dialog.status:SetJustifyH("CENTER");dialog.status:SetTextColor(1,.3,.3)
        dialog.action=Button(dialog,"",120,26,function()
            if dialog.mode=="export" then edit:SetFocus();edit:HighlightText();return end
            local ok,errorText
            local monitor=M.MonitorSharing.Scope(dialog.scope)
            if monitor then ok,errorText=M:ApplyMonitorString(edit:GetText(),monitor)
            elseif dialog.scope and dialog.scope:sub(1,8)=="received"then ok,errorText=M:ApplyReceivedBuffsString(edit:GetText())
            elseif dialog.scope and dialog.scope:sub(1,5)=="other"then ok,errorText=M:ApplyPlayerOtherMonitorString(edit:GetText())
            elseif dialog.scope then ok,errorText=M:ApplyPlayerSkillMonitorString(edit:GetText())
            else ok,errorText=M:ApplyConfigString(edit:GetText())end
            if not ok then dialog.status:SetText(errorText);return end
            dialog:Hide();M:Print("配置导入成功。")
        end)
        dialog.action:SetPoint("BOTTOM",-70,14)
        dialog.cancel=Button(dialog,"取消",120,26,function()dialog:Hide()end);dialog.cancel:SetPoint("BOTTOM",70,14)
        local close=CreateFrame("Button",nil,dialog,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",2,2);W.StyleButton(close)
        close:SetScript("OnClick",function()dialog:Hide()end)
        dialog:SetScript("OnHide",function()edit:ClearFocus()end)
    end
    local monitor,all=M.MonitorSharing.Scope(scope)
    dialog.mode,dialog.scope=mode,scope;dialog.status:SetText("");dialog:Show()
    if mode=="export" then
        dialog.title:SetText(monitor=="raidBuffs"and "导出配置"or ((monitor and all)or scope=="skillsAll"or scope=="otherAll")and "导出全职业配置"or ((monitor and not all)or scope=="skillsClass"or scope=="otherClass")and "导出当前职业配置"or "导出配置")
        dialog.hint:SetText("按 Ctrl+C 复制下方字符串，分享给其他用户。")
        dialog.action:SetText("全选")
        local value
        if monitor then value=self:ExportMonitorString(monitor,all)
        elseif scope and scope:sub(1,8)=="received"then value=self:ExportReceivedBuffsString()
        elseif scope and scope:sub(1,5)=="other"then value=self:ExportPlayerOtherMonitorString(scope=="otherAll")
        elseif scope then value=self:ExportPlayerSkillMonitorString(scope=="skillsAll")else value=self:ExportConfigString()end
        dialog.edit:SetText(value and WrapString(value,dialog.edit,dialog.measure) or "")
        if not value then dialog.status:SetText("当前配置无法导出，请检查配置数据。") end
    else
        dialog.title:SetText("导入配置")
        dialog.hint:SetText(scope and (scope:sub(1,5)=="other"and "粘贴其他监控配置字符串；单职业仅更新该职业，全职业包含共用装备监控与补充。"or "粘贴技能监控配置字符串；仅更新字符串包含的职业配置。")or "粘贴配置字符串；技能监控配置仅更新对应职业，整体配置更新全部设置。")
        if scope and scope:sub(1,8)=="received"then dialog.hint:SetText("粘贴队友Buff监控配置字符串；所有职业共用。")end
        if monitor then dialog.hint:SetText("粘贴此模块配置字符串；单职业仅更新对应职业，全职业包含通用设置。")end
        dialog.action:SetText("确认导入");dialog.edit:SetText("")
    end
    dialog.scroll:SetVerticalScroll(0);dialog.edit:SetFocus();dialog.edit:HighlightText()
end
