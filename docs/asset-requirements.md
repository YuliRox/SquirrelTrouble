# Squirrel Trouble Asset Requirements

Status: working art production brief

Purpose:
- list the art assets the mod needs
- distinguish hard Factorio requirements from project conventions
- make it clear which assets are needed now and which can wait for later milestones

Source basis:
- current prototypes in `squirrel_madness/prototypes/*.lua`
- roadmap scope in `docs/planned.md`
- official Factorio 2.0.76 prototype docs, especially `IconData`, `ItemPrototype`, `TechnologyPrototype`, `ContainerPrototype`, and `UnitPrototype`

## Hard Requirements

- Use `.png` files with transparency for all custom icons and sprites.
- Item, entity, and placeable-item icons in the current code are `64x64`.
- Technology icons in the current code are `256x256`.
- World sprites do not have one global required pixel size. Factorio reads the sprite dimensions from the prototype fields that reference the image.
- If custom world art does not match the dimensions or sheet layout of the vanilla prototype we are cloning, the prototype definitions must be updated at the same time.

## Project Conventions

- Put exported runtime assets under `squirrel_madness/graphics/`.
- Suggested folders:
  - `squirrel_madness/graphics/icons/`
  - `squirrel_madness/graphics/technology/`
  - `squirrel_madness/graphics/entities/squirrel/`
  - `squirrel_madness/graphics/entities/trees/`
  - `squirrel_madness/graphics/entities/structures/`
- Keep icons on transparent backgrounds with readable silhouettes at Factorio UI scale.
- For 1x1 placeable structures, prefer a base export around `128x128` for the world sprite, with an optional `2x` HR export if we decide to use high-resolution sprite definitions later.
- For animated squirrels, keep one consistent frame box for the whole sheet. A practical starting convention is `128x128` or `192x192` per frame, then adjust prototype metadata to match.
- For PixelLab-specific generation guidance, use [pixellab-prompt-templates.md](/mnt/c/Code/SquirrelTrouble/docs/pixellab-prompt-templates.md) and [pixellab-mcp-asset-matrix.md](/mnt/c/Code/SquirrelTrouble/docs/pixellab-mcp-asset-matrix.md).
- For feeder art direction, prefer open wooden or iron chest/bin silhouettes with visible nuts over sack-only imagery. The feeder should read as placed infrastructure, not loose cargo.

## Asset Sourcing And Licensing Strategy

Research outcome as of `2026-03-26`:

- `Krastorio2` and `Krastorio2Assets` are viable asset-reference or reuse candidates for structure art. The mod portal lists them as `GNU LGPLv3`.
- `Space Exploration` and `Alien Biomes` are not safe bundled asset sources for this mod. They are under `Limited Distribution Only Licence`.
- `Arborist` is the preferred planting-mechanic integration target. Its repo documents `MIT License` and targets `Factorio 2.0`.
- `Robot Tree Farm update for 2.0` is a viable automation reference. The mod portal lists it for `Factorio 2.0` under `CC BY-SA 4.0`.
- `TreePlant` is not a direct integration target. It is both outdated for `Factorio 2.0` and licensed as `Visible Source, No Public Derivatives`.

Practical direction:

- prefer `Krastorio2Assets` when looking for building art that can stand in for feeder, survey station, or stash roles
- do not copy `Space Exploration` or `Alien Biomes` art into this repository
- if `Alien Biomes` is relevant later, treat it as compatibility inspiration or an optional runtime dependency, not a bundled asset source
- use `Arborist` as a dependency-backed baseline for general tree planting, then integrate the mod's own `nut-tree` into that broader planting flow
- use `Robot Tree Farm update for 2.0` as a dependency-backed automation layer for later forestry and replanting, so ecological care scales into normal Factorio logistics
- borrow ideas from `TreePlant` only at the design level, not as a code or asset source
- approved design borrow from `TreePlant`: a player-facing tree-healing / stump-recovery mechanic that is implemented in this mod's own code and content

Asset implications:

- custom squirrel art is still required
- custom nut-tree and harvested-nut-tree identity is still required even if general tree planting is delegated to Arborist-style mechanics
- some structure art pressure may be reduced if we can lawfully reuse or adapt `Krastorio2Assets`
- third-party squirrel assets from marketplaces such as the Unity Asset Store are on hold until we have an explicit license path that permits rendered 2D derivative redistribution inside a public Factorio mod

## Dependency Attribution And License Notes

Current dependency decision:

- `Arborist` and `robot_tree_farm_update` are acceptable dependency mods for this project
- the intended model is dependency plus compatibility patching, not vendoring their code or assets into this repository

What our own mod should mention:

- list both mods in dependency metadata when we wire them into `info.json`
- add a visible third-party dependency or credits section in project docs and public mod-description text
- name the mod, author, source or mod portal page, and license for each dependency

Recommended wording level:

