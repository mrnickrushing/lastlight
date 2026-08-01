# Milestone 3 equipment visuals

Build `0.22.0` makes equipped permanent gear visible on the player character.
The Ironroot Hood and Bramble Boots now communicate earned loadout choices to
the wearer and the rest of the party instead of existing only as HUD text and
server-side statistics.

## Implemented silhouettes

- **Ironroot Hood:** a layered fabric crown, back and side drapes, a wooden brow
  band, and paired root pins. The open face keeps expressions readable.
- **Bramble Boots:** distinct boot shells, dark soles, living-vine cuffs, and
  mirrored bramble wraps on both feet.
- Both sets use restrained Fabric, Wood, and Ground materials. They do not use
  Neon, lights, particles, floating icons, or oversized geometry.

The pure `GearVisualPlan` catalog owns the recognizable part recipe for each
permanent item. `GearVisualService` interprets that recipe on the server and
welds massless, non-colliding parts to the character. Roblox replication makes
the result visible to every player without trusting a client-supplied loadout.

## Lifecycle and avatar compatibility

The visual service rebuilds the equipment model after profile load, every
accepted equip or unequip transaction, and each `CharacterAdded` event. It
removes the previous model first, so a respawn or loadout change cannot duplicate
parts.

The hood targets `Head`. Each boot prefers the matching R15 foot, falls back to
the matching lower leg, and finally supports the R6 leg name. Lower-leg and R6
fallbacks place the boot at the bottom of the limb rather than its center.

Every generated visual part is:

- server-created and welded to a real avatar body part;
- unanchored, massless, non-colliding, non-touching, and non-queryable;
- shadow-casting but free of active effects;
- contained in one `LastLightEquipmentVisuals` model with item-ID and part-count
  attributes for Studio inspection.

## Automated validation

Pure Luau tests require every permanent equipment definition to have a matching
visual plan and matching slot. They also enforce a layered hood, symmetric
multi-part boots, physical color maps, and the no-Neon art rule. `npm test`
regenerates and verifies both checked-in place artifacts with the service and
catalog included.

## Studio and device exit gate

1. Equip the Ironroot Hood, then inspect the character from front, side, and
   behind on R15. Require an open face, no clipping through the torso, and no
   camera obstruction.
2. Equip the Bramble Boots. Require two grounded, symmetric silhouettes and no
   change to walking, sprinting, jumping, dodging, or stair traversal.
3. Equip both, ask a second player to observe, and require the same loadout on
   both clients.
4. Unequip each slot and require only that item's parts to disappear. Re-equip,
   reset the character, and require exactly one restored visual set.
5. Repeat the journey with an R6 avatar, a baseline phone, keyboard/mouse, and
   controller. Require no physics jitter, touch interference, or measurable
   frame hitch when the model rebuilds.

The automated suite proves catalog coverage and generated-place inclusion. It
does not replace these engine, camera, replication, and avatar-fit checks.
