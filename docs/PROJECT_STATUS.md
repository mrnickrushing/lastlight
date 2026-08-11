# Project status

The living handoff between working sessions. **Read this first when starting a
session, and update it before you finish.** This project is developed across
many short AI-assisted sessions on more than one account; anything not written
here is invisible to the next session. The sibling repository learned this the
hard way — the same feature was once built twice in parallel because nothing
recorded that it was already in flight.

Last updated: 2026-08-11, at `main` = `7c06607` (PR #390), build `0.53.2`,
save schema 25, 27 services. The last published artifact remains Roblox place
version 171 from `5b7d4dd`; PRs #383 and #390 have not been published yet.
**#387 leaves Cinderfall shut for the third wave running, and closes the
last route anybody had left to try.** Play mode is unreachable on this
machine, and the two things that looked like ways around it are now
measured shut: the relay is provably healthy while `start_stop_play`
latches, and `user_mouse_input`/`user_keyboard_input` are
`datamodel_type` **`Client` only**, so they live inside Play rather than
leading to it (the evidence is in
[STUDIO_MCP_SETUP.md](STUDIO_MCP_SETUP.md)). It also records the thing
reading found instead: **the Hollow Below has no runtime at all**, so the
finale is a wave rather than a walk. #385 leaves Cinderfall shut for the
second wave running and names the same reason, and ships the arena label
defect that reading found instead, in the Crown *and* in Tempest, which is
already open. #384 wires Cinderfall's three encounters and fixes
the generation fallback that made one Crown run in fifteen the same fixed
layout, and deliberately leaves the region shut, because its live walk was
never finished.
`0.53.1` is published from PR #381, which gave every enemy a real light so
its authored PBR mesh renders solid at night instead of going black behind
only the ThreatOutline's rim — the owner's own description was "invisible
with a red line around them". (#380 left the built place byte-identical —
the place-version-167 documentation record for PR #379, no source under
`src/`.) `0.53.1` was also published from PR #379, which replaced the ten
crafting benches in Emberhollow with one Crafting Table station whose
interaction opens a client panel listing every recipe in the catalog — the
owner's own description of the old layout was "2345748357 of them". (#378
left the built place byte-identical — the place-version-166 documentation
record for PR #377, no source under `src/`.) `0.53.1` was also published
from the merged Bramblewake visual-bug-fix build in PR #377. (#376 left the
built place byte-identical — Studio-MCP wrapper and docs only, no source
under `src/`.)
(#364 added only documentation over v162, and #361/#362 only
documentation over v161.) (#358 produced v159 and #359
v160; those three are Milestone 13 wave D's closing batches, and each was
published before the next was started.) (This line used to say ``at `main` = `HEAD` ``,
and #354 is the wave that noticed `HEAD` is not a revision. The revision a
rollback restores is recorded properly in
[ROLLBACK.md](ROLLBACK.md#the-rollback-target).) (#352 leaves the built place
byte-identical, because it changes only manifests, validators and
documentation.) (#341 and #343 both left the built place
byte-identical, because they add only specs and documentation and the built
place carries no tests, so publishing either returned the version #340 had
already produced.) **The owner's standing directive: continue until the
game is completely done, then test — the buildable roadmap is finished, and
what remains in code is opening the six shut regions, each in the pull
request of its own live walk.** The queue
that makes that possible is
[WAVE_PLAN_M11_M14.md](WAVE_PLAN_M11_M14.md); read it second. Studio is
available and driven from the terminal (launch recipe in the M7 runbook);
Studio-facing checks not performed are recorded open rather than assumed.

**Milestone 13's buildable half is complete — waves A through E all shipped**, and
with it **the whole buildable roadmap**. A (cohort-scoped flags), B (tuning
telemetry), C (tuning knobs) and E (kill switches and the rollback list) were
already done. **D, localization source coverage, closed in five batches**, and the
reason it sat unbuilt through two sessions was addressed rather than ignored: the
guard landed *first*, with the 91 unmigrated files named individually and the count
pinned so it could only shrink. It stands at **one file** now, and one is the floor
— the loading screen runs before the shared root replicates and cannot reach the
table without blocking on the thing it exists to cover. Three further files are
declared *not player-facing* on a separate list with their readers named.
`Strings.luau` holds **2,621 source strings**, which is the number the language
decision is made on.
**Milestone 14's buildable half is complete — waves A through E all shipped.**

**There is no code work left in the buildable roadmap.** What remains is the
owner-gated list at the end of [WAVE_PLAN_M11_M14.md](WAVE_PLAN_M11_M14.md), read
out of QA_RELEASE_PLAN.md's 40-row checklist, of which 32 are open and every one
needs a person.

**Milestones 0 through 11 are complete, and so is Milestone 12's buildable
half** — M11 waves A through J and M12 waves A through E all shipped. What M12
still owes is the part no code produces, and the wave plan has said so since it
was written: daily full-path playtests with humans in them, the device lab, a
long-session soak on real hardware, narrative and content review,
production-like services and representative concurrency. The waves built the
instruments those gates are read from; the readings are the owner's. The plan is honest about the thing that makes M12–M14
different from everything before them: **an internal alpha needs players, a
closed beta needs cohorts and devices, and a launch candidate needs store
review** — so those milestones are mostly a list of owner-gated blockers with
a smaller list of buildable waves whose whole job is to make the human half
measurable. It also settles the cosmetic store's architecture before any store
code exists, because `scripts/validate_monetization.py` asserts there is no
purchase or ownership branch in gameplay code and that guard has to survive
M11 rather than be widened by it.

**Milestones 7, 8 and 9 are complete.** The story runs end to end: seven
chapters, seven regions, an authored finale with three endings, an
epilogue that reads the whole save, 27 residents and all 28 buildings.
**Milestone 10 is complete, and so is the roadmap through M10.** Waves
A-1 through A-3, B, C and D all shipped; both census gaps closed. The
game has seven chapters, seven regions, an authored finale with three
endings, an epilogue that reads the whole save, 27 residents in 28
buildings, 130 recipes, 33 quests in arcs, and 20 memory fragments across
six regions.

**Two counts were moved rather than met**, both with the reasoning
recorded in CONTENT_CATALOG.md and both asserted by `ContentCensus.spec`
so they cannot drift: recipes from 180 to 130 (the original allocation
assumed craftable tools, town project components, trap devices and
companion utilities, none of which are recipe categories here), and the
quest table from eight families to what exists (three of the eight were
other systems wearing the word "quest").

Since then the two quest families that were waiting on a *dependency*
rather than a design decision have shipped: seven mastery trials and six
region mysteries, on keyed objectives (an objective can name a profession
or a region, and only that one's progress counts). 46 quests.

**What is left is written in the catalog's own tables**, and the two
remaining quest families are the honest kind of missing: contracts need a
generator and crises need `ResidentLife.crisis` to become quest-shaped,
and neither system exists. Resident arcs past chapter one's three are
catalog-only work now that sequencing exists — an entry with `residentId`
and `requires` is a new stage and nothing else has to change.

Newest first since the last header:
- **#390** **The Module 1-2 placement follow-up removes the defects that survived
  #388's wider Bramblewake repair.** The arrival arch and both lanterns now
  treat their procedural constructions as replacement fallbacks, so successful
  authored meshes no longer double-render over them while their invisible
  collision remains. The orchard reserves the road plus both encounter
  sockets with four irregular verge trees instead of a collidable 3-by-3 grid,
  and its redundant deadfall is gone. The root chapel keeps its purpose-built
  chapel mesh instead of stacking the full hollow-shrine structure in the same
  footprint. Module 1's arrival landmark replaces the nearby duplicate route
  sign. `npm test` passes with **944 Luau tests**, both generated places were
  rebuilt from the exact branch source, and the built DataModel and rollback
  verification both pass. The latest place was opened from the terminal in
  Studio, but the managed MCP transport was reset during the required Wine
  teardown; do not claim a post-fix Play walk until a fresh MCP client attaches.
- **#388** (v171) **The complete physical
  Bramblewake walk found route, readability, feedback and performance defects,
  and build `0.53.2` repairs them as one coherent pass.** The source clears tall
  procedural collision at every module seam, moves the first resource prompt
  away from the first relay, extends carried Rootfire from 18 to 30 seconds,
  makes overtime recovery explicit, and replaces the false successful-return
  Mara line after an unfinished Blackout. It also corrects the inverted lantern
  cap and forest sign subparts, seats bridge interactions on the bridge deck,
  reduces camera-blocking and shadow-casting dressing, strengthens the farm
  landmark, and scales back the Wayhome gate's neon beacon. The phone Blackout
  HUD is shorter and removes duplicate detail while the crisis rail is active.

  The generated-place budget drops from 2,600 to 2,200 parts. The wrapper's
  executable-stub suite now works when the desktop TMPDIR is mounted `noexec`,
  and all 21 Wine/Vinegar launch cases pass. A fresh Codex-owned stdio session
  listed and selected the open `LastLight.rbxlx` Studio and queried its live
  Client/Server DataModels; the already-running Play DataModel is the older
  `0.53.1`/18-second build, so it is retained only as pre-fix evidence rather
  than mislabeled as post-fix verification. The merged commit `e59f7ae` passed
  the complete suite again on synchronized `main`, and Open Cloud published
  that exact regenerated artifact to start place `115897110071287` as **place
  version 171**.
- **#387** **The Crown stays shut a third time, and this wave spends itself
  proving there is no way round rather than looking for one.** Cinderfall was
  queued to open again. `Regions.luau`, `RegionBuilders.walkable`, the feature
  flag and its rollout stage are all untouched, and the four specs that pin the
  open set by name still pin five. **A region never ships enabled but unwalked**,
  and this is the third session in a row where the walk could not be started at
  all.

  **Two clean attempts, and "clean" is the whole of the claim.** Each one was a
  full teardown (`pkill -9` on `RobloxStudioBeta.exe`, `StudioMCP.exe`,
  `wineserver`, `winedevice.exe`, `AutoSaves/*.rbxl` removed), a place rebuilt
  from this revision, a freshly launched Studio, **one** relay started and
  confirmed with `list_roblox_studios` before anything else, and **exactly one**
  `start_stop_play` call. Both latched. Studio stayed in Edit with `Available
  DataModels: Edit` throughout, and its own log recorded **no playtest activity
  whatsoever** — no Play DataModel, no plugin load for one, only session
  heartbeats and autosave ticks. It is not trying and failing; the request
  reaches nothing.

  **The relay theory is now disproved rather than untested, and that matters
  because it was the best hope going in.** #385 established that the relay must
  outlive individual tool calls, which is true and stays in the runbook. It is
  not this. While `start_stop_play` sat outstanding, `get_studio_state`,
  `execute_luau` and `list_roblox_studios` each answered in under a second,
  repeatedly, for the whole of both attempts. A dead relay fails *every* call;
  this fails exactly one, which is how you tell them apart and why the two were
  confused for a session and a half.

  **The find that actually closes the question is one line of a tool schema.**
  `user_mouse_input` and `user_keyboard_input` both declare `datamodel_type`
  with `"enum": ["Client"]` — one permitted value, and the Client DataModel does
  not exist in Edit mode. Their own descriptions say to use `start_stop_play`
  first. **They are downstream of the broken call, not around it.** The natural
  reading of the earlier successful walks is the exact opposite — those sessions
  really did drive Bramblewake, the Delve, the Fen, the Reach and the Vale with
  these tools — but every one of them was already in Play before it touched one.
  There is no second door, and the next session should not spend itself looking
  for one. `execute_luau` does run at **plugin security** (`settings()`,
  `StudioService` and `RunService.Run` are all reachable), which is a wider
  surface than anyone had claimed and still not a way in: `RunService:Run()` is
  simulation inside the Edit DataModel with no client, and nothing at plugin
  level can manufacture a `LocalPlayer`. A walk needs a character to stand
  somewhere and a prompt pressed by one.

  **What reading found instead is bigger than the Crown, and it was queued as if
  it were small.** The Hollow Below was next on the list after Cinderfall, on
  the understanding that its encounter logic had already been driven through all
  five scenes to all three endings and only a live walk was missing. The logic
  has been; the walk is not what is missing. **Nothing in the running game can
  reach the Hollow**, because nothing in the running game knows about it.
  `NamelessNightEncounter` is required by `SaveSchema` (which reserves its
  fields) and `Epilogue` (which reads them) and **by nothing else in `src`** —
  no service among the 27, no builder, no `RegionBuilders` entry at all, so
  `RegionBuilders.readiness("region_hollow")` answers `unknown region` rather
  than `walkable = false`. `RegionEncounterWiring` handles five regions and the
  Hollow is not one; `boss_nameless_night` appears in the chapter catalog, the
  finale definition and its own module, and in no wiring anywhere.
  `RegionExpeditionAssembly` names the region only to give it a display string.
  So the finale is **content without a runtime**: fully authored — five scenes,
  its points of interest, three endings, chapter seven — fully saved, fully read
  by the epilogue, and unreachable. That is the shape this project has paid for
  four times already (120 recipes with no bench, 24 residents with no body,
  ninety craftable items with no equip button, the 55 localization keys nothing
  resolves), and it is worth writing down loudly: **the Hollow is a wave, not a
  walk**, and no amount of Play mode would have produced one this session.

  Nothing under `src/` changes here, so the built place is byte-identical to the
  one #386 published and place version 170 still stands. **942 Luau tests**,
  every repository validator green.

  **Open, and now needing a person rather than another attempt:** Play mode
  cannot be entered from a session on this seat, by any route that exists —
  `start_stop_play` latches with the relay healthy and Studio idle, the native
  input tools are `Client`-only and so live inside Play rather than leading to
  it, and OS-level injection is portal-gated shut (#385). **The Crown, and every
  region after it, needs somebody at the keyboard to press Play**, or a seat
  where input is not portal-gated. Three sessions have now confirmed this from
  three different directions and the cost of a fourth is a whole session.

  **Open, and larger than it was queued as:** the Hollow Below has no runtime.
  It is authored, saved and read by the epilogue, and no service, builder,
  encounter wiring or region-builder entry knows it exists, so it cannot be
  reached in any build regardless of Play mode. Chapter seven is unreachable and
  the game therefore has no ending a player can arrive at. Building that runtime
  is the last real feature in the project and it was not on the queue, because
  the finale's own module passing its specs read as the finale being finished.
- **#386** (v170) The place-version record for #385. The merged commit `cf55c16`
  was rebuilt on synchronized `main`, passed 942 Luau tests and every repository
  validator, and Open Cloud published that artifact to start place
  `115897110071287` as **place version 170**. No source under `src/` changes
  here, so the built place is byte-identical to the one #385 produced.
- **#385** (v170) **The Crown stays shut a second time, and this session can say
  exactly why: there is no Play mode on this machine.** Cinderfall was queued to
  open again and it does not open here either. `Regions.luau`,
  `RegionBuilders.walkable`, the feature flag and its rollout stage are all
  untouched, and the specs that pin the open set still pin five. **A region never
  ships enabled but unwalked**, and the walk was not merely unfinished this
  time — it was unstartable.

  **The blocker was found rather than suffered, and it is written down so the
  next session does not pay for it again.** Two facts, both measured:

  *The relay hosts the socket; Studio dials it.* Studio's own log shows it
  retrying `http://localhost:13469/studio` every three seconds forever, and
  `StudioMCP.exe` is what listens there. So the MCP server process has to
  **outlive individual tool calls** — a relay that exits between calls tears the
  host down before Studio finishes connecting, and every call answers `Not
  connected to the WS host`, which is indistinguishable from a Studio still
  loading its place. That is the whole of last session's "Studio stopped
  responding". A long-lived session connects on the first try. And a latched
  `start_stop_play` is cleared by **restarting the relay, not Studio**, which the
  last handoff had recorded the other way round.

  *No synthetic input reaches Studio at all.* This desktop is KDE on Wayland with
  a rootless Xwayland started `-enable-ei-portal`. `xdotool key --window`
  (XSendEvent), plain `xdotool key` (XTEST) and a real `/dev/uinput` virtual
  keyboard all land nowhere — and the uinput device is genuinely created and
  seated, `Handlers=kbd mouse2 event17`. Two witnesses confirm it never reaches
  the compositor rather than being dropped by Studio: Studio logs `No user input
  within the last 5000 ms` throughout, and **KDE's own Meta key does not open the
  launcher**. The trap is that the pointer half of XTEST works — `mousemove`
  moves the cursor and reports the new position — so input looks alive while
  every keystroke goes nowhere. XTEST is portal-gated, and granting the portal
  needs a dialog only somebody at the keyboard can click. So `F5` cannot be
  pressed, `start_stop_play` answers `Start play hasn't finished yet` forever,
  and **Play mode is unreachable — which means no live walk, for any region,
  from a session in this state.**

  **What Edit mode could still prove, and it is more than reading.** The Crown
  was built for real inside Roblox's own VM through `RegionExpeditionAssembly`:
  12 modules, 653 parts, 752 descendants, 22 harvest nodes, 19 event step
  interactions, the three encounter sites, the rim and the wayfinding, `Ready`
  true. **500 seeds swept in the engine rather than in Lune: 0 fallbacks, 500
  distinct layouts, and both memory-bearing points of interest present in every
  single run** — #384's generation fix holding where it actually ships. All three
  fights were driven through their real wiring handlers to completion: the Actor
  named its called beat every round (`ANSWER THE LINE — 1 OF 3 · IT CALLS THE
  TURN`) and its missed-beat line (`THE LINE STARTS AGAIN FROM THE TOP · IT CALLS
  THE BOW`), the Bailiff named its mark on a wrong appeal (`IT MARKED THE WEST
  ARCADE`), and the Regent resolved chapter six **three different ways** —
  `spared_memories/remembered`, `broke_some/recast`, `broke_them_all/erased`,
  every one of them the decision and outcome the catalog names. That is the
  Lantern Witch's unreachable `sealed` answered in the opposite direction: this
  chapter's three endings are all actually reachable. Screenshots at player
  height in day and dusk; the rim ends every sightline and the Delve's
  pale-blank dusk wash does not recur.

  **It is not a walk, and the difference is the point.** No player character, no
  server-validated interaction, no real click, no departure board press, no
  extraction. Which is exactly why the flag did not move.

  **The find is a defect nobody could have counted, in a region that is already
  open.** An arena labels each anchor with what it is, which is enough only while
  no two anchors in a ring are the same thing. The Regent's box is the first that
  breaks it: reading a statue and breaking it are deliberately separate anchors
  and they name the same statue, so the ring built **ten pillars carrying five
  names twice over** — and one of each pair is a free look while the other is the
  chapter's irreversible decision, standing side by side. That is #363's "four
  identical unlabelled pillars" returning with labels on. Writing the spec then
  caught the same defect **in Tempest, which shipped open after a live walk**:
  the Titan's `EASE`/`SLAM` tide gates have read identically since the Reach
  opened, and nobody filed it. The verb joins the label only where the object is
  ambiguous, so every ring already walked reads exactly as it was walked; the
  decision moved into `RegionEncounterWiring.anchorLabels` because the assembly
  builds Instances and the suite cannot. **The first draft of that spec was a
  list of regions and the list was wrong**, which is how Tempest was found.

  **The three defects #384 recorded are fixed.** The departure toast reads the
  region the world actually raised instead of saying `LEFT FOR EMBERHOLLOW` on
  every departure. The boss-unlock toast asks the boss what to call itself
  (`ASH REGENT HAS STOPPED WAITING`) instead of `SOMETHING BELOW`, which was
  written for the Maw and inherited by a Crown whose boss is above you. And the
  seventh destination plank clears the floor — **and the earlier measurement was
  itself wrong**: it measured `LodgeFloor`'s 1.00 slab top and missed
  `LodgeFloorPlank`, 0.08-thick boards centred at 1.02, so the surface a player
  stands on is 1.06. Only the origin moves, the pitch is unchanged, and the
  seventh plank now has 0.19 studs of daylight under it. **942 Luau tests**,
  every repository validator green. `npm run check`'s Wine wrapper suite fails
  19/21 in this sandbox and **fails identically on unmodified `main`** — the
  #377 precedent, an environment gap rather than the change.
- **#384** **The Crown's fights are wired and its region generates — and the
  Crown stays shut, because nobody walked it.** Cinderfall was queued to open
  and it does not open here. Studio stopped opening a window partway through
  the session and did not come back, so the walk was never finished, so the
  flag never moved: `Regions.luau`, `RegionBuilders.walkable`, the feature flag
  and its rollout stage are all where they were, and the specs that pin the
  open set still pin five. **A region never ships enabled but unwalked**, and a
  session that cannot finish the walk ships the preparation instead — which is
  what #363 did for Mireglass, whose wiring landed disabled one wave early.

  **The half-walk that did happen paid for itself.** A live server raised the
  region and reported `Source=known_good_fallback` — what `ExpeditionGenerator`
  answers with after three assemble attempts fail validation. Measured across
  seeds, the Crown fell back on **132 in 2,000**; Bramblewake, the Delve, the
  Fen, the Reach and the Vale fall back on **none**. The cause is authoring
  density rather than logic: a run draws twelve modules that must seat four
  points of interest and eight events between them, and the Crown carried
  point-of-interest sockets on **13 of its 30** modules and event sockets on 24,
  where every earlier region carries **20 and 27**. At the sibling density it
  generates on 2,000 seeds out of 2,000. Only the arrival, the extraction and
  the Regent's approach stay socketless, for the reason they do everywhere.

  **What a player lost was variety rather than correctness, which is why
  nothing ever reported it.** The fallback layout is valid by construction, so
  it walks fine; it is simply the same walk every time for whoever drew an
  unlucky seed. **The Crown's own 2,000-seed sweep was green throughout**,
  because it asked whether the manifest it got back was valid and never whether
  it was the one the generator meant to build — a check passing at exactly the
  moment the thing it covers is broken, which is #356's and #358's lesson
  arriving from a third direction. It asks both now, and
  `RegionBuilderCoverage` holds the same rule over the whole open set, because
  whatever joins that set next has to arrive generating.

  **Three wiring finds, all from reading the modules rather than from a spec.**
  The Lead Actor's called beat and the Glass Bailiff's marked structure both
  ride in snapshots no client reads — unspoken, each arena is a row of
  identical prompts under an instruction that only counts, which is the Vale's
  aurora order again, twice, and the Actor's own module insists its line is
  announced "loudly, in order". Both are named in the message now. Reading a
  statue is the only thing in the Crown that costs nothing but time, and the
  Regent's instruction counts anchors and nothing else, so a read wired through
  the generic wrapper would answer exactly like a read that did nothing — and
  knowing which statues are real before breaking them is the fight's whole
  argument. What a read learned is spoken; breaking is its own anchor, because
  breaking a true one is the chapter's decision and cannot be taken back.
  Three clocks live in the wiring the way the Admiral's re-rig and the Hart's
  split do, and the Bailiff's three waits are covered by two tuning values, so
  the unnamed one takes `sentenceSeconds` as well: the opening a party buys is
  as long as the sentence it paid a wall for. Both memory-bearing points of
  interest are pinned into every generated run, the rule the Reach's walk paid
  for.

  **Verified live before Studio died:** the destination board built the Crown's
  plank and pressing it returned `THE ROAD NOW LEADS TO CINDERFALL CROWN`; the
  departure refusals and countdown are real; the region assembled with 12
  modules, 691 parts, 1,131 descendants, `ExtractionReady=true`, both memory
  fragment models and the Regent's box site present. **Not verified, and so not
  shipped open:** route seams, a gather, a POI, an event's steps, either
  fragment recovered, either elite, the Regent's phase chain, the chapter
  decision, extraction, and any screenshot at player height in day or dusk.

  **Open, recorded rather than fixed:** the destination board's seventh plank
  (`THE HOLLOW`) sits at y=1.45 with a 1.3-stud plank, so its bottom is 0.80
  against a lodge floor whose top is 1.00 — 0.2 studs buried, the Delve-walk
  defect returning one plank later, and measured rather than looked at, so it
  is recorded instead of blind-fixed. `toast.the_party_of_n_has_left` reads
  `THE PARTY OF %d HAS LEFT FOR EMBERHOLLOW` on every departure regardless of
  destination. And the boss-unlock toast is `SOMETHING BELOW HAS STOPPED
  WAITING` for every region, which reads oddly in a Crown whose boss is above
  you in its box. **940 Luau tests**, `npm run check` a full pass including the
  Studio-MCP wrapper suite at 21/21.

  **A note for the next session, because it cost this one most of its time:**
  Studio's own `start_stop_play` MCP tool never completes in this environment —
  it returns `Start play hasn't finished yet` forever and latches, so only a
  Studio restart clears it. What does work is `xdotool key --window <wid> F5`.
  Plain `xdotool click`/`type` without `--window` reach nothing under this
  Wayland session; `--window` sends the event to the window directly and Wine
  accepts it. Studio also needs a full teardown (`pkill -9` on
  `RobloxStudioBeta.exe`, `StudioMCP.exe`, `wineserver`, `winedevice`) and a
  pause before relaunching, or it comes up with no window and never registers
  with the MCP relay.
- **#381** (v168) **Enemies render solid at night now, not an outline around
  nothing.** The owner's report: "the monsters look like they are invisible
  with a red line around them." Reproduced and root-caused live in Studio
  rather than guessed at: every authored enemy mesh is a PBR
  `SurfaceAppearance` MeshPart (Meshy-generated, `preserveSourceMaterials =
  true`), and that surface renders correctly under the day sun but solid
  black at night no matter how bright `Lighting.Ambient`/`OutdoorAmbient`
  are set — pushed both to pure white with zero effect. Those two
  properties light the plain fallback parts fine, which is why nobody ever
  reported the fallback silhouette itself as broken; a PBR mesh needs a
  real light source, and past the sun's night hours there wasn't one
  anywhere on the creature. The `ThreatOutline` Highlight added earlier for
  the same "disappearing at night" complaint is a screen overlay
  independent of scene lighting, so it kept rendering fine regardless —
  the outline was never the bug, the unlit body inside it was.
  `BramblewakeEnemyBuilder` now gives every enemy a `PointLight`, anchored
  just above the creature rather than parented into `core` directly: dead
  centre lit the (small) rootling fine and did nothing for the (wider)
  briarback even far past a sane brightness, because a light buried inside
  a wide enough body has no line of sight to its own outward-facing
  surface. Anchored above and scaled off each species' own `core.Size.Y`,
  it reached both, confirmed live through the real player camera across
  five enemy sizes. This is the one shared builder every enemy in the game
  uses — town night defense, Bramblewake, and Old Growth's elite — so the
  fix is not Bramblewake-specific despite the file's name. Full local
  validation passes: 935 Luau tests, format, lint, typecheck, every
  repository validator, both regenerated places, built-DataModel
  verification and the rollback build. The exact merged commit `0dfb7c2`
  was rebuilt and passed the full suite again on synchronized `main`, then
  Open Cloud published that artifact to start place `115897110071287` as
  place version 168.
- **#379** (v167) **The ten crafting benches in Emberhollow are one Crafting
  Table now.** The owner's own words for the old layout: "2345748357 of
  them." It was ten, and `WorldService`'s own comments already recorded why
  ten was itself a second attempt — a bench derived per recipe (130 of
  them) closed the "120 recipes nobody can craft" gap and broke something
  worse, a furniture maze whose click volumes swallowed the tutorial's first
  prompt; ten authored sample benches fixed the maze but still read, on an
  actual Studio walkthrough, as a conveyor belt of near-identical stalls.
  Both were the wrong shape for the same reason a hundred and thirty
  recipes do not need a hundred and thirty pieces of furniture — they need
  a menu. One `CraftingStation` model (workbench, an open ledger standing
  for "browse the catalog" rather than any one recipe's silhouette, a tool
  rack) now carries a single interaction; `Actions.CraftItem` carries a real
  client-chosen `recipeId` instead of a prompt attribute, validated by
  `ActionPayloadContract` the same way `StorePurchase`'s `productId` is and
  re-checked server-side before anything crafts. `HUDController` gained a
  crafting panel — a flat scrollable list built from `CraftingCatalog.list()`
  (no category field exists to group by), each row showing the recipe's
  output name, its materials derived from the catalog's own already-readable
  ids rather than a second name table that could drift, and a CRAFT button
  that greys out and explains itself when the bank can't afford it. Three
  specs that had encoded the ten-bench shape as correct were rewritten;
  `ContentCensus`'s own reachability case had said in its own comment "if a
  crafting menu shipped this should be zero and this case should check
  that" — it now does. Full local validation passes: 935 Luau tests,
  format, lint, typecheck, every repository validator, both regenerated
  places, built-DataModel verification and the rollback build. The exact
  merged commit `5e596ed` was rebuilt and passed the full suite again on
  synchronized `main`, then Open Cloud published that artifact to start
  place `115897110071287` as place version 167.
- **#377** (v166) **Three visual bugs from a live Studio walkthrough of
  Bramblewake, found and fixed by Claude connected to the same Studio MCP
  relay #374 and #376 used.** The Hungry Homestead's Water Cask was an
  un-rotated `Cylinder` (its long axis is local X, not Y) lying on its side
  and sinking roughly half its body through the porch floor; it and its two
  neighbors (Seed Bin, Root Cellar) now sit flush against the porch's
  measured surface. Blackout's relay fire and Old Growth's fire/heart labels
  were readable at full distance long before either system activates —
  `setBlackoutPresentation`/`setOldGrowthPresentation` already gated the
  prompt and material on `relay`/`shielded`, but the `LandmarkLabel`
  billboard wasn't wired to the same state, so a player could read "NEEDS
  CARRIED FIRE" at the arrival gate hours before Blackout is explained; now
  gated identically. The Moving Hedge event's whole visible objective sits
  boxed in by trees with no direct light reaching it; `Grass` material's
  normal map crushed to a flat black slab under ambient-only light, so it
  and its crown now use `LeafyGrass`, the material every hero tree canopy in
  the same file already uses for exactly that reason, at no light-budget
  cost. Full local validation passes: 935 Luau tests, format, lint,
  typecheck, every repository validator, both regenerated places, and
  built-DataModel verification. The one failure in
  `test-studio-mcp-wrapper.sh` (wine-dependent) reproduces identically on
  unmodified `main` and is this sandbox's environment, not the change. The
  exact merged commit `e080ba2` was rebuilt and passed the full suite again
  on synchronized `main`, then Open Cloud published that artifact to start
  place `115897110071287` as place version 166.
- **#376** hardens the Studio-MCP wrapper's batch fallback, the route #370's
  direct-exe launch does not take when Roblox's `mcp.bat` cannot be parsed for
  its `StudioMCP.exe` path. That fallback still built a host-translated `cd /d
  "Z:\..."` for the common case, the exact string #370 proved Wine's `cmd.exe`
  refuses — it now hands Wine the literal, unresolved `%LOCALAPPDATA%\Roblox`
  and lets Wine expand its own variable instead, for every discovery path that
  is that variable by construction. Codex then found the one construction that
  is not: a plain Wine prefix can hold more than one Windows user profile, and
  the `drive_c/users/*` glob can match a stale one while Wine's own
  `%LOCALAPPDATA%` currently answers for someone else — discovery succeeding
  is then not the same as the literal being safe, and using it anyway would
  make launch fail for a reason discovery gave no sign of. That one candidate
  is now checked against Wine's own answer before being trusted; every other
  candidate is unambiguous (a Vinegar install has exactly one appdata
  directory) and skips the check. The reported case was reproduced
  (`bat_is_localappdata_roblox=true` forced past the check picks the wrong
  user's directory) before being fixed, and the fixture suite that had used an
  unconfirmed single-user match to test the literal path was corrected to
  actually confirm it, the way a real single-user Wine would. Suite: 21/21.
- **#374** (v165) **Bramblewake's complete Studio walkthrough closes the defects it
  found instead of only recording them.** Codex connected to the same live
  Studio MCP relay as Claude, walked the generated route end to end, harvested
  and banked Amber Sap exactly once, completed Stag Tracks, the three blackout
  relays, Old Growth, the preserved Warden Stag route and Shared Agroforest,
  and exercised combat, dodge, downing, retreat, re-entry, rewards and chapter
  resolution through the real server-validated interactions. The visual pass
  reduces harvest labels from horizon-filling cards to compact nearby
  confirmations and rebuilds the distant canopy as overlapping forest ranks
  rather than sparse ball-on-stick silhouettes. The departure panel now names
  party size and route contract, explains every contract, summarizes the two
  choices together and marks selection without relying on color alone. It fits
  both desktop and a simulated Samsung Galaxy A06 landscape safe viewport;
  scene analysis measured 351,962 opaque triangles and 230 draws. Full local
  validation passes: **935 Luau tests**, format, lint, typecheck, all repository
  validators, both regenerated places, built-DataModel verification and the
  rollback build. The exact merged commit `ab4dfedcb1c2` was rebuilt and passed
  the full suite on synchronized `main`, then Open Cloud published that artifact
  to start place `115897110071287` as place version 165.
- **#371** (v164) **Frostmere Vale opens after its live
  end-to-end walk.** The region flag and builder walkability switch are on,
  chapter-five access is pinned beside the Delve, Fen and Reach, and the two
  memory-bearing points of interest are fixed into every generated Vale run so
  their story fragments cannot disappear behind sampling. The shared encounter
  seam now wires the Abbey Silence, Aurora Hart and White Howler through their
  own anchors, windows, clocks, ordered verbs and chapter-five warmth outcome;
  the durable specs drive all three rather than merely checking that their
  tables exist. The restored work applied over current `main` with no conflicts.
  Full local validation passes: **935 Luau tests**, format, lint, typecheck, all
  repository validators, both freshly regenerated place files, built-DataModel
  verification and rollback-build verification.
- **#370** fixes the last measured Linux Studio-MCP launch failure. Wine's
  `cmd.exe` could enumerate Vinegar's redirected `Z:` path but returned `Path
  not found` for the wrapper's quoted `cd /d`, while invoking the exact
  `StudioMCP.exe` named by Roblox's generated `mcp.bat` completed the MCP
  handshake. The wrapper now resolves and launches that exact versioned
  executable, retaining the batch route only as a fallback. Its suite is 12/12,
  a real initialize returned `RobloxStudio` 1.0.0 on protocol 2025-06-18,
  Claude reports the server connected, and a fresh Codex session completed
  `roblox-studio/list_roblox_studios`. Both clients now use the same wrapper.
- **#369** corrected launcher discovery to Roblox's generated `mcp.bat`, tied
  every candidate to the selected Vinegar/Wine prefix, and added the isolated
  layout suite that made the remaining runtime-only failure reproducible on the
  owner's machine.
- **#365** (v163) **The Mireglass Fen opens, walked live through the seam the Delve
  built - and the seam held.** No new machinery: the Fen's flags flip, its walkable
  bit flips, and the by-name open-set pins take a third member. Every fix the
  Delve's walk paid for generalized unchanged - fragments seated on the ground,
  labels short enough to stay apart, route corridors cut open, the rim ending every
  sightline - which is the argument the seam was built on, now with a second region
  as evidence.

  **The one code change the Fen forced was found by reading, before the walk could
  trip it.** The Lantern Witch's module exports no `strike` at all - her fight is
  naming and mercy - and the strike router called `module.strike` unconditionally,
  so a swing inside her ring was a nil call on a live server. A strike at a fight
  that takes none earns the fight's own instruction now.

  **Walked live end to end before the merge**: the board turned the road to the Fen,
  arrival on a boardwalk over water glassy enough to mirror the sky, a mirror-reed
  gather, the Sinking House shored beam by beam for bog iron, the ferryman's tally
  read at the Ferry Ledger, the Many-Face stripped mirror by mirror inside its
  counter windows, the Drowned Caller's four doors silted shut, the Witch unlocking,
  named through three rounds of false lanterns, spent to her question and granted
  the seal - `region_chapter_resolved chapter=chapter_three decision=spent_copies
  outcome=bound` - and a Wayhome extraction banking fifteen materials.

  **`RegionEncounterWiring.spec` is the durable half, and writing it caught its own
  gap by the count.** Handlers and anchors cover each other in both directions in
  both regions, the Delve's fights drive to exposure through their own levers and
  lines, and the Witch reaches her question with both answers resolving chapter
  three against the catalog. The suite stayed at 919 after the spec was written -
  `tests/run.luau` is an explicit list, and a spec nobody requires is a spec nobody
  runs. It is in the list, and the count says 922.

  **Open, recorded as design questions rather than defects:** the Witch's `sealed`
  outcome - the `spared_copies` decision - is unreachable by her own state machine,
  because sparing returns her to hiding without advancing the phase, so chapter III
  can end `bound` or `broken` but never `sealed`; whether mercy should advance a
  phase is the owner's call. The fen banks crossing route corridors stand 2.4
  studs - under the corridor cutter's height floor, over a walking step, jumpable,
  and reading as fen rather than fence. And the extra swing after any encounter
  completes still falls through to the roster's "the tool is calm in daylight,"
  which is true and reads odd standing over a sealed witch.
- **#363** (v162) **The region assembly seam, and the Ironroot Delve opens — the first
  region since Bramblewake a player can actually walk.** Every region after the
  forest had all of its content and none of it reachable, and the recorded gap
  ("authored mesh dressing") stood in front of an unrecorded one: `ExpeditionService`
  asserted Bramblewake by name at boot, `WorldService` built the forest
  unconditionally, and nothing anywhere called `RegionBuilders.buildModules`,
  `buildResourceNodes`, `buildPointsOfInterest`, `buildEventSockets`, `buildArena`,
  `buildWayfinding` or `RegionEncounterService.beginRun` — the shared pieces four
  waves built were functions with no caller. **The assembly that composes a region
  into a world a server can raise did not exist**, and no spec could see it, because
  every part of it a spec can read was correct.

  `RegionExpeditionAssembly` is that seam: full-cell ground under module floors
  that float inside their cells (the Delve's is 56 studs on a 72-stud cell, and the
  16-stud remainder was a fall out of the world), the region's own visuals, nodes,
  POIs, event sockets with their step anchors, wayfinding, an arrival sign, an
  extraction gate, one arena per encounter with a presence at its middle, and a rim
  wall on every outside cell edge. `RegionEncounterWiring` (shared, so Lune can hold
  a fight against its arena) maps each encounter's own id lists to anchors and
  verbs; every toast is the encounter's next instruction, the one string that cannot
  drift from the state machine. The service gained the strike router, the
  elite-to-boss unlock chain, per-participant settlement, and chapter resolution
  through `ProfileService.resolveChapter` — **a boss's completion is its chapter's
  resolution, and the decision is made inside the fight** (which vent, what was
  spared). The destination board in the departure lodge closes the M7 runbook's
  region-transition item: one plank per region, every gate re-checked where the
  press lands, the wood rebuilt only while nobody stands in it.

  **Walked live end to end before the flags flipped**, on the built place:
  destination press ("THE ROAD NOW LEADS TO IRONROOT DELVE"), arrival, a coalglass
  gather, the Gas Leak event by real clicks ("GAS LEAK — 1/3 … THE AIR CLEARS —
  +2 MACHINE OIL"), THE LAST SHIFT memory fragment, the Foreman Echo through two
  board seizes, the Iron Widow through four cuts and her grounded windows, the Maw
  unlocking itself ("SOMETHING BELOW HAS STOPPED WAITING") and dying through all
  three phases with `vent_stope` recorded — `region_chapter_resolved
  chapter=chapter_two decision=vent_stope outcome=cleared` — and a Wayhome
  extraction banking fourteen materials.

  **The walk found six defects and the fixes shipped in the same pull request**,
  every one of them the class no spec can see: the destination board's sixth plank
  level with the floor and its seventh inside it; billboard labels legible two full
  cells away stacking into one band of gold soup; **cut-rock canyons across the
  route seams**, because the Delve floor walls both X edges of every cell and
  nobody had ever walked between two cells; four identical unlabelled arena
  pillars; **both memory fragments seated on top of the shored roof**, nine studs
  above anyone who could read them, by a ground ray that starts fourteen studs up —
  above the region's own ceiling; and **a dusk that washed the whole region to a
  pale blank**, because unlike Bramblewake this world had no backdrop and the
  atmosphere had nothing to end a sightline on. The rim walls fixed the wash and
  the walk-off-the-world edge in one stroke. Everything changed was re-walked on a
  fresh boot before the merge.

  `LastLightStudioChapter` joins the Studio attributes (chapter progress through
  the real SaveSchema mutators, same three guards as the stock hook), because the
  region behind a chapter gate is now the thing a session verifies, and chapter I
  is a shipped, live-walked path. The specs that pinned "exactly one region
  enabled" pin the new truth by name: a region joins the open set only in the pull
  request of its own live walk. Ironroot's fragment-anchor POIs are pinned the way
  Bramblewake's are (and Mireglass's with them), so a story beat stops being a
  lottery ticket. **Open:** the Fen, the Reach, the Vale, the Crown and the Hollow
  stay shut behind the same gate; Mireglass is next, and its encounter wiring
  ships here already, disabled.
- **#360** **M13 wave D, batch five: the last catalogs, and the allowlist reaches its
  floor. Milestone 13's buildable half is complete, and so is the buildable
  roadmap.** 1,435 strings out of the thirteen files a player actually browses — 130
  recipes, 90 craftable items, the consumables, the tools and their traits, 27
  residents and everything they say, and all six expedition definitions with their
  landmarks, events and the sentence each one tells you before it kills you.
  **`Strings.luau` is 2,621 entries**, and that number is the answer to the question
  M13's deliverable list actually asks: *what does a language cost.*

  **The allowlist holds one file, and one is the floor rather than a shortfall.**
  `src/first/LoadingController.client.luau` runs from ReplicatedFirst to cover the
  wait for the shared root, and it only ever asks for the runtime with a
  non-blocking `FindFirstChild`. Requiring the table would mean
  `WaitForChild("LastLight")` — the loading screen blocking on the very replication
  it exists to hide, against its own first rule that *a player must never be trapped
  behind this screen*. Twelve strings, written where they are read, with the reason
  in the guard.

  **Three more files came off by a different argument, onto a different list.** The
  allowlist means *not yet*; `NOT_TRANSLATED` means *never*, and keeping them apart is
  the point — a reader who cannot tell them apart cannot tell whether this wave is
  done. `MusicCatalog`'s track titles and publishers are read by nothing (the
  controller takes `assetId`, `volume` and `intensity`), and the publisher is the
  field `validate_audio_assets.py` and ASSET_PROVENANCE.md hold the licence claim
  against, so translating it would **break an audit rather than serve a player**.
  `PerformanceBudget` and `SoakProbe` are metric labels in an admin readout and a soak
  report. It is the same judgement the guard already makes for anything handed to
  `warn`, arriving one seam later, because a label stored in a table and concatenated
  into a report is invisible from the call site. **Every entry names its reader**, and
  the count is pinned harder than the allowlist's, because "operator text" is exactly
  the sentence somebody reaches for when they want a string out of the way.

  **Four refusals exercised against the real files** before it shipped: a file on both
  lists, the not-translated count moved without the list, a file declared
  not-player-facing that holds no such text, and the allowlist emptied without
  lowering the pin.

  **Verified live**: all 116 shared modules load inside Roblox's own VM and all 2,621
  keys resolve non-empty there; the world settles at 13,931 descendants, subtree for
  subtree identical to the pre-wave baseline; 132 prompts and 209 labels with none
  empty and none showing a key; the joined prose reads as one sentence
  (`A family lived here until the roots came through the floor. The door is still
  barred from the inside.`) rather than as the two halves it was written in.

  **Open, and found by finishing:** the content registry has declared localization
  keys since Milestone 1 — `displayNameKey` on all seven regions,
  `localizationKey` on all 48 expedition events, **55 in total** — and **nothing
  resolves any of them**. `Registry.luau` and `ExpeditionEventFlow` assert only that
  the field is a non-empty string; no table defines the keys and nothing reads them
  for a word. It is the guard's own second rule one level up: a key nobody defined is
  a label wired to nothing, and here it is a whole naming convention wired to
  nothing, invisible to `validate_localization.py` because that check only follows
  `Strings.get`. Now that the table is complete, the choice is to point them at real
  keys or delete them, and both are a wave rather than a footnote — `Registry.luau`'s
  required-field list and its spec pin the shape.
- **#359** (v160) **M13 wave D, batch four: the content the world is made of — and a
  migration that had turned identifiers into translations.** 871 strings out of 51
  shared modules: every encounter, every enemy's attack and tell, the town's own
  systems, the store, the professions, the quests and the story. The allowlist goes
  **68 files to 17**, and what is left is the item catalogs, the residents, the six
  expedition definitions, three files that are not player-facing at all, and the
  loading screen.

  **The find is bigger than the batch.** Batches one and two moved four *identifiers*
  into the string table, and every one of them was then compared to decide what the
  game does — **24 sites**. `theme == Strings.get("world.miretide")` chose which night
  dressing the town raises and what colour the lantern road glows.
  `name == Strings.get("world.mara_s_shelter")` chose a cabin's wall colour, its prop
  seed and whether it gets a cot. `altar.name == Strings.get("world.engineer")` chose
  a mesh — and beside it, **`"profession_" .. string.lower(altar.name)` built the
  profession's id out of its signboard**, so a translated sign produces an attribute
  no lookup matches, and `seed = 9970 + #altar.name` moved a prop by the *length* of
  a translated word. `phase == Strings.get("hud.dusk")` chose the clock's accent.

  Every one of those is correct today and wrong the day somebody translates the
  string, in the localized build only, with nothing failing anywhere — **which is the
  precise failure this wave exists to prevent, created by this wave.** The whole point
  of one table is that a translator may change every string in it; nothing may be true
  only while a string stays in English.

  **So identifiers are identifiers again.** A night's theme is `emberfall`, not
  `EMBERFALL` — it was a table key in two modules, the value `WorldService` compares,
  *and* the word printed in "EMBERFALL NIGHT 3", and there is no version of one string
  doing both jobs that is right. `TownNightSchedule.displayName` is the word now. The
  cabins take a flag, the altars carry `id = "profession_scout"`, the clock compares
  the phase id.

  **And `validate_localization.py` refuses a `Strings.get` inside a comparison from
  this commit**, which is the durable half — the 24 sites were found by reading, and
  reading does not scale.

  **The portrait pass found the departure panel overflowing at its own floor**, which
  is #358's fix seen from the other side: eight party-size buttons at 44 points need
  422, and the floor was 260. It is the sum rather than a constant now. **Open:** a
  canvas narrower than 446 points still cannot fit that row, and no clamp can make it
   — the row has to wrap, which is a layout decision rather than a bound.
- **#358** (v159) **M13 wave D, batch three: the server surface, and the batch found the
  check reporting good news about files it could not read.** 483 strings out of the
  twenty server files — every announcement, refusal and confirmation the server pushes
  at a player, and the tutorial's own voice. The allowlist goes 88 files to **68**, and
  everything left in it is a content catalog.

  **Two things the migration could not have found by counting, and both were found by
  reading what it was about to move.**

  *A sentence assembled with `..` cannot be translated.* Thirty-one sites read
  `"THE " .. plot.displayName .. " SNARE IS ALREADY SET"`, and the half of that
  sentence beginning with a space is invisible to a check anchored on a capital
  letter — so a mechanical migration would have put `"THE "` in the table, left
  ` " SNARE IS ALREADY SET"` in the code, and reported the file clean. Worse than
  before: word order is exactly what a translator moves, and a fragment cannot be
  moved. They are `string.format` with one complete sentence each now.

  *A string that begins with a format specifier was invisible to the check.* Every
  test in `player_visible` starts by asking what the first character is, and `%d`
  is not a letter — so **48 live strings sat inside files this wave had already
  called covered**, including `"STAMINA · %d"` and `"LIGHT · %d%%"` on the HUD and
  `"TIER %d · %s"` in the town. The table meanwhile held `"STAMINA · 100"`, which
  is the *initial* value of the same label: **the migration moved the sample and
  left the sentence.** That is the half-migrated table looking finished from every
  direction except the one that matters, happening inside the wave that exists to
  prevent it. Specifiers are normalized to a letter before the string is judged
  now, and the four sample keys are gone — an initial label and a live one are one
  key with a number in it.

  **The guard could not read its own exemption, either.** Its diagnostic test read
  backwards along the line, so `assert(self:arena(), "...")` lost the `assert` at the
  inner call's closing paren and four real asserts read as player copy. It balances
  parentheses now.

  **And running it found a third database key on a plank.** A decoration slot in the
  town square read `1 heartwood + 3 meadow_fiber`, because the prompt sawed the label
  off the material id instead of asking the one module that holds material names.
  `ExtractionPayoff` has had `MEADOW FIBER` all along. This is #339's
  `THE WOOD IS REGION_BRAMBLEWAKE` and #356's `fishing_kit` in a third place, and like
  both of them it was never a literal, so no localization check would ever have looked
  at it. The snare's price had the same shape and a sharper tell: upper-casing the id
  gives `SHIPS IRON` for `SHIP'S IRON`, which is close enough to look deliberate.
  Both read the labels now, and a spec holds every material a player is ever quoted a
  price in — decoration, snare, recipe — against them, because `summarize` **drops** a
  material it cannot name, which is right for a pouch and silent for a price.

  **Verified live at 392 x 608, against a baseline rather than against a number** —
  and that turned out to be the only honest way to do it. `world_started
  interactions=122`, `server_boot_complete services=27`, 132 proximity prompts and 209
  labels with **none empty and none showing a key**, no empty label anywhere on screen,
  the tutorial's first interactions still reading `[FREE] Mara`, `[BUILD] Barricade`,
  `[LIGHT] First Lantern`, `[CHOOSE] HAND AXE`, and two migrated refusals driven
  through the real remote and read back off the HUD.

  **The world came up at 13,931 descendants, and #354 recorded 15,208.** The
  difference is not the wave: `main` at `cf3576a` was built in a worktree and walked
  the same way, and it settles at **13,931 too, subtree for subtree**, on the same
  expedition seed. **The town's descendant count is a function of the seed the
  expedition generated with**, and the seed changes when Studio reopens the place —
  so a live pass that asserts a constant fails for a reason that has nothing to do
  with the build, which is the shape of a check people learn to ignore. What the
  count is good for is a *comparison*: same seed, same subtrees, before and after.
  The one subtree that did change is the one this batch is about, and it changed in
  words: `EAST PLAZA BANNER · 1 heartwood + 3 meadow_fiber` on the baseline,
  `· 1 HEARTWOOD + 3 MEADOW FIBER` on this branch.

  **And the portrait pass found a panel sitting at a width of minus twenty-two.**
  `_layout` sizes the departure panel to `min(420, canvasWidth - 24)` with no lower
  bound, and a viewport is briefly degenerate while a window is being resized — so
  `canvasWidth` came back as 2, the panel was written a **negative** width, and it
  stayed there with three party-size buttons rendering off the right edge, because
  nothing lays out again until the viewport changes once more. A phone rotating is
  the same event. The field book's grid has had `math.max(120, …)` since it was
  written; the departure panel, the call panel and the objective card were sized
  without one and have it now. **Open:** the transient itself is not reproducible on
  demand, so this is a fix for a mechanism that was observed rather than a case that
  is covered.
- **#357** (v158, unchanged — documentation only) **Where the buildable roadmap
  actually stands, and the owner-gated list gathered against an executable one.**
  Milestones 0 through 12 are complete on their buildable halves, **M14's buildable
  half is now complete (A through E)**, and **M13 has four waves complete and one, D,
  in flight and guarded**.

  The consolidated owner list at the end of the wave plan is rewritten to point at the
  thing that now enforces it. QA_RELEASE_PLAN.md's checklist holds 40 rows, 39
  blocking, of which **32 are open and owner-gated**, and
  `validate_launch_checklist.py` refuses a declared launch candidate until each is
  answered. That is the shortest complete statement of what is left and it is
  executable, so the prose list is a reading of it rather than a second copy that can
  drift.

  **What is left in code is one thing**: M13 wave D's remaining migration batches — 88
  files, 2,623 strings, all in server announcements and content catalogs. Every one of
  them is guarded by a check that is already live, `ALLOWLIST_SIZE` only moves down,
  and none of it blocks anything on the owner's list.
- **#356** (v158) **M13 wave D, batch two: the world surface, chosen because it is the
  batch you can read back out of a running server.** 227 strings out of
  `WorldService`, `BramblewakeBuilder` and `RegionBuilders` — every proximity prompt,
  every building name, every resident's name and trade, every sign in the town. The
  reason to take this one second rather than the server toasts is that a broken
  migration here is a **blank plank**, and a blank plank is visible: the whole batch
  can be verified by walking the world and reading what it says, which is not true of
  a toast that only fires on a failure path.

  **A guard caught the migration blinding another guard**, which is the find worth
  keeping. `validate_town_layout.py` reads the town's geometry out of `WorldService`
  as text, matching `authoredBuilding("id", "NAME", ...)`. Replacing the name with
  `Strings.get("world.bell_tower")` meant the pattern matched nothing, and the script
  **refused rather than passing** — "found only 0 authored buildings, expected at
  least 10... update the pattern rather than silently passing with fewer buildings
  checked than exist". That refusal was written into it long before this wave, by
  somebody thinking about exactly this: a text check quietly matching less is a check
  that reports good news about a file it can no longer read. It reads both shapes now.

  The allowlist is at **88 files and 2,623 strings**, down from 91 and 2,854, and
  `ALLOWLIST_SIZE` moved with it — the only direction it moves.

  **Verified live at 392 x 608 on the rebuilt place**, by reading the world back: 132
  proximity prompts and 209 sign labels the server actually built, none of them empty
  and none of them showing a key.

  **And looking found a defect the migration did not cause and no spec could see.**
  The starter tool pedestals passed `definition.tool` as the prompt's object text, so
  a player standing at the fishing pedestal was shown the word **`fishing_kit`** — a
  database key on a plank, which is #339's `THE WOOD IS REGION_BRAMBLEWAKE` in a new
  place. Nothing about it was findable by counting: the string was never a literal, so
  no localization check would ever have looked at it. Each pedestal carries a name out
  of the table now, and the fishing one reads `FISHING KIT`.

  **The first fix for it was wrong, and the same habit caught that too.** Reaching for
  `definition.displayName` looked obvious and was nil — these pedestals are built from
  a local list rather than from `ToolCatalog` — so `WorldService` **failed to
  initialize** and the town did not build. 917 tests passed, `npm run check` passed,
  and the world was 1,888 instances instead of 15,000 with one line in the log. The
  only thing that found it was starting the game and counting what was in it.
- **#355** (v157) **M13 wave D: the guard goes in before the migration, or the
  migration has no guard.** Routing every player-visible string through one table
  touches nearly every file that speaks to a player, and the check that gives the
  wave its value — *no player-visible literal outside the table* — cannot be switched
  on until the migration is complete. That is why this wave sat unbuilt through two
  sessions, and the reasoning was right: **a half-migrated string table looks finished
  from every direction except the one that matters.**

  The way past it is not to do the whole thing at once. It is to land the rule with
  the exceptions named. `scripts/validate_localization.py` runs in `npm run check`
  from this commit; a file is either covered, in which case it may hold no
  player-visible literal at all, or it is on an allowlist with a written reason.
  `ALLOWLIST_SIZE` is pinned at 91 and **only ever lowered**, which is
  `validate_monetization.py`'s shape and `Config.SaveSchemaFreeze`'s: a new file that
  speaks to a player routes its text through the table on the day it is written, and
  every batch between here and empty ships guarded.

  **`src/shared/Strings.luau` is the table, and `get` throws.** That is the whole of
  its error handling and it is deliberate, because both alternatives ship. Returning
  the key paints `hud.close` on a button, which at least looks like a bug somebody
  will file. Returning an empty string paints nothing, which looks like a design. This
  project has paid four times for a silent fallback hiding a gap — 120 recipes with no
  bench, 24 residents with no body, ninety craftable items with no equip button — and
  every one of them was a lookup that answered instead of refusing.

  **The check runs in both directions, which is what makes it a wiring check rather
  than a lint.** A key nobody defined is a label wired to nothing. A key nobody reads
  is a string a translator is paid for and no player ever sees — and it is exactly
  what a migration leaves behind when it moves a line and forgets to delete the old
  one.

  **The first batch is the client surface**: 121 strings out of `HUDController`,
  `init.client` and `ObjectiveMarkerController`. Writing the spec found the first
  duplicate immediately — the Old Growth's name written once in the HUD and once in
  the client bootstrap. Two keys holding one sentence is the smaller half a translator
  pays twice for and the larger half where somebody edits one and the game starts
  saying two things in one voice. Merged under `common`, and no two keys may hold the
  same text.

  **What is deliberately not translated is anything handed to `warn`, `error`,
  `print` or `assert`.** A stack trace is read by whoever is holding the console, and
  paying to translate one only makes it harder to search.

  **Still to migrate, in the order they are worth doing:** server announcements and
  toasts (30 services), world signage and prop labels, and the content catalogs, which
  are the bulk. `src/first/LoadingController.client.luau` is the one file with a real
  argument for staying — it runs before the shared root replicates, which is the whole
  point of it, and reaching for the table would make the loading screen wait for the
  thing it exists to cover.
- **#354** (v156, unchanged — this wave adds a script, a validator and documents)
  **M14 wave E: `HEAD` is not a revision.** ROLLBACK.md's second step says "republish
  the last known-good place revision", and it pointed at this file's own header for
  the revision and the flag state that go together. The header read *at `main` =
  `HEAD`*. **`HEAD` is whatever the reader happens to be standing on, which during an
  incident is the build that is on fire.** The one place in the repository where the
  revision and the flag state were written side by side recorded neither of them, and
  nothing failed, because nothing was checking. The cost of that lands in the only
  minute the record exists for.

  It is a table now — a full commit id, the place version it produced, the save
  schema, the build, and all 26 flags read **out of that revision** rather than out of
  the working tree. `validate_rollback_target.py` checks it on every `npm run check`.

  **The rule with teeth is the schema one.** Rolling back past a schema bump strands
  every profile the newer build wrote: the old build does not know the fields, and the
  first save it writes back is a save it has narrowed. So a schema bump **moves the
  rollback target forward**, which is the same fact `Config.SaveSchemaFreeze` is
  about, arriving from the other side. The other three refusals are the ways a
  recorded target is quietly useless: a revision nobody merged is a build nobody has,
  a target that is the current tip is not somewhere to roll back *to*, and a flag
  matrix describing a build it does not match is worse than no matrix, because it will
  be followed.

  **`npm run verify:rollback` does the half a validator cannot.** It checks the
  revision out into a throwaway worktree, builds it, and runs the same DataModel
  verification the normal build runs — because a revision nobody has built since it
  was recorded is a plan rather than a rollback, and the moment you find that out is
  the moment you are trying to use it.

  **Verified live rather than by proxy.** The target's build came out **byte-identical**
  to the published place (`baa0ffd2f37f…`), which is what makes the live pass real
  rather than a stand-in: the server running in Studio *is* the rollback build. It
  booted clean with the world raised — `LastLightWorld` at 15,208 descendants, all
  three defense lanes, 132 interaction prompts and a player character in the town.

  **Five refusals exercised against the real document before it shipped**: the record
  saying `HEAD` (the actual defect, reproduced), the target set to the current tip, an
  orphan commit nobody merged, a schema bump that left the target behind, and one flag
  flipped in the matrix.
- **#353** (v156, unchanged — this wave adds scripts and documents, and neither is
  in the built place) **M14 wave D: release notes, known issues and dashboards are
  normally written at the end of a project from memory, which is the one moment nobody
  has any.** This repository has already paid for that once: the whole reason
  PROJECT_STATUS.md exists is that a feature was built twice because nothing recorded
  it was in flight. So none of the three is written. `npm run notes` builds them and
  `npm run check` fails when they are stale, because **a generated document that can
  go stale is a document written from memory again, with an extra step.**

  [RELEASE_NOTES.md](RELEASE_NOTES.md) is the merge stream with the place version each
  wave produced. [KNOWN_ISSUES.md](KNOWN_ISSUES.md) is the nine open threads this
  handoff already keeps — written inside the entry for the wave that found each one,
  which is the right place to write it and the wrong place to read it from, because at
  2,600 lines "what is still open" is an archaeology question.
  [DASHBOARDS.md](DASHBOARDS.md) is 23 panels off the marked emitters in `src`, beside
  the gate or the tuning decision each one feeds.

  **The two guards matter more than the three documents.** *Every pull request the
  handoff records has to exist in git* — a handoff citing a number that never landed
  is a note about something that did not happen, and nothing else in the project would
  ever notice. And *every wave has to have a handoff entry*, which is the direction
  that cannot be demanded of every pull request (plenty are one-line fixes summarised
  in a batch) but can be demanded of a wave, because a wave is the unit this project
  ships in and the wave plan records the number each one shipped as.

  **That second guard found three waves with no entry at all**: #301, #302 and **#347,
  M13 wave B**, which shipped this session and was described only in the wave plan and
  in the entry for the wave after it. #301 and #302 turned out to be recorded under a
  span — the reader was taking the first number of `#301–#302` and calling the second
  one missing, which is a check crying wolf and therefore a check somebody deletes, so
  it reads spans now. #347's entry is genuinely new, reconstructed from the merge
  stream and the wave plan rather than from memory, and says so in its own text.

  **Two smaller finds, both of the same kind.** Twelve pull requests in this history
  were squash-merged rather than merge-committed, so their number is in a trailing
  `(#N)` and a reader that knew one shape would have silently lost twelve — including
  four the handoff writes about by number, which would then have been reported as
  phantoms. And the first gate-table reader assumed four columns, so it found none of
  the **zero-tolerance** gates, which are two: a dashboard document with the
  zero-tolerance panels quietly missing is the precise failure it is generated to
  prevent.

  **The known-issues count is pinned at a minimum**, for #336's reason from a new
  angle: an empty known-issues list and a broken parser produce the same document, and
  it reads like good news.

  **Open, by design rather than by omission:** the notes are allowed to lag the tip by
  the merge commit that lands them, because a strict compare would leave `main` failing
  its own check the moment any wave merges. What is refused is a hole or a phantom —
  the rows have to be exactly the tail of the merge stream ending at the newest row
  recorded. Patch notes in a player's language stay the owner's, and the checklist row
  `patch_notes` says so beside the `known_issues_published` row this wave turned into a
  check.
- **#352** (v156, unchanged — this wave changes only manifests, validators and
  documentation, and none of the three is in the built place) **M14 wave C: a claim
  made once over a whole registry stops being true one asset at a time.** The three
  asset validators proved an asset exists, decodes and is registered, and could not
  say where it came from. The manifests each said something about origin in a
  different vocabulary, and **the audio manifest said it once, at the top of the file,
  covering all twenty-five tracks at the same time.**

  That is the shape of the failure rather than a gap in rigour. A heading reading
  "free public-domain audio from verified providers" is a claim the twenty-sixth track
  inherits without anybody making it, and nothing anywhere fails. An original-IP audit
  reads one list; three vocabularies is three lists.

  **Origin is a per-asset field from a closed three-word vocabulary now**, and the
  evidence a class requires is a property of the class rather than of whoever added
  the asset. `authored_here` needs a sentence and nothing else — nobody has to be
  asked about a thing this repository made. `generated_then_authored_here` needs the
  tool named, because "we made it" and "a model made it and we normalized it" are
  different answers and only one is interesting to an audit.
  `licensed_platform_library` needs the two facts a licence question actually turns
  on: who published it and where it lives. 10, 34 and 51.

  **The third count is pinned harder than the other two**, because everything in it
  belongs to somebody else and somebody else's work entering the game should be a
  decision rather than a diff nobody sized.

  [ASSET_PROVENANCE.md](ASSET_PROVENANCE.md) is the artifact the review reads, and its
  51-row inventory is held against the manifests in both directions — an asset missing
  from it is an asset nobody reviews, and a row for an asset no manifest ships is a
  licence somebody is still paying attention to for nothing.

  **What the check refuses to do is read a licence.** Whether Roblox's terms cover
  this game's use of a particular Creator Store model is a human question, and a
  script claiming to have settled it would be worse than one that says it cannot. The
  document states the terms each class is used under and names the reading as the
  owner's.

  **Nothing here was invented.** Every publisher name was already in the mesh
  manifest's own provenance sentences and every audio publisher in its `creator`
  field; the wave moved facts into fields rather than writing new ones. Four mutations
  run before it shipped: a licensed asset dropped from the inventory, a publisher
  changed in the manifest only, an original quietly reclassified as licensed, and a
  class deleted from the document. Each failed, and each named what was wrong.
- **#351** (v156) **M14 wave B: a bullet cannot be unticked.** QA_RELEASE_PLAN.md
  has ended in a release checklist since Milestone 1, and it was prose bullets, which
  means "complete launch checklist" was completed by whoever said it was — normally
  the person who most wants to ship. It is 39 rows now, and
  `validate_launch_checklist.py` reads them in `npm run check`.

  **The design decision that matters is when the gate is allowed to fail.** Nearly
  every row is a Creator Dashboard field, a triage record or a human on a phone, so a
  checklist enforced from the day it lands fails every build forever, and a check that
  fails on every build is a check somebody comments out. `Config.LaunchCandidate` is
  `nil` today for exactly the reason `Config.SaveSchemaFreeze` is, and setting it
  turns the 38 blocking rows into a gate.

  **What is live from day one is the structure**, and that half earns its place on
  its own. A row's status is one of four words. **`check` means the repository
  decides it** — the evidence column names something that runs in `npm run test`, and
  the validator confirms it still exists, so an item whose spec was renamed away stops
  being satisfiable on the day of the rename rather than on release day. `done` and
  `n/a` both require evidence, because `n/a` is the cheap way past a blocker and an
  unexplained one is an exemption nobody remembers granting. The three counts are
  pinned the way RELEASE_GATES pins its `review` rows: 39 items, 38 blocking, 6
  decided here. A blocker cannot be quietly downgraded and an owner row cannot be
  quietly promoted.

  **Declaring a candidate requires the schema freeze**, and the refusal says why: a
  launch candidate whose save schema is still free to move is precisely the failure
  wave A exists to prevent, so the two declarations are one act rather than two
  somebody can do half of.

  **The ten journey rows are ten rows rather than one**, because "smoke tested"
  passing on six of seven is the shape of every launch-day surprise.

  **Eight paths exercised against the real config and the real document** before it
  shipped, since a gate that has never been seen to fail is a gate nobody has tested:
  no candidate (passes, 32 blocking rows open); a candidate with no freeze (refused);
  a candidate with a freeze and open rows (refused, naming each); every blocking row
  answered (passes); a `check` row pointed at a renamed spec (refused); a row deleted
  (refused on the pin); a blocker set to `n/a` with no reason (refused); and the same
  id on two rows (refused).

  `patch_notes_and_known_issues` is an owner row today and M14 wave D is the wave
  that turns it into a `check` row, which is what a checklist getting stronger looks
  like from the inside.
- **#349** (v155) **M13 wave E: a switch you have to restart every server to use is not
  a switch.** [ROLLBACK.md](ROLLBACK.md) is the list M13's rollback drill needs to
  exist before it can be run: every flag, what turning it off leaves, and the build
  and flag state a rollback restores. The interesting column is **scope**, and it
  is load-bearing rather than descriptive — the only moment a kill switch exists
  for is an incident, and during an incident the servers are already running with
  players in them.

  **`TownNightService` cached the town cycle's flag at construction**, so the off
  switch for the whole night loop needed a full server restart to take effect.
  Nothing failed; every snapshot reported the right value. It is read at the door a
  new cycle comes through now, which also settles what off *means*: **stop starting
  new ones, not delete what is running.** A night that vanishes underneath the
  people fighting it is a worse outage than the one being rolled back. This is
  #344's lesson from the other side, and the spec refuses a `live` switch stored in
  a field.

  **Writing the list found four flags that nothing reads at all** —
  `bounded_join`, `first_ten_minutes`, `input_action_system` and
  `content_registry`, Milestone 1 staging switches for systems that have since
  become the game. They are declared `none` with the reason rather than wired into
  a fiction: a kill switch for the input action system leaves a world nobody can
  touch, which is not a rollback, it is an outage. **That count is pinned harder
  than the restart count**, because a switch that turns nothing off looks exactly
  like one that works right up until somebody reaches for it.

  Three encounter switches are `restart`-scoped and pinned, one is `rebuild`-scoped
  because the event states created from it have to agree with each other for the
  life of one manifest, and the scope column is what licenses a cache — declare a
  switch `live` and store it, and the spec fails.

  **The honest limit is written down rather than implied:** production refuses flag
  overrides, so step one of a rollback is a config change and a publish there
  today. Making it genuinely live needs a server-side flag store, which is
  owner-gated infrastructure.

  **Verified on the built place**: the shipped `TownNightService` no longer reads
  the flag in its constructor, `ensureStarted` reads it live, and the cached form
  is gone from the place file — checked by reading the module's own `Source` in a
  running server rather than by reading the working tree. The server booted clean
  with the rewired service (`world_started interactions=122`,
  `defense_plots_built lanes=3`, `town_mesh_dressing_ready`,
  `server_boot_complete services=27`).

  **M13 wave D (localization source coverage) is the one wave of this milestone
  still to build**, and it was taken out of order deliberately rather than started
  and abandoned; the wave plan records why.
- **#348** (v154) **M13 wave C: a number you cannot act on is an observation.** Wave B
  gave every tuning decision a number; this is the other half of the sentence.
  **Ten values came out of four services into `Config`** — the elite's and the
  boss's engagement distances, the town watch's chip damage, rate and reach, and
  the lantern's health ceiling — because while they were locals, every tuning pass
  was a code change, a rebuild and a publish, and the practical cost of that is not
  effort: it is that nobody tries a second value.

  **A knob has exactly one home, and that rule prevents the worse failure rather
  than the obvious one.** A service that reads `Config.EliteStrikeRange` and also
  keeps its own `STRIKE_RANGE` is a knob somebody turns, reads their telemetry, and
  concludes the number does not matter — a tuning pass producing a *wrong* answer
  instead of no answer.

  **The pairing is the load-bearing check.** Every decision in BETA_TUNING.md's
  first table has at least one row in its second, and every knob names a decision
  that exists, so a sixth tuning decision cannot arrive with an event and no way to
  respond to it. Both directions, plus: every knob is a finite number in `Config`,
  every knob is read somewhere outside it, and the four emptied services are
  checked by name so a later refactor cannot quietly put a constant back while the
  `Config` entry stays.

  **The obvious version of the one-home rule cried wolf and had to be tightened.**
  Matching on value alone, the first run reported `TerrainBuilder` reading
  `Config.BootstrapTimeoutSeconds` beside its own `SURFACE_PATCH_DEPTH` — both 8,
  and nothing else in common. A check that has to be argued with every time it
  fires is a check somebody deletes, so a second home now has to be the same
  **number** and the same **thing**: names normalized and compared as substrings,
  so `STRIKE_RANGE` matches `EliteStrikeRange` and `SURFACE_PATCH_DEPTH` matches
  nothing. Mutated afterwards by putting a copy of the strike range back, and both
  the general rule and the by-name check caught it.

  **Verified live for waves B and C together**, in a running server on the built
  place. The rewired services came up clean (`old_growth_ready`,
  `warden_stag_ready`, `defense_plots_built lanes=3`,
  `server_boot_complete services=27`) and the knobs read
  `elite 28/58/14 · boss 27/56/15 · watch 3/7s/26 · lantern 100` from `Config`.
  The five tuning emitters were then driven through the shipped
  `AnalyticsService` inside Roblox's VM, and every accumulator carried: two downs
  and one revive arrived on `first_night_outcome`, `difficulty_checkpoint` went
  `attempt=1` then `attempt=2`, `repeat_activity` went `run=1` then `run=2`,
  `group_outcome` carried `partySize=3 banked=12`, and `first_session_end` carried
  `furthestStep=3 furthestStage=first_night` from a funnel step recorded eight
  calls earlier. The residue counter read **8** for a departed player and **0**
  after `clear`, which is the leak the soak metric now watches.
- **#347** (v153) **M13 wave B: the tuning decisions have numbers, and a tuning
  number is not a gate number.** *(Reconstructed from the merge stream and the wave
  plan rather than written at the time — #352's generator found this wave had shipped
  with no handoff entry at all, which is the failure the handoff exists to prevent
  happening to the handoff.)* Five decisions, five events, and the distinction that
  makes them a separate family from #336's: a gate is a rate over instants and every
  gate emitter reports one instant, while a tuning decision is about a stretch of
  play, so `AnalyticsService` had to **accumulate** rather than forward. Two rules the
  events follow, both ways a tuning number lies: **a cliff is a comparison, so every
  checkpoint emits** rather than only the ones somebody suspects, and **an outcome
  with no attempt number is a survivorship number**.
  [BETA_TUNING.md](BETA_TUNING.md) is the table and `TuningMetrics.spec` is
  `GateMetrics.spec`'s three layers pointed at it.
- **#346** (v152) **M13 wave A: a flag can reach some players and not others, and the
  hard part is what happens when it reaches more.** Milestone 13's rollout is four
  rungs — team and trusted testers, a consented allowlist, a larger controlled
  cohort, then everyone — and `FeatureFlagService` has answered one question
  globally since Milestone 1. `RolloutCohorts` (pure) adds the second question and
  three rules, each of which is a way a staged rollout goes wrong in somebody's
  live beta rather than a preference.

  **The ladder only ever widens.** A flag moved from `team` to `allowlist` must not
  take the feature off the testers it was turned on for — those are the people
  whose reports the next rung is decided on. That is structural rather than
  remembered: `admits` walks the rungs from the bottom up to the flag's stage and
  returns at the first one that lets the player in, so there is no branch that can
  subtract. Driven as a property over a mixed population rather than asserted at
  one step: for every player, the set of stages that admit them is upward closed.

  **A cohort-scoped flag read without a player throws.** Every call site in the
  game asks globally today, and one of them left asking globally about a flag that
  has since acquired a cohort has to answer something. Both answers are silently
  wrong in opposite directions — `true` ships an unreleased feature to the whole
  population, which is the exact thing staging exists to prevent, and `false` hides
  it from the only people it was turned on for. So there is no answer, the same way
  an unknown flag already has none.

  **A bucket is stable per player and independent per flag — and the second half
  had to be measured rather than reasoned about.** The first version hashed
  `flag .. userId` and ran it through the Lehmer step `ExpeditionGenerator` uses,
  and every operation in that chain is affine, so changing the flag name shifted
  every player's bucket by one constant. Two flags at ten percent came out
  **perfectly disjoint** — 0 players in both against 201 expected — which reads as
  a lovely property until you notice it means no player in the beta ever sees two
  new features, and two flags at fifty percent would have cut the population into
  exact complements. Folding the two hashes with an exclusive or breaks the
  affinity; the same measurement returns 200 against 201. The spec keeps that
  measurement rather than a single-player case, because nothing about it is visible
  from one player and one flag.

  **The switch and the rung are one fact, not two that can drift.** A flag is
  `true` if and only if it stands at `everyone`, checked through
  `RolloutCohorts.globalDefault`, so the pin the wave asks for — every existing
  flag's global answer bit-identical — is a consequence rather than a snapshot.
  [BETA_ROLLOUT.md](BETA_ROLLOUT.md) is the matrix, with why each flag is where it
  is, and the spec reads its rows out of the document: **none of the three lists
  may move alone.**

  Nothing stands mid-ladder today and the spec asserts that too, which is the
  honest state rather than an oversight — the middle rungs are populations and
  there is no population. `Config.RolloutRoster` is empty for the reason
  `CommerceProductIds` is: a trusted tester is somebody the owner asked, and an
  allowlisted player is one whose guardian consented.

  **Verified live in a running server**, because the boot path of every service in
  the game now runs through a six-argument constructor: `feature_flags_initialized
  count=26 overridesAllowed=true scoped=0` and `server_boot_complete services=27`.
  Then `RolloutCohorts` was driven inside Roblox's own VM and its answers held
  against Lune's, **digit for digit**: the ladder reads
  `off>team>allowlist>cohort>everyone`, a roster member is admitted at `team` and a
  non-member refused with `outside_cohort` until `allowlist` takes them, and 2000
  players across two 20 percent flags give `cohortA=404 cohortB=421 both=82` against
  85 expected in both runtimes, with the same three sample buckets. Roblox's `bit32`
  and Lune's agree, which is not something a spec run outside the engine can say.
- **#344** (v151) **M12 wave E: the soak, and three ways the obvious version of it
  passes on a leaking build.** M12 asks that N cycles leave the same counts they
  started with. Read a counter at the start and again at the end and subtract,
  and all three of these are waiting.

  **The first cycle is not a baseline.** A server builds its town, spawns its
  residents and wires its world on the way into cycle one, so every one-time
  allocation lands between sample one and sample two. Measured from sample one a
  build that then holds perfectly reports a leak -- and the fix everybody reaches
  for is a wider tolerance, which is now wide enough to hide a real one. The
  baseline is the **second** sample, and three cycles is the least that says
  anything.

  **A sample is only comparable to one taken at the same point in the cycle.**
  Instance count during a night is legitimately higher than at dawn, because
  there are creatures in the world. A series that drifted across phases produces
  a number that means nothing and looks exactly like one that means something, so
  a mixed series is **refused** rather than averaged, along with a repeated cycle
  number -- a sampler that fires twice halves the apparent growth of a real leak.

  **A leak's signature is that it does not stop.** A metric can rise at every
  sample and sit under a flat tolerance for the length of a test, which is the
  shape of every leak ever shipped: it was small enough for an hour. So a metric
  still climbing at every step is a breach *under* its own allowance, and the
  report says which of the two it is.

  **Connection count is declared unobservable, and that is the honest answer
  rather than a gap.** Roblox exposes no API for it, so a number here would be
  one this game invented, and a gate reading an invented number is worse than a
  gate reading nothing. What a soak *can* watch is `player_residue` -- the
  per-player tables every service keeps, walked in full -- because a connection
  that outlived a player kept its table entry alive too. The count of
  unobservable metrics is pinned, the way RELEASE_GATES pins its `review` rows.

  **A live pass found the wave broken in the way this wave is about, then found
  the rule wrong.** (1) `LastLightSoak` was read once at boot, and a Studio Play
  session starts from a fresh DataModel that does not carry attributes set in
  Edit mode — so the wiring ran on every server and could never be switched on
  from the only place anybody drives it. Nothing failed: the counters were there,
  the spec was green, the log was silent. It is read per cycle now, and a spec
  case refuses a top-level read. (2) Then eight real cycles showed the town
  gaining **982 instances in one step** as it tiered up and raised new buildings,
  then holding — and the span-growth rule called that 200 a cycle forever, so a
  healthy server breached on the game working. Growth is measured over the
  **tail** now, from the middle sample to the last, which is the rule
  `PerformanceBudget` already argued for on frame rate. Walked on the fixed
  build: `incomplete` at cycles 1–2, `ok` at 3, `breach` at 4–6 while the town
  was actually growing, and **back to `ok` at 7 and 8** once it stopped. The
  breach clears when the growth does, which is the whole point.

  Also verified live across those eight cycles: one sample per cycle, all at
  `day`; `enemies=0` at every dawn with a Briarback spawning during night 8, so
  the counter is live rather than stuck; and `residue=0` throughout. **Open:**
  `profile_bytes` was read correctly and never exercised under change — driving
  cycles through the private-server rail latches practice, so the profile is
  never written, and it read a flat 2661 for a reason that is not the profile
  holding steady.
- **#343** (v150, unchanged — this wave adds only a spec and docs) **M12 wave C:
  every content spec counts, and none of them walks.** `ContentCensus` counts the
  catalog, `ChapterProgress` checks a chapter against the chapter beside it,
  `Quests` drives one arc, `MemoryFragments` checks that a fragment is anchored
  somewhere. All true, and not one of them takes a profile from the first dawn
  to the epilogue — which is the only question a player is actually asking.
  **Counting is not looking**, and this codebase has paid four times for a
  catalog whose entries were each individually reachable and whose path through
  them stopped.

  `FullPathTraversal.spec` makes **one** profile and takes it the whole way:
  `SaveSchema.default`, seven chapters through the real mutators in order, and
  the epilogue read back out of the save it just wrote. **Nothing in it is a
  fixture** — every state it asserts against is the state the previous assertion
  produced, so a break anywhere on the path fails at the step that broke rather
  than leaving a suite passing around it.

  At every step the region underfoot is open and the one after it is shut, and
  then the sharper version of the same question: **every chapter still ahead is
  offered and refuses.** That is the difference between a walk that works and
  the only walk there is. Two orderings had never been held against each other
  either — the chapters' `requires` chain and the region registry's
  `dependencies` — and a region added to one and not the other hands a player
  either a region the story cannot open or a chapter with no ground under it.

  **The quest catalog is emptied rather than sampled.** Saturated signals answer
  "can this be claimed at all"; the number of passes answers the sequencing
  question by itself, because it is one stage per arc per pass and therefore the
  depth of the deepest arc and nothing else. 46 quests, three passes.

  **The crafting tree turned out to hold a property worth pinning rather than
  merely checking.** Each of the six worked regions pays exactly five materials,
  no two regions pay the same one, and **no recipe reaches across regions** — so
  a material names the chapter it becomes obtainable at, and every one of the
  130 recipes is craftable the moment its own region is walkable. The tree is
  exactly as deep as the story and never deeper. The Hollow pays nothing, which
  is asserted rather than assumed: it is the finale, and a material dropping
  there would make the last chapter somewhere to farm. Both directions of the
  economy are checked because they fail differently — an input nothing pays out
  is a recipe nobody can craft, a payout nothing spends is a number that climbs
  in a pouch and buys nothing.

  **The one thing the walk cannot do is a case instead of a sentence in a
  document.** Six regions are `enabled = false` and flipping one is the owner's
  call after a live session walks it end to end. What is checkable is that the
  flag is the whole of the remaining distance: a fully resolved story refuses
  each of them with `region_not_built`, never with a missing dependency and
  never with an unreached chapter.

  **Four mutations were run against the finished spec before it shipped**,
  because a traversal check that passes on a broken tree is worse than none: a
  recipe made to reach across regions, a region dependency made to skip a
  chapter, an arc stage pointed at a quest that does not exist, and a chapter's
  prerequisite dropped. Each failed, and each failed in the case meant to catch
  it.
- **#341** (v150, unchanged — this wave adds only specs and docs, and the built
  place carries no tests) **M12 wave A: the fixtures were each normalized once, and a real save
  is not.** `SaveMigration.spec` has held an era fixture per released schema
  since Milestone 4 and refuses a bump without one. What it does is normalize
  each fixture **straight to current** — one hop. A save played since schema 11
  has been through fourteen migrations *in sequence*, each one reading what the
  one before it wrote, and that is a different question: a migration written
  against the fixture beside it can be correct about that fixture and wrong
  about the shape its predecessor actually produces. `SaveRehearsal.spec` walks
  one profile era by era, checking at every step that the tutorial is still
  finished, the tool still chosen, the profession still picked, twelve nights
  still survived, the chapter still resolved with its transaction id, and the
  pouch still full — and that the **revision has not moved**, because a
  migration that rewrites it has quietly created a save that outranks the one in
  the store.

  **And the forced-scenario suite M12's exit gate needs in order to be
  claimable at all.** "Save-loss and purchase-loss rate is zero in a forced
  scenario suite" is a sentence about a suite, and the suite did not exist. Four
  ways a real save is lost, each expressed against the pure module that already
  decides it, because the decision is where the loss happens and the DataStore
  call around it is Roblox's: a **disconnect mid-write** (the older copy has to
  survive, and the interrupted write has to still outrank it if it lands late);
  a **profile lock** (read-only rather than refused, and reclaimable once it
  stops beating, or a server crash ends somebody's game permanently); a **failed
  read** (the one that must not be mistaken for a new player, because that
  mistake hands out a default and then writes it over everything); and a
  **restore from backup** (which has to outrank the live save, or the operator
  is told a rollback worked that was silently refused as stale).

  **Then all of it again with money in it.** The mailbox lives outside the
  profile by construction, and this is the case that construction exists for: a
  receipt held while the profile could not be written survives the profile being
  rolled back, refused or replaced, drains into it when it can, and grants
  exactly once when the platform retries. Purchase loss is its own gate for this
  reason — a suite watching only the profile would pass on a build where every
  rollback dropped a paid-for cosmetic. The entitlement is walked era by era
  too, since it is the one field on the profile that cost a real person real
  currency.
- **#340** (v150) **M11 wave J: the taxonomy and the code named different events, and
  Milestone 11 is complete.** The monetization document lists six commerce
  events and the store-safety section says why they are six rather than one:
  *purchase analytics separates prompt, platform completion, receipt grant, and
  equip/use.* That separation exists for the support runbook rather than for a
  dashboard — **a player writes one sentence, "I bought it and I do not have
  it", and it can mean four different things with four different answers.** A
  merged `purchase` event cannot tell a prompt nobody completed from a receipt
  that never resolved, and those two are opposite.

  `CommerceAnalytics.spec` is `GateMetrics.spec`'s three layers pointed at
  commerce: every event the taxonomy lists has an emitter logging **that exact
  name**, every emitter has a `COMMERCE-EVENT` call site where the fact is
  produced, every marker is an event the taxonomy lists, and none may be
  emitted from client or shared code — a store view a client reports is a store
  view a client decides.

  **Writing it caught the thing a spec like this is for.** The taxonomy said
  `purchase_platform_result` and the code emitted `purchase_prompt_finished`.
  Both existed, both were called, both were documented — in two documents naming
  different events. A dashboard built from the taxonomy would have had one empty
  panel and no way to tell it apart from a quiet week. Renamed to the document's
  word, which is the taxonomy of record.

  **A live pass then found a second gap that no spec could see:** pressing BUY
  on a product with no dashboard id returned before the emitter, so the one case
  where somebody actually pressed the button produced no telemetry at all. That
  is this wave's own failure mode happening inside the wave. It emits now, with
  `shown=false`.

  [COMMERCE_SUPPORT.md](COMMERCE_SUPPORT.md) is the runbook
  MONETIZATION_LIVEOPS_ANALYTICS requires to exist *before* anything is sold, and
  it is written now for the reason it is required now: a support procedure
  invented during the first incident is written by whoever is most upset at the
  time. It is organised around that one sentence, with a table mapping which
  events are present to which of the four things happened and what to say. The
  refund policy is three bullets because **nothing sold here can be spent,
  consumed, traded or lost** — a refunded cosmetic leaves a player exactly where
  they were. Removing the entitlement must also unequip it (owning nothing and
  wearing something is a free cosmetic for anyone who can get a refund), the
  purchase id **stays** in the processed ledger (removing it makes the platform's
  next retry grant it back), and deleting a sold cosmetic from the catalog is
  data loss wearing a cleanup's clothes, because `normalize` correctly drops
  entitlements it no longer knows.

  **Verified live: the emitters fire, not merely exist.** `store_view cards=24`,
  `product_detail_view product=product_lantern_keeper_coat` and `receipt_result`
  all logged in a running server from a real interaction with the outfitter's
  stand. The receipt came back `outcome=held` rather than granted, which is wave
  I's latch working from the other side: a receipt arriving in a practice server
  cannot be durably granted, so it waits in the mailbox instead of being banked
  into a save that is never written. `cosmetic_equipped` and a `granted` receipt
  were walked live in #337.

  **Still owner-gated:** `purchase_platform_result` needs a real platform prompt
  to come back, which no Studio session can produce; the Creator Dashboard
  products, the prices, policy review, and the on-call contact the runbook's
  escalation table hands to.
- **#339** (v149) **M11 wave I: a private server can hold its own clock, and the price is
  that it stops paying.** MONETIZATION_LIVEOPS_ANALYTICS describes private-server
  controls as phase pause in non-reward practice, seed selection among already
  discovered seeds and cinematic tools, with one sentence attached that decides
  the whole design: **reward-bearing modifiers remain server-defined.**

  The usual way to keep that is to sort the controls into the ones that touch
  rewards and the ones that do not, and trust the sorting — a judgement made
  once, by whoever adds the fifth control, about a system they are not thinking
  about. So this module does not sort. **Every control forces practice, and
  practice is a one-way latch on the whole server.** The argument fits in a
  line: a control that changes nothing about the world does not need a private
  server to house it, and a control that changes the world changes the run.
  Hiding your own HUD is a HUD feature. What is left, once that is taken out, is
  a list where every entry is reward-bearing.

  That makes the gate line true structurally rather than by inspection — there
  is no reward left for a setting to change. `apply` sets `practice` on every
  accepted change with **no per-control branch**, so a fifth control is latched
  by the same line as the four here, and the spec drives the whole catalog
  through it rather than holding a case per entry. **The latch never lifts**,
  because a practice server that could go back to paying would let somebody hold
  the clock, arrange a night, release it and bank — the modifier the promise is
  about, reached in two presses. Verified live: releasing the hold left PRACTICE
  on the pill.

  **Practice is two lines, not an audit of forty reward paths.** Every mutation
  in the game funnels through `ProfileService.isWritable` and every durable write
  through `save`, so the whole of "a practice phase grants nothing" lives at two
  seams that can be checked. The second one is the non-obvious half: `save` does
  not consult the dirty flag — the leave path and the lock heartbeat both call it
  outright — so gating mutations alone would have left a practice server writing
  the entire in-memory profile on the way out. And **the locks go back**: a
  server that has renounced writing forever and still holds a session lock is
  holding somebody's save hostage, so the latch flushes once, then releases every
  lock it holds, and a profile arriving afterwards never claims one.

  **Nothing here is a purchase.** Authority is `PrivateServerOwnerId`, a property
  of the server rather than an entitlement of the player, which is what keeps it
  outside the monetization guard: no gameplay branch reads what anybody owns. A
  **reserved** server is refused by name, and that refusal is the one worth
  having — every expedition this game launches runs in one, and Roblox reports it
  with a non-empty `PrivateServerId` and an owner of zero, so the obvious test
  would put a clock-holding rail inside the reward-bearing half of the game.

  Save schema 24 → 25 with an era-24 fixture: a capped, deduplicated history of
  the seeds a player has actually **walked** (recorded on entering the wood, not
  on requesting a departure — a run nobody reached is a layout they have never
  seen). Capped because M12's soak gate asks in as many words that profile size
  not grow without bound. An era-24 save arrives remembering no seeds, which is
  what that player has rather than something migration lost.

  **Verified live at 392 x 608, and two things only looking could find.** (1)
  **The pill counted down through a stopped clock.** The server sat at 543.8
  seconds left for six seconds while the HUD went 08:38 to 08:32 — the label
  refreshes ten times a second off its own copy of `phaseEndsAt`, and a hold
  moves that deadline on the server and pushes nothing. Every spec passed. The
  seconds are measured where the clock is now, the flag rides with them, and the
  word changes to HELD, because a number that has simply stopped is what a frozen
  game looks like. (2) The seed readout said THE WOOD IS **REGION_BRAMBLEWAKE** ·
  32693 — a database key shouted at somebody standing in front of a plank.

  Walked on the fixed build: the rail stands inside the town gate with all four
  boards legible in portrait; a real mouse click on HOLD THE CLOCK gave PRACTICE ·
  DAY · 10:25 HELD and froze the pill for eight seconds; a second click read THE
  CLOCK RUNS AGAIN and the clock resumed with PRACTICE still on it; CALL THE NEXT
  PHASE walked day → dusk → night with the world's own announcements; STILL THE
  DARK left a spawned Rootling at 0.0000 studs over eight seconds against 18.5
  studs in five for a free Briarback, and releasing it resumed the night; CHOOSE
  A SEED refused with YOU HAVE NOT WALKED A SEED WORTH KEEPING YET on a fresh
  profile and rebuilt the wood once a seed had been walked. **And the central
  claim was checked against a control in the same session**: SaveLoadout answered
  KIT 1 SAVED and KIT 2 SAVED before the latch and KIT COULD NOT BE SAVED two
  minutes later, with nothing else changed.

  `LastLightStudioPrivateServer` is the fifth Studio-only attribute and fakes
  exactly one thing — the owner — because a Studio session is neither a private
  server nor a reserved one and the rail is otherwise unreachable from a
  playtest. Documented in [STUDIO_MCP_SETUP.md](STUDIO_MCP_SETUP.md).

  **Open, and needs a second person:** the seed board's SOMEBODY IS STILL IN THE
  WOOD refusal. It reads the whole player list, so the only honest way to raise
  it is another player standing in the expedition; a solo session cannot press a
  board in the town while it is in the wood. It joins M11 wave C's two-player
  half in the cohort work M12–M13 already list.
- **#338** (v148) **M11 wave H: the direct catalog is four lines, not five loose
  things.** The spine shipped one cosmetic per slot to prove the chain -- entry,
  plan, product, grant -- and five loose objects is not a catalog. What a player
  wants is a look, and a look is not a lantern shell: it is the thing the
  lantern shell finishes. So the unit is a **line**, one look across all five
  slots, named in the data rather than implied by display names.

  **Naming it is what makes the claim checkable.** A set product that grants
  four of five slots is a set with a hole in it, and the hole is invisible until
  somebody buys it and finds their lantern still bare — this project's most
  expensive shape, an entitlement that exists beside a cosmetic that cannot be
  worn. `CosmeticReachability.spec` now demands every line carry exactly one
  cosmetic per slot, every line have exactly one set, and each set grant exactly
  its own five with no two things for one slot. The counts are pinned and
  pinned again in CONTENT_CATALOG.md, with a case holding the two together.

  **Three new lines, named for places the story has been** rather than for
  invented brands: the Ironroot is pit leather and riveted iron with a caged
  lamp built to be dropped, the Mireglass is bog oak and split-reed binding and
  glass the colour of standing water, the Cinderfall is scorched plate with
  bronze at the joins and one ember inset that is the only lit thing on it.
  Every silhouette differs from the Greenward's rather than only its palette,
  because a line whose sole difference is its colours is VISUAL_QUALITY_STANDARD's
  recoloured cube wearing a second name.

  **20 cosmetics, 24 products**, and the four sets are the first thing to
  exercise a path wave E built and had nothing to run through it: one purchase
  id handing over five cosmetics at once, idempotently.

  **Verified live at 392 x 608**: all 24 cards and all four line headings render
  in the outfitter's panel, a heading appears only when its line has a card
  under it, and a set shows its outfit and says · 5 PIECES rather than stacking
  five plans at one origin — merged, they photograph as a pile. Weapons, tools,
  lanterns and banners each read as their own object at 76 points. **Open, and
  honest:** the four outfits read as a detailed torso block at that size, which
  is what a derived plan of a torso is; the art pass that replaces them is the
  owner's and every plan is still `derived = true`.
- **#337** (v147) **M11 wave G: there is a shop, and the interesting half of it is
  everywhere it refuses to open.** Milestone 11's exit gate is one sentence —
  *the store never interrupts onboarding, active defense, downed state, or
  defeat* — and the monetization document forbids the same four from the other
  side. Both are rules about a **moment**, so they are a predicate rather than a
  habit: `StoreAvailability` (pure) takes the snapshot fields the HUD already
  has and answers open or refused, with the reason. The server gates the door
  with it and the client evaluates the same function on the same fields, so a
  panel open when a night starts shuts itself on the frame the state changes
  instead of waiting for somebody to press something.

  **The order the refusals are asked in is the message a player gets.** Defeat
  before downed before defense: a wiped party told "not while something is out
  there" is the game not having noticed. Defeat is real rather than nominal —
  `PlayerSurvivalService` reports `partyDown` using the same eligibility rule
  the guard's last stand already uses, so the two cannot disagree about what a
  wipe is. And defense is not only night: a blackout relay, a town incident and
  both boss fights all put a player in a fight in daylight, which is why the
  predicate reads the creature count and not just the clock.

  **The door is a thing in the world, not a button on the HUD.** The
  outfitter's stand in the departure lodge is the only way in, and that is the
  design: a storefront openable from the HUD is openable in all four forbidden
  moments, and the predicate would then be the only thing between a player and
  a shop over a boss fight. It is a plank you walk up to, the same argument the
  town gate settled for the visit policy.

  **No card renders without price, permanence and owned state.**
  `StoreCard.build` returns nil and a reason rather than a card with a blank in
  it — a BUY button over an empty price is a player agreeing to something
  nobody told them. The price is never a constant; it is read from platform
  product info, and with `Config.CommerceProductIds` empty the honest answer is
  that no card renders at all and the panel says how many are waiting on a
  price. The power assurance is added by the builder rather than written per
  product, because a line a writer has to remember is a line missing from the
  twelfth product. **The wardrobe is a second list on purpose**: a product can
  stop resolving, and a store that showed owned cosmetics only through their
  sale cards would make a paid-for coat unwearable the moment the thing that
  sold it went away — an entitlement that exists and a cosmetic that can be
  worn are different facts, which this project has now paid for five times.

  **The equip payload names a cosmetic and never a slot.** The slot is the
  catalog's answer about that id, which is the only version a server should
  trust; #331's review found `equip` letting any owned cosmetic go in any slot.
  Pressing something already worn takes it off, so removal needs no second
  field. Four new actions, one interaction-routed and three carrying one id
  each, all four filed in `ExploitGate`.

  **Verified live at 392 x 608 — and touching it found five defects every spec
  had passed.** (1) The panel's CLOSE button sat at x 309..367, y 24..51,
  **entirely inside `GuiService.TopbarInset`** — on a phone that is Roblox's own
  menu button, so tapping CLOSE would open the platform menu and leave a modal
  nobody can shut over the world. The panel is measured below the topbar now.
  (2) A toast raised while any overlay is open drew **behind** it: the store
  refused a purchase correctly, said so, and painted the sentence under the
  panel. #327 was a modal eating input; this was the same modal eating output.
  Toast ZIndex 12 → 60. (3) `CommerceService:setGrantHandler` was never wired,
  so a granted receipt landed in the ledger and the profile and the card in
  front of the buyer went on saying NOT OWNED — #325's town that never
  re-rendered, with money attached. (4) The stand's first placement put a stone
  plinth **through the picnic table's bench**; the table moved to the fireside,
  which is where a table belongs anyway. (5) The stand went in at the darkest
  point on that wall — the lodge's east lamps are at z 46 and z 78 and it sits
  between them — and photographed as a pure silhouette. Three lanterns now, the
  two that matter on brackets reaching two studs *forward*, because hung close
  they lit the sign perfectly and the merchandise edge-on. The dummy's coat went
  from one dark panel (a black slab) to two lapels over pale linen, because
  value contrast is what makes a shape read in a room lit by two lamps.

  Walked on the fixed build: the stand refuses with THE OUTFITTER IS NOT OPEN
  YET while the flag is off; priced, it opens with five cards, each with a real
  preview drawn from the cosmetic's own plan, 399 ROBUX, PERMANENT — YOURS FOR
  GOOD · NOT OWNED and a BUY button; a real click on BUY answers THAT ONE IS
  NOT FOR SALE YET, which is `product_not_configured` and correct, because a
  Studio price does not make a Creator Dashboard product exist; a granted
  receipt flips the card to OWNED and raises the wardrobe row; and a real click
  on WEAR reads WORN on the toast, TAKE OFF on the row and · WORN on the card.

  Two Studio-only attributes make that possible and neither grants anything the
  real path would not: `LastLightStudioStore` sets a **price**, so
  `promptPurchase` still refuses, and `LastLightStudioGrant` pushes a synthetic
  receipt through `applyReceipt`, the single grant authority. They exist for the
  reason `LastLightSkipTutorial` exists — a live pass on a store with no priced
  products sees an empty panel, and an empty panel and a broken panel look
  identical. Documented in [STUDIO_MCP_SETUP.md](STUDIO_MCP_SETUP.md).

  **Still owner-gated and unchanged:** the Creator Dashboard products, the
  prices, and a live purchase with a real receipt. Nothing in this wave can be
  bought.
- **#336** (v146) **M12 wave D: the release gates stop being a list of numbers
  nobody collects.** [RELEASE_GATES.md](RELEASE_GATES.md) has held the promotion
  thresholds since Milestone 1 and most of them had **no emitter at all** —
  profile transaction success, crash-free sessions, join failure, first-night
  completion, canceled prompts. The reason that survived twelve milestones is
  the failure mode the document is least able to detect on its own: **a
  dashboard reading zero and a dashboard reading *nothing* look identical to
  the person approving a release.** The first says the gate passed, the second
  says nobody measured it, and the release goes out either way.

  Eleven server events now, each named by the gate it feeds and naming it back,
  and `GateMetrics.spec` holds the two lists against each other in **three
  layers**: every gate in the document names an event with an emitter in
  `AnalyticsService`; every emitter has a call site marked `GATE-METRIC: <id>`
  where the fact is produced, because an emitter nobody calls *is* the
  dashboard reading zero; and every marker in `src` is a gate the document
  lists, so neither list may grow alone. It also refuses a gate emitted from
  client code, which the measurement contract already forbade in prose.

  **Two gates say `review` instead of naming an event, and the count is
  pinned.** A blocker defect on the launch path is a triage decision and a
  platform-policy failure arrives through Roblox's moderation; nothing this
  game can emit produces either, and an event invented to stand in for one
  would be a gate passing on a number that measures something else. Pinning the
  count is what stops the cheap move — a threshold nobody wants to instrument
  becoming a third one, and then a fifth.

  **What each gate can and cannot honestly see is written down rather than
  implied.** `unauthorized_mutation` counts *refused* attempts, because a
  mutation this server let through is by definition one it did not notice; what
  a refusal rate buys is the earlier signal, since an exploit found is an
  exploit probed for first. A crash is derived rather than reported — Roblox
  fires the same leave event for a player who quit and a player whose phone
  died, so a session whose telemetry went stale three intervals before it
  disappeared *stopped* rather than left, and a server shutdown is named
  separately because counting a scheduled restart as fifty crashes is how a
  gate gets ignored. And an impossible seed is caught here only where the
  generator's own validation catches it; the seed that validates and is still
  untraversable is wave C's job, and the document says so.

  **Every per-segment threshold got the dimension it is read on**, which is
  half of five gates: a threshold readable only across the whole population is
  exactly where a phone-only failure hides. New `SessionSegment` (pure) decides
  the platform class and the performance tier, the client says which of the
  four it is **on its first frame rather than with its first sample** — a
  session that ends in four seconds is precisely the kind the join and crash
  gates are about, and one with no platform on it cannot be counted against the
  threshold it failed — and nothing in the game reads the label for anything
  but a label. The telemetry payload's field check became a **whitelist** in
  the same commit: a count was enough while a fifth field was by definition
  smuggled, and adding the platform would have made room for one extra field of
  a client's choosing, which is the one-extra-field rule failing in the
  direction it was written against.

  Also this wave: `receipt_result` carries the seconds a purchase waited,
  measured from when the platform handed the receipt over rather than from when
  the grant landed — so a purchase that sat in the mailbox while its buyer was
  in another server carries the whole wait, which is the only version of that
  number a player would recognise.

  **Open and not closed by this wave:** a live pass confirming the events
  actually fire in a running server. Studio was launched from this session and
  its window came up, but its MCP plugin never connected — the log shows no
  connection attempt at all, which is the "Enable Studio as MCP server" toggle
  needing a click in the Assistant menu. The spec proves a call site exists in
  the source; it cannot prove the line runs, and that is exactly the
  distinction this wave is about, so it is recorded open rather than assumed.
  `profile_transaction` additionally cannot be seen in Studio at all: a
  non-persistent session is not a DataStore round trip and deliberately emits
  nothing.
- **#334** (v145) **M14 wave A: the save schema freeze is a value now, not an
  intention.** M14's deliverable list says "frozen save schema except blocker
  fixes", and the cost of forgetting that is not a broken build — it is a
  player's save. A launch candidate is declared, a bump lands two weeks later
  for a reason that felt small, and the migration path validated against the
  candidate is no longer the one that runs.

  `Config.SaveSchemaFreeze` is `nil` today, which is the correct state: **a
  freeze that is on while the schema is still moving is a freeze somebody turns
  off and forgets to turn back on.** When a launch candidate is declared it is
  set to that candidate's version, and `validate_schema_freeze.py` refuses any
  bump past it from that moment.

  Two ways through, both deliberate acts, and the refusal names them: raise the
  freeze (which *is* unfreezing, and belongs in a pull request that says so), or
  set `SaveSchemaFreezeOverride` to the exact version being allowed and say why
  the fix is a blocker. The override has to be typed out, because a number that
  has to be typed is a number somebody looked at. It also refuses an override
  more than one version past the freeze — several at once is unfreezing wearing
  an override's clothes — and refuses a **stale** override left behind after the
  freeze moves, because an exemption nobody remembers granting is the failure
  mode a guard like this actually has. All six paths were exercised against the
  real config before the wave shipped.
- **#333** (v144, unchanged — the place is byte-identical, because this wave
  adds only specs and the built place carries no tests) **M12 wave B: the exploit suite can now say something it
  could not before — *every* action kind has a refusal, not only a handler.**
  `ExploitGate` covered the remote surface as it was in Milestone 3. It now
  covers all forty-three action kinds by name, each filed under where its
  refusal actually lives (the payload contract, a server re-check, or a world
  prompt the player has to be standing at), and a new action with no entry
  fails on the day it is added. That is deliberate: the two defects this spec
  family exists for were both an action being half-wired, and half-wired is
  exactly the state a new action is in between two commits. The shared refusal
  is then *exercised* rather than asserted — a smuggled field is dropped for
  every kind in the game, which is #219's shape run forty-three times.

  Four new attacker's-side cases over what M11 added. **Quick chat**: there is
  no position in the payload to forge and no target to name, an invented phrase
  id resolves to nothing rather than to a default, and the wheel's budget is
  its own bucket so flooding it cannot starve the action budget. **A block
  cannot be walked around** by distance, by expiry or by direction — including
  standing on top of the marker, which is the one a radius filter alone would
  have let through. **The town gate** carries no payload at all, so the attack
  that would matter (writing a policy onto somebody else's profile) has nothing
  to ride in on. **Commerce**, the one surface where a successful attack costs
  money: wearing what you did not buy, a save that claims you already are, and
  a receipt for a product that does not exist all settle nothing.

  And **one case per admin command** rather than one for the roster, because
  the roster check and the parser are different gates. A stranger is refused
  for every command, the feature flag is a complete off switch for every
  command, and no command lets an absurd argument reach a handler as a value —
  so a compromised roster account is still a bounded one. An unknown command is
  refused with a *different reason* before authorization is considered, so the
  roster cannot be probed by comparing refusals.
- **#332** (v144) **M11 wave F: `CommerceService`, and the allowlist goes from
  zero entries to one.** The monetization guard has held since Milestone 4 by
  *absence* — there was no purchase API anywhere to branch on — and its own
  docstring names that as the weakest way for a gate to pass. This is the wave
  that adds the thing, and the property survives by design instead: cosmetics
  are pure presentation, entitlements resolve outside gameplay into plain
  profile data, and gameplay branches on what is **equipped**. The allowlist
  entry says all of that in the file itself, because a list that is not read is
  a list that grows.

  **Two specs now say it from two directions.** The script skips allowlisted
  files entirely, so a second module added to both the codebase *and* the list
  would pass it — `CosmeticNeutrality.spec` closes that by counting, over
  comment-stripped source, how many files in `src` touch a purchase API at all,
  and demanding the answer be at most one and be `CommerceService`.

  **Every decision a receipt makes is pure.** `ProcessReceipt` cannot be
  exercised in Studio and will not be exercised anywhere until a real account
  spends real Robux, so the branch lives in `Entitlements.route` and the
  service is the shell that hands it a profile, a mailbox and a durable write.
  `CommerceReceipts.spec` drives the four scenarios the gate names — retry,
  crash mid-grant, profile lock, disconnect — plus the sequence where they
  interleave, which is where a real incident comes from: held while away,
  retried while away, drained on arrival, then retried once more by a platform
  still waiting on the first answer. **Exactly once is checked by counting what
  the player ends up owning**, not by counting calls; a call count passes on a
  grant that ran twice and happened to be idempotent by luck.

  **A receipt is acknowledged only after a durable write**, and two things
  count as durable: the buyer's profile saved, or — when this server does not
  hold that profile — the mailbox saved. Telling the platform early loses a
  purchase; telling it late costs a retry. **An unresolvable product is never
  banked either**, in either branch: a mailbox full of receipts nobody can ever
  apply is a support queue with no answer at the end of it.

  Also this wave: the five commerce analytics events the taxonomy names but
  nothing emitted (`store_view`, `product_detail_view`, `purchase_prompt`,
  `receipt_result`, `cosmetic_equipped`). **Still owner-gated and unchanged:**
  the Creator Dashboard products, the prices, and a live purchase with a real
  receipt. `Config.CommerceProductIds` is empty and the store flag is off, so
  `promptPurchase` refuses with `product_not_configured` rather than prompting
  into nothing — which on a client looks like the button being broken.
- **#331** (v143) **M11 wave E: the cosmetic spine, built before the platform
  call so the platform call has nowhere to put a decision.** `CosmeticCatalog`
  (presentation only, five slots), `Entitlements` (pure: what a grant is, idempotency by
  purchase id, the mailbox), `profile.commerce`, and the two specs the wave
  plan settled the architecture around. **No `MarketplaceService` in this
  wave** — the whole spine is testable without the platform, and that is the
  point: `ProcessReceipt` cannot be exercised in Studio, so everything that
  *decides* anything about a purchase has to be decidable without it.

  **`validate_monetization.py` still passes with an empty allowlist**, which is
  the load-bearing fact. Its own docstring names the risk it lives under: "an
  exit-gate item that passes because a thing is missing goes on passing right
  up until someone adds the thing." This wave adds the thing and the guard
  holds, because nothing here touches a purchase or ownership API.

  **A cosmetic carries no number that is not presentation**, and the check is a
  whitelist rather than a blacklist of stat names — `power`, `bonus`,
  `capacity` need no naming, because anything that is not a colour, a size, an
  offset or a rotation fails whatever it is called. **And nothing outside the
  catalog may name a cosmetic id at all**, walked over every file in `src`: a
  gameplay branch on a cosmetic is not merely absent, it is unwriteable.

  **A plan is a list of shapes, not a case in a renderer**, following
  `GearVisualPlan`. That designs out the class of bug this project has paid for
  four times — 120 recipes with no bench, 24 residents with no body, eight
  props that would have rendered as somebody else's, ninety craftable items
  with no equip button. There is no per-cosmetic drawing case that can be
  missing because there is no per-cosmetic drawing case.

  Three rules hold the receipt logic up, and all three are ways a real game
  loses a real purchase. **A retry is a success**: the platform calls again
  until told the grant is durable, so a purchase id already in the ledger
  answers "we have it" without granting twice — granting twice hands out two of
  something bought once, and refusing to acknowledge retries forever. **An
  unknown product is never consumed**: telling the platform a purchase is
  settled when this build cannot resolve it leaves a player holding a receipt
  for nothing, so it stays pending for a build that knows it. **A receipt that
  arrives while the profile is locked goes in a mailbox** that lives outside
  the profile by construction, because its entire reason for existing is the
  moments when the profile does not.

  **Review found four real holes and one standards call.** `table.freeze` is
  shallow, so a frozen catalog entry pointed at a mutable parts array;
  `normalize` kept entitlements for cosmetics the catalog no longer sells and
  kept a slot worn by somebody who did not own it (a free cosmetic for anyone
  who can write a save field, and also exactly the state a refund leaves);
  `equip` let any owned cosmetic go in any slot, so an outfit could be worn as
  a lantern shell; and `SaveSchema.commerce` handed back the profile's own
  table, which a caller could edit in place — granting an entitlement with no
  normalization, no revision bump and no save. All four fixed. **And the emote
  slot came back out**: an emote is a motion rather than a shape, the only
  geometry this file could offer for one is a glow, and
  VISUAL_QUALITY_STANDARD names a glow directly as not being construction. It
  arrives with the animation pipeline that makes an emote possible, not as a
  lit sphere called a salute. The tool grip and the banner were thickened for
  the same reason — a wrap reads as cord when you can count the turns, and a
  banner reads as a standard when it hangs from a crossbar.

  Save schema 23 → 24 with an era-23 fixture. `Config.CommerceProductIds` is
  empty and `cosmetic_store_enabled` is false, both correctly: a developer
  product does not exist until somebody creates it in the Creator Dashboard.
  The spec does not demand the table be full — it demands it cannot be wrong,
  so a number pasted against a product the catalog does not know fails the day
  it is pasted rather than the day a player presses buy.
- **#330** (v142) **M11 wave D: the artifact the privacy and abuse review
  reads, and a check that keeps it honest.**
  [SOCIAL_SAFETY_REVIEW.md](SOCIAL_SAFETY_REVIEW.md) lists **every way one
  player can reach another** — ten channels — what bounds each, and what a
  block does to it. A document like that is worth exactly its agreement with
  the code, and documents drift; this project's whole handoff exists because of
  what goes missing between sessions. So the agreement is a check.
  `SocialSafety.spec` reads `SAFETY-CHANNEL: <id>` markers out of `src` and the
  channel table out of the doc and fails if either set has an entry the other
  lacks. **Neither list may grow alone**: a channel added to the game and not
  written down fails, and a bound the document claims that nothing implements
  fails — which is the worse of the two, because that is a review passing on a
  promise.

  **Block became one reader that everything asks.** Quick chat already
  consulted `Chat:CanUsersChatAsync`; party invites now ask the same
  `SocialService` rather than the platform a second time, and a blocked player
  is skipped **silently and in both directions** — silently because the
  alternative tells the presser who has blocked them, which is a disclosure the
  platform deliberately does not make. Two specs pin the call count at one,
  from different files, so deleting either suite does not free the other rule.

  **Reporting is the platform's, deliberately, and that is now a recorded
  decision rather than an omission.** Every Roblox client carries a report menu
  that reaches Roblox's moderation with the experience and both accounts
  attached. A game-authored report button would either duplicate that into an
  inbox nobody staffs or look like it did something it did not. Same for
  blocking: Roblox's list is the list, because a second one is a list a player
  maintains twice and that travels with them nowhere.

  **The largest social surface in the experience is not in this repository**,
  and the review says so in the `platform` rows: whether Roblox's own text chat
  is enabled is a Creator Dashboard setting. Everything this game implements is
  a closed vocabulary; that would not be. It is the single biggest social
  decision left and it is the owner's.
- **#329** (v141) **M11 wave C: a town has a gate now, and somebody decides
  who comes through it.** `TownPermissions` settled the host/visitor split in
  Milestone 4 and its invariant has held since — a visit improves a town or
  leaves it alone, never breaks it. What was missing was the other half of the
  sentence: a player had no say in *who* visited.

  **What a policy can govern, and what it deliberately does not.** It does not
  govern presence. Roblox decides which server a player lands in, and a game
  that ejected somebody on arrival would brick a public join for a player who
  did nothing but get matched. So the policy governs the thing this game does
  control: whether an arriving player's town record is **adopted** into the
  host's town, and whether they may **read** the host's showcase. Refused, they
  are an `outsider` — a third role that is a narrowing of `visitor`, not a
  widening of anything: they play their own nights, their own expeditions and
  their own profile, and the host's Emberhollow is scenery. Adoption is the
  only channel by which one player's save has ever reached another's town, so
  closing it is a real boundary. And because an outsider contributes *nothing*,
  the Milestone 4 invariant is preserved twice over rather than merely
  survived; the spec re-asserts it against this path rather than trusting the
  older suite.

  **An undecided arrival is held, not guessed.** Deciding needs an answer the
  platform gives asynchronously (friendship), so the record waits rather than
  being applied on a guess. A guess in the admitting direction is a closed town
  adopting one stranger before the gate speaks — the exact bypass this wave
  exists to make impossible — and a guess the other way drops a legitimate
  contribution for good. An undecided record is simply never applied, and an
  unapplied upward-only contribution costs a town nothing. The same reasoning
  makes `pending` a real role the snapshot reports: the showcase hangs off the
  role, so a relation the platform has not answered on yet reads nothing.

  **The policy is a plank you walk up to.** `open → friends → invited →
  closed`, cycled at a gate standing over the south end of the lantern road,
  because the HUD has had buttons taken back off it twice for portrait screens
  and a setting about the town belongs in the town — the same reasoning that
  moved FIND and STRIKE onto the objects they act on. Being *asked along* beats
  being on a friends list, so a town set to `invited` admits the party the
  founder just built even if none of them are friends. Only the founder may
  work the latch; a visitor gets ONLY THIS TOWN'S FOUNDER SETS ITS GATE.

  Save schema 22 → 23 with an era-22 fixture, and that fixture carries a rejoin
  ticket — the migration case now asserts an era-22 ticket *survives* rather
  than only that older eras have none, which is the claim that matters to a
  player who dropped out of a run and updated in between. Era-22 saves arrive
  **open**, because every town before this schema was open to whoever the
  matchmaker sent and migrating them shut would be a change of behaviour
  wearing a safe default's clothes.

  **Verified live**: the gate builds (two posts, a lintel, a hung board over
  the road), a real mouse click on the board walked all four values with the
  right toast each time, the snapshot carried `role=host`, the policy, its
  label and a showcase reading tier 0 / night 1 / integrity 100, and
  `town_host_established host=… policy=open` logged at adoption. **The camera
  caught one defect**: a board's Front face is its −Z, so the sign read out
  into the trees and was blank from every angle a player approaches from.
  Turned to face the square, and confirmed by dot product and by eye.

  **Open and owner-gated**: the two-player half. A visitor being refused, a
  showcase being read by somebody else, and a friendship resolving all need a
  second person in the server, which is the cohort work M12–M13 already list.
  The pure rules and the single-door guard are spec-covered.
- **#328** (v140) **M11 wave B: a player can say something to another player,
  and there is no string in it.** Twenty-four phrases in four categories, and
  the design decision under all of it is that the vocabulary is *closed*: free
  text in a game with this audience means a filter, an appeal path and a human
  reading reports, while a fixed list means moderation is structural. There is
  nothing a player can compose, so there is nothing to moderate — and
  `QuickChat.spec` asserts that as a property of the source rather than as a
  claim in a document, walking every file in `src` for the entry points a text
  channel would have to use. Roblox's own chat is deliberately out of scope of
  that check and belongs in wave D's inventory: it is the platform's channel
  with the platform's moderation, and whether it is on is a dashboard setting.
  The one place `TextChatService` is touched at all is AdminService's slash
  commands, pinned to that file by name so it cannot spread.

  **A phrase both says something and marks a place, and the place is the
  sender's own, resolved server-side.** The payload carries a phrase id and
  nothing else — which is the one-extra-field rule #219 was found against, and
  here it is also the security property: there is no position in the payload to
  forge, so a ping cannot mark somewhere its sender is not standing. Verified
  live: the anchor's coordinates matched the character's `HumanoidRootPart` to
  four decimal places.

  **The six courtesies mark nothing on purpose.** A thank-you is speech, and
  speech has no place in it; they draw over the speaker's own head instead.
  Six people being polite must not put six cards over the town — and the
  live pass found the smaller version of exactly that: the budget allows three
  calls in a burst, and three courtesies drew three billboards on one head at
  one offset, an unreadable smear. **One card per speaker per surface, newest
  wins**, which is also what every ping wheel a player has used already does.
  The rate limiter bounds how much is said; that rule bounds how much is drawn,
  and they are different problems.

  **There is no call log on the HUD, and that is a decision about a phone.**
  A portrait canvas is 503 points wide with the objective card across the top
  and the thumb cluster along the bottom; the band left over is the band a
  player is trying to see creatures in, which is what #325's report was
  literally about. A call is drawn in the world instead, where it means
  something. Presentation is resolved from the catalog by the ping kind the
  server names — glyph, colour, life, reach — rather than chosen by that name
  in a client ladder a twenty-fifth phrase's new kind would fall off silently.

  **Verified live at a 392 x 608 viewport**, which is the 503-point canvas the
  owner's phone gives: the CALL button takes the corner slot nearest the jump
  button and nothing in the cluster is off-screen; the wheel opens by real
  mouse press and by key, four tabs and six phrases fit with CLOSE fully on
  screen; a real press on WATCH THE DARK closed the wheel and left one danger
  marker at the sender's feet; a second marking phrase from the same player
  replaced the first at the new position with the right glyph; distance on the
  card counts up as you walk away (0m → 59m); and a fourth call inside the
  burst is refused with LET THE LAST CALL LAND. Blocking is the platform's own
  answer through `Chat:CanUsersChatAsync`, called in exactly one place and
  spec-pinned to one place, applied symmetrically and to both the record and
  the markers — a suppression rule that covers the log and not the marker
  covers nothing, because the marker is the loud half.

  **Open, and not closable here:** what the ping card *looks like* on screen.
  Studio's `screen_capture` does not render BillboardGuis — proven in the same
  session, where a plain magenta probe billboard was invisible while a magenta
  part at the same coordinates rendered. The card is the same recipe as the
  objective markers and the 33 landmark labels; its geometry, adornee, text,
  colour and lifetime are all measured, and only the pixels are unseen.

  Also written this wave: the portrait-click recipe in
  [STUDIO_MCP_SETUP.md](STUDIO_MCP_SETUP.md). The M7 runbook's advice to click
  GUI buttons by `instance_path` is true of a maximized window and **silently
  false** of a resized one — the tool reports success, `Activated` never fires,
  and that looks exactly like a dead handler. Pass the button's own
  `AbsolutePosition` centre instead, and do not correct for the 58-pixel inset
  that `GetMouseLocation` reports back.
- **#327** (v139) **the walkthrough's deferred list, cleared on a portrait
  viewport — because the owner plays this game on a phone, in portrait, and
  every bug report that started this effort was a phone screenshot.** The
  session drove Studio at a 392 x 608 viewport, which is a HUD canvas 502
  points wide: the same width a 390-point portrait phone gives, and a third
  of what the offsets in HUDController were written against. Every control
  was measured against the real screen before and after, and the numbers
  below are all from that measurement.

  **Four of the six thumb-cluster controls were off the screen by
  position, and the one a phone player actually sees there was gone
  entirely.** Baseline, at viewport width 392: HOUND spanned x −16..48,
  DODGE −164..−99, STRIKE −79..−13, FIND −18..72. Two of those are latent
  rather than felt — FIND and STRIKE carry positions but are deliberately
  never rendered any more, having moved onto the world objects themselves
  — and DODGE only shows on a keyboard, so it costs a narrow desktop
  window rather than a phone. **HOUND is the one that mattered:** it is
  visible on every platform the moment a briar hound is summoned, nothing
  had ever repositioned it for touch at all, and at x −16..48 the
  companion order button was unreachable again — the same button #325
  found had never been wired to anything. The thumb cluster is a measured
  run now: it starts inboard of Roblox's jump button, steps left by each
  button's own width, and wraps up a row when the next one would reach the
  thumbstick, with both insets scaled from the canvas because Roblox's own
  controls scale too. FIND leads the run and RUN follows it, so the
  primary action and the sprint the owner asked to sit beside jump share
  the corner column on every screen; the red telegraph banner rides above
  the topmost row. **Only a control a player can see takes a slot**, which
  CodeRabbit caught and which matters more than it sounds: counting the
  two permanently hidden ones reserved the bottom row — the thumb zone —
  for nothing and pushed everything real up out of reach.
  `_refreshActionCluster` re-measures when that set changes, guarded by a
  signature because the local clock asks ten times a second. Verified
  after, on the portrait viewport: nothing off-screen, a
  rectangle-intersection test over the visible controls returns no
  overlaps, the banner clears them all, and DODGE appearing mid-Blackout
  took the bottom-right corner rather than a leftover slot three rows up.

  **The field book was 46 points wider than the screen on each side, and
  CLOSE was 57% off it.** Baseline: the panel spanned x −46..438 of a
  392-wide viewport, the title read "O BOOK · RECIPES", SAVE 1 was clipped
  to "AVE1", KIT 3 ran off the right, and two of eight equip buttons sat at
  x 312..449. The book could only be shut by hitting the 24-pixel sliver of
  CLOSE that was still on screen — which is how the session discovered it,
  because a modal overlay nobody can close eats every world click behind
  it. Panel width, kit pitch, whet width and the equip grid's column count
  all derive from the canvas now. A desktop keeps its horizontal figures
  exactly (columns at 20/210/400, a 190 pitch, an 88/4/84 kit pair); the
  portrait canvas gets two columns, and the grid adds columns rather than
  rows if a player owns more gear than the height holds, because a button
  nobody can reach is how ninety craftable items once went unwearable with
  every spec green. **The panel is measured above the grid rather than
  centred**, which CodeRabbit caught: the equip buttons position from the
  canvas bottom, so on a portrait canvas the third row onward landed
  inside the panel and covered the recipes at a higher ZIndex — and it did
  the same on a desktop over the panel's bottom-left corner, where it was
  easier to miss. Verified after: panel x 16..376, CLOSE x 306..362 and
  clicked by its own instance path, all eight equip buttons inside the
  viewport, and with four owned the panel's bottom edge sits 7.8 pixels
  above the grid's top with nothing overlapping.

  **The HUD phase pill followed a clock that had stopped.** PhaseService
  only leaves its initial `day` by running the tutorial's First Night, so a
  player who arrives with a finished profile — or skips the tutorial in
  Studio — never moves it: `hasCompletedFirstNight` stayed false forever,
  the pill read DAY · MORNING through every night the town actually held,
  and `nightActive` was false beside it. Whose clock the pill shows now
  follows the player's own stage and whether the town cycle is turning
  (`TownNightService.isRunning`), not whether a particular night happened
  to run in this server session. Walked live through a whole town cycle on
  the fixed build: DAY · 11:48 LEFT, then DUSK · 01:35 LEFT as the dusk
  toast landed, then NIGHT · 05:10 LEFT with `nightActive` true, one
  creature walking and the lantern down to 4.

  **The gamepad had no way into the recipes.** The 130 recipes moved into a
  ScrollingFrame in #325, and a scrolling text window is the one HUD
  surface a controller cannot reach by accident — the notes are a single
  label, so there was no selectable target anywhere inside the book.
  Opening it now hands `GuiService.SelectedObject` to the window itself,
  after waiting for a real `AbsoluteSize` (the lesson the loading screen
  already paid for), with `NextSelectionUp`/`Down` wiring so the D-pad is
  not a one-way trip into the notes, and the selection is released on
  close, and both ways the assignment can fail now warn rather than pass in
  silence — a controller player who loses the book can otherwise only
  report that the recipes do not work. Verified live: opening the book by
  mouse click leaves the DetailsScroll selected at a real size, and closing
  it clears the selection. **The D-pad scroll itself could not be driven**
  — this machine reports zero connected gamepads, so
  `UserInputService.GamepadEnabled` is false and the engine's navigation
  never runs. Selecting a `Selectable` ScrollingFrame is what gives its
  canvas the stick; that half is engine behaviour and remains unconfirmed
  on a real pad.

  **The floating stone was a genuinely separate literal, not #325's
  helper.** The road-stone helper that used to clamp Y to 0.42 is not
  involved: `queueItemAsset` seats a replacement mesh on the *primitive it
  replaces*, which is right, and the primitive was the thing in the air. A
  step's `y` offset is measured from an event socket anchor standing half a
  stud above the module floor on a plate seven studs across, and all three
  of `event_bw_wildfire_choice`'s breaks were authored at `y = 1` — which
  seats a break on that plate, and only the road break is on it. The farm
  and grove breaks are seven studs out over bare ground, so their markers
  and the road stones dressing them hung 0.90 studs up. Both are `y = 0.1`
  now. Verified by raycast on the fixed build: gap 0.90 → 0.00 for both,
  the road break still seated 0.10 into its plate, and — the part that
  matters after #325 — both moved click volumes still answer a real mouse
  click, with all three steps sealed by tap and THE FIRE TURNS FROM THE
  HOMES — +4 HEARTWOOD closing the event. Measured and deliberately left:
  the two Warden-sign ground prints sit 0.98 and 1.07 studs up, and four
  crate/screen markers 0.35–0.80. Lowering those means lowering a
  0.45-stud-tall pancake of a click volume onto the floor, which is how
  #325's capped root node happened; the honest fix is to give
  `queueItemAsset` a per-caller ground seat, and that is its own change.

  **Ena's 0/3 was the words, not the data.** A real extraction does append
  to `inventory.settlementOrder` and the quest snapshot reads it live: the
  session harvested a node by tap, sealed the wildfire event, banked at the
  Wayhome gate and watched the quest go 0/3 → 1/3 in the same push, twice
  over. What is wrong is that the signal counts **settled deliveries** —
  a trip that banks nothing records no settlement, because there is nothing
  to settle — while all four asks built on it described it as a trip or a
  return. A player who does exactly what the words say and still reads 0/3
  has been told the quest is broken by the quest itself. So the words moved
  to the measurement: Ena asks to BANK A POUCH FROM BRAMBLEWAKE THREE
  TIMES, Saoirse for eight pouches, Nell for fourteen loads, Pip's second
  stage for six, and FOURTEEN TRIPS BACK is FOURTEEN LOADS BANKED. The
  fallback guidance no longer borrows Ena's line for residents who have
  none. Changing the signal instead would mean a new counter on the
  profile, and a resident quest must not be the thing that introduces
  tracking. Verified live after the extraction: "ENA: BANK A POUCH FROM
  BRAMBLEWAKE THREE TIMES — 1/3." And verified in the other direction on
  the reviewed build: a round trip out and back with nothing in the pouch
  reports RETURNING TO EMBERHOLLOW — POUCH EMPTY and leaves her at 0/3,
  which is exactly the trip the old words promised credit for.

  Not closed by this wave: none of the five items. Open live checks it
  leaves behind are the gamepad D-pad scroll (needs a controller), FIND
  and STRIKE pressed as buttons (they are never rendered, so their new
  positions are geometry only), and the six event markers recorded above.

  **Worth carrying forward from the method**: a hardcoded pixel offset in
  HUDController is measured against the *canvas*, which is `viewport.X /
  scale` wide — 502 points on the owner's phone, over 1,200 on the desktop
  the offsets were written on. Anything written as a literal there is a
  bet on a screen. And the field book's own CLOSE button being off-screen
  is worth remembering as a shape: a modal overlay that cannot be closed
  swallows every world click behind it, which reads in play as "the game
  stopped responding" rather than as a layout bug.
- **#325** (v138) **the third leg of the click-everything walkthrough:
  Bramblewake's whole chapter arc, walked with real mouse input.** All
  eight expedition events (seven completed, one deliberately left to its
  timer to see the failure path), a harvest node, two memory fragments,
  the rootfire relay, the Old Growth through both shield phases, the
  Warden Stag through all three with the Greenward vote resolving
  chapter one, six real bleedouts through the recovery-satchel loop,
  the Wayhome out, a snare armed by click that bit a pathing Briarback
  on night 2, and dawn resolving clean. What the walk caught:

  **A mouse click was three server requests.** TapController duplicated
  the engine ClickDetector on mouse and InputController swung the tool
  on the same press — so every one-shot interaction's success toast
  died to MOVE CLOSER TO THE MARKED OBJECT or "The tool is calm in
  daylight." The elite's, the boss's and the chapter's completion lines
  all went unseen in the same run that earned them. Mouse taps now
  defer to a detector that will fire and only speak when it won't.

  **Invisible click volumes fought each other, one fight a soft-block.**
  The wild-regrowth vote shrine capped the Warden's south root node
  completely — phase 3 needs all four roots, so the boss could not be
  finished by tap. Module 9's nodes sat five studs off the elite's fire
  and heart; the bell fragment's volume lay across the Wayhome gate.
  All repositioned, and spent nodes stop answering raycasts.

  **Every landmark label died with the art pass** — billboards were
  disabled with the scenery lights when authored meshes replaced their
  placeholders, so POI names, LANTERN FIRE / ROOT HEART and the whole
  Blackout relay guidance never rendered in a dressed world. Billboards
  are semantics now and survive replacement.

  **The town never re-rendered in the session that changed it.** The
  consequence pushed only at profile load, so chapter results and
  night-earned tiers waited for a rejoin the single-place topology
  never provides. Chapter resolution and dawn both push now, deduped by
  signature.

  **The Studio skip left the world half-woken** — beacon dark, night
  cycle never started. It now runs the same setup a loaded complete
  profile gets. And the banked polish: the field book's 130 recipes
  scroll inside the panel, completion toasts precede the blackout's
  announcement, the RootCrown reads as wood, the backdrop ranks floor
  their shade above black, and the road stones sit on the roads (the
  placement helper hard-clamped Y to 0.42 over every caller's ask).

  **Every fix was verified live on the rebuilt place** in a second
  session: the skip now wakes the beacon and the night cycle, an event
  step click reads POLLEN STORM — 1/3 and keeps it, all 33 landmark
  labels render, the field book scrolls under its own buttons, the
  stones sit on their roads, and — the one that matters — at dawn 4
  the tier flipped to 1 and Tomas, Pip and Ena walked into a running
  session, talked with live quest progress, and Tomas's arc advanced
  to 1/12 after a real crafted satchel claimed his first stage. The
  same session armed the Meadow Gate snare by click (2 fiber + 1
  heartwood spent exactly) and watched it bite a pathing Briarback on
  night 2, with DAWN BREAKS — NIGHT 2 HELD CLEAN closing it.

  Known debt from review, deliberately deferred: the loadout row's
  fixed offsets overflow a portrait phone panel (predates this PR),
  and the new DetailsScroll has no gamepad focus path. One cosmetic
  mismatch noticed live: the HUD phase pill reads DAY · MORNING during
  repeating town nights — it follows the tutorial's PhaseService, not
  TownNightService. **All of that is closed by #327 above**, along with
  three action buttons that were off a portrait screen entirely.
- **#321–#324** (v134–v137) **the first two legs of the walkthrough,
  recorded here after the fact** — these merged from a parallel session
  without a status entry. #321 took the hundred and twenty benches back
  out of the plaza (the crafting maze made the town unplayable), #322
  stopped the world being solid where a phone cannot see it yet
  (tap-eating placeholders and mobile mesh streaming), #323 fixed what
  the first real playthrough hit (Mara's rescue, the plot shadow, click
  volumes, the title screen), and #324 the second (consumable buttons
  anchored off-screen, the field book opening empty between server
  pushes). Together they walked title → lodge → departure → full
  tutorial → town crafting and equipping → expedition entry.
- **#320** (v133) **all twenty-seven residents are authored, and the
  derivation is a safety net rather than a path anybody stands on.**
  Chapter VI's four out of the Crown and chapter VII's four out of the
  Hollow finish what #316 and #318 started. Sabine will not blow
  anything shaped like a person and breaks the day's casts at dusk
  behind her own works; Theo copies the town board in the last of the
  light and then the names scratched into the planks under it; Delia
  reads the day's name out at the town rather than into the wall; Bran
  counts beams nobody ordered. **Orin Vale is the one entry that reads
  the ending** — the roster's only `requiresEnding` — so he is in town
  for `ending_ended` and `ending_shared` and not for `ending_kept`,
  because if the light was kept somebody is still down there tending it.
  His day faces up the road at the First Lantern from the lamp house
  door, his dusk is at its foot, and his night is a post in the middle
  of the line rather than the lonely end of it, which is the entire
  point of him.

  **The census inverted with the wave, and that is the durable half.**
  It used to assert a count of authored bodies; it now walks
  `ResidentRoster.list()` and demands a body for every name, so a
  twenty-eighth resident fails a spec on the day somebody adds them
  rather than landing silently on the floor. The derivation is
  untouched and now catches that case instead of carrying eight people.
  The same pass removed the last silent fallback beside it: the prop
  lookup's `or RESIDENT_PROPS.seed_basket` is gone (a mistyped prop
  rendered as the seedkeeper's basket, which is the eight-names bug in
  miniature), and a new case refuses a resident who names a prop
  nothing builds.

  **The camera threw out three of the eight props again.** The
  glassblower's gather was a torch, because a rod with an opaque
  fireball on the end is a torch whatever the rod is — it needed a
  nearly clear skin over a bright core and a vessel profile rather than
  a sphere. The framing square was a ruler with a handle: a try-square's
  stock reads as the end of the long arm, so both arms became the same
  steel at a right angle and the nine graduations came down to four.
  The sounding lead was a bolt with nuts run down it, because a
  straight line of even thickness is a shaft — the cord kinks now and
  the weight is one long ellipsoid instead of a stack of discs. The
  snare's teeth sat at the same radius as its jaws and it photographed
  as a gear, so they moved inside the ring in bright steel against a
  darkened pan. Hung on a real R15 rig, two more failed: the speaker's
  staff ran straight through the upper arm and now leans 26 degrees off
  the hand, and the vial's thong put its knot inside the forearm and
  stops at the fist. Closest ground clearance is 0.98 (the lead).
  Positions were checked in each phase against each other, Mara and
  every footprint; the closest pair in town is still Ena and Pip at
  9.06, and the tightest new footprint clearance is Ruth at 6.50 in
  front of the celebration stage.
