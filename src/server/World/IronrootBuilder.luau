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
