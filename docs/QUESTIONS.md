# Squirrel Trouble Open Questions

Use this file to lock decisions before the implementation roadmap.

How to use it:

- Leave a checkbox unchecked while the answer is still uncertain, even if you wrote draft notes.
- Check the box only when your answer is final enough that I should treat it as decided in future turns.
- Write your answer directly after the `Answer:` line for each question.
- I will treat checked questions as settled and skip them in later review passes.

---

## 1. Simulation Model

- [x] What is one `forest region` for simulation and scoring purposes?
  Answer: 2x2 chunks
  Answer: one region = `2x2 chunks`.
  Why this matters: region size affects forest health, trust, unrest, habitat pressure, sanctuary regions, peace zones, and endgame scoring.

- [x] What numeric range should `Forest Health`, `Squirrel Trust`, `Squirrel Unrest`, and `Habitat Pressure` use?
  Answer: all four use a `0-100` scale.
  Why this matters: victory thresholds and AI escalation depend on shared ranges.

- [x] How often should regional values update?
  Answer:update every `10` seconds.
  Why this matters: this controls responsiveness, clarity, and performance.

- [x] Should the ecology values change instantly on events, gradually over time, or both?
  Answer: major events cause immediate spikes, but normal recovery/decay happens gradually.
  Why this matters: affects game feel and how readable cause-and-effect is.

- [x] How should recent deforestation be measured?
  Answer: count trees removed in the region over a rolling recent time window.
  Why this matters: unrest and habitat pressure need a concrete trigger for “recent damage.”

- [x] How should sustained pollution be measured for forest scoring?
  Answer: use rolling average pollution in the region rather than one-time spikes.
  Why this matters: forest health and squirrel behavior should reflect chronic pollution, not momentary blips.

- [x] Should squirrel simulation run globally, only near players, or in a hybrid model?
  Answer: hybrid model, with full simulation near players and simplified colony scoring elsewhere.
  Why this matters: this is a major performance and architecture decision.

- [x] How many visible active squirrels should be allowed at once in a local area?
  Answer: cap visible active squirrels per region or per player vicinity.
  Why this matters: prevents performance and readability problems.

---

## 2. Squirrel Spawning and Population

- [x] What exact conditions allow squirrels to spawn in a region?
  Answer: sufficient tree density, low recent violence, and a minimum habitat score. If all trees are lost and all squirrels are dead the player should loose the game. Purging trees and squirrels should not be encouraged.
  Why this matters: spawn logic determines whether squirrels feel natural or arbitrary.

- [x] Should squirrels spawn only in pre-existing forests, or also in regrown nut groves?
  Answer: both, but regrown nut groves should take time to become valid habitat.
  Why this matters: this determines whether restoration fully works as a recovery path.

- [x] Should squirrel colonies have a hard population cap per region?
  Answer: yes, based on habitat quality and food supply.
  Why this matters: population scaling is central to both ecological bonuses and nuisance pressure.

- [x] How quickly should squirrel populations grow in healthy forests?
  Answer: slowly enough that recovery feels meaningful, but fast enough to matter before the player finishes the game.
  Why this matters: growth rate determines whether breeding is relevant or invisible.

- [x] How quickly should squirrel populations decline after habitat collapse?
  Answer: moderate decline, with unrest rising before the population fully disappears.
  Why this matters: the scenario is more interesting if destruction creates nuisance before extinction.

- [x] Should squirrels visibly reproduce, or should population growth be abstracted?
  Answer: abstract population growth, with more visible squirrels appearing over time rather than direct baby-squirrel simulation.
  Why this matters: this is a flavor-versus-complexity choice.

---

## 3. Nut Trees, Nuts, and Forest Recovery

- [x] How common should natural nut trees be in world generation?
  Answer: uncommon but present in enough forests that the player can discover them early. Players should find the first squirrels very early.
  Why this matters: the nut economy depends on early access.

- [x] How are nuts harvested in gameplay terms?
  Answer: by interacting with nut trees directly, similar to manual gathering. Later on in the game Nut-harvesting machines should be available via research, working similar to iron drills. Build these in a nut forest and it auto harvests. I don't want nut harvesting require the engineer physically interact with the trees forever.
  Why this matters: affects early-game friction and implementation scope.

