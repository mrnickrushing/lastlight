# Commerce support, refunds and removals

MONETIZATION_LIVEOPS_ANALYTICS lists one prerequisite in its store-safety
section that is not a code change: *"refund/removal and support procedures are
documented before selling."* This is that document, and Milestone 11's
deliverable list names it too.

It is written before anything can be bought on purpose. A support procedure
invented during the first incident is a procedure written by whoever is most
upset at the time, and the decisions in it — what is refundable, who decides,
what a removed product does to the people who already own it — are exactly the
ones that should not be made under that pressure.

## What can actually be sold

Nothing yet, and that is load-bearing for everything below.
`Config.CommerceProductIds` is empty, the `cosmetic_store_enabled` flag is off,
and `promptPurchase` refuses with `product_not_configured` rather than opening a
prompt onto nothing. Until the owner creates the developer products in the
Creator Dashboard and pastes their IDs back, every procedure here is a rehearsal.

What will be sold, when that happens, is cosmetics and only cosmetics. That is
the fact that makes every refund answer below a short one: **nothing sold here
can be spent, consumed, traded, or lost.** A refunded cosmetic leaves a player
exactly where they were before they bought it, because it never changed
anything they could do.

## The four things a purchase can be, and why they are four events

The taxonomy separates `purchase_prompt`, `purchase_platform_result`,
`receipt_result` and `cosmetic_equipped`, and the separation exists for this
document rather than for a dashboard. **A player who writes in says one
sentence — "I bought it and I do not have it" — and it can mean four different
things with four different answers.** One merged `purchase` event answers none
of them.

| Where it stopped | What the events look like | What actually happened | The answer |
|---|---|---|---|
| The prompt never opened | `purchase_prompt` with `shown=false` | The product has no dashboard id in this build, or the platform call failed | Nothing was charged. This is ours to fix, not Roblox's. |
| The prompt opened and was closed | `purchase_prompt` then `purchase_platform_result` with `purchased=false` | The player cancelled, or the purchase failed at the platform | Nothing was charged. No refund exists because no payment does. |
| Charged, nothing granted | `purchase_platform_result` with `purchased=true`, **no** `receipt_result` | The receipt has not reached this game yet, or reached a server that could not resolve it | Real money, no entitlement. See *the one that matters* below. |
| Granted, not wearing it | `receipt_result` with `outcome=granted`, no `cosmetic_equipped` | It worked. They own it and have not put it on | Point them at the wardrobe row in the outfitter's panel. |

The middle two look identical to a player and are opposite to us. That is the
whole reason the events are separate, and it is why a merged event would have
to be answered by asking the player what they remember.

## The one that matters: charged and not granted

This is the only case that costs a real person real currency, and the game
emits an event named after it. `purchase_loss` is a zero-tolerance metric in
RELEASE_GATES.md: a receipt this build cannot resolve to a product, or a grant
whose durable write did not land.

**Check in this order.**

1. **Is it a retry rather than a loss?** The platform calls `ProcessReceipt`
   again until told the grant is durable, so a purchase in flight can legitimately
   have several `receipt_result` lines. A retry is the system working, and
   `Entitlements` refuses to grant twice for the same purchase id. Only the
   absence of a `granted` outcome is a problem.
2. **Is it in the mailbox?** A receipt that arrives while the buyer's profile is
   locked — because they are in another server, or because the load timed out —
   goes into a pending mailbox that lives outside the profile by construction,
   and drains at their next load. The honest answer to a player in this state is
   *rejoin*, and it is true.
3. **Does this build know the product?** A receipt for a product id that is not
   in `Config.CommerceProductIds` is deliberately **never consumed**. It stays
   pending with the platform, so a build that knows the product will grant it
   later. This is recoverable by shipping the id, and the player keeps their
   receipt in the meantime.
4. **Only then is it a real loss.** Grant it by hand through the same authority
   everything else uses — `applyReceipt` — and never by writing
   `profile.commerce.entitlements` directly. A hand-written entitlement skips the
   processed ledger, so the platform's next retry grants it a second time.

