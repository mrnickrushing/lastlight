--!strict

local ChapterCatalog = require("./ChapterCatalog")
local ResidentRoster = require("./ResidentRoster")
local Strings = require("./Strings")

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

    -- Tiers four and five are the story's rather than the calendar's, and
    -- what they add is what a crew brought home rather than what a town
    -- outgrew. The Reach teaches signalling, cold storage and charity to a
    -- place that has been hoarding; the Vale teaches rope, bells and
    -- nursing to a place that has been burying.
    building_signal_house = 4,
    building_cold_store = 4,
    building_almshouse = 4,

    building_ropewalk = 5,
    building_bell_tower = 5,
    building_infirmary = 5,

    -- Tiers six and seven are the last two, and what they add is what a
    -- town does after the story rather than during it. The Crown teaches
    -- it to keep a record; the Hollow leaves it deciding what to do with
    -- a light it now understands.
    building_glassworks = 6,
    building_memorial_hall = 6,
    building_records_office = 6,

    building_lamp_house = 7,
    building_deep_well = 7,
    building_meeting_hall = 7,
}

--[[
    How much of each material the town's stores can hold. Tier is the only
    input on purpose: storage is a thing the town grows, not a stat a player
    buys. Tier 0 starts snug enough that a few good expeditions press against
    it, and each tier earns real headroom.
]]
function TownProgression.storageCapForTier(tier: number): number
    return 80 + math.clamp(math.floor(tonumber(tier) or 0), 0, 7) * 60
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

--[[
    Reads a chapter's completion straight off the profile's story table.
    TownProgression cannot ask SaveSchema (SaveSchema requires this
    module), so it applies the same test SaveSchema.normalize already
    guarantees holds for anything stored there.
]]
local function chapterComplete(story: any, chapterId: string): boolean
    if type(story) ~= "table" then
        return false
    end
    if chapterId == "chapter_one" then
        return type(story.chapterOne) == "table" and story.chapterOne.status == "complete"
    end
    local chapters = story.chapters
    if type(chapters) ~= "table" then
        return false
    end
    local record = chapters[chapterId]
    return type(record) == "table" and record.status == "complete"
end

local function reachedChapter(story: any): number
    local reached = 1
    for _, definition in ChapterCatalog.list() do
        if chapterComplete(story, definition.id) then
            reached = math.max(reached, definition.number + 1)
        end
    end
    return math.min(reached, #ChapterCatalog.Order)
end

--[[
    Who stands in town. Tier 0 is the pre-chapter tutorial town, empty of
    named residents; after that the cast is the story's, via the roster --
    chapter I's three, then the Delve's four, then the Fen's four. Mara is
    present from the tutorial and is built separately.
]]
local function residentIds(tier: number, story: any): { string }
    if tier < 1 then
        return {}
    end
    -- The finale's ending decides one resident: Orin is in town or he is
    -- still below, depending on what was done with the light.
    local finale = if type(story) == "table" then story.finale else nil
    local ending = if type(finale) == "table" and finale.status == "complete"
        then finale.ending
        else nil
    return ResidentRoster.idsForChapter(reachedChapter(story), ending)
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
    local story = if type(profile) == "table" then profile.story else nil
    --[[
        The town grows to tier 7, but the road there is the story's:
        nights alone still cap at 3, exactly as they always have
        (spec-pinned). Stilling the Bellows Maw lifts the ceiling to 4,
        lowering the harbour's tide lifts it to 5, the Crown lifts it to 6
        and the Hollow to 7. Each resolved chapter also floors the tier,
        so coming home from a chapter always shows something changed.
    ]]
    local ceiling = if chapterComplete(story, "chapter_seven")
        then 7
        elseif chapterComplete(story, "chapter_six") then 6
        elseif chapterComplete(story, "chapter_four") then 5
        elseif chapterComplete(story, "chapter_two") then 4
        else 3
    local tier = math.clamp(math.floor(math.max(0, nights - 1) / 3), 0, ceiling)
    local decision = if type(chapter) == "table" then chapter.decision else nil
    local outcome = if type(chapter) == "table" then chapter.wardenOutcome else nil
    if type(chapter) == "table" and chapter.status == "complete" then
        tier = math.max(1, tier)
    end
    if chapterComplete(story, "chapter_two") then
        tier = math.max(2, tier)
    end
    if chapterComplete(story, "chapter_three") then
        tier = math.max(3, tier)
    end
    if chapterComplete(story, "chapter_four") then
        tier = math.max(4, tier)
    end
    if chapterComplete(story, "chapter_five") then
        tier = math.max(5, tier)
    end
    if chapterComplete(story, "chapter_six") then
        tier = math.max(6, tier)
    end
    if chapterComplete(story, "chapter_seven") then
        tier = math.max(7, tier)
    end
    local title = if decision == "restore_farmland"
        then Strings.get("town.farmland_renewed")
        elseif decision == "wild_regrowth" then Strings.get("town.wild_regrowth")
        elseif decision == "shared_agroforest" then Strings.get("town.shared_agroforest")
        else Strings.get("toast.emberhollow_awakens")
    local detail = if outcome == "preserved"
        then Strings.get("town.the_warden_s_mercy_keeps_the")
        elseif outcome == "scarred" then Strings.get("town.scored_roots_mark_a_harder_road")
        elseif outcome == "harmed" then Strings.get("town.broken_antlers_leave_the_town_under")
        else Strings.get("town.every_safe_night_makes_the_lantern")
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
        growthStage = math.min(tier, 3),
        buildingStages = buildingStages(tier),
        residentIds = residentIds(tier, story),
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

    local currentTier = math.clamp(math.floor(tonumber(current.tier) or 0), 0, 4)
    local incomingTier = math.clamp(math.floor(tonumber(incoming.tier) or 0), 0, 4)
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
    -- Rebuilt in roster order so every joiner sees the same cast in the
    -- same order. This list used to hardcode chapter I's three, which
    -- silently evicted later arrivals from a merged town.
    local mergedResidents = {}
    for _, residentId in ResidentRoster.Order do
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
