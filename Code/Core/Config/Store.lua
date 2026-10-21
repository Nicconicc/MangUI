local _,M=...
function M:InitStore()
    if type(MangUIUFDB)~="table" then MangUIUFDB={} end
    local db=MangUIUFDB
    if db.schema and db.schema>82 then error("配置由更新版本创建，请更新 MangUI；现有配置未修改。") end
    if type(db.design)~="table" or type(db.design.nodes)~="table" then
        db.design=self.Copy(self.recordedDefaults or self.defaults)
        for key,value in pairs(self.recordedSettings or {}) do
            if db[key]==nil then db[key]=self.Copy(value) end
        end
        -- The recorded preset already uses the current schema and needs no migrations.
        if self.recordedDefaults then db.schema=82 end
    end
    if not db.schema or db.schema<3 then self:UpgradeFocusAvatar(db.design) end
    if not db.schema or db.schema<4 then self:UpgradeFocusPortraitSize(db.design) end
    if not db.schema or db.schema<5 then self:UpgradeFocusBackgroundSize(db.design) end
    if not db.schema or db.schema<6 then self:UpgradeFocusAvatar256(db.design) end
    if not db.schema or db.schema<7 then self:UpgradeFocusHP(db.design) end
    if not db.schema or db.schema<8 then self:UpgradeFocusHPAnimation(db.design) end
    if not db.schema or db.schema<14 then self:UpgradeFocusMP(db.design) end
    if not db.schema or db.schema<15 then self:UpgradeFocusBarShadows(db.design) end
    if not db.schema or db.schema<16 then self:UpgradeFocusComposite(db.design) end
    if not db.schema or db.schema<17 then self:UpgradeFocusFillStart(db.design) end
    if not db.schema or db.schema<18 then self:UpgradeFocusScaleControls(db.design) end
    if not db.schema or db.schema<19 then self:UpgradeFocusName(db.design) end
    if not db.schema or db.schema<20 then self:UpgradeFocusNameControls(db.design) end
    if not db.schema or db.schema<22 then self:UpgradeFocusMenu(db.design) end
    if not db.schema or db.schema<24 then self:UpgradeFocusCast(db.design) end
    if not db.schema or db.schema<25 then self:UpgradeFocusCastScale(db.design) end
    if not db.schema or db.schema<26 then self:UpgradeFocusCastAlignIcon(db.design) end
    if not db.schema or db.schema<27 then self:UpgradeFocusWrapper(db.design) end
    if not db.schema or db.schema<28 then self:UpgradePetFrame(db.design) end
    if not db.schema or db.schema<29 then self:UpgradePetVisibility(db.design) end
    if not db.schema or db.schema<30 then self:UpgradeTotFrame(db.design) end
    if not db.schema or db.schema<31 then self:UpgradeTotHPY(db.design) end
    if not db.schema or db.schema<32 then self:UpgradePlayerHP(db.design) end
    if not db.schema or db.schema<33 then self:UpgradePlayerMP(db.design) end
    if not db.schema or db.schema<34 then self:UpgradeTargetHP(db.design) end
    if not db.schema or db.schema<35 then self:UpgradeTargetMP(db.design) end
    if not db.schema or db.schema<36 then self:UpgradeCenterPortrait(db.design) end
    if not db.schema or db.schema<37 then self:UpgradeTargetName(db.design) end
    if not db.schema or db.schema<38 then self:UpgradeCenterLevel(db.design) end
    if not db.schema or db.schema<39 then self:UpgradeCenterClassification(db.design) end
    if not db.schema or db.schema<40 then self:UpgradeCenterFire(db.design) end
    if not db.schema or db.schema<41 then self:UpgradeMainComposite(db.design) end
    if not db.schema or db.schema<42 then self:UpgradeBarMenus(db.design) end
    if not db.schema or db.schema<43 then self:UpgradeTargetPortraitScale(db.design) end
    if not db.schema or db.schema<44 then self:UpgradeCenterGlass(db.design) end
    if not db.schema or db.schema<45 then self:UpgradeMainRamps(db.design) end
    if not db.schema or db.schema<46 then self:UpgradeMainLayerAlpha(db.design) end
    if not db.schema or db.schema<47 then self:UpgradeCenterLightRotation(db.design) end
    if not db.schema or db.schema<48 then self:UpgradeTargetPortraitScale(db.design) end
    if not db.schema or db.schema<49 then self:UpgradeCenterLogo(db.design) end
    if not db.schema or db.schema<50 then self:UpgradeCenterLogoScale(db.design) end
    if not db.schema or db.schema<51 then self:UpgradeCenterLogoScale(db.design) end
    if not db.schema or db.schema<52 then self:UpgradeCenterLogoScale(db.design) end
    if not db.schema or db.schema<53 then self:UpgradeCenterGlassLayer(db.design) end
    if not db.schema or db.schema<54 then self:UpgradeCenterFallbackPortraitScale(db.design) end
    if not db.schema or db.schema<59 then self:UpgradeMainBarParticles(db.design) end
    if not db.schema or db.schema<62 then self:UpgradeMainHPLayersY(db.design,db.schema) end
    if not db.schema or db.schema<63 then self:UpgradeTargetDebuffComposite(db.design) end
    if not db.schema or db.schema<64 then self:UpgradeTargetBuffComposite(db.design) end
    if not db.schema or db.schema<65 then self:UpgradeTargetRaidMark(db.design) end
    if not db.schema or db.schema<66 then self:UpgradeCenterClassificationIcons(db.design) end
    if not db.schema or db.schema<67 then self:UpgradePlayerResources(db.design) end
    if not db.schema or db.schema<68 then self:UpgradeAnimationEffectsTrigger(db.design) end
    if not db.schema or db.schema<69 then self:UpgradeAnimationEffectsOnce(db.design) end
    if not db.schema or db.schema<70 then self:UpgradeMainAnimationEffects(db.design) end
    if not db.schema or db.schema<71 then self:UpgradePlayerCastComposite(db.design) end
    if not db.schema or db.schema<72 then self:UpgradePlayerCastFill(db.design) end
    if not db.schema or db.schema<73 then self:UpgradePlayerCastDirectFill(db.design) end
    if not db.schema or db.schema<74 then self:UpgradePlayerCastLayer(db.design) end
    if not db.schema or db.schema<75 then self:UpgradePlayerPowerDisplay(db.design) end
    if not db.schema or db.schema<76 then self:UpgradeTargetCastComposite(db.design) end
    if not db.schema or db.schema<77 then
        for _,n in ipairs(db.design.nodes) do
            if n.id=="wa8d650f8d3a" then n.label="玩家施法条";break end
        end
    end
    if not db.schema or db.schema<78 then
        for _,n in ipairs(db.design.nodes) do
            if n.id=="wa028b62b494" then n.hideCooldownNumbers=true;break end
        end
    end
    if not db.schema or db.schema<80 then
        local renamed={
            wa70b7aa5607="玩家生命条",
            waf0a666c0b7="玩家能量条",
            waf465575a72="目标生命条",
            wae608adf3d8="目标能量条",
            wabc757f81ee="头像框体",
        }
        local function renameNodeLabels(nodes)
            if type(nodes)~="table" then return end
            for _,n in ipairs(nodes) do
                if renamed[n.id] then n.label=renamed[n.id] end
            end
        end
        renameNodeLabels(db.design.nodes)
        if type(db.moduleDefaults)=="table" then renameNodeLabels(db.moduleDefaults.nodes) end
    end
    if not db.schema or db.schema<81 then
        local renamed={
            wadb51e41246="玩家生命值", wa8ee62b16d6="玩家能量值", wa6edbcf125a="玩家能量值",
            waf465575a72="目标生命条", wae608adf3d8="目标能量条",
            wa8492858a6d="目标生命值", wa712a8bee10="目标生命值百分比", wa074335b474="目标能量值",
            wa88e7259b1c="目标Buff", wa026b04c50e="目标Debuff", wabc757f81ee="头像框体",
            centerLogo="CenterLogo", targetUnifiedName="目标姓名", waf24f8d43e3="目标团队标记",
            centerLevel="头像等级", centerClassification="稀有精英图标", centerFire="头像框体装饰",
            wa65978f0ae2="动画特效", playerResources="玩家资源", targetCast="目标施法条",
        }
        local function renameNodeLabels(nodes)
            if type(nodes)~="table" then return end
            for _,n in ipairs(nodes) do
                if renamed[n.id] then n.label=renamed[n.id] end
            end
        end
        renameNodeLabels(db.design.nodes)
        if type(db.moduleDefaults)=="table" then renameNodeLabels(db.moduleDefaults.nodes) end
    end
    if not db.schema or db.schema<82 then
        local function setSolidBars(nodes)
            if type(nodes)~="table" then return end
            for _,n in ipairs(nodes) do
                if n.kind=="bar" and n.alphaFill then
                    n.materialName="Solid"
                    n.materialPath="Interface\\Buttons\\WHITE8X8"
                end
            end
        end
        setSolidBars(db.design.nodes)
        if type(db.moduleDefaults)=="table" then setSolidBars(db.moduleDefaults.nodes) end
    end
    for i=#db.design.nodes,1,-1 do
        local id=db.design.nodes[i].id
        if id=="playerHPFlash1" or id=="targetHPFlash" then table.remove(db.design.nodes,i) end
    end
    if self.EnsurePetBuffs then self:EnsurePetBuffs(db.design) end
    if self.EnsureCooldownModule then self:EnsureCooldownModule(db.design) end
    if self.EnsurePlayerSkillMonitor then self:EnsurePlayerSkillMonitor(db.design) end
    if self.EnsurePlayerOtherMonitor then self:EnsurePlayerOtherMonitor(db.design) end
    if self.EnsureCommonItems then self:EnsureCommonItems(db.design)end
    if self.EnsureRaidVulnerability then self:EnsureRaidVulnerability(db.design)end
    if self.EnsureReceivedBuffs then self:EnsureReceivedBuffs(db.design)end
    if self.EnsureRaidBuffMonitor then self:EnsureRaidBuffMonitor(db.design)end
    if self.EnsureChatButtonsModule then self:EnsureChatButtonsModule(db.design) end
    if self.EnsureCombatNoticesModule then self:EnsureCombatNoticesModule(db.design) end
    if self.EnsureSystemMenuModule then self:EnsureSystemMenuModule(db.design) end
    if self.EnsureMouseCircleModule then self:EnsureMouseCircleModule(db.design) end
    if self.EnsureExperienceBarModule then self:EnsureExperienceBarModule(db.design) end
    if self.EnsureTargetThreatModule then self:EnsureTargetThreatModule(db.design) end
    if self.EnsureTargetDistanceModule then self:EnsureTargetDistanceModule(db.design) end
    if self.EnsureBossFramesModule then self:EnsureBossFramesModule(db.design) end
    if self.EnsurePartyFramesModule then self:EnsurePartyFramesModule(db.design) end
    if self.ModuleGuides then self.ModuleGuides.Ensure(db.design)end
    if db.portraitFrameTokenRevision~=1 then
        local replacementFile="Interface\\AddOns\\MangUI\\Assets\\Library\\TokenFrame\\TokenFrame_01_BattleMaster"
        local function replaceLegacyPortraitTexture(design)
            if type(design)~="table" or type(design.nodes)~="table" then return end
            for _,node in ipairs(design.nodes) do
                if node.id=="wa92712c7b3d" and type(node.file)=="string"
                    and (node.file:find("CenterKuang_",1,true) or node.file:find("CenterKuang",1,true)) then
                    node.file=replacementFile
                end
            end
        end
        replaceLegacyPortraitTexture(db.design)
        replaceLegacyPortraitTexture(db.moduleDefaults)
        db.portraitFrameTokenRevision=1
    end
    if db.portraitAvatarLayerRevision~=1 then
        local layers={wa88b1376baa=207,wa0b0b0540c7=208}
        local function lowerPortraitLayers(design)
            if type(design)~="table" or type(design.nodes)~="table" then return end
            for _,node in ipairs(design.nodes) do
                if layers[node.id] and node.parent=="wabc757f81ee" then node.layer=layers[node.id] end
            end
        end
        lowerPortraitLayers(db.design)
        lowerPortraitLayers(db.moduleDefaults)
        db.portraitAvatarLayerRevision=1
    end
    db.minimap=type(db.minimap)=="table" and db.minimap or {angle=220,hide=false}
    if db.minimap.angle==nil then db.minimap.angle=220 end
    if db.minimap.hide==nil then db.minimap.hide=false end
    -- Re-detect the client on every addon load. Manual selection is session-local.
    db.language=self:ClientLanguage()
    db.hideWithoutTarget=db.hideWithoutTarget==true
    db.portrait3D=db.portrait3D==true
    db.healthClassColor=db.healthClassColor==true
    db.adapt4KUIScale=db.adapt4KUIScale==true
    db.useGlobalFont=db.useGlobalFont==true
    db.globalFontPath=type(db.globalFontPath)=="string" and db.globalFontPath~="" and db.globalFontPath or (M:DefaultFontPath())
    db.globalFontName=type(db.globalFontName)=="string" and db.globalFontName~="" and db.globalFontName or "默认"
    db.editor=type(db.editor)=="table" and db.editor or {scope="all",snap=true}
    db.editor.zoom=nil
    -- Updated shipped defaults become the reset baseline without replacing
    -- an existing profile's active layout.
    if (self.defaultsRevision and db.moduleDefaultsRevision~=self.defaultsRevision)
        or type(db.moduleDefaults)~="table" or type(db.moduleDefaults.nodes)~="table" then
        db.moduleDefaults=self.Copy(self.recordedDefaults or db.design)
        db.moduleDefaultsRevision=self.defaultsRevision
    end
    if self.EnsurePetBuffs then self:EnsurePetBuffs(db.moduleDefaults) end
    if self.EnsureCooldownModule then self:EnsureCooldownModule(db.moduleDefaults) end
    if self.EnsurePlayerSkillMonitor then self:EnsurePlayerSkillMonitor(db.moduleDefaults) end
    if self.EnsurePlayerOtherMonitor then self:EnsurePlayerOtherMonitor(db.moduleDefaults) end
    if self.EnsureCommonItems then self:EnsureCommonItems(db.moduleDefaults)end
    if self.EnsureRaidVulnerability then self:EnsureRaidVulnerability(db.moduleDefaults)end
    if self.EnsureReceivedBuffs then self:EnsureReceivedBuffs(db.moduleDefaults)end
    if self.EnsureRaidBuffMonitor then self:EnsureRaidBuffMonitor(db.moduleDefaults)end
    -- Preserve captured mover positions; use built-in centers only for new modules.
    for _,monitor in ipairs({self.ReceivedBuffs,self.RaidBuffMonitor,self.RaidVulnerability,self.CommonItems})do
        local group=monitor.Group(db.moduleDefaults)
        local recorded=self.recordedDefaults and monitor.Group(self.recordedDefaults)
        if group and not recorded then monitor.RestorePosition(group)end
    end
    if self.UpgradePlayerSkillMonitorDefaults then self:UpgradePlayerSkillMonitorDefaults(db) end
    if self.EnsureChatButtonsModule then self:EnsureChatButtonsModule(db.moduleDefaults) end
    if self.EnsureCombatNoticesModule then self:EnsureCombatNoticesModule(db.moduleDefaults) end
    if self.EnsureSystemMenuModule then self:EnsureSystemMenuModule(db.moduleDefaults) end
    if self.EnsureMouseCircleModule then self:EnsureMouseCircleModule(db.moduleDefaults) end
    if self.EnsureExperienceBarModule then self:EnsureExperienceBarModule(db.moduleDefaults) end
    if self.EnsureTargetThreatModule then self:EnsureTargetThreatModule(db.moduleDefaults) end
    if self.EnsureTargetDistanceModule then self:EnsureTargetDistanceModule(db.moduleDefaults) end
    if self.EnsureBossFramesModule then self:EnsureBossFramesModule(db.moduleDefaults) end
    if self.EnsurePartyFramesModule then self:EnsurePartyFramesModule(db.moduleDefaults) end
    if self.ModuleGuides then self.ModuleGuides.Ensure(db.moduleDefaults)end
    if db.targetRaidMarkArtRevision~=3 then
        self:UpgradeTargetRaidMark(db.design)
        self:UpgradeTargetRaidMark(db.moduleDefaults)
        db.targetRaidMarkArtRevision=3
    end
    if db.targetRaidMarkSizeRevision~=1 then
        for _,design in ipairs({db.design,db.moduleDefaults}) do
            for _,n in ipairs(design.nodes or {}) do
                if n.id=="waf24f8d43e3" and n.raidMarkSizeRevision~=1 then
                    n.width=(n.width or 40)*2
                    n.height=(n.height or 40)*2
                    n.raidMarkSizeRevision=1
                end
            end
        end
        db.targetRaidMarkSizeRevision=1
    end
    if db.portraitBlackFollowRevision~=3 then
        local index={}
        for _,node in ipairs(db.moduleDefaults.nodes) do index[node.id]=node end
        self:SyncCenterPortraitBlack(index)
        db.portraitBlackFollowRevision=3
    end
    db.schema=82
    db.hideBlizzard=db.hideBlizzard or false
    self.db=db
    self.PlayerSkillMonitor.InitCharacterStore()
    if self.BindPlayerSkillMonitorClass then self:BindPlayerSkillMonitorClass()end
    if self.BindPlayerOtherMonitorClass then self:BindPlayerOtherMonitorClass()end
    if self.BindCommonItemsClass then self:BindCommonItemsClass()end
    if self.BindRaidVulnerabilityClass then self:BindRaidVulnerabilityClass()end
    if self.BindReceivedBuffs then self:BindReceivedBuffs()end
    if self.BindRaidBuffMonitorClass then self:BindRaidBuffMonitorClass()end
    if self.UpgradePlayerOtherMonitorDefaults then self:UpgradePlayerOtherMonitorDefaults(db)end
    self:Index()
