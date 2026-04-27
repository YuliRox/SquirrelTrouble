# Squirrel Trouble Scenario Spec

Version: v1
Status: Working design spec
Target: Vanilla Factorio scenario on Nauvis, no Space Age

## Premise

The engineer lands on Nauvis under normal vanilla Factorio rules, but the forests are inhabited by visible squirrel colonies. Squirrels are not enemies. They are cute, neutral wildlife that become a persistent logistical nuisance when their habitat is damaged.

The scenario is built around one ecological rule:

- forests support squirrels
- squirrels are part of Nauvis' food chain
- squirrels tolerate respectful industry
- destroyed forests create hungry, disruptive squirrels
- violence against squirrels teaches the ecosystem to retaliate harder

The intended arc is:

1. The player enjoys cute wildlife.
2. Early over-clearing and pollution create squirrel trouble.
3. The player learns to preserve and restore forests.
4. Violence creates a military escalation spiral that can be calmed, but not unlearned.
5. Coexistence becomes more effective than domination.

## Design Goals

- Preserve core vanilla Factorio progression and feel.
- Keep squirrels visible, readable, and memorable.
- Make squirrel interference serious enough that the player must respond.
- Make cooperation more effective than killing squirrels.
- Make squirrel behavior understandable rather than arbitrary.
- Ensure the long-term solution is automatable, not manual busywork.
- Reward forest preservation and restoration with practical ecological benefits.
- Reward direct ecological care such as replanting and healing damaged groves.
- Tie squirrel well-being to pollution and nearby biter aggression.
- Make the biter-squirrel predator relationship visible enough that the ecosystem feels real in play.

## High-Level Pillars

### 1. Visible Wildlife

Squirrels are cute, animated neutral units that roam forests first and only push toward the factory edge when pressure rises. They should feel alive even when not causing trouble.

### 2. Disruptive Nuisance, Not Direct Destruction

Squirrels are not direct building-destruction enemies by default. Their early and peaceful-path pressure comes from blocking belts, stealing items, hiding loot, infesting machinery, misplanting nuts, and later shuffling chest contents.

Squirrels must not damage or consume trees. Habitat loss is caused by the player, pollution, fire, and industrial expansion, not by squirrels destroying the forest that sustains them.

If the player takes the military route, squirrels can evolve into more destructive behavior. Destruction is therefore an escalation tier, not a baseline identity.

### 3. Ecology Over Violence

The scenario should teach that preserving forests, feeding squirrels, and relocating them is better than shooting them.

Violence remains possible, but it should permanently raise the long-term risk profile of the colony even if short-term calm is restored later.

### 4. Visible Food Chain

Nauvis should feel like a real ecosystem, not two unrelated systems sharing the same map.

That means:

- biters should sometimes visibly chase and eat squirrels when the player is nearby enough to witness it
- squirrels eaten by biters should count as natural predation, not player-caused tragedy
- natural predation should not trigger retaliation or mourning feedback
- the player should understand that destroying forests is also destroying a food source inside Nauvis' ecology
### 5. Managed Coexistence

The player should be able to create stable, productive factory layouts with healthy forest corridors and well-managed squirrel colonies.

### 6. Automating Coexistence

The scenario should eventually become a classic Factorio problem:

- observe the system
- understand the cause
- build infrastructure to stabilize it
- automate the fix

If squirrel management remains mostly manual for too long, the scenario will feel like chores rather than Factorio.

### 7. Reversible Calm, Irreversible Adaptation

The scenario uses two different escalation axes:

- `Squirrel Unrest`: current, local or regional, and reversible through habitat recovery, feeders, and nonlethal management
- `Squirrel Evolution`: long-term global adaptation of Nauvis' squirrel population, primarily raised by player violence, and not reversible

This distinction is central to the intended arc:

- habitat damage and hunger make squirrels currently aggressive
- violence teaches squirrels smarter and more destructive counterplay
- restoring forests can calm them again
- but once a colony has adapted to war, later habitat damage can reactivate more severe behaviors faster

## Core Simulation Model

The world is evaluated in forest regions, implemented as chunks or chunk clusters.

Each forest region tracks four key values.

### Forest Health

Represents whether the region remains viable squirrel habitat.

Factors that increase it:

