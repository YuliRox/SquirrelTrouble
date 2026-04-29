local constants = {}

constants.mod_name = "squirrel_madness"
constants.primary_surface_name = "nauvis"
constants.region_chunk_span = 2
constants.chunk_size = 32
constants.region_tile_span = constants.region_chunk_span * constants.chunk_size
constants.region_update_interval = 60 * 10
constants.active_region_radius = 2
constants.region_refresh_batch_size = 3
constants.metric_min = 0
constants.metric_max = 100
constants.stocked_feeder_threshold = 20
constants.feeder_visual_stock_threshold = 1
constants.feeder_visual_update_interval = 15
constants.recent_tree_loss_window = 60 * 60 * 5
constants.pollution_sample_limit = 18
constants.full_canopy_tree_count = 72
constants.nut_tree_bonus_per_tree = 4
constants.max_nut_tree_bonus = 20
constants.stocked_feeder_bonus_per_feeder = 12
constants.max_stocked_feeder_bonus = 30
constants.empty_feeder_penalty_per_feeder = 6
constants.max_empty_feeder_penalty = 18
constants.relocation_bonus_per_event = 10
constants.max_relocation_bonus = 20
constants.squirrel_death_penalty_per_event = 16
constants.max_squirrel_death_penalty = 40
constants.squirrel_rough_handling_penalty_per_event = 6
constants.max_squirrel_rough_handling_penalty = 18
constants.pollution_penalty_multiplier = 3.5
constants.max_pollution_penalty = 65
constants.tree_loss_penalty_per_tree = 6
constants.max_tree_loss_penalty = 70
constants.nut_sapling_growth_time = 60 * 60 * 12
constants.nut_tree_harvest_regrowth_time = 60 * 60 * 5
constants.nut_tree_seed_min_regular_trees = 10
constants.nut_trees_per_chunk_divisor = 24
constants.max_nut_trees_per_chunk = 3
constants.starting_grove_radius = 96
constants.starting_grove_target = 6
constants.starting_grove_fallback_attempts = 16
constants.tutorial_tree_loss_threshold = 3
constants.reforestation_bonus_per_sapling = 2
constants.max_reforestation_bonus = 12
constants.survey_station_exact_radius = 24
constants.survey_cluster_min_tree_count = 6
constants.survey_cluster_seed_search_radius = 1
constants.survey_cluster_search_radius = 1
constants.survey_overlay_refresh_interval = 60
constants.squirrel_update_interval = 20
constants.squirrel_cleanup_interval = 60 * 5
constants.squirrel_active_region_radius = 1
constants.squirrel_spawn_batch_per_update = 1
constants.max_visible_squirrels_per_region = 8
constants.squirrel_min_tree_count = 8
constants.squirrel_tree_count_per_population_step = 10
constants.squirrel_min_forest_health = 15
constants.squirrel_stable_tree_count = 12
constants.squirrel_dense_tree_count = 18
constants.squirrel_chunk_seed_min_tree_count = 6
constants.squirrel_curious_pressure = 55
constants.squirrel_mischief_pressure = 62
constants.squirrel_agitated_pressure = 85
constants.squirrel_chest_pressure_threshold = 70
constants.max_stashes_per_region = 2
constants.squirrel_belt_target_radius = 128
constants.squirrel_chest_target_radius = 40
constants.squirrel_region_target_search_margin = 48
constants.squirrel_target_snapshot_interval = 60
constants.squirrel_spawn_player_buffer = 18
constants.squirrel_spawn_relaxed_player_buffer = 12
constants.squirrel_idle_pause_min = 60 * 5
constants.squirrel_idle_pause_max = 60 * 10
constants.squirrel_roam_step_min_distance = 1.5
constants.squirrel_roam_step_max_distance = 3.5
constants.squirrel_home_wander_min_distance = 2.5
constants.squirrel_home_wander_distance = 6.5
constants.squirrel_curious_wander_distance = 12
constants.squirrel_mischievous_wander_distance = 24
constants.squirrel_agitated_wander_distance = 36
constants.squirrel_grieving_wander_distance = 42
constants.squirrel_calm_local_target_radius = 12
constants.squirrel_curious_local_target_radius = 14
constants.squirrel_mischievous_local_target_radius = 18
constants.squirrel_agitated_local_target_radius = 22
constants.squirrel_grieving_local_target_radius = 26
constants.squirrel_belt_handoff_radius = 8
constants.squirrel_excursion_step_min_distance = 3
constants.squirrel_excursion_step_max_distance = 6
constants.squirrel_transport_line_scan_limit = 8
constants.squirrel_move_timeout = 60 * 6
constants.squirrel_decision_interval = 60
constants.squirrel_fear_duration = 60 * 30
constants.squirrel_flee_repath_interval = 15
constants.squirrel_flee_step_distance = 14
constants.squirrel_flee_min_distance_from_player = 18
constants.squirrel_flee_stuck_ticks = 12
constants.squirrel_flee_progress_distance = 0.12
constants.squirrel_belt_block_duration = 60 * 6
constants.squirrel_belt_inspect_duration = 60 * 5
constants.squirrel_belt_grab_interval = 10
constants.squirrel_belt_grab_amount = 5
constants.squirrel_belt_ride_speed = 1 / 32
constants.squirrel_belt_ride_start_progress = -0.35
constants.squirrel_belt_ride_end_progress = 0.35
constants.squirrel_belt_lane_offset = 0.14
constants.squirrel_curious_pause_duration = 60
constants.squirrel_feeder_peace_radius = 12
constants.squirrel_feeder_target_bonus = 18
constants.squirrel_feeder_visit_duration = 60 * 6
constants.squirrel_feeder_nibble_interval = 45
constants.debug_squirrel_selection_overlay = false
constants.squirrel_step_trigger_radius = 0.65
constants.squirrel_selection_hold_ticks = 60 * 60
constants.squirrel_action_cooldown = 60 * 20
constants.squirrel_region_action_cooldown = 60 * 12
constants.squirrel_target_cooldown = 60 * 15
constants.squirrel_repeat_item_bonus = 12
constants.squirrel_grief_duration = 60 * 60 * 3
constants.squirrel_stash_search_radius = 10
constants.squirrel_conflict_window = 60 * 60 * 10
constants.squirrel_damage_attribution_cooldown = 60 * 3
constants.relocation_search_radius = 6
constants.relocation_min_forest_health = 60
constants.relocation_max_habitat_pressure = 45
constants.relocation_min_tree_count = 12
constants.relocation_min_trust = 35
constants.retaliation_window = 60 * 60 * 10
constants.retaliation_step_severity = 1
constants.retaliation_death_severity = 3
constants.retaliation_spawner_search_radius = 192
constants.retaliation_feedback_duration = 60 * 60
constants.retaliation_wave_delay = 60 * 3
constants.retaliation_wave_attack_radius = 12
constants.retaliation_wave_spawn_radius = 8
constants.retaliation_wave_spawn_search_radius = 24
constants.retaliation_wave_max_members = 6
constants.squirrel_force_name = "squirrel-madness-fauna"