end
function M:Index(editing)
    -- A numeric/color edit keeps the existing node objects. Loading, importing,
    -- undoing or replacing nodes must still run the complete migration path.
    local nodes=self.db.design.nodes
    if editing and self.indexedNodes==nodes and self.indexedNodeCount==#nodes then
        local same=true
        for _,n in ipairs(nodes) do if self.byID[n.id]~=n then same=false;break end end
        if same then
            self:SyncCenterPortraitBlack(self.byID)
            if self.SettingRanges then self.SettingRanges.ClampAll(self.byID) end
            return
        end
    end
    self:NormalizeAssetPaths(self.defaults)
    self:NormalizeAssetPaths(self.recordedDefaults)
    self:NormalizeAssetPaths(self.db)
    self:NormalizeRetiredFonts(self.defaults)
    self:NormalizeRetiredFonts(self.recordedDefaults)
    self:NormalizeRetiredFonts(self.db)
    self:NormalizeTargetCastOrigin(self.defaults)
    self:NormalizeTargetCastOrigin(self.db.design)
    self:NormalizeTargetCastOrigin(self.db.moduleDefaults)
    self:NormalizeTargetAuraOrigins(self.defaults)
    self:NormalizeTargetAuraOrigins(self.db.design)
    self:NormalizeTargetAuraOrigins(self.db.moduleDefaults)
    self:NormalizeResourceOrigin(self.defaults)
    self:NormalizeResourceOrigin(self.db.design)
    self:NormalizeResourceOrigin(self.db.moduleDefaults)
    self:NormalizeValueTextAnchors(self.defaults)
    self:NormalizeValueTextAnchors(self.db.design)
    self:NormalizeValueTextAnchors(self.db.moduleDefaults)
    self:NormalizeRaidMarkPivot(self.db.design)
    self:NormalizeRaidMarkPivot(self.db.moduleDefaults)
    self:NormalizeCenterDecoration(self.db.design)
    self:NormalizeCenterDecoration(self.db.moduleDefaults)
    self:EnsureCenterClassification(self.db.design)
    self:EnsureCenterClassification(self.db.moduleDefaults)
    self:RepairValueTextScale()
    self:EnsurePlayerHealthPercent(self.defaults)
    self:EnsurePlayerHealthPercent(self.recordedDefaults)
    self:EnsurePlayerHealthPercent(self.db.design)
    self:EnsurePlayerHealthPercent(self.db.moduleDefaults)
    if self.EnsureAttackProgress then self:EnsureAttackProgress(self.db.design) end
    self.byID={}
    for _,n in ipairs(self.db.design.nodes) do self.byID[n.id]=n end
    local targetHealth=self.byID.wa385c615b2a
    if targetHealth then
        -- Expose the existing low-health condition without changing saved colors.
        local legacy
        for _,condition in ipairs(targetHealth.conditions or {}) do
            if condition.field=="percenthealth" and condition.op=="<" then
                for _,change in ipairs(condition.changes or {}) do
                    if change.field=="color" then legacy=condition;break end
                end
                if legacy then break end
            end
        end
        if targetHealth.healthThresholdEnabled==nil then
            targetHealth.healthThresholdEnabled=legacy~=nil and targetHealth.healthColor==nil and targetHealth.healthGradient~=true
        end
        targetHealth.healthThreshold=M.Clamp(math.floor(tonumber(targetHealth.healthThreshold) or (legacy and tonumber(legacy.value)) or 25),1,100)
        if not targetHealth.healthThresholdColor then
            local color={1,0,0,1}
            for _,change in ipairs(legacy and legacy.changes or {}) do if change.field=="color" then color=change.value;break end end
            targetHealth.healthThresholdColor=self.Copy(color)
        end
    end
    self:NormalizeCenterPortraitOcclusion(self.defaults)
    self:NormalizeCenterPortraitOcclusion(self.recordedDefaults)
    self:NormalizeCenterPortraitOcclusion(self.db.design)
    self:NormalizeCenterPortraitOcclusion(self.db.moduleDefaults)
    self:SyncCenterPortraitBlack(self.byID)
    self:NormalizeScaleReferences(self.defaults)
    self:NormalizeScaleReferences(self.db.design)
    self:NormalizeScaleReferences(self.db.moduleDefaults)
    if self.SettingRanges then self.SettingRanges.ClampAll(self.byID) end
    self:NormalizeNodeTextures(self.defaults)
    self:NormalizeNodeTextures(self.recordedDefaults or {})
    self:NormalizeNodeTextures(self.db.design)
    self:NormalizeNodeTextures(self.db.moduleDefaults or {})
    self.indexedNodes=self.db.design.nodes;self.indexedNodeCount=#self.indexedNodes
