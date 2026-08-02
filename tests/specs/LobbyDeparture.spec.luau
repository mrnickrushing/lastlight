--!strict

local LobbyDeparture = require("../../src/shared/LobbyDeparture")
local TestRunner = require("../TestRunner")

local MAX = 8

return {
    name = "LobbyDeparture",
    cases = {
        {
            name = "starts a bounded ten second countdown for a valid party size",
            run = function()
                local state, result =
                    LobbyDeparture.requestDeparture(LobbyDeparture.create(), 4, 100, 2, MAX)
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(result.partySize, 4)
                TestRunner.equal(result.secondsRemaining, 10)
                TestRunner.equal(state.countdownEndsAt, 110)
            end,
        },
        {
            name = "rejects a party size outside one through the server capacity",
            run = function()
                for _, size in { 0, -3, 9, 2.5, "4", nil } do
                    local _, result =
                        LobbyDeparture.requestDeparture(LobbyDeparture.create(), size, 100, 2, MAX)
                    TestRunner.equal(result.accepted, false)
                    TestRunner.equal(result.reason, "invalid_party_size")
                end
            end,
        },
        {
            name = "never starts a departure from an empty platform",
            run = function()
                local _, result =
                    LobbyDeparture.requestDeparture(LobbyDeparture.create(), 3, 100, 0, MAX)
                TestRunner.equal(result.accepted, false)
                TestRunner.equal(result.reason, "platform_empty")
            end,
        },
        {
            name = "ignores a second request while a countdown is already running",
            run = function()
                local state =
                    LobbyDeparture.requestDeparture(LobbyDeparture.create(), 2, 100, 2, MAX)
                local next, result = LobbyDeparture.requestDeparture(state, 8, 104, 3, MAX)
                TestRunner.equal(result.accepted, false)
                TestRunner.equal(result.reason, "already_counting")
                TestRunner.equal(next.partySize, 2)
                TestRunner.equal(next.countdownEndsAt, 110)
            end,
        },
        {
            name = "counts down without launching before the deadline",
            run = function()
                local state =
                    LobbyDeparture.requestDeparture(LobbyDeparture.create(), 4, 100, 2, MAX)
                local next, result = LobbyDeparture.tick(state, 109.9, 2)
                TestRunner.equal(result.launch, false)
                TestRunner.equal(result.reason, "counting")
                TestRunner.equal(next.countdownEndsAt, 110)
            end,
        },
        {
            name = "launches once at the deadline and consumes the departure",
            run = function()
                local state =
                    LobbyDeparture.requestDeparture(LobbyDeparture.create(), 4, 100, 3, MAX)
                local next, result = LobbyDeparture.tick(state, 110, 3)
                TestRunner.equal(result.launch, true)
                TestRunner.equal(result.capacity, 3)
                TestRunner.equal(next.countdownEndsAt, 0)

                local again, repeated = LobbyDeparture.tick(next, 111, 3)
                TestRunner.equal(repeated.launch, false)
                TestRunner.equal(repeated.reason, "idle")
                TestRunner.equal(again.countdownEndsAt, 0)
            end,
        },
        {
            name = "boards at most the chosen party size",
            run = function()
                local state =
                    LobbyDeparture.requestDeparture(LobbyDeparture.create(), 2, 100, 5, MAX)
                local _, result = LobbyDeparture.tick(state, 110, 5)
                TestRunner.equal(result.launch, true)
                TestRunner.equal(result.capacity, 2)
            end,
        },
        {
            name = "cancels instead of launching when the platform empties",
            run = function()
                local state =
                    LobbyDeparture.requestDeparture(LobbyDeparture.create(), 4, 100, 2, MAX)
                local next, result = LobbyDeparture.tick(state, 110, 0)
                TestRunner.equal(result.launch, false)
                TestRunner.equal(result.reason, "platform_emptied")
                TestRunner.equal(next.countdownEndsAt, 0)
                TestRunner.equal(next.partySize, 0)
            end,
        },
        {
            name = "reports remaining whole seconds for the countdown rail",
            run = function()
                local state =
                    LobbyDeparture.requestDeparture(LobbyDeparture.create(), 3, 100, 1, MAX)
                TestRunner.equal(LobbyDeparture.snapshot(state, 100).secondsRemaining, 10)
                TestRunner.equal(LobbyDeparture.snapshot(state, 104.2).secondsRemaining, 6)
                TestRunner.equal(LobbyDeparture.snapshot(state, 110).counting, false)
                TestRunner.equal(LobbyDeparture.snapshot(state, 104.2).counting, true)
            end,
        },
        {
            name = "normalizes corrupt or hostile state back to idle",
            run = function()
                for _, value in
                    {
                        "departing",
                        42,
                        { partySize = 0 / 0, countdownEndsAt = 0, launchedAt = 0 },
                        { partySize = -1, countdownEndsAt = 0, launchedAt = 0 },
                        { partySize = 2, countdownEndsAt = math.huge, launchedAt = 0 },
                    }
                do
                    local normalized = LobbyDeparture.normalize(value)
                    TestRunner.equal(normalized.partySize, 0)
                    TestRunner.equal(normalized.countdownEndsAt, 0)
                end
            end,
        },
        {
            name = "rejects an out-of-range capacity or ready count instead of trusting it",
            run = function()
                local _, badCapacity =
                    LobbyDeparture.requestDeparture(LobbyDeparture.create(), 2, 100, 2, 0)
                TestRunner.equal(badCapacity.reason, "invalid_capacity")
                local _, badReady =
                    LobbyDeparture.requestDeparture(LobbyDeparture.create(), 2, 100, -1, MAX)
                TestRunner.equal(badReady.reason, "invalid_ready_count")
            end,
        },
    },
}
