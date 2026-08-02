--!strict

local WardenStagBuilder = {}

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

local function antlerBranch(model: Model, origin: Vector3, side: number, branchIndex: number): Part
    return part(
        model,
        if side < 0 then "AntlerLeft" else "AntlerRight",
        Vector3.new(1.15, 7 + branchIndex * 1.4, 1.15),
        CFrame.new(
            origin
                + Vector3.new(
                    side * (3.2 + branchIndex * 1.6),
                    3 + branchIndex * 2.1,
                    branchIndex * 0.35
                )
        ) * CFrame.Angles(0, 0, math.rad(side * (24 + branchIndex * 8))),
        Color3.fromRGB(212, 207, 178),
        Enum.Material.SmoothPlastic,
        nil
    )
end

function WardenStagBuilder.build(origin: Vector3, target: Vector3, maxHealth: number): Model
    local model = Instance.new("Model")
    model.Name = "WardenStagBoss"
    model:SetAttribute("BossId", "boss_warden_stag")
    model:SetAttribute("BossDisplayName", "Warden Stag")
    model:SetAttribute("BossHealth", maxHealth)
    model:SetAttribute("BossMaxHealth", maxHealth)
    model:SetAttribute("BossStatus", "cleansing")
    model:SetAttribute("BossOutcome", "")

    local body = part(
        model,
        "AncientBody",
        Vector3.new(11, 8, 18),
        CFrame.new(origin + Vector3.new(0, 10, 0)),
        Color3.fromRGB(66, 48, 37),
        Enum.Material.Wood,
        Enum.PartType.Ball
    )
    model.PrimaryPart = body
    part(
        model,
        "MossMantle",
        Vector3.new(11.5, 3.8, 13),
        CFrame.new(origin + Vector3.new(0, 13, 1.5)),
        Color3.fromRGB(48, 83, 57),
        Enum.Material.Grass,
        Enum.PartType.Ball
    )
    local head = part(
        model,
        "WardenHead",
        Vector3.new(6.5, 7, 7.5),
        CFrame.new(origin + Vector3.new(0, 15.5, -9)),
        Color3.fromRGB(72, 52, 40),
        Enum.Material.Wood,
        Enum.PartType.Ball
    )
    for side = -1, 1, 2 do
        for branchIndex = 1, 3 do
            antlerBranch(model, head.Position + Vector3.new(0, 3, 0), side, branchIndex)
        end
        part(
            model,
            "MemoryEye",
            Vector3.new(0.85, 0.85, 0.45),
            CFrame.new(head.Position + Vector3.new(side * 1.5, 0.8, -3.4)),
            Color3.fromRGB(112, 220, 179),
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
        for legIndex = -1, 1, 2 do
            part(
                model,
                "RootLeg",
                Vector3.new(2.4, 10, 2.4),
                CFrame.new(origin + Vector3.new(side * 3.7, 4.5, legIndex * 5.5))
                    * CFrame.Angles(math.rad(legIndex * 6), 0, math.rad(side * 5)),
                Color3.fromRGB(57, 40, 32),
                Enum.Material.Wood,
                nil
            )
        end
    end

    local heart = part(
        model,
        "MemoryHeart",
        Vector3.new(4.5, 5.8, 1.8),
        CFrame.new(origin + Vector3.new(0, 11, -8.5)),
        Color3.fromRGB(255, 190, 85),
        Enum.Material.Neon,
        Enum.PartType.Ball
    )
    heart:SetAttribute("WeakPoint", true)

    local highlight = Instance.new("Highlight")
    highlight.Name = "BossOutline"
    highlight.FillColor = Color3.fromRGB(48, 82, 56)
    highlight.FillTransparency = 0.84
    highlight.OutlineColor = Color3.fromRGB(255, 190, 85)
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = model

    local flatTarget = Vector3.new(target.X, body.Position.Y, target.Z)
    if (flatTarget - body.Position).Magnitude > 0.01 then
        model:PivotTo(CFrame.lookAt(body.Position, flatTarget))
    end
    return model
end

function WardenStagBuilder.setState(
    model: Model,
    health: number,
    status: string,
    marked: boolean,
    brokenAntlers: { [string]: boolean },
    outcome: string?
)
    model:SetAttribute("BossHealth", math.max(0, health))
    model:SetAttribute("BossStatus", status)
    model:SetAttribute("BossOutcome", outcome or "")
    model:SetAttribute("LastLightMarked", marked)
    local exposed = status == "vulnerable"
    local complete = status == "complete"
    local heart = model:FindFirstChild("MemoryHeart")
    if heart ~= nil and heart:IsA("BasePart") then
        heart.Color = if complete
            then Color3.fromRGB(112, 220, 179)
            elseif exposed then Color3.fromRGB(255, 190, 85)
            else Color3.fromRGB(92, 117, 96)
        heart.Material = if exposed or complete
            then Enum.Material.Neon
            else Enum.Material.SmoothPlastic
        heart.Transparency = if exposed or complete then 0 else 0.38
    end
    local highlight = model:FindFirstChild("BossOutline")
    if highlight ~= nil and highlight:IsA("Highlight") then
        highlight.OutlineColor = if complete
            then Color3.fromRGB(112, 220, 179)
            elseif marked then Color3.fromRGB(255, 226, 124)
            elseif exposed then Color3.fromRGB(255, 190, 85)
            else Color3.fromRGB(112, 155, 119)
        highlight.FillTransparency = if marked then 0.62 else 0.84
    end
    for _, descendant in model:GetChildren() do
        if descendant:IsA("BasePart") then
            if descendant.Name == "AntlerLeft" then
                descendant.Transparency = if brokenAntlers.antler_left then 0.78 else 0
            elseif descendant.Name == "AntlerRight" then
                descendant.Transparency = if brokenAntlers.antler_right then 0.78 else 0
            end
        end
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

return table.freeze(WardenStagBuilder)
