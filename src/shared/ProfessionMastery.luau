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
            local xp = if type(raw.xp) == "number" then math.max(0, math.floor(raw.xp)) else 0
            local level = math.clamp(math.floor(xp / XP_PER_LEVEL) + 1, 1, MAX_LEVEL)
            result[definition.id] = { xp = xp, level = level }
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
    local nextXp = math.min(MAX_LEVEL * XP_PER_LEVEL, current.xp + math.floor(amount))
    local nextLevel = math.clamp(math.floor(nextXp / XP_PER_LEVEL) + 1, 1, MAX_LEVEL)
    nextState[professionId] = { xp = nextXp, level = nextLevel }
    return nextState,
        {
            applied = true,
            professionId = professionId,
            xp = nextXp,
            level = nextLevel,
            leveledUp = nextLevel > current.level,
        }
end

function ProfessionMastery.snapshot(state: State): { [string]: Entry }
    return ProfessionMastery.normalize(state)
end

ProfessionMastery.MaxLevel = MAX_LEVEL
ProfessionMastery.XpPerLevel = XP_PER_LEVEL

return table.freeze(ProfessionMastery)