- `Arborist` by Trevor Scott Price, used as an external dependency for general tree planting, MIT License
- `Robot Tree Farm update for 2.0` by DrAchaios, used as an external dependency for forestry automation, CC BY-SA 4.0

Important distinction:

- depending on these mods is different from copying or adapting their code or assets
- if we only depend on them and write our own compatibility patches, our mod does not need to vendor their source
- if we later copy or adapt `Arborist` code, include its MIT copyright and permission notice with the distributed source
- if we later copy or adapt material from `robot_tree_farm_update`, attribution and share-alike obligations become more significant, so avoid bundling or adaptation unless we intentionally accept those terms

This is an engineering compliance note, not legal advice.

## Held Squirrel Asset Direction

Research outcome as of `2026-03-27`:

- a realistic animated squirrel from the Unity Asset Store is technically attractive because it could be rendered into directional Factorio sprites
- however, the standard Unity Asset Store license is not a safe default for public Factorio-mod redistribution of extracted or rendered derivative sprite sheets
- for this use case, we would need an explicit license or written permission that permits:
  - derivative 2D renders from the 3D source asset
  - redistribution of those rendered sprites
  - use in a non-Unity product
  - distribution in an extractable mod package

Decision for now:

- keep this direction on hold
- do not build the mod around a Unity Asset Store squirrel unless we later secure clear redistribution rights from the asset publisher
- continue treating squirrel art as an unresolved requirement rather than a settled source

## Current Asset Checklist

| Asset | Used by | Needed now | Hard size / format | Notes |
| --- | --- | --- | --- | --- |
| `nut` icon | item `nut` | Yes | `64x64` `.png` | Replaces current wood placeholder. |
| `nut-sapling` icon | item `nut-sapling` | Yes | `64x64` `.png` | Should read as a plantable sapling item, not a full tree. |
| `wooden-squirrel-feeder` icon | item + entity icon | Yes | `64x64` `.png` | Early feeder tier. Should read like a simple open wooden chest or trough with visible nuts. |
| `steel-squirrel-feeder` icon | item + entity icon | Yes | `64x64` `.png` | Higher-capacity feeder tier. Should read like a sturdier steel bin upgrade, not a different machine family. |
| `forest-survey-station` icon | item + entity icon | Yes | `64x64` `.png` | Should read clearly in inventory and crafting menus. |
| `forest-stash` icon | entity icon | Yes | `64x64` `.png` | Runtime-only entity, but still needs a custom identity. |
| `squirrel` icon | entity icon | Yes | `64x64` `.png` | Used in entity prototype metadata. |
| `nut-tree` icon | entity icon | Yes | `64x64` `.png` | Distinct from ordinary vanilla trees. |
| `nut-tree-harvested` icon | entity icon | Yes | `64x64` `.png` | Picked state after nut harvest. |
| `nut-sapling` world sprite | placed sapling entity | Yes | `.png`, size defined by prototype | Current code clones a tree prototype. If we keep that clone layout, matching the base tree sprite layout is the cheapest path. |
| `nut-tree` world sprite set | mature nut tree entity | Yes | `.png`, size defined by prototype | Prefer several visual variations for natural worldgen. If fully bespoke, tree prototype sprite fields must be updated. |
| `nut-tree-harvested` world sprite set | picked nut tree entity | Yes | `.png`, size defined by prototype | Must visibly read as harvested but still living. |
| `wooden-squirrel-feeder` world sprite | early feeder structure | Yes | `.png`, size defined by `picture :: Sprite` | Chest-like 1x1 structure. The cheapest path is a wooden-chest-derived base with visible nuts. |
| `steel-squirrel-feeder` world sprite | upgraded feeder structure | Yes | `.png`, size defined by `picture :: Sprite` | Later 1x1 upgrade tier. Can reuse steel-chest visual language with an open nut bin or tray. |
| `forest-survey-station` world sprite | survey station structure | Yes | `.png`, size defined by `picture :: Sprite` | Also currently cloned from a chest-like placeholder. |
| `forest-stash` world sprite | stash structure | Yes | `.png`, size defined by `picture :: Sprite` | Needs to be readable as player-visible squirrel loot storage. |
| `squirrel` run animation set | visible squirrel unit | Yes | `.png` sprite sheet(s), size defined by `run_animation :: RotatedAnimation` | This is the main custom character asset for Milestone 4 playtesting. If the sheet layout differs from vanilla biters, prototype edits are required. |
| `arboriculture` technology icon | technology | Yes | `256x256` `.png` | Replaces automation placeholder. |
| `wildlife-diversion` technology icon | technology | Yes | `256x256` `.png` | Replaces logistics placeholder. |
| `forest-surveying` technology icon | technology | Yes | `256x256` `.png` | Replaces optics placeholder. |
| `wildlife-relocation` technology icon | technology | Soon | `256x256` `.png` | Tech exists now even though relocation gameplay lands later. |
| `ecological-stabilization` technology icon | technology | Soon | `256x256` `.png` | Tech exists now and should eventually stop using a vanilla placeholder. |

