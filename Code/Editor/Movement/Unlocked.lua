local _,M=...
local W,R=M.Widgets,M.Renderer
local unpack=unpack or table.unpack
local private=M.EditorInternals
local topLevelFrames=private.topLevelFrames
local unlockExcluded=private.unlockExcluded
local unlockGroupColors={{.25,1,.35},{1,.25,.25},{1,.85,.2},{.4,.8,1}}
local unlockModuleColors={}
do
    local groupIndex=1
    for _,id in ipairs(topLevelFrames)do
        unlockModuleColors[id]=unlockGroupColors[groupIndex]
        if private.moduleGroupBreaks[id]then groupIndex=groupIndex+1 end
    end
end
local RoundOffset=private.RoundOffset
local MainCompositeRoots=private.MainCompositeRoots
local UpdatePreviewGrid=private.UpdatePreviewGrid
local FrameMoveBounds=private.FrameMoveBounds
local MainCompositeMoveBounds=private.MainCompositeMoveBounds
local centralModules={mainComposite=true,wa8d650f8d3a=true,petComposite=true,totComposite=true,
    focusComposite=true,playerSkillMonitor=true,playerOtherMonitor=true,cooldownMonitor=true,
    receivedBuffs=true,raidVulnerability=true,raidBuffs=true,commonItems=true,targetThreat=true,targetDistance=true}
local centralColor={1,.35,.68}

function M:FinishUnlockedMoveMode()
    local mode=self.moveMode
    if not mode or not mode.allModules then self:StopFrameMoveMode(true);return end
    if mode.fadeOutStarted then return end
    mode.ready=false;mode.done:Disable()
    mode.restore:Disable()
    mode.snapCheck:Disable()
    mode.centralCheck:Disable()
    for _,mover in ipairs(mode.movers)do mover.drag=nil;mover:EnableMouse(false)end
    if mode.changed then mode.changed=false;self:Commit()end
    mode.fadeOutStarted=GetTime();mode.fadeOutAlpha=mode.stage:GetAlpha()
    mode.fadeOutLiveAlpha=self.live and self.live.root:GetAlpha()or 0
end

local function UnlockedBounds(group,geometry)
    if group.id=="mainComposite"then return MainCompositeMoveBounds(geometry)end
    local g=geometry[group.id]
    if group.id=="targetDistance"then
        local number=geometry.targetDistanceNumber
        return number.x,number.y,math.max(100,number.w*number.s),math.max(40,number.h*number.s)
    end
    local x,y,width,height=FrameMoveBounds(group)
    return g.x+x*g.s,g.y+y*g.s,math.max(180,width*g.s),math.max(80,height*g.s)
end
local function PlaceUnlockedMover(mode,mover,x,y,width,height,ax,ay)
    mover:ClearAllPoints();mover:SetPoint("CENTER",mode.stage,"CENTER",x,y)
    mover:SetSize(width,height);mover.area=width*height
    if mover.coordinates then
        if math.abs(ax)<.05 then ax=0 end;if math.abs(ay)<.05 then ay=0 end
        mover.coordinates:SetText(string.format("X: %g  Y: %g",ax,ay))
        if mover.positionedTitle~=mover.label:GetText() then
            mover.positionedTitle=mover.label:GetText()
            mover.label:ClearAllPoints();mover.label:SetPoint("BOTTOMLEFT",mover,"TOPLEFT",0,4)
            local titleWidth=mover.label.GetUnboundedStringWidth and mover.label:GetUnboundedStringWidth()or mover.label:GetStringWidth()
            mover.label:SetWidth(math.max(1,titleWidth+2))
        end
    end
end
local function PositionUnlockedMover(mode,mover,geometry)
    local x,y,width,height=UnlockedBounds(mover.node,geometry)
    local anchor=mover.node.id=="mainComposite" and geometry[M.DisplayModes.Minimal() and "minimalHealth" or "wabc757f81ee"]
    if mode.centralGroup and mover.node.id=="mainComposite" then
        x,y=anchor.x,anchor.y
        width,height=0,0
        for _,part in ipairs(mode.movers) do
            if part.available and centralModules[part.node.id] then
                local px,py,pw,ph=UnlockedBounds(part.node,geometry)
                width=math.max(width,2*math.abs(px-x)+pw)
                height=math.max(height,2*math.abs(py-y)+ph)
            end
        end
    end
    PlaceUnlockedMover(mode,mover,x,y,width,height,anchor and anchor.x or x,anchor and anchor.y or y)
