local constants = require("scripts.constants")
local math2d = require("math2d")

local M = {}

function M.install(deps)
  local clone_position = deps.clone_position
  local player_position_for_index = deps.player_position_for_index
  local position_with_offset = deps.position_with_offset
  local ensure_entity_variant = deps.ensure_entity_variant
  local clear_belt_ride = deps.clear_belt_ride
  local set_excursion_focus = deps.set_excursion_focus
  local stop_entity = deps.stop_entity
  local sync_render = deps.sync_render
  local move_entity = deps.move_entity

  local function squirrel_fear_is_active(record, tick)
    return record and record.fear_until_tick and tick < record.fear_until_tick
  end

  local function clear_squirrel_fear(record)
    if not record then
      return
    end

    record.feared_player_index = nil
    record.fear_until_tick = nil
    record.fear_position = nil
    record.flee_goal_position = nil
  end

  local function current_fear_position(record, tick)
    if not squirrel_fear_is_active(record, tick) then
      clear_squirrel_fear(record)
      return nil
    end

    local player_position = player_position_for_index(record.surface_index, record.feared_player_index)
    if player_position then
      record.fear_position = clone_position(player_position)
    end

    return record.fear_position and clone_position(record.fear_position) or nil
  end

  local function set_squirrel_fear(record, player, tick)
    if not (record and player and player.valid) then
      return nil
    end

    record.feared_player_index = player.index
    record.fear_until_tick = tick + constants.squirrel_fear_duration
    record.fear_position = clone_position(player.position)
    return record.fear_until_tick
  end

  local function reset_flee_progress(record, entity, tick)
    if not record then
      return
    end

    record.flee_last_progress_tick = tick
    record.flee_last_progress_position = entity and entity.valid and clone_position(entity.position) or nil
  end

  local function normalized_direction(from_position, to_position)
    local dx = to_position.x - from_position.x
    local dy = to_position.y - from_position.y
    local length = math.sqrt((dx * dx) + (dy * dy))

    if length < 0.01 then
      return nil
    end

    return {
      x = dx / length,
      y = dy / length
    }
  end

  local function compute_flee_goal_position(record, entity, avoid_position)
    local origin = (entity and entity.valid and entity.position) or record.home_position
    local home_direction = normalized_direction(origin, record.home_position)
    local player_away_direction = normalized_direction(avoid_position, origin)
    local preferred_direction = home_direction or player_away_direction
    local goal_distance = constants.squirrel_flee_goal_distance

    if not preferred_direction then
      local angle = ((((record.squirrel_id or 1) * 67) + ((record.roam_step or 0) * 31)) % 360) * (math.pi / 180)
      preferred_direction = {
        x = math.cos(angle),
        y = math.sin(angle)
      }
    end

    local goal = {
      x = origin.x + (preferred_direction.x * goal_distance),
      y = origin.y + (preferred_direction.y * goal_distance)
    }

    if math2d.position.distance_squared(goal, avoid_position) < (constants.squirrel_flee_min_distance_from_player ^ 2) then
      local away_direction = player_away_direction or preferred_direction
      goal = {
        x = avoid_position.x + (away_direction.x * constants.squirrel_flee_min_distance_from_player),
        y = avoid_position.y + (away_direction.y * constants.squirrel_flee_min_distance_from_player)
      }
    end

    return goal
  end

  local function flee_goal_position(record, entity, avoid_position)
    if not record then
      return nil
    end

    local current_goal = record.flee_goal_position
    if current_goal and avoid_position then
      if math2d.position.distance_squared(current_goal, avoid_position) >= (constants.squirrel_flee_min_distance_from_player ^ 2) then
        return clone_position(current_goal)
      end
    elseif current_goal then
      return clone_position(current_goal)
    end

    local computed_goal = compute_flee_goal_position(record, entity, avoid_position)
    record.flee_goal_position = computed_goal and clone_position(computed_goal) or nil
    return computed_goal
  end

  local function flee_destination(record, entity, avoid_position)
    local origin = (entity and entity.valid and entity.position) or record.home_position
    local goal = flee_goal_position(record, entity, avoid_position)
    local goal_direction = normalized_direction(origin, goal)

    if not goal_direction then
      return nil
    end

    local base_angle = math.atan2(goal_direction.y, goal_direction.x)
    local surface = game.surfaces[record.surface_index]
    local candidate_offsets = {0, 0.35, -0.35, 0.7, -0.7, 1.05, -1.05, 1.4, -1.4}
    local best_candidate
    local best_score

    for _, angle_offset in ipairs(candidate_offsets) do
      local angle = base_angle + angle_offset
      local candidate = position_with_offset(origin, angle, constants.squirrel_flee_step_distance)

      if surface then
        local resolved = surface.find_non_colliding_position(constants.names.squirrel, candidate, 1.5, 0.25, true)
        if
          resolved
          and math2d.position.distance_squared(resolved, avoid_position) > math2d.position.distance_squared(origin, avoid_position)
          and math2d.position.distance_squared(resolved, origin) >= (constants.squirrel_flee_min_step_distance ^ 2)
        then
          local score = math2d.position.distance_squared(resolved, goal)
          if not best_candidate or score < best_score then
            best_candidate = resolved
            best_score = score
          end
        end
      else
        return candidate
      end
    end

    return best_candidate
  end

  local function flee_is_stuck(record, entity, tick)
    if not (record and entity and entity.valid and record.mode == "flee") then
      return false
    end

    local last_position = record.flee_last_progress_position
    if not last_position then
      reset_flee_progress(record, entity, tick)
      return false
    end

    if math2d.position.distance_squared(entity.position, last_position) >= (constants.squirrel_flee_progress_distance ^ 2) then
      reset_flee_progress(record, entity, tick)
      return false
    end

    return tick >= ((record.flee_last_progress_tick or tick) + constants.squirrel_flee_stuck_ticks)
  end

  local function start_flee(record, entity, tick, avoid_position)
    entity = ensure_entity_variant(record, constants.names.squirrel) or entity
    clear_belt_ride(record)
    record.roam_step = (record.roam_step or 0) + 1
    record.mode = "flee"
    record.intent = nil
    record.target = nil
    set_excursion_focus(record, nil, nil)
    record.feeder_nibbles_remaining = nil
    record.destination = flee_destination(record, entity, avoid_position)
    record.arrival_distance = 0.6
    record.blocking_until_tick = nil
    record.action_due_tick = math.min(
      tick + constants.squirrel_flee_repath_interval,
      record.fear_until_tick or (tick + constants.squirrel_flee_repath_interval)
    )
    record.next_decision_tick = record.action_due_tick
    reset_flee_progress(record, entity, tick)
    if not record.destination then
      stop_entity(entity)
      sync_render(record, entity)
      return
    end

    move_entity(entity, record.destination)
    sync_render(record, entity)
  end

  return {
    squirrel_fear_is_active = squirrel_fear_is_active,
    clear_squirrel_fear = clear_squirrel_fear,
    current_fear_position = current_fear_position,
    set_squirrel_fear = set_squirrel_fear,
    flee_is_stuck = flee_is_stuck,
    start_flee = start_flee
  }
end

return M
