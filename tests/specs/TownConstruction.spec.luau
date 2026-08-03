--!strict

local TownConstruction = require("../../src/shared/TownConstruction")
local TownConstructionCatalog = require("../../src/shared/TownConstructionCatalog")
local TownProgression = require("../../src/shared/TownProgression")
local TestRunner = require("../TestRunner")

return {
    name = "TownConstruction",
    cases = {
        {
            name = "default is an empty ledger",
            run = function()
                TestRunner.equal(next(TownConstruction.default()), nil)
            end,
        },
        {
            name = "normalize keeps only known buildings with in-range integer stages",
            run = function()
                local normalized = TownConstruction.normalize({
                    building_archive = 2,
                    building_inn = 1.9,
                    building_town_board = -4,
                    building_workbench = 99,
                    building_does_not_exist = 3,
                    building_market = "3",
                })
                TestRunner.equal(normalized.building_archive, 2)
                TestRunner.equal(normalized.building_inn, 1)
                TestRunner.equal(normalized.building_town_board, 0)
                TestRunner.equal(normalized.building_workbench, 3)
                TestRunner.equal(normalized.building_does_not_exist, nil)
                TestRunner.equal(normalized.building_market, nil)
            end,
        },
        {
            name = "normalize rejects non-table input",
            run = function()
                TestRunner.equal(next(TownConstruction.normalize("not a table")), nil)
                TestRunner.equal(next(TownConstruction.normalize(nil)), nil)
            end,
        },
        {
            name = "stageFor reads a clamped stage and defaults unknowns to zero",
            run = function()
                local construction = { building_archive = 2 }
                TestRunner.equal(TownConstruction.stageFor(construction, "building_archive"), 2)
                TestRunner.equal(TownConstruction.stageFor(construction, "building_inn"), 0)
                TestRunner.equal(
                    TownConstruction.stageFor(construction, "building_does_not_exist"),
                    0
                )
                TestRunner.equal(TownConstruction.stageFor("not a table", "building_archive"), 0)
            end,
        },
        {
            name = "costFor escalates by stage and is nil once maxed",
            run = function()
                TestRunner.equal(TownConstruction.costFor(0).material_heartwood, 8)
                TestRunner.equal(TownConstruction.costFor(1).material_heartwood, 8)
                TestRunner.equal(TownConstruction.costFor(1).material_amber_sap, 6)
                TestRunner.equal(TownConstruction.costFor(2).material_heartwood, 12)
                TestRunner.equal(TownConstruction.costFor(2).material_amber_sap, 10)
                TestRunner.equal(TownConstruction.costFor(2).material_brightcap, 4)
                TestRunner.equal(TownConstruction.costFor(3), nil)
                TestRunner.equal(TownConstruction.costFor(-1), nil)
                TestRunner.equal(TownConstruction.costFor(1.5), nil)
            end,
        },
        {
            name = "contribute deducts the exact stage cost and advances by exactly one",
            run = function()
                local materials = { material_heartwood = 8, material_amber_sap = 1 }
                local construction = {}
                local nextMaterials, nextConstruction, result = TownConstruction.contribute(
                    materials,
                    construction,
                    "building_archive",
                    3,
                    1000
                )
                TestRunner.equal(result.applied, true)
                TestRunner.equal(result.buildingId, "building_archive")
                TestRunner.equal(result.stage, 1)
                TestRunner.equal(nextMaterials.material_heartwood, 0)
                TestRunner.equal(nextMaterials.material_amber_sap, 1)
                TestRunner.equal(nextConstruction.building_archive, 1)
                -- Inputs are untouched; the caller decides what to keep.
                TestRunner.equal(materials.material_heartwood, 8)
                TestRunner.equal(next(construction), nil)
            end,
        },
        {
            name = "contribute refuses an unknown building without mutating either input",
            run = function()
                local materials = { material_heartwood = 999 }
                local construction = {}
                local nextMaterials, nextConstruction, result = TownConstruction.contribute(
                    materials,
                    construction,
                    "building_does_not_exist",
                    3,
                    1000
                )
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.reason, "unknown_building")
                TestRunner.equal(nextMaterials, materials)
                TestRunner.equal(nextConstruction, construction)
            end,
        },
        {
            name = "contribute refuses when nights have not unlocked the next stage yet",
            run = function()
                local materials = { material_heartwood = 999 }
                local construction = { building_archive = 1 }
                local nextMaterials, nextConstruction, result = TownConstruction.contribute(
                    materials,
                    construction,
                    "building_archive",
                    1,
                    1000
                )
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.reason, "tier_not_ready")
                TestRunner.equal(nextMaterials, materials)
                TestRunner.equal(nextConstruction, construction)
            end,
        },
        {
            name = "contribute refuses a building already at stage three even at full tier",
            run = function()
                local materials = { material_heartwood = 999, material_amber_sap = 999 }
                local construction = { building_archive = 3 }
                local nextMaterials, nextConstruction, result = TownConstruction.contribute(
                    materials,
                    construction,
                    "building_archive",
                    3,
                    1000
                )
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.reason, "already_maxed")
                TestRunner.equal(nextMaterials, materials)
                TestRunner.equal(nextConstruction, construction)
            end,
        },
        {
            name = "contribute reports already_maxed rather than tier_not_ready when both are true",
            run = function()
                -- A building sitting at stage three with a tier ceiling of
                -- three satisfies currentStage >= ceiling AND currentStage
                -- >= max simultaneously. "Nothing left to build" is the more
                -- accurate story than "the tier isn't ready", so maxed wins.
                local construction = { building_inn = 3 }
                local _, _, result =
                    TownConstruction.contribute({}, construction, "building_inn", 3, 1000)
                TestRunner.equal(result.reason, "already_maxed")
            end,
        },
        {
            name = "contribute refuses insufficient materials without mutating either input",
            run = function()
                local materials = { material_heartwood = 3 }
                local construction = {}
                local nextMaterials, nextConstruction, result = TownConstruction.contribute(
                    materials,
                    construction,
                    "building_archive",
                    3,
                    1000
                )
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.reason, "insufficient_materials")
                TestRunner.equal(nextMaterials, materials)
                TestRunner.equal(nextConstruction, construction)
            end,
        },
        {
            name = "contribute can be chained to walk a building up through every stage",
            run = function()
                local materials = {
                    material_heartwood = 40,
                    material_amber_sap = 40,
                    material_brightcap = 40,
                }
                local construction = TownConstruction.default()
                for expectedStage = 1, 3 do
                    local result
                    materials, construction, result = TownConstruction.contribute(
                        materials,
                        construction,
                        "building_market",
                        3,
                        2000
                    )
                    TestRunner.equal(result.applied, true)
                    TestRunner.equal(result.stage, expectedStage)
                end
                local _, _, blocked =
                    TownConstruction.contribute(materials, construction, "building_market", 3, 2000)
                TestRunner.equal(blocked.applied, false)
                TestRunner.equal(blocked.reason, "already_maxed")
            end,
        },
        {
            name = "merge keeps the higher stage per building and never regresses",
            run = function()
                local current = { building_archive = 2, building_inn = 0 }
                local incoming = { building_archive = 1, building_inn = 3, building_market = 1 }
                local merged = TownConstruction.merge(current, incoming)
                TestRunner.equal(merged.building_archive, 2)
                TestRunner.equal(merged.building_inn, 3)
                TestRunner.equal(merged.building_market, 1)
                for _, buildingId in TownProgression.buildingIds() do
                    TestRunner.truthy(
                        merged[buildingId] ~= nil,
                        buildingId .. " was dropped by the merge"
                    )
                end
            end,
        },
        {
            name = "merge tolerates malformed input on either side",
            run = function()
                local merged = TownConstruction.merge(nil, "not a table")
                for _, buildingId in TownProgression.buildingIds() do
                    TestRunner.equal(merged[buildingId], 0)
                end
            end,
        },
        {
            name = "the construction ledger applies uniformly to every catalog building",
            run = function()
                for _, buildingId in TownProgression.buildingIds() do
                    local materials = {
                        material_heartwood = 999,
                        material_amber_sap = 999,
                        material_brightcap = 999,
                    }
                    local _, nextConstruction, result =
                        TownConstruction.contribute(materials, {}, buildingId, 3, 1000)
                    TestRunner.truthy(
                        result.applied,
                        buildingId .. " could not be contributed to despite full tier and wallet"
                    )
                    TestRunner.equal(nextConstruction[buildingId], 1)
                end
            end,
        },
        {
            name = "TownConstructionCatalog.costToReach is only defined for stages one through three",
            run = function()
                TestRunner.equal(TownConstructionCatalog.costToReach(0), nil)
                TestRunner.truthy(TownConstructionCatalog.costToReach(1) ~= nil)
                TestRunner.truthy(TownConstructionCatalog.costToReach(2) ~= nil)
                TestRunner.truthy(TownConstructionCatalog.costToReach(3) ~= nil)
                TestRunner.equal(TownConstructionCatalog.costToReach(4), nil)
                TestRunner.equal(TownConstructionCatalog.maxStage(), 3)
            end,
        },
    },
}
