-- local optimizer = require("optimizers.DiminishingTraitsOptimizer")
-- local optimizer = require("optimizers.MixingOptimizer")
local mockDrones = require("simulator.MockDrones")
local beeUtils = require("utils.beeUtils")
local luaUtils = require("utils.luaUtils")

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

local function logProgress(princess, drone, target, generation)
    local princessProgress = beeUtils.getProgress(princess, target)
    local droneProgress = beeUtils.getProgress(drone, target)
    local maxPossibleProgress = beeUtils.getMaxPossibleProgress(target)
    local princessStr = "Princess (" .. tostring(princessProgress) .. "/" ..
                            tostring(maxPossibleProgress) .. ")"
    local droneStr = "Drone (" .. tostring(droneProgress) .. "/" ..
                         tostring(maxPossibleProgress) .. ")"
    print("Generation " .. tostring(generation), princessStr, droneStr)
end

local function isFinished(princess, drone, target)
    local princessProgress = beeUtils.getProgress(princess, target)
    local droneProgress = beeUtils.getProgress(drone, target)
    local maxPossibleProgress = beeUtils.getMaxPossibleProgress(target)
    if (princessProgress == maxPossibleProgress and droneProgress ==
        maxPossibleProgress) then return true end
    return false
end

local simulator = {}

-- Uses the optimizer on a simulated bee environment to calculate the number
-- of generations required to get a perfect drone and princess
-- Returns the number of generations needed
function simulator.performSimulation(startingDrones, startingPrincess, target,
                                     optimizer, verbose)
    local currentDrones = luaUtils.deepCopy(startingDrones)
    local currentPrincess = luaUtils.deepCopy(startingPrincess)

    -- Initialize RNG
    math.randomseed(os.time())
    math.random()
    math.random()
    math.random()
    math.random()

    for generation = 1, 100 do
        local bestDroneIndex = optimizer.getBestDroneIndex(currentDrones,
                                                           currentPrincess,
                                                           target)
        local chosenDrone = luaUtils.deepCopy(currentDrones[bestDroneIndex])
        chosenDrone.size = 1
        local nrOfBestDrones = currentDrones[bestDroneIndex].size
        if nrOfBestDrones == 1 then
            table.remove(currentDrones, bestDroneIndex)
        else
            currentDrones[bestDroneIndex].size = nrOfBestDrones - 1
        end

        if verbose then
            logProgress(currentPrincess, chosenDrone, target, generation)
        end
        if (isFinished(currentPrincess, chosenDrone, target)) then
            if verbose then
                print("Finished after " .. tostring(generation) ..
                          " generations")
            end
            return generation
        end

        local generationResult =
            simulateGeneration(currentPrincess, chosenDrone)
        for _, drone in pairs(generationResult.drones) do
            table.insert(currentDrones, drone)
        end

        currentPrincess = generationResult.princess
    end

    return nil
end

return simulator
