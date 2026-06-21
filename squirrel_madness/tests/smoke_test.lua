local constants = require("scripts.constants")
local regions = require("scripts.regions.module")

local POS = {x = 128, y = 128}
local TREE_NAME = "tree-01"

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

local function player()
  return game.players[1]
end

local function reset_region_storage()
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
end

local function spawn_forest(count, origin)
  local trees = {}

  for index = 1, count do
    local x = origin.x + ((index - 1) % 6) * 5
    local y = origin.y + math.floor((index - 1) / 6) * 5
    trees[#trees + 1] = surface().create_entity({
      name = TREE_NAME,
      position = {x = x, y = y}
    })
  end

  return trees
end

before_each(function()
  surface().clear_pollution()
  reset_region_storage()
  player().teleport({x = 0, y = 0}, surface())
  local inventory = player().get_main_inventory()
  if inventory then
    inventory.clear()
  end
end)

after_each(function()
  surface().clear_pollution()
  reset_region_storage()
  local inventory = player().get_main_inventory()
  if inventory then
    inventory.clear()
  end
end)

describe("regions.position_to_region_coord", function()
  it("groups tiles into 2x2 chunk regions", function()
    assert.same({x = 0, y = 0}, regions.position_to_region_coord({x = 0, y = 0}))
    assert.same({x = 0, y = 0}, regions.position_to_region_coord({x = 63, y = 63}))
    assert.same({x = 1, y = 0}, regions.position_to_region_coord({x = 64, y = 0}))
    assert.same({x = -1, y = -1}, regions.position_to_region_coord({x = -1, y = -1}))
  end)
end)

describe("squirrel_madness remote interface", function()
  local feeder

  before_each(function()
    feeder = surface().create_entity({
      name = constants.names.feeder,
      position = POS,
      force = game.forces.player
    })

    assert.is_not_nil(feeder)

    local inventory = feeder.get_inventory(defines.inventory.chest)
    inventory.insert({name = constants.names.nut, count = constants.stocked_feeder_threshold})
  end)

  after_each(function()
    if feeder and feeder.valid then
      feeder.destroy()
    end
  end)

  it("reports stocked feeders after recomputing a region", function()
    local report = remote.call(constants.mod_name, "force_recompute_at_position", surface().index, POS.x, POS.y)

    assert.is_table(report)
    assert.equal(1, report.feeder_count)
    assert.equal(1, report.stocked_feeders)
    assert.equal("strained", report.squirrel_trust_band)
    assert.is_number(report.stocked_feeder_bonus)
  end)
end)

