# Squirrel Trouble Scenario Spec

Version: v1
Status: Working design spec
Target: Vanilla Factorio scenario on Nauvis, no Space Age

## Premise

The engineer lands on Nauvis under normal vanilla Factorio rules, but the forests are inhabited by visible squirrel colonies. Squirrels are not enemies. They are cute, neutral wildlife that become a persistent logistical nuisance when their habitat is damaged.

The scenario is built around one ecological rule:

- forests support squirrels
- squirrels tolerate respectful industry
- destroyed forests create hungry, disruptive squirrels
- violence against squirrels triggers retaliation from Nauvis itself

The intended arc is:

1. The player enjoys cute wildlife.
2. Early over-clearing and pollution create squirrel trouble.
3. The player learns to preserve and restore forests.
4. Coexistence becomes more effective than domination.

## Design Goals

- Preserve core vanilla Factorio progression and feel.
- Keep squirrels visible, readable, and memorable.
- Make squirrel interference serious enough that the player must respond.
- Make cooperation more effective than killing squirrels.
- Make squirrel behavior understandable rather than arbitrary.
- Ensure the long-term solution is automatable, not manual busywork.
- Reward forest preservation and restoration with practical ecological benefits.
- Tie squirrel well-being to pollution and nearby biter aggression.

## High-Level Pillars

### 1. Visible Wildlife

Squirrels are cute, animated neutral units that roam forests and the factory edge. They should feel alive even when not causing trouble.

### 2. Disruptive Nuisance, Not Direct Destruction

Squirrels do not chew buildings, breach walls, or behave like biters. Their pressure comes from blocking belts, stealing items, hiding loot, and shuffling chest contents.

### 3. Ecology Over Violence

The scenario should teach that preserving forests, feeding squirrels, and relocating them is better than shooting them.

### 4. Managed Coexistence

The player should be able to create stable, productive factory layouts with healthy forest corridors and well-managed squirrel colonies.

### 5. Automating Coexistence

The scenario should eventually become a classic Factorio problem:

- observe the system
- understand the cause
- build infrastructure to stabilize it
- automate the fix

If squirrel management remains mostly manual for too long, the scenario will feel like chores rather than Factorio.

## Core Simulation Model

The world is evaluated in forest regions, implemented as chunks or chunk clusters.

Each forest region tracks three key values.

### Forest Health

Represents whether the region remains viable squirrel habitat.

Factors that increase it:

- high ordinary tree density
- high nut tree density
- low pollution
- active squirrel feeders
- recent reforestation

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
- relocating rather than killing squirrels

Factors that decrease it:

- killing squirrels
- clear-cutting forests
- repeatedly stepping on squirrels
- prolonged local scarcity

### Habitat Pressure

Habitat pressure is a derived regional value that controls how disruptive squirrels become.

Habitat pressure rises when:

- forest health is low
- canopy is collapsing near industry
- unrest is high
- feeders are empty
- pollution is high

Habitat pressure falls when:

- forests are preserved or restored
- feeders are stocked
- nut trees are replanted
- squirrels are relocated into healthy forest

Design rule:

- the less habitat remains, the more severe squirrel actions become
- light pressure causes belt nuisance
- heavy pressure causes theft
- extreme pressure can unlock chest reordering as a last escalation

## Entity List

### Squirrel

Visible neutral wildlife unit.

Rules:

- spawns in forested regions
- ignored by turrets and military AI
- not counted as an enemy
- can be stepped on by the player
- can be killed by direct player damage

### Nut Tree

A dedicated tree type separate from ordinary trees.

Rules:

- appears naturally in some forests
- can be harvested for nuts
- can be regrown slowly by planting nuts
- absorbs more pollution than ordinary trees
- improves local squirrel food security

### Nut

A squirrel food item and a restoration resource.

Uses:

- stock squirrel feeders
- plant new nut trees

### Squirrel Feeder

A specialized chest-like entity placed by the player.

Purpose:

