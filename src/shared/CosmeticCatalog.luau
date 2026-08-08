--!strict

--[[
    What a cosmetic is, and the hard rule about what it is not.

    **A cosmetic is presentation and nothing else.** No cosmetic appears in a
    stat, a gate, a capacity, a recipe, a drop table, a spawn rule or a reward.
    That is the same shape `TownDecorations` already has -- "identity only, no
    slot changes a stat" -- and it is what makes the *absence* of ownership
    branches in gameplay possible rather than merely required. There is nothing
    here for a gameplay branch to read, so the branch cannot be written by
    accident. `CosmeticNeutrality.spec` enforces it by walking every entry and
    refusing a number that is not a colour, a size, an offset, a rotation or an
    effect intensity.

    **A plan is a list of shapes, not a case in a renderer.** This is the
    #299 lesson applied before it can bite: the equip panel shipped as a
    hardcoded list of eight items and left ninety craftable items unwearable
    with every spec green, because a catalog entry and a thing a player can
    reach are different facts. A store is the same shape with more expensive
    consequences. So a cosmetic describes itself the way `GearVisualPlan` does
    -- parts with a target, a shape, a size, a colour and a material -- and a
    generic builder draws it. There is no per-cosmetic case to be missing,
    which means there is no per-cosmetic case that can be forgotten.

    **The Roblox product IDs are not here.** They do not exist until somebody
    creates the products in the Creator Dashboard and copies the numbers back;
    `Config.CommerceProductIds` is the table they land in and it is empty on
    purpose. A product in this catalog with no dashboard ID is a product that
    cannot be bought, which is the correct state for all of them right now.

    Five entries, one per slot, is the spine rather than the shop. The initial
    direct catalog is its own wave; what this file has to prove today is that
    the shape works end to end -- entry, plan, product, grant -- and that every
    part of that chain is reachable from the next.
]]

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

export type Cosmetic = {
    id: string,
    slot: string,
    --[[
        Which line this belongs to.

        A line is one look carried across all five slots, and it is the unit a
        player actually wants: nobody buys a lantern shell, they buy the look
        the lantern shell finishes. Naming the grouping in the data rather than
        in the display names is what lets a spec demand that a line is
        *complete* -- a set product that grants four of five slots is a set with
        a hole in it, and the hole is invisible until somebody wears it.
    ]]
    line: string,
    displayName: string,
    detail: string,
    derived: boolean,
    parts: { PartPlan },
}

export type Product = {
    id: string,
    line: string,
    displayName: string,
    detail: string,
    -- Permanent, always, and stated on the card. A cosmetic that expires is a
    -- cosmetic a player has to be told about twice and reminded about once,
    -- and neither conversation belongs in this game.
    permanence: string,
    grants: { string },
}

local CosmeticCatalog = {}

--[[
    The slots a cosmetic can occupy, and the one rule about them: a slot is a
    place on a character or in the world where a *look* is chosen. None of them
    is an equipment slot -- `Equipment` owns those, they carry stats, and the
    two lists must never overlap or a cosmetic would be wearing a stat.
]]
local SLOTS = table.freeze({
    "outfit",
    "weapon_skin",
    "tool_skin",
    "lantern_shell",
    "banner",
})

--[[
    The four lines, each named for a place the story has been.

    A line is the unit a player wants and the unit a set product sells, and
    every one of them carries all five slots -- which the census asserts, so a
    line with a hole in it fails on the day it is written rather than on the day
    somebody buys the set and finds a slot empty.

    They are named for regions rather than invented brands because this game
    already has six places with their own light, their own material and their
    own weather, and a look that says "I have been to Cinderfall" is worth more
    than a look that says "I bought the orange one".
]]
local LINES = table.freeze({
    table.freeze({
        id = "line_greenward",
        displayName = "THE GREENWARD",
        detail = "Bramblewake amber, oiled canvas, and the first keepers' green.",
    }),
    table.freeze({
        id = "line_ironroot",
        displayName = "THE IRONROOT",
        detail = "Pit leather, riveted iron, and a lamp built to survive a fall.",
    }),
    table.freeze({
        id = "line_mireglass",
        displayName = "THE MIREGLASS",
        detail = "Bog oak, reed binding, and glass the colour of standing water.",
    }),
    table.freeze({
        id = "line_cinderfall",
        displayName = "THE CINDERFALL",
        detail = "Scorched plate, bronze at the joins, and an ember that never went out.",
    }),
})

--[[
    Emotes are not here, and the omission is the honest one.

    The wave plan lists emote packs among the first products, and an emote is a
    motion rather than a shape -- there is no geometry to describe, and the
    only thing this file could offer for one is a glow, which
    VISUAL_QUALITY_STANDARD names directly as not being construction. An emote
    slot arrives with the animation pipeline that makes an emote possible, not
    before it. Shipping a lit sphere and calling it a salute would be the
    catalog claiming something it does not have.
]]

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
        color = table.freeze(color),
        material = material,
    })
end

