local _,M=...
local U={sessions={}};M.EditorUndo=U
local function Context()
    local e=M.editor
    if not e or not e.window or not e.canvas or not e.window:IsShown() or not e.canvas:IsShown() or M.moveMode
        or (M.general and M.general:IsShown()) then return end
    local n=M.byID and M.byID[M.selection]
    local module=n and M:ModuleID(n)
    if not module then return end
    local selected={}
    for id,on in pairs(M.multi or {})do if on then selected[#selected+1]=id end end
    table.sort(selected)
    return M.selection..":"..table.concat(selected,","),module
end
local function Snapshot(module)
    local nodes={}
    for _,n in ipairs(M.db.design.nodes)do
        if M:ModuleID(n)==module then nodes[#nodes+1]=M.Copy(n) end
    end
    return nodes
end
local function Equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)=="number" then return math.abs(a-b)<.0000001 end
    if type(a)~="table" then return a==b end
    for key,value in pairs(a)do if not Equal(value,b[key]) then return false end end
    for key in pairs(b)do if a[key]==nil then return false end end
    return true
end
function U.Available()
    local key,module=Context();local s=U.session
    return s and s.key==key and s.module==module and #s.stack>0 and not s.transaction
        and not InCombatLockdown() or false
end
function U.UpdateButton()
    local b=M.editor and M.editor.undoButton
    if not b then return end
    local enabled=U.Available()
    b:SetEnabled(enabled);b.icon:SetDesaturated(not enabled)
    b.icon:SetVertexColor(enabled and 1 or .55,enabled and 1 or .55,enabled and 1 or .55,enabled and 1 or .65)
end
function U.Suspend()
    local s=U.session
    if s and s.transaction then U.Finish(s.transaction)end
    U.session=nil
    if U.colorSource then
        U.colorSource=nil
        if ColorPickerFrame then ColorPickerFrame:Hide() end
    end
    U.UpdateButton()
end
function U.Clear()
    U.Suspend();U.sessions={};U.UpdateButton()
end
function U.Sync()
    if U.syncing or(U.session and U.session.finishing)then U.UpdateButton();return end
    local key,module=Context()
    if not key then U.Suspend();return end
    local s=U.session
    if not s or s.key~=key or s.module~=module then
        U.syncing=true
        U.Suspend()
        local saved=U.sessions[module]
        -- A fresh active wrapper invalidates stale picker/drag callbacks while
        -- preserving this module's stack across selections and tab visits.
        s={key=key,module=module,stack=saved and saved.stack or {},baseline=Snapshot(module)}
        U.sessions[module]=s;U.session=s
        U.syncing=nil
    else
        -- Renderer synchronization can update derived geometry after Commit.
        if not(s.transaction and M.commitRefreshToken)then s.baseline=Snapshot(module)end
    end
    U.UpdateButton()
end
function U.Record()
    local key,module=Context();local s=U.session
    -- A deferred drag/picker commit may finish after selection has changed.
    -- Record it against the original transaction's module before switching.
    if s and s.transaction then module=s.module
    elseif not key then U.Suspend();return
    elseif not s or s.key~=key or s.module~=module then U.Sync();return end
    if s.replaying then return end
    local current=Snapshot(module)
    if Equal(current,s.baseline) then return end
    if not s.transaction or not s.transactionPushed then
        s.stack[#s.stack+1]=s.baseline
        if #s.stack>10 then
            local dropped=table.remove(s.stack,1)
            if s.transaction then s.transactionDropped=dropped end
        end
        if s.transaction then s.transactionPushed=true end
    end
    s.baseline=current;U.UpdateButton()
end
function U.Begin(source)
    local active=U.session
    if active and active.transaction then U.Finish(active.transaction)end
    U.Sync();local s=U.session
    if not s then return end
    s.transaction=source;s.transactionOriginal=s.baseline;s.transactionPushed=false;s.transactionDropped=nil
    U.UpdateButton()
end
function U.Finish(source)
    local s=U.session
    if not s or s.transaction~=source or s.finishing then return end
    s.finishing=true
    if M.commitRefreshToken then M:FlushCommit() end
    -- A cancelled picker/drag that returns to its start adds no undo action.
    if s.transactionPushed and Equal(s.baseline,s.transactionOriginal) then
        table.remove(s.stack)
        if s.transactionDropped then table.insert(s.stack,1,s.transactionDropped) end
    end
    s.transaction=nil;s.transactionOriginal=nil;s.transactionPushed=nil;s.transactionDropped=nil
    s.finishing=nil
    U.UpdateButton()
end
function U.Undo()
    if not U.Available() or not M:CanEdit() then return false end
    local s=U.session;local previous=table.remove(s.stack)
    local restore,seen,nodes={},{},{}
    for _,n in ipairs(previous)do restore[n.id]=n end
    for _,n in ipairs(M.db.design.nodes)do
        if M:ModuleID(n)==s.module then
            if restore[n.id] then nodes[#nodes+1]=M.Copy(restore[n.id]);seen[n.id]=true end
        else nodes[#nodes+1]=n end
    end
    for _,n in ipairs(previous)do if not seen[n.id] then nodes[#nodes+1]=M.Copy(n) end end
    M.db.design.nodes=nodes;s.replaying=true
    M:Commit()
    s.replaying=nil;s.baseline=Snapshot(s.module);U.UpdateButton()
    return true
end
function U.Attach(e)
    local button=CreateFrame("Button",nil,e.input);e.undoButton=button
    button:SetSize(25.6,25.6);button:SetPoint("TOPRIGHT",e.canvas,"TOPRIGHT",-8,-8)
    button:SetFrameLevel(e.input:GetFrameLevel()+10)
    button.icon=button:CreateTexture(nil,"ARTWORK");button.icon:SetAllPoints()
    button.icon:SetAtlas("BattleBar-SwapPetIcon",false)
    button:SetScript("OnClick",U.Undo)
    button:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_LEFT")
        GameTooltip:SetText(M:T("撤销"))
        GameTooltip:AddLine(M:T("每个模块保留10次调节；切换子分类或页签后保留，关闭设置后清空。"),1,1,1,true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function()GameTooltip:Hide()end)
    button:RegisterEvent("PLAYER_REGEN_DISABLED");button:RegisterEvent("PLAYER_REGEN_ENABLED")
    button:SetScript("OnEvent",U.UpdateButton)
    U.UpdateButton()
end
