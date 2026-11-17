local _,M=...
local B=M.ChatButtons
local icons=[[Interface\Icons\]]
local categories={
    bags={label="背包模块",color={.99,.70,.45}},
    action={label="动作条模块",color={.84,.57,.95}},
    combat={label="副本及战斗模块",color={.99,.49,.49}},
    utility={label="辅助功能模块",color={.53,.86,.72}},
}
local addons={
    {name="Baganator",category=categories.bags,command="/baganator",handler="Baganator",icon=icons.."INV_Misc_Bag_10",
        description="整理、分类和搜索背包与银行物品。",
        hint="适合用分类和搜索快速找到道具，也能在单一背包和分类布局间切换。"},
    {name="Bartender4",category=categories.action,command="/bt4",handler="ACECONSOLE_BT4",icon=icons.."INV_Drink_05",
        description="调整动作条布局、可见性和快捷键。",
        hint="适合重新排列动作条，并为不同情境设置显示规则。"},
    {name="Platynator",category=categories.combat,command="/platy",handler="Platynator",icon=icons.."Ability_Warrior_Challenge",
        description="自定义姓名板样式、文字和光环。",
        hint="可以把敌我姓名板做成不同风格，并突出重要光环。"},
    {name="NiceDamage",category=categories.combat,command="/nd",handler="ACECONSOLE_ND",icon=icons.."INV_Knife_1H_Rogue_C_01",
        description="替换跳出的伤害与治疗数字字体。",
        hint="装有设置界面的版本还可以调整字体大小与数字的显示方式。"},
    {name="DynamicCam",category=categories.utility,command="/dc",handler="ACECONSOLE_DC",icon=icons.."INV_Misc_Spyglass_03",
        description="按游戏情境调整镜头缩放和视角。",
        hint="可以为探索、战斗或进入载具分别设置镜头。"},
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

local function ShowAddonTip(owner,addon)
    local status,handler=State(addon)
    GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
    GameTooltip:SetText(addon.name,1,.82,.38)
    GameTooltip:AddLine(M:T(addon.hint),.9,.93,.97,true)
    if handler then
        GameTooltip:AddLine(M:T("打开设置").."  "..addon.command,.64,.88,.7)
    else
        GameTooltip:AddLine(M:T(status),.78,.78,.78)
    end
    GameTooltip:Show()
end

local function HideAddonTip(owner)
    if GameTooltip:GetOwner()==owner then GameTooltip:Hide() end
end

local function CreatePanel(anchor)
    local W=M.Widgets
    local panel=W.Panel(anchor)
    panel:SetWidth(558)
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
    local rowY=46
    local previousCategory
    for i,addon in ipairs(addons) do
        local category=addon.category
        if previousCategory and category~=previousCategory then rowY=rowY+6 end
        previousCategory=category
        local row=CreateFrame("Frame",nil,panel)
        row:SetPoint("TOPLEFT",13,-rowY)
        row:SetPoint("TOPRIGHT",-13,-rowY);row:SetHeight(48)
        rowY=rowY+53
        local backdrop=row:CreateTexture(nil,"BACKGROUND")
        backdrop:SetAllPoints();backdrop:SetColorTexture(.25,.33,.43,i%2==0 and .23 or .13)
        local badge=CreateFrame("Frame",nil,row)
        badge:SetSize(108,23);badge:SetPoint("LEFT",7,0)
        local r,g,b=unpack(category.color)
        local tint=badge:CreateTexture(nil,"BACKGROUND")
        tint:SetAllPoints();tint:SetColorTexture(r,g,b,.14)
        local stripe=badge:CreateTexture(nil,"ARTWORK")
        stripe:SetWidth(2);stripe:SetPoint("TOPLEFT");stripe:SetPoint("BOTTOMLEFT")
        stripe:SetColorTexture(r,g,b,.85)
        local categoryLabel=W.Label(badge,category.label,11)
        categoryLabel:SetPoint("LEFT",5,0);categoryLabel:SetPoint("RIGHT",-3,0)
        categoryLabel:SetJustifyH("CENTER");categoryLabel:SetWordWrap(false)
        categoryLabel:SetTextColor(r,g,b)

        local logo=row:CreateTexture(nil,"ARTWORK")
        logo:SetSize(34,34);logo:SetPoint("LEFT",badge,"RIGHT",10,0)
        local name=W.Label(row,addon.name,14)
        name:SetPoint("TOPLEFT",168,-6);name:SetTextColor(.96,.88,.68)
        local description=W.Label(row,addon.description,11)
        description:SetPoint("BOTTOMLEFT",168,7)
        description:SetPoint("RIGHT",row,"RIGHT",-103,0)
        description:SetWordWrap(false)
        description:SetTextColor(.77,.82,.87)
        local action=W.Button(row,"打开设置",92,function()OpenSettings(panel,addon)end)
        action:SetPoint("RIGHT",-5,0)
        row:EnableMouse(true)
        local function OnEnter(owner)
            backdrop:SetColorTexture(.34,.47,.61,.35)
            ShowAddonTip(owner,addon)
        end
        local function OnLeave(owner)
            backdrop:SetColorTexture(.25,.33,.43,i%2==0 and .23 or .13)
            HideAddonTip(owner)
        end
        row:HookScript("OnEnter",OnEnter);row:HookScript("OnLeave",OnLeave);row:HookScript("OnHide",OnLeave)
        action:HookScript("OnEnter",OnEnter);action:HookScript("OnLeave",OnLeave);action:HookScript("OnHide",OnLeave)
        panel.rows[i]={logo=logo,action=action,description=description}
    end
    panel:SetHeight(rowY+6)
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
