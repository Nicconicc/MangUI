local _,M=...
local C={};M.CustomMonitor=C
C.MAX_CODE=16384
C.fields={customCode=true,customEvents=true,customInterval=true}
C.status=setmetatable({},{__mode="k"})
C.defaultCode=[[function(state, event, ...)
    -- state 保存本条监控的数据；返回 false 隐藏图标。
    return {show = true, icon = 136219, count = 1, glow = false}
end]]
local function Public(v)return not issecretvalue or not issecretvalue(v)end
local function Number(v)return Public(v)and type(v)=="number"and v==v and math.abs(v)<1000000000000 and v or nil end
function C.Valid(entry)
    if entry.customCode~=nil and (type(entry.customCode)~="string"or #entry.customCode>C.MAX_CODE)then return false end
    if entry.customEvents~=nil and (type(entry.customEvents)~="string"or #entry.customEvents>1024)then return false end
    local n=entry.customInterval
    if n~=nil and (type(n)~="number"or n~=n or (n~=0 and (n<.1 or n>60)))then return false end
    return true
end
function C.Defaults(entry)
    if entry.customCode==nil then entry.customCode=C.defaultCode end
    if entry.customEvents==nil then entry.customEvents="PLAYER_TARGET_CHANGED UNIT_HEALTH:target SPELL_UPDATE_COOLDOWN"end
    if entry.customInterval==nil then entry.customInterval=.1 end
end
function C.Events(text)
    local result,count={},0
    for token in (text or ""):gmatch("[^%s,;]+")do
        local event,units=token:match("^([^:]+):?(.*)$")
        if not event:match("^[A-Z][A-Z0-9_]*$")then return nil,"无效事件："..token end
        if not result[event]then count=count+1;if count>32 then return nil,"最多监听32种事件。"end;result[event]={}end
        if units==""then result[event].all=true
        else
            for unit in units:gmatch("[^:]+")do
                if not unit:match("^[a-z]+%d*$")then return nil,"无效单位："..unit end
                result[event][unit]=true
            end
        end
    end
    return result
end
local globals={"assert","error","ipairs","pairs","next","select","tonumber","tostring","type","unpack","pcall",
    "GetTime","time","GetServerTime","GetBuildInfo","GetLocale","InCombatLockdown","IsInGroup","IsInRaid","IsInInstance",
    "UnitExists","UnitGUID","UnitName","UnitClass","UnitLevel","UnitHealth","UnitHealthMax","UnitPower","UnitPowerMax",
    "UnitIsDead","UnitIsDeadOrGhost","UnitAffectingCombat","UnitCanAttack","UnitIsUnit","UnitIsPlayer","UnitClassification",
    "UnitBuff","UnitDebuff","UnitAura","UnitAttackPower","UnitRangedAttackPower","UnitStat","GetSpellBonusDamage",
    "GetSpellInfo","GetSpellTexture","GetSpellCooldown","GetSpellCharges","IsSpellKnown","IsPlayerSpell","IsUsableSpell",
    "GetInventoryItemID","GetInventoryItemTexture","GetInventoryItemCooldown","GetItemInfo","GetItemIcon","GetItemCount","GetItemCooldown",
    "CombatLogGetCurrentEventInfo","GetNumGroupMembers","GetSpecialization","GetSpecializationInfo","issecretvalue"}
local function CopyFunctions(source)
    local target={}
    for k,v in pairs(source or {})do if type(v)=="function"or type(v)=="number"or type(v)=="string"then target[k]=v end end
    return target
end
local function Environment()
    local env={math=CopyFunctions(math),string=CopyFunctions(string),table=CopyFunctions(table)}
    -- No _G, addon objects, loaders, frame creation, chat or protected actions.
    for _,key in ipairs(globals)do env[key]=_G[key]end
    for _,key in ipairs({"C_Spell","C_Item","C_UnitAuras","C_SpecializationInfo","C_ClassTalents","C_Traits"})do
        local source=_G[key]
        if source then
            local target={};env[key]=target
            for name,fn in pairs(source)do
                if type(fn)=="function"and (name:match("^Get")or name:match("^Is")or name:match("^Has")or name:match("^Can"))then target[name]=fn end
            end
        end
    end
    return env
end
function C.Syntax(entry)
    if not C.Valid(entry)then return nil,"代码或刷新设置超出允许范围。"end
    local events,err=C.Events(entry.customEvents);if not events then return nil,err end
    local source=entry.customCode or ""
    if not source:match("^%s*function%s*%(")then return nil,"代码须为 function(state, event, ...) ... end。"end
    if not loadstring or not setfenv then return nil,"当前客户端不支持自定义代码编译。"end
    local chunk,why=loadstring("return "..source,"MangUI custom monitor")
    if not chunk then return nil,why end
    return chunk,events
end
function C.Compile(entry)
    local chunk,events=C.Syntax(entry);if not chunk then return nil,events end
    setfenv(chunk,Environment())
    local ok,fn=pcall(chunk)
    if not ok or type(fn)~="function"then return nil,tostring(fn)end
    return {fn=fn,data={},events=events,interval=entry.customInterval or .1,source=entry.customCode,
        eventText=entry.customEvents,entry=entry,nextUpdate=0,result={show=false}}
end
local function Result(value)
    if value==nil or value==false then return {show=false}end
    if value==true then return {show=true}end
    if not Public(value)or type(value)~="table"then error("返回值须为 boolean 或结果表。")end
    local r={show=false}
    if not Public(value.show)or (value.show~=nil and type(value.show)~="boolean")then error("show 须为可读取的 boolean。")end
    r.show=value.show==true
    for _,key in ipairs({"icon","count","text","sound"})do
        local v=value[key]
        if not Public(v)then error(key.." 是受保护值，不能用于自定义判断。")end
        if type(v)=="string"then
            if #v>512 then error(key.." 过长。")end
            r[key]=v
        elseif key~="text"and key~="sound"and Number(v)then
            if key=="icon"and (v<1 or v>2147483647 or v%1~=0)then error("icon 须为有效的材质ID或路径。")end
            r[key]=v
        elseif v~=nil then error(key.." 的类型无效。")end
    end
    for _,key in ipairs({"expirationTime","duration"})do
        if value[key]~=nil then r[key]=Number(value[key]);if not r[key]or r[key]<0 then error(key.." 须为非负数。")end end
    end
    if value.glow~=nil then
        if not Public(value.glow)or type(value.glow)~="boolean"then error("glow 须为 boolean。")end
        r.glow=value.glow
    end
    return r
end
local function Run(record,event,...)
    if record.error then return end
    local ok,value=pcall(record.fn,record.data,event,...)
    if ok then ok,value=pcall(Result,value)end
    if not ok then record.error=tostring(value);record.result={show=false};return false,record.error end
    record.result=value;return true,value
end
function C.Test(entry)
    local record,err=C.Compile(entry);if not record then return false,err end
    local ok,result=Run(record,"INIT");if not ok then return false,result end
    ok,result=Run(record,"TEST");if not ok then return false,result end
    return true,"测试完成：show="..tostring(result.show).."；测试数据未写入正式监控。"
end
local function Active(owner)
    local group=owner.view.byID[owner.o.spec.parent]
    return not owner.o.removed and group and group.enabled~=false and owner.o.spec.enabled~=false
end
local function Sound(slot,record,result)
    local entry=record.entry
    if result.show and not record.wasShown and slot:IsVisible()and not(M.editor and M.editor.window:IsShown())then
        if result.sound then M.PlayerOtherMonitor.Play({soundEnabled=true,sound=result.sound,soundPath="",soundID=""})
        elseif entry.soundEnabled then M.PlayerOtherMonitor.Play(entry)end
    end
    record.wasShown=result.show
end
local function Evaluate(owner,slot,record,event,...)
    local ok,err=Run(record,event,...)
    if not ok and err then C.status[record.entry]="运行已暂停："..err;M:Report("自定义代码",err:sub(1,500))end
end
function C.Remove(o)
    local owner=o.customOwner;if not owner then return end
    owner.driver:UnregisterAllEvents();owner.driver:SetScript("OnUpdate",nil);owner.driver:SetScript("OnEvent",nil);owner.driver:Hide()
    owner.records={};o.customOwner=nil
end
function C.Sync(view,o,slots,paint)
    if view.preview then return end
    local any=false
    for _,slot in ipairs(slots)do if slot.entry and slot.entry.type=="custom"then any=true;break end end
    if not any then C.Remove(o);return end
    local group=view.byID[o.spec.parent];local records={}
    local owner=o.customOwner
    if not owner then
        owner={view=view,o=o,records={},driver=o.customDriver or CreateFrame("Frame")}
        o.customOwner=owner;o.customDriver=owner.driver
    end
    owner.view=view;owner.paint=paint
    local oldByEntry={}
    for _,record in pairs(owner.records)do oldByEntry[record.entry]=record end
    if group.enabled~=false and o.spec.enabled~=false then
        for _,slot in ipairs(slots)do
            local entry=slot.entry
            if entry and entry.type=="custom"then
                local old=oldByEntry[entry]
                if old and old.entry==entry and old.source==entry.customCode and old.eventText==entry.customEvents and old.interval==entry.customInterval then records[slot]=old
                else
                    local record,err=C.Compile(entry)
                    record=record or {entry=entry,source=entry.customCode,eventText=entry.customEvents,interval=entry.customInterval,error=err,events={},result={show=false}}
                    records[slot]=record;C.status[entry]=err and ("编译失败："..err)or "编译成功"
                    if not err then Evaluate(owner,slot,record,"INIT")end
                end
            end
        end
    end
    owner.records=records;owner.driver:UnregisterAllEvents()
    local listening,poll={},false
    for _,record in pairs(records)do if not record.error then
        if record.interval>0 then poll=true end
        for event in pairs(record.events)do listening[event]=true end
    end end
    for event in pairs(listening)do
        local ok,err=pcall(owner.driver.RegisterEvent,owner.driver,event)
        if not ok or err==false then for _,record in pairs(records)do if record.events[event]then
            record.error="事件注册失败："..event.." "..tostring(err);record.result={show=false};C.status[record.entry]=record.error
        end end end
    end
    owner.driver:SetScript("OnEvent",function(_,event,...)
        if not Active(owner)then return end
        local unit=select(1,...)
        for slot,record in pairs(owner.records)do
            local filters=record.events[event]
            if filters and (filters.all or (Public(unit)and type(unit)=="string"and filters[unit]))then Evaluate(owner,slot,record,event,...)end
        end
        owner.paint(owner.view,owner.o,true)
    end)
    owner.driver:SetScript("OnUpdate",poll and function()
        if not Active(owner)then return end
        local now=GetTime();local changed=false
        for slot,record in pairs(owner.records)do
            if not record.error and record.interval>0 and now>=record.nextUpdate then
                record.nextUpdate=now+record.interval;Evaluate(owner,slot,record,"UPDATE");changed=true
            end
        end
        if changed then owner.paint(owner.view,owner.o,true)end
    end or nil)
    if next(records)then owner.driver:Show()else C.Remove(o)end
end
function C.Apply(o,slot,preview)
    local record=o.customOwner and o.customOwner.records[slot]
    local result=preview and {show=true,glow=false,count=1}or (record and record.result)or {show=false}
    slot.customResult=result;slot.show=result.show;slot.condition=result.show;slot.active=result.show
    slot:SetShown(result.show)
    slot.expires=result.expirationTime;slot.stacks=result.count;slot.faded=false;slot.rawKnown=true
    slot.texture:SetTexture(result.icon or slot.customFallbackIcon or 134400)
    if record and not preview then Sound(slot,record,result)end
    return result
end
function C.Glow(slot,enabled)
    if not slot.customGlow then
        local g=CreateFrame("Frame",nil,slot);g:SetPoint("TOPLEFT",-3,3);g:SetPoint("BOTTOMRIGHT",3,-3)
        local t=g:CreateTexture(nil,"OVERLAY");t:SetAllPoints();t:SetTexture("Interface\\Buttons\\UI-ActionButton-Border");t:SetBlendMode("ADD");t:SetVertexColor(1,.82,0,1)
        g:EnableMouse(false);slot.customGlow=g
    end
    slot.customGlow:SetShown(enabled==true)
end
