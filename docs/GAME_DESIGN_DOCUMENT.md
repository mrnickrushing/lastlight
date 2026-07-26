# Game design document

## Product statement

Last Light is a cooperative survival-town adventure for Roblox in which one to
eight players spend daylight exploring a changing wilderness and spend night
defending a persistent town whose people, buildings, and appearance remember
their choices.

The intended audience is players roughly 9+ who enjoy cooperative action,
collection, construction, role expression, secrets, and dramatic shared moments.
The game must be understandable alone, better with friends, and readable on a
phone without becoming shallow.

## Design principles

### The town is the emotional health bar

Players defend named residents and visibly repaired places, not an abstract base.
Damage changes tomorrow: an injured baker cannot make travel food, a collapsed
bridge reroutes NPCs, and a saved workshop changes how the next defense unfolds.

### Every session finishes a story

A 20–30 minute session should create a beginning, escalation, decision, and
resolution: prepare, explore, make a risk decision, return, survive, and see a
consequence. Longer progression links those stories without requiring one long
session.

### Roles create cooperation, not dependence

Every profession can fight, gather, revive, and contribute to building. Roles
create different best tools and team moments, never mandatory queue composition.

### Depth comes from interacting systems

Weather changes routes and enemies. Villager jobs change town production. Town
buildings modify expedition possibilities. Profession abilities create alternate
solutions. The game prefers reusable systemic interactions over hundreds of
isolated minigames.

### Failure teaches and redirects

Failure costs some unbanked expedition value and creates repair or recovery
objectives. It does not erase paid items, permanent story knowledge, or hours of
progress, and it never opens a paid-revive prompt.

## Session structure

### First session: 10–12 minutes

1. **Cold open, 45 seconds:** the player wakes beside a failing lantern and
   immediately frees a trapped villager while one harmless creature approaches.
2. **Movement and action, 90 seconds:** context prompts teach move, camera,
   sprint, interact, and gather using the player's current input.
3. **Meaningful choice, 2 minutes:** select one starter tool and one of three
   first priorities: food, walls, or medicine. No permanent class choice.
4. **Expedition, 3 minutes:** follow light moths into a short authored forest,
   gather two resources, rescue Mara, and discover the first memory shard.
5. **Build, 90 seconds:** place and finish the Lantern Workbench. Mara visibly
   moves in and begins working.
6. **First defense, 2 minutes:** repair one breach, defeat a small wave, revive
   an NPC or player if needed, and keep the First Lantern lit.
7. **Reveal, 45 seconds:** the lantern speaks a missing name and reveals the
   Bramblewake map. The player receives a persistent home marker and chooses the
   next objective.

The tutorial never pauses the entire server, never blocks experimentation, and
can be replayed from the archive.

### Normal cycle

| Phase | Target length | Primary decisions |
|---|---:|---|
| Dawn | 1 minute | review damage, collect production, choose priorities |
| Day | 12 minutes | expedition, gathering, rescue, story, optional extraction |
| Dusk | 2 minutes | return, assign jobs, craft, place defenses |
| Night | 6 minutes | defend lanes, repair, rescue, respond to event |
| Blackout | 9 minutes every seventh night | special rules, boss, permanent choice |

The cycle is a target, not a hidden promise. The phase service may compress quiet
time after a unanimous ready vote, but never removes preparation without consent.

### Join-in-progress

- New players spawn in a protected lit arrival room connected to the current town.
- The HUD states the current phase and offers **Join defense**, **Help in town**,
  or **Practice**.
- Late joiners receive a normalized temporary kit based on current town tier.
- A player never spawns in an unloaded area, enemy hitbox, or active hazard.
- Reconnecting players restore their expedition/town position when safe, otherwise
  return to the nearest lantern with preserved banked state.

## Core loops

### Expedition loop

1. Select a region, contract, companion, tool kit, and risk modifier.
2. Enter a deterministic handcrafted-module seed.
3. Read weather and landmarks, choose a route, and establish a return path.
4. Gather, rescue, solve, fight, and discover.
5. Decide whether to extract, push into danger, or answer a dynamic event.
6. Return through the gate or use a scarce crafted flare.
7. Bank resources, relationships, blueprints, and memory fragments.

Expeditions are never mazes with arbitrary dead ends. Every critical objective has
at least two reachable routes or a recovery route, and the generator validates
connectivity, traversal capabilities, extraction, and encounter budget.

### Town loop

