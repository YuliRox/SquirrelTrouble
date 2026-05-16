local constants = require("scripts.constants")
local active_regions = require("scripts.active_regions")
local regions = require("scripts.regions")
local relocation = require("scripts.relocation")
local selection = require("scripts.selection.module")
local squirrels = require("scripts.squirrels")
local retaliation = require("scripts.retaliation.module")
local position_util = require("scripts.util.position")
local technologies = require("scripts.util.technologies")

local module = {}

local function get_squirrel_incidents()
  storage.squirrel_incidents = storage.squirrel_incidents or {}
  return storage.squirrel_incidents
end

local function next_squirrel_incident_id()
  storage.next_squirrel_incident_id = storage.next_squirrel_incident_id or 1
  local incident_id = storage.next_squirrel_incident_id
  storage.next_squirrel_incident_id = incident_id + 1
  return incident_id
end

function module.record(surface, position, force, player_index, kind, tick, extra)
  local incident_id = next_squirrel_incident_id()
  local coord = regions.position_to_region_coord(position)
  local incident = {
    incident_id = incident_id,
    surface_index = surface.index,
    player_index = player_index,
    kind = kind,
    tick = tick,
    region_x = coord.x,
    region_y = coord.y,
    position = position_util.serialize(position),
    marker_position = position_util.serialize(position)
  }

  if kind == "relocation" then
    incident.message_key = "message.squirrel-madness-relocation-success"
    incident.destination_region_x = extra.destination_region_x
    incident.destination_region_y = extra.destination_region_y
    incident.destination_position = position_util.serialize(extra.destination_position)
    incident.destination_forest_health = extra.destination_forest_health
    incident.destination_squirrel_trust = extra.destination_squirrel_trust
    incident.destination_habitat_pressure = extra.destination_habitat_pressure
    incident.destination_tree_mass = extra.destination_tree_mass
    incident.destination_score = extra.destination_score
  else
    incident.severity = kind == "death" and constants.retaliation_death_severity or constants.retaliation_step_severity
    incident.message_key = kind == "death"
      and "message.squirrel-madness-squirrel-killed-warning"
      or "message.squirrel-madness-squirrel-harmed-warning"

    if player_index and kind == "death" then
      local state = retaliation.get_state(surface.index, player_index)
      retaliation.prune_state(state, tick)
      state.recent_incidents[#state.recent_incidents + 1] = {
        incident_id = incident_id,
        tick = tick,
        severity = incident.severity,
        kind = kind
      }
      state.total_severity = state.total_severity + incident.severity

      local spawner = retaliation.find_revenge_spawner(surface, position)
      state.pending_wave = {
        incident_id = incident_id,
        trigger = kind,
        tick = tick,
        severity = incident.severity,
        retaliation_level = state.total_severity,
        target_position = position_util.serialize(position),
        source_position = position_util.serialize(spawner and spawner.position or position),
        source_unit_number = spawner and spawner.unit_number or nil
      }

      incident.retaliation_level = state.total_severity
      incident.revenge_source = spawner and {
        unit_number = spawner.unit_number,
        name = spawner.name,
        position = position_util.serialize(spawner.position)
      } or nil
      incident.marker_position = incident.revenge_source and incident.revenge_source.position or incident.marker_position
    end
  end

  get_squirrel_incidents()[incident_id] = incident
  return incident
end

function module.relocate_selected_squirrel(player, tick)
  if not technologies.force_has_technology(player.force, constants.technologies.wildlife_relocation) then
    player.print({"message.squirrel-madness-relocation-required"})
    return nil
  end

  local squirrel_entity = selection.squirrel.current(player)
  if not squirrel_entity then
    player.print({"message.squirrel-madness-relocation-no-selection"})
    return nil
  end

  local squirrel_id = squirrels.squirrel_id_for_entity(squirrel_entity)
  if not squirrel_id then
    player.print({"message.squirrel-madness-relocation-no-selection"})
    return nil
  end

  local snapshot = squirrels.snapshot(squirrel_id)
  if not snapshot then
    player.print({"message.squirrel-madness-relocation-no-selection"})
    return nil
  end

  local origin_position = snapshot.position
  local destination, candidates = relocation.find_destination(player.surface, origin_position, tick)
  if not destination then
    player.print({"message.squirrel-madness-relocation-no-destination"})
    return nil
  end

  local result = squirrels.relocate_squirrel(squirrel_id, destination.region_x, destination.region_y, tick)
  if not result then
    player.print({"message.squirrel-madness-relocation-no-destination"})
    return nil
  end

  regions.note_successful_relocation(player.surface.index, origin_position, 1, tick)
  active_regions.enqueue_at_position(player.surface, origin_position, tick)
  active_regions.enqueue_at_position(player.surface, result.position, tick)

  local incident = module.record(player.surface, origin_position, player.force, player.index, "relocation", tick, {
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
  player.print({
    incident.message_key,
    destination.region_x,
    destination.region_y
  })
  player.print({
    "message.squirrel-madness-relocation-success-detail",
    destination.forest_health,
    destination.squirrel_trust,
    destination.habitat_pressure,
    destination.tree_mass,
    #candidates
  })

  return incident
end

return module
