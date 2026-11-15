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

local function EssentialEntries(group, order, readInfo, overrides, defaultLayout)
    local essential = Enum.CooldownViewerCategory.Essential
    local existing = ExistingCooldowns(group)
    local entries, total = {}, 0
    for _, cooldownID in ipairs(order) do
        local info = readInfo(cooldownID)
        local override=overrides and overrides[cooldownID]
        local category=override and tonumber(override.category)
        local hiddenByDefault = defaultLayout and not category and info and info.flags and FlagsUtil and Enum.CooldownSetSpellFlags
            and FlagsUtil.IsSet(info.flags, Enum.CooldownSetSpellFlags.HideByDefault)
        if info and (category or info.category) == essential and info.isKnown == true
            and not hiddenByDefault and not (CDM_HIDE_INVISIBLE_ITEMS and info.isInvisible) then
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

local function ReadEssentialCooldowns()
    local display = ReadDisplayData()
    local empty={monitors={}}
    if display and display.orderedCooldownIDs and #display.orderedCooldownIDs>0
        and type(display.cooldownInfoByID)=="table" and next(display.cooldownInfoByID)then
        return EssentialEntries(empty, display.orderedCooldownIDs, function(id) return display.cooldownInfoByID[id] end)
    end
    local api = C_CooldownViewer
    if not api or not api.GetCooldownViewerCategorySet or not api.GetCooldownViewerCooldownInfo then return end
    local settings=CooldownViewerSettings
    local manager=settings and settings.GetLayoutManager and settings:GetLayoutManager()
    local provider=settings and settings.GetDataProvider and settings:GetDataProvider()
    if not manager or not manager:IsLoaded() or (provider and provider.IsLayoutUpdateQueued and provider:IsLayoutUpdateQueued())then return end
    local layout=manager:GetActiveLayout(false)
    local overrides, savedOrder
    if layout then
        if CooldownManagerLayout_GetClassAndSpecTag(layout)~=CooldownViewerUtil.GetCurrentClassAndSpecTag()then return end
        overrides=CooldownManagerLayout_GetCooldownInfo(layout,false)
        savedOrder=CooldownManagerLayout_GetOrderedCooldownIDs(layout)
    end
    local category=Enum.CooldownViewerCategory
    local order,added={},{}
    local function Add(ids)
        for _,id in ipairs(ids or {})do
            if not added[id]then order[#order+1]=id;added[id]=true end
        end
    end
    local essential=api.GetCooldownViewerCategorySet(category.Essential,true)
    if not essential then return end
    Add(savedOrder)
    Add(essential)
    for _,key in ipairs({"Utility","TrackedBuff","TrackedBar","EquipSlotEssential","EquipSlotTracked","SpecAgnosticEssential","SpecAgnosticTracked"})do
        if category[key]~=nil then Add(api.GetCooldownViewerCategorySet(category[key],true))end
    end
    local infoByID={}
    for _,id in ipairs(order)do infoByID[id]=api.GetCooldownViewerCooldownInfo(id)end
    if next(infoByID)then return EssentialEntries(empty,order,function(id)return infoByID[id]end,overrides,true)end
end

S.ReadBlizzardCooldowns=ReadEssentialCooldowns

function S.SyncBlizzardCooldowns(group,desired)
    desired=desired or ReadEssentialCooldowns()
    if not desired then return end
    local expected, kept={},{}
    for _,entry in ipairs(desired)do expected[entry.blizzardCooldownID]=entry end
    local changed=false
    for _,entry in ipairs(group.monitors)do
        if entry.type=="blizzard" and entry.blizzardCooldownID and not expected[entry.blizzardCooldownID] then
            changed=true
        else kept[#kept+1]=entry end
    end
    local existing=ExistingCooldowns({monitors=kept})
    local byCooldown={}
    for _,entry in ipairs(kept)do
        if entry.type=="blizzard" and entry.blizzardCooldownID then byCooldown[entry.blizzardCooldownID]=true end
    end
    local placeholder=kept[1]
    if #kept==1 and placeholder.type=="cooldown" and placeholder.value=="" and (placeholder.shortcut or "")==""
        and not placeholder.reverseDisplay and #desired>0 then kept={} end
    for _,entry in ipairs(desired)do
        if not byCooldown[entry.blizzardCooldownID] and not existing[BaseSpell(tonumber(entry.value))]then
            kept[#kept+1]=entry;changed=true
        end
    end
    if changed then group.monitors=kept;M:Commit()end
    return true,changed
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

function S.OpenBlizzardCooldownSettings()
    if M.Compat.interface ~= 16001 or InCombatLockdown() then return end
    local settings = CooldownViewerSettings
    if not settings or settings:IsShown() then return end
    local manager = settings:GetLayoutManager()
    if manager and manager:IsLoaded() then ShowUIPanel(settings) end
end

function S.AddBlizzardCooldownButton(panel, current, flush)
    if M.Compat.interface ~= 16001 then return end
    local W=M.Widgets
    local check=W.Check(panel,"自动同步",function(enabled) S.SetBlizzardSyncEnabled(enabled)end)
    local button = W.Button(panel, "从暴雪冷却管理器中导入", 230, function()
        local group = current()
        if not group or not M:CanEdit() or not S.IsProfileBound(group.id) then return end
        flush()
        if current() ~= group or not S.IsProfileBound(group.id) then return end

        local ok, ready = pcall(S.SyncBlizzardCooldowns, group)
        if not ok or not ready then
            M:Print("暂时无法读取暴雪冷却设置，请打开暴雪冷却管理器后重试。")
            return
        end
        M:Print("暴雪冷却监控已同步。")
    end)
    button:SetPoint("TOPLEFT",panel,"TOPLEFT",0,0)
    check:SetPoint("LEFT",button,"RIGHT",12,0)
    button:SetHoverTextColor(1, .82, 0)
    panel.blizzardSyncCheck=check
    return button
end
