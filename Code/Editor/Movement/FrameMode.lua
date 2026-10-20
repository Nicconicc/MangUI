local _,M=...
local W,R=M.Widgets,M.Renderer
local unpack=unpack or table.unpack
local private=M.EditorInternals
local pointXY=private.pointXY
local IsUnitComposite=private.IsUnitComposite
local HasDedicatedPreview=private.HasDedicatedPreview
local IsCastGroup=private.IsCastGroup
local RoundOffset=private.RoundOffset
local Selected=private.Selected
local InMainPreview=private.InMainPreview
local MainCompositeRoots=private.MainCompositeRoots

local function FrameMoveBounds(group)
    if group.id=="playerSkillMonitor" then return M.PlayerSkillMonitor.MoveBounds(group) end
    if group.id=="playerOtherMonitor" then return M.PlayerOtherMonitor.MoveBounds(group) end
    if group.id=="raidBuffs"then return M.RaidBuffMonitor.MoveBounds(group)end
    if group.id=="receivedBuffs"then return M.ReceivedBuffs.MoveBounds(group)end
    if group.id=="raidVulnerability"then return M.RaidVulnerability.MoveBounds(group)end
    if group.id=="commonItems"then return M.CommonItems.MoveBounds(group)end
    local geometry=M:Geometry();local origin=geometry[group.id]
    if not origin or not origin.s or origin.s==0 then return 0,0,280,280 end
    if group.id=="bossFrames" then
        local left,bottom,right,top=M.BossFrames.VisibleBounds(geometry)
        if left then
            return ((left+right)/2-origin.x)/origin.s,((bottom+top)/2-origin.y)/origin.s,
                math.max(200,(right-left)/origin.s+24),math.max(100,(top-bottom)/origin.s+24)
        end
    end
    local left,right,bottom,top
    for _,n in ipairs(M.db.design.nodes) do
        if n.enabled~=false and n.kind~="group" and n.kind~="hitbox" and n.kind~="spark"
            and M:IsChild(n.id,group.id) then
            local g=geometry[n.id]
            if g then
                local l=(g.x-g.w*g.s/2-origin.x)/origin.s
                local r=(g.x+g.w*g.s/2-origin.x)/origin.s
                local b=(g.y-g.h*g.s/2-origin.y)/origin.s
                local t=(g.y+g.h*g.s/2-origin.y)/origin.s
                left=left and math.min(left,l) or l;right=right and math.max(right,r) or r
                bottom=bottom and math.min(bottom,b) or b;top=top and math.max(top,t) or t
            end
        end
    end
    left,right,bottom,top=left or -140,right or 140,bottom or -140,top or 140
    local centerX=(left+right)/2
    if group.compound=="playerCast" then
        -- Match the preview's bar center; icon/timer widths must not shift X=0.
        local bar=geometry.wa1537213e27
        centerX=bar and (bar.x-origin.x)/origin.s or 0
    end
    return centerX,(bottom+top)/2,math.max(200,2*math.max(centerX-left,right-centerX)+24),math.max(100,top-bottom+24)
end
local function MainCompositeMoveBounds(geometry)
    local left,right,bottom,top
    for _,n in ipairs(M.db.design.nodes) do
        if n.enabled~=false and n.kind~="group" and n.kind~="hitbox" and n.kind~="spark"
            and InMainPreview(n) then
            local g=geometry[n.id]
            if g then
                local l,r=g.x-g.w*g.s/2,g.x+g.w*g.s/2
                local b,t=g.y-g.h*g.s/2,g.y+g.h*g.s/2
                left=left and math.min(left,l) or l;right=right and math.max(right,r) or r
                bottom=bottom and math.min(bottom,b) or b;top=top and math.max(top,t) or t
            end
        end
    end
    left,right,bottom,top=left or -140,right or 140,bottom or -140,top or 140
    return (left+right)/2,(bottom+top)/2,math.max(200,right-left+24),math.max(100,top-bottom+24)
end

function M:SetCompositeScaleFromCenter(group,relativeScale,actualScale)
    if not group or (not IsUnitComposite(group) and not IsCastGroup(group) and group.compound~="partyFrames" and group.compound~="bossFrames" and group.compound~="playerSkillMonitor" and group.compound~="playerOtherMonitor" and group.compound~="cooldownMonitor" and group.compound~="raidBuffs" and group.compound~="receivedBuffs" and group.compound~="raidVulnerability" and group.compound~="commonItems" and group.compound~="chatButtons" and group.compound~="combatNotices" and group.compound~="experienceBar") then return end
    if group.compound=="partyFrames" or group.compound=="bossFrames" or group.compound=="playerSkillMonitor" or group.compound=="playerOtherMonitor" or group.compound=="cooldownMonitor" or group.compound=="raidBuffs" or group.compound=="receivedBuffs" or group.compound=="raidVulnerability" or group.compound=="commonItems" or group.compound=="chatButtons" or group.compound=="combatNotices" or group.compound=="experienceBar" then relativeScale=M.Clamp(relativeScale,.1,2) end
    local oldScale=group.scale or 1
    local newScale=actualScale or (group.baseScale or 1)*relativeScale
    if group.castOriginRevision==1 then group.scale=newScale;return end
    if math.abs(oldScale-newScale)<.0001 then return end
    local centerX,centerY=FrameMoveBounds(group)
    local point=pointXY[group.point] or pointXY.CENTER
    local pivotX=centerX-point[1]*(group.width or 2)/2
    local pivotY=centerY-point[2]*(group.height or 2)/2
    -- WoW scales SetPoint offsets with this frame, so x/y must be scaled too.
    local ratio=oldScale/newScale
    group.x=ratio*((group.x or 0)+pivotX)-pivotX
    group.y=ratio*((group.y or 0)+pivotY)-pivotY
    group.scale=newScale
