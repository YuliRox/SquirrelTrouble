local constants = require("scripts.constants")
local habitat = require("scripts.habitat")
local regions = require("scripts.regions")
local squirrels = require("scripts.squirrels")
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

local function localized_driver(driver)
  return {"message.squirrel-madness-driver-" .. driver}
end

local function join_localized_labels(labels)
  if #labels == 0 then
    return {"message.squirrel-madness-no-dominant-forces"}
  end

  local joined = labels[1]

  for index = 2, #labels do
    joined = {"", joined, ", ", labels[index]}
  end

  return joined
end

local function print_broad_region_report(player, region)
  local driver_labels = {}

  for _, driver in ipairs(region.drivers or {}) do
    driver_labels[#driver_labels + 1] = localized_driver(driver)
  end

  player.print({
    "message.squirrel-madness-region-broad-report",
    {"message.squirrel-madness-band-" .. region.forest_health_band},
    {"message.squirrel-madness-band-" .. region.squirrel_unrest_band},
    {"message.squirrel-madness-band-" .. region.squirrel_trust_band},
    {"message.squirrel-madness-band-" .. region.habitat_pressure_band}
  })
  player.print({
    "message.squirrel-madness-region-broad-forces",
    join_localized_labels(driver_labels)
  })
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
    region.sapling_count,
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
    region.reforestation_bonus,
    region.empty_feeder_penalty,
    region.recent_tree_loss_penalty,
    region.rolling_pollution_penalty
  })
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

local function is_powered_survey_station(entity)
  return entity
    and entity.valid
    and entity.name == constants.names.survey_station
    and entity.energy
    and entity.energy > 0
end

local function find_nearest_survey_station(surface, position, radius)
  local stations = surface.find_entities_filtered({
    area = {
      {position.x - radius, position.y - radius},
      {position.x + radius, position.y + radius}
    },
    name = constants.names.survey_station
  })

  local nearest
  local nearest_distance

  for _, station in ipairs(stations) do
    if station.valid then
      local distance = station_distance_squared(position, station.position)
      if not nearest or distance < nearest_distance then
        nearest = station
        nearest_distance = distance
      end
    end
  end

  return nearest
end

local function resolve_survey_request(force, surface, position, selected_entity)
  if not force_has_technology(force, constants.technologies.forest_surveying) then
    return {
      mode = "research-required",
      anchor_position = position
    }
  end

  if selected_entity and selected_entity.valid and selected_entity.name == constants.names.survey_station then
    return {
      mode = is_powered_survey_station(selected_entity) and "exact" or "power-required",
      anchor_position = selected_entity.position,
      station = selected_entity,
      source = "selected"
    }
  end

  local station = find_nearest_survey_station(surface, position, constants.survey_station_exact_radius)
  if station then
    return {
      mode = is_powered_survey_station(station) and "exact" or "power-required",
      anchor_position = station.position,
      station = station,
      source = "nearby"
    }
  end

  return {
    mode = "broad",
    anchor_position = position
  }
end

local function print_survey_result(player, result)
  if result.mode == "research-required" then
    player.print({"message.squirrel-madness-forest-surveying-required"})
    return
  end

  local region = regions.get_region_report_at_position(player.surface, result.anchor_position, game.tick)

  if result.mode == "exact" then
    print_region_report(player, region)
    return
  end

  print_broad_region_report(player, region)

  if result.mode == "power-required" then
    player.print({"message.squirrel-madness-survey-power-required"})
  else
    player.print({"message.squirrel-madness-survey-exact-hint"})
  end
end

local function survey_region_for_player(player)
  if not (player and player.valid and player.surface) then
    return
  end

  local result = resolve_survey_request(player.force, player.surface, player.position, player.selected)
  print_survey_result(player, result)
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
  habitat.resolve_pending_replacements(game.tick)
  habitat.recover_ready_harvested_nut_trees(game.tick)
  habitat.mature_ready_saplings(game.tick)
  refresh_active_regions()
end

