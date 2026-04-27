# Milestone 6 Manual Playtest

- Default start: use a clean checkpoint with a forest-edge hotspot, `Wildlife Relocation` and `Ecological Stabilization` researched, one powered `Forest Survey Station`, and both feeder tiers available.
- Recommended checkpoint save: `m6-mitigation-feedback` after damaging one forest edge, stocking one wooden feeder, and leaving one nearby healthier forest patch intact for relocation targets.
- Scope: survey-station readability, selected-squirrel relocation affordances, steel-feeder upgrade readability, accidental-kill escalation clarity, and hotspot stabilization without lethal control.
- Automated coverage already exists for: relocation destination selection, relocation destination preview on the selected squirrel panel, relocation incident destination metrics, retaliation attribution, revenge-wave launch bounds, feeder stocking effects, and steel-feeder capacity.

## Survey And Selection Readability

Preconditions:
- Keep one powered `Forest Survey Station` near the hotspot.
- Keep at least one visible squirrel near belts or feeders.

Checklist:
- [ ] Select the survey station and confirm the left-side panel shows exact local health, unrest, trust, pressure, observed trees, feeders, and main drivers.
- [ ] Select a squirrel and confirm the survey panel is replaced by a squirrel-specific panel instead of leaving stale survey information behind.
- [ ] Click a visible squirrel and confirm it shows a health bar again.
- [ ] Confirm the squirrel panel shows a readable behavior state and local pressure.
- [ ] Confirm the squirrel panel either shows a relocation target region with destination outlook or clearly says why relocation is unavailable.
- [ ] Confirm the displayed `ALT+R` affordance is understandable without reading the roadmap or test file.
- [ ] Click a squirrel, move the cursor across nearby entities, and confirm squirrel selection stays locked for inspection until intentional deselect or open action.
- [ ] Watch a calm squirrel near a forest edge and confirm it spends longer stretches sitting or idling instead of constant frantic movement.
- [ ] Click a belt-sitting squirrel and confirm it uses a static sitting pose instead of the running animation.

Pass condition:
- A player can tell what the selected squirrel is experiencing and whether nonlethal relocation is currently possible.

## Relocation Feedback

Preconditions:
- Research `Wildlife Relocation`.
- Keep one visible squirrel selected near a damaged hotspot.
- Keep a healthier forest patch nearby.

Checklist:
- [ ] Select a squirrel and read the relocation target from the squirrel panel before moving it.
- [ ] Press `ALT+R`.
- [ ] Confirm the squirrel does not read as deleted; the game should identify a destination region and print destination outlook details.
- [ ] Confirm a temporary `Relocated squirrel` pin appears with a readable region label.
- [ ] Confirm the relocated squirrel ends up in healthier forest rather than seeming deleted.
- [ ] Open the map and confirm the destination area is charted enough to inspect the relocation pin.
- [ ] Use `ALT+S` near the original hotspot before and after relocation.
- [ ] Confirm the original hotspot shows slightly lower unrest and slightly higher trust after a successful relocation.

Pass condition:
- Relocation reads as deliberate transfer into healthier habitat, not disappearance.

## Steel Feeder Upgrade

Preconditions:
- Research `Ecological Stabilization`.
- Place one wooden feeder and one steel feeder at comparable factory-edge pressure points.

Checklist:
- [ ] Confirm the steel feeder sprite and icon read as the sturdier late-game tier rather than a duplicate wooden feeder.
- [ ] Select a feeder and confirm its peace or suppression range overlay is visible and readable.
- [ ] Place a stocked feeder near a belt at the forest edge and confirm nearby squirrels stop passive belt sitting or theft inside that feeder area.
- [ ] Stock both feeders and let squirrels interact with them.
- [ ] Confirm the steel feeder keeps a hotspot calmer for longer because of its larger capacity, not because of a separate hidden squirrel ruleset.
- [ ] Let biters damage a feeder and confirm the feeder can be repaired normally afterward.
- [ ] Confirm feeders feel sturdier than before and are not instantly lost to minor biter contact.
- [ ] Confirm feeder range remains readable enough to improve placement decisions around belts.

Pass condition:
- The steel feeder feels like a scaled-up mitigation tool with better uptime, not a different mechanic.

## Accidental Kill And Stabilization Flow

Preconditions:
- Keep one visible squirrel near a worked factory edge.
- Keep a nearby biter nest scouted if possible.

Checklist:
- [ ] Shoot a squirrel with the pistol or shotgun and confirm it actually takes damage.
- [ ] Accidentally harm a squirrel without killing it and confirm the warning is readable but does not launch a revenge wave on its own.
- [ ] Walk over a squirrel and confirm an angry squeak plays alongside the rough-handling feedback.
- [ ] Kill one squirrel and confirm the death-site tag, revenge-source alert, and later revenge wave all point clearly to the cause.
- [ ] Confirm the mourning message appears for a squirrel death instead of the nonlethal warning.
- [ ] Confirm the revenge-source marker or alert appears if a nearby nest is available.
- [ ] Confirm the temporary retaliation feedback clears again after the timer instead of lingering indefinitely.
- [ ] Wait about one minute and confirm both the death-site tag and revenge-source feedback disappear again.
- [ ] Let a forest stash take heavy combat damage and confirm it does not turn into a destroyed chest remnant.
- [ ] Recover control of the hotspot using feeders, relocation, and restored habitat rather than repeated lethal force.
- [ ] Confirm the hotspot feels stabilizable without having to kill more squirrels.

Pass condition:
- One accidental death is painful but survivable, the escalation source is readable, and nonlethal stabilization remains the intended answer.
