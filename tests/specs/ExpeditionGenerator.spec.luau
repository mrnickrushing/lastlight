--!strict

local Catalog = require("../../src/shared/Content/Definitions/BramblewakeExpedition")
local ExpeditionGenerator = require("../../src/shared/ExpeditionGenerator")
local TestRunner = require("../TestRunner")

return {
    name = "ExpeditionGenerator",
    cases = {
        {
            -- Every point of interest is tagged story, mystery or sanctuary and
            -- all four shipped with nothing to say, so each shared one generic
            -- line. A landmark that says the same thing as the road it stands
            -- on is indistinguishable from no landmark at all.
            name = "every point of interest says something specific to itself",
            run = function()
                local seen: { [string]: boolean } = {}
                for _, poi in Catalog.PointsOfInterest do
                    TestRunner.truthy(
                        type(poi.detail) == "string" and #poi.detail > 24,
                        "point of interest has nothing to say: " .. tostring(poi.id)
                    )
                    TestRunner.truthy(not seen[poi.detail], "duplicate line: " .. poi.id)
                    seen[poi.detail] = true
                end
                TestRunner.equal(#Catalog.PointsOfInterest, Catalog.PointOfInterestCount)
            end,
        },
        {
            name = "passes 1,000 deterministic Bramblewake seeds",
            run = function()
                local hashes: { [string]: boolean } = {}
                for seed = 1, 1000 do
                    local manifest = ExpeditionGenerator.generate(seed)
                    local valid, issues = ExpeditionGenerator.validate(manifest)
                    TestRunner.truthy(valid, table.concat(issues, "; "))
                    TestRunner.equal(manifest.hash, ExpeditionGenerator.generate(seed).hash)
                    TestRunner.equal(#manifest.modules, 12)
                    hashes[manifest.hash] = true
                end

                local uniqueHashes = 0
                for _ in hashes do
                    uniqueHashes += 1
                end
                TestRunner.truthy(uniqueHashes >= 100, "seeded assembly lacks route variety")
            end,
        },
        {
            name = "uses a valid known-good authored fallback",
            run = function()
                local fallback = ExpeditionGenerator.generate(1847, true)
                local valid, issues = ExpeditionGenerator.validate(fallback)
                TestRunner.truthy(valid, table.concat(issues, "; "))
                TestRunner.equal(fallback.source, "known_good_fallback")
                TestRunner.equal(fallback.modules[1].moduleId, "module_bw_lantern_gate")
                TestRunner.equal(fallback.modules[12].moduleId, "module_bw_wayhome_gate")
            end,
        },
        {
            name = "replays normalized negative seeds from the recorded seed",
            run = function()
                local manifest = ExpeditionGenerator.generate(-41290)
                local replay = ExpeditionGenerator.generate(manifest.seed)
                TestRunner.equal(manifest.seed, 41290)
                TestRunner.equal(replay.hash, manifest.hash)
            end,
        },
        {
            name = "rejects a disconnected critical path even with a matching hash",
            run = function()
                local manifest = ExpeditionGenerator.generate(22)
                manifest.modules[6].cellX += 4
                manifest.hash = ExpeditionGenerator.computeHash(manifest)

                local valid, issues = ExpeditionGenerator.validate(manifest)
                TestRunner.equal(valid, false)
                TestRunner.truthy(
                    string.find(table.concat(issues, "; "), "disconnected", 1, true),
                    "expected a connectivity failure"
                )
            end,
        },
        {
            name = "binds four stable story vignettes to authored modules",
            run = function()
                local expected = {
                    module_bw_sunken_orchard = "last_harvest",
                    module_bw_hollow_farm = "evacuation_cart",
                    module_bw_windmill_copse = "last_repair",
                    module_bw_tangle_bridge = "lost_crossing",
                }
                for moduleId, landmark in expected do
                    local definition = ExpeditionGenerator.moduleDefinition(moduleId)
                    TestRunner.equal(definition.storyLandmark, landmark)
                    TestRunner.truthy(type(definition.storyTitle) == "string")
                    TestRunner.truthy(type(definition.storyOffset.x) == "number")
                    TestRunner.truthy(type(definition.storyOffset.z) == "number")
                    TestRunner.truthy(definition.storyPartCount > 0)
                end
            end,
        },
        {
            name = "requires the authored Old Growth arena module",
            run = function()
                local manifest = ExpeditionGenerator.generate(93)
                local oldGrowthIndex: number? = nil
                for index, placement in manifest.modules do
                    if placement.moduleId == "module_bw_old_growth_approach" then
                        oldGrowthIndex = index
                        break
                    end
                end
                TestRunner.truthy(oldGrowthIndex ~= nil, "generated route lost Old Growth")
                manifest.modules[oldGrowthIndex :: number].moduleId = "module_bw_briar_ring"
                manifest.hash = ExpeditionGenerator.computeHash(manifest)

                local valid, issues = ExpeditionGenerator.validate(manifest)
                TestRunner.equal(valid, false)
                TestRunner.truthy(
                    string.find(
                        table.concat(issues, "; "),
                        "missing required module module_bw_old_growth_approach",
                        1,
                        true
                    ),
                    "expected a missing required-module failure"
                )
            end,
        },
    },
}
