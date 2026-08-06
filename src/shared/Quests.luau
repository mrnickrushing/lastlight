--!strict

local QuestCatalog = require("./QuestCatalog")

local Quests = {}

export type Signals = {
    nightsSurvived: number,
    craftedItems: number,
    bramblewakeSettlements: number,
    -- Milestone 7's resident quests. Every one of these is derived from
    -- something the profile already stores, so no new tracking rides
    -- along with the new residents.
    buildingsRaised: number,
    decorationsPlaced: number,
    gearTraits: number,
    materialsBanked: number,
    residentsBonded: number,
}

local function currentValue(kind: string, signals: Signals): number
    if kind == "survive_nights" then
        return signals.nightsSurvived
    elseif kind == "craft_items" then
        return signals.craftedItems
    elseif kind == "bramblewake_settlements" then
        return signals.bramblewakeSettlements
    elseif kind == "buildings_raised" then
        return signals.buildingsRaised
    elseif kind == "decorations_placed" then
        return signals.decorationsPlaced
    elseif kind == "gear_traits" then
        return signals.gearTraits
    elseif kind == "materials_banked" then
        return signals.materialsBanked
    elseif kind == "residents_bonded" then
        return signals.residentsBonded
    end
    return 0
end

function Quests.default(): { [string]: boolean }
    return {}
end

function Quests.normalizeClaimed(value: any): { [string]: boolean }
    local claimed: { [string]: boolean } = {}
    if type(value) ~= "table" then
        return claimed
    end
    for questId, isClaimed in value do
        if QuestCatalog.isValid(questId) and isClaimed == true then
            claimed[questId] = true
        end
    end
    return claimed
end

-- Progress is always read live from `signals`, never stored, so a quest
-- that briefly regresses (e.g. crafting an item and then using it up)
-- doesn't lose credit once already claimed — only the claimed set persists.
function Quests.progress(questId: string, signals: Signals): (number, number, boolean)
    if not QuestCatalog.isValid(questId) then
        return 0, 0, false
    end
    local quest = QuestCatalog.get(questId) :: QuestCatalog.Quest
    local current = currentValue(quest.objective.kind, signals)
    local threshold = quest.objective.threshold
    return current, threshold, current >= threshold
end

function Quests.snapshot(claimed: { [string]: boolean }, signals: Signals): { any }
    local result = {}
    for _, quest in QuestCatalog.list() do
        local current, threshold, complete = Quests.progress(quest.id, signals)
        table.insert(result, {
            claimed = claimed[quest.id] == true,
            complete = complete,
            displayName = quest.displayName,
            id = quest.id,
            progress = current,
            threshold = threshold,
        })
    end
    return result
end

-- Silently claims every not-yet-claimed quest whose objective is currently
-- met, granting each one's material reward. Called opportunistically after
-- any action that could move a signal (a night completing, a craft
-- succeeding, an expedition settling) rather than through an accept step.
-- Resident quest-givers surface this progress and its story context, so a quest that's already
-- satisfiable claims itself the moment it's checked.
function Quests.checkAndClaim(
    claimed: { [string]: boolean },
    materials: { [string]: number },
    signals: Signals
): ({ [string]: boolean }, { [string]: number }, { any })
    local claimedResults = {}
    local nextClaimed = claimed
    local nextMaterials = materials

    for _, quest in QuestCatalog.list() do
        if claimed[quest.id] ~= true then
            local _current, _threshold, complete = Quests.progress(quest.id, signals)
            if complete then
                if nextClaimed == claimed then
                    nextClaimed = table.clone(claimed)
                end
                if nextMaterials == materials then
                    nextMaterials = table.clone(materials)
                end
                nextClaimed[quest.id] = true
                nextMaterials[quest.reward.materialId] = (
                    nextMaterials[quest.reward.materialId] or 0
                ) + quest.reward.amount
                table.insert(claimedResults, {
                    displayName = quest.displayName,
                    questId = quest.id,
                    reward = table.clone(quest.reward),
                })
            end
        end
    end

    return nextClaimed, nextMaterials, claimedResults
end

return table.freeze(Quests)
