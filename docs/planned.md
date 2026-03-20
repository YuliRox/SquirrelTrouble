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

## Proposed Architecture

### Data Stage

- `info.json`: mod metadata.
- `data.lua`: central prototype entrypoint.
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
- add nuts as manual harvest output
- allow nut planting and slow maturation into nut trees
- make stocked feeders reduce unrest and raise trust
- add early tutorial beats that point players toward arboriculture and feeders

Exit criteria:

- the player has a recoverable path after early deforestation
- feeder stocking is cheaper than enduring sustained theft
- restored nut groves visibly improve region scores

### 3. Visible Squirrels And Nuisance Loop

Deliverables:

- add squirrel unit prototype and local spawn manager
- cap visible squirrels per active area
- implement calm, curious, mischievous, agitated, and grieving runtime states
- add belt blocking, single-item belt theft, forest retreat paths, and stash creation
- add chest scavenging only under higher pressure
- compute target desirability from item value classes instead of hand-tagging every item

Exit criteria:

- players can infer forest condition from squirrel behavior alone
- nuisance is disruptive but rate-limited
- stolen goods remain recoverable through stash retrieval or ground drops

### 4. Mitigation, Feedback, And Nonlethal Control

Deliverables:

- finish survey station UX and broad-state feedback before exact numbers
- add relocation as a late-v1 nonlethal tool
- add squirrel stepping retaliation and squirrel death retaliation messaging
- spawn localized revenge waves on player-caused squirrel deaths
- add map or marker feedback for accidental train and vehicle kills

Exit criteria:

- the player can intentionally stabilize hotspots without killing squirrels
- one accidental squirrel death is painful but survivable
- the reason for every escalation is readable in-world or through the survey station

### 5. Coexistence Victory And Late-V1 Ecology

Deliverables:

- score sanctuary regions from health, trust, unrest, trees, nut trees, and feeder state
- implement first-pass peace-zone suppression near healthy sanctuaries
- validate `Coexistence Victory` with a timed final window
- keep the scenario running in freeplay after victory
- collect endgame metrics in reusable systems so `Nauvis Truce Victory` can layer on later

Exit criteria:

- the player must prove both rocket-scale industry and ecological stability
- endgame checks reuse normal region metrics instead of special-case code
- post-victory freeplay still runs squirrel systems

### 6. Post-V1 Extensions

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
3. Add nuts and feeders before theft escalation so players have mitigation tools early.
4. Introduce visible squirrel nuisance after the ecology numbers are trustworthy.
5. Add relocation and retaliation once the core nuisance loop feels fair.
6. Ship `Coexistence Victory` only after sanctuary scoring and peace-zone suppression are stable.

## Main Risks

- `Tree` and `unit` prototype work carries the highest content risk because it needs art-safe placeholders or generated assets.
- Belt interaction can become unfair fast if action cooldowns and target cooldowns are missing.
- Peace zones are easy to overtune; keep v1 local and conservative.
- Scenario-first worldgen requirements are important enough that they should not be deferred until after squirrel behavior exists.
