--!strict

--[[
    The Tidebound Titan -- chapter IV's boss, standing in the channel
    where the harbour used to be.

    Three phases, and the content catalog's non-profession solution read
    literally: climb wrecks, ground lightning, lower tide.

    - **Climb.** It is too big to reach from the water. Wrecks around the
      channel can be climbed to fighting height, and each phase asks for
      more of them because the Titan pulls the ones you used back under.
    - **Ground.** At height, the storm is the danger rather than the
      Titan: its charge has to be earthed through rods before it lands,
      which is the same lesson the Storm Ray teaches small.
    - **Lower.** Grounded, the tide gates can be worked, and a lowered
      tide is the only thing that brings the Titan's own weight against
      it. That is when it can be struck.

    The chapter's decision sits in the third verb. The gates can be
    lowered gently, over a long turn that leaves the harbour's channel
    intact, or slammed, which drops the tide at once and takes the
    channel's mouth with it. A town that wants its harbour back later
    cares which; a party in trouble tonight may not.
]]

local TideboundTitanEncounter = {}

export type Status =
    "disabled"
    | "locked"
    | "dormant"
    | "unreachable"
    | "grounding"
    | "exposed"
    | "complete"

export type State = {
    climbed: { [string]: boolean },
    grounded: { [string]: boolean },
    health: number,
    manifestHash: string,
    outcome: string?,
    participants: { [string]: boolean },
    phase: number,
    revision: number,
    runId: string,
    status: Status,
    slammedGates: number,
}

local MAX_HEALTH = 540
local PHASE_THRESHOLDS = table.freeze({ 360, 180, 0 })
local CLIMBS_REQUIRED = table.freeze({ 2, 3, 4 })
local WRECK_IDS = table.freeze({
    "wreck_collier",
    "wreck_packet",
    "wreck_trawler",
    "wreck_cutter",
})
local ROD_IDS = table.freeze({
    "rod_seaward",
    "rod_landward",
})
local GATE_IDS = table.freeze({
    gate_north = true,
    gate_south = true,
})

local TIDE_SURGE = table.freeze({
    attackId = "tidebound_titan_surge",
    attackName = "TIDE SURGE",
    damage = 28,
    instruction = "GET ABOVE THE SURGE LINE",
    length = 36,
    shape = "lane",
    width = 12,
    windup = 1.5,
})

local STORM_CROWN = table.freeze({
    attackId = "tidebound_titan_crown",
    attackName = "STORM CROWN",
    damage = 32,
    instruction = "GROUND IT — DO NOT STAND HIGHEST",
    radius = 15,
    shape = "circle",
    windup = 1.7,
})

local HARBOUR_BREAK = table.freeze({
    attackId = "tidebound_titan_break",
    attackName = "HARBOUR BREAK",
    damage = 34,
    instruction = "OFF THE STONE — IT IS TAKING THE WALL",
    radius = 17,
    shape = "circle",
    windup = 1.9,
})

TideboundTitanEncounter.Id = "boss_tidebound_titan"
TideboundTitanEncounter.MaxHealth = MAX_HEALTH
TideboundTitanEncounter.WreckIds = WRECK_IDS
TideboundTitanEncounter.RodIds = ROD_IDS
TideboundTitanEncounter.GateIds = GATE_IDS
TideboundTitanEncounter.Reward = table.freeze({
    amount = 5,
    materialId = "material_ships_iron",
})
TideboundTitanEncounter.Tuning = table.freeze({
    attackCooldownSeconds = 3.6,
    exposedAttackCooldownSeconds = 3,
    groundingAttackCooldownSeconds = 4.4,
    markedStrikeDamage = 48,
    strikeDamage = 42,
    unreachableAttackCooldownSeconds = 4.8,
})

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "boss participant user ID is invalid")
    return tostring(userId)
end

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.climbed = table.clone(state.climbed)
    nextState.grounded = table.clone(state.grounded)
    nextState.participants = table.clone(state.participants)
    return nextState