local function on_tick(event)
  if storage and storage.pending_entity_replacements and #storage.pending_entity_replacements > 0 then
    habitat.resolve_pending_replacements(event.tick)
  end

  squirrels.on_tick(event.tick)
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

  if entity.name == constants.names.squirrel then
    squirrels.on_squirrel_removed(entity, game.tick)
    return
  end

  if entity.name == constants.names.nut_tree then
    if event.name == defines.events.on_player_mined_entity or event.name == defines.events.on_robot_mined_entity then
      habitat.harvest_nut_tree(entity, game.tick)

      if event.player_index then
        habitat.maybe_show_harvest_hint(event.player_index)
      end

      return
    end

    regions.note_tree_loss(entity.surface.index, entity.position, 1, game.tick)
    habitat.maybe_show_deforestation_hint(event.player_index, entity.surface, entity.position, game.tick)
    return
  end

  if entity.name == constants.names.nut_tree_harvested then
    habitat.unregister_harvested_nut_tree(entity.surface.index, entity.position)
    regions.note_tree_loss(entity.surface.index, entity.position, 1, game.tick)
    habitat.maybe_show_deforestation_hint(event.player_index, entity.surface, entity.position, game.tick)
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
    debug_resolve_survey = function(surface_index, x, y, selected_x, selected_y)
      storage_lib.ensure()
      local surface = game.surfaces[surface_index]
      if not surface then
        return nil
      end

      local selected_entity
      if selected_x ~= nil and selected_y ~= nil then
        selected_entity = surface.find_entity(constants.names.survey_station, {x = selected_x, y = selected_y})
      end

      local result = resolve_survey_request(game.forces.player, surface, {x = x, y = y}, selected_entity)
      return {
        mode = result.mode,
        source = result.source,
        anchor_position = {
          x = result.anchor_position.x,
          y = result.anchor_position.y
        },
        station_powered = is_powered_survey_station(result.station) or false
      }
    end,
    debug_get_survey_station_state = function(surface_index, x, y)
      storage_lib.ensure()
      local surface = game.surfaces[surface_index]
      if not surface then
        return nil
      end

      local station = surface.find_entity(constants.names.survey_station, {x = x, y = y})
      if not station then
        return nil
      end

      return {
        energy = station.energy,
        powered = is_powered_survey_station(station)
      }
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
    end,
    force_recover_all_harvested_nut_trees = function(surface_index)
      storage_lib.ensure()
      return habitat.force_recover_all_harvested_nut_trees(game.tick, surface_index)
    end,
    debug_spawn_squirrel = function(surface_index, x, y)
      storage_lib.ensure()
      return squirrels.debug_spawn_squirrel(surface_index, {x = x, y = y}, game.tick)
    end,
    debug_kill_squirrel = function(squirrel_id)
      storage_lib.ensure()
      return squirrels.debug_kill_squirrel(squirrel_id)
    end,
    debug_get_squirrel_report = function(surface_index)
      storage_lib.ensure()
      return squirrels.debug_report(surface_index, game.tick)
    end,
    debug_force_region_squirrels = function(surface_index, x, y)
      storage_lib.ensure()
      local surface = game.surfaces[surface_index]
      if not surface then
        return 0
      end

      local coord = regions.position_to_region_coord({x = x, y = y})
      return squirrels.ensure_population_in_region(surface, coord.x, coord.y, game.tick)
    end,
    debug_squirrel_state_at_position = function(surface_index, x, y)
      storage_lib.ensure()
      return squirrels.debug_state_for_position(surface_index, {x = x, y = y}, game.tick)
    end,
    debug_squirrel_item_desirability = function(item_name)
      storage_lib.ensure()
      return squirrels.debug_item_desirability(item_name)
    end,
    debug_force_belt_theft = function(surface_index, squirrel_id, x, y)
      storage_lib.ensure()
      return squirrels.debug_force_belt_theft(surface_index, squirrel_id, {x = x, y = y}, game.tick)
    end,
    debug_force_chest_scavenge = function(surface_index, squirrel_id, x, y)
      storage_lib.ensure()
      return squirrels.debug_force_chest_scavenge(surface_index, squirrel_id, {x = x, y = y}, game.tick)
    end,
    debug_cleanup_empty_stashes = function(surface_index)
      storage_lib.ensure()
      return squirrels.cleanup_empty_stashes(surface_index)
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
  script.on_event(defines.events.on_tick, on_tick)
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
