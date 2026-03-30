local constants = require("scripts.constants")

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

local function player_force()
  return game.forces.player
end

local function reset_progression()
  local force = player_force()

  force.reset_technologies()

  for _, technology_name in ipairs({
    constants.technologies.arboriculture,
    constants.technologies.wildlife_diversion,
    constants.technologies.forest_surveying
  }) do
    local technology = force.technologies[technology_name]
    if technology then
      technology.researched = false
    end
  end

  force.reset_technology_effects()
end

before_each(reset_progression)
after_each(reset_progression)

describe("milestone 0 scaffold", function()
  it("registers the core item, entity, recipe, technology, and input prototypes", function()
    assert.is_not_nil(prototypes.item[constants.names.nut])
    assert.is_not_nil(prototypes.item[constants.names.nut_sapling_item])
    assert.is_not_nil(prototypes.item[constants.names.feeder])
    assert.is_not_nil(prototypes.item[constants.names.survey_station])

    assert.is_not_nil(prototypes.entity[constants.names.nut_tree])
    assert.is_not_nil(prototypes.entity[constants.names.nut_tree_harvested])
    assert.is_not_nil(prototypes.entity[constants.names.nut_sapling])
    assert.is_not_nil(prototypes.entity[constants.names.feeder])
    assert.is_not_nil(prototypes.entity[constants.names.stash])
    assert.is_not_nil(prototypes.entity[constants.names.survey_station])

    assert.is_not_nil(prototypes.recipe[constants.names.nut_sapling_item])
    assert.is_not_nil(prototypes.recipe[constants.names.feeder])
    assert.is_not_nil(prototypes.recipe[constants.names.survey_station])

    assert.is_not_nil(prototypes.technology[constants.technologies.arboriculture])
    assert.is_not_nil(prototypes.technology[constants.technologies.wildlife_diversion])
    assert.is_not_nil(prototypes.technology[constants.technologies.forest_surveying])
    assert.is_not_nil(prototypes.technology["wildlife-relocation"])
    assert.is_not_nil(prototypes.technology["ecological-stabilization"])

    assert.is_not_nil(prototypes.custom_input[constants.names.survey_input])
    assert.is_not_nil(prototypes.custom_input[constants.names.relocation_input])
  end)

  it("unlocks restoration recipes in the intended order", function()
    local force = player_force()

    assert.is_false(force.recipes[constants.names.nut_sapling_item].enabled)
    assert.is_false(force.recipes[constants.names.feeder].enabled)
    assert.is_false(force.recipes[constants.names.survey_station].enabled)

    force.technologies[constants.technologies.arboriculture].researched = true
    force.reset_technology_effects()

    assert.is_true(force.recipes[constants.names.nut_sapling_item].enabled)
    assert.is_false(force.recipes[constants.names.feeder].enabled)
    assert.is_false(force.recipes[constants.names.survey_station].enabled)

    force.technologies[constants.technologies.wildlife_diversion].researched = true
    force.reset_technology_effects()

    assert.is_true(force.recipes[constants.names.feeder].enabled)
    assert.is_false(force.recipes[constants.names.survey_station].enabled)

    force.technologies[constants.technologies.forest_surveying].researched = true
    force.reset_technology_effects()

    assert.is_true(force.recipes[constants.names.survey_station].enabled)
  end)

  it("places the survey station as a powered radar scaffold instead of a container", function()
    local entity = surface().create_entity({
      name = constants.names.survey_station,
      position = {x = 8, y = 8},
      force = player_force()
    })

    assert.is_not_nil(entity)
    assert.equal("radar", entity.type)
    assert.is_nil(entity.get_inventory(defines.inventory.chest))
    assert.is_nil(entity.get_module_inventory())

    if entity and entity.valid then
      entity.destroy()
    end
  end)
end)
