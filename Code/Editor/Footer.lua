local _, M = ...
local F={};M.FooterLinks=F
-- Card count matches the current CardMaster catalogue; no CardMaster dependency.
F.cardCount=2678

local ROOT = "Interface\\AddOns\\MangUI\\Assets\\Footer\\"
local ENTRIES = {
    { id = "kook", zh = "KOOK", en = "KOOK", chinese = true, activeTexture = "kook_color.tga", url = "https://kook.vip/DqQ5U4" },
    { id = "discord", zh = "Discord", en = "Discord", chinese = false, activeTexture = "discord_color.tga", pending = true },
    { id = "afdian", zh = "爱发电", en = "Afdian", chinese = true, heart = true, url = "https://ifdian.net/a/cardmaster" },
    { id = "patreon", zh = "Patreon", en = "Patreon", chinese = false, heart = true, pending = true },
    { id = "cardmaster", zh = "CardMaster 卡牌大师", en = "CardMaster", fullColor = true, copyText = "CardMaster" },
    { id = "github", zh = "GitHub", en = "GitHub", url = "https://github.com/Nicconicc/MangUI" },
}
F.entries=ENTRIES

local communityLinks = {
    {description="欢迎前往抖音直播，我在这里与大家互动，解答问题，搜索“队长Nc”或",
        traditional="歡迎前往抖音直播，我在這裡與大家互動，解答問題，搜尋「隊長Nc」或",url="https://live.douyin.com/992901018697"},
    {description="感谢您的支持，请我喝茶，每份捐助都是我继续下去的动力。",
        traditional="感謝您的支持，請我喝茶，每份捐助都是我繼續下去的動力。",url=ENTRIES[3].url},
}

local function text(zh, en)
    local language = M:EffectiveLanguage()
    local translated=M:T(zh)
    if language=="zhCN"then return translated end
    return translated~=zh and translated or en
end

local function chineseClient()
    local locale = M:EffectiveLanguage()
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
        return text("正在建设中", "Under construction")
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
    if entry.heart then
        local hovered=button:IsMouseOver()
        button.glow:SetShown(hovered)
        button.shine:SetShown(hovered)
        return
    end
    button.icon:SetTexture(entry.fullColor and (ROOT .. "CardMaster.png") or
        (ROOT .. (active and entry.activeTexture or (entry.id .. (active and "_white" or "") .. ".tga"))))
    button.icon:SetDesaturated(not active)
    button.icon:SetVertexColor(1, 1, 1, 1)
    button.icon:SetAlpha(active and 1 or 0.65)
    button.glow:SetShown(active)
    if button.shine then button.shine:SetShown(active) end
end

local heartTexture=ROOT.."SupportHeart.tga"
local heartColors={
    {1,.32,.55},{1,.69,.24},{.49,.79,1},{.75,.43,1},{.48,1,.68},
}
local trimColors={{1,.49,.56},{.52,.81,1},{.75,.55,1},{.55,1,.66},{1,.73,.42},{.62,1,.94}}
local borderParts={"TopLeftCorner","TopRightCorner","BottomLeftCorner","BottomRightCorner",
    "TopEdge","BottomEdge","LeftEdge","RightEdge","BotLeftCorner","BotRightCorner",
    "TopBorder","BottomBorder","BotBorder","LeftBorder","RightBorder"}
local unpack=unpack or table.unpack
local heartSize,beatDuration,heartInterval=27,3,10
local beatOffsets={0,.15,.31,.47,.72}
local beatScales={1,1.43,1.02,1.29,1}
local function HeartScale(progress)
    -- CSS ease-in-out from the preview, followed by linear keyframe interpolation.
    local t=progress
    for _=1,4 do
        local x=t*(1.26+t*(-.78+.52*t))
        t=t-(x-progress)/(1.26+1.56*t*(t-1))
    end
    local eased=t*t*(3-2*t)
    for i=2,#beatOffsets do
        if eased<beatOffsets[i] then
            local fraction=(eased-beatOffsets[i-1])/(beatOffsets[i]-beatOffsets[i-1])
            return beatScales[i-1]+(beatScales[i]-beatScales[i-1])*fraction
        end
    end
