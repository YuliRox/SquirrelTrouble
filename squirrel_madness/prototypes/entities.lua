local function clone_container(name)
  local source = data.raw.container["wooden-chest"]
  if not source then
    error("Expected base wooden-chest prototype to exist")
  end

  local prototype = table.deepcopy(source)
  prototype.name = name
  prototype.minable = prototype.minable or {}
  prototype.minable.result = name
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

local feeder = clone_container("squirrel-feeder")
feeder.icon = "__base__/graphics/icons/wooden-chest.png"
feeder.icon_size = 64
feeder.inventory_size = 1
feeder.fast_replaceable_group = nil
feeder.localised_description = {"entity-description.squirrel-feeder"}

local survey = clone_container("forest-survey-station")
survey.icon = "__base__/graphics/icons/small-lamp.png"
survey.icon_size = 64
survey.inventory_size = 1
survey.localised_description = {"entity-description.forest-survey-station"}

local stash = clone_container("forest-stash")
stash.icon = "__base__/graphics/icons/wooden-chest.png"
stash.icon_size = 64
stash.hidden = true
stash.inventory_size = 8
stash.minable = nil
stash.localised_description = {"entity-description.forest-stash"}

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
  nut_tree,
  nut_sapling,
  feeder,
  survey,
  stash
})
