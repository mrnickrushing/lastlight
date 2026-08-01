--!strict

local MeshMaterialPlan = require("../../src/server/World/MeshMaterialPlan")
local TestRunner = require("../TestRunner")

return {
    name = "MeshMaterialPlan",
    cases = {
        {
            name = "maps every authored material group to a tactile Roblox material",
            run = function()
                local expected = {
                    bark_cut = "WoodPlanks",
                    bark_dark = "Wood",
                    bark_mid = "Wood",
                    fungus = "Ground",
                    iron = "Metal",
                    lantern_amber = "Neon",
                    leaf_dark = "LeafyGrass",
                    leaf_mid = "LeafyGrass",
                    meadow = "Grass",
                    moss = "Grass",
                    pine_dark = "LeafyGrass",
                    pine_mid = "LeafyGrass",
                    stone = "Slate",
                    stone_dark = "Slate",
                    foxfire = "Neon",
                }
                for group, material in expected do
                    local style = MeshMaterialPlan.styleForPart("mesh_asset__LL_" .. group)
                    TestRunner.truthy(style ~= nil, "missing style for " .. group)
                    TestRunner.equal((style :: MeshMaterialPlan.Style).material, material)
                end
                TestRunner.equal(#MeshMaterialPlan.groups(), 15)
            end,
        },
        {
            name = "prefers specific dark and cut groups over their base family",
            run = function()
                TestRunner.equal(
                    MeshMaterialPlan.groupForPart("mesh_house__LL_stone_dark"),
                    "stone_dark"
                )
                TestRunner.equal(
                    MeshMaterialPlan.groupForPart("mesh_house__LL_bark_cut"),
                    "bark_cut"
                )
            end,
        },
        {
            name = "does not guess a material for an unknown or custom PBR group",
            run = function()
                TestRunner.equal(MeshMaterialPlan.styleForPart("tripo_embedded_pbr"), nil)
            end,
        },
    },
}
