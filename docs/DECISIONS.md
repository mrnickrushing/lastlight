# Decision log

This log records durable decisions that affect multiple systems. Add a dated entry
when a decision changes; do not rewrite history silently.

## 2026-07-25 — Original cooperative survival-town game

**Decision:** Last Light is an original 1–8 player Roblox survival-town adventure,
not a themed extension of the existing obby and not a replica of another game.

**Reason:** The concept needs its own identity, world, progression, and sustainable
content architecture. Original IP also avoids trademark and copyright risk.

## 2026-07-25 — Blueprint before full implementation

**Decision:** Define the complete launch target, then build through playable
milestones beginning with the first ten minutes and Bramblewake vertical slice.

**Reason:** “Whole world complete” is a launch acceptance target. Attempting every
system and region in one unvalidated implementation pass would hide broken
fundamentals and make mobile, save, and performance failures expensive.

## 2026-07-25 — Persistent town plus modular expeditions

**Decision:** Emberhollow is persistent. Surface expeditions use deterministic
handcrafted modules with validated seeds, not fully procedural terrain.

**Reason:** The town creates emotional continuity, while modular expeditions add
variety without sacrificing authored landmarks, navigation, art quality, or
impossible-layout prevention.

## 2026-07-25 — Bramblewake manifests before active encounters

**Decision:** Start the vertical slice with a versioned, deterministic
12-module Bramblewake manifest and a known-good authored fallback. POIs and event
sockets are stable content IDs; active event state and rewards arrive in later
scoped increments.

**Reason:** Connectivity, streaming cells, content distribution, replay, and
mobile budgets must be trustworthy before combat, quests, rewards, and authored
events depend on generated layouts.

## 2026-07-25 — Optional shared Bramblewake events

**Decision:** The first four Bramblewake events use server-owned shared
interaction steps placed off the critical path. Timeout or kill-switch disable
can remove an event reward or shortcut, but cannot block extraction. Rewards use
manifest-derived idempotency keys and remain clearly labeled as unbanked until
persistent inventory settlement exists.

**Reason:** Dynamic events should encourage nearby players to cooperate without
turning optional content, disconnects, streaming, or remote retries into
impossible routes or duplicate value.

## 2026-07-26 — Durable pouch before full inventory

**Decision:** Event rewards enter a versioned unbanked profile pouch under
run-specific transaction IDs. Wayhome extraction atomically converts the pouch
to banked material totals and retains settlement tombstones. A failed or
read-only save never clears the server-session fallback.

**Reason:** Rewards need reconnect and retry safety before crafting or a larger
inventory interface depends on them. Separating unbanked and banked state also
preserves recoverable expedition failure without granting clients authority or
pretending the Milestone 4 persistence platform is complete.

## 2026-07-26 — Server-owned recoverable player rescue

**Decision:** Replace ordinary character death during implemented combat with a
30-second server-owned downed state, interruption-safe 2.5-second ally revive,
and bleedout-safe retreat. Keep the unbanked pouch intact until the partial-loss
and recovery-cache increment can settle it transactionally. Never sell revives.

