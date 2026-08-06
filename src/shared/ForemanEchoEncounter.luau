--!strict

--[[
    Foreman Echo -- the Ironroot Delve's first elite.

    What is left of the shift boss still runs the mine. It does not fight
    you directly so much as it commands the machinery to: while it holds
    the signal board, it marks unsafe ground and the Delve's own equipment
    enforces the marks. The answer is not damage, it is authority. Three
    signal levers stand around the gallery; throwing all three strips the
    Echo of its command and leaves it exposed until it shouts the board
    back to life.

    Contract, matching the Old Growth's: profession-independent (levers
    are plain interactions), solo-passable (levers stay thrown, so one
    player can walk them), reward granted once per run per participant via
    a deterministic transaction id, disable-able, and no state that a
    client can assert -- every mutation here is called by the server.

    Distinct from the Old Growth by design: no carried fire, no burn
    window. Where the forest elite asks you to hold something fragile
    under pressure, the Delve elite asks you to shut things off in the
    right order while the ground itself is being turned against you.
]]

local ForemanEchoEncounter = {}

export type Status = "disabled" | "dormant" | "commanding" | "exposed" | "complete"

export type State = {
    health: number,
    levers: { [string]: boolean },
    manifestHash: string,
    markedUntil: number,
    participants: { [string]: boolean },
    revision: number,
    runId: string,
    seizeIndex: number,
    status: Status,
}

local MAX_HEALTH = 320
-- Each seize is the Echo shouting the board back: the levers reset and
-- must be walked again. Two seizes, so the encounter is three exposures.
local SEIZE_THRESHOLDS = table.freeze({ 210, 100 })
local LEVER_IDS = table.freeze({ "lever_north", "lever_shaft", "lever_south" })
local MARK_SECONDS = 6

local UNSAFE_MARK = table.freeze({
    attackId = "foreman_echo_mark",
    attackName = "UNSAFE GROUND",
    damage = 22,
    instruction = "LEAVE THE MARKED GROUND",
    radius = 11,
    shape = "circle",
    windup = 1.4,
})

local CART_ORDER = table.freeze({
    attackId = "foreman_echo_cart_order",
    attackName = "CART ORDER",
    damage = 26,
    instruction = "CLEAR THE RAIL LINE",
    length = 30,
    shape = "lane",
    width = 8,
    windup = 1.2,
})

ForemanEchoEncounter.Id = "elite_foreman_echo"
ForemanEchoEncounter.MaxHealth = MAX_HEALTH
ForemanEchoEncounter.LeverIds = LEVER_IDS
ForemanEchoEncounter.MarkSeconds = MARK_SECONDS
ForemanEchoEncounter.Reward = table.freeze({
    amount = 3,
    materialId = "material_ironroot_ore",
})
ForemanEchoEncounter.Tuning = table.freeze({
    attackCooldownSeconds = 3.2,
    commandingAttackCooldownSeconds = 2.6,
    markedStrikeDamage = 38,
    strikeDamage = 32,
})

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.levers = table.clone(state.levers)
    nextState.participants = table.clone(state.participants)
    return nextState
end

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "participant user ID is invalid")
    return tostring(userId)
end

local function isLever(leverId: any): boolean
    for _, id in LEVER_IDS do
        if id == leverId then
            return true
        end
    end
    return false
end

local function leversThrown(state: State): number
    local count = 0
    for _, id in LEVER_IDS do
        if state.levers[id] then
            count += 1
        end
    end
    return count
end

function ForemanEchoEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Foreman Echo run ID is required")
    assert(manifestHash ~= "", "Foreman Echo manifest hash is required")
    return {
        health = MAX_HEALTH,
        levers = {},
        manifestHash = manifestHash,
        markedUntil = 0,
        participants = {},
        revision = 0,
        runId = runId,
        seizeIndex = 0,
        status = if enabled then "dormant" else "disabled",
    }
end

function ForemanEchoEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "commanding"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function ForemanEchoEncounter.join(state: State, userId: number): State
    if state.status ~= "commanding" and state.status ~= "exposed" then
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
    Throw one signal lever. Levers stay thrown, which is what keeps the
    encounter solo-passable: nobody has to hold three places at once.
    When the last one goes over, the Echo loses the board and is exposed.
]]
function ForemanEchoEncounter.throwLever(state: State, userId: number, leverId: any): (State, any)
    if state.status ~= "commanding" then
        return state, { accepted = false, reason = state.status }
    end
    if not isLever(leverId) then
        return state, { accepted = false, reason = "unknown_lever" }
    end
    if state.levers[leverId] then
        return state, { accepted = false, reason = "already_thrown" }
    end
    local nextState = cloneState(state)
    nextState.levers[leverId] = true
    nextState.participants[participantKey(userId)] = true
    local thrown = leversThrown(nextState)
    local exposed = thrown >= #LEVER_IDS
    if exposed then
        nextState.status = "exposed"
        nextState.markedUntil = 0
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            exposed = exposed,
            reason = if exposed then "command_broken" else "lever_thrown",
            remaining = #LEVER_IDS - thrown,
            thrown = thrown,
        }
end

function ForemanEchoEncounter.strike(state: State, userId: number, amount: number): (State, any)
    assert(amount > 0 and amount <= 100, "Foreman Echo strike amount is invalid")
    if state.status ~= "exposed" then
        return state, { accepted = false, reason = state.status }
    end

    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    local nextHealth = math.max(0, state.health - amount)
    local threshold = SEIZE_THRESHOLDS[state.seizeIndex + 1]
    local seized = threshold ~= nil and nextHealth <= threshold
    if seized then
        -- The Echo shouts the board back: levers reset, command resumes.
        nextState.health = threshold
        nextState.seizeIndex += 1
        nextState.status = "commanding"
        nextState.levers = {}
    else
        nextState.health = nextHealth
        if nextHealth <= 0 then
            nextState.status = "complete"
            nextState.markedUntil = 0
        end
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            completed = nextState.status == "complete",
            damage = state.health - nextState.health,
            health = nextState.health,
            reason = if nextState.status == "complete"
                then "completed"
                elseif seized then "board_seized"
                else "damaged",
            seized = seized,
        }
end

-- The Echo marks ground: a timestamp the service uses to keep the
-- telegraph and the damage window agreeing on one clock.
function ForemanEchoEncounter.markGround(state: State, now: number): (State, any)
    if state.status ~= "commanding" then
        return state, { accepted = false, reason = state.status }
    end
    if now < state.markedUntil then
        return state, { accepted = false, reason = "already_marked" }
    end
    local nextState = cloneState(state)
    nextState.markedUntil = now + MARK_SECONDS
    nextState.revision += 1
    return nextState, { accepted = true, markedUntil = nextState.markedUntil, reason = "marked" }
end

function ForemanEchoEncounter.expire(state: State, now: number): State
    if state.markedUntil == 0 or now < state.markedUntil then
        return state
    end
    local nextState = cloneState(state)
    nextState.markedUntil = 0
    nextState.revision += 1
    return nextState
end

function ForemanEchoEncounter.attack(attackIndex: number, seizeIndex: number): any
    -- Once the board has been seized back at least once, the Echo starts
    -- ordering carts as well as marking ground.
    if seizeIndex >= 1 and attackIndex % 2 == 0 then
        return CART_ORDER
    end
    return UNSAFE_MARK
end

function ForemanEchoEncounter.snapshot(state: State, userId: number, now: number): any
    local thrown = leversThrown(state)
    local instruction = if state.status == "commanding"
        then string.format("THROW THE SIGNAL LEVERS — %d OF %d", thrown, #LEVER_IDS)
        elseif state.status == "exposed" then "STRIKE THE FOREMAN"
        elseif state.status == "complete" then "THE SHIFT IS OVER"
        elseif state.status == "disabled" then "ELITE TEMPORARILY DORMANT"
        else "ENTER THE SIGNAL GALLERY"
    return {
        active = state.status == "commanding" or state.status == "exposed",
        complete = state.status == "complete",
        displayName = "FOREMAN ECHO",
        enabled = state.status ~= "disabled",
        exposed = state.status == "exposed",
        health = state.health,
        instruction = instruction,
        leversThrown = thrown,
        leverTotal = #LEVER_IDS,
        marked = now < state.markedUntil,
        markedUntil = if now < state.markedUntil then state.markedUntil else 0,
        maxHealth = MAX_HEALTH,
        phase = math.min(3, state.seizeIndex + 1),
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        seizeIndex = state.seizeIndex,
        status = state.status,
    }
end

function ForemanEchoEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        ForemanEchoEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(ForemanEchoEncounter)
