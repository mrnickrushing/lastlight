# Asset provenance

## Purpose

This is the artifact an original-IP audit reads. QA_RELEASE_PLAN.md's narrative
review asks for "original-IP and asset provenance", and until Milestone 14 the
three asset validators could answer *does this asset exist and decode* but not
*where did it come from*. The manifests each said something about origin, in
three different vocabularies, and the audio manifest said it **once, at the top
of the file, for every track at the same time.**

A statement made once over a whole registry is the form of evidence that stops
being true one asset at a time. The twenty-sixth track added under a heading
that says "all tracks are free public-domain audio from verified providers"
inherits a claim nobody made about it, and nothing anywhere fails.

So origin is a per-asset field from a closed vocabulary, `scripts/asset_provenance.py`
holds the vocabulary and the rules, and all three validators call it. The counts
below are pinned; the third one is the number that matters.

**What this document cannot do is read a licence.** Whether Roblox's terms cover
the use this game makes of a particular Creator Store model is a human question,
and a check that claimed to have settled it would be worse than one that says it
cannot. What is mechanical is that every shipped asset is filed under a class,
that each class carries the evidence its class requires, and that the inventory
below and the manifests name the same assets. The reading is the owner's.

## Origin classes

| Class | What it means | Evidence the manifest must carry | What the audit confirms |
|---|---|---|---|
| `authored_here` | Made in this repository by its own pipeline. | `provenance` | Nothing external. Nobody has to be asked about a thing this repository made. |
| `generated_then_authored_here` | A generative tool produced a starting point which was then normalized and finished here. | `provenance` naming the tool | That the tool's output terms permit commercial use, and that nothing recognisable of a third party survived into the finished asset. |
| `licensed_platform_library` | Somebody else's work, obtained from Roblox's own Creator Store or audio library. | `provenance`, `licensedFrom`, `sourceUrl` | The terms each item is distributed under, and that they cover this use. **This is the class the audit is actually about.** |

"We made it" and "a model made it and we normalized it" are different answers,
and only one of them is interesting to an audit, which is why the middle class
exists rather than being folded into the first.

## Counts

Pinned in `scripts/asset_provenance.py`. Changing one is a deliberate act and
belongs in a pull request that says what arrived.

| Class | Assets |
|---|---|
| `authored_here` | 10 |
| `generated_then_authored_here` | 34 |
| `licensed_platform_library` | 51 |

The pin on the third is the load-bearing one: somebody else's work entering the
game should be a decision, not a diff nobody sized.

## The licensed inventory

Every asset in the game that belongs to somebody else, with who published it and
where it lives. The validators check this table against the manifests in both
directions -- an asset missing from here is an asset nobody reviews, and a row
here for an asset no manifest ships is a licence somebody is still paying
attention to for nothing.

