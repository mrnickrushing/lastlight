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
})

local DEFINITIONS: { [string]: Quest } = {
    quest_survive_three_nights = table.freeze({
        id = "quest_survive_three_nights",
        displayName = "THREE NIGHTS SURVIVED",
        objective = table.freeze({ kind = "survive_nights", threshold = 3 }),
        reward = table.freeze({ materialId = "material_heartwood", amount = 5 }),
    }),
    quest_first_craft = table.freeze({
        id = "quest_first_craft",
        displayName = "FIRST CRAFT",
        objective = table.freeze({ kind = "craft_items", threshold = 1 }),
        reward = table.freeze({ materialId = "material_amber_sap", amount = 3 }),
    }),
    quest_bramblewake_veteran = table.freeze({
        id = "quest_bramblewake_veteran",
        displayName = "BRAMBLEWAKE VETERAN",
        objective = table.freeze({ kind = "bramblewake_settlements", threshold = 3 }),
        reward = table.freeze({ materialId = "material_brightcap", amount = 3 }),
    }),

    -- Hesper kept her tools when she lost everything else, and measures
    -- people by whether they keep theirs.
    quest_delve_smith = table.freeze({
        id = "quest_delve_smith",
        displayName = "A SMITH'S MEASURE",
        objective = table.freeze({ kind = "gear_traits", threshold = 3 }),
        reward = table.freeze({ materialId = "material_heartwood", amount = 6 }),
    }),
    -- Odell hauled for a mine that stopped paying; a full store is the
    -- only thing that makes him sit down.
    quest_rail_keeper = table.freeze({
        id = "quest_rail_keeper",
        displayName = "THE STORES ARE FULL",
        objective = table.freeze({ kind = "materials_banked", threshold = 60 }),
        reward = table.freeze({ materialId = "material_spring_clay", amount = 4 }),
    }),
    -- Junie counts nights the way other people count money.
    quest_lamp_trimmer = table.freeze({
        id = "quest_lamp_trimmer",
        displayName = "SEVEN LIT NIGHTS",
        objective = table.freeze({ kind = "survive_nights", threshold = 7 }),
        reward = table.freeze({ materialId = "material_amber_sap", amount = 5 }),
    }),
    -- Bartram fed a hundred people on nothing and still thinks the pantry
    -- is short; he is satisfied by a town that builds its own kitchen.
    quest_deep_cook = table.freeze({
        id = "quest_deep_cook",
        displayName = "SOMEWHERE TO COOK",
        objective = table.freeze({ kind = "buildings_raised", threshold = 4 }),
        reward = table.freeze({ materialId = "material_brightcap", amount = 4 }),
    }),

    -- Saoirse's ledger recorded names out and names back. She wants to
    -- see a column that balances.
    quest_ferry_ledger = table.freeze({
        id = "quest_ferry_ledger",
        displayName = "NAMES OUT, NAMES BACK",
        objective = table.freeze({ kind = "bramblewake_settlements", threshold = 8 }),
        reward = table.freeze({ materialId = "material_heartwood", amount = 8 }),
    }),
    -- Dabbler left a woven figure for every house the water took, and
    -- would rather this town be decorated than remembered.
    quest_reed_weaver = table.freeze({
        id = "quest_reed_weaver",
        displayName = "SOMETHING WOVEN",
        objective = table.freeze({ kind = "decorations_placed", threshold = 3 }),
        reward = table.freeze({ materialId = "material_meadow_fiber", amount = 6 }),
    }),
    -- Marek read glass for a living and knows most people never look
    -- twice at what they carry.
    quest_glass_reader = table.freeze({
        id = "quest_glass_reader",
        displayName = "LOOK TWICE",
        objective = table.freeze({ kind = "craft_items", threshold = 6 }),
        reward = table.freeze({ materialId = "material_amber_sap", amount = 6 }),
    }),
    -- Lissen still counts heads at dusk. Bonds are how she counts.
    quest_fen_healer = table.freeze({
        id = "quest_fen_healer",
        displayName = "COUNT EVERY HEAD",
        objective = table.freeze({ kind = "residents_bonded", threshold = 3 }),
        reward = table.freeze({ materialId = "material_brightcap", amount = 6 }),
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
