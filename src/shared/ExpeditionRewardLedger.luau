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
    manifestHash: string,
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
            -- Infinity satisfies both of the checks below on its own: it is
            -- greater than one, and math.floor of it is itself. Without this
            -- line an infinite amount was a valid reward.
            and reward.amount < math.huge
            and reward.amount >= 1
            and reward.amount == math.floor(reward.amount),
        "reward contract is invalid"
    )

    local userLedger = ledger.users[userId]
    if userLedger == nil then
        userLedger = {
            materials = {},
            settlements = {},
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
        manifestHash = manifestHash,
        materialId = reward.materialId,
        settled = false,
        transactionId = transactionId,
        userId = userId,
    }
    userLedger.transactions[transactionId] = result
    userLedger.materials[reward.materialId] = (userLedger.materials[reward.materialId] or 0)
        + reward.amount
    return true, table.clone(result)
end

function ExpeditionRewardLedger.pending(ledger: any, userId: number): any
    local userLedger = ledger.users[userId]
    local rewards = {}
    local transactionIds = {}
    if userLedger ~= nil then
        for transactionId, record in userLedger.transactions do
            if record.settled ~= true then
                table.insert(transactionIds, transactionId)
                table.insert(rewards, {
                    amount = record.amount,
                    manifestHash = record.manifestHash,
                    materialId = record.materialId,
                    transactionId = transactionId,
                })
            end
        end
    end
    table.sort(transactionIds)
    table.sort(rewards, function(left: any, right: any): boolean
        return left.transactionId < right.transactionId
    end)
    return {
        materials = if userLedger == nil then {} else table.clone(userLedger.materials),
        rewards = rewards,
        transactionCount = #transactionIds,
        transactionIds = transactionIds,
    }
end

function ExpeditionRewardLedger.settle(
    ledger: any,
    userId: number,
    settlementId: string,
    transactionIds: { string }
): (boolean, any)
    local userLedger = ledger.users[userId]
    if userLedger == nil then
        return false, {
            empty = true,
        }
    end
    local existing = userLedger.settlements[settlementId]
    if existing ~= nil then
        return false, table.clone(existing)
    end

    local settledIds = {}
    for _, transactionId in transactionIds do
        local record = userLedger.transactions[transactionId]
        if record ~= nil and record.settled ~= true then
            record.settled = true
            userLedger.materials[record.materialId] =
                math.max(0, (userLedger.materials[record.materialId] or 0) - record.amount)
            table.insert(settledIds, transactionId)
        end
    end
    local result = {
        settlementId = settlementId,
        transactionIds = settledIds,
    }
    userLedger.settlements[settlementId] = result
    return #settledIds > 0, table.clone(result)
end

function ExpeditionRewardLedger.snapshot(ledger: any, userId: number): any
    return ExpeditionRewardLedger.pending(ledger, userId)
end

return table.freeze(ExpeditionRewardLedger)
