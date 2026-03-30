# Milestone 4 Drift Notes

Status: spec-alignment note for implementation

Scope reference:
- [docs/planned.md](../planned.md)
- [docs/SPEC.md](../SPEC.md)
- [docs/QUESTIONS.md](../QUESTIONS.md)

Current implementation note:
- The repo currently has ecology, nut, feeder, and survey scaffolding, but no real squirrel runtime yet. Milestone 4 is therefore the first slice that must make squirrels visible in-world and readable to a player.

## Required For Milestone

- Squirrels must be visible on the map and in forests near active player areas.
- Squirrels must have at least the core runtime states needed for Milestone 4 readability: calm, curious, mischievous, agitated, and grieving.
- Squirrels must be able to block belts, steal exactly one item from a belt, carry that item visibly, and retreat back toward forest space.
- Squirrels must create or use visible forest stashes so stolen goods are recoverable.
- Stash recovery must be possible in normal play.
- Chest scavenging must exist only as a higher-pressure escalation than belt theft.
- The visible nuisance loop must be rate-limited so one region does not become a deadlock machine.
- The player must be able to infer that forest condition is driving squirrel behavior, even before Milestone 5 retaliation and relocation arrive.

## Likely Acceptable Approximation

- Use a small, bounded number of local squirrel actors per active region or player vicinity rather than simulating a full colony swarm.
- Drive visible behavior from region metrics and a scripted state machine rather than attempting a fully autonomous animal simulation.
- Use a practical belt-interaction approximation if necessary, as long as it reads as a squirrel sitting on the belt and briefly interrupting flow.
- Use a visible carried-item state and a short retreat path even if the implementation is more scripted than organic.
- Start chest scavenging with a narrow, deterministic rule set if the full chest-family sweep is too broad for the first slice.
- Keep forest stashes simple and legible, even if they are implemented with chest-like runtime entities rather than a bespoke inventory system.

## Known Drift / Deferred Items

- True physical belt blocking is the highest-risk item. The spec and settled answers imply a squirrel should literally occupy the belt tile, but that may be too brittle to force perfectly in one milestone. If the implementation uses a scripted jam or simplified occupancy model, record that as an intentional approximation rather than pretending it is exact.
- Underground belt continuity is not a Milestone 4 requirement. The spec says later versions can make squirrels visibly vanish and reappear across underground belts. Do not let that expand Milestone 4 scope.
- Chest theft scope is broad in the settled answers: all chest types excluding infinity chest. If the first implementation cannot safely cover every chest family, do not silently narrow the scope. Call out the omission and keep the UX identical for the supported chest set.
- Chest reordering is explicitly deferred by the roadmap and should not leak into Milestone 4.
- Relocation, grief retaliation, revenge waves, and map-marker kill feedback belong to the later mitigation milestone, not this one.
- Colony breeding, peace zones, and endgame systems are out of scope for Milestone 4.

## Shippability Bound

Keep Milestone 4 small enough that a human can validate it in one play session:

- one visible squirrel state loop
- one belt-blocking and belt-theft loop
- one visible stash creation and recovery loop
- one bounded chest-scavenging escalation
- no relocation, no retaliation system, no chest reordering

If a feature needs a second milestone worth of tuning to become readable, push it out instead of folding it into Milestone 4.
