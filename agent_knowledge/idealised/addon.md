# Layered Input addon

This page is the idealised target shape of `enetheru.layered-input`.

The idealised integration project page is [project.md](project.md).

A game clones the repository into its `addons` folder under any folder name. Paths inside the addon are relative. Enabling Layered Input loads the editor plugin. Adding the autoload turns on the runtime.

## Purpose

The addon provides:
- a system to change, in a flexible way, what an input event means as the game state changes.
- resources for input maps and input actions.

### Desire
- Alter the meaning of input events, such as keypresses and mouse events, according to the game state.
- Easily apply and revert sets of changes to the input map according to the game state, in a reasonable manner.
- Compose input maps in meaningful ways.
- Save user-defined input maps.
- Switch between input maps easily.
### Godot's Limitations

- Godot keeps a single `{gdscript} InputMap`, saved in the project configuration. 
- Changing what a key means writes that global table. 
- The order of `{gdscript} Node`s in the `{gdscript} SceneTree` often differs from the order in which we would like to handle events. 
### Solutions

- A `{gdscript} CustomInputMap` saves a `{gdscript} Dictionary` of `{gdscript} InputAction` rows. Each row holds the `{gdscript} InputEvent`s for that action.
- `{gdscript} InputManager` holds a `{gdscript} ResponderTree` and dispatches each `{gdscript} InputEvent` to a `{gdscript} Node` in the main `{gdscript} SceneTree`, or to some other target.
- The editor plugin edits a `{gdscript} CustomInputMap` in the Godot editor, with the same gestures as the built-in Input Map.
- The runtime action editor is the same control the editor plugin uses, available while the game is running, so a player can change bindings and save the map.
## Runtime System

The runtime is `{gdscript} InputManager`, the `{gdscript} ResponderTree`, the maps, and the in-game editor control.
### InputManager

Godot reads a single `{gdscript} InputMap`, and it delivers an event only to a node that is in the tree, so something in the tree has to gather the meanings and then hand the event on. 

`{gdscript} InputManager` has two jobs:

- Compose multiple CustomInputMaps into a single InputMap to hand to the engine. 
- Distribute InputEvents unaffected by the SceneTree layout.

The class in `systems/input_manager.gd` is named `{gdscript} _InputManager`, which leaves the autoload name free for `{gdscript} InputManager`. 

Both the distribution of InputEvents, and the composition of the CustomInputMaps share the same `{gdscript} ResponderTree` data structure.
#### Composing InputMaps

To keep things *simple*, we will use the same ordering the engine uses when walking the `{gdscript} SceneTree`, last child wins. so the composition starts from the first child and overwrites? or should we start from the last child and skip? Can we merge? should it depend on the input action itself? things need to be decided. For now last child wins and i think we skip so less work is done.

The final result of the composition are held in the `{gdscript} effective_map` and are written to the engine, then `{gdscript} input_map_changed` fires so a listener hears the settled meaning.
#### Distributing InputEvents

The `{gdscript} SceneTree` arrangement used for visual layout and spatial mouse clicks is often at odds with the layout that we want key/joy input processed. We need to de-couple the receipt of InputEvents from the SceneTree's usual processing.
##### Last Child
Firstly we need to ensure that the InputManager responds to input before other Nodes. Godot walks `{gdscript} _input` from the last child back toward the first, to ensure we receive input before other nodes, we need to be the last child of the root node.

The InputManager calls `{gdscript} get_tree().root.move_child(self, -1)` to maintain its position as the last child:
- on `{gdscript} _enter_tree`
- on `{gdscript} child_order_changed`

The call must be deferred as the `{gdscript} SceneTree` is in the middle of adding nodes.

##### Distributing InputEvent

The `{gdscript} InputManager` implements the same four callbacks a `{gdscript} Node` receives, in the same order, so a user meets the names they already know. `{gdscript} _input` runs before the GUI. `{gdscript} _shortcut_input` runs after the GUI for a key, a shortcut, or a joypad button. `{gdscript} _unhandled_key_input` runs next, and only for a key that is still unhandled. `{gdscript} _unhandled_input` runs last, for anything still left. Each callback walks only the cached list for that pass.

##### Fall-Through
If the InputManager does not handle the event, then it will automatically fall through to the rest of the SceneTree.
#### Shutdown

`{gdscript} shutdown`, from `{gdscript} _exit_tree`, frees the tree and releases `{gdscript} effective_map`. The engine `{gdscript} InputMap` remains in the state the last `{gdscript} apply_to_engine` wrote, because teardown can run while that frame is still using those actions.

### ResponderTree

A `{gdscript} ResponderTree` is the ordered set of `{gdscript} Responder`s the `{gdscript} InputManager` owns. It is read to build the `{gdscript} effective_map` that is given to the engine, and it is walked when an event is dispatched.

