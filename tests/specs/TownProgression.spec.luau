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
                TestRunner.equal(consequence.buildingStages.building_archive, 2)
                TestRunner.equal(consequence.buildingStages.building_inn, 1)
                -- Chapter one resolved means chapter two is being played,
                -- and a chapter's residents are present while it is played
                -- (the semantic ChapterProgress.spec pinned): the Delve's
                -- four have come home alongside the original three.
                TestRunner.equal(#consequence.residentIds, 7)
                TestRunner.equal(consequence.residentIds[1], "npc_tomas_reed")
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
                TestRunner.equal(consequence.buildingStages.building_archive, 0)
                TestRunner.equal(consequence.buildingStages.building_town_board, 1)
                TestRunner.equal(consequence.buildingStages.building_inn, 0)
                TestRunner.equal(#consequence.residentIds, 0)
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
        {
            name = "the town has twenty-two buildings and every one of them stages",
            run = function()
                -- Milestone 4 asked for sixteen; tiers four and five bring
                -- six more. The count is asserted here so adding an asset
                -- without wiring its progression, or wiring one without
                -- adding it to the shared list, fails rather than quietly
                -- producing a town with a hole in it.
                local ids = TownProgression.buildingIds()
                TestRunner.equal(#ids, 22)

                local seen: { [string]: boolean } = {}
                for _, buildingId in ids do
                    TestRunner.truthy(not seen[buildingId], "duplicate building " .. buildingId)
                    seen[buildingId] = true
                end

                for tier = 0, 5 do
                    local consequence = TownProgression.resolve({
                        town = { nightNumber = tier * 3 + 1 },
                    })
                    for _, buildingId in ids do
                        local stage = consequence.buildingStages[buildingId]
                        TestRunner.truthy(
                            type(stage) == "number" and stage >= 0 and stage <= 3,
                            string.format("%s has no readable stage at tier %d", buildingId, tier)
                        )
                    end
                end
            end,
        },
        {
            name = "a building never un-builds itself as the town grows",
            run = function()
                -- Whatever the staging curve, no building may go backwards
                -- between one tier and the next. A town that survives more
                -- nights cannot show less than it did before.
                local previous: { [string]: number } = {}
                for nights = 1, 16 do
                    local consequence = TownProgression.resolve({ town = { nightNumber = nights } })
                    for buildingId, stage in consequence.buildingStages do
                        local before = previous[buildingId]
                        if before ~= nil then
                            TestRunner.truthy(
                                stage >= before,
                                string.format(
                                    "%s fell from %d to %d at night %d",
                                    buildingId,
                                    before,
                                    stage,
                                    nights
                                )
                            )
                        end
                        previous[buildingId] = stage
                    end
                end
            end,
        },
        {
            name = "every building is reconciled between players, not just the first five",
            run = function()
                -- The merge used to read a hardcoded list of five. A building
                -- missing from it stops reconciling, which reads in game as
                -- the building flickering as people join.
                local mature = TownProgression.resolve({ town = { nightNumber = 12 } })
                local fresh = TownProgression.resolve({ town = { nightNumber = 1 } })

                local merged = TownProgression.merge(mature, fresh)
                for _, buildingId in TownProgression.buildingIds() do
                    TestRunner.truthy(
                        merged.buildingStages[buildingId] ~= nil,
                        buildingId .. " was dropped by the merge"
                    )
                    TestRunner.truthy(
                        merged.buildingStages[buildingId] >= mature.buildingStages[buildingId],
                        buildingId .. " regressed when a fresh player joined"
                    )
                end
            end,
        },
        {
            name = "caps mature building stages at tier three",
            run = function()
                local consequence = TownProgression.resolve({
                    town = { nightNumber = 100 },
                })
                TestRunner.equal(consequence.tier, 3)
                TestRunner.equal(consequence.buildingStages.building_archive, 3)
                TestRunner.equal(consequence.buildingStages.building_inn, 2)
            end,
        },
        {
            name = "never regresses a shared town when a fresh player joins",
            run = function()
                local established = TownProgression.resolve({
                    town = { nightNumber = 7 },
                    story = {
                        chapterOne = {
                            status = "complete",
                            decision = "shared_agroforest",
                            wardenOutcome = "preserved",
                        },
                    },
                })
                local merged = TownProgression.merge(established, TownProgression.resolve({}))
                TestRunner.equal(merged.tier, 2)
                TestRunner.equal(merged.decision, "shared_agroforest")
                TestRunner.equal(merged.buildingStages.building_archive, 2)
                -- chapter one resolved = chapter two being played = the
                -- Delve's four are home (the ChapterProgress.spec semantic)
                TestRunner.equal(#merged.residentIds, 7)
            end,
        },
        {
            name = "adopts higher construction without erasing the first shared consequence",
            run = function()
                local farmland = TownProgression.resolve({
                    story = {
                        chapterOne = {
                            status = "complete",
                            decision = "restore_farmland",
                            wardenOutcome = "scarred",
                        },
                    },
                })
                local veteran = TownProgression.resolve({ town = { nightNumber = 10 } })
                local merged = TownProgression.merge(farmland, veteran)
                TestRunner.equal(merged.tier, 3)
                TestRunner.equal(merged.landscapeKind, "cultivated_fields")
                TestRunner.equal(merged.memorialKind, "scarred_antlers")
                TestRunner.equal(merged.buildingStages.building_archive, 3)
                TestRunner.equal(merged.buildingStages.building_inn, 2)
            end,
        },
        {
            name = "adopts the first resolved chapter arriving after an unresolved player",
            run = function()
                local unresolved = TownProgression.resolve({})
                local wild = TownProgression.resolve({
                    story = {
                        chapterOne = {
                            status = "complete",
                            decision = "wild_regrowth",
                            wardenOutcome = "harmed",
                        },
                    },
                })
                local merged = TownProgression.merge(unresolved, wild)
                TestRunner.equal(merged.decision, "wild_regrowth")
                TestRunner.equal(merged.memorialKind, "broken_antlers")
            end,
        },
        {
            -- The same contract two chapters further on: the Reach lifts the
            -- ceiling, the Vale floors the town at the top of it, and a
            -- player who never leaves Bramblewake still tops out at 3.
            name = "the Reach opens tier five and the Vale floors the town in it",
            run = function()
                local chapterOne = {
                    status = "complete",
                    decision = "shared_agroforest",
                    wardenOutcome = "preserved",
                }
                local throughFour = {
                    chapterOne = chapterOne,
                    chapters = {
                        chapter_four = { status = "complete", outcome = "navigable" },
                        chapter_three = { status = "complete", outcome = "sealed" },
                        chapter_two = { status = "complete", outcome = "cleared" },
                    },
                }
                -- floored at four on a young calendar
                local young = TownProgression.resolve({
                    story = throughFour,
                    town = { nightNumber = 1 },
                })
                TestRunner.equal(young.tier, 4)
                -- and the ceiling is five, which no number of nights alone
                -- could have reached
                local matured = TownProgression.resolve({
                    story = throughFour,
                    town = { nightNumber = 100 },
                })
                TestRunner.equal(matured.tier, 5)
                TestRunner.equal(matured.buildingStages.building_signal_house, 2)
                TestRunner.equal(matured.buildingStages.building_ropewalk, 1)
                TestRunner.equal(matured.buildingStages.building_infirmary, 1)
                -- the Vale's own buildings are lots until the ceiling lifts
                TestRunner.equal(young.buildingStages.building_ropewalk, 0)
                TestRunner.equal(young.buildingStages.building_bell_tower, 0)
                -- the Vale floors the town at the top of the new ceiling
                local throughFive = {
                    chapterOne = chapterOne,
                    chapters = {
                        chapter_five = { status = "complete", outcome = "sheltered" },
                        chapter_four = { status = "complete", outcome = "navigable" },
                        chapter_three = { status = "complete", outcome = "sealed" },
                        chapter_two = { status = "complete", outcome = "cleared" },
                    },
                }
                TestRunner.equal(
                    TownProgression.resolve({
                        story = throughFive,
                        town = { nightNumber = 1 },
                    }).tier,
                    5
                )
                -- and nights alone still cap where they always did
                TestRunner.equal(TownProgression.resolve({ town = { nightNumber = 900 } }).tier, 3)
            end,
        },
        {
            -- Milestone 7: the town grows to tier 4, but only the story can
            -- take it there — nights alone still cap at 3, spec-pinned above.
            name = "the story, not the calendar, opens tier four",
            run = function()
                local chapterOne = {
                    status = "complete",
                    decision = "shared_agroforest",
                    wardenOutcome = "preserved",
                }
                -- chapter II floors the tier at 2 and raises the ceiling
                local afterMaw = TownProgression.resolve({
                    story = {
                        chapterOne = chapterOne,
                        chapters = {
                            chapter_two = { status = "complete", outcome = "cleared" },
                        },
                    },
                    town = { nightNumber = 1 },
                })
                TestRunner.equal(afterMaw.tier, 2)
                local matured = TownProgression.resolve({
                    story = {
                        chapterOne = chapterOne,
                        chapters = {
                            chapter_two = { status = "complete", outcome = "cleared" },
                        },
                    },
                    town = { nightNumber = 100 },
                })
                TestRunner.equal(matured.tier, 4)
                -- tier 4 matures the late buildings one more stage
                TestRunner.equal(matured.buildingStages.building_celebration_stage, 2)
                TestRunner.equal(matured.buildingStages.building_sawmill, 3)
                -- chapter III floors the tier at 3 even on a young calendar
                local afterWitch = TownProgression.resolve({
                    story = {
                        chapterOne = chapterOne,
                        chapters = {
                            chapter_two = { status = "complete", outcome = "cleared" },
                            chapter_three = { status = "complete", outcome = "sealed" },
                        },
                    },
                    town = { nightNumber = 1 },
                })
                TestRunner.equal(afterWitch.tier, 3)
            end,
        },
        {
            -- The cast is the story's: three residents through chapter I,
            -- seven once the Delve is resolved, eleven once the Fen is.
            name = "residents come home with their chapters",
            run = function()
                local chapterOne = {
                    status = "complete",
                    decision = "wild_regrowth",
                    wardenOutcome = "scarred",
                }
                -- a pre-chapter town holds only the original three
                local fresh = TownProgression.resolve({
                    town = { nightNumber = 10 },
                })
                TestRunner.equal(#fresh.residentIds, 3)
                -- chapter one resolved: the Delve's four arrive with the
                -- chapter now being played
                local early = TownProgression.resolve({
                    story = { chapterOne = chapterOne },
                    town = { nightNumber = 10 },
                })
                TestRunner.equal(#early.residentIds, 7)
                local afterMaw = TownProgression.resolve({
                    story = {
                        chapterOne = chapterOne,
                        chapters = {
                            chapter_two = { status = "complete", outcome = "fouled" },
                        },
                    },
                    town = { nightNumber = 10 },
                })
                TestRunner.equal(#afterMaw.residentIds, 11)
                -- a merged shared town keeps the larger cast and can hold 4
                local merged = TownProgression.merge(afterMaw, fresh)
                TestRunner.equal(#merged.residentIds, 11)
                local four = TownProgression.resolve({
                    story = {
                        chapterOne = chapterOne,
                        chapters = {
                            chapter_two = { status = "complete", outcome = "cleared" },
                        },
                    },
                    town = { nightNumber = 100 },
                })
                TestRunner.equal(TownProgression.merge(early, four).tier, 4)
            end,
        },
    },
}
