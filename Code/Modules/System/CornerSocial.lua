local _, M = ...
local S = {}
M.CornerSocial = S

local versions = {
    {"WOW_PROJECT_MAINLINE", 1, "正式服", "Retail"},
    {"WOW_PROJECT_CLASSIC", 2, "经典旧世", "Classic Era"},
    {"WOW_PROJECT_BURNING_CRUSADE_CLASSIC", 5, "燃烧的远征怀旧服", "Burning Crusade Classic"},
    {"WOW_PROJECT_WRATH_CLASSIC", 11, "巫妖王之怒怀旧服", "Wrath Classic"},
    {"WOW_PROJECT_CATACLYSM_CLASSIC", 14, "大地的裂变怀旧服", "Cataclysm Classic"},
    {"WOW_PROJECT_MISTS_CLASSIC", 19, "熊猫人之谜怀旧服", "Mists Classic"},
    {"WOW_PROJECT_CLASSIC_ANNIVERSARY", nil, "周年怀旧服", "Anniversary Classic"},
    {"WOW_PROJECT_CAMELOT", 18, "无限服", "Classic Forever"},
    {"WOW_PROJECT_TITAN", nil, "时光服", "Titan Classic"},
}

local function Text(zh, en)
    local locale = GetLocale()
    return (locale == "zhCN" or locale == "zhTW") and zh or en
end

local function Version(project)
    for _, version in ipairs(versions) do
        local id = _G[version[1]] or version[2]
        if id and project == id then return Text(version[3], version[4]) end
    end
    return project and ("WoW · " .. tostring(project)) or Text("版本未知", "Unknown version")
end

local function ClassColor(class)
    local colors = RAID_CLASS_COLORS or {}
    if colors[class] then return colors[class] end
    for token, color in pairs(colors) do
        if (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token] == class)
            or (LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[token] == class) then
            return color
        end
    end
end

