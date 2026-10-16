local _,M=...
local W,R=M.Widgets,M.Renderer
local unpack=unpack or table.unpack
local private=M.EditorInternals
local mainAuraIcons=private.mainAuraIcons
local IsUnitComposite=private.IsUnitComposite
local HasDedicatedPreview=private.HasDedicatedPreview
local Selected=private.Selected
local InPreviewScope=private.InPreviewScope
local InMainPreview=private.InMainPreview
local PreviewModuleID=private.PreviewModuleID
local MainTextElement=private.MainTextElement
local MainPreviewSelection=private.MainPreviewSelection
local SetSelection=private.SetSelection
local fixedPortraitLevels={centerLevel=true,wa0b35e5bbc2=true,wa38ad2639d2=true}
local UpdatePreviewGrid=private.UpdatePreviewGrid

function M:FitPreview()
    local e=self.editor;local geo=self:Geometry();e.geometry=geo
    local minx,miny,maxx,maxy
    for _,n in ipairs(self.db.design.nodes) do
        if n.kind~="group" and n.kind~="hitbox" and
            ((e.mainPreview and InMainPreview(n)) or
            (not e.mainPreview and InPreviewScope(n,e.scope) and
            (not e.previewFocusID or self:IsChild(n.id,e.previewFocusID)))) then
            local g=geo[n.id]
            local width=n.autoWidth and e.view.nodes[n.id] and e.view.nodes[n.id].frame:GetWidth() or g.w
            local x1,y1,x2,y2=g.x-width*g.s/2,g.y-g.h*g.s/2,g.x+width*g.s/2,g.y+g.h*g.s/2
            minx=minx and math.min(minx,x1) or x1;miny=miny and math.min(miny,y1) or y1
            maxx=maxx and math.max(maxx,x2) or x2;maxy=maxy and math.max(maxy,y2) or y2
        end
    end
    minx,miny,maxx,maxy=minx or -100,miny or -100,maxx or 100,maxy or 100
    e.fit=UIParent:GetEffectiveScale()/math.max(.001,e.canvas:GetEffectiveScale())
    local selected=Selected()
    if PreviewModuleID(selected)=="bossFrames" then
        local left,bottom,right,top=M.BossFrames.VisibleBounds(geo)
        if left then minx,miny,maxx,maxy=left,bottom,right,top end
    end
    if HasDedicatedPreview(selected) and PreviewModuleID(selected)~="partyFrames" then
        local availableWidth=math.max(1,e.canvas:GetWidth()-40)
        local moduleID=PreviewModuleID(selected)
        local preserveSize=moduleID=="bossFrames" or moduleID=="chatButtons" or moduleID=="combatNotices"
        local availableHeight=math.max(1,(preserveSize and 200 or e.canvas:GetHeight())-40)
        local reference=moduleID=="bossFrames" and .4/math.max(.001,self.byID.bossFrames.scale or 1) or 1
        e.fit=e.fit*math.min(1,availableWidth/math.max(1,(maxx-minx)*reference),availableHeight/math.max(1,(maxy-miny)*reference))
    end
    local portrait=e.mainPreview and geo.wabc757f81ee
    local cast=HasDedicatedPreview(selected) and geo[e.previewFocusID or selected.id]
    if PreviewModuleID(selected)=="partyFrames" or PreviewModuleID(selected)=="bossFrames" then cast=nil end
    e.centerX,e.centerY=portrait and portrait.x or (cast and cast.x or (minx+maxx)/2),
        portrait and portrait.y or (cast and cast.y or (miny+maxy)/2)
    e.view.root:SetScale(e.fit);e.view.root:ClearAllPoints()
    e.view.root:SetPoint("CENTER",e.canvas,"CENTER",-e.centerX+(e.panX or 0)/e.fit,-e.centerY+(e.panY or 0)/e.fit)
end

