# Link-tree slice

The first slice of the idealised runtime is a tree of fixed responder records, linked by parent and child lists, with a cached walk for each of the four input callbacks. The target shape is [addon.md](addon.md). The live autoload stays on `systems/input_manager.gd`, and the Node `{gdscript} Responder` stays the class the benches measure. The effective map is the following slice, in [effective-map.md](effective-map.md). The contiguous block in [addon.md](addon.md) waits until these links are in place.

## Work

Do these in order.

- [x] Place the link-tree scripts in an unloaded folder
- [x] Define the fixed responder record
- [x] Store responder order in parent and child lists
- [x] Cache a front-to-back walk for each callback
- [x] Call the pass on the list it started with
- [x] Prove the tree with a correctness test

## Place the link-tree scripts in an unloaded folder

The plugin and the autoload load named scripts. A folder neither of them preloads stays out of the running game, which is how this slice can exist beside the Node tree the benches already measured.

Put the scripts at `addons/enetheru.layered-input/link_tree/`. The record file is `link_responder.gd`. The tree file is `link_tree.gd`. The test preloads both by path. The live `{gdscript} class_name Responder` stays on `systems/responder.gd`. `{gdscript} plugin.gd` keeps its current preloads. `project.godot` keeps the autoload on `systems/input_manager.gd`.

The record's map field is a `{gdscript} CustomInputMap`. The tree preloads `systems/custom_input_map.gd` and `systems/input_action.gd`, so the new files reuse the maps the editor already writes. List `link_tree/` in `.exportignore`, beside `test/`, so an export keeps shipping `systems/` and `ui/`.

## Define the fixed responder record

A responder here is one context's claim on what input means. The record is a fixed size so a later slice can lay the same fields out in one contiguous block. The script extends `{gdscript} RefCounted`. The four callback names are properties on that record.

The fields are a closed set.

**input_map**
  The `{gdscript} CustomInputMap` this responder contributes. `{gdscript} contributes_map()` is `{gdscript} active and input_map != null`.

**active**
  The process flag. A true flag with a filled slot is what puts the responder on a walk. A true flag with a map is what `{gdscript} contributes_map()` reports. The map rebuild that reads that report arrives with the owner, in the following slice.

**_input**
  Callable for the pass that runs before the GUI. An empty callable leaves the responder out of that walk.

**_shortcut_input**
  Callable for the pass that runs after the GUI for a key, a shortcut, or a joypad button.

**_unhandled_key_input**
  Callable for a key that is still unhandled after the shortcut pass.

**_unhandled_input**
  Callable for anything still left after the key pass.

**parent**
  The responder this one is linked under. The root's parent stays empty. The tree holds the root.

**children**
  The child responders, first to last. `{gdscript} add_responder` appends. Descendants of a responder are that responder and then each child's descendants.

`{gdscript} set_active` and `{gdscript} set_input_map` return when the new value is the current one. `{gdscript} set_active` then writes the flag and rebuilds each walk, because the flag is membership in all four. `{gdscript} set_input_map` writes the map and leaves the walks as they are, because a map is the contribution the following slice merges. Each setter remembers whether `{gdscript} contributes_map()` was true before the write. The call that asks an owner to rebuild the effective map uses that before-or-after check, and this slice has no owner to call.

A callable takes the `{gdscript} InputEvent`. The caller fills the slot it needs and leaves the others empty. The callable may forward to a target that already lives on the world or the UI. Adding the responder leaves that target where it is.

## Store responder order in parent and child lists

Opening a menu adds a responder under a parent and later pops it. The caller keeps the record. The link is the order, so the add pays for two list writes.

The tree creates the root, active, and assigns `settings/default_input_map.tres` when the caller passes no map. `{gdscript} add_responder` on the tree appends under that root. `{gdscript} add_responder` on a responder appends under that responder, which is how a nested page stays inside its parent's span.

`{gdscript} add_responder` warns and returns when the value is missing or its script is something other than the record. It returns when the record is already a child of this parent. It warns and leaves the record on its current parent when that parent is already set. A successful add sets `{gdscript} parent`, appends to `{gdscript} children`, and rebuilds each walk the new branch filled.

