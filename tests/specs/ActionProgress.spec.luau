--!strict

local ActionProgress = require("../../src/shared/ActionProgress")
local TestRunner = require("../TestRunner")

return {
    name = "ActionProgress",
    cases = {
        {
            name = "begins a timed gather with its own swing count and label",
            run = function()
                local state, result = ActionProgress.begin(nil, "gather", "heartwood_gather", 100)
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(result.label, "GATHERING")
                TestRunner.equal(result.swings, 2)
                TestRunner.equal((state :: any).endsAt, 101.4)
            end,
        },
        {
            name = "refuses an action that has no configured duration",
            run = function()
                for _, actionId in { "rescue", "prepare", "", 7 } do
                    local _, result = ActionProgress.begin(nil, actionId, "some_target", 100)
                    TestRunner.equal(result.accepted, false)
                    TestRunner.equal(result.reason, "untimed_action")
                end
            end,
        },
        {
            name = "refuses a second action while one is running",
            run = function()
                local state = ActionProgress.begin(nil, "gather", "heartwood_gather", 100)
                local next, result = ActionProgress.begin(state, "build", "barricade", 100.5)
                TestRunner.equal(result.accepted, false)
                TestRunner.equal(result.reason, "already_working")
                TestRunner.equal((next :: any).actionId, "gather")
            end,
        },
        {
            name = "rejects a malformed interaction id instead of trusting it",
            run = function()
                for _, target in { "", 12, string.rep("x", 65) } do
                    local _, result = ActionProgress.begin(nil, "gather", target, 100)
                    TestRunner.equal(result.accepted, false)
                    TestRunner.equal(result.reason, "invalid_interaction")
                end
            end,
        },
        {
            name = "does not complete before the clock says so",
            run = function()
                local state = ActionProgress.begin(nil, "gather", "heartwood_gather", 100)
                local next, result = ActionProgress.tick(state, 101.39)
                TestRunner.equal(result.complete, false)
                TestRunner.equal(result.reason, "working")
                TestRunner.equal((next :: any).actionId, "gather")
            end,
        },
        {
            name = "completes once and consumes the action",
            run = function()
                local state = ActionProgress.begin(nil, "build", "barricade", 100)
                local next, result = ActionProgress.tick(state, 101.8)
                TestRunner.equal(result.complete, true)
                TestRunner.equal(result.actionId, "build")
                TestRunner.equal(result.interactionId, "barricade")
                TestRunner.equal(next, nil)

                local again, repeated = ActionProgress.tick(next, 102)
                TestRunner.equal(repeated.complete, false)
                TestRunner.equal(repeated.reason, "idle")
                TestRunner.equal(again, nil)
            end,
        },
        {
            name = "cancelling grants nothing",
            run = function()
                local state = ActionProgress.begin(nil, "gather", "heartwood_gather", 100)
                local cancelled = ActionProgress.cancel(state)
                TestRunner.equal(cancelled, nil)
                local _, result = ActionProgress.tick(cancelled, 200)
                TestRunner.equal(result.complete, false)
            end,
        },
        {
            name = "reports progress for the bar and stops at full",
            run = function()
                local state = ActionProgress.begin(nil, "gather", "heartwood_gather", 100)
                TestRunner.equal(ActionProgress.snapshot(state, 100).alpha, 0)
                TestRunner.equal(ActionProgress.snapshot(state, 100.7).alpha, 0.5)
                TestRunner.equal(ActionProgress.snapshot(state, 101.4).active, false)
                TestRunner.equal(ActionProgress.snapshot(state, 999).alpha, 1)
                TestRunner.equal(ActionProgress.snapshot(nil, 100).active, false)
            end,
        },
    },
}
