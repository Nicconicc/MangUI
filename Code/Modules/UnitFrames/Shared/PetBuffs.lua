local _,M=...
local P={};M.PetBuffs=P
P.nodeID="petTrackedBuffs"
P.nameIDs={}
function P.Input(value)
    if type(value)~="string" then return "" end
    value=value:gsub("[%c]",""):match("^%s*(.-)%s*$")
    local id=value:match("^%d+$") and tonumber(value)
    if id and id>0 and id<=1000000000 then return tostring(id) end
    return value
end
function M:EnsurePetBuffs(design)
    if not design or type(design.nodes)~="table" then return end
    local root,found
    for _,n in ipairs(design.nodes) do
        if n.id=="petComposite" then root=n elseif n.id==P.nodeID then found=n end
    end
    if not root then return end
    for i=1,5 do root["petBuff"..i]=P.Input(root["petBuff"..i]) end
    if found then
        -- Preserve the row's top edge when updating saved icon sizes.
        local previousHeight=found.height or 50
        if previousHeight~=62.5 then found.y=(found.y or (-50-previousHeight/2))+(previousHeight-62.5)/2 end
        found.width,found.height=62.5,62.5
    end
    if not found then
        design.nodes[#design.nodes+1]={id=P.nodeID,label="宠物Buff监控",kind="auras",parent="petComposite",
            internal=true,locked=true,scope="pet",unit="pet",visibleUnit="pet",enabled=true,
            x=175,y=-81.25,width=62.5,height=62.5,scale=1,point="LEFT",anchor="CENTER",alpha=1,layer=330,
            filter="HELPFUL",count=5,spacing=5,cooldownReverse=true,hideCooldownNumbers=true,rules={},conditions={}}
    end
end
M:EnsurePetBuffs(M.defaults);M:EnsurePetBuffs(M.recordedDefaults)
local function Readable(value)return not issecretvalue or not issecretvalue(value)end
local function AuraID(aura)
    if type(aura.spellId)~="nil" then return aura.spellId end
    return aura.spellID
end
local function Safe(fn,...)
    if not fn then return end
    local ok,a,b,c,d,e,f,g=pcall(fn,...)
    if ok then return a,b,c,d,e,f,g end
end
function P.SpellInfo(value)
    local key=tonumber(value) or value
    if C_Spell and C_Spell.GetSpellInfo then
        local info=Safe(C_Spell.GetSpellInfo,key)
        if info and Readable(info.name) and Readable(info.spellID) and Readable(info.iconID) then
            return info.name,info.spellID,info.iconID
        end
    end
    local name,_,icon,_,_,_,id=Safe(GetSpellInfo,key)
    if Readable(name) and Readable(id) and Readable(icon) then return name,id,icon end
end
function P.Inputs(group)
    local result={}
    for i=1,5 do
        local value=P.Input(group and group["petBuff"..i])
        if value~="" then result[#result+1]={value=value,id=value:match("^%d+$") and tonumber(value),slot=i} end
    end
    return result
end
-- Enumerate the full helpful list before filtering; the first five pet auras
-- need not contain any of the requested spells. Preserve source tooltip indices.
function P.Read(group,out)
    local result=out or {};local inputs=P.Inputs(group);local matches={}
    if #inputs>0 then
        for index=1,255 do
            local aura=M.Compat.Aura("pet",index,"HELPFUL")
            if not aura then break end
            local name,id=aura.name,AuraID(aura)
            for slot,input in ipairs(inputs) do
                local match=input.id and Readable(id) and id==input.id
                    or (not input.id and Readable(name) and name==input.value)
                if match and not matches[slot] then aura.auraIndex=index;matches[slot]=aura end
            end
        end
    end
    local used,seen=0,{}
    for slot=1,#inputs do
        local aura=matches[slot]
        if aura and not seen[aura.auraIndex] then
            used=used+1;result[used]=aura;seen[aura.auraIndex]=true
        end
    end
    for i=#result,used+1,-1 do result[i]=nil end
    return result
end
function P.Preview(group)
    local result,seen={},{}
    for _,input in ipairs(P.Inputs(group)) do
        local name,id,icon=P.SpellInfo(input.value)
        local key=id or input.value
        if not seen[key] then
            seen[key]=true
            result[#result+1]={name=name or input.value,spellId=id,icon=icon or 134400,
                applications=0,duration=60,expirationTime=GetTime()+45}
        end
    end
    return result
end
-- The native container accepts ID sets, including on restricted pet auras.
-- Resolve entered names outside combat and learn visible rank IDs as well.
function P.NativeFilters(group,canScan)
    local include,inputs,needNames={},P.Inputs(group),false
    for _,input in ipairs(inputs) do
        local _,id=P.SpellInfo(input.value)
        id=input.id or id
        if type(id)=="number" and id>0 then include[id]=true end
        if not input.id then
            needNames=true
            local learned=P.nameIDs[input.value]
            for known in pairs(learned or {}) do include[known]=true end
        end
    end
    if canScan and needNames then
        for _,aura in ipairs(P.Read(group)) do
            local id=AuraID(aura)
            if Readable(id) and type(id)=="number" then
                include[id]=true
                if Readable(aura.name) and type(aura.name)=="string" then
                    local learned=P.nameIDs[aura.name] or {};P.nameIDs[aura.name]=learned;learned[id]=true
                end
            end
        end
    end
    local ids={};for id in pairs(include) do ids[#ids+1]=id end;table.sort(ids)
    return {includeSpellIDs=include},table.concat(ids,",")
end
