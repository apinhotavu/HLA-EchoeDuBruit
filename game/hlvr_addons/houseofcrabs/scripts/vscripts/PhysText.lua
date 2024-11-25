function Precache(context)
    PrecacheModel("beer_bottle_1.vmdl", context)
end

function TextToPlayerAttachement()
    print("physText")

    local physText = Entities:FindByName(nil, "text_panel2")
    local phys = Entities:FindByName(nil, "prop_physics_override")
    local playerHandR = Entities:GetLocalPlayer():GetHMDAvatar():GetVRHand(1)

    local test = SpawnEntityFromTableSynchronous("prop_physics_override", nil)
    test:SetModel("beer_bottle_1.vmdl")

    --physText:SetAbsOrigin(playerHandR:GetAbsOrigin())
    --physText:SetParent(playerHandR, "") 
end