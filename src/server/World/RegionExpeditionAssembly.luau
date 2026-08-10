--!strict

--[[
    Stand a non-Bramblewake region up as a walkable expedition.

    Bramblewake's builder does all of this and its own dressing in one
    four-thousand-line pass. The newer regions were built the other way
    around: each owns a module-visual vocabulary (IronrootBuilder,
    MireglassBuilder, ...) and RegionBuilders holds the shared pieces --
    nodes, points of interest, event sockets, arenas, wayfinding. What no
    wave ever wrote was the assembly that composes those pieces into one
    world a server can raise, which is why every region after the first
    sat enabled = false with all of its content reachable by no one.

    This is that assembly. It is deliberately plainer than Bramblewake's
    -- the authored dressing is still an art pass -- but everything a run
    needs is here: continuous ground, the region's own module visuals,
    harvest nodes, labelled points of interest, event sockets with their
    step anchors, the elite and boss arenas with a creature presence in
    each, a wayfinding trail, an arrival sign and an extraction gate.
]]

local CollectionService = game:GetService("CollectionService")

local RegionEncounterWiring =
    require(game:GetService("ReplicatedStorage"):WaitForChild("LastLight").RegionEncounterWiring)
local Strings = require(game:GetService("ReplicatedStorage"):WaitForChild("LastLight").Strings)
local RegionBuilders = require(script.Parent.RegionBuilders)

local RegionExpeditionAssembly = {}

-- The same anchor Bramblewake builds from, so the road out of town and
-- the distant scenery frame whichever wood is standing.
local ORIGIN = Vector3.new(1600, 0, -230)

export type EncounterSite = {
    id: string,
    anchors: { [string]: BasePart },
    anchorMeta: { RegionEncounterWiring.Anchor },
    center: Vector3,
    radius: number,
}

--[[
    What each region's assembly looks like where the shared pieces need a
    colour or a material: the ground its modules stand on, the arena
    palette, and the presence at an arena's middle. Kept small on
    purpose; a region's real identity lives in its module visuals.
]]
local LOOKS: { [string]: any } = {
    region_ironroot = {
        groundColor = Color3.fromRGB(48, 44, 42),
        groundMaterial = Enum.Material.Rock,
        arenaFloor = Color3.fromRGB(54, 50, 48),
        arenaEdge = Color3.fromRGB(66, 58, 50),
        arenaAnchor = Color3.fromRGB(255, 206, 128),
        presenceBody = Color3.fromRGB(38, 34, 32),
        presenceGlow = Color3.fromRGB(255, 168, 66),
    },
    region_mireglass = {
        groundColor = Color3.fromRGB(52, 58, 50),
        groundMaterial = Enum.Material.Mud,
        arenaFloor = Color3.fromRGB(56, 64, 58),
        arenaEdge = Color3.fromRGB(72, 78, 70),
        arenaAnchor = Color3.fromRGB(146, 214, 226),
        presenceBody = Color3.fromRGB(40, 46, 44),
        presenceGlow = Color3.fromRGB(146, 214, 226),
    },
    region_tempest = {
        groundColor = Color3.fromRGB(70, 72, 74),
        groundMaterial = Enum.Material.Slate,
        arenaFloor = Color3.fromRGB(76, 78, 82),
        arenaEdge = Color3.fromRGB(88, 92, 96),
        arenaAnchor = Color3.fromRGB(255, 216, 150),
        presenceBody = Color3.fromRGB(48, 50, 54),
        presenceGlow = Color3.fromRGB(255, 216, 150),
    },
    region_frostmere = {
        groundColor = Color3.fromRGB(196, 204, 210),
        groundMaterial = Enum.Material.Snow,
        arenaFloor = Color3.fromRGB(180, 190, 198),
        arenaEdge = Color3.fromRGB(126, 128, 130),
        arenaAnchor = Color3.fromRGB(238, 128, 54),
        presenceBody = Color3.fromRGB(210, 218, 224),
        presenceGlow = Color3.fromRGB(126, 236, 198),
    },
    region_cinderfall = {
        groundColor = Color3.fromRGB(72, 66, 62),
        groundMaterial = Enum.Material.Basalt,
        arenaFloor = Color3.fromRGB(80, 72, 66),
        arenaEdge = Color3.fromRGB(148, 142, 134),
        arenaAnchor = Color3.fromRGB(255, 148, 62),
        presenceBody = Color3.fromRGB(52, 46, 44),
        presenceGlow = Color3.fromRGB(255, 148, 62),
    },
}

