--!strict

local CollectionService = game:GetService("CollectionService")

local BramblewakeBuilder = {}

local GRASS = Color3.fromRGB(48, 82, 55)
local DEEP_GRASS = Color3.fromRGB(28, 58, 43)
local PATH = Color3.fromRGB(112, 94, 65)
local BARK = Color3.fromRGB(75, 48, 34)
local DARK_BARK = Color3.fromRGB(49, 34, 30)
local STONE = Color3.fromRGB(76, 85, 79)
local AMBER = Color3.fromRGB(255, 178, 71)
local FOXFIRE = Color3.fromRGB(94, 206, 176)
local MEADOW = Color3.fromRGB(189, 161, 76)
local CREAM = Color3.fromRGB(244, 230, 197)

local ORIGIN = Vector3.new(1600, 0, -230)

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

local function orb(
    parent: Instance,
    name: string,
    position: Vector3,
    size: number,
    color: Color3,
    material: Enum.Material
): Part
    local instance = part(
        parent,
        name,
        Vector3.new(size, size, size),
        CFrame.new(position),
        color,
        material,
        false
    )
    instance.Shape = Enum.PartType.Ball
    return instance
end

local function light(target: BasePart, color: Color3, brightness: number, range: number)
    local pointLight = Instance.new("PointLight")
    pointLight.Color = color
    pointLight.Brightness = brightness
    pointLight.Range = range
    pointLight.Shadows = false
    pointLight.Parent = target
end

local function billboard(target: BasePart, text: string, color: Color3)
    local gui = Instance.new("BillboardGui")
    gui.Name = "LandmarkLabel"
    gui.Adornee = target
    gui.AlwaysOnTop = false
    gui.LightInfluence = 0.35
    gui.MaxDistance = 55
    gui.Size = UDim2.fromOffset(190, 40)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 3.8, 0)
    gui.Parent = target

    local label = Instance.new("TextLabel")
    label.BackgroundColor3 = Color3.fromRGB(14, 24, 21)
    label.BackgroundTransparency = 0.2
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.Size = UDim2.fromScale(1, 1)
    label.Text = text
    label.TextColor3 = color
    label.TextScaled = false
    label.TextSize = 12
    label.TextWrapped = true
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = label
end

local function tree(parent: Instance, position: Vector3, scale: number)
    part(
        parent,
        "BrambleTrunk",
        Vector3.new(2.4 * scale, 14 * scale, 2.4 * scale),
        CFrame.new(position + Vector3.new(0, 7 * scale, 0)),
        BARK,
        Enum.Material.Wood
    )
    for layer = 1, 2 do
        local crown = orb(
            parent,
            "BrambleCrown",
            position + Vector3.new(0, (12 + layer * 4) * scale, 0),
            (10 - layer) * scale,
            if layer == 1 then DEEP_GRASS else GRASS,
            Enum.Material.Grass
        )
        crown.CanQuery = false
    end
end

local function rootArch(parent: Instance, center: Vector3, scale: number)
    for side = -1, 1, 2 do
        part(
            parent,
            "LivingRoot",
            Vector3.new(2.4 * scale, 18 * scale, 2.4 * scale),
            CFrame.new(center + Vector3.new(side * 10 * scale, 8 * scale, side * 10 * scale))
                * CFrame.Angles(0, 0, math.rad(-side * 18)),
            BARK,
            Enum.Material.Wood
        )
    end
    part(
        parent,
        "RootCrown",
        Vector3.new(29 * scale, 2.8 * scale, 3 * scale),
        CFrame.new(center + Vector3.new(0, 17 * scale, 0)) * CFrame.Angles(0, math.rad(45), 0),
        DARK_BARK,
        Enum.Material.Wood
    )
end

local function lantern(parent: Instance, position: Vector3, scale: number)
    part(
        parent,
        "FoxfirePost",
        Vector3.new(0.8 * scale, 6 * scale, 0.8 * scale),
        CFrame.new(position + Vector3.new(0, 3 * scale, 0)),
        BARK,
        Enum.Material.Wood
    )
    local glow = orb(
        parent,
        "FoxfireGlow",
        position + Vector3.new(0, 6.4 * scale, 0),
        2.1 * scale,
        FOXFIRE,
        Enum.Material.Neon
    )
    light(glow, FOXFIRE, 1.8, 18 * scale)
end

local function pathArm(parent: Instance, center: Vector3, neighbor: Vector3)
    local delta = neighbor - center
    local target = center + delta.Unit * 38
    local midpoint = (center + target) / 2 + Vector3.new(0, 0.28, 0)
    part(
        parent,
        "CriticalPath",
        Vector3.new(14, 0.5, (target - center).Magnitude + 4),
        CFrame.lookAt(midpoint, target),
        PATH,
        Enum.Material.Ground
    )
