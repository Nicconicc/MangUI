local _,M=...
local B={alpha={},mouse={},roots={},draw={},dirtyRoots={},unreadableInput={}}
M.BlizzardFrames=B

-- Leave native Show/Hide, parents, anchors and event registrations intact.
-- Suppress visual regions and input; release only the values owned here.
local function Alpha(object,wanted)
    if not object.GetAlpha or not object.SetAlpha then return end
    local state=B.alpha[object]
    if not state then
        if not wanted then return end
        state={};B.alpha[object]=state
        if hooksecurefunc then
            hooksecurefunc(object,"SetAlpha",function(_,value)
                if not state.active or B.applying then return end
                state.value=value
                B.applying=true;object:SetAlpha(0);B.applying=nil
            end)
        end
    end
    if wanted then
        if not state.active then state.value=object:GetAlpha();state.active=true end
        local value=object:GetAlpha()
        if not M.Compat.Readable(value) or value~=0 then object:SetAlpha(0) end
    elseif state.active then
        state.active=nil;object:SetAlpha(state.value)
    end
end
-- Engine alpha animations bypass SetAlpha hooks. Gate the native cast layers
-- without stopping animations or interfering with their completion scripts.
local castLayers={"BACKGROUND","BORDER","ARTWORK","OVERLAY","HIGHLIGHT"}
local function CastLayers(frame,wanted)
    if not frame.IsDrawLayerEnabled or not frame.DisableDrawLayer or not frame.EnableDrawLayer then return end
    local state=B.draw[frame]
    if not state then
        if not wanted then return end
        state={values={}};B.draw[frame]=state
        if hooksecurefunc then
            local function Changed(layer,value)
                if not state.active or state.writing or not M.Compat.Readable(layer) then return end
                if type(layer)~="string" or not M.Compat.Readable(value) or type(value)~="boolean" then return end
                state.values[layer]=value
                state.writing=true;frame:DisableDrawLayer(layer);state.writing=nil
            end
            hooksecurefunc(frame,"EnableDrawLayer",function(_,layer)Changed(layer,true)end)
            hooksecurefunc(frame,"DisableDrawLayer",function(_,layer)Changed(layer,false)end)
            if frame.SetDrawLayerEnabled then
                hooksecurefunc(frame,"SetDrawLayerEnabled",function(_,layer,value)
                    if M.Compat.Readable(value) and value==nil then value=false end
                    Changed(layer,value)
                end)
            end
        end
    end
    if wanted then
        for _,layer in ipairs(castLayers) do
            if not state.active or state.values[layer]==nil then
                local ok,value=pcall(frame.IsDrawLayerEnabled,frame,layer)
                if ok and M.Compat.Readable(value) and type(value)=="boolean" then state.values[layer]=value end
            end
        end
        state.active=true;state.writing=true
        for layer in pairs(state.values) do
            local ok,enabled=pcall(frame.IsDrawLayerEnabled,frame,layer)
            if not ok or not M.Compat.Readable(enabled) or enabled~=false then frame:DisableDrawLayer(layer) end
        end
        state.writing=nil
    elseif state.active then
        state.active=nil
        for layer,value in pairs(state.values) do
            if value then frame:EnableDrawLayer(layer) else frame:DisableDrawLayer(layer) end
        end
        state.values={}
    end
end
local function InputProperties(frame)
    if frame.IsMouseClickEnabled and frame.SetMouseClickEnabled
        and frame.IsMouseMotionEnabled and frame.SetMouseMotionEnabled then
        return {{"IsMouseClickEnabled","SetMouseClickEnabled"},{"IsMouseMotionEnabled","SetMouseMotionEnabled"}}
    elseif frame.IsMouseEnabled and frame.EnableMouse then
        return {{"IsMouseEnabled","EnableMouse"}}
    end
end
local function ReadInput(frame,getter)
    local ok,value=pcall(frame[getter],frame)
    if ok and M.Compat.Readable(value) and type(value)=="boolean" then return value end
    -- Unknown is not false. Never change input that we cannot later restore.
end
local function DisableInput(frame,state)
    for _,property in ipairs(state.properties) do
        if state[property[1]]~=nil and ReadInput(frame,property[1])~=false then
            frame[property[2]](frame,false)
        end
    end
