--!strict

local DefenseLanes = require("../../src/shared/DefenseLanes")
local SaveSchema = require("../../src/shared/SaveSchema")
local TestRunner = require("../TestRunner")

return {
    name = "DefenseLanes",
    cases = {
        {
            name = "wave one always walks the meadow gate, and its lane is the identity",
            run = function()
                for night = 1, 12 do
                    TestRunner.equal(DefenseLanes.laneForWave(night, 1).id, "lane_meadow_gate")
                end
                -- yaw 0 must reproduce the authored spawn point bit-identically:
                -- the pre-lane night behavior is preserved, not approximated
                local gate = DefenseLanes.laneForWave(3, 1)
                local x, z = DefenseLanes.rotatedPoint(gate, 0, -153, 0, 6)
                TestRunner.equal(x, 0)
                TestRunner.equal(z, -153)
            end,
        },
        {
            name = "later waves rotate deterministically and reach every lane",
            run = function()
                local seen = {}
                for night = 1, 6 do
                    for wave = 2, 5 do
                        local lane = DefenseLanes.laneForWave(night, wave)
                        TestRunner.equal(lane.id, DefenseLanes.laneForWave(night, wave).id)
                        seen[lane.id] = true
                    end
                end
                local distinct = 0
                for _ in seen do
                    distinct += 1
                end
                TestRunner.equal(distinct, 3)
            end,
        },
        {
            name = "rotation preserves the spawn's distance from the lantern",
            run = function()
                local cx, cz = 4, 9
                local sx, sz = 0, -153
                local baseline = math.sqrt((sx - cx) ^ 2 + (sz - cz) ^ 2)
                for _, lane in DefenseLanes.list() do
                    local rx, rz = DefenseLanes.rotatedPoint(lane, sx, sz, cx, cz)
                    local rotated = math.sqrt((rx - cx) ^ 2 + (rz - cz) ^ 2)
                    TestRunner.truthy(math.abs(rotated - baseline) < 0.001)
                    if lane.yaw ~= 0 then
                        TestRunner.truthy(math.abs(rx - sx) + math.abs(rz - sz) > 1)
                    end
                end
            end,
        },
        {
            name = "plots sit at one fixed range on their own lanes, apart from each other",
            run = function()
                local cx, cz = 0, 6
                local points = {}
                for _, lane in DefenseLanes.list() do
                    local px, pz = DefenseLanes.plotPoint(lane, 0, -153, cx, cz)
                    local range = math.sqrt((px - cx) ^ 2 + (pz - cz) ^ 2)
                    TestRunner.truthy(math.abs(range - 46) < 0.001)
                    for _, other in points do
                        local apart = math.sqrt((px - other.x) ^ 2 + (pz - other.z) ^ 2)
                        TestRunner.truthy(apart > 20)
                    end
                    table.insert(points, { x = px, z = pz })
                end
            end,
        },
        {
            name = "the trigger ring bites inside its radius and nowhere else",
            run = function()
                local radius = DefenseLanes.Trap.triggerRadius
                TestRunner.equal(DefenseLanes.trapTriggers(10, 10, 10, 10), true)
                TestRunner.equal(DefenseLanes.trapTriggers(10 + radius, 10, 10, 10), true)
                TestRunner.equal(DefenseLanes.trapTriggers(10 + radius + 0.1, 10, 10, 10), false)
                TestRunner.equal(DefenseLanes.trapTriggers(0, 0, 40, 40), false)
            end,
        },
        {
            name = "arming spends materials atomically or not at all",
            run = function()
                local profile = SaveSchema.default(1234)
                profile.inventory.materials = { material_meadow_fiber = 2, material_heartwood = 1 }
                local spent, result =
                    SaveSchema.withSpentMaterials(profile, DefenseLanes.Trap.armCost, 100)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(spent.inventory.materials.material_meadow_fiber, nil)
                TestRunner.equal(spent.inventory.materials.material_heartwood, nil)
                -- one material short: nothing is deducted, the profile is untouched
                local short = SaveSchema.default(1234)
                short.inventory.materials = { material_meadow_fiber = 2 }
                local unchanged, refusal =
                    SaveSchema.withSpentMaterials(short, DefenseLanes.Trap.armCost, 100)
                TestRunner.equal(refusal.applied, false)
                TestRunner.equal(refusal.reason, "insufficient_materials")
                TestRunner.equal(unchanged.inventory.materials.material_meadow_fiber, 2)
                TestRunner.equal(unchanged.revision, short.revision)
            end,
        },
        {
            -- Watched in Studio: three armed plots sat through the tutorial's
            -- first night with creatures walking their rings and nothing
            -- happened, because the service counted only nights that
            -- TownNightService starts. A lit snare bites on any night, so the
            -- trigger geometry must not care which night it is -- this case
            -- pins the boundary the service now asks about instead.
            name = "a ring bites by where the walker is, not by whose night it is",
            run = function()
                local radius = DefenseLanes.Trap.triggerRadius
                -- a creature crossing the ring on the meadow gate lane
                local plotX, plotZ =
                    DefenseLanes.plotPoint(DefenseLanes.laneForWave(1, 1), 0, -153, 0, -80)
                TestRunner.equal(DefenseLanes.trapTriggers(plotX, plotZ, plotX, plotZ), true)
                TestRunner.equal(
                    DefenseLanes.trapTriggers(plotX, plotZ + radius - 0.5, plotX, plotZ),
                    true
                )
                TestRunner.equal(
                    DefenseLanes.trapTriggers(plotX, plotZ + radius + 0.5, plotX, plotZ),
                    false
                )
                -- and the first wave of the very first night walks that lane,
                -- which is why an armed gate plot has to be live for it
                TestRunner.equal(DefenseLanes.laneForWave(1, 1).id, "lane_meadow_gate")
            end,
        },
    },
}
