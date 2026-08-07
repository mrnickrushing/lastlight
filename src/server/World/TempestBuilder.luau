--!strict

--[[
    Tempest Reach's geometry.

    The Delve reads as underground because every module carries a roof.
    The Fen reads as drowned because every module carries water it wants
    you to mistrust. The Reach reads as exposed: every module carries
    something a person built to stand against weather, and the weather is
    winning. Sea walls with pieces out of them, jetties missing planks,
    rigging still strung between hulls nobody will sail again.

    Its light is not warm. Lamps here are signals rather than comforts --
    a beacon, a mast lantern, a storm kite -- and the only colour with any
    heat in it is the amberglass the lightning leaves behind.
]]

local TempestBuilder = {}

local STONE = Color3.fromRGB(88, 92, 96)
local DARK_STONE = Color3.fromRGB(54, 58, 62)
local PLANK = Color3.fromRGB(96, 84, 68)
local DARK_PLANK = Color3.fromRGB(62, 54, 44)
local HULL = Color3.fromRGB(74, 70, 64)
local IRON = Color3.fromRGB(92, 96, 100)
local ROPE = Color3.fromRGB(158, 142, 106)
local SEA = Color3.fromRGB(44, 68, 78)
local FOAM = Color3.fromRGB(206, 220, 224)
local AMBERGLASS = Color3.fromRGB(238, 178, 96)
local SIGNAL = Color3.fromRGB(255, 216, 150)
local KELP = Color3.fromRGB(66, 88, 62)

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
    light.Range = size * 8
    light.Brightness = brightness
    light.Shadows = false
    light.Parent = orb
end

-- Open water, moving enough to read as weather rather than glass. The Fen
-- mirrors; the Reach churns, which is why this is rough and unreflective.
local function seaWater(parent: Instance, center: Vector3, size: number)
    local water = part(
        parent,
        "ReachWater",
        Vector3.new(size, 1, size * 0.9),
        CFrame.new(center + Vector3.new(0, 0.5, 0)),
        SEA,
        Enum.Material.Water,
        false
    )
    water.Transparency = 0.3
    water.CanQuery = false
    for index = -2, 2 do
        local crest = part(
            parent,
            "Whitecap",
            Vector3.new(size * 0.7, 0.5, 2.2),
            CFrame.new(center + Vector3.new(index * 3, 1.1, index * (size * 0.16)))
                * CFrame.Angles(0, math.rad(index * 7), 0),
            FOAM,
            Enum.Material.Neon,
            false
        )
        crest.Transparency = 0.72
        crest.CanQuery = false
    end
end

-- A worked stone edge: sea wall, breakwater, quay. Pieces missing on
-- purpose, because an intact wall on this coast would be a lie.
local function seaWall(parent: Instance, center: Vector3, length: number, seed: number)
    local blocks = math.max(3, math.floor(length / 7))
    for index = 0, blocks - 1 do
        if (seed + index * 13) % 7 ~= 0 then
            local drift = (seed + index * 29) % 5 - 2
            part(
                parent,
                "SeaWallBlock",
                Vector3.new(6.5, 5 + (index % 2), 7),
                CFrame.new(center + Vector3.new(0, 2.5, -length * 0.5 + index * (length / blocks)))
                    * CFrame.Angles(0, math.rad(drift * 3), math.rad(drift)),
                if index % 3 == 0 then DARK_STONE else STONE,
                Enum.Material.Slate
            )
        end
    end
end

-- Decking on piles: the jetty, the quay, the boat shed floor.
local function jettyDeck(parent: Instance, center: Vector3, length: number, width: number)
    part(
        parent,
        "JettyDeck",
        Vector3.new(width, 0.6, length),
        CFrame.new(center + Vector3.new(0, 3, 0)),
        PLANK,
        Enum.Material.Wood
    )
    local piles = math.max(2, math.floor(length / 8))
    for index = 0, piles do
        for side = -1, 1, 2 do
            part(
                parent,
                "JettyPile",
                Vector3.new(0.9, 6, 0.9),
                CFrame.new(
                    center
                        + Vector3.new(
                            side * (width * 0.5 - 1),
                            0.5,
                            -length * 0.5 + index * (length / piles)
                        )
                ),
                DARK_PLANK,
                Enum.Material.Wood
            )
        end
    end
