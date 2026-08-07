--!strict

--[[
    Cinderfall Crown's geometry.

    The Vale is drawn by absence -- a hearth that is out says more than an
    empty room. The Crown is drawn by presence: every module carries
    something that is still in the middle of doing what it was doing when
    the fire arrived. A parade still on its route, a crowd still facing
    the stage, a kiln still firing a cast that nobody is coming back for.

    So the load-bearing shape here is the figure. Casts stand everywhere,
    and the builder makes two kinds on purpose: performing ones, which
    face the stage and are posed, and authentic ones, which face wherever
    they happened to be facing and are not. A player learns that
    difference by walking past a hundred of them, and the Ash Regent's
    fight is the exam.

    Its palette inverts the Vale's on purpose. Frostmere's warm light was
    safety; here the lit things are the ones still producing false work
    and the cold ones are where the truth got to stop, so the kilns glow
    and the honest rooms are grey.
]]

local CinderfallBuilder = {}

local ASH = Color3.fromRGB(148, 142, 134)
local DARK_ASH = Color3.fromRGB(96, 92, 88)
local SOOT = Color3.fromRGB(52, 48, 46)
local CAST = Color3.fromRGB(176, 168, 156)
local TRUE_CAST = Color3.fromRGB(122, 118, 112)
local GLASS = Color3.fromRGB(180, 196, 206)
local MEMORY_GLASS = Color3.fromRGB(206, 168, 214)
local KILN_BRICK = Color3.fromRGB(128, 74, 54)
local FIRE = Color3.fromRGB(255, 148, 62)
local CINDERSTEEL = Color3.fromRGB(112, 104, 96)
local SILK = Color3.fromRGB(214, 190, 158)
local COLD_WATER = Color3.fromRGB(78, 106, 116)
local CROWN_GOLD = Color3.fromRGB(214, 172, 88)

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

local function crownGround(parent: Instance, center: Vector3)
    part(parent, "CrownGround", Vector3.new(40, 1, 40), CFrame.new(center), ASH, Enum.Material.Sand)
    for index = -1, 1 do
        local drift = part(
            parent,
            "AshDrift",
            Vector3.new(28 - index * 4, 1.6, 8),
            CFrame.new(center + Vector3.new(index * 6, 0.9, index * 11))
                * CFrame.Angles(0, math.rad(index * 8), 0),
            DARK_ASH,
            Enum.Material.Sand,
            false
        )
        drift.CanQuery = false
    end
end

--[[
    The region in one primitive. A performing cast is posed and faces the
    stage; an authentic one is not posed and faces wherever the person was
    actually looking. Casts also carry a mold seam down one side, which is
    the tell the events ask a player to find, so it is drawn rather than
    described.
]]
local function figure(parent: Instance, center: Vector3, yaw: number, performing: boolean)
    local base = CFrame.new(center) * CFrame.Angles(0, math.rad(yaw), 0)
    local color = if performing then CAST else TRUE_CAST
    part(
        parent,
        if performing then "CastFigure" else "TrueFigure",
        Vector3.new(1.9, 4.4, 1.2),
        base * CFrame.new(0, 3, 0),
        color,
        Enum.Material.Sandstone
    )
    part(
        parent,
        "FigureHead",
        Vector3.new(1.1, 1.2, 1.1),
        base * CFrame.new(0, 5.7, 0),
        color,
        Enum.Material.Sandstone,
        false
    )
    -- the arms say which kind it is: raised in the gesture it was cast
    -- mid-way through, or down, doing nothing, because nobody posed it
    for side = -1, 1, 2 do
        local pitch = if performing then math.rad(-55) else math.rad(-6)
        part(
            parent,
            "FigureArm",
            Vector3.new(0.5, 2.4, 0.5),
            base * CFrame.new(side * 1.2, 4, 0) * CFrame.Angles(pitch, 0, math.rad(side * 8)),
            color,
            Enum.Material.Sandstone,
            false
        )
    end
    if performing then
        local seam = part(
            parent,
            "MoldSeam",
            Vector3.new(0.14, 4.6, 0.14),
            base * CFrame.new(0.98, 3, 0),
            SOOT,
            Enum.Material.SmoothPlastic,
            false
        )
        seam.CanQuery = false
    end
