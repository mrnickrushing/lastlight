# Beta tuning — the numbers each decision is made on

## Purpose

[PRODUCTION_ROADMAP.md](PRODUCTION_ROADMAP.md) lists five things Milestone 13's
closed beta tunes: *first session, first night, difficulty cliffs, group
scaling, and repetition*. Each of those is a decision somebody will make in a
room, and a decision made in a room without a number is a decision made from
whoever played most recently.

This document is the table of which number answers which decision, and which
event carries it. `TuningMetrics.spec` holds it against the source in both
directions: every decision here names an event with an emitter in
`AnalyticsService`, every emitter has a `TUNING-METRIC: <id>` call site where
the fact is produced, and every marker in `src` is a decision this table lists.
Neither list may grow alone.

It is the same three-layer check [RELEASE_GATES.md](RELEASE_GATES.md) gets from
`GateMetrics.spec`, for the same reason — **an emitter nobody calls produces a
dashboard reading zero, and that is indistinguishable from a decision that has
been measured.**

## Why a tuning event is not a gate event

A gate is a rate over instants, and every gate emitter reports one instant. A
tuning decision is about a **stretch of play**: how far somebody got before
they stopped, what the third night cost, whether the fifth run into the same
wood was seen through. No instant answers any of those.

`AnalyticsService` already sees almost every number these decisions need go
past — every funnel step, every down, every revive, every extraction. What it
did not do is *accumulate*. So the counters ride along with the events already
being emitted, and the emitters below report them at the moment the unit of
play a decision is about ends.

Two rules the events follow, and both are ways a tuning number lies:

- **A cliff is a comparison, so every checkpoint emits.** A difficulty cliff is
  not a hard checkpoint; it is one much harder than the checkpoint before it,
  which cannot be seen from a single reading. Emitting only where somebody
  already suspects a problem produces numbers that agree with the suspicion and
  say nothing about the rest of the game.
- **An outcome without an attempt number is a survivorship number.** A boss
  with a 90% clear rate looks tuned until you learn it is the ninth attempt
  that clears. Every checkpoint carries which try this was, counted per player.

## The table

| Decision | The number it is made on | Event | Emitted by |
|---|---|---|---|
| Tune the first session | where the player stopped — furthest onboarding step and stage, with the seconds and the platform beside it | `first_session_end` | `PerformanceService._closeSession` |
| Tune the first night | what surviving it cost — downs, revives, and time from the first funnel step | `first_night_outcome` | `TutorialService`, at the step that leaves the night |
| Find difficulty cliffs | outcome **and attempt number** at every named checkpoint on the path | `difficulty_checkpoint` | `TutorialService`, `OldGrowthService`, `WardenStagService`, `BramblewakeBlackoutService` |
| Tune group scaling | the same outcome with the size of the group that ran it, per player | `group_outcome` | `ExpeditionService`, at extraction and at a failed extraction |
| Tune repetition | the nth time this player has done the same activity, and whether they finished it that time | `repeat_activity` | `ExpeditionService`, at the end of each attempt |

## What each event can and cannot honestly see

- **`first_session_end` fires only for a first-day player.** A returning player
  walking back through the lodge is not evidence about onboarding, and folding
  those in makes the median unreadable. The consequence is that its volume is
  not session volume, and the two must not be divided into each other.
- **`first_night_outcome` is not `first_night_completed`.** The gate answers
  whether the night was survived and this answers what it cost; a night
  everybody survives on their third down and a night everybody survives
  untouched both read 100% on the gate.
- **`difficulty_checkpoint` counts attempts within a server, not within a
  life.** The counter is per player per server session, because that is what a
  server can see; a player who leaves and rejoins starts at attempt one again.
  A cliff still shows, because a cliff is a difference between checkpoints in
  the same session, but an absolute attempt count read across sessions would
  be low.
- **`group_outcome` is per player, not per group.** A party of four produces
  four rows, so a run one person carried is visible as three rows with nothing
  banked — which is precisely the failure a group win rate cannot show.
- **`repeat_activity` counts attempts that ended.** A run abandoned by
  disconnect never reaches the emitter, which is correct for the question
  (repetition is about doing the thing again) and wrong for a churn question,
  which `session_ended` answers instead.

## What this does not decide

The decisions themselves. Which cliff is too steep, how long a first session
should be, and at what n an activity has been repeated enough are the owner's,
read across a population that does not exist yet — that population is the whole
of Milestone 13's owner-gated half, and the thresholds it is read against live
in [RELEASE_GATES.md](RELEASE_GATES.md). This document is the instrument.
