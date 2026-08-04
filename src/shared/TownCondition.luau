--!strict

local TownProgression = require("./TownProgression")

--[[
    How badly each building came through the night, and what repairing one
    does.

    Until build `0.49.0` this was a single town-wide integrity number and a
    derived 0-3 "damage level" that decided how many of three hardcoded repair
    piles appeared. That model had a specific tell that it was the wrong shape:
    repairing the inn's storm frame could make the archive's roof brace vanish,
    because no repair belonged to a building -- every repair added twenty to one
    shared number, and which sites were visible was purely a function of that
    number. A player could not damage one building, and could not fix one
    either.

    Now every building carries its own integrity, is damaged on its own, and is
    repaired on its own. The state shape deliberately mirrors TownConstruction's
    -- a `{ [buildingId]: number }` map normalized against
    `TownProgression.buildingIds()` -- because the two describe the same set of
    objects from two directions (how far built, how badly damaged) and there is
    no reason for them to be read differently.

    Three properties are worth stating because they are what makes the
    per-building model behave in a shared town:

      * **Which buildings take damage is chosen by night number alone.** The
        same rule TownNightIncident already uses, for the same reason: a replay
        is deterministic and a player who reconnects cannot reroll a gentler
        night.
      * **A building is never destroyed.** Damage floors at
        MIN_BUILDING_INTEGRITY, so a bad night creates work rather than deleting
        a building, its services, or the paths around it.
      * **Merging prefers the newest night, then the better-repaired building --
        per building.** Two players who repaired different buildings on the same
        day both keep their work, which the old single-number merge could not
        express: it had to pick one player's whole town over the other's.
]]

local TownCondition = {}

export type State = {
    buildings: { [string]: number },
    lastNightNumber: number,
    lastDamage: number,
    repairsCompleted: number,
}

local MIN_BUILDING_INTEGRITY = 25
local FULL_INTEGRITY = 100
local REPAIR_AMOUNT = 20
-- What one struck building loses. Chosen so a single hit leaves an obviously
-- damaged building that four repairs restore, rather than a scratch nobody
-- would cross the square to fix.
local DAMAGE_PER_BUILDING = 35

