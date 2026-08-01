--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

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
        _extractionPayoff: any,
        _runtimeIds: any,
        _world: Model?,
        _interactions: { [string]: ProximityPrompt },
        _spawn: SpawnLocation?,
        _mara: Model?,
        _lantern: BasePart?,
        _lanternVisualHealth: number,
        _beacon: BasePart?,
        _barricadeBuilt: boolean,
        _dusk: boolean,
        _duskSignals: { BasePart },
        _nightDefenseSignals: { BasePart },
        _breachActive: boolean,
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
        _townConsequence: any,
    },
    WorldService
))

local DAY_AMBIENT = Color3.fromRGB(50, 63, 58)
local NIGHT_AMBIENT = Color3.fromRGB(13, 18, 33)
local AMBER = Color3.fromRGB(255, 181, 76)
local FOXFIRE = Color3.fromRGB(94, 206, 176)
local CREAM = Color3.fromRGB(244, 230, 197)
local GREEN = Color3.fromRGB(42, 77, 51)
local DARK_GREEN = Color3.fromRGB(18, 42, 32)
local BARK = Color3.fromRGB(62, 39, 30)
local WET_BARK = Color3.fromRGB(36, 26, 24)
local MOSS = Color3.fromRGB(58, 91, 54)
local WET_EARTH = Color3.fromRGB(67, 55, 39)
local WAYHOME_DELIVERY_LIFETIME = 180
local WAYHOME_DELIVERY_ORIGINS = table.freeze({
    Vector3.new(-27, 0, -13),
    Vector3.new(-18, 0, -13),
    Vector3.new(-9, 0, -13),
    Vector3.new(9, 0, -13),
    Vector3.new(18, 0, -13),
    Vector3.new(27, 0, -13),
    Vector3.new(-27, 0, -21),
    Vector3.new(27, 0, -21),
})

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
    if not instance.CanCollide then
        instance.CanQuery = false
    end
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

local function buildEmberhollowSanctuary(parent: Instance)
    local courtyard = Vector3.new(0, 0, -112)
    local courtyardPatch = part(
        parent,
        "EmberhollowCourtyard",
        Vector3.new(54, 0.3, 36),
        CFrame.new(courtyard + Vector3.new(0, 0.18, 1)),
        Color3.fromRGB(53, 59, 45),
        Enum.Material.Ground,
        false
    )
    courtyardPatch.Transparency = 0.08

    -- A readable camp silhouette gives the arrival area a destination before
    -- the player understands the systems. The cabins are fully roofed, with a
    -- deliberate doorway instead of four floating walls.
    local function cabin(center: Vector3, name: string, accent: Color3)
        local cabinFolder = Instance.new("Folder")
        cabinFolder.Name = name
        cabinFolder.Parent = parent

        part(
            cabinFolder,
            "CabinFloor",
            Vector3.new(14, 0.5, 12),
            CFrame.new(center + Vector3.new(0, 0.25, 0)),
            Color3.fromRGB(75, 57, 42),
            Enum.Material.WoodPlanks
        )
        part(
            cabinFolder,
            "CabinBackWall",
            Vector3.new(14, 8, 0.7),
            CFrame.new(center + Vector3.new(0, 4.25, 5.65)),
            BARK,
            Enum.Material.WoodPlanks
        )
        for side = -1, 1, 2 do
            part(
                cabinFolder,
                "CabinSideWall",
                Vector3.new(0.7, 8, 12),
                CFrame.new(center + Vector3.new(side * 6.65, 4.25, 0)),
                BARK,
                Enum.Material.WoodPlanks
            )
            part(
                cabinFolder,
                "CabinDoorPost",
                Vector3.new(0.8, 8, 0.8),
                CFrame.new(center + Vector3.new(side * 5.2, 4.25, -5.65)),
                WET_BARK,
                Enum.Material.Wood
            )
        end
        part(
            cabinFolder,
            "CabinFrontBeam",
            Vector3.new(14, 1, 0.8),
            CFrame.new(center + Vector3.new(0, 7.8, -5.65)),
            WET_BARK,
            Enum.Material.Wood
        )
        for side = -1, 1, 2 do
            local window = part(
                cabinFolder,
                "CabinWindow",
                Vector3.new(2.7, 2.2, 0.18),
                CFrame.new(center + Vector3.new(side * 6.3, 4.8, 1.8)),
                accent,
                Enum.Material.Glass,
                false
            )
            window.Transparency = 0.22
        end
        local roof = part(
            cabinFolder,
            "CabinRoof",
            Vector3.new(16, 0.8, 14),
            CFrame.new(center + Vector3.new(0, 8.7, 0)) * CFrame.Angles(0, 0, math.rad(2)),
            Color3.fromRGB(42, 47, 41),
            Enum.Material.Slate
        )
        roof.CastShadow = true
        local porch = part(
            cabinFolder,
            "CabinPorch",
            Vector3.new(10, 0.35, 3),
            CFrame.new(center + Vector3.new(0, 0.55, -7.1)),
            Color3.fromRGB(85, 63, 43),
            Enum.Material.WoodPlanks
        )
        porch.CanQuery = false
        local windowLight = Instance.new("PointLight")
        windowLight.Color = accent
        windowLight.Brightness = 0.9
        windowLight.Range = 14
        windowLight.Shadows = false
        windowLight.Parent = cabinFolder
        local lightAnchor = part(
            cabinFolder,
            "CabinLight",
            Vector3.new(0.2, 0.2, 0.2),
            CFrame.new(center + Vector3.new(0, 4.4, 2.8)),
            accent,
            Enum.Material.Neon,
            false
        )
        windowLight.Parent = lightAnchor
        local sign = part(
            cabinFolder,
            "CabinSign",
            Vector3.new(5.5, 1.4, 0.35),
            CFrame.new(center + Vector3.new(0, 6.8, -6.1)),
            WET_BARK,
            Enum.Material.WoodPlanks,
            false
        )
        sign.CanQuery = false
        local surface = Instance.new("SurfaceGui")
        surface.Face = Enum.NormalId.Front
        surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        surface.PixelsPerStud = 28
        surface.Parent = sign
        local signText = Instance.new("TextLabel")
        signText.BackgroundTransparency = 1
        signText.Size = UDim2.fromScale(1, 1)
        signText.Font = Enum.Font.GothamBold
        signText.Text = string.upper(name)
        signText.TextColor3 = accent
        signText.TextScaled = true
        signText.Parent = surface

        if name == "MARA'S SHELTER" then
            local cot = part(
                cabinFolder,
                "MaraCot",
                Vector3.new(5.2, 0.55, 2.7),
                CFrame.new(center + Vector3.new(-3.2, 0.85, 3.6)),
                Color3.fromRGB(96, 112, 83),
                Enum.Material.Fabric,
                false
            )
            cot.CanQuery = false
            local tableTop = part(
                cabinFolder,
                "MaraWorkTable",
                Vector3.new(4.2, 0.45, 2.5),
                CFrame.new(center + Vector3.new(3.5, 2.1, 3.5)),
                Color3.fromRGB(89, 64, 43),
                Enum.Material.WoodPlanks,
                false
            )
            tableTop.CanQuery = false
            for jarIndex = -1, 1 do
                local jar = part(
                    cabinFolder,
                    "MemoryJar",
                    Vector3.new(0.7, 1.05, 0.7),
                    CFrame.new(center + Vector3.new(3.5 + jarIndex * 1.1, 2.85, 3.5)),
                    if jarIndex == 0 then FOXFIRE else AMBER,
                    Enum.Material.Glass,
                    false
                )
                jar.Shape = Enum.PartType.Cylinder
                jar.Transparency = 0.22
                jar.CanQuery = false
            end
        else
            for bedIndex = -1, 1, 2 do
                local bedroll = part(
                    cabinFolder,
                    "WayfarerBedroll",
                    Vector3.new(4.8, 0.45, 2.3),
                    CFrame.new(center + Vector3.new(bedIndex * 3.3, 0.72, 2.7)),
                    if bedIndex < 0
                        then Color3.fromRGB(127, 91, 58)
                        else Color3.fromRGB(72, 104, 82),
                    Enum.Material.Fabric,
                    false
                )
                bedroll.CanQuery = false
            end
            local trunk = part(
                cabinFolder,
                "WayfarerTrunk",
                Vector3.new(4.4, 2.3, 2.5),
                CFrame.new(center + Vector3.new(0, 1.15, 4.25)),
                Color3.fromRGB(88, 61, 39),
                Enum.Material.WoodPlanks,
                false
            )
            trunk.CanQuery = false
        end
    end

    cabin(Vector3.new(-22, 0, -112), "WAYFARER CABIN", AMBER)
    cabin(Vector3.new(22, 0, -112), "MARA'S SHELTER", FOXFIRE)

    for index = 1, 8 do
        local angle = (index / 8) * math.pi * 2
        local stone = part(
            parent,
            "LanternRingStone",
            Vector3.new(2.2, 1.3, 1.7),
            CFrame.new(courtyard + Vector3.new(math.cos(angle) * 7.3, 0.65, math.sin(angle) * 7.3))
                * CFrame.Angles(0.08, angle, 0.12),
            Color3.fromRGB(78, 82, 74),
            Enum.Material.Slate
        )
        stone.Shape = Enum.PartType.Ball
    end
    for side = -1, 1, 2 do
        local bench = part(
            parent,
            "LanternBench",
            Vector3.new(7, 0.7, 1.6),
            CFrame.new(courtyard + Vector3.new(side * 11, 1.2, 0))
                * CFrame.Angles(0, math.rad(90), 0),
            Color3.fromRGB(91, 65, 45),
            Enum.Material.WoodPlanks
        )
        bench.CanQuery = false
        for leg = -1, 1, 2 do
            local support = part(
                parent,
                "LanternBenchLeg",
                Vector3.new(0.45, 1.2, 1.1),
                CFrame.new(courtyard + Vector3.new(side * 11, 0.6, leg * 2.1)),
                WET_BARK,
                Enum.Material.Wood,
                false
            )
            support.CanQuery = false
        end
    end
    labelSign(
        parent,
        CFrame.new(0, 3.2, -95) * CFrame.Angles(0, math.pi, 0),
        "EMBERHOLLOW · SAFE CAMP"
    )
end

local function lantern(parent: Instance, at: Vector3, scale: number, ambientLightTag: string?): Part
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
    -- Keep the sanctuary's key lantern as the only strong shadow source. The
    -- route lights are guidance, not a second sun, which keeps mobile scenes
    -- readable and avoids a wall of competing shadows.
    light.Shadows = false
    light.Parent = glow
    if ambientLightTag ~= nil then
        CollectionService:AddTag(glow, ambientLightTag)
    end
    return post
end

local function pine(parent: Instance, position: Vector3, scale: number, ambientSwayTag: string?)
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
        local canopyPosition = position + Vector3.new(0, (9.5 + layer * 3.4) * scale, 0)
        local canopySize = Vector3.new(
            (11 - layer * 1.7) * scale,
            (7.5 - layer * 0.9) * scale,
            (11 - layer * 1.7) * scale
        )
        for half = 1, 2 do
            local foliage = part(
                parent,
                "PineNeedles",
                canopySize,
                CFrame.new(canopyPosition)
                    * CFrame.Angles(0, if half == 1 then 0.2 else math.pi + 0.2, 0),
                if layer == 3 then GREEN else DARK_GREEN,
                Enum.Material.Grass,
                false
            )
            foliage.Shape = Enum.PartType.Wedge
            foliage.CanQuery = false
            if ambientSwayTag ~= nil and half == 2 then
                CollectionService:AddTag(foliage, ambientSwayTag)
            end
        end
    end
    for side = -1, 1, 2 do
        local branch = part(
            parent,
            "PineBranch",
            Vector3.new(0.7 * scale, 5 * scale, 0.7 * scale),
            CFrame.new(position + Vector3.new(side * 2.5 * scale, 7.5 * scale, -0.2))
                * CFrame.Angles(0, 0, math.rad(side * 52)),
            BARK,
            Enum.Material.Wood,
            false
        )
        branch.CanQuery = false
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

local function grassTuft(parent: Instance, position: Vector3, scale: number, color: Color3)
    for blade = 1, 3 do
        local stalk = part(
            parent,
            "GrassBlade",
            Vector3.new(0.18 * scale, 1.6 * scale, 0.18 * scale),
            CFrame.new(position + Vector3.new((blade - 2) * 0.28 * scale, 0.8 * scale, 0))
                * CFrame.Angles(math.rad((blade - 2) * 18), 0, math.rad((blade - 2) * 12)),
            color,
            Enum.Material.Grass,
            false
        )
        stalk.CanQuery = false
    end
end

