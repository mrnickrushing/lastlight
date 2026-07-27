--!strict

local ProfessionMastery = require("../../src/shared/ProfessionMastery")
local TestRunner = require("../TestRunner")

return {
    name = "ProfessionMastery",
    cases = {
        {
            name = "awards XP and levels the selected profession",
            run = function()
                local state, first = ProfessionMastery.award({}, "profession_scout", 100)
                TestRunner.truthy(first.applied)
                TestRunner.equal(state.profession_scout.level, 2)
                TestRunner.equal(state.profession_scout.xp, 100)
            end,
        },
        {
            name = "normalizes unknown and unsafe entries",
            run = function()
                local state = ProfessionMastery.normalize({
                    unknown = { xp = 999 },
                    profession_scout = { xp = -3 },
                })
                TestRunner.equal(state.unknown, nil)
                TestRunner.equal(state.profession_scout.xp, 0)
            end,
        },
    },
}
