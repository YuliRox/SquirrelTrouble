-- Behavioral tests for scripts/regions/module.lua, the public regions API hub.
-- Covers the event-recording helpers (note_tree_loss / note_squirrel_death /
-- note_rough_handling / note_successful_relocation), mark_dirty, serialization
-- field mapping, and the cached vs. recomputing report accessors. These public
-- entry points are what the rest of the mod calls; milestone tests reach them
-- only through the remote interface, so the direct contract is pinned here.

local regions = require("scripts.regions.module")
local store = require("scripts.regions.store")
local constants = require("scripts.constants")

local SPAN = constants.region_tile_span
local REGION_X, REGION_Y = 30, 30
local POSITION = {
  x = (REGION_X * SPAN) + 8,
  y = (REGION_Y * SPAN) + 8
}

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

local function surface_index()
  return surface().index
end

describe("regions.module public API", function()
  before_each(function()
    storage.regions = {}
    surface().request_to_generate_chunks(POSITION, 2)
    surface().force_generate_chunk_requests()
    surface().clear_pollution()
  end)

  after_each(function()
    storage.regions = {}
    surface().clear_pollution()
  end)

  it("maps a position to a region coordinate", function()
    assert.same({x = REGION_X, y = REGION_Y}, regions.position_to_region_coord(POSITION))
  end)

  it("records a tree-loss event and marks the region dirty", function()
    local region = regions.note_tree_loss(surface_index(), POSITION, 3, 7000)

    assert.equal(1, #region.tree_loss_events)
    assert.equal(3, region.tree_loss_events[1].amount)
    assert.equal(7000, region.tree_loss_events[1].tick)
    assert.is_true(region.dirty)
  end)

  it("defaults the loss amount to one when omitted", function()
    local region = regions.note_tree_loss(surface_index(), POSITION, nil, 7000)
    assert.equal(1, region.tree_loss_events[1].amount)
  end)

  it("routes the conflict-event helpers to their distinct event buckets", function()
    regions.note_squirrel_death(surface_index(), POSITION, 1, 100)
    regions.note_rough_handling(surface_index(), POSITION, 1, 100)
    regions.note_successful_relocation(surface_index(), POSITION, 1, 100)

    local region = regions.get_region_at_position(surface(), POSITION)
    assert.equal(1, #region.squirrel_death_events)
    assert.equal(1, #region.rough_handling_events)
    assert.equal(1, #region.relocation_events)
    -- the buckets are independent: a death event does not land in tree-loss
    assert.equal(0, #region.tree_loss_events)
  end)

  it("marks a region dirty without recording any event", function()
    local region = store.get_or_create(surface_index(), REGION_X, REGION_Y)
    region.dirty = false

    local marked = regions.mark_dirty(surface_index(), POSITION)
    assert.is_true(marked.dirty)
    assert.equal(0, #marked.tree_loss_events)
  end)

  it("reports whether a region needs recompute through the public wrapper", function()
    local region = store.get_or_create(surface_index(), REGION_X, REGION_Y)
    region.dirty = false
    region.last_updated_tick = 2000

    assert.is_false(regions.needs_recompute(surface(), REGION_X, REGION_Y, 2000 + 1))
    assert.is_true(regions.needs_recompute(surface(), REGION_X, REGION_Y, 2000 + constants.region_update_interval))
  end)

  it("serializes a region into a flat report with the documented field mapping", function()
    local region = store.get_or_create(surface_index(), REGION_X, REGION_Y)
    region.forest_health = 73
    region.pollution = 4.2
    region.last_updated_tick = 9999

    local report = regions.serialize(region)

    assert.equal(REGION_X, report.region_x)
    assert.equal(73, report.forest_health)
    -- the serialized report renames region.pollution to rolling_pollution
    assert.equal(4.2, report.rolling_pollution)
    assert.equal(9999, report.last_updated_tick)
    -- window constants are surfaced for the UI
    assert.equal(constants.recent_tree_loss_window, report.recent_tree_loss_window_ticks)
    assert.equal(constants.squirrel_conflict_window, report.recent_conflict_window_ticks)
  end)

  it("returns the cached serialized report without forcing a recompute", function()
    local region = store.get_or_create(surface_index(), REGION_X, REGION_Y)
    region.dirty = false
    region.forest_health = 55
    region.last_updated_tick = 4000

    local report = regions.get_cached_region_report_by_coord(surface(), REGION_X, REGION_Y)
    assert.equal(55, report.forest_health)
    -- the stored region was not recomputed (forest_health untouched)
    assert.equal(55, store.get_or_create(surface_index(), REGION_X, REGION_Y).forest_health)
  end)

  it("recomputes when fetching a report for a dirty region", function()
    regions.note_tree_loss(surface_index(), POSITION, 1, 50)
    local report = regions.get_region_report_at_position(surface(), POSITION, 60)

    -- recompute stamps the tick and clears dirty
    assert.equal(60, report.last_updated_tick)
    assert.is_false(store.get_or_create(surface_index(), REGION_X, REGION_Y).dirty)
  end)
end)
