--!strict

local ProfessionCatalog = require("./ProfessionCatalog")

local ProfessionState = {}

export type State = {
    selectedId: string?,
    cooldownReadyAt: number,
    activeUntil: number,
    revision: number,
}

local function validNumber(value: any): boolean
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function ProfessionState.create(selectedId: string?, now: number): State
    assert(validNumber(now), "profession state time is invalid")
    return {
        selectedId = if ProfessionCatalog.isValid(selectedId) then selectedId else nil,
        cooldownReadyAt = now,
        activeUntil = now,
        revision = 0,
    }
end

function ProfessionState.select(
    state: State,
    professionId: string,
    now: number,
    canSwitch: boolean
): (State, any)
    if not ProfessionCatalog.isValid(professionId) then
        return state,
            {
                accepted = false,
                changed = false,
                reason = "unknown_profession",
            }
    end
    if not canSwitch then
        return state,
            {
                accepted = false,
                changed = false,
                reason = "switch_unavailable",
            }
    end
    if state.selectedId == professionId then
        return state,
            {
                accepted = true,
                changed = false,
                reason = "already_selected",
            }
    end

    local nextState: State = table.clone(state)
    nextState.selectedId = professionId
    nextState.cooldownReadyAt = math.max(state.cooldownReadyAt, now)
    nextState.activeUntil = now
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            changed = true,
            reason = "selected",
        }
end

function ProfessionState.canUse(state: State, now: number, canAct: boolean): any
    if not canAct then
        return {
            accepted = false,
            reason = "player_cannot_act",
        }
    end
    local professionId = state.selectedId
    if professionId == nil then
        return {
            accepted = false,
            reason = "profession_required",
        }
    end
    local definition = ProfessionCatalog.get(professionId)
    if definition == nil then
        return {
            accepted = false,
            reason = "unknown_profession",
        }
    end
    if now < state.cooldownReadyAt then
        return {
            accepted = false,
            reason = "cooldown",
            remaining = state.cooldownReadyAt - now,
        }
    end
    return {
        accepted = true,
        definition = definition,
    }
end

function ProfessionState.commitAbility(
    state: State,
    now: number,
    cooldownSeconds: number?,
    activeSeconds: number?
): (State, any)
    local professionId = state.selectedId
    local definition = if professionId == nil then nil else ProfessionCatalog.get(professionId)
    assert(definition ~= nil, "cannot commit a profession ability without a valid profession")

    local nextState: State = table.clone(state)
    local resolvedCooldown = if cooldownSeconds ~= nil
            and validNumber(cooldownSeconds)
            and cooldownSeconds >= 1
        then cooldownSeconds
        else definition.cooldownSeconds
    local resolvedActive = if activeSeconds ~= nil
            and validNumber(activeSeconds)
            and activeSeconds >= 0
        then activeSeconds
        else definition.activeSeconds
    nextState.cooldownReadyAt = now + resolvedCooldown
    nextState.activeUntil = now + resolvedActive
    nextState.revision += 1
    return nextState,
        {
            accepted = true,
            abilityId = definition.abilityId,
            activeUntil = nextState.activeUntil,
            cooldownReadyAt = nextState.cooldownReadyAt,
        }
end

function ProfessionState.mitigatesDamage(state: State, now: number): boolean
    return state.selectedId == ProfessionCatalog.Ids.Warden and now < state.activeUntil
end

function ProfessionState.snapshot(state: State, now: number): any
    local definition = if state.selectedId == nil
        then nil
        else ProfessionCatalog.get(state.selectedId)
    return {
        selectedId = state.selectedId,
        displayName = if definition == nil then nil else definition.displayName,
        abilityId = if definition == nil then nil else definition.abilityId,
        abilityName = if definition == nil then nil else definition.abilityName,
        abilityDescription = if definition == nil then nil else definition.abilityDescription,
        cooldownReadyAt = state.cooldownReadyAt,
        cooldownSeconds = if definition == nil then 0 else definition.cooldownSeconds,
        activeUntil = state.activeUntil,
        ready = definition ~= nil and now >= state.cooldownReadyAt,
        revision = state.revision,
    }
end

return table.freeze(ProfessionState)