- high ordinary tree density
- high nut tree density
- low pollution
- active squirrel feeders
- recent reforestation
- recent tree healing or stump recovery

Factors that decrease it:

- deforestation
- fire and combat damage
- high sustained pollution
- nearby industrial sprawl with little canopy left

### Squirrel Unrest

Represents how desperate and aggressive the local colony is.

Factors that increase it:

- recent tree cutting
- lack of nuts
- displacement from healthy forest
- empty feeders
- squirrel deaths
- heavy nearby pollution

Factors that decrease it:

- stocked squirrel feeders
- healthy nut groves
- successful relocation into healthy forest
- time without conflict

### Squirrel Trust

Represents whether the colony sees the player as a tolerable neighbor.

Factors that increase it:

- keeping forest belts intact
- maintaining stocked feeders
- restoring nut trees
- healing damaged groves
- relocating rather than killing squirrels

Factors that decrease it:

- killing squirrels
- clear-cutting forests
- repeatedly stepping on squirrels
- prolonged local scarcity

### Squirrel Evolution

Represents how much Nauvis' squirrel population as a whole has permanently adapted to player hostility.

Factors that increase it:

- killing squirrels
- repeated direct attacks on squirrels
- repeated rough handling through player-owned violence sources such as trains, vehicles, turrets, or combat robots
- choosing military tools that target squirrels directly

Factors that do not reduce it:

- reforestation
- stocked feeders
- relocation
- time without conflict

Design rule:

- `Squirrel Evolution` is global and not reversible
- peaceful recovery can calm current behavior, but it does not erase learned escalation potential

### Habitat Pressure

Habitat pressure is a derived regional value that controls how disruptive squirrels become right now.

Habitat pressure rises when:

- forest health is low
- canopy is collapsing near industry
- unrest is high
- feeders are empty
- pollution is high

Habitat pressure falls when:

- forests are preserved or restored
- damaged trees are healed and eligible stumps are regrown
- feeders are stocked
- nut trees are replanted
- squirrels are relocated into healthy forest

Design rule:

- the less habitat remains, the more severe squirrel actions become
- light pressure causes belt nuisance
- heavy pressure causes theft
- light pressure can already produce rare nut misplanting
- high pressure can unlock machine infestation and make misplanting much more common
- extreme pressure can unlock chest reordering or destructive sabotage if squirrel evolution is also high

## Entity List

### Squirrel

Visible neutral wildlife unit.

Rules:

- spawns in forested regions
- initial population should be seeded during chunk generation so healthy forests can already look inhabited when first discovered
- runtime population upkeep should refill gradually instead of creating a full squirrel burst on first sight
- ignored by turrets and military AI
- not counted as an enemy
- can be stepped on by the player
- can be killed by direct player damage
- becomes more dangerous over time if the player repeatedly chooses violence

### Nut Tree

A dedicated tree type separate from ordinary trees.

Rules:

- appears naturally in some forests
- can be harvested for nuts
- can be regrown slowly by planting nuts
- can also spread slowly through squirrel nut-burying in healthy colonies
- absorbs more pollution than ordinary trees
- improves local squirrel food security

### Nut

A squirrel food item and a restoration resource.

Uses:

- stock squirrel feeders
- plant new nut trees

### Squirrel Feeder

A specialized chest-like wildlife feeder placed by the player.

Purpose:

- primary peace offering
- preferred squirrel destination when stocked
- visible signal that an area is being managed
- practical wildlife diversion infrastructure

Planned tiers:

- `Wooden Squirrel Feeder`: early, cheap, low-capacity feeder that reads like a simple chest or trough of nuts near the forest edge
- `Steel Squirrel Feeder`: later, higher-capacity feeder that keeps busy factory-edge hotspots calmer for longer without changing the core squirrel logic

Rules:

- squirrels prefer stocked feeders over stealing
- squirrels should visibly visit stocked feeders, pause beside them, and occasionally consume nuts before wandering off
- the wooden feeder is the first peace offering; the steel feeder is the scaled-up version for heavier pressure and longer uptime
- empty feeders become disappointment points and can increase unrest
- feeders are best placed near forest edges and safe corridors
- feeder tiers should differ mostly by capacity, durability, and uptime, not by introducing separate squirrel behaviors

### Tree Treatment Kit

A nonlethal ecological restoration tool inspired by forestry care rather than combat.

