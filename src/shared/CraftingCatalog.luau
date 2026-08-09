--!strict

local Strings = require("./Strings")

local CraftingCatalog = {}

export type Recipe = {
    id: string,
    displayName: string,
    outputItemId: string,
    outputDisplayName: string,
    materials: { [string]: number },
}

local ORDER = table.freeze({
    "recipe_meadow_satchel",
    "recipe_amber_charm",
    "recipe_ironroot_hood",
    "recipe_bramble_boots",
    "recipe_thornwood_bow",
    "recipe_heartwood_maul",
    "recipe_briar_lance",
    "recipe_foxfire_sling",
    "recipe_amber_edge",
    "recipe_warden_cudgel",
    -- Bramblewake's other eight armour pieces
    "recipe_meadow_cowl",
    "recipe_bramble_treads",
    "recipe_meadow_coat",
    "recipe_bark_plate",
    "recipe_meadow_wraps",
    "recipe_bramble_gauntlets",
    "recipe_foxfire_token",
    "recipe_heartwood_seal",
    -- The things that are used rather than worn
    "recipe_delve_ration",
    "recipe_coalglass_ward",
    "recipe_reed_tonic",
    "recipe_mirror_ward",
    "recipe_fen_poultice",
    "recipe_storm_ration",
    "recipe_amberglass_ward",
    "recipe_reach_poultice",
    "recipe_ember_ration",
    "recipe_rime_ward",
    "recipe_vale_poultice",
    "recipe_kiln_ration",
    "recipe_cindersteel_ward",
    "recipe_crown_poultice",
    "recipe_meadow_lantern_oil",
    "recipe_meadow_clearwater",
    "recipe_meadow_mending_kit",
    "recipe_delve_lantern_oil",
    "recipe_delve_clearwater",
    "recipe_delve_mending_kit",
    "recipe_fen_lantern_oil",
    "recipe_fen_clearwater",
    "recipe_fen_mending_kit",
    "recipe_reach_lantern_oil",
    "recipe_reach_clearwater",
    "recipe_reach_mending_kit",
    "recipe_vale_lantern_oil",
    "recipe_vale_clearwater",
    "recipe_vale_mending_kit",
    "recipe_crown_lantern_oil",
    "recipe_crown_clearwater",
    "recipe_crown_mending_kit",
    "recipe_stope_bow",
    "recipe_drift_maul",
    "recipe_pit_lance",
    "recipe_slag_sling",
    "recipe_coalglass_edge",
    "recipe_shift_cudgel",
    "recipe_ironroot_cowl",
    "recipe_ironroot_helm",
    "recipe_ironroot_coat",
    "recipe_ironroot_plate",
    "recipe_ironroot_wraps",
    "recipe_ironroot_gauntlets",
    "recipe_ironroot_boots",
    "recipe_ironroot_treads",
    "recipe_ironroot_token",
    "recipe_ironroot_seal",
    "recipe_reed_bow",
    "recipe_bog_maul",
    "recipe_punt_lance",
    "recipe_mirror_sling",
    "recipe_witchlight_edge",
    "recipe_ferry_cudgel",
    "recipe_mireglass_cowl",
    "recipe_mireglass_helm",
    "recipe_mireglass_coat",
    "recipe_mireglass_plate",
    "recipe_mireglass_wraps",
    "recipe_mireglass_gauntlets",
    "recipe_mireglass_boots",
    "recipe_mireglass_treads",
    "recipe_mireglass_token",
    "recipe_mireglass_seal",
    "recipe_jetty_bow",
    "recipe_ballast_maul",
    "recipe_gaff_lance",
    "recipe_halyard_sling",
    "recipe_amberglass_edge",
    "recipe_breakwater_cudgel",
    "recipe_tempest_cowl",
    "recipe_tempest_helm",
    "recipe_tempest_coat",
    "recipe_tempest_plate",
    "recipe_tempest_wraps",
    "recipe_tempest_gauntlets",
    "recipe_tempest_boots",
    "recipe_tempest_treads",
    "recipe_tempest_token",
    "recipe_tempest_seal",
    "recipe_vale_bow",
    "recipe_thaw_maul",
    "recipe_crevasse_lance",
    "recipe_hush_sling",
    "recipe_rime_edge",
    "recipe_cloister_cudgel",
    "recipe_frostmere_cowl",
    "recipe_frostmere_helm",
    "recipe_frostmere_coat",
    "recipe_frostmere_plate",
    "recipe_frostmere_wraps",
    "recipe_frostmere_gauntlets",
    "recipe_frostmere_boots",
    "recipe_frostmere_treads",
    "recipe_frostmere_token",
    "recipe_frostmere_seal",
    "recipe_tier_bow",
    "recipe_kiln_maul",
    "recipe_procession_lance",
    "recipe_cinder_sling",
    "recipe_memory_edge",
    "recipe_bailiff_cudgel",
    "recipe_cinderfall_cowl",
    "recipe_cinderfall_helm",
    "recipe_cinderfall_coat",
    "recipe_cinderfall_plate",
    "recipe_cinderfall_wraps",
    "recipe_cinderfall_gauntlets",
    "recipe_cinderfall_boots",
    "recipe_cinderfall_treads",
    "recipe_cinderfall_token",
    "recipe_cinderfall_seal",
})

