--!strict

--[[
    What a store card is allowed to say, and what it may not be drawn without.

    The monetization document is specific about this and the roadmap's exit
    gate repeats it: every product shows a real preview, the exact Robux price,
    permanence, and owned state, and no product may confuse price or
    permanence. A card is therefore not a layout -- it is a claim about a
    purchase, and a claim missing one of its four facts is worse than no claim
    at all.

    So the refusal is structural. `build` returns **nil** when it cannot make an
    honest card, and the reason why, rather than returning a card with a blank
    where the price goes. A player who sees a BUY button over an empty price is
    a player who does not know what they are agreeing to, and a store that
    shows nothing is merely a store that is not open yet.

    **The price never comes from here.** It is passed in, because it has to be
    read from platform product information at the moment it is asked for --
    a number written into the source is a number that is wrong the first time
    the owner edits it in the Creator Dashboard, and a card showing the wrong
    price is the worst failure in this file.

    **Nothing here names a cosmetic.** A card is built from whatever product and
    plan it is handed. That is what lets `CosmeticNeutrality.spec` say no module
    outside the catalog can name a cosmetic id: the store renders the catalog
    rather than knowing it.
]]

local Strings = require("./Strings")

local StoreCard = {}

export type Context = {
    -- Nil is a real answer and means "the platform has not told us". The
    -- dashboard product may not exist yet, or the web call may have failed.
    priceInRobux: number?,
    owned: boolean?,
    equipped: boolean?,
    -- The geometry the card draws. A preview is one of the four required
    -- facts, so a product whose grants resolve to nothing drawable has no
    -- honest card either. Only its *presence* travels: see `previewParts`.
    preview: { any }?,
}

export type Card = {
    productId: string,
    displayName: string,
    detail: string,
    priceLabel: string,
    priceInRobux: number,
    permanenceLabel: string,
    ownedLabel: string,
    owned: boolean,
    equipped: boolean,
    --[[
        What the one button on the card does: `buy`, or nothing at all.

        An owned product loses the buy button entirely rather than greying it
        out, which is what the owned state is for -- a product with a price on
        it that the player already has is the "sells a player the same thing
        twice" case. And the button never becomes WEAR: a product may grant
        more than one cosmetic, and a single button cannot honestly say which
        of them it would put on. Wearing lives on the wardrobe row, which is
        one row per cosmetic and therefore never ambiguous.
    ]]
    action: string,
    actionLabel: string,
    assurance: string,
    --[[
        How many parts the preview turned out to have, rather than the parts.

        The card is built on a server and read by a client that already holds
        the catalog, so shipping the geometry would put the same plan on the
        wire on every snapshot push to say something the client can look up.
        What has to travel is that the check passed: a card exists only if
        there was real geometry behind it, and this is the number that says so.
    ]]
    previewParts: number,
}

export type WardrobeRow = {
    cosmeticId: string,
    displayName: string,
    slot: string,
    equipped: boolean,
    actionLabel: string,
    previewParts: number,
}

--[[
    On every card, always, and built in rather than authored per product.

    MONETIZATION_LIVEOPS_ANALYTICS forbids paid power, and
    CHARACTER_KITS_SPEC's storefront review asks for the sentence in as many
    words. A line a copywriter has to remember to add is a line that will be
    missing from the twelfth product; a line the builder adds cannot be.
]]
local ASSURANCE = Strings.get("hud.cosmetic_only_abilities_are_earned_in")

local PERMANENCE_LABELS: { [string]: string } = table.freeze({
    permanent = Strings.get("store.permanent_yours_for_good"),
})

function StoreCard.assurance(): string
    return ASSURANCE
end

--[[
    The Robux figure as a player reads it.

    Whole numbers only: the platform prices in whole Robux, and a decimal point
    here would be this file inventing a currency.
]]
function StoreCard.priceLabel(priceInRobux: any): string?
    if type(priceInRobux) ~= "number" then
        return nil
    end
    if priceInRobux ~= priceInRobux or priceInRobux < 0 or priceInRobux == math.huge then
        return nil
    end
    if priceInRobux ~= math.floor(priceInRobux) then
        return nil
    end
    return string.format(Strings.get("store.n_robux"), priceInRobux)
