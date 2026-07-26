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