local function ground(parent: Instance, center: Vector3, size: number, look: any): BasePart
    local slab = Instance.new("Part")
    slab.Name = "RegionGround"
    slab.Size = Vector3.new(size, 5, size)
    slab.CFrame = CFrame.new(center + Vector3.new(0, -2.5, 0))
    slab.Color = look.groundColor
    slab.Material = look.groundMaterial
    slab.Anchored = true
    slab.Parent = parent
    return slab
end

local function billboardLabel(
    target: BasePart,
    text: string,
    color: Color3,
    maxDistance: number?,
    height: number?
)
    local gui = Instance.new("BillboardGui")
    gui.Name = "Label"
    gui.Size = UDim2.fromOffset(230, 42)
    gui.StudsOffsetWorldSpace = Vector3.new(0, height or 5.5, 0)
    gui.AlwaysOnTop = false
    gui.MaxDistance = maxDistance or 80
    gui.Parent = target
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.Text = string.upper(text)
    label.TextColor3 = color
    label.TextScaled = true
    label.TextStrokeTransparency = 0.4
    label.Parent = gui
end

--[[
    A creature presence at an arena's middle, so a fight is against
    something a camera can find rather than against empty air. Not an
    authored body -- that is the art pass -- but a deliberate mass: a
    leaning dark bulk at head-and-a-half height with a lit core, the
    same silhouette discipline the enemy roster follows (a threat may
    glow; an objective may not impersonate one).
]]
local function presence(parent: Instance, center: Vector3, look: any, encounterId: string): BasePart
    local model = Instance.new("Model")
    model.Name = "EncounterPresence"
    model:SetAttribute("EncounterId", encounterId)
    model.Parent = parent
    local base = Instance.new("Part")
    base.Name = "PresenceBase"
    base.Size = Vector3.new(6.5, 5.5, 5.5)
    base.CFrame = CFrame.new(center + Vector3.new(0, 2.75, 0)) * CFrame.Angles(0, 0.6, 0.08)
    base.Color = look.presenceBody
    base.Material = Enum.Material.Rock
    base.Anchored = true
    base.Parent = model
    local shoulder = Instance.new("Part")
    shoulder.Name = "PresenceShoulder"
    shoulder.Size = Vector3.new(4.6, 3.4, 4.2)
    shoulder.CFrame = CFrame.new(center + Vector3.new(0.4, 6.6, -0.3))
        * CFrame.Angles(0.14, 1.1, -0.1)
    shoulder.Color = look.presenceBody
    shoulder.Material = Enum.Material.Rock
    shoulder.Anchored = true
    shoulder.Parent = model
    local core = Instance.new("Part")
    core.Name = "PresenceCore"
    core.Shape = Enum.PartType.Ball
    core.Size = Vector3.new(1.6, 1.6, 1.6)
    core.CFrame = CFrame.new(center + Vector3.new(0, 5.4, 1.9))
    core.Color = look.presenceGlow
    core.Material = Enum.Material.Neon
    core.Anchored = true
    core.CanCollide = false
    core.CanQuery = false
    core.CastShadow = false
    core.Parent = model
    local light = Instance.new("PointLight")
    light.Color = look.presenceGlow
    light.Brightness = 1.4
    light.Range = 18
    light.Shadows = false
    light.Parent = core
    return core
end

