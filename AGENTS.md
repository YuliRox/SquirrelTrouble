# squirrel_madness — Shared Agent Instructions

This file is the shared agent instruction source for this checkout. Keep any parallel assistant-instruction copy aligned with it if one exists in another environment.

## Repo Purpose

This repository contains the `squirrel_madness` Factorio 2.0 mod plus supporting tooling for worldgen authoring, blueprint conversion, and automated testing.

The mod theme is scarcity, salvage, and ruined infrastructure. Prefer changes that reinforce circular-economy gameplay and ruined-world presentation over vanilla-style infinite extraction.

## Repo Layout

- `squirrel_madness/` is the actual mod root loaded by Factorio.
- `docs/` contains stable design and behavior references.
- `docs/features/` documents implemented systems.
- `docs/hooks.md` is the runtime event map.
- `manual testing/` contains milestone-specific manual playtest checklists for in-game validation.
- `tools/` contains blueprint extraction, normalization, ruin-template, wear-profile, and sector-compilation tooling.
- `scripts/` contains shell wrappers for Factorio tests and world inspection.
- `planning/` and brainstorming docs are design input, not the operational source of truth.

## Working Rules

- Treat `squirrel_madness/` as the source of gameplay code. Most implementation work belongs there.
- Prefer repo evidence over stale prose. When behavior docs and code disagree, update the docs or note the mismatch.
- Keep Space Age content behind `if mods["space-age"] then`.
- Favor small, targeted edits over broad rewrites unless the task explicitly calls for restructuring.
- Register each Factorio runtime event exactly once in `control.lua` or its central derivative (`scripts/runtime.lua`). That handler is the dispatcher: filter by entity/input/context there, then call subsystem functions. Do not let feature modules call `script.on_event` for the same event independently.
- Features demand tests. There should be no untested edges. When implementing functionality, always implement and accompanying test to verfiy functionality behaves as expected. Alway try to optimize the test surface if you feel that certain features miss tests.
- Never write tests that regex or snapshot source-code structure to infer behavior. Behavioral claims must be verified through runtime tests; static tests are only acceptable for external artifacts such as asset/file existence or similarly non-behavioral build outputs.
- For each milestone, create a manual playtest document for ingame testing.
- When updating manual playtests, reset any new or modified checklist items to `[ ]`. Do not leave touched items marked `[X]`; revalidation must be explicit.
- When planning milestones, explicitly note whether a playtest is a hard stop before further milestone work and summarize what that playtest must validate.
- If the user asks to implement a roadmap milestone, first check that milestone in [docs/planned.md](docs/planned.md) for any `Open questions to settle during implementation` note. If unresolved design questions are listed, do not guess silently. Stop, surface those questions to the user, and resolve them before implementing the affected part of the milestone.
- In markdown and repo documentation, keep paths and links repo-relative unless an absolute path is genuinely necessary.
- If an assistant response would exceed roughly 30 lines, do not send it as chat prose. Write it to a markdown file in the repo and point the user to that file instead.

## Module and Test Structure

Large runtime modules are organized as package directories rather than single files. Follow these conventions when growing or splitting a module.

- A package lives at `scripts/<name>/` with `module.lua` as the entry point and hub. Consumers require the package via `scripts.<name>.module` (for example `require("scripts.regions.module")`). Do not reintroduce single-file shims such as `scripts/<name>.lua`; the canonical entry is always `<name>/module.lua`.
- Split a module by cohesive subsystem, ordering extractions by inbound coupling (smallest, least-depended-on first). Keep the most entangled core (state machine, tick loop) in `module.lua`.
- `require()` is parse-time only and lazy requires are banned (see [docs/lua-guidelines.md](docs/lua-guidelines.md)), so plan dependency direction up front:
  - A submodule may directly `require` only leaf modules it does not cycle with (e.g. `constants`, `scripts.<pkg>.position`, `scripts.<pkg>.storage`, `scripts.regions.module`). Never directly require a sibling subsystem you also call back into.
  - When a subsystem needs functions from the hub or from a sibling subsystem, expose `function M.install(deps) ... return { ... } end` and let `module.lua` inject the callbacks and assign the returned functions to locals. This is the established pattern (`flee`, `targeting`, `carrying`, `stash`).
  - Pure leaf submodules with no hub dependencies (e.g. `render`, `position`, `storage`) are plain tables required directly — no `install`.
- Preserve forward-declared-local upvalues when extracting. Leave the `local X` declaration and its assignment site in place; only swap the inline body for `X = ops.X`. Moving a declaration below a closure that captures it produces a nil upvalue that no grep or parse check will catch.
- Mirror the package layout in tests: behavioral tests for `scripts/<pkg>/<sub>.lua` live in `tests/<pkg>/<sub>_test.lua`, one focused file per submodule. Keep test files small and register each in `scripts/tests.lua`.
- Test submodules behaviorally at runtime (per the no-structural-tests rule above): `install` the submodule with controllable stubs and exercise the real logic against real prototypes, entities, inventories, and `storage`.
- Every extraction must keep the full suite green. Assert the total passed count, not merely the absence of `FAIL`: a load-time mis-wire makes a test file fail to load, which lowers the test count rather than reporting a failure.

## Canonical References

- Runtime hooks: [docs/hooks.md](docs/hooks.md)
- Feature behavior: `docs/features/*.md`
- Roadmap: [docs/planned.md](docs/planned.md)
- Manual playtest authoring: [docs/manual-playtests.md](docs/manual-playtests.md)
- Factorio art style reference: [docs/factorio-art-style-reference.md](docs/factorio-art-style-reference.md)

## Additional Rule Files

- Before doing git work, read and follow [docs/git.md](docs/git.md).
- When working in `squirrel_madness/**/*.lua`, also read and follow [docs/lua-guidelines.md](docs/lua-guidelines.md).

## Verification

Run the smallest relevant verification for the change:

- Lua/mod integration: `npm test`

## Test Environment Notes

- Factorio integration tests run through [scripts/test-factorio.sh](scripts/test-factorio.sh).
- The repo supports WSL workflows that call a Windows `factorio.exe` when `FACTORIO_PATH` points to an `.exe`.
- `FACTORIO_PLAYER_DATA` may be linked into `~/.factorio/player-data.json` by the test wrapper.
- When the WSL + Windows path is active, keep Windows path semantics in mind for test execution and failures.

## Running Tests

FactorioTest is installed locally as a dev dependency (not in `info.json`). Enable it in the Factorio mod list, then:

```bash
# one-shot run
factorio-test run -p ./squirrel_madness

# watch mode — reruns on file changes
factorio-test run -p ./squirrel_madness -w
```

To add new test files: create `squirrel_madness/tests/<name>.lua` and add `require("tests.<name>")` to `scripts/tests.lua`.

## Stable Factorio Rules

- Use `data:extend(...)` only in data stage files.
- Use `storage.*` for persistent runtime state.
- Internal helper entities should stay hidden from normal player interaction unless a task explicitly calls for debug visibility.
- Keep generated assets and generated Lua outputs reproducible from source tooling rather than hand-maintained.
