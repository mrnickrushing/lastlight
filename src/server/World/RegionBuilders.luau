--!strict

--[[
    Which builder draws which region, and what a region still owes before
    it can be walked.

    Bramblewake's builder does everything: module visuals, points of
    interest, event sockets, resource nodes, the elite arena, the boss
    annex, the Blackout layer, mesh dressing, wayfinding. The Delve's and
    the Fen's builders currently do one of those things -- module visuals
    -- and pretending otherwise is how a region ships as an empty grid
    with a name.

    So this registry records both halves: the builder, and the honest
    list of what that region has yet to grow. `readiness` is the answer
    to "could a party walk this today", and nothing but a builder gaining
    the missing pieces should ever change it.
]]

local BramblewakeBuilder = require(script.Parent.BramblewakeBuilder)
local IronrootBuilder = require(script.Parent.IronrootBuilder)
local MireglassBuilder = require(script.Parent.MireglassBuilder)

local RegionBuilders = {}

export type Readiness = {
    regionId: string,
    walkable: boolean,
    -- What the region still owes, in the order it will be built.
    missing: { string },
}

local ENTRIES: { [string]: any } = {
    region_bramblewake = {
        builder = BramblewakeBuilder,
        walkable = true,
        missing = {},
    },
    region_ironroot = {
        builder = IronrootBuilder,
        walkable = false,
        missing = {
            "wayfinding and mesh dressing",
        },
    },
    region_mireglass = {
        builder = MireglassBuilder,
        walkable = false,
        missing = {
            "wayfinding and mesh dressing",
        },
    },
}

function RegionBuilders.get(regionId: any): any
    return if type(regionId) == "string" then (ENTRIES[regionId] or {}).builder else nil
end

function RegionBuilders.readiness(regionId: any): Readiness
    local entry = if type(regionId) == "string" then ENTRIES[regionId] else nil
    if entry == nil then
        return { regionId = tostring(regionId), walkable = false, missing = { "unknown region" } }
    end
    return {
        regionId = regionId :: string,
        walkable = entry.walkable == true,
        missing = table.clone(entry.missing),
    }
end

function RegionBuilders.ids(): { string }
    local ids: { string } = {}
    for regionId in ENTRIES do
        table.insert(ids, regionId)
    end
    table.sort(ids)
    return ids
end

--[[
    Draw one region's modules from a manifest.

    This is the shared half of expedition assembly: a model per placement,
    the attributes the world and its tests read, the streaming cell, and
    the region's own visual for the module. It is deliberately not the
    whole of Bramblewake's builder -- that one also plants POIs, events,
    nodes and arenas, and each of those is its own wave for a new region.

    Returns the module models it made, so a caller can keep building on
    top of them, and the count of visuals the region's builder actually
    knew how to draw.
]]
function RegionBuilders.buildModules(
    parent: Instance,
    manifest: any,
    generator: any,
    catalog: any,
    origin: Vector3
): (number, number)
    local builder = RegionBuilders.get(manifest.regionId)
    assert(builder ~= nil, "no builder for region " .. tostring(manifest.regionId))
    assert(
        type(builder.buildModuleVisual) == "function",
        tostring(manifest.regionId) .. " has no module visual builder"
    )

    local drawn = 0
    for _, placement in manifest.modules do
        local definition = generator.moduleDefinition(placement.moduleId)
        local center = origin
            + Vector3.new(placement.cellX * catalog.CellSize, 0, placement.cellZ * catalog.CellSize)
        local module = Instance.new("Model")
        module.Name = string.format("Module_%02d", placement.index)
        module:SetAttribute("ContentId", placement.moduleId)
        module:SetAttribute("DisplayName", definition.displayName)
        module:SetAttribute("SequenceIndex", placement.index)
        module:SetAttribute("CellX", placement.cellX)
        module:SetAttribute("CellZ", placement.cellZ)
        module.Parent = parent
        if builder.buildModuleVisual(module, definition.visual, center) then
            drawn += 1
        end
    end
    return #manifest.modules, drawn
end