## Future Asset Checklist

These are not blockers for the current build, but should be planned early so later milestones are not forced to ship with placeholder art.

| Asset | Likely milestone | Hard size / format | Notes |
| --- | --- | --- | --- |
| relocation tool or drone icon | 5-6 | `64x64` `.png` | Needed once the relocation mechanic becomes player-facing. |
| tree treatment kit icon | 2-6 | `64x64` `.png` | Needed once tree healing becomes a player-facing mechanic. Exact implementation may be a capsule, spray, repair pack, or forestry tool. |
| forestry automation building or robot icon | 6+ | `64x64` `.png` | Needed if Robot Tree Farm-style planting or grove maintenance becomes player-facing automation. Exact shape depends on whether this is a station, drone, or network-only tool. |
| relocation world sprite or drone animation | 5-6 | `.png`, size defined by prototype | Exact requirements depend on whether relocation is an item, projectile, unit, or effect entity. |
| squirrel death / grievance marker art | 5-6 | usually `64x64` `.png` for icons | May be needed for map markers, alerts, or tutorial/UI feedback. |
| sanctuary / peace-zone markers | 7-8 | icon or sprite format depends on implementation | Could be map icons, GUI assets, or rendered overlays. |
| coexistence victory art | 8 | likely `256x256` `.png` or GUI sprite | Depends on how the ending is presented. |
| future chest-reordering escalation art | post-v1 | varies | Only needed if that mechanic survives scope cuts. |

## Asset-by-Asset Notes

### Squirrel

- Highest-priority art asset for the mod's identity.
- The current prototype clones `small-biter`, so replacing it cleanly means either:
  - paint over and preserve the base sheet layout, or
  - provide a new sheet layout and update the unit prototype fields accordingly
- Minimum useful delivery:
  - inventory/entity icon
  - run animation sheet set for on-screen movement
- Nice-to-have later:
  - custom death graphics
  - custom idle/passive variants if we stop relying on the cloned biter visuals

### Trees And Saplings

- The current nut tree, harvested nut tree, and sapling all clone vanilla tree prototypes.
- The intended gameplay direction has changed from "only plant nut trees" to "allow tree planting in general, using Arborist-style mechanics, while still integrating our own nut tree into that system".
- Cheapest replacement path:
  - keep the current tree prototype structure
  - swap icons first
  - later replace the world sprite sets while preserving the base layout
- Integration target:
  - prefer Arborist-compatible general planting behavior for normal trees
  - add `nut-tree` and `nut-sapling` as first-class participants in that broader planting flow rather than keeping a completely separate special-case planting mechanic
- Additional ecological-care mechanic:
  - include an in-mod tree-healing or stump-recovery tool inspired by `TreePlant`
  - treat this as part of habitat restoration, not as a military or industrial system
- Automation direction:
  - manual planting and healing should exist first
  - later automation should take cues from `Robot Tree Farm update for 2.0` so grove maintenance can be integrated into normal factory logistics
- If we want a completely bespoke tree implementation, expect extra prototype work beyond just dropping in new PNGs.
- Do not plan around copying `Alien Biomes` tree art into this repository. If alien-biome tree support is desired later, treat it as compatibility with installed prototypes, not bundled assets.

### Structures

- Feeder, survey station, and stash are currently chest-like 1x1 entities.
- That means custom structure art is straightforward compared with trees or units.
- A single main world sprite per structure is enough for a first custom pass.
- Optional shadow sprites and HR variants can be added later if needed.
- Feeder direction for v1:
  - `wooden-squirrel-feeder` should read like a cheap open wooden chest, crate, or trough containing nuts
  - `steel-squirrel-feeder` should read like the same idea scaled into a sturdier steel container with larger capacity
  - avoid sack-only feeder imagery; sacks can still inform icons for feed supply items later if needed
- Asset acquisition preference:
  - check `Krastorio2Assets` first for lawful stand-ins or adaptation candidates before commissioning or generating bespoke structure art

### Technology Icons

- These are the easiest asset wins because the code already exposes explicit technology prototypes with icon fields.
- Replace these early so the research branch stops reading like a vanilla placeholder tree.

## Recommended Production Order

1. Squirrel icon and squirrel run animation.
2. Nut icon, nut tree icon, harvested nut tree icon, sapling icon.
3. Wooden feeder, stash, and survey station icons plus world sprites.
4. Iron feeder icon and world sprite.
5. Technology icons for the squirrel research branch.
6. Full custom tree and sapling world sprite sets.
7. Later-milestone relocation, sanctuary, and endgame assets.

## Implementation Note

Right now many prototypes intentionally clone vanilla art-safe placeholders. That keeps gameplay moving, but it means:

- icon swaps are cheap and mostly data-only
- structure picture swaps are moderate and localized
- squirrel and tree world-art swaps are the risky part and may require prototype field updates alongside the PNGs
