# Squirrel Trouble Implementation Roadmap

Status: actionable v1 roadmap

Primary source: [docs/SPEC.md](/mnt/c/Code/SquirrelTrouble/docs/SPEC.md)
Resolved design answers: [docs/QUESTIONS.md](/mnt/c/Code/SquirrelTrouble/docs/QUESTIONS.md)

## Scope Baseline

The spec is broad, but the current implementation should target a scenario-first v1 shipped as a normal mod root in `squirrel_madness/`.

Use these settled decisions as the implementation baseline:

- one forest region = `2x2` chunks
- all regional metrics use a `0-100` scale
- ecology updates every `10` seconds
- major events cause immediate metric spikes, then decay happens gradually
- squirrel simulation uses a hybrid model: full local simulation near players, simplified regional scoring elsewhere
- v1 keeps squirrels on belts and chests; trains and chest reordering stay out of scope
- `Coexistence Victory` is the first shipped ending
- `Wildlife Relocation` moved from post-MVP in the spec to a late-v1 milestone in the answered questions

## Delivery Principles

- Preserve vanilla progression and keep squirrel systems legible.
- Ship in thin vertical slices so the ecology loop is testable before late-game systems exist.
- Prefer event-driven bookkeeping plus scheduled regional recomputation over broad per-tick scans.
- Keep scenario-specific setup separate from reusable ecology and squirrel runtime code so future extraction remains possible.
- External dependency mods are acceptable when they reduce duplicated ecology work, but their mechanics must be gated through this mod's own research and feedback loops instead of introducing parallel progression.

## Proposed Architecture

### Data Stage

- `info.json`: mod metadata.
- `data.lua`: central prototype entrypoint.
- `data-updates.lua` or `data-final-fixes.lua`: compatibility patches for dependency mods, especially recipe and technology gating.
- `prototypes/items.lua`: nuts plus placeables.
- `prototypes/entities.lua`: feeder, stash, survey station, later squirrel and nut-tree prototypes.
- `prototypes/recipes.lua`: early player unlocks.
- `prototypes/technology.lua`: squirrel research branch.
- `prototypes/custom-inputs.lua`: survey and relocation hotkeys.

### Runtime Stage

- `control.lua`: lifecycle registration plus FactorioTest bootstrap.
- `scripts/constants.lua`: names, tuning constants, region dimensions.
- `scripts/storage.lua`: runtime storage initialization and migration guards.
- `scripts/regions.lua`: region indexing, area math, ecology recomputation, metric serialization.
- `scripts/runtime.lua`: event handlers, nearby-region refresh, survey access, debug and test interface.

### Tests

- `factorio-test.json`: bind the repo mod root to FactorioTest.
- `scripts/tests.lua`: single FactorioTest entrypoint.
- `tests/*.lua`: focused integration tests for runtime modules and prototype behavior.

## Milestones

### 0. Scaffold And Harness

Deliverables:

- create the base mod structure
- add placeholder prototypes for feeder, stash, survey station, nuts, and research
- wire `control.lua`, storage initialization, a remote debug interface, and FactorioTest bootstrap
- correct stale `second_engineer` references in local tooling

Exit criteria:

- Factorio can load the mod root
- `npm test` can target `./squirrel_madness`
- one smoke test passes against the scaffold

### 1. Region Ecology Foundation

Validation:

- manual playtest passed on 2026-03-30
  - exact survey readouts now require a powered survey station
  - broad and exact survey modes both behaved correctly in live play

Deliverables:

- implement region mapping for `2x2` chunk regions
- track recent tree loss by region from mining, death, and fire/combat removal
- sample regional pollution and tree density every `10` seconds
- compute `forest_health`, `squirrel_unrest`, `squirrel_trust`, and `habitat_pressure`
- expose exact regional values through the survey station and a debug remote interface

Exit criteria:

- tree cutting causes immediate local unrest and pressure spikes
- untouched forest regions remain stably healthy
- survey readouts explain the relationship between trees, feeders, pollution, and pressure

### 2. Nut Economy And Habitat Recovery

Deliverables:

