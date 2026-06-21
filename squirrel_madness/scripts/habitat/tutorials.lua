local constants = require("scripts.constants")
local regions = require("scripts.regions.module")
local world = require("scripts.habitat.world")

local is_supported_surface = world.is_supported_surface

local M = {}

local function get_force_tutorials(force_index)
  storage.force_tutorials[force_index] = storage.force_tutorials[force_index] or {}
  return storage.force_tutorials[force_index]
end

function M.maybe_show_deforestation_hint(player_index, surface, position, tick)
  if not player_index then
    return
  end

  local player = game.get_player(player_index)
  if not (player and player.valid and player.force and is_supported_surface(surface)) then
    return
  end

  local tutorials = get_force_tutorials(player.force.index)
  if tutorials.deforestation_hint then
    return
  end

  local region = regions.get_region_report_at_position(surface, position, tick)
  if region.recent_tree_loss >= constants.tutorial_tree_loss_threshold then
    tutorials.deforestation_hint = true
    player.force.print({"message.squirrel-madness-deforestation-hint"})
  end
end

function M.maybe_show_sapling_hint(player_index)
  if not player_index then
    return
  end

  local player = game.get_player(player_index)
  if not (player and player.valid and player.force) then
    return
  end

  local tutorials = get_force_tutorials(player.force.index)
  if tutorials.sapling_hint then
    return
  end

  tutorials.sapling_hint = true
  player.print({"message.squirrel-madness-sapling-planted"})
end

function M.maybe_show_harvest_hint(player_index)
  if not player_index then
    return
  end

  local player = game.get_player(player_index)
  if not (player and player.valid and player.force) then
    return
  end

  local tutorials = get_force_tutorials(player.force.index)
  if tutorials.harvest_hint then
    return
  end

  tutorials.harvest_hint = true
  player.print({"message.squirrel-madness-nut-tree-harvested"})
end

function M.on_research_finished(research)
  if not (research and research.valid and research.force and research.force.valid) then
    return
  end

  local tutorials = get_force_tutorials(research.force.index)

  if research.name == constants.technologies.arboriculture and not tutorials.arboriculture_hint then
    tutorials.arboriculture_hint = true
    research.force.print({"message.squirrel-madness-arboriculture-hint"})
  elseif research.name == constants.technologies.wildlife_diversion and not tutorials.wildlife_diversion_hint then
    tutorials.wildlife_diversion_hint = true
    research.force.print({"message.squirrel-madness-wildlife-diversion-hint"})
  end
end

return M
