local lifecycle = require("scripts.habitat.lifecycle")
local seeding = require("scripts.habitat.seeding")
local tutorials = require("scripts.habitat.tutorials")

local habitat = {}

habitat.resolve_pending_replacements = lifecycle.resolve_pending_replacements
habitat.register_sapling = lifecycle.register_sapling
habitat.unregister_sapling = lifecycle.unregister_sapling
habitat.mature_ready_saplings = lifecycle.mature_ready_saplings
habitat.force_mature_all_saplings = lifecycle.force_mature_all_saplings
habitat.register_harvested_nut_tree = lifecycle.register_harvested_nut_tree
habitat.unregister_harvested_nut_tree = lifecycle.unregister_harvested_nut_tree
habitat.recover_ready_harvested_nut_trees = lifecycle.recover_ready_harvested_nut_trees
habitat.force_recover_all_harvested_nut_trees = lifecycle.force_recover_all_harvested_nut_trees
habitat.harvest_nut_tree = lifecycle.harvest_nut_tree

habitat.seed_nut_trees_in_area = seeding.seed_nut_trees_in_area
habitat.seed_chunk = seeding.seed_chunk
habitat.ensure_starting_grove = seeding.ensure_starting_grove

habitat.maybe_show_deforestation_hint = tutorials.maybe_show_deforestation_hint
habitat.maybe_show_sapling_hint = tutorials.maybe_show_sapling_hint
habitat.maybe_show_harvest_hint = tutorials.maybe_show_harvest_hint
habitat.on_research_finished = tutorials.on_research_finished

return habitat
