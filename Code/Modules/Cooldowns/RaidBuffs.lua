local _,M=...
local I={};M.RaidBuffMonitor=I
local S,O=M.PlayerSkillMonitor,M.PlayerOtherMonitor
I.Safe,I.Number,I.Readable=O.Safe,O.Number,O.Readable
function I.DefaultGuideText(group)
    if M.ModuleGuides then return M.ModuleGuides.DefaultText(group)end
    local english=M.localeTables and M.localeTables.enUS
    local text=english and english["团队Buff缺失监控"]or "Missing raid buff tracking"
    return (text:gsub("[Tt][Rr][Aa][Cc][Kk][Ii][Nn][Gg]",""):gsub("%s+"," "):match("^%s*(.-)%s*$"))
end
function I.GuideText(group)
    return type(group.guideText)=="string"and group.guideText or I.DefaultGuideText(group)
end
function I.GuideLength(group)
    return M.Clamp(I.Number(group.guideLineLength)or 1,0,1)
end
function I.GuideHorizontalLength(group)
    return M.Clamp(I.Number(group.guideHorizontalLength)or 1,0,1)
end
function I.GuideOpacity(group)
    return M.Clamp(I.Number(group.guideOpacity)or .6,0,1)
end
I.classes={
    {"WARRIOR","战士","Warrior",.78,.61,.43},{"PALADIN","圣骑士","Paladin",.96,.55,.73},
    {"HUNTER","猎人","Hunter",.67,.83,.45},{"ROGUE","潜行者","Rogue",1,.96,.41},
    {"PRIEST","牧师","Priest",1,1,1},{"DEATHKNIGHT","死亡骑士","Death Knight",.77,.12,.23},
    {"SHAMAN","萨满祭司","Shaman",0,.44,.87},{"MAGE","法师","Mage",.25,.78,.92},
    {"WARLOCK","术士","Warlock",.53,.53,.93},{"MONK","武僧","Monk",0,1,.60},
    {"DRUID","德鲁伊","Druid",1,.49,.04},{"DEMONHUNTER","恶魔猎手","Demon Hunter",.64,.19,.79},
    {"EVOKER","唤魔师","Evoker",.20,.58,.50},
}
function I.AvailableClasses()
    local interface=M.Compat.interface or 0
    local family=interface==16001 and 1 or math.floor(interface/10000)
    local introduced={DEATHKNIGHT=3,MONK=5,DEMONHUNTER=7,EVOKER=10}
    local result={}
    for _,info in ipairs(I.classes)do if family>=(introduced[info[1]]or 1)then result[#result+1]=info end end
    return result
end
local function Class()local _,class=I.Safe(UnitClass,"player");return S.ValidClass(class)and class end
function I.AllClasses()
    local result={};for _,class in ipairs(I.classes)do result[class[1]]=true end;return result
end
function I.ForClass(entry,class)return entry.classes==nil or entry.classes[class]==true end
function I.ClassMask(entry)return M.Copy(entry.classes or I.AllClasses())end
function I.NewEntry()return {value="",alternative="",classes=I.AllClasses()}end
function I.Kind(entry)return entry.type or "buff"end
function I.ValidEntries(entries)
    if type(entries)~="table"or #entries>4096 then return false end
    for k,entry in pairs(entries)do
        if type(k)~="number"or k%1~=0 or k<1 or k>#entries or type(entry)~="table"then return false end
        if type(entry.value)~="string"or #entry.value>384 then return false end
        if entry.alternative~=nil and (type(entry.alternative)~="string"or #entry.alternative>384)then return false end
        if entry.type~=nil and entry.type~="buff"and entry.type~="classWeapon"and entry.type~="consumable"then return false end
        if entry.slot~=nil and entry.slot~="main"and entry.slot~="off"and entry.slot~="both"and entry.slot~="any"then return false end
        if entry.classes~=nil then
            if type(entry.classes)~="table"then return false end
            for class,enabled in pairs(entry.classes)do if not S.ValidClass(class)or type(enabled)~="boolean"then return false end end
        end
        for field in pairs(entry)do if field~="value"and field~="alternative"and field~="type"and field~="slot"and field~="classes"then return false end end
    end
    for index=1,#entries do if type(entries[index])~="table"then return false end end
    return true
end
function I.ValidProfiles(profiles)
    if type(profiles)~="table"then return false end
    for class,entries in pairs(profiles)do if not S.ValidClass(class)or not I.ValidEntries(entries)then return false end end
    return true
end
function I.Group(design)
    for _,node in ipairs(design and design.nodes or {})do if node.id=="raidBuffs"then return node end end
end
function I.NormalizeEntries(entries)
    for _,entry in ipairs(entries or {})do
        if entry.type=="consumable"then
            local value=S.Input(entry.value)
            local id=tonumber(value)or tonumber(value:match("item:(%d+)"))
            if id==267773 or value=="尤亚姆巴巫师之油"or value:lower()=="yojamba wizard oil"then
                -- This Titan consumable grants a player aura, not a weapon enchant.
                entry.type,entry.value,entry.alternative,entry.slot="buff","1282985","",nil
            end
        end
    end
end
function I.Entries(group)
    local entries={};local class=Class()
    I.NormalizeEntries(group.raidBuffs)
    for _,entry in ipairs(group.raidBuffs or {})do
        if class and I.ForClass(entry,class)then
            if I.Kind(entry)=="buff"then
                if entry.value~=""or (entry.alternative or "")~=""then entries[#entries+1]=entry end
            elseif M.WeaponEnhancements then
                for _,rule in ipairs(M.WeaponEnhancements.Expand(entry))do entries[#entries+1]=rule end
            end
        end
    end
    return entries
end
function I.MoveBounds(group)
    local count=math.max(1,#I.Entries(group))
    return S.RowOffset(group,count),-25,math.max(320,count*44+160),156
end
function I.RestorePosition(group,reference)
    local x,y=320,-380
    if reference then local cx,cy=I.MoveBounds(reference);local scale=M:NodeScale(reference);x,y=((reference.x or 0)+cx)*scale,((reference.y or 0)+cy)*scale end
    local cx,cy=I.MoveBounds(group);local scale=math.max(.001,M:NodeScale(group));group.x,group.y=x/scale-cx,y/scale-cy
end
function M:EnsureRaidBuffMonitor(design)
    if not design or not design.nodes then return end
    local group=I.Group(design)
    if not group then
        local source
        for _,node in ipairs(design.nodes)do if node.id=="playerSkillMonitor"then source=node;break end end
        source=source or S and self.defaults and self.defaults.nodes[1]
        group={id="raidBuffs",label="玩家常驻团队增益监控",kind="group",compound="raidBuffs",scope="player",unit="player",
            width=2,height=2,scale=source and source.scale or 1,scaleReference=source and (source.scaleReference or source.scale)or 1,
            point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=350,hideWithoutTarget=false,raidOnly=true,growthDirection="CENTER",
            raidBuffs={I.NewEntry()},classBuffs={}}
        I.RestorePosition(group);design.nodes[#design.nodes+1]=group
    end
    if not I.ValidEntries(group.raidBuffs)then group.raidBuffs={}end
    if not I.ValidEntries(group.classBuffs)then group.classBuffs={}end
    I.NormalizeEntries(group.raidBuffs);I.NormalizeEntries(group.classBuffs)
    if group.hideWithoutTarget==nil then group.hideWithoutTarget=false end
    if group.raidOnly==nil then group.raidOnly=true end
    if type(group.hideGuideLines)~="boolean"then group.hideGuideLines=false end
    if type(group.showGuideText)~="boolean"then group.showGuideText=true end
    group.guideLineLength=I.GuideLength(group)
    group.guideHorizontalLength=I.GuideHorizontalLength(group)
    group.guideOpacity=I.GuideOpacity(group)
    if type(group.guideText)~="string"or #group.guideText>384 then group.guideText=I.DefaultGuideText()end
    group.growthDirection=S.Direction(group)
    for _,node in ipairs(design.nodes)do if node.id=="raidBuffsIcons"then return end end
    design.nodes[#design.nodes+1]={id="raidBuffsIcons",label="玩家常驻团队增益监控",kind="raidbuffs",parent="raidBuffs",
        internal=true,locked=true,scope="player",unit="player",x=0,y=0,width=40,height=66,autoWidth=true,
        scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=351}
end
local function EntryKey(entry)
    local parts={};for _,value in ipairs({I.Kind(entry),entry.value,entry.alternative or "",entry.slot or "main"})do parts[#parts+1]=#value..":"..value end
    return table.concat(parts,"|")
end
local function Configured(entry)return I.Kind(entry)~="buff"or entry.value~=""or (entry.alternative or "")~=""end
function I.AddClassEntries(result,entries,class)
    for _,entry in ipairs(entries or {})do
        if Configured(entry)then
            local match;local key=EntryKey(entry)
            for _,prior in ipairs(result)do if EntryKey(prior)==key then match=prior;break end end
            if match then match.classes=I.ClassMask(match);match.classes[class]=true
            else local copy=M.Copy(entry);copy.classes={[class]=true};result[#result+1]=copy end
        end
    end
end
function I.Unify(shared,profiles)
    local result=M.Copy(shared or {})
    for _,entry in ipairs(result)do entry.classes=I.ClassMask(entry)end
    for _,class in ipairs(I.classes)do I.AddClassEntries(result,profiles and profiles[class[1]],class[1])end
    I.NormalizeEntries(result);return result
end
function M:SaveRaidBuffMonitorClass()
    local db=self.db;local group=db and I.Group(db.design);if not group then return end
    if I.ValidEntries(group.raidBuffs)then db.raidBuffsShared=M.Copy(group.raidBuffs)end
    group.classBuffs={};db.raidBuffsUnified=true;db.raidBuffsByClass={};db.raidBuffsClass=Class()or db.raidBuffsClass
end
function M:BindRaidBuffMonitorClass()
    local db=self.db;local group=I.Group(db.design);if not group then return end
    if not db.raidBuffsUnified then
        local shared=I.ValidEntries(db.raidBuffsShared)and db.raidBuffsShared or group.raidBuffs
        local profiles=I.ValidProfiles(db.raidBuffsByClass)and M.Copy(db.raidBuffsByClass)or {}
        local previous=S.ValidClass(db.raidBuffsClass)and db.raidBuffsClass or Class()
        if previous and I.ValidEntries(group.classBuffs)then
            local configured=false;for _,entry in ipairs(group.classBuffs)do if Configured(entry)then configured=true;break end end
            if configured or not profiles[previous]then profiles[previous]=M.Copy(group.classBuffs)end
        end
        db.raidBuffsLegacyBackup=db.raidBuffsLegacyBackup or {shared=M.Copy(shared),profiles=M.Copy(profiles)}
        db.raidBuffsShared=I.Unify(shared,profiles);db.raidBuffsUnified=true
    end
    group.raidBuffs=M.Copy(I.ValidEntries(db.raidBuffsShared)and db.raidBuffsShared or group.raidBuffs)
    I.NormalizeEntries(group.raidBuffs);group.classBuffs={}
    self:SaveRaidBuffMonitorClass()
end
function M:ImportRaidBuffMonitor(config)
    local group=I.Group(self.db.design)
    self.db.raidBuffsShared=M.Copy(config.raidBuffsShared or group.raidBuffs)
    self.db.raidBuffsByClass=M.Copy(config.raidBuffsByClass or {})
    self.db.raidBuffsClass=config.raidBuffsClass or Class()
    self.db.raidBuffsUnified=config.raidBuffsUnified==true
    self:BindRaidBuffMonitorClass()
end
function I.CleanSharing(config)
    if type(config)~="table"or config.module~="raidBuffs"then return end
    if config.format==2 then
        if not I.ValidEntries(config.entries)then return end
        if config.scope=="class"then
            if not S.ValidClass(config.class)then return end
        elseif config.scope~="all"or config.class~=nil then return end
        local entries=M.Copy(config.entries)
        for _,entry in ipairs(entries)do entry.classes=config.scope=="class"and {[config.class]=true}or I.ClassMask(entry)end
        return {format=2,module="raidBuffs",scope=config.scope,class=config.class,entries=entries}
    end
    if config.format~=1 or not I.ValidProfiles(config.profiles)then return end
    if config.scope=="class"then
        if not S.ValidClass(config.class)or not config.profiles[config.class]or config.shared~=nil then return end
        for class in pairs(config.profiles)do if class~=config.class then return end end
        local entries={};I.AddClassEntries(entries,config.profiles[config.class],config.class)
        return {format=2,module="raidBuffs",scope="class",class=config.class,entries=entries,legacy=true}
    end
    if config.scope~="all"or config.class~=nil or not I.ValidEntries(config.shared)then return end
    local entries=I.Unify(config.shared,config.profiles);if not I.ValidEntries(entries)then return end
    return {format=2,module="raidBuffs",scope="all",entries=entries}
end
function M:ExportRaidBuffSharing()
    self:SaveRaidBuffMonitorClass();local entries={}
    for _,entry in ipairs(self.db.raidBuffsShared or {})do
        local copy=M.Copy(entry);copy.classes=I.ClassMask(entry);entries[#entries+1]=copy
    end
    return {format=2,module="raidBuffs",scope="all",entries=entries}
end
function M:ApplyRaidBuffSharing(config)
    local group=self.byID.raidBuffs;local entries
    if config.scope=="all"then entries=M.Copy(config.entries)
    else
        local result={}
        for _,entry in ipairs(group.raidBuffs)do
            local copy=M.Copy(entry);local was=I.ForClass(copy,config.class);copy.classes=I.ClassMask(copy)
            local universal=true;for _,class in ipairs(I.classes)do if not copy.classes[class[1]]then universal=false;break end end
            if not(config.legacy and universal)then copy.classes[config.class]=nil end
            local enabled=false;for _,state in pairs(copy.classes)do if state then enabled=true;break end end
            if not was or enabled then result[#result+1]=copy end
        end
        I.AddClassEntries(result,config.entries,config.class);entries=result
    end
    if not I.ValidEntries(entries)then return false,"配置字符串无效或已损坏，请检查是否完整复制。"end
    group.raidBuffs=entries
    self:EnsureRaidBuffMonitor(self.db.design);self:Commit();return true
end
function I.ResolveValue(value)
    value=S.Input(value)
    local name,id,icon,ids,revision=I.ResolveName(value)
    return {value=value,name=name or value,id=tonumber(value)or id,icon=I.Readable(icon)and icon or nil,ids=ids,revision=revision}
end
function I.Options(entry)
    if entry.type=="weaponAura"then return M.WeaponEnhancements.AuraOptions(entry)end
    if I.Kind(entry)~="buff"then return {}end
    local result={}
    for _,value in ipairs({entry.value,entry.alternative or ""})do
        if S.Input(value)~=""then result[#result+1]=I.ResolveValue(value)end
    end
    return result
end
function I.Resolve(entry)
    if I.Kind(entry)~="buff"then return M.WeaponEnhancements.Resolve(entry)end
    local first=I.ResolveValue(entry.value)
    if first.value~=""and first.icon then return first end
    local second=I.ResolveValue(entry.alternative or "")
    return second.icon and second or (first.value~=""and first or second)
end
M.moduleIDs.raidBuffs=true
M:EnsureRaidBuffMonitor(M.defaults);M:EnsureRaidBuffMonitor(M.recordedDefaults)