- primary peace offering
- preferred squirrel destination when stocked
- visible signal that an area is being managed
- practical wildlife diversion infrastructure

Rules:

- squirrels prefer stocked feeders over stealing
- empty feeders become disappointment points and can increase unrest
- feeders are best placed near forest edges and safe corridors

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

### Why Breedable Squirrels Matter

Healthy colonies provide stronger ecological effects:

- more natural nut tree propagation
- stronger local pollution control through healthier nut groves
- more stable peaceful forest zones
- more visible ecological recovery around managed forests

Neglected colonies also scale the downside:

- more squirrels are available to cause nuisance events
- retaliation pressure becomes more noticeable

This makes breeding a meaningful systemic amplifier, not just a cosmetic detail.

## Squirrel Behavior States

### Calm

Default state in healthy forest.

Behavior:

- wanders inside canopy
- idles, gathers, socializes
- visits feeders and stashes
- ignores factory logistics

### Curious

Triggered by nearby pollution, visible logistics, or damaged forest edge.

Behavior:

- approaches belts and chests near the forest edge
- investigates activity
- may linger without stealing yet

### Mischievous

Triggered by moderate unrest or food scarcity.

Behavior:

- sits on belts and blocks throughput briefly
- steals single items from belts
- may scavenge chests only under high habitat pressure
- carries loot to forest stashes or feeders

### Agitated

Triggered by being stepped on, rough handling, or high unrest.

Behavior:

- throws nuts at the engineer
- deals minor damage
- may alert nearby squirrels

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

## Nuisance Actions

Squirrel disruption should be meaningful, readable, and rate-limited.

### Belt Blocking

- A squirrel may occupy a single belt tile for a short duration.
- That tile is treated as blocked while the squirrel sits there.
- Belt blocking should be most common near the forest edge or poorly managed corridors.

### Belt Theft

- A squirrel may remove one item from a belt.
- It then carries the item visibly toward a stash or feeder.

### Chest Scavenging

- Under elevated habitat pressure, a squirrel may take a small stack from a chest.
- Chest stealing should begin only after forests are severely degraded or local unrest is high.
- Under extreme habitat collapse, a squirrel may move items between nearby chests to create disorder.
- Chest reordering is the final escalation tier and should be rare, local, and clearly linked to ecological collapse.
- Squirrels should not delete large quantities or fully destroy the base state.

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
- minor nut-throwing if stepped on

### Medium Pressure

- regular belt blocking
- single-item belt theft
- more squirrels leave forest and patrol factory edge

### High Pressure

- repeated belt theft
- chest stealing begins
- more items are carried to visible forest stashes

### Extreme Pressure

- chest reordering unlocks as a rare late-stage nuisance
- squirrels strongly prefer high-value targets
- grief and retaliation effects last longer after squirrel death

Design rule:

- the player should be able to feel the worsening state of the forest just by observing squirrel behavior

## Violence and Retaliation

If the player kills a squirrel:

- display the message: `Mother Nauvis mourns its squirrels.`
- apply an immediate unrest spike to nearby forest regions
- apply a temporary trust penalty
- spawn a localized biter revenge wave

Design intent:

- killing squirrels is possible
- killing squirrels is almost always the wrong solution
- one accidental death should hurt, but not end the run

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
- `Forest Survey Station` is the v1 primary tool for exposing forest health, unrest, trust, and habitat pressure
- early broad-state feedback can appear through tooltip-style inspection before the player has full numeric visibility
- richer map overlays can remain a later refinement
- feeders should visibly show whether squirrels are using them successfully
- squirrel death should produce an unmistakable warning and retaliation message

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

- squirrel feeders

Purpose:

- introduces the first automatable peace mechanism

### Forest Surveying

Unlocks:

- `Forest Survey Station`
- visibility of forest health, unrest, trust, and habitat pressure
- broad state bands in normal inspection, with exact numbers available through surveyed forest regions

Purpose:

- turns ecology from guesswork into an observable system