local function groundPatch(
    parent: Instance,
    position: Vector3,
    size: Vector3,
    color: Color3,
    material: Enum.Material
)
    local patch = part(
        parent,
        "WetGroundPatch",
        size,
        CFrame.new(position + Vector3.new(0, 0.18, 0)) * CFrame.Angles(0, position.X * 0.017, 0),
        color,
        material,
        false
    )
    patch.Transparency = 0.08
    patch.CanQuery = false
    return patch
end

local function fernCluster(
    parent: Instance,
    position: Vector3,
    scale: number,
    ambientSwayTag: string?
)
    for blade = 1, 7 do
        local angle = (blade / 7) * math.pi * 2
        local leaf = part(
            parent,
            "FernFrond",
            Vector3.new(0.38 * scale, 0.18 * scale, 3.2 * scale),
            CFrame.new(
                position
                    + Vector3.new(
                        math.cos(angle) * 0.75 * scale,
                        0.65 * scale,
                        math.sin(angle) * 0.75 * scale
                    )
            ) * CFrame.Angles(math.rad(22), angle, math.rad(math.sin(angle) * 10)),
            if blade % 2 == 0 then MOSS else Color3.fromRGB(39, 74, 43),
            Enum.Material.Grass,
            false
        )
        leaf.CanQuery = false
        if ambientSwayTag ~= nil and (blade == 2 or blade == 5) then
            CollectionService:AddTag(leaf, ambientSwayTag)
        end
    end
end

local function deadfall(parent: Instance, position: Vector3, scale: number, angle: number)
    local log = part(
        parent,
        "RainDarkDeadfall",
        Vector3.new(2.4 * scale, 15 * scale, 2.4 * scale),
        CFrame.new(position + Vector3.new(0, 1.3 * scale, 0))
            * CFrame.Angles(math.rad(82), angle, math.rad(5)),
        WET_BARK,
        Enum.Material.Wood
    )
    log.Shape = Enum.PartType.Cylinder
    log.CanQuery = false
    for rib = -1, 1 do
        local cut = part(
            parent,
            "BrokenWoodRib",
            Vector3.new(0.55 * scale, 2.7 * scale, 0.55 * scale),
            CFrame.new(
                position
                    + Vector3.new(
                        math.cos(angle) * rib * 4.8 * scale,
                        1.9 * scale,
                        math.sin(angle) * rib * 4.8 * scale
                    )
            )
                * CFrame.Angles(math.rad(68), angle + math.rad(rib * 12), 0),
            BARK,
            Enum.Material.Wood,
            false
        )
        cut.CanQuery = false
    end
end

local function mistSheet(
    parent: Instance,
    name: string,
    position: Vector3,
    size: Vector3,
    color: Color3,
    transparency: number
)
    local mist = part(parent, name, size, CFrame.new(position), color, Enum.Material.Glass, false)
    mist.Transparency = transparency
    mist.CastShadow = false
    mist.CanQuery = false
    return mist
end

local function emberDrift(
    parent: Instance,
    position: Vector3,
    color: Color3,
    count: number,
    spread: number,
    ambientTag: string?
)
    local random = Random.new(math.floor(position.X * 17 + position.Z * 31))
    for _ = 1, count do
        local mote = part(
            parent,
            "FloatingMote",
            Vector3.new(0.16, 0.16, 0.16),
            CFrame.new(
                position
                    + Vector3.new(
                        random:NextNumber(-spread, spread),
                        random:NextNumber(1.5, 8),
                        random:NextNumber(-spread, spread)
                    )
            ),
            color,
            Enum.Material.Neon,
            false
        )
        mote.Shape = Enum.PartType.Ball
        mote.Transparency = random:NextNumber(0.1, 0.35)
        mote.CanQuery = false
        if ambientTag ~= nil then
            CollectionService:AddTag(mote, ambientTag)
        end
    end
end

local function addFillLight(
    parent: Instance,
    position: Vector3,
    color: Color3,
    brightness: number,
    range: number
)
    local source = part(
        parent,
        "HiddenAtmosphereLight",
        Vector3.new(0.4, 0.4, 0.4),
        CFrame.new(position),
        color,
        Enum.Material.Neon,
        false
    )
    source.Transparency = 1
    source.CanQuery = false
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Shadows = false
    light.Parent = source
end

local function addSurfaceGrain(target: BasePart, color: Color3, transparency: number)
    local decal = Instance.new("Decal")
    decal.Name = "MaterialVariation"
    decal.Color3 = color
    decal.Transparency = transparency
    decal.Face = Enum.NormalId.Top
    decal.Parent = target
end

local function addBillboard(partInstance: BasePart, title: string, accent: Color3)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "WorldLabel"
    billboard.Adornee = partInstance
    billboard.AlwaysOnTop = false
    billboard.LightInfluence = 0.35
    billboard.Size = UDim2.fromOffset(165, 38)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)
    billboard.MaxDistance = 32
    billboard.Parent = partInstance

    local text = Instance.new("TextLabel")
    text.BackgroundColor3 = Color3.fromRGB(16, 25, 23)
    text.BackgroundTransparency = 0.18
    text.BorderSizePixel = 0
    text.Size = UDim2.fromScale(1, 1)
    text.Font = Enum.Font.GothamBold
    text.Text = title
    text.TextColor3 = accent
    text.TextScaled = false
    text.TextSize = 12
    text.TextWrapped = true
    text.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = text
end

