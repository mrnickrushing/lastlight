--!strict

local Environment = {}

export type Name = "local" | "test" | "staging" | "production"

export type ResolveInput = {
    isStudio: boolean,
    placeId: number,
    requested: string?,
    productionPlaceIds: { number },
}

local validNames: { [string]: boolean } = {
    ["local"] = true,
    test = true,
    staging = true,
    production = true,
}

local function contains(values: { number }, target: number): boolean
    for _, value in values do
        if value == target then
            return true
        end
    end

    return false
end

function Environment.isValid(value: string): boolean
    return validNames[value] == true
end

function Environment.resolve(input: ResolveInput): (Name?, string?)
    local requested = input.requested
    if requested ~= nil and not Environment.isValid(requested) then
        return nil, string.format("unknown environment %q", requested)
    end

    if input.isStudio then
        if requested == "test" then
            return "test", nil
        end

        if requested == nil or requested == "local" then
            return "local", nil
        end

        return nil, "staging and production environments cannot run in Roblox Studio"
    end

    local isProductionPlace = contains(input.productionPlaceIds, input.placeId)
    if isProductionPlace then
        if requested ~= nil and requested ~= "production" then
            return nil, "a production place cannot boot with a non-production environment"
        end

        return "production", nil
    end

    if requested == "production" then
        return nil, "production requires the current place ID in ProductionPlaceIds"
    end

    if requested == "local" or requested == "test" then
        return nil, "local and test environments require Roblox Studio"
    end

    return "staging", nil
end

return table.freeze(Environment)
