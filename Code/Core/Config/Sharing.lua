local _,M=...
local PREFIX="!MUF1:"
local SKILL_PREFIX="!MUS1:"
local MAX_TEXT=200000
local MAX_PAYLOAD=2000000
local INVALID="配置字符串无效或已损坏，请检查是否完整复制。"
local function Libraries()
    return LibStub("LibSerialize"),LibStub("LibDeflate")
end
local function ValidTree(value,stack,depth,budget,stringLimit)
    budget.count=budget.count+1
    if depth>16 or budget.count>100000 then return false end
    local kind=type(value)
    if kind=="number" then return value==value and math.abs(value)<=1000000000 end
    if kind=="boolean" then return true end
    if kind=="string" then return #value<=(stringLimit or 4096)end
    if kind~="table" or stack[value] then return false end
    stack[value]=true
    for key,child in pairs(value) do
        if type(key)~="string" and type(key)~="number" then return false end
        if type(key)=="string" and #key>128 then return false end
        if type(key)=="number" and (key<1 or key>10000 or key%1~=0) then return false end
        local limit=key=="customCode"and value.type=="custom"and M.CustomMonitor.MAX_CODE or nil
        if not ValidTree(child,stack,depth+1,budget,limit)then return false end
    end
    stack[value]=nil;return true
