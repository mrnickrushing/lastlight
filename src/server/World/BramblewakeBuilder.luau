--!strict

local CollectionService = game:GetService("CollectionService")
local WorldSignBuilder = require(script.Parent.WorldSignBuilder)

local BramblewakeBuilder = {}

local GRASS = Color3.fromRGB(40, 74, 48)
local DEEP_GRASS = Color3.fromRGB(18, 45, 34)
local PATH = Color3.fromRGB(79, 64, 44)
local BARK = Color3.fromRGB(58, 38, 29)
local DARK_BARK = Color3.fromRGB(32, 25, 23)
local STONE = Color3.fromRGB(58, 67, 63)
local AMBER = Color3.fromRGB(255, 178, 71)
local FOXFIRE = Color3.fromRGB(94, 206, 176)
local MEADOW = Color3.fromRGB(151, 123, 59)
local CREAM = Color3.fromRGB(244, 230, 197)
local MOSS = Color3.fromRGB(52, 83, 49)
local WET_EARTH = Color3.fromRGB(61, 50, 36)
local FOG_GLASS = Color3.fromRGB(119, 149, 143)

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
    pointLight.Shadows = true
    pointLight.Parent = target
end

local function surfaceGrain(target: BasePart, color: Color3, transparency: number)
    local decal = Instance.new("Decal")
    decal.Name = "MaterialVariation"
    decal.Color3 = color
    decal.Transparency = transparency
    decal.Face = Enum.NormalId.Top
    decal.Parent = target
end

local function groundPatch(
    parent: Instance,
    center: Vector3,
    size: Vector3,
    color: Color3,
    material: Enum.Material
)
    local patch = part(
        parent,
        "BramblewakeGroundPatch",
        size,
        CFrame.new(center + Vector3.new(0, 0.18, 0)) * CFrame.Angles(0, center.X * 0.011, 0),
        color,
        material,
        false
    )
    patch.Transparency = 0.07
    patch.CanQuery = false
    return patch
end

local function queueItemAsset(
    placements: { any },
    target: BasePart,
    assetId: string,
    scale: number,
    seed: number,
    yaw: number?,
    bottomY: number?
)
    table.insert(placements, {
        assetId = assetId,
        fallbackKind = "asset_replacement",
        position = Vector3.new(
            target.Position.X,
            bottomY or (target.Position.Y - target.Size.Y * 0.5),
            target.Position.Z
        ),
        scale = scale,
        yaw = yaw or 0,
        seed = seed,
        swayTag = nil,
        parent = target.Parent,
        fallbackInstance = target,
    })
end

local function fernCluster(
    parent: Instance,
    center: Vector3,
    scale: number,
    ambientSwayTag: string?
)
    for blade = 1, 6 do
        local angle = (blade / 6) * math.pi * 2
        local frond = part(
            parent,
            "BrambleFern",
            Vector3.new(0.32 * scale, 0.18 * scale, 2.9 * scale),
            CFrame.new(
                center
                    + Vector3.new(
                        math.cos(angle) * 0.65 * scale,
                        0.55 * scale,
                        math.sin(angle) * 0.65 * scale
                    )
            ) * CFrame.Angles(math.rad(23), angle, math.rad(math.sin(angle) * 8)),
            if blade % 2 == 0 then MOSS else Color3.fromRGB(35, 69, 43),
            Enum.Material.Grass,
            false
        )
        frond.CanQuery = false
        if ambientSwayTag ~= nil and (blade == 2 or blade == 5) then
            CollectionService:AddTag(frond, ambientSwayTag)
        end
    end
end

local function rootTangle(parent: Instance, center: Vector3, scale: number, seed: number)
    local random = Random.new(seed)
    for root = 1, 4 do
        local angle = random:NextNumber(0, math.pi * 2)
        local length = random:NextNumber(7, 13) * scale
        local tangle = part(
            parent,
            "ExposedWetRoot",
            Vector3.new(0.7 * scale, length, 0.7 * scale),
            CFrame.new(
                center
                    + Vector3.new(
                        math.cos(angle) * 2.2 * scale,
                        0.65 * scale,
                        math.sin(angle) * 2.2 * scale
                    )
            )
                * CFrame.Angles(math.rad(84), angle, math.rad(random:NextNumber(-10, 10))),
            if root % 2 == 0 then DARK_BARK else BARK,
            Enum.Material.Wood,
            false
        )
        tangle.Shape = Enum.PartType.Cylinder
        tangle.CanQuery = false
    end
end

local function lowMist(parent: Instance, center: Vector3, size: Vector3, transparency: number)
    local mist = part(
        parent,
        "BlueGroundMist",
        size,
        CFrame.new(center + Vector3.new(0, 1.2, 0)),
        FOG_GLASS,
        Enum.Material.Glass,
        false
    )
    mist.Transparency = transparency
    mist.CastShadow = false
    mist.CanQuery = false
end

local function fireflyCluster(
    parent: Instance,
    center: Vector3,
    color: Color3,
    count: number,
    spread: number,
    seed: number,
    ambientMoteTag: string?
)
    local random = Random.new(seed)
    for _ = 1, count do
        local mote = orb(
            parent,
            "BrambleMote",
            center
                + Vector3.new(
                    random:NextNumber(-spread, spread),
                    random:NextNumber(1.8, 8),
                    random:NextNumber(-spread, spread)
                ),
            random:NextNumber(0.14, 0.32),
            color,
            Enum.Material.Neon
        )
        mote.Transparency = random:NextNumber(0.05, 0.3)
        mote.CanQuery = false
        if ambientMoteTag ~= nil then
            CollectionService:AddTag(mote, ambientMoteTag)
        end
    end
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

local function _objectIcon(target: BasePart, kind: string, color: Color3)
    local gui = Instance.new("BillboardGui")
    gui.Name = "ObjectIcon"
    gui.Adornee = target
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.Size = UDim2.fromOffset(42, 42)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 5.8, 0)
    gui.MaxDistance = 72
    gui.Parent = target

    local glyph = Instance.new("TextLabel")
    glyph.Name = "IconGlyph"
    glyph.BackgroundColor3 = Color3.fromRGB(10, 21, 19)
    glyph.BackgroundTransparency = 0.05
    glyph.BorderSizePixel = 0
    glyph.Size = UDim2.fromScale(1, 1)
    glyph.Font = Enum.Font.GothamBold
    glyph.Text = if kind == "rootfire"
        then "✦"
        elseif kind == "livingroot" or kind == "root" then "✤"
        elseif kind == "wayhome" then "⌂"
        elseif kind == "event" or kind == "step" then "!"
        elseif kind == "antler" then "♢"
        else "✦"
    glyph.TextColor3 = color
    glyph.TextScaled = true
    glyph.ZIndex = 10
    glyph.Parent = gui
    local glyphCorner = Instance.new("UICorner")
    glyphCorner.CornerRadius = UDim.new(0, 10)
    glyphCorner.Parent = glyph

    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.fromScale(1, 1)
    viewport.BackgroundColor3 = Color3.fromRGB(15, 27, 24)
    viewport.BackgroundTransparency = 0.08
    viewport.BorderSizePixel = 0
    viewport.Ambient = Color3.fromRGB(210, 224, 212)
    viewport.LightColor = Color3.fromRGB(255, 214, 146)
    viewport.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = viewport
    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewport
    local camera = Instance.new("Camera")
    camera.CFrame = CFrame.new(0, 0.2, 6)
    camera.FieldOfView = 28
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    local icon = Instance.new("Part")
    icon.Name = kind .. "Icon"
    icon.Anchored = true
    icon.CanCollide = false
    icon.CanQuery = false
    icon.Size = if kind == "rootfire"
        then Vector3.new(1.4, 1.8, 1.4)
        else Vector3.new(1.8, 1.8, 1.8)
    icon.Position = Vector3.new(0, 0, 0)
    icon.Color = color
    icon.Material = Enum.Material.Neon
    icon.Shape = if kind == "rootfire" then Enum.PartType.Ball else Enum.PartType.Cylinder
    icon.Parent = worldModel
end

-- Interactable identity is authored by the physical world prop itself. Keep
-- this compatibility hook for older callers without adding floating UI cards.
local function objectIcon(_target: BasePart, _kind: string, _color: Color3) end

local function destinationCairns(parent: Instance, center: Vector3, color: Color3, radius: number)
    local placements = {
        { angle = math.rad(28), radius = radius * 0.92, lean = math.rad(-5) },
        { angle = math.rad(157), radius = radius * 1.08, lean = math.rad(4) },
        { angle = math.rad(262), radius = radius * 0.84, lean = math.rad(-3) },
    }
    for index, placement in placements do
        local offset = Vector3.new(
            math.cos(placement.angle) * placement.radius,
            0,
            math.sin(placement.angle) * placement.radius
        )
        local base = center + offset
        local stone = part(
            parent,
            "DestinationCairnStone",
            Vector3.new(1.75, 1.35, 1.45),
            CFrame.new(base + Vector3.new(0, 0.68, 0))
                * CFrame.Angles(0, placement.angle + 0.37, placement.lean),
            if index == 2 then Color3.fromRGB(70, 81, 77) else STONE,
            Enum.Material.Slate,
            false
        )
        stone.Shape = Enum.PartType.Ball
        local inset = part(
            parent,
            "DestinationCairnInset",
            Vector3.new(0.42, 0.42, 0.16),
            CFrame.lookAt(base + Vector3.new(0, 1.62, 0), center),
            color,
            Enum.Material.Glass,
            false
        )
        inset.Transparency = 0.12
        inset:SetAttribute("CairnIndex", index)
    end
end

local function cagedLanternShell(parent: Instance, center: Vector3, scale: number, prefix: string)
    part(
        parent,
        prefix .. "StoneFoot",
        Vector3.new(4.4, 0.8, 4.4) * scale,
        CFrame.new(center + Vector3.new(0, -2.2 * scale, 0)),
        STONE,
        Enum.Material.Slate,
        false
    )
    for sideX = -1, 1, 2 do
        for sideZ = -1, 1, 2 do
            part(
                parent,
                prefix .. "CageBar",
                Vector3.new(0.28, 5.1, 0.28) * scale,
                CFrame.new(center + Vector3.new(sideX * 1.45 * scale, 0, sideZ * 1.45 * scale))
                    * CFrame.Angles(0, 0, math.rad(sideX * sideZ * 2.5)),
                Color3.fromRGB(48, 52, 56),
                Enum.Material.Metal,
                false
            )
        end
    end
    local hood = part(
        parent,
        prefix .. "RainHood",
        Vector3.new(4.8, 1.1, 4.8) * scale,
        CFrame.new(center + Vector3.new(0, 2.72 * scale, 0)),
        DARK_BARK,
        Enum.Material.Slate,
        false
    )
    hood.Shape = Enum.PartType.Cylinder
end

