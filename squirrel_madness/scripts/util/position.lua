local M = {}

function M.serialize(position)
  if not position then
    return nil
  end

  return {
    x = position.x,
    y = position.y
  }
end

function M.deserialize(position)
  if not position then
    return nil
  end

  return {
    x = position.x,
    y = position.y
  }
end

function M.distance_squared(position_a, position_b)
  local dx = position_a.x - position_b.x
  local dy = position_a.y - position_b.y
  return (dx * dx) + (dy * dy)
end

return M
