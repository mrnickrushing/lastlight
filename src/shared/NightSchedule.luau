--!strict

local NightSchedule = {}

export type Beat = {
    at: number,
    kind: "spawn" | "warning" | "breach",
    enemyId: string?,
}

local BEATS: { Beat } = {
    { at = 0, kind = "warning", enemyId = nil },
    { at = 4, kind = "spawn", enemyId = "enemy_rootling" },
    { at = 22, kind = "spawn", enemyId = "enemy_briarback" },
    { at = 40, kind = "spawn", enemyId = "enemy_zombie" },
    { at = 56, kind = "breach", enemyId = nil },
    { at = 58, kind = "spawn", enemyId = "enemy_hollow_crow" },
    { at = 76, kind = "spawn", enemyId = "enemy_snapvine" },
    { at = 94, kind = "spawn", enemyId = "enemy_bark_ram" },
}

function NightSchedule.beats(duration: number): { Beat }
    local result: { Beat } = {}
    for _, beat in BEATS do
        if beat.at < duration then
            table.insert(result, table.clone(beat))
        end
    end
    return result
end

function NightSchedule.pending(duration: number, elapsed: number): { Beat }
    local result: { Beat } = {}
    for _, beat in NightSchedule.beats(duration) do
        if beat.at >= elapsed then
            table.insert(result, beat)
        end
    end
    return result
end

return table.freeze(NightSchedule)
