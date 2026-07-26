--!strict

local ReviveFlow = require("../../src/shared/ReviveFlow")
local TestRunner = require("../TestRunner")

local function validConditions()
    return {
        reachable = true,
        reviverCanAct = true,
        reviverPresent = true,
        reviverRevision = 4,
        targetDowned = true,
        targetPresent = true,
    }
end

return {
    name = "ReviveFlow",
    cases = {
        {
            name = "creates an immutable timed server channel",
            run = function()
                local channel = ReviveFlow.create(10, 20, 4, 100, 2.5)
                TestRunner.equal(channel.startedAt, 100)
                TestRunner.equal(channel.endsAt, 102.5)
                TestRunner.equal(channel.reviverRevision, 4)
                TestRunner.throws(function()
                    channel.endsAt = 0
                end)
            end,
        },
        {
            name = "remains pending until the exact completion time",
            run = function()
                local channel = ReviveFlow.create(10, 20, 4, 100, 2.5)
                local pending = ReviveFlow.evaluate(channel, 102.49, validConditions())
                local complete = ReviveFlow.evaluate(channel, 102.5, validConditions())
                TestRunner.equal(pending.status, "pending")
                TestRunner.equal(complete.status, "complete")
                TestRunner.equal(complete.elapsed, 2.5)
            end,
        },
        {
            name = "cancels when distance or line of sight changes",
            run = function()
                local channel = ReviveFlow.create(10, 20, 4, 100, 2.5)
                local conditions = validConditions()
                conditions.reachable = false
                local decision = ReviveFlow.evaluate(channel, 101, conditions)
                TestRunner.equal(decision.status, "cancel")
                TestRunner.equal(decision.reason, "revive_out_of_range")
            end,
        },
        {
            name = "cancels when the reviver is downed or damaged",
            run = function()
                local channel = ReviveFlow.create(10, 20, 4, 100, 2.5)
                local downedConditions = validConditions()
                downedConditions.reviverCanAct = false
                local downedDecision = ReviveFlow.evaluate(channel, 101, downedConditions)
                TestRunner.equal(downedDecision.reason, "reviver_cannot_act")

                local damagedConditions = validConditions()
                damagedConditions.reviverRevision = 5
                local damagedDecision = ReviveFlow.evaluate(channel, 101, damagedConditions)
                TestRunner.equal(damagedDecision.reason, "reviver_state_changed")
            end,
        },
        {
            name = "cancels safely when either player leaves",
            run = function()
                local channel = ReviveFlow.create(10, 20, 4, 100, 2.5)
                local targetLeft = validConditions()
                targetLeft.targetPresent = false
                TestRunner.equal(
                    ReviveFlow.evaluate(channel, 101, targetLeft).reason,
                    "target_left"
                )

                local reviverLeft = validConditions()
                reviverLeft.reviverPresent = false
                TestRunner.equal(
                    ReviveFlow.evaluate(channel, 101, reviverLeft).reason,
                    "reviver_left"
                )
            end,
        },
        {
            name = "rejects forged self-revive channel construction",
            run = function()
                TestRunner.throws(function()
                    ReviveFlow.create(10, 10, 0, 100, 2.5)
                end, "cannot revive themselves")
                TestRunner.throws(function()
                    ReviveFlow.create(10, 20, 0, 100, 0)
                end, "duration is invalid")
            end,
        },
    },
}
