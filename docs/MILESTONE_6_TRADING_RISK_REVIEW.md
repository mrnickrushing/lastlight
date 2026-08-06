# Milestone 6 trading risk review

## The deliverable

The roadmap lists "safe restricted trading **if it survives risk review**."
This document is that review. Its conclusion is a decision, so a future
session does not re-litigate it from scratch.

## Decision: trading does not ship for launch

Rejected for the launch window, revisitable post-launch behind its own
flag. The reasons, in weight order:

1. **The economy is young and finally honest.** The harvest → bank →
   craft loop only began paying out at all in #212. Every balance number
   downstream of it (recipe costs, storage caps, wear repair costs, trait
   scale) assumes materials are earned at expedition pace. Any transfer
   channel between players re-prices all of it at the pace of the most
   grind-tolerant player in a party, before we have a single day of
   telemetry on the intended pace.
2. **Scam surface vs. audience.** The likeliest audience skews young.
   Restricted trading (windowed, confirmable, logged) still creates the
   canonical scam vectors — switch-at-confirm, loan-and-leave, cross-town
   pressure — and this project has no moderation staffing to absorb the
   reports. The GDD's own charter is "earned in play, never purchasable";
   an inter-player market is purchase pressure by another door.
3. **Everything trade would give, the town already gives more safely.**
   Shared construction contributions, shared decorations, shared night
   defense, and the visitor model are the cooperative economies this game
   wants. A visitor who wants to help a town can build it, defend it, and
   decorate it — one-way, logged, and grief-guarded by TownPermissions.
4. **Idempotency debt.** Every transaction path in this codebase carries
   transaction ids, settlement records, and replay guards, added one
   hard-won lesson at a time. A trade is a two-party mutation of two
   profiles that must commit or abort atomically across two DataStore
   writes. That machinery does not exist, and building it for a feature
   with the above risks is not launch-window work.

## What ships instead

Nothing new is required: the cooperative surfaces above already exist and
are the answer to "I want to give my friend something." If post-launch
telemetry shows a genuine, specific need (e.g. material gifting within a
party after a shared expedition), the narrow version to consider first is
**one-way gifting of raw materials only, capped per day, no gear, no
requests** — the smallest shape that cannot become a market.

## Review basis

Roblox community safety guidance on trading scams, this project's own
permission model (TownPermissions: visitors contribute upward, never
extract), the monetization validator's zero-purchase-branch guarantee, and
the economy's age (first honest payout: #212, the same week as this
review).