local function _addObjectIcon(partInstance: BasePart, kind: string, accent: Color3)
    local existing = partInstance:FindFirstChild("ObjectIcon")
    if existing ~= nil then
        existing:Destroy()
    end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ObjectIcon"
    billboard.Adornee = partInstance
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Size = UDim2.fromOffset(44, 44)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 5.8, 0)
    billboard.MaxDistance = 72
    billboard.Parent = partInstance

    local glyph = Instance.new("TextLabel")
    glyph.Name = "IconGlyph"
    glyph.BackgroundColor3 = Color3.fromRGB(10, 21, 19)
    glyph.BackgroundTransparency = 0.05
    glyph.BorderSizePixel = 0
    glyph.Size = UDim2.fromScale(1, 1)
    glyph.Font = Enum.Font.GothamBold
    glyph.Text = if kind == "axe"
        then "⚒"
        elseif kind == "hammer" then "✚"
        elseif kind == "torch" or kind == "lantern" then "✦"
        elseif kind == "heartwood" then "◉"
        elseif kind == "barricade" then "▰"
        elseif kind == "satchel" then "▣"
        elseif kind == "charm" then "◆"
        elseif kind == "hood" then "⌂"
        elseif kind == "boots" then "≋"
        else "✦"
    glyph.TextColor3 = accent
    glyph.TextScaled = true
    glyph.ZIndex = 10
    glyph.Parent = billboard
    local glyphCorner = Instance.new("UICorner")
    glyphCorner.CornerRadius = UDim.new(0, 10)
    glyphCorner.Parent = glyph

    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "IconViewport"
    viewport.Size = UDim2.fromScale(1, 1)
    viewport.BackgroundColor3 = Color3.fromRGB(15, 27, 24)
    viewport.BackgroundTransparency = 0.08
    viewport.BorderSizePixel = 0
    viewport.Ambient = Color3.fromRGB(210, 224, 212)
    viewport.LightColor = Color3.fromRGB(255, 214, 146)
    viewport.Parent = billboard
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = viewport

    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewport
    local camera = Instance.new("Camera")
    camera.CFrame = CFrame.new(0, 0.2, 6) * CFrame.Angles(0, math.rad(16), 0)
    camera.FieldOfView = 28
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    local function iconPart(
        name: string,
        size: Vector3,
        position: Vector3,
        color: Color3,
        material: Enum.Material,
        shape: Enum.PartType?
    )
        local icon = Instance.new("Part")
        icon.Name = name
        icon.Anchored = true
        icon.CanCollide = false
        icon.CanQuery = false
        icon.Size = size
        icon.Position = position
        icon.Color = color
        icon.Material = material
        icon.Shape = shape or Enum.PartType.Block
        icon.Parent = worldModel
        return icon
    end

    if kind == "heartwood" then
        iconPart(
            "Trunk",
            Vector3.new(1.5, 2.5, 1.5),
            Vector3.new(0, -0.5, 0),
            BARK,
            Enum.Material.Wood,
            Enum.PartType.Cylinder
        )
        iconPart(
            "Core",
            Vector3.new(1.2, 1.2, 1.2),
            Vector3.new(0, 0.65, 0),
            accent,
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
    elseif kind == "axe" then
        iconPart(
            "Handle",
            Vector3.new(0.25, 2.8, 0.25),
            Vector3.new(0, -0.1, 0),
            BARK,
            Enum.Material.Wood
        )
        iconPart(
            "Blade",
            Vector3.new(1.25, 0.9, 0.22),
            Vector3.new(0.35, 0.85, 0),
            accent,
            Enum.Material.Metal
        )
    elseif kind == "hammer" then
        iconPart(
            "Handle",
            Vector3.new(0.25, 2.6, 0.25),
            Vector3.new(0, -0.1, 0),
            BARK,
            Enum.Material.Wood
        )
        iconPart(
            "Head",
            Vector3.new(1.6, 0.55, 0.55),
            Vector3.new(0, 0.95, 0),
            accent,
            Enum.Material.Metal
        )
    elseif kind == "torch" or kind == "lantern" then
        iconPart(
            "Handle",
            Vector3.new(0.28, 2.1, 0.28),
            Vector3.new(0, -0.45, 0),
            BARK,
            Enum.Material.Wood
        )
        iconPart(
            "Flame",
            Vector3.new(1.2, 1.5, 1.2),
            Vector3.new(0, 0.75, 0),
            accent,
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
    elseif kind == "satchel" then
        iconPart(
            "Bag",
            Vector3.new(2.1, 1.6, 1.2),
            Vector3.new(0, -0.15, 0),
            accent,
            Enum.Material.Fabric
        )
        iconPart(
            "Strap",
            Vector3.new(0.22, 2.2, 0.2),
            Vector3.new(0, 0.15, 0.65),
            BARK,
            Enum.Material.Wood
        )
    elseif kind == "charm" then
        iconPart(
            "Gem",
            Vector3.new(1.35, 1.35, 1.35),
            Vector3.new(0, 0, 0),
            accent,
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
        iconPart(
            "Ring",
            Vector3.new(0.22, 1.9, 1.9),
            Vector3.new(0, 0, 0),
            FOXFIRE,
            Enum.Material.Metal,
            Enum.PartType.Cylinder
        )
    elseif kind == "hood" then
        iconPart(
            "Hood",
            Vector3.new(2.2, 1.7, 1.7),
            Vector3.new(0, 0.1, 0),
            accent,
            Enum.Material.Fabric
        )
        iconPart(
            "Rim",
            Vector3.new(2.5, 0.25, 1.8),
            Vector3.new(0, -0.75, -0.1),
            DARK_GREEN,
            Enum.Material.Wood
        )
    elseif kind == "boots" then
        iconPart(
            "LeftBoot",
            Vector3.new(0.8, 1.45, 1.6),
            Vector3.new(-0.55, -0.2, 0),
            accent,
            Enum.Material.Fabric
        )
        iconPart(
            "RightBoot",
            Vector3.new(0.8, 1.45, 1.6),
            Vector3.new(0.55, -0.2, 0),
            accent,
            Enum.Material.Fabric
        )
    else
        iconPart(
            "Marker",
            Vector3.new(1.4, 1.4, 1.4),
            Vector3.new(0, 0, 0),
            accent,
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
    end
end

function WorldService.new(logger: Logger, extractionPayoff: any): WorldService
    return setmetatable({
        Name = WorldService.Name,
        _logger = logger,
        _extractionPayoff = extractionPayoff,
        _runtimeIds = nil,
        _world = nil,
        _interactions = {},
        _spawn = nil,
        _mara = nil,
        _lantern = nil,
        _lanternVisualHealth = 100,
        _beacon = nil,
        _barricadeBuilt = false,
        _dusk = false,
        _duskSignals = {},
        _nightDefenseSignals = {},
        _breachActive = false,
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
        _townConsequence = nil,
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
    Lighting.ClockTime = 6.65
    Lighting.Brightness = 2.05
    Lighting.Ambient = DAY_AMBIENT
    Lighting.OutdoorAmbient = Color3.fromRGB(72, 91, 84)
    Lighting.EnvironmentDiffuseScale = 0.72
    Lighting.EnvironmentSpecularScale = 0.48
    Lighting.GlobalShadows = true
    Lighting.ExposureCompensation = -0.18
    pcall(function()
        Lighting.ShadowSoftness = 0.42
        Lighting.GeographicLatitude = 51
    end)
    pcall(function()
        Workspace.Terrain.Decoration = true
    end)

    for _, name in
        {
            "LastLightAtmosphere",
            "LastLightBloom",
            "LastLightRays",
            "LastLightTone",
            "LastLightDepth",
        }
    do
        local existing = Lighting:FindFirstChild(name)
        if existing ~= nil then
            existing:Destroy()
        end
    end
    local existingClouds = Workspace.Terrain:FindFirstChild("LastLightClouds")
    if existingClouds ~= nil then
        existingClouds:Destroy()
    end

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "LastLightAtmosphere"
    atmosphere.Color = Color3.fromRGB(166, 185, 174)
    atmosphere.Decay = Color3.fromRGB(43, 63, 61)
    atmosphere.Density = 0.34
    atmosphere.Offset = 0.08
    atmosphere.Glare = 0.2
    atmosphere.Haze = 1.9
    atmosphere.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "LastLightBloom"
    bloom.Intensity = 0.34
    bloom.Size = 46
    bloom.Threshold = 0.82
    bloom.Parent = Lighting

    local rays = Instance.new("SunRaysEffect")
    rays.Name = "LastLightRays"
    rays.Intensity = 0.14
    rays.Spread = 0.72
    rays.Parent = Lighting

    local tone = Instance.new("ColorCorrectionEffect")
    tone.Name = "LastLightTone"
    tone.Brightness = -0.03
    tone.Contrast = 0.24
    tone.Saturation = -0.04
    tone.TintColor = Color3.fromRGB(232, 238, 224)
    tone.Parent = Lighting

    local depth = Instance.new("DepthOfFieldEffect")
    depth.Name = "LastLightDepth"
    depth.FarIntensity = 0.28
    depth.FocusDistance = 95
    depth.InFocusRadius = 70
    depth.NearIntensity = 0.04
    depth.Parent = Lighting

    local clouds = Instance.new("Clouds")
    clouds.Name = "LastLightClouds"
    clouds.Color = Color3.fromRGB(118, 137, 132)
    clouds.Cover = 0.68
    clouds.Density = 0.58
    clouds.Parent = Workspace.Terrain
end

function WorldService._buildEnvironment(_self: WorldService, world: Model)
    local geometry = Instance.new("Folder")
    geometry.Name = "Environment"
    geometry.Parent = world

    local ground = part(
        geometry,
        "Ground",
        Vector3.new(320, 6, 340),
        CFrame.new(0, -3, -70),
        Color3.fromRGB(38, 68, 46),
        Enum.Material.Grass
    )
    addSurfaceGrain(ground, Color3.fromRGB(28, 42, 34), 0.78)

    groundPatch(
        geometry,
        Vector3.new(0, 0, -70),
        Vector3.new(96, 0.28, 180),
        Color3.fromRGB(43, 63, 45),
        Enum.Material.LeafyGrass
    )
    mistSheet(
        geometry,
        "LowMorningMist",
        Vector3.new(0, 2.3, -86),
        Vector3.new(190, 1.4, 250),
        Color3.fromRGB(132, 158, 151),
        0.82
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
        local trail = part(
            geometry,
            "LanternTrail",
            Vector3.new(12, 0.35, distance + 3),
            CFrame.lookAt(midpoint, finish),
            WET_EARTH,
            Enum.Material.Mud
        )
        trail.Reflectance = 0.04
        for side = -1, 1, 2 do
            groundPatch(
                geometry,
                midpoint + Vector3.new(side * 7.2, 0.04, 0),
                Vector3.new(2.4, 0.18, distance * 0.82),
                Color3.fromRGB(31, 54, 37),
                Enum.Material.LeafyGrass
            )
        end
    end

    local random = Random.new(1847)
    for index = 1, 92 do
        local angle = random:NextNumber(0, math.pi * 2)
        local radius = random:NextNumber(54, 154)
        local zBias = -70
        local position = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius + zBias)
        pine(geometry, position, random:NextNumber(0.82, 1.65), _self._runtimeIds.AmbientSwayTag)
        if index % 3 == 0 then
            rock(
                geometry,
                position + Vector3.new(random:NextNumber(-10, 10), 0, random:NextNumber(-10, 10)),
                random:NextNumber(0.7, 1.45)
            )
        end
        if index % 2 == 0 then
            grassTuft(
                geometry,
                position + Vector3.new(random:NextNumber(-6, 6), 0, random:NextNumber(-6, 6)),
                random:NextNumber(0.8, 1.5),
                if index % 4 == 0 then Color3.fromRGB(58, 105, 62) else Color3.fromRGB(83, 116, 68)
            )
        end
        if index % 5 == 0 then
            fernCluster(
                geometry,
                position + Vector3.new(random:NextNumber(-7, 7), 0, random:NextNumber(-7, 7)),
                random:NextNumber(0.75, 1.35),
                _self._runtimeIds.AmbientSwayTag
            )
        end
        if index % 13 == 0 then
            deadfall(
                geometry,
                position + Vector3.new(random:NextNumber(-8, 8), 0, random:NextNumber(-8, 8)),
                random:NextNumber(0.65, 1.2),
                random:NextNumber(0, math.pi * 2)
            )
        end
    end

    for index = 1, 24 do
        local angle = (index / 24) * math.pi * 2
        local radius = 156 + (index % 4) * 6
        local cliff = part(
            geometry,
            "DistantCliff",
            Vector3.new(32, 46 + (index % 4) * 13, 22),
            CFrame.new(math.cos(angle) * radius, 18, math.sin(angle) * radius - 70)
                * CFrame.Angles(0, -angle, math.rad((index % 3 - 1) * 4)),
            Color3.fromRGB(34, 47, 47),
            Enum.Material.Rock
        )
        cliff.Shape = Enum.PartType.Ball
        cliff.Transparency = 0.06
    end

    for _ = 1, 34 do
        local glow = part(
            geometry,
            "Firefly",
            Vector3.new(0.18, 0.18, 0.18),
            CFrame.new(
                random:NextNumber(-52, 52),
                random:NextNumber(2, 12),
                random:NextNumber(-142, -8)
            ),
            if random:NextInteger(1, 4) == 1 then FOXFIRE else AMBER,
            Enum.Material.Neon,
            false
        )
        glow.Shape = Enum.PartType.Ball
        glow.Transparency = random:NextNumber(0.02, 0.28)
        glow.CanQuery = false
        CollectionService:AddTag(glow, _self._runtimeIds.AmbientMoteTag)
    end

    for index = 1, 24 do
        local angle = (index / 24) * math.pi * 2
        local radius = 48 + (index % 4) * 8
        local position = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius - 70)
        rock(geometry, position, 0.5 + (index % 5) * 0.13)
        if index % 2 == 0 then
            fernCluster(
                geometry,
                position + Vector3.new(3, 0, -2),
                0.8,
                _self._runtimeIds.AmbientSwayTag
            )
        end
    end

    addFillLight(geometry, Vector3.new(-46, 12, -96), Color3.fromRGB(54, 103, 95), 0.85, 78)
    addFillLight(geometry, Vector3.new(38, 10, -28), Color3.fromRGB(255, 177, 88), 0.45, 54)
    emberDrift(geometry, Vector3.new(0, 0, -112), AMBER, 16, 28, _self._runtimeIds.AmbientMoteTag)

    lantern(geometry, Vector3.new(0, 0, -8), 0.72, _self._runtimeIds.AmbientLightTag)
    lantern(geometry, Vector3.new(-9, 0, -62), 0.62, _self._runtimeIds.AmbientLightTag)
    lantern(geometry, Vector3.new(9, 0, -102), 0.62, _self._runtimeIds.AmbientLightTag)
    labelSign(geometry, CFrame.new(7, 3, -14) * CFrame.Angles(0, math.pi, 0), "EMBERHOLLOW")
    buildEmberhollowSanctuary(geometry)

    local warningFolder = Instance.new("Folder")
    warningFolder.Name = "DuskTreelineWarnings"
    warningFolder.Parent = geometry
    local warningCenters = {
        Vector3.new(-44, 3.1, -133),
        Vector3.new(46, 3.4, -121),
        Vector3.new(0, 3.2, -174),
    }
    for warningIndex, center in warningCenters do
        local body = part(
            warningFolder,
            "DuskThreatSilhouette",
            Vector3.new(5.2, 6.4, 3.3),
            CFrame.new(center) * CFrame.Angles(0, math.rad((warningIndex - 2) * 18), 0),
            Color3.fromRGB(24, 27, 28),
            Enum.Material.Slate,
            false
        )
        body.Shape = Enum.PartType.Ball
        body.CastShadow = false
        body.Transparency = 1
        body:SetAttribute("DuskTransparency", 0.08)
        table.insert(_self._duskSignals, body)
        for side = -1, 1, 2 do
            local shoulder = part(
                warningFolder,
                "DuskThreatRoot",
                Vector3.new(0.8, 5.4, 0.8),
                CFrame.new(center + Vector3.new(side * 2.7, 0.2, 0))
                    * CFrame.Angles(0, 0, math.rad(side * 30)),
                WET_BARK,
                Enum.Material.Wood,
                false
            )
            shoulder.CastShadow = false
            shoulder.Transparency = 1
            shoulder:SetAttribute("DuskTransparency", 0.12)
            table.insert(_self._duskSignals, shoulder)

            local eye = part(
                warningFolder,
                "DuskThreatEye",
                Vector3.new(0.38, 0.38, 0.22),
                CFrame.new(center + Vector3.new(side * 0.72, 0.65, -1.65)),
                Color3.fromRGB(255, 137, 82),
                Enum.Material.Neon,
                false
            )
            eye.Shape = Enum.PartType.Ball
            eye.CastShadow = false
            eye.Transparency = 1
            eye:SetAttribute("DuskTransparency", 0.04)
            table.insert(_self._duskSignals, eye)
        end
    end

    local defenseRoute = Instance.new("Folder")
    defenseRoute.Name = "NightDefenseRoute"
    defenseRoute.Parent = geometry
    for markerIndex = 1, 7 do
        local marker = part(
            defenseRoute,
            "DefenseTrailMarker",
            Vector3.new(5.8, 0.18, 1.1),
            CFrame.new(if markerIndex % 2 == 0 then 4.6 else -4.6, 0.3, -151 + markerIndex * 5),
            AMBER,
            Enum.Material.Glass,
            false
        )
        marker.Transparency = 1
        marker.CastShadow = false
        marker:SetAttribute("SignalRole", "trail")
        table.insert(_self._nightDefenseSignals, marker)
    end
    for side = -1, 1, 2 do
        local towerCenter = Vector3.new(side * 10.5, 0, -143)
        for postSide = -1, 1, 2 do
            part(
                defenseRoute,
                "WatchPost",
                Vector3.new(0.85, 8.5, 0.85),
                CFrame.new(towerCenter + Vector3.new(postSide * 2.2, 4.25, 0)),
                WET_BARK,
                Enum.Material.Wood
            )
        end
        part(
            defenseRoute,
            "WatchPlatform",
            Vector3.new(6.2, 0.65, 5.2),
            CFrame.new(towerCenter + Vector3.new(0, 7.1, 0)),
            Color3.fromRGB(83, 61, 43),
            Enum.Material.WoodPlanks
        )
        local brazier = part(
            defenseRoute,
            "WatchSignalFire",
            Vector3.new(1.55, 2.2, 1.55),
            CFrame.new(towerCenter + Vector3.new(0, 8.8, 0)),
            AMBER,
            Enum.Material.Neon,
            false
        )
        brazier.Shape = Enum.PartType.Ball
        brazier.Transparency = 1
        brazier.CastShadow = false
        brazier:SetAttribute("SignalRole", "fire")
        local signalLight = Instance.new("PointLight")
        signalLight.Name = "WatchSignalLight"
        signalLight.Color = AMBER
        signalLight.Brightness = 0
        signalLight.Range = 24
        signalLight.Shadows = false
        signalLight.Parent = brazier
        table.insert(_self._nightDefenseSignals, brazier)
    end
    local warningBoard = part(
        defenseRoute,
        "NightWatchBoard",
        Vector3.new(13, 2.8, 0.55),
        CFrame.new(0, 4.6, -146.8),
        BARK,
        Enum.Material.WoodPlanks,
        false
    )
    addBillboard(warningBoard, "NIGHT WATCH · HOLD THE LANTERN ROAD", CREAM)
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
    part(
        model,
        "CoatSkirt",
        Vector3.new(2.9, 2.5, 1.55),
        CFrame.new(-3, 1.9, -30),
        Color3.fromRGB(48, 68, 55),
        Enum.Material.Fabric,
        false
    )
    for side = -1, 1, 2 do
        part(
            model,
            "Arm",
            Vector3.new(0.72, 3.1, 0.72),
            CFrame.new(-3 + side * 1.55, 3.45, -30) * CFrame.Angles(0, 0, math.rad(side * 9)),
            Color3.fromRGB(54, 75, 59),
            Enum.Material.Fabric,
            false
        )
        local hand = part(
            model,
            "Hand",
            Vector3.new(0.76, 0.76, 0.76),
            CFrame.new(-3 + side * 1.78, 1.95, -30),
            Color3.fromRGB(205, 153, 111),
            Enum.Material.SmoothPlastic,
            false
        )
        hand.Shape = Enum.PartType.Ball
        part(
            model,
            "Leg",
            Vector3.new(0.82, 2.1, 0.9),
            CFrame.new(-3 + side * 0.68, 0.65, -30),
            Color3.fromRGB(45, 51, 48),
            Enum.Material.Fabric,
            false
        )
        part(
            model,
            "Boot",
            Vector3.new(1, 0.72, 1.5),
            CFrame.new(-3 + side * 0.68, 0.36, -30.25),
            Color3.fromRGB(54, 39, 31),
            Enum.Material.Leather,
            false
        )
        local eye = part(
            model,
            "Eye",
            Vector3.new(0.28, 0.28, 0.16),
            CFrame.new(-3 + side * 0.48, 6.18, -30.94),
            Color3.fromRGB(55, 39, 34),
            Enum.Material.SmoothPlastic,
            false
        )
        eye.Shape = Enum.PartType.Ball
    end
    part(
        model,
        "HairBack",
        Vector3.new(2.2, 2.6, 0.65),
        CFrame.new(-3, 5.7, -29.8),
        Color3.fromRGB(79, 43, 31),
        Enum.Material.SmoothPlastic,
        false
    )
    part(
        model,
        "FieldSatchel",
        Vector3.new(1.55, 1.7, 0.8),
        CFrame.new(-4.45, 2.85, -29.55) * CFrame.Angles(0, 0, math.rad(-8)),
        Color3.fromRGB(113, 79, 49),
        Enum.Material.Leather,
        false
    )
    part(
        model,
        "SatchelStrap",
        Vector3.new(0.24, 4.4, 0.24),
        CFrame.new(-3.5, 3.85, -29.55) * CFrame.Angles(0, 0, math.rad(24)),
        Color3.fromRGB(83, 57, 40),
        Enum.Material.Leather,
        false
    )
    local handLantern = part(
        model,
        "MaraLantern",
        Vector3.new(0.95, 1.25, 0.95),
        CFrame.new(-1.2, 1.45, -30),
        AMBER,
        Enum.Material.Glass,
        false
    )
    handLantern.Shape = Enum.PartType.Ball
    handLantern.Transparency = 0.14
    local handLight = Instance.new("PointLight")
    handLight.Color = AMBER
    handLight.Brightness = 0.65
    handLight.Range = 10
    handLight.Shadows = false
    handLight.Parent = handLantern
    CollectionService:AddTag(handLantern, self._runtimeIds.AmbientLightTag)
    model.PrimaryPart = root
    model.Parent = world
    model:SetAttribute("MotionKind", "resident")
    model:SetAttribute("MotionSpeed", 0.72)
    CollectionService:AddTag(model, self._runtimeIds.AmbientMotionTag)
    addBillboard(head, "MARA · GREENWARD", AMBER)

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
        Enum.Material.Glass,
        false
    )
    heart.Shape = Enum.PartType.Ball
    local heartLight = Instance.new("PointLight")
    heartLight.Color = AMBER
    heartLight.Brightness = 1.1
    heartLight.Range = 12
    heartLight.Parent = heart
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
            "ToolHandle",
            Vector3.new(0.45, 4.2, 0.45),
            CFrame.new(definition.x, 4.1, -68)
                * CFrame.Angles(0, 0, if definition.tool == "torch" then 0 else math.rad(28)),
            Color3.fromRGB(111, 76, 48),
            Enum.Material.Wood,
            false
        )
        if definition.tool == "axe" then
            local head = part(
                interactables,
                "AxeHead",
                Vector3.new(2.25, 0.65, 0.38),
                CFrame.new(definition.x - 0.28, 5.82, -68) * CFrame.Angles(0, 0, math.rad(28)),
                Color3.fromRGB(154, 169, 174),
                Enum.Material.Metal,
                false
            )
            head.Shape = Enum.PartType.Wedge
        elseif definition.tool == "hammer" then
            local head = part(
                interactables,
                "HammerHead",
                Vector3.new(2.15, 0.78, 0.9),
                CFrame.new(definition.x, 5.85, -68) * CFrame.Angles(0, 0, math.rad(90)),
                Color3.fromRGB(123, 132, 137),
                Enum.Material.Metal,
                false
            )
            head.Shape = Enum.PartType.Cylinder
        else
            local cup = part(
                interactables,
                "TorchCup",
                Vector3.new(1.2, 0.72, 1.2),
                CFrame.new(definition.x, 6.05, -68),
                Color3.fromRGB(92, 71, 48),
                Enum.Material.Metal,
                false
            )
            cup.Shape = Enum.PartType.Cylinder
            local flame = part(
                interactables,
                "TorchFlame",
                Vector3.new(1.15, 1.55, 1.15),
                CFrame.new(definition.x, 6.95, -68),
                definition.color,
                Enum.Material.Neon,
                false
            )
            flame.Shape = Enum.PartType.Ball
            local flameLight = Instance.new("PointLight")
            flameLight.Color = definition.color
            flameLight.Brightness = 1.5
            flameLight.Range = 12
            flameLight.Parent = flame
            CollectionService:AddTag(flame, self._runtimeIds.AmbientLightTag)
        end
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
        Enum.Material.Ground
    )
    plot.Transparency = 0.08
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

    local gate = Instance.new("Folder")
    gate.Name = "BramblewakeDawnGate"
    gate.Parent = interactables
    for side = -1, 1, 2 do
        part(
            gate,
            "DawnGateRoot",
            Vector3.new(1.35, 11, 1.35),
            CFrame.new(side * 5.2, 5.5, -148) * CFrame.Angles(0, 0, math.rad(side * 7)),
            WET_BARK,
            Enum.Material.Wood
        )
        part(
            gate,
            "DawnGateBrace",
            Vector3.new(0.8, 6.2, 0.8),
            CFrame.new(side * 3.7, 10.8, -148) * CFrame.Angles(0, 0, math.rad(side * 62)),
            BARK,
            Enum.Material.Wood
        )
    end
    part(
        gate,
        "DawnGateLintel",
        Vector3.new(11.5, 1.2, 1.2),
        CFrame.new(0, 11, -148),
        BARK,
        Enum.Material.WoodPlanks
    )
    for stepIndex = 1, 3 do
        part(
            gate,
            "DawnGateStep",
            Vector3.new(12 - stepIndex * 1.3, 0.45, 3.2),
            CFrame.new(0, 0.22 + stepIndex * 0.08, -140 - stepIndex * 2.2),
            Color3.fromRGB(66, 73, 68),
            Enum.Material.Slate
        )
    end
    for markerIndex = 1, 6 do
        local marker = part(
            gate,
            "DawnPathMarker",
            Vector3.new(0.72, 0.36, 0.72),
            CFrame.new(if markerIndex % 2 == 0 then 4.8 else -4.8, 0.38, -114 - markerIndex * 4.3),
            FOXFIRE,
            Enum.Material.Glass,
            false
        )
        marker.Shape = Enum.PartType.Ball
        marker.Transparency = 1
        marker.CastShadow = false
    end

    local beacon = part(
        interactables,
        "BramblewakeBeacon",
        Vector3.new(3.4, 5.4, 3.4),
        CFrame.new(0, 6.2, -148),
        Color3.fromRGB(104, 187, 166),
        Enum.Material.Glass,
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

    local workshop = Instance.new("Folder")
    workshop.Name = "GreenwardWorkshop"
    workshop.Parent = interactables
    local function workshopBay(centerX: number, title: string, accent: Color3)
        part(
            workshop,
            "WorkshopFloor",
            Vector3.new(27, 0.45, 14),
            CFrame.new(centerX, 0.22, -130),
            Color3.fromRGB(73, 57, 42),
            Enum.Material.WoodPlanks
        )
        part(
            workshop,
            "WorkshopBackWall",
            Vector3.new(27, 7.4, 0.7),
            CFrame.new(centerX, 3.7, -136.65),
            BARK,
            Enum.Material.WoodPlanks
        )
        for side = -1, 1, 2 do
            part(
                workshop,
                "WorkshopSideWall",
                Vector3.new(0.7, 7.4, 14),
                CFrame.new(centerX + side * 13.15, 3.7, -130),
                BARK,
                Enum.Material.WoodPlanks
            )
            part(
                workshop,
                "WorkshopFrontPost",
                Vector3.new(0.9, 8, 0.9),
                CFrame.new(centerX + side * 12.7, 4, -123.35),
                WET_BARK,
                Enum.Material.Wood
            )
        end
        part(
            workshop,
            "WorkshopFrontBeam",
            Vector3.new(27, 0.9, 0.9),
            CFrame.new(centerX, 7.45, -123.35),
            WET_BARK,
            Enum.Material.Wood
        )
        for slope = -1, 1, 2 do
            part(
                workshop,
                "WorkshopRoof",
                Vector3.new(29, 0.72, 8.4),
                CFrame.new(centerX, 8.3, -130 + slope * 3.55)
                    * CFrame.Angles(math.rad(slope * 8), 0, 0),
                Color3.fromRGB(42, 47, 43),
                Enum.Material.Slate
            )
        end
        part(
            workshop,
            "WorkshopShelf",
            Vector3.new(21, 0.4, 2.1),
            CFrame.new(centerX, 3.2, -135.25),
            Color3.fromRGB(91, 65, 45),
            Enum.Material.WoodPlanks
        )
        for supplyIndex = 1, 4 do
            local supply = part(
                workshop,
                "WorkshopSupply",
                Vector3.new(2.3, 1.4 + (supplyIndex % 2) * 0.5, 1.6),
                CFrame.new(centerX - 8.2 + supplyIndex * 3.3, 4.1, -135.2),
                if supplyIndex % 2 == 0 then accent else Color3.fromRGB(103, 78, 52),
                if supplyIndex % 2 == 0 then Enum.Material.Fabric else Enum.Material.WoodPlanks,
                false
            )
            supply.CanQuery = false
        end
        for crateIndex = -1, 1, 2 do
            local crate = part(
                workshop,
                "WorkshopCrate",
                Vector3.new(3.1, 2.4, 3),
                CFrame.new(centerX + crateIndex * 9.5, 1.2, -134.1),
                Color3.fromRGB(88, 64, 43),
                Enum.Material.WoodPlanks,
                false
            )
            crate.CanQuery = false
        end
        local lamp = part(
            workshop,
            "WorkshopLamp",
            Vector3.new(1.25, 1.65, 1.25),
            CFrame.new(centerX, 6.5, -126.1),
            accent,
            Enum.Material.Glass,
            false
        )
        lamp.Shape = Enum.PartType.Ball
        lamp.Transparency = 0.14
        local lampLight = Instance.new("PointLight")
        lampLight.Color = accent
        lampLight.Brightness = 0.85
        lampLight.Range = 15
        lampLight.Shadows = false
        lampLight.Parent = lamp
        labelSign(workshop, CFrame.new(centerX, 5.4, -136.95), title)
    end
    workshopBay(-22, "ROOTWORKS", Color3.fromRGB(133, 176, 108))
    workshopBay(22, "OUTFITTER", AMBER)

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
        {
            id = self._runtimeIds.InteractionIds.CraftIronrootHood,
            recipeId = "recipe_ironroot_hood",
            label = "IRONROOT HOOD",
            x = -28,
            color = Color3.fromRGB(122, 148, 132),
        },
        {
            id = self._runtimeIds.InteractionIds.CraftBrambleBoots,
            recipeId = "recipe_bramble_boots",
            label = "BRAMBLE BOOTS",
            x = 28,
            color = Color3.fromRGB(142, 112, 84),
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
        marker.Shape = if definition.recipeId == "recipe_amber_charm"
            then Enum.PartType.Ball
            elseif definition.recipeId == "recipe_ironroot_hood" then Enum.PartType.Wedge
            else Enum.PartType.Block
        marker.Size = if definition.recipeId == "recipe_meadow_satchel"
            then Vector3.new(2.6, 1.7, 1.2)
            elseif definition.recipeId == "recipe_bramble_boots" then Vector3.new(
                2.2,
                1.2,
                1.8
            )
            else Vector3.new(1.8, 1.8, 1.8)
        marker.Material = Enum.Material.SmoothPlastic
        marker.Transparency = 0.06
        local markerLight = Instance.new("PointLight")
        markerLight.Color = definition.color
        markerLight.Brightness = 0.75
        markerLight.Range = 9
        markerLight.Parent = marker
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

    local archive = part(
        interactables,
        "GreenwardArchive",
        Vector3.new(9, 6, 1),
        CFrame.new(0, 3, -154),
        BARK,
        Enum.Material.WoodPlanks
    )
    addBillboard(archive, "GREENWARD ARCHIVE · FIELD BOOK", CREAM)
    self:_registerInteraction(
        archive,
        self._runtimeIds.InteractionIds.QuestBoard,
        self._runtimeIds.Actions.OpenFieldBook,
        "OPEN",
        "Field Book",
        nil
    )
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
        local world = self._world
        local deliveries = if world ~= nil then world:FindFirstChild("WayhomeDeliveries") else nil
        local delivery = if deliveries ~= nil
            then deliveries:FindFirstChild("WayhomeDelivery_" .. tostring(player.UserId))
            else nil
        if delivery ~= nil then
            delivery:Destroy()
        end
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

function WorldService.buildBarricade(self: WorldService, animated: boolean?)
    if self._barricadeBuilt then
        return
    end
    self._barricadeBuilt = true
    local world = assert(self._world, "world service has not initialized")
    local shouldAnimate = animated == true

    local prompt = self._interactions[self._runtimeIds.InteractionIds.Barricade]
    if prompt ~= nil then
        -- Tutorial progress is per player but this model is shared. Keep the
        -- prompt alive so a player still at `build` can submit their own
        -- action after somebody else constructed the server-wide barricade;
        -- HUDController hides it for every stage that no longer needs it.
        prompt.Enabled = true
        local target = prompt.Parent
        if target ~= nil and target:IsA("BasePart") then
            target.CanCollide = false
            target.CanQuery = true
            TweenService
                :Create(
                    target,
                    TweenInfo.new(if shouldAnimate then 0.35 else 0),
                    { Transparency = 1 }
                )
                :Play()
            local label = target:FindFirstChild("WorldLabel")
            if label ~= nil then
                label:Destroy()
            end
        end
    end

    for index = -4, 4 do
        local height = if index % 2 == 0 then 8 else 7
        local targetCFrame = CFrame.new(-20 + index * 1.8, height / 2, -88)
            * CFrame.Angles(0, 0, math.rad(index * 2))
        local stake = part(
            world,
            "BarricadeStake",
            Vector3.new(1.3, height, 1.3),
            if shouldAnimate then targetCFrame - Vector3.new(0, height + 1, 0) else targetCFrame,
            BARK,
            Enum.Material.WoodPlanks,
            not shouldAnimate
        )
        if shouldAnimate then
            stake.Transparency = 0.2
            task.delay((index + 4) * 0.055, function()
                if stake.Parent == nil then
                    return
                end
                TweenService
                    :Create(
                        stake,
                        TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                        { CFrame = targetCFrame, Transparency = 0 }
                    )
                    :Play()
                task.delay(0.36, function()
                    if stake.Parent ~= nil then
                        stake.CanCollide = true
                        stake.CanQuery = true
                        stake.CanTouch = true
                    end
                end)
            end)
        end
    end
    for level = 1, 2 do
        local targetCFrame = CFrame.new(-20, 2 + level * 2.2, -87.3)
            * CFrame.Angles(0, 0, math.rad(if level == 1 then 8 else -8))
        local brace = part(
            world,
            "BarricadeBrace",
            Vector3.new(18, 1, 1),
            if shouldAnimate then targetCFrame + Vector3.new(0, 0, 5) else targetCFrame,
            Color3.fromRGB(105, 69, 45),
            Enum.Material.WoodPlanks,
            not shouldAnimate
        )
        if shouldAnimate then
            brace.Transparency = 0.2
            task.delay(0.55 + level * 0.12, function()
                if brace.Parent == nil then
                    return
                end
                TweenService
                    :Create(
                        brace,
                        TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                        { CFrame = targetCFrame, Transparency = 0 }
                    )
                    :Play()
                task.delay(0.3, function()
                    if brace.Parent ~= nil then
                        brace.CanCollide = true
                        brace.CanQuery = true
                        brace.CanTouch = true
                    end
                end)
            end)
        end
    end

    if shouldAnimate then
        task.delay(0.9, function()
            if world.Parent == nil then
                return
            end
            local pulse = part(
                world,
                "BarricadeCompletePulse",
                Vector3.new(0.14, 4, 4),
                CFrame.new(-20, 0.18, -88) * CFrame.Angles(0, 0, math.rad(90)),
                AMBER,
                Enum.Material.Glass,
                false
            )
            pulse.Shape = Enum.PartType.Cylinder
            pulse.Transparency = 0.45
            pulse.CastShadow = false
            TweenService:Create(
                pulse,
                TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Size = Vector3.new(0.14, 20, 20), Transparency = 1 }
            ):Play()
            task.delay(0.55, function()
                if pulse.Parent ~= nil then
                    pulse:Destroy()
                end
            end)
        end)
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
    local becomingVisible = visible and beacon.Transparency >= 0.95
    TweenService:Create(
        beacon,
        TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Transparency = if visible then 0.16 else 1 }
    ):Play()
    beacon.CanQuery = visible
    local prompt = self._interactions[self._runtimeIds.InteractionIds.Beacon]
    if prompt ~= nil then
        prompt.Enabled = visible
    end
    local light = beacon:FindFirstChildOfClass("PointLight")
    if light == nil then
        light = Instance.new("PointLight")
        light.Color = beacon.Color
        light.Brightness = 2.2
        light.Range = 34
        light.Shadows = false
        light.Parent = beacon
    end
    light.Enabled = visible
    if visible and beacon:FindFirstChild("WorldLabel") == nil then
        addBillboard(beacon, "THE BRAMBLEWAKE REMEMBERS", CREAM)
    end

    local world = self._world
    if world ~= nil then
        for _, descendant in world:GetDescendants() do
            if descendant:IsA("BasePart") and descendant.Name == "DawnPathMarker" then
                TweenService
                    :Create(
                        descendant,
                        TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { Transparency = if visible then 0.12 else 1 }
                    )
                    :Play()
            end
        end
    end

    if becomingVisible then
        local pulse = part(
            assert(beacon.Parent, "beacon parent is missing"),
            "DawnRevealPulse",
            Vector3.new(0.16, 5, 5),
            CFrame.new(beacon.Position - Vector3.new(0, 5.95, 0))
                * CFrame.Angles(0, 0, math.rad(90)),
            FOXFIRE,
            Enum.Material.Neon,
            false
        )
        pulse.Shape = Enum.PartType.Cylinder
        pulse.Transparency = 0.16
        pulse.CastShadow = false
        TweenService:Create(
            pulse,
            TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = Vector3.new(0.16, 34, 34), Transparency = 1 }
        ):Play()
        task.delay(1.25, function()
            if pulse.Parent ~= nil then
                pulse:Destroy()
            end
        end)
    end
end

function WorldService.setLanternHealth(self: WorldService, health: number)
    local flame = self._lantern
    if flame == nil then
        return
    end
    local clamped = math.clamp(health, 0, 100)
    local previous = self._lanternVisualHealth
    self._lanternVisualHealth = clamped
    local strength = clamped / 100
    local danger = Color3.fromRGB(255, 104, 76)
    local targetColor = danger:Lerp(AMBER, strength)
    local targetSize = Vector3.new(1.8, 2.6, 1.8):Lerp(Vector3.new(3.4, 5, 3.4), strength)

    TweenService:Create(
        flame,
        TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Color = targetColor, Size = targetSize }
    ):Play()
    local light = flame:FindFirstChildOfClass("PointLight")
    if light ~= nil then
        TweenService
            :Create(light, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Brightness = 0.7 + strength * 2.3,
                Color = targetColor,
                Range = 18 + strength * 24,
            })
            :Play()
    end
    local world = self._world
    if world ~= nil then
        world:SetAttribute("FirstLanternHealth", clamped)
    end

    if math.abs(previous - clamped) < 1 then
        return
    end
    local pulse = part(
        assert(flame.Parent, "First Lantern parent is missing"),
        if clamped < previous then "LanternDamagePulse" else "LanternRepairPulse",
        targetSize,
        flame.CFrame,
        if clamped < previous then danger else FOXFIRE,
        Enum.Material.Glass,
        false
    )
    pulse.Shape = Enum.PartType.Ball
    pulse.Transparency = 0.58
    pulse.CastShadow = false
    TweenService:Create(
        pulse,
        TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = targetSize * 1.65, Transparency = 1 }
    ):Play()
    task.delay(0.5, function()
        if pulse.Parent ~= nil then
            pulse:Destroy()
        end
    end)
