--!strict

--[[
    The Ironroot Delve's geometry.

    Bramblewake's builder is a forest: arches, ferns, root tangles, wet
    earth. None of that is the Delve, and dressing a mine in the forest's
    vocabulary is exactly the reskin the milestone's exit gate forbids. So
    the Delve gets its own primitives -- shoring timber, rail, plate,
    ore-shot rock, coalglass, lamp posts -- and its own palette, and every
    module visual is assembled from those.

    What makes a place read as underground when the sky is still there:
    ceilings. Every module here carries a low shored roof on posts, which
    frames the view, throws the module into shadow, and gives the eye a
    horizon at head height instead of at the mountains. The Delve's own
    light comes from lamps and coalglass rather than from the sun.

    This is the first half of the Delve's geometry: the shared vocabulary
    and the arrival, extraction, resource, traversal and landmark shapes.
    Its combat, connector, story and puzzle rooms follow in the next wave,
    and until every visual key in the catalog has a case here the region
    stays disabled in Regions.luau -- RegionAccess refuses it, and
    ExpeditionService's boot assert refuses it louder.
]]

local IronrootBuilder = {}

local ROCK = Color3.fromRGB(62, 58, 56)
local DARK_ROCK = Color3.fromRGB(38, 36, 35)
local ORE_ROCK = Color3.fromRGB(84, 72, 60)
local TIMBER = Color3.fromRGB(96, 68, 42)
local DARK_TIMBER = Color3.fromRGB(62, 44, 28)
local IRON = Color3.fromRGB(92, 88, 86)
local RAIL = Color3.fromRGB(112, 104, 96)
local COALGLASS = Color3.fromRGB(255, 168, 66)
local FUNGUS = Color3.fromRGB(150, 226, 176)
local LAMP = Color3.fromRGB(255, 206, 128)
local SPOIL = Color3.fromRGB(52, 46, 42)

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
    light.Range = size * 6
    light.Brightness = brightness
    light.Shadows = false
    light.Parent = orb
    return orb
end

--[[
    A shored bay: two post pairs and a roof beam. This is the Delve's
    single most repeated shape and the reason its modules read as
    interior -- the roof cuts the sky out of the frame at head height.
]]
local function shoring(parent: Instance, center: Vector3, width: number, depth: number)
    for side = -1, 1, 2 do
        for run = -1, 1, 2 do
            part(
                parent,
                "ShoringPost",
                Vector3.new(1.6, 13, 1.6),
                CFrame.new(center + Vector3.new(side * width * 0.5, 6.5, run * depth * 0.5)),
                TIMBER,
                Enum.Material.Wood
            )
        end
        part(
            parent,
            "ShoringCap",
            Vector3.new(2, 1.4, depth + 2),
            CFrame.new(center + Vector3.new(side * width * 0.5, 13.4, 0)),
            DARK_TIMBER,
            Enum.Material.Wood,
            false
        )
    end
    local roof = part(
        parent,
        "ShoringRoof",
        Vector3.new(width + 3, 1.8, depth + 3),
        CFrame.new(center + Vector3.new(0, 14.4, 0)),
        DARK_ROCK,
        Enum.Material.Slate,
        false
    )
    roof.CanQuery = false
end

-- Rough cut rock, for walls and spoil heaps: three slabs at angles so no
-- two faces of the Delve look machined.
local function rockFace(parent: Instance, center: Vector3, size: Vector3, seed: number)
    for index = 0, 2 do
        local drift = (seed + index * 37) % 11 - 5
        part(
            parent,
            "CutRock",
            size + Vector3.new(index * 1.2, index * 0.8, index * 0.9),
            CFrame.new(center + Vector3.new(drift * 0.4, index * 1.1, drift * 0.3))
                * CFrame.Angles(0, math.rad(drift * 4), math.rad(drift * 1.5)),
            if index == 1 then ORE_ROCK else ROCK,
            Enum.Material.Rock
        )
    end
end

