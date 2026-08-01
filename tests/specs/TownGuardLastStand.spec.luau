--!strict

local TownGuardLastStand = require("../../src/shared/TownGuardLastStand")
local TestRunner = require("../TestRunner")

local function context(overrides: any?): any
    local result = {
        phase = "night",
        nightNumber = 3,
        lanternHealth = 72,
        eligiblePlayers = 2,
        downedPlayers = 2,
    }
    for key, value in overrides or {} do
        result[key] = value
    end
    return result
end

return {
    name = "TownGuardLastStand",
    cases = {
        {
            name = "recovers one fully downed party at a bounded lantern cost",
            run = function()
                local state, result =
                    TownGuardLastStand.attempt(TownGuardLastStand.default(), context())
                TestRunner.equal(result.accepted, true)
                TestRunner.equal(result.lanternCost, 12)
                TestRunner.equal(result.recoveryHealth, 50)
                TestRunner.equal(result.recoveryWardSeconds, 5)
                TestRunner.equal(state.usedNight, 3)
            end,
        },
        {
            name = "never fires while one eligible player can still act",
            run = function()
                local state, result = TownGuardLastStand.attempt(
                    TownGuardLastStand.default(),
                    context({ downedPlayers = 1 })
                )
                TestRunner.equal(result.reason, "party_still_active")
                TestRunner.equal(state.usedNight, 0)
            end,
        },
        {
            name = "allows only one recovery per night",
            run = function()
                local used = TownGuardLastStand.attempt(TownGuardLastStand.default(), context())
                local unchanged, replay = TownGuardLastStand.attempt(used, context())
                TestRunner.equal(replay.reason, "last_stand_spent")
                TestRunner.equal(unchanged.usedNight, 3)
            end,
        },
        {
            name = "requires enough First Lantern strength",
            run = function()
                local _, result = TownGuardLastStand.attempt(
                    TownGuardLastStand.default(),
                    context({ lanternHealth = 29 })
                )
                TestRunner.equal(result.reason, "lantern_too_weak")
            end,
        },
        {
            name = "does not recover expedition or daylight parties",
            run = function()
                local _, daylight = TownGuardLastStand.attempt(
                    TownGuardLastStand.default(),
                    context({ phase = "day" })
                )
                local _, empty = TownGuardLastStand.attempt(
                    TownGuardLastStand.default(),
                    context({ eligiblePlayers = 0, downedPlayers = 0 })
                )
                TestRunner.equal(daylight.reason, "night_inactive")
                TestRunner.equal(empty.reason, "party_empty")
            end,
        },
        {
            name = "rejects malformed counts without spending recovery",
            run = function()
                local state, result = TownGuardLastStand.attempt(
                    TownGuardLastStand.default(),
                    context({ eligiblePlayers = 1.5 })
                )
                TestRunner.equal(result.reason, "invalid_context")
                TestRunner.equal(state.usedNight, 0)
            end,
        },
    },
}
