local constants = require("scripts.constants")

local regions = {}

local function clamp(value, minimum, maximum)
  if value < minimum then
    return minimum
  end

  if value > maximum then
    return maximum
  end

  return value
end

local function round(value)
  return math.floor(value + 0.5)
end

local function round_tenths(value)
  return math.floor((value * 10) + 0.5) / 10
end

local function region_key(region_x, region_y)
  return region_x .. "," .. region_y
end

local function average(values)
  if #values == 0 then
    return 0
  end

  local total = 0

  for _, value in ipairs(values) do
    total = total + value
  end

  return total / #values
end

local function positive_band(value)
  if value >= 80 then
    return "thriving"
  elseif value >= 60 then
    return "stable"
  elseif value >= 40 then
    return "strained"
  elseif value >= 20 then
    return "fragile"
  end

  return "collapsed"
end

local function unrest_band(value)
  if value <= 20 then
    return "calm"
  elseif value <= 40 then
    return "watchful"
  elseif value <= 60 then
    return "restless"
  elseif value <= 80 then
    return "agitated"
  end

  return "crisis"
end

local function pressure_band(value)
  if value <= 20 then
    return "light"
  elseif value <= 40 then
    return "rising"
  elseif value <= 60 then
    return "disruptive"
  elseif value <= 80 then
    return "severe"
  end

  return "collapse"
end

local function get_surface_regions(surface_index)
  storage.regions[surface_index] = storage.regions[surface_index] or {}
  return storage.regions[surface_index]
end

local function ensure_region_shape(region, surface_index, region_x, region_y)
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
  region.instant_pollution = region.instant_pollution or 0
  region.pollution = region.pollution or 0
  region.last_updated_tick = region.last_updated_tick or 0
  region.dirty = region.dirty ~= false
  region.tree_loss_events = region.tree_loss_events or {}
  region.pollution_samples = region.pollution_samples or {}
  region.canopy_score = region.canopy_score or 0
  region.nut_tree_bonus = region.nut_tree_bonus or 0
  region.stocked_feeder_bonus = region.stocked_feeder_bonus or 0
  region.reforestation_bonus = region.reforestation_bonus or 0
  region.empty_feeder_penalty = region.empty_feeder_penalty or 0
  region.recent_tree_loss_penalty = region.recent_tree_loss_penalty or 0
  region.rolling_pollution_penalty = region.rolling_pollution_penalty or 0
  region.forest_health_band = region.forest_health_band or "collapsed"
  region.squirrel_unrest_band = region.squirrel_unrest_band or "calm"
  region.squirrel_trust_band = region.squirrel_trust_band or "collapsed"
  region.habitat_pressure_band = region.habitat_pressure_band or "light"
  region.drivers = region.drivers or {}
  return region
end

local function default_region(surface_index, region_x, region_y)
  return ensure_region_shape({
    surface_index = surface_index,
    region_x = region_x,
    region_y = region_y,
    dirty = true,
    tree_loss_events = {},
    pollution_samples = {},
    drivers = {}
  }, surface_index, region_x, region_y)
end

local function get_or_create(surface_index, region_x, region_y)
  local surface_regions = get_surface_regions(surface_index)
  local key = region_key(region_x, region_y)
  surface_regions[key] = surface_regions[key] or default_region(surface_index, region_x, region_y)
  return ensure_region_shape(surface_regions[key], surface_index, region_x, region_y)
end

local function sample_region_pollution(surface, area)
  local positions = {
    {x = (area.left_top.x + area.right_bottom.x) / 2, y = (area.left_top.y + area.right_bottom.y) / 2},
    {x = area.left_top.x + 8, y = area.left_top.y + 8},
    {x = area.right_bottom.x - 8, y = area.left_top.y + 8},
    {x = area.left_top.x + 8, y = area.right_bottom.y - 8},
    {x = area.right_bottom.x - 8, y = area.right_bottom.y - 8}
  }

  local total = 0

  for _, position in ipairs(positions) do
    total = total + surface.get_pollution(position)
  end

  return total / #positions
end

