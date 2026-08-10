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

local Strings = require("../../Strings")

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
        displayName = Strings.get("story.sunken_orchard"),
        role = "resource",
        visual = "orchard",
        storyLandmark = "last_harvest",
        storyTitle = Strings.get("story.the_last_harvest"),
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
        storyTitle = Strings.get("story.the_road_they_left"),
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
        displayName = Strings.get("expedition.sapfall_gully"),
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
        displayName = Strings.get("story.windmill_copse"),
        role = "landmark",
        visual = "windmill",
        storyLandmark = "last_repair",
        storyTitle = Strings.get("story.the_last_repair"),
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
        displayName = Strings.get("story.tangle_bridge"),
        role = "traversal",
        visual = "bridge",
        storyLandmark = "lost_crossing",
        storyTitle = Strings.get("story.the_lost_crossing"),
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
        displayName = Strings.get("expedition.old_growth_approach"),
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
        displayName = Strings.get("expedition.upper_orchard"),
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
        displayName = Strings.get("expedition.foxfire_glade"),
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
        displayName = Strings.get("expedition.thorn_gauntlet"),
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
        displayName = Strings.get("expedition.gleaner_s_yard"),
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
        displayName = Strings.get("story.reedstead_ruin"),
        visual = "ruined_homestead",
        tags = { "story", "resident" },
        detail = Strings.get("expedition.a_family_lived_here_until_the"),
    }),
    frozenDefinition({
        id = "poi_bw_mothwell",
        displayName = "Mothwell",
        visual = "moth_well",
        tags = { "puzzle", "mystery" },
        detail = Strings.get("expedition.moths_gather_here_in_numbers_no"),
    }),
    frozenDefinition({
        id = "poi_bw_sapglass_grove",
        displayName = Strings.get("story.sapglass_grove"),
        visual = "sap_grove",
        tags = { "resource", "risk" },
        detail = Strings.get("expedition.amber_runs_freely_here_because_the"),
    }),
    frozenDefinition({
        id = "poi_bw_root_chapel",
        displayName = "Root Chapel",
        visual = "root_chapel",
        tags = { "story", "sanctuary" },
        detail = Strings.get("expedition.nobody_built_this_the_roots_grew"),
    }),
    --[[
        The eight that rotate. The first four anchor memory fragments and
        are pinned into every run; these appear a few at a time, so a
        player who has walked Bramblewake fifty times still meets ground
        they have not stood on. Each belongs to one of the region's three
        acts -- what the forest kept, the keeper's trail, and what came
        after -- and two of them face outward, toward regions a chapter-I
        player has not heard of yet.
    ]]
    frozenDefinition({
        id = "poi_bw_first_camp",
        displayName = Strings.get("expedition.the_first_camp"),
        visual = "first_camp",
        tags = { "story", "evacuation" },
        detail = Strings.get("expedition.where_emberhollow_spent_its_first_night"),
    }),
    frozenDefinition({
        id = "poi_bw_keepers_rest",
        displayName = Strings.get("expedition.the_keeper_s_rest"),
        visual = "keepers_rest",
        tags = { "story", "keeper" },
        detail = Strings.get("expedition.a_lean_to_with_one_bed"),
    }),
    frozenDefinition({
        id = "poi_bw_split_waymarker",
        displayName = Strings.get("expedition.the_split_waymarker"),
        visual = "split_waymarker",
        tags = { "mystery", "traversal" },
        detail = Strings.get("expedition.a_signpost_pointing_two_ways_both"),
    }),
    frozenDefinition({
        id = "poi_bw_colliers_clearing",
        displayName = Strings.get("expedition.colliers_clearing"),
        visual = "colliers_clearing",
        tags = { "resource", "story" },
        detail = Strings.get("expedition.charcoal_mounds_still_sealed_from_when"),
    }),
    frozenDefinition({
        id = "poi_bw_sunken_footbridge",
        displayName = Strings.get("expedition.the_sunken_footbridge"),
        visual = "sunken_footbridge",
        tags = { "traversal", "warning" },
        detail = Strings.get("expedition.a_footbridge_with_black_water_over"),
    }),
    frozenDefinition({
        id = "poi_bw_scored_pine",
        displayName = Strings.get("expedition.the_scored_pine"),
        visual = "scored_pine",
        tags = { "warning", "warden" },
        detail = Strings.get("expedition.a_trunk_scored_by_antlers_deep"),
    }),
    frozenDefinition({
        id = "poi_bw_bee_hollows",
        displayName = Strings.get("expedition.the_bee_hollows"),
        visual = "bee_hollows",
        tags = { "resource", "sanctuary" },
        detail = Strings.get("expedition.wild_hives_in_the_root_hollows"),
    }),
    frozenDefinition({
        id = "poi_bw_lantern_rest",
        displayName = Strings.get("expedition.the_lantern_rest"),
        visual = "lantern_rest",
        tags = { "story", "mystery" },
        detail = Strings.get("expedition.rows_of_old_lanterns_hung_on"),
    }),
}