end
local function Input(frame,wanted)
    local state=B.mouse[frame]
    if not state then
        if not wanted then return end
        local properties=InputProperties(frame)
        if not properties then return end
        state={properties=properties};B.mouse[frame]=state
        if hooksecurefunc then
            local function Changed(changed,value)
                if not state.active or B.applying then return end
                for _,property in ipairs(changed) do
                    local current
                    if M.Compat.Readable(value) and type(value)=="boolean" then current=value
                    else current=ReadInput(frame,property[1]) end
                    if current~=nil then state[property[1]]=current end
                end
                if InCombatLockdown() then B.scanDirty=true;B.pending=true;return end
                B.applying=true;DisableInput(frame,state);B.applying=nil
            end
            for _,property in ipairs(properties) do
                local property=property
                hooksecurefunc(frame,property[2],function(_,value)Changed({property},value)end)
            end
            if #properties==2 and frame.EnableMouse then hooksecurefunc(frame,"EnableMouse",function(_,value)Changed(properties,value)end) end
        end
    end
    if wanted then
        local unreadable
        for _,property in ipairs(state.properties) do
            if not state.active or state[property[1]]==nil then
                state[property[1]]=ReadInput(frame,property[1])
            end
            if state[property[1]]==nil then unreadable=true end
        end
        B.unreadableInput[frame]=unreadable
        state.active=true
        DisableInput(frame,state)
    elseif state.active then
        B.unreadableInput[frame]=nil
        state.active=nil
        for _,property in ipairs(state.properties) do
            local value=state[property[1]]
            if value~=nil then frame[property[2]](frame,value) end
            state[property[1]]=nil
        end
    end
end
local function Enabled(id)
    local node=M.byID and M.byID[id]
    if id=="focusComposite" then
        local interface=M.Compat.interface or 0
        if interface>=10000 and interface<20000 and interface~=16001 then return false end
    end
    return node and node.enabled~=false or false
end
local function CollectRoots()
    local roots={}
    local function Add(frame,id,allowed)
        if frame and frame.GetAlpha and frame.SetAlpha then
            roots[frame]=Enabled(id) and allowed~=false
            if not B.roots[frame] then
                B.roots[frame]=true
                if frame.HookScript then frame:HookScript("OnShow",function()B.QueueRoot(frame)end) end
                if hooksecurefunc then
                    for _,method in ipairs({"CreateTargetofTarget","CreateSpellbar","SetStatusBarTexture"}) do
                        if type(frame[method])=="function" then hooksecurefunc(frame,method,function()B.QueueRoot(frame)end) end
                    end
                    if frame.SetParent then hooksecurefunc(frame,"SetParent",function()B.Queue()end) end
                end
            end
        end
    end
    Add(PlayerFrame,"mainComposite");Add(TargetFrame,"mainComposite")
    Add(PlayerCastingBarFrame,"wa8d650f8d3a");Add(CastingBarFrame,"wa8d650f8d3a")
    Add(OverlayPlayerCastingBarFrame,"wa8d650f8d3a")
    Add(PetFrame,"petComposite");Add(FocusFrame,"focusComposite")
    Add(TargetFrameToT,"totComposite")
    if TargetFrame then Add(TargetFrame.totFrame,"totComposite") end
    Add(PartyFrame,"partyFrames")
    for i=1,4 do Add(_G["PartyMemberFrame"..i],"partyFrames") end
    local party=not (IsInRaid and IsInRaid())
    Add(CompactPartyFrame,"partyFrames",party)
    -- Some clients share this container between compact party and raid layouts.
    -- Its native raid display stays available while the party module is enabled.
    Add(CompactRaidFrameContainer,"partyFrames",party)
    return roots
end
local function SameEntries(before,after)
    if not before then return false end
    for key,value in pairs(before) do if after[key]~=value then return false end end
    for key,value in pairs(after) do if before[key]~=value then return false end end
    return true
end
local function ProtectedAncestors(roots)
    local paths={}
    -- Preserve ancestors of native units whose replacement is disabled.
    -- Hide their siblings' own regions without making those units transparent.
    for root,active in pairs(roots) do
        if not active then
            local parent=root.GetParent and root:GetParent()
            for _=1,100 do
                if not parent then break end
                paths[parent]=true
                parent=parent.GetParent and parent:GetParent()
            end
        end
    end
    return paths
end

local function ScanRoot(root,roots,paths)
    local objects={alpha={},mouse={},draw={}}
    local cast=root==PlayerCastingBarFrame or root==CastingBarFrame or root==OverlayPlayerCastingBarFrame
    local function Visit(frame,depth)
        if depth>40 or (frame~=root and roots[frame]~=nil) then return end
        objects.mouse[frame]=true
        if cast then objects.draw[frame]=true end
        if not paths[frame] then objects.alpha[frame]=true end
        if frame.GetRegions then
            for _,region in ipairs({frame:GetRegions()}) do objects.alpha[region]=true end
        end
        if frame.GetStatusBarTexture then
            local texture=frame:GetStatusBarTexture()
            if texture then objects.alpha[texture]=true end
        end
        if frame.GetChildren then
            for _,child in ipairs({frame:GetChildren()}) do Visit(child,depth+1) end
        end
    end
    Visit(root,0)
    return objects
