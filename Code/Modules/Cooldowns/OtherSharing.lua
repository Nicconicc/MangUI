local _,M=...
local O,S=M.PlayerOtherMonitor,M.PlayerSkillMonitor
local PREFIX="!MUO1:"
local function Clean(config)
    local result=S.CleanCharacterSharing(config,"playerOtherMonitor");if not result then return end
    if config.format==2 then
        if config.overrides~=nil or config.equipment~=nil then return end
    elseif config.scope=="all"then
        if config.overrides~=nil and not O.ValidOverrides(config.overrides)then return end
        if config.equipment~=nil and not O.ValidEquipmentEntries(config.equipment)then return end
        result.overrides=config.overrides and M.Copy(config.overrides);result.equipment=config.equipment and M.Copy(config.equipment)
    elseif config.overrides~=nil or config.equipment~=nil then return end
    return result
end
function M:ExportPlayerOtherMonitorString(all)
    self:SavePlayerOtherMonitorClass()
    local ok,result=pcall(function()
        local config=Clean(S.ExportCharacterSharing("playerOtherMonitor"))
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
    local ok,errorText=S.ApplyCharacterSharing("playerOtherMonitor",config)
    if not ok then return false,errorText or "配置字符串无效或已损坏，请检查是否完整复制。"end
    if config.scope=="all"and config.overrides then self.db.otherMonitorEquipmentOverrides=M.Copy(config.overrides)end
    if config.scope=="all"and config.equipment then self.db.otherMonitorEquipmentEntries=M.Copy(config.equipment)end
    if config.scope=="all"then O.MigrateEquipment(self.db);self:SavePlayerOtherMonitorClass()end
    self:Commit();return true
end
