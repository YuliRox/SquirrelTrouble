local math2d = require("math2d")

local M = {}

function M.clone(position)
  return {x = position.x, y = position.y}
end

function M.round_key(position)
  return math.floor((position.x * 10) + 0.5) .. ":" .. math.floor((position.y * 10) + 0.5)
end

function M.nearest_player_distance_squared(surface_index, position)
  local nearest

  for _, player in ipairs(game.connected_players) do
    if player.valid and player.surface and player.surface.index == surface_index then
      local distance = math2d.position.distance_squared(player.position, position)
      if not nearest or distance < nearest then
        nearest = distance
      end
    end
  end

  return nearest
end

function M.player_position_for_index(surface_index, player_index)
  if not player_index then
    return nil
  end

  local player = game.get_player(player_index)
  if not (player and player.valid and player.surface and player.surface.index == surface_index) then
    return nil
  end

  return M.clone(player.position)
end

function M.position_respects_player_buffer(surface_index, position, minimum_distance)
  if not minimum_distance then
    return true
  end

  local nearest = M.nearest_player_distance_squared(surface_index, position)
  if not nearest then
    return true
  end

  return nearest >= (minimum_distance * minimum_distance)
end

function M.with_offset(origin, angle, distance)
  return {
    x = origin.x + (math.cos(angle) * distance),
    y = origin.y + (math.sin(angle) * distance)
  }
end

function M.reached_position(entity, position, max_distance)
  return math2d.position.distance_squared(entity.position, position) <= ((max_distance or 1.4) ^ 2)
end

return M
