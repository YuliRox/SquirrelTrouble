# Milestone 2 Manual Playtest

Default start: new scenario on Nauvis  
Recommended checkpoint saves:
- `m2-picked-tree` immediately after harvesting a nut tree
- `m2-sapling-growth` immediately after planting one or more nut saplings
- `m2-feeder-loop` after unlocking `Wildlife Diversion`, placing a feeder, and placing a survey station  
Scope: visible nut-tree discovery, harvest/recovery presentation, replanting feel, and feeder-based habitat management.  
Automated coverage already exists for: starting grove guarantee, dense-forest nut-tree seeding, sapling bookkeeping, harvested-tree recovery bookkeeping, and region-score changes from saplings and stocked feeders.

Known current limitation:
- `Nut Tree` still uses interim vanilla-tree art. Treat hover name, selection, and harvest loop as the source of truth during this playtest. Do not fail Milestone 2 solely because mature nut trees are not yet visually distinct from every ordinary vanilla tree at a glance.

## Starting Grove Discovery

Preconditions:
- Start a brand-new scenario.
- Do not use map editor or console for this section.

Checklist:
- [X] Walk a few screens around spawn, prioritizing nearby forest.
- [X] Confirm you can find multiple `Nut Tree` entities near the starting area.
- [X] Hover likely candidates and confirm the tooltip or selection name clearly identifies `Nut Tree`.
- [X] Confirm you can intentionally target the same `Nut Tree` again once you know what you are looking for, even if the mature tree art is still interim.

Pass condition:
- The player can discover and intentionally use an early nut source through ordinary exploration plus normal hover/selection feedback.

## Nut Harvest Presentation

Preconditions:
- Stand beside a mature `Nut Tree`.
- Keep inventory space free.

Checklist:
- [X] Mine the `Nut Tree` by hand.
- [X] Confirm nuts appear in the inventory.
- [X] Confirm the tree becomes a `Picked Nut Tree` instead of disappearing completely.
- [X] Confirm the harvest hint message appears the first time and reads like sustainable harvesting guidance.

Pass condition:
- Nut collection feels like picking and recovery, not clear-cutting.

## Picked Tree Recovery

Preconditions:
- Create or load the `m2-picked-tree` checkpoint immediately after harvesting a nut tree.
- Leave the picked tree untouched.

Checklist:
- [X] Wait roughly 5 in-game minutes.
- [X] Revisit the same spot.
- [X] Confirm the `Picked Nut Tree` has turned back into a mature `Nut Tree`.
- [X] Harvest it again.
- [X] Confirm the same visible loop repeats cleanly.

Pass condition:
- Picked trees participate in a readable renewable-food loop.

## Arboriculture Guidance And Sapling Placement

Preconditions:
- Unlock `Arboriculture` through play or via a setup shortcut.
- Have at least one `Nut Sapling` item.

Setup shortcuts:

```lua
/c game.player.force.technologies["arboriculture"].researched = true
/c game.player.insert{name="nut-sapling", count=5}
```

Checklist:
- [X] Complete `Arboriculture` or apply the setup shortcut.
- [X] Confirm the Arboriculture guidance message appears once.
- [X] Select a `Nut Sapling` in the inventory.
- [X] Hover open ground at a forest edge or cleared patch.
- [X] Confirm the placement preview appears normally and does not show missing art.
- [X] Place the sapling.
- [X] Confirm the planted sapling is visibly smaller or weaker-looking than a mature `Nut Tree` and is easy to identify later.

Pass condition:
- Replanting reads clearly as a deliberate habitat-restoration action.

## Sapling Maturation

Preconditions:
- Create or load the `m2-sapling-growth` checkpoint immediately after planting saplings.
- Leave the saplings undisturbed.

Checklist:
- [X] Wait roughly 12 in-game minutes.
- [X] Revisit the planted area.
- [X] Confirm each surviving sapling has turned into a mature `Nut Tree`.
- [X] Confirm the transition is easy to notice when returning to the grove.

Pass condition:
- Slow reforestation is visually legible and understandable in normal play.

## Wildlife Diversion Guidance And Feeder Loop

Preconditions:
- Unlock `Wildlife Diversion` and `Forest Surveying` through play or via setup shortcuts.
- Have one `Squirrel Feeder`, one `Forest Survey Station`, and at least 20 nuts.
- Use a forest edge you can survey before and after stocking the feeder.

Setup shortcuts:

```lua
/c game.player.force.technologies["wildlife-diversion"].researched = true
/c game.player.force.technologies["forest-surveying"].researched = true
/c game.player.insert{name="squirrel-feeder", count=1}
/c game.player.insert{name="forest-survey-station", count=1}
/c game.player.insert{name="solar-panel", count=1}
/c game.player.insert{name="small-electric-pole", count=2}
/c game.player.insert{name="nut", count=40}
```

Checklist:
- [ ] Complete `Wildlife Diversion` or apply the setup shortcuts.
- [ ] Confirm the Wildlife Diversion guidance message appears once.
- [ ] Place a `Squirrel Feeder` on the forest edge.
- [ ] Confirm the newly placed feeder shows the empty wooden feeder art, not a vanilla chest or the stocked art.
- [ ] Confirm the feeder art and footprint make sense at that location.
- [ ] Place a `Forest Survey Station` nearby.
- [ ] Place the `Solar Panel` and a `Small Electric Pole` so the survey station is powered.
- [ ] If it is night, wait for daylight before comparing reports.
- [ ] Survey the region before stocking the feeder.
- [ ] Insert a single nut and confirm the feeder switches from the empty art to the stocked wooden feeder art.
- [ ] Insert at least 20 nuts into the feeder.
- [ ] Survey the same region again.
- [ ] Confirm the post-stocking report reads calmer or more trusted than the pre-stocking report.

Pass condition:
- Feeders feel like an understandable, visible mitigation tool rather than hidden score manipulation.