local DEFINITIONS: { [string]: Recipe } = {
    recipe_meadow_satchel = table.freeze({
        id = "recipe_meadow_satchel",
        displayName = Strings.get("world.meadow_satchel"),
        outputItemId = "gear_meadow_satchel",
        outputDisplayName = Strings.get("item.meadow_satchel"),
        materials = table.freeze({
            material_meadow_fiber = 3,
            material_heartwood = 2,
        }),
    }),
    recipe_amber_charm = table.freeze({
        id = "recipe_amber_charm",
        displayName = Strings.get("world.amber_charm"),
        outputItemId = "gear_amber_charm",
        outputDisplayName = "Amber Charm",
        materials = table.freeze({
            material_amber_sap = 2,
            material_brightcap = 2,
        }),
    }),
    recipe_ironroot_hood = table.freeze({
        id = "recipe_ironroot_hood",
        displayName = Strings.get("world.ironroot_hood"),
        outputItemId = "gear_ironroot_hood",
        outputDisplayName = Strings.get("item.ironroot_hood"),
        materials = table.freeze({
            material_heartwood = 5,
            material_amber_sap = 3,
        }),
    }),
    recipe_bramble_boots = table.freeze({
        id = "recipe_bramble_boots",
        displayName = Strings.get("world.bramble_boots"),
        outputItemId = "gear_bramble_boots",
        outputDisplayName = Strings.get("item.bramble_boots"),
        materials = table.freeze({
            material_meadow_fiber = 5,
            material_brightcap = 3,
        }),
    }),
    recipe_thornwood_bow = table.freeze({
        id = "recipe_thornwood_bow",
        displayName = Strings.get("world.thornwood_bow"),
        outputItemId = "gear_thornwood_bow",
        outputDisplayName = Strings.get("item.thornwood_bow"),
        materials = table.freeze({
            material_heartwood = 4,
            material_meadow_fiber = 3,
        }),
    }),
    recipe_heartwood_maul = table.freeze({
        id = "recipe_heartwood_maul",
        displayName = Strings.get("world.heartwood_maul"),
        outputItemId = "gear_heartwood_maul",
        outputDisplayName = Strings.get("item.heartwood_maul"),
        materials = table.freeze({
            material_heartwood = 6,
            material_spring_clay = 2,
        }),
    }),
    recipe_briar_lance = table.freeze({
        id = "recipe_briar_lance",
        displayName = Strings.get("world.briar_lance"),
        outputItemId = "gear_briar_lance",
        outputDisplayName = "Briar Lance",
        materials = table.freeze({
            material_heartwood = 3,
            material_meadow_fiber = 4,
        }),
    }),
    recipe_foxfire_sling = table.freeze({
        id = "recipe_foxfire_sling",
        displayName = Strings.get("world.foxfire_sling"),
        outputItemId = "gear_foxfire_sling",
        outputDisplayName = Strings.get("item.foxfire_sling"),
        materials = table.freeze({
            material_meadow_fiber = 4,
            material_brightcap = 3,
        }),
    }),
    recipe_amber_edge = table.freeze({
        id = "recipe_amber_edge",
        displayName = Strings.get("world.amber_edge"),
        outputItemId = "gear_amber_edge",
        outputDisplayName = "Amber Edge",
        materials = table.freeze({
            material_amber_sap = 4,
            material_heartwood = 3,
        }),
    }),
    recipe_warden_cudgel = table.freeze({
        id = "recipe_warden_cudgel",
        displayName = Strings.get("world.warden_cudgel"),
        outputItemId = "gear_warden_cudgel",
        outputDisplayName = Strings.get("item.warden_cudgel"),
        materials = table.freeze({
            material_heartwood = 4,
            material_spring_clay = 3,
        }),
    }),
    recipe_stope_bow = table.freeze({
        id = "recipe_stope_bow",
        displayName = Strings.get("item.stope_bow"),
        outputItemId = "gear_stope_bow",
        outputDisplayName = "Stope Bow",
        materials = table.freeze({
            material_glow_fungus = 2,
            material_ironroot_ore = 4,
        }),
    }),
    recipe_drift_maul = table.freeze({
        id = "recipe_drift_maul",
        displayName = Strings.get("item.drift_maul"),
        outputItemId = "gear_drift_maul",
        outputDisplayName = "Drift Maul",
        materials = table.freeze({
            material_glow_fungus = 2,
            material_ironroot_ore = 4,
        }),
    }),
    recipe_pit_lance = table.freeze({
        id = "recipe_pit_lance",
        displayName = Strings.get("item.pit_lance"),
        outputItemId = "gear_pit_lance",
        outputDisplayName = "Pit Lance",
        materials = table.freeze({
            material_glow_fungus = 2,
            material_ironroot_ore = 4,
        }),
    }),
    recipe_slag_sling = table.freeze({
        id = "recipe_slag_sling",
        displayName = Strings.get("item.slag_sling"),
        outputItemId = "gear_slag_sling",
        outputDisplayName = "Slag Sling",
        materials = table.freeze({
            material_glow_fungus = 2,
            material_ironroot_ore = 4,
        }),
    }),
    recipe_coalglass_edge = table.freeze({
        id = "recipe_coalglass_edge",
        displayName = Strings.get("item.coalglass_edge"),
        outputItemId = "gear_coalglass_edge",
        outputDisplayName = Strings.get("item.coalglass_edge_2"),
        materials = table.freeze({
            material_glow_fungus = 2,
            material_ironroot_ore = 4,
        }),
    }),
    recipe_shift_cudgel = table.freeze({
        id = "recipe_shift_cudgel",
        displayName = Strings.get("item.shift_cudgel"),
        outputItemId = "gear_shift_cudgel",
        outputDisplayName = "Shift Cudgel",
        materials = table.freeze({
            material_glow_fungus = 2,
            material_ironroot_ore = 4,
        }),
    }),
    recipe_ironroot_cowl = table.freeze({
        id = "recipe_ironroot_cowl",
        displayName = Strings.get("item.ironroot_cowl"),
        outputItemId = "gear_ironroot_cowl",
        outputDisplayName = Strings.get("item.ironroot_cowl_2"),
        materials = table.freeze({
            material_coalglass = 4,
            material_echo_crystal = 2,
        }),
    }),
    recipe_ironroot_helm = table.freeze({
        id = "recipe_ironroot_helm",
        displayName = Strings.get("item.ironroot_helm"),
        outputItemId = "gear_ironroot_helm",
        outputDisplayName = Strings.get("item.ironroot_helm_2"),
        materials = table.freeze({
            material_ironroot_ore = 4,
            material_machine_oil = 2,
        }),
    }),
    recipe_ironroot_coat = table.freeze({
        id = "recipe_ironroot_coat",
        displayName = Strings.get("item.ironroot_coat"),
        outputItemId = "gear_ironroot_coat",
        outputDisplayName = Strings.get("item.ironroot_coat_2"),
        materials = table.freeze({
            material_coalglass = 4,
            material_echo_crystal = 2,
        }),
    }),
    recipe_ironroot_plate = table.freeze({
        id = "recipe_ironroot_plate",
        displayName = Strings.get("item.ironroot_plate"),
        outputItemId = "gear_ironroot_plate",
        outputDisplayName = Strings.get("item.ironroot_plate_2"),
        materials = table.freeze({
            material_ironroot_ore = 4,
            material_machine_oil = 2,
        }),
    }),
    recipe_ironroot_wraps = table.freeze({
        id = "recipe_ironroot_wraps",
        displayName = Strings.get("item.ironroot_wraps"),
        outputItemId = "gear_ironroot_wraps",
        outputDisplayName = Strings.get("item.ironroot_wraps_2"),
        materials = table.freeze({
            material_coalglass = 4,
            material_echo_crystal = 2,
        }),
    }),
    recipe_ironroot_gauntlets = table.freeze({
        id = "recipe_ironroot_gauntlets",
        displayName = Strings.get("item.ironroot_gauntlets"),
        outputItemId = "gear_ironroot_gauntlets",
        outputDisplayName = Strings.get("item.ironroot_gauntlets_2"),
        materials = table.freeze({
            material_ironroot_ore = 4,
            material_machine_oil = 2,
        }),
    }),
    recipe_ironroot_boots = table.freeze({
        id = "recipe_ironroot_boots",
        displayName = Strings.get("item.ironroot_boots"),
        outputItemId = "gear_ironroot_boots",
        outputDisplayName = Strings.get("item.ironroot_boots_2"),
        materials = table.freeze({
            material_coalglass = 4,
            material_echo_crystal = 2,
        }),
    }),
    recipe_ironroot_treads = table.freeze({
        id = "recipe_ironroot_treads",
        displayName = Strings.get("item.ironroot_treads"),
        outputItemId = "gear_ironroot_treads",
        outputDisplayName = Strings.get("item.ironroot_treads_2"),
        materials = table.freeze({
            material_ironroot_ore = 4,
            material_machine_oil = 2,
        }),
    }),
    recipe_ironroot_token = table.freeze({
        id = "recipe_ironroot_token",
        displayName = Strings.get("item.ironroot_token"),
        outputItemId = "gear_ironroot_token",
        outputDisplayName = Strings.get("item.ironroot_token_2"),
        materials = table.freeze({
            material_coalglass = 4,
            material_echo_crystal = 2,
        }),
    }),
    recipe_ironroot_seal = table.freeze({
        id = "recipe_ironroot_seal",
        displayName = Strings.get("item.ironroot_seal"),
        outputItemId = "gear_ironroot_seal",
        outputDisplayName = Strings.get("item.ironroot_seal_2"),
        materials = table.freeze({
            material_ironroot_ore = 4,
            material_machine_oil = 2,
        }),
    }),
    recipe_reed_bow = table.freeze({
        id = "recipe_reed_bow",
        displayName = Strings.get("item.reed_bow"),
        outputItemId = "gear_reed_bow",
        outputDisplayName = "Reed Bow",
        materials = table.freeze({
            material_bog_iron = 5,
            material_witchlight_pollen = 3,
        }),
    }),
    recipe_bog_maul = table.freeze({
        id = "recipe_bog_maul",
        displayName = Strings.get("item.bog_maul"),
        outputItemId = "gear_bog_maul",
        outputDisplayName = "Bog Maul",
        materials = table.freeze({
            material_bog_iron = 5,
            material_witchlight_pollen = 3,
        }),
    }),
    recipe_punt_lance = table.freeze({
        id = "recipe_punt_lance",
        displayName = Strings.get("item.punt_lance"),
        outputItemId = "gear_punt_lance",
        outputDisplayName = "Punt Lance",
        materials = table.freeze({
            material_bog_iron = 5,
            material_witchlight_pollen = 3,
        }),
    }),
    recipe_mirror_sling = table.freeze({
        id = "recipe_mirror_sling",
        displayName = Strings.get("item.mirror_sling"),
        outputItemId = "gear_mirror_sling",
        outputDisplayName = "Mirror Sling",
        materials = table.freeze({
            material_bog_iron = 5,
            material_witchlight_pollen = 3,
        }),
    }),
    recipe_witchlight_edge = table.freeze({
        id = "recipe_witchlight_edge",
        displayName = Strings.get("item.witchlight_edge"),
        outputItemId = "gear_witchlight_edge",
        outputDisplayName = Strings.get("item.witchlight_edge_2"),
        materials = table.freeze({
            material_bog_iron = 5,
            material_witchlight_pollen = 3,
        }),
    }),
    recipe_ferry_cudgel = table.freeze({
        id = "recipe_ferry_cudgel",
        displayName = Strings.get("item.ferry_cudgel"),
        outputItemId = "gear_ferry_cudgel",
        outputDisplayName = "Ferry Cudgel",
        materials = table.freeze({
            material_bog_iron = 5,
            material_witchlight_pollen = 3,
        }),
    }),
    recipe_mireglass_cowl = table.freeze({
        id = "recipe_mireglass_cowl",
        displayName = Strings.get("item.mireglass_cowl"),
        outputItemId = "gear_mireglass_cowl",
        outputDisplayName = Strings.get("item.mireglass_cowl_2"),
        materials = table.freeze({
            material_blackwater_herb = 2,
            material_mirror_reed = 5,
        }),
    }),
    recipe_mireglass_helm = table.freeze({
        id = "recipe_mireglass_helm",
        displayName = Strings.get("item.mireglass_helm"),
        outputItemId = "gear_mireglass_helm",
        outputDisplayName = Strings.get("item.mireglass_helm_2"),
        materials = table.freeze({
            material_bog_iron = 5,
            material_eel_oil = 2,
        }),
    }),
    recipe_mireglass_coat = table.freeze({
        id = "recipe_mireglass_coat",
        displayName = Strings.get("item.mireglass_coat"),
        outputItemId = "gear_mireglass_coat",
        outputDisplayName = Strings.get("item.mireglass_coat_2"),
        materials = table.freeze({
            material_blackwater_herb = 2,
            material_mirror_reed = 5,
        }),
    }),
    recipe_mireglass_plate = table.freeze({
        id = "recipe_mireglass_plate",
        displayName = Strings.get("item.mireglass_plate"),
        outputItemId = "gear_mireglass_plate",
        outputDisplayName = Strings.get("item.mireglass_plate_2"),
        materials = table.freeze({
            material_bog_iron = 5,
            material_eel_oil = 2,
        }),
    }),
    recipe_mireglass_wraps = table.freeze({
        id = "recipe_mireglass_wraps",
        displayName = Strings.get("item.mireglass_wraps"),
        outputItemId = "gear_mireglass_wraps",
        outputDisplayName = Strings.get("item.mireglass_wraps_2"),
        materials = table.freeze({
            material_blackwater_herb = 2,
            material_mirror_reed = 5,
        }),
    }),
    recipe_mireglass_gauntlets = table.freeze({
        id = "recipe_mireglass_gauntlets",
        displayName = Strings.get("item.mireglass_gauntlets"),
        outputItemId = "gear_mireglass_gauntlets",
        outputDisplayName = Strings.get("item.mireglass_gauntlets_2"),
        materials = table.freeze({
            material_bog_iron = 5,
            material_eel_oil = 2,
        }),
    }),
    recipe_mireglass_boots = table.freeze({
        id = "recipe_mireglass_boots",
        displayName = Strings.get("item.mireglass_boots"),
        outputItemId = "gear_mireglass_boots",
        outputDisplayName = Strings.get("item.mireglass_boots_2"),
        materials = table.freeze({
            material_blackwater_herb = 2,
            material_mirror_reed = 5,
        }),
    }),
    recipe_mireglass_treads = table.freeze({
        id = "recipe_mireglass_treads",
        displayName = Strings.get("item.mireglass_treads"),
        outputItemId = "gear_mireglass_treads",
        outputDisplayName = Strings.get("item.mireglass_treads_2"),
        materials = table.freeze({
            material_bog_iron = 5,
            material_eel_oil = 2,
        }),
    }),
    recipe_mireglass_token = table.freeze({
        id = "recipe_mireglass_token",
        displayName = Strings.get("item.mireglass_token"),
        outputItemId = "gear_mireglass_token",
        outputDisplayName = Strings.get("item.mireglass_token_2"),
        materials = table.freeze({
            material_blackwater_herb = 2,
            material_mirror_reed = 5,
        }),
    }),
    recipe_mireglass_seal = table.freeze({
        id = "recipe_mireglass_seal",
        displayName = Strings.get("item.mireglass_seal"),
        outputItemId = "gear_mireglass_seal",
        outputDisplayName = Strings.get("item.mireglass_seal_2"),
        materials = table.freeze({
            material_bog_iron = 5,
            material_eel_oil = 2,
        }),
    }),
    recipe_jetty_bow = table.freeze({
        id = "recipe_jetty_bow",
        displayName = Strings.get("item.jetty_bow"),
        outputItemId = "gear_jetty_bow",
        outputDisplayName = "Jetty Bow",
        materials = table.freeze({
            material_ships_iron = 5,
            material_storm_glass = 3,
        }),
    }),
    recipe_ballast_maul = table.freeze({
        id = "recipe_ballast_maul",
        displayName = Strings.get("item.ballast_maul"),
        outputItemId = "gear_ballast_maul",
        outputDisplayName = "Ballast Maul",
        materials = table.freeze({
            material_ships_iron = 5,
            material_storm_glass = 3,
        }),
    }),
    recipe_gaff_lance = table.freeze({
        id = "recipe_gaff_lance",
        displayName = Strings.get("item.gaff_lance"),
        outputItemId = "gear_gaff_lance",
        outputDisplayName = "Gaff Lance",
        materials = table.freeze({
            material_ships_iron = 5,
            material_storm_glass = 3,
        }),
    }),
    recipe_halyard_sling = table.freeze({
        id = "recipe_halyard_sling",
        displayName = Strings.get("item.halyard_sling"),
        outputItemId = "gear_halyard_sling",
        outputDisplayName = Strings.get("item.halyard_sling_2"),
        materials = table.freeze({
            material_ships_iron = 5,
            material_storm_glass = 3,
        }),
    }),
    recipe_amberglass_edge = table.freeze({
        id = "recipe_amberglass_edge",
        displayName = Strings.get("store.amberglass_edge"),
        outputItemId = "gear_amberglass_edge",
        outputDisplayName = Strings.get("item.amberglass_edge"),
        materials = table.freeze({
            material_ships_iron = 5,
            material_storm_glass = 3,
        }),
    }),
    recipe_breakwater_cudgel = table.freeze({
        id = "recipe_breakwater_cudgel",
        displayName = Strings.get("item.breakwater_cudgel"),
        outputItemId = "gear_breakwater_cudgel",
        outputDisplayName = Strings.get("item.breakwater_cudgel_2"),
        materials = table.freeze({
            material_ships_iron = 5,
            material_storm_glass = 3,
        }),
    }),
    recipe_tempest_cowl = table.freeze({
        id = "recipe_tempest_cowl",
        displayName = Strings.get("item.tempest_cowl"),
        outputItemId = "gear_tempest_cowl",
        outputDisplayName = "Tempest Cowl",
        materials = table.freeze({
            material_amberglass = 2,
            material_rope_fiber = 5,
        }),
    }),
    recipe_tempest_helm = table.freeze({
        id = "recipe_tempest_helm",
        displayName = Strings.get("item.tempest_helm"),
        outputItemId = "gear_tempest_helm",
        outputDisplayName = "Tempest Helm",
        materials = table.freeze({
            material_salt_kelp = 2,
            material_ships_iron = 5,
        }),
    }),
    recipe_tempest_coat = table.freeze({
        id = "recipe_tempest_coat",
        displayName = Strings.get("item.tempest_coat"),
        outputItemId = "gear_tempest_coat",
        outputDisplayName = "Tempest Coat",
        materials = table.freeze({
            material_amberglass = 2,
            material_rope_fiber = 5,
        }),
    }),
    recipe_tempest_plate = table.freeze({
        id = "recipe_tempest_plate",
        displayName = Strings.get("item.tempest_plate"),
        outputItemId = "gear_tempest_plate",
        outputDisplayName = Strings.get("item.tempest_plate_2"),
        materials = table.freeze({
            material_salt_kelp = 2,
            material_ships_iron = 5,
        }),
    }),
    recipe_tempest_wraps = table.freeze({
        id = "recipe_tempest_wraps",
        displayName = Strings.get("item.tempest_wraps"),
        outputItemId = "gear_tempest_wraps",
        outputDisplayName = Strings.get("item.tempest_wraps_2"),
        materials = table.freeze({
            material_amberglass = 2,
            material_rope_fiber = 5,
        }),
    }),
    recipe_tempest_gauntlets = table.freeze({
        id = "recipe_tempest_gauntlets",
        displayName = Strings.get("item.tempest_gauntlets"),
        outputItemId = "gear_tempest_gauntlets",
        outputDisplayName = Strings.get("item.tempest_gauntlets_2"),
        materials = table.freeze({
            material_salt_kelp = 2,
            material_ships_iron = 5,
        }),
    }),
    recipe_tempest_boots = table.freeze({
        id = "recipe_tempest_boots",
        displayName = Strings.get("item.tempest_boots"),
        outputItemId = "gear_tempest_boots",
        outputDisplayName = Strings.get("item.tempest_boots_2"),
        materials = table.freeze({
            material_amberglass = 2,
            material_rope_fiber = 5,
        }),
    }),
    recipe_tempest_treads = table.freeze({
        id = "recipe_tempest_treads",
        displayName = Strings.get("item.tempest_treads"),
        outputItemId = "gear_tempest_treads",
        outputDisplayName = Strings.get("item.tempest_treads_2"),
        materials = table.freeze({
            material_salt_kelp = 2,
            material_ships_iron = 5,
        }),
    }),
    recipe_tempest_token = table.freeze({
        id = "recipe_tempest_token",
        displayName = Strings.get("item.tempest_token"),
        outputItemId = "gear_tempest_token",
        outputDisplayName = Strings.get("item.tempest_token_2"),
        materials = table.freeze({
            material_amberglass = 2,
            material_rope_fiber = 5,
        }),
    }),
    recipe_tempest_seal = table.freeze({
        id = "recipe_tempest_seal",
        displayName = Strings.get("item.tempest_seal"),
        outputItemId = "gear_tempest_seal",
        outputDisplayName = "Tempest Seal",
        materials = table.freeze({
            material_salt_kelp = 2,
            material_ships_iron = 5,
        }),
    }),
    recipe_vale_bow = table.freeze({
        id = "recipe_vale_bow",
        displayName = Strings.get("item.vale_bow"),
        outputItemId = "gear_vale_bow",
        outputDisplayName = "Vale Bow",
        materials = table.freeze({
            material_frostmere_ice = 4,
            material_thawed_iron = 6,
        }),
    }),
    recipe_thaw_maul = table.freeze({
        id = "recipe_thaw_maul",
        displayName = Strings.get("item.thaw_maul"),
        outputItemId = "gear_thaw_maul",
        outputDisplayName = "Thaw Maul",
        materials = table.freeze({
            material_frostmere_ice = 4,
            material_thawed_iron = 6,
        }),
    }),
    recipe_crevasse_lance = table.freeze({
        id = "recipe_crevasse_lance",
        displayName = Strings.get("item.crevasse_lance"),
        outputItemId = "gear_crevasse_lance",
        outputDisplayName = Strings.get("item.crevasse_lance_2"),
        materials = table.freeze({
            material_frostmere_ice = 4,
            material_thawed_iron = 6,
        }),
    }),
    recipe_hush_sling = table.freeze({
        id = "recipe_hush_sling",
        displayName = Strings.get("item.hush_sling"),
        outputItemId = "gear_hush_sling",
        outputDisplayName = "Hush Sling",
        materials = table.freeze({
            material_frostmere_ice = 4,
            material_thawed_iron = 6,
        }),
    }),
    recipe_rime_edge = table.freeze({
        id = "recipe_rime_edge",
        displayName = Strings.get("item.rime_edge"),
        outputItemId = "gear_rime_edge",
        outputDisplayName = "Rime Edge",
        materials = table.freeze({
            material_frostmere_ice = 4,
            material_thawed_iron = 6,
        }),
    }),
    recipe_cloister_cudgel = table.freeze({
        id = "recipe_cloister_cudgel",
        displayName = Strings.get("item.cloister_cudgel"),
        outputItemId = "gear_cloister_cudgel",
        outputDisplayName = Strings.get("item.cloister_cudgel_2"),
        materials = table.freeze({
            material_frostmere_ice = 4,
            material_thawed_iron = 6,
        }),
    }),
    recipe_frostmere_cowl = table.freeze({
        id = "recipe_frostmere_cowl",
        displayName = Strings.get("item.frostmere_cowl"),
        outputItemId = "gear_frostmere_cowl",
        outputDisplayName = Strings.get("item.frostmere_cowl_2"),
        materials = table.freeze({
            material_aurora_salt = 2,
            material_frostmere_wool = 6,
        }),
    }),
    recipe_frostmere_helm = table.freeze({
        id = "recipe_frostmere_helm",
        displayName = Strings.get("item.frostmere_helm"),
        outputItemId = "gear_frostmere_helm",
        outputDisplayName = Strings.get("item.frostmere_helm_2"),
        materials = table.freeze({
            material_ember_moss = 2,
            material_thawed_iron = 6,
        }),
    }),
    recipe_frostmere_coat = table.freeze({
        id = "recipe_frostmere_coat",
        displayName = Strings.get("item.frostmere_coat"),
        outputItemId = "gear_frostmere_coat",
        outputDisplayName = Strings.get("item.frostmere_coat_2"),
        materials = table.freeze({
            material_aurora_salt = 2,
            material_frostmere_wool = 6,
        }),
    }),
    recipe_frostmere_plate = table.freeze({
        id = "recipe_frostmere_plate",
        displayName = Strings.get("item.frostmere_plate"),
        outputItemId = "gear_frostmere_plate",
        outputDisplayName = Strings.get("item.frostmere_plate_2"),
        materials = table.freeze({
            material_ember_moss = 2,
            material_thawed_iron = 6,
        }),
    }),
    recipe_frostmere_wraps = table.freeze({
        id = "recipe_frostmere_wraps",
        displayName = Strings.get("item.frostmere_wraps"),
        outputItemId = "gear_frostmere_wraps",
        outputDisplayName = Strings.get("item.frostmere_wraps_2"),
        materials = table.freeze({
            material_aurora_salt = 2,
            material_frostmere_wool = 6,
        }),
    }),
    recipe_frostmere_gauntlets = table.freeze({
        id = "recipe_frostmere_gauntlets",
        displayName = Strings.get("item.frostmere_gauntlets"),
        outputItemId = "gear_frostmere_gauntlets",
        outputDisplayName = Strings.get("item.frostmere_gauntlets_2"),
        materials = table.freeze({
            material_ember_moss = 2,
            material_thawed_iron = 6,
        }),
    }),
    recipe_frostmere_boots = table.freeze({
        id = "recipe_frostmere_boots",
        displayName = Strings.get("item.frostmere_boots"),
        outputItemId = "gear_frostmere_boots",
        outputDisplayName = Strings.get("item.frostmere_boots_2"),
        materials = table.freeze({
            material_aurora_salt = 2,
            material_frostmere_wool = 6,
        }),
    }),
    recipe_frostmere_treads = table.freeze({
        id = "recipe_frostmere_treads",
        displayName = Strings.get("item.frostmere_treads"),
        outputItemId = "gear_frostmere_treads",
        outputDisplayName = Strings.get("item.frostmere_treads_2"),
        materials = table.freeze({
            material_ember_moss = 2,
            material_thawed_iron = 6,
        }),
    }),
    recipe_frostmere_token = table.freeze({
        id = "recipe_frostmere_token",
        displayName = Strings.get("item.frostmere_token"),
        outputItemId = "gear_frostmere_token",
        outputDisplayName = Strings.get("item.frostmere_token_2"),
        materials = table.freeze({
            material_aurora_salt = 2,
            material_frostmere_wool = 6,
        }),
    }),
    recipe_frostmere_seal = table.freeze({
        id = "recipe_frostmere_seal",
        displayName = Strings.get("item.frostmere_seal"),
        outputItemId = "gear_frostmere_seal",
        outputDisplayName = Strings.get("item.frostmere_seal_2"),
        materials = table.freeze({
            material_ember_moss = 2,
            material_thawed_iron = 6,
        }),
    }),
    recipe_tier_bow = table.freeze({
        id = "recipe_tier_bow",
        displayName = Strings.get("item.tier_bow"),
        outputItemId = "gear_tier_bow",
        outputDisplayName = "Tier Bow",
        materials = table.freeze({
            material_cindersteel = 7,
            material_memory_glass = 5,
        }),
    }),
    recipe_kiln_maul = table.freeze({
        id = "recipe_kiln_maul",
        displayName = Strings.get("item.kiln_maul"),
        outputItemId = "gear_kiln_maul",
        outputDisplayName = "Kiln Maul",
        materials = table.freeze({
            material_cindersteel = 7,
            material_memory_glass = 5,
        }),
    }),
    recipe_procession_lance = table.freeze({
        id = "recipe_procession_lance",
        displayName = Strings.get("item.procession_lance"),
        outputItemId = "gear_procession_lance",
        outputDisplayName = Strings.get("item.procession_lance_2"),
        materials = table.freeze({
            material_cindersteel = 7,
            material_memory_glass = 5,
        }),
    }),
    recipe_cinder_sling = table.freeze({
        id = "recipe_cinder_sling",
        displayName = Strings.get("item.cinder_sling"),
        outputItemId = "gear_cinder_sling",
        outputDisplayName = "Cinder Sling",
        materials = table.freeze({
            material_cindersteel = 7,
            material_memory_glass = 5,
        }),
    }),
    recipe_memory_edge = table.freeze({
        id = "recipe_memory_edge",
        displayName = Strings.get("item.memory_edge"),
        outputItemId = "gear_memory_edge",
        outputDisplayName = "Memory Edge",
        materials = table.freeze({
            material_cindersteel = 7,
            material_memory_glass = 5,
        }),
    }),
    recipe_bailiff_cudgel = table.freeze({
        id = "recipe_bailiff_cudgel",
        displayName = Strings.get("item.bailiff_cudgel"),
        outputItemId = "gear_bailiff_cudgel",
        outputDisplayName = Strings.get("item.bailiff_cudgel_2"),
        materials = table.freeze({
            material_cindersteel = 7,
            material_memory_glass = 5,
        }),
    }),
    recipe_cinderfall_cowl = table.freeze({
        id = "recipe_cinderfall_cowl",
        displayName = Strings.get("item.cinderfall_cowl"),
        outputItemId = "gear_cinderfall_cowl",
        outputDisplayName = Strings.get("item.cinderfall_cowl_2"),
        materials = table.freeze({
            material_ash_silk = 7,
            material_crown_coal = 2,
        }),
    }),
    recipe_cinderfall_helm = table.freeze({
        id = "recipe_cinderfall_helm",
        displayName = Strings.get("item.cinderfall_helm"),
        outputItemId = "gear_cinderfall_helm",
        outputDisplayName = Strings.get("item.cinderfall_helm_2"),
        materials = table.freeze({
            material_cindersteel = 7,
            material_kiln_pearl = 2,
        }),
    }),
    recipe_cinderfall_coat = table.freeze({
        id = "recipe_cinderfall_coat",
        displayName = Strings.get("item.cinderfall_coat"),
        outputItemId = "gear_cinderfall_coat",
        outputDisplayName = Strings.get("item.cinderfall_coat_2"),
        materials = table.freeze({
            material_ash_silk = 7,
            material_crown_coal = 2,
        }),
    }),
    recipe_cinderfall_plate = table.freeze({
        id = "recipe_cinderfall_plate",
        displayName = Strings.get("item.cinderfall_plate"),
        outputItemId = "gear_cinderfall_plate",
        outputDisplayName = Strings.get("item.cinderfall_plate_2"),
        materials = table.freeze({
            material_cindersteel = 7,
            material_kiln_pearl = 2,
        }),
    }),
    recipe_cinderfall_wraps = table.freeze({
        id = "recipe_cinderfall_wraps",
        displayName = Strings.get("item.cinderfall_wraps"),
        outputItemId = "gear_cinderfall_wraps",
        outputDisplayName = Strings.get("item.cinderfall_wraps_2"),
        materials = table.freeze({
            material_ash_silk = 7,
            material_crown_coal = 2,
        }),
    }),
    recipe_cinderfall_gauntlets = table.freeze({
        id = "recipe_cinderfall_gauntlets",
        displayName = Strings.get("item.cinderfall_gauntlets"),
        outputItemId = "gear_cinderfall_gauntlets",
        outputDisplayName = Strings.get("item.cinderfall_gauntlets_2"),
        materials = table.freeze({
            material_cindersteel = 7,
            material_kiln_pearl = 2,
        }),
    }),
    recipe_cinderfall_boots = table.freeze({
        id = "recipe_cinderfall_boots",
        displayName = Strings.get("item.cinderfall_boots"),
        outputItemId = "gear_cinderfall_boots",
        outputDisplayName = Strings.get("item.cinderfall_boots_2"),
        materials = table.freeze({
            material_ash_silk = 7,
            material_crown_coal = 2,
        }),
    }),
    recipe_cinderfall_treads = table.freeze({
        id = "recipe_cinderfall_treads",
        displayName = Strings.get("item.cinderfall_treads"),
        outputItemId = "gear_cinderfall_treads",
        outputDisplayName = Strings.get("item.cinderfall_treads_2"),
        materials = table.freeze({
            material_cindersteel = 7,
            material_kiln_pearl = 2,
        }),
    }),
    recipe_cinderfall_token = table.freeze({
        id = "recipe_cinderfall_token",
        displayName = Strings.get("item.cinderfall_token"),
        outputItemId = "gear_cinderfall_token",
        outputDisplayName = Strings.get("item.cinderfall_token_2"),
        materials = table.freeze({
            material_ash_silk = 7,
            material_crown_coal = 2,
        }),
    }),
    recipe_cinderfall_seal = table.freeze({
        id = "recipe_cinderfall_seal",
        displayName = Strings.get("item.cinderfall_seal"),
        outputItemId = "gear_cinderfall_seal",
        outputDisplayName = Strings.get("item.cinderfall_seal_2"),
        materials = table.freeze({
            material_cindersteel = 7,
            material_kiln_pearl = 2,
        }),
    }),
    recipe_delve_ration = table.freeze({
        id = "recipe_delve_ration",
        displayName = Strings.get("item.delve_ration"),
        outputItemId = "gear_delve_ration",
        outputDisplayName = "Delve Ration",
        materials = table.freeze({
            material_glow_fungus = 4,
            material_machine_oil = 2,
        }),
    }),
    recipe_coalglass_ward = table.freeze({
        id = "recipe_coalglass_ward",
        displayName = Strings.get("item.coalglass_ward"),
        outputItemId = "gear_coalglass_ward",
        outputDisplayName = Strings.get("item.coalglass_ward_2"),
        materials = table.freeze({
            material_coalglass = 4,
            material_ironroot_ore = 3,
        }),
    }),
    recipe_reed_tonic = table.freeze({
        id = "recipe_reed_tonic",
        displayName = Strings.get("item.reed_tonic"),
        outputItemId = "gear_reed_tonic",
        outputDisplayName = "Reed Tonic",
        materials = table.freeze({
            material_blackwater_herb = 4,
            material_mirror_reed = 3,
        }),
    }),
    recipe_mirror_ward = table.freeze({
        id = "recipe_mirror_ward",
        displayName = Strings.get("item.mirror_ward"),
        outputItemId = "gear_mirror_ward",
        outputDisplayName = "Mirror Ward",
        materials = table.freeze({
            material_mirror_reed = 5,
            material_witchlight_pollen = 2,
        }),
    }),
    recipe_fen_poultice = table.freeze({
        id = "recipe_fen_poultice",
        displayName = Strings.get("item.fen_poultice"),
        outputItemId = "gear_fen_poultice",
        outputDisplayName = "Fen Poultice",
        materials = table.freeze({
            material_blackwater_herb = 5,
            material_eel_oil = 3,
        }),
    }),
    recipe_storm_ration = table.freeze({
        id = "recipe_storm_ration",
        displayName = Strings.get("item.storm_ration"),
        outputItemId = "gear_storm_ration",
        outputDisplayName = "Storm Ration",
        materials = table.freeze({
            material_rope_fiber = 3,
            material_salt_kelp = 5,
        }),
    }),
    recipe_amberglass_ward = table.freeze({
        id = "recipe_amberglass_ward",
        displayName = Strings.get("item.amberglass_ward"),
        outputItemId = "gear_amberglass_ward",
        outputDisplayName = Strings.get("item.amberglass_ward_2"),
        materials = table.freeze({
            material_amberglass = 4,
            material_storm_glass = 4,
        }),
    }),
    recipe_reach_poultice = table.freeze({
        id = "recipe_reach_poultice",
        displayName = Strings.get("item.reach_poultice"),
        outputItemId = "gear_reach_poultice",
        outputDisplayName = Strings.get("item.reach_poultice_2"),
        materials = table.freeze({
            material_salt_kelp = 6,
            material_ships_iron = 2,
        }),
    }),
    recipe_ember_ration = table.freeze({
        id = "recipe_ember_ration",
        displayName = Strings.get("item.ember_ration"),
        outputItemId = "gear_ember_ration",
        outputDisplayName = "Ember Ration",
        materials = table.freeze({
            material_ember_moss = 5,
            material_frostmere_wool = 3,
        }),
    }),
    recipe_rime_ward = table.freeze({
        id = "recipe_rime_ward",
        displayName = Strings.get("item.rime_ward"),
        outputItemId = "gear_rime_ward",
        outputDisplayName = "Rime Ward",
        materials = table.freeze({
            material_frostmere_ice = 5,
            material_thawed_iron = 3,
        }),
    }),
    recipe_vale_poultice = table.freeze({
        id = "recipe_vale_poultice",
        displayName = Strings.get("item.vale_poultice"),
        outputItemId = "gear_vale_poultice",
        outputDisplayName = Strings.get("item.vale_poultice_2"),
        materials = table.freeze({
            material_aurora_salt = 3,
            material_ember_moss = 6,
        }),
    }),
    recipe_kiln_ration = table.freeze({
        id = "recipe_kiln_ration",
        displayName = Strings.get("item.kiln_ration"),
        outputItemId = "gear_kiln_ration",
        outputDisplayName = "Kiln Ration",
        materials = table.freeze({
            material_ash_silk = 4,
            material_crown_coal = 5,
        }),
    }),
    recipe_cindersteel_ward = table.freeze({
        id = "recipe_cindersteel_ward",
        displayName = Strings.get("item.cindersteel_ward"),
        outputItemId = "gear_cindersteel_ward",
        outputDisplayName = Strings.get("item.cindersteel_ward_2"),
        materials = table.freeze({
            material_cindersteel = 5,
            material_kiln_pearl = 3,
        }),
    }),
    recipe_crown_poultice = table.freeze({
        id = "recipe_crown_poultice",
        displayName = Strings.get("item.crown_poultice"),
        outputItemId = "gear_crown_poultice",
        outputDisplayName = Strings.get("item.crown_poultice_2"),
        materials = table.freeze({
            material_ash_silk = 6,
            material_memory_glass = 3,
        }),
    }),
    recipe_meadow_lantern_oil = table.freeze({
        id = "recipe_meadow_lantern_oil",
        displayName = Strings.get("item.meadow_lantern_oil"),
        outputItemId = "gear_meadow_lantern_oil",
        outputDisplayName = Strings.get("item.meadow_lantern_oil_2"),
        materials = table.freeze({
            material_amber_sap = 4,
            material_brightcap = 3,
        }),
    }),
    recipe_meadow_clearwater = table.freeze({
        id = "recipe_meadow_clearwater",
        displayName = Strings.get("item.meadow_clearwater"),
        outputItemId = "gear_meadow_clearwater",
        outputDisplayName = Strings.get("item.meadow_clearwater_2"),
        materials = table.freeze({
            material_brightcap = 4,
            material_meadow_fiber = 3,
        }),
    }),
    recipe_meadow_mending_kit = table.freeze({
        id = "recipe_meadow_mending_kit",
        displayName = Strings.get("item.meadow_mending_kit"),
        outputItemId = "gear_meadow_mending_kit",
        outputDisplayName = Strings.get("item.meadow_mending_kit_2"),
        materials = table.freeze({
            material_heartwood = 4,
            material_meadow_fiber = 4,
        }),
    }),
    recipe_delve_lantern_oil = table.freeze({
        id = "recipe_delve_lantern_oil",
        displayName = Strings.get("item.delve_lantern_oil"),
        outputItemId = "gear_delve_lantern_oil",
        outputDisplayName = Strings.get("item.delve_lantern_oil_2"),
        materials = table.freeze({
            material_machine_oil = 4,
            material_coalglass = 3,
        }),
    }),
    recipe_delve_clearwater = table.freeze({
        id = "recipe_delve_clearwater",
        displayName = Strings.get("item.delve_clearwater"),
        outputItemId = "gear_delve_clearwater",
        outputDisplayName = Strings.get("item.delve_clearwater_2"),
        materials = table.freeze({
            material_glow_fungus = 4,
            material_echo_crystal = 2,
        }),
    }),
    recipe_delve_mending_kit = table.freeze({
        id = "recipe_delve_mending_kit",
        displayName = Strings.get("item.delve_mending_kit"),
        outputItemId = "gear_delve_mending_kit",
        outputDisplayName = Strings.get("item.delve_mending_kit_2"),
        materials = table.freeze({
            material_ironroot_ore = 4,
            material_machine_oil = 3,
        }),
    }),
    recipe_fen_lantern_oil = table.freeze({
        id = "recipe_fen_lantern_oil",
        displayName = Strings.get("item.fen_lantern_oil"),
        outputItemId = "gear_fen_lantern_oil",
        outputDisplayName = Strings.get("item.fen_lantern_oil_2"),
        materials = table.freeze({
            material_eel_oil = 4,
            material_witchlight_pollen = 3,
        }),
    }),
    recipe_fen_clearwater = table.freeze({
        id = "recipe_fen_clearwater",
        displayName = Strings.get("item.fen_clearwater"),
        outputItemId = "gear_fen_clearwater",
        outputDisplayName = Strings.get("item.fen_clearwater_2"),
        materials = table.freeze({
            material_blackwater_herb = 4,
            material_witchlight_pollen = 2,
        }),
    }),
    recipe_fen_mending_kit = table.freeze({
        id = "recipe_fen_mending_kit",
        displayName = Strings.get("item.fen_mending_kit"),
        outputItemId = "gear_fen_mending_kit",
        outputDisplayName = Strings.get("item.fen_mending_kit_2"),
        materials = table.freeze({
            material_bog_iron = 4,
            material_mirror_reed = 3,
        }),
    }),
    recipe_reach_lantern_oil = table.freeze({
        id = "recipe_reach_lantern_oil",
        displayName = Strings.get("item.reach_lantern_oil"),
        outputItemId = "gear_reach_lantern_oil",
        outputDisplayName = Strings.get("item.reach_lantern_oil_2"),
        materials = table.freeze({
            material_storm_glass = 4,
            material_salt_kelp = 3,
        }),
    }),
    recipe_reach_clearwater = table.freeze({
        id = "recipe_reach_clearwater",
        displayName = Strings.get("item.reach_clearwater"),
        outputItemId = "gear_reach_clearwater",
        outputDisplayName = Strings.get("item.reach_clearwater_2"),
        materials = table.freeze({
            material_salt_kelp = 5,
            material_amberglass = 2,
        }),
    }),
    recipe_reach_mending_kit = table.freeze({
        id = "recipe_reach_mending_kit",
        displayName = Strings.get("item.reach_mending_kit"),
        outputItemId = "gear_reach_mending_kit",
        outputDisplayName = Strings.get("item.reach_mending_kit_2"),
        materials = table.freeze({
            material_ships_iron = 4,
            material_rope_fiber = 4,
        }),
    }),
    recipe_vale_lantern_oil = table.freeze({
        id = "recipe_vale_lantern_oil",
        displayName = Strings.get("item.vale_lantern_oil"),
        outputItemId = "gear_vale_lantern_oil",
        outputDisplayName = Strings.get("item.vale_lantern_oil_2"),
        materials = table.freeze({
            material_ember_moss = 4,
            material_aurora_salt = 3,
        }),
    }),
    recipe_vale_clearwater = table.freeze({
        id = "recipe_vale_clearwater",
        displayName = Strings.get("item.vale_clearwater"),
        outputItemId = "gear_vale_clearwater",
        outputDisplayName = Strings.get("item.vale_clearwater_2"),
        materials = table.freeze({
            material_aurora_salt = 4,
            material_frostmere_wool = 3,
        }),
    }),
    recipe_vale_mending_kit = table.freeze({
        id = "recipe_vale_mending_kit",
        displayName = Strings.get("item.vale_mending_kit"),
        outputItemId = "gear_vale_mending_kit",
        outputDisplayName = Strings.get("item.vale_mending_kit_2"),
        materials = table.freeze({
            material_thawed_iron = 4,
            material_frostmere_wool = 3,
        }),
    }),
    recipe_crown_lantern_oil = table.freeze({
        id = "recipe_crown_lantern_oil",
        displayName = Strings.get("item.crown_lantern_oil"),
        outputItemId = "gear_crown_lantern_oil",
        outputDisplayName = Strings.get("item.crown_lantern_oil_2"),
        materials = table.freeze({
            material_crown_coal = 4,
            material_memory_glass = 3,
        }),
    }),
    recipe_crown_clearwater = table.freeze({
        id = "recipe_crown_clearwater",
        displayName = Strings.get("item.crown_clearwater"),
        outputItemId = "gear_crown_clearwater",
        outputDisplayName = Strings.get("item.crown_clearwater_2"),
        materials = table.freeze({
            material_memory_glass = 4,
            material_ash_silk = 3,
        }),
    }),
    recipe_crown_mending_kit = table.freeze({
        id = "recipe_crown_mending_kit",
        displayName = Strings.get("item.crown_mending_kit"),
        outputItemId = "gear_crown_mending_kit",
        outputDisplayName = Strings.get("item.crown_mending_kit_2"),
        materials = table.freeze({
            material_cindersteel = 4,
            material_kiln_pearl = 3,
        }),
    }),
    recipe_meadow_cowl = table.freeze({
        id = "recipe_meadow_cowl",
        displayName = Strings.get("item.meadow_cowl"),
        outputItemId = "gear_meadow_cowl",
        outputDisplayName = "Meadow Cowl",
        materials = table.freeze({
            material_brightcap = 2,
            material_meadow_fiber = 4,
        }),
    }),
    recipe_bramble_treads = table.freeze({
        id = "recipe_bramble_treads",
        displayName = Strings.get("item.bramble_treads"),
        outputItemId = "gear_bramble_treads",
        outputDisplayName = Strings.get("item.bramble_treads_2"),
        materials = table.freeze({
            material_heartwood = 4,
            material_spring_clay = 2,
        }),
    }),
    recipe_meadow_coat = table.freeze({
        id = "recipe_meadow_coat",
        displayName = Strings.get("item.meadow_coat"),
        outputItemId = "gear_meadow_coat",
        outputDisplayName = "Meadow Coat",
        materials = table.freeze({
            material_amber_sap = 2,
            material_meadow_fiber = 5,
        }),
    }),
    recipe_bark_plate = table.freeze({
        id = "recipe_bark_plate",
        displayName = Strings.get("item.bark_plate"),
        outputItemId = "gear_bark_plate",
        outputDisplayName = "Bark Plate",
        materials = table.freeze({
            material_heartwood = 5,
            material_spring_clay = 3,
        }),
    }),
    recipe_meadow_wraps = table.freeze({
        id = "recipe_meadow_wraps",
        displayName = Strings.get("item.meadow_wraps"),
        outputItemId = "gear_meadow_wraps",
        outputDisplayName = "Meadow Wraps",
        materials = table.freeze({
            material_brightcap = 2,
            material_meadow_fiber = 3,
        }),
    }),
    recipe_bramble_gauntlets = table.freeze({
        id = "recipe_bramble_gauntlets",
        displayName = Strings.get("item.bramble_gauntlets"),
        outputItemId = "gear_bramble_gauntlets",
        outputDisplayName = Strings.get("item.bramble_gauntlets_2"),
        materials = table.freeze({
            material_amber_sap = 2,
            material_heartwood = 3,
        }),
    }),
    recipe_foxfire_token = table.freeze({
        id = "recipe_foxfire_token",
        displayName = Strings.get("item.foxfire_token"),
        outputItemId = "gear_foxfire_token",
        outputDisplayName = Strings.get("item.foxfire_token_2"),
        materials = table.freeze({
            material_amber_sap = 2,
            material_brightcap = 4,
        }),
    }),
    recipe_heartwood_seal = table.freeze({
        id = "recipe_heartwood_seal",
        displayName = Strings.get("item.heartwood_seal"),
        outputItemId = "gear_heartwood_seal",
        outputDisplayName = Strings.get("item.heartwood_seal_2"),
        materials = table.freeze({
            material_amber_sap = 3,
            material_heartwood = 4,
        }),
    }),
}

