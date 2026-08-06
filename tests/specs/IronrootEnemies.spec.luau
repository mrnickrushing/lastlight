--!strict

local BramblewakeEnemies = require("../../src/shared/BramblewakeEnemies")
local EnemyCatalog = require("../../src/shared/EnemyCatalog")
local EnemyCombatRules = require("../../src/shared/EnemyCombatRules")
local IronrootEnemies = require("../../src/shared/IronrootEnemies")
local TestRunner = require("../TestRunner")

return {
    name = "IronrootEnemies",
    cases = {
        {
            name = "the Delve fields its six named enemies",
            run = function()
                local order = IronrootEnemies.order()
                TestRunner.equal(#order, 6)
                for _, enemyId in order do
                    local definition = IronrootEnemies.require(enemyId)
                    TestRunner.equal(definition.id, enemyId)
                    TestRunner.truthy(definition.health > 0, enemyId .. " has no health")
                    TestRunner.truthy(definition.windup > 0, enemyId .. " strikes without warning")
                    TestRunner.truthy(
                        #definition.instruction > 8,
                        enemyId .. " tells the player nothing"
                    )
                    if definition.shape == "circle" then
                        TestRunner.truthy(definition.radius ~= nil, enemyId .. " has no ring")
                    else
                        TestRunner.truthy(
                            definition.width ~= nil and definition.length ~= nil,
                            enemyId .. " has no lane"
                        )
                    end
                end
            end,
        },
        {
            -- "No region is a reskin": the Delve must not be the forest with
            -- new names, and its shape of pressure must differ in the numbers.
            name = "the Delve does not fight like the forest",
            run = function()
                local forestIds: { [string]: boolean } = {}
                local forestModels: { [string]: boolean } = {}
                local forestHuntsPlayer = 0
                for _, definition in BramblewakeEnemies.all() do
                    forestIds[definition.id] = true
                    forestModels[definition.modelKey] = true
                    if definition.targetMode == "player" then
                        forestHuntsPlayer += 1
                    end
                end
                local delveHuntsPlayer = 0
                local fastest = 0
                for _, definition in IronrootEnemies.all() do
                    TestRunner.equal(forestIds[definition.id], nil)
                    TestRunner.equal(
                        forestModels[definition.modelKey],
                        nil,
                        "reskinned model: " .. definition.id
                    )
                    if definition.targetMode == "player" then
                        delveHuntsPlayer += 1
                    end
                    fastest = math.max(fastest, definition.speed)
                end
                -- the forest shoulders toward the lantern; the Delve comes for
                -- the person, and its quickest thing outruns anything in the wood
                TestRunner.truthy(delveHuntsPlayer > forestHuntsPlayer)
                local forestFastest = 0
                for _, definition in BramblewakeEnemies.all() do
                    forestFastest = math.max(forestFastest, definition.speed)
                end
                TestRunner.truthy(fastest > forestFastest)
            end,
        },
        {
            -- The Crank Guard is the roster's flanking lesson: plate in front,
            -- mechanism behind, and the existing combat rules must already
            -- express that without a new mechanic.
            name = "the crank guard rewards the flank and refuses the face",
            run = function()
                local guard = IronrootEnemies.require("enemy_crank_guard")
                TestRunner.equal(guard.frontShield, true)
                local frontal = EnemyCombatRules.strikeDamage(guard, 0.9)
                local flank = EnemyCombatRules.strikeDamage(guard, -0.6)
                TestRunner.truthy(flank > frontal * 3, "the flank is not worth taking")
                -- and the status system reaches it: stilled forces the flank
                local stilled = EnemyCombatRules.strikeDamage(guard, 0.9, { stilled = true })
                TestRunner.truthy(stilled > frontal)
            end,
        },
        {
            name = "the merged catalog serves both regions without collision",
            run = function()
                TestRunner.equal(#EnemyCatalog.order(), 12)
                TestRunner.equal(#EnemyCatalog.orderFor("region_bramblewake"), 6)
                TestRunner.equal(#EnemyCatalog.orderFor("region_ironroot"), 6)
                TestRunner.equal(#EnemyCatalog.orderFor("region_nowhere"), 0)
                -- Bramblewake's sequence is preserved exactly, so every night
                -- schedule that names an enemy keeps meaning what it meant
                local merged = EnemyCatalog.order()
                for index, enemyId in BramblewakeEnemies.order() do
                    TestRunner.equal(merged[index], enemyId)
                end
                TestRunner.equal(EnemyCatalog.regionOf("enemy_rail_hound"), "region_ironroot")
                TestRunner.equal(EnemyCatalog.regionOf("enemy_rootling"), "region_bramblewake")
                TestRunner.equal(EnemyCatalog.get("enemy_nothing"), nil)
                TestRunner.equal(
                    EnemyCatalog.require("enemy_crank_guard").displayName,
                    "Crank Guard"
                )
            end,
        },
    },
}
