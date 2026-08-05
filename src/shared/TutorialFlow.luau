--!strict

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
        objective = "FREE MARA",
        detail = "Follow the lantern path to the fallen roots.",
        mara = "Over here! The roots tighten when the light fades.",
    },
    gather = {
        targets = { "heartwood_gather" },
        index = 2,
        action = "gather",
        next = "choose_tool",
        objective = "GATHER HEARTWOOD",
        detail = "Collect 3 Heartwood from the glowing stump.",
        mara = "Heartwood remembers sunlight. We can build with it.",
    },
    choose_tool = {
        targets = { "tool_axe", "tool_hammer", "tool_torch" },
        index = 3,
        action = "choose_tool",
        next = "build",
        objective = "CHOOSE A STARTER TOOL",
        detail = "Axe, hammer, or torch — this choice is not permanent.",
        mara = "Choose what feels right. Emberhollow needs every kind of helper.",
    },
    build = {
        targets = { "barricade_build" },
        index = 4,
        action = "build",
        next = "prepare",
        objective = "BUILD THE BARRICADE",
        detail = "Use 3 Heartwood at the marked construction plot.",
        mara = "Place the braces toward the dark trail.",
    },
    prepare = {
        targets = { "first_lantern_prepare" },
        index = 5,
        action = "prepare",
        next = "survive",
        objective = "LIGHT THE FIRST LANTERN",
        detail = "Start the two-minute defense when you are ready.",
        mara = "Night is close. Light the lantern when you are ready.",
    },
    survive = {
        targets = { "first_lantern_prepare" },
        index = 6,
        action = nil,
        next = "reveal",
        objective = "KEEP THE LIGHT ALIVE",
        detail = "Defend the lantern until dawn.",
        mara = "Stay in the light. Rootlings hate a steady flame.",
    },
    reveal = {
        targets = { "bramblewake_reveal" },
        index = 7,
        action = "reveal",
        next = "complete",
        objective = "FOLLOW THE FIRST LIGHT",
        detail = "Reach the dawn beacon and reveal Bramblewake.",
        mara = "The lantern knows your name. Go—see what it remembered.",
    },
    complete = {
        index = 8,
        action = nil,
        next = nil,
        objective = "EMBERHOLLOW REMEMBERS YOU",
        detail = "First Light complete. The wider world is now ahead.",
        mara = "You brought the morning back. Welcome home.",
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
