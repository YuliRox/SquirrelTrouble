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
constants.nut_tree_seed_min_regular_trees = 10
constants.nut_trees_per_chunk_divisor = 24
constants.max_nut_trees_per_chunk = 3
constants.starting_grove_radius = 96
constants.starting_grove_target = 6
constants.starting_grove_fallback_attempts = 16
constants.tutorial_tree_loss_threshold = 3

constants.names = {
  nut = "nut",
  nut_sapling_item = "nut-sapling",
  nut_sapling = "nut-sapling",
  nut_tree = "nut-tree",
  feeder = "squirrel-feeder",
  stash = "forest-stash",
  survey_station = "forest-survey-station",
  survey_input = "squirrel-madness-open-region-survey",
  relocation_input = "squirrel-madness-relocate-selected-squirrel"
}

return constants
