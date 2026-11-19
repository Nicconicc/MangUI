local _, M = ...
local A = {}
M.HealthAbsorbs = A
local WHITE = "Interface\\Buttons\\WHITE8X8"

function A.SyncPartyLayers(o)
    if o.spec.partyIndex == nil or not o.absorbBar then return end
    local shieldLevel = o.frame:GetFrameLevel()
    local fillLevel = math.max(0, shieldLevel - 1)
    for _, region in pairs({o.bar, o.clip, o.nativeClip, o.nativeArtFrame,
        o.partyHealPredictionLayer, o.partyHealPrediction}) do
        region:SetFrameLevel(fillLevel)
    end
    o.absorbBar:SetFrameLevel(shieldLevel)
    o.absorbClip:SetFrameLevel(shieldLevel)
    o.absorbArt:SetFrameLevel(shieldLevel)
end

function A.Configure(o)
    local n = o.spec
    local supported = n.binding == "health" and not n.vertical
        and (n.id == "wa4f9903a71c" or n.id == "wa385c615b2a" or n.partyIndex ~= nil)
    if not supported then
        if o.absorbBar then o.absorbBar:Hide() end
        return
    end
    if not o.absorbBar then
        local bar = CreateFrame("StatusBar", nil, o.frame)
        bar:EnableMouse(false)
        bar:SetStatusBarTexture(WHITE)
        bar:SetStatusBarColor(1, 1, 1, 0)
        local clip = CreateFrame("Frame", nil, bar)
        clip:EnableMouse(false)
        clip:SetClipsChildren(true)
        clip:SetAllPoints(bar:GetStatusBarTexture())
        local art = CreateFrame("Frame", nil, clip)
        art:EnableMouse(false)
        art:SetAllPoints(o.frame)
        local mask = art:CreateMaskTexture()
        mask:SetAllPoints(art)
        local fill = art:CreateTexture(nil, "ARTWORK")
        fill:SetAllPoints(art)
        fill:SetColorTexture(1, .78, .24, n.partyIndex ~= nil and .80 or .55)
        fill:AddMaskTexture(mask)
        local edge = art:CreateTexture(nil, "OVERLAY")
        edge:SetColorTexture(1, .91, .52, .95)
        edge:AddMaskTexture(mask)
        local lines = {}
        for i = 1, 2 do
            local line = art:CreateTexture(nil, "OVERLAY")
            line:SetColorTexture(1, .91, .52, .65)
            line:AddMaskTexture(mask)
            local shimmer = line:CreateAnimationGroup()
            local alpha = shimmer:CreateAnimation("Alpha")
            alpha:SetFromAlpha(.35)
            alpha:SetToAlpha(.85)
            alpha:SetDuration(1.8 + i * .3)
            shimmer:SetLooping("BOUNCE")
            shimmer:Play()
            lines[i] = line
        end
        o.absorbBar, o.absorbMask, o.absorbEdge = bar, mask, edge
        o.absorbClip, o.absorbArt = clip, art
        o.absorbLines = lines
    end
    if n.partyIndex ~= nil then
        A.SyncPartyLayers(o)
    else
        o.absorbBar:SetFrameLevel(math.max(o.bar:GetFrameLevel(), o.clip:GetFrameLevel()) + 2)
    end
    o.absorbBar:SetReverseFill(not n.reverse)
    o.absorbMask:SetTexture(n.file or WHITE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    M.RendererInternals.TextureCoords(o.absorbMask, n)
    o.absorbBar:Hide()
end

function A.Paint(view, o, s, inset, start, extent)
    local bar = o.absorbBar
    if not bar then return end
    local maximum = s.maxHealth
    local amount
    if view.preview then
        amount = maximum * .30
    elseif UnitGetTotalAbsorbs and s.exists and not s.dead and s.connected ~= false then
        local ok, value = pcall(UnitGetTotalAbsorbs, s.unit)
        if ok then amount = value end
    end
    local C = M.Compat
    if type(amount) ~= "number" or type(maximum) ~= "number"
        or (C.Readable(amount) and amount <= 0)
        or (C.Readable(maximum) and maximum <= 0) then
        bar:Hide()
        return
    end
    local n = o.spec
    local side = n.reverse and "LEFT" or "RIGHT"
    local shift = n.reverse and inset + n.width - extent or -inset - n.width + extent
    local props = M.RendererInternals
    props.CachedPoint(o, "absorbPoint", bar, side, o.frame, side, shift, 0)
    props.CachedPair(o, "absorbSize", bar, "SetSize", math.max(.001, extent - start), n.height)
    -- Native range/value handling also accepts protected combat values without
    -- dividing, comparing or converting them in addon code.
    props.CachedPair(o, "absorbRange", bar, "SetMinMaxValues", 0, maximum)
    props.CachedValue(o, "absorbValue", bar, "SetValue", amount)
    local texture = bar:GetStatusBarTexture()
    local inner = n.reverse and "RIGHT" or "LEFT"
    o.absorbEdge:ClearAllPoints()
    o.absorbEdge:SetPoint("TOP", texture, "TOP"..inner)
    o.absorbEdge:SetPoint("BOTTOM", texture, "BOTTOM"..inner)
    o.absorbEdge:SetWidth(1)
    for i, line in ipairs(o.absorbLines) do
        line:ClearAllPoints()
        local y = (i == 1 and .25 or -.25) * n.height
        line:SetPoint("LEFT", bar, "LEFT", 0, y)
        line:SetPoint("RIGHT", bar, "RIGHT", 0, y)
        line:SetHeight(.65)
    end
    bar:Show()
end