- [x] Can nuts be automated into the logistics system from the start, or only later?
  Answer: at the start of the game the squirrels are probably not that active, so in the beginning, nut harvesting and feeder filling will be manual. feeders can be filled by inserters after researching them, but nut production itself is limited early.
  Why this matters: the scenario should become automatable, but not trivial immediately.

- [x] How long should it take for a planted nut to become a mature nut tree?
  Answer: slow growth over a meaningful in-game duration.
  Why this matters: restoration pacing is central to the scenario’s tone.

- [x] Should planted nut trees require specific terrain or spacing rules?
  Answer: simple placement rules in v1, with room for refinement later. We should probably influence the world generator to create a minimum of forest area or the scenario might become unreasonably hard.
  Why this matters: complex placement can add realism but also friction.

- [x] How much more pollution should nut trees absorb compared to normal trees?
  Answer: noticeably more, but not enough to replace all other pollution management.
  Why this matters: nut trees need to matter without becoming overpowered.

- [x] Should healthy squirrel colonies also help spread nut trees automatically?
  Answer: yes, but only as a later system after core planting and growth work.
  Why this matters: this affects roadmap scope and late-game fantasy.

---

## 4. Feeder and Stash Systems

- [x] What is the exact role of a `Squirrel Feeder` in the simulation?
  Answer: it reduces unrest, increases trust, and strongly diverts squirrels away from theft targets. If a feeder and a belt or chest a within the same distance, feeder is always preferred(if not empty)
  Why this matters: feeders are the main peace mechanic and need explicit effects.

- [x] How many nuts does a feeder hold?
  Answer: enough to buffer short interruptions, but not so much that it is fire-and-forget forever.
  Why this matters: feeder capacity affects automation and player burden.

- [x] Is the current `50 nuts = stocked` threshold acceptable?
  Answer: Initially shoulb be 20. Feeder capacity can be grown larger by research.
  Why this matters: this number is already referenced by the endgame conditions.

- [x] How quickly do squirrels consume nuts from a feeder?
  Answer: consumption rate scales with local squirrel population and unrest.
  Why this matters: this controls the cost of peace.

- [x] Can the player place feeders anywhere, or only near forests?
  Answer: anywhere, but they only work well near valid squirrel habitat or travel corridors. Placing a feeder in a factory next to belts will keep squirrels away from belts until it is empty. Feeders in forests keep squirrels in forests. Both possibilities open up different player strategies
  Why this matters: placement rules affect readability and exploit prevention.

- [x] Are forest stashes created only by squirrel actions, or can they also appear naturally?
  Answer: created only by squirrel actions.
  Why this matters: stash creation logic affects both immersion and implementation scope.

- [x] Should forest stashes decay, despawn, or persist until emptied?
  Answer: persist until emptied, then despawn. no player material should be destroyed by squirrel stealing.
  Why this matters: this affects recoverability and map clutter.

- [x] Can the player destroy or move a forest stash?
  Answer: a stash functions like a chest. only squirrels can put stuff into it. players can only retrieve items from stashes. if a stash is emptied, it despawns. stashes cannot be picked up and placed into inventory. Stashes cannot be destroyed while items are inside.
  Why this matters: determines whether stashes feel ecological or just like containers.

- [x] Should squirrels ever use feeders to return stolen items, or only to eat nuts?
  Answer: no, this is currently only a feeding mechanic
  Why this matters: this separates MVP from more advanced coexistence behaviors.

---

## 5. Squirrel Actions and Escalation

- [x] Which logistics entities can squirrels target in MVP?
  Answer: all types of belts and chests. they switch throught splitters like all items on a belt. When the belt ends (e.g. in a smelter) they drop of the belt on the next available ground space
  Why this matters: target scope is the biggest driver of nuisance complexity.

- [x] Should squirrels touch underground belts, splitters, inserter drop points, or machines in later versions?
  Answer: they should work on underground belts in a sense that they visibly vanish on the entry and reappear on the exist of the underground belt.
  Why this matters: prevents feature sprawl.

