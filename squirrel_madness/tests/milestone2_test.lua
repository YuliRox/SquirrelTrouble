local constants = require("scripts.constants")
local habitat = require("scripts.habitat")
local regions = require("scripts.regions")

local DENSE_FOREST_ORIGIN = {x = 384, y = 64}
local RECOVERY_ORIGIN = {x = 512, y = 256}
local SAPLING_ORIGIN = {x = 640, y = 320}
local CLAMP_PATCH_ORIGIN = {x = 736, y = 32}
local SPARSE_CHUNK_ORIGIN = {x = 768, y = 96}
local CHUNK_FOREST_ORIGIN = {x = 832, y = 96}
local HINT_FOREST_ORIGIN = {x = 928, y = 224}
local TREE_NAME = "tree-01"
local spawned_entities

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

local function player()
  return game.players[1]
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
end

local function count_storage_entries(entries)
  local count = 0

  for _ in pairs(entries or {}) do
    count = count + 1
  end

  return count
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

local function spawn_area(center, radius)
  return {
    left_top = {
      x = center.x - radius,
      y = center.y - radius
    },
    right_bottom = {
      x = center.x + radius,
      y = center.y + radius
    }
  }
end

local function starting_grove_area()
  return spawn_area(game.forces.player.get_spawn_position(surface()), constants.starting_grove_radius)
end

local function destroy_named_entities(area, names)
  for _, entity in ipairs(surface().find_entities_filtered({
    area = area,
    name = names
  })) do
    if entity.valid then
      entity.destroy()
    end
  end
end

before_each(function()
  spawned_entities = {}
  surface().clear_pollution()
  reset_runtime_storage()
  player().teleport({x = 0, y = 0}, surface())
  local inventory = player().get_main_inventory()
  if inventory then
    inventory.clear()
  end
end)

after_each(function()
  surface().clear_pollution()
  reset_runtime_storage()
  local inventory = player().get_main_inventory()
  if inventory then
    inventory.clear()
  end
end)

