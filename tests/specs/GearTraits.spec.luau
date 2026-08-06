--!strict

local GearTraits = require("../../src/shared/GearTraits")
local SaveSchema = require("../../src/shared/SaveSchema")
local TestRunner = require("../TestRunner")

return {
    name = "GearTraits",
    cases = {
        {
            name = "the roll is deterministic per save and distinct across saves",
            run = function()
                local a = GearTraits.rollFor("gear_amber_edge", 1000)
                TestRunner.equal(a, GearTraits.rollFor("gear_amber_edge", 1000))
                TestRunner.truthy(GearTraits.isValidFor("gear_amber_edge", a))
                -- across many creation times, more than one trait appears
                local seen = {}
                for createdAt = 1, 40 do
                    seen[GearTraits.rollFor("gear_amber_edge", createdAt)] = true
                end
                local distinct = 0
                for _ in seen do
                    distinct += 1
                end
                TestRunner.truthy(distinct >= 2)
            end,
        },
        {
            name = "weapon and passive pools stay separate and junk is refused",
            run = function()
                TestRunner.equal(GearTraits.isValidFor("gear_ironroot_hood", "trait_keen"), false)
                TestRunner.equal(GearTraits.isValidFor("gear_amber_edge", "trait_sturdy"), false)
                TestRunner.equal(GearTraits.rollFor("gear_fake", 100), nil)
                local normalized = GearTraits.normalize({
                    gear_amber_edge = "trait_keen",
                    gear_ironroot_hood = "trait_keen",
                    laser = "trait_keen",
                })
                TestRunner.equal(normalized.gear_amber_edge, "trait_keen")
                TestRunner.equal(normalized.gear_ironroot_hood, nil)
                TestRunner.equal(normalized.laser, nil)
            end,
        },
        {
            name = "the first craft rolls; the second keeps the first roll",
            run = function()
                local profile = SaveSchema.default(1234)
                profile.inventory.materials = { material_amber_sap = 8, material_heartwood = 6 }
                local crafted, result = SaveSchema.withCraftedItem(profile, "recipe_amber_edge", 50)
                TestRunner.truthy(result.applied)
                local firstTrait = crafted.gearTraits.gear_amber_edge
                TestRunner.truthy(GearTraits.isValidFor("gear_amber_edge", firstTrait))
                local again = SaveSchema.withCraftedItem(crafted, "recipe_amber_edge", 60)
                TestRunner.equal(again.gearTraits.gear_amber_edge, firstTrait)
                -- passive traits shade the stats inside the clamps
                crafted.equipped = { weapon = "gear_amber_edge" }
                crafted.gearTraits = { gear_amber_edge = "trait_keen" }
                local stats = SaveSchema.equipmentStats(crafted)
                TestRunner.truthy(stats.damageReduction <= 0.25)
            end,
        },
    },
}
