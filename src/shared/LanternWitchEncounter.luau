--!strict

--[[
    The Lantern Witch -- chapter III's boss, at the heart of Mireglass Fen.

    Four phases, and the content catalog's non-profession solution read
    literally: identify tells, use copies, consent seal.

    - **Identify.** She stands among her own copies. Each round, every
      copy shows a tell -- one of them is wrong, and naming the wrong one
      is the only way to find her. Naming a true copy costs the round, not
      the run.
    - **Use.** Found, she does not simply take damage: her copies do. The
      copies she made are turned, and each one spent is a phase's worth of
      progress. This is the chapter's decision -- spend a copy or spare it.
    - **Consent.** At the last phase she asks to be sealed rather than
      broken, and the seal only holds if it is given, not taken. A crew
      that spent every copy has nothing left to offer and seals her the
      hard way; a crew that spared them can close the chapter gently.

    Outcomes: sealed (copies spared, consent given), broken (copies spent),
    or bound (somewhere between). Recorded the way the Warden's antlers and
    the Maw's vent are -- decided by play, legible in one line.
]]

local LanternWitchEncounter = {}

export type Status = "disabled" | "locked" | "dormant" | "hiding" | "found" | "asking" | "complete"

export type State = {
    copiesRemaining: number,
    copiesSpent: number,
    health: number,
    manifestHash: string,
    outcome: string?,
    participants: { [string]: boolean },
    phase: number,
    revision: number,
    round: number,
    runId: string,
    status: Status,
}

local MAX_HEALTH = 520
local PHASE_THRESHOLDS = table.freeze({ 390, 260, 130, 0 })
local COPY_COUNT = 4
-- Which copy is false in a given round: deterministic from the round, so
-- the tell is learnable rather than a coin toss.
local COPY_IDS = table.freeze({
    "copy_first",
    "copy_second",
    "copy_third",
    "copy_fourth",
})

local WITCHLIGHT_RING = table.freeze({
    attackId = "lantern_witch_ring",
    attackName = "WITCHLIGHT RING",
    damage = 24,
    instruction = "LEAVE THE RING OF LIGHTS",
    radius = 12,
    shape = "circle",
    windup = 1.4,
})

local FALSE_PATH = table.freeze({
    attackId = "lantern_witch_false_path",
    attackName = "FALSE PATH",
    damage = 28,
    instruction = "THAT GROUND IS NOT THERE — GET OFF THE LINE",
    length = 32,
    shape = "lane",
    width = 8,
    windup = 1.25,
})

local DROWNING_CHOIR = table.freeze({
    attackId = "lantern_witch_choir",
    attackName = "DROWNING CHOIR",
    damage = 32,
    instruction = "COVER YOUR EARS AND MOVE",
    radius = 15,
    shape = "circle",
    windup = 1.8,
})

LanternWitchEncounter.Id = "boss_lantern_witch"
LanternWitchEncounter.MaxHealth = MAX_HEALTH
LanternWitchEncounter.CopyIds = COPY_IDS
LanternWitchEncounter.CopyCount = COPY_COUNT
LanternWitchEncounter.Reward = table.freeze({
    amount = 5,
    materialId = "material_witchlight_pollen",
})
LanternWitchEncounter.Tuning = table.freeze({
    askingAttackCooldownSeconds = 5,
    attackCooldownSeconds = 3.4,
    hidingAttackCooldownSeconds = 4,
    markedStrikeDamage = 46,
    strikeDamage = 40,
})

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "boss participant user ID is invalid")
    return tostring(userId)
end

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.participants = table.clone(state.participants)
    return nextState
end

local function isActive(status: Status): boolean
    return status == "hiding" or status == "found" or status == "asking"
end

--[[
    Which copy carries the wrong tell this round. Deterministic, and it
    walks rather than repeats, so a crew learns the rhythm instead of
    guessing four ways every time.
]]
function LanternWitchEncounter.falseCopy(round: number, phase: number): string
    return COPY_IDS[(round + phase - 2) % COPY_COUNT + 1]
end

function LanternWitchEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Lantern Witch run ID is required")
    assert(manifestHash ~= "", "Lantern Witch manifest hash is required")
    return {
        copiesRemaining = COPY_COUNT,
        copiesSpent = 0,
        health = MAX_HEALTH,
        manifestHash = manifestHash,
        outcome = nil,
        participants = {},
        phase = 1,
        revision = 0,
        round = 1,
        runId = runId,
        status = if enabled then "locked" else "disabled",
    }
end

function LanternWitchEncounter.unlock(state: State): (State, any)
    if state.status ~= "locked" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "dormant"
    nextState.revision += 1
    return nextState, { accepted = true, reason = "unlocked" }
end

function LanternWitchEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "hiding"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function LanternWitchEncounter.join(state: State, userId: number): State
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
    Name a copy. The one whose tell is wrong is the Witch; naming a true
    copy costs the round -- the tells reshuffle -- and nothing else. A
    wrong guess is never fatal, because a boss that punishes reading is a
    boss nobody reads.
]]
function LanternWitchEncounter.nameCopy(state: State, userId: number, copyId: any): (State, any)
    if state.status ~= "hiding" then
        return state, { accepted = false, reason = state.status }
    end
    local valid = false
    for _, id in COPY_IDS do
        if id == copyId then
            valid = true
            break
        end
    end
    if not valid then
        return state, { accepted = false, reason = "unknown_copy" }
    end
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    local target = LanternWitchEncounter.falseCopy(state.round, state.phase)
    if copyId ~= target then
        nextState.round += 1
        nextState.revision += 1
        return nextState,
            {
                accepted = true,
                found = false,
                reason = "true_copy_named",
                round = nextState.round,
            }
    end
    nextState.status = "found"
    nextState.revision += 1
    return nextState, { accepted = true, found = true, reason = "witch_found" }
end

--[[
    Spend one of her copies against her, or spare it. Spending advances
    the phase outright; sparing means finding her again the hard way, and
    is what the ending remembers.
]]
function LanternWitchEncounter.useCopy(state: State, userId: number, spend: boolean): (State, any)
    if state.status ~= "found" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    if not spend then
        -- spared: she slips back among them and the round moves on
        nextState.status = "hiding"
        nextState.round += 1
        nextState.revision += 1
        return nextState, { accepted = true, reason = "copy_spared", spent = false }
    end
    if state.copiesRemaining <= 0 then
        return state, { accepted = false, reason = "no_copies_left" }
    end
    nextState.copiesRemaining -= 1
    nextState.copiesSpent += 1
    local threshold = PHASE_THRESHOLDS[state.phase]
    nextState.health = threshold
    if state.phase >= #PHASE_THRESHOLDS - 1 then
        nextState.status = "asking"
    else
        nextState.phase += 1
        nextState.round = 1
        nextState.status = "hiding"
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            copiesRemaining = nextState.copiesRemaining,
            health = nextState.health,
            phase = nextState.phase,
            reason = if nextState.status == "asking" then "final_phase" else "copy_spent",
            spent = true,
        }
end

--[[
    The last phase: she asks. Granting consent seals her, and how gently
    depends on what is left of her copies. Refusing takes the seal by
    force, which the Fen also remembers.
]]
function LanternWitchEncounter.answer(state: State, userId: number, consent: boolean): (State, any)
    if state.status ~= "asking" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState.health = 0
    nextState.status = "complete"
    nextState.outcome = if not consent
        then "broken"
        elseif nextState.copiesSpent <= 1 then "sealed"
        else "bound"
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            completed = true,
            consent = consent,
            outcome = nextState.outcome,
            reason = "chapter_closed",
        }
end

function LanternWitchEncounter.attack(attackIndex: number, phase: number): any
    if phase >= 4 then
        return DROWNING_CHOIR
    elseif phase >= 2 and attackIndex % 2 == 0 then
        return FALSE_PATH
    end
    return WITCHLIGHT_RING
end

function LanternWitchEncounter.snapshot(state: State, userId: number): any
    local instruction = if state.status == "hiding"
        then "ONE TELL IS WRONG — NAME THE FALSE LANTERN"
        elseif state.status == "found" then "SPEND ONE OF HER COPIES, OR SPARE IT"
        elseif state.status == "asking" then "SHE ASKS TO BE SEALED — ANSWER HER"
        elseif state.status == "complete" then if state.outcome == "sealed"
            then "THE WITCH IS SEALED · SHE WENT WILLINGLY"
            elseif state.outcome == "broken" then "THE WITCH IS BROKEN · THE FEN IS QUIET AND COLD"
            else "THE WITCH IS BOUND · SOMETHING OF HER REMAINS"
        elseif state.status == "dormant" then "ENTER THE WITCHLIGHT RING"
        elseif state.status == "locked" then "CLEAR THE FEN'S ELITES TO REACH HER"
        elseif state.status == "disabled" then "LANTERN WITCH TEMPORARILY DORMANT"
        else "LANTERN WITCH"
    return {
        active = isActive(state.status),
        asking = state.status == "asking",
        choiceAvailable = state.status == "found" or state.status == "asking",
        complete = state.status == "complete",
        copiesRemaining = state.copiesRemaining,
        copiesSpent = state.copiesSpent,
        displayName = "LANTERN WITCH",
        enabled = state.status ~= "disabled",
        found = state.status == "found",
        health = state.health,
        instruction = instruction,
        maxHealth = MAX_HEALTH,
        outcome = state.outcome,
        phase = state.phase,
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        round = state.round,
        status = state.status,
    }
end

function LanternWitchEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        LanternWitchEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(LanternWitchEncounter)
