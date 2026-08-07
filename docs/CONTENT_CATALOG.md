# Launch content catalog

## Purpose and ID rules

This is the committed launch inventory. It prevents “complete” from becoming an
undefined moving target.

- IDs are lowercase snake case and unique across their content type.
- A shipped ID is never reused for a different meaning.
- Deleted content leaves a migration alias or tombstone.
- Content definitions declare region, tier, tags, dependencies, localization
  keys, analytics key, asset bundle, and feature flag.
- Counts below are launch gates. Cosmetic variants do not substitute for missing
  functional content.

## Regions and chapters

| ID | Region | Chapter | Modules | POIs | Events |
|---|---|---:|---:|---:|---:|
| region_bramblewake | Bramblewake Woods | 1 | 30 | 12 | 8 |
| region_ironroot | Ironroot Delve | 2 | 30 | 12 | 8 |
| region_mireglass | Mireglass Fen | 3 | 30 | 12 | 8 |
| region_tempest | Tempest Reach | 4 | 30 | 12 | 8 |
| region_frostmere | Frostmere Vale | 5 | 30 | 12 | 8 |
| region_cinderfall | Cinderfall Crown | 6 | 30 | 12 | 8 |
| region_hollow | The Hollow Below | 7 | authored finale | 7 | authored |

The launch inventory therefore contains 180 reusable surface modules, 79 POIs
(72 surface POIs plus 7 authored finale POIs), and 48 surface event templates.
The Hollow Below is an authored finale rather than a procedural surface region,
so its scenes and encounters are validated as a fixed sequence instead of being
miscounted as surface modules or event templates.

Each surface-region module set includes:

- 6 safe connectors;
- 6 traversal modules;
- 5 resource modules;
- 4 combat arenas;
- 3 rescue or story modules;
- 3 puzzle modules;
- 2 extraction variants;
- 1 landmark approach.

Modules can serve multiple tags but the final generated path must satisfy the
required distribution. Visual transforms do not count as unique modules unless
geometry and gameplay affordances differ.

## Standard enemies

### Bramblewake

| ID | Name | Combat purpose |
|---|---|---|
| enemy_rootling | Rootling | basic melee pressure with clear lunge |
| enemy_briarback | Briarback | shielded front encourages flanking |
| enemy_zombie | Hollow Zombie | rot miasma and visibility pressure |
| enemy_hollow_crow | Hollow Crow | steals loose unbanked resource bundles |
| enemy_snapvine | Snapvine | stationary route denial, cut or distract |
| enemy_bark_ram | Bark Ram | telegraphed structure charge |

Build `0.10.0` implements all six stable Bramblewake IDs in the authored
first-night sequence. Hollow Crow currently steals temporary First Lantern light
instead of durable inventory; physical loose-bundle theft remains a later
expedition encounter integration.

### Ironroot

| ID | Name | Combat purpose |
|---|---|---|
| enemy_cinder_mite | Cinder Mite | swarm pressure near heat |
| enemy_rail_hound | Rail Hound | uses tracks for fast lane attacks |
| enemy_slag_spitter | Slag Spitter | persistent hot zones |
| enemy_shift_echo | Shift Echo | repeats a worker action as attack |
| enemy_crank_guard | Crank Guard | slow armor with exposed mechanism |
| enemy_gas_bloomer | Gas Bloomer | hazard source that can be redirected |

### Mireglass

| ID | Name | Combat purpose |
|---|---|---|
| enemy_reed_lurker | Reed Lurker | ambush silhouette in shallow water |
| enemy_mirrorling | Mirrorling | copies last basic attack with delay |
| enemy_mire_leech | Mire Leech | stamina drain, removable by ally |
| enemy_false_friend | False Friend | mimics resident call, visual tells |
| enemy_glass_heron | Glass Heron | precise ranged line attack |
| enemy_bog_bell | Bog Bell | summons until interrupted |

### Tempest

| ID | Name | Combat purpose |
|---|---|---|
| enemy_gale_imp | Gale Imp | lateral wind projectile |
| enemy_wreck_crawler | Wreck Crawler | climbs defenses and rigging |
| enemy_storm_ray | Storm Ray | aerial charge passed through grounding |
| enemy_salt_husk | Salt Husk | reforms near water unless dried |
| enemy_rigging_snare | Rigging Snare | pulls player toward hazard |
| enemy_breaker | Breaker | wave-shaped structure pressure |

### Frostmere

