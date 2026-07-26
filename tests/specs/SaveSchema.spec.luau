--!strict

local SaveSchema = require("../../src/shared/SaveSchema")
local TestRunner = require("../TestRunner")

return {
    name = "SaveSchema",
    cases = {
        {
            name = "creates a safe first-session profile",
            run = function()
                local profile = SaveSchema.default(100)
                TestRunner.equal(profile.schemaVersion, 1)
                TestRunner.equal(profile.tutorial.stage, "arrive")
                TestRunner.equal(profile.tutorial.complete, false)
                TestRunner.equal(profile.revision, 0)
            end,
        },
        {
            name = "normalizes malformed data without trusting unknown stages",
            run = function()
                local profile = SaveSchema.normalize({
                    revision = -9,
                    tutorial = {
                        stage = "skip_everything",
                        complete = "yes",
                        selectedTool = "laser",
                    },
                }, 200)
                TestRunner.equal(profile.tutorial.stage, "arrive")
                TestRunner.equal(profile.tutorial.complete, false)
                TestRunner.equal(profile.tutorial.selectedTool, nil)
                TestRunner.equal(profile.revision, 0)
            end,
        },
        {
            name = "restores a valid in-progress tutorial",
            run = function()
                local profile = SaveSchema.normalize({
                    schemaVersion = 1,
                    createdAt = 10,
                    updatedAt = 20,
                    revision = 4,
                    tutorial = {
                        stage = "build",
                        complete = false,
                        selectedTool = "hammer",
                    },
                }, 300)
                TestRunner.equal(profile.tutorial.stage, "build")
                TestRunner.equal(profile.tutorial.selectedTool, "hammer")
                TestRunner.equal(profile.revision, 4)
            end,
        },
        {
            name = "marks completion once and increments revision",
            run = function()
                local profile = SaveSchema.default(100)
                local complete = SaveSchema.withTutorial(profile, "complete", "torch", 220)
                TestRunner.equal(complete.tutorial.complete, true)
                TestRunner.equal(complete.tutorial.completedAt, 220)
                TestRunner.equal(complete.revision, 1)
                TestRunner.equal(profile.tutorial.complete, false)

                local repeated = SaveSchema.withTutorial(complete, "complete", "torch", 400)
                TestRunner.equal(repeated.tutorial.completedAt, 220)
                TestRunner.equal(repeated.revision, 2)
            end,
        },
        {
            name = "drops stale completion timestamps from incomplete progress",
            run = function()
                local profile = SaveSchema.normalize({
                    tutorial = {
                        stage = "build",
                        complete = false,
                        completedAt = 99,
                    },
                }, 300)
                TestRunner.equal(profile.tutorial.completedAt, nil)

                local complete = SaveSchema.withTutorial(profile, "complete", nil, 450)
                TestRunner.equal(complete.tutorial.completedAt, 450)
            end,
        },
    },
}
