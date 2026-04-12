local constants = require("scripts.constants")
local regions = require("scripts.regions")

local TEST_POSITION = {x = 192, y = 192}
local TREE_NAME = "tree-01"

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

local function spawn_trees(count, origin)
  local trees = {}

  for index = 1, count do
    local x = origin.x + ((index - 1) % 3) * 6
    local y = origin.y + math.floor((index - 1) / 3) * 6
    trees[#trees + 1] = surface().create_entity({
      name = TREE_NAME,
      position = {x = x, y = y}
    })
  end

  return trees
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
  local trees = {}

  after_each(function()
    if station and station.valid then
      station.destroy()
    end

    for _, tree in ipairs(trees) do
      if tree and tree.valid then
        tree.destroy()
      end
    end

    trees = {}
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

  it("aggregates adjacent forest regions into a single exact survey cluster", function()
    local anchor_region = regions.position_to_region_coord(TEST_POSITION)
    local anchor_origin = {
      x = (anchor_region.x * constants.region_tile_span) + 4,
      y = (anchor_region.y * constants.region_tile_span) + 4
    }
    local east_origin = {
      x = ((anchor_region.x + 1) * constants.region_tile_span) + 4,
      y = (anchor_region.y * constants.region_tile_span) + 4
    }

    player_force().technologies[constants.technologies.forest_surveying].researched = true
    player_force().reset_technology_effects()

    station = surface().create_entity({
      name = constants.names.survey_station,
      position = TEST_POSITION,
      force = player_force()
    })

    assert.is_not_nil(station)
    station.energy = 60000

    trees = spawn_trees(constants.survey_cluster_min_tree_count, anchor_origin)
    local east_trees = spawn_trees(constants.survey_cluster_min_tree_count, east_origin)
    for _, tree in ipairs(east_trees) do
      trees[#trees + 1] = tree
    end

    local cluster = remote.call(constants.mod_name, "debug_get_survey_cluster", surface().index, TEST_POSITION.x, TEST_POSITION.y)

    assert.is_table(cluster)
    assert.equal("cluster", cluster.scope)
    assert.equal(2, cluster.region_count)
    assert.equal(constants.survey_cluster_min_tree_count * 2, cluster.tree_count)
    assert.same({
      {region_x = anchor_region.x, region_y = anchor_region.y},
      {region_x = anchor_region.x + 1, region_y = anchor_region.y}
    }, cluster.member_regions)
  end)

  it("keeps exact survey clusters local to the selected station", function()
    local anchor_region = regions.position_to_region_coord(TEST_POSITION)
    local anchor_origin = {
      x = (anchor_region.x * constants.region_tile_span) + 4,
      y = (anchor_region.y * constants.region_tile_span) + 4
    }
    local east_origin = {
      x = ((anchor_region.x + 1) * constants.region_tile_span) + 4,
      y = (anchor_region.y * constants.region_tile_span) + 4
    }
    local far_east_origin = {
      x = ((anchor_region.x + 2) * constants.region_tile_span) + 4,
      y = (anchor_region.y * constants.region_tile_span) + 4
    }

    player_force().technologies[constants.technologies.forest_surveying].researched = true
    player_force().reset_technology_effects()

    station = surface().create_entity({
      name = constants.names.survey_station,
      position = TEST_POSITION,
      force = player_force()
    })

    assert.is_not_nil(station)
    station.energy = 60000

    trees = spawn_trees(constants.survey_cluster_min_tree_count, anchor_origin)

    local east_trees = spawn_trees(constants.survey_cluster_min_tree_count, east_origin)
    for _, tree in ipairs(east_trees) do
      trees[#trees + 1] = tree
    end

    local far_east_trees = spawn_trees(constants.survey_cluster_min_tree_count, far_east_origin)
    for _, tree in ipairs(far_east_trees) do
      trees[#trees + 1] = tree
    end

    local cluster = remote.call(constants.mod_name, "debug_get_survey_cluster", surface().index, TEST_POSITION.x, TEST_POSITION.y)

    assert.is_table(cluster)
    assert.equal(2, cluster.region_count)
    assert.same({
      {region_x = anchor_region.x, region_y = anchor_region.y},
      {region_x = anchor_region.x + 1, region_y = anchor_region.y}
    }, cluster.member_regions)
  end)

  it("shows and clears a station footprint overlay for the selecting player", function()
    local anchor_region = regions.position_to_region_coord(TEST_POSITION)
    local anchor_origin = {
      x = (anchor_region.x * constants.region_tile_span) + 4,
      y = (anchor_region.y * constants.region_tile_span) + 4
    }

    player_force().technologies[constants.technologies.forest_surveying].researched = true
    player_force().reset_technology_effects()

    station = surface().create_entity({
      name = constants.names.survey_station,
      position = TEST_POSITION,
      force = player_force()
    })

    assert.is_not_nil(station)
    station.energy = 60000
    trees = spawn_trees(constants.survey_cluster_min_tree_count, anchor_origin)

    local shown = remote.call(
      constants.mod_name,
      "debug_show_survey_overlay",
      game.players[1].index,
      surface().index,
      TEST_POSITION.x,
      TEST_POSITION.y
    )
    local overlay = remote.call(constants.mod_name, "debug_get_survey_overlay_state", game.players[1].index)
    local panel = remote.call(constants.mod_name, "debug_get_survey_panel_state", game.players[1].index)

    assert.is_table(shown)
    assert.is_table(overlay)
    assert.is_table(panel)
    assert.equal(shown.region_count, overlay.region_count)
    assert.equal(overlay.region_count + 1, overlay.render_count)
    assert.equal(1, overlay.region_count)
    assert.is_true(panel.powered)
    assert.equal(1, panel.region_count)
    assert.equal(constants.survey_cluster_min_tree_count, panel.tree_count)

    assert.is_true(remote.call(constants.mod_name, "debug_clear_survey_overlay", game.players[1].index))
    assert.is_nil(remote.call(constants.mod_name, "debug_get_survey_overlay_state", game.players[1].index))
  end)
end)
