--!strict

local ExtractionPayoff = require("../../src/shared/ExtractionPayoff")
local TestRunner = require("../TestRunner")

return {
    name = "ExtractionPayoff",
    cases = {
        {
            name = "summarizes every known Bramblewake material",
            run = function()
                local entries, total = ExtractionPayoff.summarize({
                    material_amber_sap = 3,
                    material_brightcap = 2,
                    material_heartwood = 4,
                    material_meadow_fiber = 1,
                })
                TestRunner.equal(#entries, 4)
                TestRunner.equal(total, 10)
            end,
        },
        {
            name = "sorts entries into a deterministic physical layout",
            run = function()
                local entries = ExtractionPayoff.summarize({
                    material_meadow_fiber = 1,
                    material_amber_sap = 1,
                })
                TestRunner.equal(entries[1].id, "material_amber_sap")
                TestRunner.equal(entries[2].id, "material_meadow_fiber")
            end,
        },
        {
            name = "ignores unknown and empty material values",
            run = function()
                local entries, total = ExtractionPayoff.summarize({
                    material_heartwood = 0,
                    material_unknown = 99,
                })
                TestRunner.equal(#entries, 0)
                TestRunner.equal(total, 0)
            end,
        },
        {
            name = "caps one delivery stack to the expedition reward limit",
            run = function()
                local entries, total = ExtractionPayoff.summarize({ material_heartwood = 1000 })
                TestRunner.equal(entries[1].amount, 100)
                TestRunner.equal(total, 100)
            end,
        },
    },
}