local function livingRootShell(parent: Instance, center: Vector3, scale: number, prefix: string)
    part(
        parent,
        prefix .. "RootMound",
        Vector3.new(5.8, 1.2, 5.2) * scale,
        CFrame.new(center + Vector3.new(0, -2.15 * scale, 0)),
        Color3.fromRGB(56, 67, 50),
        Enum.Material.Ground,
        false
    )
    for rootIndex = 1, 3 do
        local angle = (rootIndex / 3) * math.pi * 2
        part(
            parent,
            prefix .. "LivingRoot",
            Vector3.new(0.72, 5.6 + (rootIndex % 2) * 1.1, 0.72) * scale,
            CFrame.new(
                center
                    + Vector3.new(
                        math.cos(angle) * 1.75 * scale,
                        -0.2 * scale,
                        math.sin(angle) * 1.75 * scale
                    )
            )
                * CFrame.Angles(
                    math.rad(math.sin(angle) * 10),
                    angle,
                    math.rad(math.cos(angle) * 28)
                ),
            if rootIndex % 2 == 0 then BARK else DARK_BARK,
            Enum.Material.Wood,
            false
        )
    end
end

local function chapterChoiceShrine(
    parent: Instance,
    center: Vector3,
    color: Color3,
    decisionId: string
): BasePart
    local target = orb(
        parent,
        "GreenwardChoice_" .. decisionId,
        center + Vector3.new(0, 1.3, 0),
        1.15,
        color,
        Enum.Material.Glass
    )
    target.Transparency = 0.35
    part(
        parent,
        "ChoicePlanter_" .. decisionId,
        Vector3.new(6.8, 1.5, 5.2),
        CFrame.new(center + Vector3.new(0, -0.25, 0)),
        Color3.fromRGB(78, 58, 39),
        Enum.Material.WoodPlanks,
        false
    )
    local stemCount = 2
    for stemIndex = 1, stemCount do
        local x = ((stemIndex * 17) % 9 - 4) * 0.55
        local z = ((stemIndex * 11) % 7 - 3) * 0.48
        local height = 2.4 + (stemIndex % 3) * 0.65
        part(
            parent,
            "ChoicePlantStem_" .. decisionId,
            Vector3.new(0.28, height, 0.28),
            CFrame.new(center + Vector3.new(x, 0.5 + height * 0.5, z))
                * CFrame.Angles(0, 0, math.rad((stemIndex % 2 == 0 and 1 or -1) * 8)),
            if decisionId == "restore_farmland" then MEADOW else MOSS,
            Enum.Material.Grass,
            false
        )
        local leaf = part(
            parent,
            "ChoicePlantLeaf_" .. decisionId,
            Vector3.new(1.15, 0.22, 0.65),
            CFrame.new(center + Vector3.new(x + 0.35, 1.4 + height * 0.62, z)),
            color,
            Enum.Material.LeafyGrass,
            false
        )
        leaf.Shape = Enum.PartType.Wedge
    end
    target:SetAttribute("PhysicalChoiceShrine", true)
    return target
end

local function tree(parent: Instance, position: Vector3, scale: number)
    local trunk = part(
        parent,
        "BrambleTrunk",
        Vector3.new(2.4 * scale, 14 * scale, 2.4 * scale),
        CFrame.new(position + Vector3.new(0, 7 * scale, 0)),
        BARK,
        Enum.Material.Wood
    )
    for side = -1, 1, 2 do
        local branch = part(
            parent,
            "BrambleBranch",
            Vector3.new(0.65 * scale, 5 * scale, 0.65 * scale),
            CFrame.new(position + Vector3.new(side * 2.3 * scale, 7 * scale, 0))
                * CFrame.Angles(0, 0, math.rad(side * 48)),
            BARK,
            Enum.Material.Wood,
            false
        )
        branch.CanQuery = false
    end
    for layer = 1, 2 do
        local crownPosition = position + Vector3.new(0, (11 + layer * 4.2) * scale, 0)
        local crownSize =
            Vector3.new((11 - layer * 1.5) * scale, (7 - layer) * scale, (11 - layer * 1.5) * scale)
        for half = 1, 2 do
            local crown = part(
                parent,
                "BrambleCrown",
                crownSize,
                CFrame.new(crownPosition)
                    * CFrame.Angles(0, if half == 1 then 0.15 else math.pi + 0.15, 0),
                if layer == 1 then DEEP_GRASS else GRASS,
                Enum.Material.Grass,
                false
            )
            crown.Shape = Enum.PartType.Wedge
            crown.CanQuery = false
        end
    end
    trunk.CanQuery = false
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

local function lantern(parent: Instance, position: Vector3, scale: number, ambientLightTag: string?)
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
    if ambientLightTag ~= nil then
        CollectionService:AddTag(glow, ambientLightTag)
    end
end

local function pathArm(parent: Instance, center: Vector3, neighbor: Vector3)
    local delta = neighbor - center
    local target = center + delta.Unit * 38
    local midpoint = (center + target) / 2 + Vector3.new(0, 0.28, 0)
    local roadFrame = CFrame.lookAt(midpoint, target)
    local road = part(
        parent,
        "CriticalPath",
        Vector3.new(16, 0.5, (target - center).Magnitude + 4),
        roadFrame,
        PATH,
        Enum.Material.Ground
    )
    road.Reflectance = 0.02
    local wear = part(
        parent,
        "EvacuationTrailWear",
        Vector3.new(5.2, 0.16, (target - center).Magnitude + 3.5),
        roadFrame * CFrame.new(0, 0.31, 0),
        Color3.fromRGB(95, 72, 48),
        Enum.Material.Mud,
        false
    )
    wear.CanQuery = false
    wear.CastShadow = false
    for side = -1, 1, 2 do
        local edge = part(
            parent,
            "EvacuationTrailEdge",
            Vector3.new(0.72, 0.32, (target - center).Magnitude + 3.2),
            roadFrame * CFrame.new(side * 7.15, 0.34, 0),
            if side < 0 then DARK_BARK else Color3.fromRGB(82, 91, 58),
            Enum.Material.Ground,
            false
        )
        edge.CanQuery = false
    end
end

local function evacuationRoadMarker(
    parent: Instance,
    center: Vector3,
    neighbor: Vector3,
    sequenceIndex: number
)
    local direction = (neighbor - center).Unit
    local side = Vector3.new(-direction.Z, 0, direction.X)
    local base = center + direction * 13 + side * 9
    local lean = if sequenceIndex % 4 == 1 then math.rad(-4) else math.rad(4)
    local sign = WorldSignBuilder.createDirectionSign(
        parent,
        "EvacuationRoadMarker",
        CFrame.lookAt(base + Vector3.new(0, 5.4, 0), neighbor) * CFrame.Angles(0, 0, lean),
        "EVACUATION ROAD",
        CREAM
    )
    local board = sign.PrimaryPart
    assert(board ~= nil, "evacuation road sign has no board")
    board.Name = "EvacuationRoadSign"
end

local function window(parent: Instance, position: Vector3, rotation: number)
    local frame = part(
        parent,
        "FarmWindowFrame",
        Vector3.new(3.8, 2.6, 0.35),
        CFrame.new(position) * CFrame.Angles(0, rotation, 0),
        DARK_BARK,
        Enum.Material.WoodPlanks,
        false
    )
    local pane = part(
        parent,
        "FarmWindowGlow",
        Vector3.new(2.8, 1.7, 0.15),
        CFrame.new(position + Vector3.new(0, 0, -0.22)) * CFrame.Angles(0, rotation, 0),
        Color3.fromRGB(255, 196, 103),
        Enum.Material.Glass,
        false
    )
    pane.Transparency = 0.18
    local cross = part(
        parent,
        "FarmWindowCross",
        Vector3.new(0.18, 2.1, 0.2),
        CFrame.new(position + Vector3.new(0, 0, -0.32)) * CFrame.Angles(0, rotation, 0),
        CREAM,
        Enum.Material.Wood,
        false
    )
    cross.CanQuery = false
    frame.CanQuery = false
end

local function fence(parent: Instance, start: Vector3, count: number, spacing: number)
    for index = 0, count - 1 do
        local position = start + Vector3.new(index * spacing, 0, 0)
        part(
            parent,
            "FieldFencePost",
            Vector3.new(0.6, 2.8, 0.6),
            CFrame.new(position + Vector3.new(0, 1.4, 0)),
            BARK,
            Enum.Material.Wood
        )
        if index < count - 1 then
            part(
                parent,
                "FieldFenceRail",
                Vector3.new(spacing + 0.2, 0.35, 0.35),
                CFrame.new(position + Vector3.new(spacing / 2, 1.1, 0)),
                DARK_BARK,
                Enum.Material.WoodPlanks,
                false
            )
            part(
                parent,
                "FieldFenceRail",
                Vector3.new(spacing + 0.2, 0.35, 0.35),
                CFrame.new(position + Vector3.new(spacing / 2, 2.0, 0)),
                DARK_BARK,
                Enum.Material.WoodPlanks,
                false
            )
        end
    end
end

local function moduleDressing(parent: Instance, center: Vector3, seed: number, runtimeIds: any)
    local random = Random.new(seed)
    groundPatch(
        parent,
        center,
        Vector3.new(42, 0.28, 42),
        Color3.fromRGB(35, 61, 42),
        Enum.Material.LeafyGrass
    )
    groundPatch(
        parent,
        center + Vector3.new(0, 0.02, 0),
        Vector3.new(25, 0.22, 25),
        WET_EARTH,
        Enum.Material.Mud
    )
    lowMist(parent, center, Vector3.new(56, 1.4, 56), 0.84)
    for index = 1, 13 do
        local angle = random:NextNumber(0, math.pi * 2)
        local radius = random:NextNumber(12, 31)
        local position = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
        local stone = orb(
            parent,
            "TrailStone",
            position + Vector3.new(0, 0.55, 0),
            random:NextNumber(1.2, 2.6),
            if index % 2 == 0 then STONE else Color3.fromRGB(75, 85, 72),
            Enum.Material.Slate
        )
        stone.CFrame *= CFrame.Angles(0.15, angle, 0.1)
        stone.CanQuery = false
        if index % 3 == 0 then
            rootTangle(
                parent,
                position + Vector3.new(1, 0, -1),
                random:NextNumber(0.65, 1.1),
                seed + index
            )
        end
    end
    for index = 1, 10 do
        local angle = random:NextNumber(0, math.pi * 2)
        local radius = random:NextNumber(7, 28)
        local position = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
        if index % 2 == 0 then
            fernCluster(parent, position, random:NextNumber(0.7, 1.25), runtimeIds.AmbientSwayTag)
        else
            local tuft = orb(
                parent,
                "MossLight",
                position + Vector3.new(0, 0.6, 0),
                0.42,
                if index % 3 == 0 then FOXFIRE else AMBER,
                Enum.Material.Neon
            )
            tuft.Transparency = 0.2
            tuft.CanQuery = false
            CollectionService:AddTag(tuft, runtimeIds.AmbientLightTag)
        end
    end
    fireflyCluster(
        parent,
        center + Vector3.new(0, 0, 5),
        FOXFIRE,
        5,
        24,
        seed + 1301,
        runtimeIds.AmbientMoteTag
    )
end