Purpose:

- heal damaged trees
- regrow eligible stumps or burned groves
- provide a direct restoration option besides planting

Rules:

- works on trees, damaged groves, and eligible stumps, not on buildings
- improves local habitat recovery but does not replace preserving forests
- grants a modest trust benefit when used to restore damaged habitat
- should become automatable later if it proves too manual

### Forest Stash

A visible squirrel stash placed in or near forests.

Purpose:

- stores stolen items
- acts as an ecological landmark
- creates scavenger-hunt and recovery moments for the player

Rules:

- always visible to the player
- may contain stolen shinies, edibles, wood, or mislaid factory components
- may be claimed or emptied by the player

### Squirrel Beacon

Post-v1 candidate, not a committed v1 feature.

Reasoning:

- we need a relocation mechanism and this could be a solution
- however, a squirrel beacon is prone to player abuse if it allows squirrels to be trapped or endlessly redirected
- in particular, it must be tested carefully so players cannot catch squirrels in loops by placing beacons in a circle

Current design stance:

- do not treat squirrel beacons as a guaranteed implementation
- if implemented later, they must complement ecology and relocation rather than trivializing squirrel behavior

### Relocation Drone

A nonlethal squirrel-management tool unlocked in mid game.

Purpose:

- remove squirrels from belts, chests, and production zones
- return them to healthy forest

Rules:

- works only on squirrels, not enemies
- grants trust when used correctly
- works best when a healthy destination forest exists

## Squirrel Population Model

Squirrels should be breedable, but indirectly through habitat health rather than manual breeding buildings.

Each forest region has a colony population cap based on:

- total tree cover
- nut tree density
- number of stocked feeders
- pollution level

Population grows slowly when:

- forest health is good
- feeders are stocked
- unrest is low
- pollution is manageable

Population declines when:

- habitat is lost
- squirrels are killed
- local pollution is too high
- food is unavailable

### Natural Predation

Squirrels are also prey inside the Nauvis ecosystem.

Rules:

- when the player is nearby, biters should occasionally be able to visibly chase and eat a squirrel
- this should happen often enough to teach the predator relationship, but not so often that squirrel populations collapse on their own
- squirrels eaten by biters do not trigger mourning, retaliation, or trust penalties
- natural predation should be compensated by forest-side population upkeep so the visible food chain does not destabilize the scenario
- in practice, a squirrel lost to biter predation should be replaced by a later squirrel spawn or refill in valid forest habitat

Design intent:

- biters eating squirrels makes the food chain legible
- the player is then clearly harming Nauvis by eliminating a prey species and damaging its habitat
- retaliation reads as ecological consequence, not arbitrary faction logic

### Why Breedable Squirrels Matter

Healthy colonies provide stronger ecological effects:

- more natural nut tree propagation
- stronger local pollution control through healthier nut groves
- more stable peaceful forest zones
- more visible ecological recovery around managed forests

Neglected colonies also scale the downside:

- more squirrels are available to cause nuisance events
- retaliation pressure becomes more noticeable
- higher squirrel populations make later military-route sabotage more materially disruptive once evolution is unlocked

This makes breeding a meaningful systemic amplifier, not just a cosmetic detail.

## Squirrel Behavior States

### Calm

Default state in healthy forest.

Behavior:

- wanders inside canopy
- idles, gathers, socializes
- visits feeders and stashes
- may move onto a nearby belt tile at the forest edge and sit there even in otherwise healthy habitat
- leaves nearby belts alone when a stocked feeder is pacifying the same area

### Curious

Triggered by nearby pollution, visible logistics, or damaged forest edge.

Behavior:

- expands its wander radius toward the forest edge
- investigates belts and chests near the forest edge
- may linger without stealing yet

### Mischievous

Triggered by moderate unrest or food scarcity.

Behavior:

- wanders beyond the canopy and spends more time outside safe forest cover
- can move onto a belt tile, ride with the belt for a short time, and block throughput while sitting there
- steals repeated batches from belts until carrying a full stack or being interrupted
- may scavenge chests only under high habitat pressure
- retreats with loot to forest stashes or feeders after a successful haul
- may bury nuts in factory fringe ground or paved areas, creating unwanted saplings or trees that the player must clear

### Agitated

