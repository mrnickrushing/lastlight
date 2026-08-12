--!strict

-- Roblox model assets created from the measured GLBs in assets/meshes.
-- Stable IDs are source-facing; numeric IDs may only change through the
-- manifest/upload pipeline and a matching review of this registry.

local MeshAssetRegistry = {}

export type Entry = {
    id: string,
    assetId: number,
    targetLongestDimension: number,
    maxTriangles: number,
    maxMaterialSlots: number,
    placementBand: string,
    pbr: boolean,
    preserveSourceMaterials: boolean,
    creatorStore: boolean,
    -- Yaw, in degrees, that the source model is stored at in the place it was
    -- taken from. Creator Store models are frequently saved rotated off-axis,
    -- which does two things at once: every placement comes out turned by that
    -- angle no matter what yaw the call site asks for, and the axis-aligned
    -- bounding box the loader normalizes against is inflated by the rotation,
    -- so targetLongestDimension silently stops meaning the asset's real
    -- longest dimension. The loader cancels this once at template load, so
    -- call sites can specify the yaw they actually want.
    sourceYawDegrees: number?,
    -- Strip Decals and Textures off the source model at template load.
    --
    -- Creator Store props sometimes ship with signage baked on as a decal
    -- rather than modelled. That art was authored for whatever game the asset
    -- came from, and it arrives already saying something -- in a readable
    -- modern typeface -- that this world never agreed to. Set this when the
    -- geometry is worth keeping and the printing on it is not.
    stripDecals: boolean?,
    -- Recolor and re-material matching source parts at template load. A part
    -- matches a rule when its authored color is within 4 per channel of
    -- `match` (0-255 channels). A rule without `color` keeps the part's color
    -- and changes only the material.
    --
    -- Creator Store props arrive palette-locked to whatever game they were
    -- built for -- a fairground-red canopy on otherwise sound market-stall
    -- geometry, for example. When the shape is worth keeping and only the
    -- finish is off-standard, restyling here is cheaper and safer than
    -- re-sourcing the asset, and it happens once per template rather than
    -- once per placement.
    restyleParts: { { match: { number }, color: { number }?, material: string? } }?,
    -- Fixed-shape corrections for individual sub-parts of the source model,
    -- applied once at template load (before scaling/normalization) so every
    -- placement of the asset gets it, not just the ones that happened to be
    -- audited. Each fix finds the first BasePart descendant whose Size
    -- matches `matchSize` (within a small tolerance) and rotates it in
    -- place about its OWN pivot -- the rest of the model, and the matched
    -- part's own position, are untouched. Use this only when a part is
    -- internally inconsistent with the rest of the SAME asset (a signboard
    -- welded on upside down relative to its own post, a cap authored askew
    -- relative to the body it sits on); a whole-model problem belongs in
    -- sourceYawDegrees instead, which this does not replace.
    partOrientationFixes: {
        {
            matchSize: { number },
            -- Degrees to rotate the matched part about its own local
            -- X/Y/Z axes (applied as `part.CFrame * CFrame.Angles(...)`,
            -- so the rotation is local to the part, not the world).
            localRotationDegrees: { number }?,
            -- Alternative to localRotationDegrees: copy the orientation of
            -- another sibling part in the same model, matched by ITS size,
            -- and keep the target part's own position. Use when the
            -- correct orientation isn't a clean multiple-of-90 rotation
            -- away from the broken one, but a sibling part in the same
            -- asset already has the orientation the target should share.
            copyOrientationFromSize: { number }?,
        }
    }?,
}

