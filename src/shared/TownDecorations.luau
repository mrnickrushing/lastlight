--!strict
--[[
    Town decorations: authored slots, material costs, and a tier cap.

    Milestone 4's "decoration caps" deliverable, built the same shape as
    construction: the player spends the material wallet to make the town
    theirs, the tier decides how much of that the town can hold, and every
    rule lives here pure so the spec can pin it. Slots are authored — a
    banner goes where a banner pole stands — because free placement is a
    griefing surface and a streaming problem this game does not need.

    Decorations are identity, never power: no slot changes a stat anywhere.
]]

local Strings = require("./Strings")

local TownDecorations = {}

export type Slot = {
    id: string,
    displayName: string,
    kind: string,
    cost: { [string]: number },
}

export type State = { [string]: boolean }

local SLOTS: { Slot } = table.freeze({
    table.freeze({
        id = "decor_plaza_banner_east",
        displayName = Strings.get("town.east_plaza_banner"),
        kind = "banner",
        cost = table.freeze({ material_meadow_fiber = 3, material_heartwood = 1 }) :: { [string]: number },
    }),
    table.freeze({
        id = "decor_plaza_banner_west",
        displayName = Strings.get("town.west_plaza_banner"),
        kind = "banner",
        cost = table.freeze({ material_meadow_fiber = 3, material_heartwood = 1 }) :: { [string]: number },
    }),
    table.freeze({
        id = "decor_road_garland_north",
        displayName = Strings.get("town.north_road_garland"),
        kind = "garland",
        cost = table.freeze({ material_meadow_fiber = 2, material_brightcap = 1 }) :: { [string]: number },
    }),
    table.freeze({
        id = "decor_road_garland_south",
        displayName = Strings.get("town.south_road_garland"),
        kind = "garland",
        cost = table.freeze({ material_meadow_fiber = 2, material_brightcap = 1 }) :: { [string]: number },
    }),
    table.freeze({
        id = "decor_planter_gate",
        displayName = Strings.get("town.gate_planter"),
        kind = "planter",
        cost = table.freeze({ material_heartwood = 2, material_amber_sap = 1 }) :: { [string]: number },
    }),
    table.freeze({
        id = "decor_planter_archive",
        displayName = Strings.get("town.archive_planter"),
        kind = "planter",
        cost = table.freeze({ material_heartwood = 2, material_amber_sap = 1 }) :: { [string]: number },
    }),
    table.freeze({
        id = "decor_planter_inn",
        displayName = Strings.get("town.inn_planter"),
        kind = "planter",
        cost = table.freeze({ material_heartwood = 2, material_amber_sap = 1 }) :: { [string]: number },
    }),
    table.freeze({
        id = "decor_planter_workshop",
        displayName = Strings.get("town.workshop_planter"),
        kind = "planter",
        cost = table.freeze({ material_heartwood = 2, material_amber_sap = 1 }) :: { [string]: number },
    }),
})

local SLOTS_BY_ID: { [string]: Slot } = {}
for _, slot in SLOTS do
    SLOTS_BY_ID[slot.id] = slot
end
table.freeze(SLOTS_BY_ID)

TownDecorations.Slots = SLOTS

function TownDecorations.slot(id: string): Slot?
    return SLOTS_BY_ID[id]
end

--[[
    How many decorations the town can carry at a tier. Grows with the town
    like storage does, and tops out below the slot count on purpose: a maxed
    town still chooses which corners it dresses.
]]
function TownDecorations.capForTier(tier: number): number
    return 2 + math.clamp(math.floor(tonumber(tier) or 0), 0, 3) * 2
end

function TownDecorations.default(): State
    return {}
end

function TownDecorations.normalize(value: any): State
    local state: State = {}
    if type(value) ~= "table" then
        return state
    end
    for id, placed in value do
        if SLOTS_BY_ID[id] ~= nil and placed == true then
            state[id] = true
        end
    end
    return state
end

function TownDecorations.count(state: State): number
    local total = 0
    for _ in state do
        total += 1
    end
    return total
end

--[[
    Place a decoration. Same contract as construction's contribute: wallet
    and state in, wallet and state out, with a reason a toast can speak. The
    caller charges nothing on refusal because nothing here mutates.
]]
function TownDecorations.place(
    materials: { [string]: number },
    state: State,
    decorationId: any,
    tier: number
): ({ [string]: number }, State, any)
    local slot = if type(decorationId) == "string" then SLOTS_BY_ID[decorationId] else nil
    if slot == nil then
        return materials, state, { applied = false, reason = "unknown_decoration" }
    end
    if state[slot.id] == true then
        return materials, state, { applied = false, reason = "already_placed" }
    end
    if TownDecorations.count(state) >= TownDecorations.capForTier(tier) then
        return materials, state, { applied = false, reason = "decoration_cap" }
    end
    for materialId, amount in slot.cost do
        if (materials[materialId] or 0) < amount then
            return materials, state, { applied = false, reason = "insufficient_materials" }
        end
    end

    local nextMaterials = table.clone(materials)
    for materialId, amount in slot.cost do
        nextMaterials[materialId] = nextMaterials[materialId] - amount
    end
    local nextState = table.clone(state)
    nextState[slot.id] = true
    return nextMaterials, nextState, { applied = true, decorationId = slot.id }
end

-- Shared towns keep every decoration either player paid for.
function TownDecorations.merge(current: any, incoming: any): State
    local merged = TownDecorations.normalize(current)
    for id in TownDecorations.normalize(incoming) do
        merged[id] = true
    end
    return merged
end

return table.freeze(TownDecorations)
