--!strict

local EnemyAttackFlow = {}

export type Channel = {
    endsAt: number,
    startedAt: number,
    targetUserId: number,
}
export type Conditions = {
    clearPath: boolean,
    inImpactArea: boolean,
    targetCanAct: boolean,
    targetPresent: boolean,
}
export type DecisionStatus = "cancel" | "miss" | "pending" | "resolve"
export type Decision = {
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

function EnemyAttackFlow.create(targetUserId: number, now: number, windup: number): Channel
    assert(wholeNonNegative(targetUserId), "attack target user ID is invalid")
    assert(finiteNumber(now), "attack start time is invalid")
    assert(finiteNumber(windup) and windup > 0, "attack windup is invalid")
    return table.freeze({
        endsAt = now + windup,
        startedAt = now,
        targetUserId = targetUserId,
    })
end

function EnemyAttackFlow.evaluate(channel: Channel, now: number, conditions: Conditions): Decision
    assert(finiteNumber(now), "attack evaluation time is invalid")
    if conditions.targetPresent ~= true then
        return {
            reason = "target_left",
            status = "cancel",
        }
    end
    if conditions.targetCanAct ~= true then
        return {
            reason = "target_cannot_act",
            status = "cancel",
        }
    end
    if now < channel.endsAt then
        return {
            remaining = channel.endsAt - now,
            status = "pending",
        }
    end
    if conditions.inImpactArea ~= true then
        return {
            reason = "target_evaded_area",
            status = "miss",
        }
    end
    if conditions.clearPath ~= true then
        return {
            reason = "target_reached_cover",
            status = "miss",
        }
    end
    return {
        status = "resolve",
    }
end

return table.freeze(EnemyAttackFlow)
