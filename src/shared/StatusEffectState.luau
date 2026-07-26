--!strict

local StatusEffectState = {}

export type State = {
    drowsyUntil: number,
    drowsyMultiplier: number,
    rootedUntil: number,
    rootedMultiplier: number,
}

export type Snapshot = {
    drowsy: boolean,
    drowsyUntil: number,
    movementMultiplier: number,
    rooted: boolean,
    rootedUntil: number,
}

function StatusEffectState.create(): State
    return {
        drowsyUntil = 0,
        drowsyMultiplier = 1,
        rootedUntil = 0,
        rootedMultiplier = 1,
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

function StatusEffectState.applyRooted(
    state: State,
    now: number,
    duration: number,
    multiplier: number
): State
    local nextState = table.clone(state)
    local untilTime = now + math.max(0, duration)
    if untilTime >= state.rootedUntil then
        nextState.rootedUntil = untilTime
        nextState.rootedMultiplier = math.clamp(multiplier, 0.25, 1)
    end
    return nextState
end

function StatusEffectState.clear(_state: State): State
    return StatusEffectState.create()
end

function StatusEffectState.snapshot(state: State, now: number): Snapshot
    local active = now < state.drowsyUntil
    local rooted = now < state.rootedUntil
    local movementMultiplier = 1
    if active then
        movementMultiplier = math.min(movementMultiplier, state.drowsyMultiplier)
    end
    if rooted then
        movementMultiplier = math.min(movementMultiplier, state.rootedMultiplier)
    end
    return {
        drowsy = active,
        drowsyUntil = if active then state.drowsyUntil else 0,
        movementMultiplier = movementMultiplier,
        rooted = rooted,
        rootedUntil = if rooted then state.rootedUntil else 0,
    }
end

return table.freeze(StatusEffectState)
