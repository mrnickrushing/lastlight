--!strict

local WeatherProfile = {}

local STREAK_COUNTS = table.freeze({
    day = 10,
    dusk = 14,
    night = 18,
    reveal = 8,
})

function WeatherProfile.streakCount(phase: string): number
    return STREAK_COUNTS[string.lower(phase)] or STREAK_COUNTS.day
end

function WeatherProfile.wrapHeight(height: number, floor: number, ceiling: number): number
    assert(ceiling > floor, "weather ceiling must be above floor")
    if height >= floor then
        return height
    end
    local span = ceiling - floor
    return ceiling - ((floor - height) % span)
end

return table.freeze(WeatherProfile)
