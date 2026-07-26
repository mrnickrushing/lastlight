# Monetization, live operations, and analytics

## Commercial principle

Last Light sells identity, creativity, celebration, and optional social hosting.
It does not sell strength, survival, luck, speed through intentional frustration,
or restoration of progress the game threatened to take away.

The free game includes the complete launch story, every region, every profession,
all functional buildings, all companions and their utility, matchmaking/parties,
and the ability to reach every ending.

## Launch catalog

### Permanent passes

Candidates require pricing research and platform review before configuration:

- **Decorator's Toolkit:** additional saved decoration layouts, advanced placement
  tools, and exclusive cosmetic building pieces. It does not increase functional
  plot capacity or defense strength.
- **Wardrobe Trunk:** additional saved outfits and appearance presets. No gear stats.
- **Lantern Atelier:** premium lantern shells, arrival effects, and photo-mode
  frames with low-effects alternatives.
- **Private Town Controls:** expanded private-server settings for invited players,
  such as phase pause in non-reward practice, seed selection among already
  discovered seeds, and cinematic tools. Reward-bearing modifiers remain
  server-defined and fair.

### Direct cosmetic products

- resident-inspired outfit sets;
- profession mastery appearance sets;
- weapon and tool skins;
- companion skins;
- emote and celebration packs;
- district facade themes;
- furniture/decor bundles;
- banners, signs, garden sets, and arrival effects.

Every product shows a real preview, exact Robux price, permanence, eligible
objects, effect intensity, and owned state.

### Seasonal journal

A seasonal journal is allowed only if:

- its free path contains meaningful cosmetics;
- paid rewards are cosmetic;
- gameplay tasks are varied and respect ordinary play;
- progress does not require daily attendance;
- players can buy after earning and receive already-earned premium rewards;
- the end date is clear;
- key story content is not exclusive;
- selected rewards return through an announced archive path;
- no random reward or paid tier skip sells power.

Do not launch the journal until core retention is healthy without it.

## Explicitly prohibited

- paid damage, health, stamina, profession XP, drop rate, or structure strength;
- paid revive, checkpoint, or loss protection;
- random paid eggs, crates, spins, or mystery bundles;
- energy systems that stop normal play;
- paid access to launch regions or endings;
- fake countdowns, fake scarcity, or continuously resetting “sales”;
- confusing premium currency conversion;
- construction delays created to sell completion;
- popups during downed, defeat, urgent defense, or first-session teaching;
- child-directed pressure such as “your town will suffer if you leave.”

## Commerce implementation

### Entitlements

Game passes and durable products are represented as server-owned entitlements.
The client requests display state; it never grants benefits.

### Developer product receipts

If any repeatable developer product is introduced:

1. `ProcessReceipt` is the only grant authority.
2. Purchase ID becomes the idempotency key.
3. Grant checks the processed ledger and durable ownership.
4. The item is applied exactly once.
5. The receipt returns purchase granted only after safe durable processing.
6. Retry, server crash, profile lock, full inventory, and disconnect are tested.

Cosmetic inventory has a mailbox/pending-delivery path so capacity cannot lose a
purchase.

### Store safety

- Offers have server-configured start/end and kill switch.
- Price and product info come from platform product information, not trusted
  client constants.
- Regional/platform policy and age suitability are reviewed before launch.
- Purchase analytics separates prompt, platform completion, receipt grant, and
  equip/use.
- Refund/removal and support procedures are documented before selling.

## Economy

### Currencies

- **Town Marks:** earned common currency for crafting services, cosmetic basics,
  and town operations.
- **Memory Threads:** earned mastery/story currency for runes and prestige
  cosmetics; bounded sources and sinks.
- **Robux:** shown directly for premium products. No premium currency at launch.

Materials are resources, not currency. Every source and sink has a content ID.

### Economy goals

- A first-session player crafts something meaningful without grinding.
- A returning player has useful goals across town, profession, relationships,
  cosmetics, and mysteries.
- Common materials remain relevant through repairs, consumables, and decoration.
- Rare materials have deterministic earned sources in addition to low-chance
  bonuses.
- No required recipe depends only on a rare random drop.
- Group play does not multiply inflation; contribution rewards are normalized.

### Economy dashboards

Track by progression segment:

- currency/source and sink volume;
- median balances and distribution tails;
- material creation, consumption, and hoarding;
- recipe craft and abandon rates;
- gear family usage and success;
- town upgrade time and bottlenecks;
- trade volume, value imbalance, reversals, and suspicious clusters;
- purchase conversion, duplicate receipt attempts, pending grants, and equip rate.

Alerts are defined before launch for sudden creation spikes, sink collapse,
negative balance, impossible recipe volume, duplicated receipts, and trade rings.