end
function M:ResetUnlockedModulePositions()
    local mode=self.moveMode
    if not mode or not mode.allModules or not mode.ready or not self:CanEdit() then return end
    local defaults={}
    for _,n in ipairs(self.defaults.nodes)do defaults[n.id]=n end
    for _,n in ipairs(self.db.moduleDefaults and self.db.moduleDefaults.nodes or {})do defaults[n.id]=n end
    mode.dragMover=nil;mode.changed=false
    if mode.pickMenu then mode.pickMenu:Hide()end
    for _,mover in ipairs(mode.movers)do
        mover.drag=nil
        if mover.available then
            local node=mover.node;local ref=defaults[node.id]
            if ref then
                node.x=ref.x or 0;node.y=ref.y or 0
                if node.id=="playerSkillMonitor"then M.PlayerSkillMonitor.RestorePosition(node,ref)
                elseif node.id=="playerOtherMonitor"then M.PlayerOtherMonitor.RestorePosition(node,ref)
                elseif node.id=="raidBuffs"then M.RaidBuffMonitor.RestorePosition(node,ref)
                elseif node.id=="receivedBuffs"then M.ReceivedBuffs.RestorePosition(node,ref)
                elseif node.id=="raidVulnerability"then M.RaidVulnerability.RestorePosition(node,ref)
                elseif node.id=="commonItems"then M.CommonItems.RestorePosition(node,ref)end
                if node.id=="targetDistance"then
                    local number=self.byID.targetDistanceNumber
                    local numberRef=defaults.targetDistanceNumber
                    if number and numberRef then
                        number.x=numberRef.x or 0;number.y=numberRef.y or 0
                        local copy=mode.view.byID.targetDistanceNumber
                        if copy then copy.x=number.x;copy.y=number.y end
                    end
                end
                if node.id=="mainComposite"then
                    if M.DisplayModes.Minimal() then node.moveX,node.moveY=0,0
                    else node.moveX,node.moveY=ref.moveX or 0,ref.moveY or 0 end
                end
            end
        end
    end
    self:Commit()
    for _,mover in ipairs(mode.movers)do
        local node=mover.node;local copy=mode.view.byID[node.id]
        if copy and mover.available then
            copy.x=node.x;copy.y=node.y;copy.moveX=node.moveX;copy.moveY=node.moveY
        end
    end
    R.Apply(mode.view,mode.view.design)
    local geometry=self:Geometry()
    for _,mover in ipairs(mode.movers)do if mover:IsShown()then PositionUnlockedMover(mode,mover,geometry)end end
end
local function SetCentralGroup(mode,enabled)
    local mainAvailable=false
    for _,mover in ipairs(mode.movers) do
        if mover.available and mover.node.id=="mainComposite" then mainAvailable=true;break end
    end
    mode.centralGroup=enabled==true and mainAvailable
    mode.centralCheck:SetChecked(mode.centralGroup)
    mode.selectedMover=nil;mode.pickSelected=nil
    if mode.pickMenu then mode.pickMenu:Hide() end
    local geometry=M:Geometry()
    for _,mover in ipairs(mode.movers) do
        mover.drag=nil
        local grouped=mode.centralGroup and centralModules[mover.node.id]
        mover.groupColor=grouped and centralColor or unlockModuleColors[mover.node.id]
        mover.label:SetText(grouped and mover.node.id=="mainComposite" and "中间监控区" or
            mover.node.id=="targetDistance" and "目标距离数字" or private.ModuleName(mover.node))
        mover:SetShown(mover.available and (not grouped or mover.node.id=="mainComposite"))
        if mover:IsShown() then PositionUnlockedMover(mode,mover,geometry) end
    end
end
local function UnlockedContains(mover,x,y)
    if not mover or not mover:IsShown()then return false end
    local cx,cy=mover:GetCenter()
    return math.abs(x-cx)<=mover:GetWidth()/2 and math.abs(y-cy)<=mover:GetHeight()/2