### Wildlife Relocation

Unlocks:

- relocation drones

Purpose:

- provides a nonlethal industrial solution to factory squirrel buildup

### Ecological Stabilization

Unlocks or improves:

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
- player unlocks squirrel feeders and nut restoration
- forest stewardship becomes a real logistical consideration
- research begins turning squirrel management into an automatable subsystem

### Mid/Late Game

- relocation drones unlock
- player can deliberately design forest corridors and sanctuary zones
- cooperation starts outperforming brute-force expansion

### Late Game

- mature forest regions absorb pollution and calm local biters
- squirrel nuisance drops sharply in well-managed areas
- the base can coexist with thriving wildlife instead of replacing it

## Scenario End State

This scenario does not need a hard victory condition yet. It should have a strong soft-win state.

Soft-win conditions:

- multiple forest regions are healthy
- squirrel trust is high and unrest is low
- feeders are consistently stocked
- nut groves are restored or expanding
- local biter peace zones exist
- squirrel disruption becomes rare and localized

At that point, the player has effectively automated coexistence rather than merely suppressing a nuisance.

Possible future formal objectives:

- maintain high trust across a target number of regions
- restore a target number of nut trees
- sustain a peaceful forest network for a fixed duration
- keep science production above a threshold while preserving habitat

## Scenario Endgame

This scenario should have a true squirrel-specific victory condition rather than ending as "normal vanilla, but squirrels help with pollution."

Design rule:

- squirrels should remain thematically central through late game
- the player should not win by simply shutting industry down and rewilding the map
- the ending should prove that advanced industry and thriving ecology can coexist
- the scenario should support multiple endgame variants built on the same ecology systems
- the current default should be implementable first, with a clean path toward more ambitious endings later

### Current Default

The current default ending is `Coexistence Victory`.

Reasoning:

- it is the most balanced blend of vanilla Factorio and squirrel-specific goals
- it gives the scenario a clear identity without overcomplicating the first implementation
- it establishes all systems needed for more advanced endings later

### Endgame Variants

The scenario should support three endgame variants:

- `Coexistence Victory`
- `Great Grove Victory`
- `Nauvis Truce Victory`

These variants should be designed as compatible evolutions of the same core systems rather than unrelated win conditions.

### Coexistence Victory

This is the primary intended ending for the first complete scenario version.

To win, the player must satisfy both industrial and ecological proof at the same time.

#### Industrial Proof

The player must demonstrate a functioning advanced factory, for example by one or more of:

- launching a rocket
- sustaining a target science production rate
- sustaining a target production output for a fixed duration

#### Ecological Proof

The player must demonstrate that squirrel habitat has been restored and stabilized, for example by:

- maintaining a target number of healthy forest sanctuary regions
- restoring a target number of nut trees or nut groves
- keeping a target number of squirrel feeders stocked
- maintaining high squirrel trust and low unrest across multiple regions

#### Peace Proof

The player must prove that coexistence is stable rather than temporary, for example by:

- maintaining local biter peace zones in multiple regions
- keeping squirrel disruption below a threshold for a fixed duration
- avoiding squirrel deaths for a fixed duration during the final phase

#### Concrete Thresholds

Recommended initial thresholds:

- launch `1` rocket
- maintain `6` healthy sanctuary regions for `20` consecutive minutes
- keep at least `12` stocked squirrel feeders active for `20` consecutive minutes
- maintain at least `200` mature nut trees on the map
- maintain at least `3` active peace zones for `20` consecutive minutes
- cause `no squirrel deaths` during the final `20` minute validation window

#### Pros

- balanced and easy to understand
- keeps vanilla factory progression relevant
- gives squirrels a real scenario-ending role without replacing the base game
- lowest implementation risk of the three variants

#### Cons

- can feel checklist-like if feedback and presentation are weak
- less visually dramatic than the more specialized endings

### Great Grove Victory

This variant is the most squirrel-centric and map-shaping ending.

