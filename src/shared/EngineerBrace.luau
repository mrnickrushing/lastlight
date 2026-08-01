--!strict

local EngineerBrace = {}

export type State = {
    activeUntil: number,
    capacity: number,
    maxCapacity: number,
    ownerUserId: number,
    revision: number,
}

local MAX_DURATION = 30
local MAX_CAPACITY = 40

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function EngineerBrace.default(): State
    return {
        activeUntil = 0,
        capacity = 0,
        maxCapacity = 0,
        ownerUserId = 0,
        revision = 0,
    }
end

function EngineerBrace.normalize(value: any): State
    local result = EngineerBrace.default()
    if type(value) ~= "table" then
        return result
    end
    if finite(value.activeUntil) and value.activeUntil >= 0 then
        result.activeUntil = value.activeUntil
    end
    if finite(value.maxCapacity) and value.maxCapacity >= 0 then
        result.maxCapacity = math.clamp(math.floor(value.maxCapacity), 0, MAX_CAPACITY)
    end
    if finite(value.capacity) and value.capacity >= 0 then
        result.capacity = math.clamp(math.floor(value.capacity), 0, result.maxCapacity)
    end
    if finite(value.ownerUserId) and value.ownerUserId >= 0 then
        result.ownerUserId = math.floor(value.ownerUserId)
    end
    if finite(value.revision) and value.revision >= 0 then
        result.revision = math.floor(value.revision)
    end
    return result
end

function EngineerBrace.deploy(
    state: State,
    now: number,
    duration: number,
    capacity: number,
    ownerUserId: number
): (State, any)
    local current = EngineerBrace.normalize(state)
    if
        not finite(now)
        or not finite(duration)
        or not finite(capacity)
        or not finite(ownerUserId)
        or duration <= 0
        or capacity <= 0
        or ownerUserId < 1
    then
        return current, { applied = false, reason = "invalid_deployment" }
    end

    local boundedDuration = math.clamp(duration, 1, MAX_DURATION)
    local boundedCapacity = math.clamp(math.floor(capacity), 1, MAX_CAPACITY)
    local nextState = {
        activeUntil = now + boundedDuration,
        capacity = boundedCapacity,
        maxCapacity = boundedCapacity,
        ownerUserId = math.floor(ownerUserId),
        revision = current.revision + 1,
    }
    return nextState,
        {
            applied = true,
            activeUntil = nextState.activeUntil,
            capacity = nextState.capacity,
            duration = boundedDuration,
            ownerUserId = nextState.ownerUserId,
            reason = "deployed",
            revision = nextState.revision,
        }
end

function EngineerBrace.absorb(state: State, amount: number, now: number): (State, any)
    local current = EngineerBrace.normalize(state)
    if not finite(amount) or not finite(now) or amount <= 0 then
        return current, { applied = false, reason = "invalid_pressure" }
    end
    local boundedAmount = math.clamp(math.ceil(amount), 1, 100)
    if current.capacity <= 0 then
        return current,
            {
                absorbed = 0,
                applied = false,
                reason = "brace_empty",
                remaining = boundedAmount,
            }
    end
    if now >= current.activeUntil then
        local expired = table.clone(current)
        expired.capacity = 0
        return expired,
            {
                absorbed = 0,
                applied = false,
                reason = "brace_expired",
                remaining = boundedAmount,
            }
    end

    local absorbed = math.min(current.capacity, boundedAmount)
    local nextState = table.clone(current)
    nextState.capacity -= absorbed
    return nextState,
        {
            absorbed = absorbed,
            applied = absorbed > 0,
            exhausted = nextState.capacity <= 0,
            ownerUserId = current.ownerUserId,
            reason = if nextState.capacity <= 0 then "brace_exhausted" else "pressure_absorbed",
            remaining = boundedAmount - absorbed,
            revision = current.revision,
        }
end

function EngineerBrace.snapshot(state: State, now: number): any
    local current = EngineerBrace.normalize(state)
    local active = finite(now) and now < current.activeUntil and current.capacity > 0
    return {
        active = active,
        activeUntil = current.activeUntil,
        capacity = if active then current.capacity else 0,
        maxCapacity = current.maxCapacity,
        ownerUserId = current.ownerUserId,
        remainingSeconds = if active then math.max(0, current.activeUntil - now) else 0,
        revision = current.revision,
    }
end

EngineerBrace.MaxCapacity = MAX_CAPACITY
EngineerBrace.MaxDuration = MAX_DURATION

return table.freeze(EngineerBrace)
