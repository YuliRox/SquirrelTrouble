local constants = require("scripts.constants")
local regions = require("scripts.regions")

local ORIGIN = {x = 1568, y = 144}
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

local function find_squirrel(report, squirrel_id)
  for _, squirrel in ipairs(report.squirrels or {}) do
    if squirrel.squirrel_id == squirrel_id then
      return squirrel
    end
  end

  return nil
end

local function find_squirrel_entity(squirrel_id)
  local report = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)
  local squirrel = find_squirrel(report, squirrel_id)
  if not squirrel then
    return nil, nil
  end

  local entity = surface().find_entities_filtered({
    position = squirrel.position,
    name = constants.names.squirrel,
    limit = 1
  })[1]

  return entity, squirrel
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
end

local function cleanup_area()
  return {
    left_top = {x = 1500, y = 64},
    right_bottom = {x = 2000, y = 320}
  }
end

before_each(function()
  spawned_entities = {}
  surface().clear_pollution()
  reset_runtime_storage()
  prepare_origin(ORIGIN)
  player().teleport({x = 0, y = 0}, surface())
  local inventory = player().get_main_inventory()
  if inventory then
    inventory.clear()
  end
  game.forces.player.technologies[constants.technologies.wildlife_relocation].researched = true
end)

after_each(function()
  surface().clear_pollution()
  reset_runtime_storage()

  for _, entity in ipairs(spawned_entities or {}) do
    if entity and entity.valid then
      entity.destroy()
    end
  end

  for _, entity in ipairs(surface().find_entities_filtered({
    area = cleanup_area(),
    name = {constants.names.squirrel, "biter-spawner"}
  })) do
    if entity.valid then
      entity.destroy()
    end
  end
end)

describe("milestone 5 retaliation and relocation foundation", function()
  it("relocates squirrels into healthier forest and improves local trust", function()
    local origin_trees = spawn_forest(18, ORIGIN)
    local origin_coord = regions.position_to_region_coord(ORIGIN)
    fill_region_with_forest(origin_coord.x + 2, origin_coord.y, 5)

    for index = 1, 4 do
      regions.note_tree_loss(surface().index, origin_trees[index].position, 1, game.tick)
      origin_trees[index].destroy()
    end

    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, ORIGIN.x + 6, ORIGIN.y)
    local before = remote.call(constants.mod_name, "force_recompute_at_position", surface().index, ORIGIN.x, ORIGIN.y)
    local destination = remote.call(constants.mod_name, "debug_find_relocation_destination", surface().index, ORIGIN.x, ORIGIN.y)
    local incident = remote.call(constants.mod_name, "debug_relocate_squirrel", squirrel_id, player().index)
    local squirrel_report = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)
    local relocated = find_squirrel(squirrel_report, squirrel_id)
    local after = remote.call(constants.mod_name, "force_recompute_at_position", surface().index, ORIGIN.x, ORIGIN.y)

    assert.is_not_nil(destination)
    assert.is_table(destination.best)
    assert.equal("relocation", incident.kind)
    assert.equal(destination.best.region_x, incident.destination_region_x)
    assert.equal(destination.best.region_y, incident.destination_region_y)
    assert.is_not_nil(relocated)
    assert.equal(destination.best.region_x, relocated.region_x)
    assert.equal(destination.best.region_y, relocated.region_y)
    assert.is_true(after.relocation_bonus > before.relocation_bonus)
    assert.is_true(after.squirrel_trust > before.squirrel_trust)
    assert.is_true(after.squirrel_unrest < before.squirrel_unrest)
  end)

  it("attributes player rough handling and selects a localized revenge source", function()
    spawn_forest(18, ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, ORIGIN.x + 6, ORIGIN.y)
    local squirrel_entity, squirrel = find_squirrel_entity(squirrel_id)
    local before = remote.call(constants.mod_name, "force_recompute_at_position", surface().index, squirrel.position.x, squirrel.position.y)

    track_entity(surface().create_entity({
      name = "biter-spawner",
      position = {x = squirrel.position.x + 16, y = squirrel.position.y},
      force = game.forces.enemy
    }))

    assert.is_not_nil(squirrel_entity)
    assert.is_true(squirrel_entity.damage(1, player().force, nil, player().character, player().character) > 0)

    local after = remote.call(constants.mod_name, "force_recompute_at_position", surface().index, squirrel.position.x, squirrel.position.y)
    local incidents = remote.call(constants.mod_name, "debug_get_squirrel_incidents", surface().index)
    local state = remote.call(constants.mod_name, "debug_get_retaliation_state", surface().index, player().index)
    local incident = incidents[#incidents]

    assert.equal("rough-handling", incident.kind)
    assert.equal(constants.retaliation_step_severity, incident.severity)
    assert.is_not_nil(incident.revenge_source)
    assert.equal(constants.retaliation_step_severity, state.total_severity)
    assert.equal("rough-handling", state.pending_wave.trigger)
    assert.is_true(after.rough_handling_penalty > before.rough_handling_penalty)
    assert.is_true(after.squirrel_trust < before.squirrel_trust)
  end)

  it("attributes squirrel deaths and escalates revenge-wave selection", function()
    spawn_forest(18, ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, ORIGIN.x + 6, ORIGIN.y)
    local squirrel_entity, squirrel = find_squirrel_entity(squirrel_id)
    local before = remote.call(constants.mod_name, "force_recompute_at_position", surface().index, squirrel.position.x, squirrel.position.y)

    track_entity(surface().create_entity({
      name = "biter-spawner",
      position = {x = squirrel.position.x + 18, y = squirrel.position.y},
      force = game.forces.enemy
    }))

    assert.is_not_nil(squirrel_entity)
    assert.is_true(squirrel_entity.die(player().force, player().character))

    local after = remote.call(constants.mod_name, "force_recompute_at_position", surface().index, squirrel.position.x, squirrel.position.y)
    local incidents = remote.call(constants.mod_name, "debug_get_squirrel_incidents", surface().index)
    local state = remote.call(constants.mod_name, "debug_get_retaliation_state", surface().index, player().index)
    local incident = incidents[#incidents]

    assert.equal("death", incident.kind)
    assert.equal(constants.retaliation_death_severity, incident.severity)
    assert.is_not_nil(incident.revenge_source)
    assert.equal(constants.retaliation_death_severity, state.total_severity)
    assert.equal("death", state.pending_wave.trigger)
    assert.is_true(after.squirrel_death_penalty > before.squirrel_death_penalty)
    assert.is_true(after.squirrel_unrest > before.squirrel_unrest)
    assert.is_true(after.squirrel_trust < before.squirrel_trust)
  end)
end)
