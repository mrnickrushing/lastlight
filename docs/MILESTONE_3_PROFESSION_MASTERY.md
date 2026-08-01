# Milestone 3 profession mastery

## Scope

The four playable professions now turn successful ability use into persistent,
server-owned mastery progression. Each accepted ability grants 10 XP. Every 100
XP raises that profession one level, up to the vertical-slice cap of level 10.
Invalid targets and rejected requests grant nothing.

| Level | Rank |
|---:|---|
| 1 | Initiate |
| 2 | Keeper |
| 4 | Adept |
| 6 | Veteran |
| 8 | Luminary |
| 10 | Master |

Every second level adds a bounded server-derived improvement: +2 effect amount,
+1.5 studs radius, +0.35 seconds active duration, and -0.4 seconds cooldown.
Only the parts of that package relevant to a kit affect play. At level 10, each
profession exposes three named specialization paths in the mastery snapshot.
Selection and path-specific effects remain a later increment; no path is sold
or silently selected for the player.

## Authority and player feedback

- The client requests only the normal profession ability.
- `ProfessionService` resolves persisted mastery before validating range,
  effect, duration, and cooldown.
- XP is awarded only after the effect commits successfully.
- A level-up is folded into the existing ability toast and emits
  `ProfessionMasteryRank` analytics.
- Warden mitigation reads the same mastery tuning on every server-owned damage
  path; Scout, Engineer, and Medic bonuses stay inside their server services.
- Switching professions never transfers XP or resets cooldowns. Every kit owns
  its own durable mastery entry.

## Specialization foundation

| Profession | Level-10 paths |
|---|---|
| Scout | Pathfinder, Foxfire Trapper, Trailseer |
| Warden | Bulwark, Greenkeeper, Oathbound |
| Engineer | Lamplighter, Rootwright, Salvager |
| Medic | Dawnmender, Wayhome Tender, Brightcap Herbalist |

These stable IDs can be persisted in a future schema without renaming player
choices. This increment deliberately stops before selection because each path
still needs its own gameplay contract, balance pass, and selector evidence.

## Required Studio evidence

1. Use each profession ability successfully and confirm exactly 10 XP is added
   only to the equipped profession.
2. Attempt every invalid target and cooldown case; confirm no XP is granted.
3. Cross levels 2, 4, 6, 8, and 10 and confirm the rank toast appears once.
4. Compare level 1 and level 10 range, amount, duration, and cooldown against the
   bounded values in the server snapshot.
5. Rejoin after progress, switch professions, and confirm each profession keeps
   its own XP and rank.
6. Reach level 10 and confirm the three correct specialization IDs become
   unlocked but none is selected automatically.
7. Verify solo and group balance on phone, keyboard/mouse, and controller. The
   mastery layer must not make any profession mandatory for a route or recovery.

Automated checks cover normalization, award caps, rank boundaries, bonuses,
specialization unlocks, tuned server timing, generated places, and DataModel
verification. Recorded Studio/device evidence remains required for balance and
feel.