- **#319** (v132) **M11 wave A: a party is a named thing now.** What the
  lodge has had since it shipped is a platform — whoever is standing on it
  when the countdown ends boards, in whatever order `Players:GetPlayers()`
  returned them. That is several people leaving at once, not a party, and it
  survives nothing: not a bystander who wandered onto the dais and took the
  fourth seat, and not a disconnect, because a run server is reserved and a
  player who drops out of one has **no way to name the world their friends
  are still in**. `PartySession` (pure) owns identity, roster, invitations
  and the ticket home; `PartyService` owns the live parties and the teleport
  that spends one; the departure payload carries the party id, so a run
  server recognises its own returning members instead of forwarding them into
  the world they are standing in.

  Three decisions worth carrying forward. **The invite press names nobody**
  — it offers a seat to whoever the server can see on the platform, measured
  by LobbyService's own occupancy reading, so a press cannot be forged into
  naming a stranger across the map and an invitation can never disagree with
  a boarding pass about who was on the dais. **The travelling party is the
  boarding list, not the friendship group**, because a party of three that
  chose four seats picks up a stranger and the stranger is in that reserved
  world too; a ticket has to name the world's population or they have no way
  home. And **the ticket the server holds and the fact the client sees are
  different objects**: the stored ticket carries a reserved-server access
  code, which is the entire key to a private world, and
  `PartySession.publicTicket` builds the client's half by construction rather
  than by remembering to omit a field. Save schema 21 → 22 with an era-21
  fixture; a rejoin ticket is the one saved field that resolves to a
  teleport, so a forged one is refused outright.

  Also written this wave: **[WAVE_PLAN_M11_M14.md](WAVE_PLAN_M11_M14.md)**,
  the queue for the rest of the roadmap.
