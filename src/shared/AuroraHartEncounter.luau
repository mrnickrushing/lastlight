--!strict

--[[
    The Aurora Hart -- Frostmere Vale's second elite.

    Its antlers carry light, and light in this valley is warmth. What the
    Hart does with it is the whole fight: it splits. Every few beats it
    takes an ember from the hottest hearth in the clearing and sets it
    down in a cold one, until four hearths are burning weakly and nothing
    in the clearing is warm enough to matter.

    So the party's verb is the opposite of its verb. Carrying an ember
    from one hearth to another puts warmth back together, and a hearth
    that is genuinely banked -- not merely lit -- is the only place a
    strike on the Hart lands for its full weight. The Abbey Silence is a
    fight about opening a window in time; this is a fight about refusing
    to let a resource be divided, which is the argument the whole region
    is making.

    A solo player can win it: the Hart splits on a clock rather than per
    player, and one runner can outpace it. A party wins it faster and
    with fewer cold minutes, which is the correct shape for a co-op game
    that must not require co-op.
]]

local AuroraHartEncounter = {}

export type Status = "disabled" | "dormant" | "split" | "banked" | "complete"

export type State = {
    health: number,
    hearths: { [string]: number },
    manifestHash: string,
    participants: { [string]: boolean },
    revision: number,
    runId: string,
    splits: number,
    status: Status,
}

local MAX_HEALTH = 360
local HEARTH_IDS = table.freeze({
    "hearth_north",
    "hearth_east",
    "hearth_south",
    "hearth_west",
})
-- What counts as banked: enough embers in one place to be worth standing in.
local BANKED_LEVEL = 3
local STARTING_LEVEL = 3
-- What a blow is worth with the clearing's warmth scattered.
local SPLIT_FRACTION = 0.4

local LIGHT_ANTLER = table.freeze({
    attackId = "aurora_hart_antler",
    attackName = "LIGHT ANTLER",
    damage = 24,
    instruction = "THE ANTLERS ARE WHERE THE HEAT WENT",
    length = 26,
    shape = "lane",
    width = 8,
    windup = 1.4,
})

local COLD_BOUND = table.freeze({
    attackId = "aurora_hart_bound",
    attackName = "COLD BOUND",
    damage = 20,
    instruction = "IT LANDS WHERE THE FIRE IS NOT",
    radius = 12,
    shape = "circle",
    windup = 1.15,
})

AuroraHartEncounter.Id = "elite_aurora_hart"
AuroraHartEncounter.MaxHealth = MAX_HEALTH
AuroraHartEncounter.HearthIds = HEARTH_IDS
AuroraHartEncounter.BankedLevel = BANKED_LEVEL
AuroraHartEncounter.SplitFraction = SPLIT_FRACTION
AuroraHartEncounter.Reward = table.freeze({
    amount = 3,
    materialId = "material_ember_moss",
})
AuroraHartEncounter.Tuning = table.freeze({
    attackCooldownSeconds = 3.2,
    splitIntervalSeconds = 7,
    strikeDamage = 34,
})

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.hearths = table.clone(state.hearths)
    nextState.participants = table.clone(state.participants)
    return nextState
end

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "participant user ID is invalid")
    return tostring(userId)
end

local function isHearth(hearthId: any): boolean
    for _, id in HEARTH_IDS do
        if id == hearthId then
            return true
        end
    end
    return false
end

function AuroraHartEncounter.bankedHearth(state: State): string?
    for _, id in HEARTH_IDS do
        if (state.hearths[id] or 0) >= BANKED_LEVEL then
            return id
        end
    end
    return nil
end

function AuroraHartEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Aurora Hart run ID is required")
    assert(manifestHash ~= "", "Aurora Hart manifest hash is required")
    local hearths: { [string]: number } = {}
    for index, id in HEARTH_IDS do
        hearths[id] = if index == 1 then STARTING_LEVEL else 0
    end
    return {
        health = MAX_HEALTH,
        hearths = hearths,
        manifestHash = manifestHash,
        participants = {},
        revision = 0,
        runId = runId,
        splits = 0,
        status = if enabled then "dormant" else "disabled",
    }
end

local function restatus(state: State): State
    state.status = if AuroraHartEncounter.bankedHearth(state) ~= nil then "banked" else "split"
    return state
end

function AuroraHartEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return restatus(nextState), { accepted = true, activated = true, reason = "activated" }
end

