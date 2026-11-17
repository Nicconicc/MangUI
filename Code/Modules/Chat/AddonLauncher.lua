local _,M=...
local B=M.ChatButtons
local icons=[[Interface\Icons\]]
local addons={
    {name="Bartender4",command="/bt4",handler="ACECONSOLE_BT4",icon=icons.."INV_Drink_05",
        description="调整动作条布局、可见性和快捷键。"},
    {name="Platynator",command="/platy",handler="Platynator",icon=icons.."Ability_Warrior_Challenge",
        description="自定义姓名板样式、文字和光环。"},
    {name="NiceDamage",command="/nd",handler="ACECONSOLE_ND",icon=icons.."INV_Knife_1H_Rogue_C_01",
        description="替换跳出的伤害与治疗数字字体。"},
    {name="Baganator",command="/baganator",handler="Baganator",icon=icons.."INV_Misc_Bag_10",
        description="整理、分类和搜索背包与银行物品。"},
    {name="DynamicCam",command="/dc",handler="ACECONSOLE_DC",icon=icons.."INV_Misc_Spyglass_03",
        description="按游戏情境调整镜头缩放和视角。"},
}
local function AddOnAPI(name)
    return (C_AddOns and C_AddOns[name]) or _G[name]
end

local function State(addon)
    local getInfo,isLoaded=AddOnAPI("GetAddOnInfo"),AddOnAPI("IsAddOnLoaded")
    local installed=getInfo and getInfo(addon.name)
    if not installed then return "未安装" end
    if not (isLoaded and isLoaded(addon.name)) then return "未加载" end
    local handler=SlashCmdList and SlashCmdList[addon.handler]
    if type(handler)~="function" and hash_SlashCmdList then
        handler=hash_SlashCmdList[addon.command:upper()]
    end
    if type(handler)=="function" then return "打开设置",handler end
    return "无设置入口"
end

local function Icon(addon)
    local getMetadata=AddOnAPI("GetAddOnMetadata")
    local icon=getMetadata and getMetadata(addon.name,"IconTexture")
    if type(icon)=="string" and icon~="" then
        icon=icon:gsub("%s*%[AllowLoadGameType[^%]]*%]%s*$","")
        if icon~="" then return tonumber(icon) or icon end
    end
    return addon.icon
end

local function OpenSettings(panel,addon)
    if InCombatLockdown() then M:Print("脱战后才能打开插件设置。");return end
    local _,handler=State(addon)
    if not handler then return end
    if M:Safe("打开设置",handler,"") then panel:Hide() end
end

local function CreatePanel(anchor)
    local W=M.Widgets
    local panel=W.Panel(anchor)
    panel:SetSize(440,52+#addons*53)
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:Hide()
    local title=W.Label(panel,"插件入口",16)
    title:SetPoint("TOPLEFT",17,-14)
    title:SetTextColor(1,.82,.38)
    local close=CreateFrame("Button",nil,panel,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",-3,-3)
    close:SetScript("OnClick",function()panel:Hide()end)

    local line=panel:CreateTexture(nil,"ARTWORK")
    line:SetPoint("TOPLEFT",14,-40);line:SetPoint("TOPRIGHT",-14,-40)
    line:SetHeight(1);line:SetColorTexture(.72,.56,.25,.5)
    panel.rows={}
    for i,addon in ipairs(addons) do
        local row=CreateFrame("Frame",nil,panel)
        row:SetPoint("TOPLEFT",13,-46-(i-1)*53)
        row:SetPoint("TOPRIGHT",-13,-46-(i-1)*53);row:SetHeight(48)
        local backdrop=row:CreateTexture(nil,"BACKGROUND")
        backdrop:SetAllPoints();backdrop:SetColorTexture(.25,.33,.43,i%2==0 and .23 or .13)
        local logo=row:CreateTexture(nil,"ARTWORK")
        logo:SetSize(34,34);logo:SetPoint("LEFT",8,0)
        local name=W.Label(row,addon.name,14)
        name:SetPoint("TOPLEFT",51,-6);name:SetTextColor(.96,.88,.68)
        local description=W.Label(row,addon.description,11)
        description:SetPoint("BOTTOMLEFT",51,7)
        description:SetPoint("RIGHT",row,"RIGHT",-103,0)
        description:SetWordWrap(false)
        description:SetTextColor(.77,.82,.87)
        local action=W.Button(row,"打开设置",92,function()OpenSettings(panel,addon)end)
        action:SetPoint("RIGHT",-5,0)
        panel.rows[i]={logo=logo,action=action,description=description}
    end
    anchor:HookScript("OnHide",function()panel:Hide()end)
    return panel
end

function B.ToggleAddonLauncher(anchor)
    local panel=anchor.addonLauncher
    if panel and panel:IsShown() then panel:Hide();return end
    if not panel then panel=CreatePanel(anchor);anchor.addonLauncher=panel end
    GameTooltip:Hide()
    for i,addon in ipairs(addons) do
        local status,handler=State(addon)
        local row=panel.rows[i]
        row.logo:SetTexture(Icon(addon))
        row.logo:SetDesaturated(not handler)
        row.description:SetText(addon.description)
        row.action:SetText(status)
        if handler then row.action:Enable() else row.action:Disable() end
    end
    panel:ClearAllPoints()
    panel:SetPoint("BOTTOMLEFT",anchor,"TOPLEFT",-9,14)
    panel:Show()
end
