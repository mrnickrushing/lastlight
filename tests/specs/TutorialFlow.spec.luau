--!strict

local TutorialFlow = require("../../src/shared/TutorialFlow")
local TestRunner = require("../TestRunner")

return {
    name = "TutorialFlow",
    cases = {
        {
            name = "defines one clear action for every player-driven stage",
            run = function()
                local expected = {
                    arrive = "rescue",
                    gather = "gather",
                    choose_tool = "choose_tool",
                    build = "build",
                    prepare = "prepare",
                    reveal = "reveal",
                }
                for stage, action in expected do
                    local nextStage, reason = TutorialFlow.advance(stage, action)
                    TestRunner.truthy(nextStage, reason)
                end
            end,
        },
        {
            name = "rejects out-of-order actions",
            run = function()
                local nextStage, reason = TutorialFlow.advance("gather", "build")
                TestRunner.equal(nextStage, nil)
                TestRunner.truthy(string.find(reason or "", "expected gather", 1, true))
            end,
        },
        {
            name = "allows only the system to finish survival",
            run = function()
                local nextStage = TutorialFlow.advanceSystem("survive")
                TestRunner.equal(nextStage, "reveal")

                local rejected, reason = TutorialFlow.advanceSystem("build")
                TestRunner.equal(rejected, nil)
                TestRunner.truthy(reason)
            end,
        },
        {
            name = "reports stable eight-step progress",
            run = function()
                local first, total = TutorialFlow.progress("arrive")
                local last = TutorialFlow.progress("complete")
                TestRunner.equal(first, 1)
                TestRunner.equal(last, 8)
                TestRunner.equal(total, 8)
                TestRunner.equal(#TutorialFlow.order(), 8)
            end,
        },
        {
            name = "recognizes only known stages",
            run = function()
                TestRunner.equal(TutorialFlow.isValidStage("survive"), true)
                TestRunner.equal(TutorialFlow.isValidStage("impossible"), false)
                TestRunner.equal(TutorialFlow.isValidStage(3), false)
            end,
        },
    },
}
