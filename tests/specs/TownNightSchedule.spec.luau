--!strict

local TownNightSchedule = require("../../src/shared/TownNightSchedule")
local TestRunner = require("../TestRunner")

return {
    name = "TownNightSchedule",
    cases = {
        {
            name = "escalates wave count with night number, capped at the roster ceiling",
            run = function()
                TestRunner.equal(TownNightSchedule.waveCount(1), 3)
                TestRunner.equal(TownNightSchedule.waveCount(6), 8)
                TestRunner.equal(TownNightSchedule.waveCount(20), 8)
            end,
        },
        {
            name = "rejects a non-positive or fractional night number",
            run = function()
                TestRunner.throws(function()
                    TownNightSchedule.waveCount(0)
                end)
                TestRunner.throws(function()
                    TownNightSchedule.beats(360, 1.5)
                end)
            end,
        },
        {
            name = "opens every night with a warning beat at time zero",
            run = function()
                local beats = TownNightSchedule.beats(360, 1)
                TestRunner.equal(beats[1].kind, "warning")
                TestRunner.equal(beats[1].at, 0)
            end,
        },
        {
            name = "never schedules a beat outside the duration across escalating nights",
            run = function()
                for nightNumber = 1, 9 do
                    for _, beat in TownNightSchedule.beats(360, nightNumber) do
                        TestRunner.truthy(beat.at < 360)
                    end
                end
            end,
        },
        {
            name = "includes exactly one breach beat per night",
            run = function()
                local breaches = 0
                for _, beat in TownNightSchedule.beats(360, 4) do
                    if beat.kind == "breach" then
                        breaches += 1
                    end
                end
                TestRunner.equal(breaches, 1)
            end,
        },
        {
            name = "schedules one theme incident with time left to resolve it",
            run = function()
                local incidents = 0
                for _, beat in TownNightSchedule.beats(360, 4) do
                    if beat.kind == "incident" then
                        incidents += 1
                        TestRunner.equal(beat.theme, "ASHEN VEIL")
                        TestRunner.truthy(beat.at <= 360 - 42)
                    end
                end
                TestRunner.equal(incidents, 1)
            end,
        },
        {
            name = "cycles through the full six-enemy roster on a long escalated night",
            run = function()
                local seen = {}
                for _, beat in TownNightSchedule.beats(360, 6) do
                    if beat.kind == "spawn" then
                        TestRunner.truthy(beat.enemyId ~= nil)
                        seen[beat.enemyId] = true
                    end
                end
                TestRunner.equal(seen.enemy_rootling, true)
                TestRunner.equal(seen.enemy_briarback, true)
                TestRunner.equal(seen.enemy_zombie, true)
                TestRunner.equal(seen.enemy_hollow_crow, true)
                TestRunner.equal(seen.enemy_snapvine, true)
                TestRunner.equal(seen.enemy_bark_ram, true)
            end,
        },
        {
            name = "numbers every spawn beat for readable wave presentation",
            run = function()
                local expectedWave = 1
                for _, beat in TownNightSchedule.beats(360, 5) do
                    if beat.kind == "spawn" then
                        TestRunner.equal(beat.wave, expectedWave)
                        expectedWave += 1
                    end
                end
                TestRunner.equal(expectedWave - 1, TownNightSchedule.waveCount(5))
            end,
        },
        {
            name = "returns beats sorted by ascending time",
            run = function()
                local beats = TownNightSchedule.beats(360, 5)
                for index = 2, #beats do
                    TestRunner.truthy(beats[index].at >= beats[index - 1].at)
                end
            end,
        },
        {
            name = "rotates readable themes and roster order by night",
            run = function()
                TestRunner.equal(TownNightSchedule.theme(1), "EMBERFALL")
                TestRunner.equal(TownNightSchedule.theme(5), "EMBERFALL")
                local nightOne = TownNightSchedule.beats(120, 1)
                local nightTwo = TownNightSchedule.beats(120, 2)
                TestRunner.equal(nightOne[2].enemyId, "enemy_rootling")
                TestRunner.equal(nightTwo[2].enemyId, "enemy_briarback")
            end,
        },
        {
            name = "gives every theme a distinct bounded gameplay profile",
            run = function()
                local signatures = {}
                for nightNumber = 1, 4 do
                    local profile = TownNightSchedule.profile(nightNumber)
                    TestRunner.truthy(type(profile.instruction) == "string")
                    TestRunner.truthy(profile.healthMultiplier >= 0.8)
                    TestRunner.truthy(profile.healthMultiplier <= 1.3)
                    TestRunner.truthy(profile.speedMultiplier >= 0.8)
                    TestRunner.truthy(profile.speedMultiplier <= 1.3)
                    TestRunner.truthy(profile.playerDamageMultiplier >= 1)
                    TestRunner.truthy(profile.playerDamageMultiplier <= 1.2)
                    TestRunner.truthy(profile.lanternDamageMultiplier >= 1)
                    TestRunner.truthy(profile.lanternDamageMultiplier <= 1.25)
                    local signature = string.format(
                        "%.2f:%.2f:%.2f:%.2f",
                        profile.healthMultiplier,
                        profile.speedMultiplier,
                        profile.playerDamageMultiplier,
                        profile.lanternDamageMultiplier
                    )
                    TestRunner.equal(signatures[signature], nil)
                    signatures[signature] = true
                end
            end,
        },
        {
            name = "pending excludes beats already passed",
            run = function()
                local all = TownNightSchedule.beats(360, 3)
                local pending = TownNightSchedule.pending(360, 3, 60)
                TestRunner.truthy(#pending < #all)
                for _, beat in pending do
                    TestRunner.truthy(beat.at >= 60)
                end
            end,
        },
        {
            name = "is deterministic for the same duration and night number",
            run = function()
                local first = TownNightSchedule.beats(360, 4)
                local second = TownNightSchedule.beats(360, 4)
                TestRunner.equal(#first, #second)
                for index = 1, #first do
                    TestRunner.equal(first[index].at, second[index].at)
                    TestRunner.equal(first[index].kind, second[index].kind)
                    TestRunner.equal(first[index].enemyId, second[index].enemyId)
                end
            end,
        },
    },
}
