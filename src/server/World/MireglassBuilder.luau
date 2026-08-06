--!strict

--[[
    Mireglass Fen's geometry.

    The Delve reads as underground because every module carries a roof.
    The Fen reads as drowned because every module carries water, and the
    water is the thing you cannot trust: it is glassy enough to mirror
    the sky, so a player looking at the ground is often looking at a
    reflection of what is above it. That is the region's whole idea, and
    it is built rather than described -- reed mats that float, boardwalks
    that stop, stilts that have walked in the mud, and mirror flats that
    reflect a path which is not there.

    Its palette is the opposite of the Delve's: no ember, no iron, no
    lamp. Pale glass, wet green, bog brown, and witchlight, which is the
    only light in the Fen that anything made on purpose.
]]

local MireglassBuilder = {}

local WATER = Color3.fromRGB(46, 66, 68)
local DEEP_WATER = Color3.fromRGB(28, 44, 48)
local REED = Color3.fromRGB(96, 118, 72)
local DRY_REED = Color3.fromRGB(140, 132, 84)
local BOG = Color3.fromRGB(58, 52, 40)
local PLANK = Color3.fromRGB(104, 88, 66)
local DARK_PLANK = Color3.fromRGB(68, 56, 42)
local MIREGLASS = Color3.fromRGB(186, 206, 210)
local WITCHLIGHT = Color3.fromRGB(146, 214, 226)
local BOG_IRON = Color3.fromRGB(96, 74, 58)

local function part(
    parent: Instance,
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material,
    canCollide: boolean?
): Part
    local instance = Instance.new("Part")
    instance.Name = name
    instance.Size = size
    instance.CFrame = cframe
    instance.Color = color
    instance.Material = material
    instance.Anchored = true
    instance.CanCollide = canCollide ~= false
    instance.CanTouch = instance.CanCollide
    instance.CastShadow = true
    instance.TopSurface = Enum.SurfaceType.Smooth
    instance.BottomSurface = Enum.SurfaceType.Smooth
    instance.Parent = parent
    return instance
end

local function glow(
    parent: Instance,
    name: string,
    position: Vector3,
    size: number,
    color: Color3,
    brightness: number
): Part
    local orb = part(
        parent,
        name,
        Vector3.new(size, size, size),
        CFrame.new(position),
        color,
        Enum.Material.Neon,
        false
    )
    orb.Shape = Enum.PartType.Ball
    orb.CanQuery = false
    local light = Instance.new("PointLight")
    light.Color = color
    light.Range = size * 7
    light.Brightness = brightness
    light.Shadows = false
    light.Parent = orb
    return light.Parent :: Part
end

--[[
    The sheet of water a module stands in. Reflectance is the point: this
    is what makes the Fen's ground a claim rather than a fact.
]]
local function fenWater(parent: Instance, center: Vector3, size: number, mirrored: boolean)
    local water = part(
        parent,
        "FenWater",
        Vector3.new(size, 0.8, size),
        CFrame.new(center + Vector3.new(0, 0.4, 0)),
        if mirrored then WATER else DEEP_WATER,
        Enum.Material.Glass,
        false
    )
    water.Transparency = if mirrored then 0.25 else 0.4
    water.Reflectance = if mirrored then 0.75 else 0.3
    water.CanQuery = false
end

local function reedStand(parent: Instance, center: Vector3, count: number, seed: number)
    for index = 0, count - 1 do
        local drift = (seed + index * 29) % 13 - 6
        local at = center + Vector3.new(drift * 0.9, 0, ((index % 5) - 2) * 1.4)
        part(
            parent,
            "Reed",
            Vector3.new(0.22, 5.5 + (index % 4), 0.22),
            CFrame.new(at + Vector3.new(0, 2.8, 0))
                * CFrame.Angles(math.rad(drift * 1.6), 0, math.rad(drift * 2.2)),
            if index % 3 == 0 then DRY_REED else REED,
            Enum.Material.Grass,
            false
        )
    end
end

