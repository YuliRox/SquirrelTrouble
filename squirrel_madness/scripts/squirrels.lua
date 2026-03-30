local constants = require("scripts.constants")
local regions = require("scripts.regions")

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

local function clone_position(position)
  return {x = position.x, y = position.y}
end

local function round_position_key(position)
  return math.floor((position.x * 10) + 0.5) .. ":" .. math.floor((position.y * 10) + 0.5)
end

local function distance_squared(left, right)
  local dx = left.x - right.x
  local dy = left.y - right.y
  return (dx * dx) + (dy * dy)
end

local function position_with_offset(origin, angle, distance)
  return {
    x = origin.x + (math.cos(angle) * distance),
    y = origin.y + (math.sin(angle) * distance)
  }
end

local function reached_position(entity, position, max_distance)
  return distance_squared(entity.position, position) <= ((max_distance or 1.4) ^ 2)
end

local function region_key(region_x, region_y)
  return region_x .. "," .. region_y
end

local function ensure_squirrel_force()
  local force = game.forces[constants.squirrel_force_name]
  if not force then
    force = game.create_force(constants.squirrel_force_name)
  end

  for _, other_force in pairs(game.forces) do
    if other_force.valid and other_force.name ~= force.name then
      force.set_cease_fire(other_force, true)
      other_force.set_cease_fire(force, true)
    end
  end

  return force
end

local function get_squirrel_store()
  storage.squirrels = storage.squirrels or {}
  return storage.squirrels
end

local function next_squirrel_id()
  storage.next_squirrel_id = storage.next_squirrel_id or 1
  local squirrel_id = storage.next_squirrel_id
  storage.next_squirrel_id = squirrel_id + 1
  return squirrel_id
end

local function get_surface_stashes(surface_index)
  storage.squirrel_stashes = storage.squirrel_stashes or {}
  storage.squirrel_stashes[surface_index] = storage.squirrel_stashes[surface_index] or {}
  return storage.squirrel_stashes[surface_index]
end

local function next_stash_id()
  storage.next_squirrel_stash_id = storage.next_squirrel_stash_id or 1
  local stash_id = storage.next_squirrel_stash_id
  storage.next_squirrel_stash_id = stash_id + 1
  return stash_id
end

local function get_surface_region_activity(surface_index)
  storage.squirrel_region_activity = storage.squirrel_region_activity or {}
  storage.squirrel_region_activity[surface_index] = storage.squirrel_region_activity[surface_index] or {}
  return storage.squirrel_region_activity[surface_index]
end

local function get_target_cooldowns()
  storage.squirrel_target_cooldowns = storage.squirrel_target_cooldowns or {}
  return storage.squirrel_target_cooldowns
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

local function serialize_target(entity, target_type, item_name, count)
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

local function resolve_target(record)
  local target = record.target
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

  local surface = game.surfaces[record.surface_index]
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

local function destroy_render(record)
  if record.render_id then
    pcall(function()
      rendering.destroy(record.render_id)
    end)
  end

  record.render_id = nil
end

local function sync_render(record, entity)
  destroy_render(record)

  if not (record.carrying and record.carrying.name and entity and entity.valid) then
    return
  end

  local sprite = "item/" .. record.carrying.name
  local ok, render_id = pcall(function()
    return rendering.draw_sprite({
      sprite = sprite,
      target = entity,
      surface = entity.surface,
      oriented_offset = {0, -0.9},
      x_scale = 0.55,
      y_scale = 0.55,
      render_layer = "higher-object-under"
    })
  end)

  if ok and render_id then
    record.render_id = render_id
    return
  end

  local fallback_ok, fallback_id = pcall(function()
    return rendering.draw_sprite({
      sprite = "utility/questionmark",
      target = entity,
      surface = entity.surface,
      oriented_offset = {0, -0.9},
      x_scale = 0.55,
      y_scale = 0.55,
      render_layer = "higher-object-under"
    })
  end)

  if fallback_ok then
    record.render_id = fallback_id
  end
