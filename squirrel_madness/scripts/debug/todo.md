# debug/ — cleanup TODOs

> Captured during the mechanical extraction from runtime.lua. None of these are required for the move to be correct; each is a follow-up improvement.

## High value

### 1. Avoid runtime `require()` — Factorio forbids it
- **Where:** any future edit to `scripts/debug/module.lua` or planned sub-modules
- **Action:** All cross-module requires MUST be top-level (file head), never inside function bodies. If a cycle would form, restructure ownership rather than using a lazy require.
- **Why:** Factorio crashes on first invocation of any function containing an inline `require()`. Already followed in this module — listed here as a permanent constraint for future edits.

### 2. Extract `with_surface` helper to remove boilerplate
- **Where:** `scripts/debug/module.lua:22-27`, `31-36`, `54-59`, `71-76`, `207-211`, `216-220`, `233-237`, `244-248`, `253-257`, `274-279`, `352-357` (and several more — ~15 sites total)
- **Action:** Define `local function with_surface(surface_index, fn) storage_lib.ensure(); local surface = game.surfaces[surface_index]; if not surface then return nil end; return fn(surface) end` at the top of `module.lua` and replace every repeated guard with a call to it.
- **Why:** The `storage_lib.ensure()` / `game.surfaces[surface_index]` / `if not surface then return nil end` triple appears ~15 times; a single helper eliminates ~30 lines of noise and ensures the guard is applied consistently.

### 3. Move `find_squirrel_at_position` into `scripts/squirrels.lua`
- **Where:** Injected dep used at `scripts/debug/module.lua:401`; defined as a local in `scripts/runtime.lua:255` and passed via deps at `runtime.lua:339`
- **Action:** Expose `find_squirrel_at_position` as a public function from `scripts/squirrels.lua`, then remove the `deps` parameter from `module.install` and replace `deps.find_squirrel_at_position(...)` with a direct call.
- **Why:** The dep-injection seam exists only because the function was private in `runtime.lua`; making it public on `squirrels` (which already owns squirrel entity queries) removes a one-off injection pattern that has no other callers.

### 4. Split into domain sub-modules
- **Where:** `scripts/debug/module.lua` (504 lines)
- **Action:** Extract four sub-modules — `debug/regions.lua` (region/survey methods: `get_region_at_position`, `debug_resolve_survey`, `debug_get_survey_*`, `debug_show_survey_*`, `force_recompute_at_position`, `get_region_by_coord`, `debug_enqueue_active_regions`, `debug_process_region_refresh_queue`), `debug/squirrels.lua` (squirrel-state methods: `debug_spawn_squirrel`, `debug_kill_squirrel`, `debug_clear_surface_squirrels`, `debug_get_squirrel_*`, `debug_force_*`, `debug_squirrel_*`, `debug_advance_squirrel_runtime`, `debug_cleanup_empty_stashes`, `debug_refresh_*`), `debug/feeders.lua` (`debug_sync_feeders`, `debug_get_feeder_*`, `debug_show_feeder_*`, `debug_clear_feeder_*`, `seed_nut_trees_in_area`, `ensure_starting_grove`, `force_mature_all_saplings`, `force_recover_all_harvested_nut_trees`), `debug/retaliation.lua` (`debug_handle_player_step`, `debug_get_squirrel_incidents`, `debug_get_retaliation_*`, `debug_get_last_step_feedback`, `debug_process_retaliation_*`). Keep `module.lua` as a thin aggregator that merges the four tables and calls `remote.add_interface`.
- **Why:** At 504 lines this is the largest extracted sub-module; the four concerns (region/survey, squirrel state, feeders/habitat, retaliation/feedback) have no intra-group coupling and mirror the domain split already used in `selection/`.

## Medium value

### 5. Fix `debug_get_squirrel_incidents` raw storage access
- **Where:** `scripts/debug/module.lua:413` — reads `storage.squirrel_incidents` directly
- **Action:** Replace with a call to a public `incidents.list(surface_index)` function once the incidents module owns its storage fully.
- **Why:** Direct `storage.*` access from the debug layer bypasses the incidents module's encapsulation; if the storage key or structure changes, this method silently breaks without any error at the module boundary.

## Low value / nice-to-have

### 6. `module.install` returns nothing
- **Where:** `scripts/debug/module.lua:16`
- **Action:** Return the count of methods registered (e.g. `return table_size(interface_table)`) so tests can assert the interface was populated.
- **Why:** A return value lets an automated test verify that `install` ran and registered a non-zero number of methods without depending on `remote.interfaces` state.

### 7. No key grouping in the remote interface table
- **Where:** `scripts/debug/module.lua:21-501`
- **Action:** After the split in item 4, each domain file returns its own method table; grouping becomes structural automatically. No manual reordering needed now.
- **Why:** Methods are currently listed in historical addition order; the split resolves this without a separate sorting pass.
