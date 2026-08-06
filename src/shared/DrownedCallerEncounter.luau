--!strict

--[[
    The Drowned Caller -- the Fen's second elite.

    It summons through reflected pools. Four of them stand around the
    marsh, and while one still holds a reflection the Caller can reach
    through it: every call brings something up out of the water, and the
    calls come faster the longer the pools are left alone. Breaking a
    reflection is the whole fight -- silt one pool and the Caller loses a
    door and takes the pain of it.

    Where the Many-Face is read-and-time, the Caller is a race against its
    own arithmetic: leave the pools and the summons compound; break them
    and the fight quiets, but every break costs you the walk to it while
    something new is already climbing out. Its damage does not come from
    the Caller at all, which is the point -- it never attacks you directly
    until the last pool goes dark.

    Same contract as every elite: profession-independent, solo-passable,
    one reward per participant per run through a deterministic
    transaction id, disable-able, every mutation server-called.
]]

local DrownedCallerEncounter = {}

export type Status = "disabled" | "dormant" | "calling" | "exposed" | "complete"

export type State = {
    health: number,
    manifestHash: string,
    participants: { [string]: boolean },
    pools: { [string]: boolean },
    revision: number,
    runId: string,
    status: Status,
    summoned: number,
}

local MAX_HEALTH = 280
local POOL_IDS = table.freeze({
    "pool_north",
    "pool_east",
    "pool_south",
    "pool_west",
})
-- Every pool silted takes this much out of the Caller directly: breaking
-- its doors is damage, so a player who only ever silts pools still wins.
local SILT_DAMAGE = 45
-- Base seconds between summons, and how much each silted pool buys back.
local BASE_CALL_SECONDS = 8
local CALL_RELIEF_SECONDS = 2.5
-- How much faster it calls per creature already standing: the compounding
-- the fight is actually about.
local CROWD_PRESSURE_SECONDS = 0.9
local MIN_CALL_SECONDS = 3

local DROWNING_HAND = table.freeze({
    attackId = "drowned_caller_hand",
    attackName = "DROWNING HAND",
    damage = 26,
    instruction = "STEP OFF THE WET GROUND",
    radius = 10,
    shape = "circle",
    windup = 1.45,
})

local UNDERTOW = table.freeze({
    attackId = "drowned_caller_undertow",
    attackName = "UNDERTOW",
    damage = 30,
    instruction = "GET CLEAR OF THE PULL",
    length = 28,
    shape = "lane",
    width = 9,
    windup = 1.6,
})

DrownedCallerEncounter.Id = "elite_drowned_caller"
DrownedCallerEncounter.MaxHealth = MAX_HEALTH
DrownedCallerEncounter.PoolIds = POOL_IDS
DrownedCallerEncounter.SiltDamage = SILT_DAMAGE
DrownedCallerEncounter.Reward = table.freeze({
    amount = 3,
    materialId = "material_witchlight_pollen",
})
DrownedCallerEncounter.Tuning = table.freeze({
    baseCallSeconds = BASE_CALL_SECONDS,
    callReliefSeconds = CALL_RELIEF_SECONDS,
    crowdPressureSeconds = CROWD_PRESSURE_SECONDS,
    exposedAttackCooldownSeconds = 3.2,
    minCallSeconds = MIN_CALL_SECONDS,
    strikeDamage = 34,
})

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.participants = table.clone(state.participants)
    nextState.pools = table.clone(state.pools)
    return nextState
end

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "participant user ID is invalid")
    return tostring(userId)
end

local function isPool(poolId: any): boolean
    for _, id in POOL_IDS do
        if id == poolId then
            return true
        end
    end
    return false
end

local function poolsSilted(state: State): number
    local count = 0
    for _, id in POOL_IDS do
        if state.pools[id] then
            count += 1
        end
    end
    return count
end

function DrownedCallerEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Drowned Caller run ID is required")
    assert(manifestHash ~= "", "Drowned Caller manifest hash is required")
    return {
        health = MAX_HEALTH,
        manifestHash = manifestHash,
        participants = {},
        pools = {},
        revision = 0,
        runId = runId,
        status = if enabled then "dormant" else "disabled",
        summoned = 0,
    }
end

function DrownedCallerEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "calling"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function DrownedCallerEncounter.join(state: State, userId: number): State
    if state.status ~= "calling" and state.status ~= "exposed" then
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

