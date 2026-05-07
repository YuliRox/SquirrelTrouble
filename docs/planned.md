# Squirrel Trouble Implementation Roadmap

Status: actionable v1 roadmap

Primary source: [docs/SPEC.md](SPEC.md)
Resolved design answers: [docs/QUESTIONS.md](QUESTIONS.md)

## Scope Baseline

The spec is broad, but the current implementation should target a scenario-first v1 shipped as a normal mod root in `squirrel_madness/`.

Use these settled decisions as the implementation baseline:

- one forest region = `2x2` chunks
- all regional metrics use a `0-100` scale
- ecology updates every `10` seconds
- major events cause immediate metric spikes, then decay happens gradually
- squirrel simulation uses a hybrid model: full local simulation near players, simplified regional scoring elsewhere
- v1 keeps squirrels on belts and chests; trains and chest reordering stay out of scope
- `Squirrel Evolution` is global and irreversible; `Squirrel Unrest` remains local and reversible
- the scenario ends on rocket launch
- current MVP scope includes machine infestation, squirrel-evolution-driven sabotage, and final rocket-launch scoring presentation
- current MVP scope does not require relocation drones or peace zones
- `Nauvis Truce Victory` remains the intended long-term ending, but it no longer defines the MVP boundary

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

Status:

- implemented

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

Status:

- implemented

Validation:

- manual playtest passed on 2026-03-30
  - exact survey readouts now require a powered survey station
  - broad and exact survey modes both behaved correctly in live play

Deliverables:

- implement region mapping for `2x2` chunk regions
- track recent tree loss by region from mining, death, and fire/combat removal
- sample regional pollution and tree density every `10` seconds
- compute `forest_health`, `squirrel_unrest`, `squirrel_trust`, and `habitat_pressure`
- expose exact station-footprint values through the survey station and a debug remote interface
- show the surveyed station reach when the station is selected, without hidden cell boxes

Exit criteria:

- tree cutting causes immediate local unrest and pressure spikes
- untouched forest regions remain stably healthy
- survey readouts explain the relationship between trees, feeders, pollution, and pressure, and the player can see which forest footprint is being measured

### 2. Nut Economy And Habitat Recovery

Status:

- implemented

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

Status:

- implemented

Deliverables:

- add squirrel unit prototype and local spawn manager
- seed initial squirrel presence during chunk generation so forests already feel inhabited before the player arrives
- cap visible squirrels per active area
- make runtime population upkeep refill gradually instead of filling a whole region in one update
- implement the squirrel runtime state machine and region-to-local activation rules
- implement pressure-driven wandering radii so squirrel range expands outward from forest habitat before theft occurs
- compute target desirability from item value classes instead of hand-tagging every item
- add stash bookkeeping, action cooldowns, and retreat-target selection
- keep the implementation deterministic enough for strong automated coverage before in-game tuning

Exit criteria:

- squirrel presence and action selection can be driven from normal region metrics
- active areas obey spawn caps, cooldowns, and stash bookkeeping under automated tests
- initial forest contact does not rely on a large first-sighting squirrel spawn burst
- the runtime foundation is stable enough to support visible nuisance behavior without broad rewrites

### 4. Visible Squirrels And Nuisance Loop

Status:

- implemented

Hard stop before Milestone 5: mandatory in-game playtest.

Playtest focus:

- confirm squirrels visibly spawn, move, and read correctly on screen
- confirm passive forest-edge belt sitting means squirrels actually get onto a belt tile, ride with the belt, block that lane for a readable dwell, and then leave or escalate cleanly
- confirm calm belt sitting can happen on nearby empty belts, while theft still only escalates on belts that actually carry loot
- confirm stocked-feeder diversion, stack-building belt raids, and forest retreat behavior feel readable and fair
- confirm stocked feeders visibly attract squirrels away from belts instead of only suppressing nuisance invisibly
- confirm stash creation and loot recovery are understandable in normal play

Deliverables:

- put squirrels on screen in calm, curious, mischievous, agitated, and grieving states
- increase visible squirrel counts so factory-edge nuisance feels materially present
- replace direct home-anchor target snapping with readable outward wandering from the forest edge
- make higher pressure widen squirrel wandering and allow deeper initial incursions before a theft attempt
- allow calm squirrels to move onto nearby belt tiles and sit there as a low-grade nuisance unless stocked feeders pacify the area
- make stocked feeders visibly draw squirrels in for short nut-eating visits
- add belt blocking, repeated belt theft that builds toward full carried stacks, forest retreat paths, and stash creation
- show the carried item and carried count while a squirrel is hauling loot
- add full-stack chest scavenging only under higher pressure
- tune visible behavior, readability, and fairness through in-game playtests
- create and use the milestone manual playtest to validate on-screen squirrel behavior

