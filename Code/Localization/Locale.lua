local _,M=...
local english={}
M.languageOptions={{code="zhCN",label="中文 (zhCN)"},{code="enUS",label="English (enUS)"}}
M.localeTables={enUS=english}
function M:IsLanguageSupported(language)return language=="zhCN" or language=="enUS" end
function M:ClientLanguage()
    local locale=GetLocale and GetLocale() or "enUS"
    return (locale=="zhCN" or locale=="zhTW") and "zhCN" or "enUS"
end
function M:EffectiveLanguage()
    local language=self.db and self.db.language
    return self:IsLanguageSupported(language) and language or self:ClientLanguage()
end
local replacementKeys={}
function M:RebuildLocaleKeys()
    replacementKeys={}
    for source in pairs(english)do replacementKeys[#replacementKeys+1]=source end
    table.sort(replacementKeys,function(a,b)return #a>#b end)
end
M:RebuildLocaleKeys()
function M:T(text)
    text=tostring(text or "")
    local language=self:EffectiveLanguage()
    if language=="zhCN" then return text end
    if english[text] then return english[text] end
    if not text:find("[\128-\255]") then return text end
    for _,key in ipairs(replacementKeys) do
        if text:find(key,1,true) then
            text=text:gsub(key:gsub("([^%w])","%%%1"),function()return english[key] end)
        end
    end
    return text
end
-- Native widgets can outlive their Lua wrappers. Keep fixed interface labels
-- registered even when their only local variable went out of scope.
M.localizedText={}
M.localizedInputs=setmetatable({},{__mode="k"})
local fontRoot="Interface\\AddOns\\MangUI\\Assets\\Fonts\\"
function M:InterfaceFontPath()
    return STANDARD_TEXT_FONT or (GameFontHighlight and select(1,GameFontHighlight:GetFont())) or "Fonts\\FRIZQT__.TTF"
end
function M:IsRetiredFont(value)
    if type(value)~="string" then return false end
    local lower=value:lower()
    return lower:find("notosans",1,true)~=nil or lower:find("noto sans",1,true)~=nil or lower:find("manguiunicode",1,true)~=nil
end
function M:NormalizeRetiredFonts(value,seen)
    if type(value)~="table" then return end
    seen=seen or {};if seen[value] then return end;seen[value]=true
    for key,child in pairs(value) do
        if type(child)=="table" then self:NormalizeRetiredFonts(child,seen)
        elseif self:IsRetiredFont(child) then
            if key=="fontPath" or key=="partyFontPath" or key=="globalFontPath" then value[key]=self:DefaultFontPath()
            elseif key=="fontName" or key=="partyFontName" or key=="globalFontName" or key=="font" then value[key]="默认" end
        end
    end
end
function M:EnsureLocaleLineHeight(label)
    if not label.localeLineHeight or not label.GetFont then return end
    local path,size=label:GetFont();if not path or not size then return end
    local height=label.localeLineHeight
    label:SetHeight(height)
end
function M:SetLocaleLineHeight(label,height)
    label.localeLineHeight=height;self:EnsureLocaleLineHeight(label)
end
function M:FitLocaleText(label,width,minimum)
    if not label or not label.GetFont or not label.GetStringWidth or not width or width<=0 then return end
    local path,size,flags=label:GetFont();if not path or not size then return end
    path=self:ResolveFontPath(path)
    local cached=label.localeFitCache
    local text=label:GetText()
    if cached and cached.text==text and cached.width==width and cached.minimum==(minimum or 9)
        and cached.path==path and cached.size==size and cached.flags==(flags or "") then return end
    label.localeFitSize=label.localeFitSize or size
    label.localeFitWidth=width;label.localeFitMinimum=minimum or 9
    label:SetFont(path,label.localeFitSize,flags or "")
    local measured=label.GetUnboundedStringWidth and label:GetUnboundedStringWidth()or label:GetStringWidth()
    if measured==measured and measured<math.huge and measured>width then
        label:SetFont(path,math.max(label.localeFitMinimum,label.localeFitSize*width/measured),flags or "")
    end
    -- Rebuild the glyph run after changing its face/size. The client can otherwise
    -- retain a clipped run from the previous language in constrained FontStrings.
    if label.localeNativeSetText then
        local text=label:GetText();label.localeNativeSetText(label,"");label.localeNativeSetText(label,text)
    end
    self:EnsureLocaleLineHeight(label)
    local fittedPath,fittedSize,fittedFlags=label:GetFont()
    label.localeFitCache={text=text,width=width,minimum=minimum or 9,path=fittedPath,size=fittedSize,flags=fittedFlags or ""}
end
-- Retired bundled faces in saved profiles/imports resolve to the client default.
function M:ResolveFontPath(path)
    if self:IsRetiredFont(path) then return self:DefaultFontPath() end
    path=self:ResolveAssetPath(path)
    if type(path)=="string" and path:lower():find("interface\\addons\\",1,true)==1
        and path:sub(1,#fontRoot):lower()~=fontRoot:lower() then return self:DefaultFontPath() end
    return path
end
function M:BundledFontChoices()
    local items={{name="默认",path=self:DefaultFontPath()},{name="Myriad",path=self.MYRIAD}}
    items[#items+1]={name="NoWCL 默认",path=self:DefaultFontPath()}
    items[#items+1]={name="Visitor",path=fontRoot.."Visitor.ttf"}
    items[#items+1]={name="WenQuanYi Zen Hei",path=fontRoot.."WenQuanYiZenHei\\wqy-zenhei.ttf"}
    items[#items+1]={name="伤害数字",path=self:ResolveAssetPath("Fonts\\ARKai_C.ttf")}
    items[#items+1]={name="聊天",path=self:ResolveAssetPath("Fonts\\ARHei.ttf")}
    return items
end
function M:ApplyLocaleFont(object,text)
    local label=object.GetFontString and object:GetFontString() or object
    if not label or not label.GetFont or not label.SetFont then return end
    local path,size,flags=label:GetFont()
    if not path or not size then return end
    local desired=self:InterfaceFontPath()
    if label.localeInputHeight then
        label.localeBaseSize=label.localeBaseSize or size;label.localeBaseFlags=label.localeBaseFlags or flags
        size=label.localeBaseSize;flags=label.localeBaseFlags
    end
    if label.localePreviewFont and text and not tostring(text):find("[\128-\255]") then
        desired=self:ResolveFontPath(label.localePreviewFont)
        size=label.localePreviewSize or size;flags=label.localePreviewFlags or ""
    end
    local _,currentSize,currentFlags=label:GetFont()
    if desired~=path or size~=currentSize or flags~=currentFlags then
        local ok,loaded=pcall(label.SetFont,label,desired,size,flags or "")
        if not ok or loaded==false then label:SetFont(self:InterfaceFontPath(),size,flags or "") end
    end
    self:EnsureLocaleLineHeight(label)
end
function M:BindInputFont(object)
    if not object or not object.GetFont then return end
    self.localizedInputs[object]=true
    object.localeInputHeight=object:GetHeight()
    self:ApplyLocaleFont(object,object:GetText(),true)
end
function M:BindText(object)
    if self.localizedText[object] then return object end
    local native=object.SetText;self.localizedText[object]=true
    object.localeNativeSetText=native
    local parent=object
    while parent do
        if parent.localeTransient then
            parent.localeObjects=parent.localeObjects or {};parent.localeObjects[object]=true
            break
        end
        parent=parent.GetParent and parent:GetParent()or nil
    end
    local label=object.GetFontString and object:GetFontString()or object
    if label.GetFont then label.localeBaseFont=select(1,label:GetFont())end
    function object:SetText(text)
        self.localeSource=text or ""
        local translated=M:T(self.localeSource)
        local label=self.GetFontString and self:GetFontString()or self
        local path,size,flags
        if label.GetFont then path,size,flags=label:GetFont() end
        local cached=self.localeRenderCache
        if cached and self.localeRenderedText==translated and cached.path==path and cached.size==size and cached.flags==flags
            and cached.preview==self.localePreviewFont and cached.language==M:EffectiveLanguage()
            and self.GetText and self:GetText()==translated
            and (label==self or not label.GetText or label:GetText()==translated) then return end
        self.localeRenderedText=translated
        M:ApplyLocaleFont(self,translated)
        native(self,"");native(self,translated)
        local buttonLabel=self.GetFontString and self:GetFontString()
        if buttonLabel then
            -- Keep the visible FontString in sync with the button's native text
            -- cache, including after SetNormalFontObject/hover/show updates.
            local set=buttonLabel.localeNativeSetText or buttonLabel.SetText
            set(buttonLabel,"");set(buttonLabel,translated)
        end
        if self.localeFitWidth then M:FitLocaleText(self,self.localeFitWidth,self.localeFitMinimum)end
        if label.GetFont then path,size,flags=label:GetFont() end
        self.localeRenderCache={path=path,size=size,flags=flags,preview=self.localePreviewFont,language=M:EffectiveLanguage()}
    end
    return object
end
function M:ReleaseLocaleScope(scope)
    for object in pairs(scope.localeObjects or {})do self.localizedText[object]=nil end
    scope.localeObjects=nil
end
function M:RefreshLanguage()
    for object in pairs(self.localizedText) do object.localeRenderCache=nil;object.localeFitCache=nil;object:SetText(object.localeSource) end
    for object in pairs(self.localizedInputs)do self:ApplyLocaleFont(object,object:GetText(),true)end
    if self.RefreshEditor then self:RefreshEditor() end
    if self.RefreshOtherSettings then self:RefreshOtherSettings() end
end
function M:SetLanguage(language)
    if not self:IsLanguageSupported(language) then return end
    self.db.language=language;self:RefreshLanguage()
    -- Measurements made in the same event as SetFont can precede client layout.
    -- Coalesce rapid switches and fit the final language once on the next frame.
    if C_Timer and C_Timer.After and not self.localeRefreshQueued then
        self.localeRefreshQueued=true
        C_Timer.After(0,function()
            self.localeRefreshQueued=nil
            if self.db then self:RefreshLanguage()end
        end)
    end
    if self.started and self.ApplyLive then
        if InCombatLockdown()then self.pending=true else self:Safe("应用布局",self.ApplyLive,self)end
    end
end
