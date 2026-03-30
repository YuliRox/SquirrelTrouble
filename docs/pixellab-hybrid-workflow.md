# PixelLab Hybrid Workflow

Status: working production workflow

Purpose:
- describe a practical asset workflow for contributors who are not strong pixel artists
- use PixelLab where it adds value without asking it to solve final Factorio-ready layered production alone
- make survey-station asset work concrete and repeatable

## Core Idea

Do not ask PixelLab to generate the final complete layered Factorio entity from scratch.

Instead:

1. start from a real vanilla Factorio base asset
2. keep any useful vanilla layers
3. use PixelLab to generate small replacement modules or concept fragments
4. composite those onto the vanilla base
5. do only light manual cleanup

This is a much smaller art problem than drawing a whole production sprite by hand.

## Why This Is Better

PixelLab is good at:

- concept exploration
- generating industrial-looking modules
- creating add-on parts such as sensors, antennae, gauges, or crates
- helping with shape and material ideas

PixelLab is weak at:

- matching exact Factorio sprite sheet layouts
- producing multiple aligned layers
- preserving deterministic shadow and integration behavior
- delivering final production-ready assets with no cleanup

## Survey Station: Recommended Path

Use a radar-derived workflow.

Reason:

- the vanilla radar already matches Factorio's style perfectly
- the radar art exists as clean extracted layers
- editing a radar is easier than inventing a full survey station from scratch
- this minimizes hand-drawing

Relevant files:

- [factorio-radar-frame-00.png](/mnt/c/Code/SquirrelTrouble/docs/reference/pixellab/bases/factorio-radar-frame-00.png)
- [factorio-radar-frame-08.png](/mnt/c/Code/SquirrelTrouble/docs/reference/pixellab/bases/factorio-radar-frame-08.png)
- [factorio-radar-shadow-frame-00.png](/mnt/c/Code/SquirrelTrouble/docs/reference/pixellab/bases/factorio-radar-shadow-frame-00.png)
- [factorio-radar-integration.png](/mnt/c/Code/SquirrelTrouble/docs/reference/pixellab/bases/factorio-radar-integration.png)

## Design Fork

There are two valid directions, but they are not equally easy.

### Option A: Radar-derived larger survey station

Recommended for low manual-art skill.

Use:

- the vanilla radar frame as the main base
- vanilla shadow and integration patch as-is at first
- PixelLab only for replacing or augmenting the radar head and top-side instrumentation

Pros:

- easiest to keep convincing Factorio style
- minimal hand-drawing
- strongest production path if we accept a larger footprint

Cons:

- implies changing the current survey station prototype away from a chest clone
- more prototype work later

### Option B: Keep the current `1x1` survey station

Use:

- the radar only as a reference and source of visual motifs
- PixelLab to generate a much smaller survey mast, sensor head, and gauge unit
- a simpler `1x1` base under those parts

Pros:

- less gameplay and prototype change

Cons:

- harder art problem
- more manual compositing and reduction work
- easier to drift away from Factorio style

## Recommendation

For the survey station specifically, Option A is the right path if the goal is to reduce manual pixel-art burden.

## What To Keep Vanilla

If we take the radar-derived path, keep these parts vanilla as long as possible:

- support legs
- lower base frame
- circular center platform
- most lower housing shapes
- shadow layer
- integration patch

These are already correct for Factorio.

## What To Replace Or Add

Use PixelLab or light paint-over for:

- radar dish replacement
- compact sensor mast
- ecology survey head
- gauge/control box
- sampling canister or measurement pod
- extra cables or rugged field attachments

The key is to modify only the functional top module and a few attachments, not the whole machine.

## PixelLab Prompt Strategy

Generate modules, not the full station.

Ask for:

- isolated industrial components
- transparent background
- no scene
- no house
- no cute styling
- high top-down sprite read
- practical salvaged machine construction

Use [factorio-art-style-reference.md](/mnt/c/Code/SquirrelTrouble/docs/factorio-art-style-reference.md) as the style basis.

## Suggested PixelLab Component Prompts

### Sensor Mast

```text
compact industrial sensor mast for a Factorio-style machine, rugged steel support, small antenna assembly, exposed cables, bolted plates, dust and rust, practical engineer-built field instrument, high top-down game sprite, isolated transparent background, no scene, no cute stylization
```

### Survey Head

```text
industrial ecology survey head for a Factorio-style machine, compact scanning instrument, mechanical sensor housing, lenses, gauges, vents, wires, rugged salvaged construction, muted grounded palette, high top-down game sprite, isolated transparent background, no scene, no character, no cute stylization
```

### Control Box

```text
small industrial control box for a Factorio-style field machine, bolted metal housing, analog gauges, warning markings, wires and pipe connections, worn steel, dust, rust, practical factory-edge equipment, high top-down game sprite, isolated transparent background, no scene
```

### Sampling Unit

```text
compact environmental sampling unit for a Factorio-style machine, rugged instrument canister with industrial fittings, tubes, brackets, and valves, engineered not decorative, muted grounded palette, high top-down game sprite, isolated transparent background, no scene
```

## GIMP Workflow

For a low-manual-art pass:

1. Open `factorio-radar-frame-00.png` in GIMP.
2. Keep the lower frame, legs, and base intact.
3. Hide or paint over only the radar dish and upper scanner parts.
4. Paste or paint-over one or more generated PixelLab components into that upper region.
5. Keep the silhouette believable and mechanically connected.
6. Reuse the vanilla shadow and integration patch unchanged at first.

This is kitbashing and paint-over, not full sprite creation.

## Hard Rule

If the result starts looking cute, toy-like, or scene-based, revert to the vanilla base more aggressively.

The vanilla base is the anchor that keeps the asset believable.