--[[
    Resource nodes for a region that has none yet.

    Bramblewake grows its own inside its builder, tangled with mesh
    dressing and ambient light tags. A new region needs the same contract
    -- an anchor part, an interaction id, the material it pays, the words
    the prompt says -- without inheriting the forest's dressing, so this
    plants them from the region's own material list and hands the
    descriptors back for the caller to register as prompts.

    Two per module from the second module on, which is the cadence
    Bramblewake settled on: the arrival module stays clean so a party's
    first look at a region is the region and not a shopping list.
]]
function RegionBuilders.buildResourceNodes(
    modules: { Instance },
    manifest: any,
    catalog: any,
    origin: Vector3,
    materials: { { id: string, label: string, color: Color3 } },
    prefix: string
): { any }
    local descriptors = {}
    for index, placement in manifest.modules do
        if index >= 2 and modules[index] ~= nil then
            local center = origin
                + Vector3.new(
                    placement.cellX * catalog.CellSize,
                    0,
                    placement.cellZ * catalog.CellSize
                )
            for slot = 1, 2 do
                local material = materials[((index + slot) % #materials) + 1]
                local side = if slot == 1 then -1 else 1
                local at = center + Vector3.new(side * (15 + (index % 3) * 2), 0, (slot - 1.5) * 18)
                local anchor = Instance.new("Part")
                anchor.Name = material.label .. "Node"
                anchor.Size = Vector3.new(5, 7, 5)
                anchor.CFrame = CFrame.new(at + Vector3.new(0, 3.5, 0))
                anchor.Anchored = true
                anchor.CanCollide = false
                anchor.CanTouch = false
                anchor.Transparency = 1
                anchor.Parent = modules[index]

                -- Small and quiet, for the reason Bramblewake learned the
                -- hard way: a resource cue should be findable when looked
                -- for, never the loudest thing on the screen.
                local cue = Instance.new("Part")
                cue.Name = "ResourceGlow"
                cue.Shape = Enum.PartType.Ball
                cue.Size = Vector3.new(0.7, 0.7, 0.7)
                cue.CFrame = CFrame.new(at + Vector3.new(0, 3.2, 0))
                cue.Color = material.color
                cue.Material = Enum.Material.Neon
                cue.Anchored = true
                cue.CanCollide = false
                cue.CanQuery = false
                cue.CastShadow = false
                cue.Transparency = 0.8
                cue.Parent = modules[index]

                table.insert(descriptors, {
                    target = anchor,
                    interactionId = string.format("node_%s_%d_%d", prefix, index, slot),
                    materialId = material.id,
                    objectText = material.label,
                })
            end
        end
    end
    return descriptors
end

--[[
    The materials each region pays out of its own ground, in the order
    its nodes cycle them. Kept beside the builders because it is a fact
    about the region's world, not about its economy: what a node is made
    of is what the player sees before they harvest it.
]]
RegionBuilders.NodeMaterials = table.freeze({
    region_ironroot = table.freeze({
        table.freeze({
            id = "material_ironroot_ore",
            label = "Ironroot Ore",
            color = Color3.fromRGB(196, 142, 58),
        }),
        table.freeze({
            id = "material_coalglass",
            label = "Coalglass",
            color = Color3.fromRGB(255, 168, 66),
        }),
        table.freeze({
            id = "material_glow_fungus",
            label = "Glow Fungus",
            color = Color3.fromRGB(150, 226, 176),
        }),
    }),
    region_mireglass = table.freeze({
        table.freeze({
            id = "material_mirror_reed",
            label = "Mirror Reed",
            color = Color3.fromRGB(186, 206, 210),
        }),
        table.freeze({
            id = "material_bog_iron",
            label = "Bog Iron",
            color = Color3.fromRGB(146, 118, 92),
        }),
        table.freeze({
            id = "material_witchlight_pollen",
            label = "Witchlight Pollen",
            color = Color3.fromRGB(146, 214, 226),
        }),
    }),
})

local CollectionService = game:GetService("CollectionService")

--[[
    Points of interest and event sockets for a region that has neither.

    Both are anchors with words on them: a POI says what a place is, an
    event socket says what is about to be asked of you and how far along
    it is. Bramblewake dresses them heavily -- cairns, icons, billboards
    tuned over several waves. A new region gets the anchor, the
    attributes, and the tag, which is everything the runtime and the
    tests read; its own dressing is an art pass, not a wiring one, and
    saying so is better than faking it.
]]
local function labelled(parent: Instance, text: string, color: Color3)
    local gui = Instance.new("BillboardGui")
    gui.Name = "Label"
    gui.Size = UDim2.fromOffset(220, 40)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
    gui.AlwaysOnTop = false
    gui.MaxDistance = 140
    gui.Parent = parent
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

function RegionBuilders.buildPointsOfInterest(
    modules: { Instance },
    manifest: any,
    generator: any,
    catalog: any,
    origin: Vector3,
    color: Color3
): number
    local placed = 0
    for index, placement in manifest.modules do
        if placement.poiId ~= nil and modules[index] ~= nil then
            local definition = generator.pointOfInterestDefinition(placement.poiId)
            local center = origin
                + Vector3.new(
                    placement.cellX * catalog.CellSize,
                    0,
                    placement.cellZ * catalog.CellSize
                )
            local anchor = Instance.new("Part")
            anchor.Name = "PointOfInterest"
            anchor.Size = Vector3.new(8, 1, 8)
            anchor.CFrame = CFrame.new(center + Vector3.new(-21, 0.5, 18))
            anchor.Anchored = true
            anchor.CanCollide = false
            anchor.CanTouch = false
            anchor.Transparency = 1
            anchor.CastShadow = false
            anchor:SetAttribute("ContentId", definition.id)
            anchor:SetAttribute("DisplayName", definition.displayName)
            anchor:SetAttribute("Detail", definition.detail)
            anchor.Parent = modules[index]
            labelled(anchor, definition.displayName, color)
            placed += 1
        end
    end
    return placed
end

function RegionBuilders.buildEventSockets(
    modules: { Instance },
    manifest: any,
    generator: any,
    catalog: any,
    origin: Vector3,
    runtimeIds: any,
    color: Color3
): { any }
    local sockets = {}
    for index, placement in manifest.modules do
        if placement.eventId ~= nil and modules[index] ~= nil then
            local definition = generator.eventDefinition(placement.eventId)
            local center = origin
                + Vector3.new(
                    placement.cellX * catalog.CellSize,
                    0,
                    placement.cellZ * catalog.CellSize
                )
            local anchor = Instance.new("Part")
            anchor.Name = "EventSocket"
            anchor.Size = Vector3.new(7, 1, 7)
            anchor.CFrame = CFrame.new(center + Vector3.new(22, 0.5, -19))
            anchor.Anchored = true
            anchor.CanCollide = false
            anchor.CanTouch = false
            anchor.Transparency = 1
            anchor.CastShadow = false
            anchor:SetAttribute("ContentId", definition.id)
            anchor:SetAttribute("DisplayName", definition.displayName)
            anchor:SetAttribute("Dormant", true)
            anchor:SetAttribute("Status", "dormant")
            anchor:SetAttribute("Progress", 0)
            anchor:SetAttribute("ProgressTotal", #definition.steps)
            anchor.Parent = modules[index]
            CollectionService:AddTag(anchor, runtimeIds.ExpeditionEventTag)
            labelled(anchor, definition.displayName, color)

            --[[
                One anchor per step, at the offsets the event's own
                definition names. The steps are the event: "turn the three
                latches" is three places a player has to stand, and an
                event whose steps have nowhere to happen is a prompt that
                never appears.
            ]]
            local steps = {}
            for _, step in definition.steps do
                local offset = step.offset or { x = 0, y = 1, z = 0 }
                local stepAnchor = Instance.new("Part")
                stepAnchor.Name = "EventStep"
                stepAnchor.Size = Vector3.new(3, 4, 3)
                stepAnchor.CFrame = CFrame.new(
                    anchor.Position
                        + Vector3.new(
                            tonumber(offset.x) or 0,
                            tonumber(offset.y) or 1,
                            tonumber(offset.z) or 0
                        )
                )
                stepAnchor.Anchored = true
                stepAnchor.CanCollide = false
                stepAnchor.CanTouch = false
                stepAnchor.Transparency = 1
                stepAnchor:SetAttribute("StepId", step.id)
                stepAnchor.Parent = anchor
                table.insert(steps, {
                    target = stepAnchor,
                    stepId = step.id,
                    actionText = step.actionText,
                    objectText = step.objectText,
                })
            end

            table.insert(sockets, {
                target = anchor,
                eventId = definition.id,
                steps = steps,
            })
        end
    end
    return sockets
end

--[[
    An arena for an elite or a boss.

    Every encounter this project has shipped needs the same four things
    from the world: a floor a fight can happen on, a place the creature
    stands, a set of anchors for whatever the fight asks the player to
    interact with (root nodes, levers, mirrors, pools, vent wheels), and
    an edge so the arena reads as a room rather than a clearing.

    The encounter modules already name their own interaction ids --
    ForemanEcho.LeverIds, IronWidow.AnchorIds, BellowsMaw.LineIds and so
    on -- so the arena takes that list rather than inventing its own. If
    an encounter grows a fifth lever, its arena grows a fifth anchor with
    no change here, which is the only way these two stay in agreement.
]]
function RegionBuilders.buildArena(
    parent: Instance,
    center: Vector3,
    options: {
        name: string,
        radius: number,
        floorColor: Color3,
        edgeColor: Color3,
        anchorIds: { string },
        anchorColor: Color3,
    }
): { [string]: BasePart }
    local arena = Instance.new("Model")
    arena.Name = options.name
    arena.Parent = parent

    local floor = Instance.new("Part")
    floor.Name = "ArenaFloor"
    floor.Shape = Enum.PartType.Cylinder
    -- A cylinder's axis is its Size.X, so the disc lies flat only when
    -- the thickness is on X and the rotation stands it up.
    floor.Size = Vector3.new(1.2, options.radius * 2, options.radius * 2)
    floor.CFrame = CFrame.new(center + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
    floor.Color = options.floorColor
    floor.Material = Enum.Material.Slate
    floor.Anchored = true
    floor.CanCollide = false
    floor.CanQuery = false
    floor.Parent = arena

    local edges = 12
    for index = 0, edges - 1 do
        local angle = index * (math.pi * 2 / edges)
        local post = Instance.new("Part")
        post.Name = "ArenaEdge"
        post.Size = Vector3.new(2.2, 5.5, 2.2)
        post.CFrame = CFrame.new(
            center
                + Vector3.new(
                    math.cos(angle) * options.radius,
                    2.7,
                    math.sin(angle) * options.radius
                )
        ) * CFrame.Angles(0, angle, math.rad((index % 3) - 1))
        post.Color = options.edgeColor
        post.Material = Enum.Material.Rock
        post.Anchored = true
        post.Parent = arena
    end

    --[[
        One anchor per interaction the encounter names, evenly spaced
        inside the ring so no two are ever in the same place and every one
        is reachable from the middle.
    ]]
    local anchors: { [string]: BasePart } = {}
    local count = #options.anchorIds
    for index, anchorId in options.anchorIds do
        local angle = (index - 1) * (math.pi * 2 / math.max(1, count))
        local anchor = Instance.new("Part")
        anchor.Name = "ArenaAnchor"
        anchor.Size = Vector3.new(3.4, 5, 3.4)
        anchor.CFrame = CFrame.new(
            center
                + Vector3.new(
                    math.cos(angle) * (options.radius * 0.62),
                    2.5,
                    math.sin(angle) * (options.radius * 0.62)
                )
        )
        anchor.Color = options.anchorColor
        anchor.Material = Enum.Material.Neon
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.Transparency = 0.35
        anchor:SetAttribute("AnchorId", anchorId)
        anchor.Parent = arena
        anchors[anchorId] = anchor
    end
    return anchors
end

--[[
    The arena each new encounter needs, named next to the encounter that
    needs it so the two are read together. Radii come from the fights:
    the Widow's web has to be walked between cuts, so hers is widest; the
    Echo's three levers want a room rather than a field.
]]
RegionBuilders.Arenas = table.freeze({
    elite_foreman_echo = table.freeze({
        name = "ForemanEchoArena",
        regionId = "region_ironroot",
        radius = 26,
    }),
    elite_iron_widow = table.freeze({
        name = "IronWidowArena",
        regionId = "region_ironroot",
        radius = 34,
    }),
    boss_bellows_maw = table.freeze({
        name = "BellowsMawChamber",
        regionId = "region_ironroot",
        radius = 38,
    }),
    elite_many_face = table.freeze({
        name = "ManyFaceCourt",
        regionId = "region_mireglass",
        radius = 28,
    }),
    elite_drowned_caller = table.freeze({
        name = "DrownedCallerMarsh",
        regionId = "region_mireglass",
        radius = 32,
    }),
    boss_lantern_witch = table.freeze({
        name = "LanternWitchRing",
        regionId = "region_mireglass",
        radius = 36,
    }),
})

return table.freeze(RegionBuilders)
