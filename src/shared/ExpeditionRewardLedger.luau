--!strict

local ExpeditionRewardLedger = {}

function ExpeditionRewardLedger.create(): any
    return {
        users = {},
    }
end

function ExpeditionRewardLedger.grant(
    ledger: any,
    userId: number,
    transactionId: string,
    reward: any
): (boolean, any)
    assert(type(userId) == "number" and userId > 0, "reward user ID is invalid")
    assert(
        type(transactionId) == "string" and transactionId ~= "",
        "reward transaction ID is required"
    )
    assert(
        type(reward) == "table"
            and type(reward.materialId) == "string"
            and string.sub(reward.materialId, 1, 9) == "material_"
            and type(reward.amount) == "number"
            and reward.amount >= 1
            and reward.amount == math.floor(reward.amount),
        "reward contract is invalid"
    )

    local userLedger = ledger.users[userId]
    if userLedger == nil then
        userLedger = {
            materials = {},
            transactions = {},
        }
        ledger.users[userId] = userLedger
    end
    local prior = userLedger.transactions[transactionId]
    if prior ~= nil then
        return false, table.clone(prior)
    end

    local result = {
        amount = reward.amount,
        materialId = reward.materialId,
        transactionId = transactionId,
        userId = userId,
    }
    userLedger.transactions[transactionId] = result
    userLedger.materials[reward.materialId] = (userLedger.materials[reward.materialId] or 0)
        + reward.amount
    return true, table.clone(result)
end

function ExpeditionRewardLedger.snapshot(ledger: any, userId: number): any
    local userLedger = ledger.users[userId]
    return {
        materials = if userLedger == nil then {} else table.clone(userLedger.materials),
        transactionCount = if userLedger == nil
            then 0
            else (function(): number
                local count = 0
                for _ in userLedger.transactions do
                    count += 1
                end
                return count
            end)(),
    }
end

return table.freeze(ExpeditionRewardLedger)
