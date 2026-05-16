local constants = require("scripts.constants")
local relocation = require("scripts.relocation")
local regions = require("scripts.regions")
local squirrels = require("scripts.squirrels")

local squirrel_selection = {}

local SQUIRREL_SELECTION_HOLD_TICKS = constants.squirrel_selection_hold_ticks
local LOCK_REFRESH_INTERVAL_TICKS = 10
local LOCK_CLEAR_GRACE_TICKS = 20

local function get_overlays()
  storage.squirrel_selection_overlays = storage.squirrel_selection_overlays or {}
  return storage.squirrel_selection_overlays
end

local function get_panels()
  storage.squirrel_selection_panels = storage.squirrel_selection_panels or {}
  return storage.squirrel_selection_panels
end

local function get_locks()
  storage.squirrel_selection_locks = storage.squirrel_selection_locks or {}
  return storage.squirrel_selection_locks
end

local function force_has_technology(force, technology_name)
  if not (force and force.valid and force.technologies) then
    return false
  end

  local technology = force.technologies[technology_name]
  return technology and technology.valid and technology.researched
end

local function localized_squirrel_state(state)
  return {"gui.squirrel-madness-squirrel-state-" .. (state or "unknown")}
end

function squirrel_selection.current(player)
  local selected = player and player.valid and player.selected or nil

  if squirrels.is_squirrel_entity(selected) then
    return selected
  end

  return nil
end

function squirrel_selection.clear_lock(player_index)
  get_locks()[player_index] = nil
end

function squirrel_selection.clear_overlay(player_index)
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