- [x] How long should belt blocking last per squirrel event?
  Answer: long enough to be annoying and visible, not long enough to fully deadlock lines repeatedly. Should not be "Hop-on-Hop-off". Full deadlock should not occur.
  Why this matters: belt blocking is one of the most visible nuisance actions.

- [x] How often can a squirrel perform belt blocking?
  Answer: rate-limited per squirrel and per region. It should steal an item from the belt when leaving and try to hide it in a stash. That way, we won't have squirrels just sitting on belts, but squirrels sitting on belts, running await with loot running for the forest.
  Why this matters: prevents spammy frustration.

- [x] How many items can a squirrel steal from a belt in one action?
  Answer: `1` item per belt theft action. Squirrels can carry exactly one thing.
  Why this matters: this is already implied in the spec, but should be confirmed.

- [x] How large can a chest theft be?
  Answer: a small stack, scaled by habitat pressure.
  Why this matters: chest theft can become much more disruptive than belt theft.

- [x] Which chest types can squirrels target in MVP?
  Answer: all chest types excluding infinity chest
  Why this matters: keeps the first implementation bounded.

- [x] Should chest reordering exist in the first shipped version at all?
  Answer: no. they steal, they don't rearrange

- [x] Can squirrels drop items anywhere, or only in forest-bound paths and stash-adjacent areas?
  Answer: primarily along retreat paths and near forest edges.
  Why this matters: affects both readability and item recovery.

- [x] Should squirrels ever steal from the same target repeatedly, or should there be short target cooldowns?
  Answer: they steal repeatedly if the same type of item they stole last time is still present. If item type is empty, they search for a new target.
  Why this matters: repeated harassment of one tile or chest can feel unfair fast.

- [x] Should squirrel item preferences be based on hand-authored item tags or a computed desirability formula?
  Answer: Whatever is easier to scale. Computed desirability.
  Why this matters: item selection can either be easy to control or easy to scale, but not both at once.

---

## 6. Player Interaction, Damage, and Violence

- [x] How much damage should a nut throw deal to the engineer?
  Answer: minor chip damage that is funny at first and dangerous only if repeated. It should not kill the engineer, just if he really deliberately mows through the squirrels intentionally and hordes of squirrels start throwing. In that case, he probably deserves it. Nut damage should not immediately disappear if he gets his first armor. This probably needs balancing (nut damage vs. armor) and an extended discussion.
  Why this matters: sets the tone for “agitated” squirrels.

- [x] Should nut throws have a cooldown per squirrel?
  Answer: yes, a short one.
  Why this matters: prevents accidental instant death from walking through a dense group.

- [x] What exactly counts as a player-caused squirrel death?
  Answer: player weapons, vehicles, trains, combat drones, turrets, and other player-owned damage sources. Anything the player can direct to shoot at them. Squirrels are neutral entities, so turrets do not target them by default. Train rails will need to be secured with fences or walls if squirrels continually get overrun. I want this mechanic to be present.
  Why this matters: retaliation and victory conditions depend on clear attribution.

- [x] Should accidental kills from trains or vehicles trigger full mourning retaliation?
  Answer: yes, if player-owned. It should be visible where and why it happens (e.g. a temporary marker on the map and a message "a squirrel was overrun by a train/tank") so the player gets an idea where he has to act (e.g. build walls around rails).
  Why this matters: determines whether transport infrastructure near forests has moral risk.

- [x] Should turrets always ignore squirrels, even if squirrels are hit by splash or stray damage?
  Answer: turrets do not target squirrels, but player-caused collateral damage can still kill them. This should be a visible accidental kill with a message and a marker. Squirrels are neutral, not invulnerable.
  Why this matters: there must be a clear difference between neutrality and invulnerability.

- [x] How strong should the revenge wave be after one squirrel death?
  Answer: painful but survivable, with scale based on game phase and nearby biter presence. also, running over one squirrel triggers less biters, then killing multiple squirrels.
  Why this matters: “don’t kill squirrels” has to be taught firmly without making one mistake run-ending.

---

## 7. Biter Interaction and Peace Zones

