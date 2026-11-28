local _,M=...
local D={}
M.DisplayModes=D
local art="Interface\\AddOns\\MangUI\\Assets\\Player\\Minimal\\"

local healthStart={43/255,94/255,81/255,1}
local healthEnd={139/255,174/255,115/255,1}
D.defaultBackgroundColor={.10,.12,.16,.9}
function D.UsesPowerColor(n)
    return n.id=="minimalPower" or n.id=="minimalPowerValue" or n.id=="minimalPowerPercent"
        or n.id=="minimalThirdResourceFill"
end

function D.StandardPowerBars()
    local profile=M.db
    if D.Minimal() then profile=profile.inactiveDesign end
    local design=profile and profile.design or M.recordedDefaults or M.defaults
    local primary,third
    for _,node in ipairs(design.nodes) do
        if node.id=="wa58141a60dd" then primary=node
        elseif node.id=="playerThirdResourceFill" then third=node end
        if primary and third then break end
    end
    return primary,third
end

function D.IsValueText(n)
    return n and n.modeMinimal and n.kind=="text"
end

function D.CanHideHealthText(n)
    return n and (n.id=="playerHealthPercent" or n.id=="minimalHealthValue" or n.id=="minimalHealthPercent")
end

function D.IsBar(node)
    return node and (node.id=="minimalHealth" or node.id=="minimalPower" or node.id=="minimalThirdResourceFill")
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
    local third="minimalThirdResource"
    local thirdLabel="玩家第三资源条"
    Add(generated,third,"group","static",thirdLabel,-50,-229,2,2,18,{internal=true})
    Add(generated,third.."Fill","bar","power",thirdLabel,0,0,200,24,20,
        {parent=third,file=art.."minimalPower.tga",alphaFill=true,powerColor=true,
            smooth=true,smoothDuration=.2,thirdResource=true})
    Add(generated,third.."FillFrame","texture","static",thirdLabel,0,0,200,24,19,
        {parent=third.."Fill",file=art.."minimalPowerFrame.tga",internal=true,thirdResource=true})
    Add(generated,third.."Value","text","thirdResourceValue",thirdLabel,8,0,80,22,22,
        {parent=third.."Fill",point="LEFT",anchor="RIGHT",font="Myriad",fontSize=13,
            outline="OUTLINE",justify="LEFT",thirdResource=true,thirdResourceValue=true})
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

-- Preset from the Forever minimal layout. Other modules only supply layout values.
local monitorScale=0.66000004053116
local fontPath="Interface\\AddOns\\MangUI\\Assets\\Fonts\\Myriad.ttf"
local minimalDefaults={
    mainComposite={moveX=-38.280000829697,moveY=-133.51999673843,shakeEnabled=true},
    playerResources={x=73,y=55,mainScaleFactor=1,hideWithoutTarget=false},
    minimalHealth={x=29,y=-114,width=240,height=18,scale=2.2000000476837,mainScaleFactor=1,
        materialName="Solid",materialPath="Interface\\Buttons\\WHITE8X8",cropX=0,cropY=0,locked=false,reverse=false,
        healthGradient=false,healthColor={0.8901960849762,0.92549020051956,1,1},
        healthGradientEnd={0.30196079611778,0.68235296010971,0.33333334326744,1},
        barBackgroundColor={0.098039217293262,0.10588235408068,0.16078431904316,0.81249928474426}},
    minimalPower={x=-5,y=-146,width=180,height=18,scale=1.8999999761581,mainScaleFactor=1,
        materialName="Wglass",materialPath="Interface\\AddOns\\MangUI\\Assets\\Library\\PartyFrames\\Wglass.tga",
        barBackgroundColor={0.10196078568697,0.12156862765551,0.16078431904316,0.8072909116745}},
    minimalHealthValue={x=-45,y=-220,fontName="Myriad",fontPath=fontPath,fontSize=20,mainScaleFactor=1},
    minimalHealthPercent={x=-386,y=-222,fontName="Myriad",fontPath=fontPath,fontSize=20,mainScaleFactor=1,enabled=false},
    minimalPowerValue={x=-236,y=-285,fontName="Myriad",fontPath=fontPath,fontSize=23.333333333333,mainScaleFactor=1},
    minimalPowerPercent={x=-290,y=-280,fontName="Myriad",fontPath=fontPath,fontSize=20,mainScaleFactor=1},
    wa8d650f8d3a={x=0,y=-820.83333333333},
    petComposite={x=-1098.3428571429,y=-1547.6071428571},
    totComposite={x=1015.2952380952,y=-1538.0571428571},
    focusComposite={x=-1717.3904761905,y=-1540.8571428571},
    partyFrames={x=359.99999441206,y=-382.4999916181},
    playerSkillMonitor={x=-34.242428894761,y=-671.51511150506,scale=monitorScale},
    playerOtherMonitor={x=-114.36362798943,y=-671.51511150506,scale=monitorScale},
    cooldownMonitor={x=0,y=-833.33328215763,scale=monitorScale},
    receivedBuffs={x=134.30299773667,y=-504.84845507353,scale=monitorScale},
    raidVulnerability={x=-271.69694085248,y=-504.84845507353,scale=monitorScale},
    raidBuffs={x=484.84845507353,y=-929.54539592601,scale=monitorScale},
    commonItems={x=0,y=-929.09085326287,scale=monitorScale},
    targetDistance={x=-230,y=-165},
    targetDistanceNumber={x=0,y=-55},
    targetThreat={x=-500,y=-366.66666666667},
    chatButtons={x=400,y=35},
    combatNotices={x=-383.33333333333,y=-233.33333333333},
}

function D.ApplyDefault(node)
    local preset=minimalDefaults[node.id]
    if preset then
        for key,value in pairs(preset) do node[key]=M.Copy(value) end
    end
    return node
end

function D.ApplyDefaults(design)
    D.Ensure(design)
    for _,node in ipairs(design.nodes) do D.ApplyDefault(node) end
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
    if panel and panel.edit then panel.edit:ClearFocus() end
    if M.editor then M.editor.skillEntry=nil end
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
