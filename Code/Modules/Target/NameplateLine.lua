local _,M=...
local L={restricted=setmetatable({},{__mode="k"})};M.TargetNameplateLine=L
local C=M.Compat
local function Call(fn,...)
    if not fn then return end
    local ok,value=pcall(fn,...);if ok then return value end
end
local function Number(value)return C.Readable(value)and type(value)=="number"and value==value and math.abs(value)<1e9 and value or nil end
local function Visible(frame)
    if not frame or Call(frame.IsForbidden,frame)==true then return false end
    if C.Bool(Call(frame.IsVisible,frame))~=true then return false end
    local alpha=Call(frame.GetEffectiveAlpha or frame.GetAlpha,frame)
    if not C.Readable(alpha)then return false end
    return alpha==nil or (type(alpha)=="number"and alpha>0)
end
local function Center(frame,scale)
    if not frame.GetCenter then return end
    local ok,x,y=pcall(frame.GetCenter,frame)
    local restricted=not C.Readable(x)or not C.Readable(y)
    x,y=Number(x),Number(y)
    local frameScale=Number(Call(frame.GetEffectiveScale,frame))
    if ok and x and y and frameScale then return x*frameScale/scale,y*frameScale/scale end
    if not ok or restricted then return nil,nil,"restricted"end
    return nil,nil,"unavailable"
end
function L.Hide(view,reason)
    L.status=reason or "hidden"
    local overlay=view and view.targetNameplateLine
    if overlay then
        if overlay:IsShown()then overlay:Hide()end
        overlay.source=nil;overlay.plate=nil
    end
end
function L.Update(view)
    if not view or view.preview then return end
    if L.unsupported then L.Hide(view,"nameplate-restricted");return end
    local portrait=view.nodes and view.nodes.wa0b0b0540c7
    local source=portrait and (portrait.portraitAnchor or portrait.frame)
    if not M.db or M.db.targetNameplateLine==false or not Visible(view.root)
        or not portrait or portrait.spec.enabled==false or not Visible(source)
        or C.Bool(Call(UnitExists,"target"))~=true then L.Hide(view,"source-or-target-unavailable");return end
    local plate=Call(C_NamePlate and C_NamePlate.GetNamePlateForUnit,"target")
    if not Visible(plate)then L.Hide(view,"nameplate-unavailable");return end
    if L.restricted[plate]then L.Hide(view,"nameplate-restricted");return end
    local overlay=view.targetNameplateLine
    if not overlay then
        overlay=CreateFrame("Frame",nil,UIParent);overlay:SetAllPoints(UIParent)
        overlay:SetFrameStrata("HIGH");overlay:SetFrameLevel(1);overlay:EnableMouse(false)
        overlay:Hide();view.targetNameplateLine=overlay
        if not overlay.CreateLine then return end
        overlay.line=overlay:CreateLine(nil,"ARTWORK")
        overlay.line:SetColorTexture(1,1,1,.75);overlay.line:SetThickness(2)
        if overlay.line.SetSnapToPixelGrid then overlay.line:SetSnapToPixelGrid(false)end
        if overlay.line.SetTexelSnappingBias then overlay.line:SetTexelSnappingBias(0)end
    end
    if not overlay.line then L.status="line-api-unavailable";return end
    local scale=Number(Call(overlay.GetEffectiveScale,overlay))
    local sx,sy,tx,ty,reason
    if scale and scale>0 then
        sx,sy=Center(source,scale);tx,ty,reason=Center(plate,scale)
    end
    if not tx then
        if reason=="restricted"then
            L.restricted[plate]=true;L.unsupported=true
            if M.general and M.RefreshOtherSettings then M:RefreshOtherSettings()end
        end
        L.Hide(view,reason=="restricted"and "nameplate-restricted"or "nameplate-coordinates-unavailable");return
    end
    if not sx then L.Hide(view,"source-coordinates-unavailable");return end
    -- Restricted nameplates cannot be measured or used as cross-frame line
    -- anchors. Only draw from readable coordinates; never fall back to that anchor.
    local left=Number(Call(overlay.GetLeft,overlay))or 0
    local bottom=Number(Call(overlay.GetBottom,overlay))or 0
    sx,sy,tx,ty=sx-left,sy-bottom,tx-left,ty-bottom
    if overlay.source~=source or overlay.plate~=plate
        or overlay.sx~=sx or overlay.sy~=sy or overlay.tx~=tx or overlay.ty~=ty then
        local ok,err=pcall(function()
            overlay.line:SetStartPoint("BOTTOMLEFT",overlay,sx,sy)
            overlay.line:SetEndPoint("BOTTOMLEFT",overlay,tx,ty)
        end)
        if not ok then L.lastError=tostring(err);L.Hide(view,"anchor-unavailable");return end
        overlay.source,overlay.plate=source,plate
        overlay.sx,overlay.sy,overlay.tx,overlay.ty=sx,sy,tx,ty
    end
    L.status="shown-screen";L.lastError=nil;overlay.line:Show();overlay:Show()
end
function L.Event(view,event)
    if event=="PLAYER_TARGET_CHANGED"or event=="NAME_PLATE_UNIT_ADDED"or event=="NAME_PLATE_UNIT_REMOVED"
        or event=="PLAYER_ENTERING_WORLD"or event=="PLAYER_REGEN_ENABLED"then L.Update(view)end
end
