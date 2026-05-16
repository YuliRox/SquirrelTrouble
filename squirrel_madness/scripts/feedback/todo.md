# feedback/ — cleanup TODOs

> Captured during the mechanical extraction from runtime.lua. None of these are required for the move to be correct; each is a follow-up improvement.

## High value

### 1. Avoid runtime `require()` — Factorio forbids it
- **Where:** any future edit to `scripts/feedback/module.lua`
- **Action:** All cross-module requires MUST be top-level (file head), never inside function bodies. If a cycle would form, restructure ownership (move the called function into the caller's module) rather than using a lazy require.
- **Why:** Factorio crashes on the first invocation of a function that contains an inline `require()` with "Require can't be used outside of control.lua parsing." This applies to the upcoming `debug/` extraction as well.

### 2. Confirm no require cycle after incidents extraction
- **Where:** `scripts/feedback/module.lua` (top-level requires incidents)
- **Action:** Once `debug/` is extracted, audit the full require graph: feedback → incidents → retaliation; confirm no back-edge closes a cycle. If a cycle forms, restructure ownership rather than using a lazy require.
- **Why:** The incidents extraction is done; this is the next risk point as new modules are added.

### 3. Add `feedback.reset()` and call it from runtime.lua `on_init` / `on_configuration_changed`
- **Where:** `scripts/runtime.lua:242` (`on_init`) and `scripts/runtime.lua:256` (`on_configuration_changed`); no corresponding function exists in `scripts/feedback/module.lua`
- **Action:** Add `function module.reset() storage.squirrel_step_feedback = nil end` to feedback/module.lua, then replace the two direct assignments in runtime.lua with `feedback.reset()`.
- **Why:** runtime.lua should not reach into feedback-owned storage keys directly; mirrors the pattern `selection.reset()` already establishes.

## Low value / nice-to-have

### 4. Inline or remove `get_squirrel_step_feedback` private wrapper
- **Where:** `scripts/feedback/module.lua:10-12` (private function), `scripts/feedback/module.lua:109-111` (`module.storage_step`)
- **Action:** Either inline `storage.squirrel_step_feedback` directly in `module.storage_step`, or keep the wrapper only if it gains additional logic (lazy init, validation). Today it adds no value.
- **Why:** One-line pure indirection through a named local is overhead without benefit; the intent is clearer without it.

### 5. Remove `module.storage_step()` once a debug module exists
- **Where:** `scripts/feedback/module.lua:109-111`, called at `scripts/runtime.lua:937`
- **Action:** Once a `debug/` module is extracted with its own reporting surface, audit whether the raw storage accessor is still needed. If the debug interface can use a structured reporting function instead, delete `module.storage_step()`.
- **Why:** Same pattern as `retaliation.storage()` / `retaliation.storage_feedback()` (retaliation/todo.md item 7); raw storage exports should not outlive the debug interface that requires them.

### 6. No internal split needed
- **Where:** `scripts/feedback/module.lua` (113 lines total)
- **Decision:** At 113 lines the file is well below any split threshold. Do not introduce sub-files unless the module grows substantially (e.g. a dedicated `pin.lua` for chart-tag resolution once destroy_pin gains create/update counterparts).
