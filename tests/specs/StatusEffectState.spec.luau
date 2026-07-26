--!strict

local StatusEffectState = require("../../src/shared/StatusEffectState")
local TestRunner = require("../TestRunner")

return {
    name = "StatusEffectState",
    cases = {
        {
            name = "applies and expires a bounded drowsy slow",
            run = function()
                local state = StatusEffectState.applyDrowsy(StatusEffectState.create(), 10, 3, 0.65)
                local active = StatusEffectState.snapshot(state, 11)
                TestRunner.truthy(active.drowsy)
                TestRunner.equal(active.drowsyUntil, 13)
                TestRunner.equal(active.movementMultiplier, 0.65)
                local expired = StatusEffectState.snapshot(state, 13)
                TestRunner.equal(expired.drowsy, false)
                TestRunner.equal(expired.movementMultiplier, 1)
            end,
        },
        {
            name = "keeps the longer effect and clamps unsafe speed multipliers",
            run = function()
                local first = StatusEffectState.applyDrowsy(StatusEffectState.create(), 5, 5, 0.65)
                local shorter = StatusEffectState.applyDrowsy(first, 6, 1, 0.1)
                TestRunner.equal(StatusEffectState.snapshot(shorter, 6).drowsyUntil, 10)
                local longer = StatusEffectState.applyDrowsy(first, 6, 8, 0.1)
                TestRunner.equal(StatusEffectState.snapshot(longer, 6).movementMultiplier, 0.25)
            end,
        },
        {
            name = "clears all temporary movement pressure",
            run = function()
                local active = StatusEffectState.applyDrowsy(StatusEffectState.create(), 1, 5, 0.65)
                TestRunner.equal(
                    StatusEffectState.snapshot(StatusEffectState.clear(active), 2).drowsy,
                    false
                )
            end,
        },
        {
            name = "applies a bounded root slow and resolves overlapping effects",
            run = function()
                local drowsy =
                    StatusEffectState.applyDrowsy(StatusEffectState.create(), 10, 4, 0.65)
                local rooted = StatusEffectState.applyRooted(drowsy, 10, 1.6, 0.35)
                local overlap = StatusEffectState.snapshot(rooted, 11)
                TestRunner.truthy(overlap.drowsy)
                TestRunner.truthy(overlap.rooted)
                TestRunner.equal(overlap.movementMultiplier, 0.35)
                local afterRoot = StatusEffectState.snapshot(rooted, 12)
                TestRunner.equal(afterRoot.rooted, false)
                TestRunner.equal(afterRoot.movementMultiplier, 0.65)
            end,
        },
    },
}
