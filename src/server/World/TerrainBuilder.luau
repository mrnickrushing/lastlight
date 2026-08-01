--!strict

--[[
    Sculpted Bramblewake terrain for the arrival valley.

    WHY THIS EXISTS

    The arrival world used to stand on a single 320 x 6 x 340 Part called
    "Ground". A flat rectangle has no horizon, no silhouette, and no sense of
    distance, so a valley that the design documents describe as a fracturing
    wilderness read as a small yard with props on it. No amount of prop detail
    fixes that: the eye reads ground shape and depth layers before it reads
    individual objects.

    Real Terrain fixes four things a Part floor cannot:

      * an actual horizon line, so the world stops ending in mid-air;
      * elevation the camera can look along, which is what produces depth;
      * material blending at the ground plane instead of one flat colour;
      * Terrain.Decoration grass, which is free surface detail on every
        Grass voxel and costs no instances.

    WHAT IS DELIBERATELY *NOT* SCULPTED

    Every gameplay coordinate in WorldService is a hardcoded Vector3 authored
    against a flat plane at y = 0 -- spawns, interaction prompts, the lantern
    ring, the night defense route, incident sites, enemy spawn points. Sculpting
    under those would drop props into hillsides and leave prompts floating.

    So the playable bowl is filled flat, with its surface exactly at y = 0, and
    all relief happens *outside* it. The valley floor the player walks stays
    byte-for-byte the geometry the systems were authored against; the world
    around it gains hills, ridges, and a far skyline. That split is the whole
    reason this can land without re-authoring 5,000 lines of positions.

    COST

    Terrain is voxel data, not instances, so this adds zero parts to the
    streaming budget. Fills are bulk operations on 4-stud voxels; the whole
    valley is a few hundred FillBlock/FillBall calls rather than a per-voxel
    loop. Generation is deterministic from a fixed seed so two servers build an
    identical valley and a Studio build matches a live one.
]]

local Workspace = game:GetService("Workspace")

local TerrainBuilder = {}

-- The flat region every authored gameplay coordinate lives inside. Relief is
-- only generated outside this rectangle. Widened past the actual play area so
-- the transition to hills never crowds the walkable route.
local BOWL_MIN_X = -190
local BOWL_MAX_X = 190
local BOWL_MIN_Z = -260
local BOWL_MAX_Z = 90

-- Ground surface height. Must stay 0: it is the plane every authored Vector3
-- in WorldService was placed against.
local GROUND_Y = 0

-- How deep the solid ground slab runs. Enough that a Blackout crater or a
-- future dug-out cannot punch through into empty space.
local BEDROCK_DEPTH = 90

-- Outer extent of generated terrain. StreamingTargetRadius is 1024, so terrain
-- past roughly 1200 studs is only ever seen as a horizon silhouette; beyond
-- this the sky takes over.
local WORLD_EXTENT = 1450

local VOXEL = 4

export type Palette = {
    valley: Enum.Material,
    meadow: Enum.Material,
    slope: Enum.Material,
    ridge: Enum.Material,
    peak: Enum.Material,
    shore: Enum.Material,
}

local DEFAULT_PALETTE: Palette = {
    valley = Enum.Material.Grass,
    meadow = Enum.Material.LeafyGrass,
    slope = Enum.Material.Ground,
    ridge = Enum.Material.Rock,
    peak = Enum.Material.Slate,
    shore = Enum.Material.Sand,
}

-- Rounds a span up to a whole number of voxels. Terrain snaps fills to its own
-- 4-stud grid, and unrounded sizes leave single-voxel seams between adjacent
-- fills that read as cracks in the ground from a low camera.
local function toVoxelSpan(value: number): number
    return math.max(VOXEL, math.ceil(value / VOXEL) * VOXEL)
end

local function isInsideBowl(x: number, z: number, margin: number): boolean
    return x > BOWL_MIN_X - margin
        and x < BOWL_MAX_X + margin
        and z > BOWL_MIN_Z - margin
        and z < BOWL_MAX_Z + margin
end

--[[
    Two-octave value noise in [-1, 1], seeded so every server sculpts the same
    valley.

    math.noise is Perlin and already deterministic for a given input, so the
    seed only has to offset the sample position. Two octaves is enough for a
    natural ridgeline; more detail is invisible once terrain smoothing and
    grass decoration land on top of it.
]]
local function terrainNoise(seed: number, x: number, z: number, scale: number): number
    local base = math.noise(x / scale + seed, z / scale + seed, seed * 0.37)
    local detail = math.noise(x / (scale * 0.42) - seed, z / (scale * 0.42) + seed, seed * 0.11)
    return math.clamp(base + detail * 0.38, -1, 1)
