--!strict

local BramblewakeBlackout = {}

export type Status =
    "disabled"
    | "dormant"
    | "relay"
    | "old_growth"
    | "warden"
    | "resolution"
    | "complete"

export type State = {
    carriers: { [string]: number },
    decision: string?,
    deliveredNodes: { [string]: boolean },
    duration: number,
    manifestHash: string,
    participants: { [string]: boolean },
    revision: number,
    runId: string,
    startedAt: number?,
    status: Status,
    targetEndsAt: number?,
    votes: { [string]: string },
    wardenOutcome: string?,
}

local RELAY_NODE_IDS = table.freeze({
    blackout_root_farm = true,
    blackout_root_mill = true,
    blackout_root_cathedral = true,
})
local RELAY_NODE_ORDER = table.freeze({
    "blackout_root_farm",
    "blackout_root_mill",
    "blackout_root_cathedral",
})
local RELAY_NODE_LABELS = table.freeze({
    blackout_root_farm = "FARM ROOT",
    blackout_root_mill = "MILL ROOT",
    blackout_root_cathedral = "CATHEDRAL ROOT",
})
local DECISION_IDS = table.freeze({
    restore_farmland = true,
    wild_regrowth = true,
    shared_agroforest = true,
})
local WARDEN_OUTCOMES = table.freeze({
    preserved = true,
    scarred = true,
    harmed = true,
})
local STAGE_INDEX = table.freeze({
    relay = 1,
    old_growth = 2,
    warden = 3,
    resolution = 4,
    complete = 4,
})
local STAGE_LABEL = table.freeze({
    relay = "ROOTFIRE RELAY",
    old_growth = "OLD GROWTH",
    warden = "WARDEN'S SEAL",
    resolution = "GREENWARD CHOICE",
    complete = "CHAPTER RESOLVED",
})

BramblewakeBlackout.Id = "blackout_bramblewake"
BramblewakeBlackout.RelayNodeIds = RELAY_NODE_IDS
BramblewakeBlackout.DecisionIds = DECISION_IDS
BramblewakeBlackout.FireCarrySeconds = 18
BramblewakeBlackout.StageCount = 4

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "Blackout participant ID is invalid")
    return tostring(userId)
end

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.carriers = table.clone(state.carriers)
    nextState.deliveredNodes = table.clone(state.deliveredNodes)
    nextState.participants = table.clone(state.participants)
    nextState.votes = table.clone(state.votes)
    return nextState
end

local function countTrue(values: { [string]: boolean }): number
    local count = 0
    for _, value in values do
        if value then
            count += 1
        end
    end
    return count
end

local function nextRelayNodeId(deliveredNodes: { [string]: boolean }): string?
    for _, nodeId in RELAY_NODE_ORDER do
        if deliveredNodes[nodeId] ~= true then
            return nodeId
        end
    end
    return nil
end

local function active(status: Status): boolean
    return status == "relay"
        or status == "old_growth"
        or status == "warden"
        or status == "resolution"
end

function BramblewakeBlackout.create(
    runId: string,
    manifestHash: string,
    enabled: boolean,
    duration: number
): State
    assert(runId ~= "", "Blackout run ID is required")
    assert(manifestHash ~= "", "Blackout manifest hash is required")
    assert(duration >= 60 and duration <= 30 * 60, "Blackout duration is invalid")
    return {
        carriers = {},
        decision = nil,
        deliveredNodes = {},
        duration = duration,
        manifestHash = manifestHash,
        participants = {},
        revision = 0,
        runId = runId,
        startedAt = nil,
        status = if enabled then "dormant" else "disabled",
        targetEndsAt = nil,
        votes = {},
        wardenOutcome = nil,
    }
end

function BramblewakeBlackout.start(state: State, userId: number, now: number): (State, any)
    if state.status ~= "dormant" then
        return state, {
            accepted = false,
            reason = state.status,
        }
    end
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState.startedAt = now
    nextState.status = "relay"
    nextState.targetEndsAt = now + nextState.duration
    nextState.revision += 1
    return nextState, {
        accepted = true,
        reason = "started",
    }
end

function BramblewakeBlackout.join(state: State, userId: number): State
    if not active(state.status) then
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

