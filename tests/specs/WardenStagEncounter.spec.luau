--!strict

local TestRunner = require("../TestRunner")
local WardenStagEncounter = require("../../src/shared/WardenStagEncounter")

local function active(): any
    local state = WardenStagEncounter.create("run_1", "manifest_1", true)
    state = WardenStagEncounter.unlock(state)
    return WardenStagEncounter.activate(state, 10)
end

local function exposeWithRoots(state: any, userId: number): any
    local nodeIds = {
        "root_node_north",
        "root_node_east",
        "root_node_south",
        "root_node_west",
    }
    local required = WardenStagEncounter.snapshot(state, userId).rootNodesRequired
    for index = 1, required do
        state = WardenStagEncounter.cleanseRoot(state, userId, nodeIds[index])
    end
    return state
end

local function finishPhase(state: any, userId: number): any
    state = exposeWithRoots(state, userId)
    while state.status == "vulnerable" do
        state = WardenStagEncounter.strike(state, userId, 40)
    end
    return state
end

return {
    name = "WardenStagEncounter",
    cases = {
        {
            name = "stays locked until Old Growth unlocks the seal",
            run = function()
                local state = WardenStagEncounter.create("run_1", "manifest_1", true)
                TestRunner.equal(state.status, "locked")
                local unchanged, rejected = WardenStagEncounter.activate(state, 10)
                TestRunner.equal(unchanged, state)
                TestRunner.equal(rejected.reason, "locked")
                state = WardenStagEncounter.unlock(state)
                TestRunner.equal(state.status, "dormant")
                state = WardenStagEncounter.activate(state, 10)
                TestRunner.equal(state.status, "cleansing")
            end,
        },
        {
            name = "exposes each phase through distinct living root nodes",
            run = function()
                local state = active()
                state = WardenStagEncounter.cleanseRoot(state, 10, "root_node_north")
                TestRunner.equal(state.status, "cleansing")
                local unchanged, duplicate =
                    WardenStagEncounter.cleanseRoot(state, 10, "root_node_north")
                TestRunner.equal(unchanged, state)
                TestRunner.equal(duplicate.reason, "already_cleansed")
                state = WardenStagEncounter.cleanseRoot(state, 10, "root_node_east")
                TestRunner.equal(state.status, "vulnerable")
                state = finishPhase(state, 10)
                TestRunner.equal(state.phase, 2)
                TestRunner.equal(state.status, "cleansing")
                TestRunner.equal(WardenStagEncounter.snapshot(state, 10).rootNodesRequired, 3)
            end,
        },
        {
            name = "clamps health at phase gates",
            run = function()
                local state = exposeWithRoots(active(), 10)
                for _ = 1, 4 do
                    state = WardenStagEncounter.strike(state, 10, 100)
                end
                TestRunner.equal(state.health, 320)
                TestRunner.equal(state.phase, 2)
                TestRunner.equal(state.status, "cleansing")
            end,
        },
        {
            name = "offers an explicit harmful antler shortcut",
            run = function()
                local state = active()
                local nextState, result = WardenStagEncounter.breakAntler(state, 10, "antler_left")
                TestRunner.truthy(result.accepted)
                TestRunner.equal(nextState.antlersBroken, 1)
                TestRunner.equal(nextState.status, "vulnerable")
                local unchanged, blocked =
                    WardenStagEncounter.breakAntler(nextState, 10, "antler_right")
                TestRunner.equal(unchanged, nextState)
                TestRunner.equal(blocked.reason, "vulnerable")
            end,
        },
        {
            name = "preserves the forest when every phase is cleansed",
            run = function()
                local state = active()
                state = finishPhase(state, 10)
                state = finishPhase(state, 10)
                state = finishPhase(state, 10)
                TestRunner.equal(state.status, "complete")
                TestRunner.equal(state.health, 0)
                TestRunner.equal(state.outcome, "preserved")
            end,
        },
        {
            name = "records a harmed outcome when both antlers break",
            run = function()
                local state = active()
                state = WardenStagEncounter.breakAntler(state, 10, "antler_left")
                while state.status == "vulnerable" do
                    state = WardenStagEncounter.strike(state, 10, 40)
                end
                state = WardenStagEncounter.breakAntler(state, 10, "antler_right")
                while state.status == "vulnerable" do
                    state = WardenStagEncounter.strike(state, 10, 40)
                end
                state = finishPhase(state, 10)
                TestRunner.equal(state.outcome, "harmed")
                TestRunner.equal(state.antlersBroken, 2)
            end,
        },
        {
            name = "adds late joiners without resetting shared progress",
            run = function()
                local state = active()
                state = WardenStagEncounter.cleanseRoot(state, 10, "root_node_north")
                local joined = WardenStagEncounter.join(state, 20)
                TestRunner.equal(joined.health, state.health)
                TestRunner.equal(joined.cleansedNodes.root_node_north, true)
                TestRunner.equal(WardenStagEncounter.snapshot(joined, 20).rewardEligible, true)
            end,
        },
        {
            name = "uses phase-readable attacks and bounded tuning",
            run = function()
                TestRunner.equal(WardenStagEncounter.attack(1, 1).shape, "lane")
                TestRunner.equal(WardenStagEncounter.attack(2, 2).shape, "circle")
                TestRunner.equal(
                    WardenStagEncounter.attack(3, 3).attackId,
                    "warden_stag_memory_stampede"
                )
                TestRunner.equal(WardenStagEncounter.Tuning.strikeDamage, 40)
                TestRunner.truthy(WardenStagEncounter.Tuning.markedAttackCooldownMultiplier > 1)
            end,
        },
        {
            name = "uses a stable participant reward and kill switch",
            run = function()
                local state = WardenStagEncounter.create("run_1", "manifest_1", true)
                TestRunner.equal(
                    WardenStagEncounter.rewardTransactionId(state, 42),
                    "boss_warden_stag:run_1:manifest_1:42"
                )
                TestRunner.equal(WardenStagEncounter.Reward.amount, 5)
                TestRunner.equal(WardenStagEncounter.Reward.materialId, "material_amber_sap")
                local disabled = WardenStagEncounter.create("run_1", "manifest_1", false)
                TestRunner.equal(disabled.status, "disabled")
                TestRunner.equal(WardenStagEncounter.snapshot(disabled, 42).enabled, false)
            end,
        },
    },
}
