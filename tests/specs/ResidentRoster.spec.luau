--!strict

local QuestCatalog = require("../../src/shared/QuestCatalog")
local ResidentDialogue = require("../../src/shared/ResidentDialogue")
local ResidentLife = require("../../src/shared/ResidentLife")
local ResidentRoster = require("../../src/shared/ResidentRoster")
local TownProgression = require("../../src/shared/TownProgression")
local TestRunner = require("../TestRunner")

local CHAPTER_ONE = table.freeze({ "npc_tomas_reed", "npc_pip_wren", "npc_ena_moss" })

return {
    name = "ResidentRoster",
    cases = {
        {
            name = "nineteen residents, sixteen of them earned in the new regions",
            run = function()
                local roster = ResidentRoster.list()
                TestRunner.equal(#roster, 19)
                local byRegion: { [string]: number } = {}
                for _, definition in roster do
                    byRegion[definition.homeRegion] = (byRegion[definition.homeRegion] or 0) + 1
                    TestRunner.truthy(
                        #definition.introduction > 24,
                        definition.id .. " has nothing to say about themselves"
                    )
                end
                TestRunner.equal(byRegion.region_bramblewake, 3)
                TestRunner.equal(byRegion.region_ironroot, 4)
                TestRunner.equal(byRegion.region_mireglass, 4)
                TestRunner.equal(byRegion.region_tempest, 4)
                TestRunner.equal(byRegion.region_frostmere, 4)
            end,
        },
        {
            -- A fresh save must still meet exactly the three people it has
            -- always met; the town fills as the story does, not before.
            name = "chapter one's town is unchanged, and later chapters fill it",
            run = function()
                local chapterOne = ResidentRoster.idsForChapter(1)
                TestRunner.equal(#chapterOne, 3)
                for index, residentId in CHAPTER_ONE do
                    TestRunner.equal(chapterOne[index], residentId)
                end
                -- a caller that names no chapter means chapter one
                TestRunner.equal(#ResidentRoster.idsForChapter(nil), 3)
                TestRunner.equal(#ResidentRoster.idsForChapter(0), 3)
                TestRunner.equal(#ResidentRoster.idsForChapter(2), 7)
                TestRunner.equal(#ResidentRoster.idsForChapter(3), 11)
                TestRunner.equal(#ResidentRoster.idsForChapter(4), 15)
                TestRunner.equal(#ResidentRoster.idsForChapter(5), 19)
                TestRunner.equal(#ResidentRoster.idsForChapter(9), 19)
            end,
        },
        {
            -- The roster exists because these lists used to drift apart.
            name = "every resident has a real job, a real building, and a real quest",
            run = function()
                local buildingIds: { [string]: boolean } = {}
                for _, buildingId in TownProgression.buildingIds() do
                    buildingIds[buildingId] = true
                end
                local claimedBuildings: { [string]: string } = {}
                local claimedQuests: { [string]: string } = {}
                local titles: { [string]: boolean } = {}
                for _, definition in ResidentRoster.list() do
                    local job = definition.job
                    TestRunner.equal(job.residentId, definition.id)
                    TestRunner.truthy(
                        buildingIds[job.buildingId],
                        definition.id
                            .. " works at a building that does not exist: "
                            .. job.buildingId
                    )
                    TestRunner.equal(
                        claimedBuildings[job.buildingId],
                        nil,
                        "two residents share " .. job.buildingId
                    )
                    claimedBuildings[job.buildingId] = definition.id
                    TestRunner.truthy(
                        QuestCatalog.isValid(definition.questId),
                        definition.id .. " carries an unknown quest: " .. definition.questId
                    )
                    TestRunner.equal(
                        claimedQuests[definition.questId],
                        nil,
                        "two residents carry " .. definition.questId
                    )
                    claimedQuests[definition.questId] = definition.id
                    TestRunner.equal(titles[job.title], nil, "two residents share a title")
                    titles[job.title] = true
                    TestRunner.truthy(#job.boonLabel > 12)
                end
            end,
        },
        {
            -- ResidentLife now reads the roster; chapter I's jobs, order and
            -- boons must be exactly what they were before it did.
            name = "resident life inherits the roster without changing what exists",
            run = function()
                for index, residentId in CHAPTER_ONE do
                    TestRunner.equal(ResidentLife.Ids[index], residentId)
                end
                TestRunner.equal(ResidentLife.Jobs.npc_tomas_reed.buildingId, "building_inn")
                TestRunner.equal(ResidentLife.Jobs.npc_tomas_reed.title, "QUARTERMASTER")
                TestRunner.equal(ResidentLife.Jobs.npc_tomas_reed.boon, "dawn_repair")
                TestRunner.equal(ResidentLife.Jobs.npc_pip_wren.buildingId, "building_town_board")
                TestRunner.equal(ResidentLife.Jobs.npc_ena_moss.boon, "lantern_reserve")
                -- and the new residents are known to it too
                TestRunner.equal(ResidentLife.Jobs.npc_hesper_vane.buildingId, "building_forge")
                local state = ResidentLife.default()
                TestRunner.truthy(state.npc_lissen_ford ~= nil)
                TestRunner.equal(state.npc_lissen_ford.bond, 0)
            end,
        },
        {
            -- Every resident must answer when spoken to, at every stage of
            -- their quest, or a player meets a person who has nothing to say.
            name = "every resident speaks while questing and after finishing",
            run = function()
                for _, definition in ResidentRoster.list() do
                    local questing = ResidentDialogue.respond(definition.id, {
                        {
                            id = definition.questId,
                            progress = 0,
                            threshold = 3,
                            claimed = false,
                        },
                    }, nil)
                    TestRunner.truthy(questing ~= nil, definition.id .. " does not answer")
                    local response = questing :: any
                    TestRunner.equal(response.questId, definition.questId)
                    TestRunner.equal(response.state, "active")
                    TestRunner.truthy(
                        string.find(response.message, definition.displayName, 1, true) ~= nil,
                        definition.id .. " does not say who is speaking"
                    )

                    local finished = ResidentDialogue.respond(definition.id, {
                        {
                            id = definition.questId,
                            progress = 3,
                            threshold = 3,
                            claimed = true,
                        },
                    }, nil)
                    TestRunner.truthy(finished ~= nil)
                    local story = finished :: any
                    TestRunner.equal(story.state, "story")
                    TestRunner.truthy(#story.message > 30, definition.id .. " says nothing after")
                end
                TestRunner.equal(ResidentDialogue.respond("npc_nobody", {}, nil), nil)
            end,
        },
    },
}
