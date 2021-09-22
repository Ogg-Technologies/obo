local luaUtils = require("utils.luaUtils")
local beeUtils = require("utils.beeUtils")
local optimizer = {}

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

local function calculatePairScore(princess, drone, target)
    local score = 0
    local droneMatches = beeUtils.getTargetMatches(drone, target)
    local princessMatches = beeUtils.getTargetMatches(princess, target)
    for propertyName, droneMatch in pairs(droneMatches) do
        local princessMatch = princessMatches[propertyName]
        score = score + calculatePropertyScore(princessMatch, droneMatch,
                                               target[propertyName].importance)
    end
    return score
end

local function calculatePairScores(princess, drones, target)
    local scores = {}
    for i = 1, #drones do
        scores[i] = 0
        local stack = drones[i]
        if (stack and beeUtils.isDrone(stack)) then
            scores[i] = calculatePairScore(princess, stack, target)
        end
    end
    return scores
end

function optimizer.getBestDroneIndex(drones, princess, target)
    local pairScores = calculatePairScores(princess, drones, target)
    return luaUtils.indexOfGreatest(pairScores)
end

return optimizer
