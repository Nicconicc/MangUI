local _,M=...
local L={};M.TargetNameplateLine=L
local C=M.Compat
local function Call(fn,...)
    if not fn then return end
    local ok,value=pcall(fn,...);if ok then return value end
end
local function Visible(frame)
    if not frame or Call(frame.IsForbidden,frame)==true then return false end
    return C.Bool(Call(frame.IsVisible,frame))==true
end
function L.Hide(view,reason)
    L.status=reason or "hidden"
    local host=view and view.targetNameplateLine
    if host and host:IsShown()then host:Hide()end
end
local function Restricted(view,err)
    L.lastError=tostring(err);L.unsupported=true
    L.Hide(view,"nameplate-child-anchor-unavailable")
    if M.general and M.RefreshOtherSettings then M:RefreshOtherSettings()end
end
function L.Update(view)
    if not view or view.preview then return end
    if L.unsupported then L.Hide(view,"nameplate-child-anchor-unavailable");return end
    local portrait=view.nodes and view.nodes.wa0b0b0540c7
    local source=portrait and (portrait.portraitAnchor or portrait.frame)
    if not M.db or M.db.targetNameplateLine==false or not Visible(view.root)
        or not portrait or portrait.spec.enabled==false or not Visible(source)
        or C.Bool(Call(UnitExists,"target"))~=true then L.Hide(view,"source-or-target-unavailable");return end
    local plate=Call(C_NamePlate and C_NamePlate.GetNamePlateForUnit,"target")
    if not Visible(plate)then L.Hide(view,"nameplate-unavailable");return end
    view.nameplateLineHosts=view.nameplateLineHosts or setmetatable({},{__mode="k"})
    local host=view.nameplateLineHosts[plate]
    if not host then
        local ok,err=pcall(function()
            -- Keep the line inside the nameplate's layout family. Never measure
            -- the plate or anchor a UIParent-owned line onto the plate.
            host=CreateFrame("Frame",nil,plate);host:Hide();host:EnableMouse(false)
            view.nameplateLineHosts[plate]=host
            host:SetAllPoints(plate)
            if host.SetClipsChildren then host:SetClipsChildren(false)end
            host.line=host:CreateLine(nil,"OVERLAY")
            host.line:SetColorTexture(1,1,1,.75);host.line:SetThickness(2)
            host.line:SetStartPoint("CENTER",host,0,0)
        end)
        if not ok then Restricted(view,err);return end
    end
    if view.targetNameplateLine~=host then
        L.Hide(view);view.targetNameplateLine=host
    end
    if host.source~=source then
        local ok,err=pcall(host.line.SetEndPoint,host.line,"CENTER",source,0,0)
        if not ok then Restricted(view,err);return end
        host.source=source
    end
    -- Native anchors follow both endpoints without polling their coordinates.
    L.status="shown-nameplate-child";L.lastError=nil;host.line:Show();host:Show()
end
function L.Event(view,event)
    if event=="PLAYER_TARGET_CHANGED"or event=="NAME_PLATE_UNIT_ADDED"or event=="NAME_PLATE_UNIT_REMOVED"
        or event=="PLAYER_ENTERING_WORLD"or event=="PLAYER_REGEN_ENABLED"then L.Update(view)end
end
