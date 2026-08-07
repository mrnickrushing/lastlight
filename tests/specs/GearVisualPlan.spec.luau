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
            --[[
                Eighty of the ninety items are derived rather than
                authored, and that is a labelled floor rather than a
                deliverable: the silhouette comes from the family and the
                palette from the region, so nothing equips invisibly while
                the art pass is outstanding. The label is what stops a
                recolour being mistaken for authored work later.
            ]]
            name = "derived plans are labelled, keep their family, and take their region's colour",
            run = function()
                local authored, derived = 0, 0
                for _, equipment in Equipment.list() do
                    local visual = GearVisualPlan.get(equipment.itemId) :: any
                    if visual.derived == true then
                        derived += 1
                        TestRunner.truthy(#visual.parts > 0, equipment.itemId .. " draws nothing")
                        TestRunner.truthy(
                            GearVisualPlan.regionFor(equipment.itemId) ~= nil,
                            equipment.itemId .. " belongs to no region"
                        )
                    else
                        authored += 1
                    end
                end
                -- eight, not ten: two of the authored plans are for the consumables,
                -- which are not equipment
                TestRunner.equal(authored, 8, "the authored plans went missing")
                TestRunner.truthy(derived > authored, "the derived set is not the bulk")

                -- a family keeps its silhouette across regions
                local bramblewake = GearVisualPlan.get("gear_heartwood_maul") :: any
                local vale = GearVisualPlan.get("gear_thaw_maul") :: any
                TestRunner.equal(#vale.parts, #bramblewake.parts)
                TestRunner.equal(vale.parts[1].shape, bramblewake.parts[1].shape)
                TestRunner.equal(vale.parts[1].target, bramblewake.parts[1].target)
                -- and takes its region's colour rather than the original's
                TestRunner.truthy(
                    vale.parts[1].color[1] ~= bramblewake.parts[1].color[1]
                        or vale.parts[1].color[2] ~= bramblewake.parts[1].color[2]
                )
                -- the three slots nothing authored still draw something
                for _, itemId in
                    { "gear_cinderfall_coat", "gear_tempest_wraps", "gear_frostmere_token" }
                do
                    local visual = GearVisualPlan.get(itemId) :: any
                    TestRunner.truthy(visual ~= nil, itemId .. " has no plan")
                    TestRunner.truthy(#visual.parts >= 3, itemId .. " is nearly invisible")
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
