# Squirrel Trouble Scenario Spec

Version: v1
Status: Working design spec
Target: Vanilla Factorio scenario on Nauvis, no Space Age

## Premise

The engineer lands on Nauvis under normal vanilla Factorio rules, but the forests are inhabited by visible squirrel colonies.

Squirrels are not baseline enemies. They are part of Nauvis' ecosystem:

- forests support squirrels
- biters prey on squirrels
- squirrels tolerate respectful industry
- habitat loss creates hungry, disruptive squirrels
- violence against squirrels teaches the ecosystem to retaliate harder

The intended arc is:

1. The player enjoys cute wildlife.
2. Early deforestation and pollution create squirrel trouble.
3. The player learns to preserve and restore forests.
4. Violence creates a military escalation spiral that can be calmed, but not unlearned.
5. The player reaches spaceflight while proving that industry and ecology can coexist on Nauvis.

## Design Goals

- Preserve core vanilla Factorio progression and feel.
- Keep squirrels visible, readable, and memorable.
- Make squirrel interference serious enough that the player must respond.
- Make coexistence more effective than killing squirrels.
- Keep squirrel behavior understandable rather than arbitrary.
- Ensure the long-term solution is automatable, not manual busywork.
- Reward forest preservation and restoration with grounded ecological benefits.
- Make the biter-squirrel predator relationship visible enough that the ecosystem feels real in play.

## Core Principles

- Squirrels are nuisance-first, not default destruction enemies.
- Squirrels do not destroy trees; the player destroys habitat.
- `Squirrel Unrest` is local and reversible.
- `Squirrel Evolution` is global and irreversible.
- Peaceful management can calm a region again, but cannot erase learned escalation.
- Healthy forests should improve logistics and safety, not grant abstract production buffs.
- The scenario ends on rocket launch, with a squirrel-specific ecological evaluation.

## Simulation Model

The world is evaluated in forest regions.

Settled baseline:

- one forest region = `2x2` chunks
- all regional metrics use a `0-100` scale
- ecology updates every `10` seconds
- major events cause immediate spikes, then normal recovery and decay happen gradually
- squirrel simulation uses a hybrid model: full local simulation near players, simplified regional scoring elsewhere

Each forest region tracks these local values:

### Forest Health

Represents whether the region remains viable squirrel habitat.

Increases from:

- high ordinary tree density
- high nut tree density
- low pollution
- active feeders
- recent reforestation
- tree healing or stump recovery

Decreases from:

- deforestation
- fire and combat damage
- high sustained pollution
- industrial sprawl with little remaining canopy

### Squirrel Unrest

Represents how desperate and disruptive the local colony currently is.

Increases from:

- recent tree cutting
- lack of nuts
- displacement from healthy forest
- empty feeders
- squirrel deaths
- heavy nearby pollution

Decreases from:

- stocked feeders
- healthy nut groves
- relocation into healthy forest
- time without conflict

### Squirrel Trust

Represents whether the colony sees the player as a tolerable neighbor.

Increases from:

- preserving forest belts and corridors
- maintaining stocked feeders
- restoring nut trees
- healing damaged groves
- relocating rather than killing squirrels

Decreases from:

- killing squirrels
- clear-cutting forests
- repeated rough handling
- prolonged local scarcity

### Habitat Pressure

Derived regional value controlling how disruptive squirrels become right now.

Pressure rises when:

- forest health is low
- canopy collapses near industry
- unrest is high
- feeders are empty
- pollution is high

Pressure falls when:

- forests are preserved or restored
- damaged trees are healed
- feeders are stocked
- nut trees are replanted
- squirrels are relocated into healthy forest

Design rule:

- light pressure causes belt nuisance and rare misplanting
- medium pressure causes more frequent theft and cleanup pressure
- high pressure unlocks machine infestation
- extreme pressure can unlock deeper sabotage only if squirrel evolution is also high

### Squirrel Evolution

Represents how much Nauvis' squirrel population as a whole has permanently adapted to player hostility.

It is:

- global
- raised mainly by player violence
- not reversible

