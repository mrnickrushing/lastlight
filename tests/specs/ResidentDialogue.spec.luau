--!strict

local ResidentDialogue = require("../../src/shared/ResidentDialogue")
local TestRunner = require("../TestRunner")

local function quest(id: string, progress: number, threshold: number, claimed: boolean): any
    return {
        id = id,
        progress = progress,
        threshold = threshold,
        claimed = claimed,
    }
end

return {
    name = "ResidentDialogue",
    cases = {
        {
            name = "Tomas gives live crafting progress",
            run = function()
                local response = ResidentDialogue.respond("npc_tomas_reed", {
                    quest("quest_first_craft", 0, 1, false),
                }, {})
                TestRunner.equal(response.questId, "quest_first_craft")
                TestRunner.equal(response.state, "active")
                TestRunner.truthy(string.find(response.message, "0/1", 1, true) ~= nil)
            end,
        },
        {
            name = "Pip gives live night-survival progress",
            run = function()
                local response = ResidentDialogue.respond("npc_pip_wren", {
                    quest("quest_survive_three_nights", 2, 3, false),
                }, {})
                TestRunner.equal(response.questId, "quest_survive_three_nights")
                TestRunner.truthy(string.find(response.message, "2/3", 1, true) ~= nil)
            end,
        },
        {
            name = "Ena gives live expedition progress",
            run = function()
                local response = ResidentDialogue.respond("npc_ena_moss", {
                    quest("quest_bramblewake_veteran", 1, 3, false),
                }, {})
                TestRunner.equal(response.questId, "quest_bramblewake_veteran")
                TestRunner.truthy(string.find(response.message, "1/3", 1, true) ~= nil)
            end,
        },
        {
            name = "claimed quests become consequence-aware story dialogue",
            run = function()
                local response = ResidentDialogue.respond("npc_pip_wren", {
                    quest("quest_survive_three_nights", 3, 3, true),
                }, { wardenOutcome = "preserved" })
                TestRunner.equal(response.state, "story")
                TestRunner.truthy(string.find(response.message, "WARDEN", 1, true) ~= nil)
            end,
        },
        {
            name = "rejects unknown residents without inventing dialogue",
            run = function()
                TestRunner.equal(ResidentDialogue.respond("npc_forged", {}, {}), nil)
            end,
        },
    },
}
