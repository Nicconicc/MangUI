local _,M=...
local C,B,R=M.Compat,M.MainBarLayout,M.Renderer
local unpack=unpack or table.unpack
local private=M.RendererInternals
local raidMarkFiles=private.raidMarkFiles
local raidMarkSheet="Interface\\AddOns\\MangUI\\Assets\\Target\\RaidMark\\Target_waf24f8d43e3_Atlas-v3.tga"
local Readable=private.Readable
local Cache=private.Cache
local CachedValue=private.CachedValue
local CachedPair=private.CachedPair
local CachedColor=private.CachedColor
local HealthTint=private.HealthTint
local CachedPoint=private.CachedPoint
local ResetParticle=private.ResetParticle
local State=private.State
local Rule=private.Rule
local Appearance=private.Appearance
local CastRatio=private.CastRatio
local DisplayRatio=private.DisplayRatio
local RestrictedHealthColor=private.RestrictedHealthColor
local RestrictedHealthThreshold=private.RestrictedHealthThreshold
local Text=private.Text
local Auras=private.Auras
local ResourceAnimate=private.ResourceAnimate
local ResourcePaint=private.ResourcePaint
local FillStart=private.FillStart
local CenterLogo=private.CenterLogo
local Sprite=private.Sprite
local Spin=private.Spin
local emptyState=private.emptyState
local DecorationTint=private.DecorationTint
-- The engine texture only measures the secret-valued fill region. Its color
-- alpha must stay zero on every update; visible artwork has its own tint.
local nativeDriverColor={1,1,1,0}

local function NativeSparkAlpha(o,s,alpha)
    if not (C_CurveUtil and C_CurveUtil.CreateColorCurve and CreateColor
        and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step) then return end
    if not Readable(alpha) or type(alpha)~="number" then return end
    local power=o.spec.binding=="power"
    local query=power and UnitPowerPercent or UnitHealthPercent
    if not query then return end
    if not o.sparkCurve or o.sparkCurveAlpha~=alpha then
        local curve=C_CurveUtil.CreateColorCurve();curve:SetType(Enum.LuaCurveType.Step)
        curve:AddPoint(0,CreateColor(1,1,1,0))
        curve:AddPoint(1e-9,CreateColor(1,1,1,alpha))
        curve:AddPoint(1,CreateColor(1,1,1,0))
        o.sparkCurve=curve;o.sparkCurveAlpha=alpha
    end
    local ok,color
    if power then ok,color=pcall(query,s.unit,s.powerType,false,o.sparkCurve)
    else ok,color=pcall(query,s.unit,true,o.sparkCurve) end
    if ok and color and color.GetRGBA then
        local _,_,_,value=color:GetRGBA()
        -- The engine evaluates endpoint visibility; never compare secret ratios.
        CachedValue(o,"frameAlpha",o.frame,"SetAlpha",value)
    end
end

