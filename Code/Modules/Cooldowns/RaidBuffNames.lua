local _,M=...
local I=M.RaidBuffMonitor
local Safe,Number,Readable=I.Safe,I.Number,I.Readable
local names,wanted={},{}
local cursor,seeded,cacheKey=0,false,nil
local worker=CreateFrame("Frame")
-- Query common raid-Buff IDs on every client: localized names come from the
-- client's spell data, never from the current character's spellbook.
local seeds={1243,1244,1245,2791,10937,10938,25389,48161,21562,21564,25392,48162,
    1459,1460,1461,10156,10157,27126,42995,23028,27127,43002,
    1126,5232,6756,5234,8907,9884,9885,26990,48469,21849,21850,26991,48470,
    19740,19834,19835,19836,19837,19838,25291,27140,48931,48932,25782,25916,27141,48933,48934,
    19742,19850,19852,19853,19854,25290,27142,48935,48936,25894,25918,27143,48937,48938,
    20217,25898,20911,25899,976,10957,10958,25433,48169,27683,39374,14752,14818,14819,27841,25312,48073,
    6673,5242,6192,11549,11550,11551,25289,2048,47436,469,47439,57330,57623,
    6307,7804,7805,11766,11767,27268,47982,19506,30809,17007,24932,55610,19574,57399,
    21562,1459,1126,462854,381748,381732,15473,6673,264764,465,32223,52127,32593,32594,974,97462}
local function Saved()
    local _,build=Safe(GetBuildInfo)
    local key=tostring(M.Compat.interface)..":"..tostring(build)..":"..tostring(Safe(GetLocale))
    if key~=cacheKey then names={};wanted={};cursor=0;seeded=false;cacheKey=key end
    if not M.db then return end
    local saved=M.db.raidBuffNameCache
    if type(saved)~="table"or saved.key~=key or type(saved.names)~="table"then
        saved={key=key,names={}};M.db.raidBuffNameCache=saved
    end
    return saved.names
end
local function Remember(name,id,icon,persist)
    id=Number(id)
    if not Readable(name)or type(name)~="string"or name==""or not id or id<=0 then return end
    local record=names[name]
    if not record then
        record={name=name,id=id,ids={},revision=0};names[name]=record
        local saved=Saved();local prior=saved and saved[name]
        if type(prior)=="table"and type(prior.ids)=="table"then
            for rank in pairs(prior.ids)do if Number(rank)and rank>0 then record.ids[rank]=true end end
        end
    end
    if not record.ids[id]then record.ids[id]=true;record.revision=record.revision+1 end
    if Readable(icon)and icon and record.icon~=icon then record.icon=icon;record.revision=record.revision+1 end
    if persist then
        wanted[name]=nil
        local saved=Saved();if saved then saved[name]=M.Copy(record)end
    end
    return record
end
local function Query(id,persist)
    local name,resolved,icon=M.PetBuffs.SpellInfo(tostring(id))
    return Remember(name,Number(resolved)or id,icon,persist)
end
local function Seed()
    Saved();if seeded then return end;seeded=true
    for _,id in ipairs(seeds)do Query(id,false)end
end
function I.RememberBuffAura(aura)
    Saved()
    local id=aura.spellId;if type(id)=="nil"then id=aura.spellID end
    Remember(aura.name,id,aura.icon,true)
end
function I.ResolveName(value)
    Seed()
    local name,id,icon=M.PetBuffs.SpellInfo(value)
    if tonumber(value)then return name,tonumber(value),icon end
    if name and id then Remember(name,id,icon,false)end
    local record=names[value]
    if not record then
        local saved=Saved();local prior=saved and saved[value]
        if type(prior)=="table"and Number(prior.id)and type(prior.ids)=="table"then
            record=Remember(value,prior.id,prior.icon,false)
            for rank in pairs(prior.ids)do if Number(rank)and rank>0 then Remember(value,rank,prior.icon,false)end end
        end
    end
    if record then return value,record.id,record.icon,record.ids,record.revision end
    return name,id,icon
end
-- Opt-in rank matching for player-Buff reminders only. Other modules can
-- continue resolving a numeric value as one exact spell ID.
function I.ExpandBuffRanks(spell)
    spell.matchName=not tonumber(spell.value)and spell.value or nil
    if tonumber(spell.value)and spell.name~=spell.value then
        spell.matchName=spell.name
        local _,_,_,ids,revision=I.ResolveName(spell.name)
        spell.ids,spell.revision=ids,revision
    end
end
local function Refresh()
    local view=M.live;local o=view and view.nodes.raidBuffsIcons
    if o then o.nextInfo=0;I.Paint(view,o,false)end
    local received=view and view.nodes.receivedBuffsIcons
    if received and M.ReceivedBuffs then received.nextInfo=0;M.ReceivedBuffs.Paint(view,received,false)end
    local vulnerability=view and view.nodes.raidVulnerabilityIcons
    if vulnerability and M.RaidVulnerability then vulnerability.nextInfo=0;M.RaidVulnerability.Paint(view,vulnerability,false)end
    if M.editor and M.editor.window:IsShown()and (M.selection=="raidBuffs"or M.selection=="receivedBuffs"or M.selection=="raidVulnerability")then M:RefreshProperties()end
end
local function Scan()
    if InCombatLockdown()then return end
    if not M.editor or not M.editor.window:IsShown()or (M.selection~="raidBuffs"and M.selection~="receivedBuffs"and M.selection~="raidVulnerability")then worker:SetScript("OnUpdate",nil);return end
    local start=Safe(debugprofilestop)
    local changed=false
    for index=1,200 do
        if cursor>=2000000 or not next(wanted)then worker:SetScript("OnUpdate",nil);break end
        cursor=cursor+1
        local record=Query(cursor,false)
        if record and wanted[record.name]then
            wanted[record.name]=nil;Remember(record.name,record.id,record.icon,true);changed=true
        end
        if start and index%20==0 and debugprofilestop()-start>=1 then break end
    end
    if changed then Refresh()end
end
function I.RequestBuffName(value)
    if value==""or tonumber(value)then return end
    local _,id=I.ResolveName(value);if id then return end
    wanted[value]=true
    if cursor<2000000 then worker:SetScript("OnUpdate",Scan)end
end
local function Observe(unit)
    unit=unit=="target"and "target"or "player"
    Saved()
    if C_Secrets and C_Secrets.ShouldAurasBeSecret then
        local secret=Safe(C_Secrets.ShouldAurasBeSecret,unit)
        if not Readable(secret)or secret==true then return end
    end
    for index=1,255 do local aura=M.Compat.Aura(unit,index,unit=="target"and "HARMFUL"or "HELPFUL");if not aura then break end;I.RememberBuffAura(aura)end
end
worker:SetScript("OnEvent",function(_,event,unit)
    if event=="UNIT_AURA"and unit~="player"and unit~="target"then return end
    Observe(event=="UNIT_AURA"and unit or "player")
    if event=="SPELL_DATA_LOAD_RESULT"then seeded=false end
    Refresh()
end)
for _,event in ipairs({"UNIT_AURA","PLAYER_ENTERING_WORLD","SPELLS_CHANGED","SPELL_DATA_LOAD_RESULT"})do Safe(worker.RegisterEvent,worker,event)end