function BramblewakeBlackout.takeFire(state: State, userId: number, now: number): (State, any)
    if state.status ~= "relay" then
        return state, {
            accepted = false,
            reason = state.status,
        }
    end
    local key = participantKey(userId)
    local nextState = cloneState(state)
    nextState.carriers[key] = now + BramblewakeBlackout.FireCarrySeconds
    nextState.participants[key] = true
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            expiresAt = nextState.carriers[key],
            reason = "fire_taken",
        }
end

function BramblewakeBlackout.deliverFire(
    state: State,
    userId: number,
    nodeId: string,
    now: number
): (State, any)
    if state.status ~= "relay" then
        return state, {
            accepted = false,
            reason = state.status,
        }
    end
    if RELAY_NODE_IDS[nodeId] ~= true then
        return state,
            {
                accepted = false,
                reason = "invalid_relay_node",
            }
    end
    if state.deliveredNodes[nodeId] then
        return state,
            {
                accepted = false,
                reason = "already_delivered",
            }
    end
    local key = participantKey(userId)
    local expiresAt = state.carriers[key]
    if expiresAt == nil or now > expiresAt then
        return state,
            {
                accepted = false,
                reason = if expiresAt == nil then "fire_required" else "fire_expired",
            }
    end

    local nextState = cloneState(state)
    nextState.carriers[key] = nil
    nextState.deliveredNodes[nodeId] = true
    nextState.participants[key] = true
    local delivered = countTrue(nextState.deliveredNodes)
    if delivered >= 3 then
        nextState.status = "old_growth"
        table.clear(nextState.carriers)
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            delivered = delivered,
            reason = if nextState.status == "old_growth"
                then "relay_complete"
                else "fire_delivered",
            relayComplete = nextState.status == "old_growth",
            required = 3,
        }
end

function BramblewakeBlackout.completeOldGrowth(state: State): (State, any)
    if state.status ~= "old_growth" then
        return state, {
            accepted = false,
            reason = state.status,
        }
    end
    local nextState = cloneState(state)
    nextState.status = "warden"
    nextState.revision += 1
    return nextState, {
        accepted = true,
        reason = "old_growth_complete",
    }
end

function BramblewakeBlackout.completeWarden(state: State, outcome: string): (State, any)
    if state.status ~= "warden" then
        return state, {
            accepted = false,
            reason = state.status,
        }
    end
    if WARDEN_OUTCOMES[outcome] ~= true then
        return state,
            {
                accepted = false,
                reason = "invalid_warden_outcome",
            }
    end
    local nextState = cloneState(state)
    nextState.status = "resolution"
    nextState.wardenOutcome = outcome
    nextState.revision += 1
    return nextState, {
        accepted = true,
        reason = "warden_complete",
    }
end

local function resolveVote(votes: { [string]: string }, eligibleUserIds: { number }): string?
    local counts = {
        restore_farmland = 0,
        wild_regrowth = 0,
        shared_agroforest = 0,
    }
    local eligible = 0
    for _, userId in eligibleUserIds do
        local vote = votes[participantKey(userId)]
        if vote == nil then
            return nil
        end
        counts[vote] += 1
        eligible += 1
    end
    if eligible == 0 then
        return nil
    end
    local highest =
        math.max(counts.restore_farmland, counts.wild_regrowth, counts.shared_agroforest)
    local winner: string? = nil
    local winners = 0
    for _, decision in { "restore_farmland", "wild_regrowth", "shared_agroforest" } do
        if counts[decision] == highest then
            winner = decision
            winners += 1
        end
    end
    return if winners == 1 then winner else "shared_agroforest"
end

function BramblewakeBlackout.vote(
    state: State,
    userId: number,
    decision: string,
    eligibleUserIds: { number }
): (State, any)
    if state.status ~= "resolution" then
        return state, {
            accepted = false,
            reason = state.status,
        }
    end
    if DECISION_IDS[decision] ~= true then
        return state,
            {
                accepted = false,
                reason = "invalid_decision",
            }
    end
    local key = participantKey(userId)
    if state.participants[key] ~= true then
        return state,
            {
                accepted = false,
                reason = "not_participant",
            }
    end
    local eligible = false
    for _, eligibleUserId in eligibleUserIds do
        if eligibleUserId == userId then
            eligible = true
            break
        end
    end
    if not eligible then
        return state, {
            accepted = false,
            reason = "not_eligible",
        }
    end

    local nextState = cloneState(state)
    nextState.votes[key] = decision
    local resolved = resolveVote(nextState.votes, eligibleUserIds)
    if resolved ~= nil then
        nextState.decision = resolved
        nextState.status = "complete"
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            decision = resolved,
            reason = if resolved == nil then "vote_recorded" else "resolved",
            resolved = resolved ~= nil,
        }
