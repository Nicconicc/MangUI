local _,M=...
local B={alpha={},mouse={},roots={},draw={}}
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
        for layer in pairs(state.values) do frame:DisableDrawLayer(layer) end
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
        if state[property[1]]~=nil then frame[property[2]](frame,false) end
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
                if InCombatLockdown() then B.pending=true;return end
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
        for _,property in ipairs(state.properties) do
            if not state.active or state[property[1]]==nil then
                state[property[1]]=ReadInput(frame,property[1])
            end
        end
        state.active=true
        DisableInput(frame,state)
    elseif state.active then
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
                if frame.HookScript then frame:HookScript("OnShow",function()B.Queue()end) end
                if hooksecurefunc then
                    for _,method in ipairs({"CreateTargetofTarget","CreateSpellbar","SetStatusBarTexture","SetParent"}) do
                        if type(frame[method])=="function" then hooksecurefunc(frame,method,function()B.Queue()end) end
                    end
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
function B.Apply(force)
    if not M.db or B.applying then return end
    if InCombatLockdown() then B.pending=true;return end
    local signature=table.concat({tostring(Enabled("mainComposite")),tostring(Enabled("wa8d650f8d3a")),
        tostring(Enabled("petComposite")),tostring(Enabled("focusComposite")),tostring(Enabled("totComposite")),
        tostring(Enabled("partyFrames")),tostring(IsInRaid and IsInRaid() or false)},"|")
    if not force and not B.pending and not B.scanDirty and B.signature==signature then return end
    B.pending=nil;B.scanDirty=nil
    local roots=CollectRoots()
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
    local visuals,inputs,castFrames={},{},{}
    local function Visit(frame,root,depth)
        if depth>40 or (frame~=root and roots[frame]~=nil) then return end
        inputs[frame]=true
        if root==PlayerCastingBarFrame or root==CastingBarFrame or root==OverlayPlayerCastingBarFrame then castFrames[frame]=true end
        if not paths[frame] then visuals[frame]=true end
        if frame.GetRegions then
            for _,region in ipairs({frame:GetRegions()}) do visuals[region]=true end
        end
        if frame.GetStatusBarTexture then
            local texture=frame:GetStatusBarTexture()
            if texture then visuals[texture]=true end
        end
        if frame.GetChildren then
            for _,child in ipairs({frame:GetChildren()}) do Visit(child,root,depth+1) end
        end
    end
    for frame,active in pairs(roots) do if active then Visit(frame,frame,0) end end
    B.applying=true
    local ok,err=pcall(function()
        for object in pairs(visuals) do Alpha(object,true) end
        for object,state in pairs(B.alpha) do if state.active and not visuals[object] then Alpha(object,false) end end
        for frame in pairs(castFrames) do CastLayers(frame,true) end
        for frame,state in pairs(B.draw) do if state.active and not castFrames[frame] then CastLayers(frame,false) end end
        for frame in pairs(inputs) do Input(frame,true) end
        for frame,state in pairs(B.mouse) do if state.active and not inputs[frame] then Input(frame,false) end end
    end)
    B.applying=nil
    if not ok then B.scanDirty=true;error(err) end
    B.signature=signature
end
function B.Queue()
    if not M.db then return end
    B.scanDirty=true
    if B.queued then return end
    if InCombatLockdown() then B.pending=true;return end
    if C_Timer and C_Timer.After then
        B.queued=true
        C_Timer.After(0,function()
            B.queued=nil;M:Safe("暴雪框体显示",B.Apply)
        end)
    else M:Safe("暴雪框体显示",B.Apply) end
end
function B.Start()
    if B.events then return end
    local frame=CreateFrame("Frame");B.events=frame
    for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","GROUP_ROSTER_UPDATE",
        "PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","UNIT_PET","CVAR_UPDATE"}) do pcall(frame.RegisterEvent,frame,event) end
    frame:SetScript("OnEvent",function(_,event)
        if event=="PLAYER_REGEN_ENABLED" then M:Safe("暴雪框体显示",B.Apply,true)
        else B.Queue() end
    end)
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("EditMode.Enter",B.Queue,B)
        EventRegistry:RegisterCallback("EditMode.Exit",B.Queue,B)
    end
end
function M:BlizzardVisibility()
    B.Start();B.Apply()
end
