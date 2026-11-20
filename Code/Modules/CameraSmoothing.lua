local _, M = ...
local Camera = {}
M.CameraSmoothing = Camera

local frame = CreateFrame("Frame")
local axes = {"cameraYawMoveSpeed", "cameraPitchMoveSpeed"}
local filter = {}
local active = false
local elapsed = 0
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
local function restore()
    local db = M.db
    local saved = db and db.cameraSmoothingSpeeds
    if not saved then return end
    for _, key in ipairs(axes) do
        local entry = saved[key]
        if entry then
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

local function updateAxis(key, delta, dt, flush)
    local axis = filter[key]
    if not axis then return end
    local speed = delta / dt
    -- Integrate signed mouse velocity so a reversal must cross zero first.
    axis.velocity = axis.velocity + (speed - axis.velocity) * (1 - math.exp(-dt / 0.085))
    if not flush or delta == 0 then return end
    local gain = math.max(0.03, math.min(1, axis.velocity / speed))
    local target = math.floor(axis.original * gain * 10 + 0.5) / 10
    if target == axis.requested then return end
    local current = read(key)
    if current ~= axis.applied then
        filter[key] = nil
        return
    end
    local applied = write(key, target)
    if applied then
        axis.requested, axis.applied = target, applied
        M.db.cameraSmoothingSpeeds = M.db.cameraSmoothingSpeeds or {}
        M.db.cameraSmoothingSpeeds[key] = {original = axis.original, applied = applied}
    end
end

local function update(_, dt)
    if not IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton") then stop(); return end
    if dt <= 0 then return end
    local x, y = GetCursorDelta()
    elapsed = elapsed + dt
    local flush = elapsed >= 1/60
    if flush then elapsed = 0 end
    updateAxis(axes[1], x, dt, flush)
    updateAxis(axes[2], y, dt, flush)
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
                    filter[key] = {original = original, applied = original, requested = original, velocity = 0}
                end
            end
            active, elapsed = true, 0
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
