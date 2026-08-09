--!strict

--[[
    The Many-Face -- Mireglass Fen's first elite.

    It wears a profession. Not yours necessarily: it cycles openly through
    the seven, and whichever it is wearing, it fights with that kit's
    strength and carries that kit's weakness. The catalog calls this
    "cycles visible copied profession", and visible is the whole design --
    the tell is never hidden, only brief. You cannot out-damage it wearing
    the wrong answer; you wait for the face that its current guard cannot
    cover, and you commit.

    Concretely: each face has a counter, expressed as a plain interaction
    at one of three fen mirrors. Strike it while its face is countered and
    the blow lands full; strike it uncountered and the mirror-guard turns
    most of it away. It changes face on its own clock, so the fight is
    read-and-time rather than lever-and-burst -- deliberately unlike the
    Foreman Echo, whose fight is order, and the Iron Widow's, whose fight
    is tempo.

    Same contract as every elite: profession-independent (the counters are
    mirrors anyone can turn), solo-passable, one reward per participant
    per run through a deterministic transaction id, disable-able, and
    every mutation server-called.
]]

local Strings = require("./Strings")

local ManyFaceEncounter = {}

export type Status = "disabled" | "dormant" | "wearing" | "countered" | "complete"

export type State = {
    faceIndex: number,
    counteredUntil: number,
    health: number,
    manifestHash: string,
    mirrorsTurned: { [string]: boolean },
    participants: { [string]: boolean },
    revision: number,
    runId: string,
    status: Status,
}

local MAX_HEALTH = 340
-- The seven faces, in the order it cycles them. It never hides which one
-- it is wearing; the pressure is that the window is short.
local FACES = table.freeze({
    "profession_forager",
    "profession_builder",
    "profession_scout",
    "profession_cook",
    "profession_healer",
    "profession_engineer",
    "profession_beastkeeper",
})
local MIRROR_IDS = table.freeze({
    mirror_left = true,
    mirror_center = true,
    mirror_right = true,
})
-- Turning the right mirror strips the face for this long. Long enough to
-- reach it, short enough that you must already be moving.
local COUNTER_SECONDS = 7
-- What an uncountered blow is worth against the mirror-guard.
local GUARDED_FRACTION = 0.25

local MIRROR_SPRAY = table.freeze({
    attackId = "many_face_mirror_spray",
    attackName = Strings.get("encounter.mirror_spray"),
    damage = 22,
    instruction = Strings.get("encounter.get_out_of_the_glass_ring"),
    radius = 11,
    shape = "circle",
    windup = 1.35,
})

local BORROWED_REACH = table.freeze({
    attackId = "many_face_borrowed_reach",
    attackName = Strings.get("encounter.borrowed_reach"),
    damage = 28,
    instruction = Strings.get("encounter.clear_the_line_it_has_someone"),
    length = 30,
    shape = "lane",
    width = 7,
    windup = 1.2,
})

ManyFaceEncounter.Id = "elite_many_face"
ManyFaceEncounter.MaxHealth = MAX_HEALTH
ManyFaceEncounter.Faces = FACES
ManyFaceEncounter.MirrorIds = MIRROR_IDS
ManyFaceEncounter.CounterSeconds = COUNTER_SECONDS
ManyFaceEncounter.GuardedFraction = GUARDED_FRACTION
ManyFaceEncounter.Reward = table.freeze({
    amount = 3,
    materialId = "material_mirror_reed",
})
ManyFaceEncounter.Tuning = table.freeze({
    attackCooldownSeconds = 3,
    counteredAttackCooldownSeconds = 4.4,
    faceSeconds = 12,
    strikeDamage = 34,
})

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.mirrorsTurned = table.clone(state.mirrorsTurned)
    nextState.participants = table.clone(state.participants)
    return nextState
end

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "participant user ID is invalid")
    return tostring(userId)
end

