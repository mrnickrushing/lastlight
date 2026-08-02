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
        _maraTrap: Model?,
        _lobby: Folder?,
        _lobbySpawn: SpawnLocation?,
        _departurePlatform: BasePart?,
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
local NIGHT_AMBIENT = Color3.fromRGB(19, 26, 43)
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
-- Staging yard, north of the arrival clearing and clear of the route that
-- leaves it. Inside the flat valley bowl (x -190..190, z -260..90), so every
-- authored coordinate here sits on level ground.
local LOBBY_CENTER = Vector3.new(0, 0, 62)
local DEPARTURE_PLATFORM_CENTER = Vector3.new(0, 0, 54)
local DEPARTURE_PLATFORM_RADIUS = 9
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
            position = Vector3.new(position.X, 2.42, position.Z),
            scale = 1,
            yaw = yaw,
            seed = seedBase + index,
            swayTag = nil,
            parent = parent,
            fallbackInstance = nil,
            profileScale = Vector3.new(1.12, 0.92, chunkLength / 18),
        })
    end
end

--[[
    Clear terrain above a road so nothing can bury it.

    The whole road stack is under a stud tall -- foundation, surface, and worn
    centre together top out around 0.9 -- while the valley floor fills to
    GROUND_Y. That leaves almost no margin, and it has already gone wrong once:
    a half-voxel error in the floor fill put the surface a stud high and every
    road in the world vanished under the grass with nothing in the logs.

    Rather than rely on the two numbers staying in agreement, cut the corridor
    out. Terrain is filled before any road is placed, so clearing a box from
    just above the floor upward removes anything that could sit over the
    surface and is a harmless no-op when the floor is already correct. The cut
    is kept narrower than the road so the edges still meet grass instead of
    leaving a floating lip.
]]
local function clearRoadCorridor(startPosition: Vector3, finishPosition: Vector3, width: number)
    local delta = finishPosition - startPosition
    local length = delta.Magnitude
    if length <= 0.05 or width <= 2 then
        return
    end
    local midpoint = (startPosition + finishPosition) * 0.5
    local frame = CFrame.lookAt(
        Vector3.new(midpoint.X, 0, midpoint.Z),
        Vector3.new(finishPosition.X, 0, finishPosition.Z)
    )
    local clearHeight = 14
    Workspace.Terrain:FillBlock(
        frame * CFrame.new(0, 0.1 + clearHeight * 0.5, 0),
        Vector3.new(width - 2, clearHeight, length + 2),
        Enum.Material.Air
    )
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
        hearthLight.Brightness = 1.05
        hearthLight.Range = 15
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
        windowLight.Brightness = 0.55
        windowLight.Range = 15
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
            local cotFallback = Instance.new("Model")
            cotFallback.Name = "MaraCotFallback"
            cotFallback.Parent = cabinFolder
            local cot = part(
                cotFallback,
                "MaraCot",
                Vector3.new(5.2, 0.55, 2.7),
                cabinCFrame(4.2, 1.0, 3.5),
                Color3.fromRGB(96, 112, 83),
                Enum.Material.Fabric,
                false
            )
            cot.CanQuery = false
            table.insert(meshPlacements, {
                assetId = "mesh_creator_wayfarer_bed_a",
                fallbackKind = "asset_replacement",
                -- MeshTemplateLoader normalizes the model's pivot to the
                -- bottom of its bounding box, so this Y is where the bed's
                -- underside lands, not its centre. 0.62 matches the interior
                -- floor (CabinWovenRug rests with its own bottom at the same
                -- height); -1.75 is the EXTERIOR ground level the barrel and
                -- crate correctly use a few lines below, since those sit
                -- outside the cabin footprint at x = -14.5 / 13.8. Copying
                -- that value here put the bed 2.36 studs under the interior
                -- floor -- fully invisible, since even its own top (0.53)
                -- never reached the floor it was meant to rest on (0.61).
                position = cabinCFrame(4.2, 0.62, 3.5).Position,
                scale = 1,
                -- No offset: the loader cancels the source model's stored
                -- rotation, so the bed's long axis already runs along the
                -- cabin's Z, head toward the back wall.
                yaw = yaw,
                seed = 9831,
                swayTag = nil,
                parent = cabinFolder,
                fallbackInstance = cotFallback,
            })
            local supplyFallback = Instance.new("Model")
            supplyFallback.Name = "MaraSupplyShelfFallback"
            supplyFallback.Parent = cabinFolder
            local tableTop = part(
                supplyFallback,
                "MaraWorkTable",
                Vector3.new(4.2, 0.45, 2.5),
                cabinCFrame(4.5, 2.15, -3.2),
                Color3.fromRGB(89, 64, 43),
                Enum.Material.WoodPlanks,
                false
            )
            tableTop.CanQuery = false
            -- A tabletop needs something holding it up.
            for legX = -1, 1, 2 do
                for legZ = -1, 1, 2 do
                    local leg = part(
                        supplyFallback,
                        "MaraWorkTableLeg",
                        Vector3.new(0.3, 1.7, 0.3),
                        cabinCFrame(4.5 + legX * 1.75, 1.28, -3.2 + legZ * 0.95),
                        Color3.fromRGB(72, 51, 34),
                        Enum.Material.Wood,
                        false
                    )
                    leg.CanQuery = false
                end
            end
            for jarIndex = -1, 1 do
                local jar = part(
                    supplyFallback,
                    "MemoryJar",
                    -- A Roblox Cylinder extends along its LOCAL X axis, so the
                    -- first component is the jar's height and the other two its
                    -- diameter. Sized (0.7, 1.05, 0.7) with no rotation these
                    -- were squat discs lying on their sides, not standing jars.
                    Vector3.new(1.05, 0.7, 0.7),
                    cabinCFrame(4.5 + jarIndex * 1.1, 2.9, -3.2) * CFrame.Angles(0, 0, math.rad(90)),
                    if jarIndex == 0 then FOXFIRE else AMBER,
                    Enum.Material.Glass,
                    false
                )
                jar.Shape = Enum.PartType.Cylinder
                jar.Transparency = 0.22
                jar.CanQuery = false
                local lid = part(
                    supplyFallback,
                    "MemoryJarLid",
                    Vector3.new(0.16, 0.76, 0.76),
                    cabinCFrame(4.5 + jarIndex * 1.1, 3.46, -3.2)
                        * CFrame.Angles(0, 0, math.rad(90)),
                    Color3.fromRGB(72, 51, 34),
                    Enum.Material.Wood,
                    false
                )
                lid.Shape = Enum.PartType.Cylinder
                lid.CanQuery = false
            end
            table.insert(meshPlacements, {
                assetId = "mesh_creator_potion_shelf_a",
                fallbackKind = "asset_replacement",
                position = cabinCFrame(4.5, 0.62, -3.2).Position,
                scale = 1,
                yaw = yaw + math.rad(90),
                seed = 9851,
                swayTag = nil,
                parent = cabinFolder,
                fallbackInstance = supplyFallback,
            })
        else
            for bedIndex = -1, 1, 2 do
                local bedrollFallback = Instance.new("Model")
                bedrollFallback.Name = "WayfarerBedrollFallback"
                bedrollFallback.Parent = cabinFolder
                local bedroll = part(
                    bedrollFallback,
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
                table.insert(meshPlacements, {
                    assetId = "mesh_creator_wayfarer_bed_a",
                    fallbackKind = "asset_replacement",
                    -- Same floor-height correction as Mara's bed above: 0.62
                    -- is the interior floor (WayfarerBedroll's own bottom
                    -- lands at ~0.73, in the same range); -1.75 is the
                    -- exterior ground level the barrel and crate use.
                    position = cabinCFrame(3.5 + bedIndex * 3.6, 0.62, 3.8).Position,
                    scale = 1,
                    yaw = yaw,
                    seed = 9840 + bedIndex,
                    swayTag = nil,
                    parent = cabinFolder,
                    fallbackInstance = bedrollFallback,
                })
            end
            local trunkFallback = Instance.new("Model")
            trunkFallback.Name = "WayfarerTrunkFallback"
            trunkFallback.Parent = cabinFolder
            local trunk = part(
                trunkFallback,
                "WayfarerTrunk",
                Vector3.new(4.4, 2.3, 2.5),
                cabinCFrame(5.2, 1.2, -3.6),
                Color3.fromRGB(88, 61, 39),
                Enum.Material.WoodPlanks,
                false
            )
            trunk.CanQuery = false
            table.insert(meshPlacements, {
                assetId = "mesh_creator_crate_a",
                fallbackKind = "asset_replacement",
                position = cabinCFrame(5.2, 0.62, -3.6).Position,
                scale = 1,
                yaw = yaw + math.rad(12),
                seed = 9861,
                swayTag = nil,
                parent = cabinFolder,
                fallbackInstance = trunkFallback,
            })
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
        CFrame.new(0, 1.81, -102),
        Color3.fromRGB(38, 41, 39),
        Enum.Material.Slate,
        false
    )
    streetFoundation.CanQuery = false
    local townStreet = part(
        parent,
        "TownMainStreet",
        Vector3.new(15.5, 0.32, 204),
        CFrame.new(0, 2.17, -102),
        Color3.fromRGB(183, 143, 91),
        Enum.Material.Cobblestone,
        false
    )
    townStreet.CanQuery = false
    local streetWear = part(
        parent,
        "TownMainStreetWear",
        Vector3.new(3.8, 0.12, 202),
        CFrame.new(0, 2.42, -102),
        Color3.fromRGB(88, 58, 37),
        Enum.Material.Mud,
        false
    )
    streetWear.CanQuery = false
    for rutSide = -1, 1, 2 do
        local rut = part(
            parent,
            "TownStreetRut",
            Vector3.new(0.68, 0.08, 200),
            CFrame.new(rutSide * 2.4, 2.5, -102),
            Color3.fromRGB(61, 43, 30),
            Enum.Material.Mud,
            false
        )
        rut.CanQuery = false
    end
    clearRoadCorridor(Vector3.new(0, 0, 1), Vector3.new(0, 0, -205), 18)
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
        clearRoadCorridor(start, finish, 8.6)
        local base = part(
            parent,
            "TownDistrictRoadFoundation",
            Vector3.new(8.6, 0.26, delta.Magnitude + 1.2),
            frame * CFrame.new(0, 1.5, 0),
            Color3.fromRGB(38, 41, 39),
            Enum.Material.Slate,
            false
        )
        base.CanQuery = false
        local surface = part(
            parent,
            "TownDistrictRoad",
            Vector3.new(7.2, 0.24, delta.Magnitude + 0.8),
            frame * CFrame.new(0, 1.81, 0),
            Color3.fromRGB(176, 137, 87),
            Enum.Material.Cobblestone,
            false
        )
        surface.CanQuery = false
        local wear = part(
            parent,
            "TownDistrictRoadWear",
            Vector3.new(2.1, 0.08, delta.Magnitude + 0.5),
            frame * CFrame.new(0, 2.01, 0),
            Color3.fromRGB(79, 52, 34),
            Enum.Material.Mud,
            false
        )
        wear.CanQuery = false
        queueRoadAssetPlacements(
            meshPlacements,
            parent,
            start + Vector3.new(0, 1.38, 0),
            finish + Vector3.new(0, 1.38, 0),
            9700 + #meshPlacements
        )
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
    light.Brightness = 1.95
    light.Range = 27 * scale
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
    -- Labels used to sit ~3.6 studs up, which on a waist-high display put the
    -- card directly over the object it was naming. Sitting them well clear
    -- keeps the prop readable, which is the order the visual standard asks
    -- for: recognize the object first, read the label second.
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 7.4, 0)
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
        _maraTrap = nil,
        _lobby = nil,
        _lobbySpawn = nil,
        _departurePlatform = nil,
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
    table.freeze({ x = 0, z = 62, radius = 52 }), -- the departure lodge and its clearing
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
        -- Extend behind ArrivalSpawn so the opening camera visibly starts on
        -- the route instead of looking across an unbroken foreground of grass.
        Vector3.new(0, 0.42, 18),
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
        clearRoadCorridor(start, finish, 17.2)
        local foundation = part(
            geometry,
            "EmberhollowRoadFoundation",
            Vector3.new(17.2, 0.28, distance + 4),
            roadFrame * CFrame.new(0, 1.42, 0),
            Color3.fromRGB(38, 41, 39),
            Enum.Material.Slate,
            false
        )
        foundation.CanQuery = false
        local trail = part(
            geometry,
            "EmberhollowRoad",
            Vector3.new(15.2, 0.36, distance + 3.6),
            -- Studio verification showed the voxel-rendered valley surface
            -- occluding the authored y=0 plane by about 1.5 studs. Keeping the
            -- route non-colliding while lifting its visual skin preserves the
            -- gameplay plane and makes the road actually render underfoot.
            roadFrame * CFrame.new(0, 1.77, 0),
            Color3.fromRGB(190, 149, 94),
            Enum.Material.Cobblestone,
            false
        )
        trail.CanQuery = false
        trail.Reflectance = 0.02
        local wornCenter = part(
            geometry,
            "EmberhollowRoadWear",
            Vector3.new(3.6, 0.12, distance + 2.8),
            roadFrame * CFrame.new(0, 2.05, 0),
            Color3.fromRGB(78, 51, 33),
            Enum.Material.Mud,
            false
        )
        wornCenter.CanQuery = false

        -- A continuous dark shoulder on both sides makes the path silhouette
        -- survive fog, grass texture, and the low morning camera angle. Sparse
        -- edge stones alone disappeared into the meadow between placements.
        for shoulderSide = -1, 1, 2 do
            local shoulder = part(
                geometry,
                "RoadShoulder",
                Vector3.new(1.15, 0.3, distance + 3.2),
                roadFrame * CFrame.new(shoulderSide * 7.45, 1.83, 0),
                Color3.fromRGB(57, 62, 59),
                Enum.Material.Slate,
                false
            )
            shoulder.CanQuery = false
        end

        for rutSide = -1, 1, 2 do
            local rut = part(
                geometry,
                "RoadRut",
                Vector3.new(0.62, 0.08, distance + 1),
                roadFrame * CFrame.new(rutSide * 2.25, 2.14, 0),
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
                    Vector3.new(1.3, 0.62, 1.75),
                    roadFrame
                        * CFrame.new(side * 7.85, 2.13, along)
                        * CFrame.Angles(0, math.rad(side * (marker % 2) * 7), 0),
                    if marker % 3 == 0
                        then Color3.fromRGB(132, 124, 101)
                        else Color3.fromRGB(84, 94, 89),
                    Enum.Material.Slate,
                    false
                )
                edgeStone.CanQuery = false
            end
        end
        -- Glowing waymarkers down the road centre. The route already has
        -- lantern posts and chevrons, but nothing that reads as "this way" at
        -- a glance in the dark, so the road can be underfoot and still not
        -- answer where to go next. These are foxfire inlays set into the worn
        -- centre, pointing along travel direction and brightening toward the
        -- destination so the trail has a readable gradient rather than a flat
        -- dotted line. Semantic, not decorative: they mark the critical route
        -- only, never the side spurs.
        local guideCount = math.max(2, math.floor(distance / 8))
        -- Half-open [start, finish): the finish of one segment is the start of
        -- the next, so an inclusive loop stacks two wedges and two PointLights
        -- on the exact same spot at every bend, with different headings. That
        -- reads as crossed, z-fighting arrows and a double-bright junction
        -- rather than one continuous trail.
        for guide = 0, guideCount - 1 do
            local along = -distance * 0.5 + distance * guide / guideCount
            local progress = (segment - 1 + guide / guideCount) / (#route - 1)
            local wedge = part(
                geometry,
                "RouteGuideMarker",
                Vector3.new(1.9, 0.12, 2.65),
                -- The route frame sits at Y = 0.42 and the worn road surface
                -- tops out at 0.91, so this offset puts the wedge's underside
                -- at 0.89 -- inlaid into the road. At 0.94 it floated a full
                -- 0.4 studs above the surface and pulsed in mid-air.
                roadFrame * CFrame.new(0, 2.15, along) * CFrame.Angles(0, math.pi, 0),
                FOXFIRE,
                Enum.Material.Neon,
                false
            )
            wedge.Shape = Enum.PartType.Wedge
            wedge.Transparency = 0.34 - progress * 0.16
            wedge.CastShadow = false
            wedge.CanQuery = false
            CollectionService:AddTag(wedge, _self._runtimeIds.AmbientLightTag)
            local guideLight = Instance.new("PointLight")
            guideLight.Color = FOXFIRE
            guideLight.Brightness = 0.5 + progress * 0.45
            guideLight.Range = 11
            guideLight.Shadows = false
            guideLight.Parent = wedge
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
    -- The sourced sign has its own two-board silhouette. Keeping the legacy
    -- fallback SurfaceGui after replacement projects one wide sentence across
    -- both irregular boards and clips it into unreadable fragments.
    routeSign:SetAttribute("HideSemanticGuiOnReplacement", true)
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
        -- Gate towers flank the Dawn Gate at (0, -148). At x = +/-10.5 they
        -- stood 21 studs apart across an 18-stud road -- effectively touching
        -- the verges, with no room for the gate between them. Real gatehouse
        -- towers sit outside the opening on the wall line, far enough apart
        -- that traffic passes cleanly between and each tower covers the other's
        -- approach. 38 studs apart, level with the gate.
        local towerCenter = Vector3.new(side * 19, 0, -148)
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
    local removeSemanticGui = placeholder:GetAttribute("HideSemanticGuiOnReplacement") == true
    local instances = placeholder:GetDescendants()
    table.insert(instances, placeholder)
    for _, instance in instances do
        if removeSemanticGui and (instance:IsA("SurfaceGui") or instance:IsA("BillboardGui")) then
            instance:Destroy()
        elseif instance:IsA("BasePart") then
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
            or instance:IsA("LayerCollector")
        then
            instance.Enabled = false
        end
    end
    placeholder:SetAttribute("ReplacedByAuthoredMesh", true)
end

local function keepReplacedAnchorHidden(target: BasePart)
    if target:GetAttribute("ReplacedByAuthoredMesh") ~= true then
        return
    end
    target.Transparency = 1
    target.CastShadow = false
    for _, child in target:GetChildren() do
        if child:IsA("LayerCollector") then
            child.Enabled = false
        end
    end
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

-- Dynamic enemies keep their original primitive geometry as an invisible,
-- authoritative combat volume. Only the visible shell is replaced, so a
-- cosmetic Creator Store model can never change reach, navigation, or hits.
function WorldService.placeEnemyVisual(self: WorldService, model: Model, modelKey: string): boolean
    local visualProfiles = {
        rootling = {
            assetId = "mesh_creator_hollow_rootling_a",
            groundOffset = 2,
            yaw = math.rad(8),
            profile = Vector3.new(0.9, 1.06, 0.84),
        },
        briarback = {
            assetId = "mesh_creator_earth_golem_a",
            groundOffset = 2.4,
            yaw = math.rad(-7),
            profile = Vector3.new(1.08, 0.9, 1.12),
        },
        zombie = {
            assetId = "mesh_zombie_a",
            groundOffset = 2.9,
            yaw = math.rad(180),
            profile = Vector3.new(1, 1.04, 1),
            scale = 1,
        },
        hollow_crow = {
            assetId = "mesh_creator_raven_a",
            groundOffset = 1.1,
            yaw = math.rad(180),
            profile = Vector3.new(1.16, 0.9, 0.94),
            scale = 2,
        },
        snapvine = {
            assetId = "mesh_creator_predatory_flower_a",
            groundOffset = 2,
            yaw = math.rad(-11),
            profile = Vector3.new(0.92, 1.08, 1.04),
            scale = 1.25,
        },
        bark_ram = {
            assetId = "mesh_creator_bark_ram_a",
            groundOffset = 2.5,
            yaw = math.rad(180),
            profile = Vector3.new(1.12, 0.88, 1.05),
            scale = 1.35,
        },
        old_growth = {
            assetId = "mesh_creator_old_growth_a",
            groundOffset = 9,
            yaw = math.rad(180),
            profile = Vector3.new(0.94, 1.08, 0.9),
        },
        warden_stag = {
            assetId = "mesh_creator_wood_ibex_a",
            groundOffset = 10,
            yaw = math.rad(180),
            profile = Vector3.new(1.08, 1.14, 0.94),
            scale = 3,
        },
    }
    local profile = visualProfiles[modelKey]
    local core = model.PrimaryPart
    if profile == nil or core == nil or model.Parent == nil then
        return false
    end

    local fallbackParts = {}
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            table.insert(fallbackParts, descendant)
        end
    end
    local bottomPosition = core.Position - Vector3.new(0, profile.groundOffset, 0)
    local at = CFrame.new(bottomPosition) * core.CFrame.Rotation * CFrame.Angles(0, profile.yaw, 0)
    local placed, result = pcall(
        self._meshTemplateLoader.place,
        self._meshTemplateLoader,
        profile.assetId,
        model,
        at,
        profile.scale or 1,
        profile.profile
    )
    local authored = if placed then result else nil
    if authored == nil then
        self._logger:info("enemy_asset_visual_failed", {
            assetId = profile.assetId,
            enemy = modelKey,
            error = if placed then "asset_unavailable" else tostring(result),
        })
        return false
    end
    authored.Name = "AuthoredEnemyVisual"
    for _, fallbackPart in fallbackParts do
        fallbackPart.Transparency = 1
        fallbackPart.CastShadow = false
        fallbackPart:SetAttribute("AuthoritativeEnemyHitbox", fallbackPart == core)
    end
    model:SetAttribute("EnemyVisualAssetId", profile.assetId)
    model:SetAttribute("EnemyVisualReady", true)
    return true
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

--[[
    The Emberhollow departure yard.

    Where a session starts: a lantern-lit staging courtyard with a character
    hut on one side, a notice board and stall on the other, and a raised
    departure platform at its south edge facing the road out to the arrival
    clearing. Standing on that platform is what puts a player in the party;
    the countdown and the launch itself belong to LobbyService.

    Built to the same standard as the rest of the world rather than as a grey
    box: layered ground, a real timber-framed hut with a roof and rafters,
    banded platform edging, practical lantern light, and reviewed props. The
    platform reads as a threshold you deliberately step onto -- raised, ringed,
    and pointed at the gate -- because that is the whole mechanic.
]]
function WorldService._buildLobby(self: WorldService, world: Model)
    local lobby = Instance.new("Folder")
    lobby.Name = "EmberhollowLobby"
    lobby.Parent = world
    self._lobby = lobby

    -- Interior half-extents. The room is deliberately oversized for a cabin:
    -- a third-person camera needs to orbit a whole party inside it without
    -- clipping the walls, and the departure platform needs clear floor around
    -- it so stepping on is an obvious, deliberate act.
    local halfWidth = 32
    local halfDepth = 24
    local wallHeight = 18

    groundPatch(
        lobby,
        LOBBY_CENTER,
        Vector3.new(halfWidth * 2 + 20, 0.3, halfDepth * 2 + 20),
        Color3.fromRGB(46, 55, 45),
        Enum.Material.LeafyGrass
    )

    local floor = part(
        lobby,
        "LodgeFloor",
        Vector3.new(halfWidth * 2, 1, halfDepth * 2),
        CFrame.new(LOBBY_CENTER + Vector3.new(0, 0.5, 0)),
        Color3.fromRGB(86, 62, 43),
        Enum.Material.WoodPlanks
    )
    floor.CanQuery = false
    for plankIndex = -15, 15 do
        local plank = part(
            lobby,
            "LodgeFloorPlank",
            Vector3.new(1.9, 0.08, halfDepth * 2 - 1),
            CFrame.new(LOBBY_CENTER + Vector3.new(plankIndex * 2.05, 1.02, 0)),
            if plankIndex % 2 == 0 then Color3.fromRGB(94, 68, 47) else Color3.fromRGB(78, 56, 39),
            Enum.Material.WoodPlanks,
            false
        )
        plank.CanQuery = false
    end

    -- Walls stay collidable so the camera stops at them and the room reads as
    -- an interior. The roof above is non-colliding, so the camera passes
    -- through it instead of shoving itself into the player's back.
    local function wall(name: string, size: Vector3, at: Vector3)
        part(
            lobby,
            name,
            size,
            CFrame.new(LOBBY_CENTER + at),
            Color3.fromRGB(72, 52, 37),
            Enum.Material.Wood
        )
    end
    wall(
        "LodgeWallBack",
        Vector3.new(halfWidth * 2, wallHeight, 1.2),
        Vector3.new(0, wallHeight / 2, halfDepth)
    )
    for wallSide = -1, 1, 2 do
        wall(
            "LodgeWallSide",
            Vector3.new(1.2, wallHeight, halfDepth * 2),
            Vector3.new(wallSide * halfWidth, wallHeight / 2, 0)
        )
    end
    -- Front wall with a wide doorway looking out toward Emberhollow.
    for frontSide = -1, 1, 2 do
        wall(
            "LodgeWallFront",
            Vector3.new(halfWidth - 7, wallHeight, 1.2),
            Vector3.new(frontSide * (halfWidth + 7) / 2, wallHeight / 2, -halfDepth)
        )
    end
    wall(
        "LodgeDoorHeader",
        Vector3.new(14, wallHeight - 11, 1.2),
        Vector3.new(0, wallHeight - (wallHeight - 11) / 2, -halfDepth)
    )

    -- Log courses and corner posts so the walls read as built timber.
    for courseIndex = 1, 5 do
        for courseSide = -1, 1, 2 do
            local course = part(
                lobby,
                "LodgeLogCourse",
                Vector3.new(1.5, 1.5, halfDepth * 2),
                CFrame.new(
                    LOBBY_CENTER + Vector3.new(courseSide * (halfWidth - 0.4), courseIndex * 3.3, 0)
                ),
                if courseIndex % 2 == 0 then BARK else WET_BARK,
                Enum.Material.Wood,
                false
            )
            course.CanQuery = false
        end
    end
    for cornerX = -1, 1, 2 do
        for cornerZ = -1, 1, 2 do
            part(
                lobby,
                "LodgeCornerPost",
                Vector3.new(2.4, wallHeight + 1, 2.4),
                CFrame.new(
                    LOBBY_CENTER
                        + Vector3.new(
                            cornerX * halfWidth,
                            (wallHeight + 1) / 2,
                            cornerZ * halfDepth
                        )
                ),
                WET_BARK,
                Enum.Material.Wood,
                false
            )
        end
    end

    -- Roof: high, and non-colliding so the camera never fights it.
    local ridgeHeight = wallHeight + 9
    local ridge = part(
        lobby,
        "LodgeRidgeBeam",
        Vector3.new(1.4, 1.4, halfDepth * 2 + 3),
        CFrame.new(LOBBY_CENTER + Vector3.new(0, ridgeHeight, 0)),
        WET_BARK,
        Enum.Material.Wood,
        false
    )
    ridge.CanQuery = false
    for roofSide = -1, 1, 2 do
        local roof = part(
            lobby,
            "LodgeRoof",
            Vector3.new(halfWidth + 3, 10, halfDepth * 2 + 4),
            CFrame.new(LOBBY_CENTER + Vector3.new(roofSide * (halfWidth / 2), wallHeight + 4.5, 0))
                * CFrame.Angles(0, if roofSide < 0 then math.pi else 0, 0),
            Color3.fromRGB(48, 53, 49),
            Enum.Material.Slate,
            false
        )
        roof.Shape = Enum.PartType.Wedge
        roof.CanQuery = false
    end
    for rafterIndex = -5, 5 do
        for rafterSide = -1, 1, 2 do
            local rafter = part(
                lobby,
                "LodgeRafter",
                Vector3.new(0.5, 0.5, halfWidth * 0.72),
                CFrame.new(
                    LOBBY_CENTER
                        + Vector3.new(
                            rafterSide * halfWidth * 0.26,
                            wallHeight + 4.6,
                            rafterIndex * 4.3
                        )
                ) * CFrame.Angles(0, math.rad(90), math.rad(rafterSide * 30)),
                WET_BARK,
                Enum.Material.Wood,
                false
            )
            rafter.CanQuery = false
        end
    end

    -- Warm interior light so the room is lit from inside, not by the sky.
    for lampIndex = -1, 1, 2 do
        for lampZ = -1, 1, 2 do
            local lampAt = LOBBY_CENTER
                + Vector3.new(lampIndex * (halfWidth - 9), wallHeight - 4, lampZ * (halfDepth - 8))
            local lamp = part(
                lobby,
                "LodgeLamp",
                Vector3.new(1.5, 1.8, 1.5),
                CFrame.new(lampAt),
                AMBER,
                Enum.Material.Neon,
                false
            )
            lamp.CastShadow = false
            lamp.CanQuery = false
            local lampLight = Instance.new("PointLight")
            -- Four lamps at 1.5/42 plus the hearth plus the platform washed
            -- the whole room to flat yellow and hid every material in it.
            -- Wall lamps now only pool light near the walls; the hearth and
            -- the platform are what the eye should actually go to.
            lampLight.Color = AMBER
            lampLight.Brightness = 0.5
            lampLight.Range = 20
            lampLight.Parent = lamp
            CollectionService:AddTag(lamp, self._runtimeIds.AmbientLightTag)
        end
    end

    -- Hearth at the back wall: the reason a lodge feels occupied.
    local hearthAt = LOBBY_CENTER + Vector3.new(0, 0, halfDepth - 4)
    part(
        lobby,
        "LodgeHearth",
        Vector3.new(13, 7, 4),
        CFrame.new(hearthAt + Vector3.new(0, 4.5, 1.4)),
        Color3.fromRGB(78, 82, 78),
        Enum.Material.Slate
    )
    part(
        lobby,
        "LodgeHearthMantel",
        Vector3.new(15, 0.8, 5.2),
        CFrame.new(hearthAt + Vector3.new(0, 8.2, 1.2)),
        WET_BARK,
        Enum.Material.Wood,
        false
    )
    part(
        lobby,
        "LodgeChimneyBreast",
        Vector3.new(9, wallHeight - 8, 3),
        CFrame.new(hearthAt + Vector3.new(0, 8.2 + (wallHeight - 8) / 2, 1.4)),
        Color3.fromRGB(70, 74, 70),
        Enum.Material.Slate,
        false
    )
    for jambSide = -1, 1, 2 do
        part(
            lobby,
            "LodgeHearthJamb",
            Vector3.new(2.2, 6, 3.4),
            CFrame.new(hearthAt + Vector3.new(jambSide * 5.4, 3, 0.9)),
            Color3.fromRGB(88, 92, 88),
            Enum.Material.Slate,
            false
        )
    end
    part(
        lobby,
        "LodgeHearthFender",
        Vector3.new(11, 0.6, 3),
        CFrame.new(hearthAt + Vector3.new(0, 1.3, -1.6)),
        Color3.fromRGB(58, 62, 58),
        Enum.Material.Slate,
        false
    )
    for logIndex = -1, 1 do
        part(
            lobby,
            "LodgeHearthLog",
            Vector3.new(0.9, 0.9, 4.4),
            CFrame.new(hearthAt + Vector3.new(logIndex * 1.1, 1.6, 0.2))
                * CFrame.Angles(0, math.rad(logIndex * 14), math.rad(90)),
            WET_BARK,
            Enum.Material.Wood,
            false
        )
    end
    local hearthFire = part(
        lobby,
        "LodgeHearthFire",
        Vector3.new(4.5, 3, 1.8),
        CFrame.new(hearthAt + Vector3.new(0, 2.6, 0.2)),
        AMBER,
        Enum.Material.Neon,
        false
    )
    hearthFire.CastShadow = false
    local hearthLight = Instance.new("PointLight")
    hearthLight.Color = AMBER
    hearthLight.Brightness = 1.5
    hearthLight.Range = 30
    hearthLight.Parent = hearthFire
    CollectionService:AddTag(hearthFire, self._runtimeIds.AmbientLightTag)

    --[[
        The departure platform, in the middle of the floor and impossible to
        miss: a raised timber dais on a stone base, ringed with a bright amber
        inlay, lit from four corner posts, with a floating title above it.
        Standing on it is the whole mechanic, so it is the brightest and most
        deliberate object in the room.
    ]]
    local platform = part(
        lobby,
        "DeparturePlatform",
        Vector3.new(DEPARTURE_PLATFORM_RADIUS * 2, 1.6, DEPARTURE_PLATFORM_RADIUS * 2),
        CFrame.new(DEPARTURE_PLATFORM_CENTER + Vector3.new(0, 1.8, 0)),
        Color3.fromRGB(84, 61, 43),
        Enum.Material.WoodPlanks
    )
    self._departurePlatform = platform
    local platformBase = part(
        lobby,
        "DeparturePlatformBase",
        Vector3.new(DEPARTURE_PLATFORM_RADIUS * 2 + 3, 1.1, DEPARTURE_PLATFORM_RADIUS * 2 + 3),
        CFrame.new(DEPARTURE_PLATFORM_CENTER + Vector3.new(0, 1.05, 0)),
        Color3.fromRGB(66, 70, 66),
        Enum.Material.Slate
    )
    platformBase.CanQuery = false
    for stepSide = -1, 1, 2 do
        local step = part(
            lobby,
            "DepartureStep",
            Vector3.new(DEPARTURE_PLATFORM_RADIUS * 1.5, 0.6, 2.4),
            CFrame.new(
                DEPARTURE_PLATFORM_CENTER
                    + Vector3.new(0, 0.8, stepSide * (DEPARTURE_PLATFORM_RADIUS + 2.4))
            ),
            Color3.fromRGB(74, 78, 74),
            Enum.Material.Slate
        )
        step.CanQuery = false
    end
    for markIndex = 0, 31 do
        local angle = (markIndex / 32) * math.pi * 2
        local mark = part(
            lobby,
            "DepartureRing",
            Vector3.new(1.3, 0.14, 0.6),
            CFrame.new(
                DEPARTURE_PLATFORM_CENTER
                    + Vector3.new(
                        math.cos(angle) * (DEPARTURE_PLATFORM_RADIUS - 1.5),
                        2.66,
                        math.sin(angle) * (DEPARTURE_PLATFORM_RADIUS - 1.5)
                    )
            ) * CFrame.Angles(0, -angle, 0),
            AMBER,
            Enum.Material.Neon,
            false
        )
        mark.Transparency = 0.24
        mark.CastShadow = false
        mark.CanQuery = false
    end
    local platformGlow = part(
        lobby,
        "DepartureGlow",
        Vector3.new(DEPARTURE_PLATFORM_RADIUS * 1.7, 0.12, DEPARTURE_PLATFORM_RADIUS * 1.7),
        CFrame.new(DEPARTURE_PLATFORM_CENTER + Vector3.new(0, 2.64, 0)),
        AMBER,
        Enum.Material.Neon,
        false
    )
    platformGlow.Transparency = 0.72
    platformGlow.CastShadow = false
    platformGlow.CanQuery = false
    local platformLight = Instance.new("PointLight")
    platformLight.Color = AMBER
    platformLight.Brightness = 1.1
    platformLight.Range = 22
    platformLight.Parent = platformGlow
    CollectionService:AddTag(platformGlow, self._runtimeIds.AmbientLightTag)
    for postIndex = 0, 3 do
        local angle = (postIndex / 4) * math.pi * 2 + math.pi / 4
        local postAt = DEPARTURE_PLATFORM_CENTER
            + Vector3.new(
                math.cos(angle) * (DEPARTURE_PLATFORM_RADIUS + 0.6),
                0,
                math.sin(angle) * (DEPARTURE_PLATFORM_RADIUS + 0.6)
            )
        part(
            lobby,
            "DepartureLanternPost",
            Vector3.new(0.7, 9.5, 0.7),
            CFrame.new(postAt + Vector3.new(0, 4.75, 0)),
            WET_BARK,
            Enum.Material.Wood,
            false
        )
        local lampGlow = part(
            lobby,
            "DepartureLanternGlow",
            Vector3.new(1.2, 1.5, 1.2),
            CFrame.new(postAt + Vector3.new(0, 9.2, 0)),
            AMBER,
            Enum.Material.Neon,
            false
        )
        lampGlow.CastShadow = false
        lampGlow.CanQuery = false
        local lampLight = Instance.new("PointLight")
        lampLight.Color = AMBER
        lampLight.Brightness = 0.6
        lampLight.Range = 14
        lampLight.Parent = lampGlow
    end
    addBillboard(platform, "STAND HERE TO DEPART", AMBER, 120)

    -- Everything a staging room needs, indoors: work surfaces, supplies, a
    -- table to gather at, beds along the back, and the notice board.
    --[[
        Furnishing, arranged rather than scattered.

        Everything sits against a wall on a defined side of the room, so the
        centre floor stays clear for the platform and a party walking to it.
        Loose barrels dropped in the middle of the floor is what made the first
        pass read as a storeroom someone had emptied out.

          west wall  -- the work side: bench, anvil, shelf, tool rack
          east wall  -- the rest side: beds, table, notice board
          front wall -- stores stacked either side of the doorway
    ]]
    local props = {
        -- West wall: work.
        { asset = "mesh_creator_workbench_a", at = Vector3.new(-25, 0, 6), yaw = 90, scale = 1 },
        { asset = "mesh_creator_tool_set_a", at = Vector3.new(-25, 2.7, 6), yaw = 90, scale = 0.7 },
        { asset = "mesh_creator_anvil_a", at = Vector3.new(-25.5, 0, 13), yaw = 90, scale = 1 },
        {
            asset = "mesh_creator_potion_shelf_a",
            at = Vector3.new(-27.5, 0, 0),
            yaw = 90,
            scale = 1,
        },
        { asset = "mesh_creator_crate_a", at = Vector3.new(-27, 0, -8), yaw = 90, scale = 1 },
        { asset = "mesh_creator_barrel_a", at = Vector3.new(-27, 0, -13), yaw = 0, scale = 1 },
        -- East wall: rest.
        {
            asset = "mesh_creator_wayfarer_bed_a",
            at = Vector3.new(25.5, 0, 14),
            yaw = -90,
            scale = 1,
        },
        {
            asset = "mesh_creator_wayfarer_bed_a",
            at = Vector3.new(25.5, 0, 5),
            yaw = -90,
            scale = 1,
        },
        {
            asset = "mesh_creator_picnic_table_a",
            at = Vector3.new(23, 0, -6),
            yaw = 0,
            scale = 1.1,
        },
        {
            asset = "mesh_creator_notice_board_a",
            at = Vector3.new(27, 0, -15),
            yaw = -90,
            scale = 0.9,
        },
        -- Either side of the doorway: stores.
        { asset = "mesh_creator_crate_a", at = Vector3.new(-13, 0, -20), yaw = 0, scale = 1 },
        { asset = "mesh_creator_barrel_a", at = Vector3.new(-17, 0, -20), yaw = 0, scale = 1 },
        { asset = "mesh_creator_crate_a", at = Vector3.new(15, 0, -20), yaw = 0, scale = 1 },
    }
    for propIndex, prop in props do
        table.insert(self._meshPlacements, {
            assetId = prop.asset,
            fallbackKind = "asset_dressing",
            position = LOBBY_CENTER + prop.at + Vector3.new(0, 1, 0),
            scale = prop.scale,
            yaw = math.rad(prop.yaw),
            seed = 9460 + propIndex,
            swayTag = nil,
            parent = lobby,
            fallbackInstance = nil,
        })
    end

    labelSign(
        lobby,
        CFrame.new(LOBBY_CENTER + Vector3.new(10, 0, -halfDepth + 3))
            * CFrame.Angles(0, math.rad(180), 0),
        "TO EMBERHOLLOW"
    )

    -- Spawn at the back of the room, facing the platform and the doorway
    -- beyond it, so the first thing a player sees is where to go.
    local lobbySpawn = Instance.new("SpawnLocation")
    lobbySpawn.Name = "LobbySpawn"
    lobbySpawn.Size = Vector3.new(16, 1, 10)
    lobbySpawn.CFrame = CFrame.new(LOBBY_CENTER + Vector3.new(0, 1.5, halfDepth - 12))
        * CFrame.Angles(0, math.rad(180), 0)
    lobbySpawn.Transparency = 1
    lobbySpawn.Anchored = true
    lobbySpawn.CanCollide = true
    lobbySpawn.Neutral = true
    lobbySpawn.Duration = 0
    lobbySpawn.Parent = lobby
    self._lobbySpawn = lobbySpawn
end

function WorldService._buildMara(self: WorldService, world: Model)
    -- A real R15 rig instead of ~30 hand-stacked primitive parts. Mara used
    -- to read as a box with a sphere for a head because nothing gave
    -- residents an actual articulated body; CreateHumanoidModelFromDescription
    -- builds Roblox's own body meshes (rounded head, jointed limbs, real
    -- hands and feet) tinted to her palette, with no external asset download
    -- required.
    local skin = Color3.fromRGB(205, 153, 111)
    local coat = Color3.fromRGB(59, 83, 62)
    local coatDark = Color3.fromRGB(45, 51, 48)
    local hairColor = Color3.fromRGB(79, 43, 31)

    local description = Instance.new("HumanoidDescription")
    description.HeadColor = skin
    description.LeftArmColor = coat
    description.RightArmColor = coat
    description.TorsoColor = coat
    description.LeftLegColor = coatDark
    description.RightLegColor = coatDark
    -- The default R15 rig is a broad, blocky, androgynous silhouette that read
    -- as male. Narrowing the shoulders and depth while easing the body toward
    -- avatar proportions gives a feminine frame to hang her clothing on; the
    -- long hair, waisted coat, and flared coat tails below do the rest. These
    -- stay conservative on purpose -- pushed further the stock rig stretches
    -- and reads uncanny rather than simply slimmer.
    description.HeightScale = 0.99
    description.WidthScale = 0.84
    description.DepthScale = 0.9
    description.HeadScale = 1.04
    description.BodyTypeScale = 0.3
    description.ProportionScale = 0.75

    local model = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
    model.Name = "Mara"
    model:SetAttribute("ResidentId", "npc_mara")
    model:PivotTo(CFrame.new(-3, 3, -30))

    local maraHumanoid = model:WaitForChild("Humanoid") :: Humanoid
    maraHumanoid.DisplayName = "Mara"
    maraHumanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    maraHumanoid.BreakJointsOnDeath = false
    maraHumanoid.RequiresNeck = false

    local root = model:WaitForChild("HumanoidRootPart") :: BasePart
    root.Transparency = 1
    local torso = model:WaitForChild("UpperTorso") :: BasePart
    local head = model:WaitForChild("Head") :: BasePart
    -- The old body was entirely non-colliding and non-queryable (interaction
    -- goes through _registerInteraction below, not physical touch/click), so
    -- keep the real rig's parts out of the way of players the same way.
    --
    -- Anchoring is what keeps her in the world at all. The hand-built body this
    -- replaced was made of part() calls, which anchor by default; a rig from
    -- CreateHumanoidModelFromDescription arrives unanchored, and because every
    -- part here is also CanCollide = false there is nothing under her to stand
    -- on. She fell through the valley floor the instant the world built and
    -- kept going -- the rescue's PivotTo only appeared to fix it, yanking her
    -- back up for the ~1s of the move loop before she resumed falling. She is
    -- a static NPC repositioned exclusively through PivotTo (see moveMara and
    -- the resident ambient motion), so nothing here needs physics.
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
        end
    end

    -- Welds are redundant while every part above is anchored, but they keep the
    -- accessories attached to the body they were measured against if this rig
    -- is ever put back under physics.
    local function attach(piece: BasePart, to: BasePart)
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = to
        weld.Part1 = piece
        weld.Parent = piece
    end

    -- Hair, in layers. One sphere on top of the skull is what the character
    -- standard specifically calls out as not-a-hairstyle, and a cropped cap is
    -- most of why she read as male at gameplay distance.
    local hairCrown = part(
        model,
        "Hair",
        Vector3.new(head.Size.X * 1.12, head.Size.Y * 0.62, head.Size.Z * 1.12),
        head.CFrame * CFrame.new(0, head.Size.Y * 0.36, 0),
        hairColor,
        Enum.Material.SmoothPlastic,
        false
    )
    hairCrown.Shape = Enum.PartType.Ball
    attach(hairCrown, head)
    local hairFall = part(
        model,
        "HairFall",
        Vector3.new(head.Size.X * 1.02, head.Size.Y * 1.5, head.Size.Z * 0.66),
        head.CFrame * CFrame.new(0, -head.Size.Y * 0.42, head.Size.Z * 0.5),
        hairColor,
        Enum.Material.SmoothPlastic,
        false
    )
    attach(hairFall, head)
    for hairSide = -1, 1, 2 do
        local strand = part(
            model,
            "HairStrand",
            Vector3.new(head.Size.X * 0.26, head.Size.Y * 1.15, head.Size.Z * 0.72),
            head.CFrame
                * CFrame.new(hairSide * head.Size.X * 0.46, -head.Size.Y * 0.2, 0)
                * CFrame.Angles(0, 0, math.rad(hairSide * -4)),
            hairColor,
            Enum.Material.SmoothPlastic,
            false
        )
        attach(strand, head)
    end
    local braid = part(
        model,
        "HairBraid",
        Vector3.new(head.Size.X * 0.34, head.Size.Y * 0.9, head.Size.Z * 0.34),
        head.CFrame
            * CFrame.new(0, -head.Size.Y * 1.15, head.Size.Z * 0.56)
            * CFrame.Angles(math.rad(-9), 0, 0),
        Color3.fromRGB(64, 34, 25),
        Enum.Material.SmoothPlastic,
        false
    )
    attach(braid, head)

    -- A readable face. The standard requires eyes plus at least a nose and
    -- mouth; the stock rig head ships with none of them. Roblox heads face -Z.
    for eyeSide = -1, 1, 2 do
        local eye = part(
            model,
            "Eye",
            Vector3.new(head.Size.X * 0.15, head.Size.Y * 0.15, head.Size.Z * 0.1),
            head.CFrame
                * CFrame.new(eyeSide * head.Size.X * 0.22, head.Size.Y * 0.08, -head.Size.Z * 0.48),
            Color3.fromRGB(38, 44, 42),
            Enum.Material.SmoothPlastic,
            false
        )
        eye.Shape = Enum.PartType.Ball
        attach(eye, head)
        local brow = part(
            model,
            "Brow",
            Vector3.new(head.Size.X * 0.22, head.Size.Y * 0.05, head.Size.Z * 0.08),
            head.CFrame
                * CFrame.new(eyeSide * head.Size.X * 0.22, head.Size.Y * 0.21, -head.Size.Z * 0.47),
            Color3.fromRGB(64, 34, 25),
            Enum.Material.SmoothPlastic,
            false
        )
        attach(brow, head)
    end
    local nose = part(
        model,
        "Nose",
        Vector3.new(head.Size.X * 0.12, head.Size.Y * 0.16, head.Size.Z * 0.16),
        head.CFrame * CFrame.new(0, -head.Size.Y * 0.04, -head.Size.Z * 0.52),
        Color3.fromRGB(196, 143, 103),
        Enum.Material.SmoothPlastic,
        false
    )
    attach(nose, head)
    local mouth = part(
        model,
        "Mouth",
        Vector3.new(head.Size.X * 0.24, head.Size.Y * 0.06, head.Size.Z * 0.08),
        head.CFrame * CFrame.new(0, -head.Size.Y * 0.26, -head.Size.Z * 0.48),
        Color3.fromRGB(142, 84, 74),
        Enum.Material.SmoothPlastic,
        false
    )
    attach(mouth, head)

    local scarf = part(
        model,
        "Scarf",
        Vector3.new(torso.Size.X * 0.94, 0.42, torso.Size.Z * 1.18),
        torso.CFrame * CFrame.new(0, torso.Size.Y * 0.42, 0),
        AMBER,
        Enum.Material.Fabric,
        false
    )
    attach(scarf, torso)

    -- Layered coat: shoulders, lapels, cuffs, waist, and flared tails. The
    -- tails plus the belted waist are what turn a straight blocky torso into a
    -- silhouette that reads feminine without touching the interaction anchor.
    for shoulderSide = -1, 1, 2 do
        local shoulder = part(
            model,
            "CoatShoulder",
            Vector3.new(torso.Size.X * 0.46, torso.Size.Y * 0.3, torso.Size.Z * 1.24),
            torso.CFrame
                * CFrame.new(shoulderSide * torso.Size.X * 0.36, torso.Size.Y * 0.26, 0)
                * CFrame.Angles(0, 0, math.rad(shoulderSide * 7)),
            coatDark,
            Enum.Material.Fabric,
            false
        )
        attach(shoulder, torso)
        local lapel = part(
            model,
            "CoatLapel",
            Vector3.new(torso.Size.X * 0.2, torso.Size.Y * 0.68, torso.Size.Z * 0.22),
            torso.CFrame
                * CFrame.new(
                    shoulderSide * torso.Size.X * 0.17,
                    torso.Size.Y * 0.02,
                    -torso.Size.Z * 0.52
                )
                * CFrame.Angles(0, 0, math.rad(shoulderSide * 9)),
            coatDark,
            Enum.Material.Fabric,
            false
        )
        attach(lapel, torso)
    end

    local belt = part(
        model,
        "CoatBelt",
        Vector3.new(torso.Size.X * 1.05, 0.3, torso.Size.Z * 1.12),
        torso.CFrame * CFrame.new(0, -torso.Size.Y * 0.44, 0),
        Color3.fromRGB(84, 58, 40),
        Enum.Material.Leather,
        false
    )
    attach(belt, torso)
    local buckle = part(
        model,
        "CoatBuckle",
        Vector3.new(0.26, 0.26, 0.12),
        torso.CFrame * CFrame.new(0, -torso.Size.Y * 0.44, -torso.Size.Z * 0.58),
        Color3.fromRGB(168, 137, 92),
        Enum.Material.Metal,
        false
    )
    attach(buckle, torso)

    local lowerTorso = model:FindFirstChild("LowerTorso")
    if lowerTorso ~= nil and lowerTorso:IsA("BasePart") then
        for tailSide = -1, 1, 2 do
            local tail = part(
                model,
                "CoatTail",
                Vector3.new(lowerTorso.Size.X * 0.56, lowerTorso.Size.Y * 1.9, 0.3),
                lowerTorso.CFrame
                    * CFrame.new(
                        tailSide * lowerTorso.Size.X * 0.3,
                        -lowerTorso.Size.Y * 0.72,
                        lowerTorso.Size.Z * 0.5
                    )
                    * CFrame.Angles(math.rad(4), 0, math.rad(tailSide * 5)),
                coat,
                Enum.Material.Fabric,
                false
            )
            attach(tail, lowerTorso)
        end
        local skirt = part(
            model,
            "CoatSkirt",
            Vector3.new(lowerTorso.Size.X * 1.32, lowerTorso.Size.Y * 1.25, lowerTorso.Size.Z * 1.3),
            lowerTorso.CFrame * CFrame.new(0, -lowerTorso.Size.Y * 0.5, 0),
            coat,
            Enum.Material.Fabric,
            false
        )
        attach(skirt, lowerTorso)
    end

    for cuffSide = -1, 1, 2 do
        local lowerArm =
            model:FindFirstChild(if cuffSide < 0 then "LeftLowerArm" else "RightLowerArm")
        if lowerArm ~= nil and lowerArm:IsA("BasePart") then
            local cuff = part(
                model,
                "CoatCuff",
                Vector3.new(lowerArm.Size.X * 1.24, lowerArm.Size.Y * 0.3, lowerArm.Size.Z * 1.24),
                lowerArm.CFrame * CFrame.new(0, -lowerArm.Size.Y * 0.34, 0),
                coatDark,
                Enum.Material.Fabric,
                false
            )
            attach(cuff, lowerArm)
        end
    end

    -- Her role-specific prop: the Greenward field satchel she carries herbs and
    -- cuttings in, slung across the body so it reads from any angle.
    local satchel = part(
        model,
        "FieldSatchel",
        Vector3.new(1.05, 0.86, 0.44),
        torso.CFrame * CFrame.new(torso.Size.X * 0.62, -torso.Size.Y * 0.52, torso.Size.Z * 0.16),
        Color3.fromRGB(108, 76, 48),
        Enum.Material.Leather,
        false
    )
    attach(satchel, torso)
    local satchelFlap = part(
        model,
        "FieldSatchelFlap",
        Vector3.new(1.09, 0.34, 0.5),
        satchel.CFrame * CFrame.new(0, 0.3, 0),
        Color3.fromRGB(84, 58, 40),
        Enum.Material.Leather,
        false
    )
    attach(satchelFlap, satchel)
    local satchelStrap = part(
        model,
        "FieldSatchelStrap",
        Vector3.new(0.22, torso.Size.Y * 1.32, torso.Size.Z * 1.3),
        torso.CFrame * CFrame.new(torso.Size.X * 0.12, 0, 0) * CFrame.Angles(0, 0, math.rad(24)),
        Color3.fromRGB(84, 58, 40),
        Enum.Material.Leather,
        false
    )
    attach(satchelStrap, torso)
    local sprig = part(
        model,
        "SatchelSprig",
        Vector3.new(0.16, 0.5, 0.16),
        satchel.CFrame * CFrame.new(-0.22, 0.52, 0) * CFrame.Angles(0, 0, math.rad(-14)),
        MOSS,
        Enum.Material.Grass,
        false
    )
    attach(sprig, satchel)

    local leftHand = model:WaitForChild("LeftHand") :: BasePart
    local handLanternFallback = Instance.new("Model")
    handLanternFallback.Name = "MaraLanternFallback"
    handLanternFallback.Parent = model
    local handLantern = part(
        handLanternFallback,
        "MaraLantern",
        Vector3.new(0.82, 1.12, 0.82),
        leftHand.CFrame * CFrame.new(0, -0.55, 0),
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
    handLight.Brightness = 1.25
    handLight.Range = 15
    handLight.Shadows = false
    handLight.Parent = handFlame
    CollectionService:AddTag(handFlame, self._runtimeIds.AmbientLightTag)
    table.insert(self._meshPlacements, {
        assetId = "mesh_creator_kerosene_lantern_a",
        fallbackKind = "placeholder",
        position = handLantern.Position,
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

    -- Mara has to look pinned, because the prompt on her reads FREE. The
    -- deadfall used to be placed at y = -0.2 -- lying flat on the ground
    -- alongside her, touching nothing -- and because it was wired as the
    -- fallback's replacement it hid the arching FallenRoot geometry the moment
    -- it loaded, which it does. The result was a rescue objective with visibly
    -- nothing holding her. The trunk now lies across her at waist height,
    -- carried on two broken stumps so it has believable support, and the whole
    -- assembly is one model that freeMara clears when she is released.
    local trap = Instance.new("Model")
    trap.Name = "MaraFallenRoots"
    trap.Parent = world
    for stumpSide = -1, 1, 2 do
        part(
            trap,
            "FallenRootStump",
            Vector3.new(1.9, 2.2, 1.9),
            CFrame.new(-3 + stumpSide * 5.4, 1.1, -30)
                * CFrame.Angles(0, 0, math.rad(stumpSide * 6)),
            WET_BARK,
            Enum.Material.Wood,
            false
        )
    end

    local fallenRootsFallback = Instance.new("Model")
    fallenRootsFallback.Name = "MaraFallenRootsFallback"
    fallenRootsFallback.Parent = trap
    part(
        fallenRootsFallback,
        "FallenRoot",
        Vector3.new(13.6, 1.7, 1.7),
        CFrame.new(-3, 2.55, -30) * CFrame.Angles(0, 0, math.rad(-5)),
        BARK,
        Enum.Material.Wood,
        false
    )
    for limbIndex = -1, 1, 2 do
        part(
            fallenRootsFallback,
            "FallenRootLimb",
            Vector3.new(0.85, 5.4, 0.85),
            CFrame.new(-3 + limbIndex * 2.2, 2.1, -30 + limbIndex * 0.7)
                * CFrame.Angles(math.rad(limbIndex * 26), 0, math.rad(64)),
            BARK,
            Enum.Material.Wood,
            false
        )
    end
    table.insert(self._meshPlacements, {
        assetId = "mesh_deadfall_a",
        fallbackKind = "asset_replacement",
        position = Vector3.new(-3, 1.9, -30),
        scale = 1.15,
        yaw = math.rad(90),
        seed = 9320,
        swayTag = nil,
        parent = trap,
        fallbackInstance = fallenRootsFallback,
        profileScale = Vector3.new(1.18, 0.92, 0.86),
    })
    self._maraTrap = trap

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
        -- Rotated a quarter turn about Z below, so local X is the stump's
        -- HEIGHT and Y/Z are its cross-section: (height, diameter, diameter).
        -- Authored as (7.6, 5.8, 7.6) this came out 7.6 tall with a squashed
        -- 5.8 x 7.6 oval cross-section instead of a 5.8-tall round stump. The
        -- growth rings are the proof: they offset 3.05 along the axis, which
        -- only reaches the cut face when the half-height is 2.9. At 3.8 they
        -- sat buried three quarters of a stud inside the wood.
        Vector3.new(5.8, 7.6, 7.6),
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
    heartLight.Brightness = 1.5
    heartLight.Range = 18
    heartLight.Parent = heart
    addBillboard(heart, "HEARTWOOD", AMBER, 18)
    table.insert(self._meshPlacements, {
        assetId = "mesh_heartwood_stump_a",
        fallbackKind = "asset_replacement",
        position = HEARTWOOD_CENTER,
        scale = 1,
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
    -- Building floors are collidable in this codebase (see WorkshopFloor,
    -- ArchiveFloor, etc) -- only open-world roads rely on Terrain underneath
    -- a non-colliding visual skin. This floor was built with the road
    -- pattern (CanCollide false) despite being a roofed building interior,
    -- so wherever the procedural terrain dips even slightly below y=0 here,
    -- there is nothing solid under it and a player standing on it falls
    -- straight through into whatever is below the valley floor.
    local toolYardGround = part(
        toolYard,
        "ToolYardGround",
        Vector3.new(14, 0.38, 28),
        CFrame.new(TOOL_YARD_CENTER + Vector3.new(0, 0.19, 0)),
        Color3.fromRGB(71, 54, 39),
        Enum.Material.Ground
    )
    toolYardGround.CanQuery = false
    for xSide = -1, 1, 2 do
        for zSide = -1, 1, 2 do
            part(
                toolYard,
                "ToolYardPost",
                Vector3.new(0.7, 14.4, 0.7),
                CFrame.new(TOOL_YARD_CENTER + Vector3.new(xSide * 5.8, 7.2, zSide * 12.4))
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
        CFrame.new(TOOL_YARD_CENTER + Vector3.new(0, 16.4, 0)),
        WET_BARK,
        Enum.Material.Wood,
        false
    )
    -- Open rafters carried high. Two solid slate wedges used to span the
    -- full 28-stud length directly above the three tool displays, and from any
    -- normal over-the-shoulder camera they covered the very thing the player
    -- had walked over to look at. Camera sightline is one of the four
    -- clearances the visual standard requires reserving before detail, and a
    -- roofed interior that hides its own interaction fails that.
    --
    -- Paired rafters carried on the ridge beam keep the frame reading as a
    -- built shelter -- posts, beam, rafters, believable support -- while
    -- leaving open sky between them to see and reach through. The whole frame
    -- also sits well above head height: at the original eaves the beams
    -- themselves crossed the screen at eye level, which is no better than the
    -- roof it replaced.
    for rafterIndex = -4, 4 do
        local rafterZ = rafterIndex * 3.2
        for rafterSide = -1, 1, 2 do
            part(
                toolYard,
                "ToolYardRafter",
                Vector3.new(0.34, 0.34, 7.4),
                CFrame.new(TOOL_YARD_CENTER + Vector3.new(rafterSide * 2.9, 15.5, rafterZ))
                    * CFrame.Angles(0, math.rad(90), math.rad(rafterSide * 26)),
                WET_BARK,
                Enum.Material.Wood,
                false
            )
        end
    end
    for braceSide = -1, 1, 2 do
        part(
            toolYard,
            "ToolYardEaveBeam",
            Vector3.new(0.4, 0.4, 28),
            CFrame.new(TOOL_YARD_CENTER + Vector3.new(braceSide * 5.6, 14.7, 0)),
            WET_BARK,
            Enum.Material.Wood,
            false
        )
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
            assetId = "mesh_creator_hand_axe_a",
            seed = 9895,
        },
        {
            id = self._runtimeIds.InteractionIds.ToolHammer,
            tool = "hammer",
            position = TOOL_YARD_CENTER,
            color = AMBER,
            assetId = "mesh_creator_blacksmith_hammer_a",
            seed = 9896,
        },
        {
            id = self._runtimeIds.InteractionIds.ToolTorch,
            tool = "torch",
            position = TOOL_YARD_CENTER + Vector3.new(0, 0, -8),
            color = Color3.fromRGB(111, 154, 184),
            assetId = "mesh_creator_handheld_torch_a",
            seed = 9897,
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
        -- The tool shape itself (handle + head/flame) is a disposable
        -- fallback -- the reviewed Creator Store axe/hammer/torch mesh
        -- replaces it below. The crate, cushion, bands, and plaque above
        -- stay as the permanent display stand regardless.
        local toolFallback = Instance.new("Model")
        toolFallback.Name = "ToolFallback"
        toolFallback.Parent = display
        local toolAnchor = displayFrame * CFrame.new(0, 5.4, 0)
        part(
            toolFallback,
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
                toolFallback,
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
                toolFallback,
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
                toolFallback,
                "TorchCup",
                -- Cylinder axis is local X: (height, diameter, diameter).
                Vector3.new(0.72, 1.2, 1.2),
                displayFrame * CFrame.new(0, 6.05, 0) * CFrame.Angles(0, 0, math.rad(90)),
                Color3.fromRGB(92, 71, 48),
                Enum.Material.Metal,
                false
            )
            cup.Shape = Enum.PartType.Cylinder
            local flame = part(
                toolFallback,
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
            flameLight.Brightness = 2.0
            flameLight.Range = 18
            flameLight.Parent = flame
            CollectionService:AddTag(flame, self._runtimeIds.AmbientLightTag)
        end
        table.insert(self._meshPlacements, {
            assetId = definition.assetId,
            fallbackKind = "asset_replacement",
            position = (toolAnchor * CFrame.new(0, -0.3, 0)).Position,
            scale = 1,
            yaw = math.rad(90),
            seed = definition.seed,
            swayTag = nil,
            parent = display,
            fallbackInstance = toolFallback,
        })
        -- A dedicated, always-visible anchor for the name label, since the
        -- tool shape it used to hang from gets hidden once the reviewed
        -- mesh replaces it.
        local labelAnchor = part(
            display,
            "ToolLabelAnchor",
            Vector3.new(0.2, 0.2, 0.2),
            toolAnchor,
            definition.color,
            Enum.Material.SmoothPlastic,
            false
        )
        labelAnchor.Transparency = 1
        labelAnchor.CanQuery = false
        addBillboard(labelAnchor, string.upper(definition.tool), definition.color)
        self:_registerInteraction(
            pedestal,
            definition.id,
            self._runtimeIds.Actions.ChooseTool,
            "CHOOSE",
            definition.tool,
            definition.tool
        )
    end
    -- toolDisplayFallback is not scratch geometry for this workbench prop --
    -- it holds the three real, interactive axe/hammer/torch displays players
    -- choose their starting tool from. Wiring it as this placement's
    -- fallbackInstance meant hideProceduralPlaceholder wiped all three
    -- displays the moment the (unrelated) workbench mesh finished loading,
    -- leaving the building with nothing visible to select.
    table.insert(self._meshPlacements, {
        assetId = "mesh_creator_workbench_a",
        fallbackKind = "asset_replacement",
        position = TOOL_YARD_CENTER + Vector3.new(0, 0, -1.5),
        scale = 1,
        yaw = math.rad(90),
        seed = 9890,
        swayTag = nil,
        parent = toolYard,
        fallbackInstance = nil,
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

    local firstLanternFallback = Instance.new("Model")
    firstLanternFallback.Name = "FirstLanternVisualFallback"
    firstLanternFallback.Parent = interactables

    -- The authored lantern carries its own stepped stone plinth, so the
    -- procedural block and steps belong to the fallback rather than standing
    -- permanently under it -- otherwise the town centre grows a second plinth
    -- the moment the mesh loads. They stay collidable while invisible, which
    -- is what keeps players able to walk up onto the dais either way, and
    -- lanternBase remains the interaction anchor exactly as before.
    local lanternBase = part(
        firstLanternFallback,
        "FirstLantern",
        Vector3.new(8, 3, 8),
        CFrame.new(0, 1.5, -112),
        Color3.fromRGB(67, 68, 61),
        Enum.Material.Slate
    )
    for stepIndex = 1, 3 do
        part(
            firstLanternFallback,
            "FirstLanternPlinth",
            Vector3.new(10.5 - stepIndex * 1.45, 0.52, 10.5 - stepIndex * 1.45),
            CFrame.new(0, 0.25 + stepIndex * 0.42, -112),
            if stepIndex % 2 == 0 then Color3.fromRGB(76, 79, 73) else Color3.fromRGB(61, 66, 62),
            Enum.Material.Slate
        )
    end
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

    --[[
        The lantern's fire lives outside the fallback on purpose.

        Everything above belongs to firstLanternFallback, which is exactly what
        hideProceduralPlaceholder blanks once the authored lantern loads: it
        sets Transparency to 1 and disables every Light beneath it. The flame
        used to be part of that, so lighting the First Lantern -- the object the
        entire night defense is built around, whose health this drives -- turned
        it dark instead of lighting it.

        This core sits at the height of the authored lantern's glass and stays
        visible whichever way the placement resolves, so self._lantern always
        points at something that can actually glow.
    ]]
    local lanternCore = part(
        interactables,
        "FirstLanternCore",
        Vector3.new(2.3, 3.1, 2.3),
        CFrame.new(0, 6.3, -112),
        AMBER,
        Enum.Material.Neon,
        false
    )
    lanternCore.Shape = Enum.PartType.Ball
    lanternCore.Transparency = 0.28
    lanternCore.CastShadow = false
    lanternCore.CanQuery = false
    local light = Instance.new("PointLight")
    light.Color = AMBER
    light.Brightness = 1.5
    light.Range = 30
    light.Shadows = true
    light.Parent = lanternCore
    addBillboard(lanternCore, "THE FIRST LANTERN", AMBER, 32)
    CollectionService:AddTag(lanternCore, self._runtimeIds.AmbientLightTag)
    self._lantern = lanternCore
    table.insert(self._meshPlacements, {
        assetId = "mesh_first_lantern_a",
        fallbackKind = "placeholder",
        position = Vector3.new(0, 0, -112),
        scale = 0.95,
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

    -- The gate reads as a threshold you walk through on the way in, not a
    -- cage wrapped around the beacon. Sitting it at the same z as the beacon
    -- (both at -148) put the crossed braces directly around the glowing
    -- reliquary, which read as clutter crowding the memory orb. Pulling it
    -- 28 studs back to the start of the approach (before the path markers
    -- and steps that already lead up to the beacon) keeps the arch as an
    -- entrance and leaves the beacon itself uncluttered.
    local GATE_Z = -120
    -- gateFallback holds only the primitive arch shape -- it is wired as this
    -- placement's fallbackInstance, so hideProceduralPlaceholder makes it
    -- transparent the moment the reviewed arch mesh loads. The steps and path
    -- markers below are unrelated, always-visible approach dressing; the tool
    -- yard hit this same mistake (see the comment above the workbench
    -- placement) when a shared folder doubled as both the real content and a
    -- mesh's fallback, and hideProceduralPlaceholder wiped everything in it
    -- the moment that one mesh loaded.
    local gateFallback = Instance.new("Folder")
    gateFallback.Name = "BramblewakeDawnGateFallback"
    gateFallback.Parent = interactables
    for side = -1, 1, 2 do
        part(
            gateFallback,
            "DawnGateRoot",
            Vector3.new(1.35, 11, 1.35),
            CFrame.new(side * 5.2, 5.5, GATE_Z) * CFrame.Angles(0, 0, math.rad(side * 7)),
            WET_BARK,
            Enum.Material.Wood
        )
        part(
            gateFallback,
            "DawnGateBrace",
            Vector3.new(0.8, 6.2, 0.8),
            CFrame.new(side * 3.7, 10.8, GATE_Z) * CFrame.Angles(0, 0, math.rad(side * 62)),
            BARK,
            Enum.Material.Wood
        )
    end
    part(
        gateFallback,
        "DawnGateLintel",
        Vector3.new(11.5, 1.2, 1.2),
        CFrame.new(0, 11, GATE_Z),
        BARK,
        Enum.Material.WoodPlanks
    )
    local gate = Instance.new("Folder")
    gate.Name = "BramblewakeDawnGate"
    gate.Parent = interactables
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
        position = Vector3.new(0, 0, GATE_Z),
        scale = 1,
        yaw = 0,
        seed = 9910,
        swayTag = nil,
        parent = interactables,
        fallbackInstance = gateFallback,
    })

    local beacon = part(
        interactables,
        "BramblewakeBeacon",
        Vector3.new(3.4, 5.4, 3.4),
        CFrame.new(0, 3.9, -148),
        Color3.fromRGB(104, 187, 166),
        Enum.Material.Glass,
        false
    )
    beacon.Shape = Enum.PartType.Ball
    beacon.Transparency = 1
    beacon.CanQuery = false
    self._beacon = beacon
    -- The gameplay beacon remains an invisible interaction anchor. The visible
    -- object is a thumbnail-reviewed crystal reliquary placed through
    -- MeshTemplateLoader below; this fallback only appears if the reviewed
    -- model cannot load.
    local beaconFallback = Instance.new("Model")
    beaconFallback.Name = "MemoryReliquaryFallback"
    beaconFallback.Parent = interactables
    local beaconCradle = part(
        beaconFallback,
        "BeaconCradleMount",
        Vector3.new(0.34, 3.6, 0.34),
        CFrame.new(0, 10.4, -148),
        Color3.fromRGB(47, 50, 52),
        Enum.Material.Metal,
        false
    )
    beaconCradle.CanQuery = false
    for armIndex = 0, 3 do
        local armAngle = (armIndex / 4) * math.pi * 2
        local arm = part(
            beaconFallback,
            "BeaconCradleArm",
            Vector3.new(0.26, 2.9, 0.26),
            CFrame.new(0, 8.05, -148)
                * CFrame.Angles(0, armAngle, 0)
                * CFrame.new(0, 0, -1.5)
                * CFrame.Angles(math.rad(26), 0, 0),
            Color3.fromRGB(47, 50, 52),
            Enum.Material.Metal,
            false
        )
        arm.CanQuery = false
    end
    local beaconCollar = part(
        beaconFallback,
        "BeaconCradleCollar",
        Vector3.new(0.3, 2.9, 2.9),
        CFrame.new(0, 8.6, -148) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(47, 50, 52),
        Enum.Material.Metal,
        false
    )
    beaconCollar.Shape = Enum.PartType.Cylinder
    beaconCollar.CanQuery = false
    local fallbackLens = part(
        beaconFallback,
        "BeaconFallbackLens",
        Vector3.new(2.2, 2.6, 2.6),
        CFrame.new(0, 6.25, -148) * CFrame.Angles(0, 0, math.rad(90)),
        FOXFIRE,
        Enum.Material.Glass,
        false
    )
    fallbackLens.Shape = Enum.PartType.Cylinder
    fallbackLens.Transparency = 0.22
    fallbackLens.CanQuery = false
    local fallbackFlame = part(
        beaconFallback,
        "BeaconFallbackFlame",
        Vector3.new(0.72, 1.55, 0.64),
        CFrame.new(0, 6.18, -148) * CFrame.Angles(0, math.rad(18), 0),
        FOXFIRE,
        Enum.Material.Neon,
        false
    )
    fallbackFlame.Shape = Enum.PartType.Wedge
    fallbackFlame.CanQuery = false
    table.insert(self._meshPlacements, {
        assetId = "mesh_creator_memory_reliquary_a",
        fallbackKind = "asset_replacement",
        position = Vector3.new(0, 0.25, -148),
        scale = 1,
        yaw = math.pi,
        seed = 9911,
        swayTag = nil,
        parent = interactables,
        fallbackInstance = beaconFallback,
    })
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
        lampLight.Brightness = 1.5
        lampLight.Range = 21
        lampLight.Shadows = false
        lampLight.Parent = lamp
        -- The bay's back wall is at workshopZ - 6.65 and its open front at
        -- workshopZ + 6.65, so a sign behind the back wall faces away from the
        -- players walking in. Stand it beside the entrance, turned to face the
        -- arrival direction like every other labelSign in this file.
        labelSign(
            workshop,
            CFrame.new(centerX - 10.5, 3.2, workshopZ + 8.6) * CFrame.Angles(0, math.pi, 0),
            title
        )
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
        markerLight.Brightness = 1.15
        markerLight.Range = 14
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
        -- A dais, two flat rings and a sign is not a hero location. The
        -- standard forbids shipping an interaction as a plain block, pedestal,
        -- orb, or ring, and this was all four at once. Every anchor below
        -- keeps its name, attributes, and interaction IDs; what follows is
        -- physical construction wrapped around them so a mastery clearing
        -- reads as a built shrine rather than decoration on the floor.
        local shrineBase = CFrame.new(altar.center)
        for postX = -1, 1, 2 do
            for postZ = -1, 1, 2 do
                local post = part(
                    masteryGrove,
                    altar.name .. "MasteryPost",
                    Vector3.new(0.85, 9.2, 0.85),
                    shrineBase
                        * CFrame.new(postX * 6.4, 4.6, postZ * 3.9)
                        * CFrame.Angles(0, 0, math.rad(postX * 1.5)),
                    WET_BARK,
                    Enum.Material.Wood,
                    false
                )
                post.CanQuery = false
                local brace = part(
                    masteryGrove,
                    altar.name .. "MasteryBrace",
                    Vector3.new(0.5, 3.1, 0.5),
                    shrineBase
                        * CFrame.new(postX * 5.6, 7.6, postZ * 3.3)
                        * CFrame.Angles(math.rad(postZ * 34), 0, math.rad(-postX * 30)),
                    BARK,
                    Enum.Material.Wood,
                    false
                )
                brace.CanQuery = false
            end
        end
        for beamZ = -1, 1, 2 do
            local beam = part(
                masteryGrove,
                altar.name .. "MasteryBeam",
                Vector3.new(14.2, 0.7, 0.7),
                shrineBase * CFrame.new(0, 9.05, beamZ * 3.9),
                WET_BARK,
                Enum.Material.Wood,
                false
            )
            beam.CanQuery = false
        end
        for roofSide = -1, 1, 2 do
            local roof = part(
                masteryGrove,
                altar.name .. "MasteryCanopy",
                Vector3.new(15, 0.42, 5.4),
                shrineBase
                    * CFrame.new(0, 10.1, roofSide * 2.05)
                    * CFrame.Angles(math.rad(roofSide * 21), 0, 0),
                Color3.fromRGB(47, 53, 48),
                Enum.Material.Slate,
                false
            )
            roof.CanQuery = false
        end
        local ridge = part(
            masteryGrove,
            altar.name .. "MasteryRidge",
            Vector3.new(15.4, 0.5, 0.5),
            shrineBase * CFrame.new(0, 11.1, 0),
            WET_BARK,
            Enum.Material.Wood,
            false
        )
        ridge.CanQuery = false
        -- Profession colour belongs on cloth, not on a glowing shape.
        local banner = part(
            masteryGrove,
            altar.name .. "MasteryBanner",
            Vector3.new(4.6, 5.4, 0.16),
            shrineBase * CFrame.new(0, 5.6, 3.72) * CFrame.Angles(math.rad(2), 0, 0),
            altar.color,
            Enum.Material.Fabric,
            false
        )
        banner.CanQuery = false
        local bannerRod = part(
            masteryGrove,
            altar.name .. "MasteryBannerRod",
            Vector3.new(5.4, 0.24, 0.24),
            shrineBase * CFrame.new(0, 8.35, 3.72),
            Color3.fromRGB(47, 50, 52),
            Enum.Material.Metal,
            false
        )
        bannerRod.CanQuery = false
        -- Somewhere to actually work, with the craft laid out on it.
        local bench = part(
            masteryGrove,
            altar.name .. "MasteryBench",
            Vector3.new(6.4, 0.42, 1.9),
            shrineBase * CFrame.new(-3.4, 3.05, 2.5),
            Color3.fromRGB(96, 68, 45),
            Enum.Material.WoodPlanks,
            false
        )
        bench.CanQuery = false
        for legX = -1, 1, 2 do
            local benchLeg = part(
                masteryGrove,
                altar.name .. "MasteryBenchLeg",
                Vector3.new(0.34, 2.7, 0.34),
                shrineBase * CFrame.new(-3.4 + legX * 2.7, 1.7, 2.5),
                BARK,
                Enum.Material.Wood,
                false
            )
            benchLeg.CanQuery = false
        end
        for toolIndex = -1, 1 do
            local supply = part(
                masteryGrove,
                altar.name .. "MasterySupply",
                Vector3.new(0.95, 0.85, 0.95),
                shrineBase
                    * CFrame.new(-3.4 + toolIndex * 1.85, 3.68, 2.5)
                    * CFrame.Angles(0, math.rad(toolIndex * 11), 0),
                if toolIndex == 0 then Color3.fromRGB(121, 96, 58) else Color3.fromRGB(89, 63, 42),
                Enum.Material.WoodPlanks,
                false
            )
            supply.CanQuery = false
        end
        -- Restrained practical light, hung from the frame rather than floating.
        -- The tie beam this hangs from is centred at y = 9.05 with a z = +3.9
        -- half-length of 14.2/2 = 7.1, so its underside sits at 8.7 and any x
        -- inside +/-7.1 sits below it. The chain top lands exactly on that
        -- underside and the lantern hangs from the chain's bottom, so nothing
        -- in this stack floats without a physical thing above it holding it up
        -- -- the failure the first version had: its chain sat at z = 2.1, 1.8
        -- studs clear of either beam, with its own top above the beam height,
        -- so the lantern read as an unsupported glowing box.
        local beamUnderside = 9.05 - 0.35
        local chainLength = 1.0
        local hookChain = part(
            masteryGrove,
            altar.name .. "MasteryLanternChain",
            Vector3.new(0.22, chainLength, 0.22),
            shrineBase * CFrame.new(5.7, beamUnderside - chainLength * 0.5, 3.9),
            Color3.fromRGB(58, 62, 66),
            Enum.Material.Metal,
            false
        )
        hookChain.CanQuery = false
        local lanternHeight = 1.05
        local hookLantern = part(
            masteryGrove,
            altar.name .. "MasteryLantern",
            Vector3.new(0.78, lanternHeight, 0.78),
            shrineBase * CFrame.new(5.7, beamUnderside - chainLength - lanternHeight * 0.5, 3.9),
            AMBER,
            Enum.Material.Neon,
            false
        )
        hookLantern.CanQuery = false
        hookLantern.Transparency = 0.18
        local masteryLight = Instance.new("PointLight")
        masteryLight.Color = AMBER
        masteryLight.Brightness = 1.2
        masteryLight.Range = 17
        masteryLight.Shadows = false
        masteryLight.Parent = hookLantern
        CollectionService:AddTag(hookLantern, self._runtimeIds.AmbientLightTag)
        -- A reviewed anvil stands at the working end of each shrine, so the
        -- craft has a recognizable tool rather than only stacked supply boxes.
        table.insert(self._meshPlacements, {
            assetId = "mesh_creator_anvil_a",
            fallbackKind = "asset_dressing",
            position = altar.center + Vector3.new(4.6, 1.08, 2.4),
            scale = 1,
            yaw = math.rad(-24),
            seed = 9980 + #altar.name,
            swayTag = nil,
            parent = masteryGrove,
            fallbackInstance = nil,
        })
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
    world:SetAttribute("WorldVersion", "emberhollow-runtime-visual-v28")
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
    -- The lodge owns spawning now. Leaving this enabled let Roblox choose
    -- between the two, which is why a fresh session could still start on the
    -- arrival road. It stays in the world as the launch destination and as the
    -- anchor the Studio test looks for.
    spawn.Enabled = false
    spawn.Parent = world
    self._spawn = spawn

    self:_buildLobby(world)
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
        worldVersion = "emberhollow-runtime-visual-v28",
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

-- Lift the fallen trunk off Mara. Called once, when she is actually freed, so
-- the rescue has a visible physical consequence instead of only a toast.
function WorldService.freeMara(self: WorldService)
    local trap = self._maraTrap
    if trap == nil then
        return
    end
    self._maraTrap = nil
    trap:Destroy()
end

-- The physical departure platform and where a launched party lands. Owned
-- here because the geometry is authored here; LobbyService reads them rather
-- than duplicating the coordinates.
function WorldService.departurePlatform(self: WorldService): (Vector3, number)
    local platform = self._departurePlatform
    if platform == nil then
        return DEPARTURE_PLATFORM_CENTER, DEPARTURE_PLATFORM_RADIUS
    end
    return platform.Position, DEPARTURE_PLATFORM_RADIUS
end

function WorldService.arrivalSpawnPosition(self: WorldService): Vector3
    local spawn = self._spawn
    if spawn == nil then
        return Vector3.new(0, 4, 0)
    end
    return spawn.Position + Vector3.new(0, 3, 0)
end

function WorldService.moveMara(self: WorldService, destination: Vector3)
    local mara = self._mara
    if mara == nil or mara.PrimaryPart == nil then
        return
    end

    task.spawn(function()
        local start = mara:GetPivot()
        -- Keep her own standing height and only walk her across the ground.
        -- An R15 pivot sits about three studs above the floor, so the callers'
        -- waist-height destination Y (a leftover from the hand-stacked body
        -- this rig replaced, whose pivot sat much lower) buried her to the
        -- chest on arrival. The valley floor is flat at GROUND_Y here, so
        -- carrying her current height across is both correct and immune to the
        -- next caller passing a Y that means something else.
        local target = CFrame.new(destination.X, start.Position.Y, destination.Z)
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
    local becomingVisible = visible and beacon.CanQuery == false
    -- Never reveal the procedural interaction sphere. Progression is conveyed
    -- by the reliquary light and prompt, not a second orb or a floating label.
    beacon.Transparency = 1
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
    local oldLabel = beacon:FindFirstChild("WorldLabel")
    if oldLabel ~= nil then
        oldLabel:Destroy()
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
            CFrame.new(beacon.Position.X, 0.24, beacon.Position.Z)
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

--[[
    Centre of the First Lantern's safe zone, or nil before the world is built.

    Read from the live part rather than a constant so the safe zone cannot
    drift away from the lantern players can actually see if it is ever moved.
]]
function WorldService.lanternSafeCenter(self: WorldService): Vector3?
    local world = self._world
    if world == nil then
        return nil
    end
    local base = world:FindFirstChild("FirstLantern", true)
    if base == nil or not base:IsA("BasePart") then
        return nil
    end
    return base.Position
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
                Brightness = 0.9 + strength * 1.7,
                Color = targetColor,
                Range = 26 + strength * 22,
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
        glow.Brightness = 1.25
        glow.Range = 16
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

    -- Yaw that turns a building's entrance toward `to`. A part's Front face is
    -- -Z, and CFrame.Angles(0, theta, 0) has look vector (-sin, 0, -cos), so
    -- the yaw pointing Front along `delta` is atan2(-dx, -dz).
    local function yawToward(from: Vector3, to: Vector3): number
        local delta = to - from
        if delta.Magnitude < 0.05 then
            return 0
        end
        return math.atan2(-delta.X, -delta.Z)
    end

    local function constructionSite(
        id: string,
        displayName: string,
        center: Vector3,
        size: Vector3,
        facingYaw: number
    )
        -- Authored in the building's own frame so the entrance, sign, and
        -- worksite face the street from whichever lot the building sits on.
        local base = CFrame.new(center) * CFrame.Angles(0, facingYaw, 0)
        local function at(offset: Vector3): CFrame
            return base * CFrame.new(offset)
        end
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
            at(Vector3.new(0, 0.32, 0)),
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
                    at(Vector3.new(sideX * (size.X * 0.45), 3.9, sideZ * (size.Z * 0.42))),
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
                at(Vector3.new(0, 5.7, sideZ * (size.Z * 0.42))),
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
                at(Vector3.new(0, 7.3, tarpSide * size.Z * 0.16))
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
                at(Vector3.new(-size.X * 0.23, 0.55 + lumberIndex * 0.36, size.Z * 0.34))
                    * CFrame.Angles(0, math.rad((lumberIndex % 2) * 2), 0),
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
                at(
                    Vector3.new(
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
            at(Vector3.new(0, 2.45, -size.Z * 0.3)),
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
            at(Vector3.new(0, 2.5, -(size.Z * 0.5 + 0.5))),
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
        accent: Color3,
        facingYaw: number
    ): Model
        if stage == 0 then
            return constructionSite(id, displayName, center, size, facingYaw)
        end
        local model = Instance.new("Model")
        model.Name = id
        model:SetAttribute("BuildingId", id)
        model:SetAttribute("BuildingStage", stage)
        model:SetAttribute("BuildingState", if stage == 3 then "flourishing" else "complete")
        model:SetAttribute("BuildingFacingYaw", facingYaw)
        model.Parent = parent
        local wallHeight = 7.5 + stage * 0.75
        local halfX = size.X * 0.5
        local halfZ = size.Z * 0.5
        -- Same local-frame contract as constructionSite: the door gap in
        -- FrontWall, DoorHeader, BuildingSign, and FrontAwning all sit on -Z
        -- here, and the yaw turns that whole face toward the street.
        local base = CFrame.new(center) * CFrame.Angles(0, facingYaw, 0)
        local function at(offset: Vector3): CFrame
            return base * CFrame.new(offset)
        end
        part(
            model,
            "Floor",
            Vector3.new(size.X, 0.55, size.Z),
            at(Vector3.new(0, 0.28, 0)),
            Color3.fromRGB(83, 61, 42),
            Enum.Material.WoodPlanks
        )
        part(
            model,
            "BackWall",
            Vector3.new(size.X, wallHeight, 0.7),
            at(Vector3.new(0, wallHeight * 0.5, halfZ - 0.35)),
            Color3.fromRGB(69, 48, 36),
            Enum.Material.WoodPlanks
        )
        for side = -1, 1, 2 do
            part(
                model,
                "SideWall",
                Vector3.new(0.7, wallHeight, size.Z),
                at(Vector3.new(side * (halfX - 0.35), wallHeight * 0.5, 0)),
                Color3.fromRGB(69, 48, 36),
                Enum.Material.WoodPlanks
            )
            part(
                model,
                "FrontWall",
                Vector3.new((size.X - 5) * 0.5, wallHeight, 0.7),
                at(Vector3.new(side * (halfX * 0.5 + 1.25), wallHeight * 0.5, -halfZ + 0.35)),
                Color3.fromRGB(69, 48, 36),
                Enum.Material.WoodPlanks
            )
            local window = part(
                model,
                "Window",
                Vector3.new(0.18, 2.4, 2.8),
                at(Vector3.new(side * (halfX - 0.72), 4.5, 1.6)),
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
                    at(Vector3.new(sideX * (halfX - 0.2), wallHeight * 0.5, sideZ * (halfZ - 0.2)))
                        * CFrame.Angles(0, 0, math.rad(sideX * sideZ * 1.5)),
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
            at(Vector3.new(0, wallHeight - 0.55, -halfZ + 0.3)),
            WET_BARK,
            Enum.Material.Wood
        )
        for roofSide = -1, 1, 2 do
            part(
                model,
                "RoofPlane",
                Vector3.new(size.X + 2.2, 0.42, size.Z * 0.62),
                at(Vector3.new(0, wallHeight + 1.25, roofSide * (size.Z * 0.25)))
                    * CFrame.Angles(math.rad(roofSide * 24), 0, 0),
                if stage >= 2 then Color3.fromRGB(48, 55, 49) else Color3.fromRGB(59, 58, 51),
                Enum.Material.Slate
            )
        end
        part(
            model,
            "RoofRidgeBeam",
            Vector3.new(size.X + 2.4, 0.48, 0.48),
            at(Vector3.new(0, wallHeight + 2.65, 0)),
            WET_BARK,
            Enum.Material.Wood,
            false
        )
        local sign = part(
            model,
            "BuildingSign",
            Vector3.new(8.8, 1.7, 0.38),
            at(Vector3.new(0, wallHeight - 1.7, -halfZ - 0.18)),
            WET_BARK,
            Enum.Material.WoodPlanks,
            false
        )
        WorldSignBuilder.dressBoard(sign, displayName, accent, "building")
        local lightAnchor = part(
            model,
            "WarmInterior",
            Vector3.new(0.25, 0.25, 0.25),
            at(Vector3.new(0, 4.5, 1.5)),
            accent,
            Enum.Material.Neon,
            false
        )
        lightAnchor.Transparency = 1
        local light = Instance.new("PointLight")
        light.Color = accent
        light.Brightness = 1.05 + stage * 0.3
        light.Range = 17 + stage * 4
        light.Shadows = false
        light.Parent = lightAnchor
        local interiorCounter = part(
            model,
            "BuildingInteriorCounter",
            Vector3.new(size.X * 0.48, 1.25, 2.4),
            at(Vector3.new(0, 1.25, halfZ - 1.8)),
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
                at(Vector3.new(crateIndex * (halfX * 0.52), 0.95, -0.5)),
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
                at(Vector3.new(0, wallHeight - 2.2, -halfZ - 2)) * CFrame.Angles(math.rad(-8), 0, 0),
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
                    at(Vector3.new(side * (halfX + 0.15), 3, 1.6)),
                    Color3.fromRGB(91, 65, 43),
                    Enum.Material.WoodPlanks,
                    false
                )
                for flower = -1, 1 do
                    local bloom = part(
                        model,
                        "WindowBloom",
                        Vector3.new(0.5, 0.5, 0.5),
                        planter.CFrame * CFrame.new(0, 0.58, flower * 0.85),
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
        FOXFIRE,
        yawToward(Vector3.new(-92, 0, -144), Vector3.new(0, 0, -144))
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
        AMBER,
        yawToward(Vector3.new(92, 0, -126), Vector3.new(0, 0, -126))
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
        Color3.fromRGB(219, 151, 77),
        yawToward(Vector3.new(-92, 0, -184), Vector3.new(0, 0, -184))
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
                -- Cylinder axis is local X: (height, diameter, diameter).
                Vector3.new(1.5, 2.4, 2.4),
                CFrame.new(2.5, -0.8, -0.2) * CFrame.Angles(0, 0, math.rad(90)),
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
        lanternLight.Brightness = 1.4
        lanternLight.Range = 19
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
    keepReplacedAnchorHidden(arena.fireSource)
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
        keepReplacedAnchorHidden(target)
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
        keepReplacedAnchorHidden(target)
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
    keepReplacedAnchorHidden(arena.fireSource)
    keepReplacedAnchorHidden(arena.rootHeart)

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
    keepReplacedAnchorHidden(arena.seal)

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
        keepReplacedAnchorHidden(target)
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
        keepReplacedAnchorHidden(target)
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
                    -- Cylinder axis is local X: (height, diameter, diameter).
                    Vector3.new(0.7, 3.4, 3.4),
                    CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)),
                    Color3.fromRGB(72, 58, 49),
                    Enum.Material.Slate,
                    false
                )
                basin.Shape = Enum.PartType.Cylinder
                local coal = part(
                    model,
                    "CaughtEmbers",
                    -- Cylinder axis is local X: (height, diameter, diameter).
                    Vector3.new(0.35, 2.2, 2.2),
                    CFrame.new(center + Vector3.new(0, 0.48, 0)) * CFrame.Angles(0, 0, math.rad(90)),
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
        Lighting.OutdoorAmbient = Color3.fromRGB(25, 35, 56)
        Lighting.ExposureCompensation = -0.38
        if atmosphere ~= nil and atmosphere:IsA("Atmosphere") then
            atmosphere.Color = Color3.fromRGB(82, 106, 126)
            atmosphere.Decay = Color3.fromRGB(12, 18, 36)
            atmosphere.Density = 0.4
            atmosphere.Haze = 1.75
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
