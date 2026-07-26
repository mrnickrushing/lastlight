--!strict

local FeatureFlagService = require("../../src/server/Services/FeatureFlagService")
local TestRunner = require("../TestRunner")

local silentLogger = {
    info = function() end,
    warn = function() end,
}

return {
    name = "FeatureFlagService",
    cases = {
        {
            name = "reads defaults and local overrides",
            run = function()
                local flags = FeatureFlagService.new({ example = false }, true, silentLogger)
                TestRunner.equal(flags:isEnabled("example"), false)

                local changed = flags:setOverride("example", true)
                TestRunner.equal(changed, true)
                TestRunner.equal(flags:isEnabled("example"), true)

                flags:clearOverride("example")
                TestRunner.equal(flags:isEnabled("example"), false)
            end,
        },
        {
            name = "rejects production overrides",
            run = function()
                local flags = FeatureFlagService.new({ example = false }, false, silentLogger)
                local changed, message = flags:setOverride("example", true)

                TestRunner.equal(changed, false)
                TestRunner.truthy(message)
                TestRunner.equal(flags:isEnabled("example"), false)
            end,
        },
    },
}
