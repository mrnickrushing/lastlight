--!strict

--[[
    Mireglass Fen -- chapter III's region: a drowned country of standing
    water, mirror reed and glass that grew where the bog cooled wrong.

    The Delve's traversal problem was grade and dark. The Fen's is trust.
    Ground here is a claim, not a fact: reed mats hold or they do not,
    reflections show a path that is not there, and the calls you follow
    may not come from anyone. So its modules are about reading surfaces --
    fords, mats, mirror flats, sinking houses -- and its hazards are
    committing to the wrong one. Nothing in the Fen charges you; it lets
    you walk in.
]]

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

--[[
    Thirty modules in the role distribution both prior regions use (7
    resource, 6 traversal, 5 combat, 4 connector, 3 story, 2 puzzle, 1
    landmark, plus arrival and extraction). Budgets stay inside the
    regional ceilings for any twelve-module walk.
]]
local Strings = require("../../Strings")

local modules = {
    frozenDefinition({
        id = "module_mg_ferry_landing",
        displayName = Strings.get("expedition.ferry_landing"),
        role = "arrival",
        visual = "ferry_landing",
        tags = { "safe", "connector", "arrival" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 24,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_mg_dry_causeway",
        displayName = "Dry Causeway",
        role = "extraction",
        visual = "dry_causeway",
        tags = { "safe", "extraction" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 26,
        lightBudget = 2,
        effectBudget = 2,
    }),
    -- Resource: what the Fen gives, and what it charges for giving it.
    frozenDefinition({
        id = "module_mg_reed_harvest",
        displayName = "Reed Harvest",
        role = "resource",
        visual = "reed_harvest",
        tags = { "resource", "safe" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_mg_bog_iron_pits",
        displayName = Strings.get("expedition.bog_iron_pits"),
        role = "resource",
        visual = "bog_iron_pits",
        tags = { "resource", "risk" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 46,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_mg_pollen_hollow",
        displayName = Strings.get("expedition.pollen_hollow"),
        role = "resource",
        visual = "pollen_hollow",
        tags = { "resource", "mystery" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 3,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_mg_eel_weirs",
        displayName = "Eel Weirs",
        role = "resource",
        visual = "eel_weirs",
        tags = { "resource", "water" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_mg_herb_shallows",
        displayName = Strings.get("expedition.herb_shallows"),
        role = "resource",
        visual = "herb_shallows",
        tags = { "resource", "safe" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 38,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_mg_glass_flats",
        displayName = "Glass Flats",
        role = "resource",
        visual = "glass_flats",
        tags = { "resource", "mirror" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_mg_drowned_orchard",
        displayName = Strings.get("expedition.drowned_orchard"),
        role = "resource",
        visual = "drowned_orchard",
        tags = { "resource", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    -- Traversal: every one of these is a question about whether the
    -- ground you can see is ground.
    frozenDefinition({
        id = "module_mg_reed_mat_crossing",
        displayName = Strings.get("expedition.reed_mat_crossing"),
        role = "traversal",
        visual = "reed_mat_crossing",
        tags = { "traversal", "risk" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_mg_stepping_stones",
        displayName = Strings.get("expedition.stepping_stones"),
        role = "traversal",
        visual = "stepping_stones",
        tags = { "traversal", "water" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 38,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_mg_mirror_ford",
        displayName = "Mirror Ford",
        role = "traversal",
        visual = "mirror_ford",
        tags = { "traversal", "mirror" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_mg_sunken_boardwalk",
        displayName = Strings.get("expedition.sunken_boardwalk"),
        role = "traversal",
        visual = "sunken_boardwalk",
        tags = { "traversal", "safe" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 36,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_mg_leaning_house_row",
        displayName = Strings.get("expedition.leaning_house_row"),
        role = "traversal",
        visual = "leaning_house_row",
        tags = { "traversal", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 46,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_mg_fog_bank",
        displayName = "Fog Bank",
        role = "traversal",
        visual = "fog_bank",
        tags = { "traversal", "mystery" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 34,
        lightBudget = 1,
        effectBudget = 3,
    }),
    -- Combat: the Fen ambushes, mimics and drains rather than charging.
    frozenDefinition({
        id = "module_mg_lurker_shallows",
        displayName = Strings.get("expedition.lurker_shallows"),
        role = "combat",
        visual = "lurker_shallows",
        tags = { "combat", "water" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_mg_mirror_court",
        displayName = "Mirror Court",
        role = "combat",
        visual = "mirror_court",
        tags = { "combat", "mirror" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_mg_leech_pools",
        displayName = "Leech Pools",
        role = "combat",
        visual = "leech_pools",
        tags = { "combat", "risk" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_mg_heron_reach",
        displayName = "Heron Reach",
        role = "combat",
        visual = "heron_reach",
        tags = { "combat", "water" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_mg_bell_marsh",
        displayName = "Bell Marsh",
        role = "combat",
        visual = "bell_marsh",
        tags = { "combat", "mystery" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 3,
    }),
    -- Connectors: the dry lines between drownings.
    frozenDefinition({
        id = "module_mg_low_dyke",
        displayName = "Low Dyke",
        role = "connector",
        visual = "low_dyke",
        tags = { "connector", "safe" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 30,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_mg_punt_channel",
        displayName = "Punt Channel",
        role = "connector",
        visual = "punt_channel",
        tags = { "connector", "water" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 32,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_mg_willow_gate",
        displayName = "Willow Gate",
        role = "connector",
        visual = "willow_gate",
        tags = { "connector", "safe" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 30,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_mg_stilt_junction",
        displayName = Strings.get("expedition.stilt_junction"),
        role = "connector",
        visual = "stilt_junction",
        tags = { "connector", "story" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 34,
        lightBudget = 2,
        effectBudget = 1,
    }),
    -- Story: the Fen is full of people who stayed too long.
    frozenDefinition({
        id = "module_mg_ferryman_shack",
        displayName = Strings.get("expedition.ferryman_s_shack"),
        role = "story",
        visual = "ferryman_shack",
        tags = { "story", "resident" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 38,
        lightBudget = 3,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_mg_wake_platform",
        displayName = Strings.get("expedition.wake_platform"),
        role = "story",
        visual = "wake_platform",
        tags = { "story", "sanctuary" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 36,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_mg_sunken_chapel",
        displayName = Strings.get("expedition.sunken_chapel"),
        role = "story",
        visual = "sunken_chapel",
        tags = { "story", "mystery" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    -- Puzzle: both are about telling true from reflected.
    frozenDefinition({
        id = "module_mg_reflection_locks",
        displayName = Strings.get("expedition.reflection_locks"),
        role = "puzzle",
        visual = "reflection_locks",
        tags = { "puzzle", "mirror" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_mg_tide_gates",
        displayName = "Tide Gates",
        role = "puzzle",
        visual = "tide_gates",
        tags = { "puzzle", "water" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    -- The landmark and required approach: where the Lantern Witch waits.
    frozenDefinition({
        id = "module_mg_witch_approach",
        displayName = Strings.get("expedition.witchlight_approach"),
        role = "landmark",
        visual = "witch_approach",
        tags = { "landmark", "boss", "story" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 48,
        lightBudget = 3,
        effectBudget = 3,
    }),
}

local pointsOfInterest = {
    frozenDefinition({
        id = "poi_mg_upturned_punt",
        displayName = Strings.get("expedition.upturned_punt"),
        visual = "upturned_punt",
        tags = { "story", "warning" },
        detail = Strings.get("expedition.a_flat_bottomed_boat_resting_keel"),
    }),
    frozenDefinition({
        id = "poi_mg_still_pool",
        displayName = Strings.get("story.the_still_pool"),
        visual = "still_pool",
        tags = { "mirror", "mystery" },
        detail = Strings.get("expedition.nothing_disturbs_this_water_throw_something"),
    }),
    frozenDefinition({
        id = "poi_mg_rope_ladder_tree",
        displayName = Strings.get("expedition.rope_ladder_tree"),
        visual = "rope_ladder_tree",
        tags = { "story", "resident" },
        detail = Strings.get("expedition.a_willow_with_a_ladder_up"),
    }),
    frozenDefinition({
        id = "poi_mg_bell_buoy",
        displayName = "Bell Buoy",
        visual = "bell_buoy",
        tags = { "warning", "water" },
        detail = Strings.get("expedition.it_rings_on_the_swell_to"),
    }),
    frozenDefinition({
        id = "poi_mg_glasswright_kiln",
        displayName = Strings.get("expedition.glasswright_s_kiln"),
        visual = "glasswright_kiln",
        tags = { "resource", "story" },
        detail = Strings.get("expedition.the_kiln_that_first_fired_mireglass"),
    }),
    frozenDefinition({
        id = "poi_mg_drowned_market",
        displayName = Strings.get("expedition.drowned_market"),
        visual = "drowned_market",
        tags = { "story", "mystery" },
        detail = Strings.get("expedition.stall_frames_stand_in_chest_deep"),
    }),
    frozenDefinition({
        id = "poi_mg_heron_roost",
        displayName = "Heron Roost",
        visual = "heron_roost",
        tags = { "warning", "risk" },
        detail = Strings.get("expedition.dozens_of_them_stand_in_the"),
    }),
    frozenDefinition({
        id = "poi_mg_stilt_house",
        displayName = Strings.get("expedition.leaning_stilt_house"),
        visual = "stilt_house",
        tags = { "story", "resident" },
        detail = Strings.get("expedition.its_stilts_have_walked_in_the"),
    }),
    frozenDefinition({
        id = "poi_mg_witchlight_ring",
        displayName = Strings.get("expedition.witchlight_ring"),
        visual = "witchlight_ring",
        tags = { "mystery", "risk" },
        detail = Strings.get("expedition.pale_lights_hang_in_a_wide"),
    }),
    frozenDefinition({
        id = "poi_mg_ferry_ledger",
        displayName = "Ferry Ledger",
        visual = "ferry_ledger",
        tags = { "story", "sanctuary" },
        detail = Strings.get("expedition.every_crossing_recorded_in_a_careful"),
    }),
    frozenDefinition({
        id = "poi_mg_reed_shrine",
        displayName = "Reed Shrine",
        visual = "reed_shrine",
        tags = { "sanctuary", "resident" },
        detail = Strings.get("expedition.reeds_woven_into_small_figures_and"),
    }),
    frozenDefinition({
        id = "poi_mg_false_path",
        displayName = Strings.get("expedition.the_false_path"),
        visual = "false_path",
        tags = { "mirror", "warning" },
        detail = Strings.get("expedition.a_boardwalk_runs_out_across_the"),
    }),
}

--[[
    The eight events the content catalog reserved for the Fen. Their
    rewards pay in Fen materials, which join the ledger's allow-list in
    the same change that adds this file.
]]
local events = {
    frozenDefinition({
        id = "event_mg_mirror_party",
        displayName = "Mirror Party",
        visual = "mirror_party",
        tags = { "mirror", "mystery" },
        objective = Strings.get("expedition.put_out_the_three_false_lanterns"),
        detail = Strings.get("expedition.lights_and_laughter_across_the_water"),
        completionMessage = "THE WATER GOES DARK — +3 MIRROR REED",
        failureMessage = Strings.get("expedition.the_party_moves_further_out"),
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = { "event_mg_false_rescue" },
        failureResolution = Strings.get("expedition.the_lights_drift_out_of_reach"),
        localizationKey = "events.mireglass.mirror_party",
        analyticsId = "MireglassMirrorParty",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = { guidance = Strings.get("expedition.douse_each_false_lantern_they_do") },
        groupVariant = { guidance = Strings.get("expedition.one_lantern_each_and_do_not") },
        reward = { materialId = "material_mirror_reed", amount = 3 },
        steps = {
            {
                id = "lantern_near",
                actionText = Strings.get("expedition.douse"),
                objectText = Strings.get("expedition.near_false_lantern"),
                offset = { x = -6, y = 1.4, z = 0 },
            },
            {
                id = "lantern_mid",
                actionText = Strings.get("expedition.douse"),
                objectText = Strings.get("expedition.middle_false_lantern"),
                offset = { x = 0, y = 1.4, z = 4 },
            },
            {
                id = "lantern_far",
                actionText = Strings.get("expedition.douse"),
                objectText = Strings.get("expedition.far_false_lantern"),
                offset = { x = 6, y = 1.4, z = 0 },
            },
        },
    }),
    frozenDefinition({
        id = "event_mg_sinking_house",
        displayName = Strings.get("expedition.sinking_house"),
        visual = "sinking_house",
        tags = { "rescue", "urgent" },
        objective = Strings.get("expedition.shore_the_stilts_before_the_house"),
        detail = Strings.get("expedition.two_stilts_have_given_way_and"),
        completionMessage = "THE HOUSE HOLDS — +3 BOG IRON",
        failureMessage = Strings.get("expedition.the_house_settles_into_the_channel"),
        durationSeconds = 110,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_house_is_lost_but_its"),
        localizationKey = "events.mireglass.sinking_house",
        analyticsId = "MireglassSinkingHouse",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = { guidance = Strings.get("expedition.prop_both_stilts_then_brace_the") },
        groupVariant = { guidance = Strings.get("expedition.a_stilt_each_then_the_beam") },
        reward = { materialId = "material_bog_iron", amount = 3 },
        steps = {
            {
                id = "stilt_west",
                actionText = Strings.get("expedition.prop"),
                objectText = "West Stilt",
                offset = { x = -5, y = 1.2, z = 0 },
            },
            {
                id = "stilt_east",
                actionText = Strings.get("expedition.prop"),
                objectText = "East Stilt",
                offset = { x = 5, y = 1.2, z = 0 },
            },
            {
                id = "floor_beam",
                actionText = Strings.get("expedition.brace"),
                objectText = "Floor Beam",
                offset = { x = 0, y = 2, z = 3 },
            },
        },
    }),
    frozenDefinition({
        id = "event_mg_ferry_bargain",
        displayName = Strings.get("expedition.ferry_bargain"),
        visual = "ferry_bargain",
        tags = { "choice", "story" },
        objective = Strings.get("expedition.settle_the_ferryman_s_price"),
        detail = Strings.get("expedition.he_will_take_you_across_for"),
        completionMessage = "THE PRICE IS PAID — +2 EEL OIL",
        failureMessage = Strings.get("expedition.the_punt_pushes_off_without_you"),
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.you_walk_the_long_dyke_instead"),
        localizationKey = "events.mireglass.ferry_bargain",
        analyticsId = "MireglassFerryBargain",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = { guidance = Strings.get("expedition.hear_the_price_then_set_your") },
        groupVariant = {
            guidance = Strings.get("expedition.agree_among_yourselves_before_anyone_pays"),
        },
        reward = { materialId = "material_eel_oil", amount = 2 },
        steps = {
            {
                id = "hear_price",
                actionText = Strings.get("expedition.listen"),
                objectText = "The Ferryman",
                offset = { x = -3, y = 1.6, z = 0 },
            },
            {
                id = "pay_plank",
                actionText = "PAY",
                objectText = "Fare Plank",
                offset = { x = 3, y = 1.2, z = 1 },
            },
        },
    }),
    frozenDefinition({
        id = "event_mg_false_rescue",
        displayName = "False Rescue",
        visual = "false_rescue",
        tags = { "mystery", "warning" },
        objective = Strings.get("expedition.find_who_is_really_calling"),
        detail = Strings.get("expedition.a_voice_calls_for_help_from"),
        completionMessage = "THE CALLING STOPS — +2 WITCHLIGHT POLLEN",
        failureMessage = Strings.get("expedition.the_voice_moves_deeper_in"),
        durationSeconds = 100,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = { "event_mg_mirror_party" },
        failureResolution = Strings.get("expedition.the_voice_fades_into_the_fen"),
        localizationKey = "events.mireglass.false_rescue",
        analyticsId = "MireglassFalseRescue",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.check_both_reed_stands_before_answering"),
        },
        groupVariant = { guidance = Strings.get("expedition.do_not_split_up_check_the") },
        reward = { materialId = "material_witchlight_pollen", amount = 2 },
        steps = {
            {
                id = "reeds_left",
                actionText = Strings.get("expedition.search"),
                objectText = Strings.get("expedition.left_reed_stand"),
                offset = { x = -6, y = 1.2, z = 1 },
            },
            {
                id = "reeds_right",
                actionText = Strings.get("expedition.search"),
                objectText = Strings.get("expedition.right_reed_stand"),
                offset = { x = 6, y = 1.2, z = 1 },
            },
            {
                id = "answer_call",
                actionText = Strings.get("expedition.answer"),
                objectText = "The Calling",
                offset = { x = 0, y = 1.5, z = -4 },
            },
        },
    }),
    frozenDefinition({
        id = "event_mg_eel_migration",
        displayName = Strings.get("expedition.eel_migration"),
        visual = "eel_migration",
        tags = { "resource", "timed" },
        objective = Strings.get("expedition.set_the_weirs_before_the_run"),
        detail = Strings.get("expedition.the_whole_channel_is_moving_at"),
        completionMessage = "THE WEIRS ARE FULL — +4 EEL OIL",
        failureMessage = Strings.get("expedition.the_run_passes_through_empty_weirs"),
        durationSeconds = 75,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_run_passes_the_channel_is"),
        localizationKey = "events.mireglass.eel_migration",
        analyticsId = "MireglassEelMigration",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = { guidance = Strings.get("expedition.drop_each_weir_gate_as_the") },
        groupVariant = { guidance = Strings.get("expedition.a_gate_each_dropped_on_the") },
        reward = { materialId = "material_eel_oil", amount = 4 },
        steps = {
            {
                id = "weir_upper",
                actionText = "SET",
                objectText = Strings.get("expedition.upper_weir_gate"),
                offset = { x = -6, y = 1.2, z = -2 },
            },
            {
                id = "weir_middle",
                actionText = "SET",
                objectText = Strings.get("expedition.middle_weir_gate"),
                offset = { x = 0, y = 1.2, z = 2 },
            },
            {
                id = "weir_lower",
                actionText = "SET",
                objectText = Strings.get("expedition.lower_weir_gate"),
                offset = { x = 6, y = 1.2, z = -2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_mg_reed_fire",
        displayName = "Reed Fire",
        visual = "reed_fire",
        tags = { "hazard", "urgent" },
        objective = Strings.get("expedition.cut_a_firebreak_through_the_reeds"),
        detail = Strings.get("expedition.dry_reed_burns_fast_and_low"),
        completionMessage = "THE FIRE STOPS AT THE BREAK — +3 BLACKWATER HERB",
        failureMessage = Strings.get("expedition.the_fire_takes_the_near_stand"),
        durationSeconds = 95,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.a_reed_stand_burns_out_the"),
        localizationKey = "events.mireglass.reed_fire",
        analyticsId = "MireglassReedFire",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = { guidance = Strings.get("expedition.cut_both_ends_of_the_break") },
        groupVariant = { guidance = Strings.get("expedition.cut_from_both_ends_inward_and") },
        reward = { materialId = "material_blackwater_herb", amount = 3 },
        steps = {
            {
                id = "cut_west",
                actionText = "CUT",
                objectText = Strings.get("expedition.west_break_line"),
                offset = { x = -7, y = 1.1, z = 0 },
            },
            {
                id = "cut_east",
                actionText = "CUT",
                objectText = Strings.get("expedition.east_break_line"),
                offset = { x = 7, y = 1.1, z = 0 },
            },
            {
                id = "flood_break",
                actionText = Strings.get("expedition.flood"),
                objectText = "Break Sluice",
                offset = { x = 0, y = 1.3, z = 3 },
            },
        },
    }),
    frozenDefinition({
        id = "event_mg_three_answers",
        displayName = Strings.get("expedition.three_answers"),
        visual = "three_answers",
        tags = { "puzzle", "mystery" },
        objective = Strings.get("expedition.give_the_pool_three_true_answers"),
        detail = Strings.get("expedition.your_reflection_asks_three_questions_it"),
        completionMessage = "THE POOL LETS YOU PASS — +2 MIRROR REED",
        failureMessage = Strings.get("expedition.the_reflection_turns_away"),
        durationSeconds = 110,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_pool_goes_blank_the_path"),
        localizationKey = "events.mireglass.three_answers",
        analyticsId = "MireglassThreeAnswers",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.answer_each_in_turn_there_is"),
        },
        groupVariant = { guidance = Strings.get("expedition.each_may_answer_but_the_pool") },
        reward = { materialId = "material_mirror_reed", amount = 2 },
        steps = {
            {
                id = "answer_first",
                actionText = Strings.get("expedition.answer"),
                objectText = Strings.get("expedition.first_question"),
                offset = { x = -5, y = 1.3, z = 0 },
            },
            {
                id = "answer_second",
                actionText = Strings.get("expedition.answer"),
                objectText = Strings.get("expedition.second_question"),
                offset = { x = 0, y = 1.3, z = 3 },
            },
            {
                id = "answer_third",
                actionText = Strings.get("expedition.answer"),
                objectText = Strings.get("expedition.third_question"),
                offset = { x = 5, y = 1.3, z = 0 },
            },
        },
    }),
    frozenDefinition({
        id = "event_mg_drowned_market",
        displayName = Strings.get("expedition.drowned_market"),
        visual = "drowned_market_event",
        tags = { "story", "resource" },
        objective = Strings.get("expedition.take_one_thing_and_leave_payment"),
        detail = Strings.get("expedition.the_stalls_are_still_stocked_and"),
        completionMessage = "THE ACCOUNT IS SQUARE — +2 BOG IRON",
        failureMessage = Strings.get("expedition.the_stalls_are_empty_when_you"),
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_market_stays_as_it_is"),
        localizationKey = "events.mireglass.drowned_market",
        analyticsId = "MireglassDrownedMarket",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = { guidance = Strings.get("expedition.take_one_thing_then_leave_payment") },
        groupVariant = { guidance = Strings.get("expedition.one_taking_one_paying_and_nobody") },
        reward = { materialId = "material_bog_iron", amount = 2 },
        steps = {
            {
                id = "take_goods",
                actionText = Strings.get("expedition.take"),
                objectText = "Stall Hook",
                offset = { x = -4, y = 1.5, z = 0 },
            },
            {
                id = "leave_payment",
                actionText = Strings.get("hud.leave"),
                objectText = "Payment Hook",
                offset = { x = 4, y = 1.5, z = 0 },
            },
        },
    }),
}

local eventInteractionCount = 0
for _, definition in events do
    eventInteractionCount += #definition.steps
end

return table.freeze({
    RegionId = "region_mireglass",
    Version = 1,
    CellSize = 72,
    ModuleCount = 12,
    PointOfInterestCount = 4,
    EventCount = 8,
    EventInteractionCount = eventInteractionCount,
    -- Planning budgets, as in every region catalog: PartBudget bounds the
    -- manifest's summed module allowances, not built parts. The Fen has no
    -- built-part measurement until its builder ships and Studio measures it.
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
        "module_mg_witch_approach",
    }),
    --[[
        The two fragment-anchored POIs place in every run, Bramblewake's
        rule applied here the day the region opened: a memory fragment
        whose anchor only turns up some runs is a story beat demoted to
        a lottery ticket.
    ]]
    FixedPointOfInterestIds = table.freeze({
        "poi_mg_ferry_ledger",
        "poi_mg_still_pool",
    }),
    -- The known-good fallback walk: touches every required tag, keeps the
    -- puzzle and the landmark, and stays well inside every budget.
    FixedMiddleIds = table.freeze({
        "module_mg_low_dyke",
        "module_mg_reed_harvest",
        "module_mg_reed_mat_crossing",
        "module_mg_lurker_shallows",
        "module_mg_herb_shallows",
        "module_mg_reflection_locks",
        "module_mg_mirror_ford",
        "module_mg_ferryman_shack",
        "module_mg_heron_reach",
        "module_mg_witch_approach",
    }),
    Modules = table.freeze(modules),
    PointsOfInterest = table.freeze(pointsOfInterest),
    Events = table.freeze(events),
})