Exit criteria:

- players can infer forest condition from squirrel behavior alone
- squirrels look like they are ranging outward from habitat rather than teleporting intent to arbitrary logistics targets
- nuisance is disruptive but rate-limited
- stolen goods remain recoverable through stash retrieval or ground drops

### 5. Retaliation And Relocation Foundation

Status:

- implemented
- manual playtest still required

Known design issue from playtest:

- the current click-to-relocate interaction is technically functional but not acceptable as final game design
- it reads too much like low-friction squirrel deletion instead of cumbersome wildlife control
- relocation needs a new design decision before it should be treated as finished player-facing UX

Deliverables:

- implement relocation targeting, healthy-destination selection, and trust effects
- add squirrel stepping and death attribution as explicit runtime events
- implement grief-state bookkeeping, retaliation escalation, and localized revenge-wave launch
- add map-marker and message hooks for accidental kills and localized retaliation
- keep retaliation and relocation rules deterministic enough for strong automated coverage

Exit criteria:

- relocation and retaliation outcomes follow explicit runtime rules under automated tests
- grief timers, revenge-wave triggers, and attribution stay bounded and inspectable
- the systems are stable enough for in-game readability and fairness tuning

### 6. Mitigation, Feedback, And Nonlethal Control

Status:

- implemented
- manual playtest still required

Hard stop before Milestone 7: mandatory in-game playtest.

Playtest focus:

- confirm players can understand relocation targeting and destination outcomes
- evaluate whether relocation feels like real wildlife management rather than trivial squirrel removal
- confirm stepping retaliation, death messaging, and revenge-wave escalation are readable and attributable
- confirm hotspot stabilization feels possible without killing squirrels
- confirm the progression from wooden to steel feeders is readable and worth the upgrade in live play

Deliverables:

- finish survey station UX and remaining broad-state feedback polish
- put the relocation tool in the player's hands with readable affordances
- revisit relocation interaction design before calling the mechanic complete as player-facing mitigation
- add the `Steel Squirrel Feeder` as the higher-capacity factory-edge feeder tier without introducing a separate squirrel ruleset
- declare `robot_tree_farm_update` as a dependency and gate its automation through a later ecology technology
- integrate Robot Tree Farm-style forestry automation so planted and healed groves can scale into normal logistics play
- polish tree-healing feedback so damaged groves, valid targets, and successful recovery are readable
- tune stepping retaliation, squirrel death messaging, revenge waves, and accidental-kill feedback through in-game playtests
- create and use the milestone manual playtest to validate hotspot stabilization and escalation readability

Exit criteria:

- the player can intentionally stabilize hotspots without killing squirrels
- relocation no longer reads like instant squirrel deletion
- steel feeders and late-game forestry automation plug into the ecology branch instead of bypassing it
- one accidental squirrel death is painful but survivable
- the reason for every escalation is readable in-world or through the survey station

### 7. Food Chain And Scenario Feedback

Hard stop before Milestone 8: mandatory in-game playtest.

Open questions to settle during implementation:

- visible predation frequency
- natural-predation refill timing and placement
- player-facing signal for squirrel-respawn viability after colony collapse
- homeless squirrel behavior and home-colony reassignment rules
See [docs/QUESTIONS.md](QUESTIONS.md), section `22. Open Design Gaps From The Roadmap`.

Playtest focus:

- confirm biters visibly chase and eat squirrels often enough to communicate the food chain without collapsing squirrel populations
- confirm biter-eaten squirrels do not trigger mourning or retaliation
- confirm researched squirrel facts in Tips and Tricks actually help players understand escalation, feeding, and predation

Deliverables:

- implement visible biter-on-squirrel predation when players are near enough to witness it
- ensure natural squirrel predation does not count as player-caused harm and does not trigger retaliation
- compensate natural predation through normal forest-side squirrel refill so the food chain remains readable without destabilizing the scenario
- add researched squirrel facts and Tips and Tricks entries for ecology, predation, feeders, relocation, and violence escalation
- add reusable endgame metric aggregation for the later rocket-launch ecological summary

Exit criteria:

- natural predation is clearly distinguishable from player-caused squirrel harm
- squirrel facts teach the intended ecology instead of leaving players to guess at the food chain
- the backend is ready for military escalation and rocket-launch summary work

### 8. Global Squirrel Evolution And Destructive Escalation

Hard stop before Milestone 9: mandatory in-game playtest.

