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
- [ ] Click a visible squirrel so it is selected.
- [ ] Press `ALT+R`.
- [ ] Confirm the game does not error and instead relocates that squirrel away from the current hotspot.
- [ ] Confirm a temporary `Relocated squirrel` pin appears so the destination reads as relocation, not deletion.
- [ ] Confirm the squirrel reappears in a healthier forest patch rather than on open ground or inside factory infrastructure.
- [ ] Press `ALT+S` near the original hotspot before and after relocation.
- [ ] Confirm the local trust/unrest reading improves slightly after a successful relocation.

Pass condition:
- Nonlethal relocation reads as intentional wildlife control, not disappearance or deletion, and the destination is easy to identify.

## Rough Handling Warning

Preconditions:
- Keep a visible squirrel near a forest edge.
- Keep a nearby biter nest scouted if possible.

Checklist:
- [ ] Damage a squirrel without killing it.
- [ ] Confirm the game prints a readable warning instead of failing silently.
- [ ] Confirm a localized retaliation marker or alert appears near the suspected revenge source if one exists nearby.
- [ ] Wait briefly and confirm a small biter wave actually emerges from that nearby nest instead of the warning ending as a dead-end.
- [ ] Confirm nearby squirrel behavior feels more hostile or tense afterward.

Pass condition:
- Accidental rough handling creates a readable warning, points at the nearby retaliation source, and produces a small localized wave instead of feeling random.

## Squirrel Death Retaliation

Preconditions:
- Keep a visible squirrel near a forest edge.
- Keep a nearby biter nest scouted if possible.

Checklist:
- [ ] Kill one squirrel.
- [ ] Confirm the death produces the mourning warning `Mother Nauvis mourns its children...` instead of the nonlethal harm warning.
- [ ] Confirm a temporary death-site tag appears where the squirrel died.
- [ ] Confirm a localized retaliation marker or alert appears at the revenge source if one is available.
- [ ] Wait briefly and confirm a stronger revenge wave launches from the localized source toward the death site.
- [ ] Confirm both death-site and revenge-source feedback clear again after roughly one minute instead of lingering permanently.
- [ ] Press `ALT+S` near the death site.
- [ ] Confirm trust falls and unrest rises relative to the pre-kill baseline.

Pass condition:
- One squirrel death is clearly attributable, visibly escalates local tension, and launches a readable nearby revenge wave from the localized retaliation source.
