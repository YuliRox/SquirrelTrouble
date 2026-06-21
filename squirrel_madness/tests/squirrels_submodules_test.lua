-- Behavioral tests for the squirrel runtime submodules extracted from
-- scripts/squirrels/module.lua. These exercise the real submodule logic
-- (real item prototypes, real chest inventories, real render objects) so the
-- ongoing decomposition cannot silently change carrying or render behavior.

local constants = require("scripts.constants")
local carrying_module = require("scripts.squirrels.carrying")
local render_ops = require("scripts.squirrels.render")

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

describe("squirrels.carrying submodule", function()
  local sync_calls
  local stash_entity
  local carrying

  local function install_with_stash(stash)
    return carrying_module.install({
      sync_render = function()
        sync_calls = sync_calls + 1
      end,
      ensure_stash = function()
        return stash
      end
    })
  end

  before_each(function()
    sync_calls = 0
    stash_entity = surface().create_entity({
      name = "wooden-chest",
      position = {x = 200, y = 200},
      force = game.forces.player
    })
    assert.is_not_nil(stash_entity)
    carrying = install_with_stash(stash_entity)
  end)

  after_each(function()
    if stash_entity and stash_entity.valid then
      stash_entity.destroy()
    end
  end)

  it("stores carried loot and refreshes the render", function()
    local record = {}
    carrying.set_carrying(record, nil, constants.names.nut, 3)

    assert.equal(constants.names.nut, record.carrying.name)
    assert.equal(3, record.carrying.count)
    assert.equal(constants.names.nut, record.last_loot_name)
    assert.is_true(sync_calls >= 1)
  end)

  it("accumulates count when carrying more of the same item", function()
    local record = {}
    carrying.set_carrying(record, nil, constants.names.nut, 3)
    carrying.set_carrying(record, nil, constants.names.nut, 4)

    assert.equal(7, record.carrying.count)
  end)

  it("reports carried count only for the matching item", function()
    local record = {carrying = {name = constants.names.nut, count = 5}}

    assert.equal(5, carrying.carrying_count(record, constants.names.nut))
    assert.equal(0, carrying.carrying_count(record, "wood"))
  end)

  it("derives remaining capacity from the item stack size and caps at zero", function()
    local record = {}
    local stack = carrying.carrying_stack_size(constants.names.nut)

    assert.is_true(stack >= 1)
    assert.equal(stack, carrying.carrying_remaining_capacity(record, constants.names.nut))

    carrying.set_carrying(record, nil, constants.names.nut, stack + 5)
    assert.equal(0, carrying.carrying_remaining_capacity(record, constants.names.nut))
  end)

  it("treats an empty squirrel as already deposited", function()
    local record = {surface_index = surface().index}

    assert.is_true(carrying.deposit_or_spill(record, {position = {x = 200, y = 200}}))
  end)

  it("deposits carried loot into the stash and clears it", function()
    local record = {
      surface_index = surface().index,
      carrying = {name = constants.names.nut, count = 4}
    }

    local ok = carrying.deposit_or_spill(record, {position = {x = 200, y = 200}})

    assert.is_true(ok)
    assert.is_nil(record.carrying)
    local inventory = stash_entity.get_inventory(defines.inventory.chest)
    assert.equal(4, inventory.get_item_count(constants.names.nut))
  end)

  it("keeps carried loot when no stash is available", function()
    local without_stash = install_with_stash(nil)
    local record = {
      surface_index = surface().index,
      carrying = {name = constants.names.nut, count = 4}
    }

    local ok = without_stash.deposit_or_spill(record, {position = {x = 200, y = 200}})

    assert.is_false(ok)
    assert.equal(4, record.carrying.count)
  end)

  it("clears carried loot and refreshes the render", function()
    local record = {carrying = {name = constants.names.nut, count = 2}}

    carrying.clear_carrying(record, nil)

    assert.is_nil(record.carrying)
    assert.is_true(sync_calls >= 1)
  end)
end)

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
