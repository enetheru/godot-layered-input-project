# Effective-map slice

The next slice of the idealised runtime is the table the link tree composes from contributing maps. The link tree in [link-tree.md](link-tree.md) already stores parent and child order and the four dispatch walks. This slice reads that order from the front and builds `{gdscript} effective_map`. The target shape is [addon.md](addon.md). The live autoload stays on `systems/input_manager.gd`. The contiguous block and the event-type masks stay later.

## Work

Do these in order.

- [x] Keep the effective map on the link tree
- [x] Skip a name the front map already wrote
- [x] Request a rebuild when the contribution changes
- [x] Coalesce one frame of edits into one table
- [x] Prove the table with a correctness test

## Keep the effective map on the link tree

The walks already live on the link tree, and the map is the other reading of that same order. Keeping the rebuild beside them leaves the measured Node manager on the path the node benches time.

The fields and the rebuild stay in `addons/enetheru.layered-input/systems/responder_tree.gd`. The live rebuild stays in `systems/input_manager.gd`, which still collects maps from the root forward and calls `{gdscript} merge` with its default overwrite. `{gdscript} plugin.gd` keeps its current preloads. `project.godot` keeps the autoload on `systems/input_manager.gd`.

The link tree holds `{gdscript} effective_map`. It signals `{gdscript} input_map_changed` with that map, and `{gdscript} rebuild_finished` when a queued rebuild has settled. `{gdscript} CustomInputMap.merge` and `{gdscript} apply_to_engine` stay the live functions. The link tree calls them.

## Skip a name the front map already wrote

Last child wins, which is the order the engine already uses when it walks a parent. Copying a row that a later merge is about to replace is the work a skip avoids. A name the front has written stays, and a name only a responder behind it defines is still copied.

Master order remains parent, then children first to last. The composition reads that order from the front, the same direction as a dispatch walk. `{gdscript} contributes_map()` is the membership test: `{gdscript} active and input_map != null`. An inactive responder is omitted. Its active children are still visited.

The rebuild starts a fresh `{gdscript} CustomInputMap` and merges each contributing map into it with `{gdscript} overwrite` false. The front map's rows land first. A name already present is left, including a null placeholder, so a menu in front that reserves jump leaves the play map's jump unread. A name the table does not yet have is copied, so play's attack still arrives when the menu has no attack. The incoming row is the copy `{gdscript} merge` already makes, and each responder keeps its own map.

## Request a rebuild when the contribution changes

A dispatch walk cares that a callable is filled. The table cares that a map is contributing. The two rebuilds start from different gates, so a callback edit leaves the table, and a map edit leaves the walks.

`{gdscript} set_active` and `{gdscript} set_input_map` already return when the new value is the current one. Each already remembers whether `{gdscript} contributes_map()` was true before the write. When the record contributed before the write or contributes after it, that branch calls `{gdscript} request_rebuild` on the tree. The record's `{gdscript} _tree` is the pointer. While that pointer is empty the call returns, which is how an edit made before `{gdscript} add_responder` waits.

`{gdscript} add_responder` and `{gdscript} remove_responder` already rewrite the walks for the branch. They also request a map rebuild when `{gdscript} branch_affects_map` is true for that branch. The check is true when the record contributes or any descendant does, so an inactive parent with a contributing child still updates the table. On remove, the check reads the branch that was just detached, and the request goes to the tree that held it.

The root is created with the default map, or with the map passed to the tree. Construction assigns that map and then requests a rebuild, so the base table exists before any child is added.

## Coalesce one frame of edits into one table

A frame can add a responder, silence one, and swap a map. Those edits are one meaning, so the engine sees one table.

`{gdscript} request_rebuild` sets `{gdscript} _want_rebuild` and returns when that flag is already set. While a rebuild is running it returns after setting the flag, and the running call queues the follow-up. Otherwise it queues a single `{gdscript} call_deferred` of `{gdscript} _rebuild_input_map`.

The deferred body returns when `{gdscript} _rebuilding` is already set, leaving `{gdscript} _want_rebuild` set for the outer call. It clears `{gdscript} _want_rebuild`, sets `{gdscript} _rebuilding`, and builds the table by the skip above. It stores that map on `{gdscript} effective_map` and clears the previous composed map. The composed map is always a fresh resource, so the clear leaves the root's map and the stock default alone. It then calls `{gdscript} apply_to_engine` with the default wholesale replace of each name. A null row becomes an engine action at the default deadzone with no events, which is the cleared binding. It emits `{gdscript} input_map_changed` while `{gdscript} _rebuilding` is still set, so a listener that edits the tree from that signal waits for a later rebuild. It clears `{gdscript} _rebuilding`. When `{gdscript} _want_rebuild` is set it queues one more deferred call. Otherwise it emits `{gdscript} rebuild_finished`.

`{gdscript} until_rebuilt` awaits `{gdscript} rebuild_finished` while a rebuild is queued or running, so a caller can read the settled table.

## Prove the table with a correctness test

The table is the behaviour this slice claims. A correctness test is the place that claim is checked. Timing stays in `bench/`. `bench/link_tree.gd` times this rebuild at the sizes the node bench uses for its map rebuild, and it times the walk at the same sizes as before.

Add one script per case under `tests/responder_tree/`, each extending the responder-tree fixture. Silencing the front child, and a map assigned before add, stay in that folder. The live responder leaves `input_manager` empty, so an edit after the first rebuild does not request another one.

Construction now queues a rebuild, and that rebuild writes the engine `{gdscript} InputMap`. The link fixture saves the engine map before it builds a tree and writes that snapshot back after `{gdscript} until_rebuilt`, including the dispatch cases already in the folder.

The cases read `{gdscript} effective_map` after `{gdscript} until_rebuilt`.

- A tree whose root map defines jump and attack holds both names, and the engine action for each matches the root row.
- A child in front whose map defines jump with a different event leaves the child's jump in the table. The root's attack is still present.
- A child whose jump is a null placeholder leaves `{gdscript} get_action` null for jump, and the engine action has no events. The root's other names stay.
- `{gdscript} set_active(false)` on that child settles the next table on the root's jump.
- `{gdscript} set_active(true)` on an already active child returns with the same `{gdscript} effective_map` object.
- `{gdscript} set_input_map` of the current map returns with that same object.
- An add and a map swap before idle emit `{gdscript} rebuild_finished` once, and the settled table contains both edits.
- A map assigned on a record before `{gdscript} add_responder` is present in the table that follows the add.
- An inactive parent with an active contributing child leaves the child's names in the table.