Raised by:

- killing squirrels
- repeated direct attacks on squirrels
- repeated player-owned accidental kills such as trains, vehicles, turrets, or combat robots
- choosing dedicated anti-squirrel military tools

Not reduced by:

- reforestation
- stocked feeders
- relocation
- time without conflict

Design rule:

- forests and feeders can calm current unrest
- they cannot erase global squirrel evolution
- later habitat damage can therefore reactivate worse behavior faster if the player already taught squirrels war

## Core Entities

### Squirrel

Visible neutral wildlife unit.

Rules:

- spawns in forested regions
- should already inhabit healthy forests before the player arrives
- population upkeep should refill gradually, not in one burst
- ignored by normal turret targeting
- can be stepped on
- can be killed by player-caused damage

### Nut Tree

Dedicated squirrel food tree.

Rules:

- appears naturally in some forests
- can be harvested for nuts
- regrows slowly from planted nuts
- can also spread slowly through squirrel nut-burying
- absorbs more pollution than ordinary trees

### Nut

Squirrel food and restoration resource.

Uses:

- stock feeders
- plant nut trees

### Squirrel Feeder

Wildlife diversion infrastructure.

Tiers:

- `Wooden Squirrel Feeder`: early, cheap, low-capacity
- `Steel Squirrel Feeder`: later, larger-capacity, higher-uptime

Rules:

- squirrels prefer stocked feeders over theft
- feeders visibly attract squirrels
- empty feeders increase disappointment and unrest
- feeder tiers differ by capacity, durability, and uptime, not by separate squirrel rulesets

### Tree Treatment Kit

Nonlethal ecological restoration tool.

Rules:

- heals damaged trees and eligible stumps
- supports habitat recovery without replacing preservation
- should become automatable later if manual use is too burdensome

### Forest Stash

Visible squirrel stash in or near forests.

Rules:

- created only by squirrel actions
- stores stolen items
- stays visible and recoverable
- should feel like an ecological recovery point, not random clutter

### Relocation Drone

Midgame nonlethal squirrel management tool.

Rules:

- moves squirrels away from factory hotspots
- works only on squirrels
- works best when healthy destination forest exists
- should improve trust when used correctly
- should eventually integrate cleanly with home-colony reassignment after colony collapse

## Population And Food Chain

Squirrel populations scale with habitat quality rather than breeding buildings.

Regional population capacity depends on:

- total tree cover
- nut tree density
- feeder availability
- pollution level

Population grows slowly when:

- forest health is good
- feeders are stocked
- unrest is low
- pollution is manageable

Population declines when:

- habitat is lost
- squirrels are killed
- pollution stays too high
- food is unavailable

If a forest colony is destroyed badly enough that squirrels can no longer respawn there, that should create a food-chain imbalance:

- there are fewer squirrels available as prey
- nearby biters should redirect aggression toward player infrastructure more often
- replanting forests should therefore become an attractive indirect biter-defense strategy

### Colony Collapse And Home Reassignment

If a squirrel loses its home colony entirely, it should not become a meaningless orphaned actor.

Design intent:

- squirrels without a viable home should try to attach themselves to another colony if one can support them
- a newly planted or restored forest should be able to attract homeless squirrels back into peaceful cooperation
- if no viable home exists, homeless squirrels should become the most ferocious against player infrastructure
- even homeless squirrels still need retreat behavior, loot stashing, and somewhere to bury stolen goods

This requires explicit design for:

- what counts as losing a home colony
- how far squirrels can search for a replacement colony
- when they join a new colony versus remaining feral
- what stash or retreat behavior they use while effectively homeless

### Minimum Viable Forest

Squirrel respawn should require a minimum viable forest state.

Design intent:

- squirrel colonies should not instantly recover from total habitat collapse
- but the ecosystem should also not stay permanently empty without a clear player path to recovery
- restoring enough forest should reopen squirrel respawn and help rebalance nearby biter behavior

This needs an explicit game-facing definition, not just hidden tuning.

### Natural Predation

