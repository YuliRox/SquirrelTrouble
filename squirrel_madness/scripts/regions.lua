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

local CLUSTER_NEIGHBOR_OFFSETS = {
  {-1, -1},
  {0, -1},
  {1, -1},
  {-1, 0},
  {1, 0},
  {-1, 1},
  {0, 1},
  {1, 1}
}

local function cluster_seed_offsets()
  local offsets = {}

  for dx = -constants.survey_cluster_seed_search_radius, constants.survey_cluster_seed_search_radius do
    for dy = -constants.survey_cluster_seed_search_radius, constants.survey_cluster_seed_search_radius do
      offsets[#offsets + 1] = {
        dx = dx,
        dy = dy,
        distance_squared = (dx * dx) + (dy * dy)
      }
    end
  end

  table.sort(offsets, function(left, right)
    if left.distance_squared ~= right.distance_squared then
      return left.distance_squared < right.distance_squared
    end

    if left.dx ~= right.dx then
      return left.dx < right.dx
    end

    return left.dy < right.dy
  end)

  return offsets
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

local function region_forest_mass(region)
  return math.max((region.tree_count or 0) + (region.sapling_count or 0), 0)
end

local function region_cluster_weight(region)
  return math.max(region_forest_mass(region), 1)
end

local function region_is_cluster_candidate(region)
  return region_forest_mass(region) >= constants.survey_cluster_min_tree_count
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