- [x] What is the MVP effect of a peace zone?
  Answer: reduced local biter attack interest and reduced expansion pressure near sanctuary regions.
  Why this matters: peace zones are already part of the default endgame, so they need a concrete first version.

- [x] Should biters become visibly passive unless attacked in v1, or is that a later upgrade?
  Answer: later upgrade; v1 uses reduced aggression rather than full passivity. Full passivity will happen in endgame
  Why this matters: full passivity is more dramatic, but also more complex and riskier to balance.

- [x] What radius around a healthy sanctuary region should a peace zone affect?
  Answer: a modest local radius around the region rather than a large global aura.
  Why this matters: defines gameplay impact and exploit potential.

- [x] How should a “successful biter attack on the main factory area” be defined for `Nauvis Truce Victory`?
  Answer: any enemy damage dealt to designated factory structures inside a player-defined or system-defined core area.
  Why this matters: the current victory condition depends on this but the term is not defined.

- [x] How should “main factory area” be defined?
  Answer: a system-defined area around the player’s primary production hub, or a player-placed marker in later versions.
  Why this matters: `Nauvis Truce Victory` cannot be implemented without this.

- [x] Should a peace zone require nearby live biter nests to matter, or can it exist without nearby enemies?
  Answer: it can exist without nearby enemies, but it is only strategically meaningful when biters are nearby.
  Why this matters: affects both simulation and victory checking.

---

## 8. Player Feedback and UI

- [x] What is the MVP method for exposing forest state to the player?
  Answer: `Forest Survey Station` in v1. Basic broad-state feedback is available early, and a built survey station near forests provides proper regional inspection.
  Why this matters: the player must understand squirrel escalation.

- [x] Should the player see exact numeric values, broad state bands, or both?
  Answer: in the beginning with tooltip only broad state. Forest Survey Station gives the player exact numbers.
  Answer: broad state bands in normal play, exact numbers only in advanced inspection.
  Why this matters: exact numbers help optimization, but can reduce atmosphere.

- [x] Should region state be visible on the map, in-world, or only through a dedicated tool?
  Answer: in v1, primarily through the `Forest Survey Station` and related inspection/tooltip UI, with room for richer map-level metrics later.
  Why this matters: UI complexity has major roadmap consequences.

- [x] How should feeders communicate whether they are helping?
  Answer: visual usage state plus simple text in tooltip or GUI. Squirrels could gather around feeders, visually eating nuts.
  Why this matters: players need feedback that their mitigation is working.

- [x] Should the first squirrel escalation events have tutorial-style messages?
  Answer: yes, a few lightweight scripted hints during early scenario beats.
  Why this matters: onboarding is critical for a scenario with unusual rules.

---

## 9. Research and Progression

- [x] Which science packs should each squirrel-related technology require?
  Answer: start cheap and early for nut recovery and feeders, with more advanced packs for relocation and ecological stabilization.
  Why this matters: research pacing defines when the player can respond to the nuisance.

- [x] Should `Arboriculture` be available before the player can do major accidental over-clearing?
  Answer: yes, or at least very early.
  Why this matters: the player needs a recovery path before the punishment becomes irreversible.

- [x] Should `Wildlife Diversion` unlock before chest stealing begins?
  Answer: no. but it should be available quickly when it starts
  Why this matters: the player should get a mitigation tool before the nastier escalation tiers.

- [x] Is `Forest Surveying` required for the default scenario flow, or can it be optional?
  Answer: required or very strongly recommended.
  Why this matters: the system needs readable feedback.

- [x] Is `Wildlife Relocation` part of the first shipped version, or explicitly post-MVP?
  Answer:part of v1
  Why this matters: relocation is valuable but more complex than feeders and planting.

---

## 10. Victory Conditions and Scenario Structure

- [x] Is `Coexistence Victory` definitely the v1 shipped ending?
  Answer:
  Answer: yes.
  Why this matters: roadmap scope changes significantly if the endgame target changes.

- [x] Should `Coexistence Victory` require launching a rocket, or should there be an alternative industrial proof option?
  Answer: require `1` rocket in v1 for clarity.
  Why this matters: this decides how closely the scenario is tied to vanilla progression.

