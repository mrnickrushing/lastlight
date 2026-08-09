--!strict

local Strings = require("./Strings")

local TutorialFlow = {}

export type Stage =
    "arrive"
    | "gather"
    | "choose_tool"
    | "build"
    | "prepare"
    | "survive"
    | "reveal"
    | "complete"

export type Definition = {
    index: number,
    action: string?,
    next: Stage?,
    objective: string,
    detail: string,
    mara: string,
    -- World interactions that satisfy this stage. The client raises a marker
    -- over each one, because an objective a player cannot find is the same as
    -- an objective that does not exist: "choose a starter tool" said nothing
    -- about where the tools were.
    targets: { string }?,
}

local ORDER: { Stage } = {
    "arrive",
    "gather",
    "choose_tool",
    "build",
    "prepare",
    "survive",
    "reveal",
    "complete",
}

local DEFINITIONS: { [Stage]: Definition } = {
    arrive = {
        targets = { "mara_rescue" },
        index = 1,
        action = "rescue",
        next = "gather",
        objective = Strings.get("hud.free_mara"),
        detail = Strings.get("tutorial.follow_the_lantern_path_to_the"),
        mara = Strings.get("tutorial.over_here_the_roots_tighten_when"),
    },
    gather = {
        targets = { "heartwood_gather" },
        index = 2,
        action = "gather",
        next = "choose_tool",
        objective = Strings.get("tutorial.gather_heartwood"),
        detail = Strings.get("tutorial.collect_3_heartwood_from_the_glowing"),
        mara = Strings.get("tutorial.heartwood_remembers_sunlight_we_can_build"),
    },
    choose_tool = {
        targets = { "tool_axe", "tool_hammer", "tool_torch" },
        index = 3,
        action = "choose_tool",
        next = "build",
        objective = Strings.get("tutorial.choose_a_starter_tool"),
        detail = Strings.get("tutorial.axe_hits_harder_hammer_works_faster"),
        mara = Strings.get("tutorial.choose_what_feels_right_emberhollow_needs"),
    },
    build = {
        targets = { "barricade_build" },
        index = 4,
        action = "build",
        next = "prepare",
        objective = Strings.get("tutorial.build_the_barricade"),
        detail = Strings.get("tutorial.use_3_heartwood_at_the_marked"),
        mara = Strings.get("tutorial.place_the_braces_toward_the_dark"),
    },
    prepare = {
        targets = { "first_lantern_prepare" },
        index = 5,
        action = "prepare",
        next = "survive",
        objective = Strings.get("tutorial.light_the_first_lantern"),
        detail = Strings.get("tutorial.start_the_two_minute_defense_when"),
        mara = Strings.get("tutorial.night_is_close_light_the_lantern"),
    },
    survive = {
        targets = { "first_lantern_prepare" },
        index = 6,
        action = nil,
        next = "reveal",
        objective = Strings.get("client.keep_the_light_alive"),
        detail = Strings.get("tutorial.defend_the_lantern_until_dawn"),
        mara = Strings.get("tutorial.stay_in_the_light_rootlings_hate"),
    },
    reveal = {
        targets = { "bramblewake_reveal" },
        index = 7,
        action = "reveal",
        next = "complete",
        objective = Strings.get("tutorial.follow_the_first_light"),
        detail = Strings.get("tutorial.reach_the_dawn_beacon_and_reveal"),
        mara = Strings.get("tutorial.the_lantern_knows_your_name_go"),
    },
    complete = {
        index = 8,
        action = nil,
        next = nil,
        objective = Strings.get("tutorial.emberhollow_remembers_you"),
        detail = Strings.get("tutorial.first_light_complete_the_wider_world"),
        mara = Strings.get("tutorial.you_brought_the_morning_back_welcome"),
    },
}

function TutorialFlow.isValidStage(value: any): boolean
    return type(value) == "string" and DEFINITIONS[value :: Stage] ~= nil
end

function TutorialFlow.definition(stage: Stage): Definition
    local definition = DEFINITIONS[stage]
    assert(definition ~= nil, string.format("unknown tutorial stage %q", tostring(stage)))
    return definition
end

function TutorialFlow.advance(stage: Stage, action: string): (Stage?, string?)
    local definition = TutorialFlow.definition(stage)
    if definition.action == nil then
        return nil, "stage does not accept a player action"
    end
    if action ~= definition.action then
        return nil, string.format("expected %s", definition.action)
    end
    return definition.next, nil
end

function TutorialFlow.advanceSystem(stage: Stage): (Stage?, string?)
    if stage ~= "survive" then
        return nil, "only survive advances from a system event"
    end
    return "reveal", nil
end

function TutorialFlow.progress(stage: Stage): (number, number)
    return TutorialFlow.definition(stage).index, #ORDER
end

-- The stage a fresh run begins at. Named rather than indexed at call sites so
-- reordering the flow cannot silently change where new sessions start.
function TutorialFlow.firstStage(): Stage
    return TutorialFlow.order()[1]
end

function TutorialFlow.order(): { Stage }
    return table.clone(ORDER)
end

return table.freeze(TutorialFlow)
