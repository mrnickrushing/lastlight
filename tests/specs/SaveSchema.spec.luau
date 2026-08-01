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
                TestRunner.equal(profile.schemaVersion, 10)
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
                TestRunner.equal(profile.schemaVersion, 10)
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
                TestRunner.equal(profile.schemaVersion, 10)
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
                TestRunner.equal(migrated.schemaVersion, 10)
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
                TestRunner.equal(profile.schemaVersion, 10)
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
                TestRunner.equal(profile.schemaVersion, 10)
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
            name = "migrates schema eight profiles into an undamaged town condition",
            run = function()
                local profile = SaveSchema.normalize({
                    schemaVersion = 8,
                    town = { nightNumber = 7 },
                }, 300)
                local condition = SaveSchema.townCondition(profile)
                TestRunner.equal(profile.schemaVersion, 10)
                TestRunner.equal(condition.integrity, 100)
                TestRunner.equal(condition.damageLevel, 0)
                TestRunner.equal(condition.lastNightNumber, 0)
            end,
        },
        {
            name = "persists normalized town damage and repair state",
            run = function()
                local profile = SaveSchema.default(100)
                local changed = SaveSchema.withTownCondition(profile, {
                    integrity = 58,
                    lastNightNumber = 4,
                    lastDamage = 30,
                    repairsCompleted = 2,
                }, 200)
                local condition = SaveSchema.townCondition(changed)
                TestRunner.equal(condition.integrity, 58)
                TestRunner.equal(condition.damageLevel, 2)
                TestRunner.equal(condition.repairsCompleted, 2)
                TestRunner.equal(changed.revision, 1)
                TestRunner.equal(profile.town.condition.integrity, 100)
            end,
        },
        {
            name = "migrates a schema five profile with no gear field into an empty crafted-item map",
            run = function()
                local profile = SaveSchema.normalize({
                    schemaVersion = 5,
                    town = { nightNumber = 3 },
                }, 300)
                TestRunner.equal(profile.schemaVersion, 10)
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
        {
            name = "withUsedGearItem consumes exactly one owned unit and rejects an empty stack",
            run = function()
                local profile = SaveSchema.normalize({
                    gear = { gear_amber_charm = 1 },
                }, 100)
                local used, result = SaveSchema.withUsedGearItem(profile, "gear_amber_charm", 200)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(used.gear.gear_amber_charm, 0)
                TestRunner.equal(used.revision, profile.revision + 1)
                TestRunner.equal(profile.gear.gear_amber_charm, 1)

                local rejected, rejectedResult =
                    SaveSchema.withUsedGearItem(used, "gear_amber_charm", 300)
                TestRunner.equal(rejectedResult.applied, false)
                TestRunner.equal(rejectedResult.reason, "not_owned")
                TestRunner.equal(rejected, used)
            end,
        },
        {
            name = "migrates a schema six profile with no quests field into an empty claimed set",
            run = function()
                local profile = SaveSchema.normalize({
                    schemaVersion = 6,
                    gear = { gear_meadow_satchel = 1 },
                }, 300)
                TestRunner.equal(profile.schemaVersion, 10)
                TestRunner.equal(next(profile.quests.claimed), nil)
            end,
        },
        {
            name = "restores a valid claimed-quest set and rejects unknown or invalid entries",
            run = function()
                local restored = SaveSchema.normalize({
                    schemaVersion = 7,
                    quests = { claimed = { quest_first_craft = true } },
                }, 300)
                TestRunner.equal(restored.quests.claimed.quest_first_craft, true)

                local rejected = SaveSchema.normalize({
                    schemaVersion = 7,
                    quests = { claimed = { quest_forged = true, quest_first_craft = false } },
                }, 300)
                TestRunner.equal(next(rejected.quests.claimed), nil)
            end,
        },
        {
            name = "checkAndClaimQuests claims a satisfiable quest exactly once and grants its reward",
            run = function()
                local profile = SaveSchema.normalize({
                    gear = { gear_meadow_satchel = 1 },
                }, 100)
                local claimed, results = SaveSchema.checkAndClaimQuests(profile, 200)
                TestRunner.equal(#results, 1)
                TestRunner.equal(results[1].questId, "quest_first_craft")
                TestRunner.equal(claimed.quests.claimed.quest_first_craft, true)
                TestRunner.equal(claimed.inventory.materials.material_amber_sap, 3)
                TestRunner.equal(claimed.revision, profile.revision + 1)

                local unchanged, secondResults = SaveSchema.checkAndClaimQuests(claimed, 300)
                TestRunner.equal(#secondResults, 0)
                TestRunner.equal(unchanged, claimed)
            end,
        },
        {
            name = "questSnapshot reports progress, threshold, and claimed state for every quest",
            run = function()
                local profile = SaveSchema.normalize({
                    town = { nightNumber = 4 },
                }, 100)
                local snapshot = SaveSchema.questSnapshot(profile)
                local byId = {}
                for _, quest in snapshot do
                    byId[quest.id] = quest
                end
                TestRunner.equal(byId.quest_survive_three_nights.progress, 3)
                TestRunner.equal(byId.quest_survive_three_nights.threshold, 3)
                TestRunner.equal(byId.quest_survive_three_nights.complete, true)
                TestRunner.equal(byId.quest_survive_three_nights.claimed, false)
            end,
        },
        {
            name = "migrates schema nine profiles into empty recovery state",
            run = function()
                local profile = SaveSchema.normalize({ schemaVersion = 9 }, 100)
                TestRunner.equal(profile.schemaVersion, 10)
                TestRunner.equal(SaveSchema.expeditionRecovery(profile), nil)
                TestRunner.equal(#profile.inventory.recoveryOrder, 0)
            end,
        },
        {
            name = "persists failure cache and recovery through schema wrappers",
            run = function()
                local profile = SaveSchema.default(1)
                profile = SaveSchema.withUnbankedExpeditionReward(
                    profile,
                    "reward_a",
                    "hash",
                    { materialId = "material_heartwood", amount = 2 },
                    2
                )
                profile = SaveSchema.withUnbankedExpeditionReward(
                    profile,
                    "reward_b",
                    "hash",
                    { materialId = "material_brightcap", amount = 3 },
                    3
                )
                local pending = SaveSchema.expeditionPending(profile)
                local cacheId = SaveSchema.expeditionRecoveryCacheId("run", 12, pending.fingerprint)
                local cached, cacheResult =
                    SaveSchema.withExpeditionFailureCache(profile, cacheId, "hash", 4)
                TestRunner.equal(cacheResult.applied, true)
                TestRunner.equal(SaveSchema.expeditionRecovery(cached).cacheId, cacheId)
                local recovered, recoveryResult =
                    SaveSchema.withRecoveredExpeditionCache(cached, cacheId, 5)
                TestRunner.equal(recoveryResult.applied, true)
                TestRunner.equal(SaveSchema.expeditionRecovery(recovered), nil)
                TestRunner.equal(SaveSchema.expeditionPending(recovered).count, 2)
            end,
        },
    },
}
