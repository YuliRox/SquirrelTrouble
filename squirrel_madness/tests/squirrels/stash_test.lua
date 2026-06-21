-- Behavioral tests for scripts/squirrels/stash.lua. Installs the submodule with
-- a resolve_entity_reference stub and exercises the real stash bookkeeping
-- against live stash entities, inventories and storage so the ongoing
-- decomposition of the squirrel runtime cannot silently change stash behavior.

local constants = require("scripts.constants")
local stash_module = require("scripts.squirrels.stash")

local REGION_X, REGION_Y = 5, 5
local ORIGIN = {x = 300, y = 300}

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

local function reset_stash_storage()
  storage.squirrel_stashes = {}
  storage.squirrel_stashes_by_region = {}
  storage.squirrel_stash_target_counts = {}
  storage.next_squirrel_stash_id = 1
end

local function destroy_test_stashes()
  for _, entity in ipairs(surface().find_entities_filtered({name = constants.names.stash})) do
    if entity.valid then
      entity.destroy()
    end
  end
end

describe("squirrels.stash submodule", function()
  local stash

  before_each(function()
    reset_stash_storage()
    -- ensure_stash places via can_place_entity / find_non_colliding_position,
    -- which require generated chunks around the stash origin.
    surface().request_to_generate_chunks(ORIGIN, 1)
    surface().force_generate_chunk_requests()
    destroy_test_stashes()
    stash = stash_module.install({
      resolve_entity_reference = function(reference)
        return reference
      end
    })
  end)

  after_each(function()
    destroy_test_stashes()
    reset_stash_storage()
  end)

  local function new_stash_entity(position)
    local entity = surface().create_entity({
      name = constants.names.stash,
      position = position or ORIGIN,
      force = "neutral"
    })
    assert.is_not_nil(entity)
    return entity
  end

  it("registers a stash and lists it for its region", function()
    local entity = new_stash_entity()
    local stash_id = stash.register_stash(entity, REGION_X, REGION_Y)

    assert.is_number(stash_id)
    local matches = stash.available_region_stashes(surface().index, REGION_X, REGION_Y)
    assert.equal(1, #matches)
    assert.equal(stash_id, matches[1].stash_id)
  end)

  it("tracks stash target counts as records claim and release stashes", function()
    local record = {}
    stash.set_record_stash(record, 7)
    assert.equal(7, record.stash_id)
    assert.equal(1, storage.squirrel_stash_target_counts[7])

    stash.set_record_stash(record, 9)
    assert.equal(9, record.stash_id)
    assert.is_nil(storage.squirrel_stash_target_counts[7])
    assert.equal(1, storage.squirrel_stash_target_counts[9])

    stash.set_record_stash(record, nil)
    assert.is_nil(record.stash_id)
    assert.is_nil(storage.squirrel_stash_target_counts[9])
  end)

  it("creates a new stash when a squirrel has none in range", function()
    local record = {
      surface_index = surface().index,
      region_x = REGION_X,
      region_y = REGION_Y,
      home_position = ORIGIN
    }

    local entity = stash.ensure_stash(record, {name = constants.names.nut, count = 1}, ORIGIN)

    assert.is_not_nil(entity)
    assert.equal(constants.names.stash, entity.name)
    assert.is_number(record.stash_id)
    assert.equal(1, #stash.available_region_stashes(surface().index, REGION_X, REGION_Y))
  end)

  it("reuses an existing acceptable stash in the region", function()
    local existing = new_stash_entity()
    local existing_id = stash.register_stash(existing, REGION_X, REGION_Y)
    local record = {
      surface_index = surface().index,
      region_x = REGION_X,
      region_y = REGION_Y,
      home_position = ORIGIN
    }

    local entity = stash.ensure_stash(record, {name = constants.names.nut, count = 1}, ORIGIN)

    assert.equal(existing.unit_number, entity.unit_number)
    assert.equal(existing_id, record.stash_id)
  end)

  it("reports whether a stash can accept an item stack", function()
    local entity = new_stash_entity()
    local stack = {name = constants.names.nut, count = 1}

    assert.is_true(stash.stash_can_accept(entity, stack))

    local inventory = entity.get_inventory(defines.inventory.chest)
    inventory.set_bar(1)
    assert.is_falsy(stash.stash_can_accept(entity, stack))
  end)

  it("totals the items held in an inventory", function()
    local entity = new_stash_entity()
    local inventory = entity.get_inventory(defines.inventory.chest)
    inventory.insert({name = constants.names.nut, count = 12})

    assert.equal(12, stash.inventory_total_count(inventory))
  end)

  it("destroys empty untargeted stashes and prunes stale references", function()
    local empty = new_stash_entity({x = ORIGIN.x, y = ORIGIN.y})
    local empty_id = stash.register_stash(empty, REGION_X, REGION_Y)

    local stocked = new_stash_entity({x = ORIGIN.x + 4, y = ORIGIN.y})
    local stocked_id = stash.register_stash(stocked, REGION_X, REGION_Y)
    stocked.get_inventory(defines.inventory.chest).insert({name = constants.names.nut, count = 3})

    local destroyed = stash.cleanup_empty_stashes(surface().index)

    assert.equal(1, destroyed)
    assert.is_nil(storage.squirrel_stashes[surface().index][empty_id])
    assert.is_not_nil(storage.squirrel_stashes[surface().index][stocked_id])
  end)
end)
