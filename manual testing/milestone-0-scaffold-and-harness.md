# Milestone 0 Manual Playtest

Default start: new scenario on Nauvis  
Recommended checkpoint save: none  
Scope: load quality, visible scaffold presentation, and basic player-facing affordances.  
Automated coverage already exists for: prototype registration, recipe unlock wiring, remote interface smoke, and base region math.

## Fresh Start Load

Preconditions:
- `squirrel_madness` is enabled.
- Start a brand-new Nauvis freeplay.

Checklist:
- [X] Reach the game world without a startup error dialog.
- [X] Open the in-game chat or recent log messages.
- [X] Confirm there are no missing locale keys such as `item-name.*`, `entity-name.*`, or `message.*`.
- [X] Open the inventory and crafting UI.
- [X] Confirm the mod does not introduce obviously broken placeholder text into the normal early-game UI.

Pass condition:
- The mod loads cleanly and reads like intentional content rather than a broken scaffold.

## Controls And Research Presentation

Preconditions:
- Remain in the same fresh scenario.

Checklist:
- [X] Open `Settings -> Controls -> Mods`.
- [X] Find `Survey local forest region`.
- [X] Find `Relocate selected squirrel`.
- [X] Confirm both control names are localized and readable.
- [X] Confirm the default bindings are `ALT+S` and `ALT+R`.
- [X] Open the technology screen.
- [X] Find `Arboriculture`, `Wildlife Diversion`, `Forest Surveying`, `Wildlife Relocation`, and `Ecological Stabilization`.
- [X] Confirm each entry has a readable name, description, and icon.

Pass condition:
- The scaffolded controls and technology branch are discoverable and visually sane.

## Scaffold Entity Placement

Preconditions:
- Use the same scenario.

Setup shortcuts:

```lua
/c game.player.force.research_all_technologies()
/c game.player.insert{name="squirrel-feeder", count=1}
/c game.player.insert{name="forest-survey-station", count=1}
/c game.player.insert{name="solar-panel", count=1}
/c game.player.insert{name="small-electric-pole", count=2}
```

Checklist:
- [X] Place a `Squirrel Feeder` on open ground near spawn.
- [X] Confirm the feeder has visible art, a sensible footprint, and a readable selection box.
- [X] Open the feeder and confirm the UI feels like a one-slot wildlife container, not a broken chest clone.
- [X] Place a `Forest Survey Station` nearby.
- [X] Confirm the survey station uses green-tinted radar-style intermediate art, occupies a larger radar-like footprint, and can be selected reliably.
- [X] Click the survey station and confirm it does not open a chest inventory. Expected result: it behaves like a selectable survey structure, and selecting it now outlines the forest footprint it will survey.
- [X] Place the `Solar Panel` and a `Small Electric Pole` so the survey station is powered.
- [X] Press `ALT+S` while the survey station is selected or while standing nearby.
- [X] Confirm `ALT+S` prints an exact multi-line regional report in the lower-left message log, including region coordinates plus health, unrest, trust, habitat pressure, and the main scoring inputs.
- [X] Press `ALT+R`.
- [X] Confirm a readable relocation message appears instead of a script error.
  Expected result: if no squirrel is selected, the game should tell you to select a squirrel before using `ALT+R`.

Pass condition:
- The milestone-0 placeables and basic inputs behave like stable scaffolding in a live save.
