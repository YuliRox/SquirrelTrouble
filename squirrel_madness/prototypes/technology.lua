local function add_recipe_unlock(effect_list, recipe_name)
  effect_list[#effect_list + 1] = {
    type = "unlock-recipe",
    recipe = recipe_name
  }
end

local function ecological_stabilization_effects()
  local effects = {}

  add_recipe_unlock(effects, "steel-squirrel-feeder")

  if not mods["robot_tree_farm_update"] then
    return effects
  end

  local matched = {}
  for recipe_name in pairs(data.raw.recipe or {}) do
    local lower_name = string.lower(recipe_name)
    if string.find(lower_name, "treefarm", 1, true)
      or string.find(lower_name, "tree-farm", 1, true)
      or string.find(lower_name, "tree_farm", 1, true)
      or string.find(lower_name, "robot-tree-farm", 1, true)
      or string.find(lower_name, "robot_tree_farm", 1, true)
    then
      matched[#matched + 1] = recipe_name
    end
  end

  table.sort(matched)
  for _, recipe_name in ipairs(matched) do
    add_recipe_unlock(effects, recipe_name)
  end

  return effects
end

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
    effects = ecological_stabilization_effects(),
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
