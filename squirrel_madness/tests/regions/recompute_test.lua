-- Behavioral tests for scripts/regions/recompute.lua. These target the caching
-- gate (region_needs_recompute / ensure_region_recomputed) and the time-windowed
-- event pruning + pollution sampling that recompute_region performs against a
-- real surface. Milestone 2 covers the seeding/feeder scoring math; here we pin
-- the staleness rules and the rolling-window bookkeeping that nothing else
-- exercises directly.

local recompute = require("scripts.regions.recompute")
local store = require("scripts.regions.store")
local constants = require("scripts.constants")

local SURFACE_INDEX = 1
local REGION_X, REGION_Y = 40, 40
local ORIGIN = {
  x = (REGION_X * constants.region_tile_span) + 4,
  y = (REGION_Y * constants.region_tile_span) + 4
}

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

describe("regions.recompute submodule", function()
  before_each(function()
    storage.regions = {}
    surface().request_to_generate_chunks(ORIGIN, 2)
    surface().force_generate_chunk_requests()
    surface().clear_pollution()
  end)

  after_each(function()
    storage.regions = {}
    surface().clear_pollution()
  end)

  it("requires recompute for a freshly created dirty region", function()
    local region = store.get_or_create(SURFACE_INDEX, REGION_X, REGION_Y)
    assert.is_true(recompute.region_needs_recompute(region, 100))
  end)

  it("requires recompute when last_updated_tick is unset or non-positive", function()
    local region = store.get_or_create(SURFACE_INDEX, REGION_X, REGION_Y)
    region.dirty = false
    region.last_updated_tick = 0
    assert.is_true(recompute.region_needs_recompute(region, 100))
  end)

  it("skips recompute inside the update interval and forces it once stale", function()
    local region = store.get_or_create(SURFACE_INDEX, REGION_X, REGION_Y)
    region.dirty = false
    region.last_updated_tick = 1000

    -- still fresh: just before the interval elapses
    assert.is_false(recompute.region_needs_recompute(region, 1000 + constants.region_update_interval - 1))
    -- exactly at the interval it goes stale
    assert.is_true(recompute.region_needs_recompute(region, 1000 + constants.region_update_interval))
  end)

  it("recomputes and clears the dirty flag, stamping the update tick", function()
    local region = recompute.recompute_region(surface(), REGION_X, REGION_Y, 5000)
    assert.is_false(region.dirty)
    assert.equal(5000, region.last_updated_tick)
    assert.is_string(region.forest_health_band)
  end)

  it("ensure_region_recomputed returns the cached region without recomputing when fresh", function()
    local first = recompute.recompute_region(surface(), REGION_X, REGION_Y, 5000)
    first.tree_count = 999

    -- a tick within the interval keeps the (stale-but-fresh) cached values
    local cached = recompute.ensure_region_recomputed(surface(), REGION_X, REGION_Y, 5001)
    assert.equal(999, cached.tree_count)
    assert.equal(5000, cached.last_updated_tick)
  end)

  it("ensure_region_recomputed recomputes when the cache is stale", function()
    local first = recompute.recompute_region(surface(), REGION_X, REGION_Y, 5000)
    first.tree_count = 999

    local refreshed = recompute.ensure_region_recomputed(
      surface(),
      REGION_X,
      REGION_Y,
      5000 + constants.region_update_interval
    )
    -- the empty region has no real trees, so the recompute overwrites the poke
    assert.equal(0, refreshed.tree_count)
    assert.equal(5000 + constants.region_update_interval, refreshed.last_updated_tick)
  end)

  it("drops tree-loss events older than the recent window during recompute", function()
    local region = store.get_or_create(SURFACE_INDEX, REGION_X, REGION_Y)
    local window = constants.recent_tree_loss_window
    local now = window + 10000

    -- one event inside the window, one far outside it
    region.tree_loss_events = {
      {tick = now - (window - 1), amount = 2},
      {tick = now - (window + 1), amount = 5}
    }

    recompute.recompute_region(surface(), REGION_X, REGION_Y, now)

    assert.equal(1, #region.tree_loss_events)
    assert.equal(2, region.recent_tree_loss)
  end)

  it("caps the rolling pollution sample buffer at the configured limit", function()
    local region = store.get_or_create(SURFACE_INDEX, REGION_X, REGION_Y)
    local limit = constants.pollution_sample_limit

    for tick = 1, limit + 5 do
      region.dirty = true
      recompute.recompute_region(surface(), REGION_X, REGION_Y, tick)
    end

    assert.equal(limit, #region.pollution_samples)
  end)
end)