| Asset | Published by | Source |
|---|---|---|
| `mesh_creator_kerosene_lantern_a` | lospakos | `https://create.roblox.com/store/asset/11865884168/Lantern` |
| `mesh_creator_first_lantern_a` | EndorsedModel | `https://create.roblox.com/store/asset/285454336/Dynamically-Lit-Lantern` |
| `mesh_creator_street_lantern_a` | I4supraa | `https://create.roblox.com/store/asset/8990192177/Low-poly-Street-Lantern` |
| `mesh_creator_campfire_a` | hipodrava | `https://create.roblox.com/store/asset/8752362543/Campfire` |
| `mesh_creator_wood_arch_a` | NormalUselessPerson | `https://create.roblox.com/store/asset/11084945828/Gateway-Arch` |
| `mesh_creator_rustic_fence_a` | clean_home | `https://create.roblox.com/store/asset/11701774894/Wooden-fences` |
| `mesh_creator_workbench_a` | qqSimu | `https://create.roblox.com/store/asset/12752821484/wood-clasic-ss1` |
| `mesh_creator_forest_sign_a` | Turbo203Star | `https://create.roblox.com/store/asset/82202632313902/Medieval-Road-Signpost-Town-Village-Path-Way` |
| `mesh_creator_tool_set_a` | GrazzyLimming | `https://create.roblox.com/store/asset/14578957942/esya-paketi` |
| `mesh_creator_barrel_a` | Administrator_OM3GA | `https://create.roblox.com/store/asset/4890213351/Barrel-Rex-studio-only` |
| `mesh_creator_road_stones_a` | UserAlternate8528 | `https://create.roblox.com/store/asset/15971612316/Cobblestone-Path-AltDuckAdventures` |
| `mesh_creator_barricade_a` | chipmunk_bf | `https://create.roblox.com/store/asset/15994552252/Warning-Wood-Barrier` |
| `mesh_creator_notice_board_a` | apolloreals | `https://create.roblox.com/store/asset/16148507760/Sign-by-apalo` |
| `mesh_creator_stump_a` | TwixyPlayss | `https://create.roblox.com/store/asset/17626490923/StumpBooth` |
| `mesh_creator_market_stall_a` | HaizieR | `https://create.roblox.com/store/asset/2033520495/Stall-V2` |
| `mesh_creator_wheat_cluster_a` | Rhyrne | `https://create.roblox.com/store/asset/252932623/Corn` |
| `mesh_creator_picnic_table_a` | Rythimator | `https://create.roblox.com/store/asset/2671684461/picnic-table` |
| `mesh_creator_watchtower_a` | RadiatedFrogz | `https://create.roblox.com/store/asset/3237246061/Wooden-Watchtower` |
| `mesh_creator_crate_a` | Lis_Boris | `https://create.roblox.com/store/asset/8314504894/wooden-box` |
| `mesh_creator_field_rows_a` | lilrascal8 | `https://create.roblox.com/store/asset/84661463/For-rpg` |
| `mesh_creator_wayfarer_bed_a` | wyattbro00 | `https://create.roblox.com/store/asset/5613094175/Wooden-Bed` |
| `mesh_creator_anvil_a` | IllusivePhantasm | `https://create.roblox.com/store/asset/11946437830/Anvil` |
| `mesh_creator_potion_shelf_a` | WarpedSockMonkey | `https://create.roblox.com/store/asset/107193693143362/Classic-Potion-Maker-s-Shelf` |
| `mesh_creator_hand_axe_a` | joseisbestie55 | `https://create.roblox.com/store/asset/103237554596713/Battle-Axe` |
| `mesh_creator_blacksmith_hammer_a` | br45entei | `https://create.roblox.com/store/asset/43904769/Blacksmith-s-Hammer` |
| `mesh_creator_handheld_torch_a` | AII_11 | `https://create.roblox.com/store/asset/8285874309/Torch` |
| `music_emberhollow_day` | DistrokidOfficial | `https://create.roblox.com/store/asset/110126070795458` |
| `music_emberhollow_dusk` | DistrokidOfficial | `https://create.roblox.com/store/asset/101993543714380` |
| `music_emberhollow_night` | DistrokidOfficial | `https://create.roblox.com/store/asset/124064284287798` |
| `music_bramblewake_day` | DistrokidOfficial | `https://create.roblox.com/store/asset/117417781820406` |
| `music_bramblewake_dusk` | DistrokidOfficial | `https://create.roblox.com/store/asset/100440206824362` |
| `music_bramblewake_night` | APMOfficial | `https://create.roblox.com/store/asset/1848132434` |
| `music_ironroot_day` | APMOfficial | `https://create.roblox.com/store/asset/1843033808` |
| `music_ironroot_dusk` | APMOfficial | `https://create.roblox.com/store/asset/1843781882` |
| `music_ironroot_night` | APMOfficial | `https://create.roblox.com/store/asset/9038335527` |
| `music_mireglass_day` | DistrokidOfficial | `https://create.roblox.com/store/asset/89192635799608` |
| `music_mireglass_dusk` | APMOfficial | `https://create.roblox.com/store/asset/1837021963` |
| `music_mireglass_night` | APMOfficial | `https://create.roblox.com/store/asset/1840777445` |
| `music_tempest_day` | DistrokidOfficial | `https://create.roblox.com/store/asset/84787113230396` |
| `music_tempest_dusk` | DistrokidOfficial | `https://create.roblox.com/store/asset/71987344991492` |
| `music_tempest_night` | APMOfficial | `https://create.roblox.com/store/asset/1836768154` |
| `music_frostmere_day` | DistrokidOfficial | `https://create.roblox.com/store/asset/103006284758182` |
| `music_frostmere_dusk` | DistrokidOfficial | `https://create.roblox.com/store/asset/125256568468294` |
| `music_frostmere_night` | DistrokidOfficial | `https://create.roblox.com/store/asset/71207032544256` |
| `music_cinderfall_day` | APMOfficial | `https://create.roblox.com/store/asset/77719566372748` |
| `music_cinderfall_dusk` | DistrokidOfficial | `https://create.roblox.com/store/asset/131701319079131` |
| `music_cinderfall_night` | APMOfficial | `https://create.roblox.com/store/asset/1845714245` |
| `music_hollow_day` | DistrokidOfficial | `https://create.roblox.com/store/asset/83957123998450` |
| `music_hollow_dusk` | DistrokidOfficial | `https://create.roblox.com/store/asset/137422342530077` |
| `music_hollow_night` | DistrokidOfficial | `https://create.roblox.com/store/asset/106591893537345` |
| `music_blackout_pulse` | APMOfficial | `https://create.roblox.com/store/asset/126401983585086` |

## The originals

The other 44 assets were made for this game. The Blender procedural
pipeline authored 10 of them outright; 34 began as output from a
generative tool (Meshy, Higgsfield or OpenAI image generation) and were
normalized, rescaled and finished here against the style formula recorded in
`assets/meshes/manifest.json`. Each carries its own provenance sentence naming
which, because an audit that has to infer the tool from a filename is an audit
reading a guess.
