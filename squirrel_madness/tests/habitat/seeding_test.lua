-- Behavioral tests for scripts/habitat/seeding.lua, targeting the guard and
-- once-only edges. Milestone 2 covers the spread-selection counts and starting
-- grove against real forests; here we pin the unsupported-surface guard, the
-- empty-candidate fast path, and the seeded-chunk dedupe key bookkeeping.

local seeding = require("scripts.habitat.seeding")
local constants = require("scripts.constants")

local ORIGIN = {x = 1500, y = 1500}
local TREE_NAME = "tree-01"
local spawned

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

local function area_around(center, radius)
  return {
    left_top = {x = center.x - radius, y = center.y - radius},
    right_bottom = {x = center.x + radius, y = center.y + radius}
  }
end

describe("habitat.seeding submodule", function()
  before_each(function()
    spawned = {}
    storage.seeded_chunks = {}
    storage.regions = {}
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
      area = area_around(ORIGIN, 80),
      name = {constants.names.nut_tree}
    })) do
      if entity.valid then
        entity.destroy()
      end
    end
    spawned = {}
    storage.seeded_chunks = {}
    storage.regions = {}
  end)

  local function spawn_trees(count, origin)
    for index = 1, count do
      local entity = surface().create_entity({
        name = TREE_NAME,
        position = {
          x = origin.x + (((index - 1) % 6) * 3),
          y = origin.y + (math.floor((index - 1) / 6) * 3)
        }
      })
      if entity then
        spawned[#spawned + 1] = entity
      end
    end
  end

  it("refuses to seed on an unsupported surface", function()
    local fake_surface = {valid = true, name = "elsewhere"}
    assert.equal(0, seeding.seed_nut_trees_in_area(fake_surface, area_around(ORIGIN, 24), 3, true))
  end)

  it("returns zero when the area holds no convertible trees", function()
    local empty_area = area_around({x = ORIGIN.x + 200, y = ORIGIN.y + 200}, 16)
    assert.equal(0, seeding.seed_nut_trees_in_area(surface(), empty_area, 3, true))
  end)

  it("converts an explicit count of regular trees into nut trees", function()
    spawn_trees(6, ORIGIN)
    local seeded = seeding.seed_nut_trees_in_area(surface(), area_around(ORIGIN, 32), 2, true)

    assert.equal(2, seeded)
    assert.equal(2, surface().count_entities_filtered({
      area = area_around(ORIGIN, 32),
      name = constants.names.nut_tree
    }))
  end)

  it("marks a chunk seeded even when sparse forest yields no nut trees", function()
    local chunk_position = {x = 47, y = 47}
    local area = {
      left_top = {x = chunk_position.x * constants.chunk_size, y = chunk_position.y * constants.chunk_size},
      right_bottom = {
        x = (chunk_position.x + 1) * constants.chunk_size,
        y = (chunk_position.y + 1) * constants.chunk_size
      }
    }
    -- below nut_tree_seed_min_regular_trees and not allow_sparse_patch
    spawn_trees(4, {x = area.left_top.x + 2, y = area.left_top.y + 2})

    local seeded = seeding.seed_chunk(surface(), chunk_position, area)

    assert.equal(0, seeded)
    -- the chunk is still flagged so it is not retried
    assert.is_true(storage.seeded_chunks[surface().index]["47,47"])
  end)
end)
