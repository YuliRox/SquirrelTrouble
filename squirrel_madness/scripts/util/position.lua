local M = {}

function M.clone(position)
  if not position then
    return nil
  end

  return {
    x = position.x,
    y = position.y
  }
end

return M
