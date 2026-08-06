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

    --[[
        The Milestone 5 expansion: eighteen more modules, taking the catalog
        to the full thirty-module set. Every run still walks twelve — the
        generator now SELECTS from this pool under the same tag minima — so
        each definition below reuses a proven visual recipe with its own
        role, tags, and budget rather than inventing untested geometry.
    ]]
    frozenDefinition({
        id = "module_bw_upper_orchard",
        displayName = "Upper Orchard",
        role = "resource",
        visual = "orchard",
        tags = { "resource", "farm", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_bramble_span",
        displayName = "Bramble Span",
        role = "traversal",
        visual = "bridge",
        tags = { "traversal", "puzzle" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 34,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_bw_fern_hollow",
        displayName = "Fern Hollow",
        role = "connector",
        visual = "root_arch",
        tags = { "safe", "connector" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 28,
        lightBudget = 1,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_bw_foxfire_glade",
        displayName = "Foxfire Glade",
        role = "traversal",
        visual = "foxglove",
        tags = { "traversal", "foxfire" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 30,
        lightBudget = 4,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_bw_thorn_gauntlet",
        displayName = "Thorn Gauntlet",
        role = "combat",
        visual = "briar_ring",
        tags = { "combat" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 36,
        lightBudget = 1,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_sap_terraces",
        displayName = "Sap Terraces",
        role = "resource",
        visual = "sapfall",
        tags = { "resource" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 38,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_mill_row",
        displayName = "Mill Row",
        role = "story",
        visual = "windmill",
        tags = { "story", "farm" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_moth_hollow",
        displayName = "Moth Hollow",
        role = "puzzle",
        visual = "moth_meadow",
        tags = { "puzzle", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 32,
        lightBudget = 3,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_drowned_farm",
        displayName = "Drowned Farm",
        role = "resource",
        visual = "farm",
        tags = { "resource", "farm", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_arch_row",
        displayName = "Arch Row",
        role = "connector",
        visual = "root_arch",
        tags = { "safe", "traversal" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 30,
        lightBudget = 1,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_bw_petal_run",
        displayName = "Petal Run",
        role = "traversal",
        visual = "foxglove",
        tags = { "traversal", "foxfire" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 30,
        lightBudget = 4,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_bw_briar_knot",
        displayName = "Briar Knot",
        role = "combat",
        visual = "briar_ring",
        tags = { "combat", "puzzle" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 36,
        lightBudget = 1,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_amber_falls",
        displayName = "Amber Falls",
        role = "resource",
        visual = "sapfall",
        tags = { "landmark", "resource" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 38,
        lightBudget = 3,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_wind_shear",
        displayName = "Wind Shear",
        role = "story",
        visual = "windmill",
        tags = { "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_moon_meadow",
        displayName = "Moon Meadow",
        role = "connector",
        visual = "moth_meadow",
        tags = { "safe", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 32,
        lightBudget = 3,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_root_span",
        displayName = "Root Span",
        role = "traversal",
        visual = "bridge",
        tags = { "traversal" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 34,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_bw_gleaners_yard",
        displayName = "Gleaner's Yard",
        role = "resource",
        visual = "farm",
        tags = { "resource", "combat", "farm" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_bw_watch_knoll",
        displayName = "Watch Knoll",
        role = "combat",
        visual = "root_arch",
        tags = { "landmark", "safe", "combat" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 30,
        lightBudget = 2,
        effectBudget = 1,
    }),
}

local pointsOfInterest = {
    frozenDefinition({
        id = "poi_bw_reedstead_ruin",
        displayName = "Reedstead Ruin",
        visual = "ruined_homestead",
        tags = { "story", "resident" },
        detail = "A family lived here until the roots came through the floor. "
            .. "The door is still barred from the inside.",
    }),
    frozenDefinition({
        id = "poi_bw_mothwell",
        displayName = "Mothwell",
        visual = "moth_well",
        tags = { "puzzle", "mystery" },
        detail = "Moths gather here in numbers no season explains. "
            .. "Something below the water is still warm.",
    }),
    frozenDefinition({
        id = "poi_bw_sapglass_grove",
        displayName = "Sapglass Grove",
        visual = "sap_grove",
        tags = { "resource", "risk" },
        detail = "Amber runs freely here because the trees were tapped and "
            .. "never sealed. Whatever feeds on the sap has not left.",
    }),
    frozenDefinition({
        id = "poi_bw_root_chapel",
        displayName = "Root Chapel",
        visual = "root_chapel",
        tags = { "story", "sanctuary" },
        detail = "Nobody built this. The roots grew into a nave and Emberhollow "
            .. "took it as a sign, and sheltered here on the way out.",
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
    --[[
        Two different things have been called "the part budget", and conflating
        them is why Bramblewake looked 233% over a budget it was never
        breaching.

        PartBudget bounds the MANIFEST: the sum of each chosen module's
        `partBudget` allowance, which ExpeditionGenerator.validate checks when
        it composes a run. That is a planning number, in units of "roughly how
        much structure is this module allowed to ask for". The preview seed
        totals 427 against 640, and has been comfortably inside it all along.

        BuiltPartBudget bounds the WORLD: BaseParts actually constructed under
        the expedition by BramblewakeBuilder, which is what
        `GeneratedPartCount` records and what the Studio integration test
        measures. Those are not the same quantity and never were -- a module
        with a planning allowance of 44 legitimately builds several hundred
        real parts once its trail stones, brambles, roots and dressing are
        instantiated. The test had been comparing built parts against the
        planning budget and failing on the mismatch.

        Derivation of 2600: the preview seed
        (Config.BramblewakePreviewSeed, which is the only seed the test ever
        builds) measures 2330 in Studio -- twelve modules plus the regional
        backdrop, before authored mesh dressing and before the Warden seal
        annex and Blackout layer, which are built afterwards by their own
        services and are therefore NOT in this number. 2600 is that measurement
        plus about 12% headroom.

        What this is: a regression guard. It catches the expedition quietly
        growing a few hundred parts nobody intended.

        What it is NOT: evidence that 2330 parts is affordable on a baseline
        phone. Nothing here has been measured on device, and
        TECHNICAL_ARCHITECTURE is explicit that Studio numbers are not hardware
        evidence. The device capture the Milestone 3 gate asks for is still
        owed, and if it comes back badly this ceiling should come down rather
        than the guard be widened again.
    ]]
    PartBudget = 640,
    BuiltPartBudget = 2600,
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
    --[[
        The known-good fallback's middle, in its original authored order.
        This is the exact twelve-module walk that shipped before the catalog
        grew to thirty, so the fallback stays the manifest every prior test
        proved. It lived in ExpeditionGenerator until the generator became
        region-agnostic; the list itself is unchanged.
    ]]
    FixedMiddleIds = table.freeze({
        "module_bw_root_arch",
        "module_bw_sunken_orchard",
        "module_bw_foxglove_run",
        "module_bw_hollow_farm",
        "module_bw_briar_ring",
        "module_bw_sapfall_gully",
        "module_bw_windmill_copse",
        "module_bw_tangle_bridge",
        "module_bw_moth_meadow",
        "module_bw_old_growth_approach",
    }),
    Modules = table.freeze(modules),
    PointsOfInterest = table.freeze(pointsOfInterest),
    Events = table.freeze(events),
})
