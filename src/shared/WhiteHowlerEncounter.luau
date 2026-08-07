--!strict

--[[
    The White Howler -- chapter V's boss, and the reason the Vale is
    quiet.

    Three phases, and the catalog's non-profession solution read
    literally: manage noise, share warmth, track aurora.

    - **Noise.** It hunts sound, so the fight opens with the party going
      round the bowl silencing the things that are making it -- a bell
      rope, a kettle line, a wind vane, a kennel gate. Each phase asks
      for one more of them, because between phases it wakes the ones you
      left.
    - **Warmth.** Quiet, it stops hunting and starts waiting, and waiting
      in Frostmere is what kills. Warmth has to be spent to stay in the
      bowl at all, and every share is a decision about where it goes.
    - **Aurora.** Fed and quiet, it breaks and runs, and only the light
      over the ridge shows where. The marks have to be read in order;
      guessing at them loses the trail and the phase starts over.

    The chapter's decision is in the second verb. Warmth can be spent on
    the party's own fire, which is the safe and obvious thing, or carried
    up to the Howler's den, where its pups are. The den costs: a party
    that warms it is colder when the trail opens and has further to read
    before it catches up. What the Vale keeps afterwards depends on how
    often that price was paid -- a valley with a predator still in it, a
    valley with none, or the long middle where the line thins out but
    does not end.
]]

local WhiteHowlerEncounter = {}

export type Status =
    "disabled"
    | "locked"
    | "dormant"
    | "listening"
    | "warming"
    | "tracking"
    | "exposed"
    | "complete"

export type State = {
    denPhases: { boolean },
    followed: { [string]: boolean },
    health: number,
    hushed: { [string]: boolean },
    manifestHash: string,
    outcome: string?,
    participants: { [string]: boolean },
    phase: number,
    revision: number,
    runId: string,
    shared: { [string]: boolean },
    status: Status,
}

local MAX_HEALTH = 560
local PHASE_THRESHOLDS = table.freeze({ 375, 190, 0 })
local NOISE_IDS = table.freeze({
    "noise_bell_rope",
    "noise_kettle_line",
    "noise_wind_vane",
    "noise_kennel_gate",
})
local HUSH_REQUIRED = table.freeze({ 2, 3, 4 })
local WARMTH_IDS = table.freeze({
    "warmth_lantern",
    "warmth_kettle",
    "warmth_coat",
})
local WARMTH_REQUIRED = 2
local TRACK_IDS = table.freeze({
    "track_ridge",
    "track_bowl",
    "track_stair",
    "track_cairn",
})
local TRACKS_REQUIRED = 2

local SNOW_BREATH = table.freeze({
    attackId = "white_howler_breath",
    attackName = "SNOW BREATH",
    damage = 30,
    instruction = "GET BEHIND SOMETHING SOLID",
    length = 34,
    shape = "lane",
    width = 9,
    windup = 1.5,
})

local LISTENING_STILL = table.freeze({
    attackId = "white_howler_listen",
    attackName = "IT IS LISTENING",
    damage = 26,
    instruction = "STOP MOVING",
    radius = 15,
    shape = "circle",
    windup = 1.9,
})

local WHITEOUT = table.freeze({
    attackId = "white_howler_whiteout",
    attackName = "WHITEOUT",
    damage = 34,
    instruction = "FOLLOW THE LIGHT, NOT THE SOUND",
    radius = 19,
    shape = "circle",
    windup = 1.7,
})

WhiteHowlerEncounter.Id = "boss_white_howler"
WhiteHowlerEncounter.MaxHealth = MAX_HEALTH
WhiteHowlerEncounter.NoiseIds = NOISE_IDS
WhiteHowlerEncounter.WarmthIds = WARMTH_IDS
WhiteHowlerEncounter.TrackIds = TRACK_IDS
WhiteHowlerEncounter.WarmthRequired = WARMTH_REQUIRED
WhiteHowlerEncounter.Reward = table.freeze({
    amount = 5,
    materialId = "material_frostmere_wool",
})
WhiteHowlerEncounter.Tuning = table.freeze({
    attackCooldownSeconds = 3.6,
    exposedAttackCooldownSeconds = 4.4,
    strikeDamage = 45,
})

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.denPhases = table.clone(state.denPhases)
    nextState.followed = table.clone(state.followed)
    nextState.hushed = table.clone(state.hushed)
    nextState.participants = table.clone(state.participants)
    nextState.shared = table.clone(state.shared)
    return nextState
