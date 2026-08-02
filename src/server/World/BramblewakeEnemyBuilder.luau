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
    else
        core = rootling(model, origin)
    end
    model.PrimaryPart = core

    local highlight = Instance.new("Highlight")
    highlight.Name = "ThreatOutline"
    highlight.FillColor = Color3.fromRGB(80, 29, 29)
    highlight.FillTransparency = 0.76
    highlight.OutlineColor = Color3.fromRGB(255, 143, 91)
    highlight.OutlineTransparency = 0.16
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = model

    local flatTarget = Vector3.new(target.X, core.Position.Y, target.Z)
    if (flatTarget - core.Position).Magnitude > 0.01 then
        model:PivotTo(CFrame.lookAt(core.Position, flatTarget))
    end
    return model
end

return table.freeze(BramblewakeEnemyBuilder)
