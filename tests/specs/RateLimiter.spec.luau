--!strict

local RateLimiter = require("../../src/shared/RateLimiter")
local TestRunner = require("../TestRunner")

return {
    name = "RateLimiter",
    cases = {
        {
            name = "allows a bounded burst then rejects excess",
            run = function()
                local limiter = RateLimiter.new(2, 3)
                TestRunner.equal(limiter:allow("player", 0), true)
                TestRunner.equal(limiter:allow("player", 0), true)
                TestRunner.equal(limiter:allow("player", 0), true)
                TestRunner.equal(limiter:allow("player", 0), false)
            end,
        },
        {
            name = "refills tokens over elapsed time",
            run = function()
                local limiter = RateLimiter.new(2, 2)
                limiter:allow("player", 0, 2)
                TestRunner.equal(limiter:allow("player", 0.25), false)
                TestRunner.equal(limiter:allow("player", 0.5), true)
            end,
        },
        {
            name = "keeps buckets isolated and clearable",
            run = function()
                local limiter = RateLimiter.new(1, 1)
                TestRunner.equal(limiter:allow("a", 0), true)
                TestRunner.equal(limiter:allow("a", 0), false)
                TestRunner.equal(limiter:allow("b", 0), true)
                limiter:clear("a")
                TestRunner.equal(limiter:allow("a", 0), true)
            end,
        },
    },
}