| ID | Name | Combat purpose |
|---|---|---|
| enemy_hush_pup | Hush Pup | tracks noise and isolated players |
| enemy_rime_shell | Rime Shell | armor melts inside warmth |
| enemy_bell_moth | Bell Moth | creates misleading sound cues |
| enemy_snowbound | Snowbound | buried grab with visible trail |
| enemy_cold_echo | Cold Echo | freezes recently used ability briefly |
| enemy_ice_borer | Ice Borer | undermines floors and walls |

### Cinderfall

| ID | Name | Combat purpose |
|---|---|---|
| enemy_ash_extra | Ash Extra | common actor repeating ceremonial attack |
| enemy_glass_knight | Glass Knight | reflects frontal projectiles |
| enemy_kiln_worm | Kiln Worm | tunnels between heat sources |
| enemy_crown_spark | Crown Spark | empowers nearby constructs |
| enemy_parade_giant | Parade Giant | slow crowd divider |
| enemy_false_citizen | False Citizen | repairs enemy props until revealed |

### The Hollow Below

| ID | Name | Combat purpose |
|---|---|---|
| enemy_name_eater | Name Eater | temporarily obscures labels, never controls |
| enemy_seal_shade | Seal Shade | adopts one regional hazard |
| enemy_regret_loop | Regret Loop | repeats an avoidable past hit pattern |
| enemy_lantern_inverse | Lantern Inverse | creates dark safety and light danger |
| enemy_keeper_fragment | Keeper Fragment | puzzle-combat memory projection |
| enemy_hollow_hand | Hollow Hand | separates party with moving barriers |

## Elites

| ID | Name | Region | Signature |
|---|---|---|---|
| elite_old_growth | Old Growth | Bramblewake | roots entire lane, movable fire response |
| elite_harvest_mare | Harvest Mare | Bramblewake | carries Rootlings and breaks formations |
| elite_foreman_echo | Foreman Echo | Ironroot | commands machinery and marks unsafe zones |
| elite_iron_widow | Iron Widow | Ironroot | rail-web network and cart ambush |
| elite_many_face | The Many-Face | Mireglass | cycles visible copied profession |
| elite_drowned_caller | Drowned Caller | Mireglass | summons through reflected pools |
| elite_lighthouse_eater | Lighthouse Eater | Tempest | extinguishes beams and hides in storm wall |
| elite_admiral_wreck | Admiral Wreck | Tempest | commands moving ship-debris cover |
| elite_abbey_silence | Abbey Silence | Frostmere | suppresses sound cues, preserves visual cues |
| elite_aurora_hart | Aurora Hart | Frostmere | splits warmth zones with light antlers |
| elite_lead_actor | Lead Actor | Cinderfall | forces readable stage-pattern sequence |
| elite_glass_bailiff | Glass Bailiff | Cinderfall | marks and sentences one structure |
| elite_unspoken | The Unspoken | Hollow | disables one HUD label with icon fallback |
| elite_last_regret | Last Regret | Hollow | remixes one prior boss mechanic at lower scope |

Build `0.11.0` implements `elite_old_growth` in its authored expedition arena.
The encounter has 360 health, shield gates at 240 and 120, a 15-second shared
lantern-fire carry, readable lane and circle attacks, and three Amber Sap per
participant as an unbanked idempotent reward. It remains solo-passable without a
profession or premium item. The other 13 elite IDs remain catalog targets.

## Chapter bosses

| ID | Boss | Required phases | Non-profession solution |
|---|---|---:|---|
| boss_warden_stag | Warden Stag | 3 | cleanse root nodes, then expose heart |
| boss_bellows_maw | Bellows Maw | 3 | reroute carts, vent pressure, strike core |
| boss_lantern_witch | Lantern Witch | 4 | identify tells, use copies, consent seal |
| boss_tidebound_titan | Tidebound Titan | 3 | climb wrecks, ground lightning, lower tide |
| boss_white_howler | White Howler | 3 | manage noise, share warmth, track aurora |
| boss_ash_regent | Ash Regent | 4 | expose authentic memories, break false statues |
| boss_nameless_night | Nameless Night | 5 scenes | defend, pursue, rescue, witness, choose |

Build `0.12.0` implements `boss_warden_stag` in a streamed Warden's Seal annex
unlocked by cleansing Old Growth. Its three phases require two, three, and four
distinct living-root cleanses before 480 shared health can cross the 320, 160,
and zero gates. Each cleansing phase also presents an explicit antler-breaking
shortcut: zero breaks preserves the future forest ally, one scars the outcome,
and two harm it. The encounter remains solo-passable, has bounded lane/ring
telegraphs, grants five unbanked Amber Sap per participant exactly once, and has
a kill switch. The Bramblewake Blackout schedule, permanent saved chapter
decision, final animation, audio, and VFX were open integration work in that
increment.

