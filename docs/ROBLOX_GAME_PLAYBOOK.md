# Roblox game engineering playbook

This is the practical Roblox-specific companion to Last Light's architecture,
milestone, and release documents. It records lessons from building and
publishing another Rojo-managed experience so Last Light does not repeat the
same expensive mistakes.

Use this with:

- [DEVELOPMENT.md](DEVELOPMENT.md) for the pinned toolchain and commands.
- [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md) for services, networking,
  streaming, and authority contracts.
- [UX_MOBILE_ACCESSIBILITY.md](UX_MOBILE_ACCESSIBILITY.md) for mobile rules.
- [PUBLISHING_RUNBOOK.md](PUBLISHING_RUNBOOK.md) for private publishing gates.

## 1. Source, Studio, and place-file truth

The source tree is authoritative. Studio is an inspection and playtest surface,
not a second untracked source repository.

The safe loop is:

1. Synchronize clean local `main` with `origin/main`.
2. Create an `agent/*` branch.
3. Edit source and project mappings, not generated place files by hand.
4. Run the full validation suite.
5. Rebuild `build/LastLight.rbxlx` and `build/LastLightTest.rbxlx` from that
   exact source revision.
6. Commit the generated artifacts with the source change.
7. Push, open a PR, inspect the actual GitHub check rollup, and merge only after
   required checks pass.
8. Synchronize local `main`, then publish privately according to the runbook.

If a committed `.rbxlx` is part of the repository, CI must compare it with a
fresh Rojo build. A stale place opens normally in Studio while executing old
code.

Include a build fingerprint in the generated place. A missing or different
fingerprint proves the place was not built from the expected source. A matching
fingerprint proves source provenance only; it does not prove that Studio was not
edited afterward.

When behavior contradicts source, check the Git commit and build parity, the
runtime stamp in Studio output, and Studio-side edits or the published version.
Never claim that a publish, Studio run, or device test happened without direct
evidence. Merged, built, published, and human-tested are separate states.

## 2. Architecture and runtime generation

Keep services and modules narrow. Large all-in-one builders create the hard
Luau 200-local register limit, use-before-definition bugs, and changes too large
to review. Prefer one responsibility per ModuleScript in `src/shared`,
`src/server`, or `src/client`.

Use authored geometry for important rooms, set pieces, collision, and hero
landmarks. Use runtime generation for repetition and deterministic variation.
A hybrid is usually best: authored templates provide visual fidelity, server
generation places repeated content from stable definitions, deterministic seeds
make bugs reproducible, and generated content is validated before play.

Every generated interaction needs a failure path. Streaming can remove an
instance, a player can leave, a teleport can fail, a DataStore can be
unavailable, and an asset can refuse to load. Do not turn those cases into an
infinite yield or a stuck player.

Long generation loops must yield on a deliberate budget. Loading should make the
first playable area available without waiting for the whole world, and optional
content should stream or generate after the player can move.

## 3. Roblox API and Luau discipline

- Keep `GetService` and `require` calls at the top of a file.
- Make non-member functions `local`; do not create globals.
- Use explicit branches when `false` and `nil` are meaningful; avoid
  `x and y or z` for values that may be false.
- Use stable IDs for content, remotes, saves, products, and analytics events.
  Never silently reuse a shipped ID for a different meaning.
- Verify engine properties and callback signatures against the current Roblox
  API dump before relying on community examples.
- Treat `pcall` as error handling, not proof that an API is supported. A
  swallowed security or property error can leave a misleading state.

For a questionable API, check the dump and write a focused test or Studio
assertion before building a larger feature around it.

## 4. Geometry, meshes, and materials

Players notice recognizable physical objects. A tree, lantern, workbench, bridge,
or shrine made from unrelated boxes reads as placeholder content even when
lighting is polished. Use a coherent asset library and spend visual effort on
hero props, silhouettes, materials, and readable landmarks before adding more
decorative quantity.

`SurfaceAppearance` works on `MeshPart`, not a `SpecialMesh` fallback.
Runtime `AssetService:CreateMeshPartAsync` can produce a MeshPart, but it is
expensive and should happen once per unique variant, never once per placement.
Cache a template and clone it. A cloned MeshPart keeps its mesh and
SurfaceAppearance without another asset fetch.

