# Kinds of saving in a stock map rebuild, 23 November 2026

One setup rebuild of the stock link tree went from 15.7 ms to 6.1 ms. The savings came from a handful of kinds of change. A later pass can look for the same kinds. The case, the readings, and what the last sample still pays are at the end.

## A bulk build that calls a one-name editor method

Look for a loop that calls a method written for a single inspector edit. `add_action` recopies the whole dictionary, emits `changed`, and notifies the property list, and `add_event` does the same for that action's event list. `from_engine` used to call `add_action` once per engine name.

The bulk shape reads every name, deadzone, and event list into one dictionary and assigns that dictionary once. On the release template, with 108 actions and 125 events, `from_engine` through `add_action` was 7.8 ms median. The same read that keeps the engine's event objects was 0.81 ms. The copying bulk fill, which still duplicates each event, was 2.5 ms. An editor stopwatch on a smaller map, 88 actions and 97 events, showed the same split: 5.0 ms, 1.4 ms, and 0.48 ms.

`merge` still called `refresh_actions_inspector` after each layer. That copies the dictionary for a map the inspector is not showing. The rebuild now passes `refresh` false. A merge that a person is editing still refreshes.

## Sharing the engine's events when the name will be replaced

Look for `InputEvent.duplicate` on objects the next step will replace wholesale. `InputMap.action_get_events` returns the engine's own event objects. A snapshot that keeps those objects is enough when a later layer replaces the whole action, and when `apply_to_engine` writes the result back over the engine. Duplicating is the right read when a later edit of the snapshot must leave the engine alone. `from_engine` still does that copy. `alias_from_engine` keeps the objects.

The addon calls `alias_from_engine` once, before the first rebuild, and stores it as `engine_baseline`. Each rebuild makes a new action row whose event list points at those objects. The stored baseline is left as it is, so clearing a finished merge does not clear it. Test and bench cleanup restores that one map instead of calling `from_engine` again for every case.

## A row the next pass throws away

Look for a fill that runs before the pass that overwrites the same names. The node rebuild used to install the whole baseline and then merge the responder maps, so every name the root map defined was constructed and then replaced. The merge now runs first. `install` fills only the names no layer wrote. The link tree already filled the gaps last.

`install` in the last capture is 0.36 ms. In the two earlier readings it was 1.4 ms and 1.5 ms. Those earlier readings still walked the map with the custom iterator, so the drop belongs to that walk as well as to building fewer rows.

## A copy kept while the source still holds the same events

Look for `duplicate_action` on a layer that has not changed since the previous rebuild. The stock root map is that layer. `merge` now keeps the duplicated events for a source action while that action's `events` array still holds the same objects, in the same order. The deadzone is read from the action each time, so a deadzone edit does not copy the events again. Replacing, adding, or removing an event builds a new copy. A field edit on an event object that stays in the list leaves the stored copy as it is.

This capture merges the stock map once, so the cache is filled and not reused. `Resource.duplicate` is still 1.1 ms for 98 events, and `_cached_events` around that copy is 2.0 ms. A second rebuild of an unchanged layer would skip the duplicates. That second pass is not in this file.

## An engine write of objects the engine already holds

Look for erase-and-add of a name whose deadzone and event objects are already on the engine. `apply_to_engine` compares those and leaves the name in place when they match. `action_add_event` across both writes in the last capture is 0.06 ms. The time around it is the per-name script.

On this one-shot setup the check skips nothing that matters. The first write is putting new duplicates into the engine, so they cannot match. The second write puts the baseline's original objects back, so those do not match either. The check is the right shape for a rebuild that applies the same objects again. This file does not contain that rebuild.

## A signal on every element of a cold build

Look for `changed.connect` inside the loop that builds the data. The first cache connected `changed` on each of 89 actions and on each of their events, so an in-place field edit would drop the copy. That watch was 1.6 ms, and the capture never merged the layer a second time to earn it back. The cache now compares the event objects stored on the action. The field-edit case is the one that comparison leaves in place.

## A one-line helper called once per name

Look for a function whose body is one expression, called once per action or once per event. A GDScript call showed up as its own zone on this path. Three of those wrappers were folded into the caller. `merge` constructs the `InputAction` itself. `apply_to_engine` does the match and the erase-and-add itself. `_cached_events` and `_same_event_objects` stayed, because each is the shared body rather than a wrapper.

The capture taken after that fold and before the iterator change was still about 9.8 ms. The fold is the right shape when the call count is in the hundreds. This pair of readings did not separate its saving from the noise.

## A custom `for-in` on a dictionary or an array

Look for `_iter_init`, `_iter_next`, and `_iter_get` on a type whose hot loop walks a dictionary or an array. Godot calls those three methods from `OPCODE_ITERATE_OBJECT`. In the middle capture that opcode was 2.5 ms for 468 steps, about 5 µs a step, and it was `for name in map`. Dictionary iteration in the same capture was a few microseconds. Array iteration by index is the same kind of walk.

`CustomInputMap` and `InputAction` no longer implement `for-in`. A map loop walks the keys of `_actions`. An event loop walks the `events` array and skips empty slots. The setup rebuild went from 9.6 ms to 6.1 ms across that change. The object-iteration opcode is absent from the last capture.

## The case

The case is `tests/setup/responder_tree.gd`, run on the release template. The readings were captured while that file was still `tests/setup/link_tree.gd`, so the capture path was `tests/setup/link_tree.play_release.tracy`. That file was replaced between readings. Each column is `_rebuild_input_map` from the capture that was current then.

The zone includes the test putting the baseline back. `rebuild_finished` resumes the test before `_rebuild_input_map` returns, so both engine writes sit inside the one sample.

| | Baseline and cache | Event walk, no per-event signal | Dictionary and array walks |
|---|---:|---:|---:|
| `_rebuild_input_map` | 15.7 ms | 9.6 ms | 6.1 ms |
| `merge` | 6.3 ms | 3.8 ms | 3.5 ms |
| `apply_to_engine`, both writes | 7.4 ms | 4.1 ms | 1.9 ms |
| `install` | 1.5 ms | 1.4 ms | 0.36 ms |
| `_cached_events` | 4.3 ms | 1.9 ms | 2.0 ms |
| signal watch on each event | 1.6 ms | | |
| `Resource.duplicate`, 98 events | 1.2 ms | 1.1 ms | 1.1 ms |
| object `for-in` | 4.9 ms | 2.5 ms | |

The last zone total in the file is 6.09 ms. A reading of the same zone was 6.2 ms. The two writes inside it are 1.2 ms and 0.65 ms.