local function buildFarm(parent: Instance, center: Vector3): Model
    local shell = Instance.new("Model")
    shell.Name = "ProceduralCrookedFarmhouseShell"
    shell.Parent = parent
    local housePosition = center + Vector3.new(21, 5.5, 20)
    part(
        shell,
        "Farmhouse",
        Vector3.new(16, 11, 12),
        CFrame.new(housePosition),
        Color3.fromRGB(92, 66, 46),
        Enum.Material.WoodPlanks
    )
    local roof = part(
        shell,
        "RainDarkRoof",
        Vector3.new(20, 2, 8.5),
        CFrame.new(housePosition + Vector3.new(0, 7.2, -4.2)) * CFrame.Angles(0, 0, math.rad(-24)),
        DARK_BARK,
        Enum.Material.Slate
    )
    roof.CanQuery = false
    local roof2 = part(
        shell,
        "RainDarkRoof",
        Vector3.new(20, 2, 8.5),
        CFrame.new(housePosition + Vector3.new(0, 7.2, 4.2)) * CFrame.Angles(0, 0, math.rad(24)),
        DARK_BARK,
        Enum.Material.Slate
    )
    roof2.CanQuery = false
    part(
        parent,
        "FarmDoor",
        Vector3.new(3.2, 5.4, 0.35),
        CFrame.new(housePosition + Vector3.new(0, -2.8, -6.2)),
        DARK_BARK,
        Enum.Material.WoodPlanks,
        false
    )
    window(parent, housePosition + Vector3.new(-5, 1.3, -6.25), 0)
    window(parent, housePosition + Vector3.new(5, 1.3, -6.25), 0)
    part(
        shell,
        "FarmChimney",
        Vector3.new(2.2, 5, 2.2),
        CFrame.new(housePosition + Vector3.new(4.5, 9, 1.5)),
        STONE,
        Enum.Material.Brick,
        false
    )
    fence(parent, center + Vector3.new(-31, 0, 24), 6, 4.8)
    for index = 1, 3 do
        local bale = part(
            parent,
            "HayBale",
            Vector3.new(3.4, 2.2, 2.2),
            CFrame.new(center + Vector3.new(-28 + index * 3.8, 1.1, 17)),
            MEADOW,
            Enum.Material.Fabric,
            false
        )
        bale.Shape = Enum.PartType.Cylinder
        bale.CFrame *= CFrame.Angles(0, 0, math.rad(90))
    end
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
    return shell
end

