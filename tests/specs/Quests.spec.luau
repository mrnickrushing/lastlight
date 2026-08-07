--!strict

local QuestCatalog = require("../../src/shared/QuestCatalog")
local Quests = require("../../src/shared/Quests")
local TestRunner = require("../TestRunner")

local function signals(overrides: any): Quests.Signals
    return {
        bramblewakeSettlements = overrides.bramblewakeSettlements or 0,
        chaptersResolved = overrides.chaptersResolved or 0,
        buildingsRaised = overrides.buildingsRaised or 0,
        craftedItems = overrides.craftedItems or 0,
        decorationsPlaced = overrides.decorationsPlaced or 0,
        fragmentsRecovered = overrides.fragmentsRecovered or 0,
        gearTraits = overrides.gearTraits or 0,
        materialsBanked = overrides.materialsBanked or 0,
        nightsSurvived = overrides.nightsSurvived or 0,
        residentsBonded = overrides.residentsBonded or 0,
    }
end

return {
    name = "Quests",
    cases = {
        {
            --[[
                A quest whose objective kind nothing routes reads zero
                forever: it shows in the log, never completes, and nothing
                fails. That is how a resident ends up carrying a promise
                the game cannot keep, so every kind in the catalog is
                walked here rather than only the ones a case remembered.

                Every signal is raised at once, so a kind with no case in
                currentValue is the only way this can fail.
            ]]
            name = "every quest in the catalog names a signal the game actually feeds",
            run = function()
                local raised = signals({
                    bramblewakeSettlements = 999,
                    buildingsRaised = 999,
                    chaptersResolved = 999,
                    craftedItems = 999,
                    decorationsPlaced = 999,
                    fragmentsRecovered = 999,
                    gearTraits = 999,
                    materialsBanked = 999,
                    nightsSurvived = 999,
                    residentsBonded = 999,
                })
                local empty = signals({})
                for _, quest in QuestCatalog.list() do
                    local current, threshold, complete = Quests.progress(quest.id, raised)
                    TestRunner.truthy(
                        complete,
                        quest.id
                            .. " never completes: nothing feeds "
                            .. tostring(quest.objective.kind)
                    )
                    TestRunner.truthy(current >= threshold)
                    TestRunner.truthy(threshold > 0, quest.id .. " asks for nothing")
                    local _, _, freshly = Quests.progress(quest.id, empty)
                    TestRunner.equal(
                        freshly,
                        false,
                        quest.id .. " is already complete on a fresh save"
                    )
                end
            end,
        },
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
                -- the snapshot follows the catalog, so adding a resident's
                -- quest never silently drops it from the Field Book
                TestRunner.equal(#snapshot, #QuestCatalog.list())
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
