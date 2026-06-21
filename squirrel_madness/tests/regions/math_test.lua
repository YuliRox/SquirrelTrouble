-- Behavioral tests for scripts/regions/math.lua. These are pure helpers with no
-- game/storage dependencies, so the functions are exercised directly. The band
-- functions are the operational classifiers the region reports key off, so the
-- exact threshold boundaries are pinned here.

local math_ops = require("scripts.regions.math")
local constants = require("scripts.constants")

describe("regions.math submodule", function()
  it("clamps below, above and within the range", function()
    assert.equal(0, math_ops.clamp(-5, 0, 100))
    assert.equal(100, math_ops.clamp(250, 0, 100))
    assert.equal(42, math_ops.clamp(42, 0, 100))
    assert.equal(0, math_ops.clamp(0, 0, 100))
    assert.equal(100, math_ops.clamp(100, 0, 100))
  end)

  it("rounds to the nearest integer at the half boundary", function()
    assert.equal(3, math_ops.round(2.5))
    assert.equal(2, math_ops.round(2.4))
    assert.equal(3, math_ops.round(2.6))
    assert.equal(0, math_ops.round(0))
  end)

  it("rounds to a single decimal place", function()
    assert.equal(2.5, math_ops.round_tenths(2.46))
    assert.equal(2.5, math_ops.round_tenths(2.54))
    assert.equal(0, math_ops.round_tenths(0.04))
    assert.equal(0.1, math_ops.round_tenths(0.05))
  end)

  it("builds a stable string key from region coordinates", function()
    assert.equal("3,7", math_ops.region_key(3, 7))
    assert.equal("-2,-4", math_ops.region_key(-2, -4))
  end)

  it("averages a list and returns zero for an empty list", function()
    assert.equal(0, math_ops.average({}))
    assert.equal(5, math_ops.average({5}))
    assert.equal(10, math_ops.average({0, 10, 20}))
  end)

  it("classifies positive metrics at the exact band boundaries", function()
    assert.equal("thriving", math_ops.positive_band(80))
    assert.equal("stable", math_ops.positive_band(79))
    assert.equal("stable", math_ops.positive_band(60))
    assert.equal("strained", math_ops.positive_band(59))
    assert.equal("strained", math_ops.positive_band(40))
    assert.equal("fragile", math_ops.positive_band(39))
    assert.equal("fragile", math_ops.positive_band(20))
    assert.equal("collapsed", math_ops.positive_band(19))
    assert.equal("collapsed", math_ops.positive_band(0))
  end)

  it("classifies unrest at the exact band boundaries", function()
    assert.equal("calm", math_ops.unrest_band(20))
    assert.equal("watchful", math_ops.unrest_band(21))
    assert.equal("watchful", math_ops.unrest_band(40))
    assert.equal("restless", math_ops.unrest_band(41))
    assert.equal("restless", math_ops.unrest_band(60))
    assert.equal("agitated", math_ops.unrest_band(61))
    assert.equal("agitated", math_ops.unrest_band(80))
    assert.equal("crisis", math_ops.unrest_band(81))
  end)

  it("classifies habitat pressure at the exact band boundaries", function()
    assert.equal("light", math_ops.pressure_band(20))
    assert.equal("rising", math_ops.pressure_band(21))
    assert.equal("rising", math_ops.pressure_band(40))
    assert.equal("disruptive", math_ops.pressure_band(41))
    assert.equal("disruptive", math_ops.pressure_band(60))
    assert.equal("severe", math_ops.pressure_band(61))
    assert.equal("severe", math_ops.pressure_band(80))
    assert.equal("collapse", math_ops.pressure_band(81))
  end)

  it("orders cluster seed offsets by distance then dx then dy", function()
    local offsets = math_ops.cluster_seed_offsets()
    local radius = constants.survey_cluster_seed_search_radius
    local expected_count = ((2 * radius) + 1) * ((2 * radius) + 1)

    assert.equal(expected_count, #offsets)
    -- the origin offset (distance 0) sorts first
    assert.equal(0, offsets[1].dx)
    assert.equal(0, offsets[1].dy)
    assert.equal(0, offsets[1].distance_squared)

    for index = 2, #offsets do
      local previous = offsets[index - 1]
      local current = offsets[index]
      if previous.distance_squared == current.distance_squared then
        if previous.dx == current.dx then
          assert.is_true(previous.dy < current.dy)
        else
          assert.is_true(previous.dx < current.dx)
        end
      else
        assert.is_true(previous.distance_squared < current.distance_squared)
      end
    end
  end)
end)
