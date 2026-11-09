local _,M=...
local N={};M.NativeDisplays=N
local P=M.RendererInternals
local unpack=unpack or table.unpack
local fontSerial=0
local function RestrictedClient()
    return M.Compat.interface==16001 or (C_Secrets and C_Secrets.HasSecretRestrictions and C_Secrets.HasSecretRestrictions())
end
local function AuraSupport()
    if not RestrictedClient() or not C_XMLUtil or not C_XMLUtil.GetTemplateInfo then return false end
    if not C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate") and C_AddOns and C_AddOns.LoadAddOn and not InCombatLockdown() then
        pcall(C_AddOns.LoadAddOn,"Blizzard_AuraContainer")
    end
    return C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")~=nil
end
local function CanStyleAuras()
    return not InCombatLockdown() and not (C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret())
end
function N.RefreshAuraFonts(view,o,force)
    o.nativeAuraFonts=o.nativeAuraFonts or {}
    local failed=false
    for _,spec in ipairs(view.auraTemplates[o.spec.id] or {}) do
        local object=o.nativeAuraFonts[spec.id]
        if not object then
            fontSerial=fontSerial+1;object=CreateFont("MangUINativeAuraFont"..fontSerial);o.nativeAuraFonts[spec.id]=object
        end
        if not M:ApplyRegionFont(object,P.Font(spec),spec.fontSize or 12,"OUTLINE",force)then failed=true end
    end
    o.fontFailed=failed;o.fontNeedsSettle=not force
    if failed then view.fontsPending=true end
end
local function StyleAura(view,o,frame)
    local n=o.spec
    frame:SetSize(n.width,n.height)
    frame:EnableMouse(false)
    frame:EnableMouseMotion(true)
    frame:SetTooltipAnchorPoint("ANCHOR_RIGHT")
    frame:SetHideTooltipInCombat(false)
    if not frame.manguiIcon then
        frame.manguiIcon=frame:CreateTexture(nil,"ARTWORK");frame.manguiIcon:SetAllPoints()
        frame.manguiCooldown=CreateFrame("Cooldown",nil,frame,"CooldownFrameTemplate");frame.manguiCooldown:SetAllPoints()
        frame.manguiCooldown:EnableMouse(false)
        frame.manguiCooldown:SetDrawEdge(false);frame.manguiCooldown:SetDrawBling(false)
        frame.manguiLabels={}
        frame:SetIcon(frame.manguiIcon)
        frame:SetDurationCooldown(frame.manguiCooldown)
    end
    frame.manguiCooldown:SetReverse(n.cooldownReverse~=false)
    frame.manguiCooldown:SetHideCountdownNumbers(n.hideCooldownNumbers==true)
    frame.manguiCooldown.noCooldownCount=n.hideCooldownNumbers==true
    frame:ClearApplicationCount();frame:ClearDurationText()
    for _,label in pairs(frame.manguiLabels) do label:Hide() end
    for _,spec in ipairs(view.auraTemplates[n.id] or {}) do
        if spec.enabled~=false then
            local label=frame.manguiLabels[spec.id]
            if not label then label=frame:CreateFontString(nil,"OVERLAY");frame.manguiLabels[spec.id]=label end
            label:SetFontObject(o.nativeAuraFonts[spec.id])
            label:SetTextColor(unpack(spec.color or {1,1,1,1}))
            if spec.binding=="auraStacks" then
                label:SetShadowColor(0,0,0,0);label:SetShadowOffset(0,0)
            else
                label:SetShadowColor(0,0,0,(spec.color and spec.color[4]) or 1);label:SetShadowOffset(2,-2)
            end
            label:ClearAllPoints();label:SetPoint(spec.point or "CENTER",frame,spec.anchor or "CENTER",spec.x or 0,spec.y or 0)
            if spec.binding=="auraStacks" then frame:SetApplicationCount(label,{})
            elseif spec.binding=="auraTime" then frame:SetDurationText(label,{}) end
        end
    end
