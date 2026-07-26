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
                TestRunner.equal(profile.schemaVersion, 6)
                TestRunner.equal(profile.tutorial.stage, "arrive")
                TestRunner.equal(profile.tutorial.complete, false)
                TestRunner.equal(profile.revision, 0)
                TestRunner.equal(next(profile.inventory.materials), nil)
                TestRunner.equal(profile.town.nightNumber, 1)
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
                TestRunner.equal(profile.schemaVersion, 6)
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
                TestRunner.equal(profile.schemaVersion, 6)
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
                TestRunner.equal(migrated.schemaVersion, 6)
                TestRunner.equal(migrated.profession.selectedId, nil)

                local selected = SaveSchema.withProfession(migrated, "profession_medic", 320)
                TestRunner.equal(selected.profession.selectedId, "profession_medic")
                TestRunner.equal(selected.revision, migrated.revision + 1)
                TestRunner.equal(migrated.profession.selectedId, nil)
            end,
        },
        {
            name = "migrates a safe unresolved chapter one story",
            run = function()
                local profile = SaveSchema.normalize({
                    schemaVersion = 3,
                    story = {
                        chapterOne = {
                            status = "complete",
                            decision = "destroy_everything",
                            wardenOutcome = "cheated",
                        },
                    },
                }, 300)
                TestRunner.equal(profile.schemaVersion, 6)
                TestRunner.equal(profile.story.chapterOne.status, "unresolved")
                TestRunner.equal(profile.story.chapterOne.decision, nil)
            end,
        },
        {
            name = "persists chapter one once without allowing rewrites",
            run = function()
                local profile = SaveSchema.default(100)
                local resolved, result = SaveSchema.withChapterOneResolution(
                    profile,
                    "chapter_1:run:hash:42",
                    "shared_agroforest",
                    "preserved",
                    500
                )
                TestRunner.equal(result.applied, true)
                TestRunner.equal(resolved.story.chapterOne.status, "complete")
                TestRunner.equal(resolved.story.chapterOne.completedAt, 500)
                TestRunner.equal(resolved.revision, 1)
                local duplicate, duplicateResult = SaveSchema.withChapterOneResolution(
                    resolved,
                    "chapter_1:run:hash:42",
                    "shared_agroforest",
                    "preserved",
                    600
                )
                TestRunner.equal(duplicate, resolved)
                TestRunner.equal(duplicateResult.duplicate, true)
                local conflict, conflictResult = SaveSchema.withChapterOneResolution(
                    resolved,
                    "chapter_1:other:hash:42",
                    "wild_regrowth",
                    "harmed",
                    700
                )
                TestRunner.equal(conflict, resolved)
                TestRunner.equal(conflictResult.reason, "chapter_already_resolved")
            end,
        },
        {
            name = "migrates a schema four profile with no town field into night one",
            run = function()
                local profile = SaveSchema.normalize({
                    schemaVersion = 4,
                    revision = 3,
                    tutorial = { stage = "reveal", complete = false },
                }, 300)
                TestRunner.equal(profile.schemaVersion, 6)
                TestRunner.equal(profile.town.nightNumber, 1)
            end,
        },
        {
            name = "restores a valid persisted night number and rejects corrupt values",
            run = function()
                local restored = SaveSchema.normalize({
                    schemaVersion = 5,
                    town = { nightNumber = 6 },
                }, 300)
                TestRunner.equal(restored.town.nightNumber, 6)

                local rejected = SaveSchema.normalize({
                    schemaVersion = 5,
                    town = { nightNumber = -2 },
                }, 300)
                TestRunner.equal(rejected.town.nightNumber, 1)

                local fractional = SaveSchema.normalize({
                    schemaVersion = 5,
                    town = { nightNumber = 3.5 },
                }, 300)
                TestRunner.equal(fractional.town.nightNumber, 1)
            end,
        },
        {
            name = "withNightNumber only ever advances, never regresses",
            run = function()
                local profile = SaveSchema.default(100)
                local advanced = SaveSchema.withNightNumber(profile, 4, 200)
                TestRunner.equal(advanced.town.nightNumber, 4)
                TestRunner.equal(advanced.revision, 1)
                TestRunner.equal(profile.town.nightNumber, 1)

                local unchanged = SaveSchema.withNightNumber(advanced, 2, 300)
                TestRunner.equal(unchanged, advanced)

                local same = SaveSchema.withNightNumber(advanced, 4, 300)
                TestRunner.equal(same, advanced)

                TestRunner.throws(function()
                    SaveSchema.withNightNumber(advanced, 0, 300)
                end)
            end,
        },
        {
            name = "nightNumber reads the current persisted value",
            run = function()
                local profile = SaveSchema.withNightNumber(SaveSchema.default(100), 9, 200)
                TestRunner.equal(SaveSchema.nightNumber(profile), 9)
            end,
        },
        {
            name = "migrates a schema five profile with no gear field into an empty crafted-item map",
            run = function()
                local profile = SaveSchema.normalize({
                    schemaVersion = 5,
                    town = { nightNumber = 3 },
                }, 300)
                TestRunner.equal(profile.schemaVersion, 6)
                TestRunner.equal(next(profile.gear), nil)
            end,
        },
        {
            name = "restores a valid persisted gear map and rejects unknown or invalid entries",
            run = function()
                local restored = SaveSchema.normalize({
                    schemaVersion = 6,
                    gear = { gear_meadow_satchel = 2 },
                }, 300)
                TestRunner.equal(restored.gear.gear_meadow_satchel, 2)

                local rejected = SaveSchema.normalize({
                    schemaVersion = 6,
                    gear = { gear_forged_item = 99, gear_amber_charm = -1 },
                }, 300)
                TestRunner.equal(next(rejected.gear), nil)
            end,
        },
        {
            name = "withCraftedItem deducts materials and grants the recipe's item exactly once affordable",
            run = function()
                local profile = SaveSchema.normalize({
                    inventory = {
                        materials = { material_meadow_fiber = 3, material_heartwood = 2 },
                    },
                }, 100)
                local crafted, result =
                    SaveSchema.withCraftedItem(profile, "recipe_meadow_satchel", 200)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(crafted.gear.gear_meadow_satchel, 1)
                TestRunner.equal(crafted.inventory.materials.material_meadow_fiber, 0)
                TestRunner.equal(crafted.revision, profile.revision + 1)

                local rejected, rejectedResult =
                    SaveSchema.withCraftedItem(crafted, "recipe_meadow_satchel", 300)
                TestRunner.equal(rejectedResult.applied, false)
                TestRunner.equal(rejectedResult.reason, "insufficient_materials")
                TestRunner.equal(rejected, crafted)
            end,
        },
        {
            name = "gearSnapshot reads the current persisted value",
            run = function()
                local profile = SaveSchema.normalize({
                    inventory = {
                        materials = { material_amber_sap = 2, material_brightcap = 2 },
                    },
                }, 100)
                local crafted = SaveSchema.withCraftedItem(profile, "recipe_amber_charm", 200)
                TestRunner.equal(SaveSchema.gearSnapshot(crafted).gear_amber_charm, 1)
                TestRunner.equal(next(SaveSchema.gearSnapshot(profile)), nil)
            end,
        },
    },
}
