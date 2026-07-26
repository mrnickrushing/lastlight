--!strict

local Registry = require("../../src/shared/Content/Registry")
local Regions = require("../../src/shared/Content/Definitions/Regions")
local TestRunner = require("../TestRunner")

return {
    name = "ContentRegistry",
    cases = {
        {
            name = "loads the seven launch regions with stable lookup",
            run = function()
                local registry = Registry.new(Regions)
                TestRunner.equal(registry:count(), 7)
                TestRunner.truthy(registry:has("region_bramblewake"))
                TestRunner.equal(registry:get("region_hollow").version, 1)
                TestRunner.equal(#registry:byKind("region"), 7)
                TestRunner.throws(function()
                    registry:get("region_bramblewake").tags[1] = "mutated"
                end, "readonly")
            end,
        },
        {
            name = "rejects duplicate IDs",
            run = function()
                local duplicate = table.clone(Regions)
                table.insert(duplicate, Regions[1])
                local valid, issues = Registry.validate(duplicate)

                TestRunner.equal(valid, false)
                TestRunner.truthy(#issues > 0)
            end,
        },
        {
            name = "rejects missing dependency references",
            run = function()
                local invalid = {
                    {
                        id = "region_example",
                        kind = "region",
                        version = 1,
                        enabled = true,
                        displayNameKey = "content.region.example.name",
                        analyticsKey = "region_example",
                        assetBundle = "region_example_v1",
                        tags = { "test" },
                        dependencies = { "region_missing" },
                    },
                }
                local valid, issues = Registry.validate(invalid)

                TestRunner.equal(valid, false)
                TestRunner.truthy(#issues > 0)
            end,
        },
    },
}