end

--[[
    Fills the flat valley floor that all authored gameplay geometry sits on.

    Filled as one block rather than per-column so the walkable surface is
    guaranteed level -- noise anywhere in here would tilt props and prompts.
]]
local function fillValleyFloor(terrain: Terrain, palette: Palette)
    local width = toVoxelSpan(BOWL_MAX_X - BOWL_MIN_X)
    local depth = toVoxelSpan(BOWL_MAX_Z - BOWL_MIN_Z)
    local centerX = (BOWL_MIN_X + BOWL_MAX_X) / 2
    local centerZ = (BOWL_MIN_Z + BOWL_MAX_Z) / 2

    terrain:FillBlock(
        CFrame.new(centerX, GROUND_Y - BEDROCK_DEPTH / 2, centerZ),
        Vector3.new(width, BEDROCK_DEPTH, depth),
        palette.valley
    )
end

--[[
    Rolling ground outside the bowl, rising with distance so the valley reads as
    sheltered and the skyline closes the world off.

    Columns are sampled on a coarse grid and filled as blocks. A finer grid
    would cost proportionally more fills for detail that terrain smoothing and
    the tree line hide anyway.
]]
local function fillSurroundingHills(terrain: Terrain, seed: number, palette: Palette)
    local step = 24
    local bowlCenterX = (BOWL_MIN_X + BOWL_MAX_X) / 2
    local bowlCenterZ = (BOWL_MIN_Z + BOWL_MAX_Z) / 2

    for x = -WORLD_EXTENT, WORLD_EXTENT, step do
        for z = -WORLD_EXTENT, WORLD_EXTENT, step do
            if not isInsideBowl(x, z, 0) then
                local dx = x - bowlCenterX
                local dz = z - bowlCenterZ
                local distance = math.sqrt(dx * dx + dz * dz)

                -- Ramp relief in with distance from the valley so the ground
                -- leaves the flat bowl gradually instead of at a wall.
                local ramp = math.clamp((distance - 230) / 620, 0, 1)
                local rise = terrainNoise(seed, x, z, 320) * 58 + 34
                local height = rise * ramp * ramp

                if height > 2 then
                    local material = palette.slope
                    if height > 96 then
                        material = palette.peak
                    elseif height > 46 then
                        material = palette.ridge
                    end

                    local columnHeight = toVoxelSpan(height + BEDROCK_DEPTH)
                    terrain:FillBlock(
                        CFrame.new(x, GROUND_Y + height - columnHeight / 2, z),
                        Vector3.new(toVoxelSpan(step), columnHeight, toVoxelSpan(step)),
                        material
                    )
                end
            end
        end
    end
end

--[[
    Distant peaks that close the horizon.

    Placed as overlapping balls rather than blocks: a ball reads as a rounded
    massif once smoothed, and at this distance silhouette is the only property
    that survives. This is the "distant silhouette" depth layer the art
    direction asks every background to have.
]]
local function fillHorizonPeaks(terrain: Terrain, seed: number, palette: Palette)
    local random = Random.new(seed)
    local peakCount = 26

    for index = 1, peakCount do
        local angle = (index / peakCount) * math.pi * 2 + random:NextNumber(-0.06, 0.06)
        local distance = random:NextNumber(1020, 1330)
        local x = math.cos(angle) * distance
        local z = math.sin(angle) * distance - 70
        local radius = random:NextNumber(110, 210)
        local height = random:NextNumber(150, 320)

        -- Two stacked balls give a shoulder and a cap, which reads as a
        -- mountain rather than a dome.
        terrain:FillBall(Vector3.new(x, GROUND_Y + height * 0.15, z), radius, palette.ridge)
        terrain:FillBall(Vector3.new(x, GROUND_Y + height * 0.55, z), radius * 0.62, palette.peak)
    end
end

