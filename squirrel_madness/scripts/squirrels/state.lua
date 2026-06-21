local constants = require("scripts.constants")
local regions = require("scripts.regions.module")
local storage_ops = require("scripts.squirrels.storage")

local region_key = storage_ops.region_key
local get_surface_region_activity = storage_ops.get_surface_region_activity

local M = {}

function M.get_region_activity(surface_index, region_x, region_y)
  local activities = get_surface_region_activity(surface_index)
  local key = region_key(region_x, region_y)
  activities[key] = activities[key] or {
    last_theft_tick = 0,
    grief_until_tick = 0,
    last_spawn_tick = 0
  }
  return activities[key]
end

function M.region_report(surface_index, region_x, region_y, tick, force_recompute)
  local surface = game.surfaces[surface_index]
  if not surface then
    return nil
  end

  if force_recompute then
    return regions.get_region_report_by_coord(surface, region_x, region_y, tick)
  end

  return regions.get_cached_region_report_by_coord(surface, region_x, region_y)
end

function M.squirrel_state_for_region(surface_index, region_x, region_y, tick, force_recompute)
  local report = M.region_report(surface_index, region_x, region_y, tick, force_recompute)
  if not report then
    return "calm", nil
  end

  local activity = M.get_region_activity(surface_index, region_x, region_y)
  if activity.grief_until_tick > tick then
    return "grieving", report
  end

  if report.habitat_pressure >= constants.squirrel_agitated_pressure or report.squirrel_unrest >= 75 then
    return "agitated", report
  end

  if report.habitat_pressure >= constants.squirrel_mischief_pressure or report.squirrel_unrest >= 45 then
    return "mischievous", report
  end

  if
    report.habitat_pressure >= constants.squirrel_curious_pressure
    or report.recent_tree_loss > 0
    or report.instant_pollution > 0
  then
    return "curious", report
  end

  return "calm", report
end

return M