- **#318** (v131) **nineteen residents are authored now, not eleven.**
  Chapters IV and V's eight — the Reach's four and the Vale's four — get
  what #316 gave chapters II and III. That is the whole cast of the half
  of the town a player only reaches after the storm coast and the frozen
  valley, and it is also the half whose tier four and five buildings had
  shipped as procedural shells with nobody in them. Day puts each of them
  at their own building (signal house, ropewalk, trade post, waterworks,
  bell tower, infirmary, cold store, almshouse); dusk is the hour that
  costs them something — Isolde south of her signal house with the lamp
  lit behind her and nothing in front of it, Halvard locking the store,
  Maud standing in the one door she has holding it open; night puts all
  nineteen down the length of the lantern road. Positions were checked in
  each phase against each other, against the eight spots the Crown and
  the Hollow still derive, against Mara and against every footprint; the
  closest pair in town is still Ena and Pip at 9.06.

  **The camera threw out three of the eight new props.** The bell clapper
  was a bolt until the ball became four times the shaft and the flight ran
  past it; the grapnel was a microphone stand until the barbs turned back
  up, because the corner is the whole shape; the keyring was a lollipop,
  all ring and no keys, and a keyring is mostly keys. The mortar was a
  pail and is a bowl. The lamp, the rope coil, the balance and the warming
  pan read first time. All six were then hung on a real R15 rig, because a
  prop that drops a stud below the grip can end up in the ground — the
  closest clears the sole by 0.93. Same lesson as #316's five and #251's
  six creature shapes. The remaining eight residents still derive, and the
  census asserts nineteen authored bodies.