#### Responders

The tree is parent and child lists. The root holds the default map. The caller keeps every other responder. Eg. Opening a menu adds a responder to the tree to override the meaning of key events.

#### Effective Map Rebuild

A change to a responder's `{gdscript} active`, or of `{gdscript} input_map`, rebuilds when `{gdscript} branch_affects_map` is true. The merge walks the tree, and a later contributing map replaces the same action name, which is how a menu clears jump.

##### One meaning per idle

A frame can add a responder, silence one, and swap a map. Those are one change of meaning, so the engine should see one table. `{gdscript} request_rebuild` sets `{gdscript} _want_rebuild` and queues a single `{gdscript} call_deferred` of `{gdscript} _rebuild_input_map`, which runs at idle, after the frame's decisions. `{gdscript} _rebuilding` stays set through `{gdscript} apply_to_engine` and the `{gdscript} input_map_changed` emit, so a listener that edits the tree from that signal waits for a later rebuild.

#### Dispatch

The tree keeps four cached walks, one for each callback the `{gdscript} InputManager` implements. A walk lists the responders that filled that slot, in front-to-back order, so an empty slot is never visited. During the callback the manager calls straight through that list, reads `{gdscript} get_viewport().is_input_handled()` after each call, and stops when the handler has marked the viewport.

A change made during a pass applies when the pass returns, so a key finishes on the walks that were current when it arrived. Filling or clearing a slot rebuilds that one walk.

### Responder

A `{gdscript} Responder` is a node in the `{gdscript} ResponderTree` which may contribute a `{gdscript} CustomInputMap` to the `{gdscript} effective_map` that is given to the engine, and which the `{gdscript} InputManager` may call when it dispatches an event.

#### Fixed Size
A `{gdscript} Responder` has a fixed size, and it is not overloadable. The fields are a closed set, so nothing can add to the record or replace its behaviour.

#### CustomInputMap

The fields that decide a contribution are `{gdscript} input_map` and `{gdscript} active`. `{gdscript} contributes_map()` is `{gdscript} active and input_map != null`, and that is the check the merge uses. While `{gdscript} active` is false the map stays out of the `{gdscript} effective_map`.
#### EventDispatch

The record has four callable slots, one for each callback: `{gdscript} _input`, `{gdscript} _shortcut_input`, `{gdscript} _unhandled_key_input`, and `{gdscript} _unhandled_input`. An empty slot leaves the responder out of that walk. A gameplay responder fills the unhandled slot it needs and leaves the others empty. The callable may forward to a target that already lives on the world or the UI, which is how play and menu return to the caller that added them. Adding the responder leaves that target where it is.
#### Active/Inactive

`{gdscript} set_active` and `{gdscript} set_input_map` return when the new value is the current one. Each remembers whether the responder was contributing, writes the value, and requests a rebuild only when it contributed before the write or contributes after it. A change made before the responder is in the tree waits, and the rebuild runs once it is in the tree.

`{gdscript} input_manager` is the pointer the rebuild uses. The call returns when that pointer is invalid, and it returns when the object has no `{gdscript} request_rebuild` method, which is the check for a placeholder left by an editor reload. The field needs one writer, at the moment the responder joins the tree, so this check and the rebuild stay the same path.

### CustomInputMap

A `{gdscript} CustomInputMap` is the table a responder may contribute. `{gdscript} _actions` is a `{gdscript} Dictionary` from `{gdscript} StringName` to `{gdscript} InputAction`. Each row is stored as an embedded sub-resource. A name stored as `{gdscript} null` reserves that action before any events exist.

`{gdscript} merge` folds another map into this one. The entry for the same name is replaced wholesale, and the incoming row is copied so each map keeps its own events. `{gdscript} apply_to_engine` writes this map's names onto Godot's `{gdscript} InputMap`, replacing those names.

Build the map in code and assign it on a responder, or author a `.tres`. `{gdscript} emit_changed` marks the file dirty so the editor can save it.

`settings/default_input_map.tres` is the base map. It holds the editor and UI actions.

### InputAction

An `{gdscript} InputAction` is one row of a `{gdscript} CustomInputMap`. It holds a deadzone and an ordered list of `{gdscript} InputEvent`s, the same pair Godot stores on an engine action. The default deadzone is `{gdscript} 0.2`. `{gdscript} add_event`, `{gdscript} erase_event`, and `{gdscript} clear_events` change the list. Replacing the whole array does the same.

The row lives embedded in the map `.tres`. Code creates one through `{gdscript} CustomInputMap.add_action`.

### Runtime action editor

A running game instances `ui/input_map_editor.tscn`. The control edits one `{gdscript} CustomInputMap`. It picks an action, listens for an `{gdscript} InputEvent`, and writes that event on the row. That is how a player rebinds keys and saves their map.

