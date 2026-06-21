-- Behavioral tests for scripts/feeders/inventory.lua. is_feeder_name,
-- is_stocked and wants_full_variant are pure threshold helpers; get_inventory /
-- get_nut_count / snapshot_contents / restore_contents read live entity
-- inventories, so a real feeder entity is created for the inventory-backed
-- assertions. The stock thresholds drive whether a region counts a feeder, so
-- their exact boundaries are pinned here.

local inventory_ops = require("scripts.feeders.inventory")
local constants = require("scripts.constants")

local ORIGIN = {x = 1100, y = 1100}
local spawned

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

describe("feeders.inventory submodule", function()
  before_each(function()
    spawned = {}
    surface().request_to_generate_chunks(ORIGIN, 1)
    surface().force_generate_chunk_requests()
  end)

  after_each(function()
    for _, entity in ipairs(spawned or {}) do
      if entity and entity.valid then
        entity.destroy()
      end
    end
    spawned = {}
  end)

  local function new_feeder(name, position)
    local entity = surface().create_entity({
      name = name or constants.names.feeder_empty,
      position = position or ORIGIN,
      force = "player"
    })
    assert.is_not_nil(entity)
    spawned[#spawned + 1] = entity
    return entity
  end

  it("recognizes every feeder variant name and rejects others", function()
    assert.is_true(inventory_ops.is_feeder_name(constants.names.feeder))
    assert.is_true(inventory_ops.is_feeder_name(constants.names.feeder_empty))
    assert.is_true(inventory_ops.is_feeder_name(constants.names.steel_feeder))
    assert.is_true(inventory_ops.is_feeder_name(constants.names.steel_feeder_empty))
    assert.is_falsy(inventory_ops.is_feeder_name(constants.names.nut_tree))
    assert.is_falsy(inventory_ops.is_feeder_name("nonexistent-entity"))
  end)

  it("treats a feeder as stocked only at the stocked threshold", function()
    local threshold = constants.stocked_feeder_threshold
    assert.is_falsy(inventory_ops.is_stocked(threshold - 1))
    assert.is_true(inventory_ops.is_stocked(threshold))
    assert.is_true(inventory_ops.is_stocked(threshold + 5))
  end)

  it("wants the full visual variant only at the visual stock threshold", function()
    local threshold = constants.feeder_visual_stock_threshold
    assert.is_falsy(inventory_ops.wants_full_variant(threshold - 1))
    assert.is_true(inventory_ops.wants_full_variant(threshold))
  end)

  it("reads the nut count from a live feeder inventory", function()
    local feeder = new_feeder()
    assert.equal(0, inventory_ops.get_nut_count(feeder))

    local inventory = inventory_ops.get_inventory(feeder)
    inventory.insert({name = constants.names.nut, count = 13})
    assert.equal(13, inventory_ops.get_nut_count(feeder))
  end)

  it("snapshots and restores inventory contents round-trip", function()
    local source = new_feeder()
    local source_inventory = inventory_ops.get_inventory(source)
    source_inventory.insert({name = constants.names.nut, count = 9})

    local snapshot = inventory_ops.snapshot_contents(source_inventory)
    assert.equal(1, #snapshot)
    assert.equal(constants.names.nut, snapshot[1].name)
    assert.equal(9, snapshot[1].count)

    local target = new_feeder(constants.names.feeder_empty, {x = ORIGIN.x + 4, y = ORIGIN.y})
    local target_inventory = inventory_ops.get_inventory(target)
    inventory_ops.restore_contents(target_inventory, snapshot)
    assert.equal(9, target_inventory.get_item_count(constants.names.nut))
  end)

  it("returns an empty snapshot for a nil or invalid inventory", function()
    assert.same({}, inventory_ops.snapshot_contents(nil))
  end)
end)
