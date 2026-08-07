--!strict

local Equipment = require("./Equipment")

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

--[[
    Everything the other five regions craft.

    There are eighty of those, and hand-authoring eighty part lists at the
    quality of the ten above is an art pass, not a wiring wave. What is
    not acceptable in the meantime is a player equipping a Vale maul and
    seeing nothing on their character, so a plan is derived rather than
    missing: the silhouette comes from the item's family (a maul reads as
    a maul, a bow as a bow) and the palette comes from its region.

    This is deliberately labelled. A derived plan carries `derived = true`
    so nothing downstream can mistake a recolour for authored work, and
    the art pass that replaces them is tracked as an owner-gated item
    alongside the regions' mesh dressing. The rule the visual standard
    sets -- recolouring an assembly is not new content -- is exactly why
    these are a floor rather than a deliverable.
]]
--[[
    The three armour slots the first ten items never used. These are
    authored here rather than borrowed, because there was nothing to
    borrow -- a coat is not a hood in a different colour -- and because a
    slot with no template would be an item that equips and never appears.
]]
local SLOT_TEMPLATE_PARTS: { [string]: { PartPlan } } = {
    body = {
        part(
            "CoatFront",
            "torso",
            "Block",
            { 2.05, 1.7, 0.42 },
            { 0, 0.1, -0.62 },
            { 0, 0, 0 },
            { 92, 78, 62 },
            "Fabric"
        ),
        part(
            "CoatBack",
            "torso",
            "Block",
            { 2.05, 1.7, 0.34 },
            { 0, 0.1, 0.58 },
            { 0, 0, 0 },
            { 72, 60, 48 },
            "Fabric"
        ),
        part(
            "ShoulderLeft",
            "torso",
            "Block",
            { 0.75, 0.42, 1.1 },
            { -1.05, 0.82, 0 },
            { 0, 0, -12 },
            { 108, 92, 74 },
            "Metal"
        ),
        part(
            "ShoulderRight",
            "torso",
            "Block",
            { 0.75, 0.42, 1.1 },
            { 1.05, 0.82, 0 },
            { 0, 0, 12 },
            { 108, 92, 74 },
            "Metal"
        ),
        part(
            "Belt",
            "torso",
            "Block",
            { 2.15, 0.3, 1.15 },
            { 0, -0.72, 0 },
            { 0, 0, 0 },
            { 58, 46, 36 },
            "Leather"
        ),
    },
    hands = {
        part(
            "CuffRight",
            "RightHand",
            "Block",
            { 1.1, 0.62, 1.1 },
            { 0, 0.34, 0 },
            { 0, 0, 0 },
            { 96, 82, 66 },
            "Leather"
        ),
        part(
            "CuffLeft",
            "leftHand",
            "Block",
            { 1.1, 0.62, 1.1 },
            { 0, 0.34, 0 },
            { 0, 0, 0 },
            { 96, 82, 66 },
            "Leather"
        ),
        part(
            "StrapRight",
            "RightHand",
            "Block",
            { 1.16, 0.16, 1.16 },
            { 0, 0.06, 0 },
            { 0, 0, 0 },
            { 62, 52, 42 },
            "Fabric"
        ),
        part(
            "StrapLeft",
            "leftHand",
            "Block",
            { 1.16, 0.16, 1.16 },
            { 0, 0.06, 0 },
            { 0, 0, 0 },
            { 62, 52, 42 },
            "Fabric"
        ),
    },
    charm = {
        part(
            "Cord",
            "torso",
            "Block",
            { 0.9, 0.08, 0.08 },
            { 0, 0.68, -0.6 },
            { 0, 0, 0 },
            { 148, 132, 102 },
            "Fabric"
        ),
        part(
            "Pendant",
            "torso",
            "Block",
            { 0.44, 0.5, 0.16 },
            { 0, 0.34, -0.66 },
            { 0, 0, 0 },
            { 214, 172, 88 },
            "Neon"
        ),
        part(
            "PendantBack",
            "torso",
            "Block",
            { 0.5, 0.56, 0.1 },
            { 0, 0.34, -0.58 },
            { 0, 0, 0 },
            { 92, 80, 58 },
            "Metal"
        ),
    },
}

local FAMILY_TEMPLATES: { [string]: string } = {
    -- weapon family -> the authored item whose silhouette it borrows
    bow = "gear_thornwood_bow",
    maul = "gear_heartwood_maul",
    lance = "gear_briar_lance",
    sling = "gear_foxfire_sling",
    edge = "gear_amber_edge",
    cudgel = "gear_warden_cudgel",
    -- armour slot -> same
    head = "gear_ironroot_hood",
    feet = "gear_bramble_boots",
}

