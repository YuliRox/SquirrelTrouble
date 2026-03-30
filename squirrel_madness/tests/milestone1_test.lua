local constants = require("scripts.constants")

local TEST_POSITION = {x = 192, y = 192}

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

local function player_force()
  return game.forces.player
end

local function reset_progression()
  local force = player_force()

  force.reset_technologies()
  force.reset_technology_effects()

  local technology = force.technologies[constants.technologies.forest_surveying]
  if technology then
    technology.researched = false
  end
end

local function clear_inventory(player)
  local inventory = player.get_main_inventory()
  if inventory then
    inventory.clear()
  end
end

before_each(function()
  reset_progression()
  clear_inventory(game.players[1])
end)

after_each(function()
  reset_progression()
  clear_inventory(game.players[1])
end)

describe("milestone 1 survey flow", function()
  local station

  after_each(function()
    if station and station.valid then
      station.destroy()
    end
  end)

  it("uses broad survey mode before any station is available", function()
    player_force().technologies[constants.technologies.forest_surveying].researched = true
    player_force().reset_technology_effects()

    local result = remote.call(constants.mod_name, "debug_resolve_survey", surface().index, TEST_POSITION.x, TEST_POSITION.y)

    assert.is_table(result)
    assert.equal("broad", result.mode)
    assert.is_nil(result.source)
    assert.same(TEST_POSITION, result.anchor_position)
    assert.is_false(result.station_powered)
  end)

  it("requires power before a nearby survey station grants exact values", function()
    player_force().technologies[constants.technologies.forest_surveying].researched = true
    player_force().reset_technology_effects()

    station = surface().create_entity({
      name = constants.names.survey_station,
      position = TEST_POSITION,
      force = player_force()
    })

    assert.is_not_nil(station)

    local before_power = remote.call(constants.mod_name, "debug_resolve_survey", surface().index, TEST_POSITION.x + 2, TEST_POSITION.y + 2)
    assert.equal("power-required", before_power.mode)
    assert.equal("nearby", before_power.source)
    assert.same(station.position, before_power.anchor_position)
    assert.is_false(before_power.station_powered)

    station.energy = 60000

    local after_power = remote.call(constants.mod_name, "debug_resolve_survey", surface().index, TEST_POSITION.x + 2, TEST_POSITION.y + 2)
    assert.equal("exact", after_power.mode)
    assert.equal("nearby", after_power.source)
    assert.same(station.position, after_power.anchor_position)
    assert.is_true(after_power.station_powered)
  end)

  it("anchors exact survey mode to the selected powered station", function()
    player_force().technologies[constants.technologies.forest_surveying].researched = true
    player_force().reset_technology_effects()

    station = surface().create_entity({
      name = constants.names.survey_station,
      position = TEST_POSITION,
      force = player_force()
    })

    assert.is_not_nil(station)
    station.energy = 60000

    local result = remote.call(
      constants.mod_name,
      "debug_resolve_survey",
      surface().index,
      TEST_POSITION.x + 24,
      TEST_POSITION.y + 16,
      station.position.x,
      station.position.y
    )

    assert.equal("exact", result.mode)
    assert.equal("selected", result.source)
    assert.same(station.position, result.anchor_position)
    assert.is_true(result.station_powered)
  end)
end)
