--!strict

local ExtractionPayoff = {}

local PRESENTATION = table.freeze({
    material_amber_sap = table.freeze({ kind = "amber", label = "AMBER SAP" }),
    material_brightcap = table.freeze({ kind = "brightcap", label = "BRIGHTCAP" }),
    material_heartwood = table.freeze({ kind = "heartwood", label = "HEARTWOOD" }),
    material_meadow_fiber = table.freeze({ kind = "fiber", label = "MEADOW FIBER" }),
    material_spring_clay = table.freeze({ kind = "clay", label = "SPRING CLAY" }),
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
            local safeAmount = math.clamp(math.floor(amount), 1, 100)
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

return table.freeze(ExtractionPayoff)
