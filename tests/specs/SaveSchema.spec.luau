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
                TestRunner.equal(profile.schemaVersion, 3)
                TestRunner.equal(profile.tutorial.stage, "arrive")
                TestRunner.equal(profile.tutorial.complete, false)
                TestRunner.equal(profile.revision, 0)
                TestRunner.equal(next(profile.inventory.materials), nil)
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
                TestRunner.equal(profile.schemaVersion, 3)
            end,
        },
        {
            name = "migrates schema one profiles into an empty versioned inventory",
            run = function()
                local profile = SaveSchema.normalize({
                    schemaVersion = 1,
                    createdAt = 10,
                    updatedAt = 20,
                    revision = 7,
                    tutorial = {
                        stage = "complete",
                        complete = true,
                    },
                }, 300)
                TestRunner.equal(profile.schemaVersion, 3)
                TestRunner.equal(profile.revision, 7)
                TestRunner.equal(profile.tutorial.complete, true)
                TestRunner.equal(SaveSchema.expeditionPending(profile).count, 0)
            end,
        },
        {
            name = "persists and settles expedition rewards exactly once",
            run = function()
                local profile = SaveSchema.default(100)
                local rewardProfile, rewardResult = SaveSchema.withUnbankedExpeditionReward(
                    profile,
                    "event_reward:run:hash:event",
                    "hash",
                    {
                        materialId = "material_heartwood",
                        amount = 4,
                    },
                    110
                )
                local duplicate = SaveSchema.withUnbankedExpeditionReward(
                    rewardProfile,
                    "event_reward:run:hash:event",
                    "hash",
                    {
                        materialId = "material_heartwood",
                        amount = 4,
                    },
                    111
                )
                local pending = SaveSchema.expeditionPending(rewardProfile)
                local settlementId =
                    SaveSchema.expeditionSettlementId("run", 42, pending.fingerprint)
                local settled, settlementResult =
                    SaveSchema.withExpeditionSettlement(rewardProfile, settlementId, "hash", 120)
                local replay =
                    SaveSchema.withExpeditionSettlement(settled, settlementId, "hash", 130)

                TestRunner.equal(rewardResult.applied, true)
                TestRunner.equal(duplicate, rewardProfile)
                TestRunner.equal(settlementResult.applied, true)
                TestRunner.equal(settled.inventory.materials.material_heartwood, 4)
                TestRunner.equal(replay, settled)
                TestRunner.equal(settled.revision, 2)
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
        {
            name = "migrates and persists only valid profession selections",
            run = function()
                local migrated = SaveSchema.normalize({
                    schemaVersion = 2,
                    profession = {
                        selectedId = "profession_hacker",
                    },
                }, 300)
                TestRunner.equal(migrated.schemaVersion, 3)
                TestRunner.equal(migrated.profession.selectedId, nil)

                local selected = SaveSchema.withProfession(migrated, "profession_medic", 320)
                TestRunner.equal(selected.profession.selectedId, "profession_medic")
                TestRunner.equal(selected.revision, migrated.revision + 1)
                TestRunner.equal(migrated.profession.selectedId, nil)
            end,
        },
    },
}
