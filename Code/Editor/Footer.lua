local _, M = ...
local F={};M.FooterLinks=F
-- Card count matches the current CardMaster catalogue; no CardMaster dependency.
F.cardCount=2678

local ROOT = "Interface\\AddOns\\MangUI\\Assets\\Footer\\"
local ENTRIES = {
    { id = "kook", zh = "KOOK", en = "KOOK", chinese = true, activeTexture = "kook_color.tga", url = "https://kook.vip/DqQ5U4" },
    { id = "discord", zh = "Discord", en = "Discord", chinese = false, activeTexture = "discord_color.tga", pending = true },
    { id = "afdian", zh = "爱发电", en = "Afdian", chinese = true, activeTexture = "afdian_color.tga", url = "https://ifdian.net/a/cardmaster" },
    { id = "patreon", zh = "Patreon", en = "Patreon", chinese = false, activeTexture = "patreon_color.tga", pending = true },
    { id = "cardmaster", zh = "CardMaster 卡牌大师", en = "CardMaster", fullColor = true, copyText = "CardMaster" },
    { id = "github", zh = "GitHub", en = "GitHub", url = "https://github.com/Nicconicc/CardMaster" },
}
F.entries=ENTRIES

local function text(zh, en)
    return M:EffectiveLanguage() == "enUS" and en or zh
end

local function chineseClient()
    local locale = GetLocale and GetLocale() or "enUS"
    return locale == "zhCN" or locale == "zhTW"
end

local function description(entry)
    if entry.id == "cardmaster" then
        return text("欢迎使用CardMaster卡牌大师插件，它经常和MangUI配套使用，祝开心", "Welcome to CardMaster! It is often used alongside MangUI. Have fun!")
    elseif entry.id == "kook" then
        return text("欢迎加入KOOK社群，在这里找到作者，并与朋友们畅聊。", "Join our KOOK community to meet the author and chat with friends.")
    elseif entry.id == "afdian" then
        local total = F.cardCount
        return string.format(text("感谢您请我喝茶，我已绘制了%d张卡牌，您的支持是我开发和绘制下一套卡牌的绝对动力。", "Thank you for treating me to tea! I have drawn %d cards, and your support keeps me developing CardMaster and drawing the next set."), total)
    elseif entry.pending then
        return text("创建中，请等待", "Coming soon, please wait")
    end
    return text("复制下方网址，在浏览器中打开。", "Copy the website address below and open it in your browser.")
end

local function panel(parent)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.025, 0.025, 0.035, 0.98)
    frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
    return frame
end

local function highlight(button, active)
    local entry = button.entry
    button.icon:SetTexture(entry.fullColor and (ROOT .. "CardMaster.png") or
        (ROOT .. (active and entry.activeTexture or (entry.id .. (active and "_white" or "") .. ".tga"))))
    button.icon:SetDesaturated(not active)
    button.icon:SetVertexColor(1, 1, 1, 1)
    button.icon:SetAlpha(active and 1 or 0.65)
    button.glow:SetShown(active)
    if button.shine then button.shine:SetShown(active) end
end

