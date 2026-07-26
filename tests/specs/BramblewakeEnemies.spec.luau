--!strict

local BramblewakeEnemies = require("../../src/shared/BramblewakeEnemies")
local TestRunner = require("../TestRunner")

return {
    name = "BramblewakeEnemies",
    cases = {
        {
            name = "ships the six stable catalog enemy IDs exactly once",
            run = function()
                local expected = {
                    "enemy_rootling",
                    "enemy_briarback",
                    "enemy_pollen_wisp",
                    "enemy_hollow_crow",
                    "enemy_snapvine",
                    "enemy_bark_ram",
                }
                local seen = {}
                local order = BramblewakeEnemies.order()
                TestRunner.equal(#order, #expected)
                for index, enemyId in order do
                    TestRunner.equal(enemyId, expected[index])
                    TestRunner.truthy(seen[enemyId] == nil, "enemy ID must be unique")
                    seen[enemyId] = true
                    TestRunner.equal(BramblewakeEnemies.require(enemyId).id, enemyId)
                end
            end,
        },
        {
            name = "authors bounded readable and avoidable mechanics",
            run = function()
                for _, definition in BramblewakeEnemies.all() do
                    TestRunner.truthy(definition.health > 0 and definition.health <= 150)
                    TestRunner.truthy(definition.windup >= 0.8)
                    TestRunner.truthy(definition.playerDamage > 0 and definition.playerDamage < 100)
                    TestRunner.truthy(#definition.attackName >= 4)
                    TestRunner.truthy(#definition.instruction >= 8)
                    if definition.shape == "circle" then
                        TestRunner.truthy((definition.radius or 0) >= 7)
                    else
                        TestRunner.truthy((definition.width or 0) >= 5)
                        TestRunner.truthy((definition.length or 0) >= 12)
                    end
                end
            end,
        },
        {
            name = "keeps profession independent completion paths",
            run = function()
                for _, definition in BramblewakeEnemies.all() do
                    TestRunner.truthy(definition.strikeDamage > 0)
                    TestRunner.truthy(definition.strikeRange <= definition.attackRange)
                    TestRunner.truthy(
                        definition.stationary == false or definition.lanternDamage == 0
                    )
                end
            end,
        },
    },
}