end

local function moduleDressing(parent: Instance, center: Vector3, seed: number)
    local random = Random.new(seed)
    for index = 1, 8 do
        local angle = random:NextNumber(0, math.pi * 2)
        local radius = random:NextNumber(14, 28)
        local position = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
        local stone = orb(
            parent,
            "TrailStone",
            position + Vector3.new(0, 0.55, 0),
            random:NextNumber(1.2, 2.4),
            if index % 2 == 0 then STONE else Color3.fromRGB(93, 101, 88),
            Enum.Material.Slate
        )
        stone.CFrame *= CFrame.Angles(0.15, angle, 0.1)
        stone.CanQuery = false
    end
    for index = 1, 5 do
        local angle = random:NextNumber(0, math.pi * 2)
        local radius = random:NextNumber(8, 25)
        local tuft = orb(
            parent,
            "MossLight",
            center + Vector3.new(math.cos(angle) * radius, 0.6, math.sin(angle) * radius),
            0.5,
            if index % 2 == 0 then FOXFIRE else AMBER,
            Enum.Material.Neon
        )
        tuft.CanQuery = false
    end
end

local function buildFarm(parent: Instance, center: Vector3)
    part(
        parent,
        "Farmhouse",
        Vector3.new(16, 11, 12),
        CFrame.new(center + Vector3.new(21, 5.5, 20)),
        Color3.fromRGB(92, 66, 46),
        Enum.Material.WoodPlanks
    )
    local roof = part(
        parent,
        "RainDarkRoof",
        Vector3.new(19, 2, 15),
        CFrame.new(center + Vector3.new(21, 12, 20)) * CFrame.Angles(0, 0, math.rad(8)),
        DARK_BARK,
        Enum.Material.Slate
    )
    roof.CanQuery = false
    for row = -1, 1 do
        part(
            parent,
            "OldFieldRow",
            Vector3.new(3, 0.8, 28),
            CFrame.new(center + Vector3.new(-18 + row * 6, 0.2, 9)),
            MEADOW,
            Enum.Material.Ground,
            false
        )
    end
end

local function buildWindmill(parent: Instance, center: Vector3)
    local tower = part(
        parent,
        "WindmillTower",
        Vector3.new(9, 30, 9),
        CFrame.new(center + Vector3.new(22, 15, 20)),
        Color3.fromRGB(105, 84, 61),
        Enum.Material.WoodPlanks
    )
    local hub = orb(
        parent,
        "WindmillHub",
        tower.Position + Vector3.new(0, 8, -5),
        3,
        STONE,
        Enum.Material.Metal
    )
    for angle = 0, 3 do
        part(
            parent,
            "WindmillSail",
            Vector3.new(2, 19, 0.8),
            CFrame.new(hub.Position) * CFrame.Angles(0, 0, angle * math.pi / 2),
            CREAM,
            Enum.Material.Fabric,
            false
        )
    end
end

