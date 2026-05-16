local active_regions = require("scripts.active_regions")
local constants = require("scripts.constants")
local feedback = require("scripts.feedback.module")
local feeders = require("scripts.feeders")
local habitat = require("scripts.habitat")
local incidents = require("scripts.incidents.module")
local regions = require("scripts.regions")
local relocation = require("scripts.relocation")
local retaliation = require("scripts.retaliation.module")
local selection = require("scripts.selection.module")
local squirrels = require("scripts.squirrels")
local storage_lib = require("scripts.storage")

local module = {}

function module.install(deps)
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

      local result = selection.survey.resolve_request(game.forces.player, surface, {x = x, y = y}, selected_entity)
      return {
        mode = result.mode,
        source = result.source,
        anchor_position = {
          x = result.anchor_position.x,
          y = result.anchor_position.y
        },
        station_powered = selection.survey.is_powered_station(result.station) or false
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
        powered = selection.survey.is_powered_station(station)
      }
    end,
    debug_get_survey_cluster = function(surface_index, x, y)
      storage_lib.ensure()
      local surface = game.surfaces[surface_index]
      if not surface then
        return nil
      end

      return regions.get_forest_cluster_report_at_position(surface, {x = x, y = y}, game.tick)
    end,
    debug_show_survey_overlay = function(player_index, surface_index, x, y)
      storage_lib.ensure()
      local player = game.get_player(player_index)
      local surface = game.surfaces[surface_index]
      if not (player and surface) then
        return nil
      end

      local station = surface.find_entity(constants.names.survey_station, {x = x, y = y})
      if not station then
        return nil
      end

      local cluster = selection.survey.update_for_player(player, station, game.tick)
      if not cluster then
        return nil
      end

      return {
        region_count = cluster.region_count,
        member_regions = cluster.member_regions
      }
    end,
    debug_get_survey_overlay_state = function(player_index)
      storage_lib.ensure()
      return selection.survey.overlay_state(player_index)
    end,
    debug_get_survey_panel_state = function(player_index)
      storage_lib.ensure()
      return selection.survey.panel_state(player_index)
    end,
    debug_clear_survey_overlay = function(player_index)
      storage_lib.ensure()
      return selection.survey.clear_overlay(player_index)
    end,
    debug_show_squirrel_overlay = function(player_index, surface_index, x, y)
      storage_lib.ensure()
      local player = game.get_player(player_index)
      local surface = game.surfaces[surface_index]
      if not (player and surface) then
        return nil
      end

      local squirrel = surface.find_entities_filtered({
        position = {x = x, y = y},
        name = constants.squirrel_entity_name_list,
        limit = 1
      })[1]
      if not squirrel then
        return nil
      end

      if not constants.debug_squirrel_selection_overlay then
        return nil
      end

      return selection.squirrel.render_overlay(player, squirrel, game.tick)
    end,
    debug_show_squirrel_panel = function(player_index, surface_index, x, y)
      storage_lib.ensure()
      local player = game.get_player(player_index)
      local surface = game.surfaces[surface_index]
      if not (player and surface) then
        return nil
      end

      local squirrel = surface.find_entities_filtered({
        position = {x = x, y = y},
        name = constants.squirrel_entity_name_list,
        limit = 1
      })[1]
      if not squirrel then
        return nil
      end

      return selection.squirrel.render_panel(player, squirrel, game.tick)
    end,
    debug_get_squirrel_panel_state = function(player_index)
      storage_lib.ensure()
      return selection.squirrel.panel_state(player_index)
    end,
    debug_get_squirrel_overlay_state = function(player_index)
      storage_lib.ensure()
      return selection.squirrel.overlay_state(player_index)
    end,
    debug_clear_squirrel_overlay = function(player_index)
      storage_lib.ensure()
      selection.squirrel.clear_panel(player_index)
      return selection.squirrel.clear_overlay(player_index)
    end,
    debug_sync_feeders = function(surface_index)
      storage_lib.ensure()
      feeders.rebuild_tracking(surface_index)
      return feeders.sync_registered(surface_index)
    end,
    debug_get_feeder_state = function(surface_index, x, y)
      storage_lib.ensure()
      return feeders.debug_state(surface_index, {x = x, y = y})
    end,
    debug_show_feeder_overlay = function(player_index, surface_index, x, y)
      storage_lib.ensure()
      local player = game.get_player(player_index)
      local surface = game.surfaces[surface_index]
      if not (player and surface) then
        return nil
      end

      local feeder = surface.find_entities_filtered({
        position = {x = x, y = y},
        name = constants.feeder_entity_names,
        limit = 1
      })[1]
      if not feeder then
        return nil
      end

      return selection.feeder.render_overlay(player, feeder)
    end,
    debug_get_feeder_overlay_state = function(player_index)
      storage_lib.ensure()
      return selection.feeder.overlay_state(player_index)
    end,
    debug_clear_feeder_overlay = function(player_index)
      storage_lib.ensure()
      return selection.feeder.clear_overlay(player_index)
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
    debug_enqueue_active_regions = function(force)
      storage_lib.ensure()
      return active_regions.refresh(force ~= false)
    end,
    debug_process_region_refresh_queue = function(limit)
      storage_lib.ensure()
      return active_regions.process_queue(limit, game.tick)
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
    debug_seed_squirrel_chunk = function(surface_index, chunk_x, chunk_y)
      storage_lib.ensure()
      local surface = game.surfaces[surface_index]
      if not surface then
        return 0
      end

      return squirrels.seed_chunk_population(surface, {x = chunk_x, y = chunk_y}, nil, game.tick)
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
    debug_find_relocation_destination = function(surface_index, x, y)
      storage_lib.ensure()
      local surface = game.surfaces[surface_index]
      if not surface then
        return nil
      end

      local best, candidates = relocation.find_destination(surface, {x = x, y = y}, game.tick)
      return {
        best = best,
        candidates = candidates
      }
    end,
    debug_relocate_squirrel = function(squirrel_id, player_index)
      storage_lib.ensure()
      local snapshot = squirrels.snapshot(squirrel_id)
      if not snapshot then
        return nil
      end

      local player = player_index and game.get_player(player_index) or game.players[1]
      local surface = game.surfaces[snapshot.surface_index]
      if not (player and surface) then
        return nil
      end

      local destination = relocation.find_destination(surface, snapshot.position, game.tick)
      if not destination then
        return nil
      end

      local result = squirrels.relocate_squirrel(squirrel_id, destination.region_x, destination.region_y, game.tick)
      if not result then
        return nil
      end

      regions.note_successful_relocation(surface.index, snapshot.position, 1, game.tick)
      active_regions.enqueue_at_position(surface, snapshot.position, game.tick)
      active_regions.enqueue_at_position(surface, result.position, game.tick)

      local incident = incidents.record(surface, snapshot.position, player.force, player.index, "relocation", game.tick, {
        destination_region_x = destination.region_x,
        destination_region_y = destination.region_y,
        destination_position = result.position,
        destination_forest_health = destination.forest_health,
        destination_squirrel_trust = destination.squirrel_trust,
        destination_habitat_pressure = destination.habitat_pressure,
        destination_tree_mass = destination.tree_mass,
        destination_score = destination.score
      })

      retaliation.notify_relocation(player, squirrel_id, incident)
      return incident
    end,
    debug_kill_squirrel = function(squirrel_id)
      storage_lib.ensure()
      return squirrels.debug_kill_squirrel(squirrel_id)
    end,
    debug_clear_surface_squirrels = function(surface_index)
      storage_lib.ensure()
      return squirrels.debug_clear_surface(surface_index)
    end,
    debug_get_squirrel_report = function(surface_index)
      storage_lib.ensure()
      return squirrels.debug_report(surface_index, game.tick)
    end,
    debug_get_squirrel_target = function(squirrel_id)
      storage_lib.ensure()
      return squirrels.debug_target_for_squirrel(squirrel_id, game.tick)
    end,
    debug_get_belt_block_count = function(surface_index, x, y)
      storage_lib.ensure()
      return squirrels.debug_belt_block_count(surface_index, {x = x, y = y})
    end,
    debug_get_squirrel_snapshot = function(squirrel_id)
      storage_lib.ensure()
      return squirrels.snapshot(squirrel_id)
    end,
    debug_force_region_squirrels = function(surface_index, x, y)
      storage_lib.ensure()
      local surface = game.surfaces[surface_index]
      if not surface then
        return 0
      end

      local coord = regions.position_to_region_coord({x = x, y = y})
      return squirrels.ensure_population_in_region(surface, coord.x, coord.y, game.tick, true)
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
    debug_force_belt_sit = function(surface_index, squirrel_id, x, y)
      storage_lib.ensure()
      return squirrels.debug_force_belt_sit(surface_index, squirrel_id, {x = x, y = y}, game.tick)
    end,
    debug_force_single_belt_grab = function(surface_index, squirrel_id, x, y)
      storage_lib.ensure()
      return squirrels.debug_force_single_belt_grab(surface_index, squirrel_id, {x = x, y = y}, game.tick)
    end,
    debug_force_chest_scavenge = function(surface_index, squirrel_id, x, y)
      storage_lib.ensure()
      return squirrels.debug_force_chest_scavenge(surface_index, squirrel_id, {x = x, y = y}, game.tick)
    end,
    debug_advance_squirrel_runtime = function(duration)
      storage_lib.ensure()
      return squirrels.debug_advance_runtime(duration, game.tick)
    end,
    debug_cleanup_empty_stashes = function(surface_index)
      storage_lib.ensure()
      return squirrels.cleanup_empty_stashes(surface_index)
    end,
    debug_handle_player_step = function(player_index, x, y, tick)
      storage_lib.ensure()
      local player = game.get_player(player_index)
      if not (player and player.valid and player.surface) then
        return nil
      end

      local squirrel = deps.find_squirrel_at_position(player.surface, {x = x, y = y})
      if not squirrel then
        return nil
      end

      local incident = feedback.handle_rough_handling(squirrel, player, tick or game.tick)
      return incident and incident.incident_id or nil
    end,
    debug_get_squirrel_incidents = function(surface_index)
      storage_lib.ensure()
      local all_incidents = {}

      for _, incident in pairs(storage.squirrel_incidents or {}) do
        if not surface_index or incident.surface_index == surface_index then
          all_incidents[#all_incidents + 1] = incident
        end
      end

      table.sort(all_incidents, function(left, right)
        return left.incident_id < right.incident_id
      end)

      return all_incidents
    end,
    debug_get_retaliation_state = function(surface_index, player_index)
      storage_lib.ensure()
      local state = retaliation.get_state(surface_index, player_index)
      retaliation.prune_state(state, game.tick)
      return state
    end,
    debug_get_retaliation_feedback = function(player_index)
      storage_lib.ensure()
      local entries = {}

      for _, entry in ipairs(retaliation.storage_feedback()) do
        if not player_index or entry.player_index == player_index then
          entries[#entries + 1] = {
            kind = entry.kind,
            player_index = entry.player_index,
            incident_id = entry.incident_id,
            expires_tick = entry.expires_tick,
            entity_unit_number = entry.entity_unit_number
          }
        end
      end

      return entries
    end,
    debug_get_last_step_feedback = function()
      storage_lib.ensure()
      return feedback.storage_step()
    end,
    debug_refresh_player_selection = function(player_index, tick)
      storage_lib.ensure()
      local player = game.get_player(player_index)
      if not (player and player.valid) then
        return nil
      end

      local restored = selection.squirrel.refresh(player, tick or game.tick)
      selection.update_for_player(player, tick or game.tick)

      local selected = player.selected or restored
      if selected and selected.valid then
        return {
          name = selected.name,
          unit_number = selected.unit_number,
          surface_index = selected.surface.index
        }
      end

      local lock = selection.squirrel.lock_state(player_index)
      if not lock then
        return nil
      end

      return {
        name = squirrels.entity_for_squirrel_id(lock.squirrel_id) and squirrels.entity_for_squirrel_id(lock.squirrel_id).name or constants.names.squirrel,
        unit_number = lock.squirrel_unit_number,
        surface_index = lock.surface_index,
        via_lock = true
      }
    end,
    debug_get_squirrel_selection_lock = function(player_index)
      storage_lib.ensure()
      return selection.squirrel.lock_state(player_index)
    end,
    debug_refresh_locked_squirrel_selections = function(tick)
      storage_lib.ensure()
      selection.refresh_locked_squirrel_selections(tick or game.tick)
      return true
    end,
    debug_process_retaliation_feedback_expiry = function(tick)
      storage_lib.ensure()
      return retaliation.process_feedback_expiry(tick or game.tick)
    end,
    debug_process_retaliation_waves = function(tick)
      storage_lib.ensure()
      return retaliation.process_waves(tick or game.tick)
    end
  })
end

return module