Build `0.13.0` integrates that encounter into the Bramblewake Blackout. The
server begins one vertical-slice preview for the first unresolved chapter-one
participant, preserves relay and encounter progress after the nine-minute target
as recoverable overtime, resolves a present-participant Greenward vote, and
stores the Warden outcome plus land decision as one immutable save-schema-v4
transaction. The recurring seven-night scheduler, visible future-region/town
consequences, and final animation, audio, and VFX remain open.

Boss completion gates:

- solo, 2-player, 4-player, and 8-player balance passes;
- every attack has animation, shape, sound, and minimum telegraph timing;
- recovery after one down is possible;
- no profession or premium item is required;
- disconnect and late-join behavior is defined;
- skip/cinematic recap behavior is defined;
- reward grants are idempotent.

## Companions

| ID | Companion | Region | Utility |
|---|---|---|---|
| companion_moss_fox | Moss Fox | Bramblewake | finds hidden plant cache |
| companion_bark_beetle | Bark Beetle | Bramblewake | carries one construction stack |
| companion_lantern_moth | Lantern Moth | Bramblewake | points toward safe return landmark |
| companion_rail_mouse | Rail Mouse | Ironroot | detects active machinery |
| companion_cinder_mole | Cinder Mole | Ironroot | reveals one ore seam |
| companion_bell_bat | Bell Bat | Ironroot | sonar marks hollow wall |
| companion_mirror_frog | Mirror Frog | Mireglass | identifies false ground |
| companion_reed_otter | Reed Otter | Mireglass | retrieves one dropped common bundle |
| companion_wisp_eel | Wisp Eel | Mireglass | powers one dormant rune socket |
| companion_storm_gull | Storm Gull | Tempest | warns of lightning direction |
| companion_rope_crab | Rope Crab | Tempest | anchors one temporary climb line |
| companion_tide_newt | Tide Newt | Tempest | predicts next tide transition |
| companion_hush_hare | Hush Hare | Frostmere | reduces noise while walking |
| companion_ember_yak | Ember Yak | Frostmere | expands warmth radius while stationary |
| companion_aurora_owl | Aurora Owl | Frostmere | highlights recent tracks |
| companion_ash_cat | Ash Cat | Cinderfall | distinguishes real resident echoes |
| companion_glass_gecko | Glass Gecko | Cinderfall | safely crosses one fragile surface |
| companion_kiln_toad | Kiln Toad | Cinderfall | stores and releases one heat charge |

Companion skins may be premium. Companion capabilities, bonding, and discovery
are earned only through play.

## Buildings

| ID | Building | District | Functional purpose |
|---|---|---|---|
| building_first_lantern | First Lantern | Lantern Square | phase anchor, story, town integrity |
| building_archive | Memory Archive | Lantern Square | codex, recap, mysteries, consent controls |
| building_town_board | Town Board | Lantern Square | contracts and readiness vote |
| building_celebration_stage | Celebration Stage | Lantern Square | events, endings, social emotes |
| building_workbench | Lantern Workbench | Builder's Row | basic tools and structures |
| building_sawmill | Sawmill | Builder's Row | wood refinement and modules |
| building_forge | Union Forge | Builder's Row | weapons, armor, repair |
| building_engineer_yard | Engineer Yard | Builder's Row | traps, mechanisms, testing |
| building_inn | Wayfarer Inn | Hearthmarket | party formation and resident recovery |
| building_kitchen | Common Kitchen | Hearthmarket | expedition food sidegrades |
| building_market | Hearthmarket Stalls | Hearthmarket | rotating earned goods and cosmetics entry |
| building_trade_post | Trade Post | Hearthmarket | restricted safe player exchange |
| building_garden | Memory Garden | Greenward | plants and resident scenes |
| building_apothecary | Apothecary | Greenward | medicine and alchemy |
| building_waterworks | Waterworks | Greenward | fire response and town recovery |
| building_companion_habitat | Companion Habitat | Greenward | bonding and utility loadout |
| building_library | Quill Library | Scholar's Rise | recipes, lore, profession research |
| building_observatory | Storm Observatory | Scholar's Rise | weather and seed forecast |
| building_rune_lab | Rune Laboratory | Scholar's Rise | runes and memory traits |
| building_map_room | Wayfarer Map Room | Scholar's Rise | region and route planning |
| building_stables | Trail Stables | Beast Yard | companion care and region travel |
| building_training_ground | Training Ground | Beast Yard | combat practice and mastery trials |
| building_rescue_pens | Rescue Pens | Beast Yard | injured creature events |
| building_trail_gate | Trail Gate | Beast Yard | expedition entry and reconnect |
| building_guardhouse | Guardhouse | Watch Ring | resident defenders and one recovery |
| building_watchtower | Watchtower | Watch Ring | lane warning and ranged support |
| building_trapworks | Trapworks | Watch Ring | defense placement presets |
| building_deep_gate | Deep Gate | Deep Gate | finale access and postgame network |

