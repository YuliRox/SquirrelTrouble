# Milestone 4 Manual Playtest

Default start: new scenario on Nauvis
Recommended checkpoint save: `m4-forest-edge-loop` after you have a short belt line near a forest edge and at least one stocked feeder nearby
Scope: first visible squirrel loop. This is a hard-stop milestone before Milestone 5. The playtest should confirm that squirrels are visible, readable, and disruptive in a way that still feels fair.
Automated coverage already exists for: region math, feeder bookkeeping, nut-tree recovery, and other deterministic foundation behavior.

## Current Status

Latest playtest outcome: partial pass, not yet accepted.

Validated so far:
- squirrels are visible on screen and can be distinguished from trees
- squirrels read as wildlife rather than hostile enemy units
- squirrels stay local to the forest edge instead of wandering across the whole base

Current failures:
- retest required after the latest belt-sitting, feeder-attraction, and rough-handling changes
- the next Milestone 4 retest should start from a fresh scenario so the new local squirrel population rules are what you are actually evaluating

Next implementation target:
- squirrels should range outward from forest habitat as pressure rises
- theft should happen opportunistically during those outward excursions
- after a successful haul, squirrels should still retreat back toward the forest

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

Debug aid:
- Clicking a squirrel should now show:
- an orange filled ground overlay for its current local infrastructure-detection radius
- a red outline ring for its broader belt-interest/excursion radius
Use this when checking whether a squirrel can plausibly notice a nearby belt or feeder.
This debug aid is controlled by `constants.debug_squirrel_selection_overlay`.

Checklist:
- [X] Walk to a forest edge where belts or chests are close enough to be a tempting target.
- [X] Wait without attacking anything.
- [X] Confirm squirrels are visible and easy to distinguish from trees.
- [X] Confirm squirrel movement reads like wildlife, not a hostile enemy unit.
- [X] Confirm the squirrels stay local to the forest edge instead of wandering randomly through the whole base.

Pass condition:
- A tester can immediately tell that squirrels exist, belong to the forest, and are reacting to nearby industry.

## Belt Nuisance

Preconditions:
- Stay at a forest edge with a short belt line in view.
- Item traffic helps make the blockage obvious, but passive belt sitting may also happen on an empty nearby belt.

Checklist:
- [X] Place items on the belt and watch the line for a short while.
- [X] Confirm at least one squirrel visibly moves onto a belt tile, stays on the belt for at least 5 seconds, and rides with the belt instead of just hovering beside it.
- [X] Confirm this can happen even before the forest is badly damaged.
- [X] Place a stocked feeder near the same belt and confirm nearby squirrels prefer the feeder and the passive belt-sitting stops.
- [X] Confirm the squirrel actually blocks that belt space while sitting there, rather than merely standing near the belt.
- [X] Confirm the belt blockage is short-lived and readable.
- [X] Confirm the line does not look permanently deadlocked.
- [X] Confirm squirrels seem to wander outward from the forest before engaging the belt instead of snapping to an arbitrary target.
- [X] Confirm the squirrel behavior feels annoying rather than opaque or arbitrary.

Pass condition:
- Belt interference is clearly visible, rate-limited, and understandable at a glance.

## Theft And Retreat

Preconditions:
- Keep a belt or chest close to the forest edge.
- Keep stocked feeders away from the target belt or chest so theft pressure is not being actively pacified.

Checklist:
- [X] Watch for a squirrel to leave the belt line or approach a chest.
- [X] Confirm the squirrel carries away a meaningful but bounded amount of loot at once.
- [X] Confirm the carried item is visible in the squirrel’s behavior or pathing.
- [X] Confirm a small carried-count number is visible with the stolen item while the squirrel is loaded up.
- [X] Follow the squirrel toward the forest.
- [X] Confirm it retreats back toward the forest rather than hanging around the factory edge forever.
- [X] If a feeder is stocked, confirm it is preferred over the nearby logistics target when both are available.

Pass condition:
- Theft looks like a physical, visible retreat into the forest, not a silent inventory edit.

## Stash Recovery

Preconditions:
- Have already seen at least one theft or retreat.
- Stay near the forest edge long enough to spot where stolen items end up.

Checklist:
- [X] Look for a visible squirrel stash in or near the forest.
- [X] Confirm the stash is readable as a recovery point, not just random clutter.
- [X] Retrieve items from the stash if the implementation allows it in this slice.
- [X] Confirm recovered items feel like they were actually stolen earlier.
- [X] Confirm an emptied stash is no longer an active recovery target.

Pass condition:
- Lost items feel recoverable and the stash reads like part of the ecology loop.

## Escalation Readability

Preconditions:
- Create a visibly damaged forest edge by clearing a few trees or leaving an exposed industrial corridor.
- Compare that area with a healthier forest edge nearby.

Checklist:
- [X] Observe the healthier forest edge first.
- [X] Observe the damaged edge next.
- [X] Confirm the damaged edge produces more disruptive squirrel behavior.
- [X] Confirm the behavior shift is local and tied to the damaged area.
- [X] Confirm squirrels now sit still for noticeable 5-10 second pauses instead of constantly sprinting.
- [X] If a squirrel is stepped on or killed accidentally, confirm the reaction is clearly noticeable and not easy to miss.
- [X] Walk over a squirrel on purpose and confirm it immediately flees and raises a noticeable rough-handling warning.

Pass condition:
- The player can tell that forest damage makes squirrel behavior worse without needing debug numbers.
