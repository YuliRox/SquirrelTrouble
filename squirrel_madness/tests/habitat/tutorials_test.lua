-- Behavioral tests for scripts/habitat/tutorials.lua. These pin the one-shot
-- flag bookkeeping and the nil/invalid guards. Milestone 2 covers the
-- deforestation threshold and research hints; here we isolate the sapling and
-- harvest hints (which only flip once) and confirm a nil player_index is a safe
-- no-op that never sets a flag.

local tutorials = require("scripts.habitat.tutorials")

local function player()
  return game.players[1]
end

describe("habitat.tutorials submodule", function()
  before_each(function()
    storage.force_tutorials = {}
  end)

  after_each(function()
    storage.force_tutorials = {}
  end)

  local function force_flags()
    return storage.force_tutorials[player().force.index]
  end

  it("treats a nil player_index as a no-op for the sapling hint", function()
    tutorials.maybe_show_sapling_hint(nil)
    assert.is_nil(force_flags())
  end)

  it("sets the sapling hint flag exactly once", function()
    tutorials.maybe_show_sapling_hint(player().index)
    assert.is_true(force_flags().sapling_hint)

    -- a second call must not error and the flag stays set (no double-print path)
    tutorials.maybe_show_sapling_hint(player().index)
    assert.is_true(force_flags().sapling_hint)
  end)

  it("sets the harvest hint flag exactly once", function()
    tutorials.maybe_show_harvest_hint(player().index)
    assert.is_true(force_flags().harvest_hint)

    tutorials.maybe_show_harvest_hint(player().index)
    assert.is_true(force_flags().harvest_hint)
  end)

  it("ignores invalid research payloads", function()
    -- must not raise on a payload missing a valid force
    tutorials.on_research_finished(nil)
    tutorials.on_research_finished({name = "arboriculture", valid = false})
    assert.is_nil(force_flags())
  end)

  it("only flags recognized mitigation technologies", function()
    tutorials.on_research_finished({name = "unrelated-tech", force = player().force, valid = true})
    -- an unrelated tech creates the force bucket but sets no known hint flag
    local flags = force_flags() or {}
    assert.is_nil(flags.arboriculture_hint)
    assert.is_nil(flags.wildlife_diversion_hint)
  end)
end)