end

local function SetTrimColor(window,color)
    local slice=window.NineSlice
    if slice and slice.SetBorderColor then
        if color then
            if not window.supportTrimBase then
                local base=slice.borderColor
                window.supportTrimBase=base and {base.r,base.g,base.b,base.a or 1} or {1,1,1,1}
            end
            slice:SetBorderColor(color[1],color[2],color[3],1)
        elseif window.supportTrimBase then
            slice:SetBorderColor(unpack(window.supportTrimBase))
            window.supportTrimBase=nil
        end
    else
        local name=window:GetName()
        local original=window.supportTrimPieces or {}
        for _,part in ipairs(borderParts) do
            local piece=(slice and slice[part]) or window[part] or (name and _G[name..part])
            if color and piece and piece.SetVertexColor then
                if not original[piece] then original[piece]={piece:GetVertexColor()} end
                piece:SetVertexColor(color[1],color[2],color[3],original[piece][4] or 1)
            end
        end
        if color then window.supportTrimPieces=original
        else
            for piece,rgba in pairs(original) do piece:SetVertexColor(unpack(rgba)) end
            window.supportTrimPieces=nil
        end
    end
end

local function PaintHeart(icon)
    icon:SetTexture(heartTexture)
    icon:SetVertexColor(1,.17,.29,1)
end

