--!strict

local NightSchedule = require("../../src/shared/NightSchedule")
local TestRunner = require("../TestRunner")

return {
    name = "NightSchedule",
    cases = {
        {
            name = "authors a full two-minute night",
            run = function()
                local beats = NightSchedule.beats(120)
                TestRunner.equal(#beats, 5)
                TestRunner.equal(beats[1].kind, "warning")
                TestRunner.equal(beats[2].kind, "spawn")
                TestRunner.equal(beats[5].at, 76)
            end,
        },
        {
            name = "never schedules a beat outside the duration",
            run = function()
                for _, beat in NightSchedule.beats(45) do
                    TestRunner.truthy(beat.at < 45)
                end
            end,
        },
        {
            name = "returns only pending beats after reconnect",
            run = function()
                local pending = NightSchedule.pending(120, 40)
                TestRunner.equal(#pending, 2)
                TestRunner.equal(pending[1].kind, "breach")
            end,
        },
    },
}
