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
        displayName = "Glass Orchard",
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
        displayName = "Ash Silk Looms",
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
        displayName = "Kiln Pearl Beds",
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
        displayName = "Coal Terraces",
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
        displayName = "Foundry Yards",
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
        displayName = "Cooling Channel",
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
        displayName = "Collapsed Tiers",
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
        displayName = "Ash Colonnade",
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
        displayName = "Stage Bridges",
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
        displayName = "Procession Stair",
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
        displayName = "Applause Court",
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
        displayName = "Glass Knight Gallery",
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
        displayName = "Parade Giant Plaza",
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
        displayName = "False Citizen Quarter",
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
        displayName = "The Regent's Box",
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
        displayName = "Sculptor's Hall",
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
        displayName = "Regent's Approach",
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
        displayName = "The Last Ovation",
        visual = "last_ovation",
        tags = { "story", "warning" },
        detail = "The crowd in the upper stands, cast where they were "
            .. "standing, every one of them turned to face the stage. "
            .. "Whatever they were watching, they were watching it right "
            .. "up until the end.",
    }),
    frozenDefinition({
        id = "poi_cc_glass_family",
        displayName = "The Glass Family",
        visual = "glass_family",
        tags = { "mystery", "story" },
        detail = "Four figures at a table, and the fourth chair pulled out "
            .. "as though someone had just got up. Nothing here casts a "
            .. "shadow the right way round.",
    }),
    frozenDefinition({
        id = "poi_cc_unfinished_statue",
        displayName = "The Unfinished Statue",
        visual = "unfinished_statue",
        tags = { "mystery", "memory" },
        detail = "Half-carved and abandoned, with the tools left where "
            .. "they fell. It is the only figure in the district nobody "
            .. "could have mistaken for a person.",
    }),
    frozenDefinition({
        id = "poi_cc_regents_chair",
        displayName = "The Regent's Chair",
        visual = "regents_chair",
        tags = { "story", "resident" },
        detail = "Empty, and clean, in a box thick with ash. Something has "
            .. "been sitting in it often enough to keep it that way.",
    }),
    frozenDefinition({
        id = "poi_cc_ash_shadow",
        displayName = "The Ash Shadow",
        visual = "ash_shadow",
        tags = { "story", "warning" },
        detail = "A shape burned into a wall where a body stopped the "
            .. "heat. The posture is unmistakeably someone shielding "
            .. "somebody smaller.",
    }),
    frozenDefinition({
        id = "poi_cc_kiln_still_lit",
        displayName = "The Kiln Still Lit",
        visual = "kiln_still_lit",
        tags = { "resource", "heat" },
        detail = "Coal enough for another century, feeding a fire nobody "
            .. "has fed since. Whatever is coming out of it is still "
            .. "being made.",
    }),
    frozenDefinition({
        id = "poi_cc_false_shopfront",
        displayName = "The False Shopfront",
        visual = "false_shopfront",
        tags = { "mystery", "warning" },
        detail = "A shop with a full window and no door, no counter and no "
            .. "room behind it. The Crown's clearest tell, once you have "
            .. "seen it once.",
    }),
    frozenDefinition({
        id = "poi_cc_crown_mold",
        displayName = "The Crown Mold",
        visual = "crown_mold",
        tags = { "resource", "story" },
        detail = "The mold the ceremonial crown was cast in, cracked in "
            .. "half. Both halves are here, which means the crown left "
            .. "before the fire did.",
    }),
    frozenDefinition({
        id = "poi_cc_name_wall",
        displayName = "The Name Wall",
        visual = "name_wall",
        tags = { "story", "resident" },
        detail = "Official names cut deep and formal. Under each one, "
            .. "scratched small, a second name in a different hand -- "
            .. "the one the person actually went by.",
    }),
    frozenDefinition({
        id = "poi_cc_cooling_pool",
        displayName = "The Cooling Pool",
        visual = "cooling_pool",
        tags = { "resource", "safe" },
        detail = "Channel water still running cold through a district that "
            .. "is still hot. It is the only place in the Crown that is "
            .. "not doing anything.",
    }),
    frozenDefinition({
        id = "poi_cc_understudy",
        displayName = "The Understudy",
        visual = "understudy",
        tags = { "mystery", "story" },
        detail = "A cast of the Regent, in the Regent's costume, standing "
            .. "in the wings. It is a head shorter and the hands are "
            .. "wrong.",
    }),
    frozenDefinition({
        id = "poi_cc_crown_marker",
        displayName = "The Crown Marker",
        visual = "crown_marker",
        tags = { "landmark", "story" },
        detail = "A processional marker pointing the way to the stage, and "
            .. "the only sign in the district that has been repainted "
            .. "recently.",
    }),
}

