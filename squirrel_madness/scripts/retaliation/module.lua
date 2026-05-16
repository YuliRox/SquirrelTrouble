local constants = require("scripts.constants")
local squirrels = require("scripts.squirrels")

local module = {}

local function get_squirrel_retaliation()
  storage.squirrel_retaliation = storage.squirrel_retaliation or {}
  return storage.squirrel_retaliation
end

local function get_squirrel_retaliation_feedback()
  storage.squirrel_retaliation_feedback = storage.squirrel_retaliation_feedback or {}
  return storage.squirrel_retaliation_feedback
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

local function station_distance_squared(position_a, position_b)
  local dx = position_a.x - position_b.x
  local dy = position_a.y - position_b.y
  return (dx * dx) + (dy * dy)
end

local function retaliation_state_key(surface_index, player_index)
  return surface_index .. ":" .. player_index
end

function module.get_state(surface_index, player_index)
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

function module.prune_state(state, tick)
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

function module.find_revenge_spawner(surface, position)
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

  return module.find_revenge_spawner(surface, source_position)
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

function module.process_waves(tick)
  local launched = 0
  local retaliation = get_squirrel_retaliation()

  for _, state in pairs(retaliation) do
    module.prune_state(state, tick)

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

local function destroy_feedback_pin(entry, player)
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
        local dx = candidate.position.x - entry.position.x
        local dy = candidate.position.y - entry.position.y
        local matches_position = (dx * dx) + (dy * dy) <= 1
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

function module.process_feedback_expiry(tick)
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

function module.notify_relocation(player, squirrel_id, incident)
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

function module.notify(surface, position, force, player_index, incident)
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

function module.storage()
  return get_squirrel_retaliation()
end

function module.storage_feedback()
  return get_squirrel_retaliation_feedback()
end

return module