end

local function remove_record(squirrel_id)
  local records = get_squirrel_store()
  local record = records[squirrel_id]
  if not record then
    return
  end

  destroy_render(record)
  records[squirrel_id] = nil
end

local function region_report(surface_index, region_x, region_y, tick)
  local surface = game.surfaces[surface_index]
  if not surface then
    return nil
  end

  return regions.get_region_report_by_coord(surface, region_x, region_y, tick)
end

local function can_spawn_at(surface, position, force)
  return surface.can_place_entity({
    name = constants.names.squirrel,
    position = position,
    force = force
  })
end

local function spawn_position_near_anchor(surface, anchor, radius, force)
  if can_spawn_at(surface, anchor, force) then
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

      if can_spawn_at(surface, candidate, force) then
        return candidate
      end
    end
  end

  return surface.find_non_colliding_position(constants.names.squirrel, anchor, max_radius, 0.5, false)
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

local function squirrel_state_for_region(surface_index, region_x, region_y, tick)
  local report = region_report(surface_index, region_x, region_y, tick)
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

  local target = 1
  if report.habitat_pressure >= 50 or report.squirrel_unrest >= 55 then
    target = target + 1
  end

  if report.habitat_pressure >= 80 then
    target = target + 1
  end

  return math.min(target, constants.max_visible_squirrels_per_region)
end

local function target_key(entity)
  if entity.unit_number then
    return tostring(entity.unit_number)
  end

  return entity.surface.index .. ":" .. entity.name .. ":" .. round_position_key(entity.position)
end

local function target_is_on_cooldown(entity, tick)
  local until_tick = get_target_cooldowns()[target_key(entity)]
  return until_tick and until_tick > tick
end

local function note_target_cooldown(entity, tick)
  get_target_cooldowns()[target_key(entity)] = tick + constants.squirrel_target_cooldown
end

local function item_desirability(item_name)
  local prototype = prototypes.item[item_name]
  if not prototype then
    return 0
  end

  local lower_name = item_name:lower()
  local score = 5

  if item_name == constants.names.nut or item_name == "raw-fish" then
    score = score + 75
  end

  if string.find(lower_name, "science%-pack") then
    score = score + 60
  end

  if string.find(lower_name, "circuit", 1, true) or string.find(lower_name, "module", 1, true) then
    score = score + 45
  end

  if
    string.find(lower_name, "steel", 1, true)
    or string.find(lower_name, "iron", 1, true)
    or string.find(lower_name, "copper", 1, true)
  then
    score = score + 25
  end

  if
    string.find(lower_name, "wood", 1, true)
    or string.find(lower_name, "gear", 1, true)
    or string.find(lower_name, "stick", 1, true)
    or string.find(lower_name, "coal", 1, true)
  then
    score = score + 20
  end

  if prototype.fuel_value and prototype.fuel_value > 0 then
    score = score + 15
  end

  if prototype.subgroup and prototype.subgroup.name == "science-pack" then
    score = score + 30
  end

  score = score + math.min((prototype.stack_size or 1) / 20, 10)
  return score
end

local function choose_belt_item(entity, preferred_item_name)
  if not BELT_TYPES[entity.type] then
    return nil
  end

  local best

  for line_index = 1, constants.squirrel_transport_line_scan_limit do
    local ok, line = pcall(function()
      return entity.get_transport_line(line_index)
    end)

    if ok and line and line.valid then
      for _, detail in ipairs(line.get_detailed_contents()) do
        if detail.stack and detail.stack.valid_for_read then
          local item_name = detail.stack.name
          local score = item_desirability(item_name)
          if preferred_item_name and preferred_item_name == item_name then
            score = score + constants.squirrel_repeat_item_bonus
          end

          if not best or score > best.score then
            best = serialize_target(entity, "belt", item_name, 1)
            best.line_index = line_index
            best.score = score
          end
        end
      end
    end
  end

  return best
