--!strict

local BramblewakeEnemies = require("../../src/shared/BramblewakeEnemies")
local EnemyCombatRules = require("../../src/shared/EnemyCombatRules")
local TestRunner = require("../TestRunner")

return {
    name = "EnemyCombatRules",
    cases = {
        {
            name = "resolves circle and lane geometry at their boundaries",
            run = function()
                TestRunner.truthy(EnemyCombatRules.contains("circle", 3, 4, 5, nil, nil))
                TestRunner.equal(EnemyCombatRules.contains("circle", 5.1, 0, 5, nil, nil), false)
                TestRunner.truthy(EnemyCombatRules.contains("lane", 3, 8, nil, 6, 16))
                TestRunner.equal(EnemyCombatRules.contains("lane", 3.1, 0, nil, 6, 16), false)
            end,
        },
        {
            name = "makes the Briarback shield strong but never invulnerable",
            run = function()
                local definition = BramblewakeEnemies.require("enemy_briarback")
                local frontal, frontalResult = EnemyCombatRules.strikeDamage(definition, 0.8)
                local flank, flankResult = EnemyCombatRules.strikeDamage(definition, -0.2)
                TestRunner.equal(frontal, 8)
                TestRunner.equal(frontalResult, "shielded")
                TestRunner.equal(flank, 40)
                TestRunner.equal(flankResult, "flanked")
            end,
        },
        {
            name = "uses regular strike damage for unshielded enemies",
            run = function()
                local definition = BramblewakeEnemies.require("enemy_rootling")
                local damage, result = EnemyCombatRules.strikeDamage(definition, 1)
                TestRunner.equal(damage, 34)
                TestRunner.equal(result, "hit")
            end,
        },
    },
}
