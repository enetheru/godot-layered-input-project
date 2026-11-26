# Layered Input project

This page is the shape of `Enetheru.layered-input-project`. The package is the addon in [addon.md](addon.md). This project pins that package and shows the contract a game relies on.

## The fixture

The project is a Godot 4.7 scene, `main.tscn`. A cube stands in a yard, and the camera sits behind it. `demo/play_controls.gd` mounts the play responder and keeps it: WASD and the arrows move the cube, Space jumps, Tab opens the inventory, and Escape opens the menu. `demo/inventory_controls.gd` hangs its responder under play. Tab or Escape closes that sheet. While it is mounted, its map writes `inventory` with Tab and Escape, and writes `open_menu` with no events, so play's Escape does not stay. `demo/menu_controls.gd` adds the menu as the root's last child. Escape closes it, Space and Enter confirm, `jump` is the same action name with no events, and Quit leaves the game. `main.gd` wires the three.

A panel on the left draws the link tree, the four walks, and the action rows. A frame along the bottom lists each action that still has Escape, from the front of the walk. The handlers mark the viewport when they take the event.

Play, the inventory, and the menu are the whole of this scene's gameplay. Further game systems belong in the game that depends on the addon.

## The pin

`addons/enetheru.layered-input` is the addon. `project.godot` enables its plugin and autoloads `InputManager` from `systems/input_manager.gd`. Host mode, deadzone, and panel height live in the project settings that panel already reads.

The addon repository is the source of the package. This project consumes it by pin. A change to merge, delivery, or the editor is proven here, then the pin moves.

`addons/enetheru.test-runner` and `addons/enetheru.gdsbench` are pinned the same way, and `project.godot` enables them beside the command server. The proof is the responder-tree suite, and a time taken by `bench/responder_tree.gd`.

HelloWorld is the game that already calls the same autoload. That game is the long caller. This project stays the short one, so the result of a responder change is the whole scene.

## Testing

TestRunner discovers the cases under `res://tests/responder_tree/`. Each case extends `tests/responder_tree/fixture.gd`. The checks cover walk order, a handled viewport, a pass that keeps the callables it copied, and the effective map: a front name stays, an empty jump clears the events, a name the layers leave empty keeps the engine's events, and an inactive parent stays out while an active child still contributes.

The command server stays enabled beside Layered Input. An agent lists and runs that suite through it (`TESTS_LIST`, `TESTS_RUN`).

## Benchmarking

`bench/responder_tree.gd` is an editor script. `BM_ResponderTreeRebuild` times one `_rebuild_input_map` on a tree that is already built, at 8, 64, 256, and 1024 records. `BM_ResponderTreeWalk` times one `dispatch_input` through records that fill `_input` and carry no map, at 128, 1024, and 4096. The walk sample leaves the map rebuild outside the timed loop.

## A passing run

Play moves the cube and jumps. Tab opens the inventory and Escape closes it. Opening the menu leaves the inventory mounted when it was already open, lists the menu responder in front, and shows jump with no events while confirm owns Space. Closing the menu restores the bindings the layers behind it still write. Quit leaves the game. The tree panel, the Escape frame, and the cube tell the same story.
