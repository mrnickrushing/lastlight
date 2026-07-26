--!strict

local EnemyAttackFlow = require("../../src/shared/EnemyAttackFlow")
local TestRunner = require("../TestRunner")

local READY = {
    clearPath = true,
    inImpactArea = true,
    targetCanAct = true,
    targetPresent = true,
}

return {
    name = "EnemyAttackFlow",
    cases = {
        {
            name = "creates a bounded telegraph channel",
            run = function()
                local channel = EnemyAttackFlow.create(42, 10, 0.9)
                TestRunner.equal(channel.targetUserId, 42)
                TestRunner.equal(channel.startedAt, 10)
                TestRunner.equal(channel.endsAt, 10.9)
            end,
        },
        {
            name = "remains pending throughout the readable windup",
            run = function()
                local channel = EnemyAttackFlow.create(42, 10, 0.9)
                local decision = EnemyAttackFlow.evaluate(channel, 10.4, READY)
                TestRunner.equal(decision.status, "pending")
                TestRunner.truthy((decision.remaining or 0) > 0)
            end,
        },
        {
            name = "resolves only after the windup with a valid target",
            run = function()
                local channel = EnemyAttackFlow.create(42, 10, 0.9)
                local decision = EnemyAttackFlow.evaluate(channel, 10.9, READY)
                TestRunner.equal(decision.status, "resolve")
            end,
        },
        {
            name = "records an area evade instead of applying an instant hit",
            run = function()
                local channel = EnemyAttackFlow.create(42, 10, 0.9)
                local conditions = table.clone(READY)
                conditions.inImpactArea = false
                local decision = EnemyAttackFlow.evaluate(channel, 10.9, conditions)
                TestRunner.equal(decision.status, "miss")
                TestRunner.equal(decision.reason, "target_evaded_area")
            end,
        },
        {
            name = "cancels when the target leaves or becomes downed",
            run = function()
                local channel = EnemyAttackFlow.create(42, 10, 0.9)
                local missing = table.clone(READY)
                missing.targetPresent = false
                local left = EnemyAttackFlow.evaluate(channel, 10.2, missing)
                TestRunner.equal(left.status, "cancel")
                TestRunner.equal(left.reason, "target_left")

                local downed = table.clone(READY)
                downed.targetCanAct = false
                local unavailable = EnemyAttackFlow.evaluate(channel, 10.2, downed)
                TestRunner.equal(unavailable.status, "cancel")
                TestRunner.equal(unavailable.reason, "target_cannot_act")
            end,
        },
    },
}
