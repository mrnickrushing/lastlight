--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BramblewakeBuilder = require(script.Parent.Parent.World.BramblewakeBuilder)

local WorldService = {}
WorldService.__index = WorldService
WorldService.Name = "WorldService"

export type Logger = {
    info: (self: Logger, event: string, fields: { [string]: any }?) -> (),
}

export type WorldService = typeof(setmetatable(
    {} :: {
        Name: string,
        _logger: Logger,
        _runtimeIds: any,
        _world: Model?,
        _interactions: { [string]: ProximityPrompt },
        _spawn: SpawnLocation?,
        _mara: Model?,
        _lantern: BasePart?,
        _beacon: BasePart?,
        _barricadeBuilt: boolean,
        _night: boolean,
        _blackoutLightingActive: boolean,
        _expeditionEntry: CFrame?,
        _expeditionManifest: any,
        _expeditionModuleCenters: { any },
        _eventSockets: { [string]: BasePart },
        _eventTargets: { [string]: { [string]: BasePart } },
        _eventsEnabled: boolean,
        _oldGrowthArena: any,
        _wardenStagArena: any,
        _blackoutArena: any,
        _characterRoots: { [Player]: BasePart? },
    },
    WorldService
))

local DAY_AMBIENT = Color3.fromRGB(76, 91, 86)
local NIGHT_AMBIENT = Color3.fromRGB(22, 31, 49)
local AMBER = Color3.fromRGB(255, 181, 76)
local FOXFIRE = Color3.fromRGB(94, 206, 176)
local CREAM = Color3.fromRGB(244, 230, 197)
local GREEN = Color3.fromRGB(47, 84, 63)
local DARK_GREEN = Color3.fromRGB(24, 55, 43)
local BARK = Color3.fromRGB(73, 48, 36)

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

local function labelSign(parent: Instance, at: CFrame, text: string)
    local board =
        part(parent, "TrailSign", Vector3.new(8, 3, 0.6), at, BARK, Enum.Material.WoodPlanks)
    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Front
    surface.LightInfluence = 0.5
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 32
    surface.Parent = board

    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.fromScale(1, 1)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = text
    textLabel.TextColor3 = CREAM
    textLabel.TextScaled = true
    textLabel.Parent = surface
end

local function lantern(parent: Instance, at: Vector3, scale: number): Part
    local post = part(
        parent,
        "LanternPost",
        Vector3.new(0.8 * scale, 7 * scale, 0.8 * scale),
        CFrame.new(at + Vector3.new(0, 3.5 * scale, 0)),
        BARK,
        Enum.Material.Wood
    )
    local glow = part(
        parent,
        "LanternGlow",
        Vector3.new(2.1 * scale, 2.7 * scale, 2.1 * scale),
        CFrame.new(at + Vector3.new(0, 6.2 * scale, 0)),
        AMBER,
        Enum.Material.Neon,
        false
    )
    glow.Shape = Enum.PartType.Ball
    glow.Transparency = 0.12
    local light = Instance.new("PointLight")
    light.Color = AMBER
    light.Brightness = 2.4
    light.Range = 24 * scale
    light.Shadows = true
    light.Parent = glow
    return post
end

local function pine(parent: Instance, position: Vector3, scale: number)
    local trunk = part(
        parent,
        "PineTrunk",
        Vector3.new(2.2 * scale, 13 * scale, 2.2 * scale),
        CFrame.new(position + Vector3.new(0, 6.5 * scale, 0)),
        BARK,
        Enum.Material.Wood
    )
    trunk.CFrame *= CFrame.Angles(0, position.X * 0.01, 0)

    for layer = 1, 3 do
        local foliage = part(
            parent,
            "PineNeedles",
            Vector3.new(
                (10 - layer * 1.4) * scale,
                (7 - layer * 0.8) * scale,
                (10 - layer * 1.4) * scale
            ),
            CFrame.new(position + Vector3.new(0, (10 + layer * 3.2) * scale, 0)),
            if layer == 3 then GREEN else DARK_GREEN,
            Enum.Material.Grass,
            false
        )
        foliage.Shape = Enum.PartType.Ball
    end
end

local function rock(parent: Instance, position: Vector3, scale: number)
    local stone = part(
        parent,
        "MossRock",
        Vector3.new(5.5 * scale, 3.2 * scale, 4.2 * scale),
        CFrame.new(position + Vector3.new(0, 1.4 * scale, 0))
            * CFrame.Angles(0.1, position.X * 0.03, 0.08),
        Color3.fromRGB(75, 83, 79),
        Enum.Material.Slate
    )
    stone.Shape = Enum.PartType.Ball
end

local function addBillboard(partInstance: BasePart, title: string, accent: Color3)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "WorldLabel"
    billboard.Adornee = partInstance
    billboard.AlwaysOnTop = false
    billboard.LightInfluence = 0.35
    billboard.Size = UDim2.fromOffset(220, 54)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
    billboard.MaxDistance = 45
    billboard.Parent = partInstance

    local text = Instance.new("TextLabel")
    text.BackgroundColor3 = Color3.fromRGB(16, 25, 23)
    text.BackgroundTransparency = 0.18
    text.BorderSizePixel = 0
    text.Size = UDim2.fromScale(1, 1)
    text.Font = Enum.Font.GothamBold
    text.Text = title
    text.TextColor3 = accent
    text.TextScaled = true
    text.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = text
end

