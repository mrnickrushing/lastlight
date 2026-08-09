--!strict

--[[
    The eight tool families -- axes, hammers, lanterns (the torch), picks,
    sickles, fishing kits, climbing kits, and survey instruments -- one held
    tool per family for now, each with a bounded identity expressed through
    hooks the game already has. Combat identity flows through the strike
    context, work identity through timed-action durations, endurance
    identities through the per-player stamina and sprint paths, and the
    survey's exploration identity through the objective-marker resolver.

    Every number is a small trade rather than a power ramp: the axe hits a
    quarter harder but reaches like a hand, the torch reaches four studs
    further at a small cost, the pick and sickle each hurry only their own
    kind of harvest, and nothing here can exceed the clamps combat and
    stamina already enforce. A client never submits any of these -- the
    server reads the catalog by the tool id it stored.

    The fishing and climbing kits carry their stat identities now; their
    full mechanics (a pond catch loop, real traversal) are recorded as open
    work in the Milestone 6 runbook rather than pretended at here.
]]

local Strings = require("./Strings")

local ToolCatalog = {}

export type Definition = {
    id: string,
    family: string,
    displayName: string,
    description: string,
    strikeDamageMultiplier: number?,
    strikeRangeBonus: number?,
    actionDurationMultiplier: number?,
    gatherDurationMultiplier: number?,
    gatherMaterials: { [string]: boolean }?,
    staminaRegenMultiplier: number?,
    sprintSpeedMultiplier: number?,
    surveyRevealsNodes: boolean?,
}

local ORDER = table.freeze({
    "axe",
    "hammer",
    "torch",
    "pick",
    "sickle",
    "fishing_kit",
    "climbing_kit",
    "survey_kit",
})

local DEFINITIONS: { [string]: Definition } = {
    axe = table.freeze({
        id = "axe",
        family = "axe",
        displayName = Strings.get("world.tool_axe"),
        description = Strings.get("item.strikes_land_a_quarter_harder"),
        strikeDamageMultiplier = 1.25,
    }),
    hammer = table.freeze({
        id = "hammer",
        family = "hammer",
        displayName = Strings.get("world.tool_hammer"),
        description = Strings.get("item.gather_and_build_work_runs_a"),
        actionDurationMultiplier = 0.75,
    }),
    torch = table.freeze({
        id = "torch",
        family = "lantern",
        displayName = Strings.get("world.tool_torch"),
        description = Strings.get("item.swung_fire_reaches_four_studs_further"),
        strikeDamageMultiplier = 0.9,
        strikeRangeBonus = 4,
    }),
    pick = table.freeze({
        id = "pick",
        family = "pick",
        displayName = Strings.get("world.tool_pick"),
        description = Strings.get("item.sap_and_clay_come_loose_a"),
        strikeDamageMultiplier = 1.05,
        gatherDurationMultiplier = 0.75,
        gatherMaterials = table.freeze({
            material_amber_sap = true,
            material_spring_clay = true,
        }),
    }),
    sickle = table.freeze({
        id = "sickle",
        family = "sickle",
        displayName = Strings.get("world.tool_sickle"),
        description = Strings.get("item.fiber_and_brightcap_fall_a_quarter"),
        strikeRangeBonus = 2,
        gatherDurationMultiplier = 0.75,
        gatherMaterials = table.freeze({
            material_meadow_fiber = true,
            material_brightcap = true,
        }),
    }),
    fishing_kit = table.freeze({
        id = "fishing_kit",
        family = "fishing_kit",
        displayName = Strings.get("world.tool_fishing_kit"),
        description = Strings.get("item.an_angler_s_patience_stamina_returns"),
        staminaRegenMultiplier = 1.1,
    }),
    climbing_kit = table.freeze({
        id = "climbing_kit",
        family = "climbing_kit",
        displayName = Strings.get("world.tool_climbing_kit"),
        description = Strings.get("item.sure_footed_running_carries_you_8naster"),
        sprintSpeedMultiplier = 1.08,
    }),
    survey_kit = table.freeze({
        id = "survey_kit",
        family = "survey_kit",
        displayName = Strings.get("world.tool_survey_kit"),
        description = Strings.get("item.marks_the_nearest_unharvested_node_on"),
        surveyRevealsNodes = true,
    }),
}

function ToolCatalog.isValid(id: any): boolean
    return type(id) == "string" and DEFINITIONS[id] ~= nil
end

function ToolCatalog.get(id: any): Definition?
    return if type(id) == "string" then DEFINITIONS[id] else nil
end

function ToolCatalog.list(): { Definition }
    local result = {}
    for _, id in ORDER do
        table.insert(result, DEFINITIONS[id])
    end
    return result
end

return table.freeze(ToolCatalog)