constants.technologies = {
  arboriculture = "arboriculture",
  wildlife_diversion = "wildlife-diversion",
  forest_surveying = "forest-surveying",
  wildlife_relocation = "wildlife-relocation",
  ecological_stabilization = "ecological-stabilization"
}

constants.names = {
  nut = "nut",
  nut_sapling_item = "nut-sapling",
  nut_sapling = "nut-sapling",
  nut_tree = "nut-tree",
  nut_tree_harvested = "nut-tree-harvested",
  squirrel = "squirrel",
  squirrel_panicked = "squirrel-panicked",
  squirrel_sitting = "squirrel-sitting",
  feeder = "squirrel-feeder",
  feeder_empty = "squirrel-feeder-empty",
  steel_feeder = "steel-squirrel-feeder",
  steel_feeder_empty = "steel-squirrel-feeder-empty",
  stash = "forest-stash",
  survey_station = "forest-survey-station",
  survey_input = "squirrel-madness-open-region-survey",
  relocation_input = "squirrel-madness-relocate-selected-squirrel"
}

constants.squirrel_entity_name_list = {
  constants.names.squirrel,
  constants.names.squirrel_panicked,
  constants.names.squirrel_sitting
}

constants.squirrel_entity_names = {
  [constants.names.squirrel] = true,
  [constants.names.squirrel_panicked] = true,
  [constants.names.squirrel_sitting] = true
}

constants.feeder_entity_names = {
  constants.names.feeder,
  constants.names.feeder_empty,
  constants.names.steel_feeder,
  constants.names.steel_feeder_empty
}

constants.feeder_item_names = {
  constants.names.feeder,
  constants.names.steel_feeder
}

constants.feeder_variant_by_name = {
  [constants.names.feeder] = {
    item = constants.names.feeder,
    full = constants.names.feeder,
    empty = constants.names.feeder_empty
  },
  [constants.names.feeder_empty] = {
    item = constants.names.feeder,
    full = constants.names.feeder,
    empty = constants.names.feeder_empty
  },
  [constants.names.steel_feeder] = {
    item = constants.names.steel_feeder,
    full = constants.names.steel_feeder,
    empty = constants.names.steel_feeder_empty
  },
  [constants.names.steel_feeder_empty] = {
    item = constants.names.steel_feeder,
    full = constants.names.steel_feeder,
    empty = constants.names.steel_feeder_empty
  }
}

return constants
