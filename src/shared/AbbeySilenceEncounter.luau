--!strict

--[[
    The Abbey Silence -- Frostmere Vale's first elite.

    It takes sound. Inside its reach a telegraph makes no noise at all,
    which in a game where half of danger is heard is most of a player's
    warning gone -- and the catalog is careful about the other half:
    "suppresses sound cues, preserves visual cues". The fight is fair
    because everything it does can still be seen. It is hard because
    seeing is now the only way.

    So the verb is restoring sound, and the valley's own bells are how.
    Three of them hang in the cloister; ringing one clears the silence
    around it for a while, and the Silence smothers them again on its own
    schedule. A party that rings all three has a room it can hear in and a
    short time to use it.

    Same contract as every elite: profession-independent, solo-passable,
    one reward per participant per run, disable-able, server-called.
]]

local Strings = require("./Strings")

local AbbeySilenceEncounter = {}

export type Status = "disabled" | "dormant" | "silent" | "ringing" | "complete"

export type State = {
    bells: { [string]: number },
    health: number,
    manifestHash: string,
    participants: { [string]: boolean },
    revision: number,
    runId: string,
    status: Status,
}

local MAX_HEALTH = 330
local BELL_IDS = table.freeze({
    "bell_cloister",
    "bell_refectory",
    "bell_stair",
})
-- How long a rung bell holds sound open around it.
local BELL_SECONDS = 10
-- What a blow is worth while the room is still silent.
local SILENT_FRACTION = 0.35

local SMOTHERED_STEP = table.freeze({
    attackId = "abbey_silence_step",
    attackName = Strings.get("encounter.smothered_step"),
    damage = 22,
    instruction = Strings.get("encounter.watch_the_snow_you_will_not"),
    radius = 11,
    shape = "circle",
    windup = 1.5,
})

local HELD_BREATH = table.freeze({
    attackId = "abbey_silence_breath",
    attackName = Strings.get("encounter.held_breath"),
    damage = 26,
    instruction = Strings.get("encounter.clear_the_aisle"),
    length = 28,
    shape = "lane",
    width = 7,
    windup = 1.3,
})

AbbeySilenceEncounter.Id = "elite_abbey_silence"
AbbeySilenceEncounter.MaxHealth = MAX_HEALTH
AbbeySilenceEncounter.BellIds = BELL_IDS
AbbeySilenceEncounter.BellSeconds = BELL_SECONDS
AbbeySilenceEncounter.SilentFraction = SILENT_FRACTION
AbbeySilenceEncounter.Reward = table.freeze({
    amount = 3,
    materialId = "material_aurora_salt",
})
AbbeySilenceEncounter.Tuning = table.freeze({
    attackCooldownSeconds = 3.4,
    ringingAttackCooldownSeconds = 4.2,
    silentAttackCooldownSeconds = 3,
    strikeDamage = 34,
})

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.bells = table.clone(state.bells)
    nextState.participants = table.clone(state.participants)
    return nextState
end

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "participant user ID is invalid")
    return tostring(userId)
end

function AbbeySilenceEncounter.ringingCount(state: State, now: number): number
    local ringing = 0
    for _, id in BELL_IDS do
        if (state.bells[id] or 0) > now then
            ringing += 1
        end
    end
    return ringing
end

function AbbeySilenceEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Abbey Silence run ID is required")
    assert(manifestHash ~= "", "Abbey Silence manifest hash is required")
    return {
        bells = {},
        health = MAX_HEALTH,
        manifestHash = manifestHash,
        participants = {},
        revision = 0,
        runId = runId,
        status = if enabled then "dormant" else "disabled",
    }
end

function AbbeySilenceEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "silent"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function AbbeySilenceEncounter.join(state: State, userId: number): State
    if state.status ~= "silent" and state.status ~= "ringing" then
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

