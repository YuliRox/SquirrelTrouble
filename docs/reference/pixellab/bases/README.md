# PixelLab Base Assets

Status: working extraction note

Purpose:
- record extracted vanilla assets that can be reused as structural bases
- make it clear which files are suitable for direct editing, style reference, or compositing
- reduce dependence on screenshots when a clean in-game source asset already exists

## Extracted Radar Assets

Source:

- `C:\Program Files\Factorio\data\base\graphics\entity\radar\radar.png`
- `C:\Program Files\Factorio\data\base\graphics\entity\radar\radar-shadow.png`
- `C:\Program Files\Factorio\data\base\graphics\entity\radar\radar-integration.png`

Extracted files:

- `factorio-radar-frame-00.png`
- `factorio-radar-frame-08.png`
- `factorio-radar-shadow-frame-00.png`
- `factorio-radar-integration.png`
- `radar-192.png`

## What These Are

- `factorio-radar-frame-00.png`
  Main visible radar sprite, one frame cropped from the `64`-direction vanilla sprite sheet.
- `factorio-radar-frame-08.png`
  Second orientation frame from the same sheet for comparison.
- `factorio-radar-shadow-frame-00.png`
  Matching vanilla shadow layer frame.
- `factorio-radar-integration.png`
  Ground integration patch used by the vanilla entity.
- `radar-192.png`
  Resized working copy made for previous PixelLab experiments.

## Recommended Use

Use `factorio-radar-frame-00.png` as:

- the structural base for a radar-derived survey station
- a clean reference image for PixelLab init-image or inpainting workflows
- a manual paint-over base in GIMP

Use `factorio-radar-shadow-frame-00.png` and `factorio-radar-integration.png` as:

- vanilla companion layers to preserve Factorio-like grounding and readability
- optional keep-as-is layers if the survey station becomes a radar-derived entity

## Important Constraint

These files fit the vanilla radar prototype, not the current mod survey station prototype.

The current mod entity in [entities.lua](/mnt/c/Code/SquirrelTrouble/squirrel_madness/prototypes/entities.lua#L51) clones `wooden-chest`, so:

- a full radar-base workflow implies changing the survey station to a radar-like prototype later
- if the survey station must remain `1x1`, use these files as reference or kitbash source, not as drop-in art

## Best First Base

Start with:

- `factorio-radar-frame-00.png`

Reason:

- clear top-down silhouette
- transparent background
- exact Factorio proportions
- no baked terrain
- easier to transform than a screenshot
