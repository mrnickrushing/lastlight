--!strict

local CompanionMotion = require("../../src/shared/CompanionMotion")
local TestRunner = require("../TestRunner")

return {
    name = "CompanionMotion",
    cases = {
        {
            name = "the follow offset is a flank, not the keeper's heels",
            run = function()
                local side, back = CompanionMotion.followOffset()
                TestRunner.truthy(side > 1)
                TestRunner.truthy(back > 1)
                TestRunner.truthy(math.sqrt(side * side + back * back) > 2)
            end,
        },
        {
            name = "steps settle near the target, walk close, run far, arrive at extremes",
            run = function()
                -- inside the settle radius: no movement
                local sx, sz, moving = CompanionMotion.step(1, 0, 0, 0, 0.1)
                TestRunner.equal(moving, false)
                TestRunner.equal(sx, 1)
                TestRunner.equal(sz, 0)
                -- mid distance: moves toward the target at walk pace
                local wx, _, walking = CompanionMotion.step(8, 0, 0, 0, 0.1)
                TestRunner.equal(walking, true)
                TestRunner.truthy(wx < 8)
                TestRunner.truthy(wx > 8 - CompanionMotion.Constants.WalkSpeed * 0.1 - 0.01)
                -- far: run pace outpaces walk pace over the same step
                local rx = CompanionMotion.step(30, 0, 0, 0, 0.1)
                TestRunner.truthy((30 - rx) > (8 - wx))
                -- absurd distance: simple arrival, not a cross-map jog
                local ax, az, arrivedMoving = CompanionMotion.step(500, 0, 0, 0, 0.1)
                TestRunner.equal(arrivedMoving, false)
                TestRunner.equal(ax, 0)
                TestRunner.equal(az, 0)
                -- diagonal steps preserve direction
                local dxp, dzp = CompanionMotion.step(6, 6, 0, 0, 0.1)
                TestRunner.truthy(math.abs(dxp - dzp) < 0.0001)
            end,
        },
    },
}
