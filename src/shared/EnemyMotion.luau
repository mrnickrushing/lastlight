--!strict

local EnemyMotion = {}

export type Pose = {
    height: number,
    pitch: number,
    roll: number,
}

local HOVERING = table.freeze({
    hollow_crow = true,
})

local function profile(modelKey: string): (number, number)
    if HOVERING[modelKey] then
        return 0.52, 2.45
    elseif modelKey == "zombie" then
        -- Slow, heavy, uneven: a shamble rather than a stride.
        return 0.16, 3.1
    elseif modelKey == "bark_ram" then
        return 0.13, 7.2
    elseif modelKey == "briarback" then
        return 0.11, 5.4
    elseif modelKey == "snapvine" then
        return 0.08, 1.8
    end
    return 0.15, 6.2
end

function EnemyMotion.pose(
    elapsed: number,
    modelKey: string,
    state: string,
    attackProgress: number?
): Pose
    local amplitude, frequency = profile(modelKey)
    local wave = elapsed * frequency
    local hovering = HOVERING[modelKey] == true
    local height = if hovering
        then math.sin(wave) * amplitude
        elseif state == "moving" then math.abs(math.sin(wave)) * amplitude
        else math.sin(wave * 0.42) * amplitude * 0.28
    local pitch = if state == "moving" then math.sin(wave) * math.rad(1.8) else 0
    local roll = if hovering
        then math.sin(wave * 0.63) * math.rad(3.2)
        else math.sin(wave * 0.5) * math.rad(1.1)

    if state == "attacking" then
        local progress = math.clamp(attackProgress or 0, 0, 1)
        local anticipation = math.sin(progress * math.pi * 0.5)
        height += if hovering then anticipation * 0.26 else -anticipation * 0.08
        pitch -= anticipation * math.rad(if modelKey == "bark_ram" then 13 else 8)
        roll *= 1 - anticipation * 0.7
    end

    return {
        height = height,
        pitch = pitch,
        roll = roll,
    }
end

return table.freeze(EnemyMotion)
