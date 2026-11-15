local _, M = ...
local S = M.PlayerSkillMonitor

local buttonText = "从暴雪冷却管理器添加"
local spellbookText = "从法术书添加技能"
local unavailableText = "暂时无法读取暴雪冷却设置，请打开暴雪冷却管理器后重试。"
local emptyText = "暴雪冷却管理器没有可添加的技能冷却。"
local spellbookEmptyText = "法术书没有可添加的主动技能。"

local function SpellID(value)
    if M.Compat.Readable(value) and type(value) == "number" and value > 0 then
        return value
    end
end

local function BaseSpell(id)
    if C_Spell.GetBaseSpell then return SpellID(C_Spell.GetBaseSpell(id)) or id end
    return id
end

local function ExistingCooldowns(group)
    local existing = {}
    for _, entry in ipairs(group.monitors) do
        if entry.type == "cooldown" and entry.value ~= "" then
            local id = tonumber(entry.value)
            if not id then
                local _, resolved = M.PetBuffs.SpellInfo(entry.value)
                id = SpellID(resolved)
            end
            if SpellID(id) then existing[BaseSpell(id)] = true end
        end
    end
    return existing
end

local function ReadCandidates(group)
    local settings = CooldownViewerSettings
    local manager = settings and settings.GetLayoutManager and settings:GetLayoutManager()
    if not manager or not manager:IsLoaded() then return nil end
    local layout = manager:GetActiveLayout(Enum.CDMLayoutMode.AccessOnly)
    local overrides, orderedIDs
    if layout then
        local tag = CooldownViewerUtil.GetCurrentClassAndSpecTag()
        if not tag or CooldownManagerLayout_GetClassAndSpecTag(layout) ~= tag then return nil end
        overrides = CooldownManagerLayout_GetCooldownInfo(layout, false)
        orderedIDs = CooldownManagerLayout_GetOrderedCooldownIDs(layout)
    end

    local category = Enum.CooldownViewerCategory
    local existing = ExistingCooldowns(group)
    local byID, defaultOrder = {}, {}
    for _, source in ipairs({category.Essential, category.Utility, category.TrackedBuff, category.TrackedBar,
        category.EquipSlotEssential, category.EquipSlotTracked, category.SpecAgnosticEssential, category.SpecAgnosticTracked}) do
        for _, cooldownID in ipairs(C_CooldownViewer.GetCooldownViewerCategorySet(source, true)) do
            local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
            local override = overrides and overrides[cooldownID]
            local activeCategory = override and tonumber(override.category)
            if not activeCategory and info and not FlagsUtil.IsSet(info.flags, Enum.CooldownSetSpellFlags.HideByDefault) then
                activeCategory = info.category
            end
            if info and info.isKnown and not (CDM_HIDE_INVISIBLE_ITEMS and info.isInvisible) and not info.equipSlot and not info.buffSlot
                and (activeCategory == category.Essential or activeCategory == category.Utility) then
                local id = SpellID(info.overrideSpellID) or SpellID(info.spellID)
                local baseID = id and BaseSpell(SpellID(info.spellID) or id)
                if baseID and not existing[baseID] and not existing[BaseSpell(id)] then
                    local name, _, icon = M.PetBuffs.SpellInfo(id)
                    if name then
                        if not byID[cooldownID] then defaultOrder[#defaultOrder + 1] = cooldownID end
                        byID[cooldownID] = {id = id, baseID = baseID, name = name, icon = icon, category = activeCategory,
                            heading = activeCategory == category.Essential and "主要技能冷却" or "功能技能冷却"}
                    end
                end
            end
        end
    end

    local candidates, added = {}, {}
    for _, target in ipairs({category.Essential, category.Utility}) do
        for _, order in ipairs({orderedIDs or defaultOrder, defaultOrder}) do
            for _, cooldownID in ipairs(order) do
                local entry = byID[cooldownID]
                if entry and entry.category == target and not added[entry.baseID] then
                    added[entry.baseID] = true
                    candidates[#candidates + 1] = entry
                end
            end
        end
    end
    return candidates
end

local function CanReadSpellbook()
    return C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo
        and C_SpellBook.GetSpellBookItemInfo
end

local function ReadSpellbook(group)
    local book, bank = C_SpellBook, Enum.SpellBookSpellBank.Player
    local existing, candidates = ExistingCooldowns(group), {}
    for line = 1, book.GetNumSpellBookSkillLines() do
        local info = book.GetSpellBookSkillLineInfo(line)
        if info and not info.shouldHide and not info.isGuild and not info.offSpecID then
            for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                local item = book.GetSpellBookItemInfo(slot, bank)
                if item and item.itemType == Enum.SpellBookItemType.Spell and not item.isPassive and not item.isOffSpec
                    and (not book.IsSpellBookItemLowRank or not book.IsSpellBookItemLowRank(slot, bank)) then
                    local id = SpellID(item.spellID) or SpellID(item.actionID)
                    local baseID = id and BaseSpell(SpellID(item.actionID) or id)
                    if baseID and not existing[baseID] and not existing[BaseSpell(id)] and M.Compat.Readable(item.name)
                        and type(item.name) == "string" and item.name ~= "" then
                        existing[baseID] = true
                        candidates[#candidates + 1] = {id = id, name = item.name, icon = item.iconID}
                    end
                end
            end
        end
    end
    return candidates
end

local function CreatePicker(window, onApply, onSpellbook)
    local W = M.Widgets
    local overlay = CreateFrame("Frame", nil, window)
    overlay:SetAllPoints(window)
    overlay:SetFrameStrata("FULLSCREEN_DIALOG")
    overlay:SetFrameLevel(9500)
    overlay:EnableMouse(true)
    overlay:EnableMouseWheel(true)
    local dim = overlay:CreateTexture(nil, "BACKGROUND")
    dim:SetAllPoints()
    dim:SetColorTexture(0, 0, 0, .55)
    overlay:Hide()

    local dialog = W.Panel(overlay)
    dialog:SetSize(440, 364)
    dialog:SetPoint("CENTER")
    local title = W.Label(dialog, buttonText, 15)
    title:SetPoint("TOPLEFT", 18, -15)
    title:SetPoint("RIGHT", dialog, "RIGHT", -18, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(1, .82, .2)

    local message = W.Label(dialog, "", 12)
    message:SetPoint("TOPLEFT", 18, -54)
    message:SetPoint("RIGHT", dialog, "RIGHT", -18, 0)
    message:SetJustifyH("LEFT")
    message:SetWordWrap(true)
    local scroll, content = W.Scroll(dialog)
    scroll:SetPoint("TOPLEFT", 18, -50)
    scroll:SetPoint("BOTTOMRIGHT", -38, 54)
    scroll:SetClipsChildren(true)
    content:SetWidth(384)

    local rows, checked = {}, {}
    local cancel = W.Button(dialog, "取消", 104, function() overlay:Hide() end)
    cancel:SetPoint("BOTTOMRIGHT", -18, 15)
    local apply = W.Button(dialog, "添加选中技能", 176, function() onApply(checked) end)
    apply:SetPoint("RIGHT", cancel, "LEFT", -8, 0)
    local spellbook = W.Button(dialog, spellbookText, 224, onSpellbook)
    spellbook:SetPoint("TOPLEFT", 18, -104)

    function overlay:ShowCandidates(candidates, fromSpellbook)
        wipe(checked)
        apply:Disable()
        title:SetText(fromSpellbook and spellbookText or buttonText)
        local previousHeading, y = nil, 0
        for i, entry in ipairs(candidates or {}) do
            local row = rows[i]
            if not row then
                row = CreateFrame("Frame", nil, content)
                row:SetWidth(384)
                row.heading = W.Label(row, "", 12)
                row.heading:SetPoint("TOPLEFT", 0, -1)
                row.heading:SetTextColor(1, .82, .2)
                row.check = W.Check(row, "", function(selected)
                    checked[row.entry.id] = selected and true or nil
                    apply:SetEnabled(next(checked) ~= nil)
                end)
                row.check:SetPoint("BOTTOMLEFT", 0, 2)
                row.check.label:Hide()
                local body = CreateFrame("Button", nil, row)
                body:SetPoint("LEFT", row.check, "RIGHT", 6, 0)
                body:SetPoint("RIGHT", row, "RIGHT", 0, 0)
                body:SetHeight(26)
                body:SetScript("OnClick", function() row.check:Click() end)
                row.icon = body:CreateTexture(nil, "ARTWORK")
                row.icon:SetSize(22, 22)
                row.icon:SetPoint("LEFT")
                row.name = body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
                row.name:SetPoint("RIGHT", -4, 0)
                row.name:SetJustifyH("LEFT")
                row.name:SetWordWrap(false)
                rows[i] = row
            end
            local newHeading = entry.heading ~= nil and entry.heading ~= previousHeading
            row.heading:SetShown(newHeading)
            if newHeading then row.heading:SetText(entry.heading) end
            row.entry = entry
            row.check:SetChecked(false)
            row.icon:SetTexture(entry.icon or 134400)
            row.name:SetText(entry.name)
            row:SetHeight(newHeading and 52 or 30)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -y)
            row:Show()
            y = y + row:GetHeight()
            previousHeading = entry.heading
        end
        for i = #(candidates or {}) + 1, #rows do rows[i]:Hide() end
        message:SetText(fromSpellbook and spellbookEmptyText or (candidates and emptyText or unavailableText))
        message:SetShown(y == 0)
        spellbook:SetShown(y == 0 and not fromSpellbook and not not CanReadSpellbook())
        content:SetHeight(math.max(2, y))
        scroll:SetShown(y > 0)
        scroll:SetVerticalScroll(0)
        self:Show()
    end
    return overlay
end

function S.AddBlizzardCooldownButton(panel, window, current, flush)
    if M.Compat.interface ~= 16001 or not (C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCategorySet
        and C_CooldownViewer.GetCooldownViewerCooldownInfo) then return end
    local picker, owner, profile, openedEntries, fromSpellbook
    local function CanContinue()
        if current() ~= owner or S.CurrentProfile() ~= profile or owner.monitors ~= openedEntries
            or not S.IsProfileBound(owner.id) then
            picker:Hide()
            return false
        end
        return M:CanEdit()
    end
    local function Candidates()
        local ok, candidates = pcall(fromSpellbook and ReadSpellbook or ReadCandidates, owner)
        if ok then return candidates end
    end
    local button = M.Widgets.Button(panel, buttonText, 248, function()
        local group = current()
        if not group or not M:CanEdit() or not S.IsProfileBound(group.id) then return end
        flush()
        owner, profile, openedEntries = group, S.CurrentProfile(), group.monitors
        fromSpellbook = false
        if not picker then
            picker = CreatePicker(window, function(checked)
                if not CanContinue() then return end
                local candidates = Candidates()
                if not candidates then
                    picker:ShowCandidates(nil, fromSpellbook)
                    return
                end
                local count = #owner.monitors
                for _, candidate in ipairs(candidates) do
                    if checked[candidate.id] then
                        local entry = S.NewEntry()
                        entry.value = tostring(candidate.id)
                        owner.monitors[#owner.monitors + 1] = entry
                    end
                end
                picker:Hide()
                if #owner.monitors > count then
                    M:Commit()
                end
            end, function()
                if not CanContinue() then return end
                fromSpellbook = true
                picker:ShowCandidates(Candidates(), fromSpellbook)
            end)
        end
        picker:ShowCandidates(Candidates(), fromSpellbook)
    end)
    button:SetPoint("LEFT", panel.add, "RIGHT", 8, 0)
    button:SetHoverTextColor(1, .82, 0)
    panel:HookScript("OnHide", function() if picker then picker:Hide() end end)
end
