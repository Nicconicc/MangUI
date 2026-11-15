local _, M = ...
local S = M.PlayerSkillMonitor

local function SpellID(value)
    if M.Compat.Readable(value) and type(value) == "number" and value > 0 and value % 1 == 0 then
        return value
    end
end

local function BaseSpell(id)
    local getBase = C_Spell and C_Spell.GetBaseSpell
    if getBase then return SpellID(getBase(id)) or id end
    return id
end

local function ExistingCooldowns(group)
    local existing = {}
    for _, entry in ipairs(group.monitors) do
        if (entry.type == "cooldown" or entry.type == "blizzard") and entry.value ~= "" then
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

local function ReadDisplayData()
    local settings = CooldownViewerSettings
    local provider = settings and settings.GetDataProvider and settings:GetDataProvider()
    if not provider or not provider.GetDisplayData
        or (provider.IsDirty and provider:IsDirty())
        or (provider.IsLayoutUpdateQueued and provider:IsLayoutUpdateQueued()) then return end
    -- Read only. The provider's ordered-list methods can rebuild the layout and notify the protected HUD.
    return provider:GetDisplayData()
end

local function ReadEssentialCooldowns(group)
    local display = ReadDisplayData()
    if not display or not display.orderedCooldownIDs or not display.cooldownInfoByID then return end
    local essential = Enum.CooldownViewerCategory.Essential

    local existing = ExistingCooldowns(group)
    local entries, total = {}, 0
    for _, cooldownID in ipairs(display.orderedCooldownIDs) do
        local info = display.cooldownInfoByID[cooldownID]
        if info and info.category == essential and info.isKnown == true
            and not (CDM_HIDE_INVISIBLE_ITEMS and info.isInvisible) then
            local base = SpellID(info.spellID)
            local id = SpellID(info.overrideSpellID) or base
            if id then
                total = total + 1
                local baseID, resolvedID = BaseSpell(base or id), BaseSpell(id)
                if not existing[baseID] and not existing[resolvedID] then
                    existing[baseID], existing[resolvedID] = true, true
                    local entry = S.NewEntry()
                    entry.type, entry.value, entry.blizzardCooldownID = "blizzard", tostring(base or id), cooldownID
                    entries[#entries + 1] = entry
                end
            end
        end
    end
    return entries, total
end

function S.GetBlizzardCooldownInfo(entry, id)
    if M.Compat.interface ~= 16001 or not id then return end
    local base = BaseSpell(id)
    if entry.blizzardCooldownID and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo then
        local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(entry.blizzardCooldownID)
        if info and (info.spellID == id or info.spellID == base or info.overrideSpellID == id) then return info end
    end
    local display = ReadDisplayData()
    local byID = display and display.cooldownInfoByID
    for _, cooldownID in ipairs(display and display.orderedCooldownIDs or {}) do
        local info = byID and byID[cooldownID]
        if info and (info.spellID == id or info.spellID == base or info.overrideSpellID == id) then
            if C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo then
                return C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID) or info
            end
            return info
        end
    end
    -- A manually configured entry has no cooldown ID until it can be matched.
    -- The client API also works when the official layout has not been built.
    local api = C_CooldownViewer
    if api and api.GetCooldownViewerCategorySet and api.GetCooldownViewerCooldownInfo then
        for _, category in ipairs({Enum.CooldownViewerCategory.Essential, Enum.CooldownViewerCategory.Utility}) do
            for _, cooldownID in ipairs(api.GetCooldownViewerCategorySet(category, false) or {}) do
                local info = api.GetCooldownViewerCooldownInfo(cooldownID)
                if info and (info.spellID == id or info.spellID == base or info.overrideSpellID == id) then return info end
            end
        end
    end
end

function S.AddBlizzardCooldownButton(panel, current, flush)
    if M.Compat.interface ~= 16001 then return end
    local button = M.Widgets.Button(panel, "从暴雪冷却管理器添加", 248, function()
        local group = current()
        if not group or not M:CanEdit() or not S.IsProfileBound(group.id) then return end
        flush()
        if current() ~= group or not S.IsProfileBound(group.id) then return end

        local ok, entries, total = pcall(ReadEssentialCooldowns, group)
        if not ok or not entries then
            M:Print("暂时无法读取暴雪冷却设置，请打开暴雪冷却管理器后重试。")
            return
        end
        if total == 0 then
            M:Print("暴雪主要技能冷却列表为空。")
            return
        end
        if #entries == 0 then
            M:Print("暴雪主要技能冷却已全部添加。")
            return
        end
        for _, entry in ipairs(entries) do
            group.monitors[#group.monitors + 1] = entry
        end
        M:Commit()
        M:Print(string.format(M:T("已从暴雪主要技能冷却添加 %d 项。"), #entries))
    end)
    button:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    button:SetHoverTextColor(1, .82, 0)
    return button
end
