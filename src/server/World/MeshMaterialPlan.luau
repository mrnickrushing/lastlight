--!strict

-- Roblox's GLB importer preserves the mesh groups used by the authored kit,
-- but model thumbnails and runtime loads otherwise fall back to gray
-- SmoothPlastic. Keep the material decision data-only so it can be validated
-- outside Studio; MeshTemplateLoader owns the actual Enum.Material mapping.

local MeshMaterialPlan = {}

export type Style = {
    material: string,
    color: { number },
}

local STYLES: { [string]: Style } = {
    bark_dark = { material = "Wood", color = { 36, 26, 24 } },
    bark_mid = { material = "Wood", color = { 62, 39, 30 } },
    bark_cut = { material = "WoodPlanks", color = { 121, 83, 52 } },
    pine_dark = { material = "LeafyGrass", color = { 18, 42, 32 } },
    pine_mid = { material = "LeafyGrass", color = { 42, 77, 51 } },
    leaf_dark = { material = "LeafyGrass", color = { 31, 68, 41 } },
    leaf_mid = { material = "LeafyGrass", color = { 58, 91, 54 } },
    moss = { material = "Grass", color = { 72, 104, 55 } },
    stone_dark = { material = "Slate", color = { 43, 52, 60 } },
    stone = { material = "Slate", color = { 75, 83, 89 } },
    fungus = { material = "Ground", color = { 135, 60, 29 } },
    foxfire = { material = "Neon", color = { 94, 206, 176 } },
    lantern_amber = { material = "Neon", color = { 255, 181, 76 } },
    iron = { material = "Metal", color = { 42, 46, 52 } },
    meadow = { material = "Grass", color = { 131, 93, 24 } },
}

-- Longest-first prevents `stone` and `bark` families from swallowing their
-- more specific dark/cut variants.
local ORDER = table.freeze({
    "lantern_amber",
    "stone_dark",
    "bark_dark",
    "bark_mid",
    "bark_cut",
    "pine_dark",
    "pine_mid",
    "leaf_dark",
    "leaf_mid",
    "foxfire",
    "fungus",
    "meadow",
    "stone",
    "moss",
    "iron",
})

function MeshMaterialPlan.groupForPart(partName: string): string?
    local normalized = string.lower(partName)
    for _, group in ORDER do
        if string.find(normalized, group, 1, true) ~= nil then
            return group
        end
    end
    return nil
end

function MeshMaterialPlan.styleForPart(partName: string): Style?
    local group = MeshMaterialPlan.groupForPart(partName)
    if group == nil then
        return nil
    end
    return STYLES[group]
end

function MeshMaterialPlan.groups(): { string }
    return table.clone(ORDER)
end

return table.freeze(MeshMaterialPlan)
