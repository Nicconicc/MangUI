local _,M=...
local W={};M.Widgets=W
local backdrop={bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}}
function W.Panel(parent)
    local f=CreateFrame("Frame",nil,parent,"BackdropTemplate");f:SetBackdrop(backdrop)
    f:SetBackdropColor(.12,.12,.13,.94);f:SetBackdropBorderColor(.34,.34,.36,.9)
    return f
end
function W.RoundedMoveArea(frame)
    -- Slice the two textures so the corner radius stays fixed for any module size.
    local radius=10
    local uv={0,10/32,22/32,1}
    local columns={{"LEFT",0,"LEFT",radius},{"LEFT",radius,"RIGHT",-radius},{"RIGHT",-radius,"RIGHT",0}}
    local rows={{"TOP",0,"TOP",-radius},{"TOP",-radius,"BOTTOM",radius},{"BOTTOM",radius,"BOTTOM",0}}
    frame.moveAreaTextures={}
    for _,skin in ipairs({{"MoveAreaFill.tga","BACKGROUND",{.08,.8,.25,.27}},
        {"MoveAreaBorder.tga","ARTWORK",{.25,1,.35,.95}}})do
        for y,row in ipairs(rows)do for x,column in ipairs(columns)do
            local texture=frame:CreateTexture(nil,skin[2])
            texture:SetTexture("Interface\\AddOns\\MangUI\\Assets\\UI\\"..skin[1])
            texture:SetTexCoord(uv[x],uv[x+1],uv[y],uv[y+1])
            texture:SetPoint("TOPLEFT",frame,row[1]..column[1],column[2],row[2])
            texture:SetPoint("BOTTOMRIGHT",frame,row[3]..column[3],column[4],row[4])
            texture:SetVertexColor(unpack(skin[3]))
            frame.moveAreaTextures[#frame.moveAreaTextures+1]=texture
        end end
    end
end
function W.Label(parent,text,size,nativeSize)
    local t=parent:CreateFontString(nil,"OVERLAY");t:SetFont(M:DefaultFontPath(),size or 12,"")
    if not nativeSize then t.clientInterfaceNominalSize=size or 12 end
    M:BindText(t);t:SetText(text or "");t:SetTextColor(1,1,1);t:SetJustifyH("LEFT");return t
end
function W.DragListHeader(panel,line)
    local label=W.Label(panel,"拖拽排序",12);panel.dragHint=label
    label:SetPoint("RIGHT",panel,"TOPRIGHT",0,12);label:SetTextColor(.65,.65,.65)
    label:SetJustifyH("RIGHT");label:SetWordWrap(false);M:SetLocaleLineHeight(label,18)
    line=line or panel.sectionRightLine
    if line then line:SetPoint("RIGHT",label,"LEFT",-8,0)end
end
function W.ShadeDragRow(row,index)
    if not row.alternateBackground then
        local fill=row:CreateTexture(nil,"BACKGROUND",nil,-8);row.alternateBackground=fill
        fill:SetAllPoints();fill:SetColorTexture(0,0,0,.22)
    end
    row.alternateBackground:SetShown(index%2==0)
end
function W.StyleButton(b)
    if b.panelButtonStyled then return b end
    b.panelButtonStyled=true;b.panelButtonHoverColor={1,1,1}
    local function CenterText(self)
        local text=self:GetFontString();if not text then return end
        text:ClearAllPoints();text:SetPoint("CENTER",self,"CENTER",self.panelButtonTextX or 0,self.panelButtonTextY or 0)
        text:SetSize(math.max(1,self:GetWidth()-10),self:GetHeight())
        text:SetJustifyH("CENTER");text:SetJustifyV("MIDDLE");text:SetWordWrap(false)
    end
    local function Paint(self)
        local hover=self.panelButtonHover and self:IsEnabled()
        local function TintRegions(frame)
            for _,region in ipairs({frame:GetRegions()}) do
                if region:GetObjectType()=="Texture" then region:SetDesaturated(not (hover or self.panelButtonFullColor)) end
            end
        end
        TintRegions(self)
        if self.NineSlice then TintRegions(self.NineSlice) end
        local text=self:GetFontString()
        if text then
            local color=hover and self.panelButtonHoverColor or self.panelButtonNormalTextColor or {1,1,1}
            text:SetTextColor(color[1],color[2],color[3],1)
            CenterText(self)
            local rendered=self.localeRenderedText or self:GetText()
            M:ApplyLocaleFont(self,rendered)
            if self.localeRenderedText then text:SetText(rendered)end
        end
    end
    function b:SetHoverTextColor(r,g,blue)
        self.panelButtonHoverColor={r,g,blue};Paint(self)
    end
    function b:SetFullColorStyle(r,g,blue)
        self.panelButtonFullColor=true
        self.panelButtonNormalTextColor={r,g,blue}
        self.panelButtonHoverColor={r,g,blue};Paint(self)
    end
    function b:SetTextCenterOffset(x,y)
        self.panelButtonTextX=x;self.panelButtonTextY=y;CenterText(self)
    end
    if b:GetFontString() then
        b:SetNormalFontObject(GameFontHighlight);b:SetHighlightFontObject(GameFontHighlight)
        b:SetPushedTextOffset(0,0)
    end
    b:HookScript("OnEnter",function(self)self.panelButtonHover=true;Paint(self)end)
    b:HookScript("OnLeave",function(self)self.panelButtonHover=false;Paint(self)end)
    b:HookScript("OnShow",function(self)self.panelButtonHover=self:IsMouseOver();Paint(self)end)
    b:HookScript("OnHide",function(self)self.panelButtonHover=false;Paint(self)end)
    b:HookScript("OnEnable",Paint);b:HookScript("OnDisable",Paint)
    b:HookScript("OnMouseDown",Paint);b:HookScript("OnMouseUp",Paint)
    b:HookScript("OnSizeChanged",CenterText)
    Paint(b);return b
end
function W.Button(parent,text,width,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");b:SetSize(width or 78,24);M:BindText(b);b:SetText(text)
    W.StyleButton(b)
    b:SetScript("OnClick",fn);return b
end
-- Shared-media selectors use the same client textures and previews as WA's LSM widgets.
function W.MediaSelect(parent,label,width,kind,fn)
    local f=CreateFrame("Frame",nil,parent);f:SetSize(width or 215,44)
    local caption=W.Label(f,label,12);caption:SetPoint("TOPLEFT",0,0);M:SetLocaleLineHeight(caption,18);f.caption=caption
    local skin="Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame"
    local left=f:CreateTexture(nil,"ARTWORK");left:SetSize(25,64)
    left:SetPoint("BOTTOMLEFT",-17,-21);left:SetTexture(skin);left:SetTexCoord(0,.1953125,0,1)
    local right=f:CreateTexture(nil,"ARTWORK");right:SetSize(25,64)
    right:SetPoint("TOP",left,"TOP");right:SetPoint("RIGHT",f,"RIGHT",17,0)
    right:SetTexture(skin);right:SetTexCoord(.8046875,1,0,1)
    local middle=f:CreateTexture(nil,"ARTWORK");middle:SetHeight(64)
    middle:SetPoint("TOP",left,"TOP");middle:SetPoint("LEFT",left,"RIGHT");middle:SetPoint("RIGHT",right,"LEFT")
    middle:SetTexture(skin);middle:SetTexCoord(.1953125,.8046875,0,1)
    local preview=f:CreateTexture(nil,"ARTWORK",nil,1)
    preview:SetPoint("TOPLEFT",6,-25);preview:SetPoint("BOTTOMRIGHT",-21,5);preview:SetAlpha(.5)
    local text=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    M:BindText(text)
    text:SetPoint("RIGHT",right,"RIGHT",-43,1);text:SetPoint("LEFT",left,"LEFT",26,1)
    text:SetJustifyH("RIGHT");M:SetLocaleLineHeight(text,18);text:SetWordWrap(false)
    f.valueText=text
    local defaultFont,defaultSize,defaultFlags=text:GetFont()
    local click=CreateFrame("Button",nil,f);click:SetPoint("BOTTOMLEFT");click:SetPoint("BOTTOMRIGHT");click:SetHeight(24)
    click:SetScript("OnClick",fn)
    local arrow=CreateFrame("Button",nil,f);arrow:SetSize(24,24)
    arrow:SetPoint("TOPRIGHT",right,"TOPRIGHT",-16,-18);arrow:SetFrameLevel(click:GetFrameLevel()+1)
    arrow:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    arrow:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
    arrow:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
    arrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    arrow:SetScript("OnClick",fn)
    function f:SetMedia(value,path)
        if kind=="statusbar" and value=="原始材质" then value="默认" end
        local language=M:EffectiveLanguage()
        if self.mediaCached and self.mediaValue==value and self.mediaPath==path and self.mediaLanguage==language then return end
        self.mediaCached=true;self.mediaValue=value;self.mediaPath=path;self.mediaLanguage=language
        text.localePreviewFont=kind=="font"and path or nil
        text.localePreviewSize=defaultSize;text.localePreviewFlags=defaultFlags
        text:SetFont(M:ResolveFontPath(defaultFont),defaultSize,defaultFlags)
        text:SetText(value or "")
        preview:SetTexture(kind=="statusbar" and path or nil)
    end
    f:SetScript("OnHide",function(self)if self.menu then self.menu:Hide() end end)
    return f
end
function W.MediaMenu(anchor,items,kind,selectedPath,onSelect,selectedName)
    local p=CreateFrame("Frame",nil,M.editor.window,"BackdropTemplate")
    p.controlPanelTextSize=M:ControlPanelFontSize(anchor)
    p.localeTransient=true
    p:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,
        insets={left=11,right=12,top=12,bottom=9}})
    p:SetFrameStrata("TOOLTIP");p:SetFrameLevel(9100);p:SetClampedToScreen(true);p:EnableMouse(true)
    local rowHeight=24
    local height=math.min(#items*rowHeight+25,390,UIParent:GetHeight()*2/5)
    local scrolling=#items*rowHeight>height-25
    local width=math.max(188,anchor:GetWidth());local contentWidth=width-(scrolling and 42 or 28)
    p:SetSize(width,height);p:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,0)
    -- Share the menu's parent so window-stack level changes move both together.
    -- A UIParent dismiss button with a fixed level can end up above the rows.
    local dismiss=CreateFrame("Button",nil,p:GetParent());dismiss:SetAllPoints(UIParent)
    dismiss:SetFrameStrata("TOOLTIP");dismiss:SetFrameLevel(p:GetFrameLevel()-1);dismiss:RegisterForClicks("LeftButtonUp","RightButtonUp")
    dismiss:SetScript("OnClick",function()p:Hide()end)
    local scroll=CreateFrame("ScrollFrame",nil,p)
    scroll:SetPoint("TOPLEFT",14,-13);scroll:SetPoint("BOTTOMRIGHT",scrolling and -28 or -14,12)
    local body=CreateFrame("Frame",nil,scroll);body:SetSize(contentWidth,math.max(1,#items*rowHeight));scroll:SetScrollChild(body)
    body:SetPoint("TOPLEFT",scroll,"TOPLEFT",0,0)
    local slider=CreateFrame("Slider",nil,p,"BackdropTemplate")
    slider:SetOrientation("VERTICAL");slider:SetWidth(12)
    slider:SetPoint("TOPRIGHT",-14,-10);slider:SetPoint("BOTTOMRIGHT",-14,10)
    slider:SetBackdrop({bgFile="Interface\\Buttons\\UI-SliderBar-Background",edgeFile="Interface\\Buttons\\UI-SliderBar-Border",
        tile=true,tileSize=8,edgeSize=8,insets={left=3,right=3,top=3,bottom=3}})
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")
    slider:SetMinMaxValues(0,math.max(0,#items*rowHeight-(height-25)));slider:SetValue(0);slider:SetShown(scrolling)
    slider:SetScript("OnValueChanged",function(_,value)scroll:SetVerticalScroll(value)end)
    p:EnableMouseWheel(true)
    p:SetScript("OnMouseWheel",function(_,delta)
        local lo,hi=slider:GetMinMaxValues();slider:SetValue(M.Clamp(slider:GetValue()-delta*rowHeight*2,lo,hi))
    end)
    local selectedIndex
    local function SameMedia(path)
        if kind=="font" then path=M:ResolveFontPath(path);return M:SameTexture(path,M:ResolveFontPath(selectedPath)) end
        return M:SameTexture(path,selectedPath)
    end
    -- Several names may resolve to one bundled face. Select one row by name,
    -- falling back to the first matching path for older saved configurations.
    for i,item in ipairs(items) do
        if SameMedia(item.path or item.preview) then
            if not selectedIndex then selectedIndex=i end
            if item.name==selectedName then selectedIndex=i;break end
        end
    end
    for i,item in ipairs(items) do
        local row=CreateFrame("Button",nil,body);row:SetSize(contentWidth,rowHeight);row:SetPoint("TOPLEFT",0,-(i-1)*rowHeight)
        row:EnableMouse(true);row:RegisterForClicks("LeftButtonUp")
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
        local check=row:CreateTexture(nil,"OVERLAY");check:SetSize(16,16);check:SetPoint("LEFT",1,-1)
        check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check");check:SetShown(i==selectedIndex)
        local path=item.path or item.preview
        if kind=="statusbar" then
            local bar=row:CreateTexture(nil,"ARTWORK");bar:SetHeight(16)
            bar:SetPoint("LEFT",check,"RIGHT",1,0);bar:SetPoint("RIGHT",-1,0);bar:SetTexture(path)
        end
        local text=row:CreateFontString(nil,"OVERLAY","GameFontWhite")
        M:BindText(text)
        text:SetPoint("LEFT",check,"RIGHT",kind=="statusbar"and 3 or 1,0)
        text:SetPoint("RIGHT",row,"RIGHT",-2,0);M:SetLocaleLineHeight(text,rowHeight)
        text:SetJustifyH("LEFT");text:SetJustifyV("MIDDLE");text:SetWordWrap(false)
        local font,size=text:GetFont()
        if kind=="font"and path then
            text.localePreviewFont=path;text.localePreviewSize=size;text.localePreviewFlags=""
        else text:SetFont(M:ResolveFontPath(font),size,"OUTLINE")end
        text:SetText(item.name)
        row:SetScript("OnClick",function()p:Hide();onSelect(item)end)
    end
    anchor.menu=p
    p:EnableKeyboard(true);p:SetPropagateKeyboardInput(true)
    p:SetScript("OnKeyDown",function(self,key)
        self:SetPropagateKeyboardInput(key~="ESCAPE")
        if key=="ESCAPE" then self:Hide() end
    end)
    p:SetScript("OnHide",function()
        M:ReleaseLocaleScope(p)
        dismiss:Hide();p:EnableKeyboard(false);if anchor.menu==p then anchor.menu=nil end
    end)
    return p
end
function W.Tab(parent,text,fn)
    local b=CreateFrame("Button",nil,parent);b:SetSize(102,27)
    local left=b:CreateTexture(nil,"BACKGROUND");left:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab");left:SetTexCoord(0,.15625,0,1);left:SetSize(20,27);left:SetPoint("LEFT")
    local right=b:CreateTexture(nil,"BACKGROUND");right:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab");right:SetTexCoord(.84375,1,0,1);right:SetSize(20,27);right:SetPoint("RIGHT")
    local middle=b:CreateTexture(nil,"BACKGROUND");middle:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab");middle:SetTexCoord(.15625,.84375,0,1);middle:SetPoint("TOPLEFT",left,"TOPRIGHT");middle:SetPoint("BOTTOMRIGHT",right,"BOTTOMLEFT")
    b:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight","ADD")
    local highlight=b:GetHighlightTexture();highlight:ClearAllPoints()
    highlight:SetHeight(b:GetHeight())
    highlight:SetPoint("LEFT",b,"LEFT",10,-4);highlight:SetPoint("RIGHT",b,"RIGHT",-10,-4)
    local _,labelSize=GameFontNormal:GetFont()
    b.label=W.Label(b,text,labelSize,true);b.label:SetPoint("CENTER",0,-2);b:SetScript("OnClick",fn)
    function b:SetActive(active)self.label:SetTextColor(1,active and 1 or .82,active and 1 or 0)end
    b:SetActive(false)
    return b
end
function W.SpellInputDisplay(value)
    value=tostring(value or "")
    local id=tonumber(value)
    if id and id>0 and id%1==0 then
        local name=M.PetBuffs.SpellInfo(value)
        if type(name)=="string"and name~=""then return name end
    end
    return value
end
function W.InputValue(edit)
    local text=edit:GetText()
    if edit.inputNameKind=="spell"and text==edit.inputDisplayText then return edit.inputRawValue end
    return text
end
function W.SetInputValue(edit,value)
    value=tostring(value or "")
    local display=edit.inputNameKind=="spell"and W.SpellInputDisplay(value)or value
    -- Keep exact IDs in saved data and matching rules, even for same-name ranks.
    edit.inputRawValue,edit.inputDisplayText=value,display
    if edit:GetText()~=display then edit:SetText(display)end
end
function W.NamedInput(edit,kind)
    edit.inputNameKind=kind
    if edit.namedInputHooked then return end
    edit.namedInputHooked=true
    edit:HookScript("OnTextChanged",function(self,userInput)
        if userInput then self.inputRawValue,self.inputDisplayText=nil,nil end
    end)
    edit:HookScript("OnEditFocusLost",function(self)
        if self.inputNameKind then W.SetInputValue(self,W.InputValue(self))end
    end)
end
function W.Edit(parent,width)
    local e=CreateFrame("EditBox",nil,parent,"InputBoxTemplate");e:SetSize(width or 120,22);e:SetAutoFocus(false)
    M:BindInputFont(e)
    e:SetScript("OnEscapePressed",function(self)self:ClearFocus()end);return e
end
-- Appearance and drag interaction follow WeakAurasSpinBox. Textures are bundled
-- locally so these controls work without WeakAuras being installed or enabled.
function W.SpinBox(parent,width,minimum,maximum,step)
    local f=CreateFrame("Slider",nil,parent)
    local enabled=true
    f:SetSize(width or 200,19);f:SetOrientation("HORIZONTAL");f:EnableMouse(false)
    f:SetMinMaxValues(minimum or 0,maximum or 100);f:SetValueStep(step or 1)
    local skin="Interface\\AddOns\\MangUI\\Assets\\WAControls\\spinbox"
    local left=CreateFrame("Button",nil,f);left:SetSize(16,16);left:SetPoint("LEFT",2,0)
    local right=CreateFrame("Button",nil,f);right:SetSize(16,16);right:SetPoint("RIGHT",-2,0)
    for _,entry in ipairs({{left,"left"},{right,"right"}}) do
        entry[1]:SetNormalTexture(skin..entry[2]);entry[1]:SetHighlightTexture(skin..entry[2].."h")
        entry[1]:SetPushedTexture(skin..entry[2].."p");entry[1]:SetDisabledTexture(skin..entry[2].."p")
    end
    local edit=CreateFrame("EditBox",nil,f,"InputBoxTemplate")
    edit:SetAutoFocus(false);edit:SetFontObject(ChatFontNormal);edit:SetTextColor(1,1,1);edit:SetHeight(19)
    M:BindInputFont(edit)
    edit:SetJustifyH("CENTER");edit:SetTextInsets(0,0,3,3);edit:EnableMouse(true);edit:EnableMouseWheel(false)
    edit:SetPoint("LEFT",left,"RIGHT",8,0);edit:SetPoint("RIGHT",right,"LEFT",-2,0)
    local progress=edit:CreateTexture(nil,"ARTWORK")
    progress:SetTexture(skin.."overlay");progress:SetVertexColor(.5,.5,.5,1)
    progress:SetPoint("TOPLEFT",edit,"TOPLEFT",-2,-3);progress:SetPoint("BOTTOMLEFT",edit,"BOTTOMLEFT",-2,3)
    local handle=CreateFrame("Frame",nil,edit);handle:EnableMouse(true)
    handle:SetSize(28,28);handle:SetPoint("CENTER",progress,"RIGHT",0,0)
    local highlight=handle:CreateTexture(nil,"ARTWORK")
    highlight:SetAllPoints();highlight:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    handle:Hide()
    local function Update()
        local value=f:GetValue() or 0;local lo,hi=f:GetMinMaxValues()
        if not edit:HasFocus() then
            local number=math.floor(value*100+.5)/100
            edit:SetText(f.isPercent and tostring(math.floor(value*1000+.5)/10).."%" or tostring(number))
        end
        left:SetEnabled(enabled and value>lo);right:SetEnabled(enabled and value<hi)
        local p=hi>lo and M.Clamp((value-lo)/(hi-lo),0,1) or 0
        progress:SetWidth(math.max(1,p*math.max(1,f:GetWidth()-47)));progress:SetTexCoord(0,p,0,1)
    end
    local function Apply(value)
        if not enabled then Update();return end
        local lo,hi=f:GetMinMaxValues();local increment=f:GetValueStep()
        if increment and increment>0 then
            local units=value/increment
            value=(units>=0 and math.floor(units+.5) or math.ceil(units-.5))*increment
        end
        f:SetValue(M.Clamp(value,lo,hi));Update()
    end
    left:SetScript("OnClick",function()edit:ClearFocus();Apply(f:GetValue()-f:GetValueStep())end)
    right:SetScript("OnClick",function()edit:ClearFocus();Apply(f:GetValue()+f:GetValueStep())end)
    edit:SetScript("OnEnterPressed",function(self)
        local text=self:GetText();local value=tonumber((text:gsub("%%","")))
        self:ClearFocus();if value then Apply(f.isPercent and value/100 or value) else Update() end
    end)
    edit:SetScript("OnEscapePressed",function(self)self:ClearFocus();Update()end)
    edit:SetScript("OnEditFocusLost",Update)
    edit:SetScript("OnEnter",function()if enabled and not edit:HasFocus() then handle:Show() end end)
    edit:SetScript("OnEditFocusGained",function()handle:Hide()end)
    handle:SetScript("OnMouseDown",function(self,button)
        if not enabled or button~="LeftButton" then return end
        M.EditorUndo.Begin(self)
        edit:ClearFocus();self.dragging=true;self.startX=GetCursorPosition();self.original=f:GetValue()
    end)
    handle:SetScript("OnMouseUp",function(self,button)
        if button=="LeftButton" and self.dragging then self.dragging=false;M.EditorUndo.Finish(self) end
    end)
    handle:SetScript("OnUpdate",function(self)
        if not enabled then self.dragging=false;M.EditorUndo.Finish(self);self:Hide();return end
        if self.dragging and not IsMouseButtonDown("LeftButton") then self.dragging=false;M.EditorUndo.Finish(self) end
        if self.dragging then
            local x=GetCursorPosition();local lo,hi=f:GetMinMaxValues();local increment=f:GetValueStep()
            local delta=(x-self.startX)/edit:GetEffectiveScale()/math.max(1,f:GetWidth()-47)*(hi-lo)
            Apply(math.floor((self.original+delta)/increment+.5)*increment)
        elseif edit:HasFocus() or not M.Compat.MouseOver(f) then self:Hide() end
        if self.dragging then highlight:SetVertexColor(1,.82,.4,1)
        elseif M.Compat.MouseOver(self) then highlight:SetVertexColor(1,1,.75,1)
        else highlight:SetVertexColor(1,1,1,1) end
    end)
    -- Refresh directly on programmatic changes, including while hidden. The
    -- caller installs its own OnValueChanged handler after constructing this control.
    local nativeSetValue,nativeSetMinMaxValues=f.SetValue,f.SetMinMaxValues
    function f:SetValue(value)nativeSetValue(self,value);Update()end
    function f:SetMinMaxValues(lo,hi)nativeSetMinMaxValues(self,lo,hi);Update()end
    f:HookScript("OnShow",Update);f:HookScript("OnSizeChanged",Update)
    f:HookScript("OnHide",function()handle.dragging=false;M.EditorUndo.Finish(handle);handle:Hide();edit:ClearFocus()end)
    function f:HasFocus()return edit:HasFocus()end
    function f:ClearFocus()edit:ClearFocus()end
    function f:IsEnabled()return enabled end
    function f:SetEnabled(value)
        enabled=value~=false
        if enabled then edit:Enable()
        else edit:ClearFocus();edit:Disable();handle.dragging=false;M.EditorUndo.Finish(handle);handle:Hide() end
        edit:EnableMouse(enabled);handle:EnableMouse(enabled)
        self:SetAlpha(enabled and 1 or .45);Update()
    end
    function f:SetText(value)
        local number=tonumber(value) or 0
        local updating=self.updating;self.updating=true;self:SetValue(number);self.updating=updating
        Update()
    end
    function f:SetIsPercent(value)self.isPercent=value;Update()end
    f.editbox=edit;f.leftbutton=left;f.rightbutton=right
    f:SetValue(minimum or 0);Update()
    return f
end
function W.Check(parent,text,fn)
    local b=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate");b:SetSize(24,24)
    local label=W.Label(b,text);label:SetPoint("LEFT",b,"RIGHT",0,0);label:SetTextColor(.9,.9,.9);b.label=label
    b:SetScript("OnClick",function(self)fn(self:GetChecked())end);return b
end
function W.Drop(parent,width,choices,fn)
    local b=W.Button(parent,"",width,function(self)
        if self.menu then self.menu:Hide();self.menu=nil;return end
        local menu=W.Panel(self);menu.localeTransient=true;menu:SetFrameStrata("TOOLTIP");menu:SetFrameLevel(9000);menu:SetSize(width+15,#choices*23+12)
        menu:SetScript("OnHide",function()M:ReleaseLocaleScope(menu)end)
        menu:SetPoint("TOPLEFT",self,"BOTTOMLEFT",0,-1);self.menu=menu
        for i,c in ipairs(choices) do
            local row=W.Button(menu,c[2],width-1,function() self.value=c[1];self:SetText(c[2]);menu:Hide();self.menu=nil;fn(c[1]) end)
            row:SetPoint("TOPLEFT",8,-6-(i-1)*23)
        end
        menu:SetScript("OnLeave",function(self)if not self:IsMouseOver() then self:Hide();b.menu=nil end end)
    end)
    function b:SetValue(value)
        self.value=value
        for _,c in ipairs(choices) do if c[1]==value then self:SetText(c[2]);return end end
        self:SetText(tostring(value or ""))
    end
    b:SetScript("OnHide",function(self)if self.menu then self.menu:Hide();self.menu=nil end end)
    return b
end
function W.TextureGrid(parent,width,choices,fn)
    local grid=CreateFrame("Frame",nil,parent)
    local columns,gap=4,8
    local cardWidth=math.floor((width-gap*(columns-1))/columns)
    local cardHeight=cardWidth+26
    grid:SetSize(width,math.ceil(#choices/columns)*(cardHeight+gap)-gap)
    grid.buttons={}
    local function Border(button,hover)
        if M:SameTexture(grid.value,button.file) then button:SetBackdropBorderColor(1,.82,0,1)
        elseif hover then button:SetBackdropBorderColor(.7,.7,.72,1)
        else button:SetBackdropBorderColor(.34,.34,.36,1) end
    end
    for index,choice in ipairs(choices) do
        local file,label=choice[1],choice[2]
        local button=CreateFrame("Button",nil,grid,"BackdropTemplate")
        button.file=file;button:SetSize(cardWidth,cardHeight)
        button:SetPoint("TOPLEFT",((index-1)%columns)*(cardWidth+gap),-math.floor((index-1)/columns)*(cardHeight+gap))
        button:SetBackdrop(backdrop);button:SetBackdropColor(.06,.06,.07,.95)
        button:RegisterForClicks("LeftButtonUp")
        local texture=button:CreateTexture(nil,"ARTWORK")
        texture:SetTexture(file);texture:SetSize(cardWidth-18,cardWidth-18);texture:SetPoint("TOP",0,-8)
        button.preview=texture
        local caption=W.Label(button,label,12)
        caption:SetPoint("BOTTOM",0,9);caption:SetWidth(cardWidth-10);caption:SetWordWrap(false);caption:SetJustifyH("CENTER")
        button.check=button:CreateTexture(nil,"OVERLAY")
        button.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        button.check:SetSize(24,24);button.check:SetPoint("TOPRIGHT",-6,-5);button.check:Hide()
        button:SetScript("OnClick",function()grid:SetValue(file);fn(file)end)
        button:SetScript("OnEnter",function(self)Border(self,true)end)
        button:SetScript("OnLeave",function(self)Border(self,false)end)
        Border(button,false);grid.buttons[index]=button
    end
    function grid:SetValue(value)
        self.value=value
        for _,button in ipairs(self.buttons) do
            button.check:SetShown(M:SameTexture(button.file,value));Border(button,false)
        end
    end
    return grid
end
function W.Scroll(parent)
    local s=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate")
    local content=CreateFrame("Frame",nil,s);content:SetSize(200,2);s:SetScrollChild(content)
    return s,content
end
-- Editor icon tooltips use the current resolved input, never a translated name
-- or a saved row that may have changed after typing, sorting or row reuse.
local monitorInputTooltip
local monitorIcons=setmetatable({},{__mode="k"})
local monitorHover,monitorHoverDriver,monitorCheckDriver
local tooltipFailures={}
local function TooltipFailure(stage,err)
    local message=stage..": "..tostring(err)
    if tooltipFailures[#tooltipFailures]~=message then
        tooltipFailures[#tooltipFailures+1]=message
        if #tooltipFailures>8 then table.remove(tooltipFailures,1)end
    end
end
local function InputTooltip()
    monitorInputTooltip=GameTooltip
    return monitorInputTooltip
end
local function OwnsIconTooltip(icon)
    if not monitorInputTooltip then return false end
    if monitorInputTooltip.IsOwned then return monitorInputTooltip:IsOwned(icon)end
    return monitorInputTooltip.GetOwner and monitorInputTooltip:GetOwner()==icon
end
local function HideIconTooltip(icon)
    if OwnsIconTooltip(icon)then monitorInputTooltip:Hide()end
end
local function RenderIconTooltip(icon)
    local info=icon.monitorTooltip
    if not info then HideIconTooltip(icon);return end
    local tip=InputTooltip()
    if not tip then TooltipFailure("GameTooltip","missing");return end
    tip:SetOwner(icon,"ANCHOR_RIGHT")
    -- Use the same direct name tooltip as the working class selectors first.
    -- Native detail queries may clear it; restore this name if they fail.
    local title=info.name or info.id or info.itemID or info.value
    title=title and tostring(title)or ""
    if title~=""then tip:SetText(title,1,1,1);tip:Show()end
    local function Try(methodName,...)
        local method=tip[methodName]
        if type(method)~="function"then TooltipFailure(methodName,"unavailable");return false end
        if tip.ClearLines then tip:ClearLines()end
        local ok,result=pcall(method,tip,...)
        if not ok then TooltipFailure(methodName,result);return false end
        if result==false or (tip.NumLines and tip:NumLines()==0)then
            TooltipFailure(methodName,"no content");return false
        end
        return true
    end
    local item=icon.monitorTooltipKind=="item"or info.itemID~=nil
    local id=item and (info.itemID or info.id)or info.id
    local shown
    if item then
        if info.slot and id then shown=Try("SetInventoryItem","player",info.slot)end
        if not shown and info.link then shown=Try("SetHyperlink",info.link)end
        if not shown and id then shown=Try("SetItemByID",id)or Try("SetHyperlink","item:"..id)end
    else
        if id then shown=Try("SetSpellByID",id)or Try("SetHyperlink","spell:"..id)end
        if not shown and info.name and GetSpellLink then
            local ok,link=pcall(GetSpellLink,info.name)
            if not ok then TooltipFailure("GetSpellLink",link)end
            if ok and type(link)=="string"then shown=Try("SetHyperlink",link)end
        end
    end
    if not shown and title~=""then tip:SetText(title,1,1,1);shown=true end
    if shown then tip:Show()else tip:Hide();TooltipFailure("display","no identity")end
    icon.monitorTooltipRenderedInfo=info
end
local function ShowIconTooltip(icon)
    local ok,err=pcall(RenderIconTooltip,icon)
    if not ok then TooltipFailure("display",err)end
end
-- Input icons also live on drag-enabled rows in a scroll child. Coordinate
-- checks let their tooltips work when a row receives native mouse motion.
local function CursorInside(frame,x,y)
    if not frame or not frame:IsVisible()then return false end
    local scale=frame:GetEffectiveScale()
    local left,right,bottom,top=frame:GetLeft(),frame:GetRight(),frame:GetBottom(),frame:GetTop()
    return left and right and bottom and top and x>=left*scale and x<=right*scale and y>=bottom*scale and y<=top*scale
end
local function MonitorHit()
    local editor=M.editor
    if not editor or not editor.window:IsVisible()or not editor.propScroll then return nil,"editor hidden"end
    if IsMouseButtonDown and (IsMouseButtonDown("LeftButton")or IsMouseButtonDown("RightButton"))then return nil,"mouse button down"end
    -- Inspect all mouse foci. UIParent/WorldFrame are background entries,
    -- not evidence that an unrelated window covers the input icon.
    local foci={}
    if GetMouseFoci then
        local ok,result=pcall(GetMouseFoci)
        if ok and type(result)=="table"then foci=result
        elseif not ok then TooltipFailure("GetMouseFoci",result)end
    elseif GetMouseFocus then
        local ok,result=pcall(GetMouseFocus)
        if ok and result then foci={result}
        elseif not ok then TooltipFailure("GetMouseFocus",result)end
    end
    for _,focus in ipairs(foci)do
        if focus~=UIParent and focus~=WorldFrame then
            local current,inEditor=focus,false
            while current do
                if current.localeTransient then return nil,"menu"end
                if current==editor.window then inEditor=true;break end
                current=current.GetParent and current:GetParent()
            end
            if not inEditor then return nil,"other window"end
        end
    end
    local x,y=GetCursorPosition()
    if not CursorInside(editor.propScroll,x,y)then return nil,"outside scroll viewport"end
    local hit
    for icon in pairs(monitorIcons)do
        if icon.monitorTooltip and CursorInside(icon,x,y)and (not hit or icon:GetFrameLevel()>hit:GetFrameLevel())then hit=icon end
    end
    return hit,hit and "hit"or "outside resolved icons"
end
local function UpdateMonitorHover()
    local hit=MonitorHit()
    if hit~=monitorHover then
        if monitorHover then monitorHover.monitorTooltipHovered=nil;HideIconTooltip(monitorHover)end
        monitorHover=hit
        if hit then hit.monitorTooltipHovered=true;ShowIconTooltip(hit)end
    elseif hit and (not OwnsIconTooltip(hit)or not monitorInputTooltip:IsShown()or hit.monitorTooltipRenderedInfo~=hit.monitorTooltip)then
        ShowIconTooltip(hit)
    end
end
local function WatchMonitorHover()
    if monitorHoverDriver or not M.editor or not M.editor.window then return end
    monitorHoverDriver=CreateFrame("Frame",nil,M.editor.window)
    monitorHoverDriver:EnableMouse(false)
    monitorHoverDriver:SetScript("OnUpdate",function(self,elapsed)
        self.elapsed=(self.elapsed or 0)+elapsed
        if self.elapsed<.08 then return end
        self.elapsed=0;UpdateMonitorHover()
    end)
    monitorHoverDriver:SetScript("OnHide",function()
        if monitorHover then monitorHover.monitorTooltipHovered=nil;HideIconTooltip(monitorHover);monitorHover=nil end
    end)
end
function W.CheckMonitorTooltip()
    M:Print("Icon check v"..M.version..": move to an input icon within 3 seconds.")
    monitorCheckDriver=monitorCheckDriver or CreateFrame("Frame",nil,UIParent)
    monitorCheckDriver.elapsed=0
    monitorCheckDriver:Show()
    monitorCheckDriver:SetScript("OnUpdate",function(self,elapsed)
        self.elapsed=self.elapsed+elapsed
        if self.elapsed<3 then return end
        self:Hide();self:SetScript("OnUpdate",nil)
        local ok,err=pcall(function()
            local hit,reason=MonitorHit();local count=0
            for icon in pairs(monitorIcons)do if icon:IsVisible()and icon.monitorTooltip then count=count+1 end end
            UpdateMonitorHover()
            M:Print("Icons="..count.." Hit="..tostring(hit and hit.monitorTooltip.id).." Tooltip="..tostring(monitorInputTooltip and monitorInputTooltip:IsShown()))
            M:Print("Reason="..tostring(reason).." Enter="..tostring(hit and hit.monitorTooltipEnterCount or 0).." Name="..tostring(hit and hit.monitorTooltip.name))
            for _,message in ipairs(tooltipFailures)do M:Print("Tooltip: "..message)end
        end)
        if not ok then M:Print("Icon check error: "..tostring(err))end
    end)
end
function W.SetIconTooltip(icon,info,kind)
    monitorIcons[icon]=true;WatchMonitorHover()
    local texture=info and info.icon
    local readable=M.Compat.Readable(texture)
    icon.monitorTooltip=readable and (type(texture)=="number"or type(texture)=="string")
        and texture~=0 and texture~=134400 and texture~=""and info or nil
    icon.monitorTooltipKind=kind or "spell"
    if not icon.monitorTooltipBound then
        icon.monitorTooltipBound=true;icon:EnableMouse(true)
        if icon.EnableMouseMotion then icon:EnableMouseMotion(true)end
        icon:HookScript("OnEnter",function(self)self.monitorTooltipEnterCount=(self.monitorTooltipEnterCount or 0)+1;self.monitorTooltipHovered=true;ShowIconTooltip(self)end)
        local function Leave(self)self.monitorTooltipHovered=nil;HideIconTooltip(self)end
        icon:HookScript("OnLeave",Leave)
        icon:HookScript("OnHide",Leave)
        icon:HookScript("OnDragStart",Leave)
    end
    if icon.monitorTooltipHovered and OwnsIconTooltip(icon)then ShowIconTooltip(icon)end
end

function W.BlacklistEditor(parent,width,changed)
    local f=CreateFrame("Frame",nil,parent);f:SetSize(width,234);f.rows={};f.entries={}
    local panel=W.Panel(f);panel:SetPoint("TOPLEFT");panel:SetPoint("TOPRIGHT");panel:SetHeight(198)
    local scroll,body=W.Scroll(panel)
    scroll:SetPoint("TOPLEFT",6,-6);scroll:SetPoint("BOTTOMRIGHT",-28,6);body:SetWidth(width-38)
    f.scroll,f.body=scroll,body
    f.empty=W.Label(body,"黑名单为空");f.empty:SetPoint("TOPLEFT",4,-6)
    local input=W.Edit(f,width-82);input:SetPoint("BOTTOMLEFT",8,4);input:SetMaxLetters(128)
    f.input=input
    local function Tip(button,text)
        button:HookScript("OnEnter",function(self)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(M:T(text),1,1,1);GameTooltip:Show()
        end)
        button:HookScript("OnLeave",function()GameTooltip:Hide()end)
    end
    function f:SetBlacklist(text)
        if self.source==text then return end
        self.source=text;self.entries=M.CooldownMonitor.BlacklistEntries(text)
        for i,value in ipairs(self.entries) do
            local row=self.rows[i]
            if not row then
                row=CreateFrame("Frame",nil,body);row:SetSize(width-38,26)
                row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
                M:BindInputFont(row.label)
                row.label:SetPoint("LEFT",4,0);row.label:SetPoint("RIGHT",-34,0)
                row.label:SetJustifyH("LEFT");row.label:SetWordWrap(false)
                row.remove=W.Button(row,"-",28,function()
                    local entries=M.Copy(self.entries);table.remove(entries,row.index)
                    local text=table.concat(entries,"\n")
                    input:ClearFocus()
                    if changed(text) then self:SetBlacklist(text) end
                end)
                row.remove:SetPoint("RIGHT",-2,0);row.remove:SetHeight(22)
                row.remove:SetHoverTextColor(1,.82,0)
                Tip(row.remove,"移除黑名单")
                self.rows[i]=row
            end
            row.index=i;row.label:SetText(W.SpellInputDisplay(value));row:SetPoint("TOPLEFT",0,-(i-1)*26);row:Show()
        end
        for i=#self.entries+1,#self.rows do self.rows[i]:Hide() end
        self.empty:SetShown(#self.entries==0)
        body:SetHeight(math.max(2,#self.entries*26))
        scroll:SetVerticalScroll(math.min(scroll:GetVerticalScroll(),math.max(0,body:GetHeight()-scroll:GetHeight())))
        scroll:UpdateScrollChildRect()
        if self.clear then self.clear:SetEnabled(#self.entries>0) end
    end
    local function Add()
        local entries=M.Copy(f.entries);local seen={}
        for _,value in ipairs(entries) do seen[value:lower()]=true end
        for _,value in ipairs(M.CooldownMonitor.BlacklistEntries(input:GetText())) do
            if not seen[value:lower()] then entries[#entries+1]=value;seen[value:lower()]=true end
        end
        local text=table.concat(entries,"\n")
        if #entries==#f.entries then input:SetText("");input:ClearFocus();return end
        if #text>4096 then M:Print("黑名单已满，请先移除部分条目。") return end
        if changed(text) then
            f:SetBlacklist(text);input:SetText("");input:ClearFocus()
            scroll:SetVerticalScroll(math.max(0,body:GetHeight()-scroll:GetHeight()))
        end
    end
    f.add=W.Button(f,"+",28,Add);f.add:SetPoint("LEFT",input,"RIGHT",6,0);f.add:SetHeight(22)
    f.add:SetHoverTextColor(1,.82,0);Tip(f.add,"添加黑名单")
    f.clear=W.Button(f,"×",28,function()
        input:ClearFocus()
        if changed("") then f:SetBlacklist("");input:SetText("") end
    end)
    f.clear:SetPoint("LEFT",f.add,"RIGHT",4,0);f.clear:SetHeight(22)
    f.clear:SetHoverTextColor(1,.3,.3);Tip(f.clear,"清除所有")
    input:SetScript("OnEnterPressed",Add)
    f:SetScript("OnHide",function()input:SetText("");input:ClearFocus()end)
    return f
end
function W.ColorSwatch(parent,fn)
    local b=CreateFrame("Button",nil,parent);b:SetSize(16.8,16.8);b.colorSwatchInset=5.6
    local border=b:CreateTexture(nil,"BACKGROUND");border:SetAllPoints();border:SetColorTexture(.75,.75,.75,1)
    b.swatch=b:CreateTexture(nil,"ARTWORK");b.swatch:SetPoint("TOPLEFT",1.2,-1.2);b.swatch:SetPoint("BOTTOMRIGHT",-1.2,1.2)
    function b:SetColor(color)self.color=M.Copy(color);self.swatch:SetColorTexture(unpack(color))end
    b:SetColor({1,1,1,1})
    b:SetScript("OnClick",function()
        if not M:CanEdit() or not ColorPickerFrame then return end
        local previous=M.Copy(b.color)
        local editSession
        local function Apply(color)
            if editSession and M.EditorUndo.session~=editSession then return end
            b:SetColor(color);fn(color)
        end
        local function Pick()local r,g,blue=ColorPickerFrame:GetColorRGB();Apply({r,g,blue,previous[4] or 1})end
        ColorPickerFrame:Hide()
        M.EditorUndo.Begin(b)
        editSession=M.EditorUndo.session
        M.EditorUndo.colorSource=b
        if not ColorPickerFrame.manguiUndoHook then
            ColorPickerFrame.manguiUndoHook=true
            ColorPickerFrame:HookScript("OnHide",function()
                local source=M.EditorUndo.colorSource
                if source then M.EditorUndo.Finish(source);M.EditorUndo.colorSource=nil end
            end)
        end
        local function Cancel()Apply(previous);M.EditorUndo.Finish(b)end
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({r=previous[1],g=previous[2],b=previous[3],hasOpacity=false,
                swatchFunc=Pick,cancelFunc=Cancel})
        else
            ColorPickerFrame.hasOpacity=false;ColorPickerFrame.func=Pick;ColorPickerFrame.opacityFunc=nil
            ColorPickerFrame.cancelFunc=Cancel
            ColorPickerFrame:SetColorRGB(previous[1],previous[2],previous[3]);ColorPickerFrame:Show()
        end
    end)
    return b
end
function W.Confirm(parent,text,fn)
    local f=W.Panel(parent);f:SetFrameStrata("DIALOG");f:SetFrameLevel(9500);f:SetSize(390,135);f:SetPoint("CENTER");f:EnableMouse(true)
    local t=W.Label(f,text,14);t:SetPoint("TOPLEFT",18,-18);t:SetWidth(354);t:SetWordWrap(true)
    local yes=W.Button(f,"确定",90,function()f:Hide();fn()end);yes:SetPoint("BOTTOMRIGHT",-110,16)
    local no=W.Button(f,"取消",90,function()f:Hide()end);no:SetPoint("BOTTOMRIGHT",-14,16)
    return f
end