describe("milestone 2 habitat recovery", function()
  local dense_forest
  local recovery_forest

  before_each(function()
    dense_forest = spawn_forest(24, DENSE_FOREST_ORIGIN)
    recovery_forest = spawn_forest(18, RECOVERY_ORIGIN)
  end)

  after_each(function()
    for _, entity in ipairs(spawned_entities or {}) do
      if entity and entity.valid then
        entity.destroy()
      end
    end

    local cleanup_area = {
      left_top = {x = 320, y = 0},
      right_bottom = {x = 1024, y = 512}
    }
    local cleanup_names = {
      constants.names.nut_tree,
      constants.names.nut_tree_harvested,
      constants.names.nut_sapling,
      constants.names.feeder,
      constants.names.feeder_empty,
      constants.names.steel_feeder,
      constants.names.steel_feeder_empty
    }

    for _, entity in ipairs(surface().find_entities_filtered({
      area = cleanup_area,
      name = cleanup_names
    })) do
      if entity.valid then
        entity.destroy()
      end
    end

    destroy_named_entities(starting_grove_area(), {
      constants.names.nut_tree,
      constants.names.nut_tree_harvested,
      constants.names.nut_sapling,
      constants.names.feeder,
      constants.names.feeder_empty,
      constants.names.steel_feeder,
      constants.names.steel_feeder_empty
    })
  end)

  it("seeds natural nut trees into dense forest areas", function()
    local seeded = remote.call(
      constants.mod_name,
      "seed_nut_trees_in_area",
      surface().index,
      352,
      32,
      448,
      160,
      2
    )
    local report = remote.call(
      constants.mod_name,
      "force_recompute_at_position",
      surface().index,
      DENSE_FOREST_ORIGIN.x,
      DENSE_FOREST_ORIGIN.y
    )

    assert.equal(2, seeded)
    assert.equal(2, report.nut_tree_count)
    assert.is_true(report.forest_health > 0)
  end)

  it("clamps explicit seeding to the available candidate trees", function()
    spawn_forest(2, CLAMP_PATCH_ORIGIN)

    local seeded = habitat.seed_nut_trees_in_area(
      surface(),
      spawn_area(CLAMP_PATCH_ORIGIN, 24),
      5,
      true
    )
    local nut_trees = surface().count_entities_filtered({
      area = spawn_area(CLAMP_PATCH_ORIGIN, 24),
      name = constants.names.nut_tree
    })

    assert.equal(2, seeded)
    assert.equal(2, nut_trees)
  end)

  it("refuses automatic chunk seeding in sparse forest", function()
    local chunk_position = {x = 24, y = 3}
    local area = chunk_area(chunk_position)
    spawn_forest(5, SPARSE_CHUNK_ORIGIN)

    local seeded = habitat.seed_chunk(surface(), chunk_position, area)

    assert.equal(0, seeded)
    assert.equal(0, surface().count_entities_filtered({
      area = area,
      name = constants.names.nut_tree
    }))
    assert.is_true(storage.seeded_chunks[surface().index]["24,3"])
  end)

  it("seeds each chunk only once", function()
    local chunk_position = {x = 26, y = 3}
    local area = chunk_area(chunk_position)
    spawn_forest(18, CHUNK_FOREST_ORIGIN)

    local first = habitat.seed_chunk(surface(), chunk_position, area)
    local second = habitat.seed_chunk(surface(), chunk_position, area)

    assert.equal(1, first)
    assert.equal(0, second)
    assert.equal(1, surface().count_entities_filtered({
      area = area,
      name = constants.names.nut_tree
    }))
  end)

  it("guarantees a starting grove once and does not duplicate it later", function()
    local area = starting_grove_area()

    destroy_named_entities(area, {constants.names.nut_tree, constants.names.nut_sapling})

    local first = remote.call(constants.mod_name, "ensure_starting_grove", surface().index)
    local after_first = surface().count_entities_filtered({
      area = area,
      name = constants.names.nut_tree
    })
    local second = remote.call(constants.mod_name, "ensure_starting_grove", surface().index)
    local after_second = surface().count_entities_filtered({
      area = area,
      name = constants.names.nut_tree
    })

    assert.is_true(first > 0)
    assert.is_true(after_first >= constants.starting_grove_target)
    assert.equal(0, second)
    assert.equal(after_first, after_second)
  end)

  it("reports saplings separately from mature canopy", function()
    local before = remote.call(
      constants.mod_name,
      "force_recompute_at_position",
      surface().index,
      SAPLING_ORIGIN.x,
      SAPLING_ORIGIN.y
    )
    local sapling = track_entity(surface().create_entity({
      name = constants.names.nut_sapling,
      position = SAPLING_ORIGIN,
      force = "neutral",
      raise_built = true
    }))
    local after = remote.call(
      constants.mod_name,
      "force_recompute_at_position",
      surface().index,
      SAPLING_ORIGIN.x,
      SAPLING_ORIGIN.y
    )

    assert.is_not_nil(sapling)
    assert.equal(1, after.sapling_count)
    assert.equal(0, after.nut_tree_count)
    assert.equal(before.tree_count, after.tree_count)
    assert.is_true(after.reforestation_bonus > before.reforestation_bonus)
    assert.is_true(after.forest_health > before.forest_health)
    assert.is_true(after.squirrel_trust > before.squirrel_trust)
    assert.is_true(after.habitat_pressure < before.habitat_pressure)
  end)

  it("matures planted saplings into nut trees and improves local habitat", function()
    local before = remote.call(
      constants.mod_name,
      "force_recompute_at_position",
      surface().index,
      SAPLING_ORIGIN.x,
      SAPLING_ORIGIN.y
    )
    local sapling = track_entity(surface().create_entity({
      name = constants.names.nut_sapling,
      position = SAPLING_ORIGIN,
      force = "neutral",
      raise_built = true
    }))

    assert.is_not_nil(sapling)
    assert.equal(1, remote.call(constants.mod_name, "force_mature_all_saplings", surface().index))

    local after = remote.call(
      constants.mod_name,
      "force_recompute_at_position",
      surface().index,
      SAPLING_ORIGIN.x,
      SAPLING_ORIGIN.y
    )

    assert.equal(0, before.nut_tree_count)
    assert.equal(1, after.nut_tree_count)
    assert.equal(0, after.sapling_count)
    assert.is_true(after.forest_health > before.forest_health)
    assert.is_true(after.squirrel_trust > before.squirrel_trust)
  end)

  it("harvests nut trees without counting as deforestation", function()
    local position = {x = SAPLING_ORIGIN.x + 12, y = SAPLING_ORIGIN.y}
    local nut_tree = track_entity(surface().create_entity({
      name = constants.names.nut_tree,
      position = position,
      force = "neutral"
    }))
    local before = remote.call(
      constants.mod_name,
      "force_recompute_at_position",
      surface().index,
      position.x,
      position.y
    )

    player().teleport({x = position.x + 1, y = position.y}, surface())

    assert.is_not_nil(nut_tree)
    assert.is_true(player().mine_entity(nut_tree, true))
    assert.equal(1, habitat.resolve_pending_replacements(game.tick + 1, surface().index))

    local after = remote.call(
      constants.mod_name,
      "force_recompute_at_position",
      surface().index,
      position.x,
      position.y
    )
    local harvested = surface().find_entities_filtered({
      position = position,
      name = constants.names.nut_tree_harvested,
      limit = 1
    })[1]

    assert.is_not_nil(harvested)
    assert.equal(5, player().get_main_inventory().get_item_count(constants.names.nut))
    assert.equal(0, after.recent_tree_loss)
    assert.equal(0, after.recent_tree_loss_penalty)
    assert.equal(before.tree_count, after.tree_count)
    assert.equal(0, after.nut_tree_count)
    assert.is_true(storage.force_tutorials[player().force.index].harvest_hint)
  end)

  it("lets picked nut trees recover into mature nut trees", function()
    local position = {x = SAPLING_ORIGIN.x + 20, y = SAPLING_ORIGIN.y}
    local nut_tree = track_entity(surface().create_entity({
      name = constants.names.nut_tree,
      position = position,
      force = "neutral"
    }))

    player().teleport({x = position.x + 1, y = position.y}, surface())

    assert.is_not_nil(nut_tree)
    assert.is_true(player().mine_entity(nut_tree, true))
    assert.equal(1, habitat.resolve_pending_replacements(game.tick + 1, surface().index))
    assert.equal(1, count_storage_entries(storage.harvested_nut_trees))
    assert.equal(
      1,
      habitat.force_recover_all_harvested_nut_trees(
        game.tick + constants.nut_tree_harvest_regrowth_time,
        surface().index
      )
    )

    local recovered = surface().find_entities_filtered({
      position = position,
      name = constants.names.nut_tree,
      limit = 1
    })[1]

    assert.is_not_nil(recovered)
    assert.equal(0, count_storage_entries(storage.harvested_nut_trees))
  end)

  it("clears stale sapling records when the entity disappears before maturation", function()
    local sapling = track_entity(surface().create_entity({
      name = constants.names.nut_sapling,
      position = SAPLING_ORIGIN,
      force = "neutral",
      raise_built = true
    }))

    assert.is_not_nil(sapling)
    assert.equal(1, count_storage_entries(storage.saplings))

    sapling.destroy()

    assert.equal(1, count_storage_entries(storage.saplings))
    assert.equal(0, remote.call(constants.mod_name, "force_mature_all_saplings", surface().index))
    assert.equal(0, count_storage_entries(storage.saplings))
  end)

  it("unregisters sapling records when removal bookkeeping runs", function()
    local sapling = track_entity(surface().create_entity({
      name = constants.names.nut_sapling,
      position = SAPLING_ORIGIN,
      force = "neutral",
      raise_built = true
    }))

    assert.is_not_nil(sapling)
    assert.equal(1, count_storage_entries(storage.saplings))

    habitat.unregister_sapling(surface().index, SAPLING_ORIGIN)

    assert.equal(0, count_storage_entries(storage.saplings))
  end)

  it("arms the deforestation tutorial only after the configured loss threshold", function()
    local hint_forest = spawn_forest(3, HINT_FOREST_ORIGIN)
    local force_tutorials = storage.force_tutorials[game.forces.player.index] or {}
    storage.force_tutorials[game.forces.player.index] = force_tutorials

    for index = 1, 2 do
      regions.note_tree_loss(surface().index, hint_forest[index].position, 1, game.tick)
    end

    habitat.maybe_show_deforestation_hint(1, surface(), HINT_FOREST_ORIGIN, game.tick)

    assert.is_nil(force_tutorials.deforestation_hint)

    regions.note_tree_loss(surface().index, hint_forest[3].position, 1, game.tick)
    habitat.maybe_show_deforestation_hint(1, surface(), HINT_FOREST_ORIGIN, game.tick)
    habitat.maybe_show_deforestation_hint(1, surface(), HINT_FOREST_ORIGIN, game.tick)

    assert.is_true(force_tutorials.deforestation_hint)
  end)

  it("records one-shot research tutorial flags for the early mitigation techs", function()
    local force_tutorials = storage.force_tutorials[game.forces.player.index] or {}
    storage.force_tutorials[game.forces.player.index] = force_tutorials

    habitat.on_research_finished({name = "arboriculture", force = game.forces.player, valid = true})
    habitat.on_research_finished({name = "wildlife-diversion", force = game.forces.player, valid = true})
    habitat.on_research_finished({name = "arboriculture", force = game.forces.player, valid = true})

    assert.is_true(force_tutorials.arboriculture_hint)
    assert.is_true(force_tutorials.wildlife_diversion_hint)
  end)

  it("lets stocked feeders stabilize a deforested region", function()
    for index = 1, 4 do
      local tree = recovery_forest[index]
      regions.note_tree_loss(surface().index, tree.position, 1, game.tick)
      tree.destroy()
    end

    local without_feeder = remote.call(
      constants.mod_name,
      "force_recompute_at_position",
      surface().index,
      RECOVERY_ORIGIN.x,
      RECOVERY_ORIGIN.y
    )
    local feeder = track_entity(surface().create_entity({
      name = constants.names.feeder,
      position = {x = RECOVERY_ORIGIN.x + 8, y = RECOVERY_ORIGIN.y + 8},
      force = game.forces.player
    }))
    local inventory = feeder.get_inventory(defines.inventory.chest)
    inventory.insert({name = constants.names.nut, count = constants.stocked_feeder_threshold})

    local with_feeder = remote.call(
      constants.mod_name,
      "force_recompute_at_position",
      surface().index,
      RECOVERY_ORIGIN.x,
      RECOVERY_ORIGIN.y
    )

    assert.equal(1, with_feeder.stocked_feeders)
    assert.is_true(with_feeder.squirrel_unrest < without_feeder.squirrel_unrest)
    assert.is_true(with_feeder.squirrel_trust > without_feeder.squirrel_trust)
    assert.is_true(with_feeder.habitat_pressure < without_feeder.habitat_pressure)
  end)

  it("swaps wooden feeder art between empty and stocked variants", function()
    local position = {x = RECOVERY_ORIGIN.x + 20, y = RECOVERY_ORIGIN.y + 4}
    local feeder = track_entity(surface().create_entity({
      name = constants.names.feeder_empty,
      position = position,
      force = game.forces.player
    }))
    local inventory = feeder.get_inventory(defines.inventory.chest)

    assert.equal(constants.names.feeder_empty, remote.call(
      constants.mod_name,
      "debug_get_feeder_state",
      surface().index,
      position.x,
      position.y
    ).name)

    inventory.insert({name = constants.names.nut, count = 1})
    remote.call(constants.mod_name, "debug_sync_feeders", surface().index)

    local stocked_state = remote.call(
      constants.mod_name,
      "debug_get_feeder_state",
      surface().index,
      position.x,
      position.y
    )

    assert.equal(constants.names.feeder, stocked_state.name)
    assert.equal(1, stocked_state.nut_count)

    local stocked_entity = surface().find_entities_filtered({
      area = {
        {position.x - 0.2, position.y - 0.2},
        {position.x + 0.2, position.y + 0.2}
      },
      name = constants.feeder_entity_names,
      limit = 1
    })[1]
    local stocked_inventory = stocked_entity.get_inventory(defines.inventory.chest)
    stocked_inventory.remove({name = constants.names.nut, count = 1})
    remote.call(constants.mod_name, "debug_sync_feeders", surface().index)

    local empty_state = remote.call(
      constants.mod_name,
      "debug_get_feeder_state",
      surface().index,
      position.x,
      position.y
    )

    assert.equal(constants.names.feeder_empty, empty_state.name)
    assert.equal(0, empty_state.nut_count)
  end)

  it("counts stocked steel feeders using the larger feeder tier", function()
    local position = {x = RECOVERY_ORIGIN.x + 28, y = RECOVERY_ORIGIN.y + 4}
    local steel_feeder = track_entity(surface().create_entity({
      name = constants.names.steel_feeder_empty,
      position = position,
      force = game.forces.player
    }))
    local without_feeder = remote.call(
      constants.mod_name,
      "force_recompute_at_position",
      surface().index,
      RECOVERY_ORIGIN.x,
      RECOVERY_ORIGIN.y
    )
    local inventory = steel_feeder.get_inventory(defines.inventory.chest)

    assert.equal(2, #inventory)
    assert.equal(constants.stocked_feeder_threshold, inventory.insert({
      name = constants.names.nut,
      count = constants.stocked_feeder_threshold
    }))
    remote.call(constants.mod_name, "debug_sync_feeders", surface().index)

    local with_feeder = remote.call(
      constants.mod_name,
      "force_recompute_at_position",
      surface().index,
      RECOVERY_ORIGIN.x,
      RECOVERY_ORIGIN.y
    )
    local state = remote.call(
      constants.mod_name,
      "debug_get_feeder_state",
      surface().index,
      position.x,
      position.y
    )

    assert.equal(constants.names.steel_feeder, state.name)
    assert.equal(1, with_feeder.feeder_count)
    assert.equal(1, with_feeder.stocked_feeders)
    assert.is_true(with_feeder.squirrel_unrest < without_feeder.squirrel_unrest)
  end)
end)
