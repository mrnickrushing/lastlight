--!strict

local SurvivalState = require("../../src/shared/SurvivalState")
local TestRunner = require("../TestRunner")

return {
    name = "SurvivalState",
    cases = {
        {
            name = "starts active at full health",
            run = function()
                local state = SurvivalState.create(10)
                local snapshot = SurvivalState.snapshot(state, 10)
                TestRunner.equal(snapshot.health, 100)
                TestRunner.equal(snapshot.downed, false)
                TestRunner.equal(SurvivalState.canAct(state), true)
            end,
        },
        {
            name = "applies bounded server damage without mutating prior state",
            run = function()
                local state = SurvivalState.create(0)
                local damaged, result = SurvivalState.damage(state, 24, 1)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(state.health, 100)
                TestRunner.equal(damaged.health, 76)
                TestRunner.equal(damaged.revision, 1)
            end,
        },
        {
            name = "enters a thirty second downed window at zero health",
            run = function()
                local state = SurvivalState.create(0)
                local downed, result = SurvivalState.damage(state, 100, 5)
                TestRunner.equal(result.downed, true)
                TestRunner.equal(downed.status, "downed")
                TestRunner.equal(downed.bleedoutAt, 35)
                TestRunner.equal(SurvivalState.snapshot(downed, 20).timeRemaining, 15)
                TestRunner.equal(SurvivalState.canAct(downed), false)
            end,
        },
        {
            name = "revives once before bleedout with short invulnerability",
            run = function()
                local state = SurvivalState.create(0)
                state = SurvivalState.damage(state, 100, 1)
                local revived, result = SurvivalState.revive(state, 10)
                local blocked, blockedResult = SurvivalState.damage(revived, 10, 11)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(revived.health, 35)
                TestRunner.equal(revived.status, "active")
                TestRunner.equal(blockedResult.reason, "invulnerable")
                TestRunner.equal(blocked, revived)
            end,
        },
        {
            name = "applies bounded server revive tuning",
            run = function()
                local state = SurvivalState.create(0)
                state = SurvivalState.damage(state, 100, 1)
                local revived, result = SurvivalState.revive(state, 2, {
                    health = 55,
                    wardSeconds = 4.5,
                })
                TestRunner.equal(result.health, 55)
                TestRunner.equal(revived.health, 55)
                local protected, damageResult = SurvivalState.damage(revived, 10, 6.4)
                TestRunner.equal(damageResult.applied, false)
                TestRunner.equal(protected.health, 55)
            end,
        },
        {
            name = "rejects late revive and safely recovers after bleedout",
            run = function()
                local state = SurvivalState.create(0)
                state = SurvivalState.damage(state, 100, 1)
                local unchanged, reviveResult = SurvivalState.revive(state, 31)
                local recovered, recoveryResult = SurvivalState.recover(state, 31)
                TestRunner.equal(reviveResult.reason, "bleedout_expired")
                TestRunner.equal(unchanged, state)
                TestRunner.equal(recoveryResult.applied, true)
                TestRunner.equal(recovered.health, 50)
                TestRunner.equal(recovered.status, "active")
            end,
        },
        {
            name = "rejects forged damage and repeated downed damage",
            run = function()
                local state = SurvivalState.create(0)
                local unchanged, invalid = SurvivalState.damage(state, -500, 1)
                TestRunner.equal(invalid.reason, "invalid_damage")
                TestRunner.equal(unchanged, state)

                local downed = SurvivalState.damage(state, 100, 1)
                local stillDowned, duplicate = SurvivalState.damage(downed, 20, 2)
                TestRunner.equal(duplicate.reason, "player_downed")
                TestRunner.equal(stillDowned, downed)
            end,
        },
        {
            name = "turns a character reset into a safe retreat",
            run = function()
                local state = SurvivalState.create(0)
                state = SurvivalState.damage(state, 100, 1)
                local retreated, result = SurvivalState.safeRetreat(state, 4)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(retreated.health, 50)
                TestRunner.equal(retreated.status, "active")
                TestRunner.equal(SurvivalState.snapshot(retreated, 4).invulnerable, true)
            end,
        },
        {
            name = "prevents an active character reset from becoming a full heal",
            run = function()
                local state = SurvivalState.create(0)
                state = SurvivalState.damage(state, 40, 1)
                local respawned = SurvivalState.respawn(state, 4)
                TestRunner.equal(respawned.health, 50)
                TestRunner.equal(respawned.status, "active")
                TestRunner.equal(respawned.revision, state.revision + 1)
            end,
        },
        {
            name = "heals active players up to max health without reviving",
            run = function()
                local state = SurvivalState.create(0)
                state = SurvivalState.damage(state, 30, 1)
                local healed, result = SurvivalState.heal(state, 22)
                local capped, cappedResult = SurvivalState.heal(healed, 50)
                TestRunner.equal(result.healed, 22)
                TestRunner.equal(healed.health, 92)
                TestRunner.equal(cappedResult.healed, 8)
                TestRunner.equal(capped.health, 100)

                local downed = SurvivalState.damage(state, 100, 2)
                local unchanged, rejected = SurvivalState.heal(downed, 22)
                TestRunner.equal(rejected.reason, "player_downed")
                TestRunner.equal(unchanged, downed)
            end,
        },
    },
}
