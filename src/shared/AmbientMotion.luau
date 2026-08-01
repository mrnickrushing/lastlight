--!strict

local AmbientMotion = {}

local TAU = math.pi * 2

local PHASE_LIGHT_LEVEL = table.freeze({
    day = 0.7,
    dusk = 0.88,
    night = 1,
    reveal = 0.82,
})

function AmbientMotion.rotorAngle(elapsed: number, speed: number, phaseOffset: number): number
    return (elapsed * math.max(0, speed) + phaseOffset) % TAU
end

function AmbientMotion.lightLevel(elapsed: number, phaseOffset: number, phase: string): number
    local phaseLevel = PHASE_LIGHT_LEVEL[string.lower(phase)] or PHASE_LIGHT_LEVEL.day
    local quickFlicker = math.sin(elapsed * 4.7 + phaseOffset) * 0.055
    local slowBreath = math.sin(elapsed * 1.3 + phaseOffset * 0.61) * 0.035
    return math.clamp(phaseLevel + quickFlicker + slowBreath, 0.58, 1.08)
end

return table.freeze(AmbientMotion)
