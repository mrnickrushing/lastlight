--!strict

local TownGuardLastStand = {}

export type State = {
    usedNight: number,
}

local LANTERN_COST = 12
local MINIMUM_LANTERN_HEALTH = 30
local RECOVERY_HEALTH = 50
local RECOVERY_WARD_SECONDS = 5

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function TownGuardLastStand.default(): State
    return { usedNight = 0 }
end

function TownGuardLastStand.normalize(value: any): State
    if type(value) ~= "table" or not finite(value.usedNight) or value.usedNight < 0 then
        return TownGuardLastStand.default()
    end
    return { usedNight = math.floor(value.usedNight) }
end

function TownGuardLastStand.attempt(state: State, context: any): (State, any)
    local current = TownGuardLastStand.normalize(state)
    if type(context) ~= "table" then
        return current, { accepted = false, reason = "invalid_context" }
    end
    local nightNumber = context.nightNumber
    local lanternHealth = context.lanternHealth
    local eligiblePlayers = context.eligiblePlayers
    local downedPlayers = context.downedPlayers
    if
        not finite(nightNumber)
        or nightNumber < 1
        or nightNumber ~= math.floor(nightNumber)
        or not finite(lanternHealth)
        or not finite(eligiblePlayers)
        or not finite(downedPlayers)
        or eligiblePlayers < 0
        or downedPlayers < 0
        or eligiblePlayers ~= math.floor(eligiblePlayers)
        or downedPlayers ~= math.floor(downedPlayers)
    then
        return current, { accepted = false, reason = "invalid_context" }
    end
    if context.phase ~= "night" then
        return current, { accepted = false, reason = "night_inactive" }
    end
    if eligiblePlayers < 1 then
        return current, { accepted = false, reason = "party_empty" }
    end
    if downedPlayers ~= eligiblePlayers then
        return current, { accepted = false, reason = "party_still_active" }
    end
    if current.usedNight == nightNumber then
        return current, { accepted = false, reason = "last_stand_spent" }
    end
    if lanternHealth < MINIMUM_LANTERN_HEALTH then
        return current, { accepted = false, reason = "lantern_too_weak" }
    end

    local nextState = { usedNight = nightNumber }
    return nextState,
        {
            accepted = true,
            lanternCost = LANTERN_COST,
            nightNumber = nightNumber,
            partySize = eligiblePlayers,
            reason = "guard_recovery",
            recoveryHealth = RECOVERY_HEALTH,
            recoveryWardSeconds = RECOVERY_WARD_SECONDS,
        }
end

TownGuardLastStand.LanternCost = LANTERN_COST
TownGuardLastStand.MinimumLanternHealth = MINIMUM_LANTERN_HEALTH
TownGuardLastStand.RecoveryHealth = RECOVERY_HEALTH
TownGuardLastStand.RecoveryWardSeconds = RECOVERY_WARD_SECONDS

return table.freeze(TownGuardLastStand)
