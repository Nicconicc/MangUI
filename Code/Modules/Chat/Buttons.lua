local _,M=...
local B={};M.ChatButtons=B
local ART="Interface\\AddOns\\MangUI\\Assets\\ChatButtons\\"
local bagIconScale=.84
local launcherIconScale=.80
function B.ChannelInput(value)
    if type(value)~="string" then return "" end
    return (value:gsub("[\r\n]",""):gsub("^%s+",""):gsub("%s+$",""))
end
function B.Countdown(group)
    return M.Clamp(math.floor((tonumber(group and group.pullSeconds) or 10)+.5),10,60)
end
-- Reviewed actions and appearance from the supplied WA; no imported code runs.
B.definitions={
    {key="say",text="/S",tip="说话",prefix="/s",texture="cardFront_rarity_1",color={1,1,1}},
    {key="yell",text="/Y",tip="大喊",prefix="/y",texture="cardFront_rarity_4",color={1,.18431373,.16862746}},
    {key="guild",text="/G",tip="公会",prefix="/g",texture="cardFront_rarity_2",color={.23137257,1,.33333334}},
    {key="party",text="/P",tip="队伍",prefix="/p",texture="cardFront_rarity_3",color={.24313727,.52941179,1}},
    {key="raid",text="/Ra",tip="团队",prefix="/ra",texture="cardFront_rarity_6",color={1,.62352943,.07058824}},
    {key="battle",text="/Bg",tip="战场",prefix="/bg",texture="cardFront_rarity_5",color={1,.69019610,.12941177}},
    {key="instance",text="/I",tip="副本",prefix="/i",texture="cardFront_rarity_5",color={1,.73333335,.16862746}},
    {key="lfg",text="/LFG",tip="寻求组队：右键加入／离开频道",channel="lfg",texture="cardFront_rarity_7",color={1,.84705889,.83137262}},
    {key="duty",text="Duty",tip="职责确认",texture="cardBack_hover_A",color={.71764708,1,.43921572},hover=1.15,rotation=15},
    {key="ready",text="Ready",tip="就位确认",texture="cardBack_hover_C",color={.42745101,.79607850,1},hover=1.15,rotation=15},
    {key="pull",text="Pull",tip="开怪倒计时",texture="cardBack_hover_B",color={1,.40784317,.37647063},hover=1.15,rotation=15},
    {key="roll",text="/Roll",tip="骰子：Shift 点击固定掷出 100",texture="RollDice.tga",color={1,.90588242,.34117648},hover=1.15,iconScale=.75},
    {key="durability",text="—",texture="DurabilityAnvil.tga",color={1,1,1},hover=1.15,iconScale=.72},
    {key="bags",text="—",tip="背包（B）",atlas="bag-main",fallback="Interface\\Buttons\\Button-Backpack-Up",
        color={1,.90588242,.34117648},hover=1.15,iconScale=bagIconScale},
    {key="addons",text="AddOns",tip="插件入口",texture="AddonWrench.tga",color={1,.83,.44},hover=1.15,iconScale=launcherIconScale},
    {key="community",text="",tip="加入社区与作者互动",color={1,.83,.44},hover=1.15,iconScale=launcherIconScale},
}
local textLabels={say="说",yell="大喊",guild="公会",party="队伍",raid="团队",battle="战场",
    instance="副本",lfg="世界",roll="骰子",duty="职责",ready="就位",pull="倒计时",addons="插件入口"}
function B.LabelText(def,group)
    local label=textLabels[def.key]
    return label and group and group.textLabels==true and M:T(label) or def.text
end
local function Templates()
    return {
        {id="chatButtons",label="聊天与功能按钮",kind="group",compound="chatButtons",scope="player",unit="player",
            x=300,y=30,width=2,height=2,scale=1,iconSize=64,font="Myriad",fontSize=11,fontYOffset=0,buttonSpacing=-20,
            pullSeconds=10,customChannelName="",textLabels=false,showCommunity=true,
            point="CENTER",anchor="BOTTOMLEFT",screenAnchor="BOTTOMLEFT",alpha=1,enabled=true,layer=450,rules={},conditions={}},
        {id="chatButtonsRow",label="聊天与功能按钮",kind="chatbuttons",parent="chatButtons",internal=true,locked=true,
            scope="player",unit="player",x=0,y=15,width=592,height=94,scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=451},
    }
