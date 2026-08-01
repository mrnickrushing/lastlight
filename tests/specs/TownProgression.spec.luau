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
                TestRunner.equal(consequence.landscapeKind, "community_orchard")
                TestRunner.equal(consequence.memorialKind, "living_antlers")
                TestRunner.equal(consequence.growthStage, 2)
            end,
        },
        {
            name = "uses a safe unresolved starting consequence",
            run = function()
                local consequence = TownProgression.resolve({})
                TestRunner.equal(consequence.tier, 0)
                TestRunner.equal(consequence.title, "EMBERHOLLOW AWAKENS")
                TestRunner.equal(consequence.landscapeKind, "seed_ground")
                TestRunner.equal(consequence.memorialKind, "unmarked_stone")
            end,
        },
        {
            name = "distinguishes farmland and a scarred Warden memorial",
            run = function()
                local consequence = TownProgression.resolve({
                    story = {
                        chapterOne = {
                            status = "complete",
                            decision = "restore_farmland",
                            wardenOutcome = "scarred",
                        },
                    },
                })
                TestRunner.equal(consequence.landscapeKind, "cultivated_fields")
                TestRunner.equal(consequence.memorialKind, "scarred_antlers")
            end,
        },
        {
            name = "distinguishes wild regrowth and a broken Warden memorial",
            run = function()
                local consequence = TownProgression.resolve({
                    story = {
                        chapterOne = {
                            status = "complete",
                            decision = "wild_regrowth",
                            wardenOutcome = "harmed",
                        },
                    },
                })
                TestRunner.equal(consequence.landscapeKind, "living_grove")
                TestRunner.equal(consequence.memorialKind, "broken_antlers")
            end,
        },
    },
}
