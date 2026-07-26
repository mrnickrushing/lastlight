# Art and audio direction

## Visual thesis

**Handmade warmth surrounded by impossible weather.**

The town should feel touched by specific people: repaired joints, mismatched
boards, labeled jars, worn steps, resident decorations, and tools left where work
happened. The wilderness should feel beautiful before it feels threatening. The
Long Night corrupts meaning and behavior more often than it adds spikes or black
smoke.

The target is polished stylized Roblox, not imitation realism and not a generic
simulator. Strong silhouettes, restrained materials, authored lighting, layered
backgrounds, and readable movement take priority over raw part count.

The durable gameplay-HUD visual targets and implementation rules live in
[UI_DESIGN_DIRECTION.md](UI_DESIGN_DIRECTION.md). Its locally archived images
are the source of truth if the linked external research report becomes
unavailable.

## Shape language

- **Emberhollow:** upright lantern rectangles, circles of shelter, patched
  asymmetry, upward rebuilding.
- **Safe paths:** repeating warm lights and low horizontal rhythms.
- **The Long Night:** broken repetition, inverted familiar shapes, gaps where a
  name or function should be.
- **Interactables:** deliberate handles, hinges, straps, sockets, and wear.
- **Enemies:** one readable primary mass, one signature behavior shape, limited
  secondary noise.
- **Residents:** work silhouette and personal prop visible at gameplay distance.

## Material language

Use a small reusable material library:

- rough timber with region-specific wear;
- dressed and field stone;
- canvas, rope, wool, leather, paper, and hammered metal;
- clear, smoked, storm-charged, frost, and memory glass;
- living roots, reeds, fungi, coral, ice, ash, and moss.

Material variation comes from vertex color, trim sheets, decals, and modular
details rather than unique high-resolution textures for every prop.

## Color and lighting

### Global anchors

- Lantern amber: safety, work, cooperation, recoverable objective.
- Moon cyan: distance, memory, mystery, not automatically danger.
- Deep indigo: night volume and negative space.
- Bone white: names, memory fragments, final-machine language.
- Danger coral: immediate damage/breach only; never used for premium offers.

Every region adds two accents while retaining the global anchors. Critical
gameplay colors have icon, shape, and animation alternatives.

### Day

- Readable terrain values, soft atmospheric depth, clear resource silhouettes.
- Warm sunlight does not wash out UI or interactable highlights.
- Distant landmarks remain visible at low graphics through silhouettes/LOD.

### Dusk

- The most important transition in the game.
- Sky and music change early enough to create preparation, not surprise.
- Town lanterns lead the eye home.
- Enemy clues appear at the treeline without obscuring navigation.

### Night

- Darkness creates contrast and uncertainty without making traversal blind.
- The player's local path, interaction surfaces, and telegraphs remain readable.
- Decorative point lights are capped; important lights own the lighting budget.
- Shadows on minor lights and clutter are disabled according to device tier.

### Blackout

- Each region has one rule-specific visual transformation.
- Reduced-flash and low-effects modes retain phase clarity.
- Blackout spectacle ramps in layers so low-end devices receive silhouette,
  lighting color, audio, and essential particles without losing the event.

## Region art briefs

### Bramblewake

Large roots create arches and circular rooms. Farm geometry remains visible beneath
growth. Background windmills and root cathedral establish depth. Rain-dark wood,
sap glow, meadow gold, and foxfire create a welcoming first region.

### Ironroot

Vertical composition, moving silhouettes, rail lines, and timed furnace light.
The mine must not become uniformly brown: oxidized iron, soot, fungus teal, shift
signage, and workers' personal spaces provide contrast and history.

### Mireglass

Wide reflective water planes are used carefully for performance. Reflections are
selective or faked where needed. Crooked rooflines, pale reeds, and hanging
witchlights produce navigable layers. Copies differ through motion and missing
details, not only color.

### Tempest

Strong diagonals from cliffs, masts, ropes, and rain. Background storm walls and
lighthouse beams establish scale. Water and lightning have quality-tier variants.
Climb routes remain matte/readable against wet scenery.

### Frostmere

Quiet negative space, blue shadow, dark monastery shapes, warm vents, and aurora
ribbons. Snow deformation is cosmetic and capped. Tracks critical to play use
explicit decals/markers that survive graphics changes.

### Cinderfall

Grand civic shapes fractured by ash and glass. Repeating parade banners and
empty windows make the city uncanny. Heat shimmer, glass reflection, ash volume,
and crowds are tiered aggressively for mobile.

### The Hollow Below

Reuse and transform motifs from every region. The machine should look handmade
at first, industrial deeper down, then spatially impossible. Background scale
comes from silhouette layers and slow motion, not thousands of active parts.