Each building has three gameplay tiers, a damaged state, a repair state, resident
interactions, day and night animation sets, and at least three earned visual sets.

## Resource catalog

| Region | Five primary resources |
|---|---|
| Bramblewake | heartwood, amber sap, meadow fiber, brightcap, spring clay |
| Ironroot | ironroot ore, coalglass, glow fungus, machine oil, echo crystal |
| Mireglass | mirror reed, bog iron, witchlight pollen, eel oil, blackwater herb |
| Tempest | storm copper, salt crystal, sailcloth, coral bone, charged glass |
| Frostmere | frostglass, wool moss, blue salt, ember lichen, aurora thread |
| Cinderfall | cindersteel, memory glass, ash silk, kiln pearl, crown coal |

The implemented Bramblewake material IDs are:

| Stable ID | Display name |
|---|---|
| `material_heartwood` | Heartwood |
| `material_amber_sap` | Amber Sap |
| `material_meadow_fiber` | Meadow Fiber |
| `material_brightcap` | Brightcap |
| `material_spring_clay` | Spring Clay |

Shared resources are food, clean water, scrap, cloth, stone, resin, and lantern
oil. Finale components are bound story items and cannot be traded or purchased.

Resource nodes require an interaction decision or traversal context; they are not
idle-click props. Regional common resources have at least three sources so one
event cannot block progression.

## Equipment families

### Weapons

| ID | Family | Identity |
|---|---|---|
| weapon_blade | Blade | balanced combo, guard, precise counter |
| weapon_hammer | Hammer | structure damage, stagger, slow commitment |
| weapon_spear | Spear | reach, lane control, brace |
| weapon_bow | Bow | weak-point setup, retrieval, line of sight |
| weapon_sling | Sling | mobile ranged utility and status payload |
| weapon_lantern_staff | Lantern Staff | runes, wards, support, lower physical damage |

### Tools

| ID | Family | Primary uses |
|---|---|---|
| tool_axe | Axe | wood, vines, emergency wedge |
| tool_pick | Pick | ore, breakable stone, armor crack |
| tool_hammer | Builder Hammer | build, repair, mechanism reset |
| tool_sickle | Sickle | plants, reeds, snare removal |
| tool_lantern | Field Lantern | darkness, signals, rune sockets |
| tool_fishing | Fishing Kit | food, salvage, water events |
| tool_climbing | Climbing Kit | anchors, ropes, vertical routes |
| tool_survey | Survey Kit | map, weather, secrets, safe route |

### Crafting target

**This target was revised down from 180 to 130, deliberately.** The
original allocation was written before the game had weapon families,
armour lines, or an effect system for consumables, and it assumed
categories that turned out not to exist -- tool variants (tools are a
fixed starting kit, not craftable), town project components (town
building spends the wallet directly, not recipes), defense devices (the
trap system arms from materials rather than from crafted items), and
companion utilities (companions are a party slot, not an inventory one).

Reaching 180 inside the categories that do exist would have meant a
second copy of every item with different numbers. That clears any count
gate and nothing in a test suite can detect it, but a player meets it
within an hour. The count moved instead.

The 130 launch recipes are allocated as:

| ID | Recipe group | Count | What makes each one distinct |
|---|---|---:|---|
| recipe_group_weapons | Weapons | 36 | Six families × six regions; a region is an axis (weight, reach, range, stamina, guard), not a tier |
| recipe_group_wearables | Armour | 60 | Five slots × six regions × two lines; light returns stamina, heavy reduces damage, every slot offers both |
| recipe_group_consumables | Things that are used | 34 | Six effect kinds, each answering a threat the game already makes |

No recipe may be a strict paid upgrade. Each recipe declares its output,
its station, and ingredients the expedition ledger accepts, and
`ContentCensus.spec` asserts these counts against the catalogs so the
number in this table cannot drift from the number in the game.