end

local function countKeys(values: { [string]: boolean }): number
    local count = 0
    for _, value in values do
        if value then
            count += 1
        end
    end
    return count
end

local function isActive(status: Status): boolean
    return status == "unreachable" or status == "grounding" or status == "exposed"
end

local function climbsRequired(phase: number): number
    return CLIMBS_REQUIRED[phase] or CLIMBS_REQUIRED[#CLIMBS_REQUIRED]
end

function TideboundTitanEncounter.create(
    runId: string,
    manifestHash: string,
    enabled: boolean
): State
    assert(runId ~= "", "Tidebound Titan run ID is required")
    assert(manifestHash ~= "", "Tidebound Titan manifest hash is required")
    return {
        climbed = {},
        grounded = {},
        health = MAX_HEALTH,
        manifestHash = manifestHash,
        outcome = nil,
        participants = {},
        phase = 1,
        revision = 0,
        runId = runId,
        slammedGates = 0,
        status = if enabled then "locked" else "disabled",
    }
end

function TideboundTitanEncounter.unlock(state: State): (State, any)
    if state.status ~= "locked" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "dormant"
    nextState.revision += 1
    return nextState, { accepted = true, reason = "unlocked" }
end

function TideboundTitanEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "unreachable"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function TideboundTitanEncounter.join(state: State, userId: number): State
    if not isActive(state.status) then
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

function TideboundTitanEncounter.climbWreck(
    state: State,
    userId: number,
    wreckId: any
): (State, any)
    if state.status ~= "unreachable" then
        return state, { accepted = false, reason = state.status }
    end
    local valid = false
    for _, id in WRECK_IDS do
        if id == wreckId then
            valid = true
            break
        end
    end
    if not valid then
        return state, { accepted = false, reason = "unknown_wreck" }
    end
    if state.climbed[wreckId] then
        return state, { accepted = false, reason = "already_climbed" }
    end
    local nextState = cloneState(state)
    nextState.climbed[wreckId] = true
    nextState.participants[participantKey(userId)] = true
    local climbed = countKeys(nextState.climbed)
    local required = climbsRequired(state.phase)
    local atHeight = climbed >= required
    if atHeight then
        nextState.status = "grounding"
        nextState.grounded = {}
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            atHeight = atHeight,
            climbed = climbed,
            reason = if atHeight then "at_height" else "wreck_climbed",
            remaining = math.max(0, required - climbed),
        }
end

function TideboundTitanEncounter.groundRod(state: State, userId: number, rodId: any): (State, any)
    if state.status ~= "grounding" then
        return state, { accepted = false, reason = state.status }
    end
    local valid = false
    for _, id in ROD_IDS do
        if id == rodId then
            valid = true
            break
        end
    end
    if not valid then
        return state, { accepted = false, reason = "unknown_rod" }
    end
    if state.grounded[rodId] then
        return state, { accepted = false, reason = "already_grounded" }
    end
    local nextState = cloneState(state)
    nextState.grounded[rodId] = true
    nextState.participants[participantKey(userId)] = true
    local earthed = countKeys(nextState.grounded) >= #ROD_IDS
    if earthed then
        nextState.status = "exposed"
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            earthed = earthed,
            reason = if earthed then "storm_earthed" else "rod_set",
        }
end

--[[
    Work the tide gates. Gently is the long turn that leaves the channel
    whole; slamming drops the tide at once and takes the channel's mouth
    with it. Either lowers the tide -- the difference is what the town
    finds in the morning, and the chapter remembers which was chosen.
]]
function TideboundTitanEncounter.lowerTide(
    state: State,
    userId: number,
    gateId: any,
    slam: boolean
): (State, any)
    if state.status ~= "exposed" then
        return state, { accepted = false, reason = state.status }
    end
    if type(gateId) ~= "string" or GATE_IDS[gateId] ~= true then
        return state, { accepted = false, reason = "unknown_gate" }
    end
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    if slam then
        nextState.slammedGates += 1
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            reason = if slam then "gate_slammed" else "gate_eased",
            slammed = slam,
        }