**Never ask a player to buy it again to see if it works.**

## Refunds

Roblox owns the money. This game cannot issue, reverse or partially refund a
Robux transaction, and saying otherwise to a player is a promise made on
somebody else's behalf. Refund requests go to Roblox Support; what this game
does is the entitlement half.

**Our policy, and it is short because cosmetics make it short:**

- A refund that Roblox grants is honoured on our side by **removing the
  entitlement**, because a player who has their money back and keeps the item has
  been paid to take it.
- Removing an entitlement must also **unequip it**, in the same write. A profile
  that owns nothing and wears something is a free cosmetic for anyone who can get
  a refund, and it is the exact state `Entitlements.normalize` already refuses to
  carry: a slot worn by somebody who does not own it is cleared on load.
- The purchase id **stays in the processed ledger**. Removing it would make the
  platform's next retry grant the item again, and a refunded purchase that grants
  itself back is worse than either outcome on its own.
- No progress is ever reversed with a refund, because no cosmetic ever granted
  any. This is the promise the whole monetization guard exists to keep, and it is
  what makes this section three bullets instead of a policy.

## Removing a product from sale

Three different things get called "removing a product" and only one of them is
safe.

**Delisting** — taking a product out of the store so it can no longer be bought.
Remove its id from `Config.CommerceProductIds`. Anyone who already owns the
cosmetic keeps it and can still wear it, because **the wardrobe is a second
list**: owned cosmetics are drawn from the player's entitlements rather than
from the sale cards, precisely so that a delisted product cannot make a paid-for
coat unwearable. This is the safe operation.

**Killing the store** — `cosmetic_store_enabled` off. The outfitter's stand
refuses with THE OUTFITTER IS NOT OPEN YET, nothing can be bought, and everything
already owned is still wearable and still equippable, because equipping is not
buying and is deliberately not gated on the store being open.

**Deleting a cosmetic from the catalog** — do not, without replacing it.
`Entitlements.normalize` drops entitlements for cosmetics the catalog no longer
knows, so deleting an entry silently takes it away from everyone who bought it.
That behaviour is correct on its own terms — it is what keeps a save from
carrying a reference to nothing — which is exactly why deleting a *sold*
cosmetic is a data-loss operation wearing a cleanup's clothes. If a cosmetic must
stop existing, the entry stays and stops being sold.

A product that is removed while a receipt for it is in flight is covered by rule
3 above: the receipt is never consumed, so the purchase is not lost, it is
waiting.

## What a support answer may not do

- **Never grant an entitlement by editing a profile.** One authority,
  `applyReceipt`, for the reason the retry rule exists.
- **Never grant a cosmetic as compensation for a gameplay problem.** A cosmetic
  handed out to settle a complaint about difficulty is a cosmetic that has a
  gameplay meaning, and the monetization guard's whole claim is that none of them
  do.
- **Never ask for an account password, a receipt screenshot containing payment
  details, or anything Roblox does not already show us.** The user id and the
  product id are the whole of what an answer needs.
- **Never promise a refund.** Roblox decides; we honour.

## Escalation

| Signal | Where it goes |
|---|---|
| `purchase_loss` at all | Immediate. It is zero-tolerance in RELEASE_GATES.md, and one line means one person paid for nothing. |
| `receipt_result` past the 60-second durable-grant threshold | The release gate that reads it, not a support queue. A slow grant is a systemic problem that will arrive as many tickets. |
| A refund request | Roblox Support, then the entitlement removal above once it is granted. |
| A moderation or harassment report | Roblox's own report flow, which every client carries. SOCIAL_SAFETY_REVIEW.md says why this game does not run a second one. |

## Still owner-gated

Everything that needs a person: the Creator Dashboard products and their ids,
the prices, platform and regional policy review, and the on-call contact who
receives the escalations above. This document is the procedure; the people are
M13's and M14's.
