# Milestone 3 gear effects

## Scope

Build `0.19.0` gives crafted gear its first real effect: each item can be
used for a one-time consumable buff instead of sitting inert in a player's
profile.

```text
own at least one crafted item
  → trigger its dedicated HUD button/key (or gamepad binding)
  → server checks the buff's own precondition (stamina not already full,
    player able to act, tutorial complete)
  → precondition met: one unit consumed, buff applied, toast confirms
  → precondition unmet: nothing is spent, toast explains why
```

This document records the original `0.19.0` consumable-item slice. Permanent
equipment slots were added afterward, and their effects became authoritative in
[MILESTONE_3_AUTHORITATIVE_EQUIPMENT.md](MILESTONE_3_AUTHORITATIVE_EQUIPMENT.md).

The original slice implemented:

- **Amber Charm** grants a **40% damage-reduction shield for 5 seconds**
  (`StatusEffectState.applyShield`, mirroring the existing drowsy/rooted
  duration+multiplier shape). It stacks with, rather than replaces, a
  Warden's own Lantern Guard mitigation — the two are independent checks at
  every damage call site.
- **Meadow Satchel** grants an **instant +50 stamina restore**
  (`CombatState.restoreStamina`), routed through the same `advance()` step
  every other stamina transition uses so pending drain/regen is settled
  first.
- Both consumable items are one-time uses: using one always removes exactly one unit
  from the player's `gear` map (`Crafting.useItem`, the mirror image of
  `Crafting.craft`'s atomic deduct-and-grant transaction). There is no
  equip/unequip state for those two consumables — an item is either owned or
  it has been spent. Ironroot Hood and Bramble Boots are separate permanent
  equipment outputs.
- A dedicated HUD button per item (not a picker), each wired through
  Roblox's Input Action System with keyboard, gamepad, and touch bindings,
  the same multi-input parity every other core action already has. A
  button is only visible once its owned count is above zero.

Additional equipment slots and crafting gear into better gear remain open.
Head/feet slots, authoritative passive stats, and their first replicated 3D
character silhouettes are now implemented.

## Flow and authority

The server alone decides whether a use is accepted. `TutorialService._useGear`
checks preconditions (tutorial complete, player able to act, and — for the
Meadow Satchel specifically — that stamina isn't already full) *before*
calling `ProfileService.useGearItem`, so a player never loses an item to a
no-op buff. Only after the item is actually consumed does the matching
effect get applied through `PlayerCombatService.applyShield` or
`.restoreStamina`. The client never computes whether a use should succeed;
it only sends a fixed `use_gear` action with the item ID baked into which
button was pressed, and renders whatever toast the server returns.

## Damage mitigation ordering

`EnemyService`, `OldGrowthService`, and `WardenStagService` each already
checked `PlayerCombatService:avoidsDamage` (dodge invulnerability) and
`ProfessionService:mitigateIncomingDamage` (Warden's Lantern Guard) before
calling `PlayerSurvivalService:damage`. The Amber Charm's shield adds a
third, independent check — `PlayerCombatService:mitigateShieldedDamage` —
at the same three call sites, applied after the profession mitigation so
the two damage reductions compose instead of overriding each other.

## Windows Studio journey

1. Download the merged repository ZIP from GitHub and extract it.
2. Open `build/LastLightTest.rbxlx`, press Play, and require
   `[Last Light] PASS FoundationIntegration`, the build version for the commit
   under test (see `src/shared/Config.luau`), and no red errors.
3. Open `build/LastLight.rbxlx`, finish First Light, craft one Meadow
   Satchel and one Amber Charm. Require both the "CHARM ×1" and
   "SATCHEL ×1" HUD buttons to appear, and to be absent before crafting.
4. Take damage until stamina has been spent, then use the Meadow Satchel.
   Require a "MEADOW SATCHEL — STAMINA RESTORED" toast, stamina increasing
   by 50 (capped at max), the button disappearing, and the SATCHEL key/
   gamepad binding to do the same thing as the button.
5. At full stamina, attempt to use a second Meadow Satchel. Require a
   "STAMINA ALREADY FULL" toast and the owned count to stay unchanged.
6. During a night, use the Amber Charm while an enemy attack is incoming.
   Require reduced (not zero) damage for five seconds, and full damage
   again afterward.
7. Attempt to use an Amber Charm while downed. Require a
   "YOU CANNOT USE GEAR WHILE DOWNED" toast and no item consumed.
8. Disconnect and rejoin. Require remaining owned counts to match what was
   true before disconnecting.

## Exit and abuse gate

| Gate | Required evidence |
|---|---:|
| Authority | the server alone decides whether a use succeeds; the client only sends a fixed item ID |
| Atomicity | a use either consumes exactly one unit and applies its effect, or changes nothing at all |
| No wasted items | preconditions (downed, tutorial incomplete, stamina full) are checked before consuming, never after |
| Composability | the Amber Charm's shield stacks with Warden's own mitigation instead of overriding it |
| Input parity | both items are usable via keyboard, gamepad, and touch through the same Input Action System every other core action uses |
| Persistence | remaining owned counts survive a disconnect/reconnect and a server restart |
| Scope honesty | additional slots and gear-crafts-gear progression remain open; head/feet passives and their first replicated visuals are implemented later |

Automated checks establish the shield/stamina-restore transitions and the
consume-one-unit transaction as pure Luau tests. Only recorded Studio and
multiplayer runs can close the rest of this slice's exit gate.
