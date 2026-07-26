# UI design direction

## Durable research snapshot

This file preserves the actionable results of the Last Light mobile gameplay-HUD
research generated on 2026-07-25 PDT (2026-07-26 UTC). The
[hosted report](https://www.lazyweb.com/report/lazyweb/a5059523-0d43-4386-b0f5-bda12ca3d7ea/?source=create)
contains the full source exploration; this committed snapshot remains usable if
that external page changes or disappears.

## Chosen system

The default is a **context-sensitive survival HUD**:

- show phase/time, health/stamina, hotbar, urgent squad state, and one dominant
  current action;
- reveal objective, resource, defense, companion, and status information only
  when it becomes relevant;
- keep safe-town play calm and visually sparse;
- use icon plus text or shape plus color for every critical state;
- never cover Roblox's menu area, touch thumb zones, threats, or the current
  interaction target;
- collapse rapid pickups and repeated alerts instead of stacking clutter.

The **compact corner HUD** is the stable low-effects/accessibility alternative.
The **living-world HUD** is an event layer reserved for Blackouts, bosses, and
major breaches; it must always retain explicit text/icon backups.

## Visual targets

### Default context-sensitive survival HUD

![Context-sensitive survival HUD target](assets/hud/prototype-context-survival-hud.webp)

### Compact low-effects and accessibility fallback

![Compact corner HUD target](assets/hud/prototype-compact-corner-hud.webp)

### Blackout and boss event layer

![Living-world event HUD target](assets/hud/prototype-living-world-hud.webp)

These generated images are composition targets, not shippable UI assets. Their
illustrative labels, icons, and imagery must be rebuilt with production-safe
Roblox UI, tested action bindings, localized copy, and original final assets.

## Implementation checks

- Test phone, tablet, desktop, and controller layouts from the same information
  hierarchy and action IDs.
- Derive prompts from the active binding and `PreferredInput`.
- Respect safe insets and Roblox reserved controls at every supported aspect ratio.
- Verify default, compact, reduced-motion, reduced-flash, and low-effects modes.
- Test daylight, dusk, night, Blackout, boss, revive, defense, inventory-full,
  reconnect, and store-disabled states.
- Make the current primary action understandable in motion without relying on
  color, audio, or a small icon alone.
