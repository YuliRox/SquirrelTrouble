local constants = require("scripts.constants")
local math_ops = require("scripts.regions.math")
local store = require("scripts.regions.store")

local clamp = math_ops.clamp
local round = math_ops.round
local round_tenths = math_ops.round_tenths
local average = math_ops.average
local positive_band = math_ops.positive_band
local unrest_band = math_ops.unrest_band
local pressure_band = math_ops.pressure_band

local get_or_create = store.get_or_create
local region_area = store.region_area

local M = {}

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

local function prune_recent_events(events, tick, window)
  local cutoff_tick = tick - window
  local total = 0
  local write_index = 1

  for read_index = 1, #events do
    local entry = events[read_index]
    if entry.tick >= cutoff_tick then
      events[write_index] = entry
      write_index = write_index + 1
      total = total + (entry.amount or 0)
    end
  end

  for index = write_index, #events do
    events[index] = nil
  end

  return round_tenths(total)
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

function M.recompute_region(surface, region_x, region_y, tick)
  local region = get_or_create(surface.index, region_x, region_y)
  local area = region_area(region_x, region_y)
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
  local recent_squirrel_deaths = prune_recent_events(region.squirrel_death_events, current_tick, constants.squirrel_conflict_window)
  local recent_rough_handling = prune_recent_events(
    region.rough_handling_events,
    current_tick,
    constants.squirrel_conflict_window
  )
  local recent_relocations = prune_recent_events(region.relocation_events, current_tick, constants.squirrel_conflict_window)
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
  local squirrel_death_penalty = clamp(
    recent_squirrel_deaths * constants.squirrel_death_penalty_per_event,
    0,
    constants.max_squirrel_death_penalty
  )
  local rough_handling_penalty = clamp(
    recent_rough_handling * constants.squirrel_rough_handling_penalty_per_event,
    0,
    constants.max_squirrel_rough_handling_penalty
  )
  local relocation_bonus = clamp(
    recent_relocations * constants.relocation_bonus_per_event,
    0,
    constants.max_relocation_bonus
  )

  region.tree_count = tree_count
  region.sapling_count = sapling_count
  region.nut_tree_count = nut_tree_count
  region.feeder_count = feeder_count
  region.stocked_feeders = stocked_feeders
  region.empty_feeders = empty_feeders
  region.recent_squirrel_deaths = recent_squirrel_deaths
  region.recent_rough_handling = recent_rough_handling
  region.recent_relocations = recent_relocations
  region.canopy_score = round(canopy_score)
  region.nut_tree_bonus = round(nut_tree_bonus)
  region.stocked_feeder_bonus = round(stocked_feeder_bonus)
  region.reforestation_bonus = round(reforestation_bonus)
  region.relocation_bonus = round(relocation_bonus)
  region.empty_feeder_penalty = round(empty_feeder_penalty)
  region.recent_tree_loss_penalty = round(recent_tree_loss_penalty)
  region.squirrel_death_penalty = round(squirrel_death_penalty)
  region.rough_handling_penalty = round(rough_handling_penalty)
  region.rolling_pollution_penalty = round(rolling_pollution_penalty)
  region.forest_health = round(clamp(
    canopy_score + nut_tree_bonus + stocked_feeder_bonus + reforestation_bonus - rolling_pollution_penalty - recent_tree_loss_penalty,
    0,
    100
  ))
  region.squirrel_unrest = round(clamp(
    10
      + recent_tree_loss_penalty
      + squirrel_death_penalty
      + rough_handling_penalty
      + rolling_pollution_penalty
      + empty_feeder_penalty
      - stocked_feeder_bonus
      - (relocation_bonus * 0.8)
      - (reforestation_bonus * 0.35)
      - (region.forest_health * 0.15),
    0,
    100
  ))
  region.squirrel_trust = round(clamp(
    45
      + stocked_feeder_bonus
      + nut_tree_bonus
      + relocation_bonus
      + (reforestation_bonus * 0.5)
      - empty_feeder_penalty
      - squirrel_death_penalty
      - (rough_handling_penalty * 0.75)
      - (recent_tree_loss_penalty * 0.65)
      - (rolling_pollution_penalty * 0.35),
    0,
    100
  ))
  region.habitat_pressure = round(clamp(
    ((100 - region.forest_health) * 0.55)
      + (region.squirrel_unrest * 0.65)
      + empty_feeder_penalty
      + (squirrel_death_penalty * 0.35)
      + (rough_handling_penalty * 0.2)
      - (stocked_feeder_bonus * 0.4)
      - (relocation_bonus * 0.5)
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

function M.region_needs_recompute(region, tick)
  local current_tick = tick or game.tick

  if region.dirty then
    return true
  end

  if not region.last_updated_tick or region.last_updated_tick <= 0 then
    return true
  end

  return (current_tick - region.last_updated_tick) >= constants.region_update_interval
end

function M.ensure_region_recomputed(surface, region_x, region_y, tick)
  local region = get_or_create(surface.index, region_x, region_y)
  if M.region_needs_recompute(region, tick) then
    return M.recompute_region(surface, region_x, region_y, tick)
  end

  return region
end

return M