function AbbeySilenceEncounter.ringBell(
    state: State,
    userId: number,
    bellId: any,
    now: number
): (State, any)
    if state.status ~= "silent" and state.status ~= "ringing" then
        return state, { accepted = false, reason = state.status }
    end
    local valid = false
    for _, id in BELL_IDS do
        if id == bellId then
            valid = true
            break
        end
    end
    if not valid then
        return state, { accepted = false, reason = "unknown_bell" }
    end
    if (state.bells[bellId] or 0) > now then
        return state, { accepted = false, reason = "already_ringing" }
    end
    local nextState = cloneState(state)
    nextState.bells[bellId] = now + BELL_SECONDS
    nextState.participants[participantKey(userId)] = true
    nextState.status = "ringing"
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            reason = "bell_rung",
            ringing = AbbeySilenceEncounter.ringingCount(nextState, now),
            silentUntil = nextState.bells[bellId],
        }
end

function AbbeySilenceEncounter.expire(state: State, now: number): State
    if state.status ~= "ringing" then
        return state
    end
    if AbbeySilenceEncounter.ringingCount(state, now) > 0 then
        return state
    end
    local nextState = cloneState(state)
    nextState.status = "silent"
    nextState.revision += 1
    return nextState
end

--[[
    A blow lands either way; the silence decides how much of it is worth
    anything. This is the Many-Face's guard shape on purpose -- both
    fights are about acting inside a window you opened -- but the window
    here is opened by making noise rather than by reading a tell, and it
    can be widened by ringing more than one bell.
]]
function AbbeySilenceEncounter.strike(
    state: State,
    userId: number,
    amount: number,
    now: number
): (State, any)
    assert(amount > 0 and amount <= 100, "Abbey Silence strike amount is invalid")
    if state.status ~= "silent" and state.status ~= "ringing" then
        return state, { accepted = false, reason = state.status }
    end
    local ringing = AbbeySilenceEncounter.ringingCount(state, now)
    local applied = if ringing > 0
        then math.min(100, amount + (ringing - 1) * 6)
        else math.max(1, math.floor(amount * SILENT_FRACTION))
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState.health = math.max(0, state.health - applied)
    if nextState.health <= 0 then
        nextState.status = "complete"
        nextState.bells = {}
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            completed = nextState.status == "complete",
            damage = applied,
            health = nextState.health,
            heard = ringing > 0,
            reason = if nextState.status == "complete"
                then "completed"
                elseif ringing > 0 then "damaged"
                else "smothered",
        }
end

function AbbeySilenceEncounter.attack(attackIndex: number, ringingCount: number): any
    -- With bells going it commits to a line it cannot take back; in
    -- silence it prefers the step nobody hears.
    if ringingCount > 0 and attackIndex % 2 == 0 then
        return HELD_BREATH
    end
    return SMOTHERED_STEP
end

function AbbeySilenceEncounter.snapshot(state: State, userId: number, now: number): any
    local ringing = AbbeySilenceEncounter.ringingCount(state, now)
    local instruction = if state.status == "silent"
        then string.format(
            Strings.get("encounter.ring_the_cloister_bells_n_of"),
            ringing,
            #BELL_IDS
        )
        elseif state.status == "ringing" then Strings.get(
            "encounter.the_room_has_sound_strike_while"
        )
        elseif state.status == "complete" then Strings.get(
            "encounter.the_abbey_can_be_heard_again"
        )
        elseif state.status == "disabled" then Strings.get(
            "encounter.elite_temporarily_dormant"
        )
        else Strings.get("encounter.enter_the_cloister")
    return {
        active = state.status == "silent" or state.status == "ringing",
        bellTotal = #BELL_IDS,
        bellsRinging = ringing,
        complete = state.status == "complete",
        displayName = Strings.get("encounter.abbey_silence"),
        enabled = state.status ~= "disabled",
        health = state.health,
        heard = ringing > 0,
        instruction = instruction,
        maxHealth = MAX_HEALTH,
        phase = math.min(3, math.floor((MAX_HEALTH - state.health) / (MAX_HEALTH / 3)) + 1),
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        status = state.status,
    }
end

function AbbeySilenceEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        AbbeySilenceEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(AbbeySilenceEncounter)
