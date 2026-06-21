local constants = require("scripts.constants")
local regions = require("scripts.regions.module")
local inventory_ops = require("scripts.feeders.inventory")

local is_feeder_name = inventory_ops.is_feeder_name
local get_inventory = inventory_ops.get_inventory
local get_nut_count = inventory_ops.get_nut_count
local is_stocked = inventory_ops.is_stocked
local wants_full_variant = inventory_ops.wants_full_variant
local snapshot_contents = inventory_ops.snapshot_contents
local restore_contents = inventory_ops.restore_contents

local feeders = {}

local function clone_position(position)
  return {x = position.x, y = position.y}
end

local function find_feeder_at(surface, position)
  return surface.find_entities_filtered({
    area = {
      {position.x - 0.2, position.y - 0.2},
      {position.x + 0.2, position.y + 0.2}
    },
    name = constants.feeder_entity_names,
    limit = 1
  })[1]
end

local function upsert_record(entity, nut_count)
  if not (entity and entity.valid and entity.unit_number) then
    return nil
  end

  storage.feeders[entity.unit_number] = {
    surface_index = entity.surface.index,
    position = clone_position(entity.position),
    nut_count = nut_count,
    stocked = is_stocked(nut_count)
  }

  return storage.feeders[entity.unit_number]
end

local function replace_variant(entity, target_name)
  local inventory = get_inventory(entity)
  local contents = snapshot_contents(inventory)
  local surface = entity.surface
  local position = clone_position(entity.position)
  local force = entity.force
  local direction = entity.direction
  local old_unit_number = entity.unit_number
  local health = entity.health

  if inventory and inventory.valid then
    inventory.clear()
  end

  entity.destroy()

  local replacement = surface.create_entity({
    name = target_name,
    position = position,
    force = force,
    direction = direction,
    spill = false
  })
  if not (replacement and replacement.valid) then
    return nil
  end

  if health and replacement.health then
    replacement.health = health
  end

  restore_contents(get_inventory(replacement), contents)

  if old_unit_number then
    storage.feeders[old_unit_number] = nil
  end

  return replacement
end

function feeders.is_feeder_entity(entity)
  return entity and entity.valid and is_feeder_name(entity.name)
end

function feeders.register(entity)
  if not feeders.is_feeder_entity(entity) then
    return nil
  end

  return upsert_record(entity, get_nut_count(entity))
end

function feeders.unregister(entity)
  local unit_number = entity
  if type(entity) ~= "number" then
    unit_number = entity and entity.unit_number or nil
  end

  if unit_number then
    storage.feeders[unit_number] = nil
  end
end

function feeders.rebuild_tracking(surface_index)
  if surface_index then
    for unit_number, record in pairs(storage.feeders or {}) do
      if record.surface_index == surface_index then
        storage.feeders[unit_number] = nil
      end
    end

    local surface = game.surfaces[surface_index]
    if not surface then
      return
    end

    for _, entity in ipairs(surface.find_entities_filtered({name = constants.feeder_entity_names})) do
      feeders.register(entity)
    end

    return
  end

  storage.feeders = {}

  for _, surface in pairs(game.surfaces) do
    for _, entity in ipairs(surface.find_entities_filtered({name = constants.feeder_entity_names})) do
      feeders.register(entity)
    end
  end
end

function feeders.sync_entity(entity)
  if not feeders.is_feeder_entity(entity) then
    return nil, false, false
  end

  local record = entity.unit_number and storage.feeders[entity.unit_number] or nil
  local nut_count = get_nut_count(entity)
  local stocked_before = record and record.stocked or is_stocked(nut_count)
  local variant = constants.feeder_variant_by_name[entity.name]
  local desired_name = wants_full_variant(nut_count) and variant.full or variant.empty
  local changed_visual = false

  if desired_name ~= entity.name then
    entity = replace_variant(entity, desired_name)
    changed_visual = entity ~= nil
    if not entity then
      return nil, false, stocked_before ~= is_stocked(nut_count)
    end
  end

  local stocked_after = is_stocked(get_nut_count(entity))
  upsert_record(entity, get_nut_count(entity))

  if stocked_before ~= stocked_after then
    regions.mark_dirty(entity.surface.index, entity.position)
  end

  return entity, changed_visual, stocked_before ~= stocked_after
end

function feeders.sync_registered(surface_index)
  local unit_numbers = {}
  local changed = 0

  for unit_number in pairs(storage.feeders or {}) do
    unit_numbers[#unit_numbers + 1] = unit_number
  end

  for _, unit_number in ipairs(unit_numbers) do
    local record = storage.feeders[unit_number]
    if record and (not surface_index or record.surface_index == surface_index) then
      local surface = game.surfaces[record.surface_index]
      local entity = surface and find_feeder_at(surface, record.position) or nil

      if not (entity and entity.valid) then
        storage.feeders[unit_number] = nil
      else
        if entity.unit_number and entity.unit_number ~= unit_number then
          storage.feeders[unit_number] = nil
          storage.feeders[entity.unit_number] = record
        end

        local _, changed_visual = feeders.sync_entity(entity)
        if changed_visual then
          changed = changed + 1
        end
      end
    end
  end

  return changed
end

function feeders.debug_state(surface_index, position)
  local surface = game.surfaces[surface_index]
  if not surface then
    return nil
  end

  local entity = find_feeder_at(surface, position)
  if not (entity and entity.valid) then
    return nil
  end

  local variant = constants.feeder_variant_by_name[entity.name]
  local nut_count = get_nut_count(entity)
  local inventory = get_inventory(entity)

  return {
    name = entity.name,
    item = variant and variant.item or nil,
    full_variant = variant and variant.full or nil,
    empty_variant = variant and variant.empty or nil,
    nut_count = nut_count,
    stocked = is_stocked(nut_count),
    inventory_size = inventory and #inventory or 0
  }
end

return feeders