**Two reachability gaps, the same shape, found on 2026-08-07 by asking
whether content that exists can actually be got at.** The first is fixed;
the second is recorded at its real size.

**Residents (open): 24 of the 27 cannot be met.** `WorldService`'s
resident definitions are a hand-written table with three entries, so
everyone after chapter one arrives with a chapter, takes a job at a real
building, carries a quest and a full set of dialogue — and has no body
standing in the town to say it to. Their quests are unreachable for the
same reason their greetings are. Chapter one's three are built, so a
fresh player's whole path is populated and the arcs shipped for Tomas,
Pip and Ena work. `ContentCensus.spec` asserts 3 built and 24 missing.

**Recipes (fixed): 120 of the 130 could not be crafted.** The workshop's benches were a
hardcoded list of ten in `WorldService`, each needing its own constant in
`RuntimeIds.InteractionIds`, and it never grew when the catalog did.
Every spec passes, the equipment exists, the visual plans exist, the
equip panel has a button for each — and there is no bench to make them
at. A recipe existing and a recipe being reachable are different facts,
and until this the census only checked the first.

Fixed: the benches derive from `CraftingCatalog.list()` and the
interaction id derives from the recipe (`craft:<recipeId>`), and the
census asserts the derivation itself so a hand-written list cannot come
back. Verified live — 130 benches, each carrying its own payload.

The lesson generalises, which is why the resident gap above was found
immediately afterwards: **a thing existing in a catalog and a thing being
reachable in the world are different facts, and only the first one is
easy to test.** Anywhere a hand-written table in `WorldService` mirrors a
shared catalog is worth the same suspicion.

The rest of that sweep, so nobody repeats it:

- **Town decorations — clean.** All eight of `TownDecorations`' slots are
  built in the world, so the resident quest that asks for eight placed is
  finishable.
- **Town buildings — clean.** All 28 are placed: 26 through
  `authoredBuilding`/`buildingShell` (which `validate_town_layout.py`
  reads), plus `building_town_board` and `building_first_lantern` through
  older bespoke code.
- **Encounter arenas — not applicable yet.** All twelve are filed in
  `RegionBuilders.Arenas`, and their regions are still closed, so
  unreachable is the correct state rather than a gap.

Both of the earlier gaps this section recorded are closed: Bramblewake now
carries ten armour pieces and twelve points of interest like every other
region, with its four fragment-anchored POIs pinned into every run. The
gentlest numbers in the game live on its new armour on purpose — it is
the gear a player crafts before they understand the light/heavy choice.

## Memory archive

Twenty memory fragments. Bramblewake carries ten in three authored acts —
what the forest kept, the keeper's trail, and your part in it — and each
later surface region carries two, in a fourth act that says one thing
about what happened to a place rather than retelling a chapter the player
is already walking through.

Every fragment names the region that holds it and anchors to a point of
interest that region can actually place, checked against the catalogs by
`MemoryFragments.spec` rather than against a list. A run only places the
fragments belonging to the region it built. Act four is gated behind
chapter one, like act three, because the archive reaching past the forest
is nonsense read before the forest is finished.

The Hollow Below has no fragments and will not get any: the finale is the
thing the archive has been pointing at, and a collectible inside it would
be the game explaining its own ending twice.

## Dynamic events

Each surface region ships eight event templates:

The Bramblewake vertical slice implements all eight runtime templates. Every
event remains optional, has a profession-independent solution, and fails without
blocking the extraction route. All later-region events remain catalog targets
rather than implemented runtime content.

### Bramblewake

`event_bw_moving_hedge`, `event_bw_lost_wagon`, `event_bw_pollen_storm`,
`event_bw_root_bridge`, `event_bw_hungry_homestead`, `event_bw_foxlight_trail`,
`event_bw_stag_tracks`, `event_bw_wildfire_choice`.

### Ironroot

`event_ir_runaway_cart`, `event_ir_gas_leak`, `event_ir_shift_change`,
`event_ir_cave_rescue`, `event_ir_machine_vote`, `event_ir_lost_lunchbox`,
`event_ir_fungus_bloom`, `event_ir_bell_warning`.

### Mireglass

`event_mg_mirror_party`, `event_mg_sinking_house`, `event_mg_ferry_bargain`,
`event_mg_false_rescue`, `event_mg_eel_migration`, `event_mg_reed_fire`,
`event_mg_three_answers`, `event_mg_drowned_market`.

