# Beta rollout — the flag matrix

## Purpose

[PRODUCTION_ROADMAP.md](PRODUCTION_ROADMAP.md) describes Milestone 13's closed
beta as four rungs: team and trusted testers, then a small allowlist across
devices and age ranges with guardian consent, then a larger cohort behind
controlled feature flags, then the creator and community test once moderation
and scale look healthy.

This document is the matrix that makes those rungs a thing you can read rather
than a thing you remember. Every feature flag in the game is in the table
below with the rung it has reached and why it is there, and
`FeatureFlagService.spec` holds this table against `Config.FeatureFlagRollouts`
and `Config.FeatureFlags` so **none of the three may change alone**.

## The rungs

| Rung | Who it admits | Where the roster comes from |
|---|---|---|
| `off` | nobody | — |
| `team` | the team and trusted testers | `Config.RolloutRoster.team`, by user ID |
| `allowlist` | the above, plus the consented device and age-range allowlist | `Config.RolloutRoster.allowlist`, by user ID |
| `cohort` | the above, plus a stable share of everybody else | the flag's own `percent`, bucketed by user ID |
| `everyone` | everybody | — |

Three rules hold this up, and each of them is a way a staged rollout goes
wrong in a live beta rather than a preference:

- **The ladder only widens.** `RolloutCohorts.admits` walks the rungs from the
  bottom to the flag's current stage and returns at the first one that admits,
  so advancing a flag can only add people. A tester who has been living with a
  feature is exactly whose report the next rung is decided on, and taking it
  away from them when it widens is how that gets lost.
- **A cohort-scoped flag has no global answer.** Reading one without a player
  throws. Both defaults are silently wrong: `true` ships an unreleased feature
  to the whole population, and `false` hides it from the cohort it was turned
  on for.
- **A bucket is stable per player and independent per flag.** Stable, because a
  feature that is on in one server and off in the next produces a bug report
  nobody can reproduce. Independent, because if the same players are drawn for
  every flag then the beta has one cohort wearing four features and every
  measurement is about that group.

## Advancing a flag

One edit to `Config.FeatureFlagRollouts`, and the boolean in
`Config.FeatureFlags` moves with it only at the last rung — a flag is `true`
there **if and only if** its stage is `everyone`. That is not a convention;
`RolloutCohorts.globalDefault` is the function both sides are checked against,
so the switch and the matrix cannot drift apart.

The two rosters are empty in the repository and stay that way. A trusted tester
is somebody the owner asked and an allowlisted player is one whose guardian
consented; neither is a fact this repository can invent, and a flag standing at
`team` with an empty roster is on for nobody, which is the safe direction for
this to be wrong in.

## The matrix

`percent` is read only at the `cohort` rung. It is carried at every stage so a
flag arriving at that rung cannot be opened and have its share chosen in the
same commit.

| flag | stage | percent | why it is there |
|---|---|---|---|
| `bounded_join` | `everyone` | 100 | shipped since Milestone 1 |
| `first_ten_minutes` | `everyone` | 100 | shipped; the onboarding path |
| `input_action_system` | `everyone` | 100 | shipped; every action rides it |
| `combat_mobility_enabled` | `everyone` | 100 | shipped |
| `profession_kits_enabled` | `everyone` | 100 | shipped |
| `player_survival_enabled` | `everyone` | 100 | shipped |
| `tutorial_persistence` | `off` | 0 | decided off, not unreleased: rejoining halfway through a night you already left reads as the game having lost track |
| `content_registry` | `everyone` | 100 | shipped |
| `bramblewake_events_enabled` | `everyone` | 100 | shipped |
| `old_growth_elite_enabled` | `everyone` | 100 | shipped |
| `warden_stag_boss_enabled` | `everyone` | 100 | shipped |
| `bramblewake_blackout_enabled` | `everyone` | 100 | shipped |
| `town_night_cycle_enabled` | `everyone` | 100 | shipped |
| `lobby_departure_enabled` | `everyone` | 100 | shipped |
| `reserved_run_servers_enabled` | `everyone` | 100 | shipped; falls back within the server where reserving is impossible |
| `admin_commands_enabled` | `everyone` | 100 | a complete off switch for the roster, not a rollout |
| `region_encounters_enabled` | `everyone` | 100 | on so it can be turned off in a hurry, not staged in |
| `region_bramblewake_enabled` | `everyone` | 100 | the one region a live session has walked end to end |
| `region_ironroot_enabled` | `off` | 0 | owner-gated: a region opens once a live session walks it |
| `region_mireglass_enabled` | `off` | 0 | owner-gated: as above |
| `region_tempest_enabled` | `off` | 0 | owner-gated: as above |
| `region_frostmere_enabled` | `off` | 0 | owner-gated: as above |
| `region_cinderfall_enabled` | `off` | 0 | owner-gated: as above |
| `region_hollow_enabled` | `off` | 0 | owner-gated: as above |
| `quick_chat_enabled` | `everyone` | 100 | shipped; a closed vocabulary, so the flag is a withdrawal switch |
| `cosmetic_store_enabled` | `off` | 0 | owner-gated: waits on Creator Dashboard products, prices, and one real receipt |

Nothing is mid-ladder today, and that is the honest state rather than an
oversight: the middle rungs are populations, and there is no population yet.
The first flag to stand on one will be whichever feature the closed beta wants
a tester's opinion on before everybody's.

## What this does not decide

Who is in a cohort is the owner's, and it is the whole of Milestone 13's
owner-gated half: the trusted testers, the guardian consent that makes an
allowlist legal, the measurement window the thresholds in
[RELEASE_GATES.md](RELEASE_GATES.md) are read across, and the decision to
advance. This document holds the mechanism and the current state of it.
