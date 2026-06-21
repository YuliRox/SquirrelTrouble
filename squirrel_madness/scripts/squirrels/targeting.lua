local constants = require("scripts.constants")
local math2d = require("math2d")
local target_ops = require("scripts.squirrels.target")
local state_ops = require("scripts.squirrels.state")

local serialize_target = target_ops.serialize_target
local resolve_target_reference = target_ops.resolve_target_reference
local squirrel_state_for_region = state_ops.squirrel_state_for_region

local M = {}

function M.install(deps)
  local BELT_TYPES = deps.BELT_TYPES
  local CHEST_TYPES = deps.CHEST_TYPES
  local round_position_key = deps.round_position_key
  local get_target_cooldowns = deps.get_target_cooldowns
  local theft_is_available = deps.theft_is_available
  local start_target_run = deps.start_target_run
  local reached_position = deps.reached_position
  local set_excursion_focus = deps.set_excursion_focus

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

  local function choose_belt_item(entity, preferred_item_name, allow_empty)
    if not BELT_TYPES[entity.type] then
      return nil
    end

    local best
    local max_line_index = math.min(entity.get_max_transport_line_index(), constants.squirrel_transport_line_scan_limit)

    for line_index = 1, max_line_index do
      local line = entity.get_transport_line(line_index)

      if line and line.valid then
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

    if not best and allow_empty then
      best = serialize_target(entity, "belt", nil, 1)
      best.line_index = 1
      best.score = 4
    end

    return best
  end

  local function choose_chest_item(entity, preferred_item_name)
    if not CHEST_TYPES[entity.type] or entity.type == "infinity-container" then
      return nil
    end

    local inventory = entity.get_inventory(defines.inventory.chest)
    if not (inventory and inventory.valid and not inventory.is_empty()) then
      return nil
    end

    local best
    for _, item in ipairs(inventory.get_contents()) do
      local score = item_desirability(item.name)
      if preferred_item_name and preferred_item_name == item.name then
        score = score + constants.squirrel_repeat_item_bonus
      end

      if not best or score > best.score then
        local prototype = prototypes.item[item.name]
        local stack_size = (prototype and prototype.stack_size) or 1
        best = serialize_target(entity, "chest", item.name, math.min(item.count or 1, stack_size))
        best.score = score
      end
    end

    return best
  end

  local function choose_feeder_item(entity, report)
    if not constants.feeder_variant_by_name[entity.name] then
      return nil
    end

    local inventory = entity.get_inventory(defines.inventory.chest)
    local nut_count = inventory and inventory.valid and inventory.get_item_count(constants.names.nut) or 0
    if nut_count <= 0 then
      return nil
    end

    local target = serialize_target(entity, "feeder", constants.names.nut, 1)
    target.score = item_desirability(constants.names.nut)
      + constants.squirrel_feeder_target_bonus
      + math.min((report and report.habitat_pressure or 0) / 8, 10)
    return target
  end

  local function target_area(origin, radius)
    return {
      left_top = {x = origin.x - radius, y = origin.y - radius},
      right_bottom = {x = origin.x + radius, y = origin.y + radius}
    }
  end

  local function state_wander_distance(state, report)
    local base = constants.squirrel_home_wander_distance

    if state == "curious" then
      base = constants.squirrel_curious_wander_distance
    elseif state == "mischievous" then
      base = constants.squirrel_mischievous_wander_distance
    elseif state == "agitated" then
      base = constants.squirrel_agitated_wander_distance
    elseif state == "grieving" then
      base = constants.squirrel_grieving_wander_distance
    end

    if report then
      base = base + math.min(report.habitat_pressure / 30, 6)
    end

    return base
  end

  local function state_local_target_radius(state)
    if state == "calm" then
      return constants.squirrel_calm_local_target_radius
    elseif state == "curious" then
      return constants.squirrel_curious_local_target_radius
    elseif state == "mischievous" then
      return constants.squirrel_mischievous_local_target_radius
    elseif state == "agitated" then
      return constants.squirrel_agitated_local_target_radius
    elseif state == "grieving" then
      return constants.squirrel_grieving_local_target_radius
    end

    return nil
  end

  local function state_can_steal(state)
    return state == "mischievous" or state == "agitated" or state == "grieving"
  end

  local function local_target_intent(state, report, target_type, can_theft)
    if target_type == "feeder" then
      return "feed"
    end

    if state == "calm" or state == "curious" then
      return target_type == "belt" and "inspect" or nil
    end

    if can_theft then
      if target_type == "belt" then
        return "steal"
      end

      if target_type == "chest" and report and report.habitat_pressure >= constants.squirrel_chest_pressure_threshold then
        return "steal"
      end
    end

    return target_type == "belt" and "inspect" or nil
  end

  local function build_squirrel_target(record, opportunity, origin_position, tick, max_distance_from_origin, max_distance_from_home)
    local entity = resolve_target_reference(record.surface_index, opportunity)
    if not (entity and entity.valid) or target_is_on_cooldown(entity, tick) then
      return nil
    end

    local current_distance_squared = math2d.position.distance_squared(origin_position, entity.position)
    if max_distance_from_origin and current_distance_squared > (max_distance_from_origin * max_distance_from_origin) then
      return nil
    end

    local target_radius = opportunity.target_type == "belt"
      and constants.squirrel_belt_target_radius
      or constants.squirrel_chest_target_radius
    if max_distance_from_home then
      target_radius = math.min(target_radius, max_distance_from_home)
    end

    if math2d.position.distance_squared(record.home_position, entity.position) > (target_radius * target_radius) then
      return nil
    end

    local candidate = serialize_target(entity, opportunity.target_type, opportunity.item_name, opportunity.count)
    if not candidate then
      return nil
    end

    candidate.score = opportunity.base_score or 0
    if candidate.item_name and record.last_loot_name and record.last_loot_name == candidate.item_name then
      candidate.score = candidate.score + constants.squirrel_repeat_item_bonus
    end

    candidate.score = candidate.score - (current_distance_squared * 0.015)
    if candidate.target_type == "belt" then
      candidate.score = candidate.score + 6
    elseif candidate.target_type == "feeder" then
      candidate.score = candidate.score + 10
    end

    return candidate
  end

  local function find_stocked_feeder_near_position(surface_index, position, radius)
    local surface = game.surfaces[surface_index]
    if not (surface and radius and radius > 0) then
      return nil
    end

    for _, feeder in ipairs(surface.find_entities_filtered({area = target_area(position, radius), name = constants.feeder_entity_names})) do
      local inventory = feeder.get_inventory(defines.inventory.chest)
      if inventory and inventory.valid and inventory.get_item_count(constants.names.nut) >= constants.stocked_feeder_threshold then
        return feeder
      end
    end

    return nil
  end

  local function stocked_feeder_near_position(surface_index, position, radius)
    return find_stocked_feeder_near_position(surface_index, position, radius) ~= nil
  end

  local function consider_scanned_target(record, entity, target_type, state, report, tick, origin_position, can_theft, max_distance_from_origin, max_distance_from_home, preferred_item_name, item_name_filter, inspect_bonus, best, best_intent)
    if not (entity and entity.valid) then
      return best, best_intent
    end

    if target_type == "belt" and stocked_feeder_near_position(record.surface_index, entity.position, constants.squirrel_feeder_peace_radius) then
      return best, best_intent
    end

    if target_is_on_cooldown(entity, tick) then
      return best, best_intent
    end

    local intent = local_target_intent(state, report, target_type, can_theft)
    if not intent then
      return best, best_intent
    end

    local opportunity
    if target_type == "belt" then
      opportunity = choose_belt_item(entity, preferred_item_name, intent == "inspect")
    elseif target_type == "chest" then
      opportunity = choose_chest_item(entity, preferred_item_name)
    elseif target_type == "feeder" then
      opportunity = choose_feeder_item(entity, report)
    end
    if not opportunity then
      return best, best_intent
    end

    if item_name_filter and opportunity.item_name ~= item_name_filter then
      return best, best_intent
    end

    local candidate = build_squirrel_target(record, opportunity, origin_position, tick, max_distance_from_origin, max_distance_from_home)
    if not candidate then
      return best, best_intent
    end

    if intent == "inspect" then
      candidate.score = candidate.score + (inspect_bonus or 0)
    end

    if not best or candidate.score > best.score then
      return candidate, intent
    end

    return best, best_intent
  end

  local function scan_targets_near_position(record, state, report, tick, origin_position, search_radius, max_distance_from_origin, max_distance_from_home, options)
    local surface = game.surfaces[record.surface_index]
    if not surface or not search_radius or search_radius <= 0 then
      return nil, nil
    end

    local can_theft = state_can_steal(state) and theft_is_available(record, tick)
    local area = target_area(origin_position, search_radius)
    local best
    local best_intent
    local preferred_item_name = options and options.preferred_item_name or record.last_loot_name
    local item_name_filter = options and options.item_name_filter or nil
    local inspect_bonus = options and options.inspect_bonus or 0

    for _, entity in ipairs(surface.find_entities_filtered({area = area, type = {"transport-belt", "underground-belt", "splitter"}})) do
      best, best_intent = consider_scanned_target(record, entity, "belt", state, report, tick, origin_position, can_theft, max_distance_from_origin, max_distance_from_home, preferred_item_name, item_name_filter, inspect_bonus, best, best_intent)
    end

    for _, entity in ipairs(surface.find_entities_filtered({area = area, name = constants.feeder_entity_names})) do
      best, best_intent = consider_scanned_target(record, entity, "feeder", state, report, tick, origin_position, can_theft, max_distance_from_origin, max_distance_from_home, preferred_item_name, nil, inspect_bonus, best, best_intent)
    end

    if options and options.include_chests == false then
      return best, best_intent
    end

    for _, entity in ipairs(surface.find_entities_filtered({area = area, type = {"container", "logistic-container"}})) do
      if not constants.feeder_variant_by_name[entity.name] then
        best, best_intent = consider_scanned_target(record, entity, "chest", state, report, tick, origin_position, can_theft, max_distance_from_origin, max_distance_from_home, preferred_item_name, item_name_filter, inspect_bonus, best, best_intent)
      end
    end

    return best, best_intent
  end

  local function find_local_target(record, state, report, tick, origin_position)
    local radius = state_local_target_radius(state)
    if not radius then
      return nil, nil
    end

    local home_limit = state_wander_distance(state, report) + radius
    return scan_targets_near_position(record, state, report, tick, origin_position, radius, radius, home_limit, {inspect_bonus = 4})
  end

  local function find_excursion_target(record, state, report, tick, origin_position)
    local home_limit = state_wander_distance(state, report) + state_local_target_radius(state)
    return scan_targets_near_position(record, state, report, tick, origin_position, home_limit, nil, home_limit)
  end

  local function find_nearby_belt_target(record, state, report, tick, origin_position, item_name)
    local surface = game.surfaces[record.surface_index]
    if not surface then
      return nil
    end

    local home_limit = state_wander_distance(state, report) + constants.squirrel_belt_handoff_radius
    local best

    for _, entity in ipairs(surface.find_entities_filtered({area = target_area(origin_position, constants.squirrel_belt_handoff_radius), type = {"transport-belt", "underground-belt", "splitter"}})) do
      if entity.valid
        and not target_is_on_cooldown(entity, tick)
        and not stocked_feeder_near_position(record.surface_index, entity.position, constants.squirrel_feeder_peace_radius)
      then
        local opportunity = choose_belt_item(entity, item_name)
        if opportunity and opportunity.item_name == item_name then
          local candidate = build_squirrel_target(record, opportunity, origin_position, tick, constants.squirrel_belt_handoff_radius, home_limit)
          if candidate and (not best or candidate.score > best.score) then
            best = candidate
          end
        end
      end
    end

    return best
  end

  local function refresh_target_from_entity(target_entity, target_type, preferred_item_name, report)
    if target_type == "belt" and stocked_feeder_near_position(target_entity.surface.index, target_entity.position, constants.squirrel_feeder_peace_radius) then
      return nil
    end

    local opportunity
    if target_type == "belt" then
      opportunity = choose_belt_item(target_entity, preferred_item_name)
    elseif target_type == "chest" then
      opportunity = choose_chest_item(target_entity, preferred_item_name)
    elseif target_type == "feeder" then
      opportunity = choose_feeder_item(target_entity, report)
    end

    if not opportunity then
      return nil
    end

    return serialize_target(target_entity, target_type, opportunity.item_name, opportunity.count)
  end

  local function maybe_commit_roam_target(record, entity, tick)
    if record.mode ~= "roam" or not (record.excursion_target and record.excursion_intent) then
      return false
    end

    local focus = record.excursion_target
    local target_entity = resolve_target_reference(record.surface_index, focus)
    if not (target_entity and target_entity.valid) then
      set_excursion_focus(record, nil, nil)
      return false
    end

    if target_is_on_cooldown(target_entity, tick) then
      set_excursion_focus(record, nil, nil)
      return false
    end

    if not reached_position(entity, target_entity.position, 1.4) then
      return false
    end

    local state, report = squirrel_state_for_region(record.surface_index, record.region_x, record.region_y, tick)
    record.state = state

    local refreshed_target = refresh_target_from_entity(target_entity, focus.target_type, focus.item_name, report)
    if not refreshed_target then
      set_excursion_focus(record, nil, nil)
      return false
    end

    local can_theft = state_can_steal(state) and theft_is_available(record, tick)
    local intent = local_target_intent(state, report, focus.target_type, can_theft)
    if not intent then
      set_excursion_focus(record, nil, nil)
      return false
    end

    start_target_run(record, entity, refreshed_target, intent, tick)
    return true
  end

  return {
    target_key = target_key,
    note_target_cooldown = note_target_cooldown,
    item_desirability = item_desirability,
    choose_belt_item = choose_belt_item,
    choose_chest_item = choose_chest_item,
    find_stocked_feeder_near_position = find_stocked_feeder_near_position,
    state_wander_distance = state_wander_distance,
    state_local_target_radius = state_local_target_radius,
    find_local_target = find_local_target,
    find_excursion_target = find_excursion_target,
    find_nearby_belt_target = find_nearby_belt_target,
    maybe_commit_roam_target = maybe_commit_roam_target
  }
end

return M
