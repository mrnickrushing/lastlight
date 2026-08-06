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
                -- a region with no chapter of its own answers only to its flag
                TestRunner.equal(RegionAccess.chapterReached(nil, "region_tempest"), true)
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
    },
}
