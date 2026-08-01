--!strict

local MeshAssetRegistry = require("../../src/server/World/MeshAssetRegistry")
local TestRunner = require("../TestRunner")

return {
    name = "MeshAssetRegistry",
    cases = {
        {
            name = "keeps stable and unique uploaded asset mappings",
            run = function()
                local entries = MeshAssetRegistry.all()
                TestRunner.equal(#entries, 12)
                local stableIds = {}
                local robloxIds = {}
                for _, entry in entries do
                    TestRunner.truthy(entry.targetLongestDimension > 0)
                    TestRunner.truthy(entry.maxTriangles > 0)
                    TestRunner.truthy(entry.maxMaterialSlots > 0)
                    TestRunner.truthy(not stableIds[entry.id], "duplicate stable ID")
                    TestRunner.truthy(not robloxIds[entry.assetId], "duplicate Roblox asset ID")
                    stableIds[entry.id] = true
                    robloxIds[entry.assetId] = true
                end
            end,
        },
        {
            name = "derives scale from measured imported bounds",
            run = function()
                TestRunner.equal(MeshAssetRegistry.scaleFor("mesh_root_arch_a", 10), 2.5)
                TestRunner.equal(MeshAssetRegistry.scaleFor("missing", 10), nil)
                TestRunner.equal(MeshAssetRegistry.scaleFor("mesh_root_arch_a", 0), nil)
            end,
        },
        {
            name = "marks only the texture-authored landmark as custom PBR",
            run = function()
                local rootArch = MeshAssetRegistry.get("mesh_root_arch_a")
                TestRunner.truthy(rootArch ~= nil)
                TestRunner.equal((rootArch :: MeshAssetRegistry.Entry).pbr, true)
                local conifer = MeshAssetRegistry.get("mesh_conifer_hero_a")
                TestRunner.truthy(conifer ~= nil)
                TestRunner.equal((conifer :: MeshAssetRegistry.Entry).pbr, false)
            end,
        },
        {
            name = "keeps the arrival shrine curated and measured",
            run = function()
                local shrine = MeshAssetRegistry.get("mesh_hollow_lantern_shrine_a")
                TestRunner.truthy(shrine ~= nil)
                TestRunner.equal((shrine :: MeshAssetRegistry.Entry).targetLongestDimension, 28)
                TestRunner.equal((shrine :: MeshAssetRegistry.Entry).placementBand, "curated_core")
                TestRunner.equal((shrine :: MeshAssetRegistry.Entry).pbr, false)
            end,
        },
        {
            name = "retires the failed cabin mesh while keeping the lantern curated",
            run = function()
                local cabin = MeshAssetRegistry.get("mesh_wayfarer_cabin_a")
                local lantern = MeshAssetRegistry.get("mesh_lantern_post_a")
                TestRunner.truthy(cabin ~= nil and lantern ~= nil)
                TestRunner.equal((cabin :: MeshAssetRegistry.Entry).targetLongestDimension, 20)
                TestRunner.equal((lantern :: MeshAssetRegistry.Entry).targetLongestDimension, 9)
                TestRunner.equal(
                    (cabin :: MeshAssetRegistry.Entry).placementBand,
                    "retired_visual_failure"
                )
                TestRunner.equal((lantern :: MeshAssetRegistry.Entry).placementBand, "curated_core")
            end,
        },
        {
            name = "keeps expedition landmarks measured and curated",
            run = function()
                local farm = MeshAssetRegistry.get("mesh_crooked_farmhouse_a")
                local mill = MeshAssetRegistry.get("mesh_foxfire_windmill_tower_a")
                TestRunner.truthy(farm ~= nil and mill ~= nil)
                TestRunner.equal((farm :: MeshAssetRegistry.Entry).targetLongestDimension, 24)
                TestRunner.equal((mill :: MeshAssetRegistry.Entry).targetLongestDimension, 36)
                TestRunner.equal(
                    (farm :: MeshAssetRegistry.Entry).placementBand,
                    "curated_expedition"
                )
                TestRunner.equal(
                    (mill :: MeshAssetRegistry.Entry).placementBand,
                    "curated_expedition"
                )
            end,
        },
    },
}
