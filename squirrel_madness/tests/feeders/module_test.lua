-- Behavioral tests for scripts/feeders/module.lua, targeting the tracking
-- bookkeeping edges that milestone 2 (which covers the visual variant swap and
-- region scoring) does not: register/unregister contracts, rebuild_tracking
-- stale-record pruning, and sync_registered's stale-record removal plus its
-- unit_number re-keying when an entity is replaced underneath a record.

local feeders = require("scripts.feeders.module")
local regions = require("scripts.regions.module")
local constants = require("scripts.constants")

local ORIGIN = {x = 1200, y = 1200}
local spawned

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

local function count(entries)
  local total = 0
  for _ in pairs(entries or {}) do
    total = total + 1
  end
  return total
end

describe("feeders.module tracking", function()
  before_each(function()
    storage.feeders = {}
    storage.regions = {}
    spawned = {}
    surface().request_to_generate_chunks(ORIGIN, 2)
    surface().force_generate_chunk_requests()
  end)

  after_each(function()
    for _, entity in ipairs(spawned or {}) do
      if entity and entity.valid then
        entity.destroy()
      end
    end
    for _, entity in ipairs(surface().find_entities_filtered({
      area = {{ORIGIN.x - 64, ORIGIN.y - 64}, {ORIGIN.x + 64, ORIGIN.y + 64}},
      name = constants.feeder_entity_names
    })) do
      if entity.valid then
        entity.destroy()
      end
    end
    storage.feeders = {}
    storage.regions = {}
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

  it("identifies feeder entities and rejects non-feeders", function()
    local feeder = new_feeder()
    assert.is_true(feeders.is_feeder_entity(feeder))
    assert.is_falsy(feeders.is_feeder_entity(nil))
  end)

  it("registers a feeder record keyed by unit_number", function()
    local feeder = new_feeder()
    local record = feeders.register(feeder)

    assert.is_not_nil(record)
    assert.equal(surface().index, record.surface_index)
    assert.is_false(record.stocked)
    assert.is_not_nil(storage.feeders[feeder.unit_number])
  end)

  it("marks the record stocked when registered above the threshold", function()
    local feeder = new_feeder()
    feeder.get_inventory(defines.inventory.chest).insert({
      name = constants.names.nut,
      count = constants.stocked_feeder_threshold
    })
    local record = feeders.register(feeder)
    assert.is_true(record.stocked)
  end)

  it("unregisters by entity and by raw unit_number", function()
    local first = new_feeder()
    local first_unit = first.unit_number
    feeders.register(first)
    feeders.unregister(first)
    assert.is_nil(storage.feeders[first_unit])

    local second = new_feeder(constants.names.feeder_empty, {x = ORIGIN.x + 4, y = ORIGIN.y})
    local second_unit = second.unit_number
    feeders.register(second)
    feeders.unregister(second_unit)
    assert.is_nil(storage.feeders[second_unit])
  end)

  it("rebuild_tracking drops stale records and re-registers live feeders", function()
    local feeder = new_feeder()
    feeders.register(feeder)
    -- a stale record for an entity that no longer exists
    storage.feeders[999999] = {surface_index = surface().index, position = {x = 0, y = 0}}

    feeders.rebuild_tracking(surface().index)

    assert.is_nil(storage.feeders[999999])
    assert.is_not_nil(storage.feeders[feeder.unit_number])
    assert.equal(1, count(storage.feeders))
  end)

  it("rebuild_tracking only touches the requested surface's records", function()
    local feeder = new_feeder()
    feeders.register(feeder)
    -- a record on a different (non-matching) surface index must survive
    storage.feeders[888888] = {surface_index = surface().index + 50, position = {x = 0, y = 0}}

    feeders.rebuild_tracking(surface().index)

    assert.is_not_nil(storage.feeders[888888])
    assert.is_not_nil(storage.feeders[feeder.unit_number])
  end)

  it("sync_registered removes records whose entity has disappeared", function()
    local feeder = new_feeder()
    local unit = feeder.unit_number
    feeders.register(feeder)
    feeder.destroy()

    local changed = feeders.sync_registered(surface().index)

    assert.equal(0, changed)
    assert.is_nil(storage.feeders[unit])
  end)

  it("sync_registered re-keys a record when the variant swap changes the unit_number", function()
    -- start empty and registered, then stock it so sync replaces the entity with
    -- the full variant (a new unit_number) and re-homes the record.
    local feeder = new_feeder(constants.names.feeder_empty)
    local original_unit = feeder.unit_number
    feeders.register(feeder)
    feeder.get_inventory(defines.inventory.chest).insert({name = constants.names.nut, count = 1})

    local changed = feeders.sync_registered(surface().index)

    assert.equal(1, changed)
    -- the original key is gone; a single record remains under the new entity
    assert.is_nil(storage.feeders[original_unit])
    assert.equal(1, count(storage.feeders))

    local swapped = surface().find_entities_filtered({
      area = {{ORIGIN.x - 0.2, ORIGIN.y - 0.2}, {ORIGIN.x + 0.2, ORIGIN.y + 0.2}},
      name = constants.feeder_entity_names,
      limit = 1
    })[1]
    assert.is_not_nil(swapped)
    assert.equal(constants.names.feeder, swapped.name)
    assert.is_not_nil(storage.feeders[swapped.unit_number])
  end)
end)