--[[
    The spine's five. Each is a labelled floor in the #292 sense: real geometry
    a player can actually see, marked `derived` so nothing here claims to be an
    art pass. Replacing a derived plan with an authored one is an art pass and
    it is the owner's.
]]
local COSMETICS: { Cosmetic } = {
    {
        id = "cosmetic_lantern_keeper_coat",
        line = "line_greenward",
        slot = "outfit",
        displayName = "LANTERN KEEPER'S COAT",
        detail = "The long coat the first keepers wore, oiled against the night.",
        derived = true,
        parts = {
            part(
                "CoatBody",
                "UpperTorso",
                "Block",
                { 2.15, 1.85, 1.25 },
                { 0, -0.1, 0 },
                { 0, 0, 0 },
                { 58, 46, 38 },
                "Fabric"
            ),
            part(
                "CoatSkirt",
                "LowerTorso",
                "Block",
                { 2.05, 1.5, 1.2 },
                { 0, -0.55, 0 },
                { 0, 0, 0 },
                { 47, 37, 31 },
                "Fabric"
            ),
            part(
                "CoatTrim",
                "UpperTorso",
                "Block",
                { 2.2, 0.16, 1.3 },
                { 0, 0.72, 0 },
                { 0, 0, 0 },
                { 226, 168, 88 },
                "Fabric"
            ),
        },
    },
    {
        id = "cosmetic_amberglass_edge",
        line = "line_greenward",
        slot = "weapon_skin",
        displayName = "AMBERGLASS EDGE",
        detail = "A blade finish poured from cooled sap. It catches lantern light.",
        derived = true,
        parts = {
            part(
                "SkinSheath",
                "RightHand",
                "Block",
                { 0.32, 2.4, 0.14 },
                { 0, 1.1, 0 },
                { 0, 0, 0 },
                { 236, 176, 96 },
                "Glass"
            ),
            part(
                "SkinCollar",
                "RightHand",
                "Cylinder",
                { 0.3, 0.42, 0.42 },
                { 0, 0.12, 0 },
                { 0, 0, 90 },
                { 122, 88, 52 },
                "Metal"
            ),
        },
    },
    {
        id = "cosmetic_rootbound_grip",
        line = "line_greenward",
        slot = "tool_skin",
        displayName = "ROOTBOUND GRIP",
        detail = "A tool haft wrapped in living cord that never quite dries.",
        derived = true,
        parts = {
            part(
                "GripCore",
                "RightHand",
                "Cylinder",
                { 1.05, 0.26, 0.26 },
                { 0, 0.34, 0 },
                { 0, 0, 90 },
                { 62, 48, 34 },
                "Wood"
            ),
            -- The binding, as turns rather than a sleeve. A single tube is a
            -- recoloured cylinder; what makes cord read as cord is that you
            -- can count the wraps.
            part(
                "GripTurnLower",
                "RightHand",
                "Cylinder",
                { 0.16, 0.32, 0.32 },
                { 0, 0.02, 0 },
                { 0, 0, 90 },
                { 86, 104, 58 },
                "Fabric"
            ),
            part(
                "GripTurnMiddle",
                "RightHand",
                "Cylinder",
                { 0.16, 0.32, 0.32 },
                { 0, 0.34, 0 },
                { 0, 0, 90 },
                { 76, 94, 52 },
                "Fabric"
            ),
            part(
                "GripTurnUpper",
                "RightHand",
                "Cylinder",
                { 0.16, 0.32, 0.32 },
                { 0, 0.66, 0 },
                { 0, 0, 90 },
                { 86, 104, 58 },
                "Fabric"
            ),
            part(
                "GripPommel",
                "RightHand",
                "Ball",
                { 0.34, 0.34, 0.34 },
                { 0, -0.24, 0 },
                { 0, 0, 0 },
                { 108, 84, 52 },
                "Wood"
            ),
        },
    },
    {
        id = "cosmetic_foxfire_shell",
        line = "line_greenward",
        slot = "lantern_shell",
        displayName = "FOXFIRE SHELL",
        detail = "A lantern housing of pale green glass. The flame reads colder.",
        derived = true,
        parts = {
            part(
                "ShellGlass",
                "Lantern",
                "Block",
                { 0.95, 1.15, 0.95 },
                { 0, 0.1, 0 },
                { 0, 0, 0 },
                { 138, 214, 168 },
                "Glass"
            ),
            part(
                "ShellCap",
                "Lantern",
                "Block",
                { 1.1, 0.18, 1.1 },
                { 0, 0.78, 0 },
                { 0, 0, 0 },
                { 74, 82, 76 },
                "Metal"
            ),
        },
    },
    {
        id = "cosmetic_greenward_banner",
        line = "line_greenward",
        slot = "banner",
        displayName = "GREENWARD BANNER",
        detail = "The Greenward's mark, for a plot you have already built on.",
        derived = true,
        parts = {
            part(
                "BannerCloth",
                "Banner",
                "Block",
                { 2.4, 3.2, 0.12 },
                { 0, 0, 0 },
                { 0, 0, 0 },
                { 74, 108, 72 },
                "Fabric"
            ),
            part(
                "BannerPole",
                "Banner",
                "Cylinder",
                { 4.2, 0.16, 0.16 },
                { -1.3, -0.4, 0 },
                { 0, 0, 90 },
                { 96, 74, 48 },
                "Wood"
            ),
            -- A banner hangs from something. The crossbar is what turns a
            -- rectangle of cloth into a standard, and the finial is what stops
            -- the pole reading as a cut-off stick.
            part(
                "BannerCrossbar",
                "Banner",
                "Cylinder",
                { 2.8, 0.12, 0.12 },
                { 0, 1.66, 0 },
                { 0, 90, 90 },
                { 82, 64, 42 },
                "Wood"
            ),
            part(
                "BannerFinial",
                "Banner",
                "Ball",
                { 0.3, 0.3, 0.3 },
                { -1.3, 1.78, 0 },
                { 0, 0, 0 },
                { 214, 172, 96 },
                "Metal"
            ),
        },
    },
    --[[
        The Ironroot line: pit leather, rivets, and a lamp built to be dropped.
        Every silhouette here is heavier and squarer than the Greenward's, which
        is the point -- a line whose only difference is its palette is a
        recoloured cube wearing a second name.
    ]]
    {
        id = "cosmetic_ironroot_dredger_rig",
        slot = "outfit",
        line = "line_ironroot",
        displayName = "DREDGER'S RIG",
        detail = "The apron and strapping of somebody who works below the waterline.",
        derived = true,
        parts = {
            part(
                "RigApron",
                "UpperTorso",
                "Block",
                { 2.05, 2.2, 0.32 },
                { 0, -0.25, -0.72 },
                { 0, 0, 0 },
                { 74, 62, 50 },
                "Fabric"
            ),
            part(
                "RigBody",
                "UpperTorso",
                "Block",
                { 2.0, 1.8, 1.15 },
                { 0, 0, 0 },
                { 0, 0, 0 },
                { 52, 54, 56 },
                "Fabric"
            ),
            part(
                "RigPauldron",
                "UpperTorso",
                "Wedge",
                { 1.9, 0.5, 0.8 },
                { 0, 0.86, -0.2 },
                { 0, 0, 0 },
                { 96, 94, 88 },
                "Metal"
            ),
            part(
                "RigStrap",
                "UpperTorso",
                "Block",
                { 0.34, 2.3, 0.16 },
                { -0.55, -0.2, -0.86 },
                { 0, 0, 14 },
                { 46, 38, 32 },
                "Fabric"
            ),
            part(
                "RigBelt",
                "LowerTorso",
                "Block",
                { 2.05, 0.4, 1.2 },
                { 0, 0.3, 0 },
                { 0, 0, 0 },
                { 46, 38, 32 },
                "Fabric"
            ),
            part(
                "RigBuckle",
                "LowerTorso",
                "Block",
                { 0.44, 0.44, 0.2 },
                { 0, 0.3, -0.66 },
                { 0, 0, 0 },
                { 168, 150, 108 },
                "Metal"
            ),
        },
    },
    {
        id = "cosmetic_ironroot_slagcut_edge",
        slot = "weapon_skin",
        line = "line_ironroot",
        displayName = "SLAGCUT EDGE",
        detail = "A blade whose back was never filed smooth. It bites on the draw.",
        derived = true,
        parts = {
            part(
                "SlagBlade",
                "RightHand",
                "Block",
                { 0.3, 2.3, 0.16 },
                { 0, 1.05, 0 },
                { 0, 0, 0 },
                { 118, 122, 126 },
                "Metal"
            ),
            part(
                "SlagToothLow",
                "RightHand",
                "Wedge",
                { 0.26, 0.34, 0.16 },
                { 0.2, 0.5, 0 },
                { 0, 180, 0 },
                { 96, 98, 102 },
                "Metal"
            ),
            part(
                "SlagToothMid",
                "RightHand",
                "Wedge",
                { 0.26, 0.34, 0.16 },
                { 0.2, 1.05, 0 },
                { 0, 180, 0 },
                { 96, 98, 102 },
                "Metal"
            ),
            part(
                "SlagToothHigh",
                "RightHand",
                "Wedge",
                { 0.26, 0.34, 0.16 },
                { 0.2, 1.6, 0 },
                { 0, 180, 0 },
                { 96, 98, 102 },
                "Metal"
            ),
            part(
                "SlagGuard",
                "RightHand",
                "Block",
                { 0.9, 0.18, 0.3 },
                { 0, -0.1, 0 },
                { 0, 0, 0 },
                { 62, 58, 54 },
                "Metal"
            ),
        },
    },
    {
        id = "cosmetic_ironroot_pitgrip",
        slot = "tool_skin",
        line = "line_ironroot",
        displayName = "PITGRIP",
        detail = "An iron-ferruled haft with a lanyard ring, so a dropped tool comes back.",
        derived = true,
        parts = {
            part(
                "PitHaft",
                "RightHand",
                "Cylinder",
                { 1.15, 0.24, 0.24 },
                { 0, 0.36, 0 },
                { 0, 0, 90 },
                { 54, 46, 40 },
                "Wood"
            ),
            part(
                "PitFerruleLower",
                "RightHand",
                "Cylinder",
                { 0.22, 0.32, 0.32 },
                { 0, -0.1, 0 },
                { 0, 0, 90 },
                { 118, 122, 126 },
                "Metal"
            ),
            part(
                "PitFerruleUpper",
                "RightHand",
                "Cylinder",
                { 0.22, 0.32, 0.32 },
                { 0, 0.82, 0 },
                { 0, 0, 90 },
                { 118, 122, 126 },
                "Metal"
            ),
            part(
                "PitRing",
                "RightHand",
                "Cylinder",
                { 0.09, 0.46, 0.46 },
                { 0, -0.34, 0 },
                { 0, 90, 0 },
                { 148, 150, 152 },
                "Metal"
            ),
        },
    },
    {
        id = "cosmetic_ironroot_deepwatch_shell",
        slot = "lantern_shell",
        line = "line_ironroot",
        displayName = "DEEPWATCH SHELL",
        detail = "A caged safety lamp. The bars are what let you carry it into bad air.",
        derived = true,
        parts = {
            part(
                "DeepwatchGlass",
                "Lantern",
                "Cylinder",
                { 1.05, 0.82, 0.82 },
                { 0, 0.05, 0 },
                { 0, 0, 90 },
                { 226, 214, 178 },
                "Glass"
            ),
            part(
                "DeepwatchBarFront",
                "Lantern",
                "Block",
                { 0.1, 1.1, 0.1 },
                { 0, 0.05, 0.44 },
                { 0, 0, 0 },
                { 96, 98, 102 },
                "Metal"
            ),
            part(
                "DeepwatchBarBack",
                "Lantern",
                "Block",
                { 0.1, 1.1, 0.1 },
                { 0, 0.05, -0.44 },
                { 0, 0, 0 },
                { 96, 98, 102 },
                "Metal"
            ),
            part(
                "DeepwatchBarLeft",
                "Lantern",
                "Block",
                { 0.1, 1.1, 0.1 },
                { -0.44, 0.05, 0 },
                { 0, 0, 0 },
                { 96, 98, 102 },
                "Metal"
            ),
            part(
                "DeepwatchBarRight",
                "Lantern",
                "Block",
                { 0.1, 1.1, 0.1 },
                { 0.44, 0.05, 0 },
                { 0, 0, 0 },
                { 96, 98, 102 },
                "Metal"
            ),
            part(
                "DeepwatchDome",
                "Lantern",
                "Ball",
                { 1.02, 0.62, 1.02 },
                { 0, 0.72, 0 },
                { 0, 0, 0 },
                { 74, 76, 78 },
                "Metal"
            ),
            part(
                "DeepwatchBase",
                "Lantern",
                "Cylinder",
                { 0.2, 1.06, 1.06 },
                { 0, -0.55, 0 },
                { 0, 0, 90 },
                { 74, 76, 78 },
                "Metal"
            ),
        },
    },
    {
        id = "cosmetic_ironroot_pickmark_banner",
        slot = "banner",
        line = "line_ironroot",
        displayName = "PICKMARK BANNER",
        detail = "Two crossed picks over grey. The mark cut into every Ironroot beam.",
        derived = true,
        parts = {
            part(
                "PickmarkCloth",
                "Banner",
                "Block",
                { 2.4, 3.0, 0.12 },
                { 0, 0, 0 },
                { 0, 0, 0 },
                { 88, 92, 96 },
                "Fabric"
            ),
            part(
                "PickmarkPole",
                "Banner",
                "Cylinder",
                { 4.2, 0.16, 0.16 },
                { -1.3, -0.4, 0 },
                { 0, 0, 90 },
                { 62, 58, 54 },
                "Metal"
            ),
            part(
                "PickmarkCrossbar",
                "Banner",
                "Cylinder",
                { 2.8, 0.12, 0.12 },
                { 0, 1.56, 0 },
                { 0, 90, 90 },
                { 62, 58, 54 },
                "Metal"
            ),
            part(
                "PickmarkHaftLeft",
                "Banner",
                "Block",
                { 1.9, 0.14, 0.06 },
                { 0, 0, 0.09 },
                { 0, 0, 34 },
                { 168, 150, 108 },
                "Metal"
            ),
            part(
                "PickmarkHaftRight",
                "Banner",
                "Block",
                { 1.9, 0.14, 0.06 },
                { 0, 0, 0.09 },
                { 0, 0, -34 },
                { 168, 150, 108 },
                "Metal"
            ),
            part(
                "PickmarkHead",
                "Banner",
                "Wedge",
                { 0.5, 0.34, 0.1 },
                { 0, 0.85, 0.12 },
                { 0, 0, 0 },
                { 198, 186, 142 },
                "Metal"
            ),
        },
    },
    --[[
        The Mireglass line: bog oak, reed binding, and glass the colour of
        standing water. Rounder and thinner than the Ironroot's, so the two read
        apart in a silhouette before either name is read.
    ]]
    {
        id = "cosmetic_mireglass_wader_cloak",
        slot = "outfit",
        line = "line_mireglass",
        displayName = "WADER'S CLOAK",
        detail = "A hooded cloak cut long at the back and short at the knee.",
        derived = true,
        parts = {
            part(
                "WaderCowl",
                "Head",
                "Wedge",
                { 1.5, 0.9, 1.3 },
                { 0, 0.45, 0.1 },
                { 0, 180, 0 },
                { 62, 78, 70 },
                "Fabric"
            ),
            part(
                "WaderCape",
                "UpperTorso",
                "Block",
                { 2.25, 1.9, 1.3 },
                { 0, -0.05, 0.06 },
                { 0, 0, 0 },
                { 70, 88, 78 },
                "Fabric"
            ),
            part(
                "WaderTail",
                "LowerTorso",
                "Block",
                { 2.1, 1.7, 0.28 },
                { 0, -0.6, 0.6 },
                { 0, 0, 0 },
                { 58, 74, 66 },
                "Fabric"
            ),
            part(
                "WaderClasp",
                "UpperTorso",
                "Ball",
                { 0.36, 0.36, 0.36 },
                { 0, 0.72, -0.66 },
                { 0, 0, 0 },
                { 142, 198, 176 },
                "Glass"
            ),
        },
    },
    {
        id = "cosmetic_mireglass_shardline",
        slot = "weapon_skin",
        line = "line_mireglass",
        displayName = "SHARDLINE",
        detail = "A blade of set glass, each shard a little out of true with the last.",
        derived = true,
        parts = {
            part(
                "ShardLower",
                "RightHand",
                "Wedge",
                { 0.34, 0.95, 0.13 },
                { 0, 0.5, 0 },
                { 0, 0, 0 },
                { 150, 202, 184 },
                "Glass"
            ),
            part(
                "ShardMiddle",
                "RightHand",
                "Wedge",
                { 0.29, 0.95, 0.12 },
                { 0, 1.28, 0 },
                { 0, 0, 5 },
                { 168, 214, 196 },
                "Glass"
            ),
            part(
                "ShardTip",
                "RightHand",
                "Wedge",
                { 0.22, 0.8, 0.11 },
                { 0, 2.0, 0 },
                { 0, 0, -6 },
                { 190, 226, 210 },
                "Glass"
            ),
            part(
                "ShardWrap",
                "RightHand",
                "Cylinder",
                { 0.44, 0.3, 0.3 },
                { 0, 0.02, 0 },
                { 0, 0, 90 },
                { 54, 46, 40 },
                "Fabric"
            ),
        },
    },
    {
        id = "cosmetic_mireglass_reedbind",
        slot = "tool_skin",
        line = "line_mireglass",
        displayName = "REEDBIND",
        detail = "A haft bound in split reed, with a tuft left long at the butt.",
        derived = true,
        parts = {
            part(
                "ReedHaft",
                "RightHand",
                "Cylinder",
                { 1.1, 0.22, 0.22 },
                { 0, 0.36, 0 },
                { 0, 0, 90 },
                { 66, 58, 44 },
                "Wood"
            ),
            part(
                "ReedBandLower",
                "RightHand",
                "Cylinder",
                { 0.14, 0.3, 0.3 },
                { 0, 0.02, 0 },
                { 0, 0, 90 },
                { 128, 148, 92 },
                "Fabric"
            ),
            part(
                "ReedBandMiddle",
                "RightHand",
                "Cylinder",
                { 0.14, 0.3, 0.3 },
                { 0, 0.4, 0 },
                { 0, 0, 90 },
                { 112, 132, 80 },
                "Fabric"
            ),
            part(
                "ReedBandUpper",
                "RightHand",
                "Cylinder",
                { 0.14, 0.3, 0.3 },
                { 0, 0.78, 0 },
                { 0, 0, 90 },
                { 128, 148, 92 },
                "Fabric"
            ),
            part(
                "ReedTuftLeft",
                "RightHand",
                "Block",
                { 0.07, 0.62, 0.07 },
                { -0.12, -0.4, 0 },
                { 0, 0, 22 },
                { 156, 168, 104 },
                "Fabric"
            ),
            part(
                "ReedTuftRight",
                "RightHand",
                "Block",
                { 0.07, 0.62, 0.07 },
                { 0.12, -0.4, 0 },
                { 0, 0, -22 },
                { 142, 154, 94 },
                "Fabric"
            ),
        },
    },
    {
        id = "cosmetic_mireglass_bogfire_shell",
        slot = "lantern_shell",
        line = "line_mireglass",
        displayName = "BOGFIRE SHELL",
        detail = "A round bowl under a wide brim, so rain never reaches the wick.",
        derived = true,
        parts = {
            part(
                "BogfireBowl",
                "Lantern",
                "Ball",
                { 1.0, 1.0, 1.0 },
                { 0, -0.05, 0 },
                { 0, 0, 0 },
                { 158, 210, 190 },
                "Glass"
            ),
            part(
                "BogfireBrim",
                "Lantern",
                "Cylinder",
                { 0.14, 1.5, 1.5 },
                { 0, 0.6, 0 },
                { 0, 0, 90 },
                { 66, 74, 68 },
                "Metal"
            ),
            part(
                "BogfireCollar",
                "Lantern",
                "Cylinder",
                { 0.2, 0.66, 0.66 },
                { 0, 0.5, 0 },
                { 0, 0, 90 },
                { 84, 92, 86 },
                "Metal"
            ),
            part(
                "BogfireHook",
                "Lantern",
                "Cylinder",
                { 0.08, 0.42, 0.42 },
                { 0, 0.92, 0 },
                { 0, 90, 0 },
                { 108, 116, 110 },
                "Metal"
            ),
        },
    },
    {
        id = "cosmetic_mireglass_stillwater_banner",
        slot = "banner",
        line = "line_mireglass",
        displayName = "STILLWATER BANNER",
        detail = "A long pennant weighted at the tail, so it hangs even in wind.",
        derived = true,
        parts = {
            part(
                "StillwaterCloth",
                "Banner",
                "Block",
                { 1.5, 3.6, 0.1 },
                { 0.1, -0.2, 0 },
                { 0, 0, 0 },
                { 76, 112, 104 },
                "Fabric"
            ),
            part(
                "StillwaterTail",
                "Banner",
                "Wedge",
                { 1.5, 0.7, 0.1 },
                { 0.1, -2.35, 0 },
                { 0, 0, 180 },
                { 64, 96, 90 },
                "Fabric"
            ),
            part(
                "StillwaterPole",
                "Banner",
                "Cylinder",
                { 4.4, 0.14, 0.14 },
                { -1.05, -0.4, 0 },
                { 0, 0, 90 },
                { 66, 58, 44 },
                "Wood"
            ),
            part(
                "StillwaterCrossbar",
                "Banner",
                "Cylinder",
                { 2.0, 0.1, 0.1 },
                { -0.2, 1.66, 0 },
                { 0, 90, 90 },
                { 66, 58, 44 },
                "Wood"
            ),
            part(
                "StillwaterWeight",
                "Banner",
                "Ball",
                { 0.26, 0.26, 0.26 },
                { 0.1, -2.78, 0 },
                { 0, 0, 0 },
                { 142, 198, 176 },
                "Glass"
            ),
        },
    },
    --[[
        The Cinderfall line: scorched plate, bronze at the joins, and one ember
        inset that is the only lit thing on it. Squarest of the four, and the
        only one that carries a highlight rather than a colour.
    ]]
    {
        id = "cosmetic_cinderfall_ashwarden_plate",
        slot = "outfit",
        line = "line_cinderfall",
        displayName = "ASHWARDEN PLATE",
        detail = "Plate that went through the fall and came out darker.",
        derived = true,
        parts = {
            part(
                "AshwardenChest",
                "UpperTorso",
                "Block",
                { 2.1, 1.85, 1.25 },
                { 0, 0, 0 },
                { 0, 0, 0 },
                { 44, 40, 38 },
                "Metal"
            ),
            part(
                "AshwardenPauldronLeft",
                "UpperTorso",
                "Wedge",
                { 0.8, 0.6, 1.0 },
                { -1.1, 0.7, 0 },
                { 0, 0, -18 },
                { 62, 56, 52 },
                "Metal"
            ),
            part(
                "AshwardenPauldronRight",
                "UpperTorso",
                "Wedge",
                { 0.8, 0.6, 1.0 },
                { 1.1, 0.7, 0 },
                { 0, 180, 18 },
                { 62, 56, 52 },
                "Metal"
            ),
            part(
                "AshwardenTrim",
                "UpperTorso",
                "Block",
                { 2.15, 0.14, 1.3 },
                { 0, -0.82, 0 },
                { 0, 0, 0 },
                { 176, 128, 74 },
                "Metal"
            ),
            part(
                "AshwardenFauld",
                "LowerTorso",
                "Block",
                { 2.0, 1.0, 1.2 },
                { 0, -0.3, 0 },
                { 0, 0, 0 },
                { 52, 46, 42 },
                "Metal"
            ),
        },
    },
    {
        id = "cosmetic_cinderfall_emberbrand",
        slot = "weapon_skin",
        line = "line_cinderfall",
        displayName = "EMBERBRAND",
        detail = "A fuller that never cooled. The light in it is a finish, not a fire.",
        derived = true,
        parts = {
            part(
                "EmberBlade",
                "RightHand",
                "Block",
                { 0.34, 2.4, 0.15 },
                { 0, 1.1, 0 },
                { 0, 0, 0 },
                { 52, 46, 44 },
                "Metal"
            ),
            part(
                "EmberFuller",
                "RightHand",
                "Block",
                { 0.1, 2.0, 0.17 },
                { 0, 1.1, 0 },
                { 0, 0, 0 },
                { 226, 120, 54 },
                "Neon"
            ),
            part(
                "EmberGuard",
                "RightHand",
                "Block",
                { 1.0, 0.2, 0.32 },
                { 0, -0.12, 0 },
                { 0, 0, 0 },
                { 176, 128, 74 },
                "Metal"
            ),
            part(
                "EmberPommel",
                "RightHand",
                "Ball",
                { 0.32, 0.32, 0.32 },
                { 0, -0.46, 0 },
                { 0, 0, 0 },
                { 176, 128, 74 },
                "Metal"
            ),
        },
    },
    {
        id = "cosmetic_cinderfall_forgegrip",
        slot = "tool_skin",
        line = "line_cinderfall",
        displayName = "FORGEGRIP",
        detail = "A bronze-collared haft wrapped against heat, with a counterweight.",
        derived = true,
        parts = {
            part(
                "ForgeHaft",
                "RightHand",
                "Cylinder",
                { 1.05, 0.26, 0.26 },
                { 0, 0.4, 0 },
                { 0, 0, 90 },
                { 48, 42, 40 },
                "Metal"
            ),
            part(
                "ForgeCollar",
                "RightHand",
                "Cylinder",
                { 0.26, 0.38, 0.38 },
                { 0, 0.86, 0 },
                { 0, 0, 90 },
                { 176, 128, 74 },
                "Metal"
            ),
            part(
                "ForgeWrapLower",
                "RightHand",
                "Cylinder",
                { 0.2, 0.34, 0.34 },
                { 0, 0.14, 0 },
                { 0, 0, 90 },
                { 92, 62, 50 },
                "Fabric"
            ),
            part(
                "ForgeWrapUpper",
                "RightHand",
                "Cylinder",
                { 0.2, 0.34, 0.34 },
                { 0, 0.52, 0 },
                { 0, 0, 90 },
                { 78, 52, 42 },
                "Fabric"
            ),
            part(
                "ForgeCounterweight",
                "RightHand",
                "Wedge",
                { 0.42, 0.42, 0.42 },
                { 0, -0.3, 0 },
                { 0, 0, 0 },
                { 176, 128, 74 },
                "Metal"
            ),
        },
    },
    {
        id = "cosmetic_cinderfall_ashfall_shell",
        slot = "lantern_shell",
        line = "line_cinderfall",
        displayName = "ASHFALL SHELL",
        detail = "A vented iron housing. Ash falls through it instead of settling.",
        derived = true,
        parts = {
            part(
                "AshfallBody",
                "Lantern",
                "Cylinder",
                { 1.15, 0.9, 0.9 },
                { 0, 0, 0 },
                { 0, 0, 90 },
                { 58, 52, 48 },
                "Metal"
            ),
            part(
                "AshfallVentFront",
                "Lantern",
                "Block",
                { 0.78, 0.1, 0.14 },
                { 0, 0.2, 0.44 },
                { 0, 0, 0 },
                { 226, 120, 54 },
                "Neon"
            ),
            part(
                "AshfallVentBack",
                "Lantern",
                "Block",
                { 0.78, 0.1, 0.14 },
                { 0, -0.2, 0.44 },
                { 0, 0, 0 },
                { 226, 120, 54 },
                "Neon"
            ),
            part(
                "AshfallCap",
                "Lantern",
                "Cylinder",
                { 0.2, 1.16, 1.16 },
                { 0, 0.66, 0 },
                { 0, 0, 90 },
                { 78, 70, 64 },
                "Metal"
            ),
            part(
                "AshfallFinLeft",
                "Lantern",
                "Wedge",
                { 0.14, 0.5, 0.5 },
                { -0.5, 0.4, 0 },
                { 0, 0, 0 },
                { 78, 70, 64 },
                "Metal"
            ),
            part(
                "AshfallFinRight",
                "Lantern",
                "Wedge",
                { 0.14, 0.5, 0.5 },
                { 0.5, 0.4, 0 },
                { 0, 180, 0 },
                { 78, 70, 64 },
                "Metal"
            ),
        },
    },
    {
        id = "cosmetic_cinderfall_lastfire_banner",
        slot = "banner",
        line = "line_cinderfall",
        displayName = "LASTFIRE BANNER",
        detail = "Burnt through in two places, and flown anyway.",
        derived = true,
        parts = {
            part(
                "LastfireClothLeft",
                "Banner",
                "Block",
                { 1.0, 3.0, 0.1 },
                { -0.7, -0.1, 0 },
                { 0, 0, 0 },
                { 74, 52, 46 },
                "Fabric"
            ),
            part(
                "LastfireClothRight",
                "Banner",
                "Block",
                { 1.0, 2.6, 0.1 },
                { 0.7, -0.3, 0 },
                { 0, 0, 0 },
                { 74, 52, 46 },
                "Fabric"
            ),
            part(
                "LastfireScorch",
                "Banner",
                "Block",
                { 2.4, 0.3, 0.11 },
                { 0, 1.2, 0 },
                { 0, 0, 0 },
                { 42, 34, 32 },
                "Fabric"
            ),
            part(
                "LastfirePole",
                "Banner",
                "Cylinder",
                { 4.2, 0.16, 0.16 },
                { -1.3, -0.4, 0 },
                { 0, 0, 90 },
                { 58, 52, 48 },
                "Metal"
            ),
            part(
                "LastfireCrossbar",
                "Banner",
                "Cylinder",
                { 2.8, 0.12, 0.12 },
                { 0, 1.6, 0 },
                { 0, 90, 90 },
                { 58, 52, 48 },
                "Metal"
            ),
            part(
                "LastfireFinial",
                "Banner",
                "Wedge",
                { 0.3, 0.6, 0.3 },
                { -1.3, 1.9, 0 },
                { 0, 0, 0 },
                { 226, 120, 54 },
                "Neon"
            ),
        },
    },
}

