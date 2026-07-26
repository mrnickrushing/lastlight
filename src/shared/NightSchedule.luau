--!strict

local NightSchedule = {}

export type Beat = {
    at: number,
    kind: "spawn" | "warning" | "breach",
}

local BEATS: { Beat } = {
    { at = 0, kind = "warning" },
    { at = 4, kind = "spawn" },
    { at = 38, kind = "spawn" },
    { at = 72, kind = "breach" },
    { at = 76, kind = "spawn" },
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
