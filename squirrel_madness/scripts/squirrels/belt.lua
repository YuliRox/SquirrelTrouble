local constants = require("scripts.constants")
local position_ops = require("scripts.squirrels.position")
local storage_ops = require("scripts.squirrels.storage")
local target_ops = require("scripts.squirrels.target")

local round_position_key = position_ops.round_key
local serialize_target = target_ops.serialize_target
local resolve_target_reference = target_ops.resolve_target_reference
local resolve_entity_reference = target_ops.resolve_entity_reference
local get_active_belt_riders = storage_ops.get_active_belt_riders
local get_belt_block_counts = storage_ops.get_belt_block_counts
local get_squirrel_store = storage_ops.get_squirrel_store

-- Keys a belt entity for belt's own belt_block_counts storage. Mirrors the
-- targeting target_key formula so behavior is unchanged, but is computed here
-- so belt depends only on leaf modules and can install before the targeting hub.
local function target_key(entity)
  if entity.unit_number then
    return tostring(entity.unit_number)
  end

  return entity.surface.index .. ":" .. entity.name .. ":" .. round_position_key(entity.position)
end

local M = {}

function M.install(deps)
  local BELT_TYPES = deps.BELT_TYPES
  local direction_to_orientation = deps.direction_to_orientation

  local function belt_direction_vector(direction)
    if direction == defines.direction.north then
      return {x = 0, y = -1}
    end

    if direction == defines.direction.south then
      return {x = 0, y = 1}
    end

    if direction == defines.direction.west then
      return {x = -1, y = 0}
    end

    return {x = 1, y = 0}
  end

  local function belt_perpendicular_vector(direction)
    local forward = belt_direction_vector(direction)
    return {x = -forward.y, y = forward.x}
  end

  local function belt_lane_offset(line_index, squirrel_id)
    local lane_selector = line_index or (((squirrel_id or 1) % 2) + 1)
    if lane_selector % 2 == 0 then
      return constants.squirrel_belt_lane_offset
    end

    return -constants.squirrel_belt_lane_offset
  end

  local function belt_world_position(belt_entity, progress, line_index, squirrel_id)
    local forward = belt_direction_vector(belt_entity.direction)
    local perpendicular = belt_perpendicular_vector(belt_entity.direction)
    local lateral_offset = belt_lane_offset(line_index, squirrel_id)

    return {
      x = belt_entity.position.x + (forward.x * progress) + (perpendicular.x * lateral_offset),
      y = belt_entity.position.y + (forward.y * progress) + (perpendicular.y * lateral_offset)
    }
  end

  local function set_record_belt_rider(record, active)
    if not record then
      return
    end

    local riders = get_active_belt_riders()
    if active then
      riders[record.squirrel_id] = true
    else
      riders[record.squirrel_id] = nil
    end
  end

  local function set_belt_block_state(belt_entity, blocked)
    if not (belt_entity and belt_entity.valid and BELT_TYPES[belt_entity.type]) then
      return
    end

    local counts = get_belt_block_counts()
    local key = target_key(belt_entity)
    local current = counts[key] or 0

    if blocked then
      counts[key] = current + 1
      if current == 0 then
        belt_entity.active = false
      end
      return
    end

    if current <= 1 then
      counts[key] = nil
      belt_entity.active = true
      return
    end

    counts[key] = current - 1
  end

  local function belt_output_entity(belt_entity)
    if not (belt_entity and belt_entity.valid and BELT_TYPES[belt_entity.type]) then
      return nil
    end

    local neighbours = belt_entity.belt_neighbours
    local outputs = neighbours and neighbours.outputs or nil
    if outputs and outputs[1] and outputs[1].valid then
      return outputs[1]
    end

    if belt_entity.type == "underground-belt" and belt_entity.neighbours and belt_entity.neighbours.valid then
      return belt_entity.neighbours
    end

    return nil
  end

  local function clear_belt_ride(record)
    if not (record and record.belt_ride) then
      return
    end

    local belt_entity = resolve_target_reference(record.surface_index, record.belt_ride.belt)
    if belt_entity then
      set_belt_block_state(belt_entity, false)
    end

    record.belt_ride = nil
    set_record_belt_rider(record, false)
  end

  local function refresh_belt_target_from_ride(record, belt_entity)
    if not (record and belt_entity and belt_entity.valid) then
      return
    end

    local current_target = record.target or {}
    record.target = serialize_target(
      belt_entity,
      "belt",
      current_target.item_name,
      current_target.count or 1
    )
    record.target.line_index = current_target.line_index or 1
  end

  local function begin_belt_ride(record, entity, belt_entity, tick)
    if not (record and entity and entity.valid and belt_entity and belt_entity.valid) then
      return
    end

    clear_belt_ride(record)

    record.belt_ride = {
      belt = serialize_target(belt_entity, "belt", nil, 1),
      line_index = record.target and record.target.line_index or 1,
      progress = constants.squirrel_belt_ride_start_progress,
      last_tick = tick
    }
    set_record_belt_rider(record, true)
    set_belt_block_state(belt_entity, true)
    entity.teleport(belt_world_position(
      belt_entity,
      record.belt_ride.progress,
      record.belt_ride.line_index,
      record.squirrel_id
    ))
    refresh_belt_target_from_ride(record, belt_entity)
  end

  local function advance_belt_ride(record, entity, tick)
    if not (record and entity and entity.valid and record.belt_ride) then
      return false
    end

    local ride = record.belt_ride
    local belt_entity = resolve_target_reference(record.surface_index, ride.belt)
    if not (belt_entity and belt_entity.valid and BELT_TYPES[belt_entity.type]) then
      clear_belt_ride(record)
      return false
    end

    local delta = math.max(0, tick - (ride.last_tick or tick))
    local progress = (ride.progress or constants.squirrel_belt_ride_start_progress)
      + (delta * constants.squirrel_belt_ride_speed)

    while progress > constants.squirrel_belt_ride_end_progress do
      local overflow = progress - constants.squirrel_belt_ride_end_progress
      local next_belt = belt_output_entity(belt_entity)
      if not (next_belt and next_belt.valid and BELT_TYPES[next_belt.type]) then
        progress = constants.squirrel_belt_ride_end_progress
        break
      end

      set_belt_block_state(belt_entity, false)
      belt_entity = next_belt
      set_belt_block_state(belt_entity, true)
      ride.belt = serialize_target(belt_entity, "belt", nil, 1)
      progress = constants.squirrel_belt_ride_start_progress + overflow
      refresh_belt_target_from_ride(record, belt_entity)
    end

    ride.progress = progress
    ride.last_tick = tick
    entity.direction = belt_entity.direction
    entity.orientation = direction_to_orientation(belt_entity.direction)
    entity.teleport(belt_world_position(
      belt_entity,
      progress,
      ride.line_index,
      record.squirrel_id
    ))
    return true
  end

  local function remove_belt_item(belt_entity, item_name, count)
    local max_line_index = math.min(belt_entity.get_max_transport_line_index(), constants.squirrel_transport_line_scan_limit)

    for line_index = 1, max_line_index do
      local line = belt_entity.get_transport_line(line_index)

      if line and line.valid then
        local removed = line.remove_item({name = item_name, count = count or 1})
        if removed > 0 then
          return removed
        end
      end
    end

    return 0
  end

  local function advance_active_belt_riders(tick)
    for squirrel_id in pairs(get_active_belt_riders()) do
      local record = get_squirrel_store()[squirrel_id]
      local entity = record and resolve_entity_reference(record.entity) or nil

      if
        record
        and entity
        and entity.valid
        and record.mode == "blocking"
        and record.target
        and record.target.target_type == "belt"
        and record.belt_ride
      then
        advance_belt_ride(record, entity, tick)
      elseif record then
        clear_belt_ride(record)
      else
        get_active_belt_riders()[squirrel_id] = nil
      end
    end
  end

  return {
    clear_belt_ride = clear_belt_ride,
    begin_belt_ride = begin_belt_ride,
    advance_belt_ride = advance_belt_ride,
    remove_belt_item = remove_belt_item,
    advance_active_belt_riders = advance_active_belt_riders
  }
end

return M
