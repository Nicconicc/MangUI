local _,M=...
local H={};M.MonitorSharing=H
local S=M.PlayerSkillMonitor
local definitions={
    raidVulnerability={api=M.RaidVulnerability,shared="raidVulnerabilityShared",profiles="raidVulnerabilityByClass",class="raidVulnerabilityClass",list="raidVulnerability",own="classVulnerabilities",save="SaveRaidVulnerabilityClass",ensure="EnsureRaidVulnerability"},
    raidBuffs={api=M.RaidBuffMonitor,shared="raidBuffsShared",profiles="raidBuffsByClass",class="raidBuffsClass",list="raidBuffs",own="classBuffs",save="SaveRaidBuffMonitorClass",ensure="EnsureRaidBuffMonitor"},
    commonItems={api=M.CommonItems,shared="commonItemsShared",profiles="commonItemsByClass",class="commonItemsClass",list="commonItems",own="classItems",save="SaveCommonItemsClass",ensure="EnsureCommonItems"},
}
local function CurrentClass()
    local _,class=M.RaidBuffMonitor.Safe(UnitClass,"player")
    return S.ValidClass(class)and class
end
local function Configured(d,entry)
    return d.api.Kind(entry)=="equipment"or entry.value~=""or (entry.alternative or "")~=""or (entry.createSpell or "")~=""