-- Rail: two lines and their sleepers, running along Z through a module.
local function railLine(parent: Instance, center: Vector3, length: number)
    for side = -1, 1, 2 do
        part(
            parent,
            "Rail",
            Vector3.new(0.5, 0.5, length),
            CFrame.new(center + Vector3.new(side * 1.6, 0.55, 0)),
            RAIL,
            Enum.Material.Metal,
            false
        )
    end
    local sleepers = math.max(2, math.floor(length / 5))
    for index = 0, sleepers do
        part(
            parent,
            "Sleeper",
            Vector3.new(5.4, 0.4, 1.1),
            CFrame.new(center + Vector3.new(0, 0.3, -length * 0.5 + index * (length / sleepers))),
            DARK_TIMBER,
            Enum.Material.Wood,
            false
        )
    end
end

local function lampPost(parent: Instance, position: Vector3)
    part(
        parent,
        "LampPost",
        Vector3.new(0.5, 7, 0.5),
        CFrame.new(position + Vector3.new(0, 3.5, 0)),
        IRON,
        Enum.Material.Metal
    )
    part(
        parent,
        "LampHood",
        Vector3.new(1.8, 0.6, 1.8),
        CFrame.new(position + Vector3.new(0, 7.2, 0)),
        IRON,
        Enum.Material.Metal,
        false
    )
    glow(parent, "LampFlame", position + Vector3.new(0, 6.6, 0), 1.1, LAMP, 2.2)
end

local function oreCart(parent: Instance, position: Vector3, facing: number)
    local body = part(
        parent,
        "OreCartBody",
        Vector3.new(4.4, 2.6, 6),
        CFrame.new(position + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, facing, 0),
        IRON,
        Enum.Material.DiamondPlate
    )
    part(
        parent,
        "OreCartLoad",
        Vector3.new(3.8, 1, 5.2),
        body.CFrame * CFrame.new(0, 1.6, 0),
        ORE_ROCK,
        Enum.Material.Rock,
        false
    )
    for side = -1, 1, 2 do
        for run = -1, 1, 2 do
            -- A cylinder's axis is its Size.X, so the axle runs across the
            -- cart. Getting this backwards buries a wheel in its own body,
            -- which is exactly what happened to the Rail Hound.
            local wheel = part(
                parent,
                "OreCartWheel",
                Vector3.new(0.6, 2, 2),
                body.CFrame * CFrame.new(side * 2.3, -1.4, run * 1.9),
                DARK_ROCK,
                Enum.Material.Metal,
                false
            )
            wheel.Shape = Enum.PartType.Cylinder
        end
    end
end

local function fungusPatch(parent: Instance, center: Vector3, seed: number)
    for index = 0, 4 do
        local angle = index * math.pi * 0.4 + seed * 0.1
        local at = center + Vector3.new(math.cos(angle) * 3.2, 0, math.sin(angle) * 3.2)
        part(
            parent,
            "FungusStalk",
            Vector3.new(0.3, 1.4, 0.3),
            CFrame.new(at + Vector3.new(0, 0.7, 0)),
            Color3.fromRGB(96, 110, 92),
            Enum.Material.Slate,
            false
        )
        glow(parent, "FungusCap", at + Vector3.new(0, 1.6, 0), 1.3, FUNGUS, 1.1)
    end
end

local function spoilHeap(parent: Instance, center: Vector3, scale: number)
    for index = 0, 2 do
        local heap = part(
            parent,
            "SpoilHeap",
            Vector3.new(7 * scale - index, 2.4 * scale - index * 0.4, 6 * scale - index),
            CFrame.new(center + Vector3.new(index * 0.6, index * 1.1, index * 0.4)),
            SPOIL,
            Enum.Material.Ground,
            false
        )
        heap.Shape = Enum.PartType.Ball
    end
end

local function coalglassSeam(parent: Instance, center: Vector3, height: number)
    part(
        parent,
        "SeamRock",
        Vector3.new(3.4, height, 2.2),
        CFrame.new(center + Vector3.new(0, height * 0.5, 0)) * CFrame.Angles(0, 0, math.rad(6)),
        DARK_ROCK,
        Enum.Material.Rock
    )
    for index = 0, 3 do
        glow(
            parent,
            "Coalglass",
            center + Vector3.new(0, 1.6 + index * (height / 5), -1.1),
            0.9,
            COALGLASS,
            1.4
        )
    end
end

