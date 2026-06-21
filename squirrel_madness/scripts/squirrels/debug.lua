local constants = require("scripts.constants")
local regions = require("scripts.regions.module")
local position_ops = require("scripts.squirrels.position")
local storage_ops = require("scripts.squirrels.storage")
local render_ops = require("scripts.squirrels.render")
local target_ops = require("scripts.squirrels.target")
local state_ops = require("scripts.squirrels.state")

local region_report = state_ops.region_report
local squirrel_state_for_region = state_ops.squirrel_state_for_region
local resolve_entity_reference = target_ops.resolve_entity_reference
local clone_position = position_ops.clone
local get_squirrel_store = storage_ops.get_squirrel_store
local get_entity_squirrel_index = storage_ops.get_entity_squirrel_index
local get_belt_block_counts = storage_ops.get_belt_block_counts
local destroy_render = render_ops.destroy_render

local M = {}

function M.install(deps)
  local note_squirrel_loss = deps.note_squirrel_loss
  local remove_record = deps.remove_record
  local create_record = deps.create_record
  local ensure_squirrel_force = deps.ensure_squirrel_force
  local spawn_position_near_anchor = deps.spawn_position_near_anchor
  local theft_is_available = deps.theft_is_available
  local choose_belt_item = deps.choose_belt_item
  local choose_chest_item = deps.choose_chest_item
  local start_belt_block = deps.start_belt_block
  local advance_belt_ride = deps.advance_belt_ride
  local perform_belt_theft = deps.perform_belt_theft
  local process_arrival = deps.process_arrival
  local ensure_stash = deps.ensure_stash
  local deposit_or_spill = deps.deposit_or_spill
  local send_home = deps.send_home
  local perform_chest_scavenge = deps.perform_chest_scavenge
  local find_local_target = deps.find_local_target
  local find_excursion_target = deps.find_excursion_target
  local inventory_total_count = deps.inventory_total_count
  local state_local_target_radius = deps.state_local_target_radius
  local state_wander_distance = deps.state_wander_distance
  local item_desirability = deps.item_desirability
  local target_key = deps.target_key
  local is_squirrel_entity = deps.is_squirrel_entity
  local on_tick = deps.on_tick

  local debug = {}

  function debug.snapshot(squirrel_id)
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

  function debug.debug_kill_squirrel(squirrel_id)
    local record = get_squirrel_record(squirrel_id)
    local entity = record and resolve_entity_reference(record.entity) or nil
    if not (entity and entity.valid) then
      return false
    end

    note_squirrel_loss(record, entity, game.tick)
    remove_record(squirrel_id)
    return entity.die(game.forces.player)
  end

  function debug.debug_clear_surface(surface_index)
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

  function debug.debug_force_belt_theft(surface_index, squirrel_id, position, tick)
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

  function debug.debug_force_belt_sit(surface_index, squirrel_id, position, tick)
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

    return debug.snapshot(squirrel_id)
  end

  function debug.debug_force_single_belt_grab(surface_index, squirrel_id, position, tick)
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

    return debug.snapshot(squirrel_id)
  end

  function debug.debug_force_chest_scavenge(surface_index, squirrel_id, position, tick)
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

  function debug.debug_advance_runtime(duration, start_tick)
    local final_tick = start_tick or game.tick

    for _ = 1, duration do
      final_tick = final_tick + 1
      on_tick(final_tick)
    end

    return debug.debug_report(nil, final_tick)
  end

  function debug.debug_target_for_squirrel(squirrel_id, tick)
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

  function debug.debug_report(surface_index, tick)
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

  function debug.debug_state_for_position(surface_index, position, tick)
    local coord = regions.position_to_region_coord(position)
    local state = squirrel_state_for_region(surface_index, coord.x, coord.y, tick or game.tick, true)
    return state
  end

  function debug.selection_overlay_state(entity, tick)
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

  function debug.debug_item_desirability(item_name)
    return item_desirability(item_name)
  end

  function debug.debug_belt_block_count(surface_index, position)
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

  function debug.debug_spawn_squirrel(surface_index, position, tick)
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

  return debug
end

return M
