local luaUtils = {}

function luaUtils.areEqualFloats(a, b, precision)
    return math.abs(a - b) < precision
end

function luaUtils.indexOfGreatest(numberTable)
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

function luaUtils.deepCopy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[luaUtils.deepCopy(k, s)] = luaUtils.deepCopy(v, s) end
    return res
end

return luaUtils
