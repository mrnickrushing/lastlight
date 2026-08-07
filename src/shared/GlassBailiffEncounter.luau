--!strict

--[[
    The Glass Bailiff -- Cinderfall Crown's second elite.

    "Marks and sentences one structure." It does not fight a party; it
    processes the room. Every so often it marks one of the court's four
    standing structures, and after a while it carries the sentence out and
    the structure is gone. Nothing about that is aimed at anyone. It is
    simply the reason the room a party started in is not the room they
    finish in.

    Which makes the fight a negotiation with the arena rather than with
    the Bailiff. A marked structure can be appealed -- go to it, clear the
    mark, keep the cover -- or it can be let fall, because carrying out a
    sentence is the one thing that occupies the Bailiff completely, and
    that is the only window it ever gives.

    So a party spends its own cover for its openings, and the last window
    is bought with the last wall. The Lead Actor's fight is about
    attention; this one is about what you are willing to lose to get a
    turn.
]]

local GlassBailiffEncounter = {}

export type Status = "disabled" | "dormant" | "sitting" | "sentencing" | "complete"

export type State = {
    health: number,
    manifestHash: string,
    marked: string?,
    participants: { [string]: boolean },
    revision: number,
    runId: string,
    standing: { [string]: boolean },
    status: Status,
}

local MAX_HEALTH = 340
local STRUCTURE_IDS = table.freeze({
    "structure_west_arcade",
    "structure_stand",
    "structure_press",
    "structure_dock",
})
-- What a blow is worth while the Bailiff is still sitting.
local SITTING_FRACTION = 0.3

local SUMMONS = table.freeze({
    attackId = "glass_bailiff_summons",
    attackName = "SUMMONS",
    damage = 22,
    instruction = "GET BEHIND SOMETHING STILL STANDING",
    length = 32,
    shape = "lane",
    width = 7,
    windup = 1.35,
})

local SENTENCE = table.freeze({
    attackId = "glass_bailiff_sentence",
    attackName = "SENTENCE",
    damage = 30,
    instruction = "IT IS NOT LOOKING AT YOU — GO",
    radius = 16,
    shape = "circle",
    windup = 1.9,
})

GlassBailiffEncounter.Id = "elite_glass_bailiff"
GlassBailiffEncounter.MaxHealth = MAX_HEALTH
GlassBailiffEncounter.StructureIds = STRUCTURE_IDS
GlassBailiffEncounter.SittingFraction = SITTING_FRACTION
GlassBailiffEncounter.Reward = table.freeze({
    amount = 3,
    materialId = "material_memory_glass",
})
GlassBailiffEncounter.Tuning = table.freeze({
    attackCooldownSeconds = 3.3,
    markIntervalSeconds = 9,
    sentenceSeconds = 7,
    strikeDamage = 34,
})

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.participants = table.clone(state.participants)
    nextState.standing = table.clone(state.standing)
    return nextState
end

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "participant user ID is invalid")
    return tostring(userId)
end

function GlassBailiffEncounter.standingCount(state: State): number
    local total = 0
    for _, id in STRUCTURE_IDS do
        if state.standing[id] then
            total += 1
        end
    end
    return total
end

function GlassBailiffEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Glass Bailiff run ID is required")
    assert(manifestHash ~= "", "Glass Bailiff manifest hash is required")
    local standing: { [string]: boolean } = {}
    for _, id in STRUCTURE_IDS do
        standing[id] = true
    end
    return {
        health = MAX_HEALTH,
        manifestHash = manifestHash,
        marked = nil,
        participants = {},
        revision = 0,
        runId = runId,
        standing = standing,
        status = if enabled then "dormant" else "disabled",
    }
end

function GlassBailiffEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "sitting"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function GlassBailiffEncounter.join(state: State, userId: number): State
    if state.status ~= "sitting" and state.status ~= "sentencing" then
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
    The Bailiff's own verb, on the service's clock: mark the first
    structure still standing that is not already marked. Deliberately not
    random -- a fight whose only decision is which wall to give up must
    let a party see the order coming.
]]
function GlassBailiffEncounter.mark(state: State): State
    if state.status ~= "sitting" then
        return state
    end
    if state.marked ~= nil then
        return state
    end
    for _, id in STRUCTURE_IDS do
        if state.standing[id] then
            local nextState = cloneState(state)
            nextState.marked = id
            nextState.revision += 1
            return nextState
        end
    end
    return state