end

local function buildTownConsequenceLandscape(parent: Instance, consequence: any)
    local center = Vector3.new(52, 0, -112)
    local landscapeKind = tostring(consequence.landscapeKind or "seed_ground")
    local memorialKind = tostring(consequence.memorialKind or "unmarked_stone")
    local growthStage = math.clamp(math.floor(tonumber(consequence.growthStage) or 0), 0, 3)

    local ground = part(
        parent,
        "GreenwardGround",
        Vector3.new(34, 0.45, 30),
        CFrame.new(center + Vector3.new(0, 0.1, 0)),
        if landscapeKind == "cultivated_fields"
            then Color3.fromRGB(73, 58, 39)
            elseif landscapeKind == "living_grove" then Color3.fromRGB(38, 69, 43)
            else Color3.fromRGB(53, 68, 43),
        if landscapeKind == "cultivated_fields" then Enum.Material.Mud else Enum.Material.Ground,
        false
    )
    ground.CanQuery = false

    local borderColor = if landscapeKind == "living_grove" then MOSS else BARK
    for side = -1, 1, 2 do
        part(
            parent,
            "GreenwardBoundary",
            Vector3.new(1, 2.2, 30),
            CFrame.new(center + Vector3.new(side * 16.5, 1.1, 0)),
            borderColor,
            Enum.Material.Wood,
            false
        )
    end

    local function cropRow(x: number, z: number, accent: Color3)
        part(
            parent,
            "CultivatedBed",
            Vector3.new(6.6, 0.7, 8.5),
            CFrame.new(center + Vector3.new(x, 0.45, z)),
            Color3.fromRGB(92, 67, 42),
            Enum.Material.Ground,
            false
        )
        for cropIndex = -2, 2 do
            local stem = part(
                parent,
                "CropStem",
                Vector3.new(0.28, 1.25 + growthStage * 0.12, 0.28),
                CFrame.new(center + Vector3.new(x + cropIndex * 1.05, 1.15, z)),
                Color3.fromRGB(71, 123, 63),
                Enum.Material.Grass,
                false
            )
            stem.CanQuery = false
            local crop = part(
                parent,
                "HarvestCrop",
                Vector3.new(0.72, 0.72, 0.72),
                stem.CFrame + Vector3.new(0, 0.78, 0),
                accent,
                Enum.Material.SmoothPlastic,
                false
            )
            crop.Shape = Enum.PartType.Ball
            crop.CanQuery = false
        end
    end

    local function orchardTree(x: number, z: number, accent: Color3)
        local trunk = part(
            parent,
            "OrchardTrunk",
            Vector3.new(1.1, 5.5 + growthStage * 0.5, 1.1),
            CFrame.new(center + Vector3.new(x, 2.75, z)),
            BARK,
            Enum.Material.Wood,
            false
        )
        trunk.CanQuery = false
        local crown = part(
            parent,
            "OrchardCrown",
            Vector3.new(5.4 + growthStage * 0.4, 4.2, 5.4 + growthStage * 0.4),
            trunk.CFrame + Vector3.new(0, 4.15, 0),
            Color3.fromRGB(55, 103, 58),
            Enum.Material.Grass,
            false
        )
        crown.Shape = Enum.PartType.Ball
        crown.CanQuery = false
        for fruitIndex = -1, 1 do
            local fruit = part(
                parent,
                "OrchardFruit",
                Vector3.new(0.55, 0.55, 0.55),
                crown.CFrame + Vector3.new(fruitIndex * 1.25, -0.25, 2.1),
                accent,
                Enum.Material.SmoothPlastic,
                false
            )
            fruit.Shape = Enum.PartType.Ball
            fruit.CanQuery = false
        end
    end

    if landscapeKind == "cultivated_fields" then
        cropRow(-8.5, -5.2, Color3.fromRGB(205, 149, 72))
        cropRow(0, -5.2, Color3.fromRGB(169, 86, 58))
        cropRow(8.5, -5.2, Color3.fromRGB(220, 188, 90))
        cropRow(-8.5, 5.2, Color3.fromRGB(193, 118, 67))
        cropRow(0, 5.2, Color3.fromRGB(219, 178, 81))
        cropRow(8.5, 5.2, Color3.fromRGB(151, 92, 61))
        local trough = part(
            parent,
            "IrrigationTrough",
            Vector3.new(28, 0.55, 1.5),
            CFrame.new(center + Vector3.new(0, 0.45, 0)),
            Color3.fromRGB(72, 94, 94),
            Enum.Material.Glass,
            false
        )
        trough.Transparency = 0.18
    elseif landscapeKind == "living_grove" then
        for treeIndex, offset in
            {
                Vector3.new(-9, 0, -6),
                Vector3.new(0, 0, -3),
                Vector3.new(9, 0, -6),
                Vector3.new(-6, 0, 6),
                Vector3.new(7, 0, 6),
            }
        do
            orchardTree(offset.X, offset.Z, if treeIndex % 2 == 0 then FOXFIRE else AMBER)
        end
        for archIndex = -1, 1 do
            local archCenter = center + Vector3.new(archIndex * 10, 0, 10)
            for side = -1, 1, 2 do
                part(
                    parent,
                    "LivingRootArch",
                    Vector3.new(1.2, 7.5, 1.2),
                    CFrame.new(archCenter + Vector3.new(side * 3.1, 3.6, 0))
                        * CFrame.Angles(0, 0, math.rad(-side * 13)),
                    BARK,
                    Enum.Material.Wood,
                    false
                )
            end
            part(
                parent,
                "LivingRootCrown",
                Vector3.new(7, 1.1, 1.1),
                CFrame.new(archCenter + Vector3.new(0, 7.1, 0)),
                MOSS,
                Enum.Material.Wood,
                false
            )
        end
    elseif landscapeKind == "community_orchard" then
        cropRow(-9, -5.5, Color3.fromRGB(213, 157, 73))
        cropRow(9, -5.5, Color3.fromRGB(171, 94, 61))
        orchardTree(-9, 6, AMBER)
        orchardTree(0, 7.5, FOXFIRE)
        orchardTree(9, 6, AMBER)
        local tableTop = part(
            parent,
            "CommonsTable",
            Vector3.new(10, 0.55, 3.3),
            CFrame.new(center + Vector3.new(0, 2.5, -0.2)),
            Color3.fromRGB(102, 73, 47),
            Enum.Material.WoodPlanks,
            false
        )
        tableTop.CanQuery = false
        for side = -1, 1, 2 do
            part(
                parent,
                "CommonsBench",
                Vector3.new(10, 0.5, 1.3),
                CFrame.new(center + Vector3.new(0, 1.4, -0.2 + side * 3)),
                Color3.fromRGB(89, 63, 43),
                Enum.Material.WoodPlanks,
                false
            )
        end
    else
        for markerIndex = -2, 2 do
            local marker = part(
                parent,
                "SeedGroundMarker",
                Vector3.new(1.1, 0.55, 1.1),
                CFrame.new(center + Vector3.new(markerIndex * 4.5, 0.42, markerIndex % 2 * 3)),
                Color3.fromRGB(92, 98, 80),
                Enum.Material.Slate,
                false
            )
            marker.Shape = Enum.PartType.Ball
        end
    end

    local memorialCenter = center + Vector3.new(0, 0, 12)
    local plinth = part(
        parent,
        "WardenMemorialPlinth",
        Vector3.new(7.5, 1.2, 4.2),
        CFrame.new(memorialCenter + Vector3.new(0, 0.6, 0)),
        if memorialKind == "broken_antlers" then WET_BARK else Color3.fromRGB(76, 84, 79),
        if memorialKind == "living_antlers" then Enum.Material.Ground else Enum.Material.Slate,
        false
    )
    plinth.CanQuery = false
    local antlerColor = if memorialKind == "living_antlers"
        then Color3.fromRGB(92, 137, 77)
        elseif memorialKind == "broken_antlers" then Color3.fromRGB(45, 35, 32)
        else Color3.fromRGB(113, 106, 91)
    for side = -1, 1, 2 do
        local brokenSide = memorialKind == "broken_antlers" and side == 1
        local height = if brokenSide then 3.4 else 6.8
        part(
            parent,
            if brokenSide then "BrokenWardenAntler" else "WardenAntler",
            Vector3.new(0.7, height, 0.7),
            CFrame.new(memorialCenter + Vector3.new(side * 1.45, 1 + height * 0.5, 0))
                * CFrame.Angles(0, 0, math.rad(-side * 18)),
            antlerColor,
            Enum.Material.Wood,
            false
        )
        if not brokenSide and memorialKind ~= "unmarked_stone" then
            for tineIndex = 1, 2 do
                part(
                    parent,
                    "WardenAntlerTine",
                    Vector3.new(0.48, 2.8, 0.48),
                    CFrame.new(
                        memorialCenter
                            + Vector3.new(side * (2 + tineIndex * 0.65), 3.3 + tineIndex * 1.2, 0)
                    ) * CFrame.Angles(0, 0, math.rad(-side * 48)),
                    antlerColor,
                    Enum.Material.Wood,
                    false
                )
            end
        end
    end
    if memorialKind == "living_antlers" then
        local memoryLight = part(
            parent,
            "WardenMemoryLight",
            Vector3.new(1.1, 1.1, 1.1),
            CFrame.new(memorialCenter + Vector3.new(0, 5.8, 0)),
            FOXFIRE,
            Enum.Material.Glass,
            false
        )
        memoryLight.Shape = Enum.PartType.Ball
        memoryLight.Transparency = 0.14
        local glow = Instance.new("PointLight")
        glow.Color = FOXFIRE
        glow.Brightness = 0.75
        glow.Range = 11
        glow.Shadows = false
        glow.Parent = memoryLight
    elseif memorialKind == "scarred_antlers" then
        for scarIndex = -1, 1, 2 do
            local scar = part(
                parent,
                "WardenScar",
                Vector3.new(0.15, 1.9, 2.5),
                CFrame.new(memorialCenter + Vector3.new(scarIndex * 1.6, 1.25, -2.12))
                    * CFrame.Angles(0, 0, math.rad(scarIndex * 19)),
                Color3.fromRGB(187, 111, 65),
                Enum.Material.Neon,
                false
            )
            scar.Transparency = 0.22
        end
    end

    local sign = part(
        parent,
        "GreenwardConsequenceSign",
        Vector3.new(13, 3.2, 0.6),
        CFrame.new(center + Vector3.new(0, 4.2, -15.2)),
        BARK,
        Enum.Material.WoodPlanks,
        false
    )
    addBillboard(sign, string.format("TIER %d · %s", consequence.tier, consequence.title), CREAM)
    sign:SetAttribute("Consequence", consequence.detail)
    parent:SetAttribute("LandscapeKind", landscapeKind)
    parent:SetAttribute("MemorialKind", memorialKind)
    parent:SetAttribute("GrowthStage", growthStage)
