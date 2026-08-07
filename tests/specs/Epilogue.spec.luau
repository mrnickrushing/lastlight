--!strict

local ChapterCatalog = require("../../src/shared/ChapterCatalog")
local Config = require("../../src/shared/Config")
local Epilogue = require("../../src/shared/Epilogue")
local HollowFinale = require("../../src/shared/Content/Definitions/HollowFinale")
local NamelessNight = require("../../src/shared/NamelessNightEncounter")
local SaveSchema = require("../../src/shared/SaveSchema")
local TestRunner = require("../TestRunner")

local function resolvedThroughSix(profile: any): any
    profile = (
        SaveSchema.withChapterOneResolution(
            profile,
            "chapter_1:epilogue:hash:7",
            "shared_agroforest",
            "preserved",
            100
        )
    )
    local chapters = {
        { "chapter_two", "vent_stope", "cleared" },
        { "chapter_three", "spared_copies", "sealed" },
        { "chapter_four", "eased_gates", "navigable" },
        { "chapter_five", "warmed_den", "sheltered" },
        { "chapter_six", "spared_memories", "remembered" },
    }
    for index, entry in chapters do
        profile = (
            SaveSchema.withChapterResolution(
                profile,
                entry[1],
                string.format("%s:epilogue:hash:7", entry[1]),
                entry[2],
                entry[3],
                100 + index
            )
        )
    end
    return profile
end

