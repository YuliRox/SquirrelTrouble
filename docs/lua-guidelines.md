---
path: squirrel_madness/**/*.lua
---

# Factorio Lua Rules — squirrel_madness

These rules capture hard-won lessons from working with the Factorio 2.0 Lua API. Follow them exactly; violating them causes silent data loss or crashes that are difficult to debug.

## Runtime vs Data stage

- `data:extend({...})` is data-stage only — never call it from `control.lua` or any script it requires.
- `storage.*` is runtime-only — never reference it during data stage.
- `script.*`, `game.*`, `remote.*` are runtime-only — do not use in `data*.lua` or `settings*.lua`.

## `require()` is parse-time only

- `require()` may only be called while `control.lua` (and its transitive requires) is being parsed. Calling it inside any function body that runs later — event handlers, remote interface methods, tick callbacks — crashes with `Require can't be used outside of control.lua parsing.` on first invocation.
- All `require()` calls in every module must therefore be at the top of the file, before any function definitions. No lazy/inline requires.
- This rules out the usual lazy-require workaround for circular dependencies between sibling modules. If sub-module A needs B and B needs A, the cycle must be broken structurally: move the called function into the caller's module, hoist the shared logic into a third module, or pass dependencies in via an `install(deps)` / setter pattern called from `control.lua` parse time.
- When extracting a new sub-module from `scripts/runtime.lua` or another module, plan the dependency direction up front so all requires can stay top-level.

## Runtime event registration

- Register each Factorio event or custom input only once, from `control.lua` or the central runtime registration function in `scripts/runtime.lua`.
- Treat the registered handler as a dispatcher: validate the event payload, filter by entity name/type/input/context, and then call the relevant subsystem function.
- Do not register the same event independently from feature modules such as `scripts/squirrels/`, `scripts/habitat/`, `scripts/feeders/`, or `scripts/regions/`.
- When adding a subsystem reaction to an existing event, extend the existing dispatcher and update `docs/hooks.md`; do not add a second `script.on_event` for that event.

## Storage / global state

- Use `storage.*` for all persistent runtime state. `global` was renamed to `storage` in Factorio 2.0 — never write `global`.
- Always initialise storage keys in `on_init` and guard in `on_configuration_changed` with `storage.key = storage.key or default`.

## Inventories

- `LuaInventory.get_contents()` returns `ItemCountWithQuality[]` (an array of objects), **not** `{[name] = count}`. Always iterate and read `.name` and `.count` from each element.
- `entity.get_inventory(defines.inventory.crafter_input)` — assembler input slot.
- `entity.get_inventory(defines.inventory.crafter_output)` — assembler output slot.
- `entity.get_inventory(defines.inventory.crafter_trash)` — assembler trash slot.
- `entity.get_inventory(defines.inventory.lab_input)` — lab input slot.

## Assembler / set_recipe behaviour

- `set_recipe` **silently deletes** any input items that do not match the new recipe's ingredients. You must move them out (to trash) before calling `set_recipe`.
- `set_recipe` **returns** in-progress items to input — but only items that exist in the new recipe. Items mid-craft that are not in the new recipe are lost unless rescued first.
- `entity.crafting_progress > 0` means ingredients have already been consumed from input and are "inside" the craft.

## Prototypes

- `hidden` is a standalone boolean field on a prototype table, **not** an entity flag string. Set it as `hidden = true` at the top level of the prototype.
- `collision_mask = {layers = {}}` — an empty `layers` table makes an entity non-collidable with everything.
- `energy_source = {type = "void"}` — entity consumes no power and needs no electric network.
- `entity.destructible = false` prevents the entity from taking damage, but `entity.destroy()` in script still works.
- `data.raw["some-type"]` can be `nil` if no prototype of that type has been registered yet. Always guard with `data.raw["some-type"] and data.raw["some-type"]["name"]` before indexing.

## Localised strings

- Localised string tables (arrays starting with a translation key) have a **20-parameter limit** in Factorio. If you need more substitutions, split into nested sub-tables — each sub-table counts as one parameter to the outer table.
- Keep chunks to ≤9 entries per sub-table to leave room for the key itself.

## Surface / world

- `surface.spill_item_stack(pos, stack, enable_looted, force, allow_belts)` — pass `false` as the fifth argument to prevent items landing on belts.
- `surface.request_to_generate_chunks(pos, radius)` followed by `surface.force_generate_chunk_requests()` synchronously generates chunks — safe to use in `on_init`.
- Chunk position and tile position are different coordinate spaces. A chunk at `{x, y}` covers tiles `x*32` to `(x+1)*32 - 1` on each axis.

## FactorioTest

- `describe` blocks execute at **load time** — never call `game.*`, `storage.*`, or create entities inside a `describe` body. Only use them inside `it()`, `before_each`, `after_each`, etc.
- Always pair entity creation in `before_each` with `entity.destroy()` in `after_each` so tests don't leak into each other.
- Reset relevant `storage` keys in `before_each`/`after_each`; FactorioTest does not reset `storage` between tests automatically.
- For multi-tick behaviour use `async(timeoutTicks)` then `after_ticks(n, fn)` or `on_tick(fn)` inside the test body; call `done()` when finished.
- Test files live in `squirrel_madness/tests/`. Register new files by adding a `require` line to `scripts/tests.lua` — do not edit `control.lua`.

## Mod compatibility

- Always guard Space Age content with `if mods["space-age"] then … end` in data stage, or `if script.active_mods["space-age"] then … end` in runtime.
- Guard optional-dependency prototype patches with `data.raw["type"] and data.raw["type"]["name"]` before modifying.
- Guard remote interface calls with `remote.interfaces["ModName"] and remote.interfaces["ModName"]["function_name"]` before calling.