Creator Store meshes are not normalized. Record the authored longest dimension
as `native`, declare the intended in-game longest dimension as `target`, and
derive:

```text
scale = target / native
```

Measure the actual mesh before adding it. Guessed scales can be wrong by an
order of magnitude. If a format is unsupported by the measuring tool, report it
as unmeasured rather than inventing a number.

When adding a variant, update the asset registry, measured-size fixture, theme
mapping that places it, generated-place checks, and visual/mobile review.

A legacy `TextureID` or marketplace `textureId` proves only that a diffuse
image exists. A real PBR review checks UV-compatible `ColorMap`,
`NormalMap`, `RoughnessMap`, and `MetalnessMap`. A generic texture cannot
safely be applied to an unrelated mesh because maps follow the mesh's UV layout.
Uploading an image is automatable through Open Cloud; authoring correct maps
requires a 3D tool and the actual mesh.

Roblox built-in materials already provide physically based behavior in many
cases. Weigh custom per-mesh PBR against its art-authoring cost instead of
treating built-in materials as no PBR.

For static decorative instances, prefer `Anchored = true`, `CanCollide =
false`, `CanTouch = false`, and `CanQuery = false) unless gameplay needs
otherwise. Use no shadows for tiny/distant props, Box collision for small
anchored geometry, and Automatic or Performance render fidelity.

## 5. Lighting, atmosphere, and presentation

Set renderer-selection properties declaratively in `default.project.json` or
Studio's Lighting properties. Do not assume a normal runtime Script can set
security-protected properties such as `LightingStyle` or legacy technology
selectors. A `pcall` around a forbidden write only hides the failure.

Tune lighting after geometry and materials are worth lighting. Test at low
quality as well as maximum quality. The next path, enemy telegraphs,
interactables, and safe retreat route must remain visible when quality drops.

Atmosphere density and haze can hide the route and dim the sky. Bloom should not
turn every bright hazard into screen-covering glare. DepthOfField should be
subtle. Local lights should have shadows disabled unless the shadow communicates
gameplay or a major landmark.

Feedback should support play: checkpoints, damage, downed state, revive,
extraction, crafting, rewards, and night escalation need distinct but readable
sound, particles, color, and motion cues.

## 6. Performance and streaming

Streaming is gameplay correctness, not just an optimization toggle. Keep the
arrival area playable while optional regions load. Do not preload the whole
Workspace; preload only loading-screen art, menus, and the first playable area.

Budget unique meshes, PBR materials, shadow lights, total parts, decorative
query participation, remote traffic, generation work per frame, Humanoids, NPC
animation, mobile memory, and join time.

Use `StreamingEnabled` and the declared project settings. Every interaction,
prompt, teleport, and cleanup path must tolerate a target streaming out or being
destroyed. Track join, stream, generation, teleport, and asset failures
separately.

Client-side tweens, VFX, camera effects, and UI are presentation. Shared state,
movement authority, rewards, damage, inventory, building, extraction, and
progression remain server-owned.

## 7. Moving platforms and hazards

Directly assigning an anchored platform's `CFrame` does not carry riders.
Physics sees the platform teleporting into the character, which reads as
bouncing, vibration, stuck movement, or a mobile-only failure.

For a moving platform, compute its full 3D delta, apply that delta to grounded
riders' root parts, whitelist grounded states rather than only excluding
`Jumping`, preserve player input, and test ascending, descending, stopping,
jumping off, respawning, keyboard, touch, controller, and multiple riders.

A `Jumping`-only check fails because Roblox transitions quickly to `Freefall).
Carry the full delta; a horizontal-only delta is zero for a vertical lift.

Kill floors and hazards need the same thoroughness. Audit every generated hazard
and fallback route, ensure the volume covers the playable fall, and verify that
death produces a safe checkpoint respawn instead of leaving a character inside
a hazard or below the world.

## 8. Mobile and input

Use one action semantic across touch, keyboard/mouse, and controller. Map the
same verbs through Roblox's Input Action System rather than three unrelated
gameplay rules.

Mobile rules:

- reserve Roblox's thumbstick and jump zones;
- keep touch targets thumb-sized and separated;
- use `CoreUISafeInsets` and account for notches;
- keep objective text and telegraphs readable at large text;
- place utility controls on the outer edge, not over movement controls;
- test portrait and landscape phones;
- classify compact phones by the short viewport edge, because landscape phones
  can be wider than a portrait breakpoint;
- avoid effects and HUD density that obscure the route or enemy attacks;
- retry audio after first interaction because mobile clients may block autoplay.

Desktop and tablet success does not establish phone success. Real-device runs are
required for jump/control overlap, safe areas, camera framing, audio, input
switching, streaming, and performance.

## 9. Server authority and remotes

The client sends requests. The server decides. Never trust a client claim for
currency, inventory, damage, rewards, progression, ownership, cooldowns,
teleport destinations, building placement, rescue state, extraction payloads,
or save completion.

The injected `player` argument to `OnServerEvent` is authoritative; all
other arguments are untrusted. For every remote, validate types, ranges, IDs,
ownership, state, distance, and phase; rate-limit by player and action; reject
impossible requests; send bounded deltas or snapshots; and clean up per-player
state on leave.

A client-side debounce is not security. Do not ship shared secrets in a
LocalScript. Avoid `RemoteFunction:InvokeClient` for server-critical work
because a malicious client can never return.

Be careful what is throttled. A duplicate action such as reset may be dropped.
A state message such as `sprinting = false) cannot be discarded or a fast
release can leave the player permanently sprinting. Record state on every
request and throttle only expensive work, with a trailing application of the
latest state.

## 10. Persistence and commerce

Use `UpdateAsync` for shared or monotonic state. `SetAsync` can overwrite a
newer result from another server. A stage, night, mastery, or ranking value must
merge with saved state inside the transform. Never admit a player with default
data after a failed load and later save it over their real profile.

For production, use session locking or a proven profile library, bounded retries,
shutdown flushing, schema migrations, and explicit failure telemetry. Studio
should not write production data.

Developer products are retried receipts, not ordinary button callbacks:

- one `MarketplaceService.ProcessReceipt` callback per place;
- one dispatcher by `ProductId);
- `receiptInfo.PurchaseId` as the idempotency key;
- purchase ledger and grant state in one atomic `UpdateAsync);
- `NotProcessedYet` on uncertain writes or absent players;
- never grant from an in-memory flag or client callback.

Use current async product APIs and the matching `InfoType). Prevent pointless
purchases in the UI, but do not hold a receipt forever after a valid charge.

## 11. Asset and Open Cloud safety

Creator Store search discovers candidates; it does not prove provenance,
geometry, collision, PBR, streaming behavior, or mobile suitability. Review
each asset's creator, license/provenance, thumbnail, actual model, bounds,
collision, memory, and camera composition.

Open Cloud can publish a verified place without Studio:

```text
POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published
x-api-key: <API key>
Content-Type: application/xml
body: generated .rbxlx
```

Verify with a read-only universe request first. Load keys from a local secret
file or environment variable. Never commit a key, Roblox session cookie,
`.ROBLOSECURITY), downloaded place binary, or production DataStore export.
Record the returned Roblox version with the commit, checks, and target place.

Publishing is not live verification. Join the intended private/staging place,
confirm the runtime stamp and environment, exercise the changed path, and check
server output for boot, save, remote, and streaming errors.

## 12. Professional finish checklist

Before calling a feature polished, verify:

- recognizable geometry and a coherent palette;
- intentional materials rather than default SmoothPlastic everywhere;
- indoor spaces that read as enclosed rooms when they are meant to be rooms;
- feedback for checkpoints, damage, death, revive, reward, purchase, and
  extraction;
- no utility control overlaps Roblox movement, jump, or CoreGui zones;
- success, failure, retry, and disconnect behavior;
- server validation and abuse limits before UI polish;
- low-end mobile, large text, controller, keyboard/mouse, and input switching;
- pure tests, generated-place assertions, Studio integration, and real-device
  evidence;
- source, build artifacts, GitHub checks, published version, and playtest result
  agree.

The standard is not “it ran once in Studio.” It is a reproducible source
revision, a verified generated place, an authoritative runtime path, and
evidence on the devices and network conditions Last Light promises to support.

