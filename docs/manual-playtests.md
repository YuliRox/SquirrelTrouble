# Manual Playtest Authoring Guide

Use this guide when creating or updating manual playtests for Squirrel Trouble.

Manual playtests in this repo exist for checks that need a human eye:
- whether a structure reads clearly in-world
- whether a scripted sequence feels fair and legible
- whether visual transitions, hints, and feedback land at the right moment
- whether a checkpoint save or manual test surface still demonstrates the intended loop

They are not a fallback for logic that can be asserted in automated tests.

## Purpose

Manual playtests should cover the player-facing remainder after automated coverage already proves the deterministic parts.

Good manual targets in this repo include:
- survey station presentation and survey UX
- nut-tree readability, harvest feedback, and regrowth visibility
- sapling placement and maturation legibility
- feeder art-state swaps and upgrade readability
- squirrel motion, nuisance behavior, theft, retreat, and stash recovery
- escalation, grief, and other feedback that must feel understandable in play

## Read These Inputs First

Before writing or updating a playtest, inspect:
- the relevant implementation under `squirrel_madness/`
- the related automated tests under `squirrel_madness/tests/`
- the existing docs in `manual testing/`
- any supporting design or milestone notes in `docs/`

Write from shipped behavior and concrete repo state, not from roadmap memory.

## Split The Work Before Writing

Classify each check before adding it to a manual doc.

Use automated coverage for:
- deterministic state changes
- exact inventory, timer, or score math
- scripted transitions that can be asserted from public state or saved state
- regressions that should fail fast in CI

Use manual coverage for:
- sprite readability, animation clarity, and scale
- in-world presentation of structures, wildlife, stashes, and overlays
- message timing, hint wording, and perceived fairness
- sequences where the real question is "does this make sense to a player?"

If a check can be made reliable in an automated test, automate it first and mention that coverage in the manual doc.

## Authoring Workflow

1. Re-read the relevant implementation and existing automated tests.
2. Identify what is already proven by unit or integration coverage.
3. Keep only the player-visible remainder in the manual checklist.
4. Anchor the test in a real checkpoint save or a clearly described setup shortcut.
5. Phrase each checkbox as an observable action and outcome, not an internal assertion.

## Rules For Milestone Playtest Docs

- Keep one file per milestone or tightly related manual test surface.
- Store the docs in `manual testing/` with stable, descriptive filenames.
- Start each file with:
  - `Default start`
  - `Recommended checkpoint save`
  - `Scope`
  - `Automated coverage already exists for`
- Use scenario sections with:
  - `Preconditions`
  - optional `Setup shortcuts`
  - `Checklist`
  - `Pass condition`
- Keep each checkbox narrow. One observable claim per line.
- When adding or changing checklist items, default them to `[ ]`. Do not pre-mark new or modified checks as `[X]`; manual revalidation must be explicit.
- Prefer player-facing wording such as `the squirrel is easy to track` over implementation wording such as `the render object updates correctly`.
- Call out known limitations explicitly when they should not fail the milestone yet.
- If a milestone is a retest gate, add a `Current Status` section summarizing validated behavior, failures, and the next target.

## Recommended Structure

```md
# Milestone N: Short Name

- Default start: ...
- Recommended checkpoint save: ...
- Scope: ...
- Automated coverage already exists for: ...

## Feature Or Scenario Name

Preconditions:
- ...

Setup shortcuts:
- Optional `/c` commands or editor shortcuts.

Checklist:
- [ ] Observable player-facing outcome.
- [ ] Observable player-facing outcome.

Pass condition:
- Short statement describing what good enough looks like for this milestone.
```

## What To Avoid

- Do not manually verify exact counters, timers, or storage fields that are already covered by tests.
- Do not duplicate large automated test matrices in prose.
- Do not require a full fresh run if a checkpoint save or local setup shortcut is enough.
- Do not mix setup steps and validation into one vague checkbox.
- Do not write playtests for behavior that does not exist in the repo yet.
- Do not use pass conditions like `looks fine` without saying what the tester should actually notice.

## Maintenance Rule

When Squirrel Trouble changes a milestone, update both:
- the automated coverage that proves the deterministic parts
- the manual playtest doc that proves the player-facing parts

If the checkpoint save, test surface, or visible behavior drifts, fix the prose immediately.
