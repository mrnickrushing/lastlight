--!strict

--[[
    The Ash Regent -- chapter VI's boss, in the box it never left.

    Four phases, and the catalog's non-profession solution read literally:
    expose authentic memories, break false statues.

    The Regent is not standing in the court. It is standing in everything
    in the court, distributed across the casts the fire made, and it
    cannot be touched until enough of them are gone. Each phase seats five
    statues around it. Some are casts -- shapes the ash took, repeating,
    empty. Some are authentic: a person the fire caught, kept exactly, and
    the only real record of anyone who was here.

    A party can inspect a statue and learn which it is, or skip the
    inspection and swing. Breaking a false statue takes one of the
    Regent's anchors away. Breaking an authentic one takes two, because
    the Regent is rooted far deeper in something true than in something
    it made up -- which is the fight's whole argument and the chapter's
    decision at the same time. The fast way through the Crown is to
    destroy the only memory of the people who died in it.

    So there is no menu at the end. What the court remembers afterwards
    is a count of what a party smashed to get there.
]]

local AshRegentEncounter = {}

export type Status = "disabled" | "locked" | "dormant" | "anchored" | "exposed" | "complete"

export type State = {
    broken: { [string]: boolean },
    erased: number,
    health: number,
    manifestHash: string,
    participants: { [string]: boolean },
    phase: number,
    revealed: { [string]: boolean },
    revision: number,
    runId: string,
    status: Status,
}

local MAX_HEALTH = 720
local PHASE_THRESHOLDS = table.freeze({ 540, 360, 180, 0 })
local STATUE_IDS = table.freeze({
    "statue_first",
    "statue_second",
    "statue_third",
    "statue_fourth",
    "statue_fifth",
})
-- How much of the Regent each kind of statue is holding up.
local FALSE_ANCHORS = 1
local AUTHENTIC_ANCHORS = 2
-- Anchors that have to come away before the Regent can be touched.
local ANCHORS_REQUIRED = 3

local ASH_FALL = table.freeze({
    attackId = "ash_regent_fall",
    attackName = "ASH FALL",
    damage = 30,
    instruction = "GET UNDER SOMETHING",
    radius = 17,
    shape = "circle",
    windup = 1.6,
})

local RECITATION = table.freeze({
    attackId = "ash_regent_recital",
    attackName = "RECITATION",
    damage = 26,
    instruction = "IT IS SAYING A NAME — CLEAR THE LINE",
    length = 34,
    shape = "lane",
    width = 8,
    windup = 1.4,
})

local CORONATION = table.freeze({
    attackId = "ash_regent_coronation",
    attackName = "CORONATION",
    damage = 36,
    instruction = "THE CEREMONY IS FINISHING — BREAK IT",
    radius = 21,
    shape = "circle",
    windup = 1.9,
})

AshRegentEncounter.Id = "boss_ash_regent"
AshRegentEncounter.MaxHealth = MAX_HEALTH
AshRegentEncounter.StatueIds = STATUE_IDS
AshRegentEncounter.AnchorsRequired = ANCHORS_REQUIRED
AshRegentEncounter.Reward = table.freeze({
    amount = 5,
    materialId = "material_cindersteel",
})
AshRegentEncounter.Tuning = table.freeze({
    attackCooldownSeconds = 3.5,
    exposedAttackCooldownSeconds = 4.3,
    strikeDamage = 45,
})

--[[
    Which statues in a phase are authentic. Derived rather than stored, so
    a client cannot be handed the answer and a spec can walk every phase
    without reaching inside the fight. Two per phase, and never the same
    two twice, so a party cannot learn a position and stop looking.
]]
function AshRegentEncounter.isAuthentic(phase: number, statueId: any): boolean
    for index, id in STATUE_IDS do
        if id == statueId then
            local shifted = (index + phase) % #STATUE_IDS
            return shifted == 0 or shifted == 1
        end
    end
    return false
end

function AshRegentEncounter.authenticIds(phase: number): { string }
    local ids: { string } = {}
    for _, id in STATUE_IDS do
        if AshRegentEncounter.isAuthentic(phase, id) then
            table.insert(ids, id)
        end
    end
    return ids
end

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.broken = table.clone(state.broken)
    nextState.participants = table.clone(state.participants)
    nextState.revealed = table.clone(state.revealed)
    return nextState
end

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "participant user ID is invalid")
    return tostring(userId)
end

local function isStatue(statueId: any): boolean
    for _, id in STATUE_IDS do
        if id == statueId then
            return true
        end
    end
    return false
end

function AshRegentEncounter.anchorsRemoved(state: State): number
    local total = 0
    for statueId, wasBroken in state.broken do
        if wasBroken then
            total += if AshRegentEncounter.isAuthentic(state.phase, statueId)
                then AUTHENTIC_ANCHORS
                else FALSE_ANCHORS
        end
    end
    return total
end

function AshRegentEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Ash Regent run ID is required")
    assert(manifestHash ~= "", "Ash Regent manifest hash is required")
    return {
        broken = {},
        erased = 0,
        health = MAX_HEALTH,
        manifestHash = manifestHash,
        participants = {},
        phase = 1,
        revealed = {},
        revision = 0,
        runId = runId,
        status = if enabled then "locked" else "disabled",
    }
end