end

local setters={alpha=Alpha,draw=CastLayers,mouse=Input}
local propertyOrder={"alpha","draw","mouse"}
local function StillOwned(coverage,kind,object)
    for _,objects in pairs(coverage) do
        if objects[kind][object] then return true end
    end
    return false
end

function B.Apply(force)
    if not M.db or B.applying then return end
    if InCombatLockdown() then
        if force then B.scanDirty=true end
        B.pending=true
        return
    end
    local roots=CollectRoots()
    local full=force or B.scanDirty or not SameEntries(B.activeRoots,roots)
    local dirty=B.dirtyRoots
    local paths
    if full or next(dirty) then
        paths=ProtectedAncestors(roots)
        full=full or not SameEntries(B.paths,paths)
    else
        B.pending=nil
        return
    end
    B.pending=nil
    B.scanDirty=nil
    B.dirtyRoots={}

    local previous=B.coverage or {}
    local coverage={}
    local wanted={alpha={},mouse={},draw={}}
    local released={alpha={},mouse={},draw={}}
    for root,active in pairs(roots) do
        if active then
            if full or dirty[root] then
                local objects=ScanRoot(root,roots,paths)
                coverage[root]=objects
                for _,kind in ipairs(propertyOrder) do
                    for object in pairs(objects[kind]) do wanted[kind][object]=true end
                    if not full and previous[root] then
                        for object in pairs(previous[root][kind]) do
                            if not objects[kind][object] then released[kind][object]=true end
                        end
                    end
                end
            else
                coverage[root]=previous[root]
            end
        end
    end
    if not full then
        -- Retry inputs with no readable baseline without revisiting their trees.
        for frame in pairs(B.unreadableInput) do
            if StillOwned(coverage,"mouse",frame) then wanted.mouse[frame]=true end
        end
    end
    B.applying=true
    local ok,err=pcall(function()
        for _,kind in ipairs(propertyOrder) do
            local set=setters[kind]
            for object in pairs(wanted[kind]) do set(object,true) end
            if full then
                for object,state in pairs(B[kind]) do
                    if state.active and not wanted[kind][object] then set(object,false) end
                end
            else
                for object in pairs(released[kind]) do
                    if not StillOwned(coverage,kind,object) then set(object,false) end
                end
            end
        end
    end)
    B.applying=nil
    if not ok then B.scanDirty=true;error(err) end
    B.activeRoots,B.paths,B.coverage=roots,paths,coverage
end
local function Schedule()
    if B.queued then return end
    if InCombatLockdown() then B.pending=true;return end
    if C_Timer and C_Timer.After then
        B.queued=true
        C_Timer.After(0,function()
            B.queued=nil;M:Safe("暴雪框体显示",B.Apply)
        end)
    else M:Safe("暴雪框体显示",B.Apply) end
end
function B.Queue()
    if not M.db then return end
    B.scanDirty=true
    Schedule()
end
function B.QueueRoot(...)
    if not M.db then return end
    for i=1,select("#",...) do
        local root=select(i,...)
        if root then B.dirtyRoots[root]=true end
    end
    Schedule()
end
local nativeFrameAddons={
    Blizzard_UnitFrame=true,Blizzard_UnitFrames=true,
    Blizzard_CompactRaidFrames=true,Blizzard_CompactPartyFrame=true,
    Blizzard_CastingBar=true,Blizzard_CastingBarFrame=true,
}
function B.Start()
    if B.events then return end
    local frame=CreateFrame("Frame");B.events=frame
    for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","GROUP_ROSTER_UPDATE",
        "PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","UNIT_PET","CVAR_UPDATE"}) do pcall(frame.RegisterEvent,frame,event) end
    frame:SetScript("OnEvent",function(_,event,arg)
        if event=="PLAYER_REGEN_ENABLED" then
            if B.pending then Schedule() end
        elseif event=="PLAYER_TARGET_CHANGED" then
            B.QueueRoot(TargetFrame,TargetFrameToT,TargetFrame and TargetFrame.totFrame)
        elseif event=="PLAYER_FOCUS_CHANGED" then
            B.QueueRoot(FocusFrame)
        elseif event=="UNIT_PET" then
            if arg=="player" then B.QueueRoot(PlayerFrame,PetFrame) end
        elseif event=="ADDON_LOADED" and not nativeFrameAddons[arg] then
            -- Discover new native roots without traversing unchanged trees.
            Schedule()
        else
            B.Queue()
        end
    end)
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("EditMode.Enter",B.Queue,B)
        EventRegistry:RegisterCallback("EditMode.Exit",B.Queue,B)
    end
end
function M:BlizzardVisibility()
    B.Start();B.Apply()
end
