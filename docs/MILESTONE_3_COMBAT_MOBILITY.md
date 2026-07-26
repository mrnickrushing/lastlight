# Milestone 3 combat mobility and Rootling telegraph foundation

## Scope

This increment establishes the server-authoritative mobility contract that
profession kits, the remaining enemy roster, bosses, and Blackouts will use. It
does not complete the full combat system or Milestone 3.

Implemented in source:

- immutable, server-owned 100-point stamina state;
- sprint at 24 walk speed with 18 stamina drained per second;
- regeneration at 24 stamina per second after a 0.75-second spending delay;
- a 35-stamina dodge with a 1.25-second cooldown and 0.42-second protection window;
- server-selected dodge direction and velocity, never a client position or speed;
- automatic sprint cancellation at zero stamina, down, dodge, reset, or respawn;
- stable dodge input on touch, `LeftAlt`, and `B`/Circle through the Input Action
  System and fallback path;
- a thumb-sized dodge action, context-sensitive stamina rail, low-stamina text,
  cooldown text, and input-aware labels;
- a 0.9-second Rootling swipe windup with a locked ground zone, world label, and
  targeted HUD warning;
- server resolution for target presence, active state, impact area, line of
  sight, dodge window, damage, and down state;
- accepted/rejected combat-action and hit/evade/dodge analytics;
- a kill switch, presentation attributes, 13 new pure tests, Studio assertions,
  and built-place checks.

This foundation is expanded by the
[six-enemy Bramblewake roster increment](MILESTONE_3_BRAMBLEWAKE_ENEMIES.md).
Still not implemented across the wider combat roadmap:

- charged attacks, player parry, armor, weapon combos, or a general effect stack;
- simultaneous multi-enemy navigation/pathfinding, an elite, boss, or Blackout;
- latency compensation for aimed attacks or final combat balance;
- final character/enemy animations, audio, VFX, localization, or real-device
  evidence.

Stamina, dodge protection, damage, and enemy resolution cannot be purchased.

## Authoritative contracts

The client submits only `sprint enabled/disabled` or `dodge`. It never submits
stamina, speed, direction, cooldown, protection, target, hit, or damage.

```text
server combat state
  ├─ hold sprint → drain stamina → stop at zero
  ├─ release → wait 0.75s → regenerate
  └─ dodge request
       ├─ active + ready + stamina → spend 35, move, protect for 0.42s
       └─ otherwise → reject with bounded reason

Rootling finds active player
  → lock impact zone and target for 0.9s
  → target leaves/downed: cancel
  → target exits the zone or reaches cover: miss
  → target is inside active dodge window: dodge
  → otherwise: apply 24 server damage
```

`CombatState` owns deterministic resource timing. `EnemyAttackFlow` owns the
telegraph lifecycle independently of Roblox physics. Runtime attributes are
presentation only:

- `LastLightStamina`, `LastLightMaxStamina`, and `LastLightSprinting`;
- `LastLightDodging`, `LastLightDodgeActiveUntil`, and `LastLightDodgeReadyAt`.
- `LastLightDrowsy` and `LastLightDrowsyUntil`.

Editing these attributes must never change authoritative state.

## HUD direction

The implementation follows the
[Mobile Combat Stamina + Dodge report](https://www.lazyweb.com/report/lazyweb/4e46b6e2-7bef-4633-a7b5-ed7a872da2e8/?source=create).
Its mobile-game coverage was directional rather than a genre benchmark, so it
was used for hierarchy and occlusion guidance:

- stamina appears when combat, sprinting, recovery, or cooldown makes it useful;
- one 84-pixel dodge action sits beside the existing strike/context cluster;
- full, low, cooldown, and active states use text plus fill/shape and color;
- the Rootling warning pairs a locked world zone with explicit attack and dodge
  text;
- no action bar, modal tutorial, paid recovery prompt, or permanent town clutter
  was added.

At the minimum 0.78 UI scale, the 84-pixel dodge target remains above 65
equivalent pixels. Device evidence is still required for Roblox jump,
thumbstick, top-bar, safe-inset, and preferred-text interactions.

## Windows Studio journey

1. Run `npm test`.
2. Open `build/LastLightTest.rbxlx` in Roblox Studio.
3. Start one player and require `[Last Light] PASS FoundationIntegration`,
   build `0.10.0`, `services=12`, and no red errors.
4. Reach the authored night and hold RUN/Shift/left-stick click.
5. Confirm the stamina rail drains smoothly, speed returns to normal at zero,
   and regeneration begins only after release and the short delay.
6. Approach a Rootling until a ground zone and `ROOTLING SWIPE` warning appear.
7. Stay in the zone once. Confirm damage occurs only after the warning finishes.
8. Repeat and dodge during the warning. Confirm the character moves in its
   server-selected movement/facing direction and the attack applies no damage.
9. Repeat by walking outside the locked zone and by reaching solid cover.
   Confirm both resolve as misses.
10. Spend below 35 stamina. Confirm dodge disables, says `LOW`, and does not move
    or grant protection.
11. Reset, become downed, and respawn while sprinting/dodging. Confirm speed and
    stamina reset safely and no protection survives.
12. Repeat with touch, keyboard/mouse, controller, and live input switching.

## Exit and abuse gate

| Gate | Required evidence |
|---|---|
| Touch | DODGE remains at least 64 equivalent pixels and does not overlap movement, jump, STRIKE, context, or Roblox controls |
| Keyboard/mouse | `LeftAlt` dodges, `LeftShift` still holds sprint, mouse attack and `E` context remain independent |
| Controller | `B`/Circle dodges, left-stick click sprints, right trigger attacks, and live switching updates labels |
| Accessibility | zone, `ROOTLING SWIPE`, `DODGE`, time, stamina value, `LOW`, and cooldown remain understandable without color, motion, or audio |
| Authority | forged stamina, speed, direction, cooldown, protection, target, or damage values are never accepted |
| Rate | repeated dodge/sprint requests remain bounded; no remote or toast flood destabilizes the server |
| Timing | high/variable latency cannot skip the 0.9-second server windup or extend the 0.42-second protection window |
| Cover | moving outside the locked zone or behind solid cover misses; standing inside without protection hits once |
| Recovery | down, reset, respawn, disconnect, night end, and enemy death clear sprint/attack state and visuals |
| Multiplayer | each targeted player sees only their warning; other players can still strike the Rootling during windup |
| Performance | eight-player stamina replication, one telegraph raycast, marker, and 10 Hz local countdown stay inside frame/network budgets |
| Analytics | combat action, acceptance, rejection reason, stamina, enemy result, and enemy ID appear without profile contents |

Do not mark this increment device-tested or Milestone 3 complete from headless
validation alone.