function AuroraHartEncounter.join(state: State, userId: number): State
    if state.status ~= "split" and state.status ~= "banked" then
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
    The Hart's own verb, on the service's clock rather than on a player's
    input: take one ember off the hottest hearth and set it in the
    coldest. It never destroys warmth, which is what makes the fight
    winnable -- everything it takes is still somewhere in the clearing.
]]
function AuroraHartEncounter.split(state: State): State
    if state.status ~= "split" and state.status ~= "banked" then
        return state
    end
    local hottest, coldest = HEARTH_IDS[1], HEARTH_IDS[1]
    for _, id in HEARTH_IDS do
        local level = state.hearths[id] or 0
        if level > (state.hearths[hottest] or 0) then
            hottest = id
        end
        if level < (state.hearths[coldest] or 0) then
            coldest = id
        end
    end
    if hottest == coldest or (state.hearths[hottest] or 0) <= 0 then
        return state
    end
    local nextState = cloneState(state)
    nextState.hearths[hottest] = (nextState.hearths[hottest] or 0) - 1
    nextState.hearths[coldest] = (nextState.hearths[coldest] or 0) + 1
    nextState.splits += 1
    nextState.revision += 1
    return restatus(nextState)
end

function AuroraHartEncounter.carryEmber(
    state: State,
    userId: number,
    fromHearthId: any,
    toHearthId: any
): (State, any)
    if state.status ~= "split" and state.status ~= "banked" then
        return state, { accepted = false, reason = state.status }
    end
    if not isHearth(fromHearthId) or not isHearth(toHearthId) then
        return state, { accepted = false, reason = "unknown_hearth" }
    end
    if fromHearthId == toHearthId then
        return state, { accepted = false, reason = "same_hearth" }
    end
    if (state.hearths[fromHearthId] or 0) <= 0 then
        return state, { accepted = false, reason = "hearth_cold" }
    end
    local nextState = cloneState(state)
    nextState.hearths[fromHearthId] -= 1
    nextState.hearths[toHearthId] = (nextState.hearths[toHearthId] or 0) + 1
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    restatus(nextState)
    return nextState,
        {
            accepted = true,
            banked = nextState.status == "banked",
            level = nextState.hearths[toHearthId],
            reason = if nextState.status == "banked" then "hearth_banked" else "ember_carried",
        }
end

function AuroraHartEncounter.strike(state: State, userId: number, amount: number): (State, any)
    assert(amount > 0 and amount <= 100, "Aurora Hart strike amount is invalid")
    if state.status ~= "split" and state.status ~= "banked" then
        return state, { accepted = false, reason = state.status }
    end
    local banked = AuroraHartEncounter.bankedHearth(state) ~= nil
    local applied = if banked then amount else math.max(1, math.floor(amount * SPLIT_FRACTION))
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState.health = math.max(0, state.health - applied)
    if nextState.health <= 0 then
        nextState.status = "complete"
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            banked = banked,
            completed = nextState.status == "complete",
            damage = applied,
            health = nextState.health,
            reason = if nextState.status == "complete"
                then "completed"
                elseif banked then "damaged"
                else "scattered",
        }
end

function AuroraHartEncounter.attack(attackIndex: number, banked: boolean): any
    -- Banked, it goes for the fire in a line; scattered, it bounds
    -- through the cold ground it just made.
    if banked and attackIndex % 2 == 1 then
        return LIGHT_ANTLER
    end
    return COLD_BOUND
end

function AuroraHartEncounter.snapshot(state: State, userId: number): any
    local banked = AuroraHartEncounter.bankedHearth(state)
    local hottest = 0
    for _, id in HEARTH_IDS do
        hottest = math.max(hottest, state.hearths[id] or 0)
    end
    local instruction = if state.status == "split"
        then string.format(
            "CARRY THE EMBERS TOGETHER — %d OF %d IN ONE HEARTH",
            hottest,
            BANKED_LEVEL
        )
        elseif state.status == "banked" then "THE HEARTH IS BANKED — STRIKE FROM THE WARMTH"
        elseif state.status == "complete" then "THE HART IS DOWN · THE CLEARING KEEPS ITS FIRE"
        elseif state.status == "disabled" then "ELITE TEMPORARILY DORMANT"
        else "ENTER THE CLEARING"
    return {
        active = state.status == "split" or state.status == "banked",
        bankedHearth = banked,
        bankedLevel = BANKED_LEVEL,
        complete = state.status == "complete",
        displayName = "AURORA HART",
        enabled = state.status ~= "disabled",
        health = state.health,
        hottestLevel = hottest,
        instruction = instruction,
        maxHealth = MAX_HEALTH,
        phase = math.min(3, math.floor((MAX_HEALTH - state.health) / (MAX_HEALTH / 3)) + 1),
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        splits = state.splits,
        status = state.status,
    }
end

function AuroraHartEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        AuroraHartEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(AuroraHartEncounter)
