--!strict

local Strings = require("./Strings")

local WardenStagEncounter = {}

export type Status = "disabled" | "locked" | "dormant" | "cleansing" | "vulnerable" | "complete"

export type State = {
    antlersBroken: number,
    brokenAntlers: { [string]: boolean },
    cleansedNodes: { [string]: boolean },
    health: number,
    manifestHash: string,
    outcome: string?,
    participants: { [string]: boolean },
    phase: number,
    phaseAntlerBroken: boolean,
    revision: number,
    runId: string,
    status: Status,
}

local MAX_HEALTH = 480
local PHASE_THRESHOLDS = table.freeze({ 320, 160, 0 })
local ROOTS_REQUIRED = table.freeze({ 2, 3, 4 })
local ROOT_NODE_IDS = table.freeze({
    root_node_north = true,
    root_node_east = true,
    root_node_south = true,
    root_node_west = true,
})
local ANTLER_IDS = table.freeze({
    antler_left = true,
    antler_right = true,
})

local ROOTBOUND_CHARGE = table.freeze({
    attackId = "warden_stag_rootbound_charge",
    attackName = Strings.get("encounter.rootbound_charge"),
    damage = 24,
    instruction = Strings.get("encounter.clear_the_charge_lane"),
    length = 42,
    rootedDuration = 1.2,
    rootedMultiplier = 0.45,
    shape = "lane",
    width = 11,
    windup = 1.55,
})

local ANTLER_ARC = table.freeze({
    attackId = "warden_stag_antler_arc",
    attackName = Strings.get("encounter.antler_arc"),
    damage = 28,
    instruction = Strings.get("encounter.leave_the_antler_ring"),
    radius = 11,
    shape = "circle",
    windup = 1.7,
})

local MEMORY_STAMPEDE = table.freeze({
    attackId = "warden_stag_memory_stampede",
    attackName = Strings.get("encounter.memory_stampede"),
    damage = 32,
    instruction = Strings.get("encounter.cross_out_of_the_memory_lane"),
    length = 48,
    rootedDuration = 1.5,
    rootedMultiplier = 0.38,
    shape = "lane",
    width = 14,
    windup = 1.9,
})

WardenStagEncounter.Id = "boss_warden_stag"
WardenStagEncounter.MaxHealth = MAX_HEALTH
WardenStagEncounter.RootNodeIds = ROOT_NODE_IDS
WardenStagEncounter.AntlerIds = ANTLER_IDS
WardenStagEncounter.Reward = table.freeze({
    amount = 5,
    materialId = "material_amber_sap",
})
WardenStagEncounter.Tuning = table.freeze({
    attackCooldownSeconds = 3.5,
    cleansingAttackCooldownSeconds = 4.4,
    markedAttackCooldownMultiplier = 1.35,
    markedStrikeDamage = 46,
    strikeDamage = 40,
})

local function participantKey(userId: number): string
    assert(userId > 0 and userId == math.floor(userId), "boss participant user ID is invalid")
    return tostring(userId)
end

local function cloneState(state: State): State
    local nextState = table.clone(state)
    nextState.brokenAntlers = table.clone(state.brokenAntlers)
    nextState.cleansedNodes = table.clone(state.cleansedNodes)
    nextState.participants = table.clone(state.participants)
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
    return status == "cleansing" or status == "vulnerable"
end

function WardenStagEncounter.create(runId: string, manifestHash: string, enabled: boolean): State
    assert(runId ~= "", "Warden Stag run ID is required")
    assert(manifestHash ~= "", "Warden Stag manifest hash is required")
    return {
        antlersBroken = 0,
        brokenAntlers = {},
        cleansedNodes = {},
        health = MAX_HEALTH,
        manifestHash = manifestHash,
        outcome = nil,
        participants = {},
        phase = 1,
        phaseAntlerBroken = false,
        revision = 0,
        runId = runId,
        status = if enabled then "locked" else "disabled",
    }
end

function WardenStagEncounter.unlock(state: State): (State, any)
    if state.status ~= "locked" then
        return state, {
            accepted = false,
            reason = state.status,
        }
    end
    local nextState = cloneState(state)
    nextState.status = "dormant"
    nextState.revision += 1
    return nextState, {
        accepted = true,
        reason = "unlocked",
    }
end

function WardenStagEncounter.activate(state: State, userId: number): (State, any)
    if state.status ~= "dormant" then
        return state, {
            accepted = false,
            reason = state.status,
        }
    end
    local nextState = cloneState(state)
    nextState.participants[participantKey(userId)] = true
    nextState.status = "cleansing"
    nextState.revision += 1
    return nextState, {
        accepted = true,
        reason = "activated",
    }
end

function WardenStagEncounter.join(state: State, userId: number): State
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

