# Milestone 5 Manual Playtest

Default start: use a fresh scenario or a clean checkpoint with a forest edge, `Wildlife Relocation` researched, and at least one nearby biter nest on the map.  
Recommended checkpoint save: `m5-retaliation-foundation` after placing a short belt line near a forest edge and scouting one nearby biter nest.  
Scope: selected-squirrel relocation, healthy-destination behavior, squirrel harm attribution, retaliation warnings, and localized revenge-source markers.  
Automated coverage already exists for: relocation destination selection, relocation trust/unrest effects, nonlethal squirrel-harm attribution, squirrel-death attribution, and revenge-wave source selection.

## Nonlethal Relocation

Preconditions:
- Research `Wildlife Relocation`.
- Find or lure a visible squirrel near a forest edge.
- Make sure another healthier forest patch exists somewhere nearby.

Checklist:
- [ ] Click a visible squirrel so it is selected.
- [ ] Press `ALT+R`.
- [ ] Confirm the game does not error and instead relocates that squirrel away from the current hotspot.
- [ ] Confirm the squirrel reappears in a healthier forest patch rather than on open ground or inside factory infrastructure.
- [ ] Press `ALT+S` near the original hotspot before and after relocation.
- [ ] Confirm the local trust/unrest reading improves slightly after a successful relocation.

Pass condition:
- Nonlethal relocation reads as intentional wildlife control, not disappearance or deletion.

## Rough Handling Warning

Preconditions:
- Keep a visible squirrel near a forest edge.
- Keep a nearby biter nest scouted if possible.

Checklist:
- [ ] Damage a squirrel without killing it.
- [ ] Confirm the game prints a readable warning instead of failing silently.
- [ ] Confirm a localized retaliation marker or alert appears near the suspected revenge source if one exists nearby.
- [ ] Confirm nearby squirrel behavior feels more hostile or tense afterward.

Pass condition:
- Accidental rough handling creates a readable warning and a localized retaliation source instead of feeling random.

## Squirrel Death Retaliation

Preconditions:
- Keep a visible squirrel near a forest edge.
- Keep a nearby biter nest scouted if possible.

Checklist:
- [ ] Kill one squirrel.
- [ ] Confirm the death produces a stronger warning than nonlethal harm.
- [ ] Confirm a localized retaliation marker or alert appears if a revenge source is available.
- [ ] Press `ALT+S` near the death site.
- [ ] Confirm trust falls and unrest rises relative to the pre-kill baseline.

Pass condition:
- One squirrel death is clearly attributable, visibly escalates local tension, and points the player toward the localized retaliation source.
