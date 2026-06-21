-- Behavioral tests for scripts/habitat/lifecycle.lua, targeting edges milestone 2
-- does not isolate: harvest_nut_tree scheduling, resolve_pending_replacements
-- with mixed due/not-due entries and its empty-list fast path, surface-scoped
-- maturation, and the per-surface filtering of force_mature_all_saplings.

local lifecycle = require("scripts.habitat.lifecycle")
local constants = require("scripts.constants")

-- Origin placed well clear of milestone tests and the other package tests.
local ORIGIN = {x = 1400, y = 1400}
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

local function reset_lifecycle_storage()
  storage.saplings = {}
  storage.next_sapling_id = 1
  storage.harvested_nut_trees = {}
  storage.next_harvested_nut_tree_id = 1
  storage.pending_entity_replacements = {}
  storage.regions = {}
end

local function cleanup_lifecycle_entities()
  for _, entity in ipairs(surface().find_entities_filtered({
    area = {{ORIGIN.x - 64, ORIGIN.y - 64}, {ORIGIN.x + 64, ORIGIN.y + 64}},
    name = {
      constants.names.nut_tree,
      constants.names.nut_tree_harvested,
      constants.names.nut_sapling
    }
  })) do
    if entity.valid then
      entity.destroy()
    end
  end
end

describe("habitat.lifecycle submodule", function()
  before_each(function()
    spawned = {}
    reset_lifecycle_storage()
    surface().request_to_generate_chunks(ORIGIN, 2)
    surface().force_generate_chunk_requests()
    cleanup_lifecycle_entities()
  end)

  after_each(function()
    for _, entity in ipairs(spawned or {}) do
      if entity and entity.valid then
        entity.destroy()
      end
    end
    cleanup_lifecycle_entities()
    reset_lifecycle_storage()
  end)

  local function new_entity(name, position)
    local entity = surface().create_entity({
      name = name,
      position = position or ORIGIN,
      force = "neutral"
    })
    assert.is_not_nil(entity)
    spawned[#spawned + 1] = entity
    return entity
  end

  it("resolve_pending_replacements is a no-op when nothing is pending", function()
    assert.equal(0, lifecycle.resolve_pending_replacements(game.tick + 10, surface().index))
  end)

  it("schedules a harvested-tree replacement and reports success without removing the tree", function()
    local position = {x = ORIGIN.x, y = ORIGIN.y}
    local nut_tree = new_entity(constants.names.nut_tree, position)

    local ok = lifecycle.harvest_nut_tree(nut_tree, 500)

    assert.is_true(ok)
    assert.equal(1, #storage.pending_entity_replacements)
    local scheduled = storage.pending_entity_replacements[1]
    assert.equal(constants.names.nut_tree_harvested, scheduled.name)
    assert.equal(501, scheduled.due_tick)
    -- NOTE: harvest_nut_tree does not destroy the original entity. In runtime it
    -- is driven from the mining event, which removes the tree; called directly the
    -- original nut tree remains standing. Documented edge, asserted as-is.
    assert.is_true(nut_tree.valid)
  end)

  it("harvest_nut_tree rejects non-nut-tree entities", function()
    local sapling = new_entity(constants.names.nut_sapling, ORIGIN)
    assert.is_false(lifecycle.harvest_nut_tree(sapling, 500))
    assert.equal(0, #storage.pending_entity_replacements)
  end)

  it("only resolves replacements whose due tick has arrived", function()
    local due_position = {x = ORIGIN.x, y = ORIGIN.y}
    local future_position = {x = ORIGIN.x + 8, y = ORIGIN.y}

    storage.pending_entity_replacements = {
      {surface_index = surface().index, position = due_position, name = constants.names.nut_tree, due_tick = 100},
      {surface_index = surface().index, position = future_position, name = constants.names.nut_tree, due_tick = 10000}
    }

    local created = lifecycle.resolve_pending_replacements(200, surface().index)

    assert.equal(1, created)
    -- the not-yet-due replacement is retained for later
    assert.equal(1, #storage.pending_entity_replacements)
    assert.equal(10000, storage.pending_entity_replacements[1].due_tick)

    local created_tree = surface().find_entities_filtered({
      position = due_position,
      name = constants.names.nut_tree,
      limit = 1
    })[1]
    assert.is_not_nil(created_tree)
    spawned[#spawned + 1] = created_tree
  end)

  it("re-registers a harvested nut tree when its scheduled replacement resolves", function()
    local position = {x = ORIGIN.x, y = ORIGIN.y}
    storage.pending_entity_replacements = {
      {
        surface_index = surface().index,
        position = position,
        name = constants.names.nut_tree_harvested,
        due_tick = 100
      }
    }

    local created = lifecycle.resolve_pending_replacements(200, surface().index)

    assert.equal(1, created)
    -- resolving a harvested-tree replacement re-enters the regrowth tracker
    assert.equal(1, count(storage.harvested_nut_trees))

    local harvested = surface().find_entities_filtered({
      position = position,
      name = constants.names.nut_tree_harvested,
      limit = 1
    })[1]
    assert.is_not_nil(harvested)
    spawned[#spawned + 1] = harvested
  end)

  it("registers a sapling with the configured maturation delay", function()
    local sapling = new_entity(constants.names.nut_sapling, ORIGIN)
    local record = lifecycle.register_sapling(sapling, 1000)

    assert.is_not_nil(record)
    assert.equal(1000 + constants.nut_sapling_growth_time, record.mature_tick)
    assert.equal(1, count(storage.saplings))
  end)

  it("only matures saplings that are due", function()
    local sapling = new_entity(constants.names.nut_sapling, ORIGIN)
    lifecycle.register_sapling(sapling, 1000)

    -- before the maturation tick: nothing matures
    assert.equal(0, lifecycle.mature_ready_saplings(1000, surface().index))
    assert.equal(1, count(storage.saplings))

    -- forcing the maturation tick to now matures it into a nut tree
    assert.equal(1, lifecycle.force_mature_all_saplings(2000, surface().index))
    assert.equal(0, count(storage.saplings))

    local matured = surface().find_entities_filtered({
      position = ORIGIN,
      name = constants.names.nut_tree,
      limit = 1
    })[1]
    assert.is_not_nil(matured)
    spawned[#spawned + 1] = matured
  end)

  it("force_mature_all_saplings ignores saplings on other surfaces", function()
    local sapling = new_entity(constants.names.nut_sapling, ORIGIN)
    lifecycle.register_sapling(sapling, 1000)

    -- a non-matching surface index leaves the sapling untouched
    local other_surface = surface().index + 99
    assert.equal(0, lifecycle.force_mature_all_saplings(99999, other_surface))
    assert.equal(1, count(storage.saplings))
  end)
end)
