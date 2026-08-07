--!strict

local QuestCatalog = {}

export type Objective = {
    kind: string,
    threshold: number,
}

export type Reward = {
    materialId: string,
    amount: number,
}

export type Quest = {
    --[[
        Arc support. `requires` is the quest before this one in the same
        person's arc: until that is claimed this one does not progress, is
        not offered, and cannot claim itself. `residentId` is who is
        asking, so the dialogue can find someone's current stage without
        the roster holding a second list that would drift from this one.
    ]]
    requires: string?,
    residentId: string?,
    id: string,
    displayName: string,
    objective: Objective,
    reward: Reward,
}

--[[
    Chapter I's three come first and keep their exact ids, thresholds and
    rewards. The eight that follow belong to the residents Milestone 7
    brings back from the Delve and the Fen -- each one asks for something
    that resident would actually care about, and every objective is
    computed from facts the profile already records.
]]
local ORDER = table.freeze({
    "quest_survive_three_nights",
    "quest_first_craft",
    "quest_bramblewake_veteran",
    -- Chapter one's three ask more than once. They are present from the
    -- first dawn and stay for the whole game, so they are the residents
    -- with the runway for an arc; everyone else arrives with less of it.
    "quest_tomas_second_bench",
    "quest_tomas_full_house",
    "quest_pip_further_roads",
    "quest_pip_every_night",
    "quest_ena_first_growth",
    "quest_ena_the_archive",

    -- Ironroot Delve residents
    "quest_delve_smith",
    "quest_rail_keeper",
    "quest_lamp_trimmer",
    "quest_deep_cook",
    -- Mireglass Fen residents
    "quest_ferry_ledger",
    "quest_reed_weaver",
    "quest_glass_reader",
    "quest_fen_healer",
    -- Tempest Reach residents
    "quest_signal_watch",
    "quest_ropewalk_hands",
    "quest_harbour_ledger",
    "quest_salvage_runs",
    -- Frostmere Vale residents
    "quest_bell_keeping",
    "quest_vale_nursing",
    "quest_cold_stores",
    "quest_almshouse_doors",
    -- Cinderfall Crown residents
    "quest_glass_hands",
    "quest_kept_record",
    "quest_named_stones",
    "quest_long_timber",
    -- After the Hollow
    "quest_keepers_return",
    "quest_deep_water",
    "quest_full_house",
    "quest_last_ward",
})