end

-- A hull, aground and open. The Reach's most repeated silhouette.
local function wreckHull(parent: Instance, center: Vector3, heel: number, scale: number)
    local hull = part(
        parent,
        "WreckHull",
        Vector3.new(7 * scale, 6 * scale, 22 * scale),
        CFrame.new(center + Vector3.new(0, 3 * scale, 0)) * CFrame.Angles(0, 0, math.rad(heel)),
        HULL,
        Enum.Material.Wood
    )
    for index = -2, 2 do
        part(
            parent,
            "HullRib",
            Vector3.new(0.6, 5.5 * scale, 0.6),
            hull.CFrame
                * CFrame.new(0, 3 * scale, index * 3.6 * scale)
                * CFrame.Angles(math.rad(index * 4), 0, 0),
            DARK_PLANK,
            Enum.Material.Wood,
            false
        )
    end
    part(
        parent,
        "WreckMast",
        Vector3.new(0.9, 16 * scale, 0.9),
        hull.CFrame * CFrame.new(0, 8 * scale, -2) * CFrame.Angles(math.rad(-12), 0, 0),
        DARK_PLANK,
        Enum.Material.Wood
    )
end

-- Rope between two points, sagging. Rigging, tow lines, signal chains.
local function ropeRun(parent: Instance, from: Vector3, to: Vector3, sag: number)
    local steps = 6
    for index = 0, steps - 1 do
        local a = from:Lerp(to, index / steps)
        local b = from:Lerp(to, (index + 1) / steps)
        local droop = math.sin((index / steps) * math.pi) * sag
        local mid = a:Lerp(b, 0.5) - Vector3.new(0, droop, 0)
        local length = (b - a).Magnitude + 0.4
        part(
            parent,
            "Rope",
            Vector3.new(0.25, 0.25, length),
            CFrame.lookAt(mid, mid + (b - a).Unit),
            ROPE,
            Enum.Material.Fabric,
            false
        )
    end
end

local function signalMast(parent: Instance, position: Vector3, lit: boolean)
    part(
        parent,
        "SignalMast",
        Vector3.new(0.8, 14, 0.8),
        CFrame.new(position + Vector3.new(0, 7, 0)),
        IRON,
        Enum.Material.Metal
    )
    part(
        parent,
        "SignalArm",
        Vector3.new(5, 0.5, 0.5),
        CFrame.new(position + Vector3.new(0, 12.5, 0)),
        IRON,
        Enum.Material.Metal,
        false
    )
    if lit then
        glow(parent, "SignalLamp", position + Vector3.new(0, 13.4, 0), 1.3, SIGNAL, 2.4)
    end
end

