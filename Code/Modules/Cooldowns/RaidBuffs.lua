local _,M=...
local I={};M.RaidBuffMonitor=I
local S,O=M.PlayerSkillMonitor,M.PlayerOtherMonitor
I.Safe,I.Number,I.Readable=O.Safe,O.Number,O.Readable
function I.NewEntry()return {value="",alternative=""}end
function I.ValidEntries(entries)
    if type(entries)~="table"or #entries>256 then return false end
    for k,entry in pairs(entries)do
        if type(k)~="number"or k%1~=0 or k<1 or k>#entries or type(entry)~="table"then return false end
        if type(entry.value)~="string"or #entry.value>384 then return false end
        if entry.alternative~=nil and (type(entry.alternative)~="string"or #entry.alternative>384)then return false end
        for field in pairs(entry)do if field~="value"and field~="alternative"then return false end end
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
function I.Entries(group)
    local entries={}
    for _,list in ipairs({group.raidBuffs or {},group.classBuffs or {}})do
        for _,entry in ipairs(list)do if entry.value~=""or (entry.alternative or "")~=""then entries[#entries+1]=entry end end
    end
    return entries
end
function I.MoveBounds(group)
    local count=math.max(1,#I.Entries(group))
    return S.RowOffset(group,count),20,math.max(180,count*44+20),112
end
function I.RestorePosition(group,reference)
    local x,y=0,-400
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
            raidBuffs={I.NewEntry()},classBuffs={I.NewEntry()}}
        I.RestorePosition(group);design.nodes[#design.nodes+1]=group
    end
    if not I.ValidEntries(group.raidBuffs)then group.raidBuffs={}end
    if not I.ValidEntries(group.classBuffs)then group.classBuffs={}end
    if group.hideWithoutTarget==nil then group.hideWithoutTarget=false end
    if group.raidOnly==nil then group.raidOnly=true end
    group.growthDirection=S.Direction(group)
    for _,node in ipairs(design.nodes)do if node.id=="raidBuffsIcons"then return end end
    design.nodes[#design.nodes+1]={id="raidBuffsIcons",label="玩家常驻团队增益监控",kind="raidbuffs",parent="raidBuffs",
        internal=true,locked=true,scope="player",unit="player",x=0,y=0,width=40,height=66,autoWidth=true,
        scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=351}
end
local function Class()local _,class=I.Safe(UnitClass,"player");return S.ValidClass(class)and class end
function M:SaveRaidBuffMonitorClass()
    local db=self.db;local group=db and I.Group(db.design);local class=Class()
    if not group or not class or db.raidBuffsClass~=class then return end
    if I.ValidEntries(group.raidBuffs)then db.raidBuffsShared=M.Copy(group.raidBuffs)end
    if I.ValidEntries(group.classBuffs)then
        db.raidBuffsByClass=db.raidBuffsByClass or {};db.raidBuffsByClass[class]=M.Copy(group.classBuffs)
    end
end
function M:BindRaidBuffMonitorClass()
    local db=self.db;local group=I.Group(db.design);local class=Class();if not group or not class then return end
    if not I.ValidProfiles(db.raidBuffsByClass)then db.raidBuffsByClass={}end
    if not I.ValidEntries(db.raidBuffsShared)then db.raidBuffsShared=M.Copy(group.raidBuffs)end
    local previous=db.raidBuffsClass
    if S.ValidClass(previous)then db.raidBuffsByClass[previous]=M.Copy(group.classBuffs)
    elseif db.raidBuffsByClass[class]==nil then db.raidBuffsByClass[class]=M.Copy(group.classBuffs)end
    group.raidBuffs=M.Copy(db.raidBuffsShared);group.classBuffs=M.Copy(db.raidBuffsByClass[class]or {I.NewEntry()})
    db.raidBuffsClass=class;db.raidBuffsByClass[class]=M.Copy(group.classBuffs)
end
function M:ImportRaidBuffMonitor(config)
    local group=I.Group(self.db.design)
    self.db.raidBuffsShared=M.Copy(config.raidBuffsShared or group.raidBuffs)
    if config.raidBuffsByClass then
        self.db.raidBuffsByClass=self.db.raidBuffsByClass or {}
        for class,entries in pairs(config.raidBuffsByClass)do self.db.raidBuffsByClass[class]=M.Copy(entries)end
        self.db.raidBuffsClass=config.raidBuffsClass
    else self.db.raidBuffsClass=Class()end
    self:BindRaidBuffMonitorClass()
end
function I.ResolveValue(value)
    value=S.Input(value)
    local name,id,icon,ids,revision=I.ResolveName(value)
    return {value=value,name=name or value,id=tonumber(value)or id,icon=I.Readable(icon)and icon or nil,ids=ids,revision=revision}
end
function I.Options(entry)
    local result={}
    for _,value in ipairs({entry.value,entry.alternative or ""})do
        if S.Input(value)~=""then result[#result+1]=I.ResolveValue(value)end
    end
    return result
end
function I.Resolve(entry)
    local first=I.ResolveValue(entry.value)
    if first.value~=""and first.icon then return first end
    local second=I.ResolveValue(entry.alternative or "")
    return second.icon and second or (first.value~=""and first or second)
end
M.moduleIDs.raidBuffs=true
M:EnsureRaidBuffMonitor(M.defaults);M:EnsureRaidBuffMonitor(M.recordedDefaults)
