-- Behavioral tests for scripts/squirrels/population.lua. Installs the submodule
-- with controllable stubs for the hub callbacks and exercises the spawn-site
-- helpers, region counting and culling against live entities, trees and
-- storage. The ensure_population_in_region / seed_chunk_population manager paths
-- are covered end-to-end by the milestone seeding/tick suites.

local constants = require("scripts.constants")
local regions = require("scripts.regions.module")
local storage_ops = require("scripts.squirrels.storage")
local population_module = require("scripts.squirrels.population")

local AREA = {x = 300, y = 300}
local TREE_NAME = "tree-01"

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

local function reset_population_storage()
  storage.squirrels = {}
  storage.next_squirrel_id = 1
  storage.squirrel_region_index = {}
  storage.squirrel_stashes = {}
end

describe("squirrels.population submodule", function()
  local population
  local removed_ids
  local spawned_trees
  local cull_entities

  local function install_population(overrides)
    local deps = {
      create_record = function() end,
      process_idle_decision = function() end,
      ensure_squirrel_force = function() return game.forces.player end,
      region_report = function() return nil end,
      chunk_area = function() return nil end,
      resolve_entity_reference = function(reference) return reference end,
      remove_record = function(squirrel_id)
        removed_ids[squirrel_id] = true
        storage.squirrels[squirrel_id] = nil
      end,
      deposit_or_spill = function() return true end,
      clear_carrying = function() end
    }
    for key, value in pairs(overrides or {}) do
      deps[key] = value
    end
    return population_module.install(deps)
  end

  before_each(function()
    reset_population_storage()
    removed_ids = {}
    spawned_trees = {}
    cull_entities = {}
    surface().request_to_generate_chunks(AREA, 1)
    surface().force_generate_chunk_requests()
    population = install_population()
  end)

  after_each(function()
    for _, tree in ipairs(spawned_trees) do
      if tree and tree.valid then
        tree.destroy()
      end
    end
    for _, entity in ipairs(cull_entities) do
      if entity and entity.valid then
        entity.destroy()
      end
    end
    reset_population_storage()
  end)

  it("finds a spawnable position near a clear anchor", function()
    local position = population.spawn_position_near_anchor(surface(), AREA, 8, game.forces.player, nil)

    assert.is_not_nil(position)
    assert.is_number(position.x)
    assert.is_number(position.y)
  end)

  it("places a spawn near forest trees in a region", function()
    for index = 1, 6 do
      local tree = surface().create_entity({
        name = TREE_NAME,
        position = {x = AREA.x + (index * 2), y = AREA.y}
      })
      spawned_trees[#spawned_trees + 1] = tree
    end

    local coord = regions.position_to_region_coord(AREA)
    local position = population.eligible_spawn_position(surface(), coord.x, coord.y, 0, game.forces.player)

    assert.is_not_nil(position)
  end)

  it("counts squirrels recorded in a region index entry", function()
    local entry = storage_ops.get_region_squirrel_entry(surface().index, 9, 9)
    entry.count = 3

    assert.equal(3, population.count_region_squirrels(surface().index, 9, 9))
  end)

  it("culls squirrels in regions that are not active", function()
    local entity = surface().create_entity({
      name = "wooden-chest",
      position = {x = AREA.x + 5, y = AREA.y + 5},
      force = "neutral"
    })
    cull_entities[#cull_entities + 1] = entity
    storage.squirrels[1] = {entity = entity, surface_index = surface().index, carrying = nil}

    local entry = storage_ops.get_region_squirrel_entry(surface().index, 9, 9)
    entry.ids = {[1] = true}
    entry.count = 1

    population.cull_inactive_squirrels({})

    assert.is_true(removed_ids[1])
    assert.is_false(entity.valid)
  end)

  it("keeps squirrels whose region is in the active set", function()
    local entity = surface().create_entity({
      name = "wooden-chest",
      position = {x = AREA.x + 6, y = AREA.y + 6},
      force = "neutral"
    })
    cull_entities[#cull_entities + 1] = entity
    storage.squirrels[1] = {entity = entity, surface_index = surface().index, carrying = nil}

    local entry = storage_ops.get_region_squirrel_entry(surface().index, 9, 9)
    entry.ids = {[1] = true}
    entry.count = 1

    local active_lookup = {[storage_ops.active_region_key(surface().index, 9, 9)] = true}
    population.cull_inactive_squirrels(active_lookup)

    assert.is_nil(removed_ids[1])
    assert.is_true(entity.valid)
  end)
end)
