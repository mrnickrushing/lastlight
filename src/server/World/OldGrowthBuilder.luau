--!strict

local OldGrowthBuilder = {}

local function part(
    parent: Model,
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material,
    shape: Enum.PartType?
): Part
    local item = Instance.new("Part")
    item.Name = name
    item.Size = size
    item.CFrame = cframe
    item.Color = color
    item.Material = material
    item.Shape = shape or Enum.PartType.Block
    item.Anchored = true
    item.CanCollide = false
    item.CanTouch = false
    item.CastShadow = true
    item.TopSurface = Enum.SurfaceType.Smooth
    item.BottomSurface = Enum.SurfaceType.Smooth
    item.Parent = parent
    return item
end

function OldGrowthBuilder.build(origin: Vector3, target: Vector3, maxHealth: number): Model
    local model = Instance.new("Model")
    model.Name = "OldGrowthElite"
    model:SetAttribute("EliteId", "elite_old_growth")
    model:SetAttribute("EliteDisplayName", "Old Growth")
    model:SetAttribute("EliteHealth", maxHealth)
    model:SetAttribute("EliteMaxHealth", maxHealth)
    model:SetAttribute("EliteShielded", false)

    local core = part(
        model,
        "AncientTrunk",
        Vector3.new(10, 18, 10),
        CFrame.new(origin + Vector3.new(0, 9, 0)),
        Color3.fromRGB(57, 39, 31),
        Enum.Material.Wood,
        Enum.PartType.Ball
    )
    model.PrimaryPart = core

    part(
        model,
        "BarkCrown",
        Vector3.new(13, 7, 9),
        CFrame.new(origin + Vector3.new(0, 19, 0)),
        Color3.fromRGB(45, 72, 48),
        Enum.Material.Grass,
        Enum.PartType.Ball
    )
    for index = 1, 5 do
        local angle = (index / 5) * math.pi * 2
        part(
            model,
            "CanopyMass",
            Vector3.new(8, 6, 8),
            CFrame.new(
                origin + Vector3.new(math.cos(angle) * 7, 20 + (index % 2) * 3, math.sin(angle) * 7)
            ),
            if index % 2 == 0 then Color3.fromRGB(58, 91, 55) else Color3.fromRGB(38, 68, 48),
            Enum.Material.Grass,
            Enum.PartType.Ball
        )
    end

    for side = -1, 1, 2 do
        part(
            model,
            "CathedralArm",
            Vector3.new(3, 15, 3),
            CFrame.new(origin + Vector3.new(side * 7, 11, 0))
                * CFrame.Angles(0, 0, math.rad(side * 35)),
            Color3.fromRGB(70, 48, 34),
            Enum.Material.Wood,
            nil
        )
        part(
            model,
            "RootFoot",
            Vector3.new(3.2, 3.2, 13),
            CFrame.new(origin + Vector3.new(side * 4.5, 1.4, 3))
                * CFrame.Angles(0, math.rad(side * 18), 0),
            Color3.fromRGB(68, 45, 32),
            Enum.Material.Wood,
            nil
        )
        part(
            model,
            "OldEye",
            Vector3.new(0.9, 0.9, 0.45),
            CFrame.new(origin + Vector3.new(side * 1.7, 11.5, -5)),
            Color3.fromRGB(112, 214, 174),
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
    end

    local heart = part(
        model,
        "AmberHeart",
        Vector3.new(3.8, 5.4, 1.5),
        CFrame.new(origin + Vector3.new(0, 7.5, -5.15)),
        Color3.fromRGB(255, 187, 76),
        Enum.Material.Neon,
        Enum.PartType.Ball
    )
    heart:SetAttribute("WeakPoint", true)

    local highlight = Instance.new("Highlight")
    highlight.Name = "EliteOutline"
    highlight.FillColor = Color3.fromRGB(55, 83, 57)
    highlight.FillTransparency = 0.82
    highlight.OutlineColor = Color3.fromRGB(255, 187, 76)
    highlight.OutlineTransparency = 0.12
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = model

    local flatTarget = Vector3.new(target.X, core.Position.Y, target.Z)
    if (flatTarget - core.Position).Magnitude > 0.01 then
        model:PivotTo(CFrame.lookAt(core.Position, flatTarget))
    end
    return model
end

function OldGrowthBuilder.setState(model: Model, health: number, shielded: boolean, marked: boolean)
    model:SetAttribute("EliteHealth", math.max(0, health))
    model:SetAttribute("EliteShielded", shielded)
    model:SetAttribute("LastLightMarked", marked)
    local heart = model:FindFirstChild("AmberHeart")
    if heart ~= nil and heart:IsA("BasePart") then
        heart.Color = if shielded
            then Color3.fromRGB(92, 118, 91)
            elseif marked then Color3.fromRGB(255, 222, 112)
            else Color3.fromRGB(255, 187, 76)
        heart.Material = if shielded then Enum.Material.SmoothPlastic else Enum.Material.Neon
        heart.Transparency = if shielded then 0.34 else 0
    end
    local highlight = model:FindFirstChild("EliteOutline")
    if highlight ~= nil and highlight:IsA("Highlight") then
        highlight.OutlineColor = if shielded
            then Color3.fromRGB(112, 155, 119)
            elseif marked then Color3.fromRGB(255, 222, 112)
            else Color3.fromRGB(255, 187, 76)
        highlight.FillTransparency = if marked then 0.62 else 0.82
    end
    if model:GetAttribute("EnemyVisualReady") == true then
        local authored = model:FindFirstChild("AuthoredEnemyVisual")
        for _, descendant in model:GetDescendants() do
            if
                descendant:IsA("BasePart")
                and (authored == nil or not descendant:IsDescendantOf(authored))
            then
                descendant.Transparency = 1
                descendant.CastShadow = false
            end
        end
    end
end

return table.freeze(OldGrowthBuilder)
