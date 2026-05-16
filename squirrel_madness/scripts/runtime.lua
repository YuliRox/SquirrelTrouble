local constants = require("scripts.constants")
local feeders = require("scripts.feeders")
local habitat = require("scripts.habitat")
local relocation = require("scripts.relocation")
local regions = require("scripts.regions")
local selection = require("scripts.selection.module")
local squirrels = require("scripts.squirrels")
local storage_lib = require("scripts.storage")

local runtime = {}
local SQUIRREL_STEP_SOUND = "squirrel-madness-angry-squeak"
local destroy_feedback_pin

local function get_created_entity(event)
  return event.entity or event.created_entity or event.destination
end

local ACTIVE_REGION_OFFSETS

local function refresh_region_key(surface_index, region_x, region_y)
  return surface_index .. ":" .. region_x .. ":" .. region_y
end

local function get_region_refresh_queue()
  storage.region_refresh_queue = storage.region_refresh_queue or {}
  return storage.region_refresh_queue
end

local function get_region_refresh_enqueued()
  storage.region_refresh_enqueued = storage.region_refresh_enqueued or {}
  return storage.region_refresh_enqueued
end

local function get_player_region_centers()
  storage.player_region_centers = storage.player_region_centers or {}
  return storage.player_region_centers
end

local function get_squirrel_damage_attribution()
  storage.squirrel_damage_attribution = storage.squirrel_damage_attribution or {}
  return storage.squirrel_damage_attribution
end

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

local function get_squirrel_retaliation()
  storage.squirrel_retaliation = storage.squirrel_retaliation or {}
  return storage.squirrel_retaliation
end

local function get_squirrel_retaliation_feedback()
  storage.squirrel_retaliation_feedback = storage.squirrel_retaliation_feedback or {}
  return storage.squirrel_retaliation_feedback
end

local function get_squirrel_step_feedback()
  return storage.squirrel_step_feedback
end

local function active_region_offsets()
  if ACTIVE_REGION_OFFSETS then
    return ACTIVE_REGION_OFFSETS
  end

  local offsets = {}

  for dx = -constants.active_region_radius, constants.active_region_radius do
    for dy = -constants.active_region_radius, constants.active_region_radius do
      offsets[#offsets + 1] = {
        dx = dx,
        dy = dy,
        distance_squared = (dx * dx) + (dy * dy),
        manhattan = math.abs(dx) + math.abs(dy)
      }
    end
  end

  table.sort(offsets, function(left, right)
    if left.distance_squared ~= right.distance_squared then
      return left.distance_squared < right.distance_squared
    end

    if left.manhattan ~= right.manhattan then
      return left.manhattan < right.manhattan
    end

    if left.dx ~= right.dx then
      return left.dx < right.dx
    end

    return left.dy < right.dy
  end)

  ACTIVE_REGION_OFFSETS = offsets
  return ACTIVE_REGION_OFFSETS
end

local function enqueue_region_refresh(surface, region_x, region_y, tick)
  if not (surface and surface.valid) then
    return false
  end

  if not regions.needs_recompute(surface, region_x, region_y, tick) then
    return false
  end

  local key = refresh_region_key(surface.index, region_x, region_y)
  local enqueued = get_region_refresh_enqueued()
  if enqueued[key] then
    return false
  end

  get_region_refresh_queue()[#get_region_refresh_queue() + 1] = {
    surface_index = surface.index,
    region_x = region_x,
    region_y = region_y
  }
  enqueued[key] = true
  return true
end

local function enqueue_region_refresh_at_position(surface, position, tick)
  if not (surface and position) then
    return false
  end

  local coord = regions.position_to_region_coord(position)
  return enqueue_region_refresh(surface, coord.x, coord.y, tick)
end

local function process_region_refresh_queue(limit, tick)
  local queue = get_region_refresh_queue()
  local enqueued = get_region_refresh_enqueued()
  local processed = 0
  local current_tick = tick or game.tick
  local batch_limit = limit or constants.region_refresh_batch_size

  while processed < batch_limit and #queue > 0 do
    local entry = table.remove(queue, 1)
    local key = refresh_region_key(entry.surface_index, entry.region_x, entry.region_y)
    enqueued[key] = nil

    local surface = game.surfaces[entry.surface_index]
    if surface and regions.needs_recompute(surface, entry.region_x, entry.region_y, current_tick) then
      regions.recompute_region(surface, entry.region_x, entry.region_y, current_tick)
      processed = processed + 1
    end
  end

  return {
    processed = processed,
    queued = #queue
  }
