--!strict

--[[
    Four ways a purchase is lost, walked one at a time.

    `ProcessReceipt` cannot be exercised in Studio and will not be exercised
    anywhere until a real account buys something with real Robux. That is
    exactly why the decision it makes lives in `Entitlements.route` rather than
    inside `CommerceService`: the branch is pure, so it can be driven here
    against every state the running game can be in, and the service is left
    holding only a profile, a mailbox and a write.

    The four scenarios are the ones the wave's gate names, and each is a real
    incident report from some other game:

      * **Retry.** The platform calls again because it never heard the answer.
        Granting twice hands out two of something bought once.
      * **Crash mid-grant.** The state was computed and the write never landed.
        Nothing may be acknowledged, or the purchase is gone.
      * **Profile lock.** The buyer's save belongs to another server. Writing
        anyway costs them the save; refusing outright costs them the purchase.
      * **Disconnect.** The buyer is not here at all. Same answer as the lock,
        by the same mailbox.

    Each has to grant exactly once across the whole sequence, and "exactly
    once" is checked by counting what the player ends up owning rather than by
    counting calls -- a call count would pass on a grant that ran twice and
    happened to be idempotent by luck.
]]

local CosmeticCatalog = require("../../src/shared/CosmeticCatalog")
local Entitlements = require("../../src/shared/Entitlements")
local TestRunner = require("../TestRunner")

local COAT = "cosmetic_lantern_keeper_coat"
local COAT_PRODUCT = "product_lantern_keeper_coat"

local function receipt(purchaseId: string): any
    return { purchaseId = purchaseId, productId = COAT_PRODUCT, at = 1000 }
end

local function ownedCount(state: any): number
    local count = 0
    for _ in state.entitlements do
        count += 1
    end
    return count
end

