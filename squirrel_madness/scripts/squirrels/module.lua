local constants = require("scripts.constants")
local regions = require("scripts.regions.module")
local math2d = require("math2d")
local flee_module = require("scripts.squirrels.flee")
local position_ops = require("scripts.squirrels.position")
local storage_ops = require("scripts.squirrels.storage")
local targeting_module = require("scripts.squirrels.targeting")
local render_ops = require("scripts.squirrels.render")
local carrying_module = require("scripts.squirrels.carrying")
local stash_module = require("scripts.squirrels.stash")

local squirrels = {}

local BELT_TYPES = {
  ["transport-belt"] = true,
  ["underground-belt"] = true,
  splitter = true
}

local CHEST_TYPES = {
  container = true,
  ["logistic-container"] = true
}

local stop_entity
local process_idle_decision
local theft_is_available
local start_target_run
local target_key
local serialize_target
local resolve_target_reference
local destroy_render
local sync_render
local direction_to_orientation
local note_target_cooldown
local item_desirability
local choose_belt_item
local choose_chest_item
local find_stocked_feeder_near_position
local state_wander_distance
local state_local_target_radius
local find_local_target
local find_excursion_target
local find_nearby_belt_target
local maybe_commit_roam_target

local function is_squirrel_entity_name(name)
  return constants.squirrel_entity_names[name] == true
end

local function is_squirrel_entity(entity)
  return entity and entity.valid and is_squirrel_entity_name(entity.name)
end

local clone_position = position_ops.clone
local round_position_key = position_ops.round_key
local nearest_player_distance_squared = position_ops.nearest_player_distance_squared
local player_position_for_index = position_ops.player_position_for_index
local position_respects_player_buffer = position_ops.position_respects_player_buffer
local position_with_offset = position_ops.with_offset
local reached_position = position_ops.reached_position

local region_key = storage_ops.region_key
local parse_region_key = storage_ops.parse_region_key
local active_region_key = storage_ops.active_region_key

local function ensure_squirrel_force()
  local force = game.forces[constants.squirrel_force_name]
  if not force then
    force = game.create_force(constants.squirrel_force_name)
  end

  for _, other_force in pairs(game.forces) do
    if other_force.valid and other_force.name ~= force.name then
      local allied = other_force.name == "enemy" or other_force.name == "neutral"
      force.set_friend(other_force, allied)
      other_force.set_friend(force, allied)
      force.set_cease_fire(other_force, allied)
      other_force.set_cease_fire(force, allied)
    end
  end

  return force
end

local get_squirrel_store = storage_ops.get_squirrel_store
local next_squirrel_id = storage_ops.next_squirrel_id
local get_surface_stashes = storage_ops.get_surface_stashes
local next_stash_id = storage_ops.next_stash_id
local get_surface_region_activity = storage_ops.get_surface_region_activity
local get_surface_region_index = storage_ops.get_surface_region_index
local get_region_squirrel_entry = storage_ops.get_region_squirrel_entry
local get_entity_squirrel_index = storage_ops.get_entity_squirrel_index
local get_surface_stashes_by_region = storage_ops.get_surface_stashes_by_region
local get_region_stash_entry = storage_ops.get_region_stash_entry
local get_stash_target_counts = storage_ops.get_stash_target_counts
local get_target_cooldowns = storage_ops.get_target_cooldowns
local get_active_belt_riders = storage_ops.get_active_belt_riders
local get_ignored_removals = storage_ops.get_ignored_removals
local get_belt_block_counts = storage_ops.get_belt_block_counts

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

local function get_region_activity(surface_index, region_x, region_y)
  local activities = get_surface_region_activity(surface_index)
  local key = region_key(region_x, region_y)
  activities[key] = activities[key] or {
    last_theft_tick = 0,
    grief_until_tick = 0,
    last_spawn_tick = 0
  }
  return activities[key]
end

local function resolve_entity_reference(entity)
  if not (entity and entity.valid) then
    return nil
  end

  return entity
end

local function resolve_entity_by_unit_number(unit_number)
  if not unit_number then
    return nil
  end

  return game.get_entity_by_unit_number(unit_number)
end

direction_to_orientation = render_ops.direction_to_orientation

local function replace_record_entity(record, replacement)
  if not (record and replacement and replacement.valid and replacement.unit_number) then
    return nil
  end

  local old_unit_number = record.entity_unit_number
  if old_unit_number then
    get_entity_squirrel_index()[old_unit_number] = nil
  end

  record.entity = replacement
  record.entity_unit_number = replacement.unit_number
  get_entity_squirrel_index()[replacement.unit_number] = record.squirrel_id
  return replacement
end

local function ensure_entity_variant(record, desired_name, direction)
  local entity = record and resolve_entity_reference(record.entity) or nil
  if not (record and entity and entity.valid) then
    return nil
  end

  if entity.name == desired_name then
    if direction ~= nil then
      entity.direction = direction
      entity.orientation = direction_to_orientation(direction)
    end
    return entity
  end

  destroy_render(record)

  local replacement = entity.surface.create_entity({
    name = desired_name,
    position = entity.position,
    force = entity.force,
    create_build_effect_smoke = false,
    spawn_decorations = false
  })
  if not (replacement and replacement.valid) then
    return entity
  end

  replacement.health = math.min(entity.health or replacement.health, replacement.max_health or replacement.health)
  replacement.direction = direction or entity.direction
  replacement.orientation = direction_to_orientation(direction or entity.direction)

  if entity.unit_number then
    get_ignored_removals()[entity.unit_number] = true
  end

  replace_record_entity(record, replacement)
  entity.destroy()
  sync_render(record, replacement)
  return replacement
end

serialize_target = function(entity, target_type, item_name, count)
  if not (entity and entity.valid) then
    return nil
  end

  return {
    target_type = target_type,
    entity = entity,
    unit_number = entity.unit_number,
    name = entity.name,
    position = clone_position(entity.position),
    item_name = item_name,
    count = count or 1
  }
end

resolve_target_reference = function(surface_index, target)
  if not target then
    return nil
  end

  local entity = resolve_entity_reference(target.entity)
  if entity then
    return entity
  end

  entity = resolve_entity_by_unit_number(target.unit_number)
  if entity and entity.valid then
    return entity
  end

  local surface = game.surfaces[surface_index]
  if not surface then
    return nil
  end

  local matches = surface.find_entities_filtered({
    position = target.position,
    name = target.name,
    limit = 1
  })

  return matches[1]
end

local function resolve_target(record)
  return resolve_target_reference(record.surface_index, record.target)
end

local function set_excursion_focus(record, target, intent)
  record.excursion_target = target and {
    target_type = target.target_type,
    item_name = target.item_name,
    count = target.count,
    position = target.position and clone_position(target.position) or nil,
    entity = target.entity,
    unit_number = target.unit_number,
    name = target.name
  } or nil
  record.excursion_intent = target and intent or nil
end

destroy_render = render_ops.destroy_render

sync_render = render_ops.sync_render

local stash_ops = stash_module.install({
  resolve_entity_reference = resolve_entity_reference
})

local set_record_stash = stash_ops.set_record_stash
local inventory_total_count = stash_ops.inventory_total_count
local ensure_stash = stash_ops.ensure_stash

squirrels.cleanup_empty_stashes = stash_ops.cleanup_empty_stashes