end

local function buildTownProgressionBuildings(parent: Instance, consequence: any)
    local stages = if type(consequence.buildingStages) == "table"
        then consequence.buildingStages
        else {}

    local function stageFor(id: string): number
        return math.clamp(math.floor(tonumber(stages[id]) or 0), 0, 3)
    end

    local function constructionSite(id: string, displayName: string, center: Vector3, size: Vector3)
        local model = Instance.new("Model")
        model.Name = id
        model:SetAttribute("BuildingId", id)
        model:SetAttribute("BuildingStage", 0)
        model:SetAttribute("BuildingState", "construction")
        model.Parent = parent
        part(
            model,
            "StoneFooting",
            Vector3.new(size.X, 0.65, size.Z),
            CFrame.new(center + Vector3.new(0, 0.32, 0)),
            Color3.fromRGB(73, 76, 72),
            Enum.Material.Slate,
            false
        )
        for sideX = -1, 1, 2 do
            for sideZ = -1, 1, 2 do
                part(
                    model,
                    "ScaffoldPost",
                    Vector3.new(0.55, 7.5, 0.55),
                    CFrame.new(
                        center + Vector3.new(sideX * (size.X * 0.45), 3.9, sideZ * (size.Z * 0.42))
                    ),
                    Color3.fromRGB(94, 69, 46),
                    Enum.Material.Wood,
                    false
                )
            end
        end
        for sideZ = -1, 1, 2 do
            part(
                model,
                "ScaffoldRail",
                Vector3.new(size.X * 0.92, 0.4, 0.4),
                CFrame.new(center + Vector3.new(0, 5.7, sideZ * (size.Z * 0.42))),
                Color3.fromRGB(102, 75, 49),
                Enum.Material.Wood,
                false
            )
        end
        local tarp = part(
            model,
            "BuilderTarp",
            Vector3.new(size.X * 0.7, 0.16, size.Z * 0.62),
            CFrame.new(center + Vector3.new(0, 7.55, 0)) * CFrame.Angles(0, 0, math.rad(4)),
            Color3.fromRGB(105, 119, 91),
            Enum.Material.Fabric,
            false
        )
        tarp.Transparency = 0.08
        local sign = part(
            model,
            "ConstructionSign",
            Vector3.new(8.5, 2.2, 0.45),
            CFrame.new(center + Vector3.new(0, 2.5, -(size.Z * 0.5 + 0.5))),
            BARK,
            Enum.Material.WoodPlanks,
            false
        )
        addBillboard(sign, displayName .. " · PLANNED", CREAM)
        return model
    end

    local function buildingShell(
        id: string,
        displayName: string,
        center: Vector3,
        size: Vector3,
        stage: number,
        accent: Color3
    ): Model
        if stage == 0 then
            return constructionSite(id, displayName, center, size)
        end
        local model = Instance.new("Model")
        model.Name = id
        model:SetAttribute("BuildingId", id)
        model:SetAttribute("BuildingStage", stage)
        model:SetAttribute("BuildingState", if stage == 3 then "flourishing" else "complete")
        model.Parent = parent
        local wallHeight = 7.5 + stage * 0.75
        local halfX = size.X * 0.5
        local halfZ = size.Z * 0.5
        part(
            model,
            "Floor",
            Vector3.new(size.X, 0.55, size.Z),
            CFrame.new(center + Vector3.new(0, 0.28, 0)),
            Color3.fromRGB(83, 61, 42),
            Enum.Material.WoodPlanks
        )
        part(
            model,
            "BackWall",
            Vector3.new(size.X, wallHeight, 0.7),
            CFrame.new(center + Vector3.new(0, wallHeight * 0.5, halfZ - 0.35)),
            Color3.fromRGB(69, 48, 36),
            Enum.Material.WoodPlanks
        )
        for side = -1, 1, 2 do
            part(
                model,
                "SideWall",
                Vector3.new(0.7, wallHeight, size.Z),
                CFrame.new(center + Vector3.new(side * (halfX - 0.35), wallHeight * 0.5, 0)),
                Color3.fromRGB(69, 48, 36),
                Enum.Material.WoodPlanks
            )
            part(
                model,
                "FrontWall",
                Vector3.new((size.X - 5) * 0.5, wallHeight, 0.7),
                CFrame.new(
                    center
                        + Vector3.new(side * (halfX * 0.5 + 1.25), wallHeight * 0.5, -halfZ + 0.35)
                ),
                Color3.fromRGB(69, 48, 36),
                Enum.Material.WoodPlanks
            )
            local window = part(
                model,
                "Window",
                Vector3.new(0.18, 2.4, 2.8),
                CFrame.new(center + Vector3.new(side * (halfX - 0.72), 4.5, 1.6)),
                accent,
                Enum.Material.Glass,
                false
            )
            window.Transparency = 0.25
        end
        part(
            model,
            "DoorHeader",
            Vector3.new(5, 1.1, 0.85),
            CFrame.new(center + Vector3.new(0, wallHeight - 0.55, -halfZ + 0.3)),
            WET_BARK,
            Enum.Material.Wood
        )
        part(
            model,
            "Roof",
            Vector3.new(size.X + 2.2, 0.8, size.Z + 2.2),
            CFrame.new(center + Vector3.new(0, wallHeight + 0.65, 0))
                * CFrame.Angles(0, 0, math.rad(if stage >= 2 then 3 else 1)),
            if stage >= 2 then Color3.fromRGB(48, 55, 49) else Color3.fromRGB(59, 58, 51),
            Enum.Material.Slate
        )
        local sign = part(
            model,
            "BuildingSign",
            Vector3.new(8.8, 1.7, 0.38),
            CFrame.new(center + Vector3.new(0, wallHeight - 1.7, -halfZ - 0.18)),
            WET_BARK,
            Enum.Material.WoodPlanks,
            false
        )
        addBillboard(sign, displayName, accent)
        local lightAnchor = part(
            model,
            "WarmInterior",
            Vector3.new(0.25, 0.25, 0.25),
            CFrame.new(center + Vector3.new(0, 4.5, 1.5)),
            accent,
            Enum.Material.Neon,
            false
        )
        lightAnchor.Transparency = 1
        local light = Instance.new("PointLight")
        light.Color = accent
        light.Brightness = 0.55 + stage * 0.2
        light.Range = 12 + stage * 3
        light.Shadows = false
        light.Parent = lightAnchor
        if stage >= 2 then
            local awning = part(
                model,
                "FrontAwning",
                Vector3.new(10, 0.4, 4),
                CFrame.new(center + Vector3.new(0, wallHeight - 2.2, -halfZ - 2))
                    * CFrame.Angles(math.rad(-8), 0, 0),
                Color3.fromRGB(96, 105, 77),
                Enum.Material.Fabric,
                false
            )
            awning.Transparency = 0.04
        end
        if stage >= 3 then
            for side = -1, 1, 2 do
                local planter = part(
                    model,
                    "WindowPlanter",
                    Vector3.new(3.4, 0.7, 0.85),
                    CFrame.new(center + Vector3.new(side * (halfX + 0.15), 3, 1.6)),
                    Color3.fromRGB(91, 65, 43),
                    Enum.Material.WoodPlanks,
                    false
                )
                for flower = -1, 1 do
                    local bloom = part(
                        model,
                        "WindowBloom",
                        Vector3.new(0.5, 0.5, 0.5),
                        planter.CFrame + Vector3.new(0, 0.58, flower * 0.85),
                        if flower == 0 then accent else FOXFIRE,
                        Enum.Material.SmoothPlastic,
                        false
                    )
                    bloom.Shape = Enum.PartType.Ball
                end
            end
        end
        return model
    end

    local archiveStage = stageFor("building_archive")
    local archive = buildingShell(
        "building_archive",
        "MEMORY ARCHIVE",
        Vector3.new(-40, 0, -88),
        Vector3.new(17, 0, 14),
        archiveStage,
        FOXFIRE
    )
    if archiveStage > 0 then
        for shelf = -1, 1, 2 do
            part(
                archive,
                "ArchiveShelf",
                Vector3.new(4.8, 5.2, 0.75),
                CFrame.new(-40 + shelf * 5.3, 2.85, -83.1),
                Color3.fromRGB(85, 61, 42),
                Enum.Material.WoodPlanks,
                false
            )
        end
        for jarIndex = -2, 2 do
            local jar = part(
                archive,
                "ArchiveMemoryJar",
                Vector3.new(0.65, 0.9, 0.65),
                CFrame.new(-40 + jarIndex * 1.4, 1.1, -88),
                if jarIndex % 2 == 0 then FOXFIRE else AMBER,
                Enum.Material.Glass,
                false
            )
            jar.Shape = Enum.PartType.Ball
            jar.Transparency = 0.18
        end
    end

    local workbenchStage = stageFor("building_workbench")
    local workshop = buildingShell(
        "building_workbench",
        "LANTERN WORKBENCH",
        Vector3.new(39, 0, -87),
        Vector3.new(18, 0, 14),
        workbenchStage,
        AMBER
    )
    if workbenchStage > 0 then
        local bench = part(
            workshop,
            "CraftingBench",
            Vector3.new(8, 1.2, 3.2),
            CFrame.new(39, 1.3, -83.3),
            Color3.fromRGB(104, 73, 46),
            Enum.Material.WoodPlanks,
            false
        )
        for toolIndex = -1, 1 do
            part(
                workshop,
                "WorkbenchTool",
                Vector3.new(0.35, 2.4, 0.35),
                bench.CFrame + Vector3.new(toolIndex * 2.2, 1.65, 0),
                if toolIndex == 0 then Color3.fromRGB(141, 150, 153) else BARK,
                if toolIndex == 0 then Enum.Material.Metal else Enum.Material.Wood,
                false
            )
        end
    end

    local boardStage = stageFor("building_town_board")
    local boardModel = Instance.new("Model")
    boardModel.Name = "building_town_board"
    boardModel:SetAttribute("BuildingId", "building_town_board")
    boardModel:SetAttribute("BuildingStage", boardStage)
    boardModel:SetAttribute("BuildingState", "complete")
    boardModel.Parent = parent
    for side = -1, 1, 2 do
        part(
            boardModel,
            "TownBoardPost",
            Vector3.new(0.8, 7.2, 0.8),
            CFrame.new(12 + side * 5.2, 3.6, -86),
            WET_BARK,
            Enum.Material.Wood
        )
    end
    local board = part(
        boardModel,
        "TownBoard",
        Vector3.new(11.5, 5.5, 0.65),
        CFrame.new(12, 5.2, -86),
        Color3.fromRGB(90, 64, 42),
        Enum.Material.WoodPlanks,
        false
    )
    addBillboard(board, string.format("EMBERHOLLOW · TIER %d", consequence.tier or 0), CREAM)
    for notice = -1, 1 do
        local paper = part(
            boardModel,
            "TownNotice",
            Vector3.new(2.5, 2.1, 0.08),
            CFrame.new(12 + notice * 3.3, 4.6 + math.abs(notice) * 0.35, -86.38)
                * CFrame.Angles(0, 0, math.rad(notice * 4)),
            if notice == 0 then Color3.fromRGB(223, 205, 161) else Color3.fromRGB(184, 164, 126),
            Enum.Material.SmoothPlastic,
            false
        )
        paper.CastShadow = false
    end

    local innStage = stageFor("building_inn")
    local inn = buildingShell(
        "building_inn",
        "WAYFARER INN",
        Vector3.new(-40, 0, -132),
        Vector3.new(18, 0, 14),
        innStage,
        Color3.fromRGB(219, 151, 77)
    )
    if innStage > 0 then
        for side = -1, 1, 2 do
            part(
                inn,
                "InnTable",
                Vector3.new(4.5, 0.55, 3),
                CFrame.new(-40 + side * 5, 2.1, -128.5),
                Color3.fromRGB(100, 69, 45),
                Enum.Material.WoodPlanks,
                false
            )
        end
    end

    parent:SetAttribute("BuildingCount", 4)
    parent:SetAttribute("ArchiveStage", archiveStage)
    parent:SetAttribute("WorkbenchStage", workbenchStage)
    parent:SetAttribute("InnStage", innStage)
