local storage_lib = {}

function storage_lib.ensure()
  storage.version = storage.version or 8
  storage.regions = storage.regions or {}
  storage.last_refresh_tick = storage.last_refresh_tick or 0
  storage.seeded_chunks = storage.seeded_chunks or {}
  storage.saplings = storage.saplings or {}
  storage.next_sapling_id = storage.next_sapling_id or 1
  storage.harvested_nut_trees = storage.harvested_nut_trees or {}
  storage.next_harvested_nut_tree_id = storage.next_harvested_nut_tree_id or 1
  storage.pending_entity_replacements = storage.pending_entity_replacements or {}
  storage.force_tutorials = storage.force_tutorials or {}
  storage.feeders = storage.feeders or {}
  storage.squirrels = storage.squirrels or {}
  storage.next_squirrel_id = storage.next_squirrel_id or 1
  storage.squirrel_stashes = storage.squirrel_stashes or {}
  storage.next_squirrel_stash_id = storage.next_squirrel_stash_id or 1
  storage.squirrel_region_activity = storage.squirrel_region_activity or {}
  storage.squirrel_region_targets = storage.squirrel_region_targets or {}
  storage.squirrel_target_cooldowns = storage.squirrel_target_cooldowns or {}
  storage.squirrel_region_index = storage.squirrel_region_index or {}
  storage.squirrel_entity_index = storage.squirrel_entity_index or {}
  storage.squirrel_ignored_removals = storage.squirrel_ignored_removals or {}
  storage.squirrel_stashes_by_region = storage.squirrel_stashes_by_region or {}
  storage.squirrel_stash_target_counts = storage.squirrel_stash_target_counts or {}
  storage.squirrel_last_cleanup_tick = storage.squirrel_last_cleanup_tick or 0
  storage.squirrel_damage_attribution = storage.squirrel_damage_attribution or {}
  storage.squirrel_incidents = storage.squirrel_incidents or {}
  storage.next_squirrel_incident_id = storage.next_squirrel_incident_id or 1
  storage.squirrel_retaliation = storage.squirrel_retaliation or {}
  storage.squirrel_retaliation_feedback = storage.squirrel_retaliation_feedback or {}
  storage.region_refresh_queue = storage.region_refresh_queue or {}
  storage.region_refresh_enqueued = storage.region_refresh_enqueued or {}
  storage.player_region_centers = storage.player_region_centers or {}
  storage.survey_station_overlays = storage.survey_station_overlays or {}
  storage.survey_station_panels = storage.survey_station_panels or {}
  storage.squirrel_selection_overlays = storage.squirrel_selection_overlays or {}
  storage.squirrel_selection_panels = storage.squirrel_selection_panels or {}
  storage.squirrel_active_belt_riders = storage.squirrel_active_belt_riders or {}
  storage.squirrel_belt_block_counts = storage.squirrel_belt_block_counts or {}
end

return storage_lib
