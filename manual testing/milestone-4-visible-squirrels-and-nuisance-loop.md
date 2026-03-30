# Milestone 4 Manual Playtest

Default start: new scenario on Nauvis
Recommended checkpoint save: `m4-forest-edge-loop` after you have a short belt line near a forest edge and at least one stocked feeder nearby
Scope: first visible squirrel loop. This is a hard-stop milestone before Milestone 5. The playtest should confirm that squirrels are visible, readable, and disruptive in a way that still feels fair.
Automated coverage already exists for: region math, feeder bookkeeping, nut-tree recovery, and other deterministic foundation behavior.

## First Sighting

Preconditions:
- Start from a fresh scenario or a save where your factory touches a forest edge.
- Reach a spot where you can see both trees and player logistics from the same screen.
- If needed, use setup shortcuts to get a simple forest-edge test area quickly.

Setup shortcuts:

```lua
/c game.player.force.research_all_technologies()
/c game.player.insert{name="transport-belt", count=100}
/c game.player.insert{name="squirrel-feeder", count=1}
/c game.player.insert{name="nut", count=100}
```

Checklist:
- [ ] Walk to a forest edge where belts or chests are close enough to be a tempting target.
- [ ] Wait without attacking anything.
- [ ] Confirm squirrels are visible and easy to distinguish from trees.
- [ ] Confirm squirrel movement reads like wildlife, not a hostile enemy unit.
- [ ] Confirm the squirrels stay local to the forest edge instead of wandering randomly through the whole base.

Pass condition:
- A tester can immediately tell that squirrels exist, belong to the forest, and are reacting to nearby industry.

## Belt Nuisance

Preconditions:
- Stay at a forest edge with a short belt line in view.
- Put a small amount of item traffic on that belt.

Checklist:
- [ ] Place items on the belt and watch the line for a short while.
- [ ] Confirm at least one squirrel visibly sits on or interrupts the belt.
- [ ] Confirm the belt blockage is short-lived and readable.
- [ ] Confirm the line does not look permanently deadlocked.
- [ ] Confirm the squirrel behavior feels annoying rather than opaque or arbitrary.

Pass condition:
- Belt interference is clearly visible, rate-limited, and understandable at a glance.

## Theft And Retreat

Preconditions:
- Keep a belt or chest close to the forest edge.
- Have at least one stocked feeder nearby if the implementation supports feeder diversion in this slice.

Checklist:
- [ ] Watch for a squirrel to leave the belt line or approach a chest.
- [ ] Confirm the squirrel carries away only a small amount of loot at once.
- [ ] Confirm the carried item is visible in the squirrel’s behavior or pathing.
- [ ] Follow the squirrel toward the forest.
- [ ] Confirm it retreats back toward the forest rather than hanging around the factory edge forever.
- [ ] If a feeder is stocked, confirm it is preferred over the nearby logistics target when both are available.

Pass condition:
- Theft looks like a physical, visible retreat into the forest, not a silent inventory edit.

## Stash Recovery

Preconditions:
- Have already seen at least one theft or retreat.
- Stay near the forest edge long enough to spot where stolen items end up.

Checklist:
- [ ] Look for a visible squirrel stash in or near the forest.
- [ ] Confirm the stash is readable as a recovery point, not just random clutter.
- [ ] Retrieve items from the stash if the implementation allows it in this slice.
- [ ] Confirm recovered items feel like they were actually stolen earlier.
- [ ] Confirm an emptied stash is no longer an active recovery target.

Pass condition:
- Lost items feel recoverable and the stash reads like part of the ecology loop.

## Escalation Readability

Preconditions:
- Create a visibly damaged forest edge by clearing a few trees or leaving an exposed industrial corridor.
- Compare that area with a healthier forest edge nearby.

Checklist:
- [ ] Observe the healthier forest edge first.
- [ ] Observe the damaged edge next.
- [ ] Confirm the damaged edge produces more disruptive squirrel behavior.
- [ ] Confirm the behavior shift is local and tied to the damaged area.
- [ ] If a squirrel is stepped on or killed accidentally, confirm the reaction is clearly noticeable and not easy to miss.

Pass condition:
- The player can tell that forest damage makes squirrel behavior worse without needing debug numbers.
