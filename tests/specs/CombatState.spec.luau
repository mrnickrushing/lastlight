--!strict

local CombatState = require("../../src/shared/CombatState")
local TestRunner = require("../TestRunner")

return {
    name = "CombatState",
    cases = {
        {
            name = "starts ready with full stamina",
            run = function()
                local state = CombatState.create(10)
                local snapshot = CombatState.snapshot(state, 10)
                TestRunner.equal(snapshot.stamina, 100)
                TestRunner.equal(snapshot.sprinting, false)
                TestRunner.equal(snapshot.dodgeActive, false)
                TestRunner.equal(snapshot.lowStamina, false)
            end,
        },
        {
            name = "drains sprint using server time without mutating prior state",
            run = function()
                local state = CombatState.create(0)
                local sprinting, result = CombatState.setSprint(state, true, 0, true)
                local drained = CombatState.advance(sprinting, 2, true)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(state.sprinting, false)
                TestRunner.equal(sprinting.sprinting, true)
                TestRunner.equal(CombatState.snapshot(drained, 2).stamina, 86)
            end,
        },
        {
            name = "stops sprint at empty stamina",
            run = function()
                local state = CombatState.create(0)
                state = CombatState.setSprint(state, true, 0, true)
                state = CombatState.advance(state, 16, true)
                local snapshot = CombatState.snapshot(state, 16)
                TestRunner.equal(snapshot.stamina, 0)
                TestRunner.equal(snapshot.sprinting, false)
            end,
        },
        {
            name = "regenerates only after the spending delay",
            run = function()
                local state = CombatState.create(0)
                state = CombatState.setSprint(state, true, 0, true)
                state = CombatState.advance(state, 1, true)
                state = CombatState.setSprint(state, false, 1, true)
                local waiting = CombatState.advance(state, 1.5, true)
                local recovered = CombatState.advance(waiting, 2.5, true)
                TestRunner.equal(CombatState.snapshot(waiting, 1.5).stamina, 93)
                TestRunner.equal(CombatState.snapshot(recovered, 2.5).stamina, 100)
            end,
        },
        {
            name = "applies a bounded equipment stamina regeneration multiplier",
            run = function()
                local state = CombatState.create(0)
                state.stamina = 40
                local normal = CombatState.advance(state, 1, true, 1)
                local equipped = CombatState.advance(state, 1, true, 1.1)
                local clamped = CombatState.advance(state, 1, true, 99)
                TestRunner.equal(CombatState.snapshot(normal, 1).stamina, 56)
                TestRunner.equal(CombatState.snapshot(equipped, 1).stamina, 57)
                TestRunner.equal(CombatState.snapshot(clamped, 1).stamina, 64)
            end,
        },
        {
            name = "spends stamina and grants a bounded dodge window",
            run = function()
                local state = CombatState.create(0)
                local dodging, result = CombatState.dodge(state, 1, true)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(CombatState.snapshot(dodging, 1).stamina, 65)
                TestRunner.equal(CombatState.avoidsDamage(dodging, 1.2), true)
                TestRunner.equal(CombatState.avoidsDamage(dodging, 1.42), false)
            end,
        },
        {
            name = "rejects repeated dodge during cooldown",
            run = function()
                local state = CombatState.create(0)
                state = CombatState.dodge(state, 0, true)
                local unchanged, result = CombatState.dodge(state, 0.5, true)
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.reason, "dodge_cooldown")
                TestRunner.equal(CombatState.snapshot(unchanged, 0.5).stamina, 65)
            end,
        },
        {
            name = "rejects sprint and dodge when the player cannot act",
            run = function()
                local state = CombatState.create(0)
                local sprinting, sprintResult = CombatState.setSprint(state, true, 1, false)
                local dodging, dodgeResult = CombatState.dodge(state, 1, false)
                TestRunner.equal(sprintResult.reason, "player_cannot_act")
                TestRunner.equal(dodgeResult.reason, "player_cannot_act")
                TestRunner.equal(sprinting.sprinting, false)
                TestRunner.equal(CombatState.snapshot(dodging, 1).stamina, 100)
            end,
        },
        {
            name = "rejects dodge below its stamina cost",
            run = function()
                local state = CombatState.create(0)
                state = CombatState.setSprint(state, true, 0, true)
                state = CombatState.advance(state, 10, true)
                state = CombatState.setSprint(state, false, 10, true)
                local unchanged, result = CombatState.dodge(state, 10, true)
                TestRunner.equal(result.reason, "insufficient_stamina")
                TestRunner.equal(CombatState.snapshot(unchanged, 10).lowStamina, true)
            end,
        },
        {
            name = "restoreStamina adds a flat amount clamped to the max",
            run = function()
                local state = CombatState.create(0)
                state = CombatState.dodge(state, 0, true)
                local restored, result = CombatState.restoreStamina(state, 1, 50, true)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(CombatState.snapshot(restored, 1).stamina, 100)

                local overflowed, overflowResult = CombatState.restoreStamina(restored, 1, 10, true)
                TestRunner.equal(overflowResult.applied, false)
                TestRunner.equal(overflowResult.reason, "stamina_full")
                TestRunner.equal(CombatState.snapshot(overflowed, 1).stamina, 100)
            end,
        },
        {
            name = "restoreStamina rejects a player who cannot act without mutating stamina",
            run = function()
                local state = CombatState.create(0)
                state = CombatState.dodge(state, 0, true)
                local unchanged, result = CombatState.restoreStamina(state, 1, 50, false)
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.reason, "player_cannot_act")
                TestRunner.equal(CombatState.snapshot(unchanged, 1).stamina, 65)
            end,
        },
    },
}
