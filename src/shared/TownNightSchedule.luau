--!strict

local Strings = require("./Strings")

local TownNightSchedule = {}

export type Beat = {
    at: number,
    kind: "spawn" | "warning" | "breach" | "incident",
    enemyId: string?,
    incidentId: string?,
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
    "enemy_zombie",
    "enemy_hollow_crow",
    "enemy_snapvine",
    "enemy_bark_ram",
}

local MIN_WAVES = 3
local MAX_WAVES = 8
-- The director's ceiling for a full party. Solo nights keep MAX_WAVES; the
-- extra headroom only opens as real defenders stand in the town.
local MAX_WAVES_GROUP = 12
--[[
	A night's theme is an **id**, and it did not used to be.

	It was the word EMBERFALL: a table key here, a table key in
	TownNightIncident, the value WorldService compares to choose which dressing
	to raise and what colour the lantern road glows -- and the same word printed
	at the player in "EMBERFALL NIGHT 3". That works in exactly one language.
	Translate it and the schedule keeps returning the English word (so the
	dressing still builds) while the player reads English, or translate the
	table too and every lookup misses and every night becomes amber. There is no
	version of it that is right, because it is one string doing two jobs.

	So the id is lowercase and never shown, `displayName` is the word, and
	WorldService compares the id.
]]
local THEMES = table.freeze({ "emberfall", "miretide", "rootmoon", "ashen_veil" })
local THEME_PROFILES = table.freeze({
    emberfall = table.freeze({
        id = "emberfall",
        name = Strings.get("world.emberfall"),
        instruction = Strings.get("town.keep_attackers_off_the_first_lantern"),
        healthMultiplier = 1,
        speedMultiplier = 1,
        playerDamageMultiplier = 1,
        lanternDamageMultiplier = 1.25,
    }),
    miretide = table.freeze({
        id = "miretide",
        name = Strings.get("world.miretide"),
        instruction = Strings.get("town.slow_advance_heavier_blows"),
        healthMultiplier = 1,
        speedMultiplier = 0.82,
        playerDamageMultiplier = 1.2,
        lanternDamageMultiplier = 1,
    }),
    rootmoon = table.freeze({
        id = "rootmoon",
        name = Strings.get("world.rootmoon"),
        instruction = Strings.get("town.armored_growth_focus_each_target"),
        healthMultiplier = 1.25,
        speedMultiplier = 0.94,
        playerDamageMultiplier = 1,
        lanternDamageMultiplier = 1,
    }),
    ashen_veil = table.freeze({
        id = "ashen_veil",
        name = Strings.get("world.ashen_veil"),
        instruction = Strings.get("town.fragile_hunters_fast_approach"),
        healthMultiplier = 0.85,
        speedMultiplier = 1.25,
        playerDamageMultiplier = 1,
        lanternDamageMultiplier = 1,
    }),
})

-- The word for a theme, for the one job the id must not do.
function TownNightSchedule.displayName(theme: string): string
    local profile = THEME_PROFILES[theme]
    assert(profile ~= nil, `TownNightSchedule.displayName: no theme "{theme}"`)
    return profile.name
end

function TownNightSchedule.theme(nightNumber: number): string
    assert(nightNumber >= 1 and nightNumber == math.floor(nightNumber), "night number is invalid")
    return THEMES[(nightNumber - 1) % #THEMES + 1]
end

function TownNightSchedule.profile(nightNumber: number): any
    local theme = TownNightSchedule.theme(nightNumber)
    return THEME_PROFILES[theme]
end

--[[
    The enemy director, in one function: the night's pressure scales with
    how many defenders actually stand in the town. partySize 1 (or absent)
    is EXACTLY the pre-director schedule -- solo nights were tuned to
    breathe and this must not move them -- and each additional eligible
    defender adds one wave, up to a group ceiling above the solo cap.
    Deterministic like everything else in this module: same night, same
    party size, same layout.
]]
function TownNightSchedule.waveCount(nightNumber: number, partySize: number?): number
    assert(
        nightNumber >= 1 and nightNumber == math.floor(nightNumber),
        "night number must be a positive integer"
    )
    local solo = math.clamp(MIN_WAVES - 1 + nightNumber, MIN_WAVES, MAX_WAVES)
    local size = if type(partySize) == "number" and partySize == partySize
        then math.clamp(math.floor(partySize), 1, 8)
        else 1
    return math.clamp(solo + (size - 1), MIN_WAVES, MAX_WAVES_GROUP)
end

-- Deterministic by design (no randomness) so a night's wave layout is fully
-- reproducible and testable, matching this project's existing expedition and
-- first-night schedules.
function TownNightSchedule.beats(
    duration: number,
    nightNumber: number,
    partySize: number?
): { Beat }
    assert(duration > 0, "duration must be positive")
    local waves = TownNightSchedule.waveCount(nightNumber, partySize)
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

    table.insert(result, {
        at = math.min(duration * 0.58, lastValidAt),
        kind = "incident",
        enemyId = nil,
        incidentId = "theme_incident",
        theme = theme,
        wave = nil,
    })

    table.sort(result, function(a, b)
        return a.at < b.at
    end)
    return result
end

function TownNightSchedule.pending(
    duration: number,
    nightNumber: number,
    elapsed: number,
    partySize: number?
): { Beat }
    local result: { Beat } = {}
    for _, beat in TownNightSchedule.beats(duration, nightNumber, partySize) do
        if beat.at >= elapsed then
            table.insert(result, beat)
        end
    end
    return result
end

return table.freeze(TownNightSchedule)
