local function clone_container(source_name, name)
  local source = data.raw.container[source_name]
  if not source then
    error("Expected base container prototype " .. source_name .. " to exist")
  end

  local prototype = table.deepcopy(source)
  prototype.name = name
  prototype.minable = prototype.minable or {}
  prototype.minable.result = name
  return prototype
end

local function feeder_picture(filename, shadow_filename, width, height, shadow_width, shadow_height, shadow_shift_x, shadow_shift_y)
  return {
    layers = {
      {
        filename = filename,
        priority = "extra-high",
        width = width,
        height = height,
        shift = util.by_pixel(0.5, -2),
        scale = 0.5
      },
      {
        filename = shadow_filename,
        priority = "extra-high",
        width = shadow_width,
        height = shadow_height,
        shift = util.by_pixel(shadow_shift_x, shadow_shift_y),
        draw_as_shadow = true,
        scale = 0.5
      }
    }
  }
end

local function create_survey_station()
  local source = data.raw.radar and data.raw.radar["radar"]
  if not source then
    error("Expected base radar prototype to exist")
  end

  local prototype = table.deepcopy(source)

  prototype.name = "forest-survey-station"
  prototype.icon = "__squirrel_madness__/graphics/icons/forest-survey-station.png"
  prototype.icon_size = 64
  prototype.icons = nil
  prototype.minable = {mining_time = 0.2, result = "forest-survey-station"}
  prototype.fast_replaceable_group = nil
  prototype.localised_name = {"entity-name.forest-survey-station"}
  prototype.localised_description = {"entity-description.forest-survey-station"}
  prototype.energy_usage = "60kW"
  prototype.energy_per_sector = "1J"
  prototype.energy_per_nearby_scan = "1J"
  prototype.max_distance_of_sector_revealed = 0
  prototype.max_distance_of_nearby_sector_revealed = 0
  prototype.radius_minimap_visualisation_color = {0, 0, 0, 0}
  prototype.working_sound = nil
  prototype.open_sound = nil
  prototype.close_sound = nil
  prototype.integration_patch = nil
  prototype.rotation_speed = 0
  prototype.pictures = {
    layers = {
      {
        filename = "__squirrel_madness__/graphics/entities/structures/forest-survey-station/radio-station-hr-animation-1.png",
        priority = "low",
        width = 160,
        height = 290,
        direction_count = 1,
        frame_count = 20,
        line_length = 8,
        apply_projection = false,
        shift = util.by_pixel(0, -36),
        scale = 0.5,
        animation_speed = 0.2
      },
      {
        filename = "__squirrel_madness__/graphics/entities/structures/forest-survey-station/radio-station-hr-emission-1.png",
        priority = "low",
        width = 160,
        height = 290,
        direction_count = 1,
        frame_count = 20,
        line_length = 8,
        apply_projection = false,
        shift = util.by_pixel(0, -36),
        scale = 0.5,
        animation_speed = 0.2,
        draw_as_glow = true,
        blend_mode = "additive"
      },
      {
        filename = "__squirrel_madness__/graphics/entities/structures/forest-survey-station/radio-station-hr-shadow.png",
        priority = "low",
        width = 400,
        height = 350,
        direction_count = 1,
        apply_projection = false,
        shift = util.by_pixel(24, 16),
        draw_as_shadow = true,
        scale = 0.5
      }
    }
  }

  return prototype
end

local function clone_tree(source_name, new_name)
  local source = data.raw.tree and data.raw.tree[source_name]
  if not source then
    error("Expected base tree prototype " .. source_name .. " to exist")
  end

  local prototype = table.deepcopy(source)
  prototype.name = new_name
  prototype.localised_name = {"entity-name." .. new_name}
  prototype.localised_description = {"entity-description." .. new_name}
  prototype.autoplace = nil
  prototype.order = "a[tree]-z[" .. new_name .. "]"
  return prototype
end

local function clone_unit(source_name, new_name)
  local source = data.raw.unit and data.raw.unit[source_name]
  if not source then
    error("Expected base unit prototype " .. source_name .. " to exist")
  end

  local prototype = table.deepcopy(source)
  prototype.name = new_name
  prototype.localised_name = {"entity-name." .. new_name}
  prototype.localised_description = {"entity-description." .. new_name}
  prototype.autoplace = nil
  prototype.order = "b[animal]-a[" .. new_name .. "]"
  return prototype
end

local feeder = clone_container("wooden-chest", "squirrel-feeder")
feeder.icon = "__squirrel_madness__/graphics/icons/wooden-feeder-icon.png"
feeder.icon_size = 64
feeder.inventory_size = 1
feeder.fast_replaceable_group = nil
feeder.icon_draw_specification = {scale = 0, scale_for_many = 0}
feeder.localised_description = {"entity-description.squirrel-feeder"}
feeder.picture = feeder_picture(
  "__squirrel_madness__/graphics/entities/structures/wooden-feeder.png",
  "__squirrel_madness__/graphics/entities/structures/wooden-feeder-shadow.png",
  62,
  72,
  104,
  40,
  10,
  6.5
)

local empty_feeder = clone_container("wooden-chest", "squirrel-feeder-empty")
empty_feeder.icon = "__squirrel_madness__/graphics/icons/wooden-feeder-icon.png"
empty_feeder.icon_size = 64
empty_feeder.inventory_size = 1
empty_feeder.fast_replaceable_group = nil
empty_feeder.icon_draw_specification = {scale = 0, scale_for_many = 0}
empty_feeder.localised_name = {"entity-name.squirrel-feeder"}
empty_feeder.localised_description = {"entity-description.squirrel-feeder"}
empty_feeder.minable.result = "squirrel-feeder"
empty_feeder.picture = feeder_picture(
  "__squirrel_madness__/graphics/entities/structures/empty-wooden-feeder.png",
  "__squirrel_madness__/graphics/entities/structures/wooden-feeder-shadow.png",
  62,
  72,
  104,
  40,
  10,
  6.5
)