end
M.moduleIDs={mainComposite=true,wa8d650f8d3a=true,petComposite=true,totComposite=true,focusComposite=true}
function M:ModuleID(node,index)
    index=index or self.byID
    local guard=0
    while node and guard<100 do
        if self.moduleIDs[node.id] then return node.id end
        if self.moduleIDs[node.treeParent] then return node.treeParent end
        node=index[node.parent];guard=guard+1
    end
end
function M:SetModuleEnabled(moduleID,enabled)
    if not self.moduleIDs[moduleID] or not self:CanEdit() then return false end
    local module=self.byID[moduleID]
    if not module then return false end
    module.enabled=enabled==true;self:Commit();return true
end
function M:SetHideWithoutTarget(enabled)
    if not self:CanEdit() then return false end
    self.db.hideWithoutTarget=enabled==true;self:Commit();return true
end
function M:SetPortrait3D(enabled)
    if not self:CanEdit() then return false end
    self.db.portrait3D=enabled==true;self:Commit();return true
end
function M:SetAdapt4KUIScale(enabled)
    if not self:CanEdit() then return false end
    self.db.adapt4KUIScale=enabled==true
    self:ApplyUIScale();return true
end
function M:SetHealthClassColor(enabled)
    if not self:CanEdit() then return false end
    self.db.healthClassColor=enabled==true;self:Commit();return true