local function buildWindmill(parent: Instance, center: Vector3, ambientMotionTag: string): Model
    local shell = Instance.new("Model")
    shell.Name = "ProceduralFoxfireMillTowerShell"
    shell.Parent = parent
    local tower = part(
        shell,
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
    local cap = part(
        shell,
        "WindmillCap",
        Vector3.new(11, 3, 11),
        CFrame.new(tower.Position + Vector3.new(0, 16, 0)),
        DARK_BARK,
        Enum.Material.Slate,
        false
    )
    cap.Shape = Enum.PartType.Cylinder
    cap.CFrame *= CFrame.Angles(0, 0, math.rad(90))
    for side = -1, 1, 2 do
        part(
            shell,
            "WindmillBrace",
            Vector3.new(1.1, 28, 1.1),
            CFrame.new(tower.Position + Vector3.new(side * 3.3, 0, -4.6))
                * CFrame.Angles(0, 0, math.rad(side * 9)),
            DARK_BARK,
            Enum.Material.Wood,
            false
        )
    end
    local rotor = Instance.new("Model")
    rotor.Name = "WindmillRotor"
    rotor:SetAttribute("MotionKind", "rotor")
    rotor:SetAttribute("MotionSpeed", 0.3)
    rotor.Parent = parent
    local rotorPivot = part(
        rotor,
        "WindmillRotorPivot",
        Vector3.new(0.2, 0.2, 0.2),
        CFrame.new(hub.Position),
        STONE,
        Enum.Material.SmoothPlastic,
        false
    )
    rotorPivot.Transparency = 1
    rotorPivot.CanQuery = false
    rotorPivot.CastShadow = false
    rotor.PrimaryPart = rotorPivot
    for angle = 0, 3 do
        part(
            rotor,
            "WindmillSail",
            Vector3.new(2, 19, 0.8),
            CFrame.new(hub.Position) * CFrame.Angles(0, 0, angle * math.pi / 2),
            CREAM,
            Enum.Material.Fabric,
            false
        )
        part(
            rotor,
            "WindmillSailArm",
            Vector3.new(0.7, 16, 1.2),
            CFrame.new(hub.Position) * CFrame.Angles(0, 0, angle * math.pi / 2 + math.pi / 4),
            BARK,
            Enum.Material.Wood,
            false
        )
    end
    CollectionService:AddTag(rotor, ambientMotionTag)
    return shell
end

local function buildStoryLandmark(
    parent: Instance,
    center: Vector3,
    kind: string,
    title: string,
    offset: any
): number
    assert(
        type(offset) == "table" and type(offset.x) == "number" and type(offset.z) == "number",
        "Bramblewake story landmark is missing its authored offset"
    )
    local origin = center + Vector3.new(offset.x, 0, offset.z)
    local count = 0
    local function storyPart(
        name: string,
        size: Vector3,
        cframe: CFrame,
        color: Color3,
        material: Enum.Material
    ): Part
        local artifact = part(parent, name, size, cframe, color, material, false)
        artifact.CanQuery = false
        artifact:SetAttribute("StoryLandmark", kind)
        count += 1
        return artifact
    end

    local anchor: BasePart
    if kind == "last_harvest" then
        anchor = storyPart(
            "LastHarvestTable",
            Vector3.new(8.5, 0.55, 4.2),
            CFrame.new(origin + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0.18, 0),
            Color3.fromRGB(96, 68, 43),
            Enum.Material.WoodPlanks
        )
        for x = -1, 1, 2 do
            for z = -1, 1, 2 do
                storyPart(
                    "HarvestTableLeg",
                    Vector3.new(0.45, 2.5, 0.45),
                    CFrame.new(origin + Vector3.new(x * 3.2, 1.25, z * 1.25)),
                    DARK_BARK,
                    Enum.Material.Wood
                )
            end
        end
        for basketIndex = -1, 1 do
            local basket = storyPart(
                "AbandonedHarvestBasket",
                Vector3.new(1.8, 1.3, 1.8),
                CFrame.new(origin + Vector3.new(basketIndex * 2.5, 3.45, 0)),
                if basketIndex == 0 then MEADOW else Color3.fromRGB(145, 91, 53),
                Enum.Material.WoodPlanks
            )
            basket.Shape = Enum.PartType.Ball
        end
        storyPart(
            "HarvestSickleHandle",
            Vector3.new(0.35, 3.6, 0.35),
            CFrame.new(origin + Vector3.new(4.7, 0.9, 1.5)) * CFrame.Angles(0, 0, math.rad(68)),
            BARK,
            Enum.Material.Wood
        )
        storyPart(
            "HarvestSickleBlade",
            Vector3.new(1.8, 0.3, 0.55),
            CFrame.new(origin + Vector3.new(5.8, 1.9, 1.5)) * CFrame.Angles(0, 0, math.rad(28)),
            Color3.fromRGB(127, 139, 140),
            Enum.Material.Metal
        )
    elseif kind == "evacuation_cart" then
        anchor = storyPart(
            "EvacuationHandcart",
            Vector3.new(8.5, 2.8, 5.2),
            CFrame.new(origin + Vector3.new(0, 1.65, 0)) * CFrame.Angles(0.08, 0.35, 0.12),
            Color3.fromRGB(103, 70, 43),
            Enum.Material.WoodPlanks
        )
        storyPart(
            "EvacuationCartTongue",
            Vector3.new(0.7, 0.7, 7.5),
            anchor.CFrame * CFrame.new(0, -0.35, -5.8) * CFrame.Angles(math.rad(-8), 0, 0),
            BARK,
            Enum.Material.Wood
        )
        for side = -1, 1, 2 do
            local wheel = storyPart(
                "EvacuationCartWheel",
                Vector3.new(0.65, 4.4, 4.4),
                anchor.CFrame * CFrame.new(side * 4.55, -0.6, 0),
                DARK_BARK,
                Enum.Material.Wood
            )
            wheel.Shape = Enum.PartType.Cylinder
        end
        for crateIndex = -1, 1 do
            storyPart(
                "EvacuationCrate",
                Vector3.new(2.2, 1.8 + math.abs(crateIndex) * 0.35, 2.2),
                anchor.CFrame * CFrame.new(crateIndex * 2.4, 2.2, 0),
                if crateIndex == 0 then Color3.fromRGB(108, 124, 74) else Color3.fromRGB(91, 62, 40),
                Enum.Material.WoodPlanks
            )
        end
        for trackIndex = 1, 4 do
            local track = storyPart(
                "DepartureTrack",
                Vector3.new(1.2, 0.12, 2.4),
                CFrame.new(origin + Vector3.new(-5 + trackIndex * 2.1, 0.31, -5 - trackIndex * 2.7))
                    * CFrame.Angles(0, 0.25, 0),
                WET_EARTH,
                Enum.Material.Mud
            )
            track.Transparency = 0.12
        end
    elseif kind == "last_repair" then
        anchor = storyPart(
            "FallenWindmillSpar",
            Vector3.new(1, 17, 1),
            CFrame.new(origin + Vector3.new(0, 1.2, 0))
                * CFrame.Angles(math.rad(88), math.rad(16), 0),
            BARK,
            Enum.Material.Wood
        )
        for sailIndex = -1, 1, 2 do
            local sail = storyPart(
                "TornWindmillSail",
                Vector3.new(4.2, 0.28, 6.8),
                CFrame.new(origin + Vector3.new(sailIndex * 3.2, 0.48, sailIndex * 2.1))
                    * CFrame.Angles(0, math.rad(16 + sailIndex * 8), math.rad(sailIndex * 4)),
                CREAM,
                Enum.Material.Fabric
            )
            sail.Transparency = 0.12
        end
        storyPart(
            "RepairToolChest",
            Vector3.new(4.5, 2.1, 2.8),
            CFrame.new(origin + Vector3.new(6, 1.05, 4)),
            Color3.fromRGB(90, 61, 41),
            Enum.Material.WoodPlanks
        )
        for toolIndex = -1, 1 do
            storyPart(
                "AbandonedRepairTool",
                Vector3.new(0.35, 3.2, 0.35),
                CFrame.new(origin + Vector3.new(5.3 + toolIndex * 1.1, 2.75, 4))
                    * CFrame.Angles(0, 0, math.rad(68 + toolIndex * 9)),
                if toolIndex == 0 then Color3.fromRGB(131, 144, 146) else BARK,
                if toolIndex == 0 then Enum.Material.Metal else Enum.Material.Wood
            )
        end
    elseif kind == "lost_crossing" then
        anchor = storyPart(
            "LostCrossingSatchel",
            Vector3.new(3.1, 2.2, 1.3),
            CFrame.new(origin + Vector3.new(3.5, 1.2, 1.8)) * CFrame.Angles(0.12, -0.4, 0.2),
            Color3.fromRGB(118, 78, 49),
            Enum.Material.Fabric
        )
        for plankIndex = -1, 1 do
            storyPart(
                "SnappedCrossingPlank",
                Vector3.new(2.8, 0.45, 7),
                CFrame.new(origin + Vector3.new(plankIndex * 3.4, 0.55, -1 + plankIndex * 1.4))
                    * CFrame.Angles(
                        math.rad(plankIndex * 5),
                        math.rad(plankIndex * 12),
                        math.rad(plankIndex * 4)
                    ),
                Color3.fromRGB(94, 65, 43),
                Enum.Material.WoodPlanks
            )
        end
        for railIndex = -1, 1, 2 do
            storyPart(
                "BrokenCrossingRail",
                Vector3.new(0.55, 6.5, 0.55),
                CFrame.new(origin + Vector3.new(railIndex * 5.2, 1.25, -1))
                    * CFrame.Angles(math.rad(74), 0, math.rad(railIndex * 12)),
                DARK_BARK,
                Enum.Material.Wood
            )
        end
        local lostLantern = storyPart(
            "ColdTrailLantern",
            Vector3.new(1.6, 2.1, 1.6),
            CFrame.new(origin + Vector3.new(-4.7, 1.15, 4.2)),
            Color3.fromRGB(91, 118, 113),
            Enum.Material.Glass
        )
        lostLantern.Shape = Enum.PartType.Ball
        lostLantern.Transparency = 0.28
    else
        error("Unknown Bramblewake story landmark kind: " .. kind)
    end
    billboard(anchor, title, CREAM)
    parent:SetAttribute("StoryLandmark", kind)
    parent:SetAttribute("StoryLandmarkTitle", title)
    parent:SetAttribute("StoryLandmarkPartCount", count)
    return count
end

--[[
    Authored dressing for a module.

    Several of these assets already existed and simply were not being used out
    here -- the root arch, the boulder cluster, the conifers, the shrine --
    which is most of why Bramblewake read as grey slabs while Emberhollow read
    as a place. `extra` collects any number of placements so a module can carry
    a proper set rather than the single one the return value allows.
]]
local function dress(
    extra: { any },
    assetId: string,
    parent: Instance,
    position: Vector3,
    scale: number,
    yaw: number,
    seed: number
)
    table.insert(extra, {
        assetId = assetId,
        fallbackKind = "asset_dressing",
        position = position,
        scale = scale,
        yaw = yaw,
        seed = seed,
        swayTag = nil,
        parent = parent,
        fallbackInstance = nil,
    })
end

local function buildModuleVisual(
    parent: Instance,
    visual: string,
    center: Vector3,
    runtimeIds: any,
    extra: { any }
): any?
    if visual == "lantern_gate" then
        rootArch(parent, center, 1)
        lantern(parent, center + Vector3.new(-14, 0, 13), 1, runtimeIds.AmbientLightTag)
        lantern(parent, center + Vector3.new(14, 0, 13), 1, runtimeIds.AmbientLightTag)
        dress(extra, "mesh_root_arch_a", parent, center, 1, 0, 2401)
        dress(
            extra,
            "mesh_creator_street_lantern_a",
            parent,
            center + Vector3.new(-14, 0, 13),
            1,
            0,
            2402
        )
        dress(
            extra,
            "mesh_creator_street_lantern_a",
            parent,
            center + Vector3.new(14, 0, 13),
            1,
            0,
            2403
        )
    elseif visual == "root_arch" then
        rootArch(parent, center + Vector3.new(0, 0, -7), 0.9)
        dress(extra, "mesh_root_arch_a", parent, center + Vector3.new(0, 0, -7), 0.9, 0, 2411)
        dress(extra, "mesh_fern_cluster_a", parent, center + Vector3.new(-11, 0, 6), 1.2, 0.4, 2412)
        dress(extra, "mesh_fern_cluster_a", parent, center + Vector3.new(12, 0, 4), 1.1, 2.2, 2413)
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
                dress(
                    extra,
                    if (x + z) % 2 == 0 then "mesh_broadleaf_hero_a" else "mesh_conifer_hero_b",
                    parent,
                    center + Vector3.new(x * 17, 0, z * 17),
                    0.85,
                    (x + 2) * 1.3 + z,
                    2420 + (x + 1) * 3 + (z + 1)
                )
            end
        end
        dress(extra, "mesh_deadfall_a", parent, center + Vector3.new(6, 0, -20), 1, 0.7, 2429)
    elseif visual == "foxglove" then
        -- The orbs stay: they are the light this stretch of road is read by,
        -- and a textured flower cannot emit. The authored plant goes around
        -- each one so the glow reads as coming from inside the blooms rather
        -- than from a bare sphere floating in the dark.
        for index = 1, 8 do
            local side = if index % 2 == 0 then 1 else -1
            local at = center + Vector3.new(side * (12 + index), 1.2, -26 + index * 6)
            local glow = orb(
                parent,
                "Foxglove",
                at,
                1.4,
                if index % 3 == 0 then AMBER else FOXFIRE,
                Enum.Material.Neon
            )
            glow.CanQuery = false
            dress(
                extra,
                "mesh_foxglove_cluster_a",
                parent,
                at - Vector3.new(0, 1.2, 0),
                0.95 + (index % 3) * 0.12,
                math.rad(index * 47 + side * 20),
                7300 + index
            )
        end
    elseif visual == "farm" then
        local shell = buildFarm(parent, center)
        return {
            assetId = "mesh_crooked_farmhouse_a",
            fallbackKind = "placeholder",
            position = center + Vector3.new(21, 0, 20),
            scale = 1,
            yaw = 0,
            seed = 2101,
            swayTag = nil,
            parent = parent,
            fallbackInstance = shell,
        }
    elseif visual == "briar_ring" then
        for index = 1, 10 do
            local angle = (index / 10) * math.pi * 2 + math.pi / 10
            dress(
                extra,
                "mesh_briar_wall_a",
                parent,
                center + Vector3.new(math.cos(angle) * 25, 0, math.sin(angle) * 25),
                1.1,
                -angle + math.pi / 2,
                2480 + index
            )
        end
        for index = 1, 6 do
            local angle = (index / 6) * math.pi * 2
            dress(
                extra,
                "mesh_deadfall_a",
                parent,
                center + Vector3.new(math.cos(angle) * 25, 0, math.sin(angle) * 25),
                1.1,
                -angle,
                2440 + index
            )
        end
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
            dress(
                extra,
                "mesh_boulder_cluster_a",
                parent,
                center + Vector3.new(index * 8, 0, 17 + math.abs(index) * 2),
                0.9,
                index * 0.8,
                2450 + index
            )
        end
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
        local shell = buildWindmill(parent, center, runtimeIds.AmbientMotionTag)
        return {
            assetId = "mesh_foxfire_windmill_tower_a",
            fallbackKind = "placeholder",
            position = center + Vector3.new(22, 0, 20),
            scale = 1,
            yaw = 0,
            seed = 2201,
            swayTag = nil,
            parent = parent,
            fallbackInstance = shell,
        }
    elseif visual == "bridge" then
        dress(extra, "mesh_tangle_bridge_a", parent, center + Vector3.new(19, 0.4, 0), 1, 0, 2470)
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
        for index = 1, 5 do
            local angle = index * 1.26
            dress(
                extra,
                if index % 2 == 0 then "mesh_conifer_hero_a" else "mesh_broadleaf_hero_a",
                parent,
                center + Vector3.new(math.cos(angle) * 26, 0, math.sin(angle) * 26),
                0.9,
                angle,
                2460 + index
            )
        end
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
            local moth = orb(
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
            CollectionService:AddTag(moth, runtimeIds.AmbientMoteTag)
        end
    elseif visual == "old_growth" then
        dress(
            extra,
            "mesh_old_growth_stump_a",
            parent,
            center + Vector3.new(22, 0, 22),
            1.4,
            0.5,
            2490
        )
        dress(extra, "mesh_deadfall_a", parent, center + Vector3.new(6, 0, 14), 1.2, 1.9, 2491)
        dress(
            extra,
            "mesh_boulder_cluster_a",
            parent,
            center + Vector3.new(-14, 0, 18),
            1,
            0.3,
            2492
        )
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
        dress(extra, "mesh_wayhome_gate_a", parent, center, 1.25, 0, 2495)
        dress(
            extra,
            "mesh_creator_street_lantern_a",
            parent,
            center + Vector3.new(-11, 0, 8),
            1,
            0,
            2496
        )
        dress(
            extra,
            "mesh_creator_street_lantern_a",
            parent,
            center + Vector3.new(11, 0, 8),
            1,
            0,
            2497
        )
        local beacon =
            orb(parent, "WayhomeLight", center + Vector3.new(0, 8, 0), 6, AMBER, Enum.Material.Neon)
        light(beacon, AMBER, 3, 36)
        billboard(beacon, "WAYHOME GATE", CREAM)
        objectIcon(beacon, "wayhome", AMBER)
    end
end

--[[
    Points of interest are the reason to leave the road, so they have to look
    worth leaving it for. All four were built entirely from primitives while
    the assets that suit them -- the farmhouse, the lantern shrine, boulders,
    trees, crates -- already existed and were placed only in town.
]]
local function buildPointOfInterest(
    parent: Instance,
    center: Vector3,
    definition: any,
    runtimeIds: any,
    extra: { any }
)
    local landmark = Instance.new("Model")
    landmark.Name = "PhysicalPOI_" .. definition.id
    landmark:SetAttribute("ContentId", definition.id)
    landmark:SetAttribute("DisplayName", definition.displayName)
    landmark:SetAttribute("VisualKind", definition.visual)
    landmark.Parent = parent
    local origin = center + Vector3.new(-21, 0, -18)
    local anchor = part(
        landmark,
        "PointOfInterest",
        Vector3.new(4, 1, 4),
        CFrame.new(origin + Vector3.new(0, 0.5, 0)),
        STONE,
        Enum.Material.Slate,
        false
    )
    anchor.Transparency = 1
    anchor.CastShadow = false
    anchor:SetAttribute("ContentId", definition.id)
    anchor:SetAttribute("DisplayName", definition.displayName)
    CollectionService:AddTag(anchor, runtimeIds.ExpeditionPointOfInterestTag)

    local physicalParts = 0
    local function detail(
        name: string,
        size: Vector3,
        at: CFrame,
        color: Color3,
        material: Enum.Material,
        shape: Enum.PartType?
    ): Part
        physicalParts += 1
        local created = part(landmark, name, size, at, color, material, false)
        if shape ~= nil then
            created.Shape = shape
        end
        return created
    end

    local origin2 = center + Vector3.new(-21, 0, -18)
    if definition.visual == "ruined_homestead" then
        -- A burnt-out farm: the house it used to be, and what was left behind.
        dress(
            extra,
            "mesh_crooked_farmhouse_a",
            parent,
            origin2 + Vector3.new(0, 0, -6),
            1,
            0.4,
            2510
        )
        dress(extra, "mesh_creator_crate_a", parent, origin2 + Vector3.new(7, 0, 4), 1, 1.1, 2511)
        dress(extra, "mesh_creator_barrel_a", parent, origin2 + Vector3.new(9, 0, 1), 1, 0.2, 2512)
        dress(extra, "mesh_deadfall_a", parent, origin2 + Vector3.new(-9, 0, 6), 1, 2.4, 2513)
        detail(
            "ReedsteadFoundation",
            Vector3.new(13, 0.65, 10),
            CFrame.new(origin + Vector3.new(0, 0.32, 0)),
            Color3.fromRGB(76, 78, 72),
            Enum.Material.Cobblestone,
            nil
        )
        for side = -1, 1, 2 do
            detail(
                "ReedsteadBrokenPost",
                Vector3.new(0.85, if side < 0 then 7.5 else 5.6, 0.85),
                CFrame.new(origin + Vector3.new(side * 5.3, if side < 0 then 4 else 3, 3.8))
                    * CFrame.Angles(0, 0, math.rad(side * 7)),
                DARK_BARK,
                Enum.Material.Wood,
                nil
            )
            detail(
                "ReedsteadWallFragment",
                Vector3.new(4.8, 4.1 + side * 0.4, 0.55),
                CFrame.new(origin + Vector3.new(side * 2.8, 2.35, 4.6))
                    * CFrame.Angles(0, 0, math.rad(side * 4)),
                BARK,
                Enum.Material.WoodPlanks,
                nil
            )
        end
        detail(
            "ReedsteadCollapsedRafter",
            Vector3.new(12.5, 0.75, 1),
            CFrame.new(origin + Vector3.new(0, 3.2, -0.4))
                * CFrame.Angles(math.rad(12), math.rad(-18), math.rad(9)),
            WET_EARTH,
            Enum.Material.Wood,
            nil
        )
        detail(
            "ReedsteadColdHearth",
            Vector3.new(3.5, 2.6, 2.4),
            CFrame.new(origin + Vector3.new(3.8, 1.3, 2.8)),
            STONE,
            Enum.Material.Cobblestone,
            nil
        )
        for crateIndex = -1, 1 do
            detail(
                "ReedsteadSupplyCrate",
                Vector3.new(2.2, 1.8 + math.abs(crateIndex) * 0.3, 2.2),
                CFrame.new(origin + Vector3.new(crateIndex * 2.6, 1, -3.2))
                    * CFrame.Angles(0, math.rad(crateIndex * 9), 0),
                if crateIndex == 0 then Color3.fromRGB(108, 124, 74) else Color3.fromRGB(91, 62, 40),
                Enum.Material.WoodPlanks,
                nil
            )
        end
    elseif definition.visual == "moth_well" then
        dress(
            extra,
            "mesh_boulder_cluster_a",
            parent,
            origin2 + Vector3.new(-7, 0, 5),
            0.9,
            0.7,
            2520
        )
        dress(
            extra,
            "mesh_boulder_cluster_a",
            parent,
            origin2 + Vector3.new(8, 0, -4),
            0.8,
            2.1,
            2521
        )
        dress(extra, "mesh_lantern_post_a", parent, origin2 + Vector3.new(5, 0, 6), 1, 0, 2522)
        dress(
            extra,
            "mesh_fern_cluster_a",
            parent,
            origin2 + Vector3.new(-4, 0, -6),
            1.2,
            1.4,
            2523
        )
        for stoneIndex = 1, 10 do
            local angle = stoneIndex * math.pi * 2 / 10
            detail(
                "MothwellRimStone",
                Vector3.new(2.2, 1.25, 1.55),
                CFrame.new(origin + Vector3.new(math.cos(angle) * 4.2, 0.65, math.sin(angle) * 4.2))
                    * CFrame.Angles(0, -angle, math.rad((stoneIndex % 3 - 1) * 4)),
                if stoneIndex % 2 == 0 then STONE else Color3.fromRGB(65, 74, 72),
                Enum.Material.Slate,
                nil
            )
        end
        for side = -1, 1, 2 do
            detail(
                "MothwellPost",
                Vector3.new(0.65, 7.2, 0.65),
                CFrame.new(origin + Vector3.new(side * 4.9, 3.6, 0))
                    * CFrame.Angles(0, 0, math.rad(side * 4)),
                DARK_BARK,
                Enum.Material.Wood,
                nil
            )
        end
        detail(
            "MothwellCrossbeam",
            Vector3.new(10.8, 0.7, 0.7),
            CFrame.new(origin + Vector3.new(0, 6.8, 0)),
            BARK,
            Enum.Material.Wood,
            nil
        )
        detail(
            "MothwellBucket",
            Vector3.new(2, 2.2, 2),
            CFrame.new(origin + Vector3.new(0, 2.1, 0)),
            Color3.fromRGB(93, 70, 50),
            Enum.Material.WoodPlanks,
            Enum.PartType.Cylinder
        )
        for mothIndex = 1, 5 do
            local angle = mothIndex * 2.2
            local moth = detail(
                "MothwellLanternMoth",
                Vector3.new(0.55, 0.35, 0.18),
                CFrame.new(
                    origin
                        + Vector3.new(
                            math.cos(angle) * (3.2 + mothIndex * 0.3),
                            3.2 + mothIndex * 0.55,
                            math.sin(angle) * (3.2 + mothIndex * 0.3)
                        )
                ),
                FOXFIRE,
                Enum.Material.Glass,
                nil
            )
            moth.Transparency = 0.12
            CollectionService:AddTag(moth, runtimeIds.AmbientMoteTag)
        end
    elseif definition.visual == "sap_grove" then
        -- The grove is where sap comes from, so it shows real tapped boles.
        for groveIndex = 1, 3 do
            local angle = groveIndex * 2.1
            dress(
                extra,
                "mesh_amber_sap_node_a",
                parent,
                origin2 + Vector3.new(math.cos(angle) * 9, 0, math.sin(angle) * 9),
                1,
                angle,
                2530 + groveIndex
            )
        end
        dress(
            extra,
            "mesh_broadleaf_hero_a",
            parent,
            origin2 + Vector3.new(-11, 0, -8),
            0.9,
            0.6,
            2534
        )
        dress(
            extra,
            "mesh_conifer_hero_a",
            parent,
            origin2 + Vector3.new(12, 0, 7),
            0.85,
            2.7,
            2535
        )
        for trunkIndex = -1, 1 do
            local x = trunkIndex * 4.6
            detail(
                "SapglassTrunk",
                Vector3.new(2.6, 8 + math.abs(trunkIndex) * 2.2, 2.6),
                CFrame.new(origin + Vector3.new(x, 4.3 + math.abs(trunkIndex), 1.5))
                    * CFrame.Angles(0, 0, math.rad(trunkIndex * 7)),
                DARK_BARK,
                Enum.Material.Wood,
                nil
            )
            local sap = detail(
                "SapglassVein",
                Vector3.new(0.7, 4.8, 0.32),
                CFrame.new(origin + Vector3.new(x, 4.2, 0.1)),
                AMBER,
                Enum.Material.Glass,
                nil
            )
            sap.Transparency = 0.12
        end
        detail(
            "SapglassCollector",
            Vector3.new(9.5, 1.4, 3.2),
            CFrame.new(origin + Vector3.new(0, 0.7, -3.8)),
            Color3.fromRGB(87, 64, 45),
            Enum.Material.WoodPlanks,
            nil
        )
        for vialIndex = -2, 2 do
            local vial = detail(
                "SapglassVial",
                Vector3.new(0.85, 1.45, 0.85),
                CFrame.new(origin + Vector3.new(vialIndex * 1.55, 1.95, -3.8)),
                AMBER,
                Enum.Material.Glass,
                Enum.PartType.Cylinder
            )
            vial.Transparency = 0.16
        end
    else
        for side = -1, 1, 2 do
            detail(
                "RootChapelPillar",
                Vector3.new(1.2, 9.5, 1.2),
                CFrame.new(origin + Vector3.new(side * 4.2, 4.6, 2.6))
                    * CFrame.Angles(0, 0, math.rad(-side * 11)),
                DARK_BARK,
                Enum.Material.Wood,
                nil
            )
            detail(
                "RootChapelCrown",
                Vector3.new(1.0, 7.2, 1.0),
                CFrame.new(origin + Vector3.new(side * 2.1, 8.2, 2.6))
                    * CFrame.Angles(0, 0, math.rad(side * 58)),
                BARK,
                Enum.Material.Wood,
                nil
            )
            detail(
                "RootChapelBench",
                Vector3.new(5.8, 0.65, 1.45),
                CFrame.new(origin + Vector3.new(side * 3.4, 1.05, -2.5)),
                Color3.fromRGB(92, 65, 44),
                Enum.Material.WoodPlanks,
                nil
            )
        end
        detail(
            "RootChapelAltar",
            Vector3.new(5.2, 2.6, 3.2),
            CFrame.new(origin + Vector3.new(0, 1.3, 2.9)),
            Color3.fromRGB(72, 78, 74),
            Enum.Material.Slate,
            nil
        )
        for candleIndex = -1, 1 do
            local candle = detail(
                "RootChapelMemoryCandle",
                Vector3.new(0.65, 1.25, 0.65),
                CFrame.new(origin + Vector3.new(candleIndex * 1.4, 3.15, 2.7)),
                if candleIndex == 0 then AMBER else FOXFIRE,
                Enum.Material.Glass,
                Enum.PartType.Cylinder
            )
            candle.Transparency = 0.1
        end
        -- The lantern shrine asset was authored for exactly this and had never
        -- been placed anywhere in the world.
        dress(extra, "mesh_hollow_lantern_shrine_a", parent, origin2, 0.8, 0.2, 2540)
        dress(
            extra,
            "mesh_creator_kerosene_lantern_a",
            parent,
            origin2 + Vector3.new(3, 0, 4),
            1,
            0.9,
            2541
        )
        dress(extra, "mesh_fern_cluster_a", parent, origin2 + Vector3.new(-6, 0, 3), 1.1, 1.7, 2542)
    end

    local memory = orb(
        landmark,
        "POIMemoryLantern",
        origin + Vector3.new(0, 4.6, -0.8),
        1.35,
        FOXFIRE,
        Enum.Material.Glass
    )
    physicalParts += 1
    memory.Transparency = 0.1
    light(memory, FOXFIRE, 0.85, 13)
    billboard(memory, string.upper(definition.displayName), FOXFIRE)
    objectIcon(memory, "memory", FOXFIRE)
    landmark:SetAttribute("PhysicalPartCount", physicalParts)
    return memory
end

--[[
    Event scenes are the encounters a player stops for, and they were the last
    part of the route still assembled entirely from boxes. Each now carries the
    authored props that say what it is before the prompt is read, which is the
    order the visual standard asks for.
]]
local function buildEventSocket(
    parent: Instance,
    center: Vector3,
    definition: any,
    runtimeIds: any,
    extra: { any }
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
    anchor.Transparency = 1
    anchor.CanCollide = false
    anchor.CastShadow = false
    CollectionService:AddTag(anchor, runtimeIds.ExpeditionEventTag)
    billboard(anchor, string.upper(definition.displayName), AMBER)
    objectIcon(anchor, "event", AMBER)
    destinationCairns(parent, anchor.Position, AMBER, 5.5)

    local scene = Instance.new("Model")
    scene.Name = "EventScene_" .. definition.id
    scene:SetAttribute("VisualKind", definition.visual)
    scene.Parent = parent

    local sceneAt = center + Vector3.new(22, 0, -19)
    if definition.visual == "wagon" then
        -- A wagon that did not make it, and the load it was carrying.
        dress(extra, "mesh_creator_crate_a", parent, sceneAt + Vector3.new(3, 0, 2), 1, 0.6, 2560)
        dress(extra, "mesh_creator_crate_a", parent, sceneAt + Vector3.new(-2, 0, 4), 1, 2.2, 2561)
        dress(extra, "mesh_creator_barrel_a", parent, sceneAt + Vector3.new(4, 0, -3), 1, 1.1, 2562)
        dress(extra, "mesh_deadfall_a", parent, sceneAt + Vector3.new(-6, 0, -2), 1, 1.6, 2563)
        part(
            scene,
            "LostWagon",
            Vector3.new(10, 5, 7),
            CFrame.new(anchor.Position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0.35, 0.14),
            Color3.fromRGB(104, 69, 42),
            Enum.Material.WoodPlanks
        )
        for wheelSide = -1, 1, 2 do
            local wheel = part(
                scene,
                "LostWagonWheel",
                Vector3.new(0.7, 5.3, 5.3),
                CFrame.new(anchor.Position + Vector3.new(wheelSide * 5.15, 2.6, 0))
                    * CFrame.Angles(0, math.rad(90), 0.14),
                Color3.fromRGB(64, 47, 36),
                Enum.Material.Wood
            )
            wheel.Shape = Enum.PartType.Cylinder
            for spokeIndex = 1, 4 do
                part(
                    scene,
                    "LostWagonSpoke",
                    Vector3.new(0.28, 4.6, 0.28),
                    wheel.CFrame * CFrame.Angles(math.rad(spokeIndex * 45), 0, 0),
                    Color3.fromRGB(91, 65, 44),
                    Enum.Material.Wood,
                    false
                )
            end
        end
        for shaftSide = -1, 1, 2 do
            part(
                scene,
                "LostWagonShaft",
                Vector3.new(0.52, 0.52, 10),
                CFrame.new(anchor.Position + Vector3.new(shaftSide * 2.5, 1.8, -7.2))
                    * CFrame.Angles(math.rad(5), 0, 0),
                Color3.fromRGB(78, 54, 38),
                Enum.Material.Wood,
                false
            )
        end
        for cargoIndex = -1, 1 do
            part(
                scene,
                "LostWagonCargo",
                Vector3.new(2.7, 2.2, 2.5),
                CFrame.new(anchor.Position + Vector3.new(cargoIndex * 2.5, 5.5, 0.2)),
                if cargoIndex == 0 then Color3.fromRGB(83, 102, 75) else Color3.fromRGB(94, 68, 45),
                if cargoIndex == 0 then Enum.Material.Fabric else Enum.Material.WoodPlanks,
                false
            )
        end
    elseif definition.visual == "hedge" then
        for hedgeIndex = -2, 2 do
            dress(
                extra,
                "mesh_briar_wall_a",
                parent,
                sceneAt + Vector3.new(hedgeIndex * 7, 0, 0),
                1,
                math.pi / 2,
                2610 + hedgeIndex
            )
        end
        part(
            scene,
            "MovingHedge",
            Vector3.new(18, 9, 5),
            CFrame.new(anchor.Position + Vector3.new(0, 4.5, 0)),
            DEEP_GRASS,
            Enum.Material.Grass
        )
        for branchIndex = -3, 3 do
            part(
                scene,
                "MovingHedgeBranch",
                Vector3.new(0.55, 8.5 + math.abs(branchIndex % 2), 0.55),
                CFrame.new(anchor.Position + Vector3.new(branchIndex * 2.7, 4.2, 0.4))
                    * CFrame.Angles(0, 0, math.rad(branchIndex * 7)),
                DARK_BARK,
                Enum.Material.Wood,
                false
            )
            local leaf = orb(
                scene,
                "MovingHedgeCrown",
                anchor.Position + Vector3.new(branchIndex * 2.7, 6 + math.abs(branchIndex % 2), 0),
                2.3 + (math.abs(branchIndex) % 2) * 0.5,
                if branchIndex % 2 == 0 then DEEP_GRASS else MOSS,
                Enum.Material.Grass
            )
            leaf.CanQuery = false
        end
    elseif definition.visual == "root_bridge" then
        dress(extra, "mesh_tangle_bridge_a", parent, sceneAt, 0.9, 1.57, 2570)
        dress(
            extra,
            "mesh_boulder_cluster_a",
            parent,
            sceneAt + Vector3.new(-8, 0, 5),
            0.9,
            0.4,
            2571
        )
        rootArch(scene, anchor.Position, 0.52)
    elseif definition.visual == "pollen_storm" then
        dress(
            extra,
            "mesh_broadleaf_hero_a",
            parent,
            sceneAt + Vector3.new(-8, 0, -5),
            0.85,
            0.9,
            2620
        )
        dress(extra, "mesh_fern_cluster_a", parent, sceneAt + Vector3.new(5, 0, 4), 1.3, 2.1, 2621)
        for moteIndex = 1, 7 do
            local angle = (moteIndex / 7) * math.pi * 2
            local mote = orb(
                scene,
                "PollenStormMote",
                anchor.Position
                    + Vector3.new(math.cos(angle) * 7, 3 + moteIndex % 3, math.sin(angle) * 5),
                0.7,
                Color3.fromRGB(224, 190, 93),
                Enum.Material.SmoothPlastic
            )
            mote.Transparency = 0.28
            mote.CanQuery = false
        end
    elseif definition.visual == "hungry_homestead" then
        dress(
            extra,
            "mesh_crooked_farmhouse_a",
            parent,
            sceneAt + Vector3.new(0, 0, -5),
            0.9,
            0.8,
            2580
        )
        dress(extra, "mesh_creator_barrel_a", parent, sceneAt + Vector3.new(5, 0, 2), 1, 0.3, 2581)
        dress(
            extra,
            "mesh_creator_rustic_fence_a",
            parent,
            sceneAt + Vector3.new(-7, 0, 3),
            1,
            0,
            2582
        )
        part(
            scene,
            "HomesteadPorch",
            Vector3.new(16, 0.7, 9),
            CFrame.new(anchor.Position + Vector3.new(0, 0.35, 1)),
            Color3.fromRGB(104, 72, 45),
            Enum.Material.WoodPlanks
        )
        for side = -1, 1, 2 do
            part(
                scene,
                "HomesteadPost",
                Vector3.new(0.7, 7, 0.7),
                CFrame.new(anchor.Position + Vector3.new(side * 7, 3.5, -3)),
                DARK_BARK,
                Enum.Material.Wood
            )
        end
        part(
            scene,
            "HomesteadRoof",
            Vector3.new(18, 0.7, 11),
            CFrame.new(anchor.Position + Vector3.new(0, 7.2, 1)) * CFrame.Angles(0, 0, math.rad(3)),
            Color3.fromRGB(55, 61, 50),
            Enum.Material.Slate
        )
        part(
            scene,
            "HomesteadBackWall",
            Vector3.new(15.5, 6.8, 0.7),
            CFrame.new(anchor.Position + Vector3.new(0, 3.4, 5)),
            Color3.fromRGB(77, 55, 40),
            Enum.Material.WoodPlanks
        )
        for side = -1, 1, 2 do
            part(
                scene,
                "HomesteadSideWall",
                Vector3.new(0.7, 6.8, 8.5),
                CFrame.new(anchor.Position + Vector3.new(side * 7.5, 3.4, 1)),
                Color3.fromRGB(77, 55, 40),
                Enum.Material.WoodPlanks
            )
            part(
                scene,
                "HomesteadSupplyCrate",
                Vector3.new(2.8, 2.4, 2.7),
                CFrame.new(anchor.Position + Vector3.new(side * 4.9, 1.55, 3.1)),
                Color3.fromRGB(96, 67, 43),
                Enum.Material.WoodPlanks,
                false
            )
        end
        part(
            scene,
            "HomesteadTable",
            Vector3.new(5.8, 0.55, 2.8),
            CFrame.new(anchor.Position + Vector3.new(0, 2.7, 3)),
            Color3.fromRGB(91, 63, 43),
            Enum.Material.WoodPlanks
        )
    elseif definition.visual == "stag_tracks" then
        dress(extra, "mesh_deadfall_a", parent, sceneAt + Vector3.new(6, 0, -4), 1.1, 2.9, 2590)
        dress(
            extra,
            "mesh_conifer_hero_b",
            parent,
            sceneAt + Vector3.new(-9, 0, -6),
            0.8,
            1.2,
            2591
        )
        dress(extra, "mesh_fern_cluster_a", parent, sceneAt + Vector3.new(2, 0, 5), 1.2, 0.5, 2592)
        for side = -1, 1, 2 do
            part(
                scene,
                "WardenTrackAntler",
                Vector3.new(0.6, 6.5, 0.6),
                CFrame.new(anchor.Position + Vector3.new(side * 2.2, 4.2, 4))
                    * CFrame.Angles(0, 0, math.rad(-side * 24)),
                Color3.fromRGB(112, 109, 87),
                Enum.Material.Wood,
                false
            )
        end
        for trackIndex = 1, 5 do
            local track = part(
                scene,
                "WardenTrackPrint",
                Vector3.new(1.1, 0.18, 1.8),
                CFrame.new(
                    anchor.Position
                        + Vector3.new((trackIndex % 2) * 1.8 - 0.9, 0.12, -7 + trackIndex * 2.2)
                )
                    * CFrame.Angles(0, math.rad(-12 + trackIndex * 4), 0),
                Color3.fromRGB(53, 48, 40),
                Enum.Material.Mud,
                false
            )
            track.Shape = Enum.PartType.Ball
        end
    elseif definition.visual == "wildfire_choice" then
        dress(extra, "mesh_creator_campfire_a", parent, sceneAt, 1.4, 0, 2600)
        dress(extra, "mesh_deadfall_a", parent, sceneAt + Vector3.new(-7, 0, 4), 1.2, 1.1, 2601)
        dress(
            extra,
            "mesh_boulder_cluster_a",
            parent,
            sceneAt + Vector3.new(7, 0, 3),
            0.9,
            2.4,
            2602
        )
        for side = -1, 1, 2 do
            local flame = orb(
                scene,
                "WildfireFront",
                anchor.Position + Vector3.new(side * 8, 2.2, 4),
                2.6,
                Color3.fromRGB(232, 105, 57),
                Enum.Material.Neon
            )
            flame.Transparency = 0.12
            flame.CanQuery = false
            part(
                scene,
                "CharredSapling",
                Vector3.new(0.7, 6, 0.7),
                CFrame.new(anchor.Position + Vector3.new(side * 8, 2.8, 6))
                    * CFrame.Angles(0, 0, math.rad(side * 12)),
                Color3.fromRGB(43, 37, 34),
                Enum.Material.Wood,
                false
            )
        end
    end

    local interactions = {}
    for index, step in definition.steps do
        local offset = step.offset
        local position = anchor.Position + Vector3.new(offset.x, offset.y, offset.z)
        local target: Part
        if definition.visual == "foxlight" then
            target = orb(scene, "Foxlight_" .. step.id, position, 2.2, FOXFIRE, Enum.Material.Neon)
            target.Transparency = 0.16
            light(target, FOXFIRE, 1.1, 14)
            part(
                scene,
                "FoxlightStem_" .. step.id,
                Vector3.new(0.35, 2.2, 0.35),
                CFrame.new(position - Vector3.new(0, 1.4, 0)) * CFrame.Angles(0, 0, math.rad(12)),
                DARK_BARK,
                Enum.Material.Wood,
                false
            )
        elseif definition.visual == "root_bridge" then
            target = orb(scene, "RootKnot_" .. step.id, position, 2.7, AMBER, Enum.Material.Wood)
            target.Shape = Enum.PartType.Cylinder
            target.CFrame *= CFrame.Angles(0, 0, math.rad(90))
            target.Size = Vector3.new(1.5, 2.7, 1.5)
            for rootIndex = -1, 1 do
                part(
                    scene,
                    "RootBridgeBranch_" .. step.id,
                    Vector3.new(0.45, 2.8, 0.45),
                    CFrame.new(position + Vector3.new(rootIndex * 0.8, 0.4, 0.8))
                        * CFrame.Angles(math.rad(34), 0, math.rad(rootIndex * 18)),
                    BARK,
                    Enum.Material.Wood,
                    false
                )
            end
        elseif definition.visual == "wagon" then
            target = part(
                scene,
                "WagonBrace_" .. step.id,
                Vector3.new(2.8, 1.4, 2.8),
                CFrame.new(position) * CFrame.Angles(0, index * 0.55, math.rad(8)),
                AMBER,
                Enum.Material.WoodPlanks,
                false
            )
        elseif definition.visual == "pollen_storm" then
            target = part(
                scene,
                "PollenScreen_" .. step.id,
                Vector3.new(4.2, 5.2, 0.45),
                CFrame.new(position) * CFrame.Angles(0, index * 0.18 - 0.36, 0),
                Color3.fromRGB(171, 148, 86),
                Enum.Material.Fabric,
                false
            )
            for postSide = -1, 1, 2 do
                part(
                    scene,
                    "PollenScreenPost_" .. step.id,
                    Vector3.new(0.35, 5.8, 0.35),
                    target.CFrame * CFrame.new(postSide * 2.2, 0, 0),
                    DARK_BARK,
                    Enum.Material.Wood,
                    false
                )
            end
        elseif definition.visual == "hungry_homestead" then
            target = part(
                scene,
                "HomesteadStore_" .. step.id,
                if step.id == "fill_water"
                    then Vector3.new(2.7, 3.4, 2.7)
                    else Vector3.new(3.6, 2.5, 3.2),
                CFrame.new(position) * CFrame.Angles(0, index * 0.42, 0),
                if step.id == "fill_water"
                    then Color3.fromRGB(76, 104, 105)
                    else Color3.fromRGB(116, 81, 48),
                if step.id == "fill_water" then Enum.Material.Metal else Enum.Material.WoodPlanks,
                false
            )
            if step.id == "fill_water" then
                target.Shape = Enum.PartType.Cylinder
            end
        elseif definition.visual == "stag_tracks" then
            target = part(
                scene,
                "WardenSign_" .. step.id,
                if step.id == "study_scrape"
                    then Vector3.new(1.1, 4.2, 1.1)
                    else Vector3.new(3.8, 0.45, 2.8),
                CFrame.new(position)
                    * CFrame.Angles(0, index * 0.3, if step.id == "study_scrape" then 0 else 0.08),
                Color3.fromRGB(102, 91, 69),
                if step.id == "study_scrape" then Enum.Material.Wood else Enum.Material.Ground,
                false
            )
            if step.id ~= "study_scrape" then
                target.Shape = Enum.PartType.Ball
            end
        elseif definition.visual == "wildfire_choice" then
            target = part(
                scene,
                "WetFirebreak_" .. step.id,
                Vector3.new(4.8, 1.2, 3.4),
                CFrame.new(position) * CFrame.Angles(0, index * 0.28, 0),
                Color3.fromRGB(96, 79, 59),
                Enum.Material.Mud,
                false
            )
            target.Shape = Enum.PartType.Ball
        else
            target = part(
                scene,
                "HedgeLatch_" .. step.id,
                Vector3.new(1.4, 3.2, 1.4),
                CFrame.new(position) * CFrame.Angles(0, 0, math.rad(index * 8 - 16)),
                AMBER,
                Enum.Material.WoodPlanks,
                false
            )
        end
        target.CastShadow = false
        objectIcon(target, "step", AMBER)
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

    local physicalParts = 0
    for _, descendant in scene:GetDescendants() do
        if descendant:IsA("BasePart") then
            physicalParts += 1
        end
    end
    scene:SetAttribute("PhysicalPartCount", physicalParts)

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

    lowMist(folder, average + Vector3.new(0, 0, 0), Vector3.new(680, 2.2, 680), 0.88)
    for ring = 1, 2 do
        for index = 1, 18 do
            local angle = (index / 18) * math.pi * 2 + ring * 0.09
            local radius = 230 + ring * 70 + (index % 4) * 18
            local height = 52 + (index % 5) * 16 + ring * 8
            local spire = part(
                folder,
                "DistantRootSpire",
                Vector3.new(10 + ring * 4, height, 10 + ring * 4),
                CFrame.new(
                    average
                        + Vector3.new(
                            math.cos(angle) * radius,
                            height / 2 - 3,
                            math.sin(angle) * radius
                        )
                ) * CFrame.Angles(math.rad(8 + ring * 2), 0, -angle),
                if ring == 1 then Color3.fromRGB(32, 45, 39) else Color3.fromRGB(24, 35, 34),
                Enum.Material.Wood
            )
            spire.Transparency = if ring == 1 then 0.08 else 0.18
            if index % 6 == 0 then
                local glow = orb(
                    folder,
                    "DistantSapGlow",
                    spire.Position + Vector3.new(0, height * 0.28, 0),
                    1.3,
                    FOXFIRE,
                    Enum.Material.Neon
                )
                glow.Transparency = 0.38
                glow.CanQuery = false
            end
        end
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
        Enum.Material.Glass
    )
    seal.Shape = Enum.PartType.Cylinder
    seal.CFrame *= CFrame.Angles(0, 0, math.rad(90))
    seal.Size = Vector3.new(1.2, 7, 7)
    seal.Transparency = 0.52
    billboard(seal, "WARDEN'S SEAL · CLEANSE OLD GROWTH", CREAM)
    objectIcon(seal, "seal", FOXFIRE)

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
            1.45,
            Color3.fromRGB(80, 116, 83),
            Enum.Material.Glass
        )
        node.Shape = Enum.PartType.Cylinder
        node.CFrame *= CFrame.Angles(0, 0, math.rad(90))
        node.Size = Vector3.new(1.2, 2.7, 1.2)
        node.Transparency = 0.34
        livingRootShell(arena, node.Position, 0.92, "Warden" .. definition.suffix)
        node:SetAttribute("BossId", "boss_warden_stag")
        node:SetAttribute("BossInteraction", "cleanse_root")
        node:SetAttribute("BossNodeId", definition.nodeId)
        CollectionService:AddTag(node, runtimeIds.ExpeditionBossTag)
        billboard(node, string.upper(string.gsub(definition.nodeId, "_", " ")), CREAM)
        objectIcon(node, "root", FOXFIRE)
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
            Enum.Material.Wood,
            false
        )
        target.Transparency = 0.2
        for tineIndex = 1, 3 do
            part(
                arena,
                "MemoryAntlerTine",
                Vector3.new(0.7, 3.1 - tineIndex * 0.35, 0.7),
                target.CFrame
                    * CFrame.new(
                        definition.side * (0.75 + tineIndex * 0.18),
                        1.1 + tineIndex * 1.65,
                        0
                    )
                    * CFrame.Angles(0, 0, math.rad(-definition.side * (42 + tineIndex * 4))),
                Color3.fromRGB(151, 148, 125),
                Enum.Material.Wood,
                false
            )
        end
        target:SetAttribute("BossId", "boss_warden_stag")
        target:SetAttribute("BossInteraction", "break_antler")
        target:SetAttribute("BossAntlerId", definition.antlerId)
        CollectionService:AddTag(target, runtimeIds.ExpeditionBossTag)
        billboard(target, "BREAK ANTLER · CHANGES FOREST", Color3.fromRGB(255, 166, 106))
        objectIcon(target, "antler", Color3.fromRGB(255, 166, 106))
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
    fireSource.Shape = Enum.PartType.Cylinder
    fireSource.CFrame *= CFrame.Angles(0, 0, math.rad(90))
    fireSource.Size = Vector3.new(2.2, 4.8, 2.2)
    fireSource.Color = DARK_BARK
    fireSource.Material = Enum.Material.Wood
    local sourceFlame = orb(
        layer,
        "BlackoutLanternFlame",
        fireSource.Position + Vector3.new(0, 2.7, 0),
        2.1,
        AMBER,
        Enum.Material.Neon
    )
    cagedLanternShell(layer, sourceFlame.Position, 0.78, "BlackoutLantern")
    light(sourceFlame, AMBER, 1.8, 16)
    fireSource:SetAttribute("BlackoutInteraction", "take_fire")
    CollectionService:AddTag(fireSource, runtimeIds.ExpeditionBlackoutTag)
    billboard(fireSource, "BLACKOUT FIRE · CARRY TO LIVING ROOTS", CREAM)
    objectIcon(fireSource, "rootfire", AMBER)

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
        node.Shape = Enum.PartType.Cylinder
        node.CFrame *= CFrame.Angles(0, 0, math.rad(90))
        node.Size = Vector3.new(2.4, 5.8, 2.4)
        node.Color = DARK_BARK
        node.Material = Enum.Material.Wood
        local relayCore = orb(
            layer,
            "BlackoutRelayCore_" .. definition.label,
            node.Position + Vector3.new(0, 3.2, 0),
            1.8,
            FOXFIRE,
            Enum.Material.Neon
        )
        light(relayCore, FOXFIRE, 1.1, 12)
        node:SetAttribute("BlackoutInteraction", "deliver_fire")
        node:SetAttribute("BlackoutNodeId", definition.nodeId)
        CollectionService:AddTag(node, runtimeIds.ExpeditionBlackoutTag)
        billboard(node, definition.label .. " · NEEDS CARRIED FIRE", CREAM)
        objectIcon(node, "livingroot", FOXFIRE)
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
        local shrineCenter = bossCenter + Vector3.new(definition.offset.X, 0, definition.offset.Z)
        local seedling =
            chapterChoiceShrine(layer, shrineCenter, definition.color, definition.decisionId)
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