end

function WorldService.setTownConsequence(self: WorldService, consequence: any)
    self._townConsequence = consequence
    local world = self._world
    if world == nil or type(consequence) ~= "table" then
        return
    end
    local existing = world:FindFirstChild("GreenwardConsequence")
    if existing ~= nil then
        existing:Destroy()
    end
    local existingBuildings = world:FindFirstChild("TownProgressionBuildings")
    if existingBuildings ~= nil then
        existingBuildings:Destroy()
    end
    local landscape = Instance.new("Model")
    landscape.Name = "GreenwardConsequence"
    landscape.Parent = world
    buildTownConsequenceLandscape(landscape, consequence)
    local buildings = Instance.new("Model")
    buildings.Name = "TownProgressionBuildings"
    buildings.Parent = world
    buildTownProgressionBuildings(buildings, consequence)
    local visualPartCount = 0
    for _, descendant in landscape:GetDescendants() do
        if descendant:IsA("BasePart") then
            visualPartCount += 1
        end
    end
    landscape:SetAttribute("VisualPartCount", visualPartCount)
    world:SetAttribute("TownTier", consequence.tier)
    world:SetAttribute("TownDecision", tostring(consequence.decision or "unresolved"))
    world:SetAttribute("WardenOutcome", tostring(consequence.wardenOutcome or "unresolved"))
