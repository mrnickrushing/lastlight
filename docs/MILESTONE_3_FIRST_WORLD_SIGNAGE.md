# Milestone 3: Physical First-World Signage

## Outcome

Build `0.41.0` replaces first-world blank notices, thin sign slabs, floating
route cards, neon destination rings, and large interaction orbs with physical
dark-fantasy construction. Exact wording remains code-rendered and secondary;
the board, lantern, root, planter, antler, or cairn must communicate first.

The pass covers Emberhollow and the complete Bramblewake expedition:

- route signs use supported crooked posts, braces, layered frames, iron pins,
  carved arrows, and face-mounted lettering;
- the Greenward Archive and Town Board hold eight distinct pinned illustrated
  notices with metal pins and wax seals instead of blank SmoothPlastic paper;
- construction, building, consequence, workshop, warning, and cabin signage
  shares the tactile wood/iron language without becoming one identical shape;
- event and extraction destinations use asymmetric slate cairns with glass
  insets instead of circular neon dots;
- Old Growth fire and heart targets gain lantern cages and living-root shells;
- Warden nodes gain rooted physical silhouettes and antlers gain tines;
- permanent Greenward choices are planted, braced physical planters rather than
  three colored spheres.

## Image asset

The notice art source of truth is
[`assets/images/manifest.json`](../assets/images/manifest.json). The committed
1254×1254 atlas contains six original equal cells: evacuation route, lantern
maintenance, supply inventory, bramble hazard, field botany, and community
watch. It contains no readable generated text; exact copy is rendered by Roblox
on separate physical title plates.

The original source is
`assets/images/source/first-world-notice-atlas-v1.png`, SHA-256
`1031a6e8dfa18c94595016df5aa5e485624368d48cfcce041d110058233abc3b`.
Roblox Decal asset `83727643922166` reached public thumbnail state `Completed`,
and the downloaded rendered pixels were visually checked before placement.

Validate source dimensions, hashes, atlas layout, and cloud mappings with:

```bash
python3 scripts/validate_image_assets.py
```

Upload a missing revision with:

```fish
fish -c 'source ~/.secrets/roblox.fish; python3 scripts/upload_image_assets.py --all'
```

Roblox does not support content replacement for Image/Decal assets. Pixel
changes require a new versioned source filename, stable ID, and cloud asset ID;
never silently repurpose the shipped V1 mapping.

## Runtime and budget rules

- `WorldSignBuilder` owns physical board construction and atlas placement.
- `WorldArtRegistry` owns the stable panel-to-atlas mapping.
- Gameplay prompts and server interaction targets retain their stable IDs.
- Decorative details remain anchored, non-colliding, non-touching, and
  non-querying.
- No mesh triangle or material-slot budget changes are required.
- No custom `SurfaceAppearance` is added; the image is limited to authored
  paper surfaces and built-in Roblox materials provide the 3D response.
- The existing Bramblewake part-budget ceiling is not raised. Studio must still
  report a generated count inside the declared aggregate limit.

## Acceptance gates

- All eight notice papers contain the approved cloud image and a known atlas
  panel ID.
- No `DestinationMarker` neon ring parts remain.
- Six evacuation road signs retain their stable marker/sign names and have
  physical construction details.
- Old Growth, Warden, and chapter-decision targets retain their interaction
  attributes while gaining recognizable physical shells.
- `npm test` passes and both generated places contain the new registry, builder,
  image asset ID, build `0.41.0`, and world version `bramblewake-blackout-v23`.
- Studio screenshots with labels enabled and disabled, Studio Output, and the
  phone/device pass remain the final visual release gate.
