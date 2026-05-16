local active_regions = require("scripts.active_regions")
local constants = require("scripts.constants")
local debug = require("scripts.debug.module")
local feeders = require("scripts.feeders")
local feedback = require("scripts.feedback.module")
local habitat = require("scripts.habitat")
local incidents = require("scripts.incidents.module")
local relocation = require("scripts.relocation")
local regions = require("scripts.regions")
local retaliation = require("scripts.retaliation.module")
local selection = require("scripts.selection.module")
local squirrels = require("scripts.squirrels")
local storage_lib = require("scripts.storage")

local runtime = {}
local SQUIRREL_STEP_SOUND = "squirrel-madness-angry-squeak"

local function get_created_entity(event)
  return event.entity or event.created_entity or event.destination
end

local function get_squirrel_damage_attribution()
  storage.squirrel_damage_attribution = storage.squirrel_damage_attribution or {}
  return storage.squirrel_damage_attribution
end

local function force_has_technology(force, technology_name)
  if not (force and force.valid and force.technologies) then
    return false
  end

  local technology = force.technologies[technology_name]
  return technology and technology.valid and technology.researched
end

local function station_distance_squared(position_a, position_b)
  local dx = position_a.x - position_b.x
  local dy = position_a.y - position_b.y
  return (dx * dx) + (dy * dy)
end

