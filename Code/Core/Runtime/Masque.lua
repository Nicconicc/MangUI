local _, M = ...
local K = {}
M.MasqueIcons = K

local labels = {
    playerSkillMonitor = "职业技能监控",
    playerOtherMonitor = "玩家其他监控",
    cooldownMonitor = "玩家技能冷却监控",
    commonItems = "常用物品监控",
    raidBuffs = "玩家常驻团队增益监控",
    receivedBuffs = "玩家获取他人增益监控",
    raidVulnerability = "团队易伤监控",
    partyAuras = "队伍光环",
    targetAuras = "目标光环",
    petAuras = "宠物增益",
    castIcons = "施法图标",
}
local groups, entries, pending = {}, {}, {}
local masque, watcher

local function SyncOverlay(entry)
    local overlay = entry.overlay
    if not overlay then return end
    local icon = entry.icon
    overlay:ClearAllPoints()
    overlay:SetAllPoints(icon)
    overlay:SetTexCoord(icon:GetTexCoord())
    local mask
    if icon.GetMaskTexture and (not icon.GetNumMaskTextures or icon:GetNumMaskTextures() > 0) then
        mask = icon:GetMaskTexture(1)
    end
    if mask == entry.overlayMask then return end
    if entry.overlayMask then overlay:RemoveMaskTexture(entry.overlayMask) end
    if mask then overlay:AddMaskTexture(mask) end
    entry.overlayMask = mask
end

local function Group(key)
    if groups[key] then return groups[key] end
    local group = masque:Group("MangUI", M:T(labels[key]), "MangUI:" .. key)
    groups[key] = group
    return group
end

local function Apply(entry)
    local icon = entry.icon
    if icon.IsForbidden and icon:IsForbidden() then return end
    local parent = icon:GetParent()
    if parent.IsForbidden and parent:IsForbidden() then return end
    local frame = entry.frame
    if not frame then
        -- Masque only owns a passive visual frame, including for secure items and native auras.
        frame = CreateFrame("Frame", nil, parent)
        frame:EnableMouse(false)
        frame:SetSize(entry.width, entry.height)
        frame:SetPoint("CENTER", parent, "CENTER")
        local normal = frame:CreateTexture(nil, "ARTWORK")
        normal:Hide()
        entry.frame, entry.normal = frame, normal
        entry.group = Group(entry.key)
        if entry.overlay then
            local function UpdateOverlay() SyncOverlay(entry) end
            hooksecurefunc(icon, "SetTexCoord", UpdateOverlay)
            hooksecurefunc(icon, "AddMaskTexture", UpdateOverlay)
            hooksecurefunc(icon, "RemoveMaskTexture", UpdateOverlay)
        end
        entry.group:AddButton(frame, {Icon = icon, Normal = normal, Cooldown = entry.cooldown}, "Aura", true)
        SyncOverlay(entry)
    else
        if frame:GetParent() ~= parent then
            frame:SetParent(parent)
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", parent, "CENTER")
        end
        if entry.width ~= entry.appliedWidth or entry.height ~= entry.appliedHeight then
            frame:SetSize(entry.width, entry.height)
            if entry.group.SetFrameSize then
                entry.group:SetFrameSize(entry.width, entry.height, frame, true)
            else entry.group:ReSkin(frame) end
        elseif entry.refresh then
            entry.group:ReSkin(frame)
        end
        SyncOverlay(entry)
    end
    entry.appliedWidth, entry.appliedHeight = entry.width, entry.height
    entry.refresh = nil
end

local function TryApply(entry)
    local ok, err = pcall(Apply, entry)
    if ok then return end
    entry.failed = true
    if entry.frame then
        if entry.group then pcall(entry.group.RemoveButton, entry.group, entry.frame) end
        entry.frame:Hide()
    end
    M:Report("Masque 图标", err)
end

local function Queue(entry)
    if entry.failed then return end
    if not InCombatLockdown() then TryApply(entry);return end
    pending[entry] = true
    if watcher then return end
    watcher = CreateFrame("Frame")
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:SetScript("OnEvent", function()
        for queued in pairs(pending) do
            pending[queued] = nil
            TryApply(queued)
        end
    end)
end

function K.Attach(icon, key, width, height, cooldown, overlay, refresh)
    if not masque then
        masque = LibStub and LibStub("Masque", true)
        if not masque then return end
        -- Masque uses the add-on's named skin when its group is disabled.
        masque:AddSkin("MangUI", {
            Disable = true,
            Icon = {SetAllPoints = true},
            Normal = {Hide = true},
            Cooldown = {SetAllPoints = true},
        })
    end
    local entry = entries[icon]
    if not entry then
        entry = {icon = icon, key = key, cooldown = cooldown, overlay = overlay}
        entries[icon] = entry
    elseif not refresh and entry.width == width and entry.height == height and entry.frame then return end
    entry.width, entry.height = width, height
    entry.refresh = refresh
    Queue(entry)
end

function K.Reparent(icon, parent)
    icon:SetParent(parent)
    local entry = entries[icon]
    if entry and entry.frame and entry.frame:GetParent() ~= parent then Queue(entry) end
end

function K.GlowBorder(icon)
    local entry = entries[icon]
    if not entry or entry.failed or not entry.normal then return end
    local now = GetTime()
    if now < (entry.borderRefresh or 0) then return entry.glowBorder end
    entry.borderRefresh = now + .25
    local ok, texture, atlas, width, height, coords = pcall(function()
        -- Masque can replace the supplied Normal region when a skin has no
        -- button states. That replacement is the border actually on screen.
        local config = entry.frame._MSQ_CFG
        local normal = (config and config.Normal)
            or (entry.group.GetLayer and entry.group:GetLayer(entry.frame,"Normal"))
            or entry.normal
        if not normal:IsShown() then return end
        local texture, atlas = normal:GetTexture(), normal.GetAtlas and normal:GetAtlas()
        local width, height = normal:GetWidth(), normal:GetHeight()
        local coords = {normal:GetTexCoord()}
        if (texture or atlas) and width > 0 and height > 0 and #coords >= 4 then
            return texture, atlas, width, height, coords
        end
    end)
    if ok and width then
        local old = entry.glowBorder
        if old and old.texture==texture and old.atlas==atlas and old.width==width and old.height==height
            and table.concat(old.coords,",")==table.concat(coords,",") then return old end
        entry.glowBorder = {texture=texture,atlas=atlas,width=width,height=height,coords=coords}
    else
        entry.glowBorder = nil
    end
    return entry.glowBorder
end

function K.AuraKey(spec)
    if spec.partyIndex ~= nil then return "partyAuras" end
    return spec.unit == "pet" and "petAuras" or "targetAuras"
end
