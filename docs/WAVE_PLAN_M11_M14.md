# Wave plan — Milestones 11 through 14

The owner's directive (2026-08-07): *complete milestones 11 through 14
continuously, wave by wave, each implemented, tested, merged and published,
without checking in between waves.* This is the queue that makes that
possible. Every entry names its scope, the files it touches, and the gate
that says it is done, so a session picks up cold and starts warm. It is the
successor to [WAVE_PLAN_M8_M10.md](WAVE_PLAN_M8_M10.md), which carried three
milestones on the same shape.

Milestones 0 through 10 are complete. What follows is different in kind from
what came before it, and the difference is the first thing a session needs to
understand: **M11 is mostly buildable, M12 through M14 mostly are not.** An
internal alpha needs players. A closed beta needs cohorts, devices and
guardian consent. A launch candidate needs store review, a Creator Dashboard
and a human who has looked at the icon. No amount of code produces any of
that.

So the rule this plan is built on: **everything buildable is a wave;
everything that needs a human with a phone or a test group is a blocker in
the owner-gated section, and a blocker never stops implementation.** The
waves below are the parts of M12–M14 a session can actually finish — almost
all of them are instrumentation, harnesses and guards that make the human
half *measurable* when the owner gets to it. A gate nobody can measure is a
gate that passes by assertion.

## The rhythm

`branch → implement → npm run test → PR → poll checks → merge → npm run
publish → handoff header → next wave`, no pause between. Docs update in the
same wave that earns them; deferring them breaks the only knowledge sync this
project has across sessions.

## Owner-gated, outside the PR stream

These cannot be closed by writing code, and implementation never waits on
them. The list is longer than M8–M10's because that is what these milestones
are.

**Carried forward, still open:**

- **Live Studio passes** for anything a camera has to judge. The ledger is in
  the M7 runbook.
- **The gear art pass** — 82 of 90 craftable items draw a derived plan.
- **The WHET press** on a genuinely dulled weapon (~30 landed strikes).
- **Device-hardware items** — baseline phone performance, touch reach, safe
  areas.
- **Flipping a region's `enabled` flag** once a live session walks it end to
  end.

**New with M11 (commerce and social):**

- **Creator Dashboard product configuration.** Game passes and developer
  products do not exist until somebody creates them in the dashboard and
  copies the IDs back. Every commerce wave below is built against a config
  table of IDs that is empty until then, and the store is behind a feature
  flag that is off until it is not.
- **Price research and platform policy review.** Robux prices, regional
  policy, age suitability. MONETIZATION_LIVEOPS_ANALYTICS.md sets the rules;
  the numbers are the owner's.
- **Cosmetic art.** The catalog can ship as data with derived presentation
  (the #292 pattern: a labelled floor, `derived = true`, nothing invisible
  and nothing claiming to be authored). Replacing derived plans with authored
  art is an art pass.
- **A live purchase test with a real receipt.** `ProcessReceipt` cannot be
  exercised in Studio. The idempotency logic is pure and spec-covered; the
  round trip is not.
- **Privacy and abuse review.** M11's exit gate says "social systems pass
  privacy and abuse review". The waves produce the artifact that review reads
  (every player-to-player channel and what bounds it); the review is a human
  reading it.

**New with M12–M14 (cohorts, devices, and the dashboard):**

- **Daily full-path playtests** and **human completion coverage of every
  quest**. Automated traversal proves reachability, not comprehension.
- **The device lab** and **long-session soak on real hardware**.
- **Narrative continuity and content sensitivity review.**
- **Production-like services** — DataStore behaviour under real load,
  representative concurrency, reserved-server teleports at scale. None of
  this exists in Studio.
- **Every cohort in M13's rollout**: trusted testers, the age-range allowlist
  with guardian consent, the larger flagged cohort, the creator/community
  test. Also the measurement window itself — the thresholds in
  RELEASE_GATES.md are read from a population, and there is no population.
- **The M13 decisions**: what to remove for recurring confusion, which
  languages ship, the final catalog and prices.
- **Moderation, support, incident, rollback and communication drills.**
- **All of M14's launch assets**: icon, thumbnails, trailer, description,
  age/content disclosures, Creator Dashboard configuration, production places
  and universe links, on-call contacts.