local function Paint(view,o,animateOnly,visibleHint)
    local n=o.spec;local f=o.frame
    -- An isolated preview has no work for the other modules, including their
    -- unit queries and custom painters. Tab selection refreshes newly shown nodes.
    if view.preview and view.hidden and view.hidden[n.id] then
        if f:IsShown() then f:Hide() end
        o.wasShown=false;o.started=nil
        return
    end
    local bossRoot=o.module and o.module.id=="bossFrames" and view.nodes.bossFrames
    if bossRoot and bossRoot.bossExiting and n.id~="bossFrames" then return end
    local bossCast=bossRoot and view.nodes.bossCast
    if bossCast and bossCast.bossExiting and n.parent=="bossCast" then return end
    if o.focusPortraitOnlyHidden then if f:IsShown() then f:Hide() end;return end
    -- Apply hides the entire disabled module outside combat, including unit watches.
    -- Keep previews editable and never re-show a disabled module on later events.
    if not view.preview and o.module and o.module.enabled==false then return end
    if n.attackKind then
        if n.enabled==false then if f:IsShown() then f:Hide() end;return end
        M.AttackProgress.Paint(view,o,State(view,"player"));return
    end
    -- Normal updates own rules/tint. A visible animation frame only needs its
    -- time-dependent work; restricted colors continue through the native path.
    if animateOnly and visibleHint and not view.preview and o.fastReady then
        local now=view.animationNow
        if n.effectOnce and not (o.effectStarted and now-o.effectStarted<o.effectDuration) then
            o.wasShown=false;o.started=nil;f:Hide();return
        end
        if (n.particleFlow or n.spinPeriod) and view.animationCasting==nil then
            view.animationCasting=State(view,"player").cast.active or false
        end
        if n.spinPeriod and o.texture and o.texture.SetRotation then Spin(view,o,now,view.animationCasting) end
        if n.kind=="sprite" then Sprite(view,o,o.animationAlpha,now,view.animationCasting)
        elseif n.kind=="glow" then CachedValue(o,"frameAlpha",f,"SetAlpha",o.animationAlpha*(.65+.35*math.sin(now*3)^2)) end
        return
    end
    if n.kind=="combatnotice" then M.CombatNotices.Paint(view,o);return end
    if n.kind=="systemmenu" then M.SystemMenu.Paint(view,o);return end
    if n.kind=="mousecircle" then M.MouseCircle.Paint(view,o);return end
    if n.kind=="experiencebar" then M.ExperienceBar.Paint(view,o,animateOnly);return end
    if n.kind=="targetthreat" then M.TargetThreat.Paint(view,o,animateOnly);return end
    if n.kind=="targetdistance" then M.TargetDistance.Paint(view,o,animateOnly);return end
    if n.kind=="chatbuttons" then
        local shown=n.enabled~=false and not (view.hidden and view.hidden[n.id])
        if f:IsShown()~=shown then f:SetShown(shown) end
        if shown then M.ChatButtons.Refresh(view,o) end
        return
    end
    if n.kind=="cooldowns" then
        local visible=n.enabled~=false and not (view.hidden and view.hidden[n.id])
        if f:IsShown()~=visible then f:SetShown(visible) end
        if f:IsVisible() then M.CooldownMonitor.Paint(view,o) end
        return
    end
    -- Secure visibility layers refresh synchronously on show. Their hidden
    -- descendants need neither unit queries nor invisible particle playback.
    if not view.preview and not visibleHint and not f:GetParent():IsVisible() then
        if n.particleFlow then
            ResetParticle(o)
        end
        return
    end
    if n.centerLogo then CenterLogo(view,o);return end
    if n.kind=="group" then
        -- Tab isolation hides parent groups as well as their visuals. Restore
        -- those parents when revisiting a module without changing its settings.
        if view.preview then
            local shown=n.enabled~=false or M.moduleIDs[n.id]==true
            if f:IsShown()~=shown then f:SetShown(shown) end
        end
        if n.triggerAny=="bossTarget" then M.BossFrames.Visibility(view,o,State(view,"target"));return end
        if n.triggerAny=="bossCast" then M.BossFrames.CastVisibility(view,o,State(view,"target"));return end
        if n.triggerAny=="targetOrPlayerCast" and not animateOnly then
            local shown=n.enabled~=false and (State(view,"target").exists or State(view,"player").cast.active)
            if view.preview and view.selected==n.id then shown=true end
            if view.hidden and view.hidden[n.id] then shown=false end
            f:SetShown(shown)
        end
        return
    end
    if n.kind=="hitbox" and not view.preview then return end
    if (n.binding=="auraStacks" or n.binding=="auraTime") and not (view.preview and view.selected==n.id) then
        f:Hide();return
    end
    local s=o.needsState and State(view,n.unit) or emptyState;local shown=n.enabled~=false
    if n.unit=="target" and n.binding=="powerText" and s.classification=="worldboss" then shown=false end
    if n.visibleUnit then shown=shown and State(view,n.visibleUnit).exists end
    for _,rule in ipairs(n.rules or {}) do shown=shown and Rule(view,rule) end
    if n.binding=="partyRole" and n.partyIndex~=nil then
        shown=shown and (s.partyRole=="TANK" or s.partyRole=="HEALER")
    end
    if view.preview and n.id=="waf24f8d43e3" then
        shown=n.enabled~=false and State(view,"target").exists
    end
    if view.preview and (n.id=="wad38d9b944e" or n.id=="wad25ba7d231") then
        shown=n.enabled~=false and State(view,"target").exists
    end
    -- Keep the optional player percentage selectable in the design preview
    -- after hiding it in the live UI, including after reopening the editor.
    if view.preview and (view.selected==n.id or n.id=="playerHealthPercent") then shown=true end
    if view.hidden and view.hidden[n.id] then shown=false end
    if n.kind=="hitbox" then shown=false end
    local nativeSparkOwner
    if n.kind=="spark" and n.edgeOnly then
        local owner=view.nodes[n.owner];local p=owner and owner.displayRatio
        if not view.preview and owner and owner.nativeArt and p==nil
            and (n.binding=="health" or n.binding=="power") then nativeSparkOwner=owner end
        shown=shown and (nativeSparkOwner~=nil or (type(p)=="number" and p>0 and p<1))
    end
    if n.effectOnce then
        local trigger=n.effectTrigger
        local targetPulse=trigger~="cast" and (view.effectTargetPulse or 0) or 0
        local castPulse=trigger~="target" and (view.effectCastPulse or 0) or 0
        if shown and (not o.effectCondition or o.effectTargetPulse~=targetPulse or o.effectCastPulse~=castPulse) then
            o.effectStarted=GetTime();o.effectTargetPulse=targetPulse;o.effectCastPulse=castPulse
        end
        o.effectCondition=shown
        local frames=math.min(n.frames or 1,(n.rows or 1)*(n.columns or 1))
        local duration=frames/math.max(1,n.fps or 30)
        o.effectDuration=duration
        shown=shown and o.effectStarted and GetTime()-o.effectStarted<duration
    end
    if not animateOnly or (n.kind=="spark" and n.edgeOnly) or n.effectOnce then
        if shown and not o.wasShown then o.started=GetTime() elseif not shown then o.started=nil end
        o.wasShown=shown;if f:IsShown()~=shown then f:SetShown(shown) end
    end
    if not shown or not (visibleHint or f:IsVisible()) then
        if n.particleFlow then
            ResetParticle(o)
        end
        return
    end
    local col,alpha
    if animateOnly and o.animationColor then col,alpha=o.animationColor,o.animationAlpha
    else
        col,alpha=Appearance(view,n,s,o);o.animationColor,o.animationAlpha=col,alpha
    end
    if not animateOnly then
        o.fastReady=o.fastVisual and Readable(alpha) and Readable(col[1]) and Readable(col[2]) and Readable(col[3]) and Readable(col[4] or 1)
    end
    if not n.particleFlow and n.kind~="glow" and not (nativeSparkOwner and animateOnly and o.nativeSpark) then
        CachedValue(o,"frameAlpha",f,"SetAlpha",alpha)
    end
    if o.text then
        if n.binding=="healthPercent" and s.healthRatio==nil and UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then
            local percent=UnitHealthPercent(s.unit,true,CurveConstants.ScaleTo100)
            o.text:SetFormattedText("%.0f%%",percent)
            o.shadow:SetFormattedText("%.0f%%",percent)
            Cache(o).text=nil;Cache(o).shadowText=nil;o.textWidthDirty=true
        else
            local value=Text(n,s)
            local changed=CachedValue(o,"text",o.text,"SetText",value)
            CachedValue(o,"shadowText",o.shadow,"SetText",value)
            o.textWidthDirty=o.textWidthDirty or changed
        end
        local partyTextSized=M.PartyFrames and M.PartyFrames.LayoutText(o)
        if not partyTextSized and (n.autoWidth or n.id=="wa8492858a6d") and o.textWidthDirty then
            local ok,natural=false,nil
            if o.text.GetUnboundedStringWidth then ok,natural=pcall(o.text.GetUnboundedStringWidth,o.text) end
            local fallback=math.max(800,(n.fontSize or 20)*24)
            local width=ok and Readable(natural) and type(natural)=="number" and natural+16 or fallback
            CachedValue(o,"textWidth",f,"SetWidth",math.max(n.width or 200,math.ceil(width)))
            o.textWidthDirty=nil
        end
        CachedColor(o,"textColor",o.text,"SetTextColor",col)
        local shadowColor=o.shadowColor or {0,0,0,1};o.shadowColor=shadowColor;shadowColor[4]=col[4] or 1
        CachedColor(o,"shadowColor",o.shadow,"SetTextColor",shadowColor)
    elseif o.bar then
        local barColorChanged=CachedColor(o,"barColor",o.bar,"SetStatusBarColor",o.nativeArt and nativeDriverColor or col)
        local inset=n.alphaFill and (n.fillInset or 0) or 0
        local extent=n.alphaFill and (n.fillExtent or 1) or 1
        local moving=B.Moving(view,n)
        local followsPortrait=B.bars[n.id]~=nil
        local start=animateOnly and not view.preview and not o.animatedEdge and not moving and not o.fillEdgeMoving and o.fillStart or FillStart(view,n,f)
        o.fillEdgeMoving=moving
        o.fillStart=start
        if n.startAt or followsPortrait then
            local available=math.max(.001,n.width*extent-start)
            local anchor=n.reverse and "RIGHT" or "LEFT"
            CachedPoint(o,"barPoint",o.bar,anchor,f,anchor,n.reverse and -inset-start or inset+start,0)
            CachedPair(o,"barSize",o.bar,"SetSize",available,n.height)
            local leftCoord,rightCoord
            if followsPortrait then
                leftCoord=n.reverse and (n.width-inset-n.width*extent)/n.width or (inset+start)/n.width
                rightCoord=n.reverse and (n.width-inset-start)/n.width or (inset+n.width*extent)/n.width
                local crop=1+(n.cropX or 0)
                leftCoord=.5+(leftCoord-.5)/crop;rightCoord=.5+(rightCoord-.5)/crop
                if n.mirror then leftCoord,rightCoord=rightCoord,leftCoord end
            else leftCoord,rightCoord=M.Clamp(start/n.width,0,1),1 end
            local cropY=followsPortrait and (1+(n.cropY or 0)) or 1
            local top,bottom=.5-.5/cropY,.5+.5/cropY
            if n.mirrorY then top,bottom=bottom,top end
            local coords=o.barCoords or {};o.barCoords=coords
            coords[1],coords[2],coords[3],coords[4]=leftCoord,rightCoord,top,bottom
            local texture=o.bar:GetStatusBarTexture()
            if texture and (followsPortrait or not n.materialPath) then CachedColor(o,"barCoords",texture,"SetTexCoord",coords) end
        end
        -- A missing public cast/power ratio must keep the native bar visible;
        -- it must not fall through to the unit's readable health percentage.
        local ratio
        if n.binding=="cast" then ratio=CastRatio(s)
        elseif n.binding=="power" then ratio=s.powerRatio
        else ratio=s.healthRatio end
        if n.binding=="static" then ratio=.75 end
        ratio=DisplayRatio(view,o,n,ratio,animateOnly)
        if ratio and not n.vertical then
            if o.bar:IsShown() then o.bar:Hide() end
            if o.clip:IsShown()~=(ratio>0) then o.clip:SetShown(ratio>0) end
            if n.startAt or followsPortrait then
                local anchor=n.reverse and "RIGHT" or "LEFT"
                local shift=n.reverse and -inset-start or inset+start
                CachedPoint(o,"clipPoint",o.clip,anchor,f,anchor,shift,0)
                CachedPoint(o,"fillPoint",o.fill,anchor,o.clip,anchor,-shift,0)
                if o.material then CachedPoint(o,"materialPoint",o.material,anchor,o.clip,anchor,-shift,0) end
            else CachedPoint(o,"clipPoint",o.clip,n.reverse and "RIGHT" or "LEFT",f,n.reverse and "RIGHT" or "LEFT",n.reverse and -inset or inset,0) end
            CachedPair(o,"clipSize",o.clip,"SetSize",math.max(.001,(n.width*extent-start)*ratio),n.height)
            HealthTint(o,"fillColor",o.fill,col)
            if o.material then HealthTint(o,"materialColor",o.material,col) end
        else
            if o.clip:IsShown() then o.clip:Hide() end
            if not o.bar:IsShown() then o.bar:Show() end
        end
        if n.binding=="health" and s.healthRatio==nil and not (o.classHealthColor or o.customHealthStyle or o.targetHealthThreshold) and not view.preview and not animateOnly then RestrictedHealthColor(o,s) end
        if n.binding=="health" then
            if not (animateOnly and n.smooth) then
                CachedPair(o,"barRange",o.bar,"SetMinMaxValues",0,s.maxHealth or 1)
                local interpolation=n.smooth and s.healthRatio==nil and o.nativeReady and Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut
                if interpolation then o.bar:SetValue(s.health or 0,interpolation)
                else CachedValue(o,"barValue",o.bar,"SetValue",s.health or 0) end
                o.nativeReady=true
            end
        elseif n.binding=="power" then
            if not (animateOnly and n.smooth) then
                if o.nativePowerType~=s.powerType then
                    o.nativeReady=nil;o.nativePowerType=s.powerType;Cache(o).barValue=nil
                end
                CachedPair(o,"barRange",o.bar,"SetMinMaxValues",0,s.maxPower or 1)
                local interpolation=n.smooth and s.powerRatio==nil and o.nativeReady and Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut
                if interpolation then o.bar:SetValue(s.power or 0,interpolation);Cache(o).barValue=nil
                else CachedValue(o,"barValue",o.bar,"SetValue",s.power or 0) end
                o.nativeReady=true
            end
        elseif n.binding=="cast" then
            if s.cast.duration and o.bar.SetTimerDuration and Enum and Enum.StatusBarTimerDirection then
                if not animateOnly then o.bar:SetTimerDuration(s.cast.duration,nil,s.cast.channel and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime) end
            else CachedPair(o,"barRange",o.bar,"SetMinMaxValues",0,1);CachedValue(o,"barValue",o.bar,"SetValue",CastRatio(s) or 0) end
        else CachedPair(o,"barRange",o.bar,"SetMinMaxValues",0,1);CachedValue(o,"barValue",o.bar,"SetValue",.75) end
        if o.bar:IsShown() and (o.customHealthStyle or o.classHealthColor or o.targetHealthThreshold) then
            HealthTint(o,"nativeHealthColor",o.nativeArt or o.bar:GetStatusBarTexture(),col,barColorChanged)
            if s.healthRatio==nil and not view.preview then RestrictedHealthThreshold(o,s,col) end
        end
        if o.nativeArt and not (o.customHealthStyle or o.classHealthColor or o.targetHealthThreshold) then
            CachedColor(o,"nativeArtColor",o.nativeArt,"SetVertexColor",col)
        end
        if o.healthWarning and (view.preview or s.healthRatio~=nil or n.healthThresholdEnabled~=true or o.classHealthColor or o.tapColorActive) then
            o.healthWarning:Hide()
        end
    elseif o.texture then
        if o.rangeDecoration then DecorationTint(view,o,col)
        else CachedColor(o,"textureColor",o.texture,"SetVertexColor",col) end
        if n.castFill and not M.NativeDisplays.Cast(view,o,s,col,animateOnly) then
            local ratio=CastRatio(s) or 0
            local width=math.max(.001,(n.width or 512)*ratio)
            CachedPoint(o,"castTexturePoint",o.texture,"LEFT",f,"LEFT",0,0)
            CachedPair(o,"castTextureSize",o.texture,"SetSize",width,n.height or 128)
            local coords=o.castCoords or {};o.castCoords=coords
            coords[1],coords[2],coords[3],coords[4]=0,ratio,0,1
            CachedColor(o,"castCoords",o.texture,"SetTexCoord",coords)
            CachedValue(o,"castShown",o.texture,"SetShown",ratio>0)
            CachedPoint(o,"castInteriorPoint",o.castInterior,"LEFT",f,"LEFT",24,0)
            CachedPair(o,"castInteriorSize",o.castInterior,"SetSize",math.max(.001,((n.width or 512)-48)*ratio),7)
            CachedColor(o,"castInteriorColor",o.castInterior,"SetVertexColor",col)
            CachedValue(o,"castInteriorShown",o.castInterior,"SetShown",ratio>0)
        end
        if n.spinPeriod and o.texture.SetRotation then
            Spin(view,o,GetTime())
        end
        if n.kind=="portrait" then
            M.Portraits.Paint(view,o,s,col,animateOnly)
        elseif n.kind=="sprite" then
            Sprite(view,o,alpha,GetTime())
        elseif n.kind=="spark" then
            local owner=view.nodes[n.owner]
            local p=n.followDisplay and owner and owner.displayRatio or (n.binding=="cast" and CastRatio(s) or (n.binding=="power" and s.powerRatio or s.healthRatio))
            if nativeSparkOwner then
                -- The native fill sizes this clip in the engine. Anchoring to its
                -- edge also follows native interpolation without Lua width reads.
                local edge=owner.nativeClip or owner.bar:GetStatusBarTexture()
                CachedPoint(o,"sparkPoint",f,"CENTER",edge,owner.spec.reverse and "LEFT" or "RIGHT",n.x or 0,n.y or 0)
                if not animateOnly or not o.nativeSpark then NativeSparkAlpha(o,s,alpha) end
                o.nativeSpark=true;o.sparkRatio=nil;o.sparkStart=owner.fillStart
            elseif owner and p then
                o.nativeSpark=nil
                local extent=owner.spec.fillExtent or 1
                local reverse=owner.spec.reverse
                local inset=owner.spec.fillInset or 0
                local full=(owner.spec.width or 1)*extent
                local start=animateOnly and not view.preview and not owner.animatedEdge and not B.Moving(view,owner.spec) and not owner.fillEdgeMoving and owner.fillStart or FillStart(view,owner.spec,owner.frame)
                o.sparkRatio,o.sparkStart=p,start
                local x=start+(full-start)*p
                x=reverse and -inset-x or inset+x
                CachedPoint(o,"sparkPoint",f,"CENTER",owner.frame,reverse and "RIGHT" or "LEFT",x+(n.x or 0),n.y or 0)
            end
        elseif n.binding=="castIcon" then CachedValue(o,"castIcon",o.texture,"SetTexture",s.cast.icon or 134400)
        elseif n.binding=="partyClass" or n.binding=="partyRole" then M.PartyFrames.Texture(o,s)
        elseif n.binding=="raid" then
            local mark=s.raid
            if view.preview and type(mark)=="nil" then mark=8 end
            if not Readable(mark) then
                -- Use the existing artwork as a native 4x4 sheet. The opaque
                -- index never enters a Lua table lookup, comparison or cache.
                local sheet=n.id=="waf24f8d43e3" and raidMarkSheet or "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
                CachedValue(o,"raidMarkSheet",o.texture,"SetTexture",sheet);o.raidMarkSheet=sheet
                local selectCell=o.texture.SetSpriteSheetCell
                local ok=false
                if selectCell then ok=pcall(selectCell,o.texture,mark,4,4)
                elseif SetRaidTargetIconTexture then ok=pcall(SetRaidTargetIconTexture,o.texture,mark) end
                o.raidMark=nil
                if not ok then f:Hide() end
            elseif mark and (o.raidMark~=mark or o.raidMarkSheet) then
                o.raidMarkSheet=nil
                Cache(o).raidMarkSheet=nil
                local file=n.id=="waf24f8d43e3" and raidMarkFiles[mark]
                if file then
                    o.texture:SetTexture(M:TexturePath(n,file))
                    o.texture:SetTexCoord(0,1,0,1)
                elseif SetRaidTargetIconTexture then SetRaidTargetIconTexture(o.texture,mark) end
                o.raidMark=mark
            end
        end
    -- Explicit timer labels keep their own clock; aura queries still use the
    -- event-invalidated cache instead of scanning on every animation frame.
    elseif o.icons and (not animateOnly or o.auraClock) then Auras(view,o,s)
    elseif o.resourceSlots then
        if animateOnly then ResourceAnimate(o) else ResourcePaint(view,o) end
    end
    if n.kind=="glow" then CachedValue(o,"frameAlpha",f,"SetAlpha",alpha*(.65+.35*math.sin(GetTime()*3)^2)) end
end

M.RendererInternals.Paint=Paint
