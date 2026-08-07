--!strict

local RunHandoff = require("../../src/shared/RunHandoff")
local TestRunner = require("../TestRunner")

return {
    name = "RunHandoff",
    cases = {
        {
            name = "builds a payload describing the party that actually launched",
            run = function()
                local payload, result = RunHandoff.buildPayload(3, 500)
                TestRunner.equal(result.accepted, true)
                TestRunner.equal((payload :: any).kind, RunHandoff.runKind())
                TestRunner.equal((payload :: any).schemaVersion, RunHandoff.schemaVersion())
                TestRunner.equal((payload :: any).partySize, 3)
            end,
        },
        {
            name = "refuses to build a payload for an impossible party",
            run = function()
                for _, size in { 0, -1, 9, 2.5, "3" } do
                    local payload, result = RunHandoff.buildPayload(size, 500)
                    TestRunner.equal(payload, nil)
                    TestRunner.equal(result.reason, "invalid_party_size")
                end
            end,
        },
        {
            name = "accepts its own payload on arrival",
            run = function()
                local payload = RunHandoff.buildPayload(5, 500)
                local read = RunHandoff.readPayload(payload)
                TestRunner.equal(read.isRun, true)
                TestRunner.equal(read.partySize, 5)
            end,
        },
        {
            -- The party ID is what lets a run server recognise a returning
            -- member instead of teleporting them into the world they are
            -- already standing in.
            name = "carries the departing party's identity both ways",
            run = function()
                local payload, result = RunHandoff.buildPayload(3, 500, "party_77_400")
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(RunHandoff.readPayload(payload).partyId, "party_77_400")
            end,
        },
        {
            name = "a departure that formed no party is still a run",
            run = function()
                local payload, result = RunHandoff.buildPayload(1, 500)
                TestRunner.equal(result.accepted, true)
                local read = RunHandoff.readPayload(payload)
                TestRunner.equal(read.isRun, true)
                TestRunner.equal(read.partyId, nil)
            end,
        },
        {
            -- An unusable ID costs the convenience it buys, not the run.
            name = "an unreadable party id is dropped rather than refusing the run",
            run = function()
                local read = RunHandoff.readPayload({
                    schemaVersion = RunHandoff.schemaVersion(),
                    kind = RunHandoff.runKind(),
                    partySize = 2,
                    departedAt = 10,
                    partyId = string.rep("x", 200),
                })
                TestRunner.equal(read.isRun, true)
                TestRunner.equal(read.partyId, nil)
            end,
        },
        {
            name = "refuses to build a payload naming an impossible party",
            run = function()
                local payload, result = RunHandoff.buildPayload(2, 500, string.rep("x", 200))
                TestRunner.equal(payload, nil)
                TestRunner.equal(result.reason, "invalid_party_id")
            end,
        },
        {
            name = "treats anything unrecognised as a lobby rather than a run",
            run = function()
                -- The version is read from the module rather than written as a
                -- literal: it moved from 1 to 2 when the party ID landed, and
                -- these cases are about the shape of a refusal, not about
                -- which number is current.
                local version = RunHandoff.schemaVersion()
                local cases = {
                    { value = nil, reason = "no_payload" },
                    { value = "run", reason = "no_payload" },
                    { value = {}, reason = "schema_mismatch" },
                    {
                        value = { schemaVersion = 99, kind = "last_light_run", partySize = 2 },
                        reason = "schema_mismatch",
                    },
                    {
                        value = { schemaVersion = version, kind = "something_else", partySize = 2 },
                        reason = "unknown_kind",
                    },
                    {
                        value = {
                            schemaVersion = version,
                            kind = "last_light_run",
                            partySize = 99,
                            departedAt = 1,
                        },
                        reason = "invalid_party_size",
                    },
                    {
                        value = {
                            schemaVersion = version,
                            kind = "last_light_run",
                            partySize = 2,
                            departedAt = -1,
                        },
                        reason = "invalid_time",
                    },
                }
                for _, case in cases do
                    local read = RunHandoff.readPayload(case.value)
                    TestRunner.equal(read.isRun, false)
                    TestRunner.equal(read.reason, case.reason)
                end
            end,
        },
        {
            name = "a forged payload cannot claim anything but its own kind",
            run = function()
                -- Teleport data is reachable on some paths, so the shape is
                -- deliberately inert: it can say "this is a run" and nothing
                -- about rewards, stage, or progression.
                local read = RunHandoff.readPayload({
                    schemaVersion = RunHandoff.schemaVersion(),
                    kind = "last_light_run",
                    partySize = 2,
                    departedAt = 10,
                    grantReward = "everything",
                    stage = "complete",
                })
                TestRunner.equal(read.isRun, true)
                TestRunner.equal(read.partySize, 2)
                TestRunner.equal(read.grantReward, nil)
                TestRunner.equal(read.stage, nil)
            end,
        },
        {
            name = "every failure returns the party and cancels the departure",
            run = function()
                for _, reason in { "reserve_failed", "teleport_failed", "", 42 } do
                    local recovery = RunHandoff.failureRecovery(reason)
                    TestRunner.equal(recovery.returnToLobby, true)
                    TestRunner.equal(recovery.cancelDeparture, true)
                    TestRunner.truthy(#recovery.message > 0)
                end
                TestRunner.equal(RunHandoff.failureRecovery(42).reason, "unknown")
                TestRunner.equal(
                    RunHandoff.failureRecovery("reserve_failed").reason,
                    "reserve_failed"
                )
            end,
        },
    },
}