local function default_region(surface_index, region_x, region_y)
  return ensure_region_shape({
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

local function get_or_create(surface_index, region_x, region_y)
  local surface_regions = get_surface_regions(surface_index)
  local key = region_key(region_x, region_y)
  surface_regions[key] = surface_regions[key] or default_region(surface_index, region_x, region_y)
  return ensure_region_shape(surface_regions[key], surface_index, region_x, region_y)
end

local function sort_cluster_members(members)
  table.sort(members, function(left, right)
    if left.region_x ~= right.region_x then
      return left.region_x < right.region_x
    end

    return left.region_y < right.region_y
  end)
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

local function note_recent_region_event(surface_index, position, field_name, amount, tick)
  local coord = regions.position_to_region_coord(position)
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

local function find_cluster_seed(surface, anchor_region_x, anchor_region_y, tick)
  local best_region
  local best_distance
  local best_mass = -1

  for _, offset in ipairs(cluster_seed_offsets()) do
    local candidate = ensure_region_recomputed(
      surface,
      anchor_region_x + offset.dx,
      anchor_region_y + offset.dy,
      tick
    )

    if region_is_cluster_candidate(candidate) then
      local mass = region_forest_mass(candidate)

      if not best_region
        or offset.distance_squared < best_distance
        or (offset.distance_squared == best_distance and mass > best_mass)
      then
        best_region = candidate
        best_distance = offset.distance_squared
        best_mass = mass
      end
    end
  end

  return best_region or ensure_region_recomputed(surface, anchor_region_x, anchor_region_y, tick)
end

local function aggregate_cluster_report(seed_region, anchor_region_x, anchor_region_y, members)
  local report = {
    scope = "cluster",
    anchor_region_x = anchor_region_x,
    anchor_region_y = anchor_region_y,
    seed_region_x = seed_region.region_x,
    seed_region_y = seed_region.region_y,
    region_count = 0,
    member_regions = {},
    tree_count = 0,
    sapling_count = 0,
    nut_tree_count = 0,
    feeder_count = 0,
    stocked_feeders = 0,
    empty_feeders = 0,
    recent_tree_loss = 0,
    rolling_pollution = 0,
    instant_pollution = 0,
    canopy_score = 0,
    nut_tree_bonus = 0,
    stocked_feeder_bonus = 0,
    reforestation_bonus = 0,
    empty_feeder_penalty = 0,
    recent_tree_loss_penalty = 0,
    rolling_pollution_penalty = 0,
    drivers = {}
  }
  local total_weight = 0
  local unique_drivers = {}
  local min_region_x
  local max_region_x
  local min_region_y
  local max_region_y
  local forest_health_total = 0
  local squirrel_unrest_total = 0
  local squirrel_trust_total = 0
  local habitat_pressure_total = 0

  for _, region in ipairs(members) do
    local weight = region_cluster_weight(region)
    total_weight = total_weight + weight
    report.region_count = report.region_count + 1
    report.member_regions[#report.member_regions + 1] = {
      region_x = region.region_x,
      region_y = region.region_y
    }
    min_region_x = min_region_x and math.min(min_region_x, region.region_x) or region.region_x
    max_region_x = max_region_x and math.max(max_region_x, region.region_x) or region.region_x
    min_region_y = min_region_y and math.min(min_region_y, region.region_y) or region.region_y
    max_region_y = max_region_y and math.max(max_region_y, region.region_y) or region.region_y

    report.tree_count = report.tree_count + (region.tree_count or 0)
    report.sapling_count = report.sapling_count + (region.sapling_count or 0)
    report.nut_tree_count = report.nut_tree_count + (region.nut_tree_count or 0)
    report.feeder_count = report.feeder_count + (region.feeder_count or 0)
    report.stocked_feeders = report.stocked_feeders + (region.stocked_feeders or 0)
    report.empty_feeders = report.empty_feeders + (region.empty_feeders or 0)
    report.recent_tree_loss = report.recent_tree_loss + (region.recent_tree_loss or 0)

    report.rolling_pollution = report.rolling_pollution + ((region.pollution or 0) * weight)
    report.instant_pollution = report.instant_pollution + ((region.instant_pollution or 0) * weight)
    report.canopy_score = report.canopy_score + ((region.canopy_score or 0) * weight)
    report.nut_tree_bonus = report.nut_tree_bonus + ((region.nut_tree_bonus or 0) * weight)
    report.stocked_feeder_bonus = report.stocked_feeder_bonus + ((region.stocked_feeder_bonus or 0) * weight)
    report.reforestation_bonus = report.reforestation_bonus + ((region.reforestation_bonus or 0) * weight)
    report.empty_feeder_penalty = report.empty_feeder_penalty + ((region.empty_feeder_penalty or 0) * weight)
    report.recent_tree_loss_penalty = report.recent_tree_loss_penalty + ((region.recent_tree_loss_penalty or 0) * weight)
    report.rolling_pollution_penalty = report.rolling_pollution_penalty + ((region.rolling_pollution_penalty or 0) * weight)

    forest_health_total = forest_health_total + ((region.forest_health or 0) * weight)
    squirrel_unrest_total = squirrel_unrest_total + ((region.squirrel_unrest or 0) * weight)
    squirrel_trust_total = squirrel_trust_total + ((region.squirrel_trust or 0) * weight)
    habitat_pressure_total = habitat_pressure_total + ((region.habitat_pressure or 0) * weight)

    for _, driver in ipairs(region.drivers or {}) do
      unique_drivers[driver] = true
    end
  end

  sort_cluster_members(report.member_regions)

  for driver in pairs(unique_drivers) do
    report.drivers[#report.drivers + 1] = driver
  end
  table.sort(report.drivers)

  total_weight = math.max(total_weight, 1)
  report.forest_health = round(forest_health_total / total_weight)
  report.squirrel_unrest = round(squirrel_unrest_total / total_weight)
  report.squirrel_trust = round(squirrel_trust_total / total_weight)
  report.habitat_pressure = round(habitat_pressure_total / total_weight)
  report.rolling_pollution = round_tenths(report.rolling_pollution / total_weight)
  report.instant_pollution = round_tenths(report.instant_pollution / total_weight)
  report.canopy_score = round(report.canopy_score / total_weight)
  report.nut_tree_bonus = round(report.nut_tree_bonus / total_weight)
  report.stocked_feeder_bonus = round(report.stocked_feeder_bonus / total_weight)
  report.reforestation_bonus = round(report.reforestation_bonus / total_weight)
  report.empty_feeder_penalty = round(report.empty_feeder_penalty / total_weight)
  report.recent_tree_loss_penalty = round(report.recent_tree_loss_penalty / total_weight)
  report.rolling_pollution_penalty = round(report.rolling_pollution_penalty / total_weight)
  report.recent_tree_loss = round_tenths(report.recent_tree_loss)
  report.forest_health_band = positive_band(report.forest_health)
  report.squirrel_unrest_band = unrest_band(report.squirrel_unrest)
  report.squirrel_trust_band = positive_band(report.squirrel_trust)
  report.habitat_pressure_band = pressure_band(report.habitat_pressure)
  report.bounds = {
    min_region_x = min_region_x,
    max_region_x = max_region_x,
    min_region_y = min_region_y,
    max_region_y = max_region_y
  }

  return report
end

local function build_forest_cluster(surface, anchor_region_x, anchor_region_y, tick)
  local seed_region = find_cluster_seed(surface, anchor_region_x, anchor_region_y, tick)

  if not region_is_cluster_candidate(seed_region) then
    return aggregate_cluster_report(seed_region, anchor_region_x, anchor_region_y, {seed_region})
  end

  local members = {}
  local queue = {{
    region_x = seed_region.region_x,
    region_y = seed_region.region_y
  }}
  local read_index = 1
  local visited = {}

  while read_index <= #queue do
    local entry = queue[read_index]
    read_index = read_index + 1
    local key = region_key(entry.region_x, entry.region_y)

    if not visited[key] then
      visited[key] = true

      local within_anchor_limit = math.abs(entry.region_x - anchor_region_x) <= constants.survey_cluster_search_radius
        and math.abs(entry.region_y - anchor_region_y) <= constants.survey_cluster_search_radius

      if within_anchor_limit then
        local region = ensure_region_recomputed(surface, entry.region_x, entry.region_y, tick)

        if region_is_cluster_candidate(region) then
          members[#members + 1] = region

          for _, neighbor in ipairs(CLUSTER_NEIGHBOR_OFFSETS) do
            queue[#queue + 1] = {
              region_x = entry.region_x + neighbor[1],
              region_y = entry.region_y + neighbor[2]
            }
          end
        end
      end
    end
  end

  if #members == 0 then
    members[1] = seed_region
  end

  return aggregate_cluster_report(seed_region, anchor_region_x, anchor_region_y, members)
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

function regions.get_forest_cluster_report_at_position(surface, position, tick)
  local coord = regions.position_to_region_coord(position)
  return build_forest_cluster(surface, coord.x, coord.y, tick)
end

function regions.get_forest_cluster_report_by_coord(surface, region_x, region_y, tick)
  return build_forest_cluster(surface, region_x, region_y, tick)
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

return regions
