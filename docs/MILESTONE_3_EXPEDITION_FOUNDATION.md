# Milestone 3 Bramblewake expedition foundation

## Scope

This increment begins Milestone 3 without claiming the vertical slice is
complete. It turns the First Light reveal into an explorable, streamed
Bramblewake route backed by deterministic content contracts.

Implemented:

- 12 representative original Bramblewake modules;
- four points of interest and four catalog-backed event sockets, now activated
  by the follow-on [event increment](MILESTONE_3_BRAMBLEWAKE_EVENTS.md);
- deterministic seeded assembly with a stable manifest hash;
- arrival-to-extraction connectivity, cell-overlap, content-distribution, socket,
  and mobile-budget validation;
- three bounded generation attempts plus a known-good authored fallback;
- a visually distinct route with living root arches, farms, foxglove, sapglass,
  a windmill landmark, moth meadow, Old Growth approach, Wayhome Gate, and
  four physical story vignettes for the last harvest, town evacuation, failed
  windmill repair, and a lost bridge crossing, plus a three-layer regional
  backdrop;
- beacon entry for new and returning tutorial-complete players;
- bounded server-side streaming prefetch before movement to the gated expedition zone;
- fall recovery to the expedition entrance;
- One Active Trail HUD reuse for module progress and discoveries;
- server-side expedition-start analytics;
- 1,000 deterministic seed tests and Studio DataModel assertions.

Not implemented by this increment:

- partial-loss recovery caches or the remaining four Bramblewake events;
- profession kits, full inventory UI/capacity, crafting, or quests;
- the boss, normal night, or Blackout; the complete standard roster and
  [Old Growth elite](MILESTONE_3_OLD_GROWTH_ELITE.md) now expand this foundation;
- final module art, audio, VFX, navigation bake, or device evidence;
- Milestone 2's still-open ten-new-tester and device gate.

## Deterministic preview

The default preview seed is `1847`. Studio can override it before Play:

```luau
game:SetAttribute("LastLightExpeditionSeed", 41290)
```

The server records the selected seed, manifest hash, generation source, module
count, POI count, event count, and generated part count. The same seed and
catalog version must reproduce the same manifest hash.

## Windows Studio journey

1. Synchronize the repository and run `npm test`.
2. Open `build/LastLightTest.rbxlx`, or connect Studio to
   `rojo serve test.project.json`.
3. Press Play and confirm Output contains
   `[Last Light] PASS FoundationIntegration`.
4. Finish First Light and interact with the Bramblewake beacon.
5. Confirm the character enters Lantern Gate instead of falling or waiting for
   the full route.
6. Follow the connected amber path through all 12 modules to Wayhome Gate.
7. Confirm module progress changes from `1 / 12` through `12 / 12`.
8. Fall from three different modules and confirm recovery returns to Lantern
   Gate rather than the town or an infinite death loop.
9. Reset after entry and confirm the player safely respawns in the town; use the
   visible beacon to re-enter.
10. Repeat with three different `LastLightExpeditionSeed` values and confirm
    route order changes while every critical path remains connected.

## Device and multiplayer gate

Record evidence for:

| Gate | Required evidence |
|---|---|
| Baseline phone | stable movement and camera through all module silhouettes; no touch-control overlap |
| Tablet | objective and module progress remain readable without covering landmarks |
| Keyboard/mouse | sprint, interaction, and camera remain responsive while cells stream |
| Controller | prompts remain correct after live input switching |
| 2 and 4 players | all players enter the same manifest and recover safely from falls |
| Streaming | no visible critical-path hole or collision pause at cell boundaries |
| Performance | generated part count stays within catalog budget and target-device frame/memory captures are attached |
| Accessibility | critical path is readable without relying only on amber/green color; largest supported text leaves controls usable |

Any impossible or visually blocked seed becomes a permanent regression fixture.
Do not mark this foundation or Milestone 3 complete from headless tests alone.
