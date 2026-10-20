local _,M=...
local I,S=M.ReceivedBuffs,M.PlayerSkillMonitor
local PREFIX="!MUG1:"
local function Clean(config)
    if type(config)~="table"or config.module~="receivedBuffs"then return end
    if config.format==2 and config.scope=="shared"and I.ValidEntries(config.entries)then
        return {format=2,module="receivedBuffs",scope="shared",entries=M.Copy(config.entries)}
    end
    -- Keep existing class exports importable as a shared list.
    if config.format~=1 or not I.ValidProfiles(config.profiles)then return end
    if config.scope=="class"then
        if not S.ValidClass(config.class)or not config.profiles[config.class]then return end
        for class in pairs(config.profiles)do if class~=config.class then return end end
    elseif config.scope~="all"or config.class~=nil then return end
    local _,class=I.Safe(UnitClass,"player")
    local entries=config.profiles[config.class or class]
    if not entries then
        local keys={};for key in pairs(config.profiles)do keys[#keys+1]=key end;table.sort(keys)
        entries=keys[1]and config.profiles[keys[1]]
    end
    if entries then return {format=2,module="receivedBuffs",scope="shared",entries=M.Copy(entries)}end
end
function M:ExportReceivedBuffsString()
    self:SaveReceivedBuffs()
    local config=Clean({format=2,module="receivedBuffs",scope="shared",entries=self.db.receivedBuffsShared})
    if config then return M.MonitorSharing.Encode(PREFIX,config)end
end
function M:ImportReceivedBuffsString(input)
    return Clean(M.MonitorSharing.Decode(PREFIX,input))
end
function M:ApplyReceivedBuffsString(input)
    if not self:CanEdit()then return false,"战斗中暂不能修改布局，脱战后即可编辑。"end
    local config=self:ImportReceivedBuffsString(input)
    if not config then return false,"配置字符串无效或已损坏，请检查是否完整复制。"end
    if I.FlushEditor then I.FlushEditor()end
    self.byID.receivedBuffs.monitors=M.Copy(config.entries)
    self:EnsureReceivedBuffs(self.db.design);self:Commit();return true
end