- **Canary and scale tests**, and the seven launch journeys (fresh,
  returning, migrated, payer, non-payer, solo, group).

## The monetization guard, before anybody writes store code

`scripts/validate_monetization.py` asserts two things over every `.luau` file
in `src/`:

1. gameplay code may not reference a purchase API at all;
2. nothing outside the allowlist may read a player's membership or ownership
   state, "because a branch on *does this player own X* is how a cosmetic
   quietly becomes a requirement".

**The allowlist is currently empty**, and the script says in its own docstring
why: an exit-gate item that passes because a thing is missing goes on passing
right up until someone adds the thing. M11 adds the thing. So the store's
architecture has to be decided here, before wave E, rather than discovered by
whoever writes the first `MarketplaceService` call.

The design that keeps the validator true:

- **Exactly one module ever touches a purchase or ownership API**:
  `src/server/Services/CommerceService.luau`. It goes into `ALLOWED` with its
  reason in the same commit that creates it. One entry, forever. If a second
  module ever needs to be added, that is the design failing, not the list
  being too short.
- **Entitlements are resolved outside gameplay and land as plain data.**
  CommerceService answers "what does this player own" once — at profile load,
  and again on a receipt — and writes the answer into
  `profile.commerce.entitlements` as a set of ids. Nothing downstream asks
  the platform anything. The distinction that matters: gameplay never branches
  on *ownership*, it branches on *what is equipped*, and what is equipped is a
  profile field like every other.
