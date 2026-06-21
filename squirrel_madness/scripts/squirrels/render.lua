local M = {}

function M.direction_to_orientation(direction)
  if direction == defines.direction.east then
    return 0.25
  end
  if direction == defines.direction.south then
    return 0.5
  end
  if direction == defines.direction.west then
    return 0.75
  end
  return 0
end

function M.destroy_render(record)
  if record.render_id then
    record.render_id.destroy()
  end

  if record.render_count_id then
    record.render_count_id.destroy()
  end

  record.render_id = nil
  record.render_count_id = nil
end

function M.sync_render(record, entity)
  M.destroy_render(record)

  if not (record.carrying and record.carrying.name and entity and entity.valid) then
    return
  end

  local sprite = "item/" .. record.carrying.name
  local render_id = rendering.draw_sprite({
    sprite = sprite,
    target = {
      entity = entity,
      offset = {0, -0.9}
    },
    surface = entity.surface,
    x_scale = 0.55,
    y_scale = 0.55,
    render_layer = "higher-object-under"
  })

  if render_id then
    record.render_id = render_id
  else
    record.render_id = rendering.draw_sprite({
      sprite = "utility/questionmark",
      target = {
        entity = entity,
        offset = {0, -0.9}
      },
      surface = entity.surface,
      x_scale = 0.55,
      y_scale = 0.55,
      render_layer = "higher-object-under"
    })
  end

  record.render_count_id = rendering.draw_text({
    text = tostring(record.carrying.count or 0),
    target = {
      entity = entity,
      offset = {0.45, -0.95}
    },
    surface = entity.surface,
    color = {r = 1, g = 1, b = 1, a = 1},
    scale = 1.0,
    alignment = "center",
    vertical_alignment = "middle",
    use_rich_text = false
  })
end

return M
