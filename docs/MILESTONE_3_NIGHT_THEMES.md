# Milestone 3 differentiated town nights

Build `0.20.0` turns the four rotating normal-night names into distinct tactical
profiles and physical states. Wave count and roster order still escalate
deterministically, but the choice of response now changes from night to night.

| Theme | Tactical identity | Physical telegraph |
|---|---|---|
| Emberfall | normal fighters deal 25% more damage to the First Lantern | ember-catching basins and hot coals line the road |
| Miretide | attackers move 18% slower but hit players 20% harder | shallow tide pools and reeds break up the approach |
| Rootmoon | attackers move 6% slower and have 25% more health | living root arches mark the fortified lane |
| Ashen Veil | attackers have 15% less health but move 25% faster | ash drifts and charred wayposts signal the rush |

## Authority and bounds

`TownNightSchedule.profile` owns the immutable profile paired with each rotating
theme. `TownNightService` freezes that profile at the start of the active night
and supplies it to `EnemyService`; a veteran joining mid-night cannot change it.

`EnemyService` clamps every multiplier before use. It applies health at spawn,
speed during movement, player damage before profession/item/equipment
mitigation, and lantern pressure at both direct impacts and spark theft. The
authored first night and boss encounters retain neutral multipliers.

The world rebuilds one non-colliding, theme-specific dressing model at night and
removes it at dawn. Dressing does not alter navigation, camera clearance, hit
volumes, or mobile controls.

## Validation

Pure Luau tests require four unique profiles and enforce the authored safety
bounds. `npm test` regenerates and verifies both checked-in place artifacts.
Studio/device evidence remains required for readability, performance, and full
four-night pacing.
