--!strict

local ProfessionCatalog = {}

export type Definition = {
    id: string,
    displayName: string,
    shortName: string,
    role: string,
    abilityId: string,
    abilityName: string,
    abilityDescription: string,
    cooldownSeconds: number,
    activeSeconds: number,
    effectAmount: number,
    effectRadius: number,
}

local ORDER = table.freeze({
    "profession_scout",
    "profession_warden",
    "profession_engineer",
    "profession_medic",
})

local DEFINITIONS: { [string]: Definition } = {
    profession_scout = table.freeze({
        id = "profession_scout",
        displayName = "SCOUT",
        shortName = "SCOUT",
        role = "TRACK · REVEAL · SLOW",
        abilityId = "ability_foxfire_mark",
        abilityName = "FOXFIRE MARK",
        abilityDescription = "Mark and slow the nearest Rootling for the whole team.",
        cooldownSeconds = 16,
        activeSeconds = 8,
        effectAmount = 35,
        effectRadius = 55,
    }),
    profession_warden = table.freeze({
        id = "profession_warden",
        displayName = "WARDEN",
        shortName = "WARDEN",
        role = "GUARD · HOLD · PROTECT",
        abilityId = "ability_lantern_guard",
        abilityName = "LANTERN GUARD",
        abilityDescription = "Reduce incoming Rootling damage for a short window.",
        cooldownSeconds = 20,
        activeSeconds = 6,
        effectAmount = 60,
        effectRadius = 0,
    }),
    profession_engineer = table.freeze({
        id = "profession_engineer",
        displayName = "ENGINEER",
        shortName = "ENGINEER",
        role = "REPAIR · BUILD · CONTROL",
        abilityId = "ability_emergency_patch",
        abilityName = "EMERGENCY PATCH",
        abilityDescription = "Restore the First Lantern while defending it nearby.",
        cooldownSeconds = 18,
        activeSeconds = 0,
        effectAmount = 18,
        effectRadius = 30,
    }),
    profession_medic = table.freeze({
        id = "profession_medic",
        displayName = "MEDIC",
        shortName = "MEDIC",
        role = "HEAL · RESCUE · SUSTAIN",
        abilityId = "ability_guiding_pulse",
        abilityName = "GUIDING PULSE",
        abilityDescription = "Heal yourself and active allies in a nearby pulse.",
        cooldownSeconds = 24,
        activeSeconds = 0,
        effectAmount = 22,
        effectRadius = 28,
    }),
}

function ProfessionCatalog.isValid(id: any): boolean
    return type(id) == "string" and DEFINITIONS[id] ~= nil
end

function ProfessionCatalog.get(id: string): Definition?
    return DEFINITIONS[id]
end

function ProfessionCatalog.list(): { Definition }
    local result = {}
    for _, id in ORDER do
        table.insert(result, DEFINITIONS[id])
    end
    return result
end

ProfessionCatalog.Ids = table.freeze({
    Scout = "profession_scout",
    Warden = "profession_warden",
    Engineer = "profession_engineer",
    Medic = "profession_medic",
})

return table.freeze(ProfessionCatalog)