local REGION_PALETTES: { [string]: { number } } = {
    bramblewake = { 78, 95, 48 },
    ironroot = { 112, 85, 49 },
    mireglass = { 76, 96, 88 },
    tempest = { 92, 96, 100 },
    frostmere = { 168, 202, 216 },
    cinderfall = { 148, 142, 134 },
}

local REGION_PREFIXES = table.freeze({
    { prefix = "meadow", region = "bramblewake" },
    { prefix = "bramble", region = "bramblewake" },
    { prefix = "bark", region = "bramblewake" },
    { prefix = "foxfire", region = "bramblewake" },
    { prefix = "heartwood", region = "bramblewake" },
    { prefix = "ironroot", region = "ironroot" },
    { prefix = "mireglass", region = "mireglass" },
    { prefix = "tempest", region = "tempest" },
    { prefix = "frostmere", region = "frostmere" },
    { prefix = "cinderfall", region = "cinderfall" },
    -- the display names do not all start with the region word, so the
    -- catalog's own material choice is the fallback signal
    { prefix = "coalglass", region = "ironroot" },
    { prefix = "stope", region = "ironroot" },
    { prefix = "drift", region = "ironroot" },
    { prefix = "pit", region = "ironroot" },
    { prefix = "slag", region = "ironroot" },
    { prefix = "shift", region = "ironroot" },
    { prefix = "reed", region = "mireglass" },
    { prefix = "bog", region = "mireglass" },
    { prefix = "punt", region = "mireglass" },
    { prefix = "mirror", region = "mireglass" },
    { prefix = "witchlight", region = "mireglass" },
    { prefix = "ferry", region = "mireglass" },
    { prefix = "jetty", region = "tempest" },
    { prefix = "ballast", region = "tempest" },
    { prefix = "gaff", region = "tempest" },
    { prefix = "halyard", region = "tempest" },
    { prefix = "amberglass", region = "tempest" },
    { prefix = "breakwater", region = "tempest" },
    { prefix = "vale", region = "frostmere" },
    { prefix = "thaw", region = "frostmere" },
    { prefix = "crevasse", region = "frostmere" },
    { prefix = "hush", region = "frostmere" },
    { prefix = "rime", region = "frostmere" },
    { prefix = "cloister", region = "frostmere" },
    { prefix = "tier", region = "cinderfall" },
    { prefix = "kiln", region = "cinderfall" },
    { prefix = "procession", region = "cinderfall" },
    { prefix = "cinder", region = "cinderfall" },
    { prefix = "memory", region = "cinderfall" },
    { prefix = "bailiff", region = "cinderfall" },
})

function GearVisualPlan.regionFor(itemId: string): string?
    local name = string.sub(itemId, 6)
    for _, entry in REGION_PREFIXES do
        if string.sub(name, 1, #entry.prefix) == entry.prefix then
            return entry.region
        end
    end
    return nil
end

local derivedCache: { [string]: ItemPlan } = {}

local function derive(itemId: string, definition: any): ItemPlan?
    local cached = derivedCache[itemId]
    if cached ~= nil then
        return cached
    end
    local templateId = FAMILY_TEMPLATES[definition.kind or ""] or FAMILY_TEMPLATES[definition.slot]
    local sourceParts: { PartPlan }? = if templateId ~= nil
            and DEFINITIONS[templateId] ~= nil
        then DEFINITIONS[templateId].parts
        else SLOT_TEMPLATE_PARTS[definition.slot]
    if sourceParts == nil then
        return nil
    end
    local palette = REGION_PALETTES[GearVisualPlan.regionFor(itemId) or ""]
    local parts: { PartPlan } = {}
    for _, source in sourceParts do
        table.insert(
            parts,
            part(
                source.name,
                source.target,
                source.shape,
                table.clone(source.size),
                table.clone(source.offset),
                table.clone(source.rotation),
                if palette ~= nil then palette else source.color,
                source.material
            )
        )
    end
    local plan: any = table.freeze({
        derived = true,
        itemId = itemId,
        parts = table.freeze(parts),
        slot = definition.slot,
    })
    derivedCache[itemId] = plan
    return plan
end

--[[
    An authored plan if there is one, a derived one if the item's family
    has a template, and nil only for an item nobody has described at all
    -- which the coverage spec refuses.
]]
function GearVisualPlan.get(itemId: any): ItemPlan?
    if type(itemId) ~= "string" then
        return nil
    end
    local authored = DEFINITIONS[itemId]
    if authored ~= nil then
        return authored
    end
    local definition = Equipment.get(itemId)
    if definition == nil then
        return nil
    end
    return derive(itemId, definition)
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
