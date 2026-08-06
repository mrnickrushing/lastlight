--!strict

--[[
    Ironroot Delve -- chapter II's region, and the first proof that a
    region is a catalog, not a rebuild. Same definition shapes as
    Bramblewake, consumed by the same generator through its region seam.

    The Delve is a worked mine the forest grew back into: shored tunnels,
    rail spurs, breathing shafts, and machinery that never got the order
    to stop. Where Bramblewake's traversal is thicket and root, the
    Delve's is grade and dark -- inclines, laddered scaffolds, rail walks,
    and stretches where the glow fungus is the only light. No module here
    is a reskin of a forest one: the hazards are slag, gas, and falling
    ground, and the resources are pulled from seams, not tapped from
    trees.
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
    Thirty modules: one arrival, one extraction, twenty-eight middle in
    the same role distribution Bramblewake proved (7 resource, 6
    traversal, 5 combat, 4 connector, 3 story, 2 puzzle, 1 landmark).
    Budgets stay inside the regional ceilings for any twelve-module walk:
    parts <= 52 each, and no more than four modules carry 3 lights or 3
    effects so the worst selection still clears 32.
]]
local modules = {
    frozenDefinition({
        id = "module_ir_delve_gate",
        displayName = "Delve Gate",
        role = "arrival",
        visual = "delve_gate",
        tags = { "safe", "connector", "arrival" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 24,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_ir_daylight_shaft",
        displayName = "Daylight Shaft",
        role = "extraction",
        visual = "daylight_shaft",
        tags = { "safe", "extraction" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 26,
        lightBudget = 2,
        effectBudget = 1,
    }),
    -- Resource seams: what the Delve is for.
    frozenDefinition({
        id = "module_ir_ore_gallery",
        displayName = "Ore Gallery",
        role = "resource",
        visual = "ore_gallery",
        tags = { "resource", "mine" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 46,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_ir_coalglass_seam",
        displayName = "Coalglass Seam",
        role = "resource",
        visual = "coalglass_seam",
        tags = { "resource", "risk" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_ir_fungus_terrace",
        displayName = "Fungus Terrace",
        role = "resource",
        visual = "fungus_terrace",
        tags = { "resource", "safe" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 3,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_ir_oil_works",
        displayName = "Oil Works",
        role = "resource",
        visual = "oil_works",
        tags = { "resource", "machine" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 48,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_ir_echo_vault",
        displayName = "Echo Vault",
        role = "resource",
        visual = "echo_vault",
        tags = { "resource", "mystery" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_ir_flooded_stope",
        displayName = "Flooded Stope",
        role = "resource",
        visual = "flooded_stope",
        tags = { "resource", "risk" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_ir_abandoned_face",
        displayName = "Abandoned Face",
        role = "resource",
        visual = "abandoned_face",
        tags = { "resource", "story" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 2,
    }),
    -- Traversal: grade and dark, not thicket and root.
    frozenDefinition({
        id = "module_ir_main_incline",
        displayName = "Main Incline",
        role = "traversal",
        visual = "main_incline",
        tags = { "traversal", "mine" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_ir_scaffold_climb",
        displayName = "Scaffold Climb",
        role = "traversal",
        visual = "scaffold_climb",
        tags = { "traversal", "risk" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 46,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_ir_rail_walk",
        displayName = "Rail Walk",
        role = "traversal",
        visual = "rail_walk",
        tags = { "traversal", "machine" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_ir_dark_stretch",
        displayName = "Dark Stretch",
        role = "traversal",
        visual = "dark_stretch",
        tags = { "traversal", "dark" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 36,
        lightBudget = 1,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_ir_collapse_scramble",
        displayName = "Collapse Scramble",
        role = "traversal",
        visual = "collapse_scramble",
        tags = { "traversal", "risk" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 46,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_ir_winch_crossing",
        displayName = "Winch Crossing",
        role = "traversal",
        visual = "winch_crossing",
        tags = { "traversal", "machine" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 48,
        lightBudget = 2,
        effectBudget = 2,
    }),
    -- Combat chambers.
    frozenDefinition({
        id = "module_ir_mite_nest",
        displayName = "Mite Nest",
        role = "combat",
        visual = "mite_nest",
        tags = { "combat", "risk" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_ir_slag_channel",
        displayName = "Slag Channel",
        role = "combat",
        visual = "slag_channel",
        tags = { "combat", "hazard" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 46,
        lightBudget = 3,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_ir_guard_round",
        displayName = "Guard Round",
        role = "combat",
        visual = "guard_round",
        tags = { "combat", "machine" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_ir_gas_pocket",
        displayName = "Gas Pocket",
        role = "combat",
        visual = "gas_pocket",
        tags = { "combat", "hazard" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 3,
    }),
    frozenDefinition({
        id = "module_ir_echo_gallery",
        displayName = "Echo Gallery",
        role = "combat",
        visual = "echo_gallery",
        tags = { "combat", "mystery" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 42,
        lightBudget = 2,
        effectBudget = 2,
    }),
    -- Connectors: the worked arteries between chambers.
    frozenDefinition({
        id = "module_ir_shored_drift",
        displayName = "Shored Drift",
        role = "connector",
        visual = "shored_drift",
        tags = { "connector", "safe" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 30,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_ir_junction_round",
        displayName = "Junction Round",
        role = "connector",
        visual = "junction_round",
        tags = { "connector", "safe" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 32,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_ir_rail_siding",
        displayName = "Rail Siding",
        role = "connector",
        visual = "rail_siding",
        tags = { "connector", "machine" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 34,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_ir_air_door",
        displayName = "Air Door",
        role = "connector",
        visual = "air_door",
        tags = { "connector", "safe" },
        poiSocket = false,
        eventSocket = true,
        partBudget = 28,
        lightBudget = 2,
        effectBudget = 1,
    }),
    -- Story rooms.
    frozenDefinition({
        id = "module_ir_foreman_office",
        displayName = "Foreman's Office",
        role = "story",
        visual = "foreman_office",
        tags = { "story", "resident" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_ir_miners_rest",
        displayName = "Miners' Rest",
        role = "story",
        visual = "miners_rest",
        tags = { "story", "safe" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 38,
        lightBudget = 3,
        effectBudget = 1,
    }),
    frozenDefinition({
        id = "module_ir_memorial_drift",
        displayName = "Memorial Drift",
        role = "story",
        visual = "memorial_drift",
        tags = { "story", "sanctuary" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 36,
        lightBudget = 2,
        effectBudget = 2,
    }),
    -- Puzzle rooms.
    frozenDefinition({
        id = "module_ir_signal_room",
        displayName = "Signal Room",
        role = "puzzle",
        visual = "signal_room",
        tags = { "puzzle", "machine" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 40,
        lightBudget = 2,
        effectBudget = 2,
    }),
    frozenDefinition({
        id = "module_ir_flood_locks",
        displayName = "Flood Locks",
        role = "puzzle",
        visual = "flood_locks",
        tags = { "puzzle", "risk" },
        poiSocket = true,
        eventSocket = true,
        partBudget = 44,
        lightBudget = 2,
        effectBudget = 2,
    }),
    -- The landmark and required approach: where the Bellows Maw waits.
    frozenDefinition({
        id = "module_ir_bellows_approach",
        displayName = "Bellows Approach",
        role = "landmark",
        visual = "bellows_approach",
        tags = { "landmark", "boss", "story" },
        poiSocket = false,
        eventSocket = false,
        partBudget = 50,
        lightBudget = 3,
        effectBudget = 3,
    }),
}

local pointsOfInterest = {
    frozenDefinition({
        id = "poi_ir_crushed_cage",
        displayName = "Crushed Cage",
        visual = "crushed_cage",
        tags = { "story", "warning" },
        detail = "The lift cage came down with the brake handle still tied "
            .. "open. Nobody untied it afterward.",
    }),
    frozenDefinition({
        id = "poi_ir_seam_of_light",
        displayName = "Seam of Light",
        visual = "seam_of_light",
        tags = { "resource", "mystery" },
        detail = "A vein of coalglass runs the full height of the wall, "
            .. "glowing faintly without any flame near it.",
    }),
    frozenDefinition({
        id = "poi_ir_tally_wall",
        displayName = "Tally Wall",
        visual = "tally_wall",
        tags = { "story", "resident" },
        detail = "Shift marks in chalk, one column per name. Every column "
            .. "stops on the same day except one, which stops a week later.",
    }),
    frozenDefinition({
        id = "poi_ir_sleeping_engine",
        displayName = "Sleeping Engine",
        visual = "sleeping_engine",
        tags = { "machine", "risk" },
        detail = "The pump engine is warm. It has been warm for years. "
            .. "Nothing feeds it that anyone can find.",
    }),
    frozenDefinition({
        id = "poi_ir_bell_rope",
        displayName = "Bell Rope",
        visual = "bell_rope",
        tags = { "warning", "mystery" },
        detail = "The signal bell rings up-shaft when the rope is pulled. "
            .. "Sometimes it rings without the rope moving at all.",
    }),
    frozenDefinition({
        id = "poi_ir_glow_garden",
        displayName = "Glow Garden",
        visual = "glow_garden",
        tags = { "resource", "sanctuary" },
        detail = "A miner planted fungus in neat rows and tended them. The "
            .. "rows have kept themselves neat since.",
    }),
    frozenDefinition({
        id = "poi_ir_lunch_alcove",
        displayName = "Lunch Alcove",
        visual = "lunch_alcove",
        tags = { "story", "resident" },
        detail = "Six lunch pails on a plank, five opened and finished. "
            .. "The sixth is still wrapped, still waiting.",
    }),
    frozenDefinition({
        id = "poi_ir_flooded_office",
        displayName = "Flooded Office",
        visual = "flooded_office",
        tags = { "story", "risk" },
        detail = "The pay ledger floats face-down. The safe under the desk "
            .. "is open, and it was not forced.",
    }),
    frozenDefinition({
        id = "poi_ir_widow_web",
        displayName = "Widow's Web",
        visual = "widow_web",
        tags = { "warning", "risk" },
        detail = "Rail cable strung wall to wall in patterns no rigger "
            .. "would choose. Something rides these lines at night.",
    }),
    frozenDefinition({
        id = "poi_ir_ore_cart_train",
        displayName = "Ore Cart Train",
        visual = "ore_cart_train",
        tags = { "machine", "resource" },
        detail = "Nine carts coupled and loaded, brakes set, pointed at "
            .. "the surface. The tenth coupling hangs open.",
    }),
    frozenDefinition({
        id = "poi_ir_echo_shrine",
        displayName = "Echo Shrine",
        visual = "echo_shrine",
        tags = { "mystery", "sanctuary" },
        detail = "Crystals arranged in a ring that hums your own footsteps "
            .. "back to you, a half-second late and a half-tone low.",
    }),
    frozenDefinition({
        id = "poi_ir_break_room_mural",
        displayName = "Break Room Mural",
        visual = "break_room_mural",
        tags = { "story", "sanctuary" },
        detail = "Someone painted the surface on the break room wall: sky, "
            .. "meadow, the town. The proportions are from memory, and wrong.",
    }),
}

--[[
    The eight events carry the ids the content catalog reserved for the
    Delve. Rewards pay in the Delve's own materials -- ore, coalglass,
    fungus, oil, crystal -- which join the expedition inventory allow-list
    in the same change that adds this file.
]]
local events = {
    frozenDefinition({
        id = "event_ir_runaway_cart",
        displayName = "Runaway Cart",
        visual = "runaway_cart",
        tags = { "machine", "hazard" },
        objective = "SET THE THREE RAIL BRAKES",
        detail = "A loaded cart walks the grade on its own. Brake the rails before it finds speed.",
        completionMessage = "THE CART GRINDS STILL — +3 IRONROOT ORE",
        failureMessage = "THE CART TAKES THE GRADE",
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The cart wrecks in a side drift; the marked critical path stays open.",
        localizationKey = "events.ironroot.runaway_cart",
        analyticsId = "IronrootRunawayCart",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = "Set each brake as the cart passes; it circles the loop.",
        },
        groupVariant = {
            guidance = "Take a brake each and call the cart's position.",
        },
        reward = {
            materialId = "material_ironroot_ore",
            amount = 3,
        },
        steps = {
            {
                id = "brake_upper",
                actionText = "SET",
                objectText = "Upper Rail Brake",
                offset = { x = -7, y = 1.2, z = -3 },
            },
            {
                id = "brake_middle",
                actionText = "SET",
                objectText = "Middle Rail Brake",
                offset = { x = 0, y = 1.2, z = 2 },
            },
            {
                id = "brake_lower",
                actionText = "SET",
                objectText = "Lower Rail Brake",
                offset = { x = 7, y = 1.2, z = -3 },
            },
        },
    }),
    frozenDefinition({
        id = "event_ir_gas_leak",
        displayName = "Gas Leak",
        visual = "gas_leak",
        tags = { "hazard", "urgent" },
        objective = "CLOSE BOTH VALVES, THEN VENT THE POCKET",
        detail = "Whitedamp seeps from a cracked main. The valves first; a spark later would be worse.",
        completionMessage = "THE AIR CLEARS — +2 MACHINE OIL",
        failureMessage = "THE POCKET FILLS AND SEALS ITSELF",
        durationSeconds = 100,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The drift seals behind an air door; no route or resident is lost.",
        localizationKey = "events.ironroot.gas_leak",
        analyticsId = "IronrootGasLeak",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = "Valves in either order, then the vent wheel.",
        },
        groupVariant = {
            guidance = "Split the valves; whoever is spare stands ready at the vent.",
        },
        reward = {
            materialId = "material_machine_oil",
            amount = 2,
        },
        steps = {
            {
                id = "valve_north",
                actionText = "CLOSE",
                objectText = "North Main Valve",
                offset = { x = -6, y = 1.4, z = 0 },
            },
            {
                id = "valve_south",
                actionText = "CLOSE",
                objectText = "South Main Valve",
                offset = { x = 6, y = 1.4, z = 0 },
            },
            {
                id = "vent_wheel",
                actionText = "VENT",
                objectText = "Pocket Vent Wheel",
                offset = { x = 0, y = 2, z = 4 },
            },
        },
    }),
    frozenDefinition({
        id = "event_ir_shift_change",
        displayName = "Shift Change",
        visual = "shift_change",
        tags = { "mystery", "story" },
        objective = "RING THE THREE SHIFT BELLS IN ORDER",
        detail = "The mine still keeps its hours. Ring the change and whatever walks the old "
            .. "shift will walk it somewhere else.",
        completionMessage = "THE SHIFT CHANGES — +2 ECHO CRYSTAL",
        failureMessage = "THE OLD SHIFT KEEPS WORKING",
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "Echo activity thickens nearby; the critical path stays open.",
        localizationKey = "events.ironroot.shift_change",
        analyticsId = "IronrootShiftChange",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = "First bell, second bell, third bell — the order is painted on the posts.",
        },
        groupVariant = {
            guidance = "One bell each; ring on the count.",
        },
        reward = {
            materialId = "material_echo_crystal",
            amount = 2,
        },
        steps = {
            {
                id = "bell_first",
                actionText = "RING",
                objectText = "First Shift Bell",
                offset = { x = -6, y = 1.8, z = 2 },
            },
            {
                id = "bell_second",
                actionText = "RING",
                objectText = "Second Shift Bell",
                offset = { x = 0, y = 1.8, z = -3 },
            },
            {
                id = "bell_third",
                actionText = "RING",
                objectText = "Third Shift Bell",
                offset = { x = 6, y = 1.8, z = 2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_ir_cave_rescue",
        displayName = "Cave Rescue",
        visual = "cave_rescue",
        tags = { "rescue", "urgent" },
        objective = "SHORE THE FALL AND DIG THE MINER OUT",
        detail = "A voice behind the rockfall, faint but counting steadily. Shore first; dig second.",
        completionMessage = "THE MINER IS FREE — +3 GLOW FUNGUS",
        failureMessage = "THE VOICE STOPS COUNTING",
        durationSeconds = 120,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = { "event_ir_bell_warning" },
        failureResolution = "The voice is gone when the stones move; nothing is found behind them.",
        localizationKey = "events.ironroot.cave_rescue",
        analyticsId = "IronrootCaveRescue",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = "Both props, then dig — unshored digging brings the roof down.",
        },
        groupVariant = {
            guidance = "Shore both sides at once, then dig together.",
        },
        reward = {
            materialId = "material_glow_fungus",
            amount = 3,
        },
        steps = {
            {
                id = "prop_left",
                actionText = "SHORE",
                objectText = "Left Roof Prop",
                offset = { x = -5, y = 1.6, z = 0 },
            },
            {
                id = "prop_right",
                actionText = "SHORE",
                objectText = "Right Roof Prop",
                offset = { x = 5, y = 1.6, z = 0 },
            },
            {
                id = "dig_face",
                actionText = "DIG",
                objectText = "Rockfall Face",
                offset = { x = 0, y = 1.2, z = 3 },
            },
        },
    }),
    frozenDefinition({
        id = "event_ir_machine_vote",
        displayName = "Machine Vote",
        visual = "machine_vote",
        tags = { "choice", "machine" },
        objective = "DECIDE THE OLD ENGINE'S FATE",
        detail = "The pump engine still runs, and still drains the lower drifts. Feed it oil to "
            .. "keep them dry, or pull its flywheel and let the water have what it wants.",
        completionMessage = "THE DELVE REMEMBERS THE CHOICE — +2 COALGLASS",
        failureMessage = "THE ENGINE DECIDES FOR ITSELF",
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The engine sputters on unchanged; the choice returns another run.",
        localizationKey = "events.ironroot.machine_vote",
        analyticsId = "IronrootMachineVote",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = "Read the gauge, then commit — feed it or still it.",
        },
        groupVariant = {
            guidance = "Talk it over; the lever moves once.",
        },
        reward = {
            materialId = "material_coalglass",
            amount = 2,
        },
        steps = {
            {
                id = "read_gauge",
                actionText = "READ",
                objectText = "Boiler Gauge",
                offset = { x = -4, y = 1.6, z = 0 },
            },
            {
                id = "commit_lever",
                actionText = "PULL",
                objectText = "Commitment Lever",
                offset = { x = 4, y = 1.4, z = 0 },
            },
        },
    }),
    frozenDefinition({
        id = "event_ir_lost_lunchbox",
        displayName = "Lost Lunchbox",
        visual = "lost_lunchbox",
        tags = { "story", "gentle" },
        objective = "CARRY THE LUNCHBOX TO THE TALLY WALL",
        detail = "A wrapped lunch pail, still heavy, with a name scratched on the lid. Someone's "
            .. "column on the tally wall never got its last mark.",
        completionMessage = "THE COLUMN IS COMPLETE — +2 GLOW FUNGUS",
        failureMessage = "THE PAIL STAYS WHERE IT WAS LEFT",
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The pail waits; grief keeps.",
        localizationKey = "events.ironroot.lost_lunchbox",
        analyticsId = "IronrootLostLunchbox",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = "Pick it up, walk it there, set it down gently.",
        },
        groupVariant = {
            guidance = "One carries; the others keep the way lit.",
        },
        reward = {
            materialId = "material_glow_fungus",
            amount = 2,
        },
        steps = {
            {
                id = "take_pail",
                actionText = "CARRY",
                objectText = "Wrapped Lunch Pail",
                offset = { x = -5, y = 1.2, z = 0 },
            },
            {
                id = "set_pail",
                actionText = "PLACE",
                objectText = "Tally Wall Ledge",
                offset = { x = 5, y = 1.4, z = 2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_ir_fungus_bloom",
        displayName = "Fungus Bloom",
        visual = "fungus_bloom",
        tags = { "resource", "timed" },
        objective = "HARVEST THE BLOOM BEFORE IT CLOSES",
        detail = "Once a season the glow fungus fruits all at once and the dark goes soft. "
            .. "It does not wait for stragglers.",
        completionMessage = "THE BLOOM IS GATHERED — +4 GLOW FUNGUS",
        failureMessage = "THE BLOOM FOLDS BACK INTO THE DARK",
        durationSeconds = 75,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = "The caps close; the colony keeps its light another season.",
        localizationKey = "events.ironroot.fungus_bloom",
        analyticsId = "IronrootFungusBloom",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = "Cut the three brightest caps; leave the rest to seed.",
        },
        groupVariant = {
            guidance = "Spread out — a cap each before the fold.",
        },
        reward = {
            materialId = "material_glow_fungus",
            amount = 4,
        },
        steps = {
            {
                id = "cap_east",
                actionText = "CUT",
                objectText = "East Bright Cap",
                offset = { x = 6, y = 1, z = -2 },
            },
            {
                id = "cap_center",
                actionText = "CUT",
                objectText = "Center Bright Cap",
                offset = { x = 0, y = 1, z = 3 },
            },
            {
                id = "cap_west",
                actionText = "CUT",
                objectText = "West Bright Cap",
                offset = { x = -6, y = 1, z = -2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_ir_bell_warning",
        displayName = "Bell Warning",
        visual = "bell_warning",
        tags = { "warning", "urgent" },
        objective = "ANSWER THE UP-SHAFT BELL",
        detail = "Three rings from above: the old signal for GET OUT. The bell has been right "
            .. "before. Answer it, and brace what it warned about.",
        completionMessage = "THE WARNING IS ANSWERED — +2 IRONROOT ORE",
        failureMessage = "THE BELL GOES QUIET MID-RING",
        durationSeconds = 80,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = { "event_ir_cave_rescue" },
        failureResolution = "Loose ground settles harmlessly this time; the bell remembers.",
        localizationKey = "events.ironroot.bell_warning",
        analyticsId = "IronrootBellWarning",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = "Answer on the rope, then brace the nearest prop line.",
        },
        groupVariant = {
            guidance = "One answers; the rest brace the props before the count ends.",
        },
        reward = {
            materialId = "material_ironroot_ore",
            amount = 2,
        },
        steps = {
            {
                id = "answer_rope",
                actionText = "PULL",
                objectText = "Signal Bell Rope",
                offset = { x = 0, y = 2, z = -3 },
            },
            {
                id = "brace_props",
                actionText = "BRACE",
                objectText = "Drift Prop Line",
                offset = { x = 4, y = 1.5, z = 3 },
            },
        },
    }),
}

local eventInteractionCount = 0
for _, definition in events do
    eventInteractionCount += #definition.steps
end

return table.freeze({
    RegionId = "region_ironroot",
    Version = 1,
    CellSize = 72,
    ModuleCount = 12,
    PointOfInterestCount = 4,
    EventCount = 8,
    EventInteractionCount = eventInteractionCount,
    -- Same planning-budget semantics as Bramblewake: PartBudget bounds the
    -- MANIFEST (sum of chosen modules' allowances), not built parts. The
    -- Delve has no built-part measurement yet -- that number arrives with
    -- its builder, from a Studio capture, not from here.
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
        "module_ir_bellows_approach",
    }),
    --[[
        The known-good fallback's middle, in authored order: a walk that
        touches every required tag, keeps the puzzle and landmark stops,
        and stays well inside every budget. Until a live session proves
        generated Delve walks, this is also the manifest specs replay.
    ]]
    FixedMiddleIds = table.freeze({
        "module_ir_shored_drift",
        "module_ir_ore_gallery",
        "module_ir_main_incline",
        "module_ir_mite_nest",
        "module_ir_fungus_terrace",
        "module_ir_signal_room",
        "module_ir_scaffold_climb",
        "module_ir_miners_rest",
        "module_ir_guard_round",
        "module_ir_bellows_approach",
    }),
    Modules = table.freeze(modules),
    PointsOfInterest = table.freeze(pointsOfInterest),
    Events = table.freeze(events),
})
