# Last Light visual quality standard

This document is the source of truth for environment, character, prop, mesh,
lighting, and world-presentation work. Read it before changing visible content.
It translates “premium” into implementation and review gates that another
developer or AI agent can verify.

## Target

The first playable world is the vertical slice: Emberhollow, the complete
Bramblewake expedition, its residents, events, enemies, rewards, and return
experience must look like one authored game. Later worlds inherit this standard;
they do not lower it.

Use successful stylized survival games only as a quality reference. Never copy a
recognizable building, character, map layout, prop, logo, texture, sound, or
asset. Rebuild the underlying quality principles with original Last Light forms.

## Style formula

Polished stylized low-poly dark-fantasy woodland with hand-shaped faceted forms,
softened bevels, asymmetrical silhouettes, and visible craft details. Use
rain-dark umber timber, deep moss greens, slate blue-gray stone, muted meadow
gold, and charcoal-indigo shadow. Safe objectives use restrained lantern amber;
memory cues use foxfire cyan. Materials stay matte, rough, and tactile under warm
practical light and cool atmospheric moonlight. Maintain strong gameplay-scale
silhouettes, sparse surface noise, readable negative space, and consistent
three-quarter 3D proportions.

Glow is semantic, not decoration. Neon is limited to flame, foxfire, magic,
hazard telegraphs, and brief reward feedback. It must never substitute for
physical geometry.

## Universal construction rules

1. A gameplay object must be recognizable before its billboard or prompt is
   read. Floating text and icons are secondary confirmation.
2. Never ship a visible interaction as a plain block, pedestal, orb, or ring.
   Preserve invisible stable anchors for code, then surround them with original
   physical geometry.
3. Build in layers: primary silhouette, structural frame, functional object,
   small lived-in details, then restrained light/VFX.
4. Use asymmetry and believable support. Roofs need rafters or beams, platforms
   need posts or braces, tools need handles and heads, and stored goods need a
   shelf, crate, rack, table, or carrier.
5. Every hero location needs a distinct silhouette, purpose, and prop story.
   Recoloring the same assembly does not make new content.
6. Place clutter in purposeful clusters, not uniform noise. Keep navigation,
   combat sightlines, prompts, and mobile camera space clear.
7. Decorative parts are anchored, non-touching, and non-querying when they do
   not own gameplay. Collision comes from simple stable shells, not detailed
   mesh triangles.
8. Do not block joining on optional visual assets. Procedural construction is a
   complete fallback, not an empty placeholder.

## Environment standard

### Buildings and rooms

- A room has a floor, enclosing walls, a roof or ceiling, a readable entrance,
  structural framing, and an interior purpose.
- Cabins need roof volume, corner posts, rafters, openings, a hearth or practical
  light source, furniture, storage, textiles, and exterior activity props.
- A facade with side walls but open sky is not a finished room.
- Construction sites show materials, tools, supports, and the shape of work in
  progress. Completed buildings retain structural and occupational details.

### Routes and terrain

- The critical route is visually continuous through worn ground, edge language,
  repeated landmarks, and direction signs. Players should not need a HUD arrow
  to infer the intended direction.
- Terrain needs foreground, playable midground, and horizon depth. Avoid flat
  rectangles, abrupt terrain seams, inverted water volumes, and repeated tree
  walls.
- Water surfaces must read from the playable side and be checked above, below,
  and at shoreline transitions.

### Landmarks and events

- Each POI and event must have its own physical scene model and visual kind.
- Event anchors remain invisible. Event steps belong to the scene they modify.
- A landmark should survive a screenshot with all labels disabled: its role must
  still be understandable from shape and props.

## Character standard

Debug mannequins are prohibited in player-facing builds. A resident or story NPC
requires:

- an articulated silhouette with torso, separated limbs, hands, feet or boots,
  shoulders, and a shaped head;
- layered clothing such as coat tails, lapels, belts, cuffs, scarf, shawl, apron,
  hood, or hat rather than one torso block;
- a readable face at normal conversation distance: eyes plus at least nose and
  mouth or an intentional mask equivalent;
- hair or headwear shaped beyond one sphere;
- a role-specific carried or nearby prop;
- a distinct palette and silhouette that does not rely only on the nameplate;
- preserved stable interaction target, resident ID, routine pivots, and motion
  tags.

Enemies follow the same silhouette rule, with additional telegraph and hitbox
clarity. Cosmetic geometry must not alter authoritative combat bounds.

## Interaction, crafting, and reward standard

- Tools are displayed in racks, open supply crates, work areas, or character
  hands—not on naked slabs.
- Crafting stations show a real work surface, supports, supplies, and a physical
  sample of the recipe output.
- Rewards arrive in containers, bundles, pallets, satchels, or staged displays.
  The animation reinforces the physical object; a pulse alone is insufficient.
- Semantic anchors may be transparent and non-colliding, but their names,
  attributes, prompts, and server-authoritative action routes must remain stable.

## Mesh and asset workflow

1. Prefer original source assets in `assets/meshes/source/` and reproducible
   exports in `assets/meshes/export/`.
2. Record the intended Roblox size, measured native bounds, source revision, and
   asset ID in the mesh manifest. Never guess scale from a thumbnail.
3. Measure downloaded Roblox meshes with the repository tools. A parser refusal
   for a newer compressed format is an unknown measurement, not proof that the
   asset is restricted or empty.
4. Author hero assets around stable collision shells. Sanitize loaded models and
   remove scripts, prompts, constraints, and unapproved descendants.
5. Keep material slots and triangle counts bounded. Use high detail only where
   players can inspect it.
6. Built-in Roblox materials already provide PBR response. Add custom
   `SurfaceAppearance` maps only when they match the mesh UVs and materially
   improve a hero asset.
7. API keys live only in the operator environment. Never commit, print, log, or
   embed credentials in source or generated places.

## Performance and mobile gates

- Preserve streaming cells and a playable arrival area inside the bootstrap
  timeout.
- Prefer a few strong silhouettes over hundreds of tiny parts. Reuse templates
  and disable shadows on small decorative pieces.
- Test low and maximum graphics on phone, tablet, and desktop. Review camera
  obstruction, prompt reach, collision, navigation width, and enemy readability.
- Added detail must remain within the content definition part budgets. Raise a
  budget only with measured evidence and a documented reason.

## Required evidence before calling a visual pass complete

1. `npm test` passes, including format, lint, type, pure tests, generated-place
   builds, and place verification.
2. Studio integration assertions verify stable contracts and minimum physical
   construction for the changed content.
3. Fresh `build/LastLight.rbxlx` and `build/LastLightTest.rbxlx` artifacts come
   from the same validated source revision.
4. Studio screenshots show the changed content with labels both enabled and
   disabled, in day and night lighting where applicable.
5. Studio Output has no new runtime error and reports the expected build and
   world versions.
6. A device pass confirms phone navigation, camera clearance, interaction reach,
   and acceptable performance.

Repository validation proves the artifact was built correctly; it does not prove
that the published Roblox version or final appearance was inspected. Record those
as separate gates.
