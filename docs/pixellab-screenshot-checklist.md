# PixelLab Screenshot Checklist

Status: operator checklist

Purpose:
- guide in-game screenshot capture for PixelLab style references
- gather the minimum useful Factorio scene crops before generating the first asset batch
- avoid low-value screenshots that look good as scenes but do not help asset generation

Use this before generating:

- `forest survey station`
- `squirrel feeder`
- `forest stash`
- first-pass `squirrel`

## Goal

Capture `3-4` screenshots or crops that communicate:

- industrial material language
- forest-edge vegetation and terrain
- overall palette and contrast
- optional ground-level context for where squirrels will appear

These images are style references, not final art. Tight, readable crops are more useful than cinematic full-screen shots.

## Before Launch

- [ ] Create a folder for the screenshots, for example `reference/pixellab/`.
- [ ] Prepare to save `png` screenshots if possible.
- [ ] Plan to capture during daytime unless a darker mood is explicitly desired.

## Before Taking Any Shot

- [ ] Start a new or existing scenario with visible belts, inserters, machines, and nearby forest.
- [ ] Move the engineer to a forest edge where industry and vegetation are both visible.
- [ ] Avoid combat, smoke, fire, explosions, alerts, and other temporary effects.
- [ ] Hide UI if convenient. If not, at least keep the UI from covering the area being captured.
- [ ] Use normal gameplay zoom, then adjust only if the scene is too wide to read clearly.

## Required Shot 1: Industrial Prop Reference

Purpose:
- give PixelLab the metal, wood, rust, and machine-surface language for structures like the feeder and survey station

Checklist:
- [ ] Capture a tight crop with belts, inserters, machine edges, or chest-like props.
- [ ] Include worn metal, bolts, wood, or practical industrial surfaces.
- [ ] Keep the shot tight enough that the materials are readable.
- [ ] Avoid giant open terrain areas dominating the image.

Good candidates:
- belt + inserter + chest corner
- machine cluster edge
- rusty structure next to transport belts

Suggested filename:
- `style-industrial-01.png`

## Required Shot 2: Forest Edge Reference

Purpose:
- give PixelLab the tree, grass, dirt, and natural clutter language for stash, sapling, and squirrel context

Checklist:
- [ ] Capture a transition zone where trees meet cleared ground or factory edges.
- [ ] Make sure trunks, foliage, dirt, and grass are all visible.
- [ ] Prefer muted, believable greens over unusually bright or saturated scenes.
- [ ] Keep enough ground visible that small props could plausibly sit there.

Good candidates:
- forest edge beside a belt line
- trees bordering a work area
- dirt and grass under sparse canopy

Suggested filename:
- `style-forest-edge-01.png`

## Required Shot 3: Palette And Contrast Reference

Purpose:
- lock the overall mood so generated assets do not drift too bright, too colorful, or too soft

Checklist:
- [ ] Capture a scene that shows the color balance you want the mod assets to inherit.
- [ ] Include both natural and industrial materials in the same frame if possible.
- [ ] Prefer calm daylight with readable shadows.
- [ ] Avoid heavy fog, lasers, pollution clouds, or night tint unless that is the desired permanent style.

Good candidates:
- mid-size factory edge near trees
- a quiet daytime scene with belts, dirt, and foliage

Suggested filename:
- `style-palette-01.png`

## Optional Shot 4: Squirrel Ground Context

Purpose:
- help with the first squirrel pass by showing the actual ground clutter and visual scale near belts and tree lines

Checklist:
- [ ] Capture a small area where a squirrel would realistically appear.
- [ ] Include terrain, tree bases, and nearby machinery or transport elements.
- [ ] Keep the shot readable at small scale. The squirrel should not need to compete with extreme clutter.
- [ ] Prefer edges of production areas, not the center of a dense machine block.

Good candidates:
- belt line beside trees
- chest or stash-like corner near forest ground
- edge of a clearing with transport and vegetation

Suggested filename:
- `style-squirrel-context-01.png`

## Quality Filter

Reject a screenshot if any of these are true:

- [ ] The useful subject area is tiny compared with the full image.
- [ ] The shot is mostly UI.
- [ ] The scene is dominated by combat, smoke, fire, or temporary effects.
- [ ] The image is too dark to read material shapes cleanly.
- [ ] The image looks dramatic but does not tell PixelLab what materials or silhouettes to copy.

## After Capture

- [ ] Keep the best `3-4` images only.
- [ ] If needed, crop them tighter around the useful style information.
- [ ] Share the exact file paths.
- [ ] If one image is mainly about palette, say so explicitly.
- [ ] If one image is mainly about trees/terrain, say so explicitly.

## Minimum Handoff

When the screenshots are ready, provide:

- path to `1` industrial screenshot
- path to `1` forest-edge screenshot
- path to `1` palette/contrast screenshot
- optional path to `1` squirrel-context screenshot

That is enough to begin the first PixelLab generation pass.
