local _,M=...
local C=M.Compat
local P={};M.Portraits=P
local CIRCLE="Interface\\AddOns\\MangUI\\Assets\\Library\\MainSweepPortraitMask.tga"
local LOGO="Interface\\AddOns\\MangUI\\Assets\\UI\\Logo.png"
local DEAD="Interface\\AddOns\\MangUI\\Assets\\Library\\Dead.blp"
local function Inspect(object,method,...)
    if not object or not object[method] then return "unavailable" end
    local ok,value=pcall(object[method],object,...)
    if not ok then return "read-error" end
    if not C.Readable(value) then return "restricted" end
    if type(value)=="string" then return value:sub(1,180) end
    if type(value)=="number" or type(value)=="boolean" then return value end
    return "nil"
end
local function UnitFlag(fn,unit)
    if not fn then return "unavailable" end
    local ok,value=pcall(fn,unit)
    if not ok then return "read-error" end
    if not C.Readable(value) then return "restricted" end
    return not not value
end
function P.Snapshot(o,unit,phase)
    local frame=o.frame;local texture=o.texture
    local row={time=GetTime(),unit=unit,phase=phase,combat=InCombatLockdown(),
        callOK=o.staticPortraitError==nil,calls=o.staticPortraitDraws or 0,error=o.staticPortraitError and tostring(o.staticPortraitError):sub(1,240),
        exists=UnitFlag(UnitExists,unit),unitVisible=UnitFlag(UnitIsVisible,unit),connected=UnitFlag(UnitIsConnected,unit),
        frameShown=Inspect(frame,"IsShown"),frameVisible=Inspect(frame,"IsVisible"),frameAlpha=Inspect(frame,"GetAlpha"),
        width=Inspect(frame,"GetWidth"),height=Inspect(frame,"GetHeight"),scale=Inspect(frame,"GetEffectiveScale"),
        textureShown=Inspect(texture,"IsShown"),textureVisible=Inspect(texture,"IsVisible"),textureAlpha=Inspect(texture,"GetAlpha"),
        -- Metadata only: this is never used to judge whether pixels were drawn.
        textureReference=Inspect(texture,"GetTexture"),parents={}}
    if texture.GetVertexColor then
        local ok,r,g,b,a=pcall(texture.GetVertexColor,texture)
        if ok and C.Readable(a) then row.vertexAlpha=a end
    end
    if texture.GetTexCoord then
        local values={pcall(texture.GetTexCoord,texture)}
        if values[1] then
            row.coordinates={}
            for i=2,#values do row.coordinates[#row.coordinates+1]=C.Readable(values[i]) and values[i] or "restricted" end
        end
    end
    local parent=frame:GetParent()
    for _=1,7 do
        if not parent then break end
        row.parents[#row.parents+1]={shown=Inspect(parent,"IsShown"),visible=Inspect(parent,"IsVisible"),
            alpha=Inspect(parent,"GetAlpha"),protected=Inspect(parent,"IsProtected")}
        parent=parent:GetParent()
    end
    return row
