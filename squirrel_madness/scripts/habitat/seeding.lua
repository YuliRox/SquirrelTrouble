local constants = require("scripts.constants")
local regions = require("scripts.regions.module")
local world = require("scripts.habitat.world")

local clone_position = world.clone_position
local is_supported_surface = world.is_supported_surface
local chunk_key = world.chunk_key
local chunk_area = world.chunk_area
local create_neutral_entity = world.create_neutral_entity

local M = {}

local function get_seeded_chunks(surface_index)
  storage.seeded_chunks[surface_index] = storage.seeded_chunks[surface_index] or {}
  return storage.seeded_chunks[surface_index]
end

local function collect_seed_candidates(surface, area)
  local trees = surface.find_entities_filtered({
    area = area,
    type = "tree"
  })
  local candidates = {}

  for _, tree in ipairs(trees) do
    if
      tree.valid
      and tree.name ~= constants.names.nut_tree
      and tree.name ~= constants.names.nut_tree_harvested
      and tree.name ~= constants.names.nut_sapling
    then
      candidates[#candidates + 1] = tree
    end
  end

  table.sort(candidates, function(left, right)
    if left.position.y == right.position.y then
      return left.position.x < right.position.x
    end

    return left.position.y < right.position.y
  end)

  return candidates
end

local function select_spread_candidates(candidates, desired_count)
  local selected = {}
  local used = {}

  if desired_count <= 0 then
    return selected
  end

  for selection_index = 1, desired_count do
    local candidate_index = math.floor((selection_index * (#candidates + 1)) / (desired_count + 1))
    candidate_index = math.max(1, math.min(candidate_index, #candidates))

    while used[candidate_index] and candidate_index < #candidates do
      candidate_index = candidate_index + 1
    end

    while used[candidate_index] and candidate_index > 1 do
      candidate_index = candidate_index - 1
    end

    if not used[candidate_index] then
      used[candidate_index] = true
      selected[#selected + 1] = candidates[candidate_index]
    end
  end

  return selected
end

local function replace_with_nut_tree(tree)
  if not (tree and tree.valid and tree.surface and tree.surface.valid) then
    return nil
  end

  local surface = tree.surface
  local position = clone_position(tree.position)

  if not tree.destroy() then
    return nil
  end

  local created = create_neutral_entity(surface, constants.names.nut_tree, position, false)
  if created and created.valid then
    regions.mark_dirty(surface.index, position)
  end

  return created
end

local function top_up_starting_grove(surface, spawn_position, remaining)
  local created = 0

  for attempt = 1, constants.starting_grove_fallback_attempts do
    if remaining <= 0 then
      break
    end

    local angle = (attempt / constants.starting_grove_fallback_attempts) * math.pi * 2
    local radius = 18 + (attempt * 4)
    local anchor = {
      x = spawn_position.x + (math.cos(angle) * radius),
      y = spawn_position.y + (math.sin(angle) * radius)
    }
    local position = surface.find_non_colliding_position(constants.names.nut_tree, anchor, 12, 0.5, true)

    if position then
      local entity = create_neutral_entity(surface, constants.names.nut_tree, position, false)
      if entity and entity.valid then
        created = created + 1
        remaining = remaining - 1
        regions.mark_dirty(surface.index, position)
      end
    end
  end

  return created
end

function M.seed_nut_trees_in_area(surface, area, desired_count, allow_sparse_patch)
  if not is_supported_surface(surface) then
    return 0
  end

  local candidates = collect_seed_candidates(surface, area)
  if #candidates == 0 then
    return 0
  end

  local target_count = desired_count
  if not target_count then
    if #candidates < constants.nut_tree_seed_min_regular_trees and not allow_sparse_patch then
      return 0
    end

    target_count = math.floor(#candidates / constants.nut_trees_per_chunk_divisor)
    if target_count < 1 then
      target_count = 1
    end

    target_count = math.min(target_count, constants.max_nut_trees_per_chunk)
  end

  target_count = math.min(target_count, #candidates)
  local created = 0

  for _, tree in ipairs(select_spread_candidates(candidates, target_count)) do
    if replace_with_nut_tree(tree) then
      created = created + 1
    end
  end

  return created
end

function M.seed_chunk(surface, chunk_position, area)
  if not is_supported_surface(surface) then
    return 0
  end

  local seeded_chunks = get_seeded_chunks(surface.index)
  local key = chunk_key(chunk_position)
  if seeded_chunks[key] then
    return 0
  end

  seeded_chunks[key] = true
  return M.seed_nut_trees_in_area(surface, area or chunk_area(chunk_position), nil, false)
end

function M.ensure_starting_grove(surface)
  if not is_supported_surface(surface) then
    return 0
  end

  local player_force = game.forces.player
  if not player_force then
    return 0
  end

  local spawn_position = player_force.get_spawn_position(surface)
  local area = {
    left_top = {
      x = spawn_position.x - constants.starting_grove_radius,
      y = spawn_position.y - constants.starting_grove_radius
    },
    right_bottom = {
      x = spawn_position.x + constants.starting_grove_radius,
      y = spawn_position.y + constants.starting_grove_radius
    }
  }
  local existing = surface.count_entities_filtered({
    area = area,
    name = constants.names.nut_tree
  })

  if existing >= constants.starting_grove_target then
    return 0
  end

  local created = M.seed_nut_trees_in_area(
    surface,
    area,
    constants.starting_grove_target - existing,
    true
  )
  local remaining = constants.starting_grove_target - existing - created

  if remaining > 0 then
    created = created + top_up_starting_grove(surface, spawn_position, remaining)
  end

  return created
end

return M
