local constants = require("scripts.constants")
local regions = require("scripts.regions")
local squirrels = require("scripts.squirrels")

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

local function create_belt_line(origin, length, item_name, item_count)
  local belts = {}

  for index = 0, length - 1 do
    local belt = track_entity(surface().create_entity({
      name = "transport-belt",
      position = {x = origin.x + index, y = origin.y},
      direction = defines.direction.east,
      force = game.forces.player
    }))

    belts[#belts + 1] = belt
  end

  for index = 1, item_count do
    local belt = belts[((index - 1) % #belts) + 1]
    local line_index = (math.floor((index - 1) / #belts) % 2) + 1
    belt.get_transport_line(line_index).insert_at_back({name = item_name, count = 1})
  end

  return belts
end

local function total_belt_item_count(belts, item_name)
  local total = 0

  for _, belt in ipairs(belts) do
    for line_index = 1, 2 do
      local line = belt.get_transport_line(line_index)
      if line and line.valid then
        local contents = line.get_contents()
        total = total + (contents[item_name] or 0)
      end
    end
  end

  return total
end

local function total_debug_belt_block_count(belts)
  local total = 0

  for _, belt in ipairs(belts) do
    if belt.valid then
      total = total + remote.call(
        constants.mod_name,
        "debug_get_belt_block_count",
        surface().index,
        belt.position.x,
        belt.position.y
      )
    end
  end

  return total
end

local function register_test_stash(entity, region_x, region_y)
  local surface_index = entity.surface.index
  local stash_id = storage.next_squirrel_stash_id
  local key = region_x .. "," .. region_y

  storage.next_squirrel_stash_id = stash_id + 1
  storage.squirrel_stashes[surface_index] = storage.squirrel_stashes[surface_index] or {}
  storage.squirrel_stashes[surface_index][stash_id] = {
    entity = entity,
    region_x = region_x,
    region_y = region_y
  }
  storage.squirrel_stashes_by_region[surface_index] = storage.squirrel_stashes_by_region[surface_index] or {}
  storage.squirrel_stashes_by_region[surface_index][key] = storage.squirrel_stashes_by_region[surface_index][key] or {
    ids = {}
  }
  storage.squirrel_stashes_by_region[surface_index][key].ids[stash_id] = true

  return stash_id
end

local function find_squirrel(report, squirrel_id)
  for _, squirrel in ipairs(report.squirrels or {}) do
    if squirrel.squirrel_id == squirrel_id then
      return squirrel
    end
  end

  return nil
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

local function fill_chunk_with_forest(chunk_x, chunk_y, spacing)
  local area = {
    left_top = {x = chunk_x * constants.chunk_size, y = chunk_y * constants.chunk_size},
    right_bottom = {
      x = (chunk_x * constants.chunk_size) + constants.chunk_size,
      y = (chunk_y * constants.chunk_size) + constants.chunk_size
    }
  }
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
  storage.squirrel_selection_overlays = {}
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
  it("seeds initial squirrel presence during chunk generation for forested chunks", function()
    local chunk_x = math.floor(FOREST_ORIGIN.x / constants.chunk_size)
    local chunk_y = math.floor(FOREST_ORIGIN.y / constants.chunk_size)

    fill_chunk_with_forest(chunk_x, chunk_y, 5)

    local created = remote.call(constants.mod_name, "debug_seed_squirrel_chunk", surface().index, chunk_x, chunk_y)
    local report = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    assert.equal(1, created)
    assert.equal(1, #report.squirrels)
  end)

  it("spawns visible squirrels only in eligible forest-edge regions", function()
    local barren = remote.call(constants.mod_name, "debug_force_region_squirrels", surface().index, BARREN_ORIGIN.x, BARREN_ORIGIN.y)

    spawn_forest(18, FOREST_ORIGIN)
    local created = remote.call(constants.mod_name, "debug_force_region_squirrels", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y)
    local report = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    assert.equal(0, barren)
    assert.is_true(created >= 2)
    assert.equal(created, #report.squirrels)
  end)

  it("scales regional squirrel population with forest density", function()
    spawn_forest(12, BARREN_ORIGIN)

    local dense_coord = regions.position_to_region_coord(FOREST_ORIGIN)
    fill_region_with_forest(dense_coord.x, dense_coord.y, 5)

    local sparse_created = remote.call(constants.mod_name, "debug_force_region_squirrels", surface().index, BARREN_ORIGIN.x, BARREN_ORIGIN.y)
    local dense_created = remote.call(constants.mod_name, "debug_force_region_squirrels", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y)

    assert.is_true(sparse_created >= 2)
    assert.is_true(dense_created > sparse_created)
  end)

  it("refills active squirrel populations gradually instead of spawning a full region burst", function()
    spawn_forest(18, FOREST_ORIGIN)
    player().teleport(FOREST_ORIGIN, surface())
    regions.force_recompute_at_position(surface(), FOREST_ORIGIN, game.tick)

    squirrels.on_tick(constants.squirrel_update_interval)
    local first = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    squirrels.on_tick(constants.squirrel_update_interval * 2)
    local second = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    assert.equal(1, #first.squirrels)
    assert.is_true(#second.squirrels >= 2)
  end)

  it("prefers spawning squirrels outside the player's immediate view when the forest has space", function()
    local coord = regions.position_to_region_coord(FOREST_ORIGIN)

    fill_region_with_forest(coord.x, coord.y, 6)
    player().teleport({
      x = FOREST_ORIGIN.x + 8,
      y = FOREST_ORIGIN.y + 8
    }, surface())

    local created = remote.call(constants.mod_name, "debug_force_region_squirrels", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y)
    local report = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    assert.is_true(created >= 1)
    assert.is_true(#report.squirrels >= 1)

    for _, squirrel in ipairs(report.squirrels) do
      local dx = squirrel.position.x - player().position.x
      local dy = squirrel.position.y - player().position.y
      local distance_squared = (dx * dx) + (dy * dy)

      assert.is_true(distance_squared >= (constants.squirrel_spawn_relaxed_player_buffer ^ 2))
    end
  end)

  it("keeps spawned squirrels present across multiple runtime updates", function()
    spawn_forest(24, FOREST_ORIGIN)
    remote.call(constants.mod_name, "debug_force_region_squirrels", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y)
    player().teleport(FOREST_ORIGIN, surface())

    local before = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)
    local before_ids = {}

    for _, squirrel in ipairs(before.squirrels) do
      before_ids[squirrel.squirrel_id] = true
    end

    local after = remote.call(
      constants.mod_name,
      "debug_advance_squirrel_runtime",
      constants.squirrel_move_timeout + constants.squirrel_decision_interval + 180
    )

    assert.is_true(#before.squirrels >= 2)
    assert.is_true(#after.squirrels >= #before.squirrels)

    for _, squirrel in ipairs(after.squirrels) do
      before_ids[squirrel.squirrel_id] = nil
    end

    assert.equal(0, table_size(before_ids))
  end)

  it("keeps calm squirrels close to their forest home while roaming", function()
    spawn_forest(24, FOREST_ORIGIN)
    remote.call(constants.mod_name, "debug_force_region_squirrels", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y)
    player().teleport(FOREST_ORIGIN, surface())

    local report = remote.call(
      constants.mod_name,
      "debug_advance_squirrel_runtime",
      (constants.squirrel_update_interval * 8) + constants.squirrel_idle_pause_max
    )

    assert.is_true(#report.squirrels >= 2)

    for _, squirrel in ipairs(report.squirrels) do
      local dx = squirrel.position.x - squirrel.home_position.x
      local dy = squirrel.position.y - squirrel.home_position.y
      local distance_squared = (dx * dx) + (dy * dy)
      local allowed_distance = constants.squirrel_home_wander_distance + constants.squirrel_roam_step_max_distance

      assert.is_true(distance_squared <= (allowed_distance * allowed_distance))
      assert.is_true(squirrel.mode == "idle" or squirrel.mode == "roam")
    end
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

  it("lets belts become steal targets before chest scavenging unlocks", function()
    local coord = regions.position_to_region_coord(CHEST_ORIGIN)
    local trees = fill_region_with_forest(coord.x, coord.y, 8)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, CHEST_ORIGIN.x, CHEST_ORIGIN.y)
    local belt = track_entity(surface().create_entity({
      name = "transport-belt",
      position = {x = CHEST_ORIGIN.x + 6, y = CHEST_ORIGIN.y},
      direction = defines.direction.east,
      force = game.forces.player
    }))
    local chest = track_entity(surface().create_entity({
      name = "wooden-chest",
      position = {x = CHEST_ORIGIN.x + 8, y = CHEST_ORIGIN.y},
      force = game.forces.player
    }))
    local inventory = chest.get_inventory(defines.inventory.chest)
    local report

    assert.is_not_nil(belt)
    assert.is_true(belt.get_transport_line(1).insert_at(0.25, {name = "iron-plate", count = 1}))
    inventory.insert({name = "iron-gear-wheel", count = 80})

    for index = 1, #trees do
      regions.note_tree_loss(surface().index, trees[index].position, 1, game.tick)
      trees[index].destroy()
      report = regions.get_region_report_at_position(surface(), CHEST_ORIGIN, game.tick)

      if
        report.habitat_pressure >= constants.squirrel_mischief_pressure
        and report.habitat_pressure < constants.squirrel_chest_pressure_threshold
      then
        break
      end
    end

    assert.is_not_nil(report)
    assert.is_true(report.habitat_pressure >= constants.squirrel_mischief_pressure)
    assert.is_true(report.habitat_pressure < constants.squirrel_chest_pressure_threshold)
    assert.equal("mischievous", remote.call(constants.mod_name, "debug_squirrel_state_at_position", surface().index, CHEST_ORIGIN.x, CHEST_ORIGIN.y))

    local target = remote.call(constants.mod_name, "debug_get_squirrel_target", squirrel_id)

    assert.is_table(target.local_target)
    assert.equal("belt", target.local_target.target_type)
    assert.equal("steal", target.local_intent)
    assert.equal("belt", target.chosen_target.target_type)
    assert.is_nil(remote.call(constants.mod_name, "debug_force_chest_scavenge", surface().index, squirrel_id, chest.position.x, chest.position.y))
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

  it("lets calm squirrels inspect nearby belts in healthy forest-edge areas", function()
    spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x + 6, BELT_ORIGIN.y)
    local belt = track_entity(surface().create_entity({
      name = "transport-belt",
      position = {x = BELT_ORIGIN.x + 8, y = BELT_ORIGIN.y},
      direction = defines.direction.east,
      force = game.forces.player
    }))

    assert.is_number(squirrel_id)
    assert.is_not_nil(belt)
    assert.is_true(belt.get_transport_line(1).insert_at(0.25, {name = "iron-plate", count = 1}))

    local target = remote.call(constants.mod_name, "debug_get_squirrel_target", squirrel_id)

    assert.equal("calm", target.state)
    assert.is_table(target.local_target)
    assert.equal("belt", target.local_target.target_type)
    assert.equal("inspect", target.local_intent)
    assert.is_table(target.chosen_target)
    assert.equal("belt", target.chosen_target.target_type)
  end)

  it("lets calm squirrels choose nearby empty belts for passive sitting", function()
    spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x + 6, BELT_ORIGIN.y)
    local belt = track_entity(surface().create_entity({
      name = "transport-belt",
      position = {x = BELT_ORIGIN.x + 8, y = BELT_ORIGIN.y},
      direction = defines.direction.east,
      force = game.forces.player
    }))

    assert.is_number(squirrel_id)
    assert.is_not_nil(belt)

    local target = remote.call(constants.mod_name, "debug_get_squirrel_target", squirrel_id)

    assert.equal("calm", target.state)
    assert.is_table(target.local_target)
    assert.equal("belt", target.local_target.target_type)
    assert.equal("inspect", target.local_intent)
  end)

  it("makes stocked feeders outrank nearby calm belt sitting", function()
    spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x + 6, BELT_ORIGIN.y)
    local belt = track_entity(surface().create_entity({
      name = "transport-belt",
      position = {x = BELT_ORIGIN.x + 8, y = BELT_ORIGIN.y},
      direction = defines.direction.east,
      force = game.forces.player
    }))
    local feeder = track_entity(surface().create_entity({
      name = constants.names.feeder,
      position = {x = BELT_ORIGIN.x + 9, y = BELT_ORIGIN.y + 2},
      force = game.forces.player
    }))

    assert.is_number(squirrel_id)
    assert.is_not_nil(belt)
    assert.is_not_nil(feeder)
    assert.is_true(belt.get_transport_line(1).insert_at(0.25, {name = "iron-plate", count = 1}))

    local inventory = feeder.get_inventory(defines.inventory.chest)
    assert.is_not_nil(inventory)
    assert.equal(constants.stocked_feeder_threshold, inventory.insert({
      name = constants.names.nut,
      count = constants.stocked_feeder_threshold
    }))

    local target = remote.call(constants.mod_name, "debug_get_squirrel_target", squirrel_id)

    assert.equal("calm", target.state)
    assert.is_table(target.local_target)
    assert.equal("feeder", target.local_target.target_type)
    assert.equal("feed", target.local_intent)
    assert.is_table(target.chosen_target)
    assert.equal("feeder", target.chosen_target.target_type)
  end)

  it("shows and clears the feeder peace-radius overlay for the selecting player", function()
    spawn_forest(18, BELT_ORIGIN)
    local feeder = track_entity(surface().create_entity({
      name = constants.names.feeder,
      position = {x = BELT_ORIGIN.x + 9, y = BELT_ORIGIN.y + 2},
      force = game.forces.player
    }))
    local inventory = feeder.get_inventory(defines.inventory.chest)

    assert.is_not_nil(inventory)
    assert.equal(constants.stocked_feeder_threshold, inventory.insert({
      name = constants.names.nut,
      count = constants.stocked_feeder_threshold
    }))

    local shown = remote.call(
      constants.mod_name,
      "debug_show_feeder_overlay",
      player().index,
      surface().index,
      feeder.position.x,
      feeder.position.y
    )
    local overlay = remote.call(constants.mod_name, "debug_get_feeder_overlay_state", player().index)

    assert.is_table(shown)
    assert.is_true(shown.stocked)
    assert.is_table(overlay)
    assert.is_true(overlay.stocked)
    assert.equal(constants.squirrel_feeder_peace_radius, overlay.radius)
    assert.equal(2, overlay.render_count)

    assert.is_true(remote.call(constants.mod_name, "debug_clear_feeder_overlay", player().index))
    assert.is_nil(remote.call(constants.mod_name, "debug_get_feeder_overlay_state", player().index))
  end)

  it("shows and clears squirrel local and belt-interest overlays for the selecting player", function()
    spawn_forest(18, FOREST_ORIGIN)

    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, FOREST_ORIGIN.x + 4, FOREST_ORIGIN.y + 4)
    local snapshot = remote.call(constants.mod_name, "debug_get_squirrel_snapshot", squirrel_id)

    assert.is_number(squirrel_id)
    assert.is_table(snapshot)

    local shown = remote.call(
      constants.mod_name,
      "debug_show_squirrel_overlay",
      player().index,
      surface().index,
      snapshot.position.x,
      snapshot.position.y
    )
    local overlay = remote.call(constants.mod_name, "debug_get_squirrel_overlay_state", player().index)

    assert.is_table(shown)
    assert.is_table(overlay)
    assert.equal(shown.local_radius, overlay.local_radius)
    assert.equal(shown.belt_interest_radius, overlay.belt_interest_radius)
    assert.is_true(overlay.belt_interest_radius > overlay.local_radius)
    assert.equal(shown.state, overlay.state)
    assert.equal(2, overlay.render_count)

    assert.is_true(remote.call(constants.mod_name, "debug_clear_squirrel_overlay", player().index))
    assert.is_nil(remote.call(constants.mod_name, "debug_get_squirrel_overlay_state", player().index))
  end)

  it("suppresses squirrel selection overlays when the debug flag is disabled", function()
    spawn_forest(18, FOREST_ORIGIN)

    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, FOREST_ORIGIN.x + 4, FOREST_ORIGIN.y + 4)
    local snapshot = remote.call(constants.mod_name, "debug_get_squirrel_snapshot", squirrel_id)
    local original = constants.debug_squirrel_selection_overlay

    assert.is_number(squirrel_id)
    assert.is_table(snapshot)

    constants.debug_squirrel_selection_overlay = false

    local shown = remote.call(
      constants.mod_name,
      "debug_show_squirrel_overlay",
      player().index,
      surface().index,
      snapshot.position.x,
      snapshot.position.y
    )
    local overlay = remote.call(constants.mod_name, "debug_get_squirrel_overlay_state", player().index)

    constants.debug_squirrel_selection_overlay = original

    assert.is_nil(shown)
    assert.is_nil(overlay)
  end)

  it("lets squirrels visit stocked feeders, eat nuts, and then leave", function()
    spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x + 6, BELT_ORIGIN.y)
    local feeder = track_entity(surface().create_entity({
      name = constants.names.feeder,
      position = {x = BELT_ORIGIN.x + 9, y = BELT_ORIGIN.y + 1},
      force = game.forces.player
    }))

    local inventory = feeder.get_inventory(defines.inventory.chest)
    assert.is_not_nil(inventory)
    assert.equal(constants.stocked_feeder_threshold, inventory.insert({
      name = constants.names.nut,
      count = constants.stocked_feeder_threshold
    }))

    player().teleport({x = BELT_ORIGIN.x - 10, y = BELT_ORIGIN.y}, surface())

    remote.call(
      constants.mod_name,
      "debug_advance_squirrel_runtime",
      constants.squirrel_idle_pause_max
        + constants.squirrel_move_timeout
        + constants.squirrel_feeder_visit_duration
    )

    local snapshot = remote.call(constants.mod_name, "debug_get_squirrel_snapshot", squirrel_id)

    assert.is_not_nil(snapshot)
    assert.is_true(inventory.get_item_count(constants.names.nut) < constants.stocked_feeder_threshold)
    assert.is_true(snapshot.mode == "roam" or snapshot.mode == "idle")
  end)

  it("lets curious squirrels inspect nearby belts once they have ranged to the forest edge", function()
    local trees = spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x + 6, BELT_ORIGIN.y)
    local belt = track_entity(surface().create_entity({
      name = "transport-belt",
      position = {x = BELT_ORIGIN.x + 8, y = BELT_ORIGIN.y},
      direction = defines.direction.east,
      force = game.forces.player
    }))

    assert.is_number(squirrel_id)
    assert.is_not_nil(belt)
    assert.is_true(belt.get_transport_line(1).insert_at(0.25, {name = "iron-plate", count = 1}))

    regions.note_tree_loss(surface().index, trees[1].position, 1, game.tick)
    trees[1].destroy()

    local target = remote.call(constants.mod_name, "debug_get_squirrel_target", squirrel_id)

    assert.equal("curious", target.state)
    assert.is_table(target.local_target)
    assert.equal("belt", target.local_target.target_type)
    assert.equal("inspect", target.local_intent)
    assert.is_table(target.chosen_target)
    assert.equal("belt", target.chosen_target.target_type)
  end)

  it("uses excursion targets when interesting belts are outside the squirrel's immediate local radius", function()
    local trees = spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x, BELT_ORIGIN.y)
    local belt = track_entity(surface().create_entity({
      name = "transport-belt",
      position = {x = BELT_ORIGIN.x + 18, y = BELT_ORIGIN.y},
      direction = defines.direction.east,
      force = game.forces.player
    }))

    assert.is_number(squirrel_id)
    assert.is_not_nil(belt)
    assert.is_true(belt.get_transport_line(1).insert_at(0.25, {name = "iron-plate", count = 1}))

    regions.note_tree_loss(surface().index, trees[1].position, 1, game.tick)
    trees[1].destroy()

    local target = remote.call(constants.mod_name, "debug_get_squirrel_target", squirrel_id)

    assert.equal("curious", target.state)
    assert.is_nil(target.local_target)
    assert.is_table(target.excursion_target)
    assert.equal("belt", target.excursion_target.target_type)
    assert.equal("inspect", target.excursion_intent)
    assert.is_table(target.chosen_target)
    assert.equal("belt", target.chosen_target.target_type)
  end)

  it("turns outward belt excursions into real belt raids once squirrels reach the line", function()
    local trees = spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x, BELT_ORIGIN.y)
    local belts = create_belt_line({x = BELT_ORIGIN.x + 18, y = BELT_ORIGIN.y}, 8, "iron-plate", 60)

    player().teleport({x = BELT_ORIGIN.x - 12, y = BELT_ORIGIN.y}, surface())

    for index = 1, 8 do
      regions.note_tree_loss(surface().index, trees[index].position, 1, game.tick)
      trees[index].destroy()
    end

    local target = remote.call(constants.mod_name, "debug_get_squirrel_target", squirrel_id)

    assert.is_table(target.excursion_target)
    assert.equal("belt", target.excursion_target.target_type)

    remote.call(
      constants.mod_name,
      "debug_advance_squirrel_runtime",
      (constants.squirrel_move_timeout * 2)
        + constants.squirrel_idle_pause_max
        + constants.squirrel_belt_block_duration
    )

    assert.is_true(total_belt_item_count(belts, "iron-plate") <= (60 - constants.squirrel_belt_grab_amount))
  end)

  it("renders both the carried item and stolen count after a belt grab", function()
    local trees = spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x + 6, BELT_ORIGIN.y)
    local belts = create_belt_line({x = BELT_ORIGIN.x + 8, y = BELT_ORIGIN.y}, 4, "iron-plate", 20)

    for index = 1, 8 do
      local tree = trees[index]
      if tree and tree.valid then
        regions.note_tree_loss(surface().index, tree.position, 1, game.tick)
        tree.destroy()
      end
    end

    local snapshot = remote.call(
      constants.mod_name,
      "debug_force_single_belt_grab",
      surface().index,
      squirrel_id,
      belts[1].position.x,
      belts[1].position.y
    )

    assert.is_table(snapshot)
    assert.is_table(snapshot.carrying)
    assert.is_true(snapshot.carrying.count > 0)
    assert.is_true(snapshot.render_sprite)
    assert.is_true(snapshot.render_count)
  end)

  it("diverts nearby belt theft into feeder visits once a stocked feeder pacifies that belt area", function()
    local trees = spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x + 6, BELT_ORIGIN.y)
    local belts = create_belt_line({x = BELT_ORIGIN.x + 8, y = BELT_ORIGIN.y}, 4, "iron-plate", 40)

    for index = 1, 8 do
      local tree = trees[index]
      if tree and tree.valid then
        regions.note_tree_loss(surface().index, tree.position, 1, game.tick)
        tree.destroy()
      end
    end

    local feeder = track_entity(surface().create_entity({
      name = constants.names.feeder,
      position = {x = BELT_ORIGIN.x + 9, y = BELT_ORIGIN.y + 1},
      force = game.forces.player
    }))
    local inventory = feeder.get_inventory(defines.inventory.chest)

    assert.equal(constants.stocked_feeder_threshold, inventory.insert({
      name = constants.names.nut,
      count = constants.stocked_feeder_threshold
    }))

    local before_first_grab = total_belt_item_count(belts, "iron-plate")
    local initial = remote.call(
      constants.mod_name,
      "debug_force_single_belt_grab",
      surface().index,
      squirrel_id,
      belts[1].position.x,
      belts[1].position.y
    )
    local after_first_grab = total_belt_item_count(belts, "iron-plate")

    assert.is_table(initial)
    assert.equal("blocking", initial.mode)
    assert.equal("feed", initial.intent)
    assert.equal(before_first_grab, after_first_grab)
    assert.is_nil(initial.carrying)

    remote.call(
      constants.mod_name,
      "debug_advance_squirrel_runtime",
      constants.squirrel_belt_grab_interval + constants.squirrel_update_interval
    )

    local after = remote.call(constants.mod_name, "debug_get_squirrel_snapshot", squirrel_id)
    local after_runtime_count = total_belt_item_count(belts, "iron-plate")

    assert.equal(after_first_grab, after_runtime_count)
    if after then
      assert.is_false(after.mode == "blocking" and after.intent == "steal")
    end
  end)

  it("stays on belts long enough to steal a meaningful stack before retreating", function()
    spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x, BELT_ORIGIN.y)
    local belts = create_belt_line({x = BELT_ORIGIN.x + 8, y = BELT_ORIGIN.y}, 8, "iron-plate", 16)
    local belt = belts[1]

    assert.is_not_nil(belt)

    local result = remote.call(constants.mod_name, "debug_force_belt_theft", surface().index, squirrel_id, belt.position.x, belt.position.y)
    local report = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    assert.is_table(result)
    assert.equal("iron-plate", result.item_name)
    assert.is_true(result.count >= constants.squirrel_belt_grab_amount)
    assert.is_true(result.count <= 16)
    assert.equal(1, #report.stashes)
    assert.equal(result.count, report.stashes[1].item_count)
  end)

  it("rides belts while inspecting and releases the blocked segment afterwards", function()
    spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x, BELT_ORIGIN.y)
    local belts = create_belt_line({x = BELT_ORIGIN.x + 8, y = BELT_ORIGIN.y}, 8, "iron-plate", 8)

    player().teleport({x = BELT_ORIGIN.x - 10, y = BELT_ORIGIN.y}, surface())

    local initial = remote.call(constants.mod_name, "debug_force_belt_sit", surface().index, squirrel_id, belts[1].position.x, belts[1].position.y)

    assert.is_table(initial)
    assert.equal("blocking", initial.mode)
    assert.equal("inspect", initial.intent)
    assert.is_true(initial.belt_riding)
    assert.is_true(initial.belt_pose_render)
    assert.equal(1, total_debug_belt_block_count(belts))

    local before = remote.call(constants.mod_name, "debug_get_squirrel_snapshot", squirrel_id)
    remote.call(constants.mod_name, "debug_advance_squirrel_runtime", 60 * 2)
    local during = remote.call(constants.mod_name, "debug_get_squirrel_snapshot", squirrel_id)

    assert.is_table(before)
    assert.is_table(during)
    assert.equal("blocking", during.mode)
    assert.equal("inspect", during.intent)
    assert.is_true(during.belt_riding)
    assert.is_true(during.belt_pose_render)
    assert.is_true(during.position.x > (before.position.x + 0.5))
    assert.equal(1, total_debug_belt_block_count(belts))

    remote.call(
      constants.mod_name,
      "debug_advance_squirrel_runtime",
      constants.squirrel_belt_inspect_duration + constants.squirrel_update_interval
    )

    local after = remote.call(constants.mod_name, "debug_get_squirrel_snapshot", squirrel_id)

    assert.is_table(after)
    assert.is_false(after.belt_riding)
    assert.is_false(after.belt_pose_render)
    assert.is_true(after.mode == "roam" or after.mode == "idle")
    assert.equal(0, total_debug_belt_block_count(belts))
  end)

  it("lets pressured squirrels range outward and raid nearby belts in an active forest-edge region", function()
    local coord = regions.position_to_region_coord(BELT_ORIGIN)
    local trees = fill_region_with_forest(coord.x, coord.y, 8)
    local belts = create_belt_line({x = BELT_ORIGIN.x + 10, y = BELT_ORIGIN.y}, 8, "iron-plate", 60)
    player().teleport({x = BELT_ORIGIN.x - 18, y = BELT_ORIGIN.y}, surface())

    for index = 1, 4 do
      regions.note_tree_loss(surface().index, trees[index].position, 1, game.tick)
      trees[index].destroy()
    end

    assert.is_true(
      remote.call(constants.mod_name, "debug_force_region_squirrels", surface().index, BELT_ORIGIN.x, BELT_ORIGIN.y) >= 2
    )

    local report = remote.call(
      constants.mod_name,
      "debug_advance_squirrel_runtime",
      (constants.squirrel_move_timeout * 2)
        + constants.squirrel_decision_interval
        + constants.squirrel_belt_block_duration
        + constants.squirrel_idle_pause_max
    )

    assert.is_true(#report.squirrels >= 2)
    assert.is_true(total_belt_item_count(belts, "iron-plate") <= (60 - constants.squirrel_belt_grab_amount))
  end)

  it("creates a visible forest stash and deposits stolen loot into it", function()
    spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x, BELT_ORIGIN.y)
    local belts = create_belt_line({x = BELT_ORIGIN.x + 10, y = BELT_ORIGIN.y}, 8, "copper-plate", 16)
    local belt = belts[1]

    assert.is_not_nil(belt)
    assert.is_table(remote.call(constants.mod_name, "debug_force_belt_theft", surface().index, squirrel_id, belt.position.x, belt.position.y))

    local before_cleanup = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)
    local stash = surface().find_entities_filtered({
      position = before_cleanup.stashes[1].position,
      name = constants.names.stash,
      limit = 1
    })[1]

    assert.is_not_nil(stash)
    assert.is_true(before_cleanup.stashes[1].item_count >= constants.squirrel_belt_grab_amount)

    local inventory = stash.get_inventory(defines.inventory.chest)
    inventory.clear()

    assert.equal(1, remote.call(constants.mod_name, "debug_cleanup_empty_stashes", surface().index))
    assert.equal(0, #remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index).stashes)
  end)

  it("creates an overflow stash instead of dropping carried loot when existing stashes are full", function()
    spawn_forest(18, BELT_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x, BELT_ORIGIN.y)
    local coord = regions.position_to_region_coord(BELT_ORIGIN)
    local first_stash = track_entity(surface().create_entity({
      name = constants.names.stash,
      position = {x = BELT_ORIGIN.x + 3, y = BELT_ORIGIN.y + 4},
      force = "neutral"
    }))
    local second_stash = track_entity(surface().create_entity({
      name = constants.names.stash,
      position = {x = BELT_ORIGIN.x + 6, y = BELT_ORIGIN.y + 4},
      force = "neutral"
    }))
    local belts = create_belt_line({x = BELT_ORIGIN.x + 10, y = BELT_ORIGIN.y}, 8, "coal", 50)

    register_test_stash(first_stash, coord.x, coord.y)
    register_test_stash(second_stash, coord.x, coord.y)

    for _, stash in ipairs({first_stash, second_stash}) do
      local inventory = stash.get_inventory(defines.inventory.chest)
      assert.is_not_nil(inventory)
      assert.equal(50, inventory.insert({name = "stone", count = 50}))
      assert.equal(50, inventory.insert({name = "wood", count = 50}))
      assert.equal(50, inventory.insert({name = "iron-ore", count = 50}))
      assert.equal(50, inventory.insert({name = "copper-ore", count = 50}))
      assert.equal(50, inventory.insert({name = "iron-plate", count = 50}))
      assert.equal(50, inventory.insert({name = "copper-plate", count = 50}))
      assert.equal(50, inventory.insert({name = "iron-gear-wheel", count = 50}))
      assert.equal(50, inventory.insert({name = "electronic-circuit", count = 50}))
      assert.is_false(inventory.can_insert({name = "coal", count = 1}))
    end

    local result = remote.call(constants.mod_name, "debug_force_belt_theft", surface().index, squirrel_id, belts[1].position.x, belts[1].position.y)
    local report = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)
    local all_stashes = surface().find_entities_filtered({
      area = square_area(BELT_ORIGIN, 24),
      name = constants.names.stash
    })
    local overflow_stash

    assert.is_table(result)
    assert.equal("coal", result.item_name)
    assert.equal(3, #report.stashes)

    for _, stash in ipairs(all_stashes) do
      if stash.unit_number ~= first_stash.unit_number and stash.unit_number ~= second_stash.unit_number then
        overflow_stash = stash
        break
      end
    end

    assert.is_not_nil(overflow_stash)
    assert.is_true(
      overflow_stash.get_inventory(defines.inventory.chest).get_item_count("coal")
        >= constants.squirrel_belt_grab_amount
    )
  end)

  it("rate-limits repeated theft and stash creation per squirrel and per region", function()
    spawn_forest(18, BELT_ORIGIN)
    local first_squirrel = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x, BELT_ORIGIN.y)
    local second_squirrel = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, BELT_ORIGIN.x + 2, BELT_ORIGIN.y + 2)
    local first_belt = create_belt_line({x = BELT_ORIGIN.x + 12, y = BELT_ORIGIN.y}, 6, "iron-plate", 60)[1]
    local second_belt = create_belt_line({x = BELT_ORIGIN.x + 20, y = BELT_ORIGIN.y}, 6, "copper-plate", 60)[1]

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

    inventory.insert({name = "iron-gear-wheel", count = 80})

    assert.is_nil(remote.call(constants.mod_name, "debug_force_chest_scavenge", surface().index, squirrel_id, chest.position.x, chest.position.y))

    for index = 1, 8 do
      regions.note_tree_loss(surface().index, trees[index].position, 1, game.tick)
      trees[index].destroy()
    end

    local result = remote.call(constants.mod_name, "debug_force_chest_scavenge", surface().index, squirrel_id, chest.position.x, chest.position.y)
    local report = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    assert.is_table(result)
    assert.equal("iron-gear-wheel", result.item_name)
    assert.equal(80, result.count)
    assert.equal(0, inventory.get_item_count("iron-gear-wheel"))
    assert.equal(1, #report.stashes)
  end)

  it("does not treat feeders as chest-scavenge targets", function()
    local trees = spawn_forest(18, CHEST_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, CHEST_ORIGIN.x, CHEST_ORIGIN.y)
    local feeder = track_entity(surface().create_entity({
      name = constants.names.feeder,
      position = {x = CHEST_ORIGIN.x + 8, y = CHEST_ORIGIN.y + 8},
      force = game.forces.player
    }))
    local inventory = feeder.get_inventory(defines.inventory.chest)

    inventory.insert({name = constants.names.nut, count = 8})

    for index = 1, 8 do
      regions.note_tree_loss(surface().index, trees[index].position, 1, game.tick)
      trees[index].destroy()
    end

    assert.is_nil(remote.call(constants.mod_name, "debug_force_chest_scavenge", surface().index, squirrel_id, feeder.position.x, feeder.position.y))
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

  it("treats walking onto a squirrel as rough handling and makes it flee", function()
    spawn_forest(18, FOREST_ORIGIN)
    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, FOREST_ORIGIN.x + 6, FOREST_ORIGIN.y + 2)
    local before = remote.call(constants.mod_name, "force_recompute_at_position", surface().index, FOREST_ORIGIN.x + 6, FOREST_ORIGIN.y + 2)
    local snapshot_before = remote.call(constants.mod_name, "debug_get_squirrel_snapshot", squirrel_id)

    assert.is_number(squirrel_id)
    assert.is_table(snapshot_before)

    local incident_id = remote.call(
      constants.mod_name,
      "debug_handle_player_step",
      player().index,
      snapshot_before.position.x,
      snapshot_before.position.y
    )
    local snapshot_after = remote.call(constants.mod_name, "debug_get_squirrel_snapshot", squirrel_id)
    local after = remote.call(constants.mod_name, "force_recompute_at_position", surface().index, FOREST_ORIGIN.x + 6, FOREST_ORIGIN.y + 2)

    assert.is_number(incident_id)
    assert.is_table(snapshot_after)
    assert.equal("roam", snapshot_after.mode)
    assert.is_true(after.rough_handling_penalty > before.rough_handling_penalty)
  end)

  it("can clear all squirrels on a surface in one debug call", function()
    spawn_forest(24, FOREST_ORIGIN)
    player().teleport(FOREST_ORIGIN, surface())
    remote.call(constants.mod_name, "debug_force_region_squirrels", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y)

    local before = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)
    local destroyed = remote.call(constants.mod_name, "debug_clear_surface_squirrels", surface().index)
    local after = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    assert.is_true(#before.squirrels >= 2)
    assert.equal(#before.squirrels, destroyed)
    assert.equal(0, #after.squirrels)
  end)

  it("replenishes regional squirrel population after a squirrel is removed", function()
    spawn_forest(24, FOREST_ORIGIN)
    player().teleport(FOREST_ORIGIN, surface())
    remote.call(constants.mod_name, "debug_force_region_squirrels", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y)

    local before = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    assert.is_true(#before.squirrels >= 2)
    assert.is_true(remote.call(constants.mod_name, "debug_kill_squirrel", before.squirrels[1].squirrel_id))

    local after_loss = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)
    local replenished = remote.call(constants.mod_name, "debug_force_region_squirrels", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y)
    local final = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    assert.equal(#before.squirrels - 1, #after_loss.squirrels)
    assert.equal(1, replenished)
    assert.equal(#before.squirrels, #final.squirrels)
  end)

  it("culls squirrels outside the active player region set", function()
    spawn_forest(24, FOREST_ORIGIN)
    player().teleport(FOREST_ORIGIN, surface())
    remote.call(constants.mod_name, "debug_force_region_squirrels", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y)

    local before = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)

    player().teleport({x = 0, y = 0}, surface())

    local after = remote.call(
      constants.mod_name,
      "debug_advance_squirrel_runtime",
      constants.squirrel_update_interval
    )

    assert.is_true(#before.squirrels >= 2)
    assert.equal(0, #after.squirrels)
  end)

  it("throttles the invalid-squirrel safety sweep instead of scanning every tick", function()
    spawn_forest(18, FOREST_ORIGIN)
    player().teleport(FOREST_ORIGIN, surface())

    local squirrel_id = remote.call(constants.mod_name, "debug_spawn_squirrel", surface().index, FOREST_ORIGIN.x, FOREST_ORIGIN.y)
    local report = remote.call(constants.mod_name, "debug_get_squirrel_report", surface().index)
    local entity = surface().find_entities_filtered({
      position = report.squirrels[1].position,
      name = constants.names.squirrel,
      limit = 1
    })[1]

    assert.is_number(squirrel_id)
    assert.is_not_nil(entity)

    local baseline_tick = game.tick
    entity.destroy()
    storage.squirrel_last_cleanup_tick = baseline_tick

    assert.is_not_nil(storage.squirrels[squirrel_id])
    remote.call(constants.mod_name, "debug_advance_squirrel_runtime", constants.squirrel_update_interval)
    assert.equal(baseline_tick, storage.squirrel_last_cleanup_tick)
    assert.is_not_nil(storage.squirrels[squirrel_id])

    remote.call(constants.mod_name, "debug_advance_squirrel_runtime", constants.squirrel_cleanup_interval)

    assert.is_true(storage.squirrel_last_cleanup_tick > baseline_tick)
    assert.is_nil(storage.squirrels[squirrel_id])
  end)

  it("keeps the relocation custom input registered for squirrel control", function()
    assert.is_not_nil(prototypes.custom_input[constants.names.relocation_input])
  end)
end)