-- A grounding rod: the answer to the storm ray and to the Titan's crown.
local function groundingRod(parent: Instance, position: Vector3)
    part(
        parent,
        "GroundingRod",
        Vector3.new(0.5, 9, 0.5),
        CFrame.new(position + Vector3.new(0, 4.5, 0)),
        IRON,
        Enum.Material.Metal
    )
    local plate = part(
        parent,
        "GroundingPlate",
        Vector3.new(0.4, 4, 4),
        CFrame.new(position + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        DARK_STONE,
        Enum.Material.Metal,
        false
    )
    plate.Shape = Enum.PartType.Cylinder
    glow(parent, "RodTip", position + Vector3.new(0, 9.2, 0), 0.7, AMBERGLASS, 1.1)
end

-- Amberglass: sand the lightning fused, warm underfoot after dark.
local function amberglassPatch(parent: Instance, center: Vector3, seed: number)
    for index = 0, 3 do
        local angle = (seed + index * 41) % 360
        local shard = part(
            parent,
            "Amberglass",
            Vector3.new(2.4 - index * 0.3, 0.5, 2.8 - index * 0.3),
            CFrame.new(center + Vector3.new(math.cos(angle) * 2.4, 0.4, math.sin(angle) * 2.4))
                * CFrame.Angles(0, math.rad(angle), math.rad((index % 3) * 4)),
            AMBERGLASS,
            Enum.Material.Glass,
            false
        )
        shard.Transparency = 0.25
        shard.Reflectance = 0.3
    end
    glow(parent, "AmberglassWarmth", center + Vector3.new(0, 0.9, 0), 1.1, AMBERGLASS, 0.9)
end

local function kelpRack(parent: Instance, center: Vector3)
    for side = -1, 1, 2 do
        part(
            parent,
            "RackPost",
            Vector3.new(0.6, 7, 0.6),
            CFrame.new(center + Vector3.new(side * 5, 3.5, 0)),
            DARK_PLANK,
            Enum.Material.Wood
        )
    end
    part(
        parent,
        "RackBeam",
        Vector3.new(11, 0.5, 0.5),
        CFrame.new(center + Vector3.new(0, 7, 0)),
        DARK_PLANK,
        Enum.Material.Wood,
        false
    )
    for index = -2, 2 do
        part(
            parent,
            "HangingKelp",
            Vector3.new(0.7, 5, 0.2),
            CFrame.new(center + Vector3.new(index * 2, 4.2, 0))
                * CFrame.Angles(0, 0, math.rad(index * 3)),
            KELP,
            Enum.Material.Fabric,
            false
        )
    end
end

--[[
    The Reach's ground: wet stone and shingle, with a tide line the
    weather has drawn and redrawn.
]]
local function reachGround(parent: Instance, center: Vector3)
    local ground = part(
        parent,
        "ReachGround",
        Vector3.new(56, 1, 56),
        CFrame.new(center + Vector3.new(0, 0.2, 0)),
        DARK_STONE,
        Enum.Material.Slate,
        false
    )
    ground.CanQuery = false
    local tideLine = part(
        parent,
        "TideLine",
        Vector3.new(56, 0.3, 3),
        CFrame.new(center + Vector3.new(0, 0.8, 8)),
        Color3.fromRGB(102, 96, 74),
        Enum.Material.Sand,
        false
    )
    tideLine.CanQuery = false
end

--[[
    Assemble one module's visual. Unknown keys return false, which is what
    keeps the region honest about being half-built and what the coverage
    spec reads.
]]
function TempestBuilder.buildModuleVisual(
    parent: Instance,
    visual: string,
    center: Vector3
): boolean
    if visual == "harbour_steps" then
        reachGround(parent, center)
        seaWater(parent, center + Vector3.new(0, 0, -16), 30)
        for index = 0, 4 do
            part(
                parent,
                "HarbourStep",
                Vector3.new(20 - index, 1.4, 4),
                CFrame.new(center + Vector3.new(0, 0.9 + index * 1.2, -2 - index * 3.4)),
                STONE,
                Enum.Material.Slate
            )
        end
        signalMast(parent, center + Vector3.new(-11, 0, 6), true)
        return true
    elseif visual == "lee_shore" then
        reachGround(parent, center)
        seaWater(parent, center + Vector3.new(0, 0, -18), 26)
        -- The one place on this coast the wind does not reach: a wall with
        -- its back to the weather, which is what "lee" means and what a
        -- party is looking for by the time they get here.
        seaWall(parent, center + Vector3.new(0, 0, -8), 40, 3)
        jettyDeck(parent, center + Vector3.new(0, 0, 8), 26, 12)
        signalMast(parent, center + Vector3.new(9, 0, 10), true)
        return true
    elseif visual == "salvage_flats" then
        reachGround(parent, center)
        seaWater(parent, center + Vector3.new(0, 0, -20), 22)
        wreckHull(parent, center + Vector3.new(-8, 0, -4), 22, 0.8)
        wreckHull(parent, center + Vector3.new(10, 0, 8), -14, 0.6)
        amberglassPatch(parent, center + Vector3.new(4, 0, -8), 17)
        return true
    elseif visual == "saltworks" then
        reachGround(parent, center)
        for index = -1, 1 do
            local pan = part(
                parent,
                "SaltPan",
                Vector3.new(14, 1, 10),
                CFrame.new(center + Vector3.new(index * 16, 0.8, 0)),
                Color3.fromRGB(196, 196, 186),
                Enum.Material.Sand
            )
            pan.Transparency = 0.05
        end
        seaWall(parent, center + Vector3.new(0, 0, -14), 34, 11)
        return true
    elseif visual == "kelp_racks" then
        reachGround(parent, center)
        seaWater(parent, center + Vector3.new(0, 0, -14), 26)
        kelpRack(parent, center + Vector3.new(-9, 0, 2))
        kelpRack(parent, center + Vector3.new(4, 0, 6))
        kelpRack(parent, center + Vector3.new(13, 0, -2))
        return true
    elseif visual == "amberglass_shoal" then
        reachGround(parent, center)
        seaWater(parent, center + Vector3.new(0, 0, 10), 34)
        for index = -1, 1 do
            amberglassPatch(
                parent,
                center + Vector3.new(index * 9, 0, index % 2 * 6 - 4),
                23 + index
            )
        end
        groundingRod(parent, center + Vector3.new(11, 0, -8))
        return true
    elseif visual == "rope_walk" then
        reachGround(parent, center)
        -- A ropewalk is a long shed: rope is laid, not coiled, and it
        -- needs the length of the building to lay it in.
        jettyDeck(parent, center, 44, 10)
        for side = -1, 1, 2 do
            ropeRun(
                parent,
                center + Vector3.new(side * 4, 6, -20),
                center + Vector3.new(side * 4, 6, 20),
                1.2
            )
        end
        signalMast(parent, center + Vector3.new(-10, 0, -14), false)
        return true
    elseif visual == "storm_glass_beds" then
        reachGround(parent, center)
        for index = -2, 2 do
            amberglassPatch(
                parent,
                center + Vector3.new(index * 7, 0, (index % 2) * 8 - 4),
                31 + index
            )
        end
        groundingRod(parent, center + Vector3.new(0, 0, 12))
        groundingRod(parent, center + Vector3.new(-12, 0, -10))
        return true
    elseif visual == "gull_colony" then
        reachGround(parent, center)
        seaWall(parent, center + Vector3.new(0, 0, -10), 30, 7)
        for index = 0, 6 do
            local angle = index * math.pi * 0.28
            part(
                parent,
                "NestLedge",
                Vector3.new(3, 0.8, 2.4),
                CFrame.new(
                    center
                        + Vector3.new(
                            math.cos(angle) * 11,
                            4 + (index % 3) * 2.4,
                            math.sin(angle) * 8
                        )
                ),
                STONE,
                Enum.Material.Slate,
                false
            )
        end
        return true
    elseif visual == "breakwater_run" then
        reachGround(parent, center)
        seaWater(parent, center + Vector3.new(-16, 0, 0), 24)
        seaWater(parent, center + Vector3.new(16, 0, 0), 24)
        -- The run itself: a broken wall a party crosses with water on
        -- both sides and gaps where blocks have gone.
        seaWall(parent, center, 48, 5)
        return true
    elseif visual == "rigging_climb" then
        reachGround(parent, center)
        wreckHull(parent, center + Vector3.new(-6, 0, 0), 26, 1)
        wreckHull(parent, center + Vector3.new(12, 0, -6), -20, 0.8)
        ropeRun(parent, center + Vector3.new(-6, 14, 0), center + Vector3.new(12, 12, -6), 2.4)
        ropeRun(parent, center + Vector3.new(-6, 10, 4), center + Vector3.new(12, 9, -2), 1.8)
        return true
    elseif visual == "tide_stair" then
        reachGround(parent, center)
        seaWater(parent, center + Vector3.new(0, 0, -16), 28)
        for index = 0, 5 do
            part(
                parent,
                "TideStep",
                Vector3.new(12, 1.2, 3.4),
                CFrame.new(center + Vector3.new(0, 0.8 + index * 1.4, 6 - index * 3.6)),
                if index % 2 == 0 then STONE else DARK_STONE,
                Enum.Material.Slate
            )
        end
        return true
    elseif visual == "gale_crossing" then
        reachGround(parent, center)
        -- Nothing to hide behind and a rail to hold: the module is the
        -- wind, and the rail is the only concession anyone made to it.
        for index = -3, 3 do
            part(
                parent,
                "StormRail",
                Vector3.new(0.5, 4, 0.5),
                CFrame.new(center + Vector3.new(index * 6, 2, 0)),
                IRON,
                Enum.Material.Metal
            )
        end
        ropeRun(parent, center + Vector3.new(-18, 4, 0), center + Vector3.new(18, 4, 0), 0.8)
        seaWater(parent, center + Vector3.new(0, 0, -20), 22)
        return true
    elseif visual == "hull_bridge" then
        reachGround(parent, center)
        seaWater(parent, center, 40)
        -- A hull laid across the gap on purpose, which is the most
        -- Tempest thing anyone here has done.
        wreckHull(parent, center, 90, 1.1)
        jettyDeck(parent, center + Vector3.new(0, 3, 0), 26, 7)
        return true
    elseif visual == "sea_cave_mouth" then
        reachGround(parent, center)
        for side = -1, 1, 2 do
            part(
                parent,
                "CaveJaw",
                Vector3.new(8, 14, 12),
                CFrame.new(center + Vector3.new(side * 10, 7, -8))
                    * CFrame.Angles(0, 0, math.rad(side * 6)),
                DARK_STONE,
                Enum.Material.Rock
            )
        end
        part(
            parent,
            "CaveLintel",
            Vector3.new(26, 5, 12),
            CFrame.new(center + Vector3.new(0, 15, -8)),
            DARK_STONE,
            Enum.Material.Rock,
            false
        )
        amberglassPatch(parent, center + Vector3.new(0, 0, -4), 47)
        return true
    elseif visual == "imp_reef" then
        reachGround(parent, center)
        seaWater(parent, center, 44)
        for index = 0, 5 do
            local angle = index * math.pi / 3
            part(
                parent,
                "ReefTooth",
                Vector3.new(3, 6 + (index % 3) * 2, 3),
                CFrame.new(center + Vector3.new(math.cos(angle) * 12, 3, math.sin(angle) * 12))
                    * CFrame.Angles(math.rad((index % 4) * 5), angle, 0),
                DARK_STONE,
                Enum.Material.Rock
            )
        end
        return true
    elseif visual == "wreck_yard" then
        reachGround(parent, center)
        wreckHull(parent, center + Vector3.new(-11, 0, -6), 30, 0.9)
        wreckHull(parent, center + Vector3.new(3, 0, 8), -24, 1)
        wreckHull(parent, center + Vector3.new(14, 0, -4), 12, 0.7)
        ropeRun(parent, center + Vector3.new(-11, 12, -6), center + Vector3.new(3, 12, 8), 2.2)
        return true
    elseif visual == "grounding_field" then
        reachGround(parent, center)
        for index = 0, 5 do
            local angle = index * math.pi / 3
            groundingRod(
                parent,
                center + Vector3.new(math.cos(angle) * 12, 0, math.sin(angle) * 12)
            )
        end
        amberglassPatch(parent, center, 53)
        return true
    elseif visual == "husk_shallows" then
        reachGround(parent, center)
        seaWater(parent, center, 46)
        for index = -2, 2 do
            part(
                parent,
                "SaltCrust",
                Vector3.new(6, 0.6, 6),
                CFrame.new(center + Vector3.new(index * 7, 1, (index % 2) * 6 - 3)),
                Color3.fromRGB(206, 202, 190),
                Enum.Material.Sand,
                false
            )
        end
        return true
    elseif visual == "breaker_line" then
        reachGround(parent, center)
        seaWater(parent, center + Vector3.new(0, 0, -12), 40)
        seaWall(parent, center + Vector3.new(0, 0, 4), 44, 19)
        for index = -1, 1 do
            part(
                parent,
                "BrokenBlock",
                Vector3.new(7, 4, 7),
                CFrame.new(center + Vector3.new(index * 10, 2, -6))
                    * CFrame.Angles(math.rad(index * 12), math.rad(index * 20), math.rad(8)),
                STONE,
                Enum.Material.Slate
            )
        end
        return true
    elseif visual == "jetty_span" then
        reachGround(parent, center)
        seaWater(parent, center, 44)
        jettyDeck(parent, center, 46, 9)
        return true
    elseif visual == "boat_shed" then
        reachGround(parent, center)
        jettyDeck(parent, center, 24, 14)
        for side = -1, 1, 2 do
            part(
                parent,
                "ShedWall",
                Vector3.new(0.8, 9, 22),
                CFrame.new(center + Vector3.new(side * 7, 7.5, 0)),
                PLANK,
                Enum.Material.Wood
            )
        end
        part(
            parent,
            "ShedRoof",
            Vector3.new(16, 1, 24),
            CFrame.new(center + Vector3.new(0, 12.2, 0)) * CFrame.Angles(math.rad(4), 0, 0),
            DARK_PLANK,
            Enum.Material.Wood,
            false
        )
        return true
    elseif visual == "signal_post" then
        reachGround(parent, center)
        signalMast(parent, center, true)
        signalMast(parent, center + Vector3.new(-12, 0, 6), false)
        ropeRun(parent, center + Vector3.new(0, 12, 0), center + Vector3.new(-12, 12, 6), 1.6)
        return true
    elseif visual == "sea_wall_gate" then
        reachGround(parent, center)
        seaWall(parent, center + Vector3.new(-14, 0, 0), 22, 29)
        seaWall(parent, center + Vector3.new(14, 0, 0), 22, 37)
        for side = -1, 1, 2 do
            part(
                parent,
                "GateLeaf",
                Vector3.new(1, 9, 9),
                CFrame.new(center + Vector3.new(side * 4, 4.5, 0))
                    * CFrame.Angles(0, math.rad(side * 18), 0),
                IRON,
                Enum.Material.DiamondPlate
            )
        end
        return true
    elseif visual == "harbourmaster_office" then
        reachGround(parent, center)
        jettyDeck(parent, center + Vector3.new(0, 0, 6), 18, 16)
        for side = -1, 1, 2 do
            part(
                parent,
                "OfficeWall",
                Vector3.new(0.8, 9, 14),
                CFrame.new(center + Vector3.new(side * 8, 8, 4)),
                PLANK,
                Enum.Material.Wood
            )
        end
        part(
            parent,
            "OfficeBack",
            Vector3.new(16, 9, 0.8),
            CFrame.new(center + Vector3.new(0, 8, -3)),
            PLANK,
            Enum.Material.Wood
        )
        signalMast(parent, center + Vector3.new(10, 0, -6), true)
        return true
    elseif visual == "widows_walk" then
        reachGround(parent, center)
        -- A railed platform on a roof, built for watching a horizon that
        -- has not given anything back.
        part(
            parent,
            "WalkHouse",
            Vector3.new(14, 12, 12),
            CFrame.new(center + Vector3.new(0, 6, 0)),
            PLANK,
            Enum.Material.Wood
        )
        part(
            parent,
            "WalkDeck",
            Vector3.new(10, 0.6, 10),
            CFrame.new(center + Vector3.new(0, 12.4, 0)),
            DARK_PLANK,
            Enum.Material.Wood
        )
        for index = 0, 7 do
            local angle = index * math.pi * 0.25
            part(
                parent,
                "WalkRail",
                Vector3.new(0.4, 3, 0.4),
                CFrame.new(center + Vector3.new(math.cos(angle) * 4.6, 14, math.sin(angle) * 4.6)),
                DARK_PLANK,
                Enum.Material.Wood,
                false
            )
        end
        return true
    elseif visual == "drowned_bell_tower" then
        reachGround(parent, center)
        seaWater(parent, center, 44)
        part(
            parent,
            "TowerShaft",
            Vector3.new(9, 20, 9),
            CFrame.new(center + Vector3.new(0, 9, 0)) * CFrame.Angles(0, 0, math.rad(7)),
            STONE,
            Enum.Material.Slate
        )
        part(
            parent,
            "TowerBell",
            Vector3.new(5, 5, 5),
            CFrame.new(center + Vector3.new(1.4, 17, 0)),
            Color3.fromRGB(122, 108, 78),
            Enum.Material.Metal,
            false
        )
        return true
    elseif visual == "signal_chain_room" then
        reachGround(parent, center)
        jettyDeck(parent, center, 20, 16)
        -- Three lamps in a row, which is what the signal chain event asks
        -- a party to raise in order.
        for index = -1, 1 do
            signalMast(parent, center + Vector3.new(index * 7, 3, -2), index == 0)
        end
        ropeRun(parent, center + Vector3.new(-7, 15, -2), center + Vector3.new(7, 15, -2), 1)
        return true
    elseif visual == "tide_gauge" then
        reachGround(parent, center)
        seaWater(parent, center + Vector3.new(0, 0, -10), 30)
        part(
            parent,
            "GaugeColumn",
            Vector3.new(1.6, 16, 1.6),
            CFrame.new(center + Vector3.new(0, 8, 0)),
            STONE,
            Enum.Material.Slate
        )
        for index = 0, 6 do
            part(
                parent,
                "GaugeMark",
                Vector3.new(3, 0.3, 0.4),
                CFrame.new(center + Vector3.new(0, 2 + index * 2, 1)),
                FOAM,
                Enum.Material.SmoothPlastic,
                false
            )
        end
        for side = -1, 1, 2 do
            part(
                parent,
                "GaugeGate",
                Vector3.new(8, 6, 1),
                CFrame.new(center + Vector3.new(side * 9, 3, -6)),
                IRON,
                Enum.Material.DiamondPlate
            )
        end
        return true
    elseif visual == "titan_approach" then
        reachGround(parent, center)
        seaWater(parent, center + Vector3.new(0, 0, -14), 46)
        -- Where the harbour was. Four wrecks to climb, two rods to earth
        -- the storm, and the gates that lower the tide -- the Titan's three
        -- verbs, standing in the world before the fight is wired to them.
        wreckHull(parent, center + Vector3.new(-14, 0, -4), 28, 1)
        wreckHull(parent, center + Vector3.new(-2, 0, 6), -18, 0.9)
        wreckHull(parent, center + Vector3.new(12, 0, -8), 34, 1.1)
        wreckHull(parent, center + Vector3.new(18, 0, 6), -12, 0.8)
        groundingRod(parent, center + Vector3.new(-8, 0, 12))
        groundingRod(parent, center + Vector3.new(8, 0, 12))
        for side = -1, 1, 2 do
            part(
                parent,
                "TideGate",
                Vector3.new(12, 10, 1.4),
                CFrame.new(center + Vector3.new(side * 16, 5, -18)),
                IRON,
                Enum.Material.DiamondPlate
            )
        end
        signalMast(parent, center + Vector3.new(0, 0, 18), true)
        return true
    end
    return false
end

return table.freeze(TempestBuilder)
