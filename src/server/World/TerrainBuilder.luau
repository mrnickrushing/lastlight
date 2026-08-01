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

local DEFAULT_SEED = 20260801

-- The Bramblewake expedition is built around x = 1600 (BramblewakeBuilder's
-- ORIGIN) as its own streamed area. No generated terrain may reach past this
-- line, or hills and peaks grow through the expedition modules. The hill grid
-- already stops at WORLD_EXTENT = 1450; this bounds the peak ring too, whose
-- radius would otherwise carry it further out than its centre suggests.
local BRAMBLEWAKE_KEEP_OUT_X = 1400

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

    `minRadius`/`maxRadius` select an annulus by distance from the bowl centre,
    which is what lets the near ground be generated before a player can join
    and the horizon be generated after. Splitting by radius rather than by grid
    index guarantees the two passes tile exactly: no cell is filled twice, and
    no cell between them is missed.

    `onProgress` is called once per grid row so a deferred caller can yield.
    Yielding inside the row loop instead of per cell keeps the number of
    scheduler round-trips proportional to the grid edge, not its area.
]]
--[[
    The height of the ground surface at a world position.

    This is the single source of truth for the terrain's shape. Both the fill
    loop and anything placed *on* the terrain must read it, or they disagree:
    foliage was originally planted at a hardcoded y = 0 while the ground
    outside the bowl rose by up to ~90 studs, which buried the mid and far
    tree bands -- the exact depth layers this module exists to create.

    Inside the bowl this is always GROUND_Y, which is the flat-floor guarantee
    every authored gameplay coordinate depends on.
]]
local function surfaceHeightAt(x: number, z: number, seed: number): number
    if isInsideBowl(x, z, 0) then
        return GROUND_Y
    end

    local bowlCenterX = (BOWL_MIN_X + BOWL_MAX_X) / 2
    local bowlCenterZ = (BOWL_MIN_Z + BOWL_MAX_Z) / 2
    local dx = x - bowlCenterX
    local dz = z - bowlCenterZ
    local distance = math.sqrt(dx * dx + dz * dz)

    -- Ramp relief in with distance from the valley so the ground leaves the
    -- flat bowl gradually instead of at a wall.
    local ramp = math.clamp((distance - 230) / 620, 0, 1)
    local rise = terrainNoise(seed, x, z, 320) * 58 + 34
    return GROUND_Y + math.max(0, rise * ramp * ramp)
end

--[[
    Surface height for callers outside this module, using the same seed the
    world was built with. Foliage placement uses this so trunks sit on the
    ground rather than inside it.
]]
function TerrainBuilder.surfaceHeight(x: number, z: number, seed: number?): number
    return surfaceHeightAt(x, z, seed or DEFAULT_SEED)
end

local function fillHillAnnulus(
    terrain: Terrain,
    seed: number,
    palette: Palette,
    minRadius: number,
    maxRadius: number,
    onProgress: (() -> ())?
)
    local step = 24
    local bowlCenterX = (BOWL_MIN_X + BOWL_MAX_X) / 2
    local bowlCenterZ = (BOWL_MIN_Z + BOWL_MAX_Z) / 2

    for x = -WORLD_EXTENT, WORLD_EXTENT, step do
        if onProgress ~= nil then
            onProgress()
        end
        for z = -WORLD_EXTENT, WORLD_EXTENT, step do
            if not isInsideBowl(x, z, 0) then
                local dx = x - bowlCenterX
                local dz = z - bowlCenterZ
                local distance = math.sqrt(dx * dx + dz * dz)

                if distance < minRadius or distance >= maxRadius then
                    continue
                end

                -- Stop the grid short of the Bramblewake expedition. Bounding
                -- only the peak ring was not enough: ExpeditionGenerator's
                -- ROUTES[2] walks to cellX = -2, putting a module centre at
                -- x = 1456 whose 72-stud cell reaches x = 1420, while this
                -- grid fills all the way to WORLD_EXTENT = 1450. That 30-stud
                -- overlap would grow hills through the first modules.
                if x >= BRAMBLEWAKE_KEEP_OUT_X then
                    continue
                end

                -- Same function foliage placement reads, so a tree can never
                -- disagree with the ground it stands on.
                local height = surfaceHeightAt(x, z, seed) - GROUND_Y

                -- Every cell outside the bowl is filled, including the ones
                -- with no relief at all. Skipping flat cells left a void ring
                -- between the bowl's rectangular edge and where the distance
                -- ramp starts producing height -- a cell just past x = 190 is
                -- outside the bowl but still under the 230-stud ramp, so it
                -- got no terrain and no floor. Players walking off the bowl
                -- edge fell through it into fall recovery, and removing the
                -- old DistantCliff ring took away the fence that had been
                -- accidentally hiding the gap.
                local material = palette.slope
                if height > 96 then
                    material = palette.peak
                elseif height > 46 then
                    material = palette.ridge
                elseif height < 1 then
                    -- Flat skirt immediately outside the bowl reads as the
                    -- same meadow, not as a different biome starting at a
                    -- straight line.
                    material = palette.valley
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

        -- The Bramblewake expedition is authored as a separate streamed area
        -- around x = 1600. A peak at distance 1330 with radius 210 reaches
        -- x = 1540, close enough to push a mountain through the first
        -- expedition modules. Skipping peaks that reach into it keeps the two
        -- areas from fighting over the same space.
        if x + radius > BRAMBLEWAKE_KEEP_OUT_X then
            continue
        end

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