local ENTRIES: { Entry } = {
    {
        id = "mesh_conifer_hero_a",
        assetId = 97306204840235,
        targetLongestDimension = 27,
        maxTriangles = 7500,
        maxMaterialSlots = 4,
        placementBand = "core_near",
        pbr = false,
        preserveSourceMaterials = false,
        creatorStore = false,
    },
    {
        id = "mesh_conifer_hero_b",
        assetId = 88242699154685,
        targetLongestDimension = 24,
        maxTriangles = 7500,
        maxMaterialSlots = 4,
        placementBand = "core_near",
        pbr = false,
        preserveSourceMaterials = false,
        creatorStore = false,
    },
    {
        id = "mesh_broadleaf_hero_a",
        assetId = 101220678345453,
        targetLongestDimension = 23,
        maxTriangles = 9000,
        maxMaterialSlots = 5,
        placementBand = "core_near_town_edge",
        pbr = false,
        preserveSourceMaterials = false,
        creatorStore = false,
    },
    {
        id = "mesh_boulder_cluster_a",
        assetId = 89472159459936,
        targetLongestDimension = 10,
        maxTriangles = 3500,
        maxMaterialSlots = 3,
        placementBand = "core_near",
        pbr = false,
        preserveSourceMaterials = false,
        creatorStore = false,
    },
    {
        id = "mesh_deadfall_a",
        assetId = 81668325055416,
        targetLongestDimension = 17,
        maxTriangles = 6500,
        maxMaterialSlots = 5,
        placementBand = "core_near",
        pbr = false,
        preserveSourceMaterials = false,
        creatorStore = false,
    },
    {
        id = "mesh_root_arch_a",
        assetId = 133332812215237,
        targetLongestDimension = 25,
        maxTriangles = 10000,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_fern_cluster_a",
        assetId = 133339285156460,
        targetLongestDimension = 5,
        maxTriangles = 1800,
        maxMaterialSlots = 2,
        placementBand = "core",
        pbr = false,
        preserveSourceMaterials = false,
        creatorStore = false,
    },
    {
        id = "mesh_hollow_lantern_shrine_a",
        assetId = 82771177912612,
        targetLongestDimension = 28,
        maxTriangles = 8000,
        maxMaterialSlots = 7,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = false,
        creatorStore = false,
    },
    {
        id = "mesh_wayfarer_cabin_a",
        assetId = 108978160303399,
        targetLongestDimension = 20,
        maxTriangles = 5000,
        maxMaterialSlots = 6,
        placementBand = "retired_visual_failure",
        pbr = false,
        preserveSourceMaterials = false,
        creatorStore = false,
    },
    {
        id = "mesh_lantern_post_a",
        assetId = 129285000481750,
        targetLongestDimension = 9,
        maxTriangles = 2200,
        maxMaterialSlots = 4,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = false,
        creatorStore = false,
    },
    {
        id = "mesh_hand_axe_a",
        assetId = 70394272147624,
        targetLongestDimension = 3,
        maxTriangles = 3500,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_blacksmith_hammer_a",
        assetId = 80321423425082,
        targetLongestDimension = 3,
        maxTriangles = 3500,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_wayhome_gate_a",
        assetId = 106584116139977,
        targetLongestDimension = 14,
        maxTriangles = 6000,
        maxMaterialSlots = 1,
        placementBand = "curated_expedition",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_old_growth_stump_a",
        assetId = 126541616322157,
        targetLongestDimension = 22,
        maxTriangles = 7000,
        maxMaterialSlots = 1,
        placementBand = "curated_expedition",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_tangle_bridge_a",
        assetId = 100249823997866,
        targetLongestDimension = 18,
        maxTriangles = 6000,
        maxMaterialSlots = 1,
        placementBand = "curated_expedition",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_root_chapel_a",
        assetId = 93798103786347,
        targetLongestDimension = 14,
        maxTriangles = 7000,
        maxMaterialSlots = 1,
        placementBand = "curated_hero",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_memory_reliquary_a",
        assetId = 95277599944074,
        targetLongestDimension = 5.4,
        maxTriangles = 5500,
        maxMaterialSlots = 1,
        placementBand = "curated_hero",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_rootling_a",
        assetId = 123682099011902,
        targetLongestDimension = 5.8,
        maxTriangles = 5500,
        maxMaterialSlots = 1,
        placementBand = "curated_enemy",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_briarback_a",
        assetId = 123899097134679,
        targetLongestDimension = 6.8,
        maxTriangles = 5500,
        maxMaterialSlots = 1,
        placementBand = "curated_enemy",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_hollow_crow_a",
        assetId = 133077954762802,
        targetLongestDimension = 3.8,
        maxTriangles = 5500,
        maxMaterialSlots = 1,
        placementBand = "curated_enemy",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_snapvine_a",
        assetId = 100337926258029,
        targetLongestDimension = 4.8,
        maxTriangles = 5500,
        maxMaterialSlots = 1,
        placementBand = "curated_enemy",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_bark_ram_a",
        assetId = 82812210501095,
        targetLongestDimension = 6.2,
        maxTriangles = 5500,
        maxMaterialSlots = 1,
        placementBand = "curated_enemy",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_old_growth_a",
        assetId = 132155545012921,
        targetLongestDimension = 22.5,
        maxTriangles = 9000,
        maxMaterialSlots = 1,
        placementBand = "curated_enemy",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_warden_stag_a",
        assetId = 97419722389385,
        targetLongestDimension = 19,
        maxTriangles = 9000,
        maxMaterialSlots = 1,
        placementBand = "curated_enemy",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_foxglove_cluster_a",
        assetId = 137511250030382,
        targetLongestDimension = 4.5,
        maxTriangles = 5500,
        maxMaterialSlots = 1,
        placementBand = "curated_expedition",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_briar_wall_a",
        assetId = 125598340587515,
        targetLongestDimension = 9,
        maxTriangles = 5500,
        maxMaterialSlots = 1,
        placementBand = "curated_expedition",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_amber_sap_node_a",
        assetId = 112488289637746,
        targetLongestDimension = 6,
        maxTriangles = 5500,
        maxMaterialSlots = 1,
        placementBand = "curated_expedition",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_heartwood_stump_a",
        assetId = 140476842967550,
        targetLongestDimension = 7,
        maxTriangles = 6000,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_first_lantern_a",
        assetId = 84319358349776,
        targetLongestDimension = 11,
        maxTriangles = 7000,
        maxMaterialSlots = 1,
        placementBand = "curated_hero",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    -- The cap/handle MeshPart ships welded on at a compound tilt (measured
    -- up-vector dot with world-up of -0.94, roughly 160 degrees from
    -- upright) while the body it sits directly on top of is correctly
    -- upright. Every placement of this lantern -- there are dozens across
    -- Bramblewake alone -- ships with an inverted cap. Fixed by copying the
    -- body's orientation onto the cap at template load; the Roundtable-audit
    -- finding this closed is the Bramblewake walkthrough of 2026-08-11.
    --
    -- matchSize/copyOrientationFromSize re-measured live in Studio during
    -- the 2026-08-12 First Light -> Bramblewake -> Ironroot Delve
    -- walkthrough: `mesh_orientation_fix_part_not_found` was firing at boot
    -- for this asset, because the Creator Store import had drifted ~15%
    -- smaller on every sub-part since these values were captured (findable
    -- against a 0.01-stud match epsilon, not against a person's eye), and a
    -- consistent per-axis ratio across both the cap and the body confirms
    -- it's the same two parts, just resized upstream rather than
    -- restructured.
    {
        id = "mesh_creator_kerosene_lantern_a",
        assetId = 11865884168,
        targetLongestDimension = 2.2,
        maxTriangles = 4000,
        maxMaterialSlots = 3,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
        partOrientationFixes = {
            {
                matchSize = { 0.31290403008461, 0.7303782105445862, 0.8763394951820374 },
                copyOrientationFromSize = {
                    0.9574689269065857,
                    1.7144830226898194,
                    0.957468569278717,
                },
            },
        },
    },
    {
        id = "mesh_creator_first_lantern_a",
        assetId = 285454336,
        targetLongestDimension = 4.8,
        maxTriangles = 3400,
        maxMaterialSlots = 13,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_street_lantern_a",
        assetId = 8990192177,
        targetLongestDimension = 9,
        maxTriangles = 800,
        maxMaterialSlots = 8,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_campfire_a",
        assetId = 8752362543,
        targetLongestDimension = 3.2,
        maxTriangles = 3200,
        maxMaterialSlots = 24,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    -- mesh_creator_wood_arch_a is stored as 1.88 x 27.70 x 30.19 (X x Y x Z):
    -- the doorway span is authored along Z, not X. Every call site places
    -- this with yaw = 0 expecting the span to run across X (perpendicular to
    -- the path you walk through it on), so left uncorrected the arch reads
    -- as a flat panel lying along the road instead of a gateway standing
    -- across it. measure_source_yaw reports 0 here because the parts are
    -- axis-aligned -- it only catches off-axis rotation, not this kind of
    -- simple 90-degree span/thickness swap.
    {
        id = "mesh_creator_wood_arch_a",
        assetId = 11084945828,
        sourceYawDegrees = 90,
        targetLongestDimension = 12,
        maxTriangles = 2000,
        maxMaterialSlots = 4,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_rustic_fence_a",
        assetId = 11701774894,
        targetLongestDimension = 8,
        maxTriangles = 500,
        maxMaterialSlots = 2,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_workbench_a",
        assetId = 12752821484,
        targetLongestDimension = 10,
        maxTriangles = 7000,
        maxMaterialSlots = 16,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    -- The lower signboard Union (2.20 x 0.49 x 0.07) ships rotated 180
    -- degrees about its own length axis relative to the upper signboard
    -- Union on the same post (0.07 x 0.49 x 2.20, correctly oriented) --
    -- both boards' length axes already point the same way in world space,
    -- only the lower one reads upside down. Confirmed against every
    -- placement in the Bramblewake stag-tracks event (2026-08-11 walkthrough),
    -- so this is a template defect, not a per-placement one. Fixed by
    -- flipping the lower board 180 degrees about its own local X axis
    -- (its length axis), which does not move it.
    {
        id = "mesh_creator_forest_sign_a",
        assetId = 82202632313902,
        targetLongestDimension = 6,
        maxTriangles = 500,
        maxMaterialSlots = 5,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
        partOrientationFixes = {
            {
                matchSize = { 2.1965529918670654, 0.4913640022277832, 0.0657959058880806 },
                localRotationDegrees = { 180, 0, 0 },
            },
        },
    },
    {
        id = "mesh_creator_tool_set_a",
        assetId = 14578957942,
        targetLongestDimension = 6,
        maxTriangles = 1600,
        maxMaterialSlots = 3,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_barrel_a",
        assetId = 4890213351,
        targetLongestDimension = 3,
        maxTriangles = 1000,
        maxMaterialSlots = 2,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_road_stones_a",
        assetId = 15971612316,
        targetLongestDimension = 18,
        maxTriangles = 600,
        maxMaterialSlots = 13,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_barricade_a",
        assetId = 15994552252,
        targetLongestDimension = 7,
        maxTriangles = 300,
        maxMaterialSlots = 15,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
        stripDecals = true,
    },
    {
        id = "mesh_creator_notice_board_a",
        assetId = 16148507760,
        targetLongestDimension = 11,
        maxTriangles = 1200,
        maxMaterialSlots = 8,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_stump_a",
        assetId = 17626490923,
        targetLongestDimension = 7,
        maxTriangles = 800,
        maxMaterialSlots = 6,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_market_stall_a",
        assetId = 2033520495,
        targetLongestDimension = 20,
        maxTriangles = 3300,
        maxMaterialSlots = 66,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
        restyleParts = {
            { match = { 117, 0, 0 }, color = { 64, 78, 56 }, material = "Fabric" },
            { match = { 213, 115, 61 }, color = { 89, 63, 43 }, material = "Wood" },
            { match = { 170, 85, 0 }, color = { 89, 63, 43 }, material = "Wood" },
            { match = { 105, 64, 40 }, material = "WoodPlanks" },
        },
    },
    {
        id = "mesh_creator_wheat_cluster_a",
        assetId = 252932623,
        targetLongestDimension = 4,
        maxTriangles = 1000,
        maxMaterialSlots = 67,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_picnic_table_a",
        assetId = 2671684461,
        sourceYawDegrees = -165,
        targetLongestDimension = 8,
        maxTriangles = 400,
        maxMaterialSlots = 23,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_watchtower_a",
        assetId = 3237246061,
        targetLongestDimension = 18,
        maxTriangles = 2200,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_wayfarer_bed_a",
        assetId = 5613094175,
        sourceYawDegrees = -32.85,
        targetLongestDimension = 7.2,
        maxTriangles = 2200,
        maxMaterialSlots = 12,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_anvil_a",
        assetId = 11946437830,
        sourceYawDegrees = 85,
        targetLongestDimension = 3.1,
        maxTriangles = 1600,
        maxMaterialSlots = 4,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_zombie_a",
        assetId = 137970350583998,
        targetLongestDimension = 6,
        maxTriangles = 8000,
        maxMaterialSlots = 1,
        placementBand = "curated_enemy",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_creator_potion_shelf_a",
        assetId = 107193693143362,
        targetLongestDimension = 5.4,
        maxTriangles = 3200,
        maxMaterialSlots = 19,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_crate_a",
        assetId = 8314504894,
        targetLongestDimension = 4,
        maxTriangles = 500,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_field_rows_a",
        assetId = 84661463,
        targetLongestDimension = 36,
        maxTriangles = 400,
        maxMaterialSlots = 23,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_crooked_farmhouse_a",
        assetId = 117710597512522,
        targetLongestDimension = 24,
        maxTriangles = 5000,
        maxMaterialSlots = 6,
        placementBand = "curated_expedition",
        pbr = false,
        preserveSourceMaterials = false,
        creatorStore = false,
    },
    {
        id = "mesh_foxfire_windmill_tower_a",
        assetId = 116166738568510,
        targetLongestDimension = 36,
        maxTriangles = 3200,
        maxMaterialSlots = 6,
        placementBand = "curated_expedition",
        pbr = false,
        preserveSourceMaterials = false,
        creatorStore = false,
    },
    {
        id = "mesh_creator_hand_axe_a",
        assetId = 103237554596713,
        targetLongestDimension = 3,
        maxTriangles = 2000,
        maxMaterialSlots = 2,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_blacksmith_hammer_a",
        assetId = 43904769,
        targetLongestDimension = 3,
        maxTriangles = 800,
        maxMaterialSlots = 2,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_creator_handheld_torch_a",
        assetId = 8285874309,
        targetLongestDimension = 3.2,
        maxTriangles = 1200,
        maxMaterialSlots = 12,
        placementBand = "curated_core",
        pbr = false,
        preserveSourceMaterials = true,
        creatorStore = true,
    },
    {
        id = "mesh_celebration_stage_a",
        assetId = 90438134844070,
        targetLongestDimension = 22,
        maxTriangles = 8000,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_sawmill_a",
        assetId = 118785895109979,
        targetLongestDimension = 24,
        maxTriangles = 8000,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_union_forge_a",
        assetId = 112706424048213,
        targetLongestDimension = 20,
        maxTriangles = 8000,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_engineer_yard_a",
        assetId = 124846526369833,
        targetLongestDimension = 20,
        maxTriangles = 8000,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_common_kitchen_a",
        assetId = 131499149518940,
        targetLongestDimension = 20,
        maxTriangles = 8000,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_hearthmarket_stalls_a",
        assetId = 98478070451212,
        targetLongestDimension = 24,
        maxTriangles = 8000,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_trade_post_a",
        assetId = 106875264595961,
        targetLongestDimension = 16,
        maxTriangles = 8000,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_guardhouse_a",
        assetId = 122763719647460,
        targetLongestDimension = 16,
        maxTriangles = 8000,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_watchtower_a",
        assetId = 129659016957808,
        targetLongestDimension = 26,
        maxTriangles = 8000,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_trapworks_a",
        assetId = 77879043908704,
        targetLongestDimension = 16,
        maxTriangles = 7999,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
    {
        id = "mesh_waterworks_a",
        assetId = 82559982340510,
        targetLongestDimension = 18,
        maxTriangles = 8000,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
        preserveSourceMaterials = true,
        creatorStore = false,
    },
}

local BY_ID: { [string]: Entry } = {}
for _, entry in ENTRIES do
    assert(BY_ID[entry.id] == nil, "duplicate mesh asset stable ID: " .. entry.id)
    BY_ID[entry.id] = table.freeze(entry)
end

function MeshAssetRegistry.get(stableId: string): Entry?
    return BY_ID[stableId]
end

function MeshAssetRegistry.all(): { Entry }
    return table.clone(ENTRIES)
end

function MeshAssetRegistry.scaleFor(stableId: string, importedLongestDimension: number): number?
    local entry = BY_ID[stableId]
    if entry == nil or importedLongestDimension <= 0 then
        return nil
    end
    return entry.targetLongestDimension / importedLongestDimension
end

return table.freeze(MeshAssetRegistry)