function squirrel_selection.clear_all_overlays()
  local player_indices = {}

  for player_index in pairs(storage.squirrel_selection_overlays or {}) do
    player_indices[#player_indices + 1] = player_index
  end

  for _, player_index in ipairs(player_indices) do
    squirrel_selection.clear_overlay(player_index)
  end
end

function squirrel_selection.clear_panel(player_index)
  local player = game.get_player(player_index)
  if player and player.valid then
    local panel = player.gui.left["squirrel_madness_selected_squirrel_panel"]
    if panel and panel.valid then
      panel.destroy()
    end
  end

  get_panels()[player_index] = nil
end

function squirrel_selection.clear_entity(entity)
  if not (entity and entity.valid) then
    return
  end

  local overlays_to_clear = {}

  for player_index, overlay in pairs(get_overlays()) do
    if overlay.squirrel_unit_number == entity.unit_number and overlay.surface_index == entity.surface.index then
      overlays_to_clear[#overlays_to_clear + 1] = player_index
    end
  end

  for _, player_index in ipairs(overlays_to_clear) do
    squirrel_selection.clear_overlay(player_index)
    squirrel_selection.clear_panel(player_index)
  end
end

function squirrel_selection.reset()
  squirrel_selection.clear_all_overlays()

  local panel_player_indices = {}
  for player_index in pairs(storage.squirrel_selection_panels or {}) do
    panel_player_indices[#panel_player_indices + 1] = player_index
  end

  for _, player_index in ipairs(panel_player_indices) do
    squirrel_selection.clear_panel(player_index)
  end

  storage.squirrel_selection_locks = {}
  storage.squirrel_selection_overlays = {}
  storage.squirrel_selection_panels = {}
end

function squirrel_selection.clear_player(player)
  if not (player and player.valid) then
    return
  end

  squirrel_selection.clear_lock(player.index)
  squirrel_selection.clear_overlay(player.index)
  squirrel_selection.clear_panel(player.index)

  if squirrels.is_squirrel_entity(player.opened) then
    player.opened = nil
  end

  if squirrels.is_squirrel_entity(player.selected) then
    player.selected = nil
  end
end

function squirrel_selection.refresh(player, tick, from_lock_refresh)
  if not (player and player.valid) then
    return nil
  end

  local selected = player.selected
  local squirrel = squirrel_selection.current(player)

  if squirrel then
    local lock = get_locks()[player.index]
    local squirrel_id = squirrels.squirrel_id_for_entity(squirrel)
    local expires_tick = tick + SQUIRREL_SELECTION_HOLD_TICKS

    if
      lock
      and (
        from_lock_refresh
        or (lock.skip_extend_until_tick and tick <= lock.skip_extend_until_tick)
      )
      and lock.squirrel_id == squirrel_id
      and lock.squirrel_unit_number == squirrel.unit_number
      and lock.surface_index == squirrel.surface.index
    then
      lock.clear_candidate_tick = nil
      return squirrel
    end

    local next_refresh_tick = lock and lock.next_refresh_tick or tick
    get_locks()[player.index] = {
      squirrel_id = squirrel_id,
      squirrel_unit_number = squirrel.unit_number,
      surface_index = squirrel.surface.index,
      expires_tick = expires_tick,
      next_refresh_tick = next_refresh_tick,
      clear_candidate_tick = nil
    }
    return squirrel
  end

  local lock = get_locks()[player.index]
  if lock and (not selected or not selected.valid) and not squirrels.is_squirrel_entity(player.opened) then
    lock.clear_candidate_tick = lock.clear_candidate_tick or tick
    if tick >= (lock.clear_candidate_tick + LOCK_CLEAR_GRACE_TICKS) then
      squirrel_selection.clear_lock(player.index)
    end
    return nil
  end

  if lock and selected and selected.valid then
    lock.clear_candidate_tick = nil
  end

  if selected and selected.valid then
    if
      lock
      and player.opened
      and player.opened.valid
      and player.opened.unit_number
      and selected.unit_number
      and player.opened.unit_number == selected.unit_number
    then
      squirrel_selection.clear_lock(player.index)
      return nil
    end
  end

  if not lock or tick > lock.expires_tick then
    squirrel_selection.clear_lock(player.index)
    return nil
  end

  local locked = squirrels.entity_for_squirrel_id(lock.squirrel_id)
  if not (locked and locked.valid and squirrels.is_squirrel_entity(locked)) then
    squirrel_selection.clear_lock(player.index)
    return nil
  end

  local locked_surface = locked.surface
  if not (locked_surface and locked_surface.index == lock.surface_index) then
    squirrel_selection.clear_lock(player.index)
    return nil
  end

  if selected and selected.valid and selected.unit_number == locked.unit_number then
    return selected
  end

  lock.skip_extend_until_tick = tick + 1
  player.update_selected_entity(locked.position)

  local refreshed = squirrel_selection.current(player)
  if not (refreshed and refreshed.valid and refreshed.unit_number == locked.unit_number) then
    return nil
  end

  return refreshed
end

function squirrel_selection.refresh_locked(tick)
  for player_index, lock in pairs(get_locks()) do
    local player = game.get_player(player_index)
    if player and player.valid and lock then
      local selected = squirrel_selection.current(player)
      if selected and selected.unit_number == lock.squirrel_unit_number and selected.surface.index == lock.surface_index then
        -- Keep lock stable while directly selected, but do not force reselection every tick.
      elseif tick >= (lock.next_refresh_tick or 0) then
        squirrel_selection.refresh(player, tick, true)
        local refreshed_lock = get_locks()[player_index]
        if refreshed_lock then
          refreshed_lock.next_refresh_tick = tick + LOCK_REFRESH_INTERVAL_TICKS
        end
      end
    end
  end
end

function squirrel_selection.render_panel(player, squirrel, tick)
  squirrel_selection.clear_panel(player.index)

  if not (player and player.valid and squirrel and squirrel.valid) then
    return nil
  end

  local overlay_state = squirrels.selection_overlay_state(squirrel, tick)
  if not overlay_state then
    return nil
  end

  local report = regions.get_region_report_by_coord(
    squirrel.surface,
    overlay_state.region_x,
    overlay_state.region_y,
    tick or game.tick
  )
  local can_relocate = force_has_technology(player.force, constants.technologies.wildlife_relocation)
  local destination, candidates

  if can_relocate then
    destination, candidates = relocation.find_destination(squirrel.surface, squirrel.position, tick or game.tick)
  end

  local frame = player.gui.left.add({
    type = "frame",
    name = "squirrel_madness_selected_squirrel_panel",
    direction = "vertical",
    caption = {"entity-name.squirrel"}
  })
  frame.style.minimal_width = 300

  local content = frame.add({
    type = "flow",
    direction = "vertical"
  })
  content.style.vertical_spacing = 2

  content.add({
    type = "label",
    caption = {"gui.squirrel-madness-squirrel-panel-state", localized_squirrel_state(overlay_state.state)}
  })
  content.add({
    type = "label",
    caption = {"gui.squirrel-madness-squirrel-panel-home", overlay_state.region_x, overlay_state.region_y}
  })
  content.add({
    type = "label",
    caption = {
      "gui.squirrel-madness-squirrel-panel-pressure",
      report.habitat_pressure,
      {"message.squirrel-madness-band-" .. report.habitat_pressure_band}
    }
  })

  if not can_relocate then
    content.add({
      type = "label",
      caption = {"gui.squirrel-madness-squirrel-panel-relocation-locked"}
    })
  elseif not destination then
    content.add({
      type = "label",
      caption = {"gui.squirrel-madness-squirrel-panel-relocation-none"}
    })
  else
    content.add({
      type = "label",
      caption = {"gui.squirrel-madness-squirrel-panel-relocation-ready", destination.region_x, destination.region_y}
    })
    content.add({
      type = "label",
      caption = {
        "gui.squirrel-madness-squirrel-panel-relocation-destination",
        destination.forest_health,
        destination.squirrel_trust,
        destination.habitat_pressure,
        destination.tree_mass
      }
    })
    content.add({
      type = "label",
      caption = {"gui.squirrel-madness-squirrel-panel-relocation-candidates", #candidates}
    })
  end

  get_panels()[player.index] = {
    squirrel_unit_number = squirrel.unit_number,
    surface_index = squirrel.surface.index,
    region_x = overlay_state.region_x,
    region_y = overlay_state.region_y,
    state = overlay_state.state,
    habitat_pressure = report.habitat_pressure,
    habitat_pressure_band = report.habitat_pressure_band,
    relocation_available = can_relocate and destination ~= nil or false,
    relocation_locked = not can_relocate,
    relocation_region_x = destination and destination.region_x or nil,
    relocation_region_y = destination and destination.region_y or nil,
    relocation_forest_health = destination and destination.forest_health or nil,
    relocation_squirrel_trust = destination and destination.squirrel_trust or nil,
    relocation_habitat_pressure = destination and destination.habitat_pressure or nil,
    relocation_tree_mass = destination and destination.tree_mass or nil,
    relocation_candidate_count = candidates and #candidates or 0
  }

  return get_panels()[player.index]
end

function squirrel_selection.render_overlay(player, squirrel, tick)
  squirrel_selection.clear_overlay(player.index)

  if not constants.debug_squirrel_selection_overlay then
    return nil
  end

  if not (player and player.valid and squirrel and squirrel.valid) then
    return nil
  end

  local overlay_state = squirrels.selection_overlay_state(squirrel, tick)
  if not overlay_state then
    return nil
  end

  local render_ids = {}

  local fill_circle = rendering.draw_circle({
    color = {r = 0.95, g = 0.49, b = 0.12, a = 0.11},
    radius = overlay_state.local_radius,
    filled = true,
    target = squirrel,
    surface = squirrel.surface,
    players = {player.index},
    draw_on_ground = true
  })
  render_ids[#render_ids + 1] = fill_circle.id

  local belt_interest_circle = rendering.draw_circle({
    color = {r = 0.95, g = 0.18, b = 0.12, a = 0.95},
    radius = overlay_state.belt_interest_radius,
    width = 2,
    filled = false,
    target = squirrel,
    surface = squirrel.surface,
    players = {player.index},
    draw_on_ground = true
  })
  render_ids[#render_ids + 1] = belt_interest_circle.id

  get_overlays()[player.index] = {
    squirrel_unit_number = squirrel.unit_number,
    surface_index = squirrel.surface.index,
    render_ids = render_ids,
    local_radius = overlay_state.local_radius,
    belt_interest_radius = overlay_state.belt_interest_radius,
    state = overlay_state.state,
    last_refresh_tick = tick or game.tick
  }

  return overlay_state
end

function squirrel_selection.refresh_all(tick)
  if not constants.debug_squirrel_selection_overlay then
    return
  end

  local overlays_to_clear = {}

  for player_index, overlay in pairs(get_overlays()) do
    local player = game.get_player(player_index)
    local selected_squirrel = player and squirrel_selection.current(player) or nil

    if not selected_squirrel
      or selected_squirrel.unit_number ~= overlay.squirrel_unit_number
      or selected_squirrel.surface.index ~= overlay.surface_index
    then
      overlays_to_clear[#overlays_to_clear + 1] = player_index
    else
      squirrel_selection.render_overlay(player, selected_squirrel, tick)
    end
  end

  for _, player_index in ipairs(overlays_to_clear) do
    squirrel_selection.clear_overlay(player_index)
    squirrel_selection.clear_panel(player_index)
  end
end

function squirrel_selection.panel_state(player_index)
  return get_panels()[player_index]
end

function squirrel_selection.overlay_state(player_index)
  local overlay = get_overlays()[player_index]
  if not overlay then
    return nil
  end

  return {
    squirrel_unit_number = overlay.squirrel_unit_number,
    surface_index = overlay.surface_index,
    local_radius = overlay.local_radius,
    belt_interest_radius = overlay.belt_interest_radius,
    state = overlay.state,
    render_count = #overlay.render_ids
  }
end

function squirrel_selection.lock_state(player_index)
  return get_locks()[player_index]
end

return squirrel_selection