-- How deep a surface material patch reaches. Only needs to cover the topmost
-- voxel layer that is actually visible; deeper is wasted writes.
local SURFACE_PATCH_DEPTH = 8

--[[
    Meadow and worn-earth colour variation across the valley floor.

    Every patch is a block whose TOP FACE sits exactly at GROUND_Y and whose
    body runs downward, and it is only ever yaw-rotated. Both properties are
    load-bearing:

      * The bowl is already solid from GROUND_Y down to bedrock, so a fill
        entirely at or below GROUND_Y replaces the material of existing voxels
        without changing occupancy. The walkable surface stays exactly flat.
      * Yaw keeps the top face horizontal at a fixed height. Pitch or roll
        would tip a corner up through the surface.

    The first version used FillBall centred at GROUND_Y - 0.55 * radius, which
    put the top of every ball 0.45 * radius ABOVE the ground -- up to a 19.8
    stud solid mound, in the middle of the area this module promises is flat,
    potentially burying the spawn and authored props. FillBall adds terrain; it
    does not merely repaint it. A ball cannot repaint a flat surface at all:
    any ball whose top is at or below the surface only touches it at a single
    tangent point, so a block is the right primitive here, not a rounder one.
]]
local function paintValleyVariation(terrain: Terrain, seed: number, palette: Palette)
    local random = Random.new(seed + 991)

    for _ = 1, 46 do
        local x = random:NextNumber(BOWL_MIN_X + 20, BOWL_MAX_X - 20)
        local z = random:NextNumber(BOWL_MIN_Z + 20, BOWL_MAX_Z - 20)
        local width = toVoxelSpan(random:NextNumber(26, 78))
        local depth = toVoxelSpan(random:NextNumber(26, 78))
        local material = if random:NextNumber() < 0.62 then palette.meadow else palette.slope

        terrain:FillBlock(
            CFrame.new(x, GROUND_Y - SURFACE_PATCH_DEPTH / 2, z)
                * CFrame.Angles(0, random:NextNumber(0, math.pi), 0),
            Vector3.new(width, SURFACE_PATCH_DEPTH, depth),
            material
        )
    end
end

--[[
    Where the join-blocking core pass stops and the deferred pass begins.

    Everything a player can reach, fall off, or see close up in their first
    moments is inside this radius; past it the ground is scenery. Comfortably
    beyond the 620-stud tree line so the transition is never the first thing
    in view.
]]
local CORE_RADIUS = 760

local function applyWaterStyle(terrain: Terrain)
    terrain.Decoration = true
    terrain.WaterColor = Color3.fromRGB(44, 92, 104)
    terrain.WaterReflectance = 0.28
    terrain.WaterTransparency = 0.62
    terrain.WaterWaveSize = 0.08
    terrain.WaterWaveSpeed = 8
end

--[[
    Sculpts everything a joining player needs: the flat valley floor, the
    ground immediately around it, the stream, and surface variation.

    This runs before the spawn exists and before the world is marked ready, so
    it is deliberately the smaller half of the work. Config.BootstrapTimeoutSeconds
    is 8, and AGENTS.md is explicit that joining must never block on the whole
    world loading -- the first version generated the entire 121 x 121 hill grid
    and the horizon here, which is optional scenery no one can reach.

    Safe to call more than once: every fill is deterministic for a given seed,
    so re-running writes identical voxels.
]]
function TerrainBuilder.buildCore(seed: number?, palette: Palette?)
    local terrain = Workspace.Terrain
    local resolvedSeed = seed or DEFAULT_SEED
    local resolvedPalette = palette or DEFAULT_PALETTE

    fillValleyFloor(terrain, resolvedPalette)
    fillHillAnnulus(terrain, resolvedSeed, resolvedPalette, 0, CORE_RADIUS, nil)
    fillStream(terrain, resolvedPalette)
    paintValleyVariation(terrain, resolvedSeed, resolvedPalette)
    applyWaterStyle(terrain)
end

--[[
    Sculpts the horizon: the far hills and the peak ring.

    Meant to be called after the world is marked ready. `onProgress` fires once
    per grid row so the caller can yield between rows and keep the server
    responsive while this fills in behind the tree line.

    Everything here is past CORE_RADIUS, so it can only ever add scenery a
    player is looking at from a distance -- never ground they are standing on.
]]
function TerrainBuilder.buildDistant(seed: number?, palette: Palette?, onProgress: (() -> ())?)
    local terrain = Workspace.Terrain
    local resolvedSeed = seed or DEFAULT_SEED
    local resolvedPalette = palette or DEFAULT_PALETTE

    fillHillAnnulus(terrain, resolvedSeed, resolvedPalette, CORE_RADIUS, math.huge, onProgress)
    fillHorizonPeaks(terrain, resolvedSeed, resolvedPalette)
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
