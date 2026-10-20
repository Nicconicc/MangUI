local name, M = ...
_G.MangUIUF = M
M.name, M.version = name, "1.0.558"
M.optionsTitle = "MangUI - V1.0.558 2026/10/20 1611"
M.errors, M.status = {}, "等待初始化"
M.ART = "Interface\\AddOns\\MangUI\\Assets\\"
M.MYRIAD = "Interface\\AddOns\\MangUI\\Assets\\Fonts\\Myriad.ttf"
M.units = {"player", "target", "pet", "targettarget", "focus"}
M.labels = {all="全部", player="玩家", target="目标", pet="宠物", targettarget="目标的目标", focus="焦点", shared="中央头像", decoration="外围特效"}

function M:Print(text)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc66MangUI|r " .. (self.T and self:T(text) or tostring(text))) end
end
function M:Report(stage, err)
    local line = stage .. ": " .. tostring(err)
    self.errors[#self.errors+1] = line
    self.status = "存在错误：" .. stage
    self:Print(line)
end
function M:Safe(stage, fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then self:Report(stage, result) end
    return ok, result
end
function M.Copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k,v in pairs(value) do copy[k] = type(v)=="table" and M.Copy(v) or v end
    return copy
end
function M.Clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
function M:CanEdit()
    if InCombatLockdown() then self:Print("战斗中暂不能修改布局，脱战后即可编辑。"); return false end
    return self.db ~= nil
end
function M:Open()
    if not self.db then self:Print("配置尚未就绪。输入 /mui status 查看加载状态。"); return end
    if not self.OpenDesigner then self:Report("设置", "Designer.lua 未载入"); return end
    self:Safe("打开设置", self.OpenDesigner, self)
end

-- Register the entry before loading any renderer or options code.
SLASH_MANGUIUF1, SLASH_MANGUIUF2 = "/mui", "/muf"
SlashCmdList.MANGUIUF = function(text)
    text = (text or ""):lower():match("^%s*(.-)%s*$")
    if text=="portrait" then
        if M.Portraits then M.Portraits.Report() end
    elseif text=="bosstest" or text:match("^bosstest%s") then
        if M.BossFrames then M.BossFrames.Test(text:match("^bosstest%s+(%S+)") or "") end
    elseif text=="profile" or text:match("^profile%s") then
        if M.ModuleProfiler then M.ModuleProfiler.Command(text:match("^profile%s+(%S+)") or "") end
    elseif text == "status" then
        local _, _, _, build = GetBuildInfo()
        M:Print("v"..M.version.." · 接口 "..tostring(build).." · "..M.status)
        M:Print("设置模块 "..(M.OpenDesigner and "已载入" or "缺失").." · 小地图 "..(M.minimap and "已创建" or "未创建"))
        for _,err in ipairs(M.errors) do M:Print(err) end
    elseif text == "icon" then
        if M.db then M.db.minimap.hide=false; M:CreateMinimap(); M.minimap:Show() end
    else M:Open() end
end

function M:CreateMinimap()
    if self.minimap then self.minimap.Position();self.minimap:SetShown(not self.db.minimap.hide); return end
    if not Minimap then return end
    local b = CreateFrame("Button", "MangUIUFMinimapButton", Minimap)
    self.minimap = b
    b:SetSize(32,32); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(Minimap:GetFrameLevel()+10)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp"); b:RegisterForDrag("LeftButton")
    local background=b:CreateTexture(nil,"BACKGROUND");background:SetSize(26,26);background:SetPoint("CENTER",b,"CENTER",0,0)
    background:SetColorTexture(27/255,25/255,26/255,1)
    local icon=b:CreateTexture(nil,"ARTWORK");icon:SetTexture("Interface\\AddOns\\MangUI\\Assets\\UI\\Logo.png");icon:SetAllPoints(background)
    local mask=b:CreateMaskTexture();mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(background);background:AddMaskTexture(mask);icon:AddMaskTexture(mask)
    b.logo,b.logoBackground,b.logoMask=icon,background,mask
    local ring=b:CreateTexture(nil,"OVERLAY"); ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); ring:SetSize(54,54); ring:SetPoint("TOPLEFT",0,0)
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local function Position()
        local a=math.rad(M.db.minimap.angle or 220)
        b:ClearAllPoints(); b:SetPoint("CENTER",Minimap,"CENTER",math.cos(a)*(Minimap:GetWidth()/2+10),math.sin(a)*(Minimap:GetHeight()/2+10))
    end
    b.Position=Position
    b:SetScript("OnDragStart",function(self)
        self.dragged=true
        self:SetScript("OnUpdate",function()
            local x,y=GetCursorPosition(); local cx,cy=Minimap:GetCenter(); local s=Minimap:GetEffectiveScale()
            M.db.minimap.angle=math.deg(math.atan2(y/s-cy,x/s-cx)); Position()
        end)
    end)
    b:SetScript("OnDragStop",function(self) self:SetScript("OnUpdate",nil) end)
    b:SetScript("OnClick",function(self) if self.dragged then self.dragged=nil; return end; M:Open() end)
    b:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_LEFT"); GameTooltip:AddLine(M:T("MangUI 单位框体"),1,.82,0)
        GameTooltip:AddLine(M:T("点击打开设计器；拖动调整按钮位置"),1,1,1); GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    Position(); b:SetShown(not self.db.minimap.hide)
end

local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED"); events:RegisterEvent("PLAYER_LOGIN"); events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("ADDON_ACTION_BLOCKED");events:RegisterEvent("ADDON_ACTION_FORBIDDEN")
local function Start()
    if M.started or not M.db then return end
    if InCombatLockdown() then M.pending=true; return end
    if not M.StartLive then M:Report("框体", "Live.lua 未载入"); return end
    local ok=M:Safe("创建单位框体",M.StartLive,M)
    if ok then M.started=true; M.status=#M.errors==0 and "运行中" or "运行中（有错误）" end
end
events:SetScript("OnEvent",function(_,event,arg,action)
    if (event=="ADDON_ACTION_BLOCKED" or event=="ADDON_ACTION_FORBIDDEN") and arg==name then
        M.blockedActions=M.blockedActions or {}
        local key=event..":"..tostring(action)
        if not M.blockedActions[key] then
            M.blockedActions[key]=true
            M:Report("客户端保护操作",tostring(action).." ("..event..")")
        end
    elseif event=="ADDON_LOADED" and arg==name then
        if M.InitStore then M:Safe("加载配置",M.InitStore,M) else M:Report("配置","Store.lua 未载入") end
        if M.db then M:Safe("小地图入口",M.CreateMinimap,M) end
        if M.db and M.RegisterSettingsEntry then M:Safe("系统设置入口",M.RegisterSettingsEntry,M) end
        if IsLoggedIn and IsLoggedIn() then Start() end
    elseif event=="ADDON_LOADED" then
        if M.db and M.RegisterSettingsEntry then M:Safe("系统设置入口",M.RegisterSettingsEntry,M) end
    elseif event=="PLAYER_LOGIN" then
        if M.RegisterSettingsEntry then M:Safe("系统设置入口",M.RegisterSettingsEntry,M) end
        Start(); M:Print("v"..M.version.." 已加载。/mui 打开设计器，小地图金色图标为入口。")
    elseif event=="PLAYER_REGEN_ENABLED" then
        Start()
        if M.pending and M.ApplyLive then M.pending=false; M:Safe("应用布局",M.ApplyLive,M) end
        if M.RefreshEditor then M:RefreshEditor() end
    end
end)
