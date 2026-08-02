--!strict

local Config = require("./Config")

local CombatState = {}

export type State = {
    dodgeInvulnerableUntil: number,
    dodgeReadyAt: number,
    lastUpdatedAt: number,
    regenBlockedUntil: number,
    revision: number,
    sprinting: boolean,
    stamina: number,
}
export type TransitionResult = {
    applied: boolean,
    reason: string?,
    stamina: number,
}
export type Snapshot = {
    dodgeActive: boolean,
    dodgeActiveUntil: number,
    dodgeCost: number,
    dodgeReadyAt: number,
    lowStamina: boolean,
    maxStamina: number,
    revision: number,
    sprinting: boolean,
    stamina: number,
}

local MAX_STAMINA = Config.MaxStamina
local SPRINT_DRAIN_PER_SECOND = Config.SprintDrainPerSecond
local STAMINA_REGEN_PER_SECOND = Config.StaminaRegenPerSecond
local STAMINA_REGEN_DELAY_SECONDS = Config.StaminaRegenDelaySeconds
local MIN_SPRINT_STAMINA = Config.MinSprintStamina
local DODGE_COST = Config.DodgeStaminaCost
local DODGE_COOLDOWN_SECONDS = Config.DodgeCooldownSeconds
local DODGE_INVULNERABILITY_SECONDS = Config.DodgeInvulnerabilitySeconds