end
function M:EffectiveFontPath(localPath)
    if self.db and self.db.useGlobalFont then localPath=self.db.globalFontPath end
    return self:ResolveFontPath(localPath)
end
function M:SetGlobalFont(enabled,path,name)
    if not self:CanEdit() then return false end
    if enabled~=nil then self.db.useGlobalFont=enabled==true end
    if type(path)=="string" and path~="" then self.db.globalFontPath=path;self.db.globalFontName=name or "默认" end
    self:Commit()
    if self.RefreshOtherSettings then self:RefreshOtherSettings() end
    return true
end
function M:FlushCommit()
    self.commitRefreshToken=nil
    if self.committing then return end
    self.committing=true
    self.renderBatch={}
    local ok,err=pcall(function()
    self:Index(true)
    if self.EditorUndo then self.EditorUndo.Record() end
    if self.started and self.ApplyLive then
        if InCombatLockdown() then self.pending=true else self:Safe("应用布局",self.ApplyLive,self) end
    end
    if self.RefreshEditor then self:RefreshEditor() end
    end)
    self.committing=nil
    self.renderBatch=nil
    if not ok then error(err) end
end
function M:Commit()
    if self.SavePlayerSkillMonitorClass then self:SavePlayerSkillMonitorClass()end
    if self.SavePlayerOtherMonitorClass then self:SavePlayerOtherMonitorClass()end
    if self.SaveCommonItemsClass then self:SaveCommonItemsClass()end
    if self.SaveRaidVulnerabilityClass then self:SaveRaidVulnerabilityClass()end
    if self.SaveReceivedBuffs then self:SaveReceivedBuffs()end
    if self.SaveRaidBuffMonitorClass then self:SaveRaidBuffMonitorClass()end
    local session=self.EditorUndo and self.EditorUndo.session
    if C_Timer and C_Timer.After and session and session.transaction then
        if not self.commitRefreshToken then
            local token={};self.commitRefreshToken=token
            -- Keep the latest inputs in one pending refresh, without holding
            -- continuous preview changes for a fixed 100 ms interval.
            C_Timer.After(0,function()
                if self.commitRefreshToken==token then self:FlushCommit() end
            end)
        end
    else
        self:FlushCommit()
    end
