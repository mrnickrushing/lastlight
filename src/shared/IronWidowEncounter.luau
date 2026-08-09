--!strict

--[[
    The Iron Widow -- the Delve's second elite.

    She does not hold ground; she owns the rails. A web of cut cable spans
    the stope, and while an anchor still holds she sends loaded carts down
    the lines on an ambush cadence -- the longer an anchor survives, the
    faster they come. Cutting an anchor is the whole fight: each one taken
    slows the ambush and drops her out of the web for a while, and only
    with the web fully cut does she come down to be finished.

    Where the Foreman Echo is about authority (shut it off in the right
    order), the Widow is about tempo (spend your window well). Her
    vulnerability is not a state you unlock once but a window you keep
    re-earning, and her pressure scales down as you take the web apart, so
    a solo player who is slow still converges rather than drowning.

    Same contract as every elite here: profession-independent, solo
    passable, one reward per participant per run through a deterministic
    transaction id, disable-able, server-called throughout.
]]

local Strings = require("./Strings")

local IronWidowEncounter = {}

export type Status = "disabled" | "dormant" | "webbed" | "grounded" | "complete"

export type State = {
    anchors: { [string]: boolean },
    groundedUntil: number,
    health: number,
    manifestHash: string,
    participants: { [string]: boolean },
    revision: number,
    runId: string,
    status: Status,
}

local MAX_HEALTH = 300
local ANCHOR_IDS = table.freeze({
    "anchor_head",
    "anchor_spur",
    "anchor_tail",
    "anchor_crown",
})
-- Cutting an anchor drops her out of the web for this long. It is the
-- only window in which she can be struck while the web still stands.
local GROUNDED_SECONDS = 9

local CART_AMBUSH = table.freeze({
    attackId = "iron_widow_cart",
    attackName = Strings.get("encounter.cart_ambush"),
    damage = 24,
    instruction = Strings.get("encounter.off_the_line_a_cart_is"),
    length = 34,
    shape = "lane",
    width = 7,
    windup = 1.15,
})

local CABLE_SWEEP = table.freeze({
    attackId = "iron_widow_sweep",
    attackName = Strings.get("encounter.cable_sweep"),
    damage = 20,
    instruction = Strings.get("encounter.duck_the_sweeping_cable"),
    radius = 12,
    shape = "circle",
    windup = 1.3,
})

IronWidowEncounter.Id = "elite_iron_widow"
IronWidowEncounter.MaxHealth = MAX_HEALTH
IronWidowEncounter.AnchorIds = ANCHOR_IDS
IronWidowEncounter.GroundedSeconds = GROUNDED_SECONDS
IronWidowEncounter.Reward = table.freeze({
    amount = 3,
    materialId = "material_coalglass",
})
IronWidowEncounter.Tuning = table.freeze({
    baseAmbushCooldownSeconds = 3.6,
    -- Each anchor cut adds this much breathing room between ambushes.
    anchorCooldownBonusSeconds = 0.7,
    groundedAttackCooldownSeconds = 5,
    strikeDamage = 34,
})

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.anchors = table.clone(state.anchors)
    nextState.participants = table.clone(state.participants)
    return nextState
end

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "participant user ID is invalid")
    return tostring(userId)
end

local function isAnchor(anchorId: any): boolean
    for _, id in ANCHOR_IDS do
        if id == anchorId then
            return true
        end
    end
    return false
end

local function anchorsCut(state: State): number
    local count = 0
    for _, id in ANCHOR_IDS do
        if state.anchors[id] then
            count += 1
        end
    end
    return count
end

function IronWidowEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Iron Widow run ID is required")
    assert(manifestHash ~= "", "Iron Widow manifest hash is required")
    return {
        anchors = {},
        groundedUntil = 0,
        health = MAX_HEALTH,
        manifestHash = manifestHash,
        participants = {},
        revision = 0,
        runId = runId,
        status = if enabled then "dormant" else "disabled",
    }
end

function IronWidowEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, { accepted = false, reason = state.status }
    end
    local nextState = cloneState(state)
    nextState.status = "webbed"
    nextState.participants[participantKey(userId)] = true
    nextState.revision += 1
    return nextState, { accepted = true, activated = true, reason = "activated" }
end

