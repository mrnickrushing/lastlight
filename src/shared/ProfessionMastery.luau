--!strict

local ProfessionCatalog = require("./ProfessionCatalog")

local ProfessionMastery = {}

export type Entry = {
    xp: number,
    level: number,
}

export type State = { [string]: Entry }

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

local SPECIALIZATIONS = table.freeze({
    profession_scout = table.freeze({
        table.freeze({ id = "specialization_pathfinder", name = "PATHFINDER" }),
        table.freeze({ id = "specialization_foxfire_trapper", name = "FOXFIRE TRAPPER" }),
        table.freeze({ id = "specialization_trailseer", name = "TRAILSEER" }),
    }),
    profession_warden = table.freeze({
        table.freeze({ id = "specialization_bulwark", name = "BULWARK" }),
        table.freeze({ id = "specialization_greenkeeper", name = "GREENKEEPER" }),
        table.freeze({ id = "specialization_oathbound", name = "OATHBOUND" }),
    }),
    profession_engineer = table.freeze({
        table.freeze({ id = "specialization_lamplighter", name = "LAMPLIGHTER" }),
        table.freeze({ id = "specialization_rootwright", name = "ROOTWRIGHT" }),
        table.freeze({ id = "specialization_salvager", name = "SALVAGER" }),
    }),
    profession_medic = table.freeze({
        table.freeze({ id = "specialization_dawnmender", name = "DAWNMENDER" }),
        table.freeze({ id = "specialization_wayhome_tender", name = "WAYHOME TENDER" }),
        table.freeze({ id = "specialization_brightcap_herbalist", name = "BRIGHTCAP HERBALIST" }),
    }),
})

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
            result[definition.id] = { xp = xp, level = levelForXp(xp) }
        end
    end
    return result
end

function ProfessionMastery.award(state: State, professionId: any, amount: number): (State, any)
    if not ProfessionCatalog.isValid(professionId) or type(amount) ~= "number" or amount <= 0 then
        return state, { applied = false, reason = "invalid_mastery_award" }
    end
    local nextState = ProfessionMastery.normalize(state)
    local current = nextState[professionId] or {
        xp = 0,
        level = 1,
    }
    local nextXp = math.min(MAX_XP, current.xp + math.floor(amount))
    local nextLevel = levelForXp(nextXp)
    nextState[professionId] = { xp = nextXp, level = nextLevel }
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

function ProfessionMastery.tuning(state: State, professionId: any): any
    local normalized = ProfessionMastery.normalize(state)
    local entry = if ProfessionCatalog.isValid(professionId)
        then normalized[professionId] or { xp = 0, level = 1 }
        else { xp = 0, level = 1 }
    local rewardSteps = math.floor(entry.level / 2)
    return {
        level = entry.level,
        rankName = rankName(entry.level),
        effectAmountBonus = rewardSteps * 2,
        effectRadiusBonus = rewardSteps * 1.5,
        activeSecondsBonus = rewardSteps * 0.35,
        cooldownReduction = rewardSteps * 0.4,
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
        local entry = normalized[definition.id] or { xp = 0, level = 1 }
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
