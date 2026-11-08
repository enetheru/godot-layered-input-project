@tool
extends "fixture.gd"

## Front-to-back order for root, UI, title, and play on every walk.


func _run_test() -> int:
	var tree:Object = _tree()
	var root:Object = tree.get( &"root" )
	var ui:RefCounted = _record()
	var title:RefCounted = _record()
	var play:RefCounted = _record()
	for record:Object in [root, ui, title, play]:
		_fill_all( record )
	tree.call( &"add_responder", ui )
	ui.call( &"add_responder", title )
	tree.call( &"add_responder", play )

	var want:Array = [play, title, ui, root]
	_expect( tree, INPUT_WALK, want, "nested input" )
	_expect( tree, SHORTCUT_WALK, want, "nested shortcut" )
	_expect( tree, KEY_WALK, want, "nested key" )
	_expect( tree, UNHANDLED_WALK, want, "nested unhandled" )
	return runcode
