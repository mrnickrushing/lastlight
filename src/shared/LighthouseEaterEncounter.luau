--!strict

--[[
    The Lighthouse Eater -- Tempest Reach's first elite.

    It eats beams. Every lamp on this coast that still worked went out the
    week it arrived, and it hides in the storm wall where nothing can see
    it and it does not need to see. The catalog calls this "extinguishes
    beams and hides in the storm wall", and both halves are the fight:
    while the coast is dark it cannot be found, and the only way to find
    it is to give it something to come for.

    So the fight is lighting things it wants to eat. Four beacons stand
    around the point; lighting one draws the Eater out of the wall and
    holds it in the open for as long as the beam lasts, and it puts that
    beacon out on its way back in. Relighting is the whole loop, and the
    beacons run down whether or not anyone is watching, so a party that
    stops to fight in the dark loses the light it already paid for.

    Where the Iron Widow's windows are bought by cutting something
    permanent, these are rented. Same contract as every elite here:
    profession-independent, solo-passable, one reward per participant per
    run through a deterministic transaction id, disable-able, and every
    mutation server-called.
]]

local Strings = require("./Strings")

local LighthouseEaterEncounter = {}

export type Status = "disabled" | "dormant" | "hidden" | "drawn" | "complete"

export type State = {
    beacons: { [string]: number },
    health: number,
    manifestHash: string,
    participants: { [string]: boolean },
    revision: number,
    runId: string,
    status: Status,
}

local MAX_HEALTH = 320
local BEACON_IDS = table.freeze({
    "beacon_point",
    "beacon_jetty",
    "beacon_shoal",
    "beacon_wall",
})
-- How long a lit beacon burns, and so how long the Eater stays out.
local BEACON_SECONDS = 11

local BEAM_SNUFF = table.freeze({
    attackId = "lighthouse_eater_snuff",
    attackName = Strings.get("encounter.snuffed_beam"),
    damage = 24,
    instruction = Strings.get("encounter.get_out_of_the_dark_it"),
    radius = 12,
    shape = "circle",
    windup = 1.4,
})

local STORM_LUNGE = table.freeze({
    attackId = "lighthouse_eater_lunge",
    attackName = Strings.get("encounter.lunge_from_the_wall"),
    damage = 30,
    instruction = Strings.get("encounter.clear_the_line_to_the_storm"),
    length = 30,
    shape = "lane",
    width = 8,
    windup = 1.15,
})

LighthouseEaterEncounter.Id = "elite_lighthouse_eater"
LighthouseEaterEncounter.MaxHealth = MAX_HEALTH
LighthouseEaterEncounter.BeaconIds = BEACON_IDS
LighthouseEaterEncounter.BeaconSeconds = BEACON_SECONDS
LighthouseEaterEncounter.Reward = table.freeze({
    amount = 3,
    materialId = "material_storm_glass",
})
LighthouseEaterEncounter.Tuning = table.freeze({
    attackCooldownSeconds = 3.2,
    drawnAttackCooldownSeconds = 4,
    hiddenAttackCooldownSeconds = 2.6,
    strikeDamage = 34,
})

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.beacons = table.clone(state.beacons)
    nextState.participants = table.clone(state.participants)
    return nextState
end

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "participant user ID is invalid")
    return tostring(userId)
end

local function isBeacon(beaconId: any): boolean
    for _, id in BEACON_IDS do
        if id == beaconId then
            return true
        end
    end
    return false
end

function LighthouseEaterEncounter.litCount(state: State, now: number): number
    local lit = 0
    for _, id in BEACON_IDS do
        if (state.beacons[id] or 0) > now then
            lit += 1
        end
    end
    return lit
end

function LighthouseEaterEncounter.create(
    runId: string,
    manifestHash: string,
    enabled: boolean
): State
    assert(runId ~= "", "Lighthouse Eater run ID is required")
    assert(manifestHash ~= "", "Lighthouse Eater manifest hash is required")
    return {
        beacons = {},
        health = MAX_HEALTH,
        manifestHash = manifestHash,
        participants = {},
        revision = 0,
        runId = runId,
        status = if enabled then "dormant" else "disabled",
    }
