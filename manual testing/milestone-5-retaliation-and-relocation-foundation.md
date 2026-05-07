# Milestone 5 Manual Playtest

Default start: use a fresh scenario or a clean checkpoint with a forest edge, `Wildlife Relocation` researched, and at least one nearby biter nest on the map.  
Recommended checkpoint save: `m5-retaliation-foundation` after placing a short belt line near a forest edge and scouting one nearby biter nest.  
Scope: selected-squirrel relocation, healthy-destination behavior, squirrel harm attribution, retaliation warnings, localized revenge-source markers, and bounded revenge-wave launch.  
Automated coverage already exists for: relocation destination selection, relocation trust/unrest effects, nonlethal squirrel-harm attribution, squirrel-death attribution, revenge-wave source selection, and bounded revenge-wave launch.

## Nonlethal Relocation

Preconditions:
- Research `Wildlife Relocation`.
- Find or lure a visible squirrel near a forest edge.
- Make sure another healthier forest patch exists somewhere nearby.

Checklist:
- [X] Click a visible squirrel so it is selected.
- [X] Press `ALT+R`.
- [X] Confirm the game does not error and instead relocates that squirrel away from the current hotspot.
- [X] Confirm a temporary `Relocated squirrel` pin appears so the destination reads as relocation, not deletion.
- [X] Confirm the squirrel reappears in a healthier forest patch rather than on open ground or inside factory infrastructure.
- [X] Press `ALT+S` near the original hotspot before and after relocation.
- [X] Confirm the local trust/unrest reading improves slightly after a successful relocation.

Pass condition:
- Nonlethal relocation reads as intentional wildlife control, not disappearance or deletion, and the destination is easy to identify.

FEEDBACK:
Although this technically works, it does not feel like a working game mechanic.
- There are never more then 3 active tags. I can relocate Squirrels forever, there are only ever 3 Tags. And they all have the same name. And they never disappear again.
- Relocating the squirrels feels way to easy. You just click on them and they simply disappear. This isn't a nuisance anymore, this is a squirrel-clicker idle game to get rid of them. I feel like relocation needs a design overhaul, this is not it. It should be way harder to perform that, carefully luring them away. Or the engineer has to actually catch them and they would run away from him, so it becomes cumbersome and a real hazzle. Make a note: we need to create a new design decision for how to handle relocation.

## Rough Handling Warning

Preconditions:
- Keep a visible squirrel near a forest edge.
- Keep a nearby biter nest scouted if possible.

Setup shortcut:

```lua
/c local p=game.player local e=p.selected if e and (e.name=="squirrel" or e.name=="squirrel-sitting") then game.print("Before: "..tostring(e.health)) e.damage(1,p.force,nil,p.character,p.character) game.print("After: "..tostring(e.health)) else game.print("Select a squirrel first.") end
```

Checklist:
- [X] Damage a squirrel without killing it.
- [X] Confirm the game prints a readable warning instead of failing silently.
- [X] Confirm no retaliation marker or revenge-source alert appears from nonlethal damage alone.
- [X] Wait briefly and confirm no biter wave launches from nonlethal damage alone.
- [X] Confirm nearby squirrel behavior feels more hostile or tense afterward.

Pass condition:
- Accidental rough handling creates a readable warning and worsens local tension, but does not launch a lethal revenge wave by itself.

## Squirrel Death Retaliation

Preconditions:
- Keep a visible squirrel near a forest edge.
- Keep a nearby biter nest scouted if possible.

Checklist:
- [X] Kill one squirrel.
- [X] Confirm the death produces the mourning warning `Mother Nauvis mourns its children...` instead of the nonlethal harm warning.
- [X] Confirm a temporary death-site tag appears where the squirrel died.
- [X] Confirm a localized retaliation marker or alert appears at the revenge source if one is available.
- [X] Wait briefly and confirm a stronger revenge wave launches from the localized source toward the death site.
- [X] Confirm both death-site and revenge-source feedback clear again after roughly one minute instead of lingering permanently.
- [X] Press `ALT+S` near the death site.
- [X] Confirm trust falls and unrest rises relative to the pre-kill baseline.

Pass condition:
- One squirrel death is clearly attributable, visibly escalates local tension, and launches a readable nearby revenge wave from the localized retaliation source.
