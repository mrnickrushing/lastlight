--!strict

local ExpeditionInventory = {}

local MAX_MATERIAL_STACK = 999999
local MAX_REWARD_AMOUNT = 100
local MAX_REWARD_TRANSACTIONS = 512
local MAX_SETTLEMENTS = 128
local MAX_RECOVERY_CACHES = 16
local HASH_MODULUS = 2147483647
local HASH_MULTIPLIER = 33

--[[
    Every material the ledger will accept, by region. A material outside
    this list is refused at the grant call, which is what keeps a bad
    reward shape from quietly inventing currency -- the lesson of #212.
]]
local KNOWN_MATERIALS = table.freeze({
    -- Bramblewake
    material_amber_sap = true,
    material_brightcap = true,
    material_heartwood = true,
    material_meadow_fiber = true,
    material_spring_clay = true,
    -- Ironroot Delve
    material_ironroot_ore = true,
    material_coalglass = true,
    material_glow_fungus = true,
    material_machine_oil = true,
    material_echo_crystal = true,
    -- Mireglass Fen
    material_mirror_reed = true,
    material_bog_iron = true,
    material_witchlight_pollen = true,
    material_eel_oil = true,
    material_blackwater_herb = true,
    -- Tempest Reach
    material_storm_glass = true,
    material_salt_kelp = true,
    material_ships_iron = true,
    material_rope_fiber = true,
    material_amberglass = true,
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
        recoveryCaches = table.clone(inventory.recoveryCaches),
        recoveryOrder = table.clone(inventory.recoveryOrder),
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
        recoveryCaches = {},
        recoveryOrder = {},
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
                and (record.status == "unbanked" or record.status == "cached" or record.status == "settled")
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
                    cacheId = if type(record.cacheId) == "string"
                            and validTransactionId(record.cacheId)
                        then record.cacheId
                        else nil,
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
    if type(value.recoveryCaches) == "table" and type(value.recoveryOrder) == "table" then
        for _, cacheId in value.recoveryOrder do
            if #inventory.recoveryOrder >= MAX_RECOVERY_CACHES then
                break
            end
            local record = value.recoveryCaches[cacheId]
            if
                validTransactionId(cacheId)
                and type(record) == "table"
                and (record.status == "active" or record.status == "recovered")
                and inventory.recoveryCaches[cacheId] == nil
            then
                local transactionIds = normalizeTransactionIds(record.rewardTransactionIds)
                local validIds = {}
                for _, transactionId in transactionIds do
                    local reward = inventory.expeditionRewards[transactionId]
                    if
                        record.status == "recovered"
                        or (
                            reward ~= nil
                            and reward.status == "cached"
                            and reward.cacheId == cacheId
                        )
                    then
                        table.insert(validIds, transactionId)
                    end
                end
                if record.status == "recovered" or #validIds > 0 then
                    inventory.recoveryCaches[cacheId] = {
                        createdAt = if type(record.createdAt) == "number"
                            then math.floor(record.createdAt)
                            else 0,
                        manifestHash = if type(record.manifestHash) == "string"
                            then string.sub(record.manifestHash, 1, 32)
                            else "unknown",
                        recoveredAt = if type(record.recoveredAt) == "number"
                            then math.floor(record.recoveredAt)
                            else nil,
                        rewardTransactionIds = validIds,
                        status = record.status,
                    }
                    table.insert(inventory.recoveryOrder, cacheId)
                end
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
        cacheId = nil,
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

local function recoveryMaterials(inventory: any, transactionIds: { string }): { [string]: number }
    local materials: { [string]: number } = {}
    for _, transactionId in transactionIds do
        local reward = inventory.expeditionRewards[transactionId]
        if reward ~= nil then
            materials[reward.materialId] = (materials[reward.materialId] or 0) + reward.amount
        end
    end
    return materials
end

function ExpeditionInventory.recoveryCacheId(
    runId: string,
    userId: number,
    fingerprint: string
): string
    assert(type(runId) == "string" and runId ~= "", "expedition run ID is required")
    assert(userId > 0, "recovery user ID is invalid")
    return string.format(
        "expedition_cache:%s:%d:%s",
        string.sub(runId, 1, 64),
        userId,
        string.sub(fingerprint, 1, 16)
    )
end

function ExpeditionInventory.cacheAfterFailure(
    inventory: any,
    cacheId: string,
    manifestHash: string,
    now: number
): (any, any)
    if not validTransactionId(cacheId) then
        return inventory, { applied = false, reason = "invalid_cache" }
    end
    local existing = inventory.recoveryCaches[cacheId]
    if existing ~= nil then
        return inventory,
            {
                applied = false,
                duplicate = true,
                cacheId = cacheId,
                record = table.clone(existing),
            }
    end
    local pending = ExpeditionInventory.pending(inventory)
    if pending.count < 2 then
        return inventory, { applied = false, reason = "insufficient_pouch" }
    end

    local selected = {}
    local cacheCount = math.floor(pending.count / 2)
    for index = pending.count - cacheCount + 1, pending.count do
        table.insert(selected, pending.transactionIds[index])
    end
    local nextInventory = cloneInventory(inventory)
    while #nextInventory.recoveryOrder >= MAX_RECOVERY_CACHES do
        local oldestId = nextInventory.recoveryOrder[1]
        local oldest = nextInventory.recoveryCaches[oldestId]
        if oldest == nil or oldest.status == "recovered" then
            table.remove(nextInventory.recoveryOrder, 1)
            nextInventory.recoveryCaches[oldestId] = nil
        else
            return inventory, { applied = false, reason = "recovery_cache_full" }
        end
    end
    for _, transactionId in selected do
        local reward = table.clone(nextInventory.expeditionRewards[transactionId])
        reward.status = "cached"
        reward.cacheId = cacheId
        nextInventory.expeditionRewards[transactionId] = reward
    end
    local record = {
        createdAt = math.floor(now),
        manifestHash = string.sub(manifestHash, 1, 32),
        recoveredAt = nil,
        rewardTransactionIds = selected,
        status = "active",
    }
    nextInventory.recoveryCaches[cacheId] = record
    table.insert(nextInventory.recoveryOrder, cacheId)
    return nextInventory,
        {
            applied = true,
            cacheId = cacheId,
            materials = recoveryMaterials(nextInventory, selected),
            record = table.clone(record),
            retained = pending.count - cacheCount,
            transactionIds = table.clone(selected),
        }
end

function ExpeditionInventory.activeRecovery(inventory: any): any
    for _, cacheId in inventory.recoveryOrder do
        local record = inventory.recoveryCaches[cacheId]
        if record ~= nil and record.status == "active" then
            return {
                cacheId = cacheId,
                createdAt = record.createdAt,
                manifestHash = record.manifestHash,
                materials = recoveryMaterials(inventory, record.rewardTransactionIds),
                transactionIds = table.clone(record.rewardTransactionIds),
            }
        end
    end
    return nil
end

function ExpeditionInventory.cachedTransactionIds(inventory: any): { string }
    local result = {}
    for _, transactionId in inventory.rewardOrder do
        local reward = inventory.expeditionRewards[transactionId]
        if reward ~= nil and reward.status == "cached" then
            table.insert(result, transactionId)
        end
    end
    table.sort(result)
    return result
end

function ExpeditionInventory.recover(inventory: any, cacheId: string, now: number): (any, any)
    local record = inventory.recoveryCaches[cacheId]
    if record == nil then
        return inventory, { applied = false, reason = "unknown_cache" }
    end
    if record.status ~= "active" then
        return inventory,
            {
                applied = false,
                cacheId = cacheId,
                duplicate = true,
                materials = recoveryMaterials(inventory, record.rewardTransactionIds),
                reason = "cache_recovered",
                transactionIds = table.clone(record.rewardTransactionIds),
            }
    end
    local nextInventory = cloneInventory(inventory)
    local recoveredRecord = table.clone(record)
    recoveredRecord.status = "recovered"
    recoveredRecord.recoveredAt = math.floor(now)
    nextInventory.recoveryCaches[cacheId] = recoveredRecord
    for _, transactionId in record.rewardTransactionIds do
        local reward = nextInventory.expeditionRewards[transactionId]
        if reward ~= nil and reward.status == "cached" and reward.cacheId == cacheId then
            local recoveredReward = table.clone(reward)
            recoveredReward.status = "unbanked"
            recoveredReward.cacheId = nil
            nextInventory.expeditionRewards[transactionId] = recoveredReward
        end
    end
    return nextInventory,
        {
            applied = true,
            cacheId = cacheId,
            materials = recoveryMaterials(nextInventory, record.rewardTransactionIds),
            transactionIds = table.clone(record.rewardTransactionIds),
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
    now: number,
    storageCap: number?
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
    -- Milestone 4's storage cap. The town's stores hold what its tier has
    -- earned room for; surplus is counted and REPORTED, never silently
    -- discarded -- the toast that says "stores full" is the reason a player
    -- funds the next tier.
    local cap = math.min(MAX_MATERIAL_STACK, math.floor(tonumber(storageCap) or MAX_MATERIAL_STACK))
    local overflow: { [string]: number } = {}
    local overflowTotal = 0
    for materialId, amount in pending.materials do
        local current = nextInventory.materials[materialId] or 0
        local accepted = math.max(0, math.min(cap, current + amount) - current)
        nextInventory.materials[materialId] = current + accepted
        if accepted < amount then
            overflow[materialId] = amount - accepted
            overflowTotal += amount - accepted
        end
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
        overflow = if overflowTotal > 0 then table.clone(overflow) else nil,
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
            overflowTotal = overflowTotal,
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
