local _,M=...
local O={};M.PlayerOtherMonitor=O
local S=M.PlayerSkillMonitor
O.types={{name="玩家Buff已找到",path="buffFound"},{name="玩家Buff未找到",path="buffMissing"},
    {name="目标Debuff已找到",path="debuffFound"},{name="目标Debuff未找到",path="debuffMissing"},{name="装备触发",path="equipment"}}
O.slots={{name="头部",path="1"},{name="颈部",path="2"},{name="肩部",path="3"},{name="衬衣",path="4"},
    {name="胸部",path="5"},{name="腰部",path="6"},{name="腿部",path="7"},{name="脚部",path="8"},{name="手腕",path="9"},
    {name="手套",path="10"},{name="戒指1",path="11"},{name="戒指2",path="12"},{name="饰品1",path="13"},{name="饰品2",path="14"},
    {name="背部",path="15"},{name="主手",path="16"},{name="副手",path="17"},{name="远程／圣物",path="18"},{name="战袍",path="19"}}
function O.Readable(v)return not issecretvalue or not issecretvalue(v)end
function O.Number(v)return O.Readable(v)and type(v)=="number"and v or nil end
function O.Safe(fn,...)
    if not fn then return end
    local ok,a,b,c,d,e,f,g,h,i,j=pcall(fn,...);if ok then return a,b,c,d,e,f,g,h,i,j end
end
function O.NewEntry()
    return {type="buffFound",value="",slot=13,glow=false,glowColor={1,.82,0,1},soundEnabled=false,sound="kit:8960",soundPath="",soundID=""}
end
function O.NewEquipmentEntry()local e=O.NewEntry();e.type="equipment";return e end
local function Color(c)
    if type(c)~="table"then return false end
    for i=1,4 do if type(c[i])~="number"or c[i]~=c[i]or c[i]<0 or c[i]>1 then return false end end
    for k in pairs(c)do if type(k)~="number"or k%1~=0 or k<1 or k>4 then return false end end
    return true
