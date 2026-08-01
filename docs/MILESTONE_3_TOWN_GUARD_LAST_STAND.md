# Milestone 3 Town Guard Last Stand

Build `0.29.0` adds one bounded whole-party recovery to normal town nights. It
is a shared Night Watch response, not a self-revive, paid revive, permanent
upgrade, or expedition safety net.

## Implemented scope

- recovery is considered only after every connected, tutorial-ready town player
  has entered the server-owned downed state;
- expedition players and players who have not reached the survival-ready tutorial
  state are excluded from both the party count and recovery;
- one Last Stand can resolve per active normal night;
- the First Lantern must have at least 30 strength and spends 12 strength;
- intentional recovery cost bypasses the Engineer Rootline Brace because it is
  shared-resource expenditure, not hostile lantern pressure;
- each eligible downed player returns at 50 health with a five-second ward;
- leaving players are removed before the remaining party is reevaluated, so a
  disconnect cannot leave a fully downed party stranded behind a stale count;
- active revive channels are cancelled before the group recovery is applied;
- four physical Watch pennants rise around the First Lantern, the existing watch
  route signals answer, and recovered characters carry a short ward outline;
- world attributes and bounded analytics expose night, party size, lantern spend,
  acceptance, and rejection reason without accepting client authority.

There is no new HUD rail, touch target, input binding, Developer Product, or
client-supplied health, night, party count, position, or lantern cost.

## Authority and failure behavior

`TownGuardLastStand.luau` owns the immutable once-per-night decision and numeric
bounds. `PlayerSurvivalService` owns the eligible party from live server state.
`TownNightService` owns the frozen active-night identity and use record.
`EnemyService` performs the intentional lantern spend, separately from hostile
pressure and brace absorption.

Malformed context, daylight, an empty party, one still-active player, a repeated
attempt in the same night, or weak lantern strength fail without recovery. The
normal bleedout and safe-retreat path remains available when Last Stand cannot
fire. The pure use record is session state because the normal-night loop itself
is server-session state; the night number remains persistent through the existing
profile contract.

## Automated evidence

- pure tests cover accepted recovery, active-party rejection, one use per night,
  weak lantern rejection, daylight/empty parties, and malformed counts;
- strict typecheck and Selene cover the survival, night, enemy, analytics, and
  physical-world wiring;
- Studio integration validates the shared recovery contract and proves no rally
  model exists before a whole-party collapse;
- both generated places embed build `0.29.0`, world
  `bramblewake-blackout-v8`, and save schema `11`.

## Studio and device gate

1. Complete First Light with two local players and enter a normal town night.
2. Down one player and confirm Last Stand does not fire while the other can act.
3. Down the second player and confirm both recover at 50 health with a five-second
   ward while the First Lantern loses exactly 12 strength.
4. Confirm the physical Watch response appears briefly without hiding enemies,
   prompts, attack telegraphs, or mobile controls.
5. Down the full party again in the same night and confirm no second recovery.
6. Repeat at 29 lantern strength and confirm ordinary bleedout/safe retreat remains.
7. Repeat while one player is in Bramblewake and confirm the expedition player is
   excluded and receives no town recovery.
8. Disconnect one active player while all remaining eligible players are downed;
   confirm the remaining party is reevaluated once and never receives duplicates.
9. Repeat with solo, 2, 4, and 8 players on phone, tablet, keyboard/mouse, and
   controller, including a veteran joining mid-night with a higher saved count.
10. Verify analytics records accepted and rejected attempts without profile data.

Final authored animation and sound, captions for that sound, true terminal town
defeat/spectating, boss-specific defeat, and recorded Studio/device/group evidence
remain open.
