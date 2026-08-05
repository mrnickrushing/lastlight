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
        displayName = "HAND AXE",
        description = "Strikes land a quarter harder.",
        strikeDamageMultiplier = 1.25,
    }),
    hammer = table.freeze({
        id = "hammer",
        family = "hammer",
        displayName = "BUILDER'S HAMMER",
        description = "Gather and build work runs a quarter faster.",
        actionDurationMultiplier = 0.75,
    }),
    torch = table.freeze({
        id = "torch",
        family = "lantern",
        displayName = "HAND TORCH",
        description = "Swung fire reaches four studs further at a small cost.",
        strikeDamageMultiplier = 0.9,
        strikeRangeBonus = 4,
    }),
    pick = table.freeze({
        id = "pick",
        family = "pick",
        displayName = "IRONROOT PICK",
        description = "Sap and clay come loose a quarter faster; a heavy point.",
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
        displayName = "MEADOW SICKLE",
        description = "Fiber and brightcap fall a quarter faster; a sweeping arc.",
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
        displayName = "FISHING KIT",
        description = "An angler's patience: stamina returns 10% faster.",
        staminaRegenMultiplier = 1.1,
    }),
    climbing_kit = table.freeze({
        id = "climbing_kit",
        family = "climbing_kit",
        displayName = "CLIMBING KIT",
        description = "Sure-footed: running carries you 8% faster.",
        sprintSpeedMultiplier = 1.08,
    }),
    survey_kit = table.freeze({
        id = "survey_kit",
        family = "survey_kit",
        displayName = "SURVEY GLASS",
        description = "Marks the nearest unharvested node on your trail.",
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
