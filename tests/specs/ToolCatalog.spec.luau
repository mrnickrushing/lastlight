--!strict

local ToolCatalog = require("../../src/shared/ToolCatalog")
local TestRunner = require("../TestRunner")

return {
    name = "ToolCatalog",
    cases = {
        {
            name = "the roster is eight tool families with unique identities",
            run = function()
                local tools = ToolCatalog.list()
                TestRunner.equal(#tools, 8)
                local seenIds = {}
                local seenFamilies = {}
                for _, definition in tools do
                    TestRunner.equal(seenIds[definition.id], nil)
                    seenIds[definition.id] = true
                    TestRunner.equal(seenFamilies[definition.family], nil)
                    seenFamilies[definition.family] = true
                    TestRunner.truthy(#definition.displayName > 0)
                    TestRunner.truthy(#definition.description > 0)
                end
                TestRunner.truthy(ToolCatalog.isValid("pick"))
                TestRunner.truthy(ToolCatalog.isValid("survey_kit"))
                TestRunner.equal(ToolCatalog.isValid("laser"), false)
            end,
        },
        {
            name = "every stat identity stays inside combat's own clamps",
            run = function()
                for _, definition in ToolCatalog.list() do
                    if definition.strikeDamageMultiplier ~= nil then
                        TestRunner.truthy(definition.strikeDamageMultiplier >= 0.5)
                        TestRunner.truthy(definition.strikeDamageMultiplier <= 1.5)
                    end
                    if definition.actionDurationMultiplier ~= nil then
                        TestRunner.truthy(definition.actionDurationMultiplier >= 0.5)
                    end
                    if definition.gatherDurationMultiplier ~= nil then
                        TestRunner.truthy(definition.gatherDurationMultiplier >= 0.5)
                        TestRunner.truthy(definition.gatherMaterials ~= nil)
                    end
                    if definition.staminaRegenMultiplier ~= nil then
                        TestRunner.truthy(definition.staminaRegenMultiplier <= 1.25)
                    end
                    if definition.sprintSpeedMultiplier ~= nil then
                        TestRunner.truthy(definition.sprintSpeedMultiplier <= 1.15)
                    end
                end
            end,
        },
        {
            name = "a gather specialist hurries only its own materials",
            run = function()
                local pick = ToolCatalog.get("pick")
                TestRunner.truthy(pick.gatherMaterials.material_amber_sap)
                TestRunner.equal(pick.gatherMaterials.material_meadow_fiber, nil)
                local sickle = ToolCatalog.get("sickle")
                TestRunner.truthy(sickle.gatherMaterials.material_meadow_fiber)
                TestRunner.equal(sickle.gatherMaterials.material_amber_sap, nil)
            end,
        },
    },
}
