--!strict

--[[
    What the game says when it is over.

    The obvious way to write an epilogue is to branch on the ending: three
    endings, three paragraphs, done. That would waste six chapters. A
    player who spared every memory in the Crown and one who erased them
    all should not read the same closing text merely because they both put
    the lantern out, and the whole design of this game's decisions -- made
    with the hands, in the middle of something, never in a menu -- only
    pays off if the ending remembers them.

    So this reads the entire story: every resolved chapter's outcome, what
    happened in the Hollow's scenes, and the ending. Each contributes a
    line, in chapter order, and the ending supplies the last word. A save
    that has resolved nothing still gets a coherent epilogue, because a
    player can reach the Hollow's mouth without having closed a chapter
    behind them and the game must not go blank at them.

    Every chapter outcome the catalog can record has a line here, and the
    spec walks the catalog rather than a list kept in this file, so a new
    outcome cannot ship without one.
]]

local ChapterCatalog = require("./ChapterCatalog")
local HollowFinale = require("./Content/Definitions/HollowFinale")
local ResidentRoster = require("./ResidentRoster")

local Epilogue = {}

export type Resolution = {
    -- The ending's own name, or nil for a story that never reached the seat.
    ending: string?,
    title: string,
    -- One line per resolved chapter, in chapter order, then the Hollow's.
    lines: { string },
    -- What the town is called afterwards, for the world sign.
    townState: string,
}

--[[
    A line per outcome, in the voice of the town rather than the game.
    Keyed by chapter and outcome because two chapters can record the same
    word -- the Witch and the Titan both end on "broken" -- and they do
    not mean the same thing.
]]
local OUTCOME_LINES: { [string]: { [string]: string } } = {
    chapter_one = {
        preserved = "The forest kept its old paths, and people still walk them.",
        scarred = "The forest grew back crooked, and the road through it is harder than it was.",
        harmed = "Nothing has come out of the wood since. Nobody says that is a relief.",
    },
    chapter_two = {
        cleared = "The Delve's air runs clean, and there is iron coming up again.",
        fouled = "The Delve is worked in short shifts now, and nobody goes deep.",
        mixed = "Half the Delve breathes. The other half is bricked up and marked.",
    },
    chapter_three = {
        sealed = "The Fen is quiet, and the light in it stays where it is put.",
        bound = "The Fen is watched. What is under it is held rather than gone.",
        broken = "The Fen went dark all at once, and the water has not settled since.",
    },
    chapter_four = {
        navigable = "The harbour takes boats again. Two came in this spring.",
        scoured = "The channel silted where the tide dropped, and only small craft use it.",
        broken = "There is no harbour mouth any more, only a bay with a bad memory.",
    },
    chapter_five = {
        sheltered = "There is still something living in the Vale, and it keeps to itself.",
        thinned = "The Vale is emptier every year, but it is not empty.",
        silenced = "Nothing calls in the Vale now. The quiet up there is total.",
    },
    chapter_six = {
        remembered = "Every true face in the Crown is still standing, and people go to read them.",
        recast = "Some of the Crown's dead are still named. The rest are rubble nobody sorts.",
        erased = "The Crown is clean stone. There is no record left of who was in it.",
    },
    chapter_seven = {
        lantern_kept = "The lantern road still runs, and there is always somebody below it.",
        lantern_out = "There is no lantern road. The nights are only nights now.",
        lantern_shared = "Everyone carries a piece of it. No road, and nothing at the bottom.",
    },
}

local ENDING_TITLES: { [string]: string } = {
    ending_kept = "THE LANTERN KEPT",
    ending_ended = "THE LANTERN PUT OUT",
    ending_shared = "THE LANTERN SHARED",
}

local TOWN_STATES: { [string]: string } = {
    ending_kept = "emberhollow_tended",
    ending_ended = "emberhollow_dark",
    ending_shared = "emberhollow_scattered",
}

