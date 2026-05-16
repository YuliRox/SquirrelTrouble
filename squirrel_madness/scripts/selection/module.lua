local constants = require("scripts.constants")
local feeder = require("scripts.selection.feeder")
local squirrel = require("scripts.selection.squirrel")
local survey = require("scripts.selection.survey")

local selection = {
  feeder = feeder,
  squirrel = squirrel,
  survey = survey
}

function selection.reset()
  survey.clear_all()
  feeder.reset()
  squirrel.reset()
end

function selection.update_for_player(player, tick)
  if not (player and player.valid) then
    return nil
  end

  local restored_squirrel = squirrel.refresh(player, tick)

  local station = survey.current(player)
  if station then
    feeder.clear_overlay(player.index)
    squirrel.clear_overlay(player.index)
    squirrel.clear_panel(player.index)
    survey.update_for_player(player, station, tick)
    return "survey-station"
  end

  local selected_feeder = feeder.current(player)
  if selected_feeder then
    survey.clear_overlay(player.index)
    survey.clear_panel(player.index)
    squirrel.clear_overlay(player.index)
    squirrel.clear_panel(player.index)
    feeder.render_overlay(player, selected_feeder)
    return "feeder"
  end

  local selected_squirrel = restored_squirrel or squirrel.current(player)
  if selected_squirrel then
    survey.clear_overlay(player.index)
    survey.clear_panel(player.index)
    feeder.clear_overlay(player.index)
    local panel = squirrel.panel_state(player.index)
    if not panel
      or panel.squirrel_unit_number ~= selected_squirrel.unit_number
      or panel.surface_index ~= selected_squirrel.surface.index
    then
      squirrel.render_panel(player, selected_squirrel, tick)
    end
    if constants.debug_squirrel_selection_overlay then
      squirrel.render_overlay(player, selected_squirrel, tick)
      return "squirrel"
    end

    squirrel.clear_overlay(player.index)
    return nil
  end

  survey.clear_overlay(player.index)
  survey.clear_panel(player.index)
  feeder.clear_overlay(player.index)
  squirrel.clear_overlay(player.index)
  squirrel.clear_panel(player.index)
  return nil
end

function selection.refresh_locked_squirrel_selections(tick)
  squirrel.refresh_locked(tick)
end

function selection.refresh_overlays(tick)
  if not constants.debug_squirrel_selection_overlay then
    squirrel.clear_all_overlays()
  end

  if tick % constants.survey_overlay_refresh_interval ~= 0 then
    return
  end

  survey.refresh_all(tick)
  feeder.refresh_all()
  squirrel.refresh_all(tick)
end

return selection