local function append_pollution_sample(region, pollution_sample)
  local samples = region.pollution_samples
  samples[#samples + 1] = pollution_sample

  while #samples > constants.pollution_sample_limit do
    table.remove(samples, 1)
  end

  region.instant_pollution = round_tenths(pollution_sample)
  region.pollution = round_tenths(average(samples))
  return region.pollution
end

local function prune_tree_loss_events(region, tick)
  local cutoff_tick = tick - constants.recent_tree_loss_window
  local total = 0
  local write_index = 1

  for read_index = 1, #region.tree_loss_events do
    local entry = region.tree_loss_events[read_index]
    if entry.tick >= cutoff_tick then
      region.tree_loss_events[write_index] = entry
      write_index = write_index + 1
      total = total + (entry.amount or 0)
    end
  end

  for index = write_index, #region.tree_loss_events do
    region.tree_loss_events[index] = nil
  end

  region.recent_tree_loss = round_tenths(total)
  return region.recent_tree_loss
end

local function region_drivers(region)
  local drivers = {}

  if region.canopy_score >= 60 then
    drivers[#drivers + 1] = "dense-canopy"
  end

  if region.stocked_feeder_bonus >= 10 then
    drivers[#drivers + 1] = "stocked-feeders"
  end

  if region.reforestation_bonus >= 4 then
    drivers[#drivers + 1] = "recovering-grove"
  end

  if region.empty_feeder_penalty >= 6 then
    drivers[#drivers + 1] = "empty-feeders"
  end

  if region.recent_tree_loss_penalty >= 10 then
    drivers[#drivers + 1] = "recent-tree-loss"
  end

  if region.rolling_pollution_penalty >= 10 then
    drivers[#drivers + 1] = "rolling-pollution"
  end

  return drivers
end

function regions.position_to_region_coord(position)
  return {
    x = math.floor(position.x / constants.region_tile_span),
    y = math.floor(position.y / constants.region_tile_span)
  }
end

function regions.region_area(region_x, region_y)
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

function regions.note_tree_loss(surface_index, position, amount, tick)
  local coord = regions.position_to_region_coord(position)
  local region = get_or_create(surface_index, coord.x, coord.y)
  region.tree_loss_events[#region.tree_loss_events + 1] = {
    tick = tick or game.tick,
    amount = amount or 1
  }
  region.dirty = true
  return region
end

function regions.mark_dirty(surface_index, position)
  local coord = regions.position_to_region_coord(position)
  local region = get_or_create(surface_index, coord.x, coord.y)
  region.dirty = true
  return region
end

function regions.recompute_region(surface, region_x, region_y, tick)
  local region = get_or_create(surface.index, region_x, region_y)
  local area = regions.region_area(region_x, region_y)
  local current_tick = tick or game.tick

  local tree_count = surface.count_entities_filtered({
    area = area,
    type = "tree"
  })
  local sapling_count = 0

  if prototypes.entity[constants.names.nut_sapling] then
    sapling_count = surface.count_entities_filtered({
      area = area,
      name = constants.names.nut_sapling
    })
  end

  tree_count = math.max(tree_count - sapling_count, 0)

  local nut_tree_count = 0
  if prototypes.entity[constants.names.nut_tree] then
    nut_tree_count = surface.count_entities_filtered({
      area = area,
      name = constants.names.nut_tree
    })
  end

  local feeders = surface.find_entities_filtered({
    area = area,
    name = constants.feeder_entity_names
  })

  local feeder_count = #feeders
  local stocked_feeders = 0

  for _, feeder in ipairs(feeders) do
    local inventory = feeder.get_inventory(defines.inventory.chest)
    if inventory and inventory.valid and inventory.get_item_count(constants.names.nut) >= constants.stocked_feeder_threshold then
      stocked_feeders = stocked_feeders + 1
    end
  end

  local empty_feeders = math.max(feeder_count - stocked_feeders, 0)
  local rolling_pollution = append_pollution_sample(region, sample_region_pollution(surface, area))
  local recent_tree_loss = prune_tree_loss_events(region, current_tick)
  local canopy_score = clamp((tree_count / constants.full_canopy_tree_count) * 100, 0, 100)
  local nut_tree_bonus = clamp(
    nut_tree_count * constants.nut_tree_bonus_per_tree,
    0,
    constants.max_nut_tree_bonus
  )
  local stocked_feeder_bonus = clamp(
    stocked_feeders * constants.stocked_feeder_bonus_per_feeder,
    0,
    constants.max_stocked_feeder_bonus
  )
  local reforestation_bonus = clamp(
    sapling_count * constants.reforestation_bonus_per_sapling,
    0,
    constants.max_reforestation_bonus
  )
  local empty_feeder_penalty = clamp(
    empty_feeders * constants.empty_feeder_penalty_per_feeder,
    0,
    constants.max_empty_feeder_penalty
  )
  local rolling_pollution_penalty = clamp(
    rolling_pollution * constants.pollution_penalty_multiplier,
    0,
    constants.max_pollution_penalty
  )
  local recent_tree_loss_penalty = clamp(
    recent_tree_loss * constants.tree_loss_penalty_per_tree,
    0,
    constants.max_tree_loss_penalty
  )

  region.tree_count = tree_count
  region.sapling_count = sapling_count
  region.nut_tree_count = nut_tree_count
  region.feeder_count = feeder_count
  region.stocked_feeders = stocked_feeders
  region.empty_feeders = empty_feeders
  region.canopy_score = round(canopy_score)
  region.nut_tree_bonus = round(nut_tree_bonus)
  region.stocked_feeder_bonus = round(stocked_feeder_bonus)
  region.reforestation_bonus = round(reforestation_bonus)
  region.empty_feeder_penalty = round(empty_feeder_penalty)
  region.recent_tree_loss_penalty = round(recent_tree_loss_penalty)
  region.rolling_pollution_penalty = round(rolling_pollution_penalty)
  region.forest_health = round(clamp(
    canopy_score + nut_tree_bonus + stocked_feeder_bonus + reforestation_bonus - rolling_pollution_penalty - recent_tree_loss_penalty,
    0,
    100
  ))
  region.squirrel_unrest = round(clamp(
    10
      + recent_tree_loss_penalty
      + rolling_pollution_penalty
      + empty_feeder_penalty
      - stocked_feeder_bonus
      - (reforestation_bonus * 0.35)
      - (region.forest_health * 0.15),
    0,
    100
  ))
  region.squirrel_trust = round(clamp(
    45
      + stocked_feeder_bonus
      + nut_tree_bonus
      + (reforestation_bonus * 0.5)
      - empty_feeder_penalty
      - (recent_tree_loss_penalty * 0.65)
      - (rolling_pollution_penalty * 0.35),
    0,
    100
  ))
  region.habitat_pressure = round(clamp(
    ((100 - region.forest_health) * 0.55)
      + (region.squirrel_unrest * 0.65)
      + empty_feeder_penalty
      - (stocked_feeder_bonus * 0.4)
      - (reforestation_bonus * 0.5),
    0,
    100
  ))
  region.forest_health_band = positive_band(region.forest_health)
  region.squirrel_trust_band = positive_band(region.squirrel_trust)
  region.squirrel_unrest_band = unrest_band(region.squirrel_unrest)
  region.habitat_pressure_band = pressure_band(region.habitat_pressure)
  region.drivers = region_drivers(region)
  region.last_updated_tick = current_tick
  region.dirty = false

  return region
end

local function region_needs_recompute(region, tick)
  local current_tick = tick or game.tick

  if region.dirty then
    return true
  end

  if not region.last_updated_tick or region.last_updated_tick <= 0 then
    return true
  end

  return (current_tick - region.last_updated_tick) >= constants.region_update_interval
end

local function ensure_region_recomputed(surface, region_x, region_y, tick)
  local region = get_or_create(surface.index, region_x, region_y)
  if region_needs_recompute(region, tick) then
    return regions.recompute_region(surface, region_x, region_y, tick)
  end

  return region
end

function regions.needs_recompute(surface, region_x, region_y, tick)
  return region_needs_recompute(get_or_create(surface.index, region_x, region_y), tick)
end

function regions.get_cached_region_report_by_coord(surface, region_x, region_y)
  return regions.serialize(get_or_create(surface.index, region_x, region_y))
end

function regions.get_cached_region_report_at_position(surface, position)
  local coord = regions.position_to_region_coord(position)
  return regions.get_cached_region_report_by_coord(surface, coord.x, coord.y)
end

function regions.get_region_at_position(surface, position)
  local coord = regions.position_to_region_coord(position)
  return get_or_create(surface.index, coord.x, coord.y)
end

function regions.force_recompute_at_position(surface, position, tick)
  local coord = regions.position_to_region_coord(position)
  return regions.recompute_region(surface, coord.x, coord.y, tick)
end

function regions.get_region_report_at_position(surface, position, tick)
  local coord = regions.position_to_region_coord(position)
  return regions.serialize(ensure_region_recomputed(surface, coord.x, coord.y, tick))
end

function regions.get_region_report_by_coord(surface, region_x, region_y, tick)
  return regions.serialize(ensure_region_recomputed(surface, region_x, region_y, tick))
end

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
    recent_tree_loss_window_ticks = constants.recent_tree_loss_window,
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
    empty_feeder_penalty = region.empty_feeder_penalty,
    recent_tree_loss_penalty = region.recent_tree_loss_penalty,
    rolling_pollution_penalty = region.rolling_pollution_penalty,
    drivers = region.drivers
  }
end

return regions
