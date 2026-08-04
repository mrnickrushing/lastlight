# Milestone 3 first quests

## Scope

Build `0.19.0` gives the material economy its first quest layer plus the
authoritative mastery/equipment progression layer: three automatic milestones
that grant a material reward the moment their objective is met. Tomas, Pip,
and Ena now surface live progress and become consequence-aware storytellers
after their linked milestone is complete.

```text
a tracked signal changes (a night completes, a craft succeeds, an
expedition settles)
  → server checks every not-yet-claimed quest against current signals
  → any newly satisfied quest is claimed exactly once and its reward
    is added to the player's banked materials
  → a toast reports it, folded into whatever toast the triggering
    action was already about to show
```

This remains an automatic-milestone system, not an accept-and-track quest board:

- **No accept step or new UI panel.** Every objective this increment defines
  is derivable from state the game already tracks
  (`town.nightNumber`, the `gear` map, `inventory.settlementOrder`), so
  there was nothing to gain from inventing a new tracking mechanism before
  the residents report progress but do not own or duplicate quest state.
- **Three physical quest-givers.** Tomas tracks the first craft, Pip tracks
  three defended nights, and Ena tracks three Bramblewake settlements. Their
  proximity prompts use the existing contextual action and toast surfaces.
  After completion they discuss the player's Greenward decision or Warden
  outcome instead of repeating a finished checklist forever.
- **Three starter quests**, each rewarding materials that feed straight
  back into crafting:
  - `quest_survive_three_nights` — survive 3 town nights → 5 Heartwood
  - `quest_first_craft` — craft any one item → 3 Amber Sap
  - `quest_bramblewake_veteran` — complete 3 Bramblewake settlements → 3
    Brightcap
- **Claimed state is the only new persisted field.** Progress is always
  read live from the profile's existing fields, never stored separately —
  a quest that would briefly regress (crafting an item and later using it
  up) doesn't lose credit once it's already been claimed, because only the
  claimed flag persists, not a progress counter.
- **The quest snapshot is exposed but not rendered.** `TutorialService`'s
  published state now includes a `quests` array (id, progress, threshold,
  claimed) for every catalog quest, the same way `gear`/`bankedMaterials`
  were exposed ahead of any dedicated panel — a future quest-browsing UI
  has data to render without further server work.

A quest-browsing UI, branching/choice objectives, and quests whose objective
isn't already derivable from tracked state all remain open — see the Scope
honesty row below.

## Flow and authority

`Quests.checkAndClaim` is pure and stateless: given a claimed set, the
current material bag, and a `Signals` snapshot (nights survived, items
crafted, settlements completed), it claims every quest whose objective is
met and hasn't been claimed yet, returning the updated claimed set,
updated materials, and a list of what was newly claimed. `SaveSchema`
extracts `Signals` from the real profile and wraps the transaction as
`checkAndClaimQuests`; `ProfileService.checkQuests` is the server-side
entry point, safe to call after any action regardless of whether it moved
a signal — it just returns an empty list and touches nothing when there's
nothing new to claim.

`TutorialService` calls it at the three points that can move a signal: the
town night cycle's completion handler, a successful craft, and a
successful Bramblewake extraction. The client never evaluates quest
progress; it only ever receives the resulting toast and the read-only
`quests` snapshot.

## Toast composition

A player session only ever carries one pending toast at a time (a single
`toast`/`toastRevision` field, not a queue) — an earlier bug in the town
night cycle already established that setting two toasts in a row silently
drops the first. Rather than let a quest claim silently eat the craft or
extraction toast that triggered it, `TutorialService._questToastSuffix`
returns a string fragment that each call site folds into its own toast
(`"CRAFTED MEADOW SATCHEL · QUEST COMPLETE: FIRST CRAFT"`). The one
exception is the night-completion broadcast, where a per-player quest toast
can rarely overwrite the same-tick "DAWN BREAKS" toast — accepted as a
one-time-per-player edge case consistent with other toast-priority
decisions already made in this codebase.

## Windows Studio journey

1. Download the merged repository ZIP from GitHub and extract it.
2. Open `build/LastLightTest.rbxlx`, press Play, and require
   `[Last Light] PASS FoundationIntegration`, the build version and save schema
   for the commit under test (see `src/shared/Config.luau`), and no red errors.
3. Open `build/LastLight.rbxlx`, finish First Light, craft one item.
   Require a "CRAFTED ... · QUEST COMPLETE: FIRST CRAFT" toast and 3 Amber
   Sap added to the material bank.
4. Survive three town nights. Require a "QUEST COMPLETE: THREE NIGHTS
   SURVIVED" toast on the third dawn and 5 Heartwood added.
5. Talk to Tomas, Pip, and Ena before completion. Require each resident to
   report the linked objective and exact live progress without accepting or
   resetting anything.
6. Complete three Bramblewake expeditions with settled rewards. Require a
   "QUEST COMPLETE: BRAMBLEWAKE VETERAN" toast on the third settlement and
   3 Brightcap added.
7. Talk to each resident after completion. Require story dialogue to replace
   checklist dialogue and reflect the player's chapter consequence.
8. Repeat any of the triggering actions after a quest is already claimed.
   Require no duplicate reward and no duplicate toast.
9. Disconnect and rejoin. Require claimed quests and their granted
   materials to still match what was true before disconnecting.

## Exit and abuse gate

| Gate | Required evidence |
|---|---:|
| Authority | the server alone evaluates and claims quests; the client only ever receives the resulting toast and snapshot |
| Idempotence | claiming the same quest twice grants the reward exactly once |
| No progress loss | an already-claimed quest stays claimed even if its underlying signal later regresses |
| No dead quests | every quest's reward material has an authored source elsewhere in the content (no quest can require an ungettable reward path) |
| Toast integrity | a quest claim never silently replaces the toast of the action that triggered it (folded into one string instead) |
| Persistence | claimed quests and their granted materials survive a disconnect/reconnect and a server restart |
| Resident context | each resident reports only the linked server snapshot and completed dialogue reflects chapter consequence |
| Scope honesty | a quest-browsing UI and branching/choice objectives remain open |

Automated checks establish the claim transaction's idempotence, reward
granting, and multi-quest-in-one-pass behavior as pure Luau tests. Only
recorded Studio and multiplayer runs can close the rest of this slice's
exit gate.
