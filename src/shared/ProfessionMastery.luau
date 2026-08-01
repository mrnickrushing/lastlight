--!strict

local ProfessionCatalog = require("./ProfessionCatalog")

local ProfessionMastery = {}

export type Entry = {
    xp: number,
    level: number,
    specializationId: string?,
}

export type State = { [string]: Entry }

export type Specialization = {
    id: string,
    name: string,
    description: string,
    effectAmountBonus: number?,
    effectRadiusBonus: number?,
    activeSecondsBonus: number?,
    cooldownReduction: number?,
    rescueDurationMultiplier: number?,
    rescueHealthBonus: number?,
    rescueWardBonus: number?,
}

local MAX_LEVEL = 10
local XP_PER_LEVEL = 100
local MAX_XP = MAX_LEVEL * XP_PER_LEVEL

local RANKS = table.freeze({
    table.freeze({ level = 1, name = "INITIATE" }),
    table.freeze({ level = 2, name = "KEEPER" }),
    table.freeze({ level = 4, name = "ADEPT" }),
    table.freeze({ level = 6, name = "VETERAN" }),
    table.freeze({ level = 8, name = "LUMINARY" }),
    table.freeze({ level = 10, name = "MASTER" }),
})

local function specialization(definition: any): Specialization
    return table.freeze({
        id = assert(definition.id, "specialization ID is required"),
        name = assert(definition.name, "specialization name is required"),
        description = assert(definition.description, "specialization description is required"),
        effectAmountBonus = tonumber(definition.effectAmountBonus) or 0,
        effectRadiusBonus = tonumber(definition.effectRadiusBonus) or 0,
        activeSecondsBonus = tonumber(definition.activeSecondsBonus) or 0,
        cooldownReduction = tonumber(definition.cooldownReduction) or 0,
        rescueDurationMultiplier = tonumber(definition.rescueDurationMultiplier) or 1,
        rescueHealthBonus = tonumber(definition.rescueHealthBonus) or 0,
        rescueWardBonus = tonumber(definition.rescueWardBonus) or 0,
    })
end

local SPECIALIZATIONS: { [string]: { Specialization } } = table.freeze({
    profession_scout = table.freeze({
        specialization({
            id = "specialization_pathfinder",
            name = "PATHFINDER",
            description = "Foxfire Mark reaches 8 studs farther.",
            effectRadiusBonus = 8,
        }),
        specialization({
            id = "specialization_foxfire_trapper",
            name = "FOXFIRE TRAPPER",
            description = "Foxfire Mark lasts 3 seconds longer.",
            activeSecondsBonus = 3,
        }),
        specialization({
            id = "specialization_trailseer",
            name = "TRAILSEER",
            description = "Foxfire Mark recharges 4 seconds faster.",
            cooldownReduction = 4,
        }),
    }),
    profession_warden = table.freeze({
        specialization({
            id = "specialization_bulwark",
            name = "BULWARK",
            description = "Lantern Guard reduces 10% more incoming damage.",
            effectAmountBonus = 10,
        }),
        specialization({
            id = "specialization_greenkeeper",
            name = "GREENKEEPER",
            description = "Lantern Guard lasts 3 seconds longer.",
            activeSecondsBonus = 3,
        }),
        specialization({
            id = "specialization_oathbound",
            name = "OATHBOUND",
            description = "Warden rescues grant 1.5 more ward seconds.",
            rescueWardBonus = 1.5,
        }),
    }),
    profession_engineer = table.freeze({
        specialization({
            id = "specialization_lamplighter",
            name = "LAMPLIGHTER",
            description = "Emergency Patch restores 10 more lantern health.",
            effectAmountBonus = 10,
        }),
        specialization({
            id = "specialization_rootwright",
            name = "ROOTWRIGHT",
            description = "Emergency Patch reaches 10 studs farther.",
            effectRadiusBonus = 10,
        }),
        specialization({
            id = "specialization_salvager",
            name = "SALVAGER",
            description = "Emergency Patch recharges 5 seconds faster.",
            cooldownReduction = 5,
        }),
    }),
    profession_medic = table.freeze({
        specialization({
            id = "specialization_dawnmender",
            name = "DAWNMENDER",
            description = "Guiding Pulse restores 10 more health.",
            effectAmountBonus = 10,
        }),
        specialization({
            id = "specialization_wayhome_tender",
            name = "WAYHOME TENDER",
            description = "Medic rescues are faster and restore 8 more health.",
            rescueDurationMultiplier = 0.82,
            rescueHealthBonus = 8,
        }),
        specialization({
            id = "specialization_brightcap_herbalist",
            name = "BRIGHTCAP HERBALIST",
            description = "Guiding Pulse reaches 10 studs farther.",
            effectRadiusBonus = 10,
        }),
    }),
})

