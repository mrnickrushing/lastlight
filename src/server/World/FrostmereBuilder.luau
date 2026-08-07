--!strict

--[[
    Frostmere Vale's geometry.

    The Delve reads as underground because every module carries a roof.
    The Fen reads as drowned because every module carries water it wants
    you to mistrust. The Reach reads as exposed because every module
    carries something built against weather that the weather is beating.

    The Vale reads as cold, and cold is drawn by its absence. Every
    module here carries a hearth -- and most of the hearths are out. A
    banked fire, a bed of ember moss, a stove someone left burning: those
    are the shapes a player learns to look for, and the reason a room
    with a dead hearth in it is more frightening than an empty one. The
    valley is not dangerous because it is outdoors. It is dangerous
    because being indoors stopped meaning anything.

    Its second rule is quiet, and quiet is drawn by things that would
    make noise if you touched them: bell ropes, hanging chains, loose
    slate, thin ice. The Vale is full of them on purpose.
]]

local FrostmereBuilder = {}

local SNOW = Color3.fromRGB(226, 232, 238)
local SHADOW_SNOW = Color3.fromRGB(178, 190, 204)
local ICE = Color3.fromRGB(168, 202, 216)
local DEEP_ICE = Color3.fromRGB(96, 138, 160)
local ABBEY_STONE = Color3.fromRGB(126, 128, 130)
local DARK_STONE = Color3.fromRGB(72, 76, 82)
local TIMBER = Color3.fromRGB(102, 82, 62)
local DARK_TIMBER = Color3.fromRGB(64, 50, 38)
local WOOL = Color3.fromRGB(214, 206, 188)
local EMBER = Color3.fromRGB(238, 128, 54)
local FIRE = Color3.fromRGB(255, 176, 88)
local AURORA = Color3.fromRGB(126, 236, 198)
local IRON = Color3.fromRGB(94, 96, 100)
local PINE = Color3.fromRGB(46, 66, 56)

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
)
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
    light.Range = size * 9
    light.Brightness = brightness
    light.Shadows = false
    light.Parent = orb
end

-- Snow underfoot, with the drifts that say which way the wind runs here.
local function valeGround(parent: Instance, center: Vector3)
    part(parent, "ValeGround", Vector3.new(40, 1, 40), CFrame.new(center), SNOW, Enum.Material.Snow)
    for index = -1, 1 do
        local drift = part(
            parent,
            "Drift",
            Vector3.new(30 - index * 4, 2.4 + index, 7),
            CFrame.new(center + Vector3.new(index * 5, 1.2, index * 12))
                * CFrame.Angles(0, math.rad(index * 6), 0),
            SHADOW_SNOW,
            Enum.Material.Snow,
            false
        )
        drift.CanQuery = false
    end
end

--[[
    The region's one load-bearing shape. Lit, it is the only reason a
    module is survivable; cold, it is the clearest bad news the Vale can
    give a player without a line of text. Both are drawn, because a hearth
    that is simply absent reads as decoration and a hearth that is out
    reads as a place somebody died.
]]
local function hearth(parent: Instance, center: Vector3, lit: boolean)
    for index = 0, 5 do
        part(
            parent,
            "HearthStone",
            Vector3.new(1.8, 1.4, 1.2),
            CFrame.new(center + Vector3.new(0, 0.9, 0))
                * CFrame.Angles(0, math.rad(index * 60), 0)
                * CFrame.new(0, 0, 2.6),
            ABBEY_STONE,
            Enum.Material.Slate
        )
    end
    for index = -1, 1 do
        part(
            parent,
            "HearthLog",
            Vector3.new(0.7, 0.7, 3.4),
            CFrame.new(center + Vector3.new(index * 0.7, 1.1, 0))
                * CFrame.Angles(0, math.rad(index * 40), 0),
            if lit then DARK_TIMBER else Color3.fromRGB(48, 44, 42),
            Enum.Material.Wood,
            false
        )
    end
    if lit then
        glow(parent, "HearthFire", center + Vector3.new(0, 1.8, 0), 2.2, FIRE, 3)
    else
        local ash = part(
            parent,
            "HearthAsh",
            Vector3.new(3.2, 0.3, 3.2),
            CFrame.new(center + Vector3.new(0, 0.9, 0)),
            Color3.fromRGB(108, 104, 100),
            Enum.Material.Sand,
            false
        )
        ash.CanQuery = false
    end
end

