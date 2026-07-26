--!strict

local SurvivalState = {}

local MAX_HEALTH = 100
local DOWNED_SECONDS = 30
local REVIVE_HEALTH = 35
local RECOVERY_HEALTH = 50
local REVIVE_INVULNERABILITY_SECONDS = 3
local RECOVERY_INVULNERABILITY_SECONDS = 5

local function validNumber(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function SurvivalState.create(now: number): any
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

function SurvivalState.damage(state: any, amount: number, now: number): (any, any)
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

    local nextState: any = table.clone(state)
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

function SurvivalState.revive(state: any, now: number): (any, any)
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

    local nextState: any = table.clone(state)
    nextState.health = REVIVE_HEALTH
    nextState.status = "active"
    nextState.downedAt = nil
    nextState.bleedoutAt = nil
    nextState.invulnerableUntil = now + REVIVE_INVULNERABILITY_SECONDS
    nextState.revision += 1
    return nextState, {
        applied = true,
        health = nextState.health,
    }
end

function SurvivalState.recover(state: any, now: number): (any, any)
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

    local nextState: any = table.clone(state)
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

function SurvivalState.safeRetreat(state: any, now: number): (any, any)
    if state.status ~= "downed" then
        return state,
            {
                applied = false,
                reason = "player_not_downed",
            }
    end

    local nextState: any = table.clone(state)
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

function SurvivalState.respawn(state: any, now: number): any
    local nextState: any = table.clone(state)
    nextState.health = RECOVERY_HEALTH
    nextState.status = "active"
    nextState.downedAt = nil
    nextState.bleedoutAt = nil
    nextState.invulnerableUntil = now + RECOVERY_INVULNERABILITY_SECONDS
    nextState.revision += 1
    return nextState
end

function SurvivalState.canAct(state: any): boolean
    return state.status == "active" and state.health > 0
end

function SurvivalState.snapshot(state: any, now: number): any
    local bleedoutAt = if type(state.bleedoutAt) == "number" then state.bleedoutAt else nil
    return {
        bleedoutAt = bleedoutAt,
        downed = state.status == "downed",
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
