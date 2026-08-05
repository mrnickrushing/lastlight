--!strict

local TownProgression = {}

export type Consequence = {
    tier: number,
    title: string,
    detail: string,
    decision: string?,
    wardenOutcome: string?,
    landscapeKind: string,
    memorialKind: string,
    growthStage: number,
    buildingStages: { [string]: number },
    residentIds: { string },
}

--[[
    The tier at which each later building first breaks ground.

    The five original buildings keep their own hand-written curves below: they
    are the survival core and their exact staging is pinned by tests. Everything
    added for the sixteen-building town is declared here instead, because eleven
    more bespoke expressions would be eleven more things to get subtly wrong.

    A town fills in the order it would actually need things. Defence and food
    come first, because those are what a settlement that survives its nights
    wants next. Production follows once there is something to protect. The
    fourth-tier group is the long tail a town only reaches after ten nights, so
    the last thing a player unlocks is the stage they celebrate on.
]]
local BUILDING_FIRST_TIER: { [string]: number } = {
    building_guardhouse = 1,
    building_kitchen = 1,

    building_sawmill = 2,
    building_forge = 2,
    building_watchtower = 2,
    building_market = 2,

    building_celebration_stage = 3,
    building_engineer_yard = 3,
    building_trade_post = 3,
    building_trapworks = 3,
    building_waterworks = 3,
}

--[[
    How much of each material the town's stores can hold. Tier is the only
    input on purpose: storage is a thing the town grows, not a stat a player
    buys. Tier 0 starts snug enough that a few good expeditions press against
    it, and each tier earns real headroom.
]]
function TownProgression.storageCapForTier(tier: number): number
    return 80 + math.clamp(math.floor(tonumber(tier) or 0), 0, 5) * 60
end

local function buildingStages(tier: number): { [string]: number }
    -- Stage zero is a readable construction site, while stages one through
    -- three are increasingly complete buildings. Core services arrive first;
    -- the inn opens only after the town has survived enough nights to support
    -- visitors instead of appearing fully formed on a fresh save.
    local stages = {
        building_first_lantern = math.max(1, tier),
        building_archive = tier,
        building_town_board = math.max(1, tier),
        building_workbench = math.max(1, tier),
        building_inn = math.max(0, tier - 1),
    }

    for buildingId, firstTier in BUILDING_FIRST_TIER do
        stages[buildingId] = math.clamp(tier - firstTier + 1, 0, 3)
    end

    return stages
end

function TownProgression.buildingIds(): { string }
    local ids = {
        "building_first_lantern",
        "building_archive",
        "building_town_board",
        "building_workbench",
        "building_inn",
    }
    for buildingId in BUILDING_FIRST_TIER do
        table.insert(ids, buildingId)
    end
    table.sort(ids)
    return ids
end

local function residentIds(tier: number): { string }
    if tier < 1 then
        return {}
    end
    -- Mara is present from the tutorial and is built separately. Chapter one
    -- brings the remaining Bramblewake residents home together, completing
    -- the vertical slice's four-person town cast.
    return {
        "npc_tomas_reed",
        "npc_pip_wren",
        "npc_ena_moss",
    }
end

