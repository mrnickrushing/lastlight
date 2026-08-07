--!strict

--[[
    The Lead Actor -- Cinderfall Crown's first elite.

    The catalog asks for a "readable stage-pattern sequence", and the word
    that matters is readable. This is not a memory test with the answer
    hidden; the Actor announces its line, loudly, in order, and then
    performs it. What it costs a party is attention rather than luck.

    It works the way the region works. The Actor is a cast that got stuck
    mid-performance, so it cannot fight -- it can only act, and it is
    invulnerable while it is acting because the scene is what is holding
    it together. A party answers each beat as it is called, and when the
    line is finished the scene breaks and there is a moment before the
    next one starts. That moment is the entire fight.

    Getting a beat wrong does not reset the phase. It resets the line,
    which the Actor immediately starts again one beat longer, so a party
    that keeps guessing is not punished with damage so much as with a
    scene that never ends -- which is the Crown's actual threat.
]]

local LeadActorEncounter = {}

export type Status = "disabled" | "dormant" | "performing" | "broken" | "complete"

export type State = {
    health: number,
    linesCleared: number,
    manifestHash: string,
    participants: { [string]: boolean },
    position: number,
    revision: number,
    runId: string,
    status: Status,
}

local MAX_HEALTH = 300
local BEAT_IDS = table.freeze({
    "beat_bow",
    "beat_turn",
    "beat_kneel",
    "beat_raise",
})
-- How long a line runs. It grows, so the third scene asks for four beats.
local LINE_LENGTHS = table.freeze({ 2, 3, 4 })

local STANDING_OVATION = table.freeze({
    attackId = "lead_actor_ovation",
    attackName = "STANDING OVATION",
    damage = 24,
    instruction = "THE HOUSE IS APPLAUDING — GET OFF THE FLOOR MARKS",
    radius = 14,
    shape = "circle",
    windup = 1.4,
})

local CURTAIN_CALL = table.freeze({
    attackId = "lead_actor_curtain",
    attackName = "CURTAIN CALL",
    damage = 28,
    instruction = "CLEAR THE STAGE",
    length = 30,
    shape = "lane",
    width = 8,
    windup = 1.25,
})

LeadActorEncounter.Id = "elite_lead_actor"
LeadActorEncounter.MaxHealth = MAX_HEALTH
LeadActorEncounter.BeatIds = BEAT_IDS
LeadActorEncounter.LineLengths = LINE_LENGTHS
LeadActorEncounter.Reward = table.freeze({
    amount = 3,
    materialId = "material_ash_silk",
})
LeadActorEncounter.Tuning = table.freeze({
    attackCooldownSeconds = 3.1,
    brokenSeconds = 6,
    strikeDamage = 32,
})

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.participants = table.clone(state.participants)
    return nextState
end

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "participant user ID is invalid")
    return tostring(userId)
end

--[[
    The line the Actor is performing, derived rather than stored. Two
    reasons: a client cannot be told a secret it is going to be tested on,
    and a line that is a pure function of how many scenes have been
    cleared is a line a spec can walk without reaching inside the fight.
]]
function LeadActorEncounter.lineLength(state: State): number
    return LINE_LENGTHS[math.min(#LINE_LENGTHS, state.linesCleared + 1)]
end

function LeadActorEncounter.beatAt(state: State, position: number): string
    local index = (state.linesCleared * 3 + position) % #BEAT_IDS
    return BEAT_IDS[index + 1]
end

function LeadActorEncounter.expectedBeat(state: State): string
    return LeadActorEncounter.beatAt(state, state.position)
end

function LeadActorEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Lead Actor run ID is required")
    assert(manifestHash ~= "", "Lead Actor manifest hash is required")
    return {
        health = MAX_HEALTH,
        linesCleared = 0,
        manifestHash = manifestHash,
        participants = {},
        position = 0,
        revision = 0,
        runId = runId,
        status = if enabled then "dormant" else "disabled",
    }
end

function LeadActorEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "performing"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function LeadActorEncounter.join(state: State, userId: number): State
    if state.status ~= "performing" and state.status ~= "broken" then
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
    Answer the beat the Actor just called. A wrong answer costs the line
    rather than health -- the scene starts again, one beat longer -- which
    is the difference between a fight that punishes a mistake and one that
    punishes not paying attention.
]]
function LeadActorEncounter.answerBeat(state: State, userId: number, beatId: any): (State, any)
    if state.status ~= "performing" then
        return state, { accepted = false, reason = state.status }
    end
    local valid = false
    for _, id in BEAT_IDS do
        if id == beatId then
            valid = true
            break
        end
    end
    if not valid then
        return state, { accepted = false, reason = "unknown_beat" }
    end
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    if beatId ~= LeadActorEncounter.expectedBeat(state) then
        nextState.position = 0
        nextState.revision += 1
        return nextState, { accepted = false, missed = true, reason = "line_restarted" }
    end
    nextState.position = state.position + 1
    if nextState.position >= LeadActorEncounter.lineLength(state) then
        nextState.status = "broken"
        nextState.position = 0
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            position = nextState.position,
            reason = if nextState.status == "broken" then "scene_broken" else "beat_answered",
            required = LeadActorEncounter.lineLength(state),
        }
end

-- The Actor recovers on its own and starts the next scene, longer.
function LeadActorEncounter.resume(state: State): State
    if state.status ~= "broken" then
        return state
    end
    local nextState = cloneState(state)
    nextState.linesCleared = math.min(#LINE_LENGTHS - 1, state.linesCleared + 1)
    nextState.status = "performing"
    nextState.position = 0
    nextState.revision += 1
    return nextState
end

function LeadActorEncounter.strike(state: State, userId: number, amount: number): (State, any)
    assert(amount > 0 and amount <= 100, "Lead Actor strike amount is invalid")
    if state.status == "performing" then
        return state, { accepted = false, reason = "still_performing" }
    end
    if state.status ~= "broken" then
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
            damage = amount,
            health = nextState.health,
            reason = if nextState.status == "complete" then "completed" else "damaged",
        }
end

function LeadActorEncounter.attack(attackIndex: number, performing: boolean): any
    -- Acting, it plays to the house; broken, it clears the stage of the
    -- people who broke it.
    if performing and attackIndex % 2 == 1 then
        return STANDING_OVATION
    end
    return CURTAIN_CALL
end

function LeadActorEncounter.snapshot(state: State, userId: number): any
    local instruction = if state.status == "performing"
        then string.format(
            "ANSWER THE LINE — %d OF %d",
            state.position,
            LeadActorEncounter.lineLength(state)
        )
        elseif state.status == "broken" then "THE SCENE IS BROKEN — STRIKE NOW"
        elseif state.status == "complete" then "THE ACTOR IS DOWN · THE STAGE IS QUIET"
        elseif state.status == "disabled" then "ELITE TEMPORARILY DORMANT"
        else "TAKE THE STAGE"
    return {
        active = state.status == "performing" or state.status == "broken",
        calledBeat = if state.status == "performing"
            then LeadActorEncounter.expectedBeat(state)
            else nil,
        complete = state.status == "complete",
        displayName = "LEAD ACTOR",
        enabled = state.status ~= "disabled",
        health = state.health,
        instruction = instruction,
        lineLength = LeadActorEncounter.lineLength(state),
        linesCleared = state.linesCleared,
        maxHealth = MAX_HEALTH,
        phase = math.min(3, math.floor((MAX_HEALTH - state.health) / (MAX_HEALTH / 3)) + 1),
        position = state.position,
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        status = state.status,
    }
end

function LeadActorEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        LeadActorEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(LeadActorEncounter)
