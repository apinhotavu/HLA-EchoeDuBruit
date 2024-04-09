local handActionStateEnum = {
    NO_ACTION = 0,
    ACTION = 1
}
local handActionState = handActionStateEnum.NO_ACTION

---@type CBaseEntity
local target = nil

---@type CBaseEntity
local screen = nil

---@type CBaseTrigger
local trigger = nil

---@type CBaseEntity
local camera = nil

local particle = 0

function SetScreenAttachement()
    if (Entities:GetLocalPlayer():GetHMDAvatar() == nil) then
        do return end
    end

    target = Entities:GetLocalPlayer()
    screen = Entities:FindByName(nil, "camera_screen")
    camera = Entities:FindByName(nil, "camera_map2D")
    trigger = Entities:FindByName(nil, "camera_trigger")

    thisEntity:SetContextThink("SetCameraPosition", SetCameraPosition, 0)
end

function SetCameraPosition()

    local angle = Vector(-screen:GetAngles().z, screen:GetAngles().y+90, screen:GetAngles().x)

    local leftHand = Entities:GetLocalPlayer():GetHMDAvatar():GetVRHand(0)

    screen:SetAbsOrigin(Vector(leftHand:GetAbsOrigin().x, leftHand:GetAbsOrigin().y, leftHand:GetAbsOrigin().z+5))
    camera:SetAbsOrigin(Vector(leftHand:GetAbsOrigin().x+1000, leftHand:GetAbsOrigin().y, leftHand:GetAbsOrigin().z))
    camera:SetLocalAngles(angle.x, angle.y, angle.z)

    LookAt()
    HandTriggerDetection()

    return 0
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

    screen:SetLocalAngles(0, yaw, pitch)
end

function HandTriggerDetection()
    
    if trigger:IsTouching(Entities:GetLocalPlayer():GetHMDAvatar():GetVRHand(1)) then
        if Entities:GetLocalPlayer():IsDigitalActionOnForHand(Entities:GetLocalPlayer():GetHMDAvatar():GetVRHand(1):GetLiteralHandType(), 7) then
            if handActionState == handActionStateEnum.NO_ACTION then
                --print("squezzing")
                particle = ParticleManager:CreateParticle("particles/choreo/dog_grav_hand.vpcf", PATTACH_POINT, screen)
                ParticleManager:SetParticleControlEnt(particle, 0, screen, PATTACH_POINT, nil, Vector(0,0,0), false)
                ParticleManager:SetParticleControlEnt(particle, 3, Entities:GetLocalPlayer():GetHMDAvatar():GetVRHand(1), PATTACH_POINT_FOLLOW, "vr_hand_origin", Vector(0,0,0), false)
                
                handActionState = handActionStateEnum.ACTION
            end
        end
    end

    if not Entities:GetLocalPlayer():IsDigitalActionOnForHand(Entities:GetLocalPlayer():GetHMDAvatar():GetVRHand(1):GetLiteralHandType(), 7) and handActionState == handActionStateEnum.ACTION then
        --print("drop")
        Entities:FindByName(nil, "tp_script_relay"):Trigger(nil, nil)
        DetachCameraHand()
        handActionState = handActionStateEnum.NO_ACTION
    end
end

function DetachCameraHand()
    ParticleManager:DestroyParticle(particle, true)
    thisEntity:StopThink("SetCameraPosition")
    screen:SetAbsOrigin(Vector(0,0,0))
end