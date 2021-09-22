local luaUtils = require("utils.luaUtils")
local mockDrones = {}

local targetDrone = {
    individual = {
        active = {
            caveDwelling = true,
            effect = "None",
            fertility = 4.0,
            flowerProvider = "Flowers",
            flowering = 5.0,
            humidityTolerance = "Both 1",
            lifespan = 10.0,
            nocturnal = true,
            species = "Cultivated",
            speed = 1.2000000476837,
            temperatureTolerance = "None",
            territory = {9.0, 6.0, 9.0, n = 3},
            tolerantFlyer = true
        },
        inactive = {
            caveDwelling = true,
            effect = "None",
            fertility = 4.0,
            flowerProvider = "Flowers",
            flowering = 5.0,
            humidityTolerance = "None",
            lifespan = 10.0,
            nocturnal = true,
            species = "Cultivated",
            speed = 1.2000000476837,
            temperatureTolerance = "None",
            territory = {9.0, 6.0, 9.0, n = 3},
            tolerantFlyer = true
        }
    },
    label = "Cultivated Drone",
    size = 1.0
}

function mockDrones.createDrones(targetEdits, amount, templateDrone)
    targetEdits = targetEdits or {}
    amount = amount or 1
    templateDrone = templateDrone or targetDrone
    local drone = luaUtils.deepCopy(templateDrone)
    for propertyName, propertyValue in pairs(targetEdits) do
        local ind = drone.individual
        if (ind.active[propertyName] == nil or ind.inactive[propertyName] == nil) then
            error(tostring(propertyName) .. " is not a valid drone property")
        end
        drone.individual.active[propertyName] = propertyValue
        drone.individual.inactive[propertyName] = propertyValue
    end
    if (targetEdits.species ~= nil) then
        drone.label = tostring(targetEdits.species) .. " Drone"
    end
    drone.size = amount
    return drone
end

return mockDrones