end

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "participant user ID is invalid")
    return tostring(userId)
end

local function countTrue(set: { [string]: boolean }): number
    local total = 0
    for _, value in set do
        if value then
            total += 1
        end
    end
    return total
end

local function contains(list: { string }, value: any): boolean
    for _, entry in list do
        if entry == value then
            return true
        end
    end
    return false
end

function WhiteHowlerEncounter.hushRequired(phase: number): number
    return HUSH_REQUIRED[math.clamp(phase, 1, #HUSH_REQUIRED)]
end

--[[
    A phase that warmed the den has one more mark to read before the
    trail is caught. That is the whole price of the decision, and it is
    paid in the phase that made it rather than banked for later.
]]
function WhiteHowlerEncounter.tracksRequired(state: State): number
    local extra = if state.denPhases[state.phase] then 1 else 0
    return math.min(#TRACK_IDS, TRACKS_REQUIRED + extra)
end

function WhiteHowlerEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "White Howler run ID is required")
    assert(manifestHash ~= "", "White Howler manifest hash is required")
    return {
        denPhases = { false, false, false },
        followed = {},
        health = MAX_HEALTH,
        hushed = {},
        manifestHash = manifestHash,
        outcome = nil,
        participants = {},
        phase = 1,
        revision = 0,
        runId = runId,
        shared = {},
        status = if enabled then "locked" else "disabled",
    }
end

function WhiteHowlerEncounter.unlock(state: State): (State, any)
    if state.status ~= "locked" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "dormant"
    nextState.revision += 1
    return nextState, { accepted = true, reason = "unlocked" }
end

function WhiteHowlerEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "listening"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function WhiteHowlerEncounter.join(state: State, userId: number): State
    if state.status == "disabled" or state.status == "locked" or state.status == "complete" then
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

function WhiteHowlerEncounter.hush(state: State, userId: number, noiseId: any): (State, any)
    if state.status ~= "listening" then
        return state, { accepted = false, reason = state.status }
    end
    if not contains(NOISE_IDS, noiseId) then
        return state, { accepted = false, reason = "unknown_noise" }
    end
    if state.hushed[noiseId] then
        return state, { accepted = false, reason = "already_hushed" }
    end
    local nextState = cloneState(state)
    nextState.hushed[noiseId] = true
    nextState.participants[participantKey(userId)] = true
    local required = WhiteHowlerEncounter.hushRequired(state.phase)
    local hushed = countTrue(nextState.hushed)
    if hushed >= required then
        nextState.status = "warming"
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            hushed = hushed,
            reason = if nextState.status == "warming" then "bowl_quiet" else "hushed",
            required = required,
        }
end

function WhiteHowlerEncounter.shareWarmth(
    state: State,
    userId: number,
    warmthId: any,
    toDen: boolean
): (State, any)
    if state.status ~= "warming" then
        return state, { accepted = false, reason = state.status }
    end
    if not contains(WARMTH_IDS, warmthId) then
        return state, { accepted = false, reason = "unknown_warmth" }
    end
    if state.shared[warmthId] then
        return state, { accepted = false, reason = "already_shared" }
    end
    local nextState = cloneState(state)
    nextState.shared[warmthId] = true
    nextState.participants[participantKey(userId)] = true
    if toDen then
        nextState.denPhases[state.phase] = true
    end
    local shared = countTrue(nextState.shared)
    if shared >= WARMTH_REQUIRED then
        nextState.status = "tracking"
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            den = toDen,
            reason = if nextState.status == "tracking" then "warmth_shared" else "warmth_given",
            required = WARMTH_REQUIRED,
            shared = shared,
        }
end

--[[
    The marks have to be read in the order the aurora laid them. A wrong
    one is not a small penalty -- the trail is lost and the phase begins
    again at the noise, because everything the party did to get quiet is
    undone by casting about in the dark.
]]
function WhiteHowlerEncounter.followTrack(state: State, userId: number, trackId: any): (State, any)
    if state.status ~= "tracking" then
        return state, { accepted = false, reason = state.status }
    end
    if not contains(TRACK_IDS, trackId) then
        return state, { accepted = false, reason = "unknown_track" }
    end
    local followed = countTrue(state.followed)
    local expected = TRACK_IDS[followed + 1]
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    if trackId ~= expected then
        nextState.followed = {}
        nextState.hushed = {}
        nextState.shared = {}
        nextState.status = "listening"
        nextState.revision += 1
        return nextState, { accepted = false, lost = true, reason = "trail_lost" }
    end
    nextState.followed[trackId] = true
    local total = followed + 1
    local required = WhiteHowlerEncounter.tracksRequired(nextState)
    if total >= required then
        nextState.status = "exposed"
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            followed = total,
            reason = if nextState.status == "exposed" then "run_down" else "track_read",
            required = required,
        }