local function SetupSupportHeart(button,window,interval)
    local baseSize=button.icon:GetWidth()
    PaintHeart(button.icon)
    button.shine=button:CreateTexture(nil,"OVERLAY")
    button.shine:SetAllPoints(button.icon)
    button.shine:SetTexture(heartTexture)
    button.shine:SetVertexColor(1,.38,.49,1)
    button.shine:SetBlendMode("ADD")
    button.shine:SetAlpha(.48)
    button.shine:Hide()

    local art=CreateFrame("Frame",nil,button)
    art:SetAllPoints(button)
    art:SetFrameStrata("TOOLTIP")
    art:SetFrameLevel((window or button):GetFrameLevel()+100)
    art:EnableMouse(false)

    local particles={}
    local particleSize=baseSize*.8
    for i=1,30 do
        local heart=art:CreateTexture(nil,"OVERLAY")
        heart:SetTexture(heartTexture)
        heart:SetSize(particleSize,particleSize)
        local flight=heart:CreateAnimationGroup()
        local rise=flight:CreateAnimation("Translation")
        rise:SetSmoothing("OUT")
        local shrink=flight:CreateAnimation("Scale")
        shrink:SetScaleFrom(1,1)
        shrink:SetScaleTo(.625,.625)
        local spin=flight:CreateAnimation("Rotation")
        local fade=flight:CreateAnimation("Alpha")
        fade:SetFromAlpha(.95)
        fade:SetToAlpha(0)
        local animations={rise,shrink,spin,fade}
        for _,animation in ipairs(animations) do animation:SetOrder(1) end
        flight:SetScript("OnFinished",function()heart:Hide()end)
        heart:Hide()
        particles[i]={heart=heart,flight=flight,rise=rise,spin=spin,animations=animations}
    end

    local nextParticle=1
    local function ReleaseHearts()
        for _=1,math.random(5,8) do
            local particle=particles[nextParticle]
            nextParticle=nextParticle%#particles+1
            particle.flight:Stop()
            local heart=particle.heart
            local color=heartColors[math.random(#heartColors)]
            heart:SetVertexColor(color[1],color[2],color[3])
            heart:ClearAllPoints()
            heart:SetPoint("CENTER",button,"CENTER",math.random(-10,10),math.random(-3,8))
            heart:SetRotation(math.rad(math.random(-28,28)))
            particle.rise:SetOffset(math.random(-48,48),math.random(48,94))
            particle.spin:SetDegrees(math.random(25,154)*(math.random(2)==1 and -1 or 1))
            local duration=math.random(152,245)/100
            for _,animation in ipairs(particle.animations) do animation:SetDuration(duration) end
            heart:Show()
            particle.flight:Play()
        end
    end

    local clicks,lastClick=0
    button.releaseSupportHearts=ReleaseHearts
    if window then
        button.releaseSupportHearts=function()
            ReleaseHearts()
            local now=GetTime()
            if lastClick and now-lastClick>2 then clicks=0 end
            lastClick=now
            clicks=clicks+1
            if clicks==10 then
                clicks=0
                local index=math.random(#trimColors)
                if index==window.supportTrim then index=index%#trimColors+1 end
                window.supportTrim=index
                SetTrimColor(window,trimColors[index])
            end
        end
        button.resetSupportTrim=function()
            clicks,lastClick=0,nil
            window.supportTrim=nil
            SetTrimColor(window)
        end
    end
    local function StopBeat()
        art:SetScript("OnUpdate",nil)
        button.icon:SetSize(baseSize,baseSize)
    end
    local function Pulse()
        if not button:IsVisible() then return end
        local started=GetTime()
        art:SetScript("OnUpdate",function()
            local progress=(GetTime()-started)/beatDuration
            if progress>=1 then StopBeat();return end
            local scale=HeartScale(progress)
            if not scale then StopBeat();return end
            local size=baseSize*scale
            button.icon:SetSize(size,size)
        end)
        ReleaseHearts()
    end
    local ticker
    local function Start()
        if ticker then return end
        if not interval then Pulse() end
        ticker=C_Timer.NewTicker(interval or heartInterval,Pulse)
    end
    button:HookScript("OnShow",Start)
    button:HookScript("OnHide",function()
        clicks,lastClick=0,nil
        if ticker then ticker:Cancel();ticker=nil end
        StopBeat()
        for _,particle in ipairs(particles) do
            particle.flight:Stop()
            particle.heart:Hide()
        end
    end)
    if button:IsVisible() then Start() end
end

local function createLinkPopup(parent, setHighlight, extraLinks)
    local popup = panel(parent)
    popup:SetSize(420, 110)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup:Hide()
    local keyboardEnabled = false
    popup:SetScript("OnKeyDown",function(owner,key)
        if key == "ESCAPE" and not InCombatLockdown() then
            M.Widgets.SetEditorKeyboard(owner, nil, false)
            owner:Hide()
        end
    end)
    popup.title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popup.title:SetPoint("TOPLEFT", 12, -12)
    popup.title:SetTextColor(1, 0.82, 0)
    local popupFont, popupFontSize, popupFontFlags = popup.title:GetFont()
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
    popup.fontRegions = {popup.title,popup.description,popup.hint}
    local addresses = {}
    local function addAddress(label)
        local box = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
        box:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 4, -10)
        box:SetSize(388, 23)
        box:SetFont(popupFont, popupFontSize, popupFontFlags)
        box:SetTextColor(1, 1, 1)
        box:SetAutoFocus(false)
        box:SetScript("OnEscapePressed", function() popup:Hide() end)
        box:SetScript("OnEditFocusGained", function(owner) owner:HighlightText() end)
        box:SetScript("OnMouseUp", function(owner) popup.pinned = true; owner:SetFocus(); owner:HighlightText() end)
        box:SetScript("OnTextChanged", function(owner, userInput)
            if userInput and owner.copyText then owner:SetText(owner.copyText); owner:HighlightText() end
        end)
        addresses[#addresses+1] = box
        popup.fontRegions[#popup.fontRegions+1] = box
        return box
    end
    local address = addAddress(popup.description)
    popup.address = address
    local lastAddress = address
    local extraDescriptions = {}
    for _,link in ipairs(extraLinks or {}) do
        local label = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("TOPLEFT", lastAddress, "BOTTOMLEFT", -4, -10)
        label:SetFont(popupFont, popupFontSize, popupFontFlags)
        label:SetWidth(396)
        label:SetJustifyH("LEFT")
        label:SetJustifyV("TOP")
        label:SetWordWrap(true)
        label:SetTextColor(1, 1, 1)
        label:SetText(link.description)
        extraDescriptions[#extraDescriptions+1] = label
        popup.fontRegions[#popup.fontRegions+1] = label
        lastAddress = addAddress(label)
        lastAddress.copyText = link.url
        lastAddress:SetText(link.url)
    end
    popup.hint:SetPoint("TOPLEFT", lastAddress, "BOTTOMLEFT", -4, -8)
    if extraLinks then
        popup.hint:SetTextColor(.62,.82,1)
        popup.hint:SetWidth(396)
        popup.hint:SetJustifyH("LEFT")
        popup.hint:SetWordWrap(true)
    end
    local close = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)
    close:SetSize(24, 24)
    M.Widgets.StyleButton(close)
    close:SetScript("OnClick", function() popup:Hide() end)
    popup:SetScript("OnHide", function()
        if keyboardEnabled then
            M.Widgets.SetEditorKeyboard(popup, false)
            keyboardEnabled = false
        end
        for _,box in ipairs(addresses) do box:ClearFocus() end
        if popup.owner then setHighlight(popup.owner, false) end
        popup.owner, popup.copyText, popup.pinned = nil, nil, nil
    end)

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
            if M.Compat.MouseOver(popup) or (popup.owner and M.Compat.MouseOver(popup.owner)) then return end
            popup:Hide()
        end)
    end
    popup:SetScript("OnEnter", cancelHide)
    popup:SetScript("OnLeave", scheduleHide)
    for _,box in ipairs(addresses) do
        box:SetScript("OnEnter", cancelHide)
        box:SetScript("OnLeave", scheduleHide)
    end

    local function layoutPopup()
        -- Clear the last entry's height before measuring; otherwise a short
        -- tooltip can constrain a later long Chinese description to one line.
        popup.description:SetHeight(0)
        local descriptionHeight = math.max(popupFontSize, math.ceil(popup.description:GetStringHeight())) + 2
        popup.description:SetHeight(descriptionHeight)
        local copyHeight = popup.copyText and (10 + 23 + 8 + math.ceil(popup.hint:GetStringHeight())) or 0
        for _,label in ipairs(extraDescriptions) do
            label:SetHeight(0)
            local height = math.max(popupFontSize, math.ceil(label:GetStringHeight())) + 2
            label:SetHeight(height)
            copyHeight = copyHeight + 10 + height + 10 + 23
        end
        popup:SetHeight(12 + math.ceil(popup.title:GetStringHeight()) + 8 + descriptionHeight + copyHeight + 12)
    end

    local function showPopup(owner, focus)
        cancelHide()
        GameTooltip:Hide()
        local sameOwner = popup.owner == owner
        if popup.owner and not sameOwner then setHighlight(popup.owner, false) end
        popup.owner = owner
        popup.pinned = (focus and (owner.entry.copyText or owner.entry.url) ~= nil) or (sameOwner and popup.pinned) or false
        local entry = owner.entry
        local traditional=M:EffectiveLanguage()=="zhTW"
        popup.title:SetText(extraLinks and (traditional and "KOOK 社群、抖音直播、發電捐助" or "KOOK社区、抖音直播、发电捐助") or text(entry.zh, entry.en))
        popup.description:SetHeight(0)
        popup.description:SetText(description(entry))
        popup.copyText = entry.copyText or entry.url
        address.copyText = popup.copyText
        address:SetShown(popup.copyText~=nil)
        popup.hint:SetShown(popup.copyText~=nil)
        if extraLinks then
            for index,link in ipairs(extraLinks) do
                extraDescriptions[index]:SetText(traditional and link.traditional or link.description)
            end
            popup.hint:SetText(traditional and "可在「聊天與功能按鈕」預覽中關閉此圖示" or "可在「聊天与功能按钮」预览中关闭此图标")
        else
            popup.hint:SetText(text("按 Ctrl+C 复制", "Press Ctrl+C to copy"))
        end
        layoutPopup()
        if not sameOwner then address:ClearFocus() end
        address:SetText(popup.copyText or "")
        if not keyboardEnabled and not InCombatLockdown() then
            keyboardEnabled = M.Widgets.SetEditorKeyboard(popup, true, true)
        end
        popup:Show()
        C_Timer.After(0, function()
            if popup:IsShown() and popup.owner == owner then layoutPopup() end
        end)
        setHighlight(owner, true)
        if focus and popup.copyText then
            address:SetFocus()
            address:HighlightText()
        end
    end

    return popup, showPopup, scheduleHide
end

local function refreshPopupFont(popup)
    for _,label in ipairs(popup.fontRegions) do
        local _,size,flags=label:GetFont()
        label:SetFont(M:InterfaceFontPath(),size,flags or "")
    end
end

function F.ChatCommunityArt(visual,ring,preview)
    local artPath="Interface\\AddOns\\MangUI\\Assets\\ChatButtons\\"
    ring:SetTexture(artPath.."CommunityHeartRing.tga")
    local heart=CreateFrame("Frame",nil,visual)
    heart:SetSize(heartSize,heartSize)
    heart:SetPoint("CENTER",visual,"CENTER")
    heart.icon=heart:CreateTexture(nil,"ARTWORK")
    heart.icon:SetPoint("CENTER",heart,"CENTER")
    heart.icon:SetSize(40.5,40.5)
    if not preview then SetupSupportHeart(heart,nil,60) end
    heart.icon:SetTexture(artPath.."CommunityHeart.tga")
    heart.icon:SetVertexColor(1,1,1)
    local mask=heart:CreateMaskTexture()
    mask:SetTexture(artPath.."CommunityHeartMask.tga","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
    mask:SetSize(82,82)
    mask:SetPoint("CENTER",heart,"CENTER")
    heart.icon:AddMaskTexture(mask)
    if heart.shine then
        heart.shine:SetTexture(artPath.."CommunityHeart.tga")
        heart.shine:SetVertexColor(1,1,1)
        heart.shine:AddMaskTexture(mask)
    end
    return heart
end

function F.AttachChatCommunity(button, heart)
    local popups,active={},nil
    local function open(owner,focus)
        local entry=chineseClient() and ENTRIES[1] or ENTRIES[2]
        owner.entry=entry
        local route=popups[entry.id]
        if not route then
            local extraLinks = entry.id == "kook" and communityLinks or nil
            local popup,showPopup,scheduleHide=createLinkPopup(button,function() end,extraLinks)
            popup:SetPoint("BOTTOMRIGHT",button,"TOPRIGHT",0,5)
            route={popup=popup,show=showPopup,leave=scheduleHide}
            popups[entry.id]=route
        end
        if active and active~=route then active.popup:Hide() end
        active=route
        refreshPopupFont(route.popup)
        route.show(owner,focus)
    end
    button:HookScript("OnEnter",function(owner) heart.shine:Show();open(owner,false) end)
    button:HookScript("OnLeave",function() heart.shine:Hide();if active then active.leave() end end)
    button:HookScript("OnHide",function() heart.shine:Hide();if active then active.popup:Hide() end end)
    button:SetScript("OnClick",function(owner,mouseButton)
        if mouseButton~="LeftButton" then return end
        heart.releaseSupportHearts()
        open(owner,true)
    end)
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
    bar.label:SetText(text("加入社区与作者互动", "Community & Support"))
    bar.label:SetTextColor(0.7, 0.75, 0.8)

    local popup, showPopup, scheduleHide = createLinkPopup(bar,highlight)
    popup:SetPoint("BOTTOMRIGHT",bar,"TOPRIGHT",0,5)
    bar.popup=popup

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
        local iconSize=entry.heart and heartSize or (entry.fullColor and 30*104/128 or 30)
        button.icon:SetSize(iconSize, iconSize)
        button.icon:SetPoint("CENTER")
        if entry.heart then
            SetupSupportHeart(button,window)
        elseif entry.fullColor then
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
        if entry.heart then button:RegisterForClicks("LeftButtonUp","RightButtonUp") end
        button:SetScript("OnClick", function(owner,mouseButton)
            if mouseButton=="RightButton" and owner.resetSupportTrim then
                owner.resetSupportTrim()
                return
            end
            if owner.releaseSupportHearts then owner.releaseSupportHearts() end
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
    bar.label:SetText(text("加入社区与作者互动", "Community & Support"))
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
    bar.label:SetFont(M:InterfaceFontPath(),M:ClientInterfaceFontSize(12),"")
    refreshPopupFont(bar.popup)
    GameTooltip:Hide()
end