end

-- A row of figures facing one way, which is how the Crown says "crowd".
local function crowd(parent: Instance, center: Vector3, yaw: number, count: number)
    for index = 0, count - 1 do
        figure(
            parent,
            center + Vector3.new((index - (count - 1) * 0.5) * 3.4, 0, (index % 2) * 1.6),
            yaw,
            true
        )
    end
end

-- A kiln, lit or cold. Lit ones are still making casts.
local function kiln(parent: Instance, center: Vector3, lit: boolean)
    part(
        parent,
        "KilnBody",
        Vector3.new(9, 10, 9),
        CFrame.new(center + Vector3.new(0, 5, 0)),
        KILN_BRICK,
        Enum.Material.Brick
    )
    part(
        parent,
        "KilnStack",
        Vector3.new(2.6, 8, 2.6),
        CFrame.new(center + Vector3.new(0, 13, 0)),
        KILN_BRICK,
        Enum.Material.Brick
    )
    local mouth = part(
        parent,
        "KilnMouth",
        Vector3.new(4, 4.4, 1),
        CFrame.new(center + Vector3.new(0, 3, -4.4)),
        if lit then FIRE else Color3.fromRGB(20, 20, 22),
        if lit then Enum.Material.Neon else Enum.Material.SmoothPlastic,
        false
    )
    mouth.CanQuery = false
    if lit then
        glow(parent, "KilnFire", center + Vector3.new(0, 3, -5.5), 2, FIRE, 3)
    end
end

-- Glass the heat made, in sheets and shards. Memory glass is the pink
-- one, and it is the only colour in the region that is not ash or fire.
local function glassField(parent: Instance, center: Vector3, radius: number, memory: boolean)
    for index = 0, 6 do
        local angle = index * 0.92
        local shard = part(
            parent,
            if memory then "MemoryGlass" else "GlassShard",
            Vector3.new(1.4, 4 + (index % 3), 1.4),
            CFrame.new(
                center
                    + Vector3.new(math.cos(angle) * radius * 0.5, 2, math.sin(angle) * radius * 0.5)
            ) * CFrame.Angles(math.rad(index * 4), angle, math.rad(index * 3)),
            if memory then MEMORY_GLASS else GLASS,
            Enum.Material.Glass
        )
        shard.Transparency = 0.35
    end
    if memory then
        glow(parent, "MemoryShine", center + Vector3.new(0, 3, 0), 1.6, MEMORY_GLASS, 1.4)
    end
end

-- Colonnade: the city's one repeated piece of architecture, and the only
-- reliable cover in a district with no walls left.
local function colonnade(parent: Instance, center: Vector3, length: number, roofed: boolean)
    local bays = math.max(3, math.floor(length / 7))
    for index = 0, bays - 1 do
        local z = -length * 0.5 + index * (length / bays) + (length / bays) * 0.5
        -- A cylinder's axis is its Size.X, so a standing column is
        -- height-on-X and then rolled ninety degrees upright.
        local column = part(
            parent,
            "AshColumn",
            Vector3.new(12, 2.2, 2.2),
            CFrame.new(center + Vector3.new(0, 6, z)) * CFrame.Angles(0, 0, math.rad(90)),
            ASH,
            Enum.Material.Sandstone
        )
        column.Shape = Enum.PartType.Cylinder
    end
    if roofed then
        part(
            parent,
            "ColonnadeEntablature",
            Vector3.new(4, 1.6, length),
            CFrame.new(center + Vector3.new(0, 12.8, 0)),
            DARK_ASH,
            Enum.Material.Sandstone
        )
    end
end

-- Seating, tiered, still full. The Crown's crowd is scenery and threat at
-- the same time, which is why it is drawn at real scale.
local function stands(parent: Instance, center: Vector3, rows: number, yaw: number)
    local base = CFrame.new(center) * CFrame.Angles(0, math.rad(yaw), 0)
    for index = 0, rows - 1 do
        part(
            parent,
            "StandRow",
            Vector3.new(30 - index * 2, 2.2, 5),
            base * CFrame.new(0, 1.1 + index * 2.2, index * 5.4),
            DARK_ASH,
            Enum.Material.Slate
        )
    end
    for index = 0, rows - 1 do
        crowd(parent, center + Vector3.new(0, 2.2 + index * 2.2, index * 5.4 - 1.6), yaw + 180, 4)
    end
