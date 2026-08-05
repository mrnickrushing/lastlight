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

--[[
    The contract's face. A weather kind scales what the base phase would
    show rather than replacing it: storm doubles the falling streaks and
    darkens them, mist thins them to a slow drift, spores tint the fall
    amber and let it hang. Pure data so the client controller stays a
    renderer and this table stays testable.
]]
local CONTRACT_WEATHER = {
    clear = {
        countScale = 1,
        speedScale = 1,
        transparency = 0.68,
        color = { 163, 193, 201 },
    },
    mist = {
        countScale = 0.45,
        speedScale = 0.35,
        transparency = 0.82,
        color = { 190, 205, 208 },
    },
    storm = {
        countScale = 2,
        speedScale = 1.55,
        transparency = 0.5,
        color = { 140, 168, 182 },
    },
    spores = {
        countScale = 0.8,
        speedScale = 0.25,
        transparency = 0.62,
        color = { 214, 182, 118 },
    },
}

function WeatherProfile.contractWeather(kind: any): any
    local key = if type(kind) == "string" then string.lower(kind) else "clear"
    return CONTRACT_WEATHER[key] or CONTRACT_WEATHER.clear
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
