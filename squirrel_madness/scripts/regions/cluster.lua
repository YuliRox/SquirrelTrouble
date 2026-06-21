local constants = require("scripts.constants")
local math_ops = require("scripts.regions.math")
local store = require("scripts.regions.store")
local recompute = require("scripts.regions.recompute")

local region_key = math_ops.region_key
local round = math_ops.round
local round_tenths = math_ops.round_tenths
local positive_band = math_ops.positive_band
local unrest_band = math_ops.unrest_band
local pressure_band = math_ops.pressure_band
local cluster_seed_offsets = math_ops.cluster_seed_offsets
local CLUSTER_NEIGHBOR_OFFSETS = math_ops.CLUSTER_NEIGHBOR_OFFSETS

local position_to_region_coord = store.position_to_region_coord
local region_intersects_circle = store.region_intersects_circle
local region_is_cluster_candidate = store.region_is_cluster_candidate
local region_forest_mass = store.region_forest_mass
local region_cluster_weight = store.region_cluster_weight

local ensure_region_recomputed = recompute.ensure_region_recomputed

local M = {}

local function sort_cluster_members(members)
  table.sort(members, function(left, right)
    if left.region_x ~= right.region_x then
      return left.region_x < right.region_x
    end

    return left.region_y < right.region_y
  end)
end

local function find_cluster_seed(surface, anchor_position, tick)
  local anchor = position_to_region_coord(anchor_position)
  local best_region
  local best_distance
  local best_mass = -1

  for _, offset in ipairs(cluster_seed_offsets()) do
    local region_x = anchor.x + offset.dx
    local region_y = anchor.y + offset.dy

    if region_intersects_circle(region_x, region_y, anchor_position, constants.survey_station_exact_radius) then
      local candidate = ensure_region_recomputed(
        surface,
        region_x,
        region_y,
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
  end

  return best_region or ensure_region_recomputed(surface, anchor.x, anchor.y, tick)
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

function M.build_forest_cluster(surface, anchor_position, tick)
  local anchor = position_to_region_coord(anchor_position)
  local seed_region = find_cluster_seed(surface, anchor_position, tick)

  if not region_is_cluster_candidate(seed_region) then
    return aggregate_cluster_report(seed_region, anchor.x, anchor.y, {seed_region})
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

      local within_anchor_limit = math.abs(entry.region_x - anchor.x) <= constants.survey_cluster_search_radius
        and math.abs(entry.region_y - anchor.y) <= constants.survey_cluster_search_radius
      local within_station_range = region_intersects_circle(
        entry.region_x,
        entry.region_y,
        anchor_position,
        constants.survey_station_exact_radius
      )

      if within_anchor_limit and within_station_range then
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

  return aggregate_cluster_report(seed_region, anchor.x, anchor.y, members)
end

return M