function M:UpdateSelectionOutline()
    local e=self.editor
    if not e.mainPreview then e.outline:Hide();return end
    local n=Selected();local o=n and e.view.nodes[n.id]
    if n and n.id=="mainComposite" then e.outline:Hide();return end
    if not o then e.outline:Hide();return end
    local left,right,top,bottom=o.frame:GetLeft(),o.frame:GetRight(),o.frame:GetTop(),o.frame:GetBottom()
    if n.kind=="group" then
        left,right,top,bottom=nil,nil,nil,nil
        for _,child in ipairs(self.db.design.nodes) do
            if (self:IsChild(child.id,n.id) or (n.id=="mainComposite" and InMainPreview(child))) and child.kind~="group" then
                local v=e.view.nodes[child.id];local f=v and v.frame
                local frames=mainAuraIcons[child.id] and v and v.icons or {f}
                for _,part in ipairs(frames or {}) do
                    if part and part:IsVisible() and part:GetLeft() then
                        local s=part:GetEffectiveScale()/e.canvas:GetEffectiveScale()
                        local l,r,t,b=part:GetLeft()*s,part:GetRight()*s,part:GetTop()*s,part:GetBottom()*s
                        left=left and math.min(left,l) or l;right=right and math.max(right,r) or r;top=top and math.max(top,t) or t;bottom=bottom and math.min(bottom,b) or b
                    end
                end
            end
        end
    elseif left then
        local s=o.frame:GetEffectiveScale()/e.canvas:GetEffectiveScale();left,right,top,bottom=left*s,right*s,top*s,bottom*s
    end
    if not left then e.outline:Hide();return end
    e.outline:ClearAllPoints();e.outline:SetPoint("BOTTOMLEFT",e.canvas,"BOTTOMLEFT",left-e.canvas:GetLeft()-2,bottom-e.canvas:GetBottom()-2)
    e.outline:SetSize(math.max(6,right-left+4),math.max(6,top-bottom+4));e.outline:Show()
end

local function LayoutEditorPanels(e,party,previewHeight)
    local windowWidth,windowHeight=e.window:GetWidth(),e.window:GetHeight()
    local height=party and math.max(1,windowHeight-110)or previewHeight
    if e.partyLayout==party and e.previewHeight==height and e.layoutWidth==windowWidth and e.layoutHeight==windowHeight then return end
    e.partyLayout=party;e.previewHeight=height;e.layoutWidth=windowWidth;e.layoutHeight=windowHeight;e.refit=true
    local available=math.max(1,windowWidth-14-e.left:GetWidth()-8-14)
    local width=party and math.max(1,(available-8)/2)or available
    e.canvas:ClearAllPoints();e.right:ClearAllPoints()
    e.canvas:SetPoint("TOPLEFT",e.left,"TOPRIGHT",8,0)
    e.canvas:SetSize(width,height)
    if party then
        e.canvas:SetPoint("BOTTOMLEFT",e.left,"BOTTOMRIGHT",8,0)
        e.right:SetPoint("TOPLEFT",e.canvas,"TOPRIGHT",8,0)
        e.right:SetPoint("BOTTOMRIGHT",e.window,"BOTTOMRIGHT",-14,49)
        e.right:SetSize(width,height)
    else
        e.canvas:SetPoint("TOPRIGHT",e.window,"TOPRIGHT",-14,-61)
        e.right:SetPoint("TOPLEFT",e.canvas,"BOTTOMLEFT",0,-8)
        e.right:SetPoint("BOTTOMRIGHT",e.window,"BOTTOMRIGHT",-14,49)
        e.right:SetSize(width,math.max(1,windowHeight-110-height-8))
    end
    local propertyWidth=party and math.max(1,width-42)or 470
    e.propertyRatio=propertyWidth/470;e.props:SetWidth(propertyWidth);e.propTitle:SetWidth(propertyWidth)
    local seen={}
    for _,row in ipairs(e.propRows)do
        for _,entry in ipairs(row.controls)do
            local control=entry[1]
            if not seen[control]then
                seen[control]=true
                control.propertyLayoutWidth=control.propertyLayoutWidth or control:GetWidth()
                if control.propertyLayoutWidth>=180 then control:SetWidth(control.propertyLayoutWidth*e.propertyRatio)end
            end
        end
    end
    -- The module's only numeric field can use the whole settings column.
    e.fields.scale:SetWidth(party and propertyWidth-4 or e.fields.scale.propertyLayoutWidth)
    UpdatePreviewGrid(e,width,height)
