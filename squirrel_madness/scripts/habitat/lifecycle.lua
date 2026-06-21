local constants = require("scripts.constants")
local regions = require("scripts.regions.module")
local world = require("scripts.habitat.world")

local clone_position = world.clone_position
local positions_equal = world.positions_equal
local is_supported_surface = world.is_supported_surface
local create_neutral_entity = world.create_neutral_entity
local find_named_entity = world.find_named_entity

local M = {}

local function remove_tracked_entries(entries, surface_index, position)
  for entry_id, entry in pairs(entries) do
    if entry.surface_index == surface_index and positions_equal(entry.position, position) then
      entries[entry_id] = nil
    end
  end
end

local function register_tracked_entry(entries, next_id_key, surface_index, position, mature_tick)
  local entry_id = storage[next_id_key]
  storage[next_id_key] = entry_id + 1
  entries[entry_id] = {
    surface_index = surface_index,
    position = clone_position(position),
    mature_tick = mature_tick
  }
  return entries[entry_id]
end

local function mature_tracked_entries(entries, current_tick, surface_index, current_name, next_name)
  local matured = 0

  for entry_id, entry in pairs(entries) do
    if entry.mature_tick <= current_tick and (not surface_index or entry.surface_index == surface_index) then
      local surface = game.surfaces[entry.surface_index]
      if surface then
        local entity = find_named_entity(surface, current_name, entry.position)
        if entity and entity.valid then
          local position = clone_position(entity.position)
          entity.destroy()

          local replacement = create_neutral_entity(surface, next_name, position, false)
          if replacement and replacement.valid then
            matured = matured + 1
            regions.mark_dirty(surface.index, position)
          end
        end
      end

      entries[entry_id] = nil
    end
  end

  return matured
end

local function schedule_entity_replacement(surface_index, position, name, due_tick)
  storage.pending_entity_replacements[#storage.pending_entity_replacements + 1] = {
    surface_index = surface_index,
    position = clone_position(position),
    name = name,
    due_tick = due_tick
  }
end

function M.resolve_pending_replacements(current_tick, surface_index)
  local replacements = storage.pending_entity_replacements
  if #replacements == 0 then
    return 0
  end

  local write_index = 1
  local created = 0

  for read_index = 1, #replacements do
    local replacement = replacements[read_index]
    if replacement.due_tick <= current_tick and (not surface_index or replacement.surface_index == surface_index) then
      local surface = game.surfaces[replacement.surface_index]
      if surface then
        local entity = create_neutral_entity(surface, replacement.name, replacement.position, false)
        if entity and entity.valid then
          created = created + 1
          regions.mark_dirty(surface.index, replacement.position)

          if replacement.name == constants.names.nut_tree_harvested then
            M.register_harvested_nut_tree(entity, current_tick)
          end
        else
          replacements[write_index] = replacement
          write_index = write_index + 1
        end
      end
    else
      replacements[write_index] = replacement
      write_index = write_index + 1
    end
  end

  for index = write_index, #replacements do
    replacements[index] = nil
  end

  return created
end

function M.register_sapling(entity, tick)
  if not (entity and entity.valid and entity.name == constants.names.nut_sapling and is_supported_surface(entity.surface)) then
    return nil
  end

  remove_tracked_entries(storage.saplings, entity.surface.index, entity.position)
  local sapling = register_tracked_entry(
    storage.saplings,
    "next_sapling_id",
    entity.surface.index,
    entity.position,
    (tick or game.tick) + constants.nut_sapling_growth_time
  )
  regions.mark_dirty(entity.surface.index, entity.position)

  return sapling
end

function M.unregister_sapling(surface_index, position)
  remove_tracked_entries(storage.saplings, surface_index, position)
end

function M.mature_ready_saplings(current_tick, surface_index)
  return mature_tracked_entries(
    storage.saplings,
    current_tick,
    surface_index,
    constants.names.nut_sapling,
    constants.names.nut_tree
  )
end

function M.force_mature_all_saplings(current_tick, surface_index)
  for _, sapling in pairs(storage.saplings) do
    if not surface_index or sapling.surface_index == surface_index then
      sapling.mature_tick = current_tick
    end
  end

  return M.mature_ready_saplings(current_tick, surface_index)
end

function M.register_harvested_nut_tree(entity, tick)
  if not (entity and entity.valid and entity.name == constants.names.nut_tree_harvested and is_supported_surface(entity.surface)) then
    return nil
  end

  remove_tracked_entries(storage.harvested_nut_trees, entity.surface.index, entity.position)
  return register_tracked_entry(
    storage.harvested_nut_trees,
    "next_harvested_nut_tree_id",
    entity.surface.index,
    entity.position,
    (tick or game.tick) + constants.nut_tree_harvest_regrowth_time
  )
end

function M.unregister_harvested_nut_tree(surface_index, position)
  remove_tracked_entries(storage.harvested_nut_trees, surface_index, position)
end

function M.recover_ready_harvested_nut_trees(current_tick, surface_index)
  return mature_tracked_entries(
    storage.harvested_nut_trees,
    current_tick,
    surface_index,
    constants.names.nut_tree_harvested,
    constants.names.nut_tree
  )
end

function M.force_recover_all_harvested_nut_trees(current_tick, surface_index)
  for _, harvested_tree in pairs(storage.harvested_nut_trees) do
    if not surface_index or harvested_tree.surface_index == surface_index then
      harvested_tree.mature_tick = current_tick
    end
  end

  return M.recover_ready_harvested_nut_trees(current_tick, surface_index)
end

function M.harvest_nut_tree(entity, tick)
  if not (entity and entity.valid and entity.name == constants.names.nut_tree and is_supported_surface(entity.surface)) then
    return false
  end

  schedule_entity_replacement(
    entity.surface.index,
    entity.position,
    constants.names.nut_tree_harvested,
    (tick or game.tick) + 1
  )
  regions.mark_dirty(entity.surface.index, entity.position)

  return true
end

return M
