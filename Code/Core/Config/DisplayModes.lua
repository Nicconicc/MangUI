local _,M=...
local D={}
M.DisplayModes=D
local art="Interface\\AddOns\\MangUI\\Assets\\Player\\Minimal\\"

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
    for _,node in ipairs(design.nodes) do present[node.id]=true;if node.id=="mainComposite" then main=node end end
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
        end
    end
end

function D.Visible(node,index)
    if node.modeMinimal then return D.Minimal() end
    if not D.Minimal() or M:ModuleID(node,index)~="mainComposite" then return true end
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

function D.Switch(mode)
    if not M:CanEdit() or M.moveMode or (mode~="standard" and mode~="minimal") then return end
    local db=M.db
    local current=D.Minimal() and "minimal" or "standard"
    if current==mode then return end
    if M.EditorUndo then M.EditorUndo.Clear() end
    db.modeLayouts=type(db.modeLayouts)=="table" and db.modeLayouts or {}
    local leaving={}
    local arriving=db.modeLayouts[mode]
    for _,node in ipairs(db.design.nodes) do
        local main=node.id=="mainComposite"
        leaving[node.id]={x=node.x,y=node.y,moveX=node.moveX,moveY=node.moveY,
            mainScaleFactor=node.mainScaleFactor,scale=main and node.scale or nil}
        local saved=arriving and arriving[node.id]
        if type(saved)=="table" then
            node.x,node.y,node.moveX,node.moveY=saved.x,saved.y,saved.moveX,saved.moveY
            node.mainScaleFactor=saved.mainScaleFactor or node.mainScaleFactor
            if main then node.scale=saved.scale or node.scale end
        elseif mode=="minimal" and node.id=="mainComposite" then
            node.moveX,node.moveY=0,0
        elseif mode=="minimal" and node.id=="playerResources" then
            node.x,node.y=0,-135
        end
    end
    db.modeLayouts[current]=leaving
    db.displayMode=mode
    M.selection="mainComposite";M.multi={mainComposite=true}
    M:Commit()
end
