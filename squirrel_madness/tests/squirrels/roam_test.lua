-- Behavioral tests for scripts/squirrels/roam.lua. Exercises the deterministic
-- roam/excursion distance math, the home-distance clamp, and the state-scaled
-- idle pause so decomposition cannot silently change wandering behavior.

local roam_ops = require("scripts.squirrels.roam")
local constants = require("scripts.constants")
local math2d = require("math2d")

describe("squirrels.roam submodule", function()
  it("keeps roam step distance within the configured band", function()
    for id = 1, 25 do
      local record = {squirrel_id = id, roam_step = id * 3}
      local distance = roam_ops.roam_step_distance(record)
      assert.is_true(distance >= constants.squirrel_roam_step_min_distance)
      assert.is_true(distance <= constants.squirrel_roam_step_max_distance)
    end
  end)

  it("is deterministic for the same squirrel id and roam step", function()
    local a = roam_ops.roam_step_distance({squirrel_id = 7, roam_step = 4})
    local b = roam_ops.roam_step_distance({squirrel_id = 7, roam_step = 4})
    assert.equal(a, b)
  end)

  it("pushes excursion distance further for more agitated states", function()
    local record = {squirrel_id = 3, roam_step = 2}
    local calm = roam_ops.excursion_step_distance(record, "calm")
    assert.equal(calm + 0.4, roam_ops.excursion_step_distance(record, "mischievous"))
    assert.equal(calm + 0.75, roam_ops.excursion_step_distance(record, "agitated"))
    assert.equal(calm + 1.25, roam_ops.excursion_step_distance(record, "grieving"))
  end)

  it("clamps an unbounded destination back toward home", function()
    local record = {
      squirrel_id = 9,
      roam_step = 5,
      home_position = {x = 0, y = 0}
    }
    local allowed = 6
    local destination = roam_ops.bounded_roam_destination(record, nil, allowed, nil, "calm")
    local home_distance = math2d.position.distance(destination, record.home_position)
    assert.is_true(home_distance <= allowed + 0.0001)
  end)

  it("aims an excursion toward a preferred target direction", function()
    local record = {
      squirrel_id = 2,
      roam_step = 1,
      home_position = {x = 0, y = 0}
    }
    -- A far preferred target to the east should bias the destination east of home.
    local destination = roam_ops.bounded_roam_destination(
      record, nil, constants.squirrel_home_wander_distance, {x = 100, y = 0}, "calm"
    )
    assert.is_true(destination.x > 0)
  end)

  it("scales the idle pause by mood, calmer squirrels resting longest", function()
    local base = {squirrel_id = 4, roam_step = 6}
    local function pause(state)
      base.state = state
      return roam_ops.idle_pause_duration(base)
    end
    assert.is_true(pause("calm") > pause("curious"))
    assert.is_true(pause("curious") > pause("mischievous"))
    assert.is_true(pause("mischievous") > pause("agitated"))
  end)
end)