local events = {
    frozenDefinition({
        id = "event_cc_parade_loop",
        displayName = "Parade Loop",
        visual = "parade_loop",
        tags = { "memory", "urgent" },
        objective = "BREAK THE PROCESSION BEFORE IT COMES ROUND AGAIN",
        detail = "The parade has walked this route a thousand times. It is "
            .. "wearing a groove into the street and everything in the "
            .. "district keeps time to it.",
        completionMessage = "THE PROCESSION BREAKS — +3 MEMORY GLASS",
        failureMessage = "IT COMES ROUND AGAIN",
        durationSeconds = 100,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.cinderfall.parade_loop",
        analyticsId = "CinderfallParadeLoop",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = "Find the one that leads, not the one at the front. They "
                .. "are different.",
        },
        groupVariant = { guidance = "One reads the line while the others take the leader." },
        reward = { materialId = "material_memory_glass", amount = 3 },
        steps = {
            {
                id = "read_line",
                actionText = "READ",
                objectText = "Procession Line",
                offset = { x = -6, y = 1.5, z = -2 },
            },
            {
                id = "mark_leader",
                actionText = "MARK",
                objectText = "The One Leading",
                offset = { x = 4, y = 1.4, z = 3 },
            },
            {
                id = "break_step",
                actionText = "BREAK",
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
        objective = "DECIDE WHICH OF THEM WAS REAL",
        detail = "Four figures, one of them a person the ash caught and "
            .. "three of them casts made afterwards. Only one is worth "
            .. "carrying out.",
        completionMessage = "THE REAL ONE IS CARRIED OUT — +3 ASH SILK",
        failureMessage = "ALL FOUR ARE LEFT WHERE THEY STAND",
        durationSeconds = 110,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.cinderfall.glass_family",
        analyticsId = "CinderfallGlassFamily",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = "Look at the hands. Casts are made from molds and molds " .. "have seams.",
        },
        groupVariant = { guidance = "Split the four; compare before anyone commits." },
        reward = { materialId = "material_ash_silk", amount = 3 },
        steps = {
            {
                id = "read_seams",
                actionText = "READ",
                objectText = "Their Hands",
                offset = { x = -5, y = 1.4, z = 1 },
            },
            {
                id = "lift_true",
                actionText = "LIFT",
                objectText = "The One Without Seams",
                offset = { x = 5, y = 1.3, z = -2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_cc_kiln_restart",
        displayName = "Kiln Restart",
        visual = "kiln_restart",
        tags = { "heat", "risk" },
        objective = "RESTART A KILN WITHOUT FIRING WHAT IS INSIDE IT",
        detail = "The kiln holds a cast that was never finished. "
            .. "Restarting it warms the district; finishing the cast "
            .. "fills it with one more thing that repeats.",
        completionMessage = "THE KILN RUNS COLD — +3 CROWN COAL",
        failureMessage = "THE FIRING COMPLETES",
        durationSeconds = 120,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.cinderfall.kiln_restart",
        analyticsId = "CinderfallKilnRestart",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = "Vent first, then feed. Feeding a sealed kiln is how the "
                .. "cast finishes.",
        },
        groupVariant = { guidance = "One vents while one feeds; do not swap halfway." },
        reward = { materialId = "material_crown_coal", amount = 3 },
        steps = {
            {
                id = "open_vent",
                actionText = "OPEN",
                objectText = "Kiln Vent",
                offset = { x = -7, y = 1.6, z = 0 },
            },
            {
                id = "feed_coal",
                actionText = "FEED",
                objectText = "Coal Chute",
                offset = { x = 6, y = 1.4, z = -3 },
            },
            {
                id = "bank_fire",
                actionText = "BANK",
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
        objective = "GET THE LIVING ONE OUT OF THE CAST",
        detail = "One of the figures on the stage is breathing. The rest "
            .. "of the company will keep performing around them either "
            .. "way.",
        completionMessage = "THEY WALK OUT WITH YOU — +3 CINDERSTEEL",
        failureMessage = "THE PERFORMANCE CONTINUES",
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 22,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.cinderfall.actor_rescue",
        analyticsId = "CinderfallActorRescue",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = "Cut the cast, not the person. The ash is thicker than it " .. "looks.",
        },
        groupVariant = { guidance = "One holds the company's attention while one cuts." },
        reward = { materialId = "material_cindersteel", amount = 3 },
        steps = {
            {
                id = "find_breath",
                actionText = "LISTEN",
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
        objective = "GET UNDER COVER BEFORE THE FALL SETS",
        detail = "Fresh ash falls hot and sets in minutes. Anything still "
            .. "standing in it when it sets becomes another thing that "
            .. "stands here.",
        completionMessage = "THE FALL PASSES OVER YOU — +3 KILN PEARL",
        failureMessage = "THE FALL SETS AROUND YOU",
        durationSeconds = 80,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 24,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.cinderfall.ash_storm",
        analyticsId = "CinderfallAshStorm",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = "Shutter, then shelter. A shelter with the shutters open " .. "is a mold.",
        },
        groupVariant = { guidance = "Shutters are faster shared; shelter together or not at all." },
        reward = { materialId = "material_kiln_pearl", amount = 3 },
        steps = {
            {
                id = "close_shutters",
                actionText = "CLOSE",
                objectText = "Arcade Shutters",
                offset = { x = -8, y = 1.5, z = -1 },
            },
            {
                id = "take_shelter",
                actionText = "SHELTER",
                objectText = "Under the Arcade",
                offset = { x = 6, y = 1.2, z = 4 },
            },
        },
    }),
    frozenDefinition({
        id = "event_cc_false_shop",
        displayName = "False Shop",
        visual = "false_shop",
        tags = { "mystery", "choice" },
        objective = "TELL THE STOCKED SHOP FROM THE REAL ONE",
        detail = "Two shopfronts, both full. One of them has a back room "
            .. "and a ledger; the other has a window and nothing behind "
            .. "it.",
        completionMessage = "THE REAL STOCK COMES WITH YOU — +3 ASH SILK",
        failureMessage = "YOU CARRY OUT A WINDOW",
        durationSeconds = 95,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.cinderfall.false_shop",
        analyticsId = "CinderfallFalseShop",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = "Go round the back. Casts are only made from the side " .. "people saw.",
        },
        groupVariant = { guidance = "One takes each front; meet behind them." },
        reward = { materialId = "material_ash_silk", amount = 3 },
        steps = {
            {
                id = "check_backs",
                actionText = "CHECK",
                objectText = "Behind Both Fronts",
                offset = { x = -6, y = 1.4, z = -3 },
            },
            {
                id = "take_stock",
                actionText = "TAKE",
                objectText = "The Real Stock",
                offset = { x = 6, y = 1.3, z = 2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_cc_cooling_channel",
        displayName = "Cooling Channel",
        visual = "cooling_channel_event",
        tags = { "heat", "puzzle" },
        objective = "PUT THE CHANNEL BACK THROUGH THE DISTRICT",
        detail = "The channel that kept this quarter workable is blocked "
            .. "in three places. Clearing it cools the kilns and stops "
            .. "them making anything else.",
        completionMessage = "THE QUARTER COOLS — +3 CROWN COAL",
        failureMessage = "THE KILNS KEEP THEIR HEAT",
        durationSeconds = 115,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 22,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.cinderfall.cooling_channel",
        analyticsId = "CinderfallCoolingChannel",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = "Upstream first. Clearing downstream only moves the block.",
        },
        groupVariant = { guidance = "Take a block each, but clear them in order." },
        reward = { materialId = "material_crown_coal", amount = 3 },
        steps = {
            {
                id = "clear_upper",
                actionText = "CLEAR",
                objectText = "Upper Block",
                offset = { x = -8, y = 1.4, z = -4 },
            },
            {
                id = "clear_middle",
                actionText = "CLEAR",
                objectText = "Middle Block",
                offset = { x = 0, y = 1.4, z = 5 },
            },
            {
                id = "clear_lower",
                actionText = "CLEAR",
                objectText = "Lower Block",
                offset = { x = 8, y = 1.4, z = -2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_cc_empty_applause",
        displayName = "Empty Applause",
        visual = "empty_applause",
        tags = { "memory", "quiet" },
        objective = "STOP THE COURT APPLAUDING",
        detail = "The applause starts when anyone walks in and does not "
            .. "stop until they leave. Everything in the district that "
            .. "hunts by sound is listening to it.",
        completionMessage = "THE COURT GOES QUIET — +3 MEMORY GLASS",
        failureMessage = "THE APPLAUSE CARRIES",
        durationSeconds = 100,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The chance passes; the marked critical path stays open.",
        localizationKey = "events.cinderfall.empty_applause",
        analyticsId = "CinderfallEmptyApplause",
        killSwitchFlag = "cinderfall_events_enabled",
        soloVariant = {
            guidance = "Find the first pair of hands. The rest are only following it.",
        },
        groupVariant = { guidance = "Spread out; whoever finds the first pair calls it." },
        reward = { materialId = "material_memory_glass", amount = 3 },
        steps = {
            {
                id = "find_first",
                actionText = "FIND",
                objectText = "The First Pair of Hands",
                offset = { x = -5, y = 1.5, z = 3 },
            },
            {
                id = "still_them",
                actionText = "STILL",
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