- implement nut tree prototype and natural worldgen placement
- declare `Arborist` as a dependency and patch its planting content into our `Arboriculture` branch
- integrate a general tree-planting baseline through `Arborist` rather than a nut-tree-only planting loop
- add nuts as manual harvest output
- integrate `nut-tree` and `nut-sapling` into the broader planting flow and slow maturation rules
- add a first-pass tree-healing mechanic for damaged trees and eligible stumps
- add the `Wooden Squirrel Feeder` as the first cheap, low-capacity wildlife diversion tool
- make stocked wooden feeders reduce unrest and raise trust
- add early tutorial beats that point players toward arboriculture, tree care, and wooden feeders

Exit criteria:

- the player has a recoverable path after early deforestation
- general tree planting unlocks through our own tech tree instead of a parallel dependency tech path
- replanting and healing are both legible ecological recovery tools
- stocking wooden feeders is cheaper than enduring sustained theft
- restored nut groves visibly improve region scores

### 3. Squirrel Runtime Foundation

Deliverables:

- add squirrel unit prototype and local spawn manager
- cap visible squirrels per active area
- implement the squirrel runtime state machine and region-to-local activation rules
- compute target desirability from item value classes instead of hand-tagging every item
- add stash bookkeeping, action cooldowns, and retreat-target selection
- keep the implementation deterministic enough for strong automated coverage before in-game tuning

Exit criteria:

- squirrel presence and action selection can be driven from normal region metrics
- active areas obey spawn caps, cooldowns, and stash bookkeeping under automated tests
- the runtime foundation is stable enough to support visible nuisance behavior without broad rewrites

### 4. Visible Squirrels And Nuisance Loop

Hard stop before Milestone 5: mandatory in-game playtest.

Playtest focus:

- confirm squirrels visibly spawn, move, and read correctly on screen
- confirm belt blocking, stack-building belt raids, and forest retreat behavior feel readable and fair
- confirm stash creation and loot recovery are understandable in normal play

Deliverables:

- put squirrels on screen in calm, curious, mischievous, agitated, and grieving states
- increase visible squirrel counts so factory-edge nuisance feels materially present
- add belt blocking, repeated belt theft that builds toward full carried stacks, forest retreat paths, and stash creation
- add full-stack chest scavenging only under higher pressure
- tune visible behavior, readability, and fairness through in-game playtests
- create and use the milestone manual playtest to validate on-screen squirrel behavior

Exit criteria:

- players can infer forest condition from squirrel behavior alone
- nuisance is disruptive but rate-limited
- stolen goods remain recoverable through stash retrieval or ground drops

### 5. Retaliation And Relocation Foundation

Deliverables:

- implement relocation targeting, healthy-destination selection, and trust effects
- add squirrel stepping and death attribution as explicit runtime events
- implement grief-state bookkeeping, retaliation escalation, and revenge-wave selection
- add map-marker and message hooks for accidental kills and localized retaliation
- keep retaliation and relocation rules deterministic enough for strong automated coverage

Exit criteria:

- relocation and retaliation outcomes follow explicit runtime rules under automated tests
- grief timers, revenge-wave triggers, and attribution stay bounded and inspectable
- the systems are stable enough for in-game readability and fairness tuning

### 6. Mitigation, Feedback, And Nonlethal Control

Hard stop before Milestone 7: mandatory in-game playtest.

Playtest focus:

- confirm players can understand relocation targeting and destination outcomes
- confirm stepping retaliation, death messaging, and revenge-wave escalation are readable and attributable
- confirm hotspot stabilization feels possible without killing squirrels
- confirm the progression from wooden to steel feeders is readable and worth the upgrade in live play

Deliverables:

- finish survey station UX and remaining broad-state feedback polish
- put the relocation tool in the player's hands with readable affordances
- add the `Steel Squirrel Feeder` as the higher-capacity factory-edge feeder tier without introducing a separate squirrel ruleset
- declare `robot_tree_farm_update` as a dependency and gate its automation through a later ecology technology
- integrate Robot Tree Farm-style forestry automation so planted and healed groves can scale into normal logistics play
- polish tree-healing feedback so damaged groves, valid targets, and successful recovery are readable
- tune stepping retaliation, squirrel death messaging, revenge waves, and accidental-kill feedback through in-game playtests
- create and use the milestone manual playtest to validate hotspot stabilization and escalation readability

