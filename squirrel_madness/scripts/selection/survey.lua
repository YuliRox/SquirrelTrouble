local constants = require("scripts.constants")
local math2d = require("math2d")
local regions = require("scripts.regions")
local technologies = require("scripts.util.technologies")

local survey = {}

local function get_overlays()
  storage.survey_station_overlays = storage.survey_station_overlays or {}
  return storage.survey_station_overlays
end

local function get_panels()
  storage.survey_station_panels = storage.survey_station_panels or {}
  return storage.survey_station_panels
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

local function print_cluster_report(player, cluster)
  player.print({
    "message.squirrel-madness-cluster-report",
    cluster.forest_health,
    {"message.squirrel-madness-band-" .. cluster.forest_health_band},
    cluster.squirrel_unrest,
    {"message.squirrel-madness-band-" .. cluster.squirrel_unrest_band},
    cluster.squirrel_trust,
    {"message.squirrel-madness-band-" .. cluster.squirrel_trust_band},
    cluster.habitat_pressure,
    {"message.squirrel-madness-band-" .. cluster.habitat_pressure_band}
  })
  player.print({
    "message.squirrel-madness-region-factors",
    cluster.tree_count,
    cluster.sapling_count,
    cluster.nut_tree_count,
    cluster.stocked_feeders,
    cluster.feeder_count,
    cluster.recent_tree_loss,
    cluster.rolling_pollution
  })
  player.print({
    "message.squirrel-madness-region-forces",
    cluster.canopy_score,
    cluster.nut_tree_bonus,
    cluster.stocked_feeder_bonus,
    cluster.reforestation_bonus,
    cluster.empty_feeder_penalty,
    cluster.recent_tree_loss_penalty,
    cluster.rolling_pollution_penalty
  })
end