local function validNumber(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function isValidBuildingId(buildingId: any): boolean
    if type(buildingId) ~= "string" then
        return false
    end
    for _, id in TownProgression.buildingIds() do
        if id == buildingId then
            return true
        end
    end
    return false
end

local function clampIntegrity(value: any): number
    return math.clamp(
        math.floor(tonumber(value) or FULL_INTEGRITY),
        MIN_BUILDING_INTEGRITY,
        FULL_INTEGRITY
    )
end

-- How many buildings a night of this severity strikes. The thresholds are the
-- ones the single-number model already used to pick a damage amount, kept so
-- that how hard a night felt does not change with this rewrite -- only where
-- the damage lands.
local function struckCount(lanternHealth: number): number
    if lanternHealth >= 90 then
        return 0
    elseif lanternHealth >= 70 then
        return 1
    elseif lanternHealth >= 45 then
        return 2
    end
    return 3
end

function TownCondition.default(): State
    return {
        buildings = {},
        lastNightNumber = 0,
        lastDamage = 0,
        repairsCompleted = 0,
    }
end

--[[
    An absent building is a whole one.

    Storing only damaged buildings keeps the saved map small and, more usefully,
    means a building added to the roster later starts undamaged everywhere
    without a migration touching every profile.
]]
function TownCondition.integrityFor(state: any, buildingId: any): number
    if type(state) ~= "table" or type(state.buildings) ~= "table" then
        return FULL_INTEGRITY
    end
    if not isValidBuildingId(buildingId) then
        return FULL_INTEGRITY
    end
    local stored = state.buildings[buildingId]
    if not validNumber(stored) then
        return FULL_INTEGRITY
    end
    return clampIntegrity(stored)
end

function TownCondition.normalize(value: any): State
    local result = TownCondition.default()
    if type(value) ~= "table" then
        return result
    end

    if type(value.buildings) == "table" then
        for buildingId, integrity in value.buildings do
            if isValidBuildingId(buildingId) and validNumber(integrity) then
                local clamped = clampIntegrity(integrity)
                if clamped < FULL_INTEGRITY then
                    result.buildings[buildingId] = clamped
                end
            end
        end
    elseif validNumber(value.integrity) then
        -- A schema-12 profile: one town-wide integrity, no per-building map.
        -- Every building inherits the town's number, which preserves how
        -- damaged the town was and how much repair work is outstanding. It
        -- cannot recover *which* buildings were hit, because the old model
        -- never recorded that.
        local shared = clampIntegrity(value.integrity)
        if shared < FULL_INTEGRITY then
            for _, buildingId in TownProgression.buildingIds() do
                result.buildings[buildingId] = shared
            end
        end
    end

    if validNumber(value.lastNightNumber) and value.lastNightNumber >= 0 then
        result.lastNightNumber = math.clamp(math.floor(value.lastNightNumber), 0, 1_000_000)
    end
    if validNumber(value.lastDamage) then
        result.lastDamage = math.clamp(math.floor(value.lastDamage), 0, 999)
    end
    if validNumber(value.repairsCompleted) and value.repairsCompleted >= 0 then
        result.repairsCompleted = math.floor(value.repairsCompleted)
    end
    return result
end

--[[
    Which buildings this night strikes.

    `damageable` is the set of buildings that physically exist to be broken --
    the caller's business, because whether a building is a finished structure or
    still a construction site lives in TownConstruction, not here. Selection
    walks forward from an offset derived from the night number, wrapping, so the
    same night always strikes the same buildings no matter who is connected or
    how many times the server restarts.
]]
function TownCondition.struckBuildings(
    damageable: { string },
    lanternHealth: number,
    nightNumber: number
): { string }
    if type(damageable) ~= "table" or #damageable == 0 then
        return {}
    end
    local ordered = table.clone(damageable)
    table.sort(ordered)

    local count = math.min(struckCount(math.clamp(lanternHealth, 0, 100)), #ordered)
    if count <= 0 then
        return {}
    end

    local struck = {}
    local offset = (math.floor(nightNumber) - 1) % #ordered
    for step = 0, count - 1 do
        table.insert(struck, ordered[((offset + step) % #ordered) + 1])
    end
    return struck
end

function TownCondition.afterNight(
    state: State,
    endingLanternHealth: number,
    nightNumber: number,
    damageable: { string }?
): (State, any)
    local current = TownCondition.normalize(state)
    if
        not validNumber(endingLanternHealth)
        or not validNumber(nightNumber)
        or nightNumber < 1
        or nightNumber ~= math.floor(nightNumber)
    then
        return current, { applied = false, reason = "invalid_night_result" }
    end
    if nightNumber <= current.lastNightNumber then
        return current, { applied = false, reason = "night_already_recorded" }
    end

    -- No explicit roster means every known building is standing. Keeps the
    -- caller honest for tests and safe for a server that has not yet resolved
    -- its construction state.
    local roster: { string } = if type(damageable) == "table" and #damageable > 0
        then damageable
        else TownProgression.buildingIds()

    local lanternHealth = math.clamp(endingLanternHealth, 0, 100)
    local struck = TownCondition.struckBuildings(roster, lanternHealth, nightNumber)

    local nextState = TownCondition.normalize(current)
    local applied = 0
    local damagedIds = {}
    for _, buildingId in struck do
        local before = TownCondition.integrityFor(nextState, buildingId)
        local after = math.max(MIN_BUILDING_INTEGRITY, before - DAMAGE_PER_BUILDING)
        if after < FULL_INTEGRITY then
            nextState.buildings[buildingId] = after
        end
        applied += before - after
        table.insert(damagedIds, buildingId)
    end

    nextState.lastNightNumber = math.floor(nightNumber)
    nextState.lastDamage = applied
    return nextState,
        {
            applied = true,
            damage = applied,
            struck = damagedIds,
            damageLevel = #damagedIds,
            integrity = TownCondition.averageIntegrity(nextState, roster),
            reason = if applied > 0 then "night_damage" else "clean_defense",
        }
end

--[[
    Repair one building.

    Deliberately narrow: a repair names its building and moves nothing else. The
    old model could not express this -- every repair added to one shared number,
    so fixing the inn could visibly un-damage the archive.
]]
function TownCondition.repair(state: State, buildingId: any): (State, any)
    local current = TownCondition.normalize(state)
    if not isValidBuildingId(buildingId) then
        return current, { applied = false, reason = "unknown_building" }
    end

    local before = TownCondition.integrityFor(current, buildingId)
    if before >= FULL_INTEGRITY then
        return current,
            { applied = false, reason = "building_already_repaired", buildingId = buildingId }
    end

    local nextState = TownCondition.normalize(current)
    local after = math.min(FULL_INTEGRITY, before + REPAIR_AMOUNT)
    if after >= FULL_INTEGRITY then
        nextState.buildings[buildingId] = nil
    else
        nextState.buildings[buildingId] = after
    end
    nextState.repairsCompleted += 1

    return nextState,
        {
            applied = true,
            buildingId = buildingId,
            restored = after - before,
            buildingIntegrity = after,
            integrity = TownCondition.averageIntegrity(nextState, nil),
            reason = "building_repaired",
        }
end

-- The town's overall health, kept because analytics, the HUD, and the existing
-- world attributes all speak in one number. It is derived from the buildings
-- rather than stored, so it can never disagree with them.
function TownCondition.averageIntegrity(state: any, roster: { string }?): number
    local ids: { string } = if type(roster) == "table" and #roster > 0
        then roster
        else TownProgression.buildingIds()
    if #ids == 0 then
        return FULL_INTEGRITY
    end
    local total = 0
    for _, buildingId in ids do
        total += TownCondition.integrityFor(state, buildingId)
    end
    return math.floor(total / #ids)
end

--[[
    Prefer the newest defended night; within the same night, prefer the
    better-repaired copy of each building.

    Per building rather than wholesale, which is the behaviour the old
    single-number merge could not express: two players who repaired different
    buildings on the same day would previously have had one player's entire town
    chosen over the other's, silently discarding half the work.
]]
function TownCondition.merge(current: any, incoming: any): State
    local left = TownCondition.normalize(current)
    local right = TownCondition.normalize(incoming)

    if right.lastNightNumber > left.lastNightNumber then
        return right
    elseif left.lastNightNumber > right.lastNightNumber then
        return left
    end

    local merged = TownCondition.default()
    merged.lastNightNumber = left.lastNightNumber
    merged.lastDamage = math.min(left.lastDamage, right.lastDamage)
    merged.repairsCompleted = math.max(left.repairsCompleted, right.repairsCompleted)

    for _, buildingId in TownProgression.buildingIds() do
        local best = math.max(
            TownCondition.integrityFor(left, buildingId),
            TownCondition.integrityFor(right, buildingId)
        )
        if best < FULL_INTEGRITY then
            merged.buildings[buildingId] = best
        end
    end
    return merged
end

function TownCondition.snapshot(state: State, roster: { string }?): any
    local current = TownCondition.normalize(state)
    local damaged = {}
    local repairsRemaining = 0
    for _, buildingId in TownProgression.buildingIds() do
        local integrity = TownCondition.integrityFor(current, buildingId)
        if integrity < FULL_INTEGRITY then
            table.insert(damaged, { buildingId = buildingId, integrity = integrity })
            repairsRemaining += math.ceil((FULL_INTEGRITY - integrity) / REPAIR_AMOUNT)
        end
    end
    table.sort(damaged, function(a, b)
        return a.buildingId < b.buildingId
    end)

    return {
        integrity = TownCondition.averageIntegrity(current, roster),
        damageLevel = #damaged,
        damagedBuildings = damaged,
        lastNightNumber = current.lastNightNumber,
        lastDamage = current.lastDamage,
        repairsCompleted = current.repairsCompleted,
        repairsRemaining = repairsRemaining,
    }
end

TownCondition.MinimumIntegrity = MIN_BUILDING_INTEGRITY
TownCondition.RepairAmount = REPAIR_AMOUNT
TownCondition.DamagePerBuilding = DAMAGE_PER_BUILDING

return table.freeze(TownCondition)
