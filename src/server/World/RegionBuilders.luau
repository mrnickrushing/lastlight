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
            "points of interest",
            "event sockets",
            "resource nodes",
            "elite arenas (Foreman Echo, Iron Widow)",
            "boss chamber (Bellows Maw)",
            "wayfinding and mesh dressing",
        },
    },
    region_mireglass = {
        builder = MireglassBuilder,
        walkable = false,
        missing = {
            "points of interest",
            "event sockets",
            "resource nodes",
            "elite arenas (The Many-Face, Drowned Caller)",
            "boss chamber (Lantern Witch)",
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

return table.freeze(RegionBuilders)