- **#316** (v130) **eleven residents are authored now, not three.** The
  derivation from #313 is a floor and stays one; what moved is how far
  above it the authoring reaches. Chapters II and III's eight — the
  Delve's four and the Fen's four, which is the whole cast a player meets
  next after the three they start with — have their own colours, their
  own prop and their own day, dusk and night. Day puts each of them at
  the building the roster gives them the job at. Night puts all eleven on
  the lantern road between the square and the south gate, spread out,
  because DEFENDING THE LANTERN ROAD is what the routine's night duty has
  always said and eleven people saying it from one spot is a crowd rather
  than a watch. Every position was checked against every other in the
  same phase, against the sixteen derived spots, against Mara and against
  every building footprint; the closest pair in town is 9.2 studs.

  **The wave's real lesson is the second commit.** The props started as
  one part each with a size, a colour and a material — which is what the
  three that already existed were — and that breaks
  VISUAL_QUALITY_STANDARD's rule that a recoloured cube is not
  construction. Rebuilt as assemblies, then **built in Studio and
  photographed, which found five of the eleven were still boxes**: the
  cookpot and the seed basket had to be round (a Roblox cylinder lies on
  its side, so a vessel is tipped a quarter turn), the basket needed its
  base narrower than its rim, the bell had to widen on the way down, the
  shears' blades were five degrees apart and read as a single needle, and
  the mireglass shard was a white smear until it was tinted and set in an
  iron holder. Same lesson as the six wrong creature shapes in #251:
  **nothing but a camera catches a shape.** The sixteen residents of
  chapters IV–VII still derive, and the census now asserts eleven
  authored bodies so that number can only move deliberately.