local POST_LINES: { [string]: string } = {
    post_gate = "The gate went first, and the copy of this town burned from the road in.",
    post_road = "It came up the road, past the posts nobody could spare, into the middle.",
    post_hearth = "It reached the hearth. In a town that was never lived in, that still mattered.",
}

Epilogue.OutcomeLines = OUTCOME_LINES
Epilogue.EndingTitles = ENDING_TITLES

local function chapterOutcome(story: any, definition: any): string?
    if definition.id == "chapter_one" then
        local record = if type(story) == "table" then story.chapterOne else nil
        if type(record) == "table" and record.status == "complete" then
            return record.wardenOutcome
        end
        return nil
    end
    local chapters = if type(story) == "table" then story.chapters else nil
    local record = if type(chapters) == "table" then chapters[definition.id] else nil
    if type(record) == "table" and record.status == "complete" then
        return record.outcome
    end
    return nil
end

--[[
    Read a whole save and say what became of it. Takes the story block
    rather than the profile so anything that has a story -- a live
    profile, a restored backup, an admin inspection -- can ask.
]]
function Epilogue.resolve(story: any): Resolution
    local lines: { string } = {}
    for _, definition in ChapterCatalog.list() do
        local outcome = chapterOutcome(story, definition)
        if outcome ~= nil then
            local byChapter = OUTCOME_LINES[definition.id]
            local line = if byChapter ~= nil then byChapter[outcome] else nil
            if line ~= nil then
                table.insert(lines, line)
            end
        end
    end

    local finale = if type(story) == "table" then story.finale else nil
    local ending: string? = nil
    if type(finale) == "table" and finale.status == "complete" then
        ending = finale.ending
        local postLine = POST_LINES[tostring(finale.abandonedPost)]
        if postLine ~= nil then
            table.insert(lines, postLine)
        end
        if type(finale.rescued) == "string" then
            local rescued = ResidentRoster.get(finale.rescued)
            local left = if type(finale.leftBehind) == "string"
                then ResidentRoster.get(finale.leftBehind)
                else nil
            if rescued ~= nil and left ~= nil then
                table.insert(
                    lines,
                    string.format(
                        "%s came back up. %s did not, and everybody knows which.",
                        (rescued :: any).displayName,
                        (left :: any).displayName
                    )
                )
            elseif rescued ~= nil then
                table.insert(
                    lines,
                    string.format("%s came back up with you.", (rescued :: any).displayName)
                )
            end
        else
            table.insert(lines, "Nobody came back up with you. There was light for one.")
        end
    end

    if #lines == 0 then
        table.insert(lines, "Emberhollow is still standing, and its story is not written yet.")
    end

    return {
        ending = ending,
        lines = lines,
        title = if ending ~= nil then ENDING_TITLES[ending] else "THE STORY SO FAR",
        townState = if ending ~= nil then TOWN_STATES[ending] else "emberhollow_lit",
    }
end

--[[
    The world state each ending produces, which is also chapter seven's
    outcome. Kept here beside the lines that describe it so the two cannot
    drift; SaveSchema writes the same mapping when it records the finale,
    and the spec pins that they agree.
]]
local ENDING_OUTCOMES: { [string]: string } = {
    ending_kept = "lantern_kept",
    ending_ended = "lantern_out",
    ending_shared = "lantern_shared",
}

Epilogue.EndingOutcomes = ENDING_OUTCOMES

-- The Hollow's own definition names its endings; this is the check that
-- nothing here has drifted from it.
function Epilogue.knowsEnding(endingId: any): boolean
    if type(endingId) ~= "string" then
        return false
    end
    local outcome = ENDING_OUTCOMES[endingId]
    if
        outcome == nil
        or ENDING_TITLES[endingId] == nil
        or TOWN_STATES[endingId] == nil
        or OUTCOME_LINES.chapter_seven[outcome] == nil
    then
        return false
    end
    for _, definition in HollowFinale.Endings do
        if definition.id == endingId then
            return true
        end
    end
    return false
end

return table.freeze(Epilogue)
