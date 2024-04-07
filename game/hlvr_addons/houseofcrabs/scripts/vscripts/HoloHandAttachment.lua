---@type CBaseEntity
local target = nil

---@type CBaseEntity
local screen = nil

---@type CBaseEntity
local handpose = nil

---@type CBaseEntity
local camera = nil

function SetScreenAttachement()
    if (Entities:GetLocalPlayer():GetHMDAvatar() == nil) then
        do return end
    end

    target = Entities:GetLocalPlayer()
    screen = Entities:FindByName(nil, "camera_screen")
    camera = Entities:FindByName(nil, "camera_map2D")

    thisEntity:SetContextThink("SetCameraPosition", SetCameraPosition, 0)
end

function SetCameraPosition()

    local angle = Vector(-screen:GetAngles().z, screen:GetAngles().y+90, screen:GetAngles().x)

    local leftHand = Entities:GetLocalPlayer():GetHMDAvatar():GetVRHand(0)

    screen:SetAbsOrigin(Vector(leftHand:GetAbsOrigin().x, leftHand:GetAbsOrigin().y, leftHand:GetAbsOrigin().z))
    camera:SetAbsOrigin(Vector(leftHand:GetAbsOrigin().x-1000, leftHand:GetAbsOrigin().y, leftHand:GetAbsOrigin().z))
    camera:SetLocalAngles(angle.x, angle.y, angle.z)

    LookAt()

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