end
local function CleanNodes(nodes)
    if type(nodes)~="table" or #nodes<5 or #nodes>1000 then return end
    for _,node in ipairs(nodes) do if type(node)~="table" or type(node.id)~="string" then return end end
    nodes=M.Copy(nodes)
    for _,node in ipairs(nodes) do for i=1,5 do
        local value=node["petBuff"..i]
        if value~=nil and (type(value)~="string" or #value>384) then return end
    end end
    for _,node in ipairs(nodes) do
        if node.monitors~=nil then
            local valid=node.id=="receivedBuffs"and M.ReceivedBuffs.ValidEntries or M.PlayerSkillMonitor.ValidEntries
            if not valid(node.monitors)then return end
        end
        if node.otherMonitors~=nil and not M.PlayerOtherMonitor.ValidEntries(node.otherMonitors)then return end
        if node.commonItems~=nil and not M.CommonItems.ValidEntries(node.commonItems)then return end
        if node.raidBuffs~=nil and not M.RaidBuffMonitor.ValidEntries(node.raidBuffs)then return end
        if node.raidVulnerability~=nil and not M.RaidVulnerability.ValidEntries(node.raidVulnerability)then return end
        if node.classItems~=nil and not M.CommonItems.ValidEntries(node.classItems)then return end
        if node.classBuffs~=nil and not M.RaidBuffMonitor.ValidEntries(node.classBuffs)then return end
        if node.classVulnerabilities~=nil and not M.RaidVulnerability.ValidEntries(node.classVulnerabilities)then return end
    end
    M:NormalizeAssetPaths(nodes)
    M:NormalizeRetiredFonts(nodes)
    M:NormalizeCenterDecoration({nodes=nodes})
    M:EnsureCenterClassification({nodes=nodes})
    M:EnsureThirdResource({nodes=nodes})
    if M.EnsurePetBuffs then M:EnsurePetBuffs({nodes=nodes}) end
    if M.EnsureCooldownModule then M:EnsureCooldownModule({nodes=nodes}) end
    if M.EnsurePlayerSkillMonitor then M:EnsurePlayerSkillMonitor({nodes=nodes}) end
    if M.EnsurePlayerOtherMonitor then M:EnsurePlayerOtherMonitor({nodes=nodes})end
    if M.EnsureCommonItems then M:EnsureCommonItems({nodes=nodes})end
    if M.EnsureReceivedBuffs then M:EnsureReceivedBuffs({nodes=nodes})end
    if M.EnsureRaidBuffMonitor then M:EnsureRaidBuffMonitor({nodes=nodes})end
    if M.EnsureRaidVulnerability then M:EnsureRaidVulnerability({nodes=nodes})end
    if M.EnsureChatButtonsModule then M:EnsureChatButtonsModule({nodes=nodes}) end
    if M.EnsureCombatNoticesModule then M:EnsureCombatNoticesModule({nodes=nodes}) end
    if M.EnsureSystemMenuModule then M:EnsureSystemMenuModule({nodes=nodes}) end
    if M.EnsureMouseCircleModule then M:EnsureMouseCircleModule({nodes=nodes}) end
    if M.EnsureExperienceBarModule then M:EnsureExperienceBarModule({nodes=nodes}) end
    if M.EnsureTargetThreatModule then M:EnsureTargetThreatModule({nodes=nodes}) end
    if M.EnsureTargetDistanceModule then M:EnsureTargetDistanceModule({nodes=nodes}) end
    if M.EnsureBossFramesModule then M:EnsureBossFramesModule({nodes=nodes}) end
    if M.EnsurePartyFramesModule then M:EnsurePartyFramesModule({nodes=nodes}) end
    if M.ModuleGuides then M.ModuleGuides.Ensure({nodes=nodes})end
    if M.EnsureAttackProgress then M:EnsureAttackProgress({nodes=nodes}) end
    local known,fields,index,result={},{},{},{}
    for _,node in ipairs(M.defaults.nodes) do
        known[node.id]=node.kind
        for key,value in pairs(node) do
            fields[key]=fields[key] or {};fields[key][type(value)]=true
        end
    end
    for _,key in ipairs({"fontPath","fontName","materialPath","materialName"}) do fields[key]={string=true} end
    fields.healthGradient={boolean=true};fields.healthColor={table=true};fields.healthGradientEnd={table=true}
    fields.healthThresholdEnabled={boolean=true};fields.healthThreshold={number=true};fields.healthThresholdColor={table=true}
    fields.targetDistanceHint={boolean=true}
    fields.valueUnit={string=true}
    fields.hideUntimedBuffs={boolean=true}
    fields.onlyPlayerDebuffs={boolean=true}
    for _,key in ipairs({"scaleReference","modelScaleReference","mainScaleFactor","resourceOriginRevision","auraOriginRevision","castOriginRevision",
        "valueTextOriginRevision","valueTextAnchorRevision","valueTextScaleFixRevision",
        "valueTextScalePreviousX","valueTextScalePreviousY","raidMarkPivotRevision"})do fields[key]={number=true}end
    for _,key in ipairs({"decorationBaseX","decorationBaseY","decorationPivotRevision"}) do fields[key]={number=true} end
    fields.classificationPivotRevision={number=true}
    fields.portraitNameOnly={boolean=true}
    fields.showRangedProgress={boolean=true};fields.showMeleeProgress={boolean=true}
    for _,key in ipairs({"resourceSpacing","debuffCount","debuffPerRow","buffCount","buffPerRow","moveX","moveY"}) do fields[key]={number=true} end
    for key in pairs(nodes) do if type(key)~="number" or key<1 or key>#nodes or key%1~=0 then return end end
    for _,node in ipairs(nodes) do
        if type(node)~="table" or type(node.id)~="string" or not known[node.id] or known[node.id]~=node.kind or index[node.id] then return end
        for key,value in pairs(node) do if not fields[key] or not fields[key][type(value)] then return end end
        if node.valueUnit~=nil and (not M.LargeValueUnits.Supports(node)or (node.valueUnit~="K"and node.valueUnit~="W"))then return end
        if node.healthThreshold and (node.healthThreshold<1 or node.healthThreshold>100 or node.healthThreshold%1~=0) then return end
        if node.id=="partyFrames"then
            for _,key in ipairs({"partyMaterialPath","partyMaterialName","partyFontPath","partyFontName"})do
                if type(node[key])~="string"then return end
            end
            if type(node.hidePartyNumbers)~="boolean"or type(node.hidePartyPlayer)~="boolean"or type(node.hidePartyInRaid)~="boolean"
                or type(node.partyHealthColor)~="table"or type(node.partyHealthEndColor)~="table"then return end
            for _,range in ipairs({{"partySpacing",0,300},{"partyPlayerX",-500,500},{"partyNameSize",.1,10000}})do
                local value=node[range[1]]
                if type(value)~="number" or value<range[2]or value>range[3]then return end
            end
        end
        for _,key in ipairs({"healthColor","healthGradientEnd","healthThresholdColor","rangedProgressColor","meleeProgressColor","partyHealthColor","partyHealthEndColor","distanceNumberColor"}) do
            local color=node[key]
            if color then
                for i=1,4 do if type(color[i])~="number" or color[i]<0 or color[i]>1 then return end end
                for component in pairs(color) do if type(component)~="number" or component<1 or component>4 or component%1~=0 then return end end
            end
        end
        for _,key in ipairs({"x","y","width","height","scale","alpha","layer","fontSize","rotation","fps","frames","rows","columns"}) do
            if node[key]~=nil and type(node[key])~="number" then return end
        end
        if node.scale and (node.scale<=0 or node.scale>10) then return end
        if node.mainScaleFactor and (node.mainScaleFactor<=0 or node.mainScaleFactor>100) then return end
        for _,key in ipairs({"scaleReference","modelScaleReference"})do
            if node[key] and (node[key]<=0 or node[key]>100)then return end
        end
        if node.width and (node.width<1 or node.width>4000) then return end
        if node.height and (node.height<1 or node.height>4000) then return end
        if node.alpha and (node.alpha<0 or node.alpha>1) then return end
        if node.enabled~=nil and type(node.enabled)~="boolean" then return end
        if node.parent~=nil and type(node.parent)~="string" then return end
        if node.treeParent~=nil and type(node.treeParent)~="string" then return end
        if node.label~=nil and type(node.label)~="string" then return end
        index[node.id]=node;result[#result+1]=M.Copy(node)
    end
    for id in pairs(M.moduleIDs) do if not index[id] then return end end
    for _,node in ipairs(nodes) do
        if node.parent and not index[node.parent] then return end
        if node.treeParent and not index[node.treeParent] then return end
        local seen={};local current=node;local depth=0
        while current do
            if seen[current.id] or depth>64 then return end
            seen[current.id]=true;current=current.parent and index[current.parent];depth=depth+1
        end
    end
    M:NormalizeNodeTextures({nodes=result})
    return result
end
local function CleanConfig(config)
    if type(config)~="table" or not ValidTree(config,{},0,{count=0}) then return end
    if config.format~=1 or config.schema~=82 then return end
    if not M:IsLanguageSupported(config.language) then
        local legacy={auto=true,enGB=true,zhTW=true,deDE=true,frFR=true,esES=true,esMX=true,itIT=true,ptBR=true,ruRU=true,koKR=true}
        if not legacy[config.language] then return end
        config.language=config.language=="zhTW" and "zhCN" or (config.language=="auto" and M:ClientLanguage() or "enUS")
    end
    if config.hideWithoutTarget~=nil and type(config.hideWithoutTarget)~="boolean" then return end
    if config.portrait3D~=nil and type(config.portrait3D)~="boolean" then return end
    if config.healthClassColor~=nil and type(config.healthClassColor)~="boolean" then return end
    if config.adapt4KUIScale~=nil and type(config.adapt4KUIScale)~="boolean" then return end
    if config.clientFontScale~=nil and (type(config.clientFontScale)~="number" or config.clientFontScale<.5 or config.clientFontScale>1.5) then return end
    if config.useGlobalFont~=nil and type(config.useGlobalFont)~="boolean" then return end
    local characterMonitors
    if config.characterMonitors~=nil then
        characterMonitors=M.PlayerSkillMonitor.CleanCharacterSettings(config.characterMonitors)
        if not characterMonitors then return end
    end
    for _,definition in ipairs({{"playerSkillMonitorsByCharacter","playerSkillMonitorCharacter",M.PlayerSkillMonitor.ValidEntries},{"playerOtherMonitorsByCharacter","playerOtherMonitorCharacter",M.PlayerOtherMonitor.ValidEntries}})do
        local profiles,owner=config[definition[1]],config[definition[2]]
        if profiles~=nil and (not M.PlayerSkillMonitor.ValidCharacterProfiles(profiles,definition[3])or not M.PlayerSkillMonitor.ValidCharacter(owner)or profiles[owner]==nil)then return end
    end
    if config.playerSkillMonitorsByClass~=nil and (not M.PlayerSkillMonitor.ValidClassProfiles(config.playerSkillMonitorsByClass)
        or not M.PlayerSkillMonitor.ValidClass(config.playerSkillMonitorClass))then return end
    if config.playerOtherMonitorsByClass~=nil and (not M.PlayerOtherMonitor.ValidProfiles(config.playerOtherMonitorsByClass)
        or not M.PlayerSkillMonitor.ValidClass(config.playerOtherMonitorClass))then return end
    if config.commonItemsShared~=nil and not M.CommonItems.ValidEntries(config.commonItemsShared)then return end
    if config.raidBuffsUnified~=nil and type(config.raidBuffsUnified)~="boolean"then return end
    if config.commonItemsUnified~=nil and type(config.commonItemsUnified)~="boolean"then return end
    if config.raidVulnerabilityUnified~=nil and type(config.raidVulnerabilityUnified)~="boolean"then return end
    if config.raidBuffsShared~=nil and not M.RaidBuffMonitor.ValidEntries(config.raidBuffsShared)then return end
    if config.raidVulnerabilityShared~=nil and not M.RaidVulnerability.ValidEntries(config.raidVulnerabilityShared)then return end
    if config.commonItemsByClass~=nil and (not M.CommonItems.ValidProfiles(config.commonItemsByClass)or not M.PlayerSkillMonitor.ValidClass(config.commonItemsClass))then return end
    if config.receivedBuffsShared~=nil and not M.ReceivedBuffs.ValidEntries(config.receivedBuffsShared)then return end
    if config.receivedBuffsByClass~=nil and (not M.ReceivedBuffs.ValidProfiles(config.receivedBuffsByClass)or not M.PlayerSkillMonitor.ValidClass(config.receivedBuffsClass))then return end
    if config.raidBuffsByClass~=nil and (not M.RaidBuffMonitor.ValidProfiles(config.raidBuffsByClass)or not M.PlayerSkillMonitor.ValidClass(config.raidBuffsClass))then return end
    if config.raidVulnerabilityByClass~=nil and (not M.RaidVulnerability.ValidProfiles(config.raidVulnerabilityByClass)or not M.PlayerSkillMonitor.ValidClass(config.raidVulnerabilityClass))then return end
    if config.otherMonitorEquipmentOverrides~=nil and not M.PlayerOtherMonitor.ValidOverrides(config.otherMonitorEquipmentOverrides)then return end
    if config.otherMonitorEquipmentEntries~=nil and not M.PlayerOtherMonitor.ValidEquipmentEntries(config.otherMonitorEquipmentEntries)then return end
    for _,key in ipairs({"globalFontPath","globalFontName"})do
        if config[key]~=nil and (type(config[key])~="string"or #config[key]>512)then return end
    end
    if type(config.hideBlizzard)~="boolean" or type(config.minimap)~="table" then return end
    if type(config.minimap.hide)~="boolean" or type(config.minimap.angle)~="number" then return end
    if type(config.design)~="table" or type(config.moduleDefaults)~="table" then return end
    local nodes=CleanNodes(config.design.nodes);local defaults=CleanNodes(config.moduleDefaults.nodes)
    if not nodes or not defaults then return end
    return {format=1,schema=82,language=config.language,hideBlizzard=config.hideBlizzard,hideWithoutTarget=config.hideWithoutTarget==true,
        portrait3D=config.portrait3D==true,
        healthClassColor=config.healthClassColor==true,
        adapt4KUIScale=config.adapt4KUIScale==true,
        clientFontScale=M:NormalizeClientFontScale(config.clientFontScale),
        useGlobalFont=config.useGlobalFont==true,
        globalFontPath=M:ResolveFontPath(config.globalFontPath and config.globalFontPath~="" and config.globalFontPath or M:DefaultFontPath()),
        globalFontName=not M:IsRetiredFont(config.globalFontName) and config.globalFontName and config.globalFontName~="" and config.globalFontName or "默认",
        minimap={hide=config.minimap.hide,angle=config.minimap.angle},
        characterMonitors=characterMonitors,
        playerSkillMonitorsByCharacter=config.playerSkillMonitorsByCharacter and M.Copy(config.playerSkillMonitorsByCharacter),playerSkillMonitorCharacter=config.playerSkillMonitorCharacter,
        playerOtherMonitorsByCharacter=config.playerOtherMonitorsByCharacter and M.Copy(config.playerOtherMonitorsByCharacter),playerOtherMonitorCharacter=config.playerOtherMonitorCharacter,
        playerSkillMonitorsByClass=config.playerSkillMonitorsByClass and M.Copy(config.playerSkillMonitorsByClass),
        playerSkillMonitorClass=config.playerSkillMonitorsByClass and config.playerSkillMonitorClass,
        playerOtherMonitorsByClass=config.playerOtherMonitorsByClass and M.Copy(config.playerOtherMonitorsByClass),
        playerOtherMonitorClass=config.playerOtherMonitorClass,
        commonItemsShared=config.commonItemsShared and M.Copy(config.commonItemsShared),
        raidBuffsUnified=config.raidBuffsUnified==true,
        commonItemsUnified=config.commonItemsUnified==true,
        raidVulnerabilityUnified=config.raidVulnerabilityUnified==true,
        raidBuffsShared=config.raidBuffsShared and M.Copy(config.raidBuffsShared),
        raidVulnerabilityShared=config.raidVulnerabilityShared and M.Copy(config.raidVulnerabilityShared),
        commonItemsByClass=config.commonItemsByClass and M.Copy(config.commonItemsByClass),commonItemsClass=config.commonItemsClass,
        receivedBuffsShared=config.receivedBuffsShared and M.Copy(config.receivedBuffsShared),
        receivedBuffsByClass=config.receivedBuffsByClass and M.Copy(config.receivedBuffsByClass),receivedBuffsClass=config.receivedBuffsClass,
        raidBuffsByClass=config.raidBuffsByClass and M.Copy(config.raidBuffsByClass),raidBuffsClass=config.raidBuffsClass,
        raidVulnerabilityByClass=config.raidVulnerabilityByClass and M.Copy(config.raidVulnerabilityByClass),raidVulnerabilityClass=config.raidVulnerabilityClass,
        otherMonitorEquipmentOverrides=config.otherMonitorEquipmentOverrides and M.Copy(config.otherMonitorEquipmentOverrides),
        otherMonitorEquipmentEntries=config.otherMonitorEquipmentEntries and M.Copy(config.otherMonitorEquipmentEntries),
        design={nodes=nodes},moduleDefaults={nodes=defaults}}
end
local function CleanSkillConfig(config)
    if type(config)~="table"or not ValidTree(config,{},0,{count=0})then return end
    return M.PlayerSkillMonitor.CleanCharacterSharing(config,"playerSkillMonitor")
end
function M:ExportPlayerSkillMonitorString(allClasses)
    self:SavePlayerSkillMonitorClass()
    local ok,result=pcall(function()
        local config=CleanSkillConfig(M.PlayerSkillMonitor.ExportCharacterSharing("playerSkillMonitor"))
        if not config then return end
        local serializer,deflate=Libraries();local payload=serializer:Serialize(config)
        if #payload>MAX_PAYLOAD then return end
        local text=SKILL_PREFIX..string.format("%08X",deflate:Adler32(payload))..":"..deflate:EncodeForPrint(deflate:CompressDeflate(payload,{level=1}))
        if #text<=MAX_TEXT then return text end
    end)
    return ok and result or nil
end
function M:ImportPlayerSkillMonitorString(input)
    if type(input)~="string"or #input>MAX_TEXT*2 then return end
    local text=input:gsub("%s+","")
    if #text>MAX_TEXT or text:sub(1,#SKILL_PREFIX)~=SKILL_PREFIX then return end
    local checksum,encoded=text:sub(#SKILL_PREFIX+1):match("^([0-9A-Fa-f]+):(.+)$")
    if not checksum or #checksum~=8 then return end
    local ok,result=pcall(function()
        local serializer,deflate=Libraries();local packed=deflate:DecodeForPrint(encoded)
        if not packed then return end
        local payload,remaining=deflate:DecompressDeflate(packed)
        if not payload or remaining~=0 or #payload>MAX_PAYLOAD then return end
        if string.format("%08X",deflate:Adler32(payload))~=checksum:upper()then return end
        local success,config=serializer:Deserialize(payload)
        if success then return CleanSkillConfig(config)end
    end)
    return ok and result or nil
end
function M:ApplyPlayerSkillMonitorString(input)
    if not self:CanEdit()then return false,"战斗中暂不能修改布局，脱战后即可编辑。"end
    local config=self:ImportPlayerSkillMonitorString(input)
    if not config then return false,INVALID end
    local panel=self.editor and self.editor.skillMonitorPanel
    if panel then
        panel:FinishDrag(false)
        for _,row in ipairs(panel.rows)do row.edit:ClearFocus();row.shortcutEdit:ClearFocus()end
    end
    local ok,errorText=self.PlayerSkillMonitor.ApplyCharacterSharing("playerSkillMonitor",config)
    if not ok then return false,errorText or INVALID end
    self:Commit();return true
end
function M:ExportConfigString()
    self:SavePlayerSkillMonitorClass()
    self:SavePlayerOtherMonitorClass()
    self:SaveCommonItemsClass()
    self:SaveReceivedBuffs()
    self:SaveRaidBuffMonitorClass()
    self:SaveRaidVulnerabilityClass()
    local ok,result=pcall(function()
        local serializer,deflate=Libraries()
        local config=CleanConfig({format=1,schema=self.db.schema,language=self.db.language,
            hideBlizzard=self.db.hideBlizzard,hideWithoutTarget=self.db.hideWithoutTarget,portrait3D=self.db.portrait3D,
            healthClassColor=self.db.healthClassColor,minimap=self.db.minimap,
            adapt4KUIScale=self.db.adapt4KUIScale,
            clientFontScale=self.db.clientFontScale,
            useGlobalFont=self.db.useGlobalFont,globalFontPath=self.db.globalFontPath,globalFontName=self.db.globalFontName,
            characterMonitors=self.PlayerSkillMonitor.ExportCharacterSettings(),
            commonItemsShared=self.db.commonItemsShared,commonItemsByClass=self.db.commonItemsByClass,commonItemsClass=self.db.commonItemsClass,
            receivedBuffsShared=self.db.receivedBuffsShared,
            raidBuffsUnified=self.db.raidBuffsUnified==true,
            commonItemsUnified=self.db.commonItemsUnified==true,
            raidVulnerabilityUnified=self.db.raidVulnerabilityUnified==true,
            raidBuffsShared=self.db.raidBuffsShared,raidBuffsByClass=self.db.raidBuffsByClass,raidBuffsClass=self.db.raidBuffsClass,
            raidVulnerabilityShared=self.db.raidVulnerabilityShared,raidVulnerabilityByClass=self.db.raidVulnerabilityByClass,raidVulnerabilityClass=self.db.raidVulnerabilityClass,
            otherMonitorEquipmentOverrides=self.db.otherMonitorEquipmentOverrides,
            design=self.db.design,moduleDefaults=self.db.moduleDefaults})
        if not config then return end
        local payload=serializer:Serialize(config)
        if #payload>MAX_PAYLOAD then return end
        -- Fast, lossless compression keeps export responsive. The wire format
        -- and complete configuration remain compatible with earlier versions.
        local packed=deflate:CompressDeflate(payload,{level=1})
        local encoded=deflate:EncodeForPrint(packed)
        local text=PREFIX..string.format("%08X",deflate:Adler32(payload))..":"..encoded
        if #text>MAX_TEXT then return end
        return text
    end)
    return ok and result or nil
end
function M:ImportConfigString(input)
    if type(input)~="string" or #input>MAX_TEXT*2 then return end
    local text=input:gsub("%s+","")
    if #text>MAX_TEXT then return end
    local checksum,encoded=text:match("^!MUF1:([0-9A-Fa-f]+):(.+)$")
    if not checksum or #checksum~=8 then return end
    local ok,result=pcall(function()
        local serializer,deflate=Libraries()
        local packed=deflate:DecodeForPrint(encoded)
        if not packed then return end
        local payload,remaining=deflate:DecompressDeflate(packed)
        if not payload or remaining~=0 or #payload>MAX_PAYLOAD then return end
        if string.format("%08X",deflate:Adler32(payload))~=checksum:upper() then return end
        local success,config=serializer:Deserialize(payload)
        if not success then return end
        return CleanConfig(config)
    end)
    return ok and result or nil
end
function M:ApplyConfigString(input)
    if not self:CanEdit() then return false,"战斗中暂不能修改布局，脱战后即可编辑。" end
    if type(input)=="string"and #input<=400000 and input:gsub("%s+",""):sub(1,6)=="!MUM1:"then return self:ApplyMonitorString(input)end
    if type(input)=="string"and #input<=400000 and input:gsub("%s+",""):sub(1,6)=="!MUG1:"then return self:ApplyReceivedBuffsString(input)end
    if type(input)=="string"and #input<=400000 and input:gsub("%s+",""):sub(1,6)=="!MUO1:"then return self:ApplyPlayerOtherMonitorString(input)end
    if type(input)=="string"and #input<=MAX_TEXT*2 and input:gsub("%s+",""):sub(1,#SKILL_PREFIX)==SKILL_PREFIX then
        return self:ApplyPlayerSkillMonitorString(input)
    end
    local config=self:ImportConfigString(input)
    if not config then return false,INVALID end
    if self.PlayerOtherMonitor.FlushEditor then self.PlayerOtherMonitor.FlushEditor()end
    if self.CommonItems.FlushEditor then self.CommonItems.FlushEditor()end
    if self.ReceivedBuffs.FlushEditor then self.ReceivedBuffs.FlushEditor()end
    if self.RaidBuffMonitor.FlushEditor then self.RaidBuffMonitor.FlushEditor()end
    if self.RaidVulnerability.FlushEditor then self.RaidVulnerability.FlushEditor()end
    if self.moveMode and self.StopFrameMoveMode then self:StopFrameMoveMode(false) end
    self:SavePlayerSkillMonitorClass()
    self:SavePlayerOtherMonitorClass()
    self:SaveCommonItemsClass()
    self:SaveReceivedBuffs()
    self:SaveRaidBuffMonitorClass()
    self:SaveRaidVulnerabilityClass()
    self.db.design=config.design;self.db.moduleDefaults=config.moduleDefaults
    self:ImportPlayerSkillMonitorClasses(config)
    self:ImportPlayerOtherMonitorClasses(config)
    self:ImportCommonItems(config)
    self:ImportReceivedBuffs(config)
    self:ImportRaidBuffMonitor(config)
    self:ImportRaidVulnerability(config)
    self.db.language=config.language;self.db.minimap=config.minimap;self.db.hideBlizzard=config.hideBlizzard
    self.db.hideWithoutTarget=config.hideWithoutTarget
    self.db.portrait3D=config.portrait3D
    self.db.healthClassColor=config.healthClassColor
    self.db.adapt4KUIScale=config.adapt4KUIScale
    self.db.clientFontScale=config.clientFontScale
    self:ApplyClientFontScale()
    self:ApplyUIScale()
    self.db.useGlobalFont=config.useGlobalFont
    self.db.globalFontPath=config.globalFontPath;self.db.globalFontName=config.globalFontName
    self:Index()
    if not self.byID[self.selection] then self.selection="mainComposite";self.multi={mainComposite=true} end
    self:Commit();self:CreateMinimap();self:RefreshLanguage()
    return true
end
