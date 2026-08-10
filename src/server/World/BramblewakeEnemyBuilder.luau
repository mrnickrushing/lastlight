--!strict

local BramblewakeEnemyBuilder = {}

local function part(
    parent: Model,
    name: string,
    size: Vector3,
    offset: Vector3,
    color: Color3,
    material: Enum.Material,
    shape: Enum.PartType?,
    rotation: CFrame?
): Part
    local item = Instance.new("Part")
    item.Name = name
    item.Size = size
    item.CFrame = CFrame.new(offset) * (rotation or CFrame.identity)
    item.Color = color
    item.Material = material
    item.Anchored = true
    item.CanCollide = false
    item.CanQuery = true
    item.CanTouch = false
    item.CastShadow = true
    item.TopSurface = Enum.SurfaceType.Smooth
    item.BottomSurface = Enum.SurfaceType.Smooth
    item.Shape = shape or Enum.PartType.Block
    item.Parent = parent
    return item
end

local function addEye(parent: Model, offset: Vector3, color: Color3)
    part(
        parent,
        "ReadableEye",
        Vector3.new(0.58, 0.58, 0.34),
        offset,
        color,
        Enum.Material.Neon,
        Enum.PartType.Ball,
        nil
    )
end

local function rootling(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "RootCore",
        Vector3.new(4.5, 5.4, 3.4),
        origin,
        Color3.fromRGB(48, 38, 31),
        Enum.Material.Wood,
        Enum.PartType.Ball,
        nil
    )
    part(
        model,
        "MossCrown",
        Vector3.new(5.4, 2.1, 2.6),
        origin + Vector3.new(0, 3.2, 0),
        Color3.fromRGB(51, 78, 54),
        Enum.Material.Grass,
        Enum.PartType.Ball,
        nil
    )
    for side = -1, 1, 2 do
        part(
            model,
            "RootArm",
            Vector3.new(1.1, 5.5, 1.1),
            origin + Vector3.new(side * 2.5, 0.2, 0),
            Color3.fromRGB(65, 48, 37),
            Enum.Material.Wood,
            nil,
            CFrame.Angles(0, 0, math.rad(side * 28))
        )
        addEye(model, origin + Vector3.new(side * 0.72, 0.8, -1.62), Color3.fromRGB(255, 143, 91))
    end
    return core
end

local function briarback(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "BriarbackCore",
        Vector3.new(6.8, 4.2, 7.2),
        origin + Vector3.new(0, 0.4, 0),
        Color3.fromRGB(64, 47, 36),
        Enum.Material.Wood,
        Enum.PartType.Ball,
        nil
    )
    part(
        model,
        "FrontShield",
        Vector3.new(7.8, 5.4, 1.1),
        origin + Vector3.new(0, 0.7, -3.4),
        Color3.fromRGB(47, 68, 50),
        Enum.Material.Slate,
        nil,
        CFrame.Angles(math.rad(-8), 0, 0)
    )
    for side = -1, 1, 2 do
        part(
            model,
            "ShieldTusk",
            Vector3.new(3.3, 0.9, 0.9),
            origin + Vector3.new(side * 2.8, 0.5, -4.5),
            Color3.fromRGB(208, 188, 138),
            Enum.Material.Wood,
            Enum.PartType.Cylinder,
            CFrame.Angles(0, math.rad(90), math.rad(side * 8))
        )
        part(
            model,
            "BriarLeg",
            Vector3.new(1.4, 3.5, 1.4),
            origin + Vector3.new(side * 2.2, -2, 1.6),
            Color3.fromRGB(55, 42, 34),
            Enum.Material.Wood,
            nil,
            CFrame.Angles(0, 0, math.rad(side * 8))
        )
        addEye(model, origin + Vector3.new(side * 1.05, 1.2, -4.02), Color3.fromRGB(255, 196, 99))
    end
    for x = -1, 1, 2 do
        part(
            model,
            "BackThorn",
            Vector3.new(0.8, 3.4, 0.8),
            origin + Vector3.new(x * 1.7, 3, 0.6),
            Color3.fromRGB(97, 72, 43),
            Enum.Material.Wood,
            nil,
            CFrame.Angles(0, 0, math.rad(x * 25))
        )
    end
    return core
end

