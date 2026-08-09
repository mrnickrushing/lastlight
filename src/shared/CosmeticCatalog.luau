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

local Strings = require("./Strings")

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
        displayName = Strings.get("store.the_greenward"),
        detail = Strings.get("store.bramblewake_amber_oiled_canvas_and_the"),
    }),
    table.freeze({
        id = "line_ironroot",
        displayName = Strings.get("store.the_ironroot"),
        detail = Strings.get("store.pit_leather_riveted_iron_and_a"),
    }),
    table.freeze({
        id = "line_mireglass",
        displayName = Strings.get("store.the_mireglass"),
        detail = Strings.get("store.bog_oak_reed_binding_and_glass"),
    }),
    table.freeze({
        id = "line_cinderfall",
        displayName = Strings.get("store.the_cinderfall"),
        detail = Strings.get("store.scorched_plate_bronze_at_the_joins"),
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
        displayName = Strings.get("store.lantern_keeper_s_coat"),
        detail = Strings.get("store.the_long_coat_the_first_keepers"),
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
        displayName = Strings.get("store.amberglass_edge"),
        detail = Strings.get("store.a_blade_finish_poured_from_cooled"),
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
        displayName = Strings.get("store.rootbound_grip"),
        detail = Strings.get("store.a_tool_haft_wrapped_in_living"),
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
        displayName = Strings.get("store.foxfire_shell"),
        detail = Strings.get("store.a_lantern_housing_of_pale_green"),
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
        displayName = Strings.get("store.greenward_banner"),
        detail = Strings.get("store.the_greenward_s_mark_for_a"),
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
        displayName = Strings.get("store.dredger_s_rig"),
        detail = Strings.get("store.the_apron_and_strapping_of_somebody"),
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
        displayName = Strings.get("store.slagcut_edge"),
        detail = Strings.get("store.a_blade_whose_back_was_never"),
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
        displayName = Strings.get("store.pitgrip"),
        detail = Strings.get("store.an_iron_ferruled_haft_with_a"),
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
        displayName = Strings.get("store.deepwatch_shell"),
        detail = Strings.get("store.a_caged_safety_lamp_the_bars"),
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
        displayName = Strings.get("store.pickmark_banner"),
        detail = Strings.get("store.two_crossed_picks_over_grey_the"),
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
        displayName = Strings.get("store.wader_s_cloak"),
        detail = Strings.get("store.a_hooded_cloak_cut_long_at"),
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
        displayName = Strings.get("store.shardline"),
        detail = Strings.get("store.a_blade_of_set_glass_each"),
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
        displayName = Strings.get("store.reedbind"),
        detail = Strings.get("store.a_haft_bound_in_split_reed"),
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
        displayName = Strings.get("store.bogfire_shell"),
        detail = Strings.get("store.a_round_bowl_under_a_wide"),
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
        displayName = Strings.get("store.stillwater_banner"),
        detail = Strings.get("store.a_long_pennant_weighted_at_the"),
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
        displayName = Strings.get("store.ashwarden_plate"),
        detail = Strings.get("store.plate_that_went_through_the_fall"),
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
        displayName = Strings.get("store.emberbrand"),
        detail = Strings.get("store.a_fuller_that_never_cooled_the"),
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
        displayName = Strings.get("store.forgegrip"),
        detail = Strings.get("store.a_bronze_collared_haft_wrapped_against"),
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
        displayName = Strings.get("store.ashfall_shell"),
        detail = Strings.get("store.a_vented_iron_housing_ash_falls"),
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
        displayName = Strings.get("store.lastfire_banner"),
        detail = Strings.get("store.burnt_through_in_two_places_and"),
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
        displayName = Strings.get("store.lantern_keeper_s_coat"),
        detail = Strings.get("store.an_outfit_for_the_traveller_who"),
        permanence = "permanent",
        grants = { "cosmetic_lantern_keeper_coat" },
    },
    {
        id = "product_amberglass_edge",
        line = "line_greenward",
        displayName = Strings.get("store.amberglass_edge"),
        detail = Strings.get("store.a_weapon_finish_changes_how_a"),
        permanence = "permanent",
        grants = { "cosmetic_amberglass_edge" },
    },
    {
        id = "product_rootbound_grip",
        line = "line_greenward",
        displayName = Strings.get("store.rootbound_grip"),
        detail = Strings.get("store.a_tool_finish_for_every_tool"),
        permanence = "permanent",
        grants = { "cosmetic_rootbound_grip" },
    },
    {
        id = "product_foxfire_shell",
        line = "line_greenward",
        displayName = Strings.get("store.foxfire_shell"),
        detail = Strings.get("store.a_lantern_housing_the_light_is"),
        permanence = "permanent",
        grants = { "cosmetic_foxfire_shell" },
    },
    {
        id = "product_greenward_banner",
        line = "line_greenward",
        displayName = Strings.get("store.greenward_banner"),
        detail = Strings.get("store.a_banner_for_a_plot_you"),
        permanence = "permanent",
        grants = { "cosmetic_greenward_banner" },
    },
    {
        id = "product_ironroot_dredger_rig",
        line = "line_ironroot",
        displayName = Strings.get("store.dredger_s_rig"),
        detail = Strings.get("store.an_outfit_for_somebody_who_works"),
        permanence = "permanent",
        grants = { "cosmetic_ironroot_dredger_rig" },
    },
    {
        id = "product_ironroot_slagcut_edge",
        line = "line_ironroot",
        displayName = Strings.get("store.slagcut_edge"),
        detail = Strings.get("store.a_weapon_finish_with_a_back"),
        permanence = "permanent",
        grants = { "cosmetic_ironroot_slagcut_edge" },
    },
    {
        id = "product_ironroot_pitgrip",
        line = "line_ironroot",
        displayName = Strings.get("store.pitgrip"),
        detail = Strings.get("store.a_tool_finish_iron_ferruled_with"),
        permanence = "permanent",
        grants = { "cosmetic_ironroot_pitgrip" },
    },
    {
        id = "product_ironroot_deepwatch_shell",
        line = "line_ironroot",
        displayName = Strings.get("store.deepwatch_shell"),
        detail = Strings.get("store.a_caged_lantern_housing_the_light"),
        permanence = "permanent",
        grants = { "cosmetic_ironroot_deepwatch_shell" },
    },
    {
        id = "product_ironroot_pickmark_banner",
        line = "line_ironroot",
        displayName = Strings.get("store.pickmark_banner"),
        detail = Strings.get("store.a_banner_for_a_plot_you"),
        permanence = "permanent",
        grants = { "cosmetic_ironroot_pickmark_banner" },
    },
    {
        id = "product_mireglass_wader_cloak",
        line = "line_mireglass",
        displayName = Strings.get("store.wader_s_cloak"),
        detail = Strings.get("store.an_outfit_cut_long_at_the"),
        permanence = "permanent",
        grants = { "cosmetic_mireglass_wader_cloak" },
    },
    {
        id = "product_mireglass_shardline",
        line = "line_mireglass",
        displayName = Strings.get("store.shardline"),
        detail = Strings.get("store.a_weapon_finish_of_set_glass"),
        permanence = "permanent",
        grants = { "cosmetic_mireglass_shardline" },
    },
    {
        id = "product_mireglass_reedbind",
        line = "line_mireglass",
        displayName = Strings.get("store.reedbind"),
        detail = Strings.get("store.a_tool_finish_bound_in_split"),
        permanence = "permanent",
        grants = { "cosmetic_mireglass_reedbind" },
    },
    {
        id = "product_mireglass_bogfire_shell",
        line = "line_mireglass",
        displayName = Strings.get("store.bogfire_shell"),
        detail = Strings.get("store.a_lantern_housing_under_a_wide"),
        permanence = "permanent",
        grants = { "cosmetic_mireglass_bogfire_shell" },
    },
    {
        id = "product_mireglass_stillwater_banner",
        line = "line_mireglass",
        displayName = Strings.get("store.stillwater_banner"),
        detail = Strings.get("store.a_banner_weighted_at_the_tail"),
        permanence = "permanent",
        grants = { "cosmetic_mireglass_stillwater_banner" },
    },
    {
        id = "product_cinderfall_ashwarden_plate",
        line = "line_cinderfall",
        displayName = Strings.get("store.ashwarden_plate"),
        detail = Strings.get("store.an_outfit_that_went_through_the"),
        permanence = "permanent",
        grants = { "cosmetic_cinderfall_ashwarden_plate" },
    },
    {
        id = "product_cinderfall_emberbrand",
        line = "line_cinderfall",
        displayName = Strings.get("store.emberbrand"),
        detail = Strings.get("store.a_weapon_finish_with_a_fuller"),
        permanence = "permanent",
        grants = { "cosmetic_cinderfall_emberbrand" },
    },
    {
        id = "product_cinderfall_forgegrip",
        line = "line_cinderfall",
        displayName = Strings.get("store.forgegrip"),
        detail = Strings.get("store.a_tool_finish_wrapped_against_heat"),
        permanence = "permanent",
        grants = { "cosmetic_cinderfall_forgegrip" },
    },
    {
        id = "product_cinderfall_ashfall_shell",
        line = "line_cinderfall",
        displayName = Strings.get("store.ashfall_shell"),
        detail = Strings.get("store.a_vented_lantern_housing_the_light"),
        permanence = "permanent",
        grants = { "cosmetic_cinderfall_ashfall_shell" },
    },
    {
        id = "product_cinderfall_lastfire_banner",
        line = "line_cinderfall",
        displayName = Strings.get("store.lastfire_banner"),
        detail = Strings.get("store.a_banner_burnt_through_in_two"),
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
        displayName = Strings.get("store.the_greenward_set"),
        detail = Strings.get("store.every_piece_of_the_greenward_look"),
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
        displayName = Strings.get("store.the_ironroot_set"),
        detail = Strings.get("store.every_piece_of_the_ironroot_look"),
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
        displayName = Strings.get("store.the_mireglass_set"),
        detail = Strings.get("store.every_piece_of_the_mireglass_look"),
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
        displayName = Strings.get("store.the_cinderfall_set"),
        detail = Strings.get("store.every_piece_of_the_cinderfall_look"),
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