function WorldService.new(logger: Logger): WorldService
    return setmetatable({
        Name = WorldService.Name,
        _logger = logger,
        _runtimeIds = nil,
        _world = nil,
        _interactions = {},
        _spawn = nil,
        _mara = nil,
        _lantern = nil,
        _beacon = nil,
        _barricadeBuilt = false,
        _night = false,
        _blackoutLightingActive = false,
        _expeditionEntry = nil,
        _expeditionManifest = nil,
        _expeditionModuleCenters = {},
        _eventSockets = {},
        _eventTargets = {},
        _eventsEnabled = true,
        _oldGrowthArena = nil,
        _wardenStagArena = nil,
        _blackoutArena = nil,
        _characterRoots = {},
    }, WorldService)
end

function WorldService._registerInteraction(
    self: WorldService,
    target: BasePart,
    interactionId: string,
    actionId: string,
    actionText: string,
    objectText: string,
    payload: string?,
    holdDuration: number?
)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = interactionId
    prompt.ActionText = actionText
    prompt.ObjectText = objectText
    prompt.HoldDuration = holdDuration or 0
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Style = Enum.ProximityPromptStyle.Custom
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt:SetAttribute("InteractionId", interactionId)
    prompt:SetAttribute("ActionId", actionId)
    if payload ~= nil then
        prompt:SetAttribute("Payload", payload)
    end
    prompt.Parent = target
    CollectionService:AddTag(prompt, self._runtimeIds.InteractionTag)
    self._interactions[interactionId] = prompt
end

function WorldService._configureLighting(_self: WorldService)
    Lighting.ClockTime = 8.2
    Lighting.Brightness = 2.2
    Lighting.Ambient = DAY_AMBIENT
    Lighting.OutdoorAmbient = Color3.fromRGB(92, 112, 102)
    Lighting.EnvironmentDiffuseScale = 0.45
    Lighting.EnvironmentSpecularScale = 0.3
    Lighting.GlobalShadows = true
    Lighting.ExposureCompensation = -0.1

    for _, name in { "LastLightAtmosphere", "LastLightBloom", "LastLightRays" } do
        local existing = Lighting:FindFirstChild(name)
        if existing ~= nil then
            existing:Destroy()
        end
    end

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "LastLightAtmosphere"
    atmosphere.Color = Color3.fromRGB(184, 207, 195)
    atmosphere.Decay = Color3.fromRGB(55, 76, 69)
    atmosphere.Density = 0.32
    atmosphere.Glare = 0.08
    atmosphere.Haze = 1.8
    atmosphere.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "LastLightBloom"
    bloom.Intensity = 0.35
    bloom.Size = 36
    bloom.Threshold = 1.1
    bloom.Parent = Lighting

    local rays = Instance.new("SunRaysEffect")
    rays.Name = "LastLightRays"
    rays.Intensity = 0.055
    rays.Spread = 0.82
    rays.Parent = Lighting
end

function WorldService._buildEnvironment(_self: WorldService, world: Model)
    local geometry = Instance.new("Folder")
    geometry.Name = "Environment"
    geometry.Parent = world

    part(
        geometry,
        "Ground",
        Vector3.new(320, 6, 340),
        CFrame.new(0, -3, -70),
        Color3.fromRGB(52, 84, 58),
        Enum.Material.Grass
    )

    local route = {
        Vector3.new(0, 0.1, 0),
        Vector3.new(-3, 0.1, -28),
        Vector3.new(20, 0.1, -48),
        Vector3.new(0, 0.1, -68),
        Vector3.new(-20, 0.1, -88),
        Vector3.new(0, 0.1, -112),
        Vector3.new(0, 0.1, -148),
    }

    for segment = 1, #route - 1 do
        local start = route[segment]
        local finish = route[segment + 1]
        local delta = finish - start
        local distance = delta.Magnitude
        local midpoint = (start + finish) / 2
        part(
            geometry,
            "LanternTrail",
            Vector3.new(10, 0.35, distance + 2),
            CFrame.lookAt(midpoint, finish),
            Color3.fromRGB(104, 91, 65),
            Enum.Material.Ground
        )
    end

    local random = Random.new(1847)
    for index = 1, 64 do
        local angle = random:NextNumber(0, math.pi * 2)
        local radius = random:NextNumber(68, 148)
        local zBias = -70
        local position = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius + zBias)
        pine(geometry, position, random:NextNumber(0.75, 1.45))
        if index % 4 == 0 then
            rock(
                geometry,
                position + Vector3.new(random:NextNumber(-9, 9), 0, random:NextNumber(-9, 9)),
                random:NextNumber(0.6, 1.25)
            )
        end
    end

    for index = 1, 18 do
        local angle = (index / 18) * math.pi * 2
        local radius = 158
        local cliff = part(
            geometry,
            "DistantCliff",
            Vector3.new(28, 44 + (index % 3) * 11, 18),
            CFrame.new(math.cos(angle) * radius, 17, math.sin(angle) * radius - 70)
                * CFrame.Angles(0, -angle, 0),
            Color3.fromRGB(45, 57, 55),
            Enum.Material.Rock
        )
        cliff.Shape = Enum.PartType.Ball
    end

    for _ = 1, 22 do
        local glow = part(
            geometry,
            "Firefly",
            Vector3.new(0.22, 0.22, 0.22),
            CFrame.new(
                random:NextNumber(-45, 45),
                random:NextNumber(2, 10),
                random:NextNumber(-135, -8)
            ),
            AMBER,
            Enum.Material.Neon,
            false
        )
        glow.Shape = Enum.PartType.Ball
        glow.CanQuery = false
    end

    lantern(geometry, Vector3.new(0, 0, -8), 0.72)
    lantern(geometry, Vector3.new(-9, 0, -62), 0.62)
    lantern(geometry, Vector3.new(9, 0, -102), 0.62)
    labelSign(geometry, CFrame.new(7, 3, -14) * CFrame.Angles(0, math.pi, 0), "EMBERHOLLOW")
