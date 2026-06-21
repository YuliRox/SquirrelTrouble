local M = {}

function M.install(deps)
  local sync_render = deps.sync_render
  local ensure_stash = deps.ensure_stash

  local function clear_carrying(record, entity)
    record.carrying = nil
    sync_render(record, entity)
  end

  local function carrying_stack_size(item_name)
    local prototype = prototypes.item[item_name]
    return (prototype and prototype.stack_size) or 1
  end

  local function carrying_count(record, item_name)
    if record.carrying and record.carrying.name == item_name then
      return record.carrying.count or 0
    end

    return 0
  end

  local function carrying_remaining_capacity(record, item_name)
    return math.max(0, carrying_stack_size(item_name) - carrying_count(record, item_name))
  end

  local function deposit_or_spill(record, entity)
    if not record.carrying then
      return true
    end

    local stash = ensure_stash(record, record.carrying, entity.position)
    local surface = game.surfaces[record.surface_index]
    if not surface then
      return false
    end

    if stash and stash.valid then
      local inventory = stash.get_inventory(defines.inventory.chest)
      if inventory and inventory.valid and inventory.can_insert(record.carrying) then
        inventory.insert(record.carrying)
        clear_carrying(record, entity)
        return true
      end
    end

    return false
  end

  local function set_carrying(record, entity, item_name, count)
    local total = count

    if record.carrying and record.carrying.name == item_name then
      total = record.carrying.count + count
    end

    record.carrying = {name = item_name, count = total}
    record.last_loot_name = item_name
    sync_render(record, entity)
  end

  return {
    clear_carrying = clear_carrying,
    carrying_stack_size = carrying_stack_size,
    carrying_count = carrying_count,
    carrying_remaining_capacity = carrying_remaining_capacity,
    deposit_or_spill = deposit_or_spill,
    set_carrying = set_carrying
  }
end

return M
