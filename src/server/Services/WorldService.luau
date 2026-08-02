--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local BramblewakeBuilder = require(script.Parent.Parent.World.BramblewakeBuilder)
local FoliageBuilder = require(script.Parent.Parent.World.FoliageBuilder)
local MeshTemplateLoader = require(script.Parent.Parent.World.MeshTemplateLoader)
local TerrainBuilder = require(script.Parent.Parent.World.TerrainBuilder)
local WorldSignBuilder = require(script.Parent.Parent.World.WorldSignBuilder)

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
        _townProgression: any,
        _professionAbilityVisuals: any,
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
        _nightThemeDressing: Model?,
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
        _townCondition: any,
        _townResidents: { [string]: any },
        _townIncidentModel: Model?,
        _engineerBraceModel: Model?,
        _meshTemplateLoader: MeshTemplateLoader.MeshTemplateLoader,
        _meshPlacements: { MeshPlacement },
    },
    WorldService
))

local DAY_AMBIENT = Color3.fromRGB(50, 63, 58)
local NIGHT_AMBIENT = Color3.fromRGB(13, 18, 33)
local AMBER = Color3.fromRGB(255, 181, 76)
local FOXFIRE = Color3.fromRGB(94, 206, 176)
local CREAM = Color3.fromRGB(244, 230, 197)
-- GREEN lived here for the old pine() canopy. That generator is gone; the same
-- value now reaches the forest as FOLIAGE_TONE.needle below.
local DARK_GREEN = Color3.fromRGB(18, 42, 32)
local BARK = Color3.fromRGB(62, 39, 30)
local WET_BARK = Color3.fromRGB(36, 26, 24)
local MOSS = Color3.fromRGB(58, 91, 54)
local WET_EARTH = Color3.fromRGB(67, 55, 39)
local HEARTWOOD_CENTER = Vector3.new(38, 0, -48)
local TOOL_YARD_CENTER = Vector3.new(-42, 0, -68)
local BARRICADE_CENTER = Vector3.new(-44, 0, -92)
-- Shared palette for the generated forest. Kept next to the existing colour
-- anchors so the treeline and the town read as the same world.
local FOLIAGE_TONE: FoliageBuilder.Tone = {
    bark = Color3.fromRGB(62, 39, 30),
    barkWet = Color3.fromRGB(36, 26, 24),
    needle = Color3.fromRGB(42, 77, 51),
    needleDeep = Color3.fromRGB(18, 42, 32),
    leaf = Color3.fromRGB(58, 91, 54),
    leafPale = Color3.fromRGB(112, 128, 79),
    moss = Color3.fromRGB(58, 91, 54),
    stone = Color3.fromRGB(75, 83, 79),
    stoneWarm = Color3.fromRGB(88, 84, 74),
}

type MeshPlacement = {
    assetId: string,
    fallbackKind: string,
    position: Vector3,
    scale: number,
    yaw: number,
    seed: number,
    swayTag: string?,
    parent: Instance?,
    fallbackInstance: Instance?,
    profileScale: Vector3?,
}

local function authoredPlacementTransform(placement: MeshPlacement): (CFrame, Vector3)
    local random = Random.new(placement.seed * 97 + 31)
    local pitch = 0
    local roll = 0
    local profileScale = placement.profileScale or Vector3.one

    -- Repeated organic assets keep the same measured mesh and collision-free
    -- template, but no two placements present the same upright silhouette.
    -- Buildings remain level so their doors, rotor, and fallback shells align.
    if placement.fallbackKind == "conifer" or placement.fallbackKind == "broadleaf" then
        pitch = random:NextNumber(math.rad(-6.5), math.rad(6.5))
        roll = random:NextNumber(math.rad(-7.5), math.rad(7.5))
        profileScale = Vector3.new(
            random:NextNumber(0.84, 1.16),
            random:NextNumber(0.92, 1.1),
            random:NextNumber(0.84, 1.16)
        )
    elseif placement.fallbackKind == "boulders" then
        pitch = random:NextNumber(math.rad(-4), math.rad(4))
        roll = random:NextNumber(math.rad(-4), math.rad(4))
        profileScale = Vector3.new(
            random:NextNumber(0.82, 1.18),
            random:NextNumber(0.88, 1.08),
            random:NextNumber(0.82, 1.18)
        )
    elseif placement.fallbackKind == "deadfall" then
        pitch = random:NextNumber(math.rad(-2.5), math.rad(2.5))
        roll = random:NextNumber(math.rad(-3.5), math.rad(3.5))
        profileScale = Vector3.new(
            random:NextNumber(0.88, 1.12),
            random:NextNumber(0.9, 1.08),
            random:NextNumber(0.82, 1.18)
        )
    elseif placement.fallbackKind == "undergrowth" then
        pitch = random:NextNumber(math.rad(-5), math.rad(5))
        roll = random:NextNumber(math.rad(-5), math.rad(5))
        profileScale = Vector3.new(
            random:NextNumber(0.82, 1.18),
            random:NextNumber(0.88, 1.12),
            random:NextNumber(0.82, 1.18)
        )
    elseif
        placement.assetId == "mesh_lantern_post_a"
        or placement.assetId == "mesh_creator_street_lantern_a"
    then
        pitch = random:NextNumber(math.rad(-2.5), math.rad(2.5))
        roll = random:NextNumber(math.rad(-3), math.rad(3))
    end

    return CFrame.new(placement.position) * CFrame.Angles(pitch, placement.yaw, roll), profileScale
end

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

local function labelSign(parent: Instance, at: CFrame, text: string): Model
    return WorldSignBuilder.createDirectionSign(parent, "TrailSign", at, text, CREAM)
end

local function queueRoadAssetPlacements(
    placements: { MeshPlacement },
    parent: Instance,
    startPosition: Vector3,
    finishPosition: Vector3,
    seedBase: number
)
    local delta = finishPosition - startPosition
    local distance = delta.Magnitude
    local direction = delta.Unit
    local count = math.max(1, math.ceil(distance / 42))
    local chunkLength = distance / count
    local yaw = math.atan2(-direction.X, -direction.Z)
    for index = 1, count do
        local alpha = (index - 0.5) / count
        local position = startPosition:Lerp(finishPosition, alpha)
        table.insert(placements, {
            assetId = "mesh_creator_road_stones_a",
            fallbackKind = "asset_dressing",
            position = Vector3.new(position.X, 0.92, position.Z),
            scale = 1,
            yaw = yaw,
            seed = seedBase + index,
            swayTag = nil,
            parent = parent,
            fallbackInstance = nil,
            profileScale = Vector3.new(1, 1, chunkLength / 18),
        })
    end
end