local function survey_panel_driver_labels(cluster)
  local labels = {}

  for _, driver in ipairs(cluster.drivers or {}) do
    labels[#labels + 1] = localized_driver(driver)
  end

  return join_localized_labels(labels)
end

function survey.is_powered_station(entity)
  return entity
    and entity.valid
    and entity.name == constants.names.survey_station
    and entity.energy
    and entity.energy > 0
end

function survey.find_nearest_station(surface, position, radius)
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
      local distance = math2d.position.distance_squared(position, station.position)
      if not nearest or distance < nearest_distance then
        nearest = station
        nearest_distance = distance
      end
    end
  end

  return nearest
end

function survey.current(player)
  local selected = player and player.valid and player.selected or nil

  if selected and selected.valid and selected.name == constants.names.survey_station then
    return selected
  end

  return nil
end

function survey.clear_overlay(player_index)
  local overlays = get_overlays()
  local overlay = overlays[player_index]

  if not overlay then
    return false
  end

  for _, render_id in ipairs(overlay.render_ids or {}) do
    local render_object = rendering.get_object_by_id(render_id)
    if render_object and render_object.valid then
      render_object.destroy()
    end
  end

  overlays[player_index] = nil
  return true
end

function survey.clear_panel(player_index)
  local player = game.get_player(player_index)
  if player and player.valid then
    local panel = player.gui.left["squirrel_madness_survey_station_panel"]
    if panel and panel.valid then
      panel.destroy()
    end
  end

  get_panels()[player_index] = nil
end

function survey.clear_entity(entity)
  if not (entity and entity.valid) then
    return
  end

  local overlays_to_clear = {}

  for player_index, overlay in pairs(get_overlays()) do
    if overlay.station_unit_number == entity.unit_number and overlay.surface_index == entity.surface.index then
      overlays_to_clear[#overlays_to_clear + 1] = player_index
    end
  end

  for _, player_index in ipairs(overlays_to_clear) do
    survey.clear_overlay(player_index)
    survey.clear_panel(player_index)
  end
end

function survey.clear_all()
  local overlay_player_indices = {}
  for player_index in pairs(storage.survey_station_overlays or {}) do
    overlay_player_indices[#overlay_player_indices + 1] = player_index
  end

  for _, player_index in ipairs(overlay_player_indices) do
    survey.clear_overlay(player_index)
  end

  local panel_player_indices = {}
  for player_index in pairs(storage.survey_station_panels or {}) do
    panel_player_indices[#panel_player_indices + 1] = player_index
  end

  for _, player_index in ipairs(panel_player_indices) do
    survey.clear_panel(player_index)
  end

  storage.survey_station_overlays = {}
  storage.survey_station_panels = {}
end

function survey.render_panel(player, station, cluster)
  survey.clear_panel(player.index)

  if not (player and player.valid and station and station.valid) then
    return nil
  end

  local powered = survey.is_powered_station(station)
  local frame = player.gui.left.add({
    type = "frame",
    name = "squirrel_madness_survey_station_panel",
    direction = "vertical",
    caption = {"entity-name.forest-survey-station"}
  })
  frame.style.minimal_width = 280

  local content = frame.add({
    type = "flow",
    direction = "vertical"
  })
  content.style.vertical_spacing = 2

  content.add({
    type = "label",
    caption = powered
      and {"gui.squirrel-madness-survey-panel-status-working"}
      or {"gui.squirrel-madness-survey-panel-status-unpowered"}
  })

  if not cluster then
    content.add({
      type = "label",
      caption = {"gui.squirrel-madness-survey-panel-no-data"}
    })
  else
    content.add({
      type = "label",
      caption = {"gui.squirrel-madness-survey-panel-footprint"}
    })
    content.add({
      type = "label",
      caption = {"gui.squirrel-madness-survey-panel-health", cluster.forest_health, {"message.squirrel-madness-band-" .. cluster.forest_health_band}}
    })
    content.add({
      type = "label",
      caption = {"gui.squirrel-madness-survey-panel-unrest", cluster.squirrel_unrest, {"message.squirrel-madness-band-" .. cluster.squirrel_unrest_band}}
    })
    content.add({
      type = "label",
      caption = {"gui.squirrel-madness-survey-panel-trust", cluster.squirrel_trust, {"message.squirrel-madness-band-" .. cluster.squirrel_trust_band}}
    })
    content.add({
      type = "label",
      caption = {"gui.squirrel-madness-survey-panel-pressure", cluster.habitat_pressure, {"message.squirrel-madness-band-" .. cluster.habitat_pressure_band}}
    })
    content.add({
      type = "label",
      caption = {"gui.squirrel-madness-survey-panel-observed", cluster.tree_count, cluster.nut_tree_count, cluster.sapling_count}
    })
    content.add({
      type = "label",
      caption = {"gui.squirrel-madness-survey-panel-feeders", cluster.stocked_feeders, cluster.feeder_count}
    })
    content.add({
      type = "label",
      caption = {"gui.squirrel-madness-survey-panel-forces", survey_panel_driver_labels(cluster)}
    })
  end

  get_panels()[player.index] = {
    station_unit_number = station.unit_number,
    surface_index = station.surface.index,
    powered = powered,
    region_count = cluster and cluster.region_count or 0,
    tree_count = cluster and cluster.tree_count or 0,
    forest_health = cluster and cluster.forest_health or nil,
    squirrel_unrest = cluster and cluster.squirrel_unrest or nil,
    squirrel_trust = cluster and cluster.squirrel_trust or nil,
    habitat_pressure = cluster and cluster.habitat_pressure or nil
  }

  return frame
end

function survey.render_overlay(player, station, tick)
  survey.clear_overlay(player.index)

  if not (player and player.valid and station and station.valid) then
    return nil
  end

  local cluster = regions.get_forest_cluster_report_at_position(station.surface, station.position, tick)
  local render_ids = {}

  local footprint = rendering.draw_circle({
    color = {r = 0.18, g = 0.42, b = 0.22, a = 0.14},
    radius = constants.survey_station_exact_radius,
    filled = true,
    target = station,
    surface = station.surface,
    players = {player.index},
    draw_on_ground = true
  })
  render_ids[#render_ids + 1] = footprint.id

  local station_marker = rendering.draw_circle({
    color = {r = 0.82, g = 0.94, b = 0.28, a = 0.95},
    radius = 1.2,
    width = 2,
    filled = false,
    target = station,
    surface = station.surface,
    players = {player.index},
    draw_on_ground = true
  })
  render_ids[#render_ids + 1] = station_marker.id

  local station_range = rendering.draw_circle({
    color = {r = 0.52, g = 0.86, b = 0.68, a = 0.9},
    radius = constants.survey_station_exact_radius,
    width = 2,
    filled = false,
    target = station,
    surface = station.surface,
    players = {player.index},
    draw_on_ground = true
  })
  render_ids[#render_ids + 1] = station_range.id

  get_overlays()[player.index] = {
    station_unit_number = station.unit_number,
    surface_index = station.surface.index,
    render_ids = render_ids,
    region_count = cluster.region_count,
    member_regions = cluster.member_regions,
    exact_radius = constants.survey_station_exact_radius,
    last_refresh_tick = tick or game.tick
  }

  return cluster
end

function survey.update_for_player(player, selected_entity, tick)
  if not (player and player.valid) then
    return nil
  end

  local station = selected_entity
  if not station or not station.valid then
    station = survey.current(player)
  end

  if station then
    local cluster = survey.render_overlay(player, station, tick)
    survey.render_panel(player, station, cluster)
    return cluster
  end

  survey.clear_overlay(player.index)
  survey.clear_panel(player.index)
  return nil
end

function survey.resolve_request(force, surface, position, selected_entity)
  if not technologies.force_has_technology(force, constants.technologies.forest_surveying) then
    return {
      mode = "research-required",
      anchor_position = position
    }
  end

  if selected_entity and selected_entity.valid and selected_entity.name == constants.names.survey_station then
    return {
      mode = survey.is_powered_station(selected_entity) and "exact" or "power-required",
      anchor_position = selected_entity.position,
      station = selected_entity,
      source = "selected"
    }
  end

  local station = survey.find_nearest_station(surface, position, constants.survey_station_exact_radius)
  if station then
    return {
      mode = survey.is_powered_station(station) and "exact" or "power-required",
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

function survey.print_result(player, result)
  if result.mode == "research-required" then
    player.print({"message.squirrel-madness-forest-surveying-required"})
    return
  end

  if result.mode == "exact" then
    print_cluster_report(player, regions.get_forest_cluster_report_at_position(player.surface, result.anchor_position, game.tick))
    return
  end

  local region = regions.get_region_report_at_position(player.surface, result.anchor_position, game.tick)
  print_broad_region_report(player, region)

  if result.mode == "power-required" then
    player.print({"message.squirrel-madness-survey-power-required"})
  else
    player.print({"message.squirrel-madness-survey-exact-hint"})
  end
end

function survey.run_for_player(player)
  if not (player and player.valid and player.surface) then
    return
  end

  local result = survey.resolve_request(player.force, player.surface, player.position, player.selected)
  survey.print_result(player, result)
end

function survey.refresh_all(tick)
  local overlays_to_clear = {}

  for player_index, overlay in pairs(get_overlays()) do
    local player = game.get_player(player_index)
    local selected_station = player and survey.current(player) or nil

    if not selected_station
      or selected_station.unit_number ~= overlay.station_unit_number
      or selected_station.surface.index ~= overlay.surface_index
    then
      overlays_to_clear[#overlays_to_clear + 1] = player_index
    else
      survey.render_overlay(player, selected_station, tick)
      survey.render_panel(
        player,
        selected_station,
        regions.get_forest_cluster_report_at_position(selected_station.surface, selected_station.position, tick)
      )
    end
  end

  for _, player_index in ipairs(overlays_to_clear) do
    survey.clear_overlay(player_index)
    survey.clear_panel(player_index)
  end
end

function survey.overlay_state(player_index)
  local overlay = get_overlays()[player_index]
  if not overlay then
    return nil
  end

  return {
    station_unit_number = overlay.station_unit_number,
    surface_index = overlay.surface_index,
    render_count = #overlay.render_ids,
    region_count = overlay.region_count,
    member_regions = overlay.member_regions,
    exact_radius = overlay.exact_radius
  }
end

function survey.panel_state(player_index)
  return get_panels()[player_index]
end

return survey