-- A pipe run: the Delve's plumbing, and the Maw's feed lines in miniature.
local function pipeRun(parent: Instance, center: Vector3, length: number, height: number)
    local pipe = part(
        parent,
        "Pipe",
        Vector3.new(length, 1.4, 1.4),
        CFrame.new(center + Vector3.new(0, height, 0)),
        IRON,
        Enum.Material.Metal,
        false
    )
    pipe.Shape = Enum.PartType.Cylinder
    for side = -1, 1, 2 do
        part(
            parent,
            "PipeBracket",
            Vector3.new(0.8, height, 0.8),
            CFrame.new(center + Vector3.new(side * length * 0.4, height * 0.5, 0)),
            IRON,
            Enum.Material.Metal,
            false
        )
    end
end

-- Standing water, which the Delve has wherever the pumps stopped.
local function floodPool(parent: Instance, center: Vector3, size: number)
    local water = part(
        parent,
        "FloodPool",
        Vector3.new(size, 0.6, size * 0.8),
        CFrame.new(center + Vector3.new(0, 0.5, 0)),
        Color3.fromRGB(46, 62, 66),
        Enum.Material.Glass,
        false
    )
    water.Transparency = 0.45
    water.Reflectance = 0.35
    water.CanQuery = false
end

-- Scaffolding: a laddered climb, the Delve's vertical traversal.
local function scaffold(parent: Instance, center: Vector3, levels: number)
    for level = 0, levels - 1 do
        part(
            parent,
            "ScaffoldDeck",
            Vector3.new(10, 0.6, 5),
            CFrame.new(center + Vector3.new(0, 4 + level * 5, level % 2 * 4 - 2)),
            TIMBER,
            Enum.Material.Wood
        )
        for side = -1, 1, 2 do
            part(
                parent,
                "ScaffoldLeg",
                Vector3.new(0.7, 5, 0.7),
                CFrame.new(center + Vector3.new(side * 4.6, 1.7 + level * 5, level % 2 * 4 - 2)),
                DARK_TIMBER,
                Enum.Material.Wood
            )
        end
        for rung = 0, 3 do
            part(
                parent,
                "LadderRung",
                Vector3.new(2.4, 0.3, 0.3),
                CFrame.new(
                    center + Vector3.new(0, 4.8 + level * 5 + rung * 1.1, level % 2 * 4 + 0.8)
                ),
                DARK_TIMBER,
                Enum.Material.Wood,
                false
            )
        end
    end
end

-- Machinery: the thing that is still running when nobody asked it to.
local function machine(parent: Instance, center: Vector3, scale: number)
    part(
        parent,
        "MachineBed",
        Vector3.new(7 * scale, 3 * scale, 5 * scale),
        CFrame.new(center + Vector3.new(0, 1.6 * scale, 0)),
        IRON,
        Enum.Material.DiamondPlate
    )
    local flywheel = part(
        parent,
        "MachineFlywheel",
        Vector3.new(1.1, 5.4 * scale, 5.4 * scale),
        CFrame.new(center + Vector3.new(3.6 * scale, 3.4 * scale, 0)),
        DARK_ROCK,
        Enum.Material.Metal,
        false
    )
    flywheel.Shape = Enum.PartType.Cylinder
    glow(
        parent,
        "MachineFirebox",
        center + Vector3.new(-2.4 * scale, 1.8 * scale, 0),
        1.5,
        COALGLASS,
        1.8
    )
    pipeRun(parent, center + Vector3.new(0, 0, -3.4 * scale), 12 * scale, 5 * scale)
end

-- A collapse: fallen roof rock with light finding its way through.
local function collapse(parent: Instance, center: Vector3, seed: number)
    for index = 0, 4 do
        local drift = (seed + index * 23) % 9 - 4
        part(
            parent,
            "FallenRock",
            Vector3.new(5 - index * 0.5, 4 - index * 0.4, 5 - index * 0.6),
            CFrame.new(center + Vector3.new(drift * 1.6, 1.6 + index * 1.4, drift * 0.9))
                * CFrame.Angles(math.rad(drift * 6), math.rad(drift * 9), math.rad(drift * 5)),
            if index % 2 == 0 then ROCK else DARK_ROCK,
            Enum.Material.Rock
        )
    end
end

