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
                TestRunner.equal(#entries, 58)
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
            name = "records the stored rotation of off-axis source models",
            run = function()
                -- Creator Store models are often saved rotated off-axis. That
                -- turns every placement by the same angle whatever yaw a call
                -- site asks for, AND inflates the bounding box the loader
                -- normalizes against, so the asset also loads too small --
                -- both silently. These two were measured with
                -- scripts/measure_source_yaw; if either value is lost the
                -- asset goes back to sitting crooked and undersized.
                local bed = MeshAssetRegistry.get("mesh_creator_wayfarer_bed_a")
                TestRunner.truthy(bed ~= nil, "missing the sourced bed")
                TestRunner.equal((bed :: MeshAssetRegistry.Entry).sourceYawDegrees, -32.85)
                local anvil = MeshAssetRegistry.get("mesh_creator_anvil_a")
                TestRunner.truthy(anvil ~= nil, "missing the sourced anvil")
                TestRunner.equal((anvil :: MeshAssetRegistry.Entry).sourceYawDegrees, 85)
                local table_ = MeshAssetRegistry.get("mesh_creator_picnic_table_a")
                TestRunner.truthy(table_ ~= nil, "missing the sourced commons table")
                TestRunner.equal((table_ :: MeshAssetRegistry.Entry).sourceYawDegrees, -165)
            end,
        },
        {
            -- Every creature the game names is an original asset. The list is
            -- exhaustive on purpose: it is what stops a named creature being
            -- quietly swapped back to a borrowed model, which is the failure
            -- that already cost this project a moderated boss.
            name = "keeps every named creature original, cosmetic and source-preserved",
            run = function()
                for _, stableId in
                    {
                        "mesh_rootling_a",
                        "mesh_briarback_a",
                        "mesh_zombie_a",
                        "mesh_hollow_crow_a",
                        "mesh_snapvine_a",
                        "mesh_bark_ram_a",
                        "mesh_old_growth_a",
                        "mesh_warden_stag_a",
                    }
                do
                    local entry = MeshAssetRegistry.get(stableId)
                    TestRunner.truthy(entry ~= nil, "missing enemy visual asset " .. stableId)
                    TestRunner.equal(
                        (entry :: MeshAssetRegistry.Entry).placementBand,
                        "curated_enemy"
                    )
                    TestRunner.equal(
                        (entry :: MeshAssetRegistry.Entry).preserveSourceMaterials,
                        true
                    )
                    TestRunner.equal((entry :: MeshAssetRegistry.Entry).creatorStore, false)
                end
                local reliquary = MeshAssetRegistry.get("mesh_memory_reliquary_a")
                TestRunner.truthy(reliquary ~= nil)
                TestRunner.equal(
                    (reliquary :: MeshAssetRegistry.Entry).placementBand,
                    "curated_hero"
                )
            end,
        },
        {
            name = "keeps inspected Creator Store props curated and source-preserved",
            run = function()
                for _, stableId in
                    {
                        "mesh_creator_kerosene_lantern_a",
                        "mesh_creator_first_lantern_a",
                        "mesh_creator_street_lantern_a",
                        "mesh_creator_campfire_a",
                    }
                do
                    local entry = MeshAssetRegistry.get(stableId)
                    TestRunner.truthy(entry ~= nil, "missing Creator Store prop " .. stableId)
                    TestRunner.equal(
                        (entry :: MeshAssetRegistry.Entry).placementBand,
                        "curated_core"
                    )
                    TestRunner.equal(
                        (entry :: MeshAssetRegistry.Entry).preserveSourceMaterials,
                        true
                    )
                    TestRunner.equal((entry :: MeshAssetRegistry.Entry).creatorStore, true)
                end
            end,
        },
        {
            name = "covers the full first-world asset replacement kit",
            run = function()
                local expected = {
                    "mesh_creator_wood_arch_a",
                    "mesh_creator_rustic_fence_a",
                    "mesh_creator_workbench_a",
                    "mesh_creator_forest_sign_a",
                    "mesh_creator_tool_set_a",
                    "mesh_creator_barrel_a",
                    "mesh_creator_road_stones_a",
                    "mesh_creator_barricade_a",
                    "mesh_creator_notice_board_a",
                    "mesh_creator_stump_a",
                    "mesh_creator_market_stall_a",
                    "mesh_creator_wheat_cluster_a",
                    "mesh_creator_picnic_table_a",
                    "mesh_creator_watchtower_a",
                    "mesh_creator_crate_a",
                    "mesh_creator_field_rows_a",
                }
                for _, stableId in expected do
                    local entry = MeshAssetRegistry.get(stableId)
                    TestRunner.truthy(entry ~= nil, "missing first-world asset " .. stableId)
                    TestRunner.equal((entry :: MeshAssetRegistry.Entry).creatorStore, true)
                    TestRunner.equal(
                        (entry :: MeshAssetRegistry.Entry).preserveSourceMaterials,
                        true
                    )
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
