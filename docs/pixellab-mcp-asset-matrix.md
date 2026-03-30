# PixelLab MCP Asset Matrix

Status: agent-facing tool selection guide

Purpose:
- map the current `squirrel_madness` asset backlog to the PixelLab MCP tools that are actually exposed here
- make it clear where MCP is a strong fit, a weak fit, or only a draft-generation path
- keep asset generation decisions reusable instead of re-litigating the tool choice each time

Primary references:
- `https://api.pixellab.ai/mcp/docs`
- `https://api.pixellab.ai/v2/llms.txt`
- current asset backlog in `docs/asset-requirements.md`

## Available MCP Tool Families

The PixelLab MCP available in this environment exposes these relevant creation tools:

- `create_character`
- `animate_character`
- `create_map_object`
- `create_tiles_pro`
- `create_isometric_tile`
- `create_topdown_tileset`
- `create_sidescroller_tileset`

And the expected supporting tools:

- `get_*`
- `list_*`
- `delete_*`

## Selection Rules

- Prefer `create_map_object` for single world objects and most icons.
- Prefer `create_character` plus `animate_character` for squirrels and other moving fauna.
- Prefer `create_tiles_pro` only when several related variants should be generated together in one consistent batch.
- Do not default to tileset tools for normal Factorio entity art.
- Treat MCP output as candidate production art, not guaranteed final art.

## Asset Matrix

| Asset | Milestone | Best MCP Tool | Why | Fit | Expected cleanup |
| --- | --- | --- | --- | --- | --- |
| Squirrel base sprite set | 4 | `create_character` | Native directional creature workflow with reusable base for animation. | Medium | High. There is no squirrel-specific quadruped template, so anatomy and silhouette will need correction. |
| Squirrel idle/walk animation | 4 | `animate_character` | Direct follow-on from generated character base. | Medium | High. Motion readability must be checked at Factorio gameplay scale. |
| Squirrel icon | 4 | `create_map_object` | Easier to prompt a centered readable icon than to downscale character sheets. | High | Medium. Usually needs simplification and palette cleanup. |
| Forest stash world sprite | 4 | `create_map_object` | Single transparent prop is exactly what the tool is for. | High | Medium. Add Factorio-style shadow and base-contact polish. |
| Forest stash icon | 4 | `create_map_object` | Same asset family, icon-specific prompt. | High | Low to medium. |
| Nut item icon | 2 | `create_map_object` | Best fit for isolated item art. | High | Low. |
| Nut sapling item icon | 2 | `create_map_object` | Small isolated object, transparent background. | High | Low. |
| Nut tree world sprite | 2 | `create_map_object` | Best available MCP fit for a single tree object. | Medium | High. Canopy shape, scale, and terrain read will need manual correction. |
| Harvested nut tree world sprite | 2 | `create_map_object` | Keeps the tree family in one style path. | Medium | High. Must read as harvested, not dead. |
| Nut sapling world sprite | 2 | `create_map_object` | Good match for a small environmental object. | High | Medium. Needs careful scale tuning. |
| Nut tree icon | 2 | `create_map_object` | Cleaner than extracting from world art. | High | Low to medium. |
| Squirrel feeder world sprite | 2 | `create_map_object` | Strong fit for a 1x1 utility structure. | High | Medium. Likely needs sharper edges and integration polish. |
| Squirrel feeder icon | 2 | `create_map_object` | Straightforward icon path. | High | Low. |
| Forest survey station world sprite | 1 | `create_map_object` | Good fit for a compact machine-like prop. | High | Medium. Sensor silhouette may need iteration. |
| Forest survey station icon | 1 | `create_map_object` | Straightforward icon path. | High | Low. |
| Tech icons for surveying, arboriculture, diversion, relocation, stabilization | 1+ | `create_map_object` | MCP has no dedicated tech-icon tool; centered single-subject art is the best approximation. | Medium | Medium to high. Many tech icons will still need manual compositing. |
| Related decorative variants or terrain experiments | Optional | `create_tiles_pro` | Useful when several related tiles should share one palette and style pass. | Low to medium | High if used directly in-game. Better for grouped experiments than entity production. |
| Style probe from a Factorio screenshot | Any | `create_map_object` with `background_image` | Best MCP-native path for style-matched object generation. | High | N/A. Use as reference-driven generation, not a final asset by itself. |

## Tool Guidance By Family

### Characters and fauna

Use:

- `create_character`
- `animate_character`

Use this for:

- squirrel directional bases
- squirrel idle or walk drafts

Do not use this for:

- icons
- trees
- feeder or survey station props

Constraint:

- The documented quadruped templates are `bear`, `cat`, `dog`, `horse`, and `lion`.
- There is no documented squirrel template.
- Squirrel output should therefore be treated as guided approximation, not a turnkey result.

### Single world objects

Use:

- `create_map_object`

Use this for:

- nut
- sapling
- feeder
- survey station
- stash
- tree experiments
- most icons

Best use:

- when you can provide `background_image` style context from Factorio screenshots or scene crops
- when you want transparent-background output
- when you want one asset at a time, not a sheet

### Related batches

Use:

- `create_tiles_pro`

Use this for:

- several related variants
- grouped style experiments
- decorative support art

Do not default to it for:

- single props
- characters
- ordinary Factorio entity sprites

### Tileset tools

Use cautiously:

- `create_topdown_tileset`
- `create_sidescroller_tileset`
- `create_isometric_tile`

These are not primary tools for this mod. They are better suited to:

- mood boards
- terrain concept experiments
- external prototype work

They are a weak fit for ordinary Factorio entity production because Factorio entities are not authored as Wang tilesets or isometric blocks.

## Recommended Production Order

If we use PixelLab MCP for the current backlog, generate assets in this order:

1. `create_map_object` style probes from one or more Factorio scene crops.
2. `create_map_object` for `forest survey station`, `squirrel feeder`, and `forest stash`.
3. `create_map_object` for `nut`, `nut sapling`, `nut tree`, and `harvested nut tree`.
4. `create_character` for the squirrel directional draft.
5. `animate_character` for squirrel idle and walk once the base squirrel passes visual review.
6. icon-focused passes after the world sprites have stabilized.

Reason:

- static props are the fastest way to validate whether the style direction works
- squirrel art is the highest-risk output and should not be animated before the base silhouette is acceptable
- icons are easier to finalize after the object language has settled

## Factorio Fit Warnings

- PixelLab MCP is strong at themed pixel-art generation, not at Factorio-specific sprite-sheet conventions.
- A visually nice output can still fail in actual gameplay because of scale, contrast, or shadow handling.
- Squirrel assets are the most likely to need manual touch-up.
- Tech icons are likely to need manual compositing even if the base image is generated successfully.
- Tree assets remain risky because the mod currently leans on vanilla tree prototype structure.

## Short Recommendation

The highest-value first experiment is:

1. `create_map_object` for `forest survey station`
2. `create_map_object` for `squirrel feeder`
3. `create_map_object` for `forest stash`
4. `create_character` for the squirrel

That sequence gives early signal on style fit before spending time on animation-heavy or higher-risk assets.
