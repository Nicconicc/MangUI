local _, M = ...
local Camera = {}
M.CameraSmoothing = Camera

local frame = CreateFrame("Frame")
local axes = {"cameraYawMoveSpeed", "cameraPitchMoveSpeed"}
local filter = {}
local active = false
local get = C_CVar and C_CVar.GetCVar or GetCVar
local set = C_CVar and C_CVar.SetCVar or SetCVar

local function read(key)
    local ok, value = pcall(get, key)
    if ok then return tonumber(value) end
end

local function write(key, value)
    if pcall(set, key, tostring(value)) then return read(key) end
end

-- This journal also restores the constant sensitivity override from v951.
local function restore(onlyKey)
    local db = M.db
    local saved = db and db.cameraSmoothingSpeeds
    if not saved then return end
    for _, key in ipairs(axes) do
        local entry = saved[key]
        if entry and (not onlyKey or key == onlyKey) then
            local value = read(key)
            if value and (value ~= entry.applied or write(key, entry.original) == entry.original) then
                saved[key] = nil
            end
        end
    end
    if not next(saved) then db.cameraSmoothingSpeeds = nil end
end

local function stop()
    active = false
    frame:SetScript("OnUpdate", nil)
    restore()
    wipe(filter)
end

local reverseDistance = 5
local idleReset = 0.12
local transitionDuration = 0.09
local initialGain = 0.65
local writeInterval = 1/60

local function applyGain(key, axis, gain)
    local current = read(key)
    if not current or (axis.applied and current ~= axis.applied) then
        -- A newer setting from the game or another addon takes precedence.
        filter[key] = nil
        restore(key)
        return
    end
    local target = gain == 1 and axis.original or math.max(1, axis.original * gain)
    if target == current then return end
    local applied = write(key, target)
    if not applied or applied == current then return end
    axis.applied = applied
    M.db.cameraSmoothingSpeeds = M.db.cameraSmoothingSpeeds or {}
    local saved = M.db.cameraSmoothingSpeeds
    if applied == axis.original then
        saved[key] = nil
        if not next(saved) then M.db.cameraSmoothingSpeeds = nil end
    else
        saved[key] = {original = axis.original, applied = applied}
    end
end

local function updateAxis(key, delta, dt)
    local axis = filter[key]
    if not axis then return end

    if delta == 0 then
        axis.idle = axis.idle + dt
        if axis.idle >= idleReset then
            axis.direction, axis.distance = 0, 0
        end
    else
        axis.idle = 0
        if axis.direction == 0 then
            axis.distance = axis.distance + delta
            if math.abs(axis.distance) >= reverseDistance then
                axis.direction, axis.distance = axis.distance > 0 and 1 or -1, 0
            end
        else
            axis.distance = math.max(0, axis.distance - delta * axis.direction)
            if axis.distance >= reverseDistance then
                axis.direction, axis.distance = -axis.direction, 0
                if not axis.transition then
                    axis.original = read(key)
                    if not axis.original or axis.original <= 1 then return end
                    axis.applied = axis.original
                end
                axis.transition, axis.sinceWrite = 0, 0
                applyGain(key, axis, initialGain)
                return
            end
        end
    end

    if not axis.transition then return end
    axis.transition = axis.transition + dt
    axis.sinceWrite = axis.sinceWrite + dt
    if axis.transition >= transitionDuration then
        applyGain(key, axis, 1)
        axis.transition = nil
    elseif axis.sinceWrite >= writeInterval then
        axis.sinceWrite = axis.sinceWrite - writeInterval
        local t = axis.transition / transitionDuration
        local ease = t * t * (3 - 2 * t)
        applyGain(key, axis, initialGain + (1 - initialGain) * ease)
    end
end

local function update(_, dt)
    if not IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton") then stop(); return end
    if dt <= 0 then return end
    local x, y = GetCursorDelta()
    updateAxis(axes[1], x, dt)
    updateAxis(axes[2], y, dt)
end

local hooksInstalled = false
function Camera.SetEnabled(enabled)
    stop()
    local supported = GetCursorDelta and get and set and hooksecurefunc
        and CameraOrSelectOrMoveStart and CameraOrSelectOrMoveStop
    M.db.cameraSmoothing = enabled == true and supported ~= nil and supported ~= false
    if M.db.cameraSmoothing and not hooksInstalled then
        hooksecurefunc("CameraOrSelectOrMoveStart", function()
            if active or not M.db.cameraSmoothing or not IsMouseButtonDown("LeftButton")
                or IsMouseButtonDown("RightButton") then return end
            restore()
            if M.db.cameraSmoothingSpeeds then return end
            for _, key in ipairs(axes) do
                local original = read(key)
                if original and original > 0 then
                    filter[key] = {direction = 0, distance = 0, idle = 0}
                end
            end
            active = true
            frame:SetScript("OnUpdate", update)
        end)
        hooksecurefunc("CameraOrSelectOrMoveStop", function() if active then stop() end end)
        if TurnOrActionStart then hooksecurefunc("TurnOrActionStart", function() if active then stop() end end) end
        hooksInstalled = true
    end
    return M.db.cameraSmoothing
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then Camera.SetEnabled(M.db.cameraSmoothing) else stop() end
end)
