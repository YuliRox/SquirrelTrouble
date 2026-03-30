local constants = {}

constants.mod_name = "squirrel_madness"
constants.primary_surface_name = "nauvis"
constants.region_chunk_span = 2
constants.chunk_size = 32
constants.region_tile_span = constants.region_chunk_span * constants.chunk_size
constants.region_update_interval = 60 * 10
constants.active_region_radius = 2
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
constants.squirrel_update_interval = 60
constants.squirrel_active_region_radius = 1
constants.max_visible_squirrels_per_region = 4
constants.squirrel_min_tree_count = 8
constants.squirrel_min_forest_health = 15
constants.squirrel_stable_tree_count = 12
constants.squirrel_dense_tree_count = 18
constants.squirrel_curious_pressure = 55
constants.squirrel_mischief_pressure = 70
constants.squirrel_agitated_pressure = 85
constants.squirrel_chest_pressure_threshold = 70
constants.max_chest_scavenge_count = 4
constants.max_stashes_per_region = 2
constants.squirrel_target_radius = 24
constants.squirrel_spawn_player_buffer = 18
constants.squirrel_spawn_relaxed_player_buffer = 12
constants.squirrel_home_wander_min_distance = 2.5
constants.squirrel_home_wander_distance = 6.5
constants.squirrel_transport_line_scan_limit = 8
constants.squirrel_move_timeout = 60 * 6
constants.squirrel_decision_interval = 60 * 2
constants.squirrel_belt_block_duration = 60 * 2
constants.squirrel_curious_pause_duration = 60
constants.squirrel_action_cooldown = 60 * 20
constants.squirrel_region_action_cooldown = 60 * 12
constants.squirrel_target_cooldown = 60 * 15
constants.squirrel_repeat_item_bonus = 12
constants.squirrel_grief_duration = 60 * 60 * 3
constants.squirrel_stash_search_radius = 10
constants.squirrel_force_name = "squirrel-madness-fauna"

constants.technologies = {
  arboriculture = "arboriculture",
  wildlife_diversion = "wildlife-diversion",
  forest_surveying = "forest-surveying",
  ecological_stabilization = "ecological-stabilization"
}

constants.names = {
  nut = "nut",
  nut_sapling_item = "nut-sapling",
  nut_sapling = "nut-sapling",
  nut_tree = "nut-tree",
  nut_tree_harvested = "nut-tree-harvested",
  squirrel = "squirrel",
  feeder = "squirrel-feeder",
  feeder_empty = "squirrel-feeder-empty",
  steel_feeder = "steel-squirrel-feeder",
  steel_feeder_empty = "steel-squirrel-feeder-empty",
  stash = "forest-stash",
  survey_station = "forest-survey-station",
  survey_input = "squirrel-madness-open-region-survey",
  relocation_input = "squirrel-madness-relocate-selected-squirrel"
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
