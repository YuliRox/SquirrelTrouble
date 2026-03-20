local constants = require("scripts.constants")
local habitat = require("scripts.habitat")
local regions = require("scripts.regions")
local storage_lib = require("scripts.storage")

local runtime = {}

local function get_created_entity(event)
  return event.entity or event.created_entity or event.destination
end

local function refresh_active_regions()
  local seen = {}

  for _, player in ipairs(game.connected_players) do
    if player.valid and player.surface then
      local center = regions.position_to_region_coord(player.position)

      for dx = -constants.active_region_radius, constants.active_region_radius do
        for dy = -constants.active_region_radius, constants.active_region_radius do
          local region_x = center.x + dx
          local region_y = center.y + dy
          local key = player.surface.index .. ":" .. region_x .. ":" .. region_y

          if not seen[key] then
            regions.recompute_region(player.surface, region_x, region_y, game.tick)
            seen[key] = true
          end
        end
      end
    end
  end

  storage.last_refresh_tick = game.tick
end

local function print_region_report(player, region)
  player.print({
    "message.squirrel-madness-region-report",
    region.region_x,
    region.region_y,
    region.forest_health,
    {"message.squirrel-madness-band-" .. region.forest_health_band},
    region.squirrel_unrest,
    {"message.squirrel-madness-band-" .. region.squirrel_unrest_band},
    region.squirrel_trust,
    {"message.squirrel-madness-band-" .. region.squirrel_trust_band},
    region.habitat_pressure,
    {"message.squirrel-madness-band-" .. region.habitat_pressure_band}
  })
  player.print({
    "message.squirrel-madness-region-factors",
    region.tree_count,
    region.nut_tree_count,
    region.stocked_feeders,
    region.feeder_count,
    region.recent_tree_loss,
    region.rolling_pollution
  })
  player.print({
    "message.squirrel-madness-region-forces",
    region.canopy_score,
    region.nut_tree_bonus,
    region.stocked_feeder_bonus,
    region.empty_feeder_penalty,
    region.recent_tree_loss_penalty,
    region.rolling_pollution_penalty
  })
end

local function survey_region_for_player(player)
  if not (player and player.valid and player.surface) then
    return
  end

  local selected = player.selected
  local survey_target = selected
  local position = player.position

  if selected and selected.valid and selected.name == constants.names.survey_station then
    position = selected.position
  else
    local coord = regions.position_to_region_coord(player.position)
    local stations = player.surface.find_entities_filtered({
      area = regions.region_area(coord.x, coord.y),
      name = constants.names.survey_station,
      limit = 1
    })

    survey_target = stations[1]
  end

  if not (survey_target and survey_target.valid and survey_target.name == constants.names.survey_station) then
    player.print({"message.squirrel-madness-survey-required"})
    return
  end

  local region = regions.get_region_report_at_position(player.surface, position, game.tick)
  print_region_report(player, region)
end

local function on_init()
  storage_lib.ensure()
  local nauvis = game.surfaces[constants.primary_surface_name]
  if nauvis then
    habitat.ensure_starting_grove(nauvis)
  end
  refresh_active_regions()
end

local function on_configuration_changed()
  storage_lib.ensure()
end

local function on_periodic_refresh()
  storage_lib.ensure()
  habitat.mature_ready_saplings(game.tick)
  refresh_active_regions()
end

local function on_entity_removed(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end

  if entity.name == constants.names.nut_sapling then
    habitat.unregister_sapling(entity.surface.index, entity.position)
    regions.mark_dirty(entity.surface.index, entity.position)
    return
  end

  if entity.type == "tree" then
    regions.note_tree_loss(entity.surface.index, entity.position, 1, game.tick)
    habitat.maybe_show_deforestation_hint(event.player_index, entity.surface, entity.position, game.tick)
    return
  end

  if entity.name == constants.names.feeder or entity.name == constants.names.survey_station then
    regions.mark_dirty(entity.surface.index, entity.position)
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

    if event.player_index then
      habitat.maybe_show_sapling_hint(event.player_index)
    end
  elseif entity.name == constants.names.feeder then
    regions.mark_dirty(entity.surface.index, entity.position)

    if event.player_index then
      local player = game.get_player(event.player_index)
      if player then
        player.print({"message.squirrel-madness-feeder-placed"})
      end
    end
  elseif entity.name == constants.names.survey_station then
    regions.mark_dirty(entity.surface.index, entity.position)

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
end

local function on_research_finished(event)
  storage_lib.ensure()
  habitat.on_research_finished(event.research)
end

local function on_custom_input(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  if event.input_name == constants.names.survey_input then
    survey_region_for_player(player)
  elseif event.input_name == constants.names.relocation_input then
    player.print({"message.squirrel-madness-relocation-placeholder"})
  end
end

local function install_remote_interface()
  if remote.interfaces[constants.mod_name] then
    return
  end

  remote.add_interface(constants.mod_name, {
    get_region_at_position = function(surface_index, x, y)
      storage_lib.ensure()
      local surface = game.surfaces[surface_index]
      if not surface then
        return nil
      end

      return regions.get_region_report_at_position(surface, {x = x, y = y}, game.tick)
    end,
    force_recompute_at_position = function(surface_index, x, y)
      storage_lib.ensure()
      local surface = game.surfaces[surface_index]
      if not surface then
        return nil
      end

      return regions.serialize(regions.force_recompute_at_position(surface, {x = x, y = y}, game.tick))
    end,
    get_region_by_coord = function(surface_index, region_x, region_y)
      storage_lib.ensure()
      local surface = game.surfaces[surface_index]
      if not surface then
        return nil
      end

      return regions.get_region_report_by_coord(surface, region_x, region_y, game.tick)
    end,
    seed_nut_trees_in_area = function(surface_index, left, top, right, bottom, desired_count)
      storage_lib.ensure()
      local surface = game.surfaces[surface_index]
      if not surface then
        return 0
      end

      return habitat.seed_nut_trees_in_area(surface, {
        left_top = {x = left, y = top},
        right_bottom = {x = right, y = bottom}
      }, desired_count, true)
    end,
    ensure_starting_grove = function(surface_index)
      storage_lib.ensure()
      local surface = game.surfaces[surface_index]
      if not surface then
        return 0
      end

      return habitat.ensure_starting_grove(surface)
    end,
    force_mature_all_saplings = function(surface_index)
      storage_lib.ensure()
      return habitat.force_mature_all_saplings(game.tick, surface_index)
    end
  })
end

local function register_events(events, handler)
  for _, event_id in ipairs(events) do
    script.on_event(event_id, handler)
  end
end

function runtime.register()
  install_remote_interface()

  script.on_init(on_init)
  script.on_configuration_changed(on_configuration_changed)
  script.on_nth_tick(constants.region_update_interval, on_periodic_refresh)
  register_events({
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.on_entity_died,
    defines.events.script_raised_destroy
  }, on_entity_removed)
  register_events({
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive
  }, on_entity_created)
  script.on_event(defines.events.on_chunk_generated, on_chunk_generated)
  script.on_event(defines.events.on_research_finished, on_research_finished)
  script.on_event(constants.names.survey_input, on_custom_input)
  script.on_event(constants.names.relocation_input, on_custom_input)
end

return runtime