## Character art

### Players

- Preserve Roblox avatar identity and layered clothing compatibility.
- Equipment silhouettes attach cleanly across supported body scales.
- Backpacks and large tools avoid camera occlusion.
- Cosmetic effects have intensity and density caps.
- Team/status outlines are optional and accessible.

### Residents

Each resident needs:

- silhouette sheet at gameplay and portrait distance;
- base outfit, work outfit, night-defense variation, injury variation;
- 6–10 personal props or room details;
- facial/emote set compatible with Roblox rigs;
- locomotion, work loop, social loop, fear, relief, and celebration;
- three relationship-stage visual details;
- low-detail and streaming-safe versions.

### Enemies

Each enemy brief includes:

- 3-second silhouette recognition test;
- locomotion signature;
- anticipation, active, recovery, stagger, and defeat poses;
- hit and danger volumes shown in debug;
- color-independent telegraph;
- sound signature and caption phrase;
- low-effects VFX;
- LOD and maximum simultaneous count.

## Environment production rules

- Graybox traversal and combat before final art.
- Every art module declares connectors, bounds, nav constraints, streaming mode,
  collision proxy, LOD, landmark direction, spawn sockets, and effect budget.
- Decorative geometry cannot change critical collision.
- Backgrounds include three depth layers: near framing, regional landmark, distant
  silhouette/weather.
- Repeated modules get authored dressing sets with seed-controlled variation.
- No random decoration blocks navigation, enemy sight, loot, or mobile camera.
- Use collection tags and asset manifests; do not scan names in Workspace.

## VFX

VFX priority:

1. enemy attack and hazard telegraphs;
2. player action confirmation and damage source;
3. phase, breach, revive, objective, and extraction signals;
4. profession identity;
5. rewards;
6. ambience and cosmetics.

Lower priority effects yield first under budget. VFX declare:

- duration and maximum overlap;
- particle, trail, beam, light, and transparency cost;
- quality-tier variants;
- reduced-motion/flash variant;
- pooling behavior;
- whether replicated state is necessary.

Premium effects cannot obscure other players or resemble critical telegraphs.

## Animation

- Combat timing is authored from animation markers but validated server-side.
- Root motion is avoided where it creates replication mismatch; movement intent
  remains authoritative.
- Residents use shared locomotion with layered profession loops.
- Enemies reuse rigs only when silhouettes and timing remain distinct.
- Interaction animations cancel safely when target streams out, player moves, or
  server rejects.
- Reduced-motion mode removes nonessential UI/camera animation, not readable
  character anticipation.

## Camera

- Third-person default with tested mobile sensitivity.
- Indoor modules guarantee camera clearance.
- Camera collision avoids repeated snap and wall clipping.
- Lock-on is optional and never required.
- Boss camera framing does not steal control during active danger.
- Camera shake has Off/Low/Full and intensity budget.
- Cinematics are skippable after required state is safely committed.

## Audio thesis

The town is an instrument assembled over time. Each restored district adds a
layer to Emberhollow's music and ambience. The wilderness removes or transforms
those motifs; Blackouts distort them; the finale recombines them based on player
decisions.

### Music system

Adaptive stems:

- region foundation;
- exploration curiosity;
- dusk preparation;
- night pulse;
- crisis;
- boss phase;
- victory/relief;
- Blackout transformation;
- town district layers.

Transitions are scheduled and phase-aware. Music never becomes the only phase cue.

### Ambience

- Every region has day, dusk, night, shelter, weather, and landmark beds.
- Spatial loops are bounded and pooled.
- Silence is intentional in Frostmere and Hollow, with visual danger backup.
- Resident work adds localized life to restored districts.
- Low-end/audio-limited clients retain essential cues with fewer ambience layers.

### Gameplay cues

Every enemy family, structure crisis, ally down, phase transition, rare pickup,
interaction result, and UI rejection has a distinct, short, mix-prioritized cue.
Critical cues support captions such as:

- `[Breach from the east]`
- `[Root charge approaching]`
- `[Ally down behind you]`
- `[Dusk bell — 2 minutes]`
- `[Extraction gate closing]`

Captions describe function, not decorative sound unless the player enables full
ambient captions.

## Asset review gates

An asset cannot be approved only from a static render. It passes:

- gameplay-distance silhouette;
- day, dusk, night, and low-graphics visibility;
- mobile camera and touch-overlay composition;
- collision and navigation;
- streaming in/out;
- memory, triangles, draw calls, texture, lights, particles, and audio budget;
- color/shape accessibility;
- animation cancellation and replication;
- original-IP and license provenance.
