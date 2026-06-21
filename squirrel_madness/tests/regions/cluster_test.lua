-- Behavioral tests for scripts/regions/cluster.lua. The cluster builder does a
-- flood-fill over candidate regions around a survey anchor and aggregates a
-- weighted report. We place real forest entities so regions become genuine
-- cluster candidates, then assert the flood-fill membership, aggregation totals,
-- bounds, and the single-region fallback when no region qualifies.

local cluster = require("scripts.regions.cluster")
local store = require("scripts.regions.store")
local constants = require("scripts.constants")

local SPAN = constants.region_tile_span
local TREE_NAME = "tree-01"
-- Region 20,20 anchored well clear of milestone2 (384+) and the other tests.
-- The anchor sits one tile inside the +x edge of region 20 so the survey
-- station's exact radius spills into region 21, letting the flood-fill reach it;
-- floor((21*SPAN - 1) / SPAN) is still 20, so the anchor resolves to region 20.
local ANCHOR_REGION_X, ANCHOR_REGION_Y = 20, 20
local ANCHOR_POSITION = {
  x = ((ANCHOR_REGION_X + 1) * SPAN) - 1,
  y = (ANCHOR_REGION_Y * SPAN) + (SPAN / 2)
}
local spawned

local function surface()
  return game.surfaces["nauvis"] or game.surfaces[1]
end

-- Pack `count` trees tightly near the center of the given region so they all
-- fall inside the survey station's exact radius around the anchor.
local function fill_region_with_trees(region_x, region_y, count)
  local base_x = (region_x * SPAN) + (SPAN / 2)
  local base_y = (region_y * SPAN) + (SPAN / 2)

  for index = 1, count do
    local entity = surface().create_entity({
      name = TREE_NAME,
      position = {
        x = base_x + ((index % 4) * 1.2) - 2,
        y = base_y + (math.floor(index / 4) * 1.2) - 2
      }
    })
    if entity then
      spawned[#spawned + 1] = entity
    end
  end
end

describe("regions.cluster submodule", function()
  before_each(function()
    spawned = {}
    storage.regions = {}
    surface().request_to_generate_chunks(ANCHOR_POSITION, 3)
    surface().force_generate_chunk_requests()
    surface().clear_pollution()
  end)

  after_each(function()
    for _, entity in ipairs(spawned or {}) do
      if entity and entity.valid then
        entity.destroy()
      end
    end
    spawned = {}
    storage.regions = {}
    surface().clear_pollution()
  end)

  it("returns a single-region report when no region qualifies as a candidate", function()
    -- a couple of trees, below survey_cluster_min_tree_count
    fill_region_with_trees(ANCHOR_REGION_X, ANCHOR_REGION_Y, 2)

    local report = cluster.build_forest_cluster(surface(), ANCHOR_POSITION, 1000)

    assert.equal("cluster", report.scope)
    assert.equal(1, report.region_count)
    assert.equal(1, #report.member_regions)
    assert.equal(ANCHOR_REGION_X, report.anchor_region_x)
    assert.equal(ANCHOR_REGION_Y, report.anchor_region_y)
  end)

  it("aggregates a single dense candidate region into the cluster report", function()
    local tree_count = constants.survey_cluster_min_tree_count + 4
    fill_region_with_trees(ANCHOR_REGION_X, ANCHOR_REGION_Y, tree_count)

    local report = cluster.build_forest_cluster(surface(), ANCHOR_POSITION, 1000)

    assert.equal(1, report.region_count)
    assert.equal(tree_count, report.tree_count)
    assert.is_true(report.forest_health > 0)
    -- band classifications are derived from the weighted metrics
    assert.is_string(report.forest_health_band)
    assert.is_string(report.habitat_pressure_band)
    -- bounds collapse to the single member region
    assert.equal(ANCHOR_REGION_X, report.bounds.min_region_x)
    assert.equal(ANCHOR_REGION_X, report.bounds.max_region_x)
  end)

  it("flood-fills across adjacent candidate regions and sums their trees", function()
    local per_region = constants.survey_cluster_min_tree_count + 2
    fill_region_with_trees(ANCHOR_REGION_X, ANCHOR_REGION_Y, per_region)
    fill_region_with_trees(ANCHOR_REGION_X + 1, ANCHOR_REGION_Y, per_region)

    local report = cluster.build_forest_cluster(surface(), ANCHOR_POSITION, 1000)

    assert.is_true(report.region_count >= 2)
    assert.is_true(report.tree_count >= per_region * 2)
    assert.is_true(report.bounds.max_region_x > report.bounds.min_region_x)
    -- member regions are sorted by (region_x, region_y)
    for index = 2, #report.member_regions do
      local previous = report.member_regions[index - 1]
      local current = report.member_regions[index]
      if previous.region_x == current.region_x then
        assert.is_true(previous.region_y < current.region_y)
      else
        assert.is_true(previous.region_x < current.region_x)
      end
    end
  end)

  it("does not pull in dense regions outside the survey station radius", function()
    local per_region = constants.survey_cluster_min_tree_count + 2
    fill_region_with_trees(ANCHOR_REGION_X, ANCHOR_REGION_Y, per_region)
    -- a dense region three regions away can never intersect the station circle:
    -- the radius reach (2 * survey_station_exact_radius) is less than one region span.
    fill_region_with_trees(ANCHOR_REGION_X + 3, ANCHOR_REGION_Y, per_region)

    local report = cluster.build_forest_cluster(surface(), ANCHOR_POSITION, 1000)

    -- the distant grove is excluded; the cluster never reaches region X+3
    assert.is_true(report.bounds.max_region_x < ANCHOR_REGION_X + 3)
    for _, member in ipairs(report.member_regions) do
      assert.is_true(member.region_x < ANCHOR_REGION_X + 3)
    end
  end)
end)
