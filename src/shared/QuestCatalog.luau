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

local ORDER = table.freeze({
    "quest_survive_three_nights",
    "quest_first_craft",
    "quest_bramblewake_veteran",
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