Squirrels are prey in the Nauvis ecosystem.

Rules:

- when the player is nearby, biters should occasionally visibly chase and eat squirrels
- this should teach the predator relationship without collapsing squirrel populations
- squirrels eaten by biters do not trigger mourning, retaliation, or trust penalties
- natural predation should be compensated through normal forest-side refill so squirrel presence stays stable enough for gameplay

Design intent:

- the player should understand that logging forests and killing squirrels also destroys a food source inside Nauvis
- biter retaliation should read as ecological consequence, not arbitrary faction logic

## Behavior And Escalation

Squirrel behavior is driven by two things:

- current local `Habitat Pressure` and `Squirrel Unrest`
- global `Squirrel Evolution`

### Calm

Healthy forest behavior.

Squirrels:

- wander inside canopy
- idle, gather, and socialize
- visit feeders and stashes
- may sit on a nearby forest-edge belt as a low-grade nuisance

### Curious / Mischievous

Triggered by nearby pollution, damaged forest edges, or moderate food pressure.

Squirrels:

- widen their wander radius toward the factory edge
- inspect belts and chests
- sit on belts and block throughput briefly
- steal from belts and later retreat with loot
- may stash stolen goods in visible forest stashes
- may bury nuts in factory fringe areas

Misplanting rule:

- misplanting can happen already at light pressure
- it should be rare at first
- the higher the pressure, the more often it occurs
- it should remain a whole-game management problem

### Agitated

Triggered by rough handling or high unrest.

Squirrels:

- range farther from the forest
- throw nuts at the engineer
- become more disruptive and alert nearby squirrels

### Infesting

Triggered by high pressure plus sufficient squirrel evolution.

Squirrels:

- target vulnerable machines at forest edges or neglected corridors
- temporarily make machines inoperable or unreliable
- spread infestation if ignored

Design rule:

- infestation is nuisance level 2
- it is the main midgame/lategame answer to “simple theft no longer matters enough”
- it is not baseline behavior; it belongs to escalated or militarized colonies

### Militarized

Triggered by high global squirrel evolution plus renewed local unrest.

Squirrels:

- reactivate more destructive or sabotage-capable behavior
- coordinate more aggressively around high-value targets
- calm down again if the forest recovers
- do not forget what they learned

## Nuisance And Sabotage Actions

### Belt Blocking

- squirrels can move onto belt tiles and visibly ride them
- passive belt sitting should remain readable for several seconds
- stocked feeders should suppress belt sitting locally
- squirrels should reach belts by wandering outward from habitat, not by snapping to distant targets

### Belt Theft

- squirrels can steal from belts during visible nuisance bursts
- carried item and carried count should be visible
- squirrels should retreat with loot toward forest stashes or feeders

### Chest Scavenging

- begins only at higher pressure
- should remain local and readable
- chest reordering stays an extreme-pressure escalation, not a baseline mechanic

### Machine Infestation

- unlocked by pressure plus squirrel evolution
- should disable or degrade machines temporarily rather than instantly demolishing them
- should become the main midgame/lategame squirrel headache on militarized runs

### Ground Dropping And Stashing

- interrupted squirrels may drop items on the ground
- successful raids should often end in visible forest stashes
- lost goods should usually remain recoverable

## Theft Preference

Squirrels prefer items that are:

- shiny
- edible-looking
- mechanically valuable

Strong candidates:

- metals
- wood
- circuits
- science packs
- higher-tier crafted components

Implementation rule:

- use a computed desirability score
- squirrels prioritize the highest-scoring accessible target

## Military Route

The player can choose violence, but it is intentionally an escalation trap rather than a clean alternate strategy.

Rules:

- squirrels should remain poor military targets
- anti-squirrel violence solves an immediate annoyance while making future coexistence harder
- player-caused squirrel harm raises global `Squirrel Evolution`

Higher squirrel evolution can unlock:

- faster reactivation after fresh habitat damage
- smarter target selection
- coordinated incursions
- machine infestation as a stable sabotage layer
- localized cable chewing or similar sabotage if later needed

