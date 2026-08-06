--!strict

local Bramblewake = require("../../src/shared/Content/Definitions/BramblewakeExpedition")
local ExpeditionEventFlow = require("../../src/shared/ExpeditionEventFlow")
local ExpeditionGenerator = require("../../src/shared/ExpeditionGenerator")
local ExpeditionInventory = require("../../src/shared/ExpeditionInventory")
local Mireglass = require("../../src/shared/Content/Definitions/MireglassExpedition")
local TestRunner = require("../TestRunner")

local MIREGLASS = "region_mireglass"

return {
    name = "MireglassExpedition",
    cases = {
        {
            -- The roadmap's content counts for a region production wave.
            name = "the Fen declares a full region's worth of content",
            run = function()
                TestRunner.equal(#Mireglass.Modules, 30)
                TestRunner.equal(#Mireglass.PointsOfInterest, 12)
                TestRunner.equal(#Mireglass.Events, 8)
                TestRunner.equal(Mireglass.RegionId, MIREGLASS)
                -- exactly one arrival and one extraction, or a walk cannot
                -- start and end where the validator insists it must
                local roles: { [string]: number } = {}
                for _, definition in Mireglass.Modules do
                    roles[definition.role] = (roles[definition.role] or 0) + 1
                end
                TestRunner.equal(roles.arrival, 1)
                TestRunner.equal(roles.extraction, 1)
            end,
        },
        {
            -- "No region is a reskin" is the milestone's own exit gate. Ids,
            -- visuals and POI lines must not be Bramblewake's wearing a hat.
            name = "no content is shared with the earlier regions",
            run = function()
                local Ironroot = require("../../src/shared/Content/Definitions/IronrootExpedition")
                local bramblewakeVisuals: { [string]: boolean } = {}
                local bramblewakeIds: { [string]: boolean } = {}
                for _, group in
                    {
                        Bramblewake.Modules,
                        Bramblewake.PointsOfInterest,
                        Ironroot.Modules,
                        Ironroot.PointsOfInterest,
                    }
                do
                    for _, definition in group do
                        bramblewakeIds[definition.id] = true
                        bramblewakeVisuals[definition.visual] = true
                    end
                end
                for _, group in { Mireglass.Modules, Mireglass.PointsOfInterest } do
                    for _, definition in group do
                        TestRunner.equal(bramblewakeIds[definition.id], nil)
                        TestRunner.equal(
                            bramblewakeVisuals[definition.visual],
                            nil,
                            "reskinned visual: " .. definition.id
                        )
                    end
                end
            end,
        },
        {
            name = "every point of interest says something specific to itself",
            run = function()
                local seen: { [string]: boolean } = {}
                for _, poi in Mireglass.PointsOfInterest do
                    TestRunner.truthy(
                        type(poi.detail) == "string" and #poi.detail > 24,
                        "point of interest has nothing to say: " .. tostring(poi.id)
                    )
                    TestRunner.truthy(not seen[poi.detail], "duplicate line: " .. poi.id)
                    seen[poi.detail] = true
                end
            end,
        },
        {
            -- The #212 lesson: a reward the ledger will not accept pays out
            -- nothing, silently. Every Fen reward must clear the allow-list.
            name = "every event contract holds and pays a material the ledger knows",
            run = function()
                for _, event in Mireglass.Events do
                    local valid, issues = ExpeditionEventFlow.validateDefinition(event)
                    TestRunner.truthy(
                        valid,
                        string.format("%s: %s", event.id, table.concat(issues, "; "))
                    )
                    TestRunner.truthy(event.reward ~= nil, event.id .. " pays nothing")
                    local _, result = ExpeditionInventory.addUnbanked(
                        ExpeditionInventory.default(),
                        "spec:" .. event.id,
                        "spechash",
                        { materialId = event.reward.materialId, amount = event.reward.amount },
                        1000
                    )
                    TestRunner.truthy(
                        result.applied,
                        event.id
                            .. " pays a material the ledger refuses: "
                            .. event.reward.materialId
                    )
                end
            end,
        },
        {
            name = "the known-good fallback walk is valid and deterministic",
            run = function()
                local fallback = ExpeditionGenerator.generate(1847, true, nil, MIREGLASS)
                local valid, issues = ExpeditionGenerator.validate(fallback)
                TestRunner.truthy(valid, table.concat(issues, "; "))
                TestRunner.equal(fallback.regionId, MIREGLASS)
                TestRunner.equal(fallback.source, "known_good_fallback")
                TestRunner.equal(#fallback.modules, Mireglass.ModuleCount)
                local replay = ExpeditionGenerator.generate(1847, true, nil, MIREGLASS)
                TestRunner.equal(replay.hash, fallback.hash)
            end,
        },
        {
            -- The same invariant sweep Bramblewake passes, on the Fen's pool.
            name = "passes 2,000 deterministic Fen seeds",
            run = function()
                local hashes: { [string]: boolean } = {}
                for seed = 1, 2000 do
                    local manifest = ExpeditionGenerator.generate(seed, false, nil, MIREGLASS)
                    local valid, issues = ExpeditionGenerator.validate(manifest)
                    TestRunner.truthy(
                        valid,
                        string.format("seed %d: %s", seed, table.concat(issues, "; "))
                    )
                    TestRunner.equal(manifest.regionId, MIREGLASS)
                    TestRunner.equal(#manifest.modules, Mireglass.ModuleCount)
                    hashes[manifest.hash] = true
                end
                local distinct = 0
                for _ in hashes do
                    distinct += 1
                end
                TestRunner.truthy(distinct > 100, "the Fen repeats itself")
            end,
        },
        {
            -- Region isolation: a Fen manifest may never carry forest
            -- content, and the default region must still be Bramblewake so
            -- every caller that names no region keeps its old behavior.
            name = "regions do not leak into each other",
            run = function()
                local manifest = ExpeditionGenerator.generate(77, false, nil, MIREGLASS)
                for _, placement in manifest.modules do
                    TestRunner.equal(string.sub(placement.moduleId, 1, 10), "module_mg_")
                    if placement.poiId ~= nil then
                        TestRunner.equal(string.sub(placement.poiId, 1, 7), "poi_mg_")
                    end
                    if placement.eventId ~= nil then
                        TestRunner.equal(string.sub(placement.eventId, 1, 9), "event_mg_")
                    end
                end
                TestRunner.equal(ExpeditionGenerator.generate(77).regionId, Bramblewake.RegionId)
                -- an unknown region falls back rather than erroring, and a
                -- manifest naming no known region is refused outright
                TestRunner.equal(
                    ExpeditionGenerator.generate(5, false, nil, "region_nowhere").regionId,
                    Bramblewake.RegionId
                )
                local valid = ExpeditionGenerator.validate({
                    regionId = "region_nowhere",
                    modules = {},
                })
                TestRunner.equal(valid, false)
            end,
        },
    },
}