function IronWidowEncounter.join(state: State, userId: number): State
    if state.status ~= "webbed" and state.status ~= "grounded" then
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
    Cut one web anchor. Anchors stay cut -- progress never unwinds -- and
    each cut both slows the ambush cadence and drops her into the open.
    With the last anchor gone she stays down: the web is what held her up.
]]
function IronWidowEncounter.cutAnchor(
    state: State,
    userId: number,
    anchorId: any,
    now: number
): (State, any)
    if state.status ~= "webbed" and state.status ~= "grounded" then
        return state, { accepted = false, reason = state.status }
    end
    if not isAnchor(anchorId) then
        return state, { accepted = false, reason = "unknown_anchor" }
    end
    if state.anchors[anchorId] then
        return state, { accepted = false, reason = "already_cut" }
    end
    local nextState = cloneState(state)
    nextState.anchors[anchorId] = true
    nextState.participants[participantKey(userId)] = true
    local cut = anchorsCut(nextState)
    local webDown = cut >= #ANCHOR_IDS
    nextState.status = "grounded"
    nextState.groundedUntil = if webDown then math.huge else now + GROUNDED_SECONDS
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            cut = cut,
            groundedUntil = nextState.groundedUntil,
            reason = if webDown then "web_down" else "anchor_cut",
            remaining = #ANCHOR_IDS - cut,
            webDown = webDown,
        }
end

function IronWidowEncounter.strike(state: State, userId: number, amount: number): (State, any)
    assert(amount > 0 and amount <= 100, "Iron Widow strike amount is invalid")
    if state.status ~= "grounded" then
        return state, { accepted = false, reason = state.status }
    end

    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState.health = math.max(0, state.health - amount)
    if nextState.health <= 0 then
        nextState.status = "complete"
        nextState.groundedUntil = 0
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            completed = nextState.status == "complete",
            damage = state.health - nextState.health,
            health = nextState.health,
            reason = if nextState.status == "complete" then "completed" else "damaged",
        }
end

-- She climbs back into the web when her window closes -- unless the web
-- is fully cut, in which case there is nothing left to climb.
function IronWidowEncounter.expire(state: State, now: number): State
    if state.status ~= "grounded" or now < state.groundedUntil then
        return state
    end
    local nextState = cloneState(state)
    nextState.status = "webbed"
    nextState.groundedUntil = 0
    nextState.revision += 1
    return nextState
end

-- Ambush cadence eases with every anchor taken: the fight gets calmer as
-- it gets closer, so a slow solo run converges instead of drowning.
function IronWidowEncounter.ambushCooldown(state: State): number
    local tuning = IronWidowEncounter.Tuning
    if state.status == "grounded" then
        return tuning.groundedAttackCooldownSeconds
    end
    return tuning.baseAmbushCooldownSeconds + anchorsCut(state) * tuning.anchorCooldownBonusSeconds
end

function IronWidowEncounter.attack(attackIndex: number, cutCount: number): any
    -- With half the web gone she can no longer keep carts running on
    -- every line, and falls back to sweeping cable.
    if cutCount >= 2 and attackIndex % 2 == 0 then
        return CABLE_SWEEP
    end
    return CART_AMBUSH
end

function IronWidowEncounter.snapshot(state: State, userId: number, now: number): any
    local cut = anchorsCut(state)
    local grounded = state.status == "grounded" and now < state.groundedUntil
    local instruction = if state.status == "webbed"
        then string.format(Strings.get("encounter.cut_the_web_anchors_n_of"), cut, #ANCHOR_IDS)
        elseif state.status == "grounded" then Strings.get(
            "encounter.strike_her_while_she_is_down"
        )
        elseif state.status == "complete" then Strings.get("encounter.the_rails_are_quiet")
        elseif state.status == "disabled" then Strings.get(
            "encounter.elite_temporarily_dormant"
        )
        else Strings.get("encounter.enter_the_flooded_stope")
    return {
        active = state.status == "webbed" or state.status == "grounded",
        anchorsCut = cut,
        anchorTotal = #ANCHOR_IDS,
        complete = state.status == "complete",
        displayName = Strings.get("encounter.iron_widow"),
        enabled = state.status ~= "disabled",
        grounded = grounded,
        groundedUntil = if grounded and state.groundedUntil ~= math.huge
            then state.groundedUntil
            else 0,
        health = state.health,
        instruction = instruction,
        maxHealth = MAX_HEALTH,
        phase = math.min(3, math.floor(cut / 2) + 1),
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        status = state.status,
        webDown = cut >= #ANCHOR_IDS,
    }
end

function IronWidowEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        IronWidowEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(IronWidowEncounter)
