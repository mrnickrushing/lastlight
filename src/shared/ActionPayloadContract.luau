--!strict

-- The wire contract for the ActionRequest remote, in one place so the exploit
-- suite tests what the server actually runs rather than a copy of it.
--
-- Two gates, applied in order and deliberately kept separate:
--
--   1. isValidTransport — NetworkService drops anything that is not a flat
--      table of short scalars before a payload reaches any service at all.
--   2. isValidForKind — the action dispatcher then allows only the fields the
--      requested kind declares, so a field that means something to one action
--      cannot ride along on another.
--
-- Neither gate knows what an action does. They only decide whether a payload
-- is shaped like something the server is willing to look at.

local ActionPayloadContract = {
    MaxFields = 6,
    MaxKindLength = 32,
    MaxStringLength = 128,
}

function ActionPayloadContract.isValidTransport(payload: any): boolean
    if type(payload) ~= "table" or payload.schemaVersion ~= 1 then
        return false
    end

    local kind = payload.kind
    if type(kind) ~= "string" or #kind == 0 or #kind > ActionPayloadContract.MaxKindLength then
        return false
    end

    local fieldCount = 0
    for key, value in payload do
        fieldCount += 1
        if fieldCount > ActionPayloadContract.MaxFields or type(key) ~= "string" then
            return false
        end
        local valueType = type(value)
        if valueType == "string" then
            if #value > ActionPayloadContract.MaxStringLength then
                return false
            end
        elseif valueType == "number" then
            -- NaN and the infinities compare strangely everywhere downstream,
            -- so they never get past the door.
            if value ~= value or value == math.huge or value == -math.huge then
                return false
            end
        elseif valueType ~= "boolean" then
            -- Nested tables, functions, and Instances included: a payload is
            -- flat scalars or it is nothing.
            return false
        end
    end
    return true
end

-- The one extra field a kind may carry beyond schemaVersion and kind. A kind
-- absent from this list carries no payload of its own.
function ActionPayloadContract.extraField(runtimeIds: any, kind: string): string?
    local actions = runtimeIds.Actions
    if kind == actions.Interact then
        return "interactionId"
    elseif kind == actions.SelectProfession then
        return "professionId"
    elseif kind == actions.UseGear or kind == actions.EquipGear then
        return "itemId"
    elseif kind == actions.Sprint or kind == actions.CompactHud then
        return "enabled"
    elseif kind == actions.LobbyDepart then
        return "partySize"
    end
    return nil
end

function ActionPayloadContract.allowedFields(runtimeIds: any, kind: string): { [string]: boolean }
    local allowed = {
        schemaVersion = true,
        kind = true,
    }
    local extra = ActionPayloadContract.extraField(runtimeIds, kind)
    if extra ~= nil then
        allowed[extra] = true
    end
    return allowed
end

function ActionPayloadContract.isValidForKind(runtimeIds: any, payload: any): boolean
    if type(payload) ~= "table" or payload.schemaVersion ~= 1 then
        return false
    end

    local kind = payload.kind
    if type(kind) ~= "string" or #kind == 0 or #kind > ActionPayloadContract.MaxKindLength then
        return false
    end

    local allowed = ActionPayloadContract.allowedFields(runtimeIds, kind)
    for key in payload do
        if type(key) ~= "string" or allowed[key] ~= true then
            return false
        end
    end
    return true
end

-- Rate limiter cost. The two actions that drive combat cost double, so a macro
-- cannot sustain twice the intended swing rate by spamming the remote.
function ActionPayloadContract.cost(runtimeIds: any, kind: string): number
    local actions = runtimeIds.Actions
    if kind == actions.UseTool or kind == actions.ProfessionAbility then
        return 2
    end
    return 1
end

return table.freeze(ActionPayloadContract)
