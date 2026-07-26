--!strict

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type Limiter = typeof(setmetatable(
    {} :: {
        _rate: number,
        _burst: number,
        _buckets: { [string]: { tokens: number, updatedAt: number } },
    },
    RateLimiter
))

function RateLimiter.new(ratePerSecond: number, burst: number): Limiter
    assert(ratePerSecond > 0, "rate must be positive")
    assert(burst >= 1, "burst must be at least one")
    return setmetatable({
        _rate = ratePerSecond,
        _burst = burst,
        _buckets = {},
    }, RateLimiter)
end

function RateLimiter.allow(self: Limiter, key: string, now: number, cost: number?): boolean
    local requested = cost or 1
    if requested <= 0 then
        return true
    end

    local bucket = self._buckets[key]
    if bucket == nil then
        bucket = { tokens = self._burst, updatedAt = now }
        self._buckets[key] = bucket
    end

    local elapsed = math.max(0, now - bucket.updatedAt)
    bucket.tokens = math.min(self._burst, bucket.tokens + elapsed * self._rate)
    bucket.updatedAt = now

    if bucket.tokens < requested then
        return false
    end

    bucket.tokens -= requested
    return true
end

function RateLimiter.clear(self: Limiter, key: string)
    self._buckets[key] = nil
end

return table.freeze(RateLimiter)
