--!strict

local Equipment = {}

export type Equipped = { [string]: string? }

type Definition = {
    slot: string,
    displayName: string,
    description: string,
    damageReduction: number,
    staminaRegenMultiplier: number,
    --[[
        Weapon-slot statistics. The family (`kind`) decides the moveset the
        way the roadmap asks: a ranged family declares `strikeRange` (the
        strike resolves at distance and the client draws a shot), a reaching
        melee family declares `meleeReach` (extended arm, no projectile), and
        an on-hit family carries its rider (stamina refund to the striker, or
        a snare on the struck enemy). The server reads all of these -- a
        client never submits range, damage, or an effect.
    ]]
    kind: string?,
    strikeRange: number?,
    meleeReach: number?,
    strikeDamageMultiplier: number?,
    onHitStaminaRefund: number?,
    onHitSnareSeconds: number?,
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
        kind = "bow",
        strikeRange = 30,
        strikeDamageMultiplier = 0.8,
    }),
    --[[
        The other five weapon families. Every number stays inside the bounds
        combat already clamps (damage multiplier 0.5-1.5 at the strike,
        damage reduction capped at 0.25 in stats), so no family can silence
        an enemy's mechanics or stack into an economy problem. Identities
        trade against each other: the maul is the damage ceiling with no
        reach, the lance buys reach with no rider, the sling trades the
        bow's range and damage for a snare, the edge sustains its wielder,
        and the cudgel is the one weapon that also guards.
    ]]
    gear_heartwood_maul = table.freeze({
        slot = "weapon",
        displayName = "HEARTWOOD MAUL",
        description = "Slow heavy blows land 45% harder up close.",
        damageReduction = 0,
        staminaRegenMultiplier = 1,
        kind = "maul",
        strikeDamageMultiplier = 1.45,
    }),
    gear_briar_lance = table.freeze({
        slot = "weapon",
        displayName = "BRIAR LANCE",
        description = "Full-strength strikes from 14 studs of reach.",
        damageReduction = 0,
        staminaRegenMultiplier = 1,
        kind = "lance",
        meleeReach = 14,
        strikeDamageMultiplier = 1,
    }),
    gear_foxfire_sling = table.freeze({
        slot = "weapon",
        displayName = "FOXFIRE SLING",
        description = "Stones from 22 studs hit for 70% and briefly snare the threat.",
        damageReduction = 0,
        staminaRegenMultiplier = 1,
        kind = "sling",
        strikeRange = 22,
        strikeDamageMultiplier = 0.7,
        onHitSnareSeconds = 2.5,
    }),
    gear_amber_edge = table.freeze({
        slot = "weapon",
        displayName = "AMBER EDGE",
        description = "Clean cuts hit 10% harder and return 6 stamina.",
        damageReduction = 0,
        staminaRegenMultiplier = 1,
        kind = "edge",
        strikeDamageMultiplier = 1.1,
        onHitStaminaRefund = 6,
    }),
    gear_warden_cudgel = table.freeze({
        slot = "weapon",
        displayName = "WARDEN CUDGEL",
        description = "A guard's weapon: 5% harder blows, 4% softer hits taken.",
        damageReduction = 0.04,
        staminaRegenMultiplier = 1,
        kind = "cudgel",
        strikeDamageMultiplier = 1.05,
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

    Returns nil for bare hands: the caller keeps its own defaults, so nothing
    about existing combat moves unless a weapon is actually equipped. `ranged`
    is what the client's projectile visual keys off -- only the bow and sling
    families throw something; the lance's reach is an extended arm, not a shot.
]]
function Equipment.weaponStrikeProfile(equipped: Equipped): any
    local normalized = Equipment.normalize(equipped)
    local weaponId = normalized.weapon
    if type(weaponId) ~= "string" then
        return nil
    end
    local definition = DEFINITIONS[weaponId]
    if definition == nil or definition.kind == nil then
        return nil
    end
    return {
        itemId = weaponId,
        kind = definition.kind,
        ranged = definition.strikeRange ~= nil,
        strikeRange = definition.strikeRange,
        meleeReach = definition.meleeReach,
        strikeDamageMultiplier = definition.strikeDamageMultiplier or 1,
        onHitStaminaRefund = definition.onHitStaminaRefund,
        onHitSnareSeconds = definition.onHitSnareSeconds,
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
