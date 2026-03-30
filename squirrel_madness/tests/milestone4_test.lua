local constants = require("scripts.constants")
local regions = require("scripts.regions")

local BARREN_ORIGIN = {x = 1232, y = 80}
local FOREST_ORIGIN = {x = 1296, y = 144}
local BELT_ORIGIN = {x = 1360, y = 144}
local CHEST_ORIGIN = {x = 1424, y = 144}
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

local function spawn_forest(count, origin)
  local trees = {}

  for index = 1, count do
    local x = origin.x + (((index - 1) % 6) * 4)
    local y = origin.y + (math.floor((index - 1) / 6) * 4)
    trees[#trees + 1] = track_entity(surface().create_entity({
      name = TREE_NAME,
      position = {x = x, y = y}
    }))
  end

  return trees
end

local function square_area(origin, radius)
  return {
    left_top = {x = origin.x - radius, y = origin.y - radius},
    right_bottom = {x = origin.x + radius, y = origin.y + radius}
  }
end

local function prepare_origin(origin)
  surface().request_to_generate_chunks(origin, 2)
  surface().force_generate_chunk_requests()

  local tiles = {}
  for x = origin.x - 24, origin.x + 24 do
    for y = origin.y - 24, origin.y + 24 do
      tiles[#tiles + 1] = {
        name = "grass-1",
        position = {x = x, y = y}
      }
    end
  end
  surface().set_tiles(tiles, true)

  for _, entity in ipairs(surface().find_entities_filtered({area = square_area(origin, 24)})) do
    if entity.valid and entity.type ~= "character" then
      entity.destroy()
    end
  end
end

local function reset_runtime_storage()
  storage.regions = {}
  storage.last_refresh_tick = 0
  storage.seeded_chunks = {}
  storage.saplings = {}
  storage.next_sapling_id = 1
  storage.harvested_nut_trees = {}
  storage.next_harvested_nut_tree_id = 1
  storage.pending_entity_replacements = {}
  storage.force_tutorials = {}
  storage.squirrels = {}
  storage.next_squirrel_id = 1
  storage.squirrel_stashes = {}
  storage.next_squirrel_stash_id = 1
  storage.squirrel_region_activity = {}
  storage.squirrel_target_cooldowns = {}
end

local function cleanup_area()
  return {
    left_top = {x = 1180, y = 32},
    right_bottom = {x = 1480, y = 256}
  }
end

before_each(function()
  spawned_entities = {}
  surface().clear_pollution()
  reset_runtime_storage()
  prepare_origin(BARREN_ORIGIN)
  prepare_origin(FOREST_ORIGIN)
  prepare_origin(BELT_ORIGIN)
  prepare_origin(CHEST_ORIGIN)
  player().teleport({x = 0, y = 0}, surface())
  local inventory = player().get_main_inventory()
  if inventory then
    inventory.clear()
  end
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
    name = {constants.names.squirrel, constants.names.stash, "transport-belt", "wooden-chest"}
  })) do
    if entity.valid then
      entity.destroy()
    end
  end
end)

