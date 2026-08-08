--!strict

--[[
    An entitlement that exists and a cosmetic that can actually be worn are
    different facts.

    This project has now paid for that sentence four times. 120 recipes had no
    bench. 24 residents had no body. Eight resident props would have rendered
    as somebody else's. Ninety craftable items could not be equipped, because
    the equip panel was a hardcoded list of eight. Every one of them passed
    every spec for a milestone.

    A store has exactly that shape and more expensive consequences: a player
    pays, the receipt clears, and the thing they bought has nowhere to be. So
    the chain is walked here end to end -- product, grant, cosmetic, plan,
    geometry -- and every link has to hold.

    The reason a per-cosmetic renderer case is not one of the links is that
    there is no per-cosmetic case to have: a plan is a list of parts with a
    target, a shape, a size, a colour and a material, drawn by a generic
    builder the way `GearVisualPlan` already is. The whole class of "the
    catalog knows about it and the drawing code does not" is designed out
    rather than tested for.
]]

local Config = require("../../src/shared/Config")
local CosmeticCatalog = require("../../src/shared/CosmeticCatalog")
local Entitlements = require("../../src/shared/Entitlements")
local Equipment = require("../../src/shared/Equipment")
local TestRunner = require("../TestRunner")

local SHAPES: { [string]: boolean } = {
    Block = true,
    Ball = true,
    Cylinder = true,
    Wedge = true,
}

