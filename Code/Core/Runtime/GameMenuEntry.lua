local _,M=...
local function OpenFromMenu()
    if PlaySound and SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)end
    if GameMenuFrame and GameMenuFrame:IsShown()then
        if HideUIPanel then HideUIPanel(GameMenuFrame)else GameMenuFrame:Hide()end
    end
    if not (M.editor and M.editor.window:IsShown())then M:Open()end
end
local function VisibleButtons(menu)
    local buttons={}
    for _,child in ipairs({menu:GetChildren()})do
        if child~=M.gameMenuButton and child:GetObjectType()=="Button"and child:IsShown()and child:GetTop()then
            buttons[#buttons+1]=child
        end
    end
    table.sort(buttons,function(a,b)return a:GetTop()>b:GetTop()end)
    return buttons
end
local function LayoutLegacyMenu(menu)
    if InCombatLockdown()and menu.IsProtected and menu:IsProtected()then return end
    local buttons=VisibleButtons(menu)
    local addons,index
    for i,button in ipairs(buttons)do
        if button==GameMenuButtonAddons or button==GameMenuButtonAddOns or (ADDONS and button:GetText()==ADDONS)then addons,index=button,i;break end
    end
    if not addons then return end
    local lowest=buttons[#buttons]
    menu.mangUIBottomPadding=menu.mangUIBottomPadding or math.max(0,lowest:GetBottom()-menu:GetBottom())
    local button=M.gameMenuButton
    if not button then
        button=CreateFrame("Button","MangUIUFGameMenuButton",menu,"UIPanelButtonTemplate")
        button:SetText("MangUI");button:SetScript("OnClick",OpenFromMenu);M.gameMenuButton=button
        local text,source=button:GetFontString(),addons:GetFontString()
        if text and source then text:SetFont(source:GetFont())end
    end
    button:SetSize(addons:GetWidth(),addons:GetHeight())
    local nextButton=buttons[index+1]
    local gap=nextButton and addons:GetBottom()-nextButton:GetTop()or 1
    if gap<0 or gap>8 then gap=1 end
    gap=menu.mangUIRowGap or gap;menu.mangUIRowGap=gap
    button:ClearAllPoints();button:SetPoint("TOP",addons,"BOTTOM",0,-gap);button:Show()
    if nextButton then
        local anchors={};local alreadyInserted=false
        for i=1,nextButton:GetNumPoints()do
            local point,relative,relativePoint,x,y=nextButton:GetPoint(i)
            alreadyInserted=alreadyInserted or relative==button
            anchors[#anchors+1]={point,relative,relativePoint,x,y}
        end
        if not alreadyInserted then
            local found=false
            for _,anchor in ipairs(anchors)do if anchor[2]==addons then anchor[2]=button;found=true end end
            nextButton:ClearAllPoints()
            if found then for _,anchor in ipairs(anchors)do nextButton:SetPoint(unpack(anchor))end
            else nextButton:SetPoint("TOP",button,"BOTTOM",0,-gap)end
        end
    else lowest=button end
    local height=menu:GetTop()-lowest:GetBottom()+menu.mangUIBottomPadding
    if math.abs(menu:GetHeight()-height)>.01 then menu:SetHeight(height)end
end
function M:RegisterGameMenuEntry()
    local menu=GameMenuFrame
    if not menu or menu.mangUIEntryRegistered then return end
    if type(menu.AddButton)=="function"and hooksecurefunc then
        -- Modern menus rebuild their pooled buttons on every open. Insert via
        -- the native AddButton path so order, spacing and height stay native.
        hooksecurefunc(menu,"AddButton",function(self,label)
            if ADDONS and label==ADDONS then
                M.gameMenuButton=self:AddButton("MangUI",OpenFromMenu)
            end
        end)
        menu.mangUIEntryRegistered=true
        if menu:IsShown()and menu.InitButtons then menu:InitButtons()end
    else
        menu:HookScript("OnShow",function(self)LayoutLegacyMenu(self)end)
        if hooksecurefunc and type(GameMenuFrame_UpdateVisibleButtons)=="function"then
            hooksecurefunc("GameMenuFrame_UpdateVisibleButtons",function()if menu:IsShown()then LayoutLegacyMenu(menu)end end)
        end
        menu.mangUIEntryRegistered=true
        if menu:IsShown()then LayoutLegacyMenu(menu)end
    end
end