end

function M:SetTargetProfileScaleFromCenter(group,newScale)
    if not group or group.id~="wabc757f81ee" then return end
    local oldScale=group.scale or 1
    if math.abs(oldScale-newScale)<.0001 then return end
    local point=pointXY[group.point] or pointXY.CENTER
    local pivotX=-point[1]*(group.width or 2)/2
    local pivotY=-point[2]*(group.height or 2)/2
    local ratio=oldScale/newScale
    group.x=ratio*((group.x or 0)+pivotX)-pivotX
    group.y=ratio*((group.y or 0)+pivotY)-pivotY
    group.scale=newScale
end

function M:SetMainCompositeScaleFromCenter(group,newScale)
    if not group or group.id~="mainComposite" then return end
    local oldScale=group.scale or 1
    if math.abs(oldScale-newScale)<.0001 then return end
    local geometry=self:Geometry()
    local portrait=geometry.wabc757f81ee
    if not portrait then return end
    local pivotX,pivotY=portrait.x,portrait.y
    local ratio=newScale/oldScale
    for _,n in ipairs(MainCompositeRoots()) do
        local old,parentGeometry=geometry[n.id],geometry[n.parent]
        if old and parentGeometry and (n.valueTextOriginRevision==1 or n.resourceOriginRevision==1 or n.auraOriginRevision==1 or n.castOriginRevision==1) then
            -- These offsets already start at the portrait center, in parent
            -- units. Do not convert them back into legacy SetPoint offsets.
            n.x=(n.x or 0)*ratio;n.y=(n.y or 0)*ratio
            n.mainScaleFactor=(n.mainScaleFactor or 1)*ratio
        elseif old and parentGeometry then
            local scale=self:NodeScale(n)*ratio
            local effective=parentGeometry.s*scale
            local anchor=pointXY[n.anchor] or pointXY.CENTER
            local point=pointXY[n.point] or pointXY.CENTER
            local x=pivotX+(old.x-pivotX)*ratio
            local y=pivotY+(old.y-pivotY)*ratio
            local moveX,moveY=M:MainModuleOffset(n)
            x=x-moveX;y=y-moveY
            n.x=(x-parentGeometry.x-anchor[1]*parentGeometry.w*parentGeometry.s/2+
                point[1]*(n.width or 2)*effective/2)/effective
            n.y=(y-parentGeometry.y-anchor[2]*parentGeometry.h*parentGeometry.s/2+
                point[2]*(n.height or 2)*effective/2)/effective
            n.mainScaleFactor=(n.mainScaleFactor or 1)*ratio
        end
    end
    group.scale=newScale
end

function M:StopFrameMoveMode(reopen)
    local mode=self.moveMode;if not mode then return end
    self.moveMode=nil
    if mode.allModules then
        mode.stage:SetScript("OnUpdate",nil);mode.stage:Hide();mode.view.root:Hide()
        if mode.pickMenu then mode.pickMenu:Hide()end
        for _,mover in ipairs(mode.movers)do mover.drag=nil end
        if self.live then self.live.root:SetAlpha(mode.liveAlpha or 1)end
        if mode.changed then self:Commit()end
        R.SetMovementModelsHidden(self.live,false)
        if reopen and self.editor then
            self.editor.refit=true;self.editor.panX=0;self.editor.panY=0
            self.editor.window:Show();self:RefreshEditor()
        end
        return
    end
    if mode.overlay.drag then mode.overlay.drag=nil;self:Commit() end
    mode.overlay:Hide();mode.panel:Hide()
    if mode.bossPreview then M.BossFrames.StopMovePreview() end
    if mode.partyPreview then M.PartyFrames.StopMovePreview() end
    if reopen and self.editor then
        self.editor.refit=true;self.editor.panX=0;self.editor.panY=0
        self.editor.window:Show();self:RefreshEditor()
    end
end