- **#306–#313** (v129) **the reachability sweep, which is the most
  important thing in this header.** A live Studio pass — possible at all
  because #307 finally made the tutorial skippable in Studio, where it
  belongs, in TutorialService rather than ProfileService — went to look
  at two rewritten HUD surfaces and instead found that **120 of the 130
  recipes had no bench to be crafted at** (#309, fixed in #310 by
  deriving benches and interaction ids from the catalog), and then, on
  asking the same question about people, that **24 of the 27 residents
  had no body in the town** (#311, fixed in #313 by deriving a body from
  the roster when none is authored).

  Both had passed every spec for a milestone. The generalisation is
  written into CONTENT_CATALOG.md beside them and is the thing to carry
  forward: **a thing existing in a catalog and a thing being reachable in
  the world are different facts, and only the first one is easy to
  test.** Anywhere a hand-written table in WorldService mirrors a shared
  catalog deserves the same suspicion. Decorations, town buildings and
  encounter arenas were swept and are clean (#312).

  Both census cases now assert the *derivation* rather than the count,
  because in both cases the silent fallback — a skipped resident, a
  missing bench — is exactly what made the gap invisible.
- **#304** (v128) **Mastery trials and region mysteries** — the two quest
  families that had a dependency rather than a design problem. Objectives
  can now be *keyed*: one names a profession, another names a region, and
  only that one's progress counts. Without the key both would have been
  fakeable with a plain count, and badly — a mastery trial reading total
  levels would let a player who dabbled in seven professions clear the
  scout's trial without ever scouting. Seven trials at mastery four, six
  mysteries asking for exactly what each region holds, and a spec that
  refuses a mystery asking for more memories than its region has, because
  an unfinishable quest only ever shows up in a player's log.
- **#301–#302** (v126–v127) **M10 waves B and C: arcs, and an archive
  bigger than one region.** Quests can be sequenced — a stage whose
  predecessor is unclaimed does not progress, is not offered and cannot
  claim itself, and a pass claims at most one stage per arc, because
  every quest here claims itself on satisfaction and without the lock a
  player who crafted forty things on day one would have finished Tomas's
  whole arc before he asked for anything. Chapter one's three get the
  first arcs. Then the archive: 10 fragments became 20, two per surface
  region, with a `regionId` on each so a run places only its own, and a
  resolver that no longer assumes Bramblewake's `PhysicalPOI_<id>`
  wrapper — the later regions' shared builder makes a bare anchor, and
  both now resolve. The Hollow gets none on purpose.
- **#298–#299** (v124–v125) **Bramblewake stops being the thinnest
  region.** Eight new points of interest across the region's three acts,
  with a new generator rule — a catalog can pin POIs into every run — so
  the four fragment anchors stay guaranteed while the eight new ones
  rotate two per run; the other five regions generate byte-identically,
  verified against a stashed baseline. Then eight armour pieces with the
  gentlest numbers in the game, closing the last census gap at 130
  recipes. Each wave also closed a trap it found: the root chapel had
  been the POI dispatch's `else` (any unknown visual silently drew a
  chapel), Bramblewake's builder was in no coverage spec, and the equip
  panel was a hardcoded list of eight items — which after A-1 meant
  ninety craftable items nobody could ever wear, failing nothing.
