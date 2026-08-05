--!strict

local GearVisualPlan = {}

export type PartPlan = {
    name: string,
    target: string,
    shape: string,
    size: { number },
    offset: { number },
    rotation: { number },
    color: { number },
    material: string,
}

export type ItemPlan = {
    itemId: string,
    slot: string,
    parts: { PartPlan },
}

local function part(
    name: string,
    target: string,
    shape: string,
    size: { number },
    offset: { number },
    rotation: { number },
    color: { number },
    material: string
): PartPlan
    return table.freeze({
        name = name,
        target = target,
        shape = shape,
        size = table.freeze(size),
        offset = table.freeze(offset),
        rotation = table.freeze(rotation),
        color = table.freeze(table.clone(color)),
        material = material,
    })
end

local hoodCloth = { 42, 58, 43 }
local hoodShadow = { 27, 35, 29 }
local ironroot = { 112, 85, 49 }
local brambleLeather = { 62, 48, 36 }
local brambleSole = { 31, 28, 24 }
local livingVine = { 78, 95, 48 }

local DEFINITIONS: { [string]: ItemPlan } = {
    gear_thornwood_bow = table.freeze({
        itemId = "gear_thornwood_bow",
        slot = "weapon",
        parts = table.freeze({
            part(
                "BowStave",
                "RightHand",
                "Block",
                { 0.22, 3.1, 0.5 },
                { 0, -0.55, 0 },
                { 0, 0, 12 },
                { 112, 84, 52 },
                "Wood"
            ),
            part(
                "BowString",
                "RightHand",
                "Block",
                { 0.06, 2.9, 0.06 },
                { 0.3, -0.55, 0 },
                { 0, 0, 0 },
                { 214, 205, 186 },
                "Fabric"
            ),
        }),
    }),
    gear_heartwood_maul = table.freeze({
        itemId = "gear_heartwood_maul",
        slot = "weapon",
        parts = table.freeze({
            part(
                "MaulHaft",
                "RightHand",
                "Block",
                { 0.28, 3.2, 0.28 },
                { 0, -0.7, 0 },
                { 0, 0, 8 },
                { 96, 68, 44 },
                "Wood"
            ),
            part(
                "MaulHead",
                "RightHand",
                "Block",
                { 1.7, 0.95, 0.95 },
                { 0.18, -2.15, 0 },
                { 0, 0, 8 },
                { 139, 98, 54 },
                "Wood"
            ),
        }),
    }),
    gear_briar_lance = table.freeze({
        itemId = "gear_briar_lance",
        slot = "weapon",
        parts = table.freeze({
            part(
                "LanceShaft",
                "RightHand",
                "Block",
                { 0.24, 4.6, 0.24 },
                { 0, -1.3, 0 },
                { 0, 0, 4 },
                { 104, 128, 68 },
                "Wood"
            ),
            part(
                "LanceTip",
                "RightHand",
                "Wedge",
                { 0.4, 0.95, 0.4 },
                { 0.16, -3.9, 0 },
                { 0, 0, 184 },
                { 74, 96, 46 },
                "Wood"
            ),
        }),
    }),
    gear_foxfire_sling = table.freeze({
        itemId = "gear_foxfire_sling",
        slot = "weapon",
        parts = table.freeze({
            part(
                "SlingStrap",
                "RightHand",
                "Block",
                { 0.14, 2.3, 0.14 },
                { 0, -0.5, 0 },
                { 0, 0, 24 },
                { 78, 58, 41 },
                "Fabric"
            ),
            part(
                "SlingPouch",
                "RightHand",
                "Ball",
                { 0.68, 0.5, 0.68 },
                { 0.45, -1.5, 0 },
                { 0, 0, 0 },
                { 94, 206, 176 },
                "Fabric"
            ),
        }),
    }),
    gear_amber_edge = table.freeze({
        itemId = "gear_amber_edge",
        slot = "weapon",
        parts = table.freeze({
            part(
                "EdgeGrip",
                "RightHand",
                "Block",
                { 0.3, 0.95, 0.3 },
                { 0, -0.25, 0 },
                { 0, 0, 0 },
                { 73, 54, 38 },
                "Fabric"
            ),
            part(
                "EdgeBlade",
                "RightHand",
                "Wedge",
                { 0.24, 2.3, 0.72 },
                { 0, -1.85, 0.1 },
                { 0, 0, 0 },
                { 255, 197, 106 },
                "Glass"
            ),
        }),
    }),
    gear_warden_cudgel = table.freeze({
        itemId = "gear_warden_cudgel",
        slot = "weapon",
        parts = table.freeze({
            part(
                "CudgelShaft",
                "RightHand",
                "Block",
                { 0.34, 2.6, 0.34 },
                { 0, -0.6, 0 },
                { 0, 0, 6 },
                { 91, 62, 40 },
                "Wood"
            ),
            part(
                "CudgelHead",
                "RightHand",
                "Ball",
                { 0.85, 0.85, 0.85 },
                { 0.12, -1.95, 0 },
                { 0, 0, 0 },
                { 112, 151, 119 },
                "Wood"
            ),
        }),
    }),
    gear_ironroot_hood = table.freeze({
        itemId = "gear_ironroot_hood",
        slot = "head",
        parts = table.freeze({
            part(
                "Crown",
                "head",
                "Block",
                { 2.12, 0.5, 2.08 },
                { 0, 0.66, 0.04 },
                { 0, 0, 0 },
                hoodCloth,
                "Fabric"
            ),
            part(
                "BackDrape",
                "head",
                "Block",
                { 1.96, 1.52, 0.32 },
                { 0, -0.24, 0.91 },
                { -7, 0, 0 },
                hoodShadow,
                "Fabric"
            ),
            part(
                "LeftDrape",
                "head",
                "Wedge",
                { 0.38, 1.42, 1.72 },
                { -0.91, -0.15, 0.12 },
                { 0, 0, 0 },
                hoodCloth,
                "Fabric"
            ),
            part(
                "RightDrape",
                "head",
                "Wedge",
                { 0.38, 1.42, 1.72 },
                { 0.91, -0.15, 0.12 },
                { 0, 180, 0 },
                hoodCloth,
                "Fabric"
            ),
            part(
                "BrowBand",
                "head",
                "Block",
                { 2.02, 0.25, 0.3 },
                { 0, 0.25, -0.94 },
                { 0, 0, 0 },
                ironroot,
                "Wood"
            ),
            part(
                "LeftRootPin",
                "head",
                "Cylinder",
                { 0.18, 0.18, 0.52 },
                { -0.73, 0.32, -1.02 },
                { 0, 90, 22 },
                ironroot,
                "Wood"
            ),
            part(
                "RightRootPin",
                "head",
                "Cylinder",
                { 0.18, 0.18, 0.52 },
                { 0.73, 0.32, -1.02 },
                { 0, 90, -22 },
                ironroot,
                "Wood"
            ),
        }),
    }),
    gear_bramble_boots = table.freeze({
        itemId = "gear_bramble_boots",
        slot = "feet",
        parts = table.freeze({
            part(
                "LeftBoot",
                "leftFoot",
                "Block",
                { 1.18, 0.72, 1.48 },
                { 0, 0, -0.08 },
                { 0, 0, 0 },
                brambleLeather,
                "Fabric"
            ),
            part(
                "LeftSole",
                "leftFoot",
                "Block",
                { 1.26, 0.17, 1.58 },
                { 0, -0.42, -0.08 },
                { 0, 0, 0 },
                brambleSole,
                "Ground"
            ),
            part(
                "LeftCuff",
                "leftFoot",
                "Cylinder",
                { 0.28, 1.34, 1.34 },
                { 0, 0.42, 0 },
                { 0, 0, 90 },
                livingVine,
                "Wood"
            ),
            part(
                "LeftBramble",
                "leftFoot",
                "Block",
                { 0.17, 0.17, 1.62 },
                { 0, 0.09, -0.03 },
                { 0, 0, 31 },
                livingVine,
                "Wood"
            ),
            part(
                "RightBoot",
                "rightFoot",
                "Block",
                { 1.18, 0.72, 1.48 },
                { 0, 0, -0.08 },
                { 0, 0, 0 },
                brambleLeather,
                "Fabric"
            ),
            part(
                "RightSole",
                "rightFoot",
                "Block",
                { 1.26, 0.17, 1.58 },
                { 0, -0.42, -0.08 },
                { 0, 0, 0 },
                brambleSole,
                "Ground"
            ),
            part(
                "RightCuff",
                "rightFoot",
                "Cylinder",
                { 0.28, 1.34, 1.34 },
                { 0, 0.42, 0 },
                { 0, 0, 90 },
                livingVine,
                "Wood"
            ),
            part(
                "RightBramble",
                "rightFoot",
                "Block",
                { 0.17, 0.17, 1.62 },
                { 0, 0.09, -0.03 },
                { 0, 0, -31 },
                livingVine,
                "Wood"
            ),
        }),
    }),
}

function GearVisualPlan.get(itemId: any): ItemPlan?
    return if type(itemId) == "string" then DEFINITIONS[itemId] else nil
end

function GearVisualPlan.list(): { ItemPlan }
    local result = {}
    for _, definition in DEFINITIONS do
        table.insert(result, definition)
    end
    table.sort(result, function(a, b)
        return a.itemId < b.itemId
    end)
    return result
end

return table.freeze(GearVisualPlan)
