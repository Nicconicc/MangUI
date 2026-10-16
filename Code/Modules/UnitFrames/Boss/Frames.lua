local _,M=...
local B={};M.BossFrames=B
local ART="Interface\\AddOns\\MangUI\\Assets\\"
-- Visible alpha bounds of MangBossFrameGlass (2048 x 256), excluding its padding.
B.glassUV={50/2048,1998/2048,113/256,139/256}
-- Inner horizontal channel of MangTargetFrameCastBar (1024 x 128).
-- Exclude the end caps and compensate its half-pixel center displacement.
B.castChannelUV={103/1024,922/1024}
B.castWidths={background=940,glass=799}
B.castFillSpan=.94 -- Keep a 3% inset at each end of the existing frame channel.
-- The title's metal inner edge fits a circle centered at (246.5,126.3).
-- Its measured diameter is 115.2 pixels; inset the content slightly from the rim.
B.avatarMetal={centerX=246.5/512,centerY=126.3/256,diameter=114}
B.avatarGlass={centerX=253.5/512,centerY=220.5/512,outer=289/512}
-- Alpha bounds in the original assets (left, top, right, bottom). Movement
-- bounds must exclude transparent canvas padding, especially the title art.
local visibleUV={
    bossHPBackground={52/2048,114/256,1996/2048,138/256},
    bossHPMetal={25/2048,94/256,2023/2048,162/256},
    bossHPGlass=B.glassUV,
    bossCastBackground={88/1024,47/128,937/1024,82/128},
    bossCastGlass=B.glassUV,
    bossAvatarMetal={182/512,45/256,313/512,251/256},
    bossAvatarBackground={65/256,65/256,192/256,192/256},
    bossAvatarGlass={109/512,76/512,398/512,365/512},
}
local visibleParts={"bossHPBackground","bossHPFill","bossHPMetal","bossHPGlass",
    "bossHPPercent","bossCastBackground","bossCastFill","bossCastGlass",
    "bossAvatarMetal","bossAvatarBackground","bossAvatarGlass","bossPortrait"}
function B.VisibleBounds(geometry,index)
    index=index or M.byID
    local left,bottom,right,top
    for _,id in ipairs(visibleParts) do
        local n,g=index[id],geometry[id]
        local enabled=n~=nil
        local parent=n
        while parent and enabled do
            if parent.enabled==false or (parent.id=="bossAvatar" and index.bossFrames and index.bossFrames.hideAvatar) then enabled=false end
            parent=parent.parent and index[parent.parent]
        end
        if enabled and g then
            local uv=visibleUV[id] or {0,0,1,1}
            local l=g.x+(uv[1]-.5)*g.w*g.s
            local r=g.x+(uv[3]-.5)*g.w*g.s
            local b=g.y+(.5-uv[4])*g.h*g.s
            local t=g.y+(.5-uv[2])*g.h*g.s
            left=left and math.min(left,l) or l;right=right and math.max(right,r) or r
            bottom=bottom and math.min(bottom,b) or b;top=top and math.max(top,t) or t
        end
    end
    return left,bottom,right,top
