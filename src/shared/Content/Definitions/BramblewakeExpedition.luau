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
    for _, key in { "startConditions", "incompatibleEvents" } do
        if copy[key] ~= nil then
            copy[key] = table.freeze(table.clone(copy[key]))
        end
    end
    if copy.reward ~= nil then
        copy.reward = table.freeze(table.clone(copy.reward))
    end
    if copy.soloVariant ~= nil then
        copy.soloVariant = table.freeze(table.clone(copy.soloVariant))
    end
    if copy.storyOffset ~= nil then
        copy.storyOffset = table.freeze(table.clone(copy.storyOffset))
    end
    if copy.groupVariant ~= nil then
        copy.groupVariant = table.freeze(table.clone(copy.groupVariant))
    end
    if copy.steps ~= nil then
        local steps: { any } = {}
        for _, step in copy.steps do
            local stepCopy: any = table.clone(step :: any)
            if stepCopy.offset ~= nil then
                stepCopy.offset = table.freeze(table.clone(stepCopy.offset))
            end
            table.insert(steps, table.freeze(stepCopy))
        end
        copy.steps = table.freeze(steps)
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
        storyLandmark = "last_harvest",
        storyTitle = "THE LAST HARVEST",
        storyOffset = { x = 0, z = 22 },
        storyPartCount = 10,
        tags = { "resource", "story", "farm" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
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
        storyLandmark = "evacuation_cart",
        storyTitle = "THE ROAD THEY LEFT",
        storyOffset = { x = 0, z = 22 },
        storyPartCount = 11,
        tags = { "story", "rescue", "farm" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 49,
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
        storyLandmark = "last_repair",
        storyTitle = "THE LAST REPAIR",
        storyOffset = { x = 3, z = 22 },
        storyPartCount = 7,
        tags = { "landmark", "story", "navigation" },
        poiSocket = true,
        eventSocket = false,
        partBudget = 49,
        lightBudget = 1,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_bw_tangle_bridge",
        displayName = "Tangle Bridge",
        role = "traversal",
        visual = "bridge",
        storyLandmark = "lost_crossing",
        storyTitle = "THE LOST CROSSING",
        storyOffset = { x = -18, z = 19 },
        storyPartCount = 7,
        tags = { "traversal", "puzzle", "safe_recovery" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 43,
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
        eliteId = "elite_old_growth",
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
        objective = "TURN THE THREE ROOT LATCHES",
        detail = "The hedge changes its side paths unless every amber latch is turned.",
        completionMessage = "THE HEDGE SETTLES — +4 HEARTWOOD",
        failureMessage = "THE HEDGE SLIPS AWAY",
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The side cache closes; the marked critical path remains open.",
        localizationKey = "events.bramblewake.moving_hedge",
        analyticsId = "BramblewakeMovingHedge",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = {
            guidance = "Turn each latch before the roots move again.",
        },
        groupVariant = {
            guidance = "Split up and turn separate latches.",
        },
        reward = {
            materialId = "material_heartwood",
            amount = 4,
        },
        steps = {
            {
                id = "latch_west",
                actionText = "TURN",
                objectText = "West Root Latch",
                offset = { x = -7, y = 1.5, z = 0 },
            },
            {
                id = "latch_center",
                actionText = "TURN",
                objectText = "Center Root Latch",
                offset = { x = 0, y = 1.5, z = 0 },
            },
            {
                id = "latch_east",
                actionText = "TURN",
                objectText = "East Root Latch",
                offset = { x = 7, y = 1.5, z = 0 },
            },
        },
    }),
    frozenDefinition({
        id = "event_bw_lost_wagon",
        displayName = "Lost Wagon",
        visual = "wagon",
        tags = { "rescue", "choice" },
        objective = "STABILIZE THE LOST WAGON",
        detail = "Brace the axle, lift the tongue, and secure the seed crate.",
        completionMessage = "THE WAGON IS SAFE — +3 MEADOW FIBER",
        failureMessage = "THE WAGON SINKS INTO THE FERNS",
        durationSeconds = 120,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The wagon reward is lost; no resident or critical route is removed.",
        localizationKey = "events.bramblewake.lost_wagon",
        analyticsId = "BramblewakeLostWagon",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = {
            guidance = "Complete the three braces in any order.",
        },
        groupVariant = {
            guidance = "Several travelers can stabilize the wagon together.",
        },
        reward = {
            materialId = "material_meadow_fiber",
            amount = 3,
        },
        steps = {
            {
                id = "brace_axle",
                actionText = "BRACE",
                objectText = "Broken Axle",
                offset = { x = -5, y = 1, z = 3 },
            },
            {
                id = "lift_tongue",
                actionText = "LIFT",
                objectText = "Wagon Tongue",
                offset = { x = 6, y = 1, z = 1 },
            },
            {
                id = "secure_crate",
                actionText = "SECURE",
                objectText = "Seed Crate",
                offset = { x = 0, y = 3.5, z = -3 },
            },
        },
    }),
    frozenDefinition({
        id = "event_bw_root_bridge",
        displayName = "Root Bridge",
        visual = "root_bridge",
        tags = { "traversal", "repair" },
        objective = "BIND THE THREE BRIDGE ROOTS",
        detail = "Tighten the living knots to open a safe optional crossing.",
        completionMessage = "THE ROOT BRIDGE HOLDS — +2 AMBER SAP",
        failureMessage = "THE OPTIONAL CROSSING UNRAVELS",
        durationSeconds = 105,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The shortcut closes; the default amber trail remains traversable.",
        localizationKey = "events.bramblewake.root_bridge",
        analyticsId = "BramblewakeRootBridge",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = {
            guidance = "Bind each knot from stable ground.",
        },
        groupVariant = {
            guidance = "Travelers may bind different knots at the same time.",
        },
        reward = {
            materialId = "material_amber_sap",
            amount = 2,
        },
        steps = {
            {
                id = "bind_left",
                actionText = "BIND",
                objectText = "Left Root Knot",
                offset = { x = -6, y = 2, z = 2 },
            },
            {
                id = "bind_center",
                actionText = "BIND",
                objectText = "Center Root Knot",
                offset = { x = 0, y = 3, z = 0 },
            },
            {
                id = "bind_right",
                actionText = "BIND",
                objectText = "Right Root Knot",
                offset = { x = 6, y = 2, z = 2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_bw_foxlight_trail",
        displayName = "Foxlight Trail",
        visual = "foxlight",
        tags = { "navigation", "mystery" },
        objective = "WAKE THE FOUR FOXLIGHTS",
        detail = "Attune every quiet light to reveal a hidden grove memory.",
        completionMessage = "THE FOXLIGHTS ANSWER — +2 BRIGHTCAP",
        failureMessage = "THE FOXLIGHTS RETURN TO SLEEP",
        durationSeconds = 100,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 14,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The hidden memory remains undiscovered; extraction stays reachable.",
        localizationKey = "events.bramblewake.foxlight_trail",
        analyticsId = "BramblewakeFoxlightTrail",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = {
            guidance = "Follow the lights around the clearing.",
        },
        groupVariant = {
            guidance = "Wake separate lights to reveal the memory sooner.",
        },
        reward = {
            materialId = "material_brightcap",
            amount = 2,
        },
        steps = {
            {
                id = "wake_north",
                actionText = "ATTUNE",
                objectText = "North Foxlight",
                offset = { x = 0, y = 3, z = -6 },
            },
            {
                id = "wake_east",
                actionText = "ATTUNE",
                objectText = "East Foxlight",
                offset = { x = 6, y = 4, z = 0 },
            },
            {
                id = "wake_south",
                actionText = "ATTUNE",
                objectText = "South Foxlight",
                offset = { x = 0, y = 5, z = 6 },
            },
            {
                id = "wake_west",
                actionText = "ATTUNE",
                objectText = "West Foxlight",
                offset = { x = -6, y = 4, z = 0 },
            },
        },
    }),
    frozenDefinition({
        id = "event_bw_pollen_storm",
        displayName = "Pollen Storm",
        visual = "pollen_storm",
        tags = { "weather", "shelter" },
        objective = "RAISE THE THREE POLLEN SCREENS",
        detail = "Turn each woven screen into the storm before the clearing fills.",
        completionMessage = "THE CLEARING CAN BREATHE — +3 BRIGHTCAP",
        failureMessage = "THE POLLEN CLAIMS THE SIDE CLEARING",
        durationSeconds = 95,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The side clearing closes until the storm passes; the amber route stays open.",
        localizationKey = "events.bramblewake.pollen_storm",
        analyticsId = "BramblewakePollenStorm",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = { guidance = "Raise each screen from the sheltered side." },
        groupVariant = { guidance = "Travelers can raise separate screens together." },
        reward = { materialId = "material_brightcap", amount = 3 },
        steps = {
            {
                id = "screen_west",
                actionText = "RAISE",
                objectText = "West Pollen Screen",
                offset = { x = -7, y = 2.5, z = 0 },
            },
            {
                id = "screen_center",
                actionText = "RAISE",
                objectText = "Center Pollen Screen",
                offset = { x = 0, y = 2.5, z = 0 },
            },
            {
                id = "screen_east",
                actionText = "RAISE",
                objectText = "East Pollen Screen",
                offset = { x = 7, y = 2.5, z = 0 },
            },
        },
    }),
    frozenDefinition({
        id = "event_bw_hungry_homestead",
        displayName = "Hungry Homestead",
        visual = "hungry_homestead",
        tags = { "resident", "supply" },
        objective = "RESTOCK THE THREE HOMESTEAD STORES",
        detail = "Set seed, water, and preserved roots beneath the dry porch.",
        completionMessage = "THE HOMESTEAD ENDURES — +3 SPRING CLAY",
        failureMessage = "THE HOMESTEAD BOLTS ITS DOORS",
        durationSeconds = 115,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The family shelters without a reward; no resident or route is removed.",
        localizationKey = "events.bramblewake.hungry_homestead",
        analyticsId = "BramblewakeHungryHomestead",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = { guidance = "Stock each porch store in any order." },
        groupVariant = { guidance = "Split the supplies across the porch stores." },
        reward = { materialId = "material_spring_clay", amount = 3 },
        steps = {
            {
                id = "stock_seed",
                actionText = "STOCK",
                objectText = "Seed Bin",
                offset = { x = -6, y = 1.4, z = 1 },
            },
            {
                id = "fill_water",
                actionText = "FILL",
                objectText = "Water Cask",
                offset = { x = 0, y = 1.7, z = -2 },
            },
            {
                id = "store_roots",
                actionText = "STORE",
                objectText = "Root Cellar",
                offset = { x = 6, y = 1.4, z = 1 },
            },
        },
    }),
    frozenDefinition({
        id = "event_bw_stag_tracks",
        displayName = "Stag Tracks",
        visual = "stag_tracks",
        tags = { "tracking", "mystery" },
        objective = "READ THE THREE WARDEN TRACKS",
        detail = "Study the hoofprint, antler scrape, and sleeping hollow without disturbing them.",
        completionMessage = "THE WARDEN'S PATH IS KNOWN — +2 AMBER SAP",
        failureMessage = "RAIN ERASES THE WARDEN'S TRAIL",
        durationSeconds = 100,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The optional trail memory is lost; Old Growth remains reachable.",
        localizationKey = "events.bramblewake.stag_tracks",
        analyticsId = "BramblewakeStagTracks",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = { guidance = "Read each sign before the rain deepens." },
        groupVariant = { guidance = "Search separate edges of the clearing." },
        reward = { materialId = "material_amber_sap", amount = 2 },
        steps = {
            {
                id = "read_hoofprint",
                actionText = "READ",
                objectText = "Warden Hoofprint",
                offset = { x = -6, y = 0.7, z = 3 },
            },
            {
                id = "study_scrape",
                actionText = "STUDY",
                objectText = "Antler Scrape",
                offset = { x = 0, y = 2.4, z = -2 },
            },
            {
                id = "mark_hollow",
                actionText = "MARK",
                objectText = "Sleeping Hollow",
                offset = { x = 6, y = 0.8, z = 3 },
            },
        },
    }),
    frozenDefinition({
        id = "event_bw_wildfire_choice",
        displayName = "Wildfire Choice",
        visual = "wildfire_choice",
        tags = { "fire", "rescue" },
        objective = "CLOSE THE THREE SAFE FIREBREAKS",
        detail = "Pack wet clay into the marked breaks and steer the burn away from the homes.",
        completionMessage = "THE FIRE TURNS FROM THE HOMES — +4 HEARTWOOD",
        failureMessage = "THE OPTIONAL GROVE BURNS OUT",
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The optional grove chars; the road and all residents remain recoverable.",
        localizationKey = "events.bramblewake.wildfire_choice",
        analyticsId = "BramblewakeWildfireChoice",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = { guidance = "Seal each marked break before the flame crosses." },
        groupVariant = { guidance = "Hold separate firebreaks at the same time." },
        reward = { materialId = "material_heartwood", amount = 4 },
        steps = {
            {
                id = "seal_farm_break",
                actionText = "SEAL",
                objectText = "Farm Firebreak",
                offset = { x = -7, y = 1, z = 1 },
            },
            {
                id = "seal_road_break",
                actionText = "SEAL",
                objectText = "Road Firebreak",
                offset = { x = 0, y = 1, z = -2 },
            },
            {
                id = "seal_grove_break",
                actionText = "SEAL",
                objectText = "Grove Firebreak",
                offset = { x = 7, y = 1, z = 1 },
            },
        },
    }),
}

local eventInteractionCount = 0
for _, definition in events do
    eventInteractionCount += #definition.steps
end

return table.freeze({
    RegionId = "region_bramblewake",
    Version = 3,
    CellSize = 72,
    ModuleCount = 12,
    PointOfInterestCount = 4,
    EventCount = 8,
    EventInteractionCount = eventInteractionCount,
    PartBudget = 640,
    BossArenaPartBudget = 40,
    BlackoutPartBudget = 20,
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
    RequiredModuleIds = table.freeze({
        "module_bw_old_growth_approach",
    }),
    Modules = table.freeze(modules),
    PointsOfInterest = table.freeze(pointsOfInterest),
    Events = table.freeze(events),
})
