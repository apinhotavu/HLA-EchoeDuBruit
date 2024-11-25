local handActionStateEnum = {
    NO_ACTION = 0,
    ACTION = 1
}
local handActionState = handActionStateEnum.NO_ACTION

local actionTargetStateEnum = {
    NO_ACTION = 0,
    ACTION = 1
}
local actionTargetState = actionTargetStateEnum.NO_ACTION

---@type CBaseEntity
local target = nil

---@type CBaseEntity
local screen = nil

---@type CBaseEntity
local camera = nil

---@type CBaseEntity
local handR = nil

---@type CBaseEntity
local handL = nil

local maxDistance = 100

function Activate()
    thisEntity:SetContextThink("PortalPlacement", PortalPlacement, 0)
end

function PortalPlacement()

    local playerHMD = Entities:GetLocalPlayer():GetHMDAvatar()

    if playerHMD == nil then
        do return end
    end
    
    target = Entities:GetLocalPlayer()
    screen = Entities:FindByName(nil, "portal")
    camera = Entities:FindByName(nil, "camera_map2D")

    handR = playerHMD:GetVRHand(1)
    handL = playerHMD:GetVRHand(0)

    if Entities:GetLocalPlayer():IsDigitalActionOnForHand(handR:GetLiteralHandType(), 7) then
        if handActionState == handActionStateEnum.NO_ACTION then
            actionTargetState = actionTargetStateEnum.NO_ACTION
            thisEntity:SetContextThink("TrajectoryRay", TrajectoryRay, 0)
            handActionState = handActionStateEnum.ACTION
        end
    elseif handActionState == handActionStateEnum.ACTION then
        thisEntity:StopThink("TrajectoryRay")
        handActionState = handActionStateEnum.NO_ACTION
    end
    
    return 0
end

function TrajectoryRay()
    local traceTable = {
        startpos = handR:GetCenter();
        endpos = Vector(handR:GetCenter().x, handR:GetCenter().y,handR:GetCenter().z) + (handR:GetForwardVector() - handR:GetUpVector()) * maxDistance;
        ignore = Entities:GetLocalPlayer();
    }

    TraceLine(traceTable)

    local finalPos = Vector(traceTable.pos.x, traceTable.pos.y, target:EyePosition().z)

    DebugDrawLine(traceTable.startpos, traceTable.pos, 255, 0, 0, false, 0)
    DebugDrawSphere(traceTable.pos, Vector(255,0,0), 255,2,false,0)
    DebugDrawSphere(finalPos, Vector(255,0,0), 255,2,false,0)

    SetCameraPosition(finalPos)
    LookAt()
    
    return 0
end

function SetCameraPosition(position)
    local angle = Vector(-screen:GetAngles().z, screen:GetAngles().y+90, screen:GetAngles().x)

    screen:SetAbsOrigin(position)
    camera:SetAbsOrigin(Vector(position.x+1000, position.y, position.z))
    camera:SetLocalAngles(angle.x, angle.y, 0)
end

function LookAt()
    local origin = screen:GetOrigin()
    local direction = (origin - target:EyePosition()):Normalized()
  
    local pitch = 0
    if direction.x ~= 0 or direction.y ~= 0 then
        pitch = math.deg(math.atan(direction.z / math.sqrt((direction.x ^ 2) + (direction.y ^ 2))))
    end

    local yaw = 0
    if direction.x ~= 0 then
        yaw = math.deg(math.atan(direction.y / direction.x)) - 90
    end

    if direction.x < 0 then
        yaw = yaw + 180
    end

    screen:SetLocalAngles(0, yaw, 0)
end