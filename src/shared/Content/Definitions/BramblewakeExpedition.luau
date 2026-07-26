--!strict

local function frozenDefinition(definition: any): any
    local copy = table.clone(definition)
    if copy.enabled == nil then
        copy.enabled = true
    end
    if string.sub(copy.id, 1, 7) == "module_" and copy.defaultTraversal == nil then
        copy.defaultTraversal = true
    end
    if copy.tags ~= nil then
        copy.tags = table.freeze(table.clone(copy.tags))
    end
    return table.freeze(copy)
end

local modules = {
    frozenDefinition({
        id = "module_bw_lantern_gate",
        displayName = "Lantern Gate",
        role = "arrival",
        visual = "lantern_gate",
        tags = { "safe", "connector", "arrival" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 24,
        lightBudget = 3,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_root_arch",
        displayName = "Root Arch",
        role = "connector",
        visual = "root_arch",
        tags = { "safe", "connector", "traversal" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 28,
        lightBudget = 1,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_bw_sunken_orchard",
        displayName = "Sunken Orchard",
        role = "resource",
        visual = "orchard",
        tags = { "resource", "story", "farm" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 34,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_foxglove_run",
        displayName = "Foxglove Run",
        role = "traversal",
        visual = "foxglove",
        tags = { "traversal", "resource", "foxfire" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 30,
        lightBudget = 4,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_bw_hollow_farm",
        displayName = "Hollow Farm",
        role = "story",
        visual = "farm",
        tags = { "story", "rescue", "farm" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 38,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_bw_briar_ring",
        displayName = "Briar Ring",
        role = "combat",
        visual = "briar_ring",
        tags = { "combat", "arena", "safe_recovery" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 32,
        lightBudget = 1,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_sapfall_gully",
        displayName = "Sapfall Gully",
        role = "resource",
        visual = "sapfall",
        tags = { "resource", "traversal", "amber_sap" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 30,
        lightBudget = 3,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_windmill_copse",
        displayName = "Windmill Copse",
        role = "landmark",
        visual = "windmill",
        tags = { "landmark", "story", "navigation" },
        poiSocket = true,
        eventSocket = false,
        partBudget = 42,
        lightBudget = 1,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_bw_tangle_bridge",
        displayName = "Tangle Bridge",
        role = "traversal",
        visual = "bridge",
        tags = { "traversal", "puzzle", "safe_recovery" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 36,
        lightBudget = 1,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_bw_moth_meadow",
        displayName = "Moth Meadow",
        role = "puzzle",
        visual = "moth_meadow",
        tags = { "puzzle", "safe", "foxfire" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 28,
        lightBudget = 4,
        effectBudget = 4,
    }),
    frozenDefinition({
        id = "module_bw_old_growth_approach",
        displayName = "Old Growth Approach",
        role = "combat",
        visual = "old_growth",
        tags = { "combat", "elite", "landmark", "arena" },
        poiSocket = true,
        eventSocket = false,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_wayhome_gate",
        displayName = "Wayhome Gate",
        role = "extraction",
        visual = "wayhome_gate",
        tags = { "safe", "connector", "extraction" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 26,
        lightBudget = 3,
        effectBudget = 2,
    }),
}

local pointsOfInterest = {
    frozenDefinition({
        id = "poi_bw_reedstead_ruin",
        displayName = "Reedstead Ruin",
        visual = "ruined_homestead",
        tags = { "story", "resident" },
    }),
    frozenDefinition({
        id = "poi_bw_mothwell",
        displayName = "Mothwell",
        visual = "moth_well",
        tags = { "puzzle", "mystery" },
    }),
    frozenDefinition({
        id = "poi_bw_sapglass_grove",
        displayName = "Sapglass Grove",
        visual = "sap_grove",
        tags = { "resource", "risk" },
    }),
    frozenDefinition({
        id = "poi_bw_root_chapel",
        displayName = "Root Chapel",
        visual = "root_chapel",
        tags = { "story", "sanctuary" },
    }),
}

local events = {
    frozenDefinition({
        id = "event_bw_moving_hedge",
        displayName = "Moving Hedge",
        visual = "hedge",
        tags = { "route_change", "traversal" },
    }),
    frozenDefinition({
        id = "event_bw_lost_wagon",
        displayName = "Lost Wagon",
        visual = "wagon",
        tags = { "rescue", "choice" },
    }),
    frozenDefinition({
        id = "event_bw_root_bridge",
        displayName = "Root Bridge",
        visual = "root_bridge",
        tags = { "traversal", "repair" },
    }),
    frozenDefinition({
        id = "event_bw_foxlight_trail",
        displayName = "Foxlight Trail",
        visual = "foxlight",
        tags = { "navigation", "mystery" },
    }),
}

return table.freeze({
    RegionId = "region_bramblewake",
    Version = 1,
    CellSize = 72,
    ModuleCount = 12,
    PointOfInterestCount = 4,
    EventCount = 4,
    PartBudget = 480,
    LightBudget = 32,
    EffectBudget = 32,
    RequiredTags = table.freeze({
        safe = 2,
        traversal = 2,
        resource = 2,
        combat = 2,
        story = 2,
        puzzle = 1,
        landmark = 1,
    }),
    Modules = table.freeze(modules),
    PointsOfInterest = table.freeze(pointsOfInterest),
    Events = table.freeze(events),
})