local function zombie(model: Model, origin: Vector3): Part
    -- A standing, ground-walking silhouette: torso mass, hunched shoulders,
    -- hanging arms, and a forward-tilted head. Only ever seen if the authored
    -- mesh fails to load, so it is built to read as the same creature at
    -- gameplay distance rather than as a different enemy.
    local torsoOrigin = origin + Vector3.new(0, 3.1, 0)
    local core = part(
        model,
        "ZombieTorso",
        Vector3.new(2.5, 3.2, 1.5),
        torsoOrigin,
        Color3.fromRGB(63, 74, 60),
        Enum.Material.Fabric,
        Enum.PartType.Block,
        CFrame.Angles(math.rad(9), 0, 0)
    )
    part(
        model,
        "ZombieRibcage",
        Vector3.new(1.7, 1.5, 0.5),
        torsoOrigin + Vector3.new(0, 0.35, -0.72),
        Color3.fromRGB(206, 200, 182),
        Enum.Material.SmoothPlastic,
        Enum.PartType.Block,
        CFrame.Angles(math.rad(9), 0, 0)
    )
    part(
        model,
        "ZombieCloak",
        Vector3.new(2.9, 2.1, 1.9),
        torsoOrigin + Vector3.new(0, 0.8, 0.24),
        Color3.fromRGB(44, 48, 44),
        Enum.Material.Fabric,
        Enum.PartType.Block,
        CFrame.Angles(math.rad(11), 0, 0)
    )
    part(
        model,
        "ZombieMossPad",
        Vector3.new(1.25, 0.6, 1.2),
        torsoOrigin + Vector3.new(0.72, 1.5, 0.1),
        Color3.fromRGB(74, 104, 66),
        Enum.Material.Grass,
        Enum.PartType.Block,
        CFrame.Angles(0, 0, math.rad(-13))
    )
    local head = part(
        model,
        "ZombieHead",
        Vector3.new(1.25, 1.4, 1.3),
        torsoOrigin + Vector3.new(0, 2.35, -0.28),
        Color3.fromRGB(126, 133, 121),
        Enum.Material.SmoothPlastic,
        Enum.PartType.Block,
        CFrame.Angles(math.rad(17), math.rad(-8), 0)
    )
    for armSide = -1, 1, 2 do
        part(
            model,
            "ZombieArm",
            Vector3.new(0.6, 3.4, 0.6),
            torsoOrigin + Vector3.new(armSide * 1.6, -0.5, -0.35),
            Color3.fromRGB(112, 120, 108),
            Enum.Material.SmoothPlastic,
            Enum.PartType.Block,
            CFrame.Angles(math.rad(-24), 0, math.rad(armSide * 7))
        )
        part(
            model,
            "ZombieLeg",
            Vector3.new(0.72, 3.1, 0.72),
            origin + Vector3.new(armSide * 0.62, 1.55, 0),
            Color3.fromRGB(58, 74, 62),
            Enum.Material.Fabric,
            Enum.PartType.Block,
            CFrame.Angles(0, 0, math.rad(armSide * 3))
        )
    end
    addEye(model, head.Position + Vector3.new(-0.3, 0.12, -0.62), Color3.fromRGB(94, 206, 176))
    addEye(model, head.Position + Vector3.new(0.3, 0.12, -0.62), Color3.fromRGB(94, 206, 176))
    return core
end

local function hollowCrow(model: Model, origin: Vector3): Part
    local hoverOrigin = origin + Vector3.new(0, 5, 0)
    local core = part(
        model,
        "HollowCrowCore",
        Vector3.new(3.6, 3.8, 4.5),
        hoverOrigin,
        Color3.fromRGB(31, 35, 42),
        Enum.Material.Slate,
        Enum.PartType.Ball,
        CFrame.Angles(math.rad(-12), 0, 0)
    )
    for side = -1, 1, 2 do
        part(
            model,
            "CrowWing",
            Vector3.new(7.8, 0.65, 3.4),
            hoverOrigin + Vector3.new(side * 4.2, 0.25, 0.5),
            Color3.fromRGB(42, 47, 55),
            Enum.Material.Slate,
            nil,
            CFrame.Angles(0, math.rad(side * 10), math.rad(side * 12))
        )
        addEye(
            model,
            hoverOrigin + Vector3.new(side * 0.72, 0.65, -2.12),
            Color3.fromRGB(126, 211, 194)
        )
    end
    part(
        model,
        "CrowBeak",
        Vector3.new(1.5, 1.1, 3.3),
        hoverOrigin + Vector3.new(0, 0.1, -3.35),
        Color3.fromRGB(183, 154, 83),
        Enum.Material.Wood,
        nil,
        CFrame.Angles(math.rad(-12), 0, 0)
    )
    part(
        model,
        "StolenSpark",
        Vector3.new(1.1, 1.1, 1.1),
        hoverOrigin + Vector3.new(0, -2.2, 0.2),
        Color3.fromRGB(255, 203, 97),
        Enum.Material.Neon,
        Enum.PartType.Ball,
        nil
    )
    return core
end