--[[
    What can be bought, and exactly what it hands over.

    One product per cosmetic here, because the spine has nothing to bundle yet.
    A product is the unit a receipt names; a cosmetic is the unit a player
    wears. Keeping them separate from the start is what lets a later bundle
    grant three things without any of the grant logic learning about bundles.
]]
local PRODUCTS: { Product } = {
    {
        id = "product_lantern_keeper_coat",
        line = "line_greenward",
        displayName = "LANTERN KEEPER'S COAT",
        detail = "An outfit for the traveller who keeps the light.",
        permanence = "permanent",
        grants = { "cosmetic_lantern_keeper_coat" },
    },
    {
        id = "product_amberglass_edge",
        line = "line_greenward",
        displayName = "AMBERGLASS EDGE",
        detail = "A weapon finish. Changes how a blade looks and nothing else.",
        permanence = "permanent",
        grants = { "cosmetic_amberglass_edge" },
    },
    {
        id = "product_rootbound_grip",
        line = "line_greenward",
        displayName = "ROOTBOUND GRIP",
        detail = "A tool finish, for every tool you carry.",
        permanence = "permanent",
        grants = { "cosmetic_rootbound_grip" },
    },
    {
        id = "product_foxfire_shell",
        line = "line_greenward",
        displayName = "FOXFIRE SHELL",
        detail = "A lantern housing. The light is the same light.",
        permanence = "permanent",
        grants = { "cosmetic_foxfire_shell" },
    },
    {
        id = "product_greenward_banner",
        line = "line_greenward",
        displayName = "GREENWARD BANNER",
        detail = "A banner for a plot you have already built on.",
        permanence = "permanent",
        grants = { "cosmetic_greenward_banner" },
    },
    {
        id = "product_ironroot_dredger_rig",
        line = "line_ironroot",
        displayName = "DREDGER'S RIG",
        detail = "An outfit for somebody who works below the waterline.",
        permanence = "permanent",
        grants = { "cosmetic_ironroot_dredger_rig" },
    },
    {
        id = "product_ironroot_slagcut_edge",
        line = "line_ironroot",
        displayName = "SLAGCUT EDGE",
        detail = "A weapon finish with a back that was never filed smooth.",
        permanence = "permanent",
        grants = { "cosmetic_ironroot_slagcut_edge" },
    },
    {
        id = "product_ironroot_pitgrip",
        line = "line_ironroot",
        displayName = "PITGRIP",
        detail = "A tool finish, iron-ferruled, with a lanyard ring.",
        permanence = "permanent",
        grants = { "cosmetic_ironroot_pitgrip" },
    },
    {
        id = "product_ironroot_deepwatch_shell",
        line = "line_ironroot",
        displayName = "DEEPWATCH SHELL",
        detail = "A caged lantern housing. The light is the same light.",
        permanence = "permanent",
        grants = { "cosmetic_ironroot_deepwatch_shell" },
    },
    {
        id = "product_ironroot_pickmark_banner",
        line = "line_ironroot",
        displayName = "PICKMARK BANNER",
        detail = "A banner for a plot you have already built on.",
        permanence = "permanent",
        grants = { "cosmetic_ironroot_pickmark_banner" },
    },
    {
        id = "product_mireglass_wader_cloak",
        line = "line_mireglass",
        displayName = "WADER'S CLOAK",
        detail = "An outfit cut long at the back and short at the knee.",
        permanence = "permanent",
        grants = { "cosmetic_mireglass_wader_cloak" },
    },
    {
        id = "product_mireglass_shardline",
        line = "line_mireglass",
        displayName = "SHARDLINE",
        detail = "A weapon finish of set glass, shard by shard.",
        permanence = "permanent",
        grants = { "cosmetic_mireglass_shardline" },
    },
    {
        id = "product_mireglass_reedbind",
        line = "line_mireglass",
        displayName = "REEDBIND",
        detail = "A tool finish bound in split reed.",
        permanence = "permanent",
        grants = { "cosmetic_mireglass_reedbind" },
    },
    {
        id = "product_mireglass_bogfire_shell",
        line = "line_mireglass",
        displayName = "BOGFIRE SHELL",
        detail = "A lantern housing under a wide brim.",
        permanence = "permanent",
        grants = { "cosmetic_mireglass_bogfire_shell" },
    },
    {
        id = "product_mireglass_stillwater_banner",
        line = "line_mireglass",
        displayName = "STILLWATER BANNER",
        detail = "A banner weighted at the tail so it hangs even in wind.",
        permanence = "permanent",
        grants = { "cosmetic_mireglass_stillwater_banner" },
    },
    {
        id = "product_cinderfall_ashwarden_plate",
        line = "line_cinderfall",
        displayName = "ASHWARDEN PLATE",
        detail = "An outfit that went through the fall and came out darker.",
        permanence = "permanent",
        grants = { "cosmetic_cinderfall_ashwarden_plate" },
    },
    {
        id = "product_cinderfall_emberbrand",
        line = "line_cinderfall",
        displayName = "EMBERBRAND",
        detail = "A weapon finish with a fuller that never cooled.",
        permanence = "permanent",
        grants = { "cosmetic_cinderfall_emberbrand" },
    },
    {
        id = "product_cinderfall_forgegrip",
        line = "line_cinderfall",
        displayName = "FORGEGRIP",
        detail = "A tool finish wrapped against heat.",
        permanence = "permanent",
        grants = { "cosmetic_cinderfall_forgegrip" },
    },
    {
        id = "product_cinderfall_ashfall_shell",
        line = "line_cinderfall",
        displayName = "ASHFALL SHELL",
        detail = "A vented lantern housing. The light is the same light.",
        permanence = "permanent",
        grants = { "cosmetic_cinderfall_ashfall_shell" },
    },
    {
        id = "product_cinderfall_lastfire_banner",
        line = "line_cinderfall",
        displayName = "LASTFIRE BANNER",
        detail = "A banner burnt through in two places, and flown anyway.",
        permanence = "permanent",
        grants = { "cosmetic_cinderfall_lastfire_banner" },
    },
    --[[
        The sets, and the only reason bundles exist yet.

        A line is what a player actually wants -- nobody wants a lantern shell,
        they want the look the lantern shell finishes -- and a set is that
        sentence as a product. It is also the case the grant path was built for
        in wave E and had nothing to exercise: a product that hands over five
        cosmetics at once, idempotently, on one purchase id.

        Every set grants exactly its line's five, which the census asserts
        rather than trusts. A set with four of five slots in it is a set with a
        hole, and the hole is invisible until somebody wears it.
    ]]
    {
        id = "product_set_greenward",
        line = "line_greenward",
        displayName = "THE GREENWARD SET",
        detail = "Every piece of the Greenward look, in one purchase.",
        permanence = "permanent",
        grants = {
            "cosmetic_lantern_keeper_coat",
            "cosmetic_amberglass_edge",
            "cosmetic_rootbound_grip",
            "cosmetic_foxfire_shell",
            "cosmetic_greenward_banner",
        },
    },
    {
        id = "product_set_ironroot",
        line = "line_ironroot",
        displayName = "THE IRONROOT SET",
        detail = "Every piece of the Ironroot look, in one purchase.",
        permanence = "permanent",
        grants = {
            "cosmetic_ironroot_dredger_rig",
            "cosmetic_ironroot_slagcut_edge",
            "cosmetic_ironroot_pitgrip",
            "cosmetic_ironroot_deepwatch_shell",
            "cosmetic_ironroot_pickmark_banner",
        },
    },
    {
        id = "product_set_mireglass",
        line = "line_mireglass",
        displayName = "THE MIREGLASS SET",
        detail = "Every piece of the Mireglass look, in one purchase.",
        permanence = "permanent",
        grants = {
            "cosmetic_mireglass_wader_cloak",
            "cosmetic_mireglass_shardline",
            "cosmetic_mireglass_reedbind",
            "cosmetic_mireglass_bogfire_shell",
            "cosmetic_mireglass_stillwater_banner",
        },
    },
    {
        id = "product_set_cinderfall",
        line = "line_cinderfall",
        displayName = "THE CINDERFALL SET",
        detail = "Every piece of the Cinderfall look, in one purchase.",
        permanence = "permanent",
        grants = {
            "cosmetic_cinderfall_ashwarden_plate",
            "cosmetic_cinderfall_emberbrand",
            "cosmetic_cinderfall_forgegrip",
            "cosmetic_cinderfall_ashfall_shell",
            "cosmetic_cinderfall_lastfire_banner",
        },
    },
}

