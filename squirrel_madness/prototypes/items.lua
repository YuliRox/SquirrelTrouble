local survey_station_icon_tint = {r = 0.32, g = 0.52, b = 0.34, a = 1}

data:extend({
  {
    type = "item",
    name = "nut",
    icon = "__squirrel_madness__/graphics/icons/nut.png",
    icon_size = 64,
    subgroup = "intermediate-product",
    order = "n[squirrel]-a[nut]",
    stack_size = 100,
    weight = 100 * grams
  },
  {
    type = "item",
    name = "nut-sapling",
    icon = "__base__/graphics/icons/tree-04.png",
    icon_size = 64,
    subgroup = "intermediate-product",
    order = "n[squirrel]-a[sapling]",
    place_result = "nut-sapling",
    stack_size = 100
  },
  {
    type = "item",
    name = "squirrel-feeder",
    icon = "__squirrel_madness__/graphics/icons/wooden-feeder-icon.png",
    icon_size = 64,
    subgroup = "storage",
    order = "n[squirrel]-b[feeder]",
    place_result = "squirrel-feeder-empty",
    stack_size = 50
  },
  {
    type = "item",
    name = "steel-squirrel-feeder",
    icon = "__squirrel_madness__/graphics/icons/steel-feeder-icon.png",
    icon_size = 64,
    subgroup = "storage",
    order = "n[squirrel]-c[feeder-upgrade]",
    place_result = "steel-squirrel-feeder-empty",
    stack_size = 50
  },
  {
    type = "item",
    name = "forest-survey-station",
    icons = {
      {
        icon = "__base__/graphics/icons/radar.png",
        icon_size = 64,
        tint = survey_station_icon_tint
      }
    },
    subgroup = "production-machine",
    order = "n[squirrel]-d[survey]",
    place_result = "forest-survey-station",
    stack_size = 20
  }
})
