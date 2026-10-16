local _,M=...
local S={};M.SystemMenu=S
local ART="Interface\\AddOns\\MangUI\\Assets\\SystemMenu\\"
local mouseIcons={}
local function MouseIcon(side)
    if mouseIcons[side] then return mouseIcons[side] end
    local atlas="newplayertutorial-icon-mouse-"..side.."button"
    local ok,info
    if C_Texture and C_Texture.GetAtlasInfo then ok,info=pcall(C_Texture.GetAtlasInfo,atlas) end
    local height,width=18,15
    if ok and info then
        if info.width and info.height and info.height>0 then width=math.max(1,math.floor(info.width*height/info.height+.5)) end
        if CreateAtlasMarkup then mouseIcons[side]=CreateAtlasMarkup(atlas,width,height)
        else mouseIcons[side]="|A:"..atlas..":"..height..":"..width.."|a" end
    else
        local crop=side=="left" and "230:307" or "333:410"
        mouseIcons[side]="|TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:18:15:0:-1:512:512:12:66:"..crop.."|t"
    end
    return mouseIcons[side]
end
local function ShowMenuHint(owner,def)
    local tip=S.tooltip
    if not tip then
        tip=M.Widgets.Panel(UIParent);S.tooltip=tip
        tip:Hide();tip:SetFrameStrata("TOOLTIP");tip:SetFrameLevel(10200)
        tip:SetClampedToScreen(true);tip:EnableMouse(false)
        tip:SetBackdropColor(.025,.025,.035,.98);tip:SetBackdropBorderColor(.6,.6,.6,1)
        tip.lines={}
        for i=1,2 do
            local label=tip:CreateFontString(nil,"OVERLAY")
            label:SetFont(M:DefaultFontPath(),12,"");label:SetJustifyH("LEFT")
            label:SetWordWrap(false);label:SetTextColor(1,1,1,1)
            label:SetPoint("TOPLEFT",8,-8-(i-1)*22)
            tip.lines[i]=label
        end
    end
    local texts={M:T(def.tip)}
    if def.rightTip then
        texts[1]=MouseIcon("left").." "..texts[1]
        texts[2]=MouseIcon("right").." "..M:T(def.rightTip)
    end
    local width=0
    for i,label in ipairs(tip.lines) do
        -- Clear the previous hint's limits before measuring the full new line.
        label:SetWidth(0);label:SetHeight(0);label:SetText(texts[i] or "")
        local measured=label.GetUnboundedStringWidth and label:GetUnboundedStringWidth() or label:GetStringWidth()
        width=math.max(width,measured)
    end
    width=math.ceil(width)+2
    for i,label in ipairs(tip.lines) do label:SetSize(width,22);label:SetShown(texts[i]~=nil) end
    tip:SetSize(width+16,#texts*22+16)
    tip:ClearAllPoints();tip:SetPoint("TOP",owner,"BOTTOM",0,-10)
    tip.owner=owner;GameTooltip:Hide();tip:Show()
end
local function HideMenuHint(owner)
    local tip=S.tooltip
    if tip and tip.owner==owner then tip:Hide();tip.owner=nil end
end
-- Reviewed appearance/actions from the supplied WA; imported scripts never run.
function S.AvailableDefinitions(interface)
    local forever=interface==16001
    local modern=forever or interface>=100000
    local expanded=modern or interface>=30000
    local communities=modern or interface>=50000
    local definitions={
        {key="meeting",tip="集结号",file="Meetinghorn",size=90},
        {key="character",tip="角色信息（C）",file="emblem_7"},
        {key="spellbook",tip="法术书",right="talent",rightTip="天赋",file="emblem_4"},
        {key="friends",tip=communities and "好友" or "社交（O）",right=communities and "guild" or nil,
            rightTip=communities and "公会与社区" or nil,file="emblem_1"},
    }
    if expanded then definitions[#definitions+1]={key="achievement",tip="成就",right="collections",rightTip="藏品",file="emblem_9"} end
    if not modern then definitions[#definitions+1]={key="quest",tip="任务日志（L）",atlas="Mobile-LegendaryQuestIcon-Desaturated",fallback="Interface\\GossipFrame\\AvailableQuestIcon"} end
    if expanded then definitions[#definitions+1]={key="lfg",tip="地下城查找器",right="pvp",rightTip="PVP",file="emblem_6"} end
    definitions[#definitions+1]={key="professions",tip="专业",right=not forever and modern and "housing" or nil,
        rightTip=not forever and modern and "住宅信息板" or nil,asset=ART.."SystemMenu_systemMenuButtons_button_professions_emblem_10.blp"}
    definitions[#definitions+1]={key="map",tip="世界地图（M）",right=not forever and modern and "adventure" or nil,
        rightTip=not forever and modern and "冒险指南" or nil,file="emblem_3"}
    definitions[#definitions+1]={key="bags",tip="背包（B）",atlas="bag-main",fallback="Interface\\Buttons\\Button-Backpack-Up"}
    definitions[#definitions+1]={key="game",tip="主菜单（Escape）",atlas="token-choice-bnet",fallback="Interface\\Icons\\INV_Misc_Gear_01",size=128,travel=121}
    for i,def in ipairs(definitions) do
        def.size=def.size or 96;def.travel=def.travel or 105
        def.x=-360+(i-1)*720/(#definitions-1)
    end
    return definitions
end
local _,_,_,interface=GetBuildInfo()
S.definitions=S.AvailableDefinitions(interface)
local menuWidth=848
local function Templates()
    return {
        {id="systemMenu",label="系统菜单",kind="group",compound="systemMenu",scope="player",unit="player",
            x=0,y=0,width=menuWidth,height=128,scale=1,point="TOP",anchor="TOP",screenAnchor="TOP",
            alpha=1,enabled=true,locked=true,layer=600,rules={},conditions={}},
        {id="systemMenuButtons",label="系统菜单",kind="systemmenu",parent="systemMenu",internal=true,locked=true,
            scope="player",unit="player",x=0,y=0,width=menuWidth,height=128,scale=1,point="TOP",anchor="TOP",
            alpha=1,enabled=true,layer=601},
    }
end
function M:EnsureSystemMenuModule(design)
    local seen={};for _,n in ipairs(design.nodes) do
        seen[n.id]=true
        if n.id=="systemMenu" or n.id=="systemMenuButtons" then n.width=menuWidth;n.height=128 end
    end
    for _,n in ipairs(Templates()) do if not seen[n.id] then design.nodes[#design.nodes+1]=n end end
end
M.moduleIDs.systemMenu=true
M:EnsureSystemMenuModule(M.defaults)
if M.recordedDefaults then M:EnsureSystemMenuModule(M.recordedDefaults) end

local function Toggle(frame)
    if not frame then return false end
    if frame.Toggle then frame:Toggle()
    elseif frame:IsShown() then
        if HideUIPanel then HideUIPanel(frame) else frame:Hide() end
    else
        if ShowUIPanel then ShowUIPanel(frame) else frame:Show() end
    end
    return true
end
local function MeetingHorn()
    local loaded=(C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    local ace=LibStub and LibStub("AceAddon-3.0",true)
    for _,name in ipairs({"MeetingHorn","MeetingStone"}) do
        if not loaded or loaded(name) then
            local addon=ace and ace:GetAddon(name,true)
            if addon then
                if name=="MeetingHorn" and addon.HandleChatCommand then addon:HandleChatCommand("");return true end
                if addon.Toggle then addon:Toggle();return true end
                if Toggle(addon.MainPanel) then return true end
                if addon.OpenMainFrame then addon:OpenMainFrame();return true end
            end
            if name=="MeetingHorn" and Toggle(_G.MeetingHornHeroicMainFrame) then return true end
        end
    end
    M:Print("集结号或集合石插件尚未启用。")
end
function S.Click(key)
    if key=="meeting" then return MeetingHorn() end
    -- Protected entries run only from the inherited secure click script.
    M:Print("当前客户端不支持此菜单入口。")
end
local function Reset(slot)
    slot.progress=0;slot.target=0;slot.started=nil;slot.hideAt=nil;slot.pressed=nil;slot.hovered=nil
    slot.visual:SetScale(1);slot.visual:SetAlpha(0)
    slot.visual:ClearAllPoints();slot.visual:SetPoint("BOTTOM",slot.button,"TOP",0,0)
end
local function Wake(slot)
    local active=slot.owner.menuActive
    if not slot.queued then active[#active+1]=slot;slot.queued=true end
end
local function Advance(slot,now)
    if slot.started then
        local t=math.min(1,math.max(0,(now-slot.started)/.25))
        local eased=1-(1-t)^2
        slot.progress=slot.from+(slot.target-slot.from)*eased
        if t==1 then
            slot.started=nil
            if slot.target==1 then slot.hideAt=now+2 end
        end
    end
    slot.visual:ClearAllPoints()
    slot.visual:SetPoint("BOTTOM",slot.button,"TOP",0,-slot.definition.travel*slot.progress)
    slot.visual:SetAlpha(slot.pressed and .5 or slot.progress)
end
local function Animate(slot,target)
    local now=GetTime();Advance(slot,now)
    slot.from=slot.progress;slot.target=target;slot.started=now;slot.hideAt=nil
    Wake(slot)
end
function S.Build(view,o)
    o.menuButtons={};o.menuActive={}
    for index,def in ipairs(S.definitions) do
        local route
        if not view.preview and M.Compat.secureMenuKeys[def.key] then
            route="paired"
        end
        local template=route and "SecureActionButtonTemplate,SecureHandlerBaseTemplate" or nil
        local button=CreateFrame("Button",nil,o.frame,template);button:SetSize(60,def.travel)
        button:SetFrameLevel(o.frame:GetFrameLevel()+index);button:RegisterForClicks("LeftButtonUp","RightButtonUp")
        local visual=CreateFrame("Frame",nil,button);visual:SetSize(def.size,def.size);visual:EnableMouse(false)
        local texture=visual:CreateTexture(nil,"ARTWORK");texture:SetAllPoints();texture:SetBlendMode("BLEND")
        if def.asset then texture:SetTexture(def.asset)
        elseif def.file then texture:SetTexture(M:TexturePath(o.spec,ART..def.file,"button_"..def.key))
        elseif C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(def.atlas) then texture:SetAtlas(def.atlas)
        else texture:SetTexture(def.fallback) end
        -- Explicit dimensions also apply when the client atlas has its own size.
        texture:ClearAllPoints();texture:SetPoint("CENTER",visual,"CENTER");texture:SetSize(def.size,def.size)
        local slot={button=button,visual=visual,texture=texture,definition=def,progress=0,target=0,owner=o,secureRoute=route}
        o.menuButtons[#o.menuButtons+1]=slot
        button:SetScript("OnEnter",function(self)
            slot.hovered=true
            if not view.preview then Animate(slot,1);visual:SetScale(1.05);PlaySoundFile(ART.."Hover.mp3","SFX") end
            ShowMenuHint(self,def)
        end)
        button:SetScript("OnLeave",function()
            slot.hovered=nil;slot.pressed=nil
            if not view.preview then Animate(slot,0);visual:SetScale(1) end
            if view.preview then visual:SetAlpha(1) end
            HideMenuHint(button)
        end)
        button:SetScript("OnMouseDown",function()slot.pressed=true;slot.hideAt=nil;visual:SetAlpha(.5)end)
        button:SetScript("OnMouseUp",function()slot.pressed=nil;visual:SetAlpha(view.preview and 1 or slot.progress)end)
        -- Never replace the OnClick inherited from a secure template.
        button:SetScript(route and "PostClick" or "OnClick",function(_,mouseButton)
            if view.preview or (o.module and o.module.enabled==false) then return end
            if route then
                local side=mouseButton=="RightButton" and 2 or 1
                if not slot.secureAvailable[side] then M:Print("当前客户端不支持此菜单入口。") end
            else M:Safe("系统菜单",S.Click,def.key) end
            slot.hideAt=GetTime()+2;Wake(slot)
        end)
    end
    o.frame:SetScript("OnHide",function()
        for _,slot in ipairs(o.menuButtons) do
            if slot.hovered then HideMenuHint(slot.button) end
            if not view.preview then Reset(slot) end
            slot.queued=nil
        end
        for i=#o.menuActive,1,-1 do o.menuActive[i]=nil end
    end)
end
function S.Configure(view,o)
    if not view.preview and InCombatLockdown() then M.pending=true;return end
    for i=#o.menuActive,1,-1 do o.menuActive[i]=nil end
    for _,slot in ipairs(o.menuButtons) do
        slot.queued=nil
        if slot.secureRoute then
            slot.secureAvailable=M.Compat.ConfigureMenuButton(slot.button,slot.definition.key,slot.secureRoute,slot.definition.right)
        end
        slot.button:ClearAllPoints()
        if view.preview then
            slot.button:SetPoint("CENTER",o.frame,"CENTER",slot.definition.x,0)
            slot.visual:ClearAllPoints();slot.visual:SetPoint("CENTER",slot.button,"CENTER")
            slot.visual:SetAlpha(1);slot.visual:SetScale(1)
        else
            slot.button:SetPoint("TOP",o.frame,"TOP",slot.definition.x,0);Reset(slot)
        end
    end
end
function S.Paint(view,o)
    local shown=o.spec.enabled~=false and not (view.hidden and view.hidden[o.spec.id])
    if o.frame:IsShown()~=shown then
        if not view.preview and InCombatLockdown() then M.pending=true;return end
        o.frame:SetShown(shown)
    end
    if not shown or view.preview then return end
    local active=o.menuActive
    if #active==0 then return end
    local now=GetTime()
    for i=#active,1,-1 do
        local slot=active[i]
        if slot.hideAt and now>=slot.hideAt then Animate(slot,0) end
        if slot.started then Advance(slot,now) end
        if not slot.started and not slot.hideAt then
            table.remove(active,i);slot.queued=nil
        end
    end
end