local function buildModuleVisual(parent: Instance, visual: string, center: Vector3)
    if visual == "lantern_gate" then
        rootArch(parent, center, 1)
        lantern(parent, center + Vector3.new(-14, 0, 13), 1)
        lantern(parent, center + Vector3.new(14, 0, 13), 1)
    elseif visual == "root_arch" then
        rootArch(parent, center + Vector3.new(0, 0, -7), 0.9)
        for offset = -1, 1, 2 do
            orb(
                parent,
                "Brightcap",
                center + Vector3.new(offset * 15, 1.1, 12),
                2.2,
                FOXFIRE,
                Enum.Material.Neon
            )
        end
    elseif visual == "orchard" then
        for x = -1, 1 do
            for z = -1, 1 do
                tree(parent, center + Vector3.new(x * 17, 0, z * 17), 0.68)
            end
        end
    elseif visual == "foxglove" then
        for index = 1, 8 do
            local side = if index % 2 == 0 then 1 else -1
            local glow = orb(
                parent,
                "Foxglove",
                center + Vector3.new(side * (12 + index), 1.2, -26 + index * 6),
                1.4,
                if index % 3 == 0 then AMBER else FOXFIRE,
                Enum.Material.Neon
            )
            glow.CanQuery = false
        end
    elseif visual == "farm" then
        buildFarm(parent, center)
    elseif visual == "briar_ring" then
        for index = 1, 8 do
            local angle = (index / 8) * math.pi * 2 + math.pi / 8
            part(
                parent,
                "BriarSpine",
                Vector3.new(1.4, 10, 1.4),
                CFrame.new(center + Vector3.new(math.cos(angle) * 25, 4, math.sin(angle) * 25))
                    * CFrame.Angles(math.rad(18), 0, -angle),
                DARK_BARK,
                Enum.Material.Wood
            )
        end
    elseif visual == "sapfall" then
        for index = -2, 2 do
            local stone = orb(
                parent,
                "SapglassStone",
                center + Vector3.new(index * 8, 2, 17 + math.abs(index) * 2),
                4.5,
                STONE,
                Enum.Material.Slate
            )
            local sap = orb(
                parent,
                "AmberSap",
                stone.Position + Vector3.new(0, 3.2, 0),
                1.8,
                AMBER,
                Enum.Material.Neon
            )
            if index == 0 then
                light(sap, AMBER, 1.7, 18)
            end
        end
    elseif visual == "windmill" then
        buildWindmill(parent, center)
    elseif visual == "bridge" then
        for index = -4, 4 do
            part(
                parent,
                "RootBridgePlank",
                Vector3.new(7, 0.8, 4.5),
                CFrame.new(center + Vector3.new(19, 1 + math.abs(index) * 0.2, index * 4.4)),
                Color3.fromRGB(121, 83, 52),
                Enum.Material.WoodPlanks
            )
        end
    elseif visual == "moth_meadow" then
        part(
            parent,
            "MeadowGold",
            Vector3.new(46, 0.7, 46),
            CFrame.new(center + Vector3.new(0, 0.1, 0)),
            MEADOW,
            Enum.Material.Grass
        )
        for index = 1, 10 do
            local angle = index * 2.4
            orb(
                parent,
                "LanternMoth",
                center
                    + Vector3.new(
                        math.cos(angle) * (8 + index),
                        3 + (index % 4),
                        math.sin(angle) * (8 + index)
                    ),
                0.65,
                FOXFIRE,
                Enum.Material.Neon
            )
        end
    elseif visual == "old_growth" then
        part(
            parent,
            "OldGrowthTrunk",
            Vector3.new(15, 48, 15),
            CFrame.new(center + Vector3.new(22, 23, 22)),
            DARK_BARK,
            Enum.Material.Wood
        )
        for index = 1, 5 do
            local angle = (index / 5) * math.pi * 2
            part(
                parent,
                "CathedralRoot",
                Vector3.new(4, 30, 5),
                CFrame.new(
                    center + Vector3.new(22 + math.cos(angle) * 10, 10, 22 + math.sin(angle) * 10)
                ) * CFrame.Angles(math.rad(24), 0, -angle),
                BARK,
                Enum.Material.Wood
            )
        end
    elseif visual == "wayhome_gate" then
        rootArch(parent, center, 1.15)
        local beacon =
            orb(parent, "WayhomeLight", center + Vector3.new(0, 8, 0), 6, AMBER, Enum.Material.Neon)
        light(beacon, AMBER, 3, 36)
        billboard(beacon, "WAYHOME GATE", CREAM)
    end
end

local function buildPointOfInterest(
    parent: Instance,
    center: Vector3,
    definition: any,
    runtimeIds: any
)
    local anchor = part(
        parent,
        "PointOfInterest",
        Vector3.new(9, 2, 9),
        CFrame.new(center + Vector3.new(-21, 1, -18)),
        STONE,
        Enum.Material.Slate
    )
    anchor:SetAttribute("ContentId", definition.id)
    anchor:SetAttribute("DisplayName", definition.displayName)
    CollectionService:AddTag(anchor, runtimeIds.ExpeditionPointOfInterestTag)
    local memory = orb(
        parent,
        "MemoryLight",
        anchor.Position + Vector3.new(0, 4, 0),
        3.2,
        FOXFIRE,
        Enum.Material.Neon
    )
    light(memory, FOXFIRE, 1.4, 18)
    billboard(memory, string.upper(definition.displayName), FOXFIRE)
end