end
function N.ConfigureAuras(view,o)
    local n=o.spec
    local pet=M.PetBuffs and n.id==M.PetBuffs.nodeID
    local party=n.partyBuffs and view.byID.partyFrames
    if view.preview or (n.unit~="target" and not pet and not party) then return end
    -- The native PLAYER filter also matches pets and vehicles. For the
    -- character-only filter, use the readable caster token instead.
    o.partyBuffsUseLua=party and party.partyBuffsOnlyPlayer==true
    if o.partyBuffsUseLua then
        if o.nativeAuras then o.nativeAuras:SetEnabled(false);o.nativeAuras:Hide() end
        return
    end
    if not AuraSupport() then return end
    local parent=view.nodes[n.parent] and view.nodes[n.parent].spec
    local debuff=parent and parent.id=="wa026b04c50e"
    local buff=parent and parent.id=="wa88e7259b1c"
    if not debuff and not buff and not pet and not party then return end
    N.RefreshAuraFonts(view,o,false)
    local count=pet and 5 or math.max(1,(debuff and parent.debuffCount or parent.buffCount) or n.count or 8)
    local perRow=math.max(1,(debuff and parent.debuffPerRow or parent.buffPerRow) or (party and n.perRow) or count)
    local gap=n.spacing or 4
    local container=o.nativeAuras
    if not container then
        container=CreateFrame("AuraContainer",nil,o.frame,"CustomAuraContainerTemplate")
        o.nativeAuras=container;o.nativeAuraFrames={}
        container:SetEnabled(false)
        container:SetUnit(n.unit)
        container:AddAuraGroup("main",n.filter or "HARMFUL",{maxFrameCount=0,initializeFrame=function(frame)
            if not party then o.nativeAuraFrames[#o.nativeAuraFrames+1]=frame end
            StyleAura(view,o,frame)
        end})
    end
    container:SetEnabled(false)
    container:ClearAllPoints()
    if parent.auraOriginRevision==1 then
        local columns,rows=math.min(count,perRow),math.ceil(count/perRow)
        container:SetPoint("TOPLEFT",o.frame,"CENTER",-(columns-1)*(n.width+gap)/2-n.width/2,(rows-1)*(n.height+gap)/2+n.height/2)
    else container:SetPoint("TOPLEFT",o.frame,"LEFT",0,n.height/2) end
    container:SetFlowLayoutAnchorPoint("TOPLEFT")
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right,AnchorUtil.FlowDirection.Down)
    container:SetFlowLayoutMaximumLineSize(perRow*n.width+(perRow-1)*gap+.001)
    container:SetAuraGroupLayout("main",{elementSpacing=gap,lineSpacing=gap,elementWidth=n.width,elementHeight=n.height})
    container:SetAuraGroupFilterString("main",(n.filter or "HARMFUL")..(debuff and parent.onlyPlayerDebuffs==true and "|PLAYER" or ""))
    local timedOnly=(buff and parent.hideUntimedBuffs==true) or (party and party.partyBuffsTimedOnly==true)
    local candidates=timedOnly and {maxDuration=math.huge} or {}
    if pet then
        candidates,o.nativePetFilterKey=M.PetBuffs.NativeFilters(parent,CanStyleAuras())
        o.nativePetFilterAt=GetTime()+1
    end
    container:SetAuraGroupCandidateFilters("main",candidates)
    container:SetAuraGroupMaxFrameCount("main",count)
    o.nativeAuraStylePending=not party
    if not party and CanStyleAuras() then
        for _,frame in ipairs(o.nativeAuraFrames) do StyleAura(view,o,frame) end
        o.nativeAuraStylePending=nil
    end
    for _,icon in ipairs(o.icons or {}) do icon:Hide() end
    if party then container:Show() end
    local enabled=n.enabled~=false and parent.enabled~=false and (not o.module or o.module.enabled~=false)
    if party then
        enabled=enabled and not view.raidEncounter and o.frame:IsVisible()
        o.nativePartyBuffActive=enabled
    end
    container:SetEnabled(enabled)
    o.nativeAuraVersion=nil
end
function N.SetPartyBuffActive(o,active)
    if not o.nativeAuras or o.partyBuffsUseLua or o.nativePartyBuffActive==active then return end
    o.nativeAuras:SetEnabled(active)
    o.nativePartyBuffActive=active
    o.nativeAuraVersion=nil