end
function M:IsChild(id,parent)
    local n=self.byID[id]; local guard=0
    while n and n.parent and guard<100 do
        if n.parent==parent then return true end
        n=self.byID[n.parent]; guard=guard+1
    end
    return false
end
function M:ResetDesign()
    if not self:CanEdit() then return end
    self.db.design=self.Copy(self.recordedDefaults or self.defaults); self.selection="mainComposite"; self:Commit()
end
function M:ResetPreviewModule(moduleID)
    if not self.moduleIDs[moduleID] or not self:CanEdit() then return end
    local defaultsByID,currentByID,sourceNodes,sourceSeen={},{},{},{}
    local function AddSource(n)
        if not sourceSeen[n.id] then sourceNodes[#sourceNodes+1]=n.id;sourceSeen[n.id]=true end
        defaultsByID[n.id]=n
    end
    for _,n in ipairs(self.defaults.nodes) do AddSource(n) end
    local saved=self.db.moduleDefaults
    if type(saved)=="table" and type(saved.nodes)=="table" then
        for _,n in ipairs(saved.nodes) do AddSource(n) end
    end
    for _,n in ipairs(self.db.design.nodes) do currentByID[n.id]=n end
    local function Belongs(id,index)
        local seen={}
        local n=index[id]
        while n and not seen[n.id] do
            if n.id==moduleID or (moduleID=="mainComposite" and n.treeParent=="mainComposite") then return true end
            seen[n.id]=true;n=index[n.parent]
        end
        return false
    end
    local resetIDs={}
    for _,id in ipairs(sourceNodes) do
        if Belongs(id,defaultsByID) then resetIDs[id]=true end
    end
    local nodes,seen={},{}
    for _,n in ipairs(self.db.design.nodes) do
        if resetIDs[n.id] then
            nodes[#nodes+1]=self.Copy(defaultsByID[n.id]);seen[n.id]=true
        elseif not Belongs(n.id,currentByID) then
            nodes[#nodes+1]=n
        end
    end
    for _,id in ipairs(sourceNodes) do
        if resetIDs[id] and not seen[id] then nodes[#nodes+1]=self.Copy(defaultsByID[id]) end
    end
    self.db.design.nodes=nodes
    if not currentByID[self.selection] or (Belongs(self.selection,currentByID) and not resetIDs[self.selection]) then
        self.selection=moduleID;self.multi={[moduleID]=true}
    end
    self:Commit()
end