local steel_feeder = clone_container("steel-chest", "steel-squirrel-feeder")
steel_feeder.icon = "__squirrel_madness__/graphics/icons/steel-feeder-icon.png"
steel_feeder.icon_size = 64
steel_feeder.inventory_size = 2
steel_feeder.fast_replaceable_group = nil
steel_feeder.icon_draw_specification = {scale = 0, scale_for_many = 0}
steel_feeder.localised_description = {"entity-description.steel-squirrel-feeder"}
steel_feeder.picture = feeder_picture(
  "__squirrel_madness__/graphics/entities/structures/steel-feeder.png",
  "__squirrel_madness__/graphics/entities/structures/steel-feeder-shadow.png",
  64,
  80,
  110,
  46,
  12,
  7
)

local empty_steel_feeder = clone_container("steel-chest", "steel-squirrel-feeder-empty")
empty_steel_feeder.icon = "__squirrel_madness__/graphics/icons/steel-feeder-icon.png"
empty_steel_feeder.icon_size = 64
empty_steel_feeder.inventory_size = 2
empty_steel_feeder.fast_replaceable_group = nil
empty_steel_feeder.icon_draw_specification = {scale = 0, scale_for_many = 0}
empty_steel_feeder.localised_name = {"entity-name.steel-squirrel-feeder"}
empty_steel_feeder.localised_description = {"entity-description.steel-squirrel-feeder"}
empty_steel_feeder.minable.result = "steel-squirrel-feeder"
empty_steel_feeder.picture = feeder_picture(
  "__squirrel_madness__/graphics/entities/structures/empty-steel-feeder.png",
  "__squirrel_madness__/graphics/entities/structures/steel-feeder-shadow.png",
  64,
  80,
  110,
  46,
  12,
  7
)

local survey = create_survey_station()

local stash = clone_container("wooden-chest", "forest-stash")
stash.icon = "__base__/graphics/icons/wooden-chest.png"
stash.icon_size = 64
stash.inventory_size = 8
stash.minable = nil
stash.destructible = false
stash.localised_description = {"entity-description.forest-stash"}

local squirrel = clone_unit("small-biter", "squirrel")
squirrel.icon = "__squirrel_madness__/graphics/icons/squirrel.png"
squirrel.icon_size = 48
squirrel.max_health = 30
squirrel.healing_per_tick = 0
squirrel.vision_distance = 15
squirrel.movement_speed = 0.11
squirrel.distance_per_frame = 0.11
squirrel.distraction_cooldown = 30
squirrel.ai_settings = squirrel.ai_settings or {}
squirrel.ai_settings.destroy_when_commands_fail = false
squirrel.ai_settings.path_resolution_modifier = -4
squirrel.run_animation = {
  filenames = {
    "__squirrel_madness__/graphics/entities/squirrel/run-strips/north.png",
    "__squirrel_madness__/graphics/entities/squirrel/run-strips/north-east.png",
    "__squirrel_madness__/graphics/entities/squirrel/run-strips/east.png",
    "__squirrel_madness__/graphics/entities/squirrel/run-strips/south-east.png",
    "__squirrel_madness__/graphics/entities/squirrel/run-strips/south.png",
    "__squirrel_madness__/graphics/entities/squirrel/run-strips/south-west.png",
    "__squirrel_madness__/graphics/entities/squirrel/run-strips/west.png",
    "__squirrel_madness__/graphics/entities/squirrel/run-strips/north-west.png"
  },
  width = 48,
  height = 48,
  frame_count = 6,
  direction_count = 8,
  line_length = 6,
  lines_per_file = 1,
  animation_speed = 0.42,
  scale = 1.75
}

local nut_tree = clone_tree("tree-04", "nut-tree")
nut_tree.icon = "__base__/graphics/icons/tree-04.png"
nut_tree.icon_size = 64
nut_tree.emissions_per_second = {pollution = -0.003}
nut_tree.minable = {
  mining_particle = "wooden-particle",
  mining_time = 0.55,
  result = "nut",
  count = 5
}

local harvested_nut_tree = clone_tree("dry-tree", "nut-tree-harvested")
harvested_nut_tree.icon = "__base__/graphics/icons/dry-tree.png"
harvested_nut_tree.icon_size = 64
harvested_nut_tree.emissions_per_second = {pollution = -0.0015}
harvested_nut_tree.minable = {
  mining_particle = "wooden-particle",
  mining_time = 0.35,
  result = "wood",
  count = 1
}
harvested_nut_tree.localised_description = {"entity-description.nut-tree-harvested"}

local nut_sapling = clone_tree("dry-tree", "nut-sapling")
nut_sapling.icon = "__base__/graphics/icons/tree-04.png"
nut_sapling.icon_size = 64
nut_sapling.emissions_per_second = {pollution = -0.0005}
nut_sapling.minable = {
  mining_particle = "wooden-particle",
  mining_time = 0.2,
  result = "nut-sapling",
  count = 1
}
nut_sapling.localised_description = {"entity-description.nut-sapling"}

data:extend({
  squirrel,
  nut_tree,
  harvested_nut_tree,
  nut_sapling,
  feeder,
  empty_feeder,
  steel_feeder,
  empty_steel_feeder,
  survey,
  stash
})