local function snapvine(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "SnapvineRoot",
        Vector3.new(4.6, 2.2, 4.6),
        origin,
        Color3.fromRGB(59, 46, 35),
        Enum.Material.Wood,
        Enum.PartType.Ball,
        nil
    )
    part(
        model,
        "VineStem",
        Vector3.new(6.5, 1.8, 1.8),
        origin + Vector3.new(0, 3.6, 0),
        Color3.fromRGB(57, 91, 53),
        Enum.Material.Grass,
        Enum.PartType.Cylinder,
        CFrame.Angles(0, 0, math.rad(90))
    )
    for side = -1, 1, 2 do
        part(
            model,
            "SnapJaw",
            Vector3.new(5.5, 1.5, 4.2),
            origin + Vector3.new(0, 6.2 + side * 0.9, -0.9),
            if side < 0 then Color3.fromRGB(73, 111, 62) else Color3.fromRGB(91, 126, 65),
            Enum.Material.Grass,
            nil,
            CFrame.Angles(math.rad(side * 15), 0, 0)
        )
        addEye(model, origin + Vector3.new(side * 1.2, 6.4, -3), Color3.fromRGB(255, 116, 82))
        for index = 1, 2 do
            part(
                model,
                "JawThorn",
                Vector3.new(0.55, 1.5, 0.55),
                origin + Vector3.new(side * index * 1.25, 6.1, -3.15),
                Color3.fromRGB(221, 205, 151),
                Enum.Material.Wood,
                nil,
                CFrame.Angles(math.rad(70), 0, math.rad(side * 15))
            )
        end
    end
    return core
end

local function barkRam(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "BarkRamCore",
        Vector3.new(7.5, 5.8, 8.4),
        origin + Vector3.new(0, 0.5, 0),
        Color3.fromRGB(65, 49, 38),
        Enum.Material.Wood,
        Enum.PartType.Ball,
        nil
    )
    part(
        model,
        "RamBrow",
        Vector3.new(6.2, 3.6, 3),
        origin + Vector3.new(0, 1.5, -4.1),
        Color3.fromRGB(54, 70, 50),
        Enum.Material.Slate,
        Enum.PartType.Ball,
        nil
    )
    for side = -1, 1, 2 do
        part(
            model,
            "RamHorn",
            Vector3.new(6.2, 1.5, 1.5),
            origin + Vector3.new(side * 3.2, 2.2, -5.1),
            Color3.fromRGB(219, 195, 139),
            Enum.Material.Wood,
            Enum.PartType.Cylinder,
            CFrame.Angles(0, math.rad(90), math.rad(side * 13))
        )
        for front = -1, 1, 2 do
            part(
                model,
                "RamLeg",
                Vector3.new(1.7, 4.2, 1.7),
                origin + Vector3.new(side * 2.45, -2.6, front * 2.35),
                Color3.fromRGB(57, 43, 34),
                Enum.Material.Wood,
                nil,
                CFrame.Angles(0, 0, math.rad(side * 4))
            )
        end
        addEye(model, origin + Vector3.new(side * 1.15, 1.8, -5.38), Color3.fromRGB(255, 152, 91))
    end
    part(
        model,
        "MossBack",
        Vector3.new(6.5, 1.5, 6),
        origin + Vector3.new(0, 3.5, 0.6),
        Color3.fromRGB(62, 91, 55),
        Enum.Material.Grass,
        Enum.PartType.Ball,
        nil
    )
    return core
end

--[[
    The Delve's six. Their silhouettes are deliberately unlike the
    forest's rounded, mossy masses: plated, angular, rail-borne and
    lit from inside. Readability at night comes from a hot interior
    color -- ember, slag, whitedamp green -- rather than from bulk.
]]
local IRON_PLATE = Color3.fromRGB(88, 84, 82)
local IRON_DARK = Color3.fromRGB(54, 50, 49)
local EMBER = Color3.fromRGB(255, 126, 48)
local SLAG = Color3.fromRGB(255, 168, 66)
local WHITEDAMP = Color3.fromRGB(158, 226, 138)
local ECHO_BLUE = Color3.fromRGB(126, 176, 214)

local function cinderMite(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "MiteShell",
        Vector3.new(3.2, 2.2, 3.8),
        origin,
        IRON_DARK,
        Enum.Material.Metal,
        Enum.PartType.Ball,
        nil
    )
    part(
        model,
        "EmberVent",
        Vector3.new(1.9, 0.9, 2.4),
        origin + Vector3.new(0, 1.2, 0.3),
        EMBER,
        Enum.Material.Neon,
        Enum.PartType.Ball,
        nil
    )
    for side = -1, 1, 2 do
        for pair = -1, 1, 2 do
            part(
                model,
                "MiteLeg",
                Vector3.new(0.32, 2.2, 0.32),
                origin + Vector3.new(side * 1.5, -1, pair * 1.1),
                IRON_PLATE,
                Enum.Material.Metal,
                nil,
                CFrame.Angles(0, 0, math.rad(side * 24))
            )
        end
        addEye(model, origin + Vector3.new(side * 0.6, 0.5, -1.85), EMBER)
    end
    return core
