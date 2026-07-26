# UX, mobile, and accessibility specification

## Direction

Last Light is designed for landscape mobile first, then adapted to keyboard/mouse
and controller without changing the underlying gameplay verbs.

The visual UI recommendation and local reference images are preserved in
[UI_DESIGN_DIRECTION.md](UI_DESIGN_DIRECTION.md). The
[hosted gameplay HUD report](https://www.lazyweb.com/report/lazyweb/a5059523-0d43-4386-b0f5-bda12ca3d7ea/?source=create)
remains linked as research provenance:

1. **Default:** context-sensitive survival HUD with one dominant current action.
2. **Fallback:** compact corner HUD for low effects, accessibility, and players
   who prefer stable explicit controls.
3. **Event layer:** living-world signals used only for Blackouts, bosses, and
   major breaches, always with text/icon backups.

The player-down state uses the
[Co-op Rescue HUD report](https://www.lazyweb.com/report/lazyweb/01fb79d9-741c-4685-8786-831be744e372/?source=create)
as hierarchy guidance: a non-modal bottom rail for self state, one compact ally
alert, and a world-bound contextual revive target.

The combat-mobility state uses the
[Mobile Combat Stamina + Dodge report](https://www.lazyweb.com/report/lazyweb/4e46b6e2-7bef-4633-a7b5-ed7a872da2e8/?source=create)
as hierarchy guidance: context-sensitive stamina, one thumb-safe dodge action,
and a targeted text warning paired with a world-space impact shape.

The profession state uses the
[Profession Selector + Ability HUD report](https://www.lazyweb.com/report/lazyweb/73595230-6584-431c-8d84-c7eb06fdeaa5/?source=create)
as hierarchy guidance: role selection is available only in safe town through a
four-card controller-selectable layer, while one labeled cooldown action remains
visible during play without replacing urgent survival information.

The Warden Stag state uses the
[Warden Stag Mobile Boss Layer report](https://www.lazyweb.com/report/lazyweb/d5a79e5a-8f10-46e0-b0ed-8e6e09b2dccb/?source=create)
as hierarchy guidance: one contextual rail reports exact phase and health,
living-root progress, antler consequence, and outcome, while the existing
world-space shape plus targeted warning card owns immediate attack urgency.

The Bramblewake Blackout state uses the
[Bramblewake Mobile Blackout Event Layer report](https://www.lazyweb.com/report/lazyweb/558b7278-8455-4639-bf62-bd4ebb97a034/?source=create)
as hierarchy guidance: a compact top-center event rail reports the written
stage, target clock or overtime, relay progress, carried-fire expiry,
elite/boss transition, and chapter vote/result while the existing encounter and
threat rails retain their more immediate jobs.

The design follows current Roblox guidance for
[mobile input](https://create.roblox.com/docs/input/mobile),
[reserved mobile control zones](https://create.roblox.com/docs/building-and-visuals/ui/positioning-and-sizing-guiobjects),
[accessibility](https://create.roblox.com/docs/production/publishing/accessibility),
and [safe areas](https://create.roblox.com/docs/reference/engine/enums/SafeAreaCompatibility).

## HUD information hierarchy

### Always visible

- current phase and time until transition;
- personal health and stamina;
- current hotbar selection;
- one primary contextual action;
- urgent squad danger;
- input-relevant movement/jump controls supplied by Roblox or the game.

### Contextually visible

- objective summary when changed or intentionally expanded;
- resources after collection and while building/crafting;
- town integrity and breached lane during defense;
- companion command while the companion has a valid action;
- interaction hold progress;
- directional threat or ally-down marker;
- status-effect explanation on application.

### Hidden until opened

- complete inventory;
- crafting recipe book;
- town build catalog;
- profession tree;
- map and codex;
- party and social details;
- cosmetic store;
- settings.

No gameplay-critical state lives only inside a full-screen menu.

## Landscape layout

### Safe zones

- Respect `ScreenInsets` and device cutouts; do not use legacy fullscreen
  extension as the primary strategy.
- Treat the top-left Roblox menu area as occupied.
- Treat bottom-left as movement territory and bottom-right as jump/action territory.
- Keep persistent non-control information away from both thumb centers.
- Do not place tiny buttons at extreme screen corners.
- Test dynamic thumbstick, classic thumbstick, tap-to-move, and connected
  controller on a touch device.

### Touch targets

- Primary gameplay actions target at least 64×64 logical pixels on the baseline
  phone; critical hold actions target larger.
- Secondary icon buttons target at least 48×48 logical pixels.
- Spacing prevents adjacent-action mis-taps under motion.
- Destructive actions never sit adjacent to the common confirm action without
  separation and confirmation.
- Hold interactions have progress, cancellation feedback, and an optional toggle
  alternative for accessibility where it cannot create competitive advantage.

### Thumb reach

- Movement remains bottom-left.
- Jump remains bottom-right.
- Context action sits above/inside comfortable right-thumb reach without
  overlapping jump.
- Sprint defaults to hold/toggle choice near movement or automatic sprint option.
- Hotbar selection supports tap, swipe, and optional compact radial access.
- Full menus pause local input intent but do not pause a multiplayer server.

## Cross-platform actions

All rows bind to stable Roblox Input Action System action IDs rather than
platform-specific gameplay code. The required contract is:
`action_sprint`, `action_context`, `action_primary`, `action_alternate`,
`action_dodge`, `action_profession`, `action_companion`, `action_ping`, and
`action_hotbar`. Touch buttons, keyboard/mouse keys, and controller inputs are
bindings to those same IDs. UI labels, glyphs, button visibility, and the active
binding set derive from the action binding and `PreferredInput`; no prompt
hardcodes a key name.

| Action | Touch | Keyboard/mouse | Controller |
|---|---|---|---|
| Sprint | hold/toggle button or auto | Shift, remappable | stick click/bumper option |
| Context action | large labeled button | E, remappable | X/Square |
| Primary | right action button | mouse 1 | right trigger |
| Alternate/guard | secondary action | mouse 2 | left trigger |
| Dodge | action button | Left Alt, remappable | B/Circle |
| Profession ability | labeled cooldown button | Q | bumper |
| Profession selector | labeled safe-town pill | P | D-pad Up |
| Companion command | contextual small radial | C | D-pad |
| Ping | tap marker/radial | middle mouse/G | D-pad |
| Hotbar | tap/swipe | 1–5/wheel | bumpers/D-pad |

Final bindings are tested and may change. Prompts come from action bindings, never
hardcoded text. If preferred input changes while playing, prompts and touch
visibility update without interrupting the action.

## Screen inventory

### Loading and reconnect

- Show `Connecting`, `Loading your town`, `Preparing nearby area`, and `Ready`.
- Never say the whole world must finish building.
- After a bounded threshold, show a plain recovery message and retry/cancel path.
- Reconnect shows whether the player will return to expedition, town, or safe lantern.
- Do not display fake percentages when stage progress is not measurable.

### First-session onboarding

- Teach one action at a time in play.
- Detect current input.
- Place instruction near the relevant world object without covering threats.
- Allow skip only after the essential safe controls are demonstrated.
- Archive every tutorial and offer practice dummies.
- Never require reading a long modal before movement.

### Gameplay HUD

- Phase arc at top-center below safe inset.
- Squad summary uses compact portraits/sigils; expand on tap.
- Resource toast consolidates rapid pickups.
- Objective card has collapsed, expanded, and hidden settings.
- Primary action uses verb plus icon: `Repair wall`, not only a hammer.
- Cooldowns show numeric/shape progress in addition to desaturation.
- Ally-down warning states distance, direction, and timer.

### Inventory

- Default phone view uses category tabs and large grid/list toggle.
- Selecting an item opens details without losing scroll position.
- Compare shows changed properties with symbols and plain language.
- Multi-select and sort are optional advanced tools, not tutorial requirements.
- Capacity problems provide an exact resolution: deposit, salvage, swap, or cancel.
- Premium cosmetics never appear as stronger stats.

### Crafting

- Start with craftable and pinned recipes.
- Recipe detail shows function before flavor.
- Missing ingredients link to discovered sources.
- Batch amount uses stepper plus hold, never a narrow slider only.
- Server transaction progress is cancellable until ingredients are committed.
- A failed transaction states whether materials were consumed; normally they are not.

### Town build mode

- Uses authored plot anchors with a clear valid footprint.
- Camera supports pinch zoom, one-finger orbit away from controls, and reset.
- Placement has rotate, variant, confirm, and cancel.
- Validity uses shape/pattern/text in addition to green/red.
- Visitors cannot modify without explicit permission.
- Decoration density meter warns before performance caps.

### Map and expedition planning

- Region map is visual and list-accessible.
- Each contract shows session length, hazards, known resources, story relevance,
  difficulty, party fit, and extraction rule.
- Locked content explains the earned prerequisite.
- Risk modifiers disclose exact effects and rewards.
- Party ready state does not trap players in a countdown.

### Profession and loadout

- Show role fantasy and play example before the tree.
- Nodes state mechanical effect exactly.
- Respec is free in town.
- Invalid loadout after a balance change receives automatic safe fallback and a
  clear explanation.

### Resident and quest screens

- Resident card shows location, current job, condition, bond, active request, and
  recent town event.
- Dialogue recap is accessible at any time.
- Quest abandon warns only when it resets an authored state; contracts can be
  replaced freely.
- Waypoints can be reduced or disabled without making critical paths unreadable.

### Store

- Store is never shown during downed state, defeat summary, or urgent defense.
- Every card states whether the item is cosmetic, consumable, permanent, or
  private-server access.
- Robux price is primary; no confusing custom premium currency at launch.
- Preview cosmetics on the player's current avatar/town where practical.
- Confirm exact item and price using Roblox purchase flow.
- Owned items say `Owned`; unavailable items say why.
- Receipt delay shows `Purchase pending` and restores safely after reconnect.
- No randomized paid product.

### Settings

Categories:

- controls and sprint behavior;
- camera sensitivity and shake;
- HUD scale, layout preset, objective visibility, and opacity;
- text size preference support and captions;
- color/shape assistance;
- reduced motion, reduced flashes, low-effects mode;
- master, music, effects, ambience, and dialogue volume;
- damage numbers and combat feedback;
- privacy/social permissions and trade requests;
- tutorial replay and support.

Settings are stored per player with a version and safe defaults.

## Responsive rules

Test at minimum:

- small 16:9 Android phone;
- tall/notched phone in both landscape orientations;
- standard iPhone;
- small tablet;
- large tablet;
- 16:9 desktop;
- ultrawide desktop;
- console television safe area;
- touch device with connected gamepad.

Use scale-based positioning for overall layout plus constraints for readable
minimums and maximums. Avoid one universal `UIScale` that makes text unreadably
small. Panels reflow:

- phone: one primary column or sheet;
- tablet: master/detail when it reduces taps;
- desktop: two-pane detail and hover supplements;
- console: focus graph with clear selected state and no cursor-only action.

## Text and localization

- Support Roblox preferred text size where possible; do not defeat it with
  unnecessary `TextScaled`.
- Use automatic sizing/wrapping with tested maximums.
- No required gameplay label below the approved baseline minimum.
- Allow at least 35% expansion for localized UI; more for German and Russian
  review, and support non-Latin font coverage before promising languages.
- Do not put critical text inside raster images.
- Timers and quantities use locale-aware formatting when available.
- Avoid slang in mechanical instructions.
- Name icons with accessible/tool-tip text.

## Color, contrast, and non-reliance

- Text and interactive controls require documented contrast against their actual
  dynamic backgrounds, using scrims when necessary.
- Friendly, hostile, interactable, quest, and hazard states each have unique
  silhouette/icon/animation in addition to color.
- Rare-item effects cannot resemble enemy telegraphs.
- Night readability is tested at minimum and maximum graphics quality.
- Damage feedback cannot be only a red full-screen wash.

## Motion, flashes, and camera

- Reduced motion disables large UI sweeps, repeated scale pulses, parallax, and
  nonessential camera movement.
- Camera shake has Off/Low/Full and never disrupts required aiming.
- Flashes are intensity- and frequency-capped; lightning has reduced-flash mode.
- Critical direction indicators persist long enough to read without rapid blinking.
- Motion never changes a button's hit target during confirmation.

## Sound and captions

- Every audio-only danger has a visual indicator.
- Subtitle/caption system distinguishes speaker, direction when important, and
  non-speech critical sounds.
- Music communicates phase but phase is also visible.
- Haptics reinforce impact and UI but are never required.
- The game remains playable muted.

## Assisted difficulty

Options that can be changed without stigma:

- extended telegraph timing;
- stronger objective trails;
- hold instead of repeated tap;
- simplified camera;
- reduced simultaneous crisis count in personal/solo instances;
- auto-sprint;
- aim assistance within fair Roblox norms;
- practice without loss.

Assists do not block story, achievements, cosmetics, or ordinary rewards.
Challenge leaderboards separate declared modifiers where necessary.

## UX acceptance tests

A screen cannot ship until:

- all actions work with touch, mouse/keyboard, and controller;
- focus order and back/cancel behavior are correct;
- no required control overlaps system insets or Roblox reserved zones;
- longest supported text does not clip at largest supported preferred text size;
- low vision/color-blind simulation retains state distinctions;
- muted and reduced-motion play retains critical information;
- network delay, rejection, duplicate request, and reconnect states are understandable;
- opening/closing the screen does not duplicate connections or leak memory;
- the baseline phone maintains performance with the screen open.
