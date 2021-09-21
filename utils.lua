local component = require("component")
local serial = require("serialization")
local config = require("./config")
local target = config.target
local utils = {}

local function areEqualFloats(a, b, precision) return
    math.abs(a - b) < precision end

local function equivalentTraits(traitA, traitB)
    if (type(traitA) == "number" and type(traitB) == "number") then
        return areEqualFloats(traitA, traitB, 0.01)
    end
    return traitA == traitB
end

local function getTargetMatches(bee)
    local matches = {}
    for propertyName, propertyInfo in pairs(target) do
        local active = bee.individual.active[propertyName]
        local inactive = bee.individual.inactive[propertyName]

        local propertyMatch = 0
        if (equivalentTraits(active, propertyInfo.trait)) then
            propertyMatch = propertyMatch + 1
        end
        if (equivalentTraits(inactive, propertyInfo.trait)) then
            propertyMatch = propertyMatch + 1
        end

        matches[propertyName] = propertyMatch
    end
    return matches
end

function utils.getMaxPossibleProgress()
    local sum = 0
    for k, v in pairs(target) do sum = sum + 2 end
    return sum
end

function utils.getProgress(bee)
    local sum = 0
    for k, v in pairs(getTargetMatches(bee)) do sum = sum + v end
    return sum
end

function utils.isPrincess(bee)
    local index = bee.label:find("Princess")
    return index ~= nil
end

function utils.isDrone(bee)
    local index = bee.label:find("Drone")
    return index ~= nil
end

function utils.isQueen(bee)
    local index = bee.label:find("Queen")
    return index ~= nil
end

function utils.write(obj)
    local f = io.open("output.txt", "w")
    f:write(serial.serialize(obj, 999999))
    f:close()
end

local function calculatePropertyScore(princessMatch, droneMatch, importance)
    local propertyScore = droneMatch
    if (princessMatch == 0) then
        propertyScore = propertyScore * 100
    elseif (princessMatch == 1) then
        propertyScore = propertyScore * 10
    end
    propertyScore = propertyScore * importance
    return propertyScore
end

function utils.calculatePairScore(princess, drone)
    local score = 0
    local droneMatches = getTargetMatches(drone)
    local princessMatches = getTargetMatches(princess)
    for propertyName, droneMatch in pairs(droneMatches) do
        local princessMatch = princessMatches[propertyName]
        score = score + calculatePropertyScore(princessMatch, droneMatch,
                                               target[propertyName].importance)
    end
    return score
end

function utils.indexOfGreatest(numberTable)
    local greatestIndex = 1
    local greatest = numberTable[greatestIndex]
    for i = 1, #numberTable do
        if (numberTable[i] > greatest) then
            greatest = numberTable[i]
            greatestIndex = i
        end
    end
    return greatestIndex
end

return utils
