---@type CPointTemplate
local point_template = nil
---@type CPointTemplate
local activeSkybox = nil

--TODO: Add securities when the entity is not found.

function Activate()
    SpawnSkybox(1)
end

function UpdateSkybox(skyboxNumber)
    if activeSkybox ~= Entities:FindByName(nil, "skybox_reference"..skyboxNumber) then
        RemoveSkybox()
        SpawnSkybox(skyboxNumber)
    end
end

function SpawnSkybox(skyboxNumber)
    point_template = Entities:FindByName(nil, "skybox_template"..skyboxNumber)
    point_template:ForceSpawn()
    activeSkybox = Entities:FindByName(nil, "skybox_reference"..skyboxNumber)
end

function RemoveSkybox()
    if activeSkybox ~= nil then
        activeSkybox:Kill()
    end
end