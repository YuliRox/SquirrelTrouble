# incidents/ — cleanup TODOs

> Captured after mechanical extraction (181 lines). None of these are required for the move to be correct; each is a follow-up improvement.

## High value

### 1. Deduplicate `force_has_technology` (four copies across the codebase)
- **Where:** `scripts/incidents/module.lua:34-41`, `scripts/runtime.lua:26` (dead — no callers), `scripts/selection/squirrel.lua:27`, `scripts/selection/survey.lua:88`
- **Action:** Extract into `scripts/util/technologies.lua`, export as `M.force_has_technology`, and replace the three live copies with a `require`. Delete the dead copy in `runtime.lua` independently.
- **Why:** Four copies of a 7-line helper will drift on any bug fix or API change; the `runtime.lua` copy is already dead and should be removed regardless.

### 2. Extract `module.record`'s death-retaliation block into `retaliation`
- **Where:** `scripts/incidents/module.lua:74-104` (the `if player_index and kind == "death"` block inside `module.record`)
- **Action:** Introduce `retaliation.record_incident_response(incident_id, surface, position, tick, severity)` that absorbs the three retaliation calls (`get_state`, `prune_state`, `find_revenge_spawner`) and returns the state and spawner data incidents needs to finish filling the row. Leave `module.record` purely concerned with building the incident row.
- **Why:** `module.record` currently reaches into retaliation internals; the coupling belongs in a retaliation-owned function so incidents stays read-only with respect to retaliation state.

## Medium value

### 3. Deduplicate `serialize_position`
- **Where:** `scripts/incidents/module.lua:23-32` and `scripts/retaliation/module.lua` (tracked in retaliation/todo.md item 3)
- **Action:** Move to `scripts/util/position.lua` alongside the shared util work for retaliation's copy. Require from both files.
- **Why:** Cross-reference with retaliation/todo.md item 3; coordinate both removals in the same change.

### 4. Move `force_has_technology` gate out of `module.relocate_selected_squirrel`
- **Where:** `scripts/incidents/module.lua:112-115`
- **Action:** Move the technology check into the runtime `on_custom_input` dispatcher (in `scripts/runtime.lua`) so `module.relocate_selected_squirrel` is a pure mechanic that callers can invoke without repeating the guard. Low priority.
- **Why:** The procedural gate mixed into a mechanic function makes the function harder to test in isolation and harder to call from future input paths.

## Low value / nice-to-have

### 5. Avoid runtime `require()` — Factorio forbids it
- **Where:** any future edit to `scripts/incidents/module.lua` or related sub-modules
- **Action:** All cross-module requires MUST be top-level (file head), never inside function bodies. If a cycle would form, restructure ownership (move the called function into the caller's module) rather than using a lazy require.
- **Why:** Factorio crashes on the first invocation of a function that contains an inline `require()` with "Require can't be used outside of control.lua parsing." This applies to the upcoming `debug/` extraction as well.

### 6. Document `extra`-table contract for `kind == "relocation"`
- **Where:** `scripts/incidents/module.lua:58-67` (`module.record`)
- **Action:** Add a comment above the `if kind == "relocation"` block listing the seven expected keys (`destination_region_x/y`, `destination_position`, `destination_forest_health`, `destination_squirrel_trust`, `destination_habitat_pressure`, `destination_tree_mass`, `destination_score`). Alternatively enforce with an assertion or typed wrapper.
- **Why:** The contract is implicit; any caller passing an incomplete `extra` table silently writes `nil` into the incident row with no error.

### 7. No internal split needed
- **Where:** `scripts/incidents/module.lua` (181 lines total)
- **Decision:** Below the split threshold. Do not introduce sub-files unless the module grows substantially (e.g. dedicated query/reporting functions added later).
