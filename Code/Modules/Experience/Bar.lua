local _,M=...
local E={dirty=true};M.ExperienceBar=E
local WHITE="Interface\\Buttons\\WHITE8X8"
local function Templates()
    return {
        {id="experienceBar",label="经验条",kind="group",compound="experienceBar",scope="player",unit="player",
            x=0,y=-100,width=510,height=2,experienceHeight=2,font="游戏默认",scale=1,point="CENTER",anchor="CENTER",screenAnchor="TOP",alpha=1,enabled=true,layer=800,rules={},conditions={}},
        {id="experienceBarDisplay",label="经验条",kind="experiencebar",parent="experienceBar",internal=true,locked=true,
            scope="player",unit="player",x=0,y=0,width=510,height=2,scale=1,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=801},
    }
end
function M:EnsureExperienceBarModule(design)
    local seen={};for _,n in ipairs(design.nodes) do
        seen[n.id]=true
        if n.id=="experienceBar" then n.experienceHeight=n.experienceHeight or n.height or 2;n.font=n.font or "游戏默认" end
    end
    for _,n in ipairs(Templates()) do if not seen[n.id] then design.nodes[#design.nodes+1]=n end end
end
function E.SyncNodes(design)
    local root,row
    for _,n in ipairs(design.nodes) do
        if n.id=="experienceBar" then root=n elseif n.id=="experienceBarDisplay" then row=n end
    end
    if root then root.height=M.Clamp(root.experienceHeight or root.height or 2,1,100) end
    if root and row then row.height=root.height end
end
function E.RefreshFonts(view,o,force)
    local group=o.module or {};local font=M:EffectiveFontPath(group.fontPath or M:DefaultFontPath())
    local failed=false
    for i,label in ipairs(o.labels) do
        local ok,loaded=pcall(label.SetFont,label,font,({12,11,12,12})[i],"OUTLINE")
        if not ok or loaded==false then
            failed=true;label:SetFont(M:DefaultFontPath(),({12,11,12,12})[i],"OUTLINE")
        end
        -- Rebuild unchanged glyph runs after the selected face becomes available.
        label:SetText("");label.localeFitSize=({12,11,12,12})[i]
    end
    o.xpText={};o.nextUpdate=nil
    o.fontFailed=failed;o.fontNeedsSettle=not force
    if failed then view.fontsPending=true end
end
function E.Configure(view,o)
    o.xpRender={};o.xpState=nil;o.nextUpdate=nil;o.xpEventVersion=nil
    E.RefreshFonts(view,o,false)
    o.hover:SetSize(o.spec.width or 510,math.max(38,(o.spec.height or 2)+36))
    local width=o.spec.width or 510
    -- Keep the full XP value readable, with smaller time/percentage side slots.
    o.xpLabelWidths={[2]=width/2,[3]=width/4,[4]=width/4}
    for _,i in ipairs({2,3,4})do
        o.labels[i]:SetSize(o.xpLabelWidths[i],24)
        o.labels[i].localeFitSize=({12,11,12,12})[i]
    end
    o.labels[2]:ClearAllPoints();o.labels[2]:SetPoint("BOTTOM",o.frame,"TOP",0,10);o.labels[2]:SetJustifyH("CENTER")
    o.labels[3]:ClearAllPoints();o.labels[3]:SetPoint("BOTTOMRIGHT",o.frame,"TOPRIGHT",0,10);o.labels[3]:SetJustifyH("RIGHT")
    o.labels[4]:ClearAllPoints();o.labels[4]:SetPoint("BOTTOMLEFT",o.frame,"TOPLEFT",0,10);o.labels[4]:SetJustifyH("LEFT")
    local capHeight=math.max(6,o.spec.height or 2)
    o.startCap:SetSize(1,capHeight);o.endCap:SetSize(1,capHeight)
end
M.moduleIDs.experienceBar=true
M:EnsureExperienceBarModule(M.defaults)
if M.recordedDefaults then M:EnsureExperienceBarModule(M.recordedDefaults) end
local function Call(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b,c,d,e,f,g,h=pcall(fn,...);if ok then return a,b,c,d,e,f,g,h end
end
local function Number(value)return type(value)=="number" and math.max(0,value) or 0 end
local function Now()return time and time() or GetTime() end
local function Session(reset)
    if not M.db then return {} end
    local key=Call(UnitGUID,"player") or ((Call(GetRealmName) or "")..":"..(Call(UnitName,"player") or "player"))
    M.db.experienceSessions=M.db.experienceSessions or {}
    local s=M.db.experienceSessions[key]
    if not s or reset or E.session~=s then
        s={start=Now(),gained=0,lastXP=Number(Call(UnitXP,"player")),lastMax=Number(Call(UnitXPMax,"player"))}
        M.db.experienceSessions[key]=s
    end
    E.session=s;return s
end
function E.QuestExperience()
    if E.scanning then return E.complete or 0,E.incomplete or 0 end
    E.scanning=true
    local q=C_QuestLog or {};local completed,incomplete=0,0
    local count=Number(Call(q.GetNumQuestLogEntries or GetNumQuestLogEntries))
    local selected=Call(GetQuestLogSelection);local selectedID=Call(q.GetSelectedQuest)
    for i=1,count do
        local info=Call(q.GetInfo,i);local id,header,done
        if info then id,header,done=info.questID,info.isHeader,info.isComplete
        else
            local _,_,_,isHeader,_,isComplete,_,questID=Call(GetQuestLogTitle,i)
            id,header,done=questID,isHeader,isComplete==1
            id=id or Call(q.GetQuestIDForLogIndex,i)
        end
        if type(id)=="number" and id>0 and not header then
            local reward
            if q.GetQuestLogRewardXP then reward=Call(q.GetQuestLogRewardXP,id)
            else
                if SelectQuestLogEntry then Call(SelectQuestLogEntry,i)
                elseif q.SetSelectedQuest then Call(q.SetSelectedQuest,id) end
                reward=Call(GetQuestLogRewardXP,id)
            end
            reward=Number(reward)
            local ready=Call(q.ReadyForTurnIn,id)
            local complete=Call(q.IsComplete or IsQuestComplete,id)
            if ready or complete==true or complete==1 or done==true or done==1 then completed=completed+reward
            else incomplete=incomplete+reward end
        end
    end
    -- Reward queries in Classic use the selected quest. Restore it after scanning.
    if selected~=nil and SelectQuestLogEntry then Call(SelectQuestLogEntry,selected)
    elseif selectedID~=nil and q.SetSelectedQuest then Call(q.SetSelectedQuest,selectedID) end
    E.complete,E.incomplete=completed,incomplete;E.scanning=false;E.dirty=false
    return completed,incomplete
end
function E.Event(view,event,arg1,arg2)
    if view.preview then return end
    if event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_XP_UPDATE" or event=="PLAYER_LEVEL_UP" or event=="UPDATE_EXPANSION_LEVEL" then
        E.eventVersion=(E.eventVersion or 0)+1
    end
    if event=="QUEST_LOG_UPDATE" or (event=="UNIT_QUEST_LOG_CHANGED" and arg1=="player") then
        if not E.scanning then E.dirty=true end
    elseif event=="PLAYER_ENTERING_WORLD" then
        -- The supplied WA resets its XP/hour session on login and /reload.
        Session(arg1 or arg2);E.dirty=true
    elseif event=="PLAYER_XP_UPDATE" and (not arg1 or arg1=="player") then
        local s=E.session or Session();local current=Number(Call(UnitXP,"player"));local maximum=Number(Call(UnitXPMax,"player"))
        local gain=current-(s.lastXP or current)
        if gain<0 then gain=(s.lastMax or 0)-(s.lastXP or 0)+current end
        s.gained=(s.gained or 0)+math.max(0,gain);s.lastXP=current;s.lastMax=maximum
    elseif event=="PLAYER_LEVEL_UP" then
        E.level=arg1;local s=E.session or Session();s.levelTime=0;s.playedAt=Now();E.dirty=true
    elseif event=="TIME_PLAYED_MSG" then
        local s=E.session or Session();s.levelTime=Number(arg2);s.playedAt=Now()
    end
end
function E.State(preview)
    if preview then return {level=42,current=42000,maximum=100000,rested=30000,complete=18000,incomplete=12000,
        sessionTime=3600,levelTime=7200,hourly=21000,eta=9943,maxLevel=false} end
    local s=E.session or Session();local now=Now()
    if E.dirty then E.QuestExperience() end
    local current,maximum=Number(Call(UnitXP,"player")),Number(Call(UnitXPMax,"player"))
    local level=math.max(E.level or 0,Number(Call(UnitLevel,"player")))
    local cap=Call(GetMaxPlayerLevel)
    if not cap then cap=Call(GetMaxLevelForExpansionLevel,Call(GetExpansionLevel)) end
    local elapsed=math.max(0,now-(s.start or now));local hourly=elapsed>0 and math.ceil((s.gained or 0)*3600/elapsed) or 0
    return {level=level,current=current,maximum=maximum,rested=Number(Call(GetXPExhaustion)),complete=E.complete or 0,incomplete=E.incomplete or 0,
        maxLevel=maximum<=0 or (type(cap)=="number" and cap>0 and level>=cap),sessionTime=elapsed,hourly=hourly,
        eta=hourly>0 and math.ceil(math.max(0,maximum-current)/hourly*3600) or 0,
        levelTime=s.levelTime and s.levelTime+math.max(0,now-(s.playedAt or now))}
end
local function FormatNumber(value)return Call(FormatLargeNumber,value) or tostring(math.floor(value)) end
function E.FormatTime(value)
    if value==nil then return "--" end
    if value<60 then return M:T("不到1分钟") end
    local d=math.floor(value/86400);local h=math.floor(value/3600)%24;local m=math.floor(value/60)%60
    return (d>0 and string.format(M:T("%d天"),d).." "or "")
        ..((d>0 or h>0)and string.format(M:T("%d小时"),h).." "or "")
        ..string.format(M:T("%d分钟"),m)
end
local function Percent(value,maximum)return maximum>0 and value/maximum*100 or 0 end
function E.Tooltip(o)
    local s=o.xpState;if not s then return end
    GameTooltip:SetOwner(o.frame,"ANCHOR_BOTTOM");GameTooltip:SetText(M:T("经验条"),1,1,1)
    GameTooltip:AddLine(string.format(M:T("任务经验：%s（%.1f%%）"),FormatNumber(s.complete),Percent(s.complete,s.maximum)),1,.59,0)
    GameTooltip:AddLine(string.format(M:T("休息双倍：%s（%.1f%%）"),FormatNumber(s.rested),Percent(s.rested,s.maximum)),1,.11,.98)
    GameTooltip:AddLine(string.format(M:T("未完成任务经验：%s"),FormatNumber(s.incomplete)),1,.82,.31)
    GameTooltip:AddLine(string.format(M:T("经验/小时：%s"),FormatNumber(s.hourly)),.55,.69,1)
    GameTooltip:AddLine(M:T("预计升级时间：")..(s.eta>0 and E.FormatTime(s.eta) or "--"),.55,.69,1)
    GameTooltip:AddLine(M:T("本次在线：")..E.FormatTime(s.sessionTime),.96,.55,.73)
    GameTooltip:Show()
end
function E.Build(view,o)
    local f=o.frame
    -- The entire baseline is 0–100%, even when colored segments end earlier.
    o.background=f:CreateTexture(nil,"BACKGROUND");o.background:SetAllPoints();o.background:SetColorTexture(.35,.35,.35,.8)
    o.startCap=f:CreateTexture(nil,"OVERLAY");o.startCap:SetColorTexture(.65,.65,.65,.9);o.startCap:SetPoint("LEFT",f,"LEFT",0,0)
    o.endCap=f:CreateTexture(nil,"OVERLAY");o.endCap:SetColorTexture(.65,.65,.65,.9);o.endCap:SetPoint("RIGHT",f,"RIGHT",0,0)
    o.xpFill=f:CreateTexture(nil,"ARTWORK");o.xpFill:SetTexture(WHITE)
    if o.xpFill.SetGradient and CreateColor then o.xpFill:SetGradient("HORIZONTAL",CreateColor(.3,.35,.97,1),CreateColor(.71,.34,1,1))
    elseif o.xpFill.SetGradientAlpha then o.xpFill:SetGradientAlpha("HORIZONTAL",.3,.35,.97,1,.71,.34,1,1)
    else o.xpFill:SetVertexColor(.5059,.3451,.9843,1) end
    o.complete=f:CreateTexture(nil,"ARTWORK");o.complete:SetColorTexture(.7921569347,.5058823824,.0901960805,1)
    o.rested=f:CreateTexture(nil,"ARTWORK");o.rested:SetColorTexture(1,.1058823615,.9803922176,.54)
    o.spark=f:CreateTexture(nil,"OVERLAY");o.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");o.spark:SetSize(5,10);o.spark:SetBlendMode("ADD")
    o.labels={}
    for i,size in ipairs({12,11,12,12}) do
        local text=f:CreateFontString(nil,"OVERLAY");o.labels[i]=text
        local font=(i==1 or i==4) and (M:DefaultFontPath()) or M.MYRIAD
        text:SetFont(font,size,"OUTLINE");text:SetShadowColor(0,0,0,1);text:SetShadowOffset(1,-1);text:SetWordWrap(false)
    end
    o.labels[1]:SetPoint("LEFT",f,"LEFT",5,0)
    o.labels[2]:SetPoint("CENTER",f,"CENTER",0,19)
    o.labels[3]:SetPoint("RIGHT",f,"RIGHT",-5,19);o.labels[3]:SetTextColor(.5294,1,.5765,1)
    o.labels[4]:SetPoint("BOTTOMLEFT",f,"TOPLEFT",0,10);o.labels[4]:SetTextColor(.251,.7804,.9216,1)
    -- A thin bar gets a separate hover area without changing its artwork dimensions.
    o.hover=CreateFrame("Frame",nil,f);o.hover:SetPoint("CENTER",f,"CENTER",0,12);o.hover:SetSize(510,38);o.hover:EnableMouse(true)
    o.hover:SetScript("OnEnter",function()o.hovered=true;E.Tooltip(o)end)
    o.hover:SetScript("OnLeave",function()o.hovered=nil;GameTooltip:Hide()end)
    f:SetScript("OnHide",function()if o.hovered then o.hovered=nil;GameTooltip:Hide()end end)
end
local function Segment(o,key,texture,f,first,last,width,height)
    first,last=M.Clamp(first,0,1),M.Clamp(last,0,1)
    local shown=last>first
    if texture:IsShown()~=shown then texture:SetShown(shown) end
    local cache=o.xpRender;local previous=cache[key]
    if shown and (not previous or previous[1]~=first or previous[2]~=last or previous[3]~=width or previous[4]~=height) then
        texture:ClearAllPoints();texture:SetPoint("LEFT",f,"LEFT",first*width,0);texture:SetSize((last-first)*width,height)
        previous=previous or {};cache[key]=previous
        previous[1],previous[2],previous[3],previous[4]=first,last,width,height
    end
end
local function Label(o,index,value)
    if o.xpText[index]~=value then
        o.labels[index]:SetText(value);o.xpText[index]=value
        if index~=1 then M:FitLocaleText(o.labels[index],o.xpLabelWidths[index],8)end
    end
end
function E.Paint(view,o,animateOnly)
    local n,f=o.spec,o.frame
    if n.enabled==false or (view.hidden and view.hidden[n.id]) or (not view.preview and o.module and o.module.enabled==false) then f:Hide();return end
    local now=GetTime();local s=o.xpState
    -- A capped character wakes through XP/level/world/expansion events or Apply.
    if not view.preview and s and s.maxLevel and o.xpEventVersion==(E.eventVersion or 0) then return end
    if animateOnly and s and now<(o.nextUpdate or 0) and not o.xpStarted then return end
    local stateChanged=false
    if not animateOnly or not s or not o.nextUpdate or now>=o.nextUpdate then
        s=E.State(view.preview);o.xpState=s;o.nextUpdate=now+.2;stateChanged=true
        o.xpEventVersion=E.eventVersion or 0
    end
    if s.maxLevel and not view.preview then if f:IsShown() then f:Hide() end;return end
    if not f:IsShown() then f:Show() end
    if not view.preview and not E.timeRequested and RequestTimePlayed then
        E.timeRequested=true
        local function Request()
            if o.module and o.module.enabled==false then E.timeRequested=nil;return end
            RequestTimePlayed()
        end
        -- StartLive installs event listeners after its first Apply; defer the request.
        if C_Timer and C_Timer.After then C_Timer.After(.5,Request) else Request() end
    end
    local width,height=n.width or 510,n.height or 2;local maximum=math.max(1,s.maximum)
    local actual=s.current/maximum
    if o.xpRatio==nil or o.xpMaximum~=maximum then
        o.xpRatio=actual;o.xpTarget=actual;o.xpMaximum=maximum;o.xpStarted=nil
    elseif actual~=o.xpTarget then
        o.xpFrom=o.xpRatio;o.xpTarget=actual;o.xpStarted=now
    end
    if o.xpStarted then
        local t=M.Clamp((now-o.xpStarted)/.35,0,1)
        o.xpRatio=o.xpFrom+(o.xpTarget-o.xpFrom)*t
        if t==1 then o.xpStarted=nil end
    end
    local current=o.xpRatio;local quest=current+s.complete/maximum
    Segment(o,"current",o.xpFill,f,0,current,width,height)
    Segment(o,"quest",o.complete,f,current,quest,width,height)
    Segment(o,"rested",o.rested,f,quest,quest+s.rested/maximum,width,height)
    local sparkX=M.Clamp(current,0,1)*width
    if o.xpRender.sparkX~=sparkX then
        o.spark:ClearAllPoints();o.spark:SetPoint("CENTER",f,"LEFT",sparkX,0);o.xpRender.sparkX=sparkX
    end
    if stateChanged then
        Label(o,1,"Lv "..s.level)
        Label(o,2,string.format("%s / %s (%s)",FormatNumber(s.current),FormatNumber(s.maximum),FormatNumber(math.max(0,s.maximum-s.current))))
        local percentage=string.format("%.1f%%",actual*100)
        if s.complete>0 then percentage=percentage..string.format(" (%.1f%%)",(actual+s.complete/maximum)*100) end
        Label(o,3,percentage);Label(o,4,E.FormatTime(s.levelTime))
        if not o.labels[4]:IsShown() then o.labels[4]:Show() end
        if o.hovered then E.Tooltip(o) end
    end
end