local function buildEmberhollowSanctuary(
    parent: Instance,
    meshPlacements: { MeshPlacement }
): { Instance }
    local courtyard = Vector3.new(0, 0, -112)
    local courtyardPatch = part(
        parent,
        "EmberhollowCourtyard",
        Vector3.new(92, 0.3, 62),
        CFrame.new(courtyard + Vector3.new(0, 0.18, 1)),
        Color3.fromRGB(53, 59, 45),
        Enum.Material.Ground,
        false
    )
    courtyardPatch.Transparency = 0.08

    -- This assembly follows the proven 65-part construction grammar from the
    -- supplied Place6 reference: raised foundation, segmented walls around real
    -- openings, four cross rafters, opposing roof wedges, framed windows, stairs,
    -- an open door, and a full-height stone chimney. Last Light owns the palette,
    -- props, dimensions, names, and lighting treatment.
    local function cabin(center: Vector3, yaw: number, name: string, accent: Color3): Instance
        local scale = 0.72
        center += Vector3.new(0, 2.2, 0)
        local cabinFrame = CFrame.new(center) * CFrame.Angles(0, yaw, 0)
        local cabinFolder = Instance.new("Folder")
        cabinFolder.Name = name
        cabinFolder.Parent = parent

        local shell = Instance.new("Folder")
        shell.Name = "ProceduralCabinShell"
        shell.Parent = cabinFolder

        local wallColor = if name == "MARA'S SHELTER"
            then Color3.fromRGB(69, 85, 66)
            else Color3.fromRGB(91, 63, 44)
        local trimColor = if name == "MARA'S SHELTER"
            then Color3.fromRGB(109, 126, 90)
            else Color3.fromRGB(137, 99, 61)
        local roofColor = Color3.fromRGB(48, 54, 49)
        local stoneColor = Color3.fromRGB(82, 84, 79)

        local function scaledSize(x: number, y: number, z: number): Vector3
            return Vector3.new(x * scale, y * scale, z * scale)
        end
        local function referenceCFrame(x: number, y: number, z: number): CFrame
            return cabinFrame * CFrame.new(x * scale, (y + 7.5) * scale + 0.25, z * scale)
        end
        local function cabinCFrame(x: number, y: number, z: number): CFrame
            return cabinFrame * CFrame.new(x, y, z)
        end
        local function referencePart(
            target: Instance,
            partName: string,
            dimensions: Vector3,
            x: number,
            y: number,
            z: number,
            color: Color3,
            material: Enum.Material,
            collidable: boolean?
        ): Part
            local created = part(
                target,
                partName,
                scaledSize(dimensions.X, dimensions.Y, dimensions.Z),
                referenceCFrame(x, y, z),
                color,
                material,
                collidable
            )
            if collidable == false then
                created.CanQuery = false
            end
            return created
        end

        referencePart(
            shell,
            "CabinFoundation",
            Vector3.new(36, 3, 24),
            0,
            -9.5,
            0,
            Color3.fromRGB(72, 76, 73),
            Enum.Material.Cobblestone
        )
        referencePart(
            shell,
            "CabinFloor",
            Vector3.new(34, 1, 22),
            0,
            -7.5,
            0,
            trimColor,
            Enum.Material.WoodPlanks
        )

        local wallPieces = {
            { 9, 9, 1, -13.5, -3.5, -11.5 },
            { 7, 5, 1, 0.5, -1.5, -11.5 },
            { 7, 5, 1, 14.5, -1.5, -11.5 },
            { 21, 4, 1, 7.5, -6, -11.5 },
            { 36, 6, 1, 0, 4, -11.5 },
            { 23, 8, 1, 6.5, -4, 11.5 },
            { 5, 8, 1, -15.5, -4, 11.5 },
            { 36, 7, 1, 0, 3.5, 11.5 },
        }
        for _, spec in wallPieces do
            referencePart(
                shell,
                "CabinWallPanel",
                Vector3.new(spec[1], spec[2], spec[3]),
                spec[4],
                spec[5],
                spec[6],
                wallColor,
                Enum.Material.WoodPlanks
            )
        end
        for side = -1, 1, 2 do
            for _, spec in
                {
                    { 1, 4, 22, -6, 0 },
                    { 1, 6, 22, 4, 0 },
                    { 1, 5, 7, -1.5, -7.5 },
                    { 1, 5, 8, -1.5, 7 },
                }
            do
                referencePart(
                    shell,
                    "CabinSideWallPanel",
                    Vector3.new(spec[1], spec[2], spec[3]),
                    side * 17.5,
                    spec[4],
                    spec[5],
                    wallColor,
                    Enum.Material.WoodPlanks
                )
            end
        end

        for _, z in { -7.5, -2.5, 2.5, 7.5 } do
            referencePart(
                shell,
                "CabinInteriorRafter",
                Vector3.new(34, 1, 1),
                0,
                6.5,
                z,
                WET_BARK,
                Enum.Material.Wood,
                false
            )
        end
        -- Thin pitched roof planes keep the gable readable. The previous pair
        -- of six-stud-thick wedges became two enormous dark slabs at player
        -- height and hid the walls, windows, doors, and the road behind them.
        for roofSide = -1, 1, 2 do
            local roof = referencePart(
                shell,
                "CabinRoofPlane",
                Vector3.new(36.5, 0.72, 13.5),
                0,
                9.65,
                roofSide * 5.65,
                roofColor,
                Enum.Material.Slate
            )
            roof.CFrame *= CFrame.Angles(math.rad(roofSide * 28), 0, 0)
            roof.CastShadow = true
            referencePart(
                shell,
                "CabinEaveBeam",
                Vector3.new(37, 0.75, 0.75),
                0,
                6.55,
                roofSide * 11.55,
                WET_BARK,
                Enum.Material.Wood,
                false
            )
        end
        referencePart(
            shell,
            "CabinRidgeBeam",
            Vector3.new(36.5, 0.8, 0.8),
            0,
            13,
            0,
            WET_BARK,
            Enum.Material.Wood,
            false
        )

        local function buildWindow(x: number, z: number, frontFacing: boolean)
            local window = referencePart(
                cabinFolder,
                "CabinWindowGlass",
                if frontFacing then Vector3.new(6.6, 4.6, 0.2) else Vector3.new(0.2, 4.6, 6.6),
                x,
                -1.5,
                z,
                Color3.fromRGB(118, 156, 157),
                Enum.Material.Glass,
                false
            )
            window.Transparency = 0.48
            if frontFacing then
                for frameY = -3.9, 0.9, 4.8 do
                    referencePart(
                        cabinFolder,
                        "CabinWindowFrame",
                        Vector3.new(7, 0.28, 0.72),
                        x,
                        frameY,
                        z - 0.1,
                        trimColor,
                        Enum.Material.Wood,
                        false
                    )
                end
                referencePart(
                    cabinFolder,
                    "CabinWindowMullion",
                    Vector3.new(0.28, 4.6, 0.72),
                    x,
                    -1.5,
                    z - 0.1,
                    trimColor,
                    Enum.Material.Wood,
                    false
                )
            else
                for frameY = -3.9, 0.9, 4.8 do
                    referencePart(
                        cabinFolder,
                        "CabinWindowFrame",
                        Vector3.new(0.72, 0.28, 7),
                        x,
                        frameY,
                        z,
                        trimColor,
                        Enum.Material.Wood,
                        false
                    )
                end
                referencePart(
                    cabinFolder,
                    "CabinWindowMullion",
                    Vector3.new(0.72, 4.6, 0.28),
                    x,
                    -1.5,
                    z,
                    trimColor,
                    Enum.Material.Wood,
                    false
                )
            end
        end
        buildWindow(7.5, -11.6, true)
        buildWindow(-17.6, -0.5, false)
        buildWindow(17.6, -0.5, false)

        for doorX in { -9.2, -3.2 } do
            referencePart(
                cabinFolder,
                "CabinDoorFrame",
                Vector3.new(0.65, 8.5, 0.7),
                doorX,
                -3,
                -11.7,
                trimColor,
                Enum.Material.Wood,
                false
            )
        end
        referencePart(
            cabinFolder,
            "CabinDoorHeader",
            Vector3.new(6.7, 0.65, 0.7),
            -6.2,
            1.25,
            -11.7,
            trimColor,
            Enum.Material.Wood,
            false
        )
        local hinge = referenceCFrame(-9.0, -3, -11.8)
        local openDoor = part(
            cabinFolder,
            "CabinOpenDoor",
            scaledSize(5.2, 8, 0.6),
            hinge * CFrame.Angles(0, math.rad(68), 0) * CFrame.new(2.6 * scale, 0, 0),
            trimColor,
            Enum.Material.WoodPlanks,
            false
        )
        openDoor.CanQuery = false
        part(
            cabinFolder,
            "CabinDoorBrace",
            scaledSize(4.4, 0.45, 0.24),
            openDoor.CFrame * CFrame.Angles(0, 0, math.rad(28)),
            WET_BARK,
            Enum.Material.Wood,
            false
        )
        local handle = part(
            cabinFolder,
            "CabinDoorHandle",
            scaledSize(0.45, 0.45, 0.45),
            openDoor.CFrame * CFrame.new(1.7 * scale, -0.7 * scale, -0.5 * scale),
            Color3.fromRGB(111, 114, 108),
            Enum.Material.Metal,
            false
        )
        handle.Shape = Enum.PartType.Ball

        for stepIndex = 1, 4 do
            referencePart(
                shell,
                "CabinStep",
                Vector3.new(6, 1, 1 + stepIndex),
                -6,
                -7.5 - stepIndex,
                -12.5 - stepIndex * 0.5,
                Color3.fromRGB(88, 91, 86),
                Enum.Material.Cobblestone
            )
        end

        local fireplace = Instance.new("Model")
        fireplace.Name = "CabinFireplace"
        fireplace.Parent = cabinFolder
        local hearthFallback = Instance.new("Model")
        hearthFallback.Name = "CabinHearthFallback"
        hearthFallback.Parent = fireplace
        local fireplaceParts = {
            { "CabinHearth", 8, 2, 2, -9, -6, 10 },
            { "CabinHearthSide", 1, 7, 1, -12.5, -4.5, 11.5 },
            { "CabinHearthSide", 1, 7, 1, -5.5, -4.5, 11.5 },
            { "CabinHearthLintel", 8, 1, 2, -9, -0.5, 11 },
            { "CabinChimneyBack", 8, 11, 1, -9, -5.5, 14.5 },
            { "CabinChimneySide", 1, 11, 2, -12.5, -5.5, 13 },
            { "CabinChimneySide", 1, 11, 2, -5.5, -5.5, 13 },
            { "CabinChimneyStack", 4, 12, 1, -9, 6, 12.5 },
            { "CabinChimneyStack", 4, 12, 1, -9, 6, 14.5 },
            { "CabinChimneyStack", 1, 12, 1, -10.5, 6, 13.5 },
            { "CabinChimneyStack", 1, 12, 1, -7.5, 6, 13.5 },
            { "CabinChimneyCap", 5, 0.7, 2.2, -9, 12.2, 13.5 },
        }
        for _, spec in fireplaceParts do
            referencePart(
                fireplace,
                spec[1],
                Vector3.new(spec[2], spec[3], spec[4]),
                spec[5],
                spec[6],
                spec[7],
                stoneColor,
                Enum.Material.Cobblestone,
                false
            )
        end
        referencePart(
            fireplace,
            "CabinAshBed",
            Vector3.new(6, 0.5, 3),
            -9,
            -5.5,
            12.5,
            Color3.fromRGB(45, 47, 46),
            Enum.Material.Slate,
            false
        )
        referencePart(
            hearthFallback,
            "CabinBurningWood",
            Vector3.new(4, 0.65, 0.7),
            -9,
            -4.7,
            12.5,
            WET_BARK,
            Enum.Material.Wood,
            false
        )
        local hearthFire = referencePart(
            hearthFallback,
            "CabinHearthFire",
            Vector3.new(0.75, 1.7, 0.7),
            -9,
            -3.55,
            12.2,
            accent,
            Enum.Material.Neon,
            false
        )
        hearthFire.Shape = Enum.PartType.Wedge
        hearthFire.CFrame *= CFrame.Angles(0, math.rad(-18), 0)
        hearthFire.Transparency = 0.08
        local ember = referencePart(
            hearthFallback,
            "CabinHearthEmber",
            Vector3.new(0.48, 1.05, 0.5),
            -8.65,
            -3.85,
            12.05,
            Color3.fromRGB(255, 104, 48),
            Enum.Material.Neon,
            false
        )
        ember.Shape = Enum.PartType.Wedge
        ember.CFrame *= CFrame.Angles(0, math.rad(28), math.rad(-7))
        local hearthLight = Instance.new("PointLight")
        hearthLight.Color = accent
        hearthLight.Brightness = 0.45
        hearthLight.Range = 8
        hearthLight.Shadows = true
        hearthLight.Parent = hearthFire
        CollectionService:AddTag(hearthFire, "LastLightAmbientLight")
        table.insert(meshPlacements, {
            assetId = "mesh_creator_campfire_a",
            fallbackKind = "placeholder",
            position = referenceCFrame(-9, -4.6, 12.2).Position,
            scale = 0.86,
            yaw = yaw,
            seed = if name == "MARA'S SHELTER" then 9311 else 9312,
            swayTag = nil,
            parent = fireplace,
            fallbackInstance = hearthFallback,
        })

        local windowLight = Instance.new("PointLight")
        windowLight.Color = accent
        windowLight.Brightness = 0.22
        windowLight.Range = 10
        windowLight.Shadows = false
        local lightAnchor = part(
            cabinFolder,
            "CabinLight",
            Vector3.new(0.2, 0.2, 0.2),
            cabinCFrame(0, 5.4, 2.8),
            accent,
            Enum.Material.Glass,
            false
        )
        lightAnchor.Transparency = 1
        windowLight.Parent = lightAnchor
        local sign = part(
            cabinFolder,
            "CabinSign",
            Vector3.new(6.4, 1.25, 0.35),
            referenceCFrame(6, 3.3, -12.1),
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
                cabinCFrame(4.2, 1.0, 3.5),
                Color3.fromRGB(96, 112, 83),
                Enum.Material.Fabric,
                false
            )
            cot.CanQuery = false
            local tableTop = part(
                cabinFolder,
                "MaraWorkTable",
                Vector3.new(4.2, 0.45, 2.5),
                cabinCFrame(4.5, 2.15, -3.2),
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
                    cabinCFrame(4.5 + jarIndex * 1.1, 2.9, -3.2),
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
                    cabinCFrame(3.5 + bedIndex * 3.6, 0.95, 3.8),
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
                cabinCFrame(5.2, 1.2, -3.6),
                Color3.fromRGB(88, 61, 39),
                Enum.Material.WoodPlanks,
                false
            )
            trunk.CanQuery = false
        end

        local rug = part(
            cabinFolder,
            "CabinWovenRug",
            Vector3.new(6.4, 0.12, 3.4),
            cabinCFrame(2.5, 0.68, -0.1),
            if name == "MARA'S SHELTER"
                then Color3.fromRGB(70, 112, 102)
                else Color3.fromRGB(132, 88, 54),
            Enum.Material.Fabric,
            false
        )
        rug.CanQuery = false

        local shelf = part(
            cabinFolder,
            "CabinSupplyShelf",
            Vector3.new(4.8, 0.35, 1.15),
            cabinCFrame(4.5, 5.15, 7.5),
            Color3.fromRGB(92, 65, 43),
            Enum.Material.WoodPlanks,
            false
        )
        shelf.CanQuery = false
        for supplyIndex = -1, 1 do
            local supply = part(
                cabinFolder,
                if name == "MARA'S SHELTER" then "MaraHerbBundle" else "WayfarerSupply",
                Vector3.new(0.85, 1.05 + math.abs(supplyIndex) * 0.2, 0.75),
                shelf.CFrame + Vector3.new(supplyIndex * 1.35, 0.7, 0),
                if supplyIndex == 0 then accent else Color3.fromRGB(121, 96, 58),
                if name == "MARA'S SHELTER" then Enum.Material.Grass else Enum.Material.Fabric,
                false
            )
            supply.CanQuery = false
        end

        local stoolSeat = part(
            cabinFolder,
            "CabinStoolSeat",
            Vector3.new(2.1, 0.35, 2.1),
            cabinCFrame(5.2, 1.9, 0.3),
            Color3.fromRGB(91, 64, 42),
            Enum.Material.WoodPlanks,
            false
        )
        stoolSeat.CanQuery = false
        for legX = -1, 1, 2 do
            for legZ = -1, 1, 2 do
                part(
                    cabinFolder,
                    "CabinStoolLeg",
                    Vector3.new(0.28, 1.8, 0.28),
                    stoolSeat.CFrame * CFrame.new(legX * 0.72, -1.0, legZ * 0.72),
                    WET_BARK,
                    Enum.Material.Wood,
                    false
                )
            end
        end

        local woodpile = Instance.new("Model")
        woodpile.Name = "CabinWoodpile"
        woodpile.Parent = cabinFolder
        for logIndex = 1, 5 do
            local row = math.floor((logIndex - 1) / 3)
            part(
                woodpile,
                "SplitFirewood",
                Vector3.new(2.8, 0.65, 0.72),
                cabinCFrame(-14.5, -1.45 + row * 0.62, 2.5 + ((logIndex - 1) % 3) * 0.78)
                    * CFrame.Angles(0, math.rad(4 * logIndex), math.rad((logIndex % 2) * 5)),
                if logIndex % 2 == 0 then BARK else WET_BARK,
                Enum.Material.Wood,
                false
            )
        end
        table.insert(meshPlacements, {
            assetId = "mesh_creator_barrel_a",
            fallbackKind = "asset_replacement",
            position = cabinCFrame(-14.5, -1.75, 4).Position,
            scale = 1,
            yaw = yaw + math.rad(8),
            seed = if name == "MARA'S SHELTER" then 9821 else 9822,
            swayTag = nil,
            parent = cabinFolder,
            fallbackInstance = woodpile,
        })
        table.insert(meshPlacements, {
            assetId = "mesh_creator_crate_a",
            fallbackKind = "asset_dressing",
            position = cabinCFrame(13.8, -1.75, 4.4).Position,
            scale = 0.9,
            yaw = yaw + math.rad(-7),
            seed = if name == "MARA'S SHELTER" then 9823 else 9824,
            swayTag = nil,
            parent = cabinFolder,
            fallbackInstance = nil,
        })
        local physicalParts = 0
        for _, descendant in cabinFolder:GetDescendants() do
            if descendant:IsA("BasePart") then
                physicalParts += 1
            end
        end
        cabinFolder:SetAttribute("ConstructionPattern", "place6_reference_adapted")
        cabinFolder:SetAttribute("PhysicalPartCount", physicalParts)
        cabinFolder:SetAttribute("FacesMainStreet", true)
        cabinFolder:SetAttribute("TownYawDegrees", math.deg(yaw))
        return shell
    end

    local shells = {
        cabin(Vector3.new(-36, 0, -112), math.rad(-90), "WAYFARER CABIN", AMBER),
        cabin(Vector3.new(36, 0, -112), math.rad(90), "MARA'S SHELTER", FOXFIRE),
    }

    local commons = Instance.new("Model")
    commons.Name = "EmberhollowCampCommons"
    commons.Parent = parent
    local commonsCenter = Vector3.new(62, 0, -198)
    local commonsTable = part(
        commons,
        "CampCommonsTable",
        Vector3.new(10.5, 0.55, 3.6),
        CFrame.new(commonsCenter + Vector3.new(0, 2.5, 0)),
        Color3.fromRGB(96, 67, 44),
        Enum.Material.WoodPlanks,
        false
    )
    commonsTable.CanQuery = false
    for side = -1, 1, 2 do
        part(
            commons,
            "CampCommonsBench",
            Vector3.new(10, 0.48, 1.25),
            CFrame.new(commonsCenter + Vector3.new(0, 1.4, side * 3.2)),
            Color3.fromRGB(84, 60, 42),
            Enum.Material.WoodPlanks,
            false
        )
    end
    for legX = -1, 1, 2 do
        for legZ = -1, 1, 2 do
            part(
                commons,
                "CampCommonsTableLeg",
                Vector3.new(0.48, 2.2, 0.48),
                commonsTable.CFrame * CFrame.new(legX * 4.2, -1.28, legZ * 1.15),
                WET_BARK,
                Enum.Material.Wood,
                false
            )
        end
    end
    for supplyIndex = 1, 5 do
        local supply = part(
            commons,
            "CampMealSupply",
            Vector3.new(0.9, 0.7 + (supplyIndex % 2) * 0.35, 0.9),
            commonsTable.CFrame
                * CFrame.new(-3.4 + supplyIndex * 1.4, 0.72, (supplyIndex % 2 - 0.5) * 1.1),
            if supplyIndex % 3 == 0
                then AMBER
                elseif supplyIndex % 2 == 0 then Color3.fromRGB(124, 141, 77)
                else Color3.fromRGB(132, 94, 60),
            if supplyIndex % 3 == 0 then Enum.Material.Glass else Enum.Material.Fabric,
            false
        )
        supply.CanQuery = false
    end
    table.insert(meshPlacements, {
        assetId = "mesh_creator_picnic_table_a",
        fallbackKind = "asset_replacement",
        position = commonsCenter,
        scale = 1.15,
        yaw = math.rad(90),
        seed = 9830,
        swayTag = nil,
        parent = parent,
        fallbackInstance = commons,
    })

    local streetFoundation = part(
        parent,
        "TownMainStreetFoundation",
        Vector3.new(18, 0.34, 206),
        CFrame.new(0, 0.31, -102),
        Color3.fromRGB(72, 65, 53),
        Enum.Material.Cobblestone,
        false
    )
    streetFoundation.CanQuery = false
    local townStreet = part(
        parent,
        "TownMainStreet",
        Vector3.new(15.5, 0.32, 204),
        CFrame.new(0, 0.59, -102),
        Color3.fromRGB(126, 82, 45),
        Enum.Material.Ground,
        false
    )
    townStreet.CanQuery = false
    local streetWear = part(
        parent,
        "TownMainStreetWear",
        Vector3.new(5.4, 0.12, 202),
        CFrame.new(0, 0.81, -102),
        Color3.fromRGB(162, 116, 67),
        Enum.Material.Pebble,
        false
    )
    streetWear.CanQuery = false
    for rutSide = -1, 1, 2 do
        local rut = part(
            parent,
            "TownStreetRut",
            Vector3.new(0.68, 0.08, 200),
            CFrame.new(rutSide * 2.4, 0.89, -102),
            Color3.fromRGB(61, 43, 30),
            Enum.Material.Mud,
            false
        )
        rut.CanQuery = false
    end
    queueRoadAssetPlacements(
        meshPlacements,
        parent,
        Vector3.new(0, 0.92, 0),
        Vector3.new(0, 0.92, -204),
        9600
    )
    local function townSideRoad(start: Vector3, finish: Vector3)
        local delta = finish - start
        local frame = CFrame.lookAt((start + finish) / 2, finish)
        local base = part(
            parent,
            "TownDistrictRoadFoundation",
            Vector3.new(8.6, 0.26, delta.Magnitude + 1.2),
            frame,
            Color3.fromRGB(59, 57, 50),
            Enum.Material.Cobblestone,
            false
        )
        base.CanQuery = false
        local surface = part(
            parent,
            "TownDistrictRoad",
            Vector3.new(7.2, 0.24, delta.Magnitude + 0.8),
            frame * CFrame.new(0, 0.24, 0),
            Color3.fromRGB(126, 82, 45),
            Enum.Material.Ground,
            false
        )
        surface.CanQuery = false
        local wear = part(
            parent,
            "TownDistrictRoadWear",
            Vector3.new(2.6, 0.08, delta.Magnitude + 0.5),
            frame * CFrame.new(0, 0.41, 0),
            Color3.fromRGB(135, 99, 59),
            Enum.Material.Ground,
            false
        )
        wear.CanQuery = false
        queueRoadAssetPlacements(meshPlacements, parent, start, finish, 9700 + #meshPlacements)
    end
    townSideRoad(Vector3.new(0, 0.45, -144), Vector3.new(-80, 0.45, -144))
    townSideRoad(Vector3.new(0, 0.45, -126), Vector3.new(80, 0.45, -126))
    townSideRoad(Vector3.new(0, 0.45, -184), Vector3.new(-80, 0.45, -184))
    townSideRoad(Vector3.new(0, 0.45, -164), Vector3.new(80, 0.45, -164))
    townSideRoad(Vector3.new(0, 0.45, -198), Vector3.new(50, 0.45, -198))
    local square = part(
        parent,
        "FirstLanternTownSquare",
        Vector3.new(35, 0.56, 35),
        CFrame.new(courtyard + Vector3.new(0, 0.52, 0)),
        Color3.fromRGB(83, 64, 44),
        Enum.Material.Ground,
        false
    )
    square.CanQuery = false
    for _, pathSpec in
        {
            { Vector3.new(-10, 0.84, -113), Vector3.new(-27.5, 0.84, -116.5) },
            { Vector3.new(10, 0.84, -111), Vector3.new(27.5, 0.84, -107.5) },
        }
    do
        local start = pathSpec[1]
        local finish = pathSpec[2]
        local delta = finish - start
        local entryPath = part(
            parent,
            "CabinEntryPath",
            Vector3.new(6.5, 0.18, delta.Magnitude + 1),
            CFrame.lookAt((start + finish) / 2, finish),
            Color3.fromRGB(101, 76, 48),
            Enum.Material.Mud,
            false
        )
        entryPath.CanQuery = false
        queueRoadAssetPlacements(meshPlacements, parent, start, finish, 9800 + #meshPlacements)
    end

    for index = 1, 16 do
        local angle = (index / 16) * math.pi * 2
        local xDirection = math.cos(angle)
        local zDirection = math.sin(angle)
        -- Leave four obvious gates: north/south for the main street and
        -- east/west for the cabin paths. These stones are visual edging, not
        -- player collision.
        if math.abs(xDirection) > 0.28 and math.abs(zDirection) > 0.28 then
            local stone = part(
                parent,
                "TownSquareEdgeStone",
                Vector3.new(2.4, 0.75, 1.6),
                CFrame.new(courtyard + Vector3.new(xDirection * 16.3, 0.86, zDirection * 16.3))
                    * CFrame.Angles(0.08, angle, 0.12),
                Color3.fromRGB(78, 82, 74),
                Enum.Material.Slate,
                false
            )
            stone.Shape = Enum.PartType.Ball
        end
    end
    for side = -1, 1, 2 do
        local benchZ = if side < 0 then -100 else -124
        local bench = part(
            parent,
            "LanternBench",
            Vector3.new(7, 0.7, 1.6),
            CFrame.new(side * 19.5, 1.2, benchZ) * CFrame.Angles(0, math.rad(90), 0),
            Color3.fromRGB(91, 65, 45),
            Enum.Material.WoodPlanks
        )
        bench.CanQuery = false
        for leg = -1, 1, 2 do
            local support = part(
                parent,
                "LanternBenchLeg",
                Vector3.new(0.45, 1.2, 1.1),
                CFrame.new(side * 19.5, 0.6, benchZ + leg * 2.1),
                WET_BARK,
                Enum.Material.Wood,
                false
            )
            support.CanQuery = false
        end
    end
    local campSign = labelSign(
        parent,
        CFrame.new(0, 3.2, -95) * CFrame.Angles(0, math.pi, 0),
        "EMBERHOLLOW · SAFE CAMP"
    )
    table.insert(meshPlacements, {
        assetId = "mesh_creator_forest_sign_a",
        fallbackKind = "asset_replacement",
        position = Vector3.new(0, 0, -95),
        scale = 1.2,
        yaw = math.pi,
        seed = 9840,
        swayTag = nil,
        parent = parent,
        fallbackInstance = campSign,
    })
    return shells
end

local function lantern(
    parent: Instance,
    at: Vector3,
    scale: number,
    ambientLightTag: string?
): Model
    local model = Instance.new("Model")
    model.Name = "ProceduralLanternPost"
    model.Parent = parent
    local post = part(
        model,
        "LanternPost",
        Vector3.new(0.8 * scale, 7 * scale, 0.8 * scale),
        CFrame.new(at + Vector3.new(0, 3.5 * scale, 0)),
        BARK,
        Enum.Material.Wood
    )
    local arm = part(
        model,
        "LanternArm",
        Vector3.new(2.2 * scale, 0.34 * scale, 0.34 * scale),
        CFrame.new(at + Vector3.new(0.78 * scale, 6.65 * scale, 0))
            * CFrame.Angles(0, 0, math.rad(-8)),
        WET_BARK,
        Enum.Material.Wood,
        false
    )
    arm.CanQuery = false
    local lanternCenter = at + Vector3.new(1.65 * scale, 5.55 * scale, 0)
    local glass = part(
        model,
        "LanternGlass",
        Vector3.new(1.15 * scale, 1.55 * scale, 1.15 * scale),
        CFrame.new(lanternCenter),
        Color3.fromRGB(202, 156, 84),
        Enum.Material.Glass,
        false
    )
    glass.Transparency = 0.52
    for sideX = -1, 1, 2 do
        for sideZ = -1, 1, 2 do
            part(
                model,
                "LanternCageRail",
                Vector3.new(0.1 * scale, 1.9 * scale, 0.1 * scale),
                CFrame.new(
                    lanternCenter + Vector3.new(sideX * 0.62 * scale, 0, sideZ * 0.62 * scale)
                ) * CFrame.Angles(0, 0, math.rad(sideX * sideZ * 3)),
                Color3.fromRGB(45, 49, 53),
                Enum.Material.Metal,
                false
            )
        end
    end
    for capY = -1, 1, 2 do
        part(
            model,
            if capY < 0 then "LanternCageBase" else "LanternRainCap",
            Vector3.new(1.6 * scale, 0.22 * scale, 1.6 * scale),
            CFrame.new(lanternCenter + Vector3.new(0, capY * 1.02 * scale, 0))
                * CFrame.Angles(0, math.rad(12), 0),
            Color3.fromRGB(45, 49, 53),
            Enum.Material.Metal,
            false
        )
    end
    local glow = part(
        model,
        "LanternFlame",
        Vector3.new(0.48 * scale, 0.88 * scale, 0.42 * scale),
        CFrame.new(lanternCenter + Vector3.new(0, -0.12 * scale, 0))
            * CFrame.Angles(0, math.rad(18), 0),
        AMBER,
        Enum.Material.Neon,
        false
    )
    glow.Shape = Enum.PartType.Wedge
    glow.Transparency = 0.08
    local light = Instance.new("PointLight")
    light.Color = AMBER
    light.Brightness = 1.15
    light.Range = 17 * scale
    -- Keep the sanctuary's key lantern as the only strong shadow source. The
    -- route lights are guidance, not a second sun, which keeps mobile scenes
    -- readable and avoids a wall of competing shadows.
    light.Shadows = false
    light.Parent = glow
    if ambientLightTag ~= nil then
        CollectionService:AddTag(glow, ambientLightTag)
    end
    model.PrimaryPart = post
    return model
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

local function addBillboard(
    partInstance: BasePart,
    title: string,
    accent: Color3,
    maxDistance: number?
)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "WorldLabel"
    billboard.Adornee = partInstance
    billboard.AlwaysOnTop = false
    billboard.LightInfluence = 0.35
    billboard.Size = UDim2.fromOffset(165, 38)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)
    billboard.MaxDistance = maxDistance or 20
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

function WorldService.new(
    logger: Logger,
    extractionPayoff: any,
    townProgression: any,
    professionAbilityVisuals: any
): WorldService
    return setmetatable({
        Name = WorldService.Name,
        _logger = logger,
        _extractionPayoff = extractionPayoff,
        _townProgression = townProgression,
        _professionAbilityVisuals = professionAbilityVisuals,
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
        _nightThemeDressing = nil,
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
        _townCondition = { integrity = 100, damageLevel = 0, repairsRemaining = 0 },
        _townResidents = {},
        _townIncidentModel = nil,
        _engineerBraceModel = nil,
        _meshTemplateLoader = MeshTemplateLoader.new(logger),
        _meshPlacements = {},
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

    -- Distant terrain peaks (TerrainBuilder reaches WORLD_EXTENT = 1450 studs)
    -- were reported washing out to a pale white smear instead of reading as a
    -- ridgeline. Atmosphere applies aerial perspective: with Haze and Glare
    -- above 0, the distant hue transitions from Atmosphere.Color toward
    -- Atmosphere.Decay as fog accumulates with distance. There is no sightline
    -- in the supplied Place6 reference (a small enclosed camp) anywhere near
    -- 1450 studs to have exposed this: its own Atmosphere -- Density 0.225,
    -- Haze 1, Color (199, 199, 199) -- is close to Roblox's stock defaults and
    -- was never tested at range either.
    --
    -- Some fade-to-fog at that distance is correct and even desirable -- it is
    -- what makes far terrain read as *distant*. The bug is the fade targets:
    -- Color (166, 185, 174) and Decay (43, 63, 61) both sat pale/washed rather
    -- than a readable rock tone, so anything far enough to have faded toward
    -- them read as near-white. Both are now a darker, more saturated
    -- slate-blue, which keeps the same falloff behavior but fades distant
    -- peaks toward a moody ridgeline silhouette instead of a blown-out white
    -- one -- consistent with the style formula's "slate blue-gray stone" and
    -- "moon cyan: distance" anchors. Density and Haze are also both eased back
    -- so full fade happens further out, giving mid-distance terrain more room
    -- to read as rock before it starts blending away.
    --
    -- These daytime values are duplicated in _applyTownLighting's `else`
    -- branch, which re-runs this same Atmosphere on every day/dusk transition
    -- and overwrites whatever is set here. Change both together or the fix
    -- reverts the moment a day/night cycle turns over.
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "LastLightAtmosphere"
    atmosphere.Color = Color3.fromRGB(74, 89, 98)
    atmosphere.Decay = Color3.fromRGB(38, 52, 58)
    atmosphere.Density = 0.24
    atmosphere.Offset = 0.08
    atmosphere.Glare = 0.15
    atmosphere.Haze = 1.0
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

--[[
    Depth bands for the generated forest: near framing, regional mid-ground,
    distant silhouette. Density falls with distance because far trees only
    contribute silhouette, and spending parts on them is what pushes a mobile
    device over budget.
]]
local FOREST_BANDS = table.freeze({
    table.freeze({ inner = 64, outer = 168, count = 74, minScale = 0.85, maxScale = 1.5 }),
    table.freeze({ inner = 168, outer = 340, count = 86, minScale = 1.1, maxScale = 1.9 }),
    table.freeze({ inner = 340, outer = 620, count = 64, minScale = 1.5, maxScale = 2.6 }),
})

-- Trees are never planted inside this corridor around the walkable route.
local ROUTE_HALF_WIDTH = 26

--[[
    Authored structures the forest must not grow into, as {x, z, radius}.

    A corridor test alone is not enough: it only protects the walkable route,
    so band 1 (radius 64-168) could still drop a collidable trunk through the
    workshop roof, onto a mastery dais, or across a crafting bench, all of
    which sit outside the corridor. Radii are sized for a canopy rather than a
    trunk, because the visible problem is a tree overhanging a building, not
    just its base intersecting one.
]]
local FOLIAGE_KEEP_OUT = table.freeze({
    table.freeze({ x = -36, z = -112, radius = 30 }), -- Wayfarer cabin lot
    table.freeze({ x = 36, z = -112, radius = 30 }), -- Mara's shelter lot
    table.freeze({ x = 0, z = -112, radius = 36 }), -- lantern square
    table.freeze({ x = -42, z = -142, radius = 32 }), -- western workshop district
    table.freeze({ x = 42, z = -142, radius = 32 }), -- eastern workshop district
    table.freeze({ x = -78, z = -76, radius = 22 }), -- Scout mastery clearing
    table.freeze({ x = 78, z = -76, radius = 22 }), -- Warden mastery clearing
    table.freeze({ x = -78, z = -168, radius = 22 }), -- Engineer mastery clearing
    table.freeze({ x = 78, z = -168, radius = 22 }), -- Medic mastery clearing
    table.freeze({ x = -92, z = -184, radius = 25 }), -- Wayfarer inn
    table.freeze({ x = 96, z = -164, radius = 26 }), -- Greenward garden
    table.freeze({ x = 62, z = -198, radius = 18 }), -- camp commons
    table.freeze({ x = -92, z = -144, radius = 22 }), -- archive district
    table.freeze({ x = 92, z = -126, radius = 22 }), -- workbench district
    table.freeze({ x = 0, z = -158, radius = 16 }), -- town board turnout
    table.freeze({ x = -20, z = -132, radius = 10 }), -- field-book archive
    table.freeze({ x = 38, z = -48, radius = 12 }), -- Heartwood gathering lot
    table.freeze({ x = -42, z = -68, radius = 18 }), -- starter-tool yard
    table.freeze({ x = -44, z = -92, radius = 16 }), -- barricade work lot
    table.freeze({ x = 0, z = -143, radius = 26 }), -- night watch posts
    table.freeze({ x = 78, z = -42, radius = 22 }), -- authored root arch landmark
    table.freeze({ x = -78, z = -44, radius = 24 }), -- hollow lantern shrine landmark
})

local TOWN_SIDE_ROAD_BOUNDS = table.freeze({
    table.freeze({ minX = -84, maxX = 4, minZ = -149, maxZ = -139 }),
    table.freeze({ minX = -4, maxX = 84, minZ = -131, maxZ = -121 }),
    table.freeze({ minX = -84, maxX = 4, minZ = -189, maxZ = -179 }),
    table.freeze({ minX = -4, maxX = 84, minZ = -169, maxZ = -159 }),
    table.freeze({ minX = -4, maxX = 54, minZ = -203, maxZ = -193 }),
})

--[[
    True when a position is clear of the route corridor and every authored
    structure, so foliage may be planted there.
]]
local function isFoliagePlantable(x: number, z: number): boolean
    if math.abs(x) <= ROUTE_HALF_WIDTH and z <= 20 and z >= -200 then
        return false
    end

    for _, bounds in TOWN_SIDE_ROAD_BOUNDS do
        if x >= bounds.minX and x <= bounds.maxX and z >= bounds.minZ and z <= bounds.maxZ then
            return false
        end
    end

    for _, keepOut in FOLIAGE_KEEP_OUT do
        local dx = x - keepOut.x
        local dz = z - keepOut.z
        if dx * dx + dz * dz < keepOut.radius * keepOut.radius then
            return false
        end
    end

    return true
end

--[[
    Plants one depth band of the forest.

    Each band owns a Random seeded from its own index rather than sharing one
    sequential generator. That is what lets band 1 be planted before the world
    is ready and bands 2-3 afterwards without changing what either produces: a
    shared generator would make every tree depend on how much of the rest of
    the build had already consumed from it, so deferring a band would silently
    reshape the whole forest -- and the firefly loop draws from the same
    generator, so it would have reshaped it differently depending on timing.
]]
local function plantForestBand(
    forest: Instance,
    bandIndex: number,
    swayTag: string?,
    meshPlacements: { MeshPlacement }?
)
    local band = FOREST_BANDS[bandIndex]
    local random = Random.new(1847 + bandIndex * 7919)
    local treeSeed = 4100 + bandIndex * 1000

    for _ = 1, band.count do
        local angle = random:NextNumber(0, math.pi * 2)
        local radius = random:NextNumber(band.inner, band.outer)
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius - 70

        if isFoliagePlantable(x, z) then
            -- Sit the trunk on the real surface. Bands 2 and 3 reach 340 and
            -- 620 studs, well past the flat bowl, where the ground rises by up
            -- to ~90 studs; planting at a hardcoded y = 0 buried exactly the
            -- depth layers this scatter exists to create.
            local position = Vector3.new(x, TerrainBuilder.surfaceHeight(x, z), z)
            treeSeed += 1
            local scale = random:NextNumber(band.minScale, band.maxScale)
            local roll = random:NextNumber()

            if roll < 0.62 then
                if bandIndex == 1 and meshPlacements ~= nil and treeSeed % 3 == 0 then
                    table.insert(meshPlacements, {
                        assetId = if treeSeed % 2 == 0
                            then "mesh_conifer_hero_a"
                            else "mesh_conifer_hero_b",
                        fallbackKind = "conifer",
                        position = position,
                        scale = scale,
                        yaw = random:NextNumber(0, math.pi * 2),
                        seed = treeSeed,
                        swayTag = swayTag,
                    })
                else
                    FoliageBuilder.conifer(forest, position, scale, FOLIAGE_TONE, treeSeed, swayTag)
                end
            elseif roll < 0.9 then
                if bandIndex == 1 and meshPlacements ~= nil and treeSeed % 3 == 0 then
                    table.insert(meshPlacements, {
                        assetId = "mesh_broadleaf_hero_a",
                        fallbackKind = "broadleaf",
                        position = position,
                        scale = scale,
                        yaw = random:NextNumber(0, math.pi * 2),
                        seed = treeSeed,
                        swayTag = swayTag,
                    })
                else
                    FoliageBuilder.broadleaf(
                        forest,
                        position,
                        scale,
                        FOLIAGE_TONE,
                        treeSeed,
                        swayTag
                    )
                end
            else
                FoliageBuilder.snag(forest, position, scale, FOLIAGE_TONE, treeSeed)
            end

            -- Ground detail only in the near band, where the camera can
            -- actually resolve it.
            if bandIndex == 1 then
                if treeSeed % 3 == 0 then
                    local boulderPosition = position
                        + Vector3.new(random:NextNumber(-12, 12), 0, random:NextNumber(-12, 12))
                    local boulderScale = random:NextNumber(0.7, 1.5)
                    if meshPlacements ~= nil and treeSeed % 2 == 0 then
                        table.insert(meshPlacements, {
                            assetId = "mesh_boulder_cluster_a",
                            fallbackKind = "boulders",
                            position = boulderPosition,
                            scale = boulderScale,
                            yaw = random:NextNumber(0, math.pi * 2),
                            seed = treeSeed,
                            swayTag = nil,
                        })
                    else
                        FoliageBuilder.boulders(
                            forest,
                            boulderPosition,
                            boulderScale,
                            FOLIAGE_TONE,
                            treeSeed
                        )
                    end
                end
                if treeSeed % 4 == 0 then
                    local fernPosition = position
                        + Vector3.new(random:NextNumber(-9, 9), 0, random:NextNumber(-9, 9))
                    local fernScale = random:NextNumber(0.8, 1.5)
                    if meshPlacements ~= nil and treeSeed % 8 == 0 then
                        table.insert(meshPlacements, {
                            assetId = "mesh_fern_cluster_a",
                            fallbackKind = "undergrowth",
                            position = fernPosition,
                            scale = fernScale,
                            yaw = random:NextNumber(0, math.pi * 2),
                            seed = treeSeed,
                            swayTag = swayTag,
                        })
                    else
                        FoliageBuilder.undergrowth(
                            forest,
                            fernPosition,
                            fernScale,
                            FOLIAGE_TONE,
                            treeSeed,
                            swayTag
                        )
                    end
                end
                if treeSeed % 11 == 0 then
                    local deadfallPosition = position
                        + Vector3.new(random:NextNumber(-10, 10), 0, random:NextNumber(-10, 10))
                    local deadfallScale = random:NextNumber(0.7, 1.3)
                    if meshPlacements ~= nil then
                        table.insert(meshPlacements, {
                            assetId = "mesh_deadfall_a",
                            fallbackKind = "deadfall",
                            position = deadfallPosition,
                            scale = deadfallScale,
                            yaw = random:NextNumber(0, math.pi * 2),
                            seed = treeSeed,
                            swayTag = nil,
                        })
                    else
                        FoliageBuilder.deadfall(
                            forest,
                            deadfallPosition,
                            deadfallScale,
                            FOLIAGE_TONE,
                            treeSeed
                        )
                    end
                end
            end
        end
    end
end

function WorldService._buildEnvironment(_self: WorldService, world: Model)
    local geometry = Instance.new("Folder")
    geometry.Name = "Environment"
    geometry.Parent = world

    -- Real sculpted Terrain instead of a 320 x 6 x 340 Part. The valley floor
    -- every authored coordinate below sits on stays flat at y = 0; all relief
    -- happens outside it. See TerrainBuilder for why that split matters.
    --
    -- Core only: this runs before ArrivalSpawn exists and before the world is
    -- marked ready, so it covers the ground a player can stand on and stops
    -- there. The horizon is filled in by _buildDistantScenery once joining is
    -- unblocked.
    TerrainBuilder.buildCore()

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
        Vector3.new(0, 0.42, 0),
        Vector3.new(-3, 0.42, -28),
        Vector3.new(20, 0.42, -48),
        Vector3.new(0, 0.42, -68),
        Vector3.new(-20, 0.42, -88),
        Vector3.new(0, 0.42, -112),
        Vector3.new(0, 0.42, -148),
    }
    local arrivalRoadAssetPlacements: { MeshPlacement } = {}

    for segment = 1, #route - 1 do
        local start = route[segment]
        local finish = route[segment + 1]
        local delta = finish - start
        local distance = delta.Magnitude
        local midpoint = (start + finish) / 2
        local roadFrame = CFrame.lookAt(midpoint, finish)
        local foundation = part(
            geometry,
            "EmberhollowRoadFoundation",
            Vector3.new(17.2, 0.28, distance + 4),
            roadFrame * CFrame.new(0, -0.08, 0),
            Color3.fromRGB(72, 65, 53),
            Enum.Material.Cobblestone,
            false
        )
        foundation.CanQuery = false
        local trail = part(
            geometry,
            "EmberhollowRoad",
            Vector3.new(15.2, 0.36, distance + 3.6),
            roadFrame * CFrame.new(0, 0.18, 0),
            Color3.fromRGB(126, 82, 45),
            Enum.Material.Ground,
            false
        )
        trail.CanQuery = false
        trail.Reflectance = 0.02
        local wornCenter = part(
            geometry,
            "EmberhollowRoadWear",
            Vector3.new(6.2, 0.12, distance + 2.8),
            roadFrame * CFrame.new(0, 0.43, 0),
            Color3.fromRGB(162, 116, 67),
            Enum.Material.Pebble,
            false
        )
        wornCenter.CanQuery = false

        for rutSide = -1, 1, 2 do
            local rut = part(
                geometry,
                "RoadRut",
                Vector3.new(0.62, 0.08, distance + 1),
                roadFrame * CFrame.new(rutSide * 2.25, 0.52, 0),
                Color3.fromRGB(57, 40, 28),
                Enum.Material.Mud,
                false
            )
            rut.CanQuery = false
        end

        local markerCount = math.max(2, math.floor(distance / 8))
        for marker = 0, markerCount do
            local along = -distance * 0.5 + distance * marker / markerCount
            for side = -1, 1, 2 do
                local edgeStone = part(
                    geometry,
                    "RoadEdgeStone",
                    Vector3.new(0.9, 0.38, 1.35),
                    roadFrame
                        * CFrame.new(side * 7.85, 0.37, along)
                        * CFrame.Angles(0, math.rad(side * (marker % 2) * 7), 0),
                    if marker % 3 == 0
                        then Color3.fromRGB(107, 101, 86)
                        else Color3.fromRGB(75, 83, 79),
                    Enum.Material.Slate,
                    false
                )
                edgeStone.CanQuery = false
            end
        end
        queueRoadAssetPlacements(
            arrivalRoadAssetPlacements,
            geometry,
            start,
            finish,
            9400 + segment * 20
        )
    end

    local function tutorialSpur(start: Vector3, finish: Vector3)
        local delta = finish - start
        local spur = part(
            geometry,
            "TutorialSpurPath",
            Vector3.new(6, 0.16, delta.Magnitude + 1),
            CFrame.lookAt((start + finish) / 2, finish),
            Color3.fromRGB(105, 75, 44),
            Enum.Material.Mud,
            false
        )
        spur.CanQuery = false
    end
    tutorialSpur(Vector3.new(28, 0.76, -48), Vector3.new(34, 0.76, -48))
    tutorialSpur(Vector3.new(-8, 0.76, -68), Vector3.new(-38, 0.76, -68))
    tutorialSpur(Vector3.new(-27, 0.76, -89), Vector3.new(-39, 0.76, -92))

    -- The forest. Previously 92 identical conifers packed into a 54-154 stud
    -- ring, which is why the valley read as a yard with a hedge around it: the
    -- treeline sat almost on top of the route and there was nothing past it.
    --
    -- Now the scatter runs to 620 studs in three depth bands, which is the
    -- layering the art direction asks every background to have -- near framing,
    -- regional mid-ground, distant silhouette. StreamingTargetRadius is 1024,
    -- so the far band streams in and out rather than loading at join.
    local forest = Instance.new("Folder")
    forest.Name = "Forest"
    forest.Parent = geometry

    local random = Random.new(1847)
    local swayTag = _self._runtimeIds.AmbientSwayTag

    _self._meshPlacements = {
        {
            assetId = "mesh_root_arch_a",
            fallbackKind = "root_arch",
            position = Vector3.new(78, TerrainBuilder.surfaceHeight(78, -42), -42),
            scale = 1,
            yaw = math.rad(-28),
            seed = 9147,
            swayTag = nil,
        },
        {
            assetId = "mesh_hollow_lantern_shrine_a",
            fallbackKind = "hollow_shrine",
            position = Vector3.new(-78, TerrainBuilder.surfaceHeight(-78, -44), -44),
            scale = 1,
            yaw = math.rad(22),
            seed = 9148,
            swayTag = nil,
        },
    }
    for _, placement in arrivalRoadAssetPlacements do
        table.insert(_self._meshPlacements, placement)
    end

    -- Only the near band is planted here. Bands 2 and 3 are scenery beyond the
    -- immediate clearing and are planted after the world is marked ready; see
    -- _buildDistantScenery.
    plantForestBand(forest, 1, swayTag, _self._meshPlacements)

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

    -- Near-field ground detail just outside the route, where the camera is
    -- close enough for it to register.
    for index = 1, 24 do
        local angle = (index / 24) * math.pi * 2
        local radius = 48 + (index % 4) * 8
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius - 70

        -- Same keep-out test the tree bands use. This ring sits at radius
        -- 48-72, so without it indices land directly on the lantern trail.
        if isFoliagePlantable(x, z) then
            local position = Vector3.new(x, TerrainBuilder.surfaceHeight(x, z), z)
            FoliageBuilder.boulders(
                forest,
                position,
                0.6 + (index % 5) * 0.16,
                FOLIAGE_TONE,
                8300 + index
            )
            if index % 2 == 0 then
                FoliageBuilder.undergrowth(
                    forest,
                    position + Vector3.new(3, 0, -2),
                    0.9,
                    FOLIAGE_TONE,
                    8400 + index,
                    _self._runtimeIds.AmbientSwayTag
                )
            end
        end
    end

    addFillLight(geometry, Vector3.new(-46, 12, -96), Color3.fromRGB(54, 103, 95), 0.85, 78)
    addFillLight(geometry, Vector3.new(38, 10, -28), Color3.fromRGB(255, 177, 88), 0.45, 54)
    emberDrift(geometry, Vector3.new(0, 0, -112), AMBER, 16, 28, _self._runtimeIds.AmbientMoteTag)

    local lanternSpecs = {
        { position = Vector3.new(7, 0, -9), scale = 0.68, yaw = math.rad(-18) },
        { position = Vector3.new(-10, 0, -28), scale = 0.62, yaw = math.rad(14) },
        { position = Vector3.new(24, 0, -42), scale = 0.62, yaw = math.rad(-12) },
        { position = Vector3.new(-8, 0, -66), scale = 0.62, yaw = math.rad(14) },
        { position = Vector3.new(-27, 0, -87), scale = 0.62, yaw = math.rad(-12) },
        { position = Vector3.new(8, 0, -103), scale = 0.62, yaw = math.rad(14) },
    }
    for index, spec in lanternSpecs do
        local placeholder =
            lantern(geometry, spec.position, spec.scale, _self._runtimeIds.AmbientLightTag)
        table.insert(_self._meshPlacements, {
            assetId = "mesh_creator_street_lantern_a",
            fallbackKind = "placeholder",
            position = spec.position,
            scale = spec.scale,
            yaw = spec.yaw,
            seed = 9200 + index,
            swayTag = nil,
            parent = geometry,
            fallbackInstance = placeholder,
        })
    end
    local routeSign = labelSign(
        geometry,
        CFrame.new(7, 3, -14) * CFrame.Angles(0, math.pi, 0),
        "FOLLOW THE LANTERNS"
    )
    table.insert(_self._meshPlacements, {
        assetId = "mesh_creator_forest_sign_a",
        fallbackKind = "asset_replacement",
        position = Vector3.new(7, 0, -14),
        scale = 1.2,
        yaw = math.pi,
        seed = 9841,
        swayTag = nil,
        parent = geometry,
        fallbackInstance = routeSign,
    })
    buildEmberhollowSanctuary(geometry, _self._meshPlacements)

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
        local towerFallback = Instance.new("Model")
        towerFallback.Name = "WatchtowerFallback"
        towerFallback.Parent = defenseRoute
        for postSide = -1, 1, 2 do
            part(
                towerFallback,
                "WatchPost",
                Vector3.new(0.85, 8.5, 0.85),
                CFrame.new(towerCenter + Vector3.new(postSide * 2.2, 4.25, 0)),
                WET_BARK,
                Enum.Material.Wood
            )
        end
        part(
            towerFallback,
            "WatchPlatform",
            Vector3.new(6.2, 0.65, 5.2),
            CFrame.new(towerCenter + Vector3.new(0, 7.1, 0)),
            Color3.fromRGB(83, 61, 43),
            Enum.Material.WoodPlanks
        )
        table.insert(_self._meshPlacements, {
            assetId = "mesh_creator_watchtower_a",
            fallbackKind = "asset_replacement",
            position = towerCenter,
            scale = 1,
            yaw = if side < 0 then math.rad(12) else math.rad(-12),
            seed = 9850 + side,
            swayTag = nil,
            parent = defenseRoute,
            fallbackInstance = towerFallback,
        })
        table.insert(_self._meshPlacements, {
            assetId = "mesh_creator_campfire_a",
            fallbackKind = "asset_dressing",
            position = towerCenter + Vector3.new(0, 15.4, 0),
            scale = 0.65,
            yaw = math.rad(side * 17),
            seed = 9860 + side,
            swayTag = nil,
            parent = defenseRoute,
            fallbackInstance = nil,
        })
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
    WorldSignBuilder.dressBoard(
        warningBoard,
        "NIGHT WATCH · HOLD THE LANTERN ROAD",
        CREAM,
        "warning"
    )
    table.insert(_self._meshPlacements, {
        assetId = "mesh_creator_notice_board_a",
        fallbackKind = "asset_replacement",
        position = Vector3.new(0, 1, -146.8),
        scale = 0.7,
        yaw = 0,
        seed = 9870,
        swayTag = nil,
        parent = defenseRoute,
        fallbackInstance = warningBoard,
    })
end

-- Rebuilds the same placement from inexpensive geometry when an authored model
-- cannot load. The choice is stable and never leaves a hole in the route art.
local function buildMeshFallback(parent: Instance, placement: MeshPlacement)
    if placement.fallbackKind == "conifer" then
        FoliageBuilder.conifer(
            parent,
            placement.position,
            placement.scale,
            FOLIAGE_TONE,
            placement.seed,
            placement.swayTag
        )
    elseif placement.fallbackKind == "broadleaf" then
        FoliageBuilder.broadleaf(
            parent,
            placement.position,
            placement.scale,
            FOLIAGE_TONE,
            placement.seed,
            placement.swayTag
        )
    elseif placement.fallbackKind == "boulders" then
        FoliageBuilder.boulders(
            parent,
            placement.position,
            placement.scale,
            FOLIAGE_TONE,
            placement.seed
        )
    elseif placement.fallbackKind == "undergrowth" then
        FoliageBuilder.undergrowth(
            parent,
            placement.position,
            placement.scale,
            FOLIAGE_TONE,
            placement.seed,
            placement.swayTag
        )
    elseif placement.fallbackKind == "deadfall" then
        FoliageBuilder.deadfall(
            parent,
            placement.position,
            placement.scale,
            FOLIAGE_TONE,
            placement.seed
        )
    elseif placement.fallbackKind == "root_arch" then
        FoliageBuilder.rootArch(
            parent,
            placement.position,
            placement.scale,
            FOLIAGE_TONE,
            placement.yaw
        )
    elseif placement.fallbackKind == "hollow_shrine" then
        FoliageBuilder.rootArch(
            parent,
            placement.position,
            placement.scale * 1.1,
            FOLIAGE_TONE,
            placement.yaw
        )
    end
end

local function hideProceduralPlaceholder(placeholder: Instance)
    local instances = placeholder:GetDescendants()
    table.insert(instances, placeholder)
    for _, instance in instances do
        if instance:IsA("BasePart") then
            instance.Transparency = 1
            instance.CastShadow = false
        elseif
            instance:IsA("Light")
            or instance:IsA("ParticleEmitter")
            or instance:IsA("Fire")
            or instance:IsA("Smoke")
            or instance:IsA("Sparkles")
            or instance:IsA("Trail")
            or instance:IsA("Beam")
        then
            instance.Enabled = false
        end
    end
    placeholder:SetAttribute("ReplacedByAuthoredMesh", true)
end

-- Authored art is optional streaming dressing. Loading begins only after the
-- spawn and interactions are ready, and a failed private asset immediately
-- takes the procedural path above.
function WorldService._placeAuthoredMeshes(
    self: WorldService,
    placements: { MeshPlacement },
    defaultParent: Instance,
    attributeTarget: Instance,
    readyEvent: string
)
    local queued = table.clone(placements)
    task.spawn(function()
        local authored = 0
        local fallbacks = 0
        for index, placement in queued do
            local placementParent = placement.parent or defaultParent
            if attributeTarget.Parent == nil or placementParent.Parent == nil then
                return
            end
            local placementFrame, profileScale = authoredPlacementTransform(placement)
            local placed, result = pcall(
                self._meshTemplateLoader.place,
                self._meshTemplateLoader,
                placement.assetId,
                placementParent,
                placementFrame,
                placement.scale,
                profileScale
            )
            local model = if placed then result else nil
            if not placed then
                self._logger:info("mesh_placement_failed", {
                    assetId = placement.assetId,
                    error = tostring(result),
                })
            end
            if model == nil then
                if placement.fallbackInstance == nil then
                    buildMeshFallback(placementParent, placement)
                end
                fallbacks += 1
            else
                if placement.fallbackInstance ~= nil then
                    hideProceduralPlaceholder(placement.fallbackInstance)
                end
                authored += 1
            end
            if index % 5 == 0 then
                task.wait()
            end
        end

        attributeTarget:SetAttribute("AuthoredMeshCount", authored)
        attributeTarget:SetAttribute("AuthoredMeshFallbackCount", fallbacks)
        self._logger:info(readyEvent, {
            authored = authored,
            fallbacks = fallbacks,
            placements = #queued,
        })
    end)
end

function WorldService._buildMeshDressing(self: WorldService)
    local world = self._world
    if world == nil then
        return
    end
    local geometry = world:FindFirstChild("Environment")
    local forest = if geometry ~= nil then geometry:FindFirstChild("Forest") else nil
    if forest == nil then
        return
    end
    self:_placeAuthoredMeshes(self._meshPlacements, forest, world, "mesh_dressing_ready")
end

--[[
    Fills in the horizon after joining is unblocked.

    Everything here is optional scenery: terrain past CORE_RADIUS, and the two
    outer forest bands. None of it is ground a player can stand on and none of
    it gates the tutorial, so it must not sit between a joining player and a
    playable world. AGENTS.md is explicit that joining never blocks on the
    whole world loading, and Config.BootstrapTimeoutSeconds is only 8 -- the
    first version of this change generated the entire 121 x 121 hill grid, the
    peak ring, and all 4,000-plus forest parts before ArrivalSpawn even
    existed.

    Yields between grid rows and between bands so the work lands across many
    frames instead of one long hitch. Failures are contained: scenery breaking
    out here must not take down a world that is already ready and playable.
]]
function WorldService._buildDistantScenery(self: WorldService)
    local world = self._world
    if world == nil then
        return
    end

    local geometry = world:FindFirstChild("Environment")
    local forest = if geometry ~= nil then geometry:FindFirstChild("Forest") else nil
    local swayTag = self._runtimeIds.AmbientSwayTag

    task.spawn(function()
        local ok, err = pcall(function()
            TerrainBuilder.buildDistant(nil, nil, function()
                task.wait()
            end)

            for bandIndex = 2, 3 do
                -- The world can be torn down and rebuilt while this runs.
                if forest == nil or forest.Parent == nil then
                    return
                end
                plantForestBand(forest, bandIndex, swayTag)
                task.wait()
            end
        end)

        if not ok then
            self._logger:info("distant_scenery_failed", { error = tostring(err) })
            return
        end
        self._logger:info("distant_scenery_ready", {})
    end)
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
    for side = -1, 1, 2 do
        local shoulder = part(
            model,
            "CoatShoulder",
            Vector3.new(1.05, 1.05, 1.18),
            CFrame.new(-3 + side * 1.3, 4.35, -30),
            Color3.fromRGB(50, 72, 56),
            Enum.Material.Fabric,
            false
        )
        shoulder.Shape = Enum.PartType.Ball
        part(
            model,
            "HairLock",
            Vector3.new(0.42, 1.85, 0.5),
            CFrame.new(-3 + side * 0.88, 5.78, -30.18) * CFrame.Angles(0, 0, math.rad(side * 8)),
            Color3.fromRGB(79, 43, 31),
            Enum.Material.SmoothPlastic,
            false
        )
        part(
            model,
            "CoatTail",
            Vector3.new(1.12, 2.25, 0.28),
            CFrame.new(-3 + side * 0.68, 1.72, -29.13)
                * CFrame.Angles(math.rad(-8), 0, math.rad(side * 5)),
            Color3.fromRGB(42, 61, 49),
            Enum.Material.Fabric,
            false
        )
    end
    part(
        model,
        "ScarfKnot",
        Vector3.new(0.68, 0.68, 0.48),
        CFrame.new(-3, 5.02, -30.83),
        Color3.fromRGB(196, 134, 64),
        Enum.Material.Fabric,
        false
    ).Shape =
        Enum.PartType.Ball
    part(
        model,
        "CoatBelt",
        Vector3.new(2.75, 0.34, 1.5),
        CFrame.new(-3, 2.52, -30),
        Color3.fromRGB(84, 58, 40),
        Enum.Material.Leather,
        false
    )
    part(
        model,
        "CoatBuckle",
        Vector3.new(0.52, 0.5, 0.2),
        CFrame.new(-3, 2.5, -30.82),
        AMBER,
        Enum.Material.Metal,
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
        "Nose",
        Vector3.new(0.3, 0.42, 0.34),
        CFrame.new(-3, 5.98, -31.02),
        Color3.fromRGB(190, 137, 99),
        Enum.Material.SmoothPlastic,
        false
    ).Shape =
        Enum.PartType.Ball
    part(
        model,
        "Mouth",
        Vector3.new(0.52, 0.12, 0.1),
        CFrame.new(-3, 5.58, -31.02),
        Color3.fromRGB(104, 59, 51),
        Enum.Material.SmoothPlastic,
        false
    )
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
    local handLanternFallback = Instance.new("Model")
    handLanternFallback.Name = "MaraLanternFallback"
    handLanternFallback.Parent = model
    local handLantern = part(
        handLanternFallback,
        "MaraLantern",
        Vector3.new(0.82, 1.12, 0.82),
        CFrame.new(-1.2, 1.45, -30),
        Color3.fromRGB(204, 154, 81),
        Enum.Material.Glass,
        false
    )
    handLantern.Transparency = 0.48
    for railX = -1, 1, 2 do
        for railZ = -1, 1, 2 do
            part(
                handLanternFallback,
                "MaraLanternRail",
                Vector3.new(0.1, 1.42, 0.1),
                handLantern.CFrame * CFrame.new(railX * 0.48, 0, railZ * 0.48),
                Color3.fromRGB(47, 50, 52),
                Enum.Material.Metal,
                false
            )
        end
    end
    for capY = -1, 1, 2 do
        part(
            handLanternFallback,
            "MaraLanternCap",
            Vector3.new(1.15, 0.18, 1.15),
            handLantern.CFrame * CFrame.new(0, capY * 0.7, 0),
            Color3.fromRGB(47, 50, 52),
            Enum.Material.Metal,
            false
        )
    end
    local handFlame = part(
        handLanternFallback,
        "MaraLanternFlame",
        Vector3.new(0.32, 0.62, 0.28),
        handLantern.CFrame * CFrame.new(0, -0.08, 0) * CFrame.Angles(0, math.rad(18), 0),
        AMBER,
        Enum.Material.Neon,
        false
    )
    handFlame.Shape = Enum.PartType.Wedge
    local handLight = Instance.new("PointLight")
    handLight.Color = AMBER
    handLight.Brightness = 0.55
    handLight.Range = 9
    handLight.Shadows = false
    handLight.Parent = handFlame
    CollectionService:AddTag(handFlame, self._runtimeIds.AmbientLightTag)
    table.insert(self._meshPlacements, {
        assetId = "mesh_creator_kerosene_lantern_a",
        fallbackKind = "placeholder",
        position = Vector3.new(-1.2, 0.35, -30),
        scale = 1,
        yaw = math.rad(-8),
        seed = 9313,
        swayTag = nil,
        parent = model,
        fallbackInstance = handLanternFallback,
    })
    model.PrimaryPart = root
    model.Parent = world
    model:SetAttribute("MotionKind", "resident")
    model:SetAttribute("MotionSpeed", 0.72)
    CollectionService:AddTag(model, self._runtimeIds.AmbientMotionTag)
    addBillboard(head, "MARA · GREENWARD", AMBER, 46)

    local fallenRootsFallback = Instance.new("Model")
    fallenRootsFallback.Name = "MaraFallenRootsFallback"
    fallenRootsFallback.Parent = world
    for index = -1, 1 do
        part(
            fallenRootsFallback,
            "FallenRoot",
            Vector3.new(1.3, 10, 1.3),
            CFrame.new(-3 + index * 2.6, 2, -30)
                * CFrame.Angles(math.rad(72), 0, math.rad(index * 14)),
            BARK,
            Enum.Material.Wood
        )
    end
    table.insert(self._meshPlacements, {
        assetId = "mesh_deadfall_a",
        fallbackKind = "asset_replacement",
        position = Vector3.new(-3, -0.2, -30),
        scale = 1.15,
        yaw = math.rad(17),
        seed = 9320,
        swayTag = nil,
        parent = world,
        fallbackInstance = fallenRootsFallback,
        profileScale = Vector3.new(1.18, 0.92, 0.86),
    })

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

    local heartwoodFallback = Instance.new("Model")
    heartwoodFallback.Name = "HeartwoodVisualFallback"
    heartwoodFallback.Parent = interactables
    local stump = part(
        heartwoodFallback,
        "HeartwoodStump",
        Vector3.new(7.6, 5.8, 7.6),
        CFrame.new(HEARTWOOD_CENTER + Vector3.new(0, 2.9, 0)),
        WET_BARK,
        Enum.Material.Wood
    )
    stump.Shape = Enum.PartType.Cylinder
    stump.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
    for rootIndex = 1, 6 do
        local angle = (rootIndex / 6) * math.pi * 2
        part(
            heartwoodFallback,
            "HeartwoodRoot",
            Vector3.new(1.05, 1.15, 5.8),
            CFrame.new(
                HEARTWOOD_CENTER + Vector3.new(math.cos(angle) * 3.8, 0.62, math.sin(angle) * 3.8)
            )
                * CFrame.Angles(0, -angle, math.rad(5 + rootIndex % 2 * 4)),
            if rootIndex % 2 == 0 then BARK else WET_BARK,
            Enum.Material.Wood,
            false
        )
    end
    for barkIndex = 1, 10 do
        local angle = (barkIndex / 10) * math.pi * 2
        local barkRib = part(
            heartwoodFallback,
            "HeartwoodBarkRib",
            Vector3.new(1.15, 4.8 + (barkIndex % 3) * 0.45, 0.62),
            CFrame.new(
                HEARTWOOD_CENTER
                    + Vector3.new(
                        math.cos(angle) * 3.65,
                        2.4 + (barkIndex % 3) * 0.18,
                        math.sin(angle) * 3.65
                    )
            )
                * CFrame.Angles(0, -angle + math.rad(90), math.rad((barkIndex % 2) * 3 - 1.5)),
            if barkIndex % 2 == 0 then BARK else Color3.fromRGB(48, 31, 25),
            Enum.Material.Wood,
            false
        )
        barkRib.CanQuery = false
    end
    for crownIndex = 1, 6 do
        local angle = (crownIndex / 6) * math.pi * 2
        local crown = part(
            heartwoodFallback,
            "HeartwoodSplitCrown",
            Vector3.new(1.5, 2 + (crownIndex % 2) * 0.7, 1.2),
            CFrame.new(
                HEARTWOOD_CENTER
                    + Vector3.new(
                        math.cos(angle) * 2.35,
                        6.1 + (crownIndex % 2) * 0.25,
                        math.sin(angle) * 2.35
                    )
            )
                * CFrame.Angles(0, -angle, math.rad(if crownIndex % 2 == 0 then 8 else -7)),
            if crownIndex % 2 == 0 then BARK else WET_BARK,
            Enum.Material.Wood,
            false
        )
        crown.Shape = Enum.PartType.Wedge
        crown.CanQuery = false
    end
    for ringIndex = 1, 3 do
        local growthRing = part(
            heartwoodFallback,
            "HeartwoodGrowthRing",
            Vector3.new(0.16, 5.7 - ringIndex * 0.7, 5.7 - ringIndex * 0.7),
            stump.CFrame * CFrame.new(3.05, 0, 0),
            Color3.fromRGB(128 + ringIndex * 12, 91 + ringIndex * 8, 55),
            Enum.Material.Wood,
            false
        )
        growthRing.Shape = Enum.PartType.Cylinder
    end
    local cavity = part(
        heartwoodFallback,
        "HeartwoodCavity",
        Vector3.new(3.9, 4.1, 0.5),
        CFrame.new(HEARTWOOD_CENTER + Vector3.new(0, 4.05, 3.42)),
        Color3.fromRGB(27, 19, 17),
        Enum.Material.Wood,
        false
    )
    cavity.Shape = Enum.PartType.Ball
    cavity.CanQuery = false
    local heart = part(
        heartwoodFallback,
        "HeartwoodCore",
        Vector3.new(2.5, 2.9, 0.85),
        CFrame.new(HEARTWOOD_CENTER + Vector3.new(0, 4.15, 3.65)),
        AMBER,
        Enum.Material.Glass,
        false
    )
    heart.Shape = Enum.PartType.Ball
    heart.Transparency = 0.2
    for shardIndex = -1, 1 do
        local shard = part(
            heartwoodFallback,
            "HeartwoodShard",
            Vector3.new(0.65, 2.1 + math.abs(shardIndex) * 0.45, 0.55),
            CFrame.new(
                HEARTWOOD_CENTER
                    + Vector3.new(shardIndex * 0.82, 4.2 + math.abs(shardIndex) * 0.25, 3.82)
            )
                * CFrame.Angles(0, math.rad(shardIndex * 18), math.rad(shardIndex * -8)),
            AMBER,
            Enum.Material.Glass,
            false
        )
        shard.Shape = Enum.PartType.Wedge
        shard.Transparency = 0.12
    end
    local heartLight = Instance.new("PointLight")
    heartLight.Color = AMBER
    heartLight.Brightness = 1.1
    heartLight.Range = 12
    heartLight.Parent = heart
    addBillboard(heart, "HEARTWOOD", AMBER, 18)
    table.insert(self._meshPlacements, {
        assetId = "mesh_creator_stump_a",
        fallbackKind = "asset_replacement",
        position = HEARTWOOD_CENTER,
        scale = 1.15,
        yaw = math.rad(-18),
        seed = 9880,
        swayTag = nil,
        parent = interactables,
        fallbackInstance = heartwoodFallback,
    })
    self:_registerInteraction(
        stump,
        self._runtimeIds.InteractionIds.Heartwood,
        self._runtimeIds.Actions.Gather,
        "GATHER",
        "Heartwood",
        nil
    )

    local toolYard = Instance.new("Model")
    toolYard.Name = "StarterToolYard"
    toolYard.Parent = interactables
    local toolYardGround = part(
        toolYard,
        "ToolYardGround",
        Vector3.new(14, 0.38, 28),
        CFrame.new(TOOL_YARD_CENTER + Vector3.new(0, 0.19, 0)),
        Color3.fromRGB(71, 54, 39),
        Enum.Material.Ground,
        false
    )
    toolYardGround.CanQuery = false
    for xSide = -1, 1, 2 do
        for zSide = -1, 1, 2 do
            part(
                toolYard,
                "ToolYardPost",
                Vector3.new(0.7, 8.8, 0.7),
                CFrame.new(TOOL_YARD_CENTER + Vector3.new(xSide * 5.8, 4.4, zSide * 12.4))
                    * CFrame.Angles(0, 0, math.rad(xSide * zSide * 2)),
                WET_BARK,
                Enum.Material.Wood,
                false
            )
        end
    end
    part(
        toolYard,
        "ToolYardRidgeBeam",
        Vector3.new(0.7, 0.7, 28),
        CFrame.new(TOOL_YARD_CENTER + Vector3.new(0, 10.15, 0)),
        WET_BARK,
        Enum.Material.Wood,
        false
    )
    for roofSide = -1, 1, 2 do
        local roof = part(
            toolYard,
            "ToolYardRoof",
            Vector3.new(8.2, 3.1, 28.2),
            CFrame.new(TOOL_YARD_CENTER + Vector3.new(roofSide * 3.55, 8.65, 0))
                * CFrame.Angles(0, if roofSide < 0 then math.pi else 0, 0),
            Color3.fromRGB(45, 51, 47),
            Enum.Material.Slate,
            false
        )
        roof.Shape = Enum.PartType.Wedge
    end
    local toolDisplayFallback = Instance.new("Model")
    toolDisplayFallback.Name = "ToolDisplayFallback"
    toolDisplayFallback.Parent = toolYard
    local tools = {
        {
            id = self._runtimeIds.InteractionIds.ToolAxe,
            tool = "axe",
            position = TOOL_YARD_CENTER + Vector3.new(0, 0, 8),
            color = Color3.fromRGB(102, 154, 102),
        },
        {
            id = self._runtimeIds.InteractionIds.ToolHammer,
            tool = "hammer",
            position = TOOL_YARD_CENTER,
            color = AMBER,
        },
        {
            id = self._runtimeIds.InteractionIds.ToolTorch,
            tool = "torch",
            position = TOOL_YARD_CENTER + Vector3.new(0, 0, -8),
            color = Color3.fromRGB(111, 154, 184),
        },
    }
    for _, definition in tools do
        local displayFrame = CFrame.new(definition.position) * CFrame.Angles(0, math.rad(90), 0)
        local display = Instance.new("Model")
        display.Name = "ToolDisplay_" .. definition.tool
        display:SetAttribute("DisplayKind", "open_supply_crate")
        display.Parent = toolDisplayFallback
        local pedestal = part(
            display,
            "Tool_" .. definition.tool,
            Vector3.new(6, 2, 6),
            displayFrame * CFrame.new(0, 1, 0),
            Color3.fromRGB(66, 70, 65),
            Enum.Material.Slate
        )
        pedestal.Transparency = 1
        pedestal.CanCollide = false
        pedestal.CastShadow = false
        part(
            display,
            "ToolDisplayCrate",
            Vector3.new(5.8, 1.7, 4.9),
            displayFrame * CFrame.new(0, 0.85, 0),
            Color3.fromRGB(89, 62, 42),
            Enum.Material.WoodPlanks
        )
        part(
            display,
            "ToolDisplayCushion",
            Vector3.new(4.8, 0.34, 3.7),
            displayFrame * CFrame.new(0, 1.87, 0),
            Color3.fromRGB(64, 77, 65):Lerp(definition.color, 0.24),
            Enum.Material.Fabric,
            false
        )
        for side = -1, 1, 2 do
            part(
                display,
                "ToolDisplayBand",
                Vector3.new(0.36, 1.95, 5.12),
                displayFrame * CFrame.new(side * 2.1, 0.98, 0),
                Color3.fromRGB(87, 91, 86),
                Enum.Material.Metal,
                false
            )
            part(
                display,
                "ToolDisplayLidBrace",
                Vector3.new(0.38, 3.8, 0.38),
                displayFrame
                    * CFrame.new(side * 2.25, 3.15, -2.05)
                    * CFrame.Angles(math.rad(-12), 0, 0),
                Color3.fromRGB(72, 49, 35),
                Enum.Material.Wood,
                false
            )
        end
        part(
            display,
            "ToolDisplayOpenLid",
            Vector3.new(5.8, 0.46, 4.7),
            displayFrame * CFrame.new(0, 3.72, -2.38) * CFrame.Angles(math.rad(-68), 0, 0),
            Color3.fromRGB(77, 53, 37),
            Enum.Material.WoodPlanks,
            false
        )
        part(
            display,
            "ToolDisplayPlaque",
            Vector3.new(3.7, 1.05, 0.28),
            displayFrame * CFrame.new(0, 1.1, 2.52) * CFrame.Angles(math.rad(-8), 0, 0),
            definition.color,
            Enum.Material.SmoothPlastic,
            false
        )
        local marker = part(
            display,
            "ToolHandle",
            Vector3.new(0.45, 4.2, 0.45),
            displayFrame
                * CFrame.new(0, 4.1, 0)
                * CFrame.Angles(0, 0, if definition.tool == "torch" then 0 else math.rad(28)),
            Color3.fromRGB(111, 76, 48),
            Enum.Material.Wood,
            false
        )
        if definition.tool == "axe" then
            local head = part(
                display,
                "AxeHead",
                Vector3.new(2.25, 0.65, 0.38),
                displayFrame * CFrame.new(-0.28, 5.82, 0) * CFrame.Angles(0, 0, math.rad(28)),
                Color3.fromRGB(154, 169, 174),
                Enum.Material.Metal,
                false
            )
            head.Shape = Enum.PartType.Wedge
        elseif definition.tool == "hammer" then
            local head = part(
                display,
                "HammerHead",
                Vector3.new(2.15, 0.78, 0.9),
                displayFrame * CFrame.new(0, 5.85, 0) * CFrame.Angles(0, 0, math.rad(90)),
                Color3.fromRGB(123, 132, 137),
                Enum.Material.Metal,
                false
            )
            head.Shape = Enum.PartType.Cylinder
        else
            local cup = part(
                display,
                "TorchCup",
                Vector3.new(1.2, 0.72, 1.2),
                displayFrame * CFrame.new(0, 6.05, 0),
                Color3.fromRGB(92, 71, 48),
                Enum.Material.Metal,
                false
            )
            cup.Shape = Enum.PartType.Cylinder
            local flame = part(
                display,
                "TorchFlame",
                Vector3.new(1.15, 1.55, 1.15),
                displayFrame * CFrame.new(0, 6.95, 0),
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
    table.insert(self._meshPlacements, {
        assetId = "mesh_creator_workbench_a",
        fallbackKind = "asset_replacement",
        position = TOOL_YARD_CENTER + Vector3.new(0, 0, -1.5),
        scale = 1,
        yaw = math.rad(90),
        seed = 9890,
        swayTag = nil,
        parent = toolYard,
        fallbackInstance = toolDisplayFallback,
    })
    table.insert(self._meshPlacements, {
        assetId = "mesh_creator_tool_set_a",
        fallbackKind = "asset_dressing",
        position = TOOL_YARD_CENTER + Vector3.new(0, 2.7, 3.8),
        scale = 0.8,
        yaw = math.rad(90),
        seed = 9891,
        swayTag = nil,
        parent = toolYard,
        fallbackInstance = nil,
    })

    local barricadeFallback = Instance.new("Model")
    barricadeFallback.Name = "BarricadeWorksiteFallback"
    barricadeFallback.Parent = interactables
    local plot = part(
        barricadeFallback,
        "ConstructionPlot",
        Vector3.new(18, 0.5, 9),
        CFrame.new(BARRICADE_CENTER + Vector3.new(0, 0.25, 0)),
        Color3.fromRGB(218, 184, 108),
        Enum.Material.Ground
    )
    plot.Transparency = 0.08
    for postIndex = -2, 2 do
        local height = 2.8 + (postIndex + 2) * 0.55
        part(
            barricadeFallback,
            "BarricadeWorkPost",
            Vector3.new(0.78, height, 0.78),
            CFrame.new(BARRICADE_CENTER + Vector3.new(postIndex * 3.6, height / 2, 0))
                * CFrame.Angles(0, 0, math.rad(postIndex * 3)),
            WET_BARK,
            Enum.Material.Wood
        )
    end
    for braceIndex = -1, 1 do
        part(
            barricadeFallback,
            "BarricadeWorkBrace",
            Vector3.new(14.8, 0.55, 0.62),
            CFrame.new(BARRICADE_CENTER + Vector3.new(0, 1.7 + (braceIndex + 1) * 1.4, 0))
                * CFrame.Angles(0, 0, math.rad(braceIndex * 6)),
            Color3.fromRGB(103, 72, 46),
            Enum.Material.WoodPlanks,
            false
        )
    end
    for supplyIndex = 1, 4 do
        part(
            barricadeFallback,
            "BarricadeLumber",
            Vector3.new(4.8 + supplyIndex * 0.45, 0.42, 0.58),
            CFrame.new(BARRICADE_CENTER + Vector3.new(-7.3, 0.45 + supplyIndex * 0.36, 2.6))
                * CFrame.Angles(0, math.rad(-8 + supplyIndex * 3), math.rad(2)),
            Color3.fromRGB(112, 78, 48),
            Enum.Material.WoodPlanks,
            false
        )
    end
    addBillboard(plot, "BARRICADE WORKSITE", CREAM, 18)
    for index = -1, 1, 2 do
        table.insert(self._meshPlacements, {
            assetId = "mesh_creator_barricade_a",
            fallbackKind = "asset_replacement",
            position = BARRICADE_CENTER + Vector3.new(index * 5.2, 0, 0),
            scale = 1.05,
            yaw = math.rad(index * 6),
            seed = 9900 + index,
            swayTag = nil,
            parent = interactables,
            fallbackInstance = if index < 0 then barricadeFallback else nil,
        })
    end
    table.insert(self._meshPlacements, {
        assetId = "mesh_creator_crate_a",
        fallbackKind = "asset_dressing",
        position = BARRICADE_CENTER + Vector3.new(-8, 0, 3.2),
        scale = 0.9,
        yaw = math.rad(-12),
        seed = 9903,
        swayTag = nil,
        parent = interactables,
        fallbackInstance = nil,
    })
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
    for stepIndex = 1, 3 do
        part(
            interactables,
            "FirstLanternPlinth",
            Vector3.new(10.5 - stepIndex * 1.45, 0.52, 10.5 - stepIndex * 1.45),
            CFrame.new(0, 0.25 + stepIndex * 0.42, -112),
            if stepIndex % 2 == 0 then Color3.fromRGB(76, 79, 73) else Color3.fromRGB(61, 66, 62),
            Enum.Material.Slate
        )
    end
    local firstLanternFallback = Instance.new("Model")
    firstLanternFallback.Name = "FirstLanternVisualFallback"
    firstLanternFallback.Parent = interactables
    for sideX = -1, 1, 2 do
        for sideZ = -1, 1, 2 do
            part(
                firstLanternFallback,
                "FirstLanternCagePost",
                Vector3.new(0.48, 6.2, 0.48),
                CFrame.new(sideX * 2.35, 5.7, -112 + sideZ * 2.35)
                    * CFrame.Angles(0, 0, math.rad(sideX * sideZ * 4)),
                Color3.fromRGB(75, 72, 62),
                Enum.Material.Metal,
                false
            )
        end
    end
    for ringY = 3.1, 8.2, 5.1 do
        for side = -1, 1, 2 do
            part(
                firstLanternFallback,
                "FirstLanternCageBand",
                Vector3.new(5.2, 0.28, 0.28),
                CFrame.new(0, ringY, -112 + side * 2.5),
                Color3.fromRGB(86, 76, 59),
                Enum.Material.Metal,
                false
            )
            part(
                firstLanternFallback,
                "FirstLanternCageBand",
                Vector3.new(0.28, 0.28, 5.2),
                CFrame.new(side * 2.5, ringY, -112),
                Color3.fromRGB(86, 76, 59),
                Enum.Material.Metal,
                false
            )
        end
    end
    for side = -1, 1, 2 do
        local frontGlass = part(
            firstLanternFallback,
            "FirstLanternGlassPanel",
            Vector3.new(4.35, 4.55, 0.13),
            CFrame.new(0, 5.65, -112 + side * 2.34),
            Color3.fromRGB(205, 158, 91),
            Enum.Material.Glass,
            false
        )
        frontGlass.Transparency = 0.64
        local sideGlass = part(
            firstLanternFallback,
            "FirstLanternGlassPanel",
            Vector3.new(0.13, 4.55, 4.35),
            CFrame.new(side * 2.34, 5.65, -112),
            Color3.fromRGB(205, 158, 91),
            Enum.Material.Glass,
            false
        )
        sideGlass.Transparency = 0.64
        part(
            firstLanternFallback,
            "FirstLanternRainHood",
            Vector3.new(5.7, 0.34, 3.5),
            CFrame.new(0, 9.22, -112 + side * 1.35) * CFrame.Angles(math.rad(side * 28), 0, 0),
            Color3.fromRGB(55, 57, 53),
            Enum.Material.Slate,
            false
        )
    end
    part(
        firstLanternFallback,
        "FirstLanternCrown",
        Vector3.new(0.42, 1.25, 0.42),
        CFrame.new(0, 10.35, -112) * CFrame.Angles(0, 0, math.rad(5)),
        Color3.fromRGB(73, 67, 57),
        Enum.Material.Metal,
        false
    )
    local flame = part(
        firstLanternFallback,
        "FirstLanternFlame",
        Vector3.new(1.05, 2.45, 0.82),
        CFrame.new(0, 5.65, -112) * CFrame.Angles(0, math.rad(18), 0),
        AMBER,
        Enum.Material.Neon,
        false
    )
    flame.Shape = Enum.PartType.Wedge
    local light = Instance.new("PointLight")
    light.Color = AMBER
    light.Brightness = 1.5
    light.Range = 30
    light.Shadows = true
    light.Parent = flame
    addBillboard(flame, "THE FIRST LANTERN", AMBER, 32)
    self._lantern = flame
    table.insert(self._meshPlacements, {
        assetId = "mesh_creator_first_lantern_a",
        fallbackKind = "placeholder",
        position = Vector3.new(0, 3, -112),
        scale = 1.25,
        yaw = math.rad(8),
        seed = 9314,
        swayTag = nil,
        parent = interactables,
        fallbackInstance = firstLanternFallback,
    })
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
    table.insert(self._meshPlacements, {
        assetId = "mesh_creator_wood_arch_a",
        fallbackKind = "asset_replacement",
        position = Vector3.new(0, 0, -148),
        scale = 1,
        yaw = 0,
        seed = 9910,
        swayTag = nil,
        parent = interactables,
        fallbackInstance = gate,
    })

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
    local workshopZ = -142
    local function workshopBay(centerX: number, title: string, accent: Color3)
        part(
            workshop,
            "WorkshopFloor",
            Vector3.new(27, 0.45, 14),
            CFrame.new(centerX, 0.22, workshopZ),
            Color3.fromRGB(73, 57, 42),
            Enum.Material.WoodPlanks
        )
        part(
            workshop,
            "WorkshopBackWall",
            Vector3.new(27, 7.4, 0.7),
            CFrame.new(centerX, 3.7, workshopZ - 6.65),
            BARK,
            Enum.Material.WoodPlanks
        )
        for side = -1, 1, 2 do
            part(
                workshop,
                "WorkshopSideWall",
                Vector3.new(0.7, 7.4, 14),
                CFrame.new(centerX + side * 13.15, 3.7, workshopZ),
                BARK,
                Enum.Material.WoodPlanks
            )
            part(
                workshop,
                "WorkshopFrontPost",
                Vector3.new(0.9, 8, 0.9),
                CFrame.new(centerX + side * 12.7, 4, workshopZ + 6.65),
                WET_BARK,
                Enum.Material.Wood
            )
        end
        part(
            workshop,
            "WorkshopFrontBeam",
            Vector3.new(27, 0.9, 0.9),
            CFrame.new(centerX, 7.45, workshopZ + 6.65),
            WET_BARK,
            Enum.Material.Wood
        )
        for slope = -1, 1, 2 do
            part(
                workshop,
                "WorkshopRoof",
                Vector3.new(29, 0.72, 8.4),
                CFrame.new(centerX, 8.3, workshopZ + slope * 3.55)
                    * CFrame.Angles(math.rad(slope * 8), 0, 0),
                Color3.fromRGB(42, 47, 43),
                Enum.Material.Slate
            )
        end
        part(
            workshop,
            "WorkshopShelf",
            Vector3.new(21, 0.4, 2.1),
            CFrame.new(centerX, 3.2, workshopZ - 5.25),
            Color3.fromRGB(91, 65, 45),
            Enum.Material.WoodPlanks
        )
        for supplyIndex = 1, 4 do
            local supply = part(
                workshop,
                "WorkshopSupply",
                Vector3.new(2.3, 1.4 + (supplyIndex % 2) * 0.5, 1.6),
                CFrame.new(centerX - 8.2 + supplyIndex * 3.3, 4.1, workshopZ - 5.2),
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
                CFrame.new(centerX + crateIndex * 9.5, 1.2, workshopZ - 4.1),
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
            CFrame.new(centerX, 6.5, workshopZ + 3.9),
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
        labelSign(workshop, CFrame.new(centerX, 5.4, workshopZ - 6.95), title)
    end
    workshopBay(-42, "ROOTWORKS", Color3.fromRGB(133, 176, 108))
    workshopBay(42, "OUTFITTER", AMBER)
    for index, centerX in { -42, 42 } do
        table.insert(self._meshPlacements, {
            assetId = "mesh_creator_market_stall_a",
            fallbackKind = "asset_replacement",
            position = Vector3.new(centerX, 0, workshopZ),
            scale = 1.15,
            yaw = 0,
            seed = 9920 + index,
            swayTag = nil,
            parent = interactables,
            fallbackInstance = if index == 1 then workshop else nil,
        })
    end

    local craftingFallback = Instance.new("Model")
    craftingFallback.Name = "CraftingDisplayFallback"
    craftingFallback.Parent = interactables
    local craftingBenches = {
        {
            id = self._runtimeIds.InteractionIds.CraftMeadowSatchel,
            recipeId = "recipe_meadow_satchel",
            label = "MEADOW SATCHEL",
            x = -48,
            color = Color3.fromRGB(133, 176, 108),
        },
        {
            id = self._runtimeIds.InteractionIds.CraftAmberCharm,
            recipeId = "recipe_amber_charm",
            label = "AMBER CHARM",
            x = 36,
            color = AMBER,
        },
        {
            id = self._runtimeIds.InteractionIds.CraftIronrootHood,
            recipeId = "recipe_ironroot_hood",
            label = "IRONROOT HOOD",
            x = -36,
            color = Color3.fromRGB(122, 148, 132),
        },
        {
            id = self._runtimeIds.InteractionIds.CraftBrambleBoots,
            recipeId = "recipe_bramble_boots",
            label = "BRAMBLE BOOTS",
            x = 48,
            color = Color3.fromRGB(142, 112, 84),
        },
    }
    for _, definition in craftingBenches do
        local display = Instance.new("Model")
        display.Name = "CraftingDisplay_" .. definition.recipeId
        display:SetAttribute("RecipeId", definition.recipeId)
        display:SetAttribute("DisplayKind", "physical_recipe_sample")
        display.Parent = craftingFallback
        local bench = part(
            display,
            "CraftingBench_" .. definition.recipeId,
            Vector3.new(6, 2.6, 6),
            CFrame.new(definition.x, 1.3, workshopZ),
            Color3.fromRGB(66, 70, 65),
            Enum.Material.Slate
        )
        bench.Transparency = 1
        bench.CanCollide = false
        bench.CastShadow = false
        part(
            display,
            "CraftingTableTop",
            Vector3.new(6.4, 0.55, 4.8),
            CFrame.new(definition.x, 3.15, workshopZ),
            Color3.fromRGB(91, 64, 44),
            Enum.Material.WoodPlanks
        )
        for side = -1, 1, 2 do
            for depth = -1, 1, 2 do
                part(
                    display,
                    "CraftingTableLeg",
                    Vector3.new(0.55, 3.15, 0.55),
                    CFrame.new(definition.x + side * 2.65, 1.57, workshopZ + depth * 1.85)
                        * CFrame.Angles(0, 0, math.rad(side * 3)),
                    WET_BARK,
                    Enum.Material.Wood
                )
            end
        end
        part(
            display,
            "CraftingWorkbenchApron",
            Vector3.new(5.4, 0.75, 0.42),
            CFrame.new(definition.x, 2.55, workshopZ + 2.18),
            Color3.fromRGB(68, 48, 36),
            Enum.Material.Wood,
            false
        )
        local marker = part(
            display,
            "CraftingBenchGlow",
            Vector3.new(2, 3.4, 2),
            CFrame.new(definition.x, 4.3, workshopZ),
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
        marker.Material = if definition.recipeId == "recipe_meadow_satchel"
                or definition.recipeId == "recipe_ironroot_hood"
            then Enum.Material.Fabric
            elseif definition.recipeId == "recipe_bramble_boots" then Enum.Material.Leather
            else Enum.Material.Glass
        marker.Transparency = 0.06
        if definition.recipeId == "recipe_meadow_satchel" then
            part(
                display,
                "SatchelFlap",
                Vector3.new(2.35, 0.32, 1.1),
                CFrame.new(definition.x, 4.72, workshopZ + 0.36) * CFrame.Angles(math.rad(18), 0, 0),
                Color3.fromRGB(103, 128, 84),
                Enum.Material.Fabric,
                false
            )
            for strapSide = -1, 1, 2 do
                part(
                    display,
                    "SatchelStrap",
                    Vector3.new(0.22, 2.4, 0.22),
                    CFrame.new(definition.x + strapSide * 1.05, 4.65, workshopZ - 0.2)
                        * CFrame.Angles(0, 0, math.rad(strapSide * 24)),
                    Color3.fromRGB(78, 58, 41),
                    Enum.Material.Fabric,
                    false
                )
            end
        elseif definition.recipeId == "recipe_amber_charm" then
            local charmRing = part(
                display,
                "AmberCharmRing",
                Vector3.new(0.32, 2.4, 2.4),
                CFrame.new(definition.x, 4.55, workshopZ) * CFrame.Angles(0, math.rad(90), 0),
                Color3.fromRGB(126, 97, 54),
                Enum.Material.Metal,
                false
            )
            charmRing.Shape = Enum.PartType.Cylinder
            part(
                display,
                "AmberCharmCord",
                Vector3.new(0.2, 1.7, 0.2),
                CFrame.new(definition.x, 5.8, workshopZ),
                Color3.fromRGB(73, 54, 38),
                Enum.Material.Fabric,
                false
            )
        elseif definition.recipeId == "recipe_ironroot_hood" then
            part(
                display,
                "HoodShoulders",
                Vector3.new(3.6, 0.55, 1.45),
                CFrame.new(definition.x, 3.82, workshopZ),
                Color3.fromRGB(75, 91, 81),
                Enum.Material.Fabric,
                false
            )
            part(
                display,
                "HoodStand",
                Vector3.new(0.34, 2.5, 0.34),
                CFrame.new(definition.x, 4.45, workshopZ),
                Color3.fromRGB(76, 55, 39),
                Enum.Material.Wood,
                false
            )
        else
            for bootSide = -1, 1, 2 do
                part(
                    display,
                    "BrambleBoot",
                    Vector3.new(0.92, 1.45, 1.9),
                    CFrame.new(definition.x + bootSide * 0.72, 4.05, workshopZ + 0.28)
                        * CFrame.Angles(0, math.rad(bootSide * 8), 0),
                    Color3.fromRGB(103, 76, 54),
                    Enum.Material.Leather,
                    false
                )
            end
        end
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
    for index, centerX in { -42, 42 } do
        table.insert(self._meshPlacements, {
            assetId = "mesh_creator_workbench_a",
            fallbackKind = "asset_replacement",
            position = Vector3.new(centerX, 0, workshopZ + 1.5),
            scale = 0.95,
            yaw = math.pi,
            seed = 9930 + index,
            swayTag = nil,
            parent = interactables,
            fallbackInstance = if index == 1 then craftingFallback else nil,
        })
    end

    local archiveX = -20
    local archiveZ = -132
    local archiveFallback = Instance.new("Model")
    archiveFallback.Name = "ArchiveVisualFallback"
    archiveFallback.Parent = interactables
    local archive = part(
        archiveFallback,
        "GreenwardArchive",
        Vector3.new(9, 6, 1),
        CFrame.new(archiveX, 3, archiveZ),
        BARK,
        Enum.Material.WoodPlanks
    )
    for side = -1, 1, 2 do
        part(
            archiveFallback,
            "ArchivePost",
            Vector3.new(0.75, 8.2, 0.75),
            CFrame.new(archiveX + side * 5.1, 4.1, archiveZ - 0.1)
                * CFrame.Angles(0, 0, math.rad(side * 3)),
            WET_BARK,
            Enum.Material.Wood
        )
        part(
            archiveFallback,
            "ArchiveShelf",
            Vector3.new(3.8, 0.42, 1.9),
            CFrame.new(archiveX + side * 2.2, 1.65, archiveZ + 0.75),
            Color3.fromRGB(91, 65, 44),
            Enum.Material.WoodPlanks,
            false
        )
    end
    part(
        archiveFallback,
        "ArchiveCanopy",
        Vector3.new(12.2, 0.62, 4.1),
        CFrame.new(archiveX, 7.5, archiveZ + 0.6) * CFrame.Angles(math.rad(-6), 0, 0),
        Color3.fromRGB(47, 53, 48),
        Enum.Material.Slate,
        false
    )
    WorldSignBuilder.dressNoticeBoard(archive, "GREENWARD ARCHIVE · FIELD BOOK", CREAM, {
        "field_botany",
        "evacuation_route",
        "bramble_hazard",
        "lantern_maintenance",
        "supply_inventory",
    })
    table.insert(self._meshPlacements, {
        assetId = "mesh_creator_notice_board_a",
        fallbackKind = "asset_replacement",
        position = Vector3.new(archiveX, 0, archiveZ),
        scale = 1.05,
        yaw = 0,
        seed = 9940,
        swayTag = nil,
        parent = interactables,
        fallbackInstance = archiveFallback,
    })
    self:_registerInteraction(
        archive,
        self._runtimeIds.InteractionIds.QuestBoard,
        self._runtimeIds.Actions.OpenFieldBook,
        "OPEN",
        "Field Book",
        nil
    )

    local masteryGrove = Instance.new("Folder")
    masteryGrove.Name = "GreenwardMasteryGrove"
    masteryGrove.Parent = interactables
    local professionAltars = {
        {
            center = Vector3.new(-78, 0, -76),
            color = FOXFIRE,
            name = "SCOUT",
            paths = {
                { id = "specialization_pathfinder", name = "PATHFINDER" },
                { id = "specialization_foxfire_trapper", name = "FOXFIRE TRAPPER" },
                { id = "specialization_trailseer", name = "TRAILSEER" },
            },
        },
        {
            center = Vector3.new(78, 0, -76),
            color = Color3.fromRGB(112, 151, 119),
            name = "WARDEN",
            paths = {
                { id = "specialization_bulwark", name = "BULWARK" },
                { id = "specialization_greenkeeper", name = "GREENKEEPER" },
                { id = "specialization_oathbound", name = "OATHBOUND" },
            },
        },
        {
            center = Vector3.new(-78, 0, -168),
            color = Color3.fromRGB(191, 137, 73),
            name = "ENGINEER",
            paths = {
                { id = "specialization_lamplighter", name = "LAMPLIGHTER" },
                { id = "specialization_rootwright", name = "ROOTWRIGHT" },
                { id = "specialization_salvager", name = "SALVAGER" },
            },
        },
        {
            center = Vector3.new(78, 0, -168),
            color = Color3.fromRGB(176, 108, 112),
            name = "MEDIC",
            paths = {
                { id = "specialization_dawnmender", name = "DAWNMENDER" },
                { id = "specialization_wayhome_tender", name = "WAYHOME TENDER" },
                { id = "specialization_brightcap_herbalist", name = "BRIGHTCAP HERBALIST" },
            },
        },
    }
    local authoredInteractionIds = {}
    local authoredInteractionCount = 0
    for _, altar in professionAltars do
        for _, path in altar.paths do
            local interactionId = "mastery_" .. path.id
            assert(
                authoredInteractionIds[interactionId] == nil,
                "duplicate authored mastery interaction ID: " .. interactionId
            )
            authoredInteractionIds[interactionId] = true
            authoredInteractionCount += 1
        end
    end
    assert(
        authoredInteractionCount == #self._runtimeIds.ProfessionSpecializationInteractionIds,
        "mastery grove and runtime interaction catalogs differ in size"
    )
    for _, interactionId in self._runtimeIds.ProfessionSpecializationInteractionIds do
        assert(
            authoredInteractionIds[interactionId] == true,
            "mastery grove is missing runtime interaction ID: " .. interactionId
        )
    end
    for _, altar in professionAltars do
        local dais = part(
            masteryGrove,
            altar.name .. "MasteryDais",
            Vector3.new(13, 0.8, 8),
            CFrame.new(altar.center + Vector3.new(0, 0.4, 0)),
            Color3.fromRGB(62, 64, 57),
            Enum.Material.Slate
        )
        for ring = 1, 2 do
            local rootRing = part(
                masteryGrove,
                altar.name .. "RootRing",
                Vector3.new(13.6 + ring, 0.28, 8.6 + ring),
                CFrame.new(altar.center + Vector3.new(0, 0.7 + ring * 0.12, 0)),
                if ring == 1 then BARK else MOSS,
                if ring == 1 then Enum.Material.Wood else Enum.Material.Ground,
                false
            )
            rootRing.CanQuery = false
        end
        labelSign(
            masteryGrove,
            CFrame.new(altar.center + Vector3.new(0, 4.8, 3.7)) * CFrame.Angles(0, math.pi, 0),
            altar.name .. " MASTERY"
        )
        for pathIndex, path in altar.paths do
            local xOffset = (pathIndex - 2) * 3.7
            local stone = part(
                masteryGrove,
                altar.name .. "PathStone_" .. path.id,
                Vector3.new(2.6, 3.8, 2.6),
                CFrame.new(altar.center + Vector3.new(xOffset, 2.55, -0.5))
                    * CFrame.Angles(
                        math.rad(pathIndex == 2 and 2 or -3),
                        0,
                        math.rad(xOffset * 0.6)
                    ),
                if pathIndex == 2 then altar.color else Color3.fromRGB(76, 82, 75),
                Enum.Material.Slate
            )
            local crest = part(
                masteryGrove,
                altar.name .. "PathCrest_" .. path.id,
                Vector3.new(1.15, 1.15, 0.22),
                stone.CFrame * CFrame.new(0, 0.45, -1.38),
                altar.color,
                Enum.Material.Glass,
                false
            )
            crest.Shape = Enum.PartType.Ball
            crest.Transparency = 0.1
            addBillboard(stone, path.name, altar.color)
            local interactionId =
                self._runtimeIds.ProfessionSpecializationInteractionIdBySpecialization[path.id]
            assert(interactionId ~= nil, "missing mastery runtime ID for " .. path.id)
            self:_registerInteraction(
                stone,
                interactionId,
                self._runtimeIds.Actions.SelectProfessionSpecialization,
                "CHOOSE PATH",
                path.name,
                path.id,
                1.1
            )
        end
        dais:SetAttribute("ProfessionId", "profession_" .. string.lower(altar.name))
        table.insert(self._meshPlacements, {
            assetId = if altar.name == "ENGINEER"
                then "mesh_creator_workbench_a"
                else "mesh_creator_stump_a",
            fallbackKind = "asset_dressing",
            position = altar.center + Vector3.new(0, 0.85, 2.1),
            scale = if altar.name == "ENGINEER" then 0.58 else 0.44,
            yaw = math.rad(
                if altar.name == "SCOUT" then -11 elseif altar.name == "MEDIC" then 14 else 4
            ),
            seed = 9970 + #altar.name,
            swayTag = nil,
            parent = masteryGrove,
            fallbackInstance = nil,
            profileScale = if altar.name == "WARDEN"
                then Vector3.new(1.12, 0.92, 0.88)
                else Vector3.one,
        })
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
    world:SetAttribute("WorldVersion", "emberhollow-adaptive-music-v27")
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
    self:setTownCondition(self._townCondition)

    world:SetAttribute("Ready", true)

    -- Only after the world is playable. Optional private assets and distant
    -- terrain can yield without delaying ArrivalSpawn.
    self:_buildMeshDressing()
    self:_buildDistantScenery()
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
        worldVersion = "emberhollow-adaptive-music-v27",
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
        local targetCFrame = CFrame.new(BARRICADE_CENTER + Vector3.new(index * 1.8, height / 2, 0))
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
        local targetCFrame = CFrame.new(BARRICADE_CENTER + Vector3.new(0, 2 + level * 2.2, 0.7))
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
                CFrame.new(BARRICADE_CENTER + Vector3.new(0, 0.18, 0))
                    * CFrame.Angles(0, 0, math.rad(90)),
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

function WorldService.showProfessionAbility(
    self: WorldService,
    player: Player,
    professionId: string,
    effectRadius: number,
    activeSeconds: number
)
    local world = self._world
    local visual = self._professionAbilityVisuals.get(professionId)
    local character = player.Character
    local root = if character == nil then nil else character:FindFirstChild("HumanoidRootPart")
    if world == nil or visual == nil or root == nil or not root:IsA("BasePart") then
        return
    end

    local effects = world:FindFirstChild("ProfessionAbilityEffects")
    if effects == nil then
        effects = Instance.new("Folder")
        effects.Name = "ProfessionAbilityEffects"
        effects.Parent = world
    end
    local effectName = string.format("Ability_%d_%s", player.UserId, professionId)
    local previous = effects:FindFirstChild(effectName)
    if previous ~= nil then
        previous:Destroy()
    end

    local model = Instance.new("Model")
    model.Name = effectName
    model:SetAttribute("ProfessionId", professionId)
    model:SetAttribute("Motif", visual.motif)
    model:SetAttribute("OwnerUserId", player.UserId)
    model.Parent = effects

    local color = Color3.fromRGB(visual.color[1], visual.color[2], visual.color[3])
    local accent = Color3.fromRGB(visual.accent[1], visual.accent[2], visual.accent[3])
    local origin = if professionId == "profession_engineer"
        then self:lanternPosition() - Vector3.new(0, 5.75, 0)
        else root.Position - Vector3.new(0, 2.8, 0)
    local radius = math.clamp(math.max(effectRadius, visual.minimumRadius), 8, 24)
    local pulse = part(
        model,
        "AbilityGroundSignal",
        Vector3.new(0.12, 2, 2),
        CFrame.new(origin + Vector3.new(0, 0.16, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        color,
        Enum.Material.Glass,
        false
    )
    pulse.Shape = Enum.PartType.Cylinder
    pulse.Transparency = 0.3
    pulse.CastShadow = false
    TweenService:Create(
        pulse,
        TweenInfo.new(visual.pulseLifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = Vector3.new(0.12, radius * 2, radius * 2), Transparency = 1 }
    ):Play()

    if visual.motif == "foxfire_compass" then
        for index = 1, 4 do
            local angle = math.rad((index - 1) * 90)
            local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
            local marker = part(
                model,
                "FoxfireCompassNeedle_" .. tostring(index),
                Vector3.new(0.35, 0.18, 4.6),
                CFrame.lookAt(
                    origin + direction * 3.1 + Vector3.new(0, 0.22, 0),
                    origin + direction * 8 + Vector3.new(0, 0.22, 0)
                ),
                if index == 1 then accent else color,
                Enum.Material.Neon,
                false
            )
            marker.Transparency = 0.12
        end
    elseif visual.motif == "root_ward" then
        for index = 1, 6 do
            local angle = math.rad(index * 60)
            local stake = part(
                model,
                "WardenRootStake_" .. tostring(index),
                Vector3.new(0.42, 3.4, 0.42),
                CFrame.new(origin + Vector3.new(math.cos(angle) * 4.4, 1.3, math.sin(angle) * 4.4))
                    * CFrame.Angles(math.rad(-8), angle, math.rad(index % 2 == 0 and 10 or -10)),
                if index % 2 == 0 then color else accent,
                Enum.Material.Wood,
                false
            )
            stake.Transparency = 0.08
        end
        local existingGuard = character:FindFirstChild("LastLightWardenGuardVisual")
        if existingGuard ~= nil then
            existingGuard:Destroy()
        end
        local guard = Instance.new("Highlight")
        guard.Name = "LastLightWardenGuardVisual"
        guard.Adornee = character
        guard.DepthMode = Enum.HighlightDepthMode.Occluded
        guard.FillColor = color
        guard.FillTransparency = 0.78
        guard.OutlineColor = accent
        guard.OutlineTransparency = 0.12
        guard.Parent = character
        task.delay(math.clamp(activeSeconds, 0.5, 12), function()
            if guard.Parent ~= nil then
                guard:Destroy()
            end
        end)
    elseif visual.motif == "rootline_gear" then
        for index = 1, 6 do
            local angle = math.rad(index * 60)
            local tooth = part(
                model,
                "RootlineGearTooth_" .. tostring(index),
                Vector3.new(0.8, 0.34, 2.7),
                CFrame.new(origin + Vector3.new(math.cos(angle) * 5.8, 0.28, math.sin(angle) * 5.8))
                    * CFrame.Angles(0, -angle, 0),
                if index % 2 == 0 then color else accent,
                Enum.Material.Metal,
                false
            )
            tooth.Transparency = 0.06
        end
    elseif visual.motif == "brightcap_bloom" then
        for index = 1, 6 do
            local angle = math.rad(index * 60)
            local bloomPosition = origin
                + Vector3.new(math.cos(angle) * 4.5, 0.55, math.sin(angle) * 4.5)
            part(
                model,
                "BrightcapStem_" .. tostring(index),
                Vector3.new(0.24, 1.2, 0.24),
                CFrame.new(bloomPosition),
                accent,
                Enum.Material.Grass,
                false
            )
            local cap = part(
                model,
                "BrightcapBloom_" .. tostring(index),
                Vector3.new(1.3, 0.55, 1.3),
                CFrame.new(bloomPosition + Vector3.new(0, 0.72, 0)),
                color,
                Enum.Material.Glass,
                false
            )
            cap.Shape = Enum.PartType.Ball
            cap.Transparency = 0.12
        end
    end

    task.delay(visual.pulseLifetime + 0.2, function()
        if model.Parent ~= nil then
            model:Destroy()
        end
    end)
end

function WorldService.setEngineerBrace(self: WorldService, snapshot: any, absorbed: number?)
    local world = self._world
    if world == nil then
        return
    end
    local active = type(snapshot) == "table" and snapshot.active == true
    local current = self._engineerBraceModel
    if not active then
        if current ~= nil and current.Parent ~= nil then
            current:Destroy()
        end
        self._engineerBraceModel = nil
        return
    end

    local revision = math.max(0, math.floor(tonumber(snapshot.revision) or 0))
    if
        current == nil
        or current.Parent == nil
        or current:GetAttribute("BraceRevision") ~= revision
    then
        if current ~= nil and current.Parent ~= nil then
            current:Destroy()
        end
        current = Instance.new("Model")
        current.Name = "EngineerRootlineBrace"
        current:SetAttribute("BraceRevision", revision)
        current.Parent = world
        self._engineerBraceModel = current

        local center = self:lanternPosition() - Vector3.new(0, 5.75, 0)
        for index = 1, 4 do
            local angle = math.rad(45 + (index - 1) * 90)
            local railAngle = angle - math.rad(45)
            part(
                current,
                "RootlineGroundRail_" .. tostring(index),
                Vector3.new(0.42, 0.28, 10.8),
                CFrame.new(
                    center
                        + Vector3.new(math.cos(railAngle) * 5.45, 0.24, math.sin(railAngle) * 5.45)
                ) * CFrame.Angles(0, -railAngle, 0),
                Color3.fromRGB(191, 137, 73),
                Enum.Material.Metal,
                false
            )
            part(
                current,
                "RootlineBraceStrut_" .. tostring(index),
                Vector3.new(0.62, 4.8, 0.62),
                CFrame.new(center + Vector3.new(math.cos(angle) * 5.2, 2.1, math.sin(angle) * 5.2))
                    * CFrame.Angles(math.rad(12), -angle, math.rad(index % 2 == 0 and 12 or -12)),
                Color3.fromRGB(91, 62, 40),
                Enum.Material.Wood,
                false
            )
        end
        local core = part(
            current,
            "RootlineCapacityCore",
            Vector3.new(1.8, 1.8, 1.8),
            CFrame.new(center + Vector3.new(5.6, 1.15, 0)),
            Color3.fromRGB(255, 206, 112),
            Enum.Material.Glass,
            false
        )
        core.Shape = Enum.PartType.Ball
        core.Transparency = 0.12
        local light = Instance.new("PointLight")
        light.Color = core.Color
        light.Brightness = 1.15
        light.Range = 13
        light.Parent = core

        local delaySeconds = math.clamp(tonumber(snapshot.remainingSeconds) or 0, 0.1, 30)
        task.delay(delaySeconds + 0.1, function()
            if
                self._engineerBraceModel == current
                and current.Parent ~= nil
                and current:GetAttribute("BraceRevision") == revision
            then
                current:Destroy()
                self._engineerBraceModel = nil
            end
        end)
    end

    current:SetAttribute("Capacity", math.max(0, math.floor(tonumber(snapshot.capacity) or 0)))
    current:SetAttribute(
        "MaxCapacity",
        math.max(1, math.floor(tonumber(snapshot.maxCapacity) or 1))
    )
    current:SetAttribute(
        "OwnerUserId",
        math.max(0, math.floor(tonumber(snapshot.ownerUserId) or 0))
    )
    current:SetAttribute("ActiveUntil", tonumber(snapshot.activeUntil) or 0)
    local core = current:FindFirstChild("RootlineCapacityCore")
    if core ~= nil and core:IsA("BasePart") then
        local ratio = math.clamp(
            (tonumber(snapshot.capacity) or 0) / math.max(1, tonumber(snapshot.maxCapacity) or 1),
            0,
            1
        )
        TweenService
            :Create(core, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Color = Color3.fromRGB(255, 112, 78):Lerp(Color3.fromRGB(255, 206, 112), ratio),
                Size = Vector3.new(1.05, 1.05, 1.05):Lerp(Vector3.new(1.8, 1.8, 1.8), ratio),
            })
            :Play()
    end
    if (absorbed or 0) > 0 then
        local center = self:lanternPosition() - Vector3.new(0, 5.6, 0)
        local impact = part(
            current,
            "RootlineImpactPulse",
            Vector3.new(0.16, 14, 14),
            CFrame.new(center + Vector3.new(0, 0.22, 0)) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(255, 206, 112),
            Enum.Material.Neon,
            false
        )
        impact.Shape = Enum.PartType.Cylinder
        impact.Transparency = 0.16
        impact.CastShadow = false
        TweenService:Create(
            impact,
            TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = Vector3.new(0.16, 20, 20), Transparency = 1 }
        ):Play()
        task.delay(0.45, function()
            if impact.Parent ~= nil then
                impact:Destroy()
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
    local targetSize = Vector3.new(0.62, 1.35, 0.48):Lerp(Vector3.new(1.05, 2.45, 0.82), strength)

    TweenService:Create(
        flame,
        TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Color = targetColor, Size = targetSize }
    ):Play()
    local light = flame:FindFirstChildOfClass("PointLight")
    if light ~= nil then
        TweenService
            :Create(light, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Brightness = 0.45 + strength * 1.05,
                Color = targetColor,
                Range = 16 + strength * 14,
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

function WorldService.showTownGuardRecovery(self: WorldService, players: { Player }, result: any)
    local world = self._world
    local flame = self._lantern
    if world == nil or flame == nil or #players < 1 then
        return
    end

    local previous = world:FindFirstChild("TownGuardLastStand")
    if previous ~= nil then
        previous:Destroy()
    end

    world:SetAttribute("LastStandNight", result.nightNumber)
    world:SetAttribute("LastStandPartySize", #players)
    world:SetAttribute("LastStandLanternSpent", result.lanternSpent or result.lanternCost or 0)

    local rally = Instance.new("Model")
    rally.Name = "TownGuardLastStand"
    rally:SetAttribute("NightNumber", result.nightNumber)
    rally:SetAttribute("PartySize", #players)
    rally.Parent = world

    local ground = flame.Position - Vector3.new(0, 5.5, 0)
    for index = 1, 4 do
        local angle = math.rad(45 + (index - 1) * 90)
        local offset = Vector3.new(math.cos(angle) * 7.4, 0, math.sin(angle) * 7.4)
        local postAt = ground + offset
        local post = part(
            rally,
            "WatchRallyPost",
            Vector3.new(0.45, 4.8, 0.45),
            CFrame.new(postAt + Vector3.new(0, 2.4, 0))
                * CFrame.Angles(0, -angle, math.rad(if index % 2 == 0 then 5 else -5)),
            WET_BARK,
            Enum.Material.Wood,
            false
        )
        post.Transparency = 0.08
        local pennant = part(
            rally,
            "WatchRallyPennant",
            Vector3.new(2.4, 1.15, 0.16),
            CFrame.new(postAt + Vector3.new(0.95 * math.cos(angle), 3.7, 0.95 * math.sin(angle)))
                * CFrame.Angles(0, -angle, math.rad(-8)),
            AMBER,
            Enum.Material.Fabric,
            false
        )
        pennant.Transparency = 0.08
        pennant.CastShadow = false
        TweenService:Create(
            pennant,
            TweenInfo.new(1.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Transparency = 1, Position = pennant.Position + Vector3.new(0, 1.2, 0) }
        ):Play()
    end

    for _, signal in self._nightDefenseSignals do
        if signal.Parent ~= nil then
            TweenService
                :Create(
                    signal,
                    TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        Color = AMBER,
                        Transparency = if signal:GetAttribute("SignalRole") == "fire"
                            then 0
                            else 0.12,
                    }
                )
                :Play()
            local signalLight = signal:FindFirstChild("WatchSignalLight")
            if signalLight ~= nil and signalLight:IsA("PointLight") then
                signalLight.Color = AMBER
                signalLight.Brightness = 3.4
            end
        end
    end

    for _, player in players do
        local character = player.Character
        if character ~= nil and character.Parent ~= nil then
            local highlight = Instance.new("Highlight")
            highlight.Name = "LastLightTownGuardRecovery"
            highlight.Adornee = character
            highlight.DepthMode = Enum.HighlightDepthMode.Occluded
            highlight.FillColor = AMBER
            highlight.FillTransparency = 0.72
            highlight.OutlineColor = CREAM
            highlight.OutlineTransparency = 0.08
            highlight.Parent = character
            task.delay(math.clamp(tonumber(result.recoveryWardSeconds) or 5, 0.5, 8), function()
                if highlight.Parent ~= nil then
                    highlight:Destroy()
                end
            end)
        end
    end

    task.delay(0.7, function()
        if world.Parent ~= nil then
            self:_setNightDefenseState(
                if self._breachActive then "breach" elseif self._night then "night" else "day"
            )
        end
    end)
    task.delay(1.6, function()
        if rally.Parent ~= nil then
            rally:Destroy()
        end
    end)
end

local function buildTownConsequenceLandscape(
    parent: Instance,
    consequence: any,
    assetParent: Instance,
    meshPlacements: { MeshPlacement }
)
    local center = Vector3.new(96, 0, -164)
    local landscapeKind = tostring(consequence.landscapeKind or "seed_ground")
    local memorialKind = tostring(consequence.memorialKind or "unmarked_stone")
    local growthStage = math.clamp(math.floor(tonumber(consequence.growthStage) or 0), 0, 3)

    local ground = part(
        parent,
        "GreenwardGround",
        Vector3.new(42, 0.28, 34),
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
        for postIndex = -1, 1 do
            part(
                parent,
                "GreenwardFencePost",
                Vector3.new(0.48, 2.6, 0.48),
                CFrame.new(center + Vector3.new(side * 20.5, 1.3, postIndex * 13.5))
                    * CFrame.Angles(0, 0, math.rad(side * postIndex * 3)),
                borderColor,
                Enum.Material.Wood,
                false
            )
        end
        for railY = 0.8, 1.75, 0.95 do
            part(
                parent,
                "GreenwardFenceRail",
                Vector3.new(0.32, 0.32, 27),
                CFrame.new(center + Vector3.new(side * 20.5, railY, 0))
                    * CFrame.Angles(math.rad(side * 1.5), 0, 0),
                borderColor,
                Enum.Material.Wood,
                false
            )
        end
    end

    local function cropRow(x: number, z: number, accent: Color3)
        part(
            parent,
            "CultivatedBed",
            Vector3.new(6.6, 0.3, 8.5),
            CFrame.new(center + Vector3.new(x, 0.28, z)),
            Color3.fromRGB(92, 67, 42),
            Enum.Material.Mud,
            false
        )
        for furrow = -1, 1 do
            part(
                parent,
                "CultivatedFurrow",
                Vector3.new(0.32, 0.12, 7.7),
                CFrame.new(center + Vector3.new(x + furrow * 1.7, 0.49, z)),
                Color3.fromRGB(54, 42, 31),
                Enum.Material.Ground,
                false
            )
        end
        for cropIndex = -1, 1 do
            local stem = part(
                parent,
                "CropStem",
                Vector3.new(0.24, 1.15 + growthStage * 0.12, 0.24),
                CFrame.new(center + Vector3.new(x + cropIndex * 1.65, 1.05, z)),
                Color3.fromRGB(71, 123, 63),
                Enum.Material.Grass,
                false
            )
            stem.CanQuery = false
            for leafSide = -1, 1, 2 do
                local leaf = part(
                    parent,
                    "HarvestCropLeaf",
                    Vector3.new(0.78, 0.18, 0.48),
                    stem.CFrame
                        * CFrame.new(leafSide * 0.34, 0.38 + leafSide * 0.08, 0)
                        * CFrame.Angles(0, math.rad(leafSide * 18), math.rad(-leafSide * 22)),
                    if leafSide < 0 then accent else Color3.fromRGB(82, 131, 65),
                    Enum.Material.LeafyGrass,
                    false
                )
                leaf.Shape = Enum.PartType.Wedge
                leaf.CanQuery = false
            end
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
        cropRow(-9, -5.5, Color3.fromRGB(149, 122, 66))
        cropRow(0, -5.5, Color3.fromRGB(113, 143, 71))
        cropRow(9, -5.5, Color3.fromRGB(157, 102, 61))
        for stakeIndex = -1, 1 do
            local stake = part(
                parent,
                "SeedlingRowStake",
                Vector3.new(0.34, 2.4, 0.34),
                CFrame.new(center + Vector3.new(stakeIndex * 9, 1.2, 6))
                    * CFrame.Angles(0, 0, math.rad(stakeIndex * 4)),
                BARK,
                Enum.Material.Wood,
                false
            )
            part(
                parent,
                "SeedlingRowMarker",
                Vector3.new(2.4, 0.9, 0.22),
                stake.CFrame * CFrame.new(0, 0.55, -0.22),
                Color3.fromRGB(126, 96, 58),
                Enum.Material.WoodPlanks,
                false
            )
        end
    end

    local memorialCenter = center + Vector3.new(0, 0, 14)
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
    WorldSignBuilder.dressBoard(
        sign,
        string.format("TIER %d · %s", consequence.tier, consequence.title),
        CREAM,
        "consequence"
    )
    sign:SetAttribute("Consequence", consequence.detail)

    if landscapeKind == "living_grove" then
        local groveOffsets = {
            Vector3.new(-10, 0, -7),
            Vector3.new(0, 0, -4),
            Vector3.new(10, 0, -7),
            Vector3.new(-7, 0, 7),
            Vector3.new(8, 0, 7),
        }
        for index, offset in groveOffsets do
            table.insert(meshPlacements, {
                assetId = "mesh_broadleaf_hero_a",
                fallbackKind = "asset_replacement",
                position = center + offset,
                scale = 0.48 + index * 0.025,
                yaw = math.rad(index * 51),
                seed = 10000 + index,
                swayTag = nil,
                parent = assetParent,
                fallbackInstance = if index == 1 then parent else nil,
            })
        end
    else
        table.insert(meshPlacements, {
            assetId = "mesh_creator_field_rows_a",
            fallbackKind = "asset_replacement",
            position = center,
            scale = 1.12,
            yaw = 0,
            seed = 10010,
            swayTag = nil,
            parent = assetParent,
            fallbackInstance = parent,
        })
        if landscapeKind == "cultivated_fields" or landscapeKind == "community_orchard" then
            for index, offset in
                {
                    Vector3.new(-10, 0, -6),
                    Vector3.new(0, 0, -5),
                    Vector3.new(10, 0, -6),
                }
            do
                table.insert(meshPlacements, {
                    assetId = "mesh_creator_wheat_cluster_a",
                    fallbackKind = "asset_dressing",
                    position = center + offset,
                    scale = 1,
                    yaw = math.rad(index * 37),
                    seed = 10020 + index,
                    swayTag = nil,
                    parent = assetParent,
                    fallbackInstance = nil,
                })
            end
        end
        if landscapeKind == "community_orchard" then
            for index, offset in
                { Vector3.new(-10, 0, 7), Vector3.new(0, 0, 8), Vector3.new(10, 0, 7) }
            do
                table.insert(meshPlacements, {
                    assetId = "mesh_broadleaf_hero_a",
                    fallbackKind = "asset_dressing",
                    position = center + offset,
                    scale = 0.4,
                    yaw = math.rad(index * 63),
                    seed = 10030 + index,
                    swayTag = nil,
                    parent = assetParent,
                    fallbackInstance = nil,
                })
            end
            table.insert(meshPlacements, {
                assetId = "mesh_creator_picnic_table_a",
                fallbackKind = "asset_dressing",
                position = center,
                scale = 0.9,
                yaw = math.rad(90),
                seed = 10034,
                swayTag = nil,
                parent = assetParent,
                fallbackInstance = nil,
            })
        end
    end
    for index, spec in
        {
            { position = center + Vector3.new(-20, 0, -10), yaw = math.rad(90) },
            { position = center + Vector3.new(-20, 0, 0), yaw = math.rad(90) },
            { position = center + Vector3.new(-20, 0, 10), yaw = math.rad(90) },
            { position = center + Vector3.new(20, 0, -10), yaw = math.rad(90) },
            { position = center + Vector3.new(20, 0, 0), yaw = math.rad(90) },
            { position = center + Vector3.new(20, 0, 10), yaw = math.rad(90) },
            { position = center + Vector3.new(-12, 0, -16), yaw = 0 },
            { position = center + Vector3.new(0, 0, -16), yaw = 0 },
            { position = center + Vector3.new(12, 0, -16), yaw = 0 },
            { position = center + Vector3.new(-12, 0, 16), yaw = 0 },
            { position = center + Vector3.new(0, 0, 16), yaw = 0 },
            { position = center + Vector3.new(12, 0, 16), yaw = 0 },
        }
    do
        table.insert(meshPlacements, {
            assetId = "mesh_creator_rustic_fence_a",
            fallbackKind = "asset_dressing",
            position = spec.position,
            scale = 1,
            yaw = spec.yaw,
            seed = 10040 + index,
            swayTag = nil,
            parent = assetParent,
            fallbackInstance = nil,
        })
    end
    table.insert(meshPlacements, {
        assetId = "mesh_creator_stump_a",
        fallbackKind = "asset_dressing",
        position = memorialCenter,
        scale = 0.82,
        yaw = math.rad(-11),
        seed = 10060,
        swayTag = nil,
        parent = assetParent,
        fallbackInstance = nil,
    })
    table.insert(meshPlacements, {
        assetId = "mesh_creator_forest_sign_a",
        fallbackKind = "asset_dressing",
        position = center + Vector3.new(0, 0, -15.2),
        scale = 1.1,
        yaw = 0,
        seed = 10061,
        swayTag = nil,
        parent = assetParent,
        fallbackInstance = nil,
    })
    parent:SetAttribute("LandscapeKind", landscapeKind)
    parent:SetAttribute("MemorialKind", memorialKind)
    parent:SetAttribute("GrowthStage", growthStage)
end

local function buildTownProgressionBuildings(
    parent: Instance,
    consequence: any,
    runtimeIds: any,
    assetParent: Instance,
    meshPlacements: { MeshPlacement }
): { [string]: any }
    local stages = if type(consequence.buildingStages) == "table"
        then consequence.buildingStages
        else {}
    local residents: { [string]: any } = {}

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
        for tarpSide = -1, 1, 2 do
            local tarp = part(
                model,
                "BuilderTarp",
                Vector3.new(size.X * 0.72, 0.12, size.Z * 0.36),
                CFrame.new(center + Vector3.new(0, 7.3, tarpSide * size.Z * 0.16))
                    * CFrame.Angles(math.rad(tarpSide * 12), 0, math.rad(tarpSide * 1.5)),
                if tarpSide < 0 then Color3.fromRGB(91, 107, 82) else Color3.fromRGB(111, 121, 91),
                Enum.Material.Fabric,
                false
            )
            tarp.Transparency = 0.08
        end
        local materials = Instance.new("Model")
        materials.Name = "BuilderMaterials"
        materials.Parent = model
        for lumberIndex = 1, 4 do
            part(
                materials,
                "ConstructionLumber",
                Vector3.new(size.X * 0.38, 0.42, 0.72),
                CFrame.new(
                    center + Vector3.new(-size.X * 0.23, 0.55 + lumberIndex * 0.36, size.Z * 0.34)
                ) * CFrame.Angles(0, math.rad((lumberIndex % 2) * 2), 0),
                if lumberIndex % 2 == 0 then BARK else WET_BARK,
                Enum.Material.WoodPlanks,
                false
            )
        end
        for stoneIndex = 1, 4 do
            local row = math.floor((stoneIndex - 1) / 2)
            part(
                materials,
                "ConstructionStone",
                Vector3.new(2.3, 1.05, 1.7),
                CFrame.new(
                    center
                        + Vector3.new(
                            size.X * 0.3 + ((stoneIndex - 1) % 2) * 2.5,
                            0.55 + row * 1.05,
                            size.Z * 0.3
                        )
                )
                    * CFrame.Angles(0, math.rad(stoneIndex * 7), math.rad((stoneIndex % 2) * 2)),
                if stoneIndex % 2 == 0
                    then Color3.fromRGB(83, 87, 82)
                    else Color3.fromRGB(68, 73, 70),
                Enum.Material.Cobblestone,
                false
            )
        end
        local sawhorse = part(
            materials,
            "BuilderSawhorse",
            Vector3.new(5.2, 0.5, 1.2),
            CFrame.new(center + Vector3.new(0, 2.45, -size.Z * 0.3)),
            Color3.fromRGB(99, 70, 46),
            Enum.Material.WoodPlanks,
            false
        )
        for side = -1, 1, 2 do
            for depth = -1, 1, 2 do
                part(
                    materials,
                    "BuilderSawhorseLeg",
                    Vector3.new(0.35, 2.2, 0.35),
                    sawhorse.CFrame
                        * CFrame.new(side * 1.9, -1.15, depth * 0.35)
                        * CFrame.Angles(0, 0, math.rad(side * 9)),
                    WET_BARK,
                    Enum.Material.Wood,
                    false
                )
            end
        end
        local sign = part(
            model,
            "ConstructionSign",
            Vector3.new(8.5, 2.2, 0.45),
            CFrame.new(center + Vector3.new(0, 2.5, -(size.Z * 0.5 + 0.5))),
            BARK,
            Enum.Material.WoodPlanks,
            false
        )
        WorldSignBuilder.dressBoard(sign, displayName .. " · PLANNED", CREAM, "construction")
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
        for sideX = -1, 1, 2 do
            for sideZ = -1, 1, 2 do
                part(
                    model,
                    "BuildingCornerPost",
                    Vector3.new(0.72, wallHeight + 0.5, 0.72),
                    CFrame.new(
                        center
                            + Vector3.new(
                                sideX * (halfX - 0.2),
                                wallHeight * 0.5,
                                sideZ * (halfZ - 0.2)
                            )
                    ) * CFrame.Angles(0, 0, math.rad(sideX * sideZ * 1.5)),
                    WET_BARK,
                    Enum.Material.Wood,
                    false
                )
            end
        end
        part(
            model,
            "DoorHeader",
            Vector3.new(5, 1.1, 0.85),
            CFrame.new(center + Vector3.new(0, wallHeight - 0.55, -halfZ + 0.3)),
            WET_BARK,
            Enum.Material.Wood
        )
        for roofSide = -1, 1, 2 do
            part(
                model,
                "RoofPlane",
                Vector3.new(size.X + 2.2, 0.42, size.Z * 0.62),
                CFrame.new(center + Vector3.new(0, wallHeight + 1.25, roofSide * (size.Z * 0.25)))
                    * CFrame.Angles(math.rad(roofSide * 24), 0, 0),
                if stage >= 2 then Color3.fromRGB(48, 55, 49) else Color3.fromRGB(59, 58, 51),
                Enum.Material.Slate
            )
        end
        part(
            model,
            "RoofRidgeBeam",
            Vector3.new(size.X + 2.4, 0.48, 0.48),
            CFrame.new(center + Vector3.new(0, wallHeight + 2.65, 0)),
            WET_BARK,
            Enum.Material.Wood,
            false
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
        WorldSignBuilder.dressBoard(sign, displayName, accent, "building")
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
        local interiorCounter = part(
            model,
            "BuildingInteriorCounter",
            Vector3.new(size.X * 0.48, 1.25, 2.4),
            CFrame.new(center + Vector3.new(0, 1.25, halfZ - 1.8)),
            Color3.fromRGB(96, 68, 45),
            Enum.Material.WoodPlanks,
            false
        )
        interiorCounter.CanQuery = false
        for crateIndex = -1, 1, 2 do
            local crate = part(
                model,
                "BuildingSupplyCrate",
                Vector3.new(2.4, 1.9, 2.2),
                CFrame.new(center + Vector3.new(crateIndex * (halfX * 0.52), 0.95, -0.5)),
                if crateIndex < 0 then Color3.fromRGB(89, 63, 42) else Color3.fromRGB(102, 87, 56),
                Enum.Material.WoodPlanks,
                false
            )
            crate.CanQuery = false
        end
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
        Vector3.new(-92, 0, -144),
        Vector3.new(17, 0, 14),
        archiveStage,
        FOXFIRE
    )
    if archiveStage > 0 then
        local archivePropsFallback = Instance.new("Model")
        archivePropsFallback.Name = "ArchivePropsFallback"
        archivePropsFallback.Parent = archive
        for shelf = -1, 1, 2 do
            part(
                archivePropsFallback,
                "ArchiveShelf",
                Vector3.new(4.8, 5.2, 0.75),
                CFrame.new(-92 + shelf * 5.3, 2.85, -139.1),
                Color3.fromRGB(85, 61, 42),
                Enum.Material.WoodPlanks,
                false
            )
        end
        for jarIndex = -2, 2 do
            local jar = part(
                archivePropsFallback,
                "ArchiveMemoryJar",
                Vector3.new(0.65, 0.9, 0.65),
                CFrame.new(-92 + jarIndex * 1.4, 1.1, -144),
                if jarIndex % 2 == 0 then FOXFIRE else AMBER,
                Enum.Material.Glass,
                false
            )
            jar.Shape = Enum.PartType.Ball
            jar.Transparency = 0.18
        end
        for index, definition in
            {
                { assetId = "mesh_creator_crate_a", x = -96, yaw = -9 },
                { assetId = "mesh_creator_barrel_a", x = -92, yaw = 7 },
                { assetId = "mesh_creator_crate_a", x = -88, yaw = 12 },
            }
        do
            table.insert(meshPlacements, {
                assetId = definition.assetId,
                fallbackKind = "asset_replacement",
                position = Vector3.new(definition.x, 0, -140),
                scale = 0.9,
                yaw = math.rad(definition.yaw),
                seed = 10100 + index,
                swayTag = nil,
                parent = assetParent,
                fallbackInstance = if index == 1 then archivePropsFallback else nil,
            })
        end
    end

    local workbenchStage = stageFor("building_workbench")
    local workshop = buildingShell(
        "building_workbench",
        "LANTERN WORKBENCH",
        Vector3.new(92, 0, -126),
        Vector3.new(18, 0, 14),
        workbenchStage,
        AMBER
    )
    if workbenchStage > 0 then
        local workbenchFallback = Instance.new("Model")
        workbenchFallback.Name = "TownWorkbenchFallback"
        workbenchFallback.Parent = workshop
        local bench = part(
            workbenchFallback,
            "CraftingBench",
            Vector3.new(8, 1.2, 3.2),
            CFrame.new(92, 1.3, -122.3),
            Color3.fromRGB(104, 73, 46),
            Enum.Material.WoodPlanks,
            false
        )
        for toolIndex = -1, 1 do
            part(
                workbenchFallback,
                "WorkbenchTool",
                Vector3.new(0.35, 2.4, 0.35),
                bench.CFrame + Vector3.new(toolIndex * 2.2, 1.65, 0),
                if toolIndex == 0 then Color3.fromRGB(141, 150, 153) else BARK,
                if toolIndex == 0 then Enum.Material.Metal else Enum.Material.Wood,
                false
            )
        end
        table.insert(meshPlacements, {
            assetId = "mesh_creator_workbench_a",
            fallbackKind = "asset_replacement",
            position = Vector3.new(92, 0, -122.3),
            scale = 1,
            yaw = math.pi,
            seed = 10110,
            swayTag = nil,
            parent = assetParent,
            fallbackInstance = workbenchFallback,
        })
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
            CFrame.new(side * 5.2, 3.6, -158),
            WET_BARK,
            Enum.Material.Wood
        )
    end
    local board = part(
        boardModel,
        "TownBoard",
        Vector3.new(11.5, 5.5, 0.65),
        CFrame.new(0, 5.2, -158),
        Color3.fromRGB(90, 64, 42),
        Enum.Material.WoodPlanks,
        false
    )
    WorldSignBuilder.dressNoticeBoard(
        board,
        string.format("EMBERHOLLOW · TIER %d", consequence.tier or 0),
        CREAM,
        { "community_watch", "lantern_maintenance", "supply_inventory" }
    )
    table.insert(meshPlacements, {
        assetId = "mesh_creator_notice_board_a",
        fallbackKind = "asset_replacement",
        position = Vector3.new(0, 0, -158),
        scale = 1.05,
        yaw = 0,
        seed = 10120,
        swayTag = nil,
        parent = assetParent,
        fallbackInstance = boardModel,
    })

    local innStage = stageFor("building_inn")
    local inn = buildingShell(
        "building_inn",
        "WAYFARER INN",
        Vector3.new(-92, 0, -184),
        Vector3.new(18, 0, 14),
        innStage,
        Color3.fromRGB(219, 151, 77)
    )
    if innStage > 0 then
        local innFurnitureFallback = Instance.new("Model")
        innFurnitureFallback.Name = "InnFurnitureFallback"
        innFurnitureFallback.Parent = inn
        for side = -1, 1, 2 do
            part(
                innFurnitureFallback,
                "InnTable",
                Vector3.new(4.5, 0.55, 3),
                CFrame.new(-92 + side * 5, 2.1, -180.5),
                Color3.fromRGB(100, 69, 45),
                Enum.Material.WoodPlanks,
                false
            )
            table.insert(meshPlacements, {
                assetId = "mesh_creator_picnic_table_a",
                fallbackKind = "asset_replacement",
                position = Vector3.new(-92 + side * 5, 0, -180.5),
                scale = 0.7,
                yaw = math.rad(90),
                seed = 10130 + side,
                swayTag = nil,
                parent = assetParent,
                fallbackInstance = if side < 0 then innFurnitureFallback else nil,
            })
        end
    end

    local residentDefinitions = {
        npc_tomas_reed = {
            displayName = "TOMAS REED",
            role = "QUARTERMASTER",
            coat = Color3.fromRGB(116, 72, 49),
            accent = Color3.fromRGB(221, 154, 78),
            skin = Color3.fromRGB(177, 124, 87),
            hair = Color3.fromRGB(55, 40, 34),
            prop = "cookpot",
            day = CFrame.new(-92, 3, -178) * CFrame.Angles(0, math.rad(180), 0),
            dusk = CFrame.new(-10, 3, -128) * CFrame.Angles(0, math.rad(-10), 0),
            night = CFrame.new(-9, 3, -138) * CFrame.Angles(0, math.rad(-15), 0),
            dayDuty = "PREPARING SUPPLIES",
        },
        npc_pip_wren = {
            displayName = "PIP WREN",
            role = "COURIER",
            coat = Color3.fromRGB(61, 88, 92),
            accent = Color3.fromRGB(112, 192, 176),
            skin = Color3.fromRGB(210, 157, 112),
            hair = Color3.fromRGB(111, 66, 43),
            prop = "route_map",
            day = CFrame.new(0, 3, -151) * CFrame.Angles(0, math.rad(180), 0),
            dusk = CFrame.new(0, 3, -128),
            night = CFrame.new(0, 3, -139),
            dayDuty = "MAPPING SAFE ROUTES",
        },
        npc_ena_moss = {
            displayName = "ENA MOSS",
            role = "SEEDKEEPER",
            coat = Color3.fromRGB(72, 103, 62),
            accent = Color3.fromRGB(191, 178, 82),
            skin = Color3.fromRGB(126, 87, 65),
            hair = Color3.fromRGB(41, 35, 29),
            prop = "seed_basket",
            day = CFrame.new(96, 3, -146) * CFrame.Angles(0, math.rad(180), 0),
            dusk = CFrame.new(10, 3, -128) * CFrame.Angles(0, math.rad(10), 0),
            night = CFrame.new(9, 3, -138) * CFrame.Angles(0, math.rad(15), 0),
            dayDuty = "TENDING THE GREENWARD",
        },
    }

    local function buildResident(residentId: string, definition: any)
        local model = Instance.new("Model")
        model.Name = definition.displayName
        model:SetAttribute("ResidentId", residentId)
        model:SetAttribute("ResidentRole", definition.role)
        model:SetAttribute("RoutineDay", definition.day)
        model:SetAttribute("RoutineDusk", definition.dusk)
        model:SetAttribute("RoutineNight", definition.night)
        model:SetAttribute("DayDuty", definition.dayDuty)
        model:SetAttribute("MotionKind", "resident")
        model:SetAttribute("MotionSpeed", 0.58 + (#residentId % 5) * 0.06)
        model.Parent = parent

        local root = part(
            model,
            "HumanoidRootPart",
            Vector3.new(2, 2, 1),
            CFrame.new(0, 0, 0),
            definition.coat,
            Enum.Material.SmoothPlastic,
            false
        )
        root.Transparency = 1
        part(
            model,
            "WorkCoat",
            Vector3.new(2.5, 3.2, 1.35),
            CFrame.new(0, 0.4, 0),
            definition.coat,
            Enum.Material.Fabric,
            false
        )
        local head = part(
            model,
            "Head",
            Vector3.new(2, 2, 2),
            CFrame.new(0, 3, 0),
            definition.skin,
            Enum.Material.SmoothPlastic,
            false
        )
        head.Shape = Enum.PartType.Ball
        local hair = part(
            model,
            "Hair",
            Vector3.new(2.15, 1.15, 2.15),
            CFrame.new(0, 3.65, 0.1),
            definition.hair,
            Enum.Material.SmoothPlastic,
            false
        )
        hair.Shape = Enum.PartType.Ball
        local apron = part(
            model,
            "ProfessionLayer",
            Vector3.new(1.85, 2.2, 0.18),
            CFrame.new(0, 0.2, -0.78),
            definition.accent,
            Enum.Material.Fabric,
            false
        )
        apron.Transparency = 0.04
        for side = -1, 1, 2 do
            local shoulder = part(
                model,
                "CoatShoulder",
                Vector3.new(1.02, 1.02, 1.18),
                CFrame.new(side * 1.3, 1.15, 0),
                definition.coat:Lerp(definition.accent, 0.1),
                Enum.Material.Fabric,
                false
            )
            shoulder.Shape = Enum.PartType.Ball
            part(
                model,
                "CoatCuff",
                Vector3.new(0.84, 0.42, 0.84),
                CFrame.new(side * 1.67, -0.83, 0),
                definition.accent,
                Enum.Material.Fabric,
                false
            )
            part(
                model,
                "HairSide",
                Vector3.new(0.42, 1.45, 0.5),
                CFrame.new(side * 0.88, 2.85, 0.08) * CFrame.Angles(0, 0, math.rad(side * 7)),
                definition.hair,
                Enum.Material.SmoothPlastic,
                false
            )
        end
        part(
            model,
            "WorkBelt",
            Vector3.new(2.65, 0.32, 1.45),
            CFrame.new(0, -0.55, 0),
            Color3.fromRGB(77, 55, 40),
            Enum.Material.Leather,
            false
        )
        part(
            model,
            "WorkBeltBuckle",
            Vector3.new(0.5, 0.46, 0.18),
            CFrame.new(0, -0.55, -0.8),
            definition.accent,
            Enum.Material.Metal,
            false
        )
        for lapelSide = -1, 1, 2 do
            part(
                model,
                "CoatLapel",
                Vector3.new(0.58, 1.7, 0.16),
                CFrame.new(lapelSide * 0.48, 0.72, -0.78)
                    * CFrame.Angles(0, 0, math.rad(lapelSide * 18)),
                definition.accent:Lerp(definition.coat, 0.35),
                Enum.Material.Fabric,
                false
            )
        end
        for side = -1, 1, 2 do
            part(
                model,
                "Arm",
                Vector3.new(0.7, 3, 0.7),
                CFrame.new(side * 1.55, 0.35, 0) * CFrame.Angles(0, 0, math.rad(side * 7)),
                definition.coat,
                Enum.Material.Fabric,
                false
            )
            local hand = part(
                model,
                "Hand",
                Vector3.new(0.72, 0.72, 0.72),
                CFrame.new(side * 1.72, -1.2, 0),
                definition.skin,
                Enum.Material.SmoothPlastic,
                false
            )
            hand.Shape = Enum.PartType.Ball
            part(
                model,
                "Leg",
                Vector3.new(0.82, 2.2, 0.9),
                CFrame.new(side * 0.62, -2.25, 0),
                Color3.fromRGB(45, 49, 47),
                Enum.Material.Fabric,
                false
            )
            part(
                model,
                "Boot",
                Vector3.new(1, 0.7, 1.45),
                CFrame.new(side * 0.62, -3.15, -0.22),
                Color3.fromRGB(52, 39, 31),
                Enum.Material.Leather,
                false
            )
            local eye = part(
                model,
                "Eye",
                Vector3.new(0.25, 0.25, 0.14),
                CFrame.new(side * 0.47, 3.2, -0.93),
                Color3.fromRGB(43, 34, 30),
                Enum.Material.SmoothPlastic,
                false
            )
            eye.Shape = Enum.PartType.Ball
        end
        part(
            model,
            "Nose",
            Vector3.new(0.28, 0.4, 0.32),
            CFrame.new(0, 3, -1.02),
            definition.skin:Lerp(Color3.fromRGB(119, 72, 57), 0.12),
            Enum.Material.SmoothPlastic,
            false
        ).Shape =
            Enum.PartType.Ball
        part(
            model,
            "Mouth",
            Vector3.new(0.48, 0.11, 0.1),
            CFrame.new(0, 2.62, -1.02),
            Color3.fromRGB(91, 52, 47),
            Enum.Material.SmoothPlastic,
            false
        )

        if definition.prop == "cookpot" then
            part(
                model,
                "QuartermasterCap",
                Vector3.new(2.45, 0.48, 2.35),
                CFrame.new(0, 4.18, 0.02) * CFrame.Angles(0, 0, math.rad(-4)),
                Color3.fromRGB(83, 55, 40),
                Enum.Material.Fabric,
                false
            )
            local pot = part(
                model,
                "QuartermasterCookpot",
                Vector3.new(2.4, 1.5, 2.4),
                CFrame.new(2.5, -0.8, -0.2),
                Color3.fromRGB(87, 91, 88),
                Enum.Material.Metal,
                false
            )
            pot.Shape = Enum.PartType.Cylinder
            part(
                model,
                "QuartermasterLadle",
                Vector3.new(0.22, 3.2, 0.22),
                CFrame.new(2.2, 0.55, -0.3) * CFrame.Angles(0, 0, math.rad(-20)),
                Color3.fromRGB(131, 137, 136),
                Enum.Material.Metal,
                false
            )
        elseif definition.prop == "route_map" then
            part(
                model,
                "CourierScarf",
                Vector3.new(2.55, 0.46, 1.46),
                CFrame.new(0, 1.9, 0),
                definition.accent,
                Enum.Material.Fabric,
                false
            )
            part(
                model,
                "CourierScarfTail",
                Vector3.new(0.62, 2.05, 0.28),
                CFrame.new(0.82, 1.08, 0.75) * CFrame.Angles(math.rad(-12), 0, math.rad(-8)),
                definition.accent,
                Enum.Material.Fabric,
                false
            )
            part(
                model,
                "CourierSatchel",
                Vector3.new(1.65, 1.8, 0.75),
                CFrame.new(-1.45, -0.25, 0.35),
                Color3.fromRGB(105, 74, 46),
                Enum.Material.Leather,
                false
            )
            local map = part(
                model,
                "CourierRouteMap",
                Vector3.new(2.6, 1.7, 0.12),
                CFrame.new(2, -0.05, -0.8) * CFrame.Angles(0, math.rad(-18), math.rad(5)),
                Color3.fromRGB(220, 204, 164),
                Enum.Material.SmoothPlastic,
                false
            )
            map.CastShadow = false
        else
            part(
                model,
                "SeedkeeperShawl",
                Vector3.new(3, 0.48, 1.65),
                CFrame.new(0, 1.72, 0),
                Color3.fromRGB(106, 126, 72),
                Enum.Material.Fabric,
                false
            )
            local basket = part(
                model,
                "SeedBasket",
                Vector3.new(2.4, 1.45, 2),
                CFrame.new(2.25, -0.85, 0),
                Color3.fromRGB(118, 83, 48),
                Enum.Material.WoodPlanks,
                false
            )
            for seedIndex = -1, 1 do
                local seed = part(
                    model,
                    "SeedBundle",
                    Vector3.new(0.55, 0.7, 0.55),
                    basket.CFrame + Vector3.new(seedIndex * 0.65, 0.8, 0),
                    if seedIndex == 0 then AMBER else FOXFIRE,
                    Enum.Material.Grass,
                    false
                )
                seed.Shape = Enum.PartType.Ball
            end
            part(
                model,
                "SeedkeeperHat",
                Vector3.new(3.3, 0.3, 3.3),
                CFrame.new(0, 4.15, 0),
                Color3.fromRGB(135, 112, 66),
                Enum.Material.Fabric,
                false
            )
            part(
                model,
                "SeedkeeperHatCrown",
                Vector3.new(1.75, 1.25, 1.75),
                CFrame.new(0, 4.72, 0.08),
                Color3.fromRGB(122, 101, 61),
                Enum.Material.Fabric,
                false
            )
        end

        local nightLantern = part(
            model,
            "NightWatchLantern",
            Vector3.new(0.85, 1.15, 0.85),
            CFrame.new(-2.15, -1.35, -0.1),
            AMBER,
            Enum.Material.Glass,
            false
        )
        nightLantern.Shape = Enum.PartType.Ball
        nightLantern.Transparency = 1
        nightLantern:SetAttribute("NightOnly", true)
        local lanternLight = Instance.new("PointLight")
        lanternLight.Color = AMBER
        lanternLight.Brightness = 0.75
        lanternLight.Range = 12
        lanternLight.Shadows = false
        lanternLight.Enabled = false
        lanternLight.Parent = nightLantern

        model.PrimaryPart = root
        model:PivotTo(definition.day)
        local dayPosition = definition.day.Position
        table.insert(meshPlacements, {
            assetId = "mesh_creator_kerosene_lantern_a",
            fallbackKind = "asset_dressing",
            position = dayPosition + Vector3.new(-2.15, -2.35, -0.1),
            scale = 0.72,
            yaw = math.rad(8 + (#residentId % 3) * 7),
            seed = 10150 + #residentId,
            swayTag = nil,
            parent = model,
            fallbackInstance = nil,
            profileScale = Vector3.new(0.92, 1.08, 0.92),
        })
        addBillboard(head, definition.displayName .. " · " .. definition.role, definition.accent)
        CollectionService:AddTag(model, runtimeIds.AmbientMotionTag)
        residents[residentId] = {
            model = model,
            dayDuty = definition.dayDuty,
            displayName = definition.displayName,
            interactionTarget = head,
        }
    end

    local activeResidentIds = if type(consequence.residentIds) == "table"
        then consequence.residentIds
        else {}
    for _, residentId in activeResidentIds do
        local definition = residentDefinitions[residentId]
        if definition ~= nil then
            buildResident(residentId, definition)
        end
    end

    parent:SetAttribute("BuildingCount", 4)
    parent:SetAttribute("ResidentCount", #activeResidentIds)
    parent:SetAttribute("ArchiveStage", archiveStage)
    parent:SetAttribute("WorkbenchStage", workbenchStage)
    parent:SetAttribute("InnStage", innStage)
    return residents
end

function WorldService._setTownResidentRoutine(self: WorldService, phase: string)
    local normalized = if phase == "night" then "Night" elseif phase == "dusk" then "Dusk" else "Day"
    for _, resident in self._townResidents do
        local model = resident.model
        if model ~= nil and model.Parent ~= nil then
            local destination = model:GetAttribute("Routine" .. normalized)
            if typeof(destination) == "CFrame" then
                model:PivotTo(destination)
            end
            model:SetAttribute("Routine", string.lower(normalized))
            model:SetAttribute(
                "CurrentDuty",
                if normalized == "Day"
                    then resident.dayDuty
                    elseif normalized == "Dusk" then "REPORTING TO THE NIGHT WATCH"
                    else "DEFENDING THE LANTERN ROAD"
            )
            local lanternPart = model:FindFirstChild("NightWatchLantern")
            if lanternPart ~= nil and lanternPart:IsA("BasePart") then
                local active = normalized ~= "Day"
                lanternPart.Transparency = if active then 0.16 else 1
                local light = lanternPart:FindFirstChildOfClass("PointLight")
                if light ~= nil then
                    light.Enabled = active
                end
            end
        end
    end
end

function WorldService.setTownConsequence(self: WorldService, consequence: any)
    local world = self._world
    if world == nil or type(consequence) ~= "table" then
        return
    end
    local resolved = self._townProgression.merge(self._townConsequence, consequence)
    self._townConsequence = resolved
    local existing = world:FindFirstChild("GreenwardConsequence")
    if existing ~= nil then
        existing:Destroy()
    end
    local existingBuildings = world:FindFirstChild("TownProgressionBuildings")
    for _, interactionId in self._runtimeIds.ResidentInteractionIds do
        local residentPrompt = self._interactions[interactionId]
        if residentPrompt ~= nil then
            residentPrompt:Destroy()
            self._interactions[interactionId] = nil
        end
    end
    if existingBuildings ~= nil then
        existingBuildings:Destroy()
    end
    local landscape = Instance.new("Model")
    landscape.Name = "GreenwardConsequence"
    landscape.Parent = world
    local townMeshPlacements: { MeshPlacement } = {}
    buildTownConsequenceLandscape(landscape, resolved, world, townMeshPlacements)
    local buildings = Instance.new("Model")
    buildings.Name = "TownProgressionBuildings"
    buildings.Parent = world
    self._townResidents = buildTownProgressionBuildings(
        buildings,
        resolved,
        self._runtimeIds,
        world,
        townMeshPlacements
    )
    self:_placeAuthoredMeshes(townMeshPlacements, world, buildings, "town_mesh_dressing_ready")
    for residentId, resident in self._townResidents do
        local interactionId = self._runtimeIds.ResidentInteractionIds[residentId]
        if interactionId ~= nil and resident.interactionTarget ~= nil then
            self:_registerInteraction(
                resident.interactionTarget,
                interactionId,
                self._runtimeIds.Actions.TalkResident,
                "TALK",
                resident.displayName,
                residentId
            )
        end
    end
    self:_setTownResidentRoutine(
        if self._night then "night" elseif self._dusk then "dusk" else "day"
    )
    local visualPartCount = 0
    for _, descendant in landscape:GetDescendants() do
        if descendant:IsA("BasePart") then
            visualPartCount += 1
        end
    end
    landscape:SetAttribute("VisualPartCount", visualPartCount)
    world:SetAttribute("TownTier", resolved.tier)
    world:SetAttribute("TownDecision", tostring(resolved.decision or "unresolved"))
    world:SetAttribute("WardenOutcome", tostring(resolved.wardenOutcome or "unresolved"))
end

function WorldService.setTownCondition(self: WorldService, condition: any)
    local world = self._world
    if world == nil or type(condition) ~= "table" then
        return
    end
    local integrity = math.clamp(math.floor(tonumber(condition.integrity) or 100), 25, 100)
    local damageLevel = math.clamp(math.floor(tonumber(condition.damageLevel) or 0), 0, 3)
    self._townCondition = {
        integrity = integrity,
        damageLevel = damageLevel,
        lastNightNumber = math.max(0, math.floor(tonumber(condition.lastNightNumber) or 0)),
        lastDamage = math.max(0, math.floor(tonumber(condition.lastDamage) or 0)),
        repairsCompleted = math.max(0, math.floor(tonumber(condition.repairsCompleted) or 0)),
        repairsRemaining = math.max(0, math.floor(tonumber(condition.repairsRemaining) or 0)),
    }

    for _, interactionId in self._runtimeIds.TownRepairInteractionIds do
        local prompt = self._interactions[interactionId]
        if prompt ~= nil then
            prompt:Destroy()
            self._interactions[interactionId] = nil
        end
    end
    local existing = world:FindFirstChild("TownDamageConsequences")
    if existing ~= nil then
        existing:Destroy()
    end
    world:SetAttribute("TownIntegrity", integrity)
    world:SetAttribute("TownDamageLevel", damageLevel)
    if damageLevel == 0 then
        return
    end

    local damage = Instance.new("Model")
    damage.Name = "TownDamageConsequences"
    damage:SetAttribute("Integrity", integrity)
    damage:SetAttribute("DamageLevel", damageLevel)
    damage.Parent = world
    local sites = {
        {
            id = self._runtimeIds.TownRepairInteractionIds[1],
            name = "Archive Roof Brace",
            position = Vector3.new(-40, 2.4, -96),
        },
        {
            id = self._runtimeIds.TownRepairInteractionIds[2],
            name = "Workbench Shutters",
            position = Vector3.new(39, 2.4, -95),
        },
        {
            id = self._runtimeIds.TownRepairInteractionIds[3],
            name = "Inn Storm Frame",
            position = Vector3.new(-40, 2.4, -140),
        },
    }
    for siteIndex = 1, damageLevel do
        local site = sites[siteIndex]
        local target = part(
            damage,
            "RepairPile_" .. tostring(siteIndex),
            Vector3.new(5.5, 1.2, 2.8),
            CFrame.new(site.position) * CFrame.Angles(0, math.rad(siteIndex * 8 - 16), 0),
            Color3.fromRGB(93, 65, 43),
            Enum.Material.WoodPlanks,
            false
        )
        for braceIndex = -1, 1 do
            part(
                damage,
                "StormBrokenBrace",
                Vector3.new(0.55, 5.5, 0.55),
                target.CFrame
                    * CFrame.new(braceIndex * 1.8, 2, 0)
                    * CFrame.Angles(0, 0, math.rad(braceIndex * 18)),
                if braceIndex == 0 then Color3.fromRGB(48, 41, 37) else BARK,
                Enum.Material.Wood,
                false
            )
        end
        local canvas = part(
            damage,
            "StormTarp",
            Vector3.new(5.8, 0.2, 4.4),
            CFrame.new(site.position + Vector3.new(0, 4.2, 0))
                * CFrame.Angles(0, 0, math.rad(siteIndex % 2 == 0 and -7 or 7)),
            Color3.fromRGB(75, 87, 77),
            Enum.Material.Fabric,
            false
        )
        canvas.Transparency = 0.06
        self:_registerInteraction(
            target,
            site.id,
            self._runtimeIds.Actions.RepairTown,
            "REPAIR",
            site.name,
            nil,
            1.1
        )
    end
    self:setTownRepairEnabled(not self._night and not self._dusk)
end

function WorldService.setTownRepairEnabled(self: WorldService, enabled: boolean)
    for _, interactionId in self._runtimeIds.TownRepairInteractionIds do
        local prompt = self._interactions[interactionId]
        if prompt ~= nil then
            prompt.Enabled = enabled and self._townCondition.damageLevel > 0
        end
    end
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
    for railSide = -1, 1, 2 do
        part(
            delivery,
            "WayhomePalletRail",
            Vector3.new(0.42, 1.85, 5.65),
            CFrame.new(origin + Vector3.new(railSide * 3.18, 1.2, 0)),
            Color3.fromRGB(72, 50, 36),
            Enum.Material.Wood,
            false
        )
        part(
            delivery,
            "WayhomePalletBinding",
            Vector3.new(6.55, 0.22, 0.26),
            CFrame.new(origin + Vector3.new(0, 1.65, railSide * 2.25)),
            Color3.fromRGB(103, 91, 68),
            Enum.Material.Fabric,
            false
        )
    end
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
            or actionId == self._runtimeIds.Actions.RecoverExpeditionCache
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
    self:_placeAuthoredMeshes(
        result.meshPlacements,
        result.model,
        result.model,
        "expedition_mesh_dressing_ready"
    )
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

function WorldService.clearRecoveryCache(self: WorldService, player: Player)
    local interactionId = string.format("recovery_cache:%d", player.UserId)
    local prompt = self._interactions[interactionId]
    if prompt ~= nil then
        prompt:Destroy()
        self._interactions[interactionId] = nil
    end
    local world = self._world
    if world ~= nil then
        local caches = world:FindFirstChild("ExpeditionRecoveryCaches")
        local model = if caches == nil
            then nil
            else caches:FindFirstChild("RecoveryCache_" .. tostring(player.UserId))
        if model ~= nil then
            model:Destroy()
        end
    end
end

function WorldService.showRecoveryCache(self: WorldService, player: Player, cache: any)
    self:clearRecoveryCache(player)
    local world = self._world
    local entry = self._expeditionEntry
    if world == nil or entry == nil or cache == nil then
        return
    end
    local caches = world:FindFirstChild("ExpeditionRecoveryCaches")
    if caches == nil then
        caches = Instance.new("Folder")
        caches.Name = "ExpeditionRecoveryCaches"
        caches.Parent = world
    end
    local model = Instance.new("Model")
    model.Name = "RecoveryCache_" .. tostring(player.UserId)
    model:SetAttribute("CacheId", cache.cacheId)
    model:SetAttribute("OwnerUserId", player.UserId)
    model.Parent = caches
    local side = if player.UserId % 2 == 0 then -1 else 1
    local offset = Vector3.new(side * (5 + player.UserId % 3), 0.7, 7 + player.UserId % 4)
    local at = entry.Position + offset
    local body = part(
        model,
        "RecoverySatchel",
        Vector3.new(3.8, 2.6, 2.4),
        CFrame.new(at),
        Color3.fromRGB(77, 57, 40),
        Enum.Material.Fabric,
        false
    )
    for index = -1, 1, 2 do
        part(
            model,
            "SatchelBrace",
            Vector3.new(0.28, 2.8, 2.55),
            CFrame.new(at + Vector3.new(index * 1.25, 0, 0)),
            Color3.fromRGB(111, 81, 48),
            Enum.Material.Wood,
            false
        )
    end
    part(
        model,
        "SatchelFlap",
        Vector3.new(3.65, 0.35, 2.2),
        CFrame.new(at + Vector3.new(0, 1.35, -0.15)) * CFrame.Angles(math.rad(-7), 0, 0),
        Color3.fromRGB(53, 72, 51),
        Enum.Material.Fabric,
        false
    )
    local clasp = part(
        model,
        "WayhomeClasp",
        Vector3.new(0.8, 0.8, 0.32),
        CFrame.new(at + Vector3.new(0, 0.25, -1.3)),
        Color3.fromRGB(185, 145, 72),
        Enum.Material.Metal,
        false
    )
    clasp.Shape = Enum.PartType.Ball
    addBillboard(body, "LOST SATCHEL · " .. string.upper(player.DisplayName), CREAM)
    local interactionId = string.format("recovery_cache:%d", player.UserId)
    self:_registerInteraction(
        body,
        interactionId,
        self._runtimeIds.Actions.RecoverExpeditionCache,
        "RECOVER",
        "Lost Expedition Satchel",
        cache.cacheId,
        1.2
    )
    local prompt = self._interactions[interactionId]
    prompt:SetAttribute("OwnerUserId", player.UserId)
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

local function buildNightThemeDressing(parent: Instance, theme: string): Model
    local model = Instance.new("Model")
    model.Name = "NightThemeDressing"
    model:SetAttribute("Theme", theme)
    model.Parent = parent
    local accent = nightThemeColor(theme)

    if theme == "EMBERFALL" then
        for row = 0, 2 do
            for side = -1, 1, 2 do
                local center = Vector3.new(side * 7.5, 0.45, -144 + row * 12)
                local basin = part(
                    model,
                    "EmberCatchBasin",
                    Vector3.new(3.4, 0.7, 3.4),
                    CFrame.new(center),
                    Color3.fromRGB(72, 58, 49),
                    Enum.Material.Slate,
                    false
                )
                basin.Shape = Enum.PartType.Cylinder
                local coal = part(
                    model,
                    "CaughtEmbers",
                    Vector3.new(2.2, 0.35, 2.2),
                    CFrame.new(center + Vector3.new(0, 0.48, 0)),
                    accent,
                    Enum.Material.Neon,
                    false
                )
                coal.Shape = Enum.PartType.Cylinder
                coal.Transparency = 0.18
            end
        end
    elseif theme == "MIRETIDE" then
        for poolIndex = 0, 4 do
            local side = if poolIndex % 2 == 0 then -1 else 1
            local pool = part(
                model,
                "MiretidePool",
                Vector3.new(8 + poolIndex % 3, 0.16, 6.5),
                CFrame.new(side * 6.5, 0.24, -145 + poolIndex * 7.2)
                    * CFrame.Angles(0, math.rad(side * (8 + poolIndex * 3)), 0),
                accent,
                Enum.Material.Glass,
                false
            )
            pool.Transparency = 0.48
            local reed = part(
                model,
                "MiretideReeds",
                Vector3.new(0.35, 3.2, 0.35),
                pool.CFrame + Vector3.new(side * 2.4, 1.5, 0.8),
                Color3.fromRGB(64, 103, 77),
                Enum.Material.Grass,
                false
            )
            reed.CFrame *= CFrame.Angles(0, 0, math.rad(side * 8))
        end
    elseif theme == "ROOTMOON" then
        for archIndex = 0, 2 do
            local z = -145 + archIndex * 13
            for side = -1, 1, 2 do
                part(
                    model,
                    "RootmoonPillar",
                    Vector3.new(1.05, 8, 1.05),
                    CFrame.new(side * 6.2, 4, z) * CFrame.Angles(0, 0, math.rad(-side * 12)),
                    Color3.fromRGB(72, 54, 45),
                    Enum.Material.Wood,
                    false
                )
            end
            local crown = part(
                model,
                "RootmoonCrown",
                Vector3.new(13, 1, 1),
                CFrame.new(0, 7.7, z),
                accent,
                Enum.Material.Wood,
                false
            )
            crown.Transparency = 0.12
        end
    else
        for driftIndex = 1, 8 do
            local side = if driftIndex % 2 == 0 then -1 else 1
            local drift = part(
                model,
                "AshenDrift",
                Vector3.new(4 + driftIndex % 3, 1.1, 2.5 + driftIndex % 2),
                CFrame.new(side * (7 + driftIndex % 3), 0.55, -149 + driftIndex * 4.2)
                    * CFrame.Angles(0, math.rad(side * driftIndex * 9), 0),
                Color3.fromRGB(89, 82, 78),
                Enum.Material.Sand,
                false
            )
            drift.Shape = Enum.PartType.Ball
            drift.Transparency = 0.18
            if driftIndex % 2 == 0 then
                part(
                    model,
                    "CharredWaypost",
                    Vector3.new(0.65, 5.5, 0.65),
                    CFrame.new(side * 9, 2.7, -149 + driftIndex * 4.2)
                        * CFrame.Angles(0, 0, math.rad(side * 10)),
                    Color3.fromRGB(38, 35, 34),
                    Enum.Material.Wood,
                    false
                )
            end
        end
    end

    local marker = part(
        model,
        "NightThemeMarker",
        Vector3.new(12, 2.5, 0.45),
        CFrame.new(0, 5.2, -151),
        Color3.fromRGB(48, 39, 35),
        Enum.Material.WoodPlanks,
        false
    )
    addBillboard(marker, theme, accent)
    return model
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

function WorldService.clearTownIncident(self: WorldService)
    for interactionId, prompt in self._interactions do
        if prompt:GetAttribute("ActionId") == self._runtimeIds.Actions.ResolveTownIncident then
            if prompt.Parent ~= nil then
                prompt:Destroy()
            end
            self._interactions[interactionId] = nil
        end
    end
    if self._townIncidentModel ~= nil and self._townIncidentModel.Parent ~= nil then
        self._townIncidentModel:Destroy()
    end
    self._townIncidentModel = nil
    local world = self._world
    if world ~= nil then
        world:SetAttribute("TownIncidentId", nil)
        world:SetAttribute("TownIncidentEndsAt", nil)
        world:SetAttribute("TownIncidentResolved", nil)
        world:SetAttribute("TownIncidentRequired", nil)
    end
end

local INCIDENT_SITES = table.freeze({
    archive = Vector3.new(-31, 0.65, -108),
    workshop = Vector3.new(31, 0.65, -108),
    inn = Vector3.new(-28, 0.65, -137),
})

local function buildIncidentSite(parent: Model, incidentId: string, siteId: string): BasePart
    local at = assert(INCIDENT_SITES[siteId], "town incident site is unknown")
    local site = Instance.new("Model")
    site.Name = "IncidentSite_" .. siteId
    site:SetAttribute("SiteId", siteId)
    site:SetAttribute("Resolved", false)
    site.Parent = parent

    local target: Part
    if incidentId == "incident_emberfall_cinders" then
        target = part(
            site,
            "IncidentCore",
            Vector3.new(3.8, 0.75, 3.2),
            CFrame.new(at),
            Color3.fromRGB(55, 47, 42),
            Enum.Material.Slate,
            false
        )
        target.Shape = Enum.PartType.Ball
        for index = -1, 1 do
            part(
                site,
                "CharredTimber",
                Vector3.new(0.42, 3.3, 0.42),
                CFrame.new(at + Vector3.new(index * 0.8, 0.55, 0))
                    * CFrame.Angles(math.rad(90), 0, math.rad(index * 24)),
                Color3.fromRGB(40, 32, 29),
                Enum.Material.Wood,
                false
            )
        end
        local ember = part(
            site,
            "BuriedEmber",
            Vector3.new(1.2, 0.18, 1.2),
            CFrame.new(at + Vector3.new(0, 0.46, 0)),
            Color3.fromRGB(190, 78, 38),
            Enum.Material.SmoothPlastic,
            false
        )
        ember.Shape = Enum.PartType.Ball
    elseif incidentId == "incident_emberfall_flues" then
        target = part(
            site,
            "IncidentCore",
            Vector3.new(2.8, 3.2, 2.8),
            CFrame.new(at + Vector3.new(0, 1.25, 0)),
            Color3.fromRGB(74, 65, 58),
            Enum.Material.Brick,
            false
        )
        for tier = 1, 3 do
            part(
                site,
                "FlueBrick",
                Vector3.new(3.4 - tier * 0.35, 0.42, 3.4 - tier * 0.35),
                CFrame.new(at + Vector3.new(0, 2.75 + tier * 0.35, 0)),
                Color3.fromRGB(86 - tier * 8, 69 - tier * 6, 59 - tier * 5),
                Enum.Material.Brick,
                false
            )
        end
        local cap = part(
            site,
            "LooseFlueCap",
            Vector3.new(3.1, 0.28, 3.1),
            CFrame.new(at + Vector3.new(0.55, 4.15, 0))
                * CFrame.Angles(math.rad(8), 0, math.rad(-12)),
            Color3.fromRGB(58, 56, 53),
            Enum.Material.Metal,
            false
        )
        cap:SetAttribute("NeedsSecuring", true)
    elseif incidentId == "incident_miretide_clogs" then
        target = part(
            site,
            "IncidentCore",
            Vector3.new(0.28, 4.2, 4.2),
            CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(58, 67, 48),
            Enum.Material.Ground,
            false
        )
        target.Shape = Enum.PartType.Cylinder
        for index = 1, 5 do
            local angle = math.rad(index * 72)
            part(
                site,
                "DrainStone",
                Vector3.new(0.85, 0.7, 1.2),
                CFrame.new(at + Vector3.new(math.cos(angle) * 2, 0.12, math.sin(angle) * 2))
                    * CFrame.Angles(0, -angle, 0),
                Color3.fromRGB(88, 91, 79),
                Enum.Material.Rock,
                false
            )
        end
        for index = -1, 1 do
            part(
                site,
                "RootClog",
                Vector3.new(0.5, 3.5, 0.5),
                CFrame.new(at + Vector3.new(index * 0.65, 0.55, 0))
                    * CFrame.Angles(0, 0, math.rad(78 + index * 16)),
                WET_BARK,
                Enum.Material.Wood,
                false
            )
        end
    elseif incidentId == "incident_miretide_seeps" then
        target = part(
            site,
            "IncidentCore",
            Vector3.new(5.2, 0.32, 4.4),
            CFrame.new(at - Vector3.new(0, 0.35, 0)),
            Color3.fromRGB(52, 69, 60),
            Enum.Material.Ground,
            false
        )
        target.Shape = Enum.PartType.Ball
        for index = 1, 6 do
            local angle = math.rad(index * 60)
            part(
                site,
                "SeepStone",
                Vector3.new(1.25, 0.65, 0.9),
                CFrame.new(at + Vector3.new(math.cos(angle) * 2.3, 0, math.sin(angle) * 1.9))
                    * CFrame.Angles(0, angle, math.rad(index % 2 == 0 and 6 or -6)),
                Color3.fromRGB(83, 91, 81),
                Enum.Material.Rock,
                false
            )
        end
        for index = -1, 1, 2 do
            part(
                site,
                "SealStake",
                Vector3.new(0.45, 2.8, 0.45),
                CFrame.new(at + Vector3.new(index * 1.3, 0.65, 0.3))
                    * CFrame.Angles(0, 0, math.rad(index * 12)),
                BARK,
                Enum.Material.Wood,
                false
            )
        end
    elseif incidentId == "incident_rootmoon_anchors" then
        target = part(
            site,
            "IncidentCore",
            Vector3.new(2.7, 1.1, 2.7),
            CFrame.new(at),
            WET_EARTH,
            Enum.Material.Ground,
            false
        )
        target.Shape = Enum.PartType.Ball
        for index = -1, 1 do
            part(
                site,
                "RootAnchor",
                Vector3.new(0.72, 5.2, 0.72),
                CFrame.new(at + Vector3.new(index * 0.85, 2.2, index % 2 * 0.4))
                    * CFrame.Angles(math.rad(index * 8), 0, math.rad(index * 13)),
                BARK,
                Enum.Material.Wood,
                false
            )
        end
    elseif incidentId == "incident_rootmoon_snares" then
        target = part(
            site,
            "IncidentCore",
            Vector3.new(3.4, 3.4, 3.4),
            CFrame.new(at + Vector3.new(0, 1.4, 0)),
            Color3.fromRGB(74, 83, 58),
            Enum.Material.Ground,
            false
        )
        target.Shape = Enum.PartType.Ball
        for index = 1, 5 do
            local angle = math.rad(index * 72)
            local thorn = part(
                site,
                "SnareThorn",
                Vector3.new(0.5, 2.6, 0.5),
                CFrame.new(at + Vector3.new(math.cos(angle) * 1.45, 1.5, math.sin(angle) * 1.45))
                    * CFrame.Angles(math.rad(55), -angle, math.rad(18)),
                WET_BARK,
                Enum.Material.Wood,
                false
            )
            thorn.Shape = Enum.PartType.Cylinder
        end
        for loop = -1, 1, 2 do
            part(
                site,
                "SnareVine",
                Vector3.new(0.38, 5.4, 0.38),
                CFrame.new(at + Vector3.new(loop * 1.3, 0.4, 0))
                    * CFrame.Angles(math.rad(90), 0, math.rad(loop * 24)),
                BARK,
                Enum.Material.Wood,
                false
            )
        end
    elseif incidentId == "incident_ashen_watchfires" then
        target = part(
            site,
            "IncidentCore",
            Vector3.new(3.6, 0.5, 3.6),
            CFrame.new(at),
            Color3.fromRGB(45, 43, 42),
            Enum.Material.Metal,
            false
        )
        for index = -1, 1 do
            part(
                site,
                "ColdFuel",
                Vector3.new(0.42, 2.8, 0.42),
                CFrame.new(at + Vector3.new(index * 0.62, 0.75, 0))
                    * CFrame.Angles(math.rad(90), 0, math.rad(index * 34)),
                Color3.fromRGB(55, 43, 34),
                Enum.Material.Wood,
                false
            )
        end
        for index = -1, 1, 2 do
            part(
                site,
                "BrazierLeg",
                Vector3.new(0.28, 2.4, 0.28),
                CFrame.new(at + Vector3.new(index * 1.15, -0.25, 0)),
                Color3.fromRGB(58, 57, 55),
                Enum.Material.Metal,
                false
            )
        end
    else
        target = part(
            site,
            "IncidentCore",
            Vector3.new(0.7, 4.8, 0.7),
            CFrame.new(at + Vector3.new(0, 1.65, 0)),
            Color3.fromRGB(66, 52, 39),
            Enum.Material.Wood,
            false
        )
        for side = -1, 1, 2 do
            part(
                site,
                "BellFramePost",
                Vector3.new(0.55, 5.2, 0.55),
                CFrame.new(at + Vector3.new(side * 1.8, 1.7, 0)),
                BARK,
                Enum.Material.Wood,
                false
            )
        end
        part(
            site,
            "BellFrameBeam",
            Vector3.new(4.4, 0.55, 0.55),
            CFrame.new(at + Vector3.new(0, 4.2, 0)),
            BARK,
            Enum.Material.Wood,
            false
        )
        local bell = part(
            site,
            "SilentWardBell",
            Vector3.new(2.2, 2.1, 2.2),
            CFrame.new(at + Vector3.new(0, 2.75, 0)),
            Color3.fromRGB(115, 103, 79),
            Enum.Material.Metal,
            false
        )
        bell.Shape = Enum.PartType.Ball
        part(
            site,
            "BellClapper",
            Vector3.new(0.38, 1.6, 0.38),
            CFrame.new(at + Vector3.new(0, 1.45, 0)),
            Color3.fromRGB(72, 66, 58),
            Enum.Material.Metal,
            false
        )
    end
    target:SetAttribute("IncidentId", incidentId)
    target:SetAttribute("SiteId", siteId)
    return target
end

function WorldService.startTownIncident(self: WorldService, definition: any, endsAt: number)
    self:clearTownIncident()
    local world = self._world
    if world == nil or not self._night then
        return
    end
    local model = Instance.new("Model")
    model.Name = "TownNightIncident"
    model:SetAttribute("IncidentId", definition.id)
    model:SetAttribute("Title", definition.title)
    model:SetAttribute("Required", #definition.sites)
    model.Parent = world
    self._townIncidentModel = model
    for _, siteId in definition.sites do
        local target = buildIncidentSite(model, definition.id, siteId)
        local interactionId = string.format("town_incident:%s:%s", definition.id, siteId)
        self:_registerInteraction(
            target,
            interactionId,
            self._runtimeIds.Actions.ResolveTownIncident,
            definition.actionText,
            definition.objectText,
            siteId,
            0.85
        )
        addBillboard(target, string.format("%s · %s", definition.title, siteId), CREAM)
    end
    world:SetAttribute("TownIncidentId", definition.id)
    world:SetAttribute("TownIncidentEndsAt", endsAt)
    world:SetAttribute("TownIncidentResolved", 0)
    world:SetAttribute("TownIncidentRequired", #definition.sites)
end

function WorldService.resolveTownIncidentSite(self: WorldService, siteId: string, resolved: number)
    local model = self._townIncidentModel
    local world = self._world
    if model == nil or world == nil then
        return
    end
    for _, child in model:GetChildren() do
        if child:IsA("Model") and child:GetAttribute("SiteId") == siteId then
            child:SetAttribute("Resolved", true)
            local target = child:FindFirstChild("IncidentCore")
            if target ~= nil and target:IsA("BasePart") then
                local interactionId = nil
                local prompt = target:FindFirstChildOfClass("ProximityPrompt")
                if prompt ~= nil then
                    interactionId = prompt:GetAttribute("InteractionId")
                    prompt:Destroy()
                end
                if type(interactionId) == "string" then
                    self._interactions[interactionId] = nil
                end
                local oldLabel = target:FindFirstChild("WorldLabel")
                if oldLabel ~= nil then
                    oldLabel:Destroy()
                end
                target.Color = Color3.fromRGB(72, 96, 66)
                addBillboard(target, "SECURED", FOXFIRE)
            end
            break
        end
    end
    world:SetAttribute("TownIncidentResolved", resolved)
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
    self:_setTownResidentRoutine(if enabled then "dusk" else "day")
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
            -- Must stay identical to the daytime values _configureLighting
            -- sets on world build. This function re-runs on every day/dusk
            -- transition (PhaseService:setNight(false),
            -- TownNightService:setDusk(false), and the Blackout restore
            -- path), so the two are effectively the same setting duplicated
            -- in two places -- if only one is updated, the fix holds until
            -- the first phase transition and then silently reverts. That is
            -- exactly what shipped here initially: the pale-sage atmosphere
            -- that washed distant terrain out to white was fixed in
            -- _configureLighting but left unchanged here.
            atmosphere.Color = Color3.fromRGB(74, 89, 98)
            atmosphere.Decay = Color3.fromRGB(38, 52, 58)
            atmosphere.Density = 0.24
            atmosphere.Haze = 1.0
            atmosphere.Glare = 0.15
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
    if self._nightThemeDressing ~= nil then
        self._nightThemeDressing:Destroy()
        self._nightThemeDressing = nil
    end
    if enabled and self._world ~= nil then
        self._nightThemeDressing = buildNightThemeDressing(self._world, theme or "EMBERFALL")
    end
    self:_setNightDefenseState(if enabled then "night" else "day", theme)
    self:_setTownResidentRoutine(if enabled then "night" elseif self._dusk then "dusk" else "day")
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
