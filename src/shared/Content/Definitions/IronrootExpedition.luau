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
local Strings = require("../../Strings")

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
        displayName = Strings.get("expedition.daylight_shaft"),
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
        displayName = Strings.get("expedition.coalglass_seam"),
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
        displayName = Strings.get("expedition.fungus_terrace"),
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
        displayName = Strings.get("expedition.flooded_stope"),
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
        displayName = Strings.get("expedition.abandoned_face"),
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
        displayName = Strings.get("expedition.scaffold_climb"),
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
        displayName = Strings.get("expedition.collapse_scramble"),
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
        displayName = Strings.get("expedition.winch_crossing"),
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
        displayName = Strings.get("expedition.junction_round"),
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
        displayName = Strings.get("expedition.foreman_s_office"),
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
        displayName = Strings.get("expedition.memorial_drift"),
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
        displayName = Strings.get("expedition.bellows_approach"),
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
        detail = Strings.get("expedition.the_lift_cage_came_down_with"),
    }),
    frozenDefinition({
        id = "poi_ir_seam_of_light",
        displayName = Strings.get("expedition.seam_of_light"),
        visual = "seam_of_light",
        tags = { "resource", "mystery" },
        detail = Strings.get("expedition.a_vein_of_coalglass_runs_the"),
    }),
    frozenDefinition({
        id = "poi_ir_tally_wall",
        displayName = "Tally Wall",
        visual = "tally_wall",
        tags = { "story", "resident" },
        detail = Strings.get("expedition.shift_marks_in_chalk_one_column"),
    }),
    frozenDefinition({
        id = "poi_ir_sleeping_engine",
        displayName = Strings.get("expedition.sleeping_engine"),
        visual = "sleeping_engine",
        tags = { "machine", "risk" },
        detail = Strings.get("expedition.the_pump_engine_is_warm_it"),
    }),
    frozenDefinition({
        id = "poi_ir_bell_rope",
        displayName = "Bell Rope",
        visual = "bell_rope",
        tags = { "warning", "mystery" },
        detail = Strings.get("expedition.the_signal_bell_rings_up_shaft"),
    }),
    frozenDefinition({
        id = "poi_ir_glow_garden",
        displayName = "Glow Garden",
        visual = "glow_garden",
        tags = { "resource", "sanctuary" },
        detail = Strings.get("expedition.a_miner_planted_fungus_in_neat"),
    }),
    frozenDefinition({
        id = "poi_ir_lunch_alcove",
        displayName = "Lunch Alcove",
        visual = "lunch_alcove",
        tags = { "story", "resident" },
        detail = Strings.get("expedition.six_lunch_pails_on_a_plank"),
    }),
    frozenDefinition({
        id = "poi_ir_flooded_office",
        displayName = Strings.get("expedition.flooded_office"),
        visual = "flooded_office",
        tags = { "story", "risk" },
        detail = Strings.get("expedition.the_pay_ledger_floats_face_down"),
    }),
    frozenDefinition({
        id = "poi_ir_widow_web",
        displayName = "Widow's Web",
        visual = "widow_web",
        tags = { "warning", "risk" },
        detail = Strings.get("expedition.rail_cable_strung_wall_to_wall"),
    }),
    frozenDefinition({
        id = "poi_ir_ore_cart_train",
        displayName = Strings.get("expedition.ore_cart_train"),
        visual = "ore_cart_train",
        tags = { "machine", "resource" },
        detail = Strings.get("expedition.nine_carts_coupled_and_loaded_brakes"),
    }),
    frozenDefinition({
        id = "poi_ir_echo_shrine",
        displayName = "Echo Shrine",
        visual = "echo_shrine",
        tags = { "mystery", "sanctuary" },
        detail = Strings.get("expedition.crystals_arranged_in_a_ring_that"),
    }),
    frozenDefinition({
        id = "poi_ir_break_room_mural",
        displayName = Strings.get("expedition.break_room_mural"),
        visual = "break_room_mural",
        tags = { "story", "sanctuary" },
        detail = Strings.get("expedition.someone_painted_the_surface_on_the"),
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
        objective = Strings.get("expedition.set_the_three_rail_brakes"),
        detail = Strings.get("expedition.a_loaded_cart_walks_the_grade"),
        completionMessage = "THE CART GRINDS STILL — +3 IRONROOT ORE",
        failureMessage = Strings.get("expedition.the_cart_takes_the_grade"),
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_cart_wrecks_in_a_side"),
        localizationKey = "events.ironroot.runaway_cart",
        analyticsId = "IronrootRunawayCart",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.set_each_brake_as_the_cart"),
        },
        groupVariant = {
            guidance = Strings.get("expedition.take_a_brake_each_and_call"),
        },
        reward = {
            materialId = "material_ironroot_ore",
            amount = 3,
        },
        steps = {
            {
                id = "brake_upper",
                actionText = "SET",
                objectText = Strings.get("expedition.upper_rail_brake"),
                offset = { x = -7, y = 1.2, z = -3 },
            },
            {
                id = "brake_middle",
                actionText = "SET",
                objectText = Strings.get("expedition.middle_rail_brake"),
                offset = { x = 0, y = 1.2, z = 2 },
            },
            {
                id = "brake_lower",
                actionText = "SET",
                objectText = Strings.get("expedition.lower_rail_brake"),
                offset = { x = 7, y = 1.2, z = -3 },
            },
        },
    }),
    frozenDefinition({
        id = "event_ir_gas_leak",
        displayName = "Gas Leak",
        visual = "gas_leak",
        tags = { "hazard", "urgent" },
        objective = Strings.get("expedition.close_both_valves_then_vent_the"),
        detail = Strings.get("expedition.whitedamp_seeps_from_a_cracked_main"),
        completionMessage = "THE AIR CLEARS — +2 MACHINE OIL",
        failureMessage = Strings.get("expedition.the_pocket_fills_and_seals_itself"),
        durationSeconds = 100,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 18,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_drift_seals_behind_an_air"),
        localizationKey = "events.ironroot.gas_leak",
        analyticsId = "IronrootGasLeak",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.valves_in_either_order_then_the"),
        },
        groupVariant = {
            guidance = Strings.get("expedition.split_the_valves_whoever_is_spare"),
        },
        reward = {
            materialId = "material_machine_oil",
            amount = 2,
        },
        steps = {
            {
                id = "valve_north",
                actionText = Strings.get("hud.close"),
                objectText = Strings.get("expedition.north_main_valve"),
                offset = { x = -6, y = 1.4, z = 0 },
            },
            {
                id = "valve_south",
                actionText = Strings.get("hud.close"),
                objectText = Strings.get("expedition.south_main_valve"),
                offset = { x = 6, y = 1.4, z = 0 },
            },
            {
                id = "vent_wheel",
                actionText = Strings.get("expedition.vent"),
                objectText = Strings.get("expedition.pocket_vent_wheel"),
                offset = { x = 0, y = 2, z = 4 },
            },
        },
    }),
    frozenDefinition({
        id = "event_ir_shift_change",
        displayName = "Shift Change",
        visual = "shift_change",
        tags = { "mystery", "story" },
        objective = Strings.get("expedition.ring_the_three_shift_bells_in"),
        detail = Strings.get("expedition.the_mine_still_keeps_its_hours"),
        completionMessage = "THE SHIFT CHANGES — +2 ECHO CRYSTAL",
        failureMessage = Strings.get("expedition.the_old_shift_keeps_working"),
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.echo_activity_thickens_nearby_the_critical"),
        localizationKey = "events.ironroot.shift_change",
        analyticsId = "IronrootShiftChange",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.first_bell_second_bell_third_bell"),
        },
        groupVariant = {
            guidance = Strings.get("expedition.one_bell_each_ring_on_the"),
        },
        reward = {
            materialId = "material_echo_crystal",
            amount = 2,
        },
        steps = {
            {
                id = "bell_first",
                actionText = Strings.get("hud.ring"),
                objectText = Strings.get("expedition.first_shift_bell"),
                offset = { x = -6, y = 1.8, z = 2 },
            },
            {
                id = "bell_second",
                actionText = Strings.get("hud.ring"),
                objectText = Strings.get("expedition.second_shift_bell"),
                offset = { x = 0, y = 1.8, z = -3 },
            },
            {
                id = "bell_third",
                actionText = Strings.get("hud.ring"),
                objectText = Strings.get("expedition.third_shift_bell"),
                offset = { x = 6, y = 1.8, z = 2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_ir_cave_rescue",
        displayName = "Cave Rescue",
        visual = "cave_rescue",
        tags = { "rescue", "urgent" },
        objective = Strings.get("expedition.shore_the_fall_and_dig_the"),
        detail = Strings.get("expedition.a_voice_behind_the_rockfall_faint"),
        completionMessage = "THE MINER IS FREE — +3 GLOW FUNGUS",
        failureMessage = Strings.get("expedition.the_voice_stops_counting"),
        durationSeconds = 120,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 20,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = { "event_ir_bell_warning" },
        failureResolution = Strings.get("expedition.the_voice_is_gone_when_the"),
        localizationKey = "events.ironroot.cave_rescue",
        analyticsId = "IronrootCaveRescue",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.both_props_then_dig_unshored_digging"),
        },
        groupVariant = {
            guidance = Strings.get("expedition.shore_both_sides_at_once_then"),
        },
        reward = {
            materialId = "material_glow_fungus",
            amount = 3,
        },
        steps = {
            {
                id = "prop_left",
                actionText = Strings.get("expedition.shore"),
                objectText = Strings.get("expedition.left_roof_prop"),
                offset = { x = -5, y = 1.6, z = 0 },
            },
            {
                id = "prop_right",
                actionText = Strings.get("expedition.shore"),
                objectText = Strings.get("expedition.right_roof_prop"),
                offset = { x = 5, y = 1.6, z = 0 },
            },
            {
                id = "dig_face",
                actionText = "DIG",
                objectText = Strings.get("expedition.rockfall_face"),
                offset = { x = 0, y = 1.2, z = 3 },
            },
        },
    }),
    frozenDefinition({
        id = "event_ir_machine_vote",
        displayName = "Machine Vote",
        visual = "machine_vote",
        tags = { "choice", "machine" },
        objective = Strings.get("expedition.decide_the_old_engine_s_fate"),
        detail = Strings.get("expedition.the_pump_engine_still_runs_and"),
        completionMessage = "THE DELVE REMEMBERS THE CHOICE — +2 COALGLASS",
        failureMessage = Strings.get("expedition.the_engine_decides_for_itself"),
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_engine_sputters_on_unchanged_the"),
        localizationKey = "events.ironroot.machine_vote",
        analyticsId = "IronrootMachineVote",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.read_the_gauge_then_commit_feed"),
        },
        groupVariant = {
            guidance = Strings.get("expedition.talk_it_over_the_lever_moves"),
        },
        reward = {
            materialId = "material_coalglass",
            amount = 2,
        },
        steps = {
            {
                id = "read_gauge",
                actionText = Strings.get("expedition.read"),
                objectText = "Boiler Gauge",
                offset = { x = -4, y = 1.6, z = 0 },
            },
            {
                id = "commit_lever",
                actionText = Strings.get("expedition.pull"),
                objectText = Strings.get("expedition.commitment_lever"),
                offset = { x = 4, y = 1.4, z = 0 },
            },
        },
    }),
    frozenDefinition({
        id = "event_ir_lost_lunchbox",
        displayName = Strings.get("expedition.lost_lunchbox"),
        visual = "lost_lunchbox",
        tags = { "story", "gentle" },
        objective = Strings.get("expedition.carry_the_lunchbox_to_the_tally"),
        detail = Strings.get("expedition.a_wrapped_lunch_pail_still_heavy"),
        completionMessage = "THE COLUMN IS COMPLETE — +2 GLOW FUNGUS",
        failureMessage = Strings.get("expedition.the_pail_stays_where_it_was"),
        durationSeconds = 90,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_pail_waits_grief_keeps"),
        localizationKey = "events.ironroot.lost_lunchbox",
        analyticsId = "IronrootLostLunchbox",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.pick_it_up_walk_it_there"),
        },
        groupVariant = {
            guidance = Strings.get("expedition.one_carries_the_others_keep_the"),
        },
        reward = {
            materialId = "material_glow_fungus",
            amount = 2,
        },
        steps = {
            {
                id = "take_pail",
                actionText = Strings.get("expedition.carry"),
                objectText = Strings.get("expedition.wrapped_lunch_pail"),
                offset = { x = -5, y = 1.2, z = 0 },
            },
            {
                id = "set_pail",
                actionText = Strings.get("world.place"),
                objectText = Strings.get("expedition.tally_wall_ledge"),
                offset = { x = 5, y = 1.4, z = 2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_ir_fungus_bloom",
        displayName = "Fungus Bloom",
        visual = "fungus_bloom",
        tags = { "resource", "timed" },
        objective = Strings.get("expedition.harvest_the_bloom_before_it_closes"),
        detail = Strings.get("expedition.once_a_season_the_glow_fungus"),
        completionMessage = "THE BLOOM IS GATHERED — +4 GLOW FUNGUS",
        failureMessage = Strings.get("expedition.the_bloom_folds_back_into_the"),
        durationSeconds = 75,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = {},
        failureResolution = Strings.get("expedition.the_caps_close_the_colony_keeps"),
        localizationKey = "events.ironroot.fungus_bloom",
        analyticsId = "IronrootFungusBloom",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.cut_the_three_brightest_caps_leave"),
        },
        groupVariant = {
            guidance = Strings.get("expedition.spread_out_a_cap_each_before"),
        },
        reward = {
            materialId = "material_glow_fungus",
            amount = 4,
        },
        steps = {
            {
                id = "cap_east",
                actionText = "CUT",
                objectText = Strings.get("expedition.east_bright_cap"),
                offset = { x = 6, y = 1, z = -2 },
            },
            {
                id = "cap_center",
                actionText = "CUT",
                objectText = Strings.get("expedition.center_bright_cap"),
                offset = { x = 0, y = 1, z = 3 },
            },
            {
                id = "cap_west",
                actionText = "CUT",
                objectText = Strings.get("expedition.west_bright_cap"),
                offset = { x = -6, y = 1, z = -2 },
            },
        },
    }),
    frozenDefinition({
        id = "event_ir_bell_warning",
        displayName = "Bell Warning",
        visual = "bell_warning",
        tags = { "warning", "urgent" },
        objective = Strings.get("expedition.answer_the_up_shaft_bell"),
        detail = Strings.get("expedition.three_rings_from_above_the_old"),
        completionMessage = "THE WARNING IS ANSWERED — +2 IRONROOT ORE",
        failureMessage = Strings.get("expedition.the_bell_goes_quiet_mid_ring"),
        durationSeconds = 80,
        defaultSolution = true,
        criticalPathBlocking = false,
        minimumRouteSpace = 16,
        startConditions = { "player_in_expedition", "interaction_in_range" },
        incompatibleEvents = { "event_ir_cave_rescue" },
        failureResolution = Strings.get("expedition.loose_ground_settles_harmlessly_this_time"),
        localizationKey = "events.ironroot.bell_warning",
        analyticsId = "IronrootBellWarning",
        killSwitchFlag = "ironroot_events_enabled",
        soloVariant = {
            guidance = Strings.get("expedition.answer_on_the_rope_then_brace"),
        },
        groupVariant = {
            guidance = Strings.get("expedition.one_answers_the_rest_brace_the"),
        },
        reward = {
            materialId = "material_ironroot_ore",
            amount = 2,
        },
        steps = {
            {
                id = "answer_rope",
                actionText = Strings.get("expedition.pull"),
                objectText = Strings.get("expedition.signal_bell_rope"),
                offset = { x = 0, y = 2, z = -3 },
            },
            {
                id = "brace_props",
                actionText = Strings.get("expedition.brace"),
                objectText = Strings.get("expedition.drift_prop_line"),
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
        The two fragment-anchored POIs place in every run, Bramblewake's
        rule applied here the day the region opened: a memory fragment
        whose anchor only turns up some runs is a story beat demoted to
        a lottery ticket.
    ]]
    FixedPointOfInterestIds = table.freeze({
        "poi_ir_tally_wall",
        "poi_ir_crushed_cage",
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
