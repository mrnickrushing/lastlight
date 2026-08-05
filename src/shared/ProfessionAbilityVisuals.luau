--!strict

local ProfessionAbilityVisuals = {}

export type Definition = {
    professionId: string,
    motif: string,
    color: { number },
    accent: { number },
    pulseLifetime: number,
    minimumRadius: number,
}

local DEFINITIONS: { [string]: Definition } = {
    profession_scout = table.freeze({
        professionId = "profession_scout",
        motif = "foxfire_compass",
        color = table.freeze({ 94, 206, 176 }),
        accent = table.freeze({ 218, 247, 205 }),
        pulseLifetime = 1.35,
        minimumRadius = 9,
    }),
    profession_warden = table.freeze({
        professionId = "profession_warden",
        motif = "root_ward",
        color = table.freeze({ 112, 151, 119 }),
        accent = table.freeze({ 244, 230, 197 }),
        pulseLifetime = 1.1,
        minimumRadius = 8,
    }),
    profession_engineer = table.freeze({
        professionId = "profession_engineer",
        motif = "rootline_gear",
        color = table.freeze({ 191, 137, 73 }),
        accent = table.freeze({ 255, 206, 112 }),
        pulseLifetime = 1.25,
        minimumRadius = 10,
    }),
    profession_medic = table.freeze({
        professionId = "profession_medic",
        motif = "brightcap_bloom",
        color = table.freeze({ 176, 108, 112 }),
        accent = table.freeze({ 214, 238, 190 }),
        pulseLifetime = 1.4,
        minimumRadius = 10,
    }),
    profession_alchemist = table.freeze({
        professionId = "profession_alchemist",
        motif = "tonic_bloom",
        color = table.freeze({ 154, 187, 92 }),
        accent = table.freeze({ 226, 247, 180 }),
        pulseLifetime = 1.3,
        minimumRadius = 10,
    }),
    profession_beastkeeper = table.freeze({
        professionId = "profession_beastkeeper",
        motif = "hound_dash",
        color = table.freeze({ 196, 120, 60 }),
        accent = table.freeze({ 246, 214, 165 }),
        pulseLifetime = 1.2,
        minimumRadius = 9,
    }),
    profession_runebinder = table.freeze({
        professionId = "profession_runebinder",
        motif = "still_rune",
        color = table.freeze({ 132, 150, 224 }),
        accent = table.freeze({ 214, 226, 255 }),
        pulseLifetime = 1.5,
        minimumRadius = 9,
    }),
}

function ProfessionAbilityVisuals.get(professionId: any): Definition?
    return if type(professionId) == "string" then DEFINITIONS[professionId] else nil
end

function ProfessionAbilityVisuals.list(): { Definition }
    local result = {}
    for _, definition in DEFINITIONS do
        table.insert(result, definition)
    end
    table.sort(result, function(a, b)
        return a.professionId < b.professionId
    end)
    return result
end

return table.freeze(ProfessionAbilityVisuals)
