# PixelLab Batch 01

Generated: `2026-03-20`

Source style references:

- `docs/reference/pixellab/crops/style-industrial-props-01.png`
- `docs/reference/pixellab/crops/style-forest-ground-01.png`
- `docs/reference/pixellab/crops/style-mixed-industry-forest-01.png`

## Draft Files

- `forest-survey-station.png`
- `forest-survey-station-v2.png`
- `forest-survey-station-radar-init-01.png`
- `forest-survey-station-radar-init-01.json`
- `squirrel-feeder.png`
- `forest-stash.png`
- `squirrel-draft-01.zip`
- `squirrel-draft-01/rotations/*.png`
- `squirrel-draft-01/metadata.json`

## Object IDs

- Forest survey station: `eab8e2e2-695f-4b7b-a8e3-fd71b77e2839`
- Forest survey station v2: `1be945bd-57f0-4aaf-b8e4-b384e0f63c1d`
- Forest survey station radar-init 01: seed `4242`, saved in local JSON metadata
- Squirrel feeder: `0362d675-5f50-49da-b798-f705fed93244`
- Forest stash: `8e95cee6-9059-433f-9605-0695f63fae7f`
- Squirrel draft 01: `a7a8cfed-5f7b-4b1f-bb5a-32ed118356da`

## First Assessment

- `forest-survey-station.png`: wrong semantic read. It came back as a small cabin/house scene with trees, not a compact survey device.
- `forest-survey-station-v2.png`: materially better. It reads as a rugged industrial device, though it is still too clean and studio-like to be final Factorio art.
- `forest-survey-station-radar-init-01.png`: structurally closer to the radar base, but too muddy and under-defined after transparent-background processing. Better proof of workflow than a usable asset.
- `squirrel-feeder.png`: usable as a rough direction for a nut box or hopper, but it reads more like a decorative crate than a placeable feeder station.
- `forest-stash.png`: wrong asset entirely. It returned a squirrel portrait instead of a stash.
- `squirrel-draft-01/rotations/*.png`: technically valid directional output, but the silhouette reads more like a cat than a squirrel.

## Working Prompt

The improved survey station used:

```text
forest survey station for a Factorio mod, compact 1x1 industrial field instrument, practical engineer-built machine, engineered not decorative, high top-down game sprite, functional silhouette, worn steel housing, bolted panels, exposed pipes and cables, small antenna mast, sensor head, gauge box, rugged support frame, dust, grime, rust, muted grounded palette, believable factory-edge equipment built from salvaged industrial parts, readable at gameplay scale, transparent background, no cute stylization, no diorama, no house, no cabin, no trees, no surrounding scene, no character
```

The radar-init attempt used:

```text
convert this Factorio radar into a forest survey station for a Factorio mod, preserve the core industrial machine silhouette and footprint, keep the heavy base, support legs, metal housing, cables, and engineered construction, replace the radar-specific function with ecology survey equipment such as a compact sensor mast, antenna, gauges, sampling unit, and rugged field instrumentation, practical engineer-built machine, engineered not decorative, high top-down game sprite, functional silhouette, worn steel, bolted panels, exposed pipes and cables, dust, grime, rust, muted grounded palette, believable factory-edge equipment built from salvaged industrial parts, readable at gameplay scale, transparent background
```

## Recommendation

Do not integrate this batch directly.

Use it as a calibration pass and iterate:

1. keep the stronger Factorio-art-style language from the survey station v2 prompt
2. if using the radar base again, switch from full-image init to masked inpainting so the base silhouette is preserved but the top module can change cleanly
3. further push grime, asymmetry, and factory wear so props stop reading like isolated studio renders
4. try a more constrained squirrel path, likely icon/object-style concept first before another character turnaround
5. rewrite stash and feeder prompts with stricter functional wording and explicit anti-character / anti-container-diorama language
