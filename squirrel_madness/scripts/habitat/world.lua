local constants = require("scripts.constants")

local M = {}

function M.clone_position(position)
  return {x = position.x, y = position.y}
end

function M.positions_equal(left, right)
  return left.x == right.x and left.y == right.y
end

function M.chunk_key(chunk_position)
  return chunk_position.x .. "," .. chunk_position.y
end

function M.chunk_area(chunk_position)
  local left = chunk_position.x * constants.chunk_size
  local top = chunk_position.y * constants.chunk_size

  return {
    left_top = {x = left, y = top},
    right_bottom = {
      x = left + constants.chunk_size,
      y = top + constants.chunk_size
    }
  }
end

function M.is_supported_surface(surface)
  return surface and surface.valid and surface.name == constants.primary_surface_name
end

function M.create_neutral_entity(surface, name, position, raise_built)
  return surface.create_entity({
    name = name,
    position = position,
    force = "neutral",
    raise_built = raise_built,
    create_build_effect_smoke = false,
    spawn_decorations = false
  })
end

function M.find_named_entity(surface, name, position)
  local matches = surface.find_entities_filtered({
    position = position,
    name = name,
    limit = 1
  })

  return matches[1]
end

return M