local DEFINITIONS: { [string]: Quest } = {
    quest_survive_three_nights = table.freeze({
        id = "quest_survive_three_nights",
        residentId = "npc_pip_wren",
        displayName = "THREE NIGHTS SURVIVED",
        objective = table.freeze({ kind = "survive_nights", threshold = 3 }),
        reward = table.freeze({ materialId = "material_heartwood", amount = 5 }),
    }),
    quest_first_craft = table.freeze({
        id = "quest_first_craft",
        residentId = "npc_tomas_reed",
        displayName = "FIRST CRAFT",
        objective = table.freeze({ kind = "craft_items", threshold = 1 }),
        reward = table.freeze({ materialId = "material_amber_sap", amount = 3 }),
    }),
    quest_bramblewake_veteran = table.freeze({
        id = "quest_bramblewake_veteran",
        residentId = "npc_ena_moss",
        displayName = "BRAMBLEWAKE VETERAN",
        objective = table.freeze({ kind = "bramblewake_settlements", threshold = 3 }),
        reward = table.freeze({ materialId = "material_brightcap", amount = 3 }),
    }),

    -- Hesper kept her tools when she lost everything else, and measures
    -- people by whether they keep theirs.
    quest_delve_smith = table.freeze({
        id = "quest_delve_smith",
        residentId = "npc_hesper_vane",
        displayName = "A SMITH'S MEASURE",
        objective = table.freeze({ kind = "gear_traits", threshold = 3 }),
        reward = table.freeze({ materialId = "material_heartwood", amount = 6 }),
    }),
    -- Odell hauled for a mine that stopped paying; a full store is the
    -- only thing that makes him sit down.
    quest_rail_keeper = table.freeze({
        id = "quest_rail_keeper",
        residentId = "npc_odell_crane",
        displayName = "THE STORES ARE FULL",
        objective = table.freeze({ kind = "materials_banked", threshold = 60 }),
        reward = table.freeze({ materialId = "material_spring_clay", amount = 4 }),
    }),
    -- Junie counts nights the way other people count money.
    quest_lamp_trimmer = table.freeze({
        id = "quest_lamp_trimmer",
        residentId = "npc_junie_falk",
        displayName = "SEVEN LIT NIGHTS",
        objective = table.freeze({ kind = "survive_nights", threshold = 7 }),
        reward = table.freeze({ materialId = "material_amber_sap", amount = 5 }),
    }),
    -- Bartram fed a hundred people on nothing and still thinks the pantry
    -- is short; he is satisfied by a town that builds its own kitchen.
    quest_deep_cook = table.freeze({
        id = "quest_deep_cook",
        residentId = "npc_bartram_hoke",
        displayName = "SOMEWHERE TO COOK",
        objective = table.freeze({ kind = "buildings_raised", threshold = 4 }),
        reward = table.freeze({ materialId = "material_brightcap", amount = 4 }),
    }),

    -- Saoirse's ledger recorded names out and names back. She wants to
    -- see a column that balances.
    quest_ferry_ledger = table.freeze({
        id = "quest_ferry_ledger",
        residentId = "npc_saoirse_quill",
        displayName = "NAMES OUT, NAMES BACK",
        objective = table.freeze({ kind = "bramblewake_settlements", threshold = 8 }),
        reward = table.freeze({ materialId = "material_heartwood", amount = 8 }),
    }),
    -- Dabbler left a woven figure for every house the water took, and
    -- would rather this town be decorated than remembered.
    quest_reed_weaver = table.freeze({
        id = "quest_reed_weaver",
        residentId = "npc_wren_dabbler",
        displayName = "SOMETHING WOVEN",
        objective = table.freeze({ kind = "decorations_placed", threshold = 3 }),
        reward = table.freeze({ materialId = "material_meadow_fiber", amount = 6 }),
    }),
    -- Marek read glass for a living and knows most people never look
    -- twice at what they carry.
    quest_glass_reader = table.freeze({
        id = "quest_glass_reader",
        residentId = "npc_marek_still",
        displayName = "LOOK TWICE",
        objective = table.freeze({ kind = "craft_items", threshold = 6 }),
        reward = table.freeze({ materialId = "material_amber_sap", amount = 6 }),
    }),
    -- Lissen still counts heads at dusk. Bonds are how she counts.
    quest_fen_healer = table.freeze({
        id = "quest_fen_healer",
        residentId = "npc_lissen_ford",
        displayName = "COUNT EVERY HEAD",
        objective = table.freeze({ kind = "residents_bonded", threshold = 3 }),
        reward = table.freeze({ materialId = "material_brightcap", amount = 6 }),
    }),
    -- Isolde kept a light for ships that had already sunk. Nights lit is
    -- the only number she has ever trusted.
    quest_signal_watch = table.freeze({
        id = "quest_signal_watch",
        residentId = "npc_isolde_maren",
        displayName = "KEEP THE LIGHT",
        objective = table.freeze({ kind = "survive_nights", threshold = 14 }),
        reward = table.freeze({ materialId = "material_storm_glass", amount = 6 }),
    }),
    -- Cass makes rope, and rope is made by making a great deal of it.
    quest_ropewalk_hands = table.freeze({
        id = "quest_ropewalk_hands",
        residentId = "npc_cass_pell",
        displayName = "TWENTY GOOD LENGTHS",
        objective = table.freeze({ kind = "craft_items", threshold = 20 }),
        reward = table.freeze({ materialId = "material_salt_kelp", amount = 8 }),
    }),
    -- Alder ran a harbour's books until there was no harbour. He would
    -- like to see full stores once before he stops.
    quest_harbour_ledger = table.freeze({
        id = "quest_harbour_ledger",
        residentId = "npc_alder_kine",
        displayName = "THE STORES IN BLACK",
        objective = table.freeze({ kind = "materials_banked", threshold = 200 }),
        reward = table.freeze({ materialId = "material_ships_iron", amount = 6 }),
    }),
    -- Nell dives wrecks. She counts trips out and trips back, and only
    -- the second number goes in the book.
    quest_salvage_runs = table.freeze({
        id = "quest_salvage_runs",
        residentId = "npc_nell_barrow",
        displayName = "FOURTEEN TRIPS BACK",
        objective = table.freeze({ kind = "bramblewake_settlements", threshold = 14 }),
        reward = table.freeze({ materialId = "material_storm_glass", amount = 8 }),
    }),
    -- Brother Anselm rang for a valley that had stopped answering. What
    -- he wants now is the record of what happened kept.
    quest_bell_keeping = table.freeze({
        id = "quest_bell_keeping",
        residentId = "npc_anselm_rill",
        displayName = "WHAT THE BELLS REMEMBER",
        objective = table.freeze({ kind = "fragments_recovered", threshold = 4 }),
        reward = table.freeze({ materialId = "material_aurora_salt", amount = 6 }),
    }),
    -- Sister Ivy counted heads in a place where the count kept falling.
    -- Eight people who trust you is the number she stopped at.
    quest_vale_nursing = table.freeze({
        id = "quest_vale_nursing",
        residentId = "npc_ivy_thorn",
        displayName = "EIGHT WHO TRUST YOU",
        objective = table.freeze({ kind = "residents_bonded", threshold = 8 }),
        reward = table.freeze({ materialId = "material_ember_moss", amount = 8 }),
    }),
    -- Halvard kept a cold store through five winters of people asking him
    -- to open it early. He measures a town by what it has finished.
    quest_cold_stores = table.freeze({
        id = "quest_cold_stores",
        residentId = "npc_halvard_sunn",
        displayName = "EVERY CHAPTER CLOSED",
        objective = table.freeze({ kind = "chapters_resolved", threshold = 5 }),
        reward = table.freeze({ materialId = "material_thawed_iron", amount = 6 }),
    }),
    -- Maud gave her door away for years. She would like a town with
    -- twelve of them standing.
    quest_almshouse_doors = table.freeze({
        id = "quest_almshouse_doors",
        residentId = "npc_maud_ferrow",
        displayName = "TWELVE DOORS STANDING",
        objective = table.freeze({ kind = "buildings_raised", threshold = 12 }),
        reward = table.freeze({ materialId = "material_frostmere_wool", amount = 8 }),
    }),
    -- Sabine will not make anything shaped like a person. She will make
    -- forty of everything else.
    quest_glass_hands = table.freeze({
        id = "quest_glass_hands",
        residentId = "npc_sabine_ash",
        displayName = "FORTY HONEST THINGS",
        objective = table.freeze({ kind = "craft_items", threshold = 40 }),
        reward = table.freeze({ materialId = "material_memory_glass", amount = 8 }),
    }),
    -- Theo copied official names for thirty years. He wants the other kind.
    quest_kept_record = table.freeze({
        id = "quest_kept_record",
        residentId = "npc_theo_marl",
        displayName = "THE OTHER NAMES",
        objective = table.freeze({ kind = "fragments_recovered", threshold = 8 }),
        reward = table.freeze({ materialId = "material_ash_silk", amount = 8 }),
    }),
    -- Delia knows which statues were people, and would like the same to be
    -- true of this town before it needs to be.
    quest_named_stones = table.freeze({
        id = "quest_named_stones",
        residentId = "npc_delia_kass",
        displayName = "FOURTEEN NAMED",
        objective = table.freeze({ kind = "residents_bonded", threshold = 14 }),
        reward = table.freeze({ materialId = "material_cindersteel", amount = 8 }),
    }),
    -- Bran cuts them longer now, out of spite.
    quest_long_timber = table.freeze({
        id = "quest_long_timber",
        residentId = "npc_bran_holt",
        displayName = "TWENTY STANDING",
        objective = table.freeze({ kind = "buildings_raised", threshold = 20 }),
        reward = table.freeze({ materialId = "material_heartwood", amount = 12 }),
    }),
    -- Orin has been waiting since the first fragment. What he asks for is
    -- the whole story closed.
    quest_keepers_return = table.freeze({
        id = "quest_keepers_return",
        residentId = "npc_orin_vale",
        displayName = "THE KEEPER'S RETURN",
        objective = table.freeze({ kind = "chapters_resolved", threshold = 7 }),
        reward = table.freeze({ materialId = "material_crown_coal", amount = 12 }),
    }),
    -- Signe walked out of the Hollow behind you and has not explained it.
    quest_deep_water = table.freeze({
        id = "quest_deep_water",
        residentId = "npc_signe_marr",
        displayName = "FOUR HUNDRED IN STORE",
        objective = table.freeze({ kind = "materials_banked", threshold = 400 }),
        reward = table.freeze({ materialId = "material_kiln_pearl", amount = 8 }),
    }),
    -- Ruth ran the meetings before there was a town and intends to keep on.
    quest_full_house = table.freeze({
        id = "quest_full_house",
        residentId = "npc_ruth_calder",
        displayName = "A TOWN WORTH MEETING IN",
        objective = table.freeze({ kind = "decorations_placed", threshold = 8 }),
        reward = table.freeze({ materialId = "material_ember_moss", amount = 10 }),
    }),
    -- Edda builds wards for a road that no longer needs them.
    quest_last_ward = table.freeze({
        id = "quest_last_ward",
        residentId = "npc_edda_pyne",
        displayName = "THIRTY NIGHTS WARDED",
        objective = table.freeze({ kind = "survive_nights", threshold = 30 }),
        reward = table.freeze({ materialId = "material_thawed_iron", amount = 10 }),
    }),
    -- Tomas asked for one useful thing. Having got it, he wants a bench
    -- that has clearly been used.
    quest_tomas_second_bench = table.freeze({
        id = "quest_tomas_second_bench",
        displayName = "A BENCH WORTH THE NAME",
        objective = table.freeze({ kind = "craft_items", threshold = 12 }),
        requires = "quest_first_craft",
        residentId = "npc_tomas_reed",
        reward = table.freeze({ materialId = "material_heartwood", amount = 6 }),
    }),
    -- And the innkeeper's real ambition, which is not about the inn.
    quest_tomas_full_house = table.freeze({
        id = "quest_tomas_full_house",
        displayName = "EVERY BED FULL",
        objective = table.freeze({ kind = "residents_bonded", threshold = 10 }),
        requires = "quest_tomas_second_bench",
        residentId = "npc_tomas_reed",
        reward = table.freeze({ materialId = "material_amber_sap", amount = 10 }),
    }),
    -- Pip's second ask is the courier's: not survival, distance.
    quest_pip_further_roads = table.freeze({
        id = "quest_pip_further_roads",
        displayName = "THE ROADS FURTHER OUT",
        objective = table.freeze({ kind = "bramblewake_settlements", threshold = 6 }),
        requires = "quest_survive_three_nights",
        residentId = "npc_pip_wren",
        reward = table.freeze({ materialId = "material_meadow_fiber", amount = 6 }),
    }),
    -- Three weeks of nights posted before they arrived. Pip counts in
    -- nights nobody was surprised.
    quest_pip_every_night = table.freeze({
        id = "quest_pip_every_night",
        displayName = "A YEAR OF POSTED NIGHTS",
        objective = table.freeze({ kind = "survive_nights", threshold = 21 }),
        requires = "quest_pip_further_roads",
        residentId = "npc_pip_wren",
        reward = table.freeze({ materialId = "material_brightcap", amount = 10 }),
    }),
    -- Ena's second: the seedkeeper wants the town to look planted rather
    -- than merely standing.
    quest_ena_first_growth = table.freeze({
        id = "quest_ena_first_growth",
        displayName = "SOMETHING PLANTED",
        objective = table.freeze({ kind = "decorations_placed", threshold = 5 }),
        requires = "quest_bramblewake_veteran",
        residentId = "npc_ena_moss",
        reward = table.freeze({ materialId = "material_spring_clay", amount = 6 }),
    }),
    -- And her last, which is the archive's: she is the one who noticed
    -- the fragments were a story rather than a collection.
    quest_ena_the_archive = table.freeze({
        id = "quest_ena_the_archive",
        displayName = "WHAT THE FOREST KEPT",
        objective = table.freeze({ kind = "fragments_recovered", threshold = 6 }),
        requires = "quest_ena_first_growth",
        residentId = "npc_ena_moss",
        reward = table.freeze({ materialId = "material_amber_sap", amount = 12 }),
    }),
}

function QuestCatalog.isValid(id: any): boolean
    return type(id) == "string" and DEFINITIONS[id] ~= nil
end

function QuestCatalog.get(id: string): Quest?
    return DEFINITIONS[id]
end

function QuestCatalog.list(): { Quest }
    local result = {}
    for _, id in ORDER do
        table.insert(result, DEFINITIONS[id])
    end
    return result
end

return table.freeze(QuestCatalog)