--[[
    Which mirror answers the face it is currently wearing. Deterministic
    from the face index, so a player can learn it -- the fight rewards
    recognition, not luck.
]]
function ManyFaceEncounter.counterFor(faceIndex: number): string
    local mirrors = { "mirror_left", "mirror_center", "mirror_right" }
    return mirrors[(faceIndex - 1) % #mirrors + 1]
end

function ManyFaceEncounter.faceAt(faceIndex: number): string
    return FACES[(faceIndex - 1) % #FACES + 1]
end

function ManyFaceEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Many-Face run ID is required")
    assert(manifestHash ~= "", "Many-Face manifest hash is required")
    return {
        counteredUntil = 0,
        faceIndex = 1,
        health = MAX_HEALTH,
        manifestHash = manifestHash,
        mirrorsTurned = {},
        participants = {},
        revision = 0,
        runId = runId,
        status = if enabled then "dormant" else "disabled",
    }
end

function ManyFaceEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "wearing"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function ManyFaceEncounter.join(state: State, userId: number): State
    if state.status ~= "wearing" and state.status ~= "countered" then
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
    Turn a fen mirror. The right one for the face it is wearing strips the
    guard for a window; a wrong one throws its own reflection back and
    does nothing but cost you the walk.
]]
function ManyFaceEncounter.turnMirror(
    state: State,
    userId: number,
    mirrorId: any,
    now: number
): (State, any)
    if state.status ~= "wearing" and state.status ~= "countered" then
        return state, { accepted = false, reason = state.status }
    end
    if type(mirrorId) ~= "string" or MIRROR_IDS[mirrorId] ~= true then
        return state, { accepted = false, reason = "unknown_mirror" }
    end
    local wanted = ManyFaceEncounter.counterFor(state.faceIndex)
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState.mirrorsTurned[mirrorId] = true
    if mirrorId ~= wanted then
        nextState.revision += 1
        return nextState, { accepted = false, reason = "wrong_mirror" }
    end
    nextState.status = "countered"
    nextState.counteredUntil = now + COUNTER_SECONDS
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            counteredUntil = nextState.counteredUntil,
            face = ManyFaceEncounter.faceAt(state.faceIndex),
            reason = "face_countered",
        }
end

--[[
    It changes face on its own clock. Changing face restores the guard,
    resets which mirrors have been turned, and is the reason a player who
    dithers loses their window rather than their run.
]]
function ManyFaceEncounter.cycleFace(state: State): (State, any)
    if state.status ~= "wearing" and state.status ~= "countered" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.faceIndex = (state.faceIndex % #FACES) + 1
    nextState.status = "wearing"
    nextState.counteredUntil = 0
    nextState.mirrorsTurned = {}
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            counter = ManyFaceEncounter.counterFor(nextState.faceIndex),
            face = ManyFaceEncounter.faceAt(nextState.faceIndex),
            reason = "face_changed",
        }
end

-- The counter window closing is the same event as the face resuming its
-- guard; the service calls this on its tick.
function ManyFaceEncounter.expire(state: State, now: number): State
    if state.status ~= "countered" or now < state.counteredUntil then
        return state
    end
    local nextState = cloneState(state)
    nextState.status = "wearing"
    nextState.counteredUntil = 0
    nextState.revision += 1
    return nextState
end

--[[
    A strike always lands -- the question is how much of it survives the
    mirror-guard. Countered: full. Guarded: a quarter, floored at 1, so a
    player who never reads a face still converges, very slowly, rather
    than being locked out of the fight entirely.
]]
function ManyFaceEncounter.strike(
    state: State,
    userId: number,
    amount: number,
    now: number
): (State, any)
    assert(amount > 0 and amount <= 100, "Many-Face strike amount is invalid")
    if state.status ~= "wearing" and state.status ~= "countered" then
        return state, { accepted = false, reason = state.status }
    end
    local countered = state.status == "countered" and now < state.counteredUntil
    local applied = if countered then amount else math.max(1, math.floor(amount * GUARDED_FRACTION))

    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState.health = math.max(0, state.health - applied)
    if nextState.health <= 0 then
        nextState.status = "complete"
        nextState.counteredUntil = 0
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            completed = nextState.status == "complete",
            countered = countered,
            damage = applied,
            health = nextState.health,
            reason = if nextState.status == "complete"
                then "completed"
                elseif countered then "damaged"
                else "guarded",
        }
end

function ManyFaceEncounter.attack(attackIndex: number, faceIndex: number): any
    if faceIndex % 2 == 0 and attackIndex % 2 == 0 then
        return BORROWED_REACH
    end
    return MIRROR_SPRAY
end

function ManyFaceEncounter.snapshot(state: State, userId: number, now: number): any
    local countered = state.status == "countered" and now < state.counteredUntil
    local face = ManyFaceEncounter.faceAt(state.faceIndex)
    local instruction = if countered
        then Strings.get("encounter.the_face_is_stripped_strike_now")
        elseif state.status == "wearing" then Strings.get(
            "encounter.it_wears_another_s_face_turn"
        )
        elseif state.status == "complete" then Strings.get(
            "encounter.the_faces_are_its_own_again"
        )
        elseif state.status == "disabled" then Strings.get(
            "encounter.elite_temporarily_dormant"
        )
        else Strings.get("encounter.enter_the_mirror_court")
    return {
        active = state.status == "wearing" or state.status == "countered",
        complete = state.status == "complete",
        countered = countered,
        counteredUntil = if countered then state.counteredUntil else 0,
        displayName = Strings.get("encounter.the_many_face"),
        enabled = state.status ~= "disabled",
        face = face,
        health = state.health,
        instruction = instruction,
        maxHealth = MAX_HEALTH,
        phase = math.min(3, math.floor((MAX_HEALTH - state.health) / (MAX_HEALTH / 3)) + 1),
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        status = state.status,
    }
end

function ManyFaceEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        ManyFaceEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(ManyFaceEncounter)