Calm versus forgetting:

- forests, feeders, and relocation can restore calm
- they do not erase squirrel evolution
- later deforestation can therefore revive worse behavior faster than before

## Violence And Retaliation

If the player kills a squirrel:

- show `Mother Nauvis mourns its squirrels.`
- spike nearby unrest
- apply a temporary trust penalty
- raise global squirrel evolution
- spawn a localized biter revenge wave from a nearby nest if one exists

Design intent:

- killing squirrels is possible
- killing squirrels is usually the wrong solution
- one accidental death should hurt, but not end the run

Important distinction:

- natural predation by biters does not trigger retaliation
- only player-caused harm feeds the military escalation loop

## Player Tools And Feedback

### Intended Player Tools

- preserve forest belts and corridors
- stock feeders
- plant nut trees
- heal damaged habitat
- relocate squirrels

### Feedback Rules

Players must be able to understand why squirrels are escalating.

Primary feedback channels:

- squirrel behavior itself
- visible biter-on-squirrel predation
- `Forest Survey Station`
- feeder usage and empty/full states
- clear death and retaliation messages
- researched Tips and Tricks entries

The survey station is the main observation tool and should expose:

- forest health
- squirrel unrest
- squirrel trust
- habitat pressure
- later, squirrel evolution as a long-term danger signal
- whether a region is still viable squirrel habitat or has fallen below squirrel-respawn viability

Design rule:

- if escalation is unreadable, the system will feel random and unfair
- if squirrel collapse causes biters to retarget the player more aggressively, the player needs clear enough feedback to understand why restoring forest helps

## Benefits Of Healthy Forests

Healthy forests should improve operations in grounded ways.

Operational benefits:

- lower pollution through trees and nut trees
- fewer squirrel nuisance events
- calmer factory edges
- more reliable logistics through less theft and infestation
- recoverable losses through visible stashes

### Peace Zones

Well-managed forests can create localized peace zones.

Requirements:

- high forest health
- high squirrel trust
- low unrest
- enough nut trees

Effects:

- reduced nearby biter aggression
- lower escalation pressure around sanctuary regions
- some nearby biters may become passive unless attacked in later versions

Design rule:

- peace zones must stay local
- they should create ecological safe pockets, not globally switch biters off

## Research

The squirrel branch should stay compact and practical.

### Arboriculture

Unlocks:

- nut harvesting
- nut planting
- early nut tree management

### Wildlife Diversion

Unlocks:

- `Wooden Squirrel Feeder`
- early squirrel Tips and Tricks entries

### Forest Surveying

Unlocks:

- `Forest Survey Station`
- exact survey readouts
- readable station footprint and survey UI

### Wildlife Relocation

Unlocks:

- relocation drones

### Ecological Stabilization

Unlocks or improves:

- `Steel Squirrel Feeder`
- stronger nut-tree pollution absorption
- stronger peace-zone effects
- better feeder preference

### Tips And Tricks

Research should unlock squirrel facts over time.

They should explain:

- squirrels are part of Nauvis' ecosystem
- biters prey on squirrels
- feeders calm and divert squirrels
- deforestation and pollution raise unrest
- destroyed forests can stop squirrel respawn and push biters toward player infrastructure
- violence raises irreversible squirrel evolution
- late-game sabotage is best suppressed through ecology, not force

## Progression

### Early Game

- squirrels appear as harmless wildlife
- early deforestation triggers first nuisance
- the player learns that squirrels are not enemies

### Mid Game

- theft and belt nuisance become real logistics problems
- feeders, restoration, and survey tools become core management systems
- violent players begin unlocking long-term escalation risk

### Late Game

- relocation, steel feeders, and better forestry tools scale coexistence
- militarized runs unlock infestation and stronger sabotage
- healthy forests create local peace zones
- rocket launch ends the scenario and evaluates stewardship

## Ending

The scenario ends when the player launches a rocket.

Reasoning:

- rocket launch is the clearest vanilla end trigger
- the squirrel scenario should conclude on Nauvis
- there is no strong squirrel-specific post-Nauvis design