- [x] Should the current `Coexistence Victory` thresholds stay as written for planning purposes?
  Answer: yes as provisional targets, to be tuned after playtesting.
  Why this matters: roadmap work needs stable provisional numbers.

- [x] If peace zones are not robust enough for v1, should `Coexistence Victory` use a simpler proxy?
  Answer: yes, if needed. Use stable sanctuary regions plus no local biter attacks for a validation period.
  Why this matters: prevents the default ending from depending on a too-ambitious subsystem.

- [x] Should the scenario continue in freeplay after victory?
  Answer: yes.
  Why this matters: affects end-state handling and post-victory UX.

- [x] Do you want `Great Grove Victory` and `Nauvis Truce Victory` to be alternate selectable victory modes, optional achievements, or future design targets only?
  Answer: future supported variants, with `Coexistence Victory` as the first shipped mode. Develop in a Way that we can shift to Nauvis Truce.
  Why this matters: helps separate roadmap scope from long-term design.

---

## 11. Explicit Open Questions Already Present in the Spec

- [x] Should squirrels ever enter trains, wagons, rail stations, or rail-adjacent logistics?
  Answer: no for MVP; keep them limited to belts, chests, and forest-edge nuisance.
  Why this matters: train interaction is flavorful but easy to let sprawl out of scope.

- [x] How visible should region health be to the player overall?
  Answer: partially visible through researched inspection, not fully exposed from the first minute.
  Why this matters: this is still open in the spec and should be settled before roadmaping.

- [x] Should forest stashes respawn naturally, or only be created by squirrel actions?
  Answer: only by squirrel actions in v1.
  Why this matters: affects both simulation clarity and implementation scope.

- [x] How strong should biter peace zones be before they feel exploitable?
  Answer: strong enough to reward coexistence locally, but not strong enough to replace all military planning.
  Why this matters: this will be a key balancing challenge for late game.

---

## 12. Scope Guardrails

- [x] What is explicitly out of scope for the first playable milestone?
  Answer: full passive biter behavior, train interaction, and advanced endgame variants.
  Why this matters: roadmap quality depends on clear exclusions, not just inclusions.

- [x] What is the minimum feature set required for a believable first playable prototype?
  Answer: visible squirrels, forest spawning, belt blocking, belt theft, feeders, nut trees, stashes, basic unrest/trust/pressure, squirrel death retaliation, and a simple feedback tool.
  Why this matters: this is the anchor for a scoped roadmap.

---

## 13. Scenario Setup and World Generation

- [x] Should this ship as a true Factorio `scenario`, a regular `mod`, or both?
  Answer: ship as a scenario first, with room to extract reusable systems into a mod structure later if useful.
  Why this matters: scenario packaging affects map setup, victory handling, onboarding, and development scope.

- [x] Should the scenario use custom map generation settings to guarantee a forest-heavy start?
  Answer: yes. A player should meet a squirrel early after game start.
  Why this matters: the squirrel fantasy and early mechanics depend on meaningful forests near spawn.

- [x] Should the starting area guarantee at least some nut trees near the player spawn?
  Answer: yes, a small but reliable number.
  Why this matters: players need to discover the nut loop early enough for it to matter.

- [x] Should the scenario start with any squirrel-related technology, recipes, or items already unlocked?
  Answer: no free late tools, but possibly very early access to `Arboriculture` or a scripted hint toward it.
  Why this matters: this determines how hard the opening is and how quickly the player can recover from mistakes.

- [x] Should the map include authored starting forests or sanctuary candidates, or rely purely on procedural generation?
  Answer: mostly procedural generation with a few guaranteed ecological conditions near spawn.
  Why this matters: affects replayability and implementation complexity.

- [x] Should nut trees appear only in forests, or can they also appear in isolated patches outside dense forest?
  Answer: mostly in forests, with occasional smaller patches.
  Why this matters: changes exploration incentives and habitat restoration patterns.

---

## 14. Failure States and Recovery