local SPECIALIZATION_PROFESSIONS: { [string]: string } = {}
for professionId, definitions in SPECIALIZATIONS do
    for _, definition in definitions do
        assert(
            SPECIALIZATION_PROFESSIONS[definition.id] == nil,
            "duplicate specialization ID: " .. definition.id
        )
        SPECIALIZATION_PROFESSIONS[definition.id] = professionId
    end
end

local function specializationBonus(definition: any, field: string): number
    if definition == nil then
        return 0
    end
    return tonumber(definition[field]) or 0
end

local function levelForXp(xp: number): number
    return math.clamp(math.floor(xp / XP_PER_LEVEL) + 1, 1, MAX_LEVEL)
end

local function rankName(level: number): string
    local name = RANKS[1].name
    for _, rank in RANKS do
        if level >= rank.level then
            name = rank.name
        end
    end
    return name
end

function ProfessionMastery.default(): State
    return {}
end

function ProfessionMastery.normalize(value: any): State
    local result: State = {}
    if type(value) ~= "table" then
        return result
    end
    for _, definition in ProfessionCatalog.list() do
        local raw = value[definition.id]
        if type(raw) == "table" then
            local xp = if type(raw.xp) == "number"
                then math.clamp(math.floor(raw.xp), 0, MAX_XP)
                else 0
            local level = levelForXp(xp)
            local specializationId = if level >= MAX_LEVEL
                    and type(raw.specializationId) == "string"
                    and SPECIALIZATION_PROFESSIONS[raw.specializationId] == definition.id
                then raw.specializationId
                else nil
            result[definition.id] = {
                xp = xp,
                level = level,
                specializationId = specializationId,
            }
        end
    end
    return result
end

function ProfessionMastery.award(state: State, professionId: any, amount: number): (State, any)
    if not ProfessionCatalog.isValid(professionId) or type(amount) ~= "number" or amount <= 0 then
        return state, { applied = false, reason = "invalid_mastery_award" }
    end
    local nextState = ProfessionMastery.normalize(state)
    local current = nextState[professionId]
        or {
            xp = 0,
            level = 1,
            specializationId = nil,
        }
    local nextXp = math.min(MAX_XP, current.xp + math.floor(amount))
    local nextLevel = levelForXp(nextXp)
    nextState[professionId] = {
        xp = nextXp,
        level = nextLevel,
        specializationId = current.specializationId,
    }
    return nextState,
        {
            applied = true,
            professionId = professionId,
            xp = nextXp,
            level = nextLevel,
            rankName = rankName(nextLevel),
            leveledUp = nextLevel > current.level,
            specializationUnlocked = current.level < MAX_LEVEL and nextLevel == MAX_LEVEL,
        }
end

function ProfessionMastery.selectSpecialization(
    state: State,
    professionId: any,
    specializationId: any
): (State, any)
    if not ProfessionCatalog.isValid(professionId) then
        return state, { applied = false, reason = "unknown_profession" }
    end
    if
        type(specializationId) ~= "string"
        or SPECIALIZATION_PROFESSIONS[specializationId] ~= professionId
    then
        return state, { applied = false, reason = "invalid_specialization" }
    end
    local normalized = ProfessionMastery.normalize(state)
    local current = normalized[professionId] or { xp = 0, level = 1, specializationId = nil }
    if current.level < MAX_LEVEL then
        return state, { applied = false, reason = "specialization_locked" }
    end
    if current.specializationId == specializationId then
        return state,
            {
                applied = false,
                duplicate = true,
                professionId = professionId,
                reason = "already_selected",
                specializationId = specializationId,
            }
    end
    local nextState = table.clone(normalized)
    nextState[professionId] = {
        xp = current.xp,
        level = current.level,
        specializationId = specializationId,
    }
    return nextState,
        {
            applied = true,
            professionId = professionId,
            specializationId = specializationId,
        }
