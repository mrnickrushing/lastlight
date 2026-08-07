--!strict

local BellowsMaw = require("../../src/shared/BellowsMawEncounter")
local ChapterCatalog = require("../../src/shared/ChapterCatalog")
local LanternWitch = require("../../src/shared/LanternWitchEncounter")
local AshRegent = require("../../src/shared/AshRegentEncounter")
local NamelessNight = require("../../src/shared/NamelessNightEncounter")
local TideboundTitan = require("../../src/shared/TideboundTitanEncounter")
local WhiteHowler = require("../../src/shared/WhiteHowlerEncounter")
local ResidentRoster = require("../../src/shared/ResidentRoster")
local SaveSchema = require("../../src/shared/SaveSchema")
local WardenStag = require("../../src/shared/WardenStagEncounter")
local TestRunner = require("../TestRunner")

local function resolvedChapterOne(profile: any): any
    return (
        SaveSchema.withChapterOneResolution(
            profile,
            "chapter_1:run:hash:7",
            "shared_agroforest",
            "preserved",
            100
        )
    )
end

return {
    name = "ChapterProgress",
    cases = {
        {
            name = "every chapter names a region, a boss, and outcomes its boss can reach",
            run = function()
                local chapters = ChapterCatalog.list()
                TestRunner.equal(#chapters, 7)
                local bosses = {
                    boss_warden_stag = WardenStag,
                    boss_bellows_maw = BellowsMaw,
                    boss_lantern_witch = LanternWitch,
                    boss_tidebound_titan = TideboundTitan,
                    boss_white_howler = WhiteHowler,
                    boss_ash_regent = AshRegent,
                    boss_nameless_night = NamelessNight,
                }
                for index, definition in chapters do
                    TestRunner.equal(definition.number, index)
                    TestRunner.truthy(#definition.decisions >= 3)
                    TestRunner.truthy(#definition.outcomes == 3)
                    TestRunner.truthy(
                        bosses[definition.bossId] ~= nil,
                        definition.id .. " names a boss that does not exist"
                    )
                    TestRunner.equal(ChapterCatalog.forBoss(definition.bossId).id, definition.id)
                    TestRunner.equal(
                        ChapterCatalog.forRegion(definition.regionId).id,
                        definition.id
                    )
                end
                TestRunner.equal(ChapterCatalog.require("chapter_two").requires, "chapter_one")
                TestRunner.equal(ChapterCatalog.require("chapter_three").requires, "chapter_two")
                TestRunner.equal(ChapterCatalog.require("chapter_four").requires, "chapter_three")
                TestRunner.equal(ChapterCatalog.require("chapter_five").requires, "chapter_four")
                TestRunner.equal(ChapterCatalog.require("chapter_six").requires, "chapter_five")
                TestRunner.equal(ChapterCatalog.require("chapter_seven").requires, "chapter_six")
                -- no two chapters may claim the same region or the same
                -- boss, or forRegion and forBoss silently answer for one
                -- of them and the other becomes unreachable
                local claimedRegions: { [string]: boolean } = {}
                local claimedBosses: { [string]: boolean } = {}
                for _, definition in chapters do
                    TestRunner.equal(
                        claimedRegions[definition.regionId],
                        nil,
                        "region claimed twice"
                    )
                    TestRunner.equal(claimedBosses[definition.bossId], nil, "boss claimed twice")
                    claimedRegions[definition.regionId] = true
                    claimedBosses[definition.bossId] = true
                end
            end,
        },
        {
            -- The encounters record their endings in their own words. If a
            -- chapter's outcome list drifts from what its boss can actually
            -- produce, a real ending becomes unstorable.
            name = "each boss's endings are exactly what its chapter can record",
            run = function()
                for _, outcome in { "preserved", "scarred", "harmed" } do
                    TestRunner.equal(ChapterCatalog.isOutcome("chapter_one", outcome), true)
                end
                for _, outcome in { "cleared", "fouled", "mixed" } do
                    TestRunner.equal(ChapterCatalog.isOutcome("chapter_two", outcome), true)
                end
                for _, outcome in { "sealed", "bound", "broken" } do
                    TestRunner.equal(ChapterCatalog.isOutcome("chapter_three", outcome), true)
                end
                for _, outcome in { "navigable", "scoured", "broken" } do
                    TestRunner.equal(ChapterCatalog.isOutcome("chapter_four", outcome), true)
                end
                for _, outcome in { "sheltered", "thinned", "silenced" } do
                    TestRunner.equal(ChapterCatalog.isOutcome("chapter_five", outcome), true)
                end
                TestRunner.equal(ChapterCatalog.isOutcome("chapter_four", "sheltered"), false)
                TestRunner.equal(ChapterCatalog.isOutcome("chapter_five", "navigable"), false)
                for _, outcome in { "remembered", "recast", "erased" } do
                    TestRunner.equal(ChapterCatalog.isOutcome("chapter_six", outcome), true)
                end
                for _, outcome in { "lantern_kept", "lantern_out", "lantern_shared" } do
                    TestRunner.equal(ChapterCatalog.isOutcome("chapter_seven", outcome), true)
                end
                TestRunner.equal(ChapterCatalog.isOutcome("chapter_two", "sealed"), false)
                TestRunner.equal(
                    ChapterCatalog.isDecision("chapter_two", "restore_farmland"),
                    false
                )
                TestRunner.equal(ChapterCatalog.isOutcome("chapter_nine", "sealed"), false)
            end,
        },
        {
            -- The same idempotency contract chapter one has had since it
            -- shipped: a repeat is a duplicate, a rival is refused.
            name = "a chapter resolves once, and a repeat is a duplicate rather than an error",
            run = function()
                local profile = resolvedChapterOne(SaveSchema.default(1000))
                local resolved, result = SaveSchema.withChapterResolution(
                    profile,
                    "chapter_two",
                    "chapter_2:run:hash:7",
                    "vent_stope",
                    "cleared",
                    200
                )
                TestRunner.equal(result.applied, true)
                TestRunner.equal(result.record.outcome, "cleared")
                TestRunner.equal(SaveSchema.isChapterComplete(resolved, "chapter_two"), true)

                local _, duplicate = SaveSchema.withChapterResolution(
                    resolved,
                    "chapter_two",
                    "chapter_2:run:hash:7",
                    "vent_stope",
                    "cleared",
                    300
                )
                TestRunner.equal(duplicate.applied, false)
                TestRunner.equal(duplicate.duplicate, true)

                local _, rival = SaveSchema.withChapterResolution(
                    resolved,
                    "chapter_two",
                    "chapter_2:other:hash:7",
                    "vent_drifts",
                    "fouled",
                    300
                )
                TestRunner.equal(rival.applied, false)
                TestRunner.equal(rival.reason, "chapter_already_resolved")
            end,
        },
        {
            -- Chapters are a chain: III cannot be recorded before II, and II
            -- cannot be recorded before the Warden's own resolution.
            name = "a chapter cannot be resolved before the one it requires",
            run = function()
                local fresh = SaveSchema.default(1000)
                local _, tooEarly = SaveSchema.withChapterResolution(
                    fresh,
                    "chapter_two",
                    "chapter_2:run:hash:7",
                    "vent_stope",
                    "cleared",
                    200
                )
                TestRunner.equal(tooEarly.applied, false)
                TestRunner.equal(tooEarly.reason, "chapter_locked")

                local afterOne = resolvedChapterOne(fresh)
                local _, stillEarly = SaveSchema.withChapterResolution(
                    afterOne,
                    "chapter_three",
                    "chapter_3:run:hash:7",
                    "spared_copies",
                    "sealed",
                    200
                )
                TestRunner.equal(stillEarly.applied, false)
                TestRunner.equal(stillEarly.reason, "chapter_locked")
            end,
        },
        {
            -- Chapter progress is what tells a resident whether they have
            -- arrived. A fresh save is chapter one and meets three people.
            name = "chapter progress fills the town as the story advances",
            run = function()
                local fresh = SaveSchema.default(1000)
                TestRunner.equal(SaveSchema.chapterProgress(fresh), 1)
                TestRunner.equal(
                    #ResidentRoster.idsForChapter(SaveSchema.chapterProgress(fresh)),
                    3
                )

                local afterOne = resolvedChapterOne(fresh)
                TestRunner.equal(SaveSchema.chapterProgress(afterOne), 2)
                TestRunner.equal(
                    #ResidentRoster.idsForChapter(SaveSchema.chapterProgress(afterOne)),
                    7
                )

                local afterTwo = (
                    SaveSchema.withChapterResolution(
                        afterOne,
                        "chapter_two",
                        "chapter_2:run:hash:7",
                        "vent_stope",
                        "cleared",
                        200
                    )
                )
                TestRunner.equal(SaveSchema.chapterProgress(afterTwo), 3)
                TestRunner.equal(
                    #ResidentRoster.idsForChapter(SaveSchema.chapterProgress(afterTwo)),
                    11
                )
            end,
        },
        {
            -- Records must survive a save round trip, and forged ones must
            -- not: an unknown chapter, a decision that chapter never offers,
            -- or a missing transaction id all drop on normalize.
            name = "chapter records survive normalize, and forged ones do not",
            run = function()
                local profile = resolvedChapterOne(SaveSchema.default(1000))
                local resolved = (
                    SaveSchema.withChapterResolution(
                        profile,
                        "chapter_two",
                        "chapter_2:run:hash:7",
                        "vent_both",
                        "mixed",
                        200
                    )
                )
                local round = SaveSchema.normalize(resolved)
                TestRunner.equal(round.story.chapters.chapter_two.outcome, "mixed")
                TestRunner.equal(round.story.chapters.chapter_two.decision, "vent_both")

                local forged = SaveSchema.normalize({
                    schemaVersion = 20,
                    story = {
                        chapters = {
                            chapter_two = {
                                completedAt = 5,
                                decision = "restore_farmland",
                                outcome = "cleared",
                                status = "complete",
                                transactionId = "forged",
                            },
                            chapter_nine = {
                                completedAt = 5,
                                decision = "vent_stope",
                                outcome = "cleared",
                                status = "complete",
                                transactionId = "forged",
                            },
                            chapter_three = {
                                completedAt = 5,
                                decision = "spared_copies",
                                outcome = "sealed",
                                status = "complete",
                                transactionId = "",
                            },
                        },
                    },
                })
                TestRunner.equal(forged.story.chapters.chapter_two, nil)
                TestRunner.equal(forged.story.chapters.chapter_nine, nil)
                TestRunner.equal(forged.story.chapters.chapter_three, nil)
                TestRunner.equal(SaveSchema.chapterProgress(forged), 1)
            end,
        },
    },
}