local function index_record(record)
  if not record then
    return
  end

  local region_entry = get_region_squirrel_entry(record.surface_index, record.region_x, record.region_y)
  if not region_entry.ids[record.squirrel_id] then
    region_entry.ids[record.squirrel_id] = true
    region_entry.count = region_entry.count + 1
  end

  if record.entity_unit_number then
    get_entity_squirrel_index()[record.entity_unit_number] = record.squirrel_id
  end

  if record.stash_id then
    local target_counts = get_stash_target_counts()
    target_counts[record.stash_id] = (target_counts[record.stash_id] or 0) + 1
  end
end

local function unindex_record(record)
  if not record then
    return
  end

  local surface_index = record.surface_index
  local region_x = record.region_x
  local region_y = record.region_y
  local region_entry = get_region_squirrel_entry(surface_index, region_x, region_y)

  if region_entry.ids[record.squirrel_id] then
    region_entry.ids[record.squirrel_id] = nil
    region_entry.count = math.max(0, region_entry.count - 1)
  end

  if region_entry.count == 0 then
    get_surface_region_index(surface_index)[region_key(region_x, region_y)] = nil
  end

  if record.entity_unit_number then
    get_entity_squirrel_index()[record.entity_unit_number] = nil
  end

  set_record_stash(record, nil)
end

local function remove_record(squirrel_id)
  local records = get_squirrel_store()
  local record = records[squirrel_id]
  if not record then
    return
  end

  clear_belt_ride(record)
  destroy_render(record)
  unindex_record(record)
  records[squirrel_id] = nil
end

local function region_report(surface_index, region_x, region_y, tick, force_recompute)
  local surface = game.surfaces[surface_index]
  if not surface then
    return nil
  end

  if force_recompute then
    return regions.get_region_report_by_coord(surface, region_x, region_y, tick)
  end

  return regions.get_cached_region_report_by_coord(surface, region_x, region_y)
end

local function can_spawn_at(surface, position, force, minimum_player_distance)
  return position_respects_player_buffer(surface.index, position, minimum_player_distance)
    and surface.can_place_entity({
    name = constants.names.squirrel,
    position = position,
    force = force
  })
end

local function spawn_position_near_anchor(surface, anchor, radius, force, minimum_player_distance)
  if can_spawn_at(surface, anchor, force, minimum_player_distance) then
    return clone_position(anchor)
  end

  local max_radius = radius or 8

  for current_radius = 0.5, max_radius, 0.5 do
    local samples = math.max(8, math.floor((current_radius * math.pi * 2) / 0.5))

    for sample = 1, samples do
      local angle = (sample / samples) * math.pi * 2
      local candidate = {
        x = anchor.x + (math.cos(angle) * current_radius),
        y = anchor.y + (math.sin(angle) * current_radius)
      }

      if can_spawn_at(surface, candidate, force, minimum_player_distance) then
        return candidate
      end
    end
  end

  local fallback = surface.find_non_colliding_position(constants.names.squirrel, anchor, max_radius, 0.5, false)
  if fallback and position_respects_player_buffer(surface.index, fallback, minimum_player_distance) then
    return fallback
  end

  return nil
end

local function region_search_anchors(area)
  local center = {
    x = (area.left_top.x + area.right_bottom.x) / 2,
    y = (area.left_top.y + area.right_bottom.y) / 2
  }

  return {
    center,
    {x = area.left_top.x + 8, y = area.left_top.y + 8},
    {x = area.right_bottom.x - 8, y = area.left_top.y + 8},
    {x = area.left_top.x + 8, y = area.right_bottom.y - 8},
    {x = area.right_bottom.x - 8, y = area.right_bottom.y - 8},
    {x = center.x, y = area.left_top.y + 10},
    {x = center.x, y = area.right_bottom.y - 10},
    {x = area.left_top.x + 10, y = center.y},
    {x = area.right_bottom.x - 10, y = center.y}
  }
end

local function squirrel_state_for_region(surface_index, region_x, region_y, tick, force_recompute)
  local report = region_report(surface_index, region_x, region_y, tick, force_recompute)
  if not report then
    return "calm", nil
  end

  local activity = get_region_activity(surface_index, region_x, region_y)
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

local function squirrel_population_target(report)
  if not report then
    return 0
  end

  if report.tree_count < constants.squirrel_min_tree_count or report.forest_health < constants.squirrel_min_forest_health then
    return 0
  end

  local target = 1 + math.floor(
    math.max(report.tree_count - constants.squirrel_min_tree_count, 0)
      / constants.squirrel_tree_count_per_population_step
  )
  if
    report.tree_count >= constants.squirrel_stable_tree_count
    or report.forest_health >= 25
    or report.squirrel_trust >= 35
  then
    target = target + 1
  end

  if
    report.tree_count >= constants.squirrel_dense_tree_count
    or report.forest_health >= 40
    or report.squirrel_trust >= 50
  then
    target = target + 1
  end

  if report.habitat_pressure >= 40 or report.squirrel_unrest >= 35 then
    target = target + 1
  end

  if report.habitat_pressure >= 60 or report.squirrel_unrest >= 55 then
    target = target + 1
  end

  return math.min(target, constants.max_visible_squirrels_per_region)
end

local function chunk_area(chunk_position)
  local left = chunk_position.x * constants.chunk_size
  local top = chunk_position.y * constants.chunk_size

  return {
    left_top = {x = left, y = top},
    right_bottom = {
      x = left + constants.chunk_size,
      y = top + constants.chunk_size
    }
  }
end

local function move_entity(entity, destination)
  if not (entity and entity.valid) then
    return false
  end

  local commandable = entity.commandable
  if not commandable then
    error(("Expected squirrel entity '%s' to be commandable"):format(entity.name))
  end

  commandable.set_command({
    type = defines.command.go_to_location,
    destination = destination,
    radius = 0.8,
    distraction = defines.distraction.none
  })

  return true
end

function stop_entity(entity)
  if not (entity and entity.valid) then
    return
  end

  local commandable = entity.commandable
  if not commandable then
    error(("Expected squirrel entity '%s' to be commandable"):format(entity.name))
  end

  commandable.set_command({
    type = defines.command.stop,
    distraction = defines.distraction.none
  })
end

local flee_ops = flee_module.install({
  clone_position = clone_position,
  player_position_for_index = player_position_for_index,
  position_with_offset = position_with_offset,
  ensure_entity_variant = ensure_entity_variant,
  clear_belt_ride = clear_belt_ride,
  set_excursion_focus = set_excursion_focus,
  stop_entity = stop_entity,
  sync_render = sync_render,
  move_entity = move_entity
})

local squirrel_fear_is_active = flee_ops.squirrel_fear_is_active
local clear_squirrel_fear = flee_ops.clear_squirrel_fear
local current_fear_position = flee_ops.current_fear_position
local set_squirrel_fear = flee_ops.set_squirrel_fear
local flee_is_stuck = flee_ops.flee_is_stuck
local start_flee = flee_ops.start_flee

local function roam_step_distance(record)
  local step_span = math.max(
    0,
    constants.squirrel_roam_step_max_distance - constants.squirrel_roam_step_min_distance
  )
  local distance_seed = (((record.squirrel_id or 1) * 31) + (record.roam_step * 17)) % 100
  return constants.squirrel_roam_step_min_distance + ((distance_seed / 100) * step_span)
end

local function excursion_step_distance(record, state)
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