end

local function railHound(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "HoundChassis",
        Vector3.new(2.6, 2.4, 6.4),
        origin,
        IRON_PLATE,
        Enum.Material.DiamondPlate,
        nil,
        nil
    )
    part(
        model,
        "HoundSnout",
        Vector3.new(1.8, 1.6, 2.2),
        origin + Vector3.new(0, 0.2, -4),
        IRON_DARK,
        Enum.Material.Metal,
        nil,
        nil
    )
    part(
        model,
        "SparkTrail",
        Vector3.new(1.2, 0.5, 3.4),
        origin + Vector3.new(0, -1.2, 2.6),
        EMBER,
        Enum.Material.Neon,
        nil,
        nil
    )
    --[[
        A cylinder's axis runs along its Size.X, and Y/Z are its diameters.
        These wheels were sized as though the axis were Y and then turned
        a quarter turn on top of it, which buried them inside the chassis:
        seen in Studio the hound was a floating plank with an ember streak.
        The axle now runs left to right, which is the only way a wheel on
        a rail can run, and four short legs put a creature under it.
    ]]
    for side = -1, 1, 2 do
        for pair = -1, 1, 2 do
            part(
                model,
                "HoundWheel",
                Vector3.new(0.5, 1.6, 1.6),
                origin + Vector3.new(side * 1.5, -1.3, pair * 2),
                IRON_DARK,
                Enum.Material.Metal,
                Enum.PartType.Cylinder,
                nil
            )
            part(
                model,
                "HoundLeg",
                Vector3.new(0.4, 1.6, 0.4),
                origin + Vector3.new(side * 1.05, -1, pair * 2),
                IRON_PLATE,
                Enum.Material.Metal,
                nil,
                CFrame.Angles(0, 0, math.rad(side * 14))
            )
        end
        addEye(model, origin + Vector3.new(side * 0.5, 0.7, -4.9), EMBER)
    end
    return core
end

local function slagSpitter(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "SpitterBase",
        Vector3.new(4.4, 3.6, 4.4),
        origin,
        IRON_DARK,
        Enum.Material.Slate,
        nil,
        nil
    )
    part(
        model,
        "SpitterMouth",
        Vector3.new(2.4, 2.4, 2.4),
        origin + Vector3.new(0, 2.4, -1.6),
        SLAG,
        Enum.Material.Neon,
        Enum.PartType.Ball,
        nil
    )
    for side = -1, 1, 2 do
        part(
            model,
            "SpitterRib",
            Vector3.new(0.7, 4.6, 0.7),
            origin + Vector3.new(side * 2.2, 0.8, 0.6),
            IRON_PLATE,
            Enum.Material.Metal,
            nil,
            CFrame.Angles(math.rad(12), 0, math.rad(side * -10))
        )
    end
    -- Same cylinder-axis error as the hound's wheels, and far louder: in
    -- Studio this pool stood as a glowing bar straight up through the
    -- spitter. Thickness belongs on the axis (X), width on the diameters.
    part(
        model,
        "SlagPool",
        Vector3.new(0.4, 5.6, 5.6),
        origin + Vector3.new(0, -1.9, 0),
        SLAG,
        Enum.Material.Neon,
        Enum.PartType.Cylinder,
        CFrame.Angles(0, 0, math.rad(90))
    )
    return core
end

local function shiftEcho(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "EchoTorso",
        Vector3.new(2.4, 3.4, 1.6),
        origin + Vector3.new(0, 0.6, 0),
        ECHO_BLUE,
        Enum.Material.Glass,
        nil,
        nil
    )
    core.Transparency = 0.35
    local head = part(
        model,
        "EchoHead",
        Vector3.new(1.3, 1.4, 1.3),
        origin + Vector3.new(0, 3, 0),
        ECHO_BLUE,
        Enum.Material.Glass,
        nil,
        nil
    )
    head.Transparency = 0.35
    part(
        model,
        "EchoLamp",
        Vector3.new(0.7, 0.9, 0.7),
        origin + Vector3.new(1.4, 1.6, -0.6),
        WHITEDAMP,
        Enum.Material.Neon,
        nil,
        nil
    )
    for side = -1, 1, 2 do
        local arm = part(
            model,
            "EchoArm",
            Vector3.new(0.6, 2.8, 0.6),
            origin + Vector3.new(side * 1.5, 0.8, -0.4),
            ECHO_BLUE,
            Enum.Material.Glass,
            nil,
            CFrame.Angles(math.rad(side * 34), 0, 0)
        )
        arm.Transparency = 0.45
        addEye(model, origin + Vector3.new(side * 0.35, 3.1, -0.72), WHITEDAMP)
    end
    return core
end