- **Cosmetics are pure presentation.** A cosmetic id resolves through
  `CosmeticCatalog` to a visual plan and to nothing else. No cosmetic appears
  in a stat, a gate, a capacity, a recipe, a drop table, a spawn rule or a
  reward. This is the same shape `TownDecorations` already has ("identity only
  — no slot changes a stat"), and it is what makes the *absence* of ownership
  branches possible rather than merely required: there is nothing for a
  gameplay branch to read.
- **Equipping an unowned cosmetic is refused where entitlements are read, not
  where cosmetics are drawn.** The refusal lives in CommerceService's
  neighbourhood; the drawing code takes an id and draws it. That keeps the
  ownership question in one file and out of `GearVisualService`, the HUD, and
  everything else.

Two specs make it checkable rather than aspirational, and both exist to catch
the failure this codebase has now been bitten by three times — **a thing that
exists in a catalog and a thing that is reachable in the world are different
facts**:

- **`CosmeticNeutrality.spec`** — walks every cosmetic entry and fails on any
  numeric field outside a declared presentation whitelist (colour, scale,
  material, offset, effect intensity); fails if any module under
  `src/shared` or `src/client` requires the entitlement reader; and pins the
  allowlist in `validate_monetization.py` at exactly one entry, by name.
- **`CosmeticReachability.spec`** — every id in the catalog resolves to a
  visual plan the appearance service has a case for, and every entitlement the
  catalog can grant names a cosmetic that exists. **An entitlement that exists
  and a cosmetic that can actually be worn are different facts.** The equip
  panel shipped as a hardcoded list of eight items and left ninety craftable
  items unwearable with nothing failing (#299); a store has exactly the same
  shape and more expensive consequences.

## Milestone 11 — Social and commerce readiness

Trading is already decided: **it does not ship for launch**, with the reasons
recorded in [MILESTONE_6_TRADING_RISK_REVIEW.md](MILESTONE_6_TRADING_RISK_REVIEW.md)
so it is not re-litigated. That is the deliverable "reviewed trade system or
explicit post-launch deferral", already met, and the exit-gate line about
trade duplication is satisfied by there being no trade.

| Wave | Scope | Done when |
|---|---|---|
| A ✅ | **Parties, invites and rejoin** (shipped #319). A party is a named thing that outlives the platform: `PartySession.luau` (pure) owns identity, roster, invites and the rejoin contract; `PartyService` owns the live parties and writes each member a rejoin ticket at launch; `RunHandoff` carries the party id; save schema 22 persists the ticket. Files: `src/shared/PartySession.luau`, `src/shared/RunHandoff.luau`, `src/shared/SaveSchema.luau`, `src/server/Services/PartyService.luau`, `src/server/Services/LobbyService.luau`, `src/client/Controllers/HUDController.luau` | Party spec: a party boards ahead of bystanders; a leader who leaves hands over rather than dissolving; a ticket for another party is refused; an expired ticket returns to the lobby. Migration spec: an era-21 save arrives with no ticket |
| B ✅ | **Pings and quick chat** (shipped #328). A bounded phrase vocabulary, not free text, so moderation is structural: `src/shared/QuickChat.luau` holds ~24 phrases in categories, each with a category and a ping meaning. A ping marks **the sender's own position, resolved server-side** — the payload carries a phrase id and nothing else, which is both the one-extra-field contract and the reason a ping cannot be forged to a place the sender is not standing. Rate-limited through `RateLimiter` at the same door as every other action | Quick-chat spec: no free-text path exists; every phrase has a category; the wheel draws every phrase (nothing catalog-only); a blocked player's phrases and pings do not reach the blocker |
| C ✅ | **Visits, showcases and privacy permissions** (shipped #329). Visits are already a concept — `TownNightService.hostInfo`, the visitor role, `TownPermissions`' upward-only contribution. What is missing is *choosing* to visit and *deciding who may*. New `src/shared/TownVisitPolicy.luau` (open / friends / invited / closed) on the profile, enforced where the host is adopted; a showcase view that reads the host's town record for a visitor | Policy spec: every policy value refuses and admits the right roles; `closed` cannot be bypassed by any arrival path; a visitor still cannot degrade anything (TownPermissions' invariant re-asserted against the new path) |
| D ✅ | **Block, report and moderation surface** (shipped #330). Roblox's own block list is authoritative and has to actually *suppress*: quick chat, pings, invites, and visit permission all consult it. Report goes through the platform's own prompt. The wave's real deliverable is `docs/SOCIAL_SAFETY_REVIEW.md`: every player-to-player channel in the game, what bounds it, and what a block does to it — the artifact the owner's privacy and abuse review reads | Safety spec: every channel enumerated in the doc has a suppression path in code, and every suppression path in code is enumerated in the doc. Neither list may grow alone |
| E ✅ | **Entitlements and the cosmetic spine** (shipped #331). The architectural wave, and the one the section above is about. `src/shared/CosmeticCatalog.luau` (presentation only), `src/shared/Entitlements.luau` (pure: what an entitlement is, how a receipt resolves to a grant, idempotency by purchase id, the pending mailbox), and `profile.commerce` in the save schema. **No `MarketplaceService` in this wave** — the whole spine is testable without the platform, and building it first means the platform call, when it lands, has nowhere to put a decision | `CosmeticNeutrality.spec` and `CosmeticReachability.spec` both green; `validate_monetization.py` still passes with an empty allowlist |
| F ✅ | **CommerceService and receipts** (shipped #332). The one allowlisted module. `ProcessReceipt` is the only grant authority; the purchase id is the idempotency key; the grant checks the processed ledger and durable ownership before applying; the receipt returns granted only after a durable write. The pending mailbox drains at load so a grant that arrived while the profile was locked is not lost. Adds `src/server/Services/CommerceService.luau` to `ALLOWED` with its reason | Receipt spec: retry, server crash mid-grant, profile lock, and disconnect each grant exactly once. Allowlist has exactly one entry and `CosmeticNeutrality.spec` says so |
| G | **The store surface: preview, price, permanence, owned state.** Preview stands on the lodge's opposite wall (the shape is already specified in [CHARACTER_KITS_SPEC.md](CHARACTER_KITS_SPEC.md)). Every card shows a real preview, the exact Robux price read from platform product info rather than a client constant, permanence stated, and owned state. A pure `StoreAvailability` predicate reads the snapshot fields the HUD already has and refuses to open during onboarding, active defense, downed, or defeat | Availability spec: every forbidden state named in the exit gate is a case, and each one refuses. Card spec: no card can render without price, permanence and owned state |
| H | **The initial direct cosmetic catalog.** The first real products: outfit sets, weapon and tool skins, lantern shells, emote packs, banners. Data plus derived presentation; authored art is owner-gated and the derived plan is the labelled floor | Census-style spec: every product resolves to a cosmetic, every cosmetic to a plan, and the count is asserted so it can only move deliberately |
| I | **Private-server controls.** Expanded settings for invited players — phase pause in non-reward practice, seed selection among already-discovered seeds, cinematic tools. Reward-bearing modifiers stay server-defined | Spec: no private-server setting changes a reward, and a practice phase grants nothing |
| J | **Commerce analytics and the support runbook.** `store_view`, `product_detail_view`, `purchase_prompt`, `receipt_result`, `cosmetic_equipped` into `AnalyticsService` (already named in the taxonomy, not yet emitted), and `docs/COMMERCE_SUPPORT.md` for refund, removal and support procedures — which MONETIZATION_LIVEOPS_ANALYTICS requires to exist *before* anything is sold | Analytics spec: each of the five events has an emitter and a call site. Doc exists and the roadmap's gate line points at it |

## Milestone 12 — Internal alpha

The milestone is "feature- and content-complete, not necessarily tuned". Most
of the *work* list is human. What is buildable is the half that makes the
human half measurable, and it is worth more than it looks: an exit gate that
says "save-loss and purchase-loss rate is zero in a forced scenario suite"
needs the forced scenario suite to exist before anybody can claim it.

| Wave | Scope | Done when |
|---|---|---|
| A | **Save migration rehearsal.** `SaveMigration.spec` already holds an era fixture per released schema and refuses a bump without one. What it does not do is walk one profile *through* every era in sequence, which is what a real player's save does. Add the sequential walk, and a forced-scenario suite: mid-write disconnect, profile lock, DataStore failure, restore-from-backup, and the same again with a pending purchase in the mailbox | Rehearsal spec: a schema-11 profile arrives at current with every field that ever meant something still meaning it; zero loss across every forced scenario, purchases included |
| B ✅ | **Exploit and admin review, extended** (shipped #333). `ExploitGate.spec` covers the remote surface as it was. Extend it over everything M11 added — party invites (can a non-member invite? can an invite name a userId not in the server?), quick chat, visit policy, and every commerce action — plus a case per admin command | Exploit spec: every action kind in `RuntimeIds.Actions` has a refusal case, not only a success case |
| C | **Full-path traversal.** M10's gate asked for "automated traversal checks plus human completion" over every quest; the automated half deserves to grow to the whole content path. A headless walk: seven chapters, every region gate, every quest arc's sequencing, every recipe's inputs reachable from some node, every fragment's anchor resolvable | Traversal spec: the path from a fresh profile to the epilogue exists and is unbroken, and every catalog entry is reachable from it |
| D | **The metrics a gate reads.** RELEASE_GATES.md names thresholds; a threshold nobody emits an event for is a dashboard that reads zero forever and a gate that passes by silence. Walk every threshold in that document and assert an analytics event exists that could produce it | Gate-metric spec: every numbered threshold in RELEASE_GATES.md maps to an emitter in `AnalyticsService`. This is the same reachability question the census asks about content, asked about telemetry |
| E | **Soak instrumentation.** `PerformanceService` samples already. Add a soak mode that runs the night cycle repeatedly and asserts nothing grows without bound — instance count, connection count, tracked-enemy count, profile size | Soak spec: N cycles leave the same counts they started with, within a declared tolerance |

**Owner-gated for M12:** daily full-path playtests, the device lab,
long-session soak on hardware, narrative continuity and content sensitivity
review, production-like services, representative concurrency, and the defect
triage the exit gate describes.

## Milestone 13 — Closed beta

Almost entirely owner-gated: the milestone *is* a population. The waves are
the switches and the measurements that population needs to be worth having.

| Wave | Scope | Done when |
|---|---|---|
| A | **Cohort-scoped feature flags.** `FeatureFlagService` is global today. Add a cohort dimension so a flag can be on for trusted testers, then an allowlist, then everyone — which is exactly M13's four-stage rollout — and a documented matrix of which flag belongs to which stage | Flag spec: a cohort-scoped flag is off for a player outside the cohort, on inside it, and the global default is unchanged for every existing flag (bit-identical, pinned) |
| B | **First-session and first-night telemetry.** The tuning decisions M13 makes — first session, first night, difficulty cliffs, group scaling, repetition — each need a number. Emit them | Spec: each tuning decision named in the roadmap has an event carrying the number it would be decided on |
| C | **Tuning knobs as config.** The numbers M13 will change should be config, not constants buried in services, or every tuning pass is a code change and a rebuild | Spec: the named tuning values live in `Config` and every reader reads them from there |
| D | **Localization source coverage.** Every player-visible string through one table, so "finalize supported languages from localization QA capacity" is a capacity decision rather than an archaeology project | String spec: no player-visible literal outside the table. The same text check that catches an unwired action catches an unwired string |
| E | **Kill switches and the rollback drill's code half.** Every system that can be turned off, listed and proven off-able; a documented rollback procedure with the build and flag state it restores | Spec: every major system has a flag, and turning it off leaves a playable game rather than an error |

**Owner-gated for M13:** every cohort, guardian consent, the measurement
window, moderation and scale health, the removal decisions, the language
decision, the final catalog and prices, and all five drills.

## Milestone 14 — Launch candidate

The deliverable list is mostly dashboard and art. The waves are the guards
that keep a launch candidate from drifting after it is declared one.

| Wave | Scope | Done when |
|---|---|---|
| A ✅ | **Schema freeze guard** (shipped #334). "Frozen save schema except blocker fixes" is a promise no one can keep by remembering. A marker in `Config` plus a validator that fails any bump while it is set, with an explicit override that has to be typed | Validator refuses a bump under freeze and says how to override deliberately |
| B | **The launch checklist, executable.** QA_RELEASE_PLAN.md holds the checklist; a validator reads it and fails on an unchecked blocking item, so "complete launch checklist" is a check rather than a claim | `npm run check` fails while a blocking item is unticked |
| C | **Original-asset provenance.** `validate_mesh_assets.py`, `validate_image_assets.py` and `validate_audio_assets.py` already assert that assets exist and are registered. Extend them to assert an origin is recorded for each, which is what an original-IP audit needs to read | Every registered asset has provenance; an asset without it fails the check |
| D | **Release notes, known issues and dashboards, generated.** Release notes from the merged PR stream, known issues from the open-thread ledger the handoff already keeps, dashboards from the analytics taxonomy | The three documents build from the repository rather than being written from memory |
| E | **The rollback build and flag matrix**, recorded as the exact revision and flag state to restore, and verified by building it | The named revision builds and boots |

**Owner-gated for M14:** icon, thumbnails, trailer, description, age and
content disclosures, Creator Dashboard configuration, permissions, private
servers, product IDs, production places and universe links, final
localization and captions, on-call contacts, canary and scale tests, the
seven launch journeys, and the Roblox publishing/review configuration.

## Notes that save a session

- **The one-extra-field rule is the shape of every new action.**
  `ActionPayloadContract.extraField` gives a kind exactly one payload field.
  `LobbyDepart` is the single exception and it cost the owner two bug reports
  (#219) before anybody found it. Design new actions so one field is enough:
  a ping that marks *where the sender is standing* needs no vector, and
  cannot be forged into one.
- **A new action needs four things in the same commit**: an id in
  `RuntimeIds.Actions`, a field in `ActionPayloadContract` if it carries one,
  a server branch, and a client sender. `ActionWiring.spec` reads all four as
  text and is the spec that would have caught both #219 and #249.
- **Every new service must be registered** in `src/server/init.server.luau`,
  and `scripts/validate-plan.mjs` cross-checks the count against the
  PROJECT_STATUS header. Bump both.
- **A save schema change is seven edits**: `SaveSchema.default`, the
  normalize stamp, the `Profile` type, a normalize block, an era-N fixture
  plus `REQUIRED_FIELDS` in `SaveMigration.spec`, `Config.SaveSchemaVersion`,
  and the assert in `tests/studio/FoundationIntegration.server.luau` — then
  the PROJECT_STATUS header.
- **The shared layer must not use Roblox datatypes.** The Lune runner cannot
  provide `Vector3` or `CFrame`. Pass number pairs and let a service assemble
  them; a first draft of `CompanionMotion` failed typecheck for exactly this
  and the failure was the rule working.
- **A secret the server holds and a fact the client sees are different
  objects.** The rejoin ticket is the live example: the server keeps a
  reserved-server access code, the client is told only that a rejoin is
  available. Anything commerce adds will have the same split, and putting
  both in one table is how the wrong half replicates.
- **Ask whether the thing is reachable, not whether it exists.** 120 recipes
  had no bench, 24 residents had no body, eight props would have rendered as
  somebody else's, ninety craftable items could not be equipped. All of them
  passed every spec. A silent fallback is what makes that class of gap
  invisible, and a store is full of silent fallbacks waiting to happen.