end

function BramblewakeBlackout.reconcileVote(state: State, eligibleUserIds: { number }): (State, any)
    if state.status ~= "resolution" then
        return state,
            {
                accepted = false,
                reason = state.status,
                resolved = false,
            }
    end
    local resolved = resolveVote(state.votes, eligibleUserIds)
    if resolved == nil then
        return state,
            {
                accepted = true,
                reason = "vote_pending",
                resolved = false,
            }
    end
    local nextState = cloneState(state)
    nextState.decision = resolved
    nextState.status = "complete"
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            decision = resolved,
            reason = "resolved",
            resolved = true,
        }
end

function BramblewakeBlackout.snapshot(state: State, userId: number, now: number): any
    local key = tostring(userId)
    local startedAt = state.startedAt
    local targetEndsAt = state.targetEndsAt
    local elapsed = if startedAt == nil then 0 else math.max(0, now - startedAt)
    local remaining = if targetEndsAt == nil
        then state.duration
        else math.max(0, targetEndsAt - now)
    local fireExpiresAt = state.carriers[key]
    local carryingFire = fireExpiresAt ~= nil and now <= fireExpiresAt
    local delivered = countTrue(state.deliveredNodes)
    local nextNodeId = nextRelayNodeId(state.deliveredNodes)
    local instruction = if state.status == "relay"
        then if carryingFire
            then "DELIVER ROOTFIRE TO THE MARKED NEXT ROOT"
            else "TAKE ROOTFIRE FROM THE BLACKOUT LANTERN"
        elseif state.status == "old_growth" then "CLEANSE OLD GROWTH"
        elseif state.status == "warden" then "ANSWER THE WARDEN'S SEAL"
        elseif state.status == "resolution" then "CHOOSE THE GREENWARD'S FUTURE"
        elseif state.status == "complete" then "CHAPTER I RESOLVED"
        elseif state.status == "dormant" then "ENTER BRAMBLEWAKE TO BEGIN THE BLACKOUT"
        else "BRAMBLEWAKE BLACKOUT DISABLED"
    return {
        active = active(state.status),
        carryingFire = carryingFire,
        chapterComplete = state.status == "complete",
        decision = state.decision,
        deliveredNodes = delivered,
        -- The count above and this map answer different questions -- "how
        -- many are lit" for the HUD's N/3 rail, and "which ones" for the
        -- objective-marker resolver. TutorialService used to iterate the
        -- count and threw on every publish for the whole relay stage.
        deliveredNodeMap = table.clone(state.deliveredNodes),
        duration = state.duration,
        elapsed = elapsed,
        enabled = state.status ~= "disabled",
        fireExpiresAt = if carryingFire then fireExpiresAt else nil,
        instruction = instruction,
        nextNodeId = nextNodeId,
        nextNodeLabel = if nextNodeId == nil then nil else RELAY_NODE_LABELS[nextNodeId],
        overtime = targetEndsAt ~= nil and now > targetEndsAt,
        participant = state.participants[key] == true,
        relayRequired = 3,
        remaining = remaining,
        revision = state.revision,
        stage = STAGE_INDEX[state.status] or 0,
        stageCount = BramblewakeBlackout.StageCount,
        stageLabel = STAGE_LABEL[state.status] or "BLACKOUT",
        status = state.status,
        targetEndsAt = targetEndsAt,
        vote = state.votes[key],
        wardenOutcome = state.wardenOutcome,
    }
end

function BramblewakeBlackout.chapterTransactionId(state: State, userId: number): string
    return string.format("chapter_1:%s:%s:%d", state.runId, state.manifestHash, userId)
end

return table.freeze(BramblewakeBlackout)