-- A plank walk: the Fen's only honest ground, and it always runs out.
local function boardwalk(parent: Instance, center: Vector3, length: number, stopShort: boolean)
    local run = if stopShort then length * 0.6 else length
    part(
        parent,
        "Boardwalk",
        Vector3.new(6, 0.5, run),
        CFrame.new(center + Vector3.new(0, 1.4, -(length - run) * 0.5)),
        PLANK,
        Enum.Material.Wood
    )
    local posts = math.max(2, math.floor(run / 6))
    for index = 0, posts do
        for side = -1, 1, 2 do
            part(
                parent,
                "WalkPost",
                Vector3.new(0.6, 3, 0.6),
                CFrame.new(
                    center
                        + Vector3.new(
                            side * 2.4,
                            0,
                            -(length - run) * 0.5 - run * 0.5 + index * (run / posts)
                        )
                ),
                DARK_PLANK,
                Enum.Material.Wood
            )
        end
    end
end

-- A house on stilts, leaning the way the mud took it.
local function stiltHouse(parent: Instance, center: Vector3, lean: number)
    local body = part(
        parent,
        "StiltHouse",
        Vector3.new(11, 8, 9),
        CFrame.new(center + Vector3.new(0, 7.5, 0)) * CFrame.Angles(0, 0, math.rad(lean)),
        PLANK,
        Enum.Material.Wood
    )
    part(
        parent,
        "StiltRoof",
        Vector3.new(13, 1.2, 11),
        body.CFrame * CFrame.new(0, 4.4, 0),
        DARK_PLANK,
        Enum.Material.Wood,
        false
    )
    for side = -1, 1, 2 do
        for run = -1, 1, 2 do
            part(
                parent,
                "Stilt",
                Vector3.new(0.9, 8, 0.9),
                CFrame.new(center + Vector3.new(side * 4, 3.6, run * 3.4))
                    * CFrame.Angles(0, 0, math.rad(lean * 0.6)),
                DARK_PLANK,
                Enum.Material.Wood
            )
        end
    end
end

-- Mireglass itself: sheets of the stuff standing where the bog cooled.
local function glassSheet(parent: Instance, center: Vector3, height: number, tilt: number)
    local sheet = part(
        parent,
        "MireglassSheet",
        Vector3.new(6, height, 0.6),
        CFrame.new(center + Vector3.new(0, height * 0.5, 0)) * CFrame.Angles(0, tilt, math.rad(4)),
        MIREGLASS,
        Enum.Material.Glass
    )
    sheet.Transparency = 0.35
    sheet.Reflectance = 0.6
end

local function witchLantern(parent: Instance, position: Vector3)
    part(
        parent,
        "LanternPole",
        Vector3.new(0.4, 6, 0.4),
        CFrame.new(position + Vector3.new(0, 3, 0)),
        DARK_PLANK,
        Enum.Material.Wood
    )
    glow(parent, "Witchlight", position + Vector3.new(0, 6.2, 0), 1.2, WITCHLIGHT, 1.8)
end

local function puntBoat(parent: Instance, position: Vector3, facing: number, upturned: boolean)
    local hull = part(
        parent,
        "PuntHull",
        Vector3.new(3.6, 1.4, 11),
        CFrame.new(position + Vector3.new(0, 1.2, 0))
            * CFrame.Angles(if upturned then math.rad(180) else 0, facing, 0),
        PLANK,
        Enum.Material.Wood
    )
    part(
        parent,
        "PuntPole",
        Vector3.new(0.3, 0.3, 12),
        hull.CFrame * CFrame.new(1.6, 1.2, 0) * CFrame.Angles(math.rad(72), 0, 0),
        DARK_PLANK,
        Enum.Material.Wood,
        false
    )
end

-- A reed mat: floating ground that may or may not hold.
local function reedMat(parent: Instance, center: Vector3, size: number)
    local mat = part(
        parent,
        "ReedMat",
        Vector3.new(size, 0.5, size * 0.8),
        CFrame.new(center + Vector3.new(0, 0.9, 0)),
        REED,
        Enum.Material.Grass
    )
    mat.Transparency = 0.05
    for index = -1, 1 do
        part(
            parent,
            "MatFringe",
            Vector3.new(size * 0.9, 0.3, 1.2),
            CFrame.new(center + Vector3.new(index * 1.2, 0.7, index * size * 0.35)),
            DRY_REED,
            Enum.Material.Grass,
            false
        )
    end
end

