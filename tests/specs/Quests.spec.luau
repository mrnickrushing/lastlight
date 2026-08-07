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
        fragmentsByRegion = overrides.fragmentsByRegion or {},
        masteryByProfession = overrides.masteryByProfession or {},
        residentsBonded = overrides.residentsBonded or 0,
    }
end

--[[
    Keyed signals are maps rather than counts, so "raise everything"
    cannot be a number. This builds a map that answers high for any key an
    objective might name, which is what the coverage cases need in order
    to prove a kind is routed at all.
]]
local function raisedByKey(prefix: string): { [string]: number }
    local raised: { [string]: number } = {}
    for _, quest in QuestCatalog.list() do
        local objective: any = quest.objective
        for _, key in { objective.regionId, objective.professionId } do
            if type(key) == "string" and string.sub(key, 1, #prefix) == prefix then
                raised[key] = 999
            end
        end
    end
    return raised
end

return {
    name = "Quests",
    cases = {
        {
            --[[
                A keyed objective only counts progress in the thing it
                names. The failure it guards against is the one that would
                make these two families pointless: if a mastery trial read
                total levels rather than one profession's, a player who
                dabbled in seven would clear the scout's trial without
                ever scouting, and the whole reason to specialise would go
                with it.
            ]]
            name = "a keyed objective counts only the profession or region it names",
            run = function()
                local scout = QuestCatalog.get("quest_mastery_scout") :: any
                TestRunner.equal(scout.objective.professionId, "profession_scout")
                -- deep in the wrong profession does nothing
                local elsewhere = signals({
                    masteryByProfession = { profession_warden = 9 },
                })
                local current, threshold, complete = Quests.progress(scout.id, elsewhere)
                TestRunner.equal(current, 0)
                TestRunner.equal(complete, false)
                TestRunner.truthy(threshold > 1)
                -- deep in the right one does
                local right = signals({ masteryByProfession = { profession_scout = 9 } })
                local _, _, done = Quests.progress(scout.id, right)
                TestRunner.equal(done, true)

                local mystery = QuestCatalog.get("quest_mystery_frostmere") :: any
                TestRunner.equal(mystery.objective.regionId, "region_frostmere")
                -- the archive being full of another region's memories is
                -- not this region's mystery solved
                local wrongRegion = signals({ fragmentsByRegion = { region_bramblewake = 10 } })
                TestRunner.equal((select(3, Quests.progress(mystery.id, wrongRegion))), false)
                local rightRegion = signals({ fragmentsByRegion = { region_frostmere = 2 } })
                TestRunner.equal((select(3, Quests.progress(mystery.id, rightRegion))), true)

                --[[
                    And every region's mystery asks for exactly what that
                    region holds -- a threshold above the fragment count
                    would be a quest nobody can finish, which is the kind
                    of thing that only shows up in a player's log.
                ]]
                local MemoryFragments = require("../../src/shared/MemoryFragments")
                local perRegion: { [string]: number } = {}
                for _, fragment in MemoryFragments.List do
                    local regionId = tostring(fragment.regionId)
                    perRegion[regionId] = (perRegion[regionId] or 0) + 1
                end
                for _, quest in QuestCatalog.list() do
                    local objective: any = quest.objective
                    if objective.kind == "fragments_in_region" then
                        TestRunner.truthy(
                            objective.threshold <= (perRegion[objective.regionId] or 0),
                            quest.id .. " asks for more memories than its region has"
                        )
                    end
                end
            end,
        },
        {
            --[[
                An arc is only an arc if its stages happen in order. The
                failure this guards against is specific and would look
                like a bug rather than a design mistake: every quest in
                this game claims itself the moment its objective is met,
                so without a lock a player who crafts forty things on day
                one would have all three of Tomas's stages claim
                themselves in the same tick, and his arc would be over
                before he asked for anything.
            ]]
            name = "a later stage of an arc does not progress until the one before it is claimed",
            run = function()
                local later: any = nil
                for _, quest in QuestCatalog.list() do
                    if quest.requires ~= nil then
                        later = quest
                        break
                    end
                end
                TestRunner.truthy(later ~= nil, "no quest is part of an arc")
                local first = QuestCatalog.get(later.requires)
                TestRunner.truthy(first ~= nil, later.id .. " requires a quest that does not exist")
                TestRunner.equal(
                    (first :: any).residentId,
                    later.residentId,
                    "an arc crosses two people"
                )

                -- everything satisfied, nothing claimed: the locked stage
                -- reads as zero progress and refuses to claim
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
                    fragmentsByRegion = raisedByKey("region_"),
                    masteryByProfession = raisedByKey("profession_"),
                })
                TestRunner.equal(Quests.isUnlocked(later.id, {}), false)
                local snapshot = Quests.snapshot(Quests.default(), raised)
                for _, entry in snapshot do
                    if entry.id == later.id then
                        TestRunner.equal(entry.locked, true)
                        TestRunner.equal(entry.progress, 0)
                        TestRunner.equal(entry.complete, false)
                        TestRunner.equal(entry.requires, later.requires)
                    end
                end

                --[[
                    And a single checkAndClaim pass may not walk a whole
                    arc: claiming stage one unlocks stage two, but the
                    unlock is read from the set as it was, so the player
                    goes back and hears the next request rather than
                    receiving three rewards silently.
                ]]
                local claimed, materials, results =
                    Quests.checkAndClaim(Quests.default(), {}, raised)
                local claimedIds: { [string]: boolean } = {}
                for _, result in results do
                    claimedIds[result.questId or result.id] = true
                end
                TestRunner.equal(claimedIds[later.id], nil, "an arc claimed two stages at once")
                TestRunner.equal(claimed[(first :: any).id], true)
                TestRunner.equal(Quests.isUnlocked(later.id, claimed), true)

                -- the next pass claims it, now that it is genuinely open
                local afterClaimed = (Quests.checkAndClaim(claimed, materials, raised))
                TestRunner.equal(afterClaimed[later.id], true)
            end,
        },
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
                    fragmentsByRegion = raisedByKey("region_"),
                    masteryByProfession = raisedByKey("profession_"),
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
