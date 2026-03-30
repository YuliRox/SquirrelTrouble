# PixelLab Prompt Templates

Status: agent-facing working guide

Purpose:
- provide reusable prompt templates for generating `squirrel_madness` art with PixelLab
- keep outputs stylistically consistent with Factorio-like scenes
- separate documented PixelLab guidance from project-specific prompt conventions

Primary references:
- `https://api.pixellab.ai/v2/llms.txt`
- `https://www.pixellab.ai/docs/options/guidance`
- `https://www.pixellab.ai/docs/options/camera`
- `https://www.pixellab.ai/docs/options/inpainting`
- `https://www.pixellab.ai/docs/tools/consistent-style`
- `https://www.pixellab.ai/docs/tools/style`
- `https://www.pixellab.ai/docs/tools/animate-with-text-pro`

## Documented PixelLab Guidance

PixelLab documents these useful prompt behaviors:

- `description` is the main prompt field.
- `negative description` is supported for exclusion guidance.
- `view` and `direction` are weak controls and should be reinforced in the prompt text.
- `style image` or `style_images` are the main consistency tools.
- `color_image` can help lock palette.
- `no_background` is available and should be used for asset extraction.
- for inpainting, describe the whole visible scene, not just the masked area.

## Project Conventions

These are not from PixelLab docs. They are the house rules for this mod.

- Always generate against 1-4 style crops from actual Factorio scenes or approved mockups.
- Prefer one style crop for palette and one for material language.
- Keep prompts focused on gameplay readability before fine detail.
- Ask for clean silhouettes, restrained texture noise, and readable forms at small scale.
- Generate transparent-background outputs for all asset candidates that are not full-scene concept art.
- Do not ask PixelLab to invent UI framing, text labels, or decorative backgrounds for production assets.

## Style Pack Inputs

Each asset generation task should gather:

1. `style_images`
- 1 close crop of belts, inserters, rusty metal, or forest edge
- 1 crop that shows palette and contrast
- optional 1 crop focused on vegetation if generating trees or saplings
- optional 1 crop focused on industrial props if generating feeder, stash, or survey station

2. `color_image`
- optional small crop when the palette must stay tightly controlled

3. `description`
- subject + gameplay role + view + readability + material language

4. `negative description`
- avoid painterly blur, noisy backgrounds, extra props, text, photorealism, oversaturated colors, ambiguous silhouettes

## Base Prompt Template

Use this as the starting point for most asset requests.

```text
[subject], designed as a Factorio mod game asset, readable at small scale, clear silhouette, top-down to slightly angled game-view sprite, industrial-nauvis aesthetic, grounded colors, subtle wear, clean outline separation, restrained texture detail, no background, transparent asset output
```

## Base Negative Template

```text
no background scene, no text, no UI frame, no heavy motion blur, no painterly brush strokes, no photorealism, no extreme saturation, no soft unreadable silhouette, no extra unrelated props, no character crowd, no watermark
```

## Request Skeleton

Use this shape for agent-generated PixelLab requests:

```json
{
  "description": "<asset-specific description>",
  "negative_description": "<asset-specific negative description>",
  "style_images": ["<style-1>", "<style-2>"],
  "color_image": "<optional-palette-image>",
  "no_background": true
}
```

For icons, add or request:
- centered composition
- single subject
- strong silhouette
- minimal perspective distortion

For world sprites, add or request:
- game-view readability
- grounded base contact
- production-safe crop with no environment baked in

## Endpoint Recommendations

These are project recommendations, not documented mandates.

- icons and small props:
  - `create-image-bitforge` or `generate-image-v2`
- consistent asset families:
  - `generate-with-style-v2`
- squirrel turnaround:
  - `create-character-with-4-directions` or `create-character-with-8-directions`
- squirrel animation from approved reference:
  - `animate-with-text-v2`

## Asset Templates

### 1. Squirrel Concept Sprite

Suggested endpoint:
- `generate-with-style-v2`

Prompt:

```text
small squirrel wildlife unit for a Factorio mod, cute but grounded, readable at small scale, clear tail and ear silhouette, top-down to slightly angled game-view sprite, industrial forest edge aesthetic, subtle rusty and dusty palette influence from Factorio scenes, restrained texture detail, neutral wildlife, designed to sit clearly near belts and tree lines, transparent background
```

Negative:

```text
no cartoon mascot proportions, no anime face, no photoreal fur, no giant eyes, no busy background, no extra animals, no dramatic pose, no blur, no text, no watermark
```

### 2. Squirrel Turnaround

Suggested endpoint:
- `create-character-with-8-directions`

Prompt:

```text
small squirrel wildlife unit for a Factorio-style game, compact body, readable tail shape, grounded proportions, clear silhouette from every direction, subtle industrial-forest color palette, transparent background
```

Notes:
- Reinforce direction in the prompt if a specific facing matters.
- Use the same approved squirrel concept image as the reference base if possible.

### 3. Squirrel Walk Or Idle Animation

Suggested endpoint:
- `animate-with-text-v2`

Prompt:

```text
gentle squirrel walk cycle for a top-down factory game, small quick steps, tail bouncing subtly, readable at small scale, no exaggerated smear, preserve silhouette and proportions
```

Negative:

```text
no squash-and-stretch cartoon exaggeration, no camera motion, no background, no extra limbs, no inconsistent tail shape
```

### 4. Nut Icon