end

local function choose_chest_item(entity, preferred_item_name, report)
  if not CHEST_TYPES[entity.type] then
    return nil
  end

  if entity.type == "infinity-container" then
    return nil
  end

  local inventory = entity.get_inventory(defines.inventory.chest)
  if not (inventory and inventory.valid and not inventory.is_empty()) then
    return nil
  end

  local best
  local desired_count = math.min(
    constants.max_chest_scavenge_count,
    math.max(1, 1 + math.floor((report.habitat_pressure - constants.squirrel_chest_pressure_threshold) / 12))
  )

  for _, item in ipairs(inventory.get_contents()) do
    local score = item_desirability(item.name)
    if preferred_item_name and preferred_item_name == item.name then
      score = score + constants.squirrel_repeat_item_bonus
    end

    if not best or score > best.score then
      best = serialize_target(entity, "chest", item.name, math.min(item.count or 1, desired_count))
      best.score = score
    end
  end

  return best
end

local function find_targets(record, report, tick)
  local surface = game.surfaces[record.surface_index]
  if not surface then
    return nil
  end

  local area = {
    left_top = {
      x = record.home_position.x - constants.squirrel_target_radius,
      y = record.home_position.y - constants.squirrel_target_radius
    },
    right_bottom = {
      x = record.home_position.x + constants.squirrel_target_radius,
      y = record.home_position.y + constants.squirrel_target_radius
    }
  }
  local preferred_item_name = record.last_loot_name
  local best

  for _, entity in ipairs(surface.find_entities_filtered({
    area = area,
    type = {"transport-belt", "underground-belt", "splitter"}
  })) do
    if entity.valid and not target_is_on_cooldown(entity, tick) then
      local candidate = choose_belt_item(entity, preferred_item_name)
      if candidate then
        candidate.score = candidate.score - (distance_squared(record.home_position, entity.position) * 0.015)
        if not best or candidate.score > best.score then
          best = candidate
        end
      end
    end
  end

  if report.habitat_pressure >= constants.squirrel_chest_pressure_threshold then
    for _, entity in ipairs(surface.find_entities_filtered({
      area = area,
      type = {"container", "logistic-container"}
    })) do
      if entity.valid and not target_is_on_cooldown(entity, tick) then
        local candidate = choose_chest_item(entity, preferred_item_name, report)
        if candidate then
          candidate.score = candidate.score - (distance_squared(record.home_position, entity.position) * 0.02)
          if not best or candidate.score > best.score then
            best = candidate
          end
        end
      end
    end
  end

  return best
end

local function move_entity(entity, destination)
  local ok = pcall(function()
    entity.set_command({
      type = defines.command.go_to_location,
      destination = destination,
      radius = 0.8,
      distraction = defines.distraction.none
    })
  end)

  if not ok then
    entity.teleport(destination)
  end
end

local function send_home(record, entity, tick)
  record.mode = "roam"
  record.target = nil
  record.intent = nil
  record.stash_id = nil
  record.destination = clone_position(record.home_position)
  record.action_due_tick = tick + constants.squirrel_move_timeout
  record.next_decision_tick = tick + constants.squirrel_decision_interval
  move_entity(entity, record.home_position)
end

local function available_region_stashes(surface_index, region_x, region_y)
  local matches = {}

  for stash_id, stash in pairs(get_surface_stashes(surface_index)) do
    if stash.region_x == region_x and stash.region_y == region_y then
      local entity = resolve_entity_reference(stash.entity)
      if entity and entity.valid then
        matches[#matches + 1] = {
          stash_id = stash_id,
          entity = entity,
          region_x = stash.region_x,
          region_y = stash.region_y,
          position = clone_position(entity.position)
        }
      end
    end
  end

  table.sort(matches, function(left, right)
    return left.stash_id < right.stash_id
  end)

  return matches
end

