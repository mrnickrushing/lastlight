--!strict

local Crafting = require("../../src/shared/Crafting")
local CraftingCatalog = require("../../src/shared/CraftingCatalog")
local TestRunner = require("../TestRunner")

return {
    name = "Crafting",
    cases = {
        {
            name = "crafts a known recipe by deducting its exact material cost",
            run = function()
                local materials = {
                    material_meadow_fiber = 3,
                    material_heartwood = 2,
                    material_amber_sap = 5,
                }
                local nextMaterials, nextGear, result =
                    Crafting.craft(materials, Crafting.default(), CraftingCatalog.Ids.MeadowSatchel)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(result.itemId, "gear_meadow_satchel")
                TestRunner.equal(nextMaterials.material_meadow_fiber, 0)
                TestRunner.equal(nextMaterials.material_heartwood, 0)
                TestRunner.equal(nextMaterials.material_amber_sap, 5)
                TestRunner.equal(nextGear.gear_meadow_satchel, 1)
            end,
        },
        {
            name = "rejects an unknown recipe without mutating either input",
            run = function()
                local materials = { material_meadow_fiber = 99 }
                local gear = { gear_meadow_satchel = 1 }
                local nextMaterials, nextGear, result =
                    Crafting.craft(materials, gear, "recipe_does_not_exist")
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.reason, "unknown_recipe")
                TestRunner.equal(nextMaterials, materials)
                TestRunner.equal(nextGear, gear)
            end,
        },
        {
            name = "rejects an unaffordable recipe without mutating either input",
            run = function()
                local materials = { material_amber_sap = 1, material_brightcap = 2 }
                local gear = Crafting.default()
                local nextMaterials, nextGear, result =
                    Crafting.craft(materials, gear, CraftingCatalog.Ids.AmberCharm)
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.reason, "insufficient_materials")
                TestRunner.equal(nextMaterials, materials)
                TestRunner.equal(nextGear, gear)
            end,
        },
        {
            name = "stacks repeated crafts of the same recipe",
            run = function()
                local materials = { material_amber_sap = 4, material_brightcap = 4 }
                local gear = Crafting.default()
                materials, gear = Crafting.craft(materials, gear, CraftingCatalog.Ids.AmberCharm)
                materials, gear = Crafting.craft(materials, gear, CraftingCatalog.Ids.AmberCharm)
                TestRunner.equal(gear.gear_amber_charm, 2)
                TestRunner.equal(materials.material_amber_sap, 0)
                TestRunner.equal(materials.material_brightcap, 0)
            end,
        },
        {
            name = "normalizeGear keeps only known crafted items with valid non-negative counts",
            run = function()
                local gear = Crafting.normalizeGear({
                    gear_meadow_satchel = 3,
                    gear_amber_charm = 1.7,
                    gear_unknown_item = 5,
                    gear_amber_charm_negative_ignored = -1,
                })
                TestRunner.equal(gear.gear_meadow_satchel, 3)
                TestRunner.equal(gear.gear_amber_charm, 1)
                TestRunner.equal(gear.gear_unknown_item, nil)
                TestRunner.equal(gear.gear_amber_charm_negative_ignored, nil)
            end,
        },
        {
            name = "normalizeGear rejects non-table input",
            run = function()
                local gear = Crafting.normalizeGear("not a table")
                TestRunner.equal(next(gear), nil)
            end,
        },
        {
            name = "useItem consumes exactly one owned unit",
            run = function()
                local gear = { gear_amber_charm = 2 }
                local nextGear, result = Crafting.useItem(gear, "gear_amber_charm")
                TestRunner.equal(result.applied, true)
                TestRunner.equal(result.itemId, "gear_amber_charm")
                TestRunner.equal(nextGear.gear_amber_charm, 1)
                TestRunner.equal(gear.gear_amber_charm, 2)
            end,
        },
        {
            name = "useItem rejects an item with none owned without mutating gear",
            run = function()
                local gear = { gear_amber_charm = 0 }
                local nextGear, result = Crafting.useItem(gear, "gear_amber_charm")
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.reason, "not_owned")
                TestRunner.equal(nextGear, gear)

                local emptyGear = Crafting.default()
                local stillEmpty, missingResult = Crafting.useItem(emptyGear, "gear_meadow_satchel")
                TestRunner.equal(missingResult.reason, "not_owned")
                TestRunner.equal(stillEmpty, emptyGear)
            end,
        },
        {
            name = "useItem rejects an unknown item ID without mutating gear",
            run = function()
                local gear = { gear_amber_charm = 3 }
                local nextGear, result = Crafting.useItem(gear, "gear_does_not_exist")
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.reason, "unknown_item")
                TestRunner.equal(nextGear, gear)
            end,
        },
    },
}
