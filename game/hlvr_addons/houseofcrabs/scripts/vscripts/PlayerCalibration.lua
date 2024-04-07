--[[
Used to calibrate the player in the virtal space with the physical space.

Needs to following in the map (names can be modified in the Activate()):
- "point_teleport" entity called "TeleportPlayerCalibration"
- "point_teleport" entity called "TeleportPlayerCalibrationRoom"
- "point_worldtext" entity called "CountdownPlayerCalibration"

/!\ Next step: make the TP without the need of point_teleport entity /!\ 
]]

--#region STATIC VARIABLES
local initialCountDownValue = 3
local countDownPosYOffset = 5
local calibrationSphereDistanceFromPlayer = 50
local calibrationSphereSize = 1
local debugColorEnum = {
    RED = Vector(255, 0, 0),
    GREEN = Vector(0, 255, 0)
}
local debugColor = debugColorEnum.RED
local calibrationStateEnum = {
    NOT_STARTED = 0,
    STARTED = 1,
    COUNTDOWN = 2,
    DONE = 3
}
local calibrationState = calibrationStateEnum.NOT_STARTED
local handActionStateEnum = {
    NO_ACTION = 0,
    ACTION = 1,
    DISABLED = 2
}
local handActionState = handActionStateEnum.NO_ACTION
---@type CBasePlayer
local player = nil
---@type CPointWorldText
local countDownText = nil
---@type CBaseEntity
local teleportPositionEnt = nil
---@type CBaseEntity
local teleportPositionEntCalibrationRoom = nil
--#endregion

--#region DYNAMIC VARIABLES
local countDown = 0
--#endregion

--Called after the entity has spawned
--If the entity is spawned on map load, called after all entities have spawned
function Activate()
    --Store all necessary map entities
    countDownText = Entities:FindByName(nil, "CountdownPlayerCalibration")
    teleportPositionEnt = Entities:FindByName(nil, "TeleportPlayerCalibration")
    teleportPositionEntCalibrationRoom = Entities:FindByName(nil, "TeleportPlayerCalibrationRoom")

    --Start event listener for player spawned
    ListenToGameEvent("player_spawn", OnPlayerSpawned, nil)
end

--If player ~= nil, store player
--Start ThinkInputDetection
function OnPlayerSpawned()
    if Entities:GetLocalPlayer() ~= nil then
        player = Entities:GetLocalPlayer()
        thisEntity:SetContextThink("ThinkInputDetection", ThinkInputDetection, 0)
        StopListeningToAllGameEvents(nil)
    end
end

--/!\ Always running, every 0.1s
--Detect player inputs and Start or Exit calibration
function ThinkInputDetection()
    --HMD Avatar cannot be detected with player spawn listener,
    --makes sure that the script doesn't start if player is playing with keyboard
    if player:GetHMDAvatar() == nil then
        do thisEntity:StopThink("ThinkInputDetection") return end
    end

    local handR = player:GetHMDAvatar():GetVRHand(1)
    local handL = player:GetHMDAvatar():GetVRHand(0)

    --If player presses both INTERACT buttons (17): Start the calibration
    if player:IsDigitalActionOnForHand(handR:GetLiteralHandType(), 17) and player:IsDigitalActionOnForHand(handL:GetLiteralHandType(), 17) then
        if handActionState == handActionStateEnum.NO_ACTION then
            StartCalibration()
            handActionState = handActionStateEnum.ACTION
        end
    elseif handActionState == handActionStateEnum.ACTION then
        ExitCalibration()
        handActionState = handActionStateEnum.NO_ACTION
    end
    
    return 0.1
end

--Teleport player to calibration room
--Reset necessary values
--Start ThinkCalibration and ThinkCalibrationCountdown
function StartCalibration()
    TeleportPlayer(teleportPositionEntCalibrationRoom)
    ResetDebugColorAndText()
    thisEntity:SetContextThink("ThinkCalibration", ThinkCalibration, 0)
    thisEntity:SetContextThink("ThinkCalibrationCountdown", ThinkCalibrationCountdown, 0)
    calibrationState = calibrationStateEnum.STARTED
end

