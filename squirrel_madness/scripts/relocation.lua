local constants = require("scripts.constants")
local regions = require("scripts.regions")

local relocation = {}

local function candidate_score(report, origin_region_x, origin_region_y)
  local tree_mass = (report.tree_count or 0) + (report.sapling_count or 0) + (report.nut_tree_count or 0)
  local distance = math.abs(report.region_x - origin_region_x) + math.abs(report.region_y - origin_region_y)

  return (report.forest_health * 2.0)
    + (report.squirrel_trust * 1.25)
    + math.min(tree_mass, 32)
    - (report.habitat_pressure * 1.5)
    - (distance * 6)
end

function relocation.find_destination(surface, origin_position, tick)
  local origin_coord = regions.position_to_region_coord(origin_position)
  local candidates = {}

  for dx = -constants.relocation_search_radius, constants.relocation_search_radius do
    for dy = -constants.relocation_search_radius, constants.relocation_search_radius do
      if dx ~= 0 or dy ~= 0 then
        local region_x = origin_coord.x + dx
        local region_y = origin_coord.y + dy
        local report = regions.get_region_report_by_coord(surface, region_x, region_y, tick)
        local tree_mass = (report.tree_count or 0) + (report.sapling_count or 0) + (report.nut_tree_count or 0)

        if report.forest_health >= constants.relocation_min_forest_health
          and report.habitat_pressure <= constants.relocation_max_habitat_pressure
          and report.squirrel_trust >= constants.relocation_min_trust
          and tree_mass >= constants.relocation_min_tree_count
        then
          candidates[#candidates + 1] = {
            region_x = region_x,
            region_y = region_y,
            forest_health = report.forest_health,
            squirrel_trust = report.squirrel_trust,
            habitat_pressure = report.habitat_pressure,
            tree_mass = tree_mass,
            score = candidate_score(report, origin_coord.x, origin_coord.y)
          }
        end
      end
    end
  end

  table.sort(candidates, function(left, right)
    if left.score ~= right.score then
      return left.score > right.score
    end

    if left.forest_health ~= right.forest_health then
      return left.forest_health > right.forest_health
    end

    if left.region_x ~= right.region_x then
      return left.region_x < right.region_x
    end

    return left.region_y < right.region_y
  end)

  return candidates[1], candidates
end

return relocation
