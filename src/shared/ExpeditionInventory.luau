--!strict

local ExpeditionInventory = {}

local MAX_MATERIAL_STACK = 999999
local MAX_REWARD_AMOUNT = 100
local MAX_REWARD_TRANSACTIONS = 512
local MAX_SETTLEMENTS = 128
local HASH_MODULUS = 2147483647
local HASH_MULTIPLIER = 33

local KNOWN_MATERIALS = table.freeze({
    material_amber_sap = true,
    material_brightcap = true,
    material_heartwood = true,
    material_meadow_fiber = true,
    material_spring_clay = true,
})

local function hashText(hash: number, value: string): number
    local result = hash
    for index = 1, #value do
        result = (result * HASH_MULTIPLIER + string.byte(value, index)) % HASH_MODULUS
    end
    return result
end

local function validMaterialId(materialId: any): boolean
    return type(materialId) == "string" and KNOWN_MATERIALS[materialId] == true
end

local function validTransactionId(transactionId: any): boolean
    return type(transactionId) == "string" and transactionId ~= "" and #transactionId <= 180
end

local function cloneInventory(inventory: any): any
    return {
        materials = table.clone(inventory.materials),
        expeditionRewards = table.clone(inventory.expeditionRewards),
        rewardOrder = table.clone(inventory.rewardOrder),
        settlements = table.clone(inventory.settlements),
        settlementOrder = table.clone(inventory.settlementOrder),
    }
end

local function makeRewardSpace(inventory: any): boolean
    while #inventory.rewardOrder >= MAX_REWARD_TRANSACTIONS do
        local removeIndex = nil
        for index, transactionId in inventory.rewardOrder do
            local record = inventory.expeditionRewards[transactionId]
            if record ~= nil and record.status == "settled" then
                removeIndex = index
                break
            end
        end
        if removeIndex == nil then
            return false
        end
        local removedTransactionId = table.remove(inventory.rewardOrder, removeIndex)
        inventory.expeditionRewards[removedTransactionId] = nil
    end
    return true
end

local function normalizeMaterials(value: any): { [string]: number }
    local materials: { [string]: number } = {}
    if type(value) ~= "table" then
        return materials
    end
    for materialId, amount in value do
        if validMaterialId(materialId) and type(amount) == "number" and amount >= 0 then
            materials[materialId] = math.clamp(math.floor(amount), 0, MAX_MATERIAL_STACK)
        end
    end
    return materials
end

local function normalizeTransactionIds(value: any): { string }
    local transactionIds = {}
    local seen: { [string]: boolean } = {}
    if type(value) ~= "table" then
        return transactionIds
    end
    for _, transactionId in value do
        if #transactionIds >= MAX_REWARD_TRANSACTIONS then
            break
        end
        if validTransactionId(transactionId) and not seen[transactionId] then
            seen[transactionId] = true
            table.insert(transactionIds, transactionId)
        end
    end
    return transactionIds
end

function ExpeditionInventory.default(): any
    return {
        materials = {},
        expeditionRewards = {},
        rewardOrder = {},
        settlements = {},
        settlementOrder = {},
    }
end

function ExpeditionInventory.normalize(value: any): any
    local inventory = ExpeditionInventory.default()
    if type(value) ~= "table" then
        return inventory
    end

    inventory.materials = normalizeMaterials(value.materials)
    if type(value.expeditionRewards) == "table" and type(value.rewardOrder) == "table" then
        for _, transactionId in value.rewardOrder do
            if #inventory.rewardOrder >= MAX_REWARD_TRANSACTIONS then
                break
            end
            local record = value.expeditionRewards[transactionId]
            if
                validTransactionId(transactionId)
                and type(record) == "table"
                and validMaterialId(record.materialId)
                and type(record.amount) == "number"
                and record.amount >= 1
                and record.amount <= MAX_REWARD_AMOUNT
                and (record.status == "unbanked" or record.status == "settled")
                and inventory.expeditionRewards[transactionId] == nil
            then
                inventory.expeditionRewards[transactionId] = {
                    amount = math.floor(record.amount),
                    grantedAt = if type(record.grantedAt) == "number"
                        then math.floor(record.grantedAt)
                        else 0,
                    manifestHash = if type(record.manifestHash) == "string"
                        then string.sub(record.manifestHash, 1, 32)
                        else "unknown",
                    materialId = record.materialId,
                    settledBy = if type(record.settledBy) == "string"
                        then string.sub(record.settledBy, 1, 180)
                        else nil,
                    status = record.status,
                }
                table.insert(inventory.rewardOrder, transactionId)
            end
        end
    end

    if type(value.settlements) == "table" and type(value.settlementOrder) == "table" then
        for _, settlementId in value.settlementOrder do
            if #inventory.settlementOrder >= MAX_SETTLEMENTS then
                break
            end
            local record = value.settlements[settlementId]
            if
                validTransactionId(settlementId)
                and type(record) == "table"
                and inventory.settlements[settlementId] == nil
            then
                inventory.settlements[settlementId] = {
                    manifestHash = if type(record.manifestHash) == "string"
                        then string.sub(record.manifestHash, 1, 32)
                        else "unknown",
                    materials = normalizeMaterials(record.materials),
                    rewardTransactionIds = normalizeTransactionIds(record.rewardTransactionIds),
                    settledAt = if type(record.settledAt) == "number"
                        then math.floor(record.settledAt)
                        else 0,
                }
                table.insert(inventory.settlementOrder, settlementId)
            end
        end
    end
    return inventory
end

