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

## Zero-tolerance gates

Every value below must remain zero:

- confirmed save loss or unrecoverable save corruption;
- duplicate purchase grants or a completed receipt permanently missing its grant;
- blocker or critical defects on the supported launch path;
- impossible critical-path expedition seeds in the candidate suite or live cohort;
- unauthorized economy, entitlement, admin, or progression mutation;
- critical platform-policy or player-safety failure.

Any confirmed zero-tolerance event stops promotion and triggers rollback,
kill-switch activation, or cohort isolation immediately.

## Reliability and performance

| Gate | Overall threshold | Per-segment threshold |
|---|---:|---:|
| Profile load/save transaction success | at least 99.9% | at least 99.5% |
| Crash-free interactive sessions | at least 99.0% | at least 98.5% |
| Interactive join p95 | at most 8 seconds | at most 10 seconds |
| Join failure rate | at most 1.0% | at most 2.0% |
| Generator fallback rate | below 0.1% | below 0.2% |

An interactive session begins when the player can move and act in Emberhollow,
not when the client process starts. Planned maintenance and explicit tester
fault-injection sessions are tagged and excluded.

## Comprehension and retention

| Gate | Overall threshold | Per-segment threshold |
|---|---:|---:|
| Onboarding completion | at least 70% | at least 60% |
| First-night completion after onboarding | at least 60% | at least 50% |
| D1 return | at least 20% | report once segment has 100 eligible players |
| D7 return | at least 8% | report once segment has 100 eligible players |

Retention gates supplement qualitative playtest evidence. They never justify
dark patterns, confusing timers, coercive purchases, or inflated session length.

## Commerce

- 100% of completed platform receipts eventually reach exactly one durable
  grant and one archived purchase tombstone.
- At least 99.5% of completed receipts reach the durable grant within 60 seconds.
- Canceled prompts produce no receipt and no grant.
- Receipt retry, server shutdown, full inventory, and archive compaction produce
  no duplicate grants.

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
