# Milestone 3 profession specializations

Build `0.26.0` and save schema `11` turn the twelve level-10 profession path IDs
into persistent, playable choices. Selection happens at four physical mastery
altars in Emberhollow rather than through another permanent HUD layer.

## Selection contract

A path can be selected only when all of the following are true:

- the player has reached level 10 in the matching profession;
- that profession is currently equipped;
- the player is active, outside Bramblewake, and allowed to switch professions;
- the server recognizes the exact stable specialization ID;
- the profile is loaded and writable.

Selection is free and reversible at the matching altar during safe daylight.
No path is auto-selected, sold, randomized, or required for baseline content.
Repeated selection is idempotent and cross-profession IDs are rejected.

## Physical mastery grove

The grove uses four restrained slate-and-root daises around Emberhollow: Scout,
Warden, Engineer, and Medic. Each has three named path stones and a distinct
material accent. Every stone is a real collidable world object using the normal
proximity interaction pipeline, distance validation, hold channel, touch prompt,
keyboard prompt, and gamepad prompt. There is no floating mystery glyph and no
new always-visible mobile button.

## Path effects

| Profession | Path | Server-owned effect |
|---|---|---|
| Scout | Pathfinder | Foxfire Mark reaches 8 studs farther |
| Scout | Foxfire Trapper | Foxfire Mark lasts 3 seconds longer |
| Scout | Trailseer | Foxfire Mark recharges 4 seconds faster |
| Warden | Bulwark | Lantern Guard reduces 10% more incoming damage |
| Warden | Greenkeeper | Lantern Guard lasts 3 seconds longer |
| Warden | Oathbound | rescues grant 1.5 more ward seconds |
| Engineer | Lamplighter | Emergency Patch restores 10 more lantern health |
| Engineer | Rootwright | Emergency Patch reaches 10 studs farther |
| Engineer | Salvager | Emergency Patch recharges 5 seconds faster |
| Medic | Dawnmender | Guiding Pulse restores 10 more health |
| Medic | Wayhome Tender | rescues are faster and restore 8 more health |
| Medic | Brightcap Herbalist | Guiding Pulse reaches 10 studs farther |

All effects compose with existing rank bonuses and remain inside existing
ability, mitigation, revive-health, revive-duration, and ward hard caps.

## Persistence and authority

`ProfessionMastery` owns path catalogs, profession ownership, normalization,
selection, and effect tuning. Schema 11 stores `specializationId` inside that
profession's mastery entry. A locked, unknown, or cross-profession ID is removed
during normalization. Awarding later XP preserves the selected path.

The client and physical prompt submit only a path ID. The server derives the
profession, rank, safe-town availability, effect amounts, ranges, durations,
cooldowns, and rescue values. Accepted and rejected attempts emit analytics.

## Automated validation

Pure Luau tests cover:

- locked, unknown, and cross-profession rejection;
- valid level-10 selection and idempotent replay;
- path persistence through later mastery awards and schema normalization;
- distinct ability and rescue tuning;
- schema-10 to schema-11 migration and wrapper persistence;
- bounded Oathbound and Wayhome rescue behavior.

The full suite also runs format, lint, type checks, 1,000 expedition seeds, both
deterministic place builds, and built DataModel verification.

## Studio and device exit gate

1. Reach level 10 in each profession and inspect all three matching physical
   stones. Require readable names and touch, keyboard, and gamepad prompts.
2. Try a locked path, a path for a non-equipped profession, night, expedition,
   downed, and read-only profile selection. Require a clear rejection and no save
   mutation.
3. Select all twelve paths and compare each ability or rescue against the table.
   Require only the named dimension to change and all caps to hold.
4. Rejoin and restart a private server. Require each profession's selected path
   to persist independently through switching and additional XP awards.
5. Spam and replay selection prompts. Require one durable state transition,
   idempotent feedback, bounded analytics, and no duplicated benefit.
6. Run solo and mixed four-player sessions on baseline phone, tablet, keyboard,
   and controller. Require every route, revive, encounter, and extraction to
   remain possible without a particular path.

Automated checks establish state and generated-place inclusion. Recorded Studio,
DataStore, multiplayer, device, accessibility, and balance evidence remains
required before the engine exit gate closes.