local function register_stash(entity, region_x, region_y)
  if not (entity and entity.valid) then
    return nil
  end

  local stash_id = next_stash_id()
  get_surface_stashes(entity.surface.index)[stash_id] = {
    stash_id = stash_id,
    entity = entity,
    surface_index = entity.surface.index,
    region_x = region_x,
    region_y = region_y,
    position = clone_position(entity.position)
  }
  return stash_id
end

local function stash_with_capacity(entity)
  local inventory = entity.get_inventory(defines.inventory.chest)
  return inventory and inventory.valid and inventory.can_insert({name = constants.names.nut, count = 1})
end

local function inventory_total_count(inventory)
  if not (inventory and inventory.valid) then
    return 0
  end

  local total = 0
  for _, item in ipairs(inventory.get_contents()) do
    total = total + (item.count or 0)
  end

  return total
end

local function find_stash_position(surface, origin)
  if surface.can_place_entity({
    name = constants.names.stash,
    position = origin,
    force = "neutral"
  }) then
    return clone_position(origin)
  end

  for current_radius = 0.5, constants.squirrel_stash_search_radius, 0.5 do
    local samples = math.max(8, math.floor((current_radius * math.pi * 2) / 0.5))

    for sample = 1, samples do
      local angle = (sample / samples) * math.pi * 2
      local candidate = {
        x = origin.x + (math.cos(angle) * current_radius),
        y = origin.y + (math.sin(angle) * current_radius)
      }

      if surface.can_place_entity({
        name = constants.names.stash,
        position = candidate,
        force = "neutral"
      }) then
        return candidate
      end
    end
  end

  return surface.find_non_colliding_position(
    constants.names.stash,
    origin,
    constants.squirrel_stash_search_radius,
    0.5,
    true
  )
end

local function ensure_stash(record)
  local surface = game.surfaces[record.surface_index]
  if not surface then
    return nil
  end

  local preferred = record.stash_id and get_surface_stashes(record.surface_index)[record.stash_id] or nil
  local preferred_entity = preferred and resolve_entity_reference(preferred.entity) or nil
  if preferred_entity and stash_with_capacity(preferred_entity) then
    return preferred_entity
  end

  for _, stash in ipairs(available_region_stashes(record.surface_index, record.region_x, record.region_y)) do
    if stash_with_capacity(stash.entity) then
      record.stash_id = stash.stash_id
      return stash.entity
    end
  end

  local region_stashes = available_region_stashes(record.surface_index, record.region_x, record.region_y)
  if #region_stashes >= constants.max_stashes_per_region then
    record.stash_id = region_stashes[1].stash_id
    return region_stashes[1].entity
  end

  local position = find_stash_position(surface, record.home_position)
  if not position then
    return nil
  end

  local created = surface.create_entity({
    name = constants.names.stash,
    position = position,
    force = "neutral",
    create_build_effect_smoke = false,
    spawn_decorations = false
  })

  if created and created.valid then
    record.stash_id = register_stash(created, record.region_x, record.region_y)
    return created
  end

  return nil
end

local function clear_carrying(record, entity)
  record.carrying = nil
  sync_render(record, entity)
end

local function deposit_or_spill(record, entity)
  if not record.carrying then
    return true
  end

  local stash = ensure_stash(record)
  local surface = game.surfaces[record.surface_index]
  if not surface then
    return false
  end

  if stash and stash.valid then
    local inventory = stash.get_inventory(defines.inventory.chest)
    if inventory and inventory.valid and inventory.can_insert(record.carrying) then
      inventory.insert(record.carrying)
      clear_carrying(record, entity)
      return true
    end
  end

  surface.spill_item_stack(entity.position, record.carrying, true, nil, false)
  clear_carrying(record, entity)
  return true
end

local function set_carrying(record, entity, item_name, count)
  record.carrying = {name = item_name, count = count}
  record.last_loot_name = item_name
  sync_render(record, entity)
