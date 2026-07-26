--!strict

local Environment = require("../../src/shared/Environment")
local TestRunner = require("../TestRunner")

return {
    name = "Environment",
    cases = {
        {
            name = "uses local or test inside Studio",
            run = function()
                local localName = Environment.resolve({
                    isStudio = true,
                    placeId = 0,
                    requested = nil,
                    productionPlaceIds = {},
                })
                TestRunner.equal(localName, "local")

                local testName = Environment.resolve({
                    isStudio = true,
                    placeId = 0,
                    requested = "test",
                    productionPlaceIds = {},
                })
                TestRunner.equal(testName, "test")
            end,
        },
        {
            name = "fails closed for an unregistered production place",
            run = function()
                local environment, message = Environment.resolve({
                    isStudio = false,
                    placeId = 123,
                    requested = "production",
                    productionPlaceIds = {},
                })
                TestRunner.equal(environment, nil)
                TestRunner.truthy(string.find(message or "", "ProductionPlaceIds", 1, true))
            end,
        },
        {
            name = "rejects production inside Studio",
            run = function()
                local environment, message = Environment.resolve({
                    isStudio = true,
                    placeId = 123,
                    requested = "production",
                    productionPlaceIds = { 123 },
                })
                TestRunner.equal(environment, nil)
                TestRunner.truthy(string.find(message or "", "Roblox Studio", 1, true))
            end,
        },
        {
            name = "recognizes registered production places",
            run = function()
                local environment = Environment.resolve({
                    isStudio = false,
                    placeId = 123,
                    requested = nil,
                    productionPlaceIds = { 123 },
                })
                TestRunner.equal(environment, "production")
            end,
        },
    },
}
