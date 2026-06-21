-- Behavioral tests for scripts/regions/store.lua. Geometry helpers are pure, but
-- get_surface_regions / get_or_create / default_region read and write
-- storage.regions, so storage.regions is reset around each test. These exercise
-- the region-shape defaults and the get_or_create caching that the recompute and
-- module layers depend on.

local store = require("scripts.regions.store")
local constants = require("scripts.constants")

local SURFACE_INDEX = 1
local SPAN = constants.region_tile_span

describe("regions.store submodule", function()
  before_each(function()
    storage.regions = {}
  end)

  after_each(function()
    storage.regions = {}
  end)

  it("maps tile positions to region coordinates with floor on negatives", function()
    assert.same({x = 0, y = 0}, store.position_to_region_coord({x = 0, y = 0}))
    assert.same({x = 1, y = 2}, store.position_to_region_coord({x = SPAN, y = SPAN * 2}))
    -- a position one tile inside the span still maps to region 0
    assert.same({x = 0, y = 0}, store.position_to_region_coord({x = SPAN - 1, y = SPAN - 1}))
    -- negatives floor toward minus infinity, not toward zero
    assert.same({x = -1, y = -1}, store.position_to_region_coord({x = -1, y = -1}))
  end)

  it("computes the tile bounding box for a region", function()
    local area = store.region_area(2, 3)
    assert.equal(2 * SPAN, area.left_top.x)
    assert.equal(3 * SPAN, area.left_top.y)
    assert.equal((2 * SPAN) + SPAN, area.right_bottom.x)
    assert.equal((3 * SPAN) + SPAN, area.right_bottom.y)
  end)

  it("detects circle intersection inside, on the edge and outside a region", function()
    -- region 0 covers tiles [0, SPAN). A circle centered well inside intersects.
    assert.is_true(store.region_intersects_circle(0, 0, {x = SPAN / 2, y = SPAN / 2}, 1))
    -- a point just left of region 0 with a radius reaching its edge intersects
    assert.is_true(store.region_intersects_circle(0, 0, {x = -2, y = SPAN / 2}, 2))
    -- a far-away small circle does not intersect
    assert.is_falsy(store.region_intersects_circle(0, 0, {x = -100, y = -100}, 5))
  end)

  it("derives forest mass and cluster weight with a minimum-weight floor", function()
    local region = {tree_count = 4, sapling_count = 3}
    assert.equal(7, store.region_forest_mass(region))
    assert.equal(7, store.region_cluster_weight(region))

    local empty = {tree_count = 0, sapling_count = 0}
    assert.equal(0, store.region_forest_mass(empty))
    -- weight floors at 1 even with no forest mass
    assert.equal(1, store.region_cluster_weight(empty))
  end)

  it("treats a region as a cluster candidate only at the minimum tree count", function()
    local threshold = constants.survey_cluster_min_tree_count
    assert.is_falsy(store.region_is_cluster_candidate({tree_count = threshold - 1, sapling_count = 0}))
    assert.is_true(store.region_is_cluster_candidate({tree_count = threshold, sapling_count = 0}))
    -- saplings count toward forest mass for candidacy
    assert.is_true(store.region_is_cluster_candidate({tree_count = 0, sapling_count = threshold}))
  end)

  it("fills in missing region fields with stable defaults", function()
    local region = store.ensure_region_shape({}, SURFACE_INDEX, 5, 6)

    assert.equal(SURFACE_INDEX, region.surface_index)
    assert.equal(5, region.region_x)
    assert.equal(6, region.region_y)
    assert.equal(0, region.forest_health)
    assert.equal(0, region.tree_count)
    assert.equal("collapsed", region.forest_health_band)
    assert.equal("calm", region.squirrel_unrest_band)
    assert.equal("light", region.habitat_pressure_band)
    -- a fresh region without an explicit dirty flag defaults to dirty
    assert.is_true(region.dirty)
    assert.same({}, region.tree_loss_events)
    assert.same({}, region.drivers)
  end)

  it("preserves an explicit non-dirty flag through ensure_region_shape", function()
    local region = store.ensure_region_shape({dirty = false}, SURFACE_INDEX, 0, 0)
    assert.is_false(region.dirty)
  end)

  it("creates and then caches the same region table for repeated coordinates", function()
    local first = store.get_or_create(SURFACE_INDEX, 9, 9)
    first.tree_count = 17

    local second = store.get_or_create(SURFACE_INDEX, 9, 9)

    assert.equal(first, second)
    assert.equal(17, second.tree_count)
    -- a different coordinate yields a distinct table
    assert.is_not.equal(first, store.get_or_create(SURFACE_INDEX, 9, 10))
  end)

  it("lazily initializes the per-surface region table", function()
    assert.is_nil(storage.regions[SURFACE_INDEX])
    local surface_regions = store.get_surface_regions(SURFACE_INDEX)
    assert.is_not_nil(surface_regions)
    assert.equal(surface_regions, storage.regions[SURFACE_INDEX])
  end)
end)