local slotSet: { [string]: boolean } = {}
for _, slot in SLOTS do
    slotSet[slot] = true
end

local lineSet: { [string]: boolean } = {}
for _, line in LINES do
    assert(lineSet[line.id] == nil, "duplicate line: " .. line.id)
    lineSet[line.id] = true
end

local cosmeticById: { [string]: Cosmetic } = {}
for _, cosmetic in COSMETICS do
    assert(cosmeticById[cosmetic.id] == nil, "duplicate cosmetic: " .. cosmetic.id)
    assert(slotSet[cosmetic.slot], cosmetic.id .. " names no slot: " .. cosmetic.slot)
    assert(lineSet[cosmetic.line], cosmetic.id .. " names no line: " .. cosmetic.line)
    assert(#cosmetic.parts > 0, cosmetic.id .. " has no geometry")
    -- table.freeze is shallow, so the parts array has to be frozen too or the
    -- catalog is a frozen table pointing at a mutable list.
    table.freeze(cosmetic.parts)
    cosmeticById[cosmetic.id] = table.freeze(cosmetic)
end

local productById: { [string]: Product } = {}
for _, product in PRODUCTS do
    assert(productById[product.id] == nil, "duplicate product: " .. product.id)
    assert(lineSet[product.line], product.id .. " names no line: " .. product.line)
    assert(#product.grants > 0, product.id .. " grants nothing")
    for _, cosmeticId in product.grants do
        assert(
            cosmeticById[cosmeticId] ~= nil,
            product.id .. " grants a cosmetic that does not exist: " .. cosmeticId
        )
    end
    table.freeze(product.grants)
    productById[product.id] = table.freeze(product)
end

function CosmeticCatalog.slots(): { string }
    return SLOTS
end

function CosmeticCatalog.lines(): { { id: string, displayName: string, detail: string } }
    return LINES
end

function CosmeticCatalog.isLine(lineId: any): boolean
    return type(lineId) == "string" and lineSet[lineId] == true
end

function CosmeticCatalog.isSlot(slot: any): boolean
    return type(slot) == "string" and slotSet[slot] == true
end

function CosmeticCatalog.list(): { Cosmetic }
    return COSMETICS
end

function CosmeticCatalog.get(cosmeticId: any): Cosmetic?
    if type(cosmeticId) ~= "string" then
        return nil
    end
    return cosmeticById[cosmeticId]
end

function CosmeticCatalog.products(): { Product }
    return PRODUCTS
end

function CosmeticCatalog.product(productId: any): Product?
    if type(productId) ~= "string" then
        return nil
    end
    return productById[productId]
end

--[[
    What a product hands over, as a list of cosmetic ids.

    Returns an empty list for a product nobody has heard of rather than
    guessing, because the caller is a receipt handler and a receipt naming an
    unknown product must not be consumed. An unknown product that resolved to
    "nothing, successfully" would be a purchase the platform stops retrying and
    the player never receives.
]]
function CosmeticCatalog.grantsOf(productId: any): { string }
    local product = CosmeticCatalog.product(productId)
    if product == nil then
        return {}
    end
    return product.grants
end

return table.freeze(CosmeticCatalog)
