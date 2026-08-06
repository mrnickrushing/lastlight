--!strict

--[[
    The chapters, and what each one asks the player to decide.

    Chapter I shipped as a special case: its record lives at
    story.chapterOne, its decision set and Warden outcome are validated by
    their own tables in SaveSchema, and half a dozen systems read it
    directly. That was right for one chapter and wrong for seven, so
    chapters II onward are described here instead -- id, region, the boss
    that closes them, the decision they ask, and the outcomes their boss
    can end on -- and stored uniformly under story.chapters.

    Chapter I is listed too, so anything that wants to reason about the
    story as a whole (which resident has arrived, which region is open,
    what the town remembers) can read one list. Its record is still read
    from its original home; this catalog describes it, it does not move it.
]]

local ChapterCatalog = {}

export type Chapter = {
    id: string,
    number: number,
    displayName: string,
    regionId: string,
    bossId: string,
    -- What the chapter asks the player to decide, in the player's words.
    decisionPrompt: string,
    -- The decisions a player can record for this chapter.
    decisions: { string },
    -- The outcomes its boss can end on, which the decision usually shapes.
    outcomes: { string },
    -- The chapter that must be complete before this one can be resolved.
    requires: string?,
}

local function chapter(definition: Chapter): Chapter
    return table.freeze({
        id = definition.id,
        number = definition.number,
        displayName = definition.displayName,
        regionId = definition.regionId,
        bossId = definition.bossId,
        decisionPrompt = definition.decisionPrompt,
        decisions = table.freeze(definition.decisions),
        outcomes = table.freeze(definition.outcomes),
        requires = definition.requires,
    })
end

local ORDER = table.freeze({ "chapter_one", "chapter_two", "chapter_three" })

local DEFINITIONS: { [string]: Chapter } = {
    chapter_one = chapter({
        id = "chapter_one",
        number = 1,
        displayName = "THE LANTERN ROAD",
        regionId = "region_bramblewake",
        bossId = "boss_warden_stag",
        decisionPrompt = "WHAT GROWS BACK WHERE THE ROOTS WERE",
        decisions = { "restore_farmland", "wild_regrowth", "shared_agroforest" },
        outcomes = { "preserved", "scarred", "harmed" },
        requires = nil,
    }),
    chapter_two = chapter({
        id = "chapter_two",
        number = 2,
        displayName = "THE DELVE BELOW",
        regionId = "region_ironroot",
        bossId = "boss_bellows_maw",
        --[[
            The Maw's vent is the decision, and it is made with a wheel
            rather than a menu: the drifts are quick and the Delve's air
            pays for it, the flooded stope is slow and clean. What a crew
            reached for is what the chapter records.
        ]]
        decisionPrompt = "WHERE THE PRESSURE WENT",
        decisions = { "vent_drifts", "vent_stope", "vent_both" },
        outcomes = { "cleared", "fouled", "mixed" },
        requires = "chapter_one",
    }),
    chapter_three = chapter({
        id = "chapter_three",
        number = 3,
        displayName = "THE DROWNED COUNTRY",
        regionId = "region_mireglass",
        bossId = "boss_lantern_witch",
        --[[
            The Witch asks to be sealed rather than broken, and the seal
            only holds if it is given. Spending her copies to get there is
            the cost the ending remembers.
        ]]
        decisionPrompt = "WHAT WAS SPENT TO REACH HER",
        decisions = { "spared_copies", "spent_copies", "refused_her" },
        outcomes = { "sealed", "bound", "broken" },
        requires = "chapter_two",
    }),
}

ChapterCatalog.Order = ORDER

function ChapterCatalog.get(chapterId: any): Chapter?
    return if type(chapterId) == "string" then DEFINITIONS[chapterId] else nil
end

function ChapterCatalog.require(chapterId: string): Chapter
    local definition = DEFINITIONS[chapterId]
    assert(definition ~= nil, string.format("unknown chapter ID %q", chapterId))
    return definition
end

function ChapterCatalog.list(): { Chapter }
    local result: { Chapter } = {}
    for _, chapterId in ORDER do
        table.insert(result, DEFINITIONS[chapterId])
    end
    return result
end

function ChapterCatalog.isDecision(chapterId: any, decision: any): boolean
    local definition = ChapterCatalog.get(chapterId)
    if definition == nil then
        return false
    end
    for _, candidate in definition.decisions do
        if candidate == decision then
            return true
        end
    end
    return false
end

function ChapterCatalog.isOutcome(chapterId: any, outcome: any): boolean
    local definition = ChapterCatalog.get(chapterId)
    if definition == nil then
        return false
    end
    for _, candidate in definition.outcomes do
        if candidate == outcome then
            return true
        end
    end
    return false
end

function ChapterCatalog.forRegion(regionId: any): Chapter?
    for _, chapterId in ORDER do
        if DEFINITIONS[chapterId].regionId == regionId then
            return DEFINITIONS[chapterId]
        end
    end
    return nil
end

--[[
    The chapter a boss's own outcome maps to. The encounters record their
    outcomes in their own words (the Maw says "cleared", the Witch says
    "sealed"), and the chapter records the same word -- this is the check
    that they cannot drift apart silently.
]]
function ChapterCatalog.forBoss(bossId: any): Chapter?
    for _, chapterId in ORDER do
        if DEFINITIONS[chapterId].bossId == bossId then
            return DEFINITIONS[chapterId]
        end
    end
    return nil
end

return table.freeze(ChapterCatalog)