The player wins by building and sustaining a major restored forest system that supports both ecology and industry.

#### Concrete Thresholds

Recommended initial thresholds:

- maintain `1` contiguous Great Grove made of `8` connected healthy sanctuary regions
- maintain at least `400` mature nut trees inside that grove
- keep at least `16` stocked squirrel feeders inside or adjacent to the grove for `30` consecutive minutes
- maintain a living squirrel population of at least `60` squirrels inside the grove network
- sustain `250` science per minute for `15` consecutive minutes while the grove remains valid
- cause `no squirrel deaths` during the final `30` minute validation window

#### Pros

- strongest squirrel theme and visual identity
- gives the player a memorable large-scale ecological construction project
- makes squirrels feel central in late game, not just managed

#### Cons

- more complex to explain and implement
- contiguous grove logic and squirrel population tracking must be reliable
- less grounded in standard vanilla victory expectations than Coexistence Victory

### Nauvis Truce Victory

This variant is the most ambitious and the most scenario-like.

The player wins by proving that the factory, the forest, and nearby hostile life can exist in a sustained regional truce.

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

- most distinctive and memorable ending
- gives the squirrel-biter relationship a true climax
- strongly reinforces the fantasy of earning acceptance on Nauvis

#### Cons

- highest implementation and balancing risk
- requires very clear definitions for peace zones, factory area, and successful attacks
- most vulnerable to feeling unfair if biter behavior is not sufficiently readable

### Shared Definitions

The endgame variants rely on common measurable definitions.

#### Healthy Sanctuary Region

A region qualifies as a healthy sanctuary region when:

- `Forest Health >= 75`
- `Squirrel Trust >= 70`
- `Squirrel Unrest <= 25`
- at least `20` mature trees are present in the region
- at least `8` of those trees are nut trees
- at least `1` stocked squirrel feeder is present in or adjacent to the region

#### Stocked Squirrel Feeder

A squirrel feeder counts as stocked when it contains at least `50` nuts.

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

If the victory conditions are met, the scenario should present a distinct squirrel-themed ending moment.

Suggested presentation:

- squirrels visibly gather in restored groves
- forest regions appear active and calm
- nearby biters in peace zones stand down unless attacked
- a unique ending message acknowledges coexistence

Possible message tone:

- `Mother Nauvis shelters those who make room for her children.`

### Development Path

The endgame system should be planned so the scenario can ship first with `Coexistence Victory` and later grow into `Nauvis Truce Victory`.

Recommended progression of implementation:

1. Ship `Coexistence Victory` first.
2. Build peace zones, sanctuary scoring, and trust/unrest tracking as reusable systems rather than one-off win-condition checks.
3. Add global region summaries and stronger biter-peace interactions.
4. Promote those systems into `Nauvis Truce Victory` once they are readable and stable.

Design rule:

- `Coexistence Victory` is the current default
- `Nauvis Truce Victory` is the aspirational advanced ending
- no system added for Coexistence should block future evolution toward Nauvis Truce

### Post-Victory Freeplay

After Coexistence Victory, the scenario should continue in freeplay.

Post-victory expectations:

- squirrels remain active and visible
- healthy forests continue reducing pollution and calming local biters
- the player can keep expanding while preserving coexistence
- squirrel systems remain part of the world instead of disappearing after the ending

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
- natural nut tree propagation by squirrels

## Open Questions

- Should squirrels enter trains and rail stations, or stay limited to belts and chests?
- How visible should region health be to the player: explicit UI, map overlays, or inferred from behavior?
- Should forest stashes respawn naturally, or only be created by squirrel actions?
- How strong should biter peace zones be before they feel exploitable?

## Tone and Presentation

The scenario should feel affectionate, mischievous, and slightly tragic when mistreated.

Desired player emotions:

- delight on first seeing squirrels
- annoyance when they block key logistics
- guilt when violence backfires
- satisfaction when the factory and forest finally coexist

This spec is the baseline document for future extension.
