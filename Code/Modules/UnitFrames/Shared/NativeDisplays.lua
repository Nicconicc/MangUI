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
        local ok,loaded=pcall(object.SetFont,object,P.Font(spec),spec.fontSize or 12,"OUTLINE")
        if not ok or loaded==false then failed=true;object:SetFont(M:DefaultFontPath(),spec.fontSize or 12,"OUTLINE") end
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
            label:SetShadowColor(0,0,0,(spec.color and spec.color[4]) or 1);label:SetShadowOffset(2,-2)
            label:ClearAllPoints();label:SetPoint(spec.point or "CENTER",frame,spec.anchor or "CENTER",spec.x or 0,spec.y or 0)
            if spec.binding=="auraStacks" then frame:SetApplicationCount(label,{})
            elseif spec.binding=="auraTime" then frame:SetDurationText(label,{}) end
        end
    end
end
function N.ConfigureAuras(view,o)
    local n=o.spec
    if view.preview or n.unit~="target" or not AuraSupport() then return end
    local parent=view.nodes[n.parent] and view.nodes[n.parent].spec
    local debuff=parent and parent.id=="wa026b04c50e"
    local buff=parent and parent.id=="wa88e7259b1c"
    if not debuff and not buff then return end
    N.RefreshAuraFonts(view,o,false)
    local count=math.max(1,(debuff and parent.debuffCount or parent.buffCount) or n.count or 8)
    local perRow=math.max(1,(debuff and parent.debuffPerRow or parent.buffPerRow) or count)
    local gap=n.spacing or 4
    local container=o.nativeAuras
    if not container then
        container=CreateFrame("AuraContainer",nil,o.frame,"CustomAuraContainerTemplate")
        o.nativeAuras=container;o.nativeAuraFrames={}
        container:SetEnabled(false)
        container:SetUnit("target")
        container:AddAuraGroup("main",n.filter or "HARMFUL",{maxFrameCount=0,initializeFrame=function(frame)
            o.nativeAuraFrames[#o.nativeAuraFrames+1]=frame;StyleAura(view,o,frame)
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
    container:SetAuraGroupCandidateFilters("main",buff and parent.hideUntimedBuffs==true and {maxDuration=math.huge} or {})
    container:SetAuraGroupMaxFrameCount("main",count)
    o.nativeAuraStylePending=true
    if CanStyleAuras() then
        for _,frame in ipairs(o.nativeAuraFrames) do StyleAura(view,o,frame) end
        o.nativeAuraStylePending=nil
    end
    for _,icon in ipairs(o.icons or {}) do icon:Hide() end
    container:SetEnabled(n.enabled~=false and parent.enabled~=false and (not o.module or o.module.enabled~=false))
    o.nativeAuraVersion=nil
end
function N.Auras(view,o,s)
    local container=o.nativeAuras
    if view.preview or not container then return false end
    if o.nativeAuraStylePending and CanStyleAuras() then
        for _,frame in ipairs(o.nativeAuraFrames) do StyleAura(view,o,frame) end
        o.nativeAuraStylePending=nil
    end
    -- UNIT_AURA is consumed by the native container. Only a target-token change
    -- needs an explicit refresh; no full native rescan on the regular .2s poll.
    local version=view.targetRefreshGeneration or 0
    if o.nativeAuraVersion~=version then
        container:UpdateAllAuras();o.nativeAuraVersion=version
    end
    return true
end
function N.ConfigureCast(view,o)
    if view.preview or not o.spec.castFill or not RestrictedClient() or not UnitCastingDuration
        or not Enum or not Enum.StatusBarTimerDirection then return end
    local n=o.spec;local native=o.nativeCast
    if not native then
        native={};o.nativeCast=native
        native.timer=CreateFrame("StatusBar",nil,o.frame);native.timer:SetAllPoints();native.timer:EnableMouse(false)
        if not native.timer.SetTimerDuration then o.nativeCast=nil;native.timer:Hide();return end
        native.timer:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        native.timer:SetStatusBarColor(1,1,1,0);native.timer:GetStatusBarTexture():SetAlpha(0)
        native.clip=CreateFrame("Frame",nil,native.timer,"DisableUntrustedLayoutScriptsTemplate")
        native.clip:EnableMouse(false);native.clip:SetClipsChildren(true);native.clip:SetAllPoints(native.timer:GetStatusBarTexture())
        native.art=CreateFrame("Frame",nil,native.clip,"DisableUntrustedLayoutScriptsTemplate");native.art:SetAllPoints(o.frame);native.art:EnableMouse(false)
        native.texture=native.art:CreateTexture(nil,"ARTWORK");native.texture:SetAllPoints()
        native.interior=CreateFrame("StatusBar",nil,o.frame);native.interior:EnableMouse(false)
        native.interior:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    end
    native.texture:SetTexture(n.file);native.texture:SetBlendMode(n.blend or "BLEND");P.TextureCoords(native.texture,n)
    native.interior:ClearAllPoints();native.interior:SetPoint("LEFT",o.frame,"LEFT",24,0)
    native.interior:SetSize(math.max(.001,(n.width or 512)-48),7)
    native.timer:Hide();native.interior:Hide()
end
function N.Cast(view,o,s,col,animateOnly)
    local native=o.nativeCast
    local duration=s.cast.duration
    if view.preview or not native or duration==nil or not s.cast.active or P.CastRatio(s)~=nil then
        if native then native.timer:Hide();native.interior:Hide();native.bound=nil end
        return false
    end
    P.CachedValue(o,"castShown",o.texture,"SetShown",false)
    P.CachedValue(o,"castInteriorShown",o.castInterior,"SetShown",false)
    P.CachedColor(native,"artColor",native.texture,"SetVertexColor",col)
    P.CachedColor(native,"interiorColor",native.interior,"SetStatusBarColor",col)
    if not native.timer:IsShown() then native.timer:Show() end
    if not native.interior:IsShown() then native.interior:Show() end
    if not animateOnly or not native.bound then
        local direction=s.cast.channel and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime
        native.timer:SetTimerDuration(duration,nil,direction);native.interior:SetTimerDuration(duration,nil,direction)
        native.bound=true
    end
    return true
end
