--!strict

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

function EnemyCombatRules.strikeDamage(definition: any, facingDot: number): (number, string)
    if definition.frontShield == true then
        if facingDot >= 0.25 then
            return math.max(0, definition.frontalStrikeDamage or 0), "shielded"
        end
        return math.max(0, definition.flankStrikeDamage or definition.strikeDamage), "flanked"
    end
    return math.max(0, definition.strikeDamage or 0), "hit"
end

return table.freeze(EnemyCombatRules)