end

function StoreCard.permanenceLabel(permanence: any): string?
    if type(permanence) ~= "string" then
        return nil
    end
    return PERMANENCE_LABELS[permanence]
end

--[[
    One card, or nothing and the reason.

    The four refusals below are the four facts the exit gate names, and the
    order is deliberate: a missing permanence or a missing preview is a
    catalog bug that should fail a spec, while a missing price is the ordinary
    state of a product whose dashboard half does not exist yet. Naming them
    apart is what lets the store say "not priced yet" without saying it about
    a genuinely broken entry.
]]
function StoreCard.build(product: any, context: any): (Card?, string)
    if type(product) ~= "table" or type(product.id) ~= "string" or #product.id == 0 then
        return nil, "no_product"
    end
    if type(product.displayName) ~= "string" or #product.displayName == 0 then
        return nil, "no_name"
    end
    local permanenceLabel = StoreCard.permanenceLabel(product.permanence)
    if permanenceLabel == nil then
        return nil, "no_permanence"
    end
    if type(context) ~= "table" then
        return nil, "no_owned_state"
    end
    -- Owned has to be a boolean, not merely truthy. Nil here means nobody
    -- asked, and a card that renders NOT OWNED because nobody asked is a card
    -- that will sell a player something they already have.
    if type(context.owned) ~= "boolean" then
        return nil, "no_owned_state"
    end
    local preview = context.preview
    if type(preview) ~= "table" or #preview == 0 then
        return nil, "no_preview"
    end
    local priceLabel = StoreCard.priceLabel(context.priceInRobux)
    if priceLabel == nil then
        return nil, "no_price"
    end

    local owned = context.owned
    local equipped = context.equipped == true
    return {
        productId = product.id,
        displayName = product.displayName,
        detail = if type(product.detail) == "string" then product.detail else "",
        priceLabel = priceLabel,
        priceInRobux = context.priceInRobux,
        permanenceLabel = permanenceLabel,
        ownedLabel = if owned then Strings.get("store.owned") else Strings.get("store.not_owned"),
        owned = owned,
        equipped = equipped,
        action = if owned then "owned" else "buy",
        actionLabel = if owned
            then Strings.get("store.owned")
            else string.format(Strings.get("store.buy_n"), priceLabel),
        assurance = ASSURANCE,
        previewParts = #preview,
    },
        "ok"
end

--[[
    A row for something already owned, which needs no price at all.

    The wardrobe is a separate list from the shelf on purpose. A product can
    stop resolving -- delisted in the dashboard, or its web call failing -- and
    a store that showed owned cosmetics only through their sale cards would
    make a paid-for coat unwearable the moment the thing that sold it went
    away. That is the shape this project has now paid for four times: an
    entitlement that exists and a cosmetic that can be worn are different
    facts.
]]
function StoreCard.wardrobeRow(cosmetic: any, equipped: any): (WardrobeRow?, string)
    if type(cosmetic) ~= "table" or type(cosmetic.id) ~= "string" or #cosmetic.id == 0 then
        return nil, "no_cosmetic"
    end
    if type(cosmetic.displayName) ~= "string" or #cosmetic.displayName == 0 then
        return nil, "no_name"
    end
    if type(cosmetic.slot) ~= "string" or #cosmetic.slot == 0 then
        return nil, "no_slot"
    end
    if type(cosmetic.parts) ~= "table" or #cosmetic.parts == 0 then
        return nil, "no_preview"
    end
    if type(equipped) ~= "boolean" then
        return nil, "no_worn_state"
    end
    return {
        cosmeticId = cosmetic.id,
        displayName = cosmetic.displayName,
        slot = cosmetic.slot,
        equipped = equipped,
        actionLabel = if equipped then Strings.get("store.take_off") else Strings.get("hud.wear"),
        previewParts = #cosmetic.parts,
    },
        "ok"
end

return table.freeze(StoreCard)