end
function B.SyncNodes(design)
    local group,row
    for _,n in ipairs(design.nodes) do
        if n.id=="chatButtons" then group=n elseif n.id=="chatButtonsRow" then row=n end
    end
    if not group or not row then return end
    group.pullSeconds=B.Countdown(group)
    group.customChannelName=B.ChannelInput(group.customChannelName)
    group.textLabels=group.textLabels==true
    group.showCommunity=group.showCommunity~=false
    local scale=group.scale or 1
    group.iconSize=M.Clamp((group.iconSize or 64)*scale,1,256)
    group.fontSize=math.max(.1,(group.fontSize or 11)*scale)
    group.buttonSpacing=M.Clamp((group.buttonSpacing or -20)*scale,M.SettingRanges.ChatGap(group.iconSize))
    group.font=group.font or "Myriad"
    group.fontYOffset=M.Clamp(group.fontYOffset or 0,-40,group.iconSize/2)
    if scale~=1 then group.x=(group.x or 0)*scale;group.y=(group.y or 0)*scale;group.scale=1 end
    row.width=group.iconSize+(#B.definitions-1)*(group.iconSize+group.buttonSpacing)
    row.height=group.iconSize+group.fontSize*2+8+math.abs(group.fontYOffset)*2
    row.y=group.fontSize+4
end
function M:EnsureChatButtonsModule(design)
    local seen={};for _,n in ipairs(design.nodes) do seen[n.id]=true end
    for _,n in ipairs(Templates()) do if not seen[n.id] then design.nodes[#design.nodes+1]=n end end
    B.SyncNodes(design)
end
M.moduleIDs.chatButtons=true
M:EnsureChatButtonsModule(M.defaults)
if M.recordedDefaults then M:EnsureChatButtonsModule(M.recordedDefaults) end

local function ChatContext()
    local active=ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    local frame=(active and active.chatFrame) or SELECTED_DOCK_FRAME or ChatFrame1
    return frame,active or (frame and frame.editBox),active
end
function B.ChannelName(def,group)
    if def.channel~="lfg" then return def.channel end
    local custom=B.ChannelInput(group and group.customChannelName)
    if custom~="" then return custom end
    local locale=GetLocale and GetLocale() or "zhCN"
    if locale=="zhCN" then return "寻求组队" end
    if locale=="zhTW" then return "尋求組隊" end
    return "LookingForGroup"
end
function B.Tooltip(def,group)
    if def.key=="lfg" then return string.format(M:T("%s：右键加入／离开频道"),B.ChannelName(def,group)) end
    if def.key=="pull" then return string.format(M:T("开怪倒计时：左键 %d 秒，右键取消"),B.Countdown(group)) end
    return M:T(def.tip)
end
local function SubscribeChannel(frame,name,enabled)
    if enabled then
        if frame.AddChannel then frame:AddChannel(name)
        elseif ChatFrame_AddChannel then ChatFrame_AddChannel(frame,name) end
    else
        if frame.RemoveChannel then frame:RemoveChannel(name)
        elseif ChatFrame_RemoveChannel then ChatFrame_RemoveChannel(frame,name) end
    end
end
local function ChannelMessage(frame,key,name)
    frame:AddMessage("|cffffcc66MangUI|r "..string.format(M:T(key),name))
end
function B.ProcessChannels()
    for name,request in pairs(B.pendingChannels or {}) do
        local id=GetChannelName(name)
        local joined=type(id)=="number" and id>0
        if joined==request.join then
            SubscribeChannel(request.frame,name,request.join)
            ChannelMessage(request.frame,request.join and "已加入频道：%s（当前窗口已启用接收）。" or "已离开频道：%s。",name)
            B.pendingChannels[name]=nil
        elseif GetTime()>=request.expires then
            ChannelMessage(request.frame,"频道操作未完成：%s，请稍后重试。",name)
            B.pendingChannels[name]=nil
        end
    end
    if B.channelEvents and not next(B.pendingChannels) then B.channelEvents:Hide() end
end
local function ToggleChannel(frame,name,joined)
    B.pendingChannels=B.pendingChannels or {}
    if B.pendingChannels[name] then return end
    if not B.channelEvents then
        local events=CreateFrame("Frame");B.channelEvents=events
        events:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE");events:RegisterEvent("CHANNEL_UI_UPDATE")
        events:SetScript("OnEvent",function()B.ProcessChannels()end)
        local elapsed=0
        events:SetScript("OnUpdate",function(_,dt)
            elapsed=elapsed+dt
            if elapsed>=.2 then elapsed=0;B.ProcessChannels() end
        end)
    end
    B.pendingChannels[name]={frame=frame,join=not joined,expires=GetTime()+10}
    B.channelEvents:Show()
    if joined then LeaveChannelByName(name)
    else JoinPermanentChannel(name,nil,frame:GetID() or 1,1) end
    -- Immediate completion on clients with synchronous channel updates; otherwise
    -- the notice/event or bounded polling confirms the join before subscribing.
    B.ProcessChannels()
end
function B.Context()
    local raid=IsInRaid and IsInRaid() or false
    local inside,instanceType=false,nil
    if IsInInstance then inside,instanceType=IsInInstance() end
    local maxPlayers
    if GetInstanceInfo then maxPlayers=select(5,GetInstanceInfo()) end
    return {
        guild=IsInGuild and IsInGuild() or false,
        party=raid or (IsInGroup and IsInGroup() or false),raid=raid,
        battle=inside and (instanceType=="pvp" or instanceType=="arena"),
        instance=inside and instanceType=="party" and (maxPlayers==5 or not maxPlayers),
        officer=raid and ((UnitIsGroupLeader and UnitIsGroupLeader("player")) or
            (UnitIsGroupAssistant and UnitIsGroupAssistant("player"))) or false,
    }
end
function B.IsVisible(def,context)
    if def.key=="duty" or def.key=="ready" or def.key=="pull" then return context.officer end
    local allowed=context[def.key]
    return allowed==nil or allowed==true
end
local function Pull(seconds)
    -- Resolve both the client's command cache and named handlers. SlashCmdList
    -- iteration alone can miss commands exposed through its metatable.
    local handler=hash_SlashCmdList and hash_SlashCmdList["/PULL"]
    if type(handler)~="function" and SlashCmdList then
        handler=SlashCmdList.BIGWIGSPULL or SlashCmdList.DEADLYBOSSMODSPULL
    end
    if type(handler)=="function" then handler(tostring(seconds));return end
    for key,handler in pairs(SlashCmdList or {}) do
        local index=1
        while _G["SLASH_"..key..index] do
            if _G["SLASH_"..key..index]:lower()=="/pull" and type(handler)=="function" then handler(tostring(seconds));return end
            index=index+1
        end
    end
    if DBM and type(DBM.CreatePullTimer)=="function" then DBM:CreatePullTimer(seconds);return end
    if C_PartyInfo and type(C_PartyInfo.DoCountdown)=="function" then C_PartyInfo.DoCountdown(seconds);return end
    M:Print("当前没有可用的开怪倒计时接口。")
end
function B.Click(def,button,group)
    group=group or (M.byID and M.byID.chatButtons)
    -- Recheck permissions even if the roster changed immediately before a click.
    if not B.IsVisible(def,B.Context()) then return end
    if def.key=="duty" then if button=="LeftButton" and InitiateRolePoll then InitiateRolePoll() end;return end
    if def.key=="ready" then if button=="LeftButton" and DoReadyCheck then DoReadyCheck() end;return end
    if def.key=="pull" then Pull(button=="RightButton" and 0 or B.Countdown(group));return end
    if def.key=="roll" then RandomRoll(IsShiftKeyDown() and 100 or 1,100);return end
    local frame,input,active=ChatContext()
    if not frame or not input then return end
    local channel=def.channel and B.ChannelName(def,group)
    local channelID=channel and GetChannelName(channel)
    if channel and button=="RightButton" then
        ToggleChannel(frame,channel,type(channelID)=="number" and channelID>0)
        return
    end
    if active and IsShiftKeyDown() then ChatEdit_DeactivateChat(active);return end
    local prefix=def.prefix
    if channel then
        if type(channelID)~="number" or channelID<=0 then M:Print("尚未加入此频道，请右键按钮加入。") return end
        SubscribeChannel(frame,channel,true)
        prefix="/"..channelID
    end
    if prefix then ChatFrame_OpenChat(prefix.." "..(input:GetText() or ""),frame) end
end
-- Inventory slot ID, localized client label, and Blizzard's inventory alert index.
local durabilitySlots={
    {1,"HEADSLOT",1,"Head"},{3,"SHOULDERSLOT",2,"Shoulder"},{5,"CHESTSLOT",3,"Chest"},
    {9,"WRISTSLOT",7,"Wrist"},{10,"HANDSSLOT",8,"Hands"},{6,"WAISTSLOT",4,"Waist"},
    {7,"LEGSSLOT",5,"Legs"},{8,"FEETSLOT",6,"Feet"},{16,"MAINHANDSLOT",9,"Main Hand"},
    {17,"SECONDARYHANDSLOT",10,"Off Hand"},{18,"RANGEDSLOT",11,"Ranged"},
}
local durabilityColors={
    [0]={r=.1,g=1,b=.1},[1]={r=1,g=.82,b=.18},[2]={r=.93,g=.07,b=.07},
}
local function DurabilityColor(status)
    return INVENTORY_ALERT_COLORS and INVENTORY_ALERT_COLORS[status] or durabilityColors[status]
end
local function DurabilityPercent(current,maximum)
    if maximum==0 then return "—" end
    return string.format("%.0f%%",100*current/maximum)
end
local function ReadDurability(preview)
    local rows,total,capacity,worst={},0,0,0
    for _,definition in ipairs(durabilitySlots) do
        local id,label,index,fallback=unpack(definition)
        local current,maximum,status
        if preview then
            if id~=18 then current,maximum,status=100-index,100,0 end
        elseif GetInventoryItemDurability then
            current,maximum=GetInventoryItemDurability(id)
            current,maximum=M.Compat.Number(current),M.Compat.Number(maximum)
        end
        if current and maximum and maximum>0 then
            current=M.Clamp(current,0,maximum)
            if status==nil and GetInventoryAlertStatus then
                status=M.Compat.Number(GetInventoryAlertStatus(index))
            end
            if current==0 then status=2
            elseif status~=0 and status~=1 and status~=2 then status=(current/maximum<=.25) and 1 or 0 end
            rows[#rows+1]={label=_G[label] or fallback,text=DurabilityPercent(current,maximum),status=status}
            total,capacity=total+current,capacity+maximum
            worst=math.max(worst,status)
        end
    end
    return rows,DurabilityPercent(total,capacity),capacity>0 and worst or nil
end
local function UpdateCounter(slot,text)
    if slot.counterText==text then return end
    slot.counterText=text
    slot.text:SetText(text);slot.shadow:SetText(text)
end
local function RefreshBagSpace(view,o)
    if not o.bagSlot then return end
    if view.preview then UpdateCounter(o.bagSlot,"24");return end
    local freeSlots=(C_Container and C_Container.GetContainerNumFreeSlots) or GetContainerNumFreeSlots
    if not freeSlots then UpdateCounter(o.bagSlot,"—");return end
    local bags,reagentBags=M.Compat.PlayerBagCounts()
    local total=0
    for id=0,bags+reagentBags do
        total=total+M.Compat.Number(freeSlots(id),0)
    end
    UpdateCounter(o.bagSlot,tostring(total))
end
local function RefreshDurability(view,o)
    local slot=o.durabilitySlot
    if not slot then return end
    local rows,percent,status=ReadDurability(view.preview)
    local color=status and DurabilityColor(status) or NORMAL_FONT_COLOR or {r=1,g=1,b=1}
    UpdateCounter(slot,percent)
    slot.text:SetTextColor(color.r,color.g,color.b)
    if not slot.durabilityHovered or GameTooltip:GetOwner()~=slot.button then return end
    local tooltip=GameTooltip
    tooltip:ClearLines()
    tooltip:SetText(M:T("装备耐久度"),1,.82,0)
    for _,row in ipairs(rows) do
        local c=DurabilityColor(row.status)
        tooltip:AddDoubleLine(row.label,row.text,1,1,1,c.r,c.g,c.b)
    end
    tooltip:AddDoubleLine(M:T("全身耐久度"),percent,1,.82,0,color.r,color.g,color.b)
    tooltip:Show()
end
function B.Build(view,o)
    o.chatButtons={}
    for index=1,#B.definitions do
        local def=B.definitions[index]
        local slot=CreateFrame("Frame",nil,o.frame);slot:SetSize(64,64)
        slot:SetPoint("CENTER",o.frame,"CENTER",(index-7)*44,-15);slot:SetFrameLevel(o.frame:GetFrameLevel()+index)
        local visual=CreateFrame("Frame",nil,slot);visual:SetSize(64,64);visual:SetPoint("CENTER");visual:EnableMouse(false)
        local texture=visual:CreateTexture(nil,"ARTWORK")
        if def.iconScale then texture:SetPoint("CENTER",visual,"CENTER")
        else texture:SetAllPoints() end
        local community
        if def.key=="community" then
            local logoPath
            community,logoPath=M.FooterLinks.ChatCommunity()
            texture:SetTexture(logoPath)
        elseif def.texture then
            texture:SetTexture(M:TexturePath(o.spec,ART..def.texture,"button_"..def.key))
        elseif def.atlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(def.atlas) then
            texture:SetAtlas(def.atlas)
        elseif def.fallback then
            texture:SetTexture(def.fallback)
        end
        texture:SetBlendMode("BLEND");texture:SetRotation(math.rad(def.rotation or 0))
        local shadow=visual:CreateFontString(nil,"ARTWORK");local text=visual:CreateFontString(nil,"OVERLAY")
        for _,label in ipairs({shadow,text}) do label:SetFont(M:DefaultFontPath(),11,"OUTLINE");label:SetText(def.text);label:SetJustifyH("CENTER") end
        text:SetPoint("CENTER",0,30);text:SetTextColor(unpack(def.color))
        shadow:SetPoint("CENTER",2,28);shadow:SetTextColor(0,0,0,1)
        local secureBag=def.key=="bags" and not view.preview
        local template=secureBag and "SecureActionButtonTemplate,SecureHandlerBaseTemplate" or nil
        local click=CreateFrame("Button",nil,slot,template)
        click:SetAllPoints(slot);click:SetFrameLevel(visual:GetFrameLevel()+1)
        local entry={frame=slot,visual=visual,button=click,texture=texture,text=text,shadow=shadow,definition=def}
        local isDurability=def.key=="durability"
        if isDurability then
            o.durabilitySlot=entry
        else
            click:RegisterForClicks("LeftButtonUp","RightButtonUp")
            if def.key=="bags" then o.bagSlot=entry
            elseif def.key~="addons" and not community then click:SetScript("OnClick",function(_,button)if not view.preview then B.Click(def,button,o.module) end end) end
            click:SetScript("OnMouseDown",function()visual:SetAlpha(.5)end)
            click:SetScript("OnMouseUp",function()visual:SetAlpha(1)end)
        end
        if def.key=="addons" and not view.preview then
            local guide=CreateFrame("Frame",nil,slot)
            guide:Hide()
            guide:SetSize(28,32);guide:EnableMouse(false)
            -- Draw the arrow from solid textures so it works on every client.
            for _,stroke in ipairs({{0,2,5,18,0},{-4,-6,5,14,math.pi/4},{4,-6,5,14,-math.pi/4}}) do
                local shadow=guide:CreateTexture(nil,"ARTWORK")
                shadow:SetColorTexture(.12,.07,.015,1)
                shadow:SetPoint("CENTER",guide,"CENTER",stroke[1],stroke[2]-1)
                shadow:SetSize(stroke[3]+3,stroke[4]+3);shadow:SetRotation(stroke[5])
                local arrow=guide:CreateTexture(nil,"OVERLAY")
                arrow:SetColorTexture(1,.8,.25,1)
                arrow:SetPoint("CENTER",guide,"CENTER",stroke[1],stroke[2])
                arrow:SetSize(stroke[3],stroke[4]);arrow:SetRotation(stroke[5])
            end
            local caption=M.Widgets.Label(guide,"各模块的插件使用和介绍在这里打开",12)
            caption:SetPoint("BOTTOM",guide,"TOP",0,5)
            caption:SetTextColor(1,.83,.44)
            caption:SetWordWrap(false)
            local close=CreateFrame("Button",nil,guide)
            close:SetSize(20,20)
            close:SetPoint("LEFT",caption,"RIGHT",4,0)
            close:SetFrameLevel(click:GetFrameLevel()+2)
            local cross=M.Widgets.Label(close,"×",16)
            cross:SetPoint("CENTER");cross:SetTextColor(1,.83,.44)
            close:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            close:SetScript("OnClick",function()
                M.db.addonLauncherGuideDismissed=true
                guide:Hide()
            end)
            entry.addonGuideClose=close
            local animation=guide:CreateAnimationGroup()
            animation:SetLooping("REPEAT")
            for i,offset in ipairs({6,-6}) do
                local step=animation:CreateAnimation("Translation")
                step:SetOrder(i);step:SetOffset(0,offset);step:SetDuration(.55)
                step:SetSmoothing("IN_OUT")
            end
            guide:SetScript("OnShow",function()animation:Play()end)
            guide:SetScript("OnHide",function()animation:Stop()end)
            guide:SetShown(not M.db.addonLauncherGuideDismissed)
            entry.addonGuide=guide
            click:SetScript("OnClick",function(self,button)
                if button~="LeftButton" then return end
                B.ShowAddonLauncher(self)
            end)
        end
        click:SetScript("OnEnter",function(self)
            if def.key=="addons" and not view.preview then
                B.ShowAddonLauncher(self)
            elseif not community or view.preview then
                GameTooltip:SetOwner(self,"ANCHOR_TOP")
                if isDurability then
                    entry.durabilityHovered=true
                    RefreshDurability(view,o)
                else
                    GameTooltip:SetText(B.Tooltip(def,o.module),1,1,1);GameTooltip:Show()
                end
            end
            -- The visual sibling scales without changing the click area.
            visual:SetScale(def.hover or 1.2)
            if not view.preview and PlaySoundFile then PlaySoundFile(ART.."Hover.mp3","SFX") end
        end)
        local function Reset()entry.durabilityHovered=nil;visual:SetScale(1);visual:SetAlpha(1);GameTooltip:Hide()end
        click:SetScript("OnLeave",Reset);click:SetScript("OnHide",Reset)
        if community and not view.preview then M.FooterLinks.AttachChatCommunity(click,community) end
        o.chatButtons[index]=entry
    end
end
function B.RefreshFonts(view,o,force)
    local group=o.module or (view.nodes[o.spec.parent] and view.nodes[o.spec.parent].spec)
    if not group then return end
    local size=group.fontSize or 11
    local font=M:EffectiveFontPath(group.fontPath or M.MYRIAD)
    local full=group.textLabels==true
    local language=M:EffectiveLanguage()
    local applied=o.appliedFont
    if not force and applied and not o.fontFailed and applied.path==font and applied.size==size
        and applied.textLabels==full and applied.language==language then return end
    local failed=false
    for _,slot in ipairs(o.chatButtons or {}) do
        for _,label in ipairs({slot.text,slot.shadow}) do
            if not M:ApplyRegionFont(label,font,size,"OUTLINE",force)then failed=true end
            -- Rebuild existing glyphs as well as assigning the requested face.
            label:SetWordWrap(false)
            if label.SetNonSpaceWrap then label:SetNonSpaceWrap(false) end
            label:SetWidth(0);label:SetHeight(0);label:SetJustifyV("MIDDLE")
            label:SetText("");label:SetText(slot.counterText or B.LabelText(slot.definition,group))
        end
    end
    o.appliedFont={path=font,size=size,textLabels=full,language=language};o.fontFailed=failed;o.fontNeedsSettle=not force
    if failed then view.fontsPending=true end
end
function B.Configure(view,o)
    local group=o.module or (view.nodes[o.spec.parent] and view.nodes[o.spec.parent].spec)
    if not group then return end
    local size=group.iconSize or 64
    B.RefreshFonts(view,o,false)
    local labelY=size/2-2+(group.fontYOffset or 0)
    for i,slot in ipairs(o.chatButtons) do
        slot.frame:SetSize(size,size)
        slot.visual:SetSize(size,size)
        local iconScale=slot.definition.iconScale
        if iconScale then slot.texture:SetSize(size*iconScale,size*iconScale) end
        for _,label in ipairs({slot.text,slot.shadow}) do
            label:ClearAllPoints()
        end
        slot.text:SetPoint("CENTER",0,labelY);slot.shadow:SetPoint("CENTER",2,labelY-2)
        if slot.addonGuide then
            slot.addonGuide:ClearAllPoints()
            slot.addonGuide:SetPoint("BOTTOM",slot.text,"TOP",0,5)
            slot.addonGuide:SetShown(not M.db.addonLauncherGuideDismissed)
        end
    end
    if not view.preview and o.bagSlot then M.Compat.ConfigureMenuButton(o.bagSlot.button,"bags","paired") end
    o.chatLayout=nil;B.Refresh(view,o)
    RefreshDurability(view,o)
    RefreshBagSpace(view,o)
end
function B.Refresh(view,o)
    local group=o.module or (view.nodes[o.spec.parent] and view.nodes[o.spec.parent].spec)
    if not group then return end
    if o.appliedFont and o.appliedFont.language~=M:EffectiveLanguage() then B.RefreshFonts(view,o,false) end
    local context=B.Context();local visible,signature={},{}
    for _,slot in ipairs(o.chatButtons) do
        local allowed=slot.definition.key~="community" or group.showCommunity~=false
        local shown=allowed and (view.preview or B.IsVisible(slot.definition,context))
        signature[#signature+1]=shown and "1" or "0"
        if shown then visible[#visible+1]=slot end
    end
    signature=table.concat(signature)
    if o.chatLayout==signature then return end
    -- The bag button uses the native secure click route. Apply pending layout on leaving combat.
    if not view.preview and o.bagSlot and InCombatLockdown() then return end
    o.chatLayout=signature
    local size,gap=group.iconSize or 64,group.buttonSpacing or -20
    -- Keep the full preview row's left edge fixed. New buttons fill to its right.
    o.frame:SetWidth(size+(#o.chatButtons-1)*(size+gap))
    for i,slot in ipairs(o.chatButtons) do slot.frame:SetShown(signature:sub(i,i)=="1") end
    for i,slot in ipairs(visible) do
        slot.frame:ClearAllPoints()
        slot.frame:SetPoint("CENTER",o.frame,"CENTER",(i-(#o.chatButtons+1)/2)*(size+gap),-(o.spec.y or 0))
    end
end
function B.Event(view,event)
    local row=view.nodes.chatButtonsRow
    if not row or not row.chatButtons then return end
    if event=="PLAYER_ENTERING_WORLD" or event=="BAG_UPDATE_DELAYED" then
        if not row.module or row.module.enabled~=false then RefreshBagSpace(view,row) end
    end
    if event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_EQUIPMENT_CHANGED" or
        event=="UPDATE_INVENTORY_DURABILITY" or event=="UPDATE_INVENTORY_ALERTS" then
        if not row.module or row.module.enabled~=false then RefreshDurability(view,row) end
    end
    if event=="PLAYER_ENTERING_WORLD" or event=="GROUP_ROSTER_UPDATE" or event=="PARTY_LEADER_CHANGED" or
        event=="PLAYER_GUILD_UPDATE" or event=="GUILD_ROSTER_UPDATE" or event=="ZONE_CHANGED_NEW_AREA" or
        event=="ZONE_CHANGED" or event=="UPDATE_BATTLEFIELD_STATUS" or event=="PLAYER_REGEN_ENABLED" then
        B.Refresh(view,row)
    end
end
