--!strict

local ExpeditionContracts = require("../../src/shared/ExpeditionContracts")
local TestRunner = require("../TestRunner")

return {
    name = "ExpeditionContracts",
    cases = {
        {
            name = "every contract stays inside the trusted multiplier bounds",
            run = function()
                TestRunner.equal(#ExpeditionContracts.List >= 4, true)
                for _, contract in ExpeditionContracts.List do
                    TestRunner.equal(ExpeditionContracts.get(contract.id), contract)
                    TestRunner.equal(#contract.title > 0, true)
                    TestRunner.equal(#contract.detail > 0, true)
                    TestRunner.equal(#contract.weather > 0, true)
                    TestRunner.equal(
                        contract.rewardMultiplier >= 0.75 and contract.rewardMultiplier <= 1.5,
                        true
                    )
                    TestRunner.equal(
                        contract.enemyDamageMultiplier >= 0.75
                            and contract.enemyDamageMultiplier <= 1.5,
                        true
                    )
                end
            end,
        },
        {
            name = "risk and reward move together",
            run = function()
                -- No contract may pay more while hurting less than standard:
                -- that would be a free lunch, and free lunches get farmed.
                for _, contract in ExpeditionContracts.List do
                    if contract.rewardMultiplier > 1 then
                        TestRunner.truthy(
                            contract.enemyDamageMultiplier > 1,
                            contract.id .. " pays extra without extra risk"
                        )
                    end
                    if contract.rewardMultiplier < 1 then
                        TestRunner.truthy(
                            contract.enemyDamageMultiplier < 1,
                            contract.id .. " charges a discount without giving one"
                        )
                    end
                end
            end,
        },
        {
            name = "junk resolves to the standard sweep, never more",
            run = function()
                TestRunner.equal(ExpeditionContracts.resolve(nil).id, "contract_standard")
                TestRunner.equal(
                    ExpeditionContracts.resolve("contract_nope").id,
                    "contract_standard"
                )
                TestRunner.equal(ExpeditionContracts.resolve(42).id, "contract_standard")
                TestRunner.equal(
                    ExpeditionContracts.resolve("contract_deep_growth").id,
                    "contract_deep_growth"
                )
            end,
        },
        {
            name = "reward application rounds up and never zeroes an earned reward",
            run = function()
                local quiet = ExpeditionContracts.resolve("contract_quiet_roads")
                local deep = ExpeditionContracts.resolve("contract_deep_growth")
                TestRunner.equal(ExpeditionContracts.applyReward(quiet, 1), 1)
                TestRunner.equal(ExpeditionContracts.applyReward(quiet, 4), 3)
                TestRunner.equal(ExpeditionContracts.applyReward(deep, 4), 6)
                TestRunner.equal(ExpeditionContracts.applyReward(deep, 0), 0)
                TestRunner.equal(ExpeditionContracts.applyReward(deep, -3), 0)
            end,
        },
    },
}