function ExpeditionInventory.addUnbanked(
    inventory: any,
    transactionId: string,
    manifestHash: string,
    reward: any,
    now: number
): (any, any)
    if not validTransactionId(transactionId) then
        return inventory,
            {
                applied = false,
                reason = "invalid_transaction",
            }
    end
    if
        type(reward) ~= "table"
        or not validMaterialId(reward.materialId)
        or type(reward.amount) ~= "number"
        or reward.amount < 1
        or reward.amount > MAX_REWARD_AMOUNT
        or reward.amount ~= math.floor(reward.amount)
    then
        return inventory,
            {
                applied = false,
                reason = "invalid_reward",
            }
    end

    local existing = inventory.expeditionRewards[transactionId]
    if existing ~= nil then
        return inventory,
            {
                applied = false,
                duplicate = true,
                record = table.clone(existing),
            }
    end
    local nextInventory = cloneInventory(inventory)
    if not makeRewardSpace(nextInventory) then
        return inventory,
            {
                applied = false,
                reason = "unbanked_pouch_full",
            }
    end
    local record = {
        amount = reward.amount,
        grantedAt = math.floor(now),
        manifestHash = string.sub(manifestHash, 1, 32),
        materialId = reward.materialId,
        settledBy = nil,
        status = "unbanked",
    }
    nextInventory.expeditionRewards[transactionId] = record
    table.insert(nextInventory.rewardOrder, transactionId)
    return nextInventory, {
        applied = true,
        record = table.clone(record),
    }
end

function ExpeditionInventory.pending(inventory: any): any
    local materials: { [string]: number } = {}
    local rewards = {}
    local transactionIds = {}
    for _, transactionId in inventory.rewardOrder do
        local record = inventory.expeditionRewards[transactionId]
        if record ~= nil and record.status == "unbanked" then
            materials[record.materialId] = (materials[record.materialId] or 0) + record.amount
            table.insert(transactionIds, transactionId)
            table.insert(rewards, {
                amount = record.amount,
                manifestHash = record.manifestHash,
                materialId = record.materialId,
                transactionId = transactionId,
            })
        end
    end
    table.sort(transactionIds)
    table.sort(rewards, function(left: any, right: any): boolean
        return left.transactionId < right.transactionId
    end)

    local hash = 5381
    for _, transactionId in transactionIds do
        hash = hashText(hash, "|" .. transactionId)
    end
    return {
        count = #transactionIds,
        fingerprint = string.format("%08x", hash),
        materials = materials,
        rewards = rewards,
        transactionIds = transactionIds,
    }
end

function ExpeditionInventory.settlementId(
    runId: string,
    userId: number,
    pendingFingerprint: string
): string
    assert(type(runId) == "string" and runId ~= "", "expedition run ID is required")
    assert(userId > 0, "settlement user ID is invalid")
    return string.format(
        "expedition_settlement:%s:%d:%s",
        string.sub(runId, 1, 64),
        userId,
        pendingFingerprint
    )
end

function ExpeditionInventory.settle(
    inventory: any,
    settlementId: string,
    manifestHash: string,
    now: number
): (any, any)
    if not validTransactionId(settlementId) then
        return inventory,
            {
                applied = false,
                reason = "invalid_settlement",
            }
    end
    local existing = inventory.settlements[settlementId]
    if existing ~= nil then
        return inventory,
            {
                applied = false,
                duplicate = true,
                record = table.clone(existing),
            }
    end

    local pending = ExpeditionInventory.pending(inventory)
    if pending.count == 0 then
        return inventory, {
            applied = false,
            empty = true,
        }
    end

    local nextInventory = cloneInventory(inventory)
    for materialId, amount in pending.materials do
        nextInventory.materials[materialId] =
            math.min(MAX_MATERIAL_STACK, (nextInventory.materials[materialId] or 0) + amount)
    end
    for _, transactionId in pending.transactionIds do
        local record = table.clone(nextInventory.expeditionRewards[transactionId])
        record.status = "settled"
        record.settledBy = settlementId
        nextInventory.expeditionRewards[transactionId] = record
    end

    local settlementRecord = {
        manifestHash = string.sub(manifestHash, 1, 32),
        materials = table.clone(pending.materials),
        rewardTransactionIds = table.clone(pending.transactionIds),
        settledAt = math.floor(now),
    }
    nextInventory.settlements[settlementId] = settlementRecord
    table.insert(nextInventory.settlementOrder, settlementId)
    if #nextInventory.settlementOrder > MAX_SETTLEMENTS then
        local oldest = table.remove(nextInventory.settlementOrder, 1)
        nextInventory.settlements[oldest] = nil
    end

    return nextInventory,
        {
            applied = true,
            record = table.clone(settlementRecord),
        }
end

function ExpeditionInventory.hasSettlement(inventory: any, settlementId: string): boolean
    return inventory.settlements[settlementId] ~= nil
end

function ExpeditionInventory.hasReward(inventory: any, transactionId: string): boolean
    return inventory.expeditionRewards[transactionId] ~= nil
end

function ExpeditionInventory.findSettlementForRewards(
    inventory: any,
    rewardTransactionIds: { string }
): (string?, any?)
    if #rewardTransactionIds == 0 then
        return nil, nil
    end
    local wanted: { [string]: boolean } = {}
    for _, transactionId in rewardTransactionIds do
        wanted[transactionId] = true
    end
    for index = #inventory.settlementOrder, 1, -1 do
        local settlementId = inventory.settlementOrder[index]
        local record = inventory.settlements[settlementId]
        local found = 0
        if record ~= nil then
            for _, transactionId in record.rewardTransactionIds do
                if wanted[transactionId] then
                    found += 1
                end
            end
        end
        if found == #rewardTransactionIds then
            return settlementId, table.clone(record)
        end
    end
    return nil, nil
end

return table.freeze(ExpeditionInventory)