end

-- Cold running water. The only thing in the Crown that is not doing
-- anything, which makes it the only place a party can stop.
local function coolingRun(parent: Instance, center: Vector3, length: number)
    local water = part(
        parent,
        "ChannelWater",
        Vector3.new(6, 1, length),
        CFrame.new(center + Vector3.new(0, 0.6, 0)),
        COLD_WATER,
        Enum.Material.Water,
        false
    )
    water.Transparency = 0.25
    water.CanQuery = false
    for side = -1, 1, 2 do
        part(
            parent,
            "ChannelWall",
            Vector3.new(1.6, 3, length),
            CFrame.new(center + Vector3.new(side * 3.8, 1.2, 0)),
            CINDERSTEEL,
            Enum.Material.Metal
        )
    end
end

-- Stage boards, raised. Wherever these are, something is still being
-- performed on them.
local function stage(parent: Instance, center: Vector3, width: number, depth: number)
    part(
        parent,
        "StageBoards",
        Vector3.new(width, 1.2, depth),
        CFrame.new(center + Vector3.new(0, 2.4, 0)),
        Color3.fromRGB(86, 66, 50),
        Enum.Material.WoodPlanks
    )
    for side = -1, 1, 2 do
        part(
            parent,
            "StageWing",
            Vector3.new(1.4, 11, depth),
            CFrame.new(center + Vector3.new(side * width * 0.5, 5.5, 0)),
            SOOT,
            Enum.Material.Fabric
        )
    end
end

-- Silk on frames, ash-coloured, the district's one soft surface.
local function silkFrame(parent: Instance, center: Vector3)
    for side = -1, 1, 2 do
        part(
            parent,
            "LoomPost",
            Vector3.new(0.8, 8, 0.8),
            CFrame.new(center + Vector3.new(side * 4.5, 4, 0)),
            CINDERSTEEL,
            Enum.Material.Metal
        )
    end
    local cloth = part(
        parent,
        "AshSilk",
        Vector3.new(9, 5.4, 0.4),
        CFrame.new(center + Vector3.new(0, 4.6, 0)),
        SILK,
        Enum.Material.Fabric,
        false
    )
    cloth.Transparency = 0.15
    cloth.CanQuery = false
end

-- A processional marker: the only signage in the Crown, and repainted
-- more recently than anything else here.
local function marker(parent: Instance, center: Vector3, yaw: number)
    part(
        parent,
        "MarkerPost",
        Vector3.new(1.4, 9, 1.4),
        CFrame.new(center + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, math.rad(yaw), 0),
        CINDERSTEEL,
        Enum.Material.Metal
    )
    part(
        parent,
        "MarkerCrown",
        Vector3.new(3.2, 1.6, 3.2),
        CFrame.new(center + Vector3.new(0, 9.6, 0)) * CFrame.Angles(0, math.rad(yaw), 0),
        CROWN_GOLD,
        Enum.Material.Metal,
        false
    )
end

