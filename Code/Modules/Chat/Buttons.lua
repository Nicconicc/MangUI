local _,M=...
local B={};M.ChatButtons=B
local ART="Interface\\AddOns\\MangUI\\Assets\\ChatButtons\\"
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
    {key="roll",text="/Roll",tip="骰子：Shift 点击固定掷出 100",texture="Dice",color={1,.90588242,.34117648},hover=1.15},
    {key="duty",text="Duty",tip="职责确认",texture="cardBack_hover_A",color={.71764708,1,.43921572},hover=1.15,rotation=15},
    {key="ready",text="Ready",tip="就位确认",texture="cardBack_hover_C",color={.42745101,.79607850,1},hover=1.15,rotation=15},
    {key="pull",text="Pull",tip="开怪倒计时",texture="cardBack_hover_B",color={1,.40784317,.37647063},hover=1.15,rotation=15},
}
local textLabels={say="说",yell="大喊",guild="公会",party="队伍",raid="团队",battle="战场",
    instance="副本",lfg="世界",roll="骰子",duty="职责",ready="就位",pull="倒计时"}
function B.LabelText(def,group)
    return group and group.textLabels==true and M:T(textLabels[def.key]) or def.text
end
local function Templates()
    return {
        {id="chatButtons",label="聊天与功能按钮",kind="group",compound="chatButtons",scope="player",unit="player",
            x=300,y=30,width=2,height=2,scale=1,iconSize=64,font="Myriad",fontSize=11,fontYOffset=0,buttonSpacing=-20,
            pullSeconds=10,customChannelName="",textLabels=false,
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
function B.Build(view,o)
    o.chatButtons={}
    for index,def in ipairs(B.definitions) do
        local slot=CreateFrame("Frame",nil,o.frame);slot:SetSize(64,64)
        slot:SetPoint("CENTER",o.frame,"CENTER",(index-7)*44,-15);slot:SetFrameLevel(o.frame:GetFrameLevel()+index)
        local visual=CreateFrame("Frame",nil,slot);visual:SetSize(64,64);visual:SetPoint("CENTER");visual:EnableMouse(false)
        local texture=visual:CreateTexture(nil,"ARTWORK");texture:SetAllPoints();texture:SetTexture(M:TexturePath(o.spec,ART..def.texture,"button_"..def.key))
        texture:SetBlendMode("BLEND");texture:SetRotation(math.rad(def.rotation or 0))
        local shadow=visual:CreateFontString(nil,"ARTWORK");local text=visual:CreateFontString(nil,"OVERLAY")
        for _,label in ipairs({shadow,text}) do label:SetFont(M:DefaultFontPath(),11,"OUTLINE");label:SetText(def.text);label:SetJustifyH("CENTER") end
        text:SetPoint("CENTER",0,30);text:SetTextColor(unpack(def.color))
        shadow:SetPoint("CENTER",2,28);shadow:SetTextColor(0,0,0,1)
        -- Native role/ready APIs and registered slash handlers run on a user click.
        -- Ordinary buttons let the row hide and reflow when context changes in combat.
        local click=CreateFrame("Button",nil,slot)
        click:SetAllPoints(slot);click:SetFrameLevel(visual:GetFrameLevel()+1)
        click:RegisterForClicks("LeftButtonUp","RightButtonUp")
        click:SetScript("OnClick",function(_,button)if not view.preview then B.Click(def,button,o.module) end end)
        click:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(B.Tooltip(def,o.module),1,1,1);GameTooltip:Show()
            -- The visual sibling scales without changing the click area.
            visual:SetScale(def.hover or 1.2)
            if not view.preview and PlaySoundFile then PlaySoundFile(ART.."Hover.mp3","SFX") end
        end)
        local function Reset()visual:SetScale(1);visual:SetAlpha(1);GameTooltip:Hide()end
        click:SetScript("OnLeave",Reset);click:SetScript("OnHide",Reset)
        click:SetScript("OnMouseDown",function()visual:SetAlpha(.5)end)
        click:SetScript("OnMouseUp",function()visual:SetAlpha(1)end)
        o.chatButtons[index]={frame=slot,visual=visual,button=click,texture=texture,text=text,shadow=shadow,definition=def}
    end
end
function B.RefreshFonts(view,o,force)
    local group=o.module or (view.nodes[o.spec.parent] and view.nodes[o.spec.parent].spec)
    if not group then return end
    local size=group.fontSize or 11
    local font=M:EffectiveFontPath(group.fontPath or M.MYRIAD)
    local full=group.textLabels==true
    local language=M:EffectiveLanguage()
    if full and font==M.MYRIAD and (language=="ruRU" or language=="koKR") then font=M:NotoFontPath(true,language) end
    local applied=o.appliedFont
    if not force and applied and not o.fontFailed and applied.path==font and applied.size==size
        and applied.textLabels==full and applied.language==language then return end
    local failed=false
    for _,slot in ipairs(o.chatButtons or {}) do
        for _,label in ipairs({slot.text,slot.shadow}) do
            local ok,loaded=pcall(label.SetFont,label,font,size,"OUTLINE")
            if not ok or loaded==false then failed=true;label:SetFont(M:DefaultFontPath(),size,"OUTLINE") end
            -- Rebuild existing glyphs as well as assigning the requested face.
            label:SetWordWrap(false)
            if label.SetNonSpaceWrap then label:SetNonSpaceWrap(false) end
            label:SetWidth(0);label:SetHeight(0);label:SetJustifyV("MIDDLE")
            label:SetText("");label:SetText(B.LabelText(slot.definition,group))
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
        for _,label in ipairs({slot.text,slot.shadow}) do
            label:ClearAllPoints()
        end
        slot.text:SetPoint("CENTER",0,labelY);slot.shadow:SetPoint("CENTER",2,labelY-2)
    end
    o.chatLayout=nil;B.Refresh(view,o)
end
function B.Refresh(view,o)
    local group=o.module or (view.nodes[o.spec.parent] and view.nodes[o.spec.parent].spec)
    if not group then return end
    if o.appliedFont and o.appliedFont.language~=M:EffectiveLanguage() then B.RefreshFonts(view,o,false) end
    local context=B.Context();local visible,signature={},{}
    for _,slot in ipairs(o.chatButtons) do
        local shown=view.preview or B.IsVisible(slot.definition,context)
        signature[#signature+1]=shown and "1" or "0"
        if shown then visible[#visible+1]=slot end
    end
    signature=table.concat(signature)
    if o.chatLayout==signature then return end
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
    if event=="PLAYER_ENTERING_WORLD" or event=="GROUP_ROSTER_UPDATE" or event=="PARTY_LEADER_CHANGED" or
        event=="PLAYER_GUILD_UPDATE" or event=="GUILD_ROSTER_UPDATE" or event=="ZONE_CHANGED_NEW_AREA" or
        event=="ZONE_CHANGED" or event=="UPDATE_BATTLEFIELD_STATUS" then
        local row=view.nodes.chatButtonsRow
        if row and row.chatButtons then B.Refresh(view,row) end
    end
end
