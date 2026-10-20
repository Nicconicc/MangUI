local _,M=...
local L={};M.TargetNameplateLine=L
local C=M.Compat
local function Call(fn,...)
    if not fn then return end
    local ok,value=pcall(fn,...);if ok then return value end
end
local function Visible(frame)
    if not frame or Call(frame.IsForbidden,frame)==true then return false end
    if C.Bool(Call(frame.IsVisible,frame))~=true then return false end
    local alpha=Call(frame.GetEffectiveAlpha or frame.GetAlpha,frame)
    if not C.Readable(alpha)then return false end
    return alpha==nil or (type(alpha)=="number"and alpha>0)
end
function L.Hide(view)
    local overlay=view and view.targetNameplateLine
    if overlay then overlay:Hide();overlay.source=nil;overlay.plate=nil end
end
function L.Update(view)
    if not view or view.preview then return end
    local portrait=view.nodes and view.nodes.wa0b0b0540c7
    if not M.db or M.db.targetNameplateLine==false or not Visible(view.root)
        or not portrait or portrait.spec.enabled==false or not Visible(portrait.frame)
        or C.Bool(Call(UnitExists,"target"))~=true then L.Hide(view);return end
    local plate=Call(C_NamePlate and C_NamePlate.GetNamePlateForUnit,"target")
    if not Visible(plate)then L.Hide(view);return end
    local overlay=view.targetNameplateLine
    if not overlay then
        overlay=CreateFrame("Frame",nil,view.root);overlay:SetAllPoints(view.root)
        overlay:SetFrameStrata("LOW");overlay:SetFrameLevel(1);overlay:EnableMouse(false)
        overlay:Hide();view.targetNameplateLine=overlay
        if not overlay.CreateLine then return end
        overlay.line=overlay:CreateLine(nil,"ARTWORK")
        overlay.line:SetColorTexture(1,1,1,.6);overlay.line:SetThickness(1.5)
        if overlay.line.SetSnapToPixelGrid then overlay.line:SetSnapToPixelGrid(false)end
        if overlay.line.SetTexelSnappingBias then overlay.line:SetTexelSnappingBias(0)end
    end
    if not overlay.line then return end
    if overlay.source~=portrait.frame or overlay.plate~=plate then
        -- Native region anchors follow both endpoints without reading protected
        -- nameplate coordinates, doing scale arithmetic or moving either frame.
        local ok=pcall(function()
            overlay.line:SetStartPoint("CENTER",portrait.frame,0,0)
            overlay.line:SetEndPoint("CENTER",plate,0,0)
        end)
        if not ok then overlay:Hide();return end
        overlay.source,overlay.plate=portrait.frame,plate
    end
    overlay:Show()
end
function L.Event(view,event)
    if event=="PLAYER_TARGET_CHANGED"or event=="NAME_PLATE_UNIT_ADDED"or event=="NAME_PLATE_UNIT_REMOVED"
        or event=="PLAYER_ENTERING_WORLD"or event=="PLAYER_REGEN_ENABLED"then L.Update(view)end
end