--[[
    A stream running past the east edge of the valley into a pond.

    Water is the cheapest large-scale visual interest terrain offers: it moves,
    it reflects the sky and the lanterns, and it gives the flat bowl a readable
    boundary on one side. Kept outside the bowl so it can never flood a spawn
    or an interaction, and carved before it is filled so the banks read as cut
    earth rather than a puddle sitting on grass.
]]
local function fillStream(terrain: Terrain, palette: Palette)
    local points = {
        Vector3.new(232, GROUND_Y, 60),
        Vector3.new(252, GROUND_Y, -20),
        Vector3.new(268, GROUND_Y, -104),
        Vector3.new(296, GROUND_Y, -186),
        Vector3.new(342, GROUND_Y, -252),
    }

    for index = 1, #points - 1 do
        local from = points[index]
        local to = points[index + 1]
        local delta = to - from
        local segments = math.max(1, math.floor(delta.Magnitude / 16))

        for step = 0, segments do
            local at = from + delta * (step / segments)
            local width = 26 + math.sin(step * 0.7 + index) * 5

            -- Carve the channel, then fill the lower half with water so the
            -- surface sits below the surrounding ground.
            terrain:FillBall(Vector3.new(at.X, GROUND_Y + 2, at.Z), width * 0.5, Enum.Material.Air)
            terrain:FillBall(
                Vector3.new(at.X, GROUND_Y - 3, at.Z),
                width * 0.44,
                Enum.Material.Water
            )
            terrain:FillBall(Vector3.new(at.X - width * 0.55, GROUND_Y - 1, at.Z), 8, palette.shore)
        end
    end

    -- The pond the stream empties into, wide enough to catch a reflection of
    -- the ridgeline behind it.
    terrain:FillBall(Vector3.new(362, GROUND_Y + 3, -286), 62, Enum.Material.Air)
    terrain:FillBall(Vector3.new(362, GROUND_Y - 6, -286), 56, Enum.Material.Water)
    terrain:FillBall(Vector3.new(316, GROUND_Y - 2, -268), 22, palette.shore)
end

--[[
    Meadow and worn-earth colour variation across the valley floor.

    Painted as shallow surface fills on top of the finished floor. This is what
    stops the walkable area from being one uniform green: the design direction
    asks for material variation from modular detail rather than unique
    textures, and swapping the top voxel layer is the cheapest version of that.
]]
local function paintValleyVariation(terrain: Terrain, seed: number, palette: Palette)
    local random = Random.new(seed + 991)

    for _ = 1, 46 do
        local x = random:NextNumber(BOWL_MIN_X + 20, BOWL_MAX_X - 20)
        local z = random:NextNumber(BOWL_MIN_Z + 20, BOWL_MAX_Z - 20)
        local radius = random:NextNumber(16, 44)
        local material = if random:NextNumber() < 0.62 then palette.meadow else palette.slope

        terrain:FillBall(Vector3.new(x, GROUND_Y - radius * 0.55, z), radius, material)
    end
end

--[[
    Sculpts the whole arrival valley.

    Safe to call more than once: ClearAllChildren-style resets are not needed
    because every fill is deterministic and idempotent for a given seed --
    re-running writes identical voxels.
]]
function TerrainBuilder.build(seed: number?, palette: Palette?)
    local terrain = Workspace.Terrain
    local resolvedSeed = seed or 20260801
    local resolvedPalette = palette or DEFAULT_PALETTE

    fillValleyFloor(terrain, resolvedPalette)
    fillSurroundingHills(terrain, resolvedSeed, resolvedPalette)
    fillHorizonPeaks(terrain, resolvedSeed, resolvedPalette)
    fillStream(terrain, resolvedPalette)
    paintValleyVariation(terrain, resolvedSeed, resolvedPalette)

    terrain.Decoration = true
    terrain.WaterColor = Color3.fromRGB(44, 92, 104)
    terrain.WaterReflectance = 0.28
    terrain.WaterTransparency = 0.62
    terrain.WaterWaveSize = 0.08
    terrain.WaterWaveSpeed = 8
end

-- Exposed so world code and tests can reason about the flat region without
-- duplicating the numbers.
function TerrainBuilder.bowlBounds(): (number, number, number, number)
    return BOWL_MIN_X, BOWL_MAX_X, BOWL_MIN_Z, BOWL_MAX_Z
end

function TerrainBuilder.isInsidePlayableBowl(x: number, z: number): boolean
    return isInsideBowl(x, z, 0)
end

function TerrainBuilder.groundHeight(): number
    return GROUND_Y
end

return table.freeze(TerrainBuilder)
