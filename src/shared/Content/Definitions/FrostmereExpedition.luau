--!strict

--[[
    Frostmere Vale -- chapter V's region: a high cold valley where an
    abbey kept the last warm rooms and then stopped answering.

    The Reach's problem is exposure; the Vale's is that warmth is a
    resource. Nothing here is safe because it is indoors, it is safe
    because something in it is still burning, and every fire in this
    valley is one somebody else lit and left. So its modules are hearths,
    ember beds, thawed ground and the spaces between them, and the
    distance between two warm places is the real hazard.

    Its second rule is quiet. Sound carries a long way over snow and
    several things here are listening, so the valley asks a party to
    choose between moving fast and moving unheard -- which is the same
    choice as warmth, one step sideways.
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
    warmth-bearing ones are deliberately spread across roles rather than
    grouped: a party should never be able to plan a route that is only
    hearths, because the distance between fires is the region.
]]
local modules = {
    frozenDefinition({
        id = "module_fv_abbey_gate",
        displayName = "Abbey Gate",
        role = "arrival",
        visual = "abbey_gate",
        tags = { "safe", "connector", "arrival" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 24,
        lightBudget = 3,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_fv_warm_road",
        displayName = "Warm Road",
        role = "extraction",
        visual = "warm_road",
        tags = { "safe", "extraction" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 26,
        lightBudget = 3,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_fv_ember_beds",
        displayName = "Ember Beds",
        role = "resource",
        visual = "ember_beds",
        tags = { "resource", "warmth" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 3,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_thaw_quarry",
        displayName = "Thaw Quarry",
        role = "resource",
        visual = "thaw_quarry",
        tags = { "resource", "risk" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_wool_sheds",
        displayName = "Wool Sheds",
        role = "resource",
        visual = "wool_sheds",
        tags = { "resource", "safe" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_fv_salt_pans_frozen",
        displayName = "Frozen Salt Pans",
        role = "resource",
        visual = "salt_pans_frozen",
        tags = { "resource", "mystery" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_ice_cellars",
        displayName = "Ice Cellars",
        role = "resource",
        visual = "ice_cellars",
        tags = { "resource", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_moss_hollow",
        displayName = "Moss Hollow",
        role = "resource",
        visual = "moss_hollow",
        tags = { "resource", "warmth" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 38,
        lightBudget = 3,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_frozen_orchard",
        displayName = "Frozen Orchard",
        role = "resource",
        visual = "frozen_orchard",
        tags = { "resource", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_thin_ice_crossing",
        displayName = "Thin Ice Crossing",
        role = "traversal",
        visual = "thin_ice_crossing",
        tags = { "traversal", "risk" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_drift_pass",
        displayName = "Drift Pass",
        role = "traversal",
        visual = "drift_pass",
        tags = { "traversal", "cold" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_fv_rope_bridge_gorge",
        displayName = "Rope Bridge Gorge",
        role = "traversal",
        visual = "rope_bridge_gorge",
        tags = { "traversal", "risk" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_cloister_walk",
        displayName = "Cloister Walk",
        role = "traversal",
        visual = "cloister_walk",
        tags = { "traversal", "safe" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_fv_whiteout_flat",
        displayName = "Whiteout Flat",
        role = "traversal",
        visual = "whiteout_flat",
        tags = { "traversal", "cold" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 36,
        lightBudget = 1,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_fv_bell_stair",
        displayName = "Bell Stair",
        role = "traversal",
        visual = "bell_stair",
        tags = { "traversal", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_hush_den",
        displayName = "Hush Den",
        role = "combat",
        visual = "hush_den",
        tags = { "combat", "quiet" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_rime_shelf",
        displayName = "Rime Shelf",
        role = "combat",
        visual = "rime_shelf",
        tags = { "combat", "warmth" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_moth_belfry",
        displayName = "Moth Belfry",
        role = "combat",
        visual = "moth_belfry",
        tags = { "combat", "quiet" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_fv_snowbound_field",
        displayName = "Snowbound Field",
        role = "combat",
        visual = "snowbound_field",
        tags = { "combat", "risk" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_borer_undercroft",
        displayName = "Borer Undercroft",
        role = "combat",
        visual = "borer_undercroft",
        tags = { "combat", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_snow_lane",
        displayName = "Snow Lane",
        role = "connector",
        visual = "snow_lane",
        tags = { "connector", "safe" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 30,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_fv_warming_hut",
        displayName = "Warming Hut",
        role = "connector",
        visual = "warming_hut",
        tags = { "connector", "warmth" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 32,
        lightBudget = 3,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_fv_abbey_arch",
        displayName = "Abbey Arch",
        role = "connector",
        visual = "abbey_arch",
        tags = { "connector", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 32,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_fv_wind_break",
        displayName = "Wind Break",
        role = "connector",
        visual = "wind_break",
        tags = { "connector", "cold" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 30,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_fv_abbot_study",
        displayName = "Abbot's Study",
        role = "story",
        visual = "abbot_study",
        tags = { "story", "resident" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 3,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_fv_refectory",
        displayName = "Refectory",
        role = "story",
        visual = "refectory",
        tags = { "story", "warmth" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 3,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_fv_aurora_shrine",
        displayName = "Aurora Shrine",
        role = "story",
        visual = "aurora_shrine",
        tags = { "story", "mystery" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 38,
        lightBudget = 2,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_fv_bell_ropes",
        displayName = "Bell Ropes",
        role = "puzzle",
        visual = "bell_ropes",
        tags = { "puzzle", "quiet" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_hearth_locks",
        displayName = "Hearth Locks",
        role = "puzzle",
        visual = "hearth_locks",
        tags = { "puzzle", "warmth" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 3,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_fv_howler_approach",
        displayName = "Howler Approach",
        role = "landmark",
        visual = "howler_approach",
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
        id = "poi_fv_cold_hearth",
        displayName = "The Cold Hearth",
        visual = "cold_hearth",
        tags = { "story", "warning" },
        detail = "The abbey's great fire, banked for the night it stopped "
            .. "being tended. The wood beside it is still stacked and "
            .. "still dry.",
    }),
    frozenDefinition({
        id = "poi_fv_bell_without_rope",
        displayName = "Bell Without a Rope",
        visual = "bell_without_rope",
        tags = { "mystery", "quiet" },
        detail = "The rope was cut from below and taken away. Something did "
            .. "not want this bell rung, and went to the trouble of being "
            .. "thorough.",
    }),
    frozenDefinition({
        id = "poi_fv_aurora_stones",
        displayName = "Aurora Stones",
        visual = "aurora_stones",
        tags = { "mystery", "story" },
        detail = "Standing stones that answer the lights overhead, one for "
            .. "one, and hold the colour for a few seconds after the sky "
            .. "lets go.",
    }),
    frozenDefinition({
        id = "poi_fv_last_wool",
        displayName = "The Last Wool",
        visual = "last_wool",
        tags = { "resource", "resident" },
        detail = "A shed of fleeces carded and never spun, each bundle "
            .. "tagged in a different hand. The tags are names, not "
            .. "weights.",
    }),
    frozenDefinition({
        id = "poi_fv_thawed_letter_box",
        displayName = "Thawed Letter Box",
        visual = "thawed_letter_box",
        tags = { "story", "resident" },
        detail = "The valley's post, frozen solid and thawed once by "
            .. "somebody who read every letter and left them all where the "
            .. "writers could find them.",
    }),
    frozenDefinition({
        id = "poi_fv_hunters_blind",
        displayName = "Hunter's Blind",
        visual = "hunters_blind",
        tags = { "warning", "quiet" },
        detail = "Built to watch the pass in silence, and abandoned facing "
            .. "the abbey rather than the road, which is the wrong way to "
            .. "sit.",
    }),
    frozenDefinition({
        id = "poi_fv_ice_choir",
        displayName = "The Ice Choir",
        visual = "ice_choir",
        tags = { "mystery", "sanctuary" },
        detail = "Columns the melt refroze into a nave. Sing in it once and "
            .. "it will hold the note for longer than a breath should "
            .. "last.",
    }),
    frozenDefinition({
        id = "poi_fv_ember_cache",
        displayName = "Ember Cache",
        visual = "ember_cache",
        tags = { "resource", "sanctuary" },
        detail = "Coals kept alive in a stone box by whoever passes, each of "
            .. "them leaving more than they took. The practice has "
            .. "outlived the abbey.",
    }),
    frozenDefinition({
        id = "poi_fv_snow_grave_row",
        displayName = "Snow Grave Row",
        visual = "snow_grave_row",
        tags = { "story", "warning" },
        detail = "Nine mounds in a line, dug in a season when the ground "
            .. "should have been too hard, by people who found a way "
            .. "because it mattered.",
    }),
    frozenDefinition({
        id = "poi_fv_abbots_window",
        displayName = "Abbot's Window",
        visual = "abbots_window",
        tags = { "story", "mystery" },
        detail = "The one glass in the valley, facing north at nothing but "
            .. "weather. Somebody sat here long enough to wear the sill "
            .. "smooth.",
    }),
    frozenDefinition({
        id = "poi_fv_warm_spring",
        displayName = "Warm Spring",
        visual = "warm_spring",
        tags = { "resource", "safe" },
        detail = "Water that comes out of the rock at blood heat and freezes "
            .. "twenty feet later. The moss around it is the greenest "
            .. "thing for miles.",
    }),
    frozenDefinition({
        id = "poi_fv_howlers_track",
        displayName = "Howler's Track",
        visual = "howlers_track",
        tags = { "warning", "risk" },
        detail = "Prints crossing the pass in a straight line, ignoring the "
            .. "road, the gorge and the drift. Whatever made them was not "
            .. "picking its way.",
    }),
}

local events = {
    frozenDefinition({
        id = "event_fv_warmth_split",
        displayName = "Warmth Split",
        visual = "warmth_split",
        tags = { "choice", "warmth" },
        objective = "DECIDE WHERE THE LAST EMBERS GO",
        detail = "One cache of embers, two hearths that need it: the shepherd's hut on the pass or the abbey's own.",
        completionMessage = "THE FIRE IS SET — +3 EMBER MOSS",
        failureMessage = "THE EMBERS GO OUT UNDECIDED",
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.frostmere.warmth_split",
        analyticsId = "FrostmereWarmthSplit",
        killSwitchFlag = "frostmere_events_enabled",
        soloVariant = {
            guidance = "Read both, then bank where you mean it. The choice is the point.",
        },
        groupVariant = { guidance = "Argue it out; the cache only fills one." },
        reward = { materialId = "material_ember_moss", amount = 3 },
        steps = {
            {
                id = "read_hearths",
                actionText = "READ",
                objectText = "Both Hearths",
                offset = { x = -5, y = 1.5, z = 0 },
            },
            {
                id = "bank_embers",
                actionText = "BANK",
                objectText = "Ember Cache",
                offset = { x = 5, y = 1.4, z = 1 },
            },
        },
    }),
    frozenDefinition({
        id = "event_fv_abbey_bell",
        displayName = "Abbey Bell",
        visual = "abbey_bell",
        tags = { "quiet", "urgent" },
        objective = "RING THE ABBEY BELL WITHOUT BEING HEARD FIRST",
        detail = "The bell will call anyone still alive in the valley. It will also call everything else.",
        completionMessage = "THE VALLEY HEARS IT — +3 AURORA SALT",
        failureMessage = "SOMETHING GETS THERE FIRST",
        durationSeconds = 100,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.frostmere.abbey_bell",
        analyticsId = "FrostmereAbbeyBell",
        killSwitchFlag = "frostmere_events_enabled",
        soloVariant = {
            guidance = "Muffle, clear, ring — in that order or it announces you twice.",
        },
        groupVariant = { guidance = "One muffles while one clears; ring together." },
        reward = { materialId = "material_aurora_salt", amount = 3 },
        steps = {
            {
                id = "muffle_clapper",
                actionText = "MUFFLE",
                objectText = "Bell Clapper",
                offset = { x = -6, y = 2, z = 0 },
            },
            {
                id = "clear_stair",
                actionText = "CLEAR",
                objectText = "Belfry Stair",
                offset = { x = 6, y = 1.6, z = 0 },
            },
            {
                id = "ring_bell",
                actionText = "RING",
                objectText = "Abbey Bell",
                offset = { x = 0, y = 2.4, z = 4 },
            },
        },
    }),
    frozenDefinition({
        id = "event_fv_thin_ice",
        displayName = "Thin Ice",
        visual = "thin_ice",
        tags = { "hazard", "traversal" },
        objective = "GET EVERYONE ACROSS BEFORE IT GOES",
        detail = "The crossing held yesterday. It is singing today, which is what ice does before it stops holding.",
        completionMessage = "EVERYONE IS OVER — +2 FROSTMERE ICE",
        failureMessage = "THE CROSSING GOES UNDER",
        durationSeconds = 80,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.frostmere.thin_ice",
        analyticsId = "FrostmereThinIce",
        killSwitchFlag = "frostmere_events_enabled",
        soloVariant = { guidance = "Test, lay, cross — and do not stand still on the middle." },
        groupVariant = { guidance = "Test together, lay together, cross one at a time." },
        reward = { materialId = "material_frostmere_ice", amount = 2 },
        steps = {
            {
                id = "test_edge",
                actionText = "TEST",
                objectText = "Ice Edge",
                offset = { x = -5, y = 1.2, z = -2 },
            },
            {
                id = "lay_planks",
                actionText = "LAY",
                objectText = "Plank Run",
                offset = { x = 0, y = 1.2, z = 3 },
            },
            {
                id = "cross_last",
                actionText = "CROSS",
                objectText = "Far Bank",
                offset = { x = 6, y = 1.3, z = -2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_fv_aurora_tracks",
        displayName = "Aurora Tracks",
        visual = "aurora_tracks",
        tags = { "mystery", "timed" },
        objective = "FOLLOW THE TRACKS WHILE THE LIGHTS HOLD",
        detail = "The aurora shows prints in the snow that daylight does not, and it will not hold for long.",
        completionMessage = "THE TRAIL IS READ — +3 AURORA SALT",
        failureMessage = "THE LIGHTS FADE OFF THE TRAIL",
        durationSeconds = 75,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.frostmere.aurora_tracks",
        analyticsId = "FrostmereAuroraTracks",
        killSwitchFlag = "frostmere_events_enabled",
        soloVariant = { guidance = "Read them in order; the trail only makes sense forwards." },
        groupVariant = { guidance = "Split the prints and call what you see." },
        reward = { materialId = "material_aurora_salt", amount = 3 },
        steps = {
            {
                id = "read_first",
                actionText = "READ",
                objectText = "First Print",
                offset = { x = -6, y = 1.2, z = 0 },
            },
            {
                id = "read_second",
                actionText = "READ",
                objectText = "Second Print",
                offset = { x = 0, y = 1.2, z = 4 },
            },
            {
                id = "read_third",
                actionText = "READ",
                objectText = "Third Print",
                offset = { x = 6, y = 1.2, z = 0 },
            },
        },
    }),
    frozenDefinition({
        id = "event_fv_frozen_letter",
        displayName = "Frozen Letter",
        visual = "frozen_letter",
        tags = { "story", "gentle" },
        objective = "THAW THE LETTER WITHOUT LOSING IT",
        detail = "A letter frozen into the post box, addressed in a hand somebody in town would know.",
        completionMessage = "THE LETTER IS READABLE — +2 WOOL",
        failureMessage = "THE INK RUNS AND TAKES THE NAME",
        durationSeconds = 85,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.frostmere.frozen_letter",
        analyticsId = "FrostmereFrozenLetter",
        killSwitchFlag = "frostmere_events_enabled",
        soloVariant = { guidance = "Warm it slowly. Fast is how the ink is lost." },
        groupVariant = { guidance = "One warms, one lifts, and neither hurries." },
        reward = { materialId = "material_frostmere_wool", amount = 2 },
        steps = {
            {
                id = "warm_box",
                actionText = "WARM",
                objectText = "Letter Box",
                offset = { x = -4, y = 1.4, z = 0 },
            },
            {
                id = "lift_letter",
                actionText = "LIFT",
                objectText = "Frozen Letter",
                offset = { x = 4, y = 1.3, z = 0 },
            },
        },
    }),
    frozenDefinition({
        id = "event_fv_whiteout_camp",
        displayName = "Whiteout Camp",
        visual = "whiteout_camp",
        tags = { "rescue", "urgent" },
        objective = "FIND THE CAMP IN THE WHITEOUT",
        detail = "Somebody pitched a tent in the open and the weather closed over them an hour ago.",
        completionMessage = "THE CAMP IS FOUND — +3 THAWED IRON",
        failureMessage = "THE WHITEOUT TAKES THE TRAIL",
        durationSeconds = 105,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.frostmere.whiteout_camp",
        analyticsId = "FrostmereWhiteoutCamp",
        killSwitchFlag = "frostmere_events_enabled",
        soloVariant = { guidance = "Sweep both sides before calling; calling first moves them." },
        groupVariant = { guidance = "Sweep a side each, then call together." },
        reward = { materialId = "material_thawed_iron", amount = 3 },
        steps = {
            {
                id = "sweep_left",
                actionText = "SWEEP",
                objectText = "Left Ground",
                offset = { x = -7, y = 1.3, z = 0 },
            },
            {
                id = "sweep_right",
                actionText = "SWEEP",
                objectText = "Right Ground",
                offset = { x = 7, y = 1.3, z = 0 },
            },
            {
                id = "call_out",
                actionText = "CALL",
                objectText = "Into The White",
                offset = { x = 0, y = 1.6, z = 5 },
            },
        },
    }),
    frozenDefinition({
        id = "event_fv_quiet_hunt",
        displayName = "Quiet Hunt",
        visual = "quiet_hunt",
        tags = { "quiet", "risk" },
        objective = "TAKE THE HUNT WITHOUT MAKING A SOUND",
        detail = "Something is stalking the same herd you are, and it is winning because it is quieter.",
        completionMessage = "THE HUNT IS YOURS — +3 WOOL",
        failureMessage = "IT HEARS YOU FIRST",
        durationSeconds = 95,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.frostmere.quiet_hunt",
        analyticsId = "FrostmereQuietHunt",
        killSwitchFlag = "frostmere_events_enabled",
        soloVariant = { guidance = "Wrap, still the bells, then take the line." },
        groupVariant = { guidance = "One wraps, one stills; take the line together." },
        reward = { materialId = "material_frostmere_wool", amount = 3 },
        steps = {
            {
                id = "pad_boots",
                actionText = "PAD",
                objectText = "Boot Wraps",
                offset = { x = -5, y = 1.3, z = 0 },
            },
            {
                id = "still_bells",
                actionText = "STILL",
                objectText = "Herd Bells",
                offset = { x = 5, y = 1.4, z = 0 },
            },
            {
                id = "take_line",
                actionText = "TAKE",
                objectText = "Hunting Line",
                offset = { x = 0, y = 1.5, z = 4 },
            },
        },
    }),
    frozenDefinition({
        id = "event_fv_thaw_choice",
        displayName = "Thaw Choice",
        visual = "thaw_choice",
        tags = { "choice", "story" },
        objective = "DECIDE WHAT THE THAW UNCOVERS",
        detail = "A warm spring is eating the ice over something the abbey buried on purpose.",
        completionMessage = "THE GROUND IS SETTLED — +2 THAWED IRON",
        failureMessage = "THE THAW DECIDES FOR ITSELF",
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.frostmere.thaw_choice",
        analyticsId = "FrostmereThawChoice",
        killSwitchFlag = "frostmere_events_enabled",
        soloVariant = { guidance = "Read the marker before you touch the channel." },
        groupVariant = { guidance = "Read it aloud, then agree; the channel moves once." },
        reward = { materialId = "material_thawed_iron", amount = 2 },
        steps = {
            {
                id = "read_marker",
                actionText = "READ",
                objectText = "Abbey Marker",
                offset = { x = -4, y = 1.5, z = 0 },
            },
            {
                id = "commit_choice",
                actionText = "COMMIT",
                objectText = "Spring Channel",
                offset = { x = 4, y = 1.4, z = 1 },
            },
        },
    }),
}

local eventInteractionCount = 0
for _, definition in events do
    eventInteractionCount += #definition.steps
end

return table.freeze({
    RegionId = "region_frostmere",
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
        "module_fv_howler_approach",
    }),
    FixedMiddleIds = table.freeze({
        "module_fv_snow_lane",
        "module_fv_ember_beds",
        "module_fv_drift_pass",
        "module_fv_hush_den",
        "module_fv_wool_sheds",
        "module_fv_bell_ropes",
        "module_fv_thin_ice_crossing",
        "module_fv_abbot_study",
        "module_fv_rime_shelf",
        "module_fv_howler_approach",
    }),
    Modules = table.freeze(modules),
    PointsOfInterest = table.freeze(pointsOfInterest),
    Events = table.freeze(events),
})
