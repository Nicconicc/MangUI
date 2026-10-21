local _,M=...
local I={};M.CommonItems=I
local S,O=M.PlayerSkillMonitor,M.PlayerOtherMonitor
I.Safe,I.Number,I.Readable=O.Safe,O.Number,O.Readable
I.types={{name="物品",path="item"},{name="装备",path="equipment"}}
function I.Kind(entry)return entry.type=="equipment"and "equipment"or "item"end
function I.NewEntry()return {type="item",slot=13,value="",createSpell=""}end
function I.ValidEntries(entries)
    if type(entries)~="table"or #entries>4096 then return false end
    for k,entry in pairs(entries)do
        if type(k)~="number"or k%1~=0 or k<1 or k>#entries or type(entry)~="table"then return false end
        if type(entry.value)~="string"or #entry.value>384 or type(entry.createSpell)~="string"or #entry.createSpell>384 then return false end
        if entry.type~=nil and entry.type~="item"and entry.type~="equipment"then return false end
        if entry.slot~=nil and (type(entry.slot)~="number"or entry.slot%1~=0 or entry.slot<1 or entry.slot>19)then return false end
        if entry.classes~=nil then
            if type(entry.classes)~="table"then return false end
            for class,enabled in pairs(entry.classes)do if not S.ValidClass(class)or type(enabled)~="boolean"then return false end end
        end
        for field in pairs(entry)do if field~="value"and field~="createSpell"and field~="type"and field~="slot"and field~="classes"then return false end end
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
    for _,node in ipairs(design and design.nodes or {})do if node.id=="commonItems"then return node end end