- [x] Can the player permanently fail the scenario by over-clearing forests or killing too many squirrels?
  Answer: yes; but the player needs to be discouraged by the biter waves to kill squirrels. And it should be hard to achieve perma fail (e.g. wenn nut tree density drops below a certain threshold, ramp up squirrel spawn probabilities so they don't die out that easily)
  Why this matters: this determines whether the scenario is forgiving, restart-heavy, or recoverable.

- [x] If the player destroys nearly all local forest early, what guaranteed recovery path should still exist?
  Answer: nut planting and regrowth should always allow eventual recovery, even if expensive and slow.
  Why this matters: prevents the scenario from becoming unwinnable through early ignorance.

- [x] Should very low trust or very high unrest create a temporary crisis state beyond normal nuisance?
  Answer: yes, but only as escalation, not as an instant fail condition.
  Why this matters: this could become an important milestone between normal play and endgame stability.

- [x] Should there be any explicit “ecological collapse” warning before the player enters an unrecoverable-feeling state?
  Answer: yes.
  Why this matters: strong warning improves fairness and teaches the system.

---

## 15. Multiplayer and Technical Boundaries

- [x] Is multiplayer support required for the first playable version?
  Answer: no, single-player first in v1. This scenario is intended to be a personal birthday present experienced by the person who receives it.
  Why this matters: multiplayer-safe scripting, synchronization, and per-player squirrel simulation increase scope.

- [x] If multiplayer is supported later, should ecology values and victory be tracked per force, per player, or globally per surface?
  Answer: globally per surface.
  Why this matters: determines how shared progress and griefing prevention work.

- [x] What exact Factorio version should this target?
  Answer: current base-game Factorio version without requiring Space Age.
  Why this matters: API availability and compatibility decisions depend on this.

- [x] Should the scenario explicitly ignore or disable Space Age-specific content if that expansion is installed?
  Answer: If space age is installed all scenario content happens on Nauvis. I don't want to disable Space Age content. As gameplay continues, the player might leave his squirrely planted with the rocket and thats fine. It should be recommended to not play it in space age.
  Why this matters: avoids accidental scope creep and rules confusion.

- [x] Are placeholder visuals acceptable for the first playable version?
  Answer: yes.
  Why this matters: visible squirrels, nut trees, feeders, and stashes need assets, and art scope can dominate early work if not bounded.

- [x] Are custom sounds and custom localization part of MVP, or later polish?
  Answer: later polish, except for essential text and warnings.
  Why this matters: helps separate core gameplay work from presentation work.

---

## 16. Onboarding and Presentation

- [x] Should the scenario open with a scripted introduction explaining squirrels, or should discovery be mostly organic?
  Answer: organic discovery. We might spawn a squirrel near player spawn so he definitely meets one early on. But not Scenario framing, scenario should be emergent
  Why this matters: scenarios benefit from framing, but overexplaining can weaken the surprise.

- [x] Should the player get explicit warnings the first time they trigger each escalation tier?
  Answer: yes, lightweight one-time warnings.
  Why this matters: teaches cause and effect without requiring external documentation.

- [x] Should the scenario include a quest-like objective log for squirrel goals, or keep objectives mostly implicit until research/endgame?
  Answer: keep objectices mostly implicit.
  Why this matters: affects how scenario-like versus sandbox-like the experience feels.

---

## 17. Implementation-Shaping Decisions

- [x] Should belt blocking be implemented as a true physical unit occupying the tile, or as a scripted temporary belt jam caused by a visible squirrel?
  Answer: a true physical unit occupying the tile. The squirrel can sit on an empty belt, occupying the space. If there are items on the belt and a squirrel sits on it, it picks up the item beneath it and holds it. The squirrel actor should be visible. This is the fun part. Cute squirrels traveling on belts through the factory.
  Why this matters: this is a major technical and performance decision, and it affects how reliable belt interference feels.

- [x] When a squirrel steals an item, should it carry the actual item in simulation, or should the carry behavior be partly visual with the inventory move handled immediately?
  Answer: immediate inventory move plus visible carry behavior for flavor. It should be only visible holding something when it sits, while running around thats optional. But the player must be able to visually read the stealing. ("Hey, that squirrel holds a circuit", "hey that squirrel left and now my circuit is missing")
  Why this matters: this choice strongly affects implementation complexity and edge cases.

- [x] Should squirrel pathing be fully physical and collision-based, or can squirrels “cheat” slightly to reach targets and stashes?
  Answer: allow limited scripted cheating where needed, while keeping movement visually believable.
  Why this matters: strict physical pathing may be expensive and brittle for a nuisance system.

- [x] Should visible squirrels be individually persistent entities with identity, or mostly disposable local actors representing a regional colony?
  Answer: disposable local actors backed by regional colony state.
  Why this matters: persistent individuals are flavorful, but much more expensive to simulate and maintain.

- [x] How much of squirrel behavior needs to be literally simulated versus only convincingly presented to the player?
  Answer: simulate the important outcomes and present the rest convincingly.
  Why this matters: this is the key scoping principle for a performant first version.

- [x] Should forest stashes have a capacity limit?
  Answer: yes, enough to store meaningful loot without becoming infinite squirrel warehouses. Its fine to have multiple stashes in a forest
  Why this matters: stash capacity affects recovery, clutter, and exploitability.

- [x] Should squirrels prefer returning to the same home region, or can any suitable nearby forest become their effective home?
  Answer: prefer a home region, but allow reassignment after relocation or habitat collapse.
  Why this matters: regional identity affects colony logic, relocation, and stash placement.

---

## 18. Save Compatibility, Tuning, and Testing

- [x] Do you want to preserve save compatibility across early development versions, or can breaking changes be acceptable until a later milestone?
  Answer: breaking changes are acceptable during early prototyping.
  Why this matters: save migration requirements can significantly slow iteration.

- [x] Should the first roadmap include explicit debug commands or admin tools for spawning squirrels, adjusting trust/unrest, and forcing events?
  Answer: yes. And we will use the factorio test mod to enable testing. more on this later
  Why this matters: balancing this scenario without debug tooling will be much slower.

- [x] Should the first roadmap include lightweight telemetry or logging for squirrel actions and ecology values?
  Answer: yes, at least in debug mode.
  Why this matters: the system has many hidden values, so balancing will benefit from observability.

- [x] Should there be scenario settings for tuning squirrel intensity, or should the first version be fixed-balance only?
  Answer: fixed-balance first, optional tuning later.
  Why this matters: settings increase flexibility, but also increase testing scope.

- [x] Should endgame thresholds and ecology constants be centralized in tunable data tables from the beginning?
  Answer: yes.
  Why this matters: the roadmap will be much easier to maintain if balancing values are not scattered across logic.

---

## 19. Roadmap and Milestone Boundaries

- [x] What is the actual next delivery target: a technical prototype, a first playable milestone, or a first complete scenario version?
  Answer: first build a technical prototype, then a first playable milestone, then the first complete scenario version with `Coexistence Victory`.
  Why this matters: the roadmap depends on which milestone we are optimizing for first.

- [x] Should the roadmap explicitly separate `prototype`, `first playable`, and `first shipped scenario` as different scope levels?
  Answer: yes.
  Why this matters: the spec currently mixes MVP mechanics, peace zones, and shipped-ending goals, so milestone separation will reduce ambiguity.

- [x] Is the first playable milestone allowed to omit the default victory condition if the ecology systems are not yet stable enough?
  Answer: yes.
  Why this matters: avoids forcing endgame logic too early into the first implementation milestone.

---

## 20. World, Surface, and Save Entry Assumptions

- [x] Should the scenario support only newly started games, or also retrofitting into existing saves?
  Answer: newly started scenario games only.
  Why this matters: world generation, nut-tree placement, and region initialization are much simpler on fresh starts.

- [x] Should all squirrel systems operate only on Nauvis, or on every surface if additional surfaces somehow exist?
  Answer: Nauvis only.
  Why this matters: keeps the scenario aligned with the spec and prevents accidental multi-surface scope creep.

- [x] If the map has already generated chunks before initialization, should the scenario retroactively seed nut trees and squirrel regions there?
  Answer: yes for the starting area, optional elsewhere.
  Why this matters: determines initialization complexity and how reliable early gameplay setup is.

- [x] Should chunk generation rules for nut trees and squirrels be deterministic from map seed, or can they be scenario-scripted after generation?
  Answer: scenario-scripted after generation where needed, while preserving a stable feel.
  Why this matters: affects worldgen architecture and how much control the scenario has over the opening experience.

---

## 21. Ecology Attribution and Edge Cases

- [x] Does habitat loss caused by biters, fire, or other non-player sources raise unrest the same way as player-caused deforestation?
  Answer: it should hurt habitat and raise unrest, but should not penalize trust compared to player-caused loss.
  Why this matters: the ecology system should distinguish damage from blame.

- [x] Does pollution from remote outposts affect only their local forest regions, or should there be any global ecology pressure?
  Answer: local first, with global summaries only for advanced endgame scoring.
  Why this matters: local-only systems are easier to reason about and implement.

- [x] If a squirrel steals an item but no valid stash or feeder is available, what should happen?
  Answer: squirrels can create stashes in forests.
  Why this matters: this is an implementation edge case that will definitely occur.

- [x] How many forest stashes can exist in one region at once?
  Answer:
  Answer: a small capped number per region.
  Why this matters: prevents stash spam and simplifies recovery logic.

- [x] Should an empty or destroyed feeder immediately change squirrel behavior, or should feeders have a grace period before squirrels react?
  Answer: short grace period.
  Why this matters: prevents overreactive oscillation and makes the system easier to automate.

- [x] Should squirrels be able to target the same belt line or chest network indefinitely if habitat stays bad, or should there be escalating target diversification?
  Answer: some diversification, while still preferring nearby high-value nuisance targets.
  Why this matters: repeated targeting can feel unfair, but total randomness feels arbitrary.

---

## 22. Open Design Gaps From The Roadmap

- [ ] How often should visible biter-on-squirrel predation happen when the player is nearby?
  Answer:
  Why this matters: Milestone 7 depends on the food chain being visible enough to teach the ecology, but not so common that squirrel presence feels unstable or slapstick.

- [ ] How quickly should squirrels lost to natural predation be replaced, and does replacement need to happen in the same region or just any viable nearby forest?
  Answer:
  Why this matters: the roadmap assumes natural predation will not destabilize the scenario, but the refill rule is not actually pinned down.

- [ ] What exact player-facing signal should indicate that a region has fallen below squirrel-respawn viability?
  Answer:
  Why this matters: the spec now depends on “minimum viable forest” and colony collapse, but the player needs to understand when a forest stopped being able to support squirrels.

- [ ] How should homeless squirrels behave before they successfully join a new colony?
  Answer:
  Why this matters: colony collapse, stash behavior, retreat logic, and infrastructure aggression all depend on whether homeless squirrels become feral, temporary raiders, or something in between.

- [ ] What are the exact rules for home-colony reassignment after habitat collapse or restoration?
  Answer:
  Why this matters: relocation, restored forests, and late-game ecosystem recovery all depend on predictable rules for when squirrels adopt a new home.

- [ ] What should the relocation interaction actually be: instant click relocation, lure-based diversion, engineer capture and release, or something else?
  Answer:
  Why this matters: current relocation is technically functional but failed playtest as a game mechanic. It reads like low-friction squirrel deletion rather than cumbersome wildlife control, and the final interaction needs to preserve nuisance and readability.

- [ ] Should MVP ship only machine infestation as the evolved sabotage layer, or must at least one additional sabotage behavior ship as well?
  Answer:
  Why this matters: Milestone 8 currently allows “additional sabotage if infestation is insufficient,” but that threshold is still a design judgment rather than a settled requirement.

- [ ] How should `Squirrel Evolution` be shown to the player: exact number, broad warning band, or only through late-game survey messaging?
  Answer:
  Why this matters: the roadmap expects military escalation to be understandable, but the feedback surface for global evolution is not yet decided.

- [ ] What outcome bands should the rocket-launch ecological summary use besides full success?
  Answer:
  Why this matters: Milestone 9 needs ending messaging that explains more than just perfect victory; otherwise ecological failure will not read clearly.

- [ ] What exact score categories and weights should the rocket-launch ecological summary use?
  Answer:
  Why this matters: the roadmap already calls this out as a non-coding TODO, but it should also exist as an explicit unanswered design question so it does not get lost.