end
local function SelectUnlockedMover(mode,selected)
    mode.selectedMover=selected
    for _,mover in ipairs(mode.movers)do
        local active=mover==selected
        local r,g,b=unpack(mover.groupColor)
        mover:SetFrameLevel(active and 8500 or mover.baseLevel or 8000)
        for i,texture in ipairs(mover.moveAreaTextures)do
            if i<=9 then
                texture:SetVertexColor(r*.8,g*.8,b*.8,active and .42 or .27)
            else
                if active then texture:SetVertexColor(r+(1-r)*.45,g+(1-g)*.45,b+(1-b)*.45,1)
                else texture:SetVertexColor(r,g,b,.95)end
            end
        end
    end
end
local function UnlockedOverlapMenu(mode)
    local x,y=GetCursorPosition();local scale=UIParent:GetEffectiveScale();x,y=x/scale,y/scale
    local candidates={}
    for _,mover in ipairs(mode.movers)do
        if UnlockedContains(mover,x,y)then
            candidates[#candidates+1]=mover
        end
    end
    if #candidates==0 then return end
    local menu=mode.pickMenu
    if not menu then menu=W.Panel(mode.stage);mode.pickMenu=menu;menu.buttons={}end
    menu:SetFrameStrata("FULLSCREEN_DIALOG");menu:SetFrameLevel(9000)
    menu:ClearAllPoints();menu:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",math.min(x,UIParent:GetWidth()-240),math.max(y,#candidates*30+12))
    menu:SetSize(240,#candidates*30+12)
    for i,mover in ipairs(candidates)do
        local button=menu.buttons[i]
        if not button then button=W.Button(menu,"",228,function()end);menu.buttons[i]=button end
        button:SetPoint("TOPLEFT",6,-6-(i-1)*30);button:SetText(private.ModuleName(mover.node))
        button:SetScript("OnClick",function()
            SelectUnlockedMover(mode,mover);mode.pickSelected=mover;menu:Hide()
        end)
        button:Show()
    end
    for i=#candidates+1,#menu.buttons do menu.buttons[i]:Hide()end
    menu:Show()
end
function M:StartUnlockedMoveMode()
    if not self:CanEdit()or not self.live then return end
    if self.moveMode then self:StopFrameMoveMode(false)end
    if M.BossFrames then M.BossFrames.StopTest()end
    local mode=self.unlockedMoveMode
    if not mode then
        local stage=CreateFrame("Frame",nil,UIParent);stage:Hide();stage:SetAllPoints(UIParent)
        stage:SetFrameStrata("FULLSCREEN");stage:SetFrameLevel(1);stage:EnableMouse(true)
        local dim=stage:CreateTexture(nil,"BACKGROUND");dim:SetAllPoints();dim:SetColorTexture(0,0,0,.3)
        local grid=CreateFrame("Frame",nil,stage);grid:SetAllPoints();grid:EnableMouse(false)
        mode={allModules=true,stage=stage,dim=dim,gridFrame=grid,canvas=stage,gridLines={},movers={}}
        self.unlockedMoveMode=mode
        mode.view=R.New(stage,true);mode.view.unlockMode=true;mode.view.scene="cast"
        local panel=W.Panel(stage);mode.panel=panel;panel:SetSize(560,110)
        panel:SetPoint("CENTER",UIParent,"TOP",0,-UIParent:GetHeight()/3);panel:SetFrameStrata("FULLSCREEN_DIALOG");panel:SetFrameLevel(9100)
        panel.label=W.Label(panel,"拖动彩色区域调整位置；右键选择重叠框体。",13);panel.label:SetPoint("TOP",0,-12)
        mode.snapCheck=W.Check(panel,"吸附网格线",function(enabled)M.db.editor.snap=enabled==true end)
        mode.snapCheck:SetPoint("TOPLEFT",24,-40)
        mode.centralCheck=W.Check(panel,"中间监控区整体移动",function(enabled)
            if not mode.ready or not M:CanEdit() then return end
            if mode.dragMover then mode.dragMover.drag=nil;mode.dragMover=nil;M:Commit() end
            SetCentralGroup(mode,enabled)
            SelectUnlockedMover(mode,nil)
        end)
        mode.centralCheck:SetPoint("TOPLEFT",210,-40)
        mode.done=W.Button(panel,"完成移动",100,function()M:FinishUnlockedMoveMode()end)
        mode.done:SetPoint("BOTTOM",60,10);mode.done:SetFullColorStyle(1,.82,0)
        mode.restore=W.Button(panel,"恢复默认",100,function()M:ResetUnlockedModulePositions()end)
        mode.restore:SetPoint("BOTTOM",-60,10)
        stage:EnableKeyboard(true);stage:SetPropagateKeyboardInput(true)
        stage:SetScript("OnKeyDown",function(self,key)
            if InCombatLockdown() then M:StopFrameMoveMode(false);return end
            self:SetPropagateKeyboardInput(key~="ESCAPE")
            if key=="ESCAPE"then M:StopFrameMoveMode(true)end
        end)
        stage:RegisterEvent("PLAYER_REGEN_DISABLED")
        stage:SetScript("OnEvent",function()
            if M.moveMode==mode then M:StopFrameMoveMode(false) end
        end)
        stage:SetScript("OnMouseDown",function(_,button)
            if not mode.ready then return end
            if mode.pickMenu then mode.pickMenu:Hide()end
            if button=="RightButton"then UnlockedOverlapMenu(mode)end
            if button=="LeftButton"then mode.pickSelected=nil;SelectUnlockedMover(mode,nil)end
        end)
        stage:SetScript("OnSizeChanged",function(_,width,height)
            UpdatePreviewGrid(mode,width,height)
            mode.panel:ClearAllPoints();mode.panel:SetPoint("CENTER",UIParent,"TOP",0,-UIParent:GetHeight()/3)
            if M.moveMode==mode then
                for _,object in ipairs(mode.view.ordered)do
                    if object.spec.screenAnchor then R.Position(mode.view,object.frame,object.spec,object.geometryParent)end
                end
                local geometry=M:Geometry()
                for _,mover in ipairs(mode.movers)do PositionUnlockedMover(mode,mover,geometry)end
            end
        end)
    end
    mode.changed=false;mode.pickSelected=nil;mode.dragMover=nil
    mode.ready=false;mode.fadeOutStarted=nil;mode.fadeStarted=GetTime();mode.stage:SetAlpha(0);mode.done:Disable()
    mode.restore:Disable()
    mode.snapCheck:SetChecked(self.db.editor.snap~=false);mode.snapCheck:Disable()
    mode.centralGroup=false;mode.centralCheck:SetChecked(false);mode.centralCheck:Disable()
    mode.panel:ClearAllPoints();mode.panel:SetPoint("CENTER",UIParent,"TOP",0,-UIParent:GetHeight()/3)
    mode.liveAlpha=self.live.root:GetAlpha()
    local design={nodes={}};local ids={}
    for _,id in ipairs(topLevelFrames)do
        local group=self.byID[id]
        if group and group.enabled~=false and not unlockExcluded[id] and (id~="targetDistance" or group.showDistanceNumber~=false) and private.ModuleAvailable(id)then ids[id]=true end
    end
    for _,node in ipairs(self.db.design.nodes)do
        local moduleID=M:ModuleID(node)
        if not moduleID or ids[moduleID]then
            local n=M.Copy(node)
            design.nodes[#design.nodes+1]=n
        end
    end
    -- Prepare the preview before the full-screen stage starts capturing input.
    mode.view.root:Show();R.Apply(mode.view,design)
    local geometry=self:Geometry();local count=0
    for _,id in ipairs(topLevelFrames)do
        local group=self.byID[id]
        if group and ids[id]then
            count=count+1;local mover=mode.movers[count]
            if not mover then
                mover=CreateFrame("Button",nil,mode.stage);W.RoundedMoveArea(mover)
                mover:SetFrameStrata("FULLSCREEN");mover:EnableMouse(true)
                mover.label=W.Label(mover,"",14);mover.label:SetPoint("BOTTOMLEFT",mover,"TOPLEFT",0,4)
                mover.label:SetJustifyH("LEFT");mover.label:SetTextColor(1,1,1)
                M:SetLocaleLineHeight(mover.label,24)
                mover.coordinates=W.Label(mover,"",12)
                mover.coordinates:SetPoint("LEFT",mover.label,"RIGHT",8,0)
                mover.coordinates:SetJustifyH("LEFT");mover.coordinates:SetTextColor(1,.82,0)
                M:SetLocaleLineHeight(mover.coordinates,24)
                mover:SetScript("OnMouseDown",function(self,button)
                    if not mode.ready then return end
                    if button=="RightButton"then UnlockedOverlapMenu(mode);return end
                    if button~="LeftButton"or not M:CanEdit()then return end
                    if mode.pickMenu then mode.pickMenu:Hide()end
                    local x,y=GetCursorPosition();local uiScale=UIParent:GetEffectiveScale()
                    -- Route the next overlapping click to the explicit menu choice,
                    -- even if another native frame received the mouse event.
                    if UnlockedContains(mode.pickSelected,x/uiScale,y/uiScale)then self=mode.pickSelected end
                    mode.pickSelected=nil;SelectUnlockedMover(mode,self)
                    local node=self.node;local geo=M:Geometry()
                    local drag={cursorX=x,cursorY=y,members={}}
                    drag.frameX,drag.frameY,drag.width,drag.height=UnlockedBounds(node,geo)
                    drag.centerX,drag.centerY=drag.frameX,drag.frameY
                    drag.appliedDX,drag.appliedDY=0,0
                    local anchor=node.id=="mainComposite" and geo[M.DisplayModes.Minimal() and "minimalHealth" or "wabc757f81ee"]
                    if anchor then drag.centerX,drag.centerY=anchor.x,anchor.y end
                    if node.id=="mainComposite"then drag.main=true;drag.x=node.moveX or 0;drag.y=node.moveY or 0 end
                    for _,part in ipairs(node.id=="mainComposite"and MainCompositeRoots()or {node})do
                        drag.members[#drag.members+1]={node=part,x=part.x or 0,y=part.y or 0,scale=geo[part.id].s}
                    end
                    if mode.centralGroup and node.id=="mainComposite" then
                        drag.central={}
                        for _,part in ipairs(mode.movers) do
                            local n=part.node
                            if part.available and n.id~="mainComposite" and centralModules[n.id] then
                                local g=geo[n.id]
                                drag.central[#drag.central+1]={node=n,x=g.x,y=g.y}
                            end
                        end
                        local function depth(n)
                            local count=0
                            while n and n.parent and count<100 do n=M.byID[n.parent];count=count+1 end
                            return count
                        end
                        table.sort(drag.central,function(a,b)return depth(a.node)<depth(b.node)end)
                        drag.frameX,drag.frameY=self:GetCenter()
                        local cx,cy=mode.stage:GetCenter()
                        drag.frameX,drag.frameY=drag.frameX-cx,drag.frameY-cy
                        drag.width,drag.height=self:GetWidth(),self:GetHeight()
                    end
                    self.drag=drag;mode.dragMover=self
                end)
                mover:SetScript("OnMouseUp",function(self,button)
                    if button=="LeftButton"and mode.dragMover then
                        mode.dragMover.drag=nil;mode.dragMover=nil;mode.changed=false;M:Commit()
                    end
                end)
                mode.movers[count]=mover
            end
            mover.node=group;mover.groupColor=unlockModuleColors[id]
            mover.available=true
            mover.drag=nil;mover.label:SetText(id=="targetDistance" and "目标距离数字" or private.ModuleName(group));mover:EnableMouse(false)
            PositionUnlockedMover(mode,mover,geometry);mover:Show()
        end
    end
    for i=count+1,#mode.movers do mode.movers[i].available=false;mode.movers[i]:Hide()end
    SelectUnlockedMover(mode,nil)
    local ranked={};for i=1,count do ranked[i]=mode.movers[i]end
    table.sort(ranked,function(a,b)return a.area>b.area end)
    for i,mover in ipairs(ranked)do mover.baseLevel=8000+i;mover:SetFrameLevel(mover.baseLevel)end
    UpdatePreviewGrid(mode,UIParent:GetWidth(),UIParent:GetHeight())
    mode.stage:SetScript("OnUpdate",function()
        if mode.fadeOutStarted then
            local t=M.Clamp(GetTime()-mode.fadeOutStarted,0,1);local alpha=t*t*(3-2*t)
            mode.stage:SetAlpha(mode.fadeOutAlpha*(1-alpha))
            M.live.root:SetAlpha(mode.fadeOutLiveAlpha+(mode.liveAlpha-mode.fadeOutLiveAlpha)*alpha)
            if t>=1 then M:StopFrameMoveMode(true);return end
            R.Animate(mode.view);return
        end
        if not mode.ready then
            local t=M.Clamp(GetTime()-mode.fadeStarted,0,1);local alpha=t*t*(3-2*t)
            mode.stage:SetAlpha(alpha);M.live.root:SetAlpha(mode.liveAlpha*(1-alpha))
            if t>=1 then
                mode.ready=true;mode.done:Enable();mode.restore:Enable();mode.snapCheck:Enable()
                mode.centralCheck:Enable()
                for _,mover in ipairs(mode.movers)do if mover:IsShown()then mover:EnableMouse(true)end end
            end
        end
        for _,mover in ipairs(mode.movers)do
            local drag=mover.drag
            if drag then
                if InCombatLockdown()then M:StopFrameMoveMode(false);return end
                if not IsMouseButtonDown("LeftButton")then mover.drag=nil;mode.dragMover=nil;mode.changed=false;M:Commit()
                else
                    local x,y=GetCursorPosition();local uiScale=UIParent:GetEffectiveScale()
                    local dx,dy=(x-drag.cursorX)/uiScale,(y-drag.cursorY)/uiScale
                    -- Quantize the displayed module position in screen UI units.
                    -- Preserve the resulting translation through scaled parents.
                    if math.abs(dx)>.01 or math.abs(dy)>.01 then
                        local step=M.db.editor.snap~=false and 10 or 1
                        dx=RoundOffset((drag.centerX+dx)/step)*step-drag.centerX
                        dy=RoundOffset((drag.centerY+dy)/step)*step-drag.centerY
                    end
                    -- Dragging translates a fixed layout. Reuse the bounds captured
                    -- on mouse-down, and do no layout work within one snap cell.
                    if dx~=drag.appliedDX or dy~=drag.appliedDY then
                        local shiftX,shiftY=dx,dy
                        if drag.main then
                            local node=mover.node;node.moveX=drag.x+dx;node.moveY=drag.y+dy
                            local copy=mode.view.byID[node.id];copy.moveX=node.moveX;copy.moveY=node.moveY
                            for _,member in ipairs(drag.members)do
                                local object=mode.view.nodes[member.node.id]
                                R.Position(mode.view,object.frame,object.spec,object.geometryParent)
                            end
                        else
                            for _,member in ipairs(drag.members)do
                                local node=member.node;node.x=member.x+dx/member.scale;node.y=member.y+dy/member.scale
                                local copy=mode.view.byID[node.id];copy.x=node.x;copy.y=node.y
                                local object=mode.view.nodes[node.id];R.Position(mode.view,object.frame,copy,object.geometryParent)
                            end
                        end
                        if drag.central then
                            for _,member in ipairs(drag.central) do
                                local n=member.node
                                local current=M:Geometry()[n.id]
                                n.x=(n.x or 0)+(member.x+dx-current.x)/current.s
                                n.y=(n.y or 0)+(member.y+dy-current.y)/current.s
                            end
                            for _,n in ipairs(M.db.design.nodes) do
                                local copy=mode.view.byID[n.id]
                                if copy then copy.x=n.x;copy.y=n.y;copy.moveX=n.moveX;copy.moveY=n.moveY end
                            end
                            R.Apply(mode.view,mode.view.design)
                        end
                        drag.appliedDX,drag.appliedDY=dx,dy;mode.changed=true
                        PlaceUnlockedMover(mode,mover,drag.frameX+shiftX,drag.frameY+shiftY,drag.width,drag.height,
                            drag.centerX+shiftX,drag.centerY+shiftY)
                    end
                end
            end
        end
        R.Animate(mode.view)
    end)
    self.moveMode=mode
    R.SetMovementModelsHidden(self.live,true)
    if self.editor then self.editor.window:Hide()end
    mode.stage:Show()
end


M.EditorInternals.UnlockedBounds=UnlockedBounds
M.EditorInternals.PositionUnlockedMover=PositionUnlockedMover
M.EditorInternals.UnlockedContains=UnlockedContains
M.EditorInternals.SelectUnlockedMover=SelectUnlockedMover
M.EditorInternals.UnlockedOverlapMenu=UnlockedOverlapMenu
