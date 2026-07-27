--!strict

local TownProgression = require("../../src/shared/TownProgression")
local TestRunner = require("../TestRunner")

return {
    name = "TownProgression",
    cases = {
        {
            name = "raises tier after chapter resolution and nights",
            run = function()
                local consequence = TownProgression.resolve({
                    town = { nightNumber = 7 },
                    story = {
                        chapterOne = {
                            status = "complete",
                            decision = "shared_agroforest",
                            wardenOutcome = "preserved",
                        },
                    },
                })
                TestRunner.equal(consequence.tier, 2)
                TestRunner.equal(consequence.title, "SHARED AGROFOREST")
            end,
        },
        {
            name = "uses a safe unresolved starting consequence",
            run = function()
                local consequence = TownProgression.resolve({})
                TestRunner.equal(consequence.tier, 0)
                TestRunner.equal(consequence.title, "EMBERHOLLOW AWAKENS")
            end,
        },
    },
}