end
local function EntryKey(d,entry)
    local parts={}
    for _,value in ipairs({d.api.Kind(entry),entry.value,entry.alternative or "",entry.createSpell or "",tostring(entry.slot or 13)})do parts[#parts+1]=#value..":"..value end
    return table.concat(parts,"|")
end
function H.AddClassEntries(d,result,entries,class)
    local index={};for _,entry in ipairs(result)do index[EntryKey(d,entry)]=entry end
    for _,entry in ipairs(entries or {})do if Configured(d,entry)then
        local key=EntryKey(d,entry);local prior=index[key]
        if prior then prior.classes=M.RaidBuffMonitor.ClassMask(prior);prior.classes[class]=true
        else local copy=M.Copy(entry);copy.classes={[class]=true};result[#result+1]=copy;index[key]=copy end
    end end
end
function H.Unify(d,shared,profiles)
    local entries=M.Copy(shared or {})
    for _,entry in ipairs(entries)do entry.classes=M.RaidBuffMonitor.ClassMask(entry)end
    for _,info in ipairs(M.RaidBuffMonitor.classes)do H.AddClassEntries(d,entries,profiles and profiles[info[1]],info[1])end
    return entries
end
function H.SaveUnified(id)
    local d=definitions[id];local db=M.db;local group=db and d.api.Group(db.design);if not group then return end
    if d.api.ValidEntries(group[d.list])then db[d.shared]=M.Copy(group[d.list])end
    group[d.own]={};db[id.."Unified"]=true;db[d.profiles]={};db[d.class]=CurrentClass()or db[d.class]
end
function H.BindUnified(id)
    local d=definitions[id];local db=M.db;local group=d.api.Group(db.design);if not group then return end
    if not db[id.."Unified"]then
        local shared=d.api.ValidEntries(db[d.shared])and db[d.shared]or group[d.list]
        local profiles=d.api.ValidProfiles(db[d.profiles])and M.Copy(db[d.profiles])or {}
        local previous=S.ValidClass(db[d.class])and db[d.class]or CurrentClass()
        if previous and d.api.ValidEntries(group[d.own])then
            local configured=false;for _,entry in ipairs(group[d.own])do if Configured(d,entry)then configured=true;break end end
            if configured or not profiles[previous]then profiles[previous]=M.Copy(group[d.own])end
        end
        db[id.."LegacyBackup"]=db[id.."LegacyBackup"]or {shared=M.Copy(shared),profiles=M.Copy(profiles)}
        db[d.shared]=H.Unify(d,shared,profiles);db[id.."Unified"]=true
    end
    group[d.list]=M.Copy(d.api.ValidEntries(db[d.shared])and db[d.shared]or group[d.list]);group[d.own]={}
    H.SaveUnified(id)
end
function H.ImportUnified(id,config)
    local d=definitions[id];local db=M.db;local group=d.api.Group(db.design)
    db[d.shared]=M.Copy(config[d.shared]or group[d.list]);db[d.profiles]=M.Copy(config[d.profiles]or {})
    db[d.class]=config[d.class]or CurrentClass();db[id.."Unified"]=config[id.."Unified"]==true
    H.BindUnified(id)
end
function H.BuildClassControls(row,flush,editable)
    local W=M.Widgets;local I=M.RaidBuffMonitor
    row.classLabel=W.Label(row,"职业加载",12);row.classLabel:SetPoint("TOPLEFT",0,-105)
    row.classLabel:SetWidth(92);row.classLabel:SetHeight(18);row.classLabel:SetWordWrap(false)
    row.classButtons={}
    for _,info in ipairs(I.AvailableClasses())do
        local button=CreateFrame("Button",nil,row);button:SetSize(24,24)
        button.classToken=info[1];button.classInfo=info;row.classButtons[#row.classButtons+1]=button
        button.icon=button:CreateTexture(nil,"ARTWORK");button.icon:SetSize(23.04,23.04);button.icon:SetPoint("CENTER")
        button.icon:SetAtlas("UI-HUD-MicroMenu-Communities-Icon-Notification",false);button.icon:SetDesaturated(true)
        button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
        button:SetScript("OnClick",function(self)
            flush();if editable()then
                local enabled=I.ForClass(row.entry,self.classToken)
                row.entry.classes=I.ClassMask(row.entry);row.entry.classes[self.classToken]=not enabled;M:Commit()
            end
        end)
        button:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(M:EffectiveLanguage()=="zhCN"and self.classInfo[2]or self.classInfo[3],1,1,1);GameTooltip:Show()
        end)
        button:SetScript("OnLeave",function()GameTooltip:Hide()end)
    end
end
function H.RefreshClassControls(row,entry,width)
    local I=M.RaidBuffMonitor;local step=math.min(28,math.max(18,(width-96)/#row.classButtons))
    for index,button in ipairs(row.classButtons)do
        button:ClearAllPoints();button:SetPoint("TOPLEFT",96+(index-1)*step,-102);button:SetWidth(math.min(24,step))
        local info=button.classInfo;local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[button.classToken];local enabled=I.ForClass(entry,button.classToken)
        button.icon:SetAlpha(enabled and 1 or .3)
        if enabled then
            local r,g,b=color and color.r or info[4],color and color.g or info[5],color and color.b or info[6]
            button.icon:SetVertexColor(math.min(1,r*1.08),math.min(1,g*1.08),math.min(1,b*1.08),1)
        else button.icon:SetVertexColor(.78,.78,.78,1)end
        button.selected=enabled
    end
end
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
    if type(config)=="table"and config.module=="raidBuffs"then return M.RaidBuffMonitor.CleanSharing(config)end
    if type(config)~="table"then return end
    local d=definitions[config.module];if not d then return end
    if config.format==2 then
        if not d.api.ValidEntries(config.entries)then return end
        if config.scope=="class"then if not S.ValidClass(config.class)then return end
        elseif config.scope~="all"or config.class~=nil then return end
        local entries=M.Copy(config.entries)
        for _,entry in ipairs(entries)do entry.classes=config.scope=="class"and {[config.class]=true}or M.RaidBuffMonitor.ClassMask(entry)end
        return {format=2,module=config.module,scope=config.scope,class=config.class,entries=entries}
    end
    if config.format~=1 or not d.api.ValidProfiles(config.profiles)then return end
    if config.scope=="class"then
        if not S.ValidClass(config.class)or config.profiles[config.class]==nil or config.shared~=nil then return end
        for class in pairs(config.profiles)do if class~=config.class then return end end
        local entries={};H.AddClassEntries(d,entries,config.profiles[config.class],config.class)
        return {format=2,module=config.module,scope="class",class=config.class,entries=entries,legacy=true}
    elseif config.scope~="all"or config.class~=nil or not d.api.ValidEntries(config.shared)then return end
    local entries=H.Unify(d,config.shared,config.profiles);if not d.api.ValidEntries(entries)then return end
    return {format=2,module=config.module,scope="all",entries=entries}
end
function M:ExportMonitorString(id,all)
    local d=definitions[id];if not d then return end
    if id=="raidBuffs"then local config=self:ExportRaidBuffSharing();return config and H.Encode("!MUM1:",config)end
    self[d.save](self)
    local config=Clean({format=2,module=id,scope="all",entries=self.db[d.shared]or {}})
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
    if config.module=="raidBuffs"then return self:ApplyRaidBuffSharing(config)end
    self[d.save](self)
    local group=self.byID[config.module];local entries
    if config.scope=="all"then entries=M.Copy(config.entries)
    else
        entries={}
        for _,entry in ipairs(group[d.list])do
            local copy=M.Copy(entry);local was=M.RaidBuffMonitor.ForClass(copy,config.class);copy.classes=M.RaidBuffMonitor.ClassMask(copy)
            local universal=true;for _,info in ipairs(M.RaidBuffMonitor.classes)do if not copy.classes[info[1]]then universal=false;break end end
            if not(config.legacy and universal)then copy.classes[config.class]=nil end
            local enabled=false;for _,state in pairs(copy.classes)do if state then enabled=true;break end end
            if not was or enabled then entries[#entries+1]=copy end
        end
        H.AddClassEntries(d,entries,config.entries,config.class)
    end
    if not d.api.ValidEntries(entries)then return false,"配置字符串无效或已损坏，请检查是否完整复制。"end
    group[d.list]=entries;group[d.own]={}
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
    frame.exportAll=W.Button(frame,"导出配置",150,function()flush();M:ShowConfigStringDialog("export",id.."All")end)
    frame.import=W.Button(frame,"导入配置",150,function()flush();M:ShowConfigStringDialog("import",id)end)
    frame.buttons={frame.exportAll,frame.import}
    for _,button in ipairs(frame.buttons)do button:SetHoverTextColor(1,.82,0)end
    e[id.."Sharing"]=frame
    e.propRows[#e.propRows+1]={height=56,controls={{frame,0,0}},kinds={},key=id.."Sharing"}
end
function H.RefreshControls(e,group)
    if not definitions[group.compound]then return end
    local frame=e[group.compound.."Sharing"];if not frame then return end
    local width=e.props:GetWidth();frame:SetWidth(width)
    for index,button in ipairs(frame.buttons)do
        local w=(width-(#frame.buttons-1)*8)/#frame.buttons;button:SetWidth(w);button:ClearAllPoints();button:SetPoint("TOPLEFT",(index-1)*(w+8),-24)
    end
end