end
function I.Entries(group)
    local entries={};local _,class=I.Safe(UnitClass,"player")
    for _,entry in ipairs(group.commonItems or {})do
        if class and (entry.classes==nil or entry.classes[class]==true)and (I.Kind(entry)=="equipment"or entry.value~="")then entries[#entries+1]=entry end
    end
    return entries
end
function I.MoveBounds(group)
    local count=math.max(1,#I.Entries(group))
    return S.RowOffset(group,count),20,math.max(180,count*44+20),112
end
function I.RestorePosition(group,reference)
    local x,y=0,-420
    if reference then local cx,cy=I.MoveBounds(reference);local scale=M:NodeScale(reference);x,y=((reference.x or 0)+cx)*scale,((reference.y or 0)+cy)*scale end
    local cx,cy=I.MoveBounds(group);local scale=math.max(.001,M:NodeScale(group));group.x,group.y=x/scale-cx,y/scale-cy
end
function M:EnsureCommonItems(design)
    if not design or not design.nodes then return end
    local group=I.Group(design)
    if not group then
        local source
        for _,node in ipairs(design.nodes)do if node.id=="playerSkillMonitor"then source=node;break end end
        source=source or S and self.defaults and self.defaults.nodes[1]
        group={id="commonItems",label="常用物品监控",kind="group",compound="commonItems",scope="player",unit="player",
            width=2,height=2,scale=source and source.scale or 1,scaleReference=source and (source.scaleReference or source.scale)or 1,
            point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=355,hideWithoutTarget=false,growthDirection="CENTER",
            commonItems={I.NewEntry()},classItems={}}
        I.RestorePosition(group);design.nodes[#design.nodes+1]=group
    end
    if not I.ValidEntries(group.commonItems)then group.commonItems={}end
    if not I.ValidEntries(group.classItems)then group.classItems={}end
    if group.hideWithoutTarget==nil then group.hideWithoutTarget=false end
    group.growthDirection=S.Direction(group)
    for _,node in ipairs(design.nodes)do if node.id=="commonItemsIcons"then return end end
    design.nodes[#design.nodes+1]={id="commonItemsIcons",label="常用物品监控",kind="commonitems",parent="commonItems",
        internal=true,locked=true,scope="player",unit="player",x=0,y=0,width=40,height=66,autoWidth=true,
        scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=356}
end
local function Class()local _,class=I.Safe(UnitClass,"player");return S.ValidClass(class)and class end
function M:SaveCommonItemsClass()M.MonitorSharing.SaveUnified("commonItems")end
function M:BindCommonItemsClass()M.MonitorSharing.BindUnified("commonItems")end
function M:ImportCommonItems(config)M.MonitorSharing.ImportUnified("commonItems",config)end
local function ItemID(value)
    local id=tonumber(value)or (type(value)=="string"and tonumber(value:match("item:(%d+)")))
    return id and id>0 and id%1==0 and id<=1000000000 and id or nil
end
local function ItemCache()
    if M.db then
        if type(M.db.commonItemMetadata)~="table"then M.db.commonItemMetadata={}end
        return M.db.commonItemMetadata
    end
    I.itemMetadata=I.itemMetadata or {};return I.itemMetadata
end
local function CacheKey(value)return tostring(I.Safe(GetLocale)or "")..":"..value end
local function KnownIcon(icon)return I.Readable(icon)and icon~=134400 and (type(icon)=="number"or type(icon)=="string")end
-- Class-created items must resolve on characters that cannot create them.
-- Localized item-name aliases are limited to known Classic conjured items;
-- artwork and full item metadata still come from the current client by ID.
local conjuredItems={
    zhCN={
        ["初级灵魂石"]={5232},
        ["治疗石"]={5509,19008,19009},
        ["强效治疗石"]={5510,19010,19011},
        ["次级治疗石"]={5511,19006,19007},
        ["初级治疗石"]={5512,19004,19005},
        ["法力翡翠"]={5513},
        ["法力玛瑙"]={5514},
        ["法力黄水晶"]={8007},
        ["法力红宝石"]={8008},
        ["特效治疗石"]={9421,19012,19013},
        ["次级灵魂石"]={16892},
        ["灵魂石"]={16893},
        ["强效灵魂石"]={16895},
        ["特效灵魂石"]={16896},
        ["法力刚玉"]={22044},
        ["极效治疗石"]={22103,22104,22105},
        ["极效灵魂石"]={22116},
        ["法力青玉"]={33312},
        ["恶魔治疗石"]={36889,36890,36891},
        ["邪能治疗石"]={36892,36893,36894},
        ["恶魔灵魂石"]={36895},
        ["特效火焰石"]={40773},
        ["火焰石"]={41169},
        ["次级火焰石"]={41170},
        ["强效火焰石"]={41171},
        ["极效火焰石"]={41172},
        ["邪能火焰石"]={41173},
        ["完美火焰石"]={41174},
        ["法术石"]={41191},
        ["特效法术石"]={41192,41194},
        ["极效法术石"]={41193},
        ["恶魔法术石"]={41195},
        ["完美法术石"]={41196},
    },
    zhTW={
        ["初級靈魂石"]={5232},
        ["治療石"]={5509,19008,19009},
        ["強效治療石"]={5510,19010,19011},
        ["次級治療石"]={5511,19006,19007},
        ["初級治療石"]={5512,19004,19005},
        ["法力碧玉"]={5513},
        ["法力瑪瑙"]={5514},
        ["法力黃水晶"]={8007},
        ["法力紅寶石"]={8008},
        ["極效治療石"]={9421,19012,19013},
        ["次級靈魂石"]={16892},
        ["靈魂石"]={16893},
        ["強效靈魂石"]={16895},
        ["極效靈魂石"]={16896},
        ["法力翡翠"]={22044},
        ["極強效治療石"]={22103,22104,22105},
        ["極強效靈魂石"]={22116},
        ["法力藍寶石"]={33312},
        ["惡魔治療石"]={36889,36890,36891},
        ["魔化治療石"]={36892,36893,36894},
        ["惡魔靈魂石"]={36895},
        ["極強效火焰石"]={40773},
        ["火焰石"]={41169},
        ["次級火焰石"]={41170},
        ["強效火焰石"]={41171},
        ["極效火焰石"]={41172},
        ["魔化火焰石"]={41173},
        ["極大火焰石"]={41174},
        ["法術石"]={41191},
        ["強效法術石"]={41192},
        ["極效法術石"]={41193},
        ["極強效法術石"]={41194},
        ["惡魔法術石"]={41195},
        ["極大法術石"]={41196},
    },
    enUS={
        ["Minor Soulstone"]={5232},
        ["Healthstone"]={5509,19008,19009},
        ["Greater Healthstone"]={5510,19010,19011},
        ["Lesser Healthstone"]={5511,19006,19007},
        ["Minor Healthstone"]={5512,19004,19005},
        ["Mana Jade"]={5513},
        ["Mana Agate"]={5514},
        ["Mana Citrine"]={8007},
        ["Mana Ruby"]={8008},
        ["Major Healthstone"]={9421,19012,19013},
        ["Lesser Soulstone"]={16892},
        ["Soulstone"]={16893},
        ["Greater Soulstone"]={16895},
        ["Major Soulstone"]={16896},
        ["Mana Emerald"]={22044},
        ["Master Healthstone"]={22103,22104,22105},
        ["Master Soulstone"]={22116},
        ["Mana Sapphire"]={33312},
        ["Demonic Healthstone"]={36889,36890,36891},
        ["Fel Healthstone"]={36892,36893,36894},
        ["Demonic Soulstone"]={36895},
        ["Master Firestone"]={40773},
        ["Firestone"]={41169},
        ["Lesser Firestone"]={41170},
        ["Greater Firestone"]={41171},
        ["Major Firestone"]={41172},
        ["Fel Firestone"]={41173},
        ["Grand Firestone"]={41174},
        ["Spellstone"]={41191},
        ["Greater Spellstone"]={41192},
        ["Major Spellstone"]={41193},
        ["Master Spellstone"]={41194},
        ["Demonic Spellstone"]={41195},
        ["Grand Spellstone"]={41196},
    },
}
local function NameCandidates(value)
    local locale=I.Safe(GetLocale)or "enUS"
    if locale=="enGB"then locale="enUS"end
    local names=conjuredItems[locale]
    return names and names[value]
end
function I.Resolve(entry)
    if I.Kind(entry)=="equipment"then
        local slot=entry.slot or 13;local id,name,icon=O.Item(slot)
        return {id=id,name=name or (id and tostring(id)or M:T("未装备")),icon=I.Readable(icon)and icon or nil,
            equippable=true,slot=slot,use=tostring(slot)}
    end
    local value=S.Input(entry.value);local cache=ItemCache();local cached=cache[CacheKey(value)]
    if type(cached)~="table"then cached=nil end
    local candidates=not ItemID(value)and NameCandidates(value)
    local input=ItemID(value)or cached and ItemID(cached.id)or (candidates and candidates[#candidates])or value
    local name,link,_,_,_,_,_,_,equip,icon=I.Safe(C_Item and C_Item.GetItemInfo or GetItemInfo,input)
    local id=ItemID(link)or ItemID(input)
    local instant,_,_,instantEquip,instantIcon=I.Safe(C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant,input)
    id=I.Number(instant)or id;equip=equip or instantEquip;icon=icon or instantIcon
    -- Item names may not be cached yet. Search carried items and equipment.
    if not id or not ItemID(value)then
        local carried
        for bag=0,4 do
            local size=I.Number(I.Safe(C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots,bag))or 0
            for slot=1,size do
                local itemLink=I.Safe(C_Container and C_Container.GetContainerItemLink or GetContainerItemLink,bag,slot)
                if I.Readable(itemLink)and type(itemLink)=="string"and itemLink:match("%[(.-)%]")==value then carried=ItemID(itemLink);break end
            end
            if carried then break end
        end
        if carried then
            id=carried
            name,link,_,_,_,_,_,_,equip,icon=I.Safe(C_Item and C_Item.GetItemInfo or GetItemInfo,id)
            local _,_,_,carriedEquip,carriedIcon=I.Safe(C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant,id)
            equip=equip or carriedEquip;icon=icon or carriedIcon
        end
    end
    local equippedSlot
    for slot=1,19 do
        local equipped=I.Number(I.Safe(GetInventoryItemID,"player",slot))
        if equipped and ((id and equipped==id)or (not id and I.Safe(C_Item and C_Item.GetItemInfo or GetItemInfo,equipped)==value))then id=equipped;equippedSlot=slot;break end
    end
    if not icon and id then icon=I.Safe(C_Item and C_Item.GetItemIconByID or GetItemIcon,id)end
    if id and (not name or not KnownIcon(icon))then
        I.requestedItems=I.requestedItems or {}
        if (I.Number(I.requestedItems[id])or 0)<=GetTime()and C_Item and C_Item.RequestLoadItemDataByID then
            I.requestedItems[id]=GetTime()+5;I.Safe(C_Item.RequestLoadItemDataByID,id)
        end
    end
    -- A verified alias supplies a display name while native item data loads.
    -- It must not override an already-resolved native name or a carried ID.
    if candidates and not name then name=value end
    if KnownIcon(icon)and id and name then
        local metadata={id=id,name=name,icon=icon}
        cache[CacheKey(value)]=metadata;cache[CacheKey(name)]=metadata;cache[CacheKey(tostring(id))]=metadata
    elseif cached then
        id=id or ItemID(cached.id);name=name or cached.name
        if not KnownIcon(icon)and KnownIcon(cached.icon)then icon=cached.icon end
    end
    if not KnownIcon(icon)and M.PetBuffs then
        local _,_,spellIcon=M.PetBuffs.SpellInfo(S.Input(entry.createSpell or ""))
        if KnownIcon(spellIcon)then icon=spellIcon end
    end
    -- Titan uses a nonempty NON_EQUIP marker for consumables. It is not
    -- an equipment slot and must not disable their secure item action.
    local equippable=equippedSlot~=nil or (type(equip)=="string"and equip~=""
        and equip~="INVTYPE_NON_EQUIP_IGNORE"and equip~="INVTYPE_NON_EQUIP")
    if not equippable then equippable=I.Safe(C_Item and C_Item.IsEquippableItem or IsEquippableItem,id or input)==true end
    -- Never bind a gear item by name/ID: the native action would equip it.
    local use=equippedSlot and tostring(equippedSlot)or (not equippable and (name or equip~=nil)and id and "item:"..id or nil)
    return {id=id,name=name or value,icon=I.Readable(icon)and icon or nil,equippable=equippable,slot=equippedSlot,use=use}
end
M.moduleIDs.commonItems=true
M:EnsureCommonItems(M.defaults);M:EnsureCommonItems(M.recordedDefaults)