end

local function region_from_record(record)
  return get_region_activity(record.surface_index, record.region_x, record.region_y)
end

local function theft_is_available(record, tick)
  if tick < (record.last_action_tick + constants.squirrel_action_cooldown) then
    return false
  end

  local activity = region_from_record(record)
  return tick >= (activity.last_theft_tick + constants.squirrel_region_action_cooldown)
end

local function start_retreat(record, entity, tick)
  local stash = ensure_stash(record)
  record.mode = "retreat"
  record.intent = "deposit"
  record.target = stash and serialize_target(stash, "stash") or nil
  record.destination = stash and clone_position(stash.position) or clone_position(record.home_position)
  record.action_due_tick = tick + constants.squirrel_move_timeout
  record.next_decision_tick = tick + constants.squirrel_decision_interval
  move_entity(entity, record.destination)
end

local function start_roam(record, entity, tick)
  local angle_seed = (record.squirrel_id or 1) + tick
  local angle = ((angle_seed % 360) / 180) * math.pi
  local destination = position_with_offset(
    record.home_position,
    angle,
    constants.squirrel_home_wander_distance
  )

  local surface = game.surfaces[record.surface_index]
  if surface then
    destination = surface.find_non_colliding_position(constants.names.squirrel, destination, 6, 0.5, true) or destination
  end

  record.mode = "roam"
  record.intent = nil
  record.target = nil
  record.destination = clone_position(destination)
  record.action_due_tick = tick + constants.squirrel_move_timeout
  record.next_decision_tick = tick + constants.squirrel_decision_interval
  move_entity(entity, destination)
end

local function start_target_run(record, entity, target, intent, tick)
  record.mode = "approach"
  record.intent = intent
  record.target = target
  record.destination = clone_position(target.position)
  record.action_due_tick = tick + constants.squirrel_move_timeout
  record.next_decision_tick = tick + constants.squirrel_decision_interval
  move_entity(entity, target.position)
end

local function start_belt_block(record, entity, belt_entity, tick)
  record.mode = "blocking"
  record.intent = "steal"
  record.target = serialize_target(belt_entity, "belt", record.target and record.target.item_name or nil, 1)
  record.destination = clone_position(belt_entity.position)
  record.action_due_tick = tick + constants.squirrel_belt_block_duration
  record.next_decision_tick = tick + constants.squirrel_decision_interval
  entity.teleport(belt_entity.position)
end

local function remove_belt_item(belt_entity, item_name)
  for line_index = 1, constants.squirrel_transport_line_scan_limit do
    local ok, line = pcall(function()
      return belt_entity.get_transport_line(line_index)
    end)

    if ok and line and line.valid then
      local removed = line.remove_item({name = item_name, count = 1})
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
    send_home(record, entity, tick)
    return false
  end

  local removed = remove_belt_item(belt_entity, item_name)
  if removed <= 0 then
    send_home(record, entity, tick)
    return false
  end

  set_carrying(record, entity, item_name, 1)
  record.last_action_tick = tick
  note_target_cooldown(belt_entity, tick)
  local activity = region_from_record(record)
  activity.last_theft_tick = tick
  start_retreat(record, entity, tick)
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

