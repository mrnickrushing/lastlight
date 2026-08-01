--!strict

local TownCondition = {}

export type State = {
    integrity: number,
    lastNightNumber: number,
    lastDamage: number,
    repairsCompleted: number,
}

local MIN_INTEGRITY = 25
local REPAIR_AMOUNT = 20

local function validNumber(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function damageLevel(integrity: number): number
    if integrity >= 90 then
        return 0
    elseif integrity >= 70 then
        return 1
    elseif integrity >= 50 then
        return 2
    end
    return 3
end

function TownCondition.default(): State
    return {
        integrity = 100,
        lastNightNumber = 0,
        lastDamage = 0,
        repairsCompleted = 0,
    }
end

function TownCondition.normalize(value: any): State
    local result = TownCondition.default()
    if type(value) ~= "table" then
        return result
    end
    if validNumber(value.integrity) then
        result.integrity = math.clamp(math.floor(value.integrity), MIN_INTEGRITY, 100)
    end
    if validNumber(value.lastNightNumber) and value.lastNightNumber >= 0 then
        result.lastNightNumber = math.clamp(math.floor(value.lastNightNumber), 0, 1_000_000)
    end
    if validNumber(value.lastDamage) then
        result.lastDamage = math.clamp(math.floor(value.lastDamage), 0, 55)
    end
    if validNumber(value.repairsCompleted) and value.repairsCompleted >= 0 then
        result.repairsCompleted = math.floor(value.repairsCompleted)
    end
    return result
end

function TownCondition.afterNight(
    state: State,
    endingLanternHealth: number,
    nightNumber: number
): (State, any)
    local current = TownCondition.normalize(state)
    if
        type(endingLanternHealth) ~= "number"
        or not validNumber(endingLanternHealth)
        or type(nightNumber) ~= "number"
        or not validNumber(nightNumber)
        or nightNumber < 1
        or nightNumber ~= math.floor(nightNumber)
    then
        return current, { applied = false, reason = "invalid_night_result" }
    end
    if nightNumber <= current.lastNightNumber then
        return current, { applied = false, reason = "night_already_recorded" }
    end

    local lanternHealth = math.clamp(endingLanternHealth, 0, 100)
    local damage = if lanternHealth >= 90
        then 0
        elseif lanternHealth >= 70 then 15
        elseif lanternHealth >= 45 then 35
        else 55
    local nextState = table.clone(current)
    nextState.integrity = math.max(MIN_INTEGRITY, current.integrity - damage)
    nextState.lastNightNumber = nightNumber
    nextState.lastDamage = current.integrity - nextState.integrity
    return nextState,
        {
            applied = true,
            damage = nextState.lastDamage,
            damageLevel = damageLevel(nextState.integrity),
            integrity = nextState.integrity,
            reason = if damage > 0 then "night_damage" else "clean_defense",
        }
end

function TownCondition.repair(state: State): (State, any)
    local current = TownCondition.normalize(state)
    if current.integrity >= 100 then
        return current, { applied = false, reason = "town_already_repaired" }
    end
    local nextState = table.clone(current)
    nextState.integrity = math.min(100, current.integrity + REPAIR_AMOUNT)
    nextState.repairsCompleted += 1
    if nextState.integrity >= 100 then
        nextState.lastDamage = 0
    end
    return nextState,
        {
            applied = true,
            restored = nextState.integrity - current.integrity,
            integrity = nextState.integrity,
            damageLevel = damageLevel(nextState.integrity),
            reason = "town_repaired",
        }
end

-- Prefer the newest defended night. Within that same day, higher integrity is
-- evidence of later repair work, so a stale player profile cannot re-damage a
-- shared server town after another player has already repaired it.
function TownCondition.merge(current: any, incoming: any): State
    local left = TownCondition.normalize(current)
    local right = TownCondition.normalize(incoming)
    if right.lastNightNumber > left.lastNightNumber then
        return right
    elseif left.lastNightNumber > right.lastNightNumber then
        return left
    elseif right.integrity > left.integrity then
        return right
    elseif left.integrity > right.integrity then
        return left
    elseif right.repairsCompleted > left.repairsCompleted then
        return right
    end
    return left
end

function TownCondition.snapshot(state: State): any
    local current = TownCondition.normalize(state)
    return {
        integrity = current.integrity,
        damageLevel = damageLevel(current.integrity),
        lastNightNumber = current.lastNightNumber,
        lastDamage = current.lastDamage,
        repairsCompleted = current.repairsCompleted,
        repairsRemaining = math.ceil((100 - current.integrity) / REPAIR_AMOUNT),
    }
end

TownCondition.MinimumIntegrity = MIN_INTEGRITY
TownCondition.RepairAmount = REPAIR_AMOUNT

return table.freeze(TownCondition)