end
function M:RefreshEditor(unchanged)
    local e=self.editor;if not e or not e.window:IsShown() or not e.canvas:IsShown() then return end
    e.scope="all";e.view.hidden={}
    local selected=Selected()
    e.bossPreview=selected and PreviewModuleID(selected)=="bossFrames" or false
    e.partyPreview=selected and PreviewModuleID(selected)=="partyFrames" or false
    if e.partyPreview then
        self.selection="partyFrames";self.multi={partyFrames=true};selected=self.byID.partyFrames
        e.drag=nil;e.pendingOverlap=nil
        if e.overlap then e.overlap:Hide()end
    end
    if e.bossPreview then
        self.selection="bossFrames";self.multi={bossFrames=true};selected=self.byID.bossFrames
        e.drag=nil;e.pendingOverlap=nil
        if e.overlap then e.overlap:Hide() end
    end
    e.mainPreview=MainPreviewSelection(selected)
    local previewHeight=e.mainPreview and 200 or 125
    LayoutEditorPanels(e,PreviewModuleID(selected)=="partyFrames",previewHeight)
    if e.previewDragHint then
        local showHint=selected~=nil and e.mainPreview
        local clickHint=showHint and selected.id=="mainComposite"
        e.previewDragHint:SetText(clickHint and "点击预览视窗中的元素可调节" or "预览视窗中各元素可拖动")
        e.previewDragHint:SetShown(showHint)
        if e.previewDragIcon then
            e.previewMouseMode=clickHint and "click" or "drag"
            e.previewDragIcon:SetShown(showHint and not clickHint)
            if e.previewClickIcon then e.previewClickIcon:SetShown(showHint and clickHint) end
        end
    end
    if e.previewDistanceHint then e.previewDistanceHint:SetShown(PreviewModuleID(selected)=="targetDistance") end
    if e.previewThreatHint then e.previewThreatHint:SetShown(PreviewModuleID(selected)=="targetThreat") end
    if e.previewChatHint then e.previewChatHint:SetShown(PreviewModuleID(selected)=="chatButtons") end
    if e.previewSystemHint then e.previewSystemHint:SetShown(PreviewModuleID(selected)=="systemMenu") end
    if e.restoreGroup then e.restoreGroup:SetShown(PreviewModuleID(selected)~=nil) end
    local isolated=(IsUnitComposite(selected) or HasDedicatedPreview(selected))
        and (e.scope=="all" or selected.scope==e.scope) and selected.id or nil
    if selected and PreviewModuleID(selected)=="bossFrames" and (e.scope=="all" or e.scope=="target") then isolated="bossFrames" end
    if selected and PreviewModuleID(selected)=="partyFrames" then isolated="partyFrames" end
    local focusID=e.mainPreview and "mainComposite" or isolated
    if e.previewFocusID~=focusID then
        e.previewFocusID=focusID;e.refit=true;e.panX=0;e.panY=0
    end
    for _,n in ipairs(self.db.design.nodes) do
        if e.mainPreview then
            if n.kind~="group" and not InMainPreview(n) then e.view.hidden[n.id]=true end
        elseif isolated then
            -- The isolated module can still be parented to shared layout groups.
            -- Keep that ancestor chain visible; hide the unrelated visuals.
            if n.id~=isolated and not self:IsChild(n.id,isolated)
                and not (n.kind=="group" and self:IsChild(isolated,n.id)) then e.view.hidden[n.id]=true end
        elseif not InPreviewScope(n,e.scope) and n.kind~="group" then e.view.hidden[n.id]=true end
    end
    e.view.selected=self.selection;e.view.scene=HasDedicatedPreview(selected) and "cast" or "normal"
    e.view.previewScope=focusID or e.scope
    R.Apply(e.view,self.db.design,unchanged==true)
    if e.mainPreview or HasDedicatedPreview(selected) or not e.fit or e.refit then self:FitPreview();e.refit=false end
    if e.previewXYIcon then
        local occupied=false
        for _,hint in ipairs({e.previewDragHint,e.previewDistanceHint,e.previewThreatHint,e.previewChatHint,e.previewSystemHint})do
            if hint:IsShown()then occupied=true;break end
        end
        if not occupied then
            local scale=e.input:GetEffectiveScale()
            local left,bottom=e.input:GetLeft(),e.input:GetBottom()
            if left and bottom then
                local x1,y1=(left+10)*scale,(bottom+10)*scale
                local x2,y2=x1+27*scale,y1+27*scale
                for _,o in pairs(e.view.nodes)do
                    local frame=o.frame
                    if o.spec.kind~="group" and o.spec.kind~="hitbox" and frame and frame:IsVisible()then
                        local l,r,t,b=frame:GetLeft(),frame:GetRight(),frame:GetTop(),frame:GetBottom()
                        local s=frame:GetEffectiveScale()
                        if l and r and t and b and l*s<x2 and r*s>x1 and b*s<y2 and t*s>y1 then occupied=true;break end
                    end
                end
            end
        end
        e.previewXYIcon:ClearAllPoints()
        e.previewXYIcon:SetPoint(occupied and "TOPLEFT" or "BOTTOMLEFT",e.input,occupied and "TOPLEFT" or "BOTTOMLEFT",10,occupied and -10 or 10)
        e.previewXYIcon:SetShown(PreviewModuleID(selected)~=nil)
    end
    self:RefreshTree();self:RefreshProperties();self:UpdateSelectionOutline()
    M.EditorUndo.Sync()
