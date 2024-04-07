local teleportXUnitValue = 1000

function TeleportToNextPos(value)
    if (Entities:GetLocalPlayer():GetHMDAvatar() == nil) then
        do return end
    end

    local player = Entities:GetLocalPlayer():GetHMDAvatar()
    local playerAnchor = Entities:GetLocalPlayer():GetHMDAnchor()
    local posTarget = Vector(player:GetAbsOrigin().x + (value * teleportXUnitValue), player:GetAbsOrigin().y, player:GetAbsOrigin().z)
    local posTargetAnchor = Vector(playerAnchor:GetAbsOrigin().x + (value * teleportXUnitValue), playerAnchor:GetAbsOrigin().y, playerAnchor:GetAbsOrigin().z)

    player:SetOrigin(posTarget)
    playerAnchor:SetOrigin(posTargetAnchor)
end