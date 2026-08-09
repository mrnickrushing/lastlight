--!strict
--[[
    Expedition contracts: the party names its risk before the platform
    launches, and Bramblewake answers in kind.

    Milestone 5's "contracts and risk modifiers" deliverable, kept pure. A
    contract trades risk for reward inside tight bounds — enemies hit
    harder, the pouch pays better — and the exchange is always earned in
    play, never purchasable. Weather is the contract's face: the sky tells
    the party what they signed.

    Multiplier bounds are deliberate: 0.75–1.5 keeps every contract inside
    the same clamp the combat code already trusts, so no contract can turn
    an enemy into a one-shot or a reward into an economy leak.
]]

local Strings = require("./Strings")

local ExpeditionContracts = {}

export type Contract = {
    id: string,
    title: string,
    detail: string,
    rewardMultiplier: number,
    enemyDamageMultiplier: number,
    weather: string,
}

local CONTRACTS: { Contract } = table.freeze({
    table.freeze({
        id = "contract_standard",
        title = Strings.get("expedition.standard_sweep"),
        detail = Strings.get("expedition.the_woods_as_they_are_even"),
        rewardMultiplier = 1,
        enemyDamageMultiplier = 1,
        weather = "clear",
    }),
    table.freeze({
        id = "contract_quiet_roads",
        title = Strings.get("expedition.quiet_roads"),
        detail = Strings.get("expedition.mist_keeps_the_worst_asleep_lighter"),
        rewardMultiplier = 0.75,
        enemyDamageMultiplier = 0.8,
        weather = "mist",
    }),
    table.freeze({
        id = "contract_storm_salvage",
        title = Strings.get("expedition.storm_salvage"),
        detail = Strings.get("expedition.rain_wakes_the_roots_what_you"),
        rewardMultiplier = 1.25,
        enemyDamageMultiplier = 1.2,
        weather = "storm",
    }),
    table.freeze({
        id = "contract_deep_growth",
        title = Strings.get("expedition.deep_growth"),
        detail = Strings.get("expedition.the_forest_at_full_strength_the"),
        rewardMultiplier = 1.5,
        enemyDamageMultiplier = 1.35,
        weather = "spores",
    }),
})

local CONTRACTS_BY_ID: { [string]: Contract } = {}
for _, contract in CONTRACTS do
    CONTRACTS_BY_ID[contract.id] = contract
end
table.freeze(CONTRACTS_BY_ID)

ExpeditionContracts.List = CONTRACTS

function ExpeditionContracts.get(id: any): Contract?
    if type(id) ~= "string" then
        return nil
    end
    return CONTRACTS_BY_ID[id]
end

function ExpeditionContracts.default(): Contract
    return CONTRACTS[1]
end

-- Unknown or absent ids resolve to the standard sweep: a malformed request
-- never earns more risk or more reward than the even trade.
function ExpeditionContracts.resolve(id: any): Contract
    return ExpeditionContracts.get(id) or ExpeditionContracts.default()
end

function ExpeditionContracts.applyReward(contract: Contract, amount: number): number
    if type(amount) ~= "number" or amount <= 0 then
        return 0
    end
    return math.max(1, math.ceil(amount * contract.rewardMultiplier))
end

return table.freeze(ExpeditionContracts)
