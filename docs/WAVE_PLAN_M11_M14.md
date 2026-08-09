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
  end. **Ironroot Delve is open** (#363: the region assembly seam, the walk,
  and the six defects it found, all in one pull request) and **Mireglass Fen
  is open** (#365, through the same seam, with the wiring spec that keeps a
  fight and its arena in agreement); the Reach, the Vale, the Crown and the
  Hollow still wait on their own walks.

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
| G ✅ | **The store surface** (shipped #337). The outfitter's stand in the departure lodge is the only door, because a storefront openable from the HUD is openable in all four moments the exit gate forbids. `StoreAvailability` (pure) is asked by the server at the door and by the HUD every push, so an open panel shuts itself when a night starts. `StoreCard` refuses to build a card without price, permanence, owned state and real geometry — the price read from platform product info, never a constant. The wardrobe is a second list so a delisted product cannot make a paid-for cosmetic unwearable | Availability spec: every forbidden state named in the exit gate is a case, and each one refuses. Card spec: no card can render without price, permanence and owned state |
| H ✅ | **The initial direct cosmetic catalog** (shipped #338). The unit is a **line** — one look carried across all five slots — because nobody wants a lantern shell, they want the look it finishes. Four lines named for regions, 20 cosmetics, 24 products (one per cosmetic plus one set per line). Emote packs are still out, for wave E's reason: an emote is a motion, and the only geometry a plan could offer for one is a glow | Census-style spec: every product resolves to a cosmetic, every cosmetic to a plan, every line is complete, every set grants exactly its line, and the counts are asserted in the spec and in CONTENT_CATALOG.md |
| I ✅ | **Private-server controls** (shipped #339). The promise is that reward-bearing modifiers stay server-defined, and the way it is kept is that **every control forces practice, permanently**: a control that changes nothing about the world does not need a private server to house it, and a control that changes the world changes the run. `PrivateServerControls` (pure) owns the catalog, the authority rule and the one-way latch; `PrivateServerService` is the only caller of the four things that can be held still. Practice is two lines in `ProfileService` — the mutation seam and the durable write — rather than an audit of forty reward paths. Save schema 25 carries a discovered-seed history, and seed selection is bounded by it | Spec: every control in the catalog turns rewards off and none turns them back on, driven as a property over the whole list; a reserved run server is refused because nobody bought it; a seed cannot be chosen out of a history that does not hold it |
| J ✅ | **Commerce analytics and the support runbook** (shipped #340). All six commerce events the taxonomy names now have an emitter, a marked call site and a check holding the two lists against each other — which caught the sixth being emitted under a name the taxonomy does not use. [COMMERCE_SUPPORT.md](COMMERCE_SUPPORT.md) is the runbook MONETIZATION_LIVEOPS_ANALYTICS requires to exist *before* anything is sold, and it is organised around the four things "I bought it and I do not have it" can mean, because that is the sentence support actually arrives as | `CommerceAnalytics.spec`: every taxonomy event has an emitter logging that exact name, every emitter has a `COMMERCE-EVENT` call site, every marker is an event the taxonomy lists, none is emitted outside the server, and the runbook answers the four questions |

## Milestone 12 — Internal alpha

The milestone is "feature- and content-complete, not necessarily tuned". Most
of the *work* list is human. What is buildable is the half that makes the
human half measurable, and it is worth more than it looks: an exit gate that
says "save-loss and purchase-loss rate is zero in a forced scenario suite"
needs the forced scenario suite to exist before anybody can claim it.

| Wave | Scope | Done when |
|---|---|---|
| A ✅ | **Save migration rehearsal** (shipped #341). `SaveMigration.spec` normalizes each era fixture **once, straight to current**, which is not what a real save does: one played since schema 11 has been through fourteen migrations in sequence, each reading what the one before it wrote. `SaveRehearsal.spec` walks it one era at a time, and adds the forced-scenario suite M12's exit gate needs to exist before it can be claimed — mid-write disconnect, profile lock, DataStore failure, restore-from-backup, each against the pure module that decides it, and every one again with a purchase in the mailbox | Rehearsal spec: a schema-11 profile arrives at current with every earned field intact and its revision unmoved; every forced scenario loses nothing; a held receipt survives all of them and still grants exactly once; a cosmetic bought under an older schema is still owned and still worn at current |
| B ✅ | **Exploit and admin review, extended** (shipped #333). `ExploitGate.spec` covers the remote surface as it was. Extend it over everything M11 added — party invites (can a non-member invite? can an invite name a userId not in the server?), quick chat, visit policy, and every commerce action — plus a case per admin command | Exploit spec: every action kind in `RuntimeIds.Actions` has a refusal case, not only a success case |
| C ✅ | **Full-path traversal** (shipped #343). `FullPathTraversal.spec` makes **one** profile and walks it from `SaveSchema.default` to the epilogue through the real chapter mutators — no fixtures, every state asserted against is the state the previous assertion produced. At each step the region underfoot is open, the one after it is shut, and every chapter still ahead is offered and *refuses*, which is the difference between a walk that works and the only walk there is. The quest catalog is emptied rather than sampled, and the pass count is the depth of its deepest arc. The crafting tree turned out to hold a property worth pinning: six worked regions pay five materials each, none shared, and **no recipe reaches across regions** — so the tree is exactly as deep as the story. The Hollow pays nothing, asserted rather than assumed | Traversal spec: the path from a fresh profile to the epilogue exists and is unbroken, and every catalog entry is reachable from it |
| D ✅ | **The metrics a gate reads** (shipped #336). Eleven server emitters, each named by the gate it feeds in RELEASE_GATES.md and naming it back, plus `SessionSegment` for the platform class and performance tier every per-segment threshold is read on. Two gates are `review` — a blocker defect is a triage decision and a policy failure comes through Roblox's moderation — and the count of those is pinned so a threshold cannot be quietly downgraded into "a human will look at it" | `GateMetrics.spec`: every gate names an event with an emitter, every emitter has a `GATE-METRIC` call site that calls it, every marker is a gate in the document, and no gate is emitted from client code |
| E ✅ | **Soak instrumentation** (shipped #344). `SoakProbe` (pure) owns every rule about what a series of per-cycle counts means, and all three of them exist because the obvious subtraction passes on a leaking build: **the first cycle is not a baseline** (a server builds its world between sample one and sample two, and widening the tolerance until that stops hides a real leak), **a sample is only comparable to one taken at the same point in the cycle** (a series that drifts across phases is refused, not averaged), and **a leak's signature is that it does not stop** (growth is judged per cycle, and a metric still climbing at every step is a breach under its own tolerance — that run passed and a longer one would not have). `PerformanceService` samples once per town cycle at dawn from counters injected in `init.server`; `LastLightSoak` is the sixth Studio-only attribute and grants nothing. **Connection count is declared unobservable** — Roblox exposes no API, so `player_residue` watches the tables a leaked connection would keep alive instead, and the count of unobservable metrics is pinned | Soak spec: N cycles leave the same counts they started with, within a declared tolerance |

**Every buildable M12 wave has shipped** — A through E. What is left of the
milestone is the half that needs people, and naming it here rather than in a
verdict somewhere is the point of the split.

**Owner-gated for M12:** daily full-path playtests, the device lab,
long-session soak on hardware, narrative continuity and content sensitivity
review, production-like services, representative concurrency, and the defect
triage the exit gate describes. Two smaller ones the waves themselves turned
up: `profile_bytes` has never been soaked under a profile that is actually
being written (driving cycles from a session latches practice), and the six
regions' `enabled` flags are still the whole distance between the traversal
walk and a live playthrough.

## Milestone 13 — Closed beta

Almost entirely owner-gated: the milestone *is* a population. The waves are
the switches and the measurements that population needs to be worth having.

| Wave | Scope | Done when |
|---|---|---|
| A ✅ | **Cohort-scoped feature flags** (shipped #346). `RolloutCohorts` (pure) owns the four rungs and three rules: **the ladder only widens** (`admits` walks bottom-up and returns at the first rung that lets a player in, so advancing cannot subtract), **a cohort-scoped flag read without a player throws** rather than picking one of two silently wrong defaults, and **a bucket is stable per player and independent per flag** — that last one measured rather than reasoned about, because the affine first version made two ten-percent cohorts perfectly disjoint. The switch and the rung are one fact through `globalDefault`, so the bit-identical pin is a consequence. [BETA_ROLLOUT.md](BETA_ROLLOUT.md) is the matrix and the spec reads its rows out of the document | Flag spec: a cohort-scoped flag is off for a player outside the cohort, on inside it, and the global default is unchanged for every existing flag (bit-identical, pinned) |
| B ✅ | **First-session and first-night telemetry** (shipped #347). Five decisions, five events, and the reason a tuning event is not a gate event: a gate is a rate over instants and every gate emitter reports one instant, while a tuning decision is about a stretch of play. `AnalyticsService` already saw almost every number go past — what it did not do was **accumulate**. Two rules the events follow, both ways a tuning number lies: **a cliff is a comparison, so every checkpoint emits** rather than only the ones somebody suspects, and **an outcome without an attempt number is a survivorship number**. [BETA_TUNING.md](BETA_TUNING.md) is the table and `TuningMetrics.spec` is `GateMetrics.spec`'s three layers pointed at it | Spec: each tuning decision named in the roadmap has an event carrying the number it would be decided on |
| C ✅ | **Tuning knobs as config** (shipped #348). Wave B gave every decision a number; a number you cannot act on is an observation, so this is the other half. Ten values came out of four services into `Config`, and the rule that makes them knobs is that each has exactly **one home** — a service reading `Config.EliteStrikeRange` while keeping its own `STRIKE_RANGE` is a knob somebody turns and watches do nothing, which is a tuning pass producing a *wrong* answer rather than no answer. The pairing is the load-bearing check: **every decision has at least one knob**, so a sixth tuning decision cannot arrive with an event and no way to respond to it | Spec: the named tuning values live in `Config` and every reader reads them from there |
| D ✅ | **Localization source coverage** (shipped #355, #356, #358, #359, #360). Every player-visible string through one table, so "finalize supported languages from localization QA capacity" is a capacity decision rather than an archaeology project. **The guard landed first, with an explicit list of the files it does not yet cover**, which is the shape `validate_monetization.py`'s allowlist and `Config.SaveSchemaFreeze` already have: the rule is live from the first commit, every exception is named with a reason, and `ALLOWLIST_SIZE` is pinned so the list can only shrink. `src/shared/Strings.luau` is the table, `get` throws on a key nobody defined, and every surface is migrated across five batches. **The allowlist stands at one file and that is its floor** — the loading screen runs before the shared root replicates — with three more declared *not player-facing* on a separate list, readers named. 2,621 source strings, which is the number the language decision is made on | String spec: no player-visible literal outside the table. The same text check that catches an unwired action catches an unwired string — and both directions, since a key nothing reads is a string a translator is paid for and nobody sees |
| E ✅ | **Kill switches and the rollback drill's code half** (shipped #349). [ROLLBACK.md](ROLLBACK.md) lists every flag, what turning it off leaves, and its **scope** — the column that makes the list load-bearing, because *a switch you have to restart every server to use is not a switch*. `TownNightService` cached the town cycle's flag at construction, so its off switch needed a restart; it is read at the door a cycle comes through now. Writing the list also found **four flags nothing reads at all**, declared `none` with the reason rather than wired into a fiction, and that count is pinned harder than the restart count | Spec: every major system has a flag, and turning it off leaves a playable game rather than an error |

**Wave D is complete, in five guarded batches.** The reason it sat unbuilt through
two sessions was real: routing every player-visible string through one table touches
nearly every file that speaks to a player, and the check that gives the wave its
value cannot be switched on until the migration is complete — so the obvious
version is a very large diff with no guard on it, and a half-migrated table
looks finished from every direction except the one that matters.

The way past that is not to do it all at once, it is to **land the guard first
with the unmigrated files named**. `scripts/validate_localization.py` runs in
`npm run check` from the day it landed; a file is either covered, in which case
it may hold no player-visible literal at all, or on the allowlist with a written
reason and a promise. `ALLOWLIST_SIZE` is pinned and only ever lowered, so a new
file that speaks to a player routes its text through the table on the day it is
written, and every batch in between ships guarded.

**Batch two took the world surface** — `WorldService`, `BramblewakeBuilder` and
`RegionBuilders`, 227 strings — because it is the batch whose result can be read
back out of a running server rather than argued about: every proximity prompt
and every sign in the town is one of these strings, and a broken one is a blank
plank.

**Batch three took the server surface** — 483 strings out of the twenty server
files — and its value was less the strings than the two holes it found in the
check. A sentence assembled with `..` cannot be translated, because word order is
what a translator moves and a fragment cannot be moved; thirty-one of those became
`string.format` with one complete sentence each. And a string beginning with a
format specifier was invisible to `player_visible`, whose every test starts by
asking what the first character is — **48 live strings, including `"STAMINA · %d"`
on the HUD, were inside files batches one and two had already called covered.**

**Batch four took the content the world is made of** — 871 strings out of 51
shared modules — and found the thing worth finding: batches one and two had moved
four *identifiers* into the table, and 24 sites compared them to decide what the
game does. A night's theme was a table key in two modules, the value `WorldService`
compares to choose the dressing, and the word printed at the player, all at once;
a profession's id was built by lower-casing its signboard. Every one is correct
until somebody translates the string. `validate_localization.py` refuses a
`Strings.get` inside a comparison now.

**Batch five took the catalogs a player browses** — 1,435 strings across the item
catalogs, the residents and the six expedition definitions — and brought the
allowlist to its floor. `src/first/LoadingController.client.luau` is the one file
that stays: it runs from ReplicatedFirst to cover the wait for the shared root, and
requiring the table would mean `WaitForChild("LastLight")`, so the loading screen
would block on the very replication it exists to hide. Three more files moved to a
separate `NOT_TRANSLATED` list, because their text is read by whoever is holding the
console rather than by a player, and *not yet* and *never* are different claims —
a reader who cannot tell them apart cannot tell whether the wave is done.

**Owner-gated for M13:** every cohort, guardian consent, the measurement
window, moderation and scale health, the removal decisions, the language
decision, the final catalog and prices, and all five drills.

## Milestone 14 — Launch candidate

The deliverable list is mostly dashboard and art. The waves are the guards
that keep a launch candidate from drifting after it is declared one.

| Wave | Scope | Done when |
|---|---|---|
| A ✅ | **Schema freeze guard** (shipped #334). "Frozen save schema except blocker fixes" is a promise no one can keep by remembering. A marker in `Config` plus a validator that fails any bump while it is set, with an explicit override that has to be typed | Validator refuses a bump under freeze and says how to override deliberately |
| B ✅ | **The launch checklist, executable** (shipped #351). QA_RELEASE_PLAN.md's checklist was prose bullets, and **a bullet cannot be unticked** — it is completed by whoever says it is. It is 39 rows now with a four-word status vocabulary, and the design decision that matters is *when* the gate is allowed to fail: nearly every row is owner-gated, so a checklist enforced from the day it lands fails every build forever and gets switched off within a week. `Config.LaunchCandidate` is the switch, `nil` today exactly the way `Config.SaveSchemaFreeze` is. Declaring a candidate also requires the freeze, because a candidate whose schema still moves is the failure wave A exists to prevent | `npm run check` fails while a blocking item is unticked and a candidate is declared; with none declared it still fails on a `check` row naming a check that no longer exists, on a `done` or `n/a` row with no evidence, and on a changed row count |
| C ✅ | **Original-asset provenance** (shipped #352). The three validators proved an asset exists, decodes and is registered, and could not say where it came from. The manifests each answered in a different vocabulary and **audio answered once, at the top of the file, for all twenty-five tracks at the same time** — which is the form of evidence that stops being true one asset at a time, because the twenty-sixth track inherits a claim nobody made about it. Origin is a per-asset field from a three-word vocabulary now, `scripts/asset_provenance.py` holds the rules and all three validators call it, and [ASSET_PROVENANCE.md](ASSET_PROVENANCE.md) is the artifact the original-IP audit reads. The class that matters carries who published it and where it lives, and its 51 rows are held against the manifests in both directions | Every registered asset has provenance; an asset without it fails the check. The counts are pinned, an original cannot be reclassified as somebody else's work without failing, and neither the document's inventory nor the manifests may grow alone |
| D ✅ | **Release notes, known issues and dashboards, generated** (shipped #353). All three are normally written at the end of a project from memory, which is the one moment nobody has any. `npm run notes` builds them and `npm run check` fails when they are stale: [RELEASE_NOTES.md](RELEASE_NOTES.md) from the merge stream, [KNOWN_ISSUES.md](KNOWN_ISSUES.md) from the open threads the handoff already keeps inside the entry for the wave that found each one, [DASHBOARDS.md](DASHBOARDS.md) from the marked emitters in `src`. **The two guards matter more than the documents**: every pull request the handoff records has to exist in git, and every wave has to have a handoff entry. The second found three waves with no entry at all | The three documents build from the repository rather than being written from memory, and `npm run check` fails when any of them stops matching it |
| E ✅ | **The rollback build and flag matrix** (shipped #354). ROLLBACK.md's step two said "republish the last known-good place revision" and pointed at the PROJECT_STATUS header for the revision and the flag state that go together. **That header records `at `main` = `HEAD``, and `HEAD` is not a revision** — it is whatever the reader is standing on, which during an incident is the build that is on fire. It is a table now: a full commit id, the place version, the save schema, the build, and all 26 flags read out of that revision. The rule with teeth is the schema one — rolling back past a bump strands every profile the newer build wrote, so **a schema bump moves the target forward**, which is `Config.SaveSchemaFreeze` from the other side. `npm run verify:rollback` builds the named revision in a worktree and verifies its DataModel | The named revision builds and boots — verified by building it byte-for-byte and by playing the place it produces |

**Every buildable M14 wave has shipped** — A through E. What is left is the
deliverable list no code produces.

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

## What only the owner can do — the consolidated list

Written at the end of the session that finished M14 waves B through E and put
M13 wave D's guard in, so the next person does not have to reassemble it from
five sections, and **re-checked at the end of the session that finished wave D**.
**Nothing below is blocked on code, and now there is no code work left to be
blocked on**: with M13 wave D closed, every buildable wave in M11 through M14 has
shipped. This list is the whole of what remains.

**The launch checklist is the artifact this list now points at.**
[QA_RELEASE_PLAN.md](QA_RELEASE_PLAN.md)'s release checklist holds 40 rows, 39 of
them blocking. Seven are decided by this repository; **32 are open and owner-gated**,
and `scripts/validate_launch_checklist.py` will refuse a declared launch candidate
until every one of them is answered. That is the shortest complete statement of
what is left, and it is executable. What follows is the same list read out loud.

**People and populations (M12–M13).** Every cohort in the rollout: trusted
testers, the age-range allowlist and the guardian consent that makes it legal,
the larger flagged cohort, the creator and community test. The two rosters in
`Config.RolloutRoster` stay empty until those people exist. Then the
measurement window itself — every threshold in RELEASE_GATES.md is read across
a population, and the minimums are in its measurement contract.

**Play that a human has to do.** Daily full-path playtests; human completion
coverage of every quest (automated traversal proves reachability, not
comprehension); the device lab; a long-session soak on real hardware;
narrative continuity and content sensitivity review; production-like services
at representative concurrency. Two smaller ones the waves themselves turned
up: `profile_bytes` has never been soaked under a profile that is actually
being written, and the seed board's SOMEBODY IS STILL IN THE WOOD refusal
needs a second person in the server, as does every two-player case M11 waves C
and D left open.

**Decisions.** Which of the still-shut regions' `enabled` flags to flip, once
a live session has walked each end to end — Ironroot's flipped in #363 and
Mireglass's in #365, each with its walk, and the region assembly seam the first
walk forced into existence is what the remaining four open through. One content
decision the Fen's walk surfaced: the Lantern Witch's `sealed` ending is
unreachable by her own state machine (sparing never advances a phase), so
chapter III ends `bound` or `broken` and `spared_copies` is a decision no crew
can make. What to remove for
recurring confusion. **Which languages ship**, which is now a capacity decision
with a number on it rather than an archaeology project: `Strings.luau` holds
**2,621 source strings** and that is what one language costs. Translating them is
owner work; the source coverage that makes the question answerable is done. The
final catalog and prices. Every tuning decision BETA_TUNING.md has numbers and
knobs for; the numbers do not choose themselves.

**Commerce, all of it.** Creator Dashboard products and their IDs (until they
exist `Config.CommerceProductIds` is empty and `promptPurchase` correctly
refuses), price research, platform policy review, a live purchase with a real
receipt, and the on-call contact COMMERCE_SUPPORT.md's escalation table hands
to. Also whether Roblox's own text chat is enabled — a dashboard setting, and
the single largest social decision left, per SOCIAL_SAFETY_REVIEW.md.

**Art.** The gear art pass (82 of 90 craftable items draw a derived plan), the
four cosmetic outfits that read as a detailed torso block at card size, and
M14's launch assets: icon, thumbnails, trailer, description, age and content
disclosures.

**Reviews that read an artifact this repository now produces.** The privacy and
abuse review reads [SOCIAL_SAFETY_REVIEW.md](SOCIAL_SAFETY_REVIEW.md). The
original-IP audit reads [ASSET_PROVENANCE.md](ASSET_PROVENANCE.md) — 51 licensed
assets whose terms a human has to confirm, because no script can read a licence.
The dashboards are built from [DASHBOARDS.md](DASHBOARDS.md)'s 23 panels. Known
issues are generated into [KNOWN_ISSUES.md](KNOWN_ISSUES.md); patch notes in a
player's language are not, deliberately.

**Operations.** All five drills — moderation, support, incident, rollback,
communication. [ROLLBACK.md](ROLLBACK.md) holds the code half of the fourth,
including the exact revision and flag state to restore and a `npm run
verify:rollback` that builds it. Production places and universe links,
permissions, private servers, canary and scale tests, and the seven launch
journeys, which are ten rows of the checklist rather than one.

**Two declarations that are one act.** Setting `Config.LaunchCandidate` requires
`Config.SaveSchemaFreeze`, and a schema bump moves the rollback target forward.
Those three values are the moment this project stops being in development, and
nothing sets them but a person.

**One piece of infrastructure rather than a decision:** production refuses
flag overrides, so the first step of a rollback is a config change and a
publish. Making it genuinely live needs a server-side flag store.