Triggered by being stepped on, rough handling, or high unrest.

Behavior:

- ranges farther from the forest before retreating
- throws nuts at the engineer
- deals minor damage
- may alert nearby squirrels

### Infesting

Triggered by high habitat pressure, limited access to food, and sufficient squirrel evolution.

Behavior:

- targets vulnerable machines at the forest edge or in poorly defended corridors
- temporarily makes infested machines inoperable or less reliable until the infestation is cleared
- prefers repeated annoyance and downtime over instant catastrophic destruction
- can spread pressure to nearby machines if ignored

Design rule:

- infestation is nuisance level 2 and should become a real midgame and lategame management problem
- infestation is not baseline squirrel behavior; it belongs to escalated or militarized colonies

### Content

Triggered by good habitat, stocked feeders, and high trust.

Behavior:

- rarely interferes with the factory
- spends more time in forest space
- strengthens peaceful ecological bonuses

### Grieving

Triggered by squirrel death in or near the region.

Behavior:

- raises local and temporary global unrest
- reduces feeder preference for a while
- increases nuisance chance
- triggers biter retaliation

### Militarized

Triggered by high squirrel evolution combined with renewed unrest or habitat collapse.

Behavior:

- reactivates destructive or sabotage-capable behaviors that peaceful colonies would not use
- coordinates more aggressively around high-value targets
- returns to forest cover when calm is restored, but keeps the learned escalation potential

## Nuisance Actions

Squirrel disruption should be meaningful, readable, and rate-limited.

### Belt Blocking

- Belt sitting means a squirrel moves onto a belt tile, stops there, and is visually carried by the belt while remaining on that lane.
- While sitting on that belt tile, the squirrel should block that space so belt items cannot pass through it normally.
- Passive belt sitting should remain visible for at least 5 seconds before the squirrel leaves or escalates into theft.
- Light belt sitting may happen even in healthy forest-edge areas.
- Passive belt sitting may target an empty nearby belt; actual theft still requires real items on the line.
- Stocked feeders should locally suppress that passive belt sitting in their vicinity.
- Stocked feeders should also attract nearby squirrels away from belts so the diversion is visible, not just statistical.
- Heavier belt blocking should be most common near the forest edge or poorly managed corridors.
- Squirrels should reach belts by visibly wandering outward from habitat, not by seeming to spawn directly onto a distant logistics target.

### Belt Theft

- A squirrel may stay on belts and keep stealing from nearby moving items until it has built up a meaningful carried stack.
- Belt raids should feel like a visible nuisance burst, not a one-item joke.
- The carried item and the carried count should both be visible while the squirrel is loaded up.
- It then carries the accumulated stack visibly back toward a stash or feeder in the forest.

### Chest Scavenging

- Under elevated habitat pressure, a squirrel may take a full stack from a chest, limited by the available item count.
- Chest stealing should begin only after forests are severely degraded or local unrest is high.
- Under extreme habitat collapse, a squirrel may move items between nearby chests to create disorder.
- Chest reordering is the final escalation tier and should be rare, local, and clearly linked to ecological collapse.
- Squirrels should not delete large quantities or fully destroy the base state.

### Machine Infestation

- Under high pressure and elevated squirrel evolution, squirrels may infest machines near the forest edge or inside neglected factory corridors.
- Infested machines should become temporarily inoperable, unreliable, or blocked until the player intervenes.
- Infestation should read as sabotage-through-occupation rather than instantaneous demolition.
- If ignored, infestation can spread to nearby eligible machines and become the main midgame/lategame squirrel headache.

### Nut Misplanting

- Squirrels may bury nuts in paved or built-up areas even at light pressure, but it should be rare at first.
- Those buried nuts can sprout into unwanted saplings or trees inside the factory fringe.
- The higher the habitat pressure, the more often this occurs.
- This should remain a whole-game management problem even on peaceful runs.

### Ground Dropping

- Squirrels may drop stolen items on the ground if interrupted or distracted.
- This creates recoverable mess, not total loss.

### Forest Stashing

- Squirrels deposit stolen items in visible forest stashes.
- Recovering stash contents should be possible and often worthwhile.

## Theft Preference Rules

Squirrels prefer items that are either visually shiny, seemingly edible, or mechanically valuable.

Preferred categories:

