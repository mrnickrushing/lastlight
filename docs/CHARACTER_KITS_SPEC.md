# Wayfarer character kits — design and monetization spec

The owner's ask: purchasable characters, chosen where you pick party size,
with different weapons and abilities. This spec is the version of that which
can ship on Roblox and inside this project's own rules — AGENTS.md forbids
selling combat power, and platform policy plus the monetization document
forbid paid stat advantages dressed as content. The design below sells
identity hard and keeps power earned, which is also what protects long-term
revenue: paid-power games bleed their free players, and free players are the
audience paid players buy identity in front of.

## What a character kit is

A kit is a complete playable identity purchased once and equipped at the
departure lodge, at the same moment a party size is chosen:

- **Silhouette and outfit** — a full original character look (rig-compatible
  layered clothing, distinct palette, readable at gameplay distance) that
  replaces the player's default appearance while playing Last Light.
- **Weapon and tool skins** — the kit's own art for whatever the player has
  actually earned: the same axe hits the same numbers, wrapped in the kit's
  iron, bone, or foxglass look.
- **An arrival effect and departure stance** — the moment the platform
  launches, this is who the party sees standing beside them.
- **A voice of toasts** — kit-flavored wording for common toasts (gathering,
  banking, revives). Same information, different character.
- **Two emotes and a title.**

## What a kit is not

- No stat, damage, range, cooldown, health, stamina, or drop-rate change.
- No profession, mastery rank, or specialization unlock. Abilities remain
  earned in play, free, for everyone, always.
- No expedition, region, chapter, or story access.
- Nothing consumable, nothing random, no kit "upgrades".

"Different weapons and abilities" is delivered as *earned loadout identity*:
each kit ships with a recommended starter tool and profession pre-selected
(both freely changeable, both free) and its own visual motif for the four
profession abilities — the Warden guard in the Ashen kit raises charred
stakes, in the Foxglass kit pale glass roots. Same numbers, same server
effects, different theatre.

## Launch roster (three kits, all original)

| Kit | Identity | Recommended kit | Robux |
|---|---|---|---:|
| **The Cindersworn** | a forge-scarred survivor of Cinderfall's fall | hammer · Engineer | 399 |
| **The Foxglass Courier** | a Mireglass runner who outpaced her own reflection | torch · Scout | 399 |
| **The Thornwarden** | a Bramblewake keeper who never left after the evacuation | axe · Warden | 499 |

A fourth slot stays open for the first earned kit — completing the Memory
Archive should eventually mint a kit no money can buy, because the catalog
needs at least one visible proof that play outranks purchase.

## Where it lives

The departure lodge's character hut already presents four profession stands.
The kits take the opposite wall: three preview stands showing the full
character, tap to preview on your own avatar, buy with Robux through the
platform prompt, equip/unequip freely afterward. Kit state is a server-owned
entitlement on the profile (`commerce.ownedKits`, receipt-processed,
idempotent, restore-safe) — the client requests display state and never grants
anything.

## Sequencing

1. Entitlement plumbing and one kit end-to-end (appearance swap, weapon skins,
   arrival effect) behind a feature flag, store hidden.
2. Preview stands in the lodge and the purchase flow, canary-tested with a
   test product ID.
3. Remaining kits, ability motifs, toasts, emotes.
4. Storefront copy review against MONETIZATION_LIVEOPS_ANALYTICS: price shown
   in Robux, permanence stated, "cosmetic — abilities are earned in play" on
   every card.

Analytics: `store_view`, `product_detail_view`, `purchase_prompt`,
`receipt_result`, `cosmetic_equipped`, all already in the taxonomy.

## Open questions for the owner

- Price points above are placeholders for review against comparable Roblox
  cosmetics; approve or adjust before configuration.
- Whether kits appear on other players in town before purchase (social proof)
  or only after — recommend yes, visible everywhere, it is the advertisement.
- Whether the earned Archive kit ships at kit launch (recommended) or after.
