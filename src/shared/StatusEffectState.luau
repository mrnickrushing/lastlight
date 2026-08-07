--!strict

local StatusEffectState = {}

export type State = {
    drowsyUntil: number,
    drowsyMultiplier: number,
    rootedUntil: number,
    rootedMultiplier: number,
    shieldUntil: number,
    shieldMultiplier: number,
}

export type Snapshot = {
    drowsy: boolean,
    drowsyUntil: number,
    movementMultiplier: number,
    rooted: boolean,
    rootedUntil: number,
    shielded: boolean,
    shieldUntil: number,
    damageMultiplier: number,
}

function StatusEffectState.create(): State
    return {
        drowsyUntil = 0,
        drowsyMultiplier = 1,
        rootedUntil = 0,
        rootedMultiplier = 1,
        shieldUntil = 0,
        shieldMultiplier = 1,
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

-- Reduces incoming damage for a short window, the same duration+multiplier
-- shape applyDrowsy/applyRooted already use for movement, just applied to
-- damage instead. Kept independent of ProfessionService's Warden-only
-- mitigateIncomingDamage so an item-granted shield can stack with (rather
-- than replace) a profession's own guard ability.
function StatusEffectState.applyShield(
    state: State,
    now: number,
    duration: number,
    multiplier: number
): State
    local nextState = table.clone(state)
    local untilTime = now + math.max(0, duration)
    if untilTime >= state.shieldUntil then
        nextState.shieldUntil = untilTime
        nextState.shieldMultiplier = math.clamp(multiplier, 0.1, 1)
    end
    return nextState
end

function StatusEffectState.clear(_state: State): State
    return StatusEffectState.create()
end

--[[
    Clear what was done to you, and only that.

    A player drinking something to shake off a rooting or a drowsiness
    must not also lose the shield they just put up -- that would make the
    cure worse than the condition in exactly the moment it is reached
    for. So this drops drowsy and rooted and leaves the shield alone,
    which is the difference between a cure and a reset.
]]
function StatusEffectState.clearAfflictions(state: State): (State, boolean)
    local nextState = table.clone(state)
    local had = state.drowsyUntil > 0 or state.rootedUntil > 0
    nextState.drowsyUntil = 0
    nextState.drowsyMultiplier = 1
    nextState.rootedUntil = 0
    nextState.rootedMultiplier = 1
    return nextState, had
end

-- Whether anything is currently being done to this player, which is the
-- precondition a cure has to clear before it is spent.
function StatusEffectState.afflicted(state: State, now: number): boolean
    return now < state.drowsyUntil or now < state.rootedUntil
end

function StatusEffectState.snapshot(state: State, now: number): Snapshot
    local active = now < state.drowsyUntil
    local rooted = now < state.rootedUntil
    local shielded = now < state.shieldUntil
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
        shielded = shielded,
        shieldUntil = if shielded then state.shieldUntil else 0,
        damageMultiplier = if shielded then state.shieldMultiplier else 1,
    }
end

return table.freeze(StatusEffectState)
