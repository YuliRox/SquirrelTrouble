local constants = require("scripts.constants")
local position_ops = require("scripts.squirrels.position")
local storage_ops = require("scripts.squirrels.storage")
local target_ops = require("scripts.squirrels.target")

local resolve_entity_reference = target_ops.resolve_entity_reference
local clone_position = position_ops.clone
local region_key = storage_ops.region_key
local get_stash_target_counts = storage_ops.get_stash_target_counts
local get_region_stash_entry = storage_ops.get_region_stash_entry
local get_surface_stashes = storage_ops.get_surface_stashes
local next_stash_id = storage_ops.next_stash_id
local get_surface_stashes_by_region = storage_ops.get_surface_stashes_by_region

local M = {}

function M.install(deps)
  local function set_record_stash(record, stash_id)
    if not record or record.stash_id == stash_id then
      return
    end

    local target_counts = get_stash_target_counts()
    if record.stash_id then
      local remaining = (target_counts[record.stash_id] or 0) - 1
      if remaining > 0 then
        target_counts[record.stash_id] = remaining
      else
        target_counts[record.stash_id] = nil
      end
    end

    record.stash_id = stash_id

    if stash_id then
      target_counts[stash_id] = (target_counts[stash_id] or 0) + 1
    end
  end

  local function available_region_stashes(surface_index, region_x, region_y)
    local matches = {}

    for stash_id in pairs(get_region_stash_entry(surface_index, region_x, region_y).ids) do
      local stash = get_surface_stashes(surface_index)[stash_id]
      if stash then
        local entity = resolve_entity_reference(stash.entity)
        if entity and entity.valid then
          matches[#matches + 1] = {
            stash_id = stash_id,
            entity = entity,
            region_x = stash.region_x,
            region_y = stash.region_y,
            position = clone_position(entity.position)
          }
        else
          get_surface_stashes(surface_index)[stash_id] = nil
          get_region_stash_entry(surface_index, region_x, region_y).ids[stash_id] = nil
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
    get_region_stash_entry(entity.surface.index, region_x, region_y).ids[stash_id] = true
    return stash_id
  end

  local function unregister_stash(surface_index, stash_id)
    local stash = get_surface_stashes(surface_index)[stash_id]
    if not stash then
      return
    end

    get_surface_stashes(surface_index)[stash_id] = nil
    get_stash_target_counts()[stash_id] = nil

    local region_entry = get_region_stash_entry(surface_index, stash.region_x, stash.region_y)
    region_entry.ids[stash_id] = nil
    if not next(region_entry.ids) then
      get_surface_stashes_by_region(surface_index)[region_key(stash.region_x, stash.region_y)] = nil
    end
  end

  local function stash_can_accept(entity, item_stack)
    local inventory = entity.get_inventory(defines.inventory.chest)
    local stack = item_stack or {name = constants.names.nut, count = 1}
    return inventory and inventory.valid and inventory.can_insert(stack)
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

  local function ensure_stash(record, item_stack, origin_position)
    local surface = game.surfaces[record.surface_index]
    if not surface then
      return nil
    end

    local preferred = record.stash_id and get_surface_stashes(record.surface_index)[record.stash_id] or nil
    local preferred_entity = preferred and resolve_entity_reference(preferred.entity) or nil
    if preferred_entity and stash_can_accept(preferred_entity, item_stack) then
      return preferred_entity
    end

    for _, stash in ipairs(available_region_stashes(record.surface_index, record.region_x, record.region_y)) do
      if stash_can_accept(stash.entity, item_stack) then
        set_record_stash(record, stash.stash_id)
        return stash.entity
      end
    end

    local region_stashes = available_region_stashes(record.surface_index, record.region_x, record.region_y)
    local allow_overflow = item_stack ~= nil
    if #region_stashes >= constants.max_stashes_per_region and not allow_overflow then
      if region_stashes[1] then
        set_record_stash(record, region_stashes[1].stash_id)
        return region_stashes[1].entity
      end
      return nil
    end

    local position = find_stash_position(surface, origin_position or record.home_position)
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
      set_record_stash(record, register_stash(created, record.region_x, record.region_y))
      return created
    end

    return nil
  end

  local function cleanup_empty_stashes(surface_index)
    local destroyed = 0

    for current_surface_index, stashes in pairs(storage.squirrel_stashes or {}) do
      if not surface_index or current_surface_index == surface_index then
        for stash_id, stash in pairs(stashes) do
          local entity = resolve_entity_reference(stash.entity)
          if not (entity and entity.valid) then
            unregister_stash(current_surface_index, stash_id)
          else
            local inventory = entity.get_inventory(defines.inventory.chest)
            if inventory and inventory.valid and inventory.is_empty() then
              if not get_stash_target_counts()[stash_id] then
                entity.destroy()
                unregister_stash(current_surface_index, stash_id)
                destroyed = destroyed + 1
              end
            end
          end
        end
      end
    end

    return destroyed
  end

  return {
    set_record_stash = set_record_stash,
    available_region_stashes = available_region_stashes,
    register_stash = register_stash,
    unregister_stash = unregister_stash,
    stash_can_accept = stash_can_accept,
    inventory_total_count = inventory_total_count,
    find_stash_position = find_stash_position,
    ensure_stash = ensure_stash,
    cleanup_empty_stashes = cleanup_empty_stashes
  }
end

return M
