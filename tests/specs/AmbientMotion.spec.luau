--!strict

local AmbientMotion = require("../../src/shared/AmbientMotion")
local TestRunner = require("../TestRunner")

return {
    name = "AmbientMotion",
    cases = {
        {
            name = "wraps rotor motion to one turn",
            run = function()
                local angle = AmbientMotion.rotorAngle(100, 2.4, 1.1)
                TestRunner.truthy(angle >= 0 and angle < math.pi * 2)
            end,
        },
        {
            name = "makes practical lights stronger at night than day",
            run = function()
                local day = AmbientMotion.lightLevel(0, 0, "day")
                local night = AmbientMotion.lightLevel(0, 0, "night")
                TestRunner.truthy(night > day)
            end,
        },
        {
            name = "keeps flicker inside the authored brightness envelope",
            run = function()
                for index = 0, 200 do
                    local level = AmbientMotion.lightLevel(index / 10, 1.7, "night")
                    TestRunner.truthy(level >= 0.58 and level <= 1.08)
                end
            end,
        },
        {
            name = "uses the safe day profile for unknown phases",
            run = function()
                TestRunner.equal(
                    AmbientMotion.lightLevel(0, 0, "unknown"),
                    AmbientMotion.lightLevel(0, 0, "day")
                )
            end,
        },
    },
}