local function bogIronPit(parent: Instance, center: Vector3)
    local pit = part(
        parent,
        "BogPit",
        Vector3.new(9, 1.2, 9),
        CFrame.new(center + Vector3.new(0, 0.6, 0)),
        BOG,
        Enum.Material.Ground
    )
    pit.Transparency = 0.05
    for index = 0, 3 do
        local angle = index * math.pi * 0.5
        part(
            parent,
            "BogIronLump",
            Vector3.new(1.8, 1.4, 1.8),
            CFrame.new(center + Vector3.new(math.cos(angle) * 2.6, 1.3, math.sin(angle) * 2.6)),
            BOG_IRON,
            Enum.Material.Metal,
            false
        )
    end
end

--[[
    The Fen's floor: wet ground with standing water over most of it, and
    a bank of bog at the edges so the module has a shape.
]]
local function fenGround(parent: Instance, center: Vector3)
    local ground = part(
        parent,
        "FenGround",
        Vector3.new(56, 1, 56),
        CFrame.new(center + Vector3.new(0, 0.2, 0)),
        BOG,
        Enum.Material.Ground,
        false
    )
    ground.CanQuery = false
    for side = -1, 1, 2 do
        part(
            parent,
            "FenBank",
            Vector3.new(6, 2.4, 46),
            CFrame.new(center + Vector3.new(side * 25, 1.2, 0))
                * CFrame.Angles(0, 0, math.rad(side * 3)),
            BOG,
            Enum.Material.Ground
        )
    end
end

