local _,M=...
local W,R=M.Widgets,M.Renderer
local unpack=unpack or table.unpack
local private=M.EditorInternals
local moduleGroupColors=private.moduleGroupColors
local RoundOffset=private.RoundOffset
local Selected=private.Selected
local InMainPreview=private.InMainPreview
local PreviewModuleID=private.PreviewModuleID
local UpdatePreviewGrid=private.UpdatePreviewGrid
local HitCandidates=private.HitCandidates
local OverlapMenu=private.OverlapMenu
local UpdateModuleColors=private.UpdateModuleColors
local BuildProperties=private.BuildProperties

function M:OpenDesigner()
    if self.moveMode then self:StopFrameMoveMode(true);return end
    if self.editor then
        local f=self.editor.window
        if f:IsShown() then f:Hide() else f:Show();self:RefreshEditor() end
        return
    end
    local e={rows={},scope="all",panX=0,panY=0};self.editor=e
    e.groupColors={}
    for index,color in ipairs(moduleGroupColors) do e.groupColors[index]={index=index,color={unpack(color)}} end
    local f=CreateFrame("Frame","MangUIUFOptions",UIParent,"PortraitFrameTemplate");e.window=f
    f:Hide()
    f:SetSize(820,760);f:SetScale(math.min(1,(UIParent:GetWidth()-40)/820,(UIParent:GetHeight()-40)/760));f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG");f:SetFrameLevel(100);f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton");f:SetClampedToScreen(false)
    f:SetToplevel(true)
    f:HookScript("OnShow",function(self)
        local stack=_G.MangUIOptionsWindowStack
        if stack then stack:Register(self) end
    end)
    f:SetScript("OnDragStart",function(self)self:StartMoving()end);f:SetScript("OnDragStop",function(self)self:StopMovingOrSizing()end)
    if f.Bg then f.Bg:SetColorTexture(.12,.12,.13,.8) end
    local frameName=f.GetName and f:GetName() or "MangUIUFOptions"
    local nativeTitle=f.TitleText or (f.TitleContainer and f.TitleContainer.TitleText) or _G[frameName.."TitleText"]
    if not nativeTitle then
        nativeTitle=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        nativeTitle:SetPoint("TOP",0,-5)
    end
    nativeTitle:SetText(self.optionsTitle);nativeTitle:SetTextColor(1,.82,0)
    local portrait=f.Portrait or _G[frameName.."Portrait"] or (f.PortraitContainer and f.PortraitContainer.portrait) or f.portrait
    if portrait then
        -- Keep each native template's opening. Titan's legacy ring uses the
        -- existing alignment confirmed in that client.
        if M.Compat.interface==38001 and not f.PortraitContainer then
            portrait:ClearAllPoints()
            portrait:SetPoint("TOPLEFT",f,"TOPLEFT",-10,11)
        end
        local parent=portrait:GetParent()
        local opening=(f.PortraitContainer and f.PortraitContainer.CircleMask) or f.CircleMask or portrait
        local background=parent:CreateTexture(nil,"OVERLAY",nil,-2)
        background:SetAllPoints(opening);background:SetColorTexture(27/255,25/255,26/255,1)
        local logo=parent:CreateTexture(nil,"OVERLAY",nil,-1)
        -- Show only the central medallion in the native portrait opening.
        logo:SetTexture("Interface\\AddOns\\MangUI\\Assets\\UI\\SettingsMedallion.png");logo:SetTexCoord(.22,.78,.215,.775)
        logo:SetAllPoints(background)
        local mask=parent:CreateMaskTexture()
        mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(background);background:AddMaskTexture(mask);logo:AddMaskTexture(mask)
        portrait:Hide()
        e.logo,e.logoBackground,e.logoMask=logo,background,mask
    end
    local nativeClose=f.CloseButton or _G[frameName.."CloseButton"]
    if nativeClose then nativeClose:SetScript("OnClick",function()f:Hide()end) end
    UISpecialFrames=UISpecialFrames or {};table.insert(UISpecialFrames,"MangUIUFOptions")
    M.FooterLinks.Attach(e)
    e.status=W.Label(f,"",11);e.status:SetPoint("BOTTOMLEFT",18,18);e.status:SetWidth(680);e.status:SetTextColor(.7,.75,.8)
    M.CPUUsage.Attach(e)
    e.designTab=W.Tab(f,"设计",function()if M.general then M.general:Hide()end;e.designTab:SetActive(true);e.generalTab:SetActive(false);M:RefreshEditor()end);e.designTab:SetPoint("TOPLEFT",72,-36);e.designTab:SetActive(true)
    e.generalTab=W.Tab(f,"其他",function()M:OpenGeneral()end);e.generalTab:SetPoint("LEFT",e.designTab,"RIGHT",4,0)
    e.left=W.Panel(f);e.left:SetPoint("TOPLEFT",14,-61);e.left:SetPoint("BOTTOMLEFT",14,49);e.left:SetWidth(245)
    e.left:SetBackdropColor(.12,.12,.13,.6)
    e.canvas=W.Panel(f);e.canvas:SetPoint("TOPLEFT",e.left,"TOPRIGHT",8,0);e.canvas:SetPoint("TOPRIGHT",f,"TOPRIGHT",-14,-61);e.canvas:SetHeight(200);e.previewHeight=200
    e.canvas:SetBackdropColor(.035,.04,.05,.6);e.canvas:SetClipsChildren(true)
    e.gridFrame=CreateFrame("Frame",nil,e.canvas)
    e.gridFrame:SetAllPoints(e.canvas);e.gridFrame:SetFrameLevel(e.canvas:GetFrameLevel()+1)
    e.gridFrame:EnableMouse(false)
    e.gridLines={}
    e.canvas:SetScript("OnSizeChanged",function(_,width,height)UpdatePreviewGrid(e,width,height)end)
    e.canvas:SetScript("OnShow",function()UpdatePreviewGrid(e)end)
    UpdatePreviewGrid(e)
    e.right=W.Panel(f);e.right:SetPoint("TOPLEFT",e.canvas,"BOTTOMLEFT",0,-8);e.right:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-14,49)
    e.right:SetBackdropColor(.12,.12,.13,.6)
    e.view=R.New(e.canvas,true)
    e.unlockMove=CreateFrame("Button",nil,e.left);e.unlockMove:SetSize(211,32);e.unlockMove:SetPoint("TOPLEFT",9,-12)
    e.unlockMove.base=e.unlockMove:CreateTexture(nil,"BACKGROUND");e.unlockMove.base:SetAllPoints()
    e.unlockMove.base:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp")
    e.unlockMove.base:SetBlendMode("ADD");e.unlockMove.base:SetVertexColor(.7,.7,.7,.18)
    e.unlockMove.icon=e.unlockMove:CreateTexture(nil,"OVERLAY");e.unlockMove.icon:SetSize(28.8,28.8)
    e.unlockMove.icon:SetAtlas("GM-icon-visible-hover",false)
    e.unlockMove.label=W.Label(e.unlockMove,"解锁移动模式",13);e.unlockMove.label:SetPoint("CENTER")
    M:FitLocaleText(e.unlockMove.label,155,9)
    e.unlockMove.icon:SetPoint("RIGHT",e.unlockMove.label,"LEFT",-6,0)
    e.unlockMove:SetScript("OnClick",function()M:StartUnlockedMoveMode()end)
    e.unlockMove:SetScript("OnEnter",function(self)self.base:SetVertexColor(.85,.85,.85,.28)end)
    e.unlockMove:SetScript("OnLeave",function(self)self.base:SetVertexColor(.7,.7,.7,.18)end)
    e.unlockMove.bottomEdge=e.unlockMove:CreateTexture(nil,"BORDER")
    e.unlockMove.bottomEdge:SetColorTexture(.45,.45,.45,.075);e.unlockMove.bottomEdge:SetHeight(1)
    e.unlockMove.bottomEdge:SetPoint("BOTTOMLEFT");e.unlockMove.bottomEdge:SetPoint("BOTTOMRIGHT")
    e.unlockMove.topEdge=e.unlockMove:CreateTexture(nil,"BORDER")
    e.unlockMove.topEdge:SetColorTexture(.45,.45,.45,.075);e.unlockMove.topEdge:SetHeight(1)
    e.unlockMove.topEdge:SetPoint("TOPLEFT");e.unlockMove.topEdge:SetPoint("TOPRIGHT")
    e.tree,e.treeContent=W.Scroll(e.left);e.tree:SetPoint("TOPLEFT",9,-56);e.tree:SetPoint("BOTTOMRIGHT",-29,12);e.treeContent:SetWidth(211)
    e.treeContent:SetScript("OnUpdate",function(_,elapsed)UpdateModuleColors(e,elapsed)end)
    BuildProperties(e)
    -- The main player/target composite supports local preview dragging.
    e.input=CreateFrame("Frame",nil,e.canvas);e.input:SetAllPoints();e.input:SetFrameLevel(5000);e.input:EnableMouse(true)
    e.previewXYIcon=e.gridFrame:CreateTexture(nil,"OVERLAY")
    e.previewXYIcon:SetTexture("Interface\\AddOns\\MangUI\\Assets\\UI\\PreviewXY.tga")
    e.previewXYIcon:SetSize(27,27);e.previewXYIcon:Hide()
    e.previewDragHint=W.Label(e.input,"预览视窗中各元素可拖动",11)
    e.previewDragHint:SetPoint("BOTTOMLEFT",10,10)
    e.previewDragHint:SetTextColor(.7,.75,.8);e.previewDragHint:Hide()
    e.previewDistanceHint=W.Label(e.input,"超出设定距离：姓名板显示红叉，头像旋转内环变红。",11)
    e.previewDistanceHint:SetPoint("BOTTOMLEFT",10,10)
    e.previewDistanceHint:SetPoint("BOTTOMRIGHT",-10,10)
    e.previewDistanceHint:SetJustifyH("LEFT");e.previewDistanceHint:SetWordWrap(true)
    e.previewDistanceHint:SetTextColor(.7,.75,.8);e.previewDistanceHint:Hide()
    e.previewThreatHint=W.Label(e.input,"目标仇恨：T=100%，近战110%/远程130% OT，随仇恨变色。",11)
    e.previewThreatHint:SetPoint("BOTTOMLEFT",10,10)
    e.previewThreatHint:SetPoint("BOTTOMRIGHT",-140,10)
    e.previewThreatHint:SetJustifyH("LEFT");e.previewThreatHint:SetWordWrap(false)
    e.previewThreatHint:SetTextColor(.7,.75,.8);e.previewThreatHint:Hide()
    e.previewChatHint=W.Label(e.input,"点击切换聊天频道；团长/助理可发起职责确认、就位确认和倒计时。",11)
    e.previewChatHint:SetPoint("BOTTOMLEFT",10,10)
    e.previewChatHint:SetPoint("BOTTOMRIGHT",-140,10)
    e.previewChatHint:SetJustifyH("LEFT");e.previewChatHint:SetWordWrap(false)
    e.previewChatHint:SetTextColor(.7,.75,.8);e.previewChatHint:Hide()
    e.previewSystemHint=W.Label(e.input,"鼠标移至屏幕顶端，显示功能菜单。",11)
    e.previewSystemHint:SetPoint("BOTTOMLEFT",10,10)
    e.previewSystemHint:SetPoint("BOTTOMRIGHT",-140,10)
    e.previewSystemHint:SetJustifyH("LEFT");e.previewSystemHint:SetWordWrap(false)
    e.previewSystemHint:SetTextColor(.7,.75,.8);e.previewSystemHint:Hide()
    e.previewDragIcon=e.input:CreateTexture(nil,"OVERLAY")
    e.previewDragIcon:SetAtlas("newplayertutorial-icon-mouse-turn",true)
    local ulx,uly,llx,lly,urx,ury,lrx,lry=e.previewDragIcon:GetTexCoord()
    e.previewDragIcon:SetTexCoord(urx,ury,lrx,lry,ulx,uly,llx,lly)
    local mouseWidth,mouseHeight=math.max(1,e.previewDragIcon:GetWidth()),math.max(1,e.previewDragIcon:GetHeight())
    local mouseScale=math.min(56/mouseWidth,40/mouseHeight)
    e.previewDragIcon:SetSize(mouseWidth*mouseScale,mouseHeight*mouseScale)
    e.previewDragIcon:SetPoint("BOTTOMLEFT",e.previewDragHint,"TOPLEFT",0,6);e.previewDragIcon:Hide()
    e.previewClickIcon=e.input:CreateTexture(nil,"OVERLAY")
    e.previewClickIcon:SetAtlas("newplayertutorial-icon-mouse-leftbutton",true)
    local clickWidth,clickHeight=math.max(1,e.previewClickIcon:GetWidth()),math.max(1,e.previewClickIcon:GetHeight())
    local clickScale=math.min(56/clickWidth,40/clickHeight)
    e.previewClickIcon:SetSize(clickWidth*clickScale,clickHeight*clickScale)
    e.previewClickIcon:SetPoint("BOTTOMLEFT",e.previewDragHint,"TOPLEFT",0,6);e.previewClickIcon:Hide()
    e.previewMouseMode="drag"
    e.restoreGroup=W.Button(e.input,"恢复默认",112,function()
        local id=PreviewModuleID(Selected())
        local group=id and M.byID[id]
        if not group or not M:CanEdit() then return end
        W.Confirm(f,"恢复“"..group.label.."”的默认布局？只会重置当前框体。",function()M:ResetPreviewModule(id)end)
    end)
    e.restoreGroup:SetHoverTextColor(1,.82,0)
    e.restoreGroup:SetTextCenterOffset(0,-2)
    e.restoreGroup:SetPoint("BOTTOMRIGHT",-10,12)
    e.restoreGroup:SetFrameLevel(e.input:GetFrameLevel()+10)
    M.EditorUndo.Attach(e)
    local function SelectForPreview(n,startX,startY)
        if IsShiftKeyDown() then M.multi=M.multi or {};M.multi[n.id]=not M.multi[n.id];M.selection=n.id
        else M.multi={[n.id]=true};M.selection=n.id end
        M:RefreshEditor()
        if e.mainPreview and InMainPreview(n) and n.id~="wabc757f81ee" and M:CanEdit() then
            local parent=e.view.nodes[n.parent] and e.view.nodes[n.parent].frame
            local object=e.view.nodes[n.id]
            local scale=(n.id=="centerFire" or n.id=="waf24f8d43e3" or n.id=="centerClassification" or n.valueTextOriginRevision==1 or n.resourceOriginRevision==1 or n.auraOriginRevision==1 or n.castOriginRevision==1) and parent and parent:GetEffectiveScale()
                or object and object.frame:GetEffectiveScale()
            if scale and scale>0 then
                local x,y=GetCursorPosition()
                e.drag={id=n.id,startX=startX or x,startY=startY or y,x=n.x or 0,y=n.y or 0,scale=scale}
            end
        end
    end
    e.input:SetScript("OnMouseDown",function(_,button)
        if e.bossPreview or e.partyPreview then return end
        if button~="LeftButton" and button~="RightButton" then return end
        local candidates=HitCandidates(e)
        if button=="RightButton" then if #candidates>0 then OverlapMenu(e,candidates) end;return end
        e.pendingOverlap=nil
        if #candidates==0 then return end
        if #candidates>1 then
            local x,y=GetCursorPosition()
            e.pendingOverlap={candidates=candidates,x=x,y=y}
            return
        end
        SelectForPreview(candidates[1])
    end)
    e.input:SetScript("OnMouseUp",function(_,button)
        if button~="LeftButton" then return end
        if e.pendingOverlap then
            local pending=e.pendingOverlap;e.pendingOverlap=nil
            OverlapMenu(e,pending.candidates)
        elseif e.drag then e.drag=nil;M:Commit() end
    end)
    local outline=CreateFrame("Frame",nil,e.input,"BackdropTemplate");e.outline=outline
    outline:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16});outline:SetBackdropBorderColor(1,1,1,1);outline:EnableMouse(false)
    e.input:SetScript("OnUpdate",function()
        local pending=e.pendingOverlap
        if pending and IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
            e.pendingOverlap=nil
        elseif pending then
            local x,y=GetCursorPosition()
            if (x-pending.x)^2+(y-pending.y)^2>25 then
                local chosen=pending.candidates[1]
                for _,candidate in ipairs(pending.candidates) do
                    if candidate.id==M.selection then chosen=candidate;break end
                end
                e.pendingOverlap=nil
                SelectForPreview(chosen,pending.x,pending.y)
            end
        end
        local drag=e.drag
        if drag then
            if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
                e.drag=nil;M:Commit()
            else
                local n=M.byID[drag.id];local o=n and e.view.nodes[n.id]
                if n and o then
                    local x,y=GetCursorPosition()
                    local nx=RoundOffset(drag.x+(x-drag.startX)/drag.scale)
                    local ny=M.MainBarLayout.parts[n.id] and drag.y
                        or RoundOffset(drag.y+(y-drag.startY)/drag.scale)
                    nx=M.SettingRanges.Clamp(n,"x",nx);ny=M.SettingRanges.Clamp(n,"y",ny)
                    if nx~=n.x or ny~=n.y then
                        n.x=nx;n.y=ny
                        R.Position(e.view,o.frame,n,o.geometryParent)
                        M:UpdateSelectionOutline()
                    end
                end
            end
        end
        R.Animate(e.view)
    end)
    f:SetScript("OnHide",function()
        e.pendingOverlap=nil
        if e.drag then e.drag=nil;M:Commit() end
        if e.overlap then e.overlap:Hide() end
        if M.mediaWindow then M.mediaWindow:Hide() end
        if M.materialWindow then M.materialWindow:Hide() end
        if M.fontWindow then M.fontWindow:Hide() end
        if M.general then M.general:Hide() end
        if M.configDialog then M.configDialog:Hide() end
        M.EditorUndo.Clear()
    end)
    self.selection=self.selection or "mainComposite";f:Show();self:RefreshEditor()
end