local function bounded_roam_destination(record, entity, max_home_distance, preferred_target_position, state)
  local origin = (entity and entity.valid and entity.position) or record.home_position
  local angle_seed = ((record.squirrel_id or 1) * 67) + (record.roam_step * 97)
  local angle = ((angle_seed % 360) / 180) * math.pi
  local step_distance = roam_step_distance(record)

  if preferred_target_position then
    angle = math.atan2(
      preferred_target_position.y - origin.y,
      preferred_target_position.x - origin.x
    )
    local jitter_seed = (((record.squirrel_id or 1) * 17) + (record.roam_step * 11)) % 7
    angle = angle + ((jitter_seed - 3) * 0.12)
    step_distance = excursion_step_distance(record, state)
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

local function idle_pause_duration(record)
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

local function enter_idle(record, entity, tick)
  entity = ensure_entity_variant(record, constants.names.squirrel) or entity
  clear_belt_ride(record)
  record.mode = "idle"
  record.intent = nil
  record.target = nil
  set_excursion_focus(record, nil, nil)
  record.feeder_nibbles_remaining = nil
  record.destination = nil
  record.arrival_distance = nil
  record.action_due_tick = tick + idle_pause_duration(record)
  record.next_decision_tick = record.action_due_tick
  stop_entity(entity)
  sync_render(record, entity)
end

local function send_home(record, entity, tick)
  entity = ensure_entity_variant(record, constants.names.squirrel) or entity
  clear_belt_ride(record)
  record.mode = "roam"
  record.target = nil
  record.intent = nil
  set_excursion_focus(record, nil, nil)
  set_record_stash(record, nil)
  record.feeder_nibbles_remaining = nil
  record.destination = clone_position(record.home_position)
  record.arrival_distance = 0.8
  record.action_due_tick = tick + constants.squirrel_move_timeout
  record.next_decision_tick = tick + constants.squirrel_decision_interval
  move_entity(entity, record.home_position)
  sync_render(record, entity)
end

local carrying_ops = carrying_module.install({
  sync_render = sync_render,
  ensure_stash = ensure_stash
})

local clear_carrying = carrying_ops.clear_carrying
local carrying_stack_size = carrying_ops.carrying_stack_size
local carrying_count = carrying_ops.carrying_count
local carrying_remaining_capacity = carrying_ops.carrying_remaining_capacity
local deposit_or_spill = carrying_ops.deposit_or_spill
local set_carrying = carrying_ops.set_carrying

local function region_from_record(record)
  return get_region_activity(record.surface_index, record.region_x, record.region_y)
end

theft_is_available = function(record, tick)
  if tick < (record.last_action_tick + constants.squirrel_action_cooldown) then
    return false
  end

  local activity = region_from_record(record)
  return tick >= (activity.last_theft_tick + constants.squirrel_region_action_cooldown)
end

local function start_retreat(record, entity, tick)
  local stash = ensure_stash(record, record.carrying, record.home_position)
  clear_belt_ride(record)
  record.mode = "retreat"
  record.intent = "deposit"
  set_excursion_focus(record, nil, nil)
  record.feeder_nibbles_remaining = nil
  record.target = stash and serialize_target(stash, "stash") or nil
  record.destination = stash and clone_position(stash.position) or clone_position(record.home_position)
  record.arrival_distance = 0.8
  record.blocking_until_tick = nil
  record.action_due_tick = tick + constants.squirrel_move_timeout
  record.next_decision_tick = tick + constants.squirrel_decision_interval
  move_entity(entity, record.destination)
  sync_render(record, entity)
end

local function start_roam(record, entity, tick, state, report, preferred_target, preferred_intent)
  entity = ensure_entity_variant(record, constants.names.squirrel) or entity
  clear_belt_ride(record)
  record.roam_step = (record.roam_step or 0) + 1
  local destination = bounded_roam_destination(
    record,
    entity,
    state_wander_distance(state or record.state or "calm", report),
    preferred_target and preferred_target.position or nil,
    state or record.state
  )

  local surface = game.surfaces[record.surface_index]
  if surface then
    destination = surface.find_non_colliding_position(constants.names.squirrel, destination, 4, 0.5, true) or destination
  end

  record.mode = "roam"
  record.intent = nil
  record.target = nil
  set_excursion_focus(record, preferred_target, preferred_intent)
  record.feeder_nibbles_remaining = nil
  record.destination = clone_position(destination)
  record.arrival_distance = 0.8
  record.blocking_until_tick = nil
  record.action_due_tick = tick + constants.squirrel_move_timeout
  record.next_decision_tick = tick + constants.squirrel_decision_interval
  move_entity(entity, destination)
end

start_target_run = function(record, entity, target, intent, tick)
  entity = ensure_entity_variant(record, constants.names.squirrel) or entity
  clear_belt_ride(record)
  record.mode = "approach"
  record.intent = intent
  record.target = target
  set_excursion_focus(record, nil, nil)
  record.feeder_nibbles_remaining = nil
  record.destination = clone_position(target.position)
  record.arrival_distance = target.target_type == "belt" and 0.18 or 0.45
  record.blocking_until_tick = nil
  record.action_due_tick = tick + constants.squirrel_move_timeout
  record.next_decision_tick = tick + constants.squirrel_decision_interval
  move_entity(entity, target.position)
end

local targeting_ops = targeting_module.install({
  BELT_TYPES = BELT_TYPES,
  CHEST_TYPES = CHEST_TYPES,
  round_position_key = round_position_key,
  get_target_cooldowns = get_target_cooldowns,
  serialize_target = serialize_target,
  resolve_target_reference = resolve_target_reference,
  theft_is_available = theft_is_available,
  start_target_run = start_target_run,
  squirrel_state_for_region = squirrel_state_for_region,
  reached_position = reached_position,
  set_excursion_focus = set_excursion_focus
})

target_key = targeting_ops.target_key
note_target_cooldown = targeting_ops.note_target_cooldown
item_desirability = targeting_ops.item_desirability
choose_belt_item = targeting_ops.choose_belt_item
choose_chest_item = targeting_ops.choose_chest_item
find_stocked_feeder_near_position = targeting_ops.find_stocked_feeder_near_position
state_wander_distance = targeting_ops.state_wander_distance
state_local_target_radius = targeting_ops.state_local_target_radius
find_local_target = targeting_ops.find_local_target
find_excursion_target = targeting_ops.find_excursion_target
find_nearby_belt_target = targeting_ops.find_nearby_belt_target
maybe_commit_roam_target = targeting_ops.maybe_commit_roam_target

local function feeder_nibble_target(report)
  local habitat_pressure = report and report.habitat_pressure or 0
  return math.max(1, 1 + math.floor(habitat_pressure / 35))
end

local function start_feeder_visit(record, entity, feeder_entity, tick)
  entity = ensure_entity_variant(record, constants.names.squirrel) or entity
  local _, report = squirrel_state_for_region(record.surface_index, record.region_x, record.region_y, tick)

  clear_belt_ride(record)
  record.mode = "blocking"
  record.intent = "feed"
  record.target = serialize_target(feeder_entity, "feeder", constants.names.nut, 1)
  set_excursion_focus(record, nil, nil)
  record.feeder_nibbles_remaining = feeder_nibble_target(report)
  record.destination = nil
  record.arrival_distance = nil
  record.blocking_until_tick = tick + constants.squirrel_feeder_visit_duration
  record.action_due_tick = tick
  record.next_decision_tick = tick + constants.squirrel_decision_interval
  stop_entity(entity)
end

