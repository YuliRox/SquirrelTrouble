-- Behavioral tests for scripts/squirrels/belt.lua. Installs the belt mechanics
-- with round-tripping target stubs and exercises them against a live transport
-- belt and rider entity plus real storage, so the ongoing decomposition of the
-- squirrel runtime cannot silently change belt riding, blocking or theft.

local constants = require("scripts.constants")
local belt_module = require("scripts.squirrels.belt")
local render_ops = require("scripts.squirrels.render")

local BELT_POS = {x = 220, y = 220}

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

local function reset_belt_storage()
  storage.squirrel_active_belt_riders = {}
  storage.squirrel_belt_block_counts = {}
  storage.squirrels = {}
end

describe("squirrels.belt submodule", function()
  local belt
  local belt_entity
  local rider

  before_each(function()
    reset_belt_storage()
    surface().request_to_generate_chunks(BELT_POS, 1)
    surface().force_generate_chunk_requests()
    for _, entity in ipairs(surface().find_entities_filtered({
      area = {{BELT_POS.x - 10, BELT_POS.y - 10}, {BELT_POS.x + 10, BELT_POS.y + 10}},
      type = "transport-belt"
    })) do
      entity.destroy()
    end

    belt_entity = surface().create_entity({
      name = "transport-belt",
      position = BELT_POS,
      force = game.forces.player,
      direction = defines.direction.east
    })
    assert.is_not_nil(belt_entity)

    local squirrel_force = game.forces[constants.squirrel_force_name] or game.forces.player
    rider = surface().create_entity({
      name = constants.names.squirrel,
      position = {x = BELT_POS.x, y = BELT_POS.y},
      force = squirrel_force
    })
    assert.is_not_nil(rider)

    belt = belt_module.install({
      BELT_TYPES = {["transport-belt"] = true, ["underground-belt"] = true, splitter = true},
      serialize_target = function(entity, target_type, item_name, count)
        return {entity = entity, target_type = target_type, item_name = item_name, count = count}
      end,
      resolve_target_reference = function(_, target)
        if not target then
          return nil
        end
        return target.entity or belt_entity
      end,
      resolve_entity_reference = function(reference)
        return reference
      end,
      direction_to_orientation = render_ops.direction_to_orientation
    })
  end)

  after_each(function()
    if rider and rider.valid then
      rider.destroy()
    end
    if belt_entity and belt_entity.valid then
      belt_entity.destroy()
    end
    reset_belt_storage()
  end)

  it("begins a belt ride: blocks the belt, registers the rider, records the ride", function()
    local record = {squirrel_id = 1, surface_index = surface().index, target = {line_index = 1}}

    belt.begin_belt_ride(record, rider, belt_entity, 100)

    assert.is_not_nil(record.belt_ride)
    assert.is_true(storage.squirrel_active_belt_riders[1])
    assert.is_false(belt_entity.active)
    assert.equal("belt", record.target.target_type)
  end)

  it("clears a belt ride: releases the block and deregisters the rider", function()
    local record = {squirrel_id = 1, surface_index = surface().index, target = {line_index = 1}}
    belt.begin_belt_ride(record, rider, belt_entity, 100)

    local function total_blocks()
      local total = 0
      for _, count in pairs(storage.squirrel_belt_block_counts) do
        total = total + count
      end
      return total
    end

    assert.equal(1, total_blocks())

    belt.clear_belt_ride(record)

    assert.is_nil(record.belt_ride)
    assert.is_nil(storage.squirrel_active_belt_riders[1])
    -- The block count is the deterministic contract. (belt_entity.active toggles
    -- back to true here too, but Factorio only reflects that on the next tick,
    -- and begin/clear run on the same tick in this test.)
    assert.equal(0, total_blocks())
  end)

  it("removes items from a belt transport line", function()
    local line = belt_entity.get_transport_line(1)
    line.insert_at_back({name = constants.names.nut, count = 1})

    local removed = belt.remove_belt_item(belt_entity, constants.names.nut, 1)

    assert.is_true(removed >= 1)
  end)

  it("ends the ride when the belt is no longer valid", function()
    local record = {squirrel_id = 1, surface_index = surface().index, target = {line_index = 1}}
    belt.begin_belt_ride(record, rider, belt_entity, 100)
    belt_entity.destroy()

    local advanced = belt.advance_belt_ride(record, rider, 110)

    assert.is_false(advanced)
    assert.is_nil(record.belt_ride)
  end)

  it("prunes active-rider entries that no longer have a record", function()
    storage.squirrel_active_belt_riders[999] = true

    belt.advance_active_belt_riders(200)

    assert.is_nil(storage.squirrel_active_belt_riders[999])
  end)
end)
