# Manual Playtest Authoring Guide

Status: agent-facing working guide

## Purpose

Use this guide when creating or updating milestone playtests in `manual testing/`.

Manual playtests exist to cover:

- visual presentation and readability
- discoverability of player-facing systems
- in-world behavior that requires screen inspection
- long-horizon or feel-based gameplay loops that are awkward to reduce to exact assertions

Manual playtests do not exist to replace FactorioTest coverage for deterministic rules, prototype wiring, exact numeric outputs, or storage bookkeeping.

## Read These Inputs First

- [docs/planned.md](docs/planned.md)
- [docs/SPEC.md](docs/SPEC.md)
- relevant `docs/features/*.md` files, if present
- the implementation in `squirrel_madness/`
- the current automated tests in `squirrel_madness/tests/`
- the existing manual playtests in `manual testing/`

Do not draft playtests from roadmap prose alone. Confirm what the code actually ships.

## Split The Work Before Writing

First classify every candidate check as `automated` or `manual`.

Write an automated test if the behavior:

- has an exact expected result
- can be proven through entity counts, storage state, recipe state, research state, or remote calls
- does not require looking at the screen
- is likely to regress in logic rather than presentation

Write a manual playtest check if the behavior:

- depends on sprites, animation, placement ghosts, map markers, or other visual cues
- depends on player readability, discoverability, pacing, or feel
- is best judged in-world instead of through raw numbers
- would be disproportionately expensive or brittle to automate

Examples:

- Automate: recipe unlock order, feeder stocking thresholds, sapling maturation bookkeeping, region score deltas, worldgen count guarantees.
- Manual: whether a squirrel visibly spawned, whether a picked nut tree is easy to recognize, whether survey feedback is understandable in play, whether a unit looks like it is sitting on a belt.

If a check can reasonably be automated, automate it first and remove it from the manual document.

## Authoring Workflow

1. Re-read the milestone scope in [docs/planned.md](docs/planned.md) and the matching behavior in [docs/SPEC.md](docs/SPEC.md).
2. Inspect the shipped implementation and list the player-visible behaviors that currently exist.
3. Inspect `squirrel_madness/tests/` and add missing automated coverage for deterministic behaviors.
4. Write the manual checklist only for the remaining visual, experiential, or gameplay-flow checks.
5. Keep the document scoped to implemented behavior. Do not write test steps for aspirational features.

## Rules For Milestone Playtest Docs

- Create one file per implemented milestone under `manual testing/`.
- Use stable filenames such as `milestone-2-nut-economy-and-habitat-recovery.md`.
- State the default starting point near the top.
- If the test is better from a save, name the recommended checkpoint save explicitly.
- State the scope of the manual document.
- State which coverage already exists in automation so the reader knows why the checklist is narrow.
- Every test block must include explicit preconditions.
- Keep checklist items short and observable.
- Phrase pass conditions in player-visible terms.
- Use exact timings or thresholds only when they matter to the player-facing behavior.
- If you use console commands or `/editor`, label them as setup shortcuts and explain why they are only setup, not the thing being tested.
- Prefer one assertion per checkbox. Do not hide multiple outcomes in a single line.

## Recommended Structure

Use this shape unless the milestone strongly needs something else:

````md
# Milestone N Manual Playtest

Default start: new scenario on Nauvis
Recommended checkpoint save: <name or none>
Scope: <what this document is trying to validate>
Automated coverage already exists for: <deterministic checks already covered>

## <Feature Or Flow Name>

Preconditions:
- <state the world and player state clearly>

Setup shortcuts:

```lua
/c <optional setup command>
```

Checklist:
- [ ] <one visible action or observation>
- [ ] <one visible action or observation>

Pass condition:
- <what the tester should conclude if the checklist passed>
```
````

Omit the `Setup shortcuts` section when normal play is the right setup.

## What To Avoid

- Do not ask a human to confirm exact remote values, storage fields, or recipe flags.
- Do not duplicate existing automated coverage just because it is easy to describe in prose.
- Do not require a full replay from the start if a checkpoint save isolates the behavior better.
- Do not mix setup work and validation work without labeling them separately.
- Do not write against planned future behavior that the code does not implement yet.
- Do not use vague pass conditions like "works" or "looks fine". Say what the tester should be able to see or infer.

## Maintenance Rule

When a milestone changes, update both sides of the testing story:

- extend or adjust automated tests for deterministic logic
- extend or adjust the matching manual playtest for visual or experiential behavior

If implementation and roadmap prose diverge, fix the prose or call out the mismatch before adding more tests.
