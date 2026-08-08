--!strict

--[[
    The rules that decide whether a player who paid gets what they paid for.

    None of this can be exercised in Studio -- `ProcessReceipt` needs a real
    purchase on a real account -- so all of it is pure, and this is where the
    cases that matter get walked. Every one of them is a way a grant is lost or
    doubled in a game that did not think about it:

      * the platform retries and the player gets two;
      * the platform retries forever because nothing ever said yes;
      * a build ships that has never heard of a product, tells the platform the
        purchase is settled, and the player is left holding a receipt for
        nothing;
      * the receipt lands while the profile is locked by another server, and
        writing anyway costs the player their save.
]]

local CosmeticCatalog = require("../../src/shared/CosmeticCatalog")
local Entitlements = require("../../src/shared/Entitlements")
local TestRunner = require("../TestRunner")

local COAT = "cosmetic_lantern_keeper_coat"
local COAT_PRODUCT = "product_lantern_keeper_coat"

local function receipt(purchaseId: string, productId: string, at: number): any
    return { purchaseId = purchaseId, productId = productId, at = at }
end

return {
    name = "Entitlements",
    cases = {
        {
            name = "a fresh receipt grants once and says so",
            run = function()
                local state, result = Entitlements.apply(
                    Entitlements.default(),
                    receipt("p1", COAT_PRODUCT, 100),
                    CosmeticCatalog.grantsOf
                )
                TestRunner.equal(result.applied, true)
                TestRunner.equal(result.acknowledge, true)
                TestRunner.equal(result.reason, "granted")
                TestRunner.equal(Entitlements.owns(state, COAT), true)
            end,
        },
        {
            --[[
                The retry. Roblox calls ProcessReceipt again until it is told
                the grant is durable, so a purchase id already in the ledger has
                to answer "yes, we have it" without granting a second time.
                Granting again hands out two of something bought once; refusing
                to acknowledge retries forever.
            ]]
            name = "a retried receipt is acknowledged and never granted twice",
            run = function()
                local once = Entitlements.apply(
                    Entitlements.default(),
                    receipt("p1", COAT_PRODUCT, 100),
                    CosmeticCatalog.grantsOf
                )
                local twice, result = Entitlements.apply(
                    once,
                    receipt("p1", COAT_PRODUCT, 100),
                    CosmeticCatalog.grantsOf
                )
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.acknowledge, true)
                TestRunner.equal(result.reason, "duplicate")
                TestRunner.equal(#result.granted, 0)
                TestRunner.equal(Entitlements.owns(twice, COAT), true)
                --[[
                    Nothing moved. Compared by content rather than by identity
                    because `apply` normalizes whatever it is handed, so even a
                    no-op comes back as a fresh table -- which is why the flag
                    a caller must branch on is `applied`, not "did the value
                    change". Writing on a duplicate would bump a revision and
                    cost a save write for a purchase that was already settled.
                ]]
                TestRunner.equal(result.applied, false)
                TestRunner.equal(twice.processed["p1"], once.processed["p1"])
                local ownedBefore = 0
                for _ in once.entitlements do
                    ownedBefore += 1
                end
                local ownedAfter = 0
                for _ in twice.entitlements do
                    ownedAfter += 1
                end
                TestRunner.equal(ownedAfter, ownedBefore, "a retry granted something extra")
            end,
        },
        {
            --[[
                The build that has never heard of the product. Answering
                "granted" here tells the platform to stop retrying a purchase
                the player has paid for and not received, and there is no way
                back from that except a refund somebody has to notice.
            ]]
            name = "an unknown product is refused rather than consumed",
            run = function()
                local state, result = Entitlements.apply(
                    Entitlements.default(),
                    receipt("p2", "product_from_a_later_build", 100),
                    CosmeticCatalog.grantsOf
                )
                TestRunner.equal(result.applied, false)
                TestRunner.equal(result.acknowledge, false)
                TestRunner.equal(result.reason, "unknown_product")
                TestRunner.equal(
                    state.processed["p2"],
                    nil,
                    "an unknown product entered the ledger"
                )
            end,
        },
        {
            name = "a malformed receipt is refused and changes nothing",
            run = function()
                for _, junk in
                    {
                        {},
                        { purchaseId = "", productId = COAT_PRODUCT },
                        { purchaseId = "p3" },
                        { purchaseId = string.rep("x", 400), productId = COAT_PRODUCT },
                        "not a receipt",
                        42,
                    }
                do
                    local state, result =
                        Entitlements.apply(Entitlements.default(), junk, CosmeticCatalog.grantsOf)
                    TestRunner.equal(result.applied, false)
                    TestRunner.equal(result.acknowledge, false)
                    TestRunner.equal(next(state.entitlements), nil)
                end
            end,
        },
        {
            --[[
                The mailbox, which exists for exactly one moment: a receipt
                arriving while the profile is not ours to write. Dropping it
                loses the purchase; writing anyway is two servers writing one
                save. Holding it is the only answer that costs nobody anything.
            ]]
            name = "a receipt held while the profile is away is drained intact",
            run = function()
                local mailbox = Entitlements.emptyMailbox()
                local held, accepted =
                    Entitlements.enqueue(mailbox, receipt("p4", COAT_PRODUCT, 200))
                TestRunner.equal(accepted, true)
                TestRunner.equal(#held, 1)
                -- the platform retries into the mailbox too, and a held
                -- purchase id is already held
                local again, second = Entitlements.enqueue(held, receipt("p4", COAT_PRODUCT, 200))
                TestRunner.equal(second, false)
                TestRunner.equal(#again, 1)

                local state, remaining, granted =
                    Entitlements.drain(Entitlements.default(), again, CosmeticCatalog.grantsOf)
                TestRunner.equal(#remaining, 0)
                TestRunner.equal(#granted, 1)
                TestRunner.equal(Entitlements.owns(state, COAT), true)
            end,
        },
        {
            -- A receipt a later build will understand stays in the mailbox
            -- rather than being dropped on the floor of the one that cannot.
            name = "a receipt this build cannot resolve stays in the mailbox",
            run = function()
                local held = Entitlements.enqueue(
                    Entitlements.emptyMailbox(),
                    receipt("p5", "product_from_a_later_build", 300)
                )
                local state, remaining, granted =
                    Entitlements.drain(Entitlements.default(), held, CosmeticCatalog.grantsOf)
                TestRunner.equal(#remaining, 1)
                TestRunner.equal(#granted, 0)
                TestRunner.equal(next(state.entitlements), nil)
            end,
        },
        {
            -- Draining twice must not grant twice, which is the mailbox's own
            -- version of the retry case: a drain that crashed after applying
            -- and before clearing runs again on the next load.
            name = "draining the same mailbox twice grants once",
            run = function()
                local held = Entitlements.enqueue(
                    Entitlements.emptyMailbox(),
                    receipt("p6", COAT_PRODUCT, 400)
                )
                local once, remaining =
                    Entitlements.drain(Entitlements.default(), held, CosmeticCatalog.grantsOf)
                TestRunner.equal(#remaining, 0)
                -- the same mailbox again, as if the clear never landed
                local twice, _, granted = Entitlements.drain(once, held, CosmeticCatalog.grantsOf)
                TestRunner.equal(#granted, 0, "a redrained mailbox granted again")
                TestRunner.equal(Entitlements.owns(twice, COAT), true)
            end,
        },
        {
            name = "storage is bounded on the way back in",
            run = function()
                local hostile = {
                    entitlements = { [string.rep("z", 400)] = true, [COAT] = true, other = false },
                    processed = { p7 = 0 / 0, p8 = 10 },
                    equipped = { outfit = "cosmetic_not_in_the_catalog" },
                }
                local state = Entitlements.normalize(hostile, function(cosmeticId: string): boolean
                    return CosmeticCatalog.get(cosmeticId) ~= nil
                end)
                TestRunner.equal(Entitlements.owns(state, COAT), true)
                TestRunner.equal(state.entitlements[string.rep("z", 400)], nil)
                TestRunner.equal(state.entitlements["other"], nil)
                TestRunner.equal(state.processed["p7"], nil, "a NaN timestamp survived")
                TestRunner.equal(state.processed["p8"], 10)
                TestRunner.equal(
                    Entitlements.equippedIn(state, "outfit"),
                    nil,
                    "a slot kept pointing at a cosmetic the catalog dropped"
                )

                --[[
                    Worn implies owned on the way back in as well. A save field
                    saying you are wearing something you never bought is a free
                    cosmetic for anyone who can write one, and it is also the
                    state a refund leaves behind -- both are dropped here.
                ]]
                local unpaid = Entitlements.normalize({
                    equipped = { outfit = COAT },
                }, function(cosmeticId: string): boolean
                    return CosmeticCatalog.get(cosmeticId) ~= nil
                end)
                TestRunner.equal(Entitlements.equippedIn(unpaid, "outfit"), nil)

                -- and an entitlement for something the catalog no longer sells
                -- does not survive either: a product that was removed is
                -- removed, and keeping the id would be a slot pointing at
                -- nothing the moment somebody equipped it.
                local retired = Entitlements.normalize({
                    entitlements = { cosmetic_from_a_removed_product = true, [COAT] = true },
                }, function(cosmeticId: string): boolean
                    return CosmeticCatalog.get(cosmeticId) ~= nil
                end)
                TestRunner.equal(
                    Entitlements.owns(retired, "cosmetic_from_a_removed_product"),
                    false
                )
                TestRunner.equal(Entitlements.owns(retired, COAT), true)
            end,
        },
    },
}