- **#296** (v123) **M10 A-3 and D: the counters, and an honest census.**
  Built by asking which threats this game creates that a player cannot
  answer, rather than which categories would reach 180. The spark thieves
  took the lantern and nothing a player carried put any back; the drowsy
  strikers took your footing with no response but fighting better; gear
  wore out a long way from the only bench that could fix it. So three new
  effect kinds, each a real service change: lantern restoration capped at
  the hundred a night starts at, an affliction cure that deliberately
  leaves the player's own shield alone, and a field repair with no
  material cost because the item was already paid for when it was
  crafted. Eighteen consumables on those, 122 recipes, and the gate moved
  from 180 with the reasoning recorded. `ContentCensus.spec` now asserts
  the whole inventory against the document — and records two gaps in
  Bramblewake rather than filling them with content nobody designed.
- **#294** (v122) **M10 wave A-2: consumables became data.** Each usable
  item was three hardcoded branches — one deciding its effect, one
  drawing its button, one deciding which id a keypress sends — which
  survives at two items and not at sixteen. Now an entry names an effect,
  an amount, the precondition that must hold before the item is spent,
  and what the toast says either way. The HUD draws a short column and
  fills it with whatever a player is carrying, stamping each button with
  its current item, so C and V ask the button rather than a constant.
  Fourteen new consumables needed no input or HUD code at all. A spec
  reads the three files that used to hold item names and fails if any
  still does.
- **#292** (v121) **M10 wave A-1: 10 recipes became 90.** Six weapon
  families in every region and five armour slots in two lines each, with
  the rule that a region is an axis rather than a tier — the Delve makes
  everything heavier, the Fen longer, the Reach further, the Vale
  lighter, the Crown better at taking a hit — and a spec that refuses two
  regions whose version of a family has identical numbers. Two things had
  to be fixed to make it real: `body`, `hands` and `charm` had no
  attachment point in `GearVisualService`, so anything in those slots
  would have equipped invisibly; and `GearVisualPlan` now derives a plan
  from family plus region palette, marked `derived = true`, so 82 items
  are a labelled floor rather than eighty invisible ones. **The art pass
  that replaces the derived plans is owner-gated, alongside mesh
  dressing.**
- **#284–#290** (v114–v120) **Milestone 9 finished — the game has an
  ending.** **#284** Cinderfall Crown, whose hazard is that it is still
  going: the parade still on its route, the crowd still facing the stage,
  and a rule that a memory can be false. **#285** its six, the Lead Actor
  (a readable line, where a wrong answer costs the line rather than
  health), the Glass Bailiff (its openings are bought with the party's
  own cover) and the Ash Regent, whose four phases make the fast way
  through the Crown the destruction of the only record of its dead.
  **#286** thirty visuals that draw the tell rather than describing it —
  performing casts are posed and seamed, authentic ones are neither.
  **#287** The Hollow Below, the one authored place in the game: five
  scenes rather than five phases, the two trapped people named by the
  save rather than the module, and per-scene transaction ids because a
  disconnect at the bottom must not resolve a finale twice. **#288**
  chapters VI and VII, schema 21's `story.finale`, and an epilogue that
  reads every resolved chapter plus what happened in the Hollow —
  spec-walked across all 54 outcome/ending combinations. **#289** tiers
  six and seven with the last six buildings (28 total). **#290** the
  final eight residents including Orin Vale, whose presence is the one
  thing in the game that reads the ending directly: put the light out or
  share it and he walks up; keep it and somebody is still down there
  tending it, and it is him.
- **#277–#283** (v108–v113) **Milestone 8**: Frostmere Vale end to end,
  chapters IV and V, town tiers four and five, eight more residents. Two
  gaps closed along the way — the Reach had shipped three encounters with
  no arenas, and `chapterReached` was answering yes for regions no
  chapter named.
- **#277–#282** (v108–v113) **Milestone 8 finished**: Frostmere Vale from
  catalog to town. **#277** the Vale's catalog (30 modules, 12 POIs, 8
  events, 5 materials) around one rule — warmth is a resource, and
  nothing here is safe because it is indoors, it is safe because
  something in it is still burning. **#278** its six enemies, the Abbey
  Silence (takes sound, leaves sight; three cloister bells put it back),
  the Aurora Hart (never destroys warmth, only divides it) and
  `boss_white_howler` in three phases — quiet the bowl, share the
  warmth, read the aurora in order — whose middle verb is chapter V's
  decision. **#279** the Vale's thirty visuals, which also turned up that
  the Reach's three encounters had shipped with no arenas at all; both
  regions' arenas are filed now and the coverage spec's expected list ran
  from three to twelve. **#280** chapters IV and V, which closed a gate
  that had been standing open: `chapterReached` returns true for a region
  no chapter names, so the Reach and the Vale would have opened to a
  chapter-I player the day their flags flipped. **#281** town tiers four
  and five with six buildings to grow into (signal house, cold store,
  almshouse, ropewalk, bell tower, infirmary — 16 → 22). **#282** eight
  more residents, four per region, 11 → 19, with a spec that walks every
  quest with every signal raised so an unrouted objective kind cannot
  reach a player as a promise the game has no way to keep.
- **#274–#276** (v105–v107) **M8 waves A–C: Tempest Reach** — catalog,
  roster, the Lighthouse Eater (windows are rented, not bought), the
  Admiral Wreck (cover comes back if a party lets go), the Tidebound
  Titan (climb, ground, lower, in that order every phase), and thirty
  visuals whose identity is exposure. #276 also wrote
  [WAVE_PLAN_M8_M10.md](WAVE_PLAN_M8_M10.md), the queue that lets a cold
  session start warm.
- **#266–#272** (v98–v103) **the new regions went from content to
  runtime**, and the session's own blind spot got closed first:
  **#266** an action-wiring spec that reads the ids, the contract, the
  server's branches and the client's senders — the gap #219 and #249 both
  came through; it also surfaced that RuntimeIds.Actions holds two kinds
  of id (sent kinds vs interaction ids stamped on prompts), now policed
  separately. Then **#267** a readiness gate (a region is refused unless
  its builder can draw a walkable world, even if the flag is flipped),
  **#268** resource nodes with every material put through the ledger,
  **#269** POIs and event sockets with one anchor per event step,
  **#270** arenas whose interaction anchors come from the encounters' own
  id lists, **#271** RegionEncounterService driving all six new fights
  instead of six 800-line services, **#272** wayfinding trails. Both
  regions now owe only authored mesh dressing.
- **#264** (v97) **M7 wave L: Mireglass Fen's geometry** — all thirty
  visuals, built as the Delve's opposite. The Delve reads as underground
  because every module carries a roof; the Fen reads as drowned because
  every module carries water you cannot trust, glassy enough to mirror
  the sky. Verified live: the pools carry clouds. Three modules exist
  because encounters need them (the mirror court is the Many-Face's, the
  bell marsh's four pools are the Drowned Caller's doors, the witchlight
  ring is where the Lantern Witch stands). **Both new regions now have
  complete module geometry**; RegionBuilderCoverage checks both catalogs
  against both builders and pins both enabled flags false.
- **#261** (v96) **M7 wave K: all thirty Delve module visuals now have
  geometry** — the remaining twenty-one rooms (oil works, echo vault,
  flooded stope, abandoned face, scaffold climb, collapse scramble, winch
  crossing, mite nest, slag channel, guard round, gas pocket, echo
  gallery, shored drift, junction round, rail siding, air door,
  foreman's office, miners' rest, memorial drift, signal room, flood
  locks) plus seven primitives. The wave's real deliverable is
  **IronrootBuilderCoverage.spec**: it reads the builder's source and
  fails if any visual the catalog can place has no case, because a module
  drawn into a manifest with no geometry is an empty cell a player walks
  into and nothing else in the suite can see it. The same spec pins the
  region's enabled flag false, so coverage and the flag move together.
- **#259** (v95) **M7 wave J: the Delve's geometry begins.**
  IronrootBuilder holds the region's own vocabulary — shoring timber,
  rail, ore carts, cut rock, spoil, coalglass, glow fungus, lamp posts —
  and nine module visuals built from it. The shape doing the most work
  is the shoring bay: a low roof on posts cuts the horizon to head
  height and makes the place read as underground while the sky is still
  technically there. **All nine were built in Studio and photographed
  before the commit**, which is the difference between this wave and the
  blind ones that cost six enemy shapes. buildModuleVisual returns false
  for an unknown key, so the region stays honest about being half-built;
  Ironroot stays disabled until every catalog key has a case.
- **#257** (v94) toasts were reading raw item ids to the player
  ("EQUIPPED GEAR_AMBER_EDGE"); equip and whet now use the catalog's
  display name. Closed live in the same run: the **Watch defender**
  posts at the Meadow Gate plot on a solo town night and stands down at
  dawn, and the **gear-care chain** carries a crafted blade's rolled
  trait and condition to the client (KEEN, sound) with the whet target
  correctly absent. Only the WHET *press* remains, and it needs a weapon
  that has actually dulled (~30 landed strikes).
- **#255** (v93) **an armed snare could never bite on the tutorial's
  night** — the trap gated on the service's own night flag, which only
  TownNightService raises, so three plots sat lit while a rootling, a
  briarback and a hollow zombie walked their rings. It now asks the enemy
  service where the walker is. Verified on the fix: "THE SNARE BITES —
  BRIARBACK IS HELD", ember cold on the second charge. **The defense-plot
  wave now has no open checks.**
- **#251 / #253** (v91, v92) **the live session kept paying out**:
  building all twelve Delve/Fen creatures in Studio and photographing
  them found **six wrong shapes** — four parts sized on the wrong
  cylinder axis (the Slag Spitter's pool standing as a bar through its
  body, the Bog Bell's ground marks floating as bars, the Rail Hound's
  wheels buried inside its own chassis so it read as a floating plank,
  the Crank Guard's mechanism a squashed tube), the Gas Bloomer's petals
  pitched before yaw so the bloom read as a saucer, and the Mire Leech's
  mouth. All six passed 608 tests and a build verification; nothing but
  a camera could have caught them. Then **#253**: a Studio-only
  `LastLightStockProfile` hook (three guards: Studio, non-persistent,
  logged) so a verification run stops costing a full playthrough — used
  immediately to close the snare-arming check that had been open since
  the plots shipped ("THE MEADOW GATE SNARE IS SET — 2 BITES IN IT", 2
  fiber and 1 heartwood spent exactly, ember lit).
- **#248 / #249** (v89, v90) **the first live session of this stretch,
  and it found three defects no test could see** — every part of each
  one that a test can read was correct:
  1. The **party-size button still showed nothing**. #219 fixed the
     payload half; the selection half was never implemented, so a press
     made off the platform (correctly refused by the server) left the
     panel pixel-for-pixel unchanged. That is the owner's "no number is
     selected", finally whole. Chosen size now highlights and the panel
     reads PARTY OF n.
  2. The **hound's FOLLOW/STAY order had no button**. CompanionCommand
     existed server-side complete with contract, handler and toasts, and
     nothing on the client ever sent it — half of companions was
     unreachable in the shipped game.
  3. **FoundationIntegration asserted fixtures the seed never placed**
     (memory-fragment census, rotor motion), so it failed on most seeds.
     Both terms now derive from the placed manifest.
  Also confirmed live: defense plots stand on their three lanes at 46
  studs with working detectors; the hound follows at the flank and
  settles; PASS FoundationIntegration on a fresh boot. Ledger of what
  closed and what remains open:
  [MILESTONE_7_REGION_WAVE_A.md](MILESTONE_7_REGION_WAVE_A.md).
- **#245** (v88) **M7 wave I**: RegionAccess — the departure's region
  seam. Enabled-flag + dependency + chapter gates compose in one place;
  everything not open resolves to Bramblewake; ExpeditionService boots
  through it (LastLightExpeditionRegion attribute pins it in Studio)
  with a load-bearing assert against enabling a region that has no
  builder. Chapter gates spec-pinned ready: when a region builder lands,
  flipping its `enabled` flag in Regions.luau is the whole switch. No
  player-visible change.
- **#243** (v87) **M7 wave H**: town tiers 2–4, story-gated. Nights
  alone still cap at tier 3 (bit-identical, pinned); resolving the Maw
  raises the ceiling to 4 and floors the tier at 2, the Witch floors it
  at 3. Tier 4 matures late buildings a further stage through existing
  curves (no new ids — those need geometry). The cast is now derived
  from ResidentRoster by chapter progress, and the new specs caught a
  real bug: merge() hardcoded chapter I's three names and would have
  silently evicted every later arrival from a merged shared town. Also:
  "remaining basic profession kits" was verified already complete — all
  seven professions have ability + visuals + mastery specializations
  since M6 wave A.
- **#241** (v86) **M7 wave G**: chapters II and III. ChapterCatalog
  describes all three chapters (region, closing boss, decision, outcomes
  — the Maw's and Witch's own outcome words, spec-pinned against drift);
  chapters II+ store uniformly under story.chapters with chapter one's
  idempotency contract (duplicate / rival / locked / forged-drop);
  SaveSchema.chapterProgress drives resident arrival. Schema 19 → 20
  with an era-19 fixture; the two specs that asserted the literal 19 now
  read Config.SaveSchemaVersion.
- **#239** (v85) **M7 wave F**: the eight named residents (four from the
  Delve, four from the Fen) and **ResidentRoster**, which now holds
  identity, home region, arrival chapter, job and quest in one place —
  ResidentLife and ResidentDialogue read from it, and chapter I's three
  keep their exact ids, order, jobs, titles and boons (spec-pinned).
  Arrival is chapter-gated, so a fresh save still meets exactly three
  people. Eight new quests with five new signals, all derived from facts
  the profile already stores (materials, construction stages,
  decorations, rolled traits, bonds) — no new tracking.
- **#237** (v84) **M7 wave E**: Mireglass Fen entire — catalog (30
  modules, 12 POIs, 8 event_mg_* events, five materials), six enemies
  that wait rather than charge, the Many-Face (read-and-time: an open
  profession guard stripped by the answering mirror for a short window),
  the Drowned Caller (arithmetic: silting its four reflected pools wounds
  it and calms the marsh; leaving them compounds the summons), and the
  Lantern Witch closing chapter III with identify → use copies → consent
  seal and three outcomes decided by play. EnemyCatalog now spans three
  regions with Bramblewake's order still pinned.
- **#235** (v83) **M7 wave D**: the Bellows Maw, chapter II's boss. Three
  phases that read the catalog's non-profession solution literally —
  reroute feed lines (2 → 3 → 4 as phases ratchet), vent the pressure,
  strike the open core — gated in that order. The vent wheel chosen is
  the chapter decision (cleared / fouled / mixed), remembered the way the
  Warden's antlers are. Chamber locked until the Delve's elites are done.
- **#234** (v82) **M7 wave C**: the Delve's two elites. Foreman Echo is
  authority (untouchable while it holds the signal board; three levers
  strip it; two board-seizes reset them), the Iron Widow is tempo (each
  web anchor cut buys a strike window that closes on its own, progress
  never unwinds, the ambush cadence eases as the fight closes, the last
  cut keeps her down). Same contract as the Old Growth: solo-passable,
  profession-independent, one reward per participant per run.
- **#233** (v81) **M7 wave B**: the Delve's six enemies and EnemyCatalog,
  one roster over all regions injected into EnemyService in place of the
  direct Bramblewake catalog (Bramblewake's order preserved exactly and
  asserted). The Delve hunts the player more than the forest does and
  outruns it; the Crank Guard proves the existing combat rules already
  carry its flanking lesson (8 to the face, 44 to the flank).
- **#231** (v80) **Milestone 7 wave A**: the Ironroot Delve catalog (30
  modules, 12 POIs, the 8 reserved event_ir_* events with contracts and
  Delve-material rewards) and a region-agnostic ExpeditionGenerator —
  pool, counts, budgets, required tags and the fallback walk all arrive
  from a catalog, so adding a region is adding a catalog plus a line in
  CATALOGS. Content placement now stops at the run's count rather than
  the pool's end, and the event namespace rule reads "a regional
  namespace". **Bramblewake is bit-identical**: 400 seeds plus the
  fallback compared old-vs-new, zero mismatches, fallback still
  2b08c29f. The five Delve materials joined the ledger allow-lists in
  the same change (the #212 lesson: an unlisted reward pays nothing,
  silently).
- **#229** (v79) gear care — **Milestone 6 is source-complete with this
  wave.** Passive gear wears from mitigated hits (1 point/hit vs the
  weapon's 2/strike) through a new per-item effectiveness seam in
  Equipment.stats (worn halves a piece's contribution, failing removes
  it, traits fade with the same factor; no-wear path spec-pinned
  bit-identical, and no schema change). The Field Book gains the WHET
  button (server-composed gearCare/whetTarget payload; fires the
  existing RepairGear action) and trait/condition annotations on equip
  buttons ("EQUIP EDGE ×1 · KEEN · WORN"). Drive-by: the equip-button
  refresh still hardcoded hood/boots labels, so all six weapon buttons
  read "EQUIP BOOTS ×N" — labels now come from BaseLabel attributes.
- **#227** (v78) defense plots — three authored approach lanes (Meadow
  Gate = the pre-lane straight approach, yaw 0, spec-pinned
  bit-identical; East Hollow and West Break as rotations about the
  lantern; wave 1 always the gate, later waves rotate
  deterministically), a permanent armable snare plot per lane (ArmClick
  ClickDetector — no new client payload; 2 fiber + 1 heartwood spent
  atomically via the new SaveSchema.withSpentMaterials, no schema bump;
  two bites per arm, a bite = the sling's snare timer so the "exposed"
  ×1.2 reaction applies), and the solo-night Watch defender (chips 3
  every 7s, health floors at 1 so defeats stay player-owned). Open live:
  plot placement on real terrain, arm-by-tap, bite toast, Watch
  silhouette.
- **#225** (v77) companions v1 — the Beastkeeper's briar hound: while the
  profession is worn in town (not on expedition, not downed), a
  procedural hound is summoned at the keeper's flank and follows with
  anchored PivotTo stepping (no Humanoid, no pathfinding); FOLLOW/STAY
  rides CompanionCommand with a "mode" field, allow-listed in the same
  commit. Pure motion math in CompanionMotion (number pairs — the shared
  layer stays free of Roblox datatypes; a first draft using Vector3 in
  shared failed typecheck, which is the enforcement working). Open for
  the next live session: hound visual read, follow feel, command toasts
  via a real button press.
- **#224** trading risk review — **trading does not ship for launch**;
  decision and reasons in docs/MILESTONE_6_TRADING_RISK_REVIEW.md so it
  is not re-litigated. Narrowest post-launch shape recorded there.
- **#223** (v76) equipment traits — every craftable rolls one trait at
  first craft, deterministically from hash(itemId, save createdAt): keen
  / balanced / tempered for weapons, sturdy / light for passives, folded
  inside the existing stat clamps; re-crafting keeps the first roll.
  Schema 18 → 19, era-18 fixture.

Earlier waves in this stretch:
- **#218** (v72) equipment wear/repair — weapons dull with landed strikes
  (sound/worn/failing thirds; worn halves the damage bonus and drops the
  riders, failing falls back to bare hands), whetting costs half the
  item's recipe via a RepairGear action; schema 17 → 18, era-17 fixture.
- **#219** (v73) **the owner's twice-reported departure bug, finally
  root-caused**: since contracts shipped, the real party-size button sent
  partySize plus contractId, and ActionPayloadContract's one-extra-field
  allow-list silently dropped every real press before any handler ran.
  Synthetic remote tests sent partySize alone, which is why they passed
  while every human press failed. Verified with a REAL mouse click this
  time. Lesson recorded at the fix: any client payload gaining a field
  must update the allow-list in the same commit, and flow verification
  must press the real button.