--[[
    Cut the road through whatever a module visual stood across it.

    The visuals were authored cell by cell, and several stand scenery on
    their cell edges: the Delve's floor walls both X sides in cut rock,
    which is right for a room and wrong for the two rooms the route
    passes between -- the first live walk met a rock canyon with a
    three-stud unlit slot where the trail said the road was. So after
    every module is drawn, anything solid and tall standing near the
    seam between two connected cells is removed. Floors and way markers
    are low; nothing a player walks ON clears the height test.
]]
local function clearRouteCorridor(regionModel: Instance, from: Vector3, to: Vector3)
    local midpoint = (from + to) / 2
    for _, descendant in regionModel:GetDescendants() do
        if
            descendant:IsA("BasePart")
            and descendant.CanCollide
            and descendant.Size.Y > 2.5
            and descendant.Name ~= "RegionGround"
        then
            local offset = descendant.Position - midpoint
            if math.abs(offset.X) < 12 and math.abs(offset.Z) < 12 then
                descendant:Destroy()
            end
        end
    end
end

--[[
    An unoccupied cell beside a host module, for an arena. The route is a
    self-avoiding walk, so at least one of a module's four neighbours is
    always free; claimed arena cells count as occupied so two fights are
    never dealt onto the same ground.
]]
local function freeNeighbor(
    hostCenter: Vector3,
    cellSize: number,
    occupied: { [string]: boolean }
): Vector3
    local steps = {
        Vector3.new(cellSize, 0, 0),
        Vector3.new(0, 0, cellSize),
        Vector3.new(-cellSize, 0, 0),
        Vector3.new(0, 0, -cellSize),
    }
    for _, step in steps do
        local candidate = hostCenter + step
        local key = string.format("%d:%d", candidate.X, candidate.Z)
        if not occupied[key] then
            occupied[key] = true
            return candidate
        end
    end
    -- Unreachable on any valid manifest; a diagonal cell is the honest
    -- fallback rather than stacking two arenas.
    local fallback = hostCenter + Vector3.new(cellSize, 0, cellSize)
    occupied[string.format("%d:%d", fallback.X, fallback.Z)] = true
    return fallback
end