At rocket launch, the scenario should:

- evaluate industrial success
- evaluate ecological stewardship
- summarize how responsibly the player industrialized Nauvis

### Scoring

Candidate score inputs:

- felled trees versus planted trees
- squirrel deaths caused by the player
- pollution trend over time
- land sealed by machines or paving
- machine footprint in ecologically sensitive areas
- squirrel population health and persistence
- sanctuary and peace-zone stability

Design rule:

- the score must reflect long-term stewardship, not just the final map snapshot

## Nauvis Truce Victory

This is the only intended scenario ending.

On rocket launch, award `Nauvis Truce Victory` only if the player proved that the factory, the forest, and nearby hostile life can exist in sustained regional truce.

Recommended initial thresholds:

- launch `1` rocket
- maintain `4` active peace zones for `25` consecutive minutes
- at least `2` of those peace zones must border enemy territory or lie within `3` chunks of a live biter nest
- maintain global average `Squirrel Trust >= 75` across inhabited forest regions for `25` consecutive minutes
- maintain global average `Squirrel Unrest <= 20` across inhabited forest regions for `25` consecutive minutes
- cause `no squirrel deaths` during the final `25` minute validation window
- receive no successful biter attack on the main factory area during that same window

Shared definitions:

- `Healthy Sanctuary Region`:
  - `Forest Health >= 75`
  - `Squirrel Trust >= 70`
  - `Squirrel Unrest <= 25`
  - at least `20` mature trees
  - at least `8` nut trees
  - at least `1` stocked feeder in or adjacent to the region
- `Active Peace Zone`:
  - a healthy sanctuary where local ecology is currently suppressing nearby biter aggression
- `No Squirrel Deaths`:
  - zero player-caused squirrel deaths during the validation window

Ending presentation:

- squirrels gather in restored groves
- forests appear calm
- nearby biters in peace zones stand down unless attacked
- the game presents a distinct squirrel-themed ending message

## Balancing Targets

- squirrels should feel alive without saturating the whole map
- nuisance should force adaptation without feeling arbitrary
- losses should be painful but usually recoverable
- feeders should be cheaper than enduring constant disruption
- reforestation should be slow but meaningful
- peaceful and militarized runs should feel materially different
- late-game squirrel disruption must still matter in large factories

## MVP Scope

First playable version should include:

- visible squirrels in forests
- squirrel neutrality toward turrets
- belt blocking
- belt theft
- chest scavenging at higher pressure
- visible forest stashes
- feeders
- nut trees and nuts
- minimal squirrel misplanting
- nut-throw retaliation when stepped on
- squirrel death messaging and biter revenge waves
- unrest and trust logic tied to deforestation and feeding
- readable player feedback for forest state
- machine infestation
- squirrel-evolution-driven sabotage
- final rocket-launch scoring presentation

Deferred from MVP:

- population growth and colony scaling
- advanced desirability tuning

Later design candidates, not fully settled:

- relocation drones
- peace zones
- chest reordering

## Open Questions

- Should squirrels enter trains and rail stations, or stay limited to belts and chests?
- How visible should region health be: explicit UI, map overlays, or mostly inferred from behavior?
- What exactly counts as a minimum viable forest for squirrel respawn after colony collapse?
- How should the player be told that squirrel collapse is increasing nearby biter pressure?
- How should homeless squirrels behave before they successfully join a new colony?
- What are the exact rules for home-colony reassignment after habitat collapse or restoration?
- How strong can peace zones become before they feel exploitable?
- Which deeper sabotage should ship first after infestation, if any?
- How should the final ecological score be weighted so late cleanup cannot erase bad history?

## Tone And Presentation

The scenario should feel affectionate, mischievous, and slightly tragic when mistreated.

Desired player emotions:

- delight on first seeing squirrels
- annoyance when they disrupt logistics
- guilt when violence backfires
- dread when an evolved population wakes back up after fresh habitat damage
- satisfaction when factory and forest finally coexist

This spec is the baseline document for future extension.