end

local function refresh_active_regions(force)
  local seen = {}
  local player_centers = get_player_region_centers()
  local connected_players = {}
  local enqueued = 0
  local current_tick = game.tick

  for _, player in ipairs(game.connected_players) do
    if player.valid and player.surface then
      local center = regions.position_to_region_coord(player.position)
      local previous = player_centers[player.index]
      local center_changed = force
        or not previous
        or previous.surface_index ~= player.surface.index
        or previous.x ~= center.x
        or previous.y ~= center.y

      connected_players[player.index] = true
      player_centers[player.index] = {
        surface_index = player.surface.index,
        x = center.x,
        y = center.y
      }

      if center_changed then
        for _, offset in ipairs(active_region_offsets()) do
          local region_x = center.x + offset.dx
          local region_y = center.y + offset.dy
          local key = refresh_region_key(player.surface.index, region_x, region_y)

          if not seen[key] then
            if enqueue_region_refresh(player.surface, region_x, region_y, current_tick) then
              enqueued = enqueued + 1
            end
            seen[key] = true
          end
        end
      end
    end
  end

  for player_index in pairs(player_centers) do
    if not connected_players[player_index] then
      player_centers[player_index] = nil
    end
  end

  if force or enqueued > 0 then
    storage.last_refresh_tick = current_tick
  end

  return enqueued
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

local function serialize_position(position)
  if not position then
    return nil
  end

  return {
    x = position.x,
    y = position.y
  }
end

local function deserialize_position(position)
  if not position then
    return nil
  end

  return {
    x = position.x,
    y = position.y
  }
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

local function retaliation_state_key(surface_index, player_index)
  return surface_index .. ":" .. player_index
end

local function get_retaliation_state(surface_index, player_index)
  local retaliation = get_squirrel_retaliation()
  local key = retaliation_state_key(surface_index, player_index)
  retaliation[key] = retaliation[key] or {
    surface_index = surface_index,
    player_index = player_index,
    recent_incidents = {},
    total_severity = 0,
    pending_wave = nil,
    last_wave = nil
  }
  return retaliation[key]
end

local function prune_retaliation_state(state, tick)
  local cutoff_tick = tick - constants.retaliation_window
  local total_severity = 0
  local write_index = 1

  for read_index = 1, #state.recent_incidents do
    local incident = state.recent_incidents[read_index]
    if incident.tick >= cutoff_tick then
      state.recent_incidents[write_index] = incident
      write_index = write_index + 1
      total_severity = total_severity + (incident.severity or 0)
    end
  end

  for index = write_index, #state.recent_incidents do
    state.recent_incidents[index] = nil
  end

  state.total_severity = total_severity

  if state.pending_wave and state.pending_wave.tick < cutoff_tick then
    state.pending_wave = nil
  end

  if state.last_wave and state.last_wave.tick < cutoff_tick then
    state.last_wave = nil
  end
end

