local constants = require("scripts.constants")
local regions = require("scripts.regions")

local active_regions = {}
local ACTIVE_REGION_OFFSETS

local function refresh_region_key(surface_index, region_x, region_y)
  return surface_index .. ":" .. region_x .. ":" .. region_y
end

local function get_region_refresh_queue()
  storage.region_refresh_queue = storage.region_refresh_queue or {}
  return storage.region_refresh_queue
end

local function get_region_refresh_enqueued()
  storage.region_refresh_enqueued = storage.region_refresh_enqueued or {}
  return storage.region_refresh_enqueued
end

local function get_player_region_centers()
  storage.player_region_centers = storage.player_region_centers or {}
  return storage.player_region_centers
end

local function active_region_offsets()
  if ACTIVE_REGION_OFFSETS then
    return ACTIVE_REGION_OFFSETS
  end

  local offsets = {}

  for dx = -constants.active_region_radius, constants.active_region_radius do
    for dy = -constants.active_region_radius, constants.active_region_radius do
      offsets[#offsets + 1] = {
        dx = dx,
        dy = dy,
        distance_squared = (dx * dx) + (dy * dy),
        manhattan = math.abs(dx) + math.abs(dy)
      }
    end
  end

  table.sort(offsets, function(left, right)
    if left.distance_squared ~= right.distance_squared then
      return left.distance_squared < right.distance_squared
    end

    if left.manhattan ~= right.manhattan then
      return left.manhattan < right.manhattan
    end

    if left.dx ~= right.dx then
      return left.dx < right.dx
    end

    return left.dy < right.dy
  end)

  ACTIVE_REGION_OFFSETS = offsets
  return ACTIVE_REGION_OFFSETS
end

function active_regions.enqueue(surface, region_x, region_y, tick)
  if not (surface and surface.valid) then
    return false
  end

  if not regions.needs_recompute(surface, region_x, region_y, tick) then
    return false
  end

  local key = refresh_region_key(surface.index, region_x, region_y)
  local enqueued = get_region_refresh_enqueued()
  if enqueued[key] then
    return false
  end

  get_region_refresh_queue()[#get_region_refresh_queue() + 1] = {
    surface_index = surface.index,
    region_x = region_x,
    region_y = region_y
  }
  enqueued[key] = true
  return true
end

function active_regions.enqueue_at_position(surface, position, tick)
  if not (surface and position) then
    return false
  end

  local coord = regions.position_to_region_coord(position)
  return active_regions.enqueue(surface, coord.x, coord.y, tick)
end

function active_regions.process_queue(limit, tick)
  local queue = get_region_refresh_queue()
  local enqueued = get_region_refresh_enqueued()
  local processed = 0
  local current_tick = tick or game.tick
  local batch_limit = limit or constants.region_refresh_batch_size

  while processed < batch_limit and #queue > 0 do
    local entry = table.remove(queue, 1)
    local key = refresh_region_key(entry.surface_index, entry.region_x, entry.region_y)
    enqueued[key] = nil

    local surface = game.surfaces[entry.surface_index]
    if surface and regions.needs_recompute(surface, entry.region_x, entry.region_y, current_tick) then
      regions.recompute_region(surface, entry.region_x, entry.region_y, current_tick)
      processed = processed + 1
    end
  end

  return {
    processed = processed,
    queued = #queue
  }
end

function active_regions.refresh(force)
  local seen = {}
  local player_centers = get_player_region_centers()
  local connected_players = {}
  local enqueued = 0
  local current_tick = game.tick

  for _, player in ipairs(game.connected_players) do
    if player.valid and player.surface then
      local center = regions.position_to_region_coord(player.position)
      local previous = player_centers[player.index]
      local center_changed = force
        or not previous
        or previous.surface_index ~= player.surface.index
        or previous.x ~= center.x
        or previous.y ~= center.y

      connected_players[player.index] = true
      player_centers[player.index] = {
        surface_index = player.surface.index,
        x = center.x,
        y = center.y
      }

      if center_changed then
        for _, offset in ipairs(active_region_offsets()) do
          local region_x = center.x + offset.dx
          local region_y = center.y + offset.dy
          local key = refresh_region_key(player.surface.index, region_x, region_y)

          if not seen[key] then
            if active_regions.enqueue(player.surface, region_x, region_y, current_tick) then
              enqueued = enqueued + 1
            end
            seen[key] = true
          end
        end
      end
    end
  end

  for player_index in pairs(player_centers) do
    if not connected_players[player_index] then
      player_centers[player_index] = nil
    end
  end

  if force or enqueued > 0 then
    storage.last_refresh_tick = current_tick
  end

  return enqueued
end

return active_regions