local function Add(rows, name, level, class, detail, crossClient)
    if type(name) ~= "string" or name == "" then return end
    level = tonumber(level)
    rows[#rows + 1] = {
        name = name, level = level and level > 0 and tostring(level) or "—",
        sortLevel = level or 0,
        color = ClassColor(class), detail = detail and detail ~= "" and detail or "—",
        crossClient = crossClient,
    }
    return rows[#rows]
end

local function FriendKey(name, realm)
    local character, namedRealm = name:match("^([^-]+)%-(.+)$")
    realm = namedRealm or (realm ~= "" and realm) or (GetNormalizedRealmName and GetNormalizedRealmName())
        or (GetRealmName and GetRealmName())
    return ((character or name) .. "-" .. (realm or "")):gsub("%s+", ""):lower()
end

local function IsOnlineWoW(account)
    return account and account.isOnline and account.clientProgram == (BNET_CLIENT_WOW or "WoW")
        and account.characterName and account.characterName ~= ""
end

local function Friends()
    local rows, seen = {}, {}
    local api = C_FriendList
    local count = (api and api.GetNumFriends) or GetNumFriends
    for i = 1, count and count() or 0 do
        local info
        if api and api.GetFriendInfoByIndex then
            info = api.GetFriendInfoByIndex(i)
        elseif GetFriendInfo then
            local name, level, class, area, connected = GetFriendInfo(i)
            info = {name=name, level=level, className=class, area=area, connected=connected}
        end
        if info and info.connected and info.name and info.name ~= "" then
            Add(rows, info.name, info.level, info.className, info.area)
            seen[FriendKey(info.name)] = true
        end
    end

    local battleNet = C_BattleNet
    if not (battleNet and battleNet.GetFriendAccountInfo and BNGetNumFriends) then return rows end
    for i = 1, BNGetNumFriends() do
        local friend = battleNet.GetFriendAccountInfo(i)
        local game = friend and friend.gameAccountInfo
        local best = IsOnlineWoW(game) and game or nil
        if not (best and best.wowProjectID == WOW_PROJECT_ID)
            and battleNet.GetFriendNumGameAccounts and battleNet.GetFriendGameAccountInfo then
            for j = 1, battleNet.GetFriendNumGameAccounts(i) or 0 do
                local account = battleNet.GetFriendGameAccountInfo(i, j)
                if IsOnlineWoW(account) then
                    if account.wowProjectID == WOW_PROJECT_ID then best = account; break end
                    best = best or account
                end
            end
        end
        if best then
            local same = best.wowProjectID ~= nil and best.wowProjectID == WOW_PROJECT_ID
            local key = FriendKey(best.characterName, best.realmName)
            if not same or not seen[key] then
                local row = Add(rows, best.characterName, best.characterLevel, best.classFilename or best.className,
                    same and (best.areaName or "—") or Version(best.wowProjectID), not same)
                row.accountName = BNet_GetBNetAccountName and BNet_GetBNetAccountName(friend)
                    or (friend.accountName ~= "" and friend.accountName) or friend.battleTag
                row.gameAccountID = best.gameAccountID
                row.realm = best.realmName
                if same then seen[key] = true end
            end
        end
    end
    return rows
end

local function Guild()
    local rows = {}
    if not (IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo) then return rows end
    local count = GetNumGuildMembers()
    for i = 1, count or 0 do
        local name, _, _, level, class, area, _, _, online, _, token = GetGuildRosterInfo(i)
        if online then Add(rows, name, level, token or class, area) end
    end
    return rows
end

local function MemberName(data)
    local name = data.name
    if data.realm and data.realm ~= "" and not name:find("-",1,true) then
        name = name .. "-" .. data.realm:gsub("%s+","")
    end
    local player = UnitName and UnitName("player")
    if player and FriendKey(name) == FriendKey(player) then return end
    return name
end

local function WhisperAction(data, name)
    if not name then return end
    local tell = (ChatFrameUtil and ChatFrameUtil.SendTell) or ChatFrame_SendTell
    local battleNetTell = (ChatFrameUtil and ChatFrameUtil.SendBNetTell) or ChatFrame_SendBNetTell
    if data.accountName and data.accountName ~= "" and battleNetTell then
        return function() battleNetTell(data.accountName) end
    elseif tell and not data.crossClient then
        return function() tell(name) end
    end
end

local function MemberActions(data)
    local actions = {}
    local name = MemberName(data)
    if not name then return actions end
    local whisper = WhisperAction(data,name)
    if whisper then actions[#actions+1] = {WHISPER or Text("密语","Whisper"),whisper} end
    local invite = (C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit
    if not data.crossClient then
        local label = PARTY_INVITE or INVITE or Text("邀请组队","Invite to party")
        if data.gameAccountID and BNInviteFriend then
            actions[#actions+1] = {label,function() BNInviteFriend(data.gameAccountID) end}
        elseif invite then
            actions[#actions+1] = {label,function() invite(name) end}
        end
    end
    return actions
end

local function OpenMemberMenu(panel, data)
    local actions = MemberActions(data)
    if MenuUtil and MenuUtil.CreateContextMenu then
        panel.memberMenu = MenuUtil.CreateContextMenu(panel,function(_, root)
            root:CreateTitle(data.name)
            for _, action in ipairs(actions) do root:CreateButton(action[1],action[2]) end
        end)
    elseif EasyMenu and UIDropDownMenu_CreateInfo then
        panel.legacyMenu = panel.legacyMenu or CreateFrame("Frame",nil,panel,"UIDropDownMenuTemplate")
        local entries = {{text=data.name,isTitle=true,notCheckable=true}}
        for _, action in ipairs(actions) do
            entries[#entries+1] = {text=action[1],func=action[2],notCheckable=true}
        end
        EasyMenu(entries,panel.legacyMenu,"cursor",0,0,"MENU")
        panel.memberMenu = DropDownList1
    end
end

local WIDTH, ROW_HEIGHT = 460, 23
local function Label(frame, x, y, width, size)
    local text = M.Widgets.Label(frame, "", size)
    text:SetPoint("TOPLEFT", x, y)
    text:SetWidth(width)
    text:SetHeight(ROW_HEIGHT)
    text:SetWordWrap(false)
    return text
end

local function Draw(section)
    local total = #section.data
    section.offset = math.min(section.offset, math.max(0, total - section.limit))
    local page = math.min(total, section.limit)
    section.title:SetText(section.caption .. "  ·  " .. total)
    section.range:SetText(total > page and ("%d–%d / %d"):format(section.offset + 1, section.offset + page, total) or "")
    section.empty:SetShown(total == 0)
    for i, row in ipairs(section.rows) do
        local data = i <= page and section.data[section.offset + i]
        row.member = data or nil
        row:SetShown(not not data)
        if data then
            row.name:SetText(data.name)
            local color = data.color
            row.name:SetTextColor(color and color.r or .94, color and color.g or .94, color and color.b or .94)
            row.level:SetText(data.level)
            row.detail:SetText(data.detail)
            if data.crossClient then row.detail:SetTextColor(.93,.74,.39)
            else row.detail:SetTextColor(.76,.81,.87) end
        end
    end
    section:SetHeight(52 + math.max(1, page) * ROW_HEIGHT)
end

local function Section(panel, caption, detailHeader)
    local frame = CreateFrame("Frame", nil, panel)
    frame:SetWidth(WIDTH - 24)
    frame:EnableMouseWheel(true)
    frame.caption, frame.rows, frame.offset, frame.data = caption, {}, 0, {}
    frame.title = Label(frame, 8, 0, 300, 15)
    frame.title:SetTextColor(1,.81,.39)
    frame.range = Label(frame, 318, 0, 110, 11)
    frame.range:SetJustifyH("RIGHT")
    frame.range:SetTextColor(.73,.77,.83)
    local header = frame:CreateTexture(nil,"BACKGROUND")
    header:SetPoint("TOPLEFT",0,-25);header:SetPoint("TOPRIGHT",0,-25)
    header:SetHeight(ROW_HEIGHT);header:SetColorTexture(.24,.29,.36,.78)
    local columns = {{8,165,Text("角色 ID","Character")},{180,38,"Lv"},{232,194,detailHeader}}
    for _, col in ipairs(columns) do
        local label = Label(frame,col[1],-25,col[2],12)
        label:SetText(col[3]);label:SetTextColor(.79,.85,.92)
    end
    frame.empty = Label(frame,8,-49,WIDTH-40,12)
    frame.empty:SetText(Text("暂无在线成员","No one online"))
    frame.empty:SetTextColor(.66,.71,.79)
    for i = 1, 10 do
        local row = CreateFrame("Button",nil,frame)
        row:SetPoint("TOPLEFT",0,-49-(i-1)*ROW_HEIGHT)
        row:SetSize(WIDTH-24,ROW_HEIGHT)
        row:RegisterForClicks("LeftButtonUp","RightButtonUp")
        local highlight = row:CreateTexture(nil,"HIGHLIGHT")
        highlight:SetAllPoints();highlight:SetColorTexture(.75,.83,1,.15)
        row:SetScript("OnClick",function(self, button)
            local member = self.member
            if not member then return end
            if button == "RightButton" then
                M:Safe("社交列表",OpenMemberMenu,panel,member)
            elseif button == "LeftButton" then
                local whisper = WhisperAction(member,MemberName(member))
                if whisper then M:Safe("社交列表",whisper) end
            end
        end)
        if i % 2 == 0 then
            local shade = row:CreateTexture(nil,"BACKGROUND")
            shade:SetAllPoints();shade:SetColorTexture(.75,.83,1,.055)
        end
        row.name = Label(row,8,0,165,13)
        row.level = Label(row,180,0,38,12)
        row.detail = Label(row,232,0,194,12)
        frame.rows[i] = row
    end
    frame:SetScript("OnMouseWheel",function(self, delta)
        self.offset = M.Clamp(self.offset-delta*3,0,math.max(0,#self.data-self.limit))
        Draw(self)
    end)
    return frame
end

local function BuildPanel()
    local panel = M.Widgets.Panel(UIParent)
    panel:SetPoint("TOPLEFT",UIParent,"TOPLEFT",8,-8)
    panel:SetWidth(WIDTH)
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:SetBackdropColor(.056,.071,.103,.98)
    panel:SetBackdropBorderColor(.56,.47,.31,1)
    panel.friends = Section(panel,Text("在线好友","Online friends"),Text("地区 / 客户端","Location / Client"))
    panel.guild = Section(panel,Text("公会在线成员","Guild online"),Text("地区","Location"))
    panel.friends:SetPoint("TOPLEFT",12,-11)
    panel.guild:SetPoint("TOPLEFT",panel.friends,"BOTTOMLEFT",0,-8)
    panel:Hide()
    return panel
end

local function SortByName(a,b)
    return a.name:lower() < b.name:lower()
end

local function SortGuild(a,b)
    if a.sortLevel ~= b.sortLevel then return a.sortLevel > b.sortLevel end
    return SortByName(a,b)
end

local function Refresh(panel)
    panel.friends.data, panel.guild.data = Friends(), Guild()
    table.sort(panel.friends.data,SortByName)
    table.sort(panel.guild.data,SortGuild)
    local limit = M.Clamp(math.floor((UIParent:GetHeight()-145)/(2*ROW_HEIGHT)),1,10)
    panel.friends.limit, panel.guild.limit = limit, limit
    Draw(panel.friends)
    Draw(panel.guild)
    panel:SetHeight(panel.friends:GetHeight()+panel.guild:GetHeight()+30)
end

local function IsHovered(frame)
    if M.Compat.MouseOver(frame) then return true end
    local left, bottom, width, height = frame:GetRect()
    if not left then return false end
    local x, y = GetCursorPosition()
    local scale = frame:GetEffectiveScale()
    x, y = x / scale, y / scale
    return x >= left and x <= left+width and y >= bottom and y <= bottom+height
end

local function RequestRosters()
    local requestFriends = (C_FriendList and C_FriendList.ShowFriends) or ShowFriends
    if requestFriends then pcall(requestFriends) end
    local requestGuild = (C_GuildInfo and C_GuildInfo.GuildRoster) or GuildRoster
    if requestGuild and IsInGuild and IsInGuild() then pcall(requestGuild) end
end

function S.Start()
    if S.watcher then return end
    local watcher = CreateFrame("Frame",nil,UIParent)
    S.watcher = watcher
    watcher:SetPoint("TOPLEFT",UIParent,"TOPLEFT")
    watcher:SetSize(34,34)
    watcher:EnableMouse(false)
    local panel, entered, leftAt
    local elapsed, refreshAt, requestAt = 0,0,0
    watcher:SetScript("OnUpdate",function(_, delta)
        elapsed = elapsed + delta
        if elapsed < .05 then return end
        elapsed = 0
        local now = GetTime()
        local corner = IsHovered(watcher)
        if panel and panel:IsShown() then
            if panel.memberMenu then
                if panel.memberMenu:IsShown() then leftAt = nil; return end
                panel.memberMenu = nil
            end
            if corner or IsHovered(panel) then leftAt = nil
            else leftAt = leftAt or now end
            if leftAt and now-leftAt >= .5 then
                panel:Hide()
            elseif now >= refreshAt then
                refreshAt = now+3
                M:Safe("社交列表",Refresh,panel)
            end
        elseif corner and not (IsMouseButtonDown and (IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton"))) then
            entered = entered or now
            if now-entered >= .25 then
                panel = panel or BuildPanel()
                panel.friends.offset, panel.guild.offset = 0,0
                M:Safe("社交列表",Refresh,panel)
                panel:Show()
                entered, leftAt, refreshAt = nil,nil,now+3
                if now >= requestAt and not InCombatLockdown() then
                    requestAt = now+10
                    RequestRosters()
                end
            end
        else entered = nil end
    end)
end
