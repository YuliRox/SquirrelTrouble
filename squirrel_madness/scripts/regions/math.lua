local constants = require("scripts.constants")

local M = {}

function M.clamp(value, minimum, maximum)
  if value < minimum then
    return minimum
  end

  if value > maximum then
    return maximum
  end

  return value
end

function M.round(value)
  return math.floor(value + 0.5)
end

function M.round_tenths(value)
  return math.floor((value * 10) + 0.5) / 10
end

function M.region_key(region_x, region_y)
  return region_x .. "," .. region_y
end

function M.average(values)
  if #values == 0 then
    return 0
  end

  local total = 0

  for _, value in ipairs(values) do
    total = total + value
  end

  return total / #values
end

function M.positive_band(value)
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

function M.unrest_band(value)
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

function M.pressure_band(value)
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

M.CLUSTER_NEIGHBOR_OFFSETS = {
  {-1, -1},
  {0, -1},
  {1, -1},
  {-1, 0},
  {1, 0},
  {-1, 1},
  {0, 1},
  {1, 1}
}

function M.cluster_seed_offsets()
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

return M