end

function TideboundTitanEncounter.strike(state: State, userId: number, amount: number): (State, any)
    assert(amount > 0 and amount <= 100, "Tidebound Titan strike amount is invalid")
    if state.status ~= "exposed" then
        return state, { accepted = false, reason = state.status }
    end

    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    local threshold = PHASE_THRESHOLDS[state.phase]
    nextState.health = math.max(threshold, state.health - amount)
    local phaseFinished = nextState.health <= threshold
    if phaseFinished then
        if state.phase >= #PHASE_THRESHOLDS then
            nextState.health = 0
            nextState.status = "complete"
            --[[
                What the harbour is afterwards, counted across the whole
                fight rather than one phase of it. Three phases offer two
                gates each, so six slams is a party that chose speed every
                time it was asked; none is a party that never did. The
                first draft called two "broken", which made a single
                hurried phase indistinguishable from a policy -- a spec
                walking one slammed phase and two eased ones caught it.
            ]]
            local slams = nextState.slammedGates
            nextState.outcome = if slams == 0
                then "navigable"
                elseif slams >= 4 then "broken"
                else "scoured"
        else
            nextState.phase += 1
            nextState.climbed = {}
            nextState.grounded = {}
            nextState.status = "unreachable"
        end
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            completed = nextState.status == "complete",
            damage = state.health - nextState.health,
            health = nextState.health,
            outcome = nextState.outcome,
            phase = nextState.phase,
            phaseFinished = phaseFinished,
            reason = if nextState.status == "complete"
                then "completed"
                elseif phaseFinished then "next_phase"
                else "damaged",
        }
end

function TideboundTitanEncounter.attack(attackIndex: number, phase: number, status: Status?): any
    if status == "grounding" then
        return STORM_CROWN
    end
    if phase >= 3 then
        return if attackIndex % 2 == 0 then HARBOUR_BREAK else TIDE_SURGE
    elseif phase == 2 and attackIndex % 2 == 0 then
        return STORM_CROWN
    end
    return TIDE_SURGE
end

function TideboundTitanEncounter.snapshot(state: State, userId: number): any
    local climbed = countKeys(state.climbed)
    local required = climbsRequired(state.phase)
    local instruction = if state.status == "unreachable"
        then string.format("CLIMB THE WRECKS %d/%d", climbed, required)
        elseif state.status == "grounding" then "GROUND THE STORM BEFORE IT LANDS"
        elseif state.status == "exposed" then "LOWER THE TIDE — EASE THE GATES OR SLAM THEM"
        elseif state.status == "complete" then if state.outcome == "navigable"
            then "THE TITAN IS DOWN · THE CHANNEL STILL RUNS"
            elseif state.outcome == "broken" then "THE TITAN IS DOWN · THE HARBOUR MOUTH IS GONE"
            else "THE TITAN IS DOWN · THE CHANNEL IS SCOURED"
        elseif state.status == "dormant" then "ENTER THE CHANNEL"
        elseif state.status == "locked" then "CLEAR THE REACH'S ELITES TO REACH IT"
        elseif state.status == "disabled" then "TIDEBOUND TITAN TEMPORARILY DORMANT"
        else "TIDEBOUND TITAN"
    return {
        active = isActive(state.status),
        choiceAvailable = state.status == "exposed",
        climbsRequired = required,
        complete = state.status == "complete",
        displayName = "TIDEBOUND TITAN",
        enabled = state.status ~= "disabled",
        exposed = state.status == "exposed",
        health = state.health,
        instruction = instruction,
        maxHealth = MAX_HEALTH,
        outcome = state.outcome,
        phase = state.phase,
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        slammedGates = state.slammedGates,
        status = state.status,
        wrecksClimbed = climbed,
    }
end

function TideboundTitanEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        TideboundTitanEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(TideboundTitanEncounter)