end

function ProfessionMastery.specializationProfession(specializationId: any): string?
    return if type(specializationId) == "string"
        then SPECIALIZATION_PROFESSIONS[specializationId]
        else nil
end

function ProfessionMastery.specializationDefinition(specializationId: any): any
    local professionId = ProfessionMastery.specializationProfession(specializationId)
    if professionId == nil then
        return nil
    end
    for _, definition in SPECIALIZATIONS[professionId] do
        if definition.id == specializationId then
            return definition
        end
    end
    return nil
end

function ProfessionMastery.specializationIds(): { string }
    local result = {}
    for _, profession in ProfessionCatalog.list() do
        for _, definition in SPECIALIZATIONS[profession.id] do
            table.insert(result, definition.id)
        end
    end
    return result
end

function ProfessionMastery.tuning(state: State, professionId: any): any
    local normalized = ProfessionMastery.normalize(state)
    local entry = if ProfessionCatalog.isValid(professionId)
        then normalized[professionId] or { xp = 0, level = 1, specializationId = nil }
        else { xp = 0, level = 1, specializationId = nil }
    local rewardSteps = math.floor(entry.level / 2)
    local selectedSpecialization =
        ProfessionMastery.specializationDefinition(entry.specializationId)
    return {
        level = entry.level,
        rankName = rankName(entry.level),
        effectAmountBonus = rewardSteps * 2
            + specializationBonus(selectedSpecialization, "effectAmountBonus"),
        effectRadiusBonus = rewardSteps * 1.5
            + specializationBonus(selectedSpecialization, "effectRadiusBonus"),
        activeSecondsBonus = rewardSteps * 0.35
            + specializationBonus(selectedSpecialization, "activeSecondsBonus"),
        cooldownReduction = rewardSteps * 0.4
            + specializationBonus(selectedSpecialization, "cooldownReduction"),
        rescueDurationMultiplier = if selectedSpecialization == nil
            then 1
            else selectedSpecialization.rescueDurationMultiplier or 1,
        rescueHealthBonus = if selectedSpecialization == nil
            then 0
            else selectedSpecialization.rescueHealthBonus or 0,
        rescueWardBonus = if selectedSpecialization == nil
            then 0
            else selectedSpecialization.rescueWardBonus or 0,
        specialization = selectedSpecialization,
        specializationId = entry.specializationId,
        specializationUnlocked = entry.level >= MAX_LEVEL,
        specializationUnlockLevel = MAX_LEVEL,
        specializations = if ProfessionCatalog.isValid(professionId)
            then SPECIALIZATIONS[professionId]
            else {},
    }
end

function ProfessionMastery.snapshot(state: State): { [string]: any }
    local normalized = ProfessionMastery.normalize(state)
    local result = {}
    for _, definition in ProfessionCatalog.list() do
        local entry = normalized[definition.id] or { xp = 0, level = 1, specializationId = nil }
        local tuning = ProfessionMastery.tuning(normalized, definition.id)
        result[definition.id] = {
            xp = entry.xp,
            level = entry.level,
            rankName = tuning.rankName,
            currentLevelXp = (entry.level - 1) * XP_PER_LEVEL,
            nextLevelXp = if entry.level >= MAX_LEVEL then MAX_XP else entry.level * XP_PER_LEVEL,
            effectAmountBonus = tuning.effectAmountBonus,
            effectRadiusBonus = tuning.effectRadiusBonus,
            activeSecondsBonus = tuning.activeSecondsBonus,
            cooldownReduction = tuning.cooldownReduction,
            specialization = tuning.specialization,
            specializationId = tuning.specializationId,
            specializationUnlocked = tuning.specializationUnlocked,
            specializationUnlockLevel = tuning.specializationUnlockLevel,
            specializations = tuning.specializations,
        }
    end
    return result
end

ProfessionMastery.MaxLevel = MAX_LEVEL
ProfessionMastery.MaxXp = MAX_XP
ProfessionMastery.Ranks = RANKS
ProfessionMastery.Specializations = SPECIALIZATIONS
ProfessionMastery.XpPerLevel = XP_PER_LEVEL

return table.freeze(ProfessionMastery)
