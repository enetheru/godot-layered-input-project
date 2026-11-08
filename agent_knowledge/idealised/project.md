# Layered Input project

This page is the target shape of `Enetheru.layered-input-project`. The package under design is the addon in [addon.md](addon.md). This project pins that package and shows the contract a game relies on.

## The fixture

The project is a Godot 4.7 scene, `main.tscn`, whose job is that contract on one screen. A box sits on a floor. The play responder is added and stays: WASD and the arrows move the box, Space jumps, and Escape opens the menu. The menu responder is added in front: Escape closes it, Space and Enter confirm, and jump is the same action name with no events, so Space confirms. The HUD lists the responder order and the live bindings, on the same screen as the box.

The demo's responders are the smallest callers that still show a front responder replacing a back one. Their handlers live on `main.gd`. The manager marks the viewport when a handler takes the event.

The HUD reads the `ResponderTree` order. The box and the binding lines are the check.

Play and the menu are the whole of its gameplay. Further game systems belong in the game that depends on the addon.

## The pin

`addons/enetheru.layered-input` is the addon. `project.godot` enables its plugin and autoloads `InputManager` from `systems/input_manager.gd`. Host mode, deadzone, and panel height live in the project settings that panel already reads.

The addon repository is the source of the package. This project consumes it by pin. A change to merge, delivery, or the editor is proven here, then the pin moves.

`addons/enetheru.test-runner` and `addons/enetheru.gdsbench` are pinned the same way, and `project.godot` enables them beside the command server. The proof is a suite run against this scene, and a time taken on that same scene, so the runner and the benchmark library belong with the fixture.

HelloWorld is the game that already calls the same autoload from context, the player, the action menu, and UI. That game is the long caller. This project stays the short one, so the result of a responder change is the whole scene.

## Testing

TestRunner discovers scripts under `res://tests/**`. The suite states the passing run: the box moves and jumps, the menu responder in front takes Space, and closing the menu puts jump back on Space.

The command server stays enabled beside Layered Input. An agent lists and runs that suite through it (`TESTS_LIST`, `TESTS_RUN`). `TESTS_RUN` waits for the editor to confirm before the suite starts.

## Benchmarking

A benchmark is a TestRunner suite that calls `{gdscript} BenchLib`. It times the merge and the dispatch walk on this scene, because those are the two jobs a responder change can make slower.

The suite's pass is the acceptance of a change. The benchmark records the cost of that same run.

## A passing run

Play moves the box and jumps. Opening the menu leaves the box on the ground, lists the menu responder in front, and shows jump with no events while confirm owns Space. Closing the menu restores jump on Space and drops the menu responder. The binding lines and the box tell the same story.