end

function WorldService._buildMara(self: WorldService, world: Model)
    local model = Instance.new("Model")
    model.Name = "Mara"
    model:SetAttribute("ResidentId", "npc_mara")

    local root = part(
        model,
        "HumanoidRootPart",
        Vector3.new(2.2, 2.2, 1.2),
        CFrame.new(-3, 2.2, -30),
        Color3.fromRGB(66, 83, 66),
        Enum.Material.SmoothPlastic,
        false
    )
    root.Transparency = 1
    local torso = part(
        model,
        "Torso",
        Vector3.new(2.4, 3.2, 1.3),
        CFrame.new(-3, 3.4, -30),
        Color3.fromRGB(59, 83, 62),
        Enum.Material.Fabric,
        false
    )
    local head = part(
        model,
        "Head",
        Vector3.new(2, 2, 2),
        CFrame.new(-3, 6, -30),
        Color3.fromRGB(205, 153, 111),
        Enum.Material.SmoothPlastic,
        false
    )
    head.Shape = Enum.PartType.Ball
    part(
        model,
        "Hair",
        Vector3.new(2.25, 1.2, 2.25),
        CFrame.new(-3, 6.65, -30),
        Color3.fromRGB(79, 43, 31),
        Enum.Material.SmoothPlastic,
        false
    ).Shape =
        Enum.PartType.Ball
    part(
        model,
        "Scarf",
        Vector3.new(2.6, 0.5, 1.5),
        CFrame.new(-3, 5.05, -30),
        AMBER,
        Enum.Material.Fabric,
        false
    )
    model.PrimaryPart = root
    model.Parent = world
    addBillboard(head, "MARA", AMBER)

    for index = -1, 1 do
        part(
            world,
            "FallenRoot",
            Vector3.new(1.3, 10, 1.3),
            CFrame.new(-3 + index * 2.6, 2, -30)
                * CFrame.Angles(math.rad(72), 0, math.rad(index * 14)),
            BARK,
            Enum.Material.Wood
        )
    end

    self._mara = model
    self:_registerInteraction(
        torso,
        self._runtimeIds.InteractionIds.Mara,
        self._runtimeIds.Actions.Rescue,
        "FREE",
        "Mara",
        nil
    )
end