### Tempest

`event_tr_signal_chain`, `event_tr_sudden_tide`, `event_tr_wreck_survivor`,
`event_tr_lightning_map`, `event_tr_sail_lift`, `event_tr_storm_eye`,
`event_tr_gull_delivery`, `event_tr_broken_beacon`.

### Frostmere

`event_fv_warmth_split`, `event_fv_abbey_bell`, `event_fv_thin_ice`,
`event_fv_aurora_tracks`, `event_fv_frozen_letter`, `event_fv_whiteout_camp`,
`event_fv_quiet_hunt`, `event_fv_thaw_choice`.

### Cinderfall

`event_cc_parade_loop`, `event_cc_glass_family`, `event_cc_kiln_restart`,
`event_cc_actor_rescue`, `event_cc_ash_storm`, `event_cc_false_shop`,
`event_cc_cooling_channel`, `event_cc_empty_applause`.

Every event defines start conditions, incompatible events, minimum route space,
solo and group variants, failure resolution, reward transaction, NPC aftermath,
localization, analytics, and a kill switch.

## Points of interest

Each of the six surface regions has 12 POIs consisting of:

- 4 story or resident locations;
- 2 traversal challenges;
- 2 puzzles or mysteries;
- 2 resource-risk sites;
- 1 elite arena;
- 1 hidden sanctuary.

At least four surface POIs per region change after chapter completion. The
Hollow Below instead has seven authored finale POIs—one for each final scene—
whose order and transitions are fixed and tested. Surface POIs do not all spawn
in one expedition; the seed history system reduces immediate repetition.

## Quest inventory

**Revised, like the crafting target, to describe what exists.** Three of
the original eight families turned out to be other systems wearing the
word "quest": the prologue is `TutorialFlow`, the chapter arcs are
`ChapterCatalog` (seven chapters, each with a decision and three
outcomes, resolved by a boss encounter), and the postgame is the finale's
three endings plus `requiresEnding` on the roster. Counting those as
missing quests would have meant building a second, worse copy of each.

| ID | Quest family | Built | Requirement |
|---|---|---:|---|
| quest_group_resident | Resident arcs | 33 | one per resident, plus three-stage arcs for chapter one's three |
| quest_group_prologue | Prologue arc | n/a | delivered as `TutorialFlow`, not as quests |
| quest_group_chapter | Chapter arcs | n/a | delivered as `ChapterCatalog` and the boss encounters |
| quest_group_postgame | Postgame | n/a | delivered as the three endings and `requiresEnding` |
| quest_group_mastery | Profession mastery tracks | 7 | one trial per profession, at mastery level 4 — deep in one rather than wide across seven |
| quest_group_mystery | Region mystery groups | 6 | one per surface region: recover that place's memories specifically |
| quest_group_contract | Contract templates | 0 | needs a contract generator; no system today |
| quest_group_crisis | Crisis templates | 0 | `ResidentLife.crisis` is the seed of this and is not yet quest-shaped |

Objectives come in two shapes. Most are counts -- how many nights, how
many crafts -- and any activity moves them. The mastery trials and region
mysteries are *keyed*: an objective names a profession or a region, and
only progress in that one counts. That is the difference between a quest
any play satisfies and a quest that sends a player somewhere specific,
and it is why those two families waited for the signal rather than being
faked with a count.

Every quest declares an objective kind that `Quests.currentValue` routes
and `SaveSchema.questSignals` feeds -- a kind nothing feeds reads zero
forever and is refused by spec. Arcs are ordered: a stage whose
predecessor is unclaimed does not progress, is not offered, and cannot
claim itself, and one pass claims at most one stage of an arc so a
player hears each request rather than receiving a whole arc in one tick.

Extending an arc is now catalog-only work: an entry with `residentId` and
`requires` is a new stage, and the dialogue finds it without any list
being kept in a second place.

Quest steps use stable IDs and idempotent completion. A player can always recover
from disconnect between objective completion and reward.

## Cosmetics and expression

Earned and premium catalogs may include:

- avatar-compatible outfits and accessories;
- tool and weapon appearances;
- lantern shells, light trails, and emotes;
- companion skins;
- building facades, signs, furniture, banners, plants, and weather-safe decorations;
- celebration poses, profile frames, titles, and town arrival effects.

All effects have intensity caps and reduced-effects alternatives. Cosmetics cannot
imitate hazard colors, enemy telegraphs, moderation/admin indicators, rarity beams,
or another player's interaction prompts.
