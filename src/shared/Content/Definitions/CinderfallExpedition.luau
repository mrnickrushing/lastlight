--!strict

--[[
    Cinderfall Crown -- chapter VI's region: a city that burned in the
    middle of its own ceremony, and has been performing it ever since.

    Every region so far has had a hazard a player can point at. The Delve
    is dark, the Fen is drowned, the Reach is exposed, the Vale is cold.
    The Crown's hazard is that it is still going. The ash set hard around
    everything it touched and the heat turned half the city to glass, so
    the parade is still on the parade route, the crowd is still in the
    stands, and the applause still starts when someone walks into the
    court. Nothing here is pretending to be alive. It is doing exactly
    what it was doing, which is worse.

    So the region's rule is that a memory can be false. Most of what
    stands here is a cast rather than a person -- ash around a shape that
    is no longer inside it -- and those repeat, endlessly and slightly
    wrong. The authentic ones do not perform. They are the statues facing
    away from the stage, the shop with nothing in the window, the name
    scratched under the official name. Learning to tell them apart is the
    whole region, and it is why the Crown's modules are full of things
    that look like they are about to do something.

    Its second rule is heat. The kilns that made the glass are still lit
    where the coal held, and the cooling channels that kept the city
    workable still run where they were not crushed. Warmth in Frostmere
    was safety; here it is the opposite -- the lit places are the ones
    still making false things, and the cold ones are where the truth got
    to stop.
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
    Thirty modules in the distribution the earlier regions proved. The
    lit ones and the cold ones are deliberately interleaved: a party
    should never be able to route around the working half of the city,
    because deciding which memories to trust is the region and the lit
    modules are where the false ones are made.
]]
local Strings = require("../../Strings")

