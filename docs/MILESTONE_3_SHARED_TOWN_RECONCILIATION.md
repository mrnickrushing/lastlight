# Milestone 3 shared-town reconciliation

Build `0.20.0` makes physical Emberhollow progression safe in multiplayer.
Profiles remain personal, but every player in a server sees one shared world.

Before this pass, each profile load rebuilt the shared landscape, buildings, and
resident roster directly from that player. A fresh player joining after a
veteran could therefore regress the visible town to tier zero; players with
different chapter choices could also make the landscape flicker by join order.

## Reconciliation rules

- Shared town tier, growth stage, every building stage, and unlocked resident
  roster advance monotonically to the highest state seen in the server.
- A lower-tier or unresolved profile can never remove established buildings or
  residents.
- The first resolved chapter consequence seen by the server owns its shared
  Greenward landscape and Warden memorial for that session.
- A later higher-tier player can advance construction without erasing that
  established consequence.
- Every player's personal decision remains unchanged in their saved profile and
  per-player state snapshot.

The merge is a pure `TownProgression` operation and does not mutate either input.
Tests cover lower-tier joins, higher construction arriving without a chapter
choice, and the first resolved consequence arriving after an unresolved player.

Cross-server consensus and a party-voted home-town owner remain later
architecture decisions. This increment guarantees stable behavior inside one
live server without inventing a global winner between personal story choices.
