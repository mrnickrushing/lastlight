--!strict

local BramblewakeBlackout = require("../../src/shared/BramblewakeBlackout")
local TestRunner = require("../TestRunner")

local function relayReady(): any
    local state = BramblewakeBlackout.create("run_1", "manifest_1", true, 540)
    state = BramblewakeBlackout.start(state, 10, 100)
    return state
end

local function completeRelay(state: any, userId: number): any
    for _, nodeId in
        {
            "blackout_root_farm",
            "blackout_root_mill",
            "blackout_root_cathedral",
        }
    do
        state = BramblewakeBlackout.takeFire(state, userId, 101)
        state = BramblewakeBlackout.deliverFire(state, userId, nodeId, 102)
    end
    return state
end

return {
    name = "BramblewakeBlackout",
    cases = {
        {
            name = "starts one bounded nine minute Blackout",
            run = function()
                local state = relayReady()
                local snapshot = BramblewakeBlackout.snapshot(state, 10, 130)
                TestRunner.equal(state.status, "relay")
                TestRunner.equal(snapshot.duration, 540)
                TestRunner.equal(snapshot.elapsed, 30)
                TestRunner.equal(snapshot.remaining, 510)
                local unchanged, repeated = BramblewakeBlackout.start(state, 10, 140)
                TestRunner.equal(unchanged, state)
                TestRunner.equal(repeated.reason, "relay")
            end,
        },
        {
            name = "requires carried fire at three distinct relay nodes",
            run = function()
                local state = relayReady()
                local unchanged, missing =
                    BramblewakeBlackout.deliverFire(state, 10, "blackout_root_farm", 101)
                TestRunner.equal(unchanged, state)
                TestRunner.equal(missing.reason, "fire_required")
                state = BramblewakeBlackout.takeFire(state, 10, 101)
                local expiredState, expired =
                    BramblewakeBlackout.deliverFire(state, 10, "blackout_root_farm", 121)
                TestRunner.equal(expiredState, state)
                TestRunner.equal(expired.reason, "fire_expired")
                state = BramblewakeBlackout.deliverFire(state, 10, "blackout_root_farm", 110)
                TestRunner.equal(BramblewakeBlackout.snapshot(state, 10, 110).deliveredNodes, 1)
                state = BramblewakeBlackout.takeFire(state, 10, 111)
                local duplicateState, duplicate =
                    BramblewakeBlackout.deliverFire(state, 10, "blackout_root_farm", 112)
                TestRunner.equal(duplicateState, state)
                TestRunner.equal(duplicate.reason, "already_delivered")
            end,
        },
        {
            name = "orders relay, Old Growth, Warden, and resolution",
            run = function()
                local state = completeRelay(relayReady(), 10)
                TestRunner.equal(state.status, "old_growth")
                state = BramblewakeBlackout.completeOldGrowth(state)
                TestRunner.equal(state.status, "warden")
                state = BramblewakeBlackout.completeWarden(state, "preserved")
                TestRunner.equal(state.status, "resolution")
                TestRunner.equal(state.wardenOutcome, "preserved")
            end,
        },
        {
            name = "uses a present-participant vote with shared as the safe tie",
            run = function()
                local state = completeRelay(relayReady(), 10)
                state = BramblewakeBlackout.completeOldGrowth(state)
                state = BramblewakeBlackout.join(state, 20)
                state = BramblewakeBlackout.completeWarden(state, "scarred")
                local first, waiting =
                    BramblewakeBlackout.vote(state, 10, "restore_farmland", { 10, 20 })
                TestRunner.equal(first.status, "resolution")
                TestRunner.equal(waiting.reason, "vote_recorded")
                local complete, resolved =
                    BramblewakeBlackout.vote(first, 20, "wild_regrowth", { 10, 20 })
                TestRunner.equal(complete.status, "complete")
                TestRunner.equal(complete.decision, "shared_agroforest")
                TestRunner.equal(resolved.reason, "resolved")
            end,
        },
        {
            name = "resolves immediately for a solo participant",
            run = function()
                local state = completeRelay(relayReady(), 10)
                state = BramblewakeBlackout.completeOldGrowth(state)
                state = BramblewakeBlackout.completeWarden(state, "harmed")
                state = BramblewakeBlackout.vote(state, 10, "wild_regrowth", { 10 })
                TestRunner.equal(state.status, "complete")
                TestRunner.equal(state.decision, "wild_regrowth")
            end,
        },
        {
            name = "reconciles votes when a non-voter leaves the expedition",
            run = function()
                local state = completeRelay(relayReady(), 10)
                state = BramblewakeBlackout.completeOldGrowth(state)
                state = BramblewakeBlackout.join(state, 20)
                state = BramblewakeBlackout.completeWarden(state, "preserved")
                state = BramblewakeBlackout.vote(state, 10, "restore_farmland", { 10, 20 })
                local complete, result = BramblewakeBlackout.reconcileVote(state, { 10 })
                TestRunner.equal(result.resolved, true)
                TestRunner.equal(complete.status, "complete")
                TestRunner.equal(complete.decision, "restore_farmland")
            end,
        },
        {
            name = "keeps overtime recoverable instead of erasing progress",
            run = function()
                local state = relayReady()
                state = BramblewakeBlackout.takeFire(state, 10, 110)
                state = BramblewakeBlackout.deliverFire(state, 10, "blackout_root_farm", 111)
                local snapshot = BramblewakeBlackout.snapshot(state, 10, 700)
                TestRunner.equal(snapshot.overtime, true)
                TestRunner.equal(snapshot.remaining, 0)
                TestRunner.equal(snapshot.deliveredNodes, 1)
                TestRunner.equal(state.status, "relay")
            end,
        },
        {
            name = "uses stable chapter transactions and a kill switch",
            run = function()
                local state = BramblewakeBlackout.create("run_1", "manifest_1", true, 540)
                TestRunner.equal(
                    BramblewakeBlackout.chapterTransactionId(state, 42),
                    "chapter_1:run_1:manifest_1:42"
                )
                local disabled = BramblewakeBlackout.create("run_1", "manifest_1", false, 540)
                TestRunner.equal(disabled.status, "disabled")
                TestRunner.equal(BramblewakeBlackout.snapshot(disabled, 42, 0).enabled, false)
            end,
        },
    },
}