function WardenStagEncounter.cleanseRoot(state: State, userId: number, nodeId: string): (State, any)
    if state.status ~= "cleansing" then
        return state, {
            accepted = false,
            reason = state.status,
        }
    end
    if ROOT_NODE_IDS[nodeId] ~= true then
        return state,
            {
                accepted = false,
                reason = "invalid_root_node",
            }
    end
    if state.cleansedNodes[nodeId] then
        return state,
            {
                accepted = false,
                reason = "already_cleansed",
            }
    end

    local nextState = cloneState(state)
    nextState.cleansedNodes[nodeId] = true
    nextState.participants[participantKey(userId)] = true
    local cleansed = countKeys(nextState.cleansedNodes)
    local required = ROOTS_REQUIRED[nextState.phase]
    local exposed = cleansed >= required
    if exposed then
        nextState.status = "vulnerable"
    end
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            cleansed = cleansed,
            exposed = exposed,
            reason = if exposed then "heart_exposed" else "root_cleansed",
            required = required,
        }
end

function WardenStagEncounter.breakAntler(
    state: State,
    userId: number,
    antlerId: string
): (State, any)
    if state.status ~= "cleansing" then
        return state, {
            accepted = false,
            reason = state.status,
        }
    end
    if ANTLER_IDS[antlerId] ~= true then
        return state,
            {
                accepted = false,
                reason = "invalid_antler",
            }
    end
    if state.phaseAntlerBroken then
        return state,
            {
                accepted = false,
                reason = "phase_antler_already_broken",
            }
    end
    if state.brokenAntlers[antlerId] then
        return state,
            {
                accepted = false,
                reason = "antler_already_broken",
            }
    end

    local nextState = cloneState(state)
    nextState.brokenAntlers[antlerId] = true
    nextState.antlersBroken += 1
    nextState.phaseAntlerBroken = true
    nextState.participants[participantKey(userId)] = true
    nextState.status = "vulnerable"
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            antlersBroken = nextState.antlersBroken,
            exposed = true,
            reason = "antler_broken",
        }
end

function WardenStagEncounter.strike(state: State, userId: number, amount: number): (State, any)
    assert(amount > 0 and amount <= 100, "Warden Stag strike amount is invalid")
    if state.status ~= "vulnerable" then
        return state, {
            accepted = false,
            reason = state.status,
        }
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
            nextState.outcome = if nextState.antlersBroken == 0
                then "preserved"
                elseif nextState.antlersBroken >= 2 then "harmed"
                else "scarred"
        else
            nextState.phase += 1
            nextState.phaseAntlerBroken = false
            nextState.cleansedNodes = {}
            nextState.status = "cleansing"
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

function WardenStagEncounter.attack(attackIndex: number, phase: number): any
    if phase >= 3 then
        return if attackIndex % 2 == 0 then ANTLER_ARC else MEMORY_STAMPEDE
    elseif phase == 2 and attackIndex % 2 == 0 then
        return ANTLER_ARC
    end
    return ROOTBOUND_CHARGE
end

function WardenStagEncounter.snapshot(state: State, userId: number): any
    local cleansed = countKeys(state.cleansedNodes)
    local required = ROOTS_REQUIRED[state.phase] or ROOTS_REQUIRED[#ROOTS_REQUIRED]
    local instruction = if state.status == "cleansing"
        then string.format(
            Strings.get("encounter.cleanse_living_roots_n_n_breaking"),
            cleansed,
            required
        )
        elseif state.status == "vulnerable" then Strings.get(
            "hud.heart_exposed_strike_the_memory_seal"
        )
        elseif state.status == "complete" then if state.outcome == "preserved"
            then Strings.get("encounter.warden_stag_calmed_forest_ally_preserved")
            elseif state.outcome == "harmed" then Strings.get(
                "encounter.warden_stag_defeated_forest_harmed"
            )
            else Strings.get("encounter.warden_stag_defeated_forest_scarred")
        elseif state.status == "dormant" then Strings.get("encounter.enter_the_warden_s_seal")
        elseif state.status == "locked" then Strings.get(
            "encounter.cleanse_old_growth_to_open_the"
        )
        elseif state.status == "disabled" then Strings.get(
            "encounter.warden_stag_temporarily_dormant"
        )
        else Strings.get("hud.warden_stag")
    return {
        active = isActive(state.status),
        antlersBroken = state.antlersBroken,
        choiceAvailable = state.status == "cleansing" and state.antlersBroken < 2,
        cleansedNodes = cleansed,
        complete = state.status == "complete",
        displayName = Strings.get("hud.warden_stag"),
        enabled = state.status ~= "disabled",
        exposed = state.status == "vulnerable",
        health = state.health,
        instruction = instruction,
        maxHealth = MAX_HEALTH,
        outcome = state.outcome,
        phase = state.phase,
        rewardEligible = state.participants[tostring(userId)] == true,
        revision = state.revision,
        rootNodesRequired = required,
        status = state.status,
    }
end

function WardenStagEncounter.rewardTransactionId(state: State, userId: number): string
    return string.format(
        "%s:%s:%s:%d",
        WardenStagEncounter.Id,
        state.runId,
        state.manifestHash,
        userId
    )
end

return table.freeze(WardenStagEncounter)
