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
                local granted =
                    ExpeditionRewardLedger.grant(ledger, 42, "event_reward:hash:event", HEARTWOOD)
                local duplicate, prior =
                    ExpeditionRewardLedger.grant(ledger, 42, "event_reward:hash:event", HEARTWOOD)
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
                ExpeditionRewardLedger.grant(ledger, 1, "transaction_a", HEARTWOOD)
                ExpeditionRewardLedger.grant(ledger, 1, "transaction_b", HEARTWOOD)
                ExpeditionRewardLedger.grant(ledger, 2, "transaction_a", HEARTWOOD)

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
                    ExpeditionRewardLedger.grant(ledger, 5, "", HEARTWOOD)
                end, "transaction ID")
                TestRunner.throws(function()
                    ExpeditionRewardLedger.grant(ledger, 5, "transaction", {
                        materialId = "coins",
                        amount = -1,
                    })
                end, "reward contract")
                TestRunner.equal(ExpeditionRewardLedger.snapshot(ledger, 5).transactionCount, 0)
            end,
        },
    },
}