function RegionExpeditionAssembly.build(
    parent: Instance,
    manifest: any,
    generator: any,
    catalog: any,
    runtimeIds: any
): any
    local regionId = manifest.regionId
    local look = assert(LOOKS[regionId], "no assembly look for region " .. tostring(regionId))
    local builder = RegionBuilders.get(regionId)
    assert(builder ~= nil, "no builder for region " .. tostring(regionId))

    for _, name in { "BramblewakeExpedition", "RegionExpedition" } do
        local existing = parent:FindFirstChild(name)
        if existing ~= nil then
            existing:Destroy()
        end
    end

    local expedition = Instance.new("Model")
    expedition.Name = "RegionExpedition"
    expedition:SetAttribute("RegionId", regionId)
    expedition:SetAttribute("ManifestHash", manifest.hash)
    expedition:SetAttribute("Seed", manifest.seed)
    expedition:SetAttribute("Source", manifest.source)
    expedition:SetAttribute("Ready", false)
    expedition.Parent = parent

    local centers: { Vector3 } = {}
    local occupied: { [string]: boolean } = {}
    local cellCenters: { Vector3 } = {}
    for _, placement in manifest.modules do
        local center = ORIGIN
            + Vector3.new(placement.cellX * catalog.CellSize, 0, placement.cellZ * catalog.CellSize)
        centers[placement.index] = center
        occupied[string.format("%d:%d", center.X, center.Z)] = true
        table.insert(cellCenters, center)
    end

    --[[
        Modules first: the region's own visuals, on continuous ground.
        The module visuals float their floors inside the cell (the
        Delve's is 56 studs on a 72-stud cell), so the full-cell slab
        underneath is what keeps the seam between two modules from being
        a 16-stud fall out of the world.
    ]]
    local moduleModels: { Instance } = {}
    local drawn = 0
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
        CollectionService:AddTag(module, runtimeIds.ExpeditionModuleTag)
        ground(module, center, catalog.CellSize, look)
        if builder.buildModuleVisual(module, definition.visual, center) then
            drawn += 1
        end
        moduleModels[placement.index] = module
    end
    assert(drawn == #manifest.modules, regionId .. " placed a module its builder cannot draw")

    -- The trail between modules, in the region's own light.
    local trailLook = RegionBuilders.Wayfinding[regionId]
    if trailLook ~= nil then
        RegionBuilders.buildWayfinding(
            expedition,
            manifest,
            catalog,
            ORIGIN,
            trailLook.marker,
            trailLook.glow
        )
    end

    -- Harvest nodes, from the region's own material list.
    local materials = RegionBuilders.NodeMaterials[regionId]
    assert(materials ~= nil, regionId .. " has no node material list")
    local nodePrefix = string.gsub(regionId, "^region_", "")
    local resourceNodes = RegionBuilders.buildResourceNodes(
        moduleModels,
        manifest,
        catalog,
        ORIGIN,
        materials,
        nodePrefix
    )

    RegionBuilders.buildPointsOfInterest(
        moduleModels,
        manifest,
        generator,
        catalog,
        ORIGIN,
        look.arenaAnchor
    )

    -- Event sockets and their step anchors, flattened into the same
    -- descriptor shape Bramblewake's builder returns, so one registration
    -- path serves both.
    local sockets = RegionBuilders.buildEventSockets(
        moduleModels,
        manifest,
        generator,
        catalog,
        ORIGIN,
        runtimeIds,
        look.presenceGlow
    )
    local eventSockets: { [string]: BasePart } = {}
    local eventInteractions = {}
    for _, socket in sockets do
        eventSockets[socket.eventId] = socket.target
        for _, step in socket.steps do
            table.insert(eventInteractions, {
                target = step.target,
                interactionId = runtimeIds.eventInteractionId(socket.eventId, step.stepId),
                eventId = socket.eventId,
                stepId = step.stepId,
                actionText = step.actionText,
                objectText = step.objectText,
            })
        end
    end

    -- Arrival sign at the first module, so the first thing a party sees
    -- names where they are standing.
    local arrivalCenter = centers[1]
    local arrivalPost = Instance.new("Part")
    arrivalPost.Name = "RegionArrivalSign"
    arrivalPost.Size = Vector3.new(0.8, 6.4, 0.8)
    arrivalPost.CFrame = CFrame.new(arrivalCenter + Vector3.new(0, 3.2, -8))
    arrivalPost.Color = Color3.fromRGB(74, 56, 38)
    arrivalPost.Material = Enum.Material.Wood
    arrivalPost.Anchored = true
    arrivalPost.Parent = expedition
    billboardLabel(arrivalPost, RegionExpeditionAssembly.displayName(regionId), look.arenaAnchor)

    --[[
        The extraction gate, at the module whose role is extraction: a
        lit column a player can see across the wood, ringed so it reads
        as a destination, with the interaction on the column itself.
    ]]
    local extractionTarget: BasePart? = nil
    for _, placement in manifest.modules do
        local definition = generator.moduleDefinition(placement.moduleId)
        if definition.role == "extraction" then
            local center = centers[placement.index]
            local column = Instance.new("Part")
            column.Name = "WayhomeLight"
            column.Size = Vector3.new(3.2, 14, 3.2)
            column.CFrame = CFrame.new(center + Vector3.new(0, 7, 10))
            column.Color = Color3.fromRGB(255, 224, 168)
            column.Material = Enum.Material.Neon
            column.Transparency = 0.35
            column.Anchored = true
            column.CanCollide = false
            column:SetAttribute("ContentId", placement.moduleId)
            column:SetAttribute("ExtractionId", "extraction_" .. nodePrefix .. "_wayhome")
            CollectionService:AddTag(column, runtimeIds.ExpeditionExtractionTag)
            local glowLight = Instance.new("PointLight")
            glowLight.Color = Color3.fromRGB(255, 224, 168)
            glowLight.Brightness = 2
            glowLight.Range = 26
            glowLight.Parent = column
            for postIndex = 0, 5 do
                local angle = postIndex * (math.pi * 2 / 6)
                local marker = Instance.new("Part")
                marker.Name = "WayhomeMarker"
                marker.Size = Vector3.new(1.4, 2.2, 1.4)
                marker.CFrame = CFrame.new(
                    center + Vector3.new(math.cos(angle) * 7, 1.1, 10 + math.sin(angle) * 7)
                )
                marker.Color = look.arenaEdge
                marker.Material = Enum.Material.Slate
                marker.Anchored = true
                marker.Parent = moduleModels[placement.index]
            end
            column.Parent = moduleModels[placement.index]
            extractionTarget = column
        end
    end

    --[[
        Arenas. The elites stand a third and two thirds of the way along
        the walk, the boss beside its end, each in a free cell off the
        route with its own ground -- an arena floating over the void is
        the first thing a walk would have filed. Anchor lists come from
        the encounter wiring, so a fight and its arena cannot disagree
        about what stands in it.
    ]]
    local encounters: { EncounterSite } = {}
    local wiringDefinitions = RegionEncounterWiring.definitionsFor(regionId)
    local moduleCount = #manifest.modules
    local hostIndexFor = {
        math.max(2, math.floor(moduleCount / 3)),
        math.max(3, math.floor(moduleCount * 2 / 3)),
        moduleCount,
    }
    for index, definition in wiringDefinitions do
        local arenaSpec = RegionBuilders.Arenas[definition.id]
        assert(arenaSpec ~= nil, definition.id .. " has no arena spec")
        local hostIndex = hostIndexFor[math.min(index, #hostIndexFor)]
        local hostCenter = centers[hostIndex] or centers[moduleCount]
        local arenaCenter = freeNeighbor(hostCenter, catalog.CellSize, occupied)
        local arenaHolder = Instance.new("Model")
        arenaHolder.Name = arenaSpec.name .. "Site"
        arenaHolder.Parent = expedition
        ground(arenaHolder, arenaCenter, catalog.CellSize, look)
        local anchors = RegionBuilders.buildArena(arenaHolder, arenaCenter, {
            name = arenaSpec.name,
            radius = arenaSpec.radius,
            floorColor = look.arenaFloor,
            edgeColor = look.arenaEdge,
            anchorIds = RegionEncounterWiring.anchorIds(definition),
            anchorColor = look.arenaAnchor,
        })
        presence(arenaHolder, arenaCenter, look, definition.id)
        -- A short lit spur from the host module, or the arena is a room
        -- with no corridor: findable on the map and missable on foot.
        local span = arenaCenter - hostCenter
        for step = 1, 4 do
            local at = hostCenter + span * (step / 5)
            local spur = Instance.new("Part")
            spur.Name = "ArenaSpur"
            spur.Size = Vector3.new(1.6, 0.9, 1.6)
            spur.CFrame = CFrame.new(at + Vector3.new(0, 0.45, 0))
            spur.Color = look.arenaAnchor
            spur.Material = Enum.Material.Neon
            spur.Transparency = 0.5
            spur.Anchored = true
            spur.CanCollide = false
            spur.CanQuery = false
            spur.Parent = arenaHolder
        end
        --[[
            Named at the anchor, not only at the prompt: the first walk
            found four identical glowing pillars, distinguishable only by
            standing at each one. The label reach is short so the arena
            does not join the label soup two cells away -- and shorter
            again when the ring is crowded, because the Titan's eleven
            anchors at the reach the Maw's seven walked fine with read as
            one mashed band from the arena's edge. Past nine anchors,
            only the names near you render.
        ]]
        --[[
            Two heights part a crowded ring and stop parting a dense one.
            The Titan's eleven sit fourteen studs apart and read cleanly
            on alternating heights; the Howler's fifteen sit nine and a
            half studs apart, and the walk found KETTLE LINE, BELL ROPE
            and WIND VANE stacked into one block from the bowl's edge.
            Thirteen anchors or more get a third height and a shorter
            reach, which leaves every ring already walked exactly as it
            was walked.
        ]]
        local crowded = #definition.anchors >= 10
        local dense = #definition.anchors >= 13
        local anchorLabelReach = if dense then 20 elseif crowded then 26 else 40
        for metaIndex, meta in definition.anchors do
            local anchorPart = anchors[meta.id]
            if anchorPart ~= nil then
                local labelHeight = if dense
                    then ({ 5.5, 3.4, 7.4 })[metaIndex % 3 + 1]
                    elseif crowded and metaIndex % 2 == 0 then 3.4
                    else 5.5
                billboardLabel(
                    anchorPart,
                    meta.object,
                    look.arenaAnchor,
                    anchorLabelReach,
                    labelHeight
                )
            end
        end
        clearRouteCorridor(expedition, hostCenter, arenaCenter)
        table.insert(cellCenters, arenaCenter)
        table.insert(encounters, {
            id = definition.id,
            anchors = anchors,
            anchorMeta = definition.anchors,
            center = arenaCenter,
            radius = arenaSpec.radius,
        })
    end

    for index = 1, #manifest.modules - 1 do
        clearRouteCorridor(expedition, centers[index], centers[index + 1])
    end

    --[[
        A rim around every outside edge, so a sightline ends on rock
        rather than on sky. The first dusk in the Delve washed the whole
        region to a pale blank -- the town's atmosphere had nothing to
        read against, because unlike Bramblewake this world had no
        backdrop -- and the same open edges let a player walk off the
        ground slabs into the void. One wall per cell edge that faces no
        other cell answers both.
    ]]
    local rim = Instance.new("Model")
    rim.Name = "RegionRim"
    rim.Parent = expedition
    local edges = {
        { dx = 1, dz = 0 },
        { dx = -1, dz = 0 },
        { dx = 0, dz = 1 },
        { dx = 0, dz = -1 },
    }
    for _, cell in cellCenters do
        for _, edge in edges do
            local neighborKey = string.format(
                "%d:%d",
                cell.X + edge.dx * catalog.CellSize,
                cell.Z + edge.dz * catalog.CellSize
            )
            if not occupied[neighborKey] then
                local wall = Instance.new("Part")
                wall.Name = "RimWall"
                wall.Size = if edge.dx ~= 0
                    then Vector3.new(3, 18, catalog.CellSize + 3)
                    else Vector3.new(catalog.CellSize + 3, 18, 3)
                wall.CFrame = CFrame.new(
                    cell
                        + Vector3.new(
                            edge.dx * (catalog.CellSize / 2),
                            6.5,
                            edge.dz * (catalog.CellSize / 2)
                        )
                )
                wall.Color = Color3.new(
                    look.groundColor.R * 0.55,
                    look.groundColor.G * 0.55,
                    look.groundColor.B * 0.55
                )
                wall.Material = Enum.Material.Rock
                wall.Anchored = true
                wall.CastShadow = false
                wall.Parent = rim
            end
        end
    end

    local generatedParts = 0
    for _, descendant in expedition:GetDescendants() do
        if descendant:IsA("BasePart") then
            generatedParts += 1
        end
    end
    expedition:SetAttribute("GeneratedPartCount", generatedParts)
    expedition:SetAttribute("ModuleCount", #manifest.modules)
    expedition:SetAttribute("EventInteractionCount", #eventInteractions)
    expedition:SetAttribute("ExtractionReady", extractionTarget ~= nil)
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
        extractionTarget = assert(
            extractionTarget,
            regionId .. " walk placed no extraction module"
        ),
        eventInteractions = eventInteractions,
        resourceNodes = resourceNodes,
        eventSockets = eventSockets,
        encounters = encounters,
        moduleCenters = moduleCenters,
        partCount = generatedParts,
    }
end

--[[
    What each region is called where a player reads it. Static calls
    rather than the registry's declared displayNameKey, because those 55
    declared keys resolve to nothing (#360 found the whole convention
    wired to nothing) and a static call is one the localization check can
    hold in both directions.
]]
function RegionExpeditionAssembly.displayName(regionId: string): string
    if regionId == "region_ironroot" then
        return Strings.get("region.ironroot_delve")
    elseif regionId == "region_mireglass" then
        return Strings.get("region.mireglass_fen")
    elseif regionId == "region_tempest" then
        return Strings.get("region.tempest_reach")
    elseif regionId == "region_frostmere" then
        return Strings.get("region.frostmere_vale")
    elseif regionId == "region_cinderfall" then
        return Strings.get("region.cinderfall_crown")
    elseif regionId == "region_hollow" then
        return Strings.get("region.the_hollow")
    end
    return Strings.get("bramblewake.bramblewake_woods")
end

return table.freeze(RegionExpeditionAssembly)
