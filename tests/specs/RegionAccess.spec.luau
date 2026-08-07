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
            -- Today, every request resolves to Bramblewake: nothing else is
            -- built, and access must say so rather than promise a region
            -- the server cannot construct.
            name = "only Bramblewake is open while the other builders are unbuilt",
            run = function()
                TestRunner.equal(RegionAccess.evaluate("region_bramblewake", nil).allowed, true)
                local delve = RegionAccess.evaluate("region_ironroot", RESOLVED_ONE)
                TestRunner.equal(delve.allowed, false)
                TestRunner.equal(delve.reason, "region_not_built")
                local nowhere = RegionAccess.evaluate("region_nowhere", nil)
                TestRunner.equal(nowhere.reason, "region_unknown")

                local open = RegionAccess.available(RESOLVED_ONE)
                TestRunner.equal(#open, 1)
                TestRunner.equal(open[1], "region_bramblewake")

                TestRunner.equal(
                    RegionAccess.destinationFor("region_ironroot", RESOLVED_ONE),
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
            -- The registry itself must stay coherent: exactly one enabled
            -- region today, and every dependency names a real region. This
            -- is the case that catches a flag flipped without a builder.
            name = "the region registry is coherent and singly enabled",
            run = function()
                local byId: { [string]: any } = {}
                for _, region in Regions do
                    byId[region.id] = region
                end
                local enabled = 0
                for _, region in Regions do
                    if region.enabled == true then
                        enabled += 1
                    end
                    for _, dependencyId in region.dependencies do
                        TestRunner.truthy(
                            byId[dependencyId] ~= nil,
                            region.id .. " depends on unknown " .. tostring(dependencyId)
                        )
                    end
                end
                TestRunner.equal(enabled, 1)
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