end
local validTypes={buffFound=true,buffMissing=true,debuffFound=true,debuffMissing=true,equipment=true}
function O.ValidEntries(entries)
    if type(entries)~="table"or #entries>512 then return false end
    for k,e in pairs(entries)do
        if type(k)~="number"or k%1~=0 or k<1 or k>#entries or type(e)~="table"or not validTypes[e.type]then return false end
        if type(e.value)~="string"or #e.value>384 then return false end
        if e.slot~=nil and (type(e.slot)~="number"or e.slot%1~=0 or e.slot<1 or e.slot>19)then return false end
        for _,field in ipairs({"glow","soundEnabled"})do if e[field]~=nil and type(e[field])~="boolean"then return false end end
        if e.glowColor~=nil and not Color(e.glowColor)then return false end
        for _,field in ipairs({"sound","soundPath","soundID"})do if e[field]~=nil and (type(e[field])~="string"or #e[field]>1024)then return false end end
        for field in pairs(e)do
            if field~="type"and field~="value"and field~="slot"and field~="glow"and field~="glowColor"and field~="soundEnabled"
                and field~="sound"and field~="soundPath"and field~="soundID"then return false end
        end
    end
    return true
end
function O.ValidProfiles(profiles)
    if type(profiles)~="table"then return false end
    for class,entries in pairs(profiles)do if not S.ValidClass(class)or not O.ValidEntries(entries)then return false end end
    return true
end
function O.ValidEquipmentEntries(entries)
    if not O.ValidEntries(entries)then return false end
    for _,entry in ipairs(entries)do if entry.type~="equipment"then return false end end
    return true
end
-- Upgrade the former account-wide equipment list into the owning class once.
-- Other classes retain their own lists and never inherit these rows on login.
function O.MigrateEquipment(db)
    local equipment=db.otherMonitorEquipmentEntries
    if equipment==nil then return end
    if not O.ValidEquipmentEntries(equipment)then db.otherMonitorEquipmentEntries=nil;return end
    local group=O.Group(db.design);if not group then return end
    local entries=group.otherMonitors or {};local slots={}
    for _,entry in ipairs(entries)do if entry.type=="equipment"then slots[entry.slot or 13]=true end end
    for _,entry in ipairs(equipment)do
        if not slots[entry.slot or 13]then entries[#entries+1]=M.Copy(entry);slots[entry.slot or 13]=true end
    end
    group.otherMonitors=entries
    local _,current=O.Safe(UnitClass,"player")
    local owner=S.ValidClass(db.playerOtherMonitorClass)and db.playerOtherMonitorClass or current
    if S.ValidClass(owner)then
        db.playerOtherMonitorsByClass=db.playerOtherMonitorsByClass or {}
        db.playerOtherMonitorsByClass[owner]=M.Copy(entries)
    end
    db.otherMonitorEquipmentEntries=nil
end
function O.NewOverride()return {itemID="",spellID="",cooldown=""}end
function O.ValidOverrides(rows)
    if type(rows)~="table"or #rows>512 then return false end
    for k,row in pairs(rows)do
        if type(k)~="number"or k%1~=0 or k<1 or k>#rows or type(row)~="table"then return false end
        for _,field in ipairs({"itemID","spellID","cooldown"})do if type(row[field])~="string"or #row[field]>256 then return false end end
        for field in pairs(row)do if field~="itemID"and field~="spellID"and field~="cooldown"then return false end end
    end
    return true
end
function O.Group(design)
    for _,n in ipairs(design and design.nodes or {})do if n.id=="playerOtherMonitor"then return n end end
end
function M:EnsurePlayerOtherMonitor(design)
    if not design or not design.nodes then return end
    local group=O.Group(design)
    if not group then
        local source
        for _,n in ipairs(M.defaults.nodes)do if n.id=="playerSkillMonitor"then source=n end end
        group=M.Copy(source);group.id="playerOtherMonitor";group.label="玩家其他监控";group.compound="playerOtherMonitor"
        group.monitors=nil;group.otherMonitors={O.NewEntry()};group.layer=345
        for _,n in ipairs(design.nodes)do
            if n.id=="playerSkillMonitor"then group.scale=n.scale;group.scaleReference=n.scale;break end
        end
        O.RestorePosition(group)
        design.nodes[#design.nodes+1]=group
    end
    if not O.ValidEntries(group.otherMonitors)then group.otherMonitors={O.NewEntry()}end
    if group.hideWithoutTarget==nil then group.hideWithoutTarget=false end
    group.growthDirection=S.Direction(group)
    for _,e in ipairs(group.otherMonitors)do
        e.value=S.Input(e.value);e.slot=e.slot or 13;e.glow=e.glow==true;e.glowColor=e.glowColor or {1,.82,0,1}
        e.soundEnabled=e.soundEnabled==true;e.sound=e.sound or "kit:8960";e.soundPath=e.soundPath or "";e.soundID=e.soundID or ""
    end
    for _,n in ipairs(design.nodes)do if n.id=="playerOtherMonitorIcons"then return end end
    design.nodes[#design.nodes+1]={id="playerOtherMonitorIcons",label="玩家其他监控",kind="othermonitor",parent=group.id,
        internal=true,locked=true,scope="player",unit="player",x=0,y=0,width=216,height=66,autoWidth=true,
        scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=346}
end
M.moduleIDs.playerOtherMonitor=true
local function CurrentClass()local _,class=O.Safe(UnitClass,"player");return S.ValidClass(class)and class end
function M:SavePlayerOtherMonitorClass()
    local db=self.db;local class=CurrentClass();local group=db and O.Group(db.design)
    if group and class and db.playerOtherMonitorClass==class and O.ValidEntries(group.otherMonitors)then
        db.playerOtherMonitorsByClass=db.playerOtherMonitorsByClass or {};db.playerOtherMonitorsByClass[class]=M.Copy(group.otherMonitors)
    end
end
function M:BindPlayerOtherMonitorClass()
    local db=self.db;local class=CurrentClass();local group=O.Group(db.design);if not class or not group then return end
    if not O.ValidProfiles(db.playerOtherMonitorsByClass)then db.playerOtherMonitorsByClass={}end
    O.MigrateEquipment(db)
    local profiles=db.playerOtherMonitorsByClass;local previous=db.playerOtherMonitorClass
    if S.ValidClass(previous)and O.ValidEntries(group.otherMonitors)then profiles[previous]=M.Copy(group.otherMonitors)
    elseif profiles[class]==nil then profiles[class]=M.Copy(group.otherMonitors)end
    group.otherMonitors=M.Copy(profiles[class]or {O.NewEntry()});self:EnsurePlayerOtherMonitor(db.design)
    db.playerOtherMonitorClass=class;profiles[class]=M.Copy(group.otherMonitors)
    if not O.ValidOverrides(db.otherMonitorEquipmentOverrides)then db.otherMonitorEquipmentOverrides={O.NewOverride()}end
    if type(db.otherMonitorEquipmentTimers)~="table"then db.otherMonitorEquipmentTimers={}end
    local clock=O.Safe(time)
    if clock then for key,stamp in pairs(db.otherMonitorEquipmentTimers)do if type(key)~="string"or not O.Number(stamp)or stamp<=clock then db.otherMonitorEquipmentTimers[key]=nil end end end
end
function M:ImportPlayerOtherMonitorClasses(config)
    if config.otherMonitorEquipmentEntries then self.db.otherMonitorEquipmentEntries=M.Copy(config.otherMonitorEquipmentEntries)end
    if config.playerOtherMonitorsByClass then
        self.db.playerOtherMonitorsByClass=self.db.playerOtherMonitorsByClass or {}
        for class,entries in pairs(config.playerOtherMonitorsByClass)do self.db.playerOtherMonitorsByClass[class]=M.Copy(entries)end
        self.db.playerOtherMonitorClass=config.playerOtherMonitorClass;self:BindPlayerOtherMonitorClass()
    else self.db.playerOtherMonitorClass=CurrentClass();self:SavePlayerOtherMonitorClass()end
    if config.otherMonitorEquipmentOverrides then self.db.otherMonitorEquipmentOverrides=M.Copy(config.otherMonitorEquipmentOverrides)end
    O.MigrateEquipment(self.db)
end
function O.Entries(group)
    local entries={}
    for _,entry in ipairs(group.otherMonitors or {})do
        if entry.type=="equipment"then
            local item=O.Effects(entry.slot or 13)
            if item.id and next(item.effects)then entries[#entries+1]=entry end
        elseif entry.value~=""then entries[#entries+1]=entry end
    end
    return entries
end
function O.MoveBounds(group)
    local count=#O.Entries(group);if count==0 then count=3 end
    return S.RowOffset(group,count),20,math.max(180,count*44+20),112
end
function O.RestorePosition(group,reference)
    local x,y=-310,-190
    if reference then local cx,cy=O.MoveBounds(reference);local scale=M:NodeScale(reference);x,y=((reference.x or 0)+cx)*scale,((reference.y or 0)+cy)*scale end
    local cx,cy=O.MoveBounds(group);local scale=math.max(.001,M:NodeScale(group));group.x,group.y=x/scale-cx,y/scale-cy
end
function M:UpgradePlayerOtherMonitorDefaults(db)
    if db.playerOtherMonitorPositionRevision~=1 then
        local defaults=O.Group(db.moduleDefaults)
        if defaults then O.RestorePosition(defaults)end
        db.playerOtherMonitorPositionRevision=1
    end
    if db.playerOtherMonitorSizeRevision==1 then return end
    local skill
    for _,n in ipairs(db.design.nodes)do if n.id=="playerSkillMonitor"then skill=n;break end end
    local baseline=O.Group(self.defaults)
    if skill and baseline then
        -- Correct the untouched 1.0.529 size; keep a user's custom size intact.
        for _,design in ipairs({db.design,db.moduleDefaults})do
            local group=O.Group(design)
            if group and group.scale==baseline.scale and group.scaleReference==baseline.scaleReference then
                local cx,cy=O.MoveBounds(group);local previous=self:NodeScale(group)
                local x,y=((group.x or 0)+cx)*previous,((group.y or 0)+cy)*previous
                group.scale=skill.scale;group.scaleReference=skill.scale
                local scale=math.max(.001,self:NodeScale(group));group.x,group.y=x/scale-cx,y/scale-cy
            end
        end
    end
    db.playerOtherMonitorSizeRevision=1
end
function O.Item(slot)
    local id=O.Number(O.Safe(GetInventoryItemID,"player",slot));local link=O.Safe(GetInventoryItemLink,"player",slot)
    local name,_,_,_,_,_,_,_,_,icon
    if id then
        name,_,_,_,_,_,_,_,_,icon=O.Safe(C_Item and C_Item.GetItemInfo or GetItemInfo,id)
        icon=icon or O.Safe(GetInventoryItemTexture,"player",slot)
    end
    local enchant,gem
    if O.Readable(link)and type(link)=="string"then
        -- Empty fields are valid in item links. An unsocketed weapon can have
        -- an enchant followed by blank gem fields; parse each independently.
        enchant,gem=link:match("item:%d+:([^:|]*):?([^:|]*)")
        enchant,gem=tonumber(enchant),tonumber(gem)
    end
    return id,name,icon,enchant,gem
end
function O.Effects(slot)
    local id,name,icon,enchant,gem=O.Item(slot);local result={id=id,name=name,icon=icon,slot=slot,enchant=enchant,gem=gem,effects={}}
    if not id then return result end
    local function Cooldown(value,listed)
        -- Only listed trinkets with unspecified ICDs default to 45s.
        -- Unlisted items and explicit zero keep their existing behavior.
        if value==nil and listed and (slot==13 or slot==14)then return 45 end
        return value
    end
    for i=#(M.db.otherMonitorEquipmentOverrides or {}),1,-1 do
        local row=M.db.otherMonitorEquipmentOverrides[i]
        if tonumber(row.itemID)==id then
            result.overridden=true
            for value in row.spellID:gmatch("%d+")do
                local spell=tonumber(value);if spell>0 and spell%1==0 then result.effects[spell]={cooldown=Cooldown((tonumber(row.cooldown)and tonumber(row.cooldown)>=0 and tonumber(row.cooldown)<=604800)and tonumber(row.cooldown)or nil,true)}end
            end
            return result
        end
    end
    local data=M.EquipmentEffectData
    local itemEffect=data.Item(id,M.Compat.interface)
    local listed=itemEffect~=nil or data.extra[id]~=nil
    local function Add(value)
        if type(value)=="table"then for _,spell in ipairs(value)do Add(spell)end
        elseif type(value)=="number"and value>0 and value%1==0 and value<=1000000000 then
            result.effects[value]={cooldown=Cooldown(data.noCooldown[value]and 0 or data.cooldowns[value],listed)}
        end
    end
    Add(itemEffect);Add(data.enchants[enchant]);Add(data.gems[gem]);Add(data.extra[id])
    if next(result.effects)==nil then
        local _,spell=O.Safe(C_Item and C_Item.GetItemSpell or GetItemSpell,id)
        if O.Number(spell)then Add(spell)end
    end
    return result
end
function O.Sounds()
    local choices={{name="根据ID选择音效",path="id"},{name="自定义",path="custom"},
        {name="就位确认",path="kit:8960"},{name="团队警告",path="kit:8959"},{name="首领警告",path="kit:12197"},{name="闹钟提示1",path="kit:12867"},{name="闹钟提示2",path="kit:12889"},
        {name="进入战场队列",path="kit:8458"},{name="任务提示",path="kit:7355"},{name="装备修理",path="kit:7994"},{name="成就提示",path="kit:13832"}}
    local lsm=LibStub and LibStub("LibSharedMedia-3.0",true)
    if lsm then for _,name in ipairs(lsm:List("sound")or {})do choices[#choices+1]={name=name,path="media:"..name}end end
    return choices
end
function O.Play(entry)
    if not entry or not entry.soundEnabled then return end
    local sound=entry.sound or "kit:8960"
    if sound=="custom"then
        if entry.soundPath~=""then O.Safe(PlaySoundFile,entry.soundPath,"Master")end
    elseif sound=="id"then local id=tonumber(entry.soundID);if id and id>0 then O.Safe(PlaySound,id,"Master")end
    elseif sound:sub(1,4)=="kit:"then O.Safe(PlaySound,tonumber(sound:sub(5)),"Master")
    elseif sound:sub(1,6)=="media:"then
        local lsm=LibStub and LibStub("LibSharedMedia-3.0",true);local path=lsm and lsm:Fetch("sound",sound:sub(7),true)
        if path then O.Safe(PlaySoundFile,path,"Master")end
    end
end
M:EnsurePlayerOtherMonitor(M.defaults);M:EnsurePlayerOtherMonitor(M.recordedDefaults)