**Evidence:** [Co-op Rescue HUD report](https://www.lazyweb.com/report/lazyweb/01fb79d9-741c-4685-8786-831be744e372/?source=create).

**Reason:** Enemy and profession work needs a deterministic failure contract
first. A non-modal rescue rail and automatic help signal keep touch controls and
the world readable, while server channel validation prevents self, range,
disconnect, and repeat-request exploits.

## 2026-07-31 — Persistent partial-pouch recovery before rarity loss

**Decision:** On an expedition safe retreat with at least two unbanked reward
transactions, keep the first deterministic half in the pouch and move the other
half into a schema-v10 owner-only recovery cache. The next Bramblewake entry
places a physical lost satchel near the safe arrival route. Recovering it returns
the original transactions to the unbanked pouch exactly once. A one-transaction
pouch is retained in full, and this vertical slice does not permanently delete
common materials before reward rarity is authored.

**Reason:** Failure needs a consequence and a return hook, but deleting value
before rarity, contract risk, and production persistence evidence exist would be
arbitrary. Locking a bounded half behind a reachable, persistent world object
creates tension without inventing rewards, enabling paid protection, or turning
a short first run into total loss.

## 2026-08-01 — Physical mastery paths with bounded role tradeoffs

**Decision:** At profession level 10, players explicitly choose one of three
persistent paths for that profession at a physical Emberhollow mastery altar.
Each path changes one narrow server-derived ability or rescue dimension. Path
selection is free, reversible in safe daylight, and never required for an
objective, traversal route, revive, or reward.

**Reason:** Mastery needs a meaningful long-term identity choice rather than a
finished XP bar. Physical altars preserve world presence and avoid another
permanent mobile overlay, while narrow bounded effects make paths readable and
balanceable without selling power or letting clients submit effect values.

## 2026-08-01 — Deterministic alternate normal-night incidents

**Decision:** Every normal-night theme owns two physical three-site incident
families. The family alternates every four-night theme cycle from the persisted
night number; reconnecting or restarting cannot reroll it. Timing, failure
pressure, authority, and profession-independent completion remain shared.

**Reason:** Four repeating incidents make the town defense predictable before
the wider content catalog exists. Alternate silhouettes and verbs double the
immediate authored variety while preserving the already-tested co-op window,
mobile interaction semantics, bounded consequence, and deterministic replay.

## 2026-07-26 — Shared stamina and readable attack resolution

**Decision:** Introduce one server-owned stamina resource for sprint and dodge
before profession kits. Rootling player attacks use a locked 0.9-second ground
zone and server resolution for area, cover, dodge protection, and damage.

**Evidence:** [Mobile Combat Stamina + Dodge report](https://www.lazyweb.com/report/lazyweb/4e46b6e2-7bef-4633-a7b5-ed7a872da2e8/?source=create).

**Reason:** Future attacks and profession abilities need one tested timing and
resource boundary. Text plus a world shape makes danger readable on mobile and
without color/audio, while server-owned direction, cooldown, protection, and
damage prevent client speed or invulnerability claims.

## 2026-07-25 — One Active Trail onboarding HUD

**Decision:** Implement the first session with one phase capsule, one active
objective card, and one input-aware contextual action. Keep the expanded Mission
Stack as a future help state, not the default overlay. During night, add lantern
health and threat urgency without replacing the hierarchy.

**Evidence:** [Focused First-Ten-Minutes HUD report](https://www.lazyweb.com/report/lazyweb/a34ce67d-041e-434b-acb6-0afd4ccf7ef4/?source=create).

**Reason:** The onboarding must teach sequence while leaving the detailed forest,
Mara, the current interactable, threats, and Roblox movement zones visible on a
phone.

## 2026-07-25 — Context-sensitive mobile HUD

**Decision:** Default to a world-dominant context-sensitive survival HUD. Offer a
compact explicit HUD as an accessibility/low-effects preset. Use living-world HUD
effects only for Blackouts and bosses.

**Evidence:** [Hosted design report](https://www.lazyweb.com/report/lazyweb/a5059523-0d43-4386-b0f5-bda12ca3d7ea/?source=create).

**Reason:** Mobile players need immediate phase, squad, and action clarity without
covering the detailed world or Roblox movement zones.

## 2026-07-25 — Server authority

**Decision:** The server owns combat, rewards, inventory, crafting, building,
progression, teleports, saves, trading, commerce, and admin actions.

**Reason:** These states affect value, fairness, persistence, and exploit risk.
Clients express intent and render authoritative results.

## 2026-07-25 — Ethical monetization

**Decision:** Sell cosmetics, expression, saved appearance layouts, and optional
private social controls. Do not sell power, random rewards, revives, energy,
loss protection, or relief from manufactured friction.

**Reason:** Long-term trust and fair cooperative play are product requirements,
not post-launch policy.

## 2026-07-25 — Streaming from foundation

**Decision:** Enable instance streaming, build a bounded playable arrival area,
and prohibit loaders that wait for the entire world.

**Reason:** The world target is large and mobile memory/join time are critical.

## 2026-07-25 — Single-place slice, multi-place launch option

**Decision:** Build the vertical slice in one streamed place. Profile before
separating the universe into town, expedition, and finale places.

**Reason:** One place reduces early teleport/data complexity. The launch topology
may use separate places when measured memory, production, or isolation benefits
justify the operational cost.

## 2026-07-25 — Free profession switching

**Decision:** Players can unlock every profession and switch freely in town.

**Reason:** Cooperative roles should encourage experimentation without permanent
class regret or monetized respec pressure.

## 2026-07-26 — Profession abilities remain optional team utility

**Decision:** Implement Scout, Warden, Engineer, and Medic as free, persistent
safe-town selections with one server-authoritative utility ability each. Preserve
baseline combat, gathering, construction, revive, and completion paths for every
player, regardless of profession.

**Evidence:** [Profession Selector + Ability HUD report](https://www.lazyweb.com/report/lazyweb/73595230-6584-431c-8d84-c7eb06fdeaa5/?source=create).

**Reason:** The vertical slice needs distinct cooperative identities without
class locks, paid power, or impossible solo objectives. A single readable
cooldown action proves the authority, save, input, HUD, and balance seams before
mastery trees or specializations multiply complexity.

## 2026-07-26 — One-at-a-time Bramblewake mechanic roster

**Decision:** Author all six standard Bramblewake enemies in the first-night
schedule, but keep only one enemy active at a time. Give every enemy a distinct
server-owned counter instead of multiplying simultaneous bodies. Use the stable
catalog ID `enemy_rootling` in runtime and generic enemy-ID analytics.

**Evidence:** [Bramblewake Mobile Combat Callouts report](https://www.lazyweb.com/report/lazyweb/094ebe85-c65a-4a8a-908f-b1b209ecc935/?source=create).

**Reason:** The first defense must teach readable mechanics and remain
profession-independent, solo-passable, and performant on baseline phones. A
bounded queue allows the full authored roster without turning the tutorial into
an unreadable swarm.

**First-night adaptation:** Hollow Crow steals a temporary exposed First Lantern
spark rather than durable inventory. Physical loose-bundle theft remains a later
expedition integration; banked value is never deleted by this defense.

## 2026-07-26 — Shared Old Growth with carried-fire shield breaks

**Decision:** Implement one server-run `elite_old_growth` encounter in the
already-authored Old Growth Approach. It has three exposed-heart phases separated
by two 15-second lantern-fire shield breaks. One player carries fire at a time,
but every player who enters the live arena becomes a participant. Normal strikes
remain sufficient; Scout slows telegraphs, Warden mitigates damage, Medic heals,
and Engineer remains lantern-specific.

**Reward and failure:** Completion grants each participant three unbanked Amber
Sap through a stable per-run, per-manifest, per-player transaction. The reward
uses the existing durable pouch and Wayhome settlement path. Routine downs,
retreat, and disconnect do not reset shared server-run health; no profession,
paid item, or paid revive is required.

**Evidence:** [Old Growth Elite Mobile HUD report](https://www.lazyweb.com/report/lazyweb/51156fc2-18a7-4cf0-be1b-3de54ccf33b3/?source=create).

**Reason:** The first elite should prove phase state, cooperative world
interaction, recoverable failure, shared idempotent rewards, and contextual
mobile presentation without adding permanent HUD clutter or multiplying active
NPCs. The single carrier makes the objective readable and bounds replicated
effects on baseline phones.

## 2026-07-26 — Warden Stag mechanics before Blackout integration

**Decision:** Implement `boss_warden_stag` as a server-run three-phase encounter
in a streamed Warden's Seal annex unlocked by completing Old Growth. Each phase
cleanses two, three, then four distinct living roots before the shared memory
heart is exposed. Breaking either of two antlers is an explicit harmful shortcut
that exposes the current phase and records preserved, scarred, or harmed outcome
state. The Bramblewake Blackout schedule and permanent chapter save consume this
encounter later rather than being simulated now.

**Reward and failure:** Every active-arena participant receives one stable
five-Amber-Sap unbanked transaction. Shared health, phase, root, antler, and
participant state survive routine downs, retreat, and same-server disconnect;
no profession, paid item, paid revive, or client-reported damage is required or
trusted.

**Evidence:** [Warden Stag Mobile Boss Layer report](https://www.lazyweb.com/report/lazyweb/d5a79e5a-8f10-46e0-b0ed-8e6e09b2dccb/?source=create).

**Reason:** The roadmap lists the boss and Blackout as separate Milestone 3
deliverables. Isolating the authored boss first makes phase, choice, authority,
recovery, reward, mobile HUD, and performance testable without falsely claiming
the nine-minute chapter flow or permanent story consequence is finished.

## 2026-07-26 — Bramblewake Blackout preview and immutable chapter result

**Decision:** In the vertical slice, automatically start the first unresolved
Bramblewake Blackout when a player enters the expedition after First Light. A
nine-minute target clock becomes recoverable overtime instead of erasing
progress. Players carry rootfire through three ordered relays, with every lit
relay becoming the next fire source, then complete Old Growth and the Warden
Stag. Present participants vote between restoring farmland, wild regrowth, and a
shared agroforest; a unique plurality wins and ties resolve to the shared
agroforest. The server persists the Warden outcome and land decision together
through one immutable, idempotent save-schema-v4 transaction per player.

**Scope:** This preview proves the complete chapter-one critical path without
claiming the production seven-night scheduler. Recurring cadence, visible town
and expedition consequences, ally traversal behavior, cinematic presentation,
and final art/audio/VFX remain open.

**Evidence:** [Bramblewake Mobile Blackout Event Layer report](https://www.lazyweb.com/report/lazyweb/558b7278-8455-4639-bf62-bd4ebb97a034/?source=create).

**Reason:** A recoverable clock and chained fire sources make the authored route
challenging without creating an impossible run after one miss or a long
backtrack. Present-party voting is bounded and deterministic, while committing
the boss result and land decision atomically prevents contradictory story saves.

## 2026-07-25 — Recoverable failure

**Decision:** Routine defeat damages temporary state and unbanked value but never
deletes the town, paid items, completed story knowledge, or permanently extracted
residents.

**Reason:** Failure should create stories and recovery goals, not churn or paid
rescue pressure.

## 2026-07-25 — Reproducible external Roblox toolchain

**Decision:** Use Rokit with exact Rojo, StyLua, Selene, Lune, and Luau LSP pins.
Build the runtime and a separate Studio integration-test place from filesystem
source. The project mappings and Luau remain authoritative.

**Reason:** Every developer and CI must validate the same source with the same
tools. Pure Luau tests provide fast feedback, while Studio tests remain necessary
for the real DataModel, streaming, physics, replication, and engine behavior.

## 2026-07-26 — Commit validated Studio places for Windows testing

**Decision:** After every completed phase, regenerate and commit
`build/LastLight.rbxlx` and `build/LastLightTest.rbxlx` from the exact validated
source revision. Never hand-edit the generated places.

**Reason:** The primary Windows tester downloads GitHub ZIP snapshots and needs a
playable Studio file without installing Node, Rokit, Rojo, or the rest of the
command-line toolchain. Keeping both small generated places in GitHub makes each
merged phase directly testable while source, project mappings, and automated
build verification prevent binary drift.

## 2026-07-25 — Fail-closed runtime environments

**Decision:** Studio resolves to local/test, unregistered published places resolve
to staging, and production requires an explicitly registered place ID.

**Reason:** A new or copied place must not silently gain production data, commerce,
or feature behavior. Promoting a place is an intentional reviewed configuration
change.

## 2026-07-26 — Normal Night decoupled from the Blackout trigger

**Decision:** The repeating town day/dusk/night cycle counts nights and
telegraphs the seventh-night threshold (`blackoutDue`), but does not gate,
block, or auto-start the Bramblewake Blackout. Manual Bramblewake entry after
First Light remains the way to reach the Blackout, exactly as the preview
decision above already established.

**Reason:** Coupling the two now would remove the tested fast path Windows and
device testers rely on to reach the complete chapter-one flow, in exchange for
a "seventh night" gate this increment has no Studio/device evidence for yet.
Building the counting-and-defense half of the seven-night structure first, and
wiring it to the Blackout only once the cycle itself is validated, keeps each
change reviewable and reversible on its own.

## 2026-07-26 — Night count persists per player, not as a new town save

**Decision:** The town's night count is stored as `town.nightNumber` on each
player's existing save-schema-v5 profile — the same DataStore/profile
mechanism already used for `story.chapterOne`, inventory, and profession —
rather than as a new, independent town-wide save. When a server starts, the
live cycle resumes from the highest `nightNumber` among the profiles of
players present, via `SaveSchema.withNightNumber`'s monotonic (never
decreasing) update. Every connected player's profile is updated whenever a
night completes, regardless of who was present when it started.

**Reason:** No town-wide save (save-slot key, locking, versioning) exists
anywhere in this codebase yet — every server rebuilds the same generic
Emberhollow from scratch, and only player profiles persist. Inventing a
one-off town DataStore now would almost certainly need migrating once
Milestone 4's real persistent-town platform lands with its own save-slot
design. Treating night count as a personal record that a party's most
experienced returning member restores keeps this consistent with every other
piece of per-player state already shipped (chapter one, inventory,
profession), and costs nothing to migrate later: a single field can move from
a player profile into a future town profile without changing its meaning.

## 2026-07-26 — First crafting recipes are a fixed-output bench, not a picker UI

**Decision:** Each crafting bench interactable is bound to exactly one
recipe ID, baked into its `ProximityPrompt`'s `Payload` attribute at world
build time, and the server resolves and validates that recipe entirely from
its own catalog. The client sends the same generic `interact` action every
other world object already uses; it never sends a recipe ID, a material
amount, or an item ID.

**Reason:** The tutorial already uses exactly this one-object-one-outcome
pattern for tool selection (`ToolAxe`/`ToolHammer`/`ToolTorch`, each its own
pedestal). Reusing it for crafting avoids inventing a new remote payload
shape, a client-side recipe list, or a picker UI before the game has more
than two recipes to choose between — and keeps every trust boundary the same
one already covered by the existing interaction-validation tests. A real
recipe-browsing UI remains open work once the catalog is large enough to
need one.

## 2026-07-26 — Crafted gear starts as consumable buffs, not equipment

**Decision:** Using a crafted item consumes exactly one unit and applies a
short one-time effect (a damage-reduction shield for the Amber Charm, an
instant stamina restore for the Meadow Satchel). There is no equip/unequip
state, no permanent passive stat change, and no new gear visuals — an item
is either owned or spent.

**Reason:** No equipment/loadout system exists anywhere in this codebase
yet, and Milestone 6 explicitly owns "equipment traits, repair, loadouts"
as its own scope. A consumable effect reuses patterns that already exist
(`StatusEffectState`'s duration+multiplier shape for drowsy/rooted,
`CombatState`'s advance-then-mutate shape for sprint/dodge) instead of
inventing a new stat-modifier pipeline, and it gives the crafting economy
a second, genuine sink (spending an item, not just banking materials into
one) without committing to a full equipment system's design before that
system's own milestone.

## 2026-07-26 — An item-granted shield stacks with Warden's own mitigation

**Decision:** `PlayerCombatService.mitigateShieldedDamage` is checked
independently of `ProfessionService.mitigateIncomingDamage` at every
damage call site, applied after the profession check, so the two
reductions compose instead of one replacing the other.

**Reason:** Folding the Amber Charm's effect into `ProfessionState`'s own
`mitigatesDamage` tracking would couple a universally craftable item to
state that's designed around a single profession's ability, and would make
a Warden's guard and a charm mutually exclusive for no reason. Keeping them
as two independent checks costs one extra line at each of the three
existing damage call sites and keeps a charm equally useful regardless of
profession.

## 2026-07-26 — First quests are silent milestones, not a quest board

**Follow-on:** The 2026-07-31 resident-guidance decision below supersedes the
"no quest giver" presentation choice. Automatic tracking and claiming remain
unchanged; Tomas, Pip, and Ena now explain the same server-owned milestones.

**Decision:** Quests have no quest giver, no accept step, and no browsing
UI. The server opportunistically checks every not-yet-claimed quest's
objective after any action that could satisfy it (a night completing, a
craft succeeding, a settlement completing) and auto-claims anything newly
met, granting its reward immediately. Only the claimed set persists;
progress is always recomputed live from existing profile fields
(`town.nightNumber`, `gear`, `inventory.settlementOrder`), never stored
separately.

**Reason:** No NPC/dialogue/quest-board UI exists anywhere in this
codebase yet, and every objective this increment needs is already
derivable from state the game tracks for other reasons. Building an
accept/track UI before there's anywhere to put it, or a new progress-
counter mechanism when the existing counters already say everything
needed, would be scope invented for its own sake. Reading progress live
rather than storing it also means a quest can never be permanently lost to
a later regression (e.g. crafting an item and then using it up) — once
satisfied at any check, it's claimed for good.

## 2026-07-31 — Residents surface quests without owning quest state

**Decision:** Tomas, Pip, and Ena now act as physical quest contacts for the
three automatic milestones. Talking to them reads the same authoritative quest
snapshot already published to the client. It never accepts, resets, advances,
or claims a quest. Once the linked quest is claimed, each resident switches to
story dialogue shaped by the player's Greenward decision or Warden outcome.

**Reason:** The automatic claim model remains safer and prevents missed rewards,
while named residents give objectives a human source and make the town react to
the story. Reusing proximity prompts and the existing toast surface adds that
context without introducing a second quest-state machine or another HUD panel.

## 2026-07-31 — Newest night wins town damage; same-day repairs win ties

**Decision:** Persistent town condition remains in each player's profile, like
the existing night count and chapter consequence. One shared server town merges
those records by preferring the highest recorded night. When records describe
the same night, the higher integrity wins because it represents later repair
work. Accepted repairs are copied to every connected writable profile.

**Reason:** Last Light does not yet own a separate global town DataStore. A
monotonic night-first merge prevents an old pristine save from erasing recent
damage, while the same-night integrity tie-break prevents a stale damaged save
from undoing work the current group already completed. It preserves one coherent
physical town without pretending per-player saves are global state.

## 2026-08-01 — Profession identity stays physical; Engineer structure reuses Emergency Patch

**Decision:** Give every current profession a short, color-independent physical
ability motif in the world. Extend a successful Engineer Emergency Patch with
one non-stacking Rootline Brace at the server-owned First Lantern. The brace
lasts 12 seconds, absorbs at most 14 lantern pressure, and is consumed by every
current lantern-damage path through one pure state contract.

**Reason:** The game needs stronger role readability without another permanent
HUD rail or mobile button. Reusing Emergency Patch preserves input parity and
all existing server checks, while a visible, bounded structure finally expresses
the Engineer's build/control identity without creating client-selected placement,
path obstruction, indefinite stacking, or paid combat power.

## 2026-08-01 — Whole-party night recovery spends shared light once

**Decision:** During a normal town night, if every connected, tutorial-ready
town player is downed, the Night Watch may rally that party once for the active
night. The server spends 12 First Lantern strength, revives eligible players at
50 health, and grants a five-second ward. The recovery is unavailable below 30
lantern strength and never includes expedition players.

**Reason:** Cooperative night defense needs one dramatic recovery beat before a
group collapse turns into simultaneous bleedout timers, but it must preserve
stakes. A single server-owned use, a visible shared-resource cost, and no paid
relief make the comeback legible and bounded. Tying it to the frozen active-night
number prevents a veteran joining mid-wave from resetting or consuming the wrong
night's allowance.

## 2026-08-01 — Bramblewake is the production-quality world standard

**Decision:** Finish Bramblewake as the polished vertical slice before producing
the remaining regions. Its authored mesh quality, gameplay scale, palette,
lighting hierarchy, landmark readability, interaction language, streaming
behavior, and phone performance budgets become the source of truth for later
world production. Later regions reuse the standards and asset library, not
Bramblewake's literal layout or region-specific silhouette.

**Reason:** One complete world exposes the real interaction between art quality,
navigation, loading, memory, combat readability, and mobile controls. Spreading
placeholder-quality production across seven regions would multiply rework and
leave no proven bar. A finished vertical slice turns the remaining regions into
a controlled content pipeline while preserving each region's own hazards,
landmarks, and palette accents.

## 2026-08-02 — The Pollen Wisp becomes the Hollow Zombie on an original mesh

**Decision:** Retire `enemy_pollen_wisp` and its Creator Store shell
`mesh_creator_blossom_spirit_a`. The third slot in the Bramblewake roster is now
`enemy_zombie`, the Hollow Zombie, whose visual is `mesh_zombie_a` — an original
asset generated from the style formula in VISUAL_QUALITY_STANDARD.md and
normalized through the existing Blender pipeline. The encounter keeps its
mechanics exactly: same health, speed, ranges, cooldown, circle telegraph, and
the `drowsy` status. Only the fiction changes, from an inhaled sleep cloud to a
rot miasma. The creature also stops hovering and walks.

**Reason:** Roblox moderated the Creator Store model on 2026-08-02
(`wasModerated: true`, 403 to a logged-in Studio user), so the enemy silently
fell back to placeholder geometry in a shipped-quality slice. Re-sourcing from
the store would carry the same risk again, and the store search returned no
model at this quality bar: the one first-party zombie draws its detail from
`CharacterMesh` objects that only render with a `Humanoid`, which
`MeshTemplateLoader` strips by design. An original generated asset cannot be
revoked by a third party, and the standard already prefers original sources.
Preserving the mechanics keeps the roster's readability contract, the 1,000-seed
invariants, and the drowsy balance tests intact, so this is a re-skin of an
authored encounter rather than a new one.

**Stable-ID note:** `enemy_pollen_wisp` is renamed rather than repurposed. It
has never shipped in save data — enemy IDs live only in the night schedules and
telemetry, not in the save schema — so no migration is required.

## 2026-08-02 — A session starts in a staging yard, not on the arrival road

**Decision:** Players now spawn in the Emberhollow departure yard: a lantern-lit
courtyard with a character hut, a notice board and stall, and a raised departure
platform at its south edge facing the gate. Standing on that platform is what
puts a player in the party. Any player on it may choose a party size, which
starts one bounded ten-second countdown; when it reaches zero, everyone standing
on the platform, up to the chosen size, is moved together to the arrival clearing
where the tutorial begins and Mara is freed. Players not on the platform are not
taken. The whole feature sits behind `lobby_departure_enabled`.

**Reason:** The game needed a place to gather with friends and leave together
rather than each player materializing alone on the arrival road. Building it as
an in-world area inside the existing place, rather than a separate lobby place
with a teleport, avoids teleport payloads, reconnect tokens, duplicate-reward
handling, and a second published place — none of which the project needs to take
on to get the moment it actually wanted. It is also reversible: the flag turns
the yard back into ordinary scenery.

**Authority:** All of the launch rules live in the pure `LobbyDeparture` module
and are re-checked server-side on every request. Occupancy is measured from the
server's own view of character positions, so a client cannot claim to be on the
platform, and a forged or spammed party size cannot start, resize, or rush a
countdown. An emptied platform cancels rather than launching nobody, and the
departure state is consumed on launch so a duplicated remote cannot send a party
twice. A departed player is kept in the game across respawns instead of being
returned to the yard.

**Deferred:** The character hut currently presents the four professions as
readable stands; profession selection itself still happens at the existing town
altars, and no cosmetic purchases exist yet. Selling professions outright, which
has been discussed, would contradict the paid-power rule in AGENTS.md and needs
its own decision before any implementation.

## 2026-08-02 — Tapping the world is the interaction model

**Decision:** Objects are their own controls. Tapping a gather node, a tool
display, the construction plot, the First Lantern, the memory reliquary, or a
creature performs that action. The FIND and STRIKE buttons are gone; run,
dodge, and ability keep buttons because they have no target to tap. Every
click routes through the same rate limiter and the same server validation the
keyboard path uses, so a click only says *which* object the player meant.

**Reason:** Walking into range and then hunting the right HUD button made every
interaction two steps, and on a phone those buttons were consuming the screen
space the game has least of. Tapping is also self-teaching in a way a button
labelled FIND is not.

**Consequence to watch:** a ClickDetector only receives clicks if its part
answers raycasts. Several interaction anchors are deliberately invisible and
non-colliding, and `part()` clears `CanQuery` for anything non-colliding, so
they were unclickable until `_registerInteraction` began forcing it back on.
Any new interaction anchor must stay queryable or it will silently do nothing.

## 2026-08-02 — Gathering and building take time and show it

**Decision:** Gather and build are timed server-owned actions rather than
instant grants. The character swings its tool, a progress bar runs, and the
reward lands when `ActionProgress` says the clock is up. One action at a time
per player, completion checked server-side, cancellation grants nothing, and
the state is consumed on completion.

**Reason:** An instant grant on button-press gave the player nothing to feel and
made the tool choice decorative. The timer is deliberately short — this is
confirmation that something happened, not a tax on the player's time.

**Note:** the timed gate sits after the resource and stage guards but before
`_advance`, which mutates. `TutorialFlow.advance` is pure, so validity is
checked without committing; otherwise an invalid interaction would make the
player swing an axe and only then be told it was the wrong objective.

## 2026-08-02 — A session starts a fresh run

**Decision:** `tutorial_persistence` is off. A player who leaves and rejoins
begins at the lodge rather than resuming mid-run. The stage is still written to
the profile, so turning the flag on restores resuming.

**Reason:** Rejoining to find yourself halfway through a night you had already
left, holding a tool you did not remember picking, reads as the game having
lost track rather than as progress. Durable progress — banked materials,
professions, town condition, chapter outcome — is separate from tutorial stage
and is unaffected.

## 2026-08-02 — Two placement mistakes worth recognising on sight

**Decision:** Record these because each has now caused multiple bugs that all
presented as "the thing does not appear".

1. **Procedural content wired as a mesh's `fallbackInstance`.**
   `hideProceduralPlaceholder` blanks *every* descendant of that instance —
   transparency to 1 and every `Light` disabled — the moment the authored mesh
   loads. This hid the Dawn Gate steps, wiped the tool yard displays, and
   turned the First Lantern off when lit. A fallback must contain only the
   geometry the mesh replaces, never real content that shares the model.

2. **Ground-level geometry under a road.** Roads are thin and sit around
   y 0.24–0.60. Anything authored at ground level in the same footprint is
   drawn over and becomes both invisible and unclickable. This buried the
   arrival roads once and the barricade construction plot once.

**Reason:** Both failure modes are silent — no error, no log line, and the
automated checks pass. Knowing the shape of them turns a long hunt into a
first guess.

## 2026-08-02 — Each departing party gets its own reserved server

**Decision:** Reverses the "in-world staging, no teleport" decision taken
earlier the same day. A party leaving the departure platform is now teleported
to a reserved server for the *same* place, carrying a `RunHandoff` payload that
tells the arriving server it is a run rather than a lobby. Behind
`reserved_run_servers_enabled`; when the flag is off, when the place is
unpublished, or in Studio, the party moves within the current server exactly as
before.

**Reason:** The earlier decision was right about cost and wrong about
consequence. One shared world meant a party of three and a party of five who
both departed landed in the same Emberhollow together, which makes the lodge a
lie: it presents a choice of party size and then ignores it. Reserving a server
for the same place avoids the thing that made the multi-place option expensive
— there is no second place to publish, version, or keep in sync — while giving
each run the isolation the staging platform implies.

**Authority and failure:** The payload is deliberately inert. It can say "this
is a run" and carries the party size; it cannot say anything about rewards,
stage, or progression, so a forged one changes only which room a player wakes
up in. Anything unrecognised resolves to a lobby, which is the safe direction:
a server wrongly believing it is a run strands players in a world with no way
to start one, while the reverse merely shows a staging room they can leave
again. Reserving and teleporting are separate calls and either can fail; both
are wrapped, and either failure returns the whole party to the lodge with the
departure cancelled and nothing consumed.

**Testing limit worth recording:** reserved-server teleports cannot be
exercised in Studio at all, and `game.PlaceId` is 0 on an unpublished place.
The rules therefore live in the pure `RunHandoff` module where they can be
tested without a live game, and the service falls back rather than failing when
reserving is impossible. The teleport itself can only be verified in the
published game with real clients.

## 2026-08-02 — Admin commands exist for testing, by user ID, behind a flag

**Decision:** A small chat command set — `/night`, `/give`, `/heal`, `/phase`,
`/where` — available to an explicit roster of Roblox user IDs, behind
`admin_commands_enabled`. Membership is by numeric user ID, never by username,
because a display name can change and a numeric ID cannot be chosen by the
player holding it. Every argument is bounded in `AdminRoster` rather than at
the handler, so a command cannot set night nine thousand.

**Reason:** Testing the town needs states the game only reaches after several
sessions. Residents, for example, arrive at town tier 1, which is four nights
in — so seeing them at all previously meant either playing four nights or
changing the authored gate. `/night 4` reaches the same state the game reaches
on its own, without touching the design.

**Bounds on what this may become:** these commands only call the same service
methods the game already calls itself, so an admin cannot put the world into a
state the world cannot otherwise be in. Nothing here grants currency, unlocks
purchases, or edits another player's profile. Every accepted command is logged
with the admin's user ID and the value applied, which is the audit trail
Milestone 4 requires before admin tooling counts as done. Refusals are silent
to everyone not on the roster, so ordinary chat never reveals that the roster
exists.

**Roster:** the owner (1213625298) and zacksigma472 (8772161919).


## Named creatures use original assets, not the Creator Store

**Decision:** Bramblewake's boss (Warden Stag) and elite (Old Growth) are
generated Last Light assets. Both previously borrowed Creator Store models —
a wood ibex stretched to `(1.08, 1.14, 0.94)` at three times scale, and an
old-growth model stretched to `(0.94, 1.08, 0.9)`. Neither needs a stretch
profile now, because each was generated to the silhouette the fight already
assumed.

**Reason:** a third-party model was moderated mid-project earlier in
development and silently fell back to placeholder geometry. A prop failing
that way costs a crate. A named creature failing that way costs the encounter
its identity at the moment the encounter is the point. Props may stay borrowed;
anything the game names should not be.

**The rule this produced:** a creature's mesh must be generated around the
parts the fight is read from, never over them.

  * The stag was generated deliberately *without* antlers — only broken stubs
    at the crown — because the fight breaks its antlers one at a time and they
    have to remain authored parts standing above the mesh.
  * The elite was generated with a hollow chest cavity, because the amber
    heart is the weak point and is relit on every state change; it needs
    somewhere to sit inside the creature rather than on top of it.

Getting this wrong is invisible in Studio and total in play: the mesh looks
correct standing still and the fight becomes unreadable the moment it starts.

**Facing is measured, not guessed.** A mesh's forward axis is found by
comparing the two halves of its long axis in Blender, then mapped through the
glTF convention — Blender `-Y` becomes Roblox `+Z`. Both builders put the
creature's front at `-Z`, because `CFrame.lookAt` aims `-Z` at the target, so
both profiles carry `yaw = math.rad(180)`. A backwards boss is a plausible
mistake that only a player standing in the arena would ever catch.

## 2026-08-04 — A session can connect to Studio, on the machine Studio runs on

**Decision:** Studio's built-in MCP server is the supported way for an AI
session to see this game running. Setup lives in
[STUDIO_MCP_SETUP.md](STUDIO_MCP_SETUP.md), and Linux hosts running Studio under
Wine use `scripts/studio-mcp-wrapper.sh`.

**Reason:** Every open exit gate in this project's runbooks is blocked on
somebody looking at Studio, and that has been the binding constraint for
months while source work ran ahead of evidence. A connected session closes the
DataModel and visual half of those gates directly -- Output assertions, asset
placement and scale, per-building damage behaviour, prompt reachability -- which
is precisely the class of failure this project keeps shipping (buried roads,
sideways cylinders, a beacon hidden inside its own fallback).

**Bounds on what this may claim:** the device and human half does not move. A
baseline-phone pass, the ten-tester gate, DataStore behaviour across servers,
real multiplayer, and whether the slice is fun all still require a person. A
session that marks those closed is asserting, not evidencing.

**Why not a third-party bridge:** the paid tooling in this space asks for a
daemon, unsigned binaries, and OpenCloud credentials, and its own launch thread
carried an account-compromise report. Studio's first-party server is local-only,
needs no credentials, and ships in the editor.

**Platform note:** the earlier "Windows testing" decision above still stands as
written for build artifacts -- committed places remain how a tester opens the
game without the toolchain. What changed is that the tester is no longer assumed
to be on Windows, so the runbooks' journeys are named for Studio rather than an
operating system.

## 2026-08-04 — Arrival vignettes are local, skippable camera moments

**Decision:** When a threat arrives — the night (with its theme name as the
title card), the Blackout, an awakening Old Growth or Warden Stag — the client
plays a short letterboxed camera push toward the threat with an original title
card, then returns control. The vignette is presentation only: camera-local,
never replicated, never blocking the server or another player; any input skips
it instantly; it never plays while downed, in compact HUD mode, or on a
reconnect into an already-active state; and it restores the follow camera
exactly. Focus points are resolved from the live workspace at trigger time, so
a missing or streamed-out landmark skips the shot rather than aiming at
nothing.

**Reason:** The owner asked for the arrival-cinematic beat popular survival
games use well (99 Nights in the Forest's cultist arrival was the named
reference). The technique is genre vocabulary; the content here is entirely
Last Light's — its own threats, palette, and theme names. The camera rules in
ART_AUDIO_DIRECTION (no control theft during active danger, skippable
cinematics, reduced-motion respect) bound the implementation, which is why it
is a three-second local camera tween rather than a server-owned cutscene
system.

## 2026-08-04 — Chapter one is told in the world, and the archive is the hook

**Decision:** Ten memory fragments carry Bramblewake's story, resting on
scenery that already exists — the four authored story vignettes and the four
points of interest — in three acts: what the forest kept (the evacuation), the
keeper's trail (what Orin Vale was actually doing), and your part in it (why
the eighth seal is yours). The last two are gated behind chapter one, and the
final fragment sits at the Wayhome Gate, so a player learns what Chapter II is
on the walk home from finishing Chapter I. The Field Book doubles as the
Memory Archive: recovered fragments read back in authored order, unrecovered
ones are named by the place that holds them.

**Reason:** The world bible's premise — light is memory, the Long Night is the
remainder of what a machine took because nobody could carry it — had never
reached the player, and resolving chapter one produced one line and silence.
That is the retention hole: the game had nothing to say about what comes next.
Fragments were chosen over cutscenes or a quest chain because the scenes are
already built and standing there mute, and because a collection whose missing
entries are *named* creates the honest version of "one more run" — curiosity
about a story, not a timer. This is deliberately the ethical retention model
MONETIZATION_LIVEOPS_ANALYTICS already commits to (return for the world and
the mystery, never for a streak), and it is also the commercial one: engaged
players are the precondition for any cosmetic catalog, and archive completion
opens legitimate cosmetic surface (keeper's-trail arrival effects, memory
lantern shells) that sells expression rather than power.

**Bounds:** Fragment recovery is a server transaction on the profile keyed by
fragment ID, idempotent, with unknown IDs dropped at normalization. The client
sends an interaction ID and nothing else. Nothing here grants materials,
power, or currency — a fragment is worth reading, not worth farming.

## SFX use engine-bundled rbxasset sounds (2026-08-04)

The first sound-effects layer uses only `rbxasset://sounds/...` files that
ship inside the Roblox client, not Creator Store audio. Uploaded/marketplace
audio has exactly the failure modes that already bit the authored meshes —
permissions, moderation, CDN fetches that throttle at boot — and a sound that
sometimes doesn't play is worse than a modest palette. Distinct cues reuse a
file at different playback speeds. Decision rule going forward: gameplay
feedback cues stay engine-bundled; licensed audio is reserved for music,
where MusicCatalog already handles missing assets gracefully.
