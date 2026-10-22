local _,M=...
local registered=setmetatable({},{__mode="k"})
local button
local function OpenFromMenu()
    if PlaySound and SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)end
    if GameMenuFrame and GameMenuFrame:IsShown()then
        if HideUIPanel then HideUIPanel(GameMenuFrame)else GameMenuFrame:Hide()end
    end
    if not (M.editor and M.editor.window:IsShown())then M:Open()end
end
local function Points(frame)
    local anchors={}
    for i=1,frame:GetNumPoints()do
        local p,r,rp,x,y=frame:GetPoint(i)
        anchors[#anchors+1]={p,r or frame:GetParent(),rp,x or 0,y or 0}
    end
    return anchors
end
local function SetPoints(frame,anchors,shift,below)
    frame:ClearAllPoints()
    for _,a in ipairs(anchors)do
        -- A chain following an already-shifted button moves with that button.
        local dy=(shift and not below[a[2]])and shift or 0
        frame:SetPoint(a[1],a[2],a[3],a[4],a[5]-dy)
    end
end
local function Restore(menu,state)
    if state.anchors then
        for frame,anchors in pairs(state.anchors)do SetPoints(frame,anchors)end
        menu:SetHeight(state.height)
        state.anchors=nil;state.height=nil
    end
end
local function LayoutEntry(menu,nativeLayout)
    local state=registered[menu]
    if not state or state.busy or not menu:IsShown()then return end
    if InCombatLockdown()and menu.IsProtected and menu:IsProtected()then return end
    state.busy=true
    if nativeLayout then state.anchors=nil;state.height=nil else Restore(menu,state)end
    if button then button:Hide()end
    local buttons={}
    for _,child in ipairs({menu:GetChildren()})do
        if child:GetObjectType()=="Button"and child:IsShown()and child:GetTop()then buttons[#buttons+1]=child end
    end
    table.sort(buttons,function(a,b)return a:GetTop()*a:GetEffectiveScale()>b:GetTop()*b:GetEffectiveScale()end)
    local addons,index
    for i,child in ipairs(buttons)do
        if child==GameMenuButtonAddons or child==GameMenuButtonAddOns or (ADDONS and child:GetText()==ADDONS)then addons,index=child,i;break end
    end
    if addons then
        if not button then
            -- Keep the addon button OUTSIDE the native menu and its frame pool.
            -- AddButton/Reset/InitButtons and native callback scripts stay untouched.
            button=CreateFrame("Button","MangUIUFGameMenuButton",UIParent,menu.buttonTemplate or "UIPanelButtonTemplate")
            button:Hide();button:SetText("MangUI");button:SetScript("OnClick",OpenFromMenu)
            M.gameMenuButton=button
        end
        local scale=addons:GetEffectiveScale()
        button:SetScale(scale/UIParent:GetEffectiveScale())
        button:SetSize(addons:GetWidth(),addons:GetHeight())
        button:SetFrameStrata(menu:GetFrameStrata());button:SetFrameLevel(menu:GetFrameLevel()+10)
        local text,source=button:GetFontString(),addons:GetFontString()
        if text and source then text:SetFont(source:GetFont())end
        local nextButton=buttons[index+1]
        local gap=nextButton and (addons:GetBottom()*scale-nextButton:GetTop()*nextButton:GetEffectiveScale())/scale or 1
        if gap<0 or gap>8 then gap=menu.spacing or 1 end
        local stride=(addons:GetHeight()+gap)*scale
        state.anchors={};state.height=menu:GetHeight()
        local below={}
        for i=index+1,#buttons do below[buttons[i]]=true;state.anchors[buttons[i]]=Points(buttons[i])end
        for frame,anchors in pairs(state.anchors)do SetPoints(frame,anchors,stride/frame:GetEffectiveScale(),below)end
        menu:SetHeight(state.height+stride/menu:GetEffectiveScale())
        button:ClearAllPoints();button:SetPoint("TOP",addons,"BOTTOM",0,-gap);button:Show()
    end
    state.busy=false
end
local function SafeLayout(menu,nativeLayout)
    local ok,err=pcall(LayoutEntry,menu,nativeLayout)
    if not ok then
        local state=registered[menu];if state then state.busy=false end
        if button then button:Hide()end
        M:Report("Esc菜单入口",err)
    end
end
function M:RegisterGameMenuEntry()
    local menu=GameMenuFrame
    if not menu or registered[menu]then return end
    registered[menu]={}
    -- Post-layout hooks run after the native callbacks have been created.
    -- Never call the native menu's construction functions from addon code.
    if type(menu.Layout)=="function"and hooksecurefunc then
        hooksecurefunc(menu,"Layout",function(self)SafeLayout(self,true)end)
    elseif hooksecurefunc and type(GameMenuFrame_UpdateVisibleButtons)=="function"then
        hooksecurefunc("GameMenuFrame_UpdateVisibleButtons",function()SafeLayout(menu,true)end)
    end
    menu:HookScript("OnShow",function(self)
        local state=registered[self]
        state.refresh=state.refresh or CreateFrame("Frame",nil,UIParent)
        state.refresh:Show()
        state.refresh:SetScript("OnUpdate",function(driver)
            driver:Hide();driver:SetScript("OnUpdate",nil);SafeLayout(self,false)
        end)
    end)
    menu:HookScript("OnHide",function(self)
        if button then button:Hide()end
        local state=registered[self]
        if state.refresh then state.refresh:SetScript("OnUpdate",nil);state.refresh:Hide()end
        Restore(self,state)
    end)
    if menu:IsShown()then SafeLayout(menu,false)end
end
