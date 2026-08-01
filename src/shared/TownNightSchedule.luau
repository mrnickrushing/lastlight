--!strict

local TownNightSchedule = {}

export type Beat = {
    at: number,
    kind: "spawn" | "warning" | "breach",
    enemyId: string?,
    theme: string?,
    wave: number?,
}

-- The same six-enemy Bramblewake roster the authored first night uses. Normal
-- nights reuse it rather than adding new content: escalating pressure comes
-- from wave count, not new enemies, until a later production pass adds
-- night-specific variety.
local ROSTER: { string } = {
    "enemy_rootling",
    "enemy_briarback",
    "enemy_pollen_wisp",
    "enemy_hollow_crow",
    "enemy_snapvine",
    "enemy_bark_ram",
}

local MIN_WAVES = 3
local MAX_WAVES = 8
local THEMES = table.freeze({ "EMBERFALL", "MIRETIDE", "ROOTMOON", "ASHEN VEIL" })
local THEME_PROFILES = table.freeze({
    EMBERFALL = table.freeze({
        id = "EMBERFALL",
        instruction = "KEEP ATTACKERS OFF THE FIRST LANTERN",
        healthMultiplier = 1,
        speedMultiplier = 1,
        playerDamageMultiplier = 1,
        lanternDamageMultiplier = 1.25,
    }),
    MIRETIDE = table.freeze({
        id = "MIRETIDE",
        instruction = "SLOW ADVANCE · HEAVIER BLOWS",
        healthMultiplier = 1,
        speedMultiplier = 0.82,
        playerDamageMultiplier = 1.2,
        lanternDamageMultiplier = 1,
    }),
    ROOTMOON = table.freeze({
        id = "ROOTMOON",
        instruction = "ARMORED GROWTH · FOCUS EACH TARGET",
        healthMultiplier = 1.25,
        speedMultiplier = 0.94,
        playerDamageMultiplier = 1,
        lanternDamageMultiplier = 1,
    }),
    ["ASHEN VEIL"] = table.freeze({
        id = "ASHEN VEIL",
        instruction = "FRAGILE HUNTERS · FAST APPROACH",
        healthMultiplier = 0.85,
        speedMultiplier = 1.25,
        playerDamageMultiplier = 1,
        lanternDamageMultiplier = 1,
    }),
})

function TownNightSchedule.theme(nightNumber: number): string
    assert(nightNumber >= 1 and nightNumber == math.floor(nightNumber), "night number is invalid")
    return THEMES[(nightNumber - 1) % #THEMES + 1]
end

function TownNightSchedule.profile(nightNumber: number): any
    local theme = TownNightSchedule.theme(nightNumber)
    return THEME_PROFILES[theme]
end

function TownNightSchedule.waveCount(nightNumber: number): number
    assert(
        nightNumber >= 1 and nightNumber == math.floor(nightNumber),
        "night number must be a positive integer"
    )
    return math.clamp(MIN_WAVES - 1 + nightNumber, MIN_WAVES, MAX_WAVES)
end

-- Deterministic by design (no randomness) so a night's wave layout is fully
-- reproducible and testable, matching this project's existing expedition and
-- first-night schedules.
function TownNightSchedule.beats(duration: number, nightNumber: number): { Beat }
    assert(duration > 0, "duration must be positive")
    local waves = TownNightSchedule.waveCount(nightNumber)
    local theme = TownNightSchedule.theme(nightNumber)
    local result: { Beat } = {
        { at = 0, kind = "warning", enemyId = nil, theme = theme, wave = nil },
    }

    local windowStart = duration * 0.05
    local windowEnd = duration * 0.85
    local span = math.max(windowEnd - windowStart, 0)
    local breachAfterWave = math.ceil(waves / 2)
    local lastValidAt = math.max(duration - 1, 0)

    for index = 1, waves do
        local at = if waves == 1
            then windowStart
            else windowStart + span * (index - 1) / (waves - 1)
        at = math.min(at, lastValidAt)
        local rosterIndex = (index - 1 + nightNumber - 1) % #ROSTER + 1
        local enemyId = ROSTER[rosterIndex]
        table.insert(
            result,
            { at = at, kind = "spawn", enemyId = enemyId, theme = theme, wave = index }
        )
        if index == breachAfterWave then
            table.insert(result, {
                at = math.min(at + 1, lastValidAt),
                kind = "breach",
                enemyId = nil,
                theme = theme,
                wave = index,
            })
        end
    end

    table.sort(result, function(a, b)
        return a.at < b.at
    end)
    return result
end

function TownNightSchedule.pending(duration: number, nightNumber: number, elapsed: number): { Beat }
    local result: { Beat } = {}
    for _, beat in TownNightSchedule.beats(duration, nightNumber) do
        if beat.at >= elapsed then
            table.insert(result, beat)
        end
    end
    return result
end

return table.freeze(TownNightSchedule)
