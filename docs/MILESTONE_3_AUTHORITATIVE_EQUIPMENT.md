# Milestone 3 authoritative equipment

Build `0.20.0` closes the gap between persisted equipment statistics and actual
server gameplay. The Ironroot Hood and Bramble Boots no longer provide
display-only numbers.

## Implemented effects

- **Ironroot Hood — head slot:** reduces incoming damage by 5%.
- **Bramble Boots — feet slot:** regenerates stamina 10% faster after the normal
  spending delay.
- Equipment remains an earned sidegrade. The hood cannot make a player
  invulnerable, and the boots do not reduce sprint drain, dodge cost, or the
  regeneration delay.

## Authority and composition

`PlayerSurvivalService` applies the bounded equipment reduction immediately
before its one shared damage transition. Rootlings, normal-night attackers, Old
Growth, the Warden Stag, and future callers therefore cannot accidentally skip
the passive. Dodge invulnerability, Warden guard, and the Amber Charm resolve
first; the equipped hood composes with their resulting damage.

`PlayerCombatService` supplies the equipped regeneration multiplier to every
state advance, including sprint, dodge, status interruption, consumable restore,
and heartbeat paths. `CombatState` clamps any supplied multiplier to 0.75–1.5
before applying it.

Both services read equipment through a server-owned profile provider. Clients
cannot submit a stat value. Replicated player attributes expose the effective
reduction and regeneration multiplier for Studio inspection only.

## Validation

Pure Luau tests cover slot normalization, combined equipped statistics, boosted
stamina regeneration, and unsafe multiplier clamping. `npm test` regenerates and
verifies both checked-in place artifacts.

Studio/device evidence remains required for the complete equip/use journey and
for timing the boots against the normal regeneration cadence.