local function crankGuard(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "GuardFrame",
        Vector3.new(5.2, 4.6, 3.6),
        origin + Vector3.new(0, 0.6, 0),
        IRON_PLATE,
        Enum.Material.DiamondPlate,
        nil,
        nil
    )
    part(
        model,
        "FrontPlate",
        Vector3.new(6.4, 5.2, 0.9),
        origin + Vector3.new(0, 0.9, -2.4),
        IRON_DARK,
        Enum.Material.Metal,
        nil,
        CFrame.Angles(math.rad(-6), 0, 0)
    )
    -- The exposed mechanism: the reason a flank strike lands for five
    -- times what the plate allows, and it must read from behind.
    part(
        model,
        "ExposedMechanism",
        Vector3.new(1, 2.6, 2.6),
        origin + Vector3.new(0, 1, 2.1),
        EMBER,
        Enum.Material.Neon,
        Enum.PartType.Cylinder,
        CFrame.Angles(0, math.rad(90), 0)
    )
    for side = -1, 1, 2 do
        part(
            model,
            "GuardLeg",
            Vector3.new(1.3, 3.2, 1.3),
            origin + Vector3.new(side * 2, -2.2, 0.4),
            IRON_DARK,
            Enum.Material.Metal,
            nil,
            nil
        )
        addEye(model, origin + Vector3.new(side * 1, 2.2, -2.9), EMBER)
    end
    return core
end

local function gasBloomer(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "BloomerBulb",
        Vector3.new(4.2, 4.2, 4.2),
        origin + Vector3.new(0, 0.8, 0),
        Color3.fromRGB(72, 88, 64),
        Enum.Material.Slate,
        Enum.PartType.Ball,
        nil
    )
    --[[
        Petals lean up and out from the bulb. Pitching each one before its
        yaw made all five settle into the same plane, so in Studio the
        bloom read as a flat saucer hanging over a shrub. Yaw first, then
        pitch, and the flower opens.
    ]]
    for index = 0, 4 do
        local angle = index * math.pi * 0.4
        part(
            model,
            "BloomPetal",
            Vector3.new(1.6, 0.4, 2.8),
            origin + Vector3.new(math.cos(angle) * 1.5, 3.1, math.sin(angle) * 1.5),
            WHITEDAMP,
            Enum.Material.Neon,
            nil,
            CFrame.Angles(0, -angle, 0) * CFrame.Angles(math.rad(-52), 0, 0)
        )
    end
    local haze = part(
        model,
        "Whitedamp",
        Vector3.new(7.5, 2.6, 7.5),
        origin + Vector3.new(0, -0.6, 0),
        WHITEDAMP,
        Enum.Material.Neon,
        Enum.PartType.Ball,
        nil
    )
    haze.Transparency = 0.72
    addEye(model, origin + Vector3.new(0, 1.4, -2.1), EMBER)
    return core
end

--[[
    The Fen's six. Where the Delve reads by heat, the Fen reads by water:
    pale glass, wet reed, and cold witchlight. Several of them are
    deliberately half-hidden shapes -- a heron that is mostly stillness, a
    lurker that is mostly reeds -- so the outline highlight is doing more
    work here than the geometry, which is the point of the place.
]]
local REED_GREEN = Color3.fromRGB(74, 96, 66)
local BOG_DARK = Color3.fromRGB(46, 54, 48)
local MIRROR_PALE = Color3.fromRGB(186, 206, 210)
local WITCHLIGHT = Color3.fromRGB(146, 214, 226)
local LEECH_RED = Color3.fromRGB(120, 52, 58)

local function reedLurker(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "LurkerBody",
        Vector3.new(3.6, 2.4, 6),
        origin,
        BOG_DARK,
        Enum.Material.Slate,
        nil,
        nil
    )
    for index = -2, 2 do
        part(
            model,
            "ReedFrond",
            Vector3.new(0.24, 5.5, 0.24),
            origin + Vector3.new(index * 0.9, 2.4, index * 0.5),
            REED_GREEN,
            Enum.Material.Grass,
            nil,
            CFrame.Angles(math.rad(index * 7), 0, math.rad(index * 9))
        )
    end
    for side = -1, 1, 2 do
        addEye(model, origin + Vector3.new(side * 0.7, 1.3, -2.7), WITCHLIGHT)
    end
    return core
end

local function mirrorling(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "MirrorTorso",
        Vector3.new(2.6, 4, 1.4),
        origin + Vector3.new(0, 0.8, 0),
        MIRROR_PALE,
        Enum.Material.Glass,
        nil,
        nil
    )
    core.Reflectance = 0.55
    local head = part(
        model,
        "MirrorHead",
        Vector3.new(1.4, 1.5, 1.4),
        origin + Vector3.new(0, 3.5, 0),
        MIRROR_PALE,
        Enum.Material.Glass,
        Enum.PartType.Ball,
        nil
    )
    head.Reflectance = 0.55
    for side = -1, 1, 2 do
        local arm = part(
            model,
            "MirrorArm",
            Vector3.new(0.6, 3, 0.6),
            origin + Vector3.new(side * 1.7, 0.9, 0),
            MIRROR_PALE,
            Enum.Material.Glass,
            nil,
            CFrame.Angles(0, 0, math.rad(side * 10))
        )
        arm.Reflectance = 0.4
        addEye(model, origin + Vector3.new(side * 0.36, 3.6, -0.76), WITCHLIGHT)
    end
    return core