describe("region ecology metrics", function()
  local trees
  local forest_origin = {x = 0, y = 0}

  before_each(function()
    trees = spawn_forest(18, forest_origin)
  end)

  after_each(function()
    for _, tree in ipairs(trees or {}) do
      if tree and tree.valid then
        tree.destroy()
      end
    end
  end)

  it("raises unrest and pressure after recent deforestation", function()
    local before = remote.call(constants.mod_name, "force_recompute_at_position", surface().index, forest_origin.x, forest_origin.y)

    for index = 1, 4 do
      local tree = trees[index]
      regions.note_tree_loss(surface().index, tree.position, 1, game.tick)
      tree.destroy()
    end

    local after = remote.call(constants.mod_name, "get_region_at_position", surface().index, forest_origin.x, forest_origin.y)

    assert.equal(4, after.recent_tree_loss)
    assert.is_true(after.tree_count < before.tree_count)
    assert.is_true(after.forest_health < before.forest_health)
    assert.is_true(after.squirrel_trust < before.squirrel_trust)
    assert.is_true(after.squirrel_unrest > before.squirrel_unrest)
    assert.is_true(after.habitat_pressure > before.habitat_pressure)
    assert.is_true(after.recent_tree_loss_penalty > 0)
  end)

  it("tracks actual player mining as recent tree loss", function()
    local tree = trees[1]

    player().teleport({x = tree.position.x + 1, y = tree.position.y}, surface())

    assert.is_true(player().mine_entity(tree, true))

    local after = remote.call(constants.mod_name, "get_region_at_position", surface().index, forest_origin.x, forest_origin.y)

    assert.equal(1, after.recent_tree_loss)
    assert.is_true(after.recent_tree_loss_penalty > 0)
    assert.is_true(after.squirrel_unrest > 0)
  end)

  it("uses a rolling pollution average in exact reports", function()
    surface().clear_pollution()

    local baseline = remote.call(constants.mod_name, "force_recompute_at_position", surface().index, forest_origin.x, forest_origin.y)
    surface().pollute(forest_origin, 30)
    local polluted = remote.call(constants.mod_name, "force_recompute_at_position", surface().index, forest_origin.x, forest_origin.y)
    surface().clear_pollution()
    local retained = remote.call(constants.mod_name, "force_recompute_at_position", surface().index, forest_origin.x, forest_origin.y)

    assert.equal(0, baseline.rolling_pollution)
    assert.is_true(polluted.rolling_pollution > 0)
    assert.is_true(polluted.rolling_pollution_penalty > 0)
    assert.equal(0, retained.instant_pollution)
    assert.is_true(retained.rolling_pollution > 0)
    assert.is_true(retained.forest_health < baseline.forest_health)
  end)

  it("reuses clean region reports without recomputing every read", function()
    local first = regions.get_region_report_at_position(surface(), forest_origin, 100)
    local second = regions.get_region_report_at_position(surface(), forest_origin, 101)

    assert.equal(100, first.last_updated_tick)
    assert.equal(100, second.last_updated_tick)
  end)

  it("recomputes a region again after it is marked dirty", function()
    local first = regions.get_region_report_at_position(surface(), forest_origin, 100)

    regions.mark_dirty(surface().index, forest_origin)

    local second = regions.get_region_report_at_position(surface(), forest_origin, 101)

    assert.equal(100, first.last_updated_tick)
    assert.equal(101, second.last_updated_tick)
  end)

  it("batches active region refreshes instead of recomputing the full player area at once", function()
    player().teleport(forest_origin, surface())

    local before = regions.get_cached_region_report_at_position(surface(), forest_origin)
    local enqueued = remote.call(constants.mod_name, "debug_enqueue_active_regions", true)
    local processed = remote.call(constants.mod_name, "debug_process_region_refresh_queue", 1)
    local after = regions.get_cached_region_report_at_position(surface(), forest_origin)

    assert.equal(0, before.tree_count)
    assert.is_true(enqueued > 1)
    assert.equal(1, processed.processed)
    assert.is_true(processed.queued > 0)
    assert.is_true(after.tree_count > 0)
  end)

  it("refreshes dirty active regions from the queue without forcing all active regions immediately", function()
    player().teleport(forest_origin, surface())
    remote.call(constants.mod_name, "debug_enqueue_active_regions", true)
    remote.call(constants.mod_name, "debug_process_region_refresh_queue", 25)

    local baseline = regions.get_cached_region_report_at_position(surface(), forest_origin)
    local tree = trees[1]

    assert.is_true(baseline.tree_count > 0)
    assert.is_not_nil(tree)

    tree.destroy()
    regions.mark_dirty(surface().index, forest_origin)

    local stale = regions.get_cached_region_report_at_position(surface(), forest_origin)
    local enqueued = remote.call(constants.mod_name, "debug_enqueue_active_regions", true)
    local processed = remote.call(constants.mod_name, "debug_process_region_refresh_queue", 1)
    local refreshed = regions.get_cached_region_report_at_position(surface(), forest_origin)

    assert.equal(baseline.tree_count, stale.tree_count)
    assert.is_true(enqueued >= 1)
    assert.equal(1, processed.processed)
    assert.equal(baseline.tree_count - 1, refreshed.tree_count)
  end)
end)