function WorldService._buildInteractables(self: WorldService, world: Model)
    local interactables = Instance.new("Folder")
    interactables.Name = "Interactables"
    interactables.Parent = world

    local stump = part(
        interactables,
        "HeartwoodStump",
        Vector3.new(7, 6, 7),
        CFrame.new(20, 3, -48),
        BARK,
        Enum.Material.Wood
    )
    stump.Shape = Enum.PartType.Cylinder
    stump.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
    local heart = part(
        interactables,
        "HeartwoodCore",
        Vector3.new(3.2, 3.2, 3.2),
        CFrame.new(20, 4.2, -48),
        AMBER,
        Enum.Material.Neon,
        false
    )
    heart.Shape = Enum.PartType.Ball
    addBillboard(heart, "HEARTWOOD", AMBER)
    self:_registerInteraction(
        stump,
        self._runtimeIds.InteractionIds.Heartwood,
        self._runtimeIds.Actions.Gather,
        "GATHER",
        "Heartwood",
        nil
    )

    local tools = {
        {
            id = self._runtimeIds.InteractionIds.ToolAxe,
            tool = "axe",
            x = -10,
            color = Color3.fromRGB(102, 154, 102),
        },
        {
            id = self._runtimeIds.InteractionIds.ToolHammer,
            tool = "hammer",
            x = 0,
            color = AMBER,
        },
        {
            id = self._runtimeIds.InteractionIds.ToolTorch,
            tool = "torch",
            x = 10,
            color = Color3.fromRGB(111, 154, 184),
        },
    }
    for _, definition in tools do
        local pedestal = part(
            interactables,
            "Tool_" .. definition.tool,
            Vector3.new(6, 2, 6),
            CFrame.new(definition.x, 1, -68),
            Color3.fromRGB(66, 70, 65),
            Enum.Material.Slate
        )
        local marker = part(
            interactables,
            "ToolGlow",
            Vector3.new(2.4, 4.5, 0.8),
            CFrame.new(definition.x, 4.1, -68)
                * CFrame.Angles(0, 0, if definition.tool == "torch" then 0 else math.rad(28)),
            definition.color,
            Enum.Material.Neon,
            false
        )
        addBillboard(marker, string.upper(definition.tool), definition.color)
        self:_registerInteraction(
            pedestal,
            definition.id,
            self._runtimeIds.Actions.ChooseTool,
            "CHOOSE",
            definition.tool,
            definition.tool
        )
    end

    local plot = part(
        interactables,
        "ConstructionPlot",
        Vector3.new(18, 0.5, 9),
        CFrame.new(-20, 0.25, -88),
        Color3.fromRGB(218, 184, 108),
        Enum.Material.Neon
    )
    plot.Transparency = 0.42
    addBillboard(plot, "BARRICADE PLOT", CREAM)
    self:_registerInteraction(
        plot,
        self._runtimeIds.InteractionIds.Barricade,
        self._runtimeIds.Actions.Build,
        "BUILD",
        "Barricade",
        nil
    )

    local lanternBase = part(
        interactables,
        "FirstLantern",
        Vector3.new(8, 3, 8),
        CFrame.new(0, 1.5, -112),
        Color3.fromRGB(67, 68, 61),
        Enum.Material.Slate
    )
    local flame = part(
        interactables,
        "FirstLanternFlame",
        Vector3.new(3.4, 5, 3.4),
        CFrame.new(0, 6, -112),
        AMBER,
        Enum.Material.Neon,
        false
    )
    flame.Shape = Enum.PartType.Ball
    local light = Instance.new("PointLight")
    light.Color = AMBER
    light.Brightness = 3
    light.Range = 42
    light.Shadows = true
    light.Parent = flame
    addBillboard(flame, "THE FIRST LANTERN", AMBER)
    self._lantern = flame
    self:_registerInteraction(
        lanternBase,
        self._runtimeIds.InteractionIds.Lantern,
        self._runtimeIds.Actions.Prepare,
        "LIGHT",
        "First Lantern",
        nil
    )

    local beacon = part(
        interactables,
        "BramblewakeBeacon",
        Vector3.new(7, 14, 7),
        CFrame.new(0, 7, -148),
        Color3.fromRGB(104, 187, 166),
        Enum.Material.Neon,
        false
    )
    beacon.Shape = Enum.PartType.Ball
    beacon.Transparency = 1
    beacon.CanQuery = false
    self._beacon = beacon
    self:_registerInteraction(
        beacon,
        self._runtimeIds.InteractionIds.Beacon,
        self._runtimeIds.Actions.Reveal,
        "REMEMBER",
        "Bramblewake",
        nil
    )
    local beaconPrompt = self._interactions[self._runtimeIds.InteractionIds.Beacon]
    beaconPrompt.Enabled = false

    local craftingBenches = {
        {
            id = self._runtimeIds.InteractionIds.CraftMeadowSatchel,
            recipeId = "recipe_meadow_satchel",
            label = "MEADOW SATCHEL",
            x = -16,
            color = Color3.fromRGB(133, 176, 108),
        },
        {
            id = self._runtimeIds.InteractionIds.CraftAmberCharm,
            recipeId = "recipe_amber_charm",
            label = "AMBER CHARM",
            x = 16,
            color = AMBER,
        },
    }
    for _, definition in craftingBenches do
        local bench = part(
            interactables,
            "CraftingBench_" .. definition.recipeId,
            Vector3.new(6, 2.6, 6),
            CFrame.new(definition.x, 1.3, -130),
            Color3.fromRGB(66, 70, 65),
            Enum.Material.Slate
        )
        local marker = part(
            interactables,
            "CraftingBenchGlow",
            Vector3.new(2, 3.4, 2),
            CFrame.new(definition.x, 4.3, -130),
            definition.color,
            Enum.Material.Neon,
            false
        )
        marker.Shape = Enum.PartType.Ball
        addBillboard(marker, definition.label, definition.color)
        self:_registerInteraction(
            bench,
            definition.id,
            self._runtimeIds.Actions.CraftItem,
            "CRAFT",
            definition.label,
            definition.recipeId
        )
    end
end

function WorldService.Init(self: WorldService, context: any)
    self._runtimeIds = context.runtimeIds
    self:_configureLighting()

    local existing = workspace:FindFirstChild(self._runtimeIds.WorldName)
    if existing ~= nil then
        existing:Destroy()
    end

    local world = Instance.new("Model")
    world.Name = self._runtimeIds.WorldName
    world:SetAttribute("WorldVersion", "bramblewake-blackout-v6")
    world:SetAttribute("Ready", false)
    world.Parent = workspace
    self._world = world

    self:_buildEnvironment(world)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "ArrivalSpawn"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.CFrame = CFrame.new(0, 1, 0)
    spawn.Transparency = 1
    spawn.Anchored = true
    spawn.CanCollide = true
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Parent = world
    self._spawn = spawn

    self:_buildMara(world)
    self:_buildInteractables(world)

    world:SetAttribute("Ready", true)
end

function WorldService.Start(self: WorldService)
    local function bindPlayer(player: Player)
        player:SetAttribute("LastLightInExpedition", false)
        player:SetAttribute("LastLightExpeditionTransition", false)
        self._characterRoots[player] = nil
        local function bindCharacter(character: Model)
            self._characterRoots[player] = nil
            task.defer(function()
                local root = character:WaitForChild("HumanoidRootPart", 5)
                if player.Character == character and root:IsA("BasePart") then
                    self._characterRoots[player] = root
                end
            end)
        end
        player.CharacterAdded:Connect(function(character: Model)
            player:SetAttribute("LastLightInExpedition", false)
            player:SetAttribute("LastLightExpeditionTransition", false)
            bindCharacter(character)
        end)
        local character = player.Character
        if character ~= nil then
            bindCharacter(character)
        end
    end
    Players.PlayerAdded:Connect(bindPlayer)
    for _, player in Players:GetPlayers() do
        bindPlayer(player)
    end

    Players.PlayerRemoving:Connect(function(player: Player)
        self._characterRoots[player] = nil
    end)

    local accumulator = 0
    RunService.Heartbeat:Connect(function(deltaTime: number)
        accumulator += deltaTime
        if accumulator < 0.5 then
            return
        end
        accumulator = 0

        for _, player in Players:GetPlayers() do
            local character = player.Character
            local root = self._characterRoots[player]
            if
                character ~= nil
                and root ~= nil
                and root.Parent ~= nil
                and root.Position.Y < -18
            then
                local recovery = if player:GetAttribute("LastLightInExpedition") == true
                        and self._expeditionEntry ~= nil
                    then self._expeditionEntry
                    else self:spawnCFrame()
                character:PivotTo(recovery :: CFrame)
            end
        end
    end)

    self._logger:info("world_started", {
        interactions = self:interactionCount(),
        worldVersion = "bramblewake-blackout-v6",
    })
