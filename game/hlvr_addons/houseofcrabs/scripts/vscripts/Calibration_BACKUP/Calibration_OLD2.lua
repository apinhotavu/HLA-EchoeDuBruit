local hands = {}
local handInputCount = 0
local startCalibration = false
local isCalibrating = false
local calibrationDone = false
local countDown = 0
local countDownPosOffset = 10
local maxDistance = 50

local debugColor = Vector(255, 0, 0)

-- 0 = not started
-- 1 = input on one hand detected
-- 2 = started
-- 3 = countdown
local calibrationState = 0

---@type CPointWorldText
local debugText = nil

---@type CBaseEntity
local teleportPositionEnt = nil

---@type CBaseEntity
local teleportPositionEntRoom = nil

function Spawn()
    thisEntity:SetContextThink("ThinkInputDetection", ThinkInputDetection, 0)
end

function Activate()
    debugText = Entities:FindByName(nil, "CountdownPlayerCalibration")
    teleportPositionEnt = Entities:FindByName(nil, "TeleportPlayerCalibration")
    teleportPositionEntRoom = Entities:FindByName(nil, "TeleportPlayerCalibrationRoom")
end

function CountdownInit()
    countDown = 2
end

function TeleportPlayer()
    EntFireByHandle(Entities:GetLocalPlayer(), teleportPositionEnt, "TeleportToCurrentPos")
    calibrationDone = true
end

function TeleportPlayerRoom()
    EntFireByHandle(Entities:GetLocalPlayer(), teleportPositionEntRoom, "TeleportToCurrentPos")
end

function ExecuteCalibration(state)
    if state then
        CountdownInit()
        thisEntity:SetContextThink("ThinkCalibrateOrientation", ThinkCalibrateOrientation, 0)
    else
        thisEntity:SetContextThink("ThinkCalibrationCountdown", nil, 0)
        thisEntity:SetContextThink("ThinkCalibrateOrientation", nil, 0)
    end
end

function ExitCalibration()
    ExecuteCalibration(false)
    CountdownInit()

    debugColor = Vector(255, 0, 0)
    debugText:SetOrigin(Vector(-100, 0, 0))

    isCalibrating = false
end

function ThinkInputDetection()
    if (Entities:GetLocalPlayer():GetHMDAvatar() == nil) then
        do return end
    end
    
    hands = {
        Entities:GetLocalPlayer():GetHMDAvatar():GetVRHand(0);
        Entities:GetLocalPlayer():GetHMDAvatar():GetVRHand(1)
    }

    for key,value in pairs(hands) do
        local action = Entities:GetLocalPlayer():IsDigitalActionOnForHand(value:GetLiteralHandType(), 17)

        if action and handInputCount < 2 then
            handInputCount = handInputCount+1
        elseif not action and handInputCount > 0 then
                handInputCount = handInputCount-1
        end
    end

    if (handInputCount == 2 and startCalibration == false and calibrationDone == false) then
        startCalibration = true
        ExecuteCalibration(true)
        TeleportPlayerRoom()
    elseif (handInputCount ~= 2 and startCalibration) then
        ExitCalibration()
        startCalibration = false
        calibrationDone = false
    end
    
    --DebugDrawSphere(Entities:GetLocalPlayer():GetHMDAnchor():GetAbsOrigin(), Vector(0, 128, 128), 255, 2, true, 0)
    --DebugDrawLine(Entities:GetLocalPlayer():GetHMDAnchor():GetAbsOrigin(), Vector(Entities:GetLocalPlayer():GetHMDAnchor():GetAbsOrigin().x, Entities:GetLocalPlayer():GetHMDAnchor():GetAbsOrigin().y, Entities:GetLocalPlayer():GetHMDAvatar():EyePosition().z), 0, 128, 128, true, 0)

    return 0.5
end

function ThinkCalibrateOrientation()
    local handRPos = Entities:GetLocalPlayer():GetHMDAvatar():GetVRHand(1):GetCenter()
    local handLPos = Entities:GetLocalPlayer():GetHMDAvatar():GetVRHand(0):GetCenter()

    local midPointVector = Vector((handRPos.x + handLPos.x) / 2, (handRPos.y + handLPos.y) / 2, (handRPos.z + handLPos.z) / 2)
    local directionVector = Vector(handRPos.x - handLPos.x, handRPos.y - handLPos.y, handRPos.z - handLPos.z)
    local newVector = CrossVectors(directionVector, Vector(0, 0, -1)):Normalized()
    local perpendicularPosition = Vector(midPointVector.x + maxDistance * newVector.x,midPointVector.y + maxDistance * newVector.y,midPointVector.z + maxDistance * newVector.z)
    local orientationFinalPos = Vector(perpendicularPosition.x, perpendicularPosition.y, Entities:GetLocalPlayer():EyePosition().z)

    local perpendicularEyePos = Vector(Entities:GetLocalPlayer():EyePosition().x, Entities:GetLocalPlayer():EyePosition().y, midPointVector.z)
    local eyeFinalPos = Entities:GetLocalPlayer():EyePosition() + Entities:GetLocalPlayer():GetForwardVector() + AnglesToVector(Entities:GetLocalPlayer():EyeAngles()) * maxDistance
    
    --Line between hands
    DebugDrawLine(handRPos, handLPos, debugColor.x, debugColor.y, debugColor.z, false, 0)
    --Line from middle between hands to perpendicularPosition
    DebugDrawLine(midPointVector, perpendicularPosition, debugColor.x, debugColor.y, debugColor.z, false, 0)
    --Line from perpendicularPosition to orientationEntFinalPos
    DebugDrawLine(perpendicularPosition, orientationFinalPos, debugColor.x, debugColor.y, debugColor.z, false, 0)
    --orientationFinalPos sphere
    DebugDrawSphere(orientationFinalPos, debugColor, 255, 1, false, 0)
    --eyeFinalPos sphere
    DebugDrawSphere(eyeFinalPos, debugColor, 255, 1, false, 0)

    if VectorDistance(orientationFinalPos, eyeFinalPos) < 1 and VectorDistance(perpendicularEyePos, midPointVector) < 1 then
        if isCalibrating == false then
            isCalibrating = true
            debugColor = Vector(0, 255, 0)
            CountdownInit()
            thisEntity:SetContextThink("ThinkCalibrationCountdown", ThinkCalibrationCountdown, 0)
        end
    else
        if isCalibrating then
            isCalibrating = false
            debugColor = Vector(255, 0, 0)
            debugText:SetOrigin(Vector(-100, 0, 0))
            thisEntity:SetContextThink("ThinkCalibrationCountdown", nil, 0)
        end
    end

    if isCalibrating then
        debugText:SetMessage(tostring(countDown+1))
        debugText:SetOrigin(Vector(orientationFinalPos.x, orientationFinalPos.y, orientationFinalPos.z + countDownPosOffset))
    end

    return 0
end

function ThinkCalibrationCountdown()
    if (countDown > 0 ) then
        countDown = countDown - 1
    else
        TeleportPlayer()
        ExitCalibration()
    end
    
    return 1
end