function AshRegentEncounter.unlock(state: State): (State, any)
    if state.status ~= "locked" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "dormant"
    nextState.revision += 1
    return nextState, { accepted = true, reason = "unlocked" }
end

function AshRegentEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "anchored"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function AshRegentEncounter.join(state: State, userId: number): State
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

--[[
    Look at a statue closely enough to know what it is. Free, repeatable,
    and the only thing in the fight that costs nothing but time -- which
    is exactly what the Crown is trying to take.
]]
function AshRegentEncounter.inspect(state: State, userId: number, statueId: any): (State, any)
    if state.status ~= "anchored" then
        return state, { accepted = false, reason = state.status }
    end
    if not isStatue(statueId) then
        return state, { accepted = false, reason = "unknown_statue" }
    end
    if state.broken[statueId] then
        return state, { accepted = false, reason = "already_broken" }
    end
    local nextState = cloneState(state)
    nextState.revealed[statueId] = true
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    local authentic = AshRegentEncounter.isAuthentic(state.phase, statueId)
    return nextState,
        {
            accepted = true,
            authentic = authentic,
            reason = if authentic then "authentic" else "false_cast",
        }
end

function AshRegentEncounter.breakStatue(state: State, userId: number, statueId: any): (State, any)
    if state.status ~= "anchored" then
        return state, { accepted = false, reason = state.status }
    end
    if not isStatue(statueId) then
        return state, { accepted = false, reason = "unknown_statue" }
    end
    if state.broken[statueId] then
        return state, { accepted = false, reason = "already_broken" }
    end
    local authentic = AshRegentEncounter.isAuthentic(state.phase, statueId)
    local nextState = cloneState(state)
    nextState.broken[statueId] = true
    nextState.participants[participantKey(userId)] = true
    if authentic then
        nextState.erased += 1
    end
    local anchors = AshRegentEncounter.anchorsRemoved(nextState)
    if anchors >= ANCHORS_REQUIRED then
        nextState.status = "exposed"
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            anchors = anchors,
            authentic = authentic,
            reason = if nextState.status == "exposed"
                then "regent_exposed"
                elseif authentic then "memory_erased"
                else "cast_broken",
            required = ANCHORS_REQUIRED,
        }
end

function AshRegentEncounter.strike(state: State, userId: number, amount: number): (State, any)
    assert(amount > 0 and amount <= 100, "Ash Regent strike amount is invalid")
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
        else
            nextState.phase = state.phase + 1
            nextState.status = "anchored"
            nextState.broken = {}
            nextState.revealed = {}
        end
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            completed = nextState.status == "complete",
            damage = amount,
            health = nextState.health,
            outcome = AshRegentEncounter.outcome(nextState),
            phase = nextState.phase,
            reason = if nextState.status == "complete"
                then "completed"
                elseif nextState.phase > state.phase then "phase_cleared"
                else "damaged",
        }
end

--[[
    What the court remembers. Not a menu and not a stored decision -- a
    count of the authentic statues a party chose to break, available only
    once the fight is over so nothing can read it early and change how it
    plays.
]]
function AshRegentEncounter.outcome(state: State): string?
    if state.status ~= "complete" then
        return nil
    end
    if state.erased == 0 then
        return "remembered"
    elseif state.erased >= 3 then
        return "erased"
    end
    return "recast"
end

function AshRegentEncounter.attack(attackIndex: number, phase: number, status: Status?): any
    if status == "exposed" then
        return CORONATION
    end
    if phase >= 3 and attackIndex % 2 == 0 then
        return ASH_FALL
    end
    return RECITATION
end

function AshRegentEncounter.snapshot(state: State, userId: number): any
    local outcome = AshRegentEncounter.outcome(state)
    local instruction = if state.status == "anchored"
        then string.format(
            "TAKE ITS ANCHORS — %d OF %d",
            AshRegentEncounter.anchorsRemoved(state),
            ANCHORS_REQUIRED
        )
        elseif state.status == "exposed" then "THE REGENT IS STANDING ALONE — STRIKE"
        elseif state.status == "complete" then if outcome == "remembered"
            then "THE REGENT IS DOWN · EVERY TRUE FACE STILL STANDS"
            elseif outcome == "erased" then "THE REGENT IS DOWN · NOBODY IS LEFT TO REMEMBER"
            else "THE REGENT IS DOWN · SOME OF THEM ARE STILL HERE"
        elseif state.status == "locked" then "THE CROWN IS NOT OPEN TO YOU YET"
        elseif state.status == "disabled" then "THE REGENT DOES NOT ANSWER"
        else "SOMETHING IN THE BOX IS SITTING VERY STILL"
    return {
        active = state.status == "anchored" or state.status == "exposed",
        anchors = AshRegentEncounter.anchorsRemoved(state),
        anchorsRequired = ANCHORS_REQUIRED,
        complete = state.status == "complete",
        displayName = "ASH REGENT",
        enabled = state.status ~= "disabled",
        erased = state.erased,
        health = state.health,
        instruction = instruction,
        maxHealth = MAX_HEALTH,
        outcome = outcome,
        phase = state.phase,
        revealed = table.clone(state.revealed),
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        status = state.status,
        statueTotal = #STATUE_IDS,
    }
end

function AshRegentEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        AshRegentEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(AshRegentEncounter)
