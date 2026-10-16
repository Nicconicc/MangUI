local _,M=...
M:UpgradeFocusCast(M.defaults)
M:UpgradeFocusCastScale(M.defaults)
M:UpgradeFocusCastAlignIcon(M.defaults)
M:UpgradePetFrame(M.defaults)
M:UpgradeTotFrame(M.defaults)
M:UpgradeTotHPY(M.defaults)
M:UpgradePlayerHP(M.defaults)
M:UpgradePlayerMP(M.defaults)
M:UpgradeTargetHP(M.defaults)
M:UpgradeTargetMP(M.defaults)
M:UpgradeCenterPortrait(M.defaults)
M:UpgradeTargetName(M.defaults)
M:UpgradeCenterLevel(M.defaults)
M:UpgradeCenterClassification(M.defaults)
M:UpgradeCenterFire(M.defaults)
M:UpgradeMainComposite(M.defaults)
M:UpgradeBarMenus(M.defaults)
M:UpgradeTargetPortraitScale(M.defaults)
M:UpgradeCenterFallbackPortraitScale(M.defaults)
M:UpgradeCenterGlass(M.defaults)
M:UpgradeCenterGlassLayer(M.defaults)
M:UpgradeMainRamps(M.defaults)
M:UpgradeMainLayerAlpha(M.defaults)
M:UpgradeCenterLightRotation(M.defaults)
M:UpgradeCenterLogo(M.defaults)
M:UpgradeCenterLogoScale(M.defaults)
M:UpgradeMainBarParticles(M.defaults)
M:UpgradeMainHPLayersY(M.defaults)
M:UpgradeTargetDebuffComposite(M.defaults)
M:UpgradeTargetBuffComposite(M.defaults)
M:UpgradeTargetRaidMark(M.defaults)
M:UpgradeCenterClassificationIcons(M.defaults)
M:UpgradePlayerResources(M.defaults)
M:UpgradeAnimationEffectsTrigger(M.defaults)
M:UpgradeAnimationEffectsOnce(M.defaults)
M:UpgradeMainAnimationEffects(M.defaults)
M:UpgradePlayerCastComposite(M.defaults)
M:UpgradePlayerCastFill(M.defaults)
M:UpgradePlayerCastDirectFill(M.defaults)
M:UpgradePlayerCastLayer(M.defaults)
M:UpgradePlayerPowerDisplay(M.defaults)
M:UpgradeTargetCastComposite(M.defaults)
local previewLabels={
    wadb51e41246="玩家生命值", wa8ee62b16d6="玩家能量值", wa6edbcf125a="玩家能量值",
    wa70b7aa5607="玩家生命条", waf0a666c0b7="玩家能量条",
    waf465575a72="目标生命条", wae608adf3d8="目标能量条",
    wa8492858a6d="目标生命值", wa712a8bee10="目标生命值百分比", wa074335b474="目标能量值",
    wa88e7259b1c="目标Buff", wa026b04c50e="目标Debuff", wabc757f81ee="头像框体",
    centerLogo="CenterLogo", targetUnifiedName="目标姓名", waf24f8d43e3="目标团队标记",
    centerLevel="头像等级", centerClassification="稀有精英图标", centerFire="头像框体装饰",
    wa65978f0ae2="动画特效", playerResources="玩家资源", targetCast="目标施法条",
}
for _,n in ipairs(M.defaults.nodes) do
    if previewLabels[n.id] then n.label=previewLabels[n.id] end
    if n.kind=="bar" and n.alphaFill then
        n.materialName="Solid"
        n.materialPath="Interface\\Buttons\\WHITE8X8"
    end
end
local targetHPFiles={TargetHPKuang=true,TargetHPGlass=true,TargetHPRamp=true,
    TargetHPColor=true,TargetHPBG=true,TargetHPShadow=true}
local centerPortraitFiles={CenterLight=true,CenterGlass=true,CenterBlack=true}
for code=string.byte("A"),string.byte("M") do centerPortraitFiles["CenterKuang_"..string.char(code)]=true end
for _,entry in ipairs(M.catalog) do
    if entry.name and entry.name:match("^PlayerHP") then
        entry.file=entry.file:gsub("\\Art\\PlayerHP","\\Assets\\PlayerHP")
    elseif entry.name and entry.name:match("^PlayerPower") then
        entry.file=entry.file:gsub("\\Art\\PlayerPower","\\Assets\\PlayerPower")
    elseif targetHPFiles[entry.name] then
        entry.file=entry.file:gsub("\\Art\\TargetHP","\\Assets\\TargetHP")
    elseif entry.name=="TargetHPParticular" then
        entry.file="Interface\\AddOns\\MangUI\\Assets\\Library\\TargetHPParticular"
        entry.fps=25
    elseif entry.name and entry.name:match("^TargetPower") then
        entry.file=entry.file:gsub("\\Art\\TargetPower","\\Assets\\TargetPower")
    elseif centerPortraitFiles[entry.name] then
        entry.file=entry.file:gsub("\\Art\\Center","\\Assets\\Center")
    end
end

-- Keep the generated fresh preset aligned with the linked portrait layers.
M:NormalizeRaidMarkPivot(M.defaults)
M:NormalizeValueTextAnchors(M.defaults)
do
    local index={}
    for _,node in ipairs(M.defaults.nodes) do index[node.id]=node end
    M:SyncCenterPortraitBlack(index)
end