--Does the calculations to calibrate player
--Teleport player to final pos and disable itself if countdown == 0
function ThinkCalibration()
    --Stops the calibration if calibration is DONE
    if calibrationState == calibrationStateEnum.DONE then
        do return end
    end

    --Get center pos for both hands
    local handRPos = player:GetHMDAvatar():GetVRHand(1):GetCenter()
    local handLPos = player:GetHMDAvatar():GetVRHand(0):GetCenter()

    --#CALIBRATION TRIGO#
    --Calcultate the point in between the hands
    local midPointVector = Vector((handRPos.x + handLPos.x) / 2, (handRPos.y + handLPos.y) / 2, (handRPos.z + handLPos.z) / 2)
    --Calculate the direction vector from midpoint to its forward vector
    local directionVector = Vector(handRPos.x - handLPos.x, handRPos.y - handLPos.y, handRPos.z - handLPos.z)
    local newVector = CrossVectors(directionVector, Vector(0, 0, -1)):Normalized()
    --Calculate final perpendicular position of the midpoint at a given distance
    local perpendicularPosition = Vector(midPointVector.x + calibrationSphereDistanceFromPlayer * newVector.x,midPointVector.y + calibrationSphereDistanceFromPlayer * newVector.y,midPointVector.z + calibrationSphereDistanceFromPlayer * newVector.z)
    --Set final pos to player's eye Z level
    local orientationFinalPos = Vector(perpendicularPosition.x, perpendicularPosition.y, player:EyePosition().z)

    --#PLAYER#
    --Position of where the player is looking at, at a given distance
    local eyeFinalPos = player:EyePosition() + player:GetForwardVector() + AnglesToVector(player:EyeAngles()) * calibrationSphereDistanceFromPlayer
    --Pos of the eye of the player at the midpoint Z level
    local perpendicularEyePos = Vector(player:EyePosition().x, player:EyePosition().y, midPointVector.z)

    --Draw the results of everything that needs to be feedback
    DebugDraw(handRPos, handLPos, midPointVector, perpendicularPosition, orientationFinalPos, eyeFinalPos)

    --If player is looking at orientationFinalPos and is right above the midPointVector,
    --start countDown
    if VectorDistance(orientationFinalPos, eyeFinalPos) < calibrationSphereSize and VectorDistance(perpendicularEyePos, midPointVector) < calibrationSphereSize then
        if calibrationState == calibrationStateEnum.STARTED then
            calibrationState = calibrationStateEnum.COUNTDOWN
            CountdownInit()
        end
    elseif calibrationState == calibrationStateEnum.COUNTDOWN then
            calibrationState = calibrationStateEnum.STARTED
            ResetDebugColorAndText()
    end

    --If COUNTDOWN state is active,
    --set countdown value as message
    if calibrationState == calibrationStateEnum.COUNTDOWN then
        countDownText:SetMessage(tostring(countDown))
        countDownText:SetOrigin(orientationFinalPos + Vector(0, 0, countDownPosYOffset))

        --Teleport player to final pos when countDown == 0
        if countDown == 0 then
            TeleportPlayer(teleportPositionEnt)
            calibrationState = calibrationStateEnum.DONE
        end
    end

    return 0
end

--Start countDown and decrement it every 1s
function ThinkCalibrationCountdown()
    if countDown > 0 and calibrationState == calibrationStateEnum.COUNTDOWN then
        countDown = countDown - 1
    end
    
    return 1
end

--Reset countDown value
--Set debugColor to GREEN
function CountdownInit()
    countDown = initialCountDownValue
    debugColor = debugColorEnum.GREEN
end

--Teleport player to destination
--destination is a "point_teleport" entity
function TeleportPlayer(destination)
    EntFireByHandle(player, destination, "TeleportToCurrentPos")
end

--Reset necessary values
--Stop ThinkCalibration and ThinkCalibrationCountdown
function ExitCalibration()
    ResetDebugColorAndText()
    thisEntity:StopThink("ThinkCalibration")
    thisEntity:StopThink("ThinkCalibrationCountdown")
    calibrationState = calibrationStateEnum.NOT_STARTED
end

--Reset debugColor to RED
--Teleport countDownText to a hidden pos in the world
function ResetDebugColorAndText()
    debugColor = debugColorEnum.RED
    countDownText:SetOrigin(Vector(-100, 0, 0))
end

--Draw the results of ThinkCalibration
function DebugDraw(handRPos, handLPos, midPointVector, perpendicularPosition, orientationFinalPos, eyeFinalPos)
    --Line between hands
    DebugDrawLine(handRPos, handLPos, debugColor.x, debugColor.y, debugColor.z, false, 0)
    --Line from middle between hands to perpendicularPosition
    DebugDrawLine(midPointVector, perpendicularPosition, debugColor.x, debugColor.y, debugColor.z, false, 0)
    --Line from perpendicularPosition to orientationEntFinalPos
    DebugDrawLine(perpendicularPosition, orientationFinalPos, debugColor.x, debugColor.y, debugColor.z, false, 0)

    --orientationFinalPos sphere
    DebugDrawSphere(orientationFinalPos, debugColor, 255, calibrationSphereSize, false, 0)
    --eyeFinalPos sphere
    DebugDrawSphere(eyeFinalPos, debugColor, 255, calibrationSphereSize, false, 0)

    --Line from eyeFinalPos to orientationEntFinalPos
    DebugDrawLine(eyeFinalPos, orientationFinalPos, debugColor.x, debugColor.y, debugColor.z, false, 0)
end