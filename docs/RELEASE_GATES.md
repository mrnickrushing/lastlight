# Release gates

## Purpose

These are Last Light's initial numeric closed-beta and staged-launch gates. They
are shared by production, QA, analytics, and operations so a release decision
cannot depend on vague terms such as “healthy enough.”

Thresholds may change only through a dated entry in [DECISIONS.md](DECISIONS.md)
made before examining the candidate's results. A team may always stop a release
for a newly discovered safety, policy, data, or player-harm risk.

## Measurement contract

- Use a rolling 72-hour window for every promotion decision.
- Closed beta needs at least 1,000 interactive new-player sessions and 250
  D7-eligible new players.
- Each advertised platform class—phone, tablet, desktop, and console—needs at
  least 100 interactive sessions in the window.
- Each supported device/performance segment needs at least 50 first-session
  samples. A segment below its sample minimum cannot be promoted more broadly.
- D1 and D7 denominator is eligible new players whose observation window has
  elapsed; rejoin attempts and test accounts are excluded.
- Operational rates use authoritative server events. Client telemetry is
  diagnostic and cannot hide a server failure.
- Platform class and device/performance segment are labels on the session, not
  gates of their own. `interactive_session` and `session_ended` carry them, and
  every other gate is sliced by joining a player's session to it. The platform
  class is the one fact in this list a server cannot see for itself — it sees a
  userId and a connection, not a screen — so the client says which of the four
  it is on its first frame, and nothing in the game ever reads the answer for
  anything but a label.

## What emits each gate

Every threshold in this document names a rate, and a rate needs a numerator and
a denominator that something actually produces. So each gate below carries the
event it is read from, in a column, and `GateMetrics.spec` holds the two lists
against each other in both directions: **a threshold written down with no
emitter fails, and an emitter that stops being called fails.** Neither list may
grow alone.

That check exists because of the failure this document is least able to detect
on its own. A dashboard reading zero and a dashboard reading *nothing* look
identical to the person approving a release — the first says the gate passed and
the second says nobody measured it, and the release goes out either way. A gate
nobody measures is a gate nobody can fail.

Two gates are marked `review` rather than naming an event, and that is a
statement rather than a gap. A blocker defect on the launch path is a triage
decision made by people reading QA_RELEASE_PLAN.md, and a platform-policy or
player-safety failure arrives through Roblox's own moderation. Nothing this game
can emit produces either number, and an event invented to stand in for one would
be a gate passing on telemetry that measures something else.

Operational events are server events, as the measurement contract requires. Each
carries the dimensions its per-segment threshold is read on: the session pair —
`interactive_session` and `session_ended` — carries the platform class and the
device/performance segment, and every other gate is sliced by joining a player's
session to it.

## Zero-tolerance gates

Every value below must remain zero:

| Must remain zero | Emitted by |
|---|---|
| Confirmed save loss or unrecoverable save corruption | `save_loss` |
| Duplicate purchase grants or a completed receipt permanently missing its grant | `purchase_loss` |
| Blocker or critical defects on the supported launch path | review |
| Impossible critical-path expedition seeds in the candidate suite or live cohort | `generator_fallback` |
| Unauthorized economy, entitlement, admin, or progression mutation | `unauthorized_mutation` |
| Critical platform-policy or player-safety failure | review |

Any confirmed zero-tolerance event stops promotion and triggers rollback,
kill-switch activation, or cohort isolation immediately.

Two of these are worth reading carefully, because what they can and cannot see
is not obvious. `unauthorized_mutation` counts refused attempts, not successful
ones: a mutation this server let through is by definition one it did not notice,
so nothing can emit it. What a refusal rate gives is the earlier signal — an
exploit found is an exploit probed for first. And an impossible seed is caught
here only when the generator's own validation catches it and falls back; a seed
that validates and is still untraversable is the other half, and that half is
M12 wave C's automated full-path traversal rather than a live metric.

## Reliability and performance

