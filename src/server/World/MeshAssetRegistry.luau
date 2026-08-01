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
    },
    {
        id = "mesh_conifer_hero_b",
        assetId = 88242699154685,
        targetLongestDimension = 24,
        maxTriangles = 7500,
        maxMaterialSlots = 4,
        placementBand = "core_near",
        pbr = false,
    },
    {
        id = "mesh_broadleaf_hero_a",
        assetId = 101220678345453,
        targetLongestDimension = 23,
        maxTriangles = 9000,
        maxMaterialSlots = 5,
        placementBand = "core_near_town_edge",
        pbr = false,
    },
    {
        id = "mesh_boulder_cluster_a",
        assetId = 89472159459936,
        targetLongestDimension = 10,
        maxTriangles = 3500,
        maxMaterialSlots = 3,
        placementBand = "core_near",
        pbr = false,
    },
    {
        id = "mesh_deadfall_a",
        assetId = 81668325055416,
        targetLongestDimension = 17,
        maxTriangles = 6500,
        maxMaterialSlots = 5,
        placementBand = "core_near",
        pbr = false,
    },
    {
        id = "mesh_root_arch_a",
        assetId = 133332812215237,
        targetLongestDimension = 25,
        maxTriangles = 10000,
        maxMaterialSlots = 1,
        placementBand = "curated_core",
        pbr = true,
    },
    {
        id = "mesh_fern_cluster_a",
        assetId = 133339285156460,
        targetLongestDimension = 5,
        maxTriangles = 1800,
        maxMaterialSlots = 2,
        placementBand = "core",
        pbr = false,
    },
    {
        id = "mesh_hollow_lantern_shrine_a",
        assetId = 82771177912612,
        targetLongestDimension = 28,
        maxTriangles = 8000,
        maxMaterialSlots = 7,
        placementBand = "curated_core",
        pbr = false,
    },
    {
        id = "mesh_wayfarer_cabin_a",
        assetId = 108978160303399,
        targetLongestDimension = 20,
        maxTriangles = 5000,
        maxMaterialSlots = 6,
        placementBand = "curated_core",
        pbr = false,
    },
    {
        id = "mesh_lantern_post_a",
        assetId = 129285000481750,
        targetLongestDimension = 9,
        maxTriangles = 2200,
        maxMaterialSlots = 4,
        placementBand = "curated_core",
        pbr = false,
    },
    {
        id = "mesh_crooked_farmhouse_a",
        assetId = 117710597512522,
        targetLongestDimension = 24,
        maxTriangles = 5000,
        maxMaterialSlots = 6,
        placementBand = "curated_expedition",
        pbr = false,
    },
    {
        id = "mesh_foxfire_windmill_tower_a",
        assetId = 116166738568510,
        targetLongestDimension = 36,
        maxTriangles = 3200,
        maxMaterialSlots = 6,
        placementBand = "curated_expedition",
        pbr = false,
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