local function start_belt_block(record, entity, belt_entity, tick)
  local intent = record.intent or "steal"
  local line_index = record.target and record.target.line_index or 1
  clear_belt_ride(record)
  record.mode = "blocking"
  record.intent = intent
  record.target = serialize_target(belt_entity, "belt", record.target and record.target.item_name or nil, 1)
  record.target.line_index = line_index
  set_excursion_focus(record, nil, nil)
  record.feeder_nibbles_remaining = nil
  record.destination = nil
  record.arrival_distance = nil
  record.blocking_until_tick = tick + (
    intent == "inspect"
      and constants.squirrel_belt_inspect_duration
      or constants.squirrel_belt_block_duration
  )
  record.action_due_tick = intent == "inspect" and record.blocking_until_tick or tick
  record.next_decision_tick = tick + constants.squirrel_decision_interval
  begin_belt_ride(record, entity, belt_entity, tick)
  entity = ensure_entity_variant(record, constants.names.squirrel_sitting, belt_entity.direction) or entity
  stop_entity(entity)
  sync_render(record, entity)
  return entity
end

local function perform_feeder_visit(record, entity, tick)
  local feeder = resolve_target(record)
  if not (feeder and feeder.valid) then
    send_home(record, entity, tick)
    return
  end

  local inventory = feeder.get_inventory(defines.inventory.chest)
  local nut_count = inventory and inventory.valid and inventory.get_item_count(constants.names.nut) or 0
  if nut_count <= 0 or tick >= (record.blocking_until_tick or tick) then
    send_home(record, entity, tick)
    return
  end

  if (record.feeder_nibbles_remaining or 0) <= 0 then
    send_home(record, entity, tick)
    return
  end

  inventory.remove({name = constants.names.nut, count = 1})
  regions.mark_dirty(record.surface_index, feeder.position)
  record.feeder_nibbles_remaining = math.max(0, (record.feeder_nibbles_remaining or 0) - 1)

  if record.feeder_nibbles_remaining <= 0 then
    send_home(record, entity, tick)
    return
  end

  record.mode = "blocking"
  record.intent = "feed"
  record.destination = nil
  record.arrival_distance = nil
  record.action_due_tick = tick + constants.squirrel_feeder_nibble_interval
  stop_entity(entity)
end

local function finish_belt_inspection(record, entity, tick)
  local belt_entity = resolve_target(record)
  if belt_entity and belt_entity.valid then
    note_target_cooldown(belt_entity, tick)
  end

  send_home(record, entity, tick)
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

local function perform_belt_theft(record, entity, tick)
  local belt_entity = resolve_target(record)
  local item_name = record.target and record.target.item_name
  if not (belt_entity and belt_entity.valid and item_name) then
    if record.carrying then
      start_retreat(record, entity, tick)
    else
      send_home(record, entity, tick)
    end
    return false
  end

  local feeder = find_stocked_feeder_near_position(
    record.surface_index,
    belt_entity.position,
    constants.squirrel_feeder_peace_radius
  )
  if feeder then
    note_target_cooldown(belt_entity, tick)
    if record.carrying then
      start_retreat(record, entity, tick)
    else
      start_feeder_visit(record, entity, feeder, tick)
    end
    return false
  end

  local remaining_capacity = carrying_remaining_capacity(record, item_name)
  if remaining_capacity <= 0 then
    note_target_cooldown(belt_entity, tick)
    start_retreat(record, entity, tick)
    return true
  end

  local removed = remove_belt_item(
    belt_entity,
    item_name,
    math.min(constants.squirrel_belt_grab_amount, remaining_capacity)
  )
  if removed <= 0 then
    local report = region_report(record.surface_index, record.region_x, record.region_y, tick)
    local replacement = find_nearby_belt_target(record, record.state, report, tick, entity.position, item_name)
    if replacement then
      record.target = replacement
      record.mode = "blocking"
      record.intent = "steal"
      record.destination = nil
      record.arrival_distance = nil
      record.action_due_tick = tick + constants.squirrel_belt_grab_interval
      stop_entity(entity)
      return false
    end

    if record.carrying then
      note_target_cooldown(belt_entity, tick)
      start_retreat(record, entity, tick)
    else
      send_home(record, entity, tick)
    end
    return false
  end

  local started_empty_handed = not record.carrying
  set_carrying(record, entity, item_name, removed)

  if started_empty_handed then
    record.last_action_tick = tick
    local activity = region_from_record(record)
    activity.last_theft_tick = tick
  end

  if carrying_remaining_capacity(record, item_name) <= 0 or tick >= (record.blocking_until_tick or tick) then
    note_target_cooldown(belt_entity, tick)
    start_retreat(record, entity, tick)
    return true
  end

  record.mode = "blocking"
  record.intent = "steal"
  record.destination = nil
  record.arrival_distance = nil
  record.action_due_tick = tick + constants.squirrel_belt_grab_interval
  stop_entity(entity)
  return true
end

local function perform_chest_scavenge(record, entity, tick)
  local chest = resolve_target(record)
  local item_name = record.target and record.target.item_name
  local count = (record.target and record.target.count) or 1
  if not (chest and chest.valid and item_name) then
    send_home(record, entity, tick)
    return false
  end

  local inventory = chest.get_inventory(defines.inventory.chest)
  if not (inventory and inventory.valid) then
    send_home(record, entity, tick)
    return false
  end

  local removed = inventory.remove({name = item_name, count = count})
  if removed <= 0 then
    send_home(record, entity, tick)
    return false
  end

  set_carrying(record, entity, item_name, removed)
  record.last_action_tick = tick
  note_target_cooldown(chest, tick)
  local activity = region_from_record(record)
  activity.last_theft_tick = tick
  start_retreat(record, entity, tick)
  return true
end

