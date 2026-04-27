# Debug Helpers

Use this file as the running reference for in-repo debug helpers.

## In-Game Visual Helpers

### Survey Station Selection

When a powered `Forest Survey Station` is selected:

- a subtle filled survey-reach disc is shown on the ground
- a station marker is shown at the structure
- a range ring shows `survey_station_exact_radius`
- a side panel shows the exact local survey data for that footprint

Relevant files:
- [runtime.lua](../squirrel_madness/scripts/runtime.lua)
- [constants.lua](../squirrel_madness/scripts/constants.lua)

### Squirrel Selection Overlay

This overlay is only shown when:
- `constants.debug_squirrel_selection_overlay = true`

When a squirrel is selected:

- orange filled circle: the squirrel's current local infrastructure-detection radius
- red outline ring: the squirrel's broader belt-interest / excursion radius

This is the direct answer to the “what does the red ring mean?” question:
- red ring = how far that squirrel is willing to range outward while looking for belt trouble

Relevant files:
- [constants.lua](../squirrel_madness/scripts/constants.lua)
- [runtime.lua](../squirrel_madness/scripts/runtime.lua)
- [squirrels.lua](../squirrel_madness/scripts/squirrels.lua)

## Remote Debug Interface

All of these are exposed on:
- `remote.call("squirrel_madness", ...)`

### Survey Helpers

- `debug_resolve_survey(surface_index, x, y, selected_x?, selected_y?)`
  Returns whether the current read is broad or exact and what anchor it used.
- `debug_get_survey_cluster(surface_index, x, y)`
  Returns the exact forest-footprint report for a position.
- `debug_show_survey_overlay(player_index, surface_index, x, y)`
  Forces the station footprint/range overlay for tests.
- `debug_get_survey_overlay_state(player_index)`
  Returns the currently shown survey overlay state.
- `debug_get_survey_panel_state(player_index)`
  Returns the current survey side-panel state.
- `debug_clear_survey_overlay(player_index)`
  Clears the survey overlay.

### Squirrel Helpers

- `debug_spawn_squirrel(surface_index, x, y)`
  Spawns a squirrel near the requested position.
- `debug_get_squirrel_snapshot(squirrel_id)`
  Returns the squirrel's current mode, intent, position, carrying state, and whether it is belt-riding.
- `debug_get_squirrel_report(surface_index?)`
  Returns a summary of squirrels and stashes on a surface.
- `debug_get_squirrel_target(squirrel_id)`
  Returns the squirrel's currently preferred local and excursion targets.
- `debug_show_squirrel_overlay(player_index, surface_index, x, y)`
  Shows the squirrel selection overlay for tests.
- `debug_get_squirrel_overlay_state(player_index)`
  Returns the currently shown squirrel overlay state.
- `debug_clear_squirrel_overlay(player_index)`
  Clears the squirrel overlay.
- `debug_force_belt_sit(surface_index, squirrel_id, x, y)`
  Forces a squirrel into passive on-belt sitting/inspection at a target belt.
- `debug_force_belt_theft(surface_index, squirrel_id, x, y)`
  Forces a squirrel through a belt theft run for deterministic tests.
- `debug_force_single_belt_grab(surface_index, squirrel_id, x, y)`
  Forces one belt grab so carrying/render state can be inspected.
- `debug_force_chest_scavenge(surface_index, squirrel_id, x, y)`
  Forces a chest theft attempt for deterministic tests.
- `debug_get_belt_block_count(surface_index, x, y)`
  Returns how many squirrel belt-block claims are currently held on that belt entity.
- `debug_advance_squirrel_runtime(duration)`
  Advances squirrel runtime deterministically for tests.
- `debug_clear_surface_squirrels(surface_index)`
  Removes all squirrels on the given surface.
- `debug_kill_squirrel(squirrel_id)`
  Kills a squirrel through the debug path.

### Feeder Helpers

- `debug_sync_feeders(surface_index)`
  Rebuilds feeder tracking and syncs visuals.
- `debug_get_feeder_state(surface_index, x, y)`
  Returns feeder stock / visual state at a position.

### Ecology Refresh Helpers

- `debug_enqueue_active_regions(force?)`
  Queues ecology refresh work around the connected players.
- `debug_process_region_refresh_queue(limit?)`
  Processes a bounded amount of queued ecology work.

## Manual Test Equipment

The current ad-hoc manual testing equipment kit lives in:
- [debug-equipment.md](../manual%20testing/debug-equipment.md)