- metals
- wood
- circuits
- science packs, especially shiny-looking ones
- higher-tier components with higher crafted value

Implementation rule:

- each item receives a squirrel desirability score
- squirrels prioritize the highest-scoring accessible target

This creates both thematic behavior and predictable gameplay pressure.

## Escalation Ladder

Squirrel actions should escalate with habitat pressure so the player can read the connection between environmental damage and factory disruption.

### Low Pressure

- visible roaming near forest edge
- occasional belt sitting
- rare nut misplanting in factory fringe areas
- minor nut-throwing if stepped on

### Medium Pressure

- regular belt blocking
- repeated belt theft that builds toward full carried stacks
- more squirrels leave forest and patrol factory edge
- nut misplanting becomes more noticeable and starts demanding cleanup

### High Pressure

- repeated belt theft
- full-stack chest stealing begins
- more items are carried to visible forest stashes
- nut misplanting becomes frequent
- machine infestation begins

### Extreme Pressure

- chest reordering unlocks as a rare late-stage nuisance
- machine infestation becomes common enough to threaten sustained throughput
- localized power-cable chewing on forest-edge poles can unlock if squirrel evolution is high
- squirrels strongly prefer high-value targets
- grief and retaliation effects last longer after squirrel death
- destruction-tier sabotage can appear only when both habitat pressure and squirrel evolution are high

Design rule:

- the player should be able to feel the worsening state of the forest just by observing squirrel behavior
- pressure should widen outward squirrel wandering and deepen initial incursions before theft
- successful theft should still resolve as retreat back toward forest habitat rather than further exploration into the base
- if sabotage or cable chewing is added, it must stay local, visibly telegraphed, and easy to diagnose and repair

## Military Route And Evolution

The player can take a military route against squirrels, but it is intentionally a trap-like escalation path rather than a clean alternate strategy.

### Military Route Rules

- players can attack squirrels directly after unlocking the relevant tools or choosing to use player-caused violence
- squirrels are difficult targets and should remain a poor-efficiency use of violence
- military success should solve an immediate annoyance while making future coexistence harder
- anti-squirrel violence raises global `Squirrel Evolution`, which does not go back down

### What Evolution Unlocks

Higher `Squirrel Evolution` can unlock:

- faster reactivation of hostility after new habitat damage
- smarter target selection
- more coordinated incursions
- machine infestation as a stable sabotage layer
- localized cable chewing or similar infrastructure sabotage
- a stronger shift from recoverable nuisance into reversible-but-costly destruction

### Calm Versus Forgetting

- forests, feeders, and nonlethal management can return squirrel unrest to calm
- calm colonies retreat back toward forest behavior
- but they do not forget what they learned from war
- if the player logs the forest again later, evolved colonies can return to destructive behavior much faster than untouched colonies

## Violence and Retaliation

If the player kills a squirrel:

- display the message: `Mother Nauvis mourns its squirrels.`
- apply an immediate unrest spike to nearby forest regions
- apply a temporary trust penalty
- apply a permanent global squirrel evolution increase
- spawn a localized biter revenge wave from a nearby nest if one exists

Design intent:

- killing squirrels is possible
- killing squirrels is almost always the wrong solution
- one accidental death should hurt, but not end the run

Important distinction:

- squirrels killed by biters as part of natural predation do not trigger retaliation
- only player-caused squirrel harm should feed the military escalation loop

## Player Interaction

### Stepping On Squirrels

If the player walks over a squirrel:

- the squirrel takes offense
- it throws nuts at the engineer
- the engineer takes minor damage

This should be funny the first time and mildly dangerous when repeated.

### Nonlethal Management

The intended player tools are:

- preserve forest belts
- stock squirrel feeders
- plant nut trees
- use relocation drones

## Player Feedback

The player must be able to understand why squirrels are behaving badly.

Recommended feedback channels:

- squirrel behavior itself serves as a visible ecological warning
- occasional visible biter-on-squirrel predation should reinforce that squirrels are part of the local food chain
- `Forest Survey Station` is the v1 primary tool for exposing forest health, unrest, trust, and habitat pressure
- the survey station should eventually expose squirrel evolution as a distinct long-term danger signal
- early broad-state feedback can appear through tooltip-style inspection before the player has full numeric visibility
- richer map overlays can remain a later refinement
- feeders should visibly show whether squirrels are using them successfully
- squirrel death should produce an unmistakable warning and retaliation message
- researched Tips and Tricks entries should explain squirrel ecology, biter predation, feeder use, relocation, and why violence escalates the system

