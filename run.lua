local simulator = require("simulator.Simulator")
local component = require("component")
local beeUtils = require("utils.beeUtils")
local optimizer = require("optimizers.MixingOptimizer")
local ic = component.inventory_controller

local config = require("./config")
local target = config.target

local sides = require("sides")
local robot = require("robot")

local function isApiaryRunning()
    local queenSlot = ic.getStackInSlot(sides.top, 1)
    if (not queenSlot) then return false end
    return beeUtils.isQueen(queenSlot)
end

local function isAnalyzerRunning()
    local inputSlotIndicies = {1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
    local allSlotsEmpty = true
    for _, i in ipairs(inputSlotIndicies) do
        if (ic.getStackInSlot(sides.front, i) ~= nil) then
            allSlotsEmpty = false
            break
        end
    end
    return not allSlotsEmpty
end

-- Replace species table (which contains temp, humidity, etc) with just the species name.
-- This simplifies the optimizer code since it does not have to take into consideration
-- nested tables.
local function convertToBeeFormat(slotInfo)
    slotInfo.individual.active.species = slotInfo.individual.active.species.name
    slotInfo.individual.inactive.species = slotInfo.individual.inactive.species.name
    return slotInfo
end


local function unloadApiary()
    robot.select(1)
    local apiaryBeeSlots = {1, 2, 3, 4, 5, 6, 7, 8, 9}
    for _, i in ipairs(apiaryBeeSlots) do ic.suckFromSlot(sides.top, i) end
end

local function depositInventory()
    for i = 1, 16 do
        robot.select(i)
        local stack = ic.getStackInInternalSlot(i)
        if (stack) then
            if (beeUtils.isPrincess(stack) or beeUtils.isDrone(stack) or
                beeUtils.isQueen(stack)) then
                robot.drop()
            else
                robot.dropDown()
            end
        end
    end
end

local function pickupPrincess()
    robot.select(1)
    for i = 1, ic.getInventorySize(sides.down) do
        local stack = ic.getStackInSlot(sides.down, i)
        if (stack and beeUtils.isPrincess(stack)) then
            ic.suckFromSlot(sides.down, i, 1)
            return true
        end
    end
    return false
end

-- Waits until the provided function returns false
local function waitWhile(func) while (func()) do os.sleep(5) end end

local function getAllDrones()
    local drones = {}
    for i = 1, ic.getInventorySize(sides.down) do
        local stack = ic.getStackInSlot(sides.down, i)
        if stack and beeUtils.isDrone(stack) then
            drones[i] = convertToBeeFormat(stack)
        else
            drones[i] = "Non drone"
        end
    end
    return drones
end

local function pickupBestDrone(princess, drones, target)
    robot.select(2)
    local bestDroneIndex = optimizer.getBestDroneIndex(drones, princess, target)
    ic.suckFromSlot(sides.down, bestDroneIndex, 1)
end

local function startApiary()
    robot.select(1)
    ic.dropIntoSlot(sides.up, 1)
    robot.select(2)
    ic.dropIntoSlot(sides.up, 2)
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

local function logEstimatedNrGenerationRemaining(princess, drones, target)
    local simulationSuccess, errorMessage = pcall(function()
        local nrGen = simulator.performSimulation(drones, princess, target,
                                                  optimizer, false)
        print("Estimating " .. tostring(nrGen) .. " generations left")
    end)
    if not simulationSuccess then
        print("Simulation failed with error: " .. errorMessage)
    end
end

for generation = 1, 1000 do
    print("waiting for apiary")
    waitWhile(isApiaryRunning)
    print("unloading apiary")
    unloadApiary()
    print("depositing inventory")
    depositInventory()
    print("waiting for analyzer")
    if (isAnalyzerRunning()) then
        waitWhile(isAnalyzerRunning)
        os.sleep(10) -- Sometimes the bees don't get extracted immediately
    end
    print("finding princess")
    while (not pickupPrincess()) do
        print("failed to find princess, retrying in 10 seconds")
        os.sleep(10)
    end
    local princess = convertToBeeFormat(ic.getStackInInternalSlot(1))
    print("Fetching drone data")
    local drones = getAllDrones()

    if config.runSimulations then
        print("Starting simulation")
        logEstimatedNrGenerationRemaining(princess, drones, target)
    end

    print("finding the best drone for the princess")
    pickupBestDrone(princess, drones, target)
    local drone = convertToBeeFormat(ic.getStackInInternalSlot(2))
    logProgress(princess, drone, target, generation)
    print("starting apiary")
    startApiary()
    os.sleep(10)
end
