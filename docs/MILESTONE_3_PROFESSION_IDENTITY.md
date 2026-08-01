# Milestone 3 profession identity and Rootline Brace

Build `0.28.0` gives each current profession an unmistakable physical ability
signal and adds the Engineer's first deployable structure without introducing a
new screen or input.

## Implemented scope

- Scout Foxfire Mark projects a four-point foxfire compass;
- Warden Lantern Guard raises six root stakes and outlines the protected avatar
  for the actual guard duration;
- Engineer Emergency Patch shows a rootline gear signal at the First Lantern;
- Medic Guiding Pulse blooms six physical brightcaps around the cast point;
- every motif has a distinct silhouette as well as color, lasts at most 1.5
  seconds, has no collision, and cleans itself up;
- a successful Emergency Patch deploys one 12-second Rootline Brace with 14
  points of pressure capacity;
- deploying again replaces the old brace instead of stacking it;
- the brace absorbs normal lantern impacts, Hollow Crow spark theft, and
  normal-night incident pressure through the same server-owned state contract;
- the physical brace exposes owner, expiry, revision, current capacity, and
  maximum capacity as world attributes, while its core visibly weakens when hit;
- deployment and absorption emit bounded analytics records.

The brace never blocks player damage, grants no paid advantage, and cannot be
placed through a client-supplied position. It exists only as part of the existing
Engineer ability after all normal profession, cooldown, proximity, night, and
lantern-health checks succeed.

## Authority and failure behavior

`EngineerBrace.luau` owns immutable deployment, normalization, absorption,
expiry, and snapshot math. `EnemyService` owns the only live brace state. The
client still sends only the existing profession-ability action and never sends
duration, capacity, absorbed damage, target, position, or remaining time.

Malformed values fail without creating capacity. Expired and exhausted braces
pass the remaining pressure through unchanged. Night start and stop clear the
state and world model. A Hollow Crow or incident can consume part or all of the
same capacity, so no damage path bypasses or duplicates the structure.

## Automated evidence

- pure tests cover deployment, replacement, partial absorption, exhaustion,
  expiry, malformed inputs, snapshots, visual-catalog completeness, unique
  motifs, and effect bounds;
- strict typecheck and Selene cover the renderer and service wiring;
- the Studio integration place requires both shared contracts, validates a
  deployment/absorption transition, and confirms no brace exists before use;
- both generated places embed build `0.28.0`, world
  `bramblewake-blackout-v7`, and save schema `11`.

## Studio and device gate

1. Damage the First Lantern, use Emergency Patch, and confirm the brace appears
   around the lantern rather than around the player.
2. Let one enemy impact the lantern and confirm capacity decreases once while
   the impact pulse remains readable without hiding attack telegraphs.
3. Trigger Hollow Crow spark theft and a failed night incident; confirm both use
   the same remaining capacity and never duplicate absorption.
4. Recast after cooldown and confirm the structure is replaced, not stacked.
5. Confirm expiry and night end remove every brace part and attribute.
6. Exercise all four abilities on phone, tablet, keyboard/mouse, and controller;
   verify motifs remain distinct in grayscale and add no input or HUD overlap.
7. Profile an eight-player defense and confirm transient motifs and the nine-part
   brace stay inside the existing mobile part/effect budget.

Final authored animation, sound assets, captions for those sounds, more Engineer
structures, and recorded Studio/device/group evidence remain open.