Design rule:

- if the player cannot tell why squirrels are escalating, the system will feel random and unfair

## Forest Bonuses

Healthy forests should not give magical raw production buffs like free crafting speed. They should give grounded operational benefits that still improve production outcomes.

### Primary Forest Bonuses

- reduced local pollution through tree and nut tree absorption
- reduced nearby biter aggression
- partial peaceful behavior from biters entering well-managed forest zones
- fewer squirrel nuisance events due to higher trust and lower unrest

### Secondary Forest Bonuses

- healthy squirrel colonies spread nut trees more effectively
- content squirrels are more likely to return to feeders than steal
- visible forest stashes make lost items recoverable instead of permanently gone
- some dropped or misplaced items are more likely to end up in recoverable stashes rather than staying lost in the factory fringe

### Design Decision

The scenario should avoid direct buffs like `+10% assembler speed`. The reward for healthy forests should be smoother logistics, fewer attacks, cleaner air, and lower attrition.

## Biter Peace Zones

Well-managed forests can create localized peace zones.

Requirements:

- high forest health
- high squirrel trust
- low unrest
- sufficient nut tree presence

Effects in and near the zone:

- reduced biter aggression
- some nearby biters become passive unless attacked
- reduced chance of biter escalation from pollution in that region

Important limitation:

- this effect is local, not global
- the scenario should create ecological safe pockets, not permanently pacify all biters

## Thematic Framing

The squirrel systems should feel like industrial ecology, not a detached cute minigame.

Preferred framing:

- nut trees are a managed species
- squirrel feeders are wildlife diversion infrastructure
- relocation drones are industrial wildlife control
- forest corridors are pollution-management and peace-buffer assets

Design rule:

- the scenario can be charming, but its mechanics should still feel grounded inside Factorio's world of engineering, pollution, and territorial pressure

## Research

The scenario should include a compact squirrel-related research branch using standard vanilla science packs.

Research should not create a separate minigame. It should answer the usual Factorio question: "How do I engineer a better solution?"

### Arboriculture

Unlocks:

- nut harvesting
- nut planting
- early nut tree management

Purpose:

- gives the player a recovery path after early over-clearing

### Wildlife Diversion

Unlocks:

- `Wooden Squirrel Feeder`
- first squirrel-related Tips and Tricks entries

Purpose:

- introduces the first automatable peace mechanism
- begins teaching the peaceful route in explicit in-game documentation

### Forest Surveying

Unlocks:

- `Forest Survey Station`
- visibility of forest health, unrest, trust, and habitat pressure
- broad state bands in normal inspection, with exact numbers available through a survey-station forest footprint
- a selection overlay that shows the survey station reach directly, instead of hidden region boxes
- a selected survey station should also show a side panel with the exact health, unrest, trust, pressure, tree counts, and feeder state for that local footprint

Purpose:

- turns ecology from guesswork into an observable system

### Squirrel Facts And Tips

Squirrel-related research should unlock Tips and Tricks entries over time.

These entries should explain facts the player is unlikely to infer reliably from one play session.

Early entries can cover:

- squirrels are part of Nauvis' ecosystem
- biters prey on squirrels
- feeders calm and divert squirrels
- deforestation and pollution increase squirrel unrest

Later entries can cover:

- relocation and habitat recovery
- squirrel evolution through violence
- why calm can be restored even though adaptation is not reversible
- late-game sabotage and how to suppress it through ecology instead of force

Design rule:

- Tips and Tricks should function as in-world ecological field notes
- they should support discovery without replacing the need to observe behavior directly

### Wildlife Relocation

Unlocks:

- relocation drones

Purpose:

- provides a nonlethal industrial solution to factory squirrel buildup

### Ecological Stabilization

Unlocks or improves:

- `Steel Squirrel Feeder`
- stronger nut tree pollution absorption
- stronger local peace-zone effects
- improved squirrel preference for feeders over theft

Purpose:

- makes coexistence scale into late game

## Progression

### Early Game