end

function WorldService.interaction(self: WorldService, interactionId: string): ProximityPrompt?
    return self._interactions[interactionId]
end

function WorldService.interactionCount(self: WorldService): number
    local count = 0
    for _ in self._interactions do
        count += 1
    end
    return count
end

function WorldService.isInRange(
    _self: WorldService,
    player: Player,
    prompt: ProximityPrompt
): boolean
    local character = player.Character
    local root = if character == nil then nil else character:FindFirstChild("HumanoidRootPart")
    local target = prompt.Parent
    if root == nil or not root:IsA("BasePart") or target == nil or not target:IsA("BasePart") then
        return false
    end
    return (root.Position - target.Position).Magnitude <= prompt.MaxActivationDistance + 3
end

function WorldService.buildBarricade(self: WorldService)
    if self._barricadeBuilt then
        return
    end
    self._barricadeBuilt = true
    local world = assert(self._world, "world service has not initialized")

    for index = -4, 4 do
        local height = if index % 2 == 0 then 8 else 7
        part(
            world,
            "BarricadeStake",
            Vector3.new(1.3, height, 1.3),
            CFrame.new(-20 + index * 1.8, height / 2, -88)
                * CFrame.Angles(0, 0, math.rad(index * 2)),
            BARK,
            Enum.Material.WoodPlanks
        )
    end
    for level = 1, 2 do
        part(
            world,
            "BarricadeBrace",
            Vector3.new(18, 1, 1),
            CFrame.new(-20, 2 + level * 2.2, -87.3)
                * CFrame.Angles(0, 0, math.rad(if level == 1 then 8 else -8)),
            Color3.fromRGB(105, 69, 45),
            Enum.Material.WoodPlanks
        )
    end
end

function WorldService.moveMara(self: WorldService, destination: Vector3)
    local mara = self._mara
    if mara == nil or mara.PrimaryPart == nil then
        return
    end

    task.spawn(function()
        local start = mara:GetPivot()
        local target = CFrame.new(destination)
        for step = 1, 30 do
            mara:PivotTo(start:Lerp(target, step / 30))
            task.wait(0.035)
        end
    end)
end

function WorldService.setBeaconVisible(self: WorldService, visible: boolean)
    local beacon = self._beacon
    if beacon == nil then
        return
    end
    beacon.Transparency = if visible then 0.18 else 1
    beacon.CanQuery = visible
    local prompt = self._interactions[self._runtimeIds.InteractionIds.Beacon]
    if prompt ~= nil then
        prompt.Enabled = visible
    end
    if visible and beacon:FindFirstChildOfClass("PointLight") == nil then
        local light = Instance.new("PointLight")
        light.Color = beacon.Color
        light.Brightness = 4
        light.Range = 48
        light.Parent = beacon
        addBillboard(beacon, "THE BRAMBLEWAKE REMEMBERS", CREAM)
    end
end

