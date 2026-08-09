--!strict

--[[
    The Bellows Maw -- chapter II's boss, at the bottom of the Ironroot
    Delve, where the great pump engine and something older have grown into
    each other.

    Three phases, and the content catalog's own non-profession solution
    read literally: reroute carts, vent pressure, strike core.

    - **Reroute.** The Maw feeds on the ore trains. Each phase opens with
      its feed lines running; throwing a junction switch sends that line
      somewhere else. Enough lines rerouted and the feed starves.
    - **Vent.** Starved, it over-pressurizes. Two vent wheels bleed it off
      -- and this is the chapter's decision: venting into the upper drifts
      is fast and cheap, venting into the flooded stope is slower but the
      Delve keeps its air. The choice is recorded, permanent, and shows in
      the outcome the way the Warden's antlers do.
    - **Strike.** Vented, the core is exposed until the next phase.

    Phase gates ratchet: 2 lines, then 3, then 4, so the fight asks more
    of you each time without asking anything new. Nothing here needs a
    profession, and every step can be walked by one player -- switches and
    wheels stay where they are put.
]]

local Strings = require("./Strings")

local BellowsMawEncounter = {}

export type Status =
    "disabled"
    | "locked"
    | "dormant"
    | "feeding"
    | "pressured"
    | "exposed"
    | "complete"

export type State = {
    health: number,
    manifestHash: string,
    outcome: string?,
    participants: { [string]: boolean },
    phase: number,
    reroutedLines: { [string]: boolean },
    revision: number,
    runId: string,
    status: Status,
    ventedInto: { [string]: boolean },
    vents: { [string]: boolean },
}

local MAX_HEALTH = 460
local PHASE_THRESHOLDS = table.freeze({ 300, 150, 0 })
local LINES_REQUIRED = table.freeze({ 2, 3, 4 })
local LINE_IDS = table.freeze({
    line_head = true,
    line_spur = true,
    line_deep = true,
    line_return = true,
})
local VENT_IDS = table.freeze({
    vent_drift = true,
    vent_stope = true,
})
-- Which vent a crew chooses is the chapter's decision. Drifts are quick
-- and the Delve breathes worse for it; the stope is slow and clean.
local VENT_OUTCOMES = table.freeze({
    vent_drift = "fouled",
    vent_stope = "cleared",
})

local FEED_SURGE = table.freeze({
    attackId = "bellows_maw_feed_surge",
    attackName = Strings.get("encounter.feed_surge"),
    damage = 26,
    instruction = Strings.get("encounter.clear_the_feed_line"),
    length = 34,
    shape = "lane",
    width = 8,
    windup = 1.25,
})

local PRESSURE_BURST = table.freeze({
    attackId = "bellows_maw_pressure_burst",
    attackName = Strings.get("encounter.pressure_burst"),
    damage = 30,
    instruction = Strings.get("encounter.get_behind_cover_it_is_venting"),
    radius = 14,
    shape = "circle",
    windup = 1.6,
})

local CINDER_FALL = table.freeze({
    attackId = "bellows_maw_cinder_fall",
    attackName = Strings.get("encounter.cinder_fall"),
    damage = 22,
    instruction = Strings.get("encounter.leave_the_falling_embers"),
    radius = 10,
    shape = "circle",
    windup = 1.35,
})

BellowsMawEncounter.Id = "boss_bellows_maw"
BellowsMawEncounter.MaxHealth = MAX_HEALTH
BellowsMawEncounter.LineIds = LINE_IDS
BellowsMawEncounter.VentIds = VENT_IDS
BellowsMawEncounter.Reward = table.freeze({
    amount = 5,
    materialId = "material_coalglass",
})
BellowsMawEncounter.Tuning = table.freeze({
    attackCooldownSeconds = 3.4,
    feedingAttackCooldownSeconds = 4.2,
    markedAttackCooldownMultiplier = 1.35,
    markedStrikeDamage = 46,
    pressuredAttackCooldownSeconds = 2.8,
    strikeDamage = 40,
})

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "boss participant user ID is invalid")
    return tostring(userId)
end

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.participants = table.clone(state.participants)
    nextState.reroutedLines = table.clone(state.reroutedLines)
    nextState.ventedInto = table.clone(state.ventedInto)
    nextState.vents = table.clone(state.vents)
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
    return status == "feeding" or status == "pressured" or status == "exposed"
end

