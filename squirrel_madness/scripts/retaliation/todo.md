# retaliation/ — cleanup TODOs

> Captured during the mechanical extraction from runtime.lua. None of these are required for the move to be correct; each is a follow-up improvement.

## High value

### 1. Avoid runtime `require()` — Factorio forbids it
- **Where:** any future edit to `scripts/retaliation/module.lua` or its planned sub-modules (`waves.lua`, `feedback.lua`)
- **Action:** All cross-module requires MUST be top-level (file head), never inside function bodies. If a cycle would form, restructure ownership (move the called function into the caller's module) rather than using a lazy require.
- **Why:** Factorio crashes on the first invocation of a function that contains an inline `require()` with "Require can't be used outside of control.lua parsing." This applies to the upcoming `debug/` extraction as well.

### 2. Deduplicate `serialize_position` / `deserialize_position`
- **Where:** `scripts/retaliation/module.lua:17-37` and `scripts/runtime.lua:70-90` (identical copies)
- **Action:** Extract both functions into `scripts/util/position.lua` (or add them to the existing `scripts/storage.lua` if it grows util helpers) and replace both local definitions with a single `require`.
- **Why:** Two identical copies will drift; any bug fix must be applied in two places.

### 3. Deduplicate `station_distance_squared`
- **Where:** `scripts/retaliation/module.lua:39-43` and `scripts/runtime.lua:51-55` (identical copies)
- **Action:** Move to the same shared util module as `serialize_position` (item 2) and require from both files.
- **Why:** Same drift risk as item 2; both copies exist because the move was mechanical.

## Medium value

### 4. Split module into `waves.lua` and `feedback.lua`
- **Where:** `scripts/retaliation/module.lua` (~510 lines total)
- **Action:** Move wave-scheduling logic (`retaliation_wave_unit_name`, `retaliation_wave_member_count`, `resolve_retaliation_spawner`, `create_retaliation_command`, `launch_retaliation_wave`, `module.process_waves`, ~lines 160-319) into `scripts/retaliation/waves.lua`. Move player-notification and feedback-expiry logic (`module.notify`, `module.notify_relocation`, `module.process_feedback_expiry`, ~lines 321-496) into `scripts/retaliation/feedback.lua`. Keep `module.lua` as a thin aggregator like `scripts/selection/module.lua`.
- **Why:** The file is at the same size threshold where `selection/` was split; the two concerns (wave launching vs. player notifications) have no coupling to each other.

### 5. Document `retaliation_state_key` format coupling
- **Where:** `scripts/retaliation/module.lua:45-47`
- **Action:** Add a one-line comment: `-- key format: "<surface_index>:<player_index>" — callers must use module.get_state, never construct this key externally`. Also add an assertion or note in `module.get_state` that the key is internal.
- **Why:** Any caller that reconstructs the key string independently will silently break if the format changes.

### 6. Annotate `connected_force_players` as intentionally private
- **Where:** `scripts/retaliation/module.lua:92-102`
- **Action:** Add a comment: `-- private: only retaliation uses this; promote to a shared util if a second consumer appears`.
- **Why:** Makes the "leave it here for now" decision visible to the next developer, preventing accidental promotion before it is actually needed.

## Low value / nice-to-have

### 7. Remove `module.storage()` and `module.storage_feedback()` once debug layer exists
- **Where:** `scripts/retaliation/module.lua:498-504`
- **Action:** Once a `debug/` module is implemented with proper reporting functions, audit whether `runtime.lua`'s `debug_get_retaliation_feedback` (line 1011) still needs raw storage access. If it can use a reporting function instead, delete both accessors.
- **Why:** Raw storage exports bypass encapsulation; they exist only to serve the debug interface and should not outlive that need.
