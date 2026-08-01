--!strict

local ProfessionRescue = require("../../src/shared/ProfessionRescue")
local TestRunner = require("../TestRunner")

return {
    name = "ProfessionRescue",
    cases = {
        {
            name = "keeps unselected scout and engineer rescues baseline",
            run = function()
                local unselected = ProfessionRescue.resolve(nil, 10, 2.5, 35, 3)
                TestRunner.equal(unselected.duration, 2.5)
                TestRunner.equal(unselected.health, 35)
                TestRunner.equal(unselected.wardSeconds, 3)
                TestRunner.equal(unselected.specialized, false)
                for _, professionId in { "profession_scout", "profession_engineer" } do
                    local tuning = ProfessionRescue.resolve(professionId, 10, 2.5, 35, 3)
                    TestRunner.equal(tuning.duration, 2.5)
                    TestRunner.equal(tuning.health, 35)
                    TestRunner.equal(tuning.wardSeconds, 3)
                    TestRunner.equal(tuning.specialized, false)
                end
            end,
        },
        {
            name = "makes Medic rescues faster healthier and safer",
            run = function()
                local tuning = ProfessionRescue.resolve("profession_medic", 1, 2.5, 35, 3)
                TestRunner.truthy(tuning.duration < 2.5)
                TestRunner.truthy(tuning.health > 35)
                TestRunner.truthy(tuning.wardSeconds > 3)
                TestRunner.equal(tuning.rescueTitle, "MEDIC RESCUE")
            end,
        },
        {
            name = "lets Warden protect recovery without replacing the Medic",
            run = function()
                local warden = ProfessionRescue.resolve("profession_warden", 10, 2.5, 35, 3)
                local medic = ProfessionRescue.resolve("profession_medic", 10, 2.5, 35, 3)
                TestRunner.equal(warden.duration, 2.5)
                TestRunner.equal(warden.health, 35)
                TestRunner.truthy(warden.wardSeconds > 3)
                TestRunner.truthy(medic.wardSeconds > warden.wardSeconds)
            end,
        },
        {
            name = "bounds mastery-derived rescue values",
            run = function()
                local tuning = ProfessionRescue.resolve("profession_medic", math.huge, 2.5, 35, 3)
                TestRunner.truthy(tuning.duration >= 1.25)
                TestRunner.truthy(tuning.health <= 65)
                TestRunner.truthy(tuning.wardSeconds <= 6)
                TestRunner.equal(tuning.level, 1)
            end,
        },
    },
}
