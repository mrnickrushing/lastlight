--!strict

local ExtractionPayoff = {}

local PRESENTATION = table.freeze({
    -- Bramblewake
    material_amber_sap = table.freeze({ kind = "amber", label = "AMBER SAP" }),
    material_brightcap = table.freeze({ kind = "brightcap", label = "BRIGHTCAP" }),
    material_heartwood = table.freeze({ kind = "heartwood", label = "HEARTWOOD" }),
    material_meadow_fiber = table.freeze({ kind = "fiber", label = "MEADOW FIBER" }),
    material_spring_clay = table.freeze({ kind = "clay", label = "SPRING CLAY" }),
    -- Ironroot Delve
    material_ironroot_ore = table.freeze({ kind = "ore", label = "IRONROOT ORE" }),
    material_coalglass = table.freeze({ kind = "coalglass", label = "COALGLASS" }),
    material_glow_fungus = table.freeze({ kind = "fungus", label = "GLOW FUNGUS" }),
    material_machine_oil = table.freeze({ kind = "oil", label = "MACHINE OIL" }),
    material_echo_crystal = table.freeze({ kind = "crystal", label = "ECHO CRYSTAL" }),
    -- Mireglass Fen
    material_mirror_reed = table.freeze({ kind = "reed", label = "MIRROR REED" }),
    material_bog_iron = table.freeze({ kind = "bog_iron", label = "BOG IRON" }),
    material_witchlight_pollen = table.freeze({ kind = "pollen", label = "WITCHLIGHT POLLEN" }),
    material_eel_oil = table.freeze({ kind = "eel_oil", label = "EEL OIL" }),
    material_blackwater_herb = table.freeze({ kind = "herb", label = "BLACKWATER HERB" }),
    -- Tempest Reach
    material_storm_glass = table.freeze({ kind = "storm_glass", label = "STORM GLASS" }),
    material_salt_kelp = table.freeze({ kind = "kelp", label = "SALT KELP" }),
    material_ships_iron = table.freeze({ kind = "ships_iron", label = "SHIP'S IRON" }),
    material_rope_fiber = table.freeze({ kind = "rope", label = "ROPE FIBER" }),
    material_amberglass = table.freeze({ kind = "amberglass", label = "AMBERGLASS" }),
})

export type Entry = {
    amount: number,
    id: string,
    kind: string,
    label: string,
}

function ExtractionPayoff.summarize(materials: any): ({ Entry }, number)
    local entries: { Entry } = {}
    local total = 0
    if type(materials) ~= "table" then
        return entries, total
    end
    for materialId, amount in materials do
        local presentation = PRESENTATION[materialId]
        if presentation ~= nil and type(amount) == "number" and amount > 0 then
            local safeAmount = math.max(1, math.floor(amount))
            total += safeAmount
            table.insert(entries, {
                amount = safeAmount,
                id = materialId,
                kind = presentation.kind,
                label = presentation.label,
            })
        end
    end
    table.sort(entries, function(left: Entry, right: Entry): boolean
        return left.id < right.id
    end)
    return entries, total
end

function ExtractionPayoff.firstAvailableSlot(occupied: any, slotCount: number): number?
    if type(occupied) ~= "table" or slotCount < 1 then
        return nil
    end
    for slot = 1, math.floor(slotCount) do
        if occupied[slot] ~= true then
            return slot
        end
    end
    return nil
end

function ExtractionPayoff.claim(pending: any, owner: any): any
    if type(pending) ~= "table" or owner == nil then
        return nil
    end
    local payoff = pending[owner]
    pending[owner] = nil
    return payoff
end

return table.freeze(ExtractionPayoff)
