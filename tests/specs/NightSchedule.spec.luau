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
                TestRunner.equal(#beats, 8)
                TestRunner.equal(beats[1].kind, "warning")
                TestRunner.equal(beats[2].kind, "spawn")
                TestRunner.equal(beats[2].enemyId, "enemy_rootling")
                TestRunner.equal(beats[8].enemyId, "enemy_bark_ram")
                TestRunner.equal(beats[8].at, 94)
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
                TestRunner.equal(#pending, 5)
                TestRunner.equal(pending[1].enemyId, "enemy_zombie")
                TestRunner.equal(pending[2].kind, "breach")
            end,
        },
        {
            name = "schedules every roster member once",
            run = function()
                local seen = {}
                for _, beat in NightSchedule.beats(120) do
                    if beat.kind == "spawn" then
                        TestRunner.truthy(beat.enemyId ~= nil)
                        TestRunner.truthy(seen[beat.enemyId] == nil)
                        seen[beat.enemyId] = true
                    end
                end
                TestRunner.equal(seen.enemy_rootling, true)
                TestRunner.equal(seen.enemy_bark_ram, true)
            end,
        },
    },
}
