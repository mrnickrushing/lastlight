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
    elseif kind == actions.UseGear or kind == actions.EquipGear or kind == actions.RepairGear then
        return "itemId"
    elseif kind == actions.Sprint or kind == actions.CompactHud then
        return "enabled"
    elseif kind == actions.LobbyDepart then
        return "partySize"
    elseif kind == actions.SaveLoadout or kind == actions.ApplyLoadout then
        return "slot"
    elseif kind == actions.CompanionCommand then
        return "mode"
    elseif kind == actions.PartyReply then
        -- Yes or no to the one invitation a player can be holding. A player
        -- holds at most one at a time, so the reply does not have to name
        -- which -- which is what keeps this to a single field.
        return "accept"
    elseif kind == actions.QuickChat then
        -- A phrase id and nothing else. There is no position in a quick chat
        -- payload because the server reads the sender's own, which is what
        -- makes a ping unforgeable rather than merely validated.
        return "phraseId"
    elseif kind == actions.StoreDetail or kind == actions.StorePurchase then
        -- Which product is being looked at, or bought. The Roblox product id
        -- is never in a payload: the server maps this game's id to the
        -- dashboard number, so a forged payload cannot prompt a purchase for
        -- something this catalog does not sell.
        return "productId"
    elseif kind == actions.EquipCosmetic then
        -- The cosmetic, and never its slot. The slot is the catalog's answer
        -- about that id, and a payload with no slot in it cannot name the
        -- wrong one.
        return "cosmeticId"
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
    --[[
        The departure press carries TWO fields: the party size and the
        chosen contract. The single-extra-field shape above silently
        dropped every real press from the moment contracts shipped --
        isValidForKind saw contractId, an unknown key, and rejected the
        whole payload before any handler could run. No toast, no log,
        no countdown: the platform just did nothing, exactly as the owner
        reported twice. Direct remote tests that omitted contractId passed,
        which is how it hid from every synthetic check.
    ]]
    if kind == runtimeIds.Actions.LobbyDepart then
        allowed.contractId = true
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