-- A worked doorway with an air door hung in it.
local function airDoor(parent: Instance, center: Vector3)
    for side = -1, 1, 2 do
        part(
            parent,
            "DoorJamb",
            Vector3.new(1.4, 11, 2),
            CFrame.new(center + Vector3.new(side * 5, 5.5, 0)),
            TIMBER,
            Enum.Material.Wood
        )
    end
    part(
        parent,
        "DoorHead",
        Vector3.new(11, 1.4, 2),
        CFrame.new(center + Vector3.new(0, 11.4, 0)),
        DARK_TIMBER,
        Enum.Material.Wood,
        false
    )
    local leaf = part(
        parent,
        "AirDoorLeaf",
        Vector3.new(8.6, 9.6, 0.5),
        CFrame.new(center + Vector3.new(-1.4, 5.2, 0.4)) * CFrame.Angles(0, math.rad(28), 0),
        Color3.fromRGB(112, 96, 76),
        Enum.Material.Fabric,
        false
    )
    leaf.Transparency = 0.15
end

-- A tally or notice board: where the Delve wrote things down.
local function noticeBoard(parent: Instance, center: Vector3)
    part(
        parent,
        "BoardPost",
        Vector3.new(0.6, 5, 0.6),
        CFrame.new(center + Vector3.new(0, 2.5, 0)),
        DARK_TIMBER,
        Enum.Material.Wood
    )
    local board = part(
        parent,
        "BoardFace",
        Vector3.new(5.4, 3.4, 0.4),
        CFrame.new(center + Vector3.new(0, 5.4, 0)) * CFrame.Angles(math.rad(-8), 0, 0),
        TIMBER,
        Enum.Material.Wood,
        false
    )
    for index = 0, 3 do
        part(
            parent,
            "TallyMark",
            Vector3.new(0.9, 0.2, 0.1),
            board.CFrame * CFrame.new(-1.6 + index * 1.1, 0.6, 0.25),
            Color3.fromRGB(224, 214, 196),
            Enum.Material.SmoothPlastic,
            false
        )
    end
end

--[[
    Every module's floor: worked rock rather than grass, with a spoil edge
    so the ground reads as cut rather than grown.
]]
local function delveFloor(parent: Instance, center: Vector3)
    local floor = part(
        parent,
        "DelveFloor",
        Vector3.new(56, 1, 56),
        CFrame.new(center + Vector3.new(0, 0.2, 0)),
        DARK_ROCK,
        Enum.Material.Rock,
        false
    )
    floor.CanQuery = false
    for side = -1, 1, 2 do
        rockFace(parent, center + Vector3.new(side * 26, 0, 0), Vector3.new(5, 12, 40), 17 + side)
    end
end

