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
local Strings = require("./Strings")

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
        preserved = Strings.get("story.the_forest_kept_its_old_paths"),
        scarred = Strings.get("story.the_forest_grew_back_crooked_and"),
        harmed = Strings.get("story.nothing_has_come_out_of_the"),
    },
    chapter_two = {
        cleared = Strings.get("story.the_delve_s_air_runs_clean"),
        fouled = Strings.get("story.the_delve_is_worked_in_short"),
        mixed = Strings.get("story.half_the_delve_breathes_the_other"),
    },
    chapter_three = {
        sealed = Strings.get("story.the_fen_is_quiet_and_the"),
        bound = Strings.get("story.the_fen_is_watched_what_is"),
        broken = Strings.get("story.the_fen_went_dark_all_at"),
    },
    chapter_four = {
        navigable = Strings.get("story.the_harbour_takes_boats_again_two"),
        scoured = Strings.get("story.the_channel_silted_where_the_tide"),
        broken = Strings.get("story.there_is_no_harbour_mouth_any"),
    },
    chapter_five = {
        sheltered = Strings.get("story.there_is_still_something_living_in"),
        thinned = Strings.get("story.the_vale_is_emptier_every_year"),
        silenced = Strings.get("story.nothing_calls_in_the_vale_now"),
    },
    chapter_six = {
        remembered = Strings.get("story.every_true_face_in_the_crown"),
        recast = Strings.get("story.some_of_the_crown_s_dead"),
        erased = Strings.get("story.the_crown_is_clean_stone_there"),
    },
    chapter_seven = {
        lantern_kept = Strings.get("story.the_lantern_road_still_runs_and"),
        lantern_out = Strings.get("story.there_is_no_lantern_road_the"),
        lantern_shared = Strings.get("story.everyone_carries_a_piece_of_it"),
    },
}

local ENDING_TITLES: { [string]: string } = {
    ending_kept = Strings.get("story.the_lantern_kept"),
    ending_ended = Strings.get("story.the_lantern_put_out"),
    ending_shared = Strings.get("story.the_lantern_shared"),
}

local TOWN_STATES: { [string]: string } = {
    ending_kept = "emberhollow_tended",
    ending_ended = "emberhollow_dark",
    ending_shared = "emberhollow_scattered",
}

local POST_LINES: { [string]: string } = {
    post_gate = Strings.get("story.the_gate_went_first_and_the"),
    post_road = Strings.get("story.it_came_up_the_road_past"),
    post_hearth = Strings.get("story.it_reached_the_hearth_in_a"),
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
                        Strings.get("story.n_came_back_up_n_did"),
                        (rescued :: any).displayName,
                        (left :: any).displayName
                    )
                )
            elseif rescued ~= nil then
                table.insert(
                    lines,
                    string.format(
                        Strings.get("story.n_came_back_up_with_you"),
                        (rescued :: any).displayName
                    )
                )
            end
        else
            table.insert(lines, Strings.get("story.nobody_came_back_up_with_you"))
        end
    end

    if #lines == 0 then
        table.insert(lines, Strings.get("story.emberhollow_is_still_standing_and_its"))
    end

    return {
        ending = ending,
        lines = lines,
        title = if ending ~= nil
            then ENDING_TITLES[ending]
            else Strings.get("story.the_story_so_far"),
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