`{gdscript} remove_responder` returns when the record's parent is a different responder. It clears `{gdscript} parent`, erases the record from the parent's `{gdscript} children`, and leaves the record with the caller. It rebuilds each walk the detached branch had filled. The tree's `{gdscript} remove_responder` warns and keeps the root when the record is the root.

`{gdscript} pop_responder` reads the parent's last child. It returns null when `{gdscript} children` is empty. Otherwise it removes that last child and returns it.

Master order is parent, then children first to last. The root, a UI child, a title child of the UI, and a play sibling of the UI stand in that order as root, UI, title, play. The map slice will merge forward along this order. Dispatch reads it from the other end.

## Cache a front-to-back walk for each callback

The hot path is a callback that runs every event. Chasing parent and child links on that path repeats the same walk the membership change already knew. The tree keeps the result.

The tree holds four arrays, one for `{gdscript} _input`, `{gdscript} _shortcut_input`, `{gdscript} _unhandled_key_input`, and `{gdscript} _unhandled_input`. A walk lists the responders that are active and have a valid callable for that slot. The list is the master order with those responders kept, reversed, so index 0 is the front.

Front is the responder that sees the event first. In the root, UI, title, play tree, with every responder active and every unhandled slot filled, the unhandled walk is play, title, UI, root. An empty slot drops that responder from that one walk and leaves the other three alone. `{gdscript} active` false drops it from all four. Filling or clearing a slot rebuilds that one walk. `{gdscript} set_active`, add, and remove rebuild every walk whose membership the change touches. The rewrite happens on the stored array at the time of the change. A pass that has already copied its list finishes on the copy.

## Call the pass on the list it started with

Godot delivers one event to the node it is calling, and a handler may add or pop a responder before that call returns. The event still belongs to the responders that were in front when it arrived. The next event belongs to the tree the handler left behind.

The tree exposes `{gdscript} dispatch_input`, `{gdscript} dispatch_shortcut_input`, `{gdscript} dispatch_unhandled_key_input`, and `{gdscript} dispatch_unhandled_input`. Each takes the viewport and the event. At the start it copies that walk's records and the callable each record held. It calls those callables in order with the event. After each call it reads `{gdscript} viewport.is_input_handled()`. The pass returns when that is true, and the remaining callables stay in the copy. The handler marks the viewport with `{gdscript} set_input_as_handled()`.

A fill, a clear, an add, or a remove during the pass rewrites the stored walk. The copy keeps the callables captured at the start, so the rest of this event still runs them. The following call to that dispatch reads the stored walk.

## Prove the tree with a correctness test

The walks are the behaviour this slice claims. A correctness test is the place that claim is checked. Timing stays in `bench/`, on the Node tree.

Add one script per case under `tests/link_tree/`, each extending `{gdscript} TestBase`. The runner picks up a `test*.gd` script under `res://tests/`. A trace is one case. The scripts preload `link_responder.gd` and `link_tree.gd`.

The order cases build records and read the walks.

- Root with one child, both active, both unhandled slots filled: the unhandled walk is the child, then the root.
- Root, UI, title under UI, and play beside UI, all four slots filled on each: the unhandled walk is play, title, UI, root.
- A responder with only `{gdscript} _input` filled is absent from the unhandled walk and present at the front of an otherwise empty input walk.
- `{gdscript} set_active(false)` drops a filled responder from the walks. `{gdscript} contributes_map()` is false while the map field is still set. Setting active back to true returns the filled slots to the walks.
- `{gdscript} set_active(true)` on an already active responder returns with the walk's records still the same objects in the same order.
- `{gdscript} pop_responder` on the root returns the last child and leaves the walk as the root. A second pop returns null.
- Adding a record that already has a parent leaves it on that parent.
- The tree's remove of the root keeps the root.

The handled case and the mid-pass case need a viewport. The suite ensures a `{gdscript} SceneTree`, adds a `{gdscript} SubViewport` with `{gdscript} handle_input_locally` set, and calls `{gdscript} dispatch_unhandled_input` with that viewport. The first callable marks the viewport handled, and the second callable's counter stays at zero. In the mid-pass case the first callable adds another filled responder and replaces the second record's callable. The added responder's counter stays at zero for this call, the second counter runs the callable captured at the start, and a second dispatch visits the added responder and the replacement.