function CraftingCatalog.isValid(id: any): boolean
    return type(id) == "string" and DEFINITIONS[id] ~= nil
end

function CraftingCatalog.get(id: string): Recipe?
    return DEFINITIONS[id]
end

function CraftingCatalog.list(): { Recipe }
    local result = {}
    for _, id in ORDER do
        table.insert(result, DEFINITIONS[id])
    end
    return result
end

function CraftingCatalog.isKnownOutputItem(itemId: any): boolean
    if type(itemId) ~= "string" then
        return false
    end
    for _, id in ORDER do
        if DEFINITIONS[id].outputItemId == itemId then
            return true
        end
    end
    return false
end

CraftingCatalog.Ids = table.freeze({
    MeadowSatchel = "recipe_meadow_satchel",
    AmberCharm = "recipe_amber_charm",
    IronrootHood = "recipe_ironroot_hood",
    BrambleBoots = "recipe_bramble_boots",
    ThornwoodBow = "recipe_thornwood_bow",
    HeartwoodMaul = "recipe_heartwood_maul",
    BriarLance = "recipe_briar_lance",
    FoxfireSling = "recipe_foxfire_sling",
    AmberEdge = "recipe_amber_edge",
    WardenCudgel = "recipe_warden_cudgel",
})

return table.freeze(CraftingCatalog)
