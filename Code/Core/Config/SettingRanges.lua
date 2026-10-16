local _,M=...
local R={};M.SettingRanges=R
local points={CENTER={0,0},LEFT={-1,0},RIGHT={1,0},TOP={0,1},BOTTOM={0,-1},
    TOPLEFT={-1,1},TOPRIGHT={1,1},BOTTOMLEFT={-1,-1},BOTTOMRIGHT={1,-1}}
local function Part(index,compound)
    for _,n in pairs(index)do if n.compound==compound then return n end end
end
local function Bar(index,parent,binding)
    if not parent then return end
    for _,n in pairs(index)do
        if n.parent==parent.id and n.kind=="bar" and n.binding==binding then return n end
    end
end
local function Center(n,axis,size)
    local dimension=axis=="x" and "width" or "height"
    local point=(points[n.point] or points.CENTER)[axis=="x" and 1 or 2]
    return (n[axis] or 0)-point*(size or n[dimension] or 2)/2
end
function R.ChatGap(size)
    size=size or 64
    local half=math.floor(size/2)
    return math.floor(math.max(1-size,-half)),math.ceil(half)
end
function R.FocusCast(index)
    index=index or M.byID
    local hp,cast=Part(index,"focusHP"),Part(index,"focusCast")
    local health,bar=Bar(index,hp,"health"),Bar(index,cast,"cast")
    if not health or not bar then return {width={64,512},x={150,500},y={-125,75}} end
    local hs=(hp.scale or 1)*(health.scale or 1)
    local cs=(cast.scale or 1)*(bar.scale or 1)
    local maximum=math.max(1,health.width*hs/cs)
    local width=M.Clamp(bar.width or 173,math.min(64,maximum),maximum)
    local hc=(hp.x or 0)*(hp.scale or 1)+Center(health,"x")*hs
    local bc=Center(bar,"x",width)
    local left,right=hc-health.width*hs/2,hc+health.width*hs/2
    local cy=(hp.y or 0)*(hp.scale or 1)+Center(health,"y")*hs
    local minX=(left-(bc-width/2)*cs)/(cast.scale or 1)
    local maxX=(right-(bc+width/2)*cs)/(cast.scale or 1)
    local minY=(cy-150)/(cast.scale or 1)
    local maxY=(cy+50)/(cast.scale or 1)
    return {width={math.min(64,maximum),maximum},
        x={math.floor(minX+1e-7),math.ceil(maxX-1e-7)},
        y={math.floor(minY+1e-7),math.ceil(maxY-1e-7)}}
end
function R.Range(n,field,index)
    if not n then return end
    index=index or M.byID
    if n.compound=="partyFrames" then
        if field=="partyPlayerX" then return -150,150 end
        if field=="partySpacing" then return 45,150 end
    elseif n.compound=="chatButtons" then
        if field=="buttonSpacing" then return R.ChatGap(n.iconSize) end
        if field=="fontYOffset" then local half=(n.iconSize or 64)/2;return -40,math.ceil(half) end
    elseif n.compound=="targetDistance" then
        if field=="distanceX" then return -150,150 end
        if field=="distanceY" then return -40,40 end
    end
    if n.id=="playerResources" and field=="resourceSpacing" then return -20,20 end
    if n.id=="bossHPPercent" then
        if field=="x" then return -300,300 end
        if field=="y" then return -60,60 end
    elseif n.id=="bossCast" and field=="y" then return -160,40 end
    if n.compound=="focusCast" and (field=="x" or field=="y") then return unpack(R.FocusCast(index)[field]) end
    local parent=index and index[n.parent]
    if parent and parent.compound=="focusCast" and n.binding=="cast" and field=="width" then
        return unpack(R.FocusCast(index).width)
    end
    if field~="x" and field~="y" then return end
    if n.id=="wa88e7259b1c" then return end -- Target buffs may move beyond preview canvas edges.
    if M.moduleIDs[n.id] then return end -- Whole modules move freely on the screen.
    if M.MainBarLayout.parts[n.id] then
        if field=="x" then return M.MainBarLayout.XRange(n,index) end
        -- The four strips slide into the portrait rim horizontally only.
        return n.y or 0,n.y or 0
    end
    if M:ModuleID(n,index)~="mainComposite" then return end
    if M.MainCanvasRange then return M:MainCanvasRange(n,field,index) end
end
function R.Clamp(n,field,value,index)
    local lo,hi=R.Range(n,field,index)
    return lo and M.Clamp(value,lo,hi) or value
end
-- Only these stored fields have non-canvas limits in Range. Canvas offsets
-- constrain gestures, never loading/rendering. Keep this list with Range.
local compoundLimits={partyFrames={"partyPlayerX","partySpacing"},chatButtons={"buttonSpacing","fontYOffset"},
    targetDistance={"distanceX","distanceY"},focusCast={"x","y"}}
local nodeLimits={playerResources={"resourceSpacing"},bossHPPercent={"x","y"},bossCast={"y"}}
function R.ClampAll(index)
    -- Rim position/size changes must preserve contact for all four strips.
    M.MainBarLayout.ClampAll(index)
    -- Width affects the legal cast X interval; clamp it first, including backing.
    for _,n in pairs(index)do
        if n.binding=="cast" and index[n.parent] and index[n.parent].compound=="focusCast" then
            n.width=R.Clamp(n,"width",n.width,index)
        end
    end
    for _,n in pairs(index)do
        local fields=compoundLimits[n.compound] or nodeLimits[n.id]
        if fields then
        local mainModule=M:ModuleID(n,index)=="mainComposite"
        for _,field in ipairs(fields)do
            -- Canvas bounds constrain editor gestures only. Loading/rendering
            -- must not alter saved main-module offsets using another viewport.
            local canvasOffset=(field=="x" or field=="y") and mainModule
            if type(n[field])=="number" and not canvasOffset then n[field]=R.Clamp(n,field,n[field],index) end
        end
        end
    end
end
