local _,M=...
local N={};M.CombatNotices=N
local ART="Interface\\AddOns\\MangUI\\Assets\\CombatNotices\\"
-- The stock enter atlas fades to transparent over its last three cells.
local ENTER_HOLD_FRAME=32 -- zero-based
local function Templates()
    local nodes={
        {id="combatNotices",label="进入和离开战斗提示",kind="group",compound="combatNotices",scope="player",unit="player",
            x=-310,y=-100,width=2,height=2,scale=.6,point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=500,
            soundEnabled=true,rules={},conditions={}},
    }
    for _,entry in ipairs({{"Enter","进入战斗提示","PLAYER_REGEN_DISABLED","Incombat",0},
        {"Leave","离开战斗提示","PLAYER_REGEN_ENABLED","Outcombat",.25}}) do
        nodes[#nodes+1]={id="combatNotice"..entry[1],label=entry[2],kind="combatnotice",parent="combatNotices",
            internal=true,locked=true,scope="player",unit="player",x=0,y=0,width=350,height=350,scale=1,
            point="CENTER",anchor="CENTER",alpha=1,enabled=true,layer=501,file=ART..entry[4],blend="BLEND",
            rows=6,columns=6,frames=36,fps=24,combatEvent=entry[3],noticeDuration=2,noticeFade=entry[5]}
    end
    return nodes
end
function M:EnsureCombatNoticesModule(design)
    local seen={};for _,node in ipairs(design.nodes) do
        seen[node.id]=true
        if node.id=="combatNotices" and node.soundEnabled==nil then node.soundEnabled=true end
    end
    for _,node in ipairs(Templates()) do if not seen[node.id] then design.nodes[#design.nodes+1]=node end end
end
M.moduleIDs.combatNotices=true
M:EnsureCombatNoticesModule(M.defaults)
if M.recordedDefaults then M:EnsureCombatNoticesModule(M.recordedDefaults) end

function N.Paint(view,o)
    local n,f=o.spec,o.frame
    if n.enabled==false or (view.hidden and view.hidden[n.id]) or
        (not view.preview and o.module and o.module.enabled==false) then
        f:Hide();o.combatNoticeAt=nil
        if view.preview then view.combatNoticePreviewAt=nil end
        return
    end
    local now=GetTime()
    local elapsed,hold
    local isEnter=n.combatEvent=="PLAYER_REGEN_DISABLED"
    local holdEnabled=isEnter and o.module and o.module.showDuringCombat==true
    if view.preview then
        -- Show both sequences in turn without changing combat or playing sounds.
        view.combatNoticePreviewAt=view.combatNoticePreviewAt or now
        local phase=(now-view.combatNoticePreviewAt)%4.75
        if isEnter then
            hold=holdEnabled and phase<2.25
            if hold or phase<2 then elapsed=phase end
        elseif phase>=2.25 and phase<4.5 then elapsed=phase-2.25 end
    else
        hold=holdEnabled and InCombatLockdown()
        if o.combatNoticeAt then elapsed=now-o.combatNoticeAt end
    end
    local duration,fade=n.noticeDuration or 2,n.noticeFade or 0
    if not hold and (not elapsed or elapsed>=duration+fade) then
        if f:IsShown() then f:Hide() end
        o.combatNoticeAt=nil;return
    end
    local lastFrame=(n.frames or 36)-1
    if hold then lastFrame=math.min(lastFrame,ENTER_HOLD_FRAME) end
    local frame=elapsed and math.min(lastFrame,math.floor(math.max(0,elapsed)*(n.fps or 24))) or lastFrame
    if hold and frame==lastFrame and not view.preview then o.combatNoticeAt=nil end
    local columns,rows=n.columns or 6,n.rows or 6
    local column,row=frame%columns,math.floor(frame/columns)
    if o.noticeFrame~=frame or o.noticeColumns~=columns or o.noticeRows~=rows then
        o.texture:SetTexCoord(column/columns,(column+1)/columns,row/rows,(row+1)/rows)
        o.texture:SetVertexColor(1,1,1,1)
        o.noticeFrame,o.noticeColumns,o.noticeRows=frame,columns,rows
    end
    local alpha=(hold or elapsed<duration) and 1 or 1-(elapsed-duration)/fade
    alpha=(n.alpha or 1)*alpha
    if o.noticeAlpha~=alpha then f:SetAlpha(alpha);o.noticeAlpha=alpha end
    if not f:IsShown() then f:Show() end
end
function N.Event(view,event)
    if view.preview then return end
    if event~="PLAYER_REGEN_DISABLED" and event~="PLAYER_REGEN_ENABLED" then return end
    local group=view.nodes.combatNotices
    if not group or group.removed or group.spec.enabled==false then return end
    local entering=event=="PLAYER_REGEN_DISABLED"
    local id=entering and "combatNoticeEnter" or "combatNoticeLeave"
    if group.spec.showDuringCombat==true then
        local previous=view.nodes[entering and "combatNoticeLeave" or "combatNoticeEnter"]
        if previous and not previous.removed then
            previous.combatNoticeAt=nil
            previous.frame:Hide()
        end
    end
    local o=view.nodes[id]
    if not o or o.removed or o.spec.enabled==false then return end
    o.combatNoticeAt=GetTime();N.Paint(view,o)
    if group.spec.soundEnabled~=false and PlaySoundFile then PlaySoundFile(ART.."Text.ogg","Dialog") end
end
