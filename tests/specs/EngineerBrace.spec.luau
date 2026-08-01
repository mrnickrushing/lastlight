--!strict

local EngineerBrace = require("../../src/shared/EngineerBrace")
local TestRunner = require("../TestRunner")

return {
    name = "EngineerBrace",
    cases = {
        {
            name = "deploys one bounded server-owned brace",
            run = function()
                local state, result = EngineerBrace.deploy(EngineerBrace.default(), 100, 12, 14, 42)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(state.activeUntil, 112)
                TestRunner.equal(state.capacity, 14)
                TestRunner.equal(state.ownerUserId, 42)
                TestRunner.equal(state.revision, 1)
            end,
        },
        {
            name = "replaces an old brace without stacking capacity",
            run = function()
                local first = EngineerBrace.deploy(EngineerBrace.default(), 10, 12, 14, 7)
                local second = EngineerBrace.deploy(first, 14, 12, 14, 8)
                TestRunner.equal(second.capacity, 14)
                TestRunner.equal(second.ownerUserId, 8)
                TestRunner.equal(second.revision, 2)
                TestRunner.equal(second.activeUntil, 26)
            end,
        },
        {
            name = "absorbs pressure once and preserves unblocked damage",
            run = function()
                local state = EngineerBrace.deploy(EngineerBrace.default(), 10, 12, 14, 7)
                local afterFirst, first = EngineerBrace.absorb(state, 9, 11)
                local afterSecond, second = EngineerBrace.absorb(afterFirst, 8, 12)
                TestRunner.equal(first.absorbed, 9)
                TestRunner.equal(first.remaining, 0)
                TestRunner.equal(afterFirst.capacity, 5)
                TestRunner.equal(second.absorbed, 5)
                TestRunner.equal(second.remaining, 3)
                TestRunner.equal(second.exhausted, true)
                TestRunner.equal(afterSecond.capacity, 0)
            end,
        },
        {
            name = "expires without blocking later pressure",
            run = function()
                local state = EngineerBrace.deploy(EngineerBrace.default(), 10, 5, 14, 7)
                local expired, result = EngineerBrace.absorb(state, 8, 15)
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.reason, "brace_expired")
                TestRunner.equal(result.remaining, 8)
                TestRunner.equal(expired.capacity, 0)
            end,
        },
        {
            name = "rejects malformed deployment and pressure",
            run = function()
                local state, deployment =
                    EngineerBrace.deploy(EngineerBrace.default(), 0, 0, math.huge, -1)
                local afterPressure, pressure = EngineerBrace.absorb(state, 0 / 0, 1)
                TestRunner.equal(deployment.reason, "invalid_deployment")
                TestRunner.equal(pressure.reason, "invalid_pressure")
                TestRunner.equal(afterPressure.capacity, state.capacity)
                TestRunner.equal(afterPressure.activeUntil, state.activeUntil)
                TestRunner.equal(afterPressure.revision, state.revision)
            end,
        },
        {
            name = "publishes only active remaining capacity",
            run = function()
                local state = EngineerBrace.deploy(EngineerBrace.default(), 20, 8, 14, 9)
                local active = EngineerBrace.snapshot(state, 21)
                local expired = EngineerBrace.snapshot(state, 28)
                TestRunner.equal(active.active, true)
                TestRunner.equal(active.capacity, 14)
                TestRunner.equal(active.remainingSeconds, 7)
                TestRunner.equal(expired.active, false)
                TestRunner.equal(expired.capacity, 0)
            end,
        },
    },
}
