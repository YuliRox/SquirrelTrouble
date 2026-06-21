local constants = require("scripts.constants")
local regions = require("scripts.regions.module")
local flee_module = require("scripts.squirrels.flee")
local position_ops = require("scripts.squirrels.position")
local storage_ops = require("scripts.squirrels.storage")
local targeting_module = require("scripts.squirrels.targeting")
local render_ops = require("scripts.squirrels.render")
local carrying_module = require("scripts.squirrels.carrying")
local stash_module = require("scripts.squirrels.stash")
local belt_module = require("scripts.squirrels.belt")
local debug_module = require("scripts.squirrels.debug")
local population_module = require("scripts.squirrels.population")
local target_ops = require("scripts.squirrels.target")
local state_ops = require("scripts.squirrels.state")
local roam_ops = require("scripts.squirrels.roam")

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
local clear_belt_ride

local function is_squirrel_entity_name(name)
  return constants.squirrel_entity_names[name] == true
end

local function is_squirrel_entity(entity)
  return entity and entity.valid and is_squirrel_entity_name(entity.name)
end

local clone_position = position_ops.clone
local round_position_key = position_ops.round_key
local player_position_for_index = position_ops.player_position_for_index
local position_with_offset = position_ops.with_offset
local reached_position = position_ops.reached_position

local region_key = storage_ops.region_key
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
local get_surface_region_index = storage_ops.get_surface_region_index
local get_region_squirrel_entry = storage_ops.get_region_squirrel_entry
local get_entity_squirrel_index = storage_ops.get_entity_squirrel_index
local get_stash_target_counts = storage_ops.get_stash_target_counts
local get_target_cooldowns = storage_ops.get_target_cooldowns
local get_ignored_removals = storage_ops.get_ignored_removals

local get_region_activity = state_ops.get_region_activity
local region_report = state_ops.region_report
local squirrel_state_for_region = state_ops.squirrel_state_for_region

local resolve_entity_reference = target_ops.resolve_entity_reference
local serialize_target = target_ops.serialize_target
local resolve_target_reference = target_ops.resolve_target_reference

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

local function resolve_target(record)
  return resolve_target_reference(record.surface_index, record.target)
end

local belt_ops = belt_module.install({
  BELT_TYPES = BELT_TYPES,
  direction_to_orientation = direction_to_orientation
})

clear_belt_ride = belt_ops.clear_belt_ride
local begin_belt_ride = belt_ops.begin_belt_ride
local advance_belt_ride = belt_ops.advance_belt_ride
local remove_belt_item = belt_ops.remove_belt_item
local advance_active_belt_riders = belt_ops.advance_active_belt_riders

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

local stash_ops = stash_module.install({})

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

local current_fear_position = flee_ops.current_fear_position
local set_squirrel_fear = flee_ops.set_squirrel_fear
local flee_is_stuck = flee_ops.flee_is_stuck
local start_flee = flee_ops.start_flee

local bounded_roam_destination = roam_ops.bounded_roam_destination
local idle_pause_duration = roam_ops.idle_pause_duration

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
  theft_is_available = theft_is_available,
  start_target_run = start_target_run,
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

local population_ops = population_module.install({
  create_record = create_record,
  process_idle_decision = process_idle_decision,
  ensure_squirrel_force = ensure_squirrel_force,
  chunk_area = chunk_area,
  remove_record = remove_record,
  deposit_or_spill = deposit_or_spill,
  clear_carrying = clear_carrying
})

local spawn_position_near_anchor = population_ops.spawn_position_near_anchor
local eligible_spawn_position = population_ops.eligible_spawn_position
local count_region_squirrels = population_ops.count_region_squirrels
local active_region_coords = population_ops.active_region_coords
local cull_inactive_squirrels = population_ops.cull_inactive_squirrels

squirrels.ensure_population_in_region = population_ops.ensure_population_in_region
squirrels.seed_chunk_population = population_ops.seed_chunk_population

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

local debug_ops = debug_module.install({
  create_record = create_record,
  ensure_squirrel_force = ensure_squirrel_force,
  spawn_position_near_anchor = spawn_position_near_anchor,
  note_squirrel_loss = note_squirrel_loss,
  remove_record = remove_record,
  theft_is_available = theft_is_available,
  choose_belt_item = choose_belt_item,
  choose_chest_item = choose_chest_item,
  start_belt_block = start_belt_block,
  advance_belt_ride = advance_belt_ride,
  perform_belt_theft = perform_belt_theft,
  process_arrival = process_arrival,
  ensure_stash = ensure_stash,
  deposit_or_spill = deposit_or_spill,
  send_home = send_home,
  perform_chest_scavenge = perform_chest_scavenge,
  find_local_target = find_local_target,
  find_excursion_target = find_excursion_target,
  inventory_total_count = inventory_total_count,
  state_local_target_radius = state_local_target_radius,
  state_wander_distance = state_wander_distance,
  item_desirability = item_desirability,
  target_key = target_key,
  is_squirrel_entity = is_squirrel_entity,
  on_tick = squirrels.on_tick
})

squirrels.snapshot = debug_ops.snapshot
squirrels.debug_spawn_squirrel = debug_ops.debug_spawn_squirrel
squirrels.debug_kill_squirrel = debug_ops.debug_kill_squirrel
squirrels.debug_clear_surface = debug_ops.debug_clear_surface
squirrels.debug_force_belt_theft = debug_ops.debug_force_belt_theft
squirrels.debug_force_belt_sit = debug_ops.debug_force_belt_sit
squirrels.debug_force_single_belt_grab = debug_ops.debug_force_single_belt_grab
squirrels.debug_force_chest_scavenge = debug_ops.debug_force_chest_scavenge
squirrels.debug_advance_runtime = debug_ops.debug_advance_runtime
squirrels.debug_target_for_squirrel = debug_ops.debug_target_for_squirrel
squirrels.debug_report = debug_ops.debug_report
squirrels.debug_state_for_position = debug_ops.debug_state_for_position
squirrels.selection_overlay_state = debug_ops.selection_overlay_state
squirrels.debug_item_desirability = debug_ops.debug_item_desirability
squirrels.debug_belt_block_count = debug_ops.debug_belt_block_count

return squirrels