end
function N.Auras(view,o,s)
    local container=o.nativeAuras
    if view.preview or not container or o.partyBuffsUseLua then return false end
    if o.spec.partyBuffs then N.SetPartyBuffActive(o,true) end
    if o.nativeAuraStylePending and CanStyleAuras() then
        for _,frame in ipairs(o.nativeAuraFrames) do StyleAura(view,o,frame) end
        o.nativeAuraStylePending=nil
    end
    if M.PetBuffs and o.spec.id==M.PetBuffs.nodeID and CanStyleAuras() and GetTime()>=(o.nativePetFilterAt or 0) then
        -- Resolve a newly seen rank/name outside restricted execution. The
        -- configured native ID whitelist continues updating throughout combat.
        o.nativePetFilterAt=GetTime()+1
        local group=view.nodes[o.spec.parent].spec
        local filters,key=M.PetBuffs.NativeFilters(group,true)
        if key~=o.nativePetFilterKey then
            container:SetAuraGroupCandidateFilters("main",filters);o.nativePetFilterKey=key;o.nativeAuraVersion=nil
        end
    end
    -- UNIT_AURA is consumed by the native container. Only a target-token change
    -- needs an explicit refresh; no full native rescan on the regular .2s poll.
    local pet=M.PetBuffs and o.spec.id==M.PetBuffs.nodeID
    local version
    if pet then version=view.auraVersions and view.auraVersions.pet or 0
    elseif o.spec.partyBuffs then version=view.auraRosterVersion or 0
    else version=view.targetRefreshGeneration or 0 end
    if o.nativeAuraVersion~=version then
        local profiler=M.ModuleProfiler
        local started=not view.preview and profiler and profiler.targetSampling and debugprofilestop()
        container:UpdateAllAuras()
        if started then profiler.RecordTarget(3,debugprofilestop()-started) end
        o.nativeAuraVersion=version
    end
    return true
end
function N.ConfigureCast(view,o)
    if view.preview or not o.spec.castFill or not RestrictedClient() or not UnitCastingDuration
        or not Enum or not Enum.StatusBarTimerDirection then return end
    local n=o.spec;local native=o.nativeCast
    if not native then
        native={};o.nativeCast=native
        native.timer=CreateFrame("StatusBar",nil,o.frame);native.timer:EnableMouse(false)
        if not native.timer.SetTimerDuration then o.nativeCast=nil;native.timer:Hide();return end
        native.timer:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        native.timer:SetStatusBarColor(1,1,1,0);native.timer:GetStatusBarTexture():SetAlpha(0)
        native.clip=CreateFrame("Frame",nil,native.timer,"DisableUntrustedLayoutScriptsTemplate")
        native.clip:EnableMouse(false);native.clip:SetClipsChildren(true);native.clip:SetAllPoints(native.timer:GetStatusBarTexture())
        native.art=CreateFrame("Frame",nil,native.clip,"DisableUntrustedLayoutScriptsTemplate");native.art:SetAllPoints(o.frame);native.art:EnableMouse(false)
        native.texture=native.art:CreateTexture(nil,"ARTWORK");native.texture:SetAllPoints()
    end
    native.texture:SetTexture(n.file);native.texture:SetBlendMode(n.blend or "BLEND");P.TextureCoords(native.texture,n)
    local left,span=M.PlayerCastArt.ProgressBounds(n)
    native.timer:ClearAllPoints();native.timer:SetPoint("LEFT",o.frame,"LEFT",left,0)
    native.timer:SetSize(span,n.height or 128)
    native.timer:Hide()
end
function N.Cast(view,o,s,col,animateOnly)
    local native=o.nativeCast
    local duration=s.cast.duration
    if view.preview or not native or duration==nil or not s.cast.active or P.CastRatio(s)~=nil then
        if native then native.timer:Hide();native.bound=nil end
        return false
    end
    M.PlayerCastArt.Hide(o.texture)
    P.CachedValue(o,"castShown",o.texture,"SetShown",false)
    P.CachedColor(native,"artColor",native.texture,"SetVertexColor",col)
    M.PlayerCastArt.Draw(native.texture,native.art,o.spec,1,col)
    if not native.timer:IsShown() then native.timer:Show() end
    if not animateOnly or not native.bound then
        local direction=s.cast.channel and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime
        native.timer:SetTimerDuration(duration,nil,direction)
        native.bound=true
    end
    return true
end