local function eligible_spawn_position(surface, region_x, region_y, existing_count, force)
  local area = regions.region_area(region_x, region_y)
  local trees = surface.find_entities_filtered({
    area = area,
    type = "tree"
  })

  if #trees > 0 then
    table.sort(trees, function(left, right)
      if left.position.y == right.position.y then
        return left.position.x < right.position.x
      end

      return left.position.y < right.position.y
    end)

    local tree = trees[((existing_count or 0) % #trees) + 1]
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

    for _, anchor in ipairs(anchors) do
      local position = spawn_position_near_anchor(surface, anchor, 10, force)
      if position then
        return position
      end
    end
  end

  for _, anchor in ipairs(region_search_anchors(area)) do
    local position = spawn_position_near_anchor(surface, anchor, 14, force)
    if position then
      return position
    end
  end

  return nil
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
    surface_index = entity.surface.index,
    home_position = clone_position(home_position),
    region_x = region_x,
    region_y = region_y,
    state = "calm",
    mode = "roam",
    intent = nil,
    target = nil,
    carrying = nil,
    destination = clone_position(home_position),
    next_decision_tick = tick,
    action_due_tick = tick,
    last_action_tick = 0,
    last_loot_name = nil,
    stash_id = nil,
    render_id = nil
  }

  get_squirrel_store()[squirrel_id] = record
  get_region_activity(entity.surface.index, region_x, region_y).last_spawn_tick = tick
  start_roam(record, entity, tick)
  return record
end

local function count_region_squirrels(surface_index, region_x, region_y)
  local count = 0

  for _, record in pairs(get_squirrel_store()) do
    if record.surface_index == surface_index and record.region_x == region_x and record.region_y == region_y then
      local entity = resolve_entity_reference(record.entity)
      if entity and entity.valid then
        count = count + 1
      end
    end
  end

  return count
end

function squirrels.ensure_population_in_region(surface, region_x, region_y, tick)
  local squirrel_force = ensure_squirrel_force()
  local report = region_report(surface.index, region_x, region_y, tick)
  local target = squirrel_population_target(report)
  local existing = count_region_squirrels(surface.index, region_x, region_y)
  local created = 0

  while existing + created < target do
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

    create_record(entity, position, region_x, region_y, tick)
    created = created + 1
  end

  return created
end

local function process_idle_decision(record, entity, tick)
  local state, report = squirrel_state_for_region(record.surface_index, record.region_x, record.region_y, tick)
  record.state = state

  if record.carrying then
    start_retreat(record, entity, tick)
    return
  end

  if state == "calm" then
    start_roam(record, entity, tick)
    return
  end

  if (state == "mischievous" or state == "agitated" or state == "grieving") and not theft_is_available(record, tick) then
    start_roam(record, entity, tick)
    return
  end

  local target = find_targets(record, report, tick)
  if not target then
    start_roam(record, entity, tick)
    return
  end

  if state == "curious" then
    start_target_run(record, entity, target, "inspect", tick)
  else
    start_target_run(record, entity, target, "steal", tick)
  end
end

local function process_arrival(record, entity, tick)
  local target_entity = resolve_target(record)

  if record.mode == "approach" then
    if not target_entity then
      send_home(record, entity, tick)
      return
    end

    if record.target.target_type == "belt" then
      if record.intent == "inspect" then
        record.mode = "inspect"
        record.action_due_tick = tick + constants.squirrel_curious_pause_duration
        entity.teleport(target_entity.position)
      else
        start_belt_block(record, entity, target_entity, tick)
      end
      return
    end

    if record.target.target_type == "chest" then
      if record.intent == "steal" then
        perform_chest_scavenge(record, entity, tick)
      else
        send_home(record, entity, tick)
      end
      return
    end

    send_home(record, entity, tick)
    return
  end

  if record.mode == "inspect" then
    send_home(record, entity, tick)
    return
  end

  if record.mode == "blocking" then
    perform_belt_theft(record, entity, tick)
    return
  end

  if record.mode == "retreat" then
    deposit_or_spill(record, entity)
    send_home(record, entity, tick)
  end
end

local function cleanup_invalid_squirrels()
  for squirrel_id, record in pairs(get_squirrel_store()) do
    local entity = resolve_entity_reference(record.entity)
    if not (entity and entity.valid) then
      remove_record(squirrel_id)
    end
  end
end

function squirrels.cleanup_empty_stashes(surface_index)
  local destroyed = 0

  for current_surface_index, stashes in pairs(storage.squirrel_stashes or {}) do
    if not surface_index or current_surface_index == surface_index then
      for stash_id, stash in pairs(stashes) do
        local entity = resolve_entity_reference(stash.entity)
        if not (entity and entity.valid) then
          stashes[stash_id] = nil
        else
          local inventory = entity.get_inventory(defines.inventory.chest)
          if inventory and inventory.valid and inventory.is_empty() then
            local targeted = false
            for _, record in pairs(get_squirrel_store()) do
              if record.stash_id == stash_id then
                targeted = true
                break
              end
            end

            if not targeted then
              entity.destroy()
              stashes[stash_id] = nil
              destroyed = destroyed + 1
            end
          end
        end
      end
    end
  end

  return destroyed
end

function squirrels.on_tick(tick)
  cleanup_invalid_squirrels()

  if tick % constants.squirrel_update_interval == 0 then
    for _, coord in ipairs(active_region_coords()) do
      local surface = game.surfaces[coord.surface_index]
      if surface then
        squirrels.ensure_population_in_region(surface, coord.region_x, coord.region_y, tick)
      end
    end

    squirrels.cleanup_empty_stashes()

    for _, record in pairs(get_squirrel_store()) do
      local entity = resolve_entity_reference(record.entity)
      if entity and entity.valid then
        if record.mode == "roam" and tick >= record.next_decision_tick then
          process_idle_decision(record, entity, tick)
        elseif tick >= record.action_due_tick then
          process_arrival(record, entity, tick)
        elseif record.destination and reached_position(entity, record.destination) then
          process_arrival(record, entity, tick)
        end
      end
    end
  end
end

function squirrels.on_squirrel_removed(entity, tick)
  if not (entity and entity.valid and entity.name == constants.names.squirrel) then
    return
  end

  local squirrel_id
  local record

  for current_squirrel_id, current_record in pairs(get_squirrel_store()) do
    if current_record.entity == entity then
      squirrel_id = current_squirrel_id
      record = current_record
      break
    end
  end

  if record and record.carrying then
    entity.surface.spill_item_stack(entity.position, record.carrying, true, nil, false)
  end

  local coord = regions.position_to_region_coord(entity.position)
  get_region_activity(entity.surface.index, coord.x, coord.y).grief_until_tick =
    (tick or game.tick) + constants.squirrel_grief_duration
  if squirrel_id then
    remove_record(squirrel_id)
  end
end

local function note_squirrel_loss(record, entity, tick)
  if record and record.carrying then
    entity.surface.spill_item_stack(entity.position, record.carrying, true, nil, false)
  end

  local coord = regions.position_to_region_coord(entity.position)
  get_region_activity(entity.surface.index, coord.x, coord.y).grief_until_tick =
    (tick or game.tick) + constants.squirrel_grief_duration
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

local function get_squirrel_record(squirrel_id)
  return get_squirrel_store()[squirrel_id]
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

  local removed = perform_belt_theft(record, entity, tick or game.tick)
  if not removed then
    return nil
  end

  local stash = ensure_stash(record)
  local stash_id = record.stash_id
  if stash then
    entity.teleport(stash.position)
  end

  deposit_or_spill(record, entity)
  send_home(record, entity, tick or game.tick)

  return {
    item_name = record.last_loot_name,
    count = 1,
    stash_id = stash_id
  }
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

  if not record then
    return nil
  end

  if not theft_is_available(record, tick or game.tick) then
    return nil
  end

  local report = region_report(record.surface_index, record.region_x, record.region_y, tick or game.tick)
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

  local stash = ensure_stash(record)
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
          state = record.state,
          mode = record.mode,
          region_x = record.region_x,
          region_y = record.region_y,
          carrying = record.carrying and record.carrying.name or nil,
          stash_id = record.stash_id,
          position = clone_position(entity.position),
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
  local state = squirrel_state_for_region(surface_index, coord.x, coord.y, tick or game.tick)
  return state
end

function squirrels.debug_item_desirability(item_name)
  return item_desirability(item_name)
end

return squirrels