return {
    name = "CosmeticReachability",
    cases = {
        {
            name = "every cosmetic resolves to geometry a builder can draw",
            run = function()
                local cosmetics = CosmeticCatalog.list()
                TestRunner.truthy(#cosmetics > 0, "the catalog is empty")
                for _, cosmetic in cosmetics do
                    TestRunner.equal(
                        CosmeticCatalog.get(cosmetic.id),
                        cosmetic,
                        cosmetic.id .. " does not resolve by its own id"
                    )
                    TestRunner.truthy(
                        CosmeticCatalog.isSlot(cosmetic.slot),
                        cosmetic.id .. " names an unknown slot"
                    )
                    TestRunner.truthy(#cosmetic.displayName > 0, cosmetic.id .. " has no name")
                    TestRunner.truthy(#cosmetic.detail > 0, cosmetic.id .. " has no description")
                    TestRunner.truthy(#cosmetic.parts > 0, cosmetic.id .. " has no parts")
                    for index, part in cosmetic.parts do
                        local label = string.format("%s part %d", cosmetic.id, index)
                        TestRunner.truthy(#part.name > 0, label .. " has no name")
                        TestRunner.truthy(#part.target > 0, label .. " has no target")
                        TestRunner.truthy(SHAPES[part.shape] == true, label .. " has no shape")
                        TestRunner.equal(#part.size, 3, label .. " has no size")
                        TestRunner.equal(#part.offset, 3, label .. " has no offset")
                        TestRunner.equal(#part.rotation, 3, label .. " has no rotation")
                        TestRunner.equal(#part.color, 3, label .. " has no colour")
                        TestRunner.truthy(#part.material > 0, label .. " has no material")
                        for _, dimension in part.size do
                            TestRunner.truthy(dimension > 0, label .. " has a zero dimension")
                        end
                    end
                end
            end,
        },
        {
            --[[
                The census, in the shape `ContentCensus` uses for everything
                else: a count that can only move deliberately.

                A catalog is the one kind of content where a quiet addition is
                also a quiet *sale*, so the numbers are pinned here and pinned
                again in CONTENT_CATALOG.md, and the case below reads the
                document to make sure the two still agree. Two targets is no
                target.
            ]]
            name = "the cosmetic catalog is four complete lines and twenty-four products",
            run = function()
                TestRunner.equal(#CosmeticCatalog.lines(), 4)
                TestRunner.equal(#CosmeticCatalog.slots(), 5)
                TestRunner.equal(#CosmeticCatalog.list(), 20)
                TestRunner.equal(#CosmeticCatalog.products(), 24)

                --[[
                    And every line is complete, which is the reachability half.
                    A line missing a slot is a set product with a hole in it,
                    and the hole is invisible until somebody wears the set and
                    finds their lantern still bare.
                ]]
                for _, line in CosmeticCatalog.lines() do
                    TestRunner.truthy(#line.displayName > 0, line.id .. " has no name")
                    TestRunner.truthy(#line.detail > 0, line.id .. " has no description")
                    local filled: { [string]: number } = {}
                    for _, slot in CosmeticCatalog.slots() do
                        filled[slot] = 0
                    end
                    for _, cosmetic in CosmeticCatalog.list() do
                        if cosmetic.line == line.id then
                            filled[cosmetic.slot] += 1
                        end
                    end
                    for slot, count in filled do
                        TestRunner.equal(
                            count,
                            1,
                            string.format(
                                "%s holds %d cosmetics in the %s slot",
                                line.id,
                                count,
                                slot
                            )
                        )
                    end
                end

                -- and every cosmetic belongs to a line that exists, so the
                -- grouping cannot drift into a fifth line nobody declared
                for _, cosmetic in CosmeticCatalog.list() do
                    TestRunner.truthy(
                        CosmeticCatalog.isLine(cosmetic.line),
                        cosmetic.id .. " names a line that does not exist"
                    )
                end
                for _, product in CosmeticCatalog.products() do
                    TestRunner.truthy(
                        CosmeticCatalog.isLine(product.line),
                        product.id .. " names a line that does not exist"
                    )
                end
            end,
        },
        {
            --[[
                A set grants its whole line and nothing else.

                This is the case wave E's grant path was built for and had
                nothing to exercise: one purchase id handing over five
                cosmetics. A set that granted four would be a purchase whose
                missing fifth is invisible until the buyer looks in a mirror.
            ]]
            name = "every line has one set, and each set grants exactly that line",
            run = function()
                local sets: { [string]: any } = {}
                for _, product in CosmeticCatalog.products() do
                    if #product.grants > 1 then
                        TestRunner.equal(
                            sets[product.line],
                            nil,
                            product.line .. " has more than one set"
                        )
                        sets[product.line] = product
                    end
                end
                for _, line in CosmeticCatalog.lines() do
                    local set = sets[line.id]
                    TestRunner.truthy(set ~= nil, line.id .. " has no set product")
                    TestRunner.equal(#set.grants, 5, set.id .. " does not grant five things")
                    local slots: { [string]: boolean } = {}
                    for _, cosmeticId in set.grants do
                        local cosmetic = CosmeticCatalog.get(cosmeticId)
                        TestRunner.truthy(cosmetic ~= nil, set.id .. " grants " .. cosmeticId)
                        TestRunner.equal(
                            (cosmetic :: any).line,
                            line.id,
                            set.id .. " grants something from another line"
                        )
                        TestRunner.equal(
                            slots[(cosmetic :: any).slot],
                            nil,
                            set.id .. " grants two things for one slot"
                        )
                        slots[(cosmetic :: any).slot] = true
                    end
                end
            end,
        },
        {
            --[[
                The numbers in this spec are the numbers in the content
                catalog, read the same way `ContentCensus` reads its own.
            ]]
            name = "the counts in this spec are the counts in the content catalog",
            run = function()
                local fs = require("@lune/fs")
                local doc = fs.readFile("docs/CONTENT_CATALOG.md")
                for _, claim in
                    {
                        "20 cosmetics across four lines",
                        "| line_greenward | The Greenward | 5 |",
                        "| line_ironroot | The Ironroot | 5 |",
                        "| line_mireglass | The Mireglass | 5 |",
                        "| line_cinderfall | The Cinderfall | 5 |",
                    }
                do
                    TestRunner.truthy(
                        string.find(doc, claim, 1, true) ~= nil,
                        "the content catalog no longer says: " .. claim
                    )
                end
            end,
        },
        {
            -- Every slot has something in it. An empty slot is a row in the
            -- store's own panel that can never show a card, which is the equip
            -- panel's failure inverted.
            name = "every slot holds at least one cosmetic",
            run = function()
                local perSlot: { [string]: number } = {}
                for _, slot in CosmeticCatalog.slots() do
                    perSlot[slot] = 0
                end
                for _, cosmetic in CosmeticCatalog.list() do
                    perSlot[cosmetic.slot] += 1
                end
                for slot, count in perSlot do
                    TestRunner.truthy(count > 0, "no cosmetic occupies the " .. slot .. " slot")
                end
            end,
        },
        {
            --[[
                Both directions of the product/cosmetic chain. A product that
                grants nothing is a purchase with no delivery; a cosmetic no
                product grants is a thing in a catalog nobody can ever obtain,
                which is the same as it not existing but harder to notice.
            ]]
            name = "every product grants a real cosmetic, and every cosmetic is granted",
            run = function()
                local granted: { [string]: boolean } = {}
                for _, product in CosmeticCatalog.products() do
                    TestRunner.truthy(#product.grants > 0, product.id .. " grants nothing")
                    for _, cosmeticId in product.grants do
                        TestRunner.truthy(
                            CosmeticCatalog.get(cosmeticId) ~= nil,
                            product.id .. " grants a cosmetic that does not exist: " .. cosmeticId
                        )
                        granted[cosmeticId] = true
                    end
                end
                for _, cosmetic in CosmeticCatalog.list() do
                    TestRunner.truthy(
                        granted[cosmetic.id] == true,
                        cosmetic.id .. " can never be obtained: no product grants it"
                    )
                end
            end,
        },
        {
            --[[
                A grant resolved through the same door a receipt uses. Walking
                the catalog proves the table is consistent; walking it through
                `Entitlements.apply` proves the thing that will actually run on
                a real receipt reaches the same answer.
            ]]
            name = "a receipt for every product delivers what the card promised",
            run = function()
                local state = Entitlements.default()
                for index, product in CosmeticCatalog.products() do
                    local next, result = Entitlements.apply(state, {
                        purchaseId = string.format("purchase_%d", index),
                        productId = product.id,
                        at = 1000 + index,
                    }, CosmeticCatalog.grantsOf)
                    TestRunner.equal(result.applied, true, product.id .. " granted nothing")
                    TestRunner.equal(#result.granted, #product.grants)
                    for _, cosmeticId in product.grants do
                        TestRunner.truthy(
                            Entitlements.owns(next, cosmeticId),
                            product.id .. " did not deliver " .. cosmeticId
                        )
                    end
                    state = next
                end
                -- and everything in the catalog is owned by the end of it
                for _, cosmetic in CosmeticCatalog.list() do
                    TestRunner.truthy(
                        Entitlements.owns(state, cosmetic.id),
                        cosmetic.id .. " was never delivered by any receipt"
                    )
                end
            end,
        },
        {
            --[[
                The dashboard table. It is empty today and that is correct --
                a developer product does not exist until somebody creates it --
                so what is checked is not that it is full but that it cannot be
                wrong: a number pasted against a product the catalog does not
                know fails on the day it is pasted, rather than on the day a
                player presses buy.
            ]]
            name = "every configured product id names a product that exists",
            run = function()
                for productId, robloxId in Config.CommerceProductIds do
                    TestRunner.truthy(
                        CosmeticCatalog.product(productId) ~= nil,
                        "a dashboard id is configured for an unknown product: "
                            .. tostring(productId)
                    )
                    TestRunner.truthy(
                        type(robloxId) == "number" and robloxId > 0,
                        productId .. " has a dashboard id that is not a number"
                    )
                end
                -- the store stays shut while there is nothing behind it
                local configured = 0
                for _ in Config.CommerceProductIds do
                    configured += 1
                end
                if configured == 0 then
                    TestRunner.equal(
                        Config.FeatureFlags.cosmetic_store_enabled,
                        false,
                        "the store is open with no products configured"
                    )
                end
            end,
        },
        {
            --[[
                Cosmetic slots and equipment slots must not overlap.

                If they did, a cosmetic would occupy a slot that carries stats,
                and the neutrality argument would collapse without anything
                failing -- the numbers would be Equipment's, not the catalog's,
                so the whitelist walk would not see them.
            ]]
            name = "no cosmetic slot is an equipment slot",
            run = function()
                local equipmentSlots: { [string]: boolean } = {}
                for _, item in Equipment.list() do
                    if type(item.slot) == "string" then
                        equipmentSlots[item.slot] = true
                    end
                end
                for _, slot in CosmeticCatalog.slots() do
                    TestRunner.equal(
                        equipmentSlots[slot],
                        nil,
                        "the cosmetic slot " .. slot .. " is also an equipment slot"
                    )
                end
            end,
        },
    },
}
