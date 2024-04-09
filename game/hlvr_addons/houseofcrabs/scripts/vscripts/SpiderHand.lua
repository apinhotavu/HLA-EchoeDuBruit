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

local handAttachments = {
    "fingertip_index",
    "fingertip_middle",
    "fingertip_ring",
    "fingertip_pinky",
    "fingertip_thumb"
}

local zombieAttachments = {
    "foot_l",
    "foot_r",
    "guts",
    "chest",
    "eyes"
}

local maxDistance = 300

local ptArray = {}

function Activate()
    thisEntity:SetContextThink("SpiderHand", SpiderHand, 0)
    ListenToGameEvent("npc_ragdoll_created", ApplyImpulse, nil)
end

function SpiderHand()

    local playerHMD = Entities:GetLocalPlayer():GetHMDAvatar()

    if playerHMD == nil then
        do return end
    end

    local handR = playerHMD:GetVRHand(1)
    local handL = playerHMD:GetVRHand(0)

    if Entities:GetLocalPlayer():IsDigitalActionOnForHand(handR:GetLiteralHandType(), 7) then
        if handActionState == handActionStateEnum.NO_ACTION then
            print("Hold")
            DeleteParticles()
            actionTargetState = actionTargetStateEnum.NO_ACTION
            handActionState = handActionStateEnum.ACTION
        end
    elseif handActionState == handActionStateEnum.ACTION then
        print("Release")
        TrajectoryRay(handR, handL)
        handActionState = handActionStateEnum.NO_ACTION
    end

    if handR:GetVelocity().x > Vector(50,50,0).x and actionTargetState == actionTargetStateEnum.ACTION then
        print("Ragdoll ma poule")
        actionTargetState = actionTargetStateEnum.NO_ACTION
        DeleteParticles()
        Entities:FindByName(nil, "logic_zombie"):Trigger(nil, nil)
    end

    if handActionState == handActionStateEnum.ACTION then
        --TrajectoryRay(handR, handL)
    end
    --print(handR:GetVelocity())
    return 0
end

function ApplyImpulse()
    local hand = Entities:GetLocalPlayer():GetHMDAvatar():GetVRHand(1)
    Entities:FindByName(nil, "npc_zombie"):ApplyAbsVelocityImpulse(Entities:FindByName(nil, "npc_zombie"):GetUpVector() * 300)
    Entities:FindByName(nil, "logic_zombie_unragdoll"):Trigger(nil, nil)
end

function TrajectoryRay(handR, handL)

    --Use hand angle - eye angle to get the middle vector between eye and hand direction
    local playerEyeAngle = AnglesToVector(Entities:GetLocalPlayer():EyeAngles())
    
    for i = 1, 5, 1 do
        local newVectorPlayerEyeAngle = Vector(playerEyeAngle.x, playerEyeAngle.y, playerEyeAngle.z)
        
        --Store previous pos to use it as the minimum pos for next finger
        local newI = (i*i)
        local traceTable = {
            startpos = handR:GetCenter();
            endpos = Vector(handR:GetCenter().x + RandomFloat(-newI, newI), handR:GetCenter().y+ RandomFloat(-newI, newI),handR:GetCenter().z+ RandomFloat(-newI, newI)) + handR:GetForwardVector() + newVectorPlayerEyeAngle * maxDistance;
            ignore = Entities:GetLocalPlayer();
        }
    
        TraceLine(traceTable)

        --DebugDrawLine(traceTable.startpos, traceTable.pos, 255, 0, 0, false, 5)
        --DebugDrawSphere(traceTable.pos, Vector(255,0,0), 255,2,false,5)

        if traceTable.hit then
            ptArray[i] = ParticleManager:CreateParticle("particles/choreo/dog_grav_hand.vpcf", PATTACH_POINT, Entities:GetLocalPlayer())
            ParticleManager:SetParticleControlEnt(ptArray[i], 0, handR, PATTACH_POINT_FOLLOW, handAttachments[i], Vector(0,0,0), false)
            if traceTable.enthit:GetName() == "npc_zombie" then
                actionTargetState = actionTargetStateEnum.ACTION
                ParticleManager:SetParticleControlEnt(ptArray[i], 3, Entities:FindByName(nil, "npc_zombie"), PATTACH_POINT_FOLLOW, zombieAttachments[i], Vector(0,0,0), false)
            else
                ParticleManager:SetParticleControl(ptArray[i], 3, traceTable.pos)
            end
        end
    end
end

function DeleteParticles()
    if #ptArray ~= 0 then
        for i = 1, 30, 1 do
            if ptArray[i] ~= nil then ParticleManager:DestroyParticle(ptArray[i], true) end
        end
    end
end