--[[
    Assemble one module's visual. Same contract as the Delve's builder:
    an unknown key returns false, and the region cannot open until every
    key its catalog declares has a case here.
]]
function MireglassBuilder.buildModuleVisual(
    parent: Instance,
    visual: string,
    center: Vector3
): boolean
    if visual == "ferry_landing" then
        fenGround(parent, center)
        fenWater(parent, center + Vector3.new(0, 0, -10), 34, true)
        boardwalk(parent, center + Vector3.new(0, 0, 6), 26, false)
        puntBoat(parent, center + Vector3.new(-7, 0, -10), math.rad(12), false)
        witchLantern(parent, center + Vector3.new(6, 0, 2))
        return true
    elseif visual == "dry_causeway" then
        fenGround(parent, center)
        -- The way out is the one raised road the water never took.
        part(
            parent,
            "Causeway",
            Vector3.new(12, 3, 50),
            CFrame.new(center + Vector3.new(0, 1.6, 0)),
            BOG,
            Enum.Material.Ground
        )
        fenWater(parent, center + Vector3.new(-18, 0, 0), 18, true)
        fenWater(parent, center + Vector3.new(18, 0, 0), 18, true)
        witchLantern(parent, center + Vector3.new(0, 3, -14))
        return true
    elseif visual == "reed_harvest" then
        fenGround(parent, center)
        fenWater(parent, center, 40, false)
        for index = -1, 1 do
            reedStand(parent, center + Vector3.new(index * 9, 0, index * 5), 14, 11 + index)
        end
        boardwalk(parent, center + Vector3.new(0, 0, 12), 20, false)
        return true
    elseif visual == "bog_iron_pits" then
        fenGround(parent, center)
        bogIronPit(parent, center + Vector3.new(-8, 0, -4))
        bogIronPit(parent, center + Vector3.new(7, 0, 6))
        fenWater(parent, center + Vector3.new(0, 0, 14), 22, false)
        reedStand(parent, center + Vector3.new(12, 0, -10), 8, 5)
        return true
    elseif visual == "pollen_hollow" then
        fenGround(parent, center)
        fenWater(parent, center, 30, false)
        for index = 0, 5 do
            local angle = index * math.pi / 3
            glow(
                parent,
                "WitchlightPollen",
                center + Vector3.new(math.cos(angle) * 8, 3 + (index % 3), math.sin(angle) * 8),
                1.4,
                WITCHLIGHT,
                1.2
            )
        end
        reedStand(parent, center + Vector3.new(0, 0, -12), 12, 23)
        return true
    elseif visual == "eel_weirs" then
        fenGround(parent, center)
        fenWater(parent, center, 44, false)
        for index = -1, 1 do
            part(
                parent,
                "WeirGate",
                Vector3.new(14, 4, 0.8),
                CFrame.new(center + Vector3.new(0, 2, index * 12)),
                DARK_PLANK,
                Enum.Material.Wood
            )
        end
        boardwalk(parent, center + Vector3.new(9, 0, 0), 34, false)
        return true
    elseif visual == "herb_shallows" then
        fenGround(parent, center)
        fenWater(parent, center, 38, true)
        for index = 0, 7 do
            local angle = index * math.pi * 0.25
            part(
                parent,
                "BlackwaterHerb",
                Vector3.new(1.6, 0.4, 1.6),
                CFrame.new(center + Vector3.new(math.cos(angle) * 9, 1, math.sin(angle) * 9)),
                Color3.fromRGB(44, 62, 44),
                Enum.Material.Grass,
                false
            )
        end
        reedMat(parent, center + Vector3.new(0, 0, 10), 9)
        return true
    elseif visual == "glass_flats" then
        fenGround(parent, center)
        fenWater(parent, center, 46, true)
        for index = -2, 2 do
            glassSheet(
                parent,
                center + Vector3.new(index * 7, 0, index % 2 * 6 - 3),
                7 + index,
                math.rad(index * 22)
            )
        end
        return true
    elseif visual == "drowned_orchard" then
        fenGround(parent, center)
        fenWater(parent, center, 42, true)
        for index = -1, 1 do
            for run = -1, 1 do
                part(
                    parent,
                    "DrownedTree",
                    Vector3.new(1.4, 12, 1.4),
                    CFrame.new(center + Vector3.new(index * 9, 5.5, run * 9))
                        * CFrame.Angles(math.rad(index * 4), 0, math.rad(run * 5)),
                    DARK_PLANK,
                    Enum.Material.Wood
                )
            end
        end
        return true
    elseif visual == "reed_mat_crossing" then
        fenGround(parent, center)
        fenWater(parent, center, 46, false)
        for index = -2, 2 do
            reedMat(parent, center + Vector3.new(index * 8, 0, index % 2 * 5), 8)
        end
        return true
    elseif visual == "stepping_stones" then
        fenGround(parent, center)
        fenWater(parent, center, 46, true)
        for index = -3, 3 do
            part(
                parent,
                "SteppingStone",
                Vector3.new(3.4, 1.6, 3.4),
                CFrame.new(center + Vector3.new(index * 5.5, 1.1, (index % 2) * 4 - 2))
                    * CFrame.Angles(0, math.rad(index * 14), 0),
                Color3.fromRGB(76, 78, 74),
                Enum.Material.Slate
            )
        end
        return true
    elseif visual == "mirror_ford" then
        fenGround(parent, center)
        fenWater(parent, center, 50, true)
        -- The ford's trick: a line of glass that shows a crossing which
        -- is one step to the left of the real one.
        for index = -2, 2 do
            glassSheet(parent, center + Vector3.new(index * 6, 0, 4), 6, math.rad(90))
        end
        for index = -2, 2 do
            part(
                parent,
                "FordStone",
                Vector3.new(3, 1.4, 3),
                CFrame.new(center + Vector3.new(index * 6 - 3, 1, -4)),
                Color3.fromRGB(76, 78, 74),
                Enum.Material.Slate
            )
        end
        return true
    elseif visual == "sunken_boardwalk" then
        fenGround(parent, center)
        fenWater(parent, center, 44, false)
        boardwalk(parent, center, 44, false)
        boardwalk(parent, center + Vector3.new(11, -1.2, 4), 30, true)
        return true
    elseif visual == "leaning_house_row" then
        fenGround(parent, center)
        fenWater(parent, center, 44, true)
        stiltHouse(parent, center + Vector3.new(-11, 0, -6), 7)
        stiltHouse(parent, center + Vector3.new(2, 0, 4), -5)
        stiltHouse(parent, center + Vector3.new(13, 0, -8), 11)
        boardwalk(parent, center + Vector3.new(0, 0, 12), 34, false)
        return true
    elseif visual == "fog_bank" then
        fenGround(parent, center)
        fenWater(parent, center, 46, false)
        for index = -1, 1 do
            local fog = part(
                parent,
                "FogBank",
                Vector3.new(30, 9, 14),
                CFrame.new(center + Vector3.new(index * 6, 5, index * 9)),
                Color3.fromRGB(196, 206, 202),
                Enum.Material.Neon,
                false
            )
            fog.Transparency = 0.88
            fog.CanQuery = false
        end
        reedStand(parent, center + Vector3.new(-12, 0, 8), 10, 31)
        return true
    elseif visual == "lurker_shallows" then
        fenGround(parent, center)
        fenWater(parent, center, 46, false)
        reedStand(parent, center + Vector3.new(-8, 0, -6), 16, 3)
        reedStand(parent, center + Vector3.new(9, 0, 7), 16, 19)
        reedMat(parent, center + Vector3.new(0, 0, 0), 10)
        return true
    elseif visual == "mirror_court" then
        fenGround(parent, center)
        fenWater(parent, center, 46, true)
        -- Three mirrors around a floor, which is the Many-Face's fight.
        for index = 0, 2 do
            local angle = index * math.pi * (2 / 3)
            glassSheet(
                parent,
                center + Vector3.new(math.cos(angle) * 12, 0, math.sin(angle) * 12),
                9,
                angle + math.pi * 0.5
            )
            witchLantern(parent, center + Vector3.new(math.cos(angle) * 8, 0, math.sin(angle) * 8))
        end
        return true
    elseif visual == "leech_pools" then
        fenGround(parent, center)
        for index = -1, 1 do
            fenWater(parent, center + Vector3.new(index * 12, 0, index % 2 * 8 - 4), 14, false)
        end
        reedStand(parent, center + Vector3.new(0, 0, 12), 10, 43)
        return true
    elseif visual == "heron_reach" then
        fenGround(parent, center)
        fenWater(parent, center, 48, true)
        -- Open water and long sightlines: the heron's exact line needs
        -- somewhere to be drawn.
        boardwalk(parent, center + Vector3.new(-14, 0, 0), 40, false)
        reedStand(parent, center + Vector3.new(14, 0, -8), 8, 7)
        return true
    elseif visual == "bell_marsh" then
        fenGround(parent, center)
        fenWater(parent, center, 46, false)
        -- Four reflected pools around a bell post: the Drowned Caller's
        -- doors, standing where the fight will need them.
        for index = 0, 3 do
            local angle = index * math.pi * 0.5
            fenWater(
                parent,
                center + Vector3.new(math.cos(angle) * 13, 0, math.sin(angle) * 13),
                10,
                true
            )
            witchLantern(parent, center + Vector3.new(math.cos(angle) * 9, 0, math.sin(angle) * 9))
        end
        part(
            parent,
            "BellPost",
            Vector3.new(0.8, 10, 0.8),
            CFrame.new(center + Vector3.new(0, 5, 0)),
            DARK_PLANK,
            Enum.Material.Wood
        )
        return true
    elseif visual == "low_dyke" then
        fenGround(parent, center)
        part(
            parent,
            "Dyke",
            Vector3.new(10, 2.6, 48),
            CFrame.new(center + Vector3.new(0, 1.5, 0)),
            BOG,
            Enum.Material.Ground
        )
        fenWater(parent, center + Vector3.new(-16, 0, 0), 16, false)
        fenWater(parent, center + Vector3.new(16, 0, 0), 16, true)
        return true
    elseif visual == "punt_channel" then
        fenGround(parent, center)
        fenWater(parent, center, 46, true)
        puntBoat(parent, center + Vector3.new(-4, 0, 2), 0, false)
        puntBoat(parent, center + Vector3.new(8, 0, -6), math.rad(24), true)
        boardwalk(parent, center + Vector3.new(-13, 0, 0), 34, false)
        return true
    elseif visual == "willow_gate" then
        fenGround(parent, center)
        fenWater(parent, center + Vector3.new(0, 0, 8), 26, true)
        for side = -1, 1, 2 do
            part(
                parent,
                "WillowTrunk",
                Vector3.new(2.6, 14, 2.6),
                CFrame.new(center + Vector3.new(side * 7, 7, -6))
                    * CFrame.Angles(0, 0, math.rad(side * -8)),
                DARK_PLANK,
                Enum.Material.Wood
            )
            for index = 0, 4 do
                part(
                    parent,
                    "WillowFrond",
                    Vector3.new(0.3, 7, 0.3),
                    CFrame.new(center + Vector3.new(side * (5 + index), 9, -6 + index)),
                    REED,
                    Enum.Material.Grass,
                    false
                )
            end
        end
        return true
    elseif visual == "stilt_junction" then
        fenGround(parent, center)
        fenWater(parent, center, 44, true)
        boardwalk(parent, center, 40, false)
        boardwalk(parent, center + Vector3.new(0, 0, 0), 22, false)
        stiltHouse(parent, center + Vector3.new(-12, 0, 8), 4)
        witchLantern(parent, center + Vector3.new(6, 1.4, 0))
        return true
    elseif visual == "ferryman_shack" then
        fenGround(parent, center)
        fenWater(parent, center + Vector3.new(0, 0, -10), 28, true)
        stiltHouse(parent, center + Vector3.new(0, 0, 4), 3)
        boardwalk(parent, center + Vector3.new(0, 0, -8), 22, false)
        puntBoat(parent, center + Vector3.new(-8, 0, -12), math.rad(-14), false)
        witchLantern(parent, center + Vector3.new(7, 0, -4))
        return true
    elseif visual == "wake_platform" then
        fenGround(parent, center)
        fenWater(parent, center, 40, true)
        part(
            parent,
            "WakePlatform",
            Vector3.new(16, 1, 16),
            CFrame.new(center + Vector3.new(0, 1.6, 0)),
            PLANK,
            Enum.Material.Wood
        )
        for index = 0, 5 do
            local angle = index * math.pi / 3
            witchLantern(
                parent,
                center + Vector3.new(math.cos(angle) * 6.5, 1.6, math.sin(angle) * 6.5)
            )
        end
        return true
    elseif visual == "sunken_chapel" then
        fenGround(parent, center)
        fenWater(parent, center, 44, true)
        -- A chapel the water took to the windows.
        part(
            parent,
            "ChapelWall",
            Vector3.new(16, 9, 0.9),
            CFrame.new(center + Vector3.new(0, 4, -7)),
            Color3.fromRGB(88, 88, 82),
            Enum.Material.Slate
        )
        for side = -1, 1, 2 do
            part(
                parent,
                "ChapelSide",
                Vector3.new(0.9, 9, 14),
                CFrame.new(center + Vector3.new(side * 8, 4, 0)),
                Color3.fromRGB(88, 88, 82),
                Enum.Material.Slate
            )
            glassSheet(parent, center + Vector3.new(side * 7.4, 3.5, -2), 4, math.rad(90))
        end
        witchLantern(parent, center + Vector3.new(0, 1, 4))
        return true
    elseif visual == "reflection_locks" then
        fenGround(parent, center)
        fenWater(parent, center, 46, true)
        -- Three mirrors and three stones: the puzzle is telling which is
        -- which, so both have to be legible from the same standing spot.
        for index = -1, 1 do
            glassSheet(parent, center + Vector3.new(index * 9, 0, -6), 8, math.rad(90))
            part(
                parent,
                "LockStone",
                Vector3.new(3, 2, 3),
                CFrame.new(center + Vector3.new(index * 9, 1.4, 6)),
                Color3.fromRGB(76, 78, 74),
                Enum.Material.Slate
            )
        end
        return true
    elseif visual == "tide_gates" then
        fenGround(parent, center)
        fenWater(parent, center + Vector3.new(0, 0, 12), 26, false)
        fenWater(parent, center + Vector3.new(0, 0, -12), 26, true)
        for side = -1, 1, 2 do
            part(
                parent,
                "TideGate",
                Vector3.new(11, 8, 1.2),
                CFrame.new(center + Vector3.new(side * 7, 4, 0)),
                DARK_PLANK,
                Enum.Material.Wood
            )
            local wheel = part(
                parent,
                "TideWheel",
                Vector3.new(0.8, 3.2, 3.2),
                CFrame.new(center + Vector3.new(side * 7, 9, 0)),
                BOG_IRON,
                Enum.Material.Metal,
                false
            )
            wheel.Shape = Enum.PartType.Cylinder
        end
        return true
    elseif visual == "witch_approach" then
        fenGround(parent, center)
        fenWater(parent, center, 50, true)
        -- Her ring of lights, hanging at head height, with the boardwalk
        -- running into it and stopping.
        for index = 0, 7 do
            local angle = index * math.pi * 0.25
            witchLantern(
                parent,
                center + Vector3.new(math.cos(angle) * 15, 2.5, math.sin(angle) * 15)
            )
        end
        boardwalk(parent, center + Vector3.new(0, 0, 14), 30, true)
        glassSheet(parent, center + Vector3.new(0, 0, -12), 11, 0)
        return true
    end
    return false
end

MireglassBuilder.Primitives = table.freeze({
    fenWater = fenWater,
    reedStand = reedStand,
    boardwalk = boardwalk,
    stiltHouse = stiltHouse,
    glassSheet = glassSheet,
    witchLantern = witchLantern,
    puntBoat = puntBoat,
    reedMat = reedMat,
    bogIronPit = bogIronPit,
    fenGround = fenGround,
})

return table.freeze(MireglassBuilder)