return {
    name = "Epilogue",
    cases = {
        {
            --[[
                A new outcome shipping without a line is the failure this
                exists to catch: the chapter would resolve, the epilogue
                would silently skip it, and nobody would notice until a
                player finished the game and read a paragraph with a hole
                in it. So the catalog is walked rather than a list kept
                beside the lines.
            ]]
            name = "every outcome any chapter can record has something to say about it",
            run = function()
                for _, definition in ChapterCatalog.list() do
                    local lines = Epilogue.OutcomeLines[definition.id]
                    TestRunner.truthy(lines ~= nil, definition.id .. " has no epilogue lines")
                    for _, outcome in definition.outcomes do
                        local line = (lines :: any)[outcome]
                        TestRunner.truthy(
                            type(line) == "string" and #line > 24,
                            definition.id .. "/" .. outcome .. " has no epilogue line"
                        )
                    end
                end
                -- and every ending the Hollow offers is one this knows
                for _, ending in HollowFinale.Endings do
                    TestRunner.equal(
                        Epilogue.knowsEnding(ending.id),
                        true,
                        ending.id .. " has no epilogue"
                    )
                end
                TestRunner.equal(Epilogue.knowsEnding("ending_nothing"), false)
                -- the outcome each ending produces is chapter seven's, and
                -- SaveSchema writes the same mapping
                for endingId, outcome in Epilogue.EndingOutcomes do
                    TestRunner.equal(
                        ChapterCatalog.isOutcome("chapter_seven", outcome),
                        true,
                        endingId .. " produces an outcome chapter seven cannot store"
                    )
                    TestRunner.equal(ChapterCatalog.isDecision("chapter_seven", endingId), true)
                end
            end,
        },
        {
            -- A player can reach the seat without having closed a chapter
            -- behind them, and the game must not go blank at them.
            name = "a story that resolved nothing still gets an epilogue",
            run = function()
                local fresh = SaveSchema.default(1000)
                local resolution = Epilogue.resolve(fresh.story)
                TestRunner.equal(resolution.ending, nil)
                TestRunner.equal(resolution.title, "THE STORY SO FAR")
                TestRunner.equal(resolution.townState, "emberhollow_lit")
                TestRunner.equal(#resolution.lines, 1)
                TestRunner.truthy(#resolution.lines[1] > 24)
                -- and nothing breaks on a story that is not a table at all
                TestRunner.equal(Epilogue.resolve(nil).title, "THE STORY SO FAR")
                TestRunner.equal(Epilogue.resolve(42).ending, nil)
            end,
        },
        {
            --[[
                Every combination: seven chapters' outcomes crossed with
                three endings is more text than anyone will read, but the
                failure it guards against is real -- one unlucky pairing
                producing an empty epilogue at the end of a forty-hour
                save.
            ]]
            name = "every chapter outcome pairs with every ending",
            run = function()
                local seen = 0
                for _, definition in ChapterCatalog.list() do
                    if definition.id ~= "chapter_seven" then
                        for _, outcome in definition.outcomes do
                            for _, endingId in NamelessNight.EndingIds do
                                local story: any = {
                                    chapterOne = {
                                        status = "complete",
                                        wardenOutcome = if definition.id == "chapter_one"
                                            then outcome
                                            else "preserved",
                                    },
                                    chapters = {},
                                    finale = {
                                        abandonedPost = "post_gate",
                                        completedAt = 500,
                                        ending = endingId,
                                        leftBehind = "npc_ivy_thorn",
                                        light = 1,
                                        rescued = "npc_pip_wren",
                                        status = "complete",
                                        transactionId = "finale:combo",
                                    },
                                }
                                if definition.id ~= "chapter_one" then
                                    story.chapters[definition.id] = {
                                        outcome = outcome,
                                        status = "complete",
                                    }
                                end
                                local resolution = Epilogue.resolve(story)
                                TestRunner.equal(resolution.ending, endingId)
                                TestRunner.equal(resolution.title, Epilogue.EndingTitles[endingId])
                                TestRunner.truthy(
                                    #resolution.lines >= 3,
                                    definition.id
                                        .. "/"
                                        .. outcome
                                        .. "/"
                                        .. endingId
                                        .. " produced a thin epilogue"
                                )
                                for _, line in resolution.lines do
                                    TestRunner.truthy(#line > 20, "an epilogue line is empty")
                                end
                                seen += 1
                            end
                        end
                    end
                end
                TestRunner.truthy(seen >= 54, "not every combination was walked")
            end,
        },
        {
            -- What happened in the Hollow's scenes is in the epilogue too,
            -- which is the whole reason those decisions are made with the
            -- hands rather than in a menu.
            name = "the epilogue remembers the post and the person, not only the ending",
            run = function()
                local profile = resolvedThroughSix(SaveSchema.default(1000))
                local record = {
                    abandonedPost = "post_hearth",
                    ending = "ending_shared",
                    leftBehind = "npc_ivy_thorn",
                    light = 2,
                    rescued = "npc_pip_wren",
                }
                local resolved, result =
                    SaveSchema.withFinaleResolution(profile, "finale:run:hash", record, 900)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(resolved.story.finale.status, "complete")
                -- and chapter seven closed with it, so everything that reads
                -- chapters sees the story end without learning a new thing
                TestRunner.equal(resolved.story.chapters.chapter_seven.status, "complete")
                TestRunner.equal(resolved.story.chapters.chapter_seven.outcome, "lantern_shared")
                TestRunner.equal(resolved.story.chapters.chapter_seven.decision, "ending_shared")

                local resolution = Epilogue.resolve(resolved.story)
                TestRunner.equal(resolution.ending, "ending_shared")
                TestRunner.equal(resolution.townState, "emberhollow_scattered")
                local hearth, people = false, false
                for _, line in resolution.lines do
                    if string.find(line, "hearth", 1, true) ~= nil then
                        hearth = true
                    end
                    if string.find(line, "PIP", 1, true) ~= nil then
                        people = true
                    end
                end
                TestRunner.truthy(hearth, "the abandoned post is not in the epilogue")
                TestRunner.truthy(people, "who came back up is not in the epilogue")

                -- a party that carried nobody out reads differently
                local passed = resolvedThroughSix(SaveSchema.default(1000))
                passed = (
                    SaveSchema.withFinaleResolution(
                        passed,
                        "finale:other:hash",
                        { abandonedPost = "post_gate", ending = "ending_kept", light = 0 },
                        900
                    )
                )
                local alone = Epilogue.resolve(passed.story)
                local nobody = false
                for _, line in alone.lines do
                    if string.find(line, "Nobody came back up", 1, true) ~= nil then
                        nobody = true
                    end
                end
                TestRunner.truthy(nobody, "refusing to choose left no trace")
            end,
        },
        {
            -- The same idempotency contract every chapter has, on the one
            -- record where a replay would be most tempting.
            name = "the finale resolves once, and a repeat is a duplicate rather than an error",
            run = function()
                local profile = resolvedThroughSix(SaveSchema.default(1000))
                local record = { abandonedPost = "post_road", ending = "ending_ended", light = 3 }
                local resolved = (
                    SaveSchema.withFinaleResolution(profile, "finale:once", record, 900)
                )
                local again, repeated =
                    SaveSchema.withFinaleResolution(resolved, "finale:once", record, 901)
                TestRunner.equal(repeated.applied, false)
                TestRunner.equal(repeated.duplicate, true)
                TestRunner.equal(again.story.finale.ending, "ending_ended")

                local rival, refused = SaveSchema.withFinaleResolution(
                    resolved,
                    "finale:rival",
                    { abandonedPost = "post_gate", ending = "ending_kept", light = 5 },
                    902
                )
                TestRunner.equal(refused.applied, false)
                TestRunner.equal(refused.duplicate, false)
                TestRunner.equal(rival.story.finale.ending, "ending_ended")

                -- and it cannot be recorded before the Crown is closed
                local early = SaveSchema.default(1000)
                local _, locked =
                    SaveSchema.withFinaleResolution(early, "finale:early", record, 903)
                TestRunner.equal(locked.applied, false)
                TestRunner.equal(locked.reason, "chapter_locked")
            end,
        },
        {
            -- The record has to survive a round trip, and a forged one has
            -- to be refused the same way a forged chapter is.
            name = "a finale record persists, and a forged one does not",
            run = function()
                TestRunner.equal(Config.SaveSchemaVersion, 21)
                local profile = resolvedThroughSix(SaveSchema.default(1000))
                profile = (
                    SaveSchema.withFinaleResolution(profile, "finale:round:trip", {
                        abandonedPost = "post_gate",
                        ending = "ending_kept",
                        leftBehind = "npc_pip_wren",
                        light = 4,
                        rescued = "npc_ivy_thorn",
                    }, 900)
                )
                local round = SaveSchema.normalize(profile, 1000)
                TestRunner.equal(round.story.finale.ending, "ending_kept")
                TestRunner.equal(round.story.finale.abandonedPost, "post_gate")
                TestRunner.equal(round.story.finale.rescued, "npc_ivy_thorn")
                TestRunner.equal(round.story.finale.light, 4)

                local forged = SaveSchema.normalize({
                    schemaVersion = 21,
                    story = {
                        finale = {
                            abandonedPost = "post_nowhere",
                            completedAt = 5,
                            ending = "ending_everything",
                            leftBehind = "npc_nobody",
                            light = 999,
                            rescued = "npc_nobody",
                            status = "complete",
                            transactionId = "forged",
                        },
                    },
                }, 1000)
                TestRunner.equal(forged.story.finale.status, "unresolved")
                TestRunner.equal(forged.story.finale.ending, nil)
                TestRunner.equal(forged.story.finale.light, NamelessNight.StartingLight)

                -- a real ending with a made-up post keeps the ending and
                -- drops the post, because a save that forgot which post
                -- fell should still remember how the story ended
                local partial = SaveSchema.normalize({
                    schemaVersion = 21,
                    story = {
                        finale = {
                            abandonedPost = "post_nowhere",
                            completedAt = 5,
                            ending = "ending_shared",
                            light = 2,
                            rescued = "npc_nobody",
                            status = "complete",
                            transactionId = "real",
                        },
                    },
                }, 1000)
                TestRunner.equal(partial.story.finale.status, "complete")
                TestRunner.equal(partial.story.finale.ending, "ending_shared")
                TestRunner.equal(partial.story.finale.abandonedPost, nil)
                TestRunner.equal(partial.story.finale.rescued, nil)
            end,
        },
    },
}