return {
    name = "CommerceReceipts",
    cases = {
        {
            --[[
                The happy path plus its retry. The platform calls again because
                it did not hear the first answer; the second call must be told
                yes without granting a second time.
            ]]
            name = "a retried receipt grants exactly once",
            run = function()
                local profile = Entitlements.default()
                local mailbox = Entitlements.emptyMailbox()

                local first, _, verdict =
                    Entitlements.route(profile, mailbox, receipt("p1"), CosmeticCatalog.grantsOf)
                TestRunner.equal(verdict, "granted")
                TestRunner.truthy(first ~= nil)
                profile = first :: any
                TestRunner.equal(ownedCount(profile), 1)

                local second, _, retryVerdict =
                    Entitlements.route(profile, mailbox, receipt("p1"), CosmeticCatalog.grantsOf)
                TestRunner.equal(retryVerdict, "granted", "a retry was told to try again forever")
                profile = second :: any
                TestRunner.equal(ownedCount(profile), 1, "a retry granted a second copy")
                TestRunner.equal(Entitlements.owns(profile, COAT), true)
            end,
        },
        {
            --[[
                The crash. The route computed a state and the server died
                before the write; nothing was acknowledged, so the platform
                calls again into a profile that never changed. The second run
                must produce the grant, not skip it.
            ]]
            name = "a crash between the decision and the write loses nothing",
            run = function()
                local durable = Entitlements.default()
                local mailbox = Entitlements.emptyMailbox()

                -- computed, then thrown away, exactly as an unsaved state is
                local lost =
                    Entitlements.route(durable, mailbox, receipt("p2"), CosmeticCatalog.grantsOf)
                TestRunner.truthy(lost ~= nil)
                TestRunner.equal(ownedCount(durable), 0, "the durable state moved without a write")

                local recovered, _, verdict =
                    Entitlements.route(durable, mailbox, receipt("p2"), CosmeticCatalog.grantsOf)
                TestRunner.equal(verdict, "granted")
                TestRunner.equal(ownedCount(recovered :: any), 1)
                TestRunner.equal(Entitlements.owns(recovered :: any, COAT), true)
            end,
        },
        {
            --[[
                The lock, and the disconnect: from this module's side they are
                the same fact -- there is no profile state to write -- and both
                answer `held`. The receipt lands in the mailbox, the platform is
                told the purchase is safe, and the next load delivers it.
            ]]
            name = "a receipt for a locked or absent profile is held and later delivered",
            run = function()
                local mailbox = Entitlements.emptyMailbox()
                local state, nextMailbox, verdict =
                    Entitlements.route(nil, mailbox, receipt("p3"), CosmeticCatalog.grantsOf)
                TestRunner.equal(verdict, "held")
                TestRunner.equal(state, nil, "a locked profile was written to")
                TestRunner.equal(#nextMailbox, 1)

                -- the platform retries into the mailbox as well
                local _, retriedMailbox, retryVerdict =
                    Entitlements.route(nil, nextMailbox, receipt("p3"), CosmeticCatalog.grantsOf)
                TestRunner.equal(retryVerdict, "held")
                TestRunner.equal(#retriedMailbox, 1, "a retry banked a second copy")

                -- and the load that finally holds the profile delivers it once
                local delivered, remaining, granted = Entitlements.drain(
                    Entitlements.default(),
                    retriedMailbox,
                    CosmeticCatalog.grantsOf
                )
                TestRunner.equal(#remaining, 0)
                TestRunner.equal(#granted, 1)
                TestRunner.equal(ownedCount(delivered), 1)
            end,
        },
        {
            --[[
                The whole sequence at once, because the ways these interleave
                are where a real incident comes from: held while away, retried
                while away, drained on arrival, then retried once more by a
                platform that was still waiting on the very first answer.
            ]]
            name = "held, retried, drained and retried again grants exactly once",
            run = function()
                local mailbox = Entitlements.emptyMailbox()
                local _, banked =
                    Entitlements.route(nil, mailbox, receipt("p4"), CosmeticCatalog.grantsOf)
                local _, bankedAgain =
                    Entitlements.route(nil, banked, receipt("p4"), CosmeticCatalog.grantsOf)

                local profile, remaining = Entitlements.drain(
                    Entitlements.default(),
                    bankedAgain,
                    CosmeticCatalog.grantsOf
                )
                TestRunner.equal(#remaining, 0)
                TestRunner.equal(ownedCount(profile), 1)

                local afterRetry, _, verdict = Entitlements.route(
                    profile,
                    Entitlements.emptyMailbox(),
                    receipt("p4"),
                    CosmeticCatalog.grantsOf
                )
                TestRunner.equal(verdict, "granted")
                TestRunner.equal(
                    ownedCount(afterRetry :: any),
                    1,
                    "the late retry granted a second copy"
                )
            end,
        },
        {
            --[[
                And the receipt this build cannot deliver, in both branches. It
                is never acknowledged and never banked: telling the platform to
                stop retrying leaves a player holding a receipt for nothing, and
                a mailbox full of entries nobody can apply is a support queue
                with no answer at the end of it.
            ]]
            name = "an unresolvable receipt is retried, never held, never granted",
            run = function()
                local unknown =
                    { purchaseId = "p5", productId = "product_from_a_later_build", at = 1 }
                local state, mailbox, verdict = Entitlements.route(
                    Entitlements.default(),
                    Entitlements.emptyMailbox(),
                    unknown,
                    CosmeticCatalog.grantsOf
                )
                TestRunner.equal(verdict, "retry")
                TestRunner.equal(state, nil)
                TestRunner.equal(#mailbox, 0)

                local _, awayMailbox, awayVerdict = Entitlements.route(
                    nil,
                    Entitlements.emptyMailbox(),
                    unknown,
                    CosmeticCatalog.grantsOf
                )
                TestRunner.equal(awayVerdict, "retry")
                TestRunner.equal(#awayMailbox, 0, "an unresolvable receipt was banked")
            end,
        },
        {
            name = "a malformed receipt is retried and touches nothing",
            run = function()
                for _, junk in
                    { {}, { purchaseId = "p6" }, { productId = COAT_PRODUCT }, "receipt", 7 }
                do
                    local state, mailbox, verdict = Entitlements.route(
                        Entitlements.default(),
                        Entitlements.emptyMailbox(),
                        junk,
                        CosmeticCatalog.grantsOf
                    )
                    TestRunner.equal(verdict, "retry")
                    TestRunner.equal(state, nil)
                    TestRunner.equal(#mailbox, 0)
                end
            end,
        },
    },
}
