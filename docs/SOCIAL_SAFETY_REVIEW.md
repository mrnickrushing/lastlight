# Social safety review

Milestone 11's exit gate asks that "social systems pass privacy and abuse
review." This is the artifact that review reads: **every way one player can
reach another player in Last Light, what bounds it, and what a block does to
it.** The review itself is a human reading this; what code can do is make the
list impossible to be quietly wrong, and `SocialSafety.spec` does that — every
channel here has a marked path in the source, every marked path in the source
has a row here, and **neither list can grow alone**.

Two facts frame everything below.

**There is no free-text channel in this game.** A player cannot compose a
string that reaches another player. The only thing that travels is a phrase id
from a closed catalog of twenty-four, and `QuickChat.spec` asserts that over
the source rather than claiming it here: it walks every file in `src` for the
entry points a text channel would have to use — `FilterStringAsync`,
`FilterStringForBroadcast`, a `TextBox`, a `TextChannel`, `SendAsync`,
`SetCore` — and fails if any appears. Moderation is therefore structural rather
than procedural. There is nothing to filter because there is nothing to
compose.

**One block reader, consulted by everything.** Roblox's own answer, through
`Chat:CanUsersChatAsync`, is the authority. It is called in exactly one place
in the entire codebase — `SocialService` — and every other channel asks
`SocialService` rather than the platform. `QuickChat.spec` pins that call count
at one. A suppression rule with two homes is a rule that stops being true in
one of them.

## The channels

`kind` is the column that matters to a reviewer. **game** means this repository
implements the channel and bounds it in code; **platform** means Roblox owns
it, this game neither implements nor extends it, and the controls are the
platform's own (a Creator Dashboard setting, or the report and block menus
every Roblox client carries).

| id | kind | What crosses | What bounds it | What a block does |
|---|---|---|---|---|
| `quick_chat_phrase` | game | One phrase id from a fixed catalog of 24, resolved to its text server-side | Closed vocabulary; own rate budget (3 in hand, ~1 per 2s); action-remote transport contract | The blocker never receives the phrase — filtered per recipient where the snapshot is built |
| `quick_chat_ping` | game | A marker at the sender's own position, plus the phrase | Position is read from the sender's character server-side and is not in the payload; marker life 6–30s by kind; 400-stud reach; one marker per speaker | The blocker never receives the ping, in the log or as a marker |
| `party_invite` | game | An offer of a seat, to whoever is standing on the departure platform | The press names nobody — it offers to whoever the server can see on the dais, so it cannot be forged into naming a stranger | A blocked player is skipped, silently and in both directions |
| `party_roster` | game | Display names of party members, and their boarding order | Membership requires an accepted invitation; a roster carries user IDs and display names, never text a player wrote | Nothing directly: you cannot be invited by somebody you blocked, so you cannot end up in their party by their action |
| `town_visit_adoption` | game | An arriving player's saved town record merged into the host's town | Upward-only by `TownPermissions`; further gated by the host's visit policy; one call site, spec-pinned | Not block-scoped — governed by the town's own gate (`open / friends / invited / closed`) |
| `town_showcase` | game | The host's town record — tier, night, integrity — read by a visitor | Attached only for a host or an admitted visitor; a pending or refused role reads nothing | Not block-scoped — same gate as adoption |
| `rejoin_ticket` | game | A reserved-server access code, held by the server | Never leaves the server: `PartySession.publicTicket` builds the client's half by construction | Not applicable — it reaches no player but the one it was issued to |
| `admin_command` | game | Typed text from a two-name roster of user IDs | Bounded parser, bounded arguments, a feature flag that is a complete off switch including the roster | Not applicable — carries commands, never messages, and nothing typed is shown to another player |
| `platform_chat` | platform | Roblox's own text chat, if the experience has it enabled | Roblox's text filtering, age-based chat settings, and moderation | Roblox's block list suppresses it, by the platform's own machinery |
| `platform_report` | platform | A report about a player, raised through the Roblox client's own menu | Roblox's moderation pipeline | Not applicable — this is the channel a block is requested through |

## Reporting

**This game does not implement a report flow, deliberately.** Every Roblox
client carries a report menu that reaches Roblox's moderation team with the
experience, the reported user and the reporter's account attached. A
game-authored report button would either duplicate that — a second inbox
nobody staffs — or, worse, look like it did something it did not. The honest
position is that reporting is the platform's, and this document is the record
of that decision so it is not re-litigated.

The same applies to blocking. Roblox's block list is the block list; this game
reads it and obeys it. There is no in-game block, because a second list would
be a list a player has to maintain twice and a list that does not travel with
them to any other experience.

## What a reviewer should check

1. **That the table above is complete.** The spec proves the doc and the code
   agree with each other; it cannot prove that a channel exists which nobody
   has written down anywhere. That judgement is the review.
2. **That "no free text" is still true.** `QuickChat.spec` fails the build if
   it stops being. Read the phrase list itself — twenty-four phrases chosen to
   be useful on a night — and ask whether any of them can be aimed at a person
   in a way that reads as harassment. They are callouts, directions, requests
   and courtesies; none of them names anybody.
3. **That the rate budget is civil rather than merely anti-macro.** Three calls
   in hand and roughly one every two seconds is deliberately slow. It lives in
   `Config` so a tuning pass is not a rebuild.
4. **That a block actually suppresses.** The pure rule is spec-covered in both
   directions and over both the record and the markers. The platform round trip
   itself — `Chat:CanUsersChatAsync` returning false for a real blocked pair —
   is owner-gated: it needs two accounts and a real block, and Studio cannot
   reach the endpoint.

## Owner-gated, and why

- **The privacy and abuse review itself.** This document is the input; a human
  reading it is the gate.
- **A real block between two real accounts**, end to end. Everything up to the
  platform's answer is covered by specs; the answer is not.
- **Whether Roblox's own text chat is enabled for the experience.** That is a
  Creator Dashboard setting, not a fact about this repository, and it is the
  single largest social-surface decision left. If it is on, `platform_chat`
  becomes the widest channel in the game by a long way — everything this
  repository implements is a closed vocabulary, and that would not be.
- **Age and content disclosures**, which M14 already lists.
