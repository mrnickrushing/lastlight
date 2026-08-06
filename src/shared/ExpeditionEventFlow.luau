--!strict

local ExpeditionEventFlow = {}

local INTERACTION_PREFIX = "exp_event:"

local function findStep(definition: any, stepId: string): any?
    for _, step in definition.steps do
        if step.id == stepId then
            return step
        end
    end
    return nil
end

local function participantList(participants: { [string]: boolean }): { string }
    local result = {}
    for participantId in participants do
        table.insert(result, participantId)
    end
    table.sort(result)
    return result
end

function ExpeditionEventFlow.validateDefinition(definition: any): (boolean, { string })
    local issues = {}
    local function issue(message: string)
        table.insert(issues, message)
    end

    if type(definition) ~= "table" then
        return false, { "event definition must be a table" }
    end
    --[[
        Every region owns a two-letter event namespace (bw, ir, ...). The
        rule is still that an event id names its region -- it just no
        longer names one region in particular, now that the generator
        composes more than one.
    ]]
    if type(definition.id) ~= "string" or string.match(definition.id, "^event_%l%l_%l") == nil then
        issue("event ID must use a regional event namespace")
    end
    if type(definition.displayName) ~= "string" or definition.displayName == "" then
        issue("event must have a display name")
    end
    if type(definition.objective) ~= "string" or definition.objective == "" then
        issue("event must have an objective")
    end
    if type(definition.detail) ~= "string" or definition.detail == "" then
        issue("event must have player guidance")
    end
    if
        type(definition.durationSeconds) ~= "number"
        or definition.durationSeconds < 30
        or definition.durationSeconds > 300
    then
        issue("event duration must be between 30 and 300 seconds")
    end
    if definition.defaultSolution ~= true then
        issue("event must have a profession-independent solution")
    end
    if definition.criticalPathBlocking ~= false then
        issue("event must not block the expedition critical path")
    end
    if
        type(definition.minimumRouteSpace) ~= "number"
        or definition.minimumRouteSpace < 8
        or definition.minimumRouteSpace > 48
    then
        issue("event route-space requirement is invalid")
    end
    if type(definition.startConditions) ~= "table" or #definition.startConditions == 0 then
        issue("event must declare start conditions")
    end
    if type(definition.incompatibleEvents) ~= "table" then
        issue("event must declare incompatible events")
    end
    if type(definition.failureResolution) ~= "string" or definition.failureResolution == "" then
        issue("event must declare a safe failure resolution")
    end
    if type(definition.localizationKey) ~= "string" or definition.localizationKey == "" then
        issue("event must declare a localization key")
    end
    if type(definition.analyticsId) ~= "string" or definition.analyticsId == "" then
        issue("event must declare an analytics ID")
    end
    if type(definition.killSwitchFlag) ~= "string" or definition.killSwitchFlag == "" then
        issue("event must declare a kill-switch flag")
    end
    -- Both variants are required. An event that reads clearly alone can be
    -- opaque in a group and the reverse, and an unauthored variant is
    -- indistinguishable at runtime from one that was never surfaced.
    for _, variant in { "soloVariant", "groupVariant" } do
        local authored = (definition :: any)[variant]
        if
            type(authored) ~= "table"
            or type(authored.guidance) ~= "string"
            or authored.guidance == ""
        then
            issue("event must declare " .. variant .. " guidance")
        end
    end

    local steps = definition.steps
    if type(steps) ~= "table" or #steps < 2 or #steps > 6 then
        issue("event must contain between two and six interaction steps")
    else
        local seenSteps: { [string]: boolean } = {}
        for _, step in steps do
            if type(step.id) ~= "string" or step.id == "" then
                issue("event step must have an ID")
            elseif seenSteps[step.id] then
                issue("event step IDs must be unique")
            else
                seenSteps[step.id] = true
            end
            if type(step.actionText) ~= "string" or step.actionText == "" then
                issue("event step must have action text")
            end
            if type(step.objectText) ~= "string" or step.objectText == "" then
                issue("event step must have object text")
            end
            local offset = step.offset
            if
                type(offset) ~= "table"
                or type(offset.x) ~= "number"
                or type(offset.y) ~= "number"
                or type(offset.z) ~= "number"
            then
                issue("event step must have a numeric world offset")
            end
        end
    end

    local reward = definition.reward
    if
        type(reward) ~= "table"
        or type(reward.materialId) ~= "string"
        or string.sub(reward.materialId, 1, 9) ~= "material_"
        or type(reward.amount) ~= "number"
        or reward.amount < 1
        or reward.amount ~= math.floor(reward.amount)
    then
        issue("event must declare a positive whole-material reward")
    end

    return #issues == 0, issues
end

function ExpeditionEventFlow.interactionId(eventId: string, stepId: string): string
    return INTERACTION_PREFIX .. eventId .. ":" .. stepId
end

