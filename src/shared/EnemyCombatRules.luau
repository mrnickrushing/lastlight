--!strict

local Strings = require("./Strings")

local EnemyCombatRules = {}

function EnemyCombatRules.contains(
    shape: string,
    localX: number,
    localZ: number,
    radius: number?,
    width: number?,
    length: number?
): boolean
    if shape == "circle" then
        local resolvedRadius = math.max(0, radius or 0)
        return localX * localX + localZ * localZ <= resolvedRadius * resolvedRadius
    end
    if shape == "lane" then
        local halfWidth = math.max(0, width or 0) * 0.5
        local halfLength = math.max(0, length or 0) * 0.5
        return math.abs(localX) <= halfWidth and math.abs(localZ) <= halfLength
    end
    return false
end

--[[
    The status/reaction layer rides the same resolution: statuses that are
    already in the game interact when a strike lands, instead of living in
    parallel. A STILLED enemy is bound open -- the strike counts as a clean
    flank whatever the real facing, which is what finally beats a
    front-shielded Briarback without circling it. A SNARED enemy cannot
    slip the blow (x1.2). A DROWSY striker swings soft (x0.85) -- the
    counterplay the Alchemist's tonic exists for. Multipliers stack and
    clamp to 0.6..1.6 so no combination silences an enemy or a player.
]]
export type StrikeReactions = {
    stilled: boolean?,
    snared: boolean?,
    drowsyStriker: boolean?,
}

function EnemyCombatRules.strikeDamage(
    definition: any,
    facingDot: number,
    reactions: StrikeReactions?
): (number, string, string?)
    local stilled = reactions ~= nil and reactions.stilled == true
    local snared = reactions ~= nil and reactions.snared == true
    local drowsy = reactions ~= nil and reactions.drowsyStriker == true

    local damage: number
    local result: string
    if definition.frontShield == true then
        if facingDot >= 0.25 and not stilled then
            damage, result = math.max(0, definition.frontalStrikeDamage or 0), "shielded"
        else
            damage, result =
                math.max(0, definition.flankStrikeDamage or definition.strikeDamage), "flanked"
        end
    else
        damage, result = math.max(0, definition.strikeDamage or 0), "hit"
        if stilled then
            result = "flanked"
        end
    end

    local multiplier = 1
    local label: string? = nil
    if stilled then
        multiplier *= 1.25
        label = Strings.get("enemy.bound_open_a_clean_flank")
    elseif snared then
        multiplier *= 1.2
        label = Strings.get("enemy.exposed_the_snare_held_it")
    end
    if drowsy then
        multiplier *= 0.85
        if label == nil then
            label = Strings.get("enemy.drowsy_swing")
        end
    end
    damage = math.floor(damage * math.clamp(multiplier, 0.6, 1.6) + 0.5)
    return damage, result, label
end

return table.freeze(EnemyCombatRules)