end

function LighthouseEaterEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "hidden"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function LighthouseEaterEncounter.join(state: State, userId: number): State
    if state.status ~= "hidden" and state.status ~= "drawn" then
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
    Light a beacon. It burns for a fixed span and draws the Eater into the
    open for exactly that long; lighting a second while the first burns
    extends nothing, because the Eater is already out -- what it buys is
    the next window starting later, which is the difference between a
    party that spends its light well and one that spends it all at once.
]]
function LighthouseEaterEncounter.lightBeacon(
    state: State,
    userId: number,
    beaconId: any,
    now: number
): (State, any)
    if state.status ~= "hidden" and state.status ~= "drawn" then
        return state, { accepted = false, reason = state.status }
    end
    if not isBeacon(beaconId) then
        return state, { accepted = false, reason = "unknown_beacon" }
    end
    if (state.beacons[beaconId] or 0) > now then
        return state, { accepted = false, reason = "already_lit" }
    end
    local nextState = cloneState(state)
    nextState.beacons[beaconId] = now + BEACON_SECONDS
    nextState.participants[participantKey(userId)] = true
    nextState.status = "drawn"
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            burnsUntil = nextState.beacons[beaconId],
            lit = LighthouseEaterEncounter.litCount(nextState, now),
            reason = "beacon_lit",
        }
end

-- Beacons burn down on their own; when the last one gutters the Eater is
-- back in the wall and cannot be struck.
function LighthouseEaterEncounter.expire(state: State, now: number): State
    if state.status ~= "drawn" then
        return state
    end
    if LighthouseEaterEncounter.litCount(state, now) > 0 then
        return state
    end
    local nextState = cloneState(state)
    nextState.status = "hidden"
    nextState.revision += 1
    return nextState
end

function LighthouseEaterEncounter.strike(
    state: State,
    userId: number,
    amount: number,
    now: number
): (State, any)
    assert(amount > 0 and amount <= 100, "Lighthouse Eater strike amount is invalid")
    if state.status ~= "drawn" or LighthouseEaterEncounter.litCount(state, now) <= 0 then
        return state, { accepted = false, reason = "hidden" }
    end
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState.health = math.max(0, state.health - amount)
    if nextState.health <= 0 then
        nextState.status = "complete"
        nextState.beacons = {}
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

function LighthouseEaterEncounter.attack(attackIndex: number, litCount: number): any
    -- In the dark it lunges from the wall; in the light it snuffs what it
    -- can reach, which is the only time a party can see it coming.
    if litCount > 0 and attackIndex % 2 == 0 then
        return BEAM_SNUFF
    end
    return STORM_LUNGE
end

function LighthouseEaterEncounter.snapshot(state: State, userId: number, now: number): any
    local lit = LighthouseEaterEncounter.litCount(state, now)
    local instruction = if state.status == "hidden"
        then Strings.get("encounter.it_is_in_the_storm_wall")
        elseif state.status == "drawn" then Strings.get("encounter.it_is_in_the_open_strike")
        elseif state.status == "complete" then Strings.get(
            "encounter.the_coast_keeps_its_light"
        )
        elseif state.status == "disabled" then Strings.get(
            "encounter.elite_temporarily_dormant"
        )
        else Strings.get("encounter.enter_the_point")
    return {
        active = state.status == "hidden" or state.status == "drawn",
        beaconTotal = #BEACON_IDS,
        beaconsLit = lit,
        complete = state.status == "complete",
        displayName = Strings.get("encounter.lighthouse_eater"),
        drawn = state.status == "drawn",
        enabled = state.status ~= "disabled",
        health = state.health,
        instruction = instruction,
        maxHealth = MAX_HEALTH,
        phase = math.min(3, math.floor((MAX_HEALTH - state.health) / (MAX_HEALTH / 3)) + 1),
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        status = state.status,
    }
end

function LighthouseEaterEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        LighthouseEaterEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(LighthouseEaterEncounter)