--[[
    Draw one Cinderfall module. Returns false for a key this builder has
    no case for, so the coverage spec can tell the difference between a
    module that draws nothing and a module nobody wrote.
]]
function CinderfallBuilder.buildModuleVisual(
    parent: Instance,
    visual: string,
    center: Vector3
): boolean
    if visual == "crown_gate" then
        crownGround(parent, center)
        -- Arrival: two colonnades, a marker, and the first pair of casts
        -- a party sees -- one performing, one not, side by side, before
        -- anything is asking them to tell the difference.
        colonnade(parent, center + Vector3.new(-8, 0, 0), 28, true)
        colonnade(parent, center + Vector3.new(8, 0, 0), 28, true)
        figure(parent, center + Vector3.new(-3, 0, 10), 180, true)
        figure(parent, center + Vector3.new(3, 0, 10), 44, false)
        marker(parent, center + Vector3.new(0, 0, 15), 180)
        return true
    elseif visual == "ash_road" then
        crownGround(parent, center)
        part(
            parent,
            "RoadBed",
            Vector3.new(12, 0.6, 36),
            CFrame.new(center + Vector3.new(0, 1.1, 0)),
            DARK_ASH,
            Enum.Material.Slate
        )
        marker(parent, center + Vector3.new(-7, 0, -12), 0)
        marker(parent, center + Vector3.new(7, 0, 12), 180)
        return true
    elseif visual == "kiln_row" then
        crownGround(parent, center)
        kiln(parent, center + Vector3.new(-11, 0, 0), true)
        kiln(parent, center + Vector3.new(0, 0, 6), true)
        kiln(parent, center + Vector3.new(11, 0, 0), false)
        return true
    elseif visual == "glass_orchard" then
        crownGround(parent, center)
        -- Trees the heat glassed where they stood, with the fruit still
        -- on them. The first time the Crown lies about what is safe.
        for row = -1, 1 do
            for column = -1, 1 do
                local trunk = part(
                    parent,
                    "GlassTrunk",
                    Vector3.new(1.6, 9, 1.6),
                    CFrame.new(center + Vector3.new(column * 11, 4.5, row * 11)),
                    GLASS,
                    Enum.Material.Glass
                )
                trunk.Transparency = 0.3
                local crownTop = part(
                    parent,
                    "GlassCanopy",
                    Vector3.new(7, 4, 7),
                    CFrame.new(center + Vector3.new(column * 11, 10, row * 11)),
                    GLASS,
                    Enum.Material.Glass,
                    false
                )
                crownTop.Transparency = 0.45
                crownTop.Shape = Enum.PartType.Ball
                crownTop.CanQuery = false
            end
        end
        return true
    elseif visual == "silk_looms" then
        crownGround(parent, center)
        silkFrame(parent, center + Vector3.new(-9, 0, -4))
        silkFrame(parent, center + Vector3.new(2, 0, 6))
        silkFrame(parent, center + Vector3.new(12, 0, -6))
        figure(parent, center + Vector3.new(6, 0, -2), 20, false)
        return true
    elseif visual == "pearl_beds" then
        crownGround(parent, center)
        -- Kiln pearls form where glass dripped and cooled slowly. The
        -- beds are worth stopping at and directly under a kiln stack.
        for index = 0, 5 do
            local pearl = part(
                parent,
                "KilnPearl",
                Vector3.new(2.2, 2.2, 2.2),
                CFrame.new(center + Vector3.new((index % 3 - 1) * 7, 1.6, (index // 3) * 8 - 4)),
                Color3.fromRGB(226, 214, 196),
                Enum.Material.Glass,
                false
            )
            pearl.Shape = Enum.PartType.Ball
        end
        kiln(parent, center + Vector3.new(0, 0, -14), false)
        return true
    elseif visual == "coal_terraces" then
        crownGround(parent, center)
        for index = 0, 3 do
            part(
                parent,
                "CoalTerrace",
                Vector3.new(30 - index * 4, 2.4, 7),
                CFrame.new(center + Vector3.new(0, 1.4 + index * 2.4, -12 + index * 6)),
                SOOT,
                Enum.Material.Slate
            )
        end
        glow(parent, "TerraceEmber", center + Vector3.new(0, 3, -6), 1.4, FIRE, 1.4)
        return true
    elseif visual == "slag_gardens" then
        crownGround(parent, center)
        glassField(parent, center + Vector3.new(-8, 0, 4), 16, false)
        glassField(parent, center + Vector3.new(9, 0, -6), 14, false)
        figure(parent, center + Vector3.new(0, 0, -12), 96, false)
        return true
    elseif visual == "foundry_yards" then
        crownGround(parent, center)
        kiln(parent, center + Vector3.new(-12, 0, -6), true)
        for index = -1, 1 do
            part(
                parent,
                "IngotStack",
                Vector3.new(6, 2.4, 4),
                CFrame.new(center + Vector3.new(index * 8, 1.8, 8))
                    * CFrame.Angles(0, math.rad(index * 12), 0),
                CINDERSTEEL,
                Enum.Material.Metal
            )
        end
        crowd(parent, center + Vector3.new(8, 0, -4), 200, 3)
        return true
    elseif visual == "parade_route" then
        crownGround(parent, center)
        -- The procession is still walking it. Nothing here attacks; it
        -- simply does not stop.
        part(
            parent,
            "ProcessionWay",
            Vector3.new(14, 0.6, 38),
            CFrame.new(center + Vector3.new(0, 1.1, 0)),
            DARK_ASH,
            Enum.Material.Slate
        )
        for index = -2, 2 do
            figure(parent, center + Vector3.new((index % 2) * 4 - 2, 0, index * 7), 0, true)
        end
        colonnade(parent, center + Vector3.new(-12, 0, 0), 34, false)
        return true
    elseif visual == "cooling_channel" then
        crownGround(parent, center)
        coolingRun(parent, center, 36)
        kiln(parent, center + Vector3.new(-13, 0, -8), true)
        kiln(parent, center + Vector3.new(13, 0, 8), true)
        return true
    elseif visual == "collapsed_tiers" then
        crownGround(parent, center)
        for index = 0, 3 do
            part(
                parent,
                "FallenTier",
                Vector3.new(22 - index * 3, 2.4, 6),
                CFrame.new(center + Vector3.new(index * 2 - 3, 1.6 + index * 1.4, -8 + index * 5))
                    * CFrame.Angles(math.rad(index * 6), math.rad(index * 9), math.rad(index * 4)),
                DARK_ASH,
                Enum.Material.Slate
            )
        end
        figure(parent, center + Vector3.new(9, 0, 10), 130, false)
        return true
    elseif visual == "ash_colonnade" then
        crownGround(parent, center)
        colonnade(parent, center + Vector3.new(-7, 0, 0), 34, true)
        colonnade(parent, center + Vector3.new(7, 0, 0), 34, true)
        return true
    elseif visual == "stage_bridges" then
        crownGround(parent, center)
        -- Scenery bridges between the upper tiers, built to be walked on
        -- once a night by people who knew where the boards were.
        for side = -1, 1, 2 do
            part(
                parent,
                "BridgeSpan",
                Vector3.new(5, 0.7, 30),
                CFrame.new(center + Vector3.new(side * 8, 9, 0))
                    * CFrame.Angles(0, 0, math.rad(side * 2)),
                Color3.fromRGB(86, 66, 50),
                Enum.Material.WoodPlanks
            )
            part(
                parent,
                "BridgePier",
                Vector3.new(2.4, 9, 2.4),
                CFrame.new(center + Vector3.new(side * 8, 4.5, -14)),
                ASH,
                Enum.Material.Sandstone
            )
        end
        return true
    elseif visual == "procession_stair" then
        crownGround(parent, center)
        for index = 0, 6 do
            part(
                parent,
                "ProcessionStep",
                Vector3.new(16 - index, 1.4, 4),
                CFrame.new(center + Vector3.new(0, 1 + index * 1.4, -11 + index * 3.2)),
                ASH,
                Enum.Material.Sandstone
            )
        end
        marker(parent, center + Vector3.new(-9, 0, 12), 180)
        figure(parent, center + Vector3.new(6, 0, 12), 12, false)
        return true
    elseif visual == "applause_court" then
        crownGround(parent, center)
        -- The applause starts when anyone walks in. Everything that hunts
        -- by sound in this district is listening to it.
        stands(parent, center + Vector3.new(0, 0, -14), 3, 0)
        stage(parent, center + Vector3.new(0, 0, 8), 22, 12)
        return true
    elseif visual == "knight_gallery" then
        crownGround(parent, center)
        colonnade(parent, center + Vector3.new(-9, 0, 0), 30, true)
        colonnade(parent, center + Vector3.new(9, 0, 0), 30, true)
        glassField(parent, center, 18, false)
        return true
    elseif visual == "worm_kilns" then
        crownGround(parent, center)
        kiln(parent, center + Vector3.new(-10, 0, -8), true)
        kiln(parent, center + Vector3.new(10, 0, -8), true)
        kiln(parent, center + Vector3.new(0, 0, 10), true)
        -- the ground between them, gone through
        for index = -1, 1 do
            local bore = part(
                parent,
                "WormBore",
                Vector3.new(5, 1.4, 5),
                CFrame.new(center + Vector3.new(index * 8, 0.9, index * 3)),
                Color3.fromRGB(18, 18, 20),
                Enum.Material.Slate,
                false
            )
            bore.CanQuery = false
        end
        return true
    elseif visual == "giant_plaza" then
        crownGround(parent, center)
        part(
            parent,
            "PlazaFloor",
            Vector3.new(34, 0.6, 34),
            CFrame.new(center + Vector3.new(0, 1.1, 0)),
            ASH,
            Enum.Material.Sandstone
        )
        -- room for something very large to walk a line through a party
        colonnade(parent, center + Vector3.new(-15, 0, 0), 30, false)
        colonnade(parent, center + Vector3.new(15, 0, 0), 30, false)
        crowd(parent, center + Vector3.new(0, 0, -14), 0, 5)
        return true
    elseif visual == "citizen_quarter" then
        crownGround(parent, center)
        -- Shopfronts, some with rooms behind them and some without. The
        -- false citizens work here because there is so much to mend.
        for index = -1, 1 do
            part(
                parent,
                "Shopfront",
                Vector3.new(10, 9, 1.2),
                CFrame.new(center + Vector3.new(index * 12, 4.5, -8)),
                ASH,
                Enum.Material.Sandstone
            )
            if index ~= 0 then
                part(
                    parent,
                    "ShopBackRoom",
                    Vector3.new(10, 9, 9),
                    CFrame.new(center + Vector3.new(index * 12, 4.5, -13)),
                    DARK_ASH,
                    Enum.Material.Sandstone
                )
            end
        end
        figure(parent, center + Vector3.new(0, 0, 6), 0, true)
        return true
    elseif visual == "ash_lane" then
        crownGround(parent, center)
        for side = -1, 1, 2 do
            part(
                parent,
                "LaneWall",
                Vector3.new(3, 8, 34),
                CFrame.new(center + Vector3.new(side * 10, 4, 0)),
                DARK_ASH,
                Enum.Material.Sandstone
            )
        end
        return true
    elseif visual == "warm_arcade" then
        crownGround(parent, center)
        colonnade(parent, center + Vector3.new(0, 0, -6), 26, true)
        kiln(parent, center + Vector3.new(-12, 0, 8), true)
        glow(parent, "ArcadeGlow", center + Vector3.new(0, 6, 0), 1.8, FIRE, 2)
        return true
    elseif visual == "crown_arch" then
        crownGround(parent, center)
        for side = -1, 1, 2 do
            part(
                parent,
                "ArchPier",
                Vector3.new(4, 16, 4),
                CFrame.new(center + Vector3.new(side * 10, 8, 0)),
                ASH,
                Enum.Material.Sandstone
            )
        end
        part(
            parent,
            "ArchSpan",
            Vector3.new(24, 3.4, 5),
            CFrame.new(center + Vector3.new(0, 17, 0)),
            ASH,
            Enum.Material.Sandstone
        )
        part(
            parent,
            "ArchCrown",
            Vector3.new(5, 3, 5),
            CFrame.new(center + Vector3.new(0, 20, 0)),
            CROWN_GOLD,
            Enum.Material.Metal,
            false
        )
        return true
    elseif visual == "cold_kiln" then
        crownGround(parent, center)
        -- A kiln that went out during the firing. Everything it holds is
        -- half-made and therefore honest.
        kiln(parent, center, false)
        figure(parent, center + Vector3.new(-6, 0, 6), 70, false)
        figure(parent, center + Vector3.new(6, 0, 7), 250, false)
        return true
    elseif visual == "regents_box" then
        crownGround(parent, center)
        part(
            parent,
            "BoxFloor",
            Vector3.new(20, 1, 14),
            CFrame.new(center + Vector3.new(0, 5.5, 0)),
            DARK_ASH,
            Enum.Material.Slate
        )
        for side = -1, 1, 2 do
            part(
                parent,
                "BoxPier",
                Vector3.new(3, 6, 3),
                CFrame.new(center + Vector3.new(side * 8, 3, 0)),
                ASH,
                Enum.Material.Sandstone
            )
        end
        -- the chair is empty, and clean, in a box thick with ash
        part(
            parent,
            "RegentChair",
            Vector3.new(3.2, 5, 3),
            CFrame.new(center + Vector3.new(0, 8.5, 3)),
            CROWN_GOLD,
            Enum.Material.Metal
        )
        crowd(parent, center + Vector3.new(0, 6, -4), 180, 3)
        return true
    elseif visual == "sculptors_hall" then
        crownGround(parent, center)
        colonnade(parent, center + Vector3.new(-9, 0, 0), 28, true)
        colonnade(parent, center + Vector3.new(9, 0, 0), 28, true)
        -- half-finished work, which is the only honest work in the Crown
        for index = -1, 1 do
            part(
                parent,
                "UnfinishedBlock",
                Vector3.new(3, 5 + index, 3),
                CFrame.new(center + Vector3.new(index * 7, 2.6, 4))
                    * CFrame.Angles(0, math.rad(index * 24), 0),
                TRUE_CAST,
                Enum.Material.Sandstone
            )
        end
        figure(parent, center + Vector3.new(0, 0, -8), 26, false)
        return true
    elseif visual == "memory_vault" then
        crownGround(parent, center)
        for side = -1, 1, 2 do
            part(
                parent,
                "VaultWall",
                Vector3.new(1.6, 12, 26),
                CFrame.new(center + Vector3.new(side * 10, 6, 0)),
                CINDERSTEEL,
                Enum.Material.Metal
            )
        end
        part(
            parent,
            "VaultRoof",
            Vector3.new(22, 1.4, 26),
            CFrame.new(center + Vector3.new(0, 12.4, 0)),
            CINDERSTEEL,
            Enum.Material.Metal
        )
        glassField(parent, center, 14, true)
        return true
    elseif visual == "statue_line" then
        crownGround(parent, center)
        -- The puzzle room: a row of casts, one of which is not one. The
        -- Regent's fight, taught without the Regent.
        for index = -2, 2 do
            figure(
                parent,
                center + Vector3.new(index * 6, 0, 0),
                if index == 1 then 118 else 180,
                index ~= 1
            )
        end
        part(
            parent,
            "LinePlinth",
            Vector3.new(34, 1.4, 6),
            CFrame.new(center + Vector3.new(0, 1.2, 0)),
            ASH,
            Enum.Material.Sandstone
        )
        return true
    elseif visual == "kiln_locks" then
        crownGround(parent, center)
        kiln(parent, center + Vector3.new(-10, 0, -6), true)
        kiln(parent, center + Vector3.new(10, 0, -6), false)
        coolingRun(parent, center + Vector3.new(0, 0, 8), 24)
        for index = -1, 1 do
            part(
                parent,
                "ChannelGate",
                Vector3.new(7, 5, 1.2),
                CFrame.new(center + Vector3.new(index * 9, 3, 8)),
                CINDERSTEEL,
                Enum.Material.DiamondPlate
            )
        end
        return true
    elseif visual == "regent_approach" then
        crownGround(parent, center)
        -- The landmark: the stands, the stage, the Regent's own box, and
        -- the five statues its fight is fought among -- standing in the
        -- world before anything is wired to them.
        stands(parent, center + Vector3.new(0, 0, -18), 4, 0)
        stage(parent, center + Vector3.new(0, 0, 6), 26, 14)
        part(
            parent,
            "RegentBoxFloor",
            Vector3.new(18, 1, 12),
            CFrame.new(center + Vector3.new(0, 9, 18)),
            DARK_ASH,
            Enum.Material.Slate
        )
        part(
            parent,
            "RegentSeat",
            Vector3.new(3.4, 5.4, 3.2),
            CFrame.new(center + Vector3.new(0, 12, 20)),
            CROWN_GOLD,
            Enum.Material.Metal
        )
        for index = -2, 2 do
            figure(parent, center + Vector3.new(index * 7, 0, 6), 180, index % 2 == 0)
        end
        marker(parent, center + Vector3.new(-15, 0, -4), 90)
        return true
    end
    return false
end

return table.freeze(CinderfallBuilder)
