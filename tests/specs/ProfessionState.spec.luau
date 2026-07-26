--!strict

local ProfessionCatalog = require("../../src/shared/ProfessionCatalog")
local ProfessionState = require("../../src/shared/ProfessionState")
local TestRunner = require("../TestRunner")

return {
    name = "ProfessionState",
    cases = {
        {
            name = "starts without a forced profession",
            run = function()
                local state = ProfessionState.create(nil, 10)
                local snapshot = ProfessionState.snapshot(state, 10)
                TestRunner.equal(snapshot.selectedId, nil)
                TestRunner.equal(snapshot.ready, false)
            end,
        },
        {
            name = "rejects unknown and unsafe switches",
            run = function()
                local state = ProfessionState.create(nil, 10)
                local unknown, unknownResult =
                    ProfessionState.select(state, "profession_hacker", 11, true)
                local unsafe, unsafeResult =
                    ProfessionState.select(state, ProfessionCatalog.Ids.Scout, 11, false)
                TestRunner.equal(unknown, state)
                TestRunner.equal(unknownResult.reason, "unknown_profession")
                TestRunner.equal(unsafe, state)
                TestRunner.equal(unsafeResult.reason, "switch_unavailable")
            end,
        },
        {
            name = "selects each catalog profession without mutating prior state",
            run = function()
                local state = ProfessionState.create(nil, 10)
                for _, definition in ProfessionCatalog.list() do
                    local selected, result = ProfessionState.select(state, definition.id, 12, true)
                    TestRunner.equal(result.accepted, true)
                    TestRunner.equal(selected.selectedId, definition.id)
                    TestRunner.equal(state.selectedId, nil)
                end
            end,
        },
        {
            name = "starts a server cooldown from the selected ability",
            run = function()
                local state = ProfessionState.create(ProfessionCatalog.Ids.Scout, 10)
                local decision = ProfessionState.canUse(state, 10, true)
                local used, result = ProfessionState.commitAbility(state, 10)
                TestRunner.equal(decision.accepted, true)
                TestRunner.equal(result.abilityId, "ability_foxfire_mark")
                TestRunner.equal(used.cooldownReadyAt, 26)
                TestRunner.equal(used.activeUntil, 18)
                TestRunner.equal(state.cooldownReadyAt, 10)
            end,
        },
        {
            name = "rejects ability use while cooling down or unable to act",
            run = function()
                local state = ProfessionState.create(ProfessionCatalog.Ids.Medic, 10)
                state = ProfessionState.commitAbility(state, 10)
                local cooling = ProfessionState.canUse(state, 20, true)
                local downed = ProfessionState.canUse(state, 40, false)
                TestRunner.equal(cooling.reason, "cooldown")
                TestRunner.equal(cooling.remaining, 14)
                TestRunner.equal(downed.reason, "player_cannot_act")
            end,
        },
        {
            name = "rejects ability use before a profession is selected",
            run = function()
                local state = ProfessionState.create(nil, 10)
                local decision = ProfessionState.canUse(state, 10, true)
                TestRunner.equal(decision.reason, "profession_required")
            end,
        },
        {
            name = "warden guard only mitigates during its active window",
            run = function()
                local state = ProfessionState.create(ProfessionCatalog.Ids.Warden, 10)
                state = ProfessionState.commitAbility(state, 10)
                TestRunner.equal(ProfessionState.mitigatesDamage(state, 15.9), true)
                TestRunner.equal(ProfessionState.mitigatesDamage(state, 16), false)
            end,
        },
        {
            name = "same-profession selection preserves the active state",
            run = function()
                local state = ProfessionState.create(ProfessionCatalog.Ids.Engineer, 10)
                state = ProfessionState.commitAbility(state, 10)
                local repeated, result =
                    ProfessionState.select(state, ProfessionCatalog.Ids.Engineer, 11, true)
                TestRunner.equal(repeated, state)
                TestRunner.equal(result.changed, false)
                TestRunner.equal(repeated.cooldownReadyAt, 28)
            end,
        },
        {
            name = "switching professions cannot reset an active cooldown",
            run = function()
                local state = ProfessionState.create(ProfessionCatalog.Ids.Medic, 10)
                state = ProfessionState.commitAbility(state, 10)
                local switched =
                    ProfessionState.select(state, ProfessionCatalog.Ids.Scout, 12, true)
                TestRunner.equal(switched.selectedId, ProfessionCatalog.Ids.Scout)
                TestRunner.equal(switched.cooldownReadyAt, 34)
                TestRunner.equal(switched.activeUntil, 12)
            end,
        },
    },
}
