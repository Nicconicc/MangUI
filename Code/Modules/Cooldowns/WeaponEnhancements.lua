local _,M=...
local W,I,S=M.WeaponEnhancements,M.RaidBuffMonitor,M.PlayerSkillMonitor
local Safe,Number,Readable=I.Safe,I.Number,I.Readable
W.types={{name="常驻Buff",path="buff"},{name="职业武器强化",path="classWeapon"},{name="消耗品武器强化",path="consumable"}}
W.slots={{name="主手",path="main"},{name="副手",path="off"},{name="主副手",path="both"},{name="任一武器",path="any"}}
function W.Types()
    local _,class=Safe(UnitClass,"player");local list={}
    for _,choice in ipairs(W.types)do
        if choice.path~="classWeapon"or class=="ROGUE"or class=="SHAMAN"or class=="WARLOCK"or class=="PALADIN"then list[#list+1]=choice end
    end
    return list
end
function W.Family()
    local n=M.Compat.interface or 0
    return n==16001 and 1 or math.floor(n/10000)
end
local function Contains(values,value)for _,v in ipairs(values or {})do if v==value then return true end end end
local function Text(value)return Readable(value)and type(value)=="string"and value or nil end
local function Plain(value)return (Text(value)or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|T.-|t",""):gsub("|A.-|a","")end
local function ItemID(value)return tonumber(value)or tonumber((Text(value)or ""):match("item:(%d+)"))end
function W.Name(d)return M:EffectiveLanguage()=="zhCN"and d.zh or d.en end
function W.ItemInfo(id)
    local name,link,_,ilevel,level,_,_,_,equip,icon=Safe(C_Item and C_Item.GetItemInfo or GetItemInfo,id)
    if not name then
        W.requested=W.requested or {}
        if not W.requested[id]then W.requested[id]=true;Safe(C_Item and C_Item.RequestLoadItemDataByID,id)end
    end
    if not icon then icon=Safe(C_Item and C_Item.GetItemIconByID or GetItemIcon,id)end
    return Text(name),Text(link),Number(ilevel),Number(level),Text(equip),Readable(icon)and icon or nil
end
function W.ItemAvailable(d)
    if d.interfaces then return d.interfaces[M.Compat.interface]==true end
    local family=W.Family()
    if family>=9 then return d.era==family end
    if d.items[1]==211848 or d.items[1]==211845 then
        return family==1 and Safe(C_Seasons and C_Seasons.HasActiveSeason)==true
    end
    return d.era<=math.min(2,family)
end
function W.FindItem(value,partial)
    value=S.Input(value);local id=ItemID(value)
    if id then return W.byItem[id],id end
    local query=value:lower();if query==""then return end
    local candidate,candidateID
    for _,d in ipairs(W.items)do
        local name=W.ItemInfo(d.items[1]);local exact=false;local matches=false
        for _,label in ipairs({d.zh,d.en,name or ""})do
            label=label:lower()
            if label==query then exact=true end
            if partial and label:find(query,1,true)then matches=true end
        end
        if exact then return d,d.items[1]end
        if matches and W.ItemAvailable(d)then
            if candidate then return nil,nil,"ambiguous"end
            candidate,candidateID=d,d.items[1]
        end
    end
    return candidate,candidateID
end
local function Knows(id)
    for _,fn in ipairs({IsPlayerSpell or false,IsSpellKnownOrOverridesKnown or false,IsSpellKnown or false})do
        if fn and Safe(fn,id)==true then return true end
    end
    return false
end
function W.Known(d)
    local _,class=Safe(UnitClass,"player");if class~=d.class then return false end
    local family=W.Family();local forever=M.Compat.interface==16001
    if d.class=="WARLOCK"and family~=3 and not forever then return false end
    if d.class=="PALADIN"and family<11 then return false end
    if d.class=="SHAMAN"and family>=6 and family<=8 then return false end
    if d.key=="earthliving"and family>=6 and family<10 then return false end
    if family>=6 and (d.key=="rockbiter"or d.key=="frostbrand")then return false end
    for index=#d.spells,1,-1 do
        local id=d.spells[index]
        -- Spell 8679 changed from Instant to Wound Poison in MoP.
        if not(d.key=="instant"and family>=5 and id~=315584)and not(d.key=="wound"and family<5 and id==8679)and Knows(id)then return true,id end
    end
    if d.class=="ROGUE"and family<5 and d.level and (family>=3 or Knows(2842))and (Number(Safe(UnitLevel,"player"))or 0)>=d.level then return true end
    return false
end
function W.Resolve(entry)
    if entry.type=="classWeapon"or entry.type=="weaponAura"then
        local d=W.classes[entry.value];if not d then return {supported=false,name=M:T("选择职业武器强化")}end
        local known,id=W.Known(d);id=id or d.spells[1]
        local spell=I.ResolveValue(tostring(id))
        return {supported=known==true,definition=d,id=id,name=W.Name(d),icon=spell.icon or d.icon}
    end
    local d,id=W.FindItem(entry.value)
    if not d then return {supported=false,name=entry.value or "",error=M:T("暂不支持此物品")}end
    local name,link,_,level,_,icon=W.ItemInfo(id)
    local supported=d.interfaces and d.interfaces[M.Compat.interface]==true or not d.interfaces and d.era<=W.Family()
    return {supported=supported,definition=d,itemID=id,name=name or W.Name(d),link=link,icon=icon or d.icon or 134400,requiredLevel=level}
end
function W.ItemChoices(query)
    local choices={};query=S.Input(query or ""):lower()
    for _,d in ipairs(W.items)do if W.ItemAvailable(d)then
        local name,_,_,_,_,icon=W.ItemInfo(d.items[1]);name=name or W.Name(d)
        if query==""or name:lower():find(query,1,true)or d.zh:find(query,1,true)or d.en:lower():find(query,1,true)or Contains(d.items,tonumber(query))then
            choices[#choices+1]={name="|T"..tostring(icon or 134400)..":18|t "..name,path=tostring(d.items[1])}
        end
    end end
    table.sort(choices,function(a,b)return a.name<b.name end);return choices
end
function W.ClassChoices()
    local result={{name="自动（按当前职业推荐）",path="auto"}}
    for key,d in pairs(W.classes)do if W.Known(d)then result[#result+1]={name=W.Name(d),path=key}end end
    table.sort(result,function(a,b)if a.path=="auto"then return true elseif b.path=="auto"then return false else return a.name<b.name end end)
    return result
end
local function Spec()
    local index=Number(Safe(GetSpecialization));local id=index and Number(Safe(GetSpecializationInfo,index))
    if id then return id end
    local best,points=0,-1
    for tab=1,3 do local _,_,count=Safe(GetTalentTabInfo,tab);if Number(count)and count>points then best,points=tab,count end end
    return best
end
function W.Expand(entry)
    local rules={}
    local function Add(key,position)
        local d=W.classes[key];if not d or not W.Known(d)then return end
        if W.Family()>=5 and d.class=="ROGUE"then rules[#rules+1]={type="weaponAura",value=key,alternative="",source=entry};return end
        local location=position or entry.slot or "main"
        if location=="both"then
            rules[#rules+1]={type="classWeapon",value=key,slot="main",source=entry}
            rules[#rules+1]={type="classWeapon",value=key,slot="off",source=entry}
        else rules[#rules+1]={type="classWeapon",value=key,slot=location,source=entry}end
    end
    if entry.type=="classWeapon"then
        if entry.value~="auto"then Add(entry.value);return rules end
        local _,class=Safe(UnitClass,"player")
        if class=="ROGUE"then
            if W.Family()<5 then
                if not Knows(399965)then Add("instant","main");Add(W.Known(W.classes.deadly)and "deadly"or "instant","off")end
            else
                Add(W.Known(W.classes.deadly)and "deadly"or "instant")
                Add(W.Known(W.classes.atrophic)and "atrophic"or "crippling")
            end
        elseif class=="SHAMAN"then
            local spec=Spec()
            if (spec==264 or spec==3)and W.Known(W.classes.earthliving)then Add("earthliving","main")
            elseif (spec==263 or spec==2 or spec==0)and W.Known(W.classes.windfury)then Add("windfury","main");Add("flametongue","off")
            elseif (W.Family()>=3 and W.Family()<=5)or W.Family()>=12 then Add("flametongue","main")end
        elseif class=="WARLOCK"then Add(W.Known(W.classes.spellstone)and "spellstone"or "firestone","main")
        elseif class=="PALADIN"then Add(W.Known(W.classes.sanctification)and "sanctification"or "adjuration","main")end
    elseif entry.type=="consumable"then
        if entry.slot=="both"then
            rules[1]={type="consumable",value=entry.value,slot="main",source=entry}
            rules[2]={type="consumable",value=entry.value,slot="off",source=entry}
        else rules[1]=entry end
    end
    return rules
end
function W.AuraOptions(entry)
    local d=W.classes[entry.value];local result={};if not d then return result end
    for _,id in ipairs(d.spells)do
        if not(d.key=="instant"and id~=315584)then result[#result+1]=I.ResolveValue(tostring(id))end
    end
    return result
end
local weaponSlots={INVTYPE_WEAPON=true,INVTYPE_WEAPONMAINHAND=true,INVTYPE_WEAPONOFFHAND=true,INVTYPE_2HWEAPON=true,INVTYPE_RANGED=true,INVTYPE_RANGEDRIGHT=true,INVTYPE_THROWN=true}
local blunt={[4]=true,[5]=true,[6]=true,[10]=true,[13]=true};local ranged={[2]=true,[3]=true,[16]=true,[18]=true,[19]=true}
function W.Applicable(slot,d)
    local id=Number(Safe(GetInventoryItemID,"player",slot));if not id then return false end
    local _,_,ilevel,level,equip=W.ItemInfo(id)
    local _,_,_,instantEquip,_,classID,subclass=Safe(C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant,id)
    equip=equip or Text(instantEquip)
    if not weaponSlots[equip]then return false end
    if Number(classID)and classID~=2 then return false end
    if d.class then return true end
    local interface=M.Compat.interface or 0;local titan=interface>=38000 and interface<39000
    if d.era and d.era<=2 and W.Family()>=3 and not titan and ilevel and ilevel>165 then return false end
    if d.weapon then
        if not Number(subclass)then return nil end
        if d.weapon=="ranged"then return ranged[subclass]==true end
        if ranged[subclass]then return false end
        if d.weapon=="blade"then return not blunt[subclass]end
        if d.weapon=="blunt"then return blunt[subclass]==true end
    end
    return true
end
function W.Snapshot()
    local out={}
    if C_PaperDollInfo and C_PaperDollInfo.GetTemporaryEnchantmentInfo then
        for _,slot in ipairs({16,17})do
            local data=Safe(C_PaperDollInfo.GetTemporaryEnchantmentInfo,slot)
            if Readable(data)then out[slot]=type(data)=="table"and {present=true,id=Number(data.enchantID),remaining=Number(data.remainingTimeMs)}or {present=false}end
        end
    elseif GetWeaponEnchantInfo then
        local mh,mt,_,mi,oh,ot,_,oi=Safe(GetWeaponEnchantInfo)
        if Readable(mh)then out[16]={present=mh==true,id=Number(mi),remaining=Number(mt)}end
        if Readable(oh)then out[17]={present=oh==true,id=Number(oi),remaining=Number(ot)}end
    end
    return out
end
local function TooltipLines(slot)
    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local data=Safe(C_TooltipInfo.GetInventoryItem,"player",slot);local lines={}
        if type(data)=="table"and Readable(data.lines)and type(data.lines)=="table"then
            for _,line in ipairs(data.lines)do if Text(line.leftText)then lines[#lines+1]=Plain(line.leftText)end end
        end
        return lines
    end
    if not W.scanner then
        W.scanner=CreateFrame("GameTooltip","MangUIWeaponEnhancementScanner",UIParent,"GameTooltipTemplate")
        W.scanner:SetOwner(UIParent,"ANCHOR_NONE")
    end
    local scanner=W.scanner;scanner:ClearLines();local ok=pcall(scanner.SetInventoryItem,scanner,"player",slot)
    local lines={}
    if ok then for index=1,(Number(Safe(scanner.NumLines,scanner))or 0)do
        local text=_G["MangUIWeaponEnhancementScannerTextLeft"..index]
        if text then lines[#lines+1]=Plain(Safe(text.GetText,text))end
    end end
    scanner:Hide();return lines
end
local function MatchesLine(line,label)
    if label==""then return false end
    if line==label then return true end
    if line:sub(1,#label)~=label then return false end
    local suffix=line:sub(#label+1)
    return suffix:match("^%s*%(")~=nil or suffix:match("^%s*（")~=nil
end
function W.Present(slot,info,snapshot,lines)
    local state=snapshot[slot];if not state then return nil end
    if not state.present or (state.remaining and state.remaining<=0)then return false end
    local d=info.definition
    if state.id and Contains(d.enchants,state.id)then return true,state.remaining and state.remaining/1000 end
    -- Some custom clients use different enchant IDs or allow stacked imbues.
    -- Match the actual timed inventory-tooltip line, never a proc aura or a
    -- permanent enchant in the item link. Oil is not a substitute for poison.
    lines[slot]=lines[slot]or TooltipLines(slot)
    local labels={info.name,d.zh,d.en}
    for _,line in ipairs(lines[slot])do for _,label in ipairs(labels)do
        if MatchesLine(line,label)then return true,state.remaining and state.remaining/1000 end
        if d.class and label~=""then
            local start=line:find(label,1,true)
            if start and MatchesLine(line:sub(start),label)then return true,state.remaining and state.remaining/1000 end
        end
    end end
    return false
end
function W.Missing(entry,info,snapshot,lines)
    if not info.supported then return false end
    local level=Number(Safe(UnitLevel,"player"))
    if info.requiredLevel and level and level<info.requiredLevel then return false end
    local slots=entry.slot=="off"and {17}or entry.slot=="any"and {16,17}or {16}
    local eligible,unknown,presentAny,longest=false,false,false,nil
    for _,slot in ipairs(slots)do
        local applicable=W.Applicable(slot,info.definition)
        if applicable==true then
            eligible=true;local present,remaining=W.Present(slot,info,snapshot,lines)
            if present==true then
                presentAny=true
                if not remaining then return false end
                longest=math.max(longest or 0,remaining)
            elseif present==nil then unknown=true end
        elseif applicable==nil then unknown=true end
    end
    if unknown then return false end
    if presentAny then return longest>0 and longest<180,longest end
    return eligible
end
function W.SlotName(entry)
    for _,choice in ipairs(W.slots)do if choice.path==(entry.slot or "main")then return M:T(choice.name)end end
    return ""
end
function W.SlotLabel(entry)
    if M:EffectiveLanguage()=="zhCN"then return W.SlotName(entry)end
    return entry.slot=="off"and "OH"or entry.slot=="any"and "ANY"or "MH"
end
