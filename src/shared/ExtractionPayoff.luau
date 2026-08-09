--!strict

local Strings = require("./Strings")

local ExtractionPayoff = {}

local PRESENTATION = table.freeze({
    -- Bramblewake
    material_amber_sap = table.freeze({
        kind = "amber",
        label = Strings.get("expedition.amber_sap"),
    }),
    material_brightcap = table.freeze({
        kind = "brightcap",
        label = Strings.get("expedition.brightcap"),
    }),
    material_heartwood = table.freeze({
        kind = "heartwood",
        label = Strings.get("world.heartwood"),
    }),
    material_meadow_fiber = table.freeze({
        kind = "fiber",
        label = Strings.get("expedition.meadow_fiber"),
    }),
    material_spring_clay = table.freeze({
        kind = "clay",
        label = Strings.get("expedition.spring_clay"),
    }),
    -- Ironroot Delve
    material_ironroot_ore = table.freeze({
        kind = "ore",
        label = Strings.get("expedition.ironroot_ore"),
    }),
    material_coalglass = table.freeze({
        kind = "coalglass",
        label = Strings.get("expedition.coalglass"),
    }),
    material_glow_fungus = table.freeze({
        kind = "fungus",
        label = Strings.get("expedition.glow_fungus"),
    }),
    material_machine_oil = table.freeze({
        kind = "oil",
        label = Strings.get("expedition.machine_oil"),
    }),
    material_echo_crystal = table.freeze({
        kind = "crystal",
        label = Strings.get("expedition.echo_crystal"),
    }),
    -- Mireglass Fen
    material_mirror_reed = table.freeze({
        kind = "reed",
        label = Strings.get("expedition.mirror_reed"),
    }),
    material_bog_iron = table.freeze({
        kind = "bog_iron",
        label = Strings.get("expedition.bog_iron"),
    }),
    material_witchlight_pollen = table.freeze({
        kind = "pollen",
        label = Strings.get("expedition.witchlight_pollen"),
    }),
    material_eel_oil = table.freeze({ kind = "eel_oil", label = Strings.get("expedition.eel_oil") }),
    material_blackwater_herb = table.freeze({
        kind = "herb",
        label = Strings.get("expedition.blackwater_herb"),
    }),
    -- Tempest Reach
    material_storm_glass = table.freeze({
        kind = "storm_glass",
        label = Strings.get("expedition.storm_glass"),
    }),
    material_salt_kelp = table.freeze({
        kind = "kelp",
        label = Strings.get("expedition.salt_kelp"),
    }),
    material_ships_iron = table.freeze({
        kind = "ships_iron",
        label = Strings.get("expedition.ship_s_iron"),
    }),
    material_rope_fiber = table.freeze({
        kind = "rope",
        label = Strings.get("expedition.rope_fiber"),
    }),
    material_amberglass = table.freeze({
        kind = "amberglass",
        label = Strings.get("expedition.amberglass"),
    }),
    -- Frostmere Vale
    material_frostmere_ice = table.freeze({
        kind = "ice",
        label = Strings.get("expedition.frostmere_ice"),
    }),
    material_thawed_iron = table.freeze({
        kind = "thawed_iron",
        label = Strings.get("expedition.thawed_iron"),
    }),
    material_ember_moss = table.freeze({
        kind = "ember_moss",
        label = Strings.get("expedition.ember_moss"),
    }),
    material_frostmere_wool = table.freeze({
        kind = "wool",
        label = Strings.get("expedition.frostmere_wool"),
    }),
    material_aurora_salt = table.freeze({
        kind = "aurora_salt",
        label = Strings.get("expedition.aurora_salt"),
    }),
    -- Cinderfall Crown
    material_cindersteel = table.freeze({
        kind = "cindersteel",
        label = Strings.get("expedition.cindersteel"),
    }),
    material_memory_glass = table.freeze({
        kind = "memory_glass",
        label = Strings.get("expedition.memory_glass"),
    }),
    material_ash_silk = table.freeze({
        kind = "ash_silk",
        label = Strings.get("expedition.ash_silk"),
    }),
    material_kiln_pearl = table.freeze({
        kind = "kiln_pearl",
        label = Strings.get("expedition.kiln_pearl"),
    }),
    material_crown_coal = table.freeze({
        kind = "crown_coal",
        label = Strings.get("expedition.crown_coal"),
    }),
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
