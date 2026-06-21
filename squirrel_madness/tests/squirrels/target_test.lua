-- Behavioral tests for scripts/squirrels/target.lua. Exercises the real
-- serialization and resolution logic against live entities so the decomposition
-- of the squirrel runtime cannot silently change target handling.

local target_ops = require("scripts.squirrels.target")

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

describe("squirrels.target submodule", function()
  local entity

  before_each(function()
    entity = surface().create_entity({
      name = "transport-belt",
      position = {x = 220, y = 220},
      force = game.forces.player
    })
    assert.is_not_nil(entity)
  end)

  after_each(function()
    if entity and entity.valid then
      entity.destroy()
    end
  end)

  it("returns a valid entity reference and nil for invalid ones", function()
    assert.equal(entity, target_ops.resolve_entity_reference(entity))
    assert.is_nil(target_ops.resolve_entity_reference(nil))

    local unit_number = entity.unit_number
    entity.destroy()
    assert.is_nil(target_ops.resolve_entity_reference(entity))
    assert.is_nil(target_ops.resolve_entity_by_unit_number(unit_number))
  end)

  it("returns nil from a unit-number lookup with no unit number", function()
    assert.is_nil(target_ops.resolve_entity_by_unit_number(nil))
  end)

  it("serializes a target with a cloned position", function()
    local target = target_ops.serialize_target(entity, "chest", "iron-plate", 3)

    assert.equal("chest", target.target_type)
    assert.equal(entity, target.entity)
    assert.equal(entity.unit_number, target.unit_number)
    assert.equal(entity.name, target.name)
    assert.equal("iron-plate", target.item_name)
    assert.equal(3, target.count)
    assert.equal(entity.position.x, target.position.x)
    assert.equal(entity.position.y, target.position.y)
    assert.is_false(rawequal(entity.position, target.position))
    assert.is_nil(target_ops.serialize_target(nil, "chest"))
  end)

  it("defaults count to 1 when omitted", function()
    local target = target_ops.serialize_target(entity, "chest")
    assert.equal(1, target.count)
  end)

  it("resolves a target reference from a live entity", function()
    local target = target_ops.serialize_target(entity, "chest")
    assert.equal(entity, target_ops.resolve_target_reference(entity.surface.index, target))
    assert.is_nil(target_ops.resolve_target_reference(entity.surface.index, nil))
  end)

  it("falls back to position/name lookup when the cached entity is gone", function()
    local target = target_ops.serialize_target(entity, "chest")
    local surface_index = entity.surface.index
    entity.destroy()

    -- Stale reference and unit number can no longer resolve; the position+name
    -- find filter must recover the freshly recreated entity.
    local replacement = surface().create_entity({
      name = "transport-belt",
      position = {x = 220, y = 220},
      force = game.forces.player
    })

    local resolved = target_ops.resolve_target_reference(surface_index, target)
    assert.equal(replacement, resolved)
    replacement.destroy()
  end)
end)