end
function B.SyncNodes(design)
    local index={};for _,node in ipairs(design.nodes) do index[node.id]=node end
    if index.bossFrames and index.bossAvatar then index.bossAvatar.enabled=index.bossFrames.hideAvatar~=true end
    local glass,fill=index.bossHPGlass,index.bossHPFill
    if glass and fill then
        local uv=B.glassUV
        fill.width=glass.width*(uv[2]-uv[1]);fill.height=glass.height*(uv[4]-uv[3])
        fill.x=(glass.x or 0)+glass.width*((uv[1]+uv[2])/2-.5)
        fill.y=(glass.y or 0)+glass.height*(.5-(uv[3]+uv[4])/2)
        fill.scale=glass.scale or 1
    end
    -- Internal cast widths are linked on every render, including retained test
    -- views and saved designs whose layout revision has already been recorded.
    local castGroup,castBackground,castGlass=index.bossCast,index.bossCastBackground,index.bossCastGlass
    if castGroup then castGroup.width=B.castWidths.background end
    if castBackground then castBackground.width=B.castWidths.background end
    if castGlass then castGlass.width=B.castWidths.glass end
    local castFill=index.bossCastFill
    if castBackground and castFill then
        local uv=B.castChannelUV
        castFill.width=castBackground.width*(uv[2]-uv[1])*B.castFillSpan
        castFill.x=(castBackground.x or 0)+castBackground.width*((uv[1]+uv[2])/2-.5)
        castFill.scale=castBackground.scale or 1
    end
    local metal,lens,portrait,black=index.bossAvatarMetal,index.bossAvatarGlass,index.bossPortrait,index.bossAvatarBackground
    if metal and lens and portrait and black then
        local rim,shape=B.avatarMetal,B.avatarGlass
        local centerX=(metal.x or 0)+metal.width*(rim.centerX-.5)
        local centerY=(metal.y or 0)+metal.height*(.5-rim.centerY)
        local diameter=math.min(metal.width/512,metal.height/256)*rim.diameter
        -- Fit the glass's visible circle, not its transparent square canvas.
        lens.parent=metal.parent;lens.point="CENTER";lens.anchor="CENTER"
        lens.width=diameter/shape.outer;lens.height=lens.width;lens.scale=metal.scale or 1
        lens.x=centerX-lens.width*(shape.centerX-.5)
        lens.y=centerY-lens.height*(.5-shape.centerY)
        -- A native 3D model has a rectangular viewport; keep it inside the lens.
        local size=M.db and M.db.portrait3D and diameter/math.sqrt(2) or diameter
        portrait.parent=lens.parent;portrait.point="CENTER";portrait.anchor="CENTER"
        portrait.x=centerX;portrait.y=centerY;portrait.width=size;portrait.height=size;portrait.scale=lens.scale or 1
        black.parent=lens.parent;black.point="CENTER";black.anchor="CENTER"
        black.width=diameter*256/127;black.height=black.width;black.scale=lens.scale or 1
        -- Compensate the half-pixel displacement in CenterBlack's own alpha bounds.
        black.x=centerX-black.width*.5/256;black.y=centerY+black.height*.5/256
    end
end
function B.ConfigurePortrait(o)
    if o.spec.id~="bossPortrait" then return end
    if not o.bossPortraitMask then
        local mask=o.frame:CreateMaskTexture()
        mask:SetTexture(M:TexturePath(o.spec,ART.."MainSweepPortraitMask.tga","bossPortraitMask"));mask:SetAllPoints(o.texture)
        o.texture:AddMaskTexture(mask);o.bossPortraitMask=mask
    end
    if o.portraitBackground then
        local diameter=o.spec.width*(o.portrait3D and math.sqrt(2) or 1)
        o.portraitBackground:ClearAllPoints();o.portraitBackground:SetPoint("CENTER",o.frame,"CENTER",0,0)
        o.portraitBackground:SetSize(diameter,diameter)
    end
end
function B.ConfigureHealthFill(o)
    if o.spec.id~="bossHPFill" then return end
    -- Both the clipped fill and the native StatusBar use the same glass alpha.
    for _,texture in ipairs({o.fill,o.materialMask,o.nativeMask}) do
        if texture then texture:SetTexCoord(unpack(B.glassUV)) end
    end
end
function B.EntryOffset(progress)
    -- WA reverses start progress before applying easeIn with strength 3.
    return -40*math.sin((1-M.Clamp(progress,0,1))^3*math.pi)
