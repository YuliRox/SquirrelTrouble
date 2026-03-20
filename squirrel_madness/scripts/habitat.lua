local constants = require("scripts.constants")
local regions = require("scripts.regions")

local habitat = {}

local function clone_position(position)
  return {x = position.x, y = position.y}
end

local function positions_equal(left, right)
  return left.x == right.x and left.y == right.y
end

local function chunk_key(chunk_position)
  return chunk_position.x .. "," .. chunk_position.y
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

local function is_supported_surface(surface)
  return surface and surface.valid and surface.name == constants.primary_surface_name
end

local function get_seeded_chunks(surface_index)
  storage.seeded_chunks[surface_index] = storage.seeded_chunks[surface_index] or {}
  return storage.seeded_chunks[surface_index]
end

local function get_force_tutorials(force_index)
  storage.force_tutorials[force_index] = storage.force_tutorials[force_index] or {}
  return storage.force_tutorials[force_index]
end

local function create_neutral_entity(surface, name, position, raise_built)
  return surface.create_entity({
    name = name,
    position = position,
    force = "neutral",
    raise_built = raise_built,
    create_build_effect_smoke = false,
    spawn_decorations = false
  })
end

local function remove_sapling_records(surface_index, position)
  for sapling_id, sapling in pairs(storage.saplings) do
    if sapling.surface_index == surface_index and positions_equal(sapling.position, position) then
      storage.saplings[sapling_id] = nil
    end
  end
end

local function find_sapling(surface, position)
  local matches = surface.find_entities_filtered({
    position = position,
    name = constants.names.nut_sapling,
    limit = 1
  })

  return matches[1]
end

local function collect_seed_candidates(surface, area)
  local trees = surface.find_entities_filtered({
    area = area,
    type = "tree"
  })
  local candidates = {}

  for _, tree in ipairs(trees) do
    if tree.valid and tree.name ~= constants.names.nut_tree and tree.name ~= constants.names.nut_sapling then
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

function habitat.seed_nut_trees_in_area(surface, area, desired_count, allow_sparse_patch)
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

function habitat.seed_chunk(surface, chunk_position, area)
  if not is_supported_surface(surface) then
    return 0
  end

  local seeded_chunks = get_seeded_chunks(surface.index)
  local key = chunk_key(chunk_position)
  if seeded_chunks[key] then
    return 0
  end

  seeded_chunks[key] = true
  return habitat.seed_nut_trees_in_area(surface, area or chunk_area(chunk_position), nil, false)
end

function habitat.ensure_starting_grove(surface)
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

  local created = habitat.seed_nut_trees_in_area(
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

function habitat.register_sapling(entity, tick)
  if not (entity and entity.valid and entity.name == constants.names.nut_sapling and is_supported_surface(entity.surface)) then
    return nil
  end

  remove_sapling_records(entity.surface.index, entity.position)

  local sapling_id = storage.next_sapling_id
  storage.next_sapling_id = sapling_id + 1
  storage.saplings[sapling_id] = {
    surface_index = entity.surface.index,
    position = clone_position(entity.position),
    mature_tick = (tick or game.tick) + constants.nut_sapling_growth_time
  }
  regions.mark_dirty(entity.surface.index, entity.position)

  return storage.saplings[sapling_id]
end

function habitat.unregister_sapling(surface_index, position)
  remove_sapling_records(surface_index, position)
end

function habitat.mature_ready_saplings(current_tick, surface_index)
  local matured = 0

  for sapling_id, sapling in pairs(storage.saplings) do
    if sapling.mature_tick <= current_tick and (not surface_index or sapling.surface_index == surface_index) then
      local surface = game.surfaces[sapling.surface_index]
      if surface then
        local entity = find_sapling(surface, sapling.position)
        if entity and entity.valid then
          local position = clone_position(entity.position)
          entity.destroy()

          local tree = create_neutral_entity(surface, constants.names.nut_tree, position, false)
          if tree and tree.valid then
            matured = matured + 1
            regions.mark_dirty(surface.index, position)
          end
        end
      end

      storage.saplings[sapling_id] = nil
    end
  end

  return matured
end

function habitat.force_mature_all_saplings(current_tick, surface_index)
  for _, sapling in pairs(storage.saplings) do
    if not surface_index or sapling.surface_index == surface_index then
      sapling.mature_tick = current_tick
    end
  end

  return habitat.mature_ready_saplings(current_tick, surface_index)
end

function habitat.maybe_show_deforestation_hint(player_index, surface, position, tick)
  if not player_index then
    return
  end

  local player = game.get_player(player_index)
  if not (player and player.valid and player.force and is_supported_surface(surface)) then
    return
  end

  local tutorials = get_force_tutorials(player.force.index)
  if tutorials.deforestation_hint then
    return
  end

  local region = regions.get_region_report_at_position(surface, position, tick)
  if region.recent_tree_loss >= constants.tutorial_tree_loss_threshold then
    tutorials.deforestation_hint = true
    player.force.print({"message.squirrel-madness-deforestation-hint"})
  end
end

function habitat.maybe_show_sapling_hint(player_index)
  if not player_index then
    return
  end

  local player = game.get_player(player_index)
  if not (player and player.valid and player.force) then
    return
  end

  local tutorials = get_force_tutorials(player.force.index)
  if tutorials.sapling_hint then
    return
  end

  tutorials.sapling_hint = true
  player.print({"message.squirrel-madness-sapling-planted"})
end

function habitat.on_research_finished(research)
  if not (research and research.valid and research.force and research.force.valid) then
    return
  end

  local tutorials = get_force_tutorials(research.force.index)

  if research.name == "arboriculture" and not tutorials.arboriculture_hint then
    tutorials.arboriculture_hint = true
    research.force.print({"message.squirrel-madness-arboriculture-hint"})
  elseif research.name == "wildlife-diversion" and not tutorials.wildlife_diversion_hint then
    tutorials.wildlife_diversion_hint = true
    research.force.print({"message.squirrel-madness-wildlife-diversion-hint"})
  end
end

return habitat
