--!strict

local ExpeditionRewardLedger = require("../../src/shared/ExpeditionRewardLedger")
local TestRunner = require("../TestRunner")

local HEARTWOOD = {
    materialId = "material_heartwood",
    amount = 4,
}

return {
    name = "ExpeditionRewardLedger",
    cases = {
        {
            name = "grants one material transaction exactly once",
            run = function()
                local ledger = ExpeditionRewardLedger.create()
                local granted = ExpeditionRewardLedger.grant(
                    ledger,
                    42,
                    "event_reward:hash:event",
                    "hash",
                    HEARTWOOD
                )
                local duplicate, prior = ExpeditionRewardLedger.grant(
                    ledger,
                    42,
                    "event_reward:hash:event",
                    "hash",
                    HEARTWOOD
                )
                local snapshot = ExpeditionRewardLedger.snapshot(ledger, 42)

                TestRunner.equal(granted, true)
                TestRunner.equal(duplicate, false)
                TestRunner.equal(prior.amount, 4)
                TestRunner.equal(snapshot.materials.material_heartwood, 4)
                TestRunner.equal(snapshot.transactionCount, 1)
            end,
        },
        {
            name = "isolates rewards by participant and transaction",
            run = function()
                local ledger = ExpeditionRewardLedger.create()
                ExpeditionRewardLedger.grant(ledger, 1, "transaction_a", "hash", HEARTWOOD)
                ExpeditionRewardLedger.grant(ledger, 1, "transaction_b", "hash", HEARTWOOD)
                ExpeditionRewardLedger.grant(ledger, 2, "transaction_a", "hash", HEARTWOOD)

                TestRunner.equal(
                    ExpeditionRewardLedger.snapshot(ledger, 1).materials.material_heartwood,
                    8
                )
                TestRunner.equal(
                    ExpeditionRewardLedger.snapshot(ledger, 2).materials.material_heartwood,
                    4
                )
            end,
        },
        {
            name = "rejects malformed grants before mutating value",
            run = function()
                local ledger = ExpeditionRewardLedger.create()
                TestRunner.throws(function()
                    ExpeditionRewardLedger.grant(ledger, 5, "", "hash", HEARTWOOD)
                end, "transaction ID")
                TestRunner.throws(function()
                    ExpeditionRewardLedger.grant(ledger, 5, "transaction", "hash", {
                        materialId = "coins",
                        amount = -1,
                    })
                end, "reward contract")
                TestRunner.equal(ExpeditionRewardLedger.snapshot(ledger, 5).transactionCount, 0)
            end,
        },
        {
            name = "settles only the selected session transactions",
            run = function()
                local ledger = ExpeditionRewardLedger.create()
                ExpeditionRewardLedger.grant(ledger, 8, "transaction_a", "hash", HEARTWOOD)
                ExpeditionRewardLedger.grant(ledger, 8, "transaction_b", "hash", HEARTWOOD)

                local settled =
                    ExpeditionRewardLedger.settle(ledger, 8, "settlement_a", { "transaction_a" })
                local pending = ExpeditionRewardLedger.pending(ledger, 8)
                TestRunner.equal(settled, true)
                TestRunner.equal(pending.transactionCount, 1)
                TestRunner.equal(pending.transactionIds[1], "transaction_b")
                TestRunner.equal(pending.materials.material_heartwood, 4)

                local duplicate =
                    ExpeditionRewardLedger.settle(ledger, 8, "settlement_a", { "transaction_a" })
                TestRunner.equal(duplicate, false)
                TestRunner.equal(
                    ExpeditionRewardLedger.pending(ledger, 8).materials.material_heartwood,
                    4
                )
            end,
        },
    },
}