1. Inspect overnight damage and resident needs.
2. Assign residents to jobs with strengths, preferences, and current condition.
3. Choose one major town project and any number of small repairs/decorations.
4. Contribute materials directly or fulfill construction orders.
5. See buildings change functionality and daily town behavior.
6. Prepare defenses and emergency stockpiles.
7. Celebrate, mourn, repair, and make chapter decisions after night.

Building locations use authored plots and modular extensions rather than
unrestricted physics placement. This keeps navigation, streaming, mobile controls,
and defense balance reliable while still allowing meaningful town layouts.

### Combat loop

Combat emphasizes positioning, readable telegraphs, rescue, and tools:

- light attack or tool action;
- charged or alternate action;
- dodge with short invulnerability and a clear stamina cost;
- guard/parry for applicable gear;
- profession active ability;
- contextual interaction, such as extinguish, repair, carry, or revive;
- companion utility command.

Enemies signal danger with animation, silhouette, ground shape, and sound. Color
is never the only warning. Crowd control has diminishing returns on bosses.
Server-validated hit windows use generous latency compensation without trusting
client-reported damage.

### Defense loop

Night attacks use three to five authored approach lanes per town layout. The
director composes threats from:

- **pressure:** common enemies that occupy players;
- **breach:** enemies that target structures;
- **disruption:** enemies that extinguish light, obscure vision, or disable traps;
- **crisis:** resident danger, fire, weather, or a split objective;
- **apex:** elite or boss.

The director budgets simultaneous complexity, not merely enemy health. Solo
players receive fewer concurrent crises and stronger resident support. Larger
groups receive more lane pressure and coordination problems, not eight times the
health.

## Player state and failure

### Health, stamina, and light

- Health determines downed state.
- Stamina gates sprint, dodge, charged attacks, and heavy tools.
- Personal lantern charge enables region-specific utility and protects briefly
  from Deep Dark exposure; it is replenished through skillful play and town
  infrastructure, not Robux.

### Downed and rescue

- A player is downed for 30 seconds and can crawl toward light.
- Any player or eligible resident can revive; Medics are faster and safer.
- Taking large damage reduces the timer but never causes instant paid-rescue UI.
- If all active players are downed, the town guard attempts one recovery based on
  Guardhouse tier. Otherwise the night is lost.

### Expedition failure

- Banked items, bound quest items, codex entries, unlocked recipes, and extracted
  residents are safe.
- A configurable portion of unbanked common materials is lost; rare discoveries
  become a recovery cache in a reachable follow-up seed.
- Gear takes condition damage but never permanently breaks.
- The game explains exactly what was kept, lost, and recoverable.

### Night failure

The First Lantern cannot be permanently destroyed. A lost night damages town
structures, injures residents, lowers temporary morale, and creates a recovery
chapter. Story continues through a harder path rather than forcing a save reset.

## Professions

Players can unlock all seven professions. A loadout selects one primary
profession, one cross-profession utility, a weapon, a tool, consumables, and a
companion. Profession changes are free in town.

| Profession | Identity | Team moment | Solo support | Specializations |
|---|---|---|---|---|
| Scout | navigation and weak-point setup | marks safe route and priority target | better route information | Pathfinder, Hunter, Shadowstep |
| Warden | guard and control | intercepts breach or protects revive | resident ally and stronger guard | Bulwark, Vanguard, Sentinel |
| Engineer | structures and mechanisms | emergency repairs and trap networks | deployable helper | Machinist, Trapper, Architect |
| Alchemist | reactions and consumables | creates zones and counters hazards | flexible preparation | Brewer, Catalyst, Forager |
| Medic | rescue and condition care | stabilizes split team or injured residents | restorative companion | Field Surgeon, Herbalist, Beacon |
| Beastkeeper | companions and tracking | commands utility creature for team | strong adaptable companion | Handler, Bondkeeper, Wildspeaker |
| Runebinder | light and memory magic | changes terrain or enemy state briefly | puzzle and ward solutions | Scribe, Channeler, Veilwalker |

Each has 30 mastery ranks:

- ranks 1–10 unlock the complete basic kit;
- ranks 11–20 deepen choices and unlock specializations;
- ranks 21–30 add sidegrades, cosmetic mastery, and challenge techniques;
- mastery never increases base damage indefinitely.

## Equipment and crafting

### Equipment model

Gear uses authored families with rolled minor traits:

- weapon family determines moveset;
- material determines damage/status bias and repair needs;
- two craft choices determine utility traits;
- one discovered memory rune adds a conditional effect;
- cosmetic appearance can be transmuted independently.

Rarity communicates recipe complexity and trait flexibility, not an automatic
power multiplier. Region gear is a sidegrade that solves new problems.

### Tools

Axes, picks, hammers, sickles, lanterns, fishing kits, climbing kits, and survey
instruments have exploration and defense uses. Tool actions use the same input
verbs on every platform.

### Crafting usability

- Recipes show source, purpose, missing materials, and where to get them.
- Players may pin up to three recipes.
- Crafting from town storage is allowed within the relevant district.
- Batch crafting cannot freeze the client and can be canceled.
- Server validates recipe, input ownership, output capacity, and version.
- Materials are reserved atomically before asynchronous work begins.

## Villagers and relationships

Each named resident has:

- a home and preferred district;
- profession, workplace options, and production contribution;
- two compatible residents and one relationship tension;
- a personal quest arc with at least three steps;
- a bond track with gameplay, story, and cosmetic rewards;
- night behavior, injury state, and crisis scenes;
- dialogue for chapter changes, recent victories, losses, and town decisions.

Bond is earned through shared activity and choices, never by repeating a daily gift
timer. Residents can be disappointed but do not permanently leave because the
player missed a day.

## Companions

Companions are discovered and befriended through region behavior, not hatched from
paid random eggs. Their traits are utility-focused: sniff resources, warn of
ambushes, carry one item, reveal tracks, calm residents, retrieve arrows, or
stabilize a downed player once per expedition. Combat output stays secondary.

## Quests and narrative delivery

Quest categories:

- chapter missions advance the central mystery;
- villager arcs develop the town cast;
- contracts create repeatable goals from current systems;
- mysteries reward observation, decoding, and revisiting changed spaces;
- crises respond to damage, relationships, weather, and prior choices;
- mastery challenges teach advanced profession play;
- community events contribute to shared cosmetic town celebrations.

Quest tracking is optional and compact. World landmarks, resident schedules,
light trails, dialogue recaps, and the archive prevent dependence on a waypoint.

## Difficulty and fairness

### Scaling inputs

The director considers:

- active and recently disconnected player count;
- average account and profession mastery;
- town tier and functional defenses;
- recent clear/failure history;
- selected risk modifiers;
- accessibility mode only when it affects mechanical timing, never as a penalty.

### Rules

- Group scaling is based on concurrent threats and objectives before health.
- A required traversal mechanic is never generated unless every party has an
  accessible default solution.
- No boss requires one profession.
- Telegraph duration has a documented minimum for normal and assisted modes.
- All timed interactions have a non-tapping hold option.
- Difficulty presets change pressure, recovery, and timing, not reward ownership.
- Challenge modifiers award cosmetics, titles, extra common materials, and
  leaderboard categories without locking story.

## Social design

- Parties support 1–8 players.
- A player may invite friends from the town and rejoin a recent party.
- Host town changes require explicit permission; visitors contribute through
  work orders and temporary defense placement.
- All contributors earn personal progression. Hosts receive no tax on visitors.
- Trading at launch is limited to crafted decorations and approved common
  materials with two-step confirmation, item locks, value warnings, and logs.
- Rare gear, premium items, quest items, currencies, and companions are not
  tradable at launch.
- Public town showcases allow likes but no competitive reward for like count.
- Pings, quick chat, emotes, and contextual callouts support players without voice.

## Retention without manipulation

Players should return because:

- the town visibly changes;
- residents have new behavior after story events;
- professions offer mastery and expression;
- seeds create new routes and events;
- friends can help with meaningful work;
- weekly world conditions recombine existing systems;
- new chapters add regions and mysteries.

The design forbids:

- paid streak protection;
- irreversible missed-day rewards;
- energy that prevents normal play;
- purchased combat stats;
- random paid reward boxes;
- paid revives;
- fake discounts or obscured currency conversion;
- intentionally slow construction sold back as speed.

## Launch completion criteria

The design is content-complete when the catalog in
[CONTENT_CATALOG.md](CONTENT_CATALOG.md) is implemented, every story path is
playable, and every dependency and test gate in
[PRODUCTION_ROADMAP.md](PRODUCTION_ROADMAP.md) and
[QA_RELEASE_PLAN.md](QA_RELEASE_PLAN.md) passes.

