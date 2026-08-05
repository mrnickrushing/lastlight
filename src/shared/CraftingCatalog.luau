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
    "recipe_ironroot_hood",
    "recipe_bramble_boots",
    "recipe_thornwood_bow",
    "recipe_heartwood_maul",
    "recipe_briar_lance",
    "recipe_foxfire_sling",
    "recipe_amber_edge",
    "recipe_warden_cudgel",
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
    recipe_ironroot_hood = table.freeze({
        id = "recipe_ironroot_hood",
        displayName = "IRONROOT HOOD",
        outputItemId = "gear_ironroot_hood",
        outputDisplayName = "Ironroot Hood",
        materials = table.freeze({
            material_heartwood = 5,
            material_amber_sap = 3,
        }),
    }),
    recipe_bramble_boots = table.freeze({
        id = "recipe_bramble_boots",
        displayName = "BRAMBLE BOOTS",
        outputItemId = "gear_bramble_boots",
        outputDisplayName = "Bramble Boots",
        materials = table.freeze({
            material_meadow_fiber = 5,
            material_brightcap = 3,
        }),
    }),
    recipe_thornwood_bow = table.freeze({
        id = "recipe_thornwood_bow",
        displayName = "THORNWOOD BOW",
        outputItemId = "gear_thornwood_bow",
        outputDisplayName = "Thornwood Bow",
        materials = table.freeze({
            material_heartwood = 4,
            material_meadow_fiber = 3,
        }),
    }),
    recipe_heartwood_maul = table.freeze({
        id = "recipe_heartwood_maul",
        displayName = "HEARTWOOD MAUL",
        outputItemId = "gear_heartwood_maul",
        outputDisplayName = "Heartwood Maul",
        materials = table.freeze({
            material_heartwood = 6,
            material_spring_clay = 2,
        }),
    }),
    recipe_briar_lance = table.freeze({
        id = "recipe_briar_lance",
        displayName = "BRIAR LANCE",
        outputItemId = "gear_briar_lance",
        outputDisplayName = "Briar Lance",
        materials = table.freeze({
            material_heartwood = 3,
            material_meadow_fiber = 4,
        }),
    }),
    recipe_foxfire_sling = table.freeze({
        id = "recipe_foxfire_sling",
        displayName = "FOXFIRE SLING",
        outputItemId = "gear_foxfire_sling",
        outputDisplayName = "Foxfire Sling",
        materials = table.freeze({
            material_meadow_fiber = 4,
            material_brightcap = 3,
        }),
    }),
    recipe_amber_edge = table.freeze({
        id = "recipe_amber_edge",
        displayName = "AMBER EDGE",
        outputItemId = "gear_amber_edge",
        outputDisplayName = "Amber Edge",
        materials = table.freeze({
            material_amber_sap = 4,
            material_heartwood = 3,
        }),
    }),
    recipe_warden_cudgel = table.freeze({
        id = "recipe_warden_cudgel",
        displayName = "WARDEN CUDGEL",
        outputItemId = "gear_warden_cudgel",
        outputDisplayName = "Warden Cudgel",
        materials = table.freeze({
            material_heartwood = 4,
            material_spring_clay = 3,
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
    IronrootHood = "recipe_ironroot_hood",
    BrambleBoots = "recipe_bramble_boots",
    ThornwoodBow = "recipe_thornwood_bow",
    HeartwoodMaul = "recipe_heartwood_maul",
    BriarLance = "recipe_briar_lance",
    FoxfireSling = "recipe_foxfire_sling",
    AmberEdge = "recipe_amber_edge",
    WardenCudgel = "recipe_warden_cudgel",
})

return table.freeze(CraftingCatalog)
