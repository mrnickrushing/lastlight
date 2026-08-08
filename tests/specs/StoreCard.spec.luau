--!strict

--[[
    No card can render without price, permanence and owned state.

    MONETIZATION_LIVEOPS_ANALYTICS: "Every product shows a real preview, exact
    Robux price, permanence, eligible objects, effect intensity, and owned
    state." Milestone 11's exit gate: "no product grants power or confuses
    price/permanence." A card missing one of those is not a smaller card, it is
    a claim about a purchase with a hole in it -- and a BUY button over an empty
    price is a player agreeing to something nobody told them.

    So the builder refuses rather than degrades, and this suite drives every
    refusal. It also walks the same chain `CosmeticReachability` walks, one
    link further along: product, price, card, button, and the panel that draws
    it. A card that exists and a card a player can reach are different facts.
]]

local fs = require("@lune/fs")
local CosmeticCatalog = require("../../src/shared/CosmeticCatalog")
local StoreCard = require("../../src/shared/StoreCard")
local TestRunner = require("../TestRunner")

local PRODUCT = {
    id = "product_probe",
    displayName = "PROBE",
    detail = "A thing for a spec to hold.",
    permanence = "permanent",
    grants = { "cosmetic_probe" },
}

local PREVIEW = {
    {
        name = "Body",
        target = "UpperTorso",
        shape = "Block",
        size = { 1, 1, 1 },
        offset = { 0, 0, 0 },
        rotation = { 0, 0, 0 },
        color = { 10, 20, 30 },
        material = "Fabric",
    },
}

local function context(overrides: { [string]: any }?): { [string]: any }
    local base: { [string]: any } = {
        priceInRobux = 399,
        owned = false,
        equipped = false,
        preview = PREVIEW,
    }
    for key, value in overrides or {} do
        base[key] = value
    end
    return base
end

