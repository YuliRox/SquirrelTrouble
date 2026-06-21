local constants = require("scripts.constants")
local regions = require("scripts.regions.module")

local ORIGIN = {x = 1664, y = 192}
local TREE_NAME = "tree-01"
local spawned_entities

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

local function player()
  return game.players[1]
end

local function track_entity(entity)
  if entity then
    spawned_entities[#spawned_entities + 1] = entity
  end

  return entity
end

local function find_squirrel_entity(position)
  return surface().find_entities_filtered({
    position = position,
    name = constants.squirrel_entity_name_list,
    limit = 1
  })[1]
end

local function square_area(origin, radius)
  return {
    left_top = {x = origin.x - radius, y = origin.y - radius},
    right_bottom = {x = origin.x + radius, y = origin.y + radius}
  }
end

local function prepare_origin(origin)
  surface().request_to_generate_chunks(origin, 3)
  surface().force_generate_chunk_requests()

  local tiles = {}
  for x = origin.x - 32, origin.x + 32 do
    for y = origin.y - 32, origin.y + 32 do
      tiles[#tiles + 1] = {
        name = "grass-1",
        position = {x = x, y = y}
      }
    end
  end
  surface().set_tiles(tiles, true)

  for _, entity in ipairs(surface().find_entities_filtered({area = square_area(origin, 32)})) do
    if entity.valid and entity.type ~= "character" then
      entity.destroy()
    end
  end
end

local function spawn_forest(count, origin, spacing)
  local trees = {}
  local step = spacing or 4

  for index = 1, count do
    local x = origin.x + (((index - 1) % 6) * step)
    local y = origin.y + (math.floor((index - 1) / 6) * step)
    trees[#trees + 1] = track_entity(surface().create_entity({
      name = TREE_NAME,
      position = {x = x, y = y}
    }))
  end

  return trees
end

local function fill_region_with_forest(region_x, region_y, spacing)
  local area = regions.region_area(region_x, region_y)
  local trees = {}
  local step = spacing or 5

  for x = area.left_top.x + 4, area.right_bottom.x - 4, step do
    for y = area.left_top.y + 4, area.right_bottom.y - 4, step do
      trees[#trees + 1] = track_entity(surface().create_entity({
        name = TREE_NAME,
        position = {x = x, y = y}
      }))
    end
  end

  return trees
end

local function reset_runtime_storage()
  storage.regions = {}
  storage.last_refresh_tick = 0
  storage.region_refresh_queue = {}
  storage.region_refresh_enqueued = {}
  storage.player_region_centers = {}
  storage.seeded_chunks = {}
  storage.saplings = {}
  storage.next_sapling_id = 1
  storage.harvested_nut_trees = {}
  storage.next_harvested_nut_tree_id = 1
  storage.pending_entity_replacements = {}
  storage.force_tutorials = {}
  storage.feeders = {}
  storage.squirrels = {}
  storage.next_squirrel_id = 1
  storage.squirrel_stashes = {}
  storage.next_squirrel_stash_id = 1
  storage.squirrel_region_activity = {}
  storage.squirrel_region_targets = {}
  storage.squirrel_target_cooldowns = {}
  storage.squirrel_region_index = {}
  storage.squirrel_entity_index = {}
  storage.squirrel_stashes_by_region = {}
  storage.squirrel_stash_target_counts = {}
  storage.squirrel_last_cleanup_tick = 0
  storage.squirrel_damage_attribution = {}
  storage.squirrel_incidents = {}
  storage.next_squirrel_incident_id = 1
  storage.squirrel_retaliation = {}
  storage.squirrel_retaliation_feedback = {}
  storage.survey_station_overlays = {}
  storage.survey_station_panels = {}
  storage.squirrel_selection_overlays = {}
  storage.squirrel_selection_panels = {}
  storage.squirrel_selection_locks = {}
end

local function reset_progression()
  local force = game.forces.player

  force.reset_technologies()
  force.reset_technology_effects()

  for _, technology_name in ipairs({
    constants.technologies.wildlife_relocation,
    constants.technologies.ecological_stabilization
  }) do
    local technology = force.technologies[technology_name]
    if technology then
      technology.researched = false
    end
  end

  force.reset_technology_effects()
end

local function cleanup_area()
  return {
    left_top = {x = 1600, y = 96},
    right_bottom = {x = 2080, y = 352}
  }
end

before_each(function()
  spawned_entities = {}
  surface().clear_pollution()
  reset_progression()
  reset_runtime_storage()
  prepare_origin(ORIGIN)
  player().teleport({x = 0, y = 0}, surface())
end)

after_each(function()
  surface().clear_pollution()
  reset_progression()
  reset_runtime_storage()
  remote.call(constants.mod_name, "debug_clear_squirrel_overlay", player().index)

  for _, entity in ipairs(spawned_entities or {}) do
    if entity and entity.valid then
      entity.destroy()
    end
  end

  for _, entity in ipairs(surface().find_entities_filtered({
    area = cleanup_area(),
    name = constants.names.squirrel
  })) do
    if entity.valid then
      entity.destroy()
    end
  end

  for _, entity in ipairs(surface().find_entities_filtered({
    area = cleanup_area(),
    name = constants.names.squirrel_sitting
  })) do
    if entity.valid then
      entity.destroy()
    end
  end
end)

