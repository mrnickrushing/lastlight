--!strict

local Config = require("./Config")

local SurvivalState = {}

export type Status = "active" | "downed"
export type State = {
    bleedoutAt: number?,
    downedAt: number?,
    health: number,
    invulnerableUntil: number,
    maxHealth: number,
    revision: number,
    status: Status,
}
export type TransitionResult = {
    applied: boolean,
    damage: number?,
    healed: number?,
    downed: boolean?,
    health: number?,
    reason: string?,
}
export type Snapshot = {
    bleedoutAt: number?,
    downed: boolean,
    downedDuration: number,
    health: number,
    invulnerable: boolean,
    maxHealth: number,
    revision: number,
    timeRemaining: number,
}

local MAX_HEALTH = Config.MaxHealth
local DOWNED_SECONDS = Config.DownedSeconds
local REVIVE_HEALTH = Config.ReviveHealth
local RECOVERY_HEALTH = Config.RecoveryHealth
local REVIVE_INVULNERABILITY_SECONDS = Config.ReviveInvulnerabilitySeconds
local RECOVERY_INVULNERABILITY_SECONDS = Config.RecoveryInvulnerabilitySeconds

local function validNumber(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function SurvivalState.create(now: number): State
    assert(validNumber(now), "survival state time is invalid")
    return {
        health = MAX_HEALTH,
        maxHealth = MAX_HEALTH,
        status = "active",
        downedAt = nil,
        bleedoutAt = nil,
        invulnerableUntil = now,
        revision = 0,
    }
end

function SurvivalState.damage(state: State, amount: number, now: number): (State, TransitionResult)
    if not validNumber(amount) or amount <= 0 or amount ~= math.floor(amount) then
        return state,
            {
                applied = false,
                reason = "invalid_damage",
            }
    end
    if state.status ~= "active" then
        return state, {
            applied = false,
            reason = "player_downed",
        }
    end
    if now < state.invulnerableUntil then
        return state, {
            applied = false,
            reason = "invulnerable",
        }
    end

    local nextState: State = table.clone(state)
    nextState.health = math.max(0, state.health - amount)
    nextState.revision += 1
    local downed = nextState.health == 0
    if downed then
        nextState.status = "downed"
        nextState.downedAt = now
        nextState.bleedoutAt = now + DOWNED_SECONDS
    end
    return nextState,
        {
            applied = true,
            damage = math.min(amount, state.health),
            downed = downed,
        }
end

function SurvivalState.heal(state: State, amount: number): (State, TransitionResult)
    if not validNumber(amount) or amount <= 0 or amount ~= math.floor(amount) then
        return state, {
            applied = false,
            reason = "invalid_heal",
        }
    end
    if state.status ~= "active" then
        return state, {
            applied = false,
            reason = "player_downed",
        }
    end
    if state.health >= state.maxHealth then
        return state, {
            applied = false,
            reason = "full_health",
        }
    end

    local nextState: State = table.clone(state)
    nextState.health = math.min(state.maxHealth, state.health + amount)
    nextState.revision += 1
    return nextState,
        {
            applied = true,
            healed = nextState.health - state.health,
            health = nextState.health,
        }
end

function SurvivalState.revive(state: State, now: number, tuning: any?): (State, TransitionResult)
    if state.status ~= "downed" then
        return state,
            {
                applied = false,
                reason = "player_not_downed",
            }
    end
    if type(state.bleedoutAt) ~= "number" or now >= state.bleedoutAt then
        return state,
            {
                applied = false,
                reason = "bleedout_expired",
            }
    end

    local reviveHealth = if type(tuning) == "table" and validNumber(tuning.health)
        then math.clamp(math.floor(tuning.health), REVIVE_HEALTH, state.maxHealth)
        else REVIVE_HEALTH
    local wardSeconds = if type(tuning) == "table" and validNumber(tuning.wardSeconds)
        then math.clamp(tuning.wardSeconds, REVIVE_INVULNERABILITY_SECONDS, 6)
        else REVIVE_INVULNERABILITY_SECONDS
    local nextState: State = table.clone(state)
    nextState.health = reviveHealth
    nextState.status = "active"
    nextState.downedAt = nil
    nextState.bleedoutAt = nil
    nextState.invulnerableUntil = now + wardSeconds
    nextState.revision += 1
    return nextState, {
        applied = true,
        health = nextState.health,
    }
end

function SurvivalState.recover(state: State, now: number): (State, TransitionResult)
    if state.status ~= "downed" then
        return state,
            {
                applied = false,
                reason = "player_not_downed",
            }
    end
    if type(state.bleedoutAt) ~= "number" or now < state.bleedoutAt then
        return state,
            {
                applied = false,
                reason = "bleedout_active",
            }
    end

    local nextState: State = table.clone(state)
    nextState.health = RECOVERY_HEALTH
    nextState.status = "active"
    nextState.downedAt = nil
    nextState.bleedoutAt = nil
    nextState.invulnerableUntil = now + RECOVERY_INVULNERABILITY_SECONDS
    nextState.revision += 1
    return nextState, {
        applied = true,
        health = nextState.health,
    }
end

function SurvivalState.safeRetreat(state: State, now: number): (State, TransitionResult)
    if state.status ~= "downed" then
        return state,
            {
                applied = false,
                reason = "player_not_downed",
            }
    end

    local nextState: State = table.clone(state)
    nextState.health = RECOVERY_HEALTH
    nextState.status = "active"
    nextState.downedAt = nil
    nextState.bleedoutAt = nil
    nextState.invulnerableUntil = now + RECOVERY_INVULNERABILITY_SECONDS
    nextState.revision += 1
    return nextState, {
        applied = true,
        health = nextState.health,
    }
end

function SurvivalState.respawn(state: State, now: number): State
    local nextState: State = table.clone(state)
    nextState.health = RECOVERY_HEALTH
    nextState.status = "active"
    nextState.downedAt = nil
    nextState.bleedoutAt = nil
    nextState.invulnerableUntil = now + RECOVERY_INVULNERABILITY_SECONDS
    nextState.revision += 1
    return nextState
end

function SurvivalState.canAct(state: State): boolean
    return state.status == "active" and state.health > 0
end

function SurvivalState.snapshot(state: State, now: number): Snapshot
    local bleedoutAt = if type(state.bleedoutAt) == "number" then state.bleedoutAt else nil
    return {
        bleedoutAt = bleedoutAt,
        downed = state.status == "downed",
        downedDuration = DOWNED_SECONDS,
        health = state.health,
        invulnerable = now < state.invulnerableUntil,
        maxHealth = state.maxHealth,
        revision = state.revision,
        timeRemaining = if bleedoutAt == nil then 0 else math.max(0, math.ceil(bleedoutAt - now)),
    }
end

SurvivalState.Constants = table.freeze({
    DownedSeconds = DOWNED_SECONDS,
    MaxHealth = MAX_HEALTH,
    RecoveryHealth = RECOVERY_HEALTH,
    ReviveHealth = REVIVE_HEALTH,
})

return table.freeze(SurvivalState)
