local M = {}

local function region_key(region_x, region_y)
  return region_x .. "," .. region_y
end

function M.region_key(region_x, region_y)
  return region_key(region_x, region_y)
end

function M.parse_region_key(key)
  local region_x, region_y = string.match(key or "", "^(%-?%d+),(%-?%d+)$")
  return tonumber(region_x), tonumber(region_y)
end

function M.active_region_key(surface_index, region_x, region_y)
  return surface_index .. ":" .. region_x .. ":" .. region_y
end

function M.get_squirrel_store()
  storage.squirrels = storage.squirrels or {}
  return storage.squirrels
end

function M.next_squirrel_id()
  storage.next_squirrel_id = storage.next_squirrel_id or 1
  local squirrel_id = storage.next_squirrel_id
  storage.next_squirrel_id = squirrel_id + 1
  return squirrel_id
end

function M.get_surface_stashes(surface_index)
  storage.squirrel_stashes = storage.squirrel_stashes or {}
  storage.squirrel_stashes[surface_index] = storage.squirrel_stashes[surface_index] or {}
  return storage.squirrel_stashes[surface_index]
end

function M.next_stash_id()
  storage.next_squirrel_stash_id = storage.next_squirrel_stash_id or 1
  local stash_id = storage.next_squirrel_stash_id
  storage.next_squirrel_stash_id = stash_id + 1
  return stash_id
end

function M.get_surface_region_activity(surface_index)
  storage.squirrel_region_activity = storage.squirrel_region_activity or {}
  storage.squirrel_region_activity[surface_index] = storage.squirrel_region_activity[surface_index] or {}
  return storage.squirrel_region_activity[surface_index]
end

function M.get_surface_region_index(surface_index)
  storage.squirrel_region_index = storage.squirrel_region_index or {}
  storage.squirrel_region_index[surface_index] = storage.squirrel_region_index[surface_index] or {}
  return storage.squirrel_region_index[surface_index]
end

function M.get_region_squirrel_entry(surface_index, region_x, region_y)
  local index = M.get_surface_region_index(surface_index)
  local key = region_key(region_x, region_y)
  index[key] = index[key] or {
    ids = {},
    count = 0
  }
  return index[key]
end

function M.get_entity_squirrel_index()
  storage.squirrel_entity_index = storage.squirrel_entity_index or {}
  return storage.squirrel_entity_index
end

function M.get_surface_stashes_by_region(surface_index)
  storage.squirrel_stashes_by_region = storage.squirrel_stashes_by_region or {}
  storage.squirrel_stashes_by_region[surface_index] = storage.squirrel_stashes_by_region[surface_index] or {}
  return storage.squirrel_stashes_by_region[surface_index]
end

function M.get_region_stash_entry(surface_index, region_x, region_y)
  local index = M.get_surface_stashes_by_region(surface_index)
  local key = region_key(region_x, region_y)
  index[key] = index[key] or {
    ids = {}
  }
  return index[key]
end

function M.get_stash_target_counts()
  storage.squirrel_stash_target_counts = storage.squirrel_stash_target_counts or {}
  return storage.squirrel_stash_target_counts
end

function M.get_target_cooldowns()
  storage.squirrel_target_cooldowns = storage.squirrel_target_cooldowns or {}
  return storage.squirrel_target_cooldowns
end

function M.get_active_belt_riders()
  storage.squirrel_active_belt_riders = storage.squirrel_active_belt_riders or {}
  return storage.squirrel_active_belt_riders
end

function M.get_ignored_removals()
  storage.squirrel_ignored_removals = storage.squirrel_ignored_removals or {}
  return storage.squirrel_ignored_removals
end

function M.get_belt_block_counts()
  storage.squirrel_belt_block_counts = storage.squirrel_belt_block_counts or {}
  return storage.squirrel_belt_block_counts
end

return M
