--!strict

local GearWear = require("../../src/shared/GearWear")
local TestRunner = require("../TestRunner")

return {
    name = "GearWear",
    cases = {
        {
            name = "wear accrues to the cap and names its thirds",
            run = function()
                local wear = GearWear.default()
                TestRunner.equal(GearWear.condition(wear, "gear_amber_edge"), "sound")
                local result
                wear, result = GearWear.accrue(wear, "gear_amber_edge", 59)
                TestRunner.truthy(result.applied)
                TestRunner.equal(GearWear.condition(wear, "gear_amber_edge"), "sound")
                wear = GearWear.accrue(wear, "gear_amber_edge", 1)
                TestRunner.equal(GearWear.condition(wear, "gear_amber_edge"), "worn")
                TestRunner.equal(GearWear.effectiveness(wear, "gear_amber_edge"), 0.5)
                wear = GearWear.accrue(wear, "gear_amber_edge", 500)
                TestRunner.equal(GearWear.condition(wear, "gear_amber_edge"), "failing")
                TestRunner.equal(GearWear.effectiveness(wear, "gear_amber_edge"), 0)
            end,
        },
        {
            name = "repair costs half the recipe and refuses what it must",
            run = function()
                local cost = GearWear.repairCost("gear_amber_edge")
                TestRunner.equal(cost.material_amber_sap, 2)
                TestRunner.equal(cost.material_heartwood, 2)
                local wear = GearWear.accrue(GearWear.default(), "gear_amber_edge", 70)
                -- unaffordable
                local w1, m1, r1 =
                    GearWear.repair(wear, { material_amber_sap = 1 }, "gear_amber_edge")
                TestRunner.equal(r1.applied, false)
                TestRunner.equal(w1["gear_amber_edge"], 70)
                TestRunner.equal(m1.material_amber_sap, 1)
                -- affordable
                local materials = { material_amber_sap = 3, material_heartwood = 2 }
                local w2, m2, r2 = GearWear.repair(wear, materials, "gear_amber_edge")
                TestRunner.truthy(r2.applied)
                TestRunner.equal(w2["gear_amber_edge"], nil)
                TestRunner.equal(m2.material_amber_sap, 1)
                TestRunner.equal(m2.material_heartwood, 0)
                -- sound gear refuses
                local _, _, r3 = GearWear.repair(GearWear.default(), materials, "gear_amber_edge")
                TestRunner.equal(r3.applied, false)
                -- unknown items refuse
                local _, _, r4 = GearWear.repair(wear, materials, "laser")
                TestRunner.equal(r4.applied, false)
            end,
        },
        {
            name = "normalize strips junk and clamps survivors",
            run = function()
                local wear = GearWear.normalize({
                    gear_amber_edge = 250,
                    laser = 50,
                    gear_thornwood_bow = -3,
                })
                TestRunner.equal(wear.gear_amber_edge, 100)
                TestRunner.equal(wear.laser, nil)
                TestRunner.equal(wear.gear_thornwood_bow, nil)
            end,
        },
        {
            name = "worn passive gear protects less and failing gear not at all",
            run = function()
                local SaveSchema = require("../../src/shared/SaveSchema")
                local profile = SaveSchema.default(1234)
                profile.equipped = { head = "gear_ironroot_hood" }
                profile.gearWear = {}
                local sound = SaveSchema.equipmentStats(profile).damageReduction
                profile.gearWear = { gear_ironroot_hood = 60 }
                local worn = SaveSchema.equipmentStats(profile).damageReduction
                profile.gearWear = { gear_ironroot_hood = 100 }
                local failing = SaveSchema.equipmentStats(profile).damageReduction
                TestRunner.truthy(sound > worn)
                TestRunner.truthy(math.abs(worn - sound * 0.5) < 0.0001)
                TestRunner.equal(failing, 0)
            end,
        },
        {
            name = "the effectiveness seam is bit-identical when nothing is worn",
            run = function()
                local Equipment = require("../../src/shared/Equipment")
                local equipped = { head = "gear_ironroot_hood", feet = "gear_bramble_boots" }
                local plain = Equipment.stats(equipped)
                local seamed = Equipment.stats(equipped, {})
                TestRunner.equal(plain.damageReduction, seamed.damageReduction)
                TestRunner.equal(plain.staminaRegenMultiplier, seamed.staminaRegenMultiplier)
            end,
        },
    },
}
