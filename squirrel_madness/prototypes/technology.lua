data:extend({
  {
    type = "technology",
    name = "arboriculture",
    icon = "__base__/graphics/technology/automation-1.png",
    icon_size = 256,
    effects = {
      {
        type = "unlock-recipe",
        recipe = "nut-sapling"
      }
    },
    unit = {
      count = 12,
      time = 15,
      ingredients = {
        {"automation-science-pack", 1}
      }
    },
    order = "a-b-a"
  },
  {
    type = "technology",
    name = "wildlife-diversion",
    icon = "__base__/graphics/technology/logistics-1.png",
    icon_size = 256,
    prerequisites = {"arboriculture"},
    effects = {
      {
        type = "unlock-recipe",
        recipe = "squirrel-feeder"
      }
    },
    unit = {
      count = 40,
      time = 20,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1}
      }
    },
    order = "a-b-b"
  },
  {
    type = "technology",
    name = "forest-surveying",
    icon = "__base__/graphics/technology/radar.png",
    icon_size = 256,
    prerequisites = {"wildlife-diversion", "electronics"},
    effects = {
      {
        type = "unlock-recipe",
        recipe = "forest-survey-station"
      }
    },
    unit = {
      count = 50,
      time = 20,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1}
      }
    },
    order = "a-b-c"
  },
  {
    type = "technology",
    name = "wildlife-relocation",
    icon = "__base__/graphics/technology/military.png",
    icon_size = 256,
    prerequisites = {"forest-surveying", "military-2"},
    effects = {},
    unit = {
      count = 90,
      time = 30,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"chemical-science-pack", 1}
      }
    },
    order = "a-b-d"
  },
  {
    type = "technology",
    name = "ecological-stabilization",
    icon = "__base__/graphics/technology/solar-energy.png",
    icon_size = 256,
    prerequisites = {"wildlife-relocation", "solar-energy"},
    effects = {
      {
        type = "unlock-recipe",
        recipe = "steel-squirrel-feeder"
      }
    },
    unit = {
      count = 150,
      time = 30,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"chemical-science-pack", 1}
      }
    },
    order = "a-b-e"
  }
})
