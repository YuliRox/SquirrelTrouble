# Runtime Hooks

This file maps Factorio runtime registrations to the central handlers in `squirrel_madness/scripts/runtime.lua`.

## Convention

- Register each Factorio event or custom input exactly once in `runtime.register()`.
- The registered handler is the dispatcher for that event. It should validate the payload, filter by entity name/type/input/context, and call subsystem functions.
- Feature modules should expose callable functions for event reactions. They should not call `script.on_event` directly for events already owned by `runtime.register()`.
- When adding a new reaction to an existing event, extend the existing dispatcher and update this map.

## Registered Events

| Event or input | Handler | Dispatches to |
| --- | --- | --- |
| `defines.events.on_tick` | `on_tick` | pending habitat replacements, active region refresh, selection locks, overlay refresh, feeder visuals, retaliation feedback/waves, `squirrels.on_tick` |
| `defines.events.on_player_mined_entity` | `on_entity_removed` | nut-tree harvest, tree-loss bookkeeping, feeder/station/sapling cleanup |
| `defines.events.on_robot_mined_entity` | `on_entity_removed` | nut-tree harvest, tree-loss bookkeeping, feeder/station/sapling cleanup |
| `defines.events.on_entity_died` | `on_entity_removed` | squirrel death handling, tree-loss bookkeeping, feeder/station/sapling cleanup |
| `defines.events.script_raised_destroy` | `on_entity_removed` | squirrel, tree, feeder, station, and sapling cleanup |
| `defines.events.on_entity_damaged` | `on_squirrel_damaged` | squirrel rough-handling attribution and retaliation trigger |
| `defines.events.on_built_entity` | `on_entity_created` | sapling, feeder, and survey-station registration |
| `defines.events.on_robot_built_entity` | `on_entity_created` | sapling, feeder, and survey-station registration |
| `defines.events.script_raised_built` | `on_entity_created` | sapling, feeder, and survey-station registration |
| `defines.events.script_raised_revive` | `on_entity_created` | sapling, feeder, and survey-station registration |
| `defines.events.on_chunk_generated` | `on_chunk_generated` | habitat seeding and squirrel population seeding |
| `defines.events.on_player_changed_position` | `on_player_changed_position` | squirrel rough-handling by stepping into a squirrel |
| `defines.events.on_selected_entity_changed` | `on_selected_entity_changed` | survey, feeder, and squirrel selection panels/overlays |
| `defines.events.on_research_finished` | `on_research_finished` | habitat research hooks |
| `constants.names.survey_input` | `on_custom_input` | forest survey request |
| `constants.names.relocation_input` | `on_custom_input` | selected squirrel relocation |
