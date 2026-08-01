--!strict

local TestRunner = require("../TestRunner")
local TownCondition = require("../../src/shared/TownCondition")

return {
    name = "TownCondition",
    cases = {
        {
            name = "a clean defense records the night without town damage",
            run = function()
                local state, result = TownCondition.afterNight(TownCondition.default(), 95, 1)
                TestRunner.equal(result.reason, "clean_defense")
                TestRunner.equal(state.integrity, 100)
                TestRunner.equal(state.lastNightNumber, 1)
            end,
        },
        {
            name = "lantern pressure leaves bounded persistent damage",
            run = function()
                local state, result = TownCondition.afterNight(TownCondition.default(), 55, 2)
                TestRunner.equal(result.damage, 35)
                TestRunner.equal(state.integrity, 65)
                TestRunner.equal(result.damageLevel, 2)
            end,
        },
        {
            name = "the same night cannot apply damage twice",
            run = function()
                local state = TownCondition.afterNight(TownCondition.default(), 20, 3)
                local repeated, result = TownCondition.afterNight(state, 20, 3)
                TestRunner.equal(repeated.integrity, state.integrity)
                TestRunner.equal(result.reason, "night_already_recorded")
            end,
        },
        {
            name = "day repairs restore integrity in bounded steps",
            run = function()
                local damaged = TownCondition.afterNight(TownCondition.default(), 20, 1)
                local repaired, result = TownCondition.repair(damaged)
                TestRunner.equal(result.restored, 20)
                TestRunner.equal(repaired.integrity, 65)
                TestRunner.equal(repaired.repairsCompleted, 1)
            end,
        },
        {
            name = "newer nights beat stale profiles and same-day repairs beat damage",
            run = function()
                local older = TownCondition.normalize({ integrity = 100, lastNightNumber = 2 })
                local newer = TownCondition.normalize({ integrity = 60, lastNightNumber = 3 })
                TestRunner.equal(TownCondition.merge(older, newer).integrity, 60)
                local repaired = TownCondition.normalize({ integrity = 80, lastNightNumber = 3 })
                TestRunner.equal(TownCondition.merge(newer, repaired).integrity, 80)
            end,
        },
        {
            name = "snapshot derives repair work and visible severity",
            run = function()
                local snapshot = TownCondition.snapshot({
                    integrity = 40,
                    lastNightNumber = 4,
                    lastDamage = 40,
                    repairsCompleted = 2,
                })
                TestRunner.equal(snapshot.damageLevel, 3)
                TestRunner.equal(snapshot.repairsRemaining, 3)
            end,
        },
        {
            name = "normalization rejects non-finite corrupt condition values",
            run = function()
                local normalized = TownCondition.normalize({
                    integrity = 0 / 0,
                    lastNightNumber = math.huge,
                    lastDamage = -math.huge,
                    repairsCompleted = 0 / 0,
                })
                TestRunner.equal(normalized.integrity, 100)
                TestRunner.equal(normalized.lastNightNumber, 0)
                TestRunner.equal(normalized.lastDamage, 0)
                TestRunner.equal(normalized.repairsCompleted, 0)
            end,
        },
    },
}
