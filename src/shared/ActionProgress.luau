--!strict

--[[
    Timed world actions: gathering, building, and anything else that should
    take a beat and show it.

    Pure logic. The service layer owns characters, animation, and the clock;
    everything about whether an action may start, how far along it is, and
    whether it may complete lives here so it can be tested and so a client can
    never award itself the result early.

    The rules:

      * One action at a time per player. A second request while one is running
        is refused rather than queued, so spamming an object cannot stack
        rewards.
      * Completion is time-based and checked server-side. A client asking to
        complete early is refused; the action finishes when the clock says so.
      * Moving away, taking damage, or dying cancels. A cancelled action grants
        nothing -- it is not a partial payout.
      * Completion is consumed. The state is cleared the moment it pays out, so
        a duplicated remote or a retried tick cannot grant twice.
]]

local ActionProgress = {}

export type State = {
    actionId: string,
    interactionId: string,
    startedAt: number,
    endsAt: number,
    swings: number,
}

export type Snapshot = {
    active: boolean,
    actionId: string,
    label: string,
    alpha: number,
    swings: number,
}

-- Deliberately short. This is feedback that an action happened, not a tax on
-- the player's time; the visual standard asks for physical confirmation, not
-- for waiting.
local DURATIONS = table.freeze({
    gather = 1.4,
    build = 1.8,
})

local LABELS = table.freeze({
    gather = "GATHERING",
    build = "BUILDING",
})

local SWINGS = table.freeze({
    gather = 2,
    build = 3,
})

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function ActionProgress.durationFor(actionId: any): number?
    return if type(actionId) == "string" then DURATIONS[actionId] else nil
end

function ActionProgress.labelFor(actionId: any): string
    return (if type(actionId) == "string" then LABELS[actionId] else nil) or "WORKING"
end

function ActionProgress.swingsFor(actionId: any): number
    return (if type(actionId) == "string" then SWINGS[actionId] else nil) or 1
end

function ActionProgress.idle(): State?
    return nil
end

--[[
    Begin a timed action.

    Returns the running state and a result. An action id with no configured
    duration is refused rather than silently treated as instant, so adding a
    new timed action cannot accidentally ship without a duration.
]]
function ActionProgress.begin(
    state: State?,
    actionId: any,
    interactionId: any,
    now: any
): (State?, any)
    if not finite(now) or now < 0 then
        return state, { accepted = false, reason = "invalid_time" }
    end
    if type(interactionId) ~= "string" or #interactionId == 0 or #interactionId > 64 then
        return state, { accepted = false, reason = "invalid_interaction" }
    end
    local duration = ActionProgress.durationFor(actionId)
    if duration == nil then
        return state, { accepted = false, reason = "untimed_action" }
    end
    if state ~= nil and now < state.endsAt then
        return state, { accepted = false, reason = "already_working" }
    end

    return {
        actionId = actionId :: string,
        interactionId = interactionId,
        startedAt = now,
        endsAt = now + duration,
        swings = ActionProgress.swingsFor(actionId),
    }, {
        accepted = true,
        duration = duration,
        swings = ActionProgress.swingsFor(actionId),
        label = ActionProgress.labelFor(actionId),
    }
end

--[[
    Advance the action.

    `complete` is true exactly once, on the first tick at or after the end
    time, and the state is consumed so it can never pay out twice.
]]
function ActionProgress.tick(state: State?, now: any): (State?, any)
    if state == nil then
        return nil, { complete = false, reason = "idle" }
    end
    if not finite(now) then
        return state, { complete = false, reason = "invalid_time" }
    end
    if now < state.endsAt then
        return state, { complete = false, reason = "working" }
    end
    return nil,
        {
            complete = true,
            actionId = state.actionId,
            interactionId = state.interactionId,
        }
end

function ActionProgress.cancel(_state: State?): State?
    return nil
end

function ActionProgress.snapshot(state: State?, now: any): Snapshot
    if state == nil or not finite(now) then
        return { active = false, actionId = "", label = "", alpha = 0, swings = 0 }
    end
    local span = state.endsAt - state.startedAt
    local alpha = if span <= 0 then 1 else (now - state.startedAt) / span
    return {
        active = now < state.endsAt,
        actionId = state.actionId,
        label = ActionProgress.labelFor(state.actionId),
        alpha = math.clamp(alpha, 0, 1),
        swings = state.swings,
    }
end

return table.freeze(ActionProgress)
