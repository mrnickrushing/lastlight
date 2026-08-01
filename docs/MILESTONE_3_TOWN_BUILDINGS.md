# Milestone 3 town building progression

Build `0.20.0` now turns the persisted Emberhollow town tier into visible
construction progress. The town no longer communicates growth only through a
number and the Greenward landscape.

## Implemented slice

- `TownProgression.resolve` derives bounded stages for the Memory Archive,
  Town Board, Lantern Workbench, First Lantern, and Wayfarer Inn.
- A stage-zero Archive or Inn appears as a genuine foundation and scaffold,
  preserving the promise of future growth on a fresh save.
- Completed buildings have floors, four enclosing walls with deliberate doors,
  roofs, warm interiors, readable signs, and building-specific physical props.
- Higher stages add awnings, stronger practical light, planters, and more mature
  presentation without changing critical collision or traversal.
- The Town Board identifies the current tier in the world, so progression is
  legible without opening a menu.
- Reapplying a consequence replaces the prior building model rather than
  stacking duplicate geometry.

The Wayfarer Inn intentionally opens one tier later than the core Archive,
Town Board, and Workbench. Emberhollow first becomes self-sufficient, then gains
the capacity to receive travelers.

## Validation

The pure progression contract is covered for fresh, chapter-resolved, mature,
and capped town states. `npm test` also regenerates and verifies both checked-in
place artifacts.

Studio/device confirmation remains required for camera clearance, visual
overlap, and streaming behavior at every town tier.
