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
    --[[
        The Reach's and the Vale's residents. Both of these are counts of
        things the profile already stores -- resolved chapters and
        recovered fragments -- for the same reason the milestone-7 group
        was: a resident quest must not be the thing that introduces a new
        piece of tracking, because then the quest owns a system and the
        system cannot be changed without the quest noticing.
    ]]
    chaptersResolved: number,
    fragmentsRecovered: number,
    --[[
        Keyed signals. The counts above answer "how many"; these answer
        "how many of that one", which is the difference between a quest
        that any activity satisfies and a quest that sends a player
        somewhere specific. An objective using one names its key, so the
        catalog stays the only place that decides what a quest is about.
    ]]
    fragmentsByRegion: { [string]: number },
    masteryByProfession: { [string]: number },
}

local function currentValue(objective: any, signals: Signals): number
    local kind = objective.kind
    if kind == "fragments_in_region" then
        return signals.fragmentsByRegion[tostring(objective.regionId)] or 0
    elseif kind == "profession_mastery" then
        return signals.masteryByProfession[tostring(objective.professionId)] or 0
    elseif kind == "survive_nights" then
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
    elseif kind == "chapters_resolved" then
        return signals.chaptersResolved
    elseif kind == "fragments_recovered" then
        return signals.fragmentsRecovered
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
--[[
    Whether a quest's arc has reached it yet. A stage whose predecessor is
    unclaimed is not merely hidden -- it does not progress either, so a
    player cannot satisfy stage three by accident while stage one is still
    open and then have both claim themselves in the same tick.
]]
function Quests.isUnlocked(questId: string, claimed: { [string]: boolean }): boolean
    local quest = QuestCatalog.get(questId)
    if quest == nil then
        return false
    end
    local requires = quest.requires
    if requires == nil then
        return true
    end
    return claimed[requires] == true
end

function Quests.progress(questId: string, signals: Signals): (number, number, boolean)
    if not QuestCatalog.isValid(questId) then
        return 0, 0, false
    end
    local quest = QuestCatalog.get(questId) :: QuestCatalog.Quest
    local current = currentValue(quest.objective, signals)
    local threshold = quest.objective.threshold
    return current, threshold, current >= threshold
end

function Quests.snapshot(claimed: { [string]: boolean }, signals: Signals): { any }
    local result = {}
    for _, quest in QuestCatalog.list() do
        local unlocked = Quests.isUnlocked(quest.id, claimed)
        local current, threshold, complete = Quests.progress(quest.id, signals)
        table.insert(result, {
            claimed = claimed[quest.id] == true,
            complete = complete and unlocked,
            displayName = quest.displayName,
            id = quest.id,
            locked = not unlocked,
            progress = if unlocked then current else 0,
            requires = quest.requires,
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
        --[[
            Unlock is judged against the set this pass started with, not
            the running one. Otherwise claiming stage one would unlock
            stage two inside the same loop and a player who had already
            satisfied everything would receive a whole arc's rewards in
            one tick without ever hearing the next request. One stage per
            arc per pass; the next pass takes the next one.
        ]]
        if claimed[quest.id] ~= true and Quests.isUnlocked(quest.id, claimed) then
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
