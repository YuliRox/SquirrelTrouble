-- Behavioral tests for scripts/habitat/world.lua. These are pure world/geometry
-- helpers with no storage dependency. clone_position must return a copy (the
-- lifecycle code relies on storing detached position copies), positions_equal /
-- chunk_key / chunk_area back the tracked-entry bookkeeping, and
-- is_supported_surface gates every habitat mutation to the primary surface.

local world = require("scripts.habitat.world")
local constants = require("scripts.constants")

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

describe("habitat.world submodule", function()
  it("clones a position into a detached copy", function()
    local source = {x = 5, y = 9}
    local copy = world.clone_position(source)

    assert.same({x = 5, y = 9}, copy)
    assert.is_not.equal(source, copy)

    copy.x = 100
    assert.equal(5, source.x)
  end)

  it("compares positions by value", function()
    assert.is_true(world.positions_equal({x = 1, y = 2}, {x = 1, y = 2}))
    assert.is_falsy(world.positions_equal({x = 1, y = 2}, {x = 1, y = 3}))
    assert.is_falsy(world.positions_equal({x = 0, y = 2}, {x = 1, y = 2}))
  end)

  it("builds a stable string key from a chunk position", function()
    assert.equal("3,-4", world.chunk_key({x = 3, y = -4}))
  end)

  it("computes the tile bounding box for a chunk", function()
    local area = world.chunk_area({x = 2, y = -1})
    assert.equal(2 * constants.chunk_size, area.left_top.x)
    assert.equal(-1 * constants.chunk_size, area.left_top.y)
    assert.equal((2 * constants.chunk_size) + constants.chunk_size, area.right_bottom.x)
    assert.equal((-1 * constants.chunk_size) + constants.chunk_size, area.right_bottom.y)
  end)

  it("treats only the primary surface as supported", function()
    assert.is_true(world.is_supported_surface(surface()))
    assert.is_falsy(world.is_supported_surface(nil))
    assert.is_falsy(world.is_supported_surface({valid = true, name = "some-other-surface"}))
  end)
end)
