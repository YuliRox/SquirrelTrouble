# Milestone 1 Manual Playtest

Default start: new scenario on Nauvis  
Recommended checkpoint save: `m1-forest-baseline` after finding a dense forest patch and unlocking `Forest Surveying`  
Scope: survey readability, broad-vs-exact inspection flow, and visible ecology response to tree loss and pollution.  
Automated coverage already exists for: region mapping, exact metric computation, recent tree-loss tracking, rolling pollution retention, and feeder contribution math.

## Survey Gating Before Research

Preconditions:
- Start a new scenario.
- Move the engineer into a visibly forested area.
- Do not research `Forest Surveying` yet.

Checklist:
- [X] Press `ALT+S`.
- [X] Confirm the game tells you to research `Forest Surveying`.
- [X] Confirm it does not print raw debug output, missing locale keys, or script errors.

Pass condition:
- The feature is gated cleanly and communicates the next step.

## Broad Survey Without A Station

Preconditions:
- Stay in a forested area.
- Unlock `Forest Surveying`.
- Do not place a survey station yet.

Setup shortcuts:

```lua
/c game.player.force.technologies["forest-surveying"].researched = true
```

Checklist:
- [X] Press `ALT+S` while standing in a dense forest patch.
- [X] Confirm the game prints a broad state summary instead of exact numbers.
- [X] Confirm a second line explains that a `Forest Survey Station` is needed for exact values.
- [X] Walk to a noticeably thinner or more open area nearby.
- [X] Press `ALT+S` again.
- [X] Confirm the wording changes enough that the two areas do not feel identical.

Pass condition:
- Broad survey mode gives readable, player-facing guidance before exact instrumentation is placed.

## Exact Survey Station Flow

Preconditions:
- `Forest Surveying` is unlocked.
- You have one `Forest Survey Station`.

Setup shortcuts:

```lua
/c game.player.insert{name="forest-survey-station", count=1}
/c game.player.insert{name="solar-panel", count=1}
/c game.player.insert{name="small-electric-pole", count=2}
```

Checklist:
- [X] Place the survey station inside the same forest patch you used for the broad survey.
- [X] Place the `Solar Panel` and a `Small Electric Pole` so the survey station is powered.
- [X] If it is night, wait for daylight before continuing.
- [X] Stand beside the powered survey station and press `ALT+S`.
- [X] Confirm the report switches to exact numeric values.
- [X] Walk a short distance away but keep the station selected.
- [X] Press `ALT+S` again.
- [X] Confirm the exact report still feels anchored to the station area rather than your current tile.

Pass condition:
- The powered station-based inspection flow is spatially coherent and clearly more precise than broad survey mode.

## Deforestation Feedback

Preconditions:
- Use a dense forest patch with a survey station nearby.
- Take an exact survey baseline before cutting anything.

Checklist:
- [X] Survey the untouched patch once and note the overall tone of the report.
- [X] Mine at least three nearby trees inside the same forest region.
- [X] Confirm the deforestation warning message appears after the heavier local loss.
- [X] Survey the same patch again.
- [X] Confirm the report reads worse than the untouched baseline.
- [X] Walk to a separate untouched forest patch and survey there as a control.
- [X] Confirm the untouched patch still feels healthier than the damaged one.

Pass condition:
- Normal player tree cutting causes a visible and understandable local ecology penalty.

## Pollution Feedback

Preconditions:
- Use a forest patch with a survey station nearby.
- Have a few active burner machines and fuel available.

Setup shortcuts:

```lua
/c game.player.insert{name="burner-mining-drill", count=1}
/c game.player.insert{name="stone-furnace", count=1}
/c game.player.insert{name="coal", count=100}
```

Checklist:
- [X] Place active burner machines inside or immediately beside the forest patch.
- [X] Let them run for at least 20 seconds.
- [X] Survey the same region again.
- [X] Confirm pollution becomes part of the explanation for the region state.
- [X] Confirm the polluted patch reads worse than it did before the burners were running.

Pass condition:
- Local industry visibly feeds back into the ecology report instead of feeling disconnected from it.
