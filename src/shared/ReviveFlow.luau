--!strict

local ReviveFlow = {}

export type Channel = {
    endsAt: number,
    reviverRevision: number,
    reviverUserId: number,
    startedAt: number,
    targetUserId: number,
}
export type Conditions = {
    reachable: boolean,
    reviverCanAct: boolean,
    reviverPresent: boolean,
    reviverRevision: number,
    targetDowned: boolean,
    targetPresent: boolean,
}
export type DecisionStatus = "cancel" | "complete" | "pending"
export type Decision = {
    elapsed: number?,
    reason: string?,
    remaining: number?,
    status: DecisionStatus,
}

local function finiteNumber(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function wholeNonNegative(value: any): boolean
    return finiteNumber(value) and value >= 0 and value == math.floor(value)
end

function ReviveFlow.create(
    targetUserId: number,
    reviverUserId: number,
    reviverRevision: number,
    now: number,
    duration: number
): Channel
    assert(wholeNonNegative(targetUserId), "target user ID is invalid")
    assert(wholeNonNegative(reviverUserId), "reviver user ID is invalid")
    assert(targetUserId ~= reviverUserId, "players cannot revive themselves")
    assert(wholeNonNegative(reviverRevision), "reviver revision is invalid")
    assert(finiteNumber(now), "revive start time is invalid")
    assert(finiteNumber(duration) and duration > 0, "revive duration is invalid")

    return table.freeze({
        endsAt = now + duration,
        reviverRevision = reviverRevision,
        reviverUserId = reviverUserId,
        startedAt = now,
        targetUserId = targetUserId,
    })
end

function ReviveFlow.evaluate(channel: Channel, now: number, conditions: Conditions): Decision
    assert(finiteNumber(now), "revive evaluation time is invalid")
    if conditions.targetPresent ~= true then
        return {
            reason = "target_left",
            status = "cancel",
        }
    end
    if conditions.reviverPresent ~= true then
        return {
            reason = "reviver_left",
            status = "cancel",
        }
    end
    if conditions.targetDowned ~= true then
        return {
            reason = "target_not_downed",
            status = "cancel",
        }
    end
    if conditions.reviverCanAct ~= true then
        return {
            reason = "reviver_cannot_act",
            status = "cancel",
        }
    end
    if conditions.reviverRevision ~= channel.reviverRevision then
        return {
            reason = "reviver_state_changed",
            status = "cancel",
        }
    end
    if conditions.reachable ~= true then
        return {
            reason = "revive_out_of_range",
            status = "cancel",
        }
    end
    if now >= channel.endsAt then
        return {
            elapsed = math.max(0, now - channel.startedAt),
            status = "complete",
        }
    end
    return {
        remaining = math.max(0, channel.endsAt - now),
        status = "pending",
    }
end

return table.freeze(ReviveFlow)