end

local function HitCandidates(e)
    if e.bossPreview or e.partyPreview then return {} end
    local x,y=GetCursorPosition();local result={}
    for _,n in ipairs(M.db.design.nodes) do
        local o=e.view.nodes[n.id];local f=o and o.frame
        if n.kind~="group" and n.kind~="hitbox" and not fixedPortraitLevels[n.id] and not n.locked and f and f:IsVisible() then
            local frames=mainAuraIcons[n.id] and o.icons or {f}
            for _,part in ipairs(frames or {}) do
                if part:IsVisible() then
                    local s=part:GetEffectiveScale();local l,r,t,b=part:GetLeft(),part:GetRight(),part:GetTop(),part:GetBottom()
                    if l and x>=l*s and x<=r*s and y>=b*s and y<=t*s then result[#result+1]=n;break end
                end
            end
        end
    end
    table.sort(result,function(a,b)return (a.layer or 0)>(b.layer or 0)end)
    local shown,collapsed={},{}
    for _,n in ipairs(result) do
        local item=n
        while item and item.internal and (not MainTextElement(item) or M:IsChild(item.id,"targetCast")) do
            item=M.byID[item.parent]
        end
        if item and not fixedPortraitLevels[item.id] and not item.locked and not shown[item.id] then collapsed[#collapsed+1]=item;shown[item.id]=true end
    end
    return collapsed
end
local function OverlapMenu(e,candidates)
    if e.overlap then e.overlap:Hide() end
    local p=W.Panel(e.window);e.overlap=p;p:SetFrameStrata("TOOLTIP");p:SetFrameLevel(9000)
    p:SetSize(335,math.min(350,#candidates*27+43));p:SetClampedToScreen(true)
    local x,y=GetCursorPosition();local s=p:GetEffectiveScale();p:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x/s-12,y/s-12)
    local title=W.Label(p,"选择元素（"..#candidates.."）",12);title:SetPoint("TOPLEFT",10,-8)
    local scroll,body=W.Scroll(p)
    scroll:SetPoint("TOPLEFT",7,-31);scroll:SetPoint("BOTTOMRIGHT",-25,7);body:SetWidth(300)
    for i,n in ipairs(candidates) do
        local b=W.Button(body,n.label,296,function()p:Hide();SetSelection(n.id)end)
        b:SetPoint("TOPLEFT",2,-(i-1)*27)
        b:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:AddLine(M:T(n.label),1,.82,0);GameTooltip:Show()
        end)
        b:SetScript("OnLeave",function()GameTooltip:Hide()end)
    end
    body:SetHeight(math.max(2,#candidates*27))
    p:EnableMouse(true);p:SetScript("OnLeave",function(self)if not self:IsMouseOver() then self:Hide() end end)
    p:SetScript("OnHide",function()if e.overlap==p then e.overlap=nil end;GameTooltip:Hide()end)
end


M.EditorInternals.LayoutEditorPanels=LayoutEditorPanels
M.EditorInternals.HitCandidates=HitCandidates
M.EditorInternals.OverlapMenu=OverlapMenu
