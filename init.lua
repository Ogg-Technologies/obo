local component = require("component")
local ic = component.inventory_controller
local utils = require("./utils")
local sides = require("sides")
local robot = require("robot")

local function isApiaryRunning()
    local queenSlot = ic.getStackInSlot(sides.top, 1)
    if (not queenSlot) then return false end
    return utils.isQueen(queenSlot)
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
            if (utils.isPrincess(stack) or utils.isDrone(stack) or
                utils.isQueen(stack)) then
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
        if (stack and utils.isPrincess(stack)) then
            ic.suckFromSlot(sides.down, i, 1)
            return true
        end
    end
    return false
end

-- Waits until the provided function returns false
local function waitWhile(func) while (func()) do os.sleep(5) end end

local function calculatePairScores(princess)
    local scores = {}
    for i = 1, ic.getInventorySize(sides.down) do
        scores[i] = 0
        local stack = ic.getStackInSlot(sides.down, i)
        if (stack and utils.isDrone(stack)) then
            scores[i] = utils.calculatePairScore(princess, stack)
        end
    end
    return scores
end

local function pickupBestDrone(princess)
    robot.select(2)
    local pairScores = calculatePairScores(princess)
    local bestDroneSlotIndex = utils.indexOfGreatest(pairScores)
    ic.suckFromSlot(sides.down, bestDroneSlotIndex, 1)
end

local function logProgress(princess, drone)
    local princessProgress = utils.getProgress(princess)
    local droneProgress = utils.getProgress(drone)
    local maxPossibleProgress = utils.getMaxPossibleProgress()
    local princessStr = "Princess (" .. tostring(princessProgress) .. "/" ..
                            tostring(maxPossibleProgress) .. ")"
    local droneStr = "Drone (" .. tostring(droneProgress) .. "/" ..
                         tostring(maxPossibleProgress) .. ")"
    print(princessStr, droneStr)
end

local function startApiary()
    robot.select(1)
    ic.dropIntoSlot(sides.up, 1)
    robot.select(2)
    ic.dropIntoSlot(sides.up, 2)
end

while true do
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
    local princess = ic.getStackInInternalSlot(1)
    print("finding the best drone for the princess")
    pickupBestDrone(princess)
    local drone = ic.getStackInInternalSlot(2)
    logProgress(princess, drone)
    print("starting apiary")
    startApiary()
    os.sleep(10)
end
