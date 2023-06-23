local luaUtils = require("utils.luaUtils")
local beeUtils = {}

-- Converts the slot info to the correct bee format
--
-- Replace species table (which contains temp, humidity, etc) with just the species name.
-- This simplifies the optimizer code since it does not have to take into consideration
-- nested tables.
function beeUtils.convertToBeeFormat(slotInfo)
    slotInfo.individual.active.species = slotInfo.individual.active.species.name
    slotInfo.individual.inactive.species = slotInfo.individual.inactive.species.name
    return slotInfo
end

function beeUtils.equivalentTraits(traitA, traitB)
    if (type(traitA) == "number" and type(traitB) == "number") then
        return luaUtils.areEqualFloats(traitA, traitB, 0.01)
    end
    return traitA == traitB
end

-- Returns a table with the number of matches for each property
-- If both the active and inactive traits match, the match count is 2.
-- If only one of them matches, the match count is 1.
-- If neither of them match, the match count is 0.
function beeUtils.getTargetMatches(bee, target)
    local matches = {}
    for propertyName, propertyInfo in pairs(target) do
        local active = bee.individual.active[propertyName]
        local inactive = bee.individual.inactive[propertyName]

        local propertyMatch = 0
        if (beeUtils.equivalentTraits(active, propertyInfo.trait)) then
            propertyMatch = propertyMatch + 1
        end
        if (beeUtils.equivalentTraits(inactive, propertyInfo.trait)) then
            propertyMatch = propertyMatch + 1
        end

        matches[propertyName] = propertyMatch
    end
    return matches
end

function beeUtils.getMaxPossibleProgress(target)
    local sum = 0
    for k, v in pairs(target) do sum = sum + 2 end
    return sum
end

function beeUtils.getProgress(bee, target)
    local sum = 0
    for k, v in pairs(beeUtils.getTargetMatches(bee, target)) do
        sum = sum + v
    end
    return sum
end

local function hasLabelWithSubstring(obj, substring)
    if obj and obj.label and obj.label:find(substring) ~= nil then
        return true
    end
    return false
end

function beeUtils.isPrincess(bee) return hasLabelWithSubstring(bee, "Princess") end

function beeUtils.isDrone(bee) return hasLabelWithSubstring(bee, "Drone") end

function beeUtils.isQueen(bee) return hasLabelWithSubstring(bee, "Queen") end

return beeUtils