local events = {
    frozenDefinition({
        id = "event_bw_moving_hedge",
        displayName = "Moving Hedge",
        visual = "hedge",
        tags = { "route_change", "traversal" },
        objective = Strings.get("expedition.turn_the_three_root_latches"),
        detail = Strings.get("expedition.the_hedge_changes_its_side_paths"),
        completionMessage = "THE HEDGE SETTLES — +4 HEARTWOOD",
        failureMessage = Strings.get("expedition.the_hedge_slips_away"),
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_side_cache_closes_the_marked"),
        localizationKey = "events.bramblewake.moving_hedge",
        analyticsId = "BramblewakeMovingHedge",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.turn_each_latch_before_the_roots"),
        },
        groupVariant = {
            guidance = Strings.get("expedition.split_up_and_turn_separate_latches"),
        },
        reward = {
            materialId = "material_heartwood",
            amount = 4,
        },
        steps = {
            {
                id = "latch_west",
                actionText = Strings.get("expedition.turn"),
                objectText = Strings.get("expedition.west_root_latch"),
                offset = { x = -7, y = 1.5, z = 0 },
            },
            {
                id = "latch_center",
                actionText = Strings.get("expedition.turn"),
                objectText = Strings.get("expedition.center_root_latch"),
                offset = { x = 0, y = 1.5, z = 0 },
            },
            {
                id = "latch_east",
                actionText = Strings.get("expedition.turn"),
                objectText = Strings.get("expedition.east_root_latch"),
                offset = { x = 7, y = 1.5, z = 0 },
            },
        },
    }),
    frozenDefinition({
        id = "event_bw_lost_wagon",
        displayName = "Lost Wagon",
        visual = "wagon",
        tags = { "rescue", "choice" },
        objective = Strings.get("expedition.stabilize_the_lost_wagon"),
        detail = Strings.get("expedition.brace_the_axle_lift_the_tongue"),
        completionMessage = "THE WAGON IS SAFE — +3 MEADOW FIBER",
        failureMessage = Strings.get("expedition.the_wagon_sinks_into_the_ferns"),
        durationSeconds = 120,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_wagon_reward_is_lost_no"),
        localizationKey = "events.bramblewake.lost_wagon",
        analyticsId = "BramblewakeLostWagon",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.complete_the_three_braces_in_any"),
        },
        groupVariant = {
            guidance = Strings.get("expedition.several_travelers_can_stabilize_the_wagon"),
        },
        reward = {
            materialId = "material_meadow_fiber",
            amount = 3,
        },
        steps = {
            {
                id = "brace_axle",
                actionText = Strings.get("expedition.brace"),
                objectText = "Broken Axle",
                offset = { x = -5, y = 1, z = 3 },
            },
            {
                id = "lift_tongue",
                actionText = Strings.get("expedition.lift"),
                objectText = "Wagon Tongue",
                offset = { x = 6, y = 1, z = 1 },
            },
            {
                id = "secure_crate",
                actionText = Strings.get("expedition.secure"),
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
        objective = Strings.get("expedition.bind_the_three_bridge_roots"),
        detail = Strings.get("expedition.tighten_the_living_knots_to_open"),
        completionMessage = "THE ROOT BRIDGE HOLDS — +2 AMBER SAP",
        failureMessage = Strings.get("expedition.the_optional_crossing_unravels"),
        durationSeconds = 105,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_shortcut_closes_the_default_amber"),
        localizationKey = "events.bramblewake.root_bridge",
        analyticsId = "BramblewakeRootBridge",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.bind_each_knot_from_stable_ground"),
        },
        groupVariant = {
            guidance = Strings.get("expedition.travelers_may_bind_different_knots_at"),
        },
        reward = {
            materialId = "material_amber_sap",
            amount = 2,
        },
        steps = {
            {
                id = "bind_left",
                actionText = Strings.get("expedition.bind"),
                objectText = Strings.get("expedition.left_root_knot"),
                offset = { x = -6, y = 2, z = 2 },
            },
            {
                id = "bind_center",
                actionText = Strings.get("expedition.bind"),
                objectText = Strings.get("expedition.center_root_knot"),
                offset = { x = 0, y = 3, z = 0 },
            },
            {
                id = "bind_right",
                actionText = Strings.get("expedition.bind"),
                objectText = Strings.get("expedition.right_root_knot"),
                offset = { x = 6, y = 2, z = 2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_bw_foxlight_trail",
        displayName = Strings.get("expedition.foxlight_trail"),
        visual = "foxlight",
        tags = { "navigation", "mystery" },
        objective = Strings.get("expedition.wake_the_four_foxlights"),
        detail = Strings.get("expedition.attune_every_quiet_light_to_reveal"),
        completionMessage = "THE FOXLIGHTS ANSWER — +2 BRIGHTCAP",
        failureMessage = Strings.get("expedition.the_foxlights_return_to_sleep"),
        durationSeconds = 100,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 14,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_hidden_memory_remains_undiscovered_extra"),
        localizationKey = "events.bramblewake.foxlight_trail",
        analyticsId = "BramblewakeFoxlightTrail",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.follow_the_lights_around_the_clearing"),
        },
        groupVariant = {
            guidance = Strings.get("expedition.wake_separate_lights_to_reveal_the"),
        },
        reward = {
            materialId = "material_brightcap",
            amount = 2,
        },
        steps = {
            {
                id = "wake_north",
                actionText = Strings.get("expedition.attune"),
                objectText = Strings.get("expedition.north_foxlight"),
                offset = { x = 0, y = 3, z = -6 },
            },
            {
                id = "wake_east",
                actionText = Strings.get("expedition.attune"),
                objectText = Strings.get("expedition.east_foxlight"),
                offset = { x = 6, y = 4, z = 0 },
            },
            {
                id = "wake_south",
                actionText = Strings.get("expedition.attune"),
                objectText = Strings.get("expedition.south_foxlight"),
                offset = { x = 0, y = 5, z = 6 },
            },
            {
                id = "wake_west",
                actionText = Strings.get("expedition.attune"),
                objectText = Strings.get("expedition.west_foxlight"),
                offset = { x = -6, y = 4, z = 0 },
            },
        },
    }),
    frozenDefinition({
        id = "event_bw_pollen_storm",
        displayName = "Pollen Storm",
        visual = "pollen_storm",
        tags = { "weather", "shelter" },
        objective = Strings.get("expedition.raise_the_three_pollen_screens"),
        detail = Strings.get("expedition.turn_each_woven_screen_into_the"),
        completionMessage = "THE CLEARING CAN BREATHE — +3 BRIGHTCAP",
        failureMessage = Strings.get("expedition.the_pollen_claims_the_side_clearing"),
        durationSeconds = 95,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_side_clearing_closes_until_the"),
        localizationKey = "events.bramblewake.pollen_storm",
        analyticsId = "BramblewakePollenStorm",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = { guidance = Strings.get("expedition.raise_each_screen_from_the_sheltered") },
        groupVariant = {
            guidance = Strings.get("expedition.travelers_can_raise_separate_screens_togethe"),
        },
        reward = { materialId = "material_brightcap", amount = 3 },
        steps = {
            {
                id = "screen_west",
                actionText = Strings.get("expedition.raise"),
                objectText = Strings.get("expedition.west_pollen_screen"),
                offset = { x = -7, y = 2.5, z = 0 },
            },
            {
                id = "screen_center",
                actionText = Strings.get("expedition.raise"),
                objectText = Strings.get("expedition.center_pollen_screen"),
                offset = { x = 0, y = 2.5, z = 0 },
            },
            {
                id = "screen_east",
                actionText = Strings.get("expedition.raise"),
                objectText = Strings.get("expedition.east_pollen_screen"),
                offset = { x = 7, y = 2.5, z = 0 },
            },
        },
    }),
    frozenDefinition({
        id = "event_bw_hungry_homestead",
        displayName = Strings.get("expedition.hungry_homestead"),
        visual = "hungry_homestead",
        tags = { "resident", "supply" },
        objective = Strings.get("expedition.restock_the_three_homestead_stores"),
        detail = Strings.get("expedition.set_seed_water_and_preserved_roots"),
        completionMessage = "THE HOMESTEAD ENDURES — +3 SPRING CLAY",
        failureMessage = Strings.get("expedition.the_homestead_bolts_its_doors"),
        durationSeconds = 115,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_family_shelters_without_a_reward"),
        localizationKey = "events.bramblewake.hungry_homestead",
        analyticsId = "BramblewakeHungryHomestead",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = { guidance = Strings.get("expedition.stock_each_porch_store_in_any") },
        groupVariant = { guidance = Strings.get("expedition.split_the_supplies_across_the_porch") },
        reward = { materialId = "material_spring_clay", amount = 3 },
        steps = {
            {
                id = "stock_seed",
                actionText = Strings.get("expedition.stock"),
                objectText = "Seed Bin",
                -- Porch floor sits at anchor.y + 0.7 (HomesteadPorch in
                -- BramblewakeBuilder); this box is 2.5 tall, so its base
                -- needs y = 0.7 + 1.25 to rest on the boards instead of
                -- sinking into them.
                offset = { x = -6, y = 1.95, z = 1 },
            },
            {
                id = "fill_water",
                actionText = Strings.get("expedition.fill"),
                objectText = "Water Cask",
                -- Cask is now an upright 3-tall cylinder (BramblewakeBuilder
                -- fix); base needs y = 0.7 (porch top) + 1.5 (half height).
                offset = { x = 0, y = 2.2, z = -2 },
            },
            {
                id = "store_roots",
                actionText = Strings.get("expedition.store"),
                objectText = "Root Cellar",
                offset = { x = 6, y = 1.95, z = 1 },
            },
        },
    }),
    frozenDefinition({
        id = "event_bw_stag_tracks",
        displayName = "Stag Tracks",
        visual = "stag_tracks",
        tags = { "tracking", "mystery" },
        objective = Strings.get("expedition.read_the_three_warden_tracks"),
        detail = Strings.get("expedition.study_the_hoofprint_antler_scrape_and"),
        completionMessage = "THE WARDEN'S PATH IS KNOWN — +2 AMBER SAP",
        failureMessage = Strings.get("expedition.rain_erases_the_warden_s_trail"),
        durationSeconds = 100,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_optional_trail_memory_is_lost"),
        localizationKey = "events.bramblewake.stag_tracks",
        analyticsId = "BramblewakeStagTracks",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = { guidance = Strings.get("expedition.read_each_sign_before_the_rain") },
        groupVariant = {
            guidance = Strings.get("expedition.search_separate_edges_of_the_clearing"),
        },
        reward = { materialId = "material_amber_sap", amount = 2 },
        steps = {
            {
                id = "read_hoofprint",
                actionText = Strings.get("expedition.read"),
                objectText = Strings.get("expedition.warden_hoofprint"),
                offset = { x = -6, y = 0.7, z = 3 },
            },
            {
                id = "study_scrape",
                actionText = Strings.get("expedition.study"),
                objectText = Strings.get("expedition.antler_scrape"),
                offset = { x = 0, y = 2.4, z = -2 },
            },
            {
                id = "mark_hollow",
                actionText = Strings.get("expedition.mark"),
                objectText = Strings.get("expedition.sleeping_hollow"),
                offset = { x = 6, y = 0.8, z = 3 },
            },
        },
    }),
    frozenDefinition({
        id = "event_bw_wildfire_choice",
        displayName = Strings.get("expedition.wildfire_choice"),
        visual = "wildfire_choice",
        tags = { "fire", "rescue" },
        objective = Strings.get("expedition.close_the_three_safe_firebreaks"),
        detail = Strings.get("expedition.pack_wet_clay_into_the_marked"),
        completionMessage = "THE FIRE TURNS FROM THE HOMES — +4 HEARTWOOD",
        failureMessage = Strings.get("expedition.the_optional_grove_burns_out"),
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_optional_grove_chars_the_road"),
        localizationKey = "events.bramblewake.wildfire_choice",
        analyticsId = "BramblewakeWildfireChoice",
        killSwitchFlag = "bramblewake_events_enabled",
        soloVariant = { guidance = Strings.get("expedition.seal_each_marked_break_before_the") },
        groupVariant = { guidance = Strings.get("expedition.hold_separate_firebreaks_at_the_same") },
        reward = { materialId = "material_heartwood", amount = 4 },
        --[[
            A step's `y` is measured from the event socket's own anchor, which
            stands half a stud above the module floor on a plate seven studs
            across. These three were all written at y = 1, which seats a break
            on that plate -- and only the road break is on it. The farm and
            grove breaks are seven studs out over bare ground, so y = 1 left
            them, and the road stones the mesh pass seats on their underside,
            hanging 0.9 studs in the air. A 1.2-stud-tall marker needs y = 0.1
            to have its bottom on the floor.
        ]]
        steps = {
            {
                id = "seal_farm_break",
                actionText = Strings.get("town.seal"),
                objectText = Strings.get("expedition.farm_firebreak"),
                offset = { x = -7, y = 0.1, z = 1 },
            },
            {
                id = "seal_road_break",
                actionText = Strings.get("town.seal"),
                objectText = Strings.get("expedition.road_firebreak"),
                offset = { x = 0, y = 1, z = -2 },
            },
            {
                id = "seal_grove_break",
                actionText = Strings.get("town.seal"),
                objectText = Strings.get("expedition.grove_firebreak"),
                offset = { x = 7, y = 0.1, z = 1 },
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
    PointOfInterestCount = 6,
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
    --[[
        The four fragment-anchored POIs place in every run; the eight new
        ones rotate through the remaining two slots. See the generator's
        note on FixedPointOfInterestIds for why.
    ]]
    FixedPointOfInterestIds = table.freeze({
        "poi_bw_reedstead_ruin",
        "poi_bw_mothwell",
        "poi_bw_sapglass_grove",
        "poi_bw_root_chapel",
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