Open questions to settle during implementation:

- whether machine infestation alone is enough for MVP sabotage or whether at least one more sabotage behavior is required
- how `Squirrel Evolution` should be exposed to the player
See [docs/QUESTIONS.md](QUESTIONS.md), section `22. Open Design Gaps From The Roadmap`.

Playtest focus:

- confirm peaceful runs still stay mostly in nuisance territory
- confirm military escalation raises global squirrel evolution in a way the player can understand
- confirm restoring forests and feeders calms current destruction without resetting learned escalation
- confirm machine infestation and factory misplanting keep squirrels relevant through midgame and lategame

Deliverables:

- implement global `Squirrel Evolution` tracking and expose it through debug and later survey feedback
- tie player-caused squirrel violence to permanent global evolution increases
- make rising evolution unlock smarter and more destructive squirrel behavior without replacing local unrest as the trigger for current flareups
- implement pressure-scaled nut misplanting so it starts rarely at light pressure and becomes common under heavier pressure
- implement machine infestation as nuisance level 2 and the first true destruction-adjacent military-route escalation
- implement the first squirrel-evolution-driven sabotage behaviors needed for MVP, beyond infestation if playtests show infestation alone is insufficient
- ensure infestation can be calmed or suppressed through ecology recovery even though evolution itself does not reverse
- keep any added sabotage local, telegraphed, and diagnosable

Exit criteria:

- peaceful and militarized runs feel meaningfully different
- the player can de-escalate active destruction through recovery tools without erasing global squirrel evolution
- infestation, misplanting, and any included sabotage are disruptive enough to matter in larger factories without feeling arbitrary or impossible to diagnose

### 9. Rocket-Launch Ending And Ecological Summary

Hard stop before ship: mandatory endgame playtest.

Open questions to settle during implementation:

- what outcome bands the ending summary should use besides full success
- exact ecological score categories and weights
See [docs/QUESTIONS.md](QUESTIONS.md), section `22. Open Design Gaps From The Roadmap`.

Playtest focus:

- confirm the player understands that rocket launch ends the scenario
- confirm the final ecological summary reflects long-term stewardship rather than just the final map snapshot
- confirm the ending summary makes ecological failure legible even without peace-zone systems

Deliverables:

- trigger the scenario ending on rocket launch
- evaluate industrial success and ecological stewardship at rocket launch
- present a squirrel-specific ending summary with stewardship scoring and outcome messaging
- create and use the milestone manual playtest to validate endgame readability and ending flow

Non-coding design TODO:

- shape the final ecological scoring model before implementation is locked:
  - decide score categories and weights
  - decide how strongly long-term damage outweighs last-minute cleanup
  - decide how much squirrel deaths, pollution trend, habitat loss, and recovery each matter
  - decide what score output the player actually sees at the ending screen

Exit criteria:

- rocket launch ends the scenario cleanly
- the ecological summary reflects long-term stewardship rather than a final-map snapshot exploit
- the MVP ending reads clearly even without peace-zone-based truce logic

### 10. Post-V1 Extensions

Potential later upgrades:

- peace zones and sanctuary-region scoring
- `Nauvis Truce Victory` as the formal peace-zone-based best ending
- relocation drones as a non-MVP mitigation system, even though the implementation already exists and can be retained
- optional survey-station range upgrades through custom tuning or module-driven mechanics, with explicit extra power cost, only after v1 baseline survey UX is stable
- localized power-cable chewing on forest-edge poles, only if machine infestation alone does not provide enough evolved destruction pressure
- squirrel beacons as a possible relocation mechanism, but only if anti-abuse testing proves they cannot trap squirrels in loops

Hold until v1 is readable and stable:

- natural nut tree propagation by healthy colonies beyond the minimal v1 baseline
- population growth and colony scaling
- stronger biter passivity inside peace zones
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
9. Land food-chain visibility and squirrel facts before destructive military escalation so players first understand the ecosystem they are about to destabilize.
10. Land global squirrel evolution, misplanting scaling, machine infestation, and any needed sabotage before the rocket-launch ending so militarized late-game play has enough weight.
11. Ship the rocket-launch ending and ecological summary only after late-game escalation and the final endgame presentation pass a dedicated playtest before ship.

## Main Risks

- `Tree` and `unit` prototype work carries the highest content risk because it needs art-safe placeholders or generated assets.
- Belt interaction can become unfair fast if action cooldowns and target cooldowns are missing.
- Peace zones are easy to overtune; keep v1 local and conservative.
- Scenario-first worldgen requirements are important enough that they should not be deferred until after squirrel behavior exists.