local function connected_force_players(force)
  local players = {}

  for _, player in ipairs(game.connected_players) do
    if player.valid and player.force == force then
      players[#players + 1] = player
    end
  end

  return players
end

local function find_revenge_spawner(surface, position)
  local nearest
  local nearest_distance

  for _, spawner in ipairs(surface.find_entities_filtered({
    area = {
      {position.x - constants.retaliation_spawner_search_radius, position.y - constants.retaliation_spawner_search_radius},
      {position.x + constants.retaliation_spawner_search_radius, position.y + constants.retaliation_spawner_search_radius}
    },
    type = "unit-spawner",
    force = "enemy"
  })) do
    if spawner.valid then
      local distance = station_distance_squared(position, spawner.position)
      if not nearest or distance < nearest_distance then
        nearest = spawner
        nearest_distance = distance
      end
    end
  end

  return nearest
end

local function resolve_revenge_source_entity(surface, revenge_source)
  if not (surface and surface.valid and revenge_source) then
    return nil
  end

  if revenge_source.unit_number then
    local entity = game.get_entity_by_unit_number(revenge_source.unit_number)
    if entity and entity.valid and entity.surface == surface then
      return entity
    end
  end

  if revenge_source.position then
    local candidates = surface.find_entities_filtered({
      area = {
        {revenge_source.position.x - 1, revenge_source.position.y - 1},
        {revenge_source.position.x + 1, revenge_source.position.y + 1}
      },
      type = "unit-spawner",
      force = "enemy"
    })

    for _, entity in ipairs(candidates) do
      if entity.valid then
        return entity
      end
    end
  end

  return nil
end

local function retaliation_wave_unit_name(enemy_force, surface, retaliation_level)
  local evolution = 0
  local level = retaliation_level or 0

  if enemy_force and enemy_force.valid and surface and surface.valid then
    evolution = enemy_force.get_evolution_factor(surface)
  end

  if evolution >= 0.7 or level >= 7 then
    return "big-biter"
  end

  if evolution >= 0.3 or level >= 4 then
    return "medium-biter"
  end

  return "small-biter"
end

local function retaliation_wave_member_count(wave)
  local severity = wave.severity or 0
  local retaliation_level = wave.retaliation_level or severity
  local count = severity + math.floor(retaliation_level / 2)

  return math.max(1, math.min(constants.retaliation_wave_max_members, count))
end

local function resolve_retaliation_spawner(surface, wave)
  if wave.source_unit_number then
    local entity = game.get_entity_by_unit_number(wave.source_unit_number)
    if entity and entity.valid and entity.surface == surface then
      return entity
    end
  end

  local source_position = deserialize_position(wave.source_position) or deserialize_position(wave.target_position)
  if not source_position then
    return nil
  end

  return find_revenge_spawner(surface, source_position)
end

local function create_retaliation_command(target_position)
  return {
    type = defines.command.attack_area,
    destination = target_position,
    radius = constants.retaliation_wave_attack_radius,
    distraction = defines.distraction.by_enemy
  }
end

local function launch_retaliation_wave(state, tick)
  local wave = state.pending_wave
  if not wave then
    return nil
  end

  local surface = game.surfaces[state.surface_index]
  local target_position = deserialize_position(wave.target_position)
  local spawner = surface and resolve_retaliation_spawner(surface, wave) or nil

  local launched_wave = {
    incident_id = wave.incident_id,
    trigger = wave.trigger,
    tick = wave.tick,
    launched_tick = tick,
    severity = wave.severity,
    retaliation_level = wave.retaliation_level,
    target_position = serialize_position(target_position),
    source_unit_number = spawner and spawner.unit_number or wave.source_unit_number,
    source_position = serialize_position(spawner and spawner.position or deserialize_position(wave.source_position)),
    unit_name = nil,
    unit_count = 0,
    unit_positions = {},
    status = "no-source"
  }

  if not (surface and target_position and spawner and spawner.valid) then
    state.pending_wave = nil
    state.last_wave = launched_wave
    return launched_wave
  end

  local enemy_force = game.forces.enemy
  local unit_name = retaliation_wave_unit_name(enemy_force, surface, wave.retaliation_level)
  local member_count = retaliation_wave_member_count(wave)
  launched_wave.unit_name = unit_name
  launched_wave.status = "no-units"

  for index = 1, member_count do
    local angle = ((index - 1) / member_count) * math.pi * 2
    local anchor = {
      x = spawner.position.x + (math.cos(angle) * constants.retaliation_wave_spawn_radius),
      y = spawner.position.y + (math.sin(angle) * constants.retaliation_wave_spawn_radius)
    }
    local spawn_position = surface.find_non_colliding_position(
      unit_name,
      anchor,
      constants.retaliation_wave_spawn_search_radius,
      0.5,
      true
    ) or surface.find_non_colliding_position(
      unit_name,
      spawner.position,
      constants.retaliation_wave_spawn_search_radius,
      0.5,
      true
    )

    if spawn_position then
      local unit = surface.create_entity({
        name = unit_name,
        position = spawn_position,
        force = enemy_force,
        source = spawner,
        target = target_position,
        create_build_effect_smoke = false,
        raise_built = false
      })

      if unit and unit.valid and unit.commandable then
        unit.commandable.set_command(create_retaliation_command(target_position))
        launched_wave.unit_count = launched_wave.unit_count + 1
        launched_wave.unit_positions[#launched_wave.unit_positions + 1] = serialize_position(unit.position)
      elseif unit and unit.valid then
        unit.destroy()
      end
    end
  end

  if launched_wave.unit_count > 0 then
    launched_wave.status = "launched"
  end

  state.pending_wave = nil
  state.last_wave = launched_wave
  return launched_wave
end

local function process_retaliation_waves(tick)
  local launched = 0
  local retaliation = get_squirrel_retaliation()

  for _, state in pairs(retaliation) do
    prune_retaliation_state(state, tick)

    local wave = state.pending_wave
    if wave and tick >= (wave.tick + constants.retaliation_wave_delay) then
      local launched_wave = launch_retaliation_wave(state, tick)
      if launched_wave and launched_wave.status == "launched" then
        launched = launched + 1
      end
    end
  end

  return {
    launched = launched
  }
end

local function process_retaliation_feedback_expiry(tick)
  local feedback = get_squirrel_retaliation_feedback()
  local write_index = 1

  for read_index = 1, #feedback do
    local entry = feedback[read_index]
    if tick >= entry.expires_tick then
      local player = game.get_player(entry.player_index)
      if player and player.valid then
        if entry.kind == "death-site-pin" or entry.kind == "relocation-destination-pin" then
          destroy_feedback_pin(entry, player)
        elseif entry.kind == "revenge-source-alert" and entry.entity_unit_number then
          local entity = game.get_entity_by_unit_number(entry.entity_unit_number)
          if entity and entity.valid then
            player.remove_alert({
              entity = entity,
              icon = {type = "item", name = constants.names.nut},
              message = entry.message
            })
          end
        end
      end
    else
      feedback[write_index] = entry
      write_index = write_index + 1
    end
  end

  for index = write_index, #feedback do
    feedback[index] = nil
  end

  return #feedback
end

destroy_feedback_pin = function(entry, player)
  local tag = entry.tag
  if tag and tag.valid then
    tag.destroy()
    return true
  end

  local surface = entry.surface_index and game.surfaces[entry.surface_index] or nil
  if not (surface and player and player.valid) then
    return false
  end

  for _, candidate in ipairs(player.force.find_chart_tags(surface)) do
    if candidate.valid and entry.tag_number and candidate.tag_number == entry.tag_number then
      candidate.destroy()
      return true
    end
  end

  local destroyed = false
  if entry.position then
    local expected_text = entry.text
    for _, candidate in ipairs(player.force.find_chart_tags(surface)) do
      if candidate.valid then
        local matches_position = station_distance_squared(candidate.position, entry.position) <= 1
        local matches_text = (not expected_text) or candidate.text == expected_text
        if matches_position and matches_text then
          candidate.destroy()
          destroyed = true
        end
      end
    end
  end

  if destroyed then
    return true
  end

  if entry.text then
    for _, candidate in ipairs(player.force.find_chart_tags(surface)) do
      if candidate.valid and candidate.text == entry.text then
        candidate.destroy()
        destroyed = true
      end
    end
  end

  return destroyed
end

local function notify_relocation(player, squirrel_id, incident)
  if not (player and player.valid and incident and incident.kind == "relocation") then
    return
  end

  local label = "Relocated squirrel"
  if incident.destination_region_x and incident.destination_region_y then
    label = label .. " (" .. incident.destination_region_x .. ", " .. incident.destination_region_y .. ")"
  end
  local tag
  local squirrel_entity = squirrels.entity_for_squirrel_id(squirrel_id)

  if incident.destination_position then
    local surface = game.surfaces[incident.surface_index]
    if surface then
      player.force.chart(surface, {
        left_top = {
          x = incident.destination_position.x - 4,
          y = incident.destination_position.y - 4
        },
        right_bottom = {
          x = incident.destination_position.x + 4,
          y = incident.destination_position.y + 4
        }
      })
    end
  end

  if squirrel_entity and squirrel_entity.valid then
    tag = player.add_pin({
      entity = squirrel_entity,
      label = label,
      preview_distance = 256,
      always_visible = true
    })
  else
    local surface = game.surfaces[incident.surface_index]
    if surface and incident.destination_position then
      tag = player.add_pin({
        surface = surface,
        position = incident.destination_position,
        label = label,
        preview_distance = 256,
        always_visible = true
      })
    end
  end

  if tag then
    local feedback = get_squirrel_retaliation_feedback()
    feedback[#feedback + 1] = {
      kind = "relocation-destination-pin",
      player_index = player.index,
      incident_id = incident.incident_id,
      expires_tick = game.tick + constants.retaliation_feedback_duration,
      surface_index = incident.surface_index,
      tag = tag,
      tag_number = tag.tag_number,
      position = {
        x = incident.destination_position.x,
        y = incident.destination_position.y
      },
      entity_unit_number = squirrel_entity and squirrel_entity.valid and squirrel_entity.unit_number or nil
    }
  end
end

local function notify_retaliation(surface, position, force, player_index, incident)
  local players = connected_force_players(force)
  local direct_player = player_index and game.get_player(player_index) or nil
  local death_site_tag = nil

  if #players == 0 and direct_player then
    players[1] = direct_player
  end

  if incident.kind == "death" then
    local death_position = incident.position
    force.chart(surface, {
      left_top = {x = death_position.x - 1, y = death_position.y - 1},
      right_bottom = {x = death_position.x + 1, y = death_position.y + 1}
    })
    death_site_tag = force.add_chart_tag(surface, {
      position = death_position,
      text = "Squirrel death site",
      last_user = direct_player or players[1]
    })
  end

  for _, player in ipairs(players) do
    local message = incident.kind == "death"
      and {incident.message_key, incident.retaliation_level or incident.severity}
      or {incident.message_key}

    if incident.kind ~= "rough-handling" then
      player.print(message)
    end

    if death_site_tag then
      local feedback = get_squirrel_retaliation_feedback()
      feedback[#feedback + 1] = {
        kind = "death-site-pin",
        player_index = player.index,
        incident_id = incident.incident_id,
        expires_tick = game.tick + constants.retaliation_feedback_duration,
        surface_index = surface.index,
        tag = death_site_tag,
        tag_number = death_site_tag.valid and death_site_tag.tag_number or nil,
        position = {
          x = incident.position.x,
          y = incident.position.y
        },
        text = "Squirrel death site"
      }
    end

    if incident.revenge_source then
      local spawner = resolve_revenge_source_entity(surface, incident.revenge_source)
      if spawner and spawner.valid then
        player.add_custom_alert(
          spawner,
          {type = "item", name = constants.names.nut},
          message,
          true
        )

        local feedback = get_squirrel_retaliation_feedback()
        feedback[#feedback + 1] = {
          kind = "revenge-source-alert",
          player_index = player.index,
          incident_id = incident.incident_id,
          expires_tick = game.tick + constants.retaliation_feedback_duration,
          entity_unit_number = spawner.unit_number,
          message = message
        }
      end
    end
  end
end

local function record_squirrel_incident(surface, position, force, player_index, kind, tick, extra)
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
    position = serialize_position(position),
    marker_position = serialize_position(position)
  }

  if kind == "relocation" then
    incident.message_key = "message.squirrel-madness-relocation-success"
    incident.destination_region_x = extra.destination_region_x
    incident.destination_region_y = extra.destination_region_y
    incident.destination_position = serialize_position(extra.destination_position)
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
      local state = get_retaliation_state(surface.index, player_index)
      prune_retaliation_state(state, tick)
      state.recent_incidents[#state.recent_incidents + 1] = {
        incident_id = incident_id,
        tick = tick,
        severity = incident.severity,
        kind = kind
      }
      state.total_severity = state.total_severity + incident.severity

      local spawner = find_revenge_spawner(surface, position)
      state.pending_wave = {
        incident_id = incident_id,
        trigger = kind,
        tick = tick,
        severity = incident.severity,
        retaliation_level = state.total_severity,
        target_position = serialize_position(position),
        source_position = serialize_position(spawner and spawner.position or position),
        source_unit_number = spawner and spawner.unit_number or nil
      }

      incident.retaliation_level = state.total_severity
      incident.revenge_source = spawner and {
        unit_number = spawner.unit_number,
        name = spawner.name,
        position = serialize_position(spawner.position)
      } or nil
      incident.marker_position = incident.revenge_source and incident.revenge_source.position or incident.marker_position
    end
  end

  get_squirrel_incidents()[incident_id] = incident
  return incident
end

local function relocate_selected_squirrel(player, tick)
  if not force_has_technology(player.force, constants.technologies.wildlife_relocation) then
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
  enqueue_region_refresh_at_position(player.surface, origin_position, tick)
  enqueue_region_refresh_at_position(player.surface, result.position, tick)

  local incident = record_squirrel_incident(player.surface, origin_position, player.force, player.index, "relocation", tick, {
    destination_region_x = destination.region_x,
    destination_region_y = destination.region_y,
    destination_position = result.position,
    destination_forest_health = destination.forest_health,
    destination_squirrel_trust = destination.squirrel_trust,
    destination_habitat_pressure = destination.habitat_pressure,
    destination_tree_mass = destination.tree_mass,
    destination_score = destination.score
  })

  notify_relocation(player, squirrel_id, incident)
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
  refresh_active_regions(true)
  process_region_refresh_queue(constants.region_refresh_batch_size, game.tick)
end

local function on_configuration_changed()
  storage_lib.ensure()
  storage.squirrel_step_feedback = nil
  selection.reset()
  feeders.rebuild_tracking()
  squirrels.normalize_entity_variants()
  feeders.sync_registered()
  refresh_active_regions(true)
end

local function on_periodic_refresh()
  storage_lib.ensure()
  habitat.resolve_pending_replacements(game.tick)
  habitat.recover_ready_harvested_nut_trees(game.tick)
  habitat.mature_ready_saplings(game.tick)
  refresh_active_regions(true)
end

local function on_tick(event)
  if storage and storage.pending_entity_replacements and #storage.pending_entity_replacements > 0 then
    habitat.resolve_pending_replacements(event.tick)
  end

  refresh_active_regions(false)
  process_region_refresh_queue(constants.region_refresh_batch_size, event.tick)
  selection.refresh_locked_squirrel_selections(event.tick)

  if event.tick % constants.feeder_visual_update_interval == 0 then
    feeders.sync_registered()
  end

  selection.refresh_overlays(event.tick)

  process_retaliation_feedback_expiry(event.tick)
  process_retaliation_waves(event.tick)

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
    enqueue_region_refresh_at_position(entity.surface, entity.position, game.tick)
    return
  end

  if squirrels.is_squirrel_entity(entity) then
    selection.squirrel.clear_entity(entity)

    if event.name == defines.events.on_entity_died then
      local player_index = player_index_from_actor(event.cause) or player_index_from_actor(event.source)
      if player_index then
        regions.note_squirrel_death(entity.surface.index, entity.position, 1, game.tick)
        enqueue_region_refresh_at_position(entity.surface, entity.position, game.tick)

        local player = game.get_player(player_index)
        if player then
          local incident = record_squirrel_incident(entity.surface, entity.position, player.force, player_index, "death", game.tick, {})
          notify_retaliation(entity.surface, entity.position, player.force, player_index, incident)
        end
      end
    end

    squirrels.on_squirrel_removed(entity, game.tick)
    return
  end

  if entity.name == constants.names.nut_tree then
    if event.name == defines.events.on_player_mined_entity or event.name == defines.events.on_robot_mined_entity then
      habitat.harvest_nut_tree(entity, game.tick)
      enqueue_region_refresh_at_position(entity.surface, entity.position, game.tick)

      if event.player_index then
        habitat.maybe_show_harvest_hint(event.player_index)
      end

      return
    end

    regions.note_tree_loss(entity.surface.index, entity.position, 1, game.tick)
    enqueue_region_refresh_at_position(entity.surface, entity.position, game.tick)
    habitat.maybe_show_deforestation_hint(event.player_index, entity.surface, entity.position, game.tick)
    return
  end

  if entity.name == constants.names.nut_tree_harvested then
    habitat.unregister_harvested_nut_tree(entity.surface.index, entity.position)
    regions.note_tree_loss(entity.surface.index, entity.position, 1, game.tick)
    enqueue_region_refresh_at_position(entity.surface, entity.position, game.tick)
    habitat.maybe_show_deforestation_hint(event.player_index, entity.surface, entity.position, game.tick)
    return
  end

  if entity.type == "tree" then
    regions.note_tree_loss(entity.surface.index, entity.position, 1, game.tick)
    enqueue_region_refresh_at_position(entity.surface, entity.position, game.tick)
    habitat.maybe_show_deforestation_hint(event.player_index, entity.surface, entity.position, game.tick)
    return
  end

  if feeders.is_feeder_entity(entity) then
    feeders.unregister(entity)
    regions.mark_dirty(entity.surface.index, entity.position)
    enqueue_region_refresh_at_position(entity.surface, entity.position, game.tick)
    return
  end

  if entity.name == constants.names.survey_station then
    selection.survey.clear_entity(entity)
    regions.mark_dirty(entity.surface.index, entity.position)
    enqueue_region_refresh_at_position(entity.surface, entity.position, game.tick)
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
    enqueue_region_refresh_at_position(entity.surface, entity.position, game.tick)

    if event.player_index then
      habitat.maybe_show_sapling_hint(event.player_index)
    end
  elseif feeders.is_feeder_entity(entity) then
    feeders.register(entity)
    regions.mark_dirty(entity.surface.index, entity.position)
    enqueue_region_refresh_at_position(entity.surface, entity.position, game.tick)

    if event.player_index then
      local player = game.get_player(event.player_index)
      if player then
        player.print({"message.squirrel-madness-feeder-placed"})
      end
    end
  elseif entity.name == constants.names.survey_station then
    regions.mark_dirty(entity.surface.index, entity.position)
    enqueue_region_refresh_at_position(entity.surface, entity.position, game.tick)

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

local function handle_squirrel_rough_handling(entity, player, tick)
  if not (squirrels.is_squirrel_entity(entity) and player and player.valid) then
    return nil
  end

  local player_index = player.index
  local cooldown_key = entity.unit_number .. ":" .. player_index
  local attribution = get_squirrel_damage_attribution()
  local last_tick = attribution[cooldown_key] or 0
  if tick < (last_tick + constants.squirrel_damage_attribution_cooldown) then
    return nil
  end

  attribution[cooldown_key] = tick
  regions.note_rough_handling(entity.surface.index, entity.position, 1, tick)
  enqueue_region_refresh_at_position(entity.surface, entity.position, tick)
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

  local incident = record_squirrel_incident(active_entity.surface, active_entity.position, player.force, player_index, "rough-handling", tick, {})
  notify_retaliation(active_entity.surface, active_entity.position, player.force, player_index, incident)
  return incident
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

  if not handle_squirrel_rough_handling(entity, player, event.tick) then
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
    handle_squirrel_rough_handling(squirrel, player, event.tick)
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
    relocate_selected_squirrel(player, event.tick)
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
      return refresh_active_regions(force ~= false)
    end,
    debug_process_region_refresh_queue = function(limit)
      storage_lib.ensure()
      return process_region_refresh_queue(limit, game.tick)
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
      enqueue_region_refresh_at_position(surface, snapshot.position, game.tick)
      enqueue_region_refresh_at_position(surface, result.position, game.tick)

      local incident = record_squirrel_incident(surface, snapshot.position, player.force, player.index, "relocation", game.tick, {
        destination_region_x = destination.region_x,
        destination_region_y = destination.region_y,
        destination_position = result.position,
        destination_forest_health = destination.forest_health,
        destination_squirrel_trust = destination.squirrel_trust,
        destination_habitat_pressure = destination.habitat_pressure,
        destination_tree_mass = destination.tree_mass,
        destination_score = destination.score
      })

      notify_relocation(player, squirrel_id, incident)
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

      local squirrel = find_squirrel_at_position(player.surface, {x = x, y = y})
      if not squirrel then
        return nil
      end

      local incident = handle_squirrel_rough_handling(squirrel, player, tick or game.tick)
      return incident and incident.incident_id or nil
    end,
    debug_get_squirrel_incidents = function(surface_index)
      storage_lib.ensure()
      local incidents = {}

      for _, incident in pairs(get_squirrel_incidents()) do
        if not surface_index or incident.surface_index == surface_index then
          incidents[#incidents + 1] = incident
        end
      end

      table.sort(incidents, function(left, right)
        return left.incident_id < right.incident_id
      end)

      return incidents
    end,
    debug_get_retaliation_state = function(surface_index, player_index)
      storage_lib.ensure()
      local state = get_retaliation_state(surface_index, player_index)
      prune_retaliation_state(state, game.tick)
      return state
    end,
    debug_get_retaliation_feedback = function(player_index)
      storage_lib.ensure()
      local entries = {}

      for _, entry in ipairs(get_squirrel_retaliation_feedback()) do
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
      return get_squirrel_step_feedback()
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
    debug_process_retaliation_feedback_expiry = function(tick)
      storage_lib.ensure()
      return process_retaliation_feedback_expiry(tick or game.tick)
    end,
    debug_process_retaliation_waves = function(tick)
      storage_lib.ensure()
      return process_retaliation_waves(tick or game.tick)
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
