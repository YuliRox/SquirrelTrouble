# Brainstorm Sortierung: 2026-04-16

Source: `/mnt/c/Users/Sandra/Documents/logseq/journals/2026_04_16.md`

Purpose: Sort the unsorted friend-session notes into a usable mod-design document that can feed later planning, implementation, and playtests.

Related references:

- [docs/SPEC.md](SPEC.md)
- [docs/planned.md](planned.md)

## 1. Already Resolved Or External References

These notes are not new design content and should stay out of gameplay planning:

- `factorio-spritter`: GIF-to-Factorio sprite pipeline reference.
- `designer-skills`: possible agent persona / game-design support reference.
- `blender-factorio-utils`: Blender-to-sprite tooling reference.
- `ExportFactoriopediaForLLM`: data export tooling reference.
- `meshy.ai` and `tripo3d.ai`: model-generation references.

## 2. High-Level Direction

These notes reinforce the current core fantasy and should sit at the top of future planning:

- Nauvis should feel like a living ecosystem, not a passive resource field.
- The player's actions should be judged by ecological impact, not just factory throughput.
- The world should push toward coexistence and recovery rather than domination.
- Running out of local ecology should feel like a strategic failure condition even if the player is still alive.
- Peace should be easier and more effective than extermination.

## 3. Scenario Frame And End State

These notes describe the largest scenario-level structure:

- Leaving Nauvis can act as a scenario endpoint.
- The ending can include a post-run evaluation of how well the player preserved the ecosystem.
- The world being finite is important to the fantasy: local damage should matter and restarting should not be the intended answer inside a run.

### Candidate score inputs

- felled trees versus planted trees
- squirrel deaths
- pollution trend over time, especially whether the player mitigates late-game pollution
- land coverage by machines or concrete
- total machine count
- squirrel population versus biter population

## 4. Ecology Model

These notes fit the current ecology-first direction and can be treated as candidate simulation inputs:

- Nut trees are a critical food source in the food chain.
- Squirrels bury nuts and create new nut trees from that behavior.
- Squirrels must eat nuts regularly; scarcity forces them to search elsewhere.
- Early tree planting should be available.
- Forest restoration should visibly matter.
- Healthier forests should reduce biter pressure or evolution pressure.
- Cleaner, quieter, greener technology should reduce ecological strain over time.

### Strong candidate cause-and-effect chain

1. Deforestation and pollution reduce habitat quality.
2. Nut scarcity increases squirrel pressure.
3. Squirrel pressure pushes nuisance behavior toward the factory edge.
4. Ecological recovery lowers pressure more reliably than violence.

## 5. Squirrel Behavior And Internal State

These notes can be organized as the squirrel-side simulation model:

### Baseline behavior

- Squirrels should keep distance from the player and behave like shy animals.
- The engineer's presence can temporarily protect nearby machines because squirrels avoid close proximity.
- Squirrels visibly flee early so the wildlife reads as alive before it becomes disruptive.

### Internal stats and progression

- Squirrels can have an evolution factor or intelligence factor that rises over time or from player hostility.
- There may be a point-of-no-return threshold after which peaceful recovery becomes harder.
- Squirrels can have a fear or skittishness score that drops as they acclimate to the factory.
- Modern, quieter machinery could slow that acclimation pressure.

### Reproduction and population pressure

- Squirrels can reproduce in litters of `1-6`, which can feed population growth or regional spawn pressure.

## 6. Peaceful Path

These notes fit the repo's current preferred direction and should remain first-class:

- Biter aggression can be lower on the peaceful path.
- Biter expansion can be suppressed by healthy forests.
- The player can move squirrels into newly restored forest regions.
- A squirrel-attracting structure or beacon could support relocation or habitat guidance.
- A hidden or lightly signposted squirrel research branch can teach the peaceful route.
- `Squirrel Research 1-3` is a useful placeholder structure for staged unlocks.
- Tips and Tricks can explain what squirrels are and how to coexist with them.

## 7. Military Path

These notes define the hostile route, but they should stay explicitly weaker than coexistence:

- Attacking squirrels may need an early research gate.
- A special targeting structure could be required before turrets can target squirrels.
- Removing that structure could disable automated anti-squirrel targeting again.
- Squirrels should remain hard to hit; the brainstorm suggests very low base accuracy with modest upgrades only.
- Choosing violence should escalate the system rather than solve it cleanly.