end

function GlassBailiffEncounter.appeal(state: State, userId: number, structureId: any): (State, any)
    if state.status ~= "sitting" then
        return state, { accepted = false, reason = state.status }
    end
    if state.marked == nil or state.marked ~= structureId then
        return state, { accepted = false, reason = "not_marked" }
    end
    local nextState = cloneState(state)
    nextState.marked = nil
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            reason = "appeal_upheld",
            standing = GlassBailiffEncounter.standingCount(nextState),
        }
end

--[[
    The sentence lands. The structure is gone for the rest of the fight
    and the Bailiff is occupied carrying it out, which is the window.
    Called by the service when the mark has stood long enough.
]]
function GlassBailiffEncounter.carryOut(state: State): (State, any)
    if state.status ~= "sitting" or state.marked == nil then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.standing[state.marked :: string] = false
    nextState.marked = nil
    nextState.status = "sentencing"
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            reason = "sentence_carried",
            standing = GlassBailiffEncounter.standingCount(nextState),
        }
end

-- It finishes, sits back down, and starts again.
function GlassBailiffEncounter.adjourn(state: State): State
    if state.status ~= "sentencing" then
        return state
    end
    local nextState = cloneState(state)
    nextState.status = "sitting"
    nextState.revision += 1
    return nextState
end

function GlassBailiffEncounter.strike(state: State, userId: number, amount: number): (State, any)
    assert(amount > 0 and amount <= 100, "Glass Bailiff strike amount is invalid")
    if state.status ~= "sitting" and state.status ~= "sentencing" then
        return state, { accepted = false, reason = state.status }
    end
    local occupied = state.status == "sentencing"
    local applied = if occupied then amount else math.max(1, math.floor(amount * SITTING_FRACTION))
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState.health = math.max(0, state.health - applied)
    if nextState.health <= 0 then
        nextState.status = "complete"
        nextState.marked = nil
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            completed = nextState.status == "complete",
            damage = applied,
            health = nextState.health,
            occupied = occupied,
            reason = if nextState.status == "complete"
                then "completed"
                elseif occupied then "damaged"
                else "deflected",
        }
end

function GlassBailiffEncounter.attack(attackIndex: number, standing: number): any
    -- With cover left it works the lanes between the structures; with the
    -- court bare it stops aiming at all.
    if standing <= 1 or attackIndex % 2 == 0 then
        return SENTENCE
    end
    return SUMMONS
end

function GlassBailiffEncounter.snapshot(state: State, userId: number): any
    local standing = GlassBailiffEncounter.standingCount(state)
    local instruction = if state.status == "sitting" and state.marked ~= nil
        then "IT HAS MARKED SOMETHING — APPEAL IT OR LET IT FALL"
        elseif state.status == "sitting" then "NOTHING IS MARKED — IT IS STILL IN SESSION"
        elseif state.status == "sentencing" then "IT IS CARRYING OUT THE SENTENCE — STRIKE"
        elseif state.status == "complete" then "THE BAILIFF IS DOWN · THE COURT IS ADJOURNED"
        elseif state.status == "disabled" then "ELITE TEMPORARILY DORMANT"
        else "ENTER THE COURT"
    return {
        active = state.status == "sitting" or state.status == "sentencing",
        complete = state.status == "complete",
        displayName = "GLASS BAILIFF",
        enabled = state.status ~= "disabled",
        health = state.health,
        instruction = instruction,
        marked = state.marked,
        maxHealth = MAX_HEALTH,
        occupied = state.status == "sentencing",
        phase = math.min(3, math.floor((MAX_HEALTH - state.health) / (MAX_HEALTH / 3)) + 1),
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        standing = standing,
        standingTotal = #STRUCTURE_IDS,
        status = state.status,
    }
end

function GlassBailiffEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        GlassBailiffEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(GlassBailiffEncounter)
