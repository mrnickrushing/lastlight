--!strict

--[[
    Equipment wear and repair -- the M6 "repair" deliverable, scoped to
    weapons first: a blade dulls as it lands blows, and whetting it costs
    half its own recipe. Wear is friendly by design: a worn weapon works at
    half strength and a failing one stops helping, but nothing is ever
    destroyed or unequipped -- the player is nudged to the bench, not
    punished with loss.

    Pure state math over { [itemId]: wearPoints 0..100 }; the profile owns
    persistence and the server owns when wear accrues. A client never
    submits wear.
]]

local CraftingCatalog = require("./CraftingCatalog")

local GearWear = {}

local MAX_WEAR = 100
local WORN_AT = 60

export type Wear = { [string]: number }

function GearWear.default(): Wear
    return {}
end

function GearWear.normalize(value: any): Wear
    local wear: Wear = {}
    if type(value) ~= "table" then
        return wear
    end
    for itemId, points in value do
        if
            CraftingCatalog.isKnownOutputItem(itemId)
            and type(points) == "number"
            and points > 0
        then
            wear[itemId] = math.clamp(math.floor(points), 0, MAX_WEAR)
        end
    end
    return wear
end

function GearWear.accrue(wear: Wear, itemId: any, points: number): (Wear, any)
    if not CraftingCatalog.isKnownOutputItem(itemId) then
        return wear, { applied = false, reason = "unknown_item" }
    end
    if type(points) ~= "number" or points <= 0 then
        return wear, { applied = false, reason = "invalid_points" }
    end
    local nextWear = table.clone(wear)
    local before = nextWear[itemId] or 0
    local after = math.clamp(before + math.floor(points), 0, MAX_WEAR)
    nextWear[itemId] = after
    return nextWear,
        {
            applied = after ~= before,
            points = after,
            conditionBefore = GearWear.condition(wear, itemId),
            conditionAfter = GearWear.conditionForPoints(after),
        }
end

function GearWear.conditionForPoints(points: number): string
    if points >= MAX_WEAR then
        return "failing"
    elseif points >= WORN_AT then
        return "worn"
    end
    return "sound"
end

function GearWear.condition(wear: Wear, itemId: any): string
    return GearWear.conditionForPoints(if type(itemId) == "string" then wear[itemId] or 0 else 0)
end

-- What remains of the item's identity at its current wear: full, half, or
-- nothing. Consumers multiply their own stat by this rather than knowing
-- the thresholds.
function GearWear.effectiveness(wear: Wear, itemId: any): number
    local condition = GearWear.condition(wear, itemId)
    if condition == "failing" then
        return 0
    elseif condition == "worn" then
        return 0.5
    end
    return 1
end

-- Half the item's own recipe, rounded up per material: repair always costs
-- something, and always costs less than crafting anew.
function GearWear.repairCost(itemId: any): { [string]: number }?
    if type(itemId) ~= "string" then
        return nil
    end
    for _, recipe in CraftingCatalog.list() do
        if recipe.outputItemId == itemId then
            local cost: { [string]: number } = {}
            for materialId, amount in recipe.materials do
                cost[materialId] = math.max(1, math.ceil(amount / 2))
            end
            return cost
        end
    end
    return nil
end

function GearWear.repair(
    wear: Wear,
    materials: { [string]: number },
    itemId: any
): (Wear, { [string]: number }, any)
    local cost = GearWear.repairCost(itemId)
    if cost == nil then
        return wear, materials, { applied = false, reason = "unknown_item" }
    end
    if (wear[itemId] or 0) <= 0 then
        return wear, materials, { applied = false, reason = "not_worn" }
    end
    for materialId, amount in cost do
        if (materials[materialId] or 0) < amount then
            return wear, materials, { applied = false, reason = "insufficient_materials" }
        end
    end
    local nextWear = table.clone(wear)
    nextWear[itemId] = nil
    local nextMaterials = table.clone(materials)
    for materialId, amount in cost do
        nextMaterials[materialId] -= amount
    end
    return nextWear, nextMaterials, { applied = true, cost = cost }
end

GearWear.Constants = table.freeze({
    MaxWear = MAX_WEAR,
    WornAt = WORN_AT,
})

return table.freeze(GearWear)