--[[
    Assemble one module's visual. Unknown keys return false so the caller
    can tell the difference between "built" and "not authored yet" -- the
    Delve ships disabled until this returns true for every key its catalog
    declares, and a spec counts them.
]]
function IronrootBuilder.buildModuleVisual(
    parent: Instance,
    visual: string,
    center: Vector3
): boolean
    if visual == "delve_gate" then
        delveFloor(parent, center)
        shoring(parent, center, 22, 16)
        railLine(parent, center, 46)
        lampPost(parent, center + Vector3.new(-11, 0, 10))
        lampPost(parent, center + Vector3.new(11, 0, 10))
        part(
            parent,
            "GateLintel",
            Vector3.new(26, 2.4, 3),
            CFrame.new(center + Vector3.new(0, 15.6, -8)),
            DARK_TIMBER,
            Enum.Material.Wood,
            false
        )
        return true
    elseif visual == "daylight_shaft" then
        delveFloor(parent, center)
        shoring(parent, center, 20, 14)
        railLine(parent, center, 40)
        -- The way out: a shaft of real light, which is the only place in
        -- the Delve the sky is allowed to reach the floor.
        local shaft = part(
            parent,
            "DaylightShaft",
            Vector3.new(9, 30, 9),
            CFrame.new(center + Vector3.new(0, 15, -4)),
            Color3.fromRGB(255, 244, 214),
            Enum.Material.Neon,
            false
        )
        shaft.Transparency = 0.82
        shaft.CanQuery = false
        glow(parent, "ShaftMouth", center + Vector3.new(0, 2.4, -4), 3.2, LAMP, 3)
        lampPost(parent, center + Vector3.new(-9, 0, 8))
        return true
    elseif visual == "ore_gallery" then
        delveFloor(parent, center)
        shoring(parent, center, 26, 20)
        railLine(parent, center, 44)
        oreCart(parent, center + Vector3.new(0, 0, 9), 0)
        rockFace(parent, center + Vector3.new(-14, 0, -12), Vector3.new(8, 9, 7), 41)
        spoilHeap(parent, center + Vector3.new(13, 0, -10), 1.1)
        lampPost(parent, center + Vector3.new(-12, 0, 4))
        return true
    elseif visual == "coalglass_seam" then
        delveFloor(parent, center)
        shoring(parent, center, 24, 18)
        coalglassSeam(parent, center + Vector3.new(-10, 0, -6), 11)
        coalglassSeam(parent, center + Vector3.new(9, 0, -9), 8)
        spoilHeap(parent, center + Vector3.new(6, 0, 8), 0.9)
        return true
    elseif visual == "fungus_terrace" then
        delveFloor(parent, center)
        shoring(parent, center, 26, 22)
        for index = -1, 1 do
            part(
                parent,
                "Terrace",
                Vector3.new(20, 1.6, 7),
                CFrame.new(center + Vector3.new(0, 1 + (index + 1) * 1.7, index * 8)),
                ROCK,
                Enum.Material.Rock
            )
            fungusPatch(
                parent,
                center + Vector3.new(index * 6, 2.6 + (index + 1) * 1.7, index * 8),
                index + 3
            )
        end
        return true
    elseif visual == "main_incline" then
        delveFloor(parent, center)
        shoring(parent, center, 20, 24)
        -- The grade itself: a ramp the rails climb, which is the Delve's
        -- traversal identity in one shape.
        local ramp = part(
            parent,
            "InclineRamp",
            Vector3.new(16, 2, 34),
            CFrame.new(center + Vector3.new(0, 3.4, 0)) * CFrame.Angles(math.rad(-9), 0, 0),
            ROCK,
            Enum.Material.Rock
        )
        railLine(parent, ramp.Position + Vector3.new(0, 1.2, 0), 30)
        lampPost(parent, center + Vector3.new(-9, 0, -12))
        lampPost(parent, center + Vector3.new(9, 0, 12))
        return true
    elseif visual == "rail_walk" then
        delveFloor(parent, center)
        shoring(parent, center, 18, 26)
        railLine(parent, center, 50)
        oreCart(parent, center + Vector3.new(0, 0, -14), 0)
        for offset = -1, 1, 2 do
            lampPost(parent, center + Vector3.new(offset * 8, 0, offset * 11))
        end
        return true
    elseif visual == "dark_stretch" then
        delveFloor(parent, center)
        shoring(parent, center, 16, 28)
        -- One lamp, far off, and coalglass close enough to walk by. The
        -- unlit stretch is the Delve's answer to Bramblewake's fog.
        coalglassSeam(parent, center + Vector3.new(-7, 0, 6), 6)
        lampPost(parent, center + Vector3.new(6, 0, -16))
        return true
    elseif visual == "bellows_approach" then
        delveFloor(parent, center)
        shoring(parent, center, 30, 24)
        railLine(parent, center, 46)
        -- The Maw's own feed lines converge here, and its heat shows in
        -- the rock before the chamber does.
        for side = -1, 1, 2 do
            coalglassSeam(parent, center + Vector3.new(side * 13, 0, -8), 13)
            oreCart(parent, center + Vector3.new(side * 9, 0, 12), 0)
        end
        glow(parent, "BellowsHeat", center + Vector3.new(0, 3, -18), 5.5, COALGLASS, 3.5)
        return true
    elseif visual == "oil_works" then
        delveFloor(parent, center)
        shoring(parent, center, 26, 20)
        machine(parent, center + Vector3.new(-6, 0, -4), 1.1)
        pipeRun(parent, center + Vector3.new(4, 0, 6), 22, 6)
        for index = -1, 1 do
            part(
                parent,
                "OilDrum",
                Vector3.new(2.6, 3.4, 2.6),
                CFrame.new(center + Vector3.new(9 + index * 3, 1.9, -8)),
                Color3.fromRGB(74, 66, 52),
                Enum.Material.Metal
            )
        end
        return true
    elseif visual == "echo_vault" then
        delveFloor(parent, center)
        shoring(parent, center, 24, 24)
        -- A ring of crystal that hums a half-second late; the vault is
        -- lit by its own answer rather than by any lamp.
        for index = 0, 7 do
            local angle = index * math.pi * 0.25
            local at = center + Vector3.new(math.cos(angle) * 9, 0, math.sin(angle) * 9)
            part(
                parent,
                "EchoCrystal",
                Vector3.new(1.2, 5.5 - (index % 3), 1.2),
                CFrame.new(at + Vector3.new(0, 2.8, 0))
                    * CFrame.Angles(math.rad(index * 5), angle, 0),
                Color3.fromRGB(126, 176, 214),
                Enum.Material.Glass
            )
            glow(
                parent,
                "EchoLight",
                at + Vector3.new(0, 5.6, 0),
                0.9,
                Color3.fromRGB(126, 176, 214),
                1.1
            )
        end
        return true
    elseif visual == "flooded_stope" then
        delveFloor(parent, center)
        shoring(parent, center, 28, 22)
        floodPool(parent, center + Vector3.new(0, 0, 2), 30)
        spoilHeap(parent, center + Vector3.new(-12, 0, -9), 1)
        rockFace(parent, center + Vector3.new(12, 0, -10), Vector3.new(7, 10, 8), 29)
        lampPost(parent, center + Vector3.new(-11, 0, 11))
        return true
    elseif visual == "abandoned_face" then
        delveFloor(parent, center)
        shoring(parent, center, 22, 18)
        rockFace(parent, center + Vector3.new(0, 0, -12), Vector3.new(16, 12, 6), 53)
        -- Tools left where the shift stopped.
        for index = -1, 1 do
            part(
                parent,
                "AbandonedPick",
                Vector3.new(0.4, 0.4, 4),
                CFrame.new(center + Vector3.new(index * 3, 0.6, 2))
                    * CFrame.Angles(0, math.rad(index * 34), math.rad(78)),
                DARK_TIMBER,
                Enum.Material.Wood,
                false
            )
        end
        oreCart(parent, center + Vector3.new(8, 0, 8), math.rad(20))
        return true
    elseif visual == "scaffold_climb" then
        delveFloor(parent, center)
        shoring(parent, center, 24, 22)
        scaffold(parent, center + Vector3.new(-4, 0, 0), 3)
        scaffold(parent, center + Vector3.new(9, 0, -6), 2)
        lampPost(parent, center + Vector3.new(10, 0, 9))
        return true
    elseif visual == "collapse_scramble" then
        delveFloor(parent, center)
        shoring(parent, center, 26, 20)
        collapse(parent, center + Vector3.new(-3, 0, -3), 61)
        collapse(parent, center + Vector3.new(8, 0, 7), 17)
        glow(parent, "CollapseChink", center + Vector3.new(-3, 12, -3), 2.2, LAMP, 1.6)
        return true
    elseif visual == "winch_crossing" then
        delveFloor(parent, center)
        shoring(parent, center, 24, 26)
        machine(parent, center + Vector3.new(-9, 0, 8), 0.8)
        -- The cable itself, strung across the gap it carries carts over.
        part(
            parent,
            "WinchCable",
            Vector3.new(0.3, 0.3, 34),
            CFrame.new(center + Vector3.new(0, 9.5, 0)),
            RAIL,
            Enum.Material.Metal,
            false
        )
        oreCart(parent, center + Vector3.new(0, 5.5, 2), 0)
        return true
    elseif visual == "mite_nest" then
        delveFloor(parent, center)
        shoring(parent, center, 24, 22)
        spoilHeap(parent, center + Vector3.new(-6, 0, -4), 1.3)
        spoilHeap(parent, center + Vector3.new(7, 0, 5), 1)
        for index = 0, 5 do
            local angle = index * math.pi / 3
            glow(
                parent,
                "MiteEmber",
                center + Vector3.new(math.cos(angle) * 7, 0.9, math.sin(angle) * 7),
                0.7,
                COALGLASS,
                0.9
            )
        end
        return true
    elseif visual == "slag_channel" then
        delveFloor(parent, center)
        shoring(parent, center, 22, 26)
        -- The channel: a molten line the fight has to be fought across.
        local channel = part(
            parent,
            "SlagChannel",
            Vector3.new(6, 0.8, 40),
            CFrame.new(center + Vector3.new(0, 0.7, 0)),
            COALGLASS,
            Enum.Material.Neon,
            false
        )
        channel.CanQuery = false
        for side = -1, 1, 2 do
            part(
                parent,
                "ChannelLip",
                Vector3.new(2.4, 1.6, 40),
                CFrame.new(center + Vector3.new(side * 4.2, 1, 0)),
                DARK_ROCK,
                Enum.Material.Rock
            )
        end
        glow(parent, "SlagHeat", center + Vector3.new(0, 3, 0), 4, COALGLASS, 2.6)
        return true
    elseif visual == "guard_round" then
        delveFloor(parent, center)
        shoring(parent, center, 26, 26)
        machine(parent, center + Vector3.new(0, 0, -9), 1)
        railLine(parent, center, 40)
        for side = -1, 1, 2 do
            part(
                parent,
                "GuardPlate",
                Vector3.new(1.2, 8, 9),
                CFrame.new(center + Vector3.new(side * 11, 4, 4)),
                IRON,
                Enum.Material.DiamondPlate
            )
        end
        return true
    elseif visual == "gas_pocket" then
        delveFloor(parent, center)
        shoring(parent, center, 22, 20)
        local haze = part(
            parent,
            "Whitedamp",
            Vector3.new(24, 7, 20),
            CFrame.new(center + Vector3.new(0, 3.6, 0)),
            FUNGUS,
            Enum.Material.Neon,
            false
        )
        haze.Transparency = 0.86
        haze.CanQuery = false
        fungusPatch(parent, center + Vector3.new(-7, 0, 5), 9)
        fungusPatch(parent, center + Vector3.new(8, 0, -6), 4)
        return true
    elseif visual == "echo_gallery" then
        delveFloor(parent, center)
        shoring(parent, center, 28, 22)
        for index = -1, 1 do
            part(
                parent,
                "GalleryPillar",
                Vector3.new(3.4, 12, 3.4),
                CFrame.new(center + Vector3.new(index * 9, 6, -4)),
                ROCK,
                Enum.Material.Rock
            )
            glow(
                parent,
                "EchoLight",
                center + Vector3.new(index * 9, 11, -4),
                1,
                Color3.fromRGB(126, 176, 214),
                1.2
            )
        end
        railLine(parent, center + Vector3.new(0, 0, 8), 30)
        return true
    elseif visual == "shored_drift" then
        delveFloor(parent, center)
        shoring(parent, center, 16, 30)
        railLine(parent, center, 44)
        lampPost(parent, center + Vector3.new(-6, 0, 0))
        return true
    elseif visual == "junction_round" then
        delveFloor(parent, center)
        shoring(parent, center, 26, 26)
        railLine(parent, center, 40)
        railLine(parent, center + Vector3.new(0, 0, 0), 6)
        -- The switch stand that gives a junction its name.
        part(
            parent,
            "SwitchStand",
            Vector3.new(0.6, 4, 0.6),
            CFrame.new(center + Vector3.new(5, 2, 0)),
            IRON,
            Enum.Material.Metal
        )
        glow(parent, "SwitchLamp", center + Vector3.new(5, 4.4, 0), 0.9, LAMP, 1.4)
        lampPost(parent, center + Vector3.new(-9, 0, 9))
        return true
    elseif visual == "rail_siding" then
        delveFloor(parent, center)
        shoring(parent, center, 24, 24)
        railLine(parent, center + Vector3.new(-5, 0, 0), 38)
        railLine(parent, center + Vector3.new(6, 0, 0), 26)
        oreCart(parent, center + Vector3.new(6, 0, -6), 0)
        oreCart(parent, center + Vector3.new(6, 0, 3), 0)
        return true
    elseif visual == "air_door" then
        delveFloor(parent, center)
        shoring(parent, center, 18, 22)
        airDoor(parent, center)
        railLine(parent, center, 36)
        return true
    elseif visual == "foreman_office" then
        delveFloor(parent, center)
        shoring(parent, center, 22, 20)
        -- A room inside the rock: three walls, a desk, and the board that
        -- ran the shift.
        for side = -1, 1, 2 do
            part(
                parent,
                "OfficeWall",
                Vector3.new(0.8, 9, 14),
                CFrame.new(center + Vector3.new(side * 7, 4.5, 0)),
                TIMBER,
                Enum.Material.Wood
            )
        end
        part(
            parent,
            "OfficeBack",
            Vector3.new(14, 9, 0.8),
            CFrame.new(center + Vector3.new(0, 4.5, -7)),
            TIMBER,
            Enum.Material.Wood
        )
        part(
            parent,
            "OfficeDesk",
            Vector3.new(6, 0.6, 3),
            CFrame.new(center + Vector3.new(0, 3, -4)),
            DARK_TIMBER,
            Enum.Material.Wood
        )
        noticeBoard(parent, center + Vector3.new(4, 0, 4))
        lampPost(parent, center + Vector3.new(-5, 0, 5))
        return true
    elseif visual == "miners_rest" then
        delveFloor(parent, center)
        shoring(parent, center, 24, 20)
        for index = -1, 1 do
            part(
                parent,
                "RestBench",
                Vector3.new(7, 0.6, 2),
                CFrame.new(center + Vector3.new(index * 8, 1.6, -5)),
                TIMBER,
                Enum.Material.Wood
            )
            part(
                parent,
                "LunchPail",
                Vector3.new(1.1, 1.2, 1.1),
                CFrame.new(center + Vector3.new(index * 8 + 1.4, 2.5, -5)),
                IRON,
                Enum.Material.Metal,
                false
            )
        end
        glow(parent, "RestFire", center + Vector3.new(0, 1.4, 4), 2.4, COALGLASS, 2.4)
        lampPost(parent, center + Vector3.new(9, 0, 7))
        return true
    elseif visual == "memorial_drift" then
        delveFloor(parent, center)
        shoring(parent, center, 20, 22)
        -- Lamps set in a row for the ones who did not come up, and the
        -- names cut into the rock behind them.
        rockFace(parent, center + Vector3.new(0, 0, -9), Vector3.new(16, 10, 4), 7)
        for index = -2, 2 do
            glow(parent, "MemorialLamp", center + Vector3.new(index * 3.4, 1.6, -5), 1.1, LAMP, 1.5)
            part(
                parent,
                "MemorialStone",
                Vector3.new(1.6, 2.4, 0.8),
                CFrame.new(center + Vector3.new(index * 3.4, 1.2, -6.4)),
                ROCK,
                Enum.Material.Slate
            )
        end
        return true
    elseif visual == "signal_room" then
        delveFloor(parent, center)
        shoring(parent, center, 22, 20)
        machine(parent, center + Vector3.new(-7, 0, -5), 0.7)
        noticeBoard(parent, center + Vector3.new(6, 0, -5))
        -- The signal board itself: three levers, which is what the
        -- Foreman Echo's fight is fought with.
        for index = -1, 1 do
            part(
                parent,
                "SignalLever",
                Vector3.new(0.5, 3.4, 0.5),
                CFrame.new(center + Vector3.new(index * 2.6, 2.6, 4))
                    * CFrame.Angles(math.rad(index * 18), 0, 0),
                IRON,
                Enum.Material.Metal
            )
            glow(
                parent,
                "SignalLamp",
                center + Vector3.new(index * 2.6, 4.6, 4),
                0.7,
                COALGLASS,
                1.1
            )
        end
        return true
    elseif visual == "flood_locks" then
        delveFloor(parent, center)
        shoring(parent, center, 26, 22)
        floodPool(parent, center + Vector3.new(0, 0, 7), 24)
        -- Two lock gates and their wheels, which is the puzzle's shape.
        for side = -1, 1, 2 do
            part(
                parent,
                "LockGate",
                Vector3.new(9, 7, 1),
                CFrame.new(center + Vector3.new(side * 7, 3.5, -3)),
                IRON,
                Enum.Material.DiamondPlate
            )
            local wheel = part(
                parent,
                "LockWheel",
                Vector3.new(0.8, 3, 3),
                CFrame.new(center + Vector3.new(side * 7, 8, -3)),
                RAIL,
                Enum.Material.Metal,
                false
            )
            wheel.Shape = Enum.PartType.Cylinder
        end
        pipeRun(parent, center + Vector3.new(0, 0, -8), 20, 7)
        return true
    end
    return false
end

IronrootBuilder.Primitives = table.freeze({
    shoring = shoring,
    railLine = railLine,
    lampPost = lampPost,
    oreCart = oreCart,
    fungusPatch = fungusPatch,
    spoilHeap = spoilHeap,
    coalglassSeam = coalglassSeam,
    rockFace = rockFace,
    delveFloor = delveFloor,
})

return table.freeze(IronrootBuilder)