## 8. Biter Relationship

These notes are the strongest candidate bridge between squirrels and Nauvis retaliation:

- Biters can be framed as predators or ecosystem enforcers rather than unrelated enemies.
- Damaging the food chain can explain why biters become more hostile.
- If squirrels are harmed, retaliation can include biter escalation.
- Early retaliation can be small and local; later retaliation can become wave-based.

### Candidate narrative framing

- No nut trees means less squirrel food.
- If biters depend on squirrels as part of the ecosystem, the player is effectively stealing or collapsing that food source.
- Retaliation then reads as ecological consequence instead of arbitrary punishment.

## 9. Retaliation And Escalation

These notes sort into a progression ladder:

### Passive escalation

- Early squirrels are more tolerant.
- Increasing pollution makes them more aggressive.
- If they lose habitat, they start damaging or obstructing nearby infrastructure.
- They may bury nuts inside the factory, causing trees to grow where the player does not want them.

### Active escalation after player aggression

- Biter aggression increases.
- Squirrels become smarter and harder to stop.
- They may learn to avoid defenses.
- They may expand into more coordinated raids over time.

### Late escalation examples from the brainstorm

- cable chewing, especially data cables
- coordinated night raids
- attacking drones with nuts or cones
- infesting machinery so it becomes inoperable
- spreading infestation from one machine to nearby machines
- tunneling retaliation biters that burst out of the ground

## 10. Pressure Targets And World Selection

These notes belong together as target-selection mechanics:

- Chunks can carry a score based on player structures.
- The same score can help choose high-value squirrel hostility targets.
- The same score can help choose high-value retaliation or biter attack targets.
- Items as well as map positions can be scored.

This is a strong fit for the repo's existing regional simulation approach.

## 11. Ideas That Conflict With The Current Spec

These ideas appeared in the brainstorm, but they currently conflict with [docs/SPEC.md](SPEC.md) and should be treated as explicit revisit items instead of silently merged into planning:

- direct building destruction by squirrels
- squirrels chewing cables and disabling infrastructure directly
- squirrels climbing walls or burrowing under defenses as a normal escalation path
- squirrels attacking drones directly
- machine infestation as direct building shutdown
- chest or machine destruction from underground retaliation spawns
- nuclear-reactor mutation events that create hyper-aggressive squirrels
- scenarios where the ecosystem or the player effectively "wins" through total destruction rather than nuisance and coexistence pressure

Reason for separation: the current spec deliberately frames squirrels as disruptive nuisance wildlife, not direct building-damage enemies.

## 12. Best Candidate Additions To The Current Design

If the brainstorm is mined for ideas that strengthen the current shipped direction without breaking it, these look like the best candidates:

- post-run ecology score at scenario end
- squirrel research branch as a discoverable teaching tool
- squirrel fear/skittishness as a readable behavior stat
- forest health affecting biter pressure
- squirrel-planted nut-tree regrowth
- regional structure score for target desirability
- relocation support via squirrel-attracting structures
- Tips and Tricks entries that explain squirrel ecology and the peaceful route

## 13. Open Design Questions Pulled From The Notes

- How exactly should the end-of-scenario ecology score be calculated?
- How finite should Nauvis be for this scenario?
- Should squirrel intelligence be reversible, or is a point of no return important?
- How much should biter behavior depend on forest health versus squirrel deaths?
- Should squirrel-led tree regrowth happen naturally, mechanically, or mainly as flavor feedback?
- Which military-route actions remain nuisance-based versus crossing into direct infrastructure damage?

## 14. Implementation Follow-Ups

- Categorize the brainstorm into `ecology`, `squirrel behavior`, `peace path`, `military path`, `retaliation`, and `scenario scoring`.
- Decide which conflict items should be rejected, deferred, or used to revise the current spec.
- Build midgame and lategame playtests against prepared saves if possible.
- Create or gather blueprints that quickly assemble representative test factories.
- Quantify the mechanics before implementation so pressure, escalation, and recovery have defensible numbers.
- Check whether prebuilt savegames already exist for milestone validation.
- Ask Yannick for blueprint support if that is still current.

## 15. Recommended Reading Order For Future Planning

When these notes are reused, process them in this order:

1. scenario frame and scoring
2. ecology model
3. squirrel internal state and behavior
4. peaceful path
5. military path
6. retaliation and biter relationship
7. implementation follow-ups
8. conflict items that need explicit design decisions