end

function WorldService.showExtractionPayoff(self: WorldService, player: Player, materials: any)
    local entries, total = self._extractionPayoff.summarize(materials)
    local world = self._world
    if world == nil or #entries == 0 or total <= 0 or player.Parent == nil then
        return
    end

    local deliveries = world:FindFirstChild("WayhomeDeliveries")
    if deliveries == nil then
        deliveries = Instance.new("Folder")
        deliveries.Name = "WayhomeDeliveries"
        deliveries.Parent = world
    end
    local deliveryName = "WayhomeDelivery_" .. tostring(player.UserId)
    local existing = deliveries:FindFirstChild(deliveryName)
    local existingSlot = if existing ~= nil then existing:GetAttribute("DeliverySlot") else nil
    if existing ~= nil then
        existing:Destroy()
    end

    local occupied: { [number]: boolean } = {}
    for _, candidate in deliveries:GetChildren() do
        local candidateSlot = candidate:GetAttribute("DeliverySlot")
        if type(candidateSlot) == "number" then
            occupied[candidateSlot] = true
        end
    end
    local slot = if type(existingSlot) == "number"
            and existingSlot >= 1
            and existingSlot <= #WAYHOME_DELIVERY_ORIGINS
        then existingSlot
        else self._extractionPayoff.firstAvailableSlot(occupied, #WAYHOME_DELIVERY_ORIGINS)
    if slot == nil then
        self._logger:info("wayhome_delivery_skipped", {
            player = player.UserId,
            reason = "delivery_slots_full",
        })
        return
    end

    local delivery = Instance.new("Model")
    delivery.Name = deliveryName
    delivery:SetAttribute("OwnerUserId", player.UserId)
    delivery:SetAttribute("MaterialCount", total)
    delivery:SetAttribute("DeliverySlot", slot)
    delivery.Parent = deliveries

    local origin = WAYHOME_DELIVERY_ORIGINS[slot]
    local pallet = part(
        delivery,
        "WayhomePallet",
        Vector3.new(7, 0.65, 5.5),
        CFrame.new(origin + Vector3.new(0, 0.34, 0)),
        Color3.fromRGB(91, 63, 43),
        Enum.Material.WoodPlanks,
        false
    )
    addBillboard(
        pallet,
        string.format(
            "%s · WAYHOME DELIVERY · %d",
            string.upper(string.sub(player.DisplayName, 1, 18)),
            total
        ),
        AMBER
    )

    local pieceIndex = 0
    local function animatePiece(piece: BasePart, targetCFrame: CFrame)
        pieceIndex += 1
        piece.CFrame = targetCFrame - Vector3.new(0, 4.5 + pieceIndex * 0.16, 0)
        task.delay(0.08 * pieceIndex, function()
            if piece.Parent ~= nil then
                TweenService
                    :Create(
                        piece,
                        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                        { CFrame = targetCFrame }
                    )
                    :Play()
            end
        end)
    end

    for entryIndex, entry in entries do
        local stackCount = math.min(3, math.max(1, math.ceil(entry.amount / 3)))
        for stackIndex = 1, stackCount do
            local row = entryIndex - 1
            local offset = Vector3.new(-2.4 + (stackIndex - 1) * 2.35, 1.2, -1.7 + row * 1.15)
            local targetCFrame = CFrame.new(origin + offset)
            local cargo: Part
            if entry.kind == "heartwood" then
                cargo = part(
                    delivery,
                    "HeartwoodLog",
                    Vector3.new(1.1, 3.6, 1.1),
                    targetCFrame * CFrame.Angles(0, 0, math.rad(90)),
                    BARK,
                    Enum.Material.Wood,
                    false
                )
                cargo.Shape = Enum.PartType.Cylinder
                targetCFrame = cargo.CFrame
            elseif entry.kind == "amber" then
                cargo = part(
                    delivery,
                    "AmberSapVial",
                    Vector3.new(1.25, 1.55, 1.25),
                    targetCFrame,
                    AMBER,
                    Enum.Material.Glass,
                    false
                )
                cargo.Shape = Enum.PartType.Ball
                cargo.Transparency = 0.12
                if stackIndex == 1 then
                    local cargoLight = Instance.new("PointLight")
                    cargoLight.Color = AMBER
                    cargoLight.Brightness = 0.8
                    cargoLight.Range = 9
                    cargoLight.Shadows = false
                    cargoLight.Parent = cargo
                end
            elseif entry.kind == "brightcap" then
                cargo = part(
                    delivery,
                    "Brightcap",
                    Vector3.new(1.8, 0.85, 1.8),
                    targetCFrame + Vector3.new(0, 0.65, 0),
                    FOXFIRE,
                    Enum.Material.Neon,
                    false
                )
                cargo.Shape = Enum.PartType.Ball
                targetCFrame = cargo.CFrame
                local stem = part(
                    delivery,
                    "BrightcapStem",
                    Vector3.new(0.55, 1.3, 0.55),
                    targetCFrame - Vector3.new(0, 0.8, 0),
                    CREAM,
                    Enum.Material.Wood,
                    false
                )
                animatePiece(stem, stem.CFrame)
            elseif entry.kind == "fiber" then
                cargo = part(
                    delivery,
                    "MeadowFiberBundle",
                    Vector3.new(1.5, 1.1, 2.4),
                    targetCFrame * CFrame.Angles(0, 0, math.rad(12)),
                    Color3.fromRGB(169, 139, 67),
                    Enum.Material.Fabric,
                    false
                )
                targetCFrame = cargo.CFrame
            else
                cargo = part(
                    delivery,
                    "SpringClayBundle",
                    Vector3.new(1.6, 1.35, 1.6),
                    targetCFrame,
                    Color3.fromRGB(133, 91, 72),
                    Enum.Material.Ground,
                    false
                )
                cargo.Shape = Enum.PartType.Ball
            end
            cargo:SetAttribute("MaterialId", entry.id)
            cargo:SetAttribute("Amount", entry.amount)
            animatePiece(cargo, targetCFrame)
        end
    end

    local pulse = part(
        delivery,
        "WayhomeDeliveryPulse",
        Vector3.new(0.14, 3, 3),
        CFrame.new(origin + Vector3.new(0, 0.16, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        FOXFIRE,
        Enum.Material.Glass,
        false
    )
    pulse.Shape = Enum.PartType.Cylinder
    pulse.Transparency = 0.38
    pulse.CastShadow = false
    TweenService:Create(
        pulse,
        TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = Vector3.new(0.14, 13, 13), Transparency = 1 }
    ):Play()
    task.delay(WAYHOME_DELIVERY_LIFETIME, function()
        if delivery.Parent ~= nil then
            delivery:Destroy()
        end
    end)
    task.delay(1, function()
        if pulse.Parent ~= nil then
            pulse:Destroy()
        end
    end)
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
        local nextMarker = target:FindFirstChild("BlackoutNextMarker")
        if nodeId == state.nextNodeId and relay and not delivered then
            local marker = if nextMarker ~= nil and nextMarker:IsA("BillboardGui")
                then nextMarker
                else Instance.new("BillboardGui")
            marker.Name = "BlackoutNextMarker"
            marker.Adornee = target
            marker.AlwaysOnTop = true
            marker.LightInfluence = 0
            marker.Size = UDim2.fromOffset(150, 32)
            marker.StudsOffsetWorldSpace = Vector3.new(0, 4.8, 0)
            marker.MaxDistance = 70
            marker.Parent = target
            local markerText = marker:FindFirstChild("MarkerText")
            if markerText == nil or not markerText:IsA("TextLabel") then
                markerText = Instance.new("TextLabel")
                markerText.Name = "MarkerText"
                markerText.BackgroundColor3 = Color3.fromRGB(12, 31, 25)
                markerText.BackgroundTransparency = 0.08
                markerText.BorderSizePixel = 0
                markerText.Font = Enum.Font.GothamBold
                markerText.Size = UDim2.fromScale(1, 1)
                markerText.TextColor3 = Color3.fromRGB(172, 255, 205)
                markerText.TextSize = 13
                markerText.Text = "▼  NEXT ROOT"
                markerText.Parent = marker
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 8)
                corner.Parent = markerText
            end
        elseif nextMarker ~= nil then
            nextMarker:Destroy()
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
        -- Restore the current town phase; the cycle may have advanced while
        -- the Blackout owned shared Lighting.
        if self._dusk and not self._night then
            self:_applyDuskLighting()
        else
            self:_applyTownLighting(self._night)
        end
        return
    end
    Lighting.Brightness = 1.8
    Lighting.Ambient = Color3.fromRGB(48, 62, 72)
    Lighting.OutdoorAmbient = Color3.fromRGB(38, 52, 68)
    Lighting.ExposureCompensation = -0.05
    local color = if effect ~= nil and effect:IsA("ColorCorrectionEffect")
        then effect
        else Instance.new("ColorCorrectionEffect")
    color.Name = "LastLightBlackoutColor"
    color.Brightness = 0.04
    color.Contrast = 0.04
    color.Saturation = -0.05
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

function WorldService.exitBramblewake(
    self: WorldService,
    player: Player,
    onArrive: (() -> ())?
): boolean
    local character = player.Character
    if character == nil then
        return false
    end
    if player:GetAttribute("LastLightExpeditionTransition") == true then
        return false
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
        if player.Parent ~= nil and onArrive ~= nil then
            task.defer(onArrive)
        end
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

function WorldService._setDuskSignals(self: WorldService, visible: boolean)
    for _, signal in self._duskSignals do
        if signal.Parent ~= nil then
            TweenService
                :Create(
                    signal,
                    TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        Transparency = if visible
                            then tonumber(signal:GetAttribute("DuskTransparency")) or 0.1
                            else 1,
                    }
                )
                :Play()
        end
    end
