--!strict

-- Cost to advance a building one construction stage, table-driven by the
-- stage being reached rather than sixteen bespoke curves. TownProgression's
-- own doc comment already made this call for the eleven later buildings --
-- "eleven more bespoke expressions would be eleven more things to get
-- subtly wrong" -- and a per-building cost curve would multiply that same
-- risk by sixteen for no gameplay benefit anyone asked for: every building
-- becoming buildable at the same rate is the point, not a limitation.
--
-- Costs escalate with the stage reached, not the building, and lean on the
-- same four materials Crafting already spends (CraftingCatalog recipes run
-- 2-5 units per material). A construction stage is a town-wide, permanent
-- upgrade rather than one personal accessory, so it is priced well above a
-- single recipe: stage one is roughly double the heaviest existing recipe,
-- and stage three introduces brightcap only at the top so the last stretch
-- of any building still wants a supply run across all three gathered
-- materials rather than a single stockpile.
local TownConstructionCatalog = {}

export type StageCost = { [string]: number }

local MAX_STAGE = 3

local COSTS: { [number]: StageCost } = {
    [1] = table.freeze({
        material_heartwood = 8,
    }),
    [2] = table.freeze({
        material_heartwood = 8,
        material_amber_sap = 6,
    }),
    [3] = table.freeze({
        material_heartwood = 12,
        material_amber_sap = 10,
        material_brightcap = 4,
    }),
}

-- The material cost to reach `stage` (1-3) from `stage - 1`. Nil for stage
-- zero (nothing to reach; a construction site is the starting state, not a
-- purchase) and for anything past three (already fully built).
function TownConstructionCatalog.costToReach(stage: number): StageCost?
    if type(stage) ~= "number" then
        return nil
    end
    local floored = math.floor(stage)
    if floored ~= stage or floored < 1 or floored > MAX_STAGE then
        return nil
    end
    return COSTS[floored]
end

function TownConstructionCatalog.maxStage(): number
    return MAX_STAGE
end

return table.freeze(TownConstructionCatalog)
