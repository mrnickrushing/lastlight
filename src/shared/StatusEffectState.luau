--!strict

local StatusEffectState = {}

export type State = {
    drowsyUntil: number,
    drowsyMultiplier: number,
}

export type Snapshot = {
    drowsy: boolean,
    drowsyUntil: number,
    movementMultiplier: number,
}

function StatusEffectState.create(): State
    return {
        drowsyUntil = 0,
        drowsyMultiplier = 1,
    }
end

function StatusEffectState.applyDrowsy(
    state: State,
    now: number,
    duration: number,
    multiplier: number
): State
    local nextState = table.clone(state)
    local untilTime = now + math.max(0, duration)
    if untilTime >= state.drowsyUntil then
        nextState.drowsyUntil = untilTime
        nextState.drowsyMultiplier = math.clamp(multiplier, 0.25, 1)
    end
    return nextState
end

function StatusEffectState.clear(_state: State): State
    return StatusEffectState.create()
end

function StatusEffectState.snapshot(state: State, now: number): Snapshot
    local active = now < state.drowsyUntil
    return {
        drowsy = active,
        drowsyUntil = if active then state.drowsyUntil else 0,
        movementMultiplier = if active then state.drowsyMultiplier else 1,
    }
end

return table.freeze(StatusEffectState)