return {
    name = "StoreCard",
    cases = {
        {
            name = "a complete card carries every fact the gate names",
            run = function()
                local card, reason = StoreCard.build(PRODUCT, context())
                TestRunner.equal(reason, "ok")
                TestRunner.truthy(card ~= nil, "a complete card was refused")
                local built = card :: any
                TestRunner.equal(built.productId, "product_probe")
                TestRunner.equal(built.priceLabel, "399 ROBUX")
                TestRunner.equal(built.priceInRobux, 399)
                TestRunner.equal(built.ownedLabel, "NOT OWNED")
                TestRunner.equal(built.owned, false)
                TestRunner.equal(built.action, "buy")
                TestRunner.equal(built.actionLabel, "BUY · 399 ROBUX")
                TestRunner.truthy(#built.permanenceLabel > 0, "permanence is not stated")
                TestRunner.truthy(#built.preview > 0, "a card with no preview was built")
                TestRunner.equal(built.assurance, StoreCard.assurance())
            end,
        },
        {
            --[[
                The four refusals, each on its own. Named apart because a
                missing price is the ordinary state of a product whose Creator
                Dashboard half does not exist yet, while a missing permanence
                or preview is a catalog fault -- and the store has to be able
                to say "not priced yet" without saying it about something
                genuinely broken.
            ]]
            name = "a card missing any required fact is refused, not degraded",
            run = function()
                --[[
                    Written out rather than built from the helper: a missing
                    field is an absent key, and an override table cannot carry
                    a nil to remove one. The first draft of this case passed
                    while proving nothing, which is the shape of failure this
                    whole suite is about.
                ]]
                local noPrice, priceReason =
                    StoreCard.build(PRODUCT, { owned = false, preview = PREVIEW })
                TestRunner.equal(noPrice, nil, "a card rendered with no price")
                TestRunner.equal(priceReason, "no_price")

                local noOwned, ownedReason =
                    StoreCard.build(PRODUCT, { priceInRobux = 399, preview = PREVIEW })
                TestRunner.equal(noOwned, nil, "a card rendered with no owned state")
                TestRunner.equal(ownedReason, "no_owned_state")

                local noPreview, previewReason = StoreCard.build(
                    PRODUCT,
                    context({
                        preview = {},
                    })
                )
                TestRunner.equal(noPreview, nil, "a card rendered with no preview")
                TestRunner.equal(previewReason, "no_preview")

                local forever = table.clone(PRODUCT)
                forever.permanence = "seasonal"
                local noTerms, termsReason = StoreCard.build(forever, context())
                TestRunner.equal(noTerms, nil, "a card rendered with unstated permanence")
                TestRunner.equal(termsReason, "no_permanence")

                -- and no context at all is the same answer as no owned state:
                -- a caller who asked nothing has not established anything
                TestRunner.equal(StoreCard.build(PRODUCT, nil), nil)
                TestRunner.equal(StoreCard.build(nil, context()), nil)
            end,
        },
        {
            --[[
                Owned is a boolean, not a truthy value.

                Nil here means nobody asked, and a card that reads NOT OWNED
                because nobody asked is a card that will sell a player
                something they already have -- which is the one thing the owned
                state exists to prevent.
            ]]
            name = "an owned product loses its buy button rather than greying it",
            run = function()
                local card = StoreCard.build(PRODUCT, context({ owned = true })) :: any
                TestRunner.truthy(card ~= nil)
                TestRunner.equal(card.ownedLabel, "OWNED")
                TestRunner.equal(card.action, "owned")
                TestRunner.equal(card.actionLabel, "OWNED")
                -- the price is still shown: a card that hides it once owned is
                -- a card that cannot answer "what did I pay for this"
                TestRunner.equal(card.priceLabel, "399 ROBUX")
                for _, notBoolean in { "yes", 1, {} } do
                    TestRunner.equal(
                        StoreCard.build(PRODUCT, context({ owned = notBoolean })),
                        nil,
                        "a non-boolean owned state built a card"
                    )
                end
                -- and the wardrobe row is the only place WEAR ever appears, so
                -- a card can never claim to put on one of two granted things
                TestRunner.equal(string.find(card.actionLabel, "WEAR", 1, true), nil)
            end,
        },
        {
            --[[
                A price is a whole number of Robux or it is not a price. A
                decimal, a negative, an infinity or a string would each be this
                file inventing a currency, and the failure mode is a card
                telling a player a number the platform will not charge them.
            ]]
            name = "only a real Robux figure becomes a price",
            run = function()
                TestRunner.equal(StoreCard.priceLabel(0), "0 ROBUX")
                TestRunner.equal(StoreCard.priceLabel(1200), "1200 ROBUX")
                for _, junk in { -1, 0.5, math.huge, "399", nil, {} } do
                    TestRunner.equal(
                        StoreCard.priceLabel(junk),
                        nil,
                        "a price was made out of " .. tostring(junk)
                    )
                end
                TestRunner.equal(StoreCard.priceLabel(0 / 0), nil)
            end,
        },
        {
            --[[
                The assurance is on the builder, not on the copy.

                A line a writer has to remember is a line missing from the
                twelfth product. This one is required by the monetization
                document and by CHARACTER_KITS_SPEC's storefront review, so it
                is added by construction and cannot be omitted per card.
            ]]
            name = "every card carries the same power assurance",
            run = function()
                local assurance = StoreCard.assurance()
                TestRunner.truthy(#assurance > 0)
                TestRunner.truthy(
                    string.find(assurance, "COSMETIC", 1, true) ~= nil,
                    "the assurance does not say the product is cosmetic"
                )
                TestRunner.truthy(
                    string.find(assurance, "EARNED", 1, true) ~= nil,
                    "the assurance does not say abilities are earned"
                )
                for _, product in CosmeticCatalog.products() do
                    local card = StoreCard.build(product, context()) :: any
                    TestRunner.truthy(card ~= nil, product.id .. " builds no card at a real price")
                    TestRunner.equal(card.assurance, assurance)
                end
            end,
        },
        {
            --[[
                The wardrobe is a separate list and needs no price.

                A product can stop resolving -- delisted in the dashboard, or a
                product info call that simply fails -- and a store that showed
                owned cosmetics only through their sale cards would make a
                paid-for coat unwearable the moment the thing that sold it went
                away. That is an entitlement that exists and a cosmetic that
                cannot be worn, which is this project's most expensive shape.
            ]]
            name = "an owned cosmetic can be worn with no product behind it",
            run = function()
                for _, cosmetic in CosmeticCatalog.list() do
                    local off = StoreCard.wardrobeRow(cosmetic, false) :: any
                    TestRunner.truthy(off ~= nil, cosmetic.id .. " has no wardrobe row")
                    TestRunner.equal(off.cosmeticId, cosmetic.id)
                    TestRunner.equal(off.equipped, false)
                    TestRunner.equal(off.actionLabel, "WEAR")
                    TestRunner.truthy(#off.preview > 0, cosmetic.id .. " draws nothing")
                    local on = StoreCard.wardrobeRow(cosmetic, true) :: any
                    TestRunner.equal(on.actionLabel, "TAKE OFF")
                end
                -- and a row still has to say whether it is worn: an unknown
                -- worn state is a button whose label is a guess
                TestRunner.equal(StoreCard.wardrobeRow(CosmeticCatalog.list()[1], nil), nil)
                TestRunner.equal(StoreCard.wardrobeRow({ id = "x" }, false), nil)
            end,
        },
        {
            --[[
                And the reachability half, which is the case this project keeps
                paying to have written. The equip panel shipped as a hardcoded
                list of eight items and left ninety craftable items unwearable
                with every spec green (#299). A storefront with hand-written
                cards has that shape and a price attached to it, so the panel
                is required to be built by walking the catalog.
            ]]
            name = "the panel draws every product and every cosmetic by walking the catalog",
            run = function()
                local hud = fs.readFile("src/client/Controllers/HUDController.luau")
                TestRunner.truthy(
                    string.find(hud, "for order, product in CosmeticCatalog.products()", 1, true)
                        ~= nil,
                    "the store's cards are not built from the product catalog"
                )
                TestRunner.truthy(
                    string.find(hud, "for order, cosmetic in CosmeticCatalog.list()", 1, true)
                        ~= nil,
                    "the wardrobe's rows are not built from the cosmetic catalog"
                )
                --[[
                    And the preview is a generic builder over the plan rather
                    than a case per cosmetic, which is what makes "the twelfth
                    cosmetic has no picture" impossible instead of merely
                    untested.
                ]]
                TestRunner.truthy(
                    string.find(hud, "createCosmeticPreview", 1, true) ~= nil,
                    "nothing draws a cosmetic's geometry"
                )

                local client = fs.readFile("src/client/init.client.luau")
                for _, wire in { "StoreDetail", "StorePurchase", "EquipCosmetic" } do
                    TestRunner.truthy(
                        string.find(client, "Actions." .. wire, 1, true) ~= nil,
                        "nothing on the client sends " .. wire
                    )
                end
                TestRunner.truthy(
                    string.find(client, "hud:setStoreHandlers", 1, true) ~= nil,
                    "the store's presses are wired to nothing"
                )
            end,
        },
    },
}
