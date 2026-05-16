local constants = require("scripts.constants")
local feeders = require("scripts.feeders")

local feeder_selection = {}
local feeder_selection_overlays = {}

local function get_overlays()
  return feeder_selection_overlays
end

function feeder_selection.reset()
  for player_index in pairs(feeder_selection_overlays) do
    feeder_selection.clear_overlay(player_index)
  end

  feeder_selection_overlays = {}
end

function feeder_selection.current(player)
  local selected = player and player.valid and player.selected or nil

  if selected and selected.valid and feeders.is_feeder_entity(selected) then
    return selected
  end

  return nil
end

function feeder_selection.clear_overlay(player_index)
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

function feeder_selection.render_overlay(player, feeder)
  feeder_selection.clear_overlay(player.index)

  if not (player and player.valid and feeder and feeder.valid and feeders.is_feeder_entity(feeder)) then
    return nil
  end

  local state = feeders.debug_state(feeder.surface.index, feeder.position)
  if not state then
    return nil
  end

  local stocked = state.stocked
  local fill_color = stocked
      and {r = 0.34, g = 0.74, b = 0.22, a = 0.11}
    or {r = 0.72, g = 0.44, b = 0.16, a = 0.09}
  local outline_color = stocked
      and {r = 0.64, g = 0.92, b = 0.28, a = 0.95}
    or {r = 0.92, g = 0.62, b = 0.24, a = 0.95}

  local render_ids = {}

  local fill_circle = rendering.draw_circle({
    color = fill_color,
    radius = constants.squirrel_feeder_peace_radius,
    filled = true,
    target = feeder,
    surface = feeder.surface,
    players = {player.index},
    draw_on_ground = true
  })
  render_ids[#render_ids + 1] = fill_circle.id

  local range_circle = rendering.draw_circle({
    color = outline_color,
    radius = constants.squirrel_feeder_peace_radius,
    width = 2,
    filled = false,
    target = feeder,
    surface = feeder.surface,
    players = {player.index},
    draw_on_ground = true
  })
  render_ids[#render_ids + 1] = range_circle.id

  get_overlays()[player.index] = {
    feeder_unit_number = feeder.unit_number,
    surface_index = feeder.surface.index,
    stocked = stocked,
    radius = constants.squirrel_feeder_peace_radius,
    render_ids = render_ids
  }

  return state
end

function feeder_selection.refresh_all()
  local overlays_to_clear = {}

  for player_index, overlay in pairs(get_overlays()) do
    local player = game.get_player(player_index)
    local selected_feeder = player and feeder_selection.current(player) or nil

    if not selected_feeder
      or selected_feeder.unit_number ~= overlay.feeder_unit_number
      or selected_feeder.surface.index ~= overlay.surface_index
    then
      overlays_to_clear[#overlays_to_clear + 1] = player_index
    else
      feeder_selection.render_overlay(player, selected_feeder)
    end
  end

  for _, player_index in ipairs(overlays_to_clear) do
    feeder_selection.clear_overlay(player_index)
  end
end

function feeder_selection.overlay_state(player_index)
  local overlay = get_overlays()[player_index]
  if not overlay then
    return nil
  end

  return {
    feeder_unit_number = overlay.feeder_unit_number,
    surface_index = overlay.surface_index,
    stocked = overlay.stocked,
    radius = overlay.radius,
    render_count = #overlay.render_ids
  }
end

return feeder_selection