| Gate | Overall threshold | Per-segment threshold | Emitted by |
|---|---:|---:|---|
| Profile load/save transaction success | at least 99.9% | at least 99.5% | `profile_transaction` |
| Crash-free interactive sessions | at least 99.0% | at least 98.5% | `session_ended` |
| Interactive join p95 | at most 8 seconds | at most 10 seconds | `interactive_session` |
| Join failure rate | at most 1.0% | at most 2.0% | `join_failed` |
| Generator fallback rate | below 0.1% | below 0.2% | `generator_fallback` |

An interactive session begins when the player can move and act in Emberhollow,
not when the client process starts. Planned maintenance and explicit tester
fault-injection sessions are tagged and excluded.

**How a crash is counted, since the platform does not say.** Roblox fires the
same leave event for a player who quit and a player whose phone died. What
differs is the telemetry: a client reports on a fixed interval right up to the
moment it closes, so a session whose last report is several intervals stale when
the player disappears stopped rather than left. `session_ended` carries that
verdict as its reason — `left`, `dropped`, or `shutdown`. A server closing is
named separately on purpose; counting a scheduled restart as fifty crashes is
how a gate gets ignored.

`join_failed` and `interactive_session` are emitted from the same place for the
same reason: the join failure rate is the first over the sum of both, and a
numerator counted against a denominator gathered somewhere else is a rate that
drifts without anybody editing it.

## Comprehension and retention

| Gate | Overall threshold | Per-segment threshold | Emitted by |
|---|---:|---:|---|
| Onboarding completion | at least 70% | at least 60% | `tutorial_completed` |
| First-night completion after onboarding | at least 60% | at least 50% | `first_night_completed` |
| D1 return | at least 20% | report once segment has 100 eligible players | `interactive_session` |
| D7 return | at least 8% | report once segment has 100 eligible players | `interactive_session` |

First-night completion is emitted per player, at the moment that player's own
tutorial advances past the night, rather than once per server when the night
resolves. The night resolving is a server fact and is logged as
`first_night_resolved`; the gate is counting people, and one night can carry
four of them or none. D1 and D7 are read off `interactive_session`'s
`daysSinceFirstSession`, which comes from the profile's own first-seen stamp —
so a rejoin is not a return and a test account with no profile is not a player.

Retention gates supplement qualitative playtest evidence. They never justify
dark patterns, confusing timers, coercive purchases, or inflated session length.

## Commerce

| Gate | Emitted by |
|---|---|
| 100% of completed platform receipts eventually reach exactly one durable grant and one archived purchase tombstone | `receipt_result` |
| At least 99.5% of completed receipts reach the durable grant within 60 seconds | `receipt_result` |
| Canceled prompts produce no receipt and no grant | `purchase_prompt_finished` |
| Receipt retry, server shutdown, full inventory, and archive compaction produce no duplicate grants | `purchase_loss` |

`receipt_result` carries `elapsedSeconds`, measured from the moment the platform
handed the receipt over rather than from the moment the grant was applied — so a
purchase that waited in the mailbox while its buyer was in another server
carries the whole wait, which is the only version of the number a player would
recognise.

The canceled-prompt gate is a claim about something *not* happening, and the
only way to check that a cancel produced nothing is to know a cancel happened.
Without `purchase_prompt_finished` the metric is the absence of an event, which
reads exactly the same as the store being shut.

## Promote, pause, and rollback

- **Promote:** every applicable gate passes throughout the complete 72-hour
  window, all sample minimums are met, and operations approves the evidence.
- **Pause:** a non-zero-tolerance gate fails, a sample minimum is missing, data
  is suspect, or a high-severity pattern lacks an owner and bounded mitigation.
- **Rollback or disable:** any zero-tolerance failure occurs, or a critical
  operational threshold breaches in two consecutive 15-minute windows.
- **Resume:** the cause is repaired, affected players are restored
  idempotently, the fix passes canary validation, and a fresh 72-hour window
  passes. Prior failing time is never carried into the new window.