function F.Attach(editor)
    local window=editor.window
    local bar = CreateFrame("Frame", nil, window)
    bar:SetSize(158, 30)
    bar:SetPoint("BOTTOMRIGHT", -20, 12)
    bar.buttons = {}
    editor.footerLinks = bar
    bar.label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bar.label:SetJustifyV("MIDDLE")
    bar.label:SetPoint("RIGHT", bar, "LEFT", -12, 0)
    bar.label:SetText(text("在这里找到作者", "Community & Support"))
    bar.label:SetTextColor(0.7, 0.75, 0.8)

    local popup = panel(bar)
    popup:SetSize(420, 110)
    popup:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 5)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup:Hide()
    popup:EnableKeyboard(true);popup:SetPropagateKeyboardInput(true)
    popup:SetScript("OnKeyDown",function(owner,key)
        owner:SetPropagateKeyboardInput(key~="ESCAPE")
        if key=="ESCAPE"then owner:Hide()end
    end)
    popup.title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popup.title:SetPoint("TOPLEFT", 12, -12)
    popup.title:SetTextColor(1, 0.82, 0)
    local popupFont, popupFontSize, popupFontFlags = popup.title:GetFont()
    bar.label:SetFont(popupFont, popupFontSize, popupFontFlags)
    popup.description = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    popup.description:SetFont(popupFont, popupFontSize, popupFontFlags)
    popup.description:SetPoint("TOPLEFT", popup.title, "BOTTOMLEFT", 0, -8)
    popup.description:SetWidth(396)
    popup.description:SetJustifyH("LEFT")
    popup.description:SetJustifyV("TOP")
    popup.description:SetWordWrap(true)
    popup.description:SetNonSpaceWrap(true)
    if popup.description.SetMaxLines then popup.description:SetMaxLines(0) end
    popup.description:SetTextColor(1, 1, 1)
    popup.hint = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    popup.hint:SetFont(popupFont, popupFontSize, popupFontFlags)
    popup.hint:SetTextColor(1, 1, 1)
    local address = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
    address:SetPoint("TOPLEFT", popup.description, "BOTTOMLEFT", 4, -10)
    address:SetSize(388, 23)
    address:SetFont(popupFont, popupFontSize, popupFontFlags)
    address:SetTextColor(1, 1, 1)
    popup.hint:SetPoint("TOPLEFT", address, "BOTTOMLEFT", -4, -8)
    address:SetAutoFocus(false)
    address:SetScript("OnEscapePressed", function() popup:Hide() end)
    address:SetScript("OnEditFocusGained", function(owner) owner:HighlightText() end)
    address:SetScript("OnMouseUp", function(owner) popup.pinned = true; owner:SetFocus(); owner:HighlightText() end)
    address:SetScript("OnTextChanged", function(owner, userInput)
        if userInput and popup.copyText then owner:SetText(popup.copyText); owner:HighlightText() end
    end)
    local close = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)
    close:SetSize(24, 24)
    M.Widgets.StyleButton(close)
    close:SetScript("OnClick", function() popup:Hide() end)
    popup:SetScript("OnHide", function()
        address:ClearFocus()
        if popup.owner then highlight(popup.owner, false) end
        popup.owner, popup.copyText, popup.pinned = nil, nil, nil
    end)
    bar.popup = popup

    -- Leave time to cross the small gap into the copyable popup. A click pins
    -- it until closed so copying does not depend on keeping the pointer still.
    local hideToken = 0
    local function cancelHide()
        hideToken = hideToken + 1
    end
    local function scheduleHide()
        cancelHide()
        local token = hideToken
        C_Timer.After(0.25, function()
            if token ~= hideToken or popup.pinned or not popup:IsShown() then return end
            if MouseIsOver(popup) or (popup.owner and MouseIsOver(popup.owner)) then return end
            popup:Hide()
        end)
    end
    popup:SetScript("OnEnter", cancelHide)
    popup:SetScript("OnLeave", scheduleHide)
    address:SetScript("OnEnter", cancelHide)
    address:SetScript("OnLeave", scheduleHide)

    local function layoutPopup()
        -- Clear the last entry's height before measuring; otherwise a short
        -- tooltip can constrain a later long Chinese description to one line.
        popup.description:SetHeight(0)
        local descriptionHeight = math.max(popupFontSize, math.ceil(popup.description:GetStringHeight())) + 2
        popup.description:SetHeight(descriptionHeight)
        popup:SetHeight(12 + math.ceil(popup.title:GetStringHeight()) + 8
            + descriptionHeight + 10 + 23 + 8
            + math.ceil(popup.hint:GetStringHeight()) + 12)
    end

    local function showPopup(owner, focus)
        cancelHide()
        GameTooltip:Hide()
        local sameOwner = popup.owner == owner
        if popup.owner and not sameOwner then highlight(popup.owner, false) end
        popup.owner = owner
        popup.pinned = focus or (sameOwner and popup.pinned) or false
        local entry = owner.entry
        popup.title:SetText(text(entry.zh, entry.en))
        popup.description:SetHeight(0)
        popup.description:SetText(description(entry))
        popup.copyText = entry.copyText or entry.url or text("创建中，请等待", "Coming soon, please wait")
        popup.hint:SetText(text("按 Ctrl+C 复制", "Press Ctrl+C to copy"))
        layoutPopup()
        if not sameOwner then address:ClearFocus() end
        address:SetText(popup.copyText)
        popup:Show()
        C_Timer.After(0, function()
            if popup:IsShown() and popup.owner == owner then layoutPopup() end
        end)
        highlight(owner, true)
        if focus then
            address:SetFocus()
            address:HighlightText()
        end
    end

    for index, entry in ipairs(ENTRIES) do
        local button = CreateFrame("Button", nil, bar)
        button.entry = entry
        button:SetSize(32, 30)
        button.glow = button:CreateTexture(nil, "BACKGROUND")
        button.glow:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        button.glow:SetBlendMode("ADD")
        button.glow:SetVertexColor(1, 1, 1, 0.25)
        button.glow:SetAllPoints()
        button.icon = button:CreateTexture(nil, "ARTWORK")
        -- Other footer marks have 12px transparent margins in a 128px image.
        -- Match their visible size with this full-canvas brand image.
        local iconSize=entry.fullColor and 30*104/128 or 30
        button.icon:SetSize(iconSize, iconSize)
        button.icon:SetPoint("CENTER")
        if entry.fullColor then
            button.shine = button:CreateTexture(nil, "OVERLAY")
            button.shine:SetAllPoints(button.icon)
            button.shine:SetTexture(ROOT .. "CardMaster.png")
            button.shine:SetBlendMode("ADD")
            button.shine:SetAlpha(0.25)
        end
        highlight(button, false)
        button:SetScript("OnEnter", function(owner)
            showPopup(owner, false)
        end)
        button:SetScript("OnLeave", function(owner)
            highlight(owner, not entry.fullColor and popup:IsShown() and popup.owner == owner)
            scheduleHide()
        end)
        button:SetScript("OnClick", function(owner)
            showPopup(owner, true)
        end)
        bar.buttons[index] = button
    end
    bar:SetScript("OnHide", function() popup:Hide(); GameTooltip:Hide() end)
    bar:SetScript("OnShow",function()F.Refresh(editor)end)
    F.Refresh(editor)
    return bar
end

function F.Refresh(editor)
    local bar = editor and editor.footerLinks
    if not bar then return end
    bar.label:SetText(text("在这里找到作者", "Community & Support"))
    bar.popup:Hide()
    local chinese = chineseClient()
    local visible = 0
    for _, button in ipairs(bar.buttons) do
        local show = button.entry.chinese == nil or button.entry.chinese == chinese
        button:SetShown(show)
        button:ClearAllPoints()
        if show then
            button:SetPoint("LEFT", bar, "LEFT", visible * 42, 0)
            visible = visible + 1
        end
    end
    bar:SetWidth(math.max(32, (visible - 1) * 42 + 32))
    GameTooltip:Hide()
end