--[[
    Silt one reflected pool. Pools stay silted, each break wounds the
    Caller directly, and the last one leaves it standing in the open with
    nothing left to reach through.
]]
function DrownedCallerEncounter.siltPool(state: State, userId: number, poolId: any): (State, any)
    if state.status ~= "calling" and state.status ~= "exposed" then
        return state, { accepted = false, reason = state.status }
    end
    if not isPool(poolId) then
        return state, { accepted = false, reason = "unknown_pool" }
    end
    if state.pools[poolId] then
        return state, { accepted = false, reason = "already_silted" }
    end
    local nextState = cloneState(state)
    nextState.pools[poolId] = true
    nextState.participants[participantKey(userId)] = true
    nextState.health = math.max(0, state.health - SILT_DAMAGE)
    local silted = poolsSilted(nextState)
    local lastDoor = silted >= #POOL_IDS
    if nextState.health <= 0 then
        nextState.status = "complete"
    elseif lastDoor then
        nextState.status = "exposed"
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            completed = nextState.status == "complete",
            damage = state.health - nextState.health,
            exposed = nextState.status == "exposed",
            health = nextState.health,
            reason = if nextState.status == "complete"
                then "completed"
                elseif lastDoor then "last_door_closed"
                else "pool_silted",
            remaining = #POOL_IDS - silted,
            silted = silted,
        }
end

-- One summon. The service calls this when the cadence says so; the count
-- is what makes the next one come sooner.
function DrownedCallerEncounter.summon(state: State): (State, any)
    if state.status ~= "calling" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.summoned += 1
    nextState.revision += 1
    return nextState, { accepted = true, reason = "summoned", summoned = nextState.summoned }
end

-- One creature answered for. Relieves the pressure its presence added.
function DrownedCallerEncounter.summonDefeated(state: State): State
    if state.summoned <= 0 then
        return state
    end
    local nextState = cloneState(state)
    nextState.summoned -= 1
    nextState.revision += 1
    return nextState
end

--[[
    The arithmetic the fight is about: leaving the pools and leaving the
    summoned standing both make the next call sooner, and silting buys it
    back. Floored so it can never reach zero and lock a player out.
]]
function DrownedCallerEncounter.callCooldown(state: State): number
    local seconds = BASE_CALL_SECONDS
        + poolsSilted(state) * CALL_RELIEF_SECONDS
        - state.summoned * CROWD_PRESSURE_SECONDS
    return math.max(MIN_CALL_SECONDS, seconds)
end

function DrownedCallerEncounter.strike(state: State, userId: number, amount: number): (State, any)
    assert(amount > 0 and amount <= 100, "Drowned Caller strike amount is invalid")
    if state.status ~= "exposed" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState.health = math.max(0, state.health - amount)
    if nextState.health <= 0 then
        nextState.status = "complete"
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            completed = nextState.status == "complete",
            damage = state.health - nextState.health,
            health = nextState.health,
            reason = if nextState.status == "complete" then "completed" else "damaged",
        }
end

function DrownedCallerEncounter.attack(attackIndex: number, siltedCount: number): any
    if siltedCount >= 2 and attackIndex % 2 == 0 then
        return UNDERTOW
    end
    return DROWNING_HAND
end

function DrownedCallerEncounter.snapshot(state: State, userId: number): any
    local silted = poolsSilted(state)
    local instruction = if state.status == "calling"
        then string.format("SILT THE REFLECTED POOLS — %d OF %d", silted, #POOL_IDS)
        elseif state.status == "exposed" then "NOTHING LEFT TO REACH THROUGH — STRIKE IT"
        elseif state.status == "complete" then "THE CALLING IS ENDED"
        elseif state.status == "disabled" then "ELITE TEMPORARILY DORMANT"
        else "ENTER THE BELL MARSH"
    return {
        active = state.status == "calling" or state.status == "exposed",
        callCooldown = DrownedCallerEncounter.callCooldown(state),
        complete = state.status == "complete",
        displayName = "DROWNED CALLER",
        enabled = state.status ~= "disabled",
        exposed = state.status == "exposed",
        health = state.health,
        instruction = instruction,
        maxHealth = MAX_HEALTH,
        phase = math.min(3, math.floor(silted / 2) + 1),
        poolsSilted = silted,
        poolTotal = #POOL_IDS,
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        status = state.status,
        summoned = state.summoned,
    }
end

function DrownedCallerEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        DrownedCallerEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(DrownedCallerEncounter)
