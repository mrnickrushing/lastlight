# Rollback — the kill switches and what restoring looks like

## Purpose

Milestone 13's exit gate asks that a rollback drill pass. A drill needs
something to drill: the list of what can be turned off, what turning each one
off leaves behind, and the exact build and flag state a rollback restores.
This is that list, and `KillSwitches.spec` holds it against `Config` in both
directions so neither can grow alone.

The rollback *decision* is the owner's and the drill is a human exercise. What
is written here is the half a repository can own.

## What a kill switch has to be

**A switch you have to restart every server to use is not a switch.** The only
moment a kill switch exists for is an incident, and during an incident the
servers are already running with players in them. So a flag that governs
something has to be read at the point that thing would happen, not kept from
construction — and where a flag cannot manage that, its row says so rather than
implying otherwise.

This project has paid for the other shape twice. The soak instrumentation
(#344) read its switch once at boot, and a Play session starts from a fresh
DataModel that never carries an attribute set in Edit mode — so the wiring ran
on every server and could not be turned on from the only place anybody drove
it, with nothing failing. And `TownNightService` cached
`town_night_cycle_enabled` at construction until this wave, which meant the
town cycle's off switch needed a full server restart to take effect.

**Off means "stop starting new ones", not "delete what is running".** A night
that vanishes underneath the people fighting it is a worse outage than the one
being rolled back. Every switch below stops the next instance and leaves the
one in progress to finish.

## The switches

Every flag in `Config.FeatureFlags` is here, because a flag that is not a kill
switch is a flag nobody has decided about.

| System | Flag | What turning it off leaves | Scope |
|---|---|---|---|
| Bounded join | `bounded_join` | nothing: no code reads it | none |
| Onboarding | `first_ten_minutes` | nothing: no code reads it | none |
| Input actions | `input_action_system` | nothing: no code reads it | none |
| Combat mobility | `combat_mobility_enabled` | no dodge or sprint; walking and striking remain | live |
| Profession kits | `profession_kits_enabled` | no kit, no ability; a survivor with a tool | live |
| Player survival | `player_survival_enabled` | no downed state; damage stops mattering | live |
| Tutorial persistence | `tutorial_persistence` | a session starts a fresh run at the lodge | live |
| Content registry | `content_registry` | nothing: no code reads it | none |
| Bramblewake events | `bramblewake_events_enabled` | the wood builds with every event dormant | rebuild |
| Old Growth elite | `old_growth_elite_enabled` | the elite never activates | restart |
| Warden Stag boss | `warden_stag_boss_enabled` | the boss never activates | restart |
| Bramblewake blackout | `bramblewake_blackout_enabled` | blackout nights are ordinary nights | restart |
| Town night cycle | `town_night_cycle_enabled` | the next cycle does not start; the one running finishes | live |
| Lobby departure | `lobby_departure_enabled` | nobody departs; the town is the whole game | live |
| Reserved run servers | `reserved_run_servers_enabled` | a party moves within its own server instead | live |
| Admin commands | `admin_commands_enabled` | every command refuses, roster included | live |
| Region encounters | `region_encounters_enabled` | the six region encounters never start | live |
| Bramblewake region | `region_bramblewake_enabled` | no region is walkable; the town remains | live |
| Ironroot region | `region_ironroot_enabled` | unreleased | live |
| Mireglass region | `region_mireglass_enabled` | unreleased | live |
| Tempest region | `region_tempest_enabled` | unreleased | live |
| Frostmere region | `region_frostmere_enabled` | unreleased | live |
| Cinderfall region | `region_cinderfall_enabled` | unreleased | live |
| Hollow region | `region_hollow_enabled` | unreleased | live |
| Quick chat | `quick_chat_enabled` | the wheel refuses; no player reaches another by text | live |
| Cosmetic store | `cosmetic_store_enabled` | the outfitter's stand refuses; owned cosmetics stay wearable | live |

**Scope** is what it costs to make a change take hold:

- **live** — the flag is read where the decision is made, so a change takes
  hold on every running server at the next opportunity.
- **rebuild** — read when the wood is built, which happens at boot and again
  whenever a private server owner asks for a seed. A change takes hold on the
  next build rather than immediately, because the event states created from it
  have to agree with each other for the life of one manifest: a flag flipping
  between two module placements would build a wood where half the events are
  dormant and half are disabled.
- **restart** — baked into an encounter's state machine at `Init`. **Three
  switches are restart-scoped and the count is pinned**, for the reason
  RELEASE_GATES.md pins its `review` rows: a switch nobody wants to make live
  becoming a fourth is how a kill-switch list quietly stops being one. Each of
  the three governs a single encounter whose status is part of its own state
  machine, and an encounter that vanished mid-fight would take the players in
  it with it.
- **none** — the flag exists and **nothing reads it**. Four do, and writing
  this list is what found them: `bounded_join`, `first_ten_minutes`,
  `input_action_system` and `content_registry` are Milestone 1 staging switches
  for systems that have since become the game. They are not wired because
  wiring them would be a fiction: a kill switch for the input action system
  leaves a world nobody can touch, which is not a rollback, it is an outage.
  **This count is pinned too**, and it is the more important of the two pins —
  a switch that turns nothing off looks exactly like one that works, right up
  until somebody reaches for it during an incident. A fifth means either a new
  flag was added and never wired, or a system was quietly unwired from the one
  it had.

## Rolling back

A rollback restores two things and they are restored in this order, because
the first takes seconds and the second takes a publish:

1. **The flag state.** Turn off the smallest set of switches above that
   contains the failure. This is the whole reason the list exists: most
   incidents are one system, and a flag reaches every running server.
2. **The build.** Republish the last known-good place revision. The revision
   and the flag state that go together are recorded in the PROJECT_STATUS
   header for every published version — "at `main` = *revision*, published as
   place version *N*" — which is the only place in this repository the two are
   written side by side.

**Overrides are refused in production** (`Config.Environments.production`
sets `AllowFlagOverrides = false`), so step one is a config change and a
publish in production today, and a live override only in staging and below.
That is deliberate — a runtime override a client could reach would be an
attack surface — and it is also the honest limit on how fast step one is.
Making step one genuinely live in production needs a server-side flag store,
which is owner-gated infrastructure rather than code.

## What this does not decide

The drill itself, who runs it, the communication that accompanies it, and the
decision to roll back. Those are Milestone 13's owner-gated half, along with
the on-call contacts M14's deliverable list names.
