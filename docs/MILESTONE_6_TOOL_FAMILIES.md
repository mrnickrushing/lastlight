# Milestone 6 tool-families runbook

## Scope

The roadmap's eight tool families — axes, hammers, lanterns, picks, sickles,
fishing kits, climbing kits, and survey instruments — one held tool per
family, all defined in the new shared `ToolCatalog` and each with a bounded
identity through hooks the game already had:

| Family | Tool | Identity |
|---|---|---|
| Axe | Hand Axe | strikes 1.25x (pre-existing) |
| Hammer | Builder's Hammer | all timed work 0.75x duration (pre-existing) |
| Lantern | Hand Torch | +4 strike reach at 0.9x (pre-existing) |
| Pick | Ironroot Pick | sap/clay harvests 0.75x duration; strikes 1.05x |
| Sickle | Meadow Sickle | fiber/brightcap harvests 0.75x duration; +2 reach |
| Fishing kit | Fishing Kit | stamina regen 1.1x |
| Climbing kit | Climbing Kit | sprint speed 1.08x (sprint only) |
| Survey | Survey Glass | nearest unharvested node marked as an objective |

The pick and sickle hurry only their own materials — the node's reward
decides, so a pick at a brightcap is just a pick. The endurance identities
ride per-player attributes (`LastLightToolStaminaRegen`,
`LastLightToolSprintSpeed`) that the tool selector maintains and the combat
service reads inside its existing clamps. The survey marker is one nearest
node, not a maphack. A client never submits any number.

**Tools are swappable after First Light**, the same freedom professions
have: town only, not while downed, not in the expedition. The tutorial's
choose-tool stage accepts any family. `SaveSchema` validates the stored
tool against the catalog rather than three literals, so all eight persist.

Each family has a physical display in the starter tool yard (3 → 8; the
five new crates use procedural silhouettes since no reviewed meshes exist
for them yet — recorded in the asset backlog).

## Live evidence (connected session, this increment)

- `PASS FoundationIntegration` on a clean fresh-save boot with 8 displays
  and the census at 80 (+5 tool prompts, class-by-class derivation updated).
- Tutorial choose-tool stage accepted the pick ("IRONROOT PICK SELECTED"),
  and the full tutorial completed with it.
- Post-tutorial swap verified for all paths: climbing kit set
  `sprintAttr=1.08` and sprint WalkSpeed measured **25.92** (24 × 1.08)
  exactly; fishing kit set `regenAttr=1.1` with the published regen
  multiplier reading 1.1 after the next combat sync; the survey glass
  cleared both attributes on swap. Pre-completion re-selection stays
  refused with the objective toast.

## Open work

Pick/sickle harvest-timing and the survey marker want a live expedition
pass (harvest an amber node with the pick against a stopwatch; walk the
trail with the glass and watch the marker move). The fishing kit's pond
catch loop and the climbing kit's real traversal are future mechanics —
their stat identities ship now, honestly labeled. Reviewed meshes for the
five new displays. The remaining M6 systemic items: loadouts, repair,
equipment traits, status/reaction system, companions, enemy director,
defense plots.