local modules = {
    frozenDefinition({
        id = "module_cc_crown_gate",
        displayName = "Crown Gate",
        role = "arrival",
        visual = "crown_gate",
        tags = { "safe", "connector", "arrival" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 24,
        lightBudget = 3,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_cc_ash_road",
        displayName = "Ash Road",
        role = "extraction",
        visual = "ash_road",
        tags = { "safe", "extraction" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 26,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_cc_kiln_row",
        displayName = "Kiln Row",
        role = "resource",
        visual = "kiln_row",
        tags = { "resource", "heat" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 3,
        effectBudget = 2,
    }),
    -- Trees the heat glassed where they stood. The fruit is still
    -- on them, which is the first time the Crown lies to a player
    -- about what is safe to be near.
    frozenDefinition({
        id = "module_cc_glass_orchard",
        displayName = Strings.get("expedition.glass_orchard"),
        role = "resource",
        visual = "glass_orchard",
        tags = { "resource", "memory" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_cc_silk_looms",
        displayName = Strings.get("expedition.ash_silk_looms"),
        role = "resource",
        visual = "silk_looms",
        tags = { "resource", "safe" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_cc_pearl_beds",
        displayName = Strings.get("expedition.kiln_pearl_beds"),
        role = "resource",
        visual = "pearl_beds",
        tags = { "resource", "risk" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_cc_coal_terraces",
        displayName = Strings.get("expedition.coal_terraces"),
        role = "resource",
        visual = "coal_terraces",
        tags = { "resource", "heat" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 3,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_cc_slag_gardens",
        displayName = "Slag Gardens",
        role = "resource",
        visual = "slag_gardens",
        tags = { "resource", "mystery" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_cc_foundry_yards",
        displayName = Strings.get("expedition.foundry_yards"),
        role = "resource",
        visual = "foundry_yards",
        tags = { "resource", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 46,
        lightBudget = 2,
        effectBudget = 2,
    }),
    -- The procession is still walking it. Nothing on this module
    -- attacks; it simply does not stop, and a party has to decide
    -- how long to watch before that becomes a problem.
    frozenDefinition({
        id = "module_cc_parade_route",
        displayName = "Parade Route",
        role = "traversal",
        visual = "parade_route",
        tags = { "traversal", "memory" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_cc_cooling_channel",
        displayName = Strings.get("expedition.cooling_channel"),
        role = "traversal",
        visual = "cooling_channel",
        tags = { "traversal", "heat" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_cc_collapsed_tiers",
        displayName = Strings.get("expedition.collapsed_tiers"),
        role = "traversal",
        visual = "collapsed_tiers",
        tags = { "traversal", "risk" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_cc_ash_colonnade",
        displayName = Strings.get("expedition.ash_colonnade"),
        role = "traversal",
        visual = "ash_colonnade",
        tags = { "traversal", "safe" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 36,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_cc_stage_bridges",
        displayName = Strings.get("expedition.stage_bridges"),
        role = "traversal",
        visual = "stage_bridges",
        tags = { "traversal", "risk" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_cc_procession_stair",
        displayName = Strings.get("expedition.procession_stair"),
        role = "traversal",
        visual = "procession_stair",
        tags = { "traversal", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 38,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_cc_applause_court",
        displayName = Strings.get("expedition.applause_court"),
        role = "combat",
        visual = "applause_court",
        tags = { "combat", "memory" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 46,
        lightBudget = 2,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_cc_knight_gallery",
        displayName = Strings.get("expedition.glass_knight_gallery"),
        role = "combat",
        visual = "knight_gallery",
        tags = { "combat", "risk" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_cc_worm_kilns",
        displayName = "Worm Kilns",
        role = "combat",
        visual = "worm_kilns",
        tags = { "combat", "heat" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 3,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_cc_giant_plaza",
        displayName = Strings.get("expedition.parade_giant_plaza"),
        role = "combat",
        visual = "giant_plaza",
        tags = { "combat", "risk" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 46,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_cc_citizen_quarter",
        displayName = Strings.get("expedition.false_citizen_quarter"),
        role = "combat",
        visual = "citizen_quarter",
        tags = { "combat", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_cc_ash_lane",
        displayName = "Ash Lane",
        role = "connector",
        visual = "ash_lane",
        tags = { "connector", "safe" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 28,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_cc_warm_arcade",
        displayName = "Warm Arcade",
        role = "connector",
        visual = "warm_arcade",
        tags = { "connector", "heat" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 32,
        lightBudget = 3,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_cc_crown_arch",
        displayName = "Crown Arch",
        role = "connector",
        visual = "crown_arch",
        tags = { "connector", "story" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 32,
        lightBudget = 2,
        effectBudget = 1,
    }),
    -- A kiln that went out during the firing. Everything it holds
    -- is half-made and therefore honest, which makes this the one
    -- connector worth stopping in.
    frozenDefinition({
        id = "module_cc_cold_kiln",
        displayName = "Cold Kiln",
        role = "connector",
        visual = "cold_kiln",
        tags = { "connector", "memory" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 34,
        lightBudget = 1,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_cc_regents_box",
        displayName = Strings.get("expedition.the_regent_s_box"),
        role = "story",
        visual = "regents_box",
        tags = { "story", "resident" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_cc_sculptors_hall",
        displayName = Strings.get("expedition.sculptor_s_hall"),
        role = "story",
        visual = "sculptors_hall",
        tags = { "story", "memory" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_cc_memory_vault",
        displayName = "Memory Vault",
        role = "story",
        visual = "memory_vault",
        tags = { "story", "mystery" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 3,
    }),
    -- The puzzle room: a row of casts, one of which is facing the
    -- wrong way. That is the Ash Regent's fight taught without the
    -- Regent.
    frozenDefinition({
        id = "module_cc_statue_line",
        displayName = "Statue Line",
        role = "puzzle",
        visual = "statue_line",
        tags = { "puzzle", "memory" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_cc_kiln_locks",
        displayName = "Kiln Locks",
        role = "puzzle",
        visual = "kiln_locks",
        tags = { "puzzle", "heat" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 3,
        effectBudget = 2,
    }),
    -- The landmark: the stands, the stage and the Regent's own box,
    -- with the false statues already standing in it.
    frozenDefinition({
        id = "module_cc_regent_approach",
        displayName = Strings.get("expedition.regent_s_approach"),
        role = "landmark",
        visual = "regent_approach",
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
        id = "poi_cc_last_ovation",
        displayName = Strings.get("story.the_last_ovation_2"),
        visual = "last_ovation",
        tags = { "story", "warning" },
        detail = Strings.get("expedition.the_crowd_in_the_upper_stands"),
    }),
    frozenDefinition({
        id = "poi_cc_glass_family",
        displayName = Strings.get("expedition.the_glass_family"),
        visual = "glass_family",
        tags = { "mystery", "story" },
        detail = Strings.get("expedition.four_figures_at_a_table_and"),
    }),
    frozenDefinition({
        id = "poi_cc_unfinished_statue",
        displayName = Strings.get("expedition.the_unfinished_statue"),
        visual = "unfinished_statue",
        tags = { "mystery", "memory" },
        detail = Strings.get("expedition.half_carved_and_abandoned_with_the"),
    }),
    frozenDefinition({
        id = "poi_cc_regents_chair",
        displayName = Strings.get("expedition.the_regent_s_chair"),
        visual = "regents_chair",
        tags = { "story", "resident" },
        detail = Strings.get("expedition.empty_and_clean_in_a_box"),
    }),
    frozenDefinition({
        id = "poi_cc_ash_shadow",
        displayName = Strings.get("expedition.the_ash_shadow"),
        visual = "ash_shadow",
        tags = { "story", "warning" },
        detail = Strings.get("expedition.a_shape_burned_into_a_wall"),
    }),
    frozenDefinition({
        id = "poi_cc_kiln_still_lit",
        displayName = Strings.get("expedition.the_kiln_still_lit"),
        visual = "kiln_still_lit",
        tags = { "resource", "heat" },
        detail = Strings.get("expedition.coal_enough_for_another_century_feeding"),
    }),
    frozenDefinition({
        id = "poi_cc_false_shopfront",
        displayName = Strings.get("expedition.the_false_shopfront"),
        visual = "false_shopfront",
        tags = { "mystery", "warning" },
        detail = Strings.get("expedition.a_shop_with_a_full_window"),
    }),
    frozenDefinition({
        id = "poi_cc_crown_mold",
        displayName = Strings.get("expedition.the_crown_mold"),
        visual = "crown_mold",
        tags = { "resource", "story" },
        detail = Strings.get("expedition.the_mold_the_ceremonial_crown_was"),
    }),
    frozenDefinition({
        id = "poi_cc_name_wall",
        displayName = Strings.get("story.the_name_wall"),
        visual = "name_wall",
        tags = { "story", "resident" },
        detail = Strings.get("expedition.official_names_cut_deep_and_formal"),
    }),
    frozenDefinition({
        id = "poi_cc_cooling_pool",
        displayName = Strings.get("expedition.the_cooling_pool"),
        visual = "cooling_pool",
        tags = { "resource", "safe" },
        detail = Strings.get("expedition.channel_water_still_running_cold_through"),
    }),
    frozenDefinition({
        id = "poi_cc_understudy",
        displayName = Strings.get("expedition.the_understudy"),
        visual = "understudy",
        tags = { "mystery", "story" },
        detail = Strings.get("expedition.a_cast_of_the_regent_in"),
    }),
    frozenDefinition({
        id = "poi_cc_crown_marker",
        displayName = Strings.get("expedition.the_crown_marker"),
        visual = "crown_marker",
        tags = { "landmark", "story" },
        detail = Strings.get("expedition.a_processional_marker_pointing_the_way"),
    }),
}

local events = {
    frozenDefinition({
        id = "event_cc_parade_loop",
        displayName = "Parade Loop",
        visual = "parade_loop",
        tags = { "memory", "urgent" },
        objective = Strings.get("expedition.break_the_procession_before_it_comes"),
        detail = Strings.get("expedition.the_parade_has_walked_this_route"),
        completionMessage = "THE PROCESSION BREAKS — +3 MEMORY GLASS",
        failureMessage = Strings.get("expedition.it_comes_round_again"),
        durationSeconds = 100,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_chance_passes_the_marked_critical"),
        localizationKey = "events.cinderfall.parade_loop",
        analyticsId = "CinderfallParadeLoop",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.find_the_one_that_leads_not"),
        },
        groupVariant = { guidance = Strings.get("expedition.one_reads_the_line_while_the") },
        reward = { materialId = "material_memory_glass", amount = 3 },
        steps = {
            {
                id = "read_line",
                actionText = Strings.get("expedition.read"),
                objectText = Strings.get("expedition.procession_line"),
                offset = { x = -6, y = 1.5, z = -2 },
            },
            {
                id = "mark_leader",
                actionText = Strings.get("expedition.mark"),
                objectText = Strings.get("expedition.the_one_leading"),
                offset = { x = 4, y = 1.4, z = 3 },
            },
            {
                id = "break_step",
                actionText = Strings.get("town.break"),
                objectText = "Its Step",
                offset = { x = 7, y = 1.2, z = -5 },
            },
        },
    }),
    frozenDefinition({
        id = "event_cc_glass_family",
        displayName = "Glass Family",
        visual = "glass_family_event",
        tags = { "choice", "memory" },
        objective = Strings.get("expedition.decide_which_of_them_was_real"),
        detail = Strings.get("expedition.four_figures_one_of_them_a"),
        completionMessage = "THE REAL ONE IS CARRIED OUT — +3 ASH SILK",
        failureMessage = Strings.get("expedition.all_four_are_left_where_they"),
        durationSeconds = 110,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_chance_passes_the_marked_critical"),
        localizationKey = "events.cinderfall.glass_family",
        analyticsId = "CinderfallGlassFamily",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.look_at_the_hands_casts_are"),
        },
        groupVariant = { guidance = Strings.get("expedition.split_the_four_compare_before_anyone") },
        reward = { materialId = "material_ash_silk", amount = 3 },
        steps = {
            {
                id = "read_seams",
                actionText = Strings.get("expedition.read"),
                objectText = "Their Hands",
                offset = { x = -5, y = 1.4, z = 1 },
            },
            {
                id = "lift_true",
                actionText = Strings.get("expedition.lift"),
                objectText = Strings.get("expedition.the_one_without_seams"),
                offset = { x = 5, y = 1.3, z = -2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_cc_kiln_restart",
        displayName = "Kiln Restart",
        visual = "kiln_restart",
        tags = { "heat", "risk" },
        objective = Strings.get("expedition.restart_a_kiln_without_firing_what"),
        detail = Strings.get("expedition.the_kiln_holds_a_cast_that"),
        completionMessage = "THE KILN RUNS COLD — +3 CROWN COAL",
        failureMessage = Strings.get("expedition.the_firing_completes"),
        durationSeconds = 120,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_chance_passes_the_marked_critical"),
        localizationKey = "events.cinderfall.kiln_restart",
        analyticsId = "CinderfallKilnRestart",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.vent_first_then_feed_feeding_a"),
        },
        groupVariant = { guidance = Strings.get("expedition.one_vents_while_one_feeds_do") },
        reward = { materialId = "material_crown_coal", amount = 3 },
        steps = {
            {
                id = "open_vent",
                actionText = Strings.get("world.open"),
                objectText = "Kiln Vent",
                offset = { x = -7, y = 1.6, z = 0 },
            },
            {
                id = "feed_coal",
                actionText = Strings.get("expedition.feed"),
                objectText = "Coal Chute",
                offset = { x = 6, y = 1.4, z = -3 },
            },
            {
                id = "bank_fire",
                actionText = Strings.get("expedition.bank"),
                objectText = "The Fire",
                offset = { x = 2, y = 1.2, z = 6 },
            },
        },
    }),
    frozenDefinition({
        id = "event_cc_actor_rescue",
        displayName = "Actor Rescue",
        visual = "actor_rescue",
        tags = { "urgent", "story" },
        objective = Strings.get("expedition.get_the_living_one_out_of"),
        detail = Strings.get("expedition.one_of_the_figures_on_the"),
        completionMessage = "THEY WALK OUT WITH YOU — +3 CINDERSTEEL",
        failureMessage = Strings.get("expedition.the_performance_continues"),
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 22,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_chance_passes_the_marked_critical"),
        localizationKey = "events.cinderfall.actor_rescue",
        analyticsId = "CinderfallActorRescue",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.cut_the_cast_not_the_person"),
        },
        groupVariant = { guidance = Strings.get("expedition.one_holds_the_company_s_attention") },
        reward = { materialId = "material_cindersteel", amount = 3 },
        steps = {
            {
                id = "find_breath",
                actionText = Strings.get("expedition.listen"),
                objectText = "The Company",
                offset = { x = -6, y = 1.5, z = 2 },
            },
            {
                id = "cut_cast",
                actionText = "CUT",
                objectText = "Ash Cast",
                offset = { x = 5, y = 1.3, z = -4 },
            },
        },
    }),
    frozenDefinition({
        id = "event_cc_ash_storm",
        displayName = "Ash Storm",
        visual = "ash_storm",
        tags = { "urgent", "cold" },
        objective = Strings.get("expedition.get_under_cover_before_the_fall"),
        detail = Strings.get("expedition.fresh_ash_falls_hot_and_sets"),
        completionMessage = "THE FALL PASSES OVER YOU — +3 KILN PEARL",
        failureMessage = Strings.get("expedition.the_fall_sets_around_you"),
        durationSeconds = 80,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 24,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_chance_passes_the_marked_critical"),
        localizationKey = "events.cinderfall.ash_storm",
        analyticsId = "CinderfallAshStorm",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.shutter_then_shelter_a_shelter_with"),
        },
        groupVariant = {
            guidance = Strings.get("expedition.shutters_are_faster_shared_shelter_together"),
        },
        reward = { materialId = "material_kiln_pearl", amount = 3 },
        steps = {
            {
                id = "close_shutters",
                actionText = Strings.get("hud.close"),
                objectText = Strings.get("expedition.arcade_shutters"),
                offset = { x = -8, y = 1.5, z = -1 },
            },
            {
                id = "take_shelter",
                actionText = Strings.get("expedition.shelter"),
                objectText = Strings.get("expedition.under_the_arcade"),
                offset = { x = 6, y = 1.2, z = 4 },
            },
        },
    }),
    frozenDefinition({
        id = "event_cc_false_shop",
        displayName = "False Shop",
        visual = "false_shop",
        tags = { "mystery", "choice" },
        objective = Strings.get("expedition.tell_the_stocked_shop_from_the"),
        detail = Strings.get("expedition.two_shopfronts_both_full_one_of"),
        completionMessage = "THE REAL STOCK COMES WITH YOU — +3 ASH SILK",
        failureMessage = Strings.get("expedition.you_carry_out_a_window"),
        durationSeconds = 95,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_chance_passes_the_marked_critical"),
        localizationKey = "events.cinderfall.false_shop",
        analyticsId = "CinderfallFalseShop",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.go_round_the_back_casts_are"),
        },
        groupVariant = { guidance = Strings.get("expedition.one_takes_each_front_meet_behind") },
        reward = { materialId = "material_ash_silk", amount = 3 },
        steps = {
            {
                id = "check_backs",
                actionText = Strings.get("expedition.check"),
                objectText = Strings.get("expedition.behind_both_fronts"),
                offset = { x = -6, y = 1.4, z = -3 },
            },
            {
                id = "take_stock",
                actionText = Strings.get("expedition.take"),
                objectText = Strings.get("expedition.the_real_stock"),
                offset = { x = 6, y = 1.3, z = 2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_cc_cooling_channel",
        displayName = Strings.get("expedition.cooling_channel"),
        visual = "cooling_channel_event",
        tags = { "heat", "puzzle" },
        objective = Strings.get("expedition.put_the_channel_back_through_the"),
        detail = Strings.get("expedition.the_channel_that_kept_this_quarter"),
        completionMessage = "THE QUARTER COOLS — +3 CROWN COAL",
        failureMessage = Strings.get("expedition.the_kilns_keep_their_heat"),
        durationSeconds = 115,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 22,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_chance_passes_the_marked_critical"),
        localizationKey = "events.cinderfall.cooling_channel",
        analyticsId = "CinderfallCoolingChannel",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.upstream_first_clearing_downstream_only_move"),
        },
        groupVariant = { guidance = Strings.get("expedition.take_a_block_each_but_clear") },
        reward = { materialId = "material_crown_coal", amount = 3 },
        steps = {
            {
                id = "clear_upper",
                actionText = Strings.get("town.clear"),
                objectText = "Upper Block",
                offset = { x = -8, y = 1.4, z = -4 },
            },
            {
                id = "clear_middle",
                actionText = Strings.get("town.clear"),
                objectText = "Middle Block",
                offset = { x = 0, y = 1.4, z = 5 },
            },
            {
                id = "clear_lower",
                actionText = Strings.get("town.clear"),
                objectText = "Lower Block",
                offset = { x = 8, y = 1.4, z = -2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_cc_empty_applause",
        displayName = Strings.get("expedition.empty_applause"),
        visual = "empty_applause",
        tags = { "memory", "quiet" },
        objective = Strings.get("expedition.stop_the_court_applauding"),
        detail = Strings.get("expedition.the_applause_starts_when_anyone_walks"),
        completionMessage = "THE COURT GOES QUIET — +3 MEMORY GLASS",
        failureMessage = Strings.get("expedition.the_applause_carries"),
        durationSeconds = 100,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_chance_passes_the_marked_critical"),
        localizationKey = "events.cinderfall.empty_applause",
        analyticsId = "CinderfallEmptyApplause",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.find_the_first_pair_of_hands"),
        },
        groupVariant = { guidance = Strings.get("expedition.spread_out_whoever_finds_the_first") },
        reward = { materialId = "material_memory_glass", amount = 3 },
        steps = {
            {
                id = "find_first",
                actionText = Strings.get("hud.find"),
                objectText = Strings.get("expedition.the_first_pair_of_hands"),
                offset = { x = -5, y = 1.5, z = 3 },
            },
            {
                id = "still_them",
                actionText = Strings.get("expedition.still"),
                objectText = "Them",
                offset = { x = 5, y = 1.3, z = -3 },
            },
        },
    }),
}

local eventInteractionCount = 0
for _, definition in events do
    eventInteractionCount += #definition.steps
end

return table.freeze({
    RegionId = "region_cinderfall",
    Version = 1,
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
        "module_cc_regent_approach",
    }),
    FixedMiddleIds = table.freeze({
        "module_cc_warm_arcade",
        "module_cc_kiln_row",
        "module_cc_parade_route",
        "module_cc_applause_court",
        "module_cc_silk_looms",
        "module_cc_statue_line",
        "module_cc_collapsed_tiers",
        "module_cc_regents_box",
        "module_cc_citizen_quarter",
        "module_cc_regent_approach",
    }),
    Modules = table.freeze(modules),
    PointsOfInterest = table.freeze(pointsOfInterest),
    Events = table.freeze(events),
})
