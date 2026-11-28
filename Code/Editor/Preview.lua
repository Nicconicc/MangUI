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
local monitorPreview={
    playerSkillMonitor={list="monitors",slots="skillIcons"},
    playerOtherMonitor={list="otherMonitors",slots="otherIcons"},
    receivedBuffs={list="monitors",slots="buffIcons"},
    raidVulnerability={list="raidVulnerability",slots="buffIcons"},
    raidBuffs={list="raidBuffs",slots="buffIcons"},
    commonItems={list="commonItems",slots="itemIcons"},
}

local function SkillInsertion(group,targetIndex,x,center)
    local onLeft=x<center
    local reversed=M.PlayerSkillMonitor.Direction(group)=="LEFT"
    local before=onLeft~=reversed
    return targetIndex+(before and 0 or 1),onLeft and "LEFT" or "RIGHT"
end

local function MonitorTarget(e,drag)
    local group=Selected()
    local chat=group and group.id=="chatButtons"
    local config=group and monitorPreview[group.id]
    local list=chat and group.buttonOrder or config and group[config.list]
    if not list or (drag and (drag.group~=group or drag.list~=list))then return end
    local object=e.view.nodes[chat and "chatButtonsRow" or group.id.."Icons"]
    if not object then return end
    local x,y=GetCursorPosition();local scale=e.input:GetEffectiveScale()
    if chat and drag and drag.startX then
        local left,right,bottom,top=e.input:GetLeft(),e.input:GetRight(),e.input:GetBottom(),e.input:GetTop()
        if not left or x<left*scale or x>right*scale or y<bottom*scale or y>top*scale then return end
        local pitch=((group.iconSize or 64)+(group.buttonSpacing or -20))*object.frame:GetEffectiveScale()
        if pitch<=0 then return end
        local index=M.Clamp(drag.index+math.floor((x-drag.startX)/pitch+.5),1,#list)
        local key=list[index]
        local item=object.chatButtonsByKey[key]
        return {group=group,list=list,entry=key,slot=item.frame,index=index,texture=item.texture}
    end
    x,y=x/scale,y/scale
    if not e.input:GetLeft() or x<e.input:GetLeft() or x>e.input:GetRight()
        or y<e.input:GetBottom() or y>e.input:GetTop() then return end
    local indices={}
    for i,entry in ipairs(list)do indices[entry]=i end
    local best,distance
    local slots=chat and object.chatButtons or object[config.slots]
    for _,item in ipairs(slots or {})do
        local slot=chat and item.frame or item
        local entry=chat and item.definition.key or item.entry
        local index=entry and (indices[entry] or (not chat and indices[entry.source]))
        if index and slot:IsVisible() then
            local left,right,top,bottom=slot:GetLeft(),slot:GetRight(),slot:GetTop(),slot:GetBottom()
            local ratio=slot:GetEffectiveScale()/scale
            if left then
                left,right,top,bottom=left*ratio,right*ratio,top*ratio,bottom*ratio
                local center=(left+right)/2
                local gap=math.abs(x-center)
                local inBand=group.id~="playerSkillMonitor" or (y>=bottom-12 and y<=top+12)
                if ((drag and inBand) or (x>=left and x<=right and y>=bottom and y<=top)) and (not distance or gap<distance)then
                    best,distance={group=group,list=list,entry=list[index],slot=slot,index=index,texture=item.texture},gap
                    if drag and group.id=="playerSkillMonitor" then
                        best.insertIndex,best.insertSide=SkillInsertion(group,index,x,center)
                    end
                end
            end
        end
    end
    return best
end

local function SkillDragHasMoved(drag)
    local x,y=GetCursorPosition()
    return drag.moved or (x-drag.clickX)^2+(y-drag.clickY)^2>25
end

local function UpdateMonitorHighlight(e)
    local drag=e.monitorDrag
    local isSkillDrag=drag and drag.group.id=="playerSkillMonitor"
    if isSkillDrag then drag.moved=SkillDragHasMoved(drag)end
    local moving=drag and (not isSkillDrag or drag.moved)
    local target=MonitorTarget(e,moving and drag or nil)
    if moving and e.monitorGhost then
        local x,y=GetCursorPosition();local scale=e.monitorGhost:GetEffectiveScale()
        e.monitorGhost:ClearAllPoints()
        e.monitorGhost:SetPoint("CENTER",UIParent,"BOTTOMLEFT",(x+drag.offsetX)/scale,(y+drag.offsetY)/scale)
        drag.slot:SetAlpha(.3)
        e.monitorGhost:Show()
    end
    local glow=e.monitorGlow
    local insert=e.monitorInsert
    local showLine=moving and isSkillDrag and target and target.insertSide
    if insert then
        if showLine then
            local side=target.insertSide
            local inset=side=="LEFT" and -2 or 2
            local level=target.slot:GetFrameLevel()+32
            if insert:GetFrameLevel()~=level then insert:SetFrameLevel(level)end
            insert:ClearAllPoints()
            insert:SetPoint("TOP",target.slot,"TOP"..side,inset,3)
            insert:SetPoint("BOTTOM",target.slot,"BOTTOM"..side,inset,-3)
        end
        insert:SetShown(not not showLine)
    end
    if target and not (isSkillDrag and moving) then
        local level=target.slot:GetFrameLevel()+32
        if glow:GetFrameLevel()~=level then glow:SetFrameLevel(level)end
        glow:ClearAllPoints();glow:SetPoint("TOPLEFT",target.slot,"TOPLEFT",-1,1)
        glow:SetPoint("BOTTOMRIGHT",target.slot,"BOTTOMRIGHT",1,-1)
        glow:Show()
    else
        glow:Hide()
    end
end

local function BeginMonitorDrag(e,target)
    local slot,ghost=target.slot,e.monitorGhost
    local icon=target.texture
    local scale=slot:GetEffectiveScale()
    local x,y=GetCursorPosition();local cx,cy=slot:GetCenter()
    if target.group.id=="chatButtons" then target.startX=x end
    target.clickX,target.clickY=x,y
    target.offsetX,target.offsetY=cx and cx*scale-x or 0,cy and cy*scale-y or 0
    target.alpha=slot:GetAlpha()
    e.monitorDrag=target
    ghost:SetSize(slot:GetWidth()*scale/ghost:GetEffectiveScale(),slot:GetHeight()*scale/ghost:GetEffectiveScale())
    ghost.texture:SetTexture(M:TextureFile(icon and icon:GetTexture() or 134400))
    if icon then ghost.texture:SetTexCoord(icon:GetTexCoord())else ghost.texture:SetTexCoord(0,1,0,1)end
    UpdateMonitorHighlight(e)
end

local function CancelMonitorDrag(e)
    local drag=e.monitorDrag
    if drag and drag.alpha then drag.slot:SetAlpha(drag.alpha)end
    e.monitorDrag=nil
    if e.monitorGhost then e.monitorGhost:Hide()end
    if e.monitorInsert then e.monitorInsert:Hide()end
end

local function EndMonitorDrag(e)
    local drag=e.monitorDrag
    if not drag then return end
    local skill=drag.group.id=="playerSkillMonitor"
    local moving=not skill or SkillDragHasMoved(drag)
    local target=MonitorTarget(e,moving and drag or nil)
    CancelMonitorDrag(e)
    if not target or drag.list[drag.index]~=drag.entry or not M:CanEdit()then return end
    if skill and not moving then
        if target.entry==drag.entry then
            e.skillEntry=drag.entry;e.propScroll:SetVerticalScroll(0)
            M:RefreshEditor(true)
        end
        return
    end
    local index=target.index
    if target.insertIndex then
        index=target.insertIndex-(target.insertIndex>drag.index and 1 or 0)
    end
    if index==drag.index then return end
    table.remove(drag.list,drag.index);table.insert(drag.list,index,drag.entry)
    M:Commit()
end

local function StartChatDrag(e,handle)
    local group=Selected()
    if e.monitorDrag or not group or group.id~="chatButtons" then return end
    local item=handle and handle.chatSlot
    if item then
        local list=group.buttonOrder
        local key=item.definition.key
        for index,entry in ipairs(list) do
            if entry==key then
                if M:CanEdit() then
                    BeginMonitorDrag(e,{group=group,list=list,entry=key,slot=item.frame,index=index,texture=item.texture})
                end
                return
            end
        end
    else
        local target=MonitorTarget(e)
        if target and M:CanEdit() then BeginMonitorDrag(e,target) end
    end
end

local function ChatDragMouseEvent(e,event,button)
    if button~="LeftButton" or not e.input:IsVisible() or M.selection~="chatButtons" then return end
    if event=="GLOBAL_MOUSE_UP" then
        EndMonitorDrag(e)
        return
    end
    if e.monitorDrag then return end
    for _,toggle in ipairs(e.chatToggles or {}) do
        if toggle:IsVisible() and toggle.IsMouseOver and toggle:IsMouseOver() then return end
    end
    for _,handle in ipairs(e.chatDragButtons or {}) do
        if handle:IsVisible() and handle.IsMouseOver and handle:IsMouseOver() then
            StartChatDrag(e,handle)
            return
        end
    end
    StartChatDrag(e)
end

local function RefreshChatToggles(e,group)
    e.chatToggles=e.chatToggles or {}
    e.chatDragButtons=e.chatDragButtons or {}
    local row=group and e.view.nodes.chatButtonsRow
    for index,slot in ipairs(row and row.chatButtons or {}) do
        local key=slot.definition.key
        local handle=e.chatDragButtons[index]
        if not handle then
            handle=CreateFrame("Button",nil,e.input)
            handle:SetFrameLevel(e.input:GetFrameLevel()+1)
            handle:EnableMouse(true)
            if handle.SetMouseClickEnabled then handle:SetMouseClickEnabled(true) end
            handle:SetScript("OnMouseDown",function(self,mouseButton)
                if mouseButton=="LeftButton" then StartChatDrag(e,self) end
            end)
            handle:SetScript("OnMouseUp",function(_,mouseButton)
                if mouseButton=="LeftButton" then EndMonitorDrag(e) end
            end)
            e.chatDragButtons[index]=handle
        end
        handle.chatSlot=slot
        local ratio=slot.frame:GetEffectiveScale()/e.input:GetEffectiveScale()
        local size=group.iconSize or 64
        local pitch=size+(group.buttonSpacing or -20)
        handle:ClearAllPoints()
        handle:SetSize(math.max(1,math.min(size,pitch)*ratio),math.max(1,size*ratio))
        handle:SetPoint("CENTER",slot.frame,"CENTER")
        handle:Show()
        local button=e.chatToggles[index]
        if not button then
            button=W.Check(e.input,"",function(checked)
                if M:CanEdit() then
                    local current=M.byID.chatButtons
                    current.disabledButtons[key]=not checked or nil
                    M:Commit()
                else
                    e.chatToggles[index]:SetChecked(not checked)
                end
            end)
            button:SetSize(18,18)
            button:SetFrameLevel(e.input:GetFrameLevel()+2)
            e.chatToggles[index]=button
        end
        button:ClearAllPoints()
        button:SetPoint("TOP",slot.frame,"BOTTOM",0,-2)
        button:SetChecked(group.disabledButtons[key]~=true)
        button:Show()
    end
    if not row then
        for _,button in ipairs(e.chatToggles) do button:Hide() end
        for _,handle in ipairs(e.chatDragButtons) do handle:Hide() end
    end
end

local function RefreshSkillButtons(e,group)
    if not group then
        if e.skillAdd then e.skillAdd:Hide()end
        for _,button in ipairs(e.skillDeletes or {})do button:Hide()end
        return
    end
    local object=e.view.nodes.playerSkillMonitorIcons
    if not object then return end
    local S=M.PlayerSkillMonitor
    local function Flush()
        local panel=e.skillMonitorPanel
        if panel and panel.edit then panel.edit:ClearFocus()end
        if panel and panel.soundInput then panel.soundInput:ClearFocus()end
    end
    if not e.skillAdd then
        e.skillAdd=W.Button(e.input,"+",32,function()
            local owner=Selected()
            if not owner or owner.id~="playerSkillMonitor" or not M:CanEdit()then return end
            Flush()
            local entry
            for _,candidate in ipairs(owner.monitors)do
                if candidate.value=="" and candidate.type=="cooldown" then entry=candidate;break end
            end
            if not entry then entry=S.NewEntry();owner.monitors[#owner.monitors+1]=entry end
            e.skillEntry=entry;e.propScroll:SetVerticalScroll(0);M:Commit()
        end)
        e.skillDeletes={}
    end
    local add=e.skillAdd
    add:SetFrameLevel(e.input:GetFrameLevel()+5)
    local entries=object.entries or {}
    local rightIndex=S.Direction(group)=="LEFT" and 1 or #entries
    local rightSlot=#entries>0 and object.skillIcons[rightIndex]
    local iconScale=(rightSlot or object.frame):GetEffectiveScale()/add:GetEffectiveScale()
    local width,height
    if rightSlot then width,height=rightSlot:GetWidth(),rightSlot:GetHeight()
    else width=S.IconSize(group);height=width end
    add:SetSize(width*iconScale,height*iconScale)
    add:ClearAllPoints()
    if rightSlot then add:SetPoint("LEFT",rightSlot,"RIGHT",6,0)
    else add:SetPoint("CENTER",object.frame,"CENTER",0,0)end
    add:Show()
    for i=1,math.max(#entries,#e.skillDeletes)do
        local slot=object.skillIcons and object.skillIcons[i]
        local entry=entries[i]
        local button=e.skillDeletes[i]
        if entry and slot then
            if not button then
                button=CreateFrame("Button",nil,e.input);button:SetSize(18,16)
                button:RegisterForClicks("LeftButtonUp")
                local label=W.Label(button,"×",15);label:SetPoint("CENTER");label:SetTextColor(1,.22,.22)
                button:SetScript("OnEnter",function()label:SetTextColor(1,.72,.64)end)
                local function Dim()label:SetTextColor(1,.22,.22)end
                button:SetScript("OnLeave",Dim);button:SetScript("OnHide",Dim)
                button:SetScript("OnClick",function(self)
                    local owner=Selected()
                    if owner~=self.owner or not M:CanEdit()then return end
                    Flush()
                    local index=S.EntryIndex(owner,self.entry)
                    if not index then return end
                    if e.skillEntry==self.entry then e.skillEntry=nil end
                    table.remove(owner.monitors,index);M:Commit()
                end)
                e.skillDeletes[i]=button
            end
            button.owner,button.entry=group,entry
            button:SetFrameLevel(e.input:GetFrameLevel()+5)
            button:ClearAllPoints();button:SetPoint("TOP",slot,"BOTTOM",0,-4);button:Show()
        elseif button then button:Hide()end
    end
end

function M:FitPreview()
    local e=self.editor;local geo=self:Geometry();e.geometry=geo
    local minx,miny,maxx,maxy
    for _,n in ipairs(self.db.design.nodes) do
        if M.DisplayModes.Visible(n,M.byID) and n.kind~="group" and n.kind~="hitbox" and
            ((e.mainPreview and InMainPreview(n)) or
            (not e.mainPreview and InPreviewScope(n,e.scope) and
            (not e.previewFocusID or self:IsChild(n.id,e.previewFocusID)))) then
            local g=geo[n.id]
            local width=n.autoWidth and e.view.nodes[n.id] and e.view.nodes[n.id].frame:GetWidth() or g.w
            local x=g.x
            if n.kind=="skillmonitor"or n.kind=="othermonitor"or n.kind=="raidbuffs"or n.kind=="receivedbuffs"or n.kind=="raidvulnerability"or n.kind=="commonitems"then
                local object=e.view.nodes[n.id]
                x=x+M.PlayerSkillMonitor.RowOffset(e.view.byID[n.parent],object and object.rowCount or 0)*g.s
            end
            local x1,y1,x2,y2=x-width*g.s/2,g.y-g.h*g.s/2,x+width*g.s/2,g.y+g.h*g.s/2
            minx=minx and math.min(minx,x1) or x1;miny=miny and math.min(miny,y1) or y1
            maxx=maxx and math.max(maxx,x2) or x2;maxy=maxy and math.max(maxy,y2) or y2
        end
    end
    minx,miny,maxx,maxy=minx or -100,miny or -100,maxx or 100,maxy or 100
    e.fit=UIParent:GetEffectiveScale()/math.max(.001,e.canvas:GetEffectiveScale())
    local selected=Selected()
    if PreviewModuleID(selected)=="targetDistance"then
        minx,miny,maxx,maxy=M.TargetDistance.PreviewBounds(geo)
    end
    if M.ModuleGuides.Supports(selected)then
        local left,bottom,right,top=M.ModuleGuides.PreviewBounds(e.view,selected.id,geo)
        if left then minx,miny,maxx,maxy=math.min(minx,left),math.min(miny,bottom),math.max(maxx,right),math.max(maxy,top)end
    end
    if PreviewModuleID(selected)=="bossFrames" then
        local left,bottom,right,top=M.BossFrames.VisibleBounds(geo)
        if left then minx,miny,maxx,maxy=left,bottom,right,top end
    end
    local moduleID=PreviewModuleID(selected)
    if moduleID=="playerSkillMonitor" then
        local object=e.view.nodes.playerSkillMonitorIcons
        local geometry=geo.playerSkillMonitorIcons
        if object and geometry and #(object.entries or {})>0 then
            maxx=maxx+M.PlayerSkillMonitor.IconSize(selected)*geometry.s+6
        end
    end
    if HasDedicatedPreview(selected) and moduleID~="partyFrames" and moduleID~="systemMenu" then
        local availableWidth=math.max(1,e.canvas:GetWidth()-40)
        local preserveSize=moduleID=="bossFrames" or moduleID=="chatButtons" or moduleID=="combatNotices"
        local availableHeight=math.max(1,(preserveSize and 200 or e.canvas:GetHeight())-40)
        local reference=moduleID=="bossFrames" and .4/math.max(.001,self.byID.bossFrames.scale or 1) or 1
        e.fit=e.fit*math.min(1,availableWidth/math.max(1,(maxx-minx)*reference),availableHeight/math.max(1,(maxy-miny)*reference))
    end
    local portrait=e.mainPreview and geo[M.DisplayModes.Minimal() and "minimalHealth" or "wabc757f81ee"]
    local cast=HasDedicatedPreview(selected) and geo[e.previewFocusID or selected.id]
    if PreviewModuleID(selected)=="partyFrames" or PreviewModuleID(selected)=="bossFrames"or PreviewModuleID(selected)=="playerSkillMonitor" or PreviewModuleID(selected)=="playerOtherMonitor"or PreviewModuleID(selected)=="raidBuffs"or PreviewModuleID(selected)=="receivedBuffs"or PreviewModuleID(selected)=="raidVulnerability"or PreviewModuleID(selected)=="commonItems" or PreviewModuleID(selected)=="targetDistance" then cast=nil end
    e.centerX,e.centerY=portrait and portrait.x or (cast and cast.x or (minx+maxx)/2),
        portrait and portrait.y or (cast and cast.y or (miny+maxy)/2)
    e.view.root:SetScale(e.fit);e.view.root:ClearAllPoints()
    e.view.root:SetPoint("CENTER",e.canvas,"CENTER",-e.centerX+(e.panX or 0)/e.fit,-e.centerY+(e.panY or 0)/e.fit)
end

function M:UpdateSelectionOutline()
    local e=self.editor
    if not e.mainPreview then e.outline:Hide();return end
    local n=Selected();local o=n and e.view.nodes[n.id]
    if n and (n.id=="mainComposite" or (n.modeMinimal and n.kind=="text")) then e.outline:Hide();return end
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
    if e.monitorDrag and e.monitorDrag.group~=selected then CancelMonitorDrag(e);e.monitorGlow:Hide()end
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
    local chatPreview=selected and selected.id=="chatButtons"
    local previewHeight=e.mainPreview and 200 or (chatPreview and 145 or 125)
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
    if e.previewMonitorHint then e.previewMonitorHint:SetShown(selected and monitorPreview[selected.id]~=nil)end
    if e.previewThreatHint then e.previewThreatHint:SetShown(PreviewModuleID(selected)=="targetThreat") end
    if e.previewChatHint then e.previewChatHint:SetShown(PreviewModuleID(selected)=="chatButtons") end
    local systemMenuPreview=PreviewModuleID(selected)=="systemMenu"
    if e.previewSystemHint then e.previewSystemHint:SetShown(systemMenuPreview and selected.menuAlwaysVisible~=true) end
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
    RefreshChatToggles(e,chatPreview and selected)
    RefreshSkillButtons(e,selected and selected.id=="playerSkillMonitor" and selected)
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
        if M.DisplayModes.Visible(n,M.byID) and n.kind~="group" and n.kind~="hitbox" and not fixedPortraitLevels[n.id] and not n.locked and f and f:IsVisible() then
            local frames=mainAuraIcons[n.id] and o.icons or {f}
            for _,part in ipairs(frames or {}) do
                if part:IsVisible() then
                    local s=part:GetEffectiveScale();local l,r,t,b=part:GetLeft(),part:GetRight(),part:GetTop(),part:GetBottom()
                    if l and n.modeMinimal and n.kind=="text" and o.text then
                        local width=math.min(r-l,math.max(12,o.text:GetStringWidth()+6))
                        if n.justify=="RIGHT" then l=r-width
                        elseif n.justify=="LEFT" then r=l+width
                        else local center=(l+r)/2;l,r=center-width/2,center+width/2 end
                    end
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
M.EditorInternals.MonitorTarget=MonitorTarget
M.EditorInternals.ChatDragMouseEvent=ChatDragMouseEvent
M.EditorInternals.BeginMonitorDrag=BeginMonitorDrag
M.EditorInternals.CancelMonitorDrag=CancelMonitorDrag
M.EditorInternals.UpdateMonitorHighlight=UpdateMonitorHighlight
M.EditorInternals.EndMonitorDrag=EndMonitorDrag