end
local function Trace(o,unit,phase,beforeAlpha,beforeShown)
    if not M.db or (not InCombatLockdown() and not o.staticPortraitError) then return end
    local trace=M.db.portraitTrace
    if type(trace)~="table" or trace.version~=M.version then trace={version=M.version,rows={}};M.db.portraitTrace=trace end
    local row=P.Snapshot(o,unit,phase);row.beforeAlpha=beforeAlpha;row.beforeShown=beforeShown
    local rows=trace.rows
    if #rows>=32 then table.remove(rows,1) end
    rows[#rows+1]=row
end
local function DrawStatic(o,unit,phase)
    local texture=o.texture
    local beforeAlpha=Inspect(texture,"GetAlpha");local beforeShown=Inspect(texture,"IsShown")
    local function Draw()
        -- The source must be shown before the client prepares its portrait.
        texture:SetShown(true);texture:SetAlpha(1)
        SetPortraitTexture(texture,unit)
        local color=o.staticPortraitColor
        if color then texture:SetVertexColor(color[1],color[2],color[3],color[4] or 1) end
    end
    local ok,err=pcall(Draw)
    o.staticPortraitDraws=(o.staticPortraitDraws or 0)+1
    o.staticPortraitError=nil
    if not ok then o.staticPortraitError=err end
    Trace(o,unit,phase,beforeAlpha,beforeShown)
end
local function DeferredStatic(view,o)
    if not C_Timer or not C_Timer.After or o.staticPortraitQueued then return end
    o.staticPortraitQueued=true
    C_Timer.After(0,function()
        o.staticPortraitQueued=nil
        if view.preview or o.removed or o.portrait3D or not o.frame:IsVisible()
            or (o.module and o.module.enabled==false) then return end
        local unit=C.Unit(o.spec.unit)
        if not C.Bool(UnitExists(unit)) then return end
        DrawStatic(o,unit,"next-frame")
    end)
end
local function MainStaticPortrait(o,unit)
    local guid=UnitGUID and UnitGUID(unit)
    if not C.Readable(guid) then guid=nil end
    local now=GetTime()
    if o.portraitRefresh or o.staticPortraitUnit~=unit or o.staticPortraitGUID~=guid then
        o.staticPortraitUnit,o.staticPortraitGUID=unit,guid
        o.staticPortraitAttempt=0;o.staticPortraitRetryAt=now
        o.portraitRefresh=nil
    end
    local combat=InCombatLockdown()
    if combat and not o.staticPortraitRetryAt then o.staticPortraitRetryAt=now end
    if not o.staticPortraitRetryAt or now<o.staticPortraitRetryAt then return end
    -- Match the reference WA: draw directly into the native portrait texture.
    -- GetTexture is not a readiness test or a restorable portrait snapshot.
    -- Never clear/replace this texture with SetTexture during live 2D updates.
    DrawStatic(o,unit,o.staticPortraitReason or "scheduled")
    o.staticPortraitReason=nil
    local attempt=math.min(4,o.staticPortraitAttempt+1);o.staticPortraitAttempt=attempt
    -- Native drawing has no reliable success/readiness return value. Continue
    -- once per second in combat even after a long model load or a silent failure.
    o.staticPortraitRetryAt=attempt<4 and (now+.2*2^(attempt-1))
        or ((combat or o.staticPortraitError) and (now+1) or nil)
end
local function ShowSource(o,fallback)
    local model=o.portraitModel
    o.texture:SetShown(not o.portraitDead and (not o.portrait3D or fallback))
    if o.portraitBackground then o.portraitBackground:SetShown(not o.portraitDead and o.portrait3D and not fallback) end
    if model then
        -- Internal source changes must not trigger the external hide/show reload.
        model.portraitSwitching=true
        model:SetShown(model.portraitActive and not fallback and not model.movementSuppressed)
        model.portraitSwitching=nil
    end
end
local function Fallback(o)
    local model=o.portraitModel
    model.portraitFallback=true;model.portraitCheckLoad=nil
    model.portraitRetry=GetTime()+1
    model:SetScript("OnUpdate",nil);model:ClearModel()
    -- Let the client supply its cached portrait or default race/sex portrait.
    o.texture:SetTexture(nil);SetPortraitTexture(o.texture,model.portraitUnit)
    ShowSource(o,true)
end
local function Pose(model)
    -- SetCamera selects an authored M2 camera, which differs across models;
    -- it must not override PlayerModel's unit-specific portrait framing.
    if model.SetCamDistanceScale then model:SetCamDistanceScale(1) end
    -- Force recalculation even when loading/layout retained a cached zoom of 1.
    model:SetPortraitZoom(0)
    model:SetPortraitZoom(1)
    model:SetPosition(0,0,0)
end
local function SettledPose(model)
    model:SetScript("OnUpdate",nil)
    if model.movementSuppressed or not model.portraitActive or model.portraitFallback then return end
    if model.portraitCheckLoad and model.GetModelFileID then
        local file=model:GetModelFileID()
        if C.Readable(file) and file==0 then Fallback(model.portraitObject);return end
    end
    model.portraitCheckLoad=nil
    Pose(model)
    if model.portraitAlpha then model:SetAlpha(model.portraitAlpha) end
end
local function QueuePose(model)
    -- Loading/layout can reset the camera after their callback returns.
    -- Settle it once next frame, without a permanent OnUpdate handler.
    if not model.movementSuppressed and model.portraitActive and not model.portraitFallback then model:SetScript("OnUpdate",SettledPose) end
end
local function Unit(view,o)
    return C.Unit(o.spec.unit)
end
local function Load(view,o,force)
    if view.preview or view.movementModelsHidden then return end
    local model=o.portraitModel
    local unit=Unit(view,o)
    local guid=UnitGUID and UnitGUID(unit)
    if not C.Readable(guid) then guid=nil end
    local available=C.Bool(UnitExists(unit)) and C.Bool(UnitIsConnected(unit))
        and (not UnitIsVisible or C.Bool(UnitIsVisible(unit)))
    if available and model.CanSetUnit then
        local allowed=model:CanSetUnit(unit)
        if C.Readable(allowed) and allowed==false then available=false end
    end
    local retry=model.portraitFallback and available and GetTime()>=(model.portraitRetry or 0)
    if not force and not o.portraitRefresh and not model.portraitDirty and not retry
        and model.portraitUnit==unit and model.portraitGUID==guid and model.portraitAvailable==available then return end
    model.portraitUnit,model.portraitGUID,model.portraitAvailable=unit,guid,available
    model.portraitDirty=false;o.portraitRefresh=nil
    model.portraitFallback=not available
    model:ClearModel()
    if available then
        Pose(model)
        local ok,loaded=pcall(model.SetUnit,model,unit)
        if not ok or (C.Readable(loaded) and loaded==false) then model.portraitFallback=true end
    end
    if model.portraitFallback then Fallback(o);return end
    model.portraitRetry=nil;model.portraitCheckLoad=true
    ShowSource(o,false)
    Pose(model)
    QueuePose(model)
    if model.portraitAlpha then model:SetAlpha(model.portraitAlpha) end
end
function P.Configure(view,o)
    if not view.preview and not o.staticPortraitShowHook
        and (o.spec.id=="wa88b1376baa" or o.spec.id=="wa0b0b0540c7") then
        o.staticPortraitShowHook=true
        o.frame:HookScript("OnShow",function()o.portraitRefresh=true;o.staticPortraitReason="shown" end)
    end
    if o.spec.unit=="pet" and not o.portraitDeathTexture then
        local death=o.frame:CreateTexture(nil,"ARTWORK")
        death:SetAllPoints(o.frame);death:SetTexture(M:TexturePath(o.spec,DEAD,"portraitDeath"));death:SetBlendMode("BLEND")
        death:SetVertexColor(1,1,1,1);death:Hide();o.portraitDeathTexture=death
    end
    if view.preview then
        o.portraitDead=false
        if o.portraitDeathTexture then o.portraitDeathTexture:Hide() end
    end
    local was3D=o.portrait3D
    o.portrait3D=not view.preview and M.db.portrait3D==true
    if o.portrait3D and not o.portraitModel then
        local background=o.frame:CreateTexture(nil,"BACKGROUND")
        background:SetAllPoints(o.frame);background:SetTexture(M:TexturePath(o.spec,CIRCLE,"portraitBackground"))
        background:SetVertexColor(0,0,0,1);background:SetBlendMode("BLEND")
        o.portraitBackground=background
        local viewport=CreateFrame("Frame",nil,o.frame)
        viewport:EnableMouse(false);viewport:SetPoint("CENTER",o.frame,"CENTER",0,0)
        o.portraitViewport=viewport
        local model=CreateFrame("PlayerModel",nil,viewport)
        o.portraitModel=model
        model.portraitObject=o
        -- Isolate the native camera from the small groups' compounded scale.
        -- Anchors still follow the portrait's actual on-screen bounds.
        if model.SetIgnoreParentScale then model:SetIgnoreParentScale(true) end
        model:SetScale(1)
        model:SetAllPoints(viewport);model:EnableMouse(false)
        if model.SetModelDrawLayer then model:SetModelDrawLayer("ARTWORK") end
        if model.SetKeepModelOnHide then model:SetKeepModelOnHide(false) end
        model:SetScript("OnModelLoaded",function(self)
            if self.movementSuppressed then self:Hide();self:ClearModel();return end
            if not self.portraitActive or self.portraitFallback then return end
            Pose(self)
            if self.portraitAlpha then self:SetAlpha(self.portraitAlpha) end
            QueuePose(self)
        end)
        model:SetScript("OnSizeChanged",QueuePose)
        model:SetScript("OnHide",function(self)
            if not self.portraitSwitching then self.portraitDirty=true end
            self:SetScript("OnUpdate",nil)
        end)
        model:SetScript("OnShow",function(self)
            if self.movementSuppressed then self:Hide();return end
            if self.portraitSwitching then return end
            self.portraitDirty=true
            if not view.applying and o.portrait3D then Load(view,o,true) end
        end)
        model:Hide()
    end
    -- Static fallbacks and previews fill the complete boss lens even when its
    -- model viewport is the smaller rectangle inscribed inside that circle.
    o.texture:ClearAllPoints()
    if o.spec.id=="bossPortrait" and M.db.portrait3D then
        o.texture:SetPoint("CENTER",o.frame,"CENTER",0,0)
        o.texture:SetSize(o.spec.width*math.sqrt(2),o.spec.height*math.sqrt(2))
    else o.texture:SetAllPoints(o.frame) end
    local model=o.portraitModel
    if model then
        -- Leave a further 2% margin beneath the existing rim, including small
        -- portraits. Keep the 2D source and decorative frame at their sizes.
        o.portraitViewport:SetSize(o.spec.width*.98,o.spec.height*.98)
        o.portraitViewport:SetFrameLevel(o.frame:GetFrameLevel())
        M.Renderer.SuppressMovementModel(view,model)
        -- Match the old portrait's level, below its black, glass and rim layers.
        if model.SetFrameStrata and o.frame.GetFrameStrata then model:SetFrameStrata(o.frame:GetFrameStrata()) end
        model:SetFrameLevel(o.frame:GetFrameLevel())
        model.portraitActive=o.portrait3D and not o.portraitDead
        -- Unrelated editor changes must retain the already loaded unit model.
        if was3D~=o.portrait3D then model.portraitDirty=true end
        if model.portraitActive and model.portraitDirty then QueuePose(model) end
        if not o.portrait3D and was3D then
            model:ClearModel();model.portraitUnit=nil;model.portraitGUID=nil
            model.portraitFallback=nil;model.portraitCheckLoad=nil;model:SetScript("OnUpdate",nil)
        end
    end
    ShowSource(o,model and model.portraitFallback)
    if view.preview then
        local texture=o.texture
        texture:SetTexture(M:TexturePath(o.spec,LOGO,"portraitPreview"));texture:SetTexCoord(0,1,0,1)
        texture:SetBlendMode("BLEND");texture:SetDesaturated(false)
        texture:SetRotation(0);texture:SetVertexColor(1,1,1,1)
        if not o.previewPortraitMask then
            local mask=o.frame:CreateMaskTexture()
            mask:SetTexture(M:TexturePath(o.spec,CIRCLE,"portraitPreviewMask"));mask:SetAllPoints(texture)
            texture:AddMaskTexture(mask);o.previewPortraitMask=mask
        end
    end
    if not o.portrait3D or was3D~=o.portrait3D then
        o.portraitRefresh=true
    elseif model and model.portraitFallback and model.portraitUnit then
        -- Renderer setup replaced the static texture; restore the cached
        -- fallback without restarting the native model on every slider tick.
        SetPortraitTexture(o.texture,model.portraitUnit)
    end
end
function P.Paint(view,o,state,color,animateOnly)
    if view.preview then
        o.texture:SetVertexColor(1,1,1,color[4] or 1)
        o.portraitRefresh=nil
        return
    end
    if o.portraitDeathTexture then
        local dead=state.dead==true
        if o.portraitDead~=dead then
            o.portraitDead=dead;o.portraitRefresh=true
            o.portraitDeathTexture:SetShown(dead)
            if o.portraitModel then
                o.portraitModel.portraitActive=not dead and o.portrait3D
            end
            ShowSource(o,o.portraitModel and o.portraitModel.portraitFallback)
        end
        if dead then o.portraitDeathTexture:SetAlpha(color[4] or 1);return end
    end
    if o.portrait3D then
        local model=o.portraitModel
        if view.movementModelsHidden then model:Hide();return end
        local alpha=color[4] or 1
        if model.portraitAlpha~=alpha then model:SetAlpha(alpha);model.portraitAlpha=alpha end
        o.texture:SetVertexColor(1,1,1,alpha)
        if not animateOnly then Load(view,o) end
    elseif not animateOnly then
        if o.spec.id=="wa88b1376baa" or o.spec.id=="wa0b0b0540c7" then
            local tint=o.staticPortraitColor or {};o.staticPortraitColor=tint
            tint[1],tint[2],tint[3],tint[4]=color[1],color[2],color[3],color[4]
            if o.portraitRefresh or o.staticPortraitUnit~=state.unit then DeferredStatic(view,o) end
            MainStaticPortrait(o,state.unit)
        else
            if o.portraitRefresh then o.texture:SetTexture(nil);o.portraitRefresh=nil end
            SetPortraitTexture(o.texture,state.unit)
        end
    end
end
function P.Invalidate(view,unit,reason)
    if not view or view.preview then return end
    for _,o in ipairs(view.ordered or {}) do
        local n=o.spec
        if n.kind=="portrait" and (not unit or n.unit==unit or n.unit=="shared"
            or (unit=="vehicle" and n.unit=="player")) then
            o.portraitRefresh=true
            o.staticPortraitReason=reason
        end
    end
end
function P.Report()
    local view=M.live
    if not view then return end
    local trace=M.db and M.db.portraitTrace
    local rows=trace and trace.rows or {}
    local o=view.nodes.wa0b0b0540c7 or view.nodes.wa88b1376baa
    if not o then return end
    local row=P.Snapshot(o,C.Unit(o.spec.unit),"manual")
    if M.db then M.db.portraitSnapshot=row end
    M:Print("头像状态已记录；调用无报错不代表图像已经绘制。")
    M:Print(string.format("%s · 2D=%s · 战斗=%s · 单位可见=%s · 框体可见=%s · 贴图可见=%s · 贴图透明度=%s",
        row.unit,tostring(not o.portrait3D),tostring(row.combat),tostring(row.unitVisible),tostring(row.frameVisible),tostring(row.textureVisible),tostring(row.textureAlpha)))
    M:Print("框体透明度="..tostring(row.frameAlpha).." · 顶点透明度="..tostring(row.vertexAlpha).." · 纹理标识="..tostring(row.textureReference))
    M:Print("头像调用错误："..(row.error or "无").." · 已记录 "..#rows.." 次战斗绘制调用。")
end