local function linesRequired(phase: number): number
    return LINES_REQUIRED[phase] or LINES_REQUIRED[#LINES_REQUIRED]
end

function BellowsMawEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Bellows Maw run ID is required")
    assert(manifestHash ~= "", "Bellows Maw manifest hash is required")
    return {
        health = MAX_HEALTH,
        manifestHash = manifestHash,
        outcome = nil,
        participants = {},
        phase = 1,
        reroutedLines = {},
        revision = 0,
        runId = runId,
        status = if enabled then "locked" else "disabled",
        ventedInto = {},
        vents = {},
    }
end

-- The Maw's chamber opens when the Delve's own elites have been dealt
-- with; until then the fight is not reachable, exactly as the Warden's
-- Seal waits on the Old Growth.
function BellowsMawEncounter.unlock(state: State): (State, any)
    if state.status ~= "locked" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "dormant"
    nextState.revision += 1
    return nextState, { accepted = true, reason = "unlocked" }
end

function BellowsMawEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "feeding"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function BellowsMawEncounter.join(state: State, userId: number): State
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

--[[
    Throw one junction switch. Rerouted lines stay rerouted for the phase,
    and starving the feed moves the Maw into over-pressure.
]]
function BellowsMawEncounter.rerouteLine(state: State, userId: number, lineId: any): (State, any)
    if state.status ~= "feeding" then
        return state, { accepted = false, reason = state.status }
    end
    if type(lineId) ~= "string" or LINE_IDS[lineId] ~= true then
        return state, { accepted = false, reason = "unknown_line" }
    end
    if state.reroutedLines[lineId] then
        return state, { accepted = false, reason = "already_rerouted" }
    end
    local nextState = cloneState(state)
    nextState.reroutedLines[lineId] = true
    nextState.participants[participantKey(userId)] = true
    local rerouted = countKeys(nextState.reroutedLines)
    local required = linesRequired(state.phase)
    local starved = rerouted >= required
    if starved then
        nextState.status = "pressured"
        nextState.vents = {}
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            reason = if starved then "feed_starved" else "line_rerouted",
            remaining = math.max(0, required - rerouted),
            rerouted = rerouted,
            starved = starved,
        }
end

--[[
    Turn a vent wheel. Both wheels bleed the pressure, and which one a
    crew reaches for is remembered: the drifts are quick and the air pays,
    the flooded stope is slow and the Delve keeps its air. A single wheel
    is enough to vent -- the second is a choice, not a chore.
]]
function BellowsMawEncounter.ventPressure(state: State, userId: number, ventId: any): (State, any)
    if state.status ~= "pressured" then
        return state, { accepted = false, reason = state.status }
    end
    if type(ventId) ~= "string" or VENT_IDS[ventId] ~= true then
        return state, { accepted = false, reason = "unknown_vent" }
    end
    if state.vents[ventId] then
        return state, { accepted = false, reason = "already_vented" }
    end
    local nextState = cloneState(state)
    nextState.vents[ventId] = true
    nextState.ventedInto[ventId] = true
    nextState.participants[participantKey(userId)] = true
    nextState.status = "exposed"
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            reason = "pressure_vented",
            vent = ventId,
            ventOutcome = VENT_OUTCOMES[ventId],
        }
end

function BellowsMawEncounter.strike(state: State, userId: number, amount: number): (State, any)
    assert(amount > 0 and amount <= 100, "Bellows Maw strike amount is invalid")
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
                The outcome the Delve remembers: a crew that only ever
                took the quick vent leaves the drifts fouled, one that
                only ever took the stope leaves the air clear, and a crew
                that used both is somewhere in between. The chapter's own
                consequence, decided by play rather than a menu.
            ]]
            local drift = nextState.ventedInto.vent_drift == true
            local stope = nextState.ventedInto.vent_stope == true
            nextState.outcome = if drift and stope
                then "mixed"
                elseif drift then "fouled"
                else "cleared"
        else
            nextState.phase += 1
            nextState.reroutedLines = {}
            nextState.vents = {}
            nextState.status = "feeding"
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

function BellowsMawEncounter.attack(attackIndex: number, phase: number, status: Status?): any
    -- Over-pressure is its own danger: while it is waiting to be vented
    -- the Maw throws bursts regardless of phase.
    if status == "pressured" then
        return PRESSURE_BURST
    end
    if phase >= 3 then
        return if attackIndex % 2 == 0 then CINDER_FALL else FEED_SURGE
    elseif phase == 2 and attackIndex % 2 == 0 then
        return CINDER_FALL
    end
    return FEED_SURGE
end

function BellowsMawEncounter.snapshot(state: State, userId: number): any
    local rerouted = countKeys(state.reroutedLines)
    local required = linesRequired(state.phase)
    local instruction = if state.status == "feeding"
        then string.format(Strings.get("encounter.reroute_the_feed_lines_n_n"), rerouted, required)
        elseif state.status == "pressured" then Strings.get(
            "encounter.vent_the_pressure_drifts_are_quick"
        )
        elseif state.status == "exposed" then Strings.get(
            "encounter.the_core_is_open_strike_it"
        )
        elseif state.status == "complete" then if state.outcome == "cleared"
            then Strings.get("encounter.the_maw_is_still_the_delve")
            elseif state.outcome == "fouled" then Strings.get(
                "encounter.the_maw_is_still_the_drifts"
            )
            else Strings.get("encounter.the_maw_is_still_the_delve_2")
        elseif state.status == "dormant" then Strings.get(
            "encounter.enter_the_bellows_chamber"
        )
        elseif state.status == "locked" then Strings.get(
            "encounter.clear_the_delve_s_elites_to"
        )
        elseif state.status == "disabled" then Strings.get(
            "encounter.bellows_maw_temporarily_dormant"
        )
        else Strings.get("encounter.bellows_maw")
    return {
        active = isActive(state.status),
        choiceAvailable = state.status == "pressured",
        complete = state.status == "complete",
        displayName = Strings.get("encounter.bellows_maw"),
        enabled = state.status ~= "disabled",
        exposed = state.status == "exposed",
        health = state.health,
        instruction = instruction,
        linesRequired = required,
        linesRerouted = rerouted,
        maxHealth = MAX_HEALTH,
        outcome = state.outcome,
        phase = state.phase,
        pressured = state.status == "pressured",
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        status = state.status,
    }
end

function BellowsMawEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        BellowsMawEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(BellowsMawEncounter)