end
local function Templates()
    local nodes={}
    local function Node(id,label,kind,parent,x,y,w,h,layer,extra)
        local n={id=id,label=label,kind=kind,parent=parent,scope="target",unit="target",
            x=x,y=y,width=w,height=h,scale=1,point="CENTER",anchor="CENTER",alpha=1,
            enabled=true,color={1,1,1,1},binding="static",layer=layer,rules={},conditions={}}
        for key,value in pairs(extra or {}) do n[key]=value end
        nodes[#nodes+1]=n;return n
    end
    -- Rebase the WA's 470.6-y health strip to the module origin. Coupled portrait
    -- and health-fill geometry is fitted to the glass after building the nodes.
    Node("bossFrames","首领框体","group",nil,0,-179.4,1200,200,1000,
        {compound="bossFrames",scale=.8,screenAnchor="TOP",triggerAny="bossTarget",soundEnabled=true,hideAvatar=false,bossLayoutRevision=1,bossCastLayoutRevision=2})
    Node("bossHP","首领生命条","group","bossFrames",0,0,1200,150,1001)
    Node("bossHPBackground","生命条背景","texture","bossHP",0,-.00441894531,1200,150,1002,
        {internal=true,file=ART.."MangBossFrameBG"})
    Node("bossHPFill","生命进度","bar","bossHP",0,1.16745605469,1141.40625,15.234375,1003,
        {internal=true,binding="health",file=ART.."BossHPChannel.tga",alphaFill=true,materialPath=ART.."BossHPFill.tga",
            color={.98823529411765,.058823529411765,0,1},
            conditions={{field="percenthealth",unit="target",op="<=",value=25,
                changes={{field="color",value={1,.46666666666667,.86666666666667,1}}}}}})
    Node("bossHPBorder","生命条描边","border","bossHP",0,0,806,14,1004,
        {internal=true,color={0,0,0,1},borderSize=1,enabled=false})
    Node("bossHPMetal","生命条金属框","texture","bossHP",0,-.00441894531,1200,150,1005,
        {internal=true,file=ART.."MangBossFrameMetal"})
    Node("bossHPGlass","生命条玻璃","texture","bossHP",0,-.00441894531,1200,150,1006,
        {internal=true,file=ART.."MangBossFrameGlass",blend="ADD"})
    Node("bossCast","首领施法条","group","bossFrames",0,-70.6,940,120,1007,{triggerAny="bossCast"})
    local casting={{test="casting",unit="target"}}
    Node("bossCastBackground","施法条背景","texture","bossCast",0,0,940,100,1008,
        {internal=true,file=ART.."MangTargetFrameCastBar",desaturate=true,blend="BLEND",rules=M.Copy(casting),bossEntry="fade"})
    Node("bossCastFill","施法进度","bar","bossCast",.458984375,0,706.707421875,3,1009,
        {internal=true,binding="cast",file=ART.."BossCastFill.tga",color={0,1,.5686274766922,1},
            background={0,0,0,.5},rules=M.Copy(casting),bossEntry="fade"})
    Node("bossCastGlass","施法条玻璃","texture","bossCast",0,0,799,120,1010,
        {internal=true,file=ART.."MangBossFrameGlass",blend="ADD",alpha=.75,rules=M.Copy(casting)})
    Node("bossAvatar","首领头像框体","group","bossFrames",-483,19.4,205,205,1012,{bossEntry="bounce"})
    Node("bossAvatarBackground","头像背景","texture","bossAvatar",0,0,205,205,1015,
        {internal=true,file=ART.."CenterBlack",color={0,0,0,1},alpha=.9})
    Node("bossPortrait","首领头像","portrait","bossAvatar",-1,8.98,81,81,1014,
        {internal=true,color={1,.99607843137255,.99607843137255,1}})
    Node("bossAvatarGlass","头像玻璃","texture","bossAvatar",0,0,205,205,1016,
        {internal=true,file=ART.."CenterGlassa",blend="ADD",alpha=.5})
    Node("bossAvatarMetal","头像金属框","texture","bossAvatar",6.04821777344,7.71441650391,512,256,1013,
        {internal=true,file=ART.."MangBossFrameTitle"})
    local low={{field="percenthealth",unit="target",op="<",value=20,
        changes={{field="color",value={1,.39,.79,1}}}}}
    Node("bossHPPercent","首领生命百分比","text","bossHPMetal",0,29.40441894531,240,30,1017,
        {binding="healthPercent",font="Myriad",fontSize=20,outline="OUTLINE",justify="CENTER",
            shadowX=3,shadowY=-3,autoWidth=true,conditions=M.Copy(low),bossEntry="fade"})
    return nodes
end
function M:EnsureBossFramesModule(design)
    -- Remove retired labels from saved designs and shared configs.
    for i=#design.nodes,1,-1 do
        if design.nodes[i].id=="bossHPValue" or design.nodes[i].id=="bossCastName" then table.remove(design.nodes,i) end
    end
    local seen={};for _,n in ipairs(design.nodes) do seen[n.id]=n end
    local templates=Templates()
    for _,n in ipairs(templates) do
        if not seen[n.id] then design.nodes[#design.nodes+1]=n;seen[n.id]=n end
    end
    local root=seen.bossFrames
    if root.hideAvatar==nil then root.hideAvatar=false end
    if root.bossLayoutRevision~=1 then
        local layers={bossAvatarMetal=1013,bossPortrait=1014,bossAvatarBackground=1015,bossAvatarGlass=1016}
        for id,layer in pairs(layers) do seen[id].layer=layer end
        local fill=seen.bossHPFill
        fill.file=ART.."BossHPChannel.tga";fill.alphaFill=true;fill.materialPath=ART.."BossHPFill.tga"
        fill.fillInset=nil;fill.fillExtent=nil;fill.startAt=nil
        seen.bossHPBorder.enabled=false
        seen.bossHPGlass.layer=seen.bossHPMetal.layer+1
        for _,template in ipairs(templates) do
            if template.id=="bossHPPercent" then
                local n=seen[template.id]
                n.parent=template.parent;n.x=0;n.y=template.y;n.justify="CENTER"
                n.point="CENTER";n.anchor="CENTER"
            end
        end
        root.bossLayoutRevision=1
    end
    if root.bossCastLayoutRevision~=2 then
        for _,template in ipairs(templates) do
            if template.id=="bossCast" or template.id=="bossCastBackground"
                or template.id=="bossCastFill" or template.id=="bossCastGlass" then
                local n=seen[template.id]
                for _,key in ipairs({"parent","x","y","width","height","scale","point","anchor",
                    "layer","file","blend","desaturate","alpha","color","background"}) do
                    n[key]=M.Copy(template[key])
                end
                n.reverse=nil;n.vertical=nil;n.fillInset=nil;n.fillExtent=nil;n.startAt=nil
            end
        end
        root.bossCastLayoutRevision=2
    end
    B.SyncNodes(design)
end
M.moduleIDs.bossFrames=true
M:EnsureBossFramesModule(M.defaults)
if M.recordedDefaults then M:EnsureBossFramesModule(M.recordedDefaults) end
function B.Visibility(view,o,state)
    local wanted=(view.preview or o.spec.enabled~=false) and not (view.hidden and view.hidden[o.spec.id])
        and (view.preview or state.exists and state.classification=="worldboss") or false
    if wanted~=o.bossWanted then
        if wanted then
            o.bossExiting=nil;o.bossStarted=GetTime()
            if not view.preview and o.spec.soundEnabled~=false and PlaySoundFile then PlaySoundFile(ART.."Boss\\BossShow.mp3","Master") end
            for _,child in ipairs(view.moduleBuckets and view.moduleBuckets.bossFrames or view.ordered) do
                if child.module and child.module.id=="bossFrames" then child.bossEntryShown=nil;child.bossEntryStart=nil end
            end
        elseif o.bossWanted and o.spec.enabled~=false and not view.preview then
            o.bossExiting=GetTime()
        else o.bossExiting=nil end
        o.bossWanted=wanted
    end
    o.frame:SetShown(wanted or o.bossExiting~=nil)
end
function B.Animate(view)
    view.bossAnimating=false
    local root=view.nodes.bossFrames
    if not root or not root.frame:IsShown() then return end
    local now=GetTime();local exit=root.bossExiting
    if exit then
        local p=M.Clamp((now-exit)/.25,0,1)
        root.frame:SetAlpha((root.spec.alpha or 1)*(1-p))
        if p>=1 then root.bossExiting=nil;root.frame:Hide();return end
        view.bossAnimating=true
    else root.frame:SetAlpha(root.spec.alpha or 1) end
    local cast=view.nodes.bossCast
    if cast and cast.bossExiting then
        local p=M.Clamp((now-cast.bossExiting)/.25,0,1)
        cast.frame:SetAlpha((cast.spec.alpha or 1)*(1-p))
        if p>=1 then cast.bossExiting=nil;cast.frame:Hide() else view.bossAnimating=true end
    end
    for _,o in ipairs(view.moduleBuckets and view.moduleBuckets.bossFrames or view.ordered) do
        local n=o.spec
        if o.module and o.module.id=="bossFrames" and n.bossEntry then
            local shown=o.frame:IsShown()
            if shown and not o.bossEntryShown then o.bossEntryStart=now end
            o.bossEntryShown=shown
            if not shown then o.bossEntryStart=nil end
            if o.bossEntryStart or (exit and n.bossEntry=="bounce") then
                local duration=n.bossEntry=="bounce" and 2 or .25
                local p=M.Clamp((now-(o.bossEntryStart or now))/duration,0,1)
                if n.bossEntry=="bounce" then
                    local offset=not exit and B.EntryOffset(p) or 50*M.Clamp((now-exit)/.25,0,1)
                    o.frame:ClearAllPoints();o.frame:SetPoint(n.point,o.geometryParent,n.anchor,n.x,n.y+offset)
                elseif not exit then o.frame:SetAlpha((n.alpha or 1)*p) end
                if p<1 then view.bossAnimating=true else o.bossEntryStart=nil end
            end
        end
    end
end
function B.CastVisibility(view,o,state)
    local wanted=state.cast.active and o.spec.enabled~=false
        and not (view.hidden and view.hidden[o.spec.id]) or false
    if wanted~=o.bossWanted then
        if wanted then o.bossExiting=nil;o.frame:SetAlpha(o.spec.alpha or 1)
        elseif o.bossWanted and not view.preview then o.bossExiting=GetTime() end
        o.bossWanted=wanted
    end
    o.frame:SetShown(wanted or o.bossExiting~=nil)
end
function B.StopTest()
    local view=B.testView
    if not view then return end
    view.root:SetScript("OnUpdate",nil);view.root:Hide();view.testStarted=nil
end
function B.StopMovePreview()
    local view=B.moveView
    if view then view.root:SetScript("OnUpdate",nil);view.root:Hide() end
end
local function MoveState(unit,preview,scene,out)
    local state=M.Compat.State(unit,true,"normal",out)
    state.unit="player";state.classification="worldboss";state.exists=true
    state.cast.active=true;state.cast.start=GetTime()-5;state.cast.finish=GetTime();state.cast.channel=false
    return state
end
function B.StartMovePreview()
    B.StopTest()
    local R=M.Renderer
    local view=B.moveView
    if not view then
        view=R.New(UIParent,false);B.moveView=view
        view.root:SetFrameStrata("DIALOG");view.root:EnableMouse(false)
        view.stateProvider=MoveState
    end
    for _,o in ipairs(view.ordered or {}) do o.bossWanted=nil;o.bossExiting=nil end
    local design={nodes={}}
    for _,n in ipairs(M.db.design.nodes) do
        if M:ModuleID(n)=="bossFrames" then
            local copy=M.Copy(n)
            if copy.id=="bossFrames" then copy.enabled=true;copy.soundEnabled=false
            elseif copy.id=="bossPortrait" then copy.unit="player" end
            design.nodes[#design.nodes+1]=copy
        end
    end
    M:EnsureBossFramesModule(design)
    view.root:Show();R.Apply(view,design)
    local elapsed=0
    view.root:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt
        if elapsed>=.2 then elapsed=0;R.Update(view) end
        R.Animate(view)
    end)
    return view
end
local function TestState(unit,preview,scene,out)
    local view=B.testView
    local state=M.Compat.State(unit,true,"normal",out)
    local started=view.testStarted or GetTime()-10
    local elapsed=GetTime()-started
    state.unit="player";state.classification="worldboss";state.exists=elapsed<8
    local cast=state.cast
    cast.active=elapsed>=2 and elapsed<7.5
    cast.name=M:T("施法预览");cast.start=started+2;cast.finish=started+7;cast.channel=false
    return state
end
function B.Test(command)
    if command=="stop" then B.StopTest();return end
    if not M.db then M:Print("配置尚未就绪。");return end
    if InCombatLockdown() then M:Print("请脱离战斗后测试首领框体。");return end
    B.StopTest()
    if M.editor then M.editor.window:Hide() end
    local R=M.Renderer
    local view=B.testView
    if not view then
        view=R.New(UIParent,false);B.testView=view
        view.root:SetFrameStrata("DIALOG");view.root:EnableMouse(false)
        view.stateProvider=TestState
        view.root:RegisterEvent("PLAYER_REGEN_DISABLED")
        view.root:SetScript("OnEvent",B.StopTest)
    end
    for _,o in ipairs(view.ordered or {}) do o.bossWanted=nil;o.bossExiting=nil end
    local design={nodes={}}
    for _,n in ipairs(M.db.design.nodes) do
        if M:ModuleID(n)=="bossFrames" then
            local copy=M.Copy(n)
            if copy.id=="bossFrames" then
                copy.screenAnchor=nil;copy.x=0;copy.y=0;copy.enabled=true
            elseif copy.id=="bossPortrait" then copy.unit="player" end
            design.nodes[#design.nodes+1]=copy
        end
    end
    M:EnsureBossFramesModule(design)
    view.testStarted=GetTime();view.root:Show()
    R.Apply(view,design)
    view.root:SetScript("OnUpdate",function()
        R.Update(view);R.Animate(view)
        if GetTime()-view.testStarted>=8.3 then B.StopTest() end
    end)
end
