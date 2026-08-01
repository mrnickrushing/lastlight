# Milestone 3 profession-kit runbook

## Scope

This increment implements the first playable, profession-independent role layer
for the Bramblewake slice:

- Scout — **Foxfire Mark** reveals and slows the active Rootling for 8 seconds;
- Warden — **Lantern Guard** reduces incoming Rootling damage by 60% for 6 seconds;
- Engineer — **Emergency Patch** restores up to 18 First Lantern health from
  within 30 studs;
- Medic — **Guiding Pulse** heals the caster and active allies within 28 studs
  for up to 22 health.

Every traveler still keeps the baseline strike, sprint, dodge, gather, build,
interact, and revive actions. No objective, recovery path, or reward requires a
specific profession.

## Authority and persistence

- `ProfessionCatalog` owns the four stable profession and ability contracts.
- `ProfessionState` owns selection, cooldown, active window, and revision
  transitions without mutating prior state.
- `ProfessionService` validates safe-town switching, target availability,
  distance, player state, cooldown, effect resolution, persistence, attributes,
  telemetry, and snapshots on the server.
- Save schema v3 adds only `profession.selectedId`. Unknown profession IDs are
  discarded during migration.
- Selection is free and persists. It is accepted only after First Light while
  the player is active, in daylight, and outside an expedition.
- Ability requests carry no target, amount, duration, cooldown, or outcome
  claim. The server derives all of them.

## Input and HUD contract

| Action | Touch | Keyboard/mouse | Controller |
|---|---|---|---|
| Open profession selector | `CHOOSE KIT` / `KIT` pill | `P` | D-pad Up |
| Use profession ability | labeled 84×84 cooldown action | `Q` | L1 |
| Close selector | 72×64 `CLOSE` target | Escape | B or `CLOSE` |

The selector:

- opens only when switching is valid and closes if night, expedition, or downed
  state begins;
- uses four text-complete cards, an explicit equipped label, and a border plus
  color state;
- is controller-selectable and blocks custom combat/interact intent while open;
- uses a two-by-two layout with device-safe insets and a narrow-screen panel;
- leaves phase, threat, health, light, and context actions as the gameplay HUD
  priority.

Design evidence:
[Profession Selector + Ability HUD report](https://www.lazyweb.com/report/lazyweb/73595230-6584-431c-8d84-c7eb06fdeaa5/?source=create).
The source reference set had moderate coverage and was used for selection
hierarchy, not as evidence for combat balance.

## Automated evidence

Before merge:

```bash
npm test
```

The pure suite covers:

- all four known profession selections;
- unknown and unsafe selection rejection;
- profession-required, downed, and cooldown rejection;
- server cooldown and active-window transitions;
- exact Warden protection expiry;
- cooldown preservation across profession switches;
- same-profession idempotence;
- save-schema-v2 to v3 migration and invalid-ID removal;
- bounded healing without reviving a downed player.

The Studio integration build additionally asserts the catalog, state module,
schema/build versions, profession action IDs, and `ProfessionService` presence.

## Required Studio and device evidence

Source and CI do not close the Milestone 3 device gate. Record the following in a
private Studio/server session before calling this slice complete:

1. Finish First Light, choose each profession, leave/rejoin, and confirm the last
   selection returns.
2. Attempt switching during First Light, night, an expedition, and while downed;
   confirm each request fails with a readable reason and does not change state.
3. Use Scout from inside/outside 55 studs and through cover; confirm only the
   valid Rootling receives an amber mark and visibly slower travel for 8 seconds.
4. Use Warden before and during a Rootling threat; confirm the invalid request
   spends no cooldown and an active swipe deals 10 rather than 24 damage.
5. Damage the First Lantern, test Engineer from inside/outside 30 studs, and
   confirm repair caps at 100 with no cooldown spent on a full lantern.
6. Damage one and several players, test Medic inside/outside 28 studs, and
   confirm healing caps at max health and never revives a downed player.
7. Repeatedly spam select and ability remotes; confirm rate limiting, schema
   rejection, and server logs without duplicated effects.
8. Test landscape phone, narrow portrait emulation, keyboard/mouse, controller,
   and live preferred-input switching. Verify no touch overlap with Roblox
   movement/jump zones, safe insets, threat warning, revive rail, or context action.
9. With the selector open, verify custom combat/interact intent is blocked,
   D-pad card navigation works, and Close/Escape/B restores play.
10. Run solo plus two-player sessions to confirm Scout mark and Medic pulse are
    shared correctly and no profession is required to finish the night.

## Open work

The follow-on profession-mastery increment added ten persistent levels, six rank
names, bounded gameplay rewards, and three stable level-10 specialization paths
per playable kit. The rescue-utility increment then added mastery-scaled Medic
and Warden revive modifiers. The follow-on specialization increment added
physical selection and twelve bounded path effects. Profession-specific physical
ability motifs and the first Engineer structure are now implemented. Authored
audio sets, boss interactions, wider enemy support, additional deployable
engineering structures, balance telemetry thresholds,
and recorded device/group evidence remain open.
