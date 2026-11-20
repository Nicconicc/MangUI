local _, M = ...
local Camera = {}
M.CameraSmoothing = Camera

local axes = { "cameraYawMoveSpeed", "cameraPitchMoveSpeed" }
local speedMultiplier = 0.65

local function ReadSpeed(key)
    local get = C_CVar and C_CVar.GetCVar or GetCVar
    if not get then return end
    local ok, value = pcall(get, key)
    if ok then return tonumber(value) end
end

local function WriteSpeed(key, speed)
    local set = C_CVar and C_CVar.SetCVar or SetCVar
    if not set then return end
    if pcall(set, key, tostring(speed)) then return ReadSpeed(key) end
end

function Camera.SetEnabled(enabled)
    local db = M.db
    if not db then return end
    local saved = db.cameraSmoothingSpeeds or {}
    for _, key in ipairs(axes) do
        local current = ReadSpeed(key)
        local previous = saved[key]
        if enabled then
            if current and current > 0 and (not previous or current ~= previous.applied) then
                saved[key] = nil
                local applied = WriteSpeed(key, current * speedMultiplier)
                if applied and applied ~= current then
                    saved[key] = { original = current, applied = applied }
                end
            end
        elseif previous and current then
            -- Preserve a newer camera setting made outside MangUI.
            if current ~= previous.applied or WriteSpeed(key, previous.original) == previous.original then
                saved[key] = nil
            end
        end
    end
    db.cameraSmoothingSpeeds = next(saved) and saved or nil
    db.cameraSmoothing = enabled == true and db.cameraSmoothingSpeeds ~= nil
    return db.cameraSmoothing
end

local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    if M.db and M.db.cameraSmoothing then Camera.SetEnabled(true) end
end)
