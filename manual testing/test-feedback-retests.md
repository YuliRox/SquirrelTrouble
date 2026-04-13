# Feedback Retest Checklist

Default start: use a fresh scenario or a clean checkpoint with a forest edge, at least one short live belt, one stocked feeder, `Wildlife Relocation` researched, and one nearby biter nest scouted.  
Scope: cumulative retest for the fixes requested in [test-feedback.md](/mnt/c/Code/SquirrelTrouble/manual%20testing/test-feedback.md).  
Use this after reloading the mod so the latest runtime and prototype changes are active.

## Squirrel Readability And Handling

Checklist:
- [ ] Click a visible squirrel and confirm it shows a health bar again.
- [ ] Shoot a squirrel with the pistol or shotgun and confirm it actually takes damage.
- [ ] Click a belt-sitting squirrel and confirm it uses a static sitting pose instead of the running animation.
- [ ] Walk over a squirrel and confirm an angry squeak plays alongside the rough-handling feedback.
- [ ] Click a squirrel and confirm it stays selected long enough to inspect or act on it.
- [ ] Watch a calm squirrel near a forest edge and confirm it spends longer stretches sitting or idling instead of constant frantic movement.

Pass condition:
- Squirrels are damageable, readable on belts, audible when mishandled, and stable enough to inspect during play.

## Feeder Suppression And Durability

Checklist:
- [ ] Select a feeder and confirm its peace/suppression range overlay is visible and readable.
- [ ] Place a stocked feeder near a belt at the forest edge and confirm nearby squirrels stop passive belt sitting or theft inside that feeder area.
- [ ] Let biters damage a feeder and confirm the feeder can be repaired normally afterward.
- [ ] Confirm feeders feel sturdier than before and are not instantly lost to minor biter contact.

Pass condition:
- Feeders clearly communicate their area of effect, suppress nearby squirrel nuisance when stocked, and remain maintainable infrastructure under attack.

## Relocation And Retaliation

Checklist:
- [ ] Relocate a selected squirrel with `ALT+R` and confirm a temporary `Relocated squirrel` marker makes the destination easy to identify.
- [ ] Confirm the relocated squirrel ends up in healthier forest rather than seeming deleted.
- [ ] Damage a squirrel without killing it and confirm you get the warning, but no revenge marker and no biter wave.
- [ ] Kill a squirrel and confirm the mourning message appears instead of the nonlethal warning.
- [ ] Confirm a death-site tag appears where the squirrel died.
- [ ] Confirm the revenge-source marker or alert appears if a nearby nest is available.
- [ ] Wait about one minute and confirm both the death-site tag and revenge-source feedback disappear again.

Pass condition:
- Relocation reads as nonlethal wildlife management, while only squirrel deaths escalate into readable temporary retaliation feedback.