end

local function nightThemeColor(theme: string?): Color3
    return if theme == "MIRETIDE"
        then Color3.fromRGB(90, 192, 170)
        elseif theme == "ROOTMOON" then Color3.fromRGB(174, 128, 205)
        elseif theme == "ASHEN VEIL" then Color3.fromRGB(218, 132, 91)
        else AMBER
end

function WorldService._setNightDefenseState(self: WorldService, state: string, theme: string?)
    local accent = if state == "breach" then Color3.fromRGB(255, 91, 58) else nightThemeColor(theme)
    for _, signal in self._nightDefenseSignals do
        if signal.Parent ~= nil then
            local role = signal:GetAttribute("SignalRole")
            local transparency = if state == "day"
                then 1
                elseif state == "dusk" then (if role == "fire" then 0.28 else 0.74)
                elseif state == "breach" then (if role == "fire" then 0.02 else 0.2)
                else (if role == "fire" then 0.1 else 0.46)
            signal.Color = accent
            TweenService:Create(
                signal,
                TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Transparency = transparency }
            ):Play()
            local signalLight = signal:FindFirstChild("WatchSignalLight")
            if signalLight ~= nil and signalLight:IsA("PointLight") then
                signalLight.Color = accent
                signalLight.Brightness = if state == "day"
                    then 0
                    elseif state == "dusk" then 0.8
                    elseif state == "breach" then 2.8
                    else 1.7
            end
        end
    end
    local world = self._world
    if world ~= nil then
        world:SetAttribute("NightDefenseState", state)
        world:SetAttribute("NightDefenseTheme", theme or "")
    end
end

function WorldService.signalNightWave(
    self: WorldService,
    enemyId: string?,
    wave: number?,
    theme: string?
)
    local world = self._world
    if world == nil or not self._night then
        return
    end
    local accent = nightThemeColor(theme)
    local start = Vector3.new(0, 0.34, -149)
    local finish = Vector3.new(0, 0.34, -116)
    local lane = part(
        world,
        "NightWaveApproach",
        Vector3.new(10, 0.16, (finish - start).Magnitude),
        CFrame.lookAt((start + finish) / 2, finish),
        accent,
        Enum.Material.Neon,
        false
    )
    lane.Transparency = 0.72
    lane.CastShadow = false
    lane:SetAttribute("EnemyId", enemyId or "unknown")
    lane:SetAttribute("Wave", wave or 0)
    local enemyLabel = string.upper(string.gsub(enemyId or "forest threat", "enemy_", ""))
    enemyLabel = string.gsub(enemyLabel, "_", " ")
    addBillboard(lane, string.format("WAVE %d · %s INBOUND", wave or 0, enemyLabel), accent)
    TweenService:Create(
        lane,
        TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Transparency = 1, Size = Vector3.new(13, 0.16, lane.Size.Z) }
    ):Play()
    task.delay(1.3, function()
        if lane.Parent ~= nil then
            lane:Destroy()
        end
    end)
end

function WorldService.setTownBreach(self: WorldService, enabled: boolean, theme: string?)
    self._breachActive = enabled
    local world = self._world
    if world == nil then
        return
    end
    world:SetAttribute("TownBreachActive", enabled)
    self:_setNightDefenseState(
        if enabled then "breach" else (if self._night then "night" else "day"),
        theme
    )
    if not enabled then
        return
    end
    local accent = Color3.fromRGB(255, 91, 58)
    for _, center in { Vector3.new(0, 0.4, -148), Vector3.new(0, 0.4, -112) } do
        local pulse = part(
            world,
            "TownBreachPulse",
            Vector3.new(0.14, 4, 4),
            CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)),
            accent,
            Enum.Material.Glass,
            false
        )
        pulse.Shape = Enum.PartType.Cylinder
        pulse.Transparency = 0.28
        pulse.CastShadow = false
        TweenService:Create(
            pulse,
            TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = Vector3.new(0.14, 25, 25), Transparency = 1 }
        ):Play()
        task.delay(1, function()
            if pulse.Parent ~= nil then
                pulse:Destroy()
            end
        end)
    end
end

function WorldService._applyDuskLighting(_self: WorldService)
    Lighting.ClockTime = 18.15
    Lighting.Brightness = 1.42
    Lighting.Ambient = Color3.fromRGB(49, 46, 52)
    Lighting.OutdoorAmbient = Color3.fromRGB(72, 61, 65)
    Lighting.ExposureCompensation = -0.36
    local atmosphere = Lighting:FindFirstChild("LastLightAtmosphere")
    if atmosphere ~= nil and atmosphere:IsA("Atmosphere") then
        atmosphere.Color = Color3.fromRGB(164, 143, 133)
        atmosphere.Decay = Color3.fromRGB(42, 42, 54)
        atmosphere.Density = 0.4
        atmosphere.Haze = 2.15
        atmosphere.Glare = 0.13
    end
    local tone = Lighting:FindFirstChild("LastLightTone")
    if tone ~= nil and tone:IsA("ColorCorrectionEffect") then
        tone.Brightness = -0.05
        tone.Contrast = 0.28
        tone.Saturation = -0.08
        tone.TintColor = Color3.fromRGB(237, 205, 188)
    end
    local bloom = Lighting:FindFirstChild("LastLightBloom")
    if bloom ~= nil and bloom:IsA("BloomEffect") then
        bloom.Intensity = 0.4
        bloom.Threshold = 0.78
    end
end

function WorldService.setDusk(self: WorldService, enabled: boolean)
    self._dusk = enabled
    self:_setDuskSignals(enabled)
    self:_setNightDefenseState(if enabled then "dusk" else "day", nil)
    if self._blackoutLightingActive or self._night then
        return
    end
    if enabled then
        self:_applyDuskLighting()
    else
        self:_applyTownLighting(false)
    end
end

-- Raw property application shared by the cycle and Blackout restore path, so
-- day and night always return to the same authored values.
function WorldService._applyTownLighting(_self: WorldService, night: boolean)
    local atmosphere = Lighting:FindFirstChild("LastLightAtmosphere")
    local tone = Lighting:FindFirstChild("LastLightTone")
    local bloom = Lighting:FindFirstChild("LastLightBloom")
    local depth = Lighting:FindFirstChild("LastLightDepth")

    if night then
        Lighting.ClockTime = 0.15
        Lighting.Brightness = 0.82
        Lighting.Ambient = NIGHT_AMBIENT
        Lighting.OutdoorAmbient = Color3.fromRGB(18, 27, 47)
        Lighting.ExposureCompensation = -0.62
        if atmosphere ~= nil and atmosphere:IsA("Atmosphere") then
            atmosphere.Color = Color3.fromRGB(82, 106, 126)
            atmosphere.Decay = Color3.fromRGB(12, 18, 36)
            atmosphere.Density = 0.48
            atmosphere.Haze = 2.35
            atmosphere.Glare = 0.08
        end
        if tone ~= nil and tone:IsA("ColorCorrectionEffect") then
            tone.Brightness = -0.08
            tone.Contrast = 0.32
            tone.Saturation = -0.16
            tone.TintColor = Color3.fromRGB(183, 205, 231)
        end
        if bloom ~= nil and bloom:IsA("BloomEffect") then
            bloom.Intensity = 0.48
            bloom.Threshold = 0.72
        end
        if depth ~= nil and depth:IsA("DepthOfFieldEffect") then
            depth.FarIntensity = 0.34
            depth.FocusDistance = 72
        end
    else
        Lighting.ClockTime = 6.65
        Lighting.Brightness = 2.05
        Lighting.Ambient = DAY_AMBIENT
        Lighting.OutdoorAmbient = Color3.fromRGB(72, 91, 84)
        Lighting.ExposureCompensation = -0.18
        if atmosphere ~= nil and atmosphere:IsA("Atmosphere") then
            atmosphere.Color = Color3.fromRGB(166, 185, 174)
            atmosphere.Decay = Color3.fromRGB(43, 63, 61)
            atmosphere.Density = 0.34
            atmosphere.Haze = 1.9
            atmosphere.Glare = 0.2
        end
        if tone ~= nil and tone:IsA("ColorCorrectionEffect") then
            tone.Brightness = -0.03
            tone.Contrast = 0.24
            tone.Saturation = -0.04
            tone.TintColor = Color3.fromRGB(232, 238, 224)
        end
        if bloom ~= nil and bloom:IsA("BloomEffect") then
            bloom.Intensity = 0.34
            bloom.Threshold = 0.82
        end
        if depth ~= nil and depth:IsA("DepthOfFieldEffect") then
            depth.FarIntensity = 0.28
            depth.FocusDistance = 95
        end
    end
end

function WorldService.setNight(self: WorldService, enabled: boolean, theme: string?)
    self._night = enabled
    self._breachActive = false
    self:_setNightDefenseState(if enabled then "night" else "day", theme)
    if enabled then
        self._dusk = false
        self:_setDuskSignals(false)
    end
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