function TownProgression.resolve(profile: any): Consequence
    local chapter = if type(profile) == "table" and type(profile.story) == "table"
        then profile.story.chapterOne
        else nil
    local town = if type(profile) == "table" and type(profile.town) == "table"
        then profile.town
        else nil
    local nights = if town ~= nil and type(town.nightNumber) == "number"
        then town.nightNumber
        else 1
    local tier = math.clamp(math.floor(math.max(0, nights - 1) / 3), 0, 3)
    local decision = if type(chapter) == "table" then chapter.decision else nil
    local outcome = if type(chapter) == "table" then chapter.wardenOutcome else nil
    if type(chapter) == "table" and chapter.status == "complete" then
        tier = math.max(1, tier)
    end
    local title = if decision == "restore_farmland"
        then "FARMLAND RENEWED"
        elseif decision == "wild_regrowth" then "WILD REGROWTH"
        elseif decision == "shared_agroforest" then "SHARED AGROFOREST"
        else "EMBERHOLLOW AWAKENS"
    local detail = if outcome == "preserved"
        then "The Warden's mercy keeps the old paths open."
        elseif outcome == "scarred" then "Scored roots mark a harder road through the forest."
        elseif outcome == "harmed" then "Broken antlers leave the town under a watchful shadow."
        else "Every safe night makes the lantern town stronger."
    local landscapeKind = if decision == "restore_farmland"
        then "cultivated_fields"
        elseif decision == "wild_regrowth" then "living_grove"
        elseif decision == "shared_agroforest" then "community_orchard"
        else "seed_ground"
    local memorialKind = if outcome == "preserved"
        then "living_antlers"
        elseif outcome == "scarred" then "scarred_antlers"
        elseif outcome == "harmed" then "broken_antlers"
        else "unmarked_stone"
    return {
        tier = tier,
        title = title,
        detail = detail,
        decision = decision,
        wardenOutcome = outcome,
        landscapeKind = landscapeKind,
        memorialKind = memorialKind,
        growthStage = tier,
        buildingStages = buildingStages(tier),
        residentIds = residentIds(tier),
    }
end

-- Emberhollow is one shared server world even though progression is stored per
-- player. Reconcile arrivals monotonically so a fresh or lower-tier player can
-- never tear down buildings and residents that are already visible. The first
-- resolved chapter consequence seen by the server owns the shared landscape;
-- later conflicting personal choices remain in those players' profiles and
-- snapshots without making the physical world flicker between joins.
function TownProgression.merge(current: any, incoming: Consequence): Consequence
    if type(current) ~= "table" then
        return incoming
    end

    local currentTier = math.clamp(math.floor(tonumber(current.tier) or 0), 0, 3)
    local incomingTier = math.clamp(math.floor(tonumber(incoming.tier) or 0), 0, 3)
    local base = if incomingTier > currentTier then incoming else current
    local result = table.clone(base)
    result.tier = math.max(currentTier, incomingTier)
    result.growthStage = math.max(
        math.clamp(math.floor(tonumber(current.growthStage) or 0), 0, 3),
        math.clamp(math.floor(tonumber(incoming.growthStage) or 0), 0, 3)
    )

    local mergedStages = {}
    -- Read from the shared list rather than a copy of it: a building added to
    -- the town but forgotten here would silently stop reconciling between
    -- players, which looks like the building flickering as people join.
    for _, buildingId in TownProgression.buildingIds() do
        local currentStages = if type(current.buildingStages) == "table"
            then current.buildingStages
            else {}
        local incomingStages = if type(incoming.buildingStages) == "table"
            then incoming.buildingStages
            else {}
        mergedStages[buildingId] = math.max(
            math.clamp(math.floor(tonumber(currentStages[buildingId]) or 0), 0, 3),
            math.clamp(math.floor(tonumber(incomingStages[buildingId]) or 0), 0, 3)
        )
    end
    result.buildingStages = mergedStages

    local residentSet = {}
    for _, source in { current.residentIds, incoming.residentIds } do
        if type(source) == "table" then
            for _, residentId in source do
                if type(residentId) == "string" then
                    residentSet[residentId] = true
                end
            end
        end
    end
    local mergedResidents = {}
    for _, residentId in { "npc_tomas_reed", "npc_pip_wren", "npc_ena_moss" } do
        if residentSet[residentId] == true then
            table.insert(mergedResidents, residentId)
        end
    end
    result.residentIds = mergedResidents

    local consequenceSource = if type(current.decision) == "string"
        then current
        elseif type(incoming.decision) == "string" then incoming
        else base
    result.title = consequenceSource.title
    result.detail = consequenceSource.detail
    result.decision = consequenceSource.decision
    result.wardenOutcome = consequenceSource.wardenOutcome
    result.landscapeKind = consequenceSource.landscapeKind
    result.memorialKind = consequenceSource.memorialKind
    return result :: Consequence
end

return table.freeze(TownProgression)