- **#220** (v74) the status/reaction system — stilled = bound open
  (forced flank, ×1.25, beats the Briarback's shield head-on), snared =
  exposed (×1.2), drowsy striker swings soft (×0.85); clamped 0.6–1.6;
  reactions name themselves in the toast; no-reactions path bit-identical
  by spec.
- **#221** (v75) from the owner's tablet screenshot: the Old Growth heart
  (and Warden Stag) had no StrikeClick — on touch, where the tap IS the
  strike, the encounter was undefeatable; both now carry the night
  creatures' detector recipe. The red telegraph banner also moved from
  mid-screen to above the touch action row.
- **#216/#217** (v71) loadouts (schema 16 → 17): three saved kits.

M7 waves A–F are merged and published: **both regions exist as rules and
data** (catalogs, rosters, elites, bosses) and **the eight residents
exist as people** (roster, jobs, quests, dialogue), all spec-pinned.
**Every source-side M7 deliverable is now merged and published**, and
the region-selection runtime seam is in (#245). What remains for M7 is
geometry, which most wants Studio: builders for both regions' 60 module
visuals, elite/boss services and arenas for the four new elites and two
new bosses, and physical placement for the eight new residents. These
are large waves best driven with a live Studio session; the switch for
each region is one `enabled` flag once its builder exists. The full
state of the milestone and every deferred live check:
[MILESTONE_7_REGION_WAVE_A.md](MILESTONE_7_REGION_WAVE_A.md). M6 remaining: only the
recorded live checks, all blocked on Studio availability (kit apply, gear dulling arc, hound visuals/follow feel,
defense plot placement/arm-by-tap, WHET press on device, Blackout drive
to the Old Growth on a touch path). Every source-side deliverable is
merged and published. **Milestone 7 is next**: Ironroot Delve +
Mireglass Fen, chapters II–III, the content counts in the roadmap,
town tiers 2–4. M7 (regions wave A) has not started. #214 added the enemy director: town-night
wave counts scale with the defenders standing in town (solo nights pinned
bit-identical by spec; +1 wave per extra eligible defender to a ceiling of
twelve, census taken once at nightfall and logged). **#212 matters beyond its size**: driving
the harvest → bank → craft → equip → strike loop end to end for the first
time revealed that no resource node had ever paid out (wrong reward shape
at the grant call site) and that a completed save could not strike
town-night enemies at all (the combat gate ignored its own
eligible-stages helper). Both fixed and re-verified live in one run, with
the pick's harvest discount and the Amber Edge's stamina refund measured
exactly. The economy works now; it did not before.

---

## Where the project is

**Milestone 3 (Bramblewake vertical slice)** is implemented in source; its
Studio and device exit gates remain pending owner playtest evidence — though
see #206: the Studio half of that evidence is now genuinely reachable, and
`[Last Light] PASS FoundationIntegration` has printed for the first time.

**Milestone 4 (persistent town platform)** is actively in flight and most of
its deliverables have landed. The authoritative checklist is
[PRODUCTION_ROADMAP.md — Milestone 4](PRODUCTION_ROADMAP.md); read the gate
there, not a copy here. Note the gate's own caveat: the layout validator only
guards footprint clearance from source — the gate itself still needs a live
Studio pathfinding pass.

**Milestone 6 (complete systemic foundation) is three waves in.** Wave A
(#206) landed all seven professions, wave B (#208) the six weapon
families, and wave C the eight tool families (`ToolCatalog`, all eight
displays in the yard, post-tutorial swapping, live-verified endurance
identities — see [MILESTONE_6_TOOL_FAMILIES.md](MILESTONE_6_TOOL_FAMILIES.md)).
Still open: loadouts, repair, equipment traits, the status/reaction
system, companions, the enemy director, and defense plots. Open live
checks: weapon per-family strikes (needs the crafting economy loop —
[MILESTONE_6_WEAPON_FAMILIES.md](MILESTONE_6_WEAPON_FAMILIES.md)) and
pick/sickle harvest timing + the survey marker on a real trail.

## Recently landed (PRs ~#151–#208)

Verified against `git log`, newest first:

- **Landed in #369 and completed by #370:** the Linux Studio-MCP wrapper, corrected
  against a machine it was actually run on. `scripts/studio-mcp-wrapper.sh`
  shipped in #178 searching the Wine prefix for `StudioMCP.exe`, and was wrong
  twice over: the launcher Studio writes is **`mcp.bat`**, and Vinegar
  redirects `%LOCALAPPDATA%` *out of the prefix* onto the host through Wine's
  `Z:` drive — so a search rooted at `drive_c` searches the one directory the
  file is not in. Both facts came from the owner's terminal, not from
  inference; the honest search is `find ~ -name mcp.bat`. The wrapper now
  probes Vinegar's Flatpak and native appdata plus the plain-Wine `drive_c`
  layout, converts the host path with `winepath` (falling back to the `Z:`
  mapping), and runs `cmd /c "cd /d <dir> && mcp.bat"` — the invocation that
  reached `✔ Connected`. It also says so when Wine is missing, because
  Vinegar's Flatpak runtime does not export a `wine` binary and the host must
  supply one.

  Codex then caught a third bug in the fix: the candidate list was still
  *absolute*, so a machine carrying both a Flatpak and a native Vinegar could
  pair an explicitly set `WINEPREFIX` with the other installation's launcher.
  Every candidate now derives from the selected prefix — Vinegar keeps
  `<root>/prefixes/studio` beside `<root>/appdata`, so the pairing is
  derivable — and the last-resort search is no longer a global `find` but a
  question put to Wine itself (`echo %LOCALAPPDATA%` under that prefix), which
  is prefix-tied by construction.

  A script that had now been wrong three times got a test:
  `scripts/test-studio-mcp-wrapper.sh` runs the wrapper against throwaway
  layouts with a stub `wine`, wired into `npm run check`. Its own limit was
  named plainly — the stub never runs a real `cd`, so it cannot tell a Windows
  path string that merely looks right from one Wine actually accepts. That gap
  is exactly where the fourth bug lived.

  On the owner's actual machine, the fixed wrapper still failed to launch.
  Discovery was correct — the log named the right `mcp.bat` — but the launch
  itself hit `Path not found.` from a `win_dir` that was, byte for byte, the
  same string the owner's own manual `%LOCALAPPDATA%` expansion had reached
  successfully one line earlier in a prior session. Two independent
  investigations of that failure converged on the same underlying lesson from
  different angles — Wine's `cmd.exe` accepts a Windows path built one way and
  refuses the identical string built another — and produced two different,
  both-real fixes, landed close enough together that this file briefly told
  each one as if it were the whole story:

  **#370, the fix that actually closes the failure for the common case**,
  found that invoking the exact versioned `StudioMCP.exe` Roblox writes into
  `mcp.bat`'s own first branch sidesteps the problem entirely — no `cd` at
  all, so there is nothing for `cmd.exe` to refuse, and no batch parser left
  to emit the `Syntax error: unexpected ELSE` it can raise from `mcp.bat`
  after the MCP process exits. That launch was confirmed for real: a genuine
  `initialize` response (`RobloxStudio` 1.0.0, protocol `2025-06-18`), Claude
  reporting the server connected, and a fresh Codex session completing
  `roblox-studio/list_roblox_studios`.

  **This branch's own fix (folded in here as part of resolving a merge
  against #370) hardens the batch route that direct-exe launch falls back to**
  when `mcp.bat` cannot be parsed for that path. That fallback still built a
  host-translated `cd /d "Z:\..."` — the exact string #370 proved Wine
  refuses — so it hands Wine the literal, unresolved `%LOCALAPPDATA%\Roblox`
  instead and lets Wine expand its own variable, for every discovery path
  that is that variable by construction. Codex then found the one
  construction that is not, on this branch's own PR: a plain Wine prefix can
  hold more than one Windows user profile, and the `drive_c/users/*` glob can
  match a stale one while Wine's `%LOCALAPPDATA%` currently answers for
  someone else. That candidate is now checked against Wine's own answer
  before being trusted.

  The test suite grew to twenty-one cases holding both fixes explicit —
  direct-exe launch from a generated batch file, the literal
  `%LOCALAPPDATA%\Roblox` form for every path proven to be it, the translated
  form for an override and for an unconfirmed multi-user match, and the
  multi-user mismatch itself, reproduced before being fixed — and still says
  outright what none of it can verify: the stub never runs a real `cd` or a
  real Wine process, so it cannot tell a Windows path string that merely
  looks right from one Wine actually accepts, or a `.exe` that merely exists
  from one that speaks the protocol. **A script wrong five times across two
  independent efforts, caught by static reasoning zero of those five times**,
  is the concrete argument for treating "the tests pass" and "it runs on the
  owner's machine" as two separate, both-required claims — and for reading
  this file's own header before starting the next session's version of this
  same fix a third time.
- **#368** Owner-playtest fix pass on Bramblewake —
  four reports from a real session, all four traced to source and fixed. All
  four were still present on `main` at #367; none had been fixed by the region
  waves that ran over them.
  - **Could not leave Bramblewake after clearing the area** — fixed, and it was
    the blocker. `ExpeditionService.extract` returned early on every
    `settleExpedition` failure without ever asking the world to move the
    player, and none of those reasons (`profile_read_only`, `save_pending`,
    `profile_loading`, a full unbanked pouch, a refused reward or settlement)
    can be cleared from inside an expedition. Because the empty-pouch branch
    exits *before* settlement is attempted, **earning rewards was what caused
    the trap** — a player who cleared the wood was strictly worse off than one
    who took nothing. Wayhome is a door, not a reward gate: the decision moved
    into the new `src/shared/ExtractionOutcome.luau`, every failure now leaves
    with the pouch unbanked, and the rewards stay unsettled in the session
    ledger and the profile's pending rewards so the next extraction retries
    them. Nothing is spent or discarded. A new `expedition_extraction_unbanked`
    warn records which reason fired, because the reports could not tell us.
  - **Old Growth: the lantern said to find the heart, and the heart was not
    there** — fixed. `rootHeart` and `fireSource` are both authored-mesh
    anchors, so `keepReplacedAnchorHidden` forced their transparency to 1 and
    disabled the billboards under them; all six colour/material/transparency
    assignments in `setOldGrowthPresentation` were dead code, and the objective
    had no label either. This is the third time this exact failure mode has
    shipped (`FirstLanternCore`, `BeaconCore` — see DECISIONS.md), and it is
    fixed the same way: `OldGrowthFireCore`/`OldGrowthHeartCore` carry the glow
    and the labels, the anchors keep only prompts, attributes and tags. A
    Studio assertion now fails if a label is ever parented to either anchor
    again.
  - **The arch is sideways** — fixed. `rootArch` turns its two uprights by the
    road's `facing` but pinned its crown to a hardcoded 45°, so the crossbeam
    sat askew over the posts at every module the route turns at; and the
    `root_arch` visual passed `facing` to the authored mesh while never passing
    it to the procedural arch underneath.
  - **Something blocking the rootfire relays** — fixed. The nine `RootedWall`
    parts this chapter's own doc calls "silhouettes" were built solid: three
    3.5-stud pillars with 2-stud gaps, 4.5 studs off each relay on the side the
    road arrives from, at all three relays, with an 18-second carried-fire
    timer running. Delivering fire recoloured them and left them collidable, so
    succeeding changed how they looked without changing whether anyone could
    get past. They are non-colliding and non-queryable now, which is what the
    chapter's traversal gate ("every carry is possible with base movement")
    already asked for.
- **#208** Milestone 6 wave B: **the six weapon families.** Heartwood Maul
  (1.45x melee ceiling), Briar Lance (full-strength 14-stud reach), Foxfire
  Sling (ranged 22, 0.7x, 2.5s snare at 0.75x speed — between the mark and
  the lure so stacked slows read), Amber Edge (1.1x, +6 stamina per landed
  hit), Warden Cudgel (1.05x, +4% damage reduction) beside the existing
  Thornwood Bow. Each family: a materials-priced recipe, its own physical
  bench (workshop row 5 → 10, every bench with an explicit sample
  silhouette — which surfaced that the bow bench had displayed a pair of
  boots since it shipped, via the sample chain's else branch), a held
  visual plan (3 → 8), and a Field Book equip button + icon (the count
  formatter's hardcoded hood/boots pair had every other button reading
  "EQUIP BOOTS ×N"; buttons now carry their own labels). Also fixed, found
  live: **the departure panel followed players across the whole town** —
  the distance gate held the platform instance (streamed to nil once the
  lodge unloads → gate fails open) and only re-evaluated on server pushes;
  it now works from the platform's cached position and re-evaluates on the
  local render tick. PASS FoundationIntegration reconfirmed on a fresh-save
  boot with all ten benches; census 70 → 75.
- **#207** Handoff refresh through #206 + the terminal Studio-restart
  recipe in STUDIO_MCP_SETUP.md.
- **#206** Milestone 6 wave A: **the seven-profession roster is complete.**
  Alchemist (Sporebright Tonic: radius stamina restore + half-strength
  mend), Beastkeeper (Briar Hound: the active night threat hunts the keeper
  for 7s at a 0.8x slow, gated per-enemy so a queued successor never
  inherits the lure), and Runebinder (Still Rune: 3.5s full hold that
  cancels a telegraph in flight; the held enemy can still be struck). Each
  kit maps onto an existing combat primitive, carries three level-10 paths
  on the established bonus fields, and gets a mastery shrine growing the
  grove's own columns (with matching FOLIAGE_KEEP_OUT entries). All three
  abilities live-verified through the real remotes (tonic measured 51→100
  stamina; hound turned a Hollow Zombie; rune froze a Hollow Crow to 0.35
  studs of drift with attribute lifecycle on schedule). Also in the PR: a
  pre-existing crash that flooded the console for the whole Blackout relay
  stage (TutorialService iterated the snapshot's `deliveredNodes` count as
  a map — snapshot now carries `deliveredNodeMap`), and **the
  FoundationIntegration de-rot: eight stale assertions fixed** (three made
  catalog-derived by the roster growth; five predating it — crafting
  displays, farm/windmill shells and story landmarks vs. the selective
  generator, determinism vs. the day-salted seed, and the interaction
  census 54→70 with a full class-by-class live census recorded beside it).
  **`[Last Light] PASS FoundationIntegration` printed for the first time in
  the project's history**, and again on a clean fresh-save boot of the
  final reviewed code. CodeRabbit's review contributed five real fixes.
- **#205** Session-handoff refresh through #204.
- **#204** The departure platform's ready-check was a circle (`RADIUS`
  magnitude) inscribed in the square WorldService actually builds (`RADIUS*2`
  per side), so a player standing in any of the platform's four corners —
  visibly on the dais — read as not on the platform, and a party-size tap
  there was silently rejected. Fixed by checking each axis against `RADIUS`
  independently, matching the real footprint; strictly more permissive than
  the old check. Reported live by the owner ("touching the number of players
  ... doesn't do anything anymore"). Found while investigating: **the
  connected Studio session at the time predated `LobbyService.luau` entirely**
  (no `readyPlayers` anywhere in its loaded scripts) — Studio had drifted far
  enough behind `main` that a live replay of this specific fix wasn't
  possible in that session. If a future session's Studio testing looks like
  it's exercising a different code path than what's on disk, check for this
  before assuming the bug is real or the fix didn't take.
- **#203** Milestone 5 wave C. **Contract
  weather is visible now:** WeatherProfile.contractWeather maps each
  contract's weather kind to streak count/speed/opacity/color scales
  (storm doubles and darkens the fall, mist thins it to a drift, spores
  hang amber), the client controller renders whatever the snapshot's
  contract says, both call sites pass it. **Module gallery:** new Studio
  script (tests/studio/ModuleGallery.server.luau) — always verifies all 30
  catalog modules carry a visual; set the LastLightBuildModuleGallery
  DataModel attribute to build the whole catalog side-by-side at Z+4000
  for an art walk. **Recovery cache reviewed:** the failure-cache /
  recovery / settlement-exclusion loop already ships and was live-tested;
  no open source work found. M5's remaining gate items are owner-gated:
  reserved-server teleport hangs on the multi-place decision, and the
  1,000-Studio-assembly pass needs a live Studio session.

- **#202** Milestone 5 wave B: expedition
  contracts and risk modifiers. New pure `ExpeditionContracts.luau` (4
  contracts, spec-pinned invariant: risk and reward move TOGETHER — no
  contract pays more while hurting less): Standard Sweep, Quiet Roads
  (×0.75 reward, ×0.8 enemy damage), Storm Salvage (×1.25/×1.2), Deep
  Growth (×1.5/×1.35), each carrying a weather identity. The lobby panel
  grew a contract row beside party size; the chosen id rides the depart
  payload and the server resolves it (junk → standard, never extra risk or
  reward). Reward multiplication lands at the single grant site with
  transaction ids untouched (idempotency preserved); the enemy-damage half
  applies only to players with LastLightInExpedition, so a Deep Growth
  party never hardens the town night for whoever stayed home. Weather
  presentation depth and recovery-cache completion continue in wave C.

- **#201** Milestone 5 wave A: the
  full thirty-module Bramblewake set with repetition control. Catalog grew
  12 → 30 (eighteen new definitions on proven visual recipes, tags balanced
  against RequiredTags); the generator now SELECTS twelve per run — role-
  aware arrival/extraction lookup, constrained middle selection (required
  ids first, tag deficits greedily filled, then shuffle) — instead of
  walking one fixed set; `generate` takes `avoidHashes` (novelty is a
  preference, validity a requirement: cornered callers still get the last
  valid manifest); the boot seed is salted by UTC day so servers vary while
  `LastLightExpeditionSeed` still pins builds exactly; the known-good
  fallback keeps the original twelve in authored order, seed-independent.
  Evidence: new ExpeditionSampling spec (500 seeds in CI, six cases) and
  `lune run scripts/sample_expedition_manifests` — the 10,000-seed gate run
  PASSED: 0 invalid, 0 missing spine, 10,000 distinct layouts.

- **#199** Milestone 4 wave C, closing the
  backup doc's open list that a session can close: **/restoreat <target>
  <copy#>** restores a named copy (1 = oldest kept; the roster's own comment
  asked for a separate command rather than loosening /restore, and got one —
  bounded 1–8, refuses rather than clamps, same pre-restore capture and lock
  rails), and **/export <target>** dumps the raw stored profile as JSON into
  the server log in bounded chunks with a chat summary — the export channel
  is the log because chat truncates. `ProfileBackup.snapshotAt` is exact or
  nil, never a clamp. Remaining open on backups, still owner-gated:
  DataStore behaviour evidence on a published staging place.

- **#198** Milestone 4's decoration system
  and caps, closing wave B. New pure `TownDecorations.luau` (save schema
  16, era-15 fixture): eight authored slots (plaza banners, road garlands,
  planters at gate/archive/inn/workshop) with material costs; cap 2+tier×2,
  topping out below the slot count so a maxed town still chooses its
  corners; placement charges the wallet through the same transaction shape
  construction uses; shared towns merge decorations upward. WorldService
  renders placed slots idempotently and hangs a priced PLACE prompt on
  empty markers; Field Book shows placed/cap. Identity only — no slot
  changes a stat. Build 0.53.0.

- **#197** Milestone 4's deliberate town-visit
  flow. The role model was always enforced (TownPermissions: visitors
  contribute upward, never damage); now players are TOLD which side they
  stand on: `TownNightService.hostInfo` exposes host + role, a visitor's
  first toast reads "YOU ARE A GUEST IN X'S EMBERHOLLOW — HELP IT GROW",
  the snapshot carries `townHost`, and the Field Book RESIDENTS section
  opens with the guest line for visitors. Remaining in wave B: decoration
  system + caps.

- **#196** Milestone 4 storage caps, the
  first half of wave B. Town stores now hold what the tier has earned:
  `TownProgression.storageCapForTier` (80 + tier×60), enforced inside
  `ExpeditionInventory.settle` per material, with overflow COUNTED AND
  REPORTED — the settlement record carries an `overflow` map, the Wayhome
  delivery pallet grows a "STORES FULL · N SURPLUS TURNED AWAY" notice, and
  the spec pins both the cap binding and the uncapped legacy path.
  Remaining in wave B: decoration system + caps, deliberate town-visit
  flow. Then wave C (backup restore-to-copy + export), M5 waves.

- **#195** Milestone 4's resident-life
  deliverable: jobs, injury, bonds, and the crisis framework. New pure
  `ResidentLife.luau` (save schema 15, era-14 migration fixture added):
  each resident holds a job at a real building (Tomas/inn, Pip/town board,
  Ena/workbench); a workplace falling below half integrity in a night
  injures its keeper for two nights (deterministic — no dice); two
  simultaneous injuries (or an injury on a lantern-floor night) is a CARE
  crisis persisted on the profile; players CHECK ON residents — care
  shortens recovery and builds per-profile bonds (NEWCOMER→ACQUAINTED→
  TRUSTED→KINDRED), healthy visits bond once per night; healthy employed
  residents grant dawn boons that touch town systems only (Tomas patches
  the worst-hit building, Pip forewarns the night theme, Ena banks a spark
  reserve) — never player power. Build 0.52.0.

- **#194** Audit wave 4, the last of the
  audit's fix waves. **Solo night pressure:** hollow-crow spark theft now
  scales with defender count (×0.55 solo, ×0.8 duo, full at 3+) — a lone
  player watched the light fall 100 → its 18 floor in under a minute while
  unable to be everywhere; incident failures and direct lantern impacts stay
  unscaled. **Field Book reads like a book:** RichText amber section
  headers with rules, muted secondary detail, human empty states ("Nothing
  learned yet — find a workbench."), archive entries with bold titles and
  muted body text — still one label, presentation only. Remaining from the
  audit: two live-device verifications for the owner (night-enemy
  visibility post-#188/#191 lighting, interaction-prompt card reliability)
  and the deferred taste items already listed under open threads.

- **#193** Audit wave 3, guidance and
  fiction. The lobby no longer leaks the story: the objective card, guide
  line, and objective markers hide until `departed` — "FREE MARA" was
  showing over the departure panel, pointing across the map at a town the
  player hadn't left for. Mara is visibly pinned now: her rig stands on the
  approach side of the deadfall facing arriving players instead of inside
  the authored trunk (a rescue objective starring a floating nameplate),
  and freeing her breaks the trunk apart over ~a second instead of
  deleting it in one frame. Phase countdown reads "DAY · 02:58 LEFT" —
  the bare mm:ss read as three in the morning. The profession button says
  PROFESSION / "ROLE · name" — "KIT" is reserved for the purchasable
  character kits so the free system and the paid one never share a word.

- **#192** Audit wave 2. **Mesh-load
  recovery:** a boot-burst throttle error used to condemn an asset for the
  whole server session — observed live as all eleven Milestone-4 town-ring
  buildings rendering as dark fallback shells. MeshTemplateLoader now
  separates transient from permanent failures and exposes
  `forgetTransientFailures()`; `_placeAuthoredMeshes` keeps the failed
  placements that still wear an authored-replacement fallback and runs three
  recovery rounds (75/180/360s), swapping authored meshes in and hiding the
  shells when a retry lands. **Lobby:** spawn no longer greets players with
  the hearth wall (the 180° yaw contradicted its own comment), wall lamps
  are housed iron fixtures instead of bare neon cubes, and the hearth fire
  is layered wedge flames over coals instead of a flat neon rectangle.

- **#191** Full-game audit performed in
  a live Studio session (owner directive: audit everything, fix in waves).
  Wave 1 ships the three feel fixes: **day sun raised** (ClockTime 6.65 →
  10.2 in both lighting sites — the sun sat at dawn height all day, which is
  why the owner's tablet read daytime as dusk); **the game has sound now** —
  new shared SfxCatalog (pure transition resolver, 7 spec cases) + client
  SfxController pooling engine-bundled rbxasset sounds: swing/tap on the
  input itself, gather/bank/objective/night/encounter/downed/revived on
  snapshot edges, first snapshot seeds silently; **performance-breach log
  spam throttled** to once per metric per two minutes (it was printing
  hundreds of identical WARNs per session, burying real errors). Remaining
  audit waves (lobby visuals, mesh-load recovery for the 11 town-ring
  buildings that silently fall back when boot asset loads throttle, lobby
  objective leak, Mara pose, Field Book layout, solo night drain) are logged
  in the session scratchpad AUDIT.md and land as waves 2–4.

- **(in flight, this branch: `agent/level2-legibility-and-town-signs`, PR
  #189)** The level-2 legibility batch plus the town-sign fixes from the
  owner's third round of tablet screenshots. Level 2: guide lines carry a
  speaker now ("You" in the expedition, "Mara" in town) and the
  blackout/expedition lines are first-person story narration — the owner's
  "him talking to himself telling what's actually going on"; warden nodes and
  relay roots wear heartwood stumps instead of the rootling (enemy)
  silhouette; the near backdrop tree rank is pushed from reach+40 to reach+72
  and thinned (34→20 canopies, 22→14 heroes, crowns raised) — that rank was
  the "so many bushes" hedge; normal-night lighting floor raised the way
  Blackout's was in #188. Town, from the screenshots: notice-board header
  text is single-line on a wider plate (it was TextScaled wrapped mush
  spilling off the planks — "the words go outside the bubbles"); the archive
  header now just says FIELD BOOK; the town board moved from (-24,-150) —
  five studs inside the west Dawn Gate tower's scaffold, which is why its
  TIER 1 plank hung sideways off the stairs — to (-32,-162), and the archive
  board from the same tower's base to (-26,-120); residents and Mara no
  longer show the engine's naked DisplayName stacked over the bubbled plate
  (DisplayDistanceType None, plate range 40); the safe-camp sign hides its
  procedural text on authored replacement like FOLLOW THE LANTERNS; the
  shrine inlay is four thin bands forming a ring instead of one 11×11 neon
  plate that rendered as a blinding yellow square on device.

- **(in flight, this branch: `agent/memory-fragments`; the chapter-one strike
  fix merged as #184 and the town-surface half as #183)** Level-2 playability and visual audit,
  driven live through a connected Studio session. The headline: **chapter
  one had become uncompletable, and is fixed.** The
  `part()` tap-to-interact change (#173) left the Old Growth AmberHeart and
  Warden Stag MemoryHeart non-queryable once the enemy-visual pass hid them,
  and both services' line-of-sight checks required the strike ray to hit the
  heart part first — so every strike on either encounter failed "behind the
  trunk", forever. Nobody had fought either live since the mesh pass. Fixed
  three ways (hearts marked `KeepVisibleOnReplacement`, the enemy-visual hide
  pass now honours that flag, both LOS checks exclude the creature's own body
  and test only world cover), then **proven by playing chapter one end to end
  in-session**: tutorial → night (3 defeats) → entry → relay 3/3 → Old Growth
  (3 phases, 2 fire breaks, +3 sap) → Warden Stag (3 phases, 9 roots, 0
  antlers, preserved) → solo vote → immutable `chapter_1` transaction →
  Wayhome banking; then all 8 events run to completion in one pass (25 steps
  accepted, 8 rewards persisted, second settlement banked exactly the award
  table's 23 materials).

  Also fixed in the same branch: the elite/boss rails no longer leak a
  full-health "PHASE 1/3 · 360/360" for dormant encounters (the Blackout
  relay's farm root sits beside the arena, so every carrier saw it one stage
  early — both runbooks forbid it); the DEPARTURE lobby panel is
  proximity-gated to its platform (it used to follow any player who left the
  yard without departing, through the tutorial, the night, and the whole
  expedition); the objective card holds two wrapped lines ("TAKE ROOTFIRE
  FROM THE BLACKOUT LANTERN" rendered as "TAKE ROOTFIRE FROM THE"); the
  chapter-resolution copy no longer leaks raw snake_case IDs
  ("SHARED_AGROFOREST"); the committed places now set
  `TextChatService.ChatVersion = TextChatService` — it defaulted to Legacy
  in rojo-built places, which left every `/command` the playtest runbooks
  depend on silently dead; and the Studio test's final assertion no longer
  reads the engine-removed `PlayerScriptsUseInputActionSystem` rollout gate
  raw (that error killed the test one statement before its PASS line).
  `[Last Light] PASS FoundationIntegration` was then seen to print with zero
  errors — the first time since #180.

  **Memory fragments — chapter one's story, finally told in the world.**
  The premise had never reached the player: light is memory, the Long Night is
  the remainder of memories a machine took because nobody could carry them,
  and the eighth seal has been in the player's hands since the prologue
  unexplained. Ten fragments now rest on scenery that was already standing —
  the four authored story vignettes and the four POIs — in three acts: what
  the forest kept (the evacuation, each beat landing on a resident standing in
  Emberhollow today), the keeper's trail (what Orin was actually doing), and
  your part in it (why the seal is yours). The last two are gated behind
  chapter one; the final one sits **at the Wayhome Gate**, so a player learns
  what Chapter II is on the walk home from finishing Chapter I. The Field Book
  is now also the Memory Archive: recovered fragments read back in authored
  order, unrecovered ones are named by the place that holds them, so the pull
  is "there is more to know and I know where to look" rather than a checklist
  with the labels torn off. Save schema 14; `MemoryFragments.luau` owns
  catalog, placement anchors, and pure claim logic; 10 new tests.

  Taste calls made rather than deferred:
  - **Daylight foxfire route markers** dimmed properly. `AmbientMotion.lightLevel`
    floors at 0.58, so the existing breathing could never take the 26 neon
    inlays down meaningfully and they read as saturated cyan slabs by day. New
    opt-in `DaylightFade` attribute the ambient controller honours: the road
    leads with its own worn surface by day, foxfire owns the night.
  - **Cleansed Blackout roots** stopped going 48% transparent — a lit root read
    as a flat translucent pane, which made progress look like breakage. They
    now stay solid and turn living green (LeafyGrass), so cleansing reads as
    regrowth taking the light back.

  Still flagged for the owner, needing eyes rather than a decision:
  - **Bramblewake reads very dark at dawn/day mid-route** in the test place;
    the test place does not set `Lighting.Technology = Future` (the game
    place does), so judge lighting there before tuning anything.
  - **A solo Blackout leaves the town lantern undefended** through however
    many normal nights elapse — it hit the 18-health floor during this run,
    which means three damaged buildings at dawn. Design tension, not a bug;
    the owner's call among pause-the-cycle, exempt-when-empty, or keep.
  - The market-stall canopies (restyled from fairground red to deep moss
    Fabric) read near-black in shade, and the notice-board mesh is placed
    roughly half-buried (its visible height is right, the method is odd).

  The same branch adds the owner-requested **arrival vignettes**: a short,
  local, skippable letterboxed camera push with an original title card when
  the night arrives ("NIGHT 3 · ROOTMOON" from the authored theme names), the
  Blackout begins, or Old Growth / the Warden Stag awaken. Camera-only and
  per-player (the server never waits), any input skips instantly, never plays
  while downed / in compact HUD / on a reconnect into an already-active
  state. Decision recorded in DECISIONS.md; live-verified in Studio (play,
  letterbox, restore, and the downed guard all observed working).

  The first fruits of the same audit, from before the live playthrough:
  - **The town's main street was invisible.** Its top face (0.33) was exactly
    coplanar with the courtyard's, z-fighting where they overlapped, its
    18-stud foundation was fully buried (top −0.02), and its worn center
    line disappeared under the 0.80-tall plaza pad. Every player and NPC also
    sank shin-deep in that pad, because it is a non-colliding skin and
    characters walk on the terrain through it. The whole town surface stack
    was re-layered as thin skins over the walk plane (street 0.56, wear 0.64,
    foundation 0.44, square pad 0.38), documented in `WorldService.luau` at
    the street builder. Cabin entry paths (floating 0.4), three tutorial spur
    paths (floating 0.35), the square edge stones, district-road foundations
    (buried), and the arrival road's foundations (buried) were re-seated in
    the same pass; the First Lantern mesh — whose authored plinth was
    swallowed by the old pad, reading almost a stud shorter — now stands its
    full height.
  - **Two stale Studio-test assertions** fixed: the arrival-road height check
    still asserted the pre-#180 `Y >= 2` compensation (now measured against
    `TerrainBuilder.valleyFloorTop()`), and the interaction census expected
    81 prompts against the world's real 90 — the per-module resource nodes
    reached their full two-per-module count (22) after that line last ran.
  - **New `restyleParts` registry mechanism** (same declarative pattern as
    `stripDecals`): recolors/re-materials matching source parts at template
    load. First use: the two 23-stud Creator Store market stalls whose
    fairground-red plastic canopies flanked the town gate now wear moss-green
    canvas and rain-dark timber.
- **#181** Full audit of the night-defense combat system: every combat source
  file read end to end, then live-tested by firing the real gameplay remotes
  (spawn, strike, profession, incident) through a connected Studio session,
  including driving the real `TownNightService` day/dusk/night cycle through
  five consecutive real nights. Two bugs found:
  - **Enemies floating or sinking relative to the ground.**
    `enemySpawnPosition()` held a stale hardcoded `Vector3.new(0, 2, -153)`
    left over from before the #180 datum fix below, so every enemy in every
    night defense fought ~2 studs above the ground for its whole encounter.
    Separately and independently — proved algebraically: the sink is
    `lift - groundOffset`, and the spawn origin's Y has always equaled the
    rendered terrain height on both sides of the datum fix, so the gap
    between them was never affected by it — four of six enemy species'
    authored visual meshes were sinking ~2 studs *into* the ground.
    `groundOffset` in `placeEnemyVisual` was each species' fallback-core
    Y-lift plus 2.0 more, too consistent across four unrelated species to be
    separate tuning mistakes. Both fixed; verified live that all six species
    now land within ~0.1 studs of true ground.
  - **Silent lantern damage from the hollow crow.** Its `spark_theft` status
    effect — the most frequent source of lantern-health pressure in a night,
    firing on every unblocked hit — mutated `_lanternHealth` with no log
    line, unlike every other lantern-pressure path (incident failure, a
    direct lantern impact, a Last Stand spend). Traced live: watched the
    lantern crash from 100 to its floor of 18 with nothing in the server log
    to explain it. Added the same `lantern_pressure_applied` event the other
    paths already emit; no behavior change, confirmed by the same trace.
  - Also live-verified with no changes needed: Town Guard Last Stand's four
    branches (successful recovery, lantern-too-weak falling back to the
    standard bleedout timer, already-spent-this-night rejection, and the
    once-per-night reset), the Drowsy and Spark Theft status effects, and the
    Warden/Engineer profession combat hooks.
- **#180** The world's vertical datum fix, both levels' glass removal, the
  town square move, and the Bramblewake part-budget re-derivation — see
  "Known open threads" below for the mechanics of each; they stay there
  because they are still worth checking against, not because they are
  unresolved. Two more fixes from the same PR that belong here instead,
  because they are fully closed:
  - **Three of eight Bramblewake events had never existed.** A module can
    carry both a point of interest and an event, and the builder placed them
    on `if`/`elseif` — the POI always won and the event was silently
    dropped. `ExpeditionService` logged `events=8` from the manifest while
    the world held 5. Split into separate `if` blocks; verified 8 sockets,
    25 steps.
  - **One transient asset-fetch failure condemned an asset for the whole
    server session**, silently dropping every instance of it rather than
    just the one placement. `MeshTemplateLoader` now retries a failed
    `LoadAsset`/`LoadAssetAsync` up to three times with backoff before
    condemning it — this is what finally produced a clean boot
    (`fallbacks=0` across all three asset groups).
- **#179** The first visual sweep done through a connected Studio session, and
  the first time the committed Studio integration test has ever been watched
  all the way through. Five things a player could see were wrong, and none of
  them were visible from source alone:
  - **All eight illustrated first-world notices were invisible.** Both the
    Greenward Archive board and the Town Board are mesh-replacement fallbacks,
    so `hideProceduralPlaceholder` blanked every notice paper to
    `Transparency = 1` and switched off every artwork `SurfaceGui` the moment
    the authored Creator Store board loaded — and that board is bare wood. A
    player walked up to two blank planks. This is the fourth time this exact
    failure has shipped (First Lantern flame, dawn beacon flame, the three tool
    displays), so the fix is declarative rather than another hoist: a part
    marked `KeepVisibleOnReplacement` and everything under it is skipped by the
    blanking pass. Set on the notice papers, pins, wax seals, and header plate.
  - **A glass slab was tinting the whole starting town.** `LowMorningMist` was
    a 190 x 250 stud `Enum.Material.Glass` part floating at y = 2.3 over the
    entire first playable area. Glass renders a refractive pane whatever
    `Transparency` says, so it washed every road stone, building, and patch of
    grass a flat cyan-green and ended in a hard rectangular seam at
    x = ±95 / z = -211. Nothing ever toggled it either, so a "morning" mist sat
    over the town at dusk and through the night. Removed; `LastLightAtmosphere`
    already does aerial perspective properly and is eased per phase.
  - **The town leaked authored meshes on every rebuild.** `_rebuildTownProgression`
    destroyed `GreenwardConsequence` and `TownProgressionBuildings` but not the
    authored placements the previous pass had parented straight to the world,
    so duplicates stacked at identical coordinates. Not rare: a profile load
    rebuilds twice back to back, and every construction contribution rebuilds
    again. Measured 17 stray models against 16 real placements before the fix,
    0 after. They now live in a `TownAuthoredMeshes` container that one
    `Destroy` clears.
  - **"DO NOT ENTER — THIS RESTRICTED CLEARANCE AREA"** in modern yellow-and-black
    hazard type, on the two barricades flanking the tutorial's opening path,
    at the exact moment the objective card says to follow the lantern path.
    Baked-in decals on the Creator Store barricade model. New registry flag
    `stripDecals` (honoured in `MeshTemplateLoader.sanitize`) drops `Decal` and
    `Texture` off that asset; the geometry is kept.
  - **Two HUD panels bypassed `SafeCanvas`.** `LobbyPanel` and `ActionProgress`
    were parented to the `ScreenGui` rather than the canvas, so they were the
    only bottom-anchored controls that never received the `UIScale` the canvas
    carries — exactly the class of mobile layout bug that comment was written
    about. Reparented.

  The Studio test itself had never printed
  `[Last Light] PASS FoundationIntegration` — it aborted at the notice check,
  and everything past that line had gone unexercised long enough to rot. See
  the runbook note below.
- **#178** Setup for connecting an AI session directly to Roblox Studio through
  Studio's own built-in MCP server, including a Wine wrapper for Linux hosts
  running Studio under Vinegar. **This is the thing that moved the project's
  binding constraint** — the visual and DataModel half of every runbook gate
  can now be closed by a session that can see Studio, while the device and
  human half cannot. Read [STUDIO_MCP_SETUP.md](STUDIO_MCP_SETUP.md) before
  claiming a gate closed; it draws that line explicitly. The runbooks'
  journeys are renamed from "Windows Studio journey" to "Studio journey" — the
  owner develops on Linux, and the operating system was never what those steps
  depended on. **Proven out since, not just wired up:** #179, #180, and #181
  above were each done through a live connected session — spawning real
  enemies, firing the actual gameplay remotes instead of mocking them, driving
  several real day/dusk/night cycles end to end, and reading Studio's own
  console output — not just DataModel inspection. See "Session gotchas" below
  for what that surfaced about testing this way.
- **#177** Two construction-site fixes to #176, found by
  CodeRabbit review after it merged. Both were reachable on ordinary paths:
  an explicitly empty damageable roster fell back to "every building", so a
  tier-zero town — which is entirely construction sites — would have had all
  sixteen buildings damaged on a new save's first night; and a migrated
  schema-12 profile could raise a REPAIR prompt on a construction lot, because
  the renderer checked that a building had a recorded placement but not that it
  was actually standing.
- **#176** Per-building town damage and repair. Storm
  damage stopped being one town-wide integrity number and became a property of
  each building, chosen by night number, repaired one building at a time
  through a prompt that carries its building's ID as a baked payload. Schema
  13; a schema-12 town-wide integrity spreads to every building on migration.
  Caught a live regression on the way: `TownPermissions.resolveCondition` read
  a `value.integrity` field that stopped existing, which would have silently
  turned the visitor guard off — it now takes the integrity reader as an
  injected dependency and requires it. Details and the Studio gate in
  [MILESTONE_4_PER_BUILDING_DAMAGE.md](MILESTONE_4_PER_BUILDING_DAMAGE.md).
- **#175** Profile backups and an audited restore —
  the last unimplemented piece of M4's persistence deliverable, plus the write
  half of its admin-tooling deliverable. Snapshots go to a separate
  `LastLightProfileBackup_v1` store; the load path photographs the raw stored
  bytes *before* `normalize` migrates them, which is the case
  TECHNICAL_ARCHITECTURE asks for a backup before. `/backups` lists, `/restore`
  rolls back to the newest copy, refuses while a live server holds the profile,
  and copies the replaced profile first so running it twice undoes it. Details
  and the DataStore exit gate in
  [MILESTONE_4_PROFILE_BACKUPS.md](MILESTONE_4_PROFILE_BACKUPS.md).
- **#174** Refreshed this handoff and stopped eight runbooks hard-coding build,
  schema, and service-count literals that had gone thirty-plus PRs stale; they
  now defer to `Config.luau`. `validate-plan.mjs` checks this file's own
  `Last updated` line against source, so a version bump that forgets it fails
  `npm test`.

- **#172** Fixed the committed Studio test's stale version assertions (it
  still asserted build `0.46.1`/schema `11` after the bump to `0.47.0`/`12`,
  so it failed its first line whenever a tester pressed Play); added a
  drift guard to `scripts/verify-build.luau` so `npm test` catches the next
  forgotten bump instead of the owner's Studio session.
- **#173** First owner-playtest fix pass on the tutorial-night first-town
  slice — five reports, four fixed in source with file:line evidence, one
  investigated and explicitly not acted on:
  - **Dawn beacon missing / dark panel on the road** — fixed. The "wall/sign"
    the owner saw was the memory-reliquary mesh itself, half-buried by two
    already-documented failure modes stacking: its flame lived inside
    `beaconFallback`, so `hideProceduralPlaceholder` blanked it dark the
    moment the reviewed mesh loaded (same class of bug as the First Lantern
    fix, see DECISIONS.md); and its authored position sat at the pre-lift
    road height, so the raised cobblestone visual skin buried its lower ~2
    studs. Hoisted a `BeaconCore` neon part out of the fallback (mirrors
    `FirstLanternCore`) and reseated the reliquary, `DawnPathMarker`s,
    `DawnGateStep`s, and the reveal pulse above the road surface. Also fixed
    a pre-existing dead assertion in `FoundationIntegration.server.luau`
    that checked a Creator-Store-prefixed key
    (`mesh_creator_memory_reliquary_a`) nothing ever placed under — the real
    ID has no `creator_` prefix since the reliquary is a generated original
    asset — so it always read 0 and always failed.
  - **Arch between the First Lantern and the beacon** — removed outright, in
    the same edit as the beacon fix (both lived in the same construction
    block). `mesh_creator_wood_arch_a` stays registered in
    `MeshAssetRegistry` (unplaced, same status as other reviewed-but-retired
    assets) but is no longer placed anywhere.
  - **Mobile combat callout clutter** — fixed, one line.
    `EnemyService._stepAttack` was re-writing the world-space attack label
    with the full `"name\ninstruction · Ns"` two-line caption every tick of
    the windup, duplicating the HUD threat banner exactly (a prior commit,
    2856375, only fixed the label's *initial* text, not this per-tick
    overwrite). Now writes `"name · Ns"` only; the instruction lives in the
    HUD banner, matching the documented one-alert contract.
  - **Crow enemy vanishes/respawns and is nearly untappable** — fixed. Not
    designed motion: `placeEnemyVisual` computed the authored mesh's
    placement `CFrame` from the enemy core's position *before* the
    asset-load yield, so a fast mover (the crow, speed 9, fastest in the
    roster) kept flying during the load and the visible mesh landed at a
    stale, permanently-offset position from the actual (invisible)
    authoritative hitbox — reading as vanish-then-respawn, and making taps
    miss. Now re-pivots from the core's current frame right after the load
    resolves. Also: fallback parts other than the hitbox core now get
    `CanQuery = false` (they were silently swallowing taps with no
    detector attached), and the `StrikeClick` `ClickDetector` moved from the
    core part to the enemy model itself, so a tap anywhere on the model's
    visible geometry can register.
  - **Near-black morning shadows at the first-level start** — fixed. Raised
    `DAY_AMBIENT`, day-phase `OutdoorAmbient`, and
    `EnvironmentDiffuseScale`; reduced (less negative) day
    `ExposureCompensation`; lowered day `ColorCorrectionEffect.Contrast`;
    raised `ShadowSoftness`. Changed in both places these values are
    duplicated (`_configureLighting` and `_applyTownLighting`'s day branch —
    the file's own comments warn a one-sided edit silently reverts on the
    first day/dusk transition). Night's separate, much lower floor is
    untouched.
  - **"Move the First Lantern back to the town square center"** — investigated,
    not acted on. Source already places `FirstLanternCore` at `(0, 6.3,
    -112)`, exactly the plaza center (`PLAZA = Vector3.new(0, 0, -112)`,
    `PLAZA_HALF = 36`) that `scripts/validate_town_layout.py`'s own
    docstring calls a "long-established fixed landmark." No evidence in
    source explains the report; flagged back to the owner rather than
    guessed at. Possible explanations worth checking next: a stale
    published place versus this source revision, or the report referring to
    something else entirely.
- **#170** Construction orders now cost resources; existing towns grandfathered.
- **#169** M4 unlock plus town layout: town buildings generated, prepared,
  uploaded, and placed (PR titles said eleven of sixteen staged;
  `validate_town_layout.py` passes for fourteen as of this update -- trust the
  validator's current count over any number written here); a safe lock-clear
  command; building footprint clearance guarded from source.
- **#168** Read-only admin save inspection with audit logging.
- **#167** Bramblewake fall-through floor fixed, entry quieted, tools lit.
- **#165/#166** Persistence: session locking on the autosave beat with tests
  for the five failure modes (forced crash, contention, write failure, stale
  revision, shutdown), visitor-cannot-modify-host-town enforcement.
- **#162–#164** Exploit-gate test suites reconciled and a performance budget
  harness (client frame/memory telemetry against a baseline-phone ceiling).
- **#154–#161** Visual/creature pass: borrowed third-party creature models
  retired in favour of meshes *generated around the parts each fight is read
  from* — see the rule and its reasoning at the tail of
  [DECISIONS.md](DECISIONS.md) (stag antler stubs, elite chest cavity, facing
  measured via Blender −Y → Roblox +Z). Plus level-2 story landmarks, enemy
  art, POI voice, memory reliquary, Bramblewake legibility fixes, and admin
  TextChat fix.

Earlier context (PRs #95–#115, the first visual-correction wave: buried roads,
sign facing, lantern light, cylinder axis, source-yaw cancellation, lantern
safe-zone regen) is recorded in
[ASSET_COVERAGE_AUDIT.md](ASSET_COVERAGE_AUDIT.md) and the PR history.

## Blocked on the owner

None of these can be completed from a session.

1. **Studio and device playtest evidence** — the M3 exit gates, the M4 gate's
   live pathfinding pass, and visual confirmation of the placement-correction
   wave. **Unblocked for the Studio half, and now demonstrated rather than just
   wired up:** a session running on the machine that runs Studio can close the
   Studio half through the MCP server — see
   [STUDIO_MCP_SETUP.md](STUDIO_MCP_SETUP.md). #179, #180, and #181 each did
   this for real, across two separate sessions. It cannot run on a cloud
   session, because MCP over stdio has no address to dial. What remains
   strictly human: the baseline-phone pass, the ten-tester gate, DataStore
   behaviour across servers, real multiplayer, and whether the slice is fun.
2. **`ROBLOX_API_KEY` per session** — containers lose it on reset. It is
   needed only for asset upload/download (`scripts/upload_mesh_assets.py`,
   `scripts/download_creator_store_model.py`), never committed or logged.
3. **Codex review credits are exhausted.** Codex caught two real shipped bugs
   during the visual wave (beds below the floor; lantern regen cancelling
   revives). CodeRabbit still reviews, but expect nothing from Codex until
   credits are topped up.

## Known open threads

- **The world's vertical datum was wrong by two studs, and is now fixed --
  re-read anything that reasons about height.** Roblox renders a terrain
  surface half a voxel (2 studs) above the top face of the fill that made it.
  `TerrainBuilder` reported the valley floor at `GROUND_Y = 0` while the engine
  put it at 2, so every authored `Vector3` written against y = 0 was two studs
  underground. Consequences that had been live for a long time: the town square
  (top face 0.80) was **buried and had never once rendered** at either 72 or
  112 studs across, and Mara and all three residents stood shin-deep with their
  legs swallowed. The road network looked correct only because it had been
  nudged to 2.2-2.5 one layer at a time -- `WorldService` still carried a
  comment diagnosing this as a road problem and adding a "+1.77 visual skin".

  Fixed at the source: fills are now placed at `FILL_Y = GROUND_Y -
  VOXEL_SURFACE_RISE`, so the rendered surface lands on the authored plane
  (measured 0.02 across the valley, was 2.00). Every compensation was then
  removed -- arrival road stack, town main street, district roads, road edge
  stones, cobblestone layer, `ROAD_SURFACE_Y` 2.45 -> 0.53. **If you find
  height arithmetic anywhere that looks like it is dodging the ground, it is
  probably another one of these; check it against the datum rather than nudging
  it.**
- **Bramblewake was being viewed through glass.** Thirteen `BlueGroundMist`
  Glass slabs, one per module plus the Blackout arena, covering about 1.8
  million square studs at knee height. Glass renders a refractive pane whatever
  Transparency says, so the whole expedition came out flat blue-grey and from
  any raised angle the slab edges read as the edge of a void. Removed, same as
  `LowMorningMist` over Emberhollow. Both regions already have tuned
  `Atmosphere` doing this properly.


- **The town square moved and grew; three things now stand on it.** `TOWN_CENTER`
  is (0, 0, -80) and `PLAZA_HALF` is 56, so the square spans z -24..-136 and
  reaches Mara's clearing. Mara and the starter tool yard were authored to stand
  on grass at y 0 and are now lifted onto the pad by `PLAZA_SURFACE_Y`; the
  Heartwood gather node and the First Lantern's own plinth still embed ~0.8
  studs in the paving, which reads as set-in rather than sunk but has not been
  owner-reviewed. If the Heartwood stump on a paved plaza looks wrong, reseat it.
- **`RouteGuideMarker` is a taste call nobody has made.** 26 Neon foxfire
  waypoint inlays run the length of the critical route. Their rationale is
  documented and deliberate -- they are the only thing that says "this way" in
  the dark -- but in daylight they read as saturated cyan rectangles lying on
  the paving. Left untouched. Decide whether daylight should dim them.


- **Bramblewake's part budget was never breached; the test was measuring the
  wrong thing.** Recorded here previously as "3.3x over budget" -- that was
  wrong, and the correction matters because it nearly cost the generator its
  one working constraint. `PartBudget` (640) bounds the *manifest*: the sum of
  the chosen modules' planning allowances, checked by
  `ExpeditionGenerator.validate`. The preview seed totals **427** against it and
  always has. `GeneratedPartCount` (**2330**) counts *built* BaseParts, which is
  a different quantity entirely -- a module with a planning allowance of 44
  legitimately builds several hundred real parts. The Studio test compared the
  two, and summed in the boss-arena and Blackout allowances on top, though both
  are built after that count is taken. Split into `PartBudget` (unchanged) and
  a new `BuiltPartBudget` (2600 = measured 2330 + ~12%), derivation recorded in
  `BramblewakeExpedition.luau`. **Still owed:** `BuiltPartBudget` is a
  regression guard, not evidence 2330 parts is affordable on a phone. The
  Milestone 3 device capture has still never been taken.
- **Two selected Creator Store assets were never actually adopted.**
  `mesh_creator_hollow_rootling_a` and `mesh_creator_predatory_flower_a` are
  listed in `assets/meshes/candidates/creator-store-full-pass/selection.json`
  and `scripts/generate_mesh_kit.py`, but neither was ever promoted into
  `MeshAssetRegistry` and nothing places them. The Studio test asserted four of
  the first and two of the second, so those assertions could not have passed in
  any build ever made; they have been removed rather than left as permanent
  red. **The content gap is real and still open:** the Warden and Blackout
  living-root objects and the Old Growth root hearts have no sourced art. Decide
  whether to adopt these two candidates or retire them explicitly, the same
  question `mesh_creator_first_lantern_a` is waiting on below.
- `mesh_creator_first_lantern_a` is in the manifest but genuinely undecided —
  retire it explicitly or place it. Details in
  [ASSET_COVERAGE_AUDIT.md](ASSET_COVERAGE_AUDIT.md) §Intentionally unplaced.
- **Checked (2026-08-04) against source, not just commit history:** resident
  jobs/injury/relationships/crisis framework and storage/decoration caps are
  **absent**. Residents exist only as ambient NPCs
  with day/dusk/night positions and duty labels (`WorldService.luau`
  ~8207-8250); no storage or decoration system exists to cap. Multiple
  grep patterns tried per item, all zero-hit — see the roadmap gate for what
  "done" means here. Also weaker than the deliverable wording implies: "town
  visit flow" is only implicit first-arrival hosting on a shared server (no
  deliberate visit/teleport mechanic); damage/repair is one town-wide
  integrity value (`TownCondition.luau`), not per-building — **addressed by #176
  above**; eleven of the
  sixteen buildings are staged shells with construction prompts, not yet
  functionally distinct.

## Getting caught up, in order

1. This file.
2. [README.md](../README.md) — vision and the long-form current-status recap.
3. [AGENTS.md](../AGENTS.md) — operating rules, delivery workflow, gates.
4. [PRODUCTION_ROADMAP.md](PRODUCTION_ROADMAP.md) — Milestone 4 gate.
5. Tail of [DECISIONS.md](DECISIONS.md) — the newest recorded decisions.
6. Before any visual work: [VISUAL_QUALITY_STANDARD.md](VISUAL_QUALITY_STANDARD.md)
   (includes how to pick, thumbnail-check, and place assets) and
   [ASSET_COVERAGE_AUDIT.md](ASSET_COVERAGE_AUDIT.md).
7. [DEVELOPMENT.md](DEVELOPMENT.md) — toolchain and daily commands.

## Session gotchas that live nowhere else

Hard-won, each one cost a real session real time:

- **Remote containers: the toolchain can be installed, and the old note here
  was wrong about why it could not.** Rokit's installer resolves releases
  through `api.github.com`, which the egress policy denies (403) — but
  `github.com/<org>/<repo>/releases/download/...` is allowed, so the five
  pinned tools can be fetched directly and dropped on `PATH`:

  ```bash
  # rojo 7.7.0, lune 0.10.5, stylua 2.5.2, selene 0.31.0, luau-lsp 1.69.0
  curl -sSL -o t.zip https://github.com/rojo-rbx/rojo/releases/download/v7.7.0/rojo-7.7.0-linux-x86_64.zip
  unzip -o t.zip -d ~/.lltools/bin   # repeat per tool, then chmod +x
  ```

  That gets six of `npm test`'s seven steps running locally, **including
  `npm run build`** — so place artifacts can be regenerated and committed from
  a container after all. Only `selene` still cannot run, and not for a network
  reason: it fetches the Roblox API dump with a bundled root store and rejects
  the proxy CA (`invalid peer certificate: UnknownIssuer`). `curl` reaches the
  same URL fine and the CA *is* in the system store; `SSL_CERT_FILE`,
  `SSL_CERT_DIR`, `CARGO_HTTP_CAINFO`, and `REQUESTS_CA_BUNDLE` are all ignored
  by it. Let CI cover lint; run everything else locally.
- **`.rbxm` is globally gitignored** while reviewed Creator Store candidates
  are deliberately committed — new candidate downloads need `git add -f`.
- **`scripts/validate_mesh_assets.py` reads a fixed 520-character window**
  after each registry `id` marker. A comment inside a registry entry body
  pushes later fields out of the window and fails validation with a
  misleading "differs from manifest" error. Keep rationale in commits, not in
  entry bodies.
- **Place files are build artifacts.** After any `src/` change:
  `npm run build`, then commit both `build/LastLight.rbxlx` and
  `build/LastLightTest.rbxlx` from that exact revision.
- **Creator Store models are routinely saved rotated off-axis.** Run
  `lune run scripts/measure_source_yaw <model.rbxm>` before placing a new
  source model, and record a non-zero modal yaw as `sourceYawDegrees` in
  `MeshAssetRegistry` — otherwise the asset places turned *and* undersized,
  silently.
- **Version literals live in `Config.luau`, not in runbooks.** The playtest
  runbooks used to hard-code the build, schema, and service count a tester
  should see in Studio Output; they drifted, and a tester following one would
  have failed the first line of their evidence run against a build that had not
  existed for thirty-plus PRs. They now defer to `src/shared/Config.luau` and
  `src/server/init.server.luau`. The `Last updated` line in *this* file is the
  one place those numbers are still written out, and `scripts/validate-plan.mjs`
  checks it against source — so a version bump that forgets this file fails
  `npm test`. Keep the line's shape (build `X`, save schema `N`, `N` services).
- **A passing guard is not evidence until it has been made to fail.** Inject
  the regression, watch the test fail, restore. Several checks in this
  project's history read correctly and verified nothing.
- **An unreachable assertion rots silently, and this file's own runbooks were
  built on one.** `FoundationIntegration` aborted at its Town Board notice
  check on every run, because that check counts a board that only exists after
  a profile load and the script runs at server boot. Everything after that line
  — roughly two thirds of the test — had therefore never executed, and five
  separate assertions had drifted out of agreement with the game while still
  reading as if they passed: a tool-yard roof part renamed to a rafter frame
  thirty commits earlier, a corner-post count that demanded completed buildings
  a tier-zero save cannot have, a town asset census that silently started
  counting Bramblewake once the expedition was dressed from the same library,
  two assertions naming assets that were never registered, and a
  fallback-visibility rule that directly contradicted the notice check beside
  it. Ten milestone runbooks ask for `[Last Light] PASS FoundationIntegration`
  as gate evidence; none of them could ever have got it. **When a gate line has
  never been seen to print, treat every assertion behind it as unverified.**
