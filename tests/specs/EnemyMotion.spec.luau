--!strict

local EnemyMotion = require("../../src/shared/EnemyMotion")
local TestRunner = require("../TestRunner")

return {
    name = "EnemyMotion",
    cases = {
        {
            name = "keeps grounded locomotion above its authored base",
            run = function()
                for index = 0, 100 do
                    local pose = EnemyMotion.pose(index / 20, "rootling", "moving", nil)
                    TestRunner.truthy(pose.height >= 0)
                end
            end,
        },
        {
            name = "gives flying enemies a wider hovering silhouette",
            run = function()
                local flying = EnemyMotion.pose(0.5, "hollow_crow", "moving", nil)
                local grounded = EnemyMotion.pose(0.5, "briarback", "moving", nil)
                TestRunner.truthy(math.abs(flying.height) > math.abs(grounded.height))
                TestRunner.truthy(math.abs(flying.roll) > math.abs(grounded.roll))
            end,
        },
        {
            name = "builds readable forward anticipation during attacks",
            run = function()
                local start = EnemyMotion.pose(0, "bark_ram", "attacking", 0)
                local ready = EnemyMotion.pose(0, "bark_ram", "attacking", 1)
                TestRunner.truthy(ready.pitch < start.pitch)
            end,
        },
        {
            name = "clamps unsafe attack progress",
            run = function()
                local capped = EnemyMotion.pose(1, "rootling", "attacking", 1)
                local overflow = EnemyMotion.pose(1, "rootling", "attacking", 50)
                TestRunner.equal(overflow.pitch, capped.pitch)
                TestRunner.equal(overflow.height, capped.height)
            end,
        },
    },
}
