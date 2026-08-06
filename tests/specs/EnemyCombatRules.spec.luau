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
            name = "reactions: a stilled enemy is bound open, whatever the facing",
            run = function()
                -- front-shielded enemy struck head-on: normally shielded,
                -- but the bind forces the flank
                local shielded = {
                    frontShield = true,
                    frontalStrikeDamage = 4,
                    flankStrikeDamage = 20,
                    strikeDamage = 20,
                }
                local damage, result, label =
                    EnemyCombatRules.strikeDamage(shielded, 1, { stilled = true })
                TestRunner.equal(result, "flanked")
                TestRunner.equal(damage, 25) -- 20 x 1.25
                TestRunner.truthy(label ~= nil)
                -- plain enemy: result upgrades to flanked with the bonus
                local plain = { strikeDamage = 20 }
                local d2, r2 = EnemyCombatRules.strikeDamage(plain, 1, { stilled = true })
                TestRunner.equal(r2, "flanked")
                TestRunner.equal(d2, 25)
            end,
        },
        {
            name = "reactions: snare exposes and drowsiness softens, bounded",
            run = function()
                local plain = { strikeDamage = 20 }
                local d1, _, l1 = EnemyCombatRules.strikeDamage(plain, 1, { snared = true })
                TestRunner.equal(d1, 24) -- 20 x 1.2
                TestRunner.truthy(l1 ~= nil)
                local d2, _, l2 = EnemyCombatRules.strikeDamage(plain, 1, { drowsyStriker = true })
                TestRunner.equal(d2, 17) -- 20 x 0.85
                TestRunner.truthy(l2 ~= nil)
                -- stack: stilled + drowsy = 1.25 * 0.85 = 1.0625
                local d3 = EnemyCombatRules.strikeDamage(
                    plain,
                    1,
                    { stilled = true, drowsyStriker = true }
                )
                TestRunner.equal(d3, 21)
                -- no reactions: identical to the two-argument call
                local d4, r4 = EnemyCombatRules.strikeDamage(plain, 1)
                TestRunner.equal(d4, 20)
                TestRunner.equal(r4, "hit")
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
