--!strict

local RegionAccess = require("../../src/shared/RegionAccess")
local Regions = require("../../src/shared/Content/Definitions/Regions")
local TestRunner = require("../TestRunner")

local RESOLVED_ONE = {
    chapterOne = {
        status = "complete",
        decision = "shared_agroforest",
        wardenOutcome = "preserved",
    },
}

return {
    name = "RegionAccess",
    cases = {
        {
            --[[
                The Delve is open, and only behind its chapter: a fresh
                profile still resolves everywhere to Bramblewake, a
                resolved chapter one earns Ironroot, and every region past
                it still refuses as unbuilt. This case pinned "exactly
                one region" until the Delve was walked end to end in a
                live session; it pins the new truth now.
            ]]
            name = "the Delve, the Fen, the Reach and the Vale open behind their chapters and the rest stay shut",
            run = function()
                TestRunner.equal(RegionAccess.evaluate("region_bramblewake", nil).allowed, true)
                local delveEarly = RegionAccess.evaluate("region_ironroot", nil)
                TestRunner.equal(delveEarly.allowed, false)
                TestRunner.equal(delveEarly.reason, "chapter_not_reached")
                local delve = RegionAccess.evaluate("region_ironroot", RESOLVED_ONE)
                TestRunner.equal(delve.allowed, true)
                local fenEarly = RegionAccess.evaluate("region_mireglass", RESOLVED_ONE)
                TestRunner.equal(fenEarly.allowed, false)
                TestRunner.equal(fenEarly.reason, "chapter_not_reached")
                local throughTwo = {
                    chapterOne = RESOLVED_ONE.chapterOne,
                    chapters = {
                        chapter_two = { status = "complete", outcome = "cleared" },
                    },
                }
                local fen = RegionAccess.evaluate("region_mireglass", throughTwo)
                TestRunner.equal(fen.allowed, true)
                -- The Reach is open now, so a profile short of chapter III
                -- is refused for the chapter rather than for the build.
                local reachEarly = RegionAccess.evaluate("region_tempest", throughTwo)
                TestRunner.equal(reachEarly.allowed, false)
                TestRunner.equal(reachEarly.reason, "chapter_not_reached")
                local throughThree = {
                    chapterOne = RESOLVED_ONE.chapterOne,
                    chapters = {
                        chapter_three = { status = "complete", outcome = "bound" },
                        chapter_two = { status = "complete", outcome = "cleared" },
                    },
                }
                local reach = RegionAccess.evaluate("region_tempest", throughThree)
                TestRunner.equal(reach.allowed, true)
                -- The Vale is open now, so a profile short of chapter IV
                -- is refused for the chapter rather than for the build.
                local valeEarly = RegionAccess.evaluate("region_frostmere", throughThree)
                TestRunner.equal(valeEarly.allowed, false)
                TestRunner.equal(valeEarly.reason, "chapter_not_reached")
                local throughFour = {
                    chapterOne = RESOLVED_ONE.chapterOne,
                    chapters = {
                        chapter_four = { status = "complete", outcome = "scoured" },
                        chapter_three = { status = "complete", outcome = "bound" },
                        chapter_two = { status = "complete", outcome = "cleared" },
                    },
                }
                local vale = RegionAccess.evaluate("region_frostmere", throughFour)
                TestRunner.equal(vale.allowed, true)
                local crown = RegionAccess.evaluate("region_cinderfall", throughFour)
                TestRunner.equal(crown.allowed, false)
                TestRunner.equal(crown.reason, "region_not_built")
                local nowhere = RegionAccess.evaluate("region_nowhere", nil)
                TestRunner.equal(nowhere.reason, "region_unknown")

                local open = RegionAccess.available(throughFour)
                TestRunner.equal(#open, 5)
                TestRunner.equal(open[1], "region_bramblewake")
                TestRunner.equal(open[2], "region_ironroot")
                TestRunner.equal(open[3], "region_mireglass")
                TestRunner.equal(open[4], "region_tempest")
                TestRunner.equal(open[5], "region_frostmere")

                TestRunner.equal(
                    RegionAccess.destinationFor("region_ironroot", RESOLVED_ONE),
                    "region_ironroot"
                )
                TestRunner.equal(
                    RegionAccess.destinationFor("region_ironroot", nil),
                    "region_bramblewake"
                )
                TestRunner.equal(RegionAccess.destinationFor(nil, nil), "region_bramblewake")
                TestRunner.equal(RegionAccess.destinationFor(42, nil), "region_bramblewake")
                TestRunner.equal(
                    RegionAccess.destinationFor("region_bramblewake", nil),
                    "region_bramblewake"
                )
            end,
        },
        {
            -- The chapter gate is already waiting behind the enabled flag:
            -- the Delve's chapter is reachable only once the Warden is
            -- resolved, the Fen's only once the Maw is. When a builder
            -- lands, flipping `enabled` must be the whole switch.
            name = "the chapter gate stands ready behind each region's flag",
            run = function()
                TestRunner.equal(RegionAccess.chapterReached(nil, "region_bramblewake"), true)
                TestRunner.equal(RegionAccess.chapterReached(nil, "region_ironroot"), false)
                TestRunner.equal(RegionAccess.chapterReached(RESOLVED_ONE, "region_ironroot"), true)
                TestRunner.equal(
                    RegionAccess.chapterReached(RESOLVED_ONE, "region_mireglass"),
                    false
                )
                local both = {
                    chapterOne = RESOLVED_ONE.chapterOne,
                    chapters = {
                        chapter_two = { status = "complete", outcome = "cleared" },
                    },
                }
                TestRunner.equal(RegionAccess.chapterReached(both, "region_mireglass"), true)
                -- and the chain keeps going: the Reach waits on the Fen's
                -- chapter, the Vale on the Reach's. Before chapters IV and
                -- V existed these two answered only to their flags, which
                -- would have opened them to anyone the day a flag flipped.
                TestRunner.equal(RegionAccess.chapterReached(both, "region_tempest"), false)
                local throughThree = {
                    chapterOne = RESOLVED_ONE.chapterOne,
                    chapters = {
                        chapter_three = { status = "complete", outcome = "sealed" },
                        chapter_two = { status = "complete", outcome = "cleared" },
                    },
                }
                TestRunner.equal(RegionAccess.chapterReached(throughThree, "region_tempest"), true)
                TestRunner.equal(
                    RegionAccess.chapterReached(throughThree, "region_frostmere"),
                    false
                )
                local throughFour = {
                    chapterOne = RESOLVED_ONE.chapterOne,
                    chapters = {
                        chapter_four = { status = "complete", outcome = "navigable" },
                        chapter_three = { status = "complete", outcome = "sealed" },
                        chapter_two = { status = "complete", outcome = "cleared" },
                    },
                }
                TestRunner.equal(RegionAccess.chapterReached(throughFour, "region_frostmere"), true)
                -- and the chain now runs to the bottom of it: the Crown
                -- behind the Vale's chapter, the Hollow behind the Crown's.
                -- Nothing in this game is reachable by flag alone any more.
                TestRunner.equal(
                    RegionAccess.chapterReached(throughFour, "region_cinderfall"),
                    false
                )
                local throughSix = {
                    chapterOne = RESOLVED_ONE.chapterOne,
                    chapters = {
                        chapter_six = { status = "complete", outcome = "remembered" },
                        chapter_five = { status = "complete", outcome = "sheltered" },
                        chapter_four = { status = "complete", outcome = "navigable" },
                        chapter_three = { status = "complete", outcome = "sealed" },
                        chapter_two = { status = "complete", outcome = "cleared" },
                    },
                }
                TestRunner.equal(RegionAccess.chapterReached(throughSix, "region_hollow"), true)
                TestRunner.equal(RegionAccess.chapterReached(nil, "region_hollow"), false)
            end,
        },
        {
            --[[
                The registry stays coherent, and the enabled set is pinned
                by name rather than by count: a region joins this list in
                the same pull request as the live walk that earned it, and
                a flag flipped without that walk fails here.
            ]]
            name = "the region registry is coherent and its open set is pinned",
            run = function()
                local byId: { [string]: any } = {}
                for _, region in Regions do
                    byId[region.id] = region
                end
                local expectedEnabled: { [string]: boolean } = {
                    region_bramblewake = true,
                    region_ironroot = true,
                    region_mireglass = true,
                    region_tempest = true,
                    region_frostmere = true,
                }
                for _, region in Regions do
                    TestRunner.equal(
                        region.enabled == true,
                        expectedEnabled[region.id] == true,
                        region.id .. " enabled flag does not match the pinned open set"
                    )
                    for _, dependencyId in region.dependencies do
                        TestRunner.truthy(
                            byId[dependencyId] ~= nil,
                            region.id .. " depends on unknown " .. tostring(dependencyId)
                        )
                    end
                end
                TestRunner.equal(RegionAccess.DefaultRegionId, "region_bramblewake")
            end,
        },
        {
            --[[
                The third gate: a region can be enabled and its chapter
                reached and still have nothing a party could walk. The
                Delve and the Fen are exactly there today -- module
                geometry and no points of interest, events, nodes or
                arenas -- and the gate exists so that flipping an enabled
                flag early cannot put anyone in an empty grid.
            ]]
            name = "a region with no walkable world is refused even when it is enabled",
            run = function()
                RegionAccess.setReadinessProvider(function(regionId: string): boolean
                    return regionId == "region_bramblewake"
                end)
                TestRunner.equal(RegionAccess.evaluate("region_bramblewake", nil).allowed, true)
                -- pretend the Delve's flag was flipped: chapter reached,
                -- registry enabled, and still refused for the honest reason
                local verdict = RegionAccess.evaluate("region_ironroot", RESOLVED_ONE)
                TestRunner.equal(verdict.allowed, false)
                TestRunner.truthy(
                    verdict.reason == "region_not_built" or verdict.reason == "region_not_walkable"
                )
                -- and with no provider at all, behavior is what it was
                -- before readiness existed
                RegionAccess.setReadinessProvider(nil)
                TestRunner.equal(RegionAccess.evaluate("region_bramblewake", nil).allowed, true)
            end,
        },
    },
}
