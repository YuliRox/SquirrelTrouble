local constants = require("scripts.constants")
local active_regions = require("scripts.active_regions")
local incidents = require("scripts.incidents.module")
local regions = require("scripts.regions.module")
local retaliation = require("scripts.retaliation.module")
local selection = require("scripts.selection.module")
local squirrels = require("scripts.squirrels.module")

local module = {}
local SQUIRREL_STEP_SOUND = "squirrel-madness-angry-squeak"

local function get_squirrel_step_feedback()
  return storage.squirrel_step_feedback
end

function module.handle_rough_handling(entity, player, tick)
  if not (squirrels.is_squirrel_entity(entity) and player and player.valid) then
    return nil
  end

  local player_index = player.index
  local squirrel_damage_attribution = storage.squirrel_damage_attribution or {}
  storage.squirrel_damage_attribution = squirrel_damage_attribution
  local cooldown_key = entity.unit_number .. ":" .. player_index
  local last_tick = squirrel_damage_attribution[cooldown_key] or 0
  if tick < (last_tick + constants.squirrel_damage_attribution_cooldown) then
    return nil
  end

  squirrel_damage_attribution[cooldown_key] = tick
  regions.note_rough_handling(entity.surface.index, entity.position, 1, tick)
  active_regions.enqueue_at_position(entity.surface, entity.position, tick)
  local active_entity = squirrels.on_stepped(entity, tick, player) or entity
  selection.squirrel.clear_player(player)
  player.play_sound({
    path = SQUIRREL_STEP_SOUND,
    volume_modifier = 0.85
  })
  active_entity.surface.play_sound({
    path = SQUIRREL_STEP_SOUND,
    position = active_entity.position,
    volume_modifier = 0.65
  })
  storage.squirrel_step_feedback = {
    player_index = player.index,
    surface_index = active_entity.surface.index,
    position = {x = active_entity.position.x, y = active_entity.position.y},
    tick = tick,
    path = SQUIRREL_STEP_SOUND
  }

  local incident = incidents.record(active_entity.surface, active_entity.position, player.force, player_index, "rough-handling", tick, {})
  retaliation.notify(active_entity.surface, active_entity.position, player.force, player_index, incident)
  return incident
end

function module.storage_step()
  return get_squirrel_step_feedback()
end

return module
