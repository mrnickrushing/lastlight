--!strict

local ProfessionRescue = {}

local MAX_LEVEL = 10

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function safeLevel(value: any): number
    return if finite(value) then math.clamp(math.floor(value), 1, MAX_LEVEL) else 1
end

function ProfessionRescue.resolve(
    professionId: any,
    level: any,
    baseDuration: number,
    baseHealth: number,
    baseWardSeconds: number
): any
    assert(finite(baseDuration) and baseDuration > 0, "base revive duration is invalid")
    assert(finite(baseHealth) and baseHealth > 0, "base revive health is invalid")
    assert(finite(baseWardSeconds) and baseWardSeconds >= 0, "base revive ward is invalid")

    local normalizedLevel = safeLevel(level)
    local masterySteps = math.floor(normalizedLevel / 2)
    local duration = baseDuration
    local health = baseHealth
    local wardSeconds = baseWardSeconds
    local rescueTitle = "FIELD RESCUE"
    local specialized = false

    if professionId == "profession_medic" then
        duration = baseDuration * (0.72 - masterySteps * 0.015)
        health = baseHealth + 10 + masterySteps * 2
        wardSeconds = baseWardSeconds + 0.75 + masterySteps * 0.15
        rescueTitle = "MEDIC RESCUE"
        specialized = true
    elseif professionId == "profession_warden" then
        wardSeconds = baseWardSeconds + 0.5 + masterySteps * 0.1
        rescueTitle = "WARDEN ESCORT"
        specialized = true
    end

    return table.freeze({
        duration = math.clamp(duration, 1.25, baseDuration),
        health = math.clamp(math.floor(health), baseHealth, 65),
        level = normalizedLevel,
        professionId = if type(professionId) == "string" then professionId else nil,
        rescueTitle = rescueTitle,
        specialized = specialized,
        wardSeconds = math.clamp(wardSeconds, baseWardSeconds, 6),
    })
end

return table.freeze(ProfessionRescue)