end

local function mireLeech(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "LeechBody",
        Vector3.new(1.8, 1.6, 5.2),
        origin,
        LEECH_RED,
        Enum.Material.Neon,
        Enum.PartType.Ball,
        nil
    )
    core.Transparency = 0.25
    for index = -1, 1 do
        part(
            model,
            "LeechSegment",
            Vector3.new(1.5, 1.4, 1.4),
            origin + Vector3.new(0, 0.1, index * 1.5),
            BOG_DARK,
            Enum.Material.Slate,
            Enum.PartType.Ball,
            nil
        )
    end
    part(
        model,
        "LeechMouth",
        Vector3.new(0.7, 1.1, 1.1),
        origin + Vector3.new(0, 0, -2.7),
        LEECH_RED,
        Enum.Material.Neon,
        Enum.PartType.Cylinder,
        CFrame.Angles(0, math.rad(90), 0)
    )
    return core
end

local function falseFriend(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "FriendTorso",
        Vector3.new(2.4, 3.6, 1.5),
        origin + Vector3.new(0, 0.8, 0),
        Color3.fromRGB(96, 84, 72),
        Enum.Material.Fabric,
        nil,
        nil
    )
    part(
        model,
        "FriendHead",
        Vector3.new(1.3, 1.4, 1.3),
        origin + Vector3.new(0, 3.2, 0),
        Color3.fromRGB(150, 148, 132),
        Enum.Material.SmoothPlastic,
        nil,
        nil
    )
    -- The tell: it carries a lantern that gives no light, and its hands
    -- are on backwards. Readability by wrongness, not by glow.
    local lantern = part(
        model,
        "DeadLantern",
        Vector3.new(0.8, 1, 0.8),
        origin + Vector3.new(1.6, 1.8, -0.6),
        Color3.fromRGB(58, 62, 56),
        Enum.Material.Metal,
        nil,
        nil
    )
    lantern.Reflectance = 0.1
    for side = -1, 1, 2 do
        part(
            model,
            "BackwardHand",
            Vector3.new(0.6, 0.6, 0.9),
            origin + Vector3.new(side * 1.5, 0.7, 0.5),
            Color3.fromRGB(150, 148, 132),
            Enum.Material.SmoothPlastic,
            nil,
            CFrame.Angles(0, math.rad(180), 0)
        )
        addEye(model, origin + Vector3.new(side * 0.34, 3.3, -0.72), WITCHLIGHT)
    end
    return core
end

local function glassHeron(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "HeronBody",
        Vector3.new(1.8, 2.2, 3.4),
        origin + Vector3.new(0, 3.2, 0),
        MIRROR_PALE,
        Enum.Material.Glass,
        Enum.PartType.Ball,
        nil
    )
    core.Reflectance = 0.4
    part(
        model,
        "HeronNeck",
        Vector3.new(0.5, 3.4, 0.5),
        origin + Vector3.new(0, 5.2, -0.8),
        MIRROR_PALE,
        Enum.Material.Glass,
        nil,
        CFrame.Angles(math.rad(14), 0, 0)
    )
    part(
        model,
        "HeronBeak",
        Vector3.new(0.32, 0.32, 3.4),
        origin + Vector3.new(0, 6.6, -2.6),
        WITCHLIGHT,
        Enum.Material.Neon,
        nil,
        CFrame.Angles(math.rad(-8), 0, 0)
    )
    for side = -1, 1, 2 do
        part(
            model,
            "HeronLeg",
            Vector3.new(0.3, 4.4, 0.3),
            origin + Vector3.new(side * 0.5, 0.9, 0.2),
            BOG_DARK,
            Enum.Material.Slate,
            nil,
            nil
        )
        addEye(model, origin + Vector3.new(side * 0.32, 6.5, -1.6), WITCHLIGHT)
    end
    return core
end

