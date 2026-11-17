local _,M=...
local B=M.ChatButtons
local icons=[[Interface\Icons\]]
local categories={
    {key="ui",label="界面与布局",color={.51,.90,.85},metadata="ui overhaul;user interface;interface enhancements;ui;界面增强",
        names="manguitools hidingbar hidingbar_options moveany dynamiccam lueur ls_toasts 163ui_info"},
    {key="frames",label="单位框体",color={.42,.82,.99},metadata="unit frames;unitframes;nameplates;单位框体;单位框架;姓名板",
        names="mangui platynator cell"},
    {key="bars",label="动作条与皮肤",color={.84,.57,.95},metadata="action bars;actionbars;masque;动作条",
        names="bartender4moderngloweffects"},
    {key="combat",label="战斗与技能",color={.99,.49,.49},metadata="combat;combat improvement;buffs & debuffs;class;class addons;pvp;paladin;战斗",
        names="nicedamage classicfct spellactivationoverlay decursive pallypower"},
    {key="raids",label="副本与团队",color={.95,.61,.41},metadata="dbm;boss encounters;dungeons & raids;raid;raid frames;副本;团队",
        names="details meetinghorn"},
    {key="items",label="背包与物品",color={.99,.70,.45},metadata="bags;bags & inventory;inventory;bags & bank;背包;物品",
        names="baganator syndicator tdinspect idtip tacotip"},
    {key="trade",label="交易与邮件",color={.99,.80,.49},metadata="auction/economy;auctions & economy;auction & economy;mail;拍卖行;邮件",
        names="auctionator easyauction mailwright biaoge"},
    {key="chat",label="聊天与社交",color={.99,.55,.66},metadata="chat;chat & communication;social;聊天;社交",
        names="glass whispermessenger heyboxplayerinfo"},
    {key="explore",label="任务与探索",color={.61,.88,.61},metadata="quests;quests & leveling;map;maps;map & minimap;achievements;collections;任务;地图",
        names="atlas questie questiedb questietrace leatrix_maps dfminimap waypointui cardmaster cardmastercollection"},
    {key="tools",label="工具与组件",color={.72,.74,.95},metadata="development tools;libraries;library;sharedmedia;开发工具;函数库",
        names="sharedmedia sharedmedia_mangui bugsack !buggrabber leatrix_plus !pig df_cnlocale"},
    {key="other",label="其他插件",color={.66,.76,.88},metadata="",
        names=""},
}
local categoryByKey,categoryByMetadata,categoryByName={},{},{}
for order,category in ipairs(categories) do
    category.order=order
    categoryByKey[category.key]=category
    for label in category.metadata:gmatch("[^;]+") do categoryByMetadata[label]=category end
    for name in category.names:gmatch("%S+") do categoryByName[name]=category end
end
local addonFamilies={
    {"^dbm%-","raids"},{"^details_","raids"},{"^dungeonsforever","explore"},{"^cardmaster_","explore"},{"^lib","tools"},
}
local known={
    baganator={command="/baganator",handler="Baganator",icon=icons.."INV_Misc_Bag_10",
        description="整理、分类和搜索背包与银行物品。",hint="适合用分类和搜索快速找到道具，也能在单一背包和分类布局间切换。"},
    bartender4={command="/bt4",handler="ACECONSOLE_BT4",icon=icons.."INV_Drink_05",
        description="调整动作条布局、可见性和快捷键。",hint="适合重新排列动作条，并为不同情境设置显示规则。"},
    platynator={command="/platy",handler="Platynator",icon=icons.."Ability_Warrior_Challenge",
        description="自定义姓名板样式、文字和光环。",hint="可以把敌我姓名板做成不同风格，并突出重要光环。"},
    nicedamage={command="/nd",handler="ACECONSOLE_ND",icon=icons.."INV_Knife_1H_Rogue_C_01",
        description="替换跳出的伤害与治疗数字字体。",hint="装有设置界面的版本还可以调整字体大小与数字的显示方式。"},
    dynamiccam={command="/dc",handler="ACECONSOLE_DC",icon=icons.."INV_Misc_Spyglass_03",
        description="按游戏情境调整镜头缩放和视角。",hint="可以为探索、战斗或进入载具分别设置镜头。"},
    mangui={command="/mui",handler="MANGUIUF"},
    cardmaster={command="/cm",handler="CARDMASTER"},
    glass={command="/glass",handler="ACECONSOLE_GLASS"},
    leatrix_maps={command="/ltm",handler="Leatrix_Maps"},
    leatrix_plus={command="/ltp",handler="Leatrix_Plus"},
    masque={command="/masque",handler="MASQUE"},
    spellactivationoverlay={command="/sao",handler="SAO"},
    tacotip={command="/tacotip",handler="TACOTIP"},
    ls_toasts={command="/lst",handler="LSTOASTS"},
    syndicator={command="/syndicator",handler="Syndicator"},
    cell={command="/cell",handler="CELL",args="opt"},
}
local function AddOnAPI(name)
    return (C_AddOns and C_AddOns[name]) or _G[name]
