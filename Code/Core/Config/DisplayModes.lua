local _,M=...
local D={}
M.DisplayModes=D
local art="Interface\\AddOns\\MangUI\\Assets\\Player\\Minimal\\"

local healthStart={43/255,94/255,81/255,1}
local healthEnd={139/255,174/255,115/255,1}
D.defaultBackgroundColor={.10,.12,.16,.9}
function D.UsesPowerColor(n)
    return n.id=="minimalPower" or n.id=="minimalPowerValue" or n.id=="minimalPowerPercent"
end

function D.IsValueText(n)
    return n and n.modeMinimal and n.kind=="text"
end

function D.CanHideHealthText(n)
    return n and (n.id=="playerHealthPercent" or n.id=="minimalHealthValue" or n.id=="minimalHealthPercent")
end

function D.IsBar(node)
    return node and (node.id=="minimalHealth" or node.id=="minimalPower")
end

function D.Minimal()
    return M.db and M.db.displayMode=="minimal"
end

local function Add(nodes,id,kind,binding,label,x,y,width,height,layer,extra)
    local node={id=id,kind=kind,binding=binding,label=label,x=x,y=y,width=width,height=height,
        parent="root",treeParent="mainComposite",scope="player",unit="player",
        anchor="CENTER",point="CENTER",scale=1,scaleReference=1,layer=layer,
        enabled=true,modeMinimal=true,color={1,1,1,1},rules={},conditions={}}
    for key,value in pairs(extra) do node[key]=value end
    nodes[#nodes+1]=node
end

function D.Ensure(design)
    local main
    local present={}
    for _,node in ipairs(design.nodes) do present[node.id]=node;if node.id=="mainComposite" then main=node end end
    if not main then return end
    local generated={}
    local function Bar(id,binding,label,width,y)
        local x=-150+width/2
        Add(generated,id.."Frame","texture","static",label,x,y,width,24,19,
            {file=art..id.."Frame.tga",internal=true,parent=id,x=0,y=0})
        Add(generated,id,"bar",binding,label,x,y,width,24,20,
            {file=art..id..".tga",alphaFill=true,smooth=true,smoothDuration=.2})
        Add(generated,id.."Value","text",binding.."Text",label.."数值",x,y,width-20,16,21,
            {text="%p",fontSize=13,justify="LEFT",outline="OUTLINE"})
        Add(generated,id.."Percent","text",binding.."Percent",label.."百分比",x,y,width-20,16,22,
            {text="%c%",fontSize=13,justify="RIGHT",outline="OUTLINE"})
    end
    Bar("minimalHealth","health","生命条",300,-185)
    Bar("minimalPower","power","能量条",200,-205)
    for _,node in ipairs(generated) do
        if not present[node.id] then
            if node.parent=="root" then node.mainScaleFactor=(main.scale or .6)/.6 end
            design.nodes[#design.nodes+1]=node
            present[node.id]=node
        end
    end
    local health,power=present.minimalHealth,present.minimalPower
    if health.healthGradient==nil then health.healthGradient=true end
    health.healthColor=health.healthColor or M.Copy(healthStart)
    health.healthGradientEnd=health.healthGradientEnd or M.Copy(healthEnd)
    power.healthGradient,power.healthColor,power.healthGradientEnd=nil,nil,nil
end

function D.Visible(node,index,minimal)
    if minimal==nil then minimal=D.Minimal() end
    if node.modeMinimal then return minimal end
    if not minimal or M:ModuleID(node,index)~="mainComposite" then return true end
    return node.id=="mainComposite" or node.id=="playerResources" or node.parent=="playerResources"
end

local projections=setmetatable({},{__mode="k"})
function D.RenderDesign(design)
    if design.modeProjection then return design end
    local index={}
    for _,node in ipairs(design.nodes) do index[node.id]=node end
    local projection=projections[design] or {nodes={},modeProjection=true}
    local count=0
    for _,node in ipairs(design.nodes) do
        if D.Visible(node,index) or (node.kind=="group" and not node.modeMinimal) then
            count=count+1;projection.nodes[count]=node
        end
    end
    for i=#projection.nodes,count+1,-1 do projection.nodes[i]=nil end
    projections[design]=projection
    return projection
end

-- The mode picker renders a copy of each profile, without applying it.
function D.MainPreviewDesign(mode)
    local minimal=mode=="minimal"
    local profile=(minimal==D.Minimal()) and M.db or M.db.inactiveDesign
    if not profile or not profile.design then return end
    local index,include={},{}
    for _,n in ipairs(profile.design.nodes) do index[n.id]=n end
    for _,n in ipairs(profile.design.nodes) do
        if n.kind~="hitbox" and M:ModuleID(n,index)=="mainComposite"
            and (n.kind=="group" or D.Visible(n,index,minimal)) then
            local parent=n
            while parent and not include[parent.id] do
                include[parent.id]=true;parent=index[parent.parent]
            end
        end
    end
    local design={nodes={},modeProjection=true}
    for _,n in ipairs(profile.design.nodes) do
        if include[n.id] then design.nodes[#design.nodes+1]=M.Copy(n) end
    end
    return design
end

local profileFields={
    "design","moduleDefaults","otherMonitorEquipmentOverrides","otherMonitorEquipmentEntries","otherMonitorEquipmentTimers",
    "playerSkillMonitorsByCharacter","playerSkillMonitorCharacter","playerSkillMonitorsByClass","playerSkillMonitorClass",
    "playerOtherMonitorsByCharacter","playerOtherMonitorCharacter","playerOtherMonitorsByClass","playerOtherMonitorClass",
    "commonItemsShared","commonItemsByClass","commonItemsClass","commonItemsUnified",
    "receivedBuffsShared","receivedBuffsByClass","receivedBuffsClass",
    "raidBuffsShared","raidBuffsByClass","raidBuffsClass","raidBuffsUnified",
    "raidVulnerabilityShared","raidVulnerabilityByClass","raidVulnerabilityClass","raidVulnerabilityUnified",
}
function D.Other(mode)
    return mode=="minimal" and "standard" or "minimal"
end

function D.Profile(source)
    local result={}
    for _,key in ipairs(profileFields) do result[key]=source[key] end
    return result
end

function D.ApplyStartingLayout(node)
    if node.id=="mainComposite" then node.moveX,node.moveY=0,0
    elseif node.id=="playerResources" then node.x,node.y=0,-135 end
end

function D.InitProfiles(db)
    local other=D.Other(db.displayMode)
    local inactive=db.inactiveDesign
    if type(inactive)=="table" and type(inactive.design)=="table" and type(inactive.design.nodes)=="table" then return end
    inactive=M.Copy(D.Profile(db))
    local layouts=db.modeLayouts
    local layout=type(layouts)=="table" and layouts[other]
    for _,node in ipairs(inactive.design.nodes) do
        local saved=type(layout)=="table" and layout[node.id]
        if type(saved)=="table" then
            node.x,node.y,node.moveX,node.moveY=saved.x,saved.y,saved.moveX,saved.moveY
            node.mainScaleFactor=saved.mainScaleFactor or node.mainScaleFactor
            if node.id=="mainComposite" then node.scale=saved.scale or node.scale end
        elseif other=="minimal" then
            D.ApplyStartingLayout(node)
        end
    end
    db.inactiveDesign=inactive
    db.modeLayouts=nil
end

function D.CharacterProfile(root,mode)
    if not root.designModes then
        local original={monitors=type(root.monitors)=="table" and root.monitors or {},attackVoiceID=root.attackVoiceID}
        root.designModes={standard=original,minimal=M.Copy(original)}
        root.monitors=nil;root.attackVoiceID=nil
    end
    return root.designModes[mode or (D.Minimal() and "minimal" or "standard")]
end

function D.SeedCharacterProfiles(root)
    if root.designModesSeeded then return end
    root.designModes[D.Other(M.db.displayMode)]=M.Copy(D.CharacterProfile(root))
    root.designModesSeeded=true
end

function D.FlushEditors()
    local panel=M.editor and M.editor.skillMonitorPanel
    if panel then
        panel:FinishDrag(false)
        for _,row in ipairs(panel.rows) do row.edit:ClearFocus();row.shortcutEdit:ClearFocus() end
    end
    for _,monitor in ipairs({M.PlayerOtherMonitor,M.CommonItems,M.ReceivedBuffs,M.RaidBuffMonitor,M.RaidVulnerability}) do
        if monitor.FlushEditor then monitor.FlushEditor() end
    end
end

function D.Switch(mode)
    if not M:CanEdit() or M.moveMode or (mode~="standard" and mode~="minimal") then return end
    if (D.Minimal() and "minimal" or "standard")==mode then return end
    D.FlushEditors()
    M:SaveDesignMonitors()
    if M.EditorUndo then M.EditorUndo.Clear() end
    local db=M.db
    D.InitProfiles(db)
    local incoming=db.inactiveDesign
    db.inactiveDesign=D.Profile(db)
    for _,key in ipairs(profileFields) do db[key]=incoming[key] end
    db.displayMode=mode
    M.PlayerSkillMonitor.profileBindings={}
    M:BindDesignMonitors()
    M.selection="mainComposite";M.multi={mainComposite=true}
    M:Commit()
end
