--!strict

local Quests = require("../../src/shared/Quests")
local TestRunner = require("../TestRunner")

local function signals(overrides: any): Quests.Signals
    return {
        bramblewakeSettlements = overrides.bramblewakeSettlements or 0,
        craftedItems = overrides.craftedItems or 0,
        nightsSurvived = overrides.nightsSurvived or 0,
    }
end

return {
    name = "Quests",
    cases = {
        {
            name = "progress reports current value, threshold, and completion for each objective kind",
            run = function()
                local current, threshold, complete =
                    Quests.progress("quest_survive_three_nights", signals({ nightsSurvived = 2 }))
                TestRunner.equal(current, 2)
                TestRunner.equal(threshold, 3)
                TestRunner.equal(complete, false)

                local _, _, metThreshold =
                    Quests.progress("quest_survive_three_nights", signals({ nightsSurvived = 3 }))
                TestRunner.equal(metThreshold, true)
            end,
        },
        {
            name = "progress rejects an unknown quest ID",
            run = function()
                local current, threshold, complete = Quests.progress("quest_forged", signals({}))
                TestRunner.equal(current, 0)
                TestRunner.equal(threshold, 0)
                TestRunner.equal(complete, false)
            end,
        },
        {
            name = "checkAndClaim grants a reward and marks a quest claimed exactly once",
            run = function()
                local claimed = Quests.default()
                local materials = { material_amber_sap = 1 }
                local nextClaimed, nextMaterials, results =
                    Quests.checkAndClaim(claimed, materials, signals({ craftedItems = 1 }))
                TestRunner.equal(#results, 1)
                TestRunner.equal(results[1].questId, "quest_first_craft")
                TestRunner.equal(nextClaimed.quest_first_craft, true)
                TestRunner.equal(nextMaterials.material_amber_sap, 4)
                TestRunner.equal(claimed.quest_first_craft, nil)
                TestRunner.equal(materials.material_amber_sap, 1)

                local unchangedClaimed, unchangedMaterials, secondResults =
                    Quests.checkAndClaim(nextClaimed, nextMaterials, signals({ craftedItems = 1 }))
                TestRunner.equal(#secondResults, 0)
                TestRunner.equal(unchangedClaimed, nextClaimed)
                TestRunner.equal(unchangedMaterials, nextMaterials)
            end,
        },
        {
            name = "checkAndClaim claims every newly satisfiable quest in one pass",
            run = function()
                local claimed, materials, results = Quests.checkAndClaim(
                    Quests.default(),
                    {},
                    signals({ bramblewakeSettlements = 3, craftedItems = 1, nightsSurvived = 3 })
                )
                TestRunner.equal(#results, 3)
                TestRunner.equal(claimed.quest_survive_three_nights, true)
                TestRunner.equal(claimed.quest_first_craft, true)
                TestRunner.equal(claimed.quest_bramblewake_veteran, true)
                TestRunner.equal(materials.material_heartwood, 5)
                TestRunner.equal(materials.material_amber_sap, 3)
                TestRunner.equal(materials.material_brightcap, 3)
            end,
        },
        {
            name = "checkAndClaim never regresses an already-claimed quest",
            run = function()
                local claimed = { quest_first_craft = true }
                local materials = { material_amber_sap = 9 }
                local nextClaimed, nextMaterials, results =
                    Quests.checkAndClaim(claimed, materials, signals({ craftedItems = 0 }))
                TestRunner.equal(#results, 0)
                TestRunner.equal(nextClaimed, claimed)
                TestRunner.equal(nextMaterials, materials)
            end,
        },
        {
            name = "snapshot reports every catalog quest even when nothing is complete",
            run = function()
                local snapshot = Quests.snapshot(Quests.default(), signals({}))
                TestRunner.equal(#snapshot, 3)
                for _, quest in snapshot do
                    TestRunner.equal(quest.claimed, false)
                    TestRunner.equal(quest.complete, false)
                    TestRunner.equal(quest.progress, 0)
                end
            end,
        },
        {
            name = "normalizeClaimed keeps only known quest IDs marked true",
            run = function()
                local claimed = Quests.normalizeClaimed({
                    quest_first_craft = true,
                    quest_survive_three_nights = false,
                    quest_forged = true,
                })
                TestRunner.equal(claimed.quest_first_craft, true)
                TestRunner.equal(claimed.quest_survive_three_nights, nil)
                TestRunner.equal(claimed.quest_forged, nil)
            end,
        },
        {
            name = "normalizeClaimed rejects non-table input",
            run = function()
                local claimed = Quests.normalizeClaimed("not a table")
                TestRunner.equal(next(claimed), nil)
            end,
        },
    },
}