-- Ember moss: the Vale's growing fire, and the only warmth here that
-- nobody had to light.
local function emberMoss(parent: Instance, center: Vector3, radius: number)
    for index = 0, 6 do
        local angle = index * 0.9
        local patch = part(
            parent,
            "EmberMoss",
            Vector3.new(radius * 0.5, 0.4, radius * 0.4),
            CFrame.new(
                center
                    + Vector3.new(
                        math.cos(angle) * radius * 0.5,
                        0.8,
                        math.sin(angle) * radius * 0.5
                    )
            ) * CFrame.Angles(0, angle, 0),
            EMBER,
            Enum.Material.Neon,
            false
        )
        patch.Transparency = 0.35
        patch.CanQuery = false
    end
    glow(parent, "MossGlow", center + Vector3.new(0, 1.2, 0), 1.6, EMBER, 1.6)
end

-- Abbey masonry: a run of wall with arches cut through it. The valley's
-- one building material and the reason its ruins are still standing.
local function abbeyWall(parent: Instance, center: Vector3, length: number, arches: boolean)
    local bays = math.max(2, math.floor(length / 8))
    for index = 0, bays - 1 do
        local z = -length * 0.5 + index * (length / bays) + (length / bays) * 0.5
        part(
            parent,
            "AbbeyPier",
            Vector3.new(2.4, 11, 2.4),
            CFrame.new(center + Vector3.new(0, 5.5, z)),
            ABBEY_STONE,
            Enum.Material.Slate
        )
        if arches and index < bays - 1 then
            part(
                parent,
                "AbbeyArchTop",
                Vector3.new(1.8, 2.2, length / bays),
                CFrame.new(center + Vector3.new(0, 10.4, z + (length / bays) * 0.5)),
                ABBEY_STONE,
                Enum.Material.Slate
            )
        end
    end
    part(
        parent,
        "AbbeyFooting",
        Vector3.new(3.4, 1.6, length),
        CFrame.new(center + Vector3.new(0, 0.8, 0)),
        DARK_STONE,
        Enum.Material.Slate
    )
end