end

function WhiteHowlerEncounter.strike(state: State, userId: number, amount: number): (State, any)
    assert(amount > 0 and amount <= 100, "White Howler strike amount is invalid")
    if state.status ~= "exposed" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState.health = math.max(0, state.health - amount)
    local threshold = PHASE_THRESHOLDS[state.phase]
    if nextState.health <= threshold then
        if state.phase >= #PHASE_THRESHOLDS then
            nextState.health = 0
            nextState.status = "complete"
            local dens = 0
            for _, warmed in nextState.denPhases do
                if warmed then
                    dens += 1
                end
            end
            nextState.outcome = if dens >= #PHASE_THRESHOLDS
                then "sheltered"
                elseif dens == 0 then "silenced"
                else "thinned"
        else
            nextState.phase = state.phase + 1
            nextState.status = "listening"
            nextState.followed = {}
            nextState.hushed = {}
            nextState.shared = {}
        end
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            completed = nextState.status == "complete",
            damage = amount,
            health = nextState.health,
            outcome = nextState.outcome,
            phase = nextState.phase,
            reason = if nextState.status == "complete"
                then "completed"
                elseif nextState.phase > state.phase then "phase_cleared"
                else "damaged",
        }
end

function WhiteHowlerEncounter.attack(attackIndex: number, phase: number, status: Status?): any
    if status == "tracking" then
        return WHITEOUT
    end
    if status == "listening" then
        return LISTENING_STILL
    end
    if phase >= 3 and attackIndex % 2 == 0 then
        return WHITEOUT
    end
    return SNOW_BREATH
end

function WhiteHowlerEncounter.snapshot(state: State, userId: number): any
    local instruction = if state.status == "listening"
        then string.format(
            "QUIET THE BOWL — %d OF %d",
            countTrue(state.hushed),
            WhiteHowlerEncounter.hushRequired(state.phase)
        )
        elseif state.status == "warming" then string.format(
            "SHARE WARMTH — %d OF %d GIVEN",
            countTrue(state.shared),
            WARMTH_REQUIRED
        )
        elseif state.status == "tracking" then string.format(
            "READ THE AURORA IN ORDER — %d OF %d",
            countTrue(state.followed),
            WhiteHowlerEncounter.tracksRequired(state)
        )
        elseif state.status == "exposed" then "IT HAS NOWHERE LEFT — STRIKE"
        elseif state.status == "complete" then if state.outcome == "sheltered"
            then "THE HOWLER IS DOWN · ITS DEN STILL BURNS"
            elseif state.outcome == "silenced" then "THE HOWLER IS DOWN · THE VALE IS SILENT"
            else "THE HOWLER IS DOWN · THE LINE THINS"
        elseif state.status == "locked" then "THE VALE IS NOT OPEN TO YOU YET"
        elseif state.status == "disabled" then "THE HOWLER DOES NOT ANSWER"
        else "SOMETHING IN THE BOWL IS LISTENING"
    return {
        active = state.status ~= "disabled"
            and state.status ~= "locked"
            and state.status ~= "dormant",
        complete = state.status == "complete",
        denPhases = table.clone(state.denPhases),
        displayName = "WHITE HOWLER",
        enabled = state.status ~= "disabled",
        health = state.health,
        hushRequired = WhiteHowlerEncounter.hushRequired(state.phase),
        hushed = countTrue(state.hushed),
        instruction = instruction,
        maxHealth = MAX_HEALTH,
        outcome = state.outcome,
        phase = state.phase,
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        shared = countTrue(state.shared),
        status = state.status,
        tracksFollowed = countTrue(state.followed),
        tracksRequired = WhiteHowlerEncounter.tracksRequired(state),
        warmthRequired = WARMTH_REQUIRED,
    }
end

function WhiteHowlerEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        WhiteHowlerEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(WhiteHowlerEncounter)