local function bogBell(model: Model, origin: Vector3): Part
    local core = part(
        model,
        "BellBody",
        Vector3.new(4.4, 4.4, 4.4),
        origin + Vector3.new(0, 3.4, 0),
        Color3.fromRGB(104, 96, 74),
        Enum.Material.Metal,
        Enum.PartType.Ball,
        nil
    )
    part(
        model,
        "BellPost",
        Vector3.new(0.7, 6.4, 0.7),
        origin + Vector3.new(0, 3.2, 1.6),
        BOG_DARK,
        Enum.Material.Wood,
        nil,
        nil
    )
    part(
        model,
        "BellClapper",
        Vector3.new(0.9, 1.6, 0.9),
        origin + Vector3.new(0, 1.4, 0),
        WITCHLIGHT,
        Enum.Material.Neon,
        Enum.PartType.Ball,
        nil
    )
    -- Marks burned into the ground the bell summons through. Sized on the
    -- wrong cylinder axis they stood up as four floating bars around it.
    for index = 0, 3 do
        local angle = index * math.pi * 0.5
        part(
            model,
            "SummonMark",
            Vector3.new(0.2, 1.6, 1.6),
            origin + Vector3.new(math.cos(angle) * 4, 0.1, math.sin(angle) * 4),
            WITCHLIGHT,
            Enum.Material.Neon,
            Enum.PartType.Cylinder,
            CFrame.Angles(0, 0, math.rad(90))
        )
    end
    return core
end

