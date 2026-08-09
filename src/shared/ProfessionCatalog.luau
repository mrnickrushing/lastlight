--!strict

local Strings = require("./Strings")

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
    "profession_alchemist",
    "profession_beastkeeper",
    "profession_runebinder",
})

local DEFINITIONS: { [string]: Definition } = {
    profession_scout = table.freeze({
        id = "profession_scout",
        displayName = Strings.get("world.scout"),
        shortName = Strings.get("world.scout"),
        role = Strings.get("profession.track_reveal_slow"),
        abilityId = "ability_foxfire_mark",
        abilityName = Strings.get("profession.foxfire_mark"),
        abilityDescription = Strings.get("profession.mark_and_slow_the_nearest_rootling"),
        cooldownSeconds = 16,
        activeSeconds = 8,
        effectAmount = 35,
        effectRadius = 55,
    }),
    profession_warden = table.freeze({
        id = "profession_warden",
        displayName = Strings.get("world.warden"),
        shortName = Strings.get("world.warden"),
        role = Strings.get("profession.guard_hold_protect"),
        abilityId = "ability_lantern_guard",
        abilityName = Strings.get("profession.lantern_guard"),
        abilityDescription = Strings.get("profession.reduce_incoming_rootling_damage_for_a"),
        cooldownSeconds = 20,
        activeSeconds = 6,
        effectAmount = 60,
        effectRadius = 0,
    }),
    profession_engineer = table.freeze({
        id = "profession_engineer",
        displayName = Strings.get("world.engineer"),
        shortName = Strings.get("world.engineer"),
        role = Strings.get("profession.repair_build_control"),
        abilityId = "ability_emergency_patch",
        abilityName = Strings.get("profession.emergency_patch"),
        abilityDescription = Strings.get("profession.restore_the_first_lantern_while_defending"),
        cooldownSeconds = 18,
        activeSeconds = 0,
        effectAmount = 18,
        effectRadius = 30,
    }),
    profession_medic = table.freeze({
        id = "profession_medic",
        displayName = Strings.get("world.medic"),
        shortName = Strings.get("world.medic"),
        role = Strings.get("profession.heal_rescue_sustain"),
        abilityId = "ability_guiding_pulse",
        abilityName = Strings.get("profession.guiding_pulse"),
        abilityDescription = Strings.get("profession.heal_yourself_and_active_allies_in"),
        cooldownSeconds = 24,
        activeSeconds = 0,
        effectAmount = 22,
        effectRadius = 28,
    }),
    --[[
        The final three of the seven-profession roster. Each maps onto an
        existing combat primitive rather than inventing a parallel system:
        the tonic is the Medic's radius pattern applied to stamina as well
        as health, the hound is enemy target selection with a preference,
        and the rune is the same held-state the mark's slow already uses,
        taken to a full stop. effectAmount doubles as the tonic's stamina
        number (its heal is derived as half), and activeSeconds is the
        hound's and rune's duration, so the mastery bonus fields mean the
        same thing here that they mean for the first four kits.
    ]]
    profession_alchemist = table.freeze({
        id = "profession_alchemist",
        displayName = Strings.get("world.alchemist"),
        shortName = Strings.get("world.alchemist"),
        role = Strings.get("profession.brew_restore_sustain"),
        abilityId = "ability_sporebright_tonic",
        abilityName = Strings.get("profession.sporebright_tonic"),
        abilityDescription = Strings.get("profession.share_a_tonic_that_restores_stamina"),
        cooldownSeconds = 22,
        activeSeconds = 0,
        effectAmount = 30,
        effectRadius = 26,
    }),
    profession_beastkeeper = table.freeze({
        id = "profession_beastkeeper",
        displayName = Strings.get("world.beastkeeper"),
        shortName = Strings.get("profession.keeper"),
        role = Strings.get("profession.bond_lure_protect"),
        abilityId = "ability_briar_hound",
        abilityName = Strings.get("profession.briar_hound"),
        abilityDescription = Strings.get("profession.send_your_hound_to_harry_the"),
        cooldownSeconds = 20,
        activeSeconds = 7,
        effectAmount = 0,
        effectRadius = 50,
    }),
    profession_runebinder = table.freeze({
        id = "profession_runebinder",
        displayName = Strings.get("world.runebinder"),
        shortName = Strings.get("profession.binder"),
        role = Strings.get("profession.bind_still_ward"),
        abilityId = "ability_still_rune",
        abilityName = Strings.get("profession.still_rune"),
        abilityDescription = Strings.get("profession.bind_the_threat_in_light_holding"),
        cooldownSeconds = 26,
        activeSeconds = 3.5,
        effectAmount = 0,
        effectRadius = 45,
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
    Alchemist = "profession_alchemist",
    Beastkeeper = "profession_beastkeeper",
    Runebinder = "profession_runebinder",
})

return table.freeze(ProfessionCatalog)
