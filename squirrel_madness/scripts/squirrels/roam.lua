local constants = require("scripts.constants")
local math2d = require("math2d")
local position_ops = require("scripts.squirrels.position")

local position_with_offset = position_ops.with_offset

local M = {}

function M.roam_step_distance(record)
  local step_span = math.max(
    0,
    constants.squirrel_roam_step_max_distance - constants.squirrel_roam_step_min_distance
  )
  local distance_seed = (((record.squirrel_id or 1) * 31) + (record.roam_step * 17)) % 100
  return constants.squirrel_roam_step_min_distance + ((distance_seed / 100) * step_span)
end

function M.excursion_step_distance(record, state)
  local step_span = math.max(
    0,
    constants.squirrel_excursion_step_max_distance - constants.squirrel_excursion_step_min_distance
  )
  local distance_seed = (((record.squirrel_id or 1) * 43) + (record.roam_step * 29)) % 100
  local step_distance = constants.squirrel_excursion_step_min_distance + ((distance_seed / 100) * step_span)

  if state == "agitated" then
    step_distance = step_distance + 0.75
  elseif state == "grieving" then
    step_distance = step_distance + 1.25
  elseif state == "mischievous" then
    step_distance = step_distance + 0.4
  end

  return step_distance
end

function M.bounded_roam_destination(record, entity, max_home_distance, preferred_target_position, state)
  local origin = (entity and entity.valid and entity.position) or record.home_position
  local angle_seed = ((record.squirrel_id or 1) * 67) + (record.roam_step * 97)
  local angle = ((angle_seed % 360) / 180) * math.pi
  local step_distance = M.roam_step_distance(record)

  if preferred_target_position then
    angle = math.atan2(
      preferred_target_position.y - origin.y,
      preferred_target_position.x - origin.x
    )
    local jitter_seed = (((record.squirrel_id or 1) * 17) + (record.roam_step * 11)) % 7
    angle = angle + ((jitter_seed - 3) * 0.12)
    step_distance = M.excursion_step_distance(record, state)
  end

  local candidate = position_with_offset(origin, angle, step_distance)
  local allowed_distance = max_home_distance or constants.squirrel_home_wander_distance
  local home_distance = math2d.position.distance(candidate, record.home_position)

  if home_distance > allowed_distance then
    local clamp_angle = math.atan2(
      candidate.y - record.home_position.y,
      candidate.x - record.home_position.x
    )
    candidate = position_with_offset(
      record.home_position,
      clamp_angle,
      math.max(constants.squirrel_home_wander_min_distance, allowed_distance)
    )
  end

  return candidate
end

function M.idle_pause_duration(record)
  local pause_span = math.max(0, constants.squirrel_idle_pause_max - constants.squirrel_idle_pause_min)
  local pause_seed = (((record.squirrel_id or 1) * 19) + ((record.roam_step or 0) * 23)) % (pause_span + 1)
  local base_pause = constants.squirrel_idle_pause_min + pause_seed
  local state = record.state or "calm"
  local multiplier = 1

  if state == "calm" then
    multiplier = 1.8
  elseif state == "curious" then
    multiplier = 1.5
  elseif state == "mischievous" then
    multiplier = 1.15
  elseif state == "agitated" or state == "grieving" then
    multiplier = 0.8
  end

  return math.floor(base_pause * multiplier)
end

return M
