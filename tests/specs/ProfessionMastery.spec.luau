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
        {
            name = "unlocks bounded ability bonuses every two levels",
            run = function()
                local tuning = ProfessionMastery.tuning({
                    profession_engineer = { xp = 700, level = 8 },
                }, "profession_engineer")
                TestRunner.equal(tuning.level, 8)
                TestRunner.equal(tuning.rankName, "LUMINARY")
                TestRunner.equal(tuning.effectAmountBonus, 8)
                TestRunner.equal(tuning.effectRadiusBonus, 6)
                TestRunner.truthy(math.abs(tuning.cooldownReduction - 1.6) < 0.0001)
            end,
        },
        {
            name = "keeps specializations locked until mastery level ten",
            run = function()
                local locked = ProfessionMastery.tuning({
                    profession_medic = { xp = 800, level = 9 },
                }, "profession_medic")
                local unlocked = ProfessionMastery.tuning({
                    profession_medic = { xp = 900, level = 10 },
                }, "profession_medic")
                TestRunner.equal(locked.specializationUnlocked, false)
                TestRunner.equal(unlocked.specializationUnlocked, true)
                TestRunner.equal(#unlocked.specializations, 3)
            end,
        },
        {
            name = "reports a one-time specialization unlock on reaching level ten",
            run = function()
                local _, result = ProfessionMastery.award({
                    profession_scout = { xp = 890, level = 9 },
                }, "profession_scout", 10)
                TestRunner.equal(result.level, 10)
                TestRunner.equal(result.rankName, "MASTER")
                TestRunner.equal(result.specializationUnlocked, true)
            end,
        },
        {
            name = "clamps XP without creating ranks above the vertical-slice cap",
            run = function()
                local state, result = ProfessionMastery.award({}, "profession_warden", 99999)
                TestRunner.equal(state.profession_warden.xp, ProfessionMastery.MaxXp)
                TestRunner.equal(result.level, ProfessionMastery.MaxLevel)
            end,
        },
        {
            name = "snapshot includes progression and all profession paths",
            run = function()
                local snapshot = ProfessionMastery.snapshot({})
                TestRunner.equal(snapshot.profession_scout.rankName, "INITIATE")
                TestRunner.equal(snapshot.profession_scout.nextLevelXp, 100)
                TestRunner.equal(#snapshot.profession_scout.specializations, 3)
                TestRunner.equal(#snapshot.profession_warden.specializations, 3)
                TestRunner.equal(#snapshot.profession_engineer.specializations, 3)
                TestRunner.equal(#snapshot.profession_medic.specializations, 3)
            end,
        },
    },
}