local function finiteNumber(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function copyAt(state: State, now: number): State
    local nextState: State = table.clone(state)
    nextState.lastUpdatedAt = math.max(state.lastUpdatedAt, now)
    return nextState
end

function CombatState.create(now: number): State
    assert(finiteNumber(now), "combat state time is invalid")
    return {
        dodgeInvulnerableUntil = now,
        dodgeReadyAt = now,
        lastUpdatedAt = now,
        regenBlockedUntil = now,
        revision = 0,
        sprinting = false,
        stamina = MAX_STAMINA,
    }
end

--[[
    `moving` defaults to true so existing callers keep their behaviour, but the
    service passes the player's real movement. Standing still with run toggled
    on used to drain the bar to nothing while the character had not gone
    anywhere, which reads as a bug and punishes a player for pausing to look
    around. Sprint now only costs while actually sprinting somewhere.
]]
function CombatState.advance(
    state: State,
    now: number,
    canAct: boolean,
    staminaRegenMultiplier: number?,
    moving: boolean?
): State
    assert(finiteNumber(now), "combat state time is invalid")
    local nextState = copyAt(state, now)
    local delta = math.max(0, now - state.lastUpdatedAt)
    local changed = false

    if not canAct and nextState.sprinting then
        nextState.sprinting = false
        changed = true
    end

    local spending = nextState.sprinting and canAct and moving ~= false
    if spending then
        local stamina = math.max(0, state.stamina - SPRINT_DRAIN_PER_SECOND * delta)
        if stamina ~= state.stamina then
            nextState.stamina = stamina
            nextState.regenBlockedUntil = now + STAMINA_REGEN_DELAY_SECONDS
            changed = true
        end
        if nextState.stamina <= 0 then
            nextState.sprinting = false
        end
    elseif canAct and now >= state.regenBlockedUntil and state.stamina < MAX_STAMINA then
        local regenMultiplier = math.clamp(
            if finiteNumber(staminaRegenMultiplier) then staminaRegenMultiplier :: number else 1,
            0.75,
            1.5
        )
        local stamina = math.min(
            MAX_STAMINA,
            state.stamina + STAMINA_REGEN_PER_SECOND * regenMultiplier * delta
        )
        if stamina ~= state.stamina then
            nextState.stamina = stamina
            changed = true
        end
    end

    if changed then
        nextState.revision += 1
    end
    return nextState
end

function CombatState.setSprint(
    state: State,
    enabled: boolean,
    now: number,
    canAct: boolean,
    staminaRegenMultiplier: number?
): (State, TransitionResult)
    local nextState = CombatState.advance(state, now, canAct, staminaRegenMultiplier)
    if enabled then
        if not canAct then
            return nextState,
                {
                    applied = false,
                    reason = "player_cannot_act",
                    stamina = nextState.stamina,
                }
        end
        if nextState.sprinting then
            return nextState,
                {
                    applied = false,
                    reason = "already_sprinting",
                    stamina = nextState.stamina,
                }
        end
        if nextState.stamina < MIN_SPRINT_STAMINA then
            return nextState,
                {
                    applied = false,
                    reason = "insufficient_stamina",
                    stamina = nextState.stamina,
                }
        end
        nextState.sprinting = true
        nextState.revision += 1
        return nextState,
            {
                applied = true,
                stamina = nextState.stamina,
            }
    end

    if not nextState.sprinting then
        return nextState,
            {
                applied = false,
                reason = "already_stopped",
                stamina = nextState.stamina,
            }
    end
    nextState.sprinting = false
    nextState.regenBlockedUntil = now + STAMINA_REGEN_DELAY_SECONDS
    nextState.revision += 1
    return nextState, {
        applied = true,
        stamina = nextState.stamina,
    }
end

function CombatState.dodge(
    state: State,
    now: number,
    canAct: boolean,
    staminaRegenMultiplier: number?
): (State, TransitionResult)
    local nextState = CombatState.advance(state, now, canAct, staminaRegenMultiplier)
    if not canAct then
        return nextState,
            {
                applied = false,
                reason = "player_cannot_act",
                stamina = nextState.stamina,
            }
    end
    if now < nextState.dodgeReadyAt then
        return nextState,
            {
                applied = false,
                reason = "dodge_cooldown",
                stamina = nextState.stamina,
            }
    end
    if nextState.stamina < DODGE_COST then
        return nextState,
            {
                applied = false,
                reason = "insufficient_stamina",
                stamina = nextState.stamina,
            }
    end

    nextState.stamina -= DODGE_COST
    nextState.sprinting = false
    nextState.dodgeInvulnerableUntil = now + DODGE_INVULNERABILITY_SECONDS
    nextState.dodgeReadyAt = now + DODGE_COOLDOWN_SECONDS
    nextState.regenBlockedUntil = now + STAMINA_REGEN_DELAY_SECONDS
    nextState.revision += 1
    return nextState, {
        applied = true,
        stamina = nextState.stamina,
    }
end

-- Instant, non-time-based restore (a consumed item's effect, not regen), so
-- it still routes through advance() first to settle any pending drain/regen
-- up to `now` before adding the flat amount, the same way dodge and
-- setSprint never mutate stamina without advancing state first.
function CombatState.restoreStamina(
    state: State,
    now: number,
    amount: number,
    canAct: boolean,
    staminaRegenMultiplier: number?
): (State, TransitionResult)
    local nextState = CombatState.advance(state, now, canAct, staminaRegenMultiplier)
    if not canAct then
        return nextState,
            {
                applied = false,
                reason = "player_cannot_act",
                stamina = nextState.stamina,
            }
    end
    local stamina = math.min(MAX_STAMINA, nextState.stamina + math.max(0, amount))
    if stamina == nextState.stamina then
        return nextState,
            {
                applied = false,
                reason = "stamina_full",
                stamina = nextState.stamina,
            }
    end
    nextState.stamina = stamina
    nextState.revision += 1
    return nextState, {
        applied = true,
        stamina = nextState.stamina,
    }
end

function CombatState.avoidsDamage(state: State, now: number): boolean
    return now < state.dodgeInvulnerableUntil
end

function CombatState.snapshot(state: State, now: number): Snapshot
    local stamina = math.clamp(math.floor(state.stamina), 0, MAX_STAMINA)
    return {
        dodgeActive = CombatState.avoidsDamage(state, now),
        dodgeActiveUntil = state.dodgeInvulnerableUntil,
        dodgeCost = DODGE_COST,
        dodgeReadyAt = state.dodgeReadyAt,
        lowStamina = stamina < DODGE_COST,
        maxStamina = MAX_STAMINA,
        revision = state.revision,
        sprinting = state.sprinting,
        stamina = stamina,
    }
end

CombatState.Constants = table.freeze({
    DodgeCooldownSeconds = DODGE_COOLDOWN_SECONDS,
    DodgeCost = DODGE_COST,
    DodgeInvulnerabilitySeconds = DODGE_INVULNERABILITY_SECONDS,
    MaxStamina = MAX_STAMINA,
    MinSprintStamina = MIN_SPRINT_STAMINA,
    SprintDrainPerSecond = SPRINT_DRAIN_PER_SECOND,
    StaminaRegenPerSecond = STAMINA_REGEN_PER_SECOND,
})

return table.freeze(CombatState)
