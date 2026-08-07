--!strict

--[[
    The Admiral Wreck -- the Reach's second elite.

    It commands moving ship-debris cover: a ring of hulls that drifts
    around it and takes every blow meant for the thing behind them. The
    catalog's phrase is the fight. You cannot out-damage cover that moves;
    you have to make it stop moving, and the way to do that is to foul the
    tow lines that drag it.

    Four lines, four cuts, and the wreck ring slows with each one -- but
    the lines are re-rigged over time by whatever crew it still has, so a
    party that cuts one and wanders finds it back. That is the difference
    between this and the Iron Widow: her anchors stay cut, and his do not.
    Hers is a fight you win by tempo, his by not letting go.

    Same contract as every elite: profession-independent, solo-passable,
    one reward per participant per run, disable-able, server-called.
]]

local AdmiralWreckEncounter = {}

export type Status = "disabled" | "dormant" | "covered" | "exposed" | "complete"

export type State = {
    health: number,
    lines: { [string]: boolean },
    manifestHash: string,
    participants: { [string]: boolean },
    revision: number,
    runId: string,
    status: Status,
}

local MAX_HEALTH = 340
local LINE_IDS = table.freeze({
    "tow_bow",
    "tow_quarter",
    "tow_stern",
    "tow_spring",
})
-- What a blow is worth against a ring that is still turning.
local COVERED_FRACTION = 0.3

local DEBRIS_SWEEP = table.freeze({
    attackId = "admiral_wreck_sweep",
    attackName = "DEBRIS SWEEP",
    damage = 26,
    instruction = "THE RING IS COMING AROUND — MOVE INSIDE IT",
    radius = 14,
    shape = "circle",
    windup = 1.5,
})

local BROADSIDE = table.freeze({
    attackId = "admiral_wreck_broadside",
    attackName = "BROADSIDE",
    damage = 32,
    instruction = "CLEAR THE BROADSIDE LINE",
    length = 34,
    shape = "lane",
    width = 9,
    windup = 1.3,
})

AdmiralWreckEncounter.Id = "elite_admiral_wreck"
AdmiralWreckEncounter.MaxHealth = MAX_HEALTH
AdmiralWreckEncounter.LineIds = LINE_IDS
AdmiralWreckEncounter.CoveredFraction = COVERED_FRACTION
AdmiralWreckEncounter.Reward = table.freeze({
    amount = 3,
    materialId = "material_ships_iron",
})
AdmiralWreckEncounter.Tuning = table.freeze({
    attackCooldownSeconds = 3.4,
    exposedAttackCooldownSeconds = 4.6,
    -- How long a cut line stays cut before its crew re-rigs it.
    lineRerigSeconds = 18,
    strikeDamage = 34,
})

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.lines = table.clone(state.lines)
    nextState.participants = table.clone(state.participants)
    return nextState
end

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "participant user ID is invalid")
    return tostring(userId)
end

local function isLine(lineId: any): boolean
    for _, id in LINE_IDS do
        if id == lineId then
            return true
        end
    end
    return false
end

function AdmiralWreckEncounter.cutCount(state: State): number
    local cut = 0
    for _, id in LINE_IDS do
        if state.lines[id] then
            cut += 1
        end
    end
    return cut
end

function AdmiralWreckEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Admiral Wreck run ID is required")
    assert(manifestHash ~= "", "Admiral Wreck manifest hash is required")
    return {
        health = MAX_HEALTH,
        lines = {},
        manifestHash = manifestHash,
        participants = {},
        revision = 0,
        runId = runId,
        status = if enabled then "dormant" else "disabled",
    }
end

function AdmiralWreckEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "covered"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function AdmiralWreckEncounter.join(state: State, userId: number): State
    if state.status ~= "covered" and state.status ~= "exposed" then
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
    Cut a tow line. Every cut slows the ring; all four stop it, and a
    stopped ring is no cover at all. Cuts do not last -- see rerigLine --
    so this is a fight about holding a state rather than reaching one.
]]
function AdmiralWreckEncounter.cutLine(state: State, userId: number, lineId: any): (State, any)
    if state.status ~= "covered" and state.status ~= "exposed" then
        return state, { accepted = false, reason = state.status }
    end
    if not isLine(lineId) then
        return state, { accepted = false, reason = "unknown_line" }
    end
    if state.lines[lineId] then
        return state, { accepted = false, reason = "already_cut" }
    end
    local nextState = cloneState(state)
    nextState.lines[lineId] = true
    nextState.participants[participantKey(userId)] = true
    local cut = AdmiralWreckEncounter.cutCount(nextState)
    local stopped = cut >= #LINE_IDS
    if stopped then
        nextState.status = "exposed"
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            cut = cut,
            reason = if stopped then "ring_stopped" else "line_cut",
            remaining = #LINE_IDS - cut,
            stopped = stopped,
        }
end

-- Its crew re-rigs a line. The ring turns again, and whatever the party
-- had bought with that cut is gone.
function AdmiralWreckEncounter.rerigLine(state: State, lineId: any): (State, any)
    if state.status ~= "covered" and state.status ~= "exposed" then
        return state, { accepted = false, reason = state.status }
    end
    if not isLine(lineId) or not state.lines[lineId] then
        return state, { accepted = false, reason = "not_cut" }
    end
    local nextState = cloneState(state)
    nextState.lines[lineId] = nil
    nextState.status = "covered"
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            reason = "line_rerigged",
            cut = AdmiralWreckEncounter.cutCount(nextState),
        }
end

--[[
    A blow always lands; the ring decides how much of it survives. With
    the ring stopped a strike is full, and with it turning it is a third,
    floored at one so a party that never cuts a line still converges --
    very slowly, which is the point.
]]
function AdmiralWreckEncounter.strike(state: State, userId: number, amount: number): (State, any)
    assert(amount > 0 and amount <= 100, "Admiral Wreck strike amount is invalid")
    if state.status ~= "covered" and state.status ~= "exposed" then
        return state, { accepted = false, reason = state.status }
    end
    local exposed = state.status == "exposed"
    local applied = if exposed then amount else math.max(1, math.floor(amount * COVERED_FRACTION))
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState.health = math.max(0, state.health - applied)
    if nextState.health <= 0 then
        nextState.status = "complete"
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            completed = nextState.status == "complete",
            covered = not exposed,
            damage = applied,
            health = nextState.health,
            reason = if nextState.status == "complete"
                then "completed"
                elseif exposed then "damaged"
                else "covered",
        }
end

function AdmiralWreckEncounter.attack(attackIndex: number, cutCount: number): any
    -- A ring that is still turning sweeps; a stopped one fires along it.
    if cutCount >= #LINE_IDS or attackIndex % 2 == 0 then
        return BROADSIDE
    end
    return DEBRIS_SWEEP
end

function AdmiralWreckEncounter.snapshot(state: State, userId: number): any
    local cut = AdmiralWreckEncounter.cutCount(state)
    local instruction = if state.status == "covered"
        then string.format("CUT THE TOW LINES — %d OF %d", cut, #LINE_IDS)
        elseif state.status == "exposed" then "THE RING IS STOPPED — STRIKE HIM"
        elseif state.status == "complete" then "THE WRECKS DRIFT APART"
        elseif state.status == "disabled" then "ELITE TEMPORARILY DORMANT"
        else "ENTER THE WRECK YARD"
    return {
        active = state.status == "covered" or state.status == "exposed",
        complete = state.status == "complete",
        covered = state.status == "covered",
        displayName = "ADMIRAL WRECK",
        enabled = state.status ~= "disabled",
        exposed = state.status == "exposed",
        health = state.health,
        instruction = instruction,
        lineTotal = #LINE_IDS,
        linesCut = cut,
        maxHealth = MAX_HEALTH,
        phase = math.min(3, math.floor(cut / 2) + 1),
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        status = state.status,
    }
end

function AdmiralWreckEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        AdmiralWreckEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(AdmiralWreckEncounter)
