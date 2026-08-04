# Milestone 3 first crafting recipes

## Scope

Build `0.16.0` gives banked expedition materials their first real sink: a
player who has finished First Light can spend banked materials at a town
crafting bench to craft a named piece of gear, recorded permanently on their
own profile.

```text
banked materials (from a settled Bramblewake expedition)
  → interact with a town crafting bench
  → server checks the recipe's material cost against the bank
  → sufficient: materials deducted, gear item granted, toast confirms
  → insufficient: nothing changes, toast explains why
```

This is a first, deliberately small slice of the "inventory, crafting, gear"
deliverable the vertical slice calls for, not the full system. It adds:

- a static `CraftingCatalog` of two recipes (`recipe_meadow_satchel`,
  `recipe_amber_charm`), each converting a small, currently-obtainable
  combination of the four known expedition materials into one named gear
  item;
- a pure `Crafting` module that deducts a recipe's cost and grants its output
  atomically — either both happen or neither does, the same all-or-nothing
  guarantee `ExpeditionInventory` already gives reward banking;
- two town crafting-bench interactables, each bound to one fixed recipe (the
  same one-pedestal-one-outcome pattern the tutorial's three tool pedestals
  already use, rather than a new recipe-picker UI);
- save-schema-v6 `gear` on every player's own profile: an item-ID-to-count
  map, migrated and validated the same way `town.nightNumber` was in the
  previous increment;
- pure Luau tests for the recipe transaction's success, failure, and
  stacking behavior, and for the schema migration/validation contract.

Equipping crafted gear, gear having any in-game effect, a recipe-browsing
UI, and the full 180-recipe catalog the production roadmap eventually calls
for all remain open — see the Scope honesty row below.

## Recipe catalog

| Recipe | Cost | Output |
|---|---|---|
| `recipe_meadow_satchel` | 3 Meadow Fiber, 2 Heartwood | `gear_meadow_satchel` |
| `recipe_amber_charm` | 2 Amber Sap, 2 Brightcap | `gear_amber_charm` |

Both costs sit at or below what a single completed Bramblewake expedition
already grants of each material (confirmed against the authored reward
nodes in `BramblewakeExpedition.luau`), so a first craft is reachable after
one full run. `material_spring_clay` is a known material ID with no
authored source anywhere in the content yet, so no recipe references it —
a recipe requiring an ungettable material would be a dead end, not a
feature.

## Flow and authority

The server owns the entire transaction. `WorldService` places two crafting
benches near the First Lantern in town, each a `ProximityPrompt` carrying a
fixed recipe ID as its `Payload` attribute — the client only ever sends the
existing generic `interact` action with an `interactionId`, exactly like
every other world interactable; no new remote or payload field was added.
`TutorialService` resolves the prompt's action to `Crafting.CraftItem`,
reads the baked-in recipe ID off the prompt (never off client input), and
calls `ProfileService:craftItem`, which delegates to
`SaveSchema.withCraftedItem` → the pure `Crafting.craft` transaction. The
client never computes affordability or the output item; it only receives a
toast reporting what the server decided.

Crafting is only available once a player's tutorial stage reaches
`"complete"` — the same gate the repeating town night cycle and Bramblewake
re-entry already use — so it can't be triggered mid-tutorial while other
systems assume a fixed action sequence.

## Persistence

`gear` follows the same per-player-profile pattern established for
`town.nightNumber`: no new save type, no new DataStore. `SaveSchema.default`
seeds an empty crafted-item map; `normalize` keeps only entries whose item ID
is a known recipe output and whose count is a valid non-negative integer,
discarding anything else exactly the way it discards an invalid night
number. Crafting the same recipe again stacks the count rather than
rejecting it, so a player who runs Bramblewake multiple times can keep
converting materials into gear.

## Windows Studio journey

1. Download the merged repository ZIP from GitHub and extract it.
2. Open `build/LastLightTest.rbxlx`, press Play, and require
   `[Last Light] PASS FoundationIntegration`, the build version and save schema
   for the commit under test (see `src/shared/Config.luau`), and no red errors.
3. Open `build/LastLight.rbxlx` and attempt to interact with a crafting
   bench before finishing First Light. Require a
   "FINISH FIRST LIGHT TO CRAFT" rejection and no material change.
4. Finish First Light, complete one Bramblewake expedition, and settle its
   rewards. Interact with the Meadow Satchel bench. Require a
   "CRAFTED MEADOW SATCHEL" toast, Meadow Fiber and Heartwood reduced by the
   recipe's cost, and no other material changed.
5. Interact with the same bench again without enough materials banked.
   Require a "NOT ENOUGH MATERIALS" toast and no material change.
6. Run a second expedition, settle it, and craft the Amber Charm bench.
   Require the same success/failure behavior independently of the Meadow
   Satchel bench's state.
7. Disconnect and rejoin as the same player. Require previously crafted
   items and remaining banked materials to still match what was true before
   disconnecting.

## Exit and abuse gate

| Gate | Required evidence |
|---|---:|
| Authority | the server alone decides affordability and grants the output; the client only sends a fixed interaction ID |
| Atomicity | a craft either deducts the full cost and grants the item, or changes nothing at all |
| Determinism | a recipe's cost and output are fixed catalog data, never client-supplied |
| Gating | crafting is unavailable before First Light completes, the same gate other post-tutorial systems use |
| Reachability | every recipe's cost is satisfiable from currently obtainable materials |
| Persistence | crafted items and spent materials survive a disconnect/reconnect and a server restart |
| Scope honesty | equipping/using gear, a recipe-browsing UI, and the full recipe catalog remain open |

Automated checks establish the craft transaction's success, failure, and
stacking behavior, and the gear schema's migration/validation contract, as
pure Luau tests. Only recorded Studio and multiplayer runs can close the
rest of this slice's exit gate.
