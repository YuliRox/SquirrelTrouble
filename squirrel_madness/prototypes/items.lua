data:extend({
  {
    type = "item",
    name = "nut",
    icon = "__base__/graphics/icons/wood.png",
    icon_size = 64,
    subgroup = "intermediate-product",
    order = "n[squirrel]-a[nut]",
    stack_size = 100
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
    icon = "__base__/graphics/icons/wooden-chest.png",
    icon_size = 64,
    subgroup = "storage",
    order = "n[squirrel]-b[feeder]",
    place_result = "squirrel-feeder",
    stack_size = 50
  },
  {
    type = "item",
    name = "forest-survey-station",
    icon = "__base__/graphics/icons/small-lamp.png",
    icon_size = 64,
    subgroup = "production-machine",
    order = "n[squirrel]-c[survey]",
    place_result = "forest-survey-station",
    stack_size = 20
  }
})
