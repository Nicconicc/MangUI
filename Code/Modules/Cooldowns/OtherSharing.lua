local _,M=...
local O,S=M.PlayerOtherMonitor,M.PlayerSkillMonitor
local PREFIX="!MUO1:"
local function Clean(config)
    if type(config)~="table"or config.format~=1 or config.module~="playerOtherMonitor"or not O.ValidProfiles(config.profiles)then return end
    if config.scope=="class"then
        if not S.ValidClass(config.class)or config.profiles[config.class]==nil or config.overrides~=nil or config.equipment~=nil then return end
        for class in pairs(config.profiles)do if class~=config.class then return end end
    elseif config.scope~="all"or config.class~=nil or (config.overrides~=nil and not O.ValidOverrides(config.overrides))
        or (config.equipment~=nil and not O.ValidEquipmentEntries(config.equipment))then return end
    if next(config.profiles)==nil then return end
    return {format=1,module="playerOtherMonitor",scope=config.scope,class=config.class,
        profiles=M.Copy(config.profiles),overrides=config.overrides and M.Copy(config.overrides),equipment=config.equipment and M.Copy(config.equipment)}
end
function M:ExportPlayerOtherMonitorString(all)
    self:SavePlayerOtherMonitorClass()
    local ok,result=pcall(function()
        local class=self.db.playerOtherMonitorClass;local profiles=self.db.playerOtherMonitorsByClass or {}
        local config=Clean({format=1,module="playerOtherMonitor",scope=all and "all"or "class",class=not all and class or nil,
            profiles=all and profiles or {[class]=profiles[class]},overrides=all and self.db.otherMonitorEquipmentOverrides or nil})
        if not config then return end
        local serializer,deflate=LibStub("LibSerialize"),LibStub("LibDeflate");local payload=serializer:Serialize(config)
        if #payload>2000000 then return end
        local text=PREFIX..string.format("%08X",deflate:Adler32(payload))..":"..deflate:EncodeForPrint(deflate:CompressDeflate(payload,{level=1}))
        if #text<=200000 then return text end
    end)
    return ok and result or nil
end
function M:ImportPlayerOtherMonitorString(input)
    if type(input)~="string"or #input>400000 then return end
    local text=input:gsub("%s+","");if #text>200000 or text:sub(1,#PREFIX)~=PREFIX then return end
    local sum,encoded=text:sub(#PREFIX+1):match("^([0-9A-Fa-f]+):(.+)$");if not sum or #sum~=8 then return end
    local ok,result=pcall(function()
        local serializer,deflate=LibStub("LibSerialize"),LibStub("LibDeflate");local packed=deflate:DecodeForPrint(encoded)
        if not packed then return end
        local payload,remaining=deflate:DecompressDeflate(packed)
        if not payload or remaining~=0 or #payload>2000000 or string.format("%08X",deflate:Adler32(payload))~=sum:upper()then return end
        local valid,config=serializer:Deserialize(payload);if valid then return Clean(config)end
    end)
    return ok and result or nil
end
function M:ApplyPlayerOtherMonitorString(input)
    if not self:CanEdit()then return false,"战斗中暂不能修改布局，脱战后即可编辑。"end
    local config=self:ImportPlayerOtherMonitorString(input)
    if not config then return false,"配置字符串无效或已损坏，请检查是否完整复制。"end
    if O.FlushEditor then O.FlushEditor()end
    self:SavePlayerOtherMonitorClass();local current=self.db.playerOtherMonitorClass
    self.db.playerOtherMonitorsByClass=self.db.playerOtherMonitorsByClass or {}
    for class,entries in pairs(config.profiles)do
        self.db.playerOtherMonitorsByClass[class]=M.Copy(entries)
    end
    if config.profiles[current]then
        self.byID.playerOtherMonitor.otherMonitors=M.Copy(self.db.playerOtherMonitorsByClass[current]);self:EnsurePlayerOtherMonitor(self.db.design)
    end
    if config.scope=="all"and config.overrides then self.db.otherMonitorEquipmentOverrides=M.Copy(config.overrides)end
    if config.scope=="all"and config.equipment then self.db.otherMonitorEquipmentEntries=M.Copy(config.equipment)end
    if config.scope=="all"then O.MigrateEquipment(self.db)end
    self:Commit();return true
end
