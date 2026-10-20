local _,M=...
local H={};M.MonitorSharing=H
local S=M.PlayerSkillMonitor
local definitions={
    raidVulnerability={api=M.RaidVulnerability,shared="raidVulnerabilityShared",profiles="raidVulnerabilityByClass",class="raidVulnerabilityClass",list="raidVulnerability",own="classVulnerabilities",save="SaveRaidVulnerabilityClass",ensure="EnsureRaidVulnerability"},
    raidBuffs={api=M.RaidBuffMonitor,shared="raidBuffsShared",profiles="raidBuffsByClass",class="raidBuffsClass",list="raidBuffs",own="classBuffs",save="SaveRaidBuffMonitorClass",ensure="EnsureRaidBuffMonitor"},
    commonItems={api=M.CommonItems,shared="commonItemsShared",profiles="commonItemsByClass",class="commonItemsClass",list="commonItems",own="classItems",save="SaveCommonItemsClass",ensure="EnsureCommonItems"},
}
function H.Scope(scope)
    if type(scope)~="string"then return end
    for id in pairs(definitions)do
        if scope==id or scope==id.."All"or scope==id.."Class"then return id,scope==id.."All"end
    end
end
function H.Encode(prefix,config)
    local ok,result=pcall(function()
        local serializer,deflate=LibStub("LibSerialize"),LibStub("LibDeflate")
        local payload=serializer:Serialize(config);if #payload>2000000 then return end
        local text=prefix..string.format("%08X",deflate:Adler32(payload))..":"..deflate:EncodeForPrint(deflate:CompressDeflate(payload,{level=1}))
        if #text<=200000 then return text end
    end)
    return ok and result or nil
end
function H.Decode(prefix,input)
    if type(input)~="string"or #input>400000 then return end
    local text=input:gsub("%s+","");if #text>200000 or text:sub(1,#prefix)~=prefix then return end
    local sum,encoded=text:sub(#prefix+1):match("^([0-9A-Fa-f]+):(.+)$");if not sum or #sum~=8 then return end
    local ok,result=pcall(function()
        local serializer,deflate=LibStub("LibSerialize"),LibStub("LibDeflate");local packed=deflate:DecodeForPrint(encoded)
        if not packed then return end
        local payload,remaining=deflate:DecompressDeflate(packed)
        if not payload or remaining~=0 or #payload>2000000 or string.format("%08X",deflate:Adler32(payload))~=sum:upper()then return end
        local valid,config=serializer:Deserialize(payload);if valid then return config end
    end)
    return ok and result or nil
end
local function Clean(config)
    if type(config)~="table"or config.format~=1 then return end
    local d=definitions[config.module];if not d or not d.api.ValidProfiles(config.profiles)then return end
    if config.scope=="class"then
        if not S.ValidClass(config.class)or config.profiles[config.class]==nil or config.shared~=nil then return end
        for class in pairs(config.profiles)do if class~=config.class then return end end
    elseif config.scope~="all"or config.class~=nil or not d.api.ValidEntries(config.shared)then return end
    return {format=1,module=config.module,scope=config.scope,class=config.class,profiles=M.Copy(config.profiles),shared=config.shared and M.Copy(config.shared)}
end
function M:ExportMonitorString(id,all)
    local d=definitions[id];if not d then return end
    self[d.save](self)
    local class=self.db[d.class];if not S.ValidClass(class)then return end
    local profiles=self.db[d.profiles]or {}
    local config=Clean({format=1,module=id,scope=all and "all"or "class",class=not all and class or nil,
        profiles=all and profiles or {[class]=profiles[class]},shared=all and self.db[d.shared]or nil})
    if config then return H.Encode("!MUM1:",config)end
end
function M:ImportMonitorString(input,id)
    local config=Clean(H.Decode("!MUM1:",input))
    if config and (not id or config.module==id)then return config end
end
function M:ApplyMonitorString(input,id)
    if not self:CanEdit()then return false,"战斗中暂不能修改布局，脱战后即可编辑。"end
    local config=self:ImportMonitorString(input,id)
    if not config then return false,"配置字符串无效或已损坏，请检查是否完整复制。"end
    local d=definitions[config.module];if d.api.FlushEditor then d.api.FlushEditor()end
    self[d.save](self)
    local group=self.byID[config.module];local current=self.db[d.class]
    self.db[d.profiles]=self.db[d.profiles]or {}
    for class,entries in pairs(config.profiles)do self.db[d.profiles][class]=M.Copy(entries)end
    if config.shared then self.db[d.shared]=M.Copy(config.shared);group[d.list]=M.Copy(config.shared)end
    if config.profiles[current]then group[d.own]=M.Copy(config.profiles[current])end
    self[d.ensure](self,self.db.design);self:Commit();return true
end
function H.BuildControls(e,parent,id,flush)
    local W=M.Widgets;local frame=CreateFrame("Frame",nil,parent);frame:SetSize(470,56)
    frame.title=W.Label(frame,"配置分享",12);frame.title:SetPoint("CENTER",frame,"TOP",0,12);frame.title:SetTextColor(1,.82,0)
    M:SetLocaleLineHeight(frame.title,18);frame.title:SetJustifyH("CENTER")
    local left=frame:CreateTexture(nil,"ARTWORK");left:SetHeight(1);left:SetColorTexture(.5,.5,.5,.45)
    left:SetPoint("LEFT",frame,"TOPLEFT",0,12);left:SetPoint("RIGHT",frame.title,"LEFT",-8,0)
    local right=frame:CreateTexture(nil,"ARTWORK");right:SetHeight(1);right:SetColorTexture(.5,.5,.5,.45)
    right:SetPoint("LEFT",frame.title,"RIGHT",8,0);right:SetPoint("RIGHT",frame,"TOPRIGHT",0,12)
    frame.exportAll=W.Button(frame,"导出全职业配置",150,function()flush();M:ShowConfigStringDialog("export",id.."All")end)
    frame.exportClass=W.Button(frame,"导出当前职业配置",150,function()flush();M:ShowConfigStringDialog("export",id.."Class")end)
    frame.import=W.Button(frame,"导入配置",150,function()flush();M:ShowConfigStringDialog("import",id)end)
    for _,button in ipairs({frame.exportAll,frame.exportClass,frame.import})do button:SetHoverTextColor(1,.82,0)end
    e[id.."Sharing"]=frame
    e.propRows[#e.propRows+1]={height=56,controls={{frame,0,0}},kinds={},key=id.."Sharing"}
end
function H.RefreshControls(e,group)
    if not definitions[group.compound]then return end
    local frame=e[group.compound.."Sharing"];if not frame then return end
    local width=e.props:GetWidth();frame:SetWidth(width)
    for index,button in ipairs({frame.exportAll,frame.exportClass,frame.import})do
        local w=(width-16)/3;button:SetWidth(w);button:ClearAllPoints();button:SetPoint("TOPLEFT",(index-1)*(w+8),-24)
    end
end
