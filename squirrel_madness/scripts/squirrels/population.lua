local constants = require("scripts.constants")
local regions = require("scripts.regions.module")
local position_ops = require("scripts.squirrels.position")
local storage_ops = require("scripts.squirrels.storage")

local clone_position = position_ops.clone
local position_respects_player_buffer = position_ops.position_respects_player_buffer
local nearest_player_distance_squared = position_ops.nearest_player_distance_squared
local get_region_squirrel_entry = storage_ops.get_region_squirrel_entry
local get_squirrel_store = storage_ops.get_squirrel_store
local parse_region_key = storage_ops.parse_region_key
local active_region_key = storage_ops.active_region_key

local M = {}

function M.install(deps)
  local create_record = deps.create_record
  local process_idle_decision = deps.process_idle_decision
  local ensure_squirrel_force = deps.ensure_squirrel_force
  local region_report = deps.region_report
  local chunk_area = deps.chunk_area
  local resolve_entity_reference = deps.resolve_entity_reference
  local remove_record = deps.remove_record
  local deposit_or_spill = deps.deposit_or_spill
  local clear_carrying = deps.clear_carrying

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

  local function count_region_squirrels(surface_index, region_x, region_y)
    return get_region_squirrel_entry(surface_index, region_x, region_y).count
  end

  local function ensure_population_in_region(surface, region_x, region_y, tick, force_recompute)
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

  local function seed_chunk_population(surface, chunk_position, area, tick)
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

  return {
    spawn_position_near_anchor = spawn_position_near_anchor,
    eligible_spawn_position = eligible_spawn_position,
    count_region_squirrels = count_region_squirrels,
    active_region_coords = active_region_coords,
    cull_inactive_squirrels = cull_inactive_squirrels,
    ensure_population_in_region = ensure_population_in_region,
    seed_chunk_population = seed_chunk_population
  }
end

return M