Suggested endpoint:
- `create-image-bitforge`

Prompt:

```text
single nut item icon for a Factorio mod, centered composition, simple readable silhouette, subtle shell texture, grounded natural browns, transparent background
```

Negative:

```text
no branch, no leaves, no pile of nuts, no bowl, no background, no text, no photoreal macro look
```

### 5. Nut Sapling Icon

Prompt:

```text
small plantable sapling item icon for a Factorio mod, young nut tree sprout with simple roots or wrapped base, centered composition, readable silhouette, transparent background
```

### 6. Nut Tree World Sprite

Suggested endpoint:
- `generate-with-style-v2`

Prompt:

```text
nut-bearing tree for a Factorio-style world sprite, healthy but slightly rugged, readable canopy shape from top-down game view, distinct from generic forest tree, subtle visible nut clusters, transparent background
```

Negative:

```text
no realistic forest background, no ground plane, no thick atmospheric lighting, no painterly blur, no oversized fruit
```

Notes:
- Generate multiple variations from the same style pack.
- Keep trunk and canopy readable against Factorio terrain.

### 7. Harvested Nut Tree World Sprite

Prompt:

```text
recently harvested nut tree for a Factorio-style world sprite, visibly picked over but still alive, thinner canopy, fewer leaves, no nuts remaining, transparent background
```

### 8. Nut Sapling World Sprite

Prompt:

```text
young nut tree sapling for a Factorio-style world sprite, small, fragile, easy to distinguish from mature trees, readable from top-down game view, transparent background
```

### 9. Squirrel Feeder

Prompt:

```text
squirrel feeder structure for a Factorio mod, 1x1 placeable utility object, industrial handmade look, wood and scrap metal construction, small tray or bowl area for nuts, readable from top-down game view, transparent background
```

Negative:

```text
no modern pet-store look, no shiny plastic, no decorative garden ornament, no background scene, no text
```

### 10. Forest Survey Station

Prompt:

```text
forest survey station for a Factorio mod, 1x1 placeable field instrument, improvised industrial ecology device, compact sensor post with rugged housing, readable from top-down game view, transparent background
```

Negative:

```text
no sci-fi hologram tower, no clean white laboratory style, no oversized satellite dish, no background
```

### 11. Forest Stash

Prompt:

```text
visible squirrel loot stash for a Factorio mod, small forest-side cache, mix of sticks, scrap, and hidden industrial shinies, readable as a stash from top-down game view, transparent background
```

Negative:

```text
no treasure chest fantasy style, no pirate props, no huge item pile, no background scene
```

### 12. Technology Icons

All tech icons should use a centered subject, one main idea, clean silhouette, and transparent background.

`arboriculture`

```text
technology icon for arboriculture in a Factorio mod, nut sapling and careful forest restoration theme, centered composition, clean industrial strategy-game icon, transparent background
```

`wildlife-diversion`

```text
technology icon for wildlife diversion in a Factorio mod, squirrel feeder and managed coexistence theme, centered composition, clean readable strategy-game icon, transparent background
```

`forest-surveying`

```text
technology icon for forest surveying in a Factorio mod, rugged survey station and ecological monitoring theme, centered composition, clean readable strategy-game icon, transparent background
```

`wildlife-relocation`

```text
technology icon for wildlife relocation in a Factorio mod, nonlethal squirrel transfer theme, centered composition, readable strategy-game icon, transparent background
```

`ecological-stabilization`

```text
technology icon for ecological stabilization in a Factorio mod, healthy forest corridor and stable factory coexistence theme, centered composition, readable strategy-game icon, transparent background
```

## Scene-To-Asset Workflow

Yes, a typical Factorio scene can be used to help generate fitting assets, but use it as a style guide, not as the literal composition target.

Recommended workflow:

1. Collect 2-4 scene crops.
- one forest-edge crop
- one factory-material crop
- one palette crop
- optional one vegetation crop

2. Write the asset prompt with:
- subject
- gameplay role
- view wording
- readability wording
- transparency requirement

3. Generate a small batch.
- keep the subject isolated
- do not ask for a full scene when the deliverable is a sprite or icon

4. Pick one approved image as the family anchor.
- reuse it as the reference for later variants

5. Only after approval, move to turnarounds or animation.

## Short Prompt Forms

These are optimized for quick iteration.

Squirrel:

```text
small squirrel wildlife unit, Factorio-style game asset, readable tail silhouette, top-down game sprite, subtle industrial forest palette, transparent background
```

Nut tree:

```text
nut-bearing tree, Factorio-style world sprite, readable canopy, distinct nut clusters, transparent background
```

Feeder:

```text
squirrel feeder, 1x1 Factorio structure, handmade industrial wood-and-metal object, top-down game sprite, transparent background
```

Survey station:

```text
forest survey station, compact rugged field instrument, 1x1 Factorio structure, top-down game sprite, transparent background
```

Stash:

```text
visible squirrel stash, small forest cache with scrap and stolen factory parts, top-down game sprite, transparent background
```

## Agent Checklist

Before sending a PixelLab request:

- choose the correct endpoint for icon, object, turnaround, or animation work
- attach 1-4 consistent style images
- restate view or facing in the prompt text
- include `no_background` for production assets
- include a negative prompt
- ask for a single subject, not a scene, unless the goal is concept exploration
- preserve family consistency by reusing the same style pack and approved anchor images

