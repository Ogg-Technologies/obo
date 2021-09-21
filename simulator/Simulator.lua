local optimizer = require("optimizers.DiminishingTraitsOptimizer")
local mockDrones = require("simulator.MockDrones")
local beeUtils = require("utils.beeUtils")
local luaUtils = require("utils.luaUtils")

local target = {
    caveDwelling = {trait = true, importance = 1},
    effect = {trait = "None", importance = 1},
    fertility = {trait = 4.0, importance = 1},
    flowerProvider = {trait = "Flowers", importance = 1},
    lifespan = {trait = 10.0, importance = 1},
    nocturnal = {trait = true, importance = 1},
    species = {trait = "Cultivated", importance = 1},
    speed = {trait = 1.2000000476837, importance = 1},
    tolerantFlyer = {trait = true, importance = 1}
}

local function evenProbability()
    if math.random() < 0.5 then return true end
    return false
end

local function createChildDrone(princess, drone)
    local child = mockDrones.createDrones()
    for propertyName, _ in pairs(child.individual.active) do
        local princessTrait = princess.individual.active[propertyName]
        if (evenProbability()) then
            princessTrait = princess.individual.inactive[propertyName]
        end

        local droneTrait = drone.individual.active[propertyName]
        if (evenProbability()) then
            droneTrait = drone.individual.inactive[propertyName]
        end

        if (evenProbability()) then
            child.individual.active[propertyName] = princessTrait
            child.individual.inactive[propertyName] = droneTrait
        else
            child.individual.active[propertyName] = droneTrait
            child.individual.inactive[propertyName] = princessTrait
        end
    end
    return child
end

local function simulateGeneration(princess, drone)
    local result = {}

    result.princess = createChildDrone(princess, drone)
    local nrDrones = princess.individual.active.fertility
    result.drones = {}
    for i = 1, nrDrones do
        result.drones[i] = createChildDrone(princess, drone)
    end
    return result
end

local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local function logProgress(princess, drone)
    local princessProgress = beeUtils.getProgress(princess, target)
    local droneProgress = beeUtils.getProgress(drone, target)
    local maxPossibleProgress = beeUtils.getMaxPossibleProgress(target)
    local princessStr = "Princess (" .. tostring(princessProgress) .. "/" ..
                            tostring(maxPossibleProgress) .. ")"
    local droneStr = "Drone (" .. tostring(droneProgress) .. "/" ..
                         tostring(maxPossibleProgress) .. ")"
    print(princessStr, droneStr)
end

-- Initialize RNG
math.randomseed(os.time())
math.random()
math.random()
math.random()
math.random()

local allDrones = {
    mockDrones.createDrones({species = "Imperial"}, 32),
    mockDrones.createDrones({speed = 0.4}, 32)
}
local currentPrincess = mockDrones.createDrones({
    species = "Industrious",
    lifespan = 5
})

for generation = 1, 10 do
    local bestDroneIndex = optimizer.getBestDroneIndex(allDrones,
                                                       currentPrincess, target)
    local chosenDrone = luaUtils.deepCopy(allDrones[bestDroneIndex])
    chosenDrone.size = 1
    local nrOfBestDrones = allDrones[bestDroneIndex].size
    if nrOfBestDrones == 1 then
        table.remove(allDrones, bestDroneIndex)
    else
        allDrones[bestDroneIndex].size = nrOfBestDrones - 1
    end

    logProgress(currentPrincess, chosenDrone)

    local generationResult = simulateGeneration(currentPrincess, chosenDrone)
    for _, drone in pairs(generationResult.drones) do
        table.insert(allDrones, drone)
    end

    currentPrincess = generationResult.princess
end