## Ethical retention model

### Return reasons

- visible town transformation;
- resident relationship continuation;
- profession mastery and new techniques;
- new route/POI combinations;
- weekly regional weather that changes decisions;
- friend invitations and shared recovery;
- new story chapters and mysteries;
- creative town/character expression.

### Cadence

- **Every session:** complete one story-shaped day/night loop.
- **Weekly:** one world condition and community restoration target.
- **Monthly:** quality/content update or new event composition.
- **Seasonal:** additive narrative journal, cosmetic collection, and one systemic
  modifier set.
- **Major chapter:** new region or substantial postgame addition only after
  production and performance gates.

No cadence requires a player to log in on a particular day to preserve progress.

## Live-event architecture

An event is configuration plus versioned content:

- ID, start, end, eligibility, and local-time display;
- feature flag and kill switch;
- quest/encounter/offer references;
- reward definitions and idempotency keys;
- fallback if content fails;
- analytics exposure event;
- post-event conversion and archive rules;
- performance budget and device-tier variants;
- moderation and support notes.

Events never patch core save data ad hoc. Event progress lives in a versioned
domain that can be archived or migrated.

## Analytics event taxonomy

### Acquisition and join

- `session_join_started`
- `session_join_stage`
- `session_interactive`
- `session_join_failed`
- `session_reconnect_result`
- `teleport_attempted`
- `teleport_result`

### Onboarding

- `tutorial_step_started`
- `tutorial_step_completed`
- `tutorial_step_failed`
- `tutorial_skipped`
- `first_gather`
- `first_rescue`
- `first_build`
- `first_night_started`
- `first_night_result`
- `first_reveal_seen`

### Core play

- `phase_started`
- `phase_completed`
- `expedition_started`
- `expedition_objective`
- `expedition_extracted`
- `expedition_failed`
- `player_downed`
- `player_revived`
- `night_breach`
- `night_result`
- `blackout_result`
- `boss_phase`
- `boss_result`

### Progression

- `town_project_started`
- `town_project_completed`
- `recipe_discovered`
- `craft_result`
- `profession_rank`
- `resident_bond_rank`
- `quest_state`
- `chapter_completed`
- `ending_selected`

### Social

- `party_invite`
- `party_join`
- `party_session_result`
- `town_visit`
- `ping_used`
- `trade_started`
- `trade_result`

### Commerce

- `store_view`
- `product_detail_view`
- `purchase_prompt`
- `purchase_platform_result`
- `receipt_result`
- `cosmetic_equipped`

### Quality and security

- `save_result`
- `migration_result`
- `generator_validation`
- `client_performance_sample`
- `remote_rejected`
- `suspicious_action`
- `feature_flag_exposure`
- `content_kill_switch`

Events use stable names, documented properties, privacy review, sampling policy,
and schema version. Do not log arbitrary payloads or raw personal communication.

## KPIs and guardrails

### Primary health metrics

- first interactive time;
- onboarding completion;
- first night completion;
- D1, D7, and D30 retention;
- meaningful session completion, not raw idle time;
- percentage of sessions with friend/party play;
- expedition extraction and night success by progression;
- crash/disconnect/save failure rate;
- baseline-device FPS and memory;
- payer conversion and cosmetic equip/use.

### Experience guardrails

- store exposure during onboarding and failure;
- defeat-to-purchase-prompt adjacency must remain zero;
- difficulty failure concentration;
- solo versus group completion gap;
- assisted-mode completion and reward parity;
- profession pick and win-rate concentration;
- repeated content/seed rate;
- report/block and trade dispute rates;
- purchase regret/support rate.

Revenue never overrides a guardrail without explicit product review.

## Experiments

Allowed experiments:

- tutorial ordering;
- wording and placement of non-purchase objectives;
- HUD density presets;
- expedition choice framing;
- party invitation timing after demonstrated value;
- reward feedback presentation;
- store organization after a player intentionally opens it.

Forbidden experiments:

- changing hidden difficulty to drive purchases;
- exposing children to more pressure;
- fake scarcity or confusing price anchors;
- withholding already-earned rewards;
- paid versus unpaid matchmaking or success manipulation.

Every experiment declares hypothesis, primary metric, guardrails, sample unit,
assignment persistence, minimum exposure, stop rule, and rollback. Analyze by
platform, new/returning, solo/group, and progression where sample size permits.

## Launch and live-ops ownership

Before public launch, assign named ownership for:

- economy and commerce;
- events and content flags;
- analytics and experiment quality;
- moderation and support;
- save/teleport incidents;
- client/server performance;
- communications and patch notes.

If the team is too small to staff a live system safely, reduce cadence rather than
automate unreviewed content.