- player encounters squirrels as harmless wildlife
- heavy early deforestation triggers first nuisance actions
- player learns that squirrels are not enemies

### Mid Game

- nuisance becomes serious enough to disrupt belts and storage
- player unlocks wooden squirrel feeders and nut restoration
- forest stewardship becomes a real logistical consideration
- research begins turning squirrel management into an automatable subsystem
- if the player leans on violence, squirrel evolution starts unlocking infestation and smarter sabotage

### Mid/Late Game

- relocation drones unlock
- iron squirrel feeders unlock as the larger-capacity coexistence tool for sustained hotspots
- player can deliberately design forest corridors and sanctuary zones
- cooperation starts outperforming brute-force expansion
- machine infestation and factory misplanting should keep squirrel management relevant even after simple theft stops mattering economically

### Late Game

- mature forest regions absorb pollution and calm local biters
- squirrel nuisance drops sharply in well-managed areas
- the base can coexist with thriving wildlife instead of replacing it

## Scenario End State

The scenario should end with a formal squirrel-specific outcome, not with an undefined soft-win state.

Before launch, the player's ecology may already feel stabilized in practice:

- multiple forest regions are healthy
- squirrel trust is high and unrest is low
- feeders are consistently stocked
- nut groves are restored or expanding
- local biter peace zones exist
- squirrel disruption becomes rare and localized

But that practical stabilization is not the ending by itself. The actual scenario ending happens on rocket launch.

## Scenario Scoring

When the scenario ends on rocket launch, the game should summarize how responsibly the player industrialized.

Candidate score inputs:

- felled trees versus planted trees
- number of squirrel deaths caused by the player
- pollution trend over time, especially whether late-game mitigation improved the map state
- land area sealed by machines, paving, or industrial sprawl
- total machine footprint or density in key ecological areas
- squirrel population health and persistence
- number and stability of healthy sanctuary or peace-zone regions

Design rule:

- the final score should reward long-term stewardship, not just the final map snapshot
- a player should not be able to clear-cut early, then barely replant at the end and receive a top ecological outcome

## Scenario End Trigger

The scenario ends when the player launches a rocket.

Reasoning:

- rocket launch is the clearest vanilla Factorio end trigger
- the squirrel scenario should conclude on Nauvis rather than continue into space
- there is currently no strong squirrel-specific design for post-Nauvis gameplay

Required behavior:

- launching a rocket ends the scenario
- the ending evaluates both industrial success and ecological stewardship on Nauvis
- the player receives a summary of how well they preserved the ecosystem while industrializing

This should reinforce the central fantasy:

- you did not merely industrialize Nauvis
- you were judged by how you treated its living systems while reaching spaceflight

Possible future formal objectives:

- maintain high trust across a target number of regions
- restore a target number of nut trees
- sustain a peaceful forest network for a fixed duration
- keep science production above a threshold while preserving habitat

## Scenario Endgame

This scenario should have a true squirrel-specific end evaluation rather than ending as "normal vanilla, but squirrels help with pollution."

Design rule:

- squirrels should remain thematically central through late game
- the player should not win by simply shutting industry down and rewilding the map
- the ending should prove that advanced industry and thriving ecology can coexist
- the ending should stay simple enough to explain and validate cleanly

### Nauvis Truce Victory

This is the only intended scenario ending.

On rocket launch, the scenario should award `Nauvis Truce Victory` only if the player proved that the factory, the forest, and nearby hostile life can exist in a sustained regional truce.

#### Concrete Thresholds

Recommended initial thresholds:

- launch `1` rocket
- maintain `4` active peace zones for `25` consecutive minutes
- at least `2` of those peace zones must border enemy-controlled territory or lie within `3` chunks of a live biter nest
- maintain global average `Squirrel Trust >= 75` across all inhabited forest regions for `25` consecutive minutes
- maintain global average `Squirrel Unrest <= 20` across all inhabited forest regions for `25` consecutive minutes
- cause `no squirrel deaths` during the final `25` minute validation window
- receive no successful biter attack on the main factory area during that same `25` minute window

#### Pros

- distinctive and memorable
- gives the squirrel-biter relationship a true climax
- strongly reinforces the fantasy of earning acceptance on Nauvis

#### Cons

- requires very clear definitions for peace zones, factory area, and successful attacks
- can feel unfair if biter behavior is not sufficiently readable

