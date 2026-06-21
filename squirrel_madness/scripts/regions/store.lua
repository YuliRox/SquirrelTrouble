local constants = require("scripts.constants")
local math_ops = require("scripts.regions.math")

local region_key = math_ops.region_key

local M = {}

function M.position_to_region_coord(position)
  return {
    x = math.floor(position.x / constants.region_tile_span),
    y = math.floor(position.y / constants.region_tile_span)
  }
end

function M.region_area(region_x, region_y)
  local left = region_x * constants.region_tile_span
  local top = region_y * constants.region_tile_span

  return {
    left_top = {x = left, y = top},
    right_bottom = {
      x = left + constants.region_tile_span,
      y = top + constants.region_tile_span
    }
  }
end

function M.region_intersects_circle(region_x, region_y, position, radius)
  local area = M.region_area(region_x, region_y)
  local nearest_x = math.max(area.left_top.x, math.min(position.x, area.right_bottom.x))
  local nearest_y = math.max(area.left_top.y, math.min(position.y, area.right_bottom.y))
  local dx = position.x - nearest_x
  local dy = position.y - nearest_y
  return ((dx * dx) + (dy * dy)) <= (radius * radius)
end

function M.get_surface_regions(surface_index)
  storage.regions[surface_index] = storage.regions[surface_index] or {}
  return storage.regions[surface_index]
end

function M.region_forest_mass(region)
  return math.max((region.tree_count or 0) + (region.sapling_count or 0), 0)
end

function M.region_cluster_weight(region)
  return math.max(M.region_forest_mass(region), 1)
end

function M.region_is_cluster_candidate(region)
  return M.region_forest_mass(region) >= constants.survey_cluster_min_tree_count
end

function M.ensure_region_shape(region, surface_index, region_x, region_y)
  region.surface_index = region.surface_index or surface_index
  region.region_x = region.region_x or region_x
  region.region_y = region.region_y or region_y
  region.forest_health = region.forest_health or 0
  region.squirrel_unrest = region.squirrel_unrest or 0
  region.squirrel_trust = region.squirrel_trust or 0
  region.habitat_pressure = region.habitat_pressure or 0
  region.tree_count = region.tree_count or 0
  region.sapling_count = region.sapling_count or 0
  region.nut_tree_count = region.nut_tree_count or 0
  region.feeder_count = region.feeder_count or 0
  region.stocked_feeders = region.stocked_feeders or 0
  region.empty_feeders = region.empty_feeders or 0
  region.recent_tree_loss = region.recent_tree_loss or 0
  region.recent_squirrel_deaths = region.recent_squirrel_deaths or 0
  region.recent_rough_handling = region.recent_rough_handling or 0
  region.recent_relocations = region.recent_relocations or 0
  region.instant_pollution = region.instant_pollution or 0
  region.pollution = region.pollution or 0
  region.last_updated_tick = region.last_updated_tick or 0
  region.dirty = region.dirty ~= false
  region.tree_loss_events = region.tree_loss_events or {}
  region.squirrel_death_events = region.squirrel_death_events or {}
  region.rough_handling_events = region.rough_handling_events or {}
  region.relocation_events = region.relocation_events or {}
  region.pollution_samples = region.pollution_samples or {}
  region.canopy_score = region.canopy_score or 0
  region.nut_tree_bonus = region.nut_tree_bonus or 0
  region.stocked_feeder_bonus = region.stocked_feeder_bonus or 0
  region.reforestation_bonus = region.reforestation_bonus or 0
  region.relocation_bonus = region.relocation_bonus or 0
  region.empty_feeder_penalty = region.empty_feeder_penalty or 0
  region.recent_tree_loss_penalty = region.recent_tree_loss_penalty or 0
  region.squirrel_death_penalty = region.squirrel_death_penalty or 0
  region.rough_handling_penalty = region.rough_handling_penalty or 0
  region.rolling_pollution_penalty = region.rolling_pollution_penalty or 0
  region.forest_health_band = region.forest_health_band or "collapsed"
  region.squirrel_unrest_band = region.squirrel_unrest_band or "calm"
  region.squirrel_trust_band = region.squirrel_trust_band or "collapsed"
  region.habitat_pressure_band = region.habitat_pressure_band or "light"
  region.drivers = region.drivers or {}
  return region
end

function M.default_region(surface_index, region_x, region_y)
  return M.ensure_region_shape({
    surface_index = surface_index,
    region_x = region_x,
    region_y = region_y,
    dirty = true,
    tree_loss_events = {},
    squirrel_death_events = {},
    rough_handling_events = {},
    relocation_events = {},
    pollution_samples = {},
    drivers = {}
  }, surface_index, region_x, region_y)
end

function M.get_or_create(surface_index, region_x, region_y)
  local surface_regions = M.get_surface_regions(surface_index)
  local key = region_key(region_x, region_y)
  surface_regions[key] = surface_regions[key] or M.default_region(surface_index, region_x, region_y)
  return M.ensure_region_shape(surface_regions[key], surface_index, region_x, region_y)
end

return M
