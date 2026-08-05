--!strict

local ExpeditionInventory = require("../../src/shared/ExpeditionInventory")
local TestRunner = require("../TestRunner")

local HEARTWOOD = {
    materialId = "material_heartwood",
    amount = 4,
}

return {
    name = "ExpeditionInventory",
    cases = {
        {
            name = "normalizes only known bounded material state",
            run = function()
                local inventory = ExpeditionInventory.normalize({
                    materials = {
                        material_heartwood = 12.9,
                        material_brightcap = -4,
                        robux = 999999,
                    },
                    expeditionRewards = "forged",
                })
                TestRunner.equal(inventory.materials.material_heartwood, 12)
                TestRunner.equal(inventory.materials.material_brightcap, nil)
                TestRunner.equal(inventory.materials.robux, nil)
                TestRunner.equal(#inventory.rewardOrder, 0)
            end,
        },
        {
            name = "records each unbanked reward transaction once",
            run = function()
                local inventory = ExpeditionInventory.default()
                local granted, result = ExpeditionInventory.addUnbanked(
                    inventory,
                    "event_reward:run:hash:event",
                    "hash",
                    HEARTWOOD,
                    100
                )
                local duplicate, duplicateResult = ExpeditionInventory.addUnbanked(
                    granted,
                    "event_reward:run:hash:event",
                    "hash",
                    HEARTWOOD,
                    200
                )

                TestRunner.equal(result.applied, true)
                TestRunner.equal(duplicateResult.duplicate, true)
                TestRunner.equal(duplicate, granted)
                TestRunner.equal(
                    ExpeditionInventory.pending(granted).materials.material_heartwood,
                    4
                )
            end,
        },
        {
            name = "atomically banks the pouch and makes settlement retry idempotent",
            run = function()
                local inventory = ExpeditionInventory.default()
                inventory = ExpeditionInventory.addUnbanked(
                    inventory,
                    "event_reward:run:hash:event_a",
                    "hash",
                    HEARTWOOD,
                    100
                )
                inventory = ExpeditionInventory.addUnbanked(
                    inventory,
                    "event_reward:run:hash:event_b",
                    "hash",
                    {
                        materialId = "material_brightcap",
                        amount = 2,
                    },
                    101
                )
                local pending = ExpeditionInventory.pending(inventory)
                local settlementId =
                    ExpeditionInventory.settlementId("run", 42, pending.fingerprint)
                local settled, result =
                    ExpeditionInventory.settle(inventory, settlementId, "hash", 120)
                local replay, replayResult =
                    ExpeditionInventory.settle(settled, settlementId, "hash", 130)

                TestRunner.equal(result.applied, true)
                TestRunner.equal(settled.materials.material_heartwood, 4)
                TestRunner.equal(settled.materials.material_brightcap, 2)
                TestRunner.equal(ExpeditionInventory.pending(settled).count, 0)
                TestRunner.equal(replayResult.duplicate, true)
                TestRunner.equal(replay, settled)
                TestRunner.equal(replay.materials.material_heartwood, 4)
            end,
        },
        {
            name = "the storage cap binds and overflow is reported, never silent",
            run = function()
                local inventory = ExpeditionInventory.default()
                inventory = ExpeditionInventory.addUnbanked(
                    inventory,
                    "event_reward:capped:hash:event_a",
                    "hash",
                    { materialId = "material_heartwood", amount = 10 },
                    100
                )
                local pending = ExpeditionInventory.pending(inventory)
                local settlementId =
                    ExpeditionInventory.settlementId("capped", 7, pending.fingerprint)
                local settled, result =
                    ExpeditionInventory.settle(inventory, settlementId, "hash", 120, 6)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(settled.materials.material_heartwood, 6)
                TestRunner.equal(result.overflowTotal, 4)
                TestRunner.equal((result.record.overflow :: any).material_heartwood, 4)

                -- Without a cap the old behaviour is untouched.
                local roomy = ExpeditionInventory.default()
                roomy = ExpeditionInventory.addUnbanked(
                    roomy,
                    "event_reward:roomy:hash:event_a",
                    "hash",
                    { materialId = "material_heartwood", amount = 10 },
                    100
                )
                local roomyPending = ExpeditionInventory.pending(roomy)
                local roomyId =
                    ExpeditionInventory.settlementId("roomy", 7, roomyPending.fingerprint)
                local roomySettled, roomyResult =
                    ExpeditionInventory.settle(roomy, roomyId, "hash", 120)
                TestRunner.equal(roomySettled.materials.material_heartwood, 10)
                TestRunner.equal(roomyResult.overflowTotal, 0)
                TestRunner.equal(roomyResult.record.overflow, nil)
            end,
        },
        {
            name = "rejects unknown materials without changing the pouch",
            run = function()
                local inventory = ExpeditionInventory.default()
                local unchanged, result =
                    ExpeditionInventory.addUnbanked(inventory, "transaction", "hash", {
                        materialId = "material_admin_currency",
                        amount = 99,
                    }, 100)
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.reason, "invalid_reward")
                TestRunner.equal(unchanged, inventory)
            end,
        },
        {
            name = "finds a completed settlement by its source reward transactions",
            run = function()
                local inventory = ExpeditionInventory.default()
                inventory =
                    ExpeditionInventory.addUnbanked(inventory, "reward_a", "hash", HEARTWOOD, 1)
                local pending = ExpeditionInventory.pending(inventory)
                local settlementId = ExpeditionInventory.settlementId("run", 9, pending.fingerprint)
                inventory = ExpeditionInventory.settle(inventory, settlementId, "hash", 2)

                local foundId, foundRecord =
                    ExpeditionInventory.findSettlementForRewards(inventory, { "reward_a" })
                TestRunner.equal(foundId, settlementId)
                TestRunner.equal(foundRecord.materials.material_heartwood, 4)
            end,
        },
        {
            name = "rotates old settled reward tombstones without dropping an unbanked pouch",
            run = function()
                local serialized = {
                    materials = {},
                    expeditionRewards = {},
                    rewardOrder = {},
                    settlements = {},
                    settlementOrder = {},
                }
                for index = 1, 512 do
                    local transactionId = string.format("settled_%03d", index)
                    serialized.expeditionRewards[transactionId] = {
                        amount = 1,
                        grantedAt = index,
                        manifestHash = "old",
                        materialId = "material_heartwood",
                        settledBy = "settlement_old",
                        status = "settled",
                    }
                    table.insert(serialized.rewardOrder, transactionId)
                end

                local inventory = ExpeditionInventory.normalize(serialized)
                local rotated, result =
                    ExpeditionInventory.addUnbanked(inventory, "reward_new", "new", HEARTWOOD, 600)

                TestRunner.equal(result.applied, true)
                TestRunner.equal(#rotated.rewardOrder, 512)
                TestRunner.equal(rotated.expeditionRewards.settled_001, nil)
                TestRunner.truthy(rotated.expeditionRewards.reward_new)
                TestRunner.equal(ExpeditionInventory.pending(rotated).count, 1)
            end,
        },
        {
            name = "moves deterministic half of a failed pouch into recovery",
            run = function()
                local inventory = ExpeditionInventory.default()
                for index = 1, 4 do
                    inventory = ExpeditionInventory.addUnbanked(
                        inventory,
                        "reward_" .. tostring(index),
                        "hash",
                        { materialId = "material_heartwood", amount = index },
                        index
                    )
                end
                local pending = ExpeditionInventory.pending(inventory)
                local cacheId = ExpeditionInventory.recoveryCacheId("run", 7, pending.fingerprint)
                local cached, result =
                    ExpeditionInventory.cacheAfterFailure(inventory, cacheId, "hash", 20)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(result.retained, 2)
                TestRunner.equal(#result.transactionIds, 2)
                TestRunner.equal(ExpeditionInventory.pending(cached).count, 2)
                TestRunner.equal(ExpeditionInventory.activeRecovery(cached).cacheId, cacheId)
            end,
        },
        {
            name = "retains a one-reward pouch instead of creating total loss",
            run = function()
                local inventory = ExpeditionInventory.default()
                inventory =
                    ExpeditionInventory.addUnbanked(inventory, "only_reward", "hash", HEARTWOOD, 1)
                local unchanged, result = ExpeditionInventory.cacheAfterFailure(
                    inventory,
                    "expedition_cache:run:7:one",
                    "hash",
                    2
                )
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.reason, "insufficient_pouch")
                TestRunner.equal(unchanged, inventory)
                TestRunner.equal(ExpeditionInventory.pending(unchanged).count, 1)
            end,
        },
        {
            name = "recovers cached transactions exactly once into the pouch",
            run = function()
                local inventory = ExpeditionInventory.default()
                inventory =
                    ExpeditionInventory.addUnbanked(inventory, "reward_a", "hash", HEARTWOOD, 1)
                inventory =
                    ExpeditionInventory.addUnbanked(inventory, "reward_b", "hash", HEARTWOOD, 2)
                local cacheId = "expedition_cache:run:7:pair"
                inventory = ExpeditionInventory.cacheAfterFailure(inventory, cacheId, "hash", 3)
                local recovered, result = ExpeditionInventory.recover(inventory, cacheId, 4)
                local replay, replayResult = ExpeditionInventory.recover(recovered, cacheId, 5)
                TestRunner.equal(result.applied, true)
                TestRunner.equal(ExpeditionInventory.pending(recovered).count, 2)
                TestRunner.equal(ExpeditionInventory.activeRecovery(recovered), nil)
                TestRunner.equal(replay, recovered)
                TestRunner.equal(replayResult.duplicate, true)
                TestRunner.equal(replayResult.materials.material_heartwood, 4)
                TestRunner.equal(#replayResult.transactionIds, 1)
            end,
        },
        {
            name = "normalizes only caches backed by matching cached rewards",
            run = function()
                local restored = ExpeditionInventory.normalize({
                    materials = {},
                    expeditionRewards = {
                        reward_a = {
                            amount = 2,
                            cacheId = "cache_a",
                            grantedAt = 1,
                            manifestHash = "hash",
                            materialId = "material_brightcap",
                            status = "cached",
                        },
                    },
                    rewardOrder = { "reward_a" },
                    recoveryCaches = {
                        cache_a = {
                            createdAt = 2,
                            manifestHash = "hash",
                            rewardTransactionIds = { "reward_a" },
                            status = "active",
                        },
                        forged = {
                            rewardTransactionIds = { "missing" },
                            status = "active",
                        },
                    },
                    recoveryOrder = { "cache_a", "forged" },
                    settlements = {},
                    settlementOrder = {},
                })
                TestRunner.equal(ExpeditionInventory.activeRecovery(restored).cacheId, "cache_a")
                TestRunner.equal(restored.recoveryCaches.forged, nil)
            end,
        },
    },
}
