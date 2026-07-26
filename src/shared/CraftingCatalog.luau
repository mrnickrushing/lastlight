--!strict

local CraftingCatalog = {}

export type Recipe = {
    id: string,
    displayName: string,
    outputItemId: string,
    outputDisplayName: string,
    materials: { [string]: number },
}

local ORDER = table.freeze({
    "recipe_meadow_satchel",
    "recipe_amber_charm",
})

local DEFINITIONS: { [string]: Recipe } = {
    recipe_meadow_satchel = table.freeze({
        id = "recipe_meadow_satchel",
        displayName = "MEADOW SATCHEL",
        outputItemId = "gear_meadow_satchel",
        outputDisplayName = "Meadow Satchel",
        materials = table.freeze({
            material_meadow_fiber = 3,
            material_heartwood = 2,
        }),
    }),
    recipe_amber_charm = table.freeze({
        id = "recipe_amber_charm",
        displayName = "AMBER CHARM",
        outputItemId = "gear_amber_charm",
        outputDisplayName = "Amber Charm",
        materials = table.freeze({
            material_amber_sap = 2,
            material_brightcap = 2,
        }),
    }),
}

function CraftingCatalog.isValid(id: any): boolean
    return type(id) == "string" and DEFINITIONS[id] ~= nil
end

function CraftingCatalog.get(id: string): Recipe?
    return DEFINITIONS[id]
end

function CraftingCatalog.list(): { Recipe }
    local result = {}
    for _, id in ORDER do
        table.insert(result, DEFINITIONS[id])
    end
    return result
end

function CraftingCatalog.isKnownOutputItem(itemId: any): boolean
    if type(itemId) ~= "string" then
        return false
    end
    for _, id in ORDER do
        if DEFINITIONS[id].outputItemId == itemId then
            return true
        end
    end
    return false
end

CraftingCatalog.Ids = table.freeze({
    MeadowSatchel = "recipe_meadow_satchel",
    AmberCharm = "recipe_amber_charm",
})

return table.freeze(CraftingCatalog)