--[[
    A bell in a frame. The rope is what makes it a tool rather than an
    ornament -- a bell with its rope cut is the Vale telling a player that
    somebody here wanted silence badly enough to take the option away.
]]
local function abbeyBell(parent: Instance, center: Vector3, roped: boolean)
    for side = -1, 1, 2 do
        part(
            parent,
            "BellPost",
            Vector3.new(0.9, 9, 0.9),
            CFrame.new(center + Vector3.new(side * 2.4, 4.5, 0)),
            TIMBER,
            Enum.Material.Wood
        )
    end
    part(
        parent,
        "BellBeam",
        Vector3.new(6, 0.9, 0.9),
        CFrame.new(center + Vector3.new(0, 9.2, 0)),
        TIMBER,
        Enum.Material.Wood
    )
    -- the bell itself: a cylinder hung mouth-down, so its axis (Size.X)
    -- points at the sky
    local bell = part(
        parent,
        "AbbeyBell",
        Vector3.new(3.4, 3, 3),
        CFrame.new(center + Vector3.new(0, 6.6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(148, 124, 78),
        Enum.Material.Metal
    )
    bell.Shape = Enum.PartType.Cylinder
    if roped then
        part(
            parent,
            "BellRope",
            Vector3.new(0.25, 5.2, 0.25),
            CFrame.new(center + Vector3.new(0, 2.5, 0)),
            Color3.fromRGB(158, 142, 106),
            Enum.Material.Fabric,
            false
        )
    end
end

-- Ice a party can see the floor through, which is the point: thin ice is
-- only a decision if the player can tell it is thin.
local function iceSheet(parent: Instance, center: Vector3, size: number, thin: boolean)
    local sheet = part(
        parent,
        if thin then "ThinIce" else "IceSheet",
        Vector3.new(size, 0.8, size * 0.9),
        CFrame.new(center + Vector3.new(0, 0.6, 0)),
        if thin then ICE else DEEP_ICE,
        Enum.Material.Ice
    )
    sheet.Transparency = if thin then 0.55 else 0.25
    if thin then
        for index = -2, 2 do
            local crack = part(
                parent,
                "IceCrack",
                Vector3.new(size * 0.75, 0.2, 0.35),
                CFrame.new(center + Vector3.new(index * 2.2, 1.05, index * 1.4))
                    * CFrame.Angles(0, math.rad(index * 22), 0),
                Color3.fromRGB(238, 248, 252),
                Enum.Material.Ice,
                false
            )
            crack.CanQuery = false
        end
    end
end

-- A timber shelter, walls and a roof, open on one side. Warming huts,
-- sheds, blinds -- the Vale's smallest promise.
local function shelter(parent: Instance, center: Vector3, width: number, warm: boolean)
    part(
        parent,
        "ShelterFloor",
        Vector3.new(width, 0.8, width * 0.8),
        CFrame.new(center + Vector3.new(0, 1, 0)),
        TIMBER,
        Enum.Material.Wood
    )
    for side = -1, 1, 2 do
        part(
            parent,
            "ShelterWall",
            Vector3.new(0.6, 7, width * 0.8),
            CFrame.new(center + Vector3.new(side * width * 0.5, 4.5, 0)),
            DARK_TIMBER,
            Enum.Material.Wood
        )
    end
    part(
        parent,
        "ShelterBack",
        Vector3.new(width, 7, 0.6),
        CFrame.new(center + Vector3.new(0, 4.5, -width * 0.4)),
        DARK_TIMBER,
        Enum.Material.Wood
    )
    local roof = part(
        parent,
        "ShelterRoof",
        Vector3.new(width + 2, 0.7, width),
        CFrame.new(center + Vector3.new(0, 8.2, 0)) * CFrame.Angles(math.rad(-9), 0, 0),
        TIMBER,
        Enum.Material.Wood
    )
    part(
        parent,
        "RoofSnow",
        Vector3.new(width + 2, 0.7, width),
        roof.CFrame * CFrame.new(0, 0.7, 0),
        SNOW,
        Enum.Material.Snow,
        false
    )
    if warm then
        hearth(parent, center + Vector3.new(0, 1, width * 0.15), true)
    else
        hearth(parent, center + Vector3.new(0, 1, width * 0.15), false)
    end
end

-- Wool on a rack, frozen stiff. The valley's one soft material and its
-- only export.
local function woolRack(parent: Instance, center: Vector3)
    for side = -1, 1, 2 do
        part(
            parent,
            "RackPost",
            Vector3.new(0.7, 6, 0.7),
            CFrame.new(center + Vector3.new(side * 4, 3, 0)),
            DARK_TIMBER,
            Enum.Material.Wood
        )
    end
    part(
        parent,
        "RackBar",
        Vector3.new(9, 0.5, 0.5),
        CFrame.new(center + Vector3.new(0, 6, 0)),
        DARK_TIMBER,
        Enum.Material.Wood
    )
    for index = -1, 1 do
        local fleece = part(
            parent,
            "Fleece",
            Vector3.new(2.6, 3.4, 0.8),
            CFrame.new(center + Vector3.new(index * 3, 4, 0))
                * CFrame.Angles(0, 0, math.rad(index * 4)),
            WOOL,
            Enum.Material.Fabric,
            false
        )
        fleece.CanQuery = false
    end
end

-- A frozen pine. Sparse on purpose: a forest would hide the sightlines
-- the whole region is built on.
local function frozenPine(parent: Instance, center: Vector3, scale: number)
    part(
        parent,
        "PineTrunk",
        Vector3.new(1.2 * scale, 10 * scale, 1.2 * scale),
        CFrame.new(center + Vector3.new(0, 5 * scale, 0)),
        DARK_TIMBER,
        Enum.Material.Wood
    )
    for index = 0, 2 do
        local bough = part(
            parent,
            "PineBough",
            Vector3.new(8 * scale - index * 2, 0.8, 8 * scale - index * 2),
            CFrame.new(center + Vector3.new(0, (5 + index * 2.4) * scale, 0)),
            PINE,
            Enum.Material.Grass,
            false
        )
        bough.CanQuery = false
        local cap = part(
            parent,
            "BoughSnow",
            Vector3.new(8 * scale - index * 2, 0.5, 8 * scale - index * 2),
            bough.CFrame * CFrame.new(0, 0.6, 0),
            SNOW,
            Enum.Material.Snow,
            false
        )
        cap.CanQuery = false
    end
end

-- Light over the ridge. Cold light, and the only thing in the valley that
-- moves without making a sound.
local function auroraRibbon(parent: Instance, center: Vector3, height: number)
    for index = -2, 2 do
        local ribbon = part(
            parent,
            "AuroraRibbon",
            Vector3.new(26, 0.5, 4),
            CFrame.new(center + Vector3.new(index * 3, height + index * 1.6, index * 4))
                * CFrame.Angles(math.rad(index * 5), math.rad(index * 9), math.rad(6)),
            AURORA,
            Enum.Material.Neon,
            false
        )
        ribbon.Transparency = 0.62
        ribbon.CanQuery = false
        ribbon.CastShadow = false
    end
end

-- Prints in the snow, running one way. The Vale's only tracking surface
-- and the third verb of its boss fight.
local function snowTracks(parent: Instance, center: Vector3, yaw: number, count: number)
    for index = 0, count - 1 do
        local step = part(
            parent,
            "SnowTrack",
            Vector3.new(1.6, 0.3, 2.4),
            CFrame.new(center)
                * CFrame.Angles(0, math.rad(yaw), 0)
                * CFrame.new(if index % 2 == 0 then -0.9 else 0.9, 0.7, index * 3.2),
            SHADOW_SNOW,
            Enum.Material.Snow,
            false
        )
        step.CanQuery = false
    end
end

-- Stacked stone, deliberately placed. Cairns are how anybody found their
-- way here before the aurora was the only landmark left.
local function cairn(parent: Instance, center: Vector3)
    for index = 0, 3 do
        part(
            parent,
            "CairnStone",
            Vector3.new(3 - index * 0.5, 1.1, 2.6 - index * 0.4),
            CFrame.new(center + Vector3.new(0, 1 + index * 1.1, 0))
                * CFrame.Angles(0, math.rad(index * 27), 0),
            ABBEY_STONE,
            Enum.Material.Slate
        )
    end
end

-- A rope run between two posts, sagging in the middle.
local function ropeSpan(parent: Instance, center: Vector3, length: number, height: number)
    for side = -1, 1, 2 do
        part(
            parent,
            "SpanPost",
            Vector3.new(1.1, height + 3, 1.1),
            CFrame.new(center + Vector3.new(0, (height + 3) * 0.5, side * length * 0.5)),
            DARK_TIMBER,
            Enum.Material.Wood
        )
    end
    for index = -2, 2 do
        local sag = height - (2 - math.abs(index)) * 0.8
        local line = part(
            parent,
            "SpanRope",
            Vector3.new(0.3, 0.3, length * 0.24),
            CFrame.new(center + Vector3.new(0, sag, index * length * 0.22))
                * CFrame.Angles(math.rad(index * 6), 0, 0),
            Color3.fromRGB(158, 142, 106),
            Enum.Material.Fabric,
            false
        )
        line.CanQuery = false
    end
end

--[[
    Draw one Frostmere module. Returns false for a key this builder has no
    case for, so the coverage spec can tell the difference between a
    module that draws nothing and a module nobody wrote.
]]
function FrostmereBuilder.buildModuleVisual(
    parent: Instance,
    visual: string,
    center: Vector3
): boolean
    if visual == "abbey_gate" then
        valeGround(parent, center)
        -- Arrival: the first thing a party sees is a lit hearth inside a
        -- doorway, which is the whole region's promise and its lie.
        abbeyWall(parent, center + Vector3.new(-7, 0, 0), 30, true)
        abbeyWall(parent, center + Vector3.new(7, 0, 0), 30, true)
        part(
            parent,
            "GateLintel",
            Vector3.new(18, 2.6, 4),
            CFrame.new(center + Vector3.new(0, 11.6, 0)),
            ABBEY_STONE,
            Enum.Material.Slate
        )
        hearth(parent, center + Vector3.new(0, 0, 10), true)
        cairn(parent, center + Vector3.new(-13, 0, 14))
        return true
    elseif visual == "warm_road" then
        valeGround(parent, center)
        -- Extraction. Hearths every few paces, all of them burning: the
        -- one stretch of the Vale that was kept.
        for index = -1, 1 do
            hearth(parent, center + Vector3.new(index * 11, 0, 0), true)
        end
        part(
            parent,
            "RoadBed",
            Vector3.new(34, 0.6, 8),
            CFrame.new(center + Vector3.new(0, 1.1, -7)),
            DARK_STONE,
            Enum.Material.Slate
        )
        cairn(parent, center + Vector3.new(15, 0, -7))
        return true
    elseif visual == "ember_beds" then
        valeGround(parent, center)
        emberMoss(parent, center + Vector3.new(-8, 0, 4), 12)
        emberMoss(parent, center + Vector3.new(7, 0, -6), 14)
        emberMoss(parent, center + Vector3.new(10, 0, 9), 9)
        frozenPine(parent, center + Vector3.new(-14, 0, -10), 0.8)
        return true
    elseif visual == "thaw_quarry" then
        valeGround(parent, center)
        -- Cut faces of ice, worked and abandoned. The risk is that
        -- everything worth taking is at the bottom of a hole.
        for index = -1, 1 do
            local face = part(
                parent,
                "QuarryFace",
                Vector3.new(12, 9 - index * 2, 3),
                CFrame.new(center + Vector3.new(index * 12, 4.5, -6))
                    * CFrame.Angles(0, math.rad(index * 10), 0),
                DEEP_ICE,
                Enum.Material.Ice
            )
            face.Transparency = 0.2
        end
        iceSheet(parent, center + Vector3.new(0, 0, 8), 20, false)
        hearth(parent, center + Vector3.new(-12, 0, 12), false)
        return true
    elseif visual == "wool_sheds" then
        valeGround(parent, center)
        shelter(parent, center + Vector3.new(-9, 0, 0), 14, true)
        woolRack(parent, center + Vector3.new(8, 0, -4))
        woolRack(parent, center + Vector3.new(11, 0, 8))
        return true
    elseif visual == "salt_pans_frozen" then
        valeGround(parent, center)
        for index = -1, 1 do
            local pan = part(
                parent,
                "FrozenSaltPan",
                Vector3.new(13, 1, 10),
                CFrame.new(center + Vector3.new(index * 15, 0.9, index * 3)),
                Color3.fromRGB(206, 214, 220),
                Enum.Material.Ice
            )
            pan.Transparency = 0.15
        end
        -- salt that took the aurora's colour, which nobody has explained
        glow(parent, "SaltShine", center + Vector3.new(0, 2, 0), 1.4, AURORA, 1.2)
        return true
    elseif visual == "ice_cellars" then
        valeGround(parent, center)
        for index = -1, 1 do
            part(
                parent,
                "CellarMouth",
                Vector3.new(7, 6, 5),
                CFrame.new(center + Vector3.new(index * 11, 3, -8)),
                DARK_STONE,
                Enum.Material.Slate
            )
            local dark = part(
                parent,
                "CellarDark",
                Vector3.new(5, 4.4, 1),
                CFrame.new(center + Vector3.new(index * 11, 2.6, -5.4)),
                Color3.fromRGB(16, 18, 22),
                Enum.Material.SmoothPlastic,
                false
            )
            dark.CanQuery = false
        end
        hearth(parent, center + Vector3.new(0, 0, 8), false)
        return true
    elseif visual == "moss_hollow" then
        valeGround(parent, center)
        -- A bowl out of the wind with moss growing in it: the closest
        -- thing to safety the Vale gives away for free.
        for index = 0, 5 do
            part(
                parent,
                "HollowRim",
                Vector3.new(9, 4, 5),
                CFrame.new(center + Vector3.new(0, 2, 0))
                    * CFrame.Angles(0, math.rad(index * 60), 0)
                    * CFrame.new(0, 0, 13),
                SHADOW_SNOW,
                Enum.Material.Snow
            )
        end
        emberMoss(parent, center, 16)
        return true
    elseif visual == "frozen_orchard" then
        valeGround(parent, center)
        for row = -1, 1 do
            for column = -1, 1 do
                frozenPine(
                    parent,
                    center + Vector3.new(column * 11, 0, row * 11),
                    0.7 + ((row + column) % 2) * 0.15
                )
            end
        end
        hearth(parent, center + Vector3.new(0, 0, 16), false)
        return true
    elseif visual == "thin_ice_crossing" then
        valeGround(parent, center)
        iceSheet(parent, center, 30, true)
        cairn(parent, center + Vector3.new(-16, 0, -14))
        cairn(parent, center + Vector3.new(16, 0, 14))
        return true
    elseif visual == "drift_pass" then
        valeGround(parent, center)
        -- Walls of driven snow with one line through them, which is the
        -- Vale's version of a corridor.
        for side = -1, 1, 2 do
            for index = -1, 1 do
                part(
                    parent,
                    "PassDrift",
                    Vector3.new(9, 10 + index * 2, 13),
                    CFrame.new(center + Vector3.new(side * 11, 5, index * 13))
                        * CFrame.Angles(0, math.rad(side * 5), math.rad(side * -4)),
                    SHADOW_SNOW,
                    Enum.Material.Snow
                )
            end
        end
        snowTracks(parent, center + Vector3.new(0, 0, -14), 0, 6)
        return true
    elseif visual == "rope_bridge_gorge" then
        valeGround(parent, center)
        local gorge = part(
            parent,
            "GorgeDark",
            Vector3.new(40, 6, 12),
            CFrame.new(center + Vector3.new(0, -2.5, 0)),
            Color3.fromRGB(20, 24, 30),
            Enum.Material.Slate
        )
        gorge.CanQuery = false
        part(
            parent,
            "BridgePlanks",
            Vector3.new(4, 0.5, 26),
            CFrame.new(center + Vector3.new(0, 1.2, 0)),
            TIMBER,
            Enum.Material.Wood
        )
        ropeSpan(parent, center + Vector3.new(-2.4, 0, 0), 26, 5)
        ropeSpan(parent, center + Vector3.new(2.4, 0, 0), 26, 5)
        return true
    elseif visual == "cloister_walk" then
        valeGround(parent, center)
        abbeyWall(parent, center + Vector3.new(-8, 0, 0), 34, true)
        abbeyWall(parent, center + Vector3.new(8, 0, 0), 34, true)
        part(
            parent,
            "CloisterVault",
            Vector3.new(19, 1.2, 34),
            CFrame.new(center + Vector3.new(0, 11.4, 0)),
            ABBEY_STONE,
            Enum.Material.Slate
        )
        for index = -1, 1 do
            hearth(parent, center + Vector3.new(0, 0, index * 12), index == 0)
        end
        return true
    elseif visual == "whiteout_flat" then
        valeGround(parent, center)
        -- Nothing to see, which is the hazard. One cairn, placed far
        -- enough out that a party has to commit to reaching it.
        for index = -2, 2 do
            local haze = part(
                parent,
                "Whiteout",
                Vector3.new(38, 9, 8),
                CFrame.new(center + Vector3.new(0, 5 + index, index * 8)),
                SNOW,
                Enum.Material.Snow,
                false
            )
            haze.Transparency = 0.82
            haze.CanQuery = false
            haze.CastShadow = false
        end
        cairn(parent, center + Vector3.new(0, 0, 15))
        return true
    elseif visual == "bell_stair" then
        valeGround(parent, center)
        for index = 0, 6 do
            part(
                parent,
                "BellStep",
                Vector3.new(10, 1.4, 4),
                CFrame.new(center + Vector3.new(0, 1 + index * 1.4, -12 + index * 3.4)),
                ABBEY_STONE,
                Enum.Material.Slate
            )
        end
        abbeyBell(parent, center + Vector3.new(0, 10, 12), true)
        return true
    elseif visual == "hush_den" then
        valeGround(parent, center)
        -- Where the pups are kept, and the reason a chapter-V party has
        -- something to decide about the Howler at all.
        part(
            parent,
            "DenMouth",
            Vector3.new(11, 7, 8),
            CFrame.new(center + Vector3.new(0, 3.5, -6)) * CFrame.Angles(0, math.rad(8), 0),
            DARK_STONE,
            Enum.Material.Rock
        )
        local dark = part(
            parent,
            "DenDark",
            Vector3.new(7, 5, 1),
            CFrame.new(center + Vector3.new(0, 3, -2.2)),
            Color3.fromRGB(14, 16, 20),
            Enum.Material.SmoothPlastic,
            false
        )
        dark.CanQuery = false
        emberMoss(parent, center + Vector3.new(0, 0, 4), 8)
        snowTracks(parent, center + Vector3.new(4, 0, 6), 190, 5)
        return true
    elseif visual == "rime_shelf" then
        valeGround(parent, center)
        -- The rime shells fight here, and the fire is the reason a party
        -- can win: the shelf is built around one hearth that still burns.
        iceSheet(parent, center + Vector3.new(-10, 0, -6), 18, false)
        iceSheet(parent, center + Vector3.new(11, 0, 7), 16, false)
        hearth(parent, center, true)
        for index = -1, 1 do
            part(
                parent,
                "RimeSpur",
                Vector3.new(2.2, 7, 2.2),
                CFrame.new(center + Vector3.new(index * 9, 3.5, -12))
                    * CFrame.Angles(math.rad(index * 8), 0, math.rad(index * 6)),
                ICE,
                Enum.Material.Ice
            )
        end
        return true
    elseif visual == "moth_belfry" then
        valeGround(parent, center)
        abbeyWall(parent, center + Vector3.new(-6, 0, 0), 22, false)
        abbeyWall(parent, center + Vector3.new(6, 0, 0), 22, false)
        -- Three bells and none of them roped: the belfry is where the Vale
        -- explains what the bell moths do without saying it.
        abbeyBell(parent, center + Vector3.new(0, 3, -7), false)
        abbeyBell(parent, center + Vector3.new(0, 3, 0), false)
        abbeyBell(parent, center + Vector3.new(0, 3, 7), false)
        return true
    elseif visual == "snowbound_field" then
        valeGround(parent, center)
        -- Trails under the snow that stop, which is the only warning the
        -- snowbound give.
        for index = -1, 1 do
            snowTracks(parent, center + Vector3.new(index * 12, 0, -14), index * 14, 4)
            local mound = part(
                parent,
                "BuriedMound",
                Vector3.new(6, 1.8, 8),
                CFrame.new(center + Vector3.new(index * 12, 1.3, 0))
                    * CFrame.Angles(0, math.rad(index * 12), 0),
                SHADOW_SNOW,
                Enum.Material.Snow,
                false
            )
            mound.CanQuery = false
        end
        hearth(parent, center + Vector3.new(0, 0, 14), false)
        return true
    elseif visual == "borer_undercroft" then
        valeGround(parent, center)
        abbeyWall(parent, center + Vector3.new(0, 0, -10), 26, true)
        -- Floor the borers have been through. Holes with nothing under
        -- them, which is a threat a player understands immediately.
        for index = -1, 1 do
            local bore = part(
                parent,
                "BoreHole",
                Vector3.new(6, 1.4, 6),
                CFrame.new(center + Vector3.new(index * 10, 0.9, index * 5)),
                Color3.fromRGB(16, 18, 22),
                Enum.Material.Slate,
                false
            )
            bore.CanQuery = false
        end
        part(
            parent,
            "FallenPier",
            Vector3.new(2.4, 12, 2.4),
            CFrame.new(center + Vector3.new(6, 2, 8)) * CFrame.Angles(0, 0, math.rad(74)),
            ABBEY_STONE,
            Enum.Material.Slate
        )
        return true
    elseif visual == "snow_lane" then
        valeGround(parent, center)
        for side = -1, 1, 2 do
            part(
                parent,
                "LaneWall",
                Vector3.new(4, 5, 34),
                CFrame.new(center + Vector3.new(side * 10, 2.5, 0)),
                SHADOW_SNOW,
                Enum.Material.Snow
            )
        end
        hearth(parent, center + Vector3.new(0, 0, 12), true)
        return true
    elseif visual == "warming_hut" then
        valeGround(parent, center)
        shelter(parent, center, 16, true)
        woolRack(parent, center + Vector3.new(12, 0, 8))
        return true
    elseif visual == "abbey_arch" then
        valeGround(parent, center)
        abbeyWall(parent, center + Vector3.new(-9, 0, 0), 26, true)
        abbeyWall(parent, center + Vector3.new(9, 0, 0), 26, true)
        part(
            parent,
            "ArchSpan",
            Vector3.new(22, 2.2, 6),
            CFrame.new(center + Vector3.new(0, 11.4, 0)),
            ABBEY_STONE,
            Enum.Material.Slate
        )
        auroraRibbon(parent, center, 26)
        return true
    elseif visual == "wind_break" then
        valeGround(parent, center)
        -- Boards nailed across two piers, against a wind that has been
        -- taking them down for a decade.
        for index = -1, 1 do
            part(
                parent,
                "BreakBoard",
                Vector3.new(24, 3.4, 0.7),
                CFrame.new(center + Vector3.new(0, 3 + index * 3.6, -8))
                    * CFrame.Angles(0, 0, math.rad(index * 2)),
                DARK_TIMBER,
                Enum.Material.Wood
            )
        end
        for side = -1, 1, 2 do
            part(
                parent,
                "BreakPost",
                Vector3.new(1.4, 12, 1.4),
                CFrame.new(center + Vector3.new(side * 12, 6, -8)),
                TIMBER,
                Enum.Material.Wood
            )
        end
        hearth(parent, center + Vector3.new(0, 0, 2), true)
        return true
    elseif visual == "abbot_study" then
        valeGround(parent, center)
        shelter(parent, center, 18, false)
        -- A desk, a dead fire and the letters that name the Vale's
        -- resident. Story rooms here are cold on purpose.
        part(
            parent,
            "StudyDesk",
            Vector3.new(7, 0.6, 3.4),
            CFrame.new(center + Vector3.new(-3, 3.6, -3)),
            DARK_TIMBER,
            Enum.Material.Wood
        )
        for index = -1, 1 do
            local letter = part(
                parent,
                "Letter",
                Vector3.new(1.4, 0.1, 1),
                CFrame.new(center + Vector3.new(-3 + index * 1.6, 4, -3))
                    * CFrame.Angles(0, math.rad(index * 20), 0),
                Color3.fromRGB(224, 216, 196),
                Enum.Material.SmoothPlastic,
                false
            )
            letter.CanQuery = false
        end
        return true
    elseif visual == "refectory" then
        valeGround(parent, center)
        abbeyWall(parent, center + Vector3.new(-10, 0, 0), 28, false)
        abbeyWall(parent, center + Vector3.new(10, 0, 0), 28, false)
        part(
            parent,
            "RefectoryRoof",
            Vector3.new(23, 1.2, 28),
            CFrame.new(center + Vector3.new(0, 11.4, 0)),
            ABBEY_STONE,
            Enum.Material.Slate
        )
        for index = -1, 1 do
            part(
                parent,
                "LongTable",
                Vector3.new(5, 0.7, 18),
                CFrame.new(center + Vector3.new(index * 7, 3.4, 0)),
                TIMBER,
                Enum.Material.Wood
            )
        end
        hearth(parent, center + Vector3.new(0, 0, -12), true)
        return true
    elseif visual == "aurora_shrine" then
        valeGround(parent, center)
        for index = 0, 5 do
            part(
                parent,
                "ShrineStone",
                Vector3.new(2.4, 9 - (index % 3) * 1.6, 2.4),
                CFrame.new(center + Vector3.new(0, 4.5, 0))
                    * CFrame.Angles(0, math.rad(index * 60), 0)
                    * CFrame.new(0, 0, 11),
                ABBEY_STONE,
                Enum.Material.Slate
            )
        end
        glow(parent, "ShrineLight", center + Vector3.new(0, 3, 0), 2.6, AURORA, 2.4)
        auroraRibbon(parent, center, 22)
        return true
    elseif visual == "bell_ropes" then
        valeGround(parent, center)
        -- The puzzle room: bells that can be rung and bells that cannot,
        -- which is the Abbey Silence's fight taught in a quiet place.
        abbeyBell(parent, center + Vector3.new(-9, 0, -5), true)
        abbeyBell(parent, center + Vector3.new(0, 0, 6), false)
        abbeyBell(parent, center + Vector3.new(9, 0, -5), true)
        part(
            parent,
            "RopeFloor",
            Vector3.new(28, 0.6, 24),
            CFrame.new(center + Vector3.new(0, 1.1, 0)),
            ABBEY_STONE,
            Enum.Material.Slate
        )
        return true
    elseif visual == "hearth_locks" then
        valeGround(parent, center)
        -- Four hearths, one lit. The Aurora Hart's fight, taught without
        -- the Hart.
        hearth(parent, center + Vector3.new(0, 0, -11), true)
        hearth(parent, center + Vector3.new(11, 0, 0), false)
        hearth(parent, center + Vector3.new(0, 0, 11), false)
        hearth(parent, center + Vector3.new(-11, 0, 0), false)
        for index = 0, 3 do
            part(
                parent,
                "LockRail",
                Vector3.new(0.6, 1.6, 15),
                CFrame.new(center + Vector3.new(0, 1.6, 0))
                    * CFrame.Angles(0, math.rad(45 + index * 90), 0)
                    * CFrame.new(0, 0, 7.5),
                IRON,
                Enum.Material.Metal
            )
        end
        return true
    elseif visual == "howler_approach" then
        valeGround(parent, center)
        -- The landmark: the bowl the White Howler is fought in, with its
        -- three verbs standing in the world before anything is wired to
        -- them. Things that make noise, hearths to spend, and the aurora
        -- over the ridge that is the only way to follow it.
        for index = 0, 7 do
            part(
                parent,
                "BowlRidge",
                Vector3.new(11, 9 + (index % 3) * 2, 6),
                CFrame.new(center + Vector3.new(0, 4.5, 0))
                    * CFrame.Angles(0, math.rad(index * 45), 0)
                    * CFrame.new(0, 0, 19),
                SHADOW_SNOW,
                Enum.Material.Snow
            )
        end
        abbeyBell(parent, center + Vector3.new(-13, 0, -9), true)
        hearth(parent, center + Vector3.new(0, 0, -6), true)
        hearth(parent, center + Vector3.new(0, 0, 8), false)
        snowTracks(parent, center + Vector3.new(9, 0, -12), 205, 6)
        auroraRibbon(parent, center, 30)
        cairn(parent, center + Vector3.new(14, 0, 12))
        return true
    end
    return false
end

return table.freeze(FrostmereBuilder)