function WorldService.buildBramblewake(
    self: WorldService,
    manifest: any,
    generator: any,
    catalog: any
): any
    local world = assert(self._world, "world service has not initialized")
    for interactionId, prompt in self._interactions do
        local actionId = prompt:GetAttribute("ActionId")
        if
            actionId == self._runtimeIds.Actions.ExpeditionEvent
            or actionId == self._runtimeIds.Actions.Extract
            or actionId == self._runtimeIds.Actions.OldGrowthFire
            or actionId == self._runtimeIds.Actions.WardenStagChoice
            or actionId == self._runtimeIds.Actions.BramblewakeBlackout
        then
            self._interactions[interactionId] = nil
        end
    end
    self._eventSockets = {}
    self._eventTargets = {}
    self._oldGrowthArena = nil
    self._wardenStagArena = nil
    self._blackoutArena = nil

    local result = BramblewakeBuilder.build(world, manifest, generator, catalog, self._runtimeIds)
    self._expeditionEntry = result.entryCFrame
    self._expeditionManifest = manifest
    self._expeditionModuleCenters = result.moduleCenters
    self._eventSockets = result.eventSockets
    self._oldGrowthArena = result.eliteArena
    self._wardenStagArena = result.bossArena
    self._blackoutArena = result.blackout
    self:_registerInteraction(
        result.extractionTarget,
        self._runtimeIds.InteractionIds.Wayhome,
        self._runtimeIds.Actions.Extract,
        "BANK & RETURN",
        "Wayhome Gate",
        nil,
        nil
    )
    for _, descriptor in result.eventInteractions do
        self:_registerInteraction(
            descriptor.target,
            descriptor.interactionId,
            self._runtimeIds.Actions.ExpeditionEvent,
            descriptor.actionText,
            descriptor.objectText,
            nil,
            nil
        )
        local prompt = self._interactions[descriptor.interactionId]
        prompt:SetAttribute("EventId", descriptor.eventId)
        prompt:SetAttribute("EventStepId", descriptor.stepId)
        local targets = self._eventTargets[descriptor.eventId]
        if targets == nil then
            targets = {}
            self._eventTargets[descriptor.eventId] = targets
        end
        targets[descriptor.stepId] = descriptor.target
    end
    self:_registerInteraction(
        result.eliteArena.fireSource,
        self._runtimeIds.InteractionIds.OldGrowthFireSource,
        self._runtimeIds.Actions.OldGrowthFire,
        "TAKE FIRE",
        "Lantern Fire",
        nil,
        nil
    )
    self:_registerInteraction(
        result.eliteArena.rootHeart,
        self._runtimeIds.InteractionIds.OldGrowthHeart,
        self._runtimeIds.Actions.OldGrowthFire,
        "BURN SHIELD",
        "Root Heart",
        nil,
        nil
    )
    self:setOldGrowthPresentation("dormant")
    for _, descriptor in result.bossArena.interactions do
        self:_registerInteraction(
            descriptor.target,
            descriptor.interactionId,
            self._runtimeIds.Actions.WardenStagChoice,
            descriptor.actionText,
            descriptor.objectText,
            nil,
            descriptor.holdDuration
        )
    end
    self:setWardenStagPresentation({
        brokenAntlers = {},
        cleansedNodes = {},
        status = "locked",
    })
    for _, descriptor in result.blackout.interactions do
        self:_registerInteraction(
            descriptor.target,
            descriptor.interactionId,
            self._runtimeIds.Actions.BramblewakeBlackout,
            descriptor.actionText,
            descriptor.objectText,
            nil,
            descriptor.holdDuration
        )
    end
    self:setBlackoutPresentation({
        deliveredNodes = {},
        status = "dormant",
    })
    world:SetAttribute("ExpeditionReady", true)
    world:SetAttribute("ExpeditionManifestHash", manifest.hash)
    world:SetAttribute("ExpeditionEventInteractions", #result.eventInteractions)
    return result
end

function WorldService.blackoutArena(self: WorldService): any
    return self._blackoutArena
end

function WorldService.setBlackoutPresentation(self: WorldService, state: any)
    local arena = self._blackoutArena
    local world = self._world
    if arena == nil then
        return
    end
    local status = tostring(state.status)
    local relay = status == "relay"
    local resolution = status == "resolution"
    local complete = status == "complete"
    local deliveredNodes = if type(state.deliveredNodes) == "table"
        then state.deliveredNodes
        else {}

    arena.fireSource.Color = if relay then AMBER else Color3.fromRGB(94, 83, 64)
    arena.fireSource.Material = if relay then Enum.Material.Neon else Enum.Material.SmoothPlastic
    arena.fireSource.Transparency = if relay then 0.1 else 0.58
    local firePrompt = self._interactions[self._runtimeIds.InteractionIds.BlackoutFireSource]
    if firePrompt ~= nil then
        firePrompt.Enabled = relay
    end

    for nodeId, target in arena.relayNodes do
        local delivered = deliveredNodes[nodeId] == true
        target.Color = if delivered
            then FOXFIRE
            elseif relay then Color3.fromRGB(255, 137, 72)
            else Color3.fromRGB(70, 91, 72)
        target.Material = if delivered or relay
            then Enum.Material.Neon
            else Enum.Material.SmoothPlastic
        target.Transparency = if delivered then 0.28 elseif relay then 0.12 else 0.58
        local prompt = target:FindFirstChildOfClass("ProximityPrompt")
        if prompt ~= nil then
            prompt.Enabled = relay
            prompt.ActionText = if delivered then "TAKE ROOTFIRE" else "DELIVER ROOTFIRE"
            prompt.ObjectText = if delivered then "Lit Living Root" else "Unlit Living Root"
        end
        for _, rootedWall in arena.model:GetChildren() do
            if
                rootedWall:IsA("BasePart")
                and rootedWall.Name == "RootedWall"
                and rootedWall:GetAttribute("BlackoutNodeId") == nodeId
            then
                rootedWall.Color = if delivered then Color3.fromRGB(52, 90, 61) else BARK
                rootedWall.Transparency = if delivered then 0.48 else 0
            end
        end
    end

    for decisionId, target in arena.decisions do
        target.Material = if resolution or complete
            then Enum.Material.Neon
            else Enum.Material.SmoothPlastic
        target.Transparency = if resolution then 0.08 elseif complete then 0.3 else 0.68
        local prompt = target:FindFirstChildOfClass("ProximityPrompt")
        if prompt ~= nil then
            prompt.Enabled = resolution
        end
        if complete then
            target:SetAttribute("Selected", state.decision == decisionId)
            if state.decision ~= decisionId then
                target.Transparency = 0.78
            end
        end
    end

    if world ~= nil then
        world:SetAttribute(
            "BlackoutActive",
            relay or status == "old_growth" or status == "warden" or resolution
        )
        world:SetAttribute("BlackoutStatus", status)
        world:SetAttribute("BlackoutRevision", tonumber(state.revision) or 0)
    end
end

function WorldService.setBlackoutLighting(self: WorldService, active: boolean)
    self._blackoutLightingActive = active
    local world = self._world
    if world ~= nil then
        world:SetAttribute("BlackoutLighting", active)
    end
    local effect = Lighting:FindFirstChild("LastLightBlackoutColor")
    if not active then
        if effect ~= nil then
            effect:Destroy()
        end
        -- Restore whichever of day/night is actually current -- the town
        -- cycle may have ticked past this Blackout's own start/end while it
        -- ran and setNight() skipped applying it (see setNight above).
        self:_applyTownLighting(self._night)
        return
    end
    Lighting.Ambient = Color3.fromRGB(18, 28, 35)
    local color = if effect ~= nil and effect:IsA("ColorCorrectionEffect")
        then effect
        else Instance.new("ColorCorrectionEffect")
    color.Name = "LastLightBlackoutColor"
    color.Brightness = -0.08
    color.Contrast = 0.14
    color.Saturation = -0.18
    color.TintColor = Color3.fromRGB(164, 205, 186)
    color.Parent = Lighting
end

function WorldService.oldGrowthArena(self: WorldService): any
    return self._oldGrowthArena
end

function WorldService.setOldGrowthPresentation(self: WorldService, status: string)
    local arena = self._oldGrowthArena
    if arena == nil then
        return
    end
    local shielded = status == "shielded"
    local complete = status == "complete"
    arena.fireSource.Color = if shielded then AMBER else Color3.fromRGB(96, 87, 68)
    arena.fireSource.Material = if shielded then Enum.Material.Neon else Enum.Material.SmoothPlastic
    arena.fireSource.Transparency = if shielded then 0.12 else 0.58
    arena.rootHeart.Color = if complete
        then FOXFIRE
        elseif shielded then Color3.fromRGB(255, 117, 74)
        else Color3.fromRGB(83, 102, 82)
    arena.rootHeart.Material = if shielded or complete
        then Enum.Material.Neon
        else Enum.Material.SmoothPlastic
    arena.rootHeart.Transparency = if shielded or complete then 0.14 else 0.58

    local firePrompt = self._interactions[self._runtimeIds.InteractionIds.OldGrowthFireSource]
    local heartPrompt = self._interactions[self._runtimeIds.InteractionIds.OldGrowthHeart]
    if firePrompt ~= nil then
        firePrompt.Enabled = shielded
    end
    if heartPrompt ~= nil then
        heartPrompt.Enabled = shielded
    end
end

function WorldService.wardenStagArena(self: WorldService): any
    return self._wardenStagArena
end

function WorldService.setWardenStagPresentation(self: WorldService, state: any)
    local arena = self._wardenStagArena
    if arena == nil then
        return
    end
    local status = tostring(state.status)
    local cleansing = status == "cleansing"
    local vulnerable = status == "vulnerable"
    local complete = status == "complete"
    local enabled = status ~= "disabled"
    local cleansedNodes = if type(state.cleansedNodes) == "table" then state.cleansedNodes else {}
    local brokenAntlers = if type(state.brokenAntlers) == "table" then state.brokenAntlers else {}

    arena.seal.Color = if complete
        then FOXFIRE
        elseif vulnerable then AMBER
        elseif cleansing then Color3.fromRGB(132, 186, 126)
        elseif status == "dormant" then Color3.fromRGB(94, 154, 133)
        else Color3.fromRGB(77, 88, 79)
    arena.seal.Material = if complete
            or vulnerable
            or cleansing
        then Enum.Material.Neon
        else Enum.Material.SmoothPlastic
    arena.seal.Transparency = if enabled then 0.24 else 0.72

    for nodeId, target in arena.nodes do
        local cleansed = cleansedNodes[nodeId] == true
        target.Color = if cleansed
            then FOXFIRE
            elseif cleansing then AMBER
            else Color3.fromRGB(80, 99, 82)
        target.Material = if cleansed or cleansing
            then Enum.Material.Neon
            else Enum.Material.SmoothPlastic
        target.Transparency = if cleansed then 0.46 elseif cleansing then 0.12 else 0.56
        local interactionId = target:GetAttribute("InteractionId")
        local prompt = if type(interactionId) == "string"
            then self._interactions[interactionId]
            else target:FindFirstChildOfClass("ProximityPrompt")
        if prompt ~= nil then
            prompt.Enabled = cleansing and not cleansed
        end
    end

    for antlerId, target in arena.antlers do
        local broken = brokenAntlers[antlerId] == true
        target.Color = if broken
            then Color3.fromRGB(91, 78, 67)
            elseif cleansing then Color3.fromRGB(255, 166, 106)
            else Color3.fromRGB(145, 145, 126)
        target.Material = if cleansing and not broken
            then Enum.Material.Neon
            else Enum.Material.SmoothPlastic
        target.Transparency = if broken then 0.78 elseif cleansing then 0.14 else 0.58
        local prompt = target:FindFirstChildOfClass("ProximityPrompt")
        if prompt ~= nil then
            prompt.Enabled = cleansing and not broken
        end
    end
end

function WorldService.setExpeditionEventsEnabled(self: WorldService, enabled: boolean)
    self._eventsEnabled = enabled
    local world = self._world
    if world ~= nil then
        world:SetAttribute("ExpeditionEventsEnabled", enabled)
    end
    for _, prompt in self._interactions do
        if prompt:GetAttribute("ActionId") == self._runtimeIds.Actions.ExpeditionEvent then
            prompt.Enabled = enabled
        end
    end
end

function WorldService.setExpeditionEventState(self: WorldService, eventId: string, state: any)
    local socket = self._eventSockets[eventId]
    if socket ~= nil then
        socket:SetAttribute("Dormant", state.status == "dormant")
        socket:SetAttribute("Status", state.status)
        socket:SetAttribute("Progress", state.progress)
        socket:SetAttribute("ProgressTotal", state.total)
        socket:SetAttribute("Revision", state.revision)
    end

    local targets = self._eventTargets[eventId]
    if targets == nil then
        return
    end
    local eventCanProgress = self._eventsEnabled
        and (state.status == "dormant" or state.status == "active")
    for stepId, target in targets do
        local complete = state.completedSteps[stepId] == true
        target:SetAttribute(
            "EventStepState",
            if complete then "complete" else if eventCanProgress then "available" else state.status
        )
        if complete then
            target.Color = FOXFIRE
            target.Material = Enum.Material.Neon
            target.Transparency = 0.12
        elseif state.status == "failed" or state.status == "disabled" then
            target.Color = Color3.fromRGB(83, 91, 83)
            target.Material = Enum.Material.SmoothPlastic
            target.Transparency = 0.5
        end
        local prompt = target:FindFirstChildOfClass("ProximityPrompt")
        if prompt ~= nil then
            prompt.Enabled = eventCanProgress and not complete
        end
    end
end

function WorldService.enterBramblewake(self: WorldService, player: Player): boolean
    local entry = self._expeditionEntry
    local character = player.Character
    if entry == nil or character == nil then
        return false
    end
    if player:GetAttribute("LastLightExpeditionTransition") == true then
        return true
    end

    player:SetAttribute("LastLightInExpedition", true)
    player:SetAttribute("LastLightExpeditionTransition", true)
    task.spawn(function()
        local streamFinished = false
        task.spawn(function()
            pcall(function()
                player:RequestStreamAroundAsync(entry.Position)
            end)
            streamFinished = true
        end)

        local deadline = os.clock() + 5
        while not streamFinished and os.clock() < deadline and player.Parent ~= nil do
            task.wait(0.1)
        end

        local activeCharacter = player.Character
        if
            player.Parent ~= nil
            and player:GetAttribute("LastLightInExpedition") == true
            and activeCharacter ~= nil
        then
            activeCharacter:PivotTo(entry)
        end
        player:SetAttribute("LastLightExpeditionTransition", false)
    end)
    return true
end

function WorldService.exitBramblewake(self: WorldService, player: Player): boolean
    local character = player.Character
    if character == nil then
        return false
    end
    if player:GetAttribute("LastLightExpeditionTransition") == true then
        return true
    end

    local destination = self:spawnCFrame()
    player:SetAttribute("LastLightInExpedition", false)
    player:SetAttribute("LastLightExpeditionTransition", true)
    task.spawn(function()
        local streamFinished = false
        task.spawn(function()
            pcall(function()
                player:RequestStreamAroundAsync(destination.Position)
            end)
            streamFinished = true
        end)

        local deadline = os.clock() + 5
        while not streamFinished and os.clock() < deadline and player.Parent ~= nil do
            task.wait(0.1)
        end

        local activeCharacter = player.Character
        if player.Parent ~= nil and activeCharacter ~= nil then
            activeCharacter:PivotTo(destination)
        end
        player:SetAttribute("LastLightExpeditionTransition", false)
    end)
    return true
end

function WorldService.expeditionSnapshot(self: WorldService, player: Player): any
    local manifest = self._expeditionManifest
    if manifest == nil or player:GetAttribute("LastLightInExpedition") ~= true then
        return {
            active = false,
        }
    end

    local character = player.Character
    local root = if character == nil then nil else character:FindFirstChild("HumanoidRootPart")
    local closestIndex = 1
    local closestDistance = math.huge
    if root ~= nil and root:IsA("BasePart") then
        for _, moduleCenter in self._expeditionModuleCenters do
            local distance = (root.Position - moduleCenter.position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestIndex = moduleCenter.index
            end
        end
    end

    local placement = manifest.modules[closestIndex]
    return {
        active = true,
        eventId = placement.eventId,
        manifestHash = manifest.hash,
        moduleId = placement.moduleId,
        moduleIndex = closestIndex,
        moduleTotal = #manifest.modules,
        poiId = placement.poiId,
        seed = manifest.seed,
        source = manifest.source,
    }
end

-- Raw property application shared by setNight and setBlackoutLighting's
-- restore path, so the two never disagree about what "town day" or "town
-- night" actually looks like.
function WorldService._applyTownLighting(_self: WorldService, night: boolean)
    if night then
        Lighting.ClockTime = 0.2
        Lighting.Brightness = 1.25
        Lighting.Ambient = NIGHT_AMBIENT
        Lighting.OutdoorAmbient = Color3.fromRGB(27, 37, 55)
        Lighting.ExposureCompensation = -0.45
    else
        Lighting.ClockTime = 6.8
        Lighting.Brightness = 2.4
        Lighting.Ambient = DAY_AMBIENT
        Lighting.OutdoorAmbient = Color3.fromRGB(102, 120, 110)
        Lighting.ExposureCompensation = 0
    end
end

function WorldService.setNight(self: WorldService, enabled: boolean)
    self._night = enabled
    -- The recurring town cycle and the Blackout are timed independently and
    -- can now be active at once (an earlier decision deliberately keeps
    -- Bramblewake entry unblocked regardless of the town's night count).
    -- Let the Blackout's own dramatic presentation own shared Lighting while
    -- it's active instead of the two fighting over the same properties every
    -- time either one ticks; setBlackoutLighting(false) restores whichever
    -- of these this flag says is current once it ends.
    if self._blackoutLightingActive then
        return
    end
    self:_applyTownLighting(enabled)
end

function WorldService.spawnCFrame(self: WorldService): CFrame
    local spawn = assert(self._spawn, "arrival spawn has not initialized")
    return spawn.CFrame + Vector3.new(0, 5, 0)
end

function WorldService.lanternPosition(self: WorldService): Vector3
    return assert(self._lantern, "First Lantern has not initialized").Position
end

function WorldService.enemySpawnPosition(_self: WorldService): Vector3
    return Vector3.new(0, 2, -153)
end

return table.freeze(WorldService)
