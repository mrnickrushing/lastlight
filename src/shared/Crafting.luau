--!strict

local CraftingCatalog = require("./CraftingCatalog")

local Crafting = {}

local MAX_GEAR_COUNT = 999999

function Crafting.default(): { [string]: number }
    return {}
end

function Crafting.normalizeGear(value: any): { [string]: number }
    local gear: { [string]: number } = {}
    if type(value) ~= "table" then
        return gear
    end
    for itemId, count in value do
        if CraftingCatalog.isKnownOutputItem(itemId) and type(count) == "number" and count >= 0 then
            gear[itemId] = math.clamp(math.floor(count), 0, MAX_GEAR_COUNT)
        end
    end
    return gear
end

-- Deducts a recipe's material cost and grants one of its output item, or
-- leaves both inputs untouched if the recipe is unknown or unaffordable.
-- Materials and gear are validated and cloned independently of SaveSchema so
-- this stays testable as a pure transaction, the same way ExpeditionInventory
-- keeps its own reward/settlement math out of the profile module.
function Crafting.craft(
    materials: { [string]: number },
    gear: { [string]: number },
    recipeId: any
): ({ [string]: number }, { [string]: number }, any)
    if not CraftingCatalog.isValid(recipeId) then
        return materials,
            gear,
            {
                applied = false,
                reason = "unknown_recipe",
            }
    end

    local recipe = CraftingCatalog.get(recipeId) :: CraftingCatalog.Recipe
    for materialId, amount in recipe.materials do
        if (materials[materialId] or 0) < amount then
            return materials,
                gear,
                {
                    applied = false,
                    reason = "insufficient_materials",
                    recipeId = recipeId,
                }
        end
    end

    local nextMaterials = table.clone(materials)
    for materialId, amount in recipe.materials do
        nextMaterials[materialId] = nextMaterials[materialId] - amount
    end

    local nextGear = table.clone(gear)
    nextGear[recipe.outputItemId] =
        math.min(MAX_GEAR_COUNT, (nextGear[recipe.outputItemId] or 0) + 1)

    return nextMaterials,
        nextGear,
        {
            applied = true,
            itemId = recipe.outputItemId,
            recipeId = recipeId,
        }
end

-- Consumes exactly one owned unit of a crafted item, or leaves gear
-- untouched if the item ID is unknown or none are owned. Deliberately
-- doesn't know what using the item does — that effect lives in whichever
-- service applies it — this only owns the atomic decrement.
function Crafting.useItem(gear: { [string]: number }, itemId: any): ({ [string]: number }, any)
    if not CraftingCatalog.isKnownOutputItem(itemId) then
        return gear, {
            applied = false,
            reason = "unknown_item",
        }
    end

    local owned = gear[itemId] or 0
    if owned < 1 then
        return gear,
            {
                applied = false,
                itemId = itemId,
                reason = "not_owned",
            }
    end

    local nextGear = table.clone(gear)
    nextGear[itemId] = owned - 1
    return nextGear, {
        applied = true,
        itemId = itemId,
    }
end

return table.freeze(Crafting)
