--!strict

local ContentId = {}

local MIN_LENGTH = 3
local MAX_LENGTH = 64

function ContentId.kind(value: string): string?
    return string.match(value, "^([a-z][a-z0-9]*)_")
end

function ContentId.validate(value: any, expectedKind: string?): (boolean, string?)
    if type(value) ~= "string" then
        return false, "content ID must be a string"
    end

    if #value < MIN_LENGTH or #value > MAX_LENGTH then
        return false,
            string.format("content ID length must be %d-%d characters", MIN_LENGTH, MAX_LENGTH)
    end

    if
        string.match(value, "^[a-z][a-z0-9_]*$") == nil
        or not string.find(value, "_", 1, true)
        or string.find(value, "__", 1, true) ~= nil
        or string.sub(value, -1) == "_"
    then
        return false, "content ID must be lowercase snake case with a type prefix"
    end

    local kind = ContentId.kind(value)
    if expectedKind ~= nil and kind ~= expectedKind then
        return false, string.format("content ID must use the %s_ prefix", expectedKind)
    end

    return true, nil
end

return table.freeze(ContentId)
