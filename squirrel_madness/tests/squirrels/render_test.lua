-- Behavioral tests for scripts/squirrels/render.lua. Exercises the real render
-- logic against a live entity and real render objects so the ongoing
-- decomposition of the squirrel runtime cannot silently change rendering.

local constants = require("scripts.constants")
local render_ops = require("scripts.squirrels.render")

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

describe("squirrels.render submodule", function()
  local target

  before_each(function()
    target = surface().create_entity({
      name = "wooden-chest",
      position = {x = 210, y = 210},
      force = game.forces.player
    })
    assert.is_not_nil(target)
  end)

  after_each(function()
    if target and target.valid then
      target.destroy()
    end
  end)

  it("maps cardinal directions to orientations", function()
    assert.equal(0, render_ops.direction_to_orientation(defines.direction.north))
    assert.equal(0.25, render_ops.direction_to_orientation(defines.direction.east))
    assert.equal(0.5, render_ops.direction_to_orientation(defines.direction.south))
    assert.equal(0.75, render_ops.direction_to_orientation(defines.direction.west))
  end)

  it("draws a carried-item sprite and a count label", function()
    local record = {carrying = {name = constants.names.nut, count = 6}}

    render_ops.sync_render(record, target)

    assert.is_not_nil(record.render_id)
    assert.is_not_nil(record.render_count_id)
  end)

  it("skips rendering when nothing is carried", function()
    local record = {}

    render_ops.sync_render(record, target)

    assert.is_nil(record.render_id)
    assert.is_nil(record.render_count_id)
  end)

  it("destroys existing render objects and clears their handles", function()
    local record = {carrying = {name = constants.names.nut, count = 6}}
    render_ops.sync_render(record, target)
    assert.is_not_nil(record.render_id)

    render_ops.destroy_render(record)

    assert.is_nil(record.render_id)
    assert.is_nil(record.render_count_id)
  end)
end)
