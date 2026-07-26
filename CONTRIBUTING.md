# Contributing to Last Light

## Before changing the game

Read the milestone and its acceptance gate in
[docs/PRODUCTION_ROADMAP.md](docs/PRODUCTION_ROADMAP.md). New ideas belong in the
backlog unless they are required by the active gate.

## Local workflow

```bash
git switch main
git pull --ff-only origin main
git switch -c agent/<short-task-name>
npm test
```

Rojo will eventually provide the source-to-Studio loop:

```bash
rojo serve default.project.json
```

Tool versions are pinned only when implementation begins. Do not commit Roblox
place files produced by local Studio sessions.

## Pull requests

A pull request must state:

- the player-visible outcome;
- systems and content IDs changed;
- local checks and playtest matrix used;
- save-data, performance, mobile, exploit, and monetization impact;
- screenshots or video for visual and interaction work;
- rollback or feature-flag behavior for high-risk changes.

## Definition of a finished feature

A feature is finished when its happy path, failure path, server validation,
analytics event, accessibility behavior, low-end-mobile behavior, tests, and
documentation are complete. “Works in one Studio Play session” is not enough.

