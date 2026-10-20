local _,M=...
local I,S,O={},M.PlayerSkillMonitor,M.PlayerOtherMonitor
M.ReceivedBuffs=I
I.Safe,I.Number,I.Readable=O.Safe,O.Number,O.Readable
I.Sounds,I.Play=O.Sounds,O.Play
function I.NewEntry()return {value="",soundEnabled=false,sound="kit:8960",soundPath="",soundID=""}end
function I.ValidEntries(entries)
    if type(entries)~="table"or #entries>256 then return false end
    for key,entry in pairs(entries)do
        if type(key)~="number"or key%1~=0 or key<1 or key>#entries or type(entry)~="table"then return false end
        if type(entry.value)~="string"or #entry.value>384 then return false end
        if entry.soundEnabled~=nil and type(entry.soundEnabled)~="boolean"then return false end
        for _,field in ipairs({"sound","soundPath","soundID"})do
            if entry[field]~=nil and (type(entry[field])~="string"or #entry[field]>1024)then return false end
        end
        for field in pairs(entry)do
            if field~="value"and field~="soundEnabled"and field~="sound"and field~="soundPath"and field~="soundID"then return false end
        end
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
    for _,node in ipairs(design and design.nodes or {})do if node.id=="receivedBuffs"then return node end end
end
function I.Entries(group)
    local result={};for _,entry in ipairs(group.monitors or {})do if entry.value~=""then result[#result+1]=entry end end;return result
end
function I.MoveBounds(group)
    local count=math.max(1,#I.Entries(group));return S.RowOffset(group,count),20,math.max(180,count*44+20),112
end
function I.RestorePosition(group,reference)
    local x,y=240,-120
    if reference then local cx,cy=I.MoveBounds(reference);local scale=M:NodeScale(reference);x,y=((reference.x or 0)+cx)*scale,((reference.y or 0)+cy)*scale end
    local cx,cy=I.MoveBounds(group);local scale=math.max(.001,M:NodeScale(group));group.x,group.y=x/scale-cx,y/scale-cy
end
function M:EnsureReceivedBuffs(design)
    if not design or not design.nodes then return end
    local group=I.Group(design)
    if not group then
        local source;for _,node in ipairs(design.nodes)do if node.id=="playerSkillMonitor"then source=node;break end end
        group={id="receivedBuffs",label="玩家获取他人增益监控",kind="group",compound="receivedBuffs",scope="player",unit="player",
            width=2,height=2,scale=source and source.scale or 1,scaleReference=source and (source.scaleReference or source.scale)or 1,
            point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=348,hideWithoutTarget=false,growthDirection="CENTER",monitors={I.NewEntry()}}
        I.RestorePosition(group);design.nodes[#design.nodes+1]=group
    end
    if not I.ValidEntries(group.monitors)then group.monitors={I.NewEntry()}end
    if group.hideWithoutTarget==nil then group.hideWithoutTarget=false end
    group.growthDirection=S.Direction(group)
    for _,entry in ipairs(group.monitors)do
        entry.value=S.Input(entry.value);entry.soundEnabled=entry.soundEnabled==true
        entry.sound=entry.sound or "kit:8960";entry.soundPath=entry.soundPath or "";entry.soundID=entry.soundID or ""
    end
    for _,node in ipairs(design.nodes)do if node.id=="receivedBuffsIcons"then return end end
    design.nodes[#design.nodes+1]={id="receivedBuffsIcons",label="玩家获取他人增益监控",kind="receivedbuffs",parent=group.id,
        internal=true,locked=true,scope="player",unit="player",x=0,y=0,width=40,height=66,autoWidth=true,
        scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=349}
end
function M:SaveReceivedBuffs()
    local db=self.db;local group=db and I.Group(db.design)
    if group and I.ValidEntries(group.monitors)then db.receivedBuffsShared=M.Copy(group.monitors)end
end
function M:BindReceivedBuffs()
    local db=self.db;local group=db and I.Group(db.design);if not group then return end
    -- Upgrade the last displayed list to shared storage. Keep legacy class
    -- lists in saved variables for recovery without switching to them.
    if not I.ValidEntries(db.receivedBuffsShared)then db.receivedBuffsShared=M.Copy(group.monitors)end
    group.monitors=M.Copy(db.receivedBuffsShared)
end
function M:ImportReceivedBuffs(config)
    local group=I.Group(self.db.design)
    self.db.receivedBuffsShared=M.Copy(config.receivedBuffsShared or group.monitors)
    self:BindReceivedBuffs()
end
M.moduleIDs.receivedBuffs=true
M:EnsureReceivedBuffs(M.defaults);M:EnsureReceivedBuffs(M.recordedDefaults)
