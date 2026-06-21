local constants = require("scripts.constants")
local store = require("scripts.regions.store")
local recompute = require("scripts.regions.recompute")
local cluster = require("scripts.regions.cluster")

local get_or_create = store.get_or_create
local position_to_region_coord = store.position_to_region_coord
local recompute_region = recompute.recompute_region
local region_needs_recompute = recompute.region_needs_recompute
local ensure_region_recomputed = recompute.ensure_region_recomputed
local build_forest_cluster = cluster.build_forest_cluster

local regions = {}

regions.position_to_region_coord = position_to_region_coord
regions.region_area = store.region_area
regions.recompute_region = recompute_region

function regions.serialize(region)
  return {
    surface_index = region.surface_index,
    region_x = region.region_x,
    region_y = region.region_y,
    forest_health = region.forest_health,
    squirrel_unrest = region.squirrel_unrest,
    squirrel_trust = region.squirrel_trust,
    habitat_pressure = region.habitat_pressure,
    tree_count = region.tree_count,
    sapling_count = region.sapling_count,
    nut_tree_count = region.nut_tree_count,
    feeder_count = region.feeder_count,
    stocked_feeders = region.stocked_feeders,
    empty_feeders = region.empty_feeders,
    recent_tree_loss = region.recent_tree_loss,
    recent_squirrel_deaths = region.recent_squirrel_deaths,
    recent_rough_handling = region.recent_rough_handling,
    recent_relocations = region.recent_relocations,
    recent_tree_loss_window_ticks = constants.recent_tree_loss_window,
    recent_conflict_window_ticks = constants.squirrel_conflict_window,
    rolling_pollution = region.pollution,
    instant_pollution = region.instant_pollution,
    last_updated_tick = region.last_updated_tick,
    forest_health_band = region.forest_health_band,
    squirrel_unrest_band = region.squirrel_unrest_band,
    squirrel_trust_band = region.squirrel_trust_band,
    habitat_pressure_band = region.habitat_pressure_band,
    canopy_score = region.canopy_score,
    nut_tree_bonus = region.nut_tree_bonus,
    stocked_feeder_bonus = region.stocked_feeder_bonus,
    reforestation_bonus = region.reforestation_bonus,
    relocation_bonus = region.relocation_bonus,
    empty_feeder_penalty = region.empty_feeder_penalty,
    recent_tree_loss_penalty = region.recent_tree_loss_penalty,
    squirrel_death_penalty = region.squirrel_death_penalty,
    rough_handling_penalty = region.rough_handling_penalty,
    rolling_pollution_penalty = region.rolling_pollution_penalty,
    drivers = region.drivers
  }
end

function regions.note_tree_loss(surface_index, position, amount, tick)
  local coord = position_to_region_coord(position)
  local region = get_or_create(surface_index, coord.x, coord.y)
  region.tree_loss_events[#region.tree_loss_events + 1] = {
    tick = tick or game.tick,
    amount = amount or 1
  }
  region.dirty = true
  return region
end

local function note_recent_region_event(surface_index, position, field_name, amount, tick)
  local coord = position_to_region_coord(position)
  local region = get_or_create(surface_index, coord.x, coord.y)
  region[field_name][#region[field_name] + 1] = {
    tick = tick or game.tick,
    amount = amount or 1
  }
  region.dirty = true
  return region
end

function regions.note_squirrel_death(surface_index, position, amount, tick)
  return note_recent_region_event(surface_index, position, "squirrel_death_events", amount, tick)
end

function regions.note_rough_handling(surface_index, position, amount, tick)
  return note_recent_region_event(surface_index, position, "rough_handling_events", amount, tick)
end

function regions.note_successful_relocation(surface_index, position, amount, tick)
  return note_recent_region_event(surface_index, position, "relocation_events", amount, tick)
end

function regions.mark_dirty(surface_index, position)
  local coord = position_to_region_coord(position)
  local region = get_or_create(surface_index, coord.x, coord.y)
  region.dirty = true
  return region
end

function regions.needs_recompute(surface, region_x, region_y, tick)
  return region_needs_recompute(get_or_create(surface.index, region_x, region_y), tick)
end

function regions.get_cached_region_report_by_coord(surface, region_x, region_y)
  return regions.serialize(get_or_create(surface.index, region_x, region_y))
end

function regions.get_cached_region_report_at_position(surface, position)
  local coord = position_to_region_coord(position)
  return regions.get_cached_region_report_by_coord(surface, coord.x, coord.y)
end

function regions.get_region_at_position(surface, position)
  local coord = position_to_region_coord(position)
  return get_or_create(surface.index, coord.x, coord.y)
end

function regions.force_recompute_at_position(surface, position, tick)
  local coord = position_to_region_coord(position)
  return recompute_region(surface, coord.x, coord.y, tick)
end

function regions.get_region_report_at_position(surface, position, tick)
  local coord = position_to_region_coord(position)
  return regions.serialize(ensure_region_recomputed(surface, coord.x, coord.y, tick))
end

function regions.get_region_report_by_coord(surface, region_x, region_y, tick)
  return regions.serialize(ensure_region_recomputed(surface, region_x, region_y, tick))
end

function regions.get_forest_cluster_report_at_position(surface, position, tick)
  return build_forest_cluster(surface, position, tick)
end

function regions.get_forest_cluster_report_by_coord(surface, region_x, region_y, tick)
  return build_forest_cluster(surface, {
    x = (region_x * constants.region_tile_span) + (constants.region_tile_span / 2),
    y = (region_y * constants.region_tile_span) + (constants.region_tile_span / 2)
  }, tick)
end

return regions