function ExpeditionEventFlow.transactionId(
    runId: string,
    manifestHash: string,
    eventId: string
): string
    return string.format("event_reward:%s:%s:%s", runId, manifestHash, eventId)
end

function ExpeditionEventFlow.create(
    definition: any,
    runId: string,
    manifestHash: string,
    enabled: boolean?
): any
    local valid, issues = ExpeditionEventFlow.validateDefinition(definition)
    assert(valid, table.concat(issues, "; "))
    assert(type(runId) == "string" and runId ~= "", "expedition run ID is required")
    assert(type(manifestHash) == "string" and manifestHash ~= "", "manifest hash is required")

    local isEnabled = enabled ~= false and definition.enabled == true
    return {
        eventId = definition.id,
        runId = runId,
        manifestHash = manifestHash,
        status = if isEnabled then "dormant" else "disabled",
        progress = 0,
        total = #definition.steps,
        revision = 0,
        startedAt = nil,
        expiresAt = nil,
        completedAt = nil,
        failedAt = nil,
        completedSteps = {},
        participants = {},
        rewardTransactionId = nil,
    }
end

function ExpeditionEventFlow.expire(state: any, _definition: any, now: number): boolean
    if state.status ~= "active" or type(state.expiresAt) ~= "number" or now < state.expiresAt then
        return false
    end

    state.status = "failed"
    state.failedAt = now
    state.revision += 1
    return true
end

function ExpeditionEventFlow.contribute(
    state: any,
    definition: any,
    stepId: string,
    participantId: string,
    now: number
): any
    if state.eventId ~= definition.id then
        return {
            accepted = false,
            changed = false,
            reason = "event_mismatch",
        }
    end
    if state.status == "disabled" then
        return {
            accepted = false,
            changed = false,
            reason = "event_disabled",
        }
    end
    if findStep(definition, stepId) == nil then
        return {
            accepted = false,
            changed = false,
            reason = "unknown_step",
        }
    end
    if ExpeditionEventFlow.expire(state, definition, now) then
        return {
            accepted = false,
            changed = true,
            failed = true,
            reason = "event_expired",
        }
    end
    if state.status == "failed" then
        return {
            accepted = false,
            changed = false,
            reason = "event_failed",
        }
    end
    if state.completedSteps[stepId] == true then
        return {
            accepted = true,
            changed = false,
            duplicate = true,
            reason = "step_already_complete",
        }
    end
    if state.status == "completed" then
        return {
            accepted = true,
            changed = false,
            duplicate = true,
            reason = "event_already_complete",
        }
    end

    local started = false
    if state.status == "dormant" then
        state.status = "active"
        state.startedAt = now
        state.expiresAt = now + definition.durationSeconds
        started = true
    end

    state.completedSteps[stepId] = true
    state.participants[participantId] = true
    state.progress += 1
    state.revision += 1

    local completed = state.progress == state.total
    if completed then
        state.status = "completed"
        state.completedAt = now
        state.rewardTransactionId =
            ExpeditionEventFlow.transactionId(state.runId, state.manifestHash, state.eventId)
    end

    return {
        accepted = true,
        changed = true,
        completed = completed,
        started = started,
        progress = state.progress,
        total = state.total,
        rewardTransactionId = state.rewardTransactionId,
    }
end

--[[
    Which guidance a party should be reading.

    Group advice is chosen the moment a second player is working the event,
    because that is exactly when advice like "split up and turn separate
    latches" becomes possible to act on -- telling a lone player to split up
    is worse than telling them nothing. Before anyone has engaged, the solo
    line is the safe default: it describes the event rather than the party.
]]
function ExpeditionEventFlow.guidanceFor(definition: any, participantCount: any): string?
    local isGroup = type(participantCount) == "number"
        and participantCount == participantCount
        and participantCount >= 2
        and participantCount == math.floor(participantCount)
    local variant = if isGroup then definition.groupVariant else definition.soloVariant
    if type(variant) ~= "table" or type(variant.guidance) ~= "string" or variant.guidance == "" then
        return nil
    end
    return variant.guidance
end

function ExpeditionEventFlow.snapshot(state: any, definition: any, now: number): any
    local timeRemaining = nil
    if state.status == "active" and type(state.expiresAt) == "number" then
        timeRemaining = math.max(0, math.ceil(state.expiresAt - now))
    end

    local participants = participantList(state.participants)
    return {
        eventId = state.eventId,
        displayName = definition.displayName,
        status = state.status,
        objective = definition.objective,
        detail = definition.detail,
        completionMessage = definition.completionMessage,
        failureMessage = definition.failureMessage,
        failureResolution = definition.failureResolution,
        progress = state.progress,
        total = state.total,
        revision = state.revision,
        timeRemaining = timeRemaining,
        reward = definition.reward,
        rewardTransactionId = state.rewardTransactionId,
        participants = participants,
        guidance = ExpeditionEventFlow.guidanceFor(definition, #participants),
    }
end

return table.freeze(ExpeditionEventFlow)