local function on_selected_entity_changed(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  selection.update_for_player(player, event.tick)
end

local function survey_region_for_player(player)
  selection.survey.run_for_player(player)
end

local function player_index_from_actor(actor)
  if not (actor and actor.valid) then
    return nil
  end

  if actor.type == "character" and actor.player then
    return actor.player.index
  end

  return nil
end


local function on_init()
  storage_lib.ensure()
  storage.squirrel_step_feedback = nil
  selection.reset()
  feeders.rebuild_tracking()
  local nauvis = game.surfaces[constants.primary_surface_name]
  if nauvis then
    habitat.ensure_starting_grove(nauvis)
  end
  feeders.sync_registered()
  active_regions.refresh(true)
  active_regions.process_queue(constants.region_refresh_batch_size, game.tick)
end

local function on_configuration_changed()
  storage_lib.ensure()
  storage.squirrel_step_feedback = nil
  selection.reset()
  feeders.rebuild_tracking()
  squirrels.normalize_entity_variants()
  feeders.sync_registered()
  active_regions.refresh(true)
end

local function on_periodic_refresh()
  storage_lib.ensure()
  habitat.resolve_pending_replacements(game.tick)
  habitat.recover_ready_harvested_nut_trees(game.tick)
  habitat.mature_ready_saplings(game.tick)
  active_regions.refresh(true)
end

local function on_tick(event)
  if storage and storage.pending_entity_replacements and #storage.pending_entity_replacements > 0 then
    habitat.resolve_pending_replacements(event.tick)
  end

  active_regions.refresh(false)
  active_regions.process_queue(constants.region_refresh_batch_size, event.tick)
  selection.refresh_locked_squirrel_selections(event.tick)

  if event.tick % constants.feeder_visual_update_interval == 0 then
    feeders.sync_registered()
  end

  selection.refresh_overlays(event.tick)

  retaliation.process_feedback_expiry(event.tick)
  retaliation.process_waves(event.tick)

  squirrels.on_tick(event.tick)
end

local function on_entity_removed(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end

  if squirrels.should_ignore_removed_entity(entity) then
    return
  end

  if entity.name == constants.names.nut_sapling then
    habitat.unregister_sapling(entity.surface.index, entity.position)
    regions.mark_dirty(entity.surface.index, entity.position)
    active_regions.enqueue_at_position(entity.surface, entity.position, game.tick)
    return
  end

  if squirrels.is_squirrel_entity(entity) then
    selection.squirrel.clear_entity(entity)

    if event.name == defines.events.on_entity_died then
      local player_index = player_index_from_actor(event.cause) or player_index_from_actor(event.source)
      if player_index then
        regions.note_squirrel_death(entity.surface.index, entity.position, 1, game.tick)
        active_regions.enqueue_at_position(entity.surface, entity.position, game.tick)

        local player = game.get_player(player_index)
        if player then
          local incident = incidents.record(entity.surface, entity.position, player.force, player_index, "death", game.tick, {})
          retaliation.notify(entity.surface, entity.position, player.force, player_index, incident)
        end
      end
    end

    squirrels.on_squirrel_removed(entity, game.tick)
    return
  end

  if entity.name == constants.names.nut_tree then
    if event.name == defines.events.on_player_mined_entity or event.name == defines.events.on_robot_mined_entity then
      habitat.harvest_nut_tree(entity, game.tick)
      active_regions.enqueue_at_position(entity.surface, entity.position, game.tick)

      if event.player_index then
        habitat.maybe_show_harvest_hint(event.player_index)
      end

      return
    end

    regions.note_tree_loss(entity.surface.index, entity.position, 1, game.tick)
    active_regions.enqueue_at_position(entity.surface, entity.position, game.tick)
    habitat.maybe_show_deforestation_hint(event.player_index, entity.surface, entity.position, game.tick)
    return
  end

  if entity.name == constants.names.nut_tree_harvested then
    habitat.unregister_harvested_nut_tree(entity.surface.index, entity.position)
    regions.note_tree_loss(entity.surface.index, entity.position, 1, game.tick)
    active_regions.enqueue_at_position(entity.surface, entity.position, game.tick)
    habitat.maybe_show_deforestation_hint(event.player_index, entity.surface, entity.position, game.tick)
    return
  end

  if entity.type == "tree" then
    regions.note_tree_loss(entity.surface.index, entity.position, 1, game.tick)
    active_regions.enqueue_at_position(entity.surface, entity.position, game.tick)
    habitat.maybe_show_deforestation_hint(event.player_index, entity.surface, entity.position, game.tick)
    return
  end

  if feeders.is_feeder_entity(entity) then
    feeders.unregister(entity)
    regions.mark_dirty(entity.surface.index, entity.position)
    active_regions.enqueue_at_position(entity.surface, entity.position, game.tick)
    return
  end

  if entity.name == constants.names.survey_station then
    selection.survey.clear_entity(entity)
    regions.mark_dirty(entity.surface.index, entity.position)
    active_regions.enqueue_at_position(entity.surface, entity.position, game.tick)
  end
end

local function on_entity_created(event)
  local entity = get_created_entity(event)
  if not (entity and entity.valid) then
    return
  end

  if entity.name == constants.names.nut_sapling then
    habitat.register_sapling(entity, game.tick)
    regions.mark_dirty(entity.surface.index, entity.position)
    active_regions.enqueue_at_position(entity.surface, entity.position, game.tick)

    if event.player_index then
      habitat.maybe_show_sapling_hint(event.player_index)
    end
  elseif feeders.is_feeder_entity(entity) then
    feeders.register(entity)
    regions.mark_dirty(entity.surface.index, entity.position)
    active_regions.enqueue_at_position(entity.surface, entity.position, game.tick)

    if event.player_index then
      local player = game.get_player(event.player_index)
      if player then
        player.print({"message.squirrel-madness-feeder-placed"})
      end
    end
  elseif entity.name == constants.names.survey_station then
    regions.mark_dirty(entity.surface.index, entity.position)
    active_regions.enqueue_at_position(entity.surface, entity.position, game.tick)

    if event.player_index then
      local player = game.get_player(event.player_index)
      if player then
        player.print({"message.squirrel-madness-survey-station-placed"})
      end
    end
  end
end

local function on_chunk_generated(event)
  storage_lib.ensure()
  habitat.seed_chunk(event.surface, event.position, event.area)
  squirrels.seed_chunk_population(event.surface, event.position, event.area, game.tick)
end

local function on_research_finished(event)
  storage_lib.ensure()
  habitat.on_research_finished(event.research)
end

local function find_squirrel_at_position(surface, position)
  local nearest
  local nearest_distance

  for _, entity in ipairs(surface.find_entities_filtered({
    area = {
      {position.x - constants.squirrel_step_trigger_radius, position.y - constants.squirrel_step_trigger_radius},
      {position.x + constants.squirrel_step_trigger_radius, position.y + constants.squirrel_step_trigger_radius}
    },
    name = constants.squirrel_entity_name_list
  })) do
    if entity.valid then
      local distance = station_distance_squared(position, entity.position)
      if distance <= (constants.squirrel_step_trigger_radius * constants.squirrel_step_trigger_radius)
        and (not nearest or distance < nearest_distance)
      then
        nearest = entity
        nearest_distance = distance
      end
    end
  end

  return nearest
end

local function on_squirrel_damaged(event)
  local entity = event.entity
  if not squirrels.is_squirrel_entity(entity) then
    return
  end

  local player_index = player_index_from_actor(event.cause) or player_index_from_actor(event.source)
  if not player_index then
    return
  end

  local player = game.get_player(player_index)
  if not player then
    return
  end

  if event.final_health <= 0 then
    return
  end

  if not feedback.handle_rough_handling(entity, player, event.tick) then
    return
  end
end

local function on_player_changed_position(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid and player.surface) then
    return
  end

  local squirrel = find_squirrel_at_position(player.surface, player.position)
  if squirrel then
    feedback.handle_rough_handling(squirrel, player, event.tick)
  end
end

local function on_custom_input(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  if event.input_name == constants.names.survey_input then
    survey_region_for_player(player)
  elseif event.input_name == constants.names.relocation_input then
    incidents.relocate_selected_squirrel(player, event.tick)
  end
end


local function register_events(events, handler)
  for _, event_id in ipairs(events) do
    script.on_event(event_id, handler)
  end
end

function runtime.register()
  debug.install({
    find_squirrel_at_position = find_squirrel_at_position
  })

  script.on_init(on_init)
  script.on_event(defines.events.on_tick, on_tick)
  script.on_configuration_changed(on_configuration_changed)
  script.on_nth_tick(constants.region_update_interval, on_periodic_refresh)
  register_events({
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.on_entity_died,
    defines.events.script_raised_destroy
  }, on_entity_removed)
  script.on_event(defines.events.on_entity_damaged, on_squirrel_damaged, {
    {filter = "name", name = constants.names.squirrel},
    {filter = "name", name = constants.names.squirrel_sitting}
  })
  register_events({
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive
  }, on_entity_created)
  script.on_event(defines.events.on_chunk_generated, on_chunk_generated)
  script.on_event(defines.events.on_player_changed_position, on_player_changed_position)
  script.on_event(defines.events.on_selected_entity_changed, on_selected_entity_changed)
  script.on_event(defines.events.on_research_finished, on_research_finished)
  script.on_event(constants.names.survey_input, on_custom_input)
  script.on_event(constants.names.relocation_input, on_custom_input)
end

return runtime
