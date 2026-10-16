local _,M=...
local function CloseNativePanel(frame)
    if not frame or not frame:IsShown() then return end
    if HideUIPanel then HideUIPanel(frame) else frame:Hide() end
end
function M:RegisterSettingsEntry()
    if self.settingsCategory or not self.db then return end
    local modern=Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory
    if not modern and not InterfaceOptions_AddCategory then return end
    local panel=self.settingsEntry
    if not panel then
        panel=CreateFrame("Frame","MangUIUFSettingsEntry",UIParent)
        panel.name="MangUI";panel:Hide();self.settingsEntry=panel
        local content=CreateFrame("Frame",nil,panel)
        content:SetPoint("CENTER",panel,"CENTER",0,0);panel.content=content
        local logo=content:CreateTexture(nil,"ARTWORK")
        logo:SetTexture("Interface\\AddOns\\MangUI\\Assets\\UI\\Logo.png")
        -- Crop only transparent padding, preserving the visible Logo's proportions.
        logo:SetTexCoord(21/256,231/256,27/256,232/256)
        logo:SetSize(140*210/205,140);panel.logo=logo
        local title=content:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
        title:SetFont(self.MYRIAD,36,"OUTLINE");title:SetText("MangUI");title:SetTextColor(1,.82,0)
        local version=content:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
        version:SetTextColor(1,1,1)
        local instructions=content:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
        instructions:SetTextColor(1,1,1)
        title:SetJustifyH("CENTER");version:SetJustifyH("CENTER");instructions:SetJustifyH("CENTER")
        local button=CreateFrame("Button",nil,content,"UIPanelButtonTemplate")
        button:SetSize(300,44)
        panel.title,panel.version,panel.instructions,panel.openButton=title,version,instructions,button
        local function Layout()
            local parts={logo,title,version,instructions,button}
            local gaps={14,28,14,24}
            local heights={logo:GetHeight(),title:GetStringHeight(),version:GetStringHeight(),instructions:GetStringHeight(),button:GetHeight()}
            local height=0
            for i,h in ipairs(heights) do height=height+h+(gaps[i] or 0) end
            local width=math.max(logo:GetWidth(),title:GetStringWidth(),version:GetStringWidth(),instructions:GetStringWidth(),button:GetWidth())
            content:SetSize(width,height)
            -- Fit short legacy options pages while keeping the complete group centered.
            content:SetScale(math.min(1,math.max(1,panel:GetWidth()-32)/width,math.max(1,panel:GetHeight()-32)/height))
            local top=height/2
            for i,part in ipairs(parts) do
                part:ClearAllPoints();part:SetPoint("CENTER",content,"CENTER",0,top-heights[i]/2)
                top=top-heights[i]-(gaps[i] or 0)
            end
        end
        local function Refresh()
            local font=M:DefaultFontPath()
            version:SetFont(font,16,"");version:SetText(M:T("版本：")..M.version)
            instructions:SetFont(font,16,"");instructions:SetText(M:T("输入 /mui 打开选项"))
            button:SetText(M:T("打开选项"))
            local label=button:GetFontString()
            if label then label:SetFont(font,22,"") end
            Layout()
            if C_Timer and C_Timer.After and not panel.layoutQueued then
                panel.layoutQueued=true
                C_Timer.After(0,function()panel.layoutQueued=nil;Layout()end)
            end
        end
        panel:SetScript("OnSizeChanged",Layout)
        panel:SetScript("OnShow",Refresh);Refresh()
        button:SetScript("OnClick",function()
            CloseNativePanel(SettingsPanel);CloseNativePanel(InterfaceOptionsFrame);CloseNativePanel(GameMenuFrame)
            -- This entry opens the existing panel; an already open panel stays open.
            if not (M.editor and M.editor.window:IsShown()) then M:Open() end
        end)
        panel.OnCommit=function()end;panel.OnDefault=function()end;panel.OnRefresh=Refresh
        panel.refresh=Refresh
    end
    if modern then
        local category=Settings.RegisterCanvasLayoutCategory(panel,"MangUI")
        Settings.RegisterAddOnCategory(category);self.settingsCategory=category
    else
        InterfaceOptions_AddCategory(panel);self.settingsCategory=panel
    end
end
