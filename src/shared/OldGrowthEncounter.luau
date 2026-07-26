--!strict

local OldGrowthEncounter = {}

export type Status = "disabled" | "dormant" | "vulnerable" | "shielded" | "complete"

export type State = {
    carriers: { [string]: number },
    health: number,
    manifestHash: string,
    participants: { [string]: boolean },
    revision: number,
    runId: string,
    shieldIndex: number,
    status: Status,
}

local MAX_HEALTH = 360
local FIRE_CARRY_SECONDS = 15
local SHIELD_THRESHOLDS = table.freeze({ 240, 120 })

local ROOT_LANE = table.freeze({
    attackId = "old_growth_root_lane",
    attackName = "CATHEDRAL ROOTS",
    damage = 20,
    instruction = "CLEAR THE ROOT LANE",
    length = 32,
    rootedDuration = 1.6,
    rootedMultiplier = 0.35,
    shape = "lane",
    width = 9,
    windup = 1.35,
})

local CANOPY_FALL = table.freeze({
    attackId = "old_growth_canopy_fall",
    attackName = "CANOPY FALL",
    damage = 28,
    instruction = "LEAVE THE FALL RING",
    radius = 10,
    shape = "circle",
    windup = 1.55,
})

OldGrowthEncounter.Id = "elite_old_growth"
OldGrowthEncounter.MaxHealth = MAX_HEALTH
OldGrowthEncounter.FireCarrySeconds = FIRE_CARRY_SECONDS
OldGrowthEncounter.Reward = table.freeze({
    amount = 3,
    materialId = "material_amber_sap",
})

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.carriers = table.clone(state.carriers)
    nextState.participants = table.clone(state.participants)
    return nextState
end

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "participant user ID is invalid")
    return tostring(userId)
end

function OldGrowthEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Old Growth run ID is required")
    assert(manifestHash ~= "", "Old Growth manifest hash is required")
    return {
        carriers = {},
        health = MAX_HEALTH,
        manifestHash = manifestHash,
        participants = {},
        revision = 0,
        runId = runId,
        shieldIndex = 0,
        status = if enabled then "dormant" else "disabled",
    }
end

function OldGrowthEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, {
            accepted = false,
            reason = state.status,
        }
    end
    local nextState = cloneState(state)
    nextState.status = "vulnerable"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            activated = true,
            reason = "activated",
        }
end

function OldGrowthEncounter.join(state: State, userId: number): State
    if state.status ~= "vulnerable" and state.status ~= "shielded" then
        return state
    end
    local key = participantKey(userId)
    if state.participants[key] then
        return state
    end
    local nextState = cloneState(state)
    nextState.participants[key] = true
    nextState.revision += 1
    return nextState
end

function OldGrowthEncounter.strike(state: State, userId: number, amount: number): (State, any)
    assert(amount > 0 and amount <= 100, "Old Growth strike amount is invalid")
    if state.status ~= "vulnerable" then
        return state, {
            accepted = false,
            reason = state.status,
        }
    end

    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    local nextHealth = math.max(0, state.health - amount)
    local threshold = SHIELD_THRESHOLDS[state.shieldIndex + 1]
    local shieldStarted = threshold ~= nil and nextHealth <= threshold
    if shieldStarted then
        nextState.health = threshold
        nextState.shieldIndex += 1
        nextState.status = "shielded"
    else
        nextState.health = nextHealth
        if nextHealth <= 0 then
            nextState.status = "complete"
            nextState.carriers = {}
        end
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            completed = nextState.status == "complete",
            damage = state.health - nextState.health,
            health = nextState.health,
            reason = if nextState.status == "complete"
                then "completed"
                elseif shieldStarted then "shield_started"
                else "damaged",
            shieldStarted = shieldStarted,
        }
end

function OldGrowthEncounter.takeFire(state: State, userId: number, now: number): (State, any)
    if state.status ~= "shielded" then
        return state, {
            accepted = false,
            reason = state.status,
        }
    end
    local key = participantKey(userId)
    for carrierKey, expiresAt in state.carriers do
        if carrierKey ~= key and now < expiresAt then
            return state,
                {
                    accepted = false,
                    reason = "fire_claimed",
                }
        end
    end
    local nextState = cloneState(state)
    nextState.carriers[key] = now + FIRE_CARRY_SECONDS
    nextState.participants[key] = true
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            expiresAt = nextState.carriers[key],
            reason = "fire_taken",
        }
end

function OldGrowthEncounter.burnHeart(state: State, userId: number, now: number): (State, any)
    if state.status ~= "shielded" then
        return state, {
            accepted = false,
            reason = state.status,
        }
    end
    local key = participantKey(userId)
    local expiresAt = state.carriers[key]
    if expiresAt == nil or now >= expiresAt then
        return state,
            {
                accepted = false,
                reason = "fire_required",
            }
    end
    local nextState = cloneState(state)
    nextState.carriers = {}
    nextState.participants[key] = true
    nextState.status = "vulnerable"
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            reason = "shield_burned",
            shieldIndex = nextState.shieldIndex,
        }
end

function OldGrowthEncounter.expire(state: State, now: number): State
    local expired = false
    local nextState = cloneState(state)
    for key, expiresAt in nextState.carriers do
        if now >= expiresAt then
            nextState.carriers[key] = nil
            expired = true
        end
    end
    if expired then
        nextState.revision += 1
        return nextState
    end
    return state
end

function OldGrowthEncounter.attack(attackIndex: number, shieldIndex: number): any
    if shieldIndex >= 1 and attackIndex % 2 == 0 then
        return CANOPY_FALL
    end
    return ROOT_LANE
end

function OldGrowthEncounter.snapshot(state: State, userId: number, now: number): any
    local expiresAt = state.carriers[tostring(userId)] or 0
    local carryingFire = now < expiresAt
    local instruction = if state.status == "shielded"
        then if carryingFire then "CARRY FIRE TO THE ROOT HEART" else "TAKE LANTERN FIRE"
        elseif state.status == "vulnerable" then "STRIKE THE AMBER HEART"
        elseif state.status == "complete" then "OLD GROWTH CLEANSED"
        elseif state.status == "disabled" then "ELITE TEMPORARILY DORMANT"
        else "ENTER THE OLD GROWTH ARENA"
    return {
        active = state.status == "vulnerable" or state.status == "shielded",
        carryingFire = carryingFire,
        complete = state.status == "complete",
        displayName = "OLD GROWTH",
        enabled = state.status ~= "disabled",
        fireExpiresAt = if carryingFire then expiresAt else 0,
        health = state.health,
        instruction = instruction,
        maxHealth = MAX_HEALTH,
        phase = math.min(3, state.shieldIndex + 1),
        revision = state.revision,
        shielded = state.status == "shielded",
        shieldIndex = state.shieldIndex,
        status = state.status,
    }
end

function OldGrowthEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        OldGrowthEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(OldGrowthEncounter)
