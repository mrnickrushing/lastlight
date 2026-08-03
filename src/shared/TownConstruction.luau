--!strict

local TownProgression = require("./TownProgression")
local TownConstructionCatalog = require("./TownConstructionCatalog")

-- The player-funded half of a building's stage. TownProgression still owns
-- the ceiling nights and chapter-one grant a building -- how far it is
-- *allowed* to go -- while this module owns how far it has actually been
-- *built*, paid for out of the same material wallet Crafting spends. A
-- building's rendered stage is always the lesser of the two: nights alone
-- no longer finish a building by themselves, but they never let payment
-- outrun what the story has earned either.
local TownConstruction = {}

local MAX_STAGE = TownConstructionCatalog.maxStage()

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

local function clampStage(value: any): number
    return math.clamp(math.floor(tonumber(value) or 0), 0, MAX_STAGE)
end

function TownConstruction.default(): { [string]: number }
    return {}
end

function TownConstruction.normalize(value: any): { [string]: number }
    local normalized: { [string]: number } = {}
    if type(value) ~= "table" then
        return normalized
    end
    for buildingId, stage in value do
        if isValidBuildingId(buildingId) and type(stage) == "number" then
            normalized[buildingId] = clampStage(stage)
        end
    end
    return normalized
end

function TownConstruction.stageFor(construction: any, buildingId: any): number
    if type(construction) ~= "table" or not isValidBuildingId(buildingId) then
        return 0
    end
    return clampStage(construction[buildingId])
end

-- The cost to advance from `currentStage` to `currentStage + 1`, or nil if
-- `currentStage` is already maxed (or not a real stage at all).
function TownConstruction.costFor(currentStage: number): { [string]: number }?
    if type(currentStage) ~= "number" then
        return nil
    end
    local floored = math.floor(currentStage)
    if floored ~= currentStage or floored < 0 or floored >= MAX_STAGE then
        return nil
    end
    return TownConstructionCatalog.costToReach(floored + 1)
end

-- Spends materials to advance one building exactly one stage, or leaves
-- every input untouched and reports why. Refusal order matters: a building
-- already at stage three is "already_maxed" even when the tier ceiling also
-- reads three, because there being nothing left to build is the more
-- accurate reason than the tier not being the blocker. Mirrors
-- Crafting.craft's shape and its own "insufficient_materials" reason string
-- exactly, since both spend the same wallet.
--
-- `_now` is accepted rather than dropped so a caller can pass the same
-- timestamp it already carries for revision bookkeeping without a special
-- case; nothing here is timestamped today, so it goes unused.
function TownConstruction.contribute(
    materials: { [string]: number },
    construction: { [string]: number },
    buildingId: any,
    ceilingStage: number,
    _now: number
): ({ [string]: number }, { [string]: number }, any)
    if not isValidBuildingId(buildingId) then
        return materials,
            construction,
            {
                applied = false,
                reason = "unknown_building",
            }
    end

    local currentStage = TownConstruction.stageFor(construction, buildingId)
    if currentStage >= MAX_STAGE then
        return materials,
            construction,
            {
                applied = false,
                buildingId = buildingId,
                reason = "already_maxed",
            }
    end

    local ceiling = clampStage(ceilingStage)
    if currentStage >= ceiling then
        return materials,
            construction,
            {
                applied = false,
                buildingId = buildingId,
                reason = "tier_not_ready",
            }
    end

    local cost = TownConstruction.costFor(currentStage)
    if cost == nil then
        return materials,
            construction,
            {
                applied = false,
                buildingId = buildingId,
                reason = "already_maxed",
            }
    end

    for materialId, amount in cost do
        if (materials[materialId] or 0) < amount then
            return materials,
                construction,
                {
                    applied = false,
                    buildingId = buildingId,
                    reason = "insufficient_materials",
                }
        end
    end

    local nextMaterials = table.clone(materials)
    for materialId, amount in cost do
        nextMaterials[materialId] = nextMaterials[materialId] - amount
    end

    local nextConstruction = table.clone(construction)
    local nextStage = currentStage + 1
    nextConstruction[buildingId] = nextStage

    return nextMaterials,
        nextConstruction,
        {
            applied = true,
            buildingId = buildingId,
            stage = nextStage,
        }
end

-- Reconciles two accumulators for the same shared town, the same
-- never-regress rule TownProgression.merge uses for the tier ceiling: every
-- building keeps the higher of the two stages, and unknown or malformed
-- input on either side normalizes down to nothing rather than erroring.
function TownConstruction.merge(current: any, incoming: any): { [string]: number }
    local normalizedCurrent = TownConstruction.normalize(current)
    local normalizedIncoming = TownConstruction.normalize(incoming)
    local merged: { [string]: number } = {}
    for _, buildingId in TownProgression.buildingIds() do
        merged[buildingId] =
            math.max(normalizedCurrent[buildingId] or 0, normalizedIncoming[buildingId] or 0)
    end
    return merged
end

return table.freeze(TownConstruction)
