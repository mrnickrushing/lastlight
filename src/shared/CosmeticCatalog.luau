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
    displayName: string,
    detail: string,
    derived: boolean,
    parts: { PartPlan },
}

export type Product = {
    id: string,
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
        displayName = "LANTERN KEEPER'S COAT",
        detail = "An outfit for the traveller who keeps the light.",
        permanence = "permanent",
        grants = { "cosmetic_lantern_keeper_coat" },
    },
    {
        id = "product_amberglass_edge",
        displayName = "AMBERGLASS EDGE",
        detail = "A weapon finish. Changes how a blade looks and nothing else.",
        permanence = "permanent",
        grants = { "cosmetic_amberglass_edge" },
    },
    {
        id = "product_rootbound_grip",
        displayName = "ROOTBOUND GRIP",
        detail = "A tool finish, for every tool you carry.",
        permanence = "permanent",
        grants = { "cosmetic_rootbound_grip" },
    },
    {
        id = "product_foxfire_shell",
        displayName = "FOXFIRE SHELL",
        detail = "A lantern housing. The light is the same light.",
        permanence = "permanent",
        grants = { "cosmetic_foxfire_shell" },
    },
    {
        id = "product_greenward_banner",
        displayName = "GREENWARD BANNER",
        detail = "A banner for a plot you have already built on.",
        permanence = "permanent",
        grants = { "cosmetic_greenward_banner" },
    },
}

local slotSet: { [string]: boolean } = {}
for _, slot in SLOTS do
    slotSet[slot] = true
end

local cosmeticById: { [string]: Cosmetic } = {}
for _, cosmetic in COSMETICS do
    assert(cosmeticById[cosmetic.id] == nil, "duplicate cosmetic: " .. cosmetic.id)
    assert(slotSet[cosmetic.slot], cosmetic.id .. " names no slot: " .. cosmetic.slot)
    assert(#cosmetic.parts > 0, cosmetic.id .. " has no geometry")
    -- table.freeze is shallow, so the parts array has to be frozen too or the
    -- catalog is a frozen table pointing at a mutable list.
    table.freeze(cosmetic.parts)
    cosmeticById[cosmetic.id] = table.freeze(cosmetic)
end

local productById: { [string]: Product } = {}
for _, product in PRODUCTS do
    assert(productById[product.id] == nil, "duplicate product: " .. product.id)
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
