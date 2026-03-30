# Factorio Art Style Reference

Status: working visual reference

Purpose:
- give agents and artists a short shared description of the Factorio visual language
- provide a reusable basis for PixelLab prompting and asset review
- keep generated assets aligned with the game's actual look instead of drifting into cute or generic pixel-art styles

## Short Description

Factorio's art style is practical, industrial, and unsentimental.

Objects look engineered first, decorative never. Forms are readable from a high top-down gameplay view and built from believable machine parts: metal plates, pipes, bolts, grates, frames, cables, rust, dust, oil, and worn paint. Colors stay grounded and muted. Contrast is used for function and readability, not charm. Surfaces feel used, dirty, and mechanically plausible. Even improvised devices look workshop-built, not handcrafted in a whimsical way.

## Core Elements

- high top-down readability
- functional silhouette over decorative silhouette
- engineered construction
- visible mechanical parts
- worn industrial materials
- restrained grounded palette
- believable grime, dust, rust, and wear
- practical composition
- minimal cuteness
- no toy-like scene staging

## Material Language

Typical Factorio materials:

- worn steel
- painted sheet metal
- cast metal housings
- rivets and bolts
- pipes and couplings
- grates and vents
- rubber belts
- glass gauges and lenses
- electrical boxes and cabling
- dirt, oil stains, dust, and corrosion

These materials should read as used industrial equipment, not polished showroom machinery.

## Shape Language

Prefer:

- compact machine bodies
- exposed functional attachments
- clear base contact with the ground
- attachment points, supports, or frames
- asymmetry when it suggests real function
- silhouettes that still read when viewed small in gameplay

Avoid:

- cute proportions
- tiny house or diorama staging
- soft toy-like shapes
- ornamental fantasy shapes
- oversized decorative trim
- scene composition that makes the asset look like a miniature environment instead of a placeable object

## Color And Contrast

Prefer:

- muted browns
- dusty greens
- worn reds
- faded yellows
- dirty steel blues
- oxidized metal tones
- natural dirt and scrub vegetation colors

Use contrast to:

- separate machine parts
- define functional edges
- keep gameplay readability at distance

Do not use contrast to:

- make the asset feel cheerful or cute
- create candy-like color blocking

## Terrain And Environment Read

Factorio assets usually sit in:

- dirt
- scrub grass
- rocky ground
- polluted soil
- factory edges
- sparse or rugged vegetation

That means an asset should feel believable next to belts, inserters, pipes, poles, miners, and tree lines. It should not feel like it belongs to a cozy village, toy diorama, or decorative pixel-art scene.

## Prompt Compression

When a short prompt fragment is needed, use:

```text
practical industrial machine, high top-down game sprite, engineered not decorative, worn steel, bolts, pipes, cables, gauges, dust, rust, muted grounded palette, readable functional silhouette, no cute stylization, no diorama
```

For this mod, add:

```text
frontier ecology equipment built from salvaged industrial parts, rugged field-use device, believable in a factory at the forest edge
```

## Review Heuristic

Reject or rework an asset if it reads as any of the following:

- cute
- toy-like
- cozy
- decorative
- house-like
- fantasy gadget
- miniature diorama
- generic pixel-art prop that could belong to any farming or life-sim game

Approve an asset only if it still feels plausible when mentally placed:

- beside a transport belt
- next to a power pole
- at the edge of a dirty worksite
- among patched-together industrial infrastructure

## Use In This Repo

Use this document when:

- writing PixelLab prompts
- reviewing generated drafts
- deciding whether an asset belongs in `squirrel_madness`
- correcting assets that drift too far toward cute or generic pixel-art styles
