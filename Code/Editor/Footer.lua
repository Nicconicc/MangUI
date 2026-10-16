local _,M=...
local W=M.Widgets
local F={};M.FooterLinks=F

-- Replace these temporary URLs with the creator's pages and community invites.
F.entries={
    {id="cardmaster",label="MangUI卡牌大师",tooltip="与插件“MangUI卡牌大师”配合使用体验更佳",fullColor=true,
        copyText="MangUICardMaster",description="复制插件名在任意插件平台搜索。",copyHint="按 Ctrl+C 复制插件名"},
    {id="paypal",label="PayPal",url="https://www.paypal.com/",description="支持 MangUI 的开发。"},
    {id="afdian",label="爱发电",url="https://afdian.com/",description="支持 MangUI 的开发。"},
    {id="patreon",label="Patreon",url="https://www.patreon.com/",description="支持 MangUI 的开发。"},
    {id="discord",label="Discord",url="https://discord.com/",description="加入 MangUI 社区。"},
    {id="kook",label="Kook",url="https://www.kookapp.cn/",description="加入 MangUI 社区。"},
    {id="changelog",label="更新日志",url="https://example.com/mangui/changelog",description="查看 MangUI 的更新记录。"},
}

local function Highlight(button,active)
    if button.entry.fullColor then
        button.icon:SetTexture("Interface\\AddOns\\MangUI\\Assets\\Footer\\"..button.entry.id..".tga")
        button.icon:SetDesaturated(false);button.icon:SetAlpha(1)
        if button.shine then button.shine:SetShown(active) end
        button.glow:SetShown(active)
        return
    end
    button.icon:SetTexture("Interface\\AddOns\\MangUI\\Assets\\Footer\\"..button.entry.id..(active and "_white" or "")..".tga")
    button.icon:SetAlpha(active and 1 or .65)
    button.glow:SetShown(active)
end