Exit criteria:

- the player can intentionally stabilize hotspots without killing squirrels
- steel feeders and late-game forestry automation plug into the ecology branch instead of bypassing it
- one accidental squirrel death is painful but survivable
- the reason for every escalation is readable in-world or through the survey station

### 7. Sanctuary Scoring And Peace-Zone Foundation

Deliverables:

- score sanctuary regions from health, trust, unrest, trees, nut trees, and feeder state
- implement first-pass peace-zone suppression near healthy sanctuaries
- add global sanctuary summaries and reusable endgame metric aggregation
- implement deterministic `Coexistence Victory` precondition tracking and timed-window bookkeeping
- keep the backend reusable so `Nauvis Truce Victory` can layer on later

Exit criteria:

- sanctuary and peace-zone status derive from normal region metrics under automated tests
- victory preconditions and timers are inspectable and stable without one-off special cases
- the backend is ready for scenario-level playtesting and balance tuning

### 8. Coexistence Victory And Late-V1 Ecology Validation

Hard stop before Milestone 9: mandatory endgame playtest.

Playtest focus:

- confirm sanctuary regions and peace zones are understandable in normal scenario play
- confirm the timed `Coexistence Victory` window feels fair and readable
- confirm post-victory freeplay continues cleanly without breaking squirrel systems

Deliverables:

- tune sanctuary thresholds, peace-zone strength, and the final validation window through in-game playtests
- validate `Coexistence Victory` as the first shipped ending in normal scenario play
- keep the scenario running in freeplay after victory
- create and use the milestone manual playtest to validate sanctuary readability and endgame flow
- collect endgame metrics in reusable systems so `Nauvis Truce Victory` can layer on later

Exit criteria:

- the player must prove both rocket-scale industry and ecological stability
- endgame checks reuse normal region metrics instead of special-case code
- post-victory freeplay still runs squirrel systems

### 9. Post-V1 Extensions

Potential later upgrades:

- optional survey-station range upgrades through custom tuning or module-driven mechanics, with explicit extra power cost, only after v1 baseline survey UX is stable
Hold until v1 is readable and stable:

- natural nut tree propagation by healthy colonies
- colony growth and breeding pressure
- stronger biter passivity inside peace zones
- `Great Grove Victory`
- `Nauvis Truce Victory`
- multiplayer-specific hardening
- train-adjacent squirrel hazards
- chest reordering at extreme collapse

## Recommended Build Order

1. Land the scaffold, config, and smoke test.
2. Make region metrics real before any squirrel AI.
3. Land Arborist-gated planting, nut recovery, and tree healing before theft escalation so players have mitigation tools early.
4. Include the wooden feeder in that early mitigation slice so players learn the low-capacity peace-offering loop before squirrel nuisance escalates.
5. Land the squirrel runtime foundation before tuning visible nuisance behavior.
6. Introduce visible squirrel nuisance only after the spawn, state, and targeting systems are trustworthy, then stop for the first mandatory in-game playtest before Milestone 5.
7. Land retaliation and relocation foundations before tuning feedback, tree care readability, iron-feeder scaling, and forestry automation.
8. Finalize mitigation, feedback, nonlethal control, the steel feeder upgrade path, and Robot Tree Farm-gated forestry automation, then stop for the second mandatory in-game playtest before Milestone 7.
9. Land sanctuary scoring and peace-zone foundations before tuning the endgame.
10. Ship `Coexistence Victory` only after sanctuary behavior, peace zones, and the final validation window pass a dedicated endgame playtest before Milestone 9.

## Main Risks

- `Tree` and `unit` prototype work carries the highest content risk because it needs art-safe placeholders or generated assets.
- Belt interaction can become unfair fast if action cooldowns and target cooldowns are missing.
- Peace zones are easy to overtune; keep v1 local and conservative.
- Scenario-first worldgen requirements are important enough that they should not be deferred until after squirrel behavior exists.