local function select_spawn_tree(surface_index, trees, existing_count)
  local best = {}

  for _, tree in ipairs(trees) do
    if tree and tree.valid then
      local entry = {
        tree = tree,
        distance = nearest_player_distance_squared(surface_index, tree.position) or math.huge
      }
      local inserted = false

      for index = 1, #best do
        if entry.distance > best[index].distance then
          table.insert(best, index, entry)
          inserted = true
          break
        end
      end

      if not inserted and #best < 4 then
        best[#best + 1] = entry
      elseif inserted and #best > 4 then
        best[#best] = nil
      end
    end
  end

  if #best == 0 then
    return nil
  end

  return best[((existing_count or 0) % #best) + 1].tree
end

local function eligible_spawn_position_in_area(surface, area, existing_count, force)
  local trees = surface.find_entities_filtered({
    area = area,
    type = "tree"
  })
  local minimum_distances = {
    constants.squirrel_spawn_player_buffer,
    constants.squirrel_spawn_relaxed_player_buffer
  }

  if #trees > 0 then
    local tree = select_spawn_tree(surface.index, trees, existing_count)
    local anchors = {
      tree.position,
      {x = tree.position.x + 2.5, y = tree.position.y},
      {x = tree.position.x - 2.5, y = tree.position.y},
      {x = tree.position.x, y = tree.position.y + 2.5},
      {x = tree.position.x, y = tree.position.y - 2.5},
      {x = tree.position.x + 3, y = tree.position.y + 3},
      {x = tree.position.x - 3, y = tree.position.y + 3},
      {x = tree.position.x + 3, y = tree.position.y - 3},
      {x = tree.position.x - 3, y = tree.position.y - 3}
    }

    for _, minimum_distance in ipairs(minimum_distances) do
      for _, anchor in ipairs(anchors) do
        local position = spawn_position_near_anchor(surface, anchor, 10, force, minimum_distance)
        if position then
          return position
        end
      end
    end
  end

  local anchors = region_search_anchors(area)
  table.sort(anchors, function(left, right)
    local left_distance = nearest_player_distance_squared(surface.index, left) or math.huge
    local right_distance = nearest_player_distance_squared(surface.index, right) or math.huge
    return left_distance > right_distance
  end)

  for _, minimum_distance in ipairs(minimum_distances) do
    for _, anchor in ipairs(anchors) do
      local position = spawn_position_near_anchor(surface, anchor, 14, force, minimum_distance)
      if position then
        return position
      end
    end
  end

  return nil
end

local function eligible_spawn_position(surface, region_x, region_y, existing_count, force)
  return eligible_spawn_position_in_area(
    surface,
    regions.region_area(region_x, region_y),
    existing_count,
    force
  )
end

local function active_region_coords()
  local seen = {}
  local coords = {}

  for _, player in ipairs(game.connected_players) do
    if player.valid and player.surface then
      local center = regions.position_to_region_coord(player.position)

      for dx = -constants.squirrel_active_region_radius, constants.squirrel_active_region_radius do
        for dy = -constants.squirrel_active_region_radius, constants.squirrel_active_region_radius do
          local region_x = center.x + dx
          local region_y = center.y + dy
          local key = player.surface.index .. ":" .. region_x .. ":" .. region_y
          if not seen[key] then
            seen[key] = true
            coords[#coords + 1] = {
              surface_index = player.surface.index,
              region_x = region_x,
              region_y = region_y
            }
          end
        end
      end
    end
  end

  return coords
end

local function create_record(entity, home_position, region_x, region_y, tick)
  if not (entity and entity.valid) then
    return nil
  end

  local squirrel_id = next_squirrel_id()
  local record = {
    squirrel_id = squirrel_id,
    entity = entity,
    entity_unit_number = entity.unit_number,
    surface_index = entity.surface.index,
    home_position = clone_position(home_position),
    region_x = region_x,
    region_y = region_y,
    state = "calm",
    mode = "idle",
    intent = nil,
    target = nil,
    carrying = nil,
    destination = nil,
    excursion_target = nil,
    excursion_intent = nil,
    next_decision_tick = tick,
    action_due_tick = tick,
    last_action_tick = 0,
    last_loot_name = nil,
    stash_id = nil,
    belt_pose_render_id = nil,
    render_id = nil,
    render_count_id = nil,
    roam_step = 0,
    arrival_distance = nil,
    blocking_until_tick = nil,
    feeder_nibbles_remaining = nil,
    belt_ride = nil,
    feared_player_index = nil,
    fear_until_tick = nil,
    fear_position = nil
  }

  get_squirrel_store()[squirrel_id] = record
  index_record(record)
  get_region_activity(entity.surface.index, region_x, region_y).last_spawn_tick = tick
  stop_entity(entity)
  return record
end

local function count_region_squirrels(surface_index, region_x, region_y)
  return get_region_squirrel_entry(surface_index, region_x, region_y).count
end

function squirrels.ensure_population_in_region(surface, region_x, region_y, tick, force_recompute)
  local squirrel_force = ensure_squirrel_force()
  local report = region_report(surface.index, region_x, region_y, tick, force_recompute)
  local target = squirrel_population_target(report)
  local existing = count_region_squirrels(surface.index, region_x, region_y)
  local created = 0
  local remaining_capacity = target - existing

  if remaining_capacity <= 0 then
    return 0
  end

  local spawn_budget = math.min(remaining_capacity, constants.squirrel_spawn_batch_per_update)

  if force_recompute then
    spawn_budget = remaining_capacity
  end

  while created < spawn_budget do
    local position = eligible_spawn_position(surface, region_x, region_y, existing + created, squirrel_force)
    if not position then
      break
    end

    local entity = surface.create_entity({
      name = constants.names.squirrel,
      position = position,
      force = squirrel_force,
      create_build_effect_smoke = false,
      spawn_decorations = false
    })

    if not (entity and entity.valid) then
      break
    end

    local record = create_record(entity, position, region_x, region_y, tick)
    if record then
      process_idle_decision(record, entity, tick)
    end
    created = created + 1
  end

  return created
end

function squirrels.seed_chunk_population(surface, chunk_position, area, tick)
  if not (surface and surface.valid and surface.name == constants.primary_surface_name) then
    return 0
  end

  local target_area = area or chunk_area(chunk_position)
  local tree_count = surface.count_entities_filtered({
    area = target_area,
    type = "tree"
  })

  if tree_count < constants.squirrel_chunk_seed_min_tree_count then
    return 0
  end

  local coord = regions.position_to_region_coord({
    x = (target_area.left_top.x + target_area.right_bottom.x) / 2,
    y = (target_area.left_top.y + target_area.right_bottom.y) / 2
  })
  local existing = count_region_squirrels(surface.index, coord.x, coord.y)

  if existing >= math.min(constants.max_visible_squirrels_per_region, 4) then
    return 0
  end

  local squirrel_force = ensure_squirrel_force()
  local position = eligible_spawn_position_in_area(surface, target_area, existing, squirrel_force)
  if not position then
    return 0
  end

  local entity = surface.create_entity({
    name = constants.names.squirrel,
    position = position,
    force = squirrel_force,
    create_build_effect_smoke = false,
    spawn_decorations = false
  })

  if not (entity and entity.valid) then
    return 0
  end

  local record = create_record(entity, position, coord.x, coord.y, tick or game.tick)
  return record and 1 or 0
end

process_idle_decision = function(record, entity, tick)
  local fear_position = current_fear_position(record, tick)
  if fear_position then
    start_flee(record, entity, tick, fear_position)
    return
  end

  local state, report = squirrel_state_for_region(record.surface_index, record.region_x, record.region_y, tick)
  record.state = state
  local origin_position = (entity and entity.valid and entity.position) or record.home_position

  if record.carrying then
    start_retreat(record, entity, tick)
    return
  end

  local local_target, local_intent = find_local_target(record, state, report, tick, origin_position)
  if local_target and local_intent then
    start_target_run(record, entity, local_target, local_intent, tick)
    return
  end

  local excursion_target, excursion_intent = find_excursion_target(record, state, report, tick, origin_position)
  if excursion_target then
    start_roam(record, entity, tick, state, report, excursion_target, excursion_intent)
    return
  end

  start_roam(record, entity, tick, state, report)
end

local function process_arrival(record, entity, tick)
  local target_entity = resolve_target(record)

  if record.mode == "roam" then
    if maybe_commit_roam_target(record, entity, tick) then
      return
    end
    enter_idle(record, entity, tick)
    return
  end

  if record.mode == "approach" then
    if not target_entity then
      send_home(record, entity, tick)
      return
    end

    if record.target.target_type == "belt" then
      start_belt_block(record, entity, target_entity, tick)
      return
    end

    if record.target.target_type == "feeder" then
      start_feeder_visit(record, entity, target_entity, tick)
      return
    end

    if record.target.target_type == "chest" then
      if record.intent == "steal" then
        perform_chest_scavenge(record, entity, tick)
      else
        record.mode = "inspect"
        record.destination = nil
        record.arrival_distance = nil
        record.action_due_tick = tick + constants.squirrel_curious_pause_duration
        stop_entity(entity)
      end
      return
    end

    send_home(record, entity, tick)
    return
  end

  if record.mode == "inspect" then
    enter_idle(record, entity, tick)
    return
  end

  if record.mode == "blocking" then
    if record.intent == "inspect" then
      finish_belt_inspection(record, entity, tick)
    elseif record.intent == "feed" then
      perform_feeder_visit(record, entity, tick)
    else
      perform_belt_theft(record, entity, tick)
    end
    return
  end

  if record.mode == "retreat" then
    if deposit_or_spill(record, entity) then
      send_home(record, entity, tick)
    else
      enter_idle(record, entity, tick)
    end
  end
end

local function cleanup_invalid_squirrels(tick)
  storage.squirrel_last_cleanup_tick = storage.squirrel_last_cleanup_tick or 0
  if tick < (storage.squirrel_last_cleanup_tick + constants.squirrel_cleanup_interval) then
    return
  end

  storage.squirrel_last_cleanup_tick = tick

  for squirrel_id, record in pairs(get_squirrel_store()) do
    local entity = resolve_entity_reference(record.entity)
    if not (entity and entity.valid) then
      remove_record(squirrel_id)
    end
  end
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

local function cull_inactive_squirrels(active_lookup)
  for surface_index, regions_with_squirrels in pairs(storage.squirrel_region_index or {}) do
    for current_region_key, region_entry in pairs(regions_with_squirrels) do
      local region_x, region_y = parse_region_key(current_region_key)
      if region_x and region_y and not active_lookup[active_region_key(surface_index, region_x, region_y)] then
        local squirrel_ids = {}

        for squirrel_id in pairs(region_entry.ids or {}) do
          squirrel_ids[#squirrel_ids + 1] = squirrel_id
        end

        for _, squirrel_id in ipairs(squirrel_ids) do
          local record = get_squirrel_store()[squirrel_id]
          if record then
            local entity = resolve_entity_reference(record.entity)
            if entity and entity.valid then
              if record.carrying then
                if not deposit_or_spill(record, entity) then
                  entity.surface.spill_item_stack({
                    position = entity.position,
                    stack = record.carrying,
                    enable_looted = true,
                    force = nil,
                    allow_belts = false
                  })
                  clear_carrying(record, entity)
                end
              end

              entity.destroy()
            end

            remove_record(squirrel_id)
          end
        end
      end
    end
  end
end

function squirrels.on_tick(tick)
  advance_active_belt_riders(tick)
  cleanup_invalid_squirrels(tick)

  for _, record in pairs(get_squirrel_store()) do
    local entity = resolve_entity_reference(record.entity)
    if entity and entity.valid and record.mode == "flee" then
      local fear_position = current_fear_position(record, tick)

      if not fear_position then
        process_idle_decision(record, entity, tick)
      elseif
        flee_is_stuck(record, entity, tick)
        or
        (record.destination and reached_position(entity, record.destination, record.arrival_distance))
        or tick >= record.action_due_tick
      then
        start_flee(record, entity, tick, fear_position)
      end
    end
  end

  if tick % constants.squirrel_update_interval == 0 then
    local active_coords = active_region_coords()
    local active_lookup = {}

    for _, coord in ipairs(active_coords) do
      active_lookup[active_region_key(coord.surface_index, coord.region_x, coord.region_y)] = true
    end

    cull_inactive_squirrels(active_lookup)

    for _, coord in ipairs(active_coords) do
      local surface = game.surfaces[coord.surface_index]
      if surface then
        squirrels.ensure_population_in_region(surface, coord.region_x, coord.region_y, tick)
      end
    end

    squirrels.cleanup_empty_stashes()

    for _, record in pairs(get_squirrel_store()) do
      local entity = resolve_entity_reference(record.entity)
      if entity and entity.valid then
        if record.mode == "idle" and tick >= record.next_decision_tick then
          process_idle_decision(record, entity, tick)
        elseif record.mode == "roam" and maybe_commit_roam_target(record, entity, tick) then
          -- Roaming excursions commit to real targets once the squirrel reaches them.
        elseif
          record.mode == "roam"
          and record.destination
          and reached_position(entity, record.destination, record.arrival_distance)
        then
          process_arrival(record, entity, tick)
        elseif record.mode == "roam" and tick >= record.action_due_tick then
          enter_idle(record, entity, tick)
        elseif tick >= record.action_due_tick then
          process_arrival(record, entity, tick)
        elseif
          record.mode ~= "roam"
          and record.destination
          and reached_position(entity, record.destination, record.arrival_distance)
        then
          process_arrival(record, entity, tick)
        end
      end
    end
  end
end

function squirrels.on_squirrel_removed(entity, tick)
  if not is_squirrel_entity(entity) then
    return
  end

  local squirrel_id = entity.unit_number and get_entity_squirrel_index()[entity.unit_number] or nil
  local record = squirrel_id and get_squirrel_store()[squirrel_id] or nil

  if record and record.carrying then
    entity.surface.spill_item_stack({
      position = entity.position,
      stack = record.carrying,
      enable_looted = true,
      force = nil,
      allow_belts = false
    })
  end

  local coord = regions.position_to_region_coord(entity.position)
  get_region_activity(entity.surface.index, coord.x, coord.y).grief_until_tick =
    (tick or game.tick) + constants.squirrel_grief_duration
  if squirrel_id then
    remove_record(squirrel_id)
  end
end

function squirrels.on_stepped(entity, tick, player)
  if not is_squirrel_entity(entity) then
    return nil
  end

  local squirrel_id = entity.unit_number and get_entity_squirrel_index()[entity.unit_number] or nil
  local record = squirrel_id and get_squirrel_store()[squirrel_id] or nil
  if not record then
    return nil
  end

  local current_tick = tick or game.tick
  local fear_until_tick = set_squirrel_fear(record, player, current_tick)
  local fear_position = current_fear_position(record, current_tick)

  if fear_until_tick and fear_position then
    start_flee(record, entity, current_tick, fear_position)
  elseif record.carrying then
    start_retreat(record, entity, current_tick)
  else
    send_home(record, entity, current_tick)
  end

  return resolve_entity_reference(record.entity)
end

function squirrels.normalize_entity_variants()
  for _, record in pairs(get_squirrel_store()) do
    local entity = resolve_entity_reference(record.entity)
    if entity and entity.valid and entity.name == constants.names.squirrel_panicked then
      ensure_entity_variant(record, constants.names.squirrel)
    end
  end
end

local function note_squirrel_loss(record, entity, tick)
  if record and record.carrying then
    entity.surface.spill_item_stack({
      position = entity.position,
      stack = record.carrying,
      enable_looted = true,
      force = nil,
      allow_belts = false
    })
  end

  local coord = regions.position_to_region_coord(entity.position)
  get_region_activity(entity.surface.index, coord.x, coord.y).grief_until_tick =
    (tick or game.tick) + constants.squirrel_grief_duration
end

function squirrels.relocate_squirrel(squirrel_id, region_x, region_y, tick)
  local record = get_squirrel_store()[squirrel_id]
  local entity = record and resolve_entity_reference(record.entity) or nil
  if not (record and entity and entity.valid) then
    return nil
  end

  local surface = entity.surface
  local squirrel_force = ensure_squirrel_force()
  local destination = eligible_spawn_position(surface, region_x, region_y, count_region_squirrels(surface.index, region_x, region_y), squirrel_force)
  if not destination then
    return nil
  end

  if record.carrying then
    surface.spill_item_stack({
      position = entity.position,
      stack = record.carrying,
      enable_looted = true,
      force = nil,
      allow_belts = false
    })
    clear_carrying(record, entity)
  end

  clear_belt_ride(record)
  unindex_record(record)

  if not entity.teleport(destination) then
    index_record(record)
    return nil
  end

  record.surface_index = surface.index
  record.region_x = region_x
  record.region_y = region_y
  record.home_position = clone_position(destination)
  record.state = "calm"
  record.mode = "idle"
  record.intent = nil
  record.target = nil
  record.destination = nil
  record.excursion_target = nil
  record.excursion_intent = nil
  record.arrival_distance = nil
  record.blocking_until_tick = nil
  record.belt_ride = nil
  record.action_due_tick = tick or game.tick
  record.next_decision_tick = (tick or game.tick) + constants.squirrel_decision_interval
  record.last_action_tick = tick or game.tick
  set_record_stash(record, nil)
  index_record(record)
  stop_entity(entity)

  return {
    position = clone_position(destination),
    region_x = region_x,
    region_y = region_y
  }
end

function squirrels.debug_spawn_squirrel(surface_index, position, tick)
  local surface = game.surfaces[surface_index]
  if not surface then
    return nil
  end

  local squirrel_force = ensure_squirrel_force()
  local spawn_position = spawn_position_near_anchor(surface, position, 16, squirrel_force)
  if not spawn_position then
    return nil
  end

  local entity = surface.create_entity({
    name = constants.names.squirrel,
    position = spawn_position,
    force = squirrel_force,
    create_build_effect_smoke = false,
    spawn_decorations = false
  })

  if not (entity and entity.valid) then
    return nil
  end

  local coord = regions.position_to_region_coord(spawn_position)
  local record = create_record(entity, spawn_position, coord.x, coord.y, tick or game.tick)
  return record and record.squirrel_id or nil
end

function squirrels.squirrel_id_for_entity(entity)
  if not (is_squirrel_entity(entity) and entity.unit_number) then
    return nil
  end

  return get_entity_squirrel_index()[entity.unit_number]
end

function squirrels.is_squirrel_entity(entity)
  return is_squirrel_entity(entity)
end

function squirrels.should_ignore_removed_entity(entity)
  if not (entity and entity.unit_number) then
    return false
  end

  local ignored = get_ignored_removals()
  if not ignored[entity.unit_number] then
    return false
  end

  ignored[entity.unit_number] = nil
  return true
end

function squirrels.entity_for_squirrel_id(squirrel_id)
  local record = squirrel_id and get_squirrel_store()[squirrel_id] or nil
  local entity = record and resolve_entity_reference(record.entity) or nil
  if not (entity and entity.valid) then
    return nil
  end

  return entity
end

function squirrels.snapshot(squirrel_id)
  local record = get_squirrel_store()[squirrel_id]
  local entity = record and resolve_entity_reference(record.entity) or nil
  if not (record and entity and entity.valid) then
    return nil
  end

  return {
    squirrel_id = squirrel_id,
    surface_index = record.surface_index,
    region_x = record.region_x,
    region_y = record.region_y,
    entity_name = entity.name,
    position = clone_position(entity.position),
    home_position = clone_position(record.home_position),
    mode = record.mode,
    intent = record.intent,
    destination = record.destination and clone_position(record.destination) or nil,
    belt_riding = record.belt_ride ~= nil,
    belt_pose_render = entity.name == constants.names.squirrel_sitting,
    feared_player_index = record.feared_player_index,
    fear_until_tick = record.fear_until_tick,
    fear_position = record.fear_position and clone_position(record.fear_position) or nil,
    render_sprite = record.render_id and record.render_id.valid or false,
    render_count = record.render_count_id and record.render_count_id.valid or false,
    carrying = record.carrying and {
      name = record.carrying.name,
      count = record.carrying.count
    } or nil
  }
end

local function get_squirrel_record(squirrel_id)
  return get_squirrel_store()[squirrel_id]
end

local function serialize_debug_target(target)
  if not target then
    return nil
  end

  return {
    target_type = target.target_type,
    item_name = target.item_name,
    count = target.count,
    position = clone_position(target.position)
  }
end

function squirrels.debug_kill_squirrel(squirrel_id)
  local record = get_squirrel_record(squirrel_id)
  local entity = record and resolve_entity_reference(record.entity) or nil
  if not (entity and entity.valid) then
    return false
  end

  note_squirrel_loss(record, entity, game.tick)
  remove_record(squirrel_id)
  return entity.die(game.forces.player)
end

function squirrels.debug_clear_surface(surface_index)
  local destroyed = 0

  for squirrel_id, record in pairs(get_squirrel_store()) do
    if not surface_index or record.surface_index == surface_index then
      local entity = resolve_entity_reference(record.entity)

      if entity and entity.valid then
        destroy_render(record)
        entity.destroy()
        destroyed = destroyed + 1
      end

      remove_record(squirrel_id)
    end
  end

  return destroyed
end

function squirrels.debug_force_belt_theft(surface_index, squirrel_id, position, tick)
  local surface = game.surfaces[surface_index]
  local record = get_squirrel_record(squirrel_id)
  local entity = record and resolve_entity_reference(record.entity) or nil
  if not (surface and entity and entity.valid) then
    return nil
  end

  local belt = surface.find_entities_filtered({
    position = position,
    type = {"transport-belt", "underground-belt", "splitter"},
    limit = 1
  })[1]
  if not (belt and belt.valid) then
    return nil
  end

  if not record then
    return nil
  end

  if not theft_is_available(record, tick or game.tick) then
    return nil
  end

  record.target = choose_belt_item(belt, record.last_loot_name)
  if not record.target then
    return nil
  end

  local current_tick = tick or game.tick
  entity.teleport(belt.position)
  entity = start_belt_block(record, entity, belt, current_tick) or resolve_entity_reference(record.entity) or entity

  local iterations = 0
  while iterations < 128 and (record.mode == "blocking" or (record.mode == "approach" and record.intent == "steal")) do
    current_tick = current_tick + constants.squirrel_belt_grab_interval
    entity = resolve_entity_reference(record.entity) or entity
    advance_belt_ride(record, entity, current_tick)

    if record.mode == "blocking" then
      perform_belt_theft(record, entity, current_tick)
    else
      process_arrival(record, entity, current_tick)
    end

    iterations = iterations + 1
  end

  if not record.carrying and record.mode ~= "retreat" then
    return nil
  end

  local carried_count = record.carrying and record.carrying.count or 0
  local stash = ensure_stash(record, record.carrying, record.home_position)
  local stash_id = record.stash_id
  if stash then
    entity = resolve_entity_reference(record.entity) or entity
    entity.teleport(stash.position)
  end

  entity = resolve_entity_reference(record.entity) or entity
  deposit_or_spill(record, entity)
  send_home(record, entity, current_tick)

  return {
    item_name = record.last_loot_name,
    count = carried_count,
    stash_id = stash_id
  }
end

function squirrels.debug_force_belt_sit(surface_index, squirrel_id, position, tick)
  local surface = game.surfaces[surface_index]
  local record = get_squirrel_record(squirrel_id)
  local entity = record and resolve_entity_reference(record.entity) or nil
  if not (surface and entity and entity.valid and record) then
    return nil
  end

  local belt = surface.find_entities_filtered({
    position = position,
    type = {"transport-belt", "underground-belt", "splitter"},
    limit = 1
  })[1]
  if not (belt and belt.valid) then
    return nil
  end

  local current_tick = tick or game.tick
  record.target = choose_belt_item(belt, record.last_loot_name, true)
  if not record.target then
    return nil
  end

  record.intent = "inspect"
  entity.teleport(belt.position)
  entity = start_belt_block(record, entity, belt, current_tick) or resolve_entity_reference(record.entity) or entity
  advance_belt_ride(record, entity, current_tick)

  return squirrels.snapshot(squirrel_id)
end

function squirrels.debug_force_single_belt_grab(surface_index, squirrel_id, position, tick)
  local surface = game.surfaces[surface_index]
  local record = get_squirrel_record(squirrel_id)
  local entity = record and resolve_entity_reference(record.entity) or nil
  if not (surface and entity and entity.valid and record) then
    return nil
  end

  local belt = surface.find_entities_filtered({
    position = position,
    type = {"transport-belt", "underground-belt", "splitter"},
    limit = 1
  })[1]
  if not (belt and belt.valid) then
    return nil
  end

  local current_tick = tick or game.tick
  record.target = choose_belt_item(belt, record.last_loot_name)
  if not record.target then
    return nil
  end

  entity.teleport(belt.position)
  entity = start_belt_block(record, entity, belt, current_tick) or resolve_entity_reference(record.entity) or entity
  advance_belt_ride(record, entity, current_tick)
  perform_belt_theft(record, entity, current_tick)

  return squirrels.snapshot(squirrel_id)
end

function squirrels.debug_force_chest_scavenge(surface_index, squirrel_id, position, tick)
  local surface = game.surfaces[surface_index]
  local record = get_squirrel_record(squirrel_id)
  local entity = record and resolve_entity_reference(record.entity) or nil
  if not (surface and entity and entity.valid) then
    return nil
  end

  local chest = surface.find_entities_filtered({
    position = position,
    type = {"container", "logistic-container"},
    limit = 1
  })[1]
  if not (chest and chest.valid) then
    return nil
  end

  if constants.feeder_variant_by_name[chest.name] then
    return nil
  end

  if not record then
    return nil
  end

  if not theft_is_available(record, tick or game.tick) then
    return nil
  end

  local report = region_report(record.surface_index, record.region_x, record.region_y, tick or game.tick, true)
  if not report or report.habitat_pressure < constants.squirrel_chest_pressure_threshold then
    return nil
  end

  record.target = choose_chest_item(chest, record.last_loot_name, report)
  if not record.target then
    return nil
  end

  local removed = perform_chest_scavenge(record, entity, tick or game.tick)
  if not removed then
    return nil
  end
  local carried_count = record.carrying and record.carrying.count or 0

  local stash = ensure_stash(record, record.carrying, record.home_position)
  local stash_id = record.stash_id
  if stash then
    entity.teleport(stash.position)
  end

  deposit_or_spill(record, entity)
  send_home(record, entity, tick or game.tick)

  return {
    item_name = record.last_loot_name,
    stash_id = stash_id,
    count = carried_count
  }
end

function squirrels.debug_advance_runtime(duration, start_tick)
  local final_tick = start_tick or game.tick

  for _ = 1, duration do
    final_tick = final_tick + 1
    squirrels.on_tick(final_tick)
  end

  return squirrels.debug_report(nil, final_tick)
end

function squirrels.debug_target_for_squirrel(squirrel_id, tick)
  local record = get_squirrel_record(squirrel_id)
  if not record then
    return nil
  end

  local current_tick = tick or game.tick
  local entity = resolve_entity_reference(record.entity)
  if not (entity and entity.valid) then
    return nil
  end

  local state, report = squirrel_state_for_region(record.surface_index, record.region_x, record.region_y, current_tick, true)
  local local_target, local_intent = find_local_target(record, state, report, current_tick, entity.position)
  local excursion_target, excursion_intent = find_excursion_target(record, state, report, current_tick, entity.position)
  local chosen_target = local_target or excursion_target

  return {
    state = state,
    local_target = serialize_debug_target(local_target),
    local_intent = local_intent,
    excursion_target = serialize_debug_target(excursion_target),
    excursion_intent = excursion_intent,
    chosen_target = serialize_debug_target(chosen_target)
  }
end

function squirrels.debug_report(surface_index, tick)
  local report = {
    squirrels = {},
    stashes = {}
  }

  for squirrel_id, record in pairs(get_squirrel_store()) do
    if not surface_index or record.surface_index == surface_index then
      local entity = resolve_entity_reference(record.entity)
      if entity and entity.valid then
        report.squirrels[#report.squirrels + 1] = {
          squirrel_id = squirrel_id,
          entity_name = entity.name,
          state = record.state,
          mode = record.mode,
          intent = record.intent,
          region_x = record.region_x,
          region_y = record.region_y,
          carrying = record.carrying and record.carrying.name or nil,
          stash_id = record.stash_id,
          belt_riding = record.belt_ride ~= nil,
          position = clone_position(entity.position),
          home_position = clone_position(record.home_position),
          last_action_tick = record.last_action_tick
        }
      end
    end
  end

  for current_surface_index, stashes in pairs(storage.squirrel_stashes or {}) do
    if not surface_index or current_surface_index == surface_index then
      for stash_id, stash in pairs(stashes) do
        local entity = resolve_entity_reference(stash.entity)
        if entity and entity.valid then
          local inventory = entity.get_inventory(defines.inventory.chest)
          report.stashes[#report.stashes + 1] = {
            stash_id = stash_id,
            region_x = stash.region_x,
            region_y = stash.region_y,
            position = clone_position(entity.position),
            item_count = inventory_total_count(inventory)
          }
        end
      end
    end
  end

  table.sort(report.squirrels, function(left, right)
    return left.squirrel_id < right.squirrel_id
  end)
  table.sort(report.stashes, function(left, right)
    return left.stash_id < right.stash_id
  end)

  report.tick = tick or game.tick
  return report
end

function squirrels.debug_state_for_position(surface_index, position, tick)
  local coord = regions.position_to_region_coord(position)
  local state = squirrel_state_for_region(surface_index, coord.x, coord.y, tick or game.tick, true)
  return state
end

function squirrels.selection_overlay_state(entity, tick)
  if not is_squirrel_entity(entity) then
    return nil
  end

  local squirrel_id = entity.unit_number and get_entity_squirrel_index()[entity.unit_number] or nil
  local record = squirrel_id and get_squirrel_store()[squirrel_id] or nil
  if not record then
    return nil
  end

  local state, report = squirrel_state_for_region(record.surface_index, record.region_x, record.region_y, tick or game.tick)
  local local_radius = state_local_target_radius(state)
  if not local_radius then
    return nil
  end

  local belt_interest_radius = state_wander_distance(state, report) + local_radius

  return {
    squirrel_id = squirrel_id,
    state = state,
    radius = local_radius,
    local_radius = local_radius,
    belt_interest_radius = belt_interest_radius,
    region_x = record.region_x,
    region_y = record.region_y,
    mode = record.mode,
    habitat_pressure = report and report.habitat_pressure or nil,
    home_position = clone_position(record.home_position)
  }
end

function squirrels.debug_item_desirability(item_name)
  return item_desirability(item_name)
end

function squirrels.debug_belt_block_count(surface_index, position)
  local surface = game.surfaces[surface_index]
  if not surface then
    return 0
  end

  local belt = surface.find_entities_filtered({
    position = position,
    type = {"transport-belt", "underground-belt", "splitter"},
    limit = 1
  })[1]
  if not (belt and belt.valid) then
    return 0
  end

  return get_belt_block_counts()[target_key(belt)] or 0
end

return squirrels
