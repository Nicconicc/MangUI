local _,M=...
local T={};M.TargetThreat=T
local function Templates()
    return {
        -- The supplied WA was attached to the original main group's 0.6 scale.
        {id="targetThreat",label="目标仇恨监控",kind="group",compound="targetThreat",scope="player",unit="player",
            x=-180,y=-314,width=200,height=32,scale=.6,point="LEFT",anchor="CENTER",alpha=1,enabled=true,locked=true,
            font="Myriad",fontSize=28,instanceOnly=true,layer=900,rules={},conditions={}},
        {id="targetThreatDisplay",label="目标仇恨监控",kind="targetthreat",parent="targetThreat",internal=true,locked=true,
            scope="player",unit="player",x=0,y=0,width=200,height=32,scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=901},
    }
end
function M:EnsureTargetThreatModule(design)
    local seen={}
    for _,n in ipairs(design.nodes) do
        seen[n.id]=true
        if n.id=="targetThreat" or n.id=="targetThreatDisplay" then n.label="目标仇恨监控" end
        if n.id=="targetThreat" and n.instanceOnly==nil then n.instanceOnly=true end
    end
    for _,n in ipairs(Templates()) do if not seen[n.id] then design.nodes[#design.nodes+1]=n end end
end
function T.SyncNodes(design)
    local group,display
    for _,n in ipairs(design.nodes) do
        if n.id=="targetThreat" then group=n elseif n.id=="targetThreatDisplay" then display=n end
    end
    if group then
        if group.instanceOnly==nil then group.instanceOnly=true end
        group.height=math.max(.1,group.fontSize or 28)+4
    end
    if group and display then display.height=group.height end
end
M.moduleIDs.targetThreat=true
M:EnsureTargetThreatModule(M.defaults)
if M.recordedDefaults then M:EnsureTargetThreatModule(M.recordedDefaults) end
local function Call(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b,c,d,e=pcall(fn,...);if ok then return a,b,c,d,e end
end
local function Number(value)
    if type(value)~="number" or (issecretvalue and issecretvalue(value)) then return end
    if value~=value or value==math.huge or value==-math.huge then return end
    return value
end
function T.FormatNumber(value)
    local suffix={"k","M","B"};local index=0
    while math.abs(value)>=1000 and index<3 do value=value/1000;index=index+1 end
    local text=string.format(value>=100 and "%.0f" or value>=10 and "%.1f" or "%.2f",value)
    return text..(suffix[index] or "")
end
function T.State(preview,group)
    if preview then return 125,3 end
    if not group or group.instanceOnly~=false then
        local inside,kind=Call(IsInInstance)
        if not inside or (kind~="party" and kind~="raid") then return end
        if kind=="party" and GetInstanceInfo and select(5,Call(GetInstanceInfo))~=5 then return end
    end
    if not (Call(UnitAffectingCombat,"player") or Call(InCombatLockdown)) or not Call(UnitExists,"target") then return end
    local _,status,scaled,raw=Call(UnitDetailedThreatSituation,"player","target")
    scaled=Number(scaled)
    if scaled==nil then return end
    local percentage=Number(Call(UnitThreatPercentageOfLead,"player","target"))
    -- Some clients lack the lead API; raw percentage retains the relative threat value.
    percentage=percentage or Number(raw) or scaled
    return math.max(0,percentage),Number(status) or 0
end
function T.Build(view,o)
    o.threatText=o.frame:CreateFontString(nil,"OVERLAY")
    o.threatText:SetPoint("LEFT",o.frame,"LEFT");o.threatText:SetJustifyH("LEFT");o.threatText:SetWordWrap(false)
    o.threatText:SetShadowColor(0,0,0,1);o.threatText:SetShadowOffset(1,-1)
end
function T.Configure(view,o)
    local group=o.module or {};local font=group.fontPath
    if not font or font=="" then font=group.font=="Myriad" and M.MYRIAD or (M:DefaultFontPath()) end
    font=M:EffectiveFontPath(font)
    local size=math.max(.1,group.fontSize or 28)
    local ok,loaded=pcall(o.threatText.SetFont,o.threatText,font,size,"OUTLINE")
    if not ok or loaded==false then o.threatText:SetFont(M:DefaultFontPath(),size,"OUTLINE") end
    o.frame:SetHeight(size+4);o.nextThreatUpdate=nil
end
function T.Paint(view,o,animateOnly)
    if o.spec.enabled==false or (view.hidden and view.hidden[o.spec.id]) or (not view.preview and o.module and o.module.enabled==false) then
        o.threatText:SetText("");o.frame:Hide();return
    end
    if animateOnly and o.nextThreatUpdate and GetTime()<o.nextThreatUpdate then return end
    o.nextThreatUpdate=GetTime()+.1
    local percentage,status=T.State(view.preview,o.module)
    if percentage==nil then o.threatText:SetText("");o.frame:Hide();return end
    if status==2 then o.threatText:SetTextColor(0,1,1,1)
    elseif status==1 then o.threatText:SetTextColor(1,1,0,1)
    else o.threatText:SetTextColor(1,0,0,1) end
    o.threatText:SetText(T.FormatNumber(percentage).."%");o.frame:Show()
end
