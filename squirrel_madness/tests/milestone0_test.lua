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
    assert.is_not_nil(prototypes.item[constants.names.steel_feeder])
    assert.is_not_nil(prototypes.item[constants.names.survey_station])

    assert.is_not_nil(prototypes.entity[constants.names.nut_tree])
    assert.is_not_nil(prototypes.entity[constants.names.nut_tree_harvested])
    assert.is_not_nil(prototypes.entity[constants.names.nut_sapling])
    assert.is_not_nil(prototypes.entity[constants.names.feeder])
    assert.is_not_nil(prototypes.entity[constants.names.feeder_empty])
    assert.is_not_nil(prototypes.entity[constants.names.steel_feeder])
    assert.is_not_nil(prototypes.entity[constants.names.steel_feeder_empty])
    assert.is_not_nil(prototypes.entity[constants.names.stash])
    assert.is_not_nil(prototypes.entity[constants.names.survey_station])
    assert.is_not_nil(prototypes.entity[constants.names.squirrel])
    assert.is_not_nil(prototypes.entity[constants.names.squirrel_sitting])

    assert.is_not_nil(prototypes.recipe[constants.names.nut_sapling_item])
    assert.is_not_nil(prototypes.recipe[constants.names.feeder])
    assert.is_not_nil(prototypes.recipe[constants.names.steel_feeder])
    assert.is_not_nil(prototypes.recipe[constants.names.survey_station])

    assert.is_not_nil(prototypes.technology[constants.technologies.arboriculture])
    assert.is_not_nil(prototypes.technology[constants.technologies.wildlife_diversion])
    assert.is_not_nil(prototypes.technology[constants.technologies.forest_surveying])
    assert.is_not_nil(prototypes.technology["wildlife-relocation"])
    assert.is_not_nil(prototypes.technology["ecological-stabilization"])

    assert.is_not_nil(prototypes.custom_input[constants.names.survey_input])
    assert.is_not_nil(prototypes.custom_input[constants.names.relocation_input])
  end)

  it("keeps nuts lightweight enough to read sensibly in rocket logistics", function()
    local nut = prototypes.item[constants.names.nut]
    local wood = prototypes.item["wood"]

    assert.is_not_nil(nut)
    assert.is_not_nil(wood)
    assert.is_true(nut.weight > 0)
    assert.is_true(nut.weight < wood.weight)
  end)

  it("gives squirrels a readable clickable footprint", function()
    local moving = prototypes.entity[constants.names.squirrel]
    local sitting = prototypes.entity[constants.names.squirrel_sitting]

    assert.is_not_nil(moving)
    assert.is_not_nil(sitting)
    assert.is_true(moving.selectable_in_game)
    assert.equal(moving.selection_box.left_top.x, sitting.selection_box.left_top.x)
    assert.equal(moving.selection_box.right_bottom.x, sitting.selection_box.right_bottom.x)
    assert.equal(moving.hit_visualization_box.left_top.x, sitting.hit_visualization_box.left_top.x)
    assert.equal(moving.hit_visualization_box.right_bottom.x, sitting.hit_visualization_box.right_bottom.x)
    assert.is_true((moving.selection_box.right_bottom.x - moving.selection_box.left_top.x) >= 1.4)
    assert.is_true((moving.collision_box.right_bottom.x - moving.collision_box.left_top.x) >= 0.6)
    assert.is_true(((moving.selection_box.left_top.x + moving.selection_box.right_bottom.x) / 2) > 0.3)
    assert.is_true(((moving.hit_visualization_box.left_top.x + moving.hit_visualization_box.right_bottom.x) / 2) > 0.3)
  end)

  it("uses paired squirrel body and shadow sheets for movement and belt-pose variants", function()
    local moving = prototypes.entity[constants.names.squirrel]
    local sitting = prototypes.entity[constants.names.squirrel_sitting]
    local moving_layer = moving.run_animation.layers[1]
    local moving_shadow = moving.run_animation.layers[2]
    local sitting_layer = sitting.run_animation.layers[1]
    local sitting_shadow = sitting.run_animation.layers[2]

    assert.is_not_nil(moving_layer)
    assert.is_not_nil(moving_shadow)
    assert.is_not_nil(sitting_layer)
    assert.is_not_nil(sitting_shadow)
    assert.equal("__squirrel_madness__/graphics/entities/squirrel/sq.png", moving_layer.stripes[1].filename)
    assert.equal("__squirrel_madness__/graphics/entities/squirrel/sq_shadow.png", moving_shadow.stripes[1].filename)
    assert.equal("__squirrel_madness__/graphics/entities/squirrel/sq.png", sitting_layer.stripes[1].filename)
    assert.equal("__squirrel_madness__/graphics/entities/squirrel/sq_shadow.png", sitting_shadow.stripes[1].filename)
    assert.equal(5, moving_layer.frame_count)
    assert.equal(16, moving_layer.direction_count)
    assert.equal(132, moving_layer.width)
    assert.equal(78, moving_layer.height)
    assert.equal(8, moving_layer.stripes[1].width_in_frames)
    assert.equal(10, moving_layer.stripes[1].height_in_frames)
    assert.is_true(moving_shadow.draw_as_shadow)
    assert.is_true(sitting_shadow.draw_as_shadow)
    assert.equal(1, moving_shadow.tint.a)
    assert.equal(1, sitting_shadow.tint.a)
    assert.is_true(moving_layer.animation_speed > sitting_layer.animation_speed)
  end)

  it("unlocks restoration recipes in the intended order", function()
    local force = player_force()

    assert.is_false(force.recipes[constants.names.nut_sapling_item].enabled)
    assert.is_false(force.recipes[constants.names.feeder].enabled)
    assert.is_false(force.recipes[constants.names.steel_feeder].enabled)
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
    assert.is_false(force.recipes[constants.names.steel_feeder].enabled)

    force.technologies[constants.technologies.ecological_stabilization].researched = true
    force.reset_technology_effects()

    assert.is_true(force.recipes[constants.names.steel_feeder].enabled)
  end)

  it("gives steel feeders double the nut capacity of the wooden feeder", function()
    local wooden = surface().create_entity({
      name = constants.names.feeder_empty,
      position = {x = 8, y = 8},
      force = player_force()
    })
    local steel = surface().create_entity({
      name = constants.names.steel_feeder_empty,
      position = {x = 12, y = 8},
      force = player_force()
    })
    local wooden_inventory = wooden.get_inventory(defines.inventory.chest)
    local steel_inventory = steel.get_inventory(defines.inventory.chest)

    assert.equal(100, wooden_inventory.insert({name = constants.names.nut, count = 200}))
    assert.equal(200, steel_inventory.insert({name = constants.names.nut, count = 200}))

    if wooden and wooden.valid then
      wooden.destroy()
    end

    if steel and steel.valid then
      steel.destroy()
    end
  end)

  it("keeps feeder variants sturdier than their chest bases", function()
    local wooden_chest = surface().create_entity({
      name = "wooden-chest",
      position = {x = 16, y = 8},
      force = player_force()
    })
    local wooden_feeder = surface().create_entity({
      name = constants.names.feeder_empty,
      position = {x = 18, y = 8},
      force = player_force()
    })
    local steel_chest = surface().create_entity({
      name = "steel-chest",
      position = {x = 20, y = 8},
      force = player_force()
    })
    local steel_feeder = surface().create_entity({
      name = constants.names.steel_feeder_empty,
      position = {x = 22, y = 8},
      force = player_force()
    })

    assert.is_true(wooden_feeder.health > wooden_chest.health)
    assert.is_true(steel_feeder.health > steel_chest.health)

    if wooden_chest and wooden_chest.valid then
      wooden_chest.destroy()
    end

    if wooden_feeder and wooden_feeder.valid then
      wooden_feeder.destroy()
    end

    if steel_chest and steel_chest.valid then
      steel_chest.destroy()
    end

    if steel_feeder and steel_feeder.valid then
      steel_feeder.destroy()
    end
  end)

  it("disables vanilla chest item overlays on feeder variants", function()
    for _, name in ipairs({
      constants.names.feeder,
      constants.names.feeder_empty,
      constants.names.steel_feeder,
      constants.names.steel_feeder_empty
    }) do
      local spec = prototypes.entity[name].icon_draw_specification
      assert.is_not_nil(spec)
      assert.equal(0, spec.scale)
      assert.equal(0, spec.scale_for_many)
    end
  end)

  it("disables vanilla chest item overlays on forest stashes", function()
    local spec = prototypes.entity[constants.names.stash].icon_draw_specification

    assert.is_not_nil(spec)
    assert.equal(0, spec.scale)
    assert.equal(0, spec.scale_for_many)
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

  it("defangs the inherited biter attack on squirrels", function()
    local squirrel = prototypes.entity[constants.names.squirrel]

    assert.is_not_nil(squirrel)
    assert.is_not_nil(squirrel.attack_parameters)
    assert.is_true(squirrel.attack_parameters.range > 0)
    assert.is_true(squirrel.attack_parameters.range < 0.02)
    assert.is_nil(squirrel.attack_parameters.sound)
    assert.is_not_nil(squirrel.collision_mask)
    assert.is_not_nil(squirrel.collision_mask.layers)
  end)
end)