### Shared Definitions

The ending relies on these common measurable definitions.

#### Healthy Sanctuary Region

A region qualifies as a healthy sanctuary region when:

- `Forest Health >= 75`
- `Squirrel Trust >= 70`
- `Squirrel Unrest <= 25`
- at least `20` mature trees are present in the region
- at least `8` of those trees are nut trees
- at least `1` stocked squirrel feeder is present in or adjacent to the region

#### Stocked Squirrel Feeder

A squirrel feeder counts as stocked when it contains at least the tier-specific nut threshold needed to satisfy squirrels locally. Wooden and steel feeders should use the same preference logic but different capacities and refill cadence.

#### Active Peace Zone

An active peace zone is a healthy sanctuary region where the local ecology system is currently suppressing nearby biter aggression.

#### No Squirrel Deaths

`No squirrel deaths` means zero squirrel deaths caused by the player or player-owned forces during the relevant validation window.

### Endgame Intent

The player should feel that they have not conquered the squirrels, but earned acceptance on Nauvis.

This creates the intended scenario arc:

1. squirrels are charming wildlife
2. habitat loss turns them into a serious logistical problem
3. the player learns to engineer coexistence
4. the factory and forest stabilize together
5. Nauvis accepts the player's presence

### Endgame Presentation

On rocket launch, the scenario should present a distinct squirrel-themed ending moment if `Nauvis Truce Victory` is achieved.

Suggested presentation:

- squirrels visibly gather in restored groves
- forest regions appear active and calm
- nearby biters in peace zones stand down unless attacked
- a unique ending message acknowledges coexistence

Possible message tone:

- `Mother Nauvis shelters those who make room for her children.`

### Development Path

Recommended progression of implementation:

1. Build peace zones, sanctuary scoring, and trust/unrest tracking as reusable systems rather than one-off win-condition checks.
2. Add global region summaries and stronger biter-peace interactions.
3. Make the rocket-launch end screen evaluate those systems directly for `Nauvis Truce Victory`.

Design rule:

- `Nauvis Truce Victory` is the intended ending
- endgame systems should be built directly toward that result rather than through temporary placeholder endings

## Balancing Targets

- squirrels should be common enough to feel alive, but not saturate the whole map
- nuisance should be frequent enough to force adaptation, but not arbitrary
- item loss should be painful, but usually recoverable
- feeder use should be cheaper than enduring constant theft
- reforestation should be slow, but strong enough to recover from early mistakes
- breeding should strengthen both upside and downside, depending on player behavior
- the player should be able to solve squirrel pressure with infrastructure and research, not constant manual babysitting

## MVP Scope

First playable version should include:

- visible squirrel units spawning in forests
- squirrel neutrality toward turrets
- belt blocking
- belt theft
- chest scavenging under higher pressure
- visible forest stashes
- squirrel feeders
- nut trees and nuts
- squirrel-planted nut spread or misplanting in a minimal form
- squirrel nut-throw retaliation when stepped on
- squirrel death message and biter revenge wave
- unrest/trust logic tied to deforestation and feeding
- basic player feedback for forest state

The following can wait until a later version:

- relocation drones
- biter peace zones
- breeding and colony scaling
- chest reordering as an extreme-pressure escalation
- advanced item desirability tuning
- machine infestation
- squirrel evolution-aware sabotage and destruction behaviors
- scenario scoring and leave-Nauvis ending presentation

## Open Questions

- Should squirrels enter trains and rail stations, or stay limited to belts and chests?
- How visible should region health be to the player: explicit UI, map overlays, or inferred from behavior?
- Should forest stashes respawn naturally, or only be created by squirrel actions?
- How strong should biter peace zones be before they feel exploitable?
- Which destructive sabotage behaviors should ship first once the military route is implemented: machine infestation, cable chewing, or both?
- How should the final ecological score be weighted so cleanup at the end cannot erase a bad industrial history?

## Tone and Presentation

The scenario should feel affectionate, mischievous, and slightly tragic when mistreated.

Desired player emotions:

- delight on first seeing squirrels
- annoyance when they block key logistics
- guilt when violence backfires
- dread when a previously militarized colony wakes back up after fresh habitat damage
- satisfaction when the factory and forest finally coexist

This spec is the baseline document for future extension.
