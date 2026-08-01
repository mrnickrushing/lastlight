--!strict

local TestRunner = require("../TestRunner")
local WeatherProfile = require("../../src/shared/WeatherProfile")

return {
    name = "WeatherProfile",
    cases = {
        {
            name = "keeps the baseline phone rain pool bounded",
            run = function()
                for _, phase in { "day", "dusk", "night", "reveal" } do
                    local count = WeatherProfile.streakCount(phase)
                    TestRunner.truthy(count >= 0 and count <= 18)
                end
            end,
        },
        {
            name = "reserves the strongest rain layer for night",
            run = function()
                TestRunner.truthy(
                    WeatherProfile.streakCount("night") > WeatherProfile.streakCount("day")
                )
            end,
        },
        {
            name = "wraps fallen streaks into the authored vertical band",
            run = function()
                local wrapped = WeatherProfile.wrapHeight(-70, -12, 28)
                TestRunner.truthy(wrapped >= -12 and wrapped <= 28)
            end,
        },
        {
            name = "uses day density for an unknown phase",
            run = function()
                TestRunner.equal(
                    WeatherProfile.streakCount("unknown"),
                    WeatherProfile.streakCount("day")
                )
            end,
        },
    },
}