end
local function PlainText(value)
    if type(value)~="string" then return "" end
    return (value:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
        :gsub("|[TA].-|[ta]",""):gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$",""))
end
local function Category(name,key,metadata)
    for _,family in ipairs(addonFamilies) do
        if key:match(family[1]) then return categoryByKey[family[2]] end
    end
    if metadata then
        for _,field in ipairs({"Category","X-Category"}) do
            local category=categoryByMetadata[PlainText(metadata(name,field)):lower()]
            if category then return category end
        end
    end
    return categoryByName[key] or categoryByKey.other
end

local catalog,toolsName
local function ScanAddOns()
    if catalog then return catalog end
    local count,info,metadata=AddOnAPI("GetNumAddOns"),AddOnAPI("GetAddOnInfo"),AddOnAPI("GetAddOnMetadata")
    local result={}
    if not count or not info then return result end
    local installed={}
    for i=1,count() do
        local name,title,notes=info(i)
        if type(name)=="string" and name~="" then
            local key=name:lower()
            if key=="manguitools" then toolsName=name end
            local entry=known[key]
            title=PlainText(title)
            if title=="" then title=name end
            notes=PlainText(notes)
            if notes=="" and metadata then notes=PlainText(metadata(name,"Notes")) end
            local icon=metadata and PlainText(metadata(name,"IconTexture")) or ""
            icon=icon:gsub("%s*%[AllowLoadGameType[^%]]*%]%s*$","")
            local atlas=metadata and PlainText(metadata(name,"IconAtlas")) or ""
            installed[name]=true
            result[#result+1]={
                name=name,key=key,title=title,sortTitle=title:lower(),notes=notes,known=entry,
                group=metadata and PlainText(metadata(i,"Group")) or "",
                icon=icon~="" and (tonumber(icon) or icon) or (entry and entry.icon) or icons.."INV_Misc_Gear_01",
                atlas=icon=="" and atlas~="" and atlas or nil,
                category=Category(name,key,metadata),
            }
        end
    end
    local mainAddOns={}
    for _,addon in ipairs(result) do
        local parent=addon.group
        if parent=="" or parent==addon.name then
            -- CardMaster's bundled data modules may ship without Group metadata.
            if addon.key=="cardmastercollection" or addon.key:match("^cardmaster_.+series$") then
                parent="CardMaster"
            end
        end
        if parent==addon.name or not installed[parent] then
            mainAddOns[#mainAddOns+1]=addon
        end
    end
    result=mainAddOns
    table.sort(result,function(a,b)
        if a.category.order~=b.category.order then return a.category.order<b.category.order end
        if a.sortTitle~=b.sortTitle then return a.sortTitle<b.sortTitle end
        return a.key<b.key
    end)
    catalog=result
    return catalog
end

local login=CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    ScanAddOns()
end)

local function IndexSettings()
    local routes={}
    local categorySet=Settings and Settings.CategorySet and Settings.CategorySet.AddOns
    if categorySet and Settings.OpenToCategory and SettingsPanel and SettingsPanel.GetAllCategories then
        for _,category in ipairs(SettingsPanel:GetAllCategories() or {}) do
            if category.categorySet==categorySet and category.GetName and category.GetID then
                local id=category:GetID()
                local key=PlainText(category:GetName()):lower()
                if key~="" and id~=nil then routes[key]={open=Settings.OpenToCategory,arg=id} end
            end
        end
    end
    if InterfaceOptionsFrame_OpenToCategory then
        for _,frame in ipairs(INTERFACEOPTIONS_ADDONCATEGORIES or {}) do
            local key=PlainText(frame.name):lower()
            if key~="" and not routes[key] then routes[key]={open=InterfaceOptionsFrame_OpenToCategory,arg=frame} end
        end
    end
    return routes
end

local function State(addon,routes)
    local isLoaded=AddOnAPI("IsAddOnLoaded")
    if not (isLoaded and isLoaded(addon.name)) then return "未加载" end
    local entry=addon.known
    if entry and entry.command then
        local handler=SlashCmdList and SlashCmdList[entry.handler]
        if type(handler)~="function" and hash_SlashCmdList then handler=hash_SlashCmdList[entry.command:upper()] end
        if type(handler)=="function" then return "打开设置",handler,entry.args or "",entry.command end
    end
    local route=routes[addon.key] or routes[addon.sortTitle]
    if route then return "打开设置",route.open,route.arg end
    return "无设置入口"
end

local function Description(addon)
    if addon.known and addon.known.description then return M:T(addon.known.description) end
    return addon.notes~="" and addon.notes or M:T("插件未提供介绍。")
end
local function ShowAddonTip(owner,panel,addon)
    if not toolsName then return end
    local status,open,_,command=State(addon,panel.routes)
    GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
    GameTooltip:SetText(addon.title,1,.82,.38)
    if addon.title~=addon.name then GameTooltip:AddLine(addon.name,.7,.76,.82) end
    local hint=addon.known and addon.known.hint
    GameTooltip:AddLine(hint and M:T(hint) or Description(addon),.9,.93,.97,true)
    local metadata=AddOnAPI("GetAddOnMetadata")
    if metadata then
        local field="X-MangUI-Tip-"..addon.name
        local note=PlainText(metadata(toolsName,field.."-"..GetLocale()))
        if note=="" then note=PlainText(metadata(toolsName,field)) end
        if note~="" then GameTooltip:AddLine(note,1,.82,.38,true) end
    end
    GameTooltip:AddLine(open and command and (M:T(status).."  "..command) or M:T(status),.7,.86,.76)
    GameTooltip:Show()
end
local function HideAddonTip(owner)
    if GameTooltip:GetOwner()==owner then GameTooltip:Hide() end
end

local function CreateRow(panel,index)
    local W=M.Widgets
    local row=CreateFrame("Frame",nil,panel)
    local y=46+(index-1)*53
    row:SetPoint("TOPLEFT",13,-y);row:SetPoint("TOPRIGHT",-30,-y);row:SetHeight(48)
    local backdrop=row:CreateTexture(nil,"BACKGROUND")
    backdrop:SetAllPoints()
    local badge=CreateFrame("Frame",nil,row)
    badge:SetSize(108,23);badge:SetPoint("LEFT",7,0)
    row.tint=badge:CreateTexture(nil,"BACKGROUND");row.tint:SetAllPoints()
    row.stripe=badge:CreateTexture(nil,"ARTWORK")
    row.stripe:SetWidth(2);row.stripe:SetPoint("TOPLEFT");row.stripe:SetPoint("BOTTOMLEFT")
    row.categoryLabel=W.Label(badge,"",11)
    row.categoryLabel:SetPoint("LEFT",5,0);row.categoryLabel:SetPoint("RIGHT",-3,0)
    row.categoryLabel:SetJustifyH("CENTER");row.categoryLabel:SetWordWrap(false)

    row.logo=row:CreateTexture(nil,"ARTWORK")
    row.logo:SetSize(34,34);row.logo:SetPoint("LEFT",badge,"RIGHT",10,0)
    row.nameLabel=W.Label(row,"",14)
    row.nameLabel:SetPoint("TOPLEFT",168,-6);row.nameLabel:SetPoint("RIGHT",-103,0)
    row.nameLabel:SetWordWrap(false);row.nameLabel:SetTextColor(.96,.88,.68)
    row.description=W.Label(row,"",11)
    row.description:SetPoint("BOTTOMLEFT",168,7)
    row.description:SetPoint("RIGHT",row,"RIGHT",-103,0)
    row.description:SetWordWrap(false);row.description:SetTextColor(.77,.82,.87)
    row.action=W.Button(row,"打开设置",92,function()
        if InCombatLockdown() then M:Print("脱战后才能打开插件设置。");return end
        if not row.addon then return end
        local _,open,arg=State(row.addon,IndexSettings())
        if open and M:Safe("打开设置",open,arg) then panel:Hide() end
    end)
    row.action:SetPoint("RIGHT",-5,0)
    local function OnEnter(owner)
        if not row.addon then return end
        backdrop:SetColorTexture(.34,.47,.61,.35)
        ShowAddonTip(owner,panel,row.addon)
    end
    local function OnLeave(owner)
        backdrop:SetColorTexture(.25,.33,.43,index%2==0 and .23 or .13)
        HideAddonTip(owner)
    end
    row.ResetHighlight=OnLeave
    row:EnableMouse(true)
    for _,region in ipairs({row,row.action}) do
        region:HookScript("OnEnter",OnEnter);region:HookScript("OnLeave",OnLeave);region:HookScript("OnHide",OnLeave)
        region:EnableMouseWheel(true)
        region:SetScript("OnMouseWheel",function(_,delta)
            panel.slider:SetValue(panel.slider:GetValue()-delta*3)
        end)
    end
    return row
end

local function RefreshRows(panel,index)
    index=math.floor(index+.5)
    for i,row in ipairs(panel.rows) do
        HideAddonTip(row);HideAddonTip(row.action)
        local addon=i<=panel.visibleRows and catalog and catalog[index+i]
        row.addon=addon
        if addon then
            local r,g,b=unpack(addon.category.color)
            row.tint:SetColorTexture(r,g,b,.14);row.stripe:SetColorTexture(r,g,b,.85)
            row.categoryLabel:SetText(addon.category.label);row.categoryLabel:SetTextColor(r,g,b)
            if addon.atlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(addon.atlas) then
                row.logo:SetAtlas(addon.atlas)
            else row.logo:SetTexture(addon.icon) end
            row.nameLabel:SetText(addon.title)
            row.description:SetText(Description(addon))
            local status,open=State(addon,panel.routes)
            row.logo:SetDesaturated(status=="未加载")
            row.action:SetText(status)
            if open then row.action:Enable() else row.action:Disable() end
            row.ResetHighlight(row)
            row:Show()
        else
            row:Hide()
        end
    end
end

local function CreatePanel(anchor)
    local W=M.Widgets
    local panel=W.Panel(anchor)
    panel:SetWidth(575);panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true);panel:EnableMouse(true);panel:Hide()
    local title=W.Label(panel,"插件入口",16)
    title:SetPoint("TOPLEFT",17,-14);title:SetTextColor(1,.82,.38)
    local close=CreateFrame("Button",nil,panel,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",-3,-3)
    close:SetScript("OnClick",function()panel:Hide()end)
    local line=panel:CreateTexture(nil,"ARTWORK")
    line:SetPoint("TOPLEFT",14,-40);line:SetPoint("TOPRIGHT",-14,-40)
    line:SetHeight(1);line:SetColorTexture(.72,.56,.25,.5)
    panel.count=W.Label(panel,"",11);panel.count:SetPoint("RIGHT",close,"LEFT",-8,0)
    panel.count:SetTextColor(.73,.78,.85)
    panel.empty=W.Label(panel,"当前没有可显示的插件。",13)
    panel.empty:SetPoint("TOPLEFT",17,-57)
    panel.rows={}
    for i=1,8 do panel.rows[i]=CreateRow(panel,i) end
    local slider=CreateFrame("Slider",nil,panel)
    slider:SetPoint("TOPRIGHT",-11,-48);slider:SetWidth(12)
    slider:SetOrientation("VERTICAL");slider:SetValueStep(1)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    slider:SetThumbTexture([[Interface\Buttons\UI-ScrollBar-Knob]])
    local thumb=slider:GetThumbTexture();if thumb then thumb:SetSize(16,22) end
    local track=slider:CreateTexture(nil,"BACKGROUND")
    track:SetAllPoints();track:SetColorTexture(.12,.15,.21,.8)
    panel.slider=slider
    slider:SetScript("OnValueChanged",function(_,value)RefreshRows(panel,value)end)
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel",function(_,delta) slider:SetValue(slider:GetValue()-delta*3) end)
    anchor:HookScript("OnHide",function()panel:Hide()end)
    return panel
end

function B.ToggleAddonLauncher(anchor)
    local panel=anchor.addonLauncher
    if panel and panel:IsShown() then panel:Hide();return end
    local addons=ScanAddOns()
    if not panel then panel=CreatePanel(anchor);anchor.addonLauncher=panel end
    GameTooltip:Hide()
    panel.routes=IndexSettings()
    local visibleRows=math.min(#panel.rows,math.max(1,math.floor((UIParent:GetHeight()*.65-52)/53)),math.max(1,#addons))
    local maxScroll=math.max(0,#addons-visibleRows)
    panel.visibleRows=visibleRows
    panel:SetHeight(52+visibleRows*53)
    panel.count:SetText(tostring(#addons))
    panel.empty:SetShown(#addons==0)
    panel.slider:SetHeight(visibleRows*53-10)
    panel.slider:SetMinMaxValues(0,maxScroll)
    panel.slider:SetValue(math.min(panel.slider:GetValue(),maxScroll))
    panel.slider:SetShown(maxScroll>0)
    RefreshRows(panel,panel.slider:GetValue())
    panel:ClearAllPoints();panel:SetPoint("BOTTOMLEFT",anchor,"TOPLEFT",-9,14)
    panel:Show()
end