## EditorPlugin

The editor plugin writes a `{gdscript} CustomInputMap` while Godot is open. Enabling the plugin loads the panel. The autoload remains a separate project choice.

### InputMapEditor

`{gdscript} InputMapEditor` uses the same gestures as the engine Input Map. Its scene is `ui/input_map_editor.tscn`, the control a running game instances. `{gdscript} host_mode` places the panel. A dock uses Godot 4.7 `{gdscript} EditorDock`. `host_session.gd` stores the host that was built, and closing the plugin closes that host after `{gdscript} host_mode` has changed.

When the inspector needs an object for a reserved action name, the row is stored as an empty `{gdscript} InputAction`.

### ExportPlugin

`export_plugin.gd` reads `.exportignore`. The export keeps `systems/` and `ui/`. The plugin entry, `test/`, `README.md`, and `docs/` stay in the repository.

### Settings

Settings use the prefix `input_map_editor/`. `{gdscript} InputMapEditorSettings` is the resource that features read. `settings/settings.gd` copies that resource to and from `{gdscript} ProjectSettings`.

**host_mode**
  Dock, main screen, or inspector. It is applied when the plugin attaches, and again when the setting changes while the plugin stays enabled.

**auto_raise**
  Brings the dock or the main screen forward when a map is selected. Default on.

**default_deadzone**
  The deadzone the panel uses for a new action. Default `{gdscript} 0.2`, matching a new `{gdscript} InputAction`.

**panel_min_height**
  The minimum height of the dock and of the inspector editor. Default `{gdscript} 280`.

### Logging

`settings/logging.gd` is this addon's log backend. The default is `{gdscript} print`. A project points `{gdscript} Backend` at `{gdscript} enetheru.log-shim`, or another compatible script, for a richer log. There is no `{gdscript} class_name` and no autoload, so another addon keeps its own backend. The settings copier logs here when a copy between the resource and `{gdscript} ProjectSettings` fails.

# Notes

## Flattening the tree, later

Walks follow parent and child links until the system is in place. The records are a fixed size so the tree can later be one contiguous block, and the hot walks can scan packed data instead of chasing those links.

A record would hold `{gdscript} input_map`, `{gdscript} active`, the four callable slots, a parent index, and a descendant count. The descendants of the record at index `{gdscript} i` would be the span `{gdscript} [i, i + n]`. The tree has one `{gdscript} InputManager`, so that pointer stays off the record.

A rebuild would fill a merge array of contributing map pointers, front to back, and would pack the four dispatch walks the same way. An event walks the array for its pass, forward. A pass that is already walking keeps the array it started with, and the next rebuild writes the other copy. Parent index and descendant count stay out of those arrays, because the event walk does not read them.

## Event-type masks, later

A bitmask of event types on a slot could split each of the four walks further. A mouse-motion event would then skip a responder that filled `{gdscript} _unhandled_input` for keys only. That removes more dead calls, and it multiplies the number of cached walks by the number of types. The four pass walks come first. The masks wait until those walks are in place and a profile says the extra split is worth the rebuild.

An `{gdscript} Array` of objects is a list of pointers. The later layout wants packed columns, or one fixed buffer.

## Why not use `{gdscript} window_set_input_event_callback`

`{gdscript} DisplayServer.window_set_input_event_callback(callback, window_id)` stores a Callable. The callable can be a `{gdscript} RefCounted` method, a lambda, or a static function. The root Window installs its own method there `{gdscript} Window._window_input` in `scene/main/window.cpp`. This override is for advanced users and can introduce bugs, because it replaces that method rather than adding a listener.

That method is the whole intake. On this 4.7 tree it handles an exclusive child, calls `{gdscript} _input_from_window`, emits `{gdscript} window_input` when the window is inside the tree and the event is not internal, runs the fullscreen shortcut, then calls `{gdscript} push_input`. `{gdscript} push_input` is the `{gdscript} SceneTree` walk: `{gdscript} _input`, GUI, shortcut, `{gdscript} _unhandled_key_input`, `{gdscript} _unhandled_input`, then physics picking. A replacement that does not call `{gdscript} push_input` leaves Controls, unhandled input, and picking with nothing. The root window also writes its own callback back when it enters the tree and when it leaves, so a callback installed too early is overwritten at startup.

`{gdscript} Window.window_input` is the signal on that same path. Any callable can connect to it, so the listener need not be a node. It is emitted only while the window `{gdscript} is_inside_tree()`, and only for non-internal devices. `{gdscript} push_input` still runs afterwards, and the first thing `{gdscript} push_input` does is clear the `{gdscript} handled` flag, so a signal handler cannot swallow the event for the rest of the frame.