--[[
    Harvestable resource nodes along the route.

    Bramblewake previously had no gather nodes of any kind: Heartwood and
    Amber Sap existed as materials, as crafting inputs, and as elite and boss
    rewards, but there was nothing in the world to harvest. A player walking
    the route had no way to find either, because neither was there.

    Two per module from the second module onward, alternating material and
    offset to either side of the road, so the route always has something
    visible to walk toward and the reason to travel is on the path rather than
    only at the far end. Each carries a lantern-amber or foxfire glow so it
    reads at distance in Blackout lighting, and a billboard naming what it is.
]]
local function buildResourceNodes(
    module: Instance,
    center: Vector3,
    moduleIndex: number,
    runtimeIds: any,
    nodes: { any },
    meshPlacements: { any }
)
    if moduleIndex < 2 then
        return
    end
    for slot = 1, 2 do
        local isSap = (moduleIndex + slot) % 2 == 0
        local side = if slot == 1 then -1 else 1
        local at = center + Vector3.new(side * (15 + (moduleIndex % 3) * 2), 0, (slot - 1.5) * 18)
        local nodeId = string.format("node_bw_%d_%d", moduleIndex, slot)

        local anchor = part(
            module,
            if isSap then "AmberSapNode" else "HeartwoodNode",
            Vector3.new(5, 7, 5),
            CFrame.new(at + Vector3.new(0, 3.5, 0)),
            if isSap then Color3.fromRGB(196, 142, 58) else Color3.fromRGB(96, 68, 46),
            Enum.Material.Wood
        )
        anchor.Transparency = 1
        anchor.CanCollide = false

        local glow = part(
            module,
            "ResourceGlow",
            Vector3.new(2.2, 2.2, 2.2),
            CFrame.new(at + Vector3.new(0, 3.2, 0)),
            if isSap then Color3.fromRGB(255, 186, 84) else Color3.fromRGB(120, 214, 178),
            Enum.Material.Neon,
            false
        )
        glow.Shape = Enum.PartType.Ball
        glow.Transparency = 0.4
        glow.CastShadow = false
        light(glow, glow.Color, 1.4, 24)
        CollectionService:AddTag(glow, runtimeIds.AmbientLightTag)

        table.insert(meshPlacements, {
            assetId = if isSap then "mesh_amber_sap_node_a" else "mesh_heartwood_stump_a",
            fallbackKind = "asset_replacement",
            position = at,
            scale = 1,
            yaw = math.rad((moduleIndex * 37 + slot * 61) % 360),
            seed = 11200 + moduleIndex * 10 + slot,
            swayTag = nil,
            parent = module,
            fallbackInstance = nil,
        })

        table.insert(nodes, {
            target = anchor,
            interactionId = nodeId,
            materialId = if isSap then "material_amber_sap" else "material_heartwood",
            objectText = if isSap then "Amber Sap" else "Heartwood",
        })
    end
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
    local storyLandmarkCount = 0
    local storyLandmarkPartCount = 0
    local eliteArena = nil
    local oldGrowthCenter: Vector3? = nil
    local extractionTarget: BasePart? = nil
    local meshPlacements = {}
    local resourceNodes = {}
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

        local cell = part(
            module,
            "StreamingCellCollision",
            Vector3.new(catalog.CellSize, 5, catalog.CellSize),
            CFrame.new(center + Vector3.new(0, -2.5, 0)),
            if placement.index % 2 == 0 then GRASS else Color3.fromRGB(43, 72, 49),
            Enum.Material.LeafyGrass
        )
        surfaceGrain(cell, Color3.fromRGB(23, 38, 31), 0.82)
        local clearing = part(
            module,
            "PathClearing",
            Vector3.new(26, 0.55, 26),
            CFrame.new(center + Vector3.new(0, 0.25, 0)),
            WET_EARTH,
            Enum.Material.Mud
        )
        clearing.Reflectance = 0.03
        if placement.index > 1 then
            pathArm(module, center, centers[placement.index - 1])
        end
        if placement.index < #manifest.modules then
            pathArm(module, center, centers[placement.index + 1])
            if placement.index % 2 == 1 then
                evacuationRoadMarker(module, center, centers[placement.index + 1], placement.index)
            end
        end

        moduleDressing(module, center, manifest.seed + placement.index * 97, runtimeIds)

        for cornerIndex = 1, 4 do
            local x = if cornerIndex == 1 or cornerIndex == 4 then -27 else 27
            local z = if cornerIndex <= 2 then -27 else 27
            tree(module, center + Vector3.new(x, 0, z), 0.62 + (cornerIndex % 2) * 0.08)
        end
        buildResourceNodes(
            module,
            center,
            placement.index,
            runtimeIds,
            resourceNodes,
            meshPlacements
        )
        local moduleDressingExtra = {}
        local meshPlacement =
            buildModuleVisual(module, definition.visual, center, runtimeIds, moduleDressingExtra)
        if meshPlacement ~= nil then
            table.insert(meshPlacements, meshPlacement)
        end
        for _, placementExtra in moduleDressingExtra do
            table.insert(meshPlacements, placementExtra)
        end
        if
            type(definition.storyLandmark) == "string"
            and type(definition.storyTitle) == "string"
        then
            local landmarkParts = buildStoryLandmark(
                module,
                center,
                definition.storyLandmark,
                definition.storyTitle,
                definition.storyOffset
            )
            assert(
                landmarkParts == definition.storyPartCount,
                "Bramblewake story landmark exceeded its authored part count"
            )
            storyLandmarkCount += 1
            storyLandmarkPartCount += landmarkParts
        end
        if definition.eliteId == "elite_old_growth" then
            oldGrowthCenter = center
            local fireSource = orb(
                module,
                "OldGrowthFireSource",
                center + Vector3.new(-20, 3.4, -12),
                1.35,
                AMBER,
                Enum.Material.Glass
            )
            fireSource.Transparency = 0.48
            cagedLanternShell(module, fireSource.Position, 0.86, "OldGrowthLantern")
            fireSource:SetAttribute("EliteId", definition.eliteId)
            fireSource:SetAttribute("EliteInteraction", "fire_source")
            billboard(fireSource, "LANTERN FIRE", CREAM)
            objectIcon(fireSource, "rootfire", AMBER)

            local rootHeart = orb(
                module,
                "OldGrowthRootHeart",
                center + Vector3.new(20, 4.2, 12),
                1.6,
                FOXFIRE,
                Enum.Material.Glass
            )
            rootHeart.Transparency = 0.56
            livingRootShell(module, rootHeart.Position, 1.08, "OldGrowthHeart")
            rootHeart:SetAttribute("EliteId", definition.eliteId)
            rootHeart:SetAttribute("EliteInteraction", "root_heart")
            billboard(rootHeart, "ROOT HEART", CREAM)
            objectIcon(rootHeart, "root", FOXFIRE)
            CollectionService:AddTag(fireSource, runtimeIds.ExpeditionEliteTag)
            CollectionService:AddTag(rootHeart, runtimeIds.ExpeditionEliteTag)
            eliteArena = {
                center = center,
                fireSource = fireSource,
                rootHeart = rootHeart,
            }
            queueItemAsset(
                meshPlacements,
                fireSource,
                "mesh_creator_kerosene_lantern_a",
                1.15,
                5200 + placement.index,
                math.rad(12),
                fireSource.Position.Y - 2.1
            )
            queueItemAsset(
                meshPlacements,
                rootHeart,
                "mesh_creator_predatory_flower_a",
                1.05,
                5300 + placement.index,
                math.rad(-16),
                rootHeart.Position.Y - 2.35
            )
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
            destinationCairns(module, target.Position, AMBER, 7)
        end

        if placement.poiId ~= nil then
            local poiMemory = buildPointOfInterest(
                module,
                center,
                generator.pointOfInterestDefinition(placement.poiId),
                runtimeIds,
                meshPlacements
            )
            queueItemAsset(
                meshPlacements,
                poiMemory,
                "mesh_creator_kerosene_lantern_a",
                0.95,
                5400 + placement.index,
                math.rad((placement.index % 3 - 1) * 9),
                poiMemory.Position.Y - 1.35
            )
        elseif placement.eventId ~= nil then
            local eventResult = buildEventSocket(
                module,
                center,
                generator.eventDefinition(placement.eventId),
                runtimeIds
            )
            eventSockets[placement.eventId] = eventResult.socket
            for interactionIndex, interaction in eventResult.interactions do
                table.insert(eventInteractions, interaction)
                local target = interaction.target
                local targetName = target.Name
                local assetId = "mesh_creator_crate_a"
                local scale = 0.72
                if string.find(targetName, "Foxlight", 1, true) ~= nil then
                    assetId = "mesh_creator_kerosene_lantern_a"
                    scale = 1
                elseif string.find(targetName, "RootKnot", 1, true) ~= nil then
                    assetId = "mesh_creator_stump_a"
                    scale = 0.58
                elseif string.find(targetName, "PollenScreen", 1, true) ~= nil then
                    assetId = "mesh_creator_barricade_a"
                    scale = 0.6
                elseif string.find(targetName, "HomesteadStore", 1, true) ~= nil then
                    assetId = if string.find(targetName, "fill_water", 1, true) ~= nil
                        then "mesh_creator_barrel_a"
                        else "mesh_creator_crate_a"
                    scale = 0.78
                elseif string.find(targetName, "WardenSign", 1, true) ~= nil then
                    assetId = "mesh_creator_forest_sign_a"
                    scale = 0.72
                elseif string.find(targetName, "WetFirebreak", 1, true) ~= nil then
                    assetId = "mesh_creator_road_stones_a"
                    scale = 0.28
                elseif string.find(targetName, "HedgeLatch", 1, true) ~= nil then
                    assetId = "mesh_creator_stump_a"
                    scale = 0.48
                end
                queueItemAsset(
                    meshPlacements,
                    target,
                    assetId,
                    scale,
                    6000 + placement.index * 10 + interactionIndex,
                    math.rad((interactionIndex - 2) * 11)
                )
            end
        end

        if placement.index == 1 then
            local arrivalSign = WorldSignBuilder.createDirectionSign(
                module,
                "BramblewakeArrival",
                CFrame.new(center + Vector3.new(0, 5.4, -8)) * CFrame.Angles(0, math.pi, 0),
                "BRAMBLEWAKE WOODS",
                CREAM
            )
            arrivalSign:SetAttribute("ArrivalLandmark", true)
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
    queueItemAsset(
        meshPlacements,
        bossArena.seal,
        "mesh_creator_memory_reliquary_a",
        1.12,
        7101,
        math.rad(180),
        bossArena.center.Y + 0.28
    )
    for nodeIndex, node in bossArena.nodes do
        queueItemAsset(
            meshPlacements,
            node,
            "mesh_creator_hollow_rootling_a",
            0.78,
            7200 + string.len(nodeIndex),
            math.rad(string.len(nodeIndex) * 7),
            node.Position.Y - 2.6
        )
    end
    queueItemAsset(
        meshPlacements,
        blackout.fireSource,
        "mesh_creator_kerosene_lantern_a",
        1.25,
        7301,
        math.rad(-9),
        blackout.fireSource.Position.Y - 2.2
    )
    local relaySeed = 0
    for _, node in blackout.relayNodes do
        relaySeed += 1
        queueItemAsset(
            meshPlacements,
            node,
            "mesh_creator_hollow_rootling_a",
            0.86,
            7310 + relaySeed,
            math.rad((relaySeed - 2) * 13),
            node.Position.Y - 2.7
        )
    end
    local decisionAssets = {
        restore_farmland = "mesh_creator_wheat_cluster_a",
        wild_regrowth = "mesh_creator_predatory_flower_a",
        shared_agroforest = "mesh_creator_stump_a",
    }
    local decisionSeed = 0
    for decisionId, target in blackout.decisions do
        decisionSeed += 1
        queueItemAsset(
            meshPlacements,
            target,
            decisionAssets[decisionId],
            1.05,
            7400 + decisionSeed,
            math.rad((decisionSeed - 2) * 15),
            target.Position.Y - 2.2
        )
    end
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
    expedition:SetAttribute("StoryLandmarkCount", storyLandmarkCount)
    expedition:SetAttribute("StoryLandmarkPartCount", storyLandmarkPartCount)
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
        resourceNodes = resourceNodes,
        eventSockets = eventSockets,
        eliteArena = assert(eliteArena, "Old Growth elite arena is missing"),
        bossArena = bossArena,
        blackout = blackout,
        meshPlacements = meshPlacements,
        moduleCenters = moduleCenters,
        partCount = generatedParts,
    }
end

return table.freeze(BramblewakeBuilder)
