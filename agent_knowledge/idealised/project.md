# Layered Input project

This page is the target shape of `Enetheru.layered-input-project`. The package under design is the addon in [addon.md](addon.md). This project pins that package and shows the contract a game relies on.

## The fixture

The project is a Godot 4.7 scene, `main.tscn`, whose job is that contract on one screen. A box sits on a floor. The play layer is added and stays: WASD and the arrows move the box, Space jumps, and Escape opens the menu. The menu layer is added in front: Escape closes it, Space and Enter confirm, and jump is the same action name with a placeholder that has no events, so Space confirms. The HUD lists the layer order and the live bindings, on the same screen as the box.

The demo's responders are the smallest callers that still show a front layer replacing a back layer. Their handlers live on `main.gd`. The manager marks the viewport when a handler takes the event, which matches the addon target of one in-tree node owning the walk.

The readout reads the manager's layer order. As the addon moves layers into the packed list, the HUD follows that list, and the box and the binding lines stay the check.

## The pin

`addons/enetheru.layered-input` is the addon. `project.godot` enables its plugin and autoloads `InputManager` from `systems/input_manager.gd`. Host mode, deadzone, and panel height live in the project settings that panel already reads.

The addon repository is the source of the package. This project consumes it by pin. A change to merge, delivery, or the editor is proven here, then the pin moves.

HelloWorld is the game that already calls the same autoload from context, the player, the action menu, and UI. That game is the long caller. This project stays the short one, so the result of a layer change is the whole scene.

## The bench

The command server is enabled beside Layered Input, and the tests extension sits in `addons/`. An agent opens the editor, runs this scene, and reads the HUD and the box against the stack. The project is that bench.

Play and the menu are the whole of its gameplay. Further game systems belong in the game that depends on the addon.

## A passing run

Play moves the box and jumps. Opening the menu leaves the box on the ground, lists the menu layer in front, and shows jump with no events while confirm owns Space. Closing the menu restores jump on Space and drops the menu layer. The binding lines and the box tell the same story.