describe("milestone 4 squirrel nuisance runtime", function()
  it("spawns visible squirrels only in eligible forest-edge regions", function()
    local barren = remote.call(constants.mod_name, "debug_force_region_squirrels", surface().index, BARREN_ORIGIN.x, BARREN_ORIGIN.y)

    spawn_forest(18, FOREST_ORIGIN)
    local created = remote.call(constants.mod_name, "debug_force_region_squirrels", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y)
    local report = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    assert.equal(0, barren)
    assert.is_true(created > 0)
    assert.equal(created, #report.squirrels)
  end)

  it("tracks calm, curious, mischievous, agitated, and grieving state selection", function()
    local trees = spawn_forest(18, FOREST_ORIGIN)

    assert.equal("calm", remote.call(constants.mod_name, "debug_squirrel_state_at_position", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y))

    regions.note_tree_loss(surface().index, trees[1].position, 1, game.tick)
    trees[1].destroy()
    assert.equal("curious", remote.call(constants.mod_name, "debug_squirrel_state_at_position", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y))

    for index = 2, 4 do
      regions.note_tree_loss(surface().index, trees[index].position, 1, game.tick)
      trees[index].destroy()
    end
    assert.equal("mischievous", remote.call(constants.mod_name, "debug_squirrel_state_at_position", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y))

    for index = 5, 8 do
      regions.note_tree_loss(surface().index, trees[index].position, 1, game.tick)
      trees[index].destroy()
    end
    assert.equal("agitated", remote.call(constants.mod_name, "debug_squirrel_state_at_position", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y))

    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, FOREST_ORIGIN.x + 2, FOREST_ORIGIN.y + 2)

    assert.is_number(squirrel_id)
    assert.is_true(remote.call(constants.mod_name, "debug_kill_squirrel", squirrel_id))
    assert.equal("grieving", remote.call(constants.mod_name, "debug_squirrel_state_at_position", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y))
  end)

  it("chooses higher-desirability targets when squirrels evaluate belts and chests", function()
    local science = remote.call(constants.mod_name, "debug_squirrel_item_desirability", "automation-science-pack")
    local iron = remote.call(constants.mod_name, "debug_squirrel_item_desirability", "iron-plate")
    local wood = remote.call(constants.mod_name, "debug_squirrel_item_desirability", "wood")
    local brick = remote.call(constants.mod_name, "debug_squirrel_item_desirability", "stone-brick")

    assert.is_true(science > iron)
    assert.is_true(iron > brick)
    assert.is_true(wood > brick)
  end)

  it("blocks a belt briefly and steals exactly one item before retreating", function()
    spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x, BELT_ORIGIN.y)
    local belt = track_entity(surface().create_entity({
      name = "transport-belt",
      position = {x = BELT_ORIGIN.x + 8, y = BELT_ORIGIN.y},
      direction = defines.direction.east,
      force = game.forces.player
    }))

    assert.is_not_nil(belt)
    assert.is_true(belt.get_transport_line(1).insert_at(0.25, {name = "iron-plate", count = 1}))

    local result = remote.call(constants.mod_name, "debug_force_belt_theft", surface().index, squirrel_id, belt.position.x, belt.position.y)
    local report = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    assert.is_table(result)
    assert.equal("iron-plate", result.item_name)
    assert.equal(1, result.count)
    assert.equal(0, belt.get_transport_line(1).get_item_count("iron-plate"))
    assert.equal(1, #report.stashes)
    assert.equal(1, report.stashes[1].item_count)
  end)

  it("creates a visible forest stash and deposits stolen loot into it", function()
    spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x, BELT_ORIGIN.y)
    local belt = track_entity(surface().create_entity({
      name = "transport-belt",
      position = {x = BELT_ORIGIN.x + 10, y = BELT_ORIGIN.y},
      direction = defines.direction.east,
      force = game.forces.player
    }))

    assert.is_not_nil(belt)
    assert.is_true(belt.get_transport_line(1).insert_at(0.25, {name = "copper-plate", count = 1}))
    assert.is_table(remote.call(constants.mod_name, "debug_force_belt_theft", surface().index, squirrel_id, belt.position.x, belt.position.y))

    local before_cleanup = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)
    local stash = surface().find_entities_filtered({
      position = before_cleanup.stashes[1].position,
      name = constants.names.stash,
      limit = 1
    })[1]

    assert.is_not_nil(stash)
    assert.equal(1, before_cleanup.stashes[1].item_count)

    local inventory = stash.get_inventory(defines.inventory.chest)
    inventory.clear()

    assert.equal(1, remote.call(constants.mod_name, "debug_cleanup_empty_stashes", surface().index))
    assert.equal(0, #remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index).stashes)
  end)

  it("rate-limits repeated theft and stash creation per squirrel and per region", function()
    spawn_forest(18, BELT_ORIGIN)
    local first_squirrel = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x, BELT_ORIGIN.y)
    local second_squirrel = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x + 2, BELT_ORIGIN.y + 2)
    local first_belt = track_entity(surface().create_entity({
      name = "transport-belt",
      position = {x = BELT_ORIGIN.x + 12, y = BELT_ORIGIN.y},
      direction = defines.direction.east,
      force = game.forces.player
    }))
    local second_belt = track_entity(surface().create_entity({
      name = "transport-belt",
      position = {x = BELT_ORIGIN.x + 14, y = BELT_ORIGIN.y},
      direction = defines.direction.east,
      force = game.forces.player
    }))

    assert.is_true(first_belt.get_transport_line(1).insert_at(0.25, {name = "iron-plate", count = 1}))
    assert.is_true(second_belt.get_transport_line(1).insert_at(0.25, {name = "copper-plate", count = 1}))

    assert.is_table(remote.call(constants.mod_name, "debug_force_belt_theft", surface().index, first_squirrel, first_belt.position.x, first_belt.position.y))
    assert.is_nil(remote.call(constants.mod_name, "debug_force_belt_theft", surface().index, first_squirrel, second_belt.position.x, second_belt.position.y))
    assert.is_nil(remote.call(constants.mod_name, "debug_force_belt_theft", surface().index, second_squirrel, second_belt.position.x, second_belt.position.y))
    assert.equal(1, #remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index).stashes)
  end)

  it("keeps chest scavenging gated behind higher habitat pressure", function()
    local trees = spawn_forest(18, CHEST_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, CHEST_ORIGIN.x, CHEST_ORIGIN.y)
    local chest = track_entity(surface().create_entity({
      name = "wooden-chest",
      position = {x = CHEST_ORIGIN.x + 8, y = CHEST_ORIGIN.y},
      force = game.forces.player
    }))
    local inventory = chest.get_inventory(defines.inventory.chest)

    inventory.insert({name = "iron-gear-wheel", count = 8})

    assert.is_nil(remote.call(constants.mod_name, "debug_force_chest_scavenge", surface().index, squirrel_id, chest.position.x, chest.position.y))

    for index = 1, 8 do
      regions.note_tree_loss(surface().index, trees[index].position, 1, game.tick)
      trees[index].destroy()
    end

    local result = remote.call(constants.mod_name, "debug_force_chest_scavenge", surface().index, squirrel_id, chest.position.x, chest.position.y)
    local report = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    assert.is_table(result)
    assert.equal("iron-gear-wheel", result.item_name)
    assert.is_true(result.count >= 1)
    assert.is_true(inventory.get_item_count("iron-gear-wheel") < 8)
    assert.equal(1, #report.stashes)
  end)

  it("exposes remote/debug inspection for squirrel state and local nuisance actions", function()
    spawn_forest(18, FOREST_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y)
    local report = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    assert.is_number(squirrel_id)
    assert.equal(1, #report.squirrels)
    assert.equal(squirrel_id, report.squirrels[1].squirrel_id)
    assert.is_string(report.squirrels[1].state)
    assert.is_string(report.squirrels[1].mode)
    assert.is_table(report.squirrels[1].position)
  end)

  it("keeps the relocation hotkey scaffold available for later squirrel control", function()
    assert.is_not_nil(prototypes.custom_input[constants.names.relocation_input])
  end)
end)