function BramblewakeEnemyBuilder.build(definition: any, origin: Vector3, target: Vector3): Model
    local model = Instance.new("Model")
    model.Name = definition.displayName:gsub("%s+", "")
    model:SetAttribute("EnemyId", definition.id)
    model:SetAttribute("EnemyDisplayName", definition.displayName)
    model:SetAttribute("EnemyHealth", definition.health)
    model:SetAttribute("EnemyMaxHealth", definition.health)

    local core: Part
    if definition.modelKey == "briarback" then
        core = briarback(model, origin)
    elseif definition.modelKey == "zombie" then
        core = zombie(model, origin)
    elseif definition.modelKey == "hollow_crow" then
        core = hollowCrow(model, origin)
    elseif definition.modelKey == "snapvine" then
        core = snapvine(model, origin)
    elseif definition.modelKey == "bark_ram" then
        core = barkRam(model, origin)
    elseif definition.modelKey == "cinder_mite" then
        core = cinderMite(model, origin)
    elseif definition.modelKey == "rail_hound" then
        core = railHound(model, origin)
    elseif definition.modelKey == "slag_spitter" then
        core = slagSpitter(model, origin)
    elseif definition.modelKey == "shift_echo" then
        core = shiftEcho(model, origin)
    elseif definition.modelKey == "crank_guard" then
        core = crankGuard(model, origin)
    elseif definition.modelKey == "gas_bloomer" then
        core = gasBloomer(model, origin)
    elseif definition.modelKey == "reed_lurker" then
        core = reedLurker(model, origin)
    elseif definition.modelKey == "mirrorling" then
        core = mirrorling(model, origin)
    elseif definition.modelKey == "mire_leech" then
        core = mireLeech(model, origin)
    elseif definition.modelKey == "false_friend" then
        core = falseFriend(model, origin)
    elseif definition.modelKey == "glass_heron" then
        core = glassHeron(model, origin)
    elseif definition.modelKey == "bog_bell" then
        core = bogBell(model, origin)
    else
        core = rootling(model, origin)
    end
    model.PrimaryPart = core

    local highlight = Instance.new("Highlight")
    -- The outline is the enemy's readability, not decoration: at night, a dark
    -- creature against dark forest was disappearing entirely. A fully opaque
    -- rim and a little more body tint make the silhouette legible without
    -- lighting the world or showing enemies through terrain -- Occluded is
    -- kept deliberately so nothing is visible through geometry.
    highlight.Name = "ThreatOutline"
    -- Enough to find them in the dark, not so much that they become
    -- featureless cut-outs. A fully opaque rim over a heavy fill turned every
    -- creature into a black silhouette with a white edge, which lost the
    -- shapes the enemy roster relies on for readability.
    highlight.FillColor = Color3.fromRGB(104, 42, 38)
    highlight.FillTransparency = 0.82
    highlight.OutlineColor = Color3.fromRGB(255, 178, 132)
    highlight.OutlineTransparency = 0.3
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = model

    --[[
        The outline's other half, and the one that was still missing: the
        owner reported enemies as "invisible with a red line around them"
        rather than solid, and a live Studio check found exactly that --
        the outline above, alone, on a creature with nothing left to see.

        Every authored enemy mesh is a PBR SurfaceAppearance MeshPart
        (`preserveSourceMaterials = true` in MeshAssetRegistry, so its own
        color/normal/roughness maps carry the look). Measured directly:
        that surface renders correctly under the day sun, and renders
        solid black at night NO MATTER how bright `Lighting.Ambient` or
        `OutdoorAmbient` is set -- pushing both to pure white changed
        nothing. Those two properties light the plain Wood/Grass/Plastic
        fallback parts below fine (that is why the fallback silhouette was
        never the complaint), but a PBR SurfaceAppearance mesh is lit by
        real light sources, not the flat ambient fill, and past the sun's
        night hours there was no other light source is on the creature
        at all -- only the Highlight's outline, which is a screen overlay
        and was never dependent on scene lighting to begin with. That gap
        between "the outline still shows" and "the mesh needs a real
        light and has none" is the whole bug.

        A point light fixes it, confirmed the same way: adding one at a
        workable brightness turned the same black cutout back into the same
        lit, textured creature the day sun already proves this mesh can look
        like -- with one catch measured on the way there. Parented dead
        centre in `core`, the light worked on the rootling and did nothing
        at all on the briarback even cranked far past a sane brightness: a
        point light buried inside a wide enough body has no line of sight to
        its own outward-facing surface, so the light exists and the creature
        stays black regardless of how bright it is. Anchored just above the
        creature instead -- clear of every species' own volume, the same way
        a torch is held above what it lights rather than embedded in it --
        it reached both.

        The anchor is a fresh Part rather than a light directly on `core`
        for that reason, and scaled off `core.Size.Y` rather than a fixed
        offset so a tall species (or a short one) still clears its own body.
    ]]
    local threatGlowAnchor = Instance.new("Part")
    threatGlowAnchor.Name = "ThreatGlowAnchor"
    threatGlowAnchor.Anchored = true
    threatGlowAnchor.CanCollide = false
    threatGlowAnchor.CanTouch = false
    threatGlowAnchor.CanQuery = false
    threatGlowAnchor.CastShadow = false
    threatGlowAnchor.Transparency = 1
    threatGlowAnchor.Massless = true
    threatGlowAnchor.Size = Vector3.new(0.2, 0.2, 0.2)
    threatGlowAnchor.CFrame = core.CFrame * CFrame.new(0, core.Size.Y / 2 + 2, 0)
    threatGlowAnchor.Parent = model

    local threatGlow = Instance.new("PointLight")
    threatGlow.Name = "ThreatGlow"
    threatGlow.Color = highlight.OutlineColor
    threatGlow.Brightness = 6
    threatGlow.Range = 22
    threatGlow.Shadows = false
    threatGlow.Parent = threatGlowAnchor

    --[[
        Tap the creature to hit it.

        Combat used to require finding a STRIKE button while a telegraph was
        winding up. Putting the control on the enemy itself makes attacking
        the same gesture as everything else in the game, and it aims: the
        server still resolves range and damage, so this only decides which
        creature the player meant.
    ]]
    -- Parented to the model, not the core: a ClickDetector on a Model fires
    -- for a tap on ANY descendant BasePart, not just the (often small,
    -- moving) core. A fast flier like the crow reads several studs wider
    -- than its core across wings and beak; without this, every one of those
    -- taps silently missed.
    --[[
        A tap target big enough to actually hit on a phone.

        A ClickDetector only fires when the tap ray lands on a part that
        answers raycasts, and once the authored mesh loads there is almost
        nothing left that does: MeshTemplateLoader.sanitize clears CanQuery on
        every part of a loaded model (measured: 0 of 1 queryable on the
        rootling), and placeEnemyVisual clears it on every fallback part but
        the core. So the creature a player can SEE answers no taps at all, and
        the only thing that does is one invisible box roughly the size of the
        body -- which on a phone sits behind the threat banner and the lantern
        rail. The result was a night defense that could not be fought.

        This is the same generous invisible volume every other interaction in
        the game already uses, sized past the silhouette so a thumb aimed at
        the creature lands. It is CanCollide = false so it never changes
        movement or the fight's geometry, and the server still resolves range,
        facing, cover, and damage -- a tap only says which creature was meant.
    ]]
    local strikeVolume = Instance.new("Part")
    strikeVolume.Name = "StrikeVolume"
    strikeVolume.Size = Vector3.new(
        math.max(9, core.Size.X + 5),
        math.max(10, core.Size.Y + 4),
        math.max(9, core.Size.Z + 5)
    )
    strikeVolume.CFrame = CFrame.new(core.Position)
    strikeVolume.Anchored = true
    strikeVolume.CanCollide = false
    strikeVolume.CanTouch = false
    strikeVolume.CanQuery = true
    strikeVolume.CastShadow = false
    strikeVolume.Transparency = 1
    strikeVolume.Massless = true
    strikeVolume:SetAttribute("EnemyStrikeVolume", true)
    strikeVolume.Parent = model

    local click = Instance.new("ClickDetector")
    click.Name = "StrikeClick"
    click.MaxActivationDistance = 42
    click.CursorIcon = ""
    click.Parent = model

    local flatTarget = Vector3.new(target.X, core.Position.Y, target.Z)
    if (flatTarget - core.Position).Magnitude > 0.01 then
        model:PivotTo(CFrame.lookAt(core.Position, flatTarget))
    end
    return model
end

return table.freeze(BramblewakeEnemyBuilder)
