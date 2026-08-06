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
local modules = {
    frozenDefinition({
        id = "module_mg_ferry_landing",
        displayName = "Ferry Landing",
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
        displayName = "Bog Iron Pits",
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
        displayName = "Pollen Hollow",
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
        displayName = "Herb Shallows",
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
        displayName = "Drowned Orchard",
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
        displayName = "Reed Mat Crossing",
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
        displayName = "Stepping Stones",
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
        displayName = "Sunken Boardwalk",
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
        displayName = "Leaning House Row",
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
        displayName = "Lurker Shallows",
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
        displayName = "Stilt Junction",
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
        displayName = "Ferryman's Shack",
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
        displayName = "Wake Platform",
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
        displayName = "Sunken Chapel",
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
        displayName = "Reflection Locks",
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
        displayName = "Witchlight Approach",
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
        displayName = "Upturned Punt",
        visual = "upturned_punt",
        tags = { "story", "warning" },
        detail = "A flat-bottomed boat resting keel-up on the reeds, with "
            .. "its pole driven upright beside it like a marker.",
    }),
    frozenDefinition({
        id = "poi_mg_still_pool",
        displayName = "The Still Pool",
        visual = "still_pool",
        tags = { "mirror", "mystery" },
        detail = "Nothing disturbs this water. Throw something in and the "
            .. "rings stop at the edge of your reflection, not the bank.",
    }),
    frozenDefinition({
        id = "poi_mg_rope_ladder_tree",
        displayName = "Rope Ladder Tree",
        visual = "rope_ladder_tree",
        tags = { "story", "resident" },
        detail = "A willow with a ladder up it and a child's chalk marks on "
            .. "the trunk, measuring a flood that kept rising.",
    }),
    frozenDefinition({
        id = "poi_mg_bell_buoy",
        displayName = "Bell Buoy",
        visual = "bell_buoy",
        tags = { "warning", "water" },
        detail = "It rings on the swell to warn punts off the deep channel. "
            .. "On still nights it rings anyway, and slower.",
    }),
    frozenDefinition({
        id = "poi_mg_glasswright_kiln",
        displayName = "Glasswright's Kiln",
        visual = "glasswright_kiln",
        tags = { "resource", "story" },
        detail = "The kiln that first fired mireglass, cold now, its last "
            .. "batch still racked and cooling after all these years.",
    }),
    frozenDefinition({
        id = "poi_mg_drowned_market",
        displayName = "Drowned Market",
        visual = "drowned_market",
        tags = { "story", "mystery" },
        detail = "Stall frames stand in chest-deep water in tidy rows, and "
            .. "the goods hooks are all still hung with something.",
    }),
    frozenDefinition({
        id = "poi_mg_heron_roost",
        displayName = "Heron Roost",
        visual = "heron_roost",
        tags = { "warning", "risk" },
        detail = "Dozens of them stand in the shallows facing one way, and "
            .. "not one of them is looking at the water.",
    }),
    frozenDefinition({
        id = "poi_mg_stilt_house",
        displayName = "Leaning Stilt House",
        visual = "stilt_house",
        tags = { "story", "resident" },
        detail = "Its stilts have walked in the mud until the house faces "
            .. "away from the channel it was built to watch.",
    }),
    frozenDefinition({
        id = "poi_mg_witchlight_ring",
        displayName = "Witchlight Ring",
        visual = "witchlight_ring",
        tags = { "mystery", "risk" },
        detail = "Pale lights hang in a wide circle at head height. Step "
            .. "inside and they are behind you; they were never in front.",
    }),
    frozenDefinition({
        id = "poi_mg_ferry_ledger",
        displayName = "Ferry Ledger",
        visual = "ferry_ledger",
        tags = { "story", "sanctuary" },
        detail = "Every crossing recorded in a careful hand: names out, "
            .. "names back. The last page has three going and none returning.",
    }),
    frozenDefinition({
        id = "poi_mg_reed_shrine",
        displayName = "Reed Shrine",
        visual = "reed_shrine",
        tags = { "sanctuary", "resident" },
        detail = "Reeds woven into small figures and left on a plank altar, "
            .. "one for each house the water took, all facing the deep.",
    }),
    frozenDefinition({
        id = "poi_mg_false_path",
        displayName = "The False Path",
        visual = "false_path",
        tags = { "mirror", "warning" },
        detail = "A boardwalk runs out across the flat and simply stops, "
            .. "and the water beyond it reflects boards that are not there.",
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
        objective = "PUT OUT THE THREE FALSE LANTERNS",
        detail = "Lights and laughter across the water, from a landing that has no one on it.",
        completionMessage = "THE WATER GOES DARK — +3 MIRROR REED",
        failureMessage = "THE PARTY MOVES FURTHER OUT",
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = { "event_mg_false_rescue" },
        failureResolution = "The lights drift out of reach; the marked path stays open.",
        localizationKey = "events.mireglass.mirror_party",
        analyticsId = "MireglassMirrorParty",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = { guidance = "Douse each false lantern; they do not relight." },
        groupVariant = { guidance = "One lantern each, and do not answer the laughing." },
        reward = { materialId = "material_mirror_reed", amount = 3 },
        steps = {
            {
                id = "lantern_near",
                actionText = "DOUSE",
                objectText = "Near False Lantern",
                offset = { x = -6, y = 1.4, z = 0 },
            },
            {
                id = "lantern_mid",
                actionText = "DOUSE",
                objectText = "Middle False Lantern",
                offset = { x = 0, y = 1.4, z = 4 },
            },
            {
                id = "lantern_far",
                actionText = "DOUSE",
                objectText = "Far False Lantern",
                offset = { x = 6, y = 1.4, z = 0 },
            },
        },
    }),
    frozenDefinition({
        id = "event_mg_sinking_house",
        displayName = "Sinking House",
        visual = "sinking_house",
        tags = { "rescue", "urgent" },
        objective = "SHORE THE STILTS BEFORE THE HOUSE GOES OVER",
        detail = "Two stilts have given way and the floor is already tilting toward the channel.",
        completionMessage = "THE HOUSE HOLDS — +3 BOG IRON",
        failureMessage = "THE HOUSE SETTLES INTO THE CHANNEL",
        durationSeconds = 110,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The house is lost but its landing stays walkable; no route closes.",
        localizationKey = "events.mireglass.sinking_house",
        analyticsId = "MireglassSinkingHouse",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = { guidance = "Prop both stilts, then brace the floor beam." },
        groupVariant = { guidance = "A stilt each, then the beam together." },
        reward = { materialId = "material_bog_iron", amount = 3 },
        steps = {
            {
                id = "stilt_west",
                actionText = "PROP",
                objectText = "West Stilt",
                offset = { x = -5, y = 1.2, z = 0 },
            },
            {
                id = "stilt_east",
                actionText = "PROP",
                objectText = "East Stilt",
                offset = { x = 5, y = 1.2, z = 0 },
            },
            {
                id = "floor_beam",
                actionText = "BRACE",
                objectText = "Floor Beam",
                offset = { x = 0, y = 2, z = 3 },
            },
        },
    }),
    frozenDefinition({
        id = "event_mg_ferry_bargain",
        displayName = "Ferry Bargain",
        visual = "ferry_bargain",
        tags = { "choice", "story" },
        objective = "SETTLE THE FERRYMAN'S PRICE",
        detail = "He will take you across for a fair fare, or for something you would rather keep.",
        completionMessage = "THE PRICE IS PAID — +2 EEL OIL",
        failureMessage = "THE PUNT PUSHES OFF WITHOUT YOU",
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "You walk the long dyke instead; the crossing is slower, not closed.",
        localizationKey = "events.mireglass.ferry_bargain",
        analyticsId = "MireglassFerryBargain",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = { guidance = "Hear the price, then set your coin on the plank." },
        groupVariant = { guidance = "Agree among yourselves before anyone pays." },
        reward = { materialId = "material_eel_oil", amount = 2 },
        steps = {
            {
                id = "hear_price",
                actionText = "LISTEN",
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
        objective = "FIND WHO IS REALLY CALLING",
        detail = "A voice calls for help from the reeds, using a name it should not know.",
        completionMessage = "THE CALLING STOPS — +2 WITCHLIGHT POLLEN",
        failureMessage = "THE VOICE MOVES DEEPER IN",
        durationSeconds = 100,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = { "event_mg_mirror_party" },
        failureResolution = "The voice fades into the fen; nothing follows you out.",
        localizationKey = "events.mireglass.false_rescue",
        analyticsId = "MireglassFalseRescue",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = { guidance = "Check both reed stands before answering anything." },
        groupVariant = { guidance = "Do not split up; check the stands together." },
        reward = { materialId = "material_witchlight_pollen", amount = 2 },
        steps = {
            {
                id = "reeds_left",
                actionText = "SEARCH",
                objectText = "Left Reed Stand",
                offset = { x = -6, y = 1.2, z = 1 },
            },
            {
                id = "reeds_right",
                actionText = "SEARCH",
                objectText = "Right Reed Stand",
                offset = { x = 6, y = 1.2, z = 1 },
            },
            {
                id = "answer_call",
                actionText = "ANSWER",
                objectText = "The Calling",
                offset = { x = 0, y = 1.5, z = -4 },
            },
        },
    }),
    frozenDefinition({
        id = "event_mg_eel_migration",
        displayName = "Eel Migration",
        visual = "eel_migration",
        tags = { "resource", "timed" },
        objective = "SET THE WEIRS BEFORE THE RUN PASSES",
        detail = "The whole channel is moving at once, and it will not come back this season.",
        completionMessage = "THE WEIRS ARE FULL — +4 EEL OIL",
        failureMessage = "THE RUN PASSES THROUGH EMPTY WEIRS",
        durationSeconds = 75,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The run passes; the channel is quiet and safe to cross.",
        localizationKey = "events.mireglass.eel_migration",
        analyticsId = "MireglassEelMigration",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = { guidance = "Drop each weir gate as the run reaches it." },
        groupVariant = { guidance = "A gate each, dropped on the call." },
        reward = { materialId = "material_eel_oil", amount = 4 },
        steps = {
            {
                id = "weir_upper",
                actionText = "SET",
                objectText = "Upper Weir Gate",
                offset = { x = -6, y = 1.2, z = -2 },
            },
            {
                id = "weir_middle",
                actionText = "SET",
                objectText = "Middle Weir Gate",
                offset = { x = 0, y = 1.2, z = 2 },
            },
            {
                id = "weir_lower",
                actionText = "SET",
                objectText = "Lower Weir Gate",
                offset = { x = 6, y = 1.2, z = -2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_mg_reed_fire",
        displayName = "Reed Fire",
        visual = "reed_fire",
        tags = { "hazard", "urgent" },
        objective = "CUT A FIREBREAK THROUGH THE REEDS",
        detail = "Dry reed burns fast and low, and it is running toward the stilt houses.",
        completionMessage = "THE FIRE STOPS AT THE BREAK — +3 BLACKWATER HERB",
        failureMessage = "THE FIRE TAKES THE NEAR STAND",
        durationSeconds = 95,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "A reed stand burns out; the ground it leaves is bare and passable.",
        localizationKey = "events.mireglass.reed_fire",
        analyticsId = "MireglassReedFire",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = { guidance = "Cut both ends of the break, then flood the middle." },
        groupVariant = { guidance = "Cut from both ends inward and flood together." },
        reward = { materialId = "material_blackwater_herb", amount = 3 },
        steps = {
            {
                id = "cut_west",
                actionText = "CUT",
                objectText = "West Break Line",
                offset = { x = -7, y = 1.1, z = 0 },
            },
            {
                id = "cut_east",
                actionText = "CUT",
                objectText = "East Break Line",
                offset = { x = 7, y = 1.1, z = 0 },
            },
            {
                id = "flood_break",
                actionText = "FLOOD",
                objectText = "Break Sluice",
                offset = { x = 0, y = 1.3, z = 3 },
            },
        },
    }),
    frozenDefinition({
        id = "event_mg_three_answers",
        displayName = "Three Answers",
        visual = "three_answers",
        tags = { "puzzle", "mystery" },
        objective = "GIVE THE POOL THREE TRUE ANSWERS",
        detail = "Your reflection asks three questions. It already knows which answers are yours.",
        completionMessage = "THE POOL LETS YOU PASS — +2 MIRROR REED",
        failureMessage = "THE REFLECTION TURNS AWAY",
        durationSeconds = 110,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The pool goes blank; the path around it is longer but open.",
        localizationKey = "events.mireglass.three_answers",
        analyticsId = "MireglassThreeAnswers",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = {
            guidance = "Answer each in turn; there is no wrong answer, only a false one.",
        },
        groupVariant = { guidance = "Each may answer, but the pool only counts three." },
        reward = { materialId = "material_mirror_reed", amount = 2 },
        steps = {
            {
                id = "answer_first",
                actionText = "ANSWER",
                objectText = "First Question",
                offset = { x = -5, y = 1.3, z = 0 },
            },
            {
                id = "answer_second",
                actionText = "ANSWER",
                objectText = "Second Question",
                offset = { x = 0, y = 1.3, z = 3 },
            },
            {
                id = "answer_third",
                actionText = "ANSWER",
                objectText = "Third Question",
                offset = { x = 5, y = 1.3, z = 0 },
            },
        },
    }),
    frozenDefinition({
        id = "event_mg_drowned_market",
        displayName = "Drowned Market",
        visual = "drowned_market_event",
        tags = { "story", "resource" },
        objective = "TAKE ONE THING AND LEAVE PAYMENT",
        detail = "The stalls are still stocked, and the fen keeps accounts even when the sellers cannot.",
        completionMessage = "THE ACCOUNT IS SQUARE — +2 BOG IRON",
        failureMessage = "THE STALLS ARE EMPTY WHEN YOU TURN BACK",
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The market stays as it is; nothing follows you for looking.",
        localizationKey = "events.mireglass.drowned_market",
        analyticsId = "MireglassDrownedMarket",
        killSwitchFlag = "mireglass_events_enabled",
        soloVariant = { guidance = "Take one thing, then leave payment on the same hook." },
        groupVariant = { guidance = "One taking, one paying, and nobody takes twice." },
        reward = { materialId = "material_bog_iron", amount = 2 },
        steps = {
            {
                id = "take_goods",
                actionText = "TAKE",
                objectText = "Stall Hook",
                offset = { x = -4, y = 1.5, z = 0 },
            },
            {
                id = "leave_payment",
                actionText = "LEAVE",
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
