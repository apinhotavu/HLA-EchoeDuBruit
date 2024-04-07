local hands = {}
local handInputCount = 0
local startCalibration = false
local isCalibrating = false
local calibrationDone = false
local countDown = 0
local countDownPosOffset = 10
local maxDistance = 50

local debugColor = Vector(255, 0, 0)

local finalDestination = Vector(1000,0,0)
local finalDirectionYawAngle = 180

---@type CPointWorldText
local debugText = nil

---@type CBaseEntity
local calibrateOrientationEntity = nil

---@type CBaseEntity
local teleportPositionEnt = nil

---@type CBaseEntity
local teleportPositionEntRoom = nil

function Spawn()
    thisEntity:SetContextThink("ThinkInputDetection", ThinkInputDetection, 0)
end

function Activate()
    debugText = Entities:FindByName(nil, "CountdownPlayerCalibration")
    calibrateOrientationEntity = Entities:FindByName(nil, "CalibrateOrientationEntity")
    teleportPositionEnt = Entities:FindByName(nil, "TeleportPlayerCalibration")
    teleportPositionEntRoom = Entities:FindByName(nil, "TeleportPlayerCalibrationRoom")
end

function CountdownInit()
    countDown = 2
end

function TeleportPlayer()
    --local player = Entities:GetLocalPlayer()
    --local anchor = player:GetHMDAnchor()

    --local localPlayerOrigin = anchor:GetOrigin() - player:GetOrigin()
	--anchor:SetOrigin(Vector(localPlayerOrigin.x + finalDestination.x, localPlayerOrigin.y + finalDestination.y, 0))
    
    --local localPlayerAngle = AngleDiff(anchor:GetAngles().y, player:GetAngles().y)
	--anchor:SetAngles(0, localPlayerAngle + finalDirectionYawAngle, 0)

    --print(player:GetAngles())
    --print(player:GetOrigin())

    EntFireByHandle(Entities:GetLocalPlayer(), teleportPositionEnt, "TeleportToCurrentPos")
    calibrationDone = true
end

function TeleportPlayerRoom()
    EntFireByHandle(Entities:GetLocalPlayer(), teleportPositionEntRoom, "TeleportToCurrentPos")
end

function ExecuteCalibration(state)
    if state then
        CountdownInit()
        thisEntity:SetContextThink("ThinkCalibrationOrientation", ThinkCalibrationOrientation, 0)
        thisEntity:SetContextThink("ThinkCalibrateOrientationEntity", ThinkCalibrateOrientationEntity, 0)
    else
        thisEntity:SetContextThink("ThinkCalibrationCountdown", nil, 0)
        thisEntity:SetContextThink("ThinkCalibrationOrientation", nil, 0)
        thisEntity:SetContextThink("ThinkCalibrateOrientationEntity", nil, 0)
    end
end

function ExitCalibration()
    ExecuteCalibration(false)
    CountdownInit()

    debugColor = Vector(255, 0, 0)
    debugText:SetOrigin(Vector(-100, 0, 0))
    calibrateOrientationEntity:SetOrigin(Vector(-100, 0, 0))

    --THIS MIGHT BE WHY I WAS BEING TELEPORTED TO ZERO EVERYTIME
    --teleportPositionEnt:SetAbsOrigin(Vector(0,0,0))

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
    
    local hmdanchorpos = Entities:GetLocalPlayer():GetHMDAnchor():GetLocalOrigin()
    DebugDrawSphere(Entities:GetLocalPlayer():GetHMDAnchor():GetAbsOrigin(), Vector(0, 128, 128), 255, 2, true, 0)
    DebugDrawLine(Entities:GetLocalPlayer():GetHMDAnchor():GetAbsOrigin(), Vector(Entities:GetLocalPlayer():GetHMDAnchor():GetAbsOrigin().x, Entities:GetLocalPlayer():GetHMDAnchor():GetAbsOrigin().y, Entities:GetLocalPlayer():GetHMDAvatar():EyePosition().z), 0, 128, 128, true, 0)
    DebugDrawLine(hmdanchorpos, Vector(hmdanchorpos.x + 1,0,0) + 1, 0, 128, 128, true, 0)
    return 0
end

function ThinkCalibrationOrientation()
    local traceTable = {
        startpos = Entities:GetLocalPlayer():EyePosition();
        endpos = Entities:GetLocalPlayer():EyePosition() + Entities:GetLocalPlayer():GetForwardVector() + AnglesToVector(Entities:GetLocalPlayer():EyeAngles()) * maxDistance;
        ignore = Entities:GetLocalPlayer()
    }

    TraceLine(traceTable)

    if traceTable.hit and traceTable.enthit:HasAttribute("calibrationAttribute") then
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

    DebugDrawSphere(traceTable.pos, debugColor, 255, 2, false, 0)

    return 0
end

function ThinkCalibrateOrientationEntity()
    local handRPos = Entities:GetLocalPlayer():GetHMDAvatar():GetVRHand(1):GetCenter()
    local handLPos = Entities:GetLocalPlayer():GetHMDAvatar():GetVRHand(0):GetCenter()

    local midPointVector = Vector((handRPos.x + handLPos.x) / 2, (handRPos.y + handLPos.y) / 2, (handRPos.z + handLPos.z) / 2)
    local midPointVectorEyeLevel = Vector(midPointVector.x, midPointVector.y, Entities:GetLocalPlayer():EyePosition().z)
    local directionVector = Vector(handRPos.x - handLPos.x, handRPos.y - handLPos.y, handRPos.z - handLPos.z)

    local newVector = CrossVectors(directionVector, Vector(0, 0, -1)):Normalized()
    local perpendicularPosition = Vector(midPointVector.x + maxDistance * newVector.x,midPointVector.y + maxDistance * newVector.y,midPointVector.z + maxDistance * newVector.z)

    local orientationEntFinalPos = Vector(perpendicularPosition.x, perpendicularPosition.y, Entities:GetLocalPlayer():EyePosition().z)

    local perpendicularEyeGroundPos = Vector(Entities:GetLocalPlayer():EyePosition().x, Entities:GetLocalPlayer():EyePosition().y, Entities:GetLocalPlayer():GetAbsOrigin().z)

    calibrateOrientationEntity:SetOrigin(orientationEntFinalPos)

    DebugDrawLine(handRPos, handLPos, debugColor.x, debugColor.y, debugColor.z, false, 0)
    DebugDrawLine(midPointVector, Vector(midPointVector.x, midPointVector.y, Entities:GetLocalPlayer():EyePosition().z), debugColor.x, debugColor.y, debugColor.z, false, 0)
    --In front of the eyes sphere
    DebugDrawSphere(midPointVectorEyeLevel, debugColor, 255, 2, false, 0)
    DebugDrawLine(midPointVector, perpendicularPosition, debugColor.x, debugColor.y, debugColor.z, false, 0)
    DebugDrawLine(perpendicularPosition, orientationEntFinalPos, debugColor.x, debugColor.y, debugColor.z, false, 0)
    --Target sphere
    DebugDrawSphere(orientationEntFinalPos, debugColor, 255, 2, false, 0)
    --Ground perpendicularToEyes sphere
    DebugDrawSphere(perpendicularEyeGroundPos, debugColor, 255, 2, false, 0)

    print(VectorDistance(perpendicularEyeGroundPos, midPointVector))

    if isCalibrating then
        debugText:SetMessage(tostring(countDown+1))
        debugText:SetOrigin(Vector(orientationEntFinalPos.x, orientationEntFinalPos.y, orientationEntFinalPos.z + countDownPosOffset))
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