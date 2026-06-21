local position_ops = require("scripts.squirrels.position")

local clone_position = position_ops.clone

local M = {}

function M.resolve_entity_reference(entity)
  if not (entity and entity.valid) then
    return nil
  end

  return entity
end

function M.resolve_entity_by_unit_number(unit_number)
  if not unit_number then
    return nil
  end

  return game.get_entity_by_unit_number(unit_number)
end

function M.serialize_target(entity, target_type, item_name, count)
  if not (entity and entity.valid) then
    return nil
  end

  return {
    target_type = target_type,
    entity = entity,
    unit_number = entity.unit_number,
    name = entity.name,
    position = clone_position(entity.position),
    item_name = item_name,
    count = count or 1
  }
end

function M.resolve_target_reference(surface_index, target)
  if not target then
    return nil
  end

  local entity = M.resolve_entity_reference(target.entity)
  if entity then
    return entity
  end

  entity = M.resolve_entity_by_unit_number(target.unit_number)
  if entity and entity.valid then
    return entity
  end

  local surface = game.surfaces[surface_index]
  if not surface then
    return nil
  end

  local matches = surface.find_entities_filtered({
    position = target.position,
    name = target.name,
    limit = 1
  })

  return matches[1]
end

return M
