# Milestone 6 weapon-families runbook

## Scope

Six weapon families for the roadmap's "six weapon and eight tool families"
deliverable, each with a distinct moveset expressed through the
server-authoritative strike:

| Family | Item | Identity |
|---|---|---|
| Bow | Thornwood Bow | ranged 30 studs, 0.8x (pre-existing) |
| Maul | Heartwood Maul | melee, 1.45x — the damage ceiling with no reach |
| Lance | Briar Lance | melee reach 14 studs at full strength, no projectile |
| Sling | Foxfire Sling | ranged 22 studs, 0.7x, 2.5s snare on hit (0.75x speed) |
| Edge | Amber Edge | melee, 1.1x, returns 6 stamina on a landed hit |
| Cudgel | Warden Cudgel | melee, 1.05x, +4% damage reduction while equipped |

Every number sits inside bounds combat already clamps (strike damage
0.5–1.5x, damage reduction capped at 0.25, snare 0.5–4s, refund 1–12), so no
family can silence an enemy's mechanics. The snare slots between the Scout's
mark (0.65x) and the Beastkeeper's lure (0.8x) so stacked sources stay
readable. Riders apply only on a landed hit, from Equipment's own
definitions — a client never submits range, damage, or an effect.

Each family is craftable at its own physical bench in the workshop row
(the row grew 5 → 10, every bench carrying its own sample silhouette), has a
held visual plan (`GearVisualPlan`, 3 → 8 item plans), an equip button and
viewport icon in the Field Book (now three per row, stacking upward), and a
recipe priced in expedition materials.

## Also fixed in this increment

- **The bow bench had displayed a pair of boots since it shipped**: the
  bench sample chain's `else` branch was the boots, and the bow (plus all
  five new benches) fell through to it. Every bench now has an explicit
  silhouette branch.
- **The departure panel followed the player across town** once the lodge
  streamed out: the distance gate held a platform *instance*, which
  streaming nils at range, failing the gate open — and the gate only
  re-evaluated on server state pushes, which can be minutes apart. The gate
  now works from the platform's cached *position* (which survives
  streaming) and re-evaluates on the same local render tick Mara's line
  already uses. Verified live: visible on the platform, hidden within 1.5s
  at 230 studs, visible again on return.

## Automated evidence

`npm test` (529 tests) covers, beyond the derived suites that grew
automatically: the six families each declaring a distinct bounded moveset,
every weapon being craftable at a bench, and bare hands keeping their
defaults. The Studio interaction census moved 70 → 75 (five new bench
prompts) with its class-by-class derivation updated.

## Studio evidence recorded (connected session, this increment)

- `[Last Light] PASS FoundationIntegration` on a clean fresh-save boot with
  all ten benches (each display ≥ 10 parts), `itemPlans=8`, and the new
  census.
- The departure-panel fix verified live at the platform, at 230 studs, and
  on return.

## Economy-loop evidence (recorded after the fact)

The full loop was driven end to end in a connected session: 4 amber sap +
3 heartwood harvested, "WAYHOME — 7 MATERIALS BANKED", "CRAFTED AMBER
EDGE" (which also completed the FIRST CRAFT quest), "EQUIPPED
GEAR_AMBER_EDGE", and then landed strikes on a Night 1 Rootling. The
edge's rider measured exactly: a dodge leaves 65 stamina with regen
blocked for 0.75s, and the reading 0.6s after a landed strike inside that
window was **71 = 65 + 6**, both trials. Driving the loop also surfaced
and fixed two blockers recorded in the delivery PR: node harvests threw
"reward contract is invalid" on every grant (wrong reward shape at the
call site — no node had ever paid out), and post-tutorial strikes were
gated to the tutorial's survive stage (a completed save could not fight
town nights at all).

## Open work

Per-family live strikes for the maul, lance, sling, and cudgel (the loop
is proven; each is one more craft), the sling's snare observed live, and
the remaining M6 systemic items: loadouts, repair, equipment traits, the
status/reaction system, companions, the enemy director, defense plots.