describe("milestone 6 mitigation and nonlethal control", function()
  it("shows relocation preview details on the selected squirrel panel", function()
    local origin_trees = spawn_forest(18, ORIGIN)
    local origin_coord = regions.position_to_region_coord(ORIGIN)
    fill_region_with_forest(origin_coord.x + 2, origin_coord.y, 5)
    game.forces.player.technologies[constants.technologies.wildlife_relocation].researched = true

    for index = 1, 4 do
      regions.note_tree_loss(surface().index, origin_trees[index].position, 1, game.tick)
      origin_trees[index].destroy()
    end

    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, ORIGIN.x + 6, ORIGIN.y)
    local snapshot = remote.call(constants.mod_name, "debug_get_squirrel_snapshot", squirrel_id)
    local destination = remote.call(constants.mod_name, "debug_find_relocation_destination", surface().index, ORIGIN.x, ORIGIN.y)

    local rendered = remote.call(
      constants.mod_name,
      "debug_show_squirrel_panel",
      player().index,
      surface().index,
      snapshot.position.x,
      snapshot.position.y
    )
    remote.call(
      constants.mod_name,
      "debug_show_squirrel_overlay",
      player().index,
      surface().index,
      snapshot.position.x,
      snapshot.position.y
    )
    local panel = remote.call(constants.mod_name, "debug_get_squirrel_panel_state", player().index)

    assert.is_table(rendered)
    assert.is_table(panel)
    assert.is_true(panel.relocation_available)
    assert.is_false(panel.relocation_locked)
    assert.equal(destination.best.region_x, panel.relocation_region_x)
    assert.equal(destination.best.region_y, panel.relocation_region_y)
    assert.equal(destination.best.forest_health, panel.relocation_forest_health)
    assert.equal(destination.best.squirrel_trust, panel.relocation_squirrel_trust)
    assert.equal(destination.best.habitat_pressure, panel.relocation_habitat_pressure)
    assert.equal(destination.best.tree_mass, panel.relocation_tree_mass)
    assert.equal(#destination.candidates, panel.relocation_candidate_count)
  end)

  it("marks relocation as locked before the relocation technology is researched", function()
    spawn_forest(18, ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, ORIGIN.x + 6, ORIGIN.y)
    local snapshot = remote.call(constants.mod_name, "debug_get_squirrel_snapshot", squirrel_id)

    local rendered = remote.call(
      constants.mod_name,
      "debug_show_squirrel_panel",
      player().index,
      surface().index,
      snapshot.position.x,
      snapshot.position.y
    )
    local panel = remote.call(constants.mod_name, "debug_get_squirrel_panel_state", player().index)

    assert.is_table(rendered)
    assert.is_table(panel)
    assert.is_true(panel.relocation_locked)
    assert.is_false(panel.relocation_available)
    assert.equal(0, panel.relocation_candidate_count)
  end)

  it("records readable destination metrics when a squirrel is relocated", function()
    local origin_trees = spawn_forest(18, ORIGIN)
    local origin_coord = regions.position_to_region_coord(ORIGIN)
    fill_region_with_forest(origin_coord.x + 2, origin_coord.y, 5)
    game.forces.player.technologies[constants.technologies.wildlife_relocation].researched = true

    for index = 1, 4 do
      regions.note_tree_loss(surface().index, origin_trees[index].position, 1, game.tick)
      origin_trees[index].destroy()
    end

    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, ORIGIN.x + 6, ORIGIN.y)
    local destination = remote.call(constants.mod_name, "debug_find_relocation_destination", surface().index, ORIGIN.x, ORIGIN.y)
    local incident = remote.call(constants.mod_name, "debug_relocate_squirrel", squirrel_id, player().index)

    assert.is_table(incident)
    assert.equal("relocation", incident.kind)
    assert.equal(destination.best.region_x, incident.destination_region_x)
    assert.equal(destination.best.region_y, incident.destination_region_y)
    assert.equal(destination.best.forest_health, incident.destination_forest_health)
    assert.equal(destination.best.squirrel_trust, incident.destination_squirrel_trust)
    assert.equal(destination.best.habitat_pressure, incident.destination_habitat_pressure)
    assert.equal(destination.best.tree_mass, incident.destination_tree_mass)
    assert.equal(destination.best.score, incident.destination_score)
  end)

  it("clears squirrel selection locks after player deselects and does not keep extending lock expiry", function()
    spawn_forest(18, ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, ORIGIN.x + 6, ORIGIN.y)
    local snapshot = remote.call(constants.mod_name, "debug_get_squirrel_snapshot", squirrel_id)
    local squirrel = find_squirrel_entity(snapshot.position)
    local dummy = track_entity(surface().create_entity({
      name = constants.names.feeder,
      position = {x = ORIGIN.x + 20, y = ORIGIN.y},
      force = game.forces.player
    }))

    assert.is_not_nil(squirrel)
    assert.is_not_nil(dummy)

    player().selected = squirrel
    remote.call(constants.mod_name, "debug_refresh_player_selection", player().index, game.tick)
    local initial_lock = remote.call(constants.mod_name, "debug_get_squirrel_selection_lock", player().index)

    assert.is_table(initial_lock)
    assert.equal(squirrel.unit_number, initial_lock.squirrel_unit_number)

    player().selected = dummy
    remote.call(constants.mod_name, "debug_refresh_locked_squirrel_selections", game.tick + 1)
    local lock_after_tick_refresh = remote.call(constants.mod_name, "debug_get_squirrel_selection_lock", player().index)

    assert.is_table(lock_after_tick_refresh)
    assert.equal(initial_lock.expires_tick, lock_after_tick_refresh.expires_tick)

    player().selected = nil
    remote.call(constants.mod_name, "debug_refresh_player_selection", player().index, game.tick + 2)
    for offset = 3, 25 do
      remote.call(constants.mod_name, "debug_refresh_locked_squirrel_selections", game.tick + offset)
    end
    local cleared_lock = remote.call(constants.mod_name, "debug_get_squirrel_selection_lock", player().index)

    assert.is_nil(cleared_lock)
  end)
end)