local function buildEventSocket(
    parent: Instance,
    center: Vector3,
    definition: any,
    runtimeIds: any
): any
    local anchor = part(
        parent,
        "EventSocket",
        Vector3.new(7, 1, 7),
        CFrame.new(center + Vector3.new(22, 0.5, -19)),
        Color3.fromRGB(99, 72, 48),
        Enum.Material.WoodPlanks
    )
    anchor:SetAttribute("ContentId", definition.id)
    anchor:SetAttribute("DisplayName", definition.displayName)
    anchor:SetAttribute("Dormant", true)
    anchor:SetAttribute("Status", "dormant")
    anchor:SetAttribute("Progress", 0)
    anchor:SetAttribute("ProgressTotal", #definition.steps)
    CollectionService:AddTag(anchor, runtimeIds.ExpeditionEventTag)
    billboard(anchor, string.upper(definition.displayName), AMBER)

    if definition.visual == "wagon" then
        part(
            parent,
            "LostWagon",
            Vector3.new(10, 5, 7),
            CFrame.new(anchor.Position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0.35, 0.14),
            Color3.fromRGB(104, 69, 42),
            Enum.Material.WoodPlanks
        )
    elseif definition.visual == "hedge" then
        part(
            parent,
            "MovingHedge",
            Vector3.new(18, 9, 5),
            CFrame.new(anchor.Position + Vector3.new(0, 4.5, 0)),
            DEEP_GRASS,
            Enum.Material.Grass
        )
    elseif definition.visual == "root_bridge" then
        rootArch(parent, anchor.Position, 0.52)
    end

    local interactions = {}
    for index, step in definition.steps do
        local offset = step.offset
        local position = anchor.Position + Vector3.new(offset.x, offset.y, offset.z)
        local target: Part
        if definition.visual == "foxlight" then
            target = orb(parent, "Foxlight_" .. step.id, position, 2.2, FOXFIRE, Enum.Material.Neon)
            target.Transparency = 0.16
            light(target, FOXFIRE, 1.1, 14)
        elseif definition.visual == "root_bridge" then
            target = orb(parent, "RootKnot_" .. step.id, position, 2.7, AMBER, Enum.Material.Wood)
        elseif definition.visual == "wagon" then
            target = part(
                parent,
                "WagonBrace_" .. step.id,
                Vector3.new(2.8, 1.4, 2.8),
                CFrame.new(position) * CFrame.Angles(0, index * 0.55, math.rad(8)),
                AMBER,
                Enum.Material.WoodPlanks,
                false
            )
        else
            target = part(
                parent,
                "HedgeLatch_" .. step.id,
                Vector3.new(1.4, 3.2, 1.4),
                CFrame.new(position) * CFrame.Angles(0, 0, math.rad(index * 8 - 16)),
                AMBER,
                Enum.Material.WoodPlanks,
                false
            )
        end
        target.CastShadow = false
        target:SetAttribute("EventId", definition.id)
        target:SetAttribute("EventStepId", step.id)
        target:SetAttribute("EventStepState", "available")
        CollectionService:AddTag(target, runtimeIds.ExpeditionEventStepTag)
        table.insert(interactions, {
            actionText = step.actionText,
            eventId = definition.id,
            interactionId = runtimeIds.eventInteractionId(definition.id, step.id),
            objectText = step.objectText,
            stepId = step.id,
            target = target,
        })
    end

    return {
        interactions = interactions,
        socket = anchor,
    }
end

local function buildBackdrop(parent: Instance, centers: { Vector3 })
    local folder = Instance.new("Folder")
    folder.Name = "RegionalBackdrop"
    folder.Parent = parent

    local average = Vector3.zero
    for _, center in centers do
        average += center
    end
    average /= #centers

    for index = 1, 12 do
        local angle = (index / 12) * math.pi * 2
        local radius = 270 + (index % 3) * 24
        local height = 54 + (index % 4) * 14
        part(
            folder,
            "DistantRootSpire",
            Vector3.new(12, height, 12),
            CFrame.new(
                average
                    + Vector3.new(
                        math.cos(angle) * radius,
                        height / 2 - 3,
                        math.sin(angle) * radius
                    )
            ) * CFrame.Angles(math.rad(8), 0, -angle),
            Color3.fromRGB(37, 50, 43),
            Enum.Material.Wood
        )
    end
end

local function isOccupied(center: Vector3, centers: { Vector3 }): boolean
    for _, existing in centers do
        if (existing - center).Magnitude < 1 then
            return true
        end
    end
    return false
end

local function annexCenter(
    oldGrowthCenter: Vector3,
    centers: { Vector3 },
    cellSize: number
): Vector3
    for _, direction in
        {
            Vector3.new(1, 0, 0),
            Vector3.new(0, 0, 1),
            Vector3.new(-1, 0, 0),
            Vector3.new(0, 0, -1),
        }
    do
        local candidate = oldGrowthCenter + direction * cellSize
        if not isOccupied(candidate, centers) then
            return candidate
        end
    end
    error("Old Growth has no free neighbor for the Warden's Seal")
end

local function buildWardenSeal(
    parent: Instance,
    oldGrowthCenter: Vector3,
    centers: { Vector3 },
    cellSize: number,
    runtimeIds: any
): any
    local center = annexCenter(oldGrowthCenter, centers, cellSize)
    local arena = Instance.new("Model")
    arena.Name = "WardenSealAnnex"
    arena:SetAttribute("BossId", "boss_warden_stag")
    arena:SetAttribute("ContentId", "arena_bw_warden_seal")
    arena.Parent = parent
    pcall(function()
        arena.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    end)

    pathArm(arena, oldGrowthCenter, center)
    pathArm(arena, center, oldGrowthCenter)
    part(
        arena,
        "WardenSealGround",
        Vector3.new(66, 5, 66),
        CFrame.new(center + Vector3.new(0, -2.5, 0)),
        Color3.fromRGB(38, 68, 48),
        Enum.Material.Grass
    )
    part(
        arena,
        "MemorySeal",
        Vector3.new(38, 1.1, 38),
        CFrame.new(center + Vector3.new(0, 0.15, 0)),
        STONE,
        Enum.Material.Slate
    )

    local seal = orb(
        arena,
        "WardenMemorySeal",
        center + Vector3.new(0, 1.5, 0),
        7,
        Color3.fromRGB(87, 119, 101),
        Enum.Material.SmoothPlastic
    )
    seal.Transparency = 0.52
    billboard(seal, "WARDEN'S SEAL · CLEANSE OLD GROWTH", CREAM)

    local nodeDefinitions = {
        {
            direction = Vector3.new(0, 0, -1),
            interactionId = runtimeIds.InteractionIds.WardenStagRootNorth,
            nodeId = "root_node_north",
            suffix = "North",
        },
        {
            direction = Vector3.new(1, 0, 0),
            interactionId = runtimeIds.InteractionIds.WardenStagRootEast,
            nodeId = "root_node_east",
            suffix = "East",
        },
        {
            direction = Vector3.new(0, 0, 1),
            interactionId = runtimeIds.InteractionIds.WardenStagRootSouth,
            nodeId = "root_node_south",
            suffix = "South",
        },
        {
            direction = Vector3.new(-1, 0, 0),
            interactionId = runtimeIds.InteractionIds.WardenStagRootWest,
            nodeId = "root_node_west",
            suffix = "West",
        },
    }
    local nodes = {}
    local interactions = {}
    for _, definition in nodeDefinitions do
        local node = orb(
            arena,
            "LivingRootNode" .. definition.suffix,
            center + definition.direction * 22 + Vector3.new(0, 3, 0),
            5,
            Color3.fromRGB(80, 116, 83),
            Enum.Material.SmoothPlastic
        )
        node.Transparency = 0.34
        node:SetAttribute("BossId", "boss_warden_stag")
        node:SetAttribute("BossInteraction", "cleanse_root")
        node:SetAttribute("BossNodeId", definition.nodeId)
        CollectionService:AddTag(node, runtimeIds.ExpeditionBossTag)
        billboard(node, string.upper(string.gsub(definition.nodeId, "_", " ")), CREAM)
        nodes[definition.nodeId] = node
        table.insert(interactions, {
            actionText = "CLEANSE ROOT",
            holdDuration = 0.6,
            interactionId = definition.interactionId,
            objectText = "Living Root Node",
            target = node,
        })
    end

    local antlers = {}
    for _, definition in
        {
            {
                antlerId = "antler_left",
                interactionId = runtimeIds.InteractionIds.WardenStagAntlerLeft,
                side = -1,
            },
            {
                antlerId = "antler_right",
                interactionId = runtimeIds.InteractionIds.WardenStagAntlerRight,
                side = 1,
            },
        }
    do
        local target = part(
            arena,
            if definition.side < 0 then "MemoryAntlerLeft" else "MemoryAntlerRight",
            Vector3.new(2.2, 9, 2.2),
            CFrame.new(center + Vector3.new(definition.side * 12, 4.5, 8))
                * CFrame.Angles(0, 0, math.rad(definition.side * 24)),
            Color3.fromRGB(194, 199, 173),
            Enum.Material.SmoothPlastic,
            false
        )
        target.Transparency = 0.2
        target:SetAttribute("BossId", "boss_warden_stag")
        target:SetAttribute("BossInteraction", "break_antler")
        target:SetAttribute("BossAntlerId", definition.antlerId)
        CollectionService:AddTag(target, runtimeIds.ExpeditionBossTag)
        billboard(target, "BREAK ANTLER · CHANGES FOREST", Color3.fromRGB(255, 166, 106))
        antlers[definition.antlerId] = target
        table.insert(interactions, {
            actionText = "BREAK ANTLER",
            holdDuration = 1.1,
            interactionId = definition.interactionId,
            objectText = "Harmful Shortcut",
            target = target,
        })
    end

    for index = 1, 10 do
        local angle = (index / 10) * math.pi * 2
        if math.abs(math.sin(angle)) > 0.32 then
            part(
                arena,
                "SealRootPillar",
                Vector3.new(3, 18 + (index % 3) * 4, 3),
                CFrame.new(
                    center
                        + Vector3.new(
                            math.cos(angle) * 31,
                            8 + (index % 3) * 2,
                            math.sin(angle) * 31
                        )
                ) * CFrame.Angles(math.rad(9), 0, -angle),
                if index % 2 == 0 then BARK else DARK_BARK,
                Enum.Material.Wood
            )
        end
    end
    for side = -1, 1, 2 do
        tree(arena, center + Vector3.new(side * 27, 0, -27), 1.25)
    end

    return {
        antlers = antlers,
        center = center,
        interactions = interactions,
        model = arena,
        nodes = nodes,
        seal = seal,
    }
end

local function buildBlackoutLayer(
    parent: Instance,
    centers: { Vector3 },
    bossCenter: Vector3,
    runtimeIds: any
): any
    local layer = Instance.new("Model")
    layer.Name = "BramblewakeBlackoutLayer"
    layer:SetAttribute("BlackoutId", "blackout_bramblewake")
    layer:SetAttribute("ContentId", "blackout_bw_rootfire_relay")
    layer.Parent = parent
    pcall(function()
        layer.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    end)

    local sourceCenter = assert(centers[1], "Blackout fire source center is missing")
    local fireSource = orb(
        layer,
        "BlackoutLanternFire",
        sourceCenter + Vector3.new(13, 4, 13),
        5,
        Color3.fromRGB(94, 83, 64),
        Enum.Material.SmoothPlastic
    )
    fireSource.Transparency = 0.48
    fireSource:SetAttribute("BlackoutInteraction", "take_fire")
    CollectionService:AddTag(fireSource, runtimeIds.ExpeditionBlackoutTag)
    billboard(fireSource, "BLACKOUT FIRE · CARRY TO LIVING ROOTS", CREAM)

    local interactions = {
        {
            actionText = "TAKE ROOTFIRE",
            holdDuration = 0.45,
            interactionId = runtimeIds.InteractionIds.BlackoutFireSource,
            objectText = "Blackout Lantern",
            target = fireSource,
        },
    }
    local relayNodes = {}
    for _, definition in
        {
            {
                center = assert(centers[3], "Blackout farm relay center is missing"),
                interactionId = runtimeIds.InteractionIds.BlackoutRootFarm,
                label = "FARM ROOT",
                nodeId = "blackout_root_farm",
            },
            {
                center = assert(centers[7], "Blackout mill relay center is missing"),
                interactionId = runtimeIds.InteractionIds.BlackoutRootMill,
                label = "MILL ROOT",
                nodeId = "blackout_root_mill",
            },
            {
                center = assert(centers[10], "Blackout cathedral relay center is missing"),
                interactionId = runtimeIds.InteractionIds.BlackoutRootCathedral,
                label = "CATHEDRAL ROOT",
                nodeId = "blackout_root_cathedral",
            },
        }
    do
        local node = orb(
            layer,
            "BlackoutRelay_" .. definition.label,
            definition.center + Vector3.new(-14, 3.5, -12),
            6,
            Color3.fromRGB(70, 91, 72),
            Enum.Material.SmoothPlastic
        )
        node.Transparency = 0.5
        node:SetAttribute("BlackoutInteraction", "deliver_fire")
        node:SetAttribute("BlackoutNodeId", definition.nodeId)
        CollectionService:AddTag(node, runtimeIds.ExpeditionBlackoutTag)
        billboard(node, definition.label .. " · NEEDS CARRIED FIRE", CREAM)
        relayNodes[definition.nodeId] = node
        table.insert(interactions, {
            actionText = "DELIVER ROOTFIRE",
            holdDuration = 0.7,
            interactionId = definition.interactionId,
            objectText = definition.label,
            target = node,
        })

        for rootIndex = -1, 1 do
            local rootedWall = part(
                layer,
                "RootedWall",
                Vector3.new(3.5, 14 + (rootIndex + 1) * 2, 3.5),
                CFrame.new(node.Position + Vector3.new(rootIndex * 5.5, 5 + (rootIndex + 1), 4.5))
                    * CFrame.Angles(math.rad(rootIndex * 8), 0, math.rad(rootIndex * 10)),
                DARK_BARK,
                Enum.Material.Wood,
                true
            )
            rootedWall:SetAttribute("BlackoutNodeId", definition.nodeId)
        end
    end

    local decisions = {}
    for _, definition in
        {
            {
                color = MEADOW,
                decisionId = "restore_farmland",
                interactionId = runtimeIds.InteractionIds.BlackoutDecisionFarmland,
                label = "RESTORE FARMLAND",
                offset = Vector3.new(-16, 2.5, 16),
            },
            {
                color = Color3.fromRGB(71, 139, 84),
                decisionId = "wild_regrowth",
                interactionId = runtimeIds.InteractionIds.BlackoutDecisionWild,
                label = "ALLOW WILD REGROWTH",
                offset = Vector3.new(0, 2.5, 20),
            },
            {
                color = FOXFIRE,
                decisionId = "shared_agroforest",
                interactionId = runtimeIds.InteractionIds.BlackoutDecisionShared,
                label = "CREATE SHARED AGROFOREST",
                offset = Vector3.new(16, 2.5, 16),
            },
        }
    do
        local seedling = orb(
            layer,
            "GreenwardChoice_" .. definition.decisionId,
            bossCenter + definition.offset,
            5,
            definition.color,
            Enum.Material.SmoothPlastic
        )
        seedling.Transparency = 0.58
        seedling:SetAttribute("BlackoutInteraction", "chapter_decision")
        seedling:SetAttribute("BlackoutDecisionId", definition.decisionId)
        CollectionService:AddTag(seedling, runtimeIds.ExpeditionBlackoutTag)
        billboard(seedling, definition.label, CREAM)
        decisions[definition.decisionId] = seedling
        table.insert(interactions, {
            actionText = "VOTE " .. definition.label,
            holdDuration = 1.1,
            interactionId = definition.interactionId,
            objectText = "Permanent Greenward Choice",
            target = seedling,
        })
    end

    return {
        decisions = decisions,
        fireSource = fireSource,
        interactions = interactions,
        model = layer,
        relayNodes = relayNodes,
    }
end

function BramblewakeBuilder.build(
    parent: Instance,
    manifest: any,
    generator: any,
    catalog: any,
    runtimeIds: any
): any
    local existing = parent:FindFirstChild("BramblewakeExpedition")
    if existing ~= nil then
        existing:Destroy()
    end

    local expedition = Instance.new("Model")
    expedition.Name = "BramblewakeExpedition"
    expedition:SetAttribute("RegionId", manifest.regionId)
    expedition:SetAttribute("ManifestHash", manifest.hash)
    expedition:SetAttribute("Seed", manifest.seed)
    expedition:SetAttribute("Source", manifest.source)
    expedition:SetAttribute("Ready", false)
    expedition.Parent = parent

    local centers: { Vector3 } = {}
    local eventInteractions = {}
    local eventSockets: { [string]: BasePart } = {}
    local eliteArena = nil
    local oldGrowthCenter: Vector3? = nil
    local extractionTarget: BasePart? = nil
    for _, placement in manifest.modules do
        centers[placement.index] = ORIGIN
            + Vector3.new(placement.cellX * catalog.CellSize, 0, placement.cellZ * catalog.CellSize)
    end

    for _, placement in manifest.modules do
        local definition = generator.moduleDefinition(placement.moduleId)
        local center = centers[placement.index]
        local module = Instance.new("Model")
        module.Name = string.format("Module_%02d", placement.index)
        module:SetAttribute("ContentId", placement.moduleId)
        module:SetAttribute("DisplayName", definition.displayName)
        module:SetAttribute("SequenceIndex", placement.index)
        module:SetAttribute("CellX", placement.cellX)
        module:SetAttribute("CellZ", placement.cellZ)
        module.Parent = expedition
        pcall(function()
            module.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
        end)
        CollectionService:AddTag(module, runtimeIds.ExpeditionModuleTag)

        part(
            module,
            "StreamingCellCollision",
            Vector3.new(catalog.CellSize, 5, catalog.CellSize),
            CFrame.new(center + Vector3.new(0, -2.5, 0)),
            if placement.index % 2 == 0 then GRASS else Color3.fromRGB(54, 88, 58),
            Enum.Material.Grass
        )
        part(
            module,
            "PathClearing",
            Vector3.new(24, 0.55, 24),
            CFrame.new(center + Vector3.new(0, 0.25, 0)),
            PATH,
            Enum.Material.Ground
        )
        if placement.index > 1 then
            pathArm(module, center, centers[placement.index - 1])
        end
        if placement.index < #manifest.modules then
            pathArm(module, center, centers[placement.index + 1])
        end

        moduleDressing(module, center, manifest.seed + placement.index * 97)

        for cornerIndex = 1, 4 do
            local x = if cornerIndex == 1 or cornerIndex == 4 then -27 else 27
            local z = if cornerIndex <= 2 then -27 else 27
            tree(module, center + Vector3.new(x, 0, z), 0.62 + (cornerIndex % 2) * 0.08)
        end
        buildModuleVisual(module, definition.visual, center)
        if definition.eliteId == "elite_old_growth" then
            oldGrowthCenter = center
            local fireSource = orb(
                module,
                "OldGrowthFireSource",
                center + Vector3.new(-20, 3.4, -12),
                4.2,
                AMBER,
                Enum.Material.SmoothPlastic
            )
            fireSource.Transparency = 0.48
            fireSource:SetAttribute("EliteId", definition.eliteId)
            fireSource:SetAttribute("EliteInteraction", "fire_source")
            billboard(fireSource, "LANTERN FIRE", CREAM)

            local rootHeart = orb(
                module,
                "OldGrowthRootHeart",
                center + Vector3.new(20, 4.2, 12),
                5.2,
                FOXFIRE,
                Enum.Material.SmoothPlastic
            )
            rootHeart.Transparency = 0.56
            rootHeart:SetAttribute("EliteId", definition.eliteId)
            rootHeart:SetAttribute("EliteInteraction", "root_heart")
            billboard(rootHeart, "ROOT HEART", CREAM)
            CollectionService:AddTag(fireSource, runtimeIds.ExpeditionEliteTag)
            CollectionService:AddTag(rootHeart, runtimeIds.ExpeditionEliteTag)
            eliteArena = {
                center = center,
                fireSource = fireSource,
                rootHeart = rootHeart,
            }
        end
        if definition.role == "extraction" then
            local target = module:FindFirstChild("WayhomeLight")
            assert(
                target ~= nil and target:IsA("BasePart"),
                "Wayhome Gate is missing its extraction target"
            )
            target:SetAttribute("ContentId", placement.moduleId)
            target:SetAttribute("ExtractionId", "extraction_bw_wayhome")
            CollectionService:AddTag(target, runtimeIds.ExpeditionExtractionTag)
            extractionTarget = target
        end

        if placement.poiId ~= nil then
            buildPointOfInterest(
                module,
                center,
                generator.pointOfInterestDefinition(placement.poiId),
                runtimeIds
            )
        elseif placement.eventId ~= nil then
            local eventResult = buildEventSocket(
                module,
                center,
                generator.eventDefinition(placement.eventId),
                runtimeIds
            )
            eventSockets[placement.eventId] = eventResult.socket
            for _, interaction in eventResult.interactions do
                table.insert(eventInteractions, interaction)
            end
        end

        if placement.index == 1 then
            local marker = orb(
                module,
                "BramblewakeArrival",
                center + Vector3.new(0, 5, 0),
                4,
                FOXFIRE,
                Enum.Material.Neon
            )
            marker.Transparency = 0.25
            billboard(marker, "BRAMBLEWAKE WOODS", CREAM)
        end
    end

    local bossArena = buildWardenSeal(
        expedition,
        assert(oldGrowthCenter, "Old Growth center is missing"),
        centers,
        catalog.CellSize,
        runtimeIds
    )
    local blackout = buildBlackoutLayer(expedition, centers, bossArena.center, runtimeIds)
    buildBackdrop(expedition, centers)

    local generatedParts = 0
    for _, descendant in expedition:GetDescendants() do
        if descendant:IsA("BasePart") then
            generatedParts += 1
        end
    end
    expedition:SetAttribute("GeneratedPartCount", generatedParts)
    expedition:SetAttribute("ModuleCount", #manifest.modules)
    expedition:SetAttribute("PointOfInterestCount", catalog.PointOfInterestCount)
    expedition:SetAttribute("EventCount", catalog.EventCount)
    expedition:SetAttribute("EventInteractionCount", #eventInteractions)
    expedition:SetAttribute("ExtractionReady", extractionTarget ~= nil)
    expedition:SetAttribute("BossArenaReady", bossArena ~= nil)
    expedition:SetAttribute("BlackoutLayerReady", blackout ~= nil)
    expedition:SetAttribute("Ready", true)

    local moduleCenters = {}
    for index, center in centers do
        table.insert(moduleCenters, {
            index = index,
            moduleId = manifest.modules[index].moduleId,
            position = center,
        })
    end
    return {
        model = expedition,
        entryCFrame = CFrame.new(centers[1] + Vector3.new(0, 5, 0)),
        extractionTarget = assert(extractionTarget, "Bramblewake extraction target is missing"),
        eventInteractions = eventInteractions,
        eventSockets = eventSockets,
        eliteArena = assert(eliteArena, "Old Growth elite arena is missing"),
        bossArena = bossArena,
        blackout = blackout,
        moduleCenters = moduleCenters,
        partCount = generatedParts,
    }
end

return table.freeze(BramblewakeBuilder)
