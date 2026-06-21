-- Behavioral tests for scripts/squirrels/state.lua. Exercises the real region
-- activity bookkeeping and the state-classification thresholds against live
-- region reports so decomposition cannot silently change squirrel mood logic.

local state_ops = require("scripts.squirrels.state")
local constants = require("scripts.constants")

local SURFACE_INDEX = 1
local REGION_X, REGION_Y = 41, 41
local ORIGIN = {
  x = (REGION_X * constants.region_tile_span) + 4,
  y = (REGION_Y * constants.region_tile_span) + 4
}

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

describe("squirrels.state submodule", function()
  before_each(function()
    storage.squirrel_region_activity = {}
    storage.regions = {}
    surface().request_to_generate_chunks(ORIGIN, 2)
    surface().force_generate_chunk_requests()
    surface().clear_pollution()
  end)

  after_each(function()
    storage.squirrel_region_activity = {}
    storage.regions = {}
    surface().clear_pollution()
  end)

  it("lazily creates a region activity record with zeroed timers", function()
    local activity = state_ops.get_region_activity(SURFACE_INDEX, REGION_X, REGION_Y)
    assert.equal(0, activity.last_theft_tick)
    assert.equal(0, activity.grief_until_tick)
    assert.equal(0, activity.last_spawn_tick)
  end)

  it("returns the same mutable record on subsequent calls", function()
    local first = state_ops.get_region_activity(SURFACE_INDEX, REGION_X, REGION_Y)
    first.last_theft_tick = 123
    local second = state_ops.get_region_activity(SURFACE_INDEX, REGION_X, REGION_Y)
    assert.equal(123, second.last_theft_tick)
  end)

  it("returns nil for a missing surface", function()
    assert.is_nil(state_ops.region_report(9999, REGION_X, REGION_Y, 100, true))
  end)

  local VALID_STATES = {
    calm = true,
    curious = true,
    mischievous = true,
    agitated = true,
    grieving = true
  }

  it("classifies a forced-recompute region into a valid state with a report", function()
    local state, report = state_ops.squirrel_state_for_region(SURFACE_INDEX, REGION_X, REGION_Y, 100, true)
    assert.is_not_nil(report)
    assert.is_true(VALID_STATES[state] == true)
  end)

  it("prioritizes grieving while the grief timer is in the future", function()
    state_ops.get_region_activity(SURFACE_INDEX, REGION_X, REGION_Y).grief_until_tick = 500

    local state, report = state_ops.squirrel_state_for_region(SURFACE_INDEX, REGION_X, REGION_Y, 100, true)
    assert.is_not_nil(report)
    assert.equal("grieving", state)
  end)

  it("clears to a non-grieving state once the grief timer has passed", function()
    state_ops.get_region_activity(SURFACE_INDEX, REGION_X, REGION_Y).grief_until_tick = 50

    local state = state_ops.squirrel_state_for_region(SURFACE_INDEX, REGION_X, REGION_Y, 100, true)
    assert.not_equal("grieving", state)
  end)
end)