function M:StartFrameMoveMode()
    local group=Selected()
    if not group or not (group.id=="mainComposite" or IsUnitComposite(group) or HasDedicatedPreview(group)) or not self:CanEdit() then return end
    local main=group.id=="mainComposite"
    if self.moveMode then self:StopFrameMoveMode(false) end
    local moveView=group.id=="bossFrames" and M.BossFrames.StartMovePreview() or self.live
    if group.id=="partyFrames" then moveView=M.PartyFrames.StartMovePreview() end
    local live=moveView and moveView.nodes[group.id]
    if not live then self:Print("游戏框体尚未就绪，请稍后重试。") return end

    local overlay=self.frameMoveOverlay
    if not overlay then
        overlay=CreateFrame("Button",nil,UIParent);self.frameMoveOverlay=overlay
        W.RoundedMoveArea(overlay)
        overlay:SetFrameStrata("FULLSCREEN");overlay:EnableMouse(true)
        overlay.label=W.Label(overlay,"",15);overlay.label:SetPoint("TOP",0,-12)
    end
    local x,y,width,height
    if main then x,y,width,height=MainCompositeMoveBounds(self:Geometry())
    else x,y,width,height=FrameMoveBounds(group) end
    overlay:SetParent(main and UIParent or live.frame);overlay:SetFrameStrata("FULLSCREEN")
    overlay:SetFrameLevel(live.frame:GetFrameLevel()+500)
    overlay:ClearAllPoints();overlay:SetPoint("CENTER",main and UIParent or live.frame,"CENTER",x,y)
    overlay:SetSize(width,height);overlay.label:SetText(group.label.." · 拖动绿色区域")
    overlay:SetScript("OnMouseDown",function(self,button)
        if button~="LeftButton" or InCombatLockdown() then return end
        local cursorX,cursorY=GetCursorPosition()
        local drag={cursorX=cursorX,cursorY=cursorY,x=group.x or 0,y=group.y or 0,
            scale=live.frame:GetEffectiveScale()}
        if main then
            drag.scale=UIParent:GetEffectiveScale()
            drag.members={}
            local current=M:Geometry()
            for _,n in ipairs(MainCompositeRoots()) do
                local g=current[n.id]
                local part=M.live.nodes[n.id]
                if g and part then drag.members[#drag.members+1]={node=n,frame=part.frame,x=n.x or 0,y=n.y or 0,scale=g.s} end
            end
        end
        self.drag=drag
    end)
    overlay:SetScript("OnMouseUp",function(self,button)
        if button=="LeftButton" and self.drag then self.drag=nil;M:Commit() end
    end)
    overlay:SetScript("OnUpdate",function(self)
        local drag=self.drag;if not drag then return end
        if InCombatLockdown() or not IsMouseButtonDown("LeftButton") then
            self.drag=nil;M:Commit();return
        end
        local cursorX,cursorY=GetCursorPosition()
        local scale=math.max(.001,drag.scale)
        local dx,dy=(cursorX-drag.cursorX)/scale,(cursorY-drag.cursorY)/scale
        if main then
            for _,member in ipairs(drag.members) do
                local n=member.node
                n.x=RoundOffset(member.x+dx/member.scale);n.y=RoundOffset(member.y+dy/member.scale)
                member.frame:ClearAllPoints()
                member.frame:SetPoint(n.point or "CENTER",member.frame:GetParent(),n.anchor or "CENTER",n.x,n.y)
            end
            self:ClearAllPoints();self:SetPoint("CENTER",UIParent,"CENTER",RoundOffset(x+dx),RoundOffset(y+dy))
        else
            group.x=RoundOffset(drag.x+dx);group.y=RoundOffset(drag.y+dy)
            R.Position(moveView,live.frame,group,live.frame:GetParent())
        end
    end)

    local panel=self.frameMovePanel
    if not panel then
        panel=W.Panel(UIParent);self.frameMovePanel=panel
        panel:SetSize(350,76);panel:SetPoint("TOP",UIParent,"TOP",0,-80)
        panel:SetFrameStrata("FULLSCREEN_DIALOG");panel:SetFrameLevel(9000);panel:EnableMouse(true)
        panel.label=W.Label(panel,"",13);panel.label:SetPoint("TOP",0,-12)
        local done=W.Button(panel,"完成移动",100,function()M:StopFrameMoveMode(true)end)
        done:SetFullColorStyle(1,.82,0)
        done:SetPoint("BOTTOM",0,10)
        panel:EnableKeyboard(true);panel:SetPropagateKeyboardInput(true)
        panel:SetScript("OnKeyDown",function(self,key)
            self:SetPropagateKeyboardInput(true)
            if key=="ESCAPE" then self:SetPropagateKeyboardInput(false);M:StopFrameMoveMode(true) end
        end)
        panel:RegisterEvent("PLAYER_REGEN_DISABLED")
        panel:SetScript("OnEvent",function()M:StopFrameMoveMode(false)end)
        panel:SetScript("OnHide",function()if M.moveMode then M:StopFrameMoveMode(true) end end)
    end
    panel.label:SetText("拖动绿色区域移动"..group.label)
    self.moveMode={overlay=overlay,panel=panel,bossPreview=group.id=="bossFrames",partyPreview=group.id=="partyFrames"}
    self.editor.window:Hide()
    overlay:Show();panel:Show()
end


M.EditorInternals.FrameMoveBounds=FrameMoveBounds
M.EditorInternals.MainCompositeMoveBounds=MainCompositeMoveBounds
