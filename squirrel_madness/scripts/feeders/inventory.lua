local constants = require("scripts.constants")

local M = {}

function M.is_feeder_name(name)
  return constants.feeder_variant_by_name[name] ~= nil
end

function M.get_inventory(entity)
  return entity.get_inventory(defines.inventory.chest)
end

function M.get_nut_count(entity)
  local inventory = M.get_inventory(entity)
  if not (inventory and inventory.valid) then
    return 0
  end

  return inventory.get_item_count(constants.names.nut)
end

function M.is_stocked(nut_count)
  return nut_count >= constants.stocked_feeder_threshold
end

function M.wants_full_variant(nut_count)
  return nut_count >= constants.feeder_visual_stock_threshold
end

function M.snapshot_contents(inventory)
  local contents = {}

  if not (inventory and inventory.valid) then
    return contents
  end

  for _, item in ipairs(inventory.get_contents()) do
    contents[#contents + 1] = {
      name = item.name,
      count = item.count,
      quality = item.quality
    }
  end

  return contents
end

function M.restore_contents(inventory, contents)
  if not (inventory and inventory.valid) then
    return
  end

  for _, item in ipairs(contents) do
    inventory.insert(item)
  end
end

return M
