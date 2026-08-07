--!strict

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
        displayName = "MEADOW SATCHEL",
        outputItemId = "gear_meadow_satchel",
        outputDisplayName = "Meadow Satchel",
        materials = table.freeze({
            material_meadow_fiber = 3,
            material_heartwood = 2,
        }),
    }),
    recipe_amber_charm = table.freeze({
        id = "recipe_amber_charm",
        displayName = "AMBER CHARM",
        outputItemId = "gear_amber_charm",
        outputDisplayName = "Amber Charm",
        materials = table.freeze({
            material_amber_sap = 2,
            material_brightcap = 2,
        }),
    }),
    recipe_ironroot_hood = table.freeze({
        id = "recipe_ironroot_hood",
        displayName = "IRONROOT HOOD",
        outputItemId = "gear_ironroot_hood",
        outputDisplayName = "Ironroot Hood",
        materials = table.freeze({
            material_heartwood = 5,
            material_amber_sap = 3,
        }),
    }),
    recipe_bramble_boots = table.freeze({
        id = "recipe_bramble_boots",
        displayName = "BRAMBLE BOOTS",
        outputItemId = "gear_bramble_boots",
        outputDisplayName = "Bramble Boots",
        materials = table.freeze({
            material_meadow_fiber = 5,
            material_brightcap = 3,
        }),
    }),
    recipe_thornwood_bow = table.freeze({
        id = "recipe_thornwood_bow",
        displayName = "THORNWOOD BOW",
        outputItemId = "gear_thornwood_bow",
        outputDisplayName = "Thornwood Bow",
        materials = table.freeze({
            material_heartwood = 4,
            material_meadow_fiber = 3,
        }),
    }),
    recipe_heartwood_maul = table.freeze({
        id = "recipe_heartwood_maul",
        displayName = "HEARTWOOD MAUL",
        outputItemId = "gear_heartwood_maul",
        outputDisplayName = "Heartwood Maul",
        materials = table.freeze({
            material_heartwood = 6,
            material_spring_clay = 2,
        }),
    }),
    recipe_briar_lance = table.freeze({
        id = "recipe_briar_lance",
        displayName = "BRIAR LANCE",
        outputItemId = "gear_briar_lance",
        outputDisplayName = "Briar Lance",
        materials = table.freeze({
            material_heartwood = 3,
            material_meadow_fiber = 4,
        }),
    }),
    recipe_foxfire_sling = table.freeze({
        id = "recipe_foxfire_sling",
        displayName = "FOXFIRE SLING",
        outputItemId = "gear_foxfire_sling",
        outputDisplayName = "Foxfire Sling",
        materials = table.freeze({
            material_meadow_fiber = 4,
            material_brightcap = 3,
        }),
    }),
    recipe_amber_edge = table.freeze({
        id = "recipe_amber_edge",
        displayName = "AMBER EDGE",
        outputItemId = "gear_amber_edge",
        outputDisplayName = "Amber Edge",
        materials = table.freeze({
            material_amber_sap = 4,
            material_heartwood = 3,
        }),
    }),
    recipe_warden_cudgel = table.freeze({
        id = "recipe_warden_cudgel",
        displayName = "WARDEN CUDGEL",
        outputItemId = "gear_warden_cudgel",
        outputDisplayName = "Warden Cudgel",
        materials = table.freeze({
            material_heartwood = 4,
            material_spring_clay = 3,
        }),
    }),
    recipe_stope_bow = table.freeze({
        id = "recipe_stope_bow",
        displayName = "STOPE BOW",
        outputItemId = "gear_stope_bow",
        outputDisplayName = "Stope Bow",
        materials = table.freeze({
            material_glow_fungus = 2,
            material_ironroot_ore = 4,
        }),
    }),
    recipe_drift_maul = table.freeze({
        id = "recipe_drift_maul",
        displayName = "DRIFT MAUL",
        outputItemId = "gear_drift_maul",
        outputDisplayName = "Drift Maul",
        materials = table.freeze({
            material_glow_fungus = 2,
            material_ironroot_ore = 4,
        }),
    }),
    recipe_pit_lance = table.freeze({
        id = "recipe_pit_lance",
        displayName = "PIT LANCE",
        outputItemId = "gear_pit_lance",
        outputDisplayName = "Pit Lance",
        materials = table.freeze({
            material_glow_fungus = 2,
            material_ironroot_ore = 4,
        }),
    }),
    recipe_slag_sling = table.freeze({
        id = "recipe_slag_sling",
        displayName = "SLAG SLING",
        outputItemId = "gear_slag_sling",
        outputDisplayName = "Slag Sling",
        materials = table.freeze({
            material_glow_fungus = 2,
            material_ironroot_ore = 4,
        }),
    }),
    recipe_coalglass_edge = table.freeze({
        id = "recipe_coalglass_edge",
        displayName = "COALGLASS EDGE",
        outputItemId = "gear_coalglass_edge",
        outputDisplayName = "Coalglass Edge",
        materials = table.freeze({
            material_glow_fungus = 2,
            material_ironroot_ore = 4,
        }),
    }),
    recipe_shift_cudgel = table.freeze({
        id = "recipe_shift_cudgel",
        displayName = "SHIFT CUDGEL",
        outputItemId = "gear_shift_cudgel",
        outputDisplayName = "Shift Cudgel",
        materials = table.freeze({
            material_glow_fungus = 2,
            material_ironroot_ore = 4,
        }),
    }),
    recipe_ironroot_cowl = table.freeze({
        id = "recipe_ironroot_cowl",
        displayName = "IRONROOT COWL",
        outputItemId = "gear_ironroot_cowl",
        outputDisplayName = "Ironroot Cowl",
        materials = table.freeze({
            material_coalglass = 4,
            material_echo_crystal = 2,
        }),
    }),
    recipe_ironroot_helm = table.freeze({
        id = "recipe_ironroot_helm",
        displayName = "IRONROOT HELM",
        outputItemId = "gear_ironroot_helm",
        outputDisplayName = "Ironroot Helm",
        materials = table.freeze({
            material_ironroot_ore = 4,
            material_machine_oil = 2,
        }),
    }),
    recipe_ironroot_coat = table.freeze({
        id = "recipe_ironroot_coat",
        displayName = "IRONROOT COAT",
        outputItemId = "gear_ironroot_coat",
        outputDisplayName = "Ironroot Coat",
        materials = table.freeze({
            material_coalglass = 4,
            material_echo_crystal = 2,
        }),
    }),
    recipe_ironroot_plate = table.freeze({
        id = "recipe_ironroot_plate",
        displayName = "IRONROOT PLATE",
        outputItemId = "gear_ironroot_plate",
        outputDisplayName = "Ironroot Plate",
        materials = table.freeze({
            material_ironroot_ore = 4,
            material_machine_oil = 2,
        }),
    }),
    recipe_ironroot_wraps = table.freeze({
        id = "recipe_ironroot_wraps",
        displayName = "IRONROOT WRAPS",
        outputItemId = "gear_ironroot_wraps",
        outputDisplayName = "Ironroot Wraps",
        materials = table.freeze({
            material_coalglass = 4,
            material_echo_crystal = 2,
        }),
    }),
    recipe_ironroot_gauntlets = table.freeze({
        id = "recipe_ironroot_gauntlets",
        displayName = "IRONROOT GAUNTLETS",
        outputItemId = "gear_ironroot_gauntlets",
        outputDisplayName = "Ironroot Gauntlets",
        materials = table.freeze({
            material_ironroot_ore = 4,
            material_machine_oil = 2,
        }),
    }),
    recipe_ironroot_boots = table.freeze({
        id = "recipe_ironroot_boots",
        displayName = "IRONROOT BOOTS",
        outputItemId = "gear_ironroot_boots",
        outputDisplayName = "Ironroot Boots",
        materials = table.freeze({
            material_coalglass = 4,
            material_echo_crystal = 2,
        }),
    }),
    recipe_ironroot_treads = table.freeze({
        id = "recipe_ironroot_treads",
        displayName = "IRONROOT TREADS",
        outputItemId = "gear_ironroot_treads",
        outputDisplayName = "Ironroot Treads",
        materials = table.freeze({
            material_ironroot_ore = 4,
            material_machine_oil = 2,
        }),
    }),
    recipe_ironroot_token = table.freeze({
        id = "recipe_ironroot_token",
        displayName = "IRONROOT TOKEN",
        outputItemId = "gear_ironroot_token",
        outputDisplayName = "Ironroot Token",
        materials = table.freeze({
            material_coalglass = 4,
            material_echo_crystal = 2,
        }),
    }),
    recipe_ironroot_seal = table.freeze({
        id = "recipe_ironroot_seal",
        displayName = "IRONROOT SEAL",
        outputItemId = "gear_ironroot_seal",
        outputDisplayName = "Ironroot Seal",
        materials = table.freeze({
            material_ironroot_ore = 4,
            material_machine_oil = 2,
        }),
    }),
    recipe_reed_bow = table.freeze({
        id = "recipe_reed_bow",
        displayName = "REED BOW",
        outputItemId = "gear_reed_bow",
        outputDisplayName = "Reed Bow",
        materials = table.freeze({
            material_bog_iron = 5,
            material_witchlight_pollen = 3,
        }),
    }),
    recipe_bog_maul = table.freeze({
        id = "recipe_bog_maul",
        displayName = "BOG MAUL",
        outputItemId = "gear_bog_maul",
        outputDisplayName = "Bog Maul",
        materials = table.freeze({
            material_bog_iron = 5,
            material_witchlight_pollen = 3,
        }),
    }),
    recipe_punt_lance = table.freeze({
        id = "recipe_punt_lance",
        displayName = "PUNT LANCE",
        outputItemId = "gear_punt_lance",
        outputDisplayName = "Punt Lance",
        materials = table.freeze({
            material_bog_iron = 5,
            material_witchlight_pollen = 3,
        }),
    }),
    recipe_mirror_sling = table.freeze({
        id = "recipe_mirror_sling",
        displayName = "MIRROR SLING",
        outputItemId = "gear_mirror_sling",
        outputDisplayName = "Mirror Sling",
        materials = table.freeze({
            material_bog_iron = 5,
            material_witchlight_pollen = 3,
        }),
    }),
    recipe_witchlight_edge = table.freeze({
        id = "recipe_witchlight_edge",
        displayName = "WITCHLIGHT EDGE",
        outputItemId = "gear_witchlight_edge",
        outputDisplayName = "Witchlight Edge",
        materials = table.freeze({
            material_bog_iron = 5,
            material_witchlight_pollen = 3,
        }),
    }),
    recipe_ferry_cudgel = table.freeze({
        id = "recipe_ferry_cudgel",
        displayName = "FERRY CUDGEL",
        outputItemId = "gear_ferry_cudgel",
        outputDisplayName = "Ferry Cudgel",
        materials = table.freeze({
            material_bog_iron = 5,
            material_witchlight_pollen = 3,
        }),
    }),
    recipe_mireglass_cowl = table.freeze({
        id = "recipe_mireglass_cowl",
        displayName = "MIREGLASS COWL",
        outputItemId = "gear_mireglass_cowl",
        outputDisplayName = "Mireglass Cowl",
        materials = table.freeze({
            material_blackwater_herb = 2,
            material_mirror_reed = 5,
        }),
    }),
    recipe_mireglass_helm = table.freeze({
        id = "recipe_mireglass_helm",
        displayName = "MIREGLASS HELM",
        outputItemId = "gear_mireglass_helm",
        outputDisplayName = "Mireglass Helm",
        materials = table.freeze({
            material_bog_iron = 5,
            material_eel_oil = 2,
        }),
    }),
    recipe_mireglass_coat = table.freeze({
        id = "recipe_mireglass_coat",
        displayName = "MIREGLASS COAT",
        outputItemId = "gear_mireglass_coat",
        outputDisplayName = "Mireglass Coat",
        materials = table.freeze({
            material_blackwater_herb = 2,
            material_mirror_reed = 5,
        }),
    }),
    recipe_mireglass_plate = table.freeze({
        id = "recipe_mireglass_plate",
        displayName = "MIREGLASS PLATE",
        outputItemId = "gear_mireglass_plate",
        outputDisplayName = "Mireglass Plate",
        materials = table.freeze({
            material_bog_iron = 5,
            material_eel_oil = 2,
        }),
    }),
    recipe_mireglass_wraps = table.freeze({
        id = "recipe_mireglass_wraps",
        displayName = "MIREGLASS WRAPS",
        outputItemId = "gear_mireglass_wraps",
        outputDisplayName = "Mireglass Wraps",
        materials = table.freeze({
            material_blackwater_herb = 2,
            material_mirror_reed = 5,
        }),
    }),
    recipe_mireglass_gauntlets = table.freeze({
        id = "recipe_mireglass_gauntlets",
        displayName = "MIREGLASS GAUNTLETS",
        outputItemId = "gear_mireglass_gauntlets",
        outputDisplayName = "Mireglass Gauntlets",
        materials = table.freeze({
            material_bog_iron = 5,
            material_eel_oil = 2,
        }),
    }),
    recipe_mireglass_boots = table.freeze({
        id = "recipe_mireglass_boots",
        displayName = "MIREGLASS BOOTS",
        outputItemId = "gear_mireglass_boots",
        outputDisplayName = "Mireglass Boots",
        materials = table.freeze({
            material_blackwater_herb = 2,
            material_mirror_reed = 5,
        }),
    }),
    recipe_mireglass_treads = table.freeze({
        id = "recipe_mireglass_treads",
        displayName = "MIREGLASS TREADS",
        outputItemId = "gear_mireglass_treads",
        outputDisplayName = "Mireglass Treads",
        materials = table.freeze({
            material_bog_iron = 5,
            material_eel_oil = 2,
        }),
    }),
    recipe_mireglass_token = table.freeze({
        id = "recipe_mireglass_token",
        displayName = "MIREGLASS TOKEN",
        outputItemId = "gear_mireglass_token",
        outputDisplayName = "Mireglass Token",
        materials = table.freeze({
            material_blackwater_herb = 2,
            material_mirror_reed = 5,
        }),
    }),
    recipe_mireglass_seal = table.freeze({
        id = "recipe_mireglass_seal",
        displayName = "MIREGLASS SEAL",
        outputItemId = "gear_mireglass_seal",
        outputDisplayName = "Mireglass Seal",
        materials = table.freeze({
            material_bog_iron = 5,
            material_eel_oil = 2,
        }),
    }),
    recipe_jetty_bow = table.freeze({
        id = "recipe_jetty_bow",
        displayName = "JETTY BOW",
        outputItemId = "gear_jetty_bow",
        outputDisplayName = "Jetty Bow",
        materials = table.freeze({
            material_ships_iron = 5,
            material_storm_glass = 3,
        }),
    }),
    recipe_ballast_maul = table.freeze({
        id = "recipe_ballast_maul",
        displayName = "BALLAST MAUL",
        outputItemId = "gear_ballast_maul",
        outputDisplayName = "Ballast Maul",
        materials = table.freeze({
            material_ships_iron = 5,
            material_storm_glass = 3,
        }),
    }),
    recipe_gaff_lance = table.freeze({
        id = "recipe_gaff_lance",
        displayName = "GAFF LANCE",
        outputItemId = "gear_gaff_lance",
        outputDisplayName = "Gaff Lance",
        materials = table.freeze({
            material_ships_iron = 5,
            material_storm_glass = 3,
        }),
    }),
    recipe_halyard_sling = table.freeze({
        id = "recipe_halyard_sling",
        displayName = "HALYARD SLING",
        outputItemId = "gear_halyard_sling",
        outputDisplayName = "Halyard Sling",
        materials = table.freeze({
            material_ships_iron = 5,
            material_storm_glass = 3,
        }),
    }),
    recipe_amberglass_edge = table.freeze({
        id = "recipe_amberglass_edge",
        displayName = "AMBERGLASS EDGE",
        outputItemId = "gear_amberglass_edge",
        outputDisplayName = "Amberglass Edge",
        materials = table.freeze({
            material_ships_iron = 5,
            material_storm_glass = 3,
        }),
    }),
    recipe_breakwater_cudgel = table.freeze({
        id = "recipe_breakwater_cudgel",
        displayName = "BREAKWATER CUDGEL",
        outputItemId = "gear_breakwater_cudgel",
        outputDisplayName = "Breakwater Cudgel",
        materials = table.freeze({
            material_ships_iron = 5,
            material_storm_glass = 3,
        }),
    }),
    recipe_tempest_cowl = table.freeze({
        id = "recipe_tempest_cowl",
        displayName = "TEMPEST COWL",
        outputItemId = "gear_tempest_cowl",
        outputDisplayName = "Tempest Cowl",
        materials = table.freeze({
            material_amberglass = 2,
            material_rope_fiber = 5,
        }),
    }),
    recipe_tempest_helm = table.freeze({
        id = "recipe_tempest_helm",
        displayName = "TEMPEST HELM",
        outputItemId = "gear_tempest_helm",
        outputDisplayName = "Tempest Helm",
        materials = table.freeze({
            material_salt_kelp = 2,
            material_ships_iron = 5,
        }),
    }),
    recipe_tempest_coat = table.freeze({
        id = "recipe_tempest_coat",
        displayName = "TEMPEST COAT",
        outputItemId = "gear_tempest_coat",
        outputDisplayName = "Tempest Coat",
        materials = table.freeze({
            material_amberglass = 2,
            material_rope_fiber = 5,
        }),
    }),
    recipe_tempest_plate = table.freeze({
        id = "recipe_tempest_plate",
        displayName = "TEMPEST PLATE",
        outputItemId = "gear_tempest_plate",
        outputDisplayName = "Tempest Plate",
        materials = table.freeze({
            material_salt_kelp = 2,
            material_ships_iron = 5,
        }),
    }),
    recipe_tempest_wraps = table.freeze({
        id = "recipe_tempest_wraps",
        displayName = "TEMPEST WRAPS",
        outputItemId = "gear_tempest_wraps",
        outputDisplayName = "Tempest Wraps",
        materials = table.freeze({
            material_amberglass = 2,
            material_rope_fiber = 5,
        }),
    }),
    recipe_tempest_gauntlets = table.freeze({
        id = "recipe_tempest_gauntlets",
        displayName = "TEMPEST GAUNTLETS",
        outputItemId = "gear_tempest_gauntlets",
        outputDisplayName = "Tempest Gauntlets",
        materials = table.freeze({
            material_salt_kelp = 2,
            material_ships_iron = 5,
        }),
    }),
    recipe_tempest_boots = table.freeze({
        id = "recipe_tempest_boots",
        displayName = "TEMPEST BOOTS",
        outputItemId = "gear_tempest_boots",
        outputDisplayName = "Tempest Boots",
        materials = table.freeze({
            material_amberglass = 2,
            material_rope_fiber = 5,
        }),
    }),
    recipe_tempest_treads = table.freeze({
        id = "recipe_tempest_treads",
        displayName = "TEMPEST TREADS",
        outputItemId = "gear_tempest_treads",
        outputDisplayName = "Tempest Treads",
        materials = table.freeze({
            material_salt_kelp = 2,
            material_ships_iron = 5,
        }),
    }),
    recipe_tempest_token = table.freeze({
        id = "recipe_tempest_token",
        displayName = "TEMPEST TOKEN",
        outputItemId = "gear_tempest_token",
        outputDisplayName = "Tempest Token",
        materials = table.freeze({
            material_amberglass = 2,
            material_rope_fiber = 5,
        }),
    }),
    recipe_tempest_seal = table.freeze({
        id = "recipe_tempest_seal",
        displayName = "TEMPEST SEAL",
        outputItemId = "gear_tempest_seal",
        outputDisplayName = "Tempest Seal",
        materials = table.freeze({
            material_salt_kelp = 2,
            material_ships_iron = 5,
        }),
    }),
    recipe_vale_bow = table.freeze({
        id = "recipe_vale_bow",
        displayName = "VALE BOW",
        outputItemId = "gear_vale_bow",
        outputDisplayName = "Vale Bow",
        materials = table.freeze({
            material_frostmere_ice = 4,
            material_thawed_iron = 6,
        }),
    }),
    recipe_thaw_maul = table.freeze({
        id = "recipe_thaw_maul",
        displayName = "THAW MAUL",
        outputItemId = "gear_thaw_maul",
        outputDisplayName = "Thaw Maul",
        materials = table.freeze({
            material_frostmere_ice = 4,
            material_thawed_iron = 6,
        }),
    }),
    recipe_crevasse_lance = table.freeze({
        id = "recipe_crevasse_lance",
        displayName = "CREVASSE LANCE",
        outputItemId = "gear_crevasse_lance",
        outputDisplayName = "Crevasse Lance",
        materials = table.freeze({
            material_frostmere_ice = 4,
            material_thawed_iron = 6,
        }),
    }),
    recipe_hush_sling = table.freeze({
        id = "recipe_hush_sling",
        displayName = "HUSH SLING",
        outputItemId = "gear_hush_sling",
        outputDisplayName = "Hush Sling",
        materials = table.freeze({
            material_frostmere_ice = 4,
            material_thawed_iron = 6,
        }),
    }),
    recipe_rime_edge = table.freeze({
        id = "recipe_rime_edge",
        displayName = "RIME EDGE",
        outputItemId = "gear_rime_edge",
        outputDisplayName = "Rime Edge",
        materials = table.freeze({
            material_frostmere_ice = 4,
            material_thawed_iron = 6,
        }),
    }),
    recipe_cloister_cudgel = table.freeze({
        id = "recipe_cloister_cudgel",
        displayName = "CLOISTER CUDGEL",
        outputItemId = "gear_cloister_cudgel",
        outputDisplayName = "Cloister Cudgel",
        materials = table.freeze({
            material_frostmere_ice = 4,
            material_thawed_iron = 6,
        }),
    }),
    recipe_frostmere_cowl = table.freeze({
        id = "recipe_frostmere_cowl",
        displayName = "FROSTMERE COWL",
        outputItemId = "gear_frostmere_cowl",
        outputDisplayName = "Frostmere Cowl",
        materials = table.freeze({
            material_aurora_salt = 2,
            material_frostmere_wool = 6,
        }),
    }),
    recipe_frostmere_helm = table.freeze({
        id = "recipe_frostmere_helm",
        displayName = "FROSTMERE HELM",
        outputItemId = "gear_frostmere_helm",
        outputDisplayName = "Frostmere Helm",
        materials = table.freeze({
            material_ember_moss = 2,
            material_thawed_iron = 6,
        }),
    }),
    recipe_frostmere_coat = table.freeze({
        id = "recipe_frostmere_coat",
        displayName = "FROSTMERE COAT",
        outputItemId = "gear_frostmere_coat",
        outputDisplayName = "Frostmere Coat",
        materials = table.freeze({
            material_aurora_salt = 2,
            material_frostmere_wool = 6,
        }),
    }),
    recipe_frostmere_plate = table.freeze({
        id = "recipe_frostmere_plate",
        displayName = "FROSTMERE PLATE",
        outputItemId = "gear_frostmere_plate",
        outputDisplayName = "Frostmere Plate",
        materials = table.freeze({
            material_ember_moss = 2,
            material_thawed_iron = 6,
        }),
    }),
    recipe_frostmere_wraps = table.freeze({
        id = "recipe_frostmere_wraps",
        displayName = "FROSTMERE WRAPS",
        outputItemId = "gear_frostmere_wraps",
        outputDisplayName = "Frostmere Wraps",
        materials = table.freeze({
            material_aurora_salt = 2,
            material_frostmere_wool = 6,
        }),
    }),
    recipe_frostmere_gauntlets = table.freeze({
        id = "recipe_frostmere_gauntlets",
        displayName = "FROSTMERE GAUNTLETS",
        outputItemId = "gear_frostmere_gauntlets",
        outputDisplayName = "Frostmere Gauntlets",
        materials = table.freeze({
            material_ember_moss = 2,
            material_thawed_iron = 6,
        }),
    }),
    recipe_frostmere_boots = table.freeze({
        id = "recipe_frostmere_boots",
        displayName = "FROSTMERE BOOTS",
        outputItemId = "gear_frostmere_boots",
        outputDisplayName = "Frostmere Boots",
        materials = table.freeze({
            material_aurora_salt = 2,
            material_frostmere_wool = 6,
        }),
    }),
    recipe_frostmere_treads = table.freeze({
        id = "recipe_frostmere_treads",
        displayName = "FROSTMERE TREADS",
        outputItemId = "gear_frostmere_treads",
        outputDisplayName = "Frostmere Treads",
        materials = table.freeze({
            material_ember_moss = 2,
            material_thawed_iron = 6,
        }),
    }),
    recipe_frostmere_token = table.freeze({
        id = "recipe_frostmere_token",
        displayName = "FROSTMERE TOKEN",
        outputItemId = "gear_frostmere_token",
        outputDisplayName = "Frostmere Token",
        materials = table.freeze({
            material_aurora_salt = 2,
            material_frostmere_wool = 6,
        }),
    }),
    recipe_frostmere_seal = table.freeze({
        id = "recipe_frostmere_seal",
        displayName = "FROSTMERE SEAL",
        outputItemId = "gear_frostmere_seal",
        outputDisplayName = "Frostmere Seal",
        materials = table.freeze({
            material_ember_moss = 2,
            material_thawed_iron = 6,
        }),
    }),
    recipe_tier_bow = table.freeze({
        id = "recipe_tier_bow",
        displayName = "TIER BOW",
        outputItemId = "gear_tier_bow",
        outputDisplayName = "Tier Bow",
        materials = table.freeze({
            material_cindersteel = 7,
            material_memory_glass = 5,
        }),
    }),
    recipe_kiln_maul = table.freeze({
        id = "recipe_kiln_maul",
        displayName = "KILN MAUL",
        outputItemId = "gear_kiln_maul",
        outputDisplayName = "Kiln Maul",
        materials = table.freeze({
            material_cindersteel = 7,
            material_memory_glass = 5,
        }),
    }),
    recipe_procession_lance = table.freeze({
        id = "recipe_procession_lance",
        displayName = "PROCESSION LANCE",
        outputItemId = "gear_procession_lance",
        outputDisplayName = "Procession Lance",
        materials = table.freeze({
            material_cindersteel = 7,
            material_memory_glass = 5,
        }),
    }),
    recipe_cinder_sling = table.freeze({
        id = "recipe_cinder_sling",
        displayName = "CINDER SLING",
        outputItemId = "gear_cinder_sling",
        outputDisplayName = "Cinder Sling",
        materials = table.freeze({
            material_cindersteel = 7,
            material_memory_glass = 5,
        }),
    }),
    recipe_memory_edge = table.freeze({
        id = "recipe_memory_edge",
        displayName = "MEMORY EDGE",
        outputItemId = "gear_memory_edge",
        outputDisplayName = "Memory Edge",
        materials = table.freeze({
            material_cindersteel = 7,
            material_memory_glass = 5,
        }),
    }),
    recipe_bailiff_cudgel = table.freeze({
        id = "recipe_bailiff_cudgel",
        displayName = "BAILIFF CUDGEL",
        outputItemId = "gear_bailiff_cudgel",
        outputDisplayName = "Bailiff Cudgel",
        materials = table.freeze({
            material_cindersteel = 7,
            material_memory_glass = 5,
        }),
    }),
    recipe_cinderfall_cowl = table.freeze({
        id = "recipe_cinderfall_cowl",
        displayName = "CINDERFALL COWL",
        outputItemId = "gear_cinderfall_cowl",
        outputDisplayName = "Cinderfall Cowl",
        materials = table.freeze({
            material_ash_silk = 7,
            material_crown_coal = 2,
        }),
    }),
    recipe_cinderfall_helm = table.freeze({
        id = "recipe_cinderfall_helm",
        displayName = "CINDERFALL HELM",
        outputItemId = "gear_cinderfall_helm",
        outputDisplayName = "Cinderfall Helm",
        materials = table.freeze({
            material_cindersteel = 7,
            material_kiln_pearl = 2,
        }),
    }),
    recipe_cinderfall_coat = table.freeze({
        id = "recipe_cinderfall_coat",
        displayName = "CINDERFALL COAT",
        outputItemId = "gear_cinderfall_coat",
        outputDisplayName = "Cinderfall Coat",
        materials = table.freeze({
            material_ash_silk = 7,
            material_crown_coal = 2,
        }),
    }),
    recipe_cinderfall_plate = table.freeze({
        id = "recipe_cinderfall_plate",
        displayName = "CINDERFALL PLATE",
        outputItemId = "gear_cinderfall_plate",
        outputDisplayName = "Cinderfall Plate",
        materials = table.freeze({
            material_cindersteel = 7,
            material_kiln_pearl = 2,
        }),
    }),
    recipe_cinderfall_wraps = table.freeze({
        id = "recipe_cinderfall_wraps",
        displayName = "CINDERFALL WRAPS",
        outputItemId = "gear_cinderfall_wraps",
        outputDisplayName = "Cinderfall Wraps",
        materials = table.freeze({
            material_ash_silk = 7,
            material_crown_coal = 2,
        }),
    }),
    recipe_cinderfall_gauntlets = table.freeze({
        id = "recipe_cinderfall_gauntlets",
        displayName = "CINDERFALL GAUNTLETS",
        outputItemId = "gear_cinderfall_gauntlets",
        outputDisplayName = "Cinderfall Gauntlets",
        materials = table.freeze({
            material_cindersteel = 7,
            material_kiln_pearl = 2,
        }),
    }),
    recipe_cinderfall_boots = table.freeze({
        id = "recipe_cinderfall_boots",
        displayName = "CINDERFALL BOOTS",
        outputItemId = "gear_cinderfall_boots",
        outputDisplayName = "Cinderfall Boots",
        materials = table.freeze({
            material_ash_silk = 7,
            material_crown_coal = 2,
        }),
    }),
    recipe_cinderfall_treads = table.freeze({
        id = "recipe_cinderfall_treads",
        displayName = "CINDERFALL TREADS",
        outputItemId = "gear_cinderfall_treads",
        outputDisplayName = "Cinderfall Treads",
        materials = table.freeze({
            material_cindersteel = 7,
            material_kiln_pearl = 2,
        }),
    }),
    recipe_cinderfall_token = table.freeze({
        id = "recipe_cinderfall_token",
        displayName = "CINDERFALL TOKEN",
        outputItemId = "gear_cinderfall_token",
        outputDisplayName = "Cinderfall Token",
        materials = table.freeze({
            material_ash_silk = 7,
            material_crown_coal = 2,
        }),
    }),
    recipe_cinderfall_seal = table.freeze({
        id = "recipe_cinderfall_seal",
        displayName = "CINDERFALL SEAL",
        outputItemId = "gear_cinderfall_seal",
        outputDisplayName = "Cinderfall Seal",
        materials = table.freeze({
            material_cindersteel = 7,
            material_kiln_pearl = 2,
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