function F.Attach(editor)
    local bar=CreateFrame("Frame",nil,editor.window)
    bar:SetSize(284,30);bar:SetPoint("BOTTOMRIGHT",-20,12)
    editor.footerLinks=bar;bar.buttons={}

    local nameTip=W.Panel(bar);bar.nameTip=nameTip
    nameTip:Hide();nameTip:SetFrameStrata("TOOLTIP");nameTip:SetFrameLevel(10200)
    nameTip:SetClampedToScreen(true);nameTip:EnableMouse(false)
    nameTip:SetBackdropColor(.025,.025,.035,.98);nameTip:SetBackdropBorderColor(.8,.8,.8,1)
    nameTip.label=nameTip:CreateFontString(nil,"OVERLAY","GameTooltipText")
    nameTip.label:SetPoint("CENTER",0,0)
    nameTip.label:SetJustifyH("CENTER");nameTip.label:SetJustifyV("MIDDLE")
    nameTip.label:SetTextColor(1,.82,0,1)

    local popup=W.Panel(bar);bar.popup=popup
    popup:Hide();popup:SetSize(380,120)
    popup:SetFrameStrata("TOOLTIP");popup:SetFrameLevel(10100)
    popup:SetClampedToScreen(true);popup:EnableMouse(true)
    popup:SetPoint("BOTTOMRIGHT",bar,"TOPRIGHT",0,5)
    popup:SetBackdropColor(.025,.025,.035,.98)
    popup:SetBackdropBorderColor(.8,.8,.8,1)
    popup:RegisterEvent("GLOBAL_MOUSE_DOWN")
    popup:SetScript("OnEvent",function(self,event)
        if event=="GLOBAL_MOUSE_DOWN" and self:IsShown() and not self:IsMouseOver() then
            self:Hide()
        end
    end)
    popup.title=W.Label(popup,"",14);popup.title:SetPoint("TOPLEFT",12,-10)
    popup.title:SetTextColor(1,.82,0)
    local close=CreateFrame("Button",nil,popup,"UIPanelCloseButton")
    close:SetSize(24,24);close:SetPoint("TOPRIGHT",0,0);W.StyleButton(close)
    close:SetScript("OnClick",function()popup:Hide()end);popup.close=close
    popup.description=W.Label(popup,"",12)
    popup.description:SetPoint("TOPLEFT",12,-32);popup.description:SetSize(356,22)
    popup.description:SetWordWrap(true)
    local function LayoutPopup()
        local height=math.max(22,popup.description:GetStringHeight()+2)
        popup.description:SetHeight(height);popup:SetHeight(98+height)
        if popup.address then
            popup.address:ClearAllPoints()
            popup.address:SetPoint("TOPLEFT",12,-37-height)
            popup.address:SetPoint("TOPRIGHT",-12,-37-height)
        end
    end
    popup.hint=W.Label(popup,"按 Ctrl+C 复制 URL",12)
    popup.hint:SetPoint("BOTTOMLEFT",12,10)

    local address=CreateFrame("EditBox",nil,popup,"BackdropTemplate");popup.address=address
    address:SetPoint("TOPLEFT",12,-59);address:SetPoint("TOPRIGHT",-12,-59);address:SetHeight(23)
    address:SetFontObject(GameFontHighlightSmall);address:SetTextColor(1,1,1)
    address:SetAutoFocus(false);address:SetMultiLine(false);address:SetTextInsets(6,6,0,0)
    address:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,
        insets={left=2,right=2,top=2,bottom=2}})
    address:SetBackdropColor(.015,.015,.02,1);address:SetBackdropBorderColor(.5,.5,.5,1)
    local function SelectAddress()address:SetFocus();address:HighlightText()end
    address:SetScript("OnEditFocusGained",function(self)self:HighlightText()end)
    address:SetScript("OnMouseUp",SelectAddress)
    address:SetScript("OnEnterPressed",SelectAddress)
    address:SetScript("OnEscapePressed",function()popup:Hide()end)
    -- Keep the copy field selectable without allowing edits to change its content.
    address:SetScript("OnTextChanged",function(self,userInput)
        if userInput and popup.owner then
            self:SetText(popup.owner.entry.copyText or popup.owner.entry.url);self:HighlightText()
        end
    end)
    popup:SetScript("OnHide",function(self)
        address:ClearFocus()
        if self.owner then Highlight(self.owner,self.owner:IsMouseOver()) end
        self.owner=nil
    end)
    local function Show(button)
        nameTip:Hide()
        if popup.owner and popup.owner~=button then Highlight(popup.owner,popup.owner:IsMouseOver()) end
        popup.owner=button
        popup.title:SetText(button.entry.label);popup.description:SetText(button.entry.description)
        local copyText=button.entry.copyText or button.entry.url
        popup.hint:SetText(button.entry.copyHint or "按 Ctrl+C 复制 URL")
        address:SetText(copyText)
        M:ApplyLocaleFont(address,copyText,true)
        LayoutPopup()
        popup:Show();Highlight(button,true);SelectAddress()
    end
    for index,entry in ipairs(F.entries) do
        local button=CreateFrame("Button",nil,bar);bar.buttons[index]=button;button.entry=entry
        button:SetSize(32,30);button:SetPoint("LEFT",bar,"LEFT",(index-1)*42,0)
        button.glow=button:CreateTexture(nil,"BACKGROUND")
        button.glow:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        button.glow:SetBlendMode("ADD");button.glow:SetVertexColor(1,1,1,.25)
        button.glow:SetAllPoints();button.glow:Hide()
        button.icon=button:CreateTexture(nil,"ARTWORK")
        button.icon:SetSize(30,30);button.icon:SetPoint("CENTER")
        button.icon:SetTexture("Interface\\AddOns\\MangUI\\Assets\\Footer\\"..entry.id..".tga")
        button.icon:SetDesaturated(not entry.fullColor)
        if entry.fullColor then
            button.shine=button:CreateTexture(nil,"OVERLAY")
            button.shine:SetAllPoints(button.icon)
            button.shine:SetTexture("Interface\\AddOns\\MangUI\\Assets\\Footer\\"..entry.id..".tga")
            button.shine:SetBlendMode("ADD");button.shine:SetAlpha(.25)
        end
        Highlight(button,false)
        button:SetScript("OnEnter",function(self)
            Highlight(self,true)
            if popup:IsShown() then
                nameTip:Hide();nameTip.owner=nil
                return
            end
            local title=M:T(self.entry.tooltip or self.entry.label)
            local reference=_G.GameTooltipTextLeft1 or GameTooltipHeaderText or GameTooltipText
            local font,size,flags=reference:GetFont()
            nameTip.label:SetFont(M:ResolveFontPath(font),size,flags or "")
            nameTip.label:SetText(title)
            if title:find("[\128-\255]") then M:ApplyLocaleFont(nameTip.label,title) end
            nameTip:SetSize(math.max(90,nameTip.label:GetStringWidth()+24),38)
            nameTip:ClearAllPoints();nameTip:SetPoint("BOTTOM",self,"TOP",0,8)
            nameTip.owner=self;nameTip:Show()
        end)
        button:SetScript("OnLeave",function(self)
            if nameTip.owner==self then nameTip:Hide();nameTip.owner=nil end
            Highlight(self,popup:IsShown() and popup.owner==self)
        end)
        if entry.url or entry.copyText then button:SetScript("OnClick",Show) end
    end
    bar:SetScript("OnHide",function()nameTip:Hide();nameTip.owner=nil;popup:Hide()end)
    return bar
end
