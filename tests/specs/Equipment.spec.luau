--!strict

local Equipment = require("../../src/shared/Equipment")
local TestRunner = require("../TestRunner")

return {
    name = "Equipment",
    cases = {
        {
            name = "equips owned passive gear into its slot",
            run = function()
                local equipped, result = Equipment.equip(
                    { gear_ironroot_hood = 1 },
                    {},
                    "gear_ironroot_hood"
                )
                TestRunner.truthy(result.applied)
                TestRunner.equal(equipped.head, "gear_ironroot_hood")
                TestRunner.equal(Equipment.stats(equipped).damageReduction, 0.05)
            end,
        },
        {
            name = "rejects unowned gear without mutating loadout",
            run = function()
                local equipped, result = Equipment.equip({}, {}, "gear_bramble_boots")
                TestRunner.equal(result.applied, false)
                TestRunner.equal(equipped.feet, nil)
            end,
        },
    },
}
