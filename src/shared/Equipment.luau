--!strict

local Equipment = {}

export type Equipped = { [string]: string? }

type Definition = {
    slot: string,
    displayName: string,
    description: string,
    damageReduction: number,
    staminaRegenMultiplier: number,
    -- Weapon-slot statistics. Melee weapons leave these nil; a ranged weapon
    -- declares how far a strike may resolve from and what it trades for the
    -- reach. The server reads these -- a client never submits range or damage.
    strikeRange: number?,
    strikeDamageMultiplier: number?,
}

local DEFINITIONS: { [string]: Definition } = {
    gear_ironroot_hood = table.freeze({
        slot = "head",
        displayName = "IRONROOT HOOD",
        description = "Softens incoming damage by 5%.",
        damageReduction = 0.05,
        staminaRegenMultiplier = 1,
    }),
    gear_bramble_boots = table.freeze({
        slot = "feet",
        displayName = "BRAMBLE BOOTS",
        description = "Recover stamina 10% faster.",
        damageReduction = 0,
        staminaRegenMultiplier = 1.1,
    }),
    gear_thornwood_bow = table.freeze({
        slot = "weapon",
        displayName = "THORNWOOD BOW",
        description = "Strike from 30 studs. Arrows hit for 80% of a close blow.",
        damageReduction = 0,
        staminaRegenMultiplier = 1,
        strikeRange = 30,
        strikeDamageMultiplier = 0.8,
    }),
}

function Equipment.default(): Equipped
    return {}
end

function Equipment.normalize(value: any): Equipped
    local result: Equipped = {}
    if type(value) ~= "table" then
        return result
    end
    for slot, itemId in value do
        if type(slot) == "string" and type(itemId) == "string" and DEFINITIONS[itemId] ~= nil then
            local definition = DEFINITIONS[itemId]
            if definition.slot == slot then
                result[slot] = itemId
            end
        end
    end
    return result
end

function Equipment.get(itemId: any): any
    return if type(itemId) == "string" then DEFINITIONS[itemId] else nil
end

function Equipment.isKnown(itemId: any): boolean
    return type(itemId) == "string" and DEFINITIONS[itemId] ~= nil
end

function Equipment.equip(
    gear: { [string]: number },
    equipped: Equipped,
    itemId: any
): (Equipped, any)
    local definition = Equipment.get(itemId)
    if definition == nil then
        return equipped, { applied = false, reason = "unknown_equipment" }
    end
    if (gear[itemId] or 0) < 1 then
        return equipped, { applied = false, reason = "not_owned" }
    end
    local nextEquipped = Equipment.normalize(equipped)
    nextEquipped[definition.slot] = itemId
    return nextEquipped,
        {
            applied = true,
            itemId = itemId,
            slot = definition.slot,
        }
end

function Equipment.unequip(equipped: Equipped, slot: any): (Equipped, any)
    if type(slot) ~= "string" then
        return equipped, { applied = false, reason = "invalid_slot" }
    end
    local nextEquipped = Equipment.normalize(equipped)
    if nextEquipped[slot] == nil then
        return equipped, { applied = false, reason = "empty_slot" }
    end
    nextEquipped[slot] = nil
    return nextEquipped, { applied = true, slot = slot }
end

--[[
    What the equipped weapon changes about a strike.

    Returns nil for bare hands and melee tools: the caller keeps its own
    defaults, so nothing about existing combat moves unless a ranged weapon is
    actually equipped.
]]
function Equipment.weaponStrikeProfile(equipped: Equipped): any
    local normalized = Equipment.normalize(equipped)
    local weaponId = normalized.weapon
    if type(weaponId) ~= "string" then
        return nil
    end
    local definition = DEFINITIONS[weaponId]
    if definition == nil or definition.strikeRange == nil then
        return nil
    end
    return {
        itemId = weaponId,
        strikeRange = definition.strikeRange,
        strikeDamageMultiplier = definition.strikeDamageMultiplier or 1,
    }
end

function Equipment.stats(equipped: Equipped): any
    local damageReduction = 0
    local staminaRegenMultiplier = 1
    for _, itemId in Equipment.normalize(equipped) do
        if type(itemId) == "string" then
            local definition = DEFINITIONS[itemId]
            if definition ~= nil then
                damageReduction += definition.damageReduction
                staminaRegenMultiplier *= definition.staminaRegenMultiplier
            end
        end
    end
    return {
        damageReduction = math.clamp(damageReduction, 0, 0.25),
        staminaRegenMultiplier = math.clamp(staminaRegenMultiplier, 0.75, 1.5),
    }
end

function Equipment.list(): { any }
    local result = {}
    for itemId, definition in DEFINITIONS do
        table.insert(result, {
            itemId = itemId,
            slot = definition.slot,
            displayName = definition.displayName,
            description = definition.description,
        })
    end
    table.sort(result, function(a, b)
        return a.itemId < b.itemId
    end)
    return result
end

return table.freeze(Equipment)
