--!strict

local OldGrowthEncounter = require("../../src/shared/OldGrowthEncounter")
local TestRunner = require("../TestRunner")

local function activated(): any
    local state = OldGrowthEncounter.create("run_1", "manifest_1", true)
    return OldGrowthEncounter.activate(state, 10)
end

return {
    name = "OldGrowthEncounter",
    cases = {
        {
            name = "starts dormant and activates once",
            run = function()
                local initial = OldGrowthEncounter.create("run_1", "manifest_1", true)
                TestRunner.equal(initial.status, "dormant")
                local active, result = OldGrowthEncounter.activate(initial, 10)
                TestRunner.truthy(result.accepted)
                TestRunner.equal(active.status, "vulnerable")
                TestRunner.equal(initial.status, "dormant")
                local unchanged, duplicate = OldGrowthEncounter.activate(active, 10)
                TestRunner.equal(unchanged, active)
                TestRunner.equal(duplicate.accepted, false)
            end,
        },
        {
            name = "gates two health thresholds behind carried fire",
            run = function()
                local state = activated()
                for _ = 1, 4 do
                    state = OldGrowthEncounter.strike(state, 10, 34)
                end
                TestRunner.equal(state.health, 240)
                TestRunner.equal(state.status, "shielded")
                local blocked, result = OldGrowthEncounter.strike(state, 10, 34)
                TestRunner.equal(blocked, state)
                TestRunner.equal(result.reason, "shielded")

                state = OldGrowthEncounter.takeFire(state, 10, 100)
                local carried = OldGrowthEncounter.snapshot(state, 10, 101)
                TestRunner.truthy(carried.carryingFire)
                state = OldGrowthEncounter.burnHeart(state, 10, 101)
                TestRunner.equal(state.status, "vulnerable")
                for _ = 1, 4 do
                    state = OldGrowthEncounter.strike(state, 10, 34)
                end
                TestRunner.equal(state.health, 120)
                TestRunner.equal(state.shieldIndex, 2)
            end,
        },
        {
            name = "expires carried fire and rejects a late heart burn",
            run = function()
                local state = activated()
                for _ = 1, 4 do
                    state = OldGrowthEncounter.strike(state, 10, 34)
                end
                state = OldGrowthEncounter.takeFire(state, 10, 100)
                local expired = OldGrowthEncounter.expire(state, 115)
                TestRunner.equal(OldGrowthEncounter.snapshot(expired, 10, 115).carryingFire, false)
                local unchanged, result = OldGrowthEncounter.burnHeart(expired, 10, 115)
                TestRunner.equal(unchanged, expired)
                TestRunner.equal(result.reason, "fire_required")
            end,
        },
        {
            name = "allows only one active fire carrier",
            run = function()
                local state = activated()
                for _ = 1, 4 do
                    state = OldGrowthEncounter.strike(state, 10, 34)
                end
                state = OldGrowthEncounter.takeFire(state, 10, 100)
                local unchanged, claimed = OldGrowthEncounter.takeFire(state, 20, 101)
                TestRunner.equal(unchanged, state)
                TestRunner.equal(claimed.reason, "fire_claimed")
            end,
        },
        {
            name = "completes after the final exposed phase",
            run = function()
                local state = activated()
                for _ = 1, 4 do
                    state = OldGrowthEncounter.strike(state, 10, 34)
                end
                state = OldGrowthEncounter.takeFire(state, 10, 10)
                state = OldGrowthEncounter.burnHeart(state, 10, 11)
                for _ = 1, 4 do
                    state = OldGrowthEncounter.strike(state, 10, 34)
                end
                state = OldGrowthEncounter.takeFire(state, 10, 20)
                state = OldGrowthEncounter.burnHeart(state, 10, 21)
                for _ = 1, 4 do
                    state = OldGrowthEncounter.strike(state, 10, 34)
                end
                TestRunner.equal(state.status, "complete")
                TestRunner.equal(state.health, 0)
            end,
        },
        {
            name = "alternates readable attack shapes after the first shield",
            run = function()
                TestRunner.equal(OldGrowthEncounter.attack(1, 0).shape, "lane")
                TestRunner.equal(OldGrowthEncounter.attack(2, 1).shape, "circle")
                TestRunner.equal(OldGrowthEncounter.attack(3, 2).shape, "lane")
            end,
        },
        {
            name = "uses a stable per-player reward transaction",
            run = function()
                local state = OldGrowthEncounter.create("run_1", "manifest_1", true)
                TestRunner.equal(
                    OldGrowthEncounter.rewardTransactionId(state, 42),
                    "elite_old_growth:run_1:manifest_1:42"
                )
                TestRunner.equal(OldGrowthEncounter.Reward.materialId, "material_amber_sap")
                TestRunner.equal(OldGrowthEncounter.Reward.amount, 3)
                TestRunner.equal(OldGrowthEncounter.snapshot(state, 42, 0).rewardEligible, false)
                state = OldGrowthEncounter.activate(state, 42)
                TestRunner.equal(OldGrowthEncounter.snapshot(state, 42, 0).rewardEligible, true)
                TestRunner.equal(OldGrowthEncounter.snapshot(state, 43, 0).rewardEligible, false)
            end,
        },
        {
            name = "centralizes bounded encounter tuning",
            run = function()
                TestRunner.equal(OldGrowthEncounter.Tuning.strikeDamage, 34)
                TestRunner.equal(OldGrowthEncounter.Tuning.markedStrikeDamage, 40)
                TestRunner.equal(OldGrowthEncounter.Tuning.attackCooldownSeconds, 3)
                TestRunner.equal(OldGrowthEncounter.Tuning.shieldedAttackCooldownSeconds, 4.2)
                TestRunner.truthy(OldGrowthEncounter.Tuning.markedAttackCooldownMultiplier > 1)
            end,
        },
        {
            name = "supports a kill-switched dormant encounter",
            run = function()
                local state = OldGrowthEncounter.create("run_1", "manifest_1", false)
                TestRunner.equal(state.status, "disabled")
                TestRunner.equal(OldGrowthEncounter.snapshot(state, 10, 0).enabled, false)
            end,
        },
    },
}
