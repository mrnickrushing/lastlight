--!strict

local Equipment = require("../../src/shared/Equipment")
local GearVisualPlan = require("../../src/shared/GearVisualPlan")
local TestRunner = require("../TestRunner")

return {
    name = "GearVisualPlan",
    cases = {
        {
            name = "covers every permanent equipment definition",
            run = function()
                for _, equipment in Equipment.list() do
                    local visual = GearVisualPlan.get(equipment.itemId)
                    TestRunner.truthy(visual, equipment.itemId .. " has no visual plan")
                    TestRunner.equal(visual.slot, equipment.slot)
                end
            end,
        },
        {
            name = "makes the hood a layered recognizable silhouette",
            run = function()
                local visual = GearVisualPlan.get("gear_ironroot_hood")
                TestRunner.equal(visual.slot, "head")
                TestRunner.truthy(#visual.parts >= 6)
                for _, partPlan in visual.parts do
                    TestRunner.equal(partPlan.target, "head")
                end
            end,
        },
        {
            name = "builds both boots with soles cuffs and brambles",
            run = function()
                local visual = GearVisualPlan.get("gear_bramble_boots")
                local left = 0
                local right = 0
                for _, partPlan in visual.parts do
                    if partPlan.target == "leftFoot" then
                        left += 1
                    elseif partPlan.target == "rightFoot" then
                        right += 1
                    end
                end
                TestRunner.truthy(left >= 4)
                TestRunner.equal(left, right)
            end,
        },
        {
            name = "uses restrained physical materials without neon",
            run = function()
                for _, visual in GearVisualPlan.list() do
                    for _, partPlan in visual.parts do
                        TestRunner.truthy(partPlan.material ~= "Neon")
                        TestRunner.equal(#partPlan.color, 3)
                    end
                end
            end,
        },
    },
}
