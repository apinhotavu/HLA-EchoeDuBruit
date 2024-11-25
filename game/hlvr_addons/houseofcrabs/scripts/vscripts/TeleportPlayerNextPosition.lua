local teleportDestination = {
    CALIBRATION = Vector(-1000, 0, 0),
    BASE = Vector(0, 0, 0),
    TIMEZONE_01 = Vector(1000, 0, 0),
    TIMEZONE_02 = Vector(2000, 0, 0),
    TIMEZONE_03 = Vector(3000, 0, 0)
}

local playerPossibleType = {
    NOVR = 0,
    VR = 1
}
local playerType = playerPossibleType.NOVR

---@type CBasePlayer
local player = nil

function TeleportToNextPos(destination)
    if (player == nil) then
        player = Entities:GetLocalPlayer()
        if (player:GetHMDAvatar() ~= nil) then
            playerType = playerPossibleType.VR
        end
    end

    local posTarget = FindDestination(destination)

    if (playerType == playerPossibleType.NOVR) then
        player:SetOrigin(posTarget)
    elseif (playerType == playerPossibleType.VR) then
        player:GetHMDAvatar():SetOrigin(posTarget)
        player:GetHMDAnchor():SetOrigin(posTarget)
    end
end

function FindDestination(destination)
    for key, value in pairs(teleportDestination) do
        print (string.format("Destination : %s", destination))
        print (string.format("Key : %s", key))
        print (string.format("Value : %s", value))
        if key == destination then
            return player:GetAbsOrigin() + value
        end
    end
    return Vector(0,0,0